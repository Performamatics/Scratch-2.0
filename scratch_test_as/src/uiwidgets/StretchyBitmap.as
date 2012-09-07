package uiwidgets {
	import flash.display.*;
	import flash.geom.*;

public class StretchyBitmap extends Sprite {

	private var srcBM:BitmapData;
	private var cachedBM:Bitmap;

	public function StretchyBitmap(bm:BitmapData = null, w:int = 100, h:int = 75) {
		srcBM = bm;
		if (srcBM == null) srcBM = new BitmapData(1, 1, false, 0x808080);
		cachedBM = new Bitmap(srcBM);
		addChild(cachedBM);
		setWidthHeight(w, h);
	}

	public function setWidthHeight(w:int, h:int):void {
		var srcW:int = srcBM.width;
		var srcH:int = srcBM.height;
		w = Math.max(w, srcW);
		h = Math.max(h, srcH);
		var halfSrc:int;

		// adjust width
		var newBM:BitmapData = new BitmapData(w, h, true, 0xFF000000);
		halfSrc = srcW / 2;
		newBM.copyPixels(srcBM, new Rectangle(0, 0, halfSrc, srcH), new Point(0, 0));
		newBM.copyPixels(srcBM, new Rectangle(srcW - halfSrc, 0, halfSrc, srcH), new Point(w - halfSrc, 0));
		for (var dstX:int = halfSrc; dstX < (w - halfSrc); dstX++) {
			newBM.copyPixels(srcBM, new Rectangle(halfSrc, 0, 1, srcH), new Point(dstX, 0));
		}

		// adjust height
		halfSrc = srcH / 2;
		newBM.copyPixels(newBM, new Rectangle(0, (srcH - halfSrc), w, halfSrc), new Point(0, h - halfSrc));
		for (var dstY:int = halfSrc + 1; dstY < (h - halfSrc); dstY++) {
			newBM.copyPixels(newBM, new Rectangle(0, halfSrc, w, 1), new Point(0, dstY));
		}

		// install new bitmap
		cachedBM.bitmapData = newBM;
	}

}}
