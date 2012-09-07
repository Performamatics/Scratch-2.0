// ObjectInfoPart.as
// John Maloney, November 2011
//
// This part shows information about the currently selected object (the stage or a sprite).

package ui.parts {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.text.*;
	import assets.Resources;
	import uiwidgets.*;
	import scratch.ScratchSprite;
	import scratch.ScratchObj;

public class ObjectInfoPart extends UIPart {

	private const readoutLabelFormat:TextFormat = new TextFormat('Lucida Grande', 12, 0xA6A8AB, true);
	private const readoutFormat:TextFormat = new  TextFormat('Lucida Grande', 12, 0xA6A8AB);
	private const stageNameFormat:TextFormat = new TextFormat('Lucida Grande', 12, 0xA6A8AB);
	private const spriteInfoColor:int = 0xFFFFFF;
	private const DegreesToRadians:Number = (2 * Math.PI) / 360;

	private var shape:Shape;

	// stage info
	private var stageInfo:Sprite;
	private var stageName:TextField;

	// sprite info
	private var spriteInfo:Sprite;
	private var spriteName:EditableLabel;
	private var xReadout:TextField;
	private var yReadout:TextField;
	private var dirReadout:TextField;
	private var dirWheel:Sprite;
	private var lockButton:Sprite;
	private var lastX:Number, lastY:Number, lastDirection:Number;
	private	var thumbnail:Bitmap; 
	
	public function ObjectInfoPart(app:Scratch) {
		this.app = app;
		shape = new Shape();
		addChild(shape);
		addStageInfo();
		addSpriteInfo();		
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();
		g.beginFill(spriteInfoColor);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	public function step():void {
		if (spriteInfo.visible) updateSpriteInfo();
	}

	public function refresh():void {
		selectStageOrSpriteInfo();
		if (spriteInfo.visible) {
			spriteName.setContents(app.viewedObj().objName);
			updateRotationStyle();
			updateSpriteInfo();
		}
	}

	private function selectStageOrSpriteInfo():void {
		// Make sure the currect info is showing for the currently selected object.
		if (app.viewedObj().isStage) {
			if (!stageInfo.visible) {
				stageInfo.visible = true;
				spriteInfo.visible = false;
			}
		} else {
			if (!spriteInfo.visible) {
				spriteInfo.visible = true;
				stageInfo.visible = false;
			}
		}
	}

	private function addStageInfo():void {
		stageInfo = new Sprite();
		stageName = makeLabel('Stage', stageNameFormat, 5, 2);
		stageInfo.addChild(stageName);
		stageInfo.visible = false;
		addChild(stageInfo);
	}

	private function addSpriteInfo():void {
		var nextY:int = 20;

		spriteInfo = new Sprite();
		spriteName = new EditableLabel(nameChanged);
		spriteName.setWidth(200);
		spriteName.x = 120;
		spriteName.y = nextY;
		spriteInfo.addChild(spriteName);

		// x and y readouts
		nextY += 35;
		xReadout = makeLabel('-888', readoutFormat, 120 + 18, nextY);
		spriteInfo.addChild(xReadout);
		spriteInfo.addChild(makeLabel('x:', readoutLabelFormat, xReadout.x - 18, nextY));

		yReadout = makeLabel('-888', readoutFormat, 190 + 18, nextY);
		spriteInfo.addChild(yReadout);
		spriteInfo.addChild(makeLabel('y:', readoutLabelFormat, yReadout.x - 18, nextY));

		// direction wheel and readout
		dirWheel = new Sprite();
		dirWheel.x = 270;
		dirWheel.y = nextY + 10;
		spriteInfo.addChild(dirWheel);
		dirReadout = makeLabel('-179', readoutFormat,270 + 15, nextY);
		spriteInfo.addChild(dirReadout);

		// rotation style buttons
		var b:IconButton;
		nextY += 30;
		spriteInfo.addChild(b = new IconButton(rotate360, 'rotate360', null, true));
		b.x = 120;
		b.y = nextY;
		spriteInfo.addChild(b = new IconButton(rotateFlip, 'flip', null, true));
		b.x = 150;
		b.y = nextY;
		spriteInfo.addChild(b = new IconButton(rotateNone, 'norotation', null, true));
		b.x = 180;
		b.y = nextY;

		// lock button
		lockButton = new IconButton(toggleLock, 'unlocked');
		lockButton.x = 220;
		lockButton.y = nextY + 1;
		spriteInfo.addChild(lockButton);

		spriteInfo.visible = false;
		thumbnail = new Bitmap();
		thumbnail.x = thumbnail.y = 5;
		spriteInfo.addChild(thumbnail);
		addChild(spriteInfo);
	}

	private function rotate360(ignore:*):void {
		var spr:ScratchSprite = app.viewedObj() as ScratchSprite;
		if (spr == null) return;
		spr.rotationStyle = 'normal';
	}
	private function rotateFlip(ignore:*):void {
		var spr:ScratchSprite = app.viewedObj() as ScratchSprite;
		if (spr == null) return;
		spr.rotationStyle = 'leftRight';
	}

	private function rotateNone(ignore:*):void {
		var spr:ScratchSprite = app.viewedObj() as ScratchSprite;
		if (spr == null) return;
		spr.rotationStyle = 'none';
	}

	public function toggleLock(b:IconButton):void {
		var spr:ScratchSprite = ScratchSprite(app.viewedObj());
		if (spr) spr.isDraggable = b.isOn();
	}

	private function updateSpriteInfo():void {
		// Update the sprite info. Do nothing if a field is already up to date (to minimize CPU load).
		var spr:ScratchSprite = app.viewedObj() as ScratchSprite;
		if (spr == null) return;
		updateThumbnail();
		if (spr.scratchX != lastX) {
			xReadout.text = String(Math.round(spr.scratchX));
			lastX = spr.scratchX;
		}
		if (spr.scratchY != lastY) {
			yReadout.text = String(Math.round(spr.scratchY));
			lastY = spr.scratchY;
		}
		if (spr.direction != lastDirection) {
			dirReadout.text = String(Math.round(spr.direction)) + '\u00B0';
			drawDirWheel(spr.direction);
			lastDirection = spr.direction;
		}
	}

	private function drawDirWheel(dir:Number):void {
		var r:Number = 10;
		var g:Graphics = dirWheel.graphics;
		g.clear();
	
		// circle
		g.lineStyle(2, 0xD0D0D0, 1, true);
		g.drawCircle (0, 0, r - 2);
		// g.endFill();
	
		// direction pointer
	 	g.lineStyle(3, 0x006080, 1, true);
		g.moveTo(0, 0);
		var dx:Number = r * Math.sin(DegreesToRadians * (180 - dir));
		var dy:Number = r * Math.cos(DegreesToRadians * (180 - dir));
		g.lineTo(dx, dy);
	}

	private function nameChanged(evt:Event):void {
		app.viewedObj().objName = spriteName.contents();
	}

	public function updateThumbnail():void {
		var targetObj:ScratchObj = app.viewedObj();

		if (targetObj == null) return;
		var sizew:int = 100;
		var sizeh:int = 100;
		var srcImg:DisplayObject = targetObj.img.getChildAt(0);
		var tmp:BitmapData = new BitmapData(sizew, sizeh, true, 0x00FFFFFF); // transparent fill color
		var scale:Number = Math.min(sizew / srcImg.width, sizeh / srcImg.height);
		var m:Matrix = new Matrix();
		if (scale < 1) { // scale down a large image
			m.scale(scale, scale);
			m.translate((sizew - (scale * srcImg.width)) / 2, (sizeh - (scale * srcImg.height)) / 2);
		} else { // center a smaller image
			m.translate((sizew - srcImg.width) / 2, (sizeh - srcImg.height) / 2);
		}
		tmp.draw(srcImg, m);
		thumbnail.bitmapData = tmp;
	}

	private function updateRotationStyle():void {
		var targetObj:ScratchSprite = app.viewedObj() as ScratchSprite;
		if (targetObj == null) return;
		for (var i:int = 0; i < spriteInfo.numChildren; i++) {
			var b:IconButton = spriteInfo.getChildAt(i) as IconButton;
			if (b) {
				if (b.clickFunction == rotate360) b.setOn(targetObj.rotationStyle == 'normal');
				if (b.clickFunction == rotateFlip) b.setOn(targetObj.rotationStyle == 'leftRight');
				if (b.clickFunction == rotateNone) b.setOn(targetObj.rotationStyle == 'none');
			}
		}
	}

}}
