package uiwidgets {
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.geom.Matrix;
	import flash.display.GradientType;
	
public class Button extends Sprite {

	private var labelOrIcon:DisplayObject;
	private var color:* = CSS.titleBarColors;
	private var minWidth:int = 50;
	
	private var action:Function;

	public function Button(label:String, action:Function = null) {
		this.action = action;
		addLabel(label);
		addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_UP, mouseUp);
	}

	public function setLabel(s:String):void {
		if (labelOrIcon is TextField) {
			TextField(labelOrIcon).text = s;
			setMinWidthHeight(0, 0);
		} else {
			if ((labelOrIcon != null) && (labelOrIcon.parent != null)) labelOrIcon.parent.removeChild(labelOrIcon);
			addLabel(s);
		}
	 }

	public function setIcon(icon:DisplayObject):void {
		if ((labelOrIcon != null) && (labelOrIcon.parent != null)) {
			labelOrIcon.parent.removeChild(labelOrIcon);
		}
		labelOrIcon = icon;
		if (icon != null) addChild(labelOrIcon);;
		setMinWidthHeight(0, 0);
	}

	public function setMinWidthHeight(minW:int, minH:int):void {
		if (labelOrIcon != null) {
			if (labelOrIcon is TextField) {
				minW = Math.max(minWidth, labelOrIcon.width + 11);
				minH = 26;
			} else {
				minW = Math.max(minWidth, labelOrIcon.width + 12);
				minH = Math.max(minH, labelOrIcon.height + 12);
			}
			labelOrIcon.x = ((minW - labelOrIcon.width) / 2) - 0;
			labelOrIcon.y = ((minH - labelOrIcon.height) / 2) - 0;
		}
		// outline
		graphics.clear();
		graphics.lineStyle(0.5,CSS.borderColor,1,true);
		if (color is Array){
	 		var matr:Matrix = new Matrix();
 			matr.createGradientBox(minW, minH, Math.PI / 2, 0, 0);
 			graphics.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], matr);  
  		}
		else graphics.beginFill(color);
		graphics.drawRoundRect(0, 0, minW, minH, 12);
 		graphics.endFill();
	}

	private function mouseOver(evt:MouseEvent):void { setColor(CSS.overColor) }
	private function mouseOut(evt:MouseEvent):void { setColor(CSS.titleBarColors) }
	private function mouseDown(evt:MouseEvent):void { Menu.removeMenusFrom(stage) }
	private function mouseUp(evt:MouseEvent):void {
		if (action != null) action();
		evt.stopImmediatePropagation();
	}

	private function setColor(c:*):void {
		color = c;
		if (labelOrIcon is TextField) {
			(labelOrIcon as TextField).textColor = (c == CSS.overColor) ? CSS.white : CSS.buttonLabelColor;
		}
		setMinWidthHeight(5, 5);
	}

	private function addLabel(s:String):void {
		var label:TextField = new TextField();
		label.autoSize = TextFieldAutoSize.LEFT;
		label.selectable = false;
		label.background = false;
		label.defaultTextFormat = CSS.normalTextFormat;
		label.textColor = CSS.buttonLabelColor;
		label.text = s;
		labelOrIcon = label;
		setMinWidthHeight(0, 0);
		addChild(label);
	}

}}
