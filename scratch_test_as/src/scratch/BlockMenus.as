package scratch {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.geom.*;
	import flash.ui.*;
	import blocks.*;
	import filters.*;
	import interpreter.*;
	import sound.*;
	import ui.ProcedureSpecEditor;
	import uiwidgets.*;
	import util.*;
	import watchers.ListWatcher;

public class BlockMenus implements DragClient {

	private var block:Block;
	private var blockArg:BlockArg;  // null if menu is invoked on a block
	private var app:Scratch;

	public static function BlockMenuHandler(evt:MouseEvent, block:Block, blockArg:BlockArg = null, menuName:String = null):void {
		var menuHandler:BlockMenus = new BlockMenus(block, blockArg, 0);
		if (menuName == null) {
			var op:String = block.op;
			if (op == Specs.GET_VAR) menuName = 'varMenu';
			if ((op == Specs.PROCEDURE_DEF) || (op == Specs.CALL)) menuName = 'procMenu';
			if ((op == 'broadcast:') || (op == 'doBroadcastAndWait') || (op == 'whenIReceive'))
				menuName = 'broadcastInfoMenu';
			if (menuName == null) { menuHandler.genericBlockMenu(evt) }
		}
		if (menuName == 'attribute') menuHandler.attributeMenu(evt);
		if (menuName == 'booleanSensor') menuHandler.booleanSensorMenu(evt);
		if (menuName == 'sensor') menuHandler.sensorMenu(evt);
		if (menuName == 'broadcast') menuHandler.broadcastMenu(evt);
		if (menuName == 'broadcastInfoMenu') menuHandler.broadcastInfoMenu(evt);
		if (menuName == 'bubbleStyle') menuHandler.bubbleStyleMenu(evt);
		if (menuName == 'colorPicker') menuHandler.colorPicker(evt);
		if (menuName == 'costume') menuHandler.costumeMenu(evt);
		if (menuName == 'direction') menuHandler.dirMenu(evt);
		if (menuName == 'drum') menuHandler.drumMenu(evt);
		if (menuName == 'effect') menuHandler.effectMenu(evt);
		if (menuName == 'fontStyle') menuHandler.fontStyleMenu(evt);
		if (menuName == 'instrument') menuHandler.instrumentMenu(evt);
		if (menuName == 'key') menuHandler.keyMenu(evt);
		if (menuName == 'listDeleteItem') menuHandler.listItem(evt, true);
		if (menuName == 'listItem') menuHandler.listItem(evt, false);
		if (menuName == 'listName') menuHandler.listName(evt);
		if (menuName == 'mathOp') menuHandler.mathOpMenu(evt);
		if (menuName == 'motorDirection') menuHandler.motorDirectionMenu(evt);
		if (menuName == 'procMenu') menuHandler.procMenu(evt);
		if (menuName == 'scene') menuHandler.sceneMenu(evt);
		if (menuName == 'sound') menuHandler.soundMenu(evt);
		if (menuName == 'spriteOrMouse') menuHandler.spriteMenu(evt, true, false, false);
		if (menuName == 'spriteOrStage') menuHandler.spriteMenu(evt, false, false, true);
		if (menuName == 'touching') menuHandler.spriteMenu(evt, true, true, false);
		if (menuName == 'varMenu') menuHandler.varMenu(evt);
	}

	public function BlockMenus(block:Block, blockArg:BlockArg, foo:int) {
		this.blockArg = blockArg;
		this.block = block;
		styleMenu(block);
		app = Scratch(block.root);
	}

	public function styleMenu(b:Block):void{
		Menu.font ="Lucida Grande";
		Menu.divisionColor =  Color.scaleBrightness( b.base.color, 0.52);
		Menu.color =  b.base.color;
		Menu.selectedColor = Color.scaleBrightness(Color.scaleSaturation( b.base.color, 0.75), 10); 
		Menu.fontSize =11;
		Menu.fontNormalColor = 0xFFFFFF;
		Menu.fontSelectedColor =  Color.scaleBrightness( b.base.color, 0.52);
		Menu.minHeight = 20;
		Menu.margin = 5;
		Menu.hasShadow = true;
	}

	private function setBlockArg(selection:*):void {
		if (blockArg != null) blockArg.setArgValue(selection);
	}

	public function attributeMenu(evt:MouseEvent):void {
		var obj:* = app.stagePane.objNamed(String(block.args[1].argValue));
		var attributes:Array = ['x position', 'y position', 'direction', 'costume #', 'size', 'volume'];
		if (obj is ScratchStage) attributes = ['background #', 'volume'];
		var m:Menu = new Menu(setBlockArg);
		for each (var s:String in attributes) m.addItem(s);
		if (obj is ScratchObj) {
			m.addLine();
			for each (s in obj.varNames().sort()) m.addItem(s);
		}
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function booleanSensorMenu(evt:MouseEvent):void {
		var sensorNames:Array = [
			'button pressed', 'A connected', 'B connected', 'C connected', 'D connected'];
		var m:Menu = new Menu(setBlockArg);
		for each (var s:String in sensorNames) m.addItem(s);
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function sensorMenu(evt:MouseEvent):void {
		var sensorNames:Array = [
			'slider', 'light', 'sound',
			'resistance-A', 'resistance-B', 'resistance-B', 'resistance-C', 'resistance-D',
			'---',
			'tilt', 'distance'];
		var m:Menu = new Menu(setBlockArg);
		for each (var s:String in sensorNames) m.addItem(s);
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function bubbleStyleMenu(evt:MouseEvent):void {
		var styles:Array = ['say', 'think', 'whisper', 'shout'];
		var m:Menu = new Menu(setBlockArg);
		if (app.viewedObj() == null) return;
		for each (var s:String in styles) m.addItem(s);
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function colorPicker(evt:MouseEvent):void {
		app.gh.setDragClient(this, evt);
	}

	public function costumeMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg);
		if (app.viewedObj() == null) return;
		for each (var c:ScratchCostume in app.viewedObj().costumes) {
			m.addItem(c.costumeName);
		}
		m.addLine();
		m.addItem('CAMERA');
		m.addItem('CAMERA - MIRROR');
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function dirMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg);
		m.addItem('(90) right', 90);
		m.addItem('(-90) left', -90);
		m.addItem('(0) up', 0);
		m.addItem('(180) down', 180);
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function drumMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg);
		for (var i:int = 0; i < SoundBank.drumNames.length; i++) {
			var n:int = i + 35;
			var s:String = '(' + n + ') ' + SoundBank.drumNames[i];
			m.addItem(s, n);
		}
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function effectMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg);
		if (app.viewedObj() == null) return;
		for each (var s:String in FilterPack.filterNames) m.addItem(s);
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function fontStyleMenu(evt:MouseEvent):void {
		var styles:Array = ['plain', 'bold', 'fancy', 'comic', 'typewriter'];
		var m:Menu = new Menu(setBlockArg);
		if (app.viewedObj() == null) return;
		for each (var s:String in styles) m.addItem(s);
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function instrumentMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg);
		for (var i:int = 1; i < SoundBank.instrumentNames.length; i++) {
			m.addItem('(' + i + ') ' + SoundBank.instrumentNames[i], i);
		}
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function keyMenu(evt:MouseEvent):void {
		var ch:int;
		var namedKeys:Array = ['up arrow', 'down arrow', 'right arrow', 'left arrow', 'space'];
		var m:Menu = new Menu(setBlockArg);
		for each (var s:String in namedKeys) m.addItem(s);
		for (ch = 97; ch < 123; ch++) m.addItem(String.fromCharCode(ch)); // a-z
		for (ch = 48; ch < 58; ch++) m.addItem(String.fromCharCode(ch)); // 0-9
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function listItem(evt:MouseEvent, forDelete:Boolean):void {
		var m:Menu = new Menu(setBlockArg);
		m.addItem('1');
		m.addItem('last');
		if (forDelete) {
			m.addLine();
			m.addItem('all');
		} else {
			m.addItem('any');
		}		
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function listName(evt:MouseEvent):void {
		if (app.viewedObj() == null) return;
		var m:Menu = new Menu(setBlockArg);
		var vName:String;
		for each (vName in app.stageObj().listNames()) {
			m.addItem(vName);
		}
		if (!app.viewedObj().isStage) {
			m.addLine();
			for each (vName in app.viewedObj().listNames()) {
				m.addItem(vName);
			}
		}
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function mathOpMenu(evt:MouseEvent):void {
		var ops:Array = ['abs', 'sqrt', 'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'ln', 'log', 'e ^', '10 ^'];
		var m:Menu = new Menu(setBlockArg);
		for each (var op:String in ops) m.addItem(op);
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function motorDirectionMenu(evt:MouseEvent):void {
		var ops:Array = ['this way', 'that way', 'reverse'];
		var m:Menu = new Menu(setBlockArg);
		for each (var s:String in ops) m.addItem(s);
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function sceneMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg);
		for each (var scene:ScratchCostume in app.stageObj().costumes) {
			m.addItem(scene.costumeName);
		}
		m.addLine();
		m.addItem('CAMERA');
		m.addItem('CAMERA - MIRROR');
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function soundMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg);
		if (app.viewedObj() == null) return;
		for (var i:int = 0; i < app.viewedObj().sounds.length; i++) {
			m.addItem(app.viewedObj().sounds[i].soundName);
		}
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	private function spriteMenu(evt:MouseEvent, includeMouse:Boolean, includeEdge:Boolean, includeStage:Boolean):void {
		var m:Menu = new Menu(setSpriteArg);
		if (includeMouse) m.addItem('mouse-pointer');
		if (includeEdge) m.addItem('edge');
		m.addLine();
		if (includeStage) {
			m.addItem(app.stagePane.objName, app.stagePane);
			m.addLine();
		}
		for each (var sprite:ScratchSprite in app.stagePane.sprites()) {
			if (sprite != app.viewedObj()) m.addItem(sprite.objName, sprite);
		}
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	private function setSpriteArg(spriteOrString:*):void {
		if (blockArg == null) return;
		if (spriteOrString is ScratchObj) {
			blockArg.setArgValue(ScratchObj(spriteOrString).objName);
			return;
		}
		if (spriteOrString == 'mouse-pointer') blockArg.setArgValue('_mouse_', 'mouse-pointer');
		if (spriteOrString == 'edge') blockArg.setArgValue('_edge_', 'edge');
	}

	// ***** Generic block menu *****

	private function genericBlockMenu(evt:MouseEvent):void {
		if (isInPalette(block)) return;
		var m:Menu = new Menu();
		m.addItem('duplicate', duplicateStack);
		m.addItem('delete', deleteStack);
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	private function duplicateStack():void {
		var newStack:Block = BlockIO.stringToStack(BlockIO.stackToString(block));
		newStack.x = block.x + 10;
		newStack.y = block.y + 10;
		block.parent.addChild(newStack);
		app.gh.grabOnMouseUp(newStack);
	}

	private function deleteStack():void {
		if (block.parent is Block) Block(block.parent).removeBlock(block);
		if (block.parent != null) block.parent.removeChild(block);
		app.scriptsPane.saveScripts();
	}

	// ***** Procedure menu (for procedure definition hats and call blocks) *****

	public function procMenu(evt:MouseEvent):void {
		var m:Menu = new Menu();
		if (block.op == Specs.PROCEDURE_DEF) {
			m.addItem('edit procedure name and parameters', editProcSpec);
		} else {
			if (!isInPalette(block)) {
				m.addItem('duplicate', duplicateStack);
				m.addItem('delete', deleteStack);
			}
		}
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	private function editProcSpec():void {
		var d:DialogBox = new DialogBox(editSpec2);
		d.addTitle('Edit Procedure Name and Parameters');
		d.addWidget(new ProcedureSpecEditor(block.spec, block.parameterNames));
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage, true);		
	}

	private function editSpec2(dialog:DialogBox):void {
		var newSpec:String = ProcedureSpecEditor(dialog.widget).spec();
		if (newSpec.length == 0) return;
		if (block != null) {
			var oldSpec:String = block.spec;
			block.parameterNames = ProcedureSpecEditor(dialog.widget).parameterNames();
			block.defaultArgValues = ProcedureSpecEditor(dialog.widget).defaultArgValues();
			block.setSpec(newSpec);
			for each (var caller:Block in app.runtime.allCallsOf(oldSpec)) {
				var oldArgs:Array = caller.args;
				caller.setSpec(newSpec, block.defaultArgValues);
				for (var i:int = 0; i < oldArgs.length; i++) {
					var arg:* = oldArgs[i];
					if (arg is BlockArg) arg = arg.argValue;
					caller.setArg(i, arg);
				}
				caller.fixArgLayout();
			}
		}
		app.runtime.updateCalls();
		app.updatePalette();
	}

	// ***** Variable menu *****

	public function varMenu(evt:MouseEvent):void {
		var i:int, m:Menu = new Menu(varMenuSelection);
		if (block.op == Specs.GET_VAR) {
			m.addItem('rename variable', changeVarName);
			if (isInPalette(block)) m.addItem('delete variable', deleteVar);
		} else {
			var vName:String;
			var w:ListWatcher;
			for each (vName in app.stageObj().varNames()) m.addItem(vName);
			for each (w in app.stageObj().lists) m.addItem(w.listName);
			if (!app.viewedObj().isStage) {
				m.addLine();
				for each (vName in app.viewedObj().varNames()) m.addItem(vName);
				for each (w in app.viewedObj().lists) m.addItem(w.listName);
			}
		}
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	private function isInPalette(b:Block):Boolean {
		var o:DisplayObject = b;
		while (o != null) {
			if (o == app.palette) return true;
			o = o.parent;
		}
		return false;
	}

	private function varMenuSelection(selection:*):void {
		if (selection is Function) { selection(); return }
		setBlockVarName(selection);
	}

	private function changeVarName():void {
		var d:DialogBox = new DialogBox(changeVarName2);
		d.addTitle('Rename ' + blockVarName());
		d.addField('New name', 120);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(block.stage);
	}

	private function changeVarName2(dialog:DialogBox):void {
		var newName:String = dialog.fields['New name'].text;
		if (newName.length == 0) return;
		var oldName:String = blockVarName();
		app.runtime.renameVariable(oldName, newName, block);
		setBlockVarName(newName);
		app.updatePalette();
	}

	private function setBlockVarName(newName:String):void {
		if (newName.length == 0) return;
		if ((block.op == Specs.GET_VAR) || (block.op == Specs.SET_VAR) || (block.op == Specs.CHANGE_VAR)) {
			app.runtime.createVariable(newName);
		}
		if (blockArg != null) blockArg.setArgValue(newName);
		if (block != null) {
			if (block.op == Specs.GET_VAR) block.setSpec(newName);
			block.cache = null;
		}
		app.updatePalette();
	}

	private function deleteVar():void {
		function deleteVar2(selection:*):void {
			app.runtime.deleteVariable(blockVarName());
			app.updatePalette();
		}
		DialogBox.confirm('Delete ' + blockVarName() + '?', app.stage, deleteVar2);
	}

	private function blockVarName():String {
		return (blockArg != null) ? blockArg.argValue : block.spec;
	}

	// ***** Color picker support *****

	public function dragBegin(evt:MouseEvent):void { }

	public function dragEnd(evt:MouseEvent):void {
		if (pickingColor) {
			pickingColor = false;
			Mouse.cursor = MouseCursor.AUTO;
		} else {
			pickingColor = true;
			app.gh.setDragClient(this, evt);
			Mouse.cursor = MouseCursor.BUTTON;
		}
	}

	public function dragMove(evt:MouseEvent):void {
		if (pickingColor) {
			blockArg.setArgValue(pixelColorAt(evt.stageX, evt.stageY));
		}
	}

	private var pickingColor:Boolean = false;
	private var onePixel:BitmapData = new BitmapData(1, 1);

	private function pixelColorAt(x:int, y:int):int {
		var m:Matrix = new Matrix();
		m.translate(-x, -y);
		onePixel.fillRect(onePixel.rect, 0);
		onePixel.draw(app, m);
		return onePixel.getPixel(0, 0) | 0xFF000000; // alpha is always 0xFF
	}

	// ***** Broadcast menu *****

	private function broadcastMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(broadcastMenuSelection);
		var allBroadcasts:Array = collectBroadcasts();
		for each (var msg:String in allBroadcasts) {
			m.addItem(msg);
		}
		m.addLine();
		m.addItem('new...', newBroadcast);
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	public function collectBroadcasts():Array {
		var result:Array = [];
		app.runtime.allStacksAndOwnersDo(function (stack:Block, target:ScratchObj):void {
			stack.allBlocksDo(function (b:Block):void {
				if ((b.op == 'broadcast:') ||
					(b.op == 'doBroadcastAndWait') ||
					(b.op == 'whenIReceive')) {
						if (b.args[0] is BlockArg) {
							var msg:String = b.args[0].argValue;
							if (result.indexOf(msg) < 0) result.push(msg);
						}
				}
			});
		});
		return result;
	}

	private function broadcastMenuSelection(selection:*):void {
		if (selection is Function) { selection(); return }
		setBlockArg(selection);
	}

	private function newBroadcast():void {
		var d:DialogBox = new DialogBox(newBroadcast2);
		d.addTitle('Broadcast');
		d.addField('Message Name', 120);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(block.stage);
	}

	private function newBroadcast2(dialog:DialogBox):void {
		var newName:String = dialog.fields['Message Name'].text;
		if (newName.length == 0) return;
		setBlockArg(newName);
	}

	private function broadcastInfoMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(broadcastInfoMenu2);
		if (!isInPalette(block)) {
			m.addItem('duplicate');
			m.addItem('delete');
			m.addLine();
		}
		m.addItem('show senders');
		m.addItem('show receivers');
		m.addItem('clear senders/receivers');
		m.showOnStage(block.stage, evt.stageX, evt.stageY);
	}

	private function broadcastInfoMenu2(selection:String):void {
		if (!isInPalette(block)) {
			if (selection == 'duplicate') { duplicateStack(); return }
			if (selection == 'delete') { deleteStack(); return }
		}
		var msg:String = block.args[0].argValue;
		var sprites:Array = [];
		if (selection == 'show senders') sprites = app.runtime.allSendersOfBroadcast(msg);
		if (selection == 'show receivers') sprites = app.runtime.allReceiversOfBroadcast(msg);
		app.highlightSprites(sprites);
	}

}}
