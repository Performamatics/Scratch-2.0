// NotePlayer.as
// John Maloney, June 2010
//
// Plays soundbank instruments.
//
// A soundbank instrument is a ByteArray of unsigned 8-bit samples sampled
// at 11025 samples/second. Most instruments have an original pitch of
// middle C, but some are an octave lower or higher. An instrument may be
// looped from the end of the buffer back to loopPoint.

package sound {
	import flash.utils.ByteArray;

public class NotePlayer extends ScratchSoundPlayer {

	private var originalPitch:Number = 261.6255653; // middle C
	private var originalSamplingRate:Number = 11025;

	private var index:Number = 0;
	private var samplesRemaining:int; // determines note duration

	private var isLooped:Boolean = false;
	private var loopPoint:int;
	private var loopLength:int;

	public function NotePlayer(soundData:ByteArray, loopPoint:int, pitchMultiplier:Number):void {
		super(null); // required by compiler since signature of this constructor differs from superclass
		this.soundData = soundData;
		stepSize = originalSamplingRate / 44100.0;
		startOffset = 0;
		endOffset = soundData.length;

		originalPitch = 261.6255653 * pitchMultiplier;	// middle C, adjusted by pitchMultiplier
		if ((loopPoint >= 0) && (loopPoint < soundData.length)) {
			this.isLooped = true;
			this.loopPoint = loopPoint;
			this.loopLength = soundData.length - loopPoint;
		}
	}

	public function setDuration(secs:Number):void {
		stepSize = originalSamplingRate / 44100;
		samplesRemaining = 44100 * secs;
		if (!isLooped) samplesRemaining = Math.min(samplesRemaining, soundData.length / stepSize);
	}

	public function setNoteAndDuration(midiNote:int, secs:Number):void {
		midiNote = Math.max(0, Math.min(midiNote, 127));
		var pitch:Number = 440 * Math.pow(2, (midiNote - 69) / 12); // midi key 69 is A=440 Hz
		stepSize = (pitch / originalPitch) * (originalSamplingRate / 44100);
		samplesRemaining = 44100 * secs;
		if (!isLooped) samplesRemaining = Math.min(samplesRemaining, soundData.length / stepSize);
	}

	protected override function interpolatedSample():Number {
		if (samplesRemaining-- <= 0) { noteFinished(); return 0 }
		index += stepSize;
		while (index >= soundData.length) {
			if (!isLooped) return 0;
			index -= loopLength;
		}
		var i:int = int(index);
		var frac:Number = index - i;
		var curr:Number = rawSample(i);
		var next:Number = rawSample(i + 1);
		var sample:Number = (curr + (frac * (next - curr)) - 128.0) / 128.0;
		if (samplesRemaining < 1000) sample *= (samplesRemaining / 1000.0);
		return volume * sample;
	}

	private function rawSample(index:int):int {
		if (index < soundData.length) return soundData[index];
		if (isLooped) return soundData[loopPoint + ((index - loopPoint) % loopLength)];
		return 0;
	}

}}
