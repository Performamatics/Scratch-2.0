// Scratch.as
// John Maloney, September 2009
//
// This is the top-level application.

package {
	import assets.Resources;
	
	import blocks.*;
	
	import com.lorentz.processing.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.net.*;
	import flash.system.System;
	import flash.text.*;
	import flash.ui.Mouse;
	import flash.utils.*;
	
	import interpreter.*;
	
	import scratch.*;
	
	import sound.WAVFile;
	
	import soundui.*;
	
	import soundutil.SampledSound;
	
	import spark.primitives.Graphic;
	
	import ui.*;
	import ui.media.*;
	import ui.parts.*;
	
	import uiwidgets.*;
	
	import util.*;
	
	
//[SWF('width'='960', 'height'='620', 'backgroundColor'='#FFFFFF')]

public class Scratch extends Sprite {

	// Added by Matthew Vaughan to Test Sockets Aug/24/2012
	public var mySock:SocketConnect;
	
	// Version
	protected var versionString:String = 'v78alex';

	// Runtime
	public var runtime:ScratchRuntime;
	public var interp:Interpreter;
	public var extensionManager:ExtensionManager;
	public var persistenceManager:PersistenceManager;
	public var gh:GestureHandler;
	public var autostart:Boolean;
	public var editMode:Boolean;
	public var embedMode:Boolean;
	public var stageIsContracted:Boolean;
	public var userName:String = '';
	public var projectID:String = '';
	public var projectOwner:String = '';
	public var projectIsPrivate:Boolean;
	private var viewedObject:ScratchObj;
	private var lastTab:String = 'scripts';

	// Public UI Elements
	public var playerBG:Shape;
	public var palette:BlockPalette;
	public var scriptsPane:ScriptsPane;
	public var stagePane:ScratchStage;
	public var openBackpack:BackpackPart;
	public var mediaLibrary:MediaLibrary;
	public var lp:LoadProgress;

	// UI Parts
	private var topBarPart:TopBarPart;
	private var stagePart:StagePart;
	private var libraryPart:LibraryPart;
	private var tabsPart:TabsPart;
	private var scriptsPart:ScriptsPart;
	private var imagesPart:ImagesPart;
	private var soundsPart:SoundsPart;
	private var backpackPart:BackpackPart;

	public function Scratch() {
				
		if (runtime != null) return; // do not delete! (allows initialization to be done by a subclass)
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.frameRate = 30;
		Mouse.cursor = 'arrow';
		ProcessExecutor.instance.initialize(stage); // needed by SVG parser

		Block.MenuHandlerFunction = BlockMenus.BlockMenuHandler;

		stagePane = new ScratchStage();
		gh = new GestureHandler(this);
		runtime = new ScratchRuntime(this);
		interp = runtime.interp;
		persistenceManager = new PersistenceManager(this);
		extensionManager = new ExtensionManager(this);
		autostart = true;

		playerBG = new Shape(); // create, but don't add
		addParts();

		stage.addEventListener(MouseEvent.MOUSE_DOWN, gh.mouseDown);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, gh.mouseMove);
		stage.addEventListener(MouseEvent.MOUSE_UP, gh.mouseUp);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, runtime.keyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, runtime.keyUp);
		stage.addEventListener(Event.ENTER_FRAME, step);
		stage.addEventListener(Event.RESIZE, fixLayout);

setEditMode(true); // xxx true for testing, false for release

		embedMode = stage.width < 480; // guess a default setting; later, set via a startup parameter
		backpackPart.loadBackpack();
		runtime.installEmptyProject(); // install project before calling fixLayout()
		fixLayout(null);
		setupExternalInterface();
		browserTrace(versionString);
		handleStartupParameters(); // support for embedding
	}

	public function viewedObj():ScratchObj { return viewedObject }
	public function stageObj():ScratchStage { return stagePane }
	public function projectName():String { return stagePart.projectName() }
	public function highlightSprites(sprites:Array):void { libraryPart.highlight(sprites) }
	public function updatePalette():void { scriptsPart.updatePalette() }
	public function selectCostume():void { imagesPart.selectCostume() }
	public function selectSound(snd:ScratchSound):void { soundsPart.selectSound(snd) }
	public function setSaveStatus(s:String, alert:Boolean = false):void { stagePart.setSaveStatus(s, alert) }

	public function toggleStageContract():void {
		stageIsContracted = !stageIsContracted;
		stagePart.refresh();
		fixLayout(null);
		libraryPart.refresh();
		tabsPart.refresh();
	}

	public function setProjectName(s:String):void {
		if (s.slice(-3) == '.sb') s = s.slice(0, -3);
		if (s.slice(-4) == '.sb2') s = s.slice(0, -4);
		stagePart.setProjectName(s);
	}

	public function projectLoaded():void {
		removeLoadProgressBox();
		setSaveStatus('');
		System.gc();
		persistenceManager.connectOrReconnect(projectID);
		if (autostart) runtime.startGreenFlags();
		refreshUserAndProject();
	}

	protected function step(e:Event):void {
		// Step the runtime system and all UI components.
		gh.step();
		runtime.stepRuntime();
		Transition.step(null);
		stagePart.step();
		libraryPart.step();
		imagesPart.step();
		autosave();
	}

	public function updateSpriteLibrary(sortByIndex:Boolean = false):void { libraryPart.refresh() }
	public function threadStarted():void { stagePart.threadStarted() }

	public function selectSprite(obj:ScratchObj):void {
		viewedObject = obj;
		libraryPart.refresh();
		tabsPart.refresh();
		if (isShowing(imagesPart)) {
			imagesPart.refresh();
			imagesPart.selectCostume();
		}
		if (isShowing(soundsPart)) soundsPart.refresh();
		if (isShowing(scriptsPart)) {
			scriptsPart.updatePalette();
			scriptsPane.viewScriptsFor(obj);
		}
	}

	public function setTab(tabName:String):void {
		hide(scriptsPart);
		hide(imagesPart);
		hide(soundsPart);
		if (!editMode) return;
		if (tabName == 'images') {
			imagesPart.refresh();
			show(imagesPart);
		} else if (tabName == 'scripts') {
			scriptsPart.updatePalette();
			show(scriptsPart);
		} else if (tabName == 'sounds') {
			soundsPart.refresh();
			show(soundsPart);
		}
		show(tabsPart);
		tabsPart.selectTab(tabName);
		lastTab = tabName;
	}

	public function installStage(newStage:ScratchStage):void {
		stagePart.installStage(newStage);
		selectSprite(newStage);
		libraryPart.refresh();
		setTab('scripts');
		scriptsPart.resetCategory();
	}

	private function addParts():void {
		topBarPart = new TopBarPart(this);
		stagePart = new StagePart(this);
		libraryPart = new LibraryPart(this);
		tabsPart = new TabsPart(this);
		scriptsPart = new ScriptsPart(this);
		imagesPart = new ImagesPart(this);
		soundsPart = new SoundsPart(this);
		backpackPart = new BackpackPart(this);
		addChild(topBarPart);
		addChild(stagePart);
		addChild(libraryPart);
		addChild(tabsPart);
		addChild(scriptsPart);
		addChild(imagesPart);
		addChild(soundsPart);
		addChild(backpackPart);
	}

	// -----------------------------
	// UI Mode and Resizing
	//------------------------------

	public function setEditMode(newMode:Boolean):void {
		Menu.removeMenusFrom(stage);
		editMode = newMode;
		jsSetFlashDragDrop(editMode);
		if (editMode) {
			hide(playerBG);
			show(topBarPart);
			show(libraryPart);
			show(tabsPart);
			show(backpackPart);
			setTab(lastTab);
		} else {
//			stageIsContracted = false;
			addChildAt(playerBG, 0);  // behind everything
			playerBG.visible = false;
			hide(topBarPart);
			hide(libraryPart);
			hide(tabsPart);
			hide(backpackPart);
			setTab(null); // hides scripts, images, and sounds
		}
		stagePart.refresh();
		fixLayout(null);
	}

	private function hide(obj:DisplayObject):void { if (obj.parent) obj.parent.removeChild(obj) }
	private function show(obj:DisplayObject):void { addChild(obj) }
	private function isShowing(obj:DisplayObject):Boolean { return obj.parent != null }

	public function fixLayout(e:Event):void {
		var w:int = stage.stageWidth;
		var h:int = stage.stageHeight - 1; // fix to show bottom border...

		topBarPart.x = 0;
		topBarPart.y = 0;
		topBarPart.setWidthHeight(w, 24);

		var extraW:int = 2;
		var extraH:int = stagePart.topBarHeight + 1;
		if (editMode) {
			if (stageIsContracted) {
				stagePart.setWidthHeight(240 + extraW, 180 + extraH, 0.5);
			} else {
				stagePart.setWidthHeight(480 + extraW, 360 + extraH, 1);
			}
			stagePart.x = 5;
			stagePart.y = topBarPart.bottom() + 5;
		} else {
			drawBG();
			var pad:int = (w > 550) ? 16 : 0; // add padding for full-screen mode
			var scale:Number = Math.min((w - extraW - pad) / 480, (h - extraH - pad) / 360);
			scale = Math.max(0.01, scale);
			var scaledW:int = Math.floor((scale * 480) / 4) * 4;  // round down to a multiple of 4
			scale = scaledW / 480;
			var playerW:Number = (scale * 480) + extraW;
			var playerH:Number = (scale * 360) + extraH;
			stagePart.setWidthHeight(playerW, playerH, scale);
			stagePart.x = int((w - playerW) / 2);
			stagePart.y = int((h - playerH) / 2);
			return;
		}
		libraryPart.x = stagePart.x;
		libraryPart.y = stagePart.bottom() + 18;
		libraryPart.setWidthHeight(stagePart.w, h - libraryPart.y);

		tabsPart.x = stagePart.right() + 9;
		tabsPart.y = topBarPart.bottom() + 5;
		tabsPart.fixLayout();

		// the content area shows the part associated with the currently selected tab:
		var contentX:int = tabsPart.x;
		var contentY:int = tabsPart.y + 21;
		var contentW:int = w - contentX - 5;
		var contentH:int = h - contentY - backpackPart.openAmount - 5;

		imagesPart.x = soundsPart.x = scriptsPart.x = contentX;
		imagesPart.y = soundsPart.y = scriptsPart.y = contentY;
		imagesPart.setWidthHeight(contentW, contentH);
		soundsPart.setWidthHeight(contentW, contentH);
		scriptsPart.setWidthHeight(contentW, contentH);

		backpackPart.x = contentX;
		backpackPart.y = h - backpackPart.openAmount - 1;
		backpackPart.setWidthHeight(contentW, backpackPart.fullHeight);
		if (mediaLibrary) mediaLibrary.setWidthHeight(w, h);
	}

	private function drawBG():void {
		var g:Graphics = playerBG.graphics;
		g.clear();
		g.beginFill(0);
		g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
	}

	// -----------------------------
	// Menus
	//------------------------------

	public function showLoginMenu():void {
		function goToStudio():void { jsRedirectTo('studio') }
		function goToProfile():void { jsRedirectTo('profile') }
		function goToLogout():void { jsRedirectTo('logout') }
		var m:Menu = new Menu();
		topBarPart.styleMenu();
		m.addItem('Studio', goToStudio);
		m.addItem('Profile', goToProfile);
		m.addLine();
		m.addItem('Sign out', goToLogout);
		m.showOnStage(stage, stage.width, topBarPart.bottom() - 1);
	}

	public function moreButtonPressed(b:*):void {
		var m:Menu = new Menu();
		// Skin the menu for Upstatement Look
		topBarPart.styleMenu();
		if (isLoggedIn() && (userName == projectOwner)) {
			m.addItem('Make a copy', jsCopyProject);
		}
		m.addItem('Open from local file', runtime.installProjectFromLocalFile);
		m.addItem('Save to local file', saveToFile);
		m.addLine();
// Laptop Orchestra Socket Connect code added by Matthew Vaughan Sep/1/2012
		if ( SocketConnect.getInstance().isConnected() ) {
			m.addItem('Disconnect from Laptop Orchestra Server', disconnectFromServer);
		} else {
			m.addItem('Connect to Laptop Orchestra Server', connectToServer);
		}
		m.addLine();
// End of code added
		var onOff:String = (interp.turboMode) ? 'Turn off' : 'Turn on';
		m.addItem(onOff + ' turbo mode', toggleTurboMode);
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
	}

	private function showAboutDialog():void {
		DialogBox.notify('Scratch 2.0 Preview of ' + versionString +
			'\n\nCopyright © 2011 MIT Media Laboratory' +
			'\nAll rights reserved.' +
			'\n\nPlease do not distribute!', stage);
	}

	private function saveToFile():void {
		function done(e:Event):void { setProjectName(e.target.name) }
		scriptsPane.saveScripts();
		var defaultName:String = (projectName.length > 0) ? projectName + '.sb2' : 'project.sb2';
		var zipData:ByteArray = new ProjectIO(this).encodeProjectAsZipFile(stagePane);
		var file:FileReference = new FileReference();
		file.addEventListener(Event.COMPLETE, done);
		file.save(zipData, defaultName);
	}

	private function toggleTurboMode():void { interp.turboMode = !interp.turboMode }

	private function openSoundRecorder():void {
		var r:NewSoundRecorder = new NewSoundRecorder();
		addChild(r);
	}

	private function openOldSoundRecorder():void {
		function editRecording(recording:SampledSound):void {
			recorder.stop();
			soundEditor = new SoundEditorPane(saveRecording, recording);
			soundEditor.showOnStage(stage);
		}
		function saveRecording(recording:SampledSound):void {
			var snd:ScratchSound = new ScratchSound('recording', convertToWAV(recording));
			addSound(snd);
		}
		var recorder:SoundRecorderPane = new SoundRecorderPane(saveRecording, editRecording);
		var soundEditor:SoundEditorPane;
		recorder.showOnStage(stage);
	}

	private function convertToWAV(recording: SampledSound):ByteArray {
		var wavSamples:ByteArray = new ByteArray();
		wavSamples.endian = Endian.LITTLE_ENDIAN;
		var samples:ByteArray = recording.samples;
		samples.position = 0;
		while (samples.bytesAvailable > 4) {
			wavSamples.writeShort(32767 * samples.readFloat()); // convert -1..1 to -32767..32767
		}
		return WAVFile.encode(wavSamples, wavSamples.length / 2, recording.rate, false);
	}

	// -----------------------------
	// Project Management and Login
	//------------------------------

	public function newButtonPressed(ignore:*):void { jsCreateProject() }

	public function remixButtonPressed(ignore:*):void {
		if (!isLoggedIn()) {
browserTrace('remixing when not logged in; calling jsLogin("remix")');
			jsLogin('remix');
			return;
		}
		jsRemixProject();
	}

	public function shareButtonPressed(ignore:*):void {
		function saveDone():void { jsShareProject() }
		if (!isLoggedIn()) {
browserTrace('sharing when not logged in; calling jsLogin("save")');
			jsLogin('save');
			return;
		}
		saveProject(saveDone);
	}

	public function returnToProjectPage(ignore:*):void {
		jsSetEditMode(false);
	}

	public function saveButtonPressed(ignore:*):void {
		if (!isLoggedIn() || (projectID == '')) {
browserTrace('not logged in; calling jsLogin("save")');
			jsLogin('save');
			return;
		} else if (projectOwner != userName) { // do a remix
browserTrace('Project not owned by logged in user; use "Remix"');
		} else {
			saveProject();
		}
	}

	public function isLoggedIn():Boolean { return (userName != null) && (userName != '') }

	public function loginPressed(ignore:*):void {
		if (isLoggedIn()) showLoginMenu();
		else {
			if (projectID == '') jsLogin('save'); // save the project created while logged out
			else jsLogin();
		}
	}

	public function startNewProject(newOwner:String, newID:String):void { 
		runtime.installNewProject();
		projectOwner = newOwner;
		projectID = newID;
		projectIsPrivate = true;
	}

	private function saveProject(whenDone:Function = null, saveThumbnail:Boolean = true):void {
		function uploadSucceeded():void {
browserTrace('project saved (' + (getTimer() - saveStartTime) + ' msecs)');
			if (projectOwner != userName) {
				projectOwner = userName; // this was a remix
				refreshUserAndProject();
			}
			if (whenDone != null) whenDone();
		}
		function thumbnailSaved(result:*):void {
			browserTrace('thumbnail upload ' + (result ? 'succeeded' : 'failed'));
		}
browserTrace('saving project id: ' + projectID + ' owner: ' + userName + ' title: ' + projectName());
		saveStartTime = getTimer();
		new ProjectIO(this).uploadProject(stagePane, projectID, uploadSucceeded);
		if (saveThumbnail) Server.setProjectThumbnail(projectID, stagePane.projectThumbnailPNG(144, 108), thumbnailSaved);
	}

	private const AUTO_SAVE_INTERVAL:int = 1 * 60 * 1000; // one minute
	private var lastAutoSaveTime:int;
	private var saveStartTime:int;

	private function autosave():void {
		if (interp.threadCount() > 0) return; // don't save while threads are running
		if ((getTimer() - lastAutoSaveTime) >= AUTO_SAVE_INTERVAL) {
			lastAutoSaveTime = getTimer();
			if (isLoggedIn() && (projectOwner == userName) && (projectID != '') && editMode) {
				// do outsave only if logged in, owner of the project, and have a projectID
				saveProject(null, false);
			} else {
				var reason:String = 'unknown reason';
				if (projectID == '') reason = 'no project ID';
				if (projectOwner != userName) reason = 'not project owner';
				if (!isLoggedIn()) reason = 'not logged in';
				setSaveStatus('Not saved (' + reason + ')');
			}
		}
	}

	// -----------------------------
	// Backpack and Media Importing
	//------------------------------

	public function dropMediaInfo(item:MediaInfo):void {
		// User dropped a MediaInfo onto the editor (i.e. not onto the backpack.)
		if (!item.dbObj.fromBackpack) return; // item came from editor; do nothing
		if ((item.dbObj.type == 'image') || (item.dbObj.type == 'sound')) {
			var md5AndExt:String = item.dbObj.md5;
			if ((md5AndExt.indexOf('.') < 0) && ('extension' in item.dbObj)) {
				md5AndExt = md5AndExt + '.' + item.dbObj.extension;
			}
			if (item.dbObj.type == 'image') fetchAndAddCostume(md5AndExt, item.dbObj.name);
			if (item.dbObj.type == 'sound') fetchAndAddSound(md5AndExt, item.dbObj.name);
		}
		if (item.dbObj.type == 'script') {
			// for a script, data contains the JSON string for the stack
			var json:String = item.dbObj.script;
			if (!json) json = item.dbObj.md5; // old items stored the json data in the md5 field
			if (!json) return; // no JSON data
			var script:Block = BlockIO.stringToStack(json);
			if (isShowing(scriptsPart)) {
				if (!scriptsPane.hitTestPoint(item.x, item.y)) return; // not dropped on the visible script pane
				var localP:Point = scriptsPane.globalToLocal(new Point(item.x, item.y));
				script.x = localP.x;
				script.y = localP.y;
			} else {
				script.x = script.y = 5; // place script in top-left
			}
			scriptsPane.addChild(script);
			scriptsPane.updateSize();
			scriptsPane.saveScripts();
			setTab('scripts');
		}
	}

	public function fetchAndAddCostume(id:String, costumeName:String):void {
		// Fetch and install a costume from the server.
		new ProjectIO(this).fetchImage(id, costumeName, addCostume);
	}

	public function addCostume(c:ScratchCostume):void {		
		viewedObj().costumes.push(c);
		viewedObj().showCostumeNamed(c.costumeName);
		setTab('images');
	}

	public function fetchAndAddSound(id:String, soundName:String):void {
		// Fetch and install a sound asset from the server.
		new ProjectIO(this).fetchSound(id, soundName, addSound);
	}

	public function addSound(snd:ScratchSound):void {
		viewedObj().sounds.push(snd);
		setTab('sounds');
	}

	// -----------------------------
	// Download Progress
	//------------------------------

	public function addLoadProgressBox():void {
		removeLoadProgressBox();
		if (!lp) lp = new LoadProgress();
		lp.x = int(stagePane.x + ((stagePane.width - lp.width) / 2));
		lp.y = int(stagePane.y + ((stagePane.height - lp.height) / 2));
		addChild(lp);
	}

	public function removeLoadProgressBox():void {
		if (lp != null) removeChild(lp);
		lp = null;
	}

	// -----------------------------
	// Frame rate readout (for use during development)
	//------------------------------

	private var frameRateReadout:TextField;
	private var firstFrameTime:int;
	private var frameCount:int;

	protected function addFrameRateReadout(x:int, y:int, color:uint = 0):void {
		frameRateReadout = new TextField();
		frameRateReadout.autoSize = TextFieldAutoSize.LEFT;
		frameRateReadout.selectable = false;
		frameRateReadout.background = false;
		frameRateReadout.defaultTextFormat = new TextFormat('Comic Sans MS', 12, color);
		frameRateReadout.x = x;
		frameRateReadout.y = y;
		addChild(frameRateReadout);
		frameRateReadout.addEventListener(Event.ENTER_FRAME, updateFrameRate);
	}

	private function updateFrameRate(e:Event):void {
		frameCount++;
		if (!frameRateReadout) return;
		var now:int = getTimer();
		var msecs:int = now - firstFrameTime;
		if (msecs > 500) {
			var fps:Number = Math.round((1000 * frameCount) / msecs);
			frameRateReadout.text = fps + ' fps (' + Math.round(msecs / frameCount) + ' msecs)';
			;
			firstFrameTime = now;
			frameCount = 0;
		}
	}

	// -----------------------------
	// Log pane support for debugging; noops here
	//------------------------------

	public function logPrint(obj:*, addNewline:Boolean = true):void { trace(obj) }
	public function logClear():void { }

	// -----------------------------
	// JavaScript Interface
	//------------------------------

	public function browserTrace(s:String):void {
		if (ExternalInterface.available) ExternalInterface.call('console.log', s);
	}

	private function jsCreateProject():void {
browserTrace('SWF called JScreateProject()');
		if (ExternalInterface.available) ExternalInterface.call('JScreateProject');
	}

	private function jsCopyProject():void {
browserTrace('SWF called JScopyProject()');
		if (ExternalInterface.available) ExternalInterface.call('JScopyProject');
	}

	private function jsEditorReady():void {
		if (ExternalInterface.available) ExternalInterface.call('JSeditorReady');
	}

	public function jsEditTitle():void {
browserTrace('SWF called jsEditTitle(' + projectName() + ')');
		if (ExternalInterface.available) ExternalInterface.call('JSeditTitle', projectName());
	}

	private function jsSetEditMode(flag:Boolean):void {
		if (ExternalInterface.available) ExternalInterface.call('JSsetEditMode', flag);
	}

	private function jsIsUniqueTitle(s:String):void {
		if (ExternalInterface.available) ExternalInterface.call('JSisUniqueTitle', s);
	}

	private function jsLogin(action:String = ''):void {
browserTrace('SWF called JSlogin(' + action + ')');
		if (ExternalInterface.available) ExternalInterface.call('JSlogin', action);
	}

	private function jsShareProject():void {
browserTrace('SWF called JSshareProject()');
		if (ExternalInterface.available) ExternalInterface.call('JSshareProject');
	}

	public function jsRedirectTo(newProjectID:String):void {
browserTrace('SWF called JSredirectTo(' + newProjectID + ')');
		if (ExternalInterface.available) ExternalInterface.call('JSredirectTo', newProjectID);
	}

	private function jsRemixProject():void {
browserTrace('SWF called JSremixProject()');
		if (ExternalInterface.available) ExternalInterface.call('JSremixProject');
	}

	private function jsSetFlashDragDrop(turnOn:Boolean):void {
		if (ExternalInterface.available) ExternalInterface.call('JSsetFlashDragDrop', turnOn);
	}

	public function jsSetPresentationMode(presentationMode:Boolean):void {
browserTrace('SWF called JSsetPresentationMode(' + presentationMode + ')');
		if (ExternalInterface.available) ExternalInterface.call('JSsetPresentationMode', presentationMode);
	}

	protected function setupExternalInterface():void {
		// Tests:
		//		document.getElementById('Scratch').ASversion()
		//		document.getElementById('Scratch').ASsetEditMode(true)
		if (ExternalInterface.available) {
			try {
				ExternalInterface.addCallback('ASdropFile', addFileFromJS);
				ExternalInterface.addCallback('ASdropURL', addURLFromJS);
				ExternalInterface.addCallback('ASloadProject', loadProjectFromJS);
				ExternalInterface.addCallback('ASsaveProject', saveProject);
				ExternalInterface.addCallback('ASsetEditMode', setEditMode);
				ExternalInterface.addCallback('ASsetLoginUser', setLoginUserFromJS);
				ExternalInterface.addCallback('ASsetNewProject', setNewProjectFromJS);
				ExternalInterface.addCallback('ASsetTitle', stagePart.setProjectName);
				ExternalInterface.addCallback('ASversion', function():String { return versionString });
				ExternalInterface.addCallback('ASunload', unloadFromJS);
			} catch (error:Error) { }
		}
	}

	private function handleStartupParameters():void {
		// Load a project if a 'project' URL parameter was provided.
		var projectURL:String = loaderInfo.parameters['project'];
		var autostartParam:String = loaderInfo.parameters['autostart'];
		if (projectURL) {
			autostart = true;
			if (autostartParam != null) {
				if (autostartParam.toLowerCase() == 'false') autostart = false;
			}
			browserTrace('loading project: ' + projectURL);
			new ProjectIO(this).fetchOldProjectURL(projectURL);
		} else {
			jsEditorReady(); // this triggers JS to load the project
		}
	}

	private	function addFileFromJS(fileName:String, contents:String, x:int, y:int):void {
		function errorHandler(event:ErrorEvent):void { }
		function loadDone(e:Event):void {
			var bm:BitmapData = e.target.content.bitmapData;
			browserTrace('got image: ' + bm.width + 'x' + bm.height);
			viewedObj().costumes.push(new ScratchCostume(assetName, bm, int(bm.width / 2), int(bm.height / 2)));
			viewedObj().showCostume(viewedObj().costumes.length - 1);
			setTab('costumes');
		}
		var data:ByteArray = Base64Encoder.decode(contents.slice(contents.indexOf(',') + 1));
		if (data.length == 0) return;
		var i:int, assetName:String = fileName;
		if ((i = assetName.lastIndexOf('.')) == assetName.length - 4) assetName = assetName.slice(0, -4);
		if (ScratchSound.isWAV(data)) {
			viewedObj().sounds.push(new ScratchSound(assetName, data));
			setTab('sounds');
		} else {
			var decoder:Loader = new Loader();
			decoder.contentLoaderInfo.addEventListener(Event.COMPLETE, loadDone);
			decoder.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			decoder.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			decoder.loadBytes(data);
		}
	}

	private	function addURLFromJS(url:String, x:int, y:int):void {
	 	function addAsset(md5:String):void {
	 		if (!md5) return; // failed
		 	var assetName:String = url, ext:String = '';
		 	var i:int = url.lastIndexOf('.');
		 	if (i >= 0) {
		 		ext = url.slice(i).toLowerCase();
		 		assetName = url.slice(0, i);
		 	}
		 	i = assetName.lastIndexOf('/');
		 	if (i >= 0) assetName = assetName.slice(i + 1);
			if ((ext == '.wav') || (ext == '.mp3')) fetchAndAddSound(md5, assetName);
			else fetchAndAddCostume(md5, assetName);
	 	}
	 	if (url.indexOf('http://') != 0) return;
	 	Server.saveImageAssetFromURL(url, addAsset);
	}

	private function loadProjectFromJS(owner:String, projectID:String, title:String, isPrivate:Boolean, autoStartFlag:Boolean = true):void {
browserTrace('SWF load project id: ' + projectID + ' owner: ' + owner + ' title: ' + title + ' isPrivate: ' + isPrivate);
		if (!owner) owner = '';
		if (!projectID) projectID = '';
		if (!title) title = '';
		runtime.stopAll();
		this.projectID = projectID;
		this.projectOwner = owner;
		this.projectIsPrivate = isPrivate;
		this.autostart = autoStartFlag;
		setProjectName(title);
		if (projectID == '') {
			startNewProject(owner, projectID);
		} else {
			var io:ProjectIO = new ProjectIO(this);
			io.fetchProject(projectOwner, projectID);
		}
	}

	private function setLoginUserFromJS(loginUser:String, action:String = ''):void {
		if (!loginUser) loginUser = '';
		userName = loginUser;
		backpackPart.loadBackpack();
		refreshUserAndProject();
		if ((action == 'save') && isLoggedIn()) {
			if (projectID == '') jsCopyProject();
			else saveProject();
		}
		if ((action == 'remix') && isLoggedIn()) {
			jsRemixProject();
		}
	}

	private function setNewProjectFromJS(newProjectID:String, newTitle:String):void {
		// Called after doing a remix or save-as operation.
		function projectSaved():void {
			browserTrace('redirecting to: ' + newProjectID);
			setTimeout(function():void { jsRedirectTo(newProjectID) }, 1000);
		}
		projectID = newProjectID;
		projectOwner = userName;
		projectIsPrivate = true;
		setProjectName(newTitle);
		saveProject(projectSaved);
	}

	private function unloadFromJS():void {
browserTrace('JS called ASunload');
		saveProject(null, false);
	}

	private function refreshUserAndProject():void {
		topBarPart.refresh();
		stagePart.refresh();
		browserTrace('SWF user: ' + userName + ' owner: ' + projectOwner + ' id: ' + projectID + ' isPrivate: ' + projectIsPrivate);
	}

	// Added by Matthew Vaughan Sep/1/2012
	private function connectToServer():void {
		SocketConnect.getInstance().connect();	
	}
	
	private function disconnectFromServer():void {
		SocketConnect.getInstance().disconnect();
	}
}}
