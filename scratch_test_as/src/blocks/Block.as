// Block.as
// John Maloney, August 2009
//
// A Block is a graphical object representing a program statement (command)
// or function (reporter). A stack is a sequence of command blocks, where
// the following command and any nested commands (e.g. within a loop) are
// children. Blocks come in a variety of shapes and usually have some
// combination of label strings and arguments (also children).
//
// The Block class manages block shape, labels, arguments, layout, and
// block sequence. It also supports generation of the labels and argument
// sequence from a specification string (e.g. "%n + %n") and type (e.g. reporter).

package blocks {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.GlowFilter;
	import flash.geom.*;
	import flash.text.*;
	import interpreter.*;
	import util.*;
	import uiwidgets.ScriptsPane;

public class Block extends Sprite {

	public static const blockLabelFormat:TextFormat = new TextFormat('Lucida Grande', 10, 0xFFFFFF, true);
	public static const argTextFormat:TextFormat = new TextFormat('Lucida Grande', 9, 0x3030300, true);

	public static var MenuHandlerFunction:Function;	// optional function to handle block and blockArg menus

	public var spec:String;
	public var type:String;
	public var op:String = "";
	public var opFunction:Function;
	public var args:Array = [];
	public var defaultArgValues:Array = [];
	public var cache:*;					// cache used by variable and list blocks
	public var parameterIndex:int = -1;	// cache of parameter index, used by GET_PARAM block
	public var parameterNames:Array;	// used by procedure definition hats; null for other blocks

	public var isHat:Boolean = false;
	public var isReporter:Boolean = false;
	public var isTerminal:Boolean = false;	//  blocks that end a stack like "stop" or "forever"

	public var nextBlock:Block;
	public var subStack1:Block;
	public var subStack2:Block;
	
	public var base:BlockShape;

	private var suppressLayout:Boolean; // used to avoid extra layouts during block initialization 
	private var labelsAndArgs:Array = [];
	private var argTypes:Array = [];

	private var indentTop:int = 2, indentBottom:int = 3;
	private var indentLeft:int = 4, indentRight:int = 3;

	public var wasInScriptsPane:Boolean;
	private var originalX:int, originalY:int;

	public function Block(spec:String, type:String = " ", color:int = 0xD00000, op:* = 0, defaultArgs:Array = null) {
		this.spec = Translator.map(spec);
		this.type = type;
		this.op = op;
		if (color == -1) return; // copy for clone; omit graphics

		var shape:int;
		if ((type == " ") || (type == "")) {
			base = new BlockShape(BlockShape.CmdShape, color);
			indentTop = 3;
		} else if (type == "b") {
			base = new BlockShape(BlockShape.BooleanShape, color);
			isReporter = true;
			indentLeft = 9;
			indentRight = 7;
		} else if (type == "r") {
			base = new BlockShape(BlockShape.NumberShape, color);	
			isReporter = true;
			indentTop = 2;
			indentBottom = 2;
			indentLeft = 6;
			indentRight = 4;
		} else if (type == "h") {
			base = new BlockShape(BlockShape.HatShape, color);
			isHat = true;
			indentTop = 12;
		} else if (type == "c") {
			base = new BlockShape(BlockShape.LoopShape, color);
		} else if (type == "cf") {
			base = new BlockShape(BlockShape.FinalLoopShape, color);
			isTerminal = true;
		} else if (type == "e") {
			base = new BlockShape(BlockShape.IfElseShape, color);
		} else if (type == "f") {
			base = new BlockShape(BlockShape.FinalCmdShape, color);
			isTerminal = true;
			indentTop = 5;
		} else if (type == "o") { // cmd outline for proc definition
			base = new BlockShape(BlockShape.CmdOutlineShape, color);
			base.filters = []; // no bezel
			indentTop = 3;
		} else if (type == "p") {
			base = new BlockShape(BlockShape.ProcHatShape, color);
			isHat = true;
		} else {
			base = new BlockShape(BlockShape.RectShape, color);
		}
		addChild(base);
		setSpec(this.spec, defaultArgs);

		addEventListener(MouseEvent.MOUSE_DOWN, blockMenu);
		addEventListener(MouseEvent.MOUSE_UP, blockMenu);
		addEventListener(FocusEvent.KEY_FOCUS_CHANGE, focusChange);
	}

	public function setSpec(newSpec:String, defaultArgs:Array = null):void {
		for each (var o:DisplayObject in labelsAndArgs) {
			if (o.parent != null) o.parent.removeChild(o);
		}
		spec = newSpec;
		if (op == Specs.PROCEDURE_DEF) {
			// procedure hat: make an icon from my spec and use that as the label
			base.color = Specs.blockColor(Specs.triggersCategory);
			indentTop = 20;
			indentBottom = 5;
			indentLeft = 5;
			indentRight = 5;

			labelsAndArgs = [];
			argTypes = [];
			var label:TextField = makeLabel('define');
			labelsAndArgs.push(label);
			addChild(label);
			var b:Block = declarationBlock();
			labelsAndArgs.push(b);
			addChild(b);
		} else {
			addLabelsAndArgs(spec, base.color);
			if (defaultArgs) setDefaultArgs(defaultArgs) else fixArgLayout();
		}
		fixArgLayout();
	}

	private function declarationBlock():Block {
		// Create a block representing a procedure declaration to be embedded in a
		// procedure definition header block. For each formal parameter, embed a
		// reporter for that parameter.
		var b:Block = new Block(spec, "o", Specs.procedureCallColor, 'proc_declaration');
		if (!parameterNames) parameterNames = [];
		for (var i:int = 0; i < parameterNames.length; i++) {
			var argType:String = (typeof(defaultArgValues[i]) == 'boolean') ? 'b' : 'r';
			var pBlock:Block = new Block(parameterNames[i], argType, Specs.parameterColor, Specs.GET_PARAM);
			pBlock.parameterIndex = i;
			b.setArg(i, pBlock);
		}
		b.fixArgLayout();
		return b;
	}

	public function isEmbeddedInProcHat():Boolean {
		return (parent is Block) &&
			(Block(parent).op == Specs.PROCEDURE_DEF) &&
			(this != Block(parent).nextBlock);
	}

	public function isEmbeddeParameter():Boolean {
		if ((op != Specs.GET_PARAM) || !(parent is Block)) return false;
		return Block(parent).op == 'proc_declaration';
	}

	private function addLabelsAndArgs(spec:String, c:int):void {
		var specParts:Array = ReadStream.tokenize(spec), i:int;
		labelsAndArgs = [];
		argTypes = [];
		for (i = 0; i < specParts.length; i++) {
			var o:DisplayObject = argOrLabelFor(specParts[i], c);
			labelsAndArgs.push(o);
			var argType:String = 'icon';
			if (o is BlockArg) argType = specParts[i];
			if (o is TextField) argType = 'label';
			argTypes.push(argType);
			addChild(o);
		}
	}

	public function allBlocksDo(f:Function):void {
		f(this);
		for each (var arg:* in args) {
			if (arg is Block) arg.allBlocksDo(f);
		}
		if (subStack1 != null) subStack1.allBlocksDo(f);
		if (subStack2 != null) subStack2.allBlocksDo(f);
		if (nextBlock != null) nextBlock.allBlocksDo(f);
	}

	public function showRunFeedback():void {
		if (!filters || (filters.length == 0)) {
			filters = runFeedbackFilters();
		}
	}

	public function hideRunFeedback():void {
		if (filters && (filters.length > 0)) filters = [];
	}

	private function runFeedbackFilters():Array {
		// filters for showing that a stack is running
		var f:GlowFilter = new GlowFilter(0xfeffa0); 
		f.strength = 2;
		f.blurX = f.blurY = 12;
		f.quality = 3;
		return [f];
	}
	public function saveOriginalPosition():void {
		wasInScriptsPane = topBlock().parent is ScriptsPane;
		originalX = x;
		originalY = y;
	}

	public function restoreOriginalPosition():void {
		x = originalX;
		y = originalY;
	}

	private function setDefaultArgs(defaults:Array):void {
		collectArgs();
		for (var i:int = 0; i < Math.min(args.length, defaults.length); i++) {
			var v:* = defaults[i];
			if (v is BlockArg) v = BlockArg(v).argValue;
			if (args[i] is BlockArg) args[i].setArgValue(v);
		}
		defaultArgValues = defaults;
		fixArgLayout();
	}

	public function setArg(i:int, newArg:*):void {
		// called on newly-created block (assumes argument being set is a BlockArg)
		// newArg can be either a reporter block or a literal value (string, number, etc.)
		collectArgs();
		if (i >= args.length) return;
		var oldArg:BlockArg = args[i];
		if (newArg is Block) {
			labelsAndArgs[labelsAndArgs.indexOf(oldArg)] = newArg;
			args[i] = newArg;
			removeChild(oldArg);
			addChild(newArg);
		} else {
			oldArg.setArgValue(newArg);
		}	
	}

	public function fixExpressionLayout():void {
		// fix expression layout up to the enclosing command block
		var b:Block = this;
		while (b.isReporter) {
			b.fixArgLayout();
			if (b.parent is Block) b = Block(b.parent)
			else return;
		}
		if (b is Block) b.fixArgLayout();
	}

	public function fixArgLayout():void {
		var item:DisplayObject, i:int;
		if (suppressLayout) return;
		var x:int = indentLeft - indentAjustmentFor(labelsAndArgs[0]);
		var maxH:int = 0;
		for (i = 0; i < labelsAndArgs.length; i++) {
			item = labelsAndArgs[i];
			item.x = x;
			maxH = Math.max(maxH, item.height);
			x += item.width + 2;
			if (argTypes[i] == 'icon') x += 3;
		}
		x -= indentAjustmentFor(labelsAndArgs[labelsAndArgs.length - 1]);

		for (i = 0; i < labelsAndArgs.length; i++) {
			item = labelsAndArgs[i];
			item.y = indentTop + ((maxH - item.height) / 2);
			if ((item is BlockArg) && (!BlockArg(item).isNumber)) item.y += 1;
		}
		base.setWidthAndTopHeight(x + indentRight, indentTop + maxH + indentBottom);
		if ((type == "c") || (type == "e")) fixStackLayout();
		base.redraw();
		collectArgs();
	}

	private function indentAjustmentFor(item:*):int {
		var itemType:String = '';
		if (item is Block) itemType = Block(item).type;
		if (item is BlockArg) itemType = BlockArg(item).type;	
		if ((type == 'b') && (itemType == 'b')) return 4;
		if ((type == 'r') && ((itemType == 'r') || (itemType == 'd') || (itemType == 'n'))) return 2;
		return 0;
	}

	public function fixStackLayout():void {
		var b:Block = this;
		while (b != null) {
			if (b.base.canHaveSubstack1()) {
				var substackH:int = BlockShape.EmptySubstackH;
				if (b.subStack1) {
					b.subStack1.fixStackLayout();
					b.subStack1.x = BlockShape.SubstackInset;
					b.subStack1.y = b.base.substack1y();
					substackH = b.subStack1.getRect(b).height;
				}
				b.base.setSubstack1Height(substackH);
				substackH = BlockShape.EmptySubstackH;
				if (b.subStack2) {
					b.subStack2.fixStackLayout();
					b.subStack2.x = BlockShape.SubstackInset;
					b.subStack2.y = b.base.substack2y();
					substackH = b.subStack2.getRect(b).height;
				}
				b.base.setSubstack2Height(substackH);
				b.base.redraw();
			}
			if (b.nextBlock != null) {
				b.nextBlock.x = 0;
				b.nextBlock.y = b.base.height - BlockShape.NotchDepth;
			}
			b = b.nextBlock;
		}
	}

	public function duplicate(forClone:Boolean):Block {
		var dup:Block = new Block(spec, type, (forClone ? -1 : base.color), op);
		dup.defaultArgValues = defaultArgValues;
		dup.parameterNames = parameterNames;
		if (forClone) dup.copyArgsForClone(args); else dup.copyArgs(args);
		if (nextBlock != null) dup.addChild(dup.nextBlock = nextBlock.duplicate(forClone));
		if (subStack1 != null) dup.addChild(dup.subStack1 = subStack1.duplicate(forClone));
		if (subStack2 != null) dup.addChild(dup.subStack2 = subStack2.duplicate(forClone));
		if (!forClone) {
			dup.x = x;
			dup.y = y;
			dup.fixExpressionLayout();
			dup.fixStackLayout();
		}
		return dup;
	}

	private function copyArgs(srcArgs:Array):void {
		// called on a newly created block that is being duplicated to copy the
		// argument values and/or expressions from the source block's arguments
		var i:int;
		collectArgs();
		for (i = 0; i < srcArgs.length; i++) {
			var argToCopy:* = srcArgs[i];
			if (argToCopy is BlockArg) BlockArg(args[i]).setArgValue(BlockArg(argToCopy).argValue);
			if (argToCopy is Block) {
				var newArg:Block = Block(argToCopy).duplicate(false);
				var oldArg:* = args[i];
				labelsAndArgs[labelsAndArgs.indexOf(oldArg)] = newArg;
				args[i] = newArg;
				removeChild(oldArg);
				addChild(newArg);
			}
		}
	}

	private function copyArgsForClone(srcArgs:Array):void {
		// called on a block that is being cloned.
		args = [];
		for (var i:int = 0; i < srcArgs.length; i++) {
			var argToCopy:* = srcArgs[i];
			if (argToCopy is BlockArg) {
				var a:BlockArg = new BlockArg(argToCopy.type, -1);
				a.argValue = argToCopy.argValue;
				args.push(a);
			}
			if (argToCopy is Block) {
				args.push(Block(argToCopy).duplicate(true));
			}
		}
	}

	private function collectArgs():void {
		var i:int;
		args = [];
		for (i = 0; i < labelsAndArgs.length; i++) {
			var a:* = labelsAndArgs[i];
			if ((a is Block) || (a is BlockArg)) args.push(a);
		}
	}

	public function removeBlock(b:Block):void {
		if (b.parent == this) removeChild(b);
		if (b == nextBlock) nextBlock = null;
		if (b == subStack1) subStack1 = null;
		if (b == subStack2) subStack2 = null;
		if (b.isReporter) {
			var i:int = labelsAndArgs.indexOf(b);
			if (i < 0) return;
			var newArg:DisplayObject = argOrLabelFor(argTypes[i], base.color);
			labelsAndArgs[i] = newArg;
			addChild(newArg);
			fixExpressionLayout();
		}
		topBlock().fixStackLayout();
	}

	public function insertBlock(b:Block):void {
		var oldNext:Block = nextBlock;

		if (oldNext != null) removeChild(oldNext);

		addChild(b);
		nextBlock = b;
		if (oldNext != null) b.appendBlock(oldNext);
		topBlock().fixStackLayout();
	}

	public function insertBlockAbove(b:Block):void {
		if (b.nextBlock != null) b.removeChild(b.nextBlock);
		b.x = this.x;
		b.y = this.y - b.height + BlockShape.NotchDepth;
		parent.addChild(b);
		b.insertBlock(this);
	}

	public function insertBlockSub1(b:Block):void {
		var old:Block = subStack1;
		if (old != null) old.parent.removeChild(old);

		addChild(b);
		subStack1 = b;
		if (old != null) b.appendBlock(old);
		topBlock().fixStackLayout();
	}

	public function insertBlockSub2(b:Block):void {
		var old:Block = subStack2;
		if (old != null) removeChild(old);

		addChild(b);
		subStack2 = b;
		if (old != null) b.appendBlock(old);
		topBlock().fixStackLayout();
	}

	public function replaceArgWithBlock(oldArg:DisplayObject, b:Block, pane:DisplayObjectContainer):void {
		var i:int = labelsAndArgs.indexOf(oldArg);
		if (i < 0) return;
		
		// remove the old argument
		removeChild(oldArg);
		labelsAndArgs[i] = b;
		addChild(b);
		fixExpressionLayout();

		if (oldArg is Block) {
			// leave old block in pane
			var o:Block = owningBlock();
			var p:Point = pane.globalToLocal(o.localToGlobal(new Point(o.width + 5, (o.height - oldArg.height) / 2)));
			oldArg.x = p.x;
			oldArg.y = p.y;
			pane.addChild(oldArg);
		}
		topBlock().fixStackLayout();
	}

	private function appendBlock(b:Block):void {
		var bottom:Block = bottomBlock();
		bottom.addChild(b);
		bottom.nextBlock = b;
	}

	private function owningBlock():Block {
		var b:Block = this;
		while (true) {
			if (b.parent is Block) {
				b = Block(b.parent);
				if (!b.isReporter) return b; // owning command block
			} else {
				return b; // top-level reporter block
			}
		}
		return b; // never gets here
	}

	public function topBlock():Block {
		var result:DisplayObject = this;
		while (result.parent is Block) result = result.parent;
		return Block(result);
	}

	public function bottomBlock():Block {
		var result:Block = this;
		while (result.nextBlock!= null) result = result.nextBlock;
		return result;
	}

	private function argOrLabelFor(s:String, c:int):DisplayObject {
		// Possible token formats:
		//	%<single letter>
		//	%m.<menuName>
		//	@<iconName>
		//	label (any string with no embedded white space that does not start with % or @)
		//	a token consisting of a single % or @ character is also a label
		if ((s.length >= 2) && (s.charAt(0) == "%")) { // argument spec
			var argSpec:String = s.charAt(1);
			if (argSpec == "b") return new BlockArg("b", c);
			if (argSpec == "c") return new BlockArg("c", c);
			if (argSpec == "d") return new BlockArg("d", c, true, s.slice(3));
			if (argSpec == "m") return new BlockArg("m", c, false, s.slice(3));
			if (argSpec == "n") return new BlockArg("n", c, true);
			if (argSpec == "s") return new BlockArg("s", c, true);
			if (argSpec == "v") return new BlockArg("v", c, false, "varMenu");
		} else if ((s.length >= 2) && (s.charAt(0) == "@")) { // icon spec
			var icon:* = Specs.IconNamed(s.slice(1));
			return (icon) ? icon : makeLabel(s);
		}
		return makeLabel(s);
	}

	private function makeLabel(label:String):TextField {
		var text:TextField = new TextField();
		text.autoSize = TextFieldAutoSize.LEFT;
		text.selectable = false;
		text.background = false;
		text.text = label;
		text.setTextFormat(blockLabelFormat);
		text.mouseEnabled = false;
		return text;
	}

	private function blockMenu(evt:MouseEvent):void {
		if (!evt.shiftKey) return;
		evt.stopImmediatePropagation();
		if (MenuHandlerFunction == null) return;
		if (evt.type == MouseEvent.MOUSE_UP) {
			if (isEmbeddedInProcHat()) MenuHandlerFunction(evt, parent);
			else MenuHandlerFunction(evt, this);
		}
	}

	private function focusChange(evt:Event):void {
		evt.preventDefault();
		if (evt.target.parent.parent != this) return;  // make sure the target TextField is in this block, not a child block
		if (args.length == 0) return;
		var i:int, focusIndex:int = -1;
		for (i = 0; i < args.length; i++) {
			if (stage.focus == args[i].field) focusIndex = i;
		}
		i = focusIndex + 1;
		while (true) {
			if (i >= args.length) i = 0;
			var f:TextField = args[i].field;
			if ((f != null) && f.selectable) {
				stage.focus = args[i].field;
				args[i].field.setSelection(0, 10000000);
				return;
			}
			i++
			if (i == (focusIndex + 1)) return;
		}
	}

}}
