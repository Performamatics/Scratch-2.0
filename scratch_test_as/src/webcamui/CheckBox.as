package webcamui
{
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Matrix;
	
	import uiwidgets.IconButton;

	public class CheckBox extends IconButton
	{
		public function CheckBox(clickFunction:Function)
		{
			var checked:Shape = new Shape();
			drawCheckBox(checked.graphics, true);
			
			var unchecked:Shape = new Shape();
			drawCheckBox(unchecked.graphics, false);
			
			super(clickFunction, checked, unchecked);
		}
		
		private function drawCheckBox(g:Graphics, checked:Boolean):void
		{
			g.lineStyle(1, 0x000000, 1.0, true);
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(10, 10, 0, -5, -5);
			g.beginGradientFill(GradientType.RADIAL, [0xFFFFFF, 0xCCCCCC], [1.0, 1.0], [0, 255], matrix);
			g.drawRect(0, 0, 10, 10);
			g.endFill();
			
			if (checked)
			{
				g.lineStyle(2.5, 0x3333FF, 1.0);
				g.moveTo(2, 3);
				g.lineTo(5, 9);
				g.lineTo(10, 0);
			}
		}
	}
}