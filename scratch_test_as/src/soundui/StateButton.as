package soundui
{
	import flash.display.DisplayObject;
	import uiwidgets.Button;
	
	public class StateButton extends Button
	{
		protected var _icon:DisplayObject;
		
		public function StateButton(clickFunc:Function)
		{
			super("", clickFunc);
		}
		
		public function turnOn():void
		{
			
		}
		
		public function turnOff():void
		{
			
		}
	}
}