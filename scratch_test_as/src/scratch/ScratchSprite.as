// ScratchSprite.as
// John Maloney, April 2010
//
// A Scratch sprite object. State specific to sprites includes: position, direction,
// rotation style, size, draggability, and pen state.

package scratch {
	import flash.display.*;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import com.lorentz.SVG.display.*;
	import filters.FilterPack;
	import primitives.*;
	import sound.*;
	import uiwidgets.Menu;
	import util.*;
	import interpreter.Variable;
	import watchers.ListWatcher;

public class ScratchSprite extends ScratchObj {

	[Embed(source="../assets/empty.png")] private var emptycostume:Class;	
	[Embed(source="../assets/cat1.gif")] private var Cat1:Class;
	[Embed(source="../assets/cat2.gif")] private var Cat2:Class;
	[Embed(source="../assets/pop.wav", mimeType="application/octet-stream")] private var Pop:Class;

	public var scratchX:Number;
	public var scratchY:Number;
	public var direction:Number = 90;
	public var rotationStyle:String = "normal"; // "normal", "leftRight", "none"

	public var isDraggable:Boolean = false;
	public var indexInLibrary:int;
	private var bubble:TalkBubble;

	public var penIsDown:Boolean;
	public var penWidth:Number = 1;
	public var penHue:Number = 120; // blue
	public var penShade:Number = 50; // full brightness and saturation
	public var penColorCache:Number = 0xFF;

	private var cachedBitmap:BitmapData;	// current costume, rotated & scaled
	private var cachedBounds:Rectangle;		// bounds of non-tranparent cachedBitmap in stage coords

	public function ScratchSprite(name:String = "Sprite") {
		objName = name;
		initMedia();
		img = new Sprite();
		addChild(img);
		showCostume(0);
		setScratchXY(0, 0);
		filterPack = new FilterPack(this);
	}

	private function initMedia():void {
		costumes.push(new ScratchCostume("Costume1", new Cat1().bitmapData));
		costumes.push(new ScratchCostume("Costume2", new Cat2().bitmapData));
		sounds.push(new ScratchSound("pop", new Pop()));
	}

	public function setEmptyCostume():void {
		costumes = [new ScratchCostume("Untitled", new emptycostume().bitmapData)];
		showCostume(0);
	}

	public function setInitialCostume(c:ScratchCostume):void {
		costumes = [c];
		showCostume(0);
	}

	public function initFrom(spr:ScratchSprite, forClone:Boolean):void {
		// Copy all the state from the given sprite. Used by both
		// the clone block and the "duplicate" sprite menu command.
		var i:int;
		for (i = 0; i < spr.variables.length; i++) {
			var v:Variable = spr.variables[i];
			variables.push(new Variable(v.name, v.value));
		}
		for (i = 0; i < spr.lists.length; i++) {
			var lw:ListWatcher = spr.lists[i]
			lists.push(new ListWatcher(lw.listName, lw.contents, spr));
		}
		for (i = 0; i < spr.scripts.length; i++) scripts.push(spr.scripts[i].duplicate(forClone));
		sounds = spr.sounds.concat();
		costumes = spr.costumes.concat();
		currentCostumeIndex = spr.currentCostumeIndex;
		volume = spr.volume;
		instrument = spr.instrument;
		filterPack = spr.filterPack.duplicateFor(this);

		visible = spr.visible;
		scratchX = spr.scratchX;
		scratchY = spr.scratchY;
		direction = spr.direction;
		rotationStyle = spr.rotationStyle;
		isClone = forClone;
		isDraggable = spr.isDraggable;
		indexInLibrary = 100000;

		penIsDown = spr.penIsDown;
		penWidth = spr.penWidth;
		penHue = spr.penHue;
		penShade = spr.penShade;
		penColorCache = spr.penColorCache;

		showCostume(spr.currentCostumeIndex);
		setDirection(spr.direction);
		setScratchXY(spr.scratchX, spr.scratchY);
		setSize(spr.getSize());
		applyFilters();
	}

	public function addCostume(s:String, bmData:BitmapData):void {
		costumes.push(new ScratchCostume(s, bmData));
	}

	public function setScratchXY(newX:Number, newY:Number):void {
		scratchX = newX;
		scratchY = newY;
		x = 240 + scratchX;
		y = 180 - scratchY;
		updateBubble();
	}

	public function keepOnStage():void {
		var myBox:Rectangle = bounds();
		var inset:int = Math.min(18, Math.min(myBox.width, myBox.height) / 2);
		var edgeBox:Rectangle = new Rectangle(inset, inset, 480 - (2 * inset), 360 - (2 * inset));
		if (myBox.intersects(edgeBox)) return; // sprite is sufficiently on stage
		if (myBox.right < edgeBox.left) x += edgeBox.left - myBox.right;
		if (myBox.left > edgeBox.right) x -= myBox.left - edgeBox.right;
		if (myBox.bottom < edgeBox.top) y += edgeBox.top - myBox.bottom;
		if (myBox.top > edgeBox.bottom) y -= myBox.top - edgeBox.bottom;
		scratchX = x - 240;
		scratchY = 180 - y;
		updateBubble();
	}

	public function setDirection(d:Number):void {
		d = d % 360;
		if (d < 0) d += 360;
		direction = (d > 180) ? d - 360 : d;
		if (rotationStyle == "normal") rotation = (direction - 90) % 360;
		else rotation = 0;
		updateImage();
	}

	public function getSize():Number {
		return  100 * ((costumeText == null) ? scaleX : costumeTextScale);
	}

	public function setSize(percent:Number):void {
		var newScale:Number = percent / 100.0;
		if (costumeText != null) {
			newScale = Math.max(0.01, newScale);
			scaleX = scaleY = 1;
			costumeTextScale = newScale;
			updateImage();
		} else {
			var origW:int = img.width;
			var origH:int = img.height;
			var minScale:Number = Math.min(1, Math.max(5 / origW, 5 / origH));
			var maxScale:Number = Math.min((1.5 * 480) / origW, (1.5 * 360) / origH);
			newScale = Math.max(minScale, Math.min(newScale, maxScale));
			scaleX = scaleY = newScale;
		}
		clearCachedBitmap();
	}

	public function setPenSize(n:Number):void {
		penWidth = Math.max(1, Math.min(Math.round(n), 255)); // 255 is the maximum line with supported by Flash
	}

	public function setPenColor(c:Number):void {
		var hsv:Array = Color.rgb2hsv(c);
		penHue = (200 * hsv[0]) / 360 ;
		penShade = 50 * hsv[2];  // not quite right; doesn't account for saturation
		penColorCache = c;
	}

	public function setPenHue(n:Number):void {
		penHue = n % 200;
		if (penHue < 0) penHue += 200;
		updateCachedPenColor();
	}

	public function setPenShade(n:Number):void {
		penShade = n % 200;
		if (penShade < 0) penShade += 200;
		updateCachedPenColor();
	}

	private function updateCachedPenColor():void {
		var c:int = Color.fromHSV((penHue * 180) / 100, 1, 1);
		var shade:Number = (penShade > 100) ? 200 - penShade : penShade; // range 0..100
		if (shade < 50) {
			penColorCache = Color.mixRGB(0, c, (10 + shade) / 60);
		} else {
			penColorCache = Color.mixRGB(c, 0xFFFFFF, (shade - 50) / 60);
		}
	}

	public function isCostumeFlipped():Boolean {
		return (rotationStyle == "leftRight") && (direction < 0);
	}

	protected override function clearCachedBitmap():void {
		cachedBitmap = null;
		cachedBounds = null;
	}

	public override function hitTestPoint(globalX:Number, globalY:Number, shapeFlag:Boolean = true):Boolean {
		if ((!visible) || (img.alpha == 0)) return false;
		var p:Point = parent.globalToLocal(new Point(globalX, globalY));
		var myRect:Rectangle = bounds();
		if (!myRect.containsPoint(p)) return false;
		return shapeFlag ? bitmap().hitTest(myRect.topLeft, 1, p) : true;
	}

	public function bounds():Rectangle {
		// return the bounding rectangle of my visible pixels (scaled and rotated)
		// in the coordinate system of my parent (i.e. the stage)
		if (cachedBounds == null) bitmap(); // computes cached bounds
		var result:Rectangle = cachedBounds.clone();
		result.offset(x, y);
		return result;
	}

	public function bitmap():BitmapData {
		if (cachedBitmap != null) return cachedBitmap;
	
		// compute cachedBitmap
		// Note: cachedBitmap must be drawn with alpha=1 to allow the sprite/color touching tests to work
		var m:Matrix = new Matrix();
		m.rotate((Math.PI * rotation) / 180);
		m.scale(scaleX, scaleY);
		var r:Rectangle = transformedBounds(img.getBounds(this), m);
		cachedBitmap = new BitmapData(Math.max(r.width, 1), Math.max(r.height, 1), true, 0);
		m.translate(-r.left, -r.top);
		var oldAlpha:Number = img.alpha;
		img.alpha = 1;
		cachedBitmap.draw(this, m);
		img.alpha = oldAlpha;
		cachedBounds = cachedBitmap.rect;

		// crop cachedBitmap and record cachedBounds
		// Note: handles the case where cropR is empty
		var cropR:Rectangle = cachedBitmap.getColorBoundsRect(0xFF000000, 0, false);
		if ((cropR.width > 0) && (cropR.height > 0)) {
			var cropped:BitmapData = new BitmapData(cropR.width, cropR.height, true, 0);
			cropped.copyPixels(cachedBitmap, cropR, new Point(0, 0));
			cachedBitmap = cropped;
			cachedBounds = cropR;
		}
		cachedBounds.offset(r.x, r.y);
		return cachedBitmap;
	}

	private function transformedBounds(r:Rectangle, m:Matrix):Rectangle {
		// Return the rectangle that encloses the corners of r when transformed by m.
		var p1:Point = m.transformPoint(r.topLeft);
		var p2:Point = m.transformPoint(new Point(r.right, r.top));
		var p3:Point = m.transformPoint(new Point(r.left, r.bottom));
		var p4:Point = m.transformPoint(r.bottomRight);
		var xMin:Number, xMax:Number, yMin:Number, yMax:Number;
		xMin = Math.min(p1.x, p2.x, p3.x, p4.x);
		yMin = Math.min(p1.y, p2.y, p3.y, p4.y);
		xMax = Math.max(p1.x, p2.x, p3.x, p4.x);
		yMax = Math.max(p1.y, p2.y, p3.y, p4.y);
		var newR:Rectangle = new Rectangle(xMin, yMin, xMax - xMin, yMax - yMin);
		return newR;
	}

	/* Menu */

	public function menu():Menu {
		var m:Menu = new Menu();
		m.addItem("duplicate", duplicateSprite);
		m.addItem("delete", deleteSprite);
		return m;
	}

	public function duplicateSprite():void {
		var dup:ScratchSprite = new ScratchSprite();
		dup.initFrom(this, false);
		dup.objName = unusedSpriteName();
		dup.setScratchXY(this.scratchX + 10, this.scratchY + 10);
		if (parent != null) {
			parent.addChild(dup);
			if (parent.root is Scratch) Scratch(parent.root).updateSpriteLibrary();
		}
	}

	private function deleteSprite():void {
		if (parent != null) {
			var app:Scratch;
			if (parent.root is Scratch) app = Scratch(parent.root);
			parent.removeChild(this);
			if (app) app.updateSpriteLibrary();
		}
	}

	public function unusedSpriteName(baseName:String = 'Sprite'):String {
		if (!(parent is ScratchStage)) return 'Sprite';
		var existingNames:Array = [];
		for each (var s:ScratchSprite in ScratchStage(parent).sprites()) {
			existingNames.push(s.objName.toLowerCase());
		}
		var i:int = 1;
		while (existingNames.indexOf(baseName + i) >= 0) { i++ } // find an unused name
		return baseName + i;
	}

	// talk/think bubble support

	public function showBubble(s:String, type:String, isAsk:Boolean = false):void {
		hideBubble();
		if (s == null) s = 'NULL';
		if (s.length == 0) return;
		bubble = new TalkBubble(s, type, isAsk);
		parent.addChild(bubble);
		updateBubble();
	}

	public function hideBubble():void {
		if (bubble == null) return;
		bubble.parent.removeChild(bubble);
		bubble = null;
	}

	public function updateBubble():void {
		if (bubble == null) return;
		if (bubble.visible != visible) bubble.visible = visible;
		if (!visible) return;
		var pad:int = 3;
		var stageL:int = pad;
		var stageR:int = STAGEW - pad;
		var stageH:int = STAGEH;
		var r:Rectangle = this.getBounds(parent);  // this sprite's screen rectangle

		// decide which side of the sprite the bubble should be on
		var bubbleOnRight:Boolean = bubble.pointsLeft;
		if (bubbleOnRight && ((r.x + r.width + bubble.width) > stageR)) bubbleOnRight = false;
		if (!bubbleOnRight && ((r.x - bubble.width) < 0)) bubbleOnRight = true;

		if (bubbleOnRight) {
			bubble.setDirection("left");
			bubble.x = r.x + r.width;
		} else {
			bubble.setDirection("right");
			bubble.x = r.x + - bubble.width;
		}

		// make sure bubble stays on screen
		if ((bubble.x + bubble.width) > stageR) bubble.x = stageR - bubble.width;
		if (bubble.x < stageL) bubble.x = stageL;
		bubble.y = Math.max(r.y - bubble.height, pad);
		if ((bubble.y + bubble.height) > stageH) {
			bubble.y = stageH - bubble.height;
		}
	}

	/* Saving */

	public override function writeJSON(json:JSON_AB):void {
		super.writeJSON(json);
		json.writeKeyValue("scratchX", scratchX);
		json.writeKeyValue("scratchY", scratchY);
		json.writeKeyValue("scale", scaleX);
		json.writeKeyValue("direction", direction);
		json.writeKeyValue("rotationStyle", rotationStyle);
		json.writeKeyValue("isDraggable", isDraggable);
		json.writeKeyValue("indexInLibrary", indexInLibrary);
		json.writeKeyValue("visible", visible);
	}

	public override function readJSON(jsonObj:Object):void {
		super.readJSON(jsonObj);
		scratchX = jsonObj.scratchX;
		scratchY = jsonObj.scratchY;
		scaleX = scaleY = jsonObj.scale;
		direction = jsonObj.direction;
		rotationStyle = jsonObj.rotationStyle;
		isDraggable = jsonObj.isDraggable;
		indexInLibrary = jsonObj.indexInLibrary;
		visible = jsonObj.visible;
		setScratchXY(scratchX, scratchY);
	}

}}
