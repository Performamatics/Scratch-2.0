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
This object is for imported objects that have a clip-path.
The resizing needs to calculte the right position of the clipping.
*/

package ui.paintui {
	import flash.display.Shape;
	import flash.geom.*;

public class PaintClipObject extends PaintObject {

	public function PaintClipObject(type:String, uniqueId:String, svgdata:SVGData = null) {
		super(type, uniqueId, svgdata);
	}

	public override function resizeToMatrix():void {
		var mtx:Matrix = sform.clone();
		resizeShape(sform);
		clearScaleMatrix();
		render();
	}

	public override function resizeShape(mtx:Matrix):void {
		switch (tagName) {
		case 'rect':
			odata.recreateRect(mtx);
			break;
		case 'ellipse':
			odata.recreateEllipse(mtx);
			break;
		case 'polygon':
		case 'path':
			odata.resizePath(mtx);
			break;
		}
		updateClipPath(mtx);
	}

	private function updateClipPath(mtx:Matrix):void {
		var p:Point = odata.getClipCenterDelta(mtx);
		var svg:SVGData = getAttribute('clip-path');
		odata.updateClipPath(mtx, svg);
		svg.translateTo(p);
	}

}}
