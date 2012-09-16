package uiwidgets {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;

public class TextPane extends Sprite {

	private static var scrollbarWidth:int = 10;

	public var textField:TextField;
	public var scrollbar:Scrollbar;

	public function TextPane() {
		addTextField();
		scrollbar = new Scrollbar(scrollbarWidth, textField.height, scrollTextField);
		setWidthHeight(400, 500);
		addChild(scrollbar);
		addEventListener(Event.ENTER_FRAME, updateScrollbar);
	}

	public function setWidthHeight(w:int, h:int):void {
		textField.width = w - scrollbar.width;
		textField.height = h;
		scrollbar.x = textField.width;
		scrollbar.setWidthHeight(scrollbarWidth, h);
	}

	public function append(s:String):void {
		textField.appendText(s);
		textField.scrollV = textField.maxScrollV - 1;
		updateScrollbar(null);
	}

	public function clear():void {
		textField.text = "";
		textField.scrollV = 0;
		updateScrollbar(null);
	}

	public function setText(s:String):void {
		textField.text = s;
		textField.scrollV = textField.maxScrollV - 1;
		updateScrollbar(null);
	}

	private function scrollTextField(scrollFraction:Number):void {
		textField.scrollV = scrollFraction * textField.maxScrollV;
	}

	private function updateScrollbar(evt:Event):void {
		var scroll:Number = textField.scrollV / textField.maxScrollV;
		var visible:Number = textField.height / textField.textHeight;
		scrollbar.update(scroll, visible);
	}

	private function addTextField():void {
		textField = new TextField();
		textField.background = true;
		textField.type = TextFieldType.INPUT;
		textField.defaultTextFormat = new TextFormat("Verdana", 14);
		textField.multiline = true;
		textField.wordWrap = true;
		addChild(textField);
	}

}}
