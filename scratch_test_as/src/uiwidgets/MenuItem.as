// MenuItem.as
// John Maloney, October 2009
//
// A single menu item for Menu.as.

package uiwidgets {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
public class MenuItem extends Sprite {

	public var label:TextField;
	public var selection:*;

	private var base:Shape;
	private var w:int, h:int;

	public function MenuItem(label:String, selectionValue:*, enabled:Boolean) {
		selection = (selectionValue == null) ? label : selectionValue;
		base = new Shape();
		addChild(base);
		if ((label == "---") || (label == "")) {
			// add a divider line
			base.graphics.beginFill(Menu.divisionColor);
			base.graphics.drawRect(0, 0, 1, 1); // gets stretched to menu width
			base.graphics.endFill();
			return;
		}
		addLabel(label, enabled);
		setBaseColor(Menu.color);
		if (enabled) {
			addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
	}

	private function addLabel(s:String, enabled:Boolean):void {
		var format:TextFormat = new TextFormat();
		format.font = Menu.font;
		format.size = Menu.fontSize;
		format.color = enabled ? Menu.fontNormalColor : 0x606060;
		label = new TextField();
		label.autoSize = TextFieldAutoSize.LEFT;
		label.selectable = false;
		label.background = false;
		label.text = s;
		label.setTextFormat(format);
		label.x = 10;
		label.y = (Menu.minHeight > 0) ? (Menu.minHeight - label.height) / 2 : 0;
		w = label.width + Menu.margin * 2;
		h =  (Menu.minHeight > 0) ? Menu.minHeight :  label.height;
		addChild(label);
	}

	public function setWidth(w:int):void {
		this.w = w;
		if (label != null) setBaseColor(Menu.color);
		width = w;
	}
	
	private function redrawMenuItem(c1:int, c2:int):void {
		setBaseColor(c1);
		label.textColor = c2;
	}
	
	private function setBaseColor(c:int):void {
		base.graphics.clear();
		base.graphics.beginFill(c);
//		base.graphics.drawRoundRect(0, 0, w, h, 3, 3);
		base.graphics.drawRect(0, 0, w, h);
		base.graphics.endFill();
	}

	private function mouseOver(evt:MouseEvent):void { redrawMenuItem(Menu.selectedColor, Menu.fontSelectedColor) }
	private function mouseOut(evt:MouseEvent):void  { redrawMenuItem(Menu.color, Menu.fontNormalColor) }

/*
	private function mouseOver(evt:MouseEvent):void { setBaseColor(Menu.selectedColor) }
	private function mouseOut(evt:MouseEvent):void  { setBaseColor(Menu.color) }
*/
	private function mouseUp(evt:MouseEvent):void {
		if (parent is Menu) Menu(parent).selected(selection);
	}

}}
