package ui {
import flash.display.Graphics;
  
public class DrawPath {
	static private var startx:Number, starty:Number = 0;
	static private var pathx:Number = 0; 
	static private var pathy:Number = 0;
	static private var aCurve:Boolean = false;
	static private var prevX:int, prevY:int;

	static public function drawPath(path:Array, g:Graphics, wr:Number, hr:Number, cr:Number, c2r:Number = 0):void {
		pathx = 0; pathy = 0; // start top left
		aCurve = false;
		for (var i:* in path) drawSection(path[i], g, wr, hr, cr, c2r);
	}

	static private function drawSection (item:Array, g:Graphics, wrubberband:Number, hrubberband:Number, crubberband:Number, elserubberband:Number):void {
		switch ((String (item[0])).toLowerCase()) { 
		case "m":
			absoluteMove(item[1], item[2]);
			g.moveTo(pathx, pathy);
			startx = item[1];
			starty = item[2];
			break;
		case "l":
			relativeMove(item[1], item[2]);
			g.lineTo(pathx, pathy);
			break;
		case "h":
			pathx += item[1];
			g.lineTo(pathx, pathy);
			break;
		case "v":
			pathy += item[1];
			g.lineTo(pathx, pathy);
			break;
		case "c": 
			var cx:Number = pathx + item[1];
			var cy:Number = pathy + item[2];
			var px:Number = pathx + item [3];
			var py:Number = pathy + item[4];
			g.curveTo(cx, cy, px, py);
			relativeMove(item[3], item[4]);
			break;
		case "c45": 
			var curvature:Number = (item.length > 3) ? item[3] : 0.42;
			var h:Number= hrubberband / 2;
			var p1x:Number = (item[1] > 0) ? item[1] + h : item[1] - h;
			var p1y:Number = (item[2] > 0) ? item[2] + h : item[2] - h;
			drawCurve(g, pathx, pathy, pathx + p1x,  pathy + p1y, curvature);
			relativeMove(p1x, p1y);
			break;
		case "wstrech": pathx += wrubberband * item[1]; g.lineTo(pathx, pathy); break;
		case "hstrech": pathy += hrubberband * item[1]; g.lineTo(pathx, pathy); break;
		case "cstrech": pathy += crubberband * item[1]; g.lineTo(pathx, pathy); break;
		case "c2strech": pathy += elserubberband * item[1]; g.lineTo(pathx, pathy); break;
		case "linestrech": 
			pathx += hrubberband * item[1]; pathy+= hrubberband  * item[2];
			g.lineTo(pathx, pathy);
			break;
		case "z":
			absoluteMove(startx, starty); 
			g.lineTo(pathx, pathy);
			break;
		default:
			trace("command not implemented" , item[0]);
			break;
		}
	}

	static private function drawCurve(g:Graphics, p1x:int, p1y:int, p2x:int, p2y:int, roundness:Number):void {
		// compute control point by following an orthogal vector from the midpoint
		// of the line between p1 and p2 scaled by roundness * dist(p1, p2)
		var midX:Number = (p1x + p2x) / 2.0;
		var midY:Number = (p1y + p2y) / 2.0;
		var cx:Number = midX + (roundness * (p2y - p1y));
		var cy:Number = midY - (roundness * (p2x - p1x));
		g.curveTo(cx, cy, p2x, p2y);
	}

	static private function absoluteMove(dx:Number, dy:Number):void {pathx = dx; pathy=dy;}

	static private function relativeMove(dx:Number, dy:Number):void {pathx += dx; pathy+=dy;}

}}
