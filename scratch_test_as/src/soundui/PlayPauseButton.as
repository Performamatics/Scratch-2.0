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
	
	public class PlayPauseButton extends StateButton
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		private var _playing:Boolean;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		public function PlayPauseButton(clickFunction:Function)
		{
			super(clickFunction);
			
			_icon = new Shape();
			turnOn();
			
			setIcon(_icon);
			
			playing = false;
		}
		
		//----------------------------------------------------------------------
		//  
		//  Properties
		//  
		//----------------------------------------------------------------------
		
		//------------------------------
		//  playing
		//------------------------------
		
		/**
		 * Changes the state of the button.
		 */
		public function get playing():Boolean
		{
			return _playing;
		}
		
		/**
		 * @private
		 */
		public function set playing(value:Boolean):void
		{
			_playing = value;
			
			if (playing)
			{
				drawPauseIcon((_icon as Shape).graphics, 0x339933, 0x33FF33);
			}
			else
			{
				drawPlayIcon((_icon as Shape).graphics, 0x339933, 0x33FF33);
			}
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		override public function turnOn():void
		{
			if (playing)
			{
				drawPauseIcon((_icon as Shape).graphics, 0x339933, 0x33FF33);
			}
			else
			{
				drawPlayIcon((_icon as Shape).graphics, 0x339933, 0x33FF33);
			}
		}
		
		override public function turnOff():void
		{
			if (playing)
			{
				drawPauseIcon((_icon as Shape).graphics, 0xAAAAAA, 0xCCCCCC);
			}
			else
			{
				drawPlayIcon((_icon as Shape).graphics, 0xAAAAAA, 0xCCCCCC);
			}
		}
		
		/**
		 * @private
		 * 
		 * Draws a pause icon on the given graphics object.
		 */
		private function drawPauseIcon(graphics:Graphics, strokeColor:uint, fillColor:uint):void
		{
			graphics.clear();
			graphics.lineStyle(0, 0x000000, 0);
			graphics.beginFill(0x000000, 0);
			graphics.drawRect(0, 0, 50, 50);
			
			graphics.lineStyle(1, strokeColor);
			graphics.beginFill(fillColor);
			graphics.drawRect(10, 10, 10, 30);
			graphics.beginFill(fillColor);
			graphics.drawRect(30, 10, 10, 30);
		}
		
		/**
		 * @private
		 * 
		 * Draws a play icon on the given graphics object.
		 */
		private function drawPlayIcon(graphics:Graphics, strokeColor:uint, fillColor:uint):void
		{
			graphics.clear();
			graphics.lineStyle(0, 0x000000, 0);
			graphics.beginFill(0x000000, 0);
			graphics.drawRect(0, 0, 50, 50);
			
			graphics.lineStyle(1, strokeColor);
			graphics.beginFill(fillColor);
			graphics.moveTo(10, 10);
			graphics.lineTo(10, 40);
			graphics.lineTo(40, 25);
			graphics.lineTo(10, 10);
			graphics.endFill();
		}
	}
}