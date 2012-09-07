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
	import flash.utils.ByteArray;
	import util.*;

public class SVGExport {

	private static var defsnode:XML;
	private static var rootxml:XML;

	public static function svgString(svgRoot:SVGRoot, w:Number, h:Number):String {
		XML.ignoreComments = false;
		XML.ignoreWhitespace = false;
		rootxml =
			<svg
				xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'
				xmlns:ev='http://www.w3.org/2001/xml-events'>
				<!-- Created with Scratch Costume Editor - http://scratch.mit.edu/ -->
			</svg>;
		rootxml.@x = '0px';
		rootxml.@y = '0px';
		rootxml.@width = w + 'px';
		rootxml.@height = h + 'px';
		rootxml.@viewBox = '0 0 ' + w + ' ' + h;
		defsnode = null;
		appendDataToXML(svgRoot, rootxml);
		return rootxml.toXMLString();
	}

	private static function appendDataToXML(spr:Sprite, xml:XML):void {
		for (var i:int=0;i< spr.numChildren;i++) {
			var elem:PaintObject= spr.getChildAt(i) as PaintObject;
			if (!elem) continue;
			var oxml:XML;
			if (elem.tagName == 'text') { // adding text tags is strange....
				elem.setAttribute('xml:space', 'preserve');
				var txt:String = elem.getAttribute('textfield').text;
				xml.text=txt;
				var pos:int = xml.child('text').length() -1;
				oxml = xml.child('text')[pos];
			} else {
				oxml = new XML(<placeholder> </placeholder>);
				oxml.setName(elem.tagName);
			}
			oxml.@id = elem.id;
			var fcn:Function = saveSVGtags[elem.tagName] as Function;
			if (fcn == null) trace('missing command for', elem.tagName);
			else fcn.apply(null, [oxml, elem]);
			if (elem.getAttribute('clip-path')) oxml.@['clip-path'] = saveClipPath(elem.getAttribute('clip-path'));
			if (elem.tagName != 'text') xml.appendChild(oxml);
		}
	}

	private static function saveClipPath(svg:SVGData):String {
		var clipname:String = svg.id;
		if (!defsnode) {
			defsnode = new XML(<defs> </defs>);
			rootxml.appendChild(defsnode);
		}
		var clippath:XML = new XML(<clipPath> </clipPath>);
		clippath.@id = clipname;
		var xml:XML = new XML(<placeholder> </placeholder>);
		xml.setName(svg.tagName);
		xml.@id = svg.id;

		var fcn:Function = saveSVGtags[svg.tagName] as Function;
		if (fcn == null) {
			trace('missing command for', xml.tagName);
		} else {
			var po:PaintObject = new PaintObject(svg.tagName, svg.id, svg);
			fcn.apply(null, [xml, po]);
		}
		clippath.appendChild(xml);
		defsnode.appendChild(clippath);
		return 'url(#' + clipname+ ')';
	}

	////////////////////////////////////////////////////////////
	// Save dispatch tables: add an entry for each SVG Type
	////////////////////////////////////////////////////////////

	private static const saveSVGtags:Object = {
		'ellipse': standardXML,
		'g': groupXML,
		'image': imageXML,
		'path': pathXML,
		'polygon': polygonXML,
		'rect': standardXML,
		'text': textXML
	};

	private static function groupXML(xml:XML, elem:PaintObject):void { appendDataToXML(elem, xml) }

	private static function imageXML(xml:XML, elem:PaintObject):void{
		standardXML(xml, elem);
		var pixels:ByteArray = new PNGMaker().encode(elem.getAttribute('bitmapdata'));
		xml.@['xlink:href'] = 'data:image/png;base64,' + Base64Encoder.encode(pixels);
	}

	private static function pathXML(xml:XML, elem:PaintObject):void{
		standardXML(xml, elem);
		xml.@d = calculatePathCommands(elem);
		if (elem.getAttribute('points')) xml.@anchorpoints =stringifyPoints(elem.getAttribute('points'));
		xml.@kind =elem.getAttribute('kind');
	}

	private static function polygonXML(xml:XML, elem:PaintObject):void{
		standardXML(xml, elem);
		xml.@points =stringifyPoints(elem.getAttribute('points'));
	}

	private static function standardXML(xml:XML, elem:PaintObject):void{
		var list:Array = attributeTable[elem.tagName];
		for (var s:String in list) xml.@[list[s]] = elem.getAttribute(list[s]);
		xml.@opacity = elem.getAttribute('opacity');
		if (elem.tagName != 'image') {
			var colordata:Object = getSVGcolor(elem);
			for (var i:String in colordata)xml.@[i] = colordata[i];
		}
		if (!elem.hasNoMatrices()) xml.@transform = getMatricesToXML(elem);
	}

	private static function textXML(xml:XML, elem:PaintObject):void{
		standardXML(xml, elem);
		var dy:Number = elem.getAttribute('textfield').textHeight;
		xml.@y = elem.getAttribute('y') + dy;
	}

	/////////////////////////////////////
	// Elements
	/////////////////////////////////////

	private static function stringifyPoints(list:Array):String{
		var str:String ='';
		for (var i:int=0; i < list.length ; i++) {
			var p:Point = list[i];
			str += p.x+','+p.y+' ';
		}
		return str;
	}

	private static function calculatePathCommands(elem:PaintObject):String{
		if (elem.getAttribute('commands')) return getDattribute(elem.getAttribute('commands'));
		 return (elem.getAttribute('kind') != 'editable') ?
					getRectangularPath(elem.getAttribute('points')) :
					getBezierPath(elem.getAttribute('points'));
	}

	private static function getDattribute(plist:Array):String {
		var d:String = '';
		for (var j:int =0 ; j < plist.length; j++) {
			var cmd:Array = plist[j];
			var res:Array = [];
			for (var i:int = 0; i < cmd.length;i++) {
				var o:* = cmd[i];
				if (o is Point) {
					res.push(o.x);
					res.push(o.y);
				} else {
					if (o is Number) res.push (o);
					else var key:String = o.toString();
				}
			}
			d += key+res.toString()+' ';
		}
		if (d.substring(d.length-1,d.length) == ' ') d = d.substring(0, d.length-1);
		return d;
	}

	private static function getRectangularPath(plist:Array):String {
		var first:Point = plist[0];
		var d:String = 'M' + first.x + ',' + first.y;
		for (var i:int = 1; i < plist.length; i++) d += lineSeg(plist[i-1], plist[i]);
		d+='z';
		return d;
	}

	private static function getBezierPath(plist:Array):String{
		var first:Point = plist[0];
		var d:String = 'M' + first.x + ',' + first.y;
		if (plist.length < 3 ) d += lineSeg(plist[0], plist[1]);
		else {
			for (var i:int = 1; i < plist.length - 1; i++) d += curveSeg(plist[i-1], plist[i], plist[i+1]);
			var lastpoint:Point = plist[plist.length-1];
			var farilyclose:Boolean = xPoint.vlen(xPoint.vdiff(lastpoint,first)) < 10;
			d += (farilyclose) ? curveSeg(plist[plist.length-2], lastpoint,first) :
						curveSeg(plist[plist.length-2], lastpoint,lastpoint);
			if (farilyclose) d+='z';
		}
		return d;
	}

	private static function lineSeg (before:Point, here:Point):String{
		var d:Point = xPoint.vdiff(here, before);
		var pt:String = 'l'+d.x +','+d.y;
		return pt;
	}

	private static function curveSeg(before:Point, here:Point, after:Point):String{
		var l1:Number = xPoint.vlen(xPoint.vdiff(before, here));
		var l2:Number = xPoint.vlen(xPoint.vdiff(here, after));
		var l3:Number = xPoint.vlen(xPoint.vdiff(before, after));
		var l:Number = l3/ (l1 + l2);
		var min:Number = Math.min(l1,l2);
		var endpoint:Point = xPoint.vdiff(here, before);
		var c:Point = xPoint.vscale (xPoint.controlPoint(before, here, after), l* l*min * 0.666);
		var c2:Point = xPoint.vdiff(endpoint, c);
		var pt:String = 's'+ c2.x+','+c2.y+','+endpoint.x+','+endpoint.y;
		return pt;
	}

	/////////////////////////////////////
	// Transforms
	/////////////////////////////////////

	private static function getMatricesToXML(elem:PaintObject):String{
		var angle:Number = elem.getAttribute('angle');
		if (angle == 0) return '';
		var pt:Point = elem.getBoxCenter();
		var rotdata:Array = [angle, pt.x, pt.y];
		return 'rotate('+ rotdata.toString() +')';
	}

	/////////////////////////////////////
	// Colors and Gradients
	/////////////////////////////////////

	private static function	getSVGcolor(elem:PaintObject):Object {
		var res:Object= {};
		if (elem.getAttribute('stroke') != null) {
			res ['stroke'] = (elem.tagName == 'text' ) ? 'none' : rgbToString(elem.getAttribute('stroke')) ;
			if (res['stroke'] != 'none') {
				if (elem.getAttribute('stroke-width') && !isNaN(elem.getAttribute('stroke-width'))) res ['stroke-width'] = elem.getAttribute('stroke-width');
				res['stroke-linecap'] = 'round';
			}
		}
		var fd:* = elem.getAttribute('fill');
		if (fd is Number) res ['fill'] = rgbToString(elem.getAttribute('fill'));
		else {
			if (fd =='none') res ['fill']= 'none';
			else res['fill'] = getGradientUrl(fd, elem);
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

	private static function getGradientUrl(grad:Object, elem:PaintObject):String{
		var gname:String = grad.type+'_'+elem.id;
		if (!defsnode) {
			defsnode = new XML(<defs> </defs>);
			rootxml.appendChild(defsnode);
		}
		var oxml:XML = new XML(<placeholder> </placeholder>);
		oxml.setName(grad.type+'Gradient');
		oxml.@id = gname;
		var list:Array = gradientsAttributes[grad.type];
		for (var s:String in list) oxml.@[list[s]] = grad[list[s]];
		for (var i:int=0; i < grad.colors.length ;i++) {
			var gstop:XML = new XML(<stop></stop>);
			gstop.@offset = grad.ratios[i] / 255;
			gstop.@['stop-color'] = rgbToString(grad.colors[i]);
			gstop.@['stop-opacity'] = grad.alphas[i] / 100;
			oxml.appendChild(gstop);
		}
		defsnode.appendChild(oxml);
		return 'url(#' + gname+ ')';
	}

	private static function rgbToString (color:uint):String {
		var r:int = (color >> 16) & 255;
		var g:int = (color >> 8) & 255;
		var b:int = color & 255;
		return '#' + getHex(r) + getHex(g) + getHex(b);
	}

	private static function getHex(n:int):String {
		var hex:String = n.toString(16);
		if (hex.length == 1) return '0' + hex;
		return hex;
	}

	////////////////////////////////////////////////////////////
	// Convert to absolute paths
	////////////////////////////////////////////////////////////

	private	static const curveoptions:Array = ['C', 'c', 's', 'S'];
	private	static const qcurveoptions:Array = ['Q', 'q', 'T', 't'];

	private static var acurve:Boolean = false;
	private static var aqcurve:Boolean = false;
	private static var startp:Point;
	private static var endp:Point;
	private static var lastcxy:Point;

	private static const dispatchAbsouluteCmd:Object = {
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

	private static function getAbsoultePath(list:Array):Array{
		var res:Array = [];
		for (var i:int =0 ; i < list.length; i++) res.push(getAbsoluteCommand(list[i]));
		return res;
	}

	private static function getAbsoluteCommand(cmd:Array):Array{
		var key:String = cmd[0];
		acurve = curveoptions.indexOf(key) > -1;
		aqcurve = qcurveoptions.indexOf(key) > -1;
		return (dispatchAbsouluteCmd[key] as Function).apply(null, [cmd]);
	}

	// Moves

	private static function absoulteMove(cmd:Array):Array{
		endp = cmd[1];
		startp = endp;
		return cmd;
	}

	private static function relativeMove(cmd:Array):Array{
		endp = xPoint.vsum(endp, cmd[1]);
		startp = endp;
		return ['M', endp];
	}

	// Lines

	private static function closePath(cmd:Array):Array{
		endp =startp;
		return cmd;
	}

	private static function absoluteLine(cmd:Array):Array{
		endp =cmd[1];
		return cmd;
	}

	private static function relativeLine(cmd:Array):Array{
		endp = xPoint.vsum(endp, cmd[1]);
		return ['L', endp];
	}

	private static function absoluteHLine(cmd:Array):Array{
		var dx:Number = cmd[1];
		endp = new Point(dx, endp.y);
		return cmd;
	}

	private static function relativeHLine(cmd:Array):Array{
		var dx:Number = endp.x + cmd[1];
		endp = new Point(dx, endp.y);
		return ['H', dx];
	}

	private static function absoluteVLine(cmd:Array):Array{
		var dy:Number = cmd[1];
		endp = new Point(endp.x, dy);
		return cmd;
	}

	private static function relativeVLine(cmd:Array):Array{
		var dy:Number = endp.y + cmd[1];
		endp = new Point(endp.x, dy);
		return ['V', dy];
	}

	// Curves - Cubic

	private static function absoluteCurve(cmd:Array):Array{
		lastcxy = cmd[2];
		endp=cmd[3];
		return cmd;
	}

	private static function relativeCurve(cmd:Array):Array{
		var c1:Point = xPoint.vsum(endp, cmd[1]);
		var c2:Point = xPoint.vsum(endp, cmd[2]);
		lastcxy = c2;
		var c3:Point = xPoint.vsum(endp, cmd[3]);
		endp=c3;
		return ['C', c1,c2,c3];
	}

	private static function absoluteSmooth(cmd:Array):Array{
		var c2:Point = cmd[1];
		endp=cmd[2];
		lastcxy = c2;
		return cmd;
	}

	private static function relativeSmooth(cmd:Array):Array{
		var c2:Point = xPoint.vsum(endp, cmd[1]);
		var c3:Point = xPoint.vsum(endp, cmd[2]);
		endp=c3;
		lastcxy = c2;
		return ['S', c2,c3];
	}

	// Curves - Quadratic

	private static function absoluteQCurve(cmd:Array):Array{
		endp = cmd[2];
		lastcxy = cmd[1];
		return cmd;
	}

	private static function relativeQCurve(cmd:Array):Array{
		var c1:Point = xPoint.vsum(endp, cmd[1]);
		var endp:Point = xPoint.vsum(endp, cmd[2]);
		lastcxy = c1;
		return ['Q', c1, endp];
	}

	private static function absoluteQSmooth(cmd:Array):Array{
		var c1:Point = aqcurve ? xPoint.vsum(endp,xPoint.vdiff(endp, lastcxy)) : endp;
		endp = cmd[2];
		lastcxy = c1;
		return cmd;
	}

	private static function relativeQSmooth(cmd:Array):Array{
		var c1:Point = aqcurve ? xPoint.vsum(endp,xPoint.vdiff(endp, lastcxy)) : endp;
		var endp:Point = xPoint.vsum(endp, cmd[1]);
		lastcxy = c1;
		return ['T', endp];
	}

}}
