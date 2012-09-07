// SoundPrimitives.as
// John Maloney, June 2010
//
// Sound primitives.

package primitives {
	import blocks.*;
	
	import interpreter.*;
	
	import scratch.*;
	
	import sound.*;

public class SoundPrims {

	private var app:Scratch;
	private var interp:Interpreter;

	public function SoundPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Object):void {
		primTable["playSound:"]			= primPlaySound;
		primTable["doPlaySoundAndWait"]	= primPlaySoundUntilDone;
		primTable["stopAllSounds"]		= function(b:*):* { ScratchSoundPlayer.stopAllSounds() };

		primTable["drum:duration:elapsed:from:"]	= primPlayDrum;
		primTable["rest:elapsed:from:"]				= primPlayRest;

		primTable["noteOn:duration:elapsed:from:"]	= primPlayNote;
		primTable["midiInstrument:"]				= primSetInstrument;
		
		/* TEST - Matt Vaughan */
		primTable["test:"]							= primTest;
		primTable["sendToServer:"]					= primSendToServer;
		/* END OF TEST */
		
		/* TEST - Angelo Gamarra */
		primTable["playChord:"]						= primPlayChord;
		/* END OF TEST */
		
		primTable["changeVolumeBy:"]	= primChangeVolume;
		primTable["setVolumeTo:"]		= primSetVolume;
		primTable["volume"]				= primVolume;

		primTable["changeTempoBy:"]		= function(b:*):* { app.stagePane.setTempo(app.stagePane.tempoBPM + interp.numarg(b, 0)) };
		primTable["setTempoTo:"]		= function(b:*):* { app.stagePane.setTempo(interp.numarg(b, 0)) };
		primTable["tempo"]				= function(b:*):* { return app.stagePane.tempoBPM };
	}

	private function primPlaySound(b:Block):void {
		var snd:ScratchSound = interp.targetObj().findSound(interp.arg(b, 0));
		if (snd != null) playSound(snd, interp.targetObj());
	}

	private function primPlaySoundUntilDone(b:Block):void {
		var activeThread:Thread = interp.activeThread;
		if (activeThread.firstTime) {
			var snd:ScratchSound = interp.targetObj().findSound(interp.arg(b, 0));
			if (snd == null) return;
			activeThread.tmpObj = playSound(snd, interp.targetObj());
			activeThread.firstTime = false;
		}
		var player:ScratchSoundPlayer = ScratchSoundPlayer(activeThread.tmpObj);
		if ((player == null) || (player.atEnd())) { // finished playing
			activeThread.tmp = 0;
			activeThread.firstTime = true;
		} else {
			interp.doYield();
		}
	}

	private function primPlayNote(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		if (s == null) return;
		if (interp.activeThread.firstTime) {
			var key:int = interp.numarg(b, 0);
			var secs:Number = beatsToSeconds(interp.numarg(b, 1));
			playNote(s.instrument, key, secs, s);
			interp.startTimer(secs);					// execution time... probably want to eliminate this - Matt Vaughan Aug/17/2012
		} else {
			interp.checkTimer();						// Checking to see that we're done executing this block - Matt Vaughan Aug/17/2012
		}
	}

	private function primPlayDrum(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		if (s == null) return;
		if (interp.activeThread.firstTime) {
			var drum:int = Math.round(interp.numarg(b, 0));
			var secs:Number = beatsToSeconds(interp.numarg(b, 1));
			playDrum(drum, secs, s);
			interp.startTimer(secs);
		} else {
			interp.checkTimer();
		}
	}

	public function playSound(s:ScratchSound, client:ScratchObj):ScratchSoundPlayer {
		var player:ScratchSoundPlayer = s.sndplayer();
		player.client = client;
		player.startPlaying();
		return player;
	}

	public function playDrum(drum:int, secs:Number, client:ScratchObj):ScratchSoundPlayer {
		var entry:Array = SoundBank.getDrumEntry(drum);
		if (entry == null) return null;
		var player:NotePlayer = new NotePlayer(entry[0], entry[1], entry[2]);
		player.client = client;
		player.setDuration(secs);
		player.startPlaying();
		return player;
	}

	public function playNote(instrument:int, midiKey:int, secs:Number, client:ScratchObj):ScratchSoundPlayer {
		var entry:Array = SoundBank.getInstrumentEntry(instrument);
		if (entry == null) return null;
		
		/*
		* 'NotePlayer.as' is in the 'sound' folder
		*/
		var player:NotePlayer = new NotePlayer(entry[0], entry[1], entry[2]);
		player.client = client;
		player.setNoteAndDuration( midiKey, secs);
		player.startPlaying();
		
		/*
		* Perhaps this would be the best place to send to note to the server??
		* This code, as it is, should be used when there is no hat on top of the blocks
		* But if there is hat then we want to send to the server...
		* Matt Vaughan's Note from Aug/17/2012
		*/
		return player;
	}

	private function primPlayRest(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		if (s == null) return;
		if (interp.activeThread.firstTime) {
			var secs:Number = beatsToSeconds(interp.numarg(b, 0));
			interp.startTimer(secs);
		} else {
			interp.checkTimer();
		}
	}

	private function beatsToSeconds(beats:Number):Number {
		return (beats * 60) / app.stagePane.tempoBPM;
	}

	private function primSetInstrument(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		if (s != null) s.setInstrument(interp.numarg(b, 0));
	}
	
/* LAPTOP ORCHESTRA CODE */
	private function primTest(b:Block):void {
		
		// added by Matt Vaughan -- sends data to server!!! or plays the blocks locally if there is no special hat
		if ( b.topBlock().op == "sendToServer:" ) {
			primTestSend( b );
		}
		else {
			primPlayNote( b );	
		}
	}
	
	private function primTestSend( b:Block ):void {
		var s:ScratchObj = interp.targetObj();
		if (s == null) return;
		if (interp.activeThread.firstTime) {
			var key:int = interp.numarg(b, 0);
			var secs:Number = beatsToSeconds(interp.numarg(b, 1));
			//playNote(s.instrument, key, secs, s);
			interp.startTimer(0.01);				// execution time... probably want to eliminate this - Matt Vaughan Aug/17/2012
			var phraseNum:int = interp.numarg( b.topBlock(), 0 );
			var broadcastString:String = new String("broadcast\"addnotes#" + phraseNum.toString() + "#" + key.toString() + "-QN#"+ key.toString() +"-QN#loop-f\"");
			SocketConnect.getInstance().sendData( broadcastString ); // added by Matt Vaughan -- sends data to server!!!
		} else {
			interp.checkTimer();						// Checking to see that we're done executing this block - Matt Vaughan Aug/17/2012
		}		
	}
	
	private function primSendToServer( b:Block ):void {
		
		var s:ScratchObj = interp.targetObj();
		if ( s == null ) return;
		if ( interp.activeThread.firstTime ) {
			var phraseNum:int = interp.numarg( b, 0 );
			SocketConnect.getInstance().sendData( "broadcast\"clearphrase#0\"" ); 
			interp.startTimer(0.01);
		}
		else {
			interp.checkTimer();
		}
	}
	
	// Incomplete test function for playChord Block (needs check statements, note synchronization, and server message) - Angelo Gamarra Sept/6/2012
	private function primPlayChord( b:Block ):void {
		
		var tmpB:Block = b.subStack1;
		
		while ( tmpB ) {
			primPlayNote( tmpB );
			tmpB = tmpB.nextBlock;
		}
	}
/* END OF LAPTOP ORCHESTRA CODE */	
	
	private function primChangeVolume(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		if (s != null) s.setVolume(s.volume + interp.numarg(b, 0));
	}

	private function primSetVolume(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		if (s != null) s.setVolume(interp.numarg(b, 0));
	}

	private function primVolume(b:Block):Number {
		var s:ScratchObj = interp.targetObj();
		return (s != null) ? s.volume : 0;
	}

}}
