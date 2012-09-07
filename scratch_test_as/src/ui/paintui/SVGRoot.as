/*
     ___             ___            ___           ___           ___           ___            ___
    /  /\           /  /\          /  /\         /  /\         /  /\         /  /\          /__/\
   /  /:/~/\       /  /:/         /  /::\       /  /::\       /  /:/        /  /:/          \  \:\
  /  /:/ /::\     /  /:/  ___    /  /:/\:\     /  /:/\:\     /  /::        /  /:/  ___       \__\:\
 /  /:/ /:/\:\   /  /:/  /  /\  /  /:/~/:/    /  /:/~/::\   /  /:::\      /  /:/  /  /\  ___ /  /::\
/__/:/ /:/\ \:\ /__/:/  /  /:/ /__/:/ /:/___ /__/:/ /:/\:\ /__/:/ \:\    /__/:/  /  /:/ /__/\  /:/\:\
\  \:\/:/ / /:/ \  \:\ /  /:/  \  \:\/:::::/ \  \:\/:/__\/ \__\/\  \:\   \  \:\ /  /:/  \  \:\/:/__\/
 \  \::/ / /:/   \  \:\  /:/    \  \::/~~~~   \  \::             \  \:\   \  \:\  /:/    \  \::/
  \__\/ / /:/     \  \:\/:/      \  \:\        \  \:\             \  \:\   \  \::/:/      \  \:\
       / /:/       \  \::/        \  \:\        \  \:\             \  \:\   \  \/:/        \  \:\
      \__\/         \__\/          \__\/         \__\/              \__\/    \__\/          \__\/

*/
package ui.paintui {

	import flash.events.MouseEvent;	
	import util.Color;
	import flash.display.DisplayObject;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	import flash.events.*;
	
public class SVGRoot extends Sprite{
	
	public var window:PaintEdit;
	public var selectorGroup:SVGSelector;	
	public var mouseTarget:PaintObject;
	public var dragObjAngle:Number;
	public var dragObjMatrix:Matrix;
	public var paintPixels:PaintPixels;
 	public var currentshape:PaintObject;	
//////////////////////////////////////////
//SVG Group
/////////////////////////////////////////

	public function SVGRoot(p:PaintEdit) {
		p.addChild(this);
		mask = new Shape();
		addChild(mask);
		window = p;		
		paintPixels = new PaintPixels();
	}
	
	public function setWidthHeight(w:int, h:int):void {
		drawShape(Shape(mask).graphics, w, h);
		paintPixels.setWidthHeight(w,h);
	}

	private function drawShape(g:Graphics, w:int, h:int):void {
		g.clear();
		g.beginFill(0xFF00, 1);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	public function repositionElements(p:Point):void {
		clearAllSelections();
		for(var i:int=0;i< this.numChildren;i++){
			var elem:PaintObject=this.getChildAt(i) as PaintObject;
			if (!elem) continue;
			if (elem.id == "staticbkg") resizeTheBackground(elem);
			else elem.translateTo(p);
		}
	}

	private function resizeTheBackground(elem:PaintObject):void {
		var objw:Number = Number (elem.getAttribute("width"));
		var objh:Number = Number (elem.getAttribute("height"));
		var scalew:Number = mask.width/objw;
		var scaleh:Number = mask.height/objh;
		elem.setAttribute("scalex", scalew);
		elem.setAttribute("scaley", scaleh);
		elem.render();
	}

	public function runInstantTool(evt:MouseEvent, toolname:String):void {
		cmdForMouseDown[toolname](evt);
		setTimeout(function():void { window.selectButton("select") }, 50);
	}

/////////////////////////////////////////////////////////
// dispatch tables
////////////////////////////////////////////////////////

private var cmdForMouseDown:Object = {'select': selectMouseDown, "group": groupMouseDown, 
	"rotate": rotateMouseDown, "resize": resizeMouseDown, 
	'path': pathMouseDown, "rect": rectMouseDown, 'ellipse': ellipseMouseDown,
	'grab': grabMouseDown, "add": addGrabMouseDown, "clone": cloneMouseDown,
	'text': textMouseDown, 'image': ignoreEvt,
	"eyedropper": eyeMouseDown, "front": frontMouseDown, "back": backMouseDown, 
	'eraser': eraserMouseDown, "lasso": lassoMouseDown, 'paintbucket': paintBucketMouseDown, 
	'wand': wandMouseDown, "slice": sliceMouseDown
				};
				
private var cmdForMouseMove:Object = { 'select': selectMouseMove, "group": groupMouseMove,
	"rotate": rotateMouseMove, "resize": resizeMouseMove, 
	'path': pathMouseMove, "rect": rectMouseMove, 'ellipse': ellipseMouseMove,
	'grab': grabMouseMove, "add": ignoreEvt, "clone": ignoreEvt,
	'text': ignoreEvt,'image': ignoreEvt,
	"eyedropper": ignoreEvt, "front": ignoreEvt, "back": ignoreEvt, 
	'eraser': eraserMouseMove, "lasso": lassoMouseMove, 'paintbucket': ignoreEvt, 
	'wand': ignoreEvt, "slice": pathMouseMove
				};

private var cmdForMouseUp:Object = {'select': selectMouseUp, "group": groupMouseUp, 
	"rotate": rotateMouseUp, "resize": resizeMouseUp, 
	'path': pathMouseUp, "rect": rectMouseUp, 'ellipse': ellipseMouseUp,
	'grab': grabMouseUp, "add": ignoreEvt, "clone": ignoreEvt,
	'text': ignoreEvt,  'image': ignoreEvt,
	"eyedropper": ignoreEvt, "front": ignoreEvt, "back": ignoreEvt, 
	'eraser': eraserMouseUp, "lasso": lassoMouseUp, 'paintbucket': ignoreEvt, 
	'wand': ignoreEvt, "slice": sliceMouseUp
				};

private function ignoreEvt(evt:MouseEvent):void{}

/////////////////////////////////////
//  Events
//////////////////////////////////////////////////

 public function paintMouseDown(evt:MouseEvent):void {
	PaintVars.dragging = false;
	PaintVars.resizeMode= "none";
	evt.preventDefault();
	PaintVars.initialPoint = getScreenPt(evt);
	currentshape = null; 
	var mt:PaintObject = getMouseTarget(evt);
	if (PaintVars.antsAlive() && (mt != mouseTarget) && notAbitmapAction()) clearAllSelections();
	mouseTarget = mt;
	if (mouseTarget != null)  {	
		if (mouseTarget.parent is SVGSelector) PaintVars.paintMode = mouseTarget.id.substr(0,6);
		if  ((mouseTarget.id).indexOf("grab_") > -1) PaintVars.paintMode = "grab";
		if (mouseTarget == PaintVars.pathSelector) PaintVars.paintMode = "add";
	}
	else if (PaintVars.paintMode == "select") {
		clearAllSelections();
		PaintVars.paintMode = "group";
	}
	PaintVars.deltaPoint = PaintVars.initialPoint;
	PaintVars.dragging = true;
	removeEvents();	
	if ((PaintVars.keyFocus) && (mouseTarget == PaintVars.keyFocus.parent as PaintObject)) return;
	var fcn:Function = (cmdForMouseDown[PaintVars.paintMode] as Function);
	if (fcn == null) return;
	fcn.apply(null, [evt]);
	window.addEventListener(MouseEvent.MOUSE_MOVE, paintMouseMove);
	window.addEventListener(MouseEvent.MOUSE_UP, paintMouseUp);
	}

private function removeEvents():void{
	if (window.hasEventListener(MouseEvent.MOUSE_UP)) window.removeEventListener(MouseEvent.MOUSE_UP, paintMouseUp);
	if (window.hasEventListener(MouseEvent.MOUSE_MOVE)) window.removeEventListener(MouseEvent.MOUSE_MOVE, paintMouseMove);
}

public function clearAllSelections():void {
	if (PaintVars.antsAlive())  PaintVars.clearMarchingAnts();
	if (PaintVars.inTextEditting())	selectorGroup.quitTextEditMode(selectorGroup.hideSelectorGroup);		
	if (PaintVars.pathSelector) selectorGroup.quitPathEditMode();
	selectorGroup.hideSelectorGroup();
	window.selectButton("select");
}

private function paintMouseMove(evt:MouseEvent):void {
	if (!PaintVars.dragging) return;
	evt.preventDefault();
	(cmdForMouseMove[PaintVars.paintMode] as Function).apply(null, [evt]);
}

private function paintMouseUp(evt:MouseEvent):void {	
	evt.preventDefault();
	removeEvents();
	var pt:Point = getScreenPt(evt);
	var bmptools:Array  = ['paintbucket','eraser', 'lasso', 'wand'];
	var list:Array = ['path', "rect", 'ellipse'];
	if ((list.indexOf(PaintVars.paintMode) > -1)&&((pt.x == PaintVars.initialPoint.x) && (pt.y == PaintVars.initialPoint.y))) {
			currentshape.parent.removeChild(currentshape);
			currentshape = null;
			clearAllSelections();
	} else {
		(cmdForMouseUp[PaintVars.paintMode] as Function).apply(null, [evt]);
	}
	var b:Boolean = (PaintVars.paintMode != "select");
	currentshape = null;
	PaintVars.dragging = false;
	PaintVars.resizeMode= "none";
	if (notAbitmapAction()) window.selectButton("select");
	pt = getScreenPt(evt);
	if (xPoint.vlen(xPoint.vdiff(pt,PaintVars.initialPoint)) == 0) return;
	if (b) PaintVars.recordForUndo();
	}
	
private function notAbitmapAction():Boolean{
		var bmptools:Array  = ['paintbucket','eraser', 'lasso', 'wand'];
		return bmptools.indexOf(PaintVars.paintMode) < 0;
	}
	
////////////////////////////////////
// Calls from the Mouse Down
////////////////////////////////////

private function selectMouseDown(evt:MouseEvent):void{
	if (PaintVars.pathSelector) selectorGroup.quitPathEditMode();
	currentshape = mouseTarget;
	if (mouseTarget == null) {
	 	clearAllSelections();
		return;
	}		
	if ((evt.shiftKey) && (currentshape.id != "staticbkg")) bringToFront(currentshape);
	PaintVars.pevSelection = PaintVars.selectedElement;
	dragObjMatrix = currentshape.getScaleMatrix();
	selectorGroup.selectorReset(currentshape);
	currentshape.clearMove();
	if (!PaintVars.imageIsSelected()&&(currentshape.tagName != "g")) eyeDropElement(evt);
	if (PaintVars.imageIsSelected()) window.activateBitmap();
	else window.activateSVG();
	window.selectButton("select");
}

private function addGrabMouseDown(evt:MouseEvent):void{
	PaintVars.pathSelector.addApoint(PaintVars.initialPoint);
}

private function eyeMouseDown(evt:MouseEvent):void  {
	if (mouseTarget && (mouseTarget.tagName == "image")) eyeDropOnImage(mouseTarget,getScreenPt(evt));
	else PaintVars.eyeDrop(mouseTarget, evt);
	window.colorPalette.updateSettings();
	window.colorPalette.updateElement(true);
}

private function eyeDropOnImage(mt:PaintObject, mousePt:Point):void {
	var color:* = paintPixels.getPixelColor(mouseTarget, mousePt);
	if (color == "none") return;
	PaintVars.fillAttributes["basecolor"]  = color;
	PaintVars.fillAttributes.fillstyle  = "onecolor";
	var hsv:Array= Color.rgb2hsv(color);
	PaintVars.setFillColor(hsv);
}
	
private function eyeDropElement(evt:MouseEvent):void {
	if (PaintVars.textIsSelected()) window.colorPalette.switchToText(currentshape);
	else {
		PaintVars.eyeDrop(currentshape, null);
		window.colorPalette.changeToFill(evt);
		}
	PaintVars.eyeDrop(mouseTarget, evt);
	window.colorPalette.updateSettings();
}

private function pathMouseDown(evt:MouseEvent):void {
	currentshape = addPolyline (this, PaintVars.initialPoint);	
	addChild(currentshape);
}

private function addPolyline(ignored:Sprite, p:Point):PaintObject {
	var	odata:PaintObject = new PaintObject("polyline", getIdFor("polyline"));
	var points:Array = [p];
	var attr:Object = {"points": points,  "opacity": 1};
	var stroke:* = window.colorPalette.getStrokeColor();
	if (stroke == "none")  {
		PaintVars.strokeAttributes.basecolor = 0;
		PaintVars.setStrokeColor([0,0,0]);
		window.colorPalette.updateSettings();
		}
	for (var val:String in attr) odata.setAttribute(val, attr[val]);
	var drawattr:Object = PaintVars.getPenAttr(window.colorPalette.getFillColor());
	drawattr["fill"] = "none";
	for (var ps:String in drawattr) odata.setAttribute(ps, drawattr[ps]);
	return odata;
}

private function sliceMouseDown(evt:MouseEvent):void {
	currentshape = addPolyline (this, PaintVars.initialPoint);
	currentshape.setAttribute("stroke",  0x00FF00); 
	addChild(currentshape);
}	
	
private function cloneMouseDown(evt:MouseEvent):void {
	if (! PaintVars.selectedElement) return;
	if (PaintVars.backgroundIsSelected() && ! PaintVars.antsAlive()) return;
	currentshape = (PaintVars.antsAlive() && mouseTarget && (mouseTarget.tagName == "image"))  ? copyImageBits(mouseTarget) : cloneSVGelement(PaintVars.selectedElement);
	currentshape.render();
	window.selectButton("select");
	window.settingsForTool("select");
	selectNewObject(evt);
	PaintVars.recordForUndo();   
	}

private function copyImageBits(mt:PaintObject):PaintObject{
	PaintVars.clearMarchingAnts();
	selectorGroup.hideSelection();
	// setup the variables
	var bm:BitmapData = paintPixels.copyBits(mt);
	var svg:Object = {}
	var pt:Point = paintPixels.getDeltaPoint();
	svg["x"] = pt.x;
	svg["y"] = pt.y;
	svg["width"] = bm.width;
	svg["height"] = bm.height;
	svg["bitmapdata"] = bm;
	svg["scalex"] = mt.getAttribute("scalex");
	svg["scaley"] = mt.getAttribute("scaley");
	svg["angle"] = mt.getAttribute("angle");
	
	var	po:PaintObject =new PaintObject("image", getIdFor("image"));
	for (var key:String in svg) po.setAttribute (key, svg[key]);
	po.insertImage();		
	po.translateTo(new Point(5, 5));

	addChild(po);
	po.render();
	mouseTarget = po;
	return po;
	}
	
private function cloneSVGelement(elem:PaintObject):PaintObject{
	if (elem.tagName == "g") return cloneSVGGroup(this, elem);
	else return cloneKid(elem.parent as Sprite, elem);
}

private function cloneKid(p:Sprite, elem:PaintObject):PaintObject {
	var shape:PaintObject = getClonedKid(p, elem);
	shape.translateTo(new Point(5, 5));
	return shape;
}

private function getClonedKid(p:Sprite, elem:PaintObject):PaintObject {
	var svg:SVGData = elem.odata.cloneSVG();
	if (svg.tagName == "image") svg.setAttribute("bitmapdata", elem.getAttribute("bitmapdata").clone());	
	var id:String = getIdFor(svg.tagName);
	svg.id = id;
	var po:PaintObject= new PaintObject(svg.tagName, id, svg);
	p.addChild(po);
	return po;
}

private function cloneSVGGroup(p:Sprite,elem:PaintObject):PaintObject{
	var newGroup:PaintGroup = new PaintGroup(elem.tagName, getIdFor(elem.tagName));
	var group:Array = [];
	for(var i:int=0;i< elem.numChildren;i++){
		var po:PaintObject= elem.getChildAt(i) as PaintObject;
		if (!po) continue;
		group.push(cloneKid(newGroup,po).odata);
		}
	newGroup.setAttribute("children", group);
	p.addChild(newGroup);
	return newGroup;
	}

private function frontMouseDown(evt:MouseEvent):void {
	if (PaintVars.selectedElement) bringToFront(PaintVars.selectedElement)
}

private function backMouseDown(evt:MouseEvent):void {
	if (PaintVars.selectedElement) setToBack(PaintVars.selectedElement)
}

private function bringToFront(e:PaintObject):void { this.setChildIndex(e, this.numChildren - 1);}

private function setToBack(e:PaintObject):void {
	if (this.numChildren < 3) return;
	var c:PaintObject = this.getChildAt(1) as PaintObject;
	if (c.id == "staticbkg") {
			if (this.numChildren < 3) return;
			else this.setChildIndex(e, 2);
	} else this.setChildIndex(e, 1);
}

private function textMouseDown(evt:MouseEvent):void {
	currentshape = addText (this, PaintVars.initialPoint.x, PaintVars.initialPoint.y);	
	addChild(currentshape);
	selectorGroup.enterTextEditMode(currentshape);
	eyeDropElement(evt);
	currentshape.render();
}
	
private function addText(p:Sprite, dx:Number, dy:Number):PaintObject {
	var	po:PaintObject =new PaintObject("text", getIdFor("text"));
	var attr:Object =  {"x": dx, "y": dy, "fill": window.colorPalette.getTextColor(),
			"font-size": PaintVars.textAttributes.fontsize, "font-family": PaintVars.textAttributes.family,
			"text-anchor": "start", "xml:space": "preserve", "textContent": " ",
			"font-weight": PaintVars.textAttributes.weight, 'font-style': PaintVars.textAttributes.fontstyle };
	for (var val:String in attr) po.setAttribute(val, attr[val]);
	po.setAttribute("textfield", po.createSVGText());
	po.render();
	return po;
}

private function rectMouseDown(evt:MouseEvent):void {
	currentshape = addRect (this, PaintVars.initialPoint.x, PaintVars.initialPoint.y);	
	addChild(currentshape);
	}

private function addRect(p:Sprite, dx:Number, dy:Number):PaintObject {
	var	odata:PaintObject =new PaintObject("rect", getIdFor("rect"));
	var attr:Object =  {"x": dx, "y": dy, "width": 0, "height": 0, "opacity": 1};
	for (var val:String in attr) odata.setAttribute(val, attr[val]);
	var drawattr:Object = PaintVars.getPenAttr(window.colorPalette.getFillColor());
	for (var ps:String in drawattr) odata.setAttribute(ps, drawattr[ps]);
	return odata;
}

private function ellipseMouseDown(evt:MouseEvent):void {
	currentshape = addEllipse (this, PaintVars.initialPoint.x, PaintVars.initialPoint.y);	
	addChild(currentshape);
	}

private function addEllipse(p:Sprite, dx:Number, dy:Number):PaintObject {
	var	odata:PaintObject =new PaintObject("ellipse", getIdFor("ellipse"));
	var attr:Object = {"cx": dx, "cy": dy, "rx": 0, "ry": 0, "opacity": 1};
	for (var val:String in attr) odata.setAttribute(val, attr[val]);
	var drawattr:Object = PaintVars.getPenAttr(window.colorPalette.getFillColor());
	for (var ps:String in drawattr) odata.setAttribute(ps, drawattr[ps]);
	return odata;
}

private function rotateMouseDown(evt:MouseEvent):void {
	if (! PaintVars.selectedElement) return;
	currentshape = PaintVars.selectedElement;
	currentshape = noText(currentshape);
	dragObjMatrix = currentshape.getScaleMatrix();
	selectorGroup.selectorReset(currentshape);
}

private function resizeMouseDown(evt:MouseEvent):void {
	if (! PaintVars.selectedElement) return;
	currentshape = PaintVars.selectedElement;
	// patch for the text only scaling in one dimension
	// therefore I make sure that groups don't have text  
	currentshape = noText(currentshape);
	PaintVars.resizeMode = "none";
	if ( ! currentshape)  return;
	var oid:String =  mouseTarget.id;
	dragObjMatrix = currentshape.getScaleMatrix();
	PaintVars.resizeMode =  (oid.length < 8) ? "none" :  getResizeMode(oid.substr(7,oid.length), dragObjMatrix);
	selectorGroup.selectorReset(currentshape);	
}

private function getResizeMode(str:String, m:Matrix):String{
	if (m.a < 0) {
		if (str.indexOf("e") > -1) str =	str.replace("e", "w");
		else if (str.indexOf("w") > -1)  str =	str.replace("w", "e");
		}
	if (m.d < 0) {
		if (str.indexOf("s") > -1) str =	str.replace("s", "n");
		else if (str.indexOf("n") > -1) str = str.replace("n", "s");
		}
	return str;
}

private function grabMouseDown(evt:MouseEvent):void{
	currentshape  = mouseTarget;
	currentshape.setAttribute("fill", 0x00ff00);
	currentshape.setAttribute("opacity", 1);
	currentshape.render();
	var elem:PaintObject = gn(currentshape.getAttribute("parentid"));
}

private function groupMouseDown(evt:MouseEvent):void {
	selectorGroup.selectionStart(PaintVars.initialPoint);
	}

private function paintBucketMouseDown(evt:MouseEvent):void {
	if (mouseTarget == null) paintBucketOnBackground(evt);
	else {
		switch (mouseTarget.tagName) {
			case "image":  paintBucketOnBmp(evt); break;
			case "g":  paintBucketInGroup(evt); break;
			default:  
				if (PaintVars.antsAlive()) PaintVars.clearMarchingAnts(); 
				paintBucketOnSVG(mouseTarget);
		 }
	}
	setTimeout(function():void { window.selectButton("select"); window.settingsForTool("select") }, 50);
}

private function paintBucketInGroup(evt:MouseEvent):void{
	var po:PaintObject = findHitinCanvas(evt, mouseTarget);
	if (!po) return;
	paintBucketOnSVG(po);
}

private function paintBucketOnSVG(obj:PaintObject):void {	
	if (obj.tagName == "text"){
		obj.setAttribute("fill", window.colorPalette.getTextColor());
		obj.setAttribute("font-family", window.colorPalette.getFontFamily());
		obj.setAttribute("font-size", window.colorPalette.getFontSize());
		obj.setAttribute("font-weight", window.colorPalette.getFontWeight());
		obj.setAttribute('font-style', window.colorPalette.getFontStyle());
		obj.chooseContrast(); 
		}
	else {
		obj.setAttribute("fill",  window.colorPalette.getFillColor());
		obj.setAttribute("stroke", window.colorPalette.getStrokeColor());
		obj.setAttribute("stroke-width", PaintVars.strokeAttributes.strokewidth);
	  obj.setAttribute("strokehue", PaintVars.strokeAttributes.hue);
		obj.setAttribute("fillhue", PaintVars.fillAttributes.hue);
	 	obj.setAttribute("fillghue", PaintVars.fillAttributes.gradhue);
	 }
	obj.render();
	PaintVars.recordForUndo();
}

private function paintBucketOnBackground(evt:MouseEvent):void  {
	if (gn("staticbkg")) {
		var pt:Point = getScreenPt(evt);
		paintPixels.paintBucketOnImage(gn("staticbkg"), pt, window.colorPalette.getFillColor());
	}
	else { // create the static bkg
		var cnv:Object = window.getCanvasWidthAndHeight();
		var bm:BitmapData =  paintPixels.fillCanvasWithSelectedColor(cnv.width, cnv.height, window.colorPalette.getFillColor(), null);
		var svg:Object =  {"x": 0, "y": 0, "width": bm.width, "height": bm.height,
			"bitmapdata": bm};
		var	po:PaintObject =new PaintObject("image", "staticbkg");
		for (var key:String in svg) po.setAttribute (key, svg[key]);
		po.insertImage();		
		addChild(po);
		setToBack(po);
		}
	PaintVars.recordForUndo();
	PaintVars.getKeyBoardEvents();
}
	
private function paintBucketOnBmp(evt:MouseEvent):void {
	var pt:Point = getScreenPt(evt);
	paintPixels.paintBucketOnImage(mouseTarget, pt, window.colorPalette.getFillColor());
	PaintVars.getKeyBoardEvents();
}

private function wandMouseDown(evt:MouseEvent):void {
	if (!mouseTarget) return;
	var pt:Point = getScreenPt(evt);
	if (PaintVars.antsAlive())  PaintVars.clearMarchingAnts(); 
	paintPixels.selectWithWand(mouseTarget, pt);
	PaintVars.getKeyBoardEvents();	
}

public function recalculateSelection():void {
	if (!mouseTarget) return;
	if ((mouseTarget is PaintObject) && (mouseTarget.tagName == "image")){
		PaintVars.clearMarchingAnts();
		paintPixels.selectWithWand(mouseTarget, PaintVars.initialPoint);
	}
	PaintVars.getKeyBoardEvents();	
}

private function eraserMouseDown(evt:MouseEvent):void {
	if (PaintVars.antsAlive())  PaintVars.clearMarchingAnts(); 
	if (! mouseTarget) return;
	if (mouseTarget.tagName != "image") return;
	paintPixels.eraserMouseDown(mouseTarget, PaintVars.initialPoint);
	PaintVars.dragging = true;
}

private function lassoMouseDown(evt:MouseEvent):void {
	if (PaintVars.antsAlive())  PaintVars.clearMarchingAnts(); 
	PaintVars.dragging = false;
	if (! mouseTarget) return;
	if (mouseTarget.tagName != "image") return;
	paintPixels.lassoMouseDown(mouseTarget, PaintVars.initialPoint);
	PaintVars.dragging = true;
}

////////////////////////////////////
// Calls from the Mouse Move
////////////////////////////////////

private function selectMouseMove(evt:MouseEvent):void {
 	if (mouseTarget == null) return;
	var pt:Point = getScreenPt(evt);
	var delta:Point = xPoint.vdiff(pt,PaintVars.deltaPoint);
	if (PaintVars.backgroundIsSelected())  {
		if (xPoint.vlen(delta) < 8) return;
		selectorGroup.hideSelectorGroup();
		groupMouseDown(evt);
		groupMouseMove(evt);
		PaintVars.paintMode = "group";
	}
	else {
		PaintVars.deltaPoint = pt;
		currentshape.moveBy(delta);
		selectorGroup.moveBy(delta);
		selectorGroup.updateFrame(currentshape);
	 }
 }

private function rectMouseMove(evt:MouseEvent):void{
	var pt:Point = getScreenPt(evt);
	var delta:Point = xPoint.vdiff(pt, PaintVars.initialPoint);
	var w:Number =Math.abs(delta.x); var h:Number =Math.abs(delta.y);
	var new_x:Number; var new_y:Number;
	if (evt.shiftKey) {
		w = h = Math.max(w, h);
		new_x = PaintVars.initialPoint.x < pt.x ? PaintVars.initialPoint.x : PaintVars.initialPoint.x - w;
		new_y = PaintVars.initialPoint.y < pt.y ? PaintVars.initialPoint.y : PaintVars.initialPoint.y - h;
		}
	else {
		new_x = Math.min(PaintVars.initialPoint.x, pt.x);
		new_y = Math.min(PaintVars.initialPoint.y, pt.y);
	}
	var attr:Object = {'width': w, 'height': h, 'x': new_x, 'y': new_y};
	for (var k:String in attr) currentshape.setAttribute(k, attr[k]);
	currentshape.render();
}

private function pathMouseMove(evt:MouseEvent):void{
	var pt:Point = getScreenPt(evt);
	var pl:Array = currentshape.getAttribute("points");
	pl.push(pt);
	currentshape.setAttribute("points", pl);
	currentshape.render();
}

private function ellipseMouseMove(evt:MouseEvent):void{
	var pt:Point = getScreenPt(evt);
	var cx:Number = Number(currentshape.getAttribute('cx'));
	var cy:Number = Number(currentshape.getAttribute('cy'));
	currentshape.setAttribute("rx", Math.abs(pt.x - cx));
	var ry:Number = Math.abs(evt.shiftKey?(pt.x - cx):(pt.y - cy));
	currentshape.setAttribute("ry", ry);
	currentshape.render();
}

private function rotateMouseMove(evt:MouseEvent):void{
	rotateFromMouse(evt, currentshape);	
	selectorGroup.updateFrame(currentshape);
	}

private function rotateFromMouse(evt:MouseEvent, elem:PaintObject):void{
	var pt:Point = getScreenPt(evt);
// calculate rotation
	var center:Point =  PaintVars.selectedElement.getScaleMatrix().transformPoint(PaintVars.selectedElement.getBoxCenter());
	var delta:Point = xPoint.vdiff(center, pt);
	var a:Number = ((Math.atan2(delta.y, delta.x)  * (180/Math.PI))) % 360;
	a -= 90;
	a = (a<0) ?(360+a):a;	
	if(evt.shiftKey) { // restrict rotations 
			var snap:int = 45;
			a = (Math.round(a / snap) * snap) % 360;
		 }
	PaintVars.selectedElement.setAttribute("angle", a);
	PaintVars.selectedElement.render();
}

private function resizeMouseMove(evt:MouseEvent):void{
	if (PaintVars.resizeMode  == "none") return;
	var pt:Point = getScreenPt(evt);
	var values:Object = getResizeValues(currentshape, pt);
	if(evt.shiftKey) {
		if(values.sx == 1) values.sx = values.sy
		else values.sy = values.sx;
	}
	PaintVars.selectedElement.updateScaleTransform (values.left+values.tx, values.top+values.ty, values.sx, values.sy);
	selectorGroup.updateFrame(currentshape);
	}
	
private function grabMouseMove(evt:MouseEvent):void{
 	var pt:Point = getScreenPt(evt);
	var delta:Point = xPoint.vdiff(pt, PaintVars.deltaPoint);
	PaintVars.deltaPoint = pt;
	movePointByDrag (delta.x,delta.y);
	var elem:PaintObject = gn(currentshape.getAttribute("parentid"));
	elem.refreshPath();
 }

private function movePointByDrag(dx:Number, dy:Number):void {
		var cx:Number = currentshape.getAttribute('cx');
		var cy:Number = currentshape.getAttribute('cy');
		var newcx:Number = Number(cx) + dx;
		var newcy:Number = Number (cy) + dy;
		currentshape.setAttribute("cx", newcx);
		currentshape.setAttribute("cy", newcy); 
		currentshape.render();
	}
	
private function getResizeValues(elem:PaintObject, pt:Object):Object{
	var box:Object = elem.getBox();
	var left:Number=box.x; var top:Number=box.y; 
	var width:Number=box.width; var height:Number=box.height;
	var dx:Number=(pt.x-PaintVars.initialPoint.x); var dy:Number=(pt.y-PaintVars.initialPoint.y);
// consider the scale matrix if it is there
	// if rotated, adjust the dx,dy values
	var angle:Number = elem.getAttribute('angle');
	if (angle && angle !=0) {
		var r:Number = Math.sqrt( dx*dx + dy*dy );
		var theta:Number = Math.atan2(dy,dx) - angle * Math.PI / 180.0;
		dx = r * Math.cos(theta);
		dy = r * Math.sin(theta);
		}
	var mtx:Matrix = dragObjMatrix.clone();
	mtx.invert();
	var point:Point = mtx.transformPoint(new Point(dx,dy));
	dx = point.x;	dy = point.y;
	if(PaintVars.resizeMode.indexOf("n")==-1 && PaintVars.resizeMode.indexOf("s")==-1) dy = 0;
	if(PaintVars.resizeMode.indexOf("e")==-1 && PaintVars.resizeMode.indexOf("w")==-1) dx = 0;
	
	var tx:Number = 0; var ty:Number = 0; 
	var sy:Number = height ? (height+dy)/height : 1;
	var sx:Number = width ? (width+dx)/width : 1;
	if(PaintVars.resizeMode.indexOf("n") != -1) { // negative dy
		sy = height ? (height-dy)/height : 1;
		ty = height;
	}
	if(PaintVars.resizeMode.indexOf("w") != -1) {// negative dx
		sx = width ? (width-dx)/width : 1;
		tx = width;
	}
	return {left: left, top: top, sx: sx, sy: sy, tx: tx, ty: ty};	
}

private function groupMouseMove(evt:MouseEvent):void {
	var pt:Point = getScreenPt(evt);
	selectorGroup.selectionRect(pt);
}

private function eraserMouseMove(evt:MouseEvent):void {
	if (! PaintVars.dragging) return;
	if (! mouseTarget) return;
	if (mouseTarget.tagName != "image") return;
	var	p:Point = getScreenPt(evt);
	paintPixels.eraserMouseMove(mouseTarget,p);
}

private function lassoMouseMove(evt:MouseEvent):void {
	if (! PaintVars.dragging) return;
	var	p:Point = getScreenPt(evt);
	paintPixels.lassoMouseMove(mouseTarget,p);
}

////////////////////////////////////
// Calls from the Mouse Up
////////////////////////////////////

private function selectMouseUp(evt:MouseEvent):void{
	if (PaintVars.backgroundIsSelected()) return;
	if (!currentshape) return;
	var pt:Point = getScreenPt(evt);
	if ((pt.x == PaintVars.initialPoint.x) && (pt.y == PaintVars.initialPoint.y)) reportClick(evt);
	else {
		var delta:Point = xPoint.vdiff(pt,PaintVars.deltaPoint);
		currentshape.moveBy(delta);
		selectorGroup.moveBy(delta);
		var p:Point = currentshape.getMoveBy();
		currentshape.clearMove();
		currentshape.translateTo(p);
		selectorGroup.selectorReset(currentshape);
		PaintVars.recordForUndo();
	}
} 

private function reportClick(evt:MouseEvent):void{
	if (!currentshape) return;
	switch (PaintVars.paintMode){
		case 'select':
			if (PaintVars.inTextEditting()) selectorGroup.quitTextEditMode(
				function():void { selectorGroup.showSelectorGroup(currentshape) });
			else if (PaintVars.textIsSelected()  && (PaintVars.pevSelection == currentshape)) selectorGroup.enterTextEditMode(currentshape);
			if (PaintVars.pathIsSelected() && (PaintVars.pevSelection == currentshape)) enterPathEditMode(currentshape);
			if (PaintVars.imageIsSelected()  && currentshape.getAttribute ("clip-path") && (PaintVars.pevSelection == currentshape)) enterImageEditMode(currentshape);
			if ((currentshape is PaintGroup) &&  (PaintVars.pevSelection == currentshape)) currentshape = breakGroupAppart(evt, currentshape);
			break;
		case 'rotate':
		case 'resize':
			break;
		default:
			currentshape.parent.removeChild(currentshape);
			currentshape = null;
			clearAllSelections();
			break;
		}	
	}

private function pathMouseUp(evt:MouseEvent):void{
 	currentshape.processPath();
	enterPathEditMode(currentshape);
}

private function sliceMouseUp(evt:MouseEvent):void {
 	currentshape.processPath();
 	var svg:SVGData = currentshape.odata.cloneSVG();
	currentshape.parent.removeChild(currentshape);	
	if (! PaintVars.selectedElement) return;
	currentshape = PaintVars.selectedElement;
	PaintVars.selectedElement.clipImage(svg);
	enterImageEditMode(currentshape);
}

private function enterImageEditMode(elem:PaintObject):void { 
	selectorGroup.hideSelection();
	var svg:SVGData = 	elem.getAttribute("clip-path").cloneSVG();	
	svg.id = "clippingmask";
	svg.setAttribute("mommy", elem);
	svg.setAttribute("fill", "none");
	var mtx:Matrix = elem.getScaleMatrix()
	mtx.concat (elem.getSimpleRotation());
	var list:Array = svg.convertPoints(mtx);
	svg.setAttribute("points", list);
	var newPath:PaintObject= new PaintObject(svg.tagName, "clippingmask", svg);
	addChild(newPath);
	enterPathEditMode(newPath);
}

public function enterPathEditMode(elem:PaintObject):void {
	selectorGroup.hideSelectorGroup();
	PaintVars.selectedElement = elem;
	PaintVars.pathSelector = elem;
	elem.showPathPoints();
	PaintVars.getKeyBoardEvents();
}

private function rectMouseUp(evt:MouseEvent):void {
	currentshape.makePathRect();
 	selectNewObject(evt);
}

private function ellipseMouseUp(evt:MouseEvent):void { selectNewObject(evt) }
private function selectNewObject(evt:MouseEvent):void {	selectorGroup.selectorReset(currentshape) }
private function rotateMouseUp(evt:MouseEvent):void { rotateMouseMove(evt) }

private function resizeMouseUp(evt:MouseEvent):void {
	if (PaintVars.resizeMode  == "none") return;
	var pt:Point = getScreenPt(evt);
	var values:Object = getResizeValues(currentshape, pt);
	if(evt.shiftKey) {
		if(values.sx == 1) values.sx = values.sy
		else values.sy = values.sx;
	}
	currentshape.resizeToMatrix();	
	PaintVars.selectedElement.render();
	selectorGroup.updateFrame(currentshape);
}

private function eraserMouseUp(evt:MouseEvent):void {
	if (! PaintVars.dragging) return;
	if (! mouseTarget) return;
	if (mouseTarget.tagName != "image") return;
	var	p:Point = getScreenPt(evt);
	paintPixels.eraserMouseUp(mouseTarget,p);
	PaintVars.getKeyBoardEvents();
}

private function lassoMouseUp(evt:MouseEvent):void {
	if (! PaintVars.dragging) return;
	var	p:Point = getScreenPt(evt);
	paintPixels.lassoMouseUp(mouseTarget,p);
	PaintVars.getKeyBoardEvents();
}

 private function grabMouseUp(evt:MouseEvent):void{
 	currentshape.setAttribute("fill", 0x0b72b5);
	currentshape.setAttribute("opacity", PaintVars.opacity); 
	currentshape.render();
	var elem:PaintObject = gn(currentshape.getAttribute("parentid"));
	var pt:Point = getScreenPt(evt);
	var id:String = currentshape.id;
	if (xPoint.vlen(xPoint.vdiff(pt, PaintVars.initialPoint)) == 0)  {
		var pnames:Array = elem.getAttribute("pointsnames");
		if (pnames.length > 2) { 
			if (pnames.indexOf(id) > -1) pnames.splice(pnames.indexOf(id), 1);
			elem.setAttribute("pointsnames", pnames);
 			currentshape.parent.removeChild(currentshape);
 			elem.refreshPath();
  		}
		}
 }

private function groupMouseUp(evt:MouseEvent):void{
	var pt:Point = getScreenPt(evt);
	if (xPoint.vlen(xPoint.vdiff(pt, PaintVars.initialPoint)) < 1) return;
	var group:Array= [];
	var i:int;
	var dx:Number = PaintVars.selectionBox.x ; var dy:Number  = PaintVars.selectionBox.y;
	var w:Number = PaintVars.selectionBox.width; var h:Number = PaintVars.selectionBox.height;
	if (w < 0) dx += w;
	if (h < 0) dy += h;
	w  = Math.abs(w); h  = Math.abs(h);
	var box:Rectangle = new Rectangle (dx, dy, w, h);
	for (i = 0; i < this.numChildren;  i ++) {
	 var elem:PaintObject =  this.getChildAt(i) as PaintObject;
	 if (!elem) continue;
	 if (elem.id == "staticbkg") continue;
	 if (box.intersects (elem.getTransformedBox())) group.push(elem);
	 }
	selectorGroup.hideSelectorGroup();
	if (group.length == 0) return;
	if (group.length == 1) selectorGroup.selectorReset(group[0]);		
	else {
		var g:* = makeAgroup(group);
		selectorGroup.selectorReset(g);
	}
	currentshape = PaintVars.selectedElement;
}

private function makeAgroup(group:Array):PaintObject{
	var	g:PaintGroup =new PaintGroup("g", getIdFor("g"));
	for (var i:int=0; i <group.length; i++){
		if ((group[i] as PaintObject).tagName == "g") var list:Array = removeAndAttach(g, group[i]); // make sure groups are flattened
		else g.addChild(group[i]);
		}
	g.setAttribute("children", g.getSVGChildren());
	this.addChild(g);
	return g;
}

private function removeAndAttach(p:Sprite, elem:PaintObject):Array{
	var res:Array = [];
  while (elem.numChildren > 0) {
  	var node:PaintObject = elem.getChildAt(0) as PaintObject;
  	if (node == null) continue;  	
  	if ((elem is PaintGroup) && (elem.getAttribute('angle') != 0)) (elem as PaintGroup).rotateFromPoint (node);
  	res.push(node);
		p.addChild(node);
  }
 elem.parent.removeChild(elem);
 return res;
}

private function breakGroupAppart(evt:MouseEvent, elem:PaintObject):PaintObject{
	var list:Array = removeAndAttach(this, elem);
	mouseTarget = getMouseTarget(evt);
	selectMouseDown(evt);
	return PaintVars.selectedElement;
}

private function noText(elem:PaintObject):PaintObject{
	if ((elem as PaintGroup) == null) return elem;
	var hastext:Boolean = false;
	for (var i:int=0; i < elem.numChildren; i++) {
	  var node:PaintObject = elem.getChildAt(i) as PaintObject;
  	if (node == null) continue;  
  	if (node.tagName == "text") this.addChild(node);
		}	
	if ((elem.numChildren < 2) && (elem.numChildren > 0)) {
		var pos:int = this.getChildIndex(elem);
		var list:Array = removeAndAttach(this, elem);
		elem = list[0];
		this.setChildIndex(elem,pos);
		}
	else elem.setAttribute("children", (elem as PaintGroup).getSVGChildren());
	elem.render();
	selectorGroup.selectorReset(elem);
	return elem;
}

public function deleteImageSelection():void{paintPixels.deletePressedOnAnts(mouseTarget);}

///////////////////////////////////////////////////
// Pt ot screen Coordinates
//////////////////////////////////////////////////

public function getScreenPt(evt:MouseEvent):Point {
	var pt:Point = new Point(evt.stageX, evt.stageY);
	var pos:Point = new Point(PaintVars.getScreenX(this, PaintEditor),PaintVars.getScreenY(this, PaintEditor));
	pt = xPoint.vdiff(pt, pos);
	pt.x = pt.x / PaintVars.currentZoom;
	pt.y = pt.y / PaintVars.currentZoom;
	return pt;
}

public function getIdFor(name:String):String {
	var n:int = 1;
	while (gn(name + "_" + n) != null) n++;
	return name + "_" + n;
}

//////////////////////////////////////////////////
// From Undo / Redo
/////////////////////////////////////////////////
public function reloadSVGData(spr:Sprite, list:Array):void{ 
	if (spr == null) spr = this;
	for(var i:int=0;i< list.length;i++){
		var odata:SVGData=list[i];
		if (!odata) continue;
		switch(getObjectType(odata)){
			case "g":
				var pg:PaintGroup = new PaintGroup(odata.tagName, odata.id, odata);
				spr.addChild(pg);
				reloadSVGData(pg, pg.getAttribute("children"));
				break;
			case "clip":
				var pc:PaintClipObject= new PaintClipObject(odata.tagName, odata.id, odata);
				spr.addChild(pc);
				pc.render();
				break
			default:
				var elem:PaintObject= new PaintObject(odata.tagName, odata.id, odata);
				spr.addChild(elem);
				elem.render();
				break;
			}
		}
	}


///////////////////////////////////////////////////
// Loading elements
//////////////////////////////////////////////////

public function loadSVGData(list:Array):void{addElements(this, list);}

public function loadImage(name:String, src:BitmapData):void {
	// redaw bitmap so it is  guarantee to have a trasnparent background
  var bm:BitmapData = new BitmapData(src.width,src.height, true, 0);
	bm.draw(src);
	src.dispose();
	// scale the bitmap if it doesn't fit on the canvas
	var cnv:Object = window.getCanvasWidthAndHeight();
	var scale:Number = 1;
	if ((bm.width > cnv.width) || (bm.height > cnv.height)) scale = Math.min(cnv.width/bm.width, cnv.height/bm.height);
	var dx:Number= (cnv.width - bm.width*scale) / 2;
	var dy:Number= (cnv.height - bm.height*scale) / 2;	
	var img:Bitmap =  new Bitmap(bm);
	var svg:Object =  {"x": dx, "y": dy, "width": bm.width, "height": bm.height,
		"bitmapdata": bm, "scalex": scale, "scaley": scale };	
	var	po:PaintObject =new PaintObject("image", getIdFor("image"));
	for (var key:String in svg) po.setAttribute (key, svg[key]);
	po.insertImage();		
	addChild(po);
	po.render();
	currentshape = po;
	currentshape.render();
	window.selectButton("select");
	selectNewObject(null);
	if (PaintVars.imageIsSelected()) window.activateBitmap();
	PaintVars.recordForUndo();  
	}		

public function loadBackgroundImage(name:String, src:BitmapData):void {
	// redaw bitmap so it is  guarantee to have a trasnparent background
  var bm:BitmapData = new BitmapData(src.width,src.height, true, 0);
	bm.draw(src);
	src.dispose();
 
	var cnv:Object = window.getCanvasWidthAndHeight();
	var scale:Number = 1;
	if ((bm.width > cnv.width) || (bm.height > cnv.height)) scale = Math.min(cnv.width/bm.width, cnv.height/bm.height);
	var dx:Number= (cnv.width - bm.width*scale) / 2;
	var dy:Number= (cnv.height - bm.height*scale) / 2;	
	var img:Bitmap =  new Bitmap(bm);
	var svg:Object =  {"x": dx, "y": dy, "width": bm.width, "height": bm.height,
		"bitmapdata": bm, "scalex": scale, "scaley": scale };	
	// if the image is exactly the scene dimension make it the background
	// this may change
	var id:String = ((bm.width == 480) && (bm.height == 360))  ? 	"staticbkg" : getIdFor("image");
	var oldbkg:PaintObject = gn("staticbkg");
	if ((id == "staticbkg") && oldbkg) oldbkg.parent.removeChild(oldbkg);
	var	po:PaintObject =new PaintObject("image", id);
	for (var key:String in svg) po.setAttribute (key, svg[key]);
	po.insertImage();		
	addChild(po);
	if (id == "staticbkg")setToBack(po);
	po.render();
	currentshape = po;
	currentshape.render();
	window.selectButton("select");
	selectNewObject(null);
	if (PaintVars.imageIsSelected()) window.activateBitmap();
	PaintVars.recordForUndo();  
	}
	
public function addElements(spr:Sprite, list:Array):void{
	for(var i:int=0;i< list.length;i++){
		var odata:SVGData=list[i];
		if (!odata) continue;
		switch(getObjectType(odata)){
			case "g":
				var pg:PaintGroup = new PaintGroup(odata.tagName, odata.id, odata);
				spr.addChild(pg);
				addElements(pg, pg.getAttribute("children"));
				break;
			case "clip":
				var pc:PaintClipObject= new PaintClipObject(odata.tagName, odata.id, odata);
				spr.addChild(pc);
				pc.render();
				break
			default:
				var elem:PaintObject= new PaintObject(odata.tagName, odata.id, odata);
				spr.addChild(elem);
				if (elem.tagName == "image") elem.setImageSrc();
				else elem.render();
				break;
			}
		}
	}

public function getObjectType(svg:SVGData):String{		
	if (svg.tagName == "g") return "g";
	if (svg.tagName == "image") return "image";
	if (svg.getAttribute("clip-path") != null) return "clip";
	else return svg.tagName;
}

	
///////////////////////////////////////////////////
// Other tools 
//////////////////////////////////////////////////
		
public function clearSVGroot():void{
	if (PaintVars.selectedElement) selectorGroup.hideSelectorGroup();
	this.setChildIndex(this.mask, 0);
	while (this.numChildren > 1) this.removeChild(this.getChildAt(1));
}

public function gn(str:String):*{
	for(var i:int=0;i< this.numChildren;i++){
		var elem:DisplayObject=this.getChildAt(i);
		if ((elem is PaintObject) && ((elem as PaintObject).id == str)) return elem;
		else if (elem.name == str) return elem;
	}
	return null;
}

private function getMouseTarget(evt:MouseEvent):* {
 	var mt:PaintObject;
 	var sel:* = selectorGroup.getMouseTarget(evt) ;
 	if (sel != null) return sel;
 	return findHitinCanvas(evt, this);
 	}
 	
 private function findHitinCanvas(evt:MouseEvent, p:Sprite):* {	
  for (var i:int =  p.numChildren - 1; i >= 0; i--) {
		var elem:PaintObject=p.getChildAt(i) as PaintObject;
		if (elem== null) continue;
		if (elem.touched(evt)) return elem;
		}
	return null;
}

public function isEmpty():Boolean{
	var n:int = 0;
	for(var i:int=0;i< this.numChildren;i++){
		var elem:PaintObject=this.getChildAt(i) as PaintObject;
		if (!elem) continue;
		n++;
	}
	return n < 1;
}

public function getSVGlist():Array{
	var res:Array = [];
	for(var i:int=0;i< this.numChildren;i++){
		var elem:PaintObject=this.getChildAt(i) as PaintObject;
		if (!elem) continue;
		if ((elem.id).indexOf("grab_") > -1) continue;
		res.push (elem.odata);
	}
	return res;
}

}}
