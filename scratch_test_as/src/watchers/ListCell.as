package watchers {
	import flash.display.Sprite;
	import flash.events.*;
	import flash.text.*;

public class ListCell extends Sprite {

	private const format:TextFormat = new TextFormat("Verdana", 10, 0xFFFFFF, true);

	public var tf:TextField;
	private var frame:WatcherFrame;

	public function ListCell(s:String, width:int, whenChanged:Function, nextCell:Function) {
		frame = new WatcherFrame(0xFFFFFF, Specs.listColor, 6, true);
		addChild(frame);
		addTextField(whenChanged, nextCell);
		tf.text = s;
		setWidth(width);
	}

	public function setText(s:String, w:int = 0):void {
		// Set the text and, optionally, the width.
		tf.text = s;
		setWidth((w > 0) ? w : frame.w);
	}

	public function setEditable(isEditable:Boolean):void {
		tf.type = isEditable ? 'input' : 'dynamic';
	}

	public function setWidth(w:int):void {
		tf.width = Math.max(w, 15); // forces line wrapping, possibly changing tf.height
		var frameH:int = Math.max(tf.textHeight + 7, 20);
		frame.setWidthHeight(tf.width, frameH);
	}

	private function addTextField(whenChanged:Function, nextCell:Function):void {
		tf = new TextField();
		tf.type = 'input';
		tf.wordWrap = true;
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.defaultTextFormat = format;
		tf.x = 3;
		tf.y = 1;
		tf.addEventListener(Event.CHANGE, whenChanged);
		tf.addEventListener(FocusEvent.KEY_FOCUS_CHANGE, nextCell);
		addChild(tf);
	}

}}
