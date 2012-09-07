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
	import flash.geom.*;
	import flash.utils.*;

public class PaintPixels {

	private var drawLayer:Sprite;
	private var working:Sprite;
	private var outline:Sprite;

	private var offscreenCtx:BitmapData;
	private var workingCtx:BitmapData;
	private var marchingantsCtx:BitmapData;
	private var zebradelta:Point;
	private var maskcolor:uint = 0xFFFFFFFF;

	public function PaintPixels() {
		drawLayer = new Sprite();
		working = new Sprite();
		outline = new Sprite();
	}

	public function setWidthHeight(w:int, h:int):void {
		if (PaintVars.offscreen ) PaintVars.offscreen.dispose();
		PaintVars.offscreen = new BitmapData(w,h, true, 0);
		if (PaintVars.zebra) PaintVars.zebra.dispose();
		PaintVars.zebra = getZebraStripes(w,h);
	}

	/////////////////////////////////////////////
	// Zebra
	/////////////////////////////////////////////

	public function getZebraStripes(w:int, h:int):BitmapData{
		var sh:Sprite = new Sprite();
		var size:Number = Math.floor(Math.sqrt((w * w) + (h * h)));
		size = size * 2;
		var g:Graphics = sh.graphics;
		g.beginFill(0xFFffff);
		g.drawRect(0, 0, size, size);
		g.endFill();
		for (var i:int = 2; i < size; i += 8) {
			g.lineStyle(4, 0, 1, true);
			g.moveTo(i, 0);
			g.lineTo(i, size);
			g.lineStyle(4, 0xFFFFFF, 1, true);
			g.moveTo(i + 4,0);
			g.lineTo(i + 4, size);
		}
		var bmp:BitmapData = new BitmapData(w + 15, h, true, 0);
		var mtx:Matrix = new Matrix();
		var pt:Point = new Point(size / 2, size / 2);
		mtx.translate(-pt.x, -pt.y);
		mtx.rotate(45*Turtle.DEGTOR);
		bmp.draw(sh, mtx);
		return bmp;
	}

	//////////////////////////////////
	// Mouse events
	/////////////////////////////////

	public function lassoMouseDown(mt:PaintObject, mousePt:Point):void {
		var pt:Point = getOffsetPoint(mt, mousePt);
		var w:int = mt.getAttribute('width');
		var h:int = mt.getAttribute('height');

		// drawing behind the scene on a sprite for the size of the bmp
		if (workingCtx) workingCtx.dispose();
		workingCtx =new BitmapData(w,h, true, 0);	 // where the selection result will be burned
		working.graphics.clear();
		working.graphics.beginFill(0xFFFFFF)
		working.graphics.moveTo(pt.x, pt.y);

		outline.graphics.clear();
		outline.graphics.lineStyle(1,0xFF0000,1,true, 'normal', 'round');
		outline.graphics.moveTo(pt.x, pt.y);

		// drawing on screen
		var pc:PaintCanvas = PaintVars.svgroot.window.paintarea;
		pc.addChild(drawLayer);
		drawLayer.graphics.clear();
		drawLayer.graphics.lineStyle(1, (getPixelColor(mt, pt) == 0xFFFFFF) ? 0x0 : 0xFFFFFF,1,true, 'normal', 'round');
		drawLayer.graphics.moveTo(mousePt.x, mousePt.y);
	}

	public function lassoMouseMove(mt:PaintObject, p:Point):void {
		var pt:Point = getOffsetPoint(mt, p);
		working.graphics.lineTo(pt.x,pt.y);
		outline.graphics.lineTo(pt.x,pt.y);
		drawLayer.graphics.lineStyle(1, (getPixelColor(mt, pt) == 0xFFFFFF) ? 0x0 : 0xFFFFFF,1,true, 'normal', 'round');
		drawLayer.graphics.lineTo(p.x, p.y);
	}

	public function lassoMouseUp(mt:PaintObject, p:Point):void {
		drawLayer.parent.removeChild(drawLayer);
		var pt:Point = getOffsetPoint(mt, p);
		working.graphics.lineTo(pt.x,pt.y);
		working.graphics.endFill();
		outline.graphics.lineTo(pt.x,pt.y);
		var endPt:Point = getOffsetPoint(mt, PaintVars.initialPoint);
		outline.graphics.lineTo(endPt.x,endPt.y);
		drawLayer.graphics.lineTo(p.x, p.y);
		drawLayer.graphics.lineTo(PaintVars.initialPoint.x, PaintVars.initialPoint.y);
		var cnv:Object = PaintVars.svgroot.window.getCanvasWidthAndHeight();
		if (PaintVars.contour) PaintVars.contour.dispose();
		PaintVars.contour =new BitmapData(cnv.width,cnv.height, true, 0);	 // where the selection result will be burned
		workingCtx.draw(working);
		PaintVars.contour.draw(drawLayer);
		var rect:Rectangle = new Rectangle(0,0, cnv.width,cnv.height);
		PaintVars.contour.threshold(PaintVars.contour, rect, new Point(0, 0), '!=', 0, 0xFFFFFFFF);
		startMarchingAnts(PaintVars.contour, mt);
	}

	public function eraserMouseDown(mt:PaintObject, mousePt:Point):void {
		var pt:Point = getOffsetPoint(mt, mousePt);
		var w:int = mt.getAttribute('width');
		var h:int = mt.getAttribute('height');

		// drawing behind the scene on a sprite for the size of the bmp
		if (workingCtx) workingCtx.dispose();
		workingCtx =new BitmapData(w,h, true, 0);	 // where the selection result will be burned
		working.graphics.clear();
		working.graphics.lineStyle(PaintVars.strokeAttributes.strokewidth,maskcolor,1,true, 'normal', 'round');
		working.graphics.moveTo(pt.x, pt.y);
		var original:BitmapData = mt.getAttribute('bitmapdata');
		var src:BitmapData = original.clone();
		mt.setAttribute('bitmapdata', src);
		mt.getAttribute('bitmap').bitmapData = src;
	}

	public function eraserMouseMove(mt:PaintObject, p:Point):void {
		var pt:Point = getOffsetPoint(mt, p);
		working.graphics.lineTo(pt.x, pt.y);
		workingCtx.draw(working);
		var rect:Rectangle = workingCtx.getColorBoundsRect(0xFFFFFFFF, maskcolor, true);
		if (rect.isEmpty()) return;
		// creating another copy but not disposing of the old one because of Undo
		var bm:BitmapData = mt.getAttribute('bitmapdata');
		var stencil:BitmapData = new BitmapData(rect.width,rect.height, true, 0);
		stencil.copyPixels(workingCtx, rect, new Point(0, 0));
		bm.threshold(stencil, new Rectangle (0,0, rect.width,rect.height), new Point(rect.x,rect.y), '==', maskcolor, 0x00FFFFFF);
	}

	public function eraserMouseUp(mt:PaintObject, mousePt:Point):void { }

	public function selectWithWand(mt:PaintObject, mousePt:Point):void {
		var src:BitmapData = mt.getAttribute('bitmapdata');
		var pt:Point = getOffsetPoint(mt, mousePt);
		if (outsideArea(pt, src)) return;
		if (workingCtx) workingCtx.dispose();
		workingCtx =new BitmapData(src.width,src.height, true, 0); // keeps the result
		var targetcolor:uint = src.getPixel(pt.x, pt.y);
		if (PaintVars.contour) PaintVars.contour.dispose();
		PaintVars.contour = floodfill (src, pt, targetcolor, workingCtx);
		var delta:Point = new Point(mt.getAttribute('x'),mt.getAttribute('y'));
		var m:Matrix=mt.getCombinedMatrix();
		pt = new Point(delta.x ,delta.y);
		var mtx:Matrix = new Matrix();
		mtx.translate(pt.x, pt.y);
		mtx.concat(m);
		var cnv:Object = PaintVars.svgroot.window.getCanvasWidthAndHeight();
		if (marchingantsCtx) marchingantsCtx.dispose();
		marchingantsCtx =new BitmapData(cnv.width,cnv.height, true, 0); // keeps the result
		marchingantsCtx.draw(PaintVars.contour, mtx);
		if (PaintVars.contour) PaintVars.contour.dispose();
		PaintVars.contour=new BitmapData(cnv.width,cnv.height, true, 0); // keeps the result
		PaintVars.contour.draw(marchingantsCtx);
		startMarchingAnts(PaintVars.contour, mt);
	}

	public function getPixelColor(mt:PaintObject, mousePt:Point):* {
		var src:BitmapData = mt.getAttribute('bitmapdata');
		var pt:Point = getOffsetPoint(mt, mousePt);
		if (outsideArea(pt, src)) return 'none';
		if (src.getPixel32(pt.x, pt.y) == 0) return 'none';
		else return src.getPixel(pt.x, pt.y);
	}

	public function paintBucketOnImage(mt:PaintObject, mousePt:Point, fillcolor:*):void {
		var src:BitmapData = mt.getAttribute('bitmapdata');
		var pt:Point = getOffsetPoint(mt, mousePt);
		var rect:Rectangle;
		if (outsideArea(pt, src)) return;
		if (offscreenCtx) offscreenCtx.dispose();
		if (PaintVars.antsAlive() &&workingCtx ){
			rect = workingCtx.getColorBoundsRect(0xFFFFFFFF, maskcolor, true);
			offscreenCtx = fillCanvasWithSelectedColor(src.width,src.height, fillcolor, rect);
		} else {
			if (workingCtx) workingCtx.dispose();
			workingCtx =new BitmapData(src.width,src.height, true, 0);	 // where the selection result is stored
			var targetcolor:uint = src.getPixel(pt.x, pt.y);
			var paintEdges:BitmapData = floodfill (src, pt, targetcolor, workingCtx);
			paintEdges.dispose();
			offscreenCtx = fillCanvasWithSelectedColor(src.width,src.height, fillcolor, null);
		}
		rect = workingCtx.getColorBoundsRect(0xFFFFFFFF, maskcolor, true);
		if (rect.isEmpty()) return;
		var dest:BitmapData = src.clone();
		// creating another copy not disposing of the old one because of Undo
		mt.setAttribute('bitmapdata', dest);
		mt.getAttribute('bitmap').bitmapData = dest;
		setPixelsFromPatternAcordingToMask(dest,offscreenCtx, workingCtx);
		PaintVars.recordForUndo();
	}

	private function setPixelsFromPatternAcordingToMask(dest:BitmapData,src:BitmapData, maskdata:BitmapData):void {
		var rect:Rectangle = maskdata.getColorBoundsRect(0xFFFFFFFF, maskcolor, true);
		if (rect.isEmpty()) return;
		var stencil:BitmapData = new BitmapData(rect.width,rect.height, true, 0);
		stencil.copyPixels(src, rect, new Point(0, 0));
		stencil.threshold(maskdata, rect, new Point(0, 0), '==', 0, 0x00FFFFFF);
		var mtx:Matrix = new Matrix();
		mtx.translate(rect.x,rect.y);
		dest.draw(stencil, mtx);
		stencil.dispose();
	}

	public function copyBits(mt:PaintObject):BitmapData{
		var src:BitmapData = mt.getAttribute('bitmapdata');
		var rect:Rectangle = workingCtx.getColorBoundsRect(0xFFFFFFFF, maskcolor, true);
		var bm:BitmapData = new BitmapData(rect.width,rect.height, true, 0);
		bm.copyPixels(src, rect, new Point(0, 0));
		bm.threshold(workingCtx, rect, new Point(0, 0), '==', 0, 0x00FFFFFF);
		return bm;
	}

	public function getDeltaPoint():Point{
		var rect:Rectangle = workingCtx.getColorBoundsRect(0xFFFFFFFF, maskcolor, true);
		return new Point(rect.x, rect.y);
	}

	//////////////////////////////////
	// Keyboard events
	/////////////////////////////////

	public function deletePressedOnAnts(mt:PaintObject):void {
		if (mt == null) return;
		var original:BitmapData = mt.getAttribute('bitmapdata');
		var src:BitmapData = original.clone();
		var rect:Rectangle = workingCtx.getColorBoundsRect(0xFFFFFFFF, maskcolor, true);
		if (rect.isEmpty()) return;
		rect = new Rectangle(0, 0, src.width, src.height);
		src.threshold(workingCtx, rect, new Point(0, 0), '!=', 0, 0x00FFFFFF);
		// creating another copy not disposing of the old one because of Undo
		mt.setAttribute('bitmapdata', src);
		mt.getAttribute('bitmap').bitmapData = src;
	}

	//////////////////////////
	// Marching Ants
	//////////////////////////

	private function startMarchingAnts(contour:BitmapData, mt:PaintObject):void {
		var cnv:Object = PaintVars.svgroot.window.getCanvasWidthAndHeight();
		if (marchingantsCtx) marchingantsCtx.dispose();
		marchingantsCtx =new BitmapData(cnv.width,cnv.height, true, 0); // keeps the result
		var pc:PaintCanvas = PaintVars.svgroot.window.paintarea;
		PaintVars.marchingants = new Bitmap(marchingantsCtx);
		PaintVars.marchingants.x = 0;
		PaintVars.marchingants.y = 0;
		PaintVars.marchingants.name = mt.id;
		pc.addChild(PaintVars.marchingants);
		zebradelta = new Point(2,0);
		marching(contour, marchingantsCtx);
		PaintVars.intervalId = setInterval(function():void { marching(contour, marchingantsCtx) }, 500); 
	}

	private function marching(contour:BitmapData, dest:BitmapData):void {
		if (contour == null) return;
		var rect:Rectangle = contour.getColorBoundsRect(0xFFFFFFFF, maskcolor, true);
		if (rect.isEmpty()) return;
		var stencil:BitmapData = new BitmapData(rect.width,rect.height, true, 0);
		var srcRect:Rectangle= new Rectangle (zebradelta.x,0, rect.width,rect.height);
		stencil.copyPixels(PaintVars.zebra, srcRect, new Point(0, 0));
		stencil.threshold(contour, rect, new Point(0, 0), '==', 0, 0x00FFFFFF);
		// get a stencil with the exact dimension of the image
		var mtx:Matrix = new Matrix();
		mtx.translate(rect.x ,rect.y);
		dest.draw(stencil, mtx);
		stencil.dispose();
		if (zebradelta.x > 10) 	zebradelta = new Point(2,0);
		else zebradelta = xPoint.vsum(new Point(2,0), zebradelta);
	}

	//////////////////////////
	// offscreen paint
	//////////////////////////

	public function fillCanvasWithSelectedColor(w:int, h:int, fd:*, rect:Rectangle):BitmapData {
		var spr:Sprite = new Sprite();
		var bmp:BitmapData = new BitmapData(w,h, true, 0);
		var g:Graphics = spr.graphics;
		var dx:int =0; 	var dy:int =0;
		var dw:int =w; 	var dh:int =h;

		if (rect!= null) {
			dx = rect.x; dy = rect.y;
			dw = rect.width; dh = rect.height;
		}
		if (fd != null) {
			if (fd is Number) g.beginFill(fd);
			else PaintVars.setGradientFill(g,fd, dw, dh,dx,dy);
			g.drawRect(dx,dy, dw, dh);
			g.endFill();
			bmp.draw(spr);
		}
		return bmp;
	}

	//////////////////////////
	// Flood-fill
	//////////////////////////

	/*
	Flood-fill (node, target-color, replacement-color):
	1. Set Q to the empty queue.
	2. If the color of node is not equal to target-color, return.
	3. Add node to Q.
	4. For each element n of Q:
	5.		If the color of n is equal to target-color:
	6.			Set w and e equal to n.
	7.			Move w to the west until the color of the node to the west of w no longer matches target-color.
	8.			Move e to the east until the color of the node to the east of e no longer matches target-color.
	9.			Set the color of nodes between w and e to replacement-color.
	10.			For each node n between w and e:
	11.				If the color of the node to the north of n is target-color, add that node to Q.
	12.				If the color of the node to the south of n is target-color, add that node to Q.
	13. Continue looping until Q is exhausted.
	14. Return.
	*/

	private var	basecolor:Object;

	private function floodfill(place:BitmapData, node:Point, targetcolor:uint, maskdata:BitmapData):BitmapData {
		place.lock();
		maskdata.lock();
		basecolor= getRGB(targetcolor);
		// use offscreen;
		var edges:BitmapData=new BitmapData(place.width,place.height, true, 0);
		edges.lock();
		var queue:Array = [];
		queue.push(node);
		var i:int = 0;
		while (i < queue.length) {
			var px:Point = queue[i];
			i++;
			if (!matchPoint(px, place, maskdata, targetcolor)) continue;
			var w:Point = px;
			var e:Point = px;
			while (matchPoint(w, place, maskdata, targetcolor)) w = xPoint.vsum(w, new Point(-1, 0));
			while (matchPoint(e, place, maskdata, targetcolor)) e = xPoint.vsum(e, new Point(1, 0));
			if (outsideArea(w, place)) w = xPoint.vsum(w, new Point(1,0));	// is out
			if (outsideArea(e, place)) e = xPoint.vsum(e, new Point(-1,0));	// is out
			edges.setPixel32 (w.x, w.y, maskcolor); 
			edges.setPixel32 (e.x, e.y, maskcolor); 
			var n:int = xPoint.vdiff(e, w).x;
			for (var j:int = 0; j <= n; j++) {
				var pt:Point = xPoint.vsum(w, new Point( j, 0));
				maskdata.setPixel32 (pt.x, pt.y, maskcolor);
				var north:Point = xPoint.vsum(pt,new Point(0, -1));
				var south:Point = xPoint.vsum(pt,new Point(0, 1));
				var ptn:Boolean = matchPoint(north, place, maskdata, targetcolor);
				var pts:Boolean = matchPoint(south, place, maskdata, targetcolor);
				if (ptn) queue.push(north);
				if (pts) queue.push(south);
				var northv:Boolean = !ptn && (outsideArea(north, place) ? true : isTransparent(maskdata, north));
				var southv:Boolean = !pts && (outsideArea(south, place) ? true : isTransparent(maskdata, south));
				if (northv && southv) continue;
				if (northv || southv) edges.setPixel32 (pt.x, pt.y, maskcolor);
			}
		}
		place.unlock();
		maskdata.unlock();
		edges.unlock();
		return edges;
	}

	private function matchPoint(p:Point, place:BitmapData, maskdata:BitmapData, targetcolor:uint):Boolean {
		if (outsideArea(p, place)) return false;
		if (! isTransparent(maskdata, p)) return false;
		return isLike(place, p,targetcolor);
	}

	private function getRGB(color:uint):Object {
		return {r: (color >> 16) & 255, g: (color >> 8) & 255, b: color & 255};
	}

	private function isTransparent(data:BitmapData, node:Point):Boolean { return ((data.getPixel32(node.x, node.y) >> 24) & 255) == 0 }

	private function isLike(pdata:BitmapData, pt:Point, tc:uint):Boolean{
		var color:uint = pdata.getPixel(pt.x, pt.y);
		if ((color == tc) || (PaintVars.tolerance > 255)) return true;
		if (PaintVars.tolerance == 0) return false;
		if (tc == 0) return false;
		var newcolor:Object = getRGB(color);
		var rx:uint = newcolor.r - basecolor.r;
		var gx:uint = newcolor.g - basecolor.g;
		var bx:uint = newcolor.b - basecolor.b;
		//	var t:int = Math.sqrt((rx*rx)+ (gx*gx) + (bx*bx));
		//	return (t / 441) * 255 <= PaintVars.tolerance;
		var t:int = (rx*rx)+ (gx*gx) + (bx*bx);
		return t <= (PaintVars.tolerance * PaintVars.tolerance);
	}

	private function outsideArea(node:Point, canvas:BitmapData):Boolean {
		if ((node.x < 0) || (node.x > (canvas.width - 1))) return true;
		if ((node.y < 0) || (node.y > (canvas.height - 1))) return true;
		return false;
	}

	private function getOffsetPoint(mtarget:PaintObject, pt:Point):Point {
		var delta:Point = new Point(mtarget.getAttribute('x'), mtarget.getAttribute('y'));
		var pt:Point = mtarget.getTransformedPoint(pt);
		pt = xPoint.vfloor(xPoint.vdiff(pt, delta));
		if (pt.x < 0) pt.x = 0;
		if (pt.y < 0) pt.y = 0;
		if (pt.x > mtarget.getAttribute('width')) pt.x = mtarget.getAttribute('width')
		if (pt.y > mtarget.getAttribute('height')) pt.y = mtarget.getAttribute('height')
		return pt;
	}

}}
