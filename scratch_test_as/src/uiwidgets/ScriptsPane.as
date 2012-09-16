// ScriptsPane.as
// John Maloney, August 2009
//
// A ScriptsPane is a working area that holds blocks and stacks. It supports the
// logic that highlights possible drop targets as a block is being dragged and
// decides what to do when the block is dropped.

package uiwidgets {
	import flash.display.*;
	import flash.geom.Point;
	import blocks.*;
	import scratch.ScratchObj;

public class ScriptsPane extends ScrollFrameContents {

	private const INSERT_NORMAL:int = 0;
	private const INSERT_ABOVE:int = 1;
	private const INSERT_SUB1:int = 2;
	private const INSERT_SUB2:int = 3;

	private var viewedObj:ScratchObj;

	private var possibleTargets:Array = [];
	private var nearestTarget:Array = [];
	private var feedbackShape:BlockShape;

	public function ScriptsPane() {
		hExtra = vExtra = 100;
		createTexture();
		addFeedbackShape();
	}

	private function createTexture():void {
		var bgColor:int = 0xD7D7D7;
		var c1:int = 0xCBCBCB;
		var c2:int = 0xC8C8C8;
		texture = new BitmapData(23, 23, false, bgColor);
		texture.setPixel(11, 0, c1);
		texture.setPixel(10, 1, c1);
		texture.setPixel(11, 1, c2);
		texture.setPixel(12, 1, c1);
		texture.setPixel(11, 2, c1);
		texture.setPixel(0, 11, c1);
		texture.setPixel(1, 10, c1);
		texture.setPixel(1, 11, c2);
		texture.setPixel(1, 12, c1);
		texture.setPixel(2, 11, c1);	
	}

	public function viewScriptsFor(obj:ScratchObj):void {
		// view the blocks for the given object
		saveScripts();
		while (numChildren > 0) {
			var child:DisplayObject = removeChildAt(0);
//			child.cacheAsBitmap = false; // xxx reduces sprite change timing glitch for Eric's livingcoding (but uses more memory)
		}
		viewedObj = obj;
		if (viewedObj != null) {
			for each (var b:Block in viewedObj.scripts) {
				b.cacheAsBitmap = true;
				addChild(b);
			}
		}
		updateSize();
		x = y = 0;  // reset scroll offset
	}

	public function saveScripts():void {
		// save the blocks in this pane in the viewed objects scripts list
		if (viewedObj == null) return;
		var newScripts:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var o:* = getChildAt(i);
			if (o is Block) newScripts.push(o);
		}
		viewedObj.scripts = newScripts;
	}

	public function setScale(newScale:Number):void {
		newScale = Math.max(0.1, Math.min(newScale, 10.0));
		scaleX = scaleY = newScale;
		updateSize();
	}

	public function prepareToDrag(b:Block):void {
		findTargetsFor(b);
		nearestTarget = null;
		b.scaleX = b.scaleY = scaleX;
		addFeedbackShape();
	}

	public function draggingDone():void {
		hideFeedbackShape();
		possibleTargets = [];
		nearestTarget = null;
	}

	public function updateFeedbackFor(b:Block):void {
		nearestTarget = nearestTargetForBlockIn(b, possibleTargets);
		if (nearestTarget != null) {
			var localP:Point = globalToLocal(nearestTarget[0]);
			feedbackShape.x = localP.x;
			feedbackShape.y = localP.y;
			feedbackShape.visible = true;
			if (b.isReporter) {
				var t:* = nearestTarget[1];
				if (t is Block) feedbackShape.copyFeedbackShapeFrom(Block(t).base, true);
				if (t is BlockArg) feedbackShape.copyFeedbackShapeFrom(BlockArg(t).base, true);
			} else {
				feedbackShape.copyFeedbackShapeFrom(b.base, false);
			}
		} else {
			hideFeedbackShape();
		}
	}

	public function allStacks():Array {
		var result:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var child:DisplayObject = getChildAt(i);
			if (child is Block) result.push(child);
		}
		return result;
	}

	public function blockDropped(b:Block):void {
		var localP:Point = globalToLocal(new Point(b.x, b.y));
		b.x = localP.x;
		b.y = localP.y;
		b.scaleX = b.scaleY = 1;
		addChild(b);
		b.allBlocksDo(function(b:Block):void { b.cache = null }); // clear variable caches
		if (nearestTarget == null) {
			b.cacheAsBitmap = true;
		} else {
			b.cacheAsBitmap = false;
			if (b.isReporter) {
				Block(nearestTarget[1].parent).replaceArgWithBlock(nearestTarget[1], b, this);
			} else {
				var targetCmd:Block = nearestTarget[1];
				switch (nearestTarget[2]) {
				case INSERT_NORMAL:
					targetCmd.insertBlock(b);
					break;
				case INSERT_ABOVE:
					targetCmd.insertBlockAbove(b);
					break;
				case INSERT_SUB1:
					targetCmd.insertBlockSub1(b);
					break;
				case INSERT_SUB2:
					targetCmd.insertBlockSub2(b);
					break;
				}
			}
		}
		saveScripts();
		updateSize();
	}

	private function findTargetsFor(b:Block):void {
		possibleTargets = [];
		var i:int;
		for (i = 0; i < numChildren; i++) {
			var child:DisplayObject = getChildAt(i);
			if (child is Block) {
				var target:Block = Block(child);
				if (b.isReporter) {
					findReporterTargetsIn(target);
				} else {
					if (!target.isReporter) {
						if ((b.nextBlock == null) && !b.isTerminal && !target.isHat) {
							// b is a single, non-terminal command block and target
							// is not a hat so bottom of b can connect to top of target
							var p:Point = target.localToGlobal(new Point(0, -(b.height - BlockShape.NotchDepth)));
							possibleTargets.push([p, target, INSERT_ABOVE]);
						}
						if (!b.isHat) findCommandTargetsIn(target, b.bottomBlock().isTerminal);
					}
				}
			}
		}
	}

	private function findCommandTargetsIn(stack:Block, endsWithTerminal:Boolean):void {
		var target:Block = stack;
		while (target != null) {
			var p:Point = target.localToGlobal(new Point(0, 0));
			if (!target.isTerminal && (!endsWithTerminal || (target.nextBlock == null))) {
				// insert stack after target block:
				// target block must not be a terminal
				// if stack does not end with a terminal, it can be inserted between blocks
				// otherwise, it can only inserted after the final block of the substack
				p = target.localToGlobal(new Point(0, target.base.height - 3));
				possibleTargets.push([p, target, INSERT_NORMAL]);
			}
			if (target.base.canHaveSubstack1()) {
				p = target.localToGlobal(new Point(15, target.base.substack1y()));
				possibleTargets.push([p, target, INSERT_SUB1]);
			}
			if (target.base.canHaveSubstack2()) {
				p = target.localToGlobal(new Point(15, target.base.substack2y()));
				possibleTargets.push([p, target, INSERT_SUB2]);
			}
			if (target.subStack1 != null) findCommandTargetsIn(target.subStack1, endsWithTerminal);
			if (target.subStack2 != null) findCommandTargetsIn(target.subStack2, endsWithTerminal);
			target = target.nextBlock;
		}
	}

	private function findReporterTargetsIn(stack:Block):void {
		var b:Block = stack, i:int;
		while (b != null) {
			for (i = 0; i < b.args.length; i++) {
				var o:DisplayObject = b.args[i];
				if ((o is Block) || (o is BlockArg)) {
					var p:Point = o.localToGlobal(new Point(0, 0));
					possibleTargets.push([p, o, INSERT_NORMAL]);
					if (o is Block) findReporterTargetsIn(Block(o));
				}
			}
			if (b.subStack1 != null) findReporterTargetsIn(b.subStack1);
			if (b.subStack2 != null) findReporterTargetsIn(b.subStack2);
			b = b.nextBlock;
		}
	}

	private function addFeedbackShape():void {
		if (feedbackShape == null) feedbackShape = new BlockShape();
		feedbackShape.setWidthAndTopHeight(10, 10);
		hideFeedbackShape();
		addChild(feedbackShape);
	}

	private function hideFeedbackShape():void {
		feedbackShape.visible = false;
	}

	private function nearestTargetForBlockIn(b:Block, targets:Array):Array {
		var threshold:int = b.isReporter ? 15 : 25;
		var i:int, minDist:int = 100000;
		var nearest:Array;
		var bTopLeft:Point = new Point(b.x, b.y);
		var bBottomLeft:Point = new Point(b.x, b.y + b.height - 3);

		for (i = 0; i < targets.length; i++) {
			var item:Array = targets[i];
			var dist:Number = Point.distance(bTopLeft, item[0]);
			if ((dist < minDist) && (dist < threshold) && dropCompatible(b, item[1])) {
				minDist = dist;
				nearest = item;
			}
		}
		return (minDist < threshold) ? nearest : null;
	}

	private function dropCompatible(droppedBlock:Block, target:DisplayObject):Boolean {
		if (!droppedBlock.isReporter) return true; // dropping a command block
		var dropType:String = droppedBlock.type;
		var targetType:String = (target is Block) ? Block(target).type : BlockArg(target).type;
		if (targetType == "m") return false;
		if (targetType == "b") return dropType == "b";
		return true;
	}

}}
