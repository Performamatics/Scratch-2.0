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
/*
	Outer shell that connects to the costume tab part.
	Here you'll need to set the data for the costume of the object.
*/

package ui.paintui {
	import flash.display.*;
	import flash.geom.*;
	import flash.events.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
	import assets.Resources;
	import scratch.*;
	import ui.parts.ImagesPart;
	import uiwidgets.*;
	import util.*;
	import webcamui.*;

public class PaintEdit extends Sprite {

	public var paintarea:PaintCanvas;
	public var colorPalette:ColorPalette;

	private const palettesize:int = 164;
	private const toolist:Array = [
	"select","space", "rect", "ellipse", "path","text",
	"space","clone", "eyedropper", "front", "back"];
	private const bmptoolist:Array = [
	'paintbucket', 'wand' , 'lasso','eraser', "slice"];

	private var costumename:EditableLabel;
	private var uploadFromLocal:IconButton;
	private var importFromLibrary:IconButton;
	private var takePhoto:IconButton;
	private var app:Scratch;
	private var w:int;
	private var h:int;
	private var selectedElement:String;
	private var tools:Sprite;
	private var bmptools:Sprite;
	private var allTools:Array = [];
	private var canvasBackdrop:Shape;
	private var canvasFrame:ScrollFrame;
	private var strengthPanel:Sprite;
	private var modifiers:Sprite;
	private var cwidth:EditableLabel;
	private var cheight:EditableLabel;
	private var zoomIcons:Sprite;

	private var costume:ScratchCostume;

	public function PaintEdit(app:*) {
		this.app = app;
		PaintVars.appStage = app.stage;
		createTools();
		costumename = new EditableLabel(nameChanged);
		addChild(costumename);

		importFromLibrary = new IconButton(openImportCostume, makeButtonImg('library', true), makeButtonImg('library', false));
		addChild(importFromLibrary);
		uploadFromLocal = new IconButton(uploadCostume, makeButtonImg('upload', true), makeButtonImg('upload', false));
		addChild(uploadFromLocal);
		takePhoto = new IconButton(openCamera, makeButtonImg('camera', true), makeButtonImg('camera', false));
		addChild(takePhoto);
		colorPalette = new ColorPalette(this);

		createBottomTools();
		paintarea = new PaintCanvas(this);
		canvasFrame = new ScrollFrame();
		canvasFrame.setContents(paintarea);

		addChild(canvasFrame);
		setCanvasSize(200, 200); // should take the costume size
		activateSVG();
		selectButton("select");

		// the listener is here to get the "outside" canvas call
		// you may want to put this in a different place
		canvasFrame.addEventListener(MouseEvent.MOUSE_DOWN, PaintVars.svgroot.paintMouseDown);
	}

	public function editCostume(c:ScratchCostume):void {
		this.costume = c;
		costumename.setContents(c.costumeName);
		try { c.width() } catch (e:Error) { return } // not yet loaded
		setCanvasSize(c.width() + 20, c.height() + 20);
		centerWorkingCanvas();
		if (c.baseLayerSVG) {
			insertSVG(c.costumeName, c.baseLayerData);
		} else {
			insertImage(c.costumeName, c.baseLayerBitmap.clone());
			// ToDo: add text layer...
		}
	}

	////////////////////////////////////////////////////////////////////
	// Editor Setup
	/////////////////////////////////////////////////////////////////////
	private function createBottomTools():void {
		createCanvasWidthAndHeightFields();
		createCanvasZoomIcons();
		setUpTolerance();
	}

	private function createCanvasWidthAndHeightFields():void {
		modifiers = new Sprite();
		addChild(modifiers);
		cwidth = addTextField(0, modifiers, "Width", widthChanged);
		cheight = addTextField(modifiers.width + 5, modifiers, "Height", heightChanged);
	}

	private function createCanvasZoomIcons():void {
		zoomIcons = new Sprite();
		addChild(zoomIcons);
		var list:Array = [ [doZoomOut, 'zoomOut'],[doNoZoom, 'noZoom'],[doZoomIn, 'zoomIn'] ];
		var dx:Number =0;
		for (var i:int=0; i< list.length; i++){
			var str:String = list[i][1];
			var ib:IconButton = new IconButton(list[i][0], Resources.createBmp(str+"On"), Resources.createBmp(str+"Off") );
			ib.x = dx;
			dx += ib.width;
			zoomIcons.addChild(ib);
		}
	}

	private function addTextField(dx:Number, p:Sprite, label:String, fcn:Function):EditableLabel {
		var icon:Bitmap = Resources.createBmp(label+"Icon");
		icon.x = dx;
		p.addChild(icon);

		var fmt:TextFormat = CSS.paintWidthHeightFormat;
		fmt.align = TextFormatAlign.CENTER;
		var el:EditableLabel = new EditableLabel(fcn, fmt);
		el.x = dx + icon.width;
		el.setWidth(40);
		el.tf.restrict = "0-9";
		el.tf.maxChars = 4;
		el.tf.addEventListener("focusOut", handleFocusOut);
		p.addChild(el);
		return el;
	}

	private function createTools():void {
		var ib:IconButton, i:int;
		var dy:Number = 0;
		tools = new Sprite();
		addChild(tools);
		tools.y = 27;
		for (i = 0; i< toolist.length; i++){
			if (toolist[i] == "space") dy += 8;
			else {
			ib = new IconButton(selectTool, makeToolButton(toolist[i], true), makeToolButton(toolist[i], false), true);
			ib.name = toolist[i];
				tools.addChild(ib);
				allTools.push(ib);
				if (i == 0) ib.turnOn();
				ib.name = toolist[i];
				ib.y = dy;
				dy += ib.height - 1;
			}
		}
		bmptools = new Sprite();
		addChild(bmptools);

		dy = bmptoolist.length * (ib.height - 1);
		for (i = 0; i< bmptoolist.length; i++){
			ib = new IconButton(selectTool, makeToolButton(bmptoolist[i], true), makeToolButton(bmptoolist[i], false), true);
			ib.name = bmptoolist[i];
			bmptools.addChild(ib);
			allTools.push(ib);
			if (i == 0) ib.turnOn();
			ib.name = bmptoolist[i];
			ib.y = dy;
			dy -= ib.height + 1;
		}
	}

	///////////////////////////////////////////////////////////////////
	// Tools selection call back and other calls
	//////////////////////////////////////////////////////////////////

	private function selectTool(b:IconButton):void {
		if (b.alpha !=1) return;
		var instanttools:Array = [ "clone", "eyedropper", "front", "back"];
		var bmptools:Array = [ 'paintbucket','eraser', 'lasso', 'wand', "slice"];
		//	if ((PaintVars.paintMode == "eraser") && (b.name != "eraser")) noEraserSettings();
		if ((PaintVars.paintMode == "select") && (b.name != "path")) {
			PaintVars.fillAttributes.alpha = 1;
			colorPalette.updateSettings();
		}
		PaintVars.paintMode= b.name;
		selectButton(b.name);
		settingsForTool(b.name);
		if (PaintVars.pathSelector) quitPathEditMode();
		if ((instanttools.concat(bmptools)).indexOf(b.name) < 0 ) hideSelection();
		if ((b.name == "path") && (PaintVars.strokeAttributes.basecolor == "none")) colorPalette.setStrokeSize(null, 2);
		if ((b.name != "eyedropper") && (instanttools.indexOf(b.name) > -1)) PaintVars.svgroot.runInstantTool(null, b.name);
	}

	public function selectButton(str:String):void {
		var i:int, ib:IconButton, myalpha:Number;
		PaintVars.paintMode = str;
		for (i = 0; i< tools.numChildren; i++){
			ib = tools.getChildAt(i) as IconButton;
			if (ib == null) continue;
			myalpha = ib.alpha;
			ib.alpha = 1;
			if (ib.name == str) ib.turnOn();
			else ib.turnOff();
			ib.alpha = myalpha;
		}
		for (i = 0; i< bmptools.numChildren; i++){
			ib = bmptools.getChildAt(i) as IconButton;
			if (ib == null) continue;
			myalpha = ib.alpha;
			ib.alpha = 1;
			if (ib.name == str) ib.turnOn();
			else ib.turnOff();
			ib.alpha = myalpha;
		}
	}

	public function settingsForTool (str:String):void {
		switch(str) {
		case "select":
			strengthPanel.visible=false;
			if (PaintVars.antsAlive()) PaintVars.clearMarchingAnts();
			hideSelection();
			colorPalette.updateSettings();
			activateSVG();
			break;
		case 'paintbucket':
			colorPalette.changeToFill(null);
			if (! PaintVars.antsAlive()) hideSelection();
			activateSVG();
			strengthPanel.visible=true;
			break;
		case 'eraser': if (PaintVars.antsAlive()) PaintVars.clearMarchingAnts(); eraserSettings(); strengthPanel.visible=false; break;
		case 'lasso': if (PaintVars.antsAlive()) PaintVars.clearMarchingAnts(); strengthPanel.visible=false; break;
		case 'wand': if (PaintVars.antsAlive()) PaintVars.clearMarchingAnts(); strengthPanel.visible=true; break;
		case 'slice': if (PaintVars.antsAlive()) PaintVars.clearMarchingAnts(); strengthPanel.visible=false; break;
		case 'select':
		case 'path':
		case 'ellipse':
		case 'rect':
			if (PaintVars.antsAlive()) PaintVars.clearMarchingAnts();
			strengthPanel.visible=false;
			break;
		case "text":
			colorPalette.changeToText(null);
			if (PaintVars.antsAlive()) PaintVars.clearMarchingAnts();
			strengthPanel.visible=false;
			break;
		default:
			break;
		}
	}

	private function eraserSettings():void {
		colorPalette.changeToBorder(null);
		PaintVars.penAtt = "stroke";
		colorPalette.setStrokeSize(null, 3);
		colorPalette.updateSettings();
	}

	private function hideSelectorGroup():void { PaintVars.svgroot.selectorGroup.hideSelectorGroup() }
	private function hideSelection():void { PaintVars.svgroot.selectorGroup.hideSelection() }
	private function quitPathEditMode():void { PaintVars.svgroot.selectorGroup.quitPathEditMode() }

	public function activateBitmap():void {
		var list:Array = [
			'select', "clone", "eyedropper", "front", "back", "space",
			'eraser', 'lasso', 'paintbucket', 'wand'];
		if (!PaintVars.backgroundIsSelected()) list.push ("slice");
		fadeOrBrighten(list);
		strengthPanel.visible = false;
	}

	public function activateSVG():void {
		var list:Array = [
			'select', 'path', 'ellipse', "rect", "text", "space",
			"clone", "eyedropper", "front", "back", 'paintbucket'];
		fadeOrBrighten(list);
		strengthPanel.visible = false;
	}

	private function fadeOrBrighten(list:Array):void {
		for each (var ib:IconButton in allTools) {
			ib.setDisabled(list.indexOf(ib.name) < 0);
		}
	}

	// -----------------------------
	// Camera
	//------------------------------

	private static var photoNumber:int = 1;

	private function openCamera(b:IconButton):void {
		function turnOff():void { importFromLibrary.turnOff() }
		function savePhoto(photo:BitmapData):void {
			insertImage('photo' + photoNumber++, photo);
		}
		showPanel(new WebCamPane(savePhoto));
		setTimeout(turnOff, 50);
	}

	private function showPanel(panel:DialogBox):void {
		panel.fixLayout();
		var dx:int = (app.stage.stageWidth - panel.width) / 2;
		var dy:int = (app.stage.stageHeight - panel.height) / 2;
		panel.x = dx;
		panel.y = dy;
		app.addChild(panel);
	}

	///////////////////////////////////////////////
	// Library
	///////////////////////////////////////////////

	private function openImportCostume(b:IconButton):void {
		function turnOff():void { importFromLibrary.turnOff() }
		// call here
		setTimeout(turnOff, 50);
	}

	private function uploadCostume(b:IconButton):void {
		function turnOff():void { uploadFromLocal.turnOff() }
		importMediaFromDisk();
		setTimeout(turnOff, 50);
	}

	////////////////////////////////////////////////////
	// Call backs from text fields
	//////////////////////////////////////////////////////

	private function nameChanged(evt:Event):void {
		if (!costume) return;
		costume.costumeName = costumename.contents();
		(parent as ImagesPart).refresh();
	}

	private function widthChanged(evt:Event):void {
		paintarea.setCanvasSize(Math.max(20,int(cwidth.contents())),paintarea.h);
		centerWorkingCanvas();
	}

	private function heightChanged(evt:Event):void {
		paintarea.setCanvasSize(paintarea.w, Math.max(20,int(cheight.contents())));
		centerWorkingCanvas();
	}

	private function handleFocusOut(evt:Event):void {
		setCanvasSize(Math.max(20,int(cwidth.contents())), Math.max(20,int(cheight.contents())));
	}

	public function getCanvasWidthAndHeight():Object { return {width: paintarea.w, height: paintarea.h} }

	//////////////////////////////////////////////////////
	// layout function for resizing etc.
	///////////////////////////////////////////////////////

	public function setCanvasSize(w:int, h:int):void {
		paintarea.setCanvasSize(Math.max(20, w), Math.max(h, 20));
		cwidth.setContents(w.toString());
		cheight.setContents(h.toString());
		centerWorkingCanvas();
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		// costume name
		var ww:int = w - 26*3 - 4;
		costumename.y = 2;
		costumename.setWidth(ww);
		// buttons for camera, upload and library
		importFromLibrary.x = w - 24;
		uploadFromLocal.x = w - 26 - 24;
		takePhoto.x = w - 26 - 24 - 26;
		// calculate remaining space for the backdrop
		var indent:int = 4;
		var dw:Number = w - tools.width - indent;
		var dh:Number = h - (costumename.y + costumename.height) - indent * 3 - palettesize - modifiers.height;
		canvasFrame.x = tools.width + indent;
		canvasFrame.y = costumename.y + costumename.height + indent ;
		modifiers.x = canvasFrame.x + (dw - modifiers.width) / 2; // canvasFrame.x;
		modifiers.y = canvasFrame.y + dh + indent;
		zoomIcons.x = w - zoomIcons.width - indent;
		zoomIcons.y =modifiers.y - 2;
		drawBackdrop(canvasFrame.graphics, dw, dh);
		canvasFrame.setWidthHeight( dw, dh);
		strengthPanel.x = canvasFrame.x;
		strengthPanel.y = modifiers.y - 10;
		bmptools.y = strengthPanel.y - bmptools.height + 12;
		if (bmptools.y < (tools.y + tools.height)) bmptools.y = tools.y + tools.height + 2;
		// calculate canvas position
		centerWorkingCanvas();
		colorPalette.setWidthHeight(w - canvasFrame.x + indent*2, palettesize);
		colorPalette.x = canvasFrame.x;
		colorPalette.y = h - palettesize;
	}

	public function setName(str:String):void { costumename.setContents(str) }

	public function centerWorkingCanvas():void {
		paintarea.x = Math.max(0, (canvasFrame.visibleW() - paintarea.w*PaintVars.currentZoom) / 2);
		paintarea.y = Math.max(0, (canvasFrame.visibleH() - paintarea.h*PaintVars.currentZoom) / 2);
	}

	//////////////////////////////////////////
	// tolerance
	/////////////////////////////////////////

	private function setUpTolerance():void {
		strengthPanel = new Sprite();
		addChild(strengthPanel);
		strengthPanel.visible = false;
		var tf:TextField = Resources.makeLabel("Strength", CSS.thumbnailFormat);
		tf.y = 4;
		strengthPanel.addChild(tf);
		drawToleranceValue();
		strengthPanel.addEventListener(MouseEvent.MOUSE_DOWN, selectToleranceValue);
	}

	private function selectToleranceValue(e:MouseEvent):void {
		e.preventDefault();
		var dx:Number = e.localX - 36;
		var pos:int = Math.floor (dx / 9);
		if (pos < 0) pos =0;
		if (pos > PaintVars.tolerancelist.length - 1) pos = PaintVars.tolerancelist.length - 1;
		PaintVars.tolerance = PaintVars.tolerancelist[pos];
		drawToleranceValue();
		if (PaintVars.antsAlive() && (PaintVars.paintMode=="wand")) PaintVars.svgroot.recalculateSelection();
	}

	private function drawToleranceValue():void {
		var g:Graphics = strengthPanel.graphics;
		g.beginFill(CSS.panelColor);
		g.drawRect(36, 0, (PaintVars.tolerancelist.length + 1) * 9, 26);
		g.endFill();
		var pos:int = PaintVars.tolerancelist.indexOf(PaintVars.tolerance);
		var w:int = 3;
		var h:int = 3;
		var dx:int = 36;
		for (var i:int = 0; i < PaintVars.tolerancelist.length; i++) {
			if (pos == i) g.beginFill(CSS.overColor);
			else g.beginFill(CSS.offColor);
			g.drawRect(dx, 26 - h, w, h);
			dx += 9;
			h += 3;
		}
	}

	//////////////////////////////////////////////////////////////////////
	// Other setup functions
	///////////////////////////////////////////////////////////////////////

	private function makeButtonImg(str:String, b:Boolean):Sprite {
		var bimg:Sprite = new Sprite();
		var g:Graphics = bimg.graphics;
		g.clear();
		g.lineStyle(0.5,CSS.borderColor,1,true);
		var matr:Matrix = new Matrix();
		matr.createGradientBox(32, 32, Math.PI / 2, 0, 0);
		g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], matr);
		g.drawRoundRect(0, 0, 24, 24, 8);
		g.endFill();
		bimg.addChild(Resources.createBmp(str + (b ? "On" : "Off")));
		return bimg;
	}

	private function makeToolButton(str:String, b:Boolean):Sprite {
		var bimg:Sprite = new Sprite();
		var g:Graphics = bimg.graphics;
		g.clear();
		g.lineStyle(0.5,CSS.borderColor,1,true);
		if (b) {
			g.beginFill(CSS.overColor);
		} else {
			var matr:Matrix = new Matrix();
			matr.createGradientBox(24, 24, Math.PI / 2, 0, 0);
			g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], matr);
		}
		g.drawRoundRect(0, 0, 24, 24, 8);
		g.endFill();
		if (b) bimg.addChild(Resources.createBmp(str +"On"));
		else bimg.addChild(Resources.createBmp(str +"Off"));
		return bimg;
	}

	private function drawBackdrop(g:Graphics, w:int,h:int):void {
		g.clear();
		g.lineStyle(0.5,CSS.borderColor,1,true);
		g.beginFill(CSS.white);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	/////////////////////////////////////////////////////
	// Zoom Management Call backs
	/////////////////////////////////////////////////////

	private function doZoomIn(b:IconButton):void {
		function turnOff():void { b.turnOff() }
		var pos:int = PaintVars.zoomValues.indexOf(PaintVars.currentZoom);
		pos++;
		PaintVars.currentZoom = PaintVars.zoomValues[Math.min(PaintVars.zoomValues.length - 1, pos)];
		paintarea.updateZoomScale();
		centerWorkingCanvas();
		setTimeout(turnOff, 50);
	}

	private function doNoZoom(b:IconButton):void {
		function turnOff():void { b.turnOff() }
		PaintVars.currentZoom = 1;
		paintarea.updateZoomScale();
		centerWorkingCanvas();
		setTimeout(turnOff, 50);
	}

	private function doZoomOut(b:IconButton):void {
		function turnOff():void { b.turnOff() }
		var pos:int = PaintVars.zoomValues.indexOf(PaintVars.currentZoom);
		pos--;
		PaintVars.currentZoom = PaintVars.zoomValues[Math.max(0, pos)];
		paintarea.updateZoomScale();
		centerWorkingCanvas();
		setTimeout(turnOff, 50);
	}

	//////////////////////////////////////////////////////////////
	// Import Dialog Not Fully Done Yet THIS IS A PLACEHOLDER
	/////////////////////////////////////////////////////////////

	private function importMediaFromDisk():void {
		var file:FileReference, fName:String;
		function fileSelected(e:Event):void {
			if (fileList.fileList.length == 0) return;
			file = FileReference(fileList.fileList[0]);
			file.addEventListener(Event.COMPLETE, fileLoaded);
			file.load();
		}
		function fileLoaded(e:Event):void {
			fName = file.name;
			var fExt:String = '';
			var i:int = fName.lastIndexOf('.');
			if (i > 0) {
				fExt = fName.slice(i).toLowerCase();
				fName = fName.slice(0, i);
			}
			var data:ByteArray = file.data;
			if ((fExt == '.png') || (fExt == '.jpg') || (fExt == '.gif')) {
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageDecoded);
				loader.loadBytes(file.data);
			}
			if (fExt == '.svg') insertSVG(fName, data);
		}
		function imageDecoded(e:Event):void {
			var bm:BitmapData = e.target.content.bitmapData;
			insertImage(fName, bm);
		}
		var filterImages:FileFilter = new FileFilter("Images", "*.jpg;*.gif;*.png;*.svg");
		var fileList:FileReferenceList = new FileReferenceList();
		fileList.addEventListener(Event.SELECT, fileSelected);
		fileList.browse([filterImages]);
	}

	private function insertImage(name:String, bm:BitmapData):void {
		// if it is an Scene and the bm is 480 by 360
		// loadBackgroundImage will set this image
		// as background layer (SVGData id == "staticbkg")
		if (app.viewedObj().isStage) PaintVars.svgroot.loadBackgroundImage(name, bm);
		else PaintVars.svgroot.loadImage(name, bm);
	}

	private function insertSVG(name:String, svgData:ByteArray):void {
		XML.ignoreComments = false;
		XML.ignoreWhitespace = true;
		var list:Array = SVGImport.recoverData(new XML(svgData));
		var layer:SVGData = new SVGData("g", name);
		layer.setAttribute("children", list);
		var rect:Rectangle = SVGImport.fileAttributes["viewBox"];
		if (!app.viewedObj().isStage) {
			if ((rect != null) && PaintVars.svgroot.isEmpty()) setCanvasSize(rect.width, rect.height);
			PaintVars.svgroot.clearSVGroot();
		}
		PaintVars.svgroot.loadSVGData([layer]);
		PaintVars.recordForUndo();
	}

	// Keyboard commands

	public function startKeyboardListener():void {
		app.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
	}

	public function stopKeyboardListener():void {
		app.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
	}

	private function keyDown(evt:KeyboardEvent):void {
		if (PaintVars.keyFocus) return;
		evt.preventDefault();
		if (evt.ctrlKey) { // control key commands
			switch (evt.keyCode) {
			case 69: // 'e'
				exportSVG();
				break;
			case 83: // 's'
				trace('save');
				var svgData:ByteArray = new ByteArray();
				svgData.writeUTFBytes(SVGExport.svgString(PaintVars.svgroot, paintarea.width, paintarea.height));
				costume.setSVGData(svgData);
				var obj:ScratchObj = app.viewedObj();
				obj.showCostume(obj.currentCostumeIndex);
				break;
			case 90: // 'z'
				if (evt.shiftKey) PaintVars.redo();
				else PaintVars.undo();
				break;
			default:
				trace('ctrl: ' + evt.keyCode);
			}
		} else {
			switch (evt.keyCode) {
			case 8: // delete key
				deleteElement();
				break;
			case 13: // return/enter key
				selectButton("select");
				PaintVars.svgroot.selectorGroup.quitTextEditMode(PaintVars.svgroot.selectorGroup.hideSelectorGroup);
				break;
			case 37:
			case 38:
			case 39:
			case 40:
				moveSelectedElement(evt.keyCode);
			}
		}
	}

	private function deleteElement():void { 
		if (PaintVars.antsAlive()) PaintVars.svgroot.deleteImageSelection();
		else {
			var ps:* = PaintVars.selectedElement;
//			if (ps.getAttribute("bitmapdata") is BitmapData) (ps.getAttribute("bitmapdata") as BitmapData).dispose();
			PaintVars.svgroot.selectorGroup.hideSelectorGroup();
			ps.parent.removeChild(ps);
		}
		PaintVars.recordForUndo();
	}

	private function moveSelectedElement(key:int):void {
		var elem:PaintObject = PaintVars.selectedElement;
		if (!elem) return;
		switch (key) {
		case 37:
			elem.translateTo(new Point(-1, 0));
			break;
		case 38:
			elem.translateTo(new Point(0, -1));
			break;
		case 39:
			elem.translateTo(new Point(1, 0));
			break;
		case 40:
			elem.translateTo(new Point(0, 1));
			break;
		}
		PaintVars.svgroot.selectorGroup.selectorReset(elem);
		PaintVars.recordForUndo();
	}

	private function exportSVG():void {
		var data:String = SVGExport.svgString(PaintVars.svgroot, paintarea.width, paintarea.height);
		var file:FileReference = new FileReference();
		file.save(data);
	}

}}
