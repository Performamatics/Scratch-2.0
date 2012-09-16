// TopBarPart.as
// John Maloney, November 2011
//
// This part holds the Scratch Logo, cursor tools, and undo button.

package ui.parts {
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextField;
	import assets.Resources;
	import uiwidgets.*;
	import util.Color;

public class TopBarPart extends UIPart {

	private var shape:Shape;
	private var logo:Sprite;

	private var copyTool:IconButton;
	private var cutTool:IconButton;
	private var growTool:IconButton;
	private var shrinkTool:IconButton;
	private var helpTool:IconButton;

	private var newButton:IconButton;
	private var saveButton:IconButton;
	private var remixButton:IconButton;
	private var moreButton:IconButton;
	private var loginButton:IconButton;

	private var projectPageButton:IconButton;

	public function TopBarPart(app:Scratch) {
		this.app = app;
		shape = new Shape();
		addChild(shape);
		addLogo();
		addToolButtons();
		addMenuButtons();
		addProjectButton();
	}

	private function addLogo():void {
		function logoClicked(evt:MouseEvent):void { app.jsRedirectTo('home') }
		logo = new Sprite();
		logo.addChild(Resources.createBmp('scratchlogo'));
		logo.addEventListener(MouseEvent.MOUSE_DOWN, logoClicked);
		addChild(logo);
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();
		g.beginFill(CSS.topBarColor);
		g.drawRect(0, 0, w, h);
		g.endFill();
		fixLayout();
	}

	private function fixLayout():void {
		logo.x = 0;
		logo.y = 0;

		copyTool.x = 420;
		cutTool.x = copyTool.right() + 6;
		growTool.x = cutTool.right() + 6;
		shrinkTool.x = growTool.right() + 6;
		helpTool.x = shrinkTool.right() + 6;
		copyTool.y = cutTool.y = shrinkTool.y = growTool.y = helpTool.y = 0;

		// new/save/remix buttons
		var buttonSpace:int = 12;
		var buttonY:int = 2;
		var nextX:int = logo.x + logo.width + 12;
		newButton.x = nextX;
		newButton.y = buttonY;
		nextX += newButton.width + buttonSpace;
		if (saveButton.visible) {
			saveButton.x = nextX;
			saveButton.y = buttonY;
			nextX += saveButton.width + buttonSpace;
		}
		if (remixButton.visible) {
			remixButton.x = nextX;
			remixButton.y = buttonY;
			nextX += remixButton.width + buttonSpace;
		}
		moreButton.x = nextX;
		moreButton.y = buttonY;

		loginButton.x = w - loginButton.width - 8;
		loginButton.y = buttonY;

		projectPageButton.x = w - projectPageButton.width - 2;
		projectPageButton.y = 26;
	}

	public function refresh():void {
		projectPageButton.visible = (app.projectID != '');
		setUserName(app.isLoggedIn() ? app.userName : 'login');
		if (app.isLoggedIn()) {
			remixButton.visible = (app.projectOwner != app.userName);
		} else {
			remixButton.visible = (app.projectID != '');
		}
		saveButton.visible = !remixButton.visible;
		fixLayout();
	}

	private function addToolButtons():void {
		function selectTool(b:IconButton):void { /* to be implemented */ }
		addChild(copyTool = makeToolButton('copyTool', selectTool));
		addChild(cutTool = makeToolButton('cutTool', selectTool));
		addChild(growTool = makeToolButton('growTool', selectTool));
		addChild(shrinkTool = makeToolButton('shrinkTool', selectTool));
		addChild(helpTool = makeToolButton('helpTool', selectTool));
	}

	private function makeToolButton(str:String, fcn:Function):IconButton {
		var w:int = 24;
		var h:int = 24;
		var offImage:Bitmap = Resources.createBmp(str);
		var onImage:Sprite = new Sprite();
		var g:Graphics = onImage.graphics;
		g.clear();
		g.beginFill(CSS.overColor);
		g.drawRoundRect(0, 0, w, h, 8, 8);
		g.endFill();
		onImage.addChild(Resources.createBmp(str));
//		return new IconButton(fcn, onImage, offImage, true);
		return new IconButton(fcn, offImage, offImage, true); // xxx disable visible state change for alpha
	}

	private function addProjectButton():void {
		projectPageButton = new IconButton(app.returnToProjectPage, makeFlipButtonImg(true), makeFlipButtonImg(false));
		projectPageButton.isMomentary = true;
		addChild(projectPageButton);
	}

	private function makeFlipButtonImg(isOn:Boolean):Sprite {
		var result:Sprite = new Sprite();

		var label:TextField = makeLabel('See outside', CSS.topBarButtonFormat, 2, 1);
		label.textColor = CSS.white;
		result.addChild(label); // label disabled for now

		var w:int = label.textWidth + 44;
		var h:int = 22;
		var g:Graphics = result.graphics;
		g.clear();
		g.beginFill(CSS.overColor);
		g.drawRoundRect(0, 0, w, h, 8, 8);
		g.endFill();

		var icon:Bitmap = Resources.createBmp('projectPageFlip');
		icon.x = 5;
		icon.y = -1;
		result.addChild(icon);

		label.x = icon.x + icon.width + 1;

		return result;
	}

	private function addMenuButtons():void {
		addChild(newButton = makeMenuButton('New', app.newButtonPressed));
		addChild(saveButton = makeMenuButton('Save', app.saveButtonPressed));
		addChild(remixButton = makeMenuButton('Remix', app.remixButtonPressed));
		addChild(moreButton = makeMenuButton('More', app.moreButtonPressed, true));
		addChild(loginButton = makeMenuButton('login', app.loginPressed, true));
	}

	private function makeMenuButton(s:String, fcn:Function, hasArrow:Boolean = false):IconButton {
		var onImg:Sprite = makeButtonLabel(s, true, hasArrow);
		var offImg:Sprite = makeButtonLabel(s, false, hasArrow);
		var btn:IconButton = new IconButton(fcn, onImg, offImg);
		btn.isMomentary = true;
		return btn;
	}

	private function makeButtonLabel(s:String, isOn:Boolean, hasArrow:Boolean):Sprite {
		var img:Sprite = new Sprite();

		var labelColor:int = isOn ? CSS.buttonLabelOverColor : CSS.white;
		var label:TextField = makeLabel(s, CSS.topBarButtonFormat);
		label.textColor = labelColor;
		img.addChild(label);

		if (hasArrow) img.addChild(menuArrow(label.textWidth + 6, 6, labelColor));
		return img;
	}

	private function setUserName(s:String):void {
		var onImg:Sprite = makeButtonLabel(s, true, true);
		var offImg:Sprite = makeButtonLabel(s, false, true);
		loginButton.setImage(onImg, offImg);
	}

	private function menuArrow(x:int, y:int, c:int):Shape {
		var arrow:Shape = new Shape();
		var g:Graphics = arrow.graphics;
		g.beginFill(c);
		g.lineTo(8, 0);
		g.lineTo(4, 6)
		g.lineTo(0, 0);
		g.endFill();
		arrow.x = x;
		arrow.y = y;
		return arrow;
	}

	public function styleMenu():void {
		Menu.font = 'Lucida Grande';
		Menu.color = CSS.topBarColor;
		var isDark:Boolean = false;
		Menu.divisionColor = Color.scaleBrightness(Menu.color ,isDark ? 0.52 : 0.80);
		Menu.selectedColor = Color.scaleBrightness(Color.scaleSaturation(Menu.color, 0.75), isDark ? 1.6 : 1.1);
		Menu.fontSize = 13;
		Menu.fontNormalColor = 0xFFFFFF;
		Menu.fontSelectedColor = Color.scaleBrightness(Menu.color , 0.62);
		Menu.minHeight = 32;
		Menu.margin = 12;
		Menu.hasShadow = true;
	}

}}
