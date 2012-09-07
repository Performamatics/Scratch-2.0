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
	 * A delete button.
	 * 
	 * @author Anton Nguyen
	 * @date 20110307
	 */
	public class DeleteButton extends StateButton
	{
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Creates a DeleteButton.
		 * 
		 * @param clickFunction A function whose only parameter is an IconButton.
		 */
		public function DeleteButton(clickFunction:Function)
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
			drawDeleteIcon((_icon as Shape).graphics, 0x993333, 0xFF3333);
		}
		
		override public function turnOff():void
		{
			drawDeleteIcon((_icon as Shape).graphics, 0xAAAAAA, 0xCCCCCC);
		}
		
		/**
		 * @private
		 * 
		 * Draws a record icon on the given graphics object.
		 */
		private function drawDeleteIcon(graphics:Graphics, strokeColor:uint, fillColor:uint):void
		{
			graphics.clear();
			graphics.lineStyle(0, 0x000000, 0);
			graphics.beginFill(0x000000, 0);
			graphics.drawRect(0, 0, 50, 50);
			
			graphics.lineStyle(1, strokeColor);
			graphics.beginFill(fillColor);
			graphics.moveTo(10, 10);
			graphics.curveTo(20, 30, 40, 40);
			graphics.curveTo(30, 20, 10, 10);
			graphics.endFill();
			
			graphics.beginFill(fillColor);
			graphics.moveTo(10, 40);
			graphics.curveTo(20, 20, 40, 10);
			graphics.curveTo(30, 30, 10, 40);
			graphics.endFill();
		}
	}
}