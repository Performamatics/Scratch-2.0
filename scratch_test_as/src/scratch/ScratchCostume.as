// ScratchCostume.as
// John Maloney, April 2010
// John Maloney, January 2011 (major restructure)
//
// A Scratch costume (or scene) is a named image with a rotation center.
// The bitmap field contains the composite costume image.
//
// Internally, a costume consists of a base image and an optional text layer.
// If a costume has a text layer, the text image is stored as a separate
// bitmap and composited with the base image to create the costume bitmap.
// Storing the text layer separately allows the text to be changed indpendent
// of the base image. Saving the text image means that costumes with text
// do not depend on the fonts available on the viewer's computer. (However,
// editing the text *does* depend on the user's fonts.)
//
// The source data (PNG, JPEG, or SVG format) for each layer is retained so
// that it does not need to be recomputed when saving the project. This also
// avoid the possible image degradation that might occur when repeatedly
// converting to/from JPEG format.

package scratch {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.ByteArray;
	import com.lorentz.SVG.display.SVGDocument;
	import util.*;
	//import com.adobe.serialization.json.*; // added by Matt Vaughan

public class ScratchCostume {

	public var costumeName:String;
	public var bitmap:BitmapData; // composite bitmap (base layer + text layer)
	public var rotationCenterX:int;
	public var rotationCenterY:int;

	public var baseLayerSVG:SVGDocument;  // for SVG costumes, this field is used instead of baseLayerBitmap
	public var baseLayerBitmap:BitmapData;
	public var baseLayerID:int = -1;
	public var baseLayerMD5:String;
	public var baseLayerData:ByteArray;

	public var oldComposite:BitmapData; // composite bitmap from old Scratch file (used only during loading)

	public var textLayerBitmap:BitmapData;
	public var textLayerID:int = -1;
	public var textLayerMD5:String;
	public var textLayerData:ByteArray;

	public var text:String;
	public var textRect:Rectangle;
	public var textColor:uint;
	public var fontName:String;
	public var fontSize:int;

	public var spritesHiddenInScene:Array = null; // scene support; not used on sprite costumes

	public function ScratchCostume(name:String, bm:BitmapData, centerX:int = 99999, centerY:int = 99999) {
		costumeName = name;
		bitmap = baseLayerBitmap = bm;
		rotationCenterX = centerX;
		rotationCenterY = centerY;
		if (bm != null) {
			if (centerX == 99999) rotationCenterX = bm.rect.width / 2;
			if (centerY == 99999) rotationCenterY = bm.rect.height / 2;
		}
	}
	
	public static function isSVGData(data:ByteArray):Boolean {
		var oldPosition:int = data.position;
		data.position = 0;
		var s:String = data.readUTFBytes(10);
		data.position = oldPosition;
		return (s.indexOf('<?xml') >= 0) || (s.indexOf('<svg') >= 0);
	}

	public function setSVGData(svgData:ByteArray):void {
		// Initialize an SVG costume.
		clearOldCostume();
		baseLayerData = svgData;
		baseLayerSVG = new SVGDocument();
		svgData.position = 0;
		baseLayerSVG.parse(svgData.readUTFBytes(svgData.length));
//		rotationCenterX = width() / 2;
//		rotationCenterY = height() / 2;
	}

	private function clearOldCostume():void {
		bitmap = null;
		rotationCenterX = 0;
		rotationCenterY = 0;

		baseLayerSVG = null;
		baseLayerBitmap = null;
		baseLayerID = -1;
		baseLayerMD5 = null;
		baseLayerData = null;

		oldComposite = null;

		textLayerBitmap = null;
		textLayerID = -1;
		textLayerMD5 = null;
		textLayerData = null;
	}

	public function displayObj():DisplayObject {
		if (baseLayerSVG) return baseLayerSVG;
		else return new Bitmap(bitmap);
	}

	public function width():Number {
		if (baseLayerSVG) {
			if (baseLayerSVG.width == 0) baseLayerSVG.validate();
			return baseLayerSVG.width;
		}
		return bitmap ? bitmap.width : 0;
	}

	public function height():Number {
		if (baseLayerSVG) {
			if (baseLayerSVG.height == 0) baseLayerSVG.validate();
			return baseLayerSVG.height;
		}
		return bitmap ? bitmap.height : 0;
	}

	public function toString():String {
		var result:String = 'ScratchCostume(' + costumeName + ' (' + rotationCenterX + ', ' + rotationCenterY + ')';
		if (bitmap == null) result += 'no bitmap';
		result += ')';
		return result;
	}

	public function writeJSON(json:JSON_AB):void {
		json.writeKeyValue('costumeName', costumeName);
		json.writeKeyValue('baseLayerID', baseLayerID);
		json.writeKeyValue('baseLayerMD5', baseLayerMD5);
		json.writeKeyValue('rotationCenterX', rotationCenterX);
		json.writeKeyValue('rotationCenterY', rotationCenterY);
		json.writeKeyValue('spritesHiddenInScene', spritesHiddenInScene);
		if (text != null) {
			json.writeKeyValue('text', text);
			json.writeKeyValue('textRect', [textRect.x, textRect.y, textRect.width, textRect.height]);
			json.writeKeyValue('textColor', textColor);
			json.writeKeyValue('fontName', fontName);
			json.writeKeyValue('fontSize', fontSize);
			json.writeKeyValue('textLayerID', textLayerID);
			json.writeKeyValue('textLayerMD5', textLayerMD5);
		}
	}
 
	public function readJSON(jsonObj:Object):void {
		costumeName = jsonObj.costumeName;
		baseLayerID = jsonObj.baseLayerID;
		if (jsonObj.baseLayerID == undefined) {
			if (jsonObj.imageID) baseLayerID = jsonObj.imageID; // slighly older .sb2 format
		}
		baseLayerMD5 = jsonObj.baseLayerMD5;
		rotationCenterX = jsonObj.rotationCenterX;
		rotationCenterY = jsonObj.rotationCenterY;
		spritesHiddenInScene = jsonObj.spritesHiddenInScene;
		text = jsonObj.text;
		if (text != null) {
			if (jsonObj.textRect is Array) {
				textRect = new Rectangle(jsonObj.textRect[0], jsonObj.textRect[1], jsonObj.textRect[2], jsonObj.textRect[3]);
			}
			textColor = jsonObj.textColor;
			fontName = jsonObj.fontName;
			fontSize = jsonObj.fontSize;
			textLayerID = jsonObj.textLayerID;
			textLayerMD5 = jsonObj.textLayerMD5;
		}
	}

	public function prepareToSave():void {
		if (oldComposite) computeTextLayer();
		baseLayerID = textLayerID = -1;
		if (baseLayerData == null) baseLayerData = new PNGMaker().encode(baseLayerBitmap);
		if (baseLayerMD5 == null) baseLayerMD5 = MD5.hashBinary(baseLayerData) + fileExtension(baseLayerData);
		if (textLayerBitmap != null) {
			if (textLayerData == null) textLayerData = new PNGMaker().encode(textLayerBitmap);
			if (textLayerMD5 == null) textLayerMD5 = MD5.hashBinary(textLayerData) + '.png';
		}
	}

	private function computeTextLayer():void {
		// When saving an old-format project, generate the text layer bitmap by subtracting
		// the base layer bitmap from the composite bitmap. (The new costume format keeps
		// the text layer bitmap only, rather than the entire composite image.)

		if (oldComposite == null) return; // nothing to do
		var diff:BitmapData = oldComposite.compare(baseLayerBitmap) as BitmapData;
		var stencil:BitmapData = new BitmapData(diff.width, diff.height, true, 0);
		stencil.threshold(diff, diff.rect, new Point(0, 0), '!=', 0, 0xFF000000);
		textLayerBitmap = new BitmapData(diff.width, diff.height, true, 0);
		textLayerBitmap.copyPixels(oldComposite, oldComposite.rect, new Point(0, 0), stencil, new Point(0, 0), false);
		oldComposite = null;
	}

	public static function fileExtension(data:ByteArray):String {
		data.position = 0;
		if (data.readUTFBytes(4) == '\x89PNG') return '.png';
		data.position = 6;
		if (data.readUTFBytes(4) == 'JFIF') return '.jpg';
		data.position = 0;
		if (data.readUTFBytes(5) == '<?xml') return '.svg';
		return '.jpg';
	}

	public function generateOrFindComposite(allCostumes:Array):void {
		// If this costume has a text layer bitmap, compute or find a composite bitmap.
		// Since there can be multiple copies of the same costume, first try to find a
		// costume with the same base and text layer bitmaps and share its composite
		// costume. This saves speeds up loading and saves memory.

		if (bitmap != null) return;
		if (textLayerBitmap == null) {  // no text layer; use the base layer bitmap
			bitmap = baseLayerBitmap;
			return;
		}
		for each (var c:ScratchCostume in allCostumes) {
			if ((c.baseLayerBitmap === baseLayerBitmap) &&
				(c.textLayerBitmap === textLayerBitmap) &&
				(c.bitmap != null)) {
					bitmap = c.bitmap;
					return;  // found a composite bitmap to share
				}
		}
		// compute the composite bitmap
		bitmap = baseLayerBitmap.clone();
		bitmap.draw(textLayerBitmap);
	}

}}
