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

	import flash.events.MouseEvent;	
	import flash.display.Sprite;
	import flash.display.Shape;	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.CapsStyle;	
	import flash.display.JointStyle;	
	
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.display.Graphics;
	import flash.display.BitmapData;
	import util.Color;
	import uiwidgets.*;
	import ui.DrawPath;
	import ui.parts.UIPart;
	import flash.text.*;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import assets.Resources;
	import flash.geom.Matrix;
	import flash.display.GradientType;
	import flash.display.SpreadMethod;

public class ColorPalette extends Sprite {
 	
 	private const slotsize:int =34;
	private const wheelSize:int = 130;
 	public const swatchsize:int = 14;
 	public const fillsize:int = 34;
 	public const gap:int = 180;
 	
 	
 	public var isSwatch:Boolean = true;
 		
 	public var swatchlist:Array;
	private var fillTab:IconButton;
	private var borderTab:IconButton;
	private var textTab:IconButton;
	public var w:int;
	public var h:int;
	private var tablist:Array= [];
	private var wheel:Sprite;
	private var toggleFill:Sprite;
	public var hueCursor:Sprite;
	public var gradHueCursor:Sprite;
	public var colorSB:Sprite;
	public var SBcursor:Sprite;
	public var nopen:Sprite;
	public var pureblack:Sprite;
	public var purewhite:Sprite;
	public var thiscolor:Sprite;
	public var swatchSelector:Sprite;
	public var colorSwatchCursor:Sprite;

	public var fillSwatch:Sprite;
	public var strokeSwatch:Sprite;
	public var textSwatch:TextField;
	private var colorSBsize:int;
	public var cursor:Sprite;
	public var sizeSelector:Sprite;
	public var fillSelector:Sprite;
	public var textPanel:Sprite;

	public var pensizes:Array=[0.5, 1, 2, 3, 4, 8, 12, 16];
	public var filltypes:Array=["onecolor",PaintVars.horizontal,PaintVars.vertical,
		PaintVars.diagonally,  PaintVars.diagonally2,
		PaintVars.radialgradient, PaintVars.radialtl, PaintVars.radialbr];
	public var textStyleOptions:Array = ["Casual", "Brave", "Predictable", "Trendy", "Formal","Cool", "Pleasant"];
	public var textSizeOptions:Array = ["10", "12", "18", "24", "36", "48", "72"];


	public function ColorPalette(p:PaintEdit) {
 		super();
 		initSwatchList();
 		fillTab =   makeTab('Fill', selectFill, 40);
		borderTab = makeTab('Border', selectBorder, 55); // changed to 'Costumes' or 'Scenes' by refresh()
		textTab = makeTab('Text', selectText, 66);
		fillSwatch = createSample("fillSwatch", 32, 2, 20, 20, changeToFill);
		strokeSwatch = createSample("strokeSwatch", fillTab.width + 53, 10, 40, 8, changeToBorder);
		textSwatch = createSampleText ("Sample", strokeSwatch.x  + strokeSwatch.width + 45, changeToText);
		tablist.push(fillTab); tablist.push(borderTab); tablist.push(textTab); 
		setupFillChoice();
		fixLayout();
		p.addChild(this);
		fixLayout();
		setupColorPalette();
		setupTextPalette();
		changeToFill(null);	
	}

	private function selectFill(b:IconButton):void {changeToFill (null);}
		
	private function selectBorder(b:IconButton):void {changeToBorder(null);}
		
	private function selectText(b:IconButton):void {
		selectTab (b);
		textPanel.visible = true;
		PaintVars.penAtt = "text";
		PaintVars.activeHue = "color1";
		updateSettings();
		}

	private function selectTab(b:IconButton):void {
		for (var i:int=0; i < tablist.length; i++) {
			if (tablist[i] == b) (tablist[i] as IconButton).turnOn();
			else (tablist[i] as IconButton).turnOff();
		}
	}
	
	private function drawBackground (g:Graphics, w:int, h:int):void{
		g.clear();
		g.lineStyle(0.5,CSS.borderColor,1,true);
		g.beginFill(CSS.bgColor);
		g.drawRect(0, 23,w  - 10, h - 24);
		g.endFill();	
	}
	
	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		drawBackground(this.graphics, w,h);
	}
	
	public function fixLayout():void {
		fillTab.x = 0;
		fillTab.y = 0;
		borderTab.x = fillTab.x + fillTab.width + 1;
		borderTab.y = 0;
		textTab.x = borderTab.x + borderTab.width + 1;
		textTab.y = 0;
	}

	private function setupFillChoice():void {	
		toggleFill = new Sprite();
		addChild(toggleFill);
		var bt:IconButton =  new IconButton(changeToSimple, makeButtonImg('swatches', true), makeButtonImg('swatches', false), true);
		toggleFill.addChild(bt);
		var bt2:IconButton =  new IconButton(changeToAdvance, makeButtonImg('wheel', true), makeButtonImg('wheel', false), true);
		bt2.y =  bt.y + bt.height + 5;
		toggleFill.addChild(bt2);
		bt.turnOn();
		toggleFill.x =  5;
		toggleFill.y = (175 - bt.height*2 -5) / 2;
 	}
 	
private function setupColorPalette():void {
	setupWheelSelector(x + 35, y + 24, wheelSize, wheelSize);
	createColorSwatchSelector(x + 36,y + 28, swatchsize *10, swatchsize * 8);
	setSampleColor(fillSwatch);
	setSampleColor(strokeSwatch);
	createSizeSelector(x + gap, y + 40,1 + slotsize * 4, 82);
	changeSBtopRightCorner("fill");
	createFillTypeSelector(x + gap, y + 40, fillsize * 4, 20 + fillsize * 3);
	updateSettings();
}

private function setupWheelSelector(dx:int, dy:int, w:int, h:int):void {
	wheel = new Sprite();
	wheel.name = "wheel";
	wheel.visible = ! isSwatch;
	addChild(wheel);
	wheel.x = dx;
	wheel.y = dy;
	wheel.addEventListener(MouseEvent.MOUSE_DOWN, colorSelectorMouseDown);
	setupWheel(wheel, w, h);
	setupSquare(wheel, 42, 42, 110, 110);
}

private function setupWheel(c:Sprite, w:int, h:int):void {	
	circleBorder(c.graphics, (w+8)/2, (h+8)/2, Math.floor((w+8) / 2) - 12,CSS.bgColor, 1, 18);
	circleBorder(c.graphics, (w+8)/2, (h+8)/2, Math.floor((w+8) / 2) - 1,0, 0.4, 1);
	circleBorder(c.graphics, (w+8)/2,(h+8)/2, Math.floor((w+8) / 2) - 21, 0, 0.4, 1);
	Turtle.seth(0);
	Turtle.xmax = w / 2;
	Turtle.ymax = h / 2;
	Turtle.xcor = 4 + (w / 4);
	Turtle.ycor = -4 + ((h / 4) - (h / 2));
	Turtle.pendown = true;
	drawColorWheel(c.graphics, w, h);
	hueCursor = new Sprite();
	hueCursor.name = "hueCursor";
	c.addChild(hueCursor);
	gradHueCursor = new Sprite();
	gradHueCursor.name = "gradHueCursor";
	c.addChild(gradHueCursor);	
	gradHueCursor.visible = false;
}

private function drawColorWheel(g:Graphics, w:int, h:int):void {	
	for (var i:int = 0; i < 360; i++){
		Turtle.seth(i);
		var rgb:int = Color.fromHSV(i, 1, 1);
		Turtle.pendown = false;
		g.lineStyle(2,rgb,1,true,"normal", CapsStyle.ROUND);
		Turtle.forward(Turtle.xmax - 14, g);
		Turtle.pendown = true;
		Turtle.forward(14, g);
		Turtle.pendown = false;
		Turtle.forward(-Turtle.xmax, g);
	}
}

private function setupSquare(c:Sprite, dx:Number, dy:Number, w:Number, h:Number):void{
	// sprite for saturation and brightness
	var d:Number= Math.floor(Turtle.cosdeg(45) * (w/2 - 16) * 2);
	colorSB = new Sprite();
	colorSB.name = "colorSB";
	colorSB.x = dx; colorSB.y = dx;
	var g:Graphics = colorSB.graphics;
	g.lineStyle(0.5,CSS.borderColor,1,true);
	g.beginFill(0xFFFF00);
	g.drawRect(0, 0, d, d);
	g.endFill();
	colorSB.width = colorSB.height = d;
	colorSBsize = d;
	c.addChild(colorSB);

	nopen = cornerSquare(colorSB, -6, d-5, "nopen", 10, 0xFFFFFF);	
	noColorSwatch(nopen, nopen.graphics, -1);
	pureblack =   cornerSquare(colorSB, d-6, d-5, "pureblack", 10, 0x0);	
	purewhite = cornerSquare(colorSB, -5, -5, "purewhite", 10, 0xFFFFFF);
	thiscolor = cornerSquare(colorSB,d - 6,  -5, "thiscolor", 10, 0xFFFFFF);
	SBcursor = cornerSquare(colorSB, d - 6,  -6, "SBcursor", 12, 0xFFFFFF);
	drawSquareHighlight(SBcursor, 12, 12, 0x00FFFF);
}

private function createSample(str:String, dx:int, dy:int, w:int, h:int, fcn:Function):Sprite{
	var spr:Sprite = new Sprite();
	spr.name = str;
	spr.x= dx; spr.y =dy;
	addChild(spr);	
	var g:Graphics = spr.graphics;
	g.lineStyle(0.5,CSS.borderColor,1,true);
	g.beginFill(0xFFFFFF);
	g.drawRect(0, 0, w, h);
	g.endFill();
	spr.addEventListener(MouseEvent.MOUSE_DOWN, fcn);
	return spr;
}

private function createSampleText(str:String, dx:int,  fcn:Function):TextField{
	var form:TextFormat = getCurrentTextFormat();
	var tf:TextField = Resources.makeLabel(str, form);
	tf.x = dx;
	tf.y = (20 - tf.textHeight) / 2;
	addChild(tf);
	tf.addEventListener(MouseEvent.MOUSE_DOWN, fcn);
	return tf;
}

public function getCurrentTextFormat():TextFormat{
	return new TextFormat(PaintVars.textAttributes.family, 12,
		PaintVars.textAttributes.basecolor,PaintVars.textAttributes.weight == "bold", 
		PaintVars.textAttributes.fontstyle ==  "italic");
}

	private function getBorder():Array{
		var f:GlowFilter = new GlowFilter(0x0);
		f.strength = 2;
		f.blurX = f.blurY =2;
		f.knockout = false;
		return [f];
	}
	
private function noColorSwatch(c:Sprite, g:Graphics, indent:int = 0):void {
	g.beginFill(0x818181);
	g.drawRect(0,0,c.width,c.height);  
	g.beginFill(0xffffff);
	g.drawRect(0.5,0.5,c.width -1,c.height -1);  
	g.endFill();
	indent++;
	g.lineStyle(2,0xFF0000,1,true,"normal", CapsStyle.SQUARE);
	g.moveTo(indent + 1,  c.height - indent - 1);
	g.lineTo(c.width - indent - 1,  indent + 1);
	g.lineStyle(2,0x818181,1,true,"normal", CapsStyle.SQUARE);
	g.drawRect(indent,indent, c.width - indent*2, c.height -indent*2);
}
	
private function cornerSquare(p:Sprite, dx:int, dy:int, str:String, s:int, c:int, h:int = 0):Sprite{
	var spr:Sprite = new Sprite();
	spr.name = str;
	spr.x= dx; spr.y =dy;
	p.addChild(spr);	
	var g:Graphics = spr.graphics;
	g.lineStyle(0.5,CSS.borderColor,1,true);
	g.beginFill(c);
	g.drawRect(0, 0, s, (h==0) ? s : h);
	g.endFill();
	return spr;
}

	private function makeTab(label:String, action:Function, dw:int):IconButton {
		var ib:IconButton= new IconButton(action, makeTabImg(label, true, dw), makeTabImg(label, false, dw), true);
		addChild(ib);
		return ib;
	}
	
	private function makeTabImg(label:String, on:Boolean, dw:int):Sprite {
		var tabImg:Sprite = new Sprite();
		var form:TextFormat = new TextFormat('Lucida Grande', 12, on ? CSS.onColor : CSS.offColor, false);
		var tf:TextField = Resources.makeLabel(label, form);
		tf.x = 5;
		tf.y = 4;
		tabImg.addChild(tf);

		var g:Graphics = tabImg.graphics;
		var w:int = tf.width + dw;
		var h:int = 24;
		var r:int = 9;
		if (on)	{
			g.beginFill(CSS.bgColor);
			DrawPath.drawPath(UIPart.getTopBarPath(w,h),g, 0,0,0);
			g.endFill();
			g.lineStyle(0.5,CSS.borderColor,1,true);
			DrawPath.drawPath(UIPart.getTopBarPath(w,h),g, 0,0,0);
				}
		else UIPart.drawTopBar(g, CSS.titleBarColors, UIPart.getTopBarPath(w,h), w, h);
		return tabImg;
	}

//////////////////////////////////////////////////////////////////////////////////////////
// Swatches
//////////////////////////////////////////////////////////////////////////////////////////


private	function initSwatchList():void{
	swatchlist = [
	0xf5989d,0xfdc689,0xfff9b2,0xc4df9b,0xafedaf,0xb2fcfc,0x6dcff6,0x8393ca,0xa186be,0xf598f5,
	0xf26d6d,0xfbaf5d,0xfff680,0x9fd455,0x8ae68a,0x7ef5f5,0x00bff3,0x5674b9,0x8560a8,0xf06ef0,
	0xff0000,0xff8000,0xffff00,0x8ae411,0x00ff00,0x00ffff,0x0094ff,0x0000ff,0x7f00ff,0xff00ff,
	0xb62323,0xF09B36,0xd6d602,0x598527,0x1a7a1a,0x008c83,0x0c66a6,0x2e3192,0x662d91,0x9c1a9c,
	0x8c0000,0xb85d02,0xb8b802,0x406618,0x005e20,0x00746b,0x004a80,0x1b1464,0x440e62,0x780078,
	0xf5dacc,0xf1c9ca,0xdda8a0,0xce967d,0xba7c6d,0xa67358,0xa9776e,0x8c6239,0x754c24,0x603913,
	0xE0E9ED,0xe8f7ff,0xd0effe,0xade2fd,0x88E3FF,0x74CCE5,0x00A9D3,0x0085AC,0x66B3D1,0x659AD2
	]
	var grays:Array = [
		0, 0.14, 0.21, 0.27, 0.33, 0.39, 0.44, 0.49, 0.54,
		0.58, 0.63, 0.67, 0.72, 0.76, 0.80, 0.84, 0.88, 0.92, 1.0
	];
	for ( var i:int=0; i < grays.length; i++) swatchlist.push(Color.fromHSV(0, 0, grays[i]));	
	swatchlist.push("none");
}

private function createColorSwatchSelector(dx:Number,dy:Number, w:Number,h:Number):void {
	swatchSelector = createSwatchSelector(dx, dy,w,h, 'swatchSelector');
	for ( var i:int=0; i < swatchlist.length; i++) createFillSwatch(swatchSelector, i, swatchsize, swatchsize, swatchlist[i], selectSwatch);
	// cursor in HUE
	colorSwatchCursor = cornerSquare(swatchSelector, 0,0, "colorSwatchCursor", swatchsize, 0xFFFFFF);
	drawSquareHighlight(colorSwatchCursor);
 }

public  function drawSquareHighlight(c:Sprite, w:int = 14, h:int= 14, color:uint = 0xFFFFFF):void{
	var g:Graphics = c.graphics;
  g.clear();
	squareBorder(g,w - 2, h - 2, CSS.onColor , 4);
	squareBorder(g, w - 2,h  - 2, color, 2);
}

private function createSizeSelector(dx:Number,dy:Number, w:Number,h:Number):void {
	var titleandcontents:Sprite = new Sprite();
	titleandcontents.addChild(getTitleBar("Size", w, 20));
	titleandcontents.x = dx;
	titleandcontents.y = dy;
	sizeSelector = cornerSquare(titleandcontents,0, 20, "sizeSelector", w, 0xFFFFFF, h - 20);
	sizeSelector.graphics.clear();
	for (var i:int=0; i < pensizes.length; i++) createPensizeThumb(sizeSelector, slotsize, i, setStrokeSize);
	addChild(titleandcontents);
 }

private function createPensizeThumb(mp:Sprite, size:int, pos:int, fcn:Function):void { 
	var ps:Number =  pensizes[pos];
	var dy:int = Math.floor(pos / 4) * size;
	var dx:int = Math.floor(pos % 4) * size;
	var pensize:Sprite = cornerSquare(mp,dx, dy, "color-" +pos, size, 0xFFFFFF, size);
	if (fcn != null) {
		pensize.addEventListener(MouseEvent.MOUSE_DOWN, 
			function myCallBack(e:MouseEvent):void { 
				var args:Array = new Array();
				args.push (e);			
				args.push(pos);	
				fcn.apply(null, args);
		});
	}	
	pensize.addChild(new Shape());
	var g:Graphics=(pensize.getChildAt(0) as Shape).graphics;
	g.beginFill(0);
	g.drawCircle(size / 2, size / 2, ps);
	g.endFill();
}

//////////////////////////////////////////
// call backs
/////////////////////////////////////////

public function setFillType(e:MouseEvent, key:*):void{
	e.preventDefault();
	if (!canChange("fill", key)) return;
	PaintVars.fillAttributes.fillstyle = key;
	updateSettings();
	updateElement(e != null);
	PaintVars.getKeyBoardEvents();
}

public function setStrokeSize(e:MouseEvent, n:Number = 0):void{
// callback for pen size pallete
	if (e) e.preventDefault();
	var key:String = PaintVars.textIsSelected() ? "textstroke" : "strokewidth"; 
	PaintVars.strokeAttributes[key] = isNaN(n) ? 0.5 :  pensizes[int(n)];
	showPenSizes();
	updateSettings();
	updateElement(e != null);
	PaintVars.getKeyBoardEvents();
}

private function createFillTypeSelector(dx:Number,dy:Number, w:Number,h:Number):void {
	var titleandcontents:Sprite = new Sprite();
	titleandcontents.addChild(getTitleBar("Fill Styles", w, 20));
	titleandcontents.x = dx;
	titleandcontents.y = dy;
	fillSelector = cornerSquare(titleandcontents,0, 20, "fillSelector", w, 0xFFFFFF, h - 20);
 	fillSelector.graphics.clear();
	for (var i:int=0; i < pensizes.length; i++) createFillThumb(fillSelector, fillsize, i, setFillType);
	addChild(titleandcontents);
 }

private function createFillThumb(mp:Sprite, size:int, pos:int, fcn:Function):void { 
	var ps:Number =  pensizes[pos];
  var dy:int = Math.floor(pos / 4) * size;
  var dx:int = Math.floor(pos % 4) * size;
  var key:* = filltypes[pos];
  var filltype:Sprite = cornerSquare(mp,dx, dy, "fill-" +pos, size, 0xFFFFFF);
	if (fcn != null) {
			filltype.addEventListener(MouseEvent.MOUSE_DOWN, 
			function myCallBack(e:MouseEvent):void { 
				var args:Array=new Array();
				args.push (e);			
				args.push(key);	
				fcn.apply(null, args);
				});
			}	
	var thumb:Sprite = new Sprite();
	filltype.addChild(thumb);
	var g:Graphics=thumb.graphics;
	thumb.x = 4;
	thumb.y = 4;
	if (key == "onecolor") g.beginFill (getSolidColor());
	else getFillCanvasColor(g, key,size - 8, size - 8);
	g.drawRect(0,0,size-4,size-4);  
	g.endFill();
}

private function getTitleBar(label:String, w:int, h:int):Sprite {
		var spr:Sprite = new Sprite();
		var tf:TextField = Resources.makeLabel(label, CSS.textFormatOn);
		tf.x = (w - tf.width) / 2;
		tf.y = (h - tf.height) / 2;
		spr.addChild(tf);
		var g:Graphics = spr.graphics;
		g.beginFill(CSS.onColor, 0.6);
		g.drawRect(0,0, w, h);
		g.endFill();
		return spr;
	}

private function getFillCanvasColor(g:Graphics, key:*, w:Number, h:Number):void{
		var grad:Object = new Object();
		for (var i:String in key) grad[i] = key[i];
		var colors:Array = [(PaintVars.fillAttributes.gradalpha == 0) ? getSolidColor() : getGradientColor(),
			(PaintVars.fillAttributes.alpha == 0) ? getGradientColor() : getSolidColor()];  
		var ratios:Array = PaintVars.defaultRatios;
		var alphas:Array = [((PaintVars.fillAttributes.gradalpha == 0) ? 0 : 100), 
			((PaintVars.fillAttributes.alpha == 0) ? 0 : 100)];  
		grad.colors = colors;
		grad.ratios = ratios;
		grad.alphas = alphas;
		grad.spreadMethod = SpreadMethod.PAD;
		PaintVars.setGradientFill(g, grad , w, h, 0, 0);
		}
		

////////////////////////////////////
// Cursors shapes
///////////////////////////////////

private function squareBorder(g:Graphics, w:Number,h:Number, c:uint, lw:Number):void {
		g.lineStyle(lw, c,1,true, "normal", CapsStyle.ROUND, JointStyle.MITER);
		g.drawRect(2,2, w, h);
}

private function createFillSwatch(mp:Sprite, pos:int, w:int, h:int, sw:*, fcn:Function):void { 
  var dy:int = Math.floor(pos / 10) * h;
  var dx:int = Math.floor(pos % 10) * w;
  var swatch:Sprite = cornerSquare(mp,dx, dy, "color-" +pos, w, 0x818181);
	if (fcn != null) {
			swatch.addEventListener(MouseEvent.MOUSE_DOWN, 
			function myCallBack(e:MouseEvent):void { 
				var args:Array=new Array();
				args.push (e);  
				args.push(sw);			
				args.push(pos);	
				fcn.apply(null, args);
				});
			}	
	var g:Graphics=swatch.graphics;
	if ((sw is String) && (sw == "none")) noColorSwatch(swatch, g);
	else {
		g.beginFill(uint(sw));
		g.drawRect(0.5,0.5,swatch.width -1,swatch.height -1);  
		g.endFill();
	}
}

public function selectSwatch(e:MouseEvent, color:*, pos:int= -1):void{
	PaintVars.getKeyBoardEvents();
	if (! canChange(PaintVars.penAtt, color)) return;
	setOneColorSwatch(e, color);
}

public  function setOneColorSwatch(e:MouseEvent, color:*):void{
	colorSwatchCursor.visible = true;
	var rgb:Array= ((color is String) && (color == "none")) ? [0,0,0] :  Color.rgb2hsv(color);
	switch (PaintVars.penAtt){
		case "fill":
			PaintVars.fillAttributes.fillstyle = "onecolor";
			PaintVars.fillAttributes.alpha =  ((color is String) && (color == "none")) ? 0 : 1;
			if (PaintVars.fillAttributes.alpha == 1)  {
				PaintVars.fillAttributes.basecolor =  color; 
		  	PaintVars.setFillColor (rgb);
			}
			break;
		case "stroke":
			PaintVars.strokeAttributes.basecolor =  color; 
			if  ((color is String) && (color == "none")) break;
			PaintVars.setStrokeColor(rgb);
			break;
		case "text":
			PaintVars.textAttributes.basecolor =  color; 
			PaintVars.setTextColor (rgb);
			break;
		}
	updateSettings();
	updateElement(e != null);
	PaintVars.getKeyBoardEvents();
}

public function canChange(attr:String, key:*):Boolean{
	if (key != "none") return true;
	if (key is  Array)  return true;
	if ((attr == "stroke") &&  noFillColor()) return false;
	if ((attr == "fill") &&  (PaintVars.strokeAttributes.basecolor== "none")) return false;
	return true;
} 

public function noFillColor():Boolean {
	return (PaintVars.fillAttributes.alpha == 0) && (PaintVars.fillAttributes.fillstyle == "onecolor");
}

private function createSwatchSelector(dx:Number,dy:Number, w:Number,h:Number, str:String):Sprite{
	var spr:Sprite = new Sprite();
	spr.name = str;
	spr.x= dx; spr.y =dy;
	spr.visible = isSwatch;
	addChild(spr);	
	var g:Graphics = spr.graphics;
	g.beginFill(0xbbbdc5);
	g.drawRect(0, 0, w, h);
	g.endFill();
	return spr;
}

////////////////////////////
// Element
/////////////////////////////

public function updateElement(b:Boolean):void {
	if (PaintVars..imageIsSelected()) return;
	if ((PaintVars.selectedElement == null) || (PaintVars.selectedElement.id == "clippingmask")) return;
	if ((PaintVars.penAtt == "text") && PaintVars.textIsSelected()) {
		PaintVars.selectedElement.setAttribute("fill", getTextColor());
		PaintVars.selectedElement.setAttribute("font-family", getFontFamily());
		PaintVars.selectedElement.setAttribute("font-size", getFontSize());
		PaintVars.selectedElement.setAttribute("font-weight", getFontWeight());
		PaintVars.selectedElement.setAttribute('font-style', getFontStyle());
		PaintVars.selectedElement.chooseContrast(); 
		}
	else {
		var value:* =(PaintVars.penAtt == "fill") ?  getFillColor(): getStrokeColor();
		PaintVars.selectedElement.setAttribute(PaintVars.penAtt, value);
		PaintVars.selectedElement.setAttribute("stroke-width", PaintVars.strokeAttributes[PaintVars.textIsSelected() ? "textstroke" : "strokewidth"]);
	  PaintVars.selectedElement.setAttribute("strokehue", PaintVars.strokeAttributes.hue);
		PaintVars.selectedElement.setAttribute("fillhue", PaintVars.fillAttributes.hue);
	 	PaintVars.selectedElement.setAttribute("fillghue", PaintVars.fillAttributes.gradhue);
	 }
	PaintVars.selectedElement.render();
	PaintVars.svgroot.selectorGroup.updateFrame(PaintVars.selectedElement);	
	if (b) PaintVars.recordForUndo();
}


//////////////////////////////////////////
//
// UI Display according to Vars -- > nor var changing here
//
/////////////////////////////////////////

public function updateSettings():void{
	if (sizeIsHidden()) hidePenSizes();
	else showPenSizes();
	fillStylesState();
	setSampleColor(fillSwatch);
	setSampleColor(strokeSwatch);
	setSampleTextColor();
	if (PaintVars.penAtt == "text") nopen.visible=false;
	else nopen.visible=true;
	changeSBtopRightCorner(PaintVars.penAtt);
	updateFillThumbs();
	var val:* = getHueValue();
	paintSatBright(val, 2);
	updateColorCursors();
}

public function getHueValue():*{
	switch (PaintVars.penAtt){
		case "fill":
			return ((PaintVars.activeHue == "color1") ? PaintVars.fillAttributes.hue : PaintVars.fillAttributes.gradhue);
		case "stroke":
			return PaintVars.strokeAttributes.hue;
			break;
		case "text":
		 return PaintVars.textAttributes.hue;
		}
 	return PaintVars.fillAttributes.hue;
}

public function getBaseColor():*{
	switch (PaintVars.penAtt){
		case "fill":
			return (PaintVars.activeHue == "color1") ? getSolidColor(): getGradientColor();
		case "stroke":
			return getStrokeColor();
			break;
		case "text":
		 return getTextColor();
		}
 	return getSolidColor();
}

private function fillStylesState():void{
	if ((isSwatch) || (PaintVars.paintMode == "eraser")) (fillSelector.parent).visible = false;
	else {
		if ((PaintVars.penAtt == "fill") && (PaintVars.penAtt != "text")) (fillSelector.parent).visible = true;
		else (fillSelector.parent).visible = false;
	}
 if (PaintVars.paintMode == "eraser"){
 	wheel.visible =  false;
	swatchSelector.visible = false;
	toggleFill.visible =  false;
 }
 else {
 	toggleFill.visible =  true;
 	wheel.visible =  !isSwatch;
	swatchSelector.visible = isSwatch;
 } 
}

public function updateFillThumbs():void{
	selectFillType(PaintVars.fillAttributes.fillstyle);
	for(var i:int=0;i< fillSelector.numChildren;i++){
		var elem:Sprite=fillSelector.getChildAt(i) as Sprite;
		var g:Graphics=(elem.getChildAt(0) as Sprite).graphics;
		g.clear();  
		var key:* = filltypes[i];
		if (key == "onecolor"){
			g.beginFill (getSolidColor());
			g.drawRect(0,0,fillsize-7,fillsize-7);  
			g.endFill();
			if (PaintVars.fillAttributes.alpha == 0) noColorSwatch(elem.getChildAt(0)  as Sprite, g);
			}
		else {
			getFillCanvasColor(g, key , fillsize-7,fillsize-7);  
			g.drawRect(0,0,fillsize-7,fillsize-7);  
			g.endFill();
			}
		}	
	}

public function selectFillType (str:*):void{
	var n:int = (str is String) ? 0 : str.index ? str.index : -1;
	for(var i:int=0;i< fillSelector.numChildren;i++){
		var elem:Sprite=fillSelector.getChildAt(i) as Sprite;
		var bkgc:uint = 0xFFFFFF;
		var borderc:uint =  (i == n) ? 0x0093ff : CSS.borderColor;
		var g:Graphics = elem.graphics;
		g.clear();
		g.beginFill(bkgc);
		g.lineStyle(3,borderc,1,true);
		g.drawRect(2,2,fillsize - 4, fillsize - 4);
		g.endFill();		
  }
}

public  function updateColorCursors():void{
	if (isSwatch) updateSwatchCursors();
	else updateWheelCursors();
}

private function updateSwatchCursors():void{	
	colorSwatchCursor.visible =  true;
	gradHueCursor.visible = false;
	hueCursor.visible = false;
	switch (PaintVars.penAtt){
		case "fill":
			setSwatchCusor(PaintVars.fillAttributes.basecolor);
			break
		case "stroke":
			setSwatchCusor(PaintVars.strokeAttributes.basecolor);
			break;
		case "text":
			setSwatchCusor(PaintVars.textAttributes.basecolor);
			break;
		}		
}

private function updateWheelCursors():void{	
	colorSwatchCursor.visible = false;
	gradHueCursor.visible = isExtraCursor();
	hueCursor.visible = true;	
	switch (PaintVars.penAtt){
		case "fill":
			setWheelCursors([PaintVars.fillAttributes.hue,PaintVars.fillAttributes.saturation,PaintVars.fillAttributes.brightness] ,
			  [PaintVars.fillAttributes.gradhue,PaintVars.fillAttributes.gradsat,PaintVars.fillAttributes.gradbright]);
			break
		case "stroke":
			setWheelCursors([PaintVars.strokeAttributes["hue"], PaintVars.strokeAttributes["saturation"], PaintVars.strokeAttributes["brightness"] ] );
			break;
		case "text":
			setWheelCursors([PaintVars.textAttributes["hue"], PaintVars.textAttributes["saturation"], PaintVars.textAttributes["brightness"] ] );
			break;
		}		
}

private function isExtraCursor():Boolean{
	if (PaintVars.penAtt == "text") return false;
	if (PaintVars.penAtt == "stroke") return false;	
  return ! (PaintVars.fillAttributes.fillstyle == "onecolor");
}
 
////////////////////////////////////////
// Swatches UI
////////////////////////////////////////
	
public  function setSwatchCusor (color:uint):void{
	var pos:int;
	if  (noneSelected()) pos = swatchlist.length - 1;
  else  pos = getClosestColor (color);
	if (pos < 0) return;
	colorSwatchCursor.x = Math.floor(pos % 10) * swatchsize - 1 ;
	colorSwatchCursor.y = Math.floor(pos / 10) * swatchsize - 1 ;
	drawSquareHighlight(colorSwatchCursor);
}

public  function getClosestColor (color:uint):int{
	var pos:int = swatchlist.indexOf(color);
	if (pos > -1) return  pos;
	var bench:Array = Color.rgb2hsv(color);
	for (var i:int=0; i < swatchlist.length; i++) {
		if (isSimilar(bench, swatchlist[i])) return i;
		}
	return pos;
}

public function isSimilar(bench:Array, color:uint):Boolean{
		 var hsv:Array =	Color.rgb2hsv(color)
		if (Math.abs (hsv[0] - bench[0]) > 1) return false;
		if (Math.abs (hsv[1] - bench[1]) > 0.1) return false;
		if (Math.abs (hsv[2] - bench[2]) > 0.1)  return false;
		return true;
}

// setting the sample color 
public function setSampleTextColor ():void{
	var form:TextFormat = getCurrentTextFormat();
	textSwatch.setTextFormat(form);
	textSwatch.y = (20 - textSwatch.textHeight) / 2;
	var rgbalist:Array = Color.rgb2hsv(PaintVars.textAttributes.basecolor);
	var baselist:Array = Color.rgb2hsv(0xFFFFFF);
	
	var hx:Number = rgbalist[0] - baselist[0];
	var sx:Number = rgbalist[1] - baselist[1];
	var bx:Number = rgbalist[2] - baselist[2];

	if (needsAbackground(hx, (sx*sx) + (bx*bx))) {
		textSwatch.background = true; // make true to debug alignment
		textSwatch.backgroundColor = CSS.onColor;
		}
	else textSwatch.background = false;
}

private function needsAbackground(hx:Number, sb:Number):Boolean {
	if((hx == 0)&& (sb < 0.03)) return true;
	if (( hx > 55) &&( hx < 66)) return true;
	return false;
}

// setting the sample color 
public function setSampleColor (c:Sprite):void{
	var w:int = c.width;
	var h:int = c.height;
	var g:Graphics = c.graphics;
	g.clear();
	g.lineStyle(0.5,CSS.borderColor,1,true);
	g.beginFill(0xFFFFFF);
	g.drawRect(0, 0, w, h);
	g.endFill();
	var type:String = (c == fillSwatch) ? "fill" : "stroke";
	if (noStrokeOrFill(type)) noColorSwatch(c, g);
	else {
		if (type == "fill") {
			if (PaintVars.fillAttributes.fillstyle == "onecolor") g.beginFill (getSolidColor());
			else getFillCanvasColor(g, PaintVars.fillAttributes.fillstyle , c.width - 2, c.height - 2);
			}
		else g.beginFill(getStrokeColor());
		g.drawRect(1,1,c.width-2,c.height-2);  
		g.endFill();
	}
}


public function noStrokeOrFill (str:String):Boolean{ 
	if (str == "stroke") return PaintVars.strokeAttributes.basecolor == "none";
	else return noFillColor();
}

private function getSolidColor():uint{ return PaintVars.fillAttributes.basecolor;};
private function getGradientColor():uint{ return PaintVars.fillAttributes.gradcolor;};
public function getStrokeColor():*{ return PaintVars.strokeAttributes.basecolor;};
public function getTextColor():uint { return PaintVars.textAttributes.basecolor;};

public function getFontFamily():String { return PaintVars.textAttributes.family;};
public function getFontSize():uint { return PaintVars.textAttributes.fontsize;};
public function getFontWeight():String { return PaintVars.textAttributes.weight;};
public function getFontStyle():String { return PaintVars.textAttributes.fontstyle;};

public function getFillColor():*{
	if (noFillColor()) return "none"; 
	if (PaintVars.fillAttributes.fillstyle == "onecolor") return  getSolidColor();
	return getGradientData();
}

public function getGradientData():Object{
	var key:Object = PaintVars.fillAttributes.fillstyle;
	var grad:Object = new Object();
	for (var k:String in key) grad[k] = key[k];
	var colors:Array = [(PaintVars.fillAttributes.gradalpha == 0) ? getSolidColor() : getGradientColor(),
			(PaintVars.fillAttributes.alpha == 0) ? getGradientColor() : getSolidColor()];  
	var ratios:Array = PaintVars.defaultRatios;
	var alphas:Array = [((PaintVars.fillAttributes.gradalpha == 0) ? 0 : 100), 
			((PaintVars.fillAttributes.alpha == 0) ? 0 : 100)];  
	grad.colors = colors;
	grad.ratios = ratios;
	grad.alphas = alphas;
	grad.spreadMethod = SpreadMethod.PAD;
	return grad;
}

////////////////////////////////////////
// setting the cursors on the Wheel
/////////////////////////////////////

public function setWheelCursors(hsv:Array, ghsv:Array = null):void{
	selectCursor();
	if ((hsv[1] == 0)&& (hsv[2] == 0)) hsv[1] = 1;
	setCursorHue(hueCursor, hsv[0]);
	if (ghsv) setCursorHue(gradHueCursor, ghsv[0]);
	setCursorSB((PaintVars.activeHue == "color1") ? hsv[1] : ghsv[1], (PaintVars.activeHue == "color1") ? hsv[2] : ghsv[2]);		
}

public  function setCursorHue(spr:Sprite, a:Number):void{
	var dx:Number = (wheelSize/2) - 4;
	var dy:Number = (wheelSize/2) - 4;

	var n:Number = dx - 3;
	a -= 90;
	if (a < 0) a +=360;
	dy+=n*Turtle.sindeg(a);
	dx+=n*Turtle.cosdeg(a);
	spr.x = Math.floor(dx);
	spr.y = Math.floor(dy);
	drawTwoCursors();
}

public function setCursorSB(s:Number, b:Number):void {
	var dx:Number, dy:Number = (1 - b);
	if (noneSelected()) {
		SBcursor.x = nopen.x - 2;
		SBcursor.y = nopen.y - 2;
	} else {		
		var w:Number = colorSBsize - 1;
		var h:Number = colorSBsize - 1;	
		dx = w * s - (SBcursor.width / 2) + 1;
		dy = h - (h * b)- (SBcursor.height / 2) + 1;
		SBcursor.x = Math.floor(dx);
		SBcursor.y = Math.floor(dy);
	}
}

////////////////////////
// Color cursors
////////////////////////

public function noneSelected():Boolean {
	if (PaintVars.penAtt == "text") return false;
	return ((PaintVars.penAtt == "stroke") && (PaintVars.strokeAttributes.basecolor == "none"))  || 
		((PaintVars.penAtt == "fill") && (PaintVars.activeHue == "color1") && (PaintVars.fillAttributes.alpha == 0))  || 
		((PaintVars.penAtt == "fill") && (PaintVars.activeHue == "color2") && (PaintVars.fillAttributes.gradalpha == 0));
	}

public function selectCursor():void {
	var obj:Object = getColorState();
	var sat:Number= ((PaintVars.penAtt == "fill") && (PaintVars.activeHue == "color2")) ?  obj["gradsat"] : obj["saturation"] ;
	var bri:Number=  ((PaintVars.penAtt == "fill") && (PaintVars.activeHue == "color2")) ?  obj["gradbright"] : obj["brightness"] ;
	var hue:uint = ((PaintVars.penAtt == "fill") && (PaintVars.activeHue == "color2")) ?  obj["gradhue"] : obj["hue"] ;
	setCursorSB(sat, bri);		
	drawTwoCursors();
}

public function getColorState():Object {
	return (PaintVars.penAtt == "fill") ? PaintVars.fillAttributes : 
									(PaintVars.penAtt == "stroke") ? PaintVars.strokeAttributes : PaintVars.textAttributes;
}

public function drawTwoCursors():void {
	var c1:Graphics = hueCursor.graphics;
	var c2:Graphics = gradHueCursor.graphics;
	c1.clear();
	c2.clear();
	if (PaintVars.activeHue == "color1") {
		circleBorder(c1, 8, 8,4, 0x0, 0.8, 4);
		circleBorder(c1, 8, 8,4, 0xFFFFFF, 1, 2);
		diamondBorder(c2, 16,16,  0xFFFFFF, 0.8, 4);
  	diamondBorder(c2, 16,16,0xA8A8A8, 1, 2);
		}
	else { 
		circleBorder(c1, 8,8, 4, 0xFFFFFF, 0.8, 4);
		circleBorder(c1, 8,8, 4, 0xA8A8A8, 1, 2);
		diamondBorder(c2, 16, 16, 0x0, 0.8, 4);
		diamondBorder(c2, 16, 16,  0xFFFFFF, 1, 2);
	}
}

private function circleBorder(g:Graphics, cx:int, cy:int, r:int, c:uint,a:Number, lw:Number):void{
	g.lineStyle(lw,c,a,true);
	g.drawCircle(cx, cy,r);
}

public function diamondBorder(g:Graphics, w:int, h:int, c:uint,a:Number, lw:Number):void{
	g.lineStyle(lw,c,a,true);
	g.moveTo(0 + lw / 2, (h / 2));
	g.lineTo ((w/2), lw/2);
	g.lineTo(w - lw/2, (h / 2));
	g.lineTo ((w / 2), h - lw/2);
	g.lineTo(0+lw/2, (h / 2));
}

public  function changeSBtopRightCorner(name:String):void{
	var g:Graphics = thiscolor.graphics;
	var c:uint = getHueValue();
	g.clear();
	g.lineStyle(0.5,CSS.borderColor,1,true);
	g.beginFill(Color.fromHSV(c ,1, 1));
	g.drawRect(0, 0, 10, 10);
	g.endFill();
}


///////////////////////////////////////
// painting the square of the wheel
///////////////////////////////////////

public function paintSatBright(color:uint, step:int=1):void{
	var g:Graphics = colorSB.graphics;
	g.clear();
	var max:int =colorSBsize - step;
	for (var i:int= 0;  i < max; i+=step){
		var rgb:int = Color.fromHSV(color, i/max, j/max);		
		for (var j:int = 0; j < max; j += step) {
			rgb = Color.fromHSV(color, i/max, (max - j)/max);		
			g.lineStyle(step,rgb,1,true,"nornal", CapsStyle.SQUARE);
			g.moveTo(i+step,j);
			g.lineTo(i+step,j+step);	
		}
	}
}
			
//////////////////////////////////////////////////////////////////////////////////////////
// Events	
//////////////////////////////////////////////////////////////////////////////////////////

private function colorSelectorMouseDown(evt:MouseEvent):void {
	evt.preventDefault();
	evt.stopPropagation();
	var key:String =  getHitPlaceName(evt);
	switch (key) {
		case "colorSB":
			cursor = colorSB;
			selectSBmouseMove(evt);
			PaintVars.getKeyBoardEvents();
			cursor = null;
			break;
		case "wheel":
			cursor =hueCursor;
			selectColorMouseMove(evt);
			updateSettings();
			updateElement(true);
			PaintVars.getKeyBoardEvents();
			cursor = null;
			break;
		case "hueCursor":
			PaintVars.activeHue = "color1";
			selectColorMouseDown(hueCursor);
			selectColorMouseMove(evt);
			break;
		case "gradHueCursor":
			PaintVars.activeHue = "color2";
			selectColorMouseDown(gradHueCursor);
			selectColorMouseMove(evt);
			break;
		case "SBcursor":
			selectSBmouseDown(SBcursor);
			break;
		case "nopen":
			noPenMode(evt);
			updateSettings();
			updateElement(true);
			PaintVars.getKeyBoardEvents();
			break;
		case "purewhite": changeSatBright(0,1);	break;
		case "thiscolor": changeSatBright(1,1); break;
		case "pureblack": changeSatBright(0,0); 	break;		
	}
}	

public function getHitPlaceName(e:MouseEvent):String{
	var dx:Number = e.stageX - PaintVars.getScreenX(wheel, PaintEditor);
	var dy:Number = e.stageY - PaintVars.getScreenY(wheel, PaintEditor);
	var pt:Point = new Point(dx, dy);	
	var rect:Rectangle =SBcursor.getBounds(wheel);
	if (rect.containsPoint(pt)) return SBcursor.name;
	var r:Rectangle = hueCursor.getBounds(wheel);
	if (r.containsPoint(pt)) return hueCursor.name;	
	rect=gradHueCursor.getBounds(wheel);
	if ((gradHueCursor.visible) && (rect.containsPoint(pt))) return gradHueCursor.name;
	return e.target.name;
}

public function noPenMode(e:MouseEvent):void{
	if (PaintVars.penAtt == "text") return;
	if (PaintVars.penAtt == "stroke") PaintVars.strokeAttributes.basecolor ="none";
	else {
 		switch (PaintVars.fillAttributes.fillstyle){
 			case "onecolor":
 				PaintVars.fillAttributes.alpha = 0;
 				break;
 			case "none":
 				break;
 			default:
 		 	if ((PaintVars.activeHue == "color1")  &&  (PaintVars.fillAttributes.gradalpha != 0)) PaintVars.fillAttributes.alpha = 0;
 		 	else if (PaintVars.fillAttributes.alpha != 0) PaintVars.fillAttributes.gradalpha = 0;
 		 	break;	
 		}
 	}
}

private function selectSBmouseDown(t:Sprite):void {
	cursor = t;
	removeAddedListeners();
	this.addEventListener(MouseEvent.MOUSE_UP, selectSBmouseUp);
	this.addEventListener(MouseEvent.MOUSE_MOVE, selectSBmouseMove);
}

private function removeAddedListeners():void {
	this.removeEventListener(MouseEvent.MOUSE_UP, selectColorMouseUp);
	this.removeEventListener(MouseEvent.MOUSE_MOVE, selectColorMouseMove);
	this.removeEventListener(MouseEvent.MOUSE_UP, selectSBmouseUp);
	this.removeEventListener(MouseEvent.MOUSE_MOVE, selectSBmouseMove);
}

private function selectSBmouseUp(evt:MouseEvent):void {
	evt.preventDefault();
	cursor = null;
	removeAddedListeners();
	updateElement(true);
	PaintVars.getKeyBoardEvents();
}

private function selectSBmouseMove(e:MouseEvent):void {
	e.preventDefault();
	var dx:Number = e.stageX - PaintVars.getScreenX(colorSB, PaintEditor);
	var dy:Number = e.stageY - PaintVars.getScreenY(colorSB, PaintEditor);
	var rect:Rectangle = nopen.getBounds(nopen.parent);
	var nofill:Boolean = rect.containsPoint(new Point(dx, dy));
	dx = (dx < 0) ? 0 : (dx > colorSBsize) ? colorSBsize : dx;
	dy = (dy < 0) ? 0 : (dy > colorSBsize) ? colorSBsize : dy;
	dy = colorSBsize - dy;
  
	var s:Number = Math.floor ((dx/colorSBsize) * 100) / 100; 
	var b:Number = Math.floor ((dy/colorSBsize) * 100) / 100; 
	nofill = nofill || ((dx==0) && (dy == 0) && (PaintVars.penAtt != "text"));
	
	if (PaintVars.penAtt == "fill")  {
		if (PaintVars.activeHue == "color1")  PaintVars.fillAttributes.alpha =  (nofill &&  (PaintVars.fillAttributes.gradalpha != 0)) ? 0 :1; 
 	  else PaintVars.fillAttributes.gradalpha = (nofill && (PaintVars.fillAttributes.alpha != 0)) ? 0 :1; 
	}
	var obj:Object = getColorState();
	if ((PaintVars.penAtt == "fill") && (PaintVars.activeHue == "color2")){
		obj["gradsat"] = s;	
		obj["gradbright"] = b;	
		obj["gradcolor"] = Color.fromHSV(obj["gradhue"] ,	obj["gradsat"] , obj["gradbright"]);	
	}
	else {
		obj["saturation"] = s;	
		obj["brightness"] = b;
		obj["basecolor"] = Color.fromHSV(obj["hue"], obj["saturation"], obj["brightness"]);
		if (nofill && (PaintVars.penAtt == "stroke") && changeIsValid()) obj["basecolor"] = "none";
		else if (PaintVars.penAtt == "fill") obj["alpha"] =( nofill && (PaintVars.strokeAttributes.basecolor != "none") ) ? 0 : 1;
		}
	setSampleColor(fillSwatch);
	setSampleColor(strokeSwatch);
	setSampleTextColor();
	updateColorCursors();
	updateFillThumbs();
	updateElement(false);
}
	
public function changeIsValid():Boolean{
	if (PaintVars.selectedElement && (PaintVars.selectedElement.tagName == "polyline") && (PaintVars.strokeAttributes.basecolor == "none")) return false;
	return true;
}
	
private function selectColorMouseDown(t:Sprite): void {
	cursor = t;
	if ((getBaseColor() != "none") && (getBaseColor() == 0)) {
		var obj:Object = getColorState();
		var huetype:String = (PaintVars.activeHue == "color1") ? "hue" : "gradhue";
		var sattype:String = (PaintVars.activeHue == "color1") ? "saturation" : "gradsat";
		var brighttype:String = (PaintVars.activeHue == "color1") ? "brightness" : "gradbright";
		var rgbfor:String = (PaintVars.activeHue == "color1") ? "basecolor" : "gradcolor";
		obj[rgbfor] = Color.fromHSV(obj[huetype], 1, 1);
		obj[sattype] = 1;
		obj[brighttype] = 1;
	}
	removeAddedListeners();
	this.addEventListener(MouseEvent.MOUSE_UP, selectColorMouseUp);
	this.addEventListener(MouseEvent.MOUSE_MOVE, selectColorMouseMove);
}

private function selectColorMouseUp(evt:MouseEvent):void{
	evt.preventDefault();
	cursor = null;
	removeAddedListeners();
	updateSettings();
	updateElement(true);
	PaintVars.getKeyBoardEvents();
}

private function selectColorMouseMove(e:MouseEvent):void{
	e.preventDefault();
	if (cursor == null) return;
	var dx:Number = e.stageX - PaintVars.getScreenX(wheel, PaintEditor);
	var dy:Number = e.stageY - PaintVars.getScreenY(wheel, PaintEditor);
	var cx:Number = wheelSize/2;
	var	cy:Number =  wheelSize/2;
	var angle:Number = ((Math.atan2(cy - dy, cx - dx)  * (180/Math.PI))-90) % 360;
	if (angle < 0) angle +=360;
	var obj:Object = getColorState();
	var huetype:String = (PaintVars.activeHue == "color1") ? "hue" : "gradhue";
	var sattype:String = (PaintVars.activeHue == "color1") ? "saturation" : "gradsat";
	var brighttype:String = (PaintVars.activeHue == "color1") ? "brightness" : "gradbright";
	var rgbfor:String = (PaintVars.activeHue == "color1") ? "basecolor" : "gradcolor";
	obj[huetype] = Math.floor(angle);	
	obj[rgbfor] = Color.fromHSV(obj[huetype], obj[sattype], obj[brighttype]);
//	updateSettings();	
	setSampleColor(fillSwatch);
	setSampleColor(strokeSwatch);
	setSampleTextColor();
	updateColorCursors();
	updateFillThumbs();
	changeSBtopRightCorner(PaintVars.penAtt);
	var val:* = getHueValue();
	paintSatBright(val, 4);
	updateElement(false);
}

private function changeSatBright(s:Number, b:Number):void {
	var obj:Object = getColorState();
	obj["alpha"] = 1;
	var sattype:String = (PaintVars.activeHue == "color1") ? "saturation" : "gradsat";
	var brighttype:String = (PaintVars.activeHue == "color1") ? "brightness" : "gradbright";
	var rgbfor:String = (PaintVars.activeHue == "color1") ? "basecolor" : "gradcolor";
	obj[sattype] = s;
	obj[brighttype] = b;
	obj[rgbfor] = Color.fromHSV(obj["hue"], obj["saturation"], obj["brightness"]);	
	updateSettings();	
	updateElement(true);
}

public function changeToFill(e:MouseEvent):void{
	textPanel.visible = false;
	PaintVars.penAtt = "fill";
	selectTab(fillTab)
	PaintVars.activeHue = "color1";
	updateSettings();
	}
	
public function changeToBorder(e:MouseEvent):void{
	textPanel.visible = false;
	PaintVars.penAtt = "stroke";
	selectTab(borderTab)
	PaintVars.activeHue = "color1";
	updateSettings();
}

public function changeToText(e:MouseEvent):void{
	textPanel.visible = true;
	PaintVars.penAtt = "text";
	selectTab(textTab);
	PaintVars.activeHue = "color1";
	updateSettings();
}

//////////////////////////////////
//  Pen and Fill options
/////////////////////////////////

private function showPenSizes():void {
	var key:String = PaintVars.textIsSelected() ? "textstroke" : "strokewidth"; 
	selectPenSize(pensizes.indexOf(PaintVars.strokeAttributes[key]));
	(sizeSelector.parent).visible = true;
}

private function hidePenSizes():void { (sizeSelector.parent).visible = false }

private function selectPenSize(n:int):void {
	for(var i:int=0;i< sizeSelector.numChildren;i++){
		var elem:Sprite=sizeSelector.getChildAt(i) as Sprite;
		var g:Graphics = elem.graphics;
		var dotg:Graphics=(elem.getChildAt(0) as Shape).graphics;
		var bkgc:uint = (i == n) ? CSS.overColor : CSS.fontHighlight;
		var dotc:uint = (i == n) ? CSS.fontHighlight : 0;
		g.lineStyle(0.5,CSS.borderColor,1,true);
		g.beginFill(bkgc);
		g.drawRect(1,1,slotsize - 2, slotsize - 2);
		g.endFill();
		dotg.beginFill(dotc);
		dotg.drawCircle(slotsize / 2, slotsize / 2, pensizes[i]);
		dotg.endFill();
	}
}

private function sizeIsHidden():Boolean{
	if (PaintVars.paintMode == "eraser") return false;
	if (PaintVars.penAtt != "stroke") return true;
	if (PaintVars.penAtt == "text") return true;
	return  (PaintVars.strokeAttributes.basecolor == "none") // && (paintMode != "eraser");
}

private function changeToSimple(b:IconButton):void {
	isSwatch = true;
	wheel.visible =  false;
	swatchSelector.visible = true;
	updateSettings();
	PaintVars.getKeyBoardEvents();
}

private function changeToAdvance(b:IconButton):void { 
	isSwatch = false;
	PaintVars.activeHue = "color1";
	wheel.visible =  true;
	swatchSelector.visible = false;
	updateSettings();
	PaintVars.getKeyBoardEvents();
	}

	private function makeButtonImg(str:String, b:Boolean):Sprite {
		var bimg:Sprite = new Sprite();
		var g:Graphics = bimg.graphics;
		g.clear();
		g.lineStyle(0.5,CSS.borderColor,1,true);
		if (b) g.beginFill(CSS.overColor);
		else {
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

///////////////////////////////////////////////////////////////////
// Text
///////////////////////////////////////////////////////////////////

private function setupTextPalette():void {
	textPanel = new Sprite();
	addChild(textPanel);
	textPanel.visible = false;
	setFontType(textStyleOptions[0]);
	var fonttype:Sprite = makeMenu(textStyleOptions[0], 120);
	textPanel.addChild (fonttype);
	fonttype.x = gap + 10;
	fonttype.y = 40;
	fonttype.addEventListener(MouseEvent.MOUSE_DOWN, selectFont);

	var fontsize:Sprite = makeMenu(PaintVars.textAttributes.fontsize.toString() , 50);
	var txt:TextField = fontsize.getChildAt(0) as TextField;
	txt.setTextFormat(CSS.labelFormat);
	textPanel.addChild (fontsize);
	fontsize.x = gap + 10;
	fontsize.y = 74;
	fontsize.addEventListener(MouseEvent.MOUSE_DOWN, selectFontSize);
}

public function selectFont(e:MouseEvent):void{
	var m:Menu = new Menu(setCurrentFont);
	// Skin the menu for Upstatement Look
	styleMenu();
	for each (var str:String in textStyleOptions) m.addItem(str);
	var t:* = e.target;
	if (t is TextField) t = t.parent;	
	var p:Point = t.localToGlobal(new Point(0, 0));
	m.showOnStage(stage, p.x + t.width, p.y - t.height);
}

public function selectFontSize(e:MouseEvent):void{
	var m:Menu = new Menu(setCurrentFontSize);
	// Skin the menu for Upstatement Look
	styleMenu();
	for each (var str:String in textSizeOptions) m.addItem(str);
	var t:* = e.target;
	if (t is TextField) t = t.parent;	
	var p:Point = t.localToGlobal(new Point(0, 0));
	m.showOnStage(stage, p.x + t.width, p.y - t.height);
}

private function styleMenu():void{
		Menu.font ="Lucida Grande";
		Menu.color = CSS.tabColor;
	  Menu.divisionColor =  Color.scaleBrightness( Menu.color , 0.80);
	  Menu.selectedColor = CSS.overColor; 
		Menu.fontSize =12;
		Menu.fontNormalColor = CSS.offColor;
		Menu.fontSelectedColor =  0xFFFFFF;
		Menu.minHeight = 20;
		Menu.margin = 12;
		Menu.hasShadow = true;
}

public function switchToText(svg:PaintObject):void{
	selectText(textTab);
	var color:uint = svg.getAttribute("fill");
	var hsv:Array =	Color.rgb2hsv(color);
	PaintVars.textAttributes.basecolor =  color; 
	PaintVars.setTextColor (hsv);
	changeFontSizeTo(svg.getAttribute("font-size"));
	var str:String = getFontType(svg.getAttribute("font-family")+svg.getAttribute("font-style")+ svg.getAttribute("font-weight"));
	changeFontTo(str);
}
	
private function setCurrentFont(str:String):void{
	changeFontTo(str);
	updateElement(true)
}

private function changeFontTo(str:String):void{
	var spr:Sprite = textPanel.getChildAt(0) as Sprite;
	var txt:TextField = spr.getChildAt(0) as TextField;
	setFontType(str);
	var form:TextFormat = new TextFormat(PaintVars.textAttributes.family, 12, CSS.offColor, PaintVars.textAttributes.fontstyle != "normal");
	txt.text = str;
	if ("Pleasant" == str) txt.y = 6;
	else txt.y = 4;
	txt.setTextFormat(form);
	setSampleTextColor();	
}

private function setCurrentFontSize(str:String):void{
	changeFontSizeTo(str);
	updateElement(true)
}

private function changeFontSizeTo(str:String):void{
	PaintVars.textAttributes.fontsize = Number(str);
	var spr:Sprite = textPanel.getChildAt(1) as Sprite;
	var txt:TextField = spr.getChildAt(0) as TextField;
	txt.text = str;
	txt.setTextFormat(CSS.labelFormat);
	setSampleTextColor();	
}
 
	private function makeMenu(label:String, dw:int):Sprite {
		var menui:Sprite = new Sprite();
		var form:TextFormat = new TextFormat(PaintVars.textAttributes.family, 12, CSS.offColor, PaintVars.textAttributes.fontstyle != "normal");
		var tf:TextField = Resources.makeLabel(label, form);
		tf.x = 5;
		tf.y = 4;
		menui.addChild(tf);
		var w:int = dw;
		var h:int = 30;
		var g:Graphics = menui.graphics;
		g.clear();
		g.lineStyle(0.5,CSS.borderColor,1,true);
		var matr:Matrix = new Matrix();
 		matr.createGradientBox(32, 32, Math.PI / 2, 0, 0);
 		g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], matr);  
		g.drawRoundRect(0, 0, dw, 26, 12);
 		g.endFill();
 		var dx:int = dw - 16;
 		var dy:int = 10;
 		g.lineStyle(0, 0, 0);
		g.beginFill(0xA6A8AC);
		g.moveTo(dx, dy);
		g.lineTo(dx + 10, dy);
		g.lineTo(dx + 5, dy + 5);
		g.endFill();
		return menui;
	}
	
	private function drawArrowDown():Shape {
		var arrow:Shape = new Shape();
		var g:Graphics = arrow.graphics;
		g.clear();
		return arrow;
	}

private function getFontType(str:String):String {
	switch (str) {
		case "Trebuchet MSnormalnormal": return "Casual";
		case "Arial Blacknormalnormal": return "Brave";		
		case "Courier Newnormalbold": return "Predictable";	
		case "Times New Romannormalnormal": return "Formal";		
		case "Comic Sans MSnormalbold": return "Trendy";		
		case "Verdanaitaliclighter": return "Cool";
		case "Helveticanormalnormal": return "Pleasant";
		default: 
			return "Casual";
	}
}

private function setFontType(str:String):void{
	switch (str) {
		case "Casual":
			PaintVars.textAttributes.family = "Trebuchet MS";
			PaintVars.textAttributes.fontstyle = "normal";
			PaintVars.textAttributes.weight = "normal";
			break;
		case	"Brave":
			PaintVars.textAttributes.family = "Arial Black";
			PaintVars.textAttributes.fontstyle = "normal";
			PaintVars.textAttributes.weight = "normal";
			break;
		case "Predictable":
			PaintVars.textAttributes.family = "Courier New";
			PaintVars.textAttributes.fontstyle = "normal";
			PaintVars.textAttributes.weight = "bold";
			break;
		case "Trendy":
			PaintVars.textAttributes.family = "Comic Sans MS";
			PaintVars.textAttributes.fontstyle = "normal";
			PaintVars.textAttributes.weight = "bold";
			break;
		case "Formal":
			PaintVars.textAttributes.family = "Times New Roman";
			PaintVars.textAttributes.fontstyle = "normal";
			PaintVars.textAttributes.weight = "normal";
			break;
		case "Cool":
			PaintVars.textAttributes.family = "Verdana";
			PaintVars.textAttributes.fontstyle = "italic";
			PaintVars.textAttributes.weight = "lighter";
			break;
		case "Pleasant":
			PaintVars.textAttributes.family = "Helvetica";
			PaintVars.textAttributes.fontstyle = "normal";
			PaintVars.textAttributes.weight = "normal";
			break;
		default: 
			break;
	}
}


}}