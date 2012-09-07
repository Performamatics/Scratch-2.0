package watchers {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.Point;
	import util.DragClient;

public class WatcherFrame extends Sprite implements DragClient {

	public var w:int;
	public var h:int;
	public var minWidth:int = 20;
	public var minHeight:int = 20;

	private var borderColor:int;
	private var borderWidth:int;
	private var fillColor:int;
	private var cornerRadius:int;

	private var box:Shape;
	private var outline:Shape;
	private var resizer:Shape;

	public function WatcherFrame(borderColor:int, fillColor:int, cornerRadius:int = 8, isInset:Boolean = false, borderWidth:int = 1) {
		this.borderColor = borderColor;
		this.borderWidth = borderWidth;
		this.fillColor = fillColor;
		this.cornerRadius = cornerRadius;

		box = new Shape();
		addChild(box);
		if (isInset) box.filters = [insetBevelFilter()];
		outline = new Shape();
		addChild(outline);
		setWidthHeight(80, 60);
	}

	public function setColor(c:int):void {
		fillColor = c;
		setWidthHeight(w, h);
	}

	public function showResizer():void {
		resizer = new Shape();
		var g:Graphics = resizer.graphics;
		g.lineStyle(1, 0x606060);
		g.moveTo(0, 10);
		g.lineTo(10, 0);
		g.moveTo(4, 10);
		g.lineTo(10, 4);
		addChild(resizer);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
	}

	public function hideResizer():void {
		if (resizer) {
			resizer.parent.removeChild(resizer);
			resizer = null;
		}
		removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;

		// box
		var g:Graphics = box.graphics;
		g.clear();
		g.beginFill(fillColor);
		g.drawRoundRect(0, 0, w, h, cornerRadius, cornerRadius);

		// outline
		g = outline.graphics;
		g.clear();
		g.lineStyle(borderWidth, borderColor);
		g.drawRoundRect(0, 0, w, h, cornerRadius, cornerRadius);

		if (resizer) {
			resizer.x = w - resizer.width;
			resizer.y = h - resizer.height;
		}
	}

	private function insetBevelFilter():BitmapFilter {
		var f:BevelFilter = new BevelFilter(2);
		f.angle = 225;
		f.blurX = f.blurY = 3;
		f.highlightAlpha = 0.5;
		f.shadowAlpha = 0.5;
		return f;
	}

	public function mouseDown(evt:MouseEvent):void {
		if ((root is Scratch) && !(root as Scratch).editMode) return;
		if (resizer && resizer.hitTestPoint(evt.stageX, evt.stageY)) {
			Scratch(root).gh.setDragClient(this, evt);
		}
	}

	public function dragBegin(evt:MouseEvent):void { }
	public function dragEnd(evt:MouseEvent):void { }

	public function dragMove(evt:MouseEvent):void {
		var topLeft:Point = this.localToGlobal(new Point(0, 0));
		var newW:int = Math.max(minWidth, evt.stageX + 3 - topLeft.x);
		var newH:int = Math.max(minHeight, evt.stageY + 3 - topLeft.y);
		setWidthHeight(newW, newH);
		if (parent && ('fixLayout' in parent)) (parent as Object).fixLayout();
	}

}}
