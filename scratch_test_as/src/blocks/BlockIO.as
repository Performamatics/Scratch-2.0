// BlockIO.as
// John Maloney, September 2010
//
// Convert blocks and stacks to/from an array structure or JSON string format.
// The array structure format captures the meaning of scripts in a compact form that
// is independent of the internal representation and is easy to convert to/from JSON.

package blocks {
	import scratch.*;
	import util.*;

public class BlockIO {

	public static function stackToString(b:Block):String {
		return JSON_AB.stringify(stackToArray(b));
	}

	public static function stringToStack(s:String):Block {
		return arrayToStack(JSON_AB.parse(s) as Array);
	}

	public static function stackToArray(b:Block):Array {
		// Return an array structure representing this entire stack.
		if (b == null) return null;
		var result:Array = [];
		while (b != null) {
			result.push(blockToArray(b));
			b = b.nextBlock;
		}
		return result;
	}

	public static function arrayToStack(cmdList:Array):Block {
		// Return the stack represented by an array structure.
		var topBlock:Block, lastBlock:Block;
		for each (var cmd:Array in cmdList) {
			var b:Block = arrayToBlock(cmd);
			if (topBlock == null) topBlock = b;
			if (lastBlock != null) lastBlock.insertBlock(b);
			lastBlock = b;
		}
		return topBlock;
	}

	private static function blockToArray(b:Block):Array {
		// Return an array structure for this block.
		var result:Array = [b.op];
		if (b.op == Specs.GET_VAR) return [Specs.GET_VAR, b.spec];		// variable reporter
		if (b.op == Specs.GET_LIST) return [Specs.GET_LIST, b.spec];	// list reporter
		if (b.op == Specs.GET_PARAM) return [Specs.GET_PARAM, b.spec];	// parameter reporter
		if (b.op == Specs.PROCEDURE_DEF)								// procedure definition
			return [Specs.PROCEDURE_DEF, b.spec, b.parameterNames, b.defaultArgValues];
		if (b.op == Specs.CALL) result = [Specs.CALL, b.spec];			// procedure call - arguments follow spec
		for each (var a:* in b.args) {
			if (a is Block) result.push(blockToArray(a));
			if (a is BlockArg) {
				var argVal:* = BlockArg(a).argValue;
				if (argVal is ScratchObj) {
					// convert a Scratch sprite/stage reference to a name string
					argVal = ScratchObj(argVal).objName;
				}
				result.push(argVal);
			}
		}
		if (b.base.canHaveSubstack1()) result.push(stackToArray(b.subStack1));
		if (b.base.canHaveSubstack2()) result.push(stackToArray(b.subStack2));
		return result;
	}

	private static function arrayToBlock(cmd:Array, undefinedBlockType:String = ""):Block {
		// Make a block from an array of form: <op><arg>*
		var special:Block = specialCmd(cmd);
		if (special) { special.fixArgLayout(); return special }
		var b:Block;
		if (cmd[0] == Specs.CALL) {
			b = new Block(cmd[1], "", Specs.procedureCallColor, Specs.CALL);
			cmd.splice(0, 1);
		} else {
			var spec:Array = specForCmd(cmd, undefinedBlockType);
			b = new Block(spec[0], spec[1], Specs.blockColor(spec[2]), spec[3]);
		}
		var args:Array = argsForCmd(cmd);
		var substacks:Array = substacksForCmd(cmd);
		for (var i:int = 0; i < args.length; i++) {
			var a:* = args[i];
			if (a is ScratchObj) a = ScratchObj(a).objName; // convert Scratch 1.4 direct-reference into sprite name
			b.setArg(i, a);
		}
		if (substacks[0] && (b.base.canHaveSubstack1())) b.insertBlockSub1(substacks[0]);
		if (substacks[1] && (b.base.canHaveSubstack2())) b.insertBlockSub2(substacks[1]);
		fixMouseEdgeRefs(b);
		b.fixArgLayout();
		return b;
	}

	private static function specForCmd(cmd:Array, undefinedBlockType:String):Array {
		// Return the block specification for the given command.
		var op:String = cmd[0];
		for each (var entry:Array in Specs.commands) {
			if (entry[3] == op) return entry;
		}
		return [op, undefinedBlockType, 0, "undefined"]; // no match found
	}

	private static function argsForCmd(cmd:Array):Array {
		// Return an array of zero or more arguments for the given command.
		// Skip substacks. Arguments may be literal values or reporter blocks (expressions).
		var result:Array = [];
		for (var i:int = 1; i < cmd.length; i++) {
			var a:* = cmd[i];
			if (a is Array) {
				// block (skip if substack)
				if (!(a[0] is Array)) result.push(arrayToBlock(a, "r"));
			} else {
				// literal value
				result.push(a);
			}
		}
		return result;
	}

	private static function substacksForCmd(cmd:Array):Array {
		// Return an array of zero or more substacks for the given command.
		var result:Array = [];
		for (var i:int = 1; i < cmd.length; i++) {
			var a:* = cmd[i];
			if (a == null) result.push(null); // null indicates an empty stack
			// a is substack if (1) it is an array and (2) it's first element is an array (vs. a String)
			if ((a is Array) && (a[0] is Array)) result.push(arrayToStack(a));
		}
		return result;
	}

	private static function specialCmd(cmd:Array):Block {
		// If the given command is special (e.g. a reporter or old-style a hat blocK), return a block for it.
		// Otherwise, return null.
		var b:Block, c:int;
		switch (cmd[0]) {
		case Specs.GET_VAR:
			c = Specs.blockColor(Specs.variablesCategory);
			return new Block(cmd[1], "r", c, Specs.GET_VAR);
		case Specs.GET_LIST:
			c = Specs.blockColor(Specs.variablesCategory);
			return new Block(cmd[1], "r", c, Specs.GET_LIST);
		case Specs.PROCEDURE_DEF:
			c = Specs.blockColor(Specs.controlCategory);
			b = new Block("", "p", c, Specs.PROCEDURE_DEF);
			b.parameterNames = cmd[2];
			b.defaultArgValues = cmd[3];
			b.setSpec(cmd[1]);
			b.fixArgLayout();
			return b;
		case Specs.GET_PARAM:
			return new Block(cmd[1], "r", Specs.parameterColor, Specs.GET_PARAM);
		case "changeVariable":
			c = Specs.blockColor(Specs.variablesCategory);
			var varOp:String = cmd[2];
			if (varOp == Specs.SET_VAR) {
				b = new Block("set %v to %s", " ", c, Specs.SET_VAR);
			} else if (varOp == Specs.CHANGE_VAR) {
				b = new Block("change %v by %n", " ", c, Specs.CHANGE_VAR);
			}
			if (b == null) return null;
			var arg:* = cmd[3];
			if (arg is Array) arg = arrayToBlock(arg, "r");
			b.setArg(0, cmd[1]);
			b.setArg(1, arg);
			return b;
		case "EventHatMorph":
			c = Specs.blockColor(Specs.controlCategory);
			if (cmd[1] == "Scratch-StartClicked") {
				return new Block("when @greenFlag clicked", "h", c, "whenGreenFlag");
			}
			b = new Block("when I receive %m.broadcast", "h", c, "whenIReceive");
			b.setArg(0, cmd[1]);
			return b;
		case "MouseClickEventHatMorph":
			c = Specs.blockColor(Specs.controlCategory);
			b = new Block("when I am clicked", "h", c, "whenClicked");
			return b;
		case "KeyEventHatMorph":
			c = Specs.blockColor(Specs.controlCategory);
			b = new Block("when %m.key key pressed", "h", c, "whenKeyPressed");
			b.setArg(0, cmd[1]);
			return b;
		}
		return null;
	}

	private static function fixMouseEdgeRefs(b:Block):void {
		var refCmds:Array = ["pointTowards:", "gotoSpriteOrMouse:", "distanceTo:", "touching:"];
		if (refCmds.indexOf(b.op) < 0) return;
		if (b.args[0] is BlockArg) {
			var arg:BlockArg = b.args[0];
			var oldVal:String = arg.argValue;
			if ((oldVal == "edge") || (oldVal == "_edge_")) arg.setArgValue("_edge_", "edge");
			if ((oldVal == "mouse") || (oldVal == "_mouse_")) arg.setArgValue("_mouse_", "mouse-pointer");
		}
	}

}}