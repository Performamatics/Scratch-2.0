//------------------------------------------------------------------------------
//  
//  Package
//  
//------------------------------------------------------------------------------

package soundutil.filters
{
	
	//--------------------------------------------------------------------------
	//  
	//  Imports
	//  
	//--------------------------------------------------------------------------
	
	import flash.utils.ByteArray;
	
	import soundutil.filters.Filter;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * A filter that reverses the sound data. 
	 * 
	 * @author Anton Nguyen
	 * @date 20110314
	 */
	public class ReverseFilter extends Filter
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Makes a reverse filter.
		 */
		public function ReverseFilter()
		{
			// whatever
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Applies the filter to the given byte array at the offset and length. 
		 * If length == 0, then it applies it to the entire byte array.
		 */
		override public function apply(bytes:ByteArray, offset:uint = 0, length:uint = 0):void
		{
			var topSample:Number;
			var bottomSample:Number;
			var halfway:int;
			var limit:int;
			
			if (length == 0)
			{
				limit = bytes.length;
				length = bytes.length - offset;
			}
			else
			{
				limit = length + offset;
			}
			
			halfway = int(length / 2 + offset);
			halfway -= halfway % 4;
			
			for (var i:int = offset, j:int = 1; i < halfway; i += 4, j++)
			{
				bytes.position = i;
				topSample = bytes.readFloat();
				
				bytes.position = limit - 4 * j;
				bottomSample = bytes.readFloat();
				bytes.position -= 4;
				bytes.writeFloat(topSample);
				
				bytes.position = i;
				bytes.writeFloat(bottomSample);
			}
		}
	}
}