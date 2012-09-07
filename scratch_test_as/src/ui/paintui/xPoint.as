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
	import flash.geom.Point;

public class xPoint {

	public static function vsum(a:Point, b:Point):Point {
		var res:Point = new Point();
		res.x = a.x + b.x;
		res.y = a.y + b.y;
		return res;
	}

	public static function vdiff(a:Point, b:Point):Point {
		var res:Point = new Point();
		res.x = a.x - b.x;
		res.y = a.y - b.y;
		return res;
	}

	public static function vfloor(a:Point):Point {
		var res:Point = new Point();
		res.x = Math.floor (a.x);
		res.y = Math.floor (a.y);
		return res;
	}

	public static function vneg(a:Point):Point {
		var res:Point = new Point();
		res.x = -a.x;
		res.y = -a.y;
		return res;
	}

	public static function vlen(a:Point):Number {
		return Math.sqrt(a.x * a.x + a.y * a.y);
	}

	public static function vscale(a:Point, s:Number):Point {
		var res:Point = new Point();
		res.x = a.x * s;
		res.y = a.y * s;
		return res;
	}

	public static function vdot(a:Point, b:Point):Number {
		return a.x * b.x + a.y * b.y;
	}

	public static function vmid(a:Point, b:Point):Point {
		var res:Point = new Point();
		res.x = ((a.x + b.x) / 2);
		res.y = ((a.y + b.y) / 2);
		return res;
	}

	public static function controlPoint(before:Point, here:Point, after:Point):Point {
		var beforev:Point = vdiff(before, here);
		var afterv:Point = vdiff(after, here);
		var bisect:Point = vsum(vnorm (beforev), vnorm (afterv));
		var perp:Point = vperp(bisect);
		if (vdot(perp, afterv) < 0) perp = vneg(perp);
		return perp;
	}

	private static function vnorm(a:Point):Point {
		var len:Number = vlen(a);
		var res:Point = new Point();
		if (len == 0) len = 0.001;
		res.x = a.x / len;
		res.y = a.y / len;
		return res;
	}

	private static function vperp(a:Point):Point {
		var res:Point = new Point();
		res.x = -a.y;
		res.y = a.x;
		return res;
	}

}}
