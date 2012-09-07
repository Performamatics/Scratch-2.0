// LibraryPart.as
// John Maloney, November 2011
//
// This part holds the Sprite Library and the UI elements around it.

package ui.parts {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.text.*;
	import assets.Resources;
	import scratch.*;
	import uiwidgets.*;
	import ui.*;
	import ui.media.*;

public class LibraryPart extends UIPart {

	private const bgColor:int = 0xFFFFFF;
	private const highlightcolor:uint = 0x179FD7;
	private const stageAreaWidth:int = 85;

	private var shape:Shape;
	private var stageTitle:TextField;
	private var spritesTitle:TextField;
	private var objectInfoPart:ObjectInfoPart;

	private var stageThumbnail:SpriteThumbnail;
	private var spritesFrame:ScrollFrame;
	private var spritesPane:ScrollFrameContents;

	private var newSpriteButton:IconButton;
	private var importSpriteButton:IconButton;
	private var nextSceneButton:IconButton;
	private var prevSceneButton:IconButton;
	private var viewOne:IconButton;

	public function LibraryPart(app:Scratch) {
		this.app = app;
		shape = new Shape();
		addChild(shape);

		stageTitle = makeLabel('Stage', CSS.titleFormat, 10, 5);
		addChild(stageTitle);

		spritesTitle = makeLabel('Sprites', CSS.titleFormat, stageAreaWidth + 10, 5);
		addChild(spritesTitle);

		viewOne = new IconButton(toggleSpriteInfo, 'info')
		viewOne.x = spritesTitle.x + spritesTitle.textWidth + 20;
		viewOne.y = 7;
		addChild(viewOne);

		newSpriteButton = new IconButton(createSprite, makeButtonImg('Create', true), makeButtonImg('Create', false));
		newSpriteButton.isMomentary = true;
		addChild(newSpriteButton);

		importSpriteButton = new IconButton(importSprite, makeButtonImg('Import', true), makeButtonImg('Import', false));
		importSpriteButton.isMomentary = true;
		addChild(importSpriteButton);

		addStageArea();
		addSpritesArea();
		objectInfoPart = new ObjectInfoPart(app);
		addChild(objectInfoPart);
		objectInfoPart.visible = false;
	}

	private function makeButtonImg(label:String, isOn:Boolean):Sprite {
		var tabImg:Sprite = new Sprite();
		var tf:TextField = new TextField();
		tf.selectable = false;
		tf.defaultTextFormat = CSS.normalTextFormat;
		tf.textColor = isOn ? CSS.white : CSS.buttonLabelColor;
		tf.text = label;
		tf.width = tf.textWidth + 5;
		tf.height = tf.textHeight + 5;
		tf.x = (62 - tf.width) / 2;
		tf.y = 6;
		tabImg.addChild(tf);
		var g:Graphics = tabImg.graphics;
		var w:int = 62;
		var h:int = CSS.titleBarH;
		var rectpath:Array = [["M", 0, 0], ["h", w], ["v", h], ["h",-w],["v",-h]];
		var cpath:Array = 	[["M", 0, h], ["v", -h], ["h", w - cornerRadius],
			["c", cornerRadius, 0, cornerRadius, cornerRadius], ["v", h - cornerRadius]];
		var path:Array = (label == "Create") ? rectpath : cpath;
		if (isOn) {
			g.beginFill(CSS.overColor);
		} else {
			var m:Matrix = new Matrix();
 			m.createGradientBox(w, h, Math.PI / 2, 0, 0);
 			g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], m);  
		}
		DrawPath.drawPath(path, g, 0,0,0);
		g.endFill();
		g.lineStyle(0.5,CSS.borderColor,1,true);
		DrawPath.drawPath(path, g, 0, 0, 0);
		return tabImg;
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();
		drawTopBar(g, CSS.titleBarColors, getTopBarPath(w,CSS.titleBarH), w, CSS.titleBarH);
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.drawRect(0, CSS.titleBarH, w, h - CSS.titleBarH);
		g.lineStyle(1, CSS.borderColor);
		g.moveTo(stageAreaWidth, 0);
		g.lineTo(stageAreaWidth, h);
		fixLayout();
		if (app.viewedObj()) refresh(); // refresh, but not during initialization
	}

	private function fixLayout():void {
		importSpriteButton.x = w - importSpriteButton.width;
		importSpriteButton.y = 0;
		newSpriteButton.x = importSpriteButton.x - newSpriteButton.width;
		newSpriteButton.y = 0;

		spritesFrame.x = objectInfoPart.x = stageAreaWidth + 1;
		spritesFrame.y = objectInfoPart.y = CSS.titleBarH + 1;
		spritesFrame.setWidthHeight(w - spritesFrame.x, h - spritesFrame.y);

		objectInfoPart.x = stageAreaWidth + 1;
		objectInfoPart.setWidthHeight(w - spritesFrame.x, h - spritesFrame.y);
	}

	public function highlight(highlightList:Array):void {
		// Highlight each ScratchObject in the given list to show,
		// for example, broadcast senders or receivers. Passing an
		// empty list to this function clears all highlights.
		for each (var tn:SpriteThumbnail in allThumbnails()) {
			tn.showHighlight(highlightList.indexOf(tn.targetObj) >= 0);
		}
	}

	public function refresh():void {
		// Create thumbnails for all sprites. This function is called
		// after loading project, or adding or deleting a sprite.
		stageThumbnail.setTarget(app.stageObj());
		spritesPane.clear();
		var rightEdge:int = w - spritesFrame.x - 10;
		var nextX:int = 6, nextY:int = 6;
		for each (var spr:ScratchSprite in app.stageObj().sprites()) {
			var tn:SpriteThumbnail = new SpriteThumbnail(spr, app);
			tn.x = nextX;
			tn.y = nextY;
			spritesPane.addChild(tn);
			nextX += tn.width + 6;
			if ((nextX + tn.width) > rightEdge) { // start new line
				nextX = 6;
				nextY += tn.height + 6;
			}
		}
		updateViewModeButtons();
		spritesPane.updateSize();
		step();
	}

	public function step():void {
		// Update all thumbnails and scene arrow visibility.
		updateSceneArrowVisibility();
		var viewedObj:ScratchObj = app.viewedObj();
		for each (var tn:SpriteThumbnail in allThumbnails()) {
			tn.updateThumbnail();
			tn.select(tn.targetObj == viewedObj);
		}
		spritesTitle.visible = !app.stageIsContracted;
		updateViewModeButtons();
		if (objectInfoPart.visible) objectInfoPart.step();
	}

	private function updateSceneArrowVisibility():void {
		// Show the prev/next scene arrows only if there is previous or next scene.
		var stg:ScratchStage = app.stageObj();
		if (stg == null) return;
		if (stg.costumes.length < 2) {
			nextSceneButton.visible = prevSceneButton.visible = false;
		} else {
			prevSceneButton.visible = stg.currentCostumeIndex > 0;
			nextSceneButton.visible = stg.currentCostumeIndex < (stg.costumes.length - 1);
		}
	}

	private function updateViewModeButtons():void {
		var showButtons:Boolean = !app.stageIsContracted && !app.viewedObj().isStage;
		viewOne.visible = showButtons;
		if (!showButtons) {
			viewOne.turnOff();
			objectInfoPart.visible = false;
		}
	}

	private function addStageArea():void {
		stageThumbnail = new SpriteThumbnail(null, app);
		stageThumbnail.x = 2;
		stageThumbnail.y = 53;
		addChild(stageThumbnail);

		prevSceneButton = new IconButton(prevScene, drawArrowUp());
		prevSceneButton.x = 34;
		prevSceneButton.y = 42;
		addChild(prevSceneButton);

		nextSceneButton = new IconButton(nextScene, drawArrowDown());
		nextSceneButton.x = 34;
		nextSceneButton.y = 130;
		addChild(nextSceneButton);
	}

	private function addSpritesArea():void {
		spritesPane = new ScrollFrameContents();
		spritesPane.color = bgColor;
		spritesFrame = new ScrollFrame();
		spritesFrame.setContents(spritesPane);
		addChild(spritesFrame);
	}

	private function drawArrowUp():Shape {
		var arrow:Shape = new Shape();
		var g:Graphics = arrow.graphics;
		g.clear();
		g.lineStyle(0, 0, 0);
		g.beginFill(0xA6A8AC);
		g.moveTo(0,10);
		g.lineTo(18,10);
		g.lineTo(9,0);
		g.endFill();
		return arrow;
	}

	private function drawArrowDown():Shape {
		var arrow:Shape = new Shape();
		var g:Graphics = arrow.graphics;
		g.clear();
		g.lineStyle(0, 0, 0);
		g.beginFill(0xA6A8AC);
		g.moveTo(0, 0);
		g.lineTo(18, 0);
		g.lineTo(9, 10);
		g.endFill();
		return arrow;
	}

	// -----------------------------
	// Button Operations
	//------------------------------

	private function importSprite(b:IconButton):void {
		function addSprite(c:ScratchCostume):void {
			var s:ScratchSprite = new ScratchSprite(c.costumeName);
			s.setInitialCostume(c);
			addNewSprite(s);
		}
		b.turnOff();
		new MediaLibrary(app, 'costumes', addSprite).open();
	}

	private function createSprite(b:IconButton):void {
return; // xxx disabled for now (at mres request)
		var spr:ScratchSprite = new ScratchSprite();
		spr.setEmptyCostume();
		addNewSprite(spr);
	}

	private function nextScene(b:IconButton):void {
		app.stagePane.recordHiddenSprites();
		app.stagePane.showCostume(app.stagePane.currentCostumeIndex + 1);
		app.stagePane.updateSpriteVisibility();
	}

	private function prevScene(b:IconButton):void {
		app.stagePane.recordHiddenSprites();
		app.stagePane.showCostume(app.stagePane.currentCostumeIndex - 1);
		app.stagePane.updateSpriteVisibility();
	}

	private	function toggleSpriteInfo(b:IconButton):void {
		b.lastEvent.preventDefault(); 
		b.lastEvent.stopPropagation() 
		var flag:Boolean = b.isOn();
		objectInfoPart.visible = flag;
		if (flag) objectInfoPart.refresh();
	}

	// -----------------------------
	// Misc
	//------------------------------

	private function allThumbnails():Array {
		// Return a list containing all thumbnails.
		var result:Array = [stageThumbnail];
		for (var i:int = 0; i < spritesPane.numChildren; i++) {
			result.push(spritesPane.getChildAt(i));
		}
		return result;
	}

	private function addNewSprite(spr:ScratchSprite):void {
		app.stagePane.addChild(spr);
		spr.objName = spr.unusedSpriteName(spr.objName);	
		spr.setScratchXY(int(200 * Math.random() - 100), int(100 * Math.random() - 50));
		app.selectSprite(spr);
		app.setTab('images');
		refresh();
	}

}}
