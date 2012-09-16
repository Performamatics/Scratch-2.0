package soundui
{
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	
	import soundutil.SampledSound;
	
	import uiwidgets.DialogBox;
	
	public class Main extends Sprite
	{
		private var _soundEditorPane:SoundEditorPane;
		private var _soundRecorderPane:SoundRecorderPane;
		
		public function Main()
		{
			_soundRecorderPane = new SoundRecorderPane(saveRecording, editRecording);
			_soundRecorderPane.showOnStage(stage);
			stage.scaleMode = StageScaleMode.NO_SCALE;
		}
		
		private function saveEdit(recording:SampledSound):void
		{
			// do nothing, or return to main Scratch view
			trace("edited recording saved");
		}
		
		private function editRecording(recording:SampledSound):void
		{
			// open sound editor
			
			_soundEditorPane = new SoundEditorPane(saveEdit, recording);
			_soundEditorPane.showOnStage(stage, false);
		}
		
		private function saveRecording(recording:SampledSound):void
		{
			// do nothing, or return to main Scratch view
			trace("recording saved");
		}
	}
}