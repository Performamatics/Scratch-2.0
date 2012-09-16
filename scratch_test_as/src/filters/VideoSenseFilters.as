// VideoSenseFilters.as
// John Maloney, April 2011
//
// Experimental filters for detectecting colors in a video feed. The settings of
// these filters are global.

package filters {
	import flash.display.*;
	import flash.filters.*;
	import scratch.*;
	import util.*;

public class VideoSenseFilters {

	[Embed(source="kernels/rgbdiff.pbj", mimeType="application/octet-stream")]
	private var RGBDiffKernel:Class;
	private var rgbDiffShader:Shader = new Shader(new RGBDiffKernel());

	[Embed(source="kernels/hsvmap.pbj", mimeType="application/octet-stream")]
	private var HSVMapKernel:Class;
	private var hsvMapShader:Shader = new Shader(new HSVMapKernel());

	[Embed(source="kernels/colorsense.pbj", mimeType="application/octet-stream")]
	private var ColorSenseKernel:Class;
	private var colorSenseShader:Shader = new Shader(new ColorSenseKernel());

	public static var rgbTargetColor:int;
	public static var rgbDistThreshold:Number = -1; // less than zero means off

	public static var hsvMapMode:int; // 0..3; 0 is off

	public static var colorSenseOn:Boolean;
	public static var targetColors:Array = [0, 0, 0, 0, 0, 0];
	public static var hueThreshold:Number = 15;
	public static var satThreshold:Number = 0.2;
	public static var briThreshold:Number = 0.2;

	public static var preBlur:Number = 0;

	public static function resetAllFilters():void {
		rgbTargetColor = 0;
		rgbDistThreshold = -1;

		hsvMapMode = 0;
		
		colorSenseOn = false;
		targetColors = [0, 0, 0, 0, 0, 0];
		hueThreshold = 15;
		satThreshold = 0.2;
		briThreshold = 0.2;

		preBlur = 0;
	}

	public function colorSenseFilter():BitmapFilter {
		colorSenseShader.data.hueThreshold.value = [hueThreshold];
		colorSenseShader.data.satThreshold.value = [satThreshold];
		colorSenseShader.data.briThreshold.value = [briThreshold];
		colorSenseShader.data.hsv0.value = hsv3(targetColors[0]);
		colorSenseShader.data.rgb0.value = rgb4(targetColors[0]);
		colorSenseShader.data.hsv1.value = hsv3(targetColors[1]);
		colorSenseShader.data.rgb1.value = rgb4(targetColors[1]);
		colorSenseShader.data.hsv2.value = hsv3(targetColors[2]);
		colorSenseShader.data.rgb2.value = rgb4(targetColors[2]);
		colorSenseShader.data.hsv3.value = hsv3(targetColors[3]);
		colorSenseShader.data.rgb3.value = rgb4(targetColors[3]);
		colorSenseShader.data.hsv4.value = hsv3(targetColors[4]);
		colorSenseShader.data.rgb4.value = rgb4(targetColors[4]);
		colorSenseShader.data.hsv5.value = hsv3(targetColors[5]);
		colorSenseShader.data.rgb5.value = rgb4(targetColors[5]);
		return new ShaderFilter(colorSenseShader);
	}

	private function hsv3(color:int):Array {
		// if a color is not used (== 0), use an impossible saturation to tell filter to ignore it.
		return (color == 0) ? [0, 10, 0] : Color.rgb2hsv(color);
	}

	private function rgb4(color:int):Array {
		return [
			1.0,
			((color >> 16) & 255) / 255.0,
			((color >> 8) & 255) / 255.0,
			(color & 255) / 255.0];
	}

	public function rgbDiffFilter():BitmapFilter {
		rgbDiffShader.data.refR.value = [((rgbTargetColor & 0xFF0000) >> 16) / 255.0];
		rgbDiffShader.data.refG.value = [((rgbTargetColor & 0xFF00) >> 8) / 255.0];
		rgbDiffShader.data.refB.value = [(rgbTargetColor & 0xFF) / 255.0]
		rgbDiffShader.data.rgbThreshold.value = [rgbDistThreshold];
		return new ShaderFilter(rgbDiffShader);
	}

	public function buildFilters():Array {
		var result:Array = [];
		var n:Number;
		if (rgbDistThreshold >= 0) {
			if (preBlur > 0) {			
				n = Math.round(Math.abs(preBlur));
				n = Math.max(1, Math.min(n, 30));  // preBlur range: 1..30
				result.push(new BlurFilter(n, n));	
			}
			result.push(rgbDiffFilter());
		}
		if (hsvMapMode > 0) {
			n = Math.max(1, Math.min(hsvMapMode, 3)); // range: 0-3
			hsvMapShader.data.mode.value = [n];
			result.push(new ShaderFilter(hsvMapShader));
		}
		if (colorSenseOn) {
			if (preBlur > 0) {
				n = Math.round(Math.abs(preBlur));
				n = Math.max(1, Math.min(n, 30));  // preBlur range: 1..30
				result.push(new BlurFilter(n, n));	
			}
			result.push(colorSenseFilter());
		}
		return result;
	}

}}
