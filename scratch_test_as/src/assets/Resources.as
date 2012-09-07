package assets {
	import flash.display.Bitmap;
	import flash.text.*;
	import flash.utils.getDefinitionByName;

public class Resources {

	public static function createBmp(resourceName:String):Bitmap {
		var imgRef:Class = getDefinitionByName("assets::Resources_" + resourceName) as Class;
		return new imgRef() as Bitmap;
	}

	public static function makeLabel(s:String, fmt:TextFormat, x:int = 0, y:int = 0):TextField {
		// Create a non-editable text field for use as a label.
		// Note: Although labels not related to bitmaps, this was a handy
		// place to put this function.
		var tf:TextField = new TextField();
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.selectable = false;
		tf.defaultTextFormat = fmt;
		tf.text = s;
		tf.x = x;
		tf.y = y;
		return tf;
	}

	// Upstatement graphics
	[Embed(source="../assets/UI/topbar/scratchlogo.png")] private const scratchlogo:Class;
	[Embed(source="../assets/UI/topbar/copyTool.png")] private const copyTool:Class;
	[Embed(source="../assets/UI/topbar/cutTool.png")] private const cutTool:Class;
	[Embed(source="../assets/UI/topbar/growTool.png")] private const growTool:Class;
	[Embed(source="../assets/UI/topbar/shrinkTool.png")] private const shrinkTool:Class;
	[Embed(source="../assets/UI/topbar/helpTool.png")] private const helpTool:Class;
	[Embed(source="../assets/UI/topbar/projectPageFlip.png")] private const projectPageFlip:Class;

	// Block Icons
	[Embed(source="../assets/blocks/flagIcon.png")] private const flagIcon:Class;
	[Embed(source="../assets/blocks/randomIcon.png")] private const randomIcon:Class;
	[Embed(source="../assets/blocks/stopIcon.png")] private const stopIcon:Class;
	[Embed(source="../assets/blocks/turnLeftIcon.png")] private const turnLeftIcon:Class;
	[Embed(source="../assets/blocks/turnRightIcon.png")] private const turnRightIcon:Class;

	// Sound Editing
	[Embed(source="../assets/UI/sound/playOn.png")] private const playSndOn:Class;
	[Embed(source="../assets/UI/sound/playOff.png")] private const playSndOff:Class;
	[Embed(source="../assets/UI/sound/recordOn.png")] private const recordSndOn:Class;
	[Embed(source="../assets/UI/sound/recordOff.png")] private const recordSndOff:Class;
	[Embed(source="../assets/UI/sound/stopOn.png")] private const stopSndOn:Class;
	[Embed(source="../assets/UI/sound/stopOff.png")] private const stopSndOff:Class;
	[Embed(source="../assets/UI/sound/rewindOn.png")] private const rewindSndOn:Class;
	[Embed(source="../assets/UI/sound/rewindOff.png")] private const rewindSndOff:Class;
	[Embed(source="../assets/UI/sound/forwardOn.png")] private const forwardSndOn:Class;
	[Embed(source="../assets/UI/sound/forwardOff.png")] private const forwardSndOff:Class;
	[Embed(source="../assets/UI/sound/pauseOn.png")] private const pauseSndOn:Class;
	[Embed(source="../assets/UI/sound/pauseOff.png")] private const pauseSndOff:Class;

	// Buttons
	[Embed(source="../assets/UI/buttons/addItemOff.gif")] private const addItemOff:Class;
	[Embed(source="../assets/UI/buttons/addItemOn.gif")] private const addItemOn:Class;
	[Embed(source="../assets/UI/buttons/checkboxOff.gif")] private const checkboxOff:Class;
	[Embed(source="../assets/UI/buttons/checkboxOn.gif")] private const checkboxOn:Class;
	[Embed(source="../assets/UI/buttons/flipOff.png")] private const flipOff:Class;
	[Embed(source="../assets/UI/buttons/flipOn.png")] private const flipOn:Class;
	[Embed(source="../assets/UI/buttons/greenflagOff.png")] private const greenflagOff:Class;
	[Embed(source="../assets/UI/buttons/greenflagOn.png")] private const greenflagOn:Class;
	[Embed(source="../assets/UI/buttons/infoOff.png")] private const infoOff:Class;
	[Embed(source="../assets/UI/buttons/infoOn.png")] private const infoOn:Class;
	[Embed(source="../assets/UI/buttons/norotationOff.png")] private const norotationOff:Class;
	[Embed(source="../assets/UI/buttons/norotationOn.png")] private const norotationOn:Class;
	[Embed(source="../assets/UI/buttons/playOff.png")] private const playOff:Class;
	[Embed(source="../assets/UI/buttons/playOn.png")] private const playOn:Class;
	[Embed(source="../assets/UI/buttons/rotate360Off.png")] private const rotate360Off:Class;
	[Embed(source="../assets/UI/buttons/rotate360On.png")] private const rotate360On:Class;
	[Embed(source="../assets/UI/buttons/stopOff.png")] private const stopOff:Class;
	[Embed(source="../assets/UI/buttons/stopOn.png")] private const stopOn:Class;
	[Embed(source="../assets/UI/buttons/unlockedOff.png")] private const unlockedOff:Class;
	[Embed(source="../assets/UI/buttons/unlockedOn.png")] private const unlockedOn:Class;
	[Embed(source="../assets/UI/player/fullscreenOff.png")] private const fullscreenOff:Class;
	[Embed(source="../assets/UI/player/fullscreenOn.png")] private const fullscreenOn:Class;

	// Sprite Library
	[Embed(source="../assets/UI/library/sprhighlighted.png")] private const sprhighlighted:Class;
	[Embed(source="../assets/UI/library/seealloff.png")] private const viewAllOff:Class;
	[Embed(source="../assets/UI/library/seeallon.png")] private const viewAllOn:Class;
	[Embed(source="../assets/UI/library/seeoneoff.png")] private const viewOneOff:Class;
	[Embed(source="../assets/UI/library/seeoneon.png")] private const viewOneOn:Class;

	// Misc UI Elements
	[Embed(source="../assets/UI/misc/hatshape.png")] private const hatshape:Class;
	[Embed(source="../assets/UI/misc/playerStartScreen.png")] private var playerStartScreen:Class;
	[Embed(source="../assets/UI/misc/promptCheckButton.png")] private const promptCheckButton:Class;
	[Embed(source="../assets/UI/misc/removeItem.png")] private const removeItem:Class;
	[Embed(source="../assets/UI/misc/speakerOff.png")] private const speakerOff:Class;
	[Embed(source="../assets/UI/misc/speakerOn.png")] private const speakerOn:Class;

	// New Costume and Sound editors
	[Embed(source="../assets/UI/mediacenter/cameraOff.png")] private const cameraOff:Class;
	[Embed(source="../assets/UI/mediacenter/cameraOn.png")] private const cameraOn:Class;
	[Embed(source="../assets/UI/mediacenter/libraryOff.png")] private const libraryOff:Class;
	[Embed(source="../assets/UI/mediacenter/libraryOn.png")] private const libraryOn:Class;
	[Embed(source="../assets/UI/mediacenter/uploadOff.png")] private const uploadOff:Class;
	[Embed(source="../assets/UI/mediacenter/uploadOn.png")] private const uploadOn:Class;
	[Embed(source='../assets/UI/mediacenter/imgPlaceholder.png')] private static var Placeholder:Class;
	[Embed(source='../assets/empty.png')] private static var emptyCostume:Class;

	// Paint
	[Embed(source="../assets/UI/paint/swatchesOff.png")] private const swatchesOff:Class;
	[Embed(source="../assets/UI/paint/swatchesOn.png")] private const swatchesOn:Class;
	[Embed(source="../assets/UI/paint/wheelOff.png")] private const wheelOff:Class;
	[Embed(source="../assets/UI/paint/wheelOn.png")] private const wheelOn:Class;

	[Embed(source="../assets/UI/paint/noZoomOff.png")] private const noZoomOff:Class;
	[Embed(source="../assets/UI/paint/noZoomOn.png")] private const noZoomOn:Class;
	[Embed(source="../assets/UI/paint/zoomInOff.png")] private const zoomInOff:Class;
	[Embed(source="../assets/UI/paint/zoomInOn.png")] private const zoomInOn:Class;
	[Embed(source="../assets/UI/paint/zoomOutOff.png")] private const zoomOutOff:Class;
	[Embed(source="../assets/UI/paint/zoomOutOn.png")] private const zoomOutOn:Class;

	[Embed(source="../assets/UI/paint/wicon.png")] private const WidthIcon:Class;
	[Embed(source="../assets/UI/paint/hicon.png")] private const HeightIcon:Class;

	// Paint Tools
	[Embed(source="../assets/UI/paint/ellipseOff.png")] private const ellipseOff:Class;
	[Embed(source="../assets/UI/paint/ellipseOn.png")] private const ellipseOn:Class;
	[Embed(source="../assets/UI/paint/pathOff.png")] private const pathOff:Class;
	[Embed(source="../assets/UI/paint/pathOn.png")] private const pathOn:Class;
	[Embed(source="../assets/UI/paint/rectOff.png")] private const rectOff:Class;
	[Embed(source="../assets/UI/paint/rectOn.png")] private const rectOn:Class;
	[Embed(source="../assets/UI/paint/selectOff.png")] private const selectOff:Class;
	[Embed(source="../assets/UI/paint/selectOn.png")] private const selectOn:Class;

	[Embed(source="../assets/UI/paint/sliceOn.png")] private const sliceOn:Class;
	[Embed(source="../assets/UI/paint/sliceOff.png")] private const sliceOff:Class;
	[Embed(source="../assets/UI/paint/wandOff.png")] private const wandOff:Class;
	[Embed(source="../assets/UI/paint/wandOn.png")] private const wandOn:Class;
	[Embed(source="../assets/UI/paint/eyedropperOff.png")] private const eyedropperOff:Class;
	[Embed(source="../assets/UI/paint/eyedropperOn.png")] private const eyedropperOn:Class;
	[Embed(source="../assets/UI/paint/textOff.png")] private const textOff:Class;
	[Embed(source="../assets/UI/paint/textOn.png")] private const textOn:Class;

	[Embed(source="../assets/UI/paint/eraserOn.png")] private const eraserOn:Class;
	[Embed(source="../assets/UI/paint/eraserOff.png")] private const eraserOff:Class;
	[Embed(source="../assets/UI/paint/cloneOff.png")] private const cloneOff:Class;
	[Embed(source="../assets/UI/paint/cloneOn.png")] private const cloneOn:Class;
	[Embed(source="../assets/UI/paint/frontOff.png")] private const frontOff:Class;
	[Embed(source="../assets/UI/paint/frontOn.png")] private const frontOn:Class;
	[Embed(source="../assets/UI/paint/backOn.png")] private const backOn:Class;
	[Embed(source="../assets/UI/paint/backOff.png")] private const backOff:Class;
	[Embed(source="../assets/UI/paint/lassoOn.png")] private const lassoOn:Class;
	[Embed(source="../assets/UI/paint/lassoOff.png")] private const lassoOff:Class;
	[Embed(source="../assets/UI/paint/paintbucketOn.png")] private const paintbucketOn:Class;
	[Embed(source="../assets/UI/paint/paintbucketOff.png")] private const paintbucketOff:Class;

}}
