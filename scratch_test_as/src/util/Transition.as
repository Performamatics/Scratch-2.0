package util {
	import flash.utils.getTimer;

public class Transition {

	private static var activeTransitions:Array = [];

	private var setValue:Function;
	private var startValue:Number;
	private var endValue:Number;
	private var delta:Number;
	private var duration:uint;
	private var startMSecs:uint;
	private var whenDone:Function;

	public function Transition(setValue:Function, startValue:Number, endValue:Number, secs:Number, whenDone:Function) {
		this.setValue = setValue;
		this.startValue = startValue;
		this.endValue = endValue;
		this.delta = endValue - startValue;
		this.duration = 1000 * secs;
		this.startMSecs = getTimer();
		this.whenDone = whenDone;
	}

	public static function easeOut(setValue:Function, startValue:Number, endValue:Number, secs:Number, whenDone:Function = null):void {
		activeTransitions.push(new Transition(setValue, startValue, endValue, secs, whenDone));
	}

	public static function step(evt:*):void {
		if (activeTransitions.length == 0) return;
		var now:uint = getTimer();
		var newActive:Array = [];
		for each (var t:Transition in activeTransitions) {
			 if (t.apply(now)) newActive.push(t);
		}
		activeTransitions = newActive;
	}

	private function apply(now:uint):Boolean {
		var t:Number = (now - startMSecs) / duration;
		if (t > 1.0) {
			setValue(endValue);
			if (whenDone != null) whenDone();
			return false;
		}
		setValue(startValue + (delta * (1.0 - cubic(1.0 - t))));
		return true;
	}

	// Transition functions:
	private static function linear(t:Number):Number { return t }
	private static function quadratic(t:Number):Number { return t * t }
	private static function cubic(t:Number):Number { return t * t * t }

}}
