// SensingPrims.as
// John Maloney, April 2010
//
// Sensing primitives.

package primitives {
	import flash.display.*;
	import flash.geom.*;
	import flash.utils.Dictionary;
	import blocks.Block;
	import interpreter.*;
	import scratch.*;
	import watchers.*;

public class SensingPrims {

	private var app:Scratch;
	private var interp:Interpreter;

	public function SensingPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Dictionary):void {
		// sensing
		primTable["touching:"]			= primTouching;
		primTable["touchingColor:"]		= primTouchingColor;
		primTable["color:sees:"]		= primColorSees;

		primTable["doAsk"]				= primAsk;
		primTable["answer"]				= function(b:*):* { return app.runtime.lastAnswer };

		primTable["mousePressed"]		= function(b:*):* { return app.gh.mouseIsDown };
		primTable["mouseX"]				= function(b:*):* { return app.stagePane.scratchMouseX() };
		primTable["mouseY"]				= function(b:*):* { return app.stagePane.scratchMouseY() };
		primTable["timer"]				= function(b:*):* { return app.runtime.timer() };
		primTable["timerReset"]			= function(b:*):* { app.runtime.timerReset() };
		primTable["keyPressed:"]		= primKeyPressed;
		primTable["distanceTo:"]		= primDistanceTo;
		primTable["getAttribute:of:"]	= primGetAttribute;
		primTable["soundLevel"]			= function(b:*):* { return app.runtime.soundLevel() };
		primTable["isLoud"]				= function(b:*):* { return app.runtime.isLoud() };
		primTable["username"]			= primGetUserName;

		// variable watchers
		primTable["showVariable:"]		= primShowWatcher;
		primTable["hideVariable:"]		= primHideWatcher;

		// sensor
		primTable["sensor:"]			= function(b:*):* { return app.runtime.getSensor(interp.arg(b, 0)) };
		primTable["sensorPressed:"]		= function(b:*):* { return app.runtime.getBooleanSensor(interp.arg(b, 0)) };
	}

	private function primTouching(b:Block):Boolean {
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return false;
		var arg:* = interp.arg(b, 0);
		if ("_edge_" == arg) {
			var r:Rectangle = s.bounds();
			return  (r.left < 0) || (r.right > ScratchObj.STAGEW) ||
					(r.top < 0) || (r.bottom > ScratchObj.STAGEH);
		}
		if ("_mouse_" == arg) {
			var oldAlpha:Number = s.img.alpha;
			s.img.alpha = 1; // allow fully ghosted sprite to detect mouse touching
			var isTouchingMouse:Boolean = s.hitTestPoint(app.mouseX, app.mouseY, true);
			s.img.alpha = oldAlpha;
			return isTouchingMouse;
		}
		var s2:ScratchSprite = app.stagePane.spriteNamed(arg);
		if (s2 == null) return false;
		if (!s.visible || !s2.visible) return false;
		var myBM:BitmapData = s.bitmap();
		var otherBM:BitmapData = s2.bitmap();
		return myBM.hitTest(s.bounds().topLeft, 1, otherBM, s2.bounds().topLeft, 1);
	}

	private function primTouchingColor(b:Block):Boolean {
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return false;
		var c:int = interp.arg(b, 0) | 0xFF000000;;
		// Switch to LOW quality to disable anti-aliasing, which can create false colors
		var oldQuality:String = app.stage.quality;
		app.stage.quality = StageQuality.LOW;
		var myBM:BitmapData = s.bitmap();
		var stageBM:BitmapData = stageBitmapWithoutSpriteFilteredByColor(s, c);
		app.stage.quality = oldQuality;
		return myBM.hitTest(new Point(0, 0), 1, stageBM, new Point(0, 0), 1);
	}

	private function primColorSees(b:Block):Boolean {
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return false;
		var c1:int = interp.arg(b, 0) | 0xFF000000;
		var c2:int = interp.arg(b, 1) | 0xFF000000;
		// Switch to LOW quality to disable anti-aliasing, which can create false colors
		var oldQuality:String = app.stage.quality;
		app.stage.quality = StageQuality.LOW;
		var myBM:BitmapData = bitmapFilteredByColor(s.bitmap(), c1);
		var stageBM:BitmapData = stageBitmapWithoutSpriteFilteredByColor(s, c2);
		app.stage.quality = oldQuality;
		return myBM.hitTest(new Point(0, 0), 1, stageBM, new Point(0, 0), 1);
	}

	// useful for debugging:
	private var debugView:Bitmap;
	private function showBM(bm:BitmapData):void {
		if (debugView == null) {
			debugView = new Bitmap();
			debugView.scaleX = debugView.scaleY = 5;
			app.addChild(debugView);
		}
		debugView.bitmapData = bm;
	}

	private function bitmapFilteredByColor(srcBM:BitmapData, c:int):BitmapData {
		var outBM:BitmapData = new BitmapData(srcBM.width, srcBM.height, true, 0);
		outBM.threshold(srcBM, srcBM.rect, srcBM.rect.topLeft, "==", c, 0xFF000000, 0xF0F8F8F0); // match only top five bits of each component
		return outBM;
	}

	private function stageBitmapWithoutSpriteFilteredByColor(s:ScratchSprite, c:int):BitmapData {
		var bm1:BitmapData = app.stagePane.bitmapWithoutSprite(s);
		var bm2:BitmapData = new BitmapData(bm1.width, bm1.height, true, 0);
		bm2.threshold(bm1, bm1.rect, bm1.rect.topLeft, "==", c, 0xFF000000, 0xF0F8F8F0); // match only top five bits of each component
		return bm2;
	}

	private function primAsk(b:Block):void {
		if (app.runtime.askPromptShowing()) {
			// wait if (1) some other sprite is asking (2) this question is answered (when firstTime is false)
			interp.doYield();
			return;
		}
		var obj:ScratchObj = interp.targetObj();
		if (interp.activeThread.firstTime) {
			var question:String = interp.arg(b, 0);
			if ((obj is ScratchSprite) && (obj.visible)) {
				ScratchSprite(obj).showBubble(question, "talk", true);
				app.runtime.showAskPrompt("");
			} else {
				app.runtime.showAskPrompt(question);
			}
			interp.activeThread.firstTime = false;
			interp.doYield();
		} else {
			if ((obj is ScratchSprite) && (obj.visible)) ScratchSprite(obj).hideBubble();
			interp.activeThread.firstTime = true;
		}
	}

	private function primKeyPressed(b:Block):Boolean {
		var key:String = interp.arg(b, 0);
		var ch:int = key.charCodeAt(0);
		if (ch > 127) return false;
		if (key == "left arrow") ch = 28;
		if (key == "right arrow") ch = 29;
		if (key == "up arrow") ch = 30;
		if (key == "down arrow") ch = 31;
		if (key == "space") ch = 32;
		return app.runtime.keyIsDown[ch];
	}

	private function primDistanceTo(b:Block):Number {
		var s:ScratchSprite = interp.targetSprite();
		var p:Point = mouseOrSpritePosition(interp.arg(b, 0));
		if ((s == null) || (p == null)) return 0;
		var dx:Number = p.x - s.scratchX;
		var dy:Number = p.y - s.scratchY;
		return Math.sqrt((dx * dx) + (dy * dy));
	}

	private function primGetAttribute(b:Block):* {
		var attribute:String = interp.arg(b, 0);
		var obj:ScratchObj = app.stagePane.objNamed(String(interp.arg(b, 1)));
		if (!(obj is ScratchObj)) return 0;
		if (obj is ScratchSprite) {
			var s:ScratchSprite = ScratchSprite(obj);
			if ("x position" == attribute) return s.scratchX;
			if ("y position" == attribute) return s.scratchY;
			if ("direction" == attribute) return s.direction;
			if ("costume #" == attribute) return s.costumeNumber();
			if ("size" == attribute) return s.getSize();
			if ("volume" == attribute) return s.volume;
		} if (obj is ScratchStage) {
			if ("scene #" == attribute) return obj.costumeNumber();
			if ("volume" == attribute) return obj.volume;
		}
		if (obj.ownsVar(attribute)) return obj.lookupVar(attribute).value; // variable
		return 0;
	}

	private function mouseOrSpritePosition(arg:String):Point {
		if (arg == "_mouse_") {
			var w:ScratchStage = app.stagePane;
			return new Point(w.scratchMouseX(), w.scratchMouseY());
		} else {
			var s:ScratchSprite = app.stagePane.spriteNamed(arg);
			if (s == null) return null;
			return new Point(s.scratchX, s.scratchY);
		}
		return null;
	}

	private function primGetUserName(b:Block):String {
		return app.isLoggedIn() ? app.userName : 'Anonymous';
	}

	private function primShowWatcher(b:Block):* {
		var varOrListName:String = interp.arg(b, 0);
		var w:DisplayObject = watcherForVar(varOrListName);
		if (w == null) w = watcherForList(varOrListName);
		if (w != null) app.stagePane.show(w);
	}

	private function primHideWatcher(b:Block):* {
		var varOrListName:String = interp.arg(b, 0);
		var w:DisplayObject = watcherForVar(varOrListName);
		if (w == null) w = watcherForList(varOrListName);
		if (w != null) w.visible = false;
	}

	private function watcherForVar(vName:String):DisplayObject {
		var target:ScratchObj = interp.targetObj();
		var v:Variable = target.lookupVar(vName);
		if (v == null) return null; // variable is not defined
		if (v.watcher == null) {
			if (app.stagePane.ownsVar(vName)) target = app.stagePane; // global
			var existing:Watcher = findExistingWatcherFor(target, vName);
			if (existing != null) {
				v.watcher = existing;
			} else {
				v.watcher = new Watcher();
				Watcher(v.watcher).initForVar(target, vName);
			}
		}
		return v.watcher;
	}

	private function watcherForList(listName:String):DisplayObject {
		var w:ListWatcher;
		for each (w in interp.targetObj().lists) {
			if (w.listName == listName) return w;
		}
		for each (w in app.stagePane.lists) {
			if (w.listName == listName) return w;
		}
		return null;
	}

	private function findExistingWatcherFor(target:ScratchObj, vName:String):Watcher {
		for (var i:int = 0; i < app.stagePane.numChildren; i++) {
			var c:* = app.stagePane.getChildAt(i);
			if ((c is Watcher) && (c.isVarWatcherFor(target, vName))) return c;
		}
		return null;
	}

}}
