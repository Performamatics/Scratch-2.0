// Primitives.as
// John Maloney, April 2010
//
// Miscellaneous primitives. Registers other primitive modules.
// Note: A few control structure primitives are implemented directly in Interpreter.as.

package primitives {
	import flash.utils.Dictionary;
	import blocks.*;
	import interpreter.*;
	import scratch.ScratchSprite;

public class Primitives {

	private var app:Scratch;
	private var interp:Interpreter;
	private var counter:int;

	public function Primitives(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Dictionary):void {
		// operators
		primTable["+"]				= function(b:*):* { return interp.numarg(b, 0) + interp.numarg(b, 1) };
		primTable["-"]				= function(b:*):* { return interp.numarg(b, 0) - interp.numarg(b, 1) };
		primTable["*"]				= function(b:*):* { return interp.numarg(b, 0) * interp.numarg(b, 1) };
		primTable["/"]				= function(b:*):* { return interp.numarg(b, 0) / interp.numarg(b, 1) };
		primTable["randomFrom:to:"]	= primRandom;
		primTable["<"]				= function(b:*):* { return compare(interp.arg(b, 0), interp.arg(b, 1)) < 0 };
		primTable["="]				= function(b:*):* { return compare(interp.arg(b, 0), interp.arg(b, 1)) == 0 };
		primTable[">"]				= function(b:*):* { return compare(interp.arg(b, 0), interp.arg(b, 1)) > 0 };
		primTable["&"]				= function(b:*):* { return interp.arg(b, 0) && interp.arg(b, 1) };
		primTable["|"]				= function(b:*):* { return interp.arg(b, 0) || interp.arg(b, 1) };
		primTable["not"]			= function(b:*):* { return !interp.arg(b, 0) };
		primTable["abs"]			= function(b:*):* { return Math.abs(interp.numarg(b, 0)) };
		primTable["sqrt"]			= function(b:*):* { return Math.sqrt(interp.numarg(b, 0)) };

		primTable["concatenate:with:"]	= function(b:*):* { return "" + interp.arg(b, 0) + interp.arg(b, 1) };
		primTable["letter:of:"]			= primLetterOf;
		primTable["stringLength:"]		= function(b:*):* { return String(interp.arg(b, 0)).length };

		primTable["\\\\"]				= primModulo;
		primTable["rounded"]			= function(b:*):* { return Math.round(interp.numarg(b, 0)) };
		primTable["computeFunction:of:"] = primMathFunction;

		// output (for development)
		primTable["PRINT"]		= primPrintLine;
		primTable["PRS"]		= primPrintString;
		primTable["CLR_TEXT"]	= primClearLog;

		// testing (for development)
		primTable["NOOP"]		= interp.primNoop;
		primTable["COUNT"]		= function(b:*):* { return counter };
		primTable["INCR_COUNT"]	= function(b:*):* { counter++ };
		primTable["CLR_COUNT"]	= function(b:*):* { counter = 0 };

		// clone
		primTable["createClone"]		= primCreateClone;		
		primTable["deleteClone"]		= primDeleteClone;		
		primTable[Specs.CLONE_START]	= interp.primNoop;

		new MidiPrims(app, interp).addPrimsTo(primTable);
		new ListPrims(app, interp).addPrimsTo(primTable);
		new LooksPrims(app, interp).addPrimsTo(primTable);
		new MotionAndPenPrims(app, interp).addPrimsTo(primTable);
		new SensingPrims(app, interp).addPrimsTo(primTable);
		new SoundPrims(app, interp).addPrimsTo(primTable);
		new VideoFacePrims(app, interp).addPrimsTo(primTable);
		new VideoMotionPrims(app, interp).addPrimsTo(primTable);
		new VideoSensePrims(app, interp).addPrimsTo(primTable);
		new WeDoPrims(app, interp).addPrimsTo(primTable);
	}

	private function primRandom(b:Block):Number {
		var n1:Number = interp.numarg(b, 0);
		var n2:Number = interp.numarg(b, 1);
		var low:Number = (n1 <= n2) ? n1 : n2;
		var hi:Number = (n1 <= n2) ? n2 : n1;
		if (low == hi) return low;
		// if both low and hi are ints, truncate the result to an int
		if ((int(low) == low) && (int(hi) == hi)) {
			return low + int(Math.random() * ((hi + 1) - low));
		}
		return (Math.random() * (hi - low)) + low;
	}

	private function primLetterOf(b:Block):String {
		var s:String = interp.arg(b, 1);
		var i:int = interp.numarg(b, 0) - 1;
		if ((i < 0) || (i >= s.length)) return "";
		return s.charAt(i);
	}

	private function primModulo(b:Block):Number {
		var modulus:Number = interp.numarg(b, 1);
		var n:Number = interp.numarg(b, 0) % modulus;
		if (n < 0) n += modulus;
		return n;
	}

	private function primMathFunction(b:Block):Number {
		var op:* = interp.arg(b, 0);
		var n:Number = interp.numarg(b, 1);
		switch(op) {
		case "abs": return Math.abs(n);
		case "sqrt": return Math.sqrt(n);
		case "sin": return Math.sin((Math.PI * n) / 180);
		case "cos": return Math.cos((Math.PI * n) / 180);
		case "tan": return Math.tan((Math.PI * n) / 180);
		case "asin": return (Math.asin(n) * 180) / Math.PI;
		case "acos": return (Math.acos(n) * 180) / Math.PI;
		case "atan": return (Math.atan(n) * 180) / Math.PI;
		case "ln": return Math.log(n);
		case "log": return Math.log(n) / Math.LN10; 
		case "e ^": return Math.exp(n);
		case "10 ^": return Math.exp(n * Math.LN10);
		}
		return 0;
	}

	private function primPrintLine(b:Block):void {
		app.logPrint(interp.arg(b, 0), true);
		interp.redraw();
	}

	private function primPrintString(b:Block):void {
		app.logPrint(interp.arg(b, 0), false);
		interp.redraw();
	}

	private function primClearLog(b:Block):void {
		app.logClear();
		interp.redraw();
	}

	public static function compare(a1:*, a2:*):int {
		// This is static so it can be used by the list "contains" primitive.
		var n1:Number = asNumber(a1);
		var n2:Number = asNumber(a2);
		if (isNaN(n1) || isNaN(n2)) {
			// at least one argument can't be converted to a number: compare as strings
			var s1:String = String(a1).toLowerCase();
			var s2:String = String(a2).toLowerCase();
			return s1.localeCompare(s2);
		} else {
			// compare as numbers
			if (n1 < n2) return -1;
			if (n1 == n2) return 0;
			if (n1 > n2) return 1;
		}
		return 1;
	}

	private static function asNumber(n:*):Number {
		// Convert n to a number if possible. If n is a string, it must contain
		// at least one digit to be treated as a number (otherwise a string
		// containing only whitespace would be consider equal to zero.)
		var digits:String = '0123456789';
		if (typeof(n) == 'string') {
			var s:String = n as String;
			for (var i:int = 0; i < s.length; i++) {
				if (digits.indexOf(s.charAt(i)) >= 0) return Number(s);
			}
			return NaN; // no digits found; string is not a number
		}
		return Number(n);
	}

	private function primCreateClone(b:Block):void {
		const MaxCloneCount:int = 1000;
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return;
		if (app.runtime.cloneCount > MaxCloneCount) return;
		var clone:ScratchSprite = new ScratchSprite();
		clone.initFrom(s, true);
		clone.objName = 'clone';
		clone.isClone = true;
		app.stagePane.addChildAt(clone, app.stagePane.getChildIndex(s));
		for each (var stack:Block in clone.scripts) {
			if (stack.op == Specs.CLONE_START) {
				interp.startThreadForClone(stack, clone);
			}
		}
		app.runtime.cloneCount++;
	}

	private function primDeleteClone(b:Block):void {
		var clone:ScratchSprite = interp.targetSprite();
		if ((clone == null) || (!clone.isClone) || (clone.parent == null)) return;
		clone.parent.removeChild(clone);
		app.interp.stopThreadsForClone(clone);
		app.runtime.cloneCount--;
	}

}}
