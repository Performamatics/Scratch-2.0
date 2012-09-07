// ScratchObj.as
// John Maloney, April 2010
//
// This is the superclass for both ScratchStage and ScratchSprite,
// containing the variables and methods common to both.

package scratch {
	import flash.display.*;
	import flash.geom.*;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.text.*;
	import flash.utils.*;
	import blocks.*;
	import filters.FilterPack;
	import interpreter.*;
	import util.*;
	import watchers.*;

public class ScratchObj extends Sprite {

	public static const STAGEW:int = 480;
	public static const STAGEH:int = 360;

	public var objName:String = 'no name';
	public var isStage:Boolean = false;
	public var variables:Array = [];
	public var lists:Array = [];
	public var scripts:Array = [];
	public var sounds:Array = [];
	public var costumes:Array = [];
	public var currentCostumeIndex:Number;
	public var volume:Number = 100;
	public var instrument:int = 1;
	public var filterPack:FilterPack;
	public var isClone:Boolean;

	public var img:Sprite;  // holds a bitmap or svg object, after applying image filters, scale, and rotation

	// text costume support
	protected var costumeText:String;
	protected var costumeTextScale:Number = 1;
	protected var costumeFont:String = 'Arial';
	protected var costumeFontStyle:String = '';
	protected var costumeFontColor:int;

	// camera support
	public var videoImage:BitmapData;
	static private var camera:Camera;
	private var video:Video;
	private var mirrorVideo:Boolean = true;

	public function deleteCostume(c:ScratchCostume):void {
		if (costumes.length < 2) return; // a sprite must have at least one costume
		var i:int = costumes.indexOf(c);
		if (i < 0) return;
		costumes.splice(i, 1);
		if (currentCostumeIndex >= i) showCostume(currentCostumeIndex - 1);
	}

	public function deleteSound(snd:ScratchSound):void {
		var i:int = sounds.indexOf(snd);
		if (i < 0) return;
		sounds.splice(i, 1);
	}

	public function showCostumeNamed(n:String):void {
		if (n.indexOf('CAMERA') == 0) {
			mirrorVideo = (n == 'CAMERA - MIRROR');
			setCameraCostume(true);
			updateImage();
			return;
		}
		var i:int = indexOfCostumeNamed(n);
		if (i >= 0) showCostume(i);
	}

	public function indexOfCostumeNamed(n:String):int {
		for (var i:int = 0; i < costumes.length; i++) {
			if (ScratchCostume(costumes[i]).costumeName == n) return i;
		}
		return -1;
	}

	public function showCostume(costumeIndex:Number):void {
		if (costumeText != null) { // was showing text
			costumeText = null;
			if (this is ScratchSprite) ScratchSprite(this).setSize(100 * costumeTextScale);
		}
		setCameraCostume(false);
		currentCostumeIndex = costumeIndex % costumes.length;
		if (currentCostumeIndex < 0) currentCostumeIndex += costumes.length;
		var c:ScratchCostume = currentCostume();
		updateImage();
	}

	public function replaceCurrentCostumeBy(newCostume:ScratchCostume):void {
		costumes.splice(currentCostumeIndex, 1, newCostume);
	}

	public function currentCostume():ScratchCostume {
		return costumes[Math.round(currentCostumeIndex) % costumes.length]
	}

	public function costumeNumber():int {
		// One-based costume number as seen by user (currentCostumeIndex is 0-based)
		return currentCostumeIndex + 1;
	}

	public function setCostumeText(s:String):void {
		if (costumeText == null) costumeTextScale = scaleX;
		costumeText = s;
		scaleX = scaleY = 1;
		updateImage();
	}

	public function setCostumeFontAndColor(fontStyle:String, fontColor:int):void {
		switch (fontStyle) {
		case 'bold':
			costumeFont = 'Arial';
			costumeFontStyle = 'bold';
			break;
		case 'fancy':
			costumeFont = 'Times New Roman';
			costumeFontStyle = 'italic';
			break;
		case 'comic':
			costumeFont = 'Comic Sans MS';
			costumeFontStyle = '';
			break;
		case 'typewriter':
			costumeFont = 'Courier New';
			costumeFontStyle = 'bold';
			break;
		case 'plain':
		default:
			costumeFont = 'Arial';
			costumeFontStyle = '';
			break;
		}
		costumeFontColor = fontColor;
		updateImage();
	}

	protected function updateImage():void {
		while (img.numChildren > 0) img.removeChildAt(0);
		img.addChild(srcImage());
		clearCachedBitmap();
		adjustForRotationCenter();
	}

	private function srcImage():DisplayObject {
		if (videoImage) return new Bitmap(videoImage);
		if (costumeText) return new Bitmap(costumeTextBitmap());
		return currentCostume().displayObj();
	}

	private function adjustForRotationCenter():void {
		// Adjust the offset of img relative to it's parent. If the parent is a ScratchSprite
		// then img is adusted based on the costume's rotation center. If the parent is the
		// ScratchStage, img is centered on the stage.
		var costumeObj:DisplayObject = img.getChildAt(0);
		var centerX:int, centerY:int;
		if (videoImage || costumeText || isStage) {
			centerX = costumeObj.width / 2;
			centerY = costumeObj.height / 2;
		} else {
			var c:ScratchCostume = currentCostume();
			centerX = c.rotationCenterX;
			centerY = c.rotationCenterY;
			if ((this as ScratchSprite).isCostumeFlipped()) {
				costumeObj.scaleX = -1; // flip
				centerX = c.rotationCenterX - c.width();
			} else {
				costumeObj.scaleX = 1; // don't flip
			}
		}
		if (isStage) {
			img.x = (STAGEW / 2) - centerX;
			img.y = (STAGEH / 2) - centerY;
		} else {
			img.x = -centerX;
			img.y = -centerY;
		}
	}

	private function costumeTextBitmap():BitmapData {
		var format:TextFormat = new TextFormat(costumeFont, 100, costumeFontColor);
		if (costumeFontStyle.indexOf('bold') >= 0) format.bold = true;
		if (costumeFontStyle.indexOf('talic') >= 0) format.italic = true;

		var tf:TextField = new TextField();
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.backgroundColor = 0; // transparent
		tf.selectable = false; // not selectable
		tf.defaultTextFormat = format;
		tf.text = costumeText;

		// Compute the maximum scale that does not exceed the maximum bitmap size:
		var maxScale:Number = Math.sqrt(16777000  / (tf.width * tf.height)); // based on area
		maxScale = Math.min(maxScale, Math.min((8190 / tf.width), (8190 / tf.height)));
		var scale:Number = Math.min(costumeTextScale, maxScale);
		scale = Math.max(scale, Math.max(1 / tf.width, 1 / tf.height));
		var bm:BitmapData = new BitmapData(scale * tf.width, scale * tf.height, true, 0);
		var m:Matrix = new Matrix();
		m.scale(scale, scale);
		bm.draw(tf, m);
		return bm;
	}

	protected function clearCachedBitmap():void {
		// Does nothing here, but overridden in ScratchSprite		
	}

	public function applyFilters():void {
		img.filters = filterPack.buildFilters();
		clearCachedBitmap();
		var n:Number = Math.max(0, Math.min(filterPack.getFilterSetting('ghost'), 100));
		img.alpha = 1.0 - (n / 100.0);
	}

	public function clearFilters():void {
		if (filterPack != null) filterPack.resetAllFilters();
		img.filters = [];
		img.alpha = 1;
		clearCachedBitmap();
	}

	public function step():void {
		if (videoImage != null) {
			if (mirrorVideo) {
				// flip the image like a mirror
				var m:Matrix = new Matrix();
				m.scale(-1, 1);
				m.translate(video.width, 0);
				videoImage.draw(video, m);
			} else {
				videoImage.draw(video);
			}
			updateImage();
		}
	}

	private function setCameraCostume(useCamera:Boolean):void {
		if (!useCamera) {
			video = null;
			videoImage = null;
			return;
		}
		if (camera == null) {
			camera = Camera.getCamera();
			camera.setMode(640, 480, 30);
		}
		if (video == null) {
			video = (this is ScratchSprite) ? new Video(240, 180) : new Video(480, 360);
			video.attachCamera(camera);
			videoImage = new BitmapData(video.width, video.height, false);
		}
		updateImage();
	}

	public function setMedia(media:Array, currentCostume:ScratchCostume):void {
		var newCostumes:Array = [];
		sounds = [];
		for each (var m:* in media) {
			if (m is ScratchSound) sounds.push(m);
			if (m is ScratchCostume) newCostumes.push(m);
		}
		if (newCostumes.length > 0) costumes = newCostumes;
		var i:int = costumes.indexOf(currentCostume);
		currentCostumeIndex = (i < 0) ? 0 : i;
		showCostume(i);
	}

	/* Sounds */

	public function findSound(arg:*):ScratchSound {
		// Return a sound describe by arg, which can be a string (sound name),
		// a number (sound index), or a string representing a number (sound index).
		if (sounds.length == 0) return null;
		if (typeof(arg) == 'number') {
			var i:int = Math.round(arg - 1) % sounds.length;
			if (i < 0) i += sounds.length; // ensure positive
			return sounds[i];
		} else if (typeof(arg) == 'string') {
			for each (var snd:ScratchSound in sounds) {
				if (snd.soundName == arg) return snd; // arg matches a sound name
			}
			// try converting string arg to a number
			var n:Number = Number(arg);
			if (isNaN(n)) return null;
			return findSound(n);
		}	
		return null;
	}

	public function setVolume(vol:Number):void {
		volume = Math.max(0, Math.min(vol, 100));
	}

	public function setInstrument(instr:Number):void {
		instrument = Math.max(1, Math.min(Math.round(instr), 128));
	}

	/* Procedures */

	public function procedureDefinitions():Array {
		var result:Array = [];
		for (var i:int = 0; i < scripts.length; i++) {
			var b:Block = scripts[i] as Block;
			if (b && (b.op == Specs.PROCEDURE_DEF)) result.push(b);
		}
		return result;
	}

	public function lookupProcedure(procName:String):Block {
		for (var i:int = 0; i < scripts.length; i++) {
			var b:Block = scripts[i] as Block;
			if (b && (b.op == Specs.PROCEDURE_DEF) && (b.spec == procName)) return b;
		}
		return null;
	}

	/* Variables */

	public function varNames():Array {
		var varList:Array = [];
		for each (var v:Variable in variables) varList.push(v.name);
		return varList;
	}

	public function setVarTo(varName:String, value:*):void {
		lookupOrCreateVar(varName).value = value;
	}

	public function ownsVar(varName:String):Boolean {
		// Return true if this object owns a variable of the given name.
		for each (var v:Variable in variables) {
			if (v.name == varName) return true;
		}
		return false;
	}

	public function lookupOrCreateVar(varName:String):Variable {
		// Lookup and return a variable. If lookup fails, create the variable in this object.
		var v:Variable = lookupVar(varName);
		if (v == null) { // not found; create it
			v = new Variable(varName, 0);
			variables.push(v);
		}
		return v;
	}

	public function lookupVar(varName:String):Variable {
		// Look for variable first in sprite (local), then stage (global).
		// Return null if not found.
		var v:Variable;
		for each (v in variables) {
			if (v.name == varName) return v;
		}
		if (parent is ScratchStage) {
			for each (v in ScratchObj(parent).variables) {
				if (v.name == varName) return v;
			}
		}
		return null;
	}

	public function deleteVar(varToDelete:String):void {
		var newVars:Array = [];
		for each (var v:Variable in variables) {
			if (v.name == varToDelete) {
				if ((v.watcher != null) && (v.watcher.parent != null)) {
					v.watcher.parent.removeChild(v.watcher);
				}
				v.watcher = v.value = null;
			}
			else newVars.push(v);
		}
		variables = newVars;
	}

	/* Lists */

	public function listNames():Array {
		var result:Array = [];
		for each (var list:ListWatcher in lists) result.push(list.listName);
		return result;
	}

	public function lookupOrCreateList(listName:String):ListWatcher {
		// Look and return a list. If lookup fails, create the list in this object.
		var list:ListWatcher = lookupList(listName);
		if (list == null) { // not found; create it
			list = new ListWatcher(listName, [], this);
			lists.push(list);
		}
		return list;
	}

	public function lookupList(listName:String):ListWatcher {
		// Look for list first in this sprite (local), then stage (global).
		// Return null if not found.
		var list:ListWatcher;
		for each (list in lists) {
			if (list.listName == listName) return list;
		}
		if (parent is ScratchStage) {
			for each (list in ScratchObj(parent).lists) {
				if (list.listName == listName) return list;
			}
		}
		return null;
	}

	/* Saving */

	public function writeJSON(json:JSON_AB):void {
		var allScripts:Array = [];
		for each (var b:Block in scripts) {
			allScripts.push([b.x, b.y, BlockIO.stackToArray(b)]);
		}
		json.writeKeyValue('objName', objName);
		if (variables.length > 0)	json.writeKeyValue('variables', variables);
		if (lists.length > 0)		json.writeKeyValue('lists', lists);
		if (scripts.length > 0)		json.writeKeyValue('scripts', allScripts);
		if (sounds.length > 0)		json.writeKeyValue('sounds', sounds);
		json.writeKeyValue('costumes', costumes);
		json.writeKeyValue('currentCostumeIndex', currentCostumeIndex);
	}

	public function readJSON(jsonObj:Object):void {
		objName = jsonObj.objName;
		variables = (jsonObj.variables == undefined) ? [] : jsonObj.variables;
		for (var i:int = 0; i < variables.length; i++) {
			var varObj:Object = variables[i];
			variables[i] = new Variable(varObj.name, varObj.value);
			if (varObj.isPersistent != null) variables[i].isPersistent = varObj.isPersistent;
		}
		lists = (jsonObj.lists == undefined) ? [] : jsonObj.lists;
		scripts = (jsonObj.scripts == undefined) ? [] : jsonObj.scripts;
		sounds = (jsonObj.sounds == undefined) ? [] : jsonObj.sounds;
		costumes = jsonObj.costumes;
		currentCostumeIndex = jsonObj.currentCostumeIndex;
	}

	public function instantiateFromJSON(newStage:ScratchStage):void {
		var i:int, jsonObj:Object;

		// lists
		for (i = 0; i < lists.length; i++) {
			jsonObj = lists[i];
			jsonObj.target = newStage.objNamed(jsonObj.target);
			var newList:ListWatcher = new ListWatcher();
			newList.readJSON(jsonObj);
			if (jsonObj.visible) newStage.addChild(newList);
			newList.updateTitleAndContents();
			lists[i] = newList;
		}

		// scripts
		for (i = 0; i < scripts.length; i++) {
			// entries are of the form: [x y stack]
			var entry:Array = scripts[i];
			var b:Block = BlockIO.arrayToStack(entry[2]);
			b.x = entry[0];
			b.y = entry[1];
			scripts[i] = b;
		}

		// sounds
		for (i = 0; i < sounds.length; i++) {
			jsonObj = sounds[i];
			sounds[i] = new ScratchSound('json temp', null);
			sounds[i].readJSON(jsonObj);
		}

		// costumes
		for (i = 0; i < costumes.length; i++) {
			jsonObj = costumes[i];
			costumes[i] = new ScratchCostume('json temp', null);
			costumes[i].readJSON(jsonObj);
		}
	}

}}
