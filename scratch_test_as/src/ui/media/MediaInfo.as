// MediaInfo.as
// John Maloney, December 2011
//
// This object represent a sound, image, or script. It displays a thumbnail,
// name, and information about the object it represents.
// It is used in many ways:
//	* to represent costumes, scenes, and sounds in the media panes of a Scratch object
//	* to represent images and sounds in the Scratch media library
//	* to represent images, sounds, and scripts in the backpack.
//	* to drag between containers (e.g. between the backpack and a sprite)

package ui.media {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
	import assets.Resources;
	import blocks.BlockIO;
	import scratch.*;
	import sound.*;
	import util.ProjectIO;
	import ui.parts.SoundsPart;
	import uiwidgets.*;
	import util.*;
	import blocks.Block;
	import ui.parts.BackpackPart;
	import ui.parts.ImagesPart;
	import ui.parts.SoundsPart;

public class MediaInfo extends Sprite {

	public var frameWidth:int = 80;	
	public var frameHeight:int = 80;
	private var thumbnailWidth:int = 68;	
	private var thumbnailHeight:int = 51;

	// Only of these is non-nil:
	public var mysound:ScratchSound;
	public var mycostume:ScratchCostume;
	public var script:Block;

	public var dbObj:Object;
	public var inLibrary:Boolean;

	private var frame:Shape; // visible when selected
	private var thumbnail:Bitmap;
	private var label:TextField;
	private var info:TextField;
	private var deleteButton:IconButton;
	private var playButton:IconButton;

	private var targetObj:ScratchObj; // object owning the sound or costume; null for other cases
	public var isSound:Boolean;
	private var sndData:ByteArray;
	private var sndPlayer:ScratchSoundPlayer;
	
	public function MediaInfo(targetObj:ScratchObj, costumeScriptOrSound:*, dbObject:Object = null, inLibrary:Boolean = false) {
		this.targetObj = targetObj;
		this.mycostume = costumeScriptOrSound as ScratchCostume;
		this.mysound = costumeScriptOrSound as ScratchSound;
		this.script = costumeScriptOrSound as Block;
		this.dbObj = dbObject;
		this.inLibrary = inLibrary;

		if (!dbObj) generateDBObj();
		if (dbObj.seconds) {
			isSound = true;
			if (mysound) sndData = mysound.soundData;
		}
		if (inLibrary && !isSound) {
			frameWidth = 100;
			frameHeight = 105;
			thumbnailWidth = 98;
			thumbnailHeight = 68;
		}
		addFrame();
		addThumbnail();
		addLabel();
		addInfo();
		unhighlight();
		if (!inLibrary) addDeleteButton();
		if (isSound) addPlayButton();
	}

	public function highlight():void {
		frame.alpha = 1;
	//	textIsOn(label, true);
	//	textIsOn(info, true);
		}
		
	public function unhighlight():void { 
		frame.alpha = 0; 
	//	textIsOn(label, false);
	//	textIsOn(info, false);
	}
	
	public function toggleHighlight():void {
	 // textIsOn(label, !(frame.alpha == 1)); 
	 // textIsOn(info, !(frame.alpha == 1)); 
		frame.alpha = (frame.alpha == 1) ? 0 : 1; 
		}
		
	public function isHighlighted():Boolean { return frame.alpha == 1 }

	private function textIsOn(tf:TextField, b:Boolean):void{
		var format:TextFormat =tf.getTextFormat();
		format.color = b ? CSS.white : CSS.textColor;
		tf.setTextFormat(format);
}		
	// -----------------------------
	// Thumbnail
	//------------------------------

	public function updateThumbnail():void {}

	private function setThumbnailFrom(srcImg:BitmapData):void {
		if (!srcImg) return;
		var w:int = thumbnailWidth;
		var h:int = thumbnailHeight;
		var tmp:BitmapData = new BitmapData(w, h, true, 0x00FFFFFF); // transparent fill color
		var scale:Number = Math.min(w / srcImg.width, h / srcImg.height);
		var m:Matrix = new Matrix();
		if (scale < 1) { // scale down a large image
			m.scale(scale, scale);
			m.translate((w - (scale * srcImg.width)) / 2, (h - (scale * srcImg.height)) / 2);
		} else { // center a smaller image
			m.translate((w - srcImg.width) / 2, (h - srcImg.height) / 2);
		}
		tmp.draw(new Bitmap(srcImg), m);
		thumbnail.bitmapData = tmp;
		thumbnail.x = (frameWidth - thumbnail.width) / 2;
	}

	private function fetchThumbnail():void {
		function gotThumbnail(bm:BitmapData):void {
			if (bm) thumbnail.bitmapData = bm;
			thumbnail.x = (frameWidth - thumbnail.width) / 2;
		}
		var id:String = dbObj.md5;
		if ((id.indexOf('.') < 0) && (dbObj.extension)) id += '.' + dbObj.extension;
		if (fileType(id) == 'svg') return; // thumbnails of svg's not yet handled
		Server.getThumbnail(id, thumbnailWidth, thumbnailHeight, gotThumbnail);
	}

	private function setScriptThumbnail():void {
		var scale:Number = Math.min(thumbnailWidth / script.width, thumbnailHeight / script.height);
		var bm:BitmapData = new BitmapData(thumbnailWidth, thumbnailHeight, true, 0);
		var m:Matrix = new Matrix();
		m.scale(scale, scale);
		bm.draw(script, m);
		thumbnail.bitmapData = bm;
		thumbnail.x = (frameWidth - thumbnail.width) / 2;
	}

	private function fileType(s:String):String {
		var i:int = s.lastIndexOf('.');
		if (i < 0) return '';
		return s.slice(i + 1);
	}

	// -----------------------------
	// Label and Info
	//------------------------------

	private function labelString():String {
		if (mycostume) return mycostume.costumeName;
		if (mysound) return mysound.soundName;
		if (script) return '';
		if (dbObj.name) return dbObj.name;
		return '';
	}

	private function infoString():String {
		if (mycostume) {
			var bmp:BitmapData = mycostume.baseLayerBitmap;
			return bmp ? (bmp.width + 'x' + bmp.height) : '';
		}
		if (mysound) return getTime(mysound.getLengthInMsec());
		if (script) return 'Script';
		if (dbObj.width) return dbObj.width + " x " + dbObj.height; // image asset
		if (dbObj.seconds) return getTime(dbObj.seconds * 1000); // sound asset
		return '';
	}
	
	private function getTime(msecs:Number):String {
		// Return a formatted time in MM:SS.T (where T is tenths of a second).
		var secs:int = msecs / 1000;
		var tenths:int = (msecs % 1000) / 100;
		return twoDigits(secs / 60) + ':' + twoDigits(secs % 60) + '.' + tenths;
	}

	private function twoDigits(n:int):String { return (n < 10) ? '0' + n : '' + n }

	// -----------------------------
	// Backpack Support
	//------------------------------

	public function copyForDrag():MediaInfo {
		var result:MediaInfo = new MediaInfo(null, null, dbObj);
		if (mysound) result = new MediaInfo(null, mysound);
		if (mycostume) result = new MediaInfo(null, mycostume);
		if (script) result = new MediaInfo(null, script);
		result.removeDeleteButton();
		if (getBackpack()) result.dbObj.fromBackpack = true;
		return result;
	}

	public function addDeleteButton():void {
		removeDeleteButton();
		deleteButton = new IconButton(deleteMe, Resources.createBmp('removeItem'));
		deleteButton.x = frame.width - deleteButton.width + 5;
		deleteButton.y = 3;
		addChild(deleteButton);
	}

	public function removeDeleteButton():void {
		if (deleteButton) {
			removeChild(deleteButton);
			deleteButton = null;
		}
	}

	private function generateDBObj():void {
		// Generate a database object for a costume, sound, or script.
		if (mysound) {
			mysound.prepareToSave();
			dbObj = {
				name: mysound.soundName,
				type: 'sound',
				md5: mysound.md5,
				seconds: mysound.getLengthInMsec() / 1000
			}
		}
		if (mycostume) {
			mycostume.prepareToSave();
			dbObj = {
				name: mycostume.costumeName,
				type: 'image',
				md5: mycostume.baseLayerMD5,
				width: mycostume.width(),
				height: mycostume.height()
			}
		}
		if (script) {
			dbObj = {
				type: 'script',
				script: BlockIO.stackToString(script)
			}
			dbObj.md5 = MD5.hashString(dbObj.script);
		}
	}

	// -----------------------------
	// Parts
	//------------------------------

	private function addFrame():void {
		frame = new Shape();
		var g:Graphics = frame.graphics;
		if (!inLibrary) g.lineStyle(0.5, CSS.borderColor);
		g.beginFill(CSS.panelColor);
		g.drawRoundRect(0, 0, frameWidth, frameHeight, 12, 12);
		g.endFill();
		addChild(frame);
	}

	private function addThumbnail():void {
		thumbnail = Resources.createBmp('Placeholder');
		thumbnail.x = (frameWidth - thumbnail.width) / 2;
		thumbnail.y = (thumbnailHeight - thumbnail.height) / 2;
		if (isSound) {
			thumbnail = Resources.createBmp('speakerOff');
			thumbnail.x = 10;
			thumbnail.y = 20;
		}
		if (mycostume) setThumbnailFrom(mycostume.baseLayerBitmap);
		else if (dbObj.width) fetchThumbnail();
		else if (script) setScriptThumbnail();
		addChild(thumbnail);	
	}

	private function addInfo():void {
		info = Resources.makeLabel(infoString(), CSS.thumbnailExtraInfoFormat);
		info.x = Math.max(0, (frameWidth - info.textWidth) / 2);
		info.y = frameHeight - 13;
		addChild(info);
	}

	private function addLabel():void {
		label = Resources.makeLabel('', CSS.thumbnailFormat);
		setText(label, labelString())
		label.x = (frameWidth - label.textWidth) / 2;
		label.y = frameHeight - 27;
		addChild(label);
	}

	private function addPlayButton():void {
		playButton = new IconButton(toggleSoundPlay, 'play');
		playButton.x = 53;
		playButton.y = 23;
		addChild(playButton);
	}

	private function setText(tf:TextField, s:String):void {
		// Set the text of the given TextField, truncating if necessary.
		tf.text = s;
		while ((tf.textWidth > frame.width) && (s.length > 0)) {
			s = s.substring(0, s.length - 1);
			label.text = s + '\u2026';  // truncated name with ellipses
		}
	}

	// -----------------------------
	// Events
	//------------------------------

	public function click(evt:MouseEvent):void {
		var app:Scratch = root as Scratch;
		if (mycostume) {
			app.viewedObj().showCostumeNamed(mycostume.costumeName);
			app.selectCostume();
		}
		if (mysound) app.selectSound(mysound);
		if (inLibrary) {
			if (!evt.shiftKey) unhighlightAll();
			toggleHighlight();
		}
	}

	private function deleteMe(ignore:*):void {
		if (targetObj) {
			if (mycostume) targetObj.deleteCostume(mycostume);
			if (mysound) targetObj.deleteSound(mysound);
			if (this.parent.parent.parent is ImagesPart)(this.parent.parent.parent as ImagesPart).refresh();
			else if (this.parent.parent.parent is SoundsPart)(this.parent.parent.parent as SoundsPart).refresh();		
		//	(parent as MediaPane).refresh();
		}
		if (getBackpack()) getBackpack().deleteItem(this);
	}

	private function getBackpack():BackpackPart {
		var p:DisplayObject = parent;
		while (p != null) {
			if (p is BackpackPart) return (p as BackpackPart);
			p = p.parent;
		}
		return null;
	}

	private function unhighlightAll():void {
		var contents:ScrollFrameContents = parent as ScrollFrameContents;
		if (!contents) return;
		for (var i:int = 0; i < contents.numChildren; i++) {
			var item:MediaInfo = contents.getChildAt(i) as MediaInfo;
			if (item) item.unhighlight();
		}
	}

	// -----------------------------
	// Play Sound
	//------------------------------

	private function toggleSoundPlay(b:IconButton):void {
		if (sndPlayer) stopPlayingSound(null);
		else startPlayingSound();
	}

	private function stopPlayingSound(ignore:*):void {
		if (sndPlayer) sndPlayer.stopPlaying();
		sndPlayer = null;
		playButton.turnOff();
	}

	private function startPlayingSound():void {
		if (mysound) {
			sndPlayer = mysound.sndplayer(); 
		} else if (sndData) {
			if (ScratchSound.isWAV(sndData)) {
				sndPlayer = new ScratchSoundPlayer(sndData);
			} else {
				sndPlayer = new MP3SoundPlayer(sndData);
			}
		}
		if (sndPlayer) {
			sndPlayer.startPlaying(stopPlayingSound);
			playButton.turnOn();
		} else {
			downloadAndPlay();
		}
	}

	private function downloadAndPlay():void {
		// Download and play a library sound.
		function gotSoundData(wavData:ByteArray):void {
			sndData = wavData;
			startPlayingSound();
		}
		var id:String = dbObj.md5;
		if ((id.indexOf('.') < 0) && (dbObj.extension)) id += '.' + dbObj.extension;
		Server.getAsset(id, gotSoundData);
	}

}}
