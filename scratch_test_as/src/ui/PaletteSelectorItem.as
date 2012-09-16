// PaletteSelectorItem.as
// John Maloney, August 2009
//
// A PaletteSelectorItem is a text button for a named category in a PaletteSelector.
// It handles mouse over, out, and up events and changes its appearance when selected.

package ui {
	import flash.display.Sprite;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

public class PaletteSelectorItem extends Sprite {

	public var categoryID:int;
	public var label:TextField;
	public var isSelected:Boolean = false;

	private var color:uint;

	public function PaletteSelectorItem(id: int, s:String, c:uint) {
		color = c;
		categoryID = id;
		initLabel(s);
		setSelected(false);
		addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
		addEventListener(MouseEvent.MOUSE_UP, mouseUp);
	}

	private function initLabel(s:String):void {
		label = new TextField();
		label.autoSize = TextFieldAutoSize.LEFT;
		label.selectable = false;
		label.text = s;
		label.setTextFormat(CSS.paletteFormat);
		addChild(label);
	}

	public function setSelected(flag:Boolean):void {
		var w:int = 100;
		var h:int = label.height + 2;
		var tabInset:int = 8;
		var tabW:int = 7;
		isSelected = flag;
		label.textColor = isSelected ? CSS.white : CSS.offColor;
		label.x = 17;
		label.y = 1;
		var g:Graphics = this.graphics;
		g.clear();
		g.beginFill(0xFF00, 0); // invisible, but mouse sensitive
		g.drawRect(0, 0, w, h);
		g.endFill();
		g.beginFill(color);
		g.drawRect(tabInset, 1, isSelected ? w - tabInset - 5 : tabW, h - 2);
		g.endFill();
	}

	private function mouseOver(event:MouseEvent):void {
		label.textColor = isSelected ? CSS.white : CSS.buttonLabelOverColor;
	}

	private function mouseOut(event:MouseEvent):void {
		label.textColor = isSelected ? CSS.white : CSS.offColor;
	}

	private function mouseUp(event:MouseEvent):void {
		if (parent is PaletteSelector) {
			PaletteSelector(parent).select(categoryID);
		}
	}

}}
