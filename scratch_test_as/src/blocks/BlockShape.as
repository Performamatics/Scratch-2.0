// BlockShape.as
// John Maloney, August 2009
//
// BlockShape handles drawing and resizing of a block shape.

package blocks {
	import flash.display.*;
	import flash.filters.*;

public class BlockShape extends Shape {

	// Shapes
	public static const RectShape:int = 1;
	public static const BooleanShape:int = 2;
	public static const NumberShape:int = 3;
	public static const CmdShape:int = 4;
	public static const FinalCmdShape:int = 5;
	public static const CmdOutlineShape:int = 6;
	public static const HatShape:int = 7;
	public static const ProcHatShape:int = 8;
	// C-shaped blocks
	public static const LoopShape:int = 9;
	public static const FinalLoopShape:int = 10;
	// E-shaped blocks
	public static const IfElseShape:int = 11;

	// Geometry
	public static const NotchDepth:int = 3;
	public static const EmptySubstackH:int = 12;
	public static const SubstackInset:int = 15;

	private const CornerInset:int = 3;
	private const DividerH:int = 15; // height of bars in C or E block
	private const NotchL1:int = 13;
	private const NotchL2:int = NotchL1 + NotchDepth;
	private const NotchR1:int = NotchL2 + 8;
	private const NotchR2:int = NotchR1 + NotchDepth;

	// Variables
	public var color:uint;

	private var shape:int;
	private var w:int;
	private var topH:int;
	private var substack1H:int = EmptySubstackH;
	private var substack2H:int = EmptySubstackH;
	private var drawFunction:Function = drawRectShape;
	private var redrawNeeded:Boolean = true;

	public function BlockShape(shape:int = 1, color:int = 0xFFFFFF) {
		this.color = color;
		this.shape = shape;
		setShape(shape);
		filters = blockShapeFilters();
	}

	public function setWidthAndTopHeight(newW:int, newTopH:int, doRedraw:Boolean = false):void {
		// Set the width and 'top' height of this block. For normal command
		// and reporter blocks, the top height is the height of the block.
		// For C and E shaped blocks (conditionals and loops), the top height
		// is the height of the top bar, which contains block labels and arguments.
		if ((newW == w) && (newTopH == topH)) return;
		w = newW;
		topH = newTopH;
		redrawNeeded = true;
		if (doRedraw) redraw();
	}

	public function setWidth(newW:int):void {
		if (newW == w) return;
		w = newW;
		redrawNeeded = true;
	}

	public function copyFeedbackShapeFrom(s:BlockShape, reporterFlag:Boolean):void {
		color = 0x0093ff;
		setShape(s.shape);
		w = s.w;
		topH = s.topH;
		substack1H = s.substack1H;
		substack2H = s.substack2H;
		filters = dropFeedbackFilters(reporterFlag);
		redrawNeeded = true;
		redraw();
	}

	public function setColor(color:int):void { this.color = color; redrawNeeded = true }

	public function setSubstack1Height(h:int):void {
		h = Math.max(h, EmptySubstackH);
		if (h != substack1H) { substack1H = h; redrawNeeded = true }
	}

	public function setSubstack2Height(h:int):void {
		h = Math.max(h, EmptySubstackH);
		if (h != substack2H) { substack2H = h; redrawNeeded = true }
	}

	public function canHaveSubstack1():Boolean { return shape >= LoopShape }
	public function canHaveSubstack2():Boolean { return shape == IfElseShape }

	public function substack1y():int { return topH }
	public function substack2y():int { return topH + substack1H + DividerH - NotchDepth }

	public function redraw():void {
		if (!redrawNeeded) return;
		var g:Graphics = this.graphics;
		g.clear();
		g.beginFill(color);
		drawFunction(g);
		g.endFill();
		redrawNeeded = false;
	}

	private function blockShapeFilters():Array {
		// filters for command and reporter Block outlines
		var f:BevelFilter = new BevelFilter(1);
		f.blurX = f.blurY = 2;
		f.highlightAlpha = 0.3;
		f.shadowAlpha = 0.6;
		return [f];		
	}

	private function dropFeedbackFilters(forReporter:Boolean):Array {
		// filters for command/reporter block drop feedback
		var f:GlowFilter;
		if (forReporter) {
			f = new GlowFilter(0xFFFFFF);
			f.strength = 5;
			f.blurX = f.blurY = 8;
			f.quality = 2;
		} else {
			f = new GlowFilter(0xFFFFFF);
			f.strength = 12;
			f.blurX = f.blurY = 6;
			f.inner = true;
		}
		f.knockout = true;
		return [f];
	}

	private function setShape(shape:int):void {
		this.shape = shape;
		switch(shape) {
		case RectShape:			drawFunction = drawRectShape; break;
		case BooleanShape:		drawFunction = drawBooleanShape; break;
		case NumberShape:		drawFunction = drawNumberShape; break;
		case CmdShape:
		case FinalCmdShape:		drawFunction = drawCmdShape; break;
		case CmdOutlineShape:	drawFunction = drawCmdOutlineShape; break;
		case LoopShape:
		case FinalLoopShape:	drawFunction = drawLoopShape; break;
		case IfElseShape:		drawFunction = drawIfElseShape; break;
		case HatShape:			drawFunction = drawHatShape; break;
		case ProcHatShape:		drawFunction = drawProcHatShape; break;
		}
	}

	private function drawRectShape(g:Graphics):void { g.drawRect(0, 0, w, topH) }

	private function drawBooleanShape(g:Graphics):void {
		var centerY:int = topH / 2;
		g.moveTo(centerY, topH);
		g.lineTo(0, centerY);
		g.lineTo(centerY, 0);
		g.lineTo(w - centerY, 0);
		g.lineTo(w, centerY);
		g.lineTo(w - centerY, topH);
	}

	private function drawNumberShape(g:Graphics):void {
		var centerY:int = topH / 2;
		g.moveTo(centerY, topH);
		curve(centerY, topH, 0, centerY);
		curve(0, centerY, centerY, 0);
		g.lineTo(w - centerY, 0);
		curve(w - centerY, 0, w, centerY);
		curve(w, centerY, w - centerY, topH);
	}

	private function drawCmdShape(g:Graphics):void {
		drawTop(g);
		drawRightAndBottom(g, topH, (shape != FinalCmdShape));
	}

	private function drawCmdOutlineShape(g:Graphics):void {
		g.endFill(); // do not fill
		g.lineStyle(1, 0, 0.4);
		drawTop(g);
		drawRightAndBottom(g, topH, (shape != FinalCmdShape));
		g.lineTo(0, CornerInset);
	}

	private function drawTop(g:Graphics):void {
		g.moveTo(0, CornerInset);
		g.lineTo(CornerInset, 0);
		g.lineTo(NotchL1, 0);
		g.lineTo(NotchL2, NotchDepth);
		g.lineTo(NotchR1, NotchDepth);
		g.lineTo(NotchR2, 0);
		g.lineTo(w - CornerInset, 0);
		g.lineTo(w, CornerInset);
	}

	private function drawRightAndBottom(g:Graphics, bottomY:int, hasNotch:Boolean, inset:int = 0):void {
		g.lineTo(w, bottomY - CornerInset);
		g.lineTo(w - CornerInset, bottomY);
		if (hasNotch) {
			g.lineTo(inset + NotchR2, bottomY);
			g.lineTo(inset + NotchR1, bottomY + NotchDepth);
			g.lineTo(inset + NotchL2, bottomY + NotchDepth);
			g.lineTo(inset + NotchL1, bottomY);
		}
		g.lineTo(inset + CornerInset, bottomY);
		if (inset > 0) g.lineTo(inset, bottomY + CornerInset); // bottom of control structure arm 
		else g.lineTo(0, bottomY - CornerInset); // bottom of entire block
	}

	private function drawHatShape(g:Graphics):void {
		g.moveTo(0, 12);
		curve(0, 12, 40, 0, 0.15);
		curve(40, 0, 80, 10, 0.12);
		g.lineTo(w - CornerInset, 10);
		g.lineTo(w, 10 + CornerInset);
		drawRightAndBottom(g, topH, true);
	}

	private function drawProcHatShape(g:Graphics):void {
		g.moveTo(0, 15);
		g.lineTo(w / 2, 0);
		g.lineTo(w , 15);
		drawRightAndBottom(g, topH, true);
	}

	private function drawLoopShape(g:Graphics):void {
		var h1:int = topH + substack1H - NotchDepth;
		drawTop(g);
		drawRightAndBottom(g, topH, true, SubstackInset);
		drawArm(g, h1);
		drawRightAndBottom(g, h1 + DividerH, (shape == LoopShape));
	}

	private function drawIfElseShape(g:Graphics):void {
		var h1:int = topH + substack1H - NotchDepth;
		var h2:int = h1 + DividerH + substack2H - NotchDepth;
		drawTop(g);
		drawRightAndBottom(g, topH, true, SubstackInset);
		drawArm(g, h1);
		drawRightAndBottom(g, h1 + DividerH, true, SubstackInset);
		drawArm(g, h2);
		drawRightAndBottom(g, h2 + DividerH, true);
	}

	private function drawArm(g:Graphics, armTop:int):void {
		g.lineTo(SubstackInset, armTop - CornerInset);
		g.lineTo(SubstackInset + CornerInset, armTop);
		g.lineTo(w - CornerInset, armTop);
		g.lineTo(w, armTop + CornerInset);		
	}

	private function curve(p1x:int, p1y:int, p2x:int, p2y:int, roundness:Number = 0.42):void {
		// Compute the Bezier control point by following an orthogal vector from the midpoint
		// of the line between p1 and p2 scaled by roundness * dist(p1, p2). The default roundness
		// approximates a circular arc. Negative roundness gives a concave curve.

		var midX:Number = (p1x + p2x) / 2.0;
		var midY:Number = (p1y + p2y) / 2.0;
		var cx:Number = midX + (roundness * (p2y - p1y));
		var cy:Number = midY - (roundness * (p2x - p1x));
		graphics.curveTo(cx, cy, p2x, p2y);
	}

}}
