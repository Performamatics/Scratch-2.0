//------------------------------------------------------------------------------
//  
//  Package
//  
//------------------------------------------------------------------------------

package soundutil
{
	
	//--------------------------------------------------------------------------
	//  
	//  Imports
	//  
	//--------------------------------------------------------------------------
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SampleDataEvent;
	import flash.media.Microphone;
	import flash.utils.ByteArray;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * Records sound from an audio input device as uncompressed samples. The 
	 * samples are contained in a SampledSound object. 
	 * 
	 * @author Anton Nguyen
	 * @date 20110305
	 */
	public class SoundRecorder extends EventDispatcher
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		private var _microphone:Microphone;
		private var _recording:SampledSound;
		private var _state:String;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Constructs a SoundRecorder object.
		 */
		public function SoundRecorder()
		{
			// set rate to 44 ( = 44,100 Hz)
			_microphone = Microphone.getMicrophone();
			microphone.rate = 44;
			microphone.setSilenceLevel(0);
			microphone.gain = 100;
			
			_recording = new SampledSound(new ByteArray());
			
			_state = SoundRecorderState.STOPPED;
		}
		
		//----------------------------------------------------------------------
		//  
		//  Properties
		//  
		//----------------------------------------------------------------------
		
		//------------------------------
		//  microphone
		//------------------------------
		
		/**
		 * The microphone object used to record sound from.
		 */
		public function get microphone():Microphone
		{
			return _microphone;
		}
		
		//------------------------------
		//  recording
		//------------------------------
		
		/**
		 * The SampledSound object that contains the recorded samples.
		 */
		public function get recording():SampledSound
		{
			return _recording;
		}
		
		//------------------------------
		//  state
		//------------------------------
		
		/**
		 * The state of the SoundRecorder.
		 */
		public function get state():String
		{
			return _state;
		}
		
		/**
		 * @private
		 */
		private function set state(value:String):void
		{
			dispatchEvent(new SoundRecorderStateEvent(SoundRecorderStateEvent.EXIT, _state));
			
			_state = value;
			
			dispatchEvent(new SoundRecorderStateEvent(SoundRecorderStateEvent.ENTER, _state));
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Clears a previous recording, if any, and writes a new one.
		 */
		public function record():void
		{
			switch (public::state)
			{
				case SoundRecorderState.RECORDING:
				{
					// do nothing, recording can only happen when stopped
				}
					break;
				case SoundRecorderState.STOPPED:
				{
					// forgets the old recording, if there was one
					recording.samples.clear();
					
					// good practice to create a weakly-referenced event handler
					microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, writeSamples, false, 0, true);
					
					private::state = SoundRecorderState.RECORDING;
				}
					break;
			}
		}
		
		/**
		 * Stops playback or recording. Playback afterwards starts from position 
		 * 0ms.
		 */
		public function stop():void
		{
			switch (public::state)
			{
				case SoundRecorderState.RECORDING:
				{
					// stop recording
					microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, writeSamples);
					
					private::state = SoundRecorderState.STOPPED;
				}
					break;
				case SoundRecorderState.STOPPED:
				{
					// do nothing, already stopped
				}
					break;
			}
		}
		
		//----------------------------------------------------------------------
		//  
		//  Event Handlers
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Writes samples from the Microphone into the SampledSound's byte 
		 * array.
		 */
		protected function writeSamples(event:SampleDataEvent):void
		{
			var incomingSamples:ByteArray = event.data;
			incomingSamples.position = 0;
			var outgoingSamples:ByteArray = recording.samples;
			
			while (incomingSamples.bytesAvailable)
			{
				outgoingSamples.writeFloat(incomingSamples.readFloat());0
			}
		}
	}
}