// BlockArg.as
// John Maloney, August 2009
//
// A BlockArg represents a Block argument slot. Some BlockArgs, contain
// a text field that can be edited by the user. Others (e.g. booleans)
// are immutable. In either case, they be replaced by a reporter block
// of the right type. That is, dropping a reporter block onto a BlockArg
// inside a block causes the BlockArg to be replaced by the reporter.
// If a reporter is removed, a BlockArg is added to the block.
//
// To create a custom BlockArg widget such as a color picker, make a
// subclass of BlockArg for the widget. Your constructor is responsible
// for adding child display objects and setting its width and height.
// The widget must initialize argValue and update it as the user
// interacts with the widget. In some cases, the widget may need to
// override the setArgValue() method. If the widget can accept dropped
// arguments, it should set base to a BlockShape to support drag feedback.

package blocks {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.BevelFilter;
	import flash.text.*;
	import util.Color;

public class BlockArg extends Sprite {

	public static const epsilon:Number = 0.00000000000001;

	public var type:String;
	public var base:BlockShape;
	public var argValue:* = "";
	public var isVar:Boolean;
	public var isNumber:Boolean;
	public var field:TextField;
	public var menuName:String;

	private var menuIcon:Shape;

	// BlockArg types:
	//	b - boolean (pointed)
	//	c - color selector
	//	d - number with menu (rounded w/ menu icon)
	//	m - string with menu (rectangular w/ menu icon)
	//	n - number (rounded)
	//	s - string (rectangular)
	//	v - variable menu (a variant of "m" that sets isVar to true)
	//	none of the above - custom subclass of BlockArg
	public function BlockArg(type:String, color:int, editable:Boolean = false, menuName:String = "") {
		if (type == "v") {
			isVar = true;
			type = "m";
		}
		this.type = type;

		if (color == -1) { // copy for clone; omit graphics
			if ((type == 'd') || (type == 'n')) isNumber = true;
			return;
		}

		var c:int = Color.scaleBrightness(color, 0.92);
		if (type == "b") {
			base = new BlockShape(BlockShape.BooleanShape, c);
			argValue = false;
		} else if (type == "c") {
			base = new BlockShape(BlockShape.RectShape, c);
			this.menuName = "colorPicker";
			addEventListener(MouseEvent.MOUSE_DOWN, invokeMenu);
		} else if (type == "d") {
			base = new BlockShape(BlockShape.NumberShape, c);
			isNumber = true;
			this.menuName = menuName;
			addEventListener(MouseEvent.MOUSE_DOWN, invokeMenu);
		} else if (type == "m") {
			base = new BlockShape(BlockShape.RectShape, c);
			this.menuName = menuName;
			addEventListener(MouseEvent.MOUSE_DOWN, invokeMenu);
		} else if (type == "n") {
			base = new BlockShape(BlockShape.NumberShape, c);
			isNumber = true;
			argValue = 0;
		} else if (type == "s") {
			base = new BlockShape(BlockShape.RectShape, c);
		} else {
			// custom type; subclass is responsible for adding
			// the desired children, setting width and height,
			// and optionally defining the base shape
			return;
		}

		if (type == "c") {
			base.setWidthAndTopHeight(13, 13);
			setArgValue(Color.random());
		} else {
			base.setWidthAndTopHeight(30, 15);
		}
		base.filters = blockArgFilters();
		addChild(base);

		if ((type == "d") || (type == "m")) { // add a menu icon
			menuIcon = new Shape();
			var g:Graphics = menuIcon.graphics;
//			g.beginFill(0x101010);
			g.beginFill(Color.scaleBrightness(base.color, 0.52));
			g.lineTo(7, 0);
			g.lineTo(3.5, 4);
			g.lineTo(0, 0);
			g.endFill();
			menuIcon.y = 5;
			addChild(menuIcon);
		}

		if (editable || isNumber || (type == "m")) { // add a string field
			field = makeTextField();
			if ((type == "m") && !editable) field.textColor = 0xFFFFFF;
			else base.setWidthAndTopHeight(30, 14);
			field.text = isNumber ? "10" : "abc";
			if (isNumber) field.restrict = "0-9e.\\-"; // restrict to numeric characters
			if (editable) {
				base.setColor(0xFFFFFF); // if editable, set color to white
				field.type = TextFieldType.INPUT;
				field.selectable = true;
			}
			addChild(field);
			textChanged(null);
		} else {
			base.redraw();
		}
	}

	public function setArgValue(value:*, label:String = null):void {
		// if provided, label is displayed in field, rather than the value
		// this is used for sprite names and to support translation
		argValue = value;
		if (field != null) {
			var s:String = (value == null) ? "" : value;
			field.text = (label) ? label : s;

			if (!label && (value is Number) && ((value - epsilon) is int)) {
				// Append '.0' to numeric values that are exactly epsilon
				// greather than an integer. See comment in textChanged().
				field.text = (value - epsilon) + '.0';
			}
			textChanged(null);
			argValue = value; // set argValue after textChanged()
			return;
		}
		if (type == "c") base.setColor(int(argValue) & 0xFFFFFF);
		base.redraw();
	}

	private function blockArgFilters():Array {
		// filters for BlockArg outlines
		var f:BevelFilter = new BevelFilter(1);
		f.blurX = f.blurY = 2;
		f.highlightAlpha = 0.3;
		f.shadowAlpha = 0.6;
		f.angle = 240;  // change light angle to show indentation
		return [f];		
	}

	private function makeTextField():TextField {
		var tf:TextField = new TextField();
		var offsets:Array = argTextInsets(type);
		tf.x = offsets[0];
		tf.y = offsets[1];
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.defaultTextFormat = Block.argTextFormat;
		tf.selectable = false;
		tf.addEventListener(Event.CHANGE, textChanged);
		return tf;
	}

	private function argTextInsets(type:String = ''):Array {
		if (type == 'b') return [5, 0];
		return (type == 'n') ? [3, 0] : [2, -1];
	}

	private function textChanged(evt:*):void {
		argValue = field.text;
		if (isNumber) {
			// optimization: coerce to a number if possible
			var n:Number = Number(argValue);
			if (!isNaN(n)) {
				argValue = n;
				if ((field.text.indexOf('.') >= 0) && (argValue is int)) {
					// if text includes a decimal point, make value a float as a signal to
					// primitives (e.g. random) to use real numbers rather than integers.
					// Note: Flash does not appear to distguish between a floating point
					// value with no fractional part and an int of that value. We "mark"
					// arguments like 1.0 by adding a tiny epsilon to force them to be a
					// floating point number. Certain primitives, such as "random", use
					// this to decide whether to work in integers or real numbers.
					argValue += epsilon; 
				}
			}
		}
		// fix layout:
		var padding:int = (type == "n") ? 3 : 0;
		if (type == "b") padding = 8;
		if (menuIcon != null) padding = (type == "d") ? 10 : 13;
		var w:int = Math.max(field.width + padding, 16);
		if (menuIcon) menuIcon.x = w - menuIcon.width - 3;
		base.setWidth(w);
		base.redraw();
		if (parent is Block) Block(parent).fixExpressionLayout();
	}

	private function invokeMenu(evt:MouseEvent):void {
		if ((menuIcon != null) && (evt.localX <= menuIcon.x)) return;
		if (Block.MenuHandlerFunction != null) {
			Block.MenuHandlerFunction(evt, parent, this, menuName);
			evt.stopImmediatePropagation();
		}
	}

}}
