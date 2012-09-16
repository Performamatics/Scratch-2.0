package ui.media {
	import flash.display.Sprite;
	import scratch.*;
	import uiwidgets.ScrollFrameContents;
	import ui.parts.SoundsPart;

public class MediaPane extends ScrollFrameContents {

	public var app:Scratch;

	private var isSound:Boolean;

	public function MediaPane(app:Scratch, type:String):void {
		this.app = app;
		isSound = (type == 'sounds');
		refresh();
	}

	public function refresh():void {
		if (app.viewedObj() == null) return;
		replaceContents(isSound ? soundItems() : costumeItems());
		updateSelection();
	}

	public function updateSelection():void {
		if (isSound) updateSoundSelection() else updateCostumeSelection();
	}

	private function replaceContents(newItems:Array):void {
		while (numChildren > 0) removeChildAt(0);
		var offset:int = 10;
		for each (var item:Sprite in newItems) {
			item.x = 10;
			item.y = offset;
			offset += item.height + 15;
			addChild(item);
		}
		updateSize();
		x = y = 0; // reset scroll offset
	}

	private function costumeItems():Array {
		var result:Array = [];
		var viewedObj:ScratchObj = app.viewedObj();
		for each (var c:ScratchCostume in viewedObj.costumes) {
			result.push(new MediaInfo(viewedObj, c));
		}
		return result;
	}

	private function soundItems():Array {
		var result:Array = [];
		var viewedObj:ScratchObj = app.viewedObj();
		for each (var snd:ScratchSound in viewedObj.sounds) {
			result.push(new MediaInfo(viewedObj, snd));
		}
		return result;
	}

	private function updateCostumeSelection():void {
		var viewedObj:ScratchObj = app.viewedObj();
		if ((viewedObj == null) || isSound) return;
		var current:ScratchCostume = viewedObj.currentCostume();
		for (var i:int = 0 ; i < numChildren ; i++) {
			var ci:MediaInfo = getChildAt(i) as MediaInfo;
			if (ci != null) {
				if (ci.mycostume == current) ci.highlight();
				else ci.unhighlight();
			}
		}
	}

	private function updateSoundSelection():void {
		var viewedObj:ScratchObj = app.viewedObj();
		if ((viewedObj == null) || !isSound) return;
		if (viewedObj.sounds.length < 1) return;
		var sp:SoundsPart = this.parent.parent as SoundsPart;
		if (sp == null) return;
	 	sp.currentIndex = Math.min(sp.currentIndex, viewedObj.sounds.length - 1);
		var current:ScratchSound = viewedObj.sounds[sp.currentIndex] as ScratchSound;
		for (var i:int = 0 ; i < numChildren ; i++) {
			var si:MediaInfo = getChildAt(i) as MediaInfo;
			if (si != null) {
				if (si.mysound == current) si.highlight();
				else si.unhighlight();
			}
		}
	}

}}
