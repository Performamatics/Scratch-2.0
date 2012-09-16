package watchers {
	import flash.display.Sprite;
	import flash.text.*;

public class WatcherReadout extends Sprite {

	private var smallFont:TextFormat = new TextFormat("Verdana", 10, 0xFFFFFF, true);
	private var largeFont:TextFormat = new TextFormat("Verdana", 14, 0xFFFFFF, true);

	private var frame:WatcherFrame;
	private var tf:TextField;
	private var isLarge:Boolean;

	public function WatcherReadout() {
		frame = new WatcherFrame(0xFFFFFF, Specs.variableColor, 8, true);
		addChild(frame);
		addTextField();
		beLarge(false);
	}

	public function setColor(color:int):void { frame.setColor(color) }

	public function get contents():String { return tf.text }

	public function setContents(s:String):void {
		if (s == tf.text) return; // no change
		tf.text = s;
		fixLayout();
	}

	public function beLarge(newValue:Boolean):void {
		isLarge = newValue;
		var fmt:TextFormat = isLarge ? largeFont : smallFont;
		fmt.align = TextFormatAlign.CENTER;
		tf.defaultTextFormat = fmt;
		tf.setTextFormat(fmt); // force font change
		fixLayout();
	}

	private function fixLayout():void {
		var w:int = isLarge ? 48 : 40;
		var h:int = isLarge ? 20 : 14;
		var hPad:int = isLarge ? 12 : 5;
		w = Math.max(w, tf.textWidth + hPad);
		tf.width = w;
		tf.height = h;
		tf.y = isLarge ? 0 : -1;
		if ((w != frame.w) || (h != frame.h)) frame.setWidthHeight(w, h);
	}

	private function addTextField():void {
		tf = new TextField();
		tf.type = "dynamic";
		tf.selectable = false;
		addChild(tf);
	}

}}
