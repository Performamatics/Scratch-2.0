package util {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.filters.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.getTimer;
	import blocks.*;
	import scratch.*;
	import ui.*;
	import ui.media.*;
	import uiwidgets.*;
	import watchers.ListWatcher;
	import watchers.Watcher;

public class GestureHandler {

	private const CLICK_MSECS:int = 250;

	public var mouseIsDown:Boolean;
	public var carriedObj:Sprite;

	private var app:Scratch;
	private var dragClient:DragClient;
	private var mouseDownTime:uint;
	private var gesture:String = "idle";
	private var mouseTarget:*;
	private var objToGrabOnUp:Sprite;
	private var mouseDownEvent:MouseEvent;

	public function GestureHandler(app:Scratch) {
		this.app = app;
	}

	public function setDragClient(newClient:DragClient, evt:MouseEvent):void {
		Menu.removeMenusFrom(app.stage);
		if (dragClient != null) dragClient.dragEnd(evt);
		dragClient = newClient as DragClient;
		dragClient.dragBegin(evt);
		evt.stopImmediatePropagation();
	}

	public function grabOnMouseUp(obj:Sprite):void { objToGrabOnUp = obj }

	public function step():void {
		if ((gesture == "unknown") && ((getTimer() - mouseDownTime) > CLICK_MSECS)) {
			if (mouseTarget != null) handleDrag(new MouseEvent(""));
			if (gesture != 'drag') handleClick(mouseDownEvent);
//			gesture = "drag";
		}
	}

	public function mouseDown(evt:MouseEvent):void {
		mouseIsDown = true;
		mouseDownTime = getTimer();
		mouseDownEvent = evt;
		gesture = "unknown";
		mouseTarget = null;

		if (carriedObj != null) { drop(); return }

		if (dragClient != null) {
			dragClient.dragBegin(evt);
			return;
		}
//		if (evt.ctrlKey) return showDebugFeedback(evt);

		var t:* = evt.target;
		if ((t is TextField) && (TextField(t).type == TextFieldType.INPUT)) return;
		mouseTarget = findMouseTarget(evt, t);
		if (mouseTarget == null) {
			gesture = "ignore";
			return;
		}
		if (doClickImmediately()) {
			handleClick(evt);
//			gesture = "click";
			return;
		}
		if (evt.shiftKey && app.editMode && ('menu' in mouseTarget)) {
			gesture = "menu";
			return;
		}
	}

	private function doClickImmediately():Boolean {
		// Answer true when clicking on the stage or a locked sprite in play (presentation) mode.
		if (app.editMode) return false;
		if (mouseTarget is ScratchStage) return true;
		return (mouseTarget is ScratchSprite) && !ScratchSprite(mouseTarget).isDraggable;
	}

	public function mouseMove(evt:MouseEvent):void {
		mouseIsDown = evt.buttonDown;
		if (dragClient != null) {
			dragClient.dragMove(evt);
			return;
		}
		if (gesture == "unknown") {
			if (mouseTarget != null) handleDrag(evt);
//			gesture = "drag";
			return;
		}
		if ((gesture == "drag") && (carriedObj is Block)) {
			app.scriptsPane.updateFeedbackFor(Block(carriedObj));
		}
		if ((gesture == "drag") && (carriedObj is ScratchSprite)) {
			var stageP:Point = app.stagePane.globalToLocal(carriedObj.localToGlobal(new Point(0, 0)));
			var spr:ScratchSprite = ScratchSprite(carriedObj);
			spr.scratchX = stageP.x - 240;
			spr.scratchY = 180 - stageP.y;
		}
	}

	public function mouseUp(evt:MouseEvent):void {
		mouseIsDown = false;
		if (dragClient != null) {
			var oldClient:DragClient = dragClient;
			dragClient = null;
			oldClient.dragEnd(evt);
			return;
		}
		drop();
		Menu.removeMenusFrom(app.stage);
		if (gesture == "unknown") handleClick(evt);
		if (gesture == "menu") handleMenu(evt);
		if (app.scriptsPane) app.scriptsPane.draggingDone();
		mouseTarget = null;
		gesture = "idle";
		if (objToGrabOnUp != null) {
			gesture = "drag";
			grab(objToGrabOnUp);
			objToGrabOnUp = null;
		}
	}

	private function findMouseTarget(evt:MouseEvent, target:*):DisplayObject {
		// Find the mouse target for the given event. Return null if no target found.

		if ((target is TextField) && (TextField(target).type == TextFieldType.INPUT)) return null;
		if ((target is Button) || (target is IconButton)) return null;

		var o:DisplayObject = DisplayObject(evt.target);
		while (o != null) {
			if (isMouseTarget(o, evt.stageX, evt.stageY)) break;
			o = o.parent;
		}
		if ((o is Block) && Block(o).isEmbeddedInProcHat()) o = o.parent;
		if (o is ScratchObj) o = findMouseTargetOnStage(evt.stageX, evt.stageY);
		if (!isMouseTarget(o, evt.stageX, evt.stageY)) return null;
		return o;
	}

	private function findMouseTargetOnStage(globalX:int, globalY:int):DisplayObject {
		// Find the front-most, visible stage element at the given point.
		// Take sprite shape into account so you can click or grab a sprite
		// through a hole in another sprite that is in front of it.
		// Return the stage if no other object is found.
		for (var i:int = app.stagePane.numChildren - 1; i > 0; i--) {
			var o:DisplayObject = app.stagePane.getChildAt(i);
			if (o is Bitmap) break; // hit the paint layer of the stage; no more elments
			if (o.visible && o.hitTestPoint(globalX, globalY, true)) return o;
		}
		return app.stagePane;		
	}

	private function isMouseTarget(o:DisplayObject, globalX:int, globalY:int):Boolean {
		// To make an object a possible mouse target, add its class to this list.
		// (An object must be a mouse target to be get click() and menu() callbacks
		// and to be draggable.)
		var grabbable:Array = [
			Block, ScratchSprite, ScratchStage, Watcher, ListWatcher,
			MediaInfo, SpriteThumbnail];
		for each (var c:Class in grabbable) {
			if ((o is c) && o.hitTestPoint(globalX, globalY, true)) return true;
		}
		return false;
	}

	private function handleDrag(evt:MouseEvent):void {
		Menu.removeMenusFrom(app.stage);
		if ((mouseTarget is ScratchStage) || (mouseTarget is ScrollFrame)) return;
		if (mouseTarget is MediaInfo) {
			var mInfo:MediaInfo = mouseTarget as MediaInfo;
			if (mInfo.inLibrary) return; // don't drag items in library window 
			if (mInfo && mInfo.mycostume && (!mInfo.mycostume.baseLayerBitmap)) return;
		}
		if (mouseTarget is SpriteThumbnail) return;
		if (!app.editMode) {
			if ((mouseTarget is ScratchSprite) && !ScratchSprite(mouseTarget).isDraggable) return; // don't drag locked sprites in presentation mode
			if ((mouseTarget is Watcher) || (mouseTarget is ListWatcher)) return; // don't drag watchers in presentation mode
		}

		var p:Point = app.globalToLocal(mouseTarget.localToGlobal(new Point(0, 0)));
		if (mouseTarget is Block) {
			var b:Block = mouseTarget;
			if (isInPalette(b)) {
				b = b.duplicate(false);
				b.x = p.x;
				b.y = p.y;
				mouseTarget = b;
			}
		}
		if (mouseTarget is MediaInfo) {
			mouseTarget = mouseTarget.copyForDrag();
			mouseTarget.x = p.x - 5;
			mouseTarget.y = p.y;
		}
		grab(mouseTarget);
		gesture = 'drag';
	}

	private function handleClick(evt:MouseEvent):void {
		if (mouseTarget == null) return;
		if (mouseTarget is Block) {
			app.runtime.interp.toggleThread(Block(mouseTarget).topBlock(), app.viewedObj());
		}
		if (mouseTarget is ScratchObj) {
			app.runtime.startClickedHats(ScratchObj(mouseTarget))			
		}
		if ('click' in mouseTarget) mouseTarget.click(evt);
		gesture = 'click';
	}

	private function handleMenu(evt:MouseEvent):void {
		if (mouseTarget == null) return;
		var menu:Menu;
		try { menu = mouseTarget.menu() } catch (e:Error) {}
		if (menu != null) {
			menu.showOnStage(app.stage, evt.stageX, evt.stageY);
		}
	}

	private function grab(obj:Sprite):void {
		drop();
		var p:Point = app.globalToLocal(obj.localToGlobal(new Point(0, 0)));
		if (obj is Block) {
			var b:Block = Block(obj);
			b.saveOriginalPosition();
			if (b.parent is Block) Block(b.parent).removeBlock(b);
			if (b.parent != null) b.parent.removeChild(b);
			app.scriptsPane.prepareToDrag(b);
		} else {
			if (obj.parent != null) obj.parent.removeChild(obj);
			if ((obj is ScratchSprite) && (app.stagePane.scaleX != 1)) {
				obj.scaleX = obj.scaleY = (obj.scaleX * app.stagePane.scaleX);
			}
		}
		if (app.editMode) addDropShadowTo(obj);
		app.addChild(obj);
		obj.x = p.x;
		obj.y = p.y;
		obj.startDrag();
		carriedObj = obj;
	}

	private function drop():void {
		if (carriedObj == null) return;
		carriedObj.stopDrag();
		removeDropShadowFrom(carriedObj);
		var centerX:int = carriedObj.localToGlobal(new Point(0, 0)).x + (carriedObj.width / 2);
		var centerY:int = carriedObj.localToGlobal(new Point(0, 0)).y + (carriedObj.height / 2);
		if (carriedObj is Block) {
			var b:Block = Block(carriedObj);
			if (isOverPalette()) {
				app.removeChild(b);
				b.restoreOriginalPosition();
				app.scriptsPane.saveScripts();
			} else if (app.openBackpack && (centerY >= app.openBackpack.y)) {
				app.removeChild(b);
				var scriptData:Object = {
					type: 'script',
					md5: BlockIO.stackToString(b),
					name: 'from ' + app.projectName
				}
				app.openBackpack.dropMediaInfo(new MediaInfo(null, b));
				if (b.wasInScriptsPane) {
					b.restoreOriginalPosition();
					app.scriptsPane.addChild(b);
				}
			} else {
				app.scriptsPane.blockDropped(b);
				if (b.op == Specs.PROCEDURE_DEF) {
					app.updatePalette();
				}
			}
			app.scriptsPane.draggingDone();
		} else if (carriedObj is MediaInfo) {
			var item:MediaInfo = carriedObj as MediaInfo;
			item.parent.removeChild(item);
			if (app.openBackpack && (centerY > app.openBackpack.y)) {
				app.openBackpack.dropMediaInfo(item);
			} else {
				app.dropMediaInfo(item);
			}
		} else {
			if ((carriedObj is ScratchSprite) && (app.stagePane.scaleX != 1)) {
				carriedObj.scaleX = carriedObj.scaleY = carriedObj.scaleX / app.stagePane.scaleX;
			}
			var p:Point = app.stagePane.globalToLocal(new Point(carriedObj.x, carriedObj.y));
			carriedObj.x = p.x;
			carriedObj.y = p.y;
			app.stagePane.addChild(carriedObj);
			if (carriedObj is ScratchSprite) {
				ScratchSprite(carriedObj).setScratchXY(p.x - 240, 180 - p.y);
			} else {
				app.stagePane.show(carriedObj, true);
			}
		}
		carriedObj = null;
	}

	private function isOverPalette():Boolean {
		return app.palette.hitTestPoint(app.mouseX, app.mouseY);
	}

	private function isInPalette(b:Block):Boolean {
		if (b.isEmbeddeParameter()) return true;
		var o:DisplayObject = b;
		while (o != null) {
			if (o == app.palette) return true;
			o = o.parent;
		}
		return false;
	}

	public function ownerThatIsA(o:*, c:Class):DisplayObject {
		if (!(o is DisplayObject)) return null;
		var result:DisplayObject = DisplayObject(o);
		while (o != null) {
			if (o is c) return o;
			o = o.parent;
		}
		return null;
	}

	private function addDropShadowTo(o:DisplayObject):void {
		var f:DropShadowFilter = new DropShadowFilter();
		var blockScale:Number = (app.scriptsPane) ? app.scriptsPane.scaleX : 1;
		f.distance = 8 * blockScale;
		f.blurX = f.blurY = 2;
		f.alpha = 0.4;
		o.filters = o.filters.concat([f]);
	}

	private function removeDropShadowFrom(o:DisplayObject):void {
		var newFilters:Array = [];
		for each (var f:* in o.filters) {
			if (!(f is DropShadowFilter)) newFilters.push(f);
		}
		o.filters = newFilters;
	}

	/* Debugging */

	private var debugSelection:DisplayObject;

	private function showDebugFeedback(evt:MouseEvent):void {
		var stage:DisplayObject = evt.target.stage;
		if (debugSelection != null) {
			removeDebugGlow(debugSelection);
			if (debugSelection.getRect(stage).containsPoint(new Point(stage.mouseX, stage.mouseY))) {
				debugSelection = debugSelection.parent;
			} else {
				debugSelection = DisplayObject(evt.target);
			}
		} else {
			debugSelection = DisplayObject(evt.target);
		}
		if (debugSelection is Stage) {
			debugSelection = null;
			return;
		}
		trace(debugSelection);
		addDebugGlow(debugSelection);
	}

	private function addDebugGlow(o:DisplayObject):void {
		var newFilters:Array = [];
		if (o.filters != null) newFilters = o.filters;
		var f:GlowFilter = new GlowFilter(0xFFFF00);
		f.strength = 15;
		f.blurX = f.blurY = 6;
		f.inner = true;
		newFilters.push(f);
		o.filters = newFilters;
	}

	private function removeDebugGlow(o:DisplayObject):void {
		var newFilters:Array = [];
		for each (var f:* in o.filters) {
			if (!(f is GlowFilter)) newFilters.push(f);
		}
		o.filters = newFilters;
	}

}}
