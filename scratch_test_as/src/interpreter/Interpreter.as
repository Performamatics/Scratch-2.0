// Interpreter.as
// John Maloney, August 2009
// Revised, March 2010
//
// A simple yet efficient interpreter for blocks.
//
// Interpreters may seem mysterious, but this one is quite straightforward. Since every
// block knows which block (if any) follows it in a sequence of blocks, the interpreter
// simply executes the current block, then asks that block for the next block. The heart
// of the interpreter is the evalCmd() function, which looks up the opcode string in a
// dictionary (initialized by initPrims()) then calls the primitive function for that opcode.
// Control structures are handled by pushing the current state onto the active thread's
// execution stack and continuing with the first block of the substack. When the end of a
// substack is reached, the previous execution state is popped. If the substack was a loop
// body, control yields to the next thread. Otherwise, execution continues with the next
// block. If there is no next block, and no state to pop, the thread terminates.
//
// The interpreter does as much as it can within WorkTime milliseconds, then returns
// control. It returns control earlier if either (a) there are are no more threads
// to run or (b) some thread does an output command.
//
// To add a command to the interpreter, just add a new case to initPrims(). Command blocks
// usually perform some operation and return null, while reporters must return a value.
// Control structures are a little tricky; look at some of the existing control structure
// commands to get a sense of what to do.
//
// Clocks and time:
//
// The millisecond clock starts at zero when  Flash  is started and, since the clock is
// a 32-bit integer, it wraps after 24.86 days. Since it seems unlikely that one Scratch
// session would run that long, this code doesn't deal with clock wrapping.
// Since Scratch only runs at discrete intervals, timed commands may be resumed a few
// milliseconds late. These small errors accumulate, causing threads to slip out of
// synchronization with each other, a problem especially noticable in music projects.
// This problem is addressed by recording the amount of time slipage and shortening
// subsequent timed commmands slightly to "catch up".
// Delay times are rounded to milliseconds, and the minimum delay is a millisecond.

package interpreter {
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import blocks.*;
	import primitives.*;
	import scratch.*;
	import sound.*;
	import util.*;

public class Interpreter {

	public var activeThread:Thread;				// current thread
	public var currentMSecs:int = getTimer();	// millisecond clock for the current step
	public var turboMode:Boolean = false;

	private var app:Scratch;
	private var primTable:Dictionary;		// maps opcodes to functions
	private var threads:Array = [];			// all threads
	private var globals:Array = [];			// array of Variable objects
	private var yield:Boolean;				// set true to indicate that active thread should yield control
	private var callCount:int;				// counts procedure calls and yields every 100 calls to handle deep recursion
	private var doRedraw:Boolean;
	private var suppressRedraw:Boolean;

	public function Interpreter(app:Scratch) {
		this.app = app;
		initPrims();
//		checkPrims();
	}

	public function targetSprite():ScratchSprite {
		if (activeThread.target is ScratchSprite) return activeThread.target;
		return null;
	}

	public function targetObj():ScratchObj { return ScratchObj(activeThread.target) }

	/* Threads */

	public function doYield():void { yield = true }
	public function redraw():void { if (!suppressRedraw) doRedraw = true }

	public function threadCount():int { return threads.length }

	public function toggleThread(b:Block, targetObj:*):void {
		if (b.isReporter) {
			// click on reporter shows value in log
			currentMSecs = getTimer();
			activeThread = new Thread(b, targetObj);
			app.logPrint(evalCmd(b));
			activeThread = null;
			return;
		}
		var i:int, newThreads:Array = [], wasRunning:Boolean = false;
		for (i = 0; i < threads.length; i++) {
			if (threads[i].topBlock == b) {
				wasRunning = true;
			} else {
				newThreads.push(threads[i]);
			}
		}
		threads = newThreads;
		if (wasRunning) {
			b.hideRunFeedback();
		} else {
			b.showRunFeedback();
			threads.push(new Thread(b, targetObj));
			app.threadStarted();
		}
	}

	public function isRunning(b:Block):Boolean {
		for each (var t:Thread in threads) {
			if (t.topBlock == b) return true;
		}
		return false;
	}

	public function startThreadForClone(b:Block, clone:*):void {
		threads.push(new Thread(b, clone));
	}

	public function stopThreadsForClone(clone:*):void {
		for (var i:int = 0; i < threads.length; i++) {
			if (threads[i].target == clone) threads[i].stop();
		}
		if (activeThread.target == clone) yield = true;
	}

	public function restartThread(b:Block, targetObj:*):Thread {
		// used by broadcast; stop any thread running on b, then start a new thread on b
		var newThread:Thread = new Thread(b, targetObj);
		var wasRunning:Boolean = false;
		for (var i:int = 0; i < threads.length; i++) {
			if (threads[i].topBlock == b) {
				threads[i] = newThread;
				wasRunning = true;
			}
		}
		if (!wasRunning) {
			threads.push(newThread);
			b.showRunFeedback();
			app.threadStarted();
		}
		return newThread;
	}

	public function stopAllThreads():void {
		threads = [];
		if (activeThread != null) activeThread.stop();
		app.runtime.clearRunFeedback();
		suppressRedraw = false;
		doRedraw = true;
	}

	public function stepThreads():void {
		var startTime:int = getTimer();
		var workTime:int = (0.9 * 1000) / app.stage.frameRate; // work for up to 90% of one frame time
		suppressRedraw = turboMode;
		doRedraw = false;
		currentMSecs = getTimer();
		if (threads.length == 0) return;
		while (((currentMSecs - startTime) < workTime) && !doRedraw) {
			var threadStopped:Boolean = false;
			for each (activeThread in threads) {
				stepActiveThread();
				if (activeThread.block == null) threadStopped = true;
			}
			if (threadStopped) {
				var newThreads:Array = [];
				for each (var t:Thread in threads) {
					if (t.block != null) newThreads.push(t);
					else t.topBlock.hideRunFeedback();
				}
				threads = newThreads;
				if (threads.length == 0) return;
			}
			currentMSecs = getTimer();
		}
	}

	private function stepActiveThread():void {
		if (activeThread.block == null) return;
		if (!(activeThread.target.isStage || (activeThread.target.parent is ScratchStage))) {
			// don't run scripts of a sprite being dragged, but do update the screen
			doRedraw = true;
			return;
		}
		yield = false;
		callCount = 0;
		while (true) {
			evalCmd(activeThread.block);
			if (yield) return;
			activeThread.block = activeThread.block.nextBlock;
			while (activeThread.block == null) {  // end of block sequence
				if (!activeThread.popState()) return;  // end of script
				if (activeThread.isLoop) return;
				activeThread.block = activeThread.block.nextBlock;
			}
		}
	}

	/* Evaluation */

	public function evalCmd(b:Block):* {
		if (b.opFunction == null) {
			b.opFunction = (primTable[b.op] == undefined) ? primNoop : primTable[b.op];		// lol, that's very clever - Matt Vaughan Aug/18/2012
		}
		return b.opFunction(b);
	}

	public function arg(b:Block, i:int):* {
		return (b.args[i] is BlockArg) ?
			BlockArg(b.args[i]).argValue : evalCmd(Block(b.args[i]));
	}

	public function numarg(b:Block, i:int):Number {
		var n:Number = (b.args[i] is BlockArg) ?
			Number(BlockArg(b.args[i]).argValue) : Number(evalCmd(Block(b.args[i])));
		if (!((n <= 0) || (n > 0))) return 0;  // fast test for NaN; return 0 if NaN
		return n;
	}

	public function boolarg(b:Block, i:int):Boolean {
		var o:* = (b.args[i] is BlockArg) ? BlockArg(b.args[i]).argValue : evalCmd(Block(b.args[i]));
		if (o is Boolean) return o;
		if (o is String) {
			var s:String = o;
			if ((s == '') || (s == '0') || (s.toLowerCase() == 'false')) return false
			return true; // treat all other strings as true
		}
		return Boolean(o); // coerce Number and anything else
	}

	private function startCmdList(b:Block, isLoop:Boolean = false, argList:Array = null):void {
		if (b == null) {
			if (isLoop) yield = true;
			return;
		}
		activeThread.isLoop = isLoop;
		activeThread.pushStateForBlock(b);
		if (argList) activeThread.args = argList;
		evalCmd(activeThread.block);
	}

	/* Timer */

	public function startTimer(secs:Number):void {
		var waitMSecs:int = 1000 * secs;
		if (waitMSecs < 0) waitMSecs = 0;
		activeThread.tmp = currentMSecs + waitMSecs; // end time in milliseconds
		activeThread.firstTime = false;
		yield = true;
	}

	public function checkTimer():Boolean {
		// check for timer expiration and clean up if expired. return true when expired
		if (currentMSecs >= activeThread.tmp) {
			// time expired
			activeThread.tmp = 0;
			activeThread.firstTime = true;
			return true;
		} else {
			// time not yet expired
			yield = true;
			return false;
		}
	}

	/* Primitives */

	public function isImplemented(op:String):Boolean {
		return primTable[op] != undefined;
	}

	private function initPrims():void {
		primTable = new Dictionary();
		// control
		primTable["whenGreenFlag"]		= primNoop;
		primTable["whenKeyPressed"]		= primNoop;
		primTable["whenClicked"]		= primNoop;
		primTable["whenSceneStarts"]	= primNoop;
		primTable["wait:elapsed:from:"]	= primWait;
		primTable["doForever"]			= function(b:*):* { startCmdList(b.subStack1, true) };
		primTable["doRepeat"]			= primRepeat;
		primTable["broadcast:"]			= function(b:*):* { broadcast(b, false) }
		primTable["doBroadcastAndWait"]	= function(b:*):* { broadcast(b, true) }
		primTable["whenIReceive"]		= primNoop;
		primTable["doForeverIf"]		= function(b:*):* { if (arg(b, 0)) startCmdList(b.subStack1, true) else yield = true };
		primTable["doIf"]				= function(b:*):* { if (arg(b, 0)) startCmdList(b.subStack1) };
		primTable["doIfElse"]			= function(b:*):* { if (arg(b, 0)) startCmdList(b.subStack1) else startCmdList(b.subStack2) };
		primTable["doWaitUntil"]		= function(b:*):* { if (!arg(b, 0)) yield = true };
		primTable["doUntil"]			= function(b:*):* { if (!arg(b, 0)) startCmdList(b.subStack1, true) };
		primTable["doReturn"]			= primReturn;
		primTable["stopAll"]			= function(b:*):* { stopAllThreads(); yield = true };

		primTable["FOR_LOOP"]			= primForLoop;
		primTable["WHILE"]				= function(b:*):* { if (arg(b, 0)) startCmdList(b.subStack1, true) };
		primTable["SUSPEND_REDRAW"]		= primSuspendRedrawDuring;
		primTable["REDRAW"]				= function(b:*):* { doRedraw = true };

		// procedures
		primTable[Specs.CALL]			= primCall;

		// variables
		primTable[Specs.GET_VAR]		= primVarGet;
		primTable[Specs.SET_VAR]		= primVarSet;
		primTable[Specs.CHANGE_VAR]		= primVarChange;
		primTable[Specs.GET_PARAM]		= primGetParam;

		// other primitives
		new Primitives(app, this).addPrimsTo(primTable);
	}

	private function checkPrims():void {
		var op:String;
		var allOps:Array = ["CALL", "GET_VAR", "NOOP"];
		for each (var spec:Array in Specs.commands) {
			if (spec.length > 3) {
				op = spec[3];
				allOps.push(op);
				if (primTable[op] == undefined) trace("Unimplemented: " + op);
			}
		}
		for (op in primTable) {
			if (allOps.indexOf(op) < 0) trace("Not in specs: " + op);
		}
	}

	public function primNoop(b:Block):void { }

	private function primRepeat(b:Block):void {
		if (activeThread.firstTime) {
			activeThread.tmp = Math.max(Math.round(arg(b, 0)), 0); // repeat count
			activeThread.firstTime = false;
		}
		if (activeThread.tmp > 0) {
			activeThread.tmp--; // decrement count
			startCmdList(b.subStack1, true);
		} else {
			activeThread.firstTime = true;
		}
	}

	private function primWait(b:Block):void {
		if (activeThread.firstTime) {
			startTimer(numarg(b, 0));
			redraw();
		} else checkTimer();
	}

	private function broadcast(b:Block, waitFlag:Boolean):void {
		var pair:Array;
		if (activeThread.firstTime) {
			var receivers:Array = [];
			var newThreads:Array = [];
			var msg:String = String(arg(b, 0)).toLowerCase();
			var findReceivers:Function = function (stack:Block, target:ScratchObj):void {
				if ((stack.op == "whenIReceive") && (stack.args[0].argValue.toLowerCase() == msg)) {
					receivers.push([stack, target]);
				}
			}
			app.runtime.allStacksAndOwnersDo(findReceivers);
			// (re)start all receivers
			for each (pair in receivers) newThreads.push(restartThread(pair[0], pair[1]));
			if (!waitFlag) return;
			activeThread.tmpObj = newThreads;
			activeThread.firstTime = false;
		}
		var done:Boolean = true;
		for each (var t:Thread in activeThread.tmpObj) { if (threads.indexOf(t) >= 0) done = false }
		if (done) {
			activeThread.tmpObj = null;
			activeThread.firstTime = true;
		} else {
			yield = true;
		}
	}

	private function primForLoop(b:Block):void {
		if (activeThread.firstTime) {
			if (!(arg(b, 0) is String)) return;
			var list:Array = [];
			var listArg:* = arg(b, 1);
			if (listArg is Array) {
				list = listArg as Array;
			}
			if (listArg is String) {
				var n:Number = Number(listArg);
				if (!isNaN(n)) listArg = n;
			}
			if ((listArg is Number) && !isNaN(listArg)) {
				var last:int = int(listArg);
				if (last >= 1) {
					list = new Array(last - 1);
					for (var i:int = 0; i < last; i++) list[i] = i + 1;
				}
			}
			activeThread.loopVar = activeThread.target.lookupOrCreateVar(arg(b, 0));
			activeThread.list = list;
			activeThread.tmp = 0;
			activeThread.firstTime = false;
		}
		if (activeThread.tmp < activeThread.list.length) {
			activeThread.loopVar.value = activeThread.list[activeThread.tmp++];
			startCmdList(b.subStack1, true);
		} else {
			activeThread.loopVar = null;
			activeThread.list = null;
			activeThread.firstTime = true;
		}
	}

	private function primSuspendRedrawDuring(b:Block):void {
		if (activeThread.firstTime) {
			activeThread.tmpObj = suppressRedraw;
			suppressRedraw = true;
			doRedraw = false;
			activeThread.firstTime = false;
			startCmdList(b.subStack1, true);  // pretend to be a loop to get control again at the end
		} else {
			suppressRedraw = activeThread.tmpObj;
			activeThread.firstTime = true;
		}
	}

	private function primCall(b:Block):void {
		if (callCount++ > 100) {
			yield = true;
			return;
		}
		var proc:Block = b.cache;
		if (!proc) proc = b.cache = activeThread.target.lookupProcedure(b.spec);
		if (proc) {
			var argCount:int = proc.parameterNames.length;
			var argList:Array = [];
			for (var i:int = 0; i < argCount; i++) argList.push(arg(b, i));
			startCmdList(proc, false, argList);
		}
	}

	private function primReturn(b:Block):void {
		var didReturn:Boolean = activeThread.returnFromProcedure();
		if (!didReturn) {
			activeThread.stop();
			yield = true;
		}
	}

	// Variable Primitives
	// Optimization: to avoid the cost of looking up the variable every time,
	// a reference to the Variable object is cached in the block.
	// Note: Procedures can only reference global variables.

	private function primVarGet(b:Block):* {
		if (b.cache == null) {
			b.cache = activeThread.target.lookupOrCreateVar(b.spec);
			if (b.cache == null) return 0;
		}
		// XXX: Do we need a get() for persistent variables here ?
		return b.cache.value;
	}

	private function primVarSet(b:Block):void {
		if (b.cache == null) {
			b.cache = activeThread.target.lookupOrCreateVar(arg(b, 0));
			if (b.cache == null) return;
		}
		var v:Variable = b.cache;
		v.value = arg(b, 1);
		if (v.isPersistent) {
			app.persistenceManager.updateVariable(v.name, v.value);
		}
	}

	private function primVarChange(b:Block):void {
		if (b.cache == null) {
			b.cache = activeThread.target.lookupOrCreateVar(arg(b, 0));
			if (b.cache == null) return;
		}
		var v:Variable = b.cache;
		v.value = Number(v.value) + numarg(b, 1);
		if (v.isPersistent) {
			app.persistenceManager.updateVariable(v.name, v.value);
		}
	}

	private function primGetParam(b:Block):* {
		if (b.parameterIndex < 0) {
			var proc:Block = b.topBlock();
			if (proc.parameterNames) b.parameterIndex = proc.parameterNames.indexOf(b.spec);
			if (b.parameterIndex < 0) return 0;
		}
		if ((activeThread.args == null) || (b.parameterIndex >= activeThread.args.length)) return 0;
		return activeThread.args[b.parameterIndex];
	}

}}
