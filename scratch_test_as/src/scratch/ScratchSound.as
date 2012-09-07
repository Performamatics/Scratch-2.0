// ScratchSound.as
// John Maloney, June 2010
//
// Represents a Scratch sampled sound.
// Possible formats:
//	''			WAVE format 1, 16-bit uncompressed
//	'adpcm'		WAVE format 17, 4-bit ADPCM
//	'mp3'		MP3 file or WAVE format 85
//	'squeak'	Squeak ADPCM format, 2-bits to 5-bits per sample

package scratch {
	import flash.utils.ByteArray;
	import sound.*;
	import util.*;
	import util.JSON_AB;
	import sound.mp3.MP3FileReader;

public class ScratchSound {

	public var soundName:String = '';
	public var soundID:int;
	public var md5:String;
	public var soundData:ByteArray = new ByteArray();
	public var format:String = '';
	public var rate:int = 44100;
	public var sampleCount:int;
	public var channels:int;
	public var bitsPerSample:int;

	public function ScratchSound(name:String, wavFileData:ByteArray) {
		this.soundName = name;
		this.soundData = wavFileData;
		if (wavFileData != null) {
			try {
				var info:* = WAVFile.decode(wavFileData);
				rate = info.samplesPerSecond;
				sampleCount = info.sampleCount;
				channels = 1;
				if (info.encoding == 17) format = 'adpcm';
				if (info.encoding == 85) initMP3(soundData);
			} catch (e:Error) {
				initMP3(soundData);
			}
		}
	}

	public function initMP3(mp3Data:ByteArray):void {
		format = 'mp3';
		soundData = mp3Data;
		var mp3Info:Object = new MP3FileReader(mp3Data).getInfo();
		if ((mp3Info.samplingRate == 0) || (mp3Info.sampleCount == 0) || (mp3Info.channels == 0)) {
			// bad MP3 file
			format = '';
			soundData = WAVFile.encode(new ByteArray(), 0, 44100, false); // empty sound
			sampleCount = 0;
		} else {
			rate = mp3Info.samplingRate;
			sampleCount = mp3Info.sampleCount;
			channels = mp3Info.channels;
		}
	}

	public function sndplayer():ScratchSoundPlayer {
		var player:ScratchSoundPlayer
		if (format == 'squeak') player = new SqueakSoundPlayer(soundData, bitsPerSample, rate);
		else if (format == 'mp3') player = new MP3SoundPlayer(soundData);
		else player = new ScratchSoundPlayer(soundData);
		player.scratchSound = this;
		return player;
	}

	public function getLengthInMsec():Number { return (1000.0 * sampleCount) / rate};

	public function toString():String {
		var secs:Number = Math.ceil(getLengthInMsec() / 1000);
		var result:String = 'ScratchSound(' + secs + ' secs, ' + rate;
		if (format != '') result += ' ' + format;
		result += ')';
		return result;
	}

	public function prepareToSave():void {
		if (format == 'squeak') { // convert Squeak ADPCM to WAV ADPCM
			var uncompressedData:ByteArray = new SqueakSoundDecoder(bitsPerSample).decode(soundData);
trace('converting squeak sound to WAV ADPCM; sampleCount old: ' + sampleCount + ' new: ' + (uncompressedData.length / 2));
			sampleCount = uncompressedData.length / 2;
			soundData = WAVFile.encode(uncompressedData, sampleCount, rate, true);
			format = 'adpcm';
			bitsPerSample = 4;
		}
		if (!md5) {
			var extension:String = (format == 'mp3') ? '.mp3' : '.wav';
			md5 = MD5.hashBinary(soundData) + extension;
		}
	}

	public static function isWAV(data:ByteArray):Boolean {
		if (data.length < 12) return false;
		data.position = 0;
		if (data.readUTFBytes(4) != "RIFF") return false;
		data.readInt();
		return (data.readUTFBytes(4) == "WAVE");
	}

	public function writeJSON(json:JSON_AB):void {
		json.writeKeyValue('soundName', soundName);
		json.writeKeyValue('soundID', soundID);
		json.writeKeyValue('md5', md5);
		json.writeKeyValue('sampleCount', sampleCount);
		json.writeKeyValue('rate', rate);
		json.writeKeyValue('format', format);
	}

	public function readJSON(jsonObj:Object):void {
		soundName = jsonObj.soundName;
		soundID = jsonObj.soundID;
		md5 = jsonObj.md5;
		sampleCount = jsonObj.sampleCount;
		rate = jsonObj.rate;
		format = jsonObj.format;
	}

}}
