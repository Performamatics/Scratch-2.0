package webcamui
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Mouse;
	
	public class Slider extends Sprite
	{
		private var _maxValue:Number;
		private var _minValue:Number;
		
		private var _retValue:Number;
		
		private var _track:Sprite;
		private var _thumb:Sprite;
		
		public function Slider(maxValue:Number = 100, minValue:Number = 0)
		{
			this.maxValue = maxValue;
			this.minValue = minValue;
			
			_track = new Sprite();
			var g:Graphics = _track.graphics;
			g.beginFill(0xAAAAAA);
			g.drawRect(0, 0, 100, 5);
			_track.addEventListener(MouseEvent.MOUSE_DOWN, beginDrag, false, 0, true);
			addChild(_track);
			
			_thumb = new Sprite();
			g = _thumb.graphics;
			g.lineStyle(1, 0x000000, 1.0, true);
			g.beginFill(0xCCCCCC);
			g.drawCircle(0, 0, 7.5);
			_thumb.x = 100;
			_thumb.y = 3.75;
			_thumb.addEventListener(MouseEvent.MOUSE_DOWN, beginDrag, false, 0, true);
			addChild(_thumb);
		}
		
		public function get maxValue():Number
		{
			return _maxValue;
		}
		
		public function set maxValue(value:Number):void
		{
			_maxValue = isFinite(value) ? value : _maxValue;
		}
		
		public function get minValue():Number
		{
			return _minValue;
		}
		
		public function set minValue(value:Number):void
		{
			_minValue = isFinite(value) ? value : _minValue;
		}
		
		public function get value():Number
		{
			return _thumb.x / 100 * (maxValue - minValue) + minValue;
		}
		
		public function set value(value:Number):void
		{
			if (isFinite(value) && value <= maxValue && value >= minValue)
			{
				_thumb.x = (value - minValue) / (maxValue - minValue) * 100;
				
				// this can be...uhh...rather bad if the code is intensive
				dispatchEvent(new SliderEvent(SliderEvent.UPDATE));
			}
		}
		
		private function beginDrag(event:MouseEvent):void
		{
			stage.addEventListener(MouseEvent.MOUSE_MOVE, doDrag, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, returnDrag, false, 0, true);
			_thumb.addEventListener(MouseEvent.MOUSE_UP, endDrag, false, 0, true);
			
			_retValue = value;
			
			if (event.target == _track)
			{
				doDrag(event);
			}
		}
		
		private function doDrag(event:MouseEvent):void
		{
			value = _track.globalToLocal(new Point(event.stageX, event.stageY)).x / 100 * maxValue;
		}
		
		private function returnDrag(event:MouseEvent):void
		{
			if (event.target != _thumb)
			{
				value = _retValue;
				
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, doDrag);
				stage.removeEventListener(MouseEvent.MOUSE_UP, returnDrag);
				_thumb.removeEventListener(MouseEvent.MOUSE_UP, endDrag);
			}
		}
		
		private function endDrag(event:MouseEvent):void
		{
			if (event.target == _thumb)
			{
				// last move
				doDrag(event);
				
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, doDrag);
				stage.removeEventListener(MouseEvent.MOUSE_UP, returnDrag);
				_thumb.removeEventListener(MouseEvent.MOUSE_UP, endDrag);
				
				// update listeners
				dispatchEvent(new SliderEvent(SliderEvent.UPDATE));
			}
		}
	}
}