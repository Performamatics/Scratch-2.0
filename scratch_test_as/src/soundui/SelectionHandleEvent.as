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
	public class SelectionHandleEvent extends Event
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		public static const BEGIN_DRAG:String = "beginDrag";
		public static const DO_DRAG:String = "doDrag";
		public static const END_DRAG:String = "endDrag";
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Instantiates a new event with the state specified.
		 */
		public function SelectionHandleEvent(type:String)
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
			return new SelectionHandleEvent(type);
		}
	}
}