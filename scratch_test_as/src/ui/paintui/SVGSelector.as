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
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.geom.*;

public class SVGSelector extends Sprite {

	private var selectorRect:Shape;
	private var selectorGrips:Object;
	private var rotateGripConnector:Shape;
	private var rotateGrip:PaintObject;
	private var dashArray:Array;
	private var dashIndex:int;
	private var xform:Matrix;

	public function SVGSelector() {
		selectorRect = new Shape();
		dashArray = [5,5];
		addChild(selectorRect);
		selectorGrips = {'nw': null, 'n': null, 'ne': null, 'e': null, 'se': null, 's': null, 'sw': null,'w': null};
		rotateGripConnector = addRotateGripConnector();
		rotateGrip = addRotationGrip();
		for (var dir:String in selectorGrips) selectorGrips[dir] = addGrip('resize_'+dir);
		this.visible = false;
		xform = new Matrix();
	}

	public function hideSelectorGroup():void {
		hideSelection();
		PaintVars.svgroot.window.activateSVG();
	}

	public function clearMove():void { xform.identity() }
	public function moveBy(delta:Point):void { xform.translate(delta.x, delta.y) }

	public function selectionStart(pt:Point):void {
		this.transform.matrix = new Matrix();
		this.transform.matrix.identity();
		showBox();
		PaintVars.selectionBox = new Rectangle(pt.x, pt.y, 0, 0);
		drawSelection(PaintVars.selectionBox);
	}

	public function selectionRect(pt:Point):void {
		PaintVars.selectionBox.width = pt.x - PaintVars.selectionBox.x;
		PaintVars.selectionBox.height = pt.y - PaintVars.selectionBox.y;
		/*
			if (m.a < 0) box.x -= box.width;
		if (m.d < 0) box.y -= box.height;
		*/
		drawSelection(PaintVars.selectionBox);
	}

	private function showBox():void {
		this.visible = true;
		rotateGrip.visible = false;
		rotateGripConnector.visible = false;
		for (var dir:String in selectorGrips) selectorGrips[dir].visible = false;
	}

	public function hideSelection():void {
		this.visible = false;
		PaintVars.selectedElement = null;
	}

	public function selectorReset(obj:PaintObject):void {
		showSelectorGroup(obj);
		if (obj.tagName == 'text') showBox();
		clearMove();
		updateFrame(obj);
	}

	public function showSelectorGroup(obj:PaintObject):void {
		if (obj && (obj.id == 'staticbkg')) {
			hideSelection();
			showBox();
//			selectorGroup.style.visibility = 'visible';
//			selectorRect.setAttribute('stroke', '#d3dae0');
//			selectorRect.setAttribute('stroke-width', '4');
		} else {
			this.visible = true;
			rotateGrip.visible = true;
			rotateGripConnector.visible = true;
			for (var dir:String in selectorGrips) selectorGrips[dir].visible = true;
		}
		this.parent.setChildIndex(this, this.parent.numChildren - 1);
		PaintVars.selectedElement = obj;
	}

	public function updateFrame(e:PaintObject):void {
		var a:Number= e.getAttribute('angle');
		var box:Rectangle = e.getBox();
		// set selector transform
		this.transform.matrix.identity();
		var mtx:Matrix = e.getSimpleRotation()
		mtx.concat (xform);
		this.transform.matrix = mtx;
		var m:Matrix = e.sform.clone();
		m.concat (e.getScaleMatrix());
		var p:Point = m.transformPoint(new Point(box.x, box.y));
		box.width= Math.abs(box.width*m.a);
		box.height= Math.abs(box.height*m.d);
		box.x= p.x;
		box.y = p.y;
		if (m.a < 0) box.x -= box.width;
		if (m.d < 0) box.y -= box.height;
		drawSelection(box);
	}

	public function getMouseTarget(evt:MouseEvent):PaintObject {
		if (!this.visible ) return null;
		if (rotateGrip.visible && rotateGrip.hitTestPoint(evt.stageX, evt.stageY,true)) return rotateGrip;
		for (var dir:String in selectorGrips) {
			var sh:PaintObject = selectorGrips[dir] as PaintObject;
			if (sh.visible && sh.hitTestPoint(evt.stageX, evt.stageY)) return sh;
		}
		return null;
	}

	private function drawSelection (box:Rectangle):void {
		if (PaintVars.backgroundIsSelected()) box.inflate(1, 1);
		selectorRect.x = box.x;
		selectorRect.y = box.y;
		var g:Graphics = selectorRect.graphics;
		g.clear();
		if (PaintVars.backgroundIsSelected()) {
			g.lineStyle(2, CSS.overColor, 1, true);
			g.drawRect(box.x, box.y, box.width, box.height);
		}
		g.lineStyle(2,getLineColor(), 1,true);
		drawDashedRect(g, 0,0, box.width, box.height);
		var gripCoords:Object = getGripCoordsForm(box);
		for (var dir:String in gripCoords) {
			var coords:Array = gripCoords[dir];
			var sh:PaintObject = selectorGrips[dir] as PaintObject;
			sh.x = coords[0] - 2;
			sh.y = coords[1] - 2;
		};
		rotateGripConnector.x = box.x + (box.width)/2;
		rotateGripConnector.y = box.y - 20;
		rotateGrip.x = box.x + (box.width)/2 - 2;
		rotateGrip.y = box.y - 20 - 2;
	}

	private function getLineColor():uint {
		if (PaintVars.selectedElement is PaintGroup) return 0x0bb50;
		if (PaintVars.inTextEditting()) return 0xFFFFFF;
		if (PaintVars.backgroundIsSelected()) return 0xFFFFFF;
		if (PaintVars.textIsSelected()) return CSS.overColor;
		else return 0x0b72b5;
	}

	private function getGripCoordsForm(box:Rectangle):Object {
		return {
			nw: [box.x, box.y],
			ne: [box.x + box.width, box.y],
			sw: [box.x, box.y+box.height],
			se:	[box.x + box.width, box.y + box.height],
			n:	[box.x + (box.width / 2), box.y],
			w:	[box.x, box.y + (box.height / 2)],
			e:	[box.x + box.width, box.y + (box.height / 2)],
			s:	[box.x + (box.width / 2), box.y + box.height]
		};
	}

	private function addRotationGrip():PaintObject {
		var rg:PaintObject = addCircle('rotate', 4, 0x009eff, 0x0b72b5);
		addChild(rg);
		rg.setAttribute('opacity',1);
		rg.render ();
		return rg;
	}

	private function addRotateGripConnector():Shape {
		var rg:Shape = new Shape();
		addChild(rg);
		rg.name = 'rotateline';
		var g:Graphics = rg.graphics;
		g.lineStyle(2,0x0b72b5,1,true);
		var dashDrawnLength:Number = 0;
		Turtle.xcor = 0;
		Turtle.ycor = 10;
		Turtle.xmax = 0;
		Turtle.ymax = 20;
		Turtle.seth(180);
		var missing:Number=lineTo(g, 0, 20);
		return rg;
	}

	private function addGrip(str:String):PaintObject{
		var rg:PaintObject = addCircle(str, 4, 0x0b72b5, 'none');
		addChild(rg);
		rg.render ();
		return rg;
	}

	private function drawDashedRect(g:Graphics, dx:Number, dy:Number, w:int, h:int):void {
		dashIndex = 0;
		var dashDrawnLength:Number = 0;
		Turtle.xcor = -w/2;
		Turtle.ycor = h/2;
		Turtle.xmax = w;
		Turtle.ymax = h;
		Turtle.seth(90);
		var missing:Number=0;
		var len:Number = w;
		for (var i:int=0; i < 4; i++) {
			missing= lineTo(g, missing, len);
			Turtle.rt(90);
			if (missing > 0) Turtle.forward(missing, g);
			if (((i + 1)%2) == 0) len = w;
			else len = h;
		}
	}

	private function lineTo(g:Graphics, delta:Number, maxl:Number):Number {
		var missing:Number;
		var lengthToDraw:Number;
		while (delta < maxl) {
		Turtle.pendown = (dashIndex % 2) == 0;
		lengthToDraw = Math.min(dashArray[dashIndex], maxl - delta);
			Turtle.forward(lengthToDraw, g);
			missing = dashArray[dashIndex] - lengthToDraw;
			dashIndex++;
			dashIndex = dashIndex % dashArray.length;
			delta += lengthToDraw;
		}
		return missing;
	}

	public function addCircle(str:String, radius:Number, fc:*, sc:*):PaintObject {
		var	odata:PaintObject =new PaintObject('circle', str);
		var attr:Object = {'cx': radius / 2, 'cy': radius / 2, 'r': radius, 'opacity': 0.7, 'fill': fc, 'stroke': sc};
		if (sc !='none') attr ['stroke-width'] = 2;
		for (var val:String in attr) odata.setAttribute(val, attr[val]);
		return odata;
	}

	public function quitPathEditMode():void {
		PaintVars.pathSelector.hidePathPoints();
		if (PaintVars.pathSelector.id == 'clippingmask') PaintVars.pathSelector.parent.removeChild(PaintVars.pathSelector);
		PaintVars.pathSelector = null;
		PaintVars.pevSelection = null;
		PaintVars.selectedElement = null;
		PaintVars.getKeyBoardEvents();
	}

	/////////////////////////////////
	// Text Management
	/////////////////////////////////

	public function quitTextEditMode(fcn:Function):void {
		fcn.apply(null, []);
		if (PaintVars.keyFocus && (PaintVars.keyFocus.parent is PaintObject))
			(PaintVars.keyFocus.parent as PaintObject).exitEditMode();
		PaintVars.pevSelection = null;
		PaintVars.keyFocus = null;
		PaintVars.appStage.focus = null;
	}

	public function enterTextEditMode(elem:PaintObject):void {
		PaintVars.selectedElement = elem;
		elem.enterEditMode();
		clearMove();
		showBox();
		updateFrame(elem);
	}

}}
