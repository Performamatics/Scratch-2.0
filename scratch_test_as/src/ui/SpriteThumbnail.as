package ui {
	import flash.display.*;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.*;
	import flash.text.*;
	import assets.Resources;
	import scratch.*;
	import uiwidgets.*;

public class SpriteThumbnail extends Sprite {

	public var targetObj:ScratchObj;

	private var app:Scratch;
	private var thumbnail:Bitmap;
	private var label:TextField;
	private var selectedFrame:Shape;
	private var highlightFrame:Bitmap;
	private var infoSprite:Sprite;

	private var lastSrcImg:DisplayObject;
	private var lastName:String = '';

	public function SpriteThumbnail(targetObj:ScratchObj, app:Scratch) {
		this.targetObj = targetObj;
		this.app = app;

		selectedFrame = createSelectFrame();
		selectedFrame.visible = false;
		addChild(selectedFrame);

		thumbnail = new Bitmap();
		thumbnail.x = 8;
		addChild(thumbnail);

		label = Resources.makeLabel('', CSS.thumbnailFormat);
		label.width = 80;
		addChild(label);

		updateThumbnail();
	}

	private function createSelectFrame():Shape {
		var sh:Shape = new Shape();
		var g:Graphics = sh.graphics;
		g.beginFill(CSS.overColor);
		g.drawRoundRect(0, 0, 80, 76, 12, 12);
		g.endFill();
		return sh;
	}
	
	public function setTarget(obj:ScratchObj):void {
		targetObj = obj;
		updateThumbnail();
	}

	public function select(flag:Boolean):void {
		if (selectedFrame.visible == flag) return;
		selectedFrame.visible = flag;
		var c:int = flag ? CSS.white : CSS.textColor;
		if (label.textColor != c) label.textColor = c;
	}

	public function showHighlight(flag:Boolean):void {
		// Display a highlight if flag is true (e.g. to show broadcast sender/eceivers).
		if (highlightFrame) {
			removeChild(highlightFrame);
			highlightFrame = null;
		}
		if (flag) {
			highlightFrame = Resources.createBmp("sprhighlighted");
			addChild(highlightFrame);
		}
	}

	public function showInfo(flag:Boolean):void {
		if (infoSprite) {
			removeChild(infoSprite);
			infoSprite = null;
		}
		if (flag) {
			infoSprite = makeInfoSprite();
			addChild(infoSprite);
		}
	}

	public function makeInfoSprite():Sprite {
		var result:Sprite = new Sprite();
		var bm:Bitmap = Resources.createBmp('hatshape');
		bm.x = (80 - bm.width) / 2;
		bm.y = 20;
		result.addChild(bm);
		var tf:TextField = Resources.makeLabel(String(targetObj.scripts.length), CSS.normalTextFormat);
		tf.x = bm.x + 20 - (tf.textWidth / 2);
		tf.y = bm.y + 4;
		result.addChild(tf);
		return result;
	}

	public function updateThumbnail():void {
		if (targetObj == null) return;
		updateName();
		var sizew:int = selectedFrame.width - 15;
		var sizeh:int = selectedFrame.height - 15;
		var srcImg:DisplayObject = targetObj.img.getChildAt(0);
		if (srcImg == lastSrcImg) return; // thumbnail is up to date
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
		lastSrcImg = srcImg;
		thumbnail.bitmapData = tmp;
		thumbnail.y = (targetObj.isStage) ? 2 : 0;
		thumbnail.filters = getBorder(); // to show properly white on white 
	}

	private function getBorder():Array{
		var f:GlowFilter = new GlowFilter(CSS.onColor);
		f.strength = 1;
		f.blurX = f.blurY =2;
		f.knockout = false;
		return [f];
	}
	
	private function updateName():void {
		var s:String = (targetObj.isStage) ? targetObj.currentCostume().costumeName : targetObj.objName;
		if (s == lastName) return;
		lastName = s;
		label.text = s;
		while ((label.textWidth > 60) && (s.length > 0)) {
			s = s.substring(0, s.length - 1);
			label.text = s + '\u2026';  // truncated name with ellipses
		}
		label.x = (80 - label.textWidth) / 2;
		label.y = 76 - 18;
	}

	// -----------------------------
	// User interaction
	//------------------------------

	public function menu():Menu {
		function hideInScene():void { targetObj.visible = false }
		function showInScene():void { targetObj.visible = true }
		if (targetObj.isStage) return null;
		var m:Menu = (targetObj as ScratchSprite).menu(); // basic sprite menu
		m.addLine();
		if (targetObj.visible) {
			m.addItem("hide", hideInScene);
		} else {
			m.addItem("show", showInScene);
		}
		return m;
	}

	public function click(evt:Event):void {
		app.selectSprite(targetObj);
	}

}}
