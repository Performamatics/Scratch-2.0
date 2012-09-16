// Server.as
// John Maloney, February 2010
//
// Interface to the Scratch website API's. 
//
// Note: All operations call the whenDone function with the result
// if the operation succeeded or null if it failed.

package util {
	import flash.display.Loader;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.*;
	import flash.utils.ByteArray;
	import util.Base64Encoder;
	
	
public class Server {

	private static const apiPrefix:String = 'http://jiggler.media.mit.edu/internalapi/';

	// -----------------------------
	// Asset API
	//------------------------------

	public static function getAsset(md5:String, whenDone:Function):void {
		var url:String = apiPrefix + 'asset/' + md5 + '/get/';
		callServer(url, null, whenDone);
	}

	public static function setAsset(md5:String, data:ByteArray, whenDone:Function):void {
		var url:String = apiPrefix + 'asset/' + md5 + '/set/';
		callServer(url, data, whenDone);
	}

	public static function getThumbnail(idAndExt:String, w:int, h:int, whenDone:Function):void {
		function decodeImage(data:ByteArray):void {
			if (!data || data.length == 0) return; // no data
			var decoder:Loader = new Loader();
			decoder.contentLoaderInfo.addEventListener(Event.COMPLETE, imageDecoded);
			decoder.loadBytes(data);
		}
		function imageDecoded(e:Event):void { whenDone(e.target.content.bitmapData) }
		var url:String = apiPrefix + 'thumbnail/' + w + '/' + h + '/' + idAndExt;
		callServer(url, null, decodeImage);
	}

	// -----------------------------
	// Old Asset API
	//------------------------------

	private static const oldAPIPrefix:String = 'http://jiggler.media.mit.edu/v3/';

	public static function listLibraryAssets(assetType:String, whenDone:Function):void {
		var url:String = oldAPIPrefix + 'objects/scratchlib/scr4tch/list/' + assetType;
		callServer(url, null, whenDone);
	}

	public static function saveImageAssetFromURL(fullURL:String, whenDone:Function):void {
		var s:String = fullURL.slice(7); // remove the 'http://' prefix from the full URL
		var url:String = oldAPIPrefix + 'assets/setfromurl/' + s;
		callServer(url, null, whenDone);
	}

	// -----------------------------
	// Backpack API
	//------------------------------

	public static function getBackpack(usr:String, whenDone:Function):void {
		var url:String = apiPrefix + 'backpack/' + usr + '/get/';
		callServer(url, null, whenDone);
	}

	public static function setBackpack(elements:Array, usr:String, whenDone:Function):void {
		var url:String = apiPrefix + 'backpack/' + usr + '/set/';
		callServer(url, JSON_AB.stringify(elements), whenDone);
	}

	// -----------------------------
	// ProjectStore API
	//------------------------------

	public static function getProject(projectID:String, whenDone:Function):void {
		var url:String = apiPrefix + 'project/' + projectID + '/get/';
		callServer(url, null, whenDone);
	}

	public static function setProject(projectID:String, jsonData:String, whenDone:Function):void {
		var url:String = apiPrefix + 'project/' + projectID + '/set/';
		callServer(url, jsonData, whenDone);
	}

	// -----------------------------
	// Project Thumbnail API
	//------------------------------

	public static function setProjectThumbnail(projectID:String, pngData:ByteArray, whenDone:Function):void {
		var url:String = '/projects/' + projectID + '/thumbnail/';
		callServer(url, pngData, whenDone);
	}

	// -----------------------------
	// Server GET/POST
	//------------------------------

	private static function callServer(url:String, data:*, whenDone:Function):void {
		// Make a GET or POST request to the given URL (do a POST if the data is not null).
		// The whenDone() function is called when the request is done, either with the
		// data returned by the server or with a null argument if the request failed.
		// The request includes site and session authentication headers.

		function completeHandler(e:Event):void { whenDone(loader.data) }
		function errorHandler(err:ErrorEvent):void { whenDone(null) }
		var loader:URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		loader.addEventListener(Event.COMPLETE, completeHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		var request:URLRequest = new URLRequest(url);
		if (data) {
			request.method = URLRequestMethod.POST;
			request.data = data;
		}

		// header for beta-test website password
		request.requestHeaders.push(authHeader());

		// header for CSRF authentication
		var csrfCookie:String = getCSRF();
		if (csrfCookie && (csrfCookie.length > 0)) {
			request.requestHeaders.push(new URLRequestHeader('X-CSRFToken', csrfCookie));
		}

		loader.load(request);
	}

	private static function authHeader():URLRequestHeader {
		// Return an authentication header for the temporary website password.
		return new URLRequestHeader(
			'Authorization',
			'Basic ' + Base64Encoder.encodeString('scratchteam:gobo'));
	}

	private static function getCSRF():String {
		return ExternalInterface.available ? ExternalInterface.call('getCookie', 'csrftoken') : null;
	}

}}
