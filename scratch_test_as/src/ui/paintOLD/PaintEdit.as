package ui.paint {
	import flash.display.*;
	import flash.events.Event;
	import flash.geom.Matrix;
	import assets.Resources;
	import scratch.*;
	import ui.parts.ImagesPart;
	import ui.media.MediaLibrary;
	import uiwidgets.*;
	import webcamui.*;

public class PaintEdit extends Sprite {

	public var app:Scratch;
	public var viewedObj:ScratchObj;

	private var costumename:EditableLabel;
	private var importFromLibrary:IconButton;
	private var takePhoto:IconButton;
	private var paintarea:PaintCanvas;
	private var w:int;
	private var h:int;

	public function PaintEdit(app:Scratch) {
		this.app = app;
		costumename = new EditableLabel(nameChanged);
		addChild(costumename);
		importFromLibrary = new IconButton(openLibrary, makeButtonImg('library', true), makeButtonImg('library', false));
		importFromLibrary.isMomentary = true;
		addChild(importFromLibrary);
		takePhoto = new IconButton(openCamera, makeButtonImg('camera', true), makeButtonImg('camera', false));
		takePhoto.isMomentary = true;
		addChild(takePhoto);				
		
		paintarea = new PaintCanvas();
		addChild(paintarea);	
	}
	
	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		costumename.y = 2;
		costumename.setWidth(w - 82 - 40);		
		importFromLibrary.x = w - 32;
		takePhoto.x = w - 40 - 32 - 40;
		var shrinkby:int = 20;
		if (viewedObj == null) return;
		var dh:int = viewedObj.isStage ? Math.min(360, Math.floor ((w - shrinkby) * 3 / 4)) : Math.min(w-shrinkby, h - 200);
		var dw:int = viewedObj.isStage ? Math.min(480, w - shrinkby) : w-shrinkby;
		paintarea.setWidthHeight(dw, dh);		
		paintarea.x = (w - dw) / 2;
		paintarea.y = 40;		
	}

	public function refresh():void {
		viewedObj = app.viewedObj();
		if (viewedObj == null) return;
		var current:ScratchCostume = viewedObj.currentCostume();
		costumename.setContents(current.costumeName);
		setWidthHeight(w, h);
	}
	
	private function makeButtonImg(str:String, isOn:Boolean):Sprite {
		var img:Sprite = new Sprite();
		var g:Graphics = img.graphics;
		g.clear();
		g.lineStyle(0.5,CSS.borderColor,1,true);
		var m:Matrix = new Matrix();
 		m.createGradientBox(32, 32, Math.PI / 2, 0, 0);
 		g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], m);  
		g.drawRoundRect(0, 0, 32, 32, 12);
 		g.endFill();
 		if (isOn) img.addChild(Resources.createBmp(str + "On"));
 		else img.addChild(Resources.createBmp(str + "Off"));
		return img;
	}

	private function nameChanged(evt:Event):void {
		var current:ScratchCostume = viewedObj.currentCostume();
		current.costumeName = costumename.contents();
		(parent as ImagesPart).refresh();
	}

	// -----------------------------
	// Camera and Library
	//------------------------------

	private static var photoNumber:int = 1;
	private static var cameraDialog:WebCamPane;

	private function openCamera(b:IconButton):void {
		function savePhoto(photo:BitmapData):void {
			var c:ScratchCostume = new ScratchCostume('photo' + photoNumber++, photo);
			app.addCostume(c);
		}
		if (cameraDialog) cameraDialog.closeDialog();
		cameraDialog = new WebCamPane(savePhoto);
		cameraDialog.fixLayout();
		cameraDialog.x = (stage.stageWidth - cameraDialog.width) / 2;
		cameraDialog.y = (stage.stageHeight - cameraDialog.height) / 2;;
		app.addChild(cameraDialog);
	}

	private function openLibrary(b:IconButton):void {
		var mediaType:String = (viewedObj.isStage) ? "backgrounds": "costumes";
		new MediaLibrary(app, mediaType, app.addCostume).open();		
	}

}}
