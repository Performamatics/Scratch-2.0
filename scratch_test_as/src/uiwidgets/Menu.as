// Menu.as
// John Maloney, October 2009
//
// A simple one-level text menu. Menus are built using addItem() and addLine() and
// invoked using showOnStage(). When the menu operation is complete, the client function
// is called, if it isn't null. If the client function is null but the selected item is
// a function, then that function is called. This allows you to create a menu whose
// elements are actions. If callIfNoSelection and the client function is not null,
// the client function is called with null as the selection if no selection is made.

package uiwidgets {
	import flash.display.*;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;

public class Menu extends Sprite {

	public static var color:int = 0xFFFFFF;
	public static var selectedColor:int = 0xC0D0FF;
	public static var font:String = 'Verdana';
	public static var fontSize:int = 11;
	public static var fontSelectedColor:uint;
	public static var fontNormalColor:uint = 0x0;
	public static var minHeight:int=0;
	public static var divisionColor:uint= 0;
	public static var margin:int=0;
	public static var hasShadow:Boolean = true;

	public var clientFunction:Function;  // if not nil, called when menu interaction is done
	public var callIfNoSelection:Boolean;

	private var allItems:Array = [];
	private var firstItemIndex:int = 0;
	private var maxHeight:int = 400;
	private var maxScrollIndex:int;

	private static var menuJustCreated:Boolean;

	public function Menu(clientFunction:Function = null, callIfNoSelection:Boolean = false) {
		this.clientFunction = clientFunction;
		this.callIfNoSelection = callIfNoSelection;
	}

	public function addItem(label:String, value:* = null, enabled:Boolean = true):void {
		var last:MenuItem = (numChildren > 0) ? MenuItem(getChildAt(numChildren - 1)) : null;
		var newItem:MenuItem = new MenuItem(label, value, enabled);
		allItems.push(newItem);
	}

	public function addLine():void {
		addItem('---');
	}

	public function showOnStage(stage:Stage, x:int = -1, y:int = -1):void {
		removeMenusFrom(stage); // remove old menus
		menuJustCreated = true;
		prepMenu(stage);
		scrollBy(0);
		this.x = (x > 0) ? x : stage.mouseX + 5;
		this.y = (y > 0) ? y : stage.mouseY - 5;
		// keep menu on screen
		this.x = Math.max(0, Math.min(this.x, stage.stageWidth - this.width));
		this.y = Math.max(0, Math.min(this.y, stage.stageHeight - this.height));
		stage.addChild(this);
		addEventListener(Event.ENTER_FRAME, step);
	}

	public function selected(itemValue:*):void {
		// run the clientFunction, if there is one.
		// otherwise, if itemValue is a function, run that
		if (clientFunction != null) {
			clientFunction(itemValue);
		} else {
			if (itemValue is Function) itemValue();
		}
		if (parent != null) parent.removeChild(this);
	}

	static public function removeMenusFrom(o:DisplayObjectContainer):void {
		if (menuJustCreated) { menuJustCreated = false; return }
		var i:int, menus:Array = [];
		for (i = 0; i < o.numChildren; i++) {
			if (o.getChildAt(i) is Menu) menus.push(o.getChildAt(i));
		}
		for (i = 0; i < menus.length; i++) {
			var m:Menu = Menu(menus[i]);
			if (m.callIfNoSelection) m.selected(null);
			if (m.parent != null) m.parent.removeChild(m);
		}
	}

	private function prepMenu(stage:Stage):void {
		var i:int, maxW:int = 0;
		var item:MenuItem;
		// find the widest menu item...
		for each (item in allItems) maxW = Math.max(maxW, item.width + Menu.margin);
		// then make all items that wide
		for each (item in allItems) item.setWidth(maxW);
		// compute max height
		maxHeight = stage.stageHeight - 50;
		// compute max scrollIndex
		var totalH:int;
		for (maxScrollIndex = allItems.length - 1; maxScrollIndex > 0; maxScrollIndex--) {
			totalH += allItems[maxScrollIndex].height;
			if (totalH > maxHeight) break;
		}
		if (hasShadow) addFilters();
	}

	private function step(e:Event):void {
		if (parent == null) {
			removeEventListener(Event.ENTER_FRAME, step);
			return;
		}
		var localY:int = this.globalToLocal(new Point(stage.mouseX, stage.mouseY)).y;
		if ((localY < 2) && (firstItemIndex > 0)) scrollBy(-1);
		if ((localY > this.height) && (firstItemIndex < maxScrollIndex)) scrollBy(1);
	}

	private function scrollBy(delta:int):void {
		firstItemIndex += delta;
		var nextY:int = 1;
		// remove any existing children
		while (this.numChildren > 0) this.removeChildAt(0);
		// add menu items
		for (var i:int = firstItemIndex; i < allItems.length; i++) {
			var item:MenuItem = allItems[i];
			addChild(item);
			item.x = 1;
			item.y = nextY;
			nextY += item.height;
			if (nextY > maxHeight) break;
		}
		drawBackground();
	}

	private function drawBackground():void {
	/*
		var w:int = 50, h:int = 20;
		if (numChildren > 0) {
			var last:MenuItem = MenuItem(getChildAt(numChildren - 1));
			w = last.width + 2;
			h = last.y + last.height + 1;
		}

		graphics.clear();
		graphics.lineStyle(2, 0x404040);
		graphics.beginFill(color);
		graphics.drawRoundRect(0, 0, w, h, 8, 8);
		graphics.endFill();
		*/
	}

	private function addFilters():void {
		var f:DropShadowFilter = new DropShadowFilter();
		f.blurX = f.blurY = 5;
		f.distance = 3;
		f.color = 0x333333;
		filters = [f];
	}

}}