// ScratchRuntime.as
// John Maloney, September 2010

package scratch {
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.System;
	import flash.text.TextField;
	import flash.utils.*;
	import blocks.*;
	import interpreter.*;
	import primitives.*;
	import sound.*;
	import uiwidgets.DialogBox;
	import util.*;
	import watchers.*;
	import com.lorentz.SVG.display.SVGDocument;

public class ScratchRuntime {

	public var app:Scratch;
	public var interp:Interpreter;
	public var faceDetector:VideoFacePrims;
	public var motionDetector:VideoMotionPrims;
	public var keyIsDown:Array = new Array(128); // records key up/down state
	public var lastAnswer:String = '';
	public var cloneCount:int;

	private var microphone:Microphone;
	private var timerBase:uint;

	private var projectToInstall:ScratchStage;

	public function ScratchRuntime(app:Scratch) {
		this.app = app;
		interp = new Interpreter(app);
		timerBase = interp.currentMSecs;
		clearKeyDownArray();
	}

	// -----------------------------
	// Running and stopping
	//------------------------------

	public function stepRuntime():void {
		if (projectToInstall != null) {
			installProject(projectToInstall);
			projectToInstall = null;
			return;
		}

		if (recording) saveFrame();
		app.extensionManager.step();
		if (faceDetector) faceDetector.step();
		if (motionDetector) motionDetector.step();

		// Step the stage, sprites, and watchers
		app.stagePane.step();
		for (var i:int = 0; i < app.stagePane.numChildren; i++) {
			var c:DisplayObject = app.stagePane.getChildAt(i);
			if (c.visible == true) {
				if (c is ScratchSprite) ScratchSprite(c).step();
				if (c is Watcher) Watcher(c).step(this);
				if (c is ListWatcher) ListWatcher(c).step();
			}
		}

		// run scripts and commit any pen strokes
		interp.stepThreads();
		if (app.stagePane.penActivity) app.stagePane.commitPenStrokes();
	 }

//-------- recording test ---------
	public var recording:Boolean;
	private var frames:Array = [];

	private function saveFrame():void {
		var f:BitmapData = new BitmapData(480, 360);
		f.draw(app.stagePane);
		frames.push(f);
		if ((frames.length % 100) == 0) {
			trace('frames: ' + frames.length + ' mem: ' + System.totalMemory);
		}
	}

	public function startRecording():void {
		clearRecording();
		recording = true;
	}

	public function stopRecording():void {
		recording = false;
	}

	public function clearRecording():void {
		recording = false;
		frames = [];
		System.gc();
		trace('mem: ' + System.totalMemory);
	}

	public function saveRecording():void {
		var myWriter:SimpleFlvWriter = SimpleFlvWriter.getInstance();
		var data:ByteArray = new ByteArray();
		myWriter.createFile(data, 480, 360, 30, frames.length / 30.0);
		for (var i:int = 0; i < frames.length; i++) {
			myWriter.saveFrame(frames[i]);
			frames[i] = null;
		}
		frames = [];
		trace('data: ' + data.length);
		new FileReference().save(data);
	}

//----------
	public function stopAll():void {
		interp.stopAllThreads();
		for each (var b:Block in allStacks()) b.hideRunFeedback();
		app.stagePane.deleteClones();
		cloneCount = 0;
		clearKeyDownArray();
		ScratchSoundPlayer.stopAllSounds();
		app.stagePane.clearFilters();
		for each (var s:ScratchSprite in app.stagePane.sprites()) {
			s.clearFilters();
			s.hideBubble();
		}
		clearAskPrompts();
		app.removeLoadProgressBox();
		faceDetector = null;
		motionDetector = null;
	}

	// -----------------------------
	// Hat Blocks
	//------------------------------

	public function startGreenFlags():void {
		stopAll();
		function startIfGreenFlag(stack:Block, target:ScratchObj):void {
			if (stack.op == 'whenGreenFlag') interp.toggleThread(stack, target);
		}
		allStacksAndOwnersDo(startIfGreenFlag);
	}

	public function startClickedHats(clickedObj:ScratchObj):void {
		for each (var stack:Block in clickedObj.scripts) {
			if (stack.op == 'whenClicked') {
				interp.restartThread(stack, clickedObj);
			}
		}
	}

	public function startSceneEnteredHats(sceneName:String):void {
		function startMatchingSceneHats(stack:Block, target:ScratchObj):void {
			if ((stack.op == 'whenSceneStarts') && (stack.args[0].argValue == sceneName)) {
				// only start the stack if it is not already running
				if (!interp.isRunning(stack)) interp.toggleThread(stack, target);
			}
		}
		allStacksAndOwnersDo(startMatchingSceneHats);
	}

	private function startKeyHats(ch:int):void {
		var keyName:String = null;
		if (('a'.charCodeAt(0) <= ch) && (ch <= 'z'.charCodeAt(0))) keyName = String.fromCharCode(ch);
		if (('0'.charCodeAt(0) <= ch) && (ch <= '9'.charCodeAt(0))) keyName = String.fromCharCode(ch);
		if (28 == ch) keyName = 'left arrow';
		if (29 == ch) keyName = 'right arrow';
		if (30 == ch) keyName = 'up arrow';
		if (31 == ch) keyName = 'down arrow';
		if (32 == ch) keyName = 'space';
		if (keyName == null) return;
		var startMatchingKeyHats:Function = function (stack:Block, target:ScratchObj):void {
			if ((stack.op == 'whenKeyPressed') && (stack.args[0].argValue == keyName)) {
				// only start the stack if it is not already running
				if (!interp.isRunning(stack)) interp.toggleThread(stack, target);
			}
		}
		allStacksAndOwnersDo(startMatchingKeyHats);
	}

	// -----------------------------
	// Project Loading and Installing
	//------------------------------

	public function installEmptyProject():void {
		installProject(new ScratchStage());
	}
	
	public function installNewProject():void {
		var emptyProject:ScratchStage = new ScratchStage();
		emptyProject.addChild(new ScratchSprite('Sprite1'));
		installProject(emptyProject);
	}

	public function installProjectFromLocalFile():void {
		// Prompt user for a file name and load that file.
		function fileSelected(event:Event):void {
			if (fileList.fileList.length == 0) return;
			var file:FileReference = FileReference(fileList.fileList[0]);
			app.setProjectName(file.name);
			file.addEventListener(Event.COMPLETE, fileLoadHandler);
			file.load();
		}
		function fileLoadHandler(event:Event):void {
			var fileReference:FileReference = FileReference(event.target);
			installProjectFromData(fileReference.data);
		}
		stopAll();
		var fileList:FileReferenceList = new FileReferenceList();
		fileList.addEventListener(Event.SELECT, fileSelected);
		var allTypes:Array = [new FileFilter('Scratch Projects (*.sb, *.sb2, *.sprite)', '*.sb;*.sprite;*.sb2')];
		fileList.browse(allTypes);
	}

	public function installProjectFromData(data:ByteArray):void {
		var newProject:ScratchStage;
		stopAll();
Perf.start('Loading');
		data.position = 0;
		if (data.readUTFBytes(8) != 'ScratchV') {
			data.position = 0;
			newProject = new ProjectIO(app).decodeProjectFromZipFile(data);
		} else {
			var info:Object;
			var objTable:Array;
			data.position = 0;
			var reader:ObjReader = new ObjReader(data);
			try { info = reader.readInfo() } catch (e:Error) { data.position = 0 }
			try { objTable = reader.readObjTable() } catch (e:Error) { }
			if (objTable == null) return;
Perf.clearLap();
			newProject = new OldProjectReader().extractProject(objTable);
Perf.lap('Extract project');
			newProject.info = info;
			if (info != null) delete info.thumbnail; // delete old thumbnail
		}
Perf.clearLap();
		decodeImagesAndInstall(newProject);
	}

	public function decodeImagesAndInstall(newProject:ScratchStage):void {
		// Load all images in all costumes from their image data and proceed when done.
		function imageDecoded():void {
			var c:ScratchCostume;
			var imgCount:int;
			for each (var o:* in imageDict) {
				if (o == 'loading...') return;  // not yet finished loading
				imgCount++;
			}
			if (newProject.penLayerPNG) {
				newProject.penLayer.bitmapData = imageDict[newProject.penLayerPNG];
				newProject.penLayerPNG = null;
			}
			for each (c in allCostumes) {
				if ((c.baseLayerData != null) && (c.baseLayerBitmap == null)) {
					var img:* = imageDict[c.baseLayerData];
					if (img is BitmapData) c.baseLayerBitmap = img;
					if (img is SVGDocument) c.baseLayerSVG = img;
				}
				if ((c.textLayerData != null) && (c.textLayerBitmap == null)) c.textLayerBitmap = imageDict[c.textLayerData];
			}
			for each (c in allCostumes) c.generateOrFindComposite(allCostumes);
			projectToInstall = newProject; // stepRuntime() will finish installation
		}

		var c:ScratchCostume;
		var allCostumes:Array = [];
		for each (var o:ScratchObj in newProject.allObjects()) {
			for each (c in o.costumes) allCostumes.push(c);
		}
		var imageDict:Dictionary = new Dictionary(); // maps image data to BitmapData
		if (newProject.penLayerPNG) decodeImage(newProject.penLayerPNG, imageDict, imageDecoded);
		for each (c in allCostumes) {
			if ((c.baseLayerData != null) && (c.baseLayerBitmap == null)) decodeImage(c.baseLayerData, imageDict, imageDecoded);
			if ((c.textLayerData != null) && (c.textLayerBitmap == null)) decodeImage(c.textLayerData, imageDict, imageDecoded);
		}
		imageDecoded(); // handles case that there were no images to load
	}

	private function decodeImage(imageData:ByteArray, imageDict:Dictionary, doneFunction:Function):void {
		function loadDone(e:Event):void {
			imageDict[imageData] = e.target.content.bitmapData;
			doneFunction();
		}
		if (imageDict[imageData] != undefined) return; // already loading or loaded
		if (ScratchCostume.isSVGData(imageData)) {
			var svg:SVGDocument = new SVGDocument();
			svg.parse(imageData.readUTFBytes(imageData.length));
			imageDict[imageData] = svg;
			doneFunction();
			return;
		}
		imageDict[imageData] = 'loading...';
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadDone);
		loader.loadBytes(imageData);
	}

	private function installProject(project:ScratchStage):void {
Perf.lap('Load images');
		if (app.stagePane != null) stopAll();
		if (app.scriptsPane) app.scriptsPane.viewScriptsFor(null);

		for each (var obj:ScratchObj in project.allObjects()) {
			obj.showCostume(obj.currentCostumeIndex);
		}
		app.installStage(project);
		app.updateSpriteLibrary(true);
		// set the active sprite
		var allSprites:Array = app.stagePane.sprites();
		if (allSprites.length > 0) {
			allSprites = allSprites.sortOn('indexInLibrary');
			app.selectSprite(allSprites[0]);
		} else {
			app.selectSprite(app.stagePane);
		}
Perf.lap('Install project');
		// add and open extensions for this project
		app.extensionManager.step();
Perf.lap('Opened extensions');
Perf.end();
		app.projectLoaded();
	}

	// -----------------------------
	// Ask prompter
	//------------------------------

	public function showAskPrompt(question:String = ''):void {
		var p:AskPrompter = new AskPrompter(question, app);
		p.x = 15;
		p.y = ScratchObj.STAGEH - p.height - 5;
		app.stagePane.addChild(p);
		setTimeout(p.grabKeyboardFocus, 100); // work-dround for Window keyboard event handling
	}

	public function hideAskPrompt(p:AskPrompter):void {
		lastAnswer = p.answer();
		p.parent.removeChild(p);
		app.stage.focus = null;
	}

	public function askPromptShowing():Boolean {
		for (var i:int = 0; i < app.stagePane.numChildren; i++) {
			if (app.stagePane.getChildAt(i) is AskPrompter) return true;
		}
		return false;
	}

	public function clearAskPrompts():void {
		var allPrompts:Array = [];
		var c:DisplayObject;
		for (var i:int = 0; i < app.stagePane.numChildren; i++) {
			if ((c = app.stagePane.getChildAt(i)) is AskPrompter) allPrompts.push(c);
		}
		for each (c in allPrompts) app.stagePane.removeChild(c);
	}

	// -----------------------------
	// Keyboard input handling
	//------------------------------

	public function keyDown(evt:KeyboardEvent):void {
		var ch:int = evt.charCode;
		if (evt.charCode == 0) ch = mapArrowKey(evt.keyCode);
		if ((65 <= ch) && (ch <= 90)) ch += 32; // map A-Z to a-z
		if (!(evt.target is TextField)) startKeyHats(ch);
		if (ch < 128) keyIsDown[ch] = true;
	}

	public function keyUp(evt:KeyboardEvent):void {
		var ch:int = evt.charCode;
		if (evt.charCode == 0) ch = mapArrowKey(evt.keyCode);
		if ((65 <= ch) && (ch <= 90)) ch += 32; // map A-Z to a-z
		if (ch < 128) keyIsDown[ch] = false;
	}

	private function clearKeyDownArray():void {
		for (var i:int = 0; i < 128; i++) keyIsDown[i] = false;
	}

	private function mapArrowKey(keyCode:int):int {
		// map key codes for arrow keys to ASCII, other key codes to zero
		if (keyCode == 37) return 28;
		if (keyCode == 38) return 30;
		if (keyCode == 39) return 29;
		if (keyCode == 40) return 31;
		return 0;
	}

	// -----------------------------
	// Sensors
	//------------------------------

	public function getSensor(sensorName:String):Number {
		if (sensorName == 'distance') return app.extensionManager.getStateVar('WeDo', 'distance', 0);
		if (sensorName == 'tilt') return app.extensionManager.getStateVar('WeDo', 'tilt', 0);
		return 0;
	}

	public function getBooleanSensor(sensorName:String):Boolean {
		return false;
	}

	// -----------------------------
	// Variables
	//------------------------------

	public function createVariable(varName:String):void {
		app.viewedObj().lookupOrCreateVar(varName);
	}

	public function deleteVariable(varName:String):void {
		if (app.viewedObj().ownsVar(varName)) {
			app.viewedObj().deleteVar(varName);
		} else {
			app.stageObj().deleteVar(varName);
		}
	}

	public function allVarNames():Array {
		var result:Array = [], v:Variable;
		for each (v in app.stageObj().variables) result.push(v.name);
		if (!app.viewedObj().isStage) {
			for each (v in app.viewedObj().variables) result.push(v.name);
		}
		return result;
	}

	public function renameVariable(oldName:String, newName:String, block:Block):void {
		var v:Variable = app.viewedObj().lookupVar(oldName);
		if (v != null) v.name = newName;
		else app.viewedObj().lookupOrCreateVar(newName);
		updateVarRefs(oldName, newName);
	}

	public function updateVarRefs(oldName:String, newName:String):void {
		for each (var b:Block in allUsesOfVariable(oldName)) {
			b.cache = null;
			if (b.op == Specs.GET_VAR) b.setSpec(newName);
			else b.args[0].setArgValue(newName);
		}
	}

	// -----------------------------
	// Lists
	//------------------------------

	public function allListNames():Array {
		var result:Array = app.stageObj().listNames();
		if (!app.viewedObj().isStage) {
			result = result.concat(app.viewedObj().listNames());
		}
		return result;
	}

	public function createList(listName:String):ListWatcher {
		return app.viewedObj().lookupOrCreateList(listName);
	}

	// -----------------------------
	// Sensing
	//------------------------------

	public function timer():Number { return (interp.currentMSecs - timerBase) / 1000 }
	public function timerReset():void { timerBase = interp.currentMSecs }
	public function isLoud():Boolean { return soundLevel() > 10 }

	public function soundLevel():int {
		if (microphone == null) {
			microphone = Microphone.getMicrophone();
			microphone.setLoopBack(true);
			microphone.soundTransform = new SoundTransform(0, 0);
		}
		return microphone.activityLevel;
	}

	// -----------------------------
	// Script utilities
	//------------------------------

	public function clearRunFeedback():void {
		for each (var b:Block in allStacks()) b.hideRunFeedback();
	}

	public function allSendersOfBroadcast(msg:String):Array {
		// Return an array of all Scratch objects that broadcast the given message.
		var result:Array = [];
		for each (var o:ScratchObj in app.stagePane.allObjects()) {
			if (sendsBroadcast(o, msg)) result.push(o);
		}
		return result;
	}

	public function allReceiversOfBroadcast(msg:String):Array {
		// Return an array of all Scratch objects that receive the given message.
		var result:Array = [];
		for each (var o:ScratchObj in app.stagePane.allObjects()) {
			if (receivesBroadcast(o, msg)) result.push(o);
		}
		return result;
	}

	private function sendsBroadcast(obj:ScratchObj, msg:String):Boolean {
		for each (var stack:Block in obj.scripts) {
			var found:Boolean;
			stack.allBlocksDo(function (b:Block):void {
				if ((b.op == 'broadcast:') || (b.op == 'doBroadcastAndWait')) {
					if (b.args[0].argValue == msg) found = true;
				}
			});
			if (found) return true;
		}
		return false;
	}

	private function receivesBroadcast(obj:ScratchObj, msg:String):Boolean {
		msg = msg.toLowerCase();
		for each (var stack:Block in obj.scripts) {
			var found:Boolean;
			stack.allBlocksDo(function (b:Block):void {
				if (b.op == 'whenIReceive') {
					if (b.args[0].argValue.toLowerCase() == msg) found = true;
				}
			});
			if (found) return true;
		}
		return false;
	}

	public function allUsesOfVariable(varName:String):Array {
		var result:Array = [];
		for each (var stack:Block in allStacks()) {
			// for each block in stack
			stack.allBlocksDo(function (b:Block):void {
				if ((b.op == Specs.GET_VAR) && (b.spec == varName)) result.push(b);
				if ((b.op == Specs.SET_VAR) && (b.args[0].argValue == varName)) result.push(b);
				if ((b.op == Specs.CHANGE_VAR) && (b.args[0].argValue == varName)) result.push(b);
			});
		}
		return result;
	}

	public function allCallsOf(callee:String):Array {
		var result:Array = [];
		for each (var stack:Block in allStacks()) {
			// for each block in stack
			stack.allBlocksDo(function (b:Block):void {
				if ((b.op == Specs.CALL) && (b.spec == callee)) result.push(b);
			});
		}
		return result;
	}

	public function updateCalls():void {
		allStacksAndOwnersDo(function (b:Block, target:ScratchObj):void {
			if (b.op == Specs.CALL) {
				b.cache = null;
				if (target.lookupProcedure(b.spec) == null) {
					b.base.setColor(0xFF0000);
					b.base.redraw();
				}
				else b.base.setColor(Specs.procedureCallColor);
			}
		});
	}

	public function allStacks():Array {
		// return an array containing all stacks in all objects
		var result:Array = [];
		allStacksAndOwnersDo(
			function (stack:Block, target:ScratchObj):void { result.push(stack) });
		return result;
	}

	public function allStacksAndOwnersDo(f:Function):void {
		// call the given function on every stack in the project, passing the stack and owning sprite/stage
		// This method is used by broadcast, so enumerate sprites/stage from front to back to match Scratch.
		var stage:ScratchStage = app.stagePane;
		var stack:Block;
		for (var i:int = stage.numChildren - 1; i >= 0; i--) {
			var o:* = stage.getChildAt(i);
			if (o is ScratchObj) {
				for each (stack in ScratchObj(o).scripts) f(stack, o);
			}
		}
		for each (stack in stage.scripts) f(stack, stage);
	}

}}
