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
 Data structues for SVG Objects

*/

package ui.paintui {

	import flash.events.MouseEvent;	
	import util.Color;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.display.GradientType;
	import flash.display.CapsStyle;	
	import flash.display.JointStyle;	
	import flash.text.*;
	import spark.primitives.Graphic;
	import spark.primitives.Rect;

public class SVGData{

//////////////////////////////////////////
//SVG Object
/////////////////////////////////////////

	public var tagName:String;
	public var id:String;
	public var attributes:Object;
//	public var attr:Object;  //  scale matrix data
//	public var matrixdata:Object;
//	public var scaleMatrix:Matrix;
	
	public function SVGData(type:String, uniqueId:String) {
		tagName=type;
		id = uniqueId;
		attributes ={"angle": 0, "scalex": 1, "scaley": 1,  "opacity": 1}; // set the must have defaults
		}

public function cloneSVG():SVGData{
	var newsvg:SVGData = new SVGData(this.tagName, this.id)
	for (var key:String in this.attributes) newsvg.setAttribute (key, cloneType(this.getAttribute(key)));
	return newsvg;
}

public function cloneType(obj:*):*{
 	if (obj is Array) return cloneArray (obj);
 	if (obj is SVGData) return (obj as SVGData).cloneSVG();
 	return obj;
}

public function cloneArray(list:Array):Array {
	var res:Array = [];
	for (var i:int = 0; i < list.length; i++){
		var elem:* = list[i];
		if (elem is Array) elem = cloneArray(elem);
		if (elem is Point) elem = elem.clone();
		res.push(elem);
	}
	return res;
}

public function getScaleMatrix():Matrix{ 
	var m:Matrix =  new Matrix();
	m.scale(attributes['scalex'], attributes['scaley']);	
	return m;
}

public function getCombinedMatrix():Matrix{
	var m:Matrix = getScaleMatrix();
	m.concat (getSimpleRotation());
	return m;
}

	public function getSimpleRotation():Matrix{
		var pt:Point = getBoxCenter();
		pt = getScaleMatrix().transformPoint(pt);
		var mtx:Matrix = new Matrix();
		mtx.identity();
		if (getAttribute("angle") == 0) return mtx;
		mtx.translate(-1*pt.x, -1*pt.y);
		mtx.rotate(getAttribute("angle")*Turtle.DEGTOR);
		mtx.translate(pt.x, pt.y);
		return mtx;
	}
	
	public function hasNoMatrices():Boolean {
		if (getAttribute("angle") != 0) return false;
		if (getAttribute("scalex") != 1) return false;
		if (getAttribute("scaley") != 1) return false;
		return true;
	}

	public function setAttribute(key:String , val:*):void { attributes[key] = val }
	public function getAttribute(key:String):* { return attributes[key] }

	public function getBoxCenter():Point{
	 var box:Rectangle = getBox();
	 return new Point(box.x + box.width / 2, box.y + box.height / 2);
	}

	public function getBoxCenterDelta(m:Matrix):Point{
		var center:Point = getBoxCenter();
		var rot:Matrix = getSimpleRotation();
		center = m.transformPoint(center);
		var c:Point = new Point(center.x, center.y);
		center =rot.transformPoint(center);
		return xPoint.vdiff(center,c);	
		}

public function getClipCenterDelta(m:Matrix):Point{
	var svg:SVGData = getAttribute("clip-path");
	var center:Point = svg.getBoxCenter();
	var pt:Point = m.transformPoint(center);
	var c:Point = new Point(pt.x, pt.y);
	var rot:Matrix = new Matrix();
	rot.identity();
	if (getAttribute("angle") != 0) {
			rot.translate(-1*center.x, -1*center.y);
			rot.rotate(getAttribute("angle")*Turtle.DEGTOR);
			rot.translate(center.x, center.y);
	}
	pt =rot.transformPoint(pt);
	return xPoint.vdiff(pt,c);	
}

public function updateClipPath(mtx:Matrix, svg:SVGData):void {
	switch (svg.tagName){
	case "rect":
		svg.recreateRect(mtx);
		break;
	case "ellipse":
		svg.recreateEllipse(mtx);
		break;
	case "polygon":
	case "path":
		svg.resizePath(mtx);
		break;
	}
}

/////////////////////////////////////////////////
// scaled rendering to a bitmap
////////////////////////////////////////////////

	public function scaledBitmap(scale:Number):BitmapData {
		var box:Rectangle = fullBox();
		var w:int = Math.max(Math.ceil(scale * box.width), 1);
		var h:int = Math.max(Math.ceil(scale * box.height), 1);
		w = Math.min(Math.max(w, 1), 2000);
		h = Math.min(Math.max(h, 1), 2000);
		var svgs:Array = [this];
		var bitmap:BitmapData = new BitmapData(w, h, true, 0);
		var scaledSVGs:Array = getScaledClones(svgs, scale);
		drawSVGs(scaledSVGs, bitmap);
		return bitmap;
	}

	private function fullBox():Rectangle {
		// Return the bounding box for this SVGData object.
		// If it is a group ('g') then return the bounding box for all it's children
		if (tagName != 'g') return getBox();
		var minX:int, minY:int, maxX:int, maxY:int;
		for each (var svg:SVGData in getAttribute('children')) {
			var r:Rectangle = svg.getBox();
			minX = Math.min(minX, r.left);
			minY = Math.min(minY, r.top);
			maxX = Math.max(maxX, r.right);
			maxY = Math.max(maxY, r.bottom);
		}
		return new Rectangle(minX, minY, (maxX - minX), (maxY - minY));
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

	private function drawSVGs(svgs:Array, bitmap:BitmapData):void{
		for each (var svg:SVGData in svgs) {
			if (svg.tagName == "g") drawSVGs(svg.getAttribute("children"), bitmap);
			else svg.stamp(bitmap);
		}
	}

//////////////////////////////////////////////
//  Bounding Box for any object
//////////////////////////////////////////////

	private var dispatchGetBox:Object = {'ellipse': getEllipseBox, "rect": getRectBox, 
			"path": getPathBox, "polygon": getPolygonBox, "g": getGroupBox, "text": getTextBox,
			"image": getImageBox,  "circle": getCircleBox,  "polyline": getPolygonBox
				};
				
	public function getBox():Rectangle{
		var fcn:Function = (dispatchGetBox[tagName] as Function);
		if (fcn == null)  {
			trace("I don't know how to calculate box for", id);
			return new Rectangle();
			}
		else return(dispatchGetBox[tagName] as Function).apply(null, []);
	}

	private function getImageBox():Rectangle{
		var box:Rectangle =  new Rectangle();
		box.x = getAttribute ('x');
		box.y = getAttribute ('y');
		box.width = getAttribute ('bitmapdata').width; //+ getAttribute ('font-size') / 4;
		box.height = getAttribute ('bitmapdata').height;
		return box;
	}
	
	private function getTextBox():Rectangle{
		var box:Rectangle =  new Rectangle();
		box.x = getAttribute ('textfield').x;
		box.y = getAttribute ('y');
		box.width = getAttribute ('textfield').width; //+ getAttribute ('font-size') / 4;
		box.height = getAttribute ('textfield').height;
		return box;
	}

	private function getEllipseBox():Rectangle{
		var box:Rectangle =  new Rectangle();
		box.x = getAttribute ('cx') - getAttribute ('rx');
		box.y = getAttribute ('cy') - getAttribute ('ry');
		box.width = getAttribute ('rx') * 2;
		box.height = getAttribute ('ry') * 2;
		return box;
	}

	private function getCircleBox():Rectangle{
		var box:Rectangle =  new Rectangle();
		box.x = getAttribute ('cx') - getAttribute ('r');
		box.y = getAttribute ('cy') - getAttribute ('r');
		box.width = getAttribute ('r') * 2;
		box.height = getAttribute ('r') * 2;
		return box;
	}

	private function getGroupBox():Rectangle{
		var list:Array = getAttribute("children");
		var box:Rectangle = new Rectangle();
		for (var j:int=0; j < list.length; j++)  box =box.union((list[j] as SVGData).getTransformedBox());
		return box;
	}

	private function getRectBox():Rectangle{
		var box:Rectangle =  new Rectangle();
		box.x = getAttribute ("x");
		box.y = getAttribute ("y");
		box.width = getAttribute ("width");
		box.height = getAttribute ("height");
		return box;
	}

	private function getPathBox():Rectangle{
		var list:Array = getAttribute("points");
		if (!list) return getCommandsBox();
		else return getMinMaxFromPoints (list);
	}

	private function getCommandsBox():Rectangle{ 
		var list:Array = getAttribute("commands"); 
		if (!list) {
			trace(id, "doesn't have commands");
			return new Rectangle();
		}
		var sh:Shape = new Shape();
		var g:Graphics = sh.graphics;
		var mpoints:Array = getCommandsPoints(list, g);
		return getMinMaxFromPoints(mpoints);
	}

	private function getMinMaxFromPoints(list:Array):Rectangle{
		var box:Rectangle =  new Rectangle();
		if (list.length < 1) return box;
		var minx:Number = 9999999;
		var miny:Number = 9999999;
		var maxx:Number = -9999999;
		var maxy:Number = -9999999;
		for (var i:int = 0; i < list.length; i++) {
			if (list[i].x < minx) minx = list[i].x;
			if (list[i].x > maxx) maxx = list[i].x;
			if (list[i].y < miny) miny = list[i].y;
			if (list[i].y > maxy) maxy = list[i].y;
			}
		box.x = minx;
		box.y = miny;
		box.width = maxx - minx;
		box.height =maxy - miny;
		return box;
	}

	private function getPolygonBox():Rectangle{
		return getMinMaxFromPoints(getAttribute("points"));
	}

	public function getTransformedBox():Rectangle{
		var m:Matrix = getScaleMatrix();
		var box:Rectangle = getBox();
		var p:Point = m.transformPoint(new Point(box.x, box.y));
		box.width= Math.abs(box.width*m.a);
		box.height= Math.abs(box.height*m.d);
		box.x=  p.x;
		box.y = p.y;
		if (m.a < 0) box.x -= box.width;
		if (m.d < 0)  box.y -= box.height;
		if (getAttribute("angle") != 0) {
			var rot:Matrix = getSimpleRotation();
			var minx:Number = 9999999;
			var miny:Number = 9999999;
			var maxx:Number = -9999999;
			var maxy:Number = -9999999;	
			var list:Array = [];
			list.push(rot.transformPoint(new Point(box.x, box.y)));
			list.push(rot.transformPoint(new Point(box.x+box.width, box.y)));
			list.push(rot.transformPoint(new Point(box.x+box.width, box.y + box.height)));
			list.push(rot.transformPoint(new Point(box.x, box.y + box.height)));
			box =getMinMaxFromPoints(list);
			}
		return box;
	}

///////////////////////////////////////////////////////
// Transformations
//////////////////////////////////////////////////////

public function adjustCenter(m:Matrix):void{
	switch (tagName){
		case "image":  
			var box:Rectangle =  getBox();
			var c:Point = new Point (box.x + box.width / 2, box.y + box.height / 2);	
			var p:Point = m.transformPoint(c);	
			p.x -= (box.width / 2);
			p.y -= (box.height / 2);
			var svgdata:Object = {'x': p.x, 'y': p.y};
			for (var val:String in svgdata)  setAttribute(val, svgdata[val]);
			break;
	}
}

public function translateTo(p:Point):void{
	switch (tagName){
		case "text":  
		case "image":  
		case "rect":
			var m:Matrix =  getScaleMatrix();
			m.invert();	
			p = m.transformPoint(p);
			setAttribute('x',  getAttribute("x") + p.x);
			setAttribute('y',  getAttribute("y") + p.y);
			break;
		case "ellipse":
		case "circle": 
			setAttribute('cx',  getAttribute("cx") + p.x);
			setAttribute('cy',  getAttribute("cy") + p.y);
			break;
		case "polygon":
		case "path":
			translatePath(p); 
			break;
	}
}

public function translatePath(pt:Point):void{
	var mtx:Matrix = new Matrix();
	mtx.identity();
	mtx.translate(pt.x, pt.y);
	if (getAttribute("points"))	 setAttribute("points", convertPoints(mtx));
	else setAttribute("commands", convertCommands(mtx));
}

public function applyMatrix(m:Matrix):void{ // eliminates the object matrices -scale and rotation-
	var mtx:Matrix = getScaleMatrix();
	mtx.concat (getSimpleRotation());
	mtx.concat (m);
	if (getAttribute("points"))	 setAttribute("points", convertPoints(mtx));
	else setAttribute("commands", convertCommands(mtx));
	setAttribute('angle', 0);
}

public function resizePath(mtx:Matrix):void { // keeps the rotation of the element
	var delta:Point = getBoxCenterDelta(mtx);
	if (getAttribute("points"))	 setAttribute("points", convertPoints(mtx));
	else setAttribute("commands", convertCommands(mtx));
	translatePath(delta);
	}

public function convertPoints(mtx:Matrix):Array {
	var newpts:Array = [];
	var list:Array = getAttribute("points");
	for (var j:int = 0; j < list.length; j++) {
		var pt:Point =  mtx.transformPoint(list[j]);
		newpts.push (pt);
	}
	return newpts;
}

public function convertCommands(mtx:Matrix):Array{
	var plist:Array = []
	var list:Array = getAttribute("commands");
	for (var j:int = 0; j < list.length; j++) {
		var cmd:Array= list[j];
		for (var i:int = 1; i < cmd.length;i++){
			if (cmd[i] is Point) cmd[i] =  mtx.transformPoint(cmd[i] as Point);
			else 	if (cmd[i] is Number) cmd[i] = transformNumber(cmd, mtx);
			}
		plist.push(cmd);
		}
	return plist;
}
	
private function transformNumber(cmd:Array, mtx:Matrix):Number{
	var pt:Point;
	if (cmd[0].toLowerCase()  == "h") pt = new Point (cmd[1], 0);
	else pt=  new Point (0, cmd[1]);
	pt  =  mtx.transformPoint(pt);
	if (cmd[0].toLowerCase()  == "h") return pt.x ;
	else  return pt.y ;
}

public function recreateRect(m:Matrix):void{
	var w:Number =getAttribute('width'); 	var h:Number = getAttribute('height');
	var dx:Number = getAttribute('x'); 	var dy:Number = getAttribute('y');
	var cx:Number = dx + Math.floor (w / 2); var cy:Number =  dy + Math.floor (h / 2);
	var mtx:Matrix = m.clone();
	mtx.concat (getSimpleRotation()); 
	var pt:Point =   mtx.transformPoint(new Point(cx, cy));
	w =  Math.abs (w*m.a);	h = Math.abs (h *m.d);
	pt.x -= Math.floor (w/ 2);	pt.y -=Math.floor (h / 2);
	var p:Point = new Point (pt.x - getAttribute("x"), pt.y - getAttribute("y"));
	var svgdata:Object = {'width': w, 'height': h, 'x': pt.x, 'y': pt.y};
	for (var val:String in svgdata) setAttribute(val, svgdata[val]);
}	

public function recreateEllipse(m:Matrix):void{
	var rx:Number = getAttribute('rx');	var ry:Number = getAttribute('ry');
	var cx:Number =getAttribute('cx');	var cy:Number = getAttribute('cy');
	var mtx:Matrix = m.clone();
	mtx.concat (getSimpleRotation()); 
	var p:Point =   mtx.transformPoint(new Point(cx, cy));
	var svgdata:Object  = {'rx': Math.abs (rx*m.a), 'ry': Math.abs(ry*m.d), 'cx': p.x, 'cy': p.y};
	for (var val:String in svgdata) setAttribute(val, svgdata[val]);
	}			

public function resizeImageRect (m:Matrix):void{
	var sm:Matrix = getScaleMatrix();
	var cm:Matrix = m.clone();
	cm.concat (sm); // get scale / tx matrix: sm is the scale, m is the resize mtrx(scale + translate)
	var mtx:Matrix = new Matrix();
	var delta:Point = getBoxCenterDelta(cm); // finds the delta due to rotation
	mtx.scale(cm.a, cm.d);		
	mtx.invert();
	var coors:Point = new Point (getAttribute('x'), getAttribute('y'));
	delta = mtx.transformPoint(delta); // "divides" by the matrix that will be applied
 	var pt:Point = cm.transformPoint(coors);
 	pt = mtx.transformPoint(pt);
 	pt = xPoint.vsum(pt, delta);
	var p:Point = new Point (pt.x - getAttribute("x"), pt.y - getAttribute("y"));
	setAttribute('x', pt.x);
	setAttribute('y', pt.y);
	setAttribute('scalex', cm.a);
	setAttribute('scaley', cm.d);
	if (getAttribute("clip-path")) getAttribute("clip-path").translateTo(p);
}

public function skewImageRect (m:Matrix):void {
// in the skew you have ouside matrix 
// this function eliminates the skew 
// but keeps the center and scale
// Not your standar skew -- but effective
	var skew:Matrix = getScaleMatrix();
	skew.concat (getSimpleRotation())
	skew.concat (m)
	
	var coors:Point = new Point (getAttribute("x"), getAttribute("y"));

  var cm:Matrix = getScaleMatrix();
	cm.concat (m); // get scale / tx matrix: sm is the scale, m is the resize mtrx(scale + translate)
	var mtx:Matrix = new Matrix();
	mtx.scale(cm.a, cm.d);		
	mtx.invert();
	
	// grab center and get the screen coordinate and then divide it by the scale of the object
	var c:Point = getBoxCenter();
	var center:Point =  skew.transformPoint(c);
	center = mtx.transformPoint(center);	

	// calculate the top left corner by the center
	// and get a prelimiary top left
	var box:Rectangle = getBox();
	var pt:Point = new Point (center.x - box.width, center.y - box.height);
	setAttribute('x', pt.x);
	setAttribute('y', pt.y);
	setAttribute('scalex', cm.a);
	setAttribute('scaley', cm.d);
	
	// get the new center compare it with the "correct" one and add
	// the displacment for the top left corner
	var c2:Point = getBoxCenter();
	var delta:Point = xPoint.vdiff(center, c2);
 	pt = xPoint.vsum(pt, delta);
	setAttribute('x', pt.x);
	setAttribute('y', pt.y);
	if (getAttribute("clip-path")) getAttribute("clip-path").translateTo(xPoint.vdiff(pt, coors));
}

public function applyScale(sx:Number, sy:Number):void{
	if ((getAttribute("stroke") != null) && (getAttribute("stroke") != "none")) setAttribute("stroke-width", getAttribute("stroke-width") * Math.max(sx, sy));
	var m:Matrix =  new Matrix();
	m.scale(sx, sy);	
	switch (tagName){
		case "image":
			resizeImageRect(m);
			break;
		case "rect":
			recreateRect(m);
			break;
		case "ellipse":
			recreateEllipse(m);
			break;
		case "path":
		case "polygon":
			resizePath(m);
			break;
		}
}

public function scaleCostume(scale:Number):void{
	if ((getAttribute("stroke") != null) && (getAttribute("stroke") != "none")) setAttribute("stroke-width", getAttribute("stroke-width") * scale);
	var box:Rectangle = getBox();
	var tl:Point = new Point (box.x, box.y);
	var mtx:Matrix =  new Matrix();
	mtx.identity();
	mtx.scale(scale, scale);
	var delta:Point = getBoxCenterDelta(mtx); // finds the delta due to rotation
	switch (tagName){
		case "text":
			setAttribute('scalex', scale);
			setAttribute('scaley', scale);
			break;
		case "image":
			var sm:Matrix = getScaleMatrix();
			var cm:Matrix = mtx.clone();
			cm.concat (sm); 
			setAttribute('scalex', cm.a);
			setAttribute('scaley', cm.d);
			break;
		case "rect":
			recreateRect(mtx);	
			if (getAttribute("clip-path")) updateClipPath(mtx, getAttribute("clip-path"));
			break;
		case "ellipse":
			recreateEllipse(mtx);
			if (getAttribute("clip-path")) updateClipPath(mtx, getAttribute("clip-path"));
		break;
		case "path":
		case "polygon":
			resizePath(mtx);
			if (getAttribute("clip-path")) updateClipPath(mtx, getAttribute("clip-path"));
			break;
		}
	if (tagName != "image") translateTo(xPoint.vneg(delta));
}

/*
	var sm:Matrix = getScaleMatrix();
	var cm:Matrix = m.clone();
	cm.concat (sm); // get scale / tx matrix: sm is the scale, m is the resize mtrx(scale + translate)
	var mtx:Matrix = new Matrix();
	var delta:Point = getBoxCenterDelta(cm); // finds the delta due to rotation
	mtx.scale(cm.a, cm.d);		
	mtx.invert();
	var coors:Point = new Point (getAttribute('x'), getAttribute('y'));
	delta = mtx.transformPoint(delta); // "divides" by the matrix that will be applied
 	var pt:Point = cm.transformPoint(coors);
 	pt = mtx.transformPoint(pt);
 	pt = xPoint.vsum(pt, delta);
	var p:Point = new Point (pt.x - getAttribute("x"), pt.y - getAttribute("y"));
	setAttribute('x', pt.x);
	setAttribute('y', pt.y);
	setAttribute('scalex', cm.a);
	setAttribute('scaley', cm.d);
	if (getAttribute("clip-path")) getAttribute("clip-path").translateTo(p);

*/

public function rotateFromPoint(m:Matrix, angle:Number):void {
		var c:Point, p:Point, delta:Point;
		switch (tagName) {
		case 'ellipse':
			var cx:Number = getAttribute('cx');	var cy:Number = getAttribute('cy');
			// calculate center when rotated	
			p = m.transformPoint(new Point(cx, cy));	
			var svgdata:Object = {'cx': p.x, 'cy': p.y };
			for (var val:String in svgdata)  setAttribute(val, svgdata[val]);
 			setAttribute("angle", angle +   getAttribute("angle"));
			break;
		case "rect":
		case "image":
			var cmtx:Matrix = getScaleMatrix();
			cmtx.concat (getSimpleRotation())
			cmtx.concat (m);
			
			var mtx:Matrix = getScaleMatrix();
			mtx.invert();

			var coors:Point = new Point (getAttribute("x"), getAttribute("y"));
	
			// grab center and get the screen coordinate and then divide it by the scale of the object
			c = getBoxCenter();
			var center:Point = cmtx.transformPoint(c);
			center = mtx.transformPoint(center);	
			// calculate the top left corner by the center
			// and get a prelimiary top left
			var box:Rectangle = getBox();
			var pt:Point = new Point (center.x - box.width, center.y - box.height);
			setAttribute('x', pt.x);
			setAttribute('y', pt.y);
	
			setAttribute("angle", angle +   getAttribute("angle"));

			// get the new center compare it with the "correct" one and add
			// the displacment for the top left corner
			var c2:Point = getBoxCenter();
			delta = xPoint.vdiff(center, c2);
			pt = xPoint.vsum(pt, delta);
			setAttribute('x', pt.x);
			setAttribute('y', pt.y);
			if (getAttribute("clip-path")) getAttribute("clip-path").translateTo(xPoint.vdiff(pt, coors));
 			break;
 		case "polygon":
		case 'path':
			c = getBoxCenter();
			p = m.transformPoint(c);
			delta = xPoint.vdiff(p, c);
			translatePath(delta);
			setAttribute("angle", angle +   getAttribute("angle"));
			break;
		}
}

///////////////////////////////////////////////////////////
// Object color and rendering data
//////////////////////////////////////////////////////////

public function getWidth():Number { return getBox().width }

public function getHeight():Number { return getBox().height }

public function getTx():Number { return getBox().x }

public function getTy():Number { return getBox().y }

public function applyMatrixToGradient(a:Number):void {
// not perfect but acceptable
	var zero:Number = 1e-14;
	var pt:Point, mtx:Matrix;
	var grad:Object = getAttribute("fill");
	switch(grad.type){
		case GradientType.LINEAR: 
			var startPt:Point = new Point(grad.x1, grad.y1);
			var endPt:Point = new Point(grad.x2, grad.y2);
			pt = new Point(0.5, 0.5);
			mtx = new Matrix();
			mtx.identity();
			mtx.translate(-1*pt.x, -1*pt.y);
			mtx.rotate(a*Turtle.DEGTOR);
			mtx.translate(pt.x, pt.y);
			startPt = mtx.transformPoint(startPt);
			endPt = mtx.transformPoint(endPt);	
			grad.x1 = nearest(startPt.x);
			grad.y1 = nearest(startPt.y);
			grad.x2 = nearest(endPt.x);
			grad.y2 = nearest(endPt.y);
			break;
		case GradientType.RADIAL: 
			var cpt:Point = new Point(grad.cx, grad.cy)
			var fpt:Point = new Point(grad.fx, grad.fy)
			pt = new Point(0.5, 0.5);
			mtx = new Matrix();
			mtx.identity();
			mtx.translate(-1*pt.x, -1*pt.y);
			mtx.rotate(a*Turtle.DEGTOR);
			mtx.translate(pt.x, pt.y);
			cpt = mtx.transformPoint(cpt);
			fpt = mtx.transformPoint(fpt);	
			grad.cx = nearest(cpt.x);
			grad.cy = nearest(cpt.y);
			grad.fx = nearest(fpt.x);
			grad.fy = nearest(fpt.y);
			break;
		}	
}

public function nearest	(n:Number):Number{
	var zero:Number = 1e-14;
	if (Math.abs(n) < zero) return 0;
	if ((Math.abs(n - 1) < zero) && (Math.abs(n - 1) <= 1)) return 1;
	return n;
}

public function setGradientUnits():void {
	var grad:Object = getAttribute("fill");
	if (grad.transform && (grad.transform is Matrix)) {
		switch(grad.type){
			case GradientType.LINEAR: 
				var startPt:Point = (grad.transform as Matrix).transformPoint(new Point(grad.x1, grad.y1));
				var endPt:Point = (grad.transform as Matrix).transformPoint(new Point(grad.x2, grad.y2));
				grad.x1 = startPt.x;
				grad.y1 = startPt.y;
				grad.x2 = endPt.x;
				grad.y2 = endPt.y;
				break;
			case GradientType.RADIAL: 
				var cpt:Point = (grad.transform as Matrix).transformPoint(new Point(grad.cx, grad.cy));
				var fpt:Point = (grad.transform as Matrix).transformPoint(new Point(grad.fx, grad.fy));
				grad.cx = cpt.x;
				grad.cy = cpt.y;
				grad.fx = fpt.x;
				grad.fy = fpt.y;
				break;
		}	
	grad.transform = null;
	}
	if (grad.gradientUnits == "userSpaceOnUse") {
		switch(grad.type){
			case GradientType.LINEAR: 
				grad.x1 = (grad.x1 - getTx()) / getWidth();
				grad.x2 = (grad.x2 - getTx()) / getWidth();
				grad.y1 = (grad.y1 - getTy())/ getHeight();
				grad.y2 = (grad.y2 - getTy())/ getHeight();
				break;
			case GradientType.RADIAL: 
				grad.cx = (grad.cx - getTx()) / getWidth();
				grad.fx = (grad.fx - getTx()) / getWidth();
				grad.cy = (grad.cy - getTy())/ getHeight();
				grad.fy = (grad.fy - getTy())/ getHeight();
				break;
			}
		grad.gradientUnits == "objectBoundingBox"
		}
}

////////////////////////////////////////////////////
//
// Rendering functions for Editor and for Costume
//
////////////////////////////////////////////////////
	public var curves:Array=[];
	public var endp:Point;
	public var startp:Point;
	private	static var curveoptions:Array =['C', 'c', 's', 'S'];
	private	static var qcurveoptions:Array =['Q', 'q', 'T', 't'];
	public var acurve:Boolean = false;
	private var aqcurve:Boolean = false;
	private var lastcxy:Point;
	public var tolerance:Number = 1;

////////////////////////////////////////////////
// Bitmap Data rendering
////////////////////////////////////////////////

public function stamp(tmp:BitmapData):void{
	var m:Matrix = getCombinedMatrix(), tm:Matrix;
	switch (tagName){
		case "image":
			var bd:BitmapData = getAttribute("bitmapdata").clone();
			var img:Sprite = getClippedImage(bd, m);
			tm = new Matrix();
			tmp.draw(img, m);
			bd.dispose();
			break;
		case "text":
			changeFormat();
			tm = new Matrix();
			tm.translate(attributes["x"],attributes["y"]);
			tm.concat (m);
			tmp.draw(attributes["textfield"], tm);
			break;
		default:
			var sh:Sprite = new Sprite();
			var g:Graphics = sh.graphics;
			render (g);
			if ( getAttribute("clip-path")) {
				var cp:SVGData= getAttribute ("clip-path");
				sh.mask = new Shape();
				sh.addChild(sh.mask);
				cp.render(Shape(sh.mask).graphics);
			};
			tmp.draw(sh, m);	
			break;
		}
}
	
private function getClippedImage(bd:BitmapData, m:Matrix):Sprite{
	var spr:Sprite = new Sprite();
 	var bmp:Bitmap = new Bitmap(bd);
 	spr.addChild(bmp);
 	bmp.x = attributes["x"];
 	bmp.y = attributes["y"];
	var g:Graphics =spr.graphics;	
	if (getAttribute("clip-path")) {
		var cp:SVGData= getAttribute ("clip-path");
		spr.mask = new Shape();
		spr.addChild(spr.mask);
		cp.render(Shape(spr.mask).graphics);
		}
	return spr;
}

public function getCommandsPoints(list:Array, g:Graphics):Array{ 
	endp = new Point();
	startp = endp;
	acurve = false;
	aqcurve = false;
	var mpoints:Array = []
	for (var i:int =0 ; i < list.length; i++)  {
		drawCommand(g, list[i]);
		mpoints.push(endp);
		}
	return mpoints;
}

public function getJointStyle():String{
	switch (tagName){
		case "polygon":  return JointStyle.MITER;
		case "rect":  return JointStyle.MITER;
		case "polyline":  return JointStyle.MITER;
		default: return JointStyle.ROUND	;
	}
}

public function render(g:Graphics):void{
	g.clear(); 
	prepareGraphics(g);
	switch (tagName){
		case "image":
			var img:Bitmap = getAttribute ("bitmap");
			img.x = attributes["x"]; 
			img.y= attributes["y"];
			break;
		case "text":
			changeFormat();
			break;
		case "rect":
			g.drawRect(attributes["x"],attributes["y"],attributes["width"], attributes["height"]);
			break;
		case "ellipse":
			g.drawEllipse(attributes["cx"] - attributes["rx"],attributes["cy"] - attributes["ry"],getWidth(),getHeight());
			break;
		case "circle":
			g.drawCircle(attributes["cx"],attributes["cy"],attributes["r"]);
			break;
		case "polygon":
			drawStraightLines(g);
			break;
		case "path":
			renderPath(g);
			break;
		case "polyline":
			var pl:Array = attributes["points"];
			if (pl.length < 2) return;
			var p:Point = pl[0];
			g.moveTo(p.x, p.y);
			for (var i:int =1; i < pl.length; i++) g.lineTo(pl[i].x, pl[i].y);
			break;
		}
	if (fillState() && !needsTwoPasses()) g.endFill();
}

private function changeFormat():void{
	var tf:TextField = getAttribute("textfield");
	var fmt:TextFormat = new TextFormat(getAttribute("font-family"), getAttribute("font-size"), 
																			getAttribute("fill"), getAttribute("font-weight") =="bold",
																			getAttribute("font-style")== "italic");
	tf.defaultTextFormat = fmt;
	tf.setTextFormat(fmt);
	getAttribute('textfield').x = getAttribute("x");
	getAttribute('textfield').y = getAttribute("y");
}

//////////////////////////////////////////////////////
//  Path Drawing 
/////////////////////////////////////////////////////

private function renderPath(g:Graphics):void {
	switch (getAttribute("kind")){
		case "editable":
			acurve = false;
			drawBezierPoints(g);
			if (needsTwoPasses()) {  // flash needs to have separate draw if the path is open
				g.endFill();		// otherwise it draws a close path
				setLineStyle(g);			
				acurve = false;
				drawBezierPoints(g);
			}
			break;
		default: 
			drawCommands(g); 
			break;
	}
}

public function drawCommands(g:Graphics):void{
	var list:Array = getAttribute("commands"); 
	endp = new Point();
	startp = endp;
	acurve = false;
	aqcurve = false;
	for (var i:int =0 ; i < list.length; i++)  drawCommand(g, list[i]);
}

///////////////////////////////////////////////////////////
// Object color and rendering data
//////////////////////////////////////////////////////////
	
public function setLineStyle(g:Graphics):void {
	if (attributes["stroke-width"] == undefined) attributes["stroke-width"] = 1;
	g.lineStyle(attributes["stroke-width"],attributes["stroke"],attributes["opacity"],true,
			"normal", CapsStyle.ROUND, getJointStyle());	
}		
	
public function pathIsOpen():Boolean{
	if (getAttribute("kind") != "editable") return false;
	var list:Array = getAttribute("points");
	var first:Point = list[0];
	var lastpoint:Point = list[list.length-1];
	return xPoint.vlen(xPoint.vdiff(lastpoint,first)) >= 10;
}

public function needsTwoPasses():Boolean{
	if (tagName != "path") return false;	
	if ((getAttribute("stroke") == "none") || (getAttribute("fill") == "none")) return false;
	return pathIsOpen();
}

public function prepareGraphics(g:Graphics):void{
	var fd:* = fillState();
	var opacity:Number = attributes["opacity"];
	if (fd != null){
		if (fd is Number) g.beginFill(fd, opacity);
		else PaintVars.setGradientFill(g,fd, getWidth(), getHeight(),getTx(),getTy());
		}
	if (needsTwoPasses()) return;  //  open paths with fill and strok need to be drawn in two steps
	if ((getAttribute("stroke") != undefined) && (getAttribute("stroke") != "none")) setLineStyle(g);
	}

private function fillState():* {
	var fd:* = getAttribute("fill");
	if (fd == undefined) fd = 0;
	if (fd == "none") return null;
	if (tagName == "polyline") return null;
	return fd;
}

////////////////////////////////////////////////////////
//  Drawing SVG path commands
////////////////////////////////////////////////////////
	
	private var dispatchDrawCmd:Object = {'M': absoulteMove, "m": relativeMove, 
	"L": absoluteLine, "l": relativeLine,	"H": absoluteHLine, "h": relativeHLine, 
	"V": absoluteVLine, "v": relativeVLine, 
	'C': absoluteCurve, 'c': relativeCurve, 'S': absoluteSmooth, 's': relativeSmooth, 
	'Q': absoluteQCurve, 'q': relativeQCurve, 'T': absoluteQSmooth, 't': relativeQSmooth, 
	"Z": closePath, "z": closePath
				};
				
					
public function drawCommand(g:Graphics,cmd:Array):void{
	(dispatchDrawCmd[cmd[0]] as Function).apply(null, [g, cmd]);
	acurve = curveoptions.indexOf(cmd[0]) > -1 ; 
	aqcurve = qcurveoptions.indexOf(cmd[0]) > -1 ; 
}

// moves
private function absoulteMove(g:Graphics,cmd:Array):void{
	endp = cmd[1];
	g.moveTo(endp.x, endp.y);
	startp = endp;
}

private function relativeMove(g:Graphics,cmd:Array):void{
	endp = xPoint.vsum(endp, cmd[1]);
	g.moveTo(endp.x, endp.y);
	startp = endp;
}

// lines
private function closePath(g:Graphics,cmd:Array):void{
 	endp =startp;
  g.lineTo(endp.x, endp.y);	
}


private function absoluteLine(g:Graphics,cmd:Array):void{
 	endp =cmd[1];
  g.lineTo(endp.x, endp.y);	
}

private function relativeLine(g:Graphics,cmd:Array):void{
  endp = xPoint.vsum(endp, cmd[1]);
  g.lineTo(endp.x, endp.y);	
}

private function absoluteHLine(g:Graphics,cmd:Array):void{
	var dx:Number = cmd[1];
 	endp = new Point(dx, endp.y);
  g.lineTo(endp.x, endp.y);	
}

private function relativeHLine(g:Graphics,cmd:Array):void{
	var dx:Number = endp.x + cmd[1];
 	endp = new Point(dx, endp.y);
  g.lineTo(endp.x, endp.y);	
}

private function absoluteVLine(g:Graphics,cmd:Array):void{
 	var dy:Number =  cmd[1];
 	endp = new Point(endp.x, dy);
  g.lineTo(endp.x, endp.y);	
}

private function relativeVLine(g:Graphics,cmd:Array):void{
 	var dy:Number = endp.y + cmd[1];
 	endp = new Point(endp.x, dy);
  g.lineTo(endp.x, endp.y);	
}

// curves
// Cubic
private function absoluteCurve(g:Graphics,cmd:Array):void{
	curves=[];
	getQuadraticBezierPoints(endp, cmd[1],cmd[2],cmd[3]);
	lastcxy = cmd[2];
	for each (var quad:Object in curves) g.curveTo(quad.c.x, quad.c.y, quad.p.x, quad.p.y);
	endp=cmd[3];
}

private function relativeCurve(g:Graphics,cmd:Array):void{
	curves=[];
	var c1:Point = xPoint.vsum(endp, cmd[1]);
	var c2:Point = xPoint.vsum(endp, cmd[2]);
	lastcxy = c2;
	var endat:Point = xPoint.vsum(endp, cmd[3]);
	getQuadraticBezierPoints(endp, c1,c2,endat);
	for each (var quad:Object in curves) g.curveTo(quad.c.x, quad.c.y, quad.p.x, quad.p.y);
	endp=endat;
}

private function absoluteSmooth(g:Graphics,cmd:Array):void{
	curves=[];
	var c1:Point = acurve ?  xPoint.vsum (endp,xPoint.vdiff(endp, lastcxy)) : endp;
	var c2:Point = cmd[1];
	getQuadraticBezierPoints(endp, c1,c2,cmd[2]);
	for each (var quad:Object in curves) g.curveTo(quad.c.x, quad.c.y, quad.p.x, quad.p.y);
	endp=cmd[2];
	lastcxy = c2;
}

private function relativeSmooth(g:Graphics,cmd:Array):void{
	curves=[];
	var c1:Point = acurve ?  xPoint.vsum (endp,xPoint.vdiff(endp, lastcxy)) : endp;
	var c2:Point = xPoint.vsum(endp, cmd[1]);
	var endat:Point = xPoint.vsum(endp, cmd[2]);
	getQuadraticBezierPoints(endp, c1,c2,endat);
	for each (var quad:Object in curves) g.curveTo(quad.c.x, quad.c.y, quad.p.x, quad.p.y);
	endp=endat;
	lastcxy = c2;
}

// 	Quadratic
private function absoluteQCurve(g:Graphics,cmd:Array):void{
	endp = cmd[2];
	g.curveTo(cmd[1].x, cmd[1].y,endp.x,endp.y);
	lastcxy = cmd[1];
}

private function relativeQCurve(g:Graphics,cmd:Array):void{
	var c1:Point = xPoint.vsum(endp, cmd[1]);
	var endp:Point = xPoint.vsum(endp, cmd[2]);
	lastcxy = c1;
	g.curveTo(c1.x, c1.y,endp.x,endp.y);
}

private function absoluteQSmooth(g:Graphics,cmd:Array):void{
	var c1:Point = aqcurve ?  xPoint.vsum (endp,xPoint.vdiff(endp, lastcxy)) : endp;
	endp = cmd[2];
	lastcxy = c1;
	g.curveTo(c1.x, c1.y,endp.x,endp.y);
}

private function relativeQSmooth(g:Graphics,cmd:Array):void{
	var c1:Point = aqcurve ?  xPoint.vsum (endp,xPoint.vdiff(endp, lastcxy)) : endp;
	var endp:Point = xPoint.vsum(endp, cmd[2]);
	lastcxy = c1;
	g.curveTo(c1.x, c1.y,endp.x,endp.y);
}

////////////////////////////////////////
// Drawing Polygon
////////////////////////////////////////
	
private function drawStraightLines(g:Graphics):void{
	var list:Array = getAttribute("points");
	var first:Point = list[0];
	g.moveTo(first.x, first.y);		
	for (var i:int = 1; i < list.length; i++) g.lineTo(list[i].x, list[i].y);
	g.lineTo(first.x, first.y);		
}

//////////////////////////////////////////////////////
// From anchorpoints to Bezier 
/////////////////////////////////////////////////////


public function drawBezierPoints(g:Graphics):void {
	var list:Array = getAttribute("points");
	var first:Point = list[0];
	g.moveTo(first.x, first.y);	
	if (list.length < 3 )	g.lineTo(list[1].x, list[1].y);
	else {
		curves=[];
		for (var i:int = 1; i < list.length - 1; i++) drawSegment(g, list[i-1], list[i], list[i+1]);
		var lastpoint:Point = list[list.length-1];
		var farilyclose:Boolean = xPoint.vlen(xPoint.vdiff(lastpoint,first)) < 10;
		if (farilyclose) drawSegment(g, list[list.length-2], lastpoint,first);
		else drawSegment(g, list[list.length-2], lastpoint,lastpoint);
		for each (var quad:Object in curves) g.curveTo(quad.c.x, quad.c.y, quad.p.x, quad.p.y);
	}	
}

// Draw segement takes 3 anchor points to draw and SVG "S" command 
// as a Cubic Bezier ("C" command in SVG) curve with:
// the first control as the flip of the last curve 2nd control point
// and the second control from the internal calculation (specific to our UI)
// the end point is the current anchor point in the loop
// (the start point is the previous point)

public function drawSegment(g:Graphics, before:Point, here:Point, after:Point):void {
	var l1:Number = xPoint.vlen(xPoint.vdiff(before, here));
	var l2:Number = xPoint.vlen(xPoint.vdiff(here, after));
	var l3:Number = xPoint.vlen(xPoint.vdiff(before, after));
	var l:Number = l3/ (l1 + l2);
	var min:Number = Math.min(l1,l2);
	//if ((l1 + l2) >  3 * l3)	l = 0;
	var endpoint:Point = xPoint.vdiff(here, before);
	var c:Point = xPoint.vscale (xPoint.controlPoint(before, here, after), l* l*min * 0.666); // needs more work on the fudge factor
	var c1:Point = acurve ?  xPoint.vsum (before,xPoint.vdiff(before, lastcxy)) : before;
	var c2:Point = xPoint.vsum (before, xPoint.vdiff(endpoint, c));
	getQuadraticBezierPoints(before, c1, c2, here);
	acurve = true;
  lastcxy = c2;
}

// functions below were take from com.lorentz.SVG.utils.Bezier
// and addapted for our purposes
private function getQuadraticBezierPoints(a:Point, b:Point, c:Point, d:Point):void{
	// find intersection between bezier arms
  var s:Point = intersect2Lines(a, b, c, d);
  if (s && !isNaN(s.x) && !isNaN(s.y)) {
		// find distance between the midpoints
		var dx:Number = (a.x + d.x + s.x * 4 - (b.x + c.x) * 3) * .125;
		var dy:Number = (a.y + d.y + s.y * 4 - (b.y + c.y) * 3) * .125;
		// split curve if the quadratic isn't close enough
		if (dx*dx + dy*dy <= tolerance*tolerance) {
		// end recursion by saving points
			curves.push({p:d,c:s});
			return;
			}
		} else {
			var mp:Point = Point.interpolate(a, d, 0.5);
			if(Point.distance(a, mp)<=tolerance){
				curves.push({p:d,c:mp});
				return;
			}
		}		
	var halves:Object = bezierSplit (a, b, c, d);
	var b0:Object = halves.b0;
	var b1:Object = halves.b1;
	// recursive call to subdivide curve
	getQuadraticBezierPoints(a, b0.b, b0.c, b0.d);
	getQuadraticBezierPoints(b1.a, b1.b, b1.c, d);
}
        
public function intersect2Lines(p1:Point, p2:Point, p3:Point, p4:Point):Point{
	var x1:Number = p1.x; var y1:Number = p1.y;
 	var x4:Number = p4.x; var y4:Number = p4.y;

 	var dx1:Number = p2.x - x1;
 	var dx2:Number = p3.x - x4;

  if (!dx1 && !dx2) return null; // new Point(NaN, NaN);

  var m1:Number = (p2.y - y1) / dx1;
  var m2:Number = (p3.y - y4) / dx2;

	if (!dx1) return new Point(x1, m2 * (x1 - x4) + y4);
  else if (!dx2) return new Point(x4, m1 * (x4 - x1) + y1);

  var xInt:Number = (-m2 * x4 + y4 + m1 * x1 - y1) / (m1 - m2);
  var yInt:Number = m1 * (xInt - x1) + y1;

	return new Point(xInt, yInt);
}

public function bezierSplit(p0:Point, p1:Point, p2:Point, p3:Point):Object{
  var p01:Point = Point.interpolate(p0, p1, 0.5);
  var p12:Point = Point.interpolate(p1, p2, 0.5);
  var p23:Point = Point.interpolate(p2, p3, 0.5);
  var p02:Point = Point.interpolate(p01, p12, 0.5);
  var p13:Point = Point.interpolate(p12, p23, 0.5);
  var p03:Point = Point.interpolate(p02, p13, 0.5);
  return {
  	b0: {a: p0,  b: p01, c: p02, d: p03},
	b1: {a: p03, b: p13, c: p23, d: p3}};
}

}}
