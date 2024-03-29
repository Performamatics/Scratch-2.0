// SqueakSoundDecoder.as
// John Maloney, November 2010
//
// Decode a Flash/Squeak ADPCM compressed sounds with 2, 3, 4, or 5 bits pers sample.

package sound {
	import flash.utils.*;

public class SqueakSoundDecoder {

	static private var stepSizeTable:Array = [
		7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
		50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173, 190, 209, 230,
		253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724, 796, 876, 963,
		1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327,
		3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487,
		12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767];

	// bit stream state
	private var bitsPerSample:int;
	private var currentByte:int;
	private var bitPosition:int;

	// decoder state
	private var indexTable:Array;
	private var signMask:int;
	private var valueMask:int;
	private var valueHighBit:int;

	public function SqueakSoundDecoder(bitsPerSample:int) {
		this.bitsPerSample = bitsPerSample;
		switch(bitsPerSample) {
		case 2:
			indexTable = [-1, 2, -1, 2];
			break;
		case 3:
			indexTable = [-1, -1, 2, 4, -1, -1, 2, 4];
			break;
		case 4:
			indexTable = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8];
			break;
		case 5:
			indexTable = [
				-1, -1, -1, -1, -1, -1, -1, -1, 1, 2, 4, 6, 8, 10, 13, 16,
				-1, -1, -1, -1, -1, -1, -1, -1, 1, 2, 4, 6, 8, 10, 13, 16];
			break;
		}
		signMask = 1 << (bitsPerSample - 1);
		valueMask = signMask - 1;
		valueHighBit = signMask >> 1;
	}

	public function decode(soundData:ByteArray):ByteArray {
		var result:ByteArray = new ByteArray();
		result.endian = Endian.LITTLE_ENDIAN;
		var sample:int = 0;
		var index:int = 0;
		soundData.position = 0;
		while (true) {
			var code:int = nextCode(soundData);
			if (code < 0) break;  // no more input
			var step:int = stepSizeTable[index];
			var delta:int = 0;
			for (var bit:int = valueHighBit; bit > 0; bit = bit >> 1) {
				if ((code & bit) != 0) delta += step;
				step = step >> 1;
			}
			delta += step;
			sample += ((code & signMask) != 0) ? -delta : delta;
	
			index += indexTable[code];
			if (index < 0) index = 0;
			if (index > 88) index = 88;
	
			if (sample > 32767) sample = 32767;
			if (sample < -32768) sample = -32768;
			result.writeShort(sample);
		}
		result.position = 0;
		return result;
	}

	private function nextCode(soundData:ByteArray):int {
		var result:int = 0;
		var remaining:int = bitsPerSample;
		while (true) {
			var shift:int = remaining - bitPosition;
			result += (shift < 0) ? (currentByte >> -shift) : (currentByte << shift);
			if (shift > 0) {  // consumed all bits of currentByte; fetch next byte
				remaining -= bitPosition;
				if (soundData.bytesAvailable > 0) {
					currentByte = soundData.readUnsignedByte();
					bitPosition = 8;
				} else {  // no more input
					currentByte = 0;
					bitPosition = 0;
					return -1;	// -1 indicates no more input
				}
			} else {  // still some bits left in currentByte
				bitPosition -= remaining;
				currentByte = currentByte & (0xFF >> (8 - bitPosition));
				break;
			}
		}
		return result;
	}

}}
