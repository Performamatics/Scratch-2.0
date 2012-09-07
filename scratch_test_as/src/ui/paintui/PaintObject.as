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
/*
	Rendering object when costume is viewed in the editor
*/

package ui.paintui {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.*;
	import util.*;

public class PaintObject extends Sprite {

	private const filldot2:int = 0xFFFFFF;
	private const filldot:int = 0x0b72b5;
	private const strokedot2:int = 0x0b72b5 ;
	private const strokedot:int = 0xFFFFFF;

	public var tagName:String;
	public var id:String;
	public var odata:SVGData;
	public var sform:Matrix; // matrix while scaling a selected object

	private var xform:Matrix; // matrix for dragging

	public function PaintObject(type:String, uniqueId:String, svgdata:SVGData = null) {
		odata = (svgdata != null) ? svgdata : new SVGData(type, uniqueId);
		if (svgdata && type == 'text') insertText();
		if (svgdata && type == 'image') insertImage();
		if (getAttribute ('clip-path')) insertMask();
		this.tagName=type;
		this.id = uniqueId;
		xform = new Matrix();
		sform = new Matrix();
	}

	private function insertMask():void {
		mask = new Shape();
		addChild(mask);
		getAttribute ('clip-path').render(Shape(mask).graphics);
	}

	private function insertText():void {
		this.setAttribute('textfield', cloneSVGText());
		this.setAttribute('container', this);
		this.addChild(this.getAttribute('textfield'));
	}

	public function insertImage():void {
		this.setAttribute ('container', this);
		var img:Bitmap = new Bitmap(getAttribute('bitmapdata'));
		this.setAttribute('bitmap', img);
		img.x = this.getAttribute('x');
		img.y = this.getAttribute('y');
		addChild(img);
	}

	public function render():void {
		var g:Graphics =this.graphics;
		odata.render(g);
		var m:Matrix = getScaleMatrix();
		m.concat (getSimpleRotation());
		this.transform.matrix = m;
		if (getAttribute('clip-path')) getAttribute('clip-path').render(Shape(mask).graphics);
	}

	public function clearMove():void { xform.identity() }
	public function getMoveBy():Point { return new Point (xform.tx, xform.ty) }
	public function clearScaleMatrix():void { sform.identity() }

	private function applyMatrix(mtx:Matrix):void { odata.applyMatrix(mtx) }
	private function skewImageRect(mtx:Matrix):void { odata.skewImageRect(mtx) }

	public function updateScaleTransform(tx:Number, ty:Number, sx:Number, sy:Number):void {
		sform.identity();
		sform.translate(-tx, -ty);
		sform.scale(sx,sy);
		sform.translate(tx,ty);
		var m:Matrix = sform.clone();
		m.concat (getScaleMatrix());
		m.concat (getSimpleRotation());
		this.transform.matrix = m;
	}

	public function moveBy(delta:Point):void {
		xform.translate(delta.x, delta.y);
		var m:Matrix = getScaleMatrix();
		m.concat (getSimpleRotation());
		m.concat (xform);
		this.transform.matrix = m;
	}

	public function getAttribute(key:String):* { return odata.getAttribute(key) }
	public function setAttribute(key:String, val:*):void { odata.setAttribute(key,val) }

	public function getBox():Rectangle { return odata.getBox() }
	public function getBoxCenter():Point { return odata.getBoxCenter() }
	public function getTransformedBox():Rectangle {return odata.getTransformedBox() }
	public function hasNoMatrices():Boolean {return odata.hasNoMatrices() }

	public function getCombinedMatrix():Matrix { return odata.getCombinedMatrix() }
	public function getSimpleRotation():Matrix { return odata.getSimpleRotation() }
	public function getScaleMatrix():Matrix { return odata.getScaleMatrix() }
	public function resizeToMatrix():void { resizeShape(sform.clone()) }

	private function getDotColor():uint { return (getAttribute('kind') == 'editable') ? filldot : filldot2 }
	private function getDotStroke():uint { return (getAttribute('kind') == 'editable') ? strokedot : strokedot2 }

	public function resizeShape(mtx:Matrix):void {
		switch (tagName){
		case 'text':
		case 'image':
			odata.resizeImageRect(mtx);
			render();
			break;
		case 'rect':
			odata.recreateRect(mtx);
			render();
			break;
		case 'ellipse':
			odata.recreateEllipse(mtx);
			render();
			break;
		case 'polygon':
		case 'path':
			odata.resizePath(mtx);
			render();
			break;
		}
		clearScaleMatrix();
	}

	public function skewShape(mtx:Matrix):void {
		// with no skew this is the best we can do
		// otherwise we need to add a skew matrix
		// see nots on SkewImageRect
		switch (tagName) {
		case 'image':
		case 'text':
			skewImageRect(mtx.clone());
			break;
		case 'ellipse':
			makePathEllipse();
			applyMatrix(mtx);
			break;
		case 'rect':
			makePathRect();
			applyMatrix(mtx);
			break;
		case 'polygon':
			applyMatrix(mtx);
			break;
		case 'path':
			applyMatrix(mtx);
			break;
		}
		render();
	}

	public function translateTo(p:Point):void {
		odata.translateTo(p);
		if (getAttribute('clip-path')) {
			var mtx:Matrix = getScaleMatrix();
			mtx.invert()
			getAttribute('clip-path').translateTo(mtx.transformPoint(p));
		}
		render();
	}

	public function getBoxCenterDelta():Point {
		var m:Matrix = sform.clone();
		m.concat (getScaleMatrix());
		return odata.getBoxCenterDelta(m);
	}

	////////////////////////////////////////////
	// Ellipse convertion to Path
	////////////////////////////////////////////

	public function makePathEllipse():void {
		var rx:Number = getAttribute('rx'); 
		var ry:Number = getAttribute('ry');
		var cx:Number = getAttribute('cx'); 
		var cy:Number =getAttribute('cy');
		var kappa:Number =(Math.sqrt(2) - 1) / 3 * 4;
		var pl:Array = [['M', new Point(cx-rx, cy)],
			['C', new Point (cx-rx, cy-ry * kappa), new Point (cx - rx * kappa, cy- ry), new Point(cx, cy - ry)],
			['C', new Point (cx + rx * kappa, cy- ry), new Point(cx + rx, cy - ry * kappa), new Point (cx + rx, cy)],
			['C', new Point(cx + rx, cy + ry * kappa), new Point (cx + rx * kappa, cy + ry), new Point(cx, cy + ry)],
			['C', new Point (cx - rx * kappa, cy + ry), new Point(cx-rx, cy+ ry * kappa), new Point (cx-rx, cy)]];
		changeTypeAndId('path', PaintVars.svgroot.getIdFor('path'));
		setAttribute('commands', pl);
		setAttribute('kind', 'noneditable');
		render();
	}

	////////////////////////////////////////////
	// Process the path when mouse up rect
	////////////////////////////////////////////

	public function makePathRect():void {
		var w:Number = getAttribute('width'); 
		var h:Number = getAttribute('height');
		var dx:Number = getAttribute('x'); 
		var dy:Number = getAttribute('y');
		var pl:Array = [
			new Point(dx, dy),
			new Point(dx + w, dy),
			new Point(dx + w, dy + h),
			new Point(dx, dy + h)];
		changeTypeAndId('polygon', PaintVars.svgroot.getIdFor('polygon'));
		setAttribute('points', pl);
		render();
	}

	//////////////////////////////////////////
	// Process the path when mouse up Path
	/////////////////////////////////////////

	public function processPath():void {
		smoothPoints();
		addPoints(); // make sure points are evenly spaced
		deletePoints();
		fromLinesToCurves();
	}

	private function smoothPoints():void {
		var pl:Array = getAttribute('points');
		var interval:int = 3;
		var i:int;
		var res:Array = [];
		var n:int = pl.length;
		for (i = 0; i < (n - 1); i++) {
			var ax:Number =0;
			var ay:Number =0;
			for (var j:int = -interval; j <= interval; j++) {
				var nj:int = Math.max(0, i + j);
				nj = Math.min(nj, n - 1);
				ax += pl[nj].x;
				ay += pl[nj].y;
			}
			ax /= ((interval * 2) + 1);
			ay /= ((interval * 2) + 1);
			res.push(new Point(ax, ay));
		}
		res.push(pl[n - 1]);
		setAttribute('points', res);
	}

	private function addPoints():void {
		var n:int = 0;
		var it:int=0;
		var b:Boolean = true;
		while (b){
			b = fillWithPoints();
			it++;
			if (it>10) return;
		}
	}

	private function fillWithPoints():Boolean {
		var pl:Array = getAttribute('points');
		var n:int = pl.length;
		var i:int = 1;
		var b:Boolean = false;
		var res:Array = [];
		res.push (pl[0]);
		while (i < n - 1) {
			var here:Point = pl[i];
			var after:Point = pl[i+ 1];
			var l2:Number = xPoint.vlen(xPoint.vdiff(after, here));
			res.push(here);
			if (l2 > 5) {
				var mp:Point = xPoint.vmid(here, after);
				res.push(mp);
				b = true;
			}
			i++;
		}
		res.push(pl[n - 1]);
		setAttribute('points', res);
		return b;
	}

	private function deletePoints():void {
		var pl:Array = getAttribute('points');
		var n:int = pl.length;
		var i:int = 1; var j:int = 0;
		var plist:Array = [];
		plist.push(pl[0]);
		while (i < n - 1) {
			var before:Point = pl[j];
			var here:Point = pl[i];
			var after:Point = pl[i+ 1];
			var l1:Point = xPoint.vdiff(before, here);
			var l2:Point = xPoint.vdiff(after, here);
			var div:Number = xPoint.vlen(l1)*xPoint.vlen(l2);
			if (div ==0) div = 0.01;
			var factor:Number = xPoint.vdot(l1,l2)/ div;
			if ((factor > -0.9) || (xPoint.vlen(l2) > 20) || (xPoint.vlen(l1) > 20)) {
				plist.push(pl[i]);
				j = i;
			}
			i++;
		}
		before = pl[n-2];
		here = pl[n-1];
		if (xPoint.vlen(xPoint.vdiff(before,here)) < 3) plist.pop();
		plist.push(pl[n-1]);
		setAttribute('points', plist);
	}

	private function fromLinesToCurves():void {
		var pointslist:Array = getAttribute('points');
		var first:Point = pointslist[0];
		var lastpoint:Point = pointslist[pointslist.length - 1];
		changeTypeAndId('path', PaintVars.svgroot.getIdFor('path'));
		setAttribute('points', pointslist);
		setAttribute('kind', 'editable');
		var c:*= PaintVars.svgroot.window.colorPalette.getFillColor();
		if (xPoint.vlen(xPoint.vdiff(lastpoint,first)) < 10) setAttribute('fill', c);
		render();
	}

	/////////////////////////////////////////////////////////////
	// Path editing
	////////////////////////////////////////////////////////////

	public function showPathPoints():void {
		var mtx:Matrix = getScaleMatrix()
		mtx.concat (getSimpleRotation());
		var list:Array = convertPoints(mtx);
		if (list == null) return;
		var a:Number =getAttribute ('angle');
		if ((a !=0) && (SVGImport.isGradient(getAttribute('fill')))) odata.applyMatrixToGradient(a);
		setAttribute('points', list);
		var plist:Array = [];
		var pnames:Array = [];
		for (var j:int = 0; j < list.length; j++) {
			var cp:PaintObject = getControlPoint(list[j]);
			plist.push (cp);
			pnames.push(cp.id);
			cp.addEventListener(MouseEvent.MOUSE_OVER, highlightdot);
			cp.addEventListener(MouseEvent.MOUSE_OUT, unhighlightdot);
		}
		for (var k:int=0; k< plist.length; k++) plist[k].setAttribute('parentid', odata.id);
		setAttribute('pointsnames', pnames);
		clearScaleMatrix();
		setAttribute ('angle', 0);
		render();
	}

	public function convertPoints(mtx:Matrix):Array { return odata.convertPoints(mtx) }

	public function refreshPath():void {
		setAttribute('points', getPointsCoodinates());
		if (id == 'clippingmask') {
			var img:PaintObject = getAttribute('mommy');
			var clip:SVGData = img.getAttribute ('clip-path');
			clip.setAttribute('points', img.getClipPoints(getAttribute('points')));
			clip.render(Shape(img.mask).graphics);
		 }
		render();
	}

	private function getClipPoints(list:Array):Array {
		var mtx:Matrix = getCombinedMatrix();
		mtx.invert();
		var res:Array = [];
		for (var j:int = 0; j < list.length; j++) {
			var centerpt:Point = list [j];
			var pt:Point= mtx.transformPoint(centerpt) ;
			res.push(pt)
		}
		return res;
	}

	private function highlightdot(e:MouseEvent):void {
		var shape:PaintObject = e.target as PaintObject;
		if (!shape) return;
		if (shape.parent == null) return;
		shape.setAttribute('fill', 0x00ffff);
		shape.setAttribute('opacity', 1);
		shape.render();
	}

	private function unhighlightdot(e:MouseEvent):void {
		var shape:PaintObject = e.target as PaintObject;
		if (!shape) return;
		if (shape.parent == null) return;
		var p:PaintObject = PaintVars.svgroot.gn(shape.getAttribute('parentid'));
		shape.setAttribute('fill',p.getDotColor());
		shape.setAttribute('opacity', PaintVars.opacity);
		shape.render();
	}

	private function getControlPoint(pt:Point):PaintObject {
		var radius:Number = Math.floor (5 /PaintVars.currentZoom) + 1;
		var id:String = PaintVars.svgroot.getIdFor('grab');
		var	rg:PaintObject = new PaintObject('circle', id);
		var attri:Object = {'cx': pt.x, 'cy': pt.y, 'r': radius, 'opacity': PaintVars.opacity,
			'fill': getDotColor(), 'stroke': getDotStroke(), 'stroke-width': 1};
		for (var val:String in attri) rg.setAttribute(val, attri[val]);
		rg.render ();
		this.parent.addChild(rg);
		return rg;
	}

	private function getPointsCoodinates():Array {
		var plist:Array = getAttribute('pointsnames');
		if (!plist) return[];
		var pointslist:Array = [];
		for (var i:int=0 ; i < plist.length; i++){
			var dot:PaintObject = PaintVars.svgroot.gn(plist[i]);
			pointslist.push(getNsPoint(dot));
		}
		return pointslist;
	}

	private function getNsPoint(dot:PaintObject):Point {
		var mtx:Matrix = getScaleMatrix();
		var rot:Matrix = getSimpleRotation();
		mtx.invert();
		rot.invert();
		var centerpt:Point = new Point(dot.getAttribute('cx'),dot.getAttribute('cy'));
		var pt:Point= mtx.transformPoint(centerpt) ;
		pt= rot.transformPoint(pt) ;
		return pt;
	}

	public function hidePathPoints():void {
		var plist:Array = getAttribute('pointsnames');
		for (var i:int = 0 ; i < plist.length; i++){
			var dot:PaintObject = PaintVars.svgroot.gn(plist[i]);
			if (!dot) continue;
			dot.parent.removeChild(dot);
		}
		setAttribute('pointsnames', undefined);
	}

	public function changeTypeAndId(tag:String, mid:String):void {
		odata.tagName = tag;
		odata.id = mid;
		this.tagName = tag;
		this.id = odata.id;
	}

	////////////////////////////////////////
	// UI Path editing Adding Points
	///////////////////////////////////////

	public function addApoint(pt:Point):void {
		var plist:Array = getAttribute('points');
		var list:Array = getPointsCoodinates();
		var canvas:Shape = new Shape();
		var g:Graphics = canvas.graphics;
		var indx:int;
		var w:Number = getAttribute('stroke-width');
		w = (w < 4) ? 8 : w * 2;
		g.lineStyle(w,0xff00FF,1,true,'normal', CapsStyle.ROUND, JointStyle.MITER);
		switch (tagName) {
		case 'path' :
			indx =getAttribute('points') ? hitPlaceBezier(canvas, pt) : -1;
			break;
		case 'polygon' :
			indx = hitPlaceLine(canvas, pt);
			break;
		default:
			indx = hitPlaceBezier(canvas, pt);
			break;
		}
		if (indx < 0) return;
		var mtx:Matrix = getSimpleRotation();
		mtx.invert();
		var newpt:Point = mtx.transformPoint(pt);
		list.splice(indx,0, newpt);
		setAttribute('points', list);
		render();
		hidePathPoints();
		showPathPoints();
	}

	private function hitPlaceBezier(cnv:Shape, pt:Point):int {
		var bmp:BitmapData = PaintVars.offscreen;
		var g:Graphics = cnv.graphics;
		var list:Array = getAttribute('points');
		var first:Point = list[0];
		g.moveTo(first.x, first.y);
		var indx:int = -1;
		var keep:Boolean = true;
		var max:int = list.length - 1;
		var i:int = 1;
		var quad:Object;
		if (list.length < 3 )	return hitPlaceLine(cnv, pt);
		odata.acurve = false;
		var mtx:Matrix =getSimpleRotation();
		while(keep) {
			odata.curves=[];
			bmp.fillRect(bmp.rect, 0x00000000);
			odata.drawSegment(g, list[i-1], list[i], list[i+1]);
			for each (quad in odata.curves) g.curveTo(quad.c.x, quad.c.y, quad.p.x, quad.p.y);
			bmp.draw(cnv, mtx);
			if (bmp.hitTest(new Point(0,0), 0xFF, pt)) indx = i;
			i++;
			keep = (indx== -1) && i < max;
		}
		if (indx < 0) {
			odata.curves=[];
			bmp.fillRect(bmp.rect, 0x00000000);
			var lastpoint:Point = list[list.length-1];
			var farilyclose:Boolean = xPoint.vlen(xPoint.vdiff(lastpoint,first)) < 10;
			if (farilyclose) odata.drawSegment(g, list[list.length-2], lastpoint,first);
			else odata.drawSegment(g, list[list.length-2], lastpoint,lastpoint);
			for each (quad in odata.curves) g.curveTo(quad.c.x, quad.c.y, quad.p.x, quad.p.y);
			bmp.draw(cnv, mtx);
			if (bmp.hitTest(new Point(0,0), 0xFF, pt)) indx = list.length-1;
		}
		return indx;
	}

	private function hitPlaceLine(cnv:Shape, pt:Point):int {
		var bmp:BitmapData = PaintVars.offscreen;
		var g:Graphics = cnv.graphics;
		var list:Array = getAttribute('points');
		var indx:int = -1;
		var keep:Boolean = true;
		var i:int = 1;
		var first:Point = list[0];
		list.push (first);
		var max:int = list.length - 1;
		g.moveTo(first.x, first.y);
		var mtx:Matrix =getSimpleRotation();
		while (keep) {
			bmp.fillRect(bmp.rect, 0x00000000);
			g.lineTo(list[i].x, list[i].y);
			bmp.draw(cnv, mtx);
			if (bmp.hitTest(new Point(0,0), 0xFF, pt)) indx = i;
			i++
			keep = (indx== -1) && i < max;
		}
		if (indx < 0) {
			bmp.fillRect(bmp.rect, 0x00000000);
			g.lineTo(first.x, first.y);
			bmp.draw(cnv, mtx);
			if (bmp.hitTest(new Point(0,0), 0xFF, pt)) indx = max;
		}
		return indx;
	}

	//////////////////////////////////////////////////////////
	// Image
	/////////////////////////////////////////////////////////

	public function touched(evt:MouseEvent):Boolean {
		switch (tagName) {
		case 'image':
			var pt:Point = PaintVars.svgroot.getScreenPt(evt);
			var hit:Boolean = (PaintVars.antsAlive() && (PaintVars.marchingants.name == id)) || (PaintVars.paintMode == 'wand');
			var color:uint = hit ? 0xFFFFFFFF : 0x00FFFFFF;
			var rect:Rectangle = new Rectangle(0,0, PaintVars.offscreen.width, PaintVars.offscreen.height);
			PaintVars.offscreen.fillRect(rect, color); // not transparent if ants are active
			odata.stamp(PaintVars.offscreen);
			return PaintVars.offscreen.getPixel32(pt.x, pt.y) != 0;
		default:
			return hitTestPoint(evt.stageX, evt.stageY, true);
		}
	}

	private function getOffsetPoint(pt:Point):Point {
		var cnv:Object = PaintVars.svgroot.window.getCanvasWidthAndHeight();
		var pt:Point = getTransformedPoint(pt);
		if (pt.x < 0) pt.x = 0;
		if (pt.y < 0) pt.y = 0;
		if (pt.x > cnv.width) pt.x =cnv.width;
		if (pt.y > cnv.height) pt.y = cnv.height
		return pt;
	}

	public function getTransformedPoint(pt:Point):Point {
		var mtx:Matrix = getCombinedMatrix();
		/*
		var rot:Matrix = getSimpleRotation();
		var mtx:Matrix = getScaleMatrix();
		rot.invert();
		var pt:Point= rot.transformPoint(pt) ;
		*/
		mtx.invert();
		return mtx.transformPoint(pt) ;
	}

	///////////////////////////////////////////////////////////
	// Text Creation and data Storage
	//////////////////////////////////////////////////////////

	public function cloneSVGText():TextField {
		var fmt:TextFormat = new TextFormat(
			getAttribute('font-family'), getAttribute('font-size'), getAttribute('fill'), getAttribute('font-weight'));
		fmt.align = getTextAligment();
		var tf:TextField = new TextField();
		tf.defaultTextFormat = fmt;
		tf.autoSize = getTextAutosize();
		tf.selectable = false;
		tf.text = getAttribute('textContent');
		tf.type = TextFieldType.DYNAMIC;
		tf.x = getAttribute('x');
		tf.y = getAttribute('y');
		setAttribute('y', tf.y);
		return tf;
	}

	public function createSVGText():TextField {
		var fmt:TextFormat = new TextFormat(
			getAttribute('font-family'), getAttribute('font-size'), getAttribute('fill'), getAttribute('font-weight'));
		fmt.align = getTextAligment();
		var tf:TextField = new TextField();
		tf.defaultTextFormat = fmt;
		tf.autoSize = getTextAutosize();
		tf.selectable = true;
		tf.text = getAttribute('textContent');
		tf.type = TextFieldType.INPUT;
		tf.background = true;
		tf.backgroundColor =getColorContrast();
		tf.setTextFormat(fmt);
		addChild (tf);
		tf.x = getAttribute('x'); // - tf.width / 2;;
		tf.y = getAttribute('y') - tf.height / 2;
		PaintVars.appStage.focus = tf;
		setAttribute('y', tf.y);
		tf.addEventListener(Event.CHANGE, textChanged);
		return tf;
	}

	private function getColorContrast():uint {
		var rgbalist:Array = Color.rgb2hsv(getAttribute('fill'));
		var baselist:Array = Color.rgb2hsv(0xFFFFFF);
		var hx:Number = rgbalist[0] - baselist[0];
		var sx:Number = rgbalist[1] - baselist[1];
		var bx:Number = rgbalist[2] - baselist[2];
		if (needsAbackground(hx, (sx*sx) + (bx*bx))) return CSS.onColor;
		else return CSS.panelColor;
	}

	private function needsAbackground(hx:Number, sb:Number):Boolean {
		if ((hx == 0)&& (sb < 0.03)) return true;
		if (( hx > 55) &&( hx < 66)) return true;
		return false;
	}

	public function chooseContrast():void {
		var tf:TextField = getAttribute('textfield');
		if (!tf) return;
		tf.backgroundColor =getColorContrast();
	}

	public function exitEditMode():void {
		var tf:TextField = getAttribute('textfield');
		tf.selectable = false;
		tf.type = TextFieldType.DYNAMIC;
		tf.background = false;
		setAttribute('textContent', tf.text);
		tf.removeEventListener(Event.CHANGE, textChanged);
		render();
		PaintVars.recordForUndo();
	}

	public function enterEditMode():void {
		var tf:TextField = getAttribute('textfield');
		PaintVars.keyFocus = tf;
		PaintVars.appStage.focus = PaintVars.keyFocus ;
		tf.selectable = true;
		tf.type = TextFieldType.INPUT;
		tf.background = true;
		tf.backgroundColor =getColorContrast();
		PaintVars.keyFocus = getAttribute('textfield');
		tf.addEventListener(Event.CHANGE, textChanged);
		render();
	}

	private function textChanged(evt:Event):void {
		if (!PaintVars.keyFocus) return;
		evt.preventDefault();
		evt.stopPropagation();
		var tf:TextField = PaintVars.keyFocus;
		var po:PaintObject = tf.parent as PaintObject;
		if (!po) return;
		po.setAttribute('textContent',tf.text);
		render();
		// PaintVars.recordForUndo();
		PaintVars.svgroot.selectorGroup.updateFrame(po);
	}

	public function spot():PaintObject{
		var	odata:PaintObject =new PaintObject('circle', 'textanchor');
		var attri:Object = {'cx': 2, 'cy': 2, 'r': 4, 'opacity': 0.6,
			'fill': 0xff00, 'stroke': 0xff, 'stroke-width': 2};
		for (var val:String in attri) odata.setAttribute(val, attri[val]);
		return odata;
	}

	private function getTextAligment():String {
		switch (getAttribute('text-anchor')) {
			case 'start': return TextFormatAlign.LEFT;
			case 'middle': return TextFormatAlign.CENTER;
			case 'end ':return TextFormatAlign.RIGHT;
			default: return TextFormatAlign.CENTER;
		}
	}

	private function getTextAutosize():String {
		switch (getAttribute('text-anchor')) {
			case 'start':return TextFieldAutoSize.LEFT;
			case 'middle': return TextFieldAutoSize.CENTER;
			case 'end ':return TextFieldAutoSize.RIGHT;
			default: return TextFieldAutoSize.CENTER;
		}
	}

	//////////////////////////////
	// Image Loader
	//////////////////////////////

	public function uploadImage():void {
		setAttribute('container', this);
		var imgstr:String = getAttribute('http://www.w3.org/1999/xlink::href');
		var data:String = imgstr.slice(imgstr.indexOf(',') + 1);
		var bytes:ByteArray = Base64Encoder.decode(data);
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, showImage);
		loader.loadBytes(bytes);
	}

	private function showImage(e:Event):void {
		var src:BitmapData = new BitmapData(e.target.content.width, e.target.content.height);
		src.draw(e.target.content);
		setAttribute('bitmapdata', src);
		var bmp:Bitmap = new Bitmap(src);
		setAttribute('bitmap', bmp);
		setAttribute('container', this);
		addChild(bmp);
		render();
	}

	public function setImageSrc():void {
		if (getAttribute('http://www.w3.org/1999/xlink::href')) uploadImage();
		else if (getAttribute('bitmapdata')) cloneImage();
	}

	public function cloneImage():void {
		var src:BitmapData = getAttribute('bitmapdata').clone();
		setAttribute('bitmapdata', src);
		var bmp:Bitmap = new Bitmap(src);
		setAttribute('bitmap', bmp);
		setAttribute('container', this);
		addChild(bmp);
		render();
	}

	////////////////////////////////////////
	// Clip Management
	///////////////////////////////////////

	public function clipImage(svg:SVGData):void {
		svg.id = PaintVars.svgroot.getIdFor('mask');
		svg.setAttribute('points', this.getClipPoints(svg.getAttribute('points')));
		svg.setAttribute('fill', 0xFF0000);
		this.setAttribute('clip-path', svg);
		insertMask();
	}

}}
