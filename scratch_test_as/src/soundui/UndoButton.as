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
	 * An undo button.
	 * 
	 * @author Anton Nguyen
	 * @date 20110307
	 */
	public class UndoButton extends StateButton
	{
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Creates a UndoButton.
		 * 
		 * @param clickFunction A function whose only parameter is an IconButton.
		 */
		public function UndoButton(clickFunction:Function)
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
			drawUndoIcon((_icon as Shape).graphics, 0x333399, 0x3333FF);
		}
		
		override public function turnOff():void
		{
			drawUndoIcon((_icon as Shape).graphics, 0xAAAAAA, 0xCCCCCC);
		}
		
		/**
		 * @private
		 * 
		 * Draws a record icon on the given graphics object.
		 */
		private function drawUndoIcon(graphics:Graphics, strokeColor:uint, fillColor:uint):void
		{
			graphics.clear();
			graphics.lineStyle(0, 0x000000, 0);
			graphics.beginFill(0x000000, 0);
			graphics.drawRect(0, 0, 50, 50);
			graphics.endFill();
			
			var pi:Number = Math.PI;
			var tStart:Number = 11 / 4 * pi;
			var tMin:Number = 5 / 4 * pi;
			var tStep:Number = pi / 20;
			var cx:Number = 25;
			var cy:Number = 25;
			var r:Number = 15;
			
			graphics.lineStyle(3, fillColor);
			graphics.moveTo(cx + Math.cos(tStart) * r, cy + Math.sin(tStart) * r);
			
			for (var t:Number = tStart; t > tMin; t -= tStep)
			{
				graphics.lineTo(cx + Math.cos(t) * r, cy + Math.sin(t) * r);
			}
			
			graphics.moveTo(cx + Math.cos(tMin) * r, cy + Math.sin(tMin) * r);
			graphics.lineTo(17.5, 5);
			graphics.moveTo(cx + Math.cos(tMin) * r, cy + Math.sin(tMin) * r);
			graphics.lineTo(25, 17.5);
		}
	}
}