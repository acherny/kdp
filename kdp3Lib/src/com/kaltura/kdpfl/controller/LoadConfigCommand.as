package com.kaltura.kdpfl.controller
{
	import com.kaltura.KalturaClient;
	import com.kaltura.commands.MultiRequest;
	import com.kaltura.commands.baseEntry.BaseEntryGet;
	import com.kaltura.commands.baseEntry.BaseEntryGetContextData;
	import com.kaltura.commands.flavorAsset.FlavorAssetGetWebPlayableByEntryId;
	import com.kaltura.commands.session.SessionStartWidgetSession;
	import com.kaltura.commands.uiConf.UiConfGet;
	import com.kaltura.commands.widget.WidgetGet;
	import com.kaltura.delegates.uiConf.UiConfGetDelegate;
	import com.kaltura.delegates.widget.WidgetGetDelegate;
	import com.kaltura.errors.KalturaError;
	import com.kaltura.events.KalturaEvent;
	import com.kaltura.kdpfl.model.ConfigProxy;
	import com.kaltura.kdpfl.model.LayoutProxy;
	import com.kaltura.kdpfl.model.MediaProxy;
	import com.kaltura.kdpfl.model.ServicesProxy;
	import com.kaltura.kdpfl.model.type.SourceType;
	import com.kaltura.vo.KalturaEntryContextDataParams;
	import com.kaltura.vo.KalturaLiveStreamBitrate;
	import com.kaltura.vo.KalturaStartWidgetSessionResponse;
	import com.kaltura.vo.KalturaUiConf;
	import com.kaltura.vo.KalturaWidget;KalturaLiveStreamBitrate;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import com.kaltura.vo.KalturaLiveStreamEntry;KalturaLiveStreamEntry;
	import com.kaltura.vo.KalturaLiveStreamBitrate; KalturaLiveStreamBitrate;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.AsyncCommand;
	import org.puremvc.as3.patterns.proxy.Proxy;
	import com.kaltura.vo.KalturaFlavorAsset;
	import mx.utils.UIDUtil;
	import com.kaltura.kdpfl.model.type.StreamerType;
	import fl.core.UIComponent;
	import flash.events.ErrorEvent;
	import com.kaltura.kdpfl.util.URLUtils;
	import com.kaltura.kdpfl.plugin.PluginManager;
	import flash.sampler.DeleteObjectSample;
	import com.kaltura.vo.KalturaMetadataFilter;
	import com.kaltura.types.KalturaMetadataObjectType;
	import com.kaltura.commands.metadata.MetadataList;
	import com.kaltura.vo.KalturaMetadataListResponse;
	import com.kaltura.kdpfl.model.type.NotificationType;
	import com.kaltura.vo.KalturaMetadata;
	import com.kaltura.types.KalturaMetadataStatus;
	import com.kaltura.vo.KalturaMetadataProfile;
	import com.kaltura.types.KalturaMetadataProfileStatus;
	import com.kaltura.net.KalturaCall;
	import com.kaltura.commands.metadata.MetadataGet;
	import com.kaltura.vo.KalturaFilter;
	import com.kaltura.types.KalturaMetadataOrderBy;
	import com.kaltura.vo.KalturaFilterPager;

	public class LoadConfigCommand extends AsyncCommand implements IResponder
	{
		public static const LOCAL : String = "local";
		public static const INJECT : String = "inject";
		
		private var _configProxy : ConfigProxy;
		private var _layoutProxy : LayoutProxy;
		private var _mediaProxy : MediaProxy;
		private var _flashvars : Object;
		private var _kc : KalturaClient;
		private var _numPreInitPlugins : Number;
		
		/**
		 * try using the wrapper embedded data for setting up the widget and uiconf
		 * in case the embedded uiconf id is different from the one passed via flashvars drop the embedded data
		 * and request the data from the server  
		 * @return true if embedded data was used and we can skip requesting the widget and uiconf from the server 
		 * 
		 */
		private function useEmbeddedData():Boolean
		{
			var embeddedWidgetData:String = _flashvars['embeddedWidgetData'];
			if (embeddedWidgetData)
			{
				var embeddedXML:XML = new XML(embeddedWidgetData);
				var xml:String = "<result>" + embeddedXML.result[1].toString() + "</result>";

				var getUiconfXml:XML = new XML(xml);
				var getUiconfDelegate:UiConfGetDelegate = new UiConfGetDelegate(null, null);
					 
				var uiConf:KalturaUiConf = getUiconfDelegate.parse(getUiconfXml);
					
				// if flashvars requested a uiconf different from the one embedded check if need to fetch uiconf from server
				if (_flashvars.uiConfId && _flashvars.uiConfId != uiConf.id)
					return false;
					
				_configProxy.vo.kuiConf = uiConf;
					
				xml = "<result>" + embeddedXML.result[0].toString() + "</result>";
				var getWidgetXml:XML = new XML(xml);
				var getWidgetDelegate:WidgetGetDelegate = new WidgetGetDelegate(null, null);
				var kw:KalturaWidget = getWidgetDelegate.parse(getWidgetXml);
				_configProxy.vo.kw = kw;
		
				return true;
			}
			
			return false;
		}
		
		/**
		 * 
		 * @param notification
		 * 
		 */		
		override public function execute(notification:INotification):void
		{
			//trace("LoadConfigCommand - execute - notification: " + notification);
			_configProxy = facade.retrieveProxy( ConfigProxy.NAME ) as ConfigProxy;
			_layoutProxy = facade.retrieveProxy( LayoutProxy.NAME ) as LayoutProxy;
			_mediaProxy = facade.retrieveProxy( MediaProxy.NAME ) as MediaProxy;

			_flashvars = _configProxy.vo.flashvars;
			
							
			// if the wrapper embedded data was valid we can immidiately start working on the layout
			// without sending a get widget request.
			// in this case an flashvar given entry will be fetched in a later stage since we dont
			// want to wait for a multirequest now but rather show the ui asap
			var usedEmbeddedData:Boolean = useEmbeddedData();
			if (usedEmbeddedData)
			{
				if (_flashvars.entryId && _flashvars.entryId != "-1")					
					_mediaProxy.vo.entry.id = _flashvars.entryId;
					
				_flashvars.widgetId = _configProxy.vo.kw.id;
				fetchLayout();
				return;
			}
			
			if(_flashvars.widgetId == null)
			{
				_configProxy.vo.kw = new KalturaWidget();
				fetchLayout();
				return;
			}	
			
			if(_flashvars.sourceType == SourceType.URL)
			{
				fetchLayout();
				return;
			} 
			
			//get a hold on the kaltura client
			_kc = ( facade.retrieveProxy( ServicesProxy.NAME ) as ServicesProxy ).kalturaClient;
			
			//start a multi request to get session if needed widget and uiconf
			var mr : MultiRequest = new MultiRequest();
				
			//if there is no ks we need to call first to create widget session
			if(!_flashvars.ks)
			{
				var ssws : SessionStartWidgetSession = new SessionStartWidgetSession( _flashvars.widgetId );
				mr.addAction( ssws );
				
				//use the ks result in Start Widget Session in the next 3 calls
				mr.addRequestParam("2:ks","{1:result:ks}");
				mr.addRequestParam("3:ks","{1:result:ks}");
				mr.addRequestParam("4:ks","{1:result:ks}");
				mr.addRequestParam("5:ks","{1:result:ks}");
				mr.addRequestParam("6:ks","{1:result:ks}");
				if (_flashvars.requiredMetadataFields)
				{
					mr.addRequestParam("7:ks","{1:result:ks}");
				}
			}
			else
			{
				_kc.ks = _flashvars.ks;
			}

			//Get Widget 
			var widgetGet:WidgetGet = new WidgetGet(_flashvars.widgetId);
			mr.addAction( widgetGet );
			
			var uiconfGet : UiConfGet;
			//if we don't have uiconfid on the flashvar try to get it from the getWidget call
			if (_flashvars.uiConfId == undefined)
			{
				uiconfGet = new UiConfGet(NaN);
				if(!_flashvars.ks)
					mr.mapMultiRequestParam(2,"uiConfId",3,"id");
				else
					mr.mapMultiRequestParam(1,"uiConfId",2,"id");
			}
			else //we have the uiconfid in flashvars
			{
				uiconfGet = new UiConfGet(int(_flashvars.uiConfId));
			}
			
			mr.addAction( uiconfGet );
			
			if(_flashvars.sourceType == SourceType.ENTRY_ID && _flashvars.entryId && _flashvars.entryId != "-1")
			{
				//TODO: Change get entry when we will add mix support
				var getEntry : BaseEntryGet = new BaseEntryGet(_flashvars.entryId);
				mr.addAction( getEntry );
				
				//Get Flavors
 				var getFlavors:FlavorAssetGetWebPlayableByEntryId= new FlavorAssetGetWebPlayableByEntryId(_flashvars.entryId);
	            mr.addAction(getFlavors); 
	            
	            var keedp : KalturaEntryContextDataParams  = new KalturaEntryContextDataParams();
	            keedp.referrer = _flashvars.referrer;
	            var getExtraData : BaseEntryGetContextData = new BaseEntryGetContextData( _flashvars.entryId , keedp );
	            mr.addAction(getExtraData); 
				if (_flashvars.requiredMetadataFields)
				{
					var metadataAction : KalturaCall;
					
					if (_flashvars.metadataProfileId)
					{
						metadataAction = new MetadataGet ( _flashvars.metadataProfileId );
					}
					else
					{
						var metadataFilter : KalturaMetadataFilter = new KalturaMetadataFilter();
						
						metadataFilter.metadataObjectTypeEqual = KalturaMetadataObjectType.ENTRY;
						
						metadataFilter.orderBy = KalturaMetadataOrderBy.CREATED_AT_ASC;
						
						metadataFilter.objectIdEqual = _mediaProxy.vo.entry.id;
						
						var metadataPager : KalturaFilterPager = new KalturaFilterPager();
						
						metadataPager.pageSize = 1;
						
						metadataAction = new MetadataList(metadataFilter,metadataPager);
					}
				
					mr.addAction(metadataAction);
				}
	              
		  	}  	
			
           
			mr.addEventListener( KalturaEvent.COMPLETE , result );
			mr.addEventListener( KalturaEvent.FAILED , fault );
		
			_kc.post( mr );
			/////////////////////////////////////////////	
		}
		
		/**
		 * When the multi request to kaltura is done we get a hold on the result
		 * and KDP model 
		 * @param data
		 * 
		 */		
		public function result(data:Object):void
		{
			var i : int = 0;
			var arr : Array = data.data as Array;
			
			var flashvars : Object = (facade.retrieveProxy(ConfigProxy.NAME) as ConfigProxy).vo.flashvars;
			
			//ifd we didn't got the ks from the flashvars we have a result on start widger session
			if(!_kc.ks)
			{
				if(arr[i] is KalturaError)
				{
					++i; //procced anyway
					//TODO: Trace, Report, and notify the user
					trace("Error in Start Widget Session");
					//sendNotification( NotificationType.ALERT , {message: DefaultStrings.SERVICE_START_WIDGET_ERROR, title: DefaultStrings.SERVICE_ERROR} );
				}
				else
				{	
					var kws : KalturaStartWidgetSessionResponse = arr[i++];
					_kc.ks = kws.ks;
				}
			}
			
			if(arr[i] is KalturaError)
			{
				++i; //procced anyway
				//TODO: Trace, Report, and notify the user
				trace("Error in Get Widget");
				//sendNotification( NotificationType.ALERT , {message: DefaultStrings.SERVICE_GET_WIDGET_ERROR, title: DefaultStrings.SERVICE_ERROR} );
			}
			else
			{
				//set the config proxy with the new kalture widget
				var kw : KalturaWidget = arr[i++];
				_configProxy.vo.kw = kw;
			}
		
			if(arr[i] is KalturaError)
			{
				++i; //procced anyway
				//TODO: Trace, Report, and notify the user
				trace("Error in Get UIConf");
				//sendNotification( NotificationType.ALERT , {message: DefaultStrings.SERVICE_GET_UICONF_ERROR, title: DefaultStrings.SERVICE_ERROR} );
			}
			else
			{
				//set the config proxy with the new kalture uiconf 
				var kuiConf : KalturaUiConf = arr[i++];
				_configProxy.vo.kuiConf = kuiConf;
			}
				
			if(_flashvars.sourceType != SourceType.URL)
			{
				if(_flashvars.entryId && _flashvars.entryId != "-1")
				{
					if(arr[i] is KalturaError)
					{
						++i; //procced anyway
						trace("Error in Get Entry");
						//sendNotification( NotificationType.ALERT , {message: DefaultStrings.SERVICE_GET_ENTRY_ERROR, title: DefaultStrings.SERVICE_ERROR} );
						//hasError = true;
					}
					else
					{
						//TODO: if mix...
						_mediaProxy.vo.entry = arr[i++];
						_mediaProxy.vo.entryLoadedBeforeChangeMedia = true;
						if(_mediaProxy.vo.entry is KalturaLiveStreamEntry)
						{
							_mediaProxy.vo.deliveryType = StreamerType.LIVE;
						}
						else
						{
							_mediaProxy.vo.deliveryType = flashvars.streamerType;
						}
					}
					
		 			if(arr[i] is KalturaError)
					{
						++i; //procced anyway
						trace("Error in Get Flavors");
						
						//if this is live entry we will create the flavors using 
						if( _mediaProxy.vo.entry is KalturaLiveStreamEntry )
						{
							var flavorAssetArray : Array = new Array(); 
							for(var j:int=0; j<_mediaProxy.vo.entry.bitrates.length; j++)
							{
								var flavorAsset : KalturaFlavorAsset = new KalturaFlavorAsset();
								flavorAsset.bitrate = _mediaProxy.vo.entry.bitrates[j].bitrate;
								flavorAsset.height = _mediaProxy.vo.entry.bitrates[j].height;
								flavorAsset.width = _mediaProxy.vo.entry.bitrates[j].width;
								flavorAsset.entryId = _mediaProxy.vo.entry.id;
								flavorAsset.isWeb = true;
								flavorAsset.id = j.toString();
								flavorAsset.partnerId = _mediaProxy.vo.entry.partnerId;
								flavorAssetArray.push(flavorAsset);
							}
							
							if(j>0)
								_mediaProxy.vo.kalturaMediaFlavorArray = flavorAssetArray;
							else
								_mediaProxy.vo.kalturaMediaFlavorArray = null;
						}
						else
						{
							_mediaProxy.vo.kalturaMediaFlavorArray = null;
							//sendNotification( NotificationType.ALERT , {message: DefaultStrings.SERVICE_GET_FLAVORS_ERROR, title: DefaultStrings.SERVICE_ERROR} );
						}
					}
					else
					{
						_mediaProxy.vo.kalturaMediaFlavorArray = arr[i++];
					} 
					
					if(arr[i] is KalturaError)
					{
						++i; //procced anyway
						//TODO: Trace, Report, and notify the user
						trace("Error in Get Extra Params");
						//sendNotification( NotificationType.ALERT , {message: DefaultStrings.SERVICE_GET_EXTRA_ERROR, title: DefaultStrings.SERVICE_GET_EXTRA_ERROR_TITLE} );
					}
					else
					{
						_mediaProxy.vo.entryExtraData = arr[i++];
					} 
					if(arr[i] is KalturaError)
					{
						++i;
						trace("Error in Get metadata");
					}
					else
					{
						var mediaProxy : MediaProxy = facade.retrieveProxy(MediaProxy.NAME) as MediaProxy;
						
						mediaProxy.vo.entryMetadata = new Object();
						
						var listResponse : KalturaMetadataListResponse = arr[i++] as KalturaMetadataListResponse;
						if (listResponse && listResponse.objects[listResponse.objects.length - 1])
						{
							var metadataXml : XMLList = XML(listResponse.objects[listResponse.objects.length - 1]["xml"]).children();
							var metaDataObj : Object = new Object();
							for each (var node : XML in metadataXml)
							{
								if (!metaDataObj.hasOwnProperty(node.name().toString()))
								{
									metaDataObj[node.name().toString()] = node.valueOf().toString();
								}
								else
								{
									if (metaDataObj[node.name().toString()] is Array)
									{
										(metaDataObj[node.name().toString()] as Array).push(node.valueOf().toString());
									}
									else
									{
										metaDataObj[node.name().toString()] =new Array ( metaDataObj[node.name().toString()]);
										(metaDataObj[node.name().toString()] as Array).push(node.valueOf().toString() );
									}
								}
							}
							mediaProxy.vo.entryMetadata = metaDataObj;
						}
						sendNotification(NotificationType.METADATA_RECEIVED);
					}
				} 
				
			}

			fetchLayout();			
		}
		
		public function fault(data:Object):void
		{
			trace("LoadConfigCommand==>fault");
			commandComplete(); //execute next command
		}
		
		//PRIVATE FUNCTIONS
		/////////////////////////////////////////////
		
		public function fetchLayout():void
		{
			//if we inject the xml through the init( kml : XML ) function in kdp3 class 
			//we can setLayout xml right away
			if( _flashvars.kml == INJECT )
			{
				setLayout( _layoutProxy.vo.layoutXML );
			}
			else if( _flashvars.kml == LOCAL ) //if we want to load local XML (DEBUG USE ONLY)
			{
				var loader : URLLoader;
				
				if(_flashvars.kmlPath == null) //if we don't have kmlPath in flashvars
					_flashvars.kmlPath = 'config.xml'
					
				
				loader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, XMLLoaded ); 
				loader.addEventListener(IOErrorEvent.IO_ERROR , onIOError);
				loader.load( new URLRequest(_flashvars.kmlPath) );
				//Only after XML was loaded we move on...
			}
			else //set the layout proxy with the new uiconf xml
			{
				setLayout(XML(_configProxy.vo.kuiConf.confFile));
			}
		}
		
		//We must implement IO Eroor to any case somwone is closing the browser in the middle of
		//Loading, if not it might crash the browser.
		private function onIOError( event : Event ) : void
		{
			
		}
		
		/**
		 * Add a plugin xml (e.g. <Plugin id=tremor width="100%" ... />) into the given layout
		 * The insert position in set using the relativeTo and position parameres.
		 * If both attributes are ommited the plugin is prepended to the first child of the layout.
		 * This would be probably be a non visual plugin
		 * Builtin components can be added as well by specfying a className attribute such as Button, Label etc.. 
		 * @param layoutXML the whole kdp layout
		 * @param pluginXML the plugin xml including the relativeTo and position attributes
		 * 
		 */
		private function appendPluginToLayout(layoutXML:XML, pluginXML:XML):void
		{
			//trace(pluginXML.toXMLString());
			
			var relativeTo:String = pluginXML.@relativeTo; 
			var position:String = pluginXML.@position; 
			
			var parentNode:XML;
			
			if (relativeTo)
			{
				var className:String = pluginXML.@className;
				if (className)
				{
					pluginXML.setName(className);
					delete (pluginXML.@className);	
				}
				
				delete (pluginXML.@relativeTo);
				delete (pluginXML.@position);

				var xml:XML = layoutXML.descendants().(attribute("id") == relativeTo)[0];
				if (xml == null)
				{
					trace("ERROR: plugin ", pluginXML.@id, " - couldnt find relativeTo component " + relativeTo);
				}
				else if (position == "before")
				{
					parentNode = xml.parent();
					parentNode.insertChildBefore(xml, pluginXML);
				}
				else if (position == "after")
				{
					parentNode = xml.parent();
					parentNode.insertChildAfter(xml, pluginXML);
				}
				else if (position == "firstChild")
				{
					xml.prependChild(pluginXML);
				}
				else if (position == "lastChild")
				{
					xml.appendChild(pluginXML);
				}
				else {
					trace("ERROR: plugin ", pluginXML.@id, " - invalid position " + position);
				}
			}
			else
			{
				parentNode = layoutXML.children()[0];
				parentNode.prependChild(pluginXML);
			}
		}
		
		/**
		 * Append plugins to the layout from flashvars and plugins segment within the layout xml.
		 * Look for all flashvars with .plugin attribute and treat them as plugins
		 * The id of the given plugin is the flashvars prefix
		 * Insert all children of the <plugins> segment of the layout xml as well
		 * @param layoutXML the whole kdp layout
		 * 
		 */
		private function appendPluginsToLayout(layoutXML:XML):void
		{
			for each(var pluginXML:XML in layoutXML..plugins.children())
			{
				appendPluginToLayout(layoutXML, pluginXML);
			}
			
			for(var pluginName:String in _flashvars)
			{
				var pluginParams:Object = _flashvars[pluginName];
				if (pluginParams.hasOwnProperty('plugin'))
				{
					pluginXML  = new XML("<Plugin/>");
					pluginXML.@['id'] = pluginName;
					
					//trace("build plugin xml for " + pluginName);
					
					for(var s:String in pluginParams)
						pluginXML.@[s] = pluginParams[s];
						
					appendPluginToLayout(layoutXML, pluginXML);
				}
			}
		}
		
		/**
		 * Converts all flashvars with dot syntax (e.g. watermark.path) to objects 
		 * 
		 */
		private function buildFlashvarsTree():void
		{
			// assemble list of all dotted vars since we shouldn't change the list while iterting it
			var dottedVars:Array = new Array();
			
			for(var s:String in _flashvars)
			{
				if (s.indexOf(".") >= 0)
					dottedVars.push(s);
			}
				
			for each(s in dottedVars)
			{				
				var subParams:Array = s.split(".");
				var root:* = _flashvars;
				for(var i:int = 0; i < subParams.length - 1; ++i)
				{
					if (!root[subParams[i]])
						root[subParams[i]] = new Object();
					
					root = root[subParams[i]];
				}
				
				root[subParams[i]] = _flashvars[s];
				delete(_flashvars[s]);
			}
		}
		
		/**
		 * Add variables from an XMLList to the flashvars array.
		 * The XMLList is of the form <var key="name" value="value" overrideFlashvar="[true/false]" />
		 * if the variable already appears in flashvars and it wasnt marked as overrideFlashvar="true"
		 * the flashvars original value will persist.
		 * @param layoutXML the layout xml 
		 * @param prefix a dotted prefix to prepend before the variable key name  
		 * 
		 */
		private function addLayoutVars(xmlList:XMLList, prefix:String = ""):void
		{
			// local uiVars overriding the original flashyvars
			for each (var uiVar:XML in xmlList)
			{
				var key:String = prefix + uiVar.@key.toString();
				var value:String = uiVar.@value.toString();
				
				//check if this variable already exists in flashvars and whether it needs to be overriden
				if (!_flashvars.hasOwnProperty(key) || uiVar.@overrideFlashvar == "true")
					_flashvars[key] = value;
			}
		}
		
		/**
		 * override layout and proxy attributes using flashvars
		 * originally dotted variables are now container objects (after calling buildFlashvarsTree).
		 * these parameters override components using their id's as the first part of the flashvar dotted name
		 * if a component wasnt found we try to retrieve a proxy object with the container name (e.g. mediaProxy)   
		 * @param layoutXML the whole kdp layout
		 * 
		 */
		private function overrideAttributes(layoutXML:XML):void
		{
			for(var s:String in _flashvars)
			{
				var fvKeyObject:Object = _flashvars[s];
				if (!(fvKeyObject is String) && !fvKeyObject.hasOwnProperty('plugin'))
				{
					var xml:XML = layoutXML.descendants().(attribute("id") == s)[0];
					if (xml)
					{
						for(var key:String in fvKeyObject)  
							xml.@[key] = fvKeyObject[key]; 
					}
					else
					{
						var proxy:Proxy = facade.retrieveProxy( s ) as Proxy;
						if (proxy)
						{
							try {
								var data:Object = proxy.getData();
								for(key in fvKeyObject)  
									data[key] = fvKeyObject[key];
							}
							catch(e:Error)
							{
								trace("overrideAttributes failed to set attribute ", s, key);
							}
						}
					}
				}
			}
		}
		
		/**
		 * analyzes the layout xml:
		 * 1. add strings and uiVars sections to flashvars
		 * 2. add partner data variables from retrieved widget
		 * 3. convert all flashvars with dot syntax (e.g. watermark.path) to objects 
		 * 4. append plugins into actual layout from flashvars and plugins section
		 * 
		 * @param xml the layout xml received from either uiconf or local configuration
		 * 
		 */
		private function setLayout(xml:XML):void
		{
			// add a top level layouts node so our searches within the xml will find
			// the layout node itself (for overriding skinPath) and not only its descendants
			xml = new XML("<layouts>" + xml.toString() + "</layouts>");
			
			// add the strings section of the layout to the flashvars
			addLayoutVars(xml..strings.children(), "strings.");
			
			// add variables from the uiVars section of the layout to the flashvars
			addLayoutVars(xml..uiVars.children());
			
			// add partner data variables from retrieved widget
			var kw:KalturaWidget = _configProxy.vo.kw;
			//kw.partnerData = '<xml><uiVars><var key="pageName" value="my blog post" /><var key="pageUrl" value="http://my.blog.com/blog?article=1234" /></uiVars></xml>';
			
			if (kw && kw.partnerData)
			{
				addLayoutVars(XML(kw.partnerData).uiVars.children());
			}
			
			// convert all flashvars with dot syntax (e.g. watermark.path) to objects
			buildFlashvarsTree();

			// append plugins to the layout from flashvars and plugins segment within the layout xml			
			appendPluginsToLayout(xml);
			
			// override layout and proxy variables using flashvars
			overrideAttributes(xml);
			
			_layoutProxy.vo.layoutXML = xml.child(0)[0];
			
			//Load plugin with loadingPolicy="preInitialize"
			loadPreInitPlugins ();
			
			
		}
		
		//on kml=local mode if we load the kml localy
		private function XMLLoaded( event : Event) : void
		{
			setLayout(new XML(event.target.data));
		}
		/**
		 * 
		 * 
		 */		
		private function loadPreInitPlugins () : void
		{
			var layoutXml : XML = _layoutProxy.vo.layoutXML;
			var plugins : XMLList = layoutXml..Plugin.(attribute("loadingPolicy") == "preInitialize");
			
			var uiComponent : UIComponent;
			_layoutProxy.numPreInitPlugins = plugins.length();
			var plugin : XML;
			for ( var i:int=0; i<plugins.length(); i++)
			{
				plugin=plugins[i];
				_layoutProxy.loadPreInitPlugin(plugins[i]);
				delete(plugins[i]);
			}
			
			
			var pm : PluginManager = PluginManager.getInstance();
			pm.updateAllLoaded(preInitPluginsLoaded);
			
		}
		
		private function preInitPluginsLoaded (e : Event ) : void
		{
			commandComplete();
		}
		
	}
}