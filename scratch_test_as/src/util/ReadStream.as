// ReadStream.as
// John Maloney, October 2009
//
// A simple character stream with two character look-ahead and tokenization.

package util {
public class ReadStream {

	private var src:String, i:int;

	public function ReadStream(s:String) {
		src = s;
		i = 0;
	}

	public function atEnd():Boolean {
		return i >= src.length;
	}

	public function next():String {
		if (i >= src.length) return "";
		return src.charAt(i++);
	}

	public function peek():String {
		return (i < src.length) ? src.charAt(i) : "";
	}

	public function peek2():String {
		return ((i + 1) < src.length) ? src.charAt(i + 1) : "";
	}

	public function peekString(n:int):String { return src.slice(i, i + n) }

	public function nextString(n:int):String {
		i += n;
		return src.slice(i - n, i);
	}

	public function pos():int { return i }

	public function setPos(newPos:int):void { i = newPos }

	public function skip(count:int):void { i += count }

	public function skipWhiteSpace():void {
		while ((i < src.length) && (src.charCodeAt(i) <= 32)) i++;
	}

	public function upToEnd():String {
		var result:String = (i < src.length) ? src.slice(i, src.length) : "";
		i = src.length;
		return result;
	}

	public static function tokenize(s:String):Array {
		var stream:ReadStream = new ReadStream(s);
		var result:Array = [];
		while (!stream.atEnd()) {
			var token:String = stream.nextToken();
			if (token.length > 0) result.push(token);
		}
		return result;
	}

	public function nextToken():String {
		skipWhiteSpace();
		if (atEnd()) return "";
		var percentSeen:Boolean;
		var start:int = i;
		while (i < src.length) {
			if (src.charCodeAt(i) <= 32) break;
			if (src.charAt(i) == "%") {
				if (i > start) break; // percent sign starts new token
				percentSeen = true;
			}
			// special case for "touching %m?" ("?" starts new token) vs. loud?" (doesn't)
			if ((src.charAt(i) == "?") && percentSeen && (i > start)) break;
			i++;
		}
		return src.slice(start, i);
	}

}}
