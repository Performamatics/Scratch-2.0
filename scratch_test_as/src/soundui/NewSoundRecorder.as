// SoundRecorder.as
// John Maloney, November 2011

package soundui {
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.text.*;
	import sound.mp3.*;
	import uiwidgets.*;

public class NewSoundRecorder extends Sprite {

	private const borderColor:int = 0x606060;
	private const bgColor:int = 0xF0F0F0;
	private const cornerRadius:int = 20;

	private var shape:Shape;
	private var levelIndicator:MicrophoneActivityBar;
	private var waveform:WaveformView;
	private var scrollbar:Scrollbar;

	private var microphone:Microphone;

	public function NewSoundRecorder() {
		shape = new Shape();
		addChild(shape);
		addActivityBar();
		waveform = new WaveformView(this, 415, 120);
		waveform.x = 60;
		waveform.y = 20;
		addChild(waveform);
		scrollbar = new Scrollbar(415, 10, waveform.setScroll);
		scrollbar.x = 60;
		scrollbar.y = 185;
		addChild(scrollbar);
		addRecordPlayButtons();
		addCancelEditSaveButtons();
		setWidthHeight(500, 300);
	}

	public function setWidthHeight(w:int, h:int):void {
		var g:Graphics = shape.graphics;
		g.clear();
		g.lineStyle(2, borderColor);
		g.beginFill(bgColor);
		g.drawRoundRect(0, 0, w, h, cornerRadius, cornerRadius);
		g.endFill();
	}

	private function openMicrophone():void {
		if (microphone == null) {
			microphone = Microphone.getMicrophone();
			microphone.setLoopBack(true);
			microphone.soundTransform = new SoundTransform(0, 0);
			levelIndicator.setMicrophone(microphone);
		}
	}

	private function addActivityBar():void {
		levelIndicator = new MicrophoneActivityBar(12, 120);
		levelIndicator.x = 15;
		levelIndicator.y = 20;
		addChild(levelIndicator);
	}

	private function addRecordPlayButtons():void {
		var b:Button = new Button('Record', close);
		b.x = 150;
		b.y = 200;
		addChild(b);
		b = new Button('Condense', setCondensation);
		b.x = 230;
		b.y = 200;
		addChild(b);
		b = new Button('Play', close);
		b.x = 300;
		b.y = 200;
		addChild(b);
		b = new Button('Import', importMP3);
		b.x = 350;
		b.y = 200;
		addChild(b);
	}

	private function addCancelEditSaveButtons():void {
		var b:Button = new Button('Cancel', close);
		b.x = 150;
		b.y = 270;
		addChild(b);
		b = new Button('Edit', close);
		b.x = 230;
		b.y = 270;
		addChild(b);
		b = new Button('Save', close);
		b.x = 300;
		b.y = 270;
		addChild(b);
	}

	private function close():void { parent.removeChild(this) }

	private function importMP3():void {
		function fileSelected(e:Event):void { file.load() }
		function fileLoaded(e:Event):void { MP3Loader.load(file.data, viewSamples) }
		function viewSamples(snd:Sound):void { waveform.setSound(snd) }
		var file:FileReference = new FileReference();
		file.addEventListener(Event.SELECT, fileSelected, false, 0, true);
		file.addEventListener(Event.COMPLETE, fileLoaded);
		file.browse([new FileFilter("MP3 files (*.mp3)", "*.mp3")]);
	}

	private function setCondensation():void {
		function done(s:String):void { if (s.length > 0) waveform.setCondensation(int(s)) }
		DialogBox.ask('Samples per condensed sample?', '100', root.stage, done);
	}

}}
