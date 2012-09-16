// Watcher.as
// Paula Bonta, Summer 2010
// John Maloney, April 2011
//
// Represents a variable display.

package watchers {
	import flash.display.*;
	import flash.filters.BevelFilter;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.*;
	import interpreter.*;
	import scratch.*;
	import uiwidgets.Menu;
	import util.*;

public class Watcher extends Sprite implements DragClient {

	private const format:TextFormat = new TextFormat("Verdana", 10, 0, true);
	private const precision:Number = 1000;

	private const NORMAL_MODE:int = 1;
	private const LARGE_MODE:int = 2;
	private const SLIDER_MODE:int = 3;
	private const TEXT_MODE:int = 4;

	public var target:ScratchObj;
	private var cmd:String;
	private var param:String;
	private var mode:int = NORMAL_MODE;

	private var frame:WatcherFrame;
	private var label:TextField;
	private var readout:WatcherReadout;
	private var slider:Shape;
	private var knob:Shape;

	// stepping
	private var lastValue:*;

	// slider support
	private var sliderMin:Number = 0;
	private var sliderMax:Number = 100;
	private var isDiscrete:Boolean = false;
	private var mouseMoved:Boolean;

	public function Watcher() {
		frame = new WatcherFrame(0x949191, 0xC1C4C7, 8);
		addChild(frame);
		addLabel();
		readout = new WatcherReadout();
		addChild(readout);
		addSliderAndKnob();
		slider.visible = knob.visible = false;
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
	}

	public function initWatcher(target:ScratchObj, cmd:String, param:String, color:int, label: String):void {
		this.target = target;
		this.cmd = cmd;
		this.param = param;
		this.mode = NORMAL_MODE;
		setColor(color);
		setLabel(label);
	}

	public function initForVar(target:ScratchObj, varName:String):void {
		this.target = target;
		this.cmd = "getVar:";
		this.param = varName;
		this.mode = NORMAL_MODE;
		// link to this watcher from its variable
		var v:Variable = target.lookupVar(param);
		if (v != null) v.watcher = this;
		setColor(Specs.variableColor);
		setLabel((target.isStage) ? varName : (target.objName + " " + varName));
	}


	public function isVarWatcherFor(target:ScratchObj, vName:String):Boolean {
		return ((cmd == "getVar:") && (this.target == target) && (param == vName));
	}

	public function setMode(m:int):void {
		mode = m;
		readout.beLarge(mode == LARGE_MODE);
		fixLayout();
	}

	public function setColor(c:int):void { readout.setColor(c) }

	public function setSliderMinMax(min:Number, max:Number, val:Number):void {
		// Set slider range. Make it discrete if min, max, and current value are all integral.
		sliderMin = min;
		sliderMax = max;
		isDiscrete = (int(min) == min) && (int(max) == max) && (int(val) == val);
	}

	public override function hitTestPoint(globalX:Number, globalY:Number, shapeFlag:Boolean = true):Boolean {
		if (!visible) return false;
		if (frame.visible) return frame.hitTestPoint(globalX, globalY, shapeFlag);
		return readout.hitTestPoint(globalX, globalY, shapeFlag);
	}

	/* Stepping */

	public function step(runtime:ScratchRuntime):void {
		var newValue:* = getValue(runtime);
		if (newValue != lastValue) {
			showValue(newValue);
			runtime.interp.redraw();
		}
		lastValue = newValue;
		if (cmd == "getVar:") { // update in case variable name or sprite name changes 
			setLabel((target.isStage) ? param : (target.objName + " " + param)); // parmam is the variable name
		}
	}

	private function showValue(value:*):void {
		if ((value is Number) && (Math.abs(value) > 0.001)) {
			// show at most N digits after the decimal point
			value = Math.round(value * precision) / precision;
		}
		readout.setContents(value.toString());
		fixLayout();
	}

	private function getValue(runtime:ScratchRuntime):* {
		if (target == null) return "";
		var o:ScratchObj = ScratchObj(target);
		if (targetIsVariable()) {
			var v:Variable = o.lookupVar(param);
			return (v == null) ? "unknown var: " + param : v.value;
		}
		if (o is ScratchStage) {
			switch(cmd) {
				case "backgroundIndex": return ScratchStage(o).costumeNumber();
				case "tempo": return ScratchStage(o).tempoBPM;
			}
		}
		if (o is ScratchSprite) {
			switch(cmd) {
				case "costumeIndex": return ScratchSprite(o).costumeNumber();
				case "xpos": return ScratchSprite(o).scratchX;
				case "ypos": return ScratchSprite(o).scratchY;
				case "heading": return ScratchSprite(o).direction;
				case "scale": return ScratchSprite(o).getSize();
			}
		}
		switch(cmd) {
			case "volume": return o.volume;
			case "answer": return runtime.lastAnswer;
			case "timer": return Math.round(10 * runtime.timer()) / 10; // round to 10's of seconds
			case "soundLevel": return runtime.soundLevel();
			case "isLoud": return runtime.isLoud();
			case "sensor:": return runtime.getSensor(param);
			case "sensorPressed:": return runtime.getBooleanSensor(param);
		}
		return "unknown: " + cmd;
	}

	private function targetIsVariable():Boolean { return (cmd == "getVar:") }

	/* Layout */

	private function addLabel():void {
		label = new TextField();
		label.type = "dynamic";
		label.selectable = false;
		label.defaultTextFormat = format;
		label.text = "";
		label.width = label.textWidth + 5;
		label.height = label.textHeight + 5
		label.x = 4;
		label.y = 2;
		addChild(label);
	}

	private function setLabel(s:String):void {
		if (!label.visible || label.text == s) return; // no change
		label.text = s;
		label.width = label.textWidth + 5;
		label.height = label.textHeight + 5;
		fixLayout();
	}

	private function addSliderAndKnob():void {
		slider = new Shape(); // slider is drawn by fixLayout()
		var f:BevelFilter = new BevelFilter(2);
		f.angle = 225;
		f.shadowAlpha = 0.5;
		f.highlightAlpha = 0.5;
		slider.filters = [f];
		addChild(slider);

		knob = new Shape();
		var g:Graphics = knob.graphics;
		g.lineStyle(1, 0x808080);
		g.beginFill(0xFFFFFF);
		g.drawCircle(5, 5, 5);
		f = new BevelFilter(2);
		f.blurX = f.blurY = 5;
		knob.filters = [f];
		addChild(knob);
	}

	private function fixLayout():void {
		adjustReadoutSize();
		if (mode == LARGE_MODE) {
			frame.visible = label.visible = false;
			readout.x = 0;
			readout.y = 3;
		} else {
			frame.visible = label.visible = true;
			readout.x = label.width + 8;
			readout.y = 3;
		}
		if (mode == SLIDER_MODE) {
			slider.visible = knob.visible = true;
			slider.x = 6;
			slider.y = 22;

			// re-draw slider
			var g:Graphics = slider.graphics;
			g.clear();
			g.beginFill(0xC0C0C0);
			g.drawRoundRect(0, 0, frame.w - 12, 5, 5, 5);

			setKnobPosition();
		} else {
			slider.visible = knob.visible = false;
		}
	}

	private function adjustReadoutSize():void {
		frame.w = label.width + readout.width + 15;
		frame.h = (mode == NORMAL_MODE) ? 21 : 31;
		frame.setWidthHeight(frame.w, frame.h);
	}

	private function setKnobPosition():void {
		var fraction:Number = (Number(readout.contents) - sliderMin) / (sliderMax - sliderMin);
		fraction = Math.max(0, Math.min(fraction, 1));
		var xOffset:int = Math.round(fraction * (slider.width - 10));
		knob.x = slider.x + xOffset;
		knob.y = slider.y - 3;
	}

	/* Menu */

	public function menu():Menu {
		var m:Menu = new Menu(handleMenu);
		m.addItem("normal readout", 1);
		m.addItem("large readout", 2);
		if (targetIsVariable()) {
			m.addItem("slider", 3);
//			m.addItem("text", 4);
		}
		m.addLine();
		m.addItem("hide", 5);
		return m;
	}

	private function handleMenu(item:int):void {
		if ((1 <= item) && (item <= 3)) setMode(item);
		if (item == 5) visible = false;
	}

	/* Slider */

	private function mouseDown(evt:MouseEvent):void {
		if (mode != SLIDER_MODE) return;
		var p:Point = globalToLocal(new Point(evt.stageX, evt.stageY));
		if (p.y > 20) Scratch(root).gh.setDragClient(this, evt);
	}

	public function dragBegin(evt:MouseEvent):void {
		mouseMoved = false;
	}

	public function dragMove(evt:MouseEvent):void {
		var p:Point = globalToLocal(new Point(evt.stageX, evt.stageY));
		var xOffset:Number = p.x - slider.x - 4;
		setSliderValue(((xOffset / (slider.width - 10)) * (sliderMax - sliderMin)) + sliderMin);
		mouseMoved = true;
	}

	public function dragEnd(evt:MouseEvent):void {
		var p:Point = globalToLocal(new Point(evt.stageX, evt.stageY));
		if (!mouseMoved) clickAt(p.x);
	}

	private function clickAt(localX:Number):void {
		var sign:Number = (localX < knob.x) ? -1 : 1;
		var delta:Number = (isDiscrete) ? sign : sign * ((sliderMax - sliderMin) / 100.0);
		setSliderValue(Number(readout.contents) + delta);
	}

	private function setSliderValue(newValue:Number):void {
		var sliderVal:Number = isDiscrete ? Math.round(newValue) : Math.round(newValue * 100) / 100;
		sliderVal = Math.max(sliderMin, Math.min(sliderVal, sliderMax));
		if (target != null) target.setVarTo(param, sliderVal);
		showValue(sliderVal);
	}

	// JSON save/restore

	public function writeJSON(json:JSON_AB):void {
		json.writeKeyValue("target", target.objName);
		json.writeKeyValue("cmd", cmd);
		json.writeKeyValue("param", param);
		json.writeKeyValue("color", cmd);
		json.writeKeyValue("label", label.text);
		json.writeKeyValue("mode", mode);
		json.writeKeyValue("sliderMin", sliderMin);
		json.writeKeyValue("sliderMax", sliderMax);
		json.writeKeyValue("isDiscrete", isDiscrete);
		json.writeKeyValue("x", x);
		json.writeKeyValue("y", y);
		json.writeKeyValue("visible", visible);
	}

	public function readJSON(obj:Object):void {
		if (obj.cmd == "getVar:") initForVar(obj.target, obj.param);
		else initWatcher(obj.target, obj.cmd, obj.param, obj.color, obj.label);
		sliderMin = obj.sliderMin;
		sliderMax = obj.sliderMax;
		isDiscrete = obj.isDiscrete;
		setMode(obj.mode);
		x = obj.x;
		y = obj.y;
		visible = obj.visible;
	}

}}
