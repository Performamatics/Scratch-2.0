package ui {
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import blocks.*;
	import uiwidgets.*;
	import util.*;

// row holds mixture of shapes and TextFields
// always has at least one text field
// 3 cases for inserting a shape:
//	a. cursor at start of a TextField: insert shape before that TextField
//	b. cursor at end of a TextField: insert shape after that TextField
//	c. cursor in middle of a TextField: split that TextField and insert shape between the two resulting TextFields
//	d. cursor not in any of my TextFields: do nothing
// 3 cases for backspace:
//	a. at beginning of a TextField, delete shape before that TextField and merge with previous TextField, if any
//	b. in middle of TextField: delete a character
//	c. not in any of my TextFields: do nothing 

public class ProcedureSpecEditor extends Sprite {

	private var base:Shape;
	private var blockShape:BlockShape;
	private var row:Array = [];
	private var label:TextField;
	private var buttons:Array = [];
	private var activeField:TextField;

	public function ProcedureSpecEditor(originalSpec:String, parameterNames:Array) {
		base = new Shape();
		base.graphics.beginFill(DialogBox.color);
		base.graphics.drawRect(0, 0, 350, 100);
		base.graphics.endFill();
		addChild(base);

		blockShape = new BlockShape(BlockShape.CmdShape, 0xF3761D);
		blockShape.setWidthAndTopHeight(100, 25, true);
		addChild(blockShape);

		addLabel();
		addButtons();

		addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(Event.CHANGE, textChange);
		addEventListener(FocusEvent.FOCUS_OUT, focusChange);
		addEventListener(FocusEvent.FOCUS_IN, focusChange);
		addEventListener(Event.ADDED_TO_STAGE, addedToStage);
	
		addSpecElements(originalSpec, parameterNames);
	}

	private function addSpecElements(spec:String, parameterNames:Array):void {
		var i:int = 0;
		for each (var s:String in ReadStream.tokenize(spec)) {
			if ((s.length >= 2) && (s.charAt(0) == "%")) { // argument spec
				var argSpec:String = s.charAt(1);
				var arg:BlockArg = null;
				if (argSpec == "b") arg = makeBooleanArg();
				if (argSpec == "n") arg = makeNumberArg();
				if (argSpec == "s") arg = makeStringArg();
				if (arg) {
					arg.setArgValue(parameterNames[i++]);
					addElement(arg);
				}		
			} else {
				addElement(makeTextField(s));
			}	
		}
		if ((row.length == 0) || (row[row.length - 1] is BlockArg)) addElement(makeTextField(""));
		fixLayout();
	}

	private function addElement(o:DisplayObject):void {
		row.push(o);
		addChild(o);
	}

	public function spec():String {
		var result:String = "";
		for each (var o:* in row) {
			if (o is TextField) result += TextField(o).text;
			if (o is BlockArg) result += "%" + BlockArg(o).type;
			if ((result.length > 0) && (result.charAt(result.length - 1) != " ")) result += " ";
		}
		if ((result.length > 0) && (result.charAt(result.length - 1) == " ")) result = result.slice(0, result.length - 1);
		return result;
	}

	public function defaultArgValues():Array {
		var result:Array = [];
		for each (var el:* in row) {
			if (el is BlockArg) {
				var arg:BlockArg = BlockArg(el);
				result.push((arg.type == "n") ? 10 : "");
			}
		}
		return result;
	}

	public function parameterNames():Array {
		var result:Array = [];
		for each (var o:* in row) {
			if (o is BlockArg) result.push(BlockArg(o).field.text);
		}
		return result;
	}

	private function addButtons():void {
		var lightGray:int = 0xA0A0A0;
		buttons = [
			new Button("", function():void { addArg(makeNumberArg())  }),
			new Button("", function():void { addArg(makeStringArg())  }),
			new Button("", function():void { addArg(makeBooleanArg()) })
		];

		icon = new BlockShape(BlockShape.NumberShape, lightGray);
		icon.setWidthAndTopHeight(25, 15, true);
		buttons[0].setIcon(icon);

		icon = new BlockShape(BlockShape.RectShape, lightGray);
		icon.setWidthAndTopHeight(22, 15, true);
		buttons[1].setIcon(icon);

		var icon:BlockShape = new BlockShape(BlockShape.BooleanShape, lightGray);
		icon.setWidthAndTopHeight(25, 15, true);
		buttons[2].setIcon(icon);
	}

	private function addLabel():void {
		label = new TextField();
		label.selectable = false;
		label.defaultTextFormat = new TextFormat("Verdana", 14, 0);
		label.autoSize = TextFieldAutoSize.LEFT;
		label.text = "Click to add a parameter:";
		addChild(label);
	}

	private function makeBooleanArg():BlockArg { 
		var result:BlockArg = new BlockArg("b", 0xFFFFFF, true);
		result.field.text = "b1";
		return result;
	}

	private function makeNumberArg():BlockArg {
		var result:BlockArg = new BlockArg("n", 0xFFFFFF, true);
		result.field.restrict = null;
		result.field.text = "n1";
		return result;
	}

	private function makeStringArg():BlockArg {
		var result:BlockArg = new BlockArg("s", 0xFFFFFF, true);
		result.field.text = "s1";
		return result;
	}

	private function addArg(o:DisplayObject):void {
		var i:int = row.indexOf(activeField);
		if (i < 0) {
			appendObj(o);
			return;
		}
		stage.focus = activeField;
		var caret:int = activeField.caretIndex;
		if (activeField.caretIndex == 0) {
			insertObjAt(o, i);
		} else if (activeField.caretIndex == activeField.text.length) {
			if (i == (row.length - 1)) appendObj(o);
			else insertObjAt(o, i + 1);
		} else {
			// split text field and insert between
			var newTF:TextField = makeTextField(activeField.text.slice(caret));
			activeField.text = activeField.text.slice(0, caret);
			insertObjAt(newTF, i + 1);
			insertObjAt(o, i + 1);
			newTF.setSelection(0, 0);
			stage.focus = newTF;
		}
	}

	private function appendObj(o:DisplayObject):void {
		row.push(o);
		addChild(o);
		var tf:TextField = makeTextField("");
		row.push(tf);
		addChild(tf);
		stage.focus = tf;
		fixLayout();
	}

	private function insertObjAt(o:DisplayObject, i:int):void {
		row.splice(i, 0, o);
		addChild(o);
		fixLayout();
	}

	private function makeTextField(contents:String):TextField {
		var result:TextField = new TextField();
		result.borderColor = 0;
		result.backgroundColor = Color.mixRGB(blockShape.color, 0, 0.15);
		result.type = TextFieldType.INPUT;
		result.defaultTextFormat = new TextFormat("Verdana", 12, 0xFFFFFF);
		result.autoSize = TextFieldAutoSize.LEFT;
		result.text = contents;
		return result;
	}

	private function fixLayout():void {
		blockShape.x = 10;
		blockShape.y = 5;
		var nextX:int = blockShape.x + 6;
		var nextY:int = blockShape.y + 4;
		var maxH:int = 0;
		for each (var o:DisplayObject in row) maxH = Math.max(maxH, o.height);
		for each (o in row) {
			o.x = nextX;
			o.y = nextY + int((maxH - o.height) / 2) + ((o is TextField) ? 0 : 2);
			nextX += o.width;
			if (o is BlockArg) {
				var type:String = BlockArg(o).type;
				if (type == 'b') nextX += 3;
				if (type == 'n') nextX += 3;
				if (type == 's') nextX += 4;
			}
		}
		blockShape.setWidthAndTopHeight(nextX + 3 - blockShape.x, maxH + 10, true);

		label.x = blockShape.x;
		label.y = blockShape.y + blockShape.height + 20;

		nextX = label.x + label.width + 10;
		nextY = label.y - 3;
		for each (var b:Button in buttons) {
			b.x = nextX;
			b.y = nextY;
			addChild(b);
			nextX = nextX + b.width + 10;
		}
	}

	private function deleteBeforeLabel(label:TextField):void {
		// delete the element before the given label
		var i:int = row.indexOf(label);
		if (i <= 0) return;
		if (!(row[i - 1] is TextField)) deleteElement(row[i - 1]);  // delete a parameter
		i = row.indexOf(label);
		if ((i > 0) && (row[i - 1] is TextField)) {
			var prev:TextField = TextField(row[i - 1]);
			var caret:int = prev.caretIndex + 1;
			prev.appendText(" " + label.text); // insert an extra character that will be deleted
			deleteElement(label);
			prev.setSelection(caret, caret);
			stage.focus = prev;
		}
		fixLayout();
	}

	private function deleteElement(o:DisplayObject):void {
		this.removeChild(o);
		var i:int = row.indexOf(o);
		if (i >= 0) row.splice(i, 1);
	}

	private function keyDown(evt:KeyboardEvent):void {
		if ((evt.keyCode == 8) || (evt.keyCode == 127)) {
			var label:TextField = TextField(evt.target);
			if (label.caretIndex == 0) deleteBeforeLabel(label);
		}
	}

	private function mouseDown(evt:MouseEvent):void {
		if ((evt.target == this) && blockShape.hitTestPoint(evt.stageX, evt.stageY)) {
			// make the first text field the input focus when user clicks on the block shape
			// but misses all the text fields
			for each (var o:DisplayObject in row) {
				if (o is TextField) { stage.focus = TextField(o); return; }
			}
		}
	}

	private function textChange(evt:Event):void { fixLayout() }

	private function focusChange(evt:FocusEvent):void {
		activeField = null;
	 	if ((evt.target is TextField) && (row.indexOf(evt.target) >= 0)) {
	 		// a label field is losing focus; remember it
	 		activeField = TextField(evt.target);
		 }
		// update label fields to show focus
		for each (var o:DisplayObject in row) {
			if (o is TextField) {
				var tf:TextField = TextField(o);
				tf.background = (stage != null) && (tf == stage.focus);
			}
		}
	}

	private function addedToStage(evt:Event):void {
		for each (var o:DisplayObject in row) {
			if (o is TextField) {
				var tf:TextField = TextField(o);
				tf.setSelection(tf.text.length, tf.text.length);
				stage.focus = tf;
			}
		}
	}

}}
