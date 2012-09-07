package uiwidgets {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.text.*;
	import flash.utils.Dictionary;
	import ui.parts.UIPart;

public class DialogBox extends Sprite {

	public static var color:int = 0xFFFFFF;

	public var acceptFunction:Function;  // if not nil, called when menu interaction is accepted
	public var fields:Dictionary = new Dictionary();
	public var booleanFields:Dictionary = new Dictionary();
	public var widget:DisplayObject;
	public var minW:int = 0;
	public var minH:int = 0;

	protected var title:TextField;
	protected var buttons:Array = [];
	protected var labelsAndFields:Array = [];
	protected var booleanLabelsAndFields:Array = [];
	protected var maxLabelWidth:int = 0;
	protected var maxFieldWidth:int = 0;
	protected var heightPerField:int = Math.max(makeLabel("foo").height, makeField(10).height) + 10;
  private var textColor:uint = 0x4c4d4f;
 	private var titleColor:uint = 0x848484;


	public function DialogBox(acceptFunction:Function = null) {
		this.acceptFunction = acceptFunction;
		addFilters();
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		addEventListener(FocusEvent.KEY_FOCUS_CHANGE, focusChange);
	}

	public static function ask(question:String, defaultAnswer:String, stage:Stage, resultFunction:Function = null):void {
		function done():void { if (resultFunction != null) resultFunction(d.fields["answer"].text) }
		var d:DialogBox = new DialogBox(done);
		d.addTitle(question);
		d.addField("answer", 120, defaultAnswer, false);
		d.addButton("OK", d.accept);
		d.showOnStage(stage);
	}

	public static function confirm(question:String, stage:Stage, okFunction:Function = null):void {
		var d:DialogBox = new DialogBox(okFunction);
		d.addTitle(question);
		d.addAcceptCancelButtons("OK");
		d.showOnStage(stage);
	}

	public static function notify(msg:String, stage:Stage, okFunction:Function = null):void {
		var d:DialogBox = new DialogBox(okFunction);
		d.addTitle(msg);
		d.addButton("OK", d.cancel);
		d.showOnStage(stage);
	}

	public function addTitle(s:String):void {
		title = makeLabel(s, true);
		addChild(title);
	}

	public function addWidget(o:DisplayObject):void {
		widget = o;
		addChild(o);
	}

	public function addField(fieldName:String, width:int, defaultValue:* = null, showLabel:Boolean = true):void {
		var l:TextField = null;
		if (showLabel) {
			l = makeLabel(fieldName + ":");
			addChild(l);
		}
		var f:TextField = makeField(width);
		if (defaultValue != null) f.text = defaultValue;
		addChild(f);
		fields[fieldName] = f;
		labelsAndFields.push([l, f]);
	}

	public function addBoolean(fieldName:String, defaultValue:Boolean = false, isRadioButton:Boolean = false):void {
		var l:TextField = makeLabel(fieldName + ":");
		addChild(l);
		var f:IconButton = isRadioButton ?
			new IconButton(null, null, null, true) :
			new IconButton(null, getCheckMark(true), getCheckMark(false));
		if (defaultValue) f.turnOn() else f.turnOff();
		addChild(f);
		booleanFields[fieldName] = f;
		booleanLabelsAndFields.push([l, f]);
	}

private function getCheckMark(b:Boolean):Sprite{
	var spr:Sprite = new Sprite();
	var g:Graphics = spr.graphics;
	g.clear();
	g.beginFill(0xFFFFFF);
	g.lineStyle(1,0x929497,1,true);
	g.drawRoundRect(0, 0, 17, 17, 3, 3);
	g.endFill();
	if (b) {
		g.lineStyle(2,textColor,1,true);
		g.moveTo(3,7);
		g.lineTo(5,7);
		g.lineTo(8,13);
		g.lineTo(14,3);
	}
	return spr;
}
	public function addAcceptCancelButtons(acceptLabel:String = null):void {
		// Add a cancel button and an optional accept button with the given label.
		if (acceptLabel != null) addButton(acceptLabel, accept);
		addButton("Cancel", cancel);
	}

	public function addButton(label:String, action:Function):void {
		function doAction():void {
			cancel();
			if (action != null) action();
		}
		var b:Button = new Button(label, doAction);
		addChild(b);
		buttons.push(b);
	}

	public function showOnStage(stage:Stage, center:Boolean = false):void {
		fixLayout();
		if (center) {
			x = (stage.stageWidth - width) / 2;
			y = (stage.stageHeight - height) / 2;
		} else {
			x = stage.mouseX + 10;
			y = stage.mouseY + 10;
		}
		x = Math.max(0, Math.min(x, stage.stageWidth - width));
		y = Math.max(0, Math.min(y, stage.stageHeight - height));
		stage.addChild(this);
		if (labelsAndFields.length > 0) {
			// note: doesn't work when testing from FlexBuilder; works when deployed
			stage.focus = labelsAndFields[0][1];
		}
	}

	public function accept():void {
		if (acceptFunction != null) acceptFunction(this);
		if (parent != null) parent.removeChild(this);
	}

	public function cancel():void {
		if (parent != null) parent.removeChild(this);
	}

	public function getField(fieldName:String):* {
		if (fields[fieldName] != null) return fields[fieldName].text;
		if (booleanFields[fieldName] != null) return booleanFields[fieldName].isOn();
		return null;
	}

	private function makeLabel(s:String, forTitle:Boolean = false):TextField {
		var format:TextFormat = new TextFormat();
		format.font = 'Lucida Grande';
		format.bold = forTitle;
		format.size = forTitle ? 13 : 13;
		format.color =  forTitle ? titleColor : textColor;
		if (forTitle) format.align = TextFormatAlign.CENTER;

		var result:TextField = new TextField();
		result.autoSize = TextFieldAutoSize.LEFT;
		result.selectable = false;
		result.background = false;
		result.text = s;
		result.setTextFormat(format);
		return result;
	}

	private function makeField(width:int):TextField {
		var format:TextFormat = new TextFormat();
		format.font ='Lucida Grande';
		format.size = 13;
		format.color = textColor;

		var result:TextField = new TextField();
		result.selectable = true;
		result.type = TextFieldType.INPUT;
		result.background = true;
		result.border = true;
		result.defaultTextFormat = format;
		result.width = width;
		result.height = format.size + 8;

		result.backgroundColor = 0xFFFFFF;
		result.borderColor = CSS.borderColor;

		return result;
	}

	public function fixLayout():void {
		var label:TextField;
		var i:int, totalW:int;
		fixSize();
		var fieldX:int = maxLabelWidth + 17;
		var fieldY:int = 15;
		if (title != null) {
			title.x = (width - title.width) / 2;
			title.y = 5;
			fieldY = title.y + title.height + 20;
		}
		if (widget != null) {
			widget.x = (width - widget.width) / 2;
			widget.y = (title != null) ? title.y + title.height + 10 : 10;
			fieldY = widget.y + widget.height + 15;
		}
		// fields
		for (i = 0; i < labelsAndFields.length; i++) {
			label = labelsAndFields[i][0];
			var field:TextField = labelsAndFields[i][1];
			if (label != null) {
				label.x = fieldX - 5 - label.width;
				label.y = fieldY;
			}
			field.x = fieldX;
			field.y = fieldY + 1;
			fieldY += heightPerField;
		}
		// boolean fields
		for (i = 0; i < booleanLabelsAndFields.length; i++) {
			label = booleanLabelsAndFields[i][0];
			var ib:IconButton = booleanLabelsAndFields[i][1];
			if (label != null) {
				label.x = fieldX - 5 - label.width;
				label.y = fieldY + 5;
			}
			ib.x = fieldX - 2;
			ib.y = fieldY + 5;
			fieldY += heightPerField;
		}
		// buttons
		if (buttons.length > 0) {
			totalW = (buttons.length - 1) * 10;
			for (i = 0; i < buttons.length; i++) totalW += buttons[i].width;
			var buttonX:int = (width - totalW) / 2;
			var buttonY:int = height - (buttons[0].height + 15);
			for (i = 0; i < buttons.length; i++) {
				buttons[i].x = buttonX;
				buttons[i].y = buttonY;
				buttonX += buttons[i].width + 10;
			}
		}
	}

	private function fixSize():void {
		var i:int, totalW:int;
		var w:int = minW;
		var h:int = 0;
		// title
		if (title != null) {
			w = Math.max(w, title.width);
			h += 10 + title.height;
		}
		if (widget != null) {
			w = Math.max(w, widget.width);
			h += 10 + widget.height;
		}
		// fields
		maxLabelWidth = 0;
		maxFieldWidth = 0;
		for (i = 0; i < labelsAndFields.length; i++) {
			var r:Array = labelsAndFields[i];
			if (r[0] != null) maxLabelWidth = Math.max(maxLabelWidth, r[0].width);
			maxFieldWidth = Math.max(maxFieldWidth, r[1].width);
			h += heightPerField;
		}
		//boolean fields
		for (i = 0; i < booleanLabelsAndFields.length; i++) {
			r = booleanLabelsAndFields[i];
			if (r[0] != null) maxLabelWidth = Math.max(maxLabelWidth, r[0].width);
			maxFieldWidth = Math.max(maxFieldWidth, r[1].width);
			h += heightPerField;
		}
		w = Math.max(w, maxLabelWidth + maxFieldWidth + 5);
		// buttons
		totalW = 0;
		for (i = 0; i < buttons.length; i++) totalW += buttons[i].width + 10;
		w = Math.max(w, totalW);
		if (buttons.length > 0) h += buttons[0].height + 15;
		if ((labelsAndFields.length > 0) || (booleanLabelsAndFields.length > 0)) h += 15;
		drawBackground(w + 30, h + 10);
	}

	private function drawBackground(w:int, h:int):void {
		UIPart.drawTopBar(graphics, CSS.titleBarColors,UIPart.getTopBarPath(w,h), w, CSS.titleBarH);
		graphics.lineStyle(0.5, CSS.borderColor, 1, true);
		graphics.beginFill(0xFFFFFF);
		graphics.drawRect(0, CSS.titleBarH, w, h - CSS.titleBarH);
		width = w;
		height = h;
		
	}

	private function addFilters():void {
		var f:DropShadowFilter = new DropShadowFilter();

		f.blurX = f.blurY = 8;
		f.distance = 5;
		f.alpha = 0.75;
		f.color = 0x333333;	
		filters = [f];
	}

	private function focusChange(evt:Event):void {
		evt.preventDefault();
		if (labelsAndFields.length == 0) return;
		var focusIndex:int = -1;
		for (var i:int = 0; i < labelsAndFields.length; i++) {
			if (stage.focus == labelsAndFields[i][1]) focusIndex = i;
		}
		focusIndex++;
		if (focusIndex >= labelsAndFields.length) focusIndex = 0;
		stage.focus = labelsAndFields[focusIndex][1];
	}

	private function mouseDown(evt:MouseEvent):void {if (evt.target == this) startDrag();}
	
	private function mouseUp(evt:MouseEvent):void { stopDrag() }

	private function keyDown(evt:KeyboardEvent):void {
		if ((evt.keyCode == 10) || (evt.keyCode == 13)) accept();
	}

}}
