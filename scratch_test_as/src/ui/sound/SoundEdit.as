package ui.sound {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.utils.*;
	import assets.Resources;
	import scratch.*;
	import ui.parts.SoundsPart;
	import ui.media.MediaLibrary;
	import uiwidgets.*;

public class SoundEdit extends Sprite {

	private var app:Scratch;

	private var nameField:EditableLabel;
	private var importFromLibrary:IconButton;

	// Sound tool
	private var soundFrame:Sprite;
	private var recordedWave:Sprite;

	private var playSound:IconButton;
	private var recordSound:IconButton;
	private var pauseSound:IconButton;
	private var stopSound:IconButton;
	private var rewindSound:IconButton;
	private var forwardSound:IconButton;

	public function SoundEdit(app:Scratch) {
		this.app = app;

		nameField = new EditableLabel(nameChanged);
		addChild(nameField);
		importFromLibrary = new IconButton(openImportSound, makeButtonImg('library', true), makeButtonImg('library', false));
		importFromLibrary.isMomentary = true;
		addChild(importFromLibrary);

		addChild(soundFrame = new Sprite());
		addChild(recordedWave = new Sprite());
		
		var list:Array = [];
		function placeholder():void {}
		list.push(recordSound = new IconButton(placeholder, "recordSnd", null, true));
		list.push(playSound = new IconButton(placeholder, "playSnd", null, true));
		list.push(rewindSound = new IconButton(placeholder, "rewindSnd", null, true));
		list.push(forwardSound = new IconButton(placeholder, "forwardSnd", null, true));
		list.push(stopSound = new IconButton(placeholder, "stopSnd", null, true));
		list.push(pauseSound = new IconButton(placeholder, "pauseSnd", null, true));
		for (var i:int = 0; i < list.length; i++) {
			var ib:IconButton= list [i];
			ib.x = 28 + i * 46;
			ib.y = 122;
			soundFrame.addChild(ib);
		}	
	}

	public function setWidthHeight(w:int, h:int):void {
		nameField.y = 2;
		soundFrame.x = 0;
		soundFrame.y = 60;
		recordedWave.x = soundFrame.x + 20;
		recordedWave.y = 	soundFrame.y + 20;
		recordBox(recordedWave.graphics, 280, 86);
		drawBox(soundFrame.graphics, 320, 172);
		nameField.setWidth(w - 82);
		importFromLibrary.x = w - 32;
	}

	public function refresh():void {
		var viewedObj:ScratchObj = app.viewedObj();
		if (viewedObj.sounds.length < 1) return;
		(parent as SoundsPart).currentIndex = Math.min((parent as SoundsPart).currentIndex, viewedObj.sounds.length - 1);
		var current:ScratchSound = viewedObj.sounds[(parent as SoundsPart).currentIndex] as ScratchSound;
		nameField.setContents(current.soundName)
	}

	private function openImportSound(b:IconButton):void {
		new MediaLibrary(app, "sounds", app.addSound).open();
	}

	private function nameChanged(evt:Event):void {
		(parent as SoundsPart).currentIndex = Math.min((parent as SoundsPart).currentIndex, app.viewedObj().sounds.length - 1);
		var current:ScratchSound = app.viewedObj().sounds[(parent as SoundsPart).currentIndex] as ScratchSound;
		current.soundName = nameField.contents();
		(parent as SoundsPart).refresh();
	}

	private function makeButtonImg(str:String, isOn:Boolean):Sprite {
		var img:Sprite = new Sprite();
		var g:Graphics = img.graphics;
		g.clear();
		g.lineStyle(0.5, CSS.borderColor, 1, true);
		var m:Matrix = new Matrix();
 		m.createGradientBox(32, 32, Math.PI / 2, 0, 0);
 		g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], m);
		g.drawRoundRect(0, 0, 32, 32, 12);
 		g.endFill();
 		if (isOn) img.addChild(Resources.createBmp(str + "On"));
 		else img.addChild(Resources.createBmp(str + "Off"));
		return img;
	}

	private function drawBox(g:Graphics, w:int, h:int):void {
		g.clear();
		var m:Matrix = new Matrix();
 		m.createGradientBox(w, h, Math.PI / 2, 0, 0);
 		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], m);
 		g.drawRoundRect(0,0, w,h, 12,12);
		g.endFill();
	}

	private function recordBox(g:Graphics, w:int, h:int):void {
		g.beginFill(CSS.white)
 		g.lineStyle(0.5,CSS.borderColor,1,true);
 		g.drawRoundRect(0,0, w,h, 18,18);
		g.endFill();
	}

}}
