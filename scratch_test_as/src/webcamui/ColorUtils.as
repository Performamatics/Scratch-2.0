package webcamui
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	public class ColorUtils
	{
		public function ColorUtils()
		{
		}
		
		public static function getBackgroundColor(bitmapData:BitmapData):uint
		{
			var leftCorner:ByteArray = bitmapData.getPixels(new Rectangle(0, 0, bitmapData.width / 10, bitmapData.height / 10));
			var rightCorner:ByteArray = bitmapData.getPixels(new Rectangle(bitmapData.width * 9 / 10, 0, bitmapData.width / 10, bitmapData.height / 10));
			
			// average the pixel values in each corner and return
			var ar:uint = 0x00;
			var ag:uint = 0x00;
			var ab:uint = 0x00;
			var rgb:uint = 0;
			
			leftCorner.position = 0;
			while (leftCorner.bytesAvailable > 3)
			{
				rgb = leftCorner.readUnsignedInt();
				ar += (rgb >> 16) & 0xFF;
				ag += (rgb >> 8) & 0xFF;
				ab += rgb & 0xFF;
			}
			
			rightCorner.position = 0;
			while(rightCorner.bytesAvailable > 3)
			{
				rgb = rightCorner.readUnsignedInt();
				ar += (rgb >> 16) & 0xFF;
				ag += (rgb >> 8) & 0xFF;
				ab += rgb & 0xFF;
			}
			
			ar = uint(ar / (leftCorner.length / 4 + rightCorner.length / 4));
			ag = uint(ag / (leftCorner.length / 4 + rightCorner.length / 4));
			ab = uint(ab / (leftCorner.length / 4 + rightCorner.length / 4));
			
			return (ar << 16) | (ag << 8) | ab;
		}
		
		public static function emptyPixel32(pixel:uint, passed:Boolean):uint
		{
			if (passed)
			{
				return 0x00000000;
			}
			else
			{
				return pixel;
			}
		}
		
		public static function inRange(value:Number, max:Number, min:Number):Boolean
		{
			if (max < min)
			{
				return value <= max || value >= min; 
			}
			else
			{
				return value <= max && value >= min;
			}
		}
		
		public static function rgbThreshold(bitmapData:BitmapData, sourceData:BitmapData, sourceRect:Rectangle, threshold:Function, replace:Function):void
		{
			bitmapData.lock();
			
			var initX:int = int(sourceRect.x);
			var initY:int = int(sourceRect.y);
			var width:int = int(sourceRect.width);
			var height:int = int(sourceRect.height);
			var sourceGetPixel:Function = sourceData.getPixel;
			var transparent:Boolean = bitmapData.transparent;
			var getPixel:Function = transparent ? bitmapData.getPixel32 : bitmapData.getPixel;
			var setPixel:Function = transparent ? bitmapData.setPixel32 : bitmapData.setPixel;
			
			for (var x:int = initX; x < width; x++)
			{
				for (var y:int = initY; y < height; y++)
				{
					// var rgb:Vector.<uint> = rgbToComp(sourceGetPixel(x, y));
					var rgb:uint = sourceGetPixel(x, y);
					var r:uint = (rgb >> 16) & 0xFF;
					var g:uint = (rgb >> 8) & 0xFF;
					var b:uint = rgb & 0xFF;
					
					setPixel(x, y, replace(getPixel(x, y), threshold(r, g, b)));
				}
			}
			
			bitmapData.unlock();
		}
		
		/**
		 * threshold = function(h:Number, s:Number, l:Number):Boolean as whether it passed or not
		 * replace = function(pixel:uint, passed:Boolean):uint as ARGB or RGB
		 */
		public static function hslThreshold(bitmapData:BitmapData, sourceData:BitmapData, sourceRect:Rectangle, threshold:Function, replace:Function):void
		{
			bitmapData.lock();
			
			for (var x:uint = sourceRect.x; x < sourceRect.width; x++)
			{
				for (var y:uint = sourceRect.y; y < sourceRect.height; y++)
				{
					var hsl:Vector.<Number> = rgbToHsl(sourceData.getPixel(x, y));
					var h:Number = hsl[0];
					var s:Number = hsl[1];
					var l:Number = hsl[2];
					
					if (bitmapData.transparent)
					{
						bitmapData.setPixel32(x, y, replace(bitmapData.getPixel32(x, y), (threshold(h, s, l))));
					}
					else
					{
						bitmapData.setPixel(x, y, replace(bitmapData.getPixel(x, y), (threshold(h, s, l))));
					}
				}
			}
			
			bitmapData.unlock();
		}
		
		public static function rgbToComp(color:uint):Vector.<uint>
		{
			return new <uint>[(color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF];
		}
		
		// takes in (A)RGB as a hex value (uint) 0xAARRGGBB where A, R, G, and B range from 0x00 to 0xFF
		// returns HSL as a vector in range H(0, 360), S(0, 1), L(0, 1)
		public static function rgbToHsl(color:uint):Vector.<Number>
		{
			var r:Number = Number((color >> 16) & 0xFF) / 0xFF;
			var g:Number = Number((color >> 8) & 0xFF) / 0xFF;
			var b:Number = Number(color & 0xFF) / 0xFF;
			
			var max:Number = Math.max(r, g, b);
			var min:Number = Math.min(r, g, b);
			
			var h:Number = 0;
			var s:Number = 0;
			var l:Number = (max + min) / 2;
			
			if (max != min)
			{
				var d:Number = max - min;
				s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
				
				switch (max)
				{
					case r:
					{
						h = (g - b) / d + (g < b ? 6 : 0);
					}
						break;
					case g:
					{
						h = (b - r) / d + 2;
					}
						break;
					case b:
					{
						h = (r - g) / d + 4;
					}
						break;
				}
				
				h *= 60;
			}
			
			return new <Number>[h, s, l];
		}
	}
}