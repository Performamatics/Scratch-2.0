// ProjectIO.as
// John Maloney, September 2010
//
// Support for project saving/loading, either to the local file system or a server.
// Three types of projects are supported: old Scratch projects (.sb), new Scratch
// projects stored as a JSON project file and a collection of media files packed
// in a single ZIP file, and new Scratch projects stored on a server as a collection
// of separate elements.

package util {
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	import blocks.BlockIO;
	import scratch.*;
	import ui.LoadProgress;
	import uiwidgets.DialogBox;

public class ProjectIO {

	private var app:Scratch;
	private var proj:ScratchStage;
	private var images:Array = [];
	private var sounds:Array = [];

	public function ProjectIO(app:Scratch):void {
		this.app = app;
	}

	//----------------------------
	// Load and install a project from a file
	//----------------------------

	public	function loadProjectFromFileNamed(fileName:String):void {
		function fileLoaded(e:Event):void { app.runtime.installProjectFromData(e.target.data) }
		app.runtime.stopAll();
		app.setProjectName(fileName);
		var loader:URLLoader = new URLLoader();
		loader.addEventListener(Event.COMPLETE, fileLoaded);
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		loader.load(new URLRequest(fileName));
	}

	//----------------------------
	// Download and install an old project
	//----------------------------

	public function fetchOldProjectURL(url:String):void {
		function progressHandler(event:ProgressEvent):void {
			progress.errorStatus('Loaded ' + event.bytesLoaded + ' of ' + event.bytesTotal + ' bytes');
			if (event.bytesTotal > 0) {
				progress.updateProgress(event.bytesLoaded / event.bytesTotal);
			}
		}
		function completeHandler(event:Event):void { 
			progress.updateStatus('Loading...');
			app.runtime.installProjectFromData(loader.data);
		}
		function errorHandler(event:ErrorEvent):void {
			progress.updateStatus(event.type);
			progress.errorStatus(event.text);
		}
		app.runtime.stopAll();
		app.runtime.installEmptyProject();
		app.addLoadProgressBox();
		var progress:LoadProgress = app.lp;
		var loader:URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
		loader.addEventListener(Event.COMPLETE, completeHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		progress.updateStatus('Loading...');
		try {
			loader.load(new URLRequest(url));
		} catch (error:Error) {
			progress.updateStatus(error.name);
			progress.errorStatus(error.message);
			loader = null;
		}
	}

	//----------------------------
	// Encode a project as a ByteArray (a 'one-file' project)
	//----------------------------

	public function encodeProjectAsZipFile(project:ScratchStage):ByteArray {
		// Encode a project into a ByteArray. The format is a ZIP file containing
		// the JSON project data and all images and sounds as files.
		this.proj = project;
		delete proj.info.penTrails; // remove the penTrails bitmap saved in some old projects' info
		proj.savePenLayer();
		recordImagesAndSounds(false);
		var zip:ZipIO = new ZipIO();
		zip.startWrite();
		addProjectJSON(zip);
		addImagesAndSounds(zip);
		proj.clearPenLayer();
		return zip.endWrite();
	}

	private function addProjectJSON(zip:ZipIO):void {
		var jsonData:ByteArray = new ByteArray();
		jsonData.writeUTFBytes(JSON_AB.stringify(proj));
		zip.write('project.json', jsonData, true);
	}

	private function addImagesAndSounds(zip:ZipIO):void {
		var i:int, ext:String;
		for (i = 0; i < images.length; i++) {
			var imgData:ByteArray = images[i][1];
			ext = ScratchCostume.fileExtension(imgData);
			zip.write(i + ext, imgData);
		}
		for (i = 0; i < sounds.length; i++) {
			var sndData:ByteArray = sounds[i][1];
			ext = ScratchSound.isWAV(sndData) ? '.wav' : '.mp3';
			zip.write(i + ext, sndData);
		}
	}

	//----------------------------
	// Decode a project from a ByteArray (a 'one-file' project)
	//----------------------------

	public function decodeProjectFromZipFile(zipData:ByteArray):ScratchStage {
		var jsonData:String;
		images = [];
		sounds = [];
		var files:Array = new ZipIO().read(zipData);
		for each (var f:Array in files) {
			var fName:String = f[0];
			var fIndex:int = int(integerName(fName));
			var contents:ByteArray = f[1];
			if (fName.slice(-4) == '.jpg') images[fIndex] = contents;
			if (fName.slice(-4) == '.png') images[fIndex] = contents;
			if (fName.slice(-4) == '.svg') images[fIndex] = contents;
			if (fName.slice(-4) == '.wav') sounds[fIndex] = contents;
			if (fName.slice(-4) == '.mp3') sounds[fIndex] = contents;
			if (fName.slice(-5) == '.json') jsonData = contents.readUTFBytes(contents.length);
		}
		if (jsonData == null) return null;
		proj = new ScratchStage();
		var jsonObj:Object = JSON_AB.parse(jsonData);
		proj.readJSON(jsonObj);
		installImagesAndSounds();
		return proj;
	}

	private function integerName(s:String):String {
		// Return the substring of digits preceding the last '.' in the given string.
		// For example integerName('123.jpg') -> '123'.
		const digits:String = '1234567890';
		var end:int = s.lastIndexOf('.');
		if (end < 0) end = s.length;
		var start:int = end - 1;
		if (start < 0) return s;
		while ((start >= 0) && (digits.indexOf(s.charAt(start)) >= 0)) start--;
		return s.slice(start + 1, end);
	}

	private function installImagesAndSounds():void {
		if (proj.penLayerMD5) proj.penLayerPNG = images[0];
		for each (var obj:ScratchObj in proj.allObjects()) {
			for each (var c:ScratchCostume in obj.costumes) {
				if (images[c.baseLayerID] != undefined) c.baseLayerData = images[c.baseLayerID];
				if (images[c.textLayerID] != undefined) c.textLayerData = images[c.textLayerID];
			}
			for each (var snd:ScratchSound in obj.sounds) {
				snd.soundData = sounds[snd.soundID];
			}
		}
	}

	//----------------------------
	// Upload project to server
	//----------------------------

	public function uploadProject(project:ScratchStage, projectID:String, onSuccess:Function):void {
		function projectSaved(result:String):void {
			projectDataSaved = (result != null);
			if (projectDataSaved) checkDone();
			else app.setSaveStatus('Save failed.', true);
		}
		function allAssetsUploaded():void { assetsSaved = true; checkDone() }
		function checkDone():void {
			if (projectDataSaved && assetsSaved) {
				proj.clearPenLayer();
				app.setSaveStatus('Last save at ' + new Date().toLocaleTimeString());
				onSuccess();
			}
		}
		var assetsSaved:Boolean, projectDataSaved:Boolean;
		this.proj = project;
		app.setSaveStatus('Saving...');
		delete proj.info.penTrails; // remove the penTrails bitmap saved in some old projects' info
		proj.savePenLayer();
		recordImagesAndSounds(true);
		uploadImagesAndSounds(allAssetsUploaded);
		Server.setProject(projectID, JSON_AB.stringify(proj), projectSaved);
	}

	private function uploadImagesAndSounds(whenDone:Function):void {
		function assetUploadDone():void {
			assetCount--;
			if (assetCount == 0) whenDone();
		}
		var i:int, md5:String, data:ByteArray, ext:String;
		var assetCount:int = images.length + sounds.length;
		if (assetCount == 0) whenDone();
		for (i = 0; i < images.length; i++) {
			md5 = images[i][0];
			data = images[i][1];
			ext = ScratchCostume.fileExtension(data);
			uploadAsset(md5, ext, data, assetUploadDone);
		}
		for (i = 0; i < sounds.length; i++) {
			md5 = sounds[i][0];
			data = sounds[i][1];
			uploadAsset(md5, '.wav', data, assetUploadDone);
		}
	}

	private function uploadAsset(md5:String, dotExt:String, data:ByteArray, whenDone:Function):void  {
		function uploadDone(s:String):void {
			if (s == null) {
				app.setSaveStatus('Save failed.', true);
				return;
			}
			recordServerAsset(md5);
			whenDone();
		}
		if (md5.indexOf('.') < 0) md5 = md5 + dotExt; // append extension, if needed
		Server.setAsset(md5, data, uploadDone);
	}

	//----------------------------
	// Download a project from the server
	//----------------------------

	public function fetchProject(projectOwner:String, projectID:String):void {
		// Fetch a project with the given owner and ID.
		// Details: First, try to fetch the project from the new version store. If that fails,
		// and if projectID is < 10,000,000, try fetching the project from the old website.
		// If projectID is >= 10,000,000 then start a new project with that ID.
		// During alpha, edited versions of old projects override their original versions on
		// the old website.
		function whenDone(projectData:ByteArray):void {
			if (projectData && (projectData.length > 50)) downloadProjectAssets(projectData);
			else { // failed; fetch from old website or create a new project
				if (projectID.length < 8) { // fetch from old website
					var oldWebsiteURL:String = 'http://scratch.mit.edu/static/projects/' + projectOwner + '/' + projectID + '.sb';
					fetchOldProjectURL(oldWebsiteURL);
				} else {
					app.removeLoadProgressBox();
					app.startNewProject(projectOwner, projectID);
				}
			}
		}
		app.addLoadProgressBox();
		Server.getProject(projectID, whenDone);
	}

	private function downloadProjectAssets(projectData:ByteArray):void {
		function assetReceived(md5:String, data:ByteArray):void {
			recordServerAsset(md5);
			assetDict[md5] = data;
			assetCount++;
			assetBytes += data.length;
			app.lp.updateProgress(assetCount / assetsToFetch.length);
			if (assetCount == assetsToFetch.length) {
				installAssetsInProject(assetDict);
				app.runtime.decodeImagesAndInstall(proj);
			}
		}
		var projJSON:String = projectData.readUTFBytes(projectData.length);
		proj = new ScratchStage();
		proj.readJSON(JSON_AB.parse(projJSON));
		var assetsToFetch:Array = collectAssetsToFetch();
		var assetDict:Object = new Object();
		var assetCount:int = 0;
		var assetBytes:int;
		for each (var md5:String in assetsToFetch) fetchAsset(md5, assetReceived);
	}

	private function fetchAsset(md5:String, whenDone:Function):void {
		function gotData(data:ByteArray):void { whenDone(md5, data) }
		Server.getAsset(md5, gotData);
	}

	private function collectAssetsToFetch():Array {
		// Return list of MD5's for all project assets.
		var list:Array = new Array();
//		if (proj.penLayerMD5) list.push(proj.penLayerMD5);
		for each (var obj:ScratchObj in proj.allObjects()) {
			for each (var c:ScratchCostume in obj.costumes) {
				if (list.indexOf(c.baseLayerMD5) < 0) list.push(c.baseLayerMD5);
				if (c.textLayerMD5) {
					if (list.indexOf(c.textLayerMD5) < 0) list.push(c.textLayerMD5);
				}
			}
			for each (var snd:ScratchSound in obj.sounds) {
				if (list.indexOf(snd.md5) < 0) list.push(snd.md5);
			}
		}
		return list;
	}

	private function installAssetsInProject(assetDict:Object):void {
//		if (proj.penLayerMD5) proj.penLayerPNG = assetDict[proj.penLayerMD5];
		for each (var obj:ScratchObj in proj.allObjects()) {
			for each (var c:ScratchCostume in obj.costumes) {
				c.baseLayerData = assetDict[c.baseLayerMD5];
				if (c.textLayerMD5) c.textLayerData = assetDict[c.textLayerMD5];
			}
			for each (var snd:ScratchSound in obj.sounds) {
				var sndData:* = assetDict[snd.md5];
				if (sndData != undefined) snd.soundData = sndData;
			}
		}
	}

	//----------------------------
	// Record unique images and sounds
	//----------------------------

	private function recordImagesAndSounds(uploading:Boolean):void {
		var recordedAssets:Object = {};
		images = [];
		sounds = [];

		if (!uploading) recordImage(proj.penLayerPNG, proj.penLayerMD5, recordedAssets, uploading);

		for each (var obj:ScratchObj in proj.allObjects()) {
			for each (var c:ScratchCostume in obj.costumes) {
				c.prepareToSave(); // encodes image and computes md5 if necessary
				c.baseLayerID = recordImage(c.baseLayerData, c.baseLayerMD5, recordedAssets, uploading);
				if (c.textLayerBitmap) {
					c.textLayerID = recordImage(c.textLayerData, c.textLayerMD5, recordedAssets, uploading);
				}
			}
			for each (var snd:ScratchSound in obj.sounds) {
				snd.prepareToSave(); // compute md5 if necessary
				snd.soundID = recordSound(snd, snd.md5, recordedAssets, uploading);
			}
		}
	}

	private function recordImage(img:*, md5:String, recordedAssets:Object, uploading:Boolean):int {
		var id:* = recordedAssets[md5];
		if (id != undefined) return id; // image was already added
		if (uploading && serverHasAsset(md5)) return -1; // server already has asset
		images.push([md5, img]);
		id = images.length - 1;
		recordedAssets[md5] = id;
		return id;
	}

	private function recordSound(snd:ScratchSound, md5:String, recordedAssets:Object, uploading:Boolean):int {
		var id:* = recordedAssets[md5];
		if (id != undefined) return id; // sound was already added
		if (uploading && serverHasAsset(md5)) return -1; // server already has asset
		sounds.push([md5, snd.soundData]);
		id = sounds.length - 1;
		recordedAssets[md5] = id;
		return id;
	}

	//----------------------------
	// Fetch a costume or sound from the server
	//----------------------------

	public function fetchImage(id:String, costumeName:String, whenDone:Function):void {
		// Fetch an image asset from the server and call whenDone with the resulting ScratchCostume.
		var c:ScratchCostume, imgData:ByteArray;
		function gotCostumeData(data:ByteArray):void {
			imgData = data;
			if (ScratchCostume.isSVGData(imgData)) {
				c.setSVGData(imgData);
				c.baseLayerMD5 = id;
				whenDone(c);
			} else {
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, costumeDecoded);
				loader.loadBytes(imgData);
			}
		}
		function costumeDecoded(e:Event):void {
			c = new ScratchCostume(costumeName, e.target.content.bitmapData);
			c.baseLayerMD5 = id;
			whenDone(c);
		}
		Server.getAsset(id, gotCostumeData);
	}

	public function fetchSound(id:String, sndName:String, whenDone:Function):void {
		// Fetch a sound asset from the server and call whenDone with the resulting ScratchSound.
		function gotSoundData(wavData:ByteArray):void {
			var snd:ScratchSound;
			try {
				snd = new ScratchSound(sndName, wavData);
			} catch (e:Error) { app.browserTrace('sound decode error') }
			if (!snd) return; // decode error
			snd.md5 = id;
			whenDone(snd);
		}
		Server.getAsset(id, gotSoundData);
	}

	//----------------------------
	// Cache of server assets
	//----------------------------

	// Hashtable whose keys are asset ID's and whose values are null (and not used).
	private static var serverAssets:Object = {};

	private function recordServerAsset(id:String):void { serverAssets[id] = null }
	private function serverHasAsset(id:String):Boolean { return (id in serverAssets) }

}}
