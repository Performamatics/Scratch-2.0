// MD5.as
// Extensively modified by John Maloney, December 2010
// Based on code from Adobe (see copyright notice below), but optimized (4x to 5x speedup!).
//
// Implements MD5 Message-Digest for strings and ByteArrays.
// References:
//	http://www.faqs.org/rfcs/rfc1321.html
//  http://en.wikipedia.org/wiki/Md5

/*
Copyright (c) 2008, Adobe Systems Incorporated
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Adobe Systems Incorporated nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package util {
	import flash.utils.ByteArray;

public class MD5 {

	public static function hashString(s:String):String {
		var ba:ByteArray = new ByteArray();
		ba.writeUTFBytes(s);
		return hashBinary(ba);
	}

	public static function hashBinary(data:ByteArray):String {
		var a:int = 1732584193;
		var b:int = -271733879;
		var c:int = -1732584194;
		var d:int = 271733878;

		var aa:int, bb:int, cc:int, dd:int;

		var x:Array = createBlocks(data);
		var len:int = x.length;

		for (var i:int = 0; i < len; i += 16) {
			// record previous values
			aa = a;
			bb = b;
			cc = c;
			dd = d;

			// Round 1
			a = ff(a, b, c, d, x[int(i +  0)],  7, -680876936); 	// 1
			d = ff(d, a, b, c, x[int(i +  1)], 12, -389564586);		// 2
			c = ff(c, d, a, b, x[int(i +  2)], 17, 606105819); 		// 3
			b = ff(b, c, d, a, x[int(i +  3)], 22, -1044525330);	// 4
			a = ff(a, b, c, d, x[int(i +  4)],  7, -176418897); 	// 5
			d = ff(d, a, b, c, x[int(i +  5)], 12, 1200080426); 	// 6
			c = ff(c, d, a, b, x[int(i +  6)], 17, -1473231341);	// 7
			b = ff(b, c, d, a, x[int(i +  7)], 22, -45705983); 		// 8
			a = ff(a, b, c, d, x[int(i +  8)],  7, 1770035416); 	// 9
			d = ff(d, a, b, c, x[int(i +  9)], 12, -1958414417);	// 10
			c = ff(c, d, a, b, x[int(i + 10)], 17, -42063); 		// 11
			b = ff(b, c, d, a, x[int(i + 11)], 22, -1990404162);	// 12
			a = ff(a, b, c, d, x[int(i + 12)],  7, 1804603682); 	// 13
			d = ff(d, a, b, c, x[int(i + 13)], 12, -40341101); 		// 14
			c = ff(c, d, a, b, x[int(i + 14)], 17, -1502002290);	// 15
			b = ff(b, c, d, a, x[int(i + 15)], 22, 1236535329); 	// 16

			// Round 2
			a = gg(a, b, c, d, x[int(i +  1)],  5, -165796510); 	// 17
			d = gg(d, a, b, c, x[int(i +  6)],  9, -1069501632);	// 18
			c = gg(c, d, a, b, x[int(i + 11)], 14, 643717713); 		// 19
			b = gg(b, c, d, a, x[int(i +  0)], 20, -373897302); 	// 20
			a = gg(a, b, c, d, x[int(i +  5)],  5, -701558691); 	// 21
			d = gg(d, a, b, c, x[int(i + 10)],  9, 38016083); 		// 22
			c = gg(c, d, a, b, x[int(i + 15)], 14, -660478335); 	// 23
			b = gg(b, c, d, a, x[int(i +  4)], 20, -405537848); 	// 24
			a = gg(a, b, c, d, x[int(i +  9)],  5, 568446438); 		// 25
			d = gg(d, a, b, c, x[int(i + 14)],  9, -1019803690);	// 26
			c = gg(c, d, a, b, x[int(i +  3)], 14, -187363961); 	// 27
			b = gg(b, c, d, a, x[int(i +  8)], 20, 1163531501); 	// 28
			a = gg(a, b, c, d, x[int(i + 13)],  5, -1444681467);	// 29
			d = gg(d, a, b, c, x[int(i +  2)],  9, -51403784); 		// 30
			c = gg(c, d, a, b, x[int(i +  7)], 14, 1735328473); 	// 31
			b = gg(b, c, d, a, x[int(i + 12)], 20, -1926607734);	// 32

			// Round 3
			a = hh(a, b, c, d, x[int(i +  5)],  4, -378558); 		// 33
			d = hh(d, a, b, c, x[int(i +  8)], 11, -2022574463);	// 34
			c = hh(c, d, a, b, x[int(i + 11)], 16, 1839030562); 	// 35
			b = hh(b, c, d, a, x[int(i + 14)], 23, -35309556); 		// 36
			a = hh(a, b, c, d, x[int(i +  1)],  4, -1530992060);	// 37
			d = hh(d, a, b, c, x[int(i +  4)], 11, 1272893353); 	// 38
			c = hh(c, d, a, b, x[int(i +  7)], 16, -155497632); 	// 39
			b = hh(b, c, d, a, x[int(i + 10)], 23, -1094730640);	// 40
			a = hh(a, b, c, d, x[int(i + 13)],  4, 681279174); 		// 41
			d = hh(d, a, b, c, x[int(i +  0)], 11, -358537222); 	// 42
			c = hh(c, d, a, b, x[int(i +  3)], 16, -722521979); 	// 43
			b = hh(b, c, d, a, x[int(i +  6)], 23, 76029189); 		// 44
			a = hh(a, b, c, d, x[int(i +  9)],  4, -640364487); 	// 45
			d = hh(d, a, b, c, x[int(i + 12)], 11, -421815835); 	// 46
			c = hh(c, d, a, b, x[int(i + 15)], 16, 530742520); 		// 47
			b = hh(b, c, d, a, x[int(i +  2)], 23, -995338651); 	// 48

			// Round 4
			a = ii(a, b, c, d, x[int(i +  0)],  6, -198630844); 	// 49
			d = ii(d, a, b, c, x[int(i +  7)], 10, 1126891415); 	// 50
			c = ii(c, d, a, b, x[int(i + 14)], 15, -1416354905);	// 51
			b = ii(b, c, d, a, x[int(i +  5)], 21, -57434055); 		// 52
			a = ii(a, b, c, d, x[int(i + 12)],  6, 1700485571); 	// 53
			d = ii(d, a, b, c, x[int(i +  3)], 10, -1894986606);	// 54
			c = ii(c, d, a, b, x[int(i + 10)], 15, -1051523); 		// 55
			b = ii(b, c, d, a, x[int(i +  1)], 21, -2054922799);	// 56
			a = ii(a, b, c, d, x[int(i +  8)],  6, 1873313359); 	// 57
			d = ii(d, a, b, c, x[int(i + 15)], 10, -30611744); 		// 58
			c = ii(c, d, a, b, x[int(i +  6)], 15, -1560198380);	// 59
			b = ii(b, c, d, a, x[int(i + 13)], 21, 1309151649); 	// 60
			a = ii(a, b, c, d, x[int(i +  4)],  6, -145523070); 	// 61
			d = ii(d, a, b, c, x[int(i + 11)], 10, -1120210379);	// 62
			c = ii(c, d, a, b, x[int(i +  2)], 15, 718787259); 		// 63
			b = ii(b, c, d, a, x[int(i +  9)], 21, -343485551); 	// 64

			a += aa;
			b += bb;
			c += cc;
			d += dd;
		}
		return toHex(a) + toHex(b) + toHex(c) + toHex(d);
	}

	private static function ff(a:int, b:int, c:int, d:int, x:int, s:int, t:int):int {
		var tmp:int = a + ((b & c) | ((~b) & d)) + x + t;
		return ((tmp << s) | (tmp >>> (32 - s))) + b;
	}

	private static function gg(a:int, b:int, c:int, d:int, x:int, s:int, t:int):int {
		var tmp:int = a + ((b & d) | (c & (~d))) + x + t;
		return ((tmp << s) | (tmp >>> (32 - s))) + b;
	}

	private static function hh(a:int, b:int, c:int, d:int, x:int, s:int, t:int):int {
		var tmp:int = a + (b ^ c ^ d) + x + t;
		return ((tmp << s) | (tmp >>> (32 - s))) + b;
	}

	private static function ii(a:int, b:int, c:int, d:int, x:int, s:int, t:int):int {
		var tmp:int = a + (c ^ (b | (~d))) + x + t;
		return ((tmp << s) | (tmp >>> (32 - s))) + b;
	}

	private static function createBlocks(data:ByteArray):Array {
		// Convert data to an array of 16-word blocks. Append a "1" bit and add padding and length to last block.
		var result:Array = new Array(), i:int;
		var len:int = int(data.length / 4) * 4;
		for (i = 0; i < len; i += 4) {
			result.push((data[i+3] << 24) | (data[i+2] << 16) | (data[i+1] << 8) | data[i]);
		}
		var lastWord:int = 0, shift:int = 0;
		for (i = len; i < data.length; i++) { // handle extra bytes if data size was not multiple of 4
			lastWord += data[i] << shift;
			shift += 8;
		}
		lastWord += 128 << shift;  // append "1" bit to data
		result.push(lastWord);

		while ((result.length % 16) != 14) result.push(0); // add padding
		len = 8 * data.length; // 64-bit length in bits
		result.push(len & 0xFFFFFFFF); // length, low word
		// Note: Use two shifts to get high word because shifting by 32 is a noop:
		result.push(((len >>> 30) >>> 2) & 0xFFFFFFFF); // length, high word
		return result;
	}

	private static function toHex(n:int):String {
		var hexDigits:String = "0123456789abcdef";
		var hex:String = "";
		for (var x:int = 0; x < 4; x++) {
			var byte:int = (n >> (x * 8)) & 0xFF;
			hex += hexDigits.charAt(byte >> 4) + hexDigits.charAt(byte & 0xF);
		}
		return hex;
	}

}}
