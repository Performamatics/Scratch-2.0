package util {
	import flash.utils.getQualifiedClassName;

public class DebugUtils {

	public static function printTree(top:DisplayObject):String {
		var result:String = '';
		printSubtree(top, 0, result);
		return result;
	}

	private static function printSubtree(t:DisplayObject, indent:int, out:String):void {
		var tabs:String = '';
		for (var i:int = 0; i < indent; i++) tabs += '\t';
		out += tabs + getQualifiedClassName(t) + '\n';
		var container:DisplaObjectContainer = t as DisplaObjectContainer;
		if (container == null) return;
		for (i = 0; i < container.numChildren; i++) {
			printTree(container.getChildAt(i), indent + 1);
		}
	}

}}
