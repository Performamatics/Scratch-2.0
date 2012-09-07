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

package ui.paintui {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.geom.*;
	import flash.text.TextField;
	import flash.utils.*;
	import util.Color;

public class PaintVars {

	//////////////////////////////////////////
	// Painting Varibles
	/////////////////////////////////////////

	public static var appStage:Stage;

	public static var dragging:Boolean = false;
	public static var resizeMode:String = 'none';
	public static var initialPoint:Point;
	public static var deltaPoint:Point;
	public static var pathanchor:Point;
	public static var paintMode:String = 'select';
	public static var currentZoom:Number = 1;
	public static var zoomValues:Array = [0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0];

	public static var selectedElement:PaintObject; // element that has selection border
	public static var pathSelector:PaintObject;
	public static var pevSelection:PaintObject;
	public static var currentshape:PaintObject;
	public static var svgns:String = 'http://www.w3.org/2000/svg';

	public static var tolerancelist:Array = [0, 8, 16, 32, 64, 128]; // 255];
	public static var tolerance:int = 32;

	public static var svgroot:SVGRoot;
	public static var selectionBox:Rectangle;

	public static const opacity:Number = 0.6;

	public static var keyFocus:TextField;

	////////////////////////////////////////////
	// Pixel Editting
	////////////////////////////////////////////

	public static var offscreen:BitmapData;
	public static var zebra:BitmapData;
	public static var marchingants:Bitmap;
	public static var intervalId:uint = 0;
	public static var contour:BitmapData;

	public static function antsAlive():Boolean { return intervalId != 0 }

	public static function clearMarchingAnts():void {
		if (!marchingants) return;
		if (marchingants.parent != null) {
			marchingants.parent.removeChild(marchingants);
			if (contour) contour.dispose();
			contour = null;
			marchingants = null;
		}
		if (intervalId) clearInterval(intervalId);
		intervalId = 0;
	}

	////////////////////////////////////////////
	// Undo
	///////////////////////////////////////////

	public static var undoBuffer:Array = [[]];
	public static var undoIndex:int = 0;

	public static function recordForUndo():void {
		var svgs:Array = svgroot.getSVGlist();
		var data:Array = getClones(svgs);
		if ((undoIndex + 1) <= undoBuffer.length) undoBuffer.splice(undoIndex + 1, undoBuffer.length);
		undoBuffer.push (data);
		undoIndex++;
	}

	public static function undo():void {
		if (pathSelector != null) svgroot.selectorGroup.quitPathEditMode();
		if (selectedElement) svgroot.selectorGroup.hideSelectorGroup();
		undoIndex--;
		while (undoIndex >= undoBuffer.length) undoIndex--;
		svgroot.clearSVGroot();
		if (undoIndex < 0) undoIndex = 0;
		else svgroot.reloadSVGData(null, undoBuffer[undoIndex]);
	}

	public static function redo():void {
		if (pathSelector) svgroot.selectorGroup.quitPathEditMode();
		if (selectedElement) svgroot.selectorGroup.hideSelectorGroup();
		undoIndex++;
		if (undoIndex > undoBuffer.length - 1) return;
		svgroot.clearSVGroot();
		svgroot.reloadSVGData(null, undoBuffer[undoIndex]);
	}

	public static function getClones(svgs:Array):Array{
		var res:Array = [];
		for (var k:int =0; k < svgs.length; k++) {
			var svg:SVGData = svgs[k] as SVGData;
			var costume:SVGData = svg.cloneSVG();
			if (costume.tagName == 'g') costume.setAttribute('children', getClones(costume.getAttribute('children')));
			res.push(costume);
		}
		return res;
	}

	//////////////////////////////////////////
	// Selection status
	/////////////////////////////////////////

	public static function getKeyBoardEvents():void { appStage.focus = keyFocus }
	public static function inTextEditting():Boolean { return keyFocus != null }
	public static function textIsSelected():Boolean { return selectedElement && (selectedElement.tagName == 'text') }
	public static function pathIsSelected():Boolean { return selectedElement && (selectedElement.getAttribute('points') != null) }
	public static function imageIsSelected():Boolean { return selectedElement && (selectedElement.tagName == 'image') }
	public static function backgroundIsSelected():Boolean { return selectedElement && (selectedElement.id == 'staticbkg') }

	//////////////////////////////////////////
	// Gradients Attributes
	/////////////////////////////////////////

	public static var defaultRatios:Array = [0x00, 0xFF];
	public static var horizontal:Object = {type: GradientType.LINEAR, index: 1, x1: 0, y1:0, x2: 1, y2: 0};
	public static var vertical:Object = {type: GradientType.LINEAR, index: 2, x1: 0, y1: 0, x2: 0, y2: 1};
	public static var diagonally:Object = {type: GradientType.LINEAR, index: 3, x1: 1, y1: 0, x2: 0, y2: 1};
	public static var diagonally2:Object = {type: GradientType.LINEAR, index: 4, x1: 1, y1: 1, x2: 0, y2: 0};
	public static var radialgradient:Object = {type: GradientType.RADIAL, index: 5, cx: 0.5, cy: 0.5, fx: 0.5, fy: 0.5, r: 0.6};
	public static var radialtl:Object = {type: GradientType.RADIAL, index: 6, cx: 0.2, cy: 0.2, fx: 0.2, fy: 0.2, r: 1};
	public static var radialbr:Object = {type: GradientType.RADIAL, index: 7, cx: 0.8, cy: 0.8, fx: 0.8, fy: 0.8, r: 1};

	//////////////////////////////////////////
	// Text Attributes
	/////////////////////////////////////////

	public static var textAttributes:Object = {
		family: 'Trebuchet MS',
		fontsize: 24,
		fontstyle: 'normal',
		basecolor: 0xff,
		hue: 0,
		saturation: 1,
		brightness: 1,
		weight: 'normal'
	}

	public static var	fillAttributes:Object = {
		fillstyle: 'onecolor',
		basecolor: 0xff0000,
		hue: 0,
		saturation: 1,
		brightness: 1,
		alpha: 1,
		gradcolor: 0x00ff72,
		gradhue: 147,
		gradsat: 1,
		gradbright: 1,
		gradalpha: 1
	};

	//////////////////////////////////////////
	// Element Attributes
	/////////////////////////////////////////

	public static function getPenAttr(c:*):Object{
		var sw:* = PaintVars.strokeAttributes.basecolor;
		if (sw == 'none') {
			return {
				'fill': c,
				'stroke': 'none'}
		} else {
			return {
				'fill': c,
				'stroke': PaintVars.strokeAttributes.basecolor,
				'stroke-width': PaintVars.strokeAttributes.strokewidth
			}
		}
	}

	public static function eyeDrop(po:PaintObject, evt:MouseEvent):void {
		if (po == null) return;
		var elem:SVGData = po.odata;
		var drawattr:Object = SVGImport.attributePenTable[elem.tagName];
		if (drawattr == null) return;
		for (var i:int = 0; i < drawattr.length; i++) {
			switch (drawattr[i]) {
			case 'stroke-width':
				var n:Number = Number(elem.getAttribute(drawattr[i]));
				if (elem.tagName == 'text') strokeAttributes.textstroke = n;
				else strokeAttributes.strokewidth =n;
				break;
			case 'stroke':
				if ((elem.getAttribute(drawattr[i]) == 'none') || (elem.getAttribute(drawattr[i]) == null)) strokeAttributes.basecolor = 'none';
				else {
					strokeAttributes.basecolor= elem.getAttribute(drawattr[i]);
					var rgb:Array= ((strokeAttributes.basecolor is String) && (strokeAttributes.basecolor == 'none')) ? [0,0,0] : Color.rgb2hsv(strokeAttributes.basecolor);
					setStrokeColor(rgb);
					}
				break;
			case 'fill':
				eyedropFill(elem, drawattr[i]);
				break;
			}
		}
		if (elem.getAttribute('fillhue')) fillAttributes.hue = elem.getAttribute('fillhue');
		if (elem.getAttribute('fillghue')) fillAttributes.gradhue = elem.getAttribute('fillghue');
		fillAttributes['basecolor'] = Color.fromHSV(fillAttributes['hue'], fillAttributes['saturation'], fillAttributes['brightness']);
		fillAttributes['gradcolor'] = Color.fromHSV(fillAttributes['gradhue'] ,	fillAttributes['gradsat'] ,	fillAttributes['gradbright']);
	}

	private static function eyedropFill(elem:SVGData, key:String):void {
		var fill:* = elem.getAttribute(key);
		if (fill == 'none') {
			fillAttributes.fillstyle = 'onecolor';
			fillAttributes.alpha = 0;
		} else {
			if (fill is Number) {
				fillAttributes.fillstyle = 'onecolor';
				fillAttributes.alpha = 1;
				fillAttributes.basecolor= fill;
				var hsv:Array= Color.rgb2hsv(fill);
				setFillColor(hsv);
			} else {
				fillAttributes.fillstyle = getFillStyleFrom(fill);
				var colors:Array = fill.colors;
				var ratios:Array = fill.ratios;
				var alphas:Array = fill.alphas;
				fillAttributes.gradalpha = (alphas[0] == 0) ? 0 : 1;
				fillAttributes.alpha = (alphas[1] == 0) ? 0 : 1;
				fillAttributes.gradcolor = colors[0];
				fillAttributes.basecolor = colors[1];
				setFillColor(Color.rgb2hsv(fillAttributes.basecolor));
				setFillColor2(Color.rgb2hsv(fillAttributes.gradcolor));
			}
		}
	}

	public static function getFillStyleFrom(grad:Object):Object{
		var res:Object = {}, i:String;
		switch (grad.type) {
		case GradientType.LINEAR:
			for (i in vertical) res[i] = grad[i];
			break;
		case GradientType.RADIAL:
			for (i in radialgradient) res[i] = grad[i];
			break;
		}
		return res;
	}

	//////////////////////////////////////////
	// Color Attributes
	/////////////////////////////////////////

	public static var penAtt:String = 'fill';
	public static var activeHue:String = 'color1';

	public static var strokeAttributes:Object = {
		basecolor: 0x0,
		hue: 0,
		alpha: 1,
		saturation: 1,
		brightness: 0,
		strokewidth: 2,
		textstroke: 0.5
	}

	public static function radialGradientMatrix(cx:Number, cy:Number, r:Number, fx:Number, fy:Number ):Matrix {
		var d:Number = r*2;
		var mat:Matrix = new Matrix();
		mat.createGradientBox( d, d, 0, 0, 0);
		var a:Number = Math.atan2(fy-cy,fx-cx);
		mat.translate( -cx, -cy );
		mat.rotate( -a );
		mat.translate( cx, cy );
		mat.translate( cx-r, cy-r );
		return mat;
	 }

	public static function setGradientFill(g:Graphics, grad:Object, w:Number, h:Number, tx:Number,ty:Number):void {
		switch (grad.type) {
		case GradientType.LINEAR:
			setLinearGradientFill(g, grad, w,h, tx, ty);
			break;
		case GradientType.RADIAL:
			if(grad.r == '0') g.beginFill(grad.colors[grad.colors.length-1], grad.alphas[grad.alphas.length-1]);
			else setRadialGradientFill(g, grad, w,h, tx, ty);
			break;
		}
	}

	private static function setLinearGradientFill(g:Graphics,grad:Object, w:Number, h:Number, tx:Number, ty:Number):void {
		var mat:Matrix =getLinearGradientMatrix(tx + grad.x1*w,ty + grad.y1*h, tx + grad.x2*w, ty + grad.y2*h);
		g.beginGradientFill(grad.type, grad.colors, grad.alphas, grad.ratios, mat, grad.spreadMethod, InterpolationMethod.RGB);
	}

	public static function getLinearGradientMatrix(x1:Number, y1:Number, x2:Number, y2:Number):Matrix {
		var w:Number = x2-x1;
		var h:Number = y2-y1;
		var a:Number = Math.atan2(h,w);
		var vl:Number = Math.sqrt( Math.pow(w,2) + Math.pow(h,2) );
		var matr:Matrix = new Matrix();
		matr.createGradientBox(1, 1, 0, 0, 0);
		matr.rotate( a );
		matr.scale( vl, vl );
		matr.translate( x1, y1 );
		return matr;
	}

	private static function setRadialGradientFill(g:Graphics,grad:Object, w:Number, h:Number, tx:Number, ty:Number):void {
		var mat:Matrix = getRadialGradientMatrix(tx + grad.cx*w, ty + grad.cy*h, grad.r*Math.max(w,h), tx + grad.fx*w, ty +grad.fy*h);
		g.beginGradientFill(grad.type, grad.colors, grad.alphas, grad.ratios, mat, grad.spreadMethod, InterpolationMethod.RGB);
	}

	public static function getRadialGradientMatrix(cx:Number, cy:Number, r:Number, fx:Number, fy:Number):Matrix {
		var d:Number = r*2;
		var mat:Matrix = new flash.geom.Matrix();
		mat.createGradientBox( d, d, 0, 0, 0);
		var a:Number = Math.atan2(fy-cy,fx-cx);
		mat.translate( -cx, -cy );
		mat.rotate( -a );
		mat.translate( cx, cy );
		mat.translate( cx-r, cy-r );
		return mat;
	}

	//////////////////////////////////////////
	// Variables Setting
	/////////////////////////////////////////

	public static function setFillColor(hsb:Array):void {
		fillAttributes.hue= hsb[0];
		fillAttributes.saturation= hsb[1];
		fillAttributes.brightness =hsb[2];
	};

	public static function setTextColor(hsb:Array):void {
		textAttributes.hue= hsb[0];
		textAttributes.saturation= hsb[1];
		textAttributes.brightness =hsb[2];
	};

	public static function setFillColor2(hsb:Array):void {
		fillAttributes.gradhue= hsb[0];
		fillAttributes.gradsat= hsb[1];
		fillAttributes.gradbright = hsb[2];
	};

	public static function setStrokeColor(hsb:Array):void {
		strokeAttributes.hue= hsb[0];
		strokeAttributes.saturation= hsb[1];
		strokeAttributes.brightness= hsb[2];
	}

	public static function setThisColorSB(s:Number, b:Number):void {
		if (penAtt == 'fill') {
			if (activeHue =='color1') {
				fillAttributes.alpha = 1;
				fillAttributes.saturation= s;
				fillAttributes.brightness = b;
				fillAttributes['basecolor'] = Color.fromHSV(fillAttributes['hue'], fillAttributes['saturation'], fillAttributes['brightness']);
			} else {
				fillAttributes.gradalpha = 1;
				fillAttributes.gradsat= s;
				fillAttributes.gradbright = b;
				fillAttributes['gradcolor'] = Color.fromHSV(fillAttributes['gradhue'] ,	fillAttributes['gradsat'] ,	fillAttributes['gradbright']);
			}
		} else {
			strokeAttributes.saturation= s;
			strokeAttributes.brightness= b;
			strokeAttributes.basecolor = Color.fromHSV(strokeAttributes['hue'] ,	strokeAttributes['saturation'], strokeAttributes['brightness']);
		}
	}

	public static function getScreenX(o:DisplayObject,c:Class):Number {
		var n:Number = 0;
		while (o != null) {
			n += o.x;
			if (o is c) return n ;
			o = o.parent;
		}
		return n;
	}

	public static function getScreenY(o:DisplayObject,c:Class):Number {
		var n:Number = 0;
		while (o != null) {
			n += o.y;
			if (o is c) return n ;
			o = o.parent;
		}
		return n;
	}

}}
