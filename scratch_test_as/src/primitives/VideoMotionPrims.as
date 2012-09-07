// VideoMotionPrims.as
// Tony Hwang and John Maloney, January 2011
//
// Video motion sensing primitives.

package primitives {
	import flash.display.*;
	import flash.geom.Matrix;
	import flash.utils.Dictionary;
	import blocks.Block;
	import interpreter.*;
	import spark.primitives.BitmapImage;

public class VideoMotionPrims {

	private const toDegree:Number = 180 / Math.PI;
	private const WIDTH:int = 320;
	private const HEIGHT:int = 240;
	private const AMOUNT_SCALE:int = 25; // chosen empirically to give a range of roughly 0-100
	private const THRESHOLD:int = 10;

	private var app:Scratch;
	private var interp:Interpreter;

	private var motionAmount:int;
	private var motionDirection:int;

	private var analysisDone:Boolean;

	private var frameBuffer:BitmapData;
	private var curr:Vector.<uint>;
	private var prev:Vector.<uint>;

	public function VideoMotionPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
		frameBuffer = new BitmapData(WIDTH, HEIGHT);
	}

	public function addPrimsTo(primTable:Dictionary):void {
		primTable['motionAmount']		= primMotionAmount;
		primTable['motionDirection']	= primMotionDirection;
	}

	private function primMotionAmount(b:Block):Number {
		startMotionDetector();
		if (!analysisDone) analyzeFrame();
		return motionAmount;
	}

	private function primMotionDirection(b:Block):Number {
		startMotionDetector();
		if (!analysisDone) analyzeFrame();
		return motionDirection;
	}

	private function startMotionDetector():void { app.runtime.motionDetector = this }
	private function stopMotionDetector():void { app.runtime.motionDetector = null }
	
	public function step():void {
		if (!(app.stagePane && app.stagePane.videoImage)) {
			prev = curr = null;
			motionAmount = motionDirection = 0;
			analysisDone = true;
			stopMotionDetector();
			return;
		}

		var img:BitmapData = app.stagePane.videoImage;
		var scale:Number = Math.min(WIDTH / img.width, HEIGHT / img.height);
		var m:Matrix = new Matrix();
		m.scale(scale, scale);
		frameBuffer.draw(img, m);
		prev = curr;
		curr = frameBuffer.getVector(frameBuffer.rect);
		analysisDone = false;
	}

	private function analyzeFrame():void {
		if (!curr || !prev) {
			motionAmount = motionDirection = -1;
			return; // don't have two frames to analyze yet
		}

		const winSize:int = 8;
		const winStep:int = winSize * 2 + 1;
		const wmax:int = WIDTH - winSize - 1;
		const hmax:int = HEIGHT - winSize - 1;

		var i:int, j:int, k:int, l:int;
		var address:int;

		var A2:Number, A1B2:Number, B1:Number, C1:Number, C2:Number;
		var u:Number, v:Number, uu:Number, vv:Number, n:int;

		uu = vv = n = 0;
		for (i = winSize + 1; i < hmax; i += winStep) { // y
			for (j = winSize + 1; j < wmax; j += winStep) { // x
				A2 = 0;
				A1B2 = 0;
				B1 = 0;
				C1 = 0;
				C2 = 0;
				for (k = -winSize; k <= winSize; k++) { // y
					for (l = -winSize; l <= winSize; l++) { // x
						var gradX:int, gradY:int, gradT:int;

						address = (i + k) * WIDTH + j + l;
						gradX = (curr[address - 1] & 0xff) - (curr[address + 1] & 0xff);
						gradY = (curr[address - WIDTH] & 0xff) - (curr[address + WIDTH] & 0xff);
						gradT = (prev[address] & 0xff) - (curr[address] & 0xff);

						A2 += gradX * gradX;
						A1B2 += gradX * gradY;
						B1 += gradY * gradY;
						C2 += gradX * gradT;
						C1 += gradY * gradT;
					}
				}
				var delta:Number = (A1B2 * A1B2 - A2 * B1);
				if (delta) {
					/* system is not singular - solving by Kramer method */
					var deltaX:Number = -(C1 * A1B2 - C2 * B1);
					var deltaY:Number = -(A1B2 * C2 - A2 * C1);
					var Idelta:Number = 8 / delta;
					u = deltaX * Idelta;
					v = deltaY * Idelta;
				} else {
					/* singular system - find optical flow in gradient direction */
					var Norm:Number = (A1B2 + A2) * (A1B2 + A2) + (B1 + A1B2) * (B1 + A1B2);
					if (Norm) {
						var IGradNorm:Number = 8 / Norm;
						var temp:Number = -(C1 + C2) * IGradNorm;
						u = (A1B2 + A2) * temp;
						v = (B1 + A1B2) * temp;
					} else {
						u = v = 0;
					}
				}
				if (-winStep < u && u < winStep && -winStep < v && v < winStep) {
					uu += u;
					vv += v;
					n++;
				}
			}
		}
		uu /= n;
		vv /= n;
		motionAmount = Math.round(AMOUNT_SCALE * Math.sqrt((uu * uu) + (vv * vv)));
		if (motionAmount > THRESHOLD) motionDirection = ((Math.atan2(vv, uu) * toDegree + 270) % 360) - 180; // Scratch direction
		analysisDone = true;
	}

}}
