// VideoSensePrims.as
// John Maloney, April 2010
//
// Video sensing primitives.

package primitives {
	import flash.display.*;
	import flash.utils.Dictionary;
	import blocks.Block;
	import filters.*;
	import interpreter.*;

public class VideoSensePrims {

	private var app:Scratch;
	private var interp:Interpreter;

	public function VideoSensePrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Dictionary):void {
		primTable["senseColor1"] = function(b:*):* { senseColor(0, interp.arg(b, 0)) };
		primTable["senseColor2"] = function(b:*):* { senseColor(1, interp.arg(b, 0)) };
		primTable["senseColor3"] = function(b:*):* { senseColor(2, interp.arg(b, 0)) };
		primTable["senseColor4"] = function(b:*):* { senseColor(3, interp.arg(b, 0)) };
		primTable["senseColor5"] = function(b:*):* { senseColor(4, interp.arg(b, 0)) };
		primTable["senseColor6"] = function(b:*):* { senseColor(5, interp.arg(b, 0)) };
		primTable["setHSVThresholds"] = primSetHSVThresholds;
		primTable["setRGBDiffFilter"] = primRGBDiff;
	}

	private function senseColor(targetColorIndex:int, c:int):void {
		VideoSenseFilters.colorSenseOn = true;
		VideoSenseFilters.targetColors[targetColorIndex] = c;
		app.stagePane.applyFilters();
		interp.redraw();
	}

	private function primSetHSVThresholds(b:Block):void {
		VideoSenseFilters.hueThreshold = interp.numarg(b, 0);
		VideoSenseFilters.satThreshold = interp.numarg(b, 1);
		VideoSenseFilters.briThreshold = interp.numarg(b, 2);
		app.stagePane.applyFilters();
		interp.redraw();
	}

	private function primRGBDiff(b:Block):void {
		VideoSenseFilters.rgbTargetColor = interp.arg(b, 0);
		VideoSenseFilters.rgbDistThreshold = interp.numarg(b, 1);
		app.stagePane.applyFilters();
		interp.redraw();
	}

}}
