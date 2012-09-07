// ListPrimitives.as
// John Maloney, September 2010
//
// List primitives.

package primitives {
	import blocks.Block;
	import interpreter.Interpreter;
	import watchers.ListWatcher;

public class ListPrims {

	private var app:Scratch;
	private var interp:Interpreter;

	public function ListPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Object):void {
		primTable[Specs.GET_LIST]		= primContents;
		primTable['append:toList:']		= primAppend;
		primTable['deleteLine:ofList:']	= primDelete;
		primTable['insert:at:ofList:']	= primInsert;
		primTable['setLine:ofList:to:']	= primReplace;
		primTable['getLine:ofList:']	= primGetItem;
		primTable['lineCountOfList:']	= primLength;
		primTable['list:contains:']		= primContains;
	}

	private function primContents(b:Block):String {
		var list:ListWatcher = interp.targetObj().lookupOrCreateList(b.spec);
		return (list.contents.join(' '));
	}

	private function primAppend(b:Block):void {
		var list:ListWatcher = listarg(b, 1);
		list.contents.push(interp.arg(b, 0));
		if (list.isPersistent) this.app.persistenceManager.appendList(list.listName, interp.arg(b, 0));
		if (list.visible) list.updateWatcher(list.contents.length, false, interp);
	}

	private function primDelete(b:Block):void {
		var which:* = interp.arg(b, 0);
		var list:ListWatcher = listarg(b, 1);
		var len:int = list.contents.length;
		if (which == 'all') {
			list.contents = new Array();
			if (list.visible) list.updateWatcher(-1, false, interp);
			if (list.isPersistent) this.app.persistenceManager.setList(list.listName, list.contents);
			return;
		}
		var n:Number = (which == 'last') ? len : Number(which);
		if (isNaN(n)) return;
		var i:int = Math.round(n);
		if ((i < 1) || (i > len)) return;
		list.contents.splice (i - 1, 1);
		if (list.visible) list.updateWatcher(((i == len) ? i - 1 : i), false, interp);
		if (list.isPersistent) this.app.persistenceManager.deleteList(list.listName, i);
	}

	private function primInsert(b:Block):void {
		var val:* = interp.arg(b, 0);
		var where:* = interp.arg(b, 1);
		var list:ListWatcher = listarg(b, 2);
		if (where == 'last') {
			list.contents.push(val);
			if (list.visible) list.updateWatcher(list.contents.length, false, interp);
			if (list.isPersistent) this.app.persistenceManager.appendList(list.listName, val);
		} else {
			var i:int = computeIndex(where, list.contents.length + 1);
			if (i < 0) return;
			list.contents.splice(i - 1, 0, val);
			if (list.visible) list.updateWatcher(i, false, interp);
			if (list.isPersistent) this.app.persistenceManager.insertList(list.listName, val, i);
		}
	}

	private function primReplace(b:Block):void {
		var list:ListWatcher = listarg(b, 1);
		var i:int = computeIndex(interp.arg(b, 0), list.contents.length);
		if (i < 0) return;
		list.contents.splice(i - 1, 1, interp.arg(b, 2));
		if (list.visible) list.updateWatcher(i, false, interp);
		if (list.isPersistent) this.app.persistenceManager.replaceList(list.listName, interp.arg(b, 2), i);
	}

	private function primGetItem(b:Block):String {
		var list:ListWatcher = listarg(b, 1);
		var i:int = computeIndex(interp.arg(b, 0), list.contents.length);
		if (i < 0) return '';
		if (list.visible) list.updateWatcher(i, true, interp);
		return list.contents[i - 1];
	}

	private function primLength(b:Block):Number {
		var list:ListWatcher = listarg(b, 0);
		return list.contents.length;
	}

	private function primContains(b:Block):Boolean {
		var list:ListWatcher = listarg(b, 0);
		var item:* = interp.arg(b, 1);
		if (list.contents.indexOf(item) >= 0) return true;
		for each (var el:* in list.contents) {
			// use Scratch comparision operator (Scratch considers the string '123' equal the number 123)
			if (Primitives.compare(el, item) == 0) return true;
		}
		return false;
	}

	private function listarg(b:Block, i:int):ListWatcher {
		if (b.cache != null) return b.cache;
		return b.cache = interp.targetObj().lookupOrCreateList(interp.arg(b, i));
	}

	private function computeIndex(n:*, len:int):int {
		var i:int;
		if (!(n is Number)) {
			if (n == 'last') return len;
			if (n == 'any') return 1 + Math.floor(Math.random() * len);
			n = Number(n);
			if (isNaN(n)) return -1;
		}
		i = (n is int) ? n : Math.round(n);
		if ((i < 1) || (i > len)) return -1;
		return i;
	}

}}
