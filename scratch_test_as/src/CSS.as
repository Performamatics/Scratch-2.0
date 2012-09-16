// CSS.as
// Paula Bonta, November 2011
//
// Styles for Scratch Editor based on the Upstatement design.

package {
	import flash.text.*;

public class CSS {

	// Colors
	public static const white:int = 0xFFFFFF;
	public static const topBarColor:int = 0x9C9EA2; // 0x6D6E70;
	public static const tabColor:int = 0xE6E8E8;
	public static const panelColor:int = 0xF2F2F2;
	public static const borderColor:int = 0xD0D1D2;
	public static const textColor:int = 0x6C6D6F; // 0x929497;
	public static const alertColor:int = 0xE03030;
	public static const buttonLabelColor:int = textColor;
	public static const buttonLabelOverColor:int = 0xFBA939;
	public static const offColor:int = 0x9FA1A3; // 0x9FA1A3;
	public static const onColor:int = textColor; // 0x4C4D4F;
	public static const overColor:int= 0x179FD7;

	// Fonts
	public static const normalTextFormat:TextFormat = new TextFormat('Lucida Grande', 12, textColor);
	public static const topBarButtonFormat:TextFormat = new TextFormat('Lucida Grande', 12, white, true);
	public static const titleFormat:TextFormat = new TextFormat('Lucida Grande', 13, textColor);
	public static const paletteFormat:TextFormat = normalTextFormat;
	public static const paletteSectionFormat:TextFormat = new TextFormat('Lucida Grande', 11, textColor);
	public static const thumbnailFormat:TextFormat = new TextFormat('Lucida Grande', 11, textColor);
	public static const thumbnailExtraInfoFormat:TextFormat = new TextFormat('Lucida Grande', 9, textColor);
	public static const projectTitleFormat:TextFormat = new TextFormat('Lucida Grande', 13, textColor);
	public static const projectInfoFormat:TextFormat = new TextFormat('Lucida Grande', 10, textColor);
	public static const progressInfoFormat:TextFormat = new TextFormat('Lucida Grande', 11, textColor);
	public static const paintWidthHeightFormat:TextFormat = new TextFormat('Lucida Grande', 11, textColor);

	// Section title bars
	public static const titleBarColors:Array = [white, tabColor];
	public static const titleBarH:int = 30;

	// Paint editor (temporary)
	public static const bgColor:int = white; // xxx change this
	public static const fontHighlight:int = 0xFFFFFF;
	public static const labelFormat:TextFormat = new TextFormat('Lucida Grande', 12, 0x929497);
	public static const textFormatOn:TextFormat = new TextFormat('Lucida Grande', 12, fontHighlight);

}}
