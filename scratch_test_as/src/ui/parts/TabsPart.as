// TabsPart.as
// John Maloney, November 2011
//
// This part holds the tab buttons to view scripts, costumes/scenes, or sounds.

package ui.parts {
	import flash.display.*;
	import flash.text.*;
	import ui.DrawPath;
	import uiwidgets.IconButton;
	
public class TabsPart extends UIPart {

	private const arrowNormalColor:int = 0xA6A8AC;
	private const arrowOverColor:int = 0x4C4D4F;

	private var scriptsTab:IconButton;
	private var imagesTab:IconButton;
	private var soundsTab:IconButton;
	private var expandContract:IconButton;

	public function TabsPart(app:Scratch) {
		function selectScripts(b:IconButton):void { app.setTab('scripts') }
		function selectImages(b:IconButton):void { app.setTab('images') }
		function selectSounds(b:IconButton):void { app.setTab('sounds') }
		function contractOrExpand(b:IconButton):void { app.toggleStageContract() }

		this.app = app;
		scriptsTab = makeTab('Scripts', selectScripts);
		imagesTab = makeTab('Images', selectImages); // changed to 'Costumes' or 'Scenes' by refresh()
		soundsTab = makeTab('Sounds', selectSounds);
		expandContract = new IconButton(contractOrExpand, makeFlapImg(app.stageIsContracted, true), makeFlapImg(app.stageIsContracted, false));
		expandContract.isMomentary = true;
		addChild(scriptsTab);
		addChild(imagesTab);
		addChild(soundsTab);
		addChild(expandContract);
		scriptsTab.turnOn();
	}

	public function refresh():void {
		var label:String = ((app.viewedObj() != null) && app.viewedObj().isStage) ? 'Scenes' : 'Costumes';
		imagesTab.setImage(makeTabImg(label, true), makeTabImg(label, false));
		expandContract.setImage(makeFlapImg(app.stageIsContracted, true), makeFlapImg(app.stageIsContracted, false));
		fixLayout();
	}

	public function selectTab(tabName:String):void {
		scriptsTab.turnOff();
		imagesTab.turnOff();
		soundsTab.turnOff();
		if (tabName == 'scripts') scriptsTab.turnOn();
		if (tabName == 'images') imagesTab.turnOn();
		if (tabName == 'sounds') soundsTab.turnOn();
	}

	public function fixLayout():void {
		scriptsTab.x = 0;
		scriptsTab.y = 0;
		imagesTab.x = scriptsTab.x + scriptsTab.width + 1;
		imagesTab.y = 0;
		soundsTab.x = imagesTab.x + imagesTab.width + 1;
		soundsTab.y = 0;
		expandContract.y = 60;
		expandContract.x = -7;
		this.w = soundsTab.x + soundsTab.width;
		this.h = scriptsTab.height;
	}

	private function makeTab(label:String, action:Function):IconButton {
		var tab:IconButton = new IconButton(action, makeTabImg(label, true), makeTabImg(label, false), true);
		return tab;
	}

	private function makeTabImg(label:String, isSelected:Boolean):Sprite {
		var img:Sprite = new Sprite();
		var tf:TextField = new TextField();
		tf.defaultTextFormat = new TextFormat('Lucida Grande', 12, isSelected ? CSS.onColor : CSS.offColor, false);
		tf.text = label;
		tf.width = tf.textWidth + 5;
		tf.height = tf.textHeight + 5;
		tf.x = 10;
		tf.y = 2;
		img.addChild(tf);

		var g:Graphics = img.graphics;
		var w:int = tf.width + 20;
		var h:int = 22;
		var r:int = 9;
		if (isSelected) drawTopBar(g, CSS.titleBarColors, getTopBarPath(w, h), w, h);
		else drawSelected(g, [0xf2f2f2, 0xd1d2d3], getTopBarPath(w, h), w, h);
		return img;
	}

	private function makeFlapImg(pointRight:Boolean, isOver:Boolean):Shape {
		var img:Shape = new Shape();
	 	var g:Graphics = img.graphics;
	 	var curve:int = 8;
		var h:int = 17 + curve * 2;
		var path:Array = [["M", 8, 0], ["c", -curve, 0, -curve, curve], ["v", 17], ["c", 0, curve, curve, curve]];
		g.clear();
		g.lineStyle(0.5, CSS.borderColor, 1, true);
//		drawBoxBkgGradientShape(g, 0, CSS.titleBarColors, [0x00, 0xFF], path, w, h);
g.beginFill(0xF0F0F0); // xxx experiment
		DrawPath.drawPath(path, g, 0, 0, 0);
		var arrowColor:int = isOver ? arrowOverColor : arrowNormalColor;
		if (pointRight) drawArrowRight(g, arrowColor, 3, (h / 2) - 3);
		else drawArrowLeft(g, arrowColor, 3, (h / 2) - 3);
		return img;
	}

	private function drawArrowLeft(g:Graphics, c:int, x:int, y:int):void {
		g.lineStyle(0, 0, 0);
		g.beginFill(c);
		g.moveTo(x + 6, y);
		g.lineTo(x + 6, y + 8);
		g.lineTo(x, y + 4);
		g.endFill();
	}

	private function drawArrowRight(g:Graphics, c:int, x:int, y:int):void {
		g.lineStyle(0, 0, 0);
		g.beginFill(c);
		g.moveTo(x, y);
		g.lineTo(x, y + 8);
		g.lineTo(x + 6, y + 4);
		g.endFill();
	}

}}
