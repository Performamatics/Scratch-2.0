// WeDoPrims.as
// John Maloney, September 2010
//
// WeDo primitives.

package primitives {
	import blocks.Block;
	import interpreter.Interpreter;

public class WeDoPrims {

	private var app:Scratch;
	private var interp:Interpreter;

	public function WeDoPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Object):void {
		primTable['allMotorsOff']				= primAllMotorsOff;
		primTable['allMotorsOn']				= primAllMotorsOn;
		primTable['motorOnFor:elapsed:from:']	= primMotorOnFor;
		primTable['setMotorDirection:']			= primSetMotorDirection;
		primTable['startMotorPower:']			= primStartMotorPower;
	}

	private function primAllMotorsOff(ignore:*):void { app.extensionManager.call('WeDo', 'allMotorsOff', []) }
	private function primAllMotorsOn(ignore:*):void { app.extensionManager.call('WeDo', 'allMotorsOn', []) }

	private function primMotorOnFor(b:Block):void {
		if (interp.activeThread.firstTime) {
			primAllMotorsOn(null);
			interp.startTimer(interp.numarg(b, 0));
		} else {
			if (interp.checkTimer()) primAllMotorsOff(null);
		}
	}

	private function primSetMotorDirection(b:Block):void {
		app.extensionManager.call('WeDo', 'setMotorDirection', [interp.arg(b, 0)]);
	}

	private function primStartMotorPower(b:Block):void {
		app.extensionManager.call('WeDo', 'setMotorPower', [interp.numarg(b, 0)]);
		primAllMotorsOn(null);
	}

}}
