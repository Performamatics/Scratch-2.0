// PaletteBuilder.as
// John Maloney, September 2010
//
// PaletteBuilder generates the contents of the blocks palette for a given
// category, including the blocks, buttons, and watcher toggle boxes.

package scratch {
	import flash.display.*;
	import flash.text.*;
	import blocks.*;
	import interpreter.Variable;
	import uiwidgets.*;
	import watchers.ListWatcher;

public class PaletteBuilder {

	private var app:Scratch;
	private var nextY:int;

	public function PaletteBuilder(app:Scratch) {
		this.app = app;
	}

	public function showBlocksForCategory(selectedCategory:int):void {
		if (app.palette == null) return;
		app.palette.clear();
		nextY = 7;

		if (selectedCategory == Specs.variablesCategory) return showVariablesPalette();
		if (selectedCategory == Specs.myBlocksCategory) return showMyBlocks();

		var catName:String = Specs.categories[selectedCategory][1];
		var catColor:int = Specs.blockColor(selectedCategory);
		if (app.viewedObj() && app.viewedObj().isStage) {
			// The stage has different blocks for some categories
			if (catName == 'Motion') {
				addItem(makeLabel('Stage selected:'));
				nextY -= 6;
				addItem(makeLabel('No motion blocks'));
				return;
			}
			if (catName == 'Looks') selectedCategory += 100;
			if (catName == 'Pen') selectedCategory += 100;
			if (catName == 'Sensing') selectedCategory += 100;
		}
		addBlocksForCategory(selectedCategory, catColor);
	}

	private function addBlocksForCategory(category:int, catColor:int, defaultListName:String = ''):void {
		var cmdCount:int;
		for each (var spec:Array in Specs.commands) {
			if ((spec.length > 3) && (spec[2] == category)) {
				var blockColor:int = (app.interp.isImplemented(spec[3])) ? catColor : 0x505050;
				var block:Block = new Block(spec[0], spec[1], blockColor, spec[3], spec.slice(4));
				setListArgs(block, defaultListName);
				addItem(block);
				cmdCount++;
			} else {
				if ((spec.length == 1) && (cmdCount > 0)) nextY += 10 * spec[0].length; // add some space
				cmdCount = 0;
			}
		}
	}

	private function setListArgs(block:Block, defaultListName:String):void {
		for each (var arg:BlockArg in block.args) {
			if ((arg.type == 'm') && (arg.menuName == 'listName')) arg.setArgValue(defaultListName);
		}
	}

	private function addItem(o:DisplayObject):void {
		o.x = 6;
		o.y = nextY;
		app.palette.addChild(o);
		app.palette.updateSize();
		nextY += o.height + 5;
	}

	private function makeLabel(label:String):TextField {
		var t:TextField = new TextField();
		t.autoSize = TextFieldAutoSize.LEFT;
		t.selectable = false;
		t.background = false;
		t.text = label;
		t.setTextFormat(CSS.paletteSectionFormat);
		return t;
	}

	private function showMyBlocks():void {
		// show creation button, hat, and call blocks
		var catColor:int = Specs.blockColor(Specs.blocksCategory);
		addItem(new Button('Make a Block', defineProc));
		for each (var proc:Block in app.viewedObj().procedureDefinitions()) {
			var b:Block = new Block(proc.spec, ' ', Specs.procedureCallColor, Specs.CALL, proc.defaultArgValues);
			addItem(b);
		}
	}

	private function showVariablesPalette():void {
		var catColor:int = Specs.blockColor(Specs.variablesCategory);

		// variable buttons, reporters, and set/change blocks
		addItem(new Button('Make a Variable', makeVariable));
		var varNames:Array = app.runtime.allVarNames();
		if (varNames.length > 0) {
			for each (var n:String in varNames) {
				addItem(new Block(n, 'r', catColor, Specs.GET_VAR));
			}
			nextY += 10;
			var defaultVarName:String = varNames[varNames.length - 1];
			addItem(new Block('set %v to %s', ' ', catColor, Specs.SET_VAR, [defaultVarName, 0]));
			addItem(new Block('change %v by %n', ' ', catColor, Specs.CHANGE_VAR, [defaultVarName, 10]));
			addItem(new Block('show variable %v', ' ', catColor, 'showVariable:', [defaultVarName, 1]));
			addItem(new Block('hide variable %v', ' ', catColor, 'hideVariable:', [defaultVarName, 1]));

			nextY += 15;
		}

		// lists
		catColor = Specs.blockColor(Specs.listCategory);
		addItem(new Button('Make a List', makeList));

		var listNames:Array = app.runtime.allListNames();
		if (listNames.length > 0) {
			for each (n in listNames) {
				addItem(new Block(n, 'r', catColor, Specs.GET_LIST));
			}
			nextY += 10;
			var defaultListName:String = listNames[listNames.length - 1];
			addBlocksForCategory(Specs.listCategory, catColor, defaultListName);
			nextY += 15;
		}
	}

	private function makeVariable():void {
		function makeVar2():void {
			var n:String = d.fields['Name'].text;
			if (n.length == 0) return;
			var persistent:Boolean = d.booleanFields['Cloud'].isOn()
			if (persistent) {
				// Persistent variables are always global. This needs to be reflected in the UI
				var v:Variable = app.stageObj().lookupOrCreateVar('\u2601 '+n); // 2601 is the Unicode cloud character
				v.isPersistent = true;
			} else {
				app.runtime.createVariable(n);
			}
			app.updatePalette();
		}
		var d:DialogBox = new DialogBox(makeVar2);
		d.addTitle('New Variable');
		d.addField('Name', 120);
		d.addBoolean('Cloud');
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function makeList():void {
		function makeList2():void {
			var w:ListWatcher;
			var n:String = d.fields['Name'].text;
			if (n.length == 0) return;
			var persistent:Boolean = d.booleanFields['Cloud'].isOn()
			if (persistent) {
				w = app.stageObj().lookupOrCreateList('\u2601 ' + n);  // 2601 is the Unicode cloud character
				w.isPersistent = true;
				// Somewhat ugly: Initialize on the server
				// We have to do this because the Scratch code may start
				// with a list append, which does not create a new list on
				// the server. Only lset() initializes a new list serverside
				app.persistenceManager.setList(w.listName, w.contents);
			} else {
				w = app.runtime.createList(n);
			}
			app.stagePane.show(w);
			app.updatePalette();
		}
		var d:DialogBox = new DialogBox(makeList2);
		d.addTitle('New List');
		d.addField('Name', 120);
		d.addBoolean('Cloud');
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function defineProc():void {
		var d:DialogBox = new DialogBox(defineProc2);
		d.addTitle('New Block');
		d.addField('Name', 120);
		d.fields['Name'].text = 'block-name';
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function defineProc2(dialog:DialogBox):void {
		var blockName:String = dialog.fields['Name'].text;
		if (blockName.length == 0) return;
		var newHat:Block = new Block(blockName, 'p', Specs.variableColor, Specs.PROCEDURE_DEF);
		app.updatePalette();
		newHat.x = 10 + (200 * Math.random());
		newHat.y = 10 + (300 * Math.random());
		app.scriptsPane.addChild(newHat);
		app.scriptsPane.saveScripts();
		app.runtime.updateCalls();
		app.updatePalette();
	}

}}
