package webcamui
{
	import flash.events.Event;
	
	public class SliderEvent extends Event 
	{
		public static const UPDATE:String = "update";
		
		public function SliderEvent(type:String)
		{
			super(type);
		}
	}
}