package com.kaltura.kdpfl.view
{
	
	import com.kaltura.KalturaClient;
	import com.kaltura.commands.MultiRequest;
	import com.kaltura.commands.annotation.AnnotationAdd;
	import com.kaltura.commands.annotation.AnnotationGet;
	import com.kaltura.commands.annotation.AnnotationList;
	import com.kaltura.events.KalturaEvent;
	import com.kaltura.kdpfl.model.ServicesProxy;
	import com.kaltura.kdpfl.model.type.NotificationType;
	import com.kaltura.kdpfl.util.KAstraAdvancedLayoutUtil;
	import com.kaltura.kdpfl.view.events.AnnotationEvent;
	import com.kaltura.kdpfl.view.media.KMediaPlayer;
	import com.kaltura.kdpfl.view.media.KMediaPlayerMediator;
	import com.kaltura.kdpfl.view.strings.AnnotationStrings;
	import com.kaltura.kdpfl.view.strings.Notifications;
	import com.kaltura.vo.KalturaAnnotation;
	import com.kaltura.vo.KalturaAnnotationBaseFilter;
	import com.kaltura.vo.KalturaAnnotationFilter;
	
	import fl.core.UIComponent;
	import fl.data.DataProvider;
	
	import flash.events.Event;
	import flash.net.SharedObject;
	
	import org.osmf.events.TimelineMetadataEvent;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaPlayer;
	import org.osmf.metadata.TimelineMarker;
	import org.osmf.metadata.TimelineMetadata;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	import org.puremvc.as3.patterns.observer.Notification;
	
	public class AnnotationBoxMediator extends Mediator
	{
		public static const NAME : String = "annotationBoxMediator";
		
		protected var _unsavedAnnotationSO : Array;
		protected var _player : MediaPlayer;
		protected var _timelineMetadata : TimelineMetadata;
		protected var _entryId : String = "0";
		protected var _sessionId : String = "";
		protected var _userModeBeforeFS : String;
		
		/**
		 * Saved annotations shared object prefix. 
		 */		
		public static const ANNOTATIONS_SO_PREFIX : String = "KalturaSavedAnnotations_"
		
		public function AnnotationBoxMediator(viewComponent:Object=null )
		{
			super(NAME, viewComponent);
			createListeners();
		}
		
		protected function createListeners () : void
		{
			(viewComponent as annotationsPluginCode).annotationsBox.addEventListener(AnnotationEvent.DELETE_ANNOTATION, onAnnotationDeleted); 
			
			(viewComponent as annotationsPluginCode).annotationsBox.addEventListener(AnnotationEvent.EDIT_ANNOTATION, onAnnotationEdit);
			
			(viewComponent as annotationsPluginCode).annotationsBox.addEventListener(AnnotationEvent.SEEK_TO_ANNOTATION, onAnnotationClick);
		}
		
		override public function listNotificationInterests():Array
		{
			var interests : Array = [Notifications.ADD_ANNOTATION, Notifications.EDIT_ANNOTATION, Notifications.CANCEL_ANNOTATION, 
				Notifications.ANNOTATION_DELETED, Notifications.SAVE_ANNOTATION, Notifications.LOAD_FEEDBACK_SESSION, Notifications.LOAD_LOCAL_SAVED_ANNOTATIONS,Notifications.RESET_ANNOTATIONS_COMPONENT,
				NotificationType.LAYOUT_READY, NotificationType.MEDIA_LOADED, NotificationType.ENTRY_READY, Notifications.SUBMIT_FEEDBACK_SESSION, NotificationType.HAS_OPENED_FULL_SCREEN, NotificationType.HAS_CLOSED_FULL_SCREEN, NotificationType.PLAYER_PLAY_END];
			return interests;
		}
		
		override public function handleNotification(notification:INotification):void
		{

			var name : String = notification.getName();
			var index : int;
			var currentTime : Number;
			var currEntryId : String = facade.retrieveProxy("mediaProxy")["vo"]["entry"]["id"];
			switch (name)
			{
				case NotificationType.LAYOUT_READY:
					_player = facade.retrieveMediator("kMediaPlayerMediator")["player"] as MediaPlayer;
					break;
				case NotificationType.ENTRY_READY:
					
					if (currEntryId != _entryId)
					{
						_entryId = currEntryId;
					}
					if ( (viewComponent as annotationsPluginCode).userMode == AnnotationStrings.REVIEWER )
					{
						configureLocalSavedAnnotations ();
					}
					else
					{
						loadFeedbackSession ();
						(viewComponent as annotationsPluginCode).removeEventListener(AnnotationStrings.ANNOTATIONS_LIST_CHANGED_EVENT, saveAnnotationsToLocalObject )
					}
						
					
					break;
				case NotificationType.MEDIA_LOADED:
					var currMedia : MediaElement = facade.retrieveProxy("mediaProxy")["vo"]["media"];
					if (currMedia && currEntryId==_entryId)
					{
						initTimelineMetadata();
					}
					if ((viewComponent as annotationsPluginCode).annotationsBox.dataProvider.toArray().length )
					{
						var dpArray : Array = (viewComponent as annotationsPluginCode).annotationsBox.dataProvider.toArray();
						for (var i:int = 0; i<dpArray.length; i++)
						{
							addTimelineMarker( (dpArray[i]["annotation"] as Annotation).inTime );
						}
					}
					break;
				
				case Notifications.SUBMIT_FEEDBACK_SESSION:
					
					var kAnnotationArray : Array = (viewComponent as annotationsPluginCode).annotationsBox.annotationsAsKalturaAnnotationArray;
					
					if (kAnnotationArray && kAnnotationArray.length != 0 && _entryId && _entryId != "" && _entryId != "-1")
					{
						submitFeedbackSession (kAnnotationArray);
					}
					
					break;
				
				case Notifications.LOAD_LOCAL_SAVED_ANNOTATIONS:
					
					if (!(viewComponent as annotationsPluginCode).showAnnotationsPlugin)
					{
						(viewComponent as annotationsPluginCode).showAnnotationsPlugin = true;
					}
					
					for (index =0; index< _unsavedAnnotationSO.length; index++)
					{
						var annotationObj : Object = _unsavedAnnotationSO[index];
						
						var unsavedAnnotation : Annotation = new Annotation(AnnotationStrings.VIEW_MODE, annotationObj["inTime"],annotationObj["annotationText"], annotationObj["entryId"]);
						
						(viewComponent as annotationsPluginCode).annotationsBox.addAnnotation(unsavedAnnotation);
						
						addTimelineMarker( unsavedAnnotation.inTime);
					}
					
					sendNotification("receivedCuePoints", (viewComponent as annotationsPluginCode).annotationsBox.millisecTimesArray );
					
					(viewComponent as annotationsPluginCode).addEventListener(AnnotationStrings.ANNOTATIONS_LIST_CHANGED_EVENT, saveAnnotationsToLocalObject);
					
					break;
				
				
				case Notifications.ADD_ANNOTATION:
					
					if (_entryId && _entryId != "" && _entryId != "-1")
					{
					
						sendNotification( NotificationType.DO_PAUSE );
						
						if (!(viewComponent as annotationsPluginCode).showAnnotationsPlugin)
						{
							(viewComponent as annotationsPluginCode).showAnnotationsPlugin = true;
						}
						var n_annotation : Annotation = new Annotation(AnnotationStrings.EDIT_MODE, -1, Annotation.ANNOTATION_PROMPT, _entryId);
	
						(viewComponent as annotationsPluginCode).gotoEditMode();
						(viewComponent as annotationsPluginCode).annotationEditForm.openAnnotationForEditing(n_annotation);
					}
					
					break;
				
				case Notifications.LOAD_FEEDBACK_SESSION:
					(viewComponent as annotationsPluginCode).annotationsBox.reset();
					
					(viewComponent as annotationsPluginCode).userMode = AnnotationStrings.CANDIDATE;
					
					_sessionId = notification.getBody().sessionId;
					
					var kc : KalturaClient = (facade.retrieveProxy(ServicesProxy.NAME) as ServicesProxy).kalturaClient;
					
					var sessionParentRequest : AnnotationGet = new AnnotationGet(_sessionId);
					
					sessionParentRequest.addEventListener(KalturaEvent.COMPLETE,onParentAcquired);
					sessionParentRequest.addEventListener(KalturaEvent.FAILED, onParentFeedbackFailed );
					kc.post(sessionParentRequest);
					break;
					
					
					
				
				case Notifications.EDIT_ANNOTATION:
					var editAnnotation : Annotation = notification.getBody().annotation;
					KAstraAdvancedLayoutUtil.removeFromLayout((viewComponent as annotationsPluginCode).annotationsBox, editAnnotation);
					(viewComponent as annotationsPluginCode).gotoEditMode();
					(viewComponent as annotationsPluginCode).annotationEditForm.openAnnotationForEditing(editAnnotation);
					break;
				
				case Notifications.SAVE_ANNOTATION:
					currentTime = Math.floor(_player.currentTime);
					var currTimeIndex:int = (viewComponent as annotationsPluginCode).annotationsBox.findIndexByInTime(currentTime);
					
					if (currTimeIndex != -1 && (viewComponent as annotationsPluginCode).annotationsBox.findIndexByAnnotation((viewComponent as annotationsPluginCode).annotationEditForm.annotation)== -1)
					{
						(viewComponent as annotationsPluginCode).annotationsBox.dispatchEvent(new Event(AnnotationStrings.INVALID_ANNOTATION_INTIME_EVENT, true) );
						return;
					}
					
					var savedAnnotation : Annotation = (viewComponent as annotationsPluginCode).annotationEditForm.returnValidAnnotation(currentTime);
					if (savedAnnotation)
					{
						index = (viewComponent as annotationsPluginCode).annotationsBox.findIndexByAnnotation(savedAnnotation);
						if (index != -1)
						{
							KAstraAdvancedLayoutUtil.appendToLayoutAt((viewComponent as annotationsPluginCode).annotationsBox, savedAnnotation, index, 100, 100);
							saveAnnotationsToLocalObject();
						}
						else
						{
							addTimelineMarker(savedAnnotation.inTime);
							(viewComponent as annotationsPluginCode).annotationsBox.addAnnotation(savedAnnotation);
							
						}
						(viewComponent as annotationsPluginCode).gotoViewMode();
						
					}
					sendNotification("receivedCuePoints", (viewComponent as annotationsPluginCode).annotationsBox.millisecTimesArray );
					break;
				
				case Notifications.CANCEL_ANNOTATION:
					var returnedAnnotation : Annotation = (viewComponent as annotationsPluginCode).annotationEditForm.canceledAnnotation();
					if (returnedAnnotation)
					{
						index = (viewComponent as annotationsPluginCode).annotationsBox.findIndexByAnnotation(returnedAnnotation);
						if (index != -1)
						{
							KAstraAdvancedLayoutUtil.appendToLayoutAt((viewComponent as annotationsPluginCode).annotationsBox, returnedAnnotation, index, 100, 100);
						}
						(viewComponent as annotationsPluginCode).gotoViewMode();
					}
					
					if ( (viewComponent as annotationsPluginCode).annotationsBox.dataProvider.length == 0 )
					{
						(viewComponent as annotationsPluginCode).showAnnotationsPlugin = false;
					}
					break;
				
				case Notifications.ANNOTATION_DELETED:
					var removedAnnotation : Annotation = notification.getBody().annotation as Annotation;
					removeTimelineMarker(removedAnnotation.inTime );
					if ( (viewComponent as annotationsPluginCode).annotationsBox.dataProvider.length == 0 )
					{
						(viewComponent as annotationsPluginCode).showAnnotationsPlugin = false;
					}
					sendNotification("receivedCuePoints", (viewComponent as annotationsPluginCode).annotationsBox.millisecTimesArray );
					break;
				case NotificationType.HAS_OPENED_FULL_SCREEN:

						_userModeBeforeFS = (viewComponent as annotationsPluginCode).userMode;
						(viewComponent as annotationsPluginCode).userMode = AnnotationStrings.CANDIDATE;

					break;
				case NotificationType.HAS_CLOSED_FULL_SCREEN:

						(viewComponent as annotationsPluginCode).userMode = _userModeBeforeFS;
						trace (_userModeBeforeFS);

					break;
				case Notifications.RESET_ANNOTATIONS_COMPONENT:
					resetAnnotationComponent();
					break;
				case NotificationType.PLAYER_PLAY_END:
					(viewComponent as annotationsPluginCode).annotationsBox.scrollToInTime((viewComponent as annotationsPluginCode).annotationsBox.dataProvider.getItemAt(0).inTime);
					break;
			}
			
			
		}
		/**
		 * Function is in charge of loading the entry associated with the loaded feedback session.
		 * @param e - KalturaEvent
		 * 
		 */		
		protected function onParentAcquired (e : KalturaEvent) : void
		{
			
			sendNotification(NotificationType.CHANGE_MEDIA, {entryId : (e.data as KalturaAnnotation).entryId});
		}
		/**
		 * Handler for a failed
		 * @param e
		 * 
		 */		
		protected function onParentFeedbackFailed (e : KalturaEvent) : void
		{
			trace ("feedback session load failed");
			sendNotification(NotificationType.ALERT, {message: AnnotationStrings.INVALID_FEEDBACK_SESSION_MESSAGE, title: AnnotationStrings.INVALID_FEEDBACK_SESSION_TITLE} );
		}
		/**
		 * 
		 * @param e
		 * 
		 */		
		protected function onAnnotationDeleted (e : AnnotationEvent) : void
		{
			(viewComponent as annotationsPluginCode).annotationsBox.removeAnnotation(e.annotation);
			sendNotification(Notifications.ANNOTATION_DELETED, {annotation: e.annotation});
		}
		/**
		 * 
		 * @param e
		 * 
		 */		
		protected function onAnnotationEdit (e : AnnotationEvent) : void
		{
			sendNotification(Notifications.EDIT_ANNOTATION, {annotation : e.annotation} );
		}
		
		protected function onAnnotationClick ( e : AnnotationEvent ) : void
		{
			sendNotification (Notifications.SKIP_TO_ANNOTATION_TIME, {time : e.annotation.inTime})
			sendNotification (NotificationType.DO_SEEK, e.annotation.inTime);
		}
		
		protected function initTimelineMetadata () : void
		{
			_timelineMetadata = new TimelineMetadata(_player.media);
			_timelineMetadata.addEventListener(TimelineMetadataEvent.MARKER_TIME_REACHED, onMarkerReached );
		}
		
		protected function addTimelineMarker (inTime : Number) : void
		{
			if (_timelineMetadata)
			{
				_timelineMetadata.addMarker(new TimelineMarker(inTime) );
			}
			
		}
		
		protected function removeTimelineMarker ( inTime : Number) : void
		{
			if (_timelineMetadata)
			{
				_timelineMetadata.removeMarker(new TimelineMarker(inTime) );
			}
		}
		
		protected function onMarkerReached (e : TimelineMetadataEvent) : void
		{
			
			(viewComponent as annotationsPluginCode).annotationsBox.scrollToInTime(e.marker.time);
		}

		
		protected function configureLocalSavedAnnotations () : void
		{
			if ((viewComponent as annotationsPluginCode).hasEventListener(AnnotationStrings.ANNOTATIONS_LIST_CHANGED_EVENT) )
			{
				(viewComponent as annotationsPluginCode).removeEventListener(AnnotationStrings.ANNOTATIONS_LIST_CHANGED_EVENT, saveAnnotationsToLocalObject )
			}
			
			(viewComponent as annotationsPluginCode).annotationsBox.reset();
			try{
				var so : SharedObject = SharedObject.getLocal(ANNOTATIONS_SO_PREFIX + _entryId);
			}
			catch (e : Error)
			{
				
			}
			_unsavedAnnotationSO = so? so.data.savedAnnotations as Array : new Array();
			
			if (_unsavedAnnotationSO && _unsavedAnnotationSO.length != 0)
			{
				sendNotification(Notifications.LOAD_LOCAL_SAVED_ANNOTATIONS);
			}
			else
			{
				_unsavedAnnotationSO = new Array();
				
				sendNotification ("receivedCuePoints", new Array());
				
				(viewComponent as annotationsPluginCode).showAnnotationsPlugin = false;
				
				(viewComponent as annotationsPluginCode).addEventListener(AnnotationStrings.ANNOTATIONS_LIST_CHANGED_EVENT, saveAnnotationsToLocalObject);
			}
		}
		
		protected function saveAnnotationsToLocalObject (e : Event = null) : void 
		{
			_unsavedAnnotationSO = (viewComponent as annotationsPluginCode).annotationsBox.getAllObjectsInFieldAsArray("annotation");
			try
			{
				SharedObject.getLocal(ANNOTATIONS_SO_PREFIX + _entryId).data.savedAnnotations = _unsavedAnnotationSO;
				SharedObject.getLocal(ANNOTATIONS_SO_PREFIX + _entryId).flush();
			}
			catch (e : Error)
			{
				
			}
		}
		
		/**
		 * Function contains the logic which submits the annotations currently found in the 
		 * annotations box and submits it to the server as a feedback session. 
		 * @param kalturaAnnotationsArray - the array of the annotations currently found in the annotations box.
		 * 
		 */		
		protected function submitFeedbackSession (kalturaAnnotationsArray : Array) : void
		{
			var kalturaClient : KalturaClient = (facade.retrieveProxy(ServicesProxy.NAME) as ServicesProxy).kalturaClient;
			
			var parentAnnotation : KalturaAnnotation = new KalturaAnnotation();
			parentAnnotation.entryId = _entryId;
			
			var createParentAnnotation : AnnotationAdd = new AnnotationAdd(parentAnnotation);
			
			createParentAnnotation.addEventListener(KalturaEvent.COMPLETE, onParentAnnotationCreated );
			createParentAnnotation.addEventListener(KalturaEvent.FAILED, onCreateParentAnnotationFailed);
			kalturaClient.post(createParentAnnotation);
			
			function onParentAnnotationCreated (e : KalturaEvent) : void
			{
				var parentId : String = (e.data as KalturaAnnotation).id;
				var submitAnnotationsMultiRequest : MultiRequest = new MultiRequest();
				var addAnnotationToParent : AnnotationAdd;
				
				for (var i:int =0; i< kalturaAnnotationsArray.length; i++)
				{
					var currentAnnotationToAdd : KalturaAnnotation = kalturaAnnotationsArray[i];
					currentAnnotationToAdd.parentId = parentId;
					addAnnotationToParent = new AnnotationAdd(currentAnnotationToAdd);
					submitAnnotationsMultiRequest.addAction(addAnnotationToParent);
				}
				submitAnnotationsMultiRequest.addEventListener(KalturaEvent.COMPLETE, onFeedbackSaved);
				submitAnnotationsMultiRequest.addEventListener(KalturaEvent.FAILED, onFeedbackSaveFailed );
				kalturaClient.post(submitAnnotationsMultiRequest);
			}
			
			function onCreateParentAnnotationFailed (e : KalturaEvent) : void
			{
				trace ("failed");
			}
			
			function onFeedbackSaved (e : KalturaEvent) : void
			{
				trace ("Feedback saved successfully");
				
				resetAnnotationComponent();
			}
			
			function onFeedbackSaveFailed (e : KalturaEvent) : void
			{
				trace ("Feedback not saved");
			}
		}
		
		protected function resetAnnotationComponent () : void
		{
			(viewComponent as annotationsPluginCode).annotationsBox.reset();
			resetCookieForSessionId();
			(viewComponent as annotationsPluginCode).showAnnotationsPlugin = false;
			sendNotification("receivedCuePoints", (viewComponent as annotationsPluginCode).annotationsBox.millisecTimesArray );
		}
		
		protected function resetCookieForSessionId () : void
		{
			try
			{
				SharedObject.getLocal(ANNOTATIONS_SO_PREFIX + _entryId).data.savedAnnotations = null;
				SharedObject.getLocal(ANNOTATIONS_SO_PREFIX + _entryId).flush();
			}
			catch (e : Error)
			{
				
			}
		}
		protected function loadFeedbackSession () : void
		{
			var kc : KalturaClient = (facade.retrieveProxy(ServicesProxy.NAME) as ServicesProxy).kalturaClient;
			
			var filterAnnotationsList : KalturaAnnotationFilter = new KalturaAnnotationFilter();
			filterAnnotationsList.parentIdEqual = _sessionId;
			var getAnnotationsList : AnnotationList = new AnnotationList (filterAnnotationsList);
			
			getAnnotationsList.addEventListener(KalturaEvent.COMPLETE, onSessionsAnnotationsLoaded);
			getAnnotationsList.addEventListener(KalturaEvent.FAILED, onSessionAnnotationsFailed);
			
			kc.post(getAnnotationsList);
		}

		protected function onSessionsAnnotationsLoaded (e : KalturaEvent) : void
		{
			if (!(viewComponent as annotationsPluginCode).showAnnotationsPlugin)
			{
				(viewComponent as annotationsPluginCode).showAnnotationsPlugin = true;
			}
			var kalturaAnnotationList : Array = e.data.objects as Array;
			if (kalturaAnnotationList && kalturaAnnotationList.length)
			{
				for (var i:int = 0; i<kalturaAnnotationList.length; i++)
				{
					var annotations2Add : Annotation = new Annotation (AnnotationStrings.VIEW_MODE, -1,"","", kalturaAnnotationList[i] as KalturaAnnotation);
					(viewComponent as annotationsPluginCode).annotationsBox.addAnnotation(annotations2Add);
				}
				
				sendNotification("receivedCuePoints", (viewComponent as annotationsPluginCode).annotationsBox.millisecTimesArray );
			}
		}
		
		protected function onSessionAnnotationsFailed (e : KalturaEvent) : void
		{
			
		}
	}
}