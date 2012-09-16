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
	 * @date 20110326
	 */
	public class FadeOutFilter extends Filter
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
		public function FadeOutFilter()
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
			var sample:Number;
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
			
			// all subsequent calls are sequential
			bytes.position = offset;
			
			for (var i:int = offset; i < limit; i += 4)
			{
				sample = bytes.readFloat();
				bytes.position -= 4;
				bytes.writeFloat(sample * (1 - (i - offset) / length));
			}
		}
	}
}