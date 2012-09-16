// SoundRecorder.as
// Anton Nguyen, March 2011

package soundui {
	import flash.display.*;
	import flash.events.*;
	import flash.media.Microphone;
	import flash.text.*;
	
public class MicrophoneActivityBar extends Sprite {

	private var bar:Shape;
	private var w:int, h:int;
	private var microphone:Microphone;

	public function MicrophoneActivityBar(barWidth:Number = 25, barHeight:Number = 100) {
		w = barWidth;
		h = barHeight;

		// border of the bar
		graphics.lineStyle(1);
		graphics.drawRect(0, 0, w, h);

		// the actual bar
		bar = new Shape();
		addChild(bar);

		addLabels();
		addEventListener(Event.ENTER_FRAME, step);
	}

	public function setMicrophone(m:Microphone):void { microphone = m }

	private function step(event:Event):void {
		if (microphone == null) return;
		var fillHeight:Number = h * microphone.activityLevel / 100;
		var g:Graphics = bar.graphics;
		g.clear();
		g.beginFill(0xFF0000);
		g.drawRect(0, h - fillHeight, w, fillHeight);
	}

	private function addLabels():void {
		const fmt:TextFormat = new TextFormat("Verdana", 9);

		var maxdB:TextField = new TextField();
		maxdB.text = "100";
		maxdB.selectable = false;
		maxdB.x = w + 5;
		maxdB.setTextFormat(fmt);
		addChild(maxdB);

		var mindB:TextField = new TextField();
		mindB.text = "0";
		mindB.selectable = false;
		mindB.x = w + 5;
		mindB.y = h - 15;
		mindB.setTextFormat(fmt);
		addChild(mindB);
	}

}}
