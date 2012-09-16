// ImagesPart.as
// John Maloney, November 2011
//
// This part holds the Costumes/Scenes list for the current sprite (or stage),
// as well as the image editor, camera, import button and other image media tools.

package ui.parts {
	import flash.display.*;
	import assets.Resources;
	import scratch.*;
	import ui.media.MediaPane;
	import ui.paintui.PaintEdit;
	import uiwidgets.*;

public class ImagesPart extends UIPart {

	private const columnWidth:int = 115;

	private var shape:Shape;
	private var addButton:Button;
	private var listFrame:ScrollFrame;
	private var paintEdit:PaintEdit;

	public function ImagesPart(app:Scratch) {
		this.app = app;
		shape = new Shape();
		addChild(shape);

		addButton = new Button('Add Costume', createCostume);
		addButton.y = 12;
		addChild(addButton);

		addListFrame();

		paintEdit = new PaintEdit(app);
		paintEdit.x = columnWidth + 13;
		paintEdit.y = 15;
		addChild(paintEdit);
	}

	public function refresh():void {
		var isStage:Boolean = app.viewedObj() && app.viewedObj().isStage;
		addButton.setLabel(isStage ? 'Add Scene' : 'Add Costume');
		addButton.x = (columnWidth - addButton.width) / 2;
		(listFrame.contents as MediaPane).refresh();
		paintEdit.startKeyboardListener();
	}

	public function step():void {
		(listFrame.contents as MediaPane).updateSelection();
		listFrame.updateScrollbars();
		if (!parent) paintEdit.stopKeyboardListener();
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();

		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(CSS.tabColor);
		g.drawRect(0, 0, w, h);
		g.endFill();

		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(CSS.panelColor);
		g.drawRect(columnWidth + 1, 5, w - columnWidth - 6, h - 10);
		g.endFill();

		fixlayout();
	}

	public function selectCostume():void {
		var contents:MediaPane = listFrame.contents as MediaPane;
		contents.updateSelection();
		var obj:ScratchObj = app.viewedObj();
		if (obj == null) return;
		clearPaintEditor();
		paintEdit.editCostume(obj.currentCostume());
		paintEdit.startKeyboardListener();
	}

	private function clearPaintEditor():void {
		// I'm not sure how to reset the paint editor.
		// For now, delete it and create a new one.
		if (paintEdit && paintEdit.parent) {
			paintEdit.stopKeyboardListener();
			paintEdit.parent.removeChild(paintEdit);
		}
		paintEdit = new PaintEdit(app);
		paintEdit.x = columnWidth + 13;
		paintEdit.y = 15;
		paintEdit.setWidthHeight(w - columnWidth - 30, h - 30);
		addChild(paintEdit);
	}

	private function fixlayout():void {
		listFrame.setWidthHeight(columnWidth, h - listFrame.y);
		paintEdit.setWidthHeight(w - columnWidth - 30, h - 30);
		refresh();
	}

	private function addListFrame():void {
		listFrame = new ScrollFrame();
		listFrame.setContents(new MediaPane(app, 'costumes'));
		listFrame.contents.color = CSS.tabColor;
		listFrame.x = 1;
		listFrame.y = 40;
		addChild(listFrame);
	}

	private function createCostume():void {
		var obj:ScratchObj = app.viewedObj();
		if (obj == null) return;
		obj.costumes.push(new ScratchCostume('Untitled', Resources.createBmp('emptyCostume').bitmapData));
		refresh();
	}

}}
