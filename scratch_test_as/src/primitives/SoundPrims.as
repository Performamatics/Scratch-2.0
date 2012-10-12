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

	private var interpWait:Number;	// how long to pause to not overflow the sockets...
	
	public function SoundPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
		interpWait = 0.001;
	}

	public function addPrimsTo(primTable:Object):void {
		primTable["playSound:"]			= primPlaySound;
		primTable["doPlaySoundAndWait"]	= primPlaySoundUntilDone;
		primTable["stopAllSounds"]		= function(b:*):* { ScratchSoundPlayer.stopAllSounds() };

		primTable["drum:duration:elapsed:from:"]	= primPlayDrum;
		primTable["rest:elapsed:from:"]				= primPlayRest;

		primTable["noteOn:duration:elapsed:from:"]	= primPlayNote;
		primTable["midiInstrument:"]				= primSetInstrument;
		
		/* START Laptop Orchestra */
		primTable["addNote:"]						= primAddOrPlay;
		primTable["addRest:"]						= primAddRest;
		primTable["sendToServer:"]					= primSendToServer;
		primTable["sendToServerAt:"]				= primSendToServerAtRelative;
		primTable["sendToServerAtE:"]				= primSendToServerAtExact;
		primTable["playChord:"]						= primPlayChord;
		/* END Laptop Orchestra */
		
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

/* LAPTOP ORCHESTRA CODE BEGINS ******************************/
	private function primSetInstrument(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		var instrumentNumber:Number = interp.numarg(b, 0);
		if (s != null) s.setInstrument( instrumentNumber );
		
		if ( b.topBlock().op == "sendToServer:" || b.topBlock().op == "sendToServerAt:" ) {
			var broadcastString:String = new String("!@setinstrument(" + instrumentNumber +")" );
			SocketConnect.getInstance().sendData( broadcastString );
		}

		
	}
	
	private function primAddOrPlay(b:Block):void {
		
		// added by Matt Vaughan -- sends data to server!!! or plays the blocks locally if there is no special hat
		if ( b.topBlock().op == "sendToServer:" || b.topBlock().op == "sendToServerAt:" || b.topBlock().op == "sendToServerAtE:" ) {
			primAddNote( b );
		}
		else {
			primPlayNote( b );	
		}
	}
	
	private function primAddRest( b:Block ):void {
		var s:ScratchObj = interp.targetObj();
		if (s == null) return;
		if (interp.activeThread.firstTime) {
			var beats:Number = interp.numarg(b, 0);
			var broadcastString:String = new String("@addrest(" + beats +")" );
			var startOffset:Number;
			
			if ( b.topBlock().op == "sendToServerAt:" ) {
				startOffset = interp.numarg( b.topBlock(), 1 );	
				broadcastString = "!@queue('"+broadcastString+"',@+(@currentphrase(),"+ startOffset +"))";
			}
			else if ( b.topBlock().op == "sendToServerE:" ) {
				startOffset = interp.numarg( b.topBlock(), 1 );	
				broadcastString = "!@queue('"+broadcastString+"',"+ startOffset +")";
			}
			else {
				broadcastString = "!"+broadcastString;
			}
			
			SocketConnect.getInstance().sendData( broadcastString ); // added by Matt Vaughan -- sends data to server!!
			interp.startTimer( interpWait );					// execution time... so we don't flood the socket causing an exception on the server side
		} else {
			interp.checkTimer();						// Checking to see that we're done executing this block - Matt Vaughan Aug/17/2012
		}	
	}
	
	private function primAddNote( b:Block ):void {
		var s:ScratchObj = interp.targetObj();
		if (s == null) return;
		if (interp.activeThread.firstTime) {
			var key:int = interp.numarg(b, 0);
			var beats:Number = interp.numarg(b, 1);
			var broadcastString:String = new String("@addnote(" + key + "," + beats.valueOf() +")" );
			var startOffset:Number;
			
			if ( b.topBlock().op == "sendToServerAt:" ) {
				startOffset = interp.numarg( b.topBlock(), 1 );	
				broadcastString = "!@queue('"+broadcastString+"',@+(@currentphrase(),"+ startOffset +"))";
			}
			else if ( b.topBlock().op == "sendToServerAtE:" ) {
				startOffset = interp.numarg( b.topBlock(), 1 );
				broadcastString = "!@queue('"+broadcastString+"',"+ startOffset +")";
			}
			else {
				broadcastString = "!"+broadcastString;
			}
			
			SocketConnect.getInstance().sendData( broadcastString ); // added by Matt Vaughan -- sends data to server!!
			interp.startTimer( interpWait );					// execution time... so we don't flood the socket causing an exception on the server side
		} else {
			interp.checkTimer();						// Checking to see that we're done executing this block - Matt Vaughan Aug/17/2012
		}		
	}
	
	private function primSendToServer( b:Block ):void {
		
		var s:ScratchObj = interp.targetObj();
		if ( s == null ) return;
		if ( interp.activeThread.firstTime ) {
			
			var hostAddr:String = interp.arg( b, 0 );				// address of host from argument
			if ( ! SocketConnect.getInstance().isConnected() ) {
				SocketConnect.getInstance().connectTo( hostAddr );		// connect to host (if not connected allready)
			}
			
			SocketConnect.getInstance().sendData( "!@clearphrase()" );						// clears any phrases currently loaded
			//SocketConnect.getInstance().sendData("!@clearphrase(@+(@currentphrase(),1))");	// clears the next phrase... THE OLD WAY
			SocketConnect.getInstance().sendData("!@queue('@clearphrase()',@+(@currentphrase(),1))");	// clears the next phrase... THE NEW WAY

			interp.startTimer( interpWait );
		}
		else {
			interp.checkTimer();
		}
	}
	
	private function primSendToServerAtRelative( b:Block ):void {
		
		var s:ScratchObj = interp.targetObj();
		if ( s == null ) return;
		if ( interp.activeThread.firstTime ) {
			
			var hostAddr:String 	= interp.arg( b, 0 );				// address of host from argument
			var startOffset:Number 	= interp.numarg( b, 1 );			// start messure offset (play at cm+this number)
			var endOffset:Number 	= interp.numarg( b, 2 );			// end messure offset  (stop playing at cm+this number)

			if ( ! SocketConnect.getInstance().isConnected() ) {
				SocketConnect.getInstance().connectTo( hostAddr );		// connect to host (if not connected allready)
			}
			
			SocketConnect.getInstance().sendData("!@queue('@clearphrase()',@+(@currentphrase()," + startOffset +"))");	// clears the phrase we start on
			SocketConnect.getInstance().sendData("!@queue('@clearphrase()',@+(@currentphrase()," + (startOffset+endOffset+1) + "))");		// clears phrase we want to STOP playing on

			interp.startTimer( interpWait );
		}
		else {
			interp.checkTimer();
		}
	}
	
	private function primSendToServerAtExact( b:Block ):void {
		
		var s:ScratchObj = interp.targetObj();
		if ( s == null ) return;
		if ( interp.activeThread.firstTime ) {
			
			var hostAddr:String 	= interp.arg( b, 0 );				// address of host from argument
			var startOffset:Number 	= interp.numarg( b, 1 );			// start messure offset (play at this number)
			var endOffset:Number 	= interp.numarg( b, 2 );			// end messure offset  (stop playing at this number)
			
			if ( ! SocketConnect.getInstance().isConnected() ) {
				SocketConnect.getInstance().connectTo( hostAddr );		// connect to host (if not connected allready)
			}
			
			SocketConnect.getInstance().sendData("!@queue('@clearphrase()',"+ startOffset +")");					// clears the phrase we start on
			SocketConnect.getInstance().sendData("!@queue('@clearphrase()',"+ (startOffset+endOffset+1) + ")");		// clears phrase we want to STOP playing on
			
			interp.startTimer( interpWait );
		}
		else {
			interp.checkTimer();
		}
	}
	
	// Incomplete test function for playChord Block (needs note synchronization and iteration of numerous blocks) - Angelo Gamarra Sept/21/2012
	private function primPlayChord( b:Block ):void {
		
		var s:ScratchObj = interp.targetObj();
		if ( s == null ) return;
		
		if ( b.topBlock().op == "sendToServer:" || b.topBlock().op == "sendToServerAt:" ) {
			if ( interp.activeThread.firstTime ) {
			
				var tmpB:Block = b.subStack1;
				var key:int = 0;
				var beats:Number = 0.0;
				var tmpBeat:Number = 0.0;
				var broadcastString:String = "!@addchord(";
			
				while ( tmpB != null ) {
					key = interp.numarg(tmpB, 0);
					beats = (((tmpBeat = interp.numarg(tmpB, 1)) > beats) ? tmpBeat : beats);
					broadcastString = "" + broadcastString + key + ",";
				
					tmpB = tmpB.nextBlock;
				}
				broadcastString = "" + broadcastString + beats + ")";
			
				SocketConnect.getInstance().sendData(broadcastString);
				interp.startTimer( interpWait );
			}
			else {
				interp.checkTimer();
			}
		}
		/*
		var tmpB:Block = b.subStack1;
		
		if ( tmpB != null )
			playOrchestraBlock( tmpB );*/
	}
	
	private function playOrchestraBlock( b:Block ):void {
		var tempS:String = b.op;
		
		if ( tempS == "addNote:" ) {
			primAddOrPlay( b );
		}
	}
/* END OF LAPTOP ORCHESTRA CODE ************************/	
	
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
