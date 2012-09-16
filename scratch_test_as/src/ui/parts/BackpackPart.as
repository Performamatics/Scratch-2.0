// BackpackPart.as
// John Maloney, November 2011
//
// This part holds a collection of items in the user's backpack.

package ui.parts {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.SharedObject;
	import flash.text.*;
	import flash.utils.getTimer;
	import blocks.BlockIO;
	import ui.media.*;
	import uiwidgets.*;
	import util.*;
	import blocks.Block;

public class BackpackPart extends UIPart {

	public const fullHeight:int = 130;

	private const arrowColor:int = 0xA6A8AC;
	private const backpackBarH:int = 20;
	private const checkInterval:uint = 3000; // interval between calls to updateThumbnails (msecs)
	private const closed:int = 17;

	public var openAmount:int = closed; // how 'open' the tab is; 0 is entirely off screen

	private var shape:Shape;
	private var title:TextField;
	private var arrow:Shape;
	private var contentsFrame:ScrollFrame;
	private var contents:ScrollFrameContents;

	private var animationRunning:Boolean;
	private var lastThumbnailCheckTime:uint;

	public function BackpackPart(app:Scratch) {
		this.app = app;
		shape = new Shape();
		addChild(shape);
		title = makeLabel('Backpack', CSS.titleFormat);
		addChild(title);
		arrow = new Shape();
		addChild(arrow);
		addContentsPane();
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
	}

	public function loadBackpack():void { fetchInitialContents(app.userName) }

	// -----------------------------
	// Layout
	//------------------------------

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();
		drawTopBar(g, CSS.titleBarColors, getTopBarPath(w, backpackBarH), w, backpackBarH);
		if ((h - backpackBarH) > 10) drawArrowDown();
		else drawArrowUp();
		if ((h - backpackBarH) > 10) {
			g.lineStyle(1, CSS.borderColor);
			g.drawRect(0, backpackBarH, w, h - backpackBarH);
		}
		fixLayout();
	}

	private function fixLayout():void {
		title.x = 16;
		title.y = -1;
		arrow.x = (w - arrow.width) / 2;
		arrow.y = 5;
		contentsFrame.x = 1;
		contentsFrame.y = backpackBarH + 1;
		contentsFrame.setWidthHeight(w - 1, h - contentsFrame.y);
	}

	private function drawArrowUp():void {
		var g:Graphics = arrow.graphics;
		g.clear();
		g.lineStyle(0, 0, 0);
		g.beginFill(arrowColor);
		g.moveTo(0,6);
		g.lineTo(8,6);
		g.lineTo(4,0);
		g.endFill();
	}

	private function drawArrowDown():void {
		var g:Graphics = arrow.graphics;
		g.clear();
		g.lineStyle(0, 0, 0);
		g.beginFill(arrowColor);
		g.moveTo(0, 0);
		g.lineTo(8, 0);
		g.lineTo(4, 6);
		g.endFill();
	}

	private function addContentsPane():void {
		contents = new ScrollFrameContents();
		contents.color = CSS.panelColor;
		contentsFrame = new ScrollFrame();
		contentsFrame.setContents(contents);
		addChild(contentsFrame);
	}

	// -----------------------------
	// Inserting Items
	//------------------------------

	public function dropMediaInfo(item:MediaInfo):void {
		insertItem(item);
		saveToServer();
	}

	// -----------------------------
	// Persistance Support
	//------------------------------

	private function fetchInitialContents(user:String):void {
		function gotBackpack(s:String):void {
			removeAllItems();
			if (!s) return;
			var elements:Array = JSON_AB.parse(s) as Array;
			if (!elements) return;
			addAllItems(elements);
			fixItemLayout();
		}
		if (user && (user.length > 0)) Server.getBackpack(user, gotBackpack);
		else readFromLocalStorage();
	}

	private function fetchNewItemsFromServer(whenDone:Function):void {
		// Add any new items from the server since the last sync. (This might
		// happen if the user adds to their backpack from another browser tab.)
		function gotBackpack(s:String):void {
			if (s) {
				var elements:Array = JSON_AB.parse(s) as Array;
				if (elements && (elements.length > 0)) {
					var existing:Array = [];
					for each (var item:MediaInfo in allItems()) existing.push(item.dbObj.md5);
					var itemsToAdd:Array = [];
					for each (var o:Object in elements) {
						if (existing.indexOf(o.md5) < 0) itemsToAdd.push(o);
					}
					addAllItems(itemsToAdd);
				}
			}
			if (whenDone != null) whenDone();
		}
		Server.getBackpack(app.userName, gotBackpack);
	}

	private function saveToServer():void {
		function done(s:String):void { app.browserTrace('saved backpack ' + s + ' on server') }
		removeDuplicates();
		var elements:Array = [];
		for each (var item:MediaInfo in allItems()) elements.push(copyItemForSave(item.dbObj));
		if (app.userName == '') saveToLocalStorage(elements);
		else Server.setBackpack(elements, app.userName, done);
	}

	private function copyItemForSave(item:Object):Object {
		// Copy an item to be saved. Copy all fields except the 'fromBackpack' field.
		var dup:Object = {};
		for (var field:String in item) {
			if (field != 'fromBackpack') dup[field] = item[field];
		}
		return dup;
	}

	private function saveToLocalStorage(elements:Array):void {
		// Save backpack data to local storage. (This is done when
		// the user is not logged in or the server is not available.)
		var sharedObj:SharedObject = SharedObject.getLocal('Scratch');
		sharedObj.data.backpack = JSON_AB.stringify(elements);
		sharedObj.flush();
	}

	private function readFromLocalStorage():void {
		// Read backpack data from local storage.
		var sharedObj:SharedObject = SharedObject.getLocal('Scratch');
		removeAllItems();
		if (sharedObj.data.backpack) addAllItems(JSON_AB.parse(sharedObj.data.backpack) as Array);
	}

	private function addAllItems(items:Array):void {
		if (items.length == 0) return;
		for each (var dbObj:Object in items) {
			var script:Block = null;
			if (dbObj.type == 'script') {
				if (dbObj.md5 && !dbObj.script) {
					dbObj.script = dbObj.md5;
					delete dbObj.md5;
				}
				if (dbObj.script) script = BlockIO.stringToStack(dbObj.script);
			}
			dbObj.fromBackpack = true;	
			var knownTypes:Array = ['image', 'sound', 'script'];
			if (knownTypes.indexOf(dbObj.type) >= 0) contents.addChild(new MediaInfo(null, script, dbObj));
		}
		fixItemLayout();
	}

	private function removeDuplicates():void {
		var unique:Array = [];
		for each (var item:MediaInfo in allItems()) {
			if (unique.indexOf(item.dbObj.md5) < 0) unique.push(item.dbObj.md5);
			else contents.removeChild(item);
		}
		fixItemLayout();
	}

	// -----------------------------
	// Items
	//------------------------------

	public function deleteItem(item:MediaInfo):void {
		// Called by button on a backpack item.
		contents.removeChild(item);
		saveToServer();
		fixItemLayout();
	}

	private function insertItem(newItem:MediaInfo):void {
		var i:int;
		for each (var existingItem:MediaInfo in allItems()) {
			if (existingItem.dbObj.md5 == newItem.dbObj.md5) contents.removeChild(existingItem);
		}
		var localX:int = contents.globalToLocal(newItem.localToGlobal(new Point(0, 0))).x;
		for (i = 0; i < contents.numChildren; i++) {
			if (contents.getChildAt(i).x > localX) break;
		}
		newItem.addDeleteButton();
		newItem.dbObj.fromBackpack = true;
		contents.addChildAt(newItem, i);
		fixItemLayout();
	}

	private function allItems():Array {
		var items:Array = [];
		for (var i:int = 0; i < contents.numChildren; i++) {
			var item:MediaInfo = contents.getChildAt(i) as MediaInfo;
			if (item) items.push(item);
		}
		return items;
	}

	private function removeAllItems():void {
		while (contents.numChildren > 0) contents.removeChildAt(0);
	}

	private function fixItemLayout():void {
		var nextX:int = 10;
		for each (var item:MediaInfo in allItems()) {
			item.x = nextX;
			item.y = 10;
			nextX += item.frameWidth + 10;
		}
	}

	// -----------------------------
	// Open/Close Animation
	//------------------------------

	private function mouseDown(e:MouseEvent):void {
		var p:Point = globalToLocal(new Point(e.stageX, e.stageY));
		if ((p.y > 0) && (p.y < backpackBarH)) {
			toggleOpenClose();
			e.stopImmediatePropagation();
		}
	}

	private function toggleOpenClose():void {
		function setOpenAmount(n:int):void {
			openAmount = n;
			app.fixLayout(null);
		}
		function animationDone():void {
			animationRunning = false;
			if (openAmount == fullHeight) {
				app.openBackpack = backpack;
				addEventListener(Event.ENTER_FRAME, updateThumbnails);
			} else {
				app.openBackpack = null;
				removeEventListener(Event.ENTER_FRAME, updateThumbnails);
			}
		}
		var backpack:BackpackPart = this;
		if (animationRunning) return;
		var h:int = (openAmount < fullHeight) ? fullHeight : closed;
		animationRunning = true;
		Transition.easeOut(setOpenAmount, openAmount, h, 0.1, animationDone);
	}

	private function updateThumbnails(evt:Event):void {
		if ((getTimer() - lastThumbnailCheckTime) > checkInterval) {
			for each (var item:MediaInfo in allItems()) {
				item.updateThumbnail();
			}
			lastThumbnailCheckTime = getTimer();
		}
	}

}}
