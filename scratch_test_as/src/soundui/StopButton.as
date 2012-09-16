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
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * A stop button.
	 * 
	 * @author Anton Nguyen
	 * @date 20110503
	 */
	public class StopButton extends StateButton
	{
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Creates a StopButton.
		 * 
		 * @param clickFunction A function whose only parameter is an IconButton.
		 */
		public function StopButton(clickFunction:Function)
		{
			super(clickFunction);
			
			_icon = new Shape();
			turnOn();
			
			setIcon(_icon);
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		override public function turnOn():void
		{
			drawStopIcon((_icon as Shape).graphics, 0x999999, 0xFFFFFF);
		}
		
		override public function turnOff():void
		{
			drawStopIcon((_icon as Shape).graphics, 0xAAAAAA, 0xCCCCCC);
		}
		
		/**
		 * @private
		 * 
		 * Draws a record icon on the given graphics object.
		 */
		private function drawStopIcon(graphics:Graphics, strokeColor:uint, fillColor:uint):void
		{
			graphics.clear();
			graphics.lineStyle(0, 0x000000, 0);
			graphics.beginFill(0x000000, 0);
			graphics.drawRect(0, 0, 50, 50);
			
			graphics.lineStyle(1, strokeColor);
			graphics.beginFill(fillColor);
			graphics.drawRect(10, 10, 30, 30);
		}
	}
}