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
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import soundutil.SampledSound;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * Allows the user to manipulate sound via a visual waveform.
	 * 
	 * @author Anton Nguyen
	 * @date 20110404
	 */
	public class SelectableWaveForm extends Sprite
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		private var _bitmap:Bitmap;
		private var _bitmapContainer:Sprite;
		private var _bitmapData:BitmapData;
		private var _moved:Boolean;
		private var _recording:SampledSound;
		private var _state:String;
		private var _waveHeight:Number;
		private var _waveWidth:Number;
		
		private var _playhead:Shape;
		private var _selection:Selection;
		private var _leftHandle:SelectionHandle;
		private var _rightHandle:SelectionHandle;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Creates a selectable wave form.
		 */
		public function SelectableWaveForm(recording:SampledSound, waveWidth:Number = 200, waveHeight:Number = 50)
		{
			_waveHeight = waveHeight;
			_waveWidth = waveWidth;
			_recording = recording;
			_state = SelectableWaveFormState.UNSELECTED;
			
			// border
			graphics.lineStyle(1);
			graphics.drawRect(0, 0, width, height);
			
			// wave form bitmap
			_bitmapData = new BitmapData(_waveWidth, _waveHeight, false, 0xFFFFFF);
			_bitmap = new Bitmap(_bitmapData);
			_bitmap.width = _waveWidth;
			_bitmap.height = _waveHeight;
			drawWaveForm();
			addChild(_bitmap);
			
			// playhead
			_playhead = new Shape();
			_playhead.graphics.lineStyle(2.5, 0xFF0000, 0.5);
			_playhead.graphics.lineTo(0, _waveHeight);
			addChild(_playhead);
			
			// create selection handles
			_leftHandle = new SelectionHandle(_waveWidth);
			_leftHandle.visible = false;
			_leftHandle.addEventListener(SelectionHandleEvent.BEGIN_DRAG, beginDrag, false, 0, true);
			_leftHandle.addEventListener(SelectionHandleEvent.DO_DRAG, doDrag, false, 0, true);
			_leftHandle.addEventListener(SelectionHandleEvent.END_DRAG, endDrag, false, 0, true);
			addChild(_leftHandle);
			
			_rightHandle = new SelectionHandle(_waveWidth);
			_rightHandle.visible = false;
			_rightHandle.addEventListener(SelectionHandleEvent.BEGIN_DRAG, beginDrag, false, 0, true);
			_rightHandle.addEventListener(SelectionHandleEvent.DO_DRAG, doDrag, false, 0, true);
			_rightHandle.addEventListener(SelectionHandleEvent.END_DRAG, endDrag, false, 0, true);
			addChild(_rightHandle);
			
			// selection
			_selection = new Selection(_waveWidth, _waveHeight);
			_selection.addEventListener(SelectionEvent.BEGIN_SELECTION, beginSelection, false, 0, true);
			_selection.addEventListener(SelectionEvent.CLEAR_SELECTION, resetSelection, false, 0, true);
			_selection.addEventListener(SelectionEvent.DO_SELECTION, doSelection, false, 0, true);
			_selection.addEventListener(SelectionEvent.END_SELECTION, endSelection, false, 0, true);
			addChild(_selection);
		}
		
		//----------------------------------------------------------------------
		//  
		//  Properties
		//  
		//----------------------------------------------------------------------
		
		//------------------------------
		//  playhead
		//------------------------------
		
		/**
		 * The playhead.
		 */
		public function get playhead():Shape
		{
			return _playhead;
		}
		
		//------------------------------
		//  recording
		//------------------------------
		
		/**
		 * The recording.
		 */
		public function get recording():SampledSound
		{
			return _recording;
		}
		
		/**
		 * @private
		 */
		public function set recording(value:SampledSound):void
		{
			_recording = value;
		}
		
		//------------------------------
		//  selectionStart
		//------------------------------
		
		private function get leftmostSelectionHandle():SelectionHandle
		{
			if (_leftHandle.x < _rightHandle.x)
			{
				return _leftHandle;
			}
			else
			{
				return _rightHandle;
			}
		}
		
		/**
		 * The start of the selection in pixels.
		 */
		public function get selectionStart():Number
		{
			return public::state == SelectableWaveFormState.SELECTED ? leftmostSelectionHandle.x : 0;
		}
		
		//------------------------------
		//  selectionEnd
		//------------------------------
		
		private function get rightmostSelectionHandle():SelectionHandle
		{
			if (_leftHandle.x > _rightHandle.x)
			{
				return _leftHandle;
			}
			else
			{
				return _rightHandle;
			}
		}
		
		/**
		 * The end of the selection in pixels.
		 */
		public function get selectionEnd():Number
		{
			return public::state == SelectableWaveFormState.SELECTED ? rightmostSelectionHandle.x : waveWidth;
		}
		
		//------------------------------
		//  state
		//------------------------------
		
		/**
		 * The internal state of the wave form interactivity.
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
			dispatchEvent(new SelectableWaveFormStateEvent(SelectableWaveFormStateEvent.EXIT, public::state));
			
			_state = value;
			
			dispatchEvent(new SelectableWaveFormStateEvent(SelectableWaveFormStateEvent.ENTER, public::state));
		}
		
		//------------------------------
		//  waveHeight
		//------------------------------
		
		/**
		 * The height of the wave form.
		 */
		public function get waveHeight():Number
		{
			return _waveHeight;
		}
		
		//------------------------------
		//  waveWidth
		//------------------------------
		
		/**
		 * The width of the wave form.
		 */
		public function get waveWidth():Number
		{
			return _waveWidth;
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		public function clearSelection():void
		{
			resetSelection(new SelectionEvent(SelectionEvent.CLEAR_SELECTION));
		}
		
		/**
		 * Draws the entire wave form.
		 */
		public function drawWaveForm():void
		{
			// clear bitmap
			_bitmapData.fillRect(new Rectangle(0, 0, _waveWidth, _waveHeight), 0xFFFFFF);
			
			var samples:ByteArray = _recording.samples;
			samples.position = 0;
			
			var lineOfPixels:Rectangle = new Rectangle(0, 0, 1, 0);
			var pixelValues:Vector.<uint>;
			var pixelHeight:int;
			
			// floats / px
			var step:int = Math.floor(samples.length / 4 / _waveWidth);
			var average:Number = 0;
			var maxVal:Number = 0;
			var sample:Number;
			
			for (var i:int = 0; (i < _waveWidth) && (samples.bytesAvailable > 4); i++)
			{
				average = 0;
				maxVal = samples.readFloat();
				samples.position -= 4;
				
				// trace(samples.readFloat());
				// samples.position -= 4;
				for (var j:int = 0; (j < step) && (samples.bytesAvailable > 4); j++)
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
		
		private function beginDrag(event:SelectionHandleEvent):void
		{
			_selection.selectionStart = leftmostSelectionHandle.x;
			_selection.selectionEnd = rightmostSelectionHandle.x;
		}
		
		private function doDrag(event:SelectionHandleEvent):void
		{
			_selection.selectionStart = leftmostSelectionHandle.x;
			_selection.selectionEnd = rightmostSelectionHandle.x;
		}
		
		private function endDrag(event:SelectionHandleEvent):void
		{
			_selection.selectionStart = leftmostSelectionHandle.x;
			_selection.selectionEnd = rightmostSelectionHandle.x;
			
			// rebroadcast state change
			private::state = SelectableWaveFormState.SELECTED;
		}
		
		private function beginSelection(event:SelectionEvent):void
		{
			// change states
			private::state = SelectableWaveFormState.UNSELECTED;
			
			// reset handles
			_leftHandle.visible = true;
			_rightHandle.visible = false;
			_leftHandle.x = _selection.selectionStart;
		}
		
		private function resetSelection(event:SelectionEvent):void
		{
			// change states
			private::state = SelectableWaveFormState.UNSELECTED;
			
			// reset handles
			_leftHandle.visible = false;
			_leftHandle.x = 0;
			_rightHandle.visible = false;
			_rightHandle.x = _waveWidth;
			_playhead.x = 0;
			_selection.selectionStart = 0;
			_selection.selectionEnd = 0;
		}
		
		private function doSelection(event:SelectionEvent):void
		{
			// update handles
			_leftHandle.x = _selection.selectionStart;
			_rightHandle.visible = true;
			_rightHandle.x = _selection.selectionEnd;
		}
		
		private function endSelection(event:SelectionEvent):void
		{
			// update handles
			_leftHandle.x = _selection.selectionStart;
			_rightHandle.visible = true; // in case
			_rightHandle.x = _selection.selectionEnd;
			
			// change states
			private::state = SelectableWaveFormState.SELECTED;
		}
	}
}