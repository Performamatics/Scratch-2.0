package uiwidgets {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;
	import flash.geom.Point;
	import util.DragClient

public class Scrollbar extends Sprite implements DragClient {

	public static var color:int = 0xBBBDBF;
	public static var sliderColor:int = 0x929497;
	public static var cornerRadius:int = 9;
	public static var look3D:Boolean = false;

	public var w:int, h:int;

	private var base:Shape;
	private var slider:Shape;
	private var positionFraction:Number = 0;		// scroll amount (range: 0-1)
	private var sliderSizeFraction:Number = 0.1;	// slider size, used to show fraction of docutment vislbe (range: 0-1)
	private var isVertical:Boolean;
	private var dragOffset:int;
	private var scrollFunction:Function;

	public function Scrollbar(w:int, h:int, scrollFunction:Function = null) {
		this.scrollFunction = scrollFunction;
		base = new Shape();
		slider = new Shape();
		addChild(base);
		addChild(slider);
		if (look3D) addFilters();
		alpha = 0.5;
		setWidthHeight(w, h);
		allowDragging(true);
	}

	public function scrollValue():Number { return positionFraction }
	public function sliderSize():Number { return sliderSizeFraction }

	public function update(position:Number, sliderSize:Number = 0):void {
		// Update the scrollbar scroll position (0-1) and slider size (0-1)
		var newPosition:Number = Math.max(0, Math.min(position, 1));
		var newSliderSize:Number = Math.max(0, Math.min(sliderSize, 1));
		if ((newPosition != positionFraction) || (newSliderSize != sliderSizeFraction)) {
			positionFraction = newPosition;
			sliderSizeFraction = newSliderSize;
			drawSlider();
			slider.visible = sliderSizeFraction < 1;
		}
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		base.graphics.clear();
		base.graphics.beginFill(color);
		base.graphics.drawRoundRect(0, 0, w, h, cornerRadius, cornerRadius);
		base.graphics.endFill();
		drawSlider();
	}

	private function drawSlider():void {
		var w:int, h:int, maxSize:int;
		isVertical = base.height > base.width;
		if (isVertical) {
			maxSize = base.height;
			w = base.width;
			h = Math.max(10, Math.min(sliderSizeFraction * maxSize, maxSize));
			slider.x = 0;
			slider.y = positionFraction * (this.height - h);
		} else {
			maxSize = base.width;
			w = Math.max(10, Math.min(sliderSizeFraction * maxSize, maxSize));
			h = base.height;
			slider.x = positionFraction * (this.width - w);
			slider.y = 0;
		}
		slider.graphics.clear();
		slider.graphics.beginFill(sliderColor);
		slider.graphics.drawRoundRect(0, 0, w, h, cornerRadius, cornerRadius);
		slider.graphics.endFill();
	}

	private function addFilters():void {
		var f:BevelFilter = new BevelFilter();
		f.distance = 1;
		f.blurX = f.blurY = 2;
		f.highlightAlpha = 0.5;
		f.shadowAlpha = 0.5;
		f.angle = 225;
		base.filters = [f];
		f = new BevelFilter();
		f.distance = 2;
		f.blurX = f.blurY = 4;
		f.highlightAlpha = 1.0;
		f.shadowAlpha = 0.5;
		slider.filters = [f];
	}

	public function allowDragging(flag:Boolean):void {
		if (flag) addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		else removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
	}

	private function mouseDown(evt:MouseEvent):void {
		Object(root).gh.setDragClient(this, evt);
	}

	public function dragBegin(evt:MouseEvent):void {
		var sliderOrigin:Point = slider.localToGlobal(new Point(0, 0));
		if (isVertical) {
			dragOffset = evt.stageY - sliderOrigin.y;
			dragOffset = Math.max(5, Math.min(dragOffset, slider.height - 5));
		} else {
			dragOffset = evt.stageX - sliderOrigin.x;
			dragOffset = Math.max(5, Math.min(dragOffset, slider.width - 5));
		}
		dragMove(evt);
	}

	public function dragMove(evt:MouseEvent):void {
		var range:int, frac:Number;
		var localP:Point = globalToLocal(new Point(evt.stageX, evt.stageY));
		if (isVertical) {
			range = base.height - slider.height;
			positionFraction = (localP.y - dragOffset) / range;
		} else {
			range = base.width - slider.width;
			positionFraction = (localP.x - dragOffset) / range;
		}
		positionFraction = Math.max(0, Math.min(positionFraction, 1));
		drawSlider();
		if (scrollFunction != null) scrollFunction(positionFraction);
	}

	public function dragEnd(evt:MouseEvent):void { }

}}