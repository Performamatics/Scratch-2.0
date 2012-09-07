// Thread.as
// John Maloney, March 2010
//
// Thread is an internal data structure used by the interpreter. It holds the
// state of a thread so it can continue from where it left off, and it has
// a stack to support nested control structures.

package interpreter {
	import blocks.Block;
	
public class Thread {

	public var topBlock:Block;		// top block of the stack
	public var target:*;			// object that owns the stack
	public var tmpObj:*;			// temporary object (not saved on stack)

	// the stack
	private var stack:Array = [];
	private var sp:int = 0;

	// the following state is pushed and popped when running substacks
	public var block:Block;
	public var isLoop:Boolean;
	public var args:Array;			// arguments to a user-defined procedure
	public var firstTime:Boolean;	// used by certain control structures
	public var tmp:int;				// used by repeat and wait
	public var list:Array;			// used by forall
	public var loopVar:Variable;	// used by forall

	public function Thread(b:Block, targetObj:*) {
		topBlock = b;
		initForBlock(b);
		target = targetObj;
	}

	public function pushStateForBlock(b:Block):void {
		if (sp >= (stack.length - 1)) growStack();
		var old:StackFrame = stack[sp++];
		old.block = block;
		old.isLoop = isLoop;
		old.args = args;
		old.firstTime = firstTime;
		old.tmp = tmp;
		old.list = list;
		old.loopVar = loopVar;
		initForBlock(b);
	}

	public function popState():Boolean {
		if (sp == 0) return false;
		var old:StackFrame = stack[--sp];
		block		= old.block;
		isLoop		= old.isLoop;
		args		= old.args;
		firstTime	= old.firstTime;
		tmp			= old.tmp;
		list		= old.list;
		loopVar		= old.loopVar;
		return true;
	}

	public function stackEmpty():Boolean { return sp == 0 }

	public function stop():void {
		block = null;
		stack = [];
		sp = 0;
	}

	private function initForBlock(b:Block):void {
		block = b;
		isLoop = false;
		firstTime = true;
		tmp = 0;
		list = null;
		loopVar = null;
	}

	private function growStack():void {
		// The stack is an array of Thread instances, pre-allocated for efficiency.
		// When growing, the current size is doubled. Grows by 8 the first time.
		var n:int = Math.max(stack.length, 8);
		for (var i:int = 0; i < n; i++) stack.push(new StackFrame());
	}

	public function returnFromProcedure():Boolean {
		for (var i:int = sp - 1; i >= 0; i--) {
			if (stack[i].block.op == Specs.CALL) {
				sp = i + 1;
				popState();
				return true;
			}
		}
		return false;
	}

}}

import blocks.*;
import interpreter.*;

class StackFrame {
	internal var block:Block;
	internal var isLoop:Boolean;
	internal var args:Array;
	internal var firstTime:Boolean;
	internal var tmp:int;
	internal var list:Array;
	internal var loopVar:Variable;
}
