package ui.paint {
	import flash.events.MouseEvent;	
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.filters.DropShadowFilter;
	import flash.display.Graphics;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.geom.Matrix;
	import scratch.*;

public class PaintCanvas extends Sprite {

	private var texture:BitmapData;
	private var container:Sprite;
	private var canvas:Sprite;
	private var viewedObj:ScratchObj;
	private var costume:Bitmap;

	public function PaintCanvas() {
		container = new Sprite();
		addChild(container);
	 	canvas = new Sprite();
		container.addChild(canvas);
		createTexture();
		drawFrame(canvas.graphics, 200, 200);
		canvas.filters = addFilters();
		costume = new Bitmap();
		canvas.addChild(costume);
	}

	public function setWidthHeight(w:int, h:int):void {	
		if ((w <0) || (h < 0)) return;
		viewedObj = (parent as PaintEdit).viewedObj;
		drawBackdrop(container.graphics, w, h);
		if (viewedObj == null) return;
		var current:ScratchCostume = viewedObj.currentCostume();
		var exits:Boolean = current.baseLayerBitmap != null;
		var sw:int = exits ? Math.min(w, Math.max (current.baseLayerBitmap.width, 120)) : 120;
		var sh:int = exits ? Math.min(h, Math.max (current.baseLayerBitmap.height, 120)) : 120;
		if (exits && (( current.baseLayerBitmap.width > sw) || (current.baseLayerBitmap.height > sh))) costume.bitmapData = scaleToFit(current, sw, sh);
		else {
			if (exits) costume.bitmapData = current.baseLayerBitmap.clone();
			else costume.bitmapData = new BitmapData(sw, sh, true, 0x00FFFFFF)
		}		
		drawFrame(canvas.graphics, sw, sh);
		var dx:int = (w - sw) / 2;
		var dy:int = (h - sh) / 2;
		canvas.x = dx; canvas.y = dy;
		costume.x = exits ? Math.max(0,(sw - current.baseLayerBitmap.width) / 2) : 0;
		costume.y = exits ? Math.max(0,(sh - current.baseLayerBitmap.height) / 2) : 0;
	}

	public function scaleToFit(current:ScratchCostume, w:int, h:int):BitmapData{
		var sizew:int = current.baseLayerBitmap.width;
		var sizeh:int = current.baseLayerBitmap.height;
		var tmp:BitmapData = new BitmapData(w, h, true, 0x00FFFFFF); // transparent fill color
		var scale:Number = Math.min(w / sizew, h / sizeh);
		var m:Matrix = new Matrix();
		if (scale < 1) { // scale down a large image
			m.scale(scale, scale);
			m.translate((w - (scale * sizew)) / 2, (h - (scale * sizeh)) / 2);
			} else { // center a smaller image
			m.translate((w - sizew) / 2, (h - sizeh) / 2);
		}
		tmp.draw(current.baseLayerBitmap, m);
		return tmp;
	}
		
	private  function drawBackdrop(g:Graphics, w:int,h:int):void{
	    g.clear();
	  	g.lineStyle(0.5, CSS.borderColor, 1, true);
	  	g.beginFill(CSS.white);
		g.drawRect(0, 0, w, h);
	  	g.endFill();
	}

	private function addFilters():Array {
		var f:DropShadowFilter = new DropShadowFilter();
		f.blurX = f.blurY = 5;
		f.distance = 3;
		f.color = 0x333333;
		return [f];		
	}

private function drawFrame(g:Graphics, w:int, h:int):void {
	g.clear();
	g.beginBitmapFill(texture);
	g.lineStyle(1,0xc2c2c3,0.5,true);
	g.drawRect(0, 0, w, h); 
	g.endFill();
}

//////////////////////////////////////////
// texture for bmp erasing
//////////////////////////////////////////
	
	public function createTexture():void {
		var a:uint = 0xFF, seg:Array;	
		var lines:Array= [[0xc5c6c8, 0xdcddde, 0xd1d3d4],[0xdbdcdd,0xe9eaea,0xe2e3e4],[0xdcddde,0xeaecec,0xe4e4e6]];		
		texture = new BitmapData(10, 10);
		for (var row:int=0; row < 3; row++) {
			for (var j:int=0; j < lines.length; j++) {
				seg = lines[j];
				for (var column:int=0; column < 3; column++) { // repeat each pattern
					for (var k:int=0; k < seg.length; k++) texture.setPixel32(j + 3*row, 3*column + k,  (a << 24) | seg[k]  );
					texture.setPixel32(j+ 3*row , 3*column + k, (a << 24) | seg[0]);
				}
			}
		}
		seg = lines[0];
		for (column = 0; column < 3; column++) {
			for (k = 0; k < seg.length; k++) texture.setPixel32(9, 3*column + k, (a << 24) | seg[k]);
			texture.setPixel32(9, 3*column + k, (a << 24) | seg[0]);
		}
	}

}}