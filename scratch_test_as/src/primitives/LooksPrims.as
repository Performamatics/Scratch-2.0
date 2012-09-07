// LooksPrims.as
// John Maloney, April 2010
//
// Looks primitives.

package primitives {
	import flash.utils.Dictionary;
	import blocks.*;
	import interpreter.*;
	import scratch.*;

public class LooksPrims {

	private var app:Scratch;
	private var interp:Interpreter;

	public function LooksPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Dictionary):void {
		primTable["lookLike:"]				= primShowCostume;
		primTable["nextCostume"]			= primNextCostume;
		primTable["costumeIndex"]			= primCostumeNum;

		primTable["showBackground:"]		= primShowCostume; // used by Scratch 1.4 and earlier
		primTable["nextBackground"]			= primNextCostume; // used by Scratch 1.4 and earlier
		primTable["backgroundIndex"]		= primCostumeNum;
		primTable["startScene"]				= primStartScene;
		primTable["nextScene"]				= primNextScene;

		primTable["say:duration:elapsed:from:"]		= function(b:*):* { showBubbleAndWait(b, "talk") };
		primTable["say:"]							= function(b:*):* { showBubble(b, "talk") };
		primTable["think:duration:elapsed:from:"]	= function(b:*):* { showBubbleAndWait(b, "think") };
		primTable["think:"]							= function(b:*):* { showBubble(b, "think") };
		primTable["showBubble"]						= function(b:*):* { showBubble(b) };
		primTable["showBubbleAndWait"]				= function(b:*):* { showBubbleAndWait(b) };

		primTable["changeGraphicEffect:by:"] = primChangeEffect;
		primTable["setGraphicEffect:to:"]	= primSetEffect;
		primTable["filterReset"]			= primClearEffects;

		primTable["changeSizeBy:"]			= primChangeSize;
		primTable["setSizeTo:"]				= primSetSize;
		primTable["scale"]					= primSize;

		primTable["show"]					= primShow;
		primTable["hide"]					= primHide;

		primTable["comeToFront"]			= primGoFront;
		primTable["goBackByLayers:"]		= primGoBack;
	}

	private function primNextCostume(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		if (s != null) s.showCostume(s.currentCostumeIndex + 1);
		if (s.visible) interp.redraw();
	}

	private function primShowCostume(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		if (s == null) return;
		var arg:* = interp.arg(b, 0);
		if (typeof(arg) == 'number') {
			s.showCostume(arg - 1);
		} else {
			if ((arg == 'CAMERA') || (arg == "CAMERA - MIRROR")) {
				s.showCostumeNamed(arg);
				return;
			}
			var i:int = s.indexOfCostumeNamed(arg);
			if (i >= 0) {
				s.showCostume(i);
			} else {
				var n:Number = Number(arg);
				if (!isNaN(n)) s.showCostume(n - 1);
				else return;  // arg did not match a costume name nor is a valid number
			}
		}
		if (s.visible) interp.redraw();
	}

	private function primCostumeNum(b:Block):Number {
		var s:ScratchObj = interp.targetObj();
		return (s == null) ? 1 : s.costumeNumber();
	}

	private function primStartScene(b:Block):void {
		var sceneName:String = interp.arg(b, 0);
		app.stagePane.recordHiddenSprites();
		app.stagePane.showCostumeNamed(sceneName);
		app.stagePane.updateSpriteVisibility();
		app.runtime.startSceneEnteredHats(sceneName);
		interp.redraw();
	}

	private function primNextScene(b:Block):void {
		var stg:ScratchStage = app.stagePane;
		app.stagePane.recordHiddenSprites();
		stg.showCostume(stg.currentCostumeIndex + 1);
		app.stagePane.updateSpriteVisibility();
		app.runtime.startSceneEnteredHats(stg.currentCostume().costumeName);
		interp.redraw();
	}

	private function showBubbleAndWait(b:Block, type:String = null):void {
		var text:String, secs:Number;
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return;
		if (interp.activeThread.firstTime) {
			if (type == null) { // combined talk/think/shout/whisper command
				type = interp.arg(b, 0);
				text = interp.arg(b, 1);
				secs = interp.numarg(b, 2);
			} else { // talk or think command
				text = interp.arg(b, 0);
				secs = interp.numarg(b, 1);
			}
			s.showBubble(text, type);
			if (s.visible) interp.redraw();
			interp.startTimer(secs);
		} else {
			if (interp.checkTimer()) s.hideBubble();
		}
	}

	private function showBubble(b:Block, type:String = null):void {
		var text:String, secs:Number;
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return;
		if (type == null) { // combined talk/think/shout/whisper command
			type = interp.arg(b, 0);
			text = interp.arg(b, 1);
		} else { // talk or think command
			text = interp.arg(b, 0);
		}
		s.showBubble(text, type);
		if (s.visible) interp.redraw();
	}

	private function primChangeEffect(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		if (s == null) return;
		var filterName:String = interp.arg(b, 0);
		var newValue:Number = s.filterPack.getFilterSetting(filterName) + interp.numarg(b, 1);
		s.filterPack.setFilter(filterName, newValue);
		s.applyFilters();
		if (s.visible) interp.redraw();
	}

	private function primSetEffect(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		if (s == null) return;
		var filterName:String = interp.arg(b, 0);
		var newValue:Number = interp.numarg(b, 1);
		s.filterPack.setFilter(filterName, newValue);
		s.applyFilters();
		if (s.visible) interp.redraw();
	}

	private function primClearEffects(b:Block):void {
		var s:ScratchObj = interp.targetObj();
		s.clearFilters();
		if (s.visible) interp.redraw();
	}

	private function primChangeSize(b:Block):void {
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return;
		var oldSize:Number = 100 * s.scaleX;
		s.setSize(s.getSize() + interp.numarg(b, 0));
		if (s.visible) interp.redraw();
	}

	private function primSetSize(b:Block):void {
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return;
		s.setSize(interp.numarg(b, 0));
		if (s.visible) interp.redraw();
	}

	private function primSize(b:Block):Number {
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return 100;
		return s.getSize();
	}

	private function primShow(b:Block):void {
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return;
		s.visible = true;
		s.updateBubble();
		if (s.visible) interp.redraw();
	}

	private function primHide(b:Block):void {
		var s:ScratchSprite = interp.targetSprite();
		if (s == null) return;
		s.visible = false;
		s.updateBubble();
		if (s.visible) interp.redraw();
	}

	private function primGoFront(b:Block):void {
		var s:ScratchSprite = interp.targetSprite();
		if ((s == null) || (s.parent == null)) return;
		s.parent.setChildIndex(s, s.parent.numChildren - 1);
		if (s.visible) interp.redraw();
	}

	private function primGoBack(b:Block):void {
		var s:ScratchSprite = interp.targetSprite();
		if ((s == null) || (s.parent == null)) return;
		var newIndex:int = s.parent.getChildIndex(s) - interp.numarg(b, 0);
		newIndex = Math.max(4, Math.min(newIndex, s.parent.numChildren - 1));
		s.parent.setChildIndex(s, newIndex);
		if (s.visible) interp.redraw();
	}

}}
