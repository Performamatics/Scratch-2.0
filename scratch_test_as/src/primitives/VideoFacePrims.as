// VideoFacePrims.as
// Tony Hwang and John Maloney, January 2011
//
// Video motion sensing primitives.

package primitives {
	import flash.display.*;
	import flash.geom.*;
	import flash.utils.Dictionary;
	import blocks.Block;
	import interpreter.*;
	import facedetector.jp.maaash.ObjectDetection.ObjectDetector;

public class VideoFacePrims {

	private const WIDTH:int = 200;
	private const HEIGHT:int = 150;

	private var app:Scratch;
	private var interp:Interpreter;
	private var detector:ObjectDetector;
	private var frameBuf:BitmapData;
	private var analysisDone:Boolean;

	private var faceDetected:Boolean;
	private var faceX:int;
	private var faceY:int;

	public function VideoFacePrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
		detector = new ObjectDetector();
		frameBuf = new BitmapData(WIDTH, HEIGHT);
	}

	public function addPrimsTo(primTable:Dictionary):void {
		primTable['faceDetected']	= primFaceDetected;
		primTable['faceX']			= primFaceX;
		primTable['faceY']			= primFaceY;
	}

	private function primFaceDetected(b:Block):Boolean {
		startFaceDetector();
		if (!analysisDone) analyzeFrame();
		return faceDetected;
	}

	private function primFaceX(b:Block):int {
		startFaceDetector();
		if (!analysisDone) analyzeFrame();
		return faceX;
	}

	private function primFaceY(b:Block):int {
		startFaceDetector();
		if (!analysisDone) analyzeFrame();
		return faceY;
	}

	private function startFaceDetector():void { app.runtime.faceDetector = this }
	private function stopFaceDetector():void { app.runtime.faceDetector = null }
	
	public function step():void {
		if (!(app.stagePane && app.stagePane.videoImage)) {
			faceDetected = false;
			faceX = faceY = 0;
			analysisDone = true;
			stopFaceDetector();
			return;
		}
		analysisDone = false;
	}

	private function analyzeFrame():void {
		if (!(app.stagePane && app.stagePane.videoImage)) return;

		var m:Matrix = new Matrix();
		m.scale(WIDTH / app.stagePane.videoImage.width, HEIGHT / app.stagePane.videoImage.height);
		frameBuf.draw(app.stagePane.videoImage, m);

		var faceRects:Array = detector.detect(frameBuf);
		if (faceRects.length == 0) {
			faceDetected = false;
		} else {
			faceDetected = true;
			var r:Rectangle = faceRects[0];
			faceX = (480 / WIDTH) * (((r.left + r.right) / 2) - (WIDTH / 2));
			faceY = (360 / HEIGHT) * ((HEIGHT / 2) - ((r.top + r.bottom) / 2));
		}
		analysisDone = true;
	}

}}
