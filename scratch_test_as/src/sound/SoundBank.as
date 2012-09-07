// SoundBank.as
// John Maloney, June 2010
//
// A collection of instrument and drum resources to support the note and drum commands.

package sound {
	import flash.utils.ByteArray;

public class SoundBank {

	public static function getInstrumentEntry(i:int):Array {
		// Return an instrument entry (samples, loop point) for the given
		// Scratch 1.4 instrument number in range 1..128. If the number is
		// out of range, use a default instrument.
		if ((i < 1) || (i > 128)) return instrument[1];
		return instrument[instrumentMap[i - 1]];
	}

	public static function getDrumEntry(i:int):Array {
		// Return a drum entry (samples, loop point) for the given
		// Scratch 1.4 drum number in range 35..81. If the number is
		// out of range, use a default drum.
		if ((i < 35) || (i > 81)) return drum[1];
		return drum[drumMap[i - 35]];
	}

	static public var instrumentNames:Array = [
		"none",			// skip zero; instrument numbers start with 1
		// Piano
		"Acoustic Grand", "Bright Acoustic", "Electric Grand", "Honky-Tonk",
		"Electric Piano 1", "Electric Piano 2", "Harpsichord", "Clavinet",
		// Chromatic Percussion
		"Celesta", "Glockenspiel", "Music Box", "Vibraphone",
		"Marimba", "Xylophone", "Tubular Bells", "Dulcimer",
		// Organ
		"Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ",
		"Reed Organ", "Accordion", "Harmonica", "Tango Accordion",
		// Guitar
		"Nylon String Guitar","Steel String Guitar","Electric Jazz Guitar","Electric Clean Guitar",
		"Electric Muted Guitar","Overdriven Guitar","Distortion Guitar", "Guitar Harmonics",
		// Bass
		"Acoustic Bass", "Electric Bass (finger)", "Electric Bass (pick)", "Fretless Bass",
		"Slap Bass 1", "Slap Bass 2", "Synth Bass 1", "Synth Bass 2",
		// Strings 1
		"Violin", "Viola", "Cello", "Contrabass",
		"Tremolo Strings", "Pizzicato Strings", "Orchestral Strings", "Timpani",
		// Strings 2
		"String Ensemble 1", "String Ensemble 2", "SynthStrings 1", "SynthStrings 2",
		"Choir Aahs", "Voice Oohs", "Synth Voice", "Orchestra Hit",
		// Brass
		"Trumpet", "Trombone", "Tuba", "Muted Trumpet",
		"French Horn", "Brass Section", "SynthBrass 1", "SynthBrass 2",
		// Reed
		"Soprano Sax", "Alto Sax", "Tenor Sax", "Baritone Sax",
		"Oboe", "English Horn", "Bassoon", "Clarinet",
		// Flute
		"Piccolo", "Flute", "Recorder", "Pan Flute",
		"Blown Bottle", "Shakuhachi", "Whistle", "Ocarina",
		// Synth Lead
		"Lead 1 (square)", "Lead 2 (sawtooth)", "Lead 3 (calliope)", "Lead 4 (chiff)",
		"Lead 5 (charang)", "Lead 6 (voice)", "Lead 7 (fifths)", "Lead 8 (bass+lead)",
		// Synth Pipe
		"Pad 1 (new age)", "Pad 2 (warm)", "Pad 3 (polysynth)", "Pad 4 (choir)",
		"Pad 5 (bowed)", "Pad 6 (metallic)", "Pad 7 (halo)", "Pad 8 (sweep)",
		// Synth Effects
		"FX 1 (rain)", "FX 2 (soundtrack)", "FX 3 (crystal)", "FX 4 (atmosphere)",
		"FX 5 (brightness)", "FX 6 (goblins)", "FX 7 (echoes)", "FX 8 (sci-fi)",
		// Ethnic
		"Sitar", "Banjo", "Shamisen", "Koto",
		"Kalimba", "Bagpipe", "Fiddle", "Shanai",
		// Percussive
		"Tinkle Bell", "Agogo", "Steel Drums", "Woodblock",
		"Taiko Drum", "Melodic Tom", "Synth Drum", "Reverse Cymbal",
		// Sound effects
		"Guitar Fret Noise", "Breath Noise", "Seashore", "Bird Tweet",
		"Telephone Ring", "Helicopter", "Applause", "Gunshot"
	];

	// map from Scratch 1.4 instrument to a sound bank instrument
	static private var instrumentMap:Array = [
		 1,  1,  1,  1,  1,  1,  1,  1,		// Pianos
		 2,  2,  2,  2,  2,  2,  2,  2,		// Chromatic percusion (e.g. xylophone, marimba, etc.)
		10, 10, 10, 10, 10, 10, 10, 10,		// Organ
		 4,  4,  4,  4,  4,  4,  4,  4,		// Guitar
		 6,  6,  6,  6,  6,  6,  6,  6,		// Bass
		 3,  3,  3,  3,  3, 13,  4,  1,		// Strings
		 3,  3,  3,  3,  7,  7,  7,  1,		// Strings + Chorus
		12, 12, 12, 12, 12, 12, 12, 12,		// Brass
		 1,  1,  1,  1,  1,  1,  1,  8,		// Reeds
		 9,  9,  9,  9,  9,  9,  9,  9,		// Flutes
		11, 11, 11, 11, 11, 11, 11, 11,		// Synth
		 5,  5,  5,  5,  5,  5,  5,  5,		// Synth Pad
		 1,  1,  1,  1,  1,  1,  1,  1,		// Synth Effects
		 1,  1,  1,  1,  1,  1,  1,  1,		// Ethnic
		 1,  1, 14,  1,  1,  1,  1,  1,		// Percussive
		 1,  1,  1,  1,  1,  1,  1,  1,		// Sound Effects
	];		

	static public var drumNames:Array = [
		"Acoustic Bass Drum",
		"Bass Drum 1",
		"Side Stick",
		"Acoustic Snare",
		"Hand Clap",
		"Electric Snare",
		"Low Floor Tom",
		"Closed Hi-Hat",
		"High Floor Tom",
		"Pedal Hi-Hat",
		"Low Tom",
		"Open Hi-Hat",
		"Low-Mid Tom",
		"Hi-Mid Tom",
		"Crash Cymbal 1",
		"High Tom",
		"Ride Cymbal 1",
		"Chinese Cymbal",
		"Ride Bell",
		"Tambourine",
		"Splash Cymbal",
		"Cowbell",
		"Crash Cymbal 2",
		"Vibraslap",
		"Ride Cymbal 2",
		"Hi Bongo",
		"Low Bongo",
		"Mute Hi Conga",
		"Open Hi Conga",
		"Low Conga",
		"High Timbale",
		"Low Timbale",
		"High Agogo",
		"Low Agogo",
		"Cabasa",
		"Maracas",
		"Short Whistle",
		"Long Whistle",
		"Short Guiro",
		"Long Guiro",
		"Claves",
		"Hi Wood Block",
		"Low Wood Block",
		"Mute Cuica",
		"Open Cuica",
		"Mute Triangle",
		"Open Triangle"];

	// map from Scratch 1.4 drum numbers to a sound bank drums
	// Note: Scratch 1.4 drum number range is [35..81]
	static private var drumMap:Array = [
		1,	// Acoustic Bass Drum
		1,	// Bass Drum 1
		9,	// Side Stick
		4,	// Acoustic Snare
		12,	// Hand Clap
		4,	// Electric Snare
		1,	// Low Floor Tom
		2,	// Closed Hi-Hat
		1,	// High Floor Tom
		2,	// Pedal Hi-Hat
		5,	// Low Tom
		1,	// Open Hi-Hat
		6,	// Low-Mid Tom
		6,	// Hi-Mid Tom
		8,	// Crash Cymbal 1
		1,	// High Tom
		8,	// Ride Cymbal 1
		8,	// Chinese Cymbal
		11,	// Ride Bell
		1,	// Tambourine
		8,	// Splash Cymbal
		11,	// Cowbell
		8,	// Crash Cymbal 2
		1,	// Vibraslap
		8,	// Ride Cymbal 2
		1,	// Hi Bongo
		1,	// Low Bongo
		1,	// Mute Hi Conga
		1,	// Open Hi Conga
		1,	// Low Conga
		1,	// High Timbale
		1,	// Low Timbale
		1,	// High Agogo
		1,	// Low Agogo
		1,	// Cabasa
		1,	// Maracas
		1,	// Short Whistle
		1,	// Long Whistle
		3,	// Short Guiro
		3,	// Long Guiro
		1,	// Claves
		7,	// Hi Wood Block
		7,	// Low Wood Block
		1,	// Mute Cuica
		1,	// Open Cuica
		11,	// Mute Triangle
		1,	// Open Triangle
	];

	// instruments (pitched)
	// entries are [<sample bytes><loop point><pitch adjust (for octaves)>]

	static private var instrument:Array = [];

	[Embed(source="../soundbank/pianoblend.bin", mimeType="application/octet-stream")] static private const Instr1: Class;
	instrument[1] = [ByteArray(new Instr1()), 17673, 0.5];

	[Embed(source="../soundbank/vibes.bin", mimeType="application/octet-stream")] static private const Instr2: Class;
	instrument[2] = [ByteArray(new Instr2()), -1, 1];

	[Embed(source="../soundbank/string.bin", mimeType="application/octet-stream")] static private const Instr3: Class;
	instrument[3] = [ByteArray(new Instr3()), 11484, 1];

	[Embed(source="../soundbank/acoustic_guitar.bin", mimeType="application/octet-stream")] static private const Instr4: Class;
	instrument[4] = [ByteArray(new Instr4()), 1972, 0.5];

	[Embed(source="../soundbank/analogue_pad.bin", mimeType="application/octet-stream")] static private const Instr5: Class;
	instrument[5] = [ByteArray(new Instr5()), -1, 0.5];

	[Embed(source="../soundbank/bass34.bin", mimeType="application/octet-stream")] static private const Instr6: Class;
	instrument[6] = [ByteArray(new Instr6()), 5475, 0.25];

	[Embed(source="../soundbank/choir.bin", mimeType="application/octet-stream")] static private const Instr7: Class;
	instrument[7] = [ByteArray(new Instr7()), 0, 0.5];

	[Embed(source="../soundbank/clarinet.bin", mimeType="application/octet-stream")] static private const Instr8: Class;
	instrument[8] = [ByteArray(new Instr8()), 574, 2];

	[Embed(source="../soundbank/flute.bin", mimeType="application/octet-stream")] static private const Instr9: Class;
	instrument[9] = [ByteArray(new Instr9()), 7913, 1];

	[Embed(source="../soundbank/organ.bin", mimeType="application/octet-stream")] static private const Instr10: Class;
	instrument[10] = [ByteArray(new Instr10()), 2356, 1];

	[Embed(source="../soundbank/synthLead81.bin", mimeType="application/octet-stream")] static private const Instr11: Class;
	instrument[11] = [ByteArray(new Instr11()), 1156, 1];

	[Embed(source="../soundbank/trombone.bin", mimeType="application/octet-stream")] static private const Instr12: Class;
	instrument[12] = [ByteArray(new Instr12()), 2621, 0.5];

	[Embed(source="../soundbank/pizz.bin", mimeType="application/octet-stream")] static private const Instr13: Class;
	instrument[13] = [ByteArray(new Instr13()), -1, 0.5];

	[Embed(source="../soundbank/steeldrum.bin", mimeType="application/octet-stream")] static private const Instr14: Class;
	instrument[14] = [ByteArray(new Instr14()), -1, 0.5];

	[Embed(source="../soundbank/cello.bin", mimeType="application/octet-stream")] static private const Instr15: Class;
	instrument[15] = [ByteArray(new Instr15()), 7356, 0.5];

	// drums
	// entries are [<sample bytes><loop point><pitch adjust (for octaves)>]

	static private var drum:Array = [];

	[Embed(source="../soundbank/drums/kickdrum.bin", mimeType="application/octet-stream")] static private const Drum1: Class;
	drum[1] = [ByteArray(new Drum1()), -1, 1];

	[Embed(source="../soundbank/drums/hihat.bin", mimeType="application/octet-stream")] static private const Drum2: Class;
	drum[2] = [ByteArray(new Drum2()), -1, 1];

	[Embed(source="../soundbank/drums/guiro.bin", mimeType="application/octet-stream")] static private const Drum3: Class;
	drum[3] = [ByteArray(new Drum3()), -1, 1];

	[Embed(source="../soundbank/drums/snare.bin", mimeType="application/octet-stream")] static private const Drum4: Class;
	drum[4] = [ByteArray(new Drum4()), -1, 1];

	[Embed(source="../soundbank/drums/tom1.bin", mimeType="application/octet-stream")] static private const Drum5: Class;
	drum[5] = [ByteArray(new Drum5()), -1, 1];

	[Embed(source="../soundbank/drums/tom2.bin", mimeType="application/octet-stream")] static private const Drum6: Class;
	drum[6] = [ByteArray(new Drum6()), -1, 1];

	[Embed(source="../soundbank/drums/woodblock.bin", mimeType="application/octet-stream")] static private const Drum7: Class;
	drum[7] = [ByteArray(new Drum7()), -1, 1];

	[Embed(source="../soundbank/drums/cymbal.bin", mimeType="application/octet-stream")] static private const Drum8: Class;
	drum[8] = [ByteArray(new Drum8()), -1, 1];

	[Embed(source="../soundbank/drums/sidestick.bin", mimeType="application/octet-stream")] static private const Drum9: Class;
	drum[9] = [ByteArray(new Drum9()), -1, 1];

	[Embed(source="../soundbank/drums/sticks.bin", mimeType="application/octet-stream")] static private const Drum10: Class;
	drum[10] = [ByteArray(new Drum10()), -1, 1];

	[Embed(source="../soundbank/drums/cowbell.bin", mimeType="application/octet-stream")] static private const Drum11: Class;
	drum[11] = [ByteArray(new Drum11()), -1, 1];

	[Embed(source="../soundbank/drums/clap.bin", mimeType="application/octet-stream")] static private const Drum12: Class;
	drum[12] = [ByteArray(new Drum12()), -1, 1];

}}