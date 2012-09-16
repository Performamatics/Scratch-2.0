// SoundsPart.as
// John Maloney, November 2011
//
// This part holds the sounds list for the current sprite (or stage),
// as well as the sound recorder, editor, and import button.

package ui.parts {
	import flash.display.*;
	import flash.utils.*;
	import scratch.*;
	import sound.WAVFile;
	import soundui.*;
	import soundutil.SampledSound;
	import ui.media.*;
	import ui.sound.SoundEdit;
	import uiwidgets.*;

public class SoundsPart extends UIPart {

	public var currentIndex:int;

	private const columnWidth:int = 115;

	private var shape:Shape;
	private var addButton:Button;
	private var listFrame:ScrollFrame;
	private var soundEdit:SoundEdit;

	public function SoundsPart(app:Scratch) {
		this.app = app;
		shape = new Shape();
		addChild(shape);

		addButton = new Button("Add Sound", recordSound);
		addButton.x = (columnWidth - addButton.width) / 2;
		addButton.y = 12;
		addChild(addButton);

		addListFrame();

		soundEdit = new SoundEdit(app);
		soundEdit.x = columnWidth + 13;
		soundEdit.y = 15;
		addChild(soundEdit);
	}

	public function selectSound(snd:ScratchSound):void{
		var obj:ScratchObj = app.viewedObj();
		if (obj == null) return;
		if (obj.sounds.length == 0) return;
		currentIndex = 0;
		for (var i:int = 0; i < obj.sounds.length; i++) {
			if ((obj.sounds[i] as ScratchSound) == snd) currentIndex = i;
		}
		var contents:MediaPane = listFrame.contents as MediaPane;
		contents.updateSelection();
		soundEdit.refresh();
	}

	public function refresh():void {
		var contents:MediaPane = listFrame.contents as MediaPane;
		contents.refresh();
		soundEdit.refresh();
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();

		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(CSS.tabColor);
		g.drawRect(0, 0, w, h);
		g.endFill();

		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(CSS.panelColor);
		g.drawRect(columnWidth + 1, 5, w - columnWidth - 6, h - 10);
		g.endFill();

		fixlayout();
	}

	private function fixlayout():void {
		listFrame.setWidthHeight(columnWidth, h - listFrame.y);
		soundEdit.setWidthHeight(w - columnWidth - 30, h - 30);
	}

	private function addListFrame():void {
		listFrame = new ScrollFrame();
		listFrame.setContents(new MediaPane(app, 'sounds'));
		listFrame.contents.color = CSS.tabColor;
		listFrame.x = 1;
		listFrame.y = 40;
		addChild(listFrame);
	}

	// -----------------------------
	// Sound Recorder
	//------------------------------

	private function recordSound():void {
		function editRecording(recording:SampledSound):void {
			recorder.stop();
			soundEditor = new SoundEditorPane(saveRecording, recording);
			soundEditor.showOnStage(app.stage);
		}
		function saveRecording(recording:SampledSound):void {
			var snd:ScratchSound = new ScratchSound('recording', convertToWAV(recording));
			app.addSound(snd);
		}
		var app:Scratch = Scratch(root);
		var recorder:SoundRecorderPane = new SoundRecorderPane(saveRecording, editRecording);
		var soundEditor:SoundEditorPane;
		recorder.showOnStage(app.stage);
	}

	private function convertToWAV(recording: SampledSound):ByteArray {
		var wavSamples:ByteArray = new ByteArray();
		wavSamples.endian = Endian.LITTLE_ENDIAN;
		var samples:ByteArray = recording.samples;
		samples.position = 0;
		while (samples.bytesAvailable > 4) {
			wavSamples.writeShort(32767 * samples.readFloat()); // convert -1..1 to -32767..32767
		}
		return WAVFile.encode(wavSamples, wavSamples.length / 2, recording.rate, false);
	}

}}
