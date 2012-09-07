package {

	import flash.display.Graphics;
	import flash.display.StageAlign;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;	
	import flash.geom.Point;
	import flash.utils.setTimeout;
	import ui.paintui.*;
	import flash.events.KeyboardEvent;

//[SWF("width"="360", "height"="550", "backgroundColor"="0xF2F2F2")]
[SWF("backgroundColor"="0xF2F2F2")]

public class PaintEditor extends Sprite {

	private const inset:int = 5;

	private var pc:PaintEdit;
	public var isStage:Boolean = false;
	private var scalesize:Number = 1.0;

	public function PaintEditor() {
		var w:int = stage.stageWidth;
		var h:int = stage.stageHeight;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		stage.frameRate = 60;			
		pc = new PaintEdit(this);
		pc.setWidthHeight(w - (2 * inset), h - (2 * inset));
		pc.x = pc.y = inset;
		addChild(pc);
		stage.addEventListener(Event.RESIZE, fixLayout);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, handleSVGkeyDown);
		PaintVars.appStage = stage;
	}
	
///////////////////////////////////////////
// Keyboard events
//////////////////////////////////////////

private function handleSVGkeyDown(e:KeyboardEvent):void{
	e.preventDefault();
	if (PaintVars.keyFocus) return;
	if (e.ctrlKey &&  (e.keyCode==83)) SVGExport.svgString(PaintVars.svgroot, pc.paintarea.width, pc.paintarea.height);
	if (e.ctrlKey &&  !e.shiftKey && (e.keyCode==76)) { // ctrl+L to  enlarge and render as bmp
		scalesize = scalesize *2;
		createBitmap(scalesize); // test svg
	}
	if (e.ctrlKey&& e.shiftKey &&  (e.keyCode==76)) { // ctrl+shift+L to shrink and render as bmp
		scalesize = scalesize *0.5;
		createBitmap(scalesize); // test svg
	}	
	if (e.ctrlKey && (e.keyCode==84)) toggleStage();	
	if (e.ctrlKey && e.shiftKey && (e.keyCode==90)) PaintVars.redo();
	if (e.ctrlKey &&  !e.shiftKey && (e.keyCode==90)) PaintVars.undo();
	if (! PaintVars.selectedElement || PaintVars.pathSelector) return; // && !antsAlive()) return;
	var action:String = getKeyAction (e.keyCode );
	switch (action){
		case "keyboard":
			moveSelectedElement(e.keyCode);
			break;
		case "delete":
			deleteObj();
			break;
		case "deactivate":
			pc.selectButton("select");
			PaintVars.svgroot.selectorGroup.quitTextEditMode(PaintVars.svgroot.selectorGroup.hideSelectorGroup);
			break;
		default:
			break;
	 }
}

/////////////////////////////////////////////////
// toggle to stage
////////////////////////////////////////////////

public function toggleStage():void {
	isStage = !isStage;
	var w:int, h:int;
	PaintVars.svgroot.clearSVGroot();
	if (isStage) {
		w = Math.max(stage.stageWidth, 500);
		h = Math.max(stage.stageHeight, 620);
		pc.setCanvasSize(480, 360);
	} else {
		w = 360;
		h = 550;
		pc.setCanvasSize(200, 200);
	 }
	stage.stageWidth = w;
	stage.stageHeight = h;
}

/////////////////////////////////////////////////
// testing bitmap saving
////////////////////////////////////////////////

	public function createBitmap(scale:Number):void {
		function removeBmp():void { tst.parent.removeChild(tst);}

		var svg:SVGData = new SVGData('g', '');
		svg.setAttribute('children', PaintVars.svgroot.getSVGlist());
		var tst:Bitmap = new Bitmap(svg.scaledBitmap(scale));
		addChild(tst);
		setTimeout(removeBmp, 1000);
	}

	public function createBitmapOLD(scale:Number):void {
		function removeBmp():void { tst.parent.removeChild(tst);}

		var cnv:Object = pc.getCanvasWidthAndHeight();
		var w:Number = cnv.width * scale;
		var h:Number = cnv.height * scale;
		// do not bother render something too small
		if (w < 10) return;
		if (h < 10) return;
		var temp:BitmapData = new BitmapData(Math.floor(w), Math.floor(h), true, 0);
		var svgs:Array = PaintVars.svgroot.getSVGlist();
		var costumes:Array = getScaledClones(svgs, scale);
		drawScaled(costumes, temp);
		var tst:Bitmap = new Bitmap(temp);
		addChild (tst);
		setTimeout(removeBmp, 1000);
	}

	private function getScaledClones(svgs:Array, scale:Number):Array {
		var clones:Array = [];
		for (var k:int = 0; k < svgs.length; k++) {
			var clone:SVGData = (svgs[k] as SVGData).cloneSVG();
			if (clone.tagName == "g") clone.setAttribute("children", getScaledClones(clone.getAttribute("children"), scale));
			else clone.scaleCostume(scale);
			clones.push(clone);
		}
		return clones;
	}

	private function drawScaled(costumes:Array, bitmap:BitmapData):void{
		for each (var svg:SVGData in costumes) {
			if (svg.tagName == "g") drawScaled(svg.getAttribute("children"), bitmap);
			else svg.stamp(bitmap);
		}
	}

/////////////////////////////////////////////////
// Keyboard events that should be kept
////////////////////////////////////////////////


private function getKeyAction(key:uint):String{
	var validkeys:Array =[38, 39, 40, 37];
	if ((validkeys.indexOf(key) > -1) && PaintVars.selectedElement) return "keyboard";
	if (key == 8) return "delete";
	if (key == 13) return "deactivate";
	return null;
	}
	
private function moveSelectedElement(key:uint):void{
	var elem:PaintObject = PaintVars.selectedElement;
	switch(key){
		case 37:
			elem.translateTo(new Point(-1, 0));
			break;
		case 38:
			elem.translateTo(new Point(0, -1));
			break;
		case 39:
			elem.translateTo(new Point(1, 0));
			break;
		case 40:
			elem.translateTo(new Point(0, 1));
			break;
	}
	PaintVars.svgroot.selectorGroup.selectorReset(elem);
	PaintVars.recordForUndo();
}

	private function deleteObj():void { 
		if (PaintVars. antsAlive()) PaintVars.svgroot.deleteImageSelection();
		else {
			var ps:* = PaintVars.selectedElement;
	//		if (ps.getAttribute("bitmapdata") is BitmapData) (ps.getAttribute("bitmapdata") as BitmapData).dispose();
			PaintVars.svgroot.selectorGroup.hideSelectorGroup();
			ps.parent.removeChild(ps);
		}
		PaintVars.recordForUndo();
	}

	public function fixLayout(e:Event):void {
		var w:int = stage.stageWidth;
		var h:int = stage.stageHeight - 1; // fix to show bottom border...
		pc.setWidthHeight(w - (2 * inset), h - (2 * inset));
	}

}}