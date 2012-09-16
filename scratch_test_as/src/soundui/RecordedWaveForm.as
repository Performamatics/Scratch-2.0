//------------------------------------------------------------------------------
//  
//  Package
//  
//------------------------------------------------------------------------------

package soundui
{
	
	//--------------------------------------------------------------------------
	//  
	//  Imports
	//  
	//--------------------------------------------------------------------------
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.SampleDataEvent;
	import flash.geom.Rectangle;
	import flash.media.Microphone;
	import flash.utils.ByteArray;
	
	import soundutil.SoundRecorder;
	import soundutil.SoundRecorderState;
	import soundutil.SoundRecorderStateEvent;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * A waveform that updates as the microphone receives data.
	 * 
	 * @author Anton Nguyen
	 * @date 20110314
	 */
	public class RecordedWaveForm extends Sprite
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		private var _bitmap:Bitmap;
		private var _bitmapData:BitmapData;
		private var _cursorX:int;
		private var _soundRecorder:SoundRecorder;
		private var _waveHeight:Number;
		private var _waveWidth:Number;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		public function RecordedWaveForm(soundRecorder:SoundRecorder, waveWidth:Number = 200, waveHeight:Number = 50)
		{
			_soundRecorder = soundRecorder;
			_soundRecorder.addEventListener(SoundRecorderStateEvent.ENTER, enterState, false, 0, true);
			_soundRecorder.addEventListener(SoundRecorderStateEvent.EXIT, exitState, false, 0, true);
			_waveHeight = waveHeight;
			_waveWidth = waveWidth;
			
			// border
			graphics.lineStyle(1);
			graphics.drawRect(0, 0, _waveWidth, _waveHeight);
			
			_bitmapData = new BitmapData(_waveWidth, _waveHeight, false, 0xFFFFFF);
			_bitmap = new Bitmap(_bitmapData);
			addChild(_bitmap);
			
			// the drawing cursor
			_cursorX = 0;
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		/**
		 * @private
		 * 
		 * Effectively clears the bitmap.
		 */
		private function clearBitmap():void
		{
			_cursorX = 0;
			_bitmapData.fillRect(new Rectangle(0, 0, _bitmapData.width, _bitmapData.height), 0xFFFFFF);
		}
		
		/**
		 * @private
		 * 
		 * Draws the entire wave form.
		 */
		private function drawWaveForm():void
		{
			var samples:ByteArray = _soundRecorder.recording.samples;
			samples.position = 0;
			
			var lineOfPixels:Rectangle = new Rectangle(0, 0, 1, 0);
			var pixelValues:Vector.<uint>;
			var pixelHeight:int;
			
			// floats / px
			var step:int = Math.floor(samples.length / 4 / _waveWidth);
			var average:Number = 0;
			var maxVal:Number = 0;
			var sample:Number;
			
			for (var i:int = 0; i < _waveWidth; i++)
			{
				average = 0;
				maxVal = samples.readFloat();
				samples.position -= 4;
				
				for (var j:int = 0; j < step; j++)
				{
					sample = samples.readFloat();
					average += sample;
					
					maxVal = Math.max(maxVal, sample);
				}
				
				average = average / step;
				
				// update the rectangle of pixels to draw
				pixelHeight = Math.floor((maxVal - average) * _waveHeight);
				// pixelHeight = Math.abs(Math.floor(Math.log(average * 10) / Math.log(10) * _waveHeight));
				lineOfPixels.x = i;
				lineOfPixels.y = Math.floor((_waveHeight - pixelHeight) / 2);
				lineOfPixels.height = pixelHeight;
				
				pixelValues = new Vector.<uint>();
				
				for (j = 0; j < pixelHeight; j++)
				{
					pixelValues.push(0x000000);
				}
				
				_bitmapData.setVector(lineOfPixels, pixelValues);
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
		 * When the SoundRecorder is recording, add listeners to the Microphone 
		 * object to plot waveform data. 
		 */
		private function enterState(event:SoundRecorderStateEvent):void
		{
			if (event.state == SoundRecorderState.RECORDING)
			{
				clearBitmap();
				_soundRecorder.microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, updateWaveForm, false, 0, true);
			}
		}
		
		/**
		 * @private
		 * 
		 * Removes the listener from the Microphone object to stop plotting the 
		 * waveform.
		 */
		private function exitState(event:SoundRecorderStateEvent):void
		{
			if (event.state == SoundRecorderState.RECORDING)
			{
				_soundRecorder.microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, updateWaveForm, false);
				drawWaveForm();
			}
		}
		
		/**
		 * @private
		 * 
		 * Draws the waveform.
		 */
		private function updateWaveForm(event:SampleDataEvent):void
		{
			var lineOfPixels:Rectangle = new Rectangle(0, 0, 1, 0);
			var average:Number = 0;
			var sample:Number = 0;
			var maxVal:Number = 0;
			var incomingSamples:ByteArray = event.data;
			incomingSamples.position = 0;
			
			// average the samples
			for (var i:int = 0; i < incomingSamples.length / 4; i++)
			{
				// average += Math.abs(incomingSamples.readFloat());
				sample = incomingSamples.readFloat();
				average += sample;
				
				maxVal = Math.max(maxVal, sample);
			}
			
			// average = average / i;
			average = average / incomingSamples.length;
			
			// update the rectangle of pixels to draw
			var pixelHeight:int = Math.floor((maxVal - average) * _waveHeight);
			
			// fill in pixels, scaled to base = waveHeight
			// var pixelHeight:int = Math.abs(Math.floor(Math.log(average * 10) / Math.log(10) * _waveHeight));
			lineOfPixels.x = _cursorX;
			lineOfPixels.y = Math.floor((_waveHeight - pixelHeight) / 2);
			lineOfPixels.height = pixelHeight;
			var pixelValues:Vector.<uint> = new Vector.<uint>();
			
			for (i = 0; i < pixelHeight; i++)
			{
				pixelValues.push(0x000000);
			}
			
			_bitmapData.setVector(lineOfPixels, pixelValues);
			
			_cursorX++;
			
			if (_cursorX == _waveWidth)
			{
				clearBitmap();
			}
		}
	}
}