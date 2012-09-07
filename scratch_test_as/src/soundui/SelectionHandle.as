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
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * A handle used in selecting a waveform.
	 */
	public class SelectionHandle extends Sprite
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		private var _maxWidth:Number;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Creates a selection handle.
		 */
		public function SelectionHandle(maxWidth:Number)
		{
			_maxWidth = maxWidth;
			
			graphics.lineStyle(1, 0x0000FF);
			graphics.beginFill(0xFFFFFF);
			graphics.lineTo(-15, -20);
			graphics.lineTo(15, -20);
			graphics.lineTo(0, 0);
			graphics.endFill();
			
			addEventListener(MouseEvent.MOUSE_DOWN, beginDrag, false, 0, true);
		}
		
		//----------------------------------------------------------------------
		//  
		//  Event Handlers
		//  
		//----------------------------------------------------------------------
		
		private function beginDrag(event:MouseEvent):void
		{
			startDrag(false, new Rectangle(0, 0, _maxWidth, 0));
			stage.addEventListener(MouseEvent.MOUSE_MOVE, doDrag, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, endDrag, false, 0, true);
			
			dispatchEvent(new SelectionHandleEvent(SelectionHandleEvent.BEGIN_DRAG));
		}
		
		private function doDrag(event:MouseEvent):void
		{
			dispatchEvent(new SelectionHandleEvent(SelectionHandleEvent.DO_DRAG));
		}
		
		private function endDrag(event:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, doDrag);
			stage.removeEventListener(MouseEvent.MOUSE_UP, endDrag);
			stopDrag();
			
			dispatchEvent(new SelectionHandleEvent(SelectionHandleEvent.END_DRAG));
		}
	}
}