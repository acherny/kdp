package com.kaltura.delegates.attachmentAsset
{
	import com.kaltura.config.KalturaConfig;
	import com.kaltura.net.KalturaCall;
	import com.kaltura.delegates.WebDelegateBase;
	import flash.utils.getDefinitionByName;

	public class AttachmentAssetGetDownloadUrlDelegate extends WebDelegateBase
	{
		public function AttachmentAssetGetDownloadUrlDelegate(call:KalturaCall, config:KalturaConfig)
		{
			super(call, config);
		}

		override public function parse(result:XML) : *
		{
			return result.result.toString();
		}

	}
}
