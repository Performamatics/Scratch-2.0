package ui.media {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.net.*;
	import flash.utils.ByteArray;
	import scratch.*;
	import uiwidgets.*;
	import util.*;
	
public class MediaLibrary extends Sprite {

	private const overlayColor:int = 0x585756;
	private const overlayAlpha:Number = 0.82;
	private const overlayDropShadowColor:int = 0x333333;

	private var app:Scratch;
	private var assetType:String;
	private var whenDone:Function;

	private var outerFrame:Shape;
	private var innerFrame:Shape;
	private var resultsView:ScrollFrame;
	private var resultsPane:ScrollFrameContents;
	private var importButton:Button;
	private var addButton:Button;
	private var closeButton:Button;

	public function MediaLibrary(app:Scratch, type:String, whenDone:Function) {
		this.app = app;
		this.assetType = type;
		this.whenDone = whenDone;

		outerFrame = new Shape();
		outerFrame.filters = addFilters();
		addChild(outerFrame);
		innerFrame = new Shape();
		addChild(innerFrame);
		addResultsView();

		importButton = new Button('Import from disk', importFromDisk);
		addChild(importButton);
		addButton = new Button('OK', addSelected);
		addChild(addButton);
		closeButton = new Button('Cancel', close);
		addChild(closeButton);
	}

	public function open():void {
		setWidthHeight(app.stage.stageWidth, app.stage.stageHeight);
		app.addChild(this);
		app.mediaLibrary = this;
		viewLibrary();
	}

	private function importFromDisk():void {
		close();
		if (assetType == 'sounds') importSoundFromDisk();
		else importImageFromDisk();
	}

	private function close():void {
		parent.removeChild(this);
		app.mediaLibrary = null;
	}

	public function setWidthHeight(w:int, h:int):void {
		var inset:int = 40;
		drawBackground(w, h);
		drawOuterFrame(w - (2 * inset), h - (2 * inset));
		drawInnerFrame(outerFrame.width - 10, outerFrame.height - 50);	

		outerFrame.x = inset;
		outerFrame.y = inset;
		innerFrame.x = inset + 5;
		innerFrame.y = inset + 45;

		resultsView.setWidthHeight(innerFrame.width - 10, innerFrame.height - 10);
		resultsView.x = innerFrame.x + 5;
		resultsView.y = innerFrame.y + 5;

		importButton.x = inset + 10;	
		importButton.y = inset + 10;

		closeButton.x = w - inset - closeButton.width - 10;	
		closeButton.y = inset + 10;
		addButton.x = closeButton.x - addButton.width - 10;
		addButton.y = closeButton.y;
	}

	private function drawBackground(w:int, h:int):void {
		var g:Graphics = this.graphics;
		g.clear();
		g.beginFill(overlayColor, overlayAlpha);
		g.drawRect(0, 0, w, h); 
		g.endFill();
	}

	private function drawOuterFrame(w:int, h:int):void {
		var g:Graphics = outerFrame.graphics;
		g.clear();
		g.beginFill(CSS.tabColor);
		g.drawRoundRect(0, 0, w, h, 8, 8); 
		g.endFill();
	}

	private function drawInnerFrame(w:int, h:int):void {
		var g:Graphics = innerFrame.graphics;
		g.clear();
		g.beginFill(CSS.white, 1);
		g.drawRoundRect(0, 0, w, h, 12, 12);
		g.endFill();
	}

	private function addFilters():Array {
		var f:DropShadowFilter = new DropShadowFilter();
		f.blurX = f.blurY = 5;
		f.distance = 3;
		f.color = overlayDropShadowColor;
		return [f];		
	}

	private function addResultsView():void {
		resultsPane = new ScrollFrameContents();
		resultsPane.color = CSS.white;
		resultsPane.hExtra = 0;
		resultsPane.vExtra = 5;
		resultsView = new ScrollFrame();
		resultsView.setContents(resultsPane);
		addChild(resultsView);
	}

	// -----------------------------
	// Library Contents
	//------------------------------

	private function viewLibrary():void {
		function gotLibraryData(data:ByteArray):void {
			if (!data) return; // failure
			var s:String = data.readUTFBytes(data.length);
			var rawItems:Array = JSON_AB.parse(s) as Array;
			if (rawItems == null) return;
			var items:Array = [];
			for each (var o:Object in rawItems) items.push(o.obj); // extract obj fields from the results
			appendItems(items);
		}
		Server.listLibraryAssets(assetType, gotLibraryData);
	}

	private var nextY:int;

	private function appendItems(items:Array):void {
		var nextX:int = 0;
		for each (var dbObj:Object in items) {
			var item:MediaInfo = new MediaInfo(null, null, dbObj, true);
			item.x = nextX;
			item.y = nextY;
			resultsPane.addChild(item);
			nextX += item.frameWidth +  (item.isSound ? 12 : 6);
			if ((nextX + item.frameWidth + 8) > resultsView.width) {
				nextX = 0;
				nextY += item.frameHeight + 20;
			}
		}
		if (nextX > 5) nextY += item.frameHeight +  20; // if there's anything on this line, start a new one
		resultsPane.updateSize();
	}

	private function addSelected():void {
		// Close dialog and call whenDone() with an array of selected media items.
		var io:ProjectIO = new ProjectIO(app);
		close();
		for (var i:int = 0; i < resultsPane.numChildren; i++) {
			var item:MediaInfo = resultsPane.getChildAt(i) as MediaInfo;
			if (item && item.isHighlighted()) {
				var md5AndExt:String = item.dbObj.md5;
				if ((md5AndExt.indexOf('.') < 0) && ('extension' in item.dbObj)) {
					md5AndExt = md5AndExt + '.' + item.dbObj.extension;
				}
				if (assetType == 'sounds') io.fetchSound(md5AndExt, item.dbObj.name, whenDone);
				else io.fetchImage(md5AndExt, item.dbObj.name, whenDone);
			}
		}
	}

	// -----------------------------
	// Import from disk
	//------------------------------

	private function importImageFromDisk():void {
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
			} else if (ScratchCostume.isSVGData(data)) {
				var c:ScratchCostume = new ScratchCostume(name, null);
				c.setSVGData(data);
				whenDone(c);
			}
		}
		function imageDecoded(e:Event):void {
			whenDone(new ScratchCostume(name, e.target.content.bitmapData));
		}
		var filterImages:FileFilter = new FileFilter('Images', '*.jpg;*.gif;*.png;*.svg');
		var fileList:FileReferenceList = new FileReferenceList();
		fileList.addEventListener(Event.SELECT, fileSelected);
		fileList.browse([filterImages]);
	}

	private function importSoundFromDisk():void {
		var file:FileReference, fName:String;
		function fileSelected(e:Event):void {
			if (fileList.fileList.length == 0) return;
			file = FileReference(fileList.fileList[0]);
			file.addEventListener(Event.COMPLETE, fileLoaded);
			file.load();
		}
		function fileLoaded(e:Event):void {
			var snd:ScratchSound;
			try {
				snd = new ScratchSound(file.name, file.data);
			} catch (e:Error) { app.browserTrace('sound decode error') }
			if (!snd) return; // decode error
			whenDone(snd);
		}
		var fileList:FileReferenceList = new FileReferenceList();
		fileList.addEventListener(Event.SELECT, fileSelected);
		fileList.browse([new FileFilter('Sounds', '*.wav;*.mp3')]);
	}

}}
