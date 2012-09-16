package uiwidgets {
	import flash.display.Sprite;
	import assets.Resources;

public class ZoomWidget extends Sprite {

	private const scaleFactors:Array = [25, 50, 75, 100, 125, 150, 200];

	private var app:Scratch;
	private var zoom:int;
	private var smaller:IconButton;
	private var normal:IconButton;
	private var bigger:IconButton;

	public function ZoomWidget(app:Scratch) {
		this.app = app;
		smaller = new IconButton(minusClicked, Resources.createBmp('zoomminus'));
		normal = new IconButton(normalClicked, Resources.createBmp('zoomnormal'));
		bigger = new IconButton(plusClicked, Resources.createBmp('zoomplus'));
		smaller.x = 0;
		normal.x = 25;
		bigger.x = 50;
		addChild(smaller);
		addChild(normal);
		addChild(bigger);
	}

	private function minusClicked(b:IconButton):void { changeZoomBy(-1) }
	private function normalClicked(b:IconButton):void { zoom = 0; changeZoomBy(0) }
	private function plusClicked(b:IconButton):void { changeZoomBy(1) }

	private function changeZoomBy(delta:int):void {
		zoom += delta;
		zoom = Math.max(-3, Math.min(zoom, 3));
		smaller.visible = zoom >= -2;
		bigger.visible = zoom <= 2;
		app.scriptsPaneFrame.setContentsScale(scaleFactors[3 + zoom]);
	}

}}