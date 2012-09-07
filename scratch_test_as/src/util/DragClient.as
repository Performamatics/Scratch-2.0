package util {
	import flash.events.MouseEvent;

public interface DragClient {
	function dragBegin(evt:MouseEvent):void;
	function dragMove(evt:MouseEvent):void;
	function dragEnd(evt:MouseEvent):void;
}}
