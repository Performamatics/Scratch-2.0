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
	 * Dispatched when a SoundController enters or exits state.
	 * 
	 * @author Anton Nguyen
	 * @date 20110305
	 */
	public class SoundControllerStateEvent extends Event
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
		public function SoundControllerStateEvent(type:String, state:String)
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
		 * Either the state being entered or exited by the SoundController 
		 * target.
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
			return new SoundControllerStateEvent(type, state);
		}
	}
}