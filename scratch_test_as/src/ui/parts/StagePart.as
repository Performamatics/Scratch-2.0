// StagePart.as
// John Maloney, November 2011
//
// This part frames the Scratch stage and supplies the UI elements around it.
// Note: The Scratch stage is a child of StagePart but is stored in an app instance variable (app.stagePane)
// since it is referred from many places.

package ui.parts {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Point;
	import flash.text.*;
	import assets.Resources;
	import scratch.*;
	import uiwidgets.*;
	import util.Server;

public class StagePart extends UIPart {

	public const topBarHeightNormal:int = 39;
	public const topBarHeightEmbedMode:int = 26;

	private const fontName:String = CSS.normalTextFormat.font;
	private const readoutLabelFormat:TextFormat = new TextFormat(fontName, 12, CSS.textColor, true);
	private const readoutFormat:TextFormat = new TextFormat(fontName, 10, CSS.textColor);
	private const saveStatusNormalFormat:TextFormat = new TextFormat(fontName, 10, CSS.textColor);
	private const saveStatusAlertFormat:TextFormat = new TextFormat(fontName, 10, CSS.alertColor, true);

	public var topBarHeight:int = topBarHeightNormal;

	private var outline:Shape;
	private var projectTitle:EditableLabel;
	private var projectInfo:TextField;
	private var runButton:IconButton;
	private var stopButton:IconButton;
	private var fullscreenButton:IconButton;

	private var playButton:Sprite; // YouTube-like play button in center of screen; used by Kiosk version
	private var runButtonOnTicks:int;

	// x-y readouts
	private var readouts:Sprite; // readouts that appear below the stage
	private var xLabel:TextField;
	private var xReadout:TextField;
	private var yLabel:TextField;
	private var yReadout:TextField;
	private var saveStatus:TextField;

	public function StagePart(app:Scratch) {
		this.app = app;
		outline = new Shape();
		addChild(outline);
		addTitleAndInfo();
		addRunStopButtons();
		addFullScreenButton();
		addXYReadoutsAndSaveStatus();
		fixLayout();
	}

	public function setWidthHeight(w:int, h:int, scale:Number):void {
		this.w = w;
		this.h = h;
		if (app.stagePane) app.stagePane.scaleX = app.stagePane.scaleY = scale;
		topBarHeight = app.embedMode ? topBarHeightEmbedMode : topBarHeightNormal;
		drawOutline();
		fixLayout();
	}

	public function installStage(newStage:ScratchStage):void {
		var scale:Number = app.stageIsContracted ? 0.5 : 1;
		if ((app.stagePane != null) && (app.stagePane.parent != null)) {
			scale = app.stagePane.scaleX;
			app.stagePane.parent.removeChild(app.stagePane); // remove old stage
		}
		newStage.x = 1;
		newStage.y = topBarHeight;
		newStage.scaleX = newStage.scaleY = scale;
		addChild(newStage);
		app.stagePane = newStage;
	}

	public function projectName():String { return projectTitle.contents() }
	public function setProjectName(s:String):void { projectTitle.setContents(s) }

	public function refresh():void {
		readouts.visible = app.editMode;
		projectTitle.visible = app.editMode;
		projectInfo.visible = app.editMode;
		fullscreenButton.visible = !app.editMode && !app.embedMode;
		if (app.editMode) fullscreenButton.setOn(false);
		updateProjectInfo();
	}

	// -----------------------------
	// Save status
	//------------------------------

	public function setSaveStatus(s:String, alert:Boolean):void {
		saveStatus.text = s;
		saveStatus.setTextFormat(alert ? saveStatusAlertFormat : saveStatusNormalFormat);
	}
	
	// -----------------------------
	// Layout
	//------------------------------

	private const black:int = 0;

	private function drawOutline():void {
		var g:Graphics = outline.graphics;
		g.clear();
		var topBarColors:Array = fullscreenButton.isOn() ? [black, black] : CSS.titleBarColors;
		if (app.embedMode) topBarColors = [CSS.tabColor, CSS.tabColor];
		var borderColor:int =  fullscreenButton.isOn() ? black : CSS.borderColor;
		drawTopBar(g, topBarColors, getTopBarPath(w - 1, topBarHeight), w, topBarHeight, borderColor);
		g.lineStyle(1, borderColor, 1, true);
		g.drawRect(0, topBarHeight, w - 1, h - topBarHeight - 1);
	}

	private function fixLayout():void {
		if (app.stagePane) app.stagePane.y = topBarHeight;

		projectTitle.x = 4;
		projectTitle.y = 1;
		projectInfo.x = projectTitle.x + 3;
		projectInfo.y = projectTitle.y + 20;

		runButton.x = w - 60;
		runButton.y = int((topBarHeight - runButton.height) / 2);
		stopButton.x = runButton.x + 32;
		stopButton.y = runButton.y + 1;

		fullscreenButton.x = 10;
		fullscreenButton.y = stopButton.y;

		projectTitle.setWidth(runButton.x - 15);

		// x-y readouts
		var left:int = w - 95;
		xLabel.x = left;
		xReadout.x = left + 16;
		yLabel.x = left + 50;
		yReadout.x = left + 66;

		var top:int = h + 1;
		xReadout.y = yReadout.y = top;
		xLabel.y = yLabel.y = top - 2;

		saveStatus.x = 0;
		saveStatus.y = top;
	}

	private function addTitleAndInfo():void {
		function titleChanged(evt:Event):void { app.jsEditTitle() }
		projectTitle = new EditableLabel(titleChanged, CSS.projectTitleFormat);
		projectTitle.useDynamicBezel(true);
		addChild(projectTitle);

		projectInfo = makeLabel('', CSS.projectInfoFormat);
		addChild(projectInfo);
	}

	private function addXYReadoutsAndSaveStatus():void {
		readouts = new Sprite();
		addChild(readouts);

		xLabel = makeLabel('x:', readoutLabelFormat);
		readouts.addChild(xLabel);
		xReadout = makeLabel('-888', readoutFormat);
		readouts.addChild(xReadout);

		yLabel = makeLabel('y:', readoutLabelFormat);
		readouts.addChild(yLabel);
		yReadout = makeLabel('-888', readoutFormat);
		readouts.addChild(yReadout);

		saveStatus = makeLabel('', saveStatusNormalFormat);
		readouts.addChild(saveStatus);
	}

	private function updateProjectInfo():void {
		projectTitle.setEditable(false);
		if (app.projectOwner == '') {
			projectInfo.text = '';
		} else {
			if (app.userName == app.projectOwner) {
				projectInfo.text = 'by ' + app.projectOwner + (app.projectIsPrivate ? ' (private)' : ' (shared)');
				projectTitle.setEditable(true);
			} else {
				projectInfo.text = 'by ' + app.projectOwner;
			}
		}
	}

	// -----------------------------
	// Stepping
	//------------------------------

	public function step():void {
		updateRunStopButtons();
		if (app.editMode) updateMouseReadout();
	}

	private function updateRunStopButtons():void {
		// Update the run/stop buttons.
		// Note: To ensure that the user sees at least a flash of the
		// on button, it stays on a minumum of two display cycles.
		if (app.interp.threadCount() > 0) threadStarted();
		else { // nothing running
			if (runButtonOnTicks > 2) {
				runButton.turnOff();
				stopButton.turnOn();
			}
		}
		runButtonOnTicks++;
	}

	private var lastX:int, lastY:int;

	private function updateMouseReadout():void {
		// Update the mouse reaadouts. Do nothing if they are up-to-date (to minimize CPU load).
		if (stage.mouseX != lastX) {
			lastX = app.stagePane.scratchMouseX();
			xReadout.text = String(lastX);
		}
		if (stage.mouseY != lastY) {
			lastY = app.stagePane.scratchMouseY();
			yReadout.text = String(lastY);
		}
	}

	// -----------------------------
	// Run/Stop/Fullscreen Buttons
	//------------------------------

	public function threadStarted():void {
		runButtonOnTicks = 0;
		runButton.turnOn();
		stopButton.turnOff();
	}

	private function addRunStopButtons():void {
		function startAll(b:IconButton):void {
			hidePlayButton();
			app.runtime.startGreenFlags();
		}
		function stopAll(b:IconButton):void { app.runtime.stopAll() }
		runButton = new IconButton(startAll, 'greenflag');
		runButton.actOnMouseUp();
		addChild(runButton);
		stopButton = new IconButton(stopAll, 'stop');
		addChild(stopButton);
	}

	private function addFullScreenButton():void {
		function toggleFullscreen(b:IconButton):void {
			app.jsSetPresentationMode(b.isOn());
			drawOutline();
			app.playerBG.visible = b.isOn();
		}
		fullscreenButton = new IconButton(toggleFullscreen, 'fullscreen');
		addChild(fullscreenButton);
	}

	// -----------------------------
	// Play Button
	//------------------------------

	private function showPlayButton():void {
		// The play button is a YouTube-like button the covers the entire stage.
		// Used by the player to ensure that the user clicks on the SWF to start
		// the project, which ensurs that the SWF gets keyboard focus.
		function playButtonPressed(e:Event):void {
			hidePlayButton();
			app.runtime.startGreenFlags();
		}
		if (!playButton) {
			playButton = new Sprite();
			playButton.addChild(Resources.createBmp('playerStartScreen'));
			playButton.alpha = 0.7;
			playButton.addEventListener(MouseEvent.MOUSE_DOWN, playButtonPressed);
		}
		fixPlayButtonLayout();
		addChild(playButton);
	}

	private function hidePlayButton():void {
		if ((playButton) && (playButton.parent != null)) playButton.parent.removeChild(playButton);
		playButton = null;
	}

	private function fixPlayButtonLayout():void {
		if (playButton) {
			playButton.scaleX = playButton.scaleY = app.stagePane.scaleX;
			var p:Point = app.stagePane.localToGlobal(new Point(0, 0));
			playButton.x = p.x;
			playButton.y = p.y;
		}
	}

}}
