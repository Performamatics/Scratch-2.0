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
Container for scrolling and scaling. It has 2 main objects:
	SVGroot: contains all the costume objects
	SVGSelector: selector widget for rotating and scaling
*/

package ui.paintui {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.filters.*;
	import flash.geom.*;
	import uiwidgets.*;

public class PaintCanvas extends ScrollFrameContents {

	public var w:int;
	public var h:int;

	public function PaintCanvas(p:PaintEdit) {
		createTexture();
		this.filters = addFilters();
		PaintVars.svgroot = new SVGRoot(p);
		addChild(PaintVars.svgroot);
		PaintVars.svgroot.selectorGroup = new SVGSelector();
		addChild(PaintVars.svgroot.selectorGroup );
	}

	public override function updateSize():void {
		if (parent is ScrollFrame) (parent as ScrollFrame).updateScrollbarVisibility();
	}

	public function setCanvasSize(dw:int, dh:int):void {
		var cw:int = this.w;
		var ch:int = this.h;
		this.w = dw;
		this.h = dh;
		setWidthHeight(dw, dh);
		PaintVars.svgroot.setWidthHeight(dw, dh);
		PaintVars.svgroot.repositionElements(new Point(Math.floor((this.w - cw) / 2), Math.floor((this.h - ch) / 2)));
		updateSize();
	}

	public function updateZoomScale():void {
		this.scaleX = this.scaleY= PaintVars.currentZoom;
		updateSize();
		PaintVars.svgroot.clearAllSelections();
	}

	private function addFilters():Array {
		var f:DropShadowFilter = new DropShadowFilter();
		f.blurX = f.blurY = 5;
		f.distance = 3;
		f.color = 0x333333;
		return [f];
	}

	private function createTexture():void {
		var a:uint = 0xFF;
		var seg:Array;
		var row:int, column:int, j:int, k:int;
		var lines:Array = [[0xc5c6c8, 0xdcddde, 0xd1d3d4], [0xdbdcdd, 0xe9eaea, 0xe2e3e4], [0xdcddde, 0xeaecec, 0xe4e4e6]];
		texture = new BitmapData(10, 10);
		for (row = 0; row < 3; row++) {
			for (j = 0; j < lines.length; j++) {
				seg = lines[j];
				for (column = 0; column < 3; column++) { // repeat each pattern
					for (k = 0; k < seg.length; k++) texture.setPixel32(j + 3 * row, 3 * column + k, (a << 24) | seg[k]);
					texture.setPixel32(j + 3 * row , 3 * column + k, (a << 24) | seg[0]);
				}
			}
		}
		seg = lines[0];
		for (column = 0; column < 3; column++) {
			for (k = 0; k < seg.length; k++) texture.setPixel32(9, 3 * column + k, (a << 24) | seg[k]);
			texture.setPixel32(9, 3 * column + k, (a << 24) | seg[0]);
		}
	}

}}
