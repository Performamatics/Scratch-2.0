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
	import flash.media.Sound;
	import flash.media.SoundChannel;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * Provides media playback control of a given Sound object. 
	 * 
	 * @author Anton Nguyen
	 * @date 20110305
	 */
	public class SoundController extends EventDispatcher
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		private var _sound:Sound;
		private var _soundChannel:SoundChannel;
		private var _state:String;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Constructs a SoundController object.
		 */
		public function SoundController(sound:Sound)
		{
			_sound = sound;
			
			_state = SoundControllerState.STOPPED;
		}
		
		//----------------------------------------------------------------------
		//  
		//  Properties
		//  
		//----------------------------------------------------------------------
		
		//------------------------------
		//  position
		//------------------------------
		
		/**
		 * The position of the sound during playback. 
		 */
		public function get position():Number
		{
			var value:Number = NaN;
			
			switch (public::state)
			{
				case SoundControllerState.PLAYING:
				case SoundControllerState.PAUSED:
				{
					value = _soundChannel.position;
				}
					break;
				case SoundControllerState.STOPPED:
				{
					value = 0;
				}
					break;
			}
			
			return value;
		}
		
		//------------------------------
		//  sound
		//------------------------------
		
		/**
		 * The Sound object being controlled.
		 */
		public function get sound():Sound
		{
			return _sound;
		}
		
		/**
		 * @private
		 */
		public function set sound(value:Sound):void
		{
			_sound = value;
		}
		
		//------------------------------
		//  state
		//------------------------------
		
		/**
		 * The state of the SoundController.
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
			dispatchEvent(new SoundControllerStateEvent(SoundControllerStateEvent.EXIT, public::state));
			
			_state = value;
			
			dispatchEvent(new SoundControllerStateEvent(SoundControllerStateEvent.ENTER, public::state));
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Plays the sound, or resumes playback.
		 */
		public function play():void
		{
			switch (public::state)
			{
				case SoundControllerState.PLAYING:
				{
					// do nothing, already playing
				}
					break;
				case SoundControllerState.PAUSED:
				{
					_soundChannel = _sound.play(_soundChannel.position, 1);
					
					// if sound finishes playing, stop
					_soundChannel.addEventListener(Event.SOUND_COMPLETE, resetPlayback, false, 0, true);
					
					private::state = SoundControllerState.PLAYING;
				}
					break;
				case SoundControllerState.STOPPED:
				{
					_soundChannel = _sound.play(0, 1);
					
					// if sound finishes playing, stop
					_soundChannel.addEventListener(Event.SOUND_COMPLETE, resetPlayback, false, 0, true);
					
					private::state = SoundControllerState.PLAYING;
				}
					break; 
			}
		}
		
		/**
		 * Pauses playback. Playback will resume from the position at which it 
		 * was paused.
		 */
		public function pause():void
		{
			switch (public::state)
			{
				case SoundControllerState.PLAYING:
				{
					// stops playback at the current position, 
					// playback resumes from that position
					// "useless" access of position guarantees that the 
					// position's value persists when the channel is stopped  
					_soundChannel.position;
					_soundChannel.stop();
					
					private::state = SoundControllerState.PAUSED;
				}
					break;
				case SoundControllerState.PAUSED:
				case SoundControllerState.STOPPED:
				{
					// do nothing, can only pause during playback
				}
					break;
			}
		}
		
		/**
		 * Stops playback. Playback afterwards starts from position 0 ms.
		 */
		public function stop():void
		{
			switch (public::state)
			{
				// both of these are playback-related, same exact outcome
				// stop playback entirely
				case SoundControllerState.PLAYING:
				case SoundControllerState.PAUSED:
				{
					// stop playback
					_soundChannel.stop();
					_soundChannel.removeEventListener(Event.SOUND_COMPLETE, resetPlayback);
					
					private::state = SoundControllerState.STOPPED;
				}
					break;
				case SoundControllerState.STOPPED:
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
		 * @private
		 * 
		 * Convenience event handler for the SoundController.stop() method.
		 */
		private function resetPlayback(event:Event):void
		{
			stop();
		}
	}
}