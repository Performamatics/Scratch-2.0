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
	Rendering object when costume is viewed in the editor.
	A PaintGroup is a collection of PaintObjects.
*/

package ui.paintui {
	import flash.geom.*;

public class PaintGroup extends PaintObject {

	public function PaintGroup(type:String, uniqueId:String, svgdata:SVGData = null) {
		super(type, uniqueId, svgdata);
	}

	public function getSVGChildren():Array {
		var res:Array = [];
		for (var j:int = 0; j < this.numChildren; j++) res.push((getChildAt(j) as PaintObject).odata);
		return res;
	}

	public override function render():void {
		var m:Matrix = getScaleMatrix();
		m.concat(getSimpleRotation());
		this.transform.matrix = m;
	}

	public override function resizeToMatrix():void {
		var p:Point = getBoxCenterDelta();
		for (var i:int = 0; i < this.numChildren; i++) {
			var elem:PaintObject = this.getChildAt(i) as PaintObject;
			if (!elem) continue;
			if (elem.hasNoMatrices()) elem.resizeShape(sform.clone());
			else elem.skewShape(sform);
			elem.translateTo(p);
		}
		render();
		clearScaleMatrix();
	}

	public function rotateFromPoint(node:PaintObject):void {
		node.odata.rotateFromPoint(this.transform.matrix, this.getAttribute('angle'));
		node.render();
	}

	public override function translateTo(p:Point):void {
		for (var i:int = 0; i < this.numChildren; i++) (this.getChildAt(i) as PaintObject).translateTo(p);
		render();
	}

}}
