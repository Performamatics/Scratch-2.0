// ExtensionPrims.as
// John Maloney, September 2011
//
// Scratch extension primitives.

package primitives {
	import blocks.Block;
	import interpreter.*;

public class MidiPrims {

	private var app:Scratch;
	private var interp:Interpreter;
	private var extensionSockets:Object = new Object();

	public function MidiPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Object):void {
		primTable['midiController'] 	= primController;
		primTable['midiNoteOn'] 		= primNoteOn;
		primTable['midiNoteOff'] 		= primNoteOff;
		primTable['midiPitchBend'] 		= primPitchBend;
		primTable['midiProgram'] 		= primProgram;
		primTable['midiPlayNote'] 		= primNoteWithDur;
		primTable['midiReset'] 			= primReset;
		primTable['midiUseJavaSynth'] 	= primUseJavaSynth;
		primTable['midiTime'] 			= primMidiTime;
	}

	private function primController(b:Block):void { app.extensionManager.call('Midi', 'controller', collectNumArgs(b)) }
	private function primNoteOn(b:Block):void { app.extensionManager.call('Midi', 'noteOn', collectNumArgs(b)) }
	private function primNoteOff(b:Block):void { app.extensionManager.call('Midi', 'noteOff', collectNumArgs(b)) }
	private function primPitchBend(b:Block):void { app.extensionManager.call('Midi', 'pitchBend', collectNumArgs(b)) }
	private function primProgram(b:Block):void { app.extensionManager.call('Midi', 'program', collectNumArgs(b)) }
	private function primReset(b:Block):void { app.extensionManager.call('Midi', 'midiReset', []) }
	private function primUseJavaSynth(b:Block):void { app.extensionManager.call('Midi', 'useJavaSynth', [interp.arg(b, 0)]) }
	private function primMidiTime(b:Block):* { return app.extensionManager.getStateVar('Midi', 'time', 0); }

	private function primNoteWithDur(b:Block):void {
		// No longer used, but a good example of how to do a blocking command.
		var activeThread:Thread = interp.activeThread;
		if (activeThread.firstTime) {
			var returnID:int = app.extensionManager.call('Midi', 'playNote', collectNumArgs(b));
			if (returnID < 0) return;
			activeThread.tmp = returnID
			activeThread.firstTime = false;
		}
		var reply:Object = app.extensionManager.getReply('Midi', activeThread.tmp);
		if (reply != null) { // finished
			activeThread.tmp = 0;
			activeThread.firstTime = true;
		} else {
			interp.doYield();
		}
	}

	private function collectNumArgs(b:Block):Array {
		// Collects number arguments.
		var args:Array = [];
		for (var i:int = 0; i < b.args.length; i++) args.push(interp.numarg(b, i));
		return args;
	}

}}
