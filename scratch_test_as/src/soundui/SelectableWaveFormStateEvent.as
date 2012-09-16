//------------------------------------------------------------------------------
//  
//  Package
//  
//------------------------------------------------------------------------------

package soundui
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
	 * Dispatched when a SelectableWaveForm enters or exits state.
	 * 
	 * @author Anton Nguyen
	 * @date 20110307
	 */
	public class SelectableWaveFormStateEvent extends Event
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
		public function SelectableWaveFormStateEvent(type:String, state:String)
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
		 * Either the state being entered or exited by the SelectableWaveForm 
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
			return new SelectableWaveFormStateEvent(type, state);
		}
	}
}