package webcamui
{
	import webcamui.inspirit.InspiritCannyEdgeDetector;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Shader;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;
	import flash.filters.ShaderFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	import assets.Resources;
	import uiwidgets.*;
	
	public class WebCamPane extends DialogBox 
	{
		[Embed(source="RGBThreshold.pbj",mimeType="application/octet-stream")]
		private var RGBThresholdFilter:Class;
		private var _rgbShader:Shader;
		private var _rgbShaderFilter:ShaderFilter;
		
		private var _cameraButton:CameraButton;
		private var _cloneBitmap:Bitmap;
		private var _container:Sprite;
		private var _picture:Bitmap;
		private var _pictureContainer:Sprite;
		private var _originalData:BitmapData;
		private var _rect:Rectangle;
		private var _state:String;
		private var _video:Video;
		
		private var _checkBox:CheckBox;
		private var _label:TextField;
		private var _slider:Slider;
		
		private var _edgeDetector:InspiritCannyEdgeDetector;
		private var _saveFunc:Function;
		private var _saveButton:Button;
		private var _closeButton:Button;
		
		
		public function WebCamPane(saveFunc:Function)
		{	
			super();
			_saveFunc = saveFunc;
			
			addTitle("Camera");
			
			_container = new Sprite();
			addWidget(_container);
			
			_pictureContainer = new Sprite();
			_container.addChild(_pictureContainer);
			
			_picture = new Bitmap();
			_picture.bitmapData = new BitmapData(320, 240, true);
			_picture.visible = false;
			_pictureContainer.addChild(_picture);
			
			_cloneBitmap = new Bitmap();
			_cloneBitmap.blendMode = BlendMode.ALPHA;
			_pictureContainer.addChild(_cloneBitmap);
			
			_rect = new Rectangle(0, 0, _picture.bitmapData.width, _picture.bitmapData.height);
			
			_video = new Video(320, 240);
			_video.smoothing = true;
			_video.attachCamera(Camera.getCamera());
			_container.addChild(_video);
			
			// add form elements
			_checkBox = new CheckBox(toggleBackground);
			_checkBox.x = 10;
			_checkBox.y = 245;
			_checkBox.visible = false;
//			_container.addChild(_checkBox);
			var fmt:TextFormat = new TextFormat('Verdana', 10, 0, true);
			_label = Resources.makeLabel('Remove Background', fmt);
			_label.x = 25;
			_label.y = 250;
			_label.visible = false;
//			_container.addChild(_label);
			//_slider = new Slider(32, 1);	// for threshold2
			// _slider = new Slider(100, 0);	// for threshold4
			//_slider = new Slider(0xFF / 2.0, 0);	// for threshold5
			_slider = new Slider(0.33, 0.02);
			_slider.x = 10;
			_slider.y = 265;
			_slider.visible = false;
			_slider.value = 0.3;
			_slider.addEventListener(SliderEvent.UPDATE, updateBackground, false, 0, true);
//			_container.addChild(_slider);
			
//			_cameraButton = new CameraButton(takePicture, showCamera);
//			addChild(_cameraButton);
//			buttons.push(_cameraButton);

			_saveButton = new Button("Save", savePicture);
			addChild(_saveButton);
			buttons.push(_saveButton);		

			_closeButton = new Button("Close", closeDialog);
			addChild(_closeButton);
			buttons.push(_closeButton);		

			
			// filters
			_rgbShader = new Shader(new RGBThresholdFilter() as ByteArray);
			_rgbShaderFilter = new ShaderFilter(_rgbShader);
		}

		public function get picture():BitmapData
		{
			return _picture.bitmapData;
		}
		
		public function get rect():Rectangle
		{
			return _rect;
		}
		
		public function get state():String
		{
			return _state;
		}
		
		public function set state(value:String):void
		{
			_state = value;
			
			switch (state)
			{
				case WebCamPaneState.CAMERA:
				{
					_picture.visible = false;
					_video.visible = true;
					
					// remove form for removing bgcolor
					_checkBox.visible = false;
					_label.visible = false;
					_slider.visible = false;
				}
					break;
				case WebCamPaneState.PICTURE:
				{
					_video.visible = false;
					_picture.visible = true;
					
					// add in the form for removing background color
					_checkBox.visible = true;
					_label.visible = true;
					_slider.visible = true;
				}
					break;
			}
		}
		
		private function savePicture():void
		{
			_picture.bitmapData.draw(_video);
			if (_saveFunc != null) (_saveFunc(_picture.bitmapData.clone()));
		}

		public function closeDialog():void
		{
			if (_video) _video.attachCamera(null);
			if (parent) parent.removeChild(this);
		}
		
		private function showCamera():void
		{
			state = WebCamPaneState.CAMERA;
		}
		
		private function takePicture():void
		{
			_picture.bitmapData.draw(_video);
			_originalData = _picture.bitmapData.clone();
			_checkBox.turnOff();
			_slider.value = 6;
			
			state = WebCamPaneState.PICTURE;
		}
		
		private function updateBackground(event:SliderEvent):void
		{
			if (_checkBox.isOn())
			{
				toggleBackground(_checkBox);
			}
		}
		
		private function toggleBackground(button:IconButton):void
		{
			_picture.bitmapData = _originalData.clone();
			
			if (button.isOn())
			{
				threshold8();
			}
		}
		
		//----------------------------------------------------------------------
		//  
		//  Threshold Functions
		//  
		//----------------------------------------------------------------------
		
		//------------------------------
		// threshold0
		// 
		// BitmapData.threshold()
		//------------------------------
		
		// uses BitmapData.threshold
		// doesn't quite work that well...forget why
		private function threshold0():void
		{
			var threshold:uint = ColorUtils.getBackgroundColor(_originalData);
			trace(threshold.toString(16));
			var mask:uint = 0x00C0C0C0;
			_picture.bitmapData.threshold(_originalData, rect, new Point(0, 0), "==", threshold, 0x00000000, mask, true);
		}
		
		//------------------------------
		// threshold1
		// 
		// ColorUtils.hslThreshold()
		//------------------------------
		
		// screwed by noise that has a wide range of hue values
		// creates really spotty deletions (swiss cheesy), which are mostly accurate 
		// with a moderate threshold
		private function theshold1():void
		{
			var hsl:Vector.<Number> = ColorUtils.rgbToHsl(ColorUtils.getBackgroundColor(_originalData));
			trace(hsl);
			
			var range:Number = 25;
			var hMult:Number = 1;
			var sMult:Number = 0.01;
			var lMult:Number = 0.01;
			
			// normalize the hue to wrap around 360 degrees
			var maxH:Number = hsl[0] + range * hMult;
			maxH -= maxH > 360 ? 360 : 0;
			var minH:Number = hsl[0] - range * hMult;
			minH += minH < 0 ? 360 :0;
			
			var maxS:Number = hsl[1] + range * sMult;
			var minS:Number = hsl[1] - range * sMult;
			var maxL:Number = hsl[2] + range * lMult;
			var minL:Number = hsl[2] - range * lMult;
			
			var threshold:Function = function(h:Number, s:Number, l:Number):Boolean
			{
				return ColorUtils.inRange(h, maxH, minH) && ColorUtils.inRange(s, maxS, minS) && ColorUtils.inRange(l, maxL, minL);
			};
			
			ColorUtils.hslThreshold(_picture.bitmapData, _picture.bitmapData, rect, threshold, ColorUtils.emptyPixel32);
		}
		
		//------------------------------
		// threshold2
		// 
		// ColorUtils.rgbThreshold()
		//------------------------------
		
		// has rgb thresholding with optional hsl thresholding (or vice versa)
		// 
		// with hsl on, it's spotty since hue threshold fails due to noise levels (swiss cheese)
		// rgb is good, but captures non-contiguous areas
		private function threshold2():void
		{
			var rgbRaw:uint = ColorUtils.getBackgroundColor(_originalData)
			var rgb:Vector.<uint> = ColorUtils.rgbToComp(rgbRaw);
			trace(rgb);
			
			var range:Number = 0xFF / _slider.value;
			
			var maxR:Number = rgb[0] + range;
			var minR:Number = rgb[0] - range;
			var maxG:Number = rgb[1] + range;
			var minG:Number = rgb[1] - range;
			var maxB:Number = rgb[2] + range;
			var minB:Number = rgb[2] - range;
			
			var hsl:Vector.<Number> = ColorUtils.rgbToHsl(rgbRaw);
			var hslRange:Number = 20;
			var hMult:Number = 1;
			//var sMult:Number = 0.01;
			//var lMult:Number = 0.01;
			var maxH:Number = hsl[0] + hslRange * hMult;
			maxH -= maxH > 360 ? 360 : 0;
			var minH:Number = hsl[0] - hslRange * hMult;
			minH += minH < 0 ? 360 :0;
			
			//var maxS:Number = hsl[1] + hslRange * sMult;
			//var minS:Number = hsl[1] - hslRange * sMult;
			//var maxL:Number = hsl[2] + hslRange * lMult;
			//var minL:Number = hsl[2] - hslRange * lMult;
			
			var threshold:Function = function(r:Number, g:Number, b:Number):Boolean
			{
				var comp:Boolean = ColorUtils.inRange(r, maxR, minR) && ColorUtils.inRange(g, maxG, minG) && ColorUtils.inRange(b, maxB, minB);
				
				var rgb:uint = (r << 16) | (g << 8) | b;
				var hsl:Vector.<Number> = ColorUtils.rgbToHsl(rgb);
				//var comp2:Boolean = inRange(hsl[0], maxH, minH) && inRange(hsl[1], maxL, minL) && inRange(hsl[2], maxS, minS);
				
				//return comp && comp2;
				return comp && ColorUtils.inRange(hsl[0], maxH, minH);
				//return comp;
			};
			
			ColorUtils.rgbThreshold(_picture.bitmapData, _picture.bitmapData, rect, threshold, ColorUtils.emptyPixel32);
		}
		
		//------------------------------
		// threshold3
		// 
		// blurRemoval (hsl)
		//------------------------------
		
		private function threshold3():void
		{
			var blur:Number = 8;
			var filter:BlurFilter = new BlurFilter(blur, blur, BitmapFilterQuality.HIGH);
			var rect:Rectangle = new Rectangle(0, 0, _picture.bitmapData.width, _picture.bitmapData.height);
			var clone:BitmapData = _picture.bitmapData.clone();
			clone.applyFilter(_picture.bitmapData, rect, new Point(0, 0), filter);
			
			var hsl:Vector.<Number> = ColorUtils.rgbToHsl(ColorUtils.getBackgroundColor(_originalData));
			trace(hsl);
			
			var range:Number = 40;
			var hMult:Number = 1;
			var sMult:Number = 0.01;
			var lMult:Number = 0.01;
			
			// normalize the hue to wrap around 360 degrees
			var maxH:Number = hsl[0] + range * hMult;
			maxH -= maxH > 360 ? 360 : 0;
			var minH:Number = hsl[0] - range * hMult;
			minH += minH < 0 ? 360 :0;
			
			var maxS:Number = hsl[1] + range * sMult;
			var minS:Number = hsl[1] - range * sMult;
			var maxL:Number = hsl[2] + range * lMult;
			var minL:Number = hsl[2] - range * lMult;
			
			var threshold:Function = function(h:Number, s:Number, l:Number):Boolean
			{
				return ColorUtils.inRange(h, maxH, minH) && ColorUtils.inRange(s, maxS, minS) && ColorUtils.inRange(l, maxL, minL);
			};
			
			ColorUtils.hslThreshold(_picture.bitmapData, clone, rect, threshold, ColorUtils.emptyPixel32);
		}
		
		//------------------------------
		// threshold4
		// 
		// manhattanDistance (rgb)
		//------------------------------
		
		// works alright, probably need a combo of something plus some contiguity check
		private function threshold4():void
		{
			var rgb:Vector.<uint> = ColorUtils.rgbToComp(ColorUtils.getBackgroundColor(_originalData));
			trace(rgb);
			
			//var distance:uint = _slider.value;
			var distance:uint = 75;
			
			var threshold:Function = function(r:uint, g:uint, b:uint):Boolean
			{
				return Math.abs(rgb[0] - r) + Math.abs(rgb[1] - g) + Math.abs(rgb[2] - b) <= distance; 
			};
			
			ColorUtils.rgbThreshold(_picture.bitmapData, _picture.bitmapData, rect, threshold, ColorUtils.emptyPixel32);
		}
		
		//------------------------------
		// threshold5
		// 
		// floodFill removal (rgb)
		// 	(includes rgb thresholding)
		//------------------------------
		
		private function threshold5():void
		{
			var rgb:Vector.<uint> = ColorUtils.rgbToComp(ColorUtils.getBackgroundColor(_originalData));
			
			var range:Number = _slider.value;
			//trace(rgb, range);
			var maxR:Number = rgb[0] + range;
			var minR:Number = rgb[0] - range;
			var maxG:Number = rgb[1] + range;
			var minG:Number = rgb[1] - range;
			var maxB:Number = rgb[2] + range;
			var minB:Number = rgb[2] - range;
			
			var threshold:Function = function(r:uint, g:uint, b:uint):Boolean
			{
				return ColorUtils.inRange(r, maxR, minR) && ColorUtils.inRange(g, maxG, minG) && ColorUtils.inRange(b, maxB, minB);
			};
			
			// remove pixels from the clone (they are empty, so alpha channel = 0x00)
			var clone:BitmapData = _originalData.clone();
			_cloneBitmap.bitmapData = clone;
			//ColorUtils.rgbThreshold(clone, clone, rect, threshold, ColorUtils.emptyPixel32);
			var makeAlmostOpaque:Function = function(pixel:uint, passed:Boolean):uint
			{
				if (passed)
				{
					return 0xFE000000;
				}
				else
				{
					return pixel;
				}
			};
			
			ColorUtils.rgbThreshold(clone, clone, rect, threshold, makeAlmostOpaque);   
			
			// now perform floodfill for empty pixel 0x11FFFFFF, on the clone
			// then, iterate through all pixels in clone, for each one that is now 0x11FFFFFF
			// remove the corresponding (set to 0x11000000) from the picture
			
			// (we pick 0x11FFFFFF with alpha = 0x11 because internally, bitmapdata stores
			// premultiplied values of pixels so 0x00FFFFFF becomes 0x00000000 and then 
			// it just doesn't work like that
			var picWidth:int = _picture.bitmapData.width;
			/*
			var picHeight:int = _picture.bitmapData.height;
			var getPix:Function = clone.getPixel32;
			var setPix:Function = _picture.bitmapData.setPixel32;
			
			_picture.bitmapData.lock();
			
			clone.floodFill(0, 0, 0x11FFFFFF);
			clone.floodFill(picWidth, 0, 0x11FFFFFF);
			
			for (var x:int = 0; x < picWidth; x++)
			{
				for (var y:int = 0; y < picHeight; y++)
				{
					if (getPix(x, y) == 0x11FFFFFF)
					{
						setPix(x, y, 0x00000000);
					}
				}
			}
			
			_picture.bitmapData.unlock();
			*/
			
			clone.floodFill(0, 0, 0x00000000);
			clone.floodFill(picWidth, 0, 0x00000000);
			// there will be 0xFE alpha pixels, but that's technically close enough...(negligible???)
			// should do one pass to fix them
			_picture.bitmapData.draw(_pictureContainer);
			clone.dispose();
		}
		
		//------------------------------
		// threshold6
		// 
		// floodFill removal (rgb)
		// 	(includes rgb thresholding)
		// implemented in PixelBender
		//------------------------------
		
		private function threshold6():void
		{
			var rgb:Vector.<uint> = ColorUtils.rgbToComp(ColorUtils.getBackgroundColor(_originalData));
			var r:Number = rgb[0];
			var g:Number = rgb[1];
			var b:Number = rgb[2];
			
			var range:Number = _slider.value;
			var maxR:Number = Math.min(1.0, (r + range) / 255.0);
			var minR:Number = Math.max(0.0, (r - range) / 255.0);
			var maxG:Number = Math.min(1.0, (g + range) / 255.0);
			var minG:Number = Math.max(0.0, (g - range) / 255.0);
			var maxB:Number = Math.min(1.0, (b + range) / 255.0);
			var minB:Number = Math.max(0.0, (b - range) / 255.0);
			
			_rgbShader.data.upperLimit.value = [maxR, maxG, maxB];
			_rgbShader.data.lowerLimit.value = [minR, minG, minB];
			_rgbShader.data.replacement.value = [0.0, 0.0, 0.0, 254.0 / 255.0];
			
			// remove pixels from the clone (they are empty, so alpha channel = 0x00)
			var clone:BitmapData = _originalData.clone();
			_cloneBitmap.bitmapData = clone;
			clone.applyFilter(_originalData, rect, new Point(0, 0), _rgbShaderFilter);
			
			// now perform floodfill for empty pixel 0x11FFFFFF, on the clone
			// then, iterate through all pixels in clone, for each one that is now 0x11FFFFFF
			// remove the corresponding (set to 0x11000000) from the picture
			var picWidth:int = _picture.bitmapData.width;
			
			clone.floodFill(0, 0, 0x00000000);
			clone.floodFill(picWidth, 0, 0x00000000);
			
			// there will be 0xFE alpha pixels, but that's technically close enough...(negligible???)
			// should do one pass to fix them
			_picture.bitmapData.draw(_pictureContainer);
			clone.dispose();
		}
		
		//------------------------------
		// threshold7
		// 
		// floodFill removal (hsl)
		// 
		// implemented in PixelBender
		//------------------------------
		
		private function threshold7():void
		{
			var hsl:Vector.<Number> = ColorUtils.rgbToHsl(ColorUtils.getBackgroundColor(_originalData));
			trace(hsl);
			
			var range:Number = _slider.value;
			var hMult:Number = 1;
			var sMult:Number = 0.01;
			var lMult:Number = 0.01;
			
			// normalize the hue to wrap around 360 degrees
			var maxH:Number = hsl[0] + range * hMult;
			maxH -= maxH > 360 ? 360 : 0;
			var minH:Number = hsl[0] - range * hMult;
			minH += minH < 0 ? 360 :0;
			
			var maxS:Number = hsl[1] + 0.2;
			var minS:Number = hsl[1] - 0.2;
			var maxL:Number = hsl[2] + 0.4;
			var minL:Number = hsl[2] - 0.4;
			
			var threshold:Function = function(h:Number, s:Number, l:Number):Boolean
			{
				return ColorUtils.inRange(h, maxH, minH) && ColorUtils.inRange(s, maxS, minS) && ColorUtils.inRange(l, maxL, minL);
			};
			
			// remove pixels from the clone (they are empty, so alpha channel = 0x00)
			var clone:BitmapData = _originalData.clone();
			_cloneBitmap.bitmapData = clone;
			
			var makeAlmostOpaque:Function = function(pixel:uint, passed:Boolean):uint
			{
				if (passed)
				{
					return 0xFE000000;
				}
				else
				{
					return pixel;
				}
			};
			
			ColorUtils.hslThreshold(clone, clone, rect, threshold, makeAlmostOpaque);   
			
			// now perform floodfill for empty pixel 0x11FFFFFF, on the clone
			// then, iterate through all pixels in clone, for each one that is now 0x11FFFFFF
			// remove the corresponding (set to 0x11000000) from the picture
			
			// (we pick 0x11FFFFFF with alpha = 0x11 because internally, bitmapdata stores
			// premultiplied values of pixels so 0x00FFFFFF becomes 0x00000000 and then 
			// it just doesn't work like that
			var picWidth:int = _picture.bitmapData.width;
			
			clone.floodFill(0, 0, 0x00000000);
			clone.floodFill(picWidth, 0, 0x00000000);
			
			// there will be 0xFE alpha pixels, but that's technically close enough...(negligible???)
			// should do one pass to fix them
			_picture.bitmapData.draw(_pictureContainer);
			clone.dispose();
		}
		
		//------------------------------
		// threshold8
		// 
		// edge detection (in pixelbender)
		// need to do face/body detection?
		// 
		//------------------------------
		
		private function threshold8():void
		{
			var clone:BitmapData = _originalData.clone();
			_cloneBitmap.bitmapData = clone;
			
			_edgeDetector = new InspiritCannyEdgeDetector(clone, 0.02, _slider.value);
			var picWidth:int = _picture.bitmapData.width;
			
			_edgeDetector.detectEdgesBold(clone);
			clone.floodFill(0, 0, 0x00000000);
			clone.floodFill(picWidth, 0, 0x00000000);
			
			_picture.bitmapData.draw(_pictureContainer);
			clone.dispose();
		}
	}
}