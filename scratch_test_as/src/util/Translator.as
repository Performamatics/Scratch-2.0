package util {
	import flash.utils.*;
	
public class Translator {

	// Temporary for testing...
//	[Embed(source="nl.po", mimeType="application/octet-stream")] static private const NL: Class;
//	[Embed(source="th.po", mimeType="application/octet-stream")] static private const TH: Class;

	static public function setLanguage(langCode:String):void {
		dictionary = new Object();
//		if (langCode == "nl") install(new NL());
//		if (langCode == "th") install(new TH());
	}

	static private function lengthOfDict(o:Object):uint {
		var result:uint;
		for (var k:String in o) result++;
		return result;
	}
	// end testing

	static public var dictionary:Object = new Object();

	static public function map(s:String):String {
		var result:* = dictionary[s];
		return (result == undefined) ? s : result;
	}

	static public function xxxMap(s:String):String {
		var result:String = "";
		for (var i:int = 0; i < s.length; i++) {
			var ch:int = s.charCodeAt(i);
			if ((97 <= ch) && (ch <= 122)) {
				ch = ch - 32;
			}
			result += String.fromCharCode(ch);
		}
		return result;
	}

	static public function install(poData:ByteArray):void {
		if (poData == null) {
			dictionary = new Object();
			return;
		}
		dictionary = new Translator().parsePOData(poData);
	}

	private function parsePOData(bytes:ByteArray):Object {
		// Parse the given data in gettext .po file format.
		skipBOM(bytes);
		var lines:Array = [];
		while (bytes.bytesAvailable > 0) {
			var s:String = trimWhitespace(nextLine(bytes));
			if ((s.length > 0) && (s.charAt(0) != "#")) lines.push(s);
		}
		return makeDictionary(lines);
	}

	private function skipBOM(bytes:ByteArray):void {
		// Some .po files begin with a three-byte UTF-8 Byte Order Mark (BOM).
		// Skip this BOM if it exists, otherwise do nothing.
		if (bytes.bytesAvailable < 3) return;
		var b1:int = bytes.readUnsignedByte();
		var b2:int = bytes.readUnsignedByte();
		var b3:int = bytes.readUnsignedByte();
		if ((b1 == 0xEF) && (b2 == 0xBB) && (b3 == 0xBF)) return; // found BOM
		bytes.position = bytes.position - 3; // BOM not found; back up
	}

	private function trimWhitespace(s:String):String {
		// Remove leading and trailing whitespace characters.
		if (s.length == 0) return "";
		var i:int = 0;
		while ((i < s.length) && (s.charCodeAt(i) <= 32)) i++;
		if (i == s.length) return "";
		var j:int = s.length - 1;
		while ((j > i) && (s.charCodeAt(j) <= 32)) j--;
		return s.slice(i, j + 1);
	}

	private function nextLine(bytes:ByteArray):String {
		// Read the next line from the given ByteArray. A line ends with CR, LF, or CR-LF.
		var buf:ByteArray = new ByteArray();
		while (bytes.bytesAvailable > 0) {
			var byte:int = bytes.readUnsignedByte();
			if (byte == 13) { // CR
				// line could end in CR or CR-LF
				if (bytes.readUnsignedByte() != 10) bytes.position--; // try to read LF, but backup if not LF
				break;
			} else if (byte == 10) { // LF
				break;
			} else {
				buf.writeByte(byte);
			}
		}
		buf.position = 0;
		return buf.readUTFBytes(buf.length);
	}

	private function makeDictionary(lines:Array):Object {
		// Build a dictionary object mapping English to translated strings.
		var dict:Object = new Object();
		var mode:String = "none"; // none, key, val
		var key:String = "";
		var val:String = "";
		for each (var line:String in lines) {
			if ((line.length >= 5) && (line.slice(0, 5).toLowerCase() == "msgid")) {
				if (mode == "val") recordPairIn(key, val, dict);
				mode = "key";
				key = "";
			} else if ((line.length >= 6) && (line.slice(0, 6).toLowerCase() == "msgstr")) {
				mode = "val";
				val = "";
			}
			if (mode == "key") key += extractQuotedString(line);
			if (mode == "val") val += extractQuotedString(line);
		}
		if (mode == "val") recordPairIn(key, val, dict);
		return dict;
	}

	private function extractQuotedString(s:String):String {
		// Remove leading and trailing whitespace characters.
		var i:int = s.indexOf('"'); // find first double-quote
		if (i < 0) i = s.indexOf(" "); // if no double-quote, start after first space
		var result:String = "";
		for (i = i + 1; i < s.length; i++) {
			var ch:String = s.charAt(i);
			if ((ch == "\\") && (i < (s.length - 1))) {
				ch = s.charAt(++i);
				if (ch == "n") ch = "\n";
				if (ch == "r") ch = "\r";
				if (ch == "t") ch = "\t";
			}
			if (ch == '"') return result; // closing double-quote
			result += ch;
		}
		return result;
	}

	private function recordPairIn(key:String, val:String, dict:Object):void {
		// Handle some special cases where block specs changed for Scratch 2.0.
		// The default case is to simple modernize the arg specs.
		switch (key) {
		case "%a of %m":
			val = val.replace("%a", "%m.attribute");
			val = val.replace("%m", "%m.sprite");
			dict["%m.attribute of %m.sprite"] = val;
			break;
		case "stop all":
			dict["@stop stop all"] = "@stop " + val;
			break;
		case "touching %m?":
			dict["touching %m.touching?"] = val.replace("%m", "%m.touching");
			break;
		case "turn %n degrees":
			dict["turn @turnRight %n degrees"] = val.replace("%n", "@turnRight %n");
			dict["turn @turnLeft %n degrees"] = val.replace("%n", "@turnLeft %n");
			break;
		case "when %m clicked":
			dict["when @greenFlag clicked"] = val.replace("%m", "@greenFlag");
			dict["when I am clicked"] = val.replace("%m", "I am");
			break;
		default:
			var converted:Array = modernize(key, val);
			dict[converted[0]] = converted[1];
		}
	}

	private function modernize(key:String, val:String):Array {
		// Convert an old block specs to the new format.
		// (The new format uses %m.<menuName> and %d.<menuName> for menu commands, whereas
		// the old format had many individual letters that were difficult to remember.)
		for each (var conv:Array in conversions) {
			var regex:RegExp = new RegExp(conv[0], "g");
			if (key.search(regex) >= 0) {
				return [key.replace(regex, conv[1]), val.replace(regex, conv[1])];
			}
		}
		return [key, val];
	}

	private var conversions:Array = [
		["%a", "%m.attribute"],
		["%C", "%c"],
		["%D", "%d.drum"],
		["%d", "%d.direction"],
		["%e", "%m.broadcast"],
		["%f", "%m.mathOp"],
		["%g", "%m.effect"],
		["%H", "%m.sensor"],
		["%h", "%m.booleanSensor"],
		["%I", "%d.instrument"],
		["%k", "%m.key"],
		["%l", "%m.costume"],
		["%m", "%m.spriteOrMouse"],
		["%N", "%d.note"],
		["%S", "%m.sound"],
	];

}}