package webcamui
{
	import flash.display.Graphics;
	import flash.display.Shape;
	
	import uiwidgets.Button;
	import uiwidgets.DialogBox;
	
	public class CameraButton extends Button
	{
		private var _cameraIcon:Shape;
		private var _readyFunc:Function;
		private var _notReadyFunc:Function;
		private var _ready:Boolean;
		
		public function CameraButton(readyFunc:Function, notReadyFunc:Function)
		{
			super("Take Picture", triggerClick);
			
			_readyFunc = readyFunc;
			_notReadyFunc = notReadyFunc;
			_cameraIcon = new Shape();
			drawCamera(_cameraIcon.graphics);
			setIcon(_cameraIcon);
			private::ready = true;
		}
		
		public function get ready():Boolean
		{
			return _ready;
		}
		
		private function set ready(value:Boolean):void
		{
			_ready = value;
			if (_ready)
			{
				setIcon(_cameraIcon);
			}
			else
			{
				setLabel("Redo");
			}
		}
		
		private function drawCamera(g:Graphics):void
		{
			g.lineStyle(0, 0x000000, 0);
			g.beginFill(0x000000, 0);
			g.drawRect(0, 0, 40, 10);
			g.beginFill(0x333399);
			//g.drawRect(0, 5, 50, 25);
			g.drawRoundRect(7.5, 0, 25, 10, 10, 25);
			g.beginFill(0x999999);
			g.drawCircle(20, 5, 4);
			g.beginFill(0xFFFFFF);
			g.drawCircle(20, 5, 3);
		}
		
		private function triggerClick():void
		{
			if (public::ready)
			{	
				_readyFunc();
			}
			else
			{
				_notReadyFunc();
			}
			
			private::ready = !public::ready;
		}
	}
}