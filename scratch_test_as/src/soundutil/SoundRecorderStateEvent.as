//------------------------------------------------------------------------------
//  
//  Package
//  
//------------------------------------------------------------------------------

package soundutil
{
	
	//--------------------------------------------------------------------------
	//  
	//  Imports
	//  
	//--------------------------------------------------------------------------
	
	import flash.events.Event;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * Dispatched when a SoundRecorder enters or exits state.
	 * 
	 * @author Anton Nguyen
	 * @date 20110223
	 */
	public class SoundRecorderStateEvent extends Event
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		public static const ENTER:String = "enter";
		public static const EXIT:String = "exit";
		
		private var _state:String;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Instantiates a new event with the state specified.
		 */
		public function SoundRecorderStateEvent(type:String, state:String)
		{
			super(type, false, false);
			
			_state = state;
		}
		
		//----------------------------------------------------------------------
		//  
		//  Properties
		//  
		//----------------------------------------------------------------------
		
		//------------------------------
		//  state
		//------------------------------
		
		/**
		 * Either the state being entered or exited by the SoundRecorder target.
		 */
		public function get state():String
		{
			return _state;
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		/**
		 * @private
		 */
		override public function clone():Event
		{
			return new SoundRecorderStateEvent(type, state);
		}
	}
}