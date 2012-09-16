package scratch {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.text.*;
	import assets.Resources;

public class AskPrompter extends Sprite {

	private const fontSize:int = 13;
	private const outlineColor:int = 0x4AADDE;
	private const inputFieldColor:int = 0xF2F2F2;

	private var app:Scratch;
	private var input:TextField;
	private var doneButton:Bitmap;

	public function	AskPrompter(promptString:String, app:Scratch) {
		this.app = app;
		var w:int = 449;
		var h:int = (promptString == "") ? 34 : 51;
		addBackground(w, h);
		addDoneButton(w, h);
		addPrompt(promptString);
		addInputField(h);
		x = 10;
		y = 340 - height;
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
	}

	public function grabKeyboardFocus():void { stage.focus = input }

	public function answer():String { return input.text }

	private function mouseDown(evt:MouseEvent):void {
		if (doneButton.hitTestPoint(evt.stageX, evt.stageY)) app.runtime.hideAskPrompt(this);
	}

	private function keyDown(evt:KeyboardEvent):void {
		if (evt.charCode == 13) app.runtime.hideAskPrompt(this);
	}

	private function addBackground(w:int, h:int):void {
		var shape:Shape = new Shape();
		shape.graphics.lineStyle(3, outlineColor, 1, true);
		shape.graphics.beginFill(0xFFFFFF);
		shape.graphics.drawRoundRect(0, 0, w, h, 13);
		shape.graphics.endFill();
		addChild(shape);
	}

	private function addDoneButton(w:int, h:int):void {
		doneButton = Resources.createBmp("promptCheckButton");
		doneButton.x = w - 26;
		doneButton.y = h - 26;
		addChild(doneButton);
	}

	private function addPrompt(s:String):void {
		if (s == "") return;
		var tf:TextField = new TextField();
		tf.defaultTextFormat = new TextFormat("Verdana", fontSize - 1, 0, true);
		tf.selectable = false;
		tf.text = s;
		tf.width = 430;
		tf.height = fontSize + 5
		tf.x = 9;
		tf.y = 2;
		addChild(tf);
	}

	private function addInputField(h:int):void {
		input = new TextField();
		input.defaultTextFormat = new TextFormat("Verdana", fontSize, 0, false);;
		input.type = TextFieldType.INPUT;
		input.background = true;
		input.backgroundColor = inputFieldColor;
		input.width = 410;
		input.height = 20;

		var f:BevelFilter = new BevelFilter();
		f.angle = 225;
		f.shadowAlpha = 0.6;
		f.distance = 3;
		f.strength = 0.4;
		f.blurX = f.blurY = 0;
		f.type = BitmapFilterType.OUTER;
		input.filters = [f];

		input.x = 9;
		input.y = h - (input.height + 5);
		addChild(input);
	}

}}
