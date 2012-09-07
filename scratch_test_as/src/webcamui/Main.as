package webcamui
{
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	
	public class Main extends Sprite
	{
		private var _webcam:WebCamPane;
		
		public function Main()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			_webcam = new WebCamPane();
			_webcam.showOnStage(stage);
		}
	}
}