// WaveformView.as
// John Maloney, November 2011

package soundui {
	import flash.display.*;
	import flash.media.*;
	import flash.text.*;
	import flash.utils.*;
	import uiwidgets.*;

public class WaveformView extends Sprite {

	private const borderColor:int = 0x202020;
	private const bgColor:int = 0xF0F0F0;
	private const selectionColor:int = 0xA0A0F0;
	private const waveformColor:int = 0x101010;

	private var recorder:NewSoundRecorder;
	private var bg:Shape;
	private var selectionShape:Shape;
	private var waveShape:Shape;

	private var selectionStart:int;	// index of first selected condensedSample
	private var selectionEnd:int;	// index of last selected condensedSample
	private var scrollStart:int;	// index of first visible condensedSample

	private var samplesPerCondensedSample:int = 30;
	private var samples:Vector.<int> = new Vector.<int>();
	private var condensedSamples:Vector.<int> = new Vector.<int>();

	public function WaveformView(recorder:NewSoundRecorder, w:int = 300, h:int = 100) {
		this.recorder = recorder;
		bg = new Shape();
		addChild(bg);
		selectionShape = new Shape();
		addChild(selectionShape);
		waveShape = new Shape();
		addChild(waveShape);
		setWidthHeight(w, h);
	}

	public function setWidthHeight(w:int, h:int):void {
		var g:Graphics = bg.graphics;
		g.clear();
		g.lineStyle(1, borderColor);
		g.beginFill(bgColor);
		g.drawRect(0, 0, w, h);
		g.endFill();
//		drawSelection();
		drawWave();
	}

	public function setSound(snd:Sound):void {
		// Extract samples from the given sound, merging the stereo channels and
		// downsampling to 22050 samples/second.
		var samples:Vector.<int> = new Vector.<int>();
		var buf:ByteArray = new ByteArray;
		snd.extract(buf, 0, 0); // start at the beginning
		while (true) {
			buf.position = 0;
			var count:int = snd.extract(buf, 10000);
			if (count == 0) break;
			buf.position = 0;
			count = count / 2;  // downsample to 22050 samples/sec
			for (var i:int = 0; i < count; i++) {
				// output is the average of left and right channels
				var s:Number = buf.readFloat() + buf.readFloat();
				samples.push(16383 * s); // s range is -2 to 2; output range is -32766 to 32766
				buf.position += 8; // skip one sample (downsampling)
			}
		}
		setSamples(samples);
	}

	public function setSamples(samples:Vector.<int>):void {
		this.samples = samples;
		computeCondensedSamples();
		drawWave();
	}

	public function setScroll(n:Number):void {
		var maxScroll:int = condensedSamples.length - bg.width;
		scrollStart = Math.max(0, Math.min(n * maxScroll, maxScroll));
		drawWave();
	}

	public function setCondensation(n:int):void {
		var scrollFrac:Number = scrollStart / samplesPerCondensedSample;
		samplesPerCondensedSample = Math.max(1, n);
		computeCondensedSamples();
		setScroll(scrollFrac);
	}

	private function drawSelection():void {
		var g:Graphics = selectionShape.graphics;
		g.clear();
		g.beginFill(selectionColor);
		g.drawRect(0, 0, 10, 10); // xxx fix this
		g.endFill();
	}

	private function drawWave():void {
		var h:int = bg.height - 2;
		var scale:Number = (h / 2) / 32768;
		var center:int = h / 2;
		var count:int = Math.min(condensedSamples.length, bg.width);
trace('drawWave; count: ' + condensedSamples.length + ' scale: ' + scale);
		var g:Graphics = waveShape.graphics;
		g.clear();
		g.beginFill(waveformColor);
		if (samplesPerCondensedSample < 20) {
			var j:int = scrollStart * samplesPerCondensedSample;
			for (var i:int = 0; i < bg.width; i++) {
				if (j >= samples.length) break;
				var dy:int = scale * samples[j];
				if (dy > 0) g.drawRect(i, center - dy, 1, dy);
				else g.drawRect(i, center, 1, -dy);
				j += samplesPerCondensedSample;
			}
		} else {
			for (i = 0; i < bg.width; i++) {
				j = scrollStart + i;
				if (j >= condensedSamples.length) break;
				dy = scale * condensedSamples[j];
				g.drawRect(i, center - dy, 1, (2 * dy));
			}
		}
		g.endFill();
	}

	private function computeCondensedSamples():void {
		condensedSamples = new Vector.<int>();
		var level:int, n:int;
		for (var i:int = 0; i < samples.length; i++) {
			var v:int = samples[i];
			if (v < 0) v = -v;
			if (v > level) level = v;
			if (++n == samplesPerCondensedSample) {
				condensedSamples.push(level);
				level = n = 0;
			}
		}
	}

}}
