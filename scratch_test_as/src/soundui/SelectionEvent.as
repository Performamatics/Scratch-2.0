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
	 * 
	 * 
	 * @author Anton Nguyen
	 * @date 20110404
	 */
	public class SelectionEvent extends Event
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		public static const BEGIN_SELECTION:String = "beginSelection";
		public static const CLEAR_SELECTION:String = "clearSelection";
		public static const DO_SELECTION:String = "doSelection";
		public static const END_SELECTION:String = "endSelection";
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Instantiates a new event with the state specified.
		 */
		public function SelectionEvent(type:String)
		{
			super(type, false, false);
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
			return new SelectionEvent(type);
		}
	}
}