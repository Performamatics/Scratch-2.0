package ui {
	import flash.filters.DropShadowFilter;
	import flash.display.*;		
	import flash.text.*;
	import assets.Resources;

public class LoadProgress extends Sprite {

	private const grooveColor:int = 0xB9BBBD;

	private var bkg:Shape;
	private var statusField:TextField;
	private var errorField:TextField;
	private var groove:Shape;
	private var progressBar:Shape;

	public function LoadProgress():void {
		bkg = new Shape();
		addChild(bkg);
		drawBackground(bkg.graphics, 312, 109);
		bkg.filters = addFilters();
		statusField = Resources.makeLabel('', CSS.titleFormat, 20, bkg.height - 60);
		addChild(statusField);
		statusField.width = 296;

		errorField = Resources.makeLabel('', CSS.progressInfoFormat, 20, bkg.height - 40);
		errorField.width = 296;
		errorField.height = 26;
		errorField.wordWrap = true;
		addChild(errorField);

		groove = new Shape();
		addChild(groove);
		drawLine(groove.graphics, grooveColor, 257, 22)
		groove.y = 20;
		groove.x = 30;	

		progressBar = new Shape();;
		progressBar.x = groove.x;
		progressBar.y = groove.y;
		addChild(progressBar);
	}

	private function drawBackground(g:Graphics, w:int, h:int):void {
		g.clear();
		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(0xFFFFFF);
		g.drawRoundRect(0, 0, w, h, 24, 24);
		g.endFill();		
	}

	private function drawLine(g:Graphics, c:uint, w:int, h:int):void {
		g.clear();
		g.beginFill(c);
		g.drawRoundRect(0, 0, w, h, h/2, h/2);
		g.endFill();		
	}

	private function addFilters():Array {
		var f:DropShadowFilter = new DropShadowFilter();
		f.blurX = f.blurY = 8;
		f.distance = 5;
		f.alpha = 0.75;
		f.color = 0x333333;	
		return  [f];
	}

	public function updateProgress(p:Number):void {	
		if (p < 0.1) return;
		drawLine (progressBar.graphics, CSS.overColor, Math.floor(groove.width * p), groove.height);
	}

	public function updateStatus(s:String):void {
		statusField.text = s;
		statusField.x = (bkg.width - statusField.textWidth) / 2;
	}

	public function errorStatus(s:String):void {
		errorField.text = s; 		
	}

}}
