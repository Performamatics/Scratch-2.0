/*
     ___             ___            ___           ___           ___           ___            ___
    /  /\           /  /\          /  /\         /  /\         /  /\         /  /\          /__/\
   /  /:/~/\       /  /:/         /  /::\       /  /::\       /  /:/        /  /:/          \  \:\
  /  /:/ /::\     /  /:/  ___    /  /:/\:\     /  /:/\:\     /  /::        /  /:/  ___       \__\:\
 /  /:/ /:/\:\   /  /:/  /  /\  /  /:/~/:/    /  /:/~/::\   /  /:::\      /  /:/  /  /\  ___ /  /::\
/__/:/ /:/\ \:\ /__/:/  /  /:/ /__/:/ /:/___ /__/:/ /:/\:\ /__/:/ \:\    /__/:/  /  /:/ /__/\  /:/\:\
\  \:\/:/ / /:/ \  \:\ /  /:/  \  \:\/:::::/ \  \:\/:/__\/ \__\/\  \:\   \  \:\ /  /:/  \  \:\/:/__\/
 \  \::/ / /:/   \  \:\  /:/    \  \::/~~~~   \  \::             \  \:\   \  \:\  /:/    \  \::/
  \__\/ / /:/     \  \:\/:/      \  \:\        \  \:\             \  \:\   \  \::/:/      \  \:\
       / /:/       \  \::/        \  \:\        \  \:\             \  \:\   \  \/:/        \  \:\
      \__\/         \__\/          \__\/         \__\/              \__\/    \__\/          \__\/

*/

package ui.paintui {
	import flash.display.Graphics;

public class Turtle {

	public static const DEGTOR:Number = 2 * Math.PI / 360;

	public static var heading:Number = 0;
	public static var xmax:Number;
	public static var ymax:Number;
	public static var xcor:Number;
	public static var ycor:Number;
	public static var pendown:Boolean;

	public static function forward(n:Number, g:Graphics):void {
		var oldx:Number = xcor, oldy:Number = ycor;
		if (pendown) {
			g.moveTo(xcor + xmax / 2, ymax / 2 - ycor);
		}
		xcor += n * Math.sin(heading * DEGTOR);
		ycor += n * Math.cos(heading * DEGTOR);
		if (pendown) {
			var sx:Number = xcor + xmax / 2, sy:Number = ymax / 2 - ycor;
			g.lineTo(sx, sy);
		}
	}

	public static function rt(a:Number):void {
		heading += a;
		heading = heading % 360;
		if (heading < 0) heading += 360;
	}

	public static function seth(a:Number):void { heading = 0; rt(a) }
	public static function cosdeg(deg:Number):Number { return Math.cos(deg * DEGTOR) }
	public static function sindeg(deg:Number):Number { return Math.sin(deg * DEGTOR) }

}}
