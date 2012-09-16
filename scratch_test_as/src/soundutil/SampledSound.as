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
	
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * A SampledSound object is a Sound object that uses a ByteArray from which 
	 * samples are played back. This is useful for samples from an audio input 
	 * device such as a microphone.
	 * 
	 * @author Anton Nguyen
	 * @date 20110404
	 */
	public class SampledSound extends Sound
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		private var _rate:int;
		private var _samples:ByteArray;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Creates a new SampledSound object.
		 * 
		 * @param samples The samples to be used for playback.
		 * 
		 * @param rate The bitrate at which the samples were recorded.
		 */
		public function SampledSound(samples:ByteArray, rate:int = 44100)
		{
			_rate = rate;
			_samples = samples;
			
			// good practice to create a weakly-referenced event handler
			addEventListener(SampleDataEvent.SAMPLE_DATA, readSamples, false, 0, true);
		}
		
		//----------------------------------------------------------------------
		//  
		//  Properties
		//  
		//----------------------------------------------------------------------
		
		//------------------------------
		//  bytesLoaded
		//------------------------------
		
		/**
		 * @private
		 */
		override public function get bytesLoaded():uint
		{
			return _samples.length;
		}
		
		//------------------------------
		//  bytesTotal
		//------------------------------
		
		/**
		 * @private
		 */
		override public function get bytesTotal():int
		{
			return _samples.length;
		}
		
		//------------------------------
		//  length
		//------------------------------
		
		/**
		 * @private
		 */
		override public function get length():Number
		{
			// {length} ms = {length} bytes * 8 bits/1 byte * 1 sample/32 bits * 1 s/{rate} samples * 1000 ms/1 s  
			return _samples.length * 8 / 32 / rate * 1000;
		}
		
		//------------------------------
		//  rate
		//------------------------------
		
		/**
		 * The sample rate in Hz.
		 */
		public function get rate():int
		{
			return _rate;
		}
		
		//------------------------------
		//  samples
		//------------------------------
		
		/**
		 * The samples used for playback. It is highly suggested that you do not
		 * mutate the sample data during playback.
		 */
		public function get samples():ByteArray
		{
			return _samples;
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		public function clone():SampledSound
		{
			var clonedSamples:ByteArray = new ByteArray();
			clonedSamples.writeBytes(samples, 0, 0);
			
			return new SampledSound(clonedSamples, rate);
		}
		
		/**
		 * @param loops This is ignored; the sound only plays once.
		 */
		override public function play(startTime:Number = 0, loops:int = 0, sndTransform:SoundTransform = null):SoundChannel
		{
			// {position} bytes = {startTime} ms * 1 s/1000 ms * {rate} samples/1 s * 32 bits/1 sample * 1 byte/8 bits
			_samples.position = int(startTime / 1000 * rate * 32 / 8);
			
			// ensures that we start at a full sample (if we don't, resuming 
			// playback results in silence)
			_samples.position -= _samples.position % 4;
			
			return super.play(startTime, loops, sndTransform);
		}
		
		//----------------------------------------------------------------------
		//  
		//  Event Handlers
		//  
		//----------------------------------------------------------------------
		
		/**
		 * @private
		 * 
		 * Provides sample data when requested during playback.
		 */
		private function readSamples(event:SampleDataEvent):void
		{
			var outgoingSamples:ByteArray = event.data;
			var sample:Number;
			
			for (var i:int = 0; i < 8192; i++)
			{
				if (_samples.bytesAvailable < 4)
				{
					// at (near) EOF, insufficient data to read a 32-bit float
					return;
				}
				
				sample = _samples.readFloat();
				
				// left and right channel are the same (mono sound)
				outgoingSamples.writeFloat(sample);
				outgoingSamples.writeFloat(sample);
			}
		}
	}
}