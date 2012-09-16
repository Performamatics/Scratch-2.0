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
	import flash.geom.*;
 
public class SVGImport {

	public static var fileAttributes:Object;

	private static var loadSVGtags:Object = {
		'g': loadGroup,
		'path': loadType,
		'polygon': loadType,
		'rect': loadType,
		'ellipse': loadType,
		'image': loadImage,
		'circle': loadToEllipse
	};

	private static var fileTags:Object = {
		'x': parseUnit,
		'y': parseUnit,
		'width': parseUnit,
		'height': parseUnit,
		'viewBox': parseViewBox
	};

	private static var isScratchSVG:Boolean;
	private static var gradients:Object;
	private static var clippaths:Object;

	public static function recoverData(xml:XML):Array {
		var cc:XMLList = xml.comments();
		if (cc.length() != 0) {
			var str:String = cc[0].toString();
			isScratchSVG = (str == '<!-- Created with Scratch Costume Editor - http://scratch.mit.edu/ -->');
		} else {
			isScratchSVG = false;
		}
		if (xml.localName() !='svg') {
			trace('not a valid svg file');
			return [];
		}
		headerScan(xml);
		gradients = parseGradients(xml);
		clippaths = parseClipPaths(xml);
		return loadElement(xml);
	}

	private static function headerScan(xml:XML):void {
		fileAttributes = {};
		var attNamesList:XMLList = xml.@*;
		for each (var val:* in attNamesList) {
			var fcn:Function = fileTags[String(val.name())] as Function;
			if (fcn == null) trace('header not parsed for',val.name());
			else fcn.apply(null, [val]);
		}
	}

	private static function parseGradients(svg:XML):Object {
		var result:Object = {};
		var nodes:XMLList = svg..*::*.(localName().toLowerCase()=='lineargradient' || localName().toLowerCase()=='radialgradient');
		for each(var node:XML in nodes) parseGradient(node.@id, svg, result);
		return result;
	}

	private static function parseClipPaths(svg:XML):Object {
		var result:Object = {};
		var nodes:XMLList = svg..*::*.(localName().toLowerCase()=='clippath');
		for each(var node:XML in nodes) parseClipPath(node.@id, svg, result);
		return result;
	}

	private static function parseUnit(val:*):void {fileAttributes[String(val.name())] = getUnit(val);}

	private static function parseClipPath(id:String, svg:XML, storeObject:Object):Object {
		id = (id.indexOf('#') != -1) ? id.replace('#', '') : id ;
		if (storeObject[id]!=null) return storeObject[id];
		var clip:Object = {};
		var xml_grad:XML = svg..*.(attribute('id')==id)[0];
		var fcn:Function;
		for each (var def:XML in xml_grad.*) {
			switch (def.localName().toLowerCase()) {
			case 'use':
				var xlink:Namespace = new Namespace('http://www.w3.org/1999/xlink');
				if (def.@xlink::href.length()>0) {
					clip = parseClipPath(def.@xlink::href, svg, storeObject);
					storeObject[id] = clip;
				}
				break;
			default:
				fcn = loadSVGtags[def.localName()] as Function;
				if (fcn == null) trace('missing load clippath command for',def.localName());
				else {
					clip = fcn.apply(null, [def]);
					storeObject[id] = clip;
				}
				return clip;
			}
		}
		fcn = loadSVGtags[xml_grad.localName()] as Function;
		if (fcn == null) {
			trace('missing load clippath command for',xml_grad.localName());
		} else {
			clip = fcn.apply(null, [xml_grad]);
			storeObject[id] = clip;
		}
		return clip;
	}

	private static function parseViewBox(val:*):void {
		var rect:Rectangle = new Rectangle();
		if (val == null || val == '') return;
		var params:Object = val.split(/\s/);
		fileAttributes[String(val.name())] = new Rectangle(params[0], params[1], params[2], params[3]);
	}

	private static function getUnit(s:String):Number {
		if (s.indexOf('pt') != -1) return Number(s.replace('pt', '')) * 1.25;
		if (s.indexOf('pc') != -1) return Number(s.replace('pc', '')) * 15;
		if (s.indexOf('mm') != -1) return Number(s.replace('mm', '')) * 3.543307;
		if (s.indexOf('cm') != -1) return Number(s.replace('cm', '')) * 35.43307;
		if (s.indexOf('in') != -1) return Number(s.replace('in', '')) * 90;
		if (s.indexOf('px') != -1) return Number(s.replace('px', ''));
		return Number(s);
	}

	private static function loadElement(xml:XML):Array {
		var res:Array = [];
		for each (var node:XML in xml.*) {
			if (node.localName()== null) continue;
			var fcn:Function = loadSVGtags[node.localName()] as Function;
			if (fcn == null) trace('missing load command for', node.localName());
			else res.push(fcn.apply(null, [node]));
		}
		return res;
	}

	private static function loadGroup(xml:XML):SVGData {
		var id:String = xml.@id ? xml.@id : PaintVars.svgroot.getIdFor('g_import')
		var	g:SVGData = new SVGData('g', xml.@id);
		var res:Array = loadElement(xml);
		g.setAttribute('children', res);
		return g;
	}

	private static function loadImage(xml:XML):SVGData {
		var id:String = xml.@id ? xml.@id : PaintVars.svgroot.getIdFor(xml.localName()+'_import')
		var	sdata:SVGData = new SVGData(xml.localName(), id);
		var attNamesList:XMLList = xml.@*;
		for each (var val:* in attNamesList) 	{
			var mykey:String = String(val.name());
			var newValue:* = (attIsNum.indexOf(mykey) < 0) ? String(val) : Number(val);
			sdata.setAttribute(val.name(), newValue);
		}
		if (sdata.getAttribute('clip-path')) {
			var key:String = extractUrlId(sdata.getAttribute('clip-path'));
			sdata.setAttribute('clip-path', clippaths[key]);
		}
		return sdata;
	}

	private static function loadToEllipse(xml:XML):SVGData {
		var sdata:SVGData = loadType(xml);
		sdata.tagName = 'ellipse';
		sdata.setAttribute('rx', sdata.getAttribute('r'));
		sdata.setAttribute('ry', sdata.getAttribute('r'));
		return sdata;
	}

	private static function loadType(xml:XML):SVGData {
		var id:String =xml.@id ? xml.@id : PaintVars.svgroot.getIdFor(xml.localName()+'_import')
		var	sdata:SVGData =new SVGData(xml.localName(), id);
		var attNamesList:XMLList = xml.@*;
		for each (var val:* in attNamesList) 	{
			var mykey:String = String(val.name());
			var newValue:* = (attIsNum.indexOf(mykey) < 0) ? String(val) : Number(val);
			sdata.setAttribute(val.name(), newValue);
		}
		if (isScratchSVG) {
			if (sdata.getAttribute('anchorpoints')) sdata.setAttribute('points', stringToPoints(sdata.getAttribute('anchorpoints')));
			else {
				if (sdata.getAttribute('points')) sdata.setAttribute('points', stringToPoints(sdata.getAttribute('points')));
				else processShapeData(sdata);
			}
		}
		else processShapeData(sdata);
		if (sdata.getAttribute('transform')) parseTransform(sdata, sdata.getAttribute('transform'));
		if (sdata.getAttribute('clip-path')) {
			var key:String = extractUrlId(sdata.getAttribute('clip-path'));
			sdata.setAttribute('clip-path', clippaths[key]);
		}
		parseColorInfo(sdata);
		return sdata;
	}

	private static function processShapeData(sdata:SVGData):void {
		var args:Vector.<String>;
		if (sdata.getAttribute('points')) {
			args = splitNumericArgs(sdata.getAttribute('points'));
			sdata.setAttribute('points', vectorToPoints(args));
		}
		if (sdata.getAttribute('d')) {
			var d:String = sdata.getAttribute('d');
			var res:Array = [];
			var notPoints:Array = ['h', 'v'];
			for each(var cmd:String in d.match(/[A-DF-Za-df-z][^A-Za-df-z]*/g)) {
				var type:String = cmd.charAt(0);
				args = splitNumericArgs(cmd.substr(1));
				var cmddata:Array=[];
				if (notPoints.indexOf(type.toLowerCase()) < 0) cmddata=vectorToPoints(args);
				else cmddata.push(Number(args[0]));
				cmddata.unshift(type);
				res.push(cmddata);
			}
			sdata.setAttribute('commands', getAbsoultePath(res));
			sdata.setAttribute('kind', 'noneditable');
			sdata.setAttribute('d', null);
		}
	}

	private static function vectorToPoints(args:Vector.<String>):Array {
		var res:Array = [];
		for (var i:int=1; i < args.length; i+=2) res.push(new Point(Number(args[i-1]), Number(args[i])));
		return res;
	}

	private static function parseTransform(sdata:SVGData, m:String):void {
		if (m.length == 0) return;
		var transformations:Array = m.match(/(\w+?\s*\([^)]*\))/g);
		if (! (transformations is Array)) return;
		for (var i:int = transformations.length - 1; i >= 0; i--) {
			var parts:Array = /(\w+?)\s*\(([^)]*)\)/.exec(transformations[i]);
			if (! (parts is Array)) return;
			var name:String = parts[1].toLowerCase();
			var args:Vector.<String> = splitNumericArgs(parts[2]);
			switch (name) {
			case 'matrix':
				trace('element has a matrix that is being ignored');
				break;
			case 'translate':
				var pt:Point = new Point(Number(args[0]), args.length > 1 ? Number(args[1]) : Number(args[0]));
				sdata.translateTo(pt);
				break;
			case 'scale' :
				sdata.applyScale(Number(args[0]), args.length > 1 ? Number(args[1]) : Number(args[0]));
				break;
			case 'rotate' :
				if (args.length > 1) {
					var mat:Matrix = new Matrix();
					var tx:Number = args.length > 1 ? Number(args[1]) : 0;
					var ty:Number = args.length > 2 ? Number(args[2]) : 0;
					mat.translate(-tx, -ty);
					mat.rotate(Number(args[0]) *Turtle.DEGTOR);
					mat.translate(tx, ty);
				}
				else mat.rotate(Number(args[0]) *Turtle.DEGTOR);
				sdata.rotateFromPoint(mat,Number(args[0]));
				break;
			case 'skewx':
				trace('skewx is being ignored');
				break;
			case 'skewy' :
				trace('skewy is being ignored');
				break;
			}
		}
	}

	private static function parseColorInfo(sdata:SVGData):void {
		for each(var style:String in SVGStyles) {
			if (!sdata.getAttribute(style)) continue;
			switch (style) {
			case 'fill':
			case 'stroke':
				sdata.setAttribute(style, getColorValue(sdata.getAttribute(style)));
				if (isGradient(sdata.getAttribute(style))) sdata.setGradientUnits();
				break;
			case 'opacity':
			case 'stroke-width':
			case 'fill-opacity':
			case 'stroke-opacity':
				sdata.setAttribute(style, getNumberFromString(sdata.getAttribute(style)));
				break;
			default:
				break;
			}
		}
	}

	public static function isGradient(s:String):Boolean { return s.indexOf('[object Object]') >= 0 }

	private static function getNumberFromString(str:String):Number{
		var s:Array = str.split(' ');
		var n:Number;
		for (var i:int = 0; i < s.length; i++) {
			n = Number(s[i]);
			if (!isNaN(n)) return n;
		}
		return 1;
	}

	private static function splitNumericArgs(input:String):Vector.<String> {
		var returnData:Vector.<String> = new Vector.<String>();
		var matchedNumbers:Array = input.match(/(?:\+|-)?\d+(?:\.\d+)?(?:e(?:\+|-)?\d+)?/g);
		for each(var numberString:String in matchedNumbers) returnData.push(numberString);
		return returnData;
	}

	private static function getColorValue(s:String):* {
		if (s.indexOf('url')>-1) return gradients[extractUrlId(s)];
		if (s == null) return 'none';
		if (s == 'none' || s=='') {
			return 'none';
		} else if (s.charAt(0)=='#') {
			s = s.substring(1);
			if (s.length<6) s = s.charAt(0)+s.charAt(0)+s.charAt(1)+s.charAt(1)+s.charAt(2)+s.charAt(2);
			return new uint('0x' + s);
		} else if (s.indexOf('(')>-1) {
			s = /\((.*?)\)/.exec(s)[1];
			var args:Vector.<String> = splitNumericArgs(s);
			return uint(args[0]) << 16 | uint(args[1]) << 8 | uint(args[2]);
		} else {
			return getColorByName(s);
		}
	}

	private static function extractUrlId(url:String):String {
		return /url\s*\(#(.*?)\)/.exec(url)[1];
	}

	private static function stringToPoints (str:String):Array {
		var list:Array = str.split(' ');
		var res:Array = [];
		for (var i:int=0; i < list.length; i++) {
		var pt:Array = list[i].split(',');
		if (pt.length < 2) continue;
		res.push(new Point(pt[0], pt[1]));
		}
		return res;
	}

	private static const gradientsAttributes:Object = {
		'linear': ['x1', 'y1', 'x2', 'y2'],
		'radial': ['cx', 'cy', 'r', 'fx', 'fy']
	}

	private static const attributeTable:Object = {
		'path': ['d', 'kind'],
		'image': ['x', 'y', 'width', 'height', 'xlink:href'],
		'ellipse': ['cx', 'cy', 'rx', 'ry' ],
		'rect': ['x', 'y', 'width', 'height'],
		'text': ['x', 'y', 'font-size', 'font-family', 'font-style', 'font-weight', 'text-anchor', 'xml:space'],
		'polyline': ['points'],
		'polygon': ['points']
	}

	private static const attIsNum:Array = [
		'x', 'y', 'width', 'height', 'cx', 'cy', 'rx', 'ry', 'opacity'
	];

	public static const attributePenTable:Object = {
		'path': ['fill', 'stroke', 'stroke-width', 'stroke-linecap'],
		'ellipse': ['fill', 'stroke', 'stroke-width', 'stroke-linecap'],
		'rect': ['fill', 'stroke', 'stroke-width', 'stroke-linecap'],
		'text': ['fill'],
		'image': [],
		'polyline':['fill', 'stroke', 'stroke-width', 'stroke-linecap'],
		'polygon': ['fill', 'stroke', 'stroke-width', 'stroke-linecap']
	}

	private static const SVGStyles:Array = [
		'display', 'visibility', 'opacity', 'fill',
		'fill-opacity', 'fill-rule', 'stroke', 'stroke-opacity',
		'stroke-width', 'stroke-linecap', 'stroke-linejoin',
		'stroke-dasharray', 'stroke-dashoffset', 'stroke-dashalign',
		'font-size', 'font-family', 'font-weight', 'text-anchor', 'dominant-baseline'
	];

	/////////////////////////////////////////////////////////////
	// Gradients I/O
	/////////////////////////////////////////////////////////////

	private static function parseGradient(id:String, svg:XML, storeObject:Object):Object {
		id = (id.indexOf('#') != -1) ? id.replace('#', '') : id ;
		if (storeObject[id]!=null) return storeObject[id];
		var xml_grad:XML = svg..*.(attribute('id')==id)[0];
		if (xml_grad == null) return null;
		var grad:Object = {};
		var i:String;
		switch (xml_grad.localName().toLowerCase()) {
		case 'lineargradient':
			for (i in PaintVars.vertical) grad[i] = PaintVars.vertical[i];
			break;
		case 'radialgradient' :
			for (i in PaintVars.radialgradient) grad[i] = PaintVars.radialgradient[i];
			break;
		}
		//inherits the href reference
		var xlink:Namespace = new Namespace('http://www.w3.org/1999/xlink');
		if (xml_grad.@xlink::href.length()>0) {
		var baseGradient:Object = parseGradient(xml_grad.@xlink::href, svg, storeObject);
		for (i in baseGradient) grad[i] = baseGradient[i];
		}
		if ('@gradientUnits' in xml_grad) grad.gradientUnits = xml_grad.@gradientUnits;
		else grad.gradientUnits = 'objectBoundingBox';
		if ('@gradientTransform' in xml_grad) grad.transform = parseTransformation(xml_grad.@gradientTransform);
		switch (grad.type) {
		case GradientType.LINEAR :
			if ('@x1' in xml_grad) grad.x1 = xml_grad.@x1;
			else grad.x1 = 0;
			if ('@y1' in xml_grad) grad.y1 = xml_grad.@y1;
			else if (grad.y1 == null) grad.y1 = 0;
			if ('@x2' in xml_grad) grad.x2 = xml_grad.@x2;
			else if (grad.x2 == null) grad.x2 = 1;
			if ('@y2' in xml_grad) grad.y2 = xml_grad.@y2;
			else if (grad.y2 == null)
			grad.y2 = 0;
			break;
		case GradientType.RADIAL:
			if ('@cx' in xml_grad) grad.cx = xml_grad.@cx;
			else if (grad.cx==null) grad.cx = 0.5;
			if ('@cy' in xml_grad) grad.cy = xml_grad.@cy;
			else if (grad.cy==null) grad.cy = 0.5;
			if ('@r' in xml_grad) grad.r = xml_grad.@r;
			else grad.r = 0.5;
			if ('@fx' in xml_grad) grad.fx = xml_grad.@fx;
			else grad.fx = grad.cx;
			if ('@fy' in xml_grad) grad.fy = xml_grad.@fy;
			else grad.fy = grad.cy;
			break;
		}

		switch (xml_grad.@spreadMethod) {
		case 'pad' : grad.spreadMethod = SpreadMethod.PAD; break;
		case 'reflect' : grad.spreadMethod = SpreadMethod.REFLECT; break;
		case 'repeat' : grad.spreadMethod = SpreadMethod.REPEAT; break;
		default: grad.spreadMethod = SpreadMethod.PAD; break
		}

		if (grad.colors == null) grad.colors = new Array();
		if (grad.alphas==null) grad.alphas = new Array();
		if (grad.ratios==null) grad.ratios = new Array();
		for each(var stop:XML in xml_grad.*::stop) {
			if ('@stop-opacity' in stop) grad.alphas.push((stop.@['stop-opacity'] != null) ? stop.@['stop-opacity'] * 100 : 100);
			if ('@stop-color' in stop) grad.colors.push(getColorValue(stop.@['stop-color']));
			// color and opacity in the style def
			if ('@style' in stop) grad= addgradStopFromStyle(stop, grad);
			var s:String = stop.@offset;
			var offset:Number = (s.indexOf('%') != -1) ? Number(s.replace('%', '')) : Number (s);
			if (String(stop.@offset).indexOf('%') > -1) offset/=100;
			grad.ratios.push( offset*255 );
		}
		storeObject[id] = grad;
		return grad;
	}

	private static function addgradStopFromStyle(stop:XML, grad:Object):Object {
		var list:Array= (stop.@style).split(';');
		var pp:Object= {};
		for each(var prop:String in list) {
			var split:Array = prop.split(':');
			if (split.length==2) pp[String(split[0])]= split[1];
		}
		grad.colors.push(pp['stop-color'] ? getColorValue(pp['stop-color']) : 0);
		grad.alphas.push(pp['stop-opacity'] ? pp['stop-opacity'] : 1);
		return grad;
	}

	private static function parseTransformation(m:String):Matrix {
		if (m.length == 0) return new Matrix();
		var transformations:Array = m.match(/(\w+?\s*\([^)]*\))/g);
		var mat:Matrix = new Matrix();
		if (transformations is Array) {
			for (var i:int = transformations.length - 1; i >= 0; i--) {
				var parts:Array = /(\w+?)\s*\(([^)]*)\)/.exec(transformations[i]);
				if (parts is Array) {
					var name:String = parts[1].toLowerCase();
					var args:Vector.<String> = splitNumericArgs(parts[2]);
					if (name == 'matrix') return new Matrix(Number(args[0]), Number(args[1]), Number(args[2]), Number(args[3]), Number(args[4]), Number(args[5]));
					switch (name) {
					case 'translate' :
						mat.translate(Number(args[0]), args.length > 1 ? Number(args[1]) : Number(args[0]));
						break;
					case 'scale' :
						mat.scale(Number(args[0]), args.length > 1 ? Number(args[1]) : Number(args[0]));
						break;
					case 'rotate' :
						if (args.length > 1) {
							var tx:Number = args.length > 1 ? Number(args[1]) : 0;
							var ty:Number = args.length > 2 ? Number(args[2]) : 0;
							mat.translate(-tx, -ty);
							mat.rotate(Number(args[0])*Turtle.DEGTOR);
							mat.translate(tx, ty);
						}
						else mat.rotate(Number(args[0])*Turtle.DEGTOR);
						break;
					case 'skewx' :
						var skewXMatrix:Matrix = new Matrix();
						skewXMatrix.c = Math.tan(Number(args[0])*Turtle.DEGTOR);
						mat.concat(skewXMatrix);
						break;
					case 'skewy' :
						var skewYMatrix:Matrix = new Matrix();
						skewYMatrix.b = Math.tan(Number(args[0])*Turtle.DEGTOR);
						mat.concat(skewYMatrix);
						break;
					}
				}
			}
		}
		return mat;
	}

	////////////////////////////////////////////////////////////
	// Transform to absolute paths
	////////////////////////////////////////////////////////////

	private	static var curveoptions:Array = ['C', 'c', 's', 'S'];
	private	static var qcurveoptions:Array = ['Q', 'q', 'T', 't'];
	private static var acurve:Boolean = false;
	private static var aqcurve:Boolean = false;
	private static var lastcxy:Point;
	private static var endp:Point;
	private static var startp:Point;

	private static var dispatchAbsouluteCmd:Object = {
		'M': absoulteMove, 'm': relativeMove,
		'L': absoluteLine, 'l': relativeLine,
		'H': absoluteHLine, 'h': relativeHLine,
		'V': absoluteVLine, 'v': relativeVLine,
		'C': absoluteCurve, 'c': relativeCurve,
		'S': absoluteSmooth, 's': relativeSmooth,
		'Q': absoluteQCurve, 'q': relativeQCurve,
		'T': absoluteQSmooth, 't': relativeQSmooth,
		'Z': closePath, 'z': closePath
	};

	private static function getAbsoultePath(list:Array):Array {
		var res:Array = [];
		for (var i:int =0 ; i < list.length; i++) res.push(getAbsoluteCommand(list[i]));
		return res;
	}

	private static function getAbsoluteCommand(cmd:Array):Array {
		var key:String = cmd[0];
		acurve = curveoptions.indexOf(key) > -1 ;
		aqcurve = qcurveoptions.indexOf(key) > -1 ;
		return (dispatchAbsouluteCmd[key] as Function).apply(null, [cmd]);
	}

	// Moves

	private static function absoulteMove(cmd:Array):Array {
		endp = cmd[1];
		startp = endp;
		return cmd;
	}

	private static function relativeMove(cmd:Array):Array {
		endp = xPoint.vsum(endp, cmd[1]);
		startp = endp;
		return ['M', endp];
	}

	// Lines

	private static function closePath(cmd:Array):Array {
		endp =startp;
		return cmd;
	}

	private static function absoluteLine(cmd:Array):Array {
		endp =cmd[1];
		return cmd;
	}

	private static function relativeLine(cmd:Array):Array {
		endp = xPoint.vsum(endp, cmd[1]);
		return ['L', endp];
	}

	private static function absoluteHLine(cmd:Array):Array {
		var dx:Number = cmd[1];
		endp = new Point(dx, endp.y);
		return cmd;
	}

	private static function relativeHLine(cmd:Array):Array {
		var dx:Number = endp.x + cmd[1];
		endp = new Point(dx, endp.y);
		return ['H', dx];
	}

	private static function absoluteVLine(cmd:Array):Array {
		var dy:Number = cmd[1];
		endp = new Point(endp.x, dy);
		return cmd;
	}

	private static function relativeVLine(cmd:Array):Array {
		var dy:Number = endp.y + cmd[1];
		endp = new Point(endp.x, dy);
		return ['V', dy];
	}

	// Curves - Cubic

	private static function absoluteCurve(cmd:Array):Array {
		lastcxy = cmd[2];
		endp=cmd[3];
		return cmd;
	}

	private static function relativeCurve(cmd:Array):Array {
		var c1:Point = xPoint.vsum(endp, cmd[1]);
		var c2:Point = xPoint.vsum(endp, cmd[2]);
		lastcxy = c2;
		var c3:Point = xPoint.vsum(endp, cmd[3]);
		endp=c3;
		return ['C', c1,c2,c3];
	}

	private static function absoluteSmooth(cmd:Array):Array {
		var c2:Point = cmd[1];
		endp=cmd[2];
		lastcxy = c2;
		return cmd;
	}

	private static function relativeSmooth(cmd:Array):Array {
		var c2:Point = xPoint.vsum(endp, cmd[1]);
		var c3:Point = xPoint.vsum(endp, cmd[2]);
		endp=c3;
		lastcxy = c2;
		return ['S', c2,c3];
	}

	// Curves - Quadratic

	private static function absoluteQCurve(cmd:Array):Array {
		endp = cmd[2];
		lastcxy = cmd[1];
		return cmd;
	}

	private static function relativeQCurve(cmd:Array):Array {
		var c1:Point = xPoint.vsum(endp, cmd[1]);
		var endp:Point = xPoint.vsum(endp, cmd[2]);
		lastcxy = c1;
		return ['Q', c1, endp];
	}

	private static function absoluteQSmooth(cmd:Array):Array {
		var c1:Point = aqcurve ? xPoint.vsum (endp,xPoint.vdiff(endp, lastcxy)) : endp;
		endp = cmd[2];
		lastcxy = c1;
		return cmd;
	}

	private static function relativeQSmooth(cmd:Array):Array {
		var c1:Point = aqcurve ? xPoint.vsum (endp,xPoint.vdiff(endp, lastcxy)) : endp;
		var endp:Point = xPoint.vsum(endp, cmd[1]);
		lastcxy = c1;
		return ['T', endp];
	}

	// Colors

	private static function getColorByName(name:String):int { return namedColors[name.toLowerCase()] }

	private static var namedColors:Object = {
		'aliceblue': 0xF0F8FF,
		'antiquewhite': 0xFAEBD7,
		'aqua': 0x00FFFF,
		'aquamarine': 0x7FFFD4,
		'azure': 0xF0FFFF,
		'beige': 0xF5F5DC,
		'bisque': 0xFFE4C4,
		'black': 0x000000,
		'blanchedalmond': 0xFFEBCD,
		'blue': 0x0000FF,
		'blueviolet': 0x8A2BE2,
		'brown': 0xA52A2A,
		'burlywood': 0xDEB887,
		'cadetblue': 0x5F9EA0,
		'chartreuse': 0x7FFF00,
		'chocolate': 0xD2691E,
		'coral': 0xFF7F50,
		'cornflowerblue': 0x6495ED,
		'cornsilk': 0xFFF8DC,
		'crimson': 0xDC143C,
		'cyan': 0x00FFFF,
		'darkblue': 0x00008B,
		'darkcyan': 0x008B8B,
		'darkgoldenrod': 0xB8860B,
		'darkgray': 0xA9A9A9,
		'darkgrey': 0xA9A9A9,
		'darkgreen': 0x006400,
		'darkkhaki': 0xBDB76B,
		'darkmagenta': 0x8B008B,
		'darkolivegreen': 0x556B2F,
		'darkorange': 0xFF8C00,
		'darkorchid': 0x9932CC,
		'darkred': 0x8B0000,
		'darksalmon': 0xE9967A,
		'darkseagreen': 0x8FBC8F,
		'darkslateblue': 0x483D8B,
		'darkslategray': 0x2F4F4F,
		'darkslategrey': 0x2F4F4F,
		'darkturquoise': 0x00CED1,
		'darkviolet': 0x9400D3,
		'deeppink': 0xFF1493,
		'deepskyblue': 0x00BFFF,
		'dimgray': 0x696969,
		'dimgrey': 0x696969,
		'dodgerblue': 0x1E90FF,
		'firebrick': 0xB22222,
		'floralwhite': 0xFFFAF0,
		'forestgreen': 0x228B22,
		'fuchsia': 0xFF00FF,
		'gainsboro': 0xDCDCDC,
		'ghostwhite': 0xF8F8FF,
		'gold': 0xFFD700,
		'goldenrod': 0xDAA520,
		'gray': 0x808080,
		'grey': 0x808080,
		'green': 0x008000,
		'greenyellow': 0xADFF2F,
		'honeydew': 0xF0FFF0,
		'hotpink': 0xFF69B4,
		'indianred': 0xCD5C5C,
		'indigo': 0x4B0082,
		'ivory': 0xFFFFF0,
		'khaki': 0xF0E68C,
		'lavender': 0xE6E6FA,
		'lavenderblush': 0xFFF0F5,
		'lawngreen': 0x7CFC00,
		'lemonchiffon': 0xFFFACD,
		'lightblue': 0xADD8E6,
		'lightcoral': 0xF08080,
		'lightcyan': 0xE0FFFF,
		'lightgoldenrodyellow': 0xFAFAD2,
		'lightgray': 0xD3D3D3,
		'lightgrey': 0xD3D3D3,
		'lightgreen': 0x90EE90,
		'lightpink': 0xFFB6C1,
		'lightsalmon': 0xFFA07A,
		'lightseagreen': 0x20B2AA,
		'lightskyblue': 0x87CEFA,
		'lightslategray': 0x778899,
		'lightslategrey': 0x778899,
		'lightsteelblue': 0xB0C4DE,
		'lightyellow': 0xFFFFE0,
		'lime': 0x00FF00,
		'limegreen': 0x32CD32,
		'linen': 0xFAF0E6,
		'magenta': 0xFF00FF,
		'maroon': 0x800000,
		'mediumaquamarine': 0x66CDAA,
		'mediumblue': 0x0000CD,
		'mediumorchid': 0xBA55D3,
		'mediumpurple': 0x9370D8,
		'mediumseagreen': 0x3CB371,
		'mediumslateblue': 0x7B68EE,
		'mediumspringgreen': 0x00FA9A,
		'mediumturquoise': 0x48D1CC,
		'mediumvioletred': 0xC71585,
		'midnightblue': 0x191970,
		'mintcream': 0xF5FFFA,
		'mistyrose': 0xFFE4E1,
		'moccasin': 0xFFE4B5,
		'navajowhite': 0xFFDEAD,
		'navy': 0x000080,
		'oldlace': 0xFDF5E6,
		'olive': 0x808000,
		'olivedrab': 0x6B8E23,
		'orange': 0xFFA500,
		'orangered': 0xFF4500,
		'orchid': 0xDA70D6,
		'palegoldenrod': 0xEEE8AA,
		'palegreen': 0x98FB98,
		'paleturquoise': 0xAFEEEE,
		'palevioletred': 0xD87093,
		'papayawhip': 0xFFEFD5,
		'peachpuff': 0xFFDAB9,
		'peru': 0xCD853F,
		'pink': 0xFFC0CB,
		'plum': 0xDDA0DD,
		'powderblue': 0xB0E0E6,
		'purple': 0x800080,
		'red': 0xFF0000,
		'rosybrown': 0xBC8F8F,
		'royalblue': 0x4169E1,
		'saddlebrown': 0x8B4513,
		'salmon': 0xFA8072,
		'sandybrown': 0xF4A460,
		'seagreen': 0x2E8B57,
		'seashell': 0xFFF5EE,
		'sienna': 0xA0522D,
		'silver': 0xC0C0C0,
		'skyblue': 0x87CEEB,
		'slateblue': 0x6A5ACD,
		'slategray': 0x708090,
		'slategrey': 0x708090,
		'snow': 0xFFFAFA,
		'springgreen': 0x00FF7F,
		'steelblue': 0x4682B4,
		'tan': 0xD2B48C,
		'teal': 0x008080,
		'thistle': 0xD8BFD8,
		'tomato': 0xFF6347,
		'turquoise': 0x40E0D0,
		'violet': 0xEE82EE,
		'wheat': 0xF5DEB3,
		'white': 0xFFFFFF,
		'whitesmoke': 0xF5F5F5,
		'yellow': 0xFFFF00,
		'yellowgreen': 0x9ACD32
	}

}}
