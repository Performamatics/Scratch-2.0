// Specs.as
// John Maloney, April 2010
//
// This file defines the command blocks and categories.
// To add a new command:
//		a. add a specification for the new command to the commands array
//		b. add a primitive for the new command to the interpreter

package {
	import flash.display.Bitmap;
	import assets.Resources;

public class Specs {

	public static const GET_VAR:String = "readVariable";
	public static const SET_VAR:String = "setVar:to:";
	public static const CHANGE_VAR:String = "changeVar:by:";
	public static const GET_LIST:String = "contentsOfList:";
	public static const CALL:String = "call";
	public static const PROCEDURE_DEF:String = "procDef";
	public static const GET_PARAM:String = "getParam";
	public static const CLONE_START:String = "whenCloned";

	public static const motionCategory:int = 1;
	public static const controlCategory:int = 6;
	public static const triggersCategory:int = 5;
	public static const variablesCategory:int = 9;
	public static const myBlocksCategory:int = 10;
	public static const listCategory:int = 12;

	public static const blocksCategory:int = 0x7C4B1E;
	public static const variableColor:int = 0xF3761D; // 0xbf1a11;
	public static const listColor:int = 0xd93311; // 0xD94D11;
	
	// 0xb3170e; // 0xc72e10; // 0xc74710;  0xcc3010; //0xB2390F;//0xd93311; // 0xc41b63;
//	public static const listColor:int = 0xb32a0e; // 0xb0195a;
	public static const procedureCallColor:int = blocksCategory;
	public static const parameterColor:int = 0xF88020;
	public static const undefinedColor:int = 0xFF0000;
	public static const unimplementedColor:int = 0x505050;

	public static const grayColor:int = 0x4c4d4f;

	public static const categories:Array = [
	  // id   category name	  color
		[0,  "undefined",	0xD42828],
		[1,  "Motion",		0x2F55A5],
		[2,  "Looks",		0x8050CC],
		[3,  "Sound",		0xD65D9E],
		[13, "Orchestra",	0x009AD0],
		//[4,  "Pen",			0x2A8240],
		[5,  "Triggers",	0xD98B15],
		[6,  "Control",		0xE6A822],
		[7,  "Sensing",		0x009BD0],
		[8,  "Operators",	0x7CC142],
		[9,  "Data",		variableColor],
		[10, "My Blocks",	blocksCategory],
		[11, "Motor",		0x1B50B9],
		[12, "List",		listColor],
		[98, "Obsolete", 		0x6D6F70],
		[99, "Experimental",	0xC0B000],
		[102, "Looks (stage)",	0x8F56E3],
	];

	public static function blockColor(categoryID:int):int {
		for each (var entry:Array in categories) {
			if (entry[0] == categoryID) return entry[2];
		}
		return undefinedColor;
	}

	public static function nameForCategory(categoryID:int):String {
		if (categoryID > 100) categoryID -= 100;
		for each (var entry:Array in categories) {
			if (entry[0] == categoryID) return entry[1];
		}
		return "Unknown";
	}

	public static function IconNamed(name:String):* {
		// Block icons are 2x resolution to look better when scaled.
		var icon:Bitmap;
		if (name == "greenFlag") icon = Resources.createBmp('flagIcon');
		if (name == "random") icon = Resources.createBmp('randomIcon');
		if (name == "stop") icon = Resources.createBmp('stopIcon');
		if (name == "turnLeft") icon = Resources.createBmp('turnLeftIcon');
		if (name == "turnRight") icon = Resources.createBmp('turnRightIcon');
		if (icon != null) icon.scaleX = icon.scaleY = 0.5;
		return icon;
	}

	public static var commands:Array = [
		// block specification					type, cat, opcode			default args (optional)
		// motion
		["move %n steps",						" ", 1, "forward:",					10],
		["turn @turnRight %n degrees",			" ", 1, "turnRight:",				15],
		["turn @turnLeft %n degrees",			" ", 1, "turnLeft:",				15],
		["--"],
		["point in direction %d.direction",		" ", 1, "heading:",					90],
		["point towards %m.spriteOrMouse",		" ", 1, "pointTowards:",			""],
		["--"],
		["go to x:%n y:%n",						" ", 1, "gotoX:y:"],
		["go to %m.spriteOrMouse",				" ", 1, "gotoSpriteOrMouse:", ""],
		["glide %n secs to x:%n y:%n",			" ", 1, "glideSecs:toX:y:elapsed:from:"],
		["--"],
		["change x by %n",						" ", 1, "changeXposBy:",			10],
		["set x to %n",							" ", 1, "xpos:",					0],
		["change y by %n",						" ", 1, "changeYposBy:",			10],
		["set y to %n",							" ", 1, "ypos:",					0],
		["--"],
		["if on edge, bounce",					" ", 1, "bounceOffEdge"],
		["--"],
		["x position",							"r", 1, "xpos"],
		["y position",							"r", 1, "ypos"],
		["direction",							"r", 1, "heading"],

/* Motor blocks:
		// motor
		["--"],
		["motor on for %n secs",				" ", 1, "motorOnFor:elapsed:from:",	1],
		["motor on",							" ", 1, "allMotorsOn"],
		["motor off",							" ", 1, "allMotorsOff"],
		["motor power %n",						" ", 1, "startMotorPower:",			100],
		["motor direction %m.motorDirection",	" ", 1, "setMotorDirection:",		"this way"],
*/

		// looks
		["switch to costume %m.costume",		" ", 2, "lookLike:",				"Costume1"],
		["next costume",						" ", 2, "nextCostume"],
		["costume #",							"r", 2, "costumeIndex"],
		["--"],
		["start scene %m.scene",				" ", 2, "startScene",				"Scene 1"],
		["--"],
		["%m.bubbleStyle %s",					" ", 2, "showBubble",				"say", "Hello"],
		["%m.bubbleStyle %s for %n secs",		" ", 2, "showBubbleAndWait",		"say", "Hello", 2],
		["-"],
		["change %m.effect effect by %n",		" ", 2, "changeGraphicEffect:by:",	"color", 25],
		["set %m.effect effect to %n",			" ", 2, "setGraphicEffect:to:",		"color", 0],
		["clear graphic effects",				" ", 2, "filterReset"],
		["-"],
		["change size by %n",					" ", 2, "changeSizeBy:",	 		10],
		["set size to %n%",						" ", 2, "setSizeTo:", 				100],
		["size",								"r", 2, "scale"],
		["-"],
		["show",								" ", 2, "show"],
		["hide",								" ", 2, "hide"],
		["-"],
		["go to front",							" ", 2, "comeToFront"],
		["go back %n layers",					" ", 2, "goBackByLayers:", 			1],

		// stage looks
		["start scene %m.scene",				" ", 102, "startScene", 					"Scene 1"],
		["next scene",							" ", 102, "nextScene"],
		["scene #",								"r", 102, "backgroundIndex"],
		["-"],
		["change %m.effect effect by %n",		" ", 102, "changeGraphicEffect:by:",		"color", 25],
		["set %m.effect effect to %n",			" ", 102, "setGraphicEffect:to:",			"color", 0],
		["clear graphic effects",				" ", 102, "filterReset"],
		["---"],

		// Laptop Orchestra
		["Send To Server at %s",						"h", 13, "sendToServer:",			"127.0.0.1"],		// Matt Vaughan Sep/1/2012
		//["Play from measure %d to %d at %s",			"h", 13, "sendFuturePhrase:", 0, 1, "127.0.0.1"],		// Angelo Gamarra Sep/27/2012 new hat block for measures with length
		["Play on Server %d.midinote for %n", 			" ", 13, "addNote:",					60, 0.5],		// Brendan Reilly Sep/22/2012 added %d.midinote (look in BlockMenus.as)
		["Sets server instrument to %d.instrument",		" ", 13, "midiInstrument:",					  1],		// duplicate of setInstrument  %d.instrument added Sep/22/2012  Brendan Reilly (look in BlockMenus.as)
		["Play Chord",									"c", 13, "playChord:"],									// Angelo Gamarra Sep/6/2012
		
		// sound
		["play sound %m.sound",					" ", 3, "playSound:",						"pop"],
		["play sound %m.sound until done",		" ", 3, "doPlaySoundAndWait",				"pop"],
		["stop all sounds",						" ", 3, "stopAllSounds"],
		["-"],
		["play drum %d.drum for %n beats",		" ", 3, "drum:duration:elapsed:from:",		35, 0.2],
		["rest for %n beats",					" ", 3, "rest:elapsed:from:",				0.2],
		["-"],
		["play note %d.note for %n beats",		" ", 3, "noteOn:duration:elapsed:from:",	60, 0.5],
		["set instrument to %d.instrument",		" ", 3, "midiInstrument:",					1],
		["-"],
		["change volume by %n",					" ", 3, "changeVolumeBy:",					-10],
		["set volume to %n%",					" ", 3, "setVolumeTo:", 					100],
		["volume",								"r", 3, "volume"],
		["-"],
		["change tempo by %n",					" ", 3, "changeTempoBy:",					20],
		["set tempo to %n bpm",					" ", 3, "setTempoTo:",						60],
		["tempo",								"r", 3,  "tempo"],
		["---"],

		// pen
		["clear",								" ", 4, "clearPenTrails"],
		["-"],
		["pen down",							" ", 4, "putPenDown"],
		["pen up",								" ", 4, "putPenUp"],
		["-"],
		["set pen color to %c",					" ", 4, "penColor:"],
		["change pen color by %n",				" ", 4, "changePenHueBy:"],
		["set pen color to %n",					" ", 4, "setPenHueTo:", 		0],
		["-"],
		["change pen shade by %n",				" ", 4, "changePenShadeBy:"],
		["set pen shade to %n",					" ", 4, "setPenShadeTo:",		50],
		["-"],
		["change pen size by %n",				" ", 4, "changePenSizeBy:",		1],
		["set pen size to %n",					" ", 4, "penSize:", 			1],
		["-"],
		["stamp",								" ", 4, "stampCostume"],
		["stamp transparent %n",				" ", 4, "stampTransparent",		50],

		// stage pen
		["clear",								" ", 104, "clearPenTrails"],

	// triggers
		["when @greenFlag clicked",				"h", 5, "whenGreenFlag"],
		["when %m.key key pressed",				"h", 5, "whenKeyPressed", 		"space"],
		["when I am clicked",					"h", 5, "whenClicked"],
		["when scene %m.scene starts",			"h", 5, "whenSceneStarts", 		"Scene 1"],
		["-"],
		["broadcast %m.broadcast",				" ", 5, "broadcast:",			""],
		["broadcast %m.broadcast and wait",		" ", 5, "doBroadcastAndWait",	""],
		["when I receive %m.broadcast",			"h", 5, "whenIReceive",			""],

		// control
		["wait %n secs",						" ", 6, "wait:elapsed:from:",	1],
		["-"],
		["forever",								"cf",6, "doForever"],
		["repeat %n",							"c", 6, "doRepeat", 10],
		["-"],
		["forever if %b",						"cf",6, "doForeverIf"],
		["if %b",								"c", 6, "doIf"],
		["if %b",								"e", 6, "doIfElse"],
		["wait until %b",						" ", 6, "doWaitUntil"],
		["repeat until %b",						"c", 6, "doUntil"],
		["-"],
		["stop script",							"f", 6, "doReturn"],
		["@stop stop all",						"f", 6, "stopAll"],
		["-"],
		["create clone",						" ", 6, "createClone"],
		["delete this clone",					"f", 6, "deleteClone"],
		["clone startup",						"h", 6, CLONE_START],

		// sensing
		["touching %m.touching?",				"b", 7, "touching:",			""],
		["touching color %c?",					"b", 7, "touchingColor:"],
		["color %c is touching %c?",			"b", 7, "color:sees:"],
		["-"],
		["ask %s and wait",						" ", 7, "doAsk", 				"What's your name?"],
		["answer",								"r", 7, "answer"],
		["-"],
		["mouse x",								"r", 7, "mouseX"],
		["mouse y",								"r", 7, "mouseY"],
		["mouse down?",							"b", 7, "mousePressed"],
		["-"],
		["key %m.key pressed?",					"b", 7, "keyPressed:",			"space"],
		["-"],
		["distance to %m.spriteOrMouse",		"r", 7, "distanceTo:",			""],
		["-"],
		["reset timer",							" ", 7, "timerReset"],
		["timer",								"r", 7, "timer"],
		["-"],
		["%m.attribute of %m.spriteOrStage",	"r", 7, "getAttribute:of:",		"x position", ""],
		["-"],
		["loudness",							"r", 7, "soundLevel"],
		["loud?",								"b", 7, "isLoud"],
		["-"],
		["Scratcher name",						"r", 7, "username"],
		["-"],
		["motion amount",						"r", 7, "motionAmount"],
		["motion direction",					"r", 7, "motionDirection"],		
		["-"],
		["face detected",						"b", 7, "faceDetected"],
		["face x",								"r", 7, "faceX"],
		["face y",								"r", 7, "faceY"],
		["-"],
		["%m.sensor sensor value",				"r", 7, "sensor:", 				"slider"],
		["sensor %m.booleanSensor?",			"b", 7, "sensorPressed:", 		"button pressed"],
		
		// stage sensing
		["ask %s and wait",						" ", 107, "doAsk", 				"What's your name?"],
		["answer",								"r", 107, "answer"],
		["-"],
		["mouse x",								"r", 107, "mouseX"],
		["mouse y",								"r", 107, "mouseY"],
		["mouse down?",							"b", 107, "mousePressed"],
		["-"],
		["key %m.key pressed?",					"b", 107, "keyPressed:",		"space"],
		["-"],
		["reset timer",							" ", 107, "timerReset"],
		["timer",								"r", 107, "timer"],
		["-"],
		["%m.attribute of %m.spriteOrStage",	"r", 107, "getAttribute:of:",	"x position", ""],
		["-"],
		["loudness",							"r", 107, "soundLevel"],
		["loud?",								"b", 107, "isLoud"],
		["-"],
		["Scratcher name",						"r", 107, "username"],
		["-"],
		["motion amount",						"r", 107, "motionAmount"],
		["motion direction",					"r", 107, "motionDirection"],		
		["-"],
		["face detected",						"b", 107, "faceDetected"],
		["face x",								"r", 107, "faceX"],
		["face y",								"r", 107, "faceY"],
		["-"],
		["%m.sensor sensor value",				"r", 107, "sensor:", 			"slider"],
		["sensor %m.booleanSensor?",			"b", 107, "sensorPressed:", 	"button pressed"],

		// operators
		["%n + %n",								"r", 8, "+",					"", ""],
		["%n - %n",								"r", 8, "-",					"", ""],
		["%n * %n",								"r", 8, "*",					"", ""],
		["%n / %n",								"r", 8, "/",					"", ""],
		["-"],
		["pick random %n to %n",				"r", 8, "randomFrom:to:",		1, 10],
		["-"],
		["%s < %s",								"b", 8, "<",					"", ""],
		["%s = %s",								"b", 8, "=",					"", ""],
		["%s > %s",								"b", 8, ">",					"", ""],
		["-"],
		["%b and %b",							"b", 8, "&"],
		["%b or %b",							"b", 8, "|"],
		["not %b",								"b", 8, "not"],
		["-"],
		["join %s %s",							"r", 8, "concatenate:with:",	"hello ", "world"],
		["letter %n of %s",						"r", 8, "letter:of:",			1, "world"],
		["length of %s",						"r", 8, "stringLength:",		"world"],
		["-"],
		["%n mod %n",							"r", 8, "\\\\",					"", ""],
		["round %n",							"r", 8, "rounded", 				""],
		["-"],
		["%m.mathOp of %n",						"r", 8, "computeFunction:of:",	"sqrt", 10],
	
	// variables
		["set %v to %s",						" ", 9, SET_VAR,				"", 0],
		["change %v by %n",						" ", 9, CHANGE_VAR,				"", 10],
		["show variable %v",					" ", 9, "showVariable:",		""],
		["hide variable %v",					" ", 9, "hideVariable:",		""],

		// list
		["add %s to %m.listName",							" ", 12, "append:toList:",		"thing", ""],
		["-"],
		["delete %d.listDeleteItem of %m.listName",			" ", 12, "deleteLine:ofList:",	1, ""],
		["insert %s at %d.listItem of %m.listName",			" ", 12, "insert:at:ofList:",	"thing", 1, ""],
		["replace item %d.listItem of %m.listName with %s",	" ", 12, "setLine:ofList:to:",	1, "", "thing"],
		["-"],
		["item %d.listItem of %m.listName",					"r", 12, "getLine:ofList:",		1, ""],
		["length of %m.listName",							"r", 12, "lineCountOfList:",	""],
		["%m.listName contains %s",							"b", 12, "list:contains:",		"", "thing"],


		// obsolete blocks that may be used in older projects
		["abs %n",								"r", 98, "abs"],
		["sqrt %n",								"r", 98, "sqrt"],
		["say %s for %n secs",					" ", 98, "say:duration:elapsed:from:",		"Hello!", 2],
		["say %s",								" ", 98, "say:",							"Hello!"],
		["think %s for %n secs",				" ", 98, "think:duration:elapsed:from:", 	"Hmm...", 2],
		["think %s",							" ", 98, "think:",							"Hmm..."],
		["switch to background %m.costume",		" ", 98, "showBackground:", "background1"],
		["next background",						" ", 98, "nextBackground"],

		// experimental control prims
		["for each %v in %s",					"c", 99, "FOR_LOOP", "v", 10],
		["defer display updates",				"c", 99, "SUSPEND_REDRAW"],
		["while %b",							"c", 99, "WHILE"],
		["redraw",								" ", 99, "REDRAW"],

/* xxx for Eric's live coding
		["note on %n vel %n chan %n",			" ", 3, "midiNoteOn",		60, 80, 0],
		["note off %n chan %n",					" ", 3, "midiNoteOff",		60, 0],
		["pitch bend %n chan %n",				" ", 3, "midiPitchBend",	8192, 0],
		["set controller %n to %n chan %n",		" ", 3, "midiController",	10, 127, 0],
		["set instrument to %n chan %n",		" ", 3, "midiProgram",		0, 0],
		["turn all notes off",					" ", 3, "midiReset"],
		["use java synthesizer %b",				" ", 3, "midiUseJavaSynth"],
		["midi time",							"r", 3, "midiTime"],
*/
// xxx for Jay and Eric's camera experiments:
/*
		["sense color 1 %c", " ", 102, "senseColor1", 0xC0C0],
		["sense color 2 %c", " ", 102, "senseColor2", 0xC0C0],
		["sense color 3 %c", " ", 102, "senseColor3", 0xC0C0],
		["sense color 4 %c", " ", 102, "senseColor4", 0xC0C0],
		["sense color 5 %c", " ", 102, "senseColor5", 0xC0C0],
		["sense color 6 %c", " ", 102, "senseColor6", 0xC0C0],
		["set thresholds hue %n sat %n bri %n",	" ", 102, "setHSVThresholds", 15, .2, .2],
//		["filter rgb %c dist %n", " ", 102, "setRGBDiffFilter", 0, .5],
*/

		// testing
		["noop",								"r", 99, "COUNT"],
		["counter",								"r", 99, "COUNT"],
		["clear counter",						" ", 99, "CLR_COUNT"],
		["incr counter",						" ", 99, "INCR_COUNT"],

	];

}}
