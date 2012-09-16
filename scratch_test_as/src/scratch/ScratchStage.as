// ScratchStage.as
// John Maloney, April 2010
//
// A Scratch stage object. Supports a drawing surface for the pen commands.

package scratch {
	import flash.display.*;
	import flash.geom.*;
	import flash.utils.ByteArray;
	import filters.FilterPack;
	import sound.*;
	import util.*;
	import watchers.*;

public class ScratchStage extends ScratchObj {

	[Embed(source='../assets/pop.wav', mimeType='application/octet-stream')] private var Pop:Class;

	public var info:Object = new Object();
	public var tempoBPM:Number = 60;

	public var penActivity:Boolean;
	public var newPenStrokes:Shape;
	public var penLayer:Bitmap;

	public var penLayerPNG:ByteArray;
	public var penLayerMD5:String;

	private var bg:Shape;

	public function ScratchStage() {
		objName = 'Stage';
		isStage = true;
		scrollRect = new Rectangle(0, 0, STAGEW, STAGEH); // clip drawing to my bounds
		cacheAsBitmap = true; // clip damage reports to my bounds

		addWhiteBG();
		img = new Sprite();
		img.addChild(new Bitmap(new BitmapData(1, 1)));
		addChild(img);		
		addPenLayer();
		initMedia();
		showCostume(0);
		filterPack = new FilterPack(this);
	}

	public function setTempo(bpm:Number):void {
		tempoBPM = Math.max(20, Math.min(bpm, 500));
	}

	public function objNamed(s:String):ScratchObj {
		// Return the object with the given name, or null if not found.
		if (objName == s) return this;
		return spriteNamed(s);
	}

	public function spriteNamed(spriteName:String):ScratchSprite {
		// Return the sprite with the given name, or null if not found.
		for each (var spr:ScratchSprite in sprites()) {
			if (spr.objName == spriteName) return spr;
		}
		var app:Scratch = parent as Scratch;
		if ((app != null) && (app.gh.carriedObj is ScratchSprite)) {
			spr = ScratchSprite(app.gh.carriedObj);
			if (spr.objName == spriteName) return spr;
		}
		return null;
	}

	private function initMedia():void {
		var bm:BitmapData = new BitmapData(STAGEW, STAGEH, false, 0xFFFFFF);
		costumes.push(new ScratchCostume('Scene 1', bm));
		sounds.push(new ScratchSound('pop', new Pop()));
	}

	private function addWhiteBG():void {
		bg = new Shape();
		bg.graphics.beginFill(0xFFFFFF);
		bg.graphics.drawRect(0, 0, STAGEW, STAGEH);
		addChild(bg);
	}

	private function addPenLayer():void {
		newPenStrokes = new Shape();
		var bm:BitmapData = new BitmapData(STAGEW, STAGEH, true, 0);
		penLayer = new Bitmap(bm);
		addChild(penLayer);
	}

	public function baseW():Number { return bg.width }
	public function baseH():Number { return bg.height }

	public function scratchMouseX():int { return mouseX - (STAGEW / 2) }
	public function scratchMouseY():int { return (STAGEH / 2) - mouseY }

	public function allObjects():Array {
		// Return an array of all sprites in this project plus the stage.
		var result:Array = sprites();
		result.push(this);
		return result;
	}

	public function sprites():Array {
		// Return an array of all sprites in this project.
		var result:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var o:* = getChildAt(i);
			if ((o is ScratchSprite) && !o.isClone) result.push(o);
		}
		return result;
	}

	public function deleteClones():void {
		var clones:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var o:* = getChildAt(i);
			if ((o is ScratchSprite) && o.isClone) clones.push(o);
		}
		for each (var c:ScratchSprite in clones) removeChild(c);
	}

	public function show(obj:DisplayObject, ensureOnStage:Boolean = false):void {
		obj.visible = true;
		if (ensureOnStage) {
			if ((obj.x + obj.width) > STAGEW) obj.x = STAGEW - obj.width;
			if ((obj.y + obj.height) > STAGEH) obj.y = STAGEH - obj.height;
			if (obj.x < 0) obj.x = 0;
			if (obj.y < 0) obj.y = 0;
		}
		addChild(obj);
	}

	// Scene support

	public function recordHiddenSprites():void {
		var scene:ScratchCostume = costumes[currentCostumeIndex];
		var hiddenSprites:Array = [];
		for each (var spr:ScratchSprite in sprites()) {
			if (!spr.visible) hiddenSprites.push(spr.objName);
		}
		scene.spritesHiddenInScene = hiddenSprites;
	}

	public function updateSpriteVisibility():void {
		var scene:ScratchCostume = costumes[currentCostumeIndex];
		var hiddenSprites:Array = scene.spritesHiddenInScene;
		if (hiddenSprites == null) return; // not using scenes
		for each (var spr:ScratchSprite in sprites()) {
			spr.visible = hiddenSprites.indexOf(spr.objName) < 0;
		}
	}

	// Pen support

	public function clearPenStrokes():void {
		var bm:BitmapData = penLayer.bitmapData;
		bm.fillRect(bm.rect, 0);
		newPenStrokes.graphics.clear();
		penActivity = false;
	}

	public function commitPenStrokes():void {
		penLayer.bitmapData.draw(newPenStrokes);
		newPenStrokes.graphics.clear();
		penActivity = false;
	}

	public function bitmapWithoutSprite(s:ScratchSprite):BitmapData {
		// used by the 'touching color' primitives
		var oldVisible:Boolean = s.visible;
		var i:int, child:DisplayObject;

		// hide the sprite and things like variable and list watchers
		// that should not be seen by 'touching color'
		var wasVisible:Array = [];
		s.visible = false;
		for (i = 0; i < this.numChildren; i++) {
			child = this.getChildAt(i);
			if (invisibleForColorTouching(child) && child.visible) {
				child.visible = false;
				wasVisible.push(child);
			}
		}

		var r:Rectangle = s.bounds();
		var bm:BitmapData = new BitmapData(r.width, r.height, false);

		var m:Matrix = new Matrix();
		m.translate(-r.x, -r.y);
		bm.draw(this, m);

		// restore visiblity of sprite and other objects that were hidden
		s.visible = oldVisible;
		for (i = 0; i < wasVisible.length; i++) wasVisible[i].visible = true;

		return bm;
	}

	private function invisibleForColorTouching(o:*):Boolean {
		return ((o is Watcher) || (o is ListWatcher) || (o is TalkBubble));
	}

	public function projectThumbnailPNG(w:int, h:int):ByteArray {
		// Generate project thumbnail with given dimensions.
		var bm:BitmapData = new BitmapData(w, h, false);
		var scale:Number = Math.min(w / STAGEW, h / STAGEH);
		var m:Matrix = new Matrix();
		m.scale(scale, scale);
		bm.draw(this, m);
		return new PNGMaker().encode(bm);
	}

	public function savePenLayer():void {
		penLayerPNG = new PNGMaker().encode(penLayer.bitmapData);
		penLayerMD5 = MD5.hashBinary(penLayerPNG) + '.png';
	}

	public function clearPenLayer():void {
		penLayerPNG = null;
		penLayerMD5 = null;
	}

	public override function writeJSON(json:JSON_AB):void {
		super.writeJSON(json);
		var children:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var c:DisplayObject = getChildAt(i);
			if (((c is ScratchSprite) && !ScratchSprite(c).isClone) || (c is Watcher)) {
				children.push(c);
			}
		}
		json.writeKeyValue('penLayerMD5', penLayerMD5);
		json.writeKeyValue('tempoBPM', tempoBPM);
		json.writeKeyValue('children', children);
		json.writeKeyValue('info', info);
	}

	public override function readJSON(jsonObj:Object):void {
		var children:Array, i:int, o:Object;

		// read stage fields
		super.readJSON(jsonObj);
		penLayerMD5 = jsonObj.penLayerMD5;
		tempoBPM = jsonObj.tempoBPM;
		children = jsonObj.children;
		info = jsonObj.info;

		// instantiate sprites and record their names
		var spriteNameMap:Object = new Object();
		spriteNameMap[objName] = this; // record stage's name
		for (i = 0; i < children.length; i++) {
			o = children[i];
			if (o.objName != undefined) { // o is a sprite record
				var s:ScratchSprite = new ScratchSprite();
				s.readJSON(o);
				spriteNameMap[s.objName] = s;
				children[i] = s;
			}
		}

		// instantiate Watchers and add all children (sprites and watchers)
		for (i = 0; i < children.length; i++) {
			o = children[i];
			if (o is ScratchSprite) {
				addChild(ScratchSprite(o));
			} else if (o.sliderMin != undefined) {  // o is a watcher record
				o.target = spriteNameMap[o.target]; // update target before instantiating
				var w:Watcher = new Watcher();
				w.readJSON(o);
				addChild(w);	
			}
		}

		// instantiate lists, variables, scripts, costumes, and sounds
		for each (var scratchObj:ScratchObj in allObjects()) {
			scratchObj.instantiateFromJSON(this);
		}
	}

}}
