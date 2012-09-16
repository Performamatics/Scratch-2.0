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
	 * A record button.
	 * 
	 * @author Anton Nguyen
	 * @date 20110305
	 */
	public class RecordButton extends StateButton
	{
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Creates a RecordButton.
		 * 
		 * @param clickFunction A function whose only parameter is an IconButton.
		 */
		public function RecordButton(clickFunction:Function)
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
			drawRecordIcon((_icon as Shape).graphics, 0x993333, 0xFF3333);
		}
		
		override public function turnOff():void
		{
			drawRecordIcon((_icon as Shape).graphics, 0xAAAAAA, 0xCCCCCC);
		}
		
		/**
		 * @private
		 * 
		 * Draws a record icon on the given graphics object.
		 */
		private function drawRecordIcon(graphics:Graphics, strokeColor:uint, fillColor:uint):void
		{
			graphics.clear();
			graphics.lineStyle(0, 0x000000, 0);
			graphics.beginFill(0x000000, 0);
			graphics.drawRect(0, 0, 50, 50);
			
			graphics.lineStyle(1, strokeColor);
			graphics.beginFill(fillColor);
			graphics.drawCircle(25, 25, 15);
		}
	}
}