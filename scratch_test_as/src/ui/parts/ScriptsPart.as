// ScriptsPart.as
// John Maloney, November 2011
//
// This part holds the palette and scripts pane for the current sprite (or stage).

package ui.parts {
	import flash.display.*;
	import ui.*;
	import uiwidgets.*;

public class ScriptsPart extends UIPart {

	private var shape:Shape;
	private var selector:PaletteSelector;
	private var paletteFrame:ScrollFrame;
	private var scriptsFrame:ScrollFrame;

	public function ScriptsPart(app:Scratch) {
		this.app = app;
		shape = new Shape();
		addChild(shape);

		selector = new PaletteSelector(app);
		addChild(selector);

		var palette:BlockPalette = new BlockPalette();
		palette.color = CSS.tabColor; // CSS.panelColor;
		paletteFrame = new ScrollFrame();
		paletteFrame.setContents(palette);
		addChild(paletteFrame);

		var scriptsPane:ScriptsPane = new ScriptsPane();
		scriptsFrame = new ScrollFrame(true);
		scriptsFrame.setContents(scriptsPane);
		addChild(scriptsFrame);

		app.palette = palette;
		app.scriptsPane = scriptsPane;
	}

	public function updatePalette():void { selector.select(selector.selectedCategory) }
	public function resetCategory():void { selector.select(Specs.motionCategory) }

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		fixlayout();
		redraw();
	}

	private function fixlayout():void {
		selector.x = 1;
		selector.y = 5;
		paletteFrame.x = selector.x;
		paletteFrame.y = selector.y + selector.height + 2;
		paletteFrame.setWidthHeight(selector.width + 1, h - paletteFrame.y - 2); // 5
		scriptsFrame.x = selector.x + selector.width + 2;
		scriptsFrame.y = selector.y + 1;
		scriptsFrame.setWidthHeight(w - scriptsFrame.x - 5, h - scriptsFrame.y - 5);
	}

	private function redraw():void {
		var paletteW:int = paletteFrame.visibleW();
		var paletteH:int = paletteFrame.visibleH();
		var scriptsW:int = scriptsFrame.visibleW();
		var scriptsH:int = scriptsFrame.visibleH();

		var g:Graphics = shape.graphics;
		g.clear();
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.beginFill(CSS.tabColor);
		g.drawRect(0, 0, w, h);
		g.endFill();

//		hLine(g, paletteFrame.x - 1, paletteFrame.y + paletteH, paletteW + 1);
//		hLine(g, paletteFrame.x - 1, paletteFrame.y - 1, paletteW + 1);

		var lineY:int = selector.y + selector.height;
		var darkerBorder:int = CSS.borderColor - 0x141414;
		var lighterBorder:int = 0xF2F2F2;
		g.lineStyle(1, darkerBorder, 1, true);
		hLine(g, paletteFrame.x + 8, lineY, paletteW - 20);
		g.lineStyle(1, lighterBorder, 1, true);
		hLine(g, paletteFrame.x + 8, lineY + 1, paletteW - 20);

		g.lineStyle(1, darkerBorder, 1, true);
		g.drawRect(scriptsFrame.x - 1, scriptsFrame.y - 1, scriptsW + 1, scriptsH + 1);
	}

	private function hLine(g:Graphics, x:int, y:int, w:int):void {
		g.moveTo(x, y);
		g.lineTo(x + w, y);
	}

}}
