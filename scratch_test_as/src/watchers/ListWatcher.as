package watchers {
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
	import scratch.ScratchObj;
	import util.JSON_AB;
	import uiwidgets.*;
	import interpreter.Interpreter;
	//import com.adobe.serialization.json.*;		// added by Matt Vaughan
	
public class ListWatcher extends Sprite {

	private const titleFont:TextFormat = new TextFormat("Verdana", 10, 0, true);
	private const cellNumFont:TextFormat = new TextFormat("Verdana", 10, 0, false);
	private const SCROLLBAR_W:int = 10;

	public var listName:String = "";
	public var target:ScratchObj; // the ScratchObj that owns this list
	public var contents:Array = [];
	public var isPersistent:Boolean = false;

	private var frame:WatcherFrame;
	private var title:TextField;
	private var elementCount:TextField;
	private var cellPane:Sprite;
	private var scrollbar:Scrollbar;
	private var addItemButton:IconButton;

	private var firstVisibleIndex:int;
	private var visibleCells:Array = [];
	private var visibleCellNums:Array = [];
	private var insertionIndex:int = -1; // where to add an item; -1 means to add it at the end

	private var cellPool:Array = []; // recycled cells
	private var cellNumPool:Array = []; // recycled cell numbers
	private var tempCellNum:TextField; // used to compute maximum cell number width

	private var lastAccess:Vector.<uint> = new Vector.<uint>();
	private var lastActiveIndex:int;
	private var contentsChanged:Boolean;
	private var isIdle:Boolean;

	public function ListWatcher(listName:String = "List Title", contents:Array = null, target:ScratchObj = null) {
		this.listName = listName;
		this.target = target;
		this.contents = (contents == null) ? [] : contents;

		frame = new WatcherFrame(0x949191, 0xC1C4C7, 14, false, 2);
		frame.setWidthHeight(50, 100);
		frame.showResizer();
		frame.minWidth = frame.minHeight = 60;
		addChild(frame);

		title = createTextField(listName, titleFont);
		frame.addChild(title);

		cellPane = new Sprite();
		cellPane.mask = new Shape();
		cellPane.addChild(cellPane.mask);
		addChild(cellPane);

		scrollbar = new Scrollbar(10, 10, scrollToFraction);
		addChild(scrollbar);

		addItemButton = new IconButton(addItem, "addItem");
		addChild(addItemButton);

		elementCount = createTextField('length: 0', cellNumFont);
		frame.addChild(elementCount);

		setWidthHeight(100, 200);
		addEventListener(flash.events.FocusEvent.FOCUS_IN, gotFocus);
		addEventListener(flash.events.FocusEvent.FOCUS_OUT, lostFocus);
	}

	public function updateTitleAndContents():void {
		// Called when opening a project.
		updateTitle();
		scrollToIndex(0);
	}

	public function menu():Menu {
		var m:Menu = new Menu();
		m.addItem('import', importList);
		m.addItem('export', exportList);
		m.addLine();
		m.addItem("hide", hide);
		return m;
	}

	private function importList():void {
		// Prompt user for a file name and import that file.
		// Each line of the file becomes a list item.
		function fileSelected(event:Event):void {
			if (fileList.fileList.length == 0) return;
			file = FileReference(fileList.fileList[0]);
			file.addEventListener(Event.COMPLETE, fileLoadHandler);
			file.load();
		}
		function fileLoadHandler(event:Event):void {
			var s:String = file.data.readUTFBytes(file.data.length);
			var delimiter:String = '\n';
			if (s.indexOf(delimiter) < 0) delimiter = '\r';
			contents = s.split(delimiter);
			scrollToIndex(0);
		}
		var fileList:FileReferenceList = new FileReferenceList();
		var file:FileReference;
		fileList.addEventListener(Event.SELECT, fileSelected);
		fileList.browse();
	}

	private function exportList():void {
		var file:FileReference = new FileReference();
		var s:String = '';
		for each (var el:* in contents) s += el + '\n';
		if (s.length > 0) s = s.slice(0, s.length - 1); // remove final '\n'
		file.save(s);
	}

	private function hide():void { visible = false }

	// -----------------------------
	// Visual feedback for list changes
	//------------------------------

	public function updateWatcher(i:int, readOnly:Boolean, interp:Interpreter):void {
		// Colled by list primitives. Reccord acces to entry at i and if list contents has changed.
		// Note: To reduce the cost of list operations, updateWatcher() merely records changes,
		// leaving the more time-consuming work of updating the visual feedback to step(), which
		// is called only once per frame.
		if (parent == null) {
			visible = false;
			return;
		}
		isIdle = false;
		if (!readOnly) contentsChanged = true;
		adjustLastAccessSize();
		if ((i < 1) || (i > lastAccess.length)) return;
		lastAccess[i - 1] = getTimer();
		lastActiveIndex = i - 1;
		interp.redraw();
	}

	public function step():void {
		// Update index highlights.
		if (isIdle) return;
		if (contentsChanged) {
			updateContents();
			updateScrollbar();
			contentsChanged = false; 
		}
		if (contents.length == 0) return;
		ensureVisible();
		updateIndexHighlights();
	}

	private function ensureVisible():void {
		var i:int = Math.max(0, Math.min(lastActiveIndex, contents.length - 1));
		if ((firstVisibleIndex <= i) && (i < (firstVisibleIndex + visibleCells.length))) {
			return; // index is already visible
		}
		firstVisibleIndex = i;
		updateContents();
		updateScrollbar();
	}

	private function updateIndexHighlights():void {
		// Highlight the cell number of all recently accessed cells currently visible.
		adjustLastAccessSize();
		var now:int = getTimer();
		isIdle = true; // try to be idle; set to false if any non-zero lastAccess value is found
		for (var i:int = 0; i < visibleCellNums.length; i++) {
			var lastAccessTime:int = lastAccess[firstVisibleIndex + i];
			if (lastAccessTime > 0) {
				isIdle = false;
				var msecsSinceAccess:int = now - lastAccessTime;
				if (msecsSinceAccess < 1000) {
					var gray:int = ((1000 - msecsSinceAccess) / 4) & 255;
					visibleCellNums[i].textColor = (gray << 16) | (gray << 8);
				} else {
					visibleCellNums[i].textColor = 0; // black
					lastAccess[firstVisibleIndex + i] = 0;
				}
			}
		}
	}

	private function adjustLastAccessSize():void {
		// Ensure that lastAccess is the same length as contents.
		if (lastAccess.length == contents.length) return;
		if (lastAccess.length < contents.length) {
			lastAccess = lastAccess.concat(new Vector.<uint>(contents.length - lastAccess.length));
		} else if (lastAccess.length > contents.length) {
			lastAccess = lastAccess.slice(0, contents.length);
		}
	}

	// -----------------------------
	// Add Item Button Support
	//------------------------------

	private function addItem(b:IconButton):void {
		// Called when addItemButton is clicked.
		if ((root is Scratch) && !(root as Scratch).editMode) return;
		if (insertionIndex < 0) insertionIndex = contents.length;
		contents.splice(insertionIndex, 0, '***');
		updateContents();
		updateScrollbar();
	}

	private function gotFocus(e:FocusEvent):void {
		// When the user clicks on a cell, it gets keyboard focus.
		// Record that list index for possibly inserting a new cell.
		// Note: focus is lost when the addItem button is clicked.
		var newFocus:DisplayObject = e.target as DisplayObject;
		if (newFocus == null) return;
		insertionIndex = -1;
		for (var i:int = 0; i < visibleCells.length; i++) {
			if (visibleCells[i] == newFocus.parent) {
				insertionIndex = firstVisibleIndex + i;
				return;
			}
		}
	}

	private function lostFocus(e:FocusEvent):void {
		// If another object is getting focus, clear insertionIndex.
		if (e.relatedObject != null) insertionIndex = -1;
	}

	// -----------------------------
	// Layout
	//------------------------------

	public function setWidthHeight(w:int, h:int):void {
		frame.setWidthHeight(w, h);
		fixLayout();
	}

	public function fixLayout():void {
		// Called by WatcherFrame, so must be public.
		title.x = Math.floor((frame.w - title.width) / 2);
		title.y = 2;
	
		elementCount.x = Math.floor((frame.w - elementCount.width) / 2);
		elementCount.y = frame.h - elementCount.height + 1;

		cellPane.x = 1;
		cellPane.y = 22;

		addItemButton.x = 2;
		addItemButton.y = frame.h - addItemButton.height - 2;

		var g:Graphics = (cellPane.mask as Shape).graphics;
		g.clear();
		g.beginFill(0);
		g.drawRect(0, 0, frame.w - 17, frame.h - 42);
		g.endFill();

		scrollbar.setWidthHeight(SCROLLBAR_W, cellPane.mask.height);
		scrollbar.x = frame.w - SCROLLBAR_W - 2;
		scrollbar.y = 20;

		updateContents();
		updateScrollbar();
	}

	// -----------------------------
	// List contents layout and scrolling
	//------------------------------

	private function scrollToFraction(n:Number):void {
		var old:int = firstVisibleIndex;
		n = Math.floor(n * contents.length);
		firstVisibleIndex = Math.max(0, Math.min(n, contents.length - 1));
		lastActiveIndex = firstVisibleIndex;
		if (firstVisibleIndex != old) updateContents();
	}

	private function scrollToIndex(i:int):void {
		var frac:Number = i / (contents.length - 1);
		firstVisibleIndex = -1; // force scrollToFraction() to always update contents
		scrollToFraction(frac);
		updateScrollbar();
	}

	private function updateScrollbar():void {
		var frac:Number = (firstVisibleIndex - 1) / (contents.length - 1);
		scrollbar.update(frac, visibleCells.length / contents.length);
	}

	private function updateContents():void {
		var isEditable:Boolean = (root is Scratch) && (root as Scratch).editMode;
		updateElementCount();
		removeAllCells();
		visibleCells = [];
		visibleCellNums = [];
		var visibleHeight:int = cellPane.height;
		var cellNumRight:int = cellNumWidth() + 14;
		var cellX:int = cellNumRight;
		var cellW:int = cellPane.width - cellX - 1;
		var nextY:int = 0;
		for (var i:int = firstVisibleIndex; i < contents.length; i++) {
			var cell:ListCell = allocateCell(contents[i], cellW);
			cell.x = cellX;
			cell.y = nextY;
			cell.setEditable(isEditable);
			visibleCells.push(cell);
			cellPane.addChild(cell);

			var cellNum:TextField = allocateCellNum(String(i + 1));
			cellNum.x = cellNumRight - cellNum.width - 3;
			cellNum.y = nextY + int((cell.height - cellNum.height) / 2);
			cellNum.textColor = 0;
			visibleCellNums.push(cellNum);
			cellPane.addChild(cellNum);
			
			nextY += cell.height - 1;
			if (nextY > visibleHeight) break;
		}
//		isIdle = false;
	}

	private function cellNumWidth():int {
		// Return the estimated maxium cell number width. We assume that a list
		// can display at most 20 elements, so we need enough width to display
		// firstVisibleIndex + 20. Take the log base 10 to get the number of digits
		// and measure the width of a textfield with that many zeros.
		if (tempCellNum == null) tempCellNum = createTextField('', cellNumFont);
		var digitCount:int = Math.log(firstVisibleIndex + 20) / Math.log(10);
		tempCellNum.text = '000000000000000'.slice(0, digitCount);
		return tempCellNum.textWidth;
	}

	private function removeAllCells():void {
		// Remove all children except the mask. Reycle ListCells and TextFields.
		while (cellPane.numChildren > 1) {
			var o:DisplayObject = cellPane.getChildAt(1);
			if (o is ListCell) cellPool.push(o);
			if (o is TextField) cellNumPool.push(o);
			cellPane.removeChildAt(1);
		}
	}

	private function allocateCell(s:String, width:int):ListCell {
		// Allocate a ListCell with the given contents and width.
		// Recycle one from the cell pool if possible.
		if (cellPool.length == 0) return new ListCell(s, width, textChanged, nextCell);
		var result:ListCell = cellPool.pop();
		result.setText(s, width);
		return result;
	}

	private function allocateCellNum(s:String):TextField {
		// Allocate a TextField for a cell number with the given contents.
		// Recycle one from the cell number pool if possible.
		if (cellNumPool.length == 0) return createTextField(s, cellNumFont);
		var result:TextField = cellNumPool.pop();
		result.text = s;
		result.width = result.textWidth + 5;
		return result;
	}

	private function createTextField(s:String, format:TextFormat):TextField {
		var tf:TextField = new TextField();
		tf.type = "dynamic"; // not editable
		tf.selectable = false;
		tf.defaultTextFormat = format;
		tf.text = s;
		tf.height = tf.textHeight + 5
		tf.width = tf.textWidth + 5;
		return tf;
	}

	private function updateTitle():void {
		title.text = ((target == null) || (target.isStage)) ? listName : target.objName + " " + listName;
		title.width = title.textWidth + 5;
		title.x = Math.floor((frame.w - title.width) / 2);
	}

	private function updateElementCount():void {
		elementCount.text = 'length: ' + contents.length;
		elementCount.width = elementCount.textWidth + 5;
		elementCount.x = Math.floor((frame.w - elementCount.width) / 2);
	}

	// -----------------------------
	// User Input (handle events for cell's TextField)
	//------------------------------

	private function textChanged(e:Event):void {
		// Triggered by editing the contents of a cell. Copy the
		// the cell contents into the underlying list.
		var cellContents:TextField = e.target as TextField;
		for (var i:int = 0; i < visibleCells.length; i++) {
			var cell:ListCell = visibleCells[i];
			if (cell.tf == cellContents) contents[firstVisibleIndex + i] = cellContents.text;
		}
	}

	private function nextCell(e:Event):void {
		// Triggered by tab key. Select the next cell in the list.
		var cellContents:TextField = e.target as TextField;
		for (var i:int = 0; i < visibleCells.length; i++) {
			var cell:ListCell = visibleCells[i];
			if (cell.tf == cellContents) {
				e.preventDefault();
				if (contents.length < 2) return; // only one cell, and it's already selected
				if ((i + 1) < visibleCells.length) {
					stage.focus = visibleCells[i + 1];
					return;
				} else {
					var selectIndex:int = (firstVisibleIndex + i + 1) % contents.length;
					scrollToIndex(selectIndex);
					var j:int = firstVisibleIndex - selectIndex;
					if ((j >= 0) && (j < visibleCells.length)) stage.focus = visibleCells[j];
				}
			}
		}
	}

	// -----------------------------
	// Saving
	//------------------------------

	public function writeJSON(json:JSON_AB):void {
		json.writeKeyValue("listName", listName);
		json.writeKeyValue("contents", contents);
		json.writeKeyValue("isPersistent", isPersistent);
		json.writeKeyValue("target", target.objName);
		json.writeKeyValue("x", x);
		json.writeKeyValue("y", y);
		json.writeKeyValue("width", width);
		json.writeKeyValue("height", height);
		json.writeKeyValue("visible", visible && (parent != null));
	}

	public function readJSON(obj:Object):void {
		listName = obj.listName;
		contents = obj.contents;
		isPersistent = (obj.isPersistent == undefined) ? false : obj.isPersistent; // handle old projects gracefully
		target = obj.target;
		x = obj.x;
		y = obj.y;
		setWidthHeight(obj.width, obj.height);
		visible = obj.visible;
		updateTitleAndContents();
	}

}}
