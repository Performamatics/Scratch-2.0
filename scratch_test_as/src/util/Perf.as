package util {
	import flash.external.ExternalInterface;
	import flash.utils.getTimer;

public class Perf {

	private static var totalStart:uint;
	private static var lapStart:uint;
	private static var lapTotal:uint;

	public static function start(msg:String = null):void {
totalStart = 0;
return; // xxx disable reporting
		if (!msg) msg = 'Perf.start';
		browserTrace(msg);
		totalStart = lapStart = getTimer();
		lapTotal = 0;
	}

	public static function clearLap():void {
		lapStart = getTimer();
	}

	public static function lap(msg:String = ""):void {
		if (totalStart == 0) return; // not monitoring performance
		var lapMSecs:uint = getTimer() - lapStart;
		browserTrace('  ' + msg + ': ' + lapMSecs + ' msecs');
		lapTotal += lapMSecs;
		lapStart = getTimer();
	}

	public static function end():void {
		if (totalStart == 0) return; // not monitoring performance
		var totalMSecs:uint = getTimer() - totalStart;
		var unaccountedFor:uint = totalMSecs - lapTotal;
		browserTrace('Total: ' + totalMSecs + ' msecs; unaccounted for: ' + unaccountedFor + ' msecs (' + int((100 * unaccountedFor) / totalMSecs) + '%)');
		totalStart = lapStart = lapTotal = 0;
	}

	public static function browserTrace(s:String):void {
		if (ExternalInterface.available) ExternalInterface.call("console.log", s);
	}

}}
