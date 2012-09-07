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
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * Selection in a selectable waveform.
	 */
	public class Selection extends Sprite
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		private var _hitArea:Shape;
		private var _highlight:Shape;
		private var _moved:Boolean;
		private var _selectionStart:Number;
		private var _selectionEnd:Number;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Creates a selection.
		 */
		public function Selection(width:Number, height:Number)
		{
			_hitArea = new Shape();
			_hitArea.graphics.beginFill(0xFFFFFF, 0);
			_hitArea.graphics.drawRect(0, 0, width, height);
			addChild(_hitArea);
			
			_highlight = new Shape();
			addChild(_highlight);
			
			_selectionStart = 0;
			_selectionEnd = 0;
			
			addEventListener(MouseEvent.MOUSE_DOWN, beginSelection, false, 0, true);
		}
		
		//----------------------------------------------------------------------
		//  
		//  Properties
		//  
		//----------------------------------------------------------------------
		
		public function get selectionStart():Number
		{
			return _selectionStart; 
		}
		
		public function set selectionStart(value:Number):void
		{
			_selectionStart = value;
			
			updateSelection();
		}
		
		public function get selectionEnd():Number
		{
			return _selectionEnd;
		}
		
		public function set selectionEnd(value:Number):void
		{
			_selectionEnd = value;
			
			updateSelection();
		}
		
		//----------------------------------------------------------------------
		//  
		//  Event Handlers
		//  
		//----------------------------------------------------------------------
		
		private function beginSelection(event:MouseEvent):void
		{
			// begin selection
			_moved = false;
			addEventListener(MouseEvent.MOUSE_MOVE, drawSelection, false, 0, true);
			addEventListener(MouseEvent.MOUSE_UP, endSelection, false, 0, true);
			addEventListener(MouseEvent.MOUSE_OUT, endSelection, false, 0, true);
			
			// update vars
			selectionStart = event.localX;
			selectionEnd = event.localX;
			
			dispatchEvent(new SelectionEvent(SelectionEvent.BEGIN_SELECTION));
		}
		
		private function drawSelection(event:MouseEvent):void
		{
			// indicates it was a selection
			_moved = true;
			
			if (event.localX > _hitArea.width)
			{
				event.localX = _hitArea.width; 
			}
			else if (event.localX < 0)
			{
				event.localX = 0;
			}
			
			selectionEnd = event.localX;
			
			dispatchEvent(new SelectionEvent(SelectionEvent.DO_SELECTION));
		}
		
		private function endSelection(event:MouseEvent):void
		{
			// get rid of listeners
			removeEventListener(MouseEvent.MOUSE_MOVE, drawSelection);
			removeEventListener(MouseEvent.MOUSE_UP, endSelection);
			removeEventListener(MouseEvent.MOUSE_OUT, endSelection);
			
			if (_moved)
			{
				// this was a selection, not a click
				if (event.localX > _hitArea.width)
				{
					event.localX = _hitArea.width; 
				}
				else if (event.localX < 0)
				{
					event.localX = 0;
				}
				
				selectionEnd = event.localX;
				
				if (selectionEnd < selectionStart)
				{
					// reversed order
					var temp:Number = selectionStart;
					selectionStart = selectionEnd;
					selectionEnd = temp;
				}
				
				dispatchEvent(new SelectionEvent(SelectionEvent.END_SELECTION));
			}
			else
			{
				// the user was just clicking
				selectionStart = 0;
				selectionEnd = _hitArea.width;
				_highlight.graphics.clear();
				
				dispatchEvent(new SelectionEvent(SelectionEvent.CLEAR_SELECTION));
			}
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		private function updateSelection():void
		{
			_highlight.graphics.clear();
			_highlight.graphics.beginFill(0x0000FF, 0.25);
			_highlight.graphics.drawRect(selectionStart, 0, selectionEnd - selectionStart, _hitArea.height);
		}
	}
}