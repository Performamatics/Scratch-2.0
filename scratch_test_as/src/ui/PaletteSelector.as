// PaletteSelector.as
// John Maloney, August 2009
//
// PaletteSelector is a UI widget that holds set of PaletteSelectorItems
// and supports changing the selected category. When the category is changed,
// the blocks palette is filled with the blocks for the selected category.

package ui {
	import flash.display.*;
	import scratch.PaletteBuilder;

public class PaletteSelector extends Sprite {

	public var selectedCategory:int = 0;
	private var app:Scratch;

	public function PaletteSelector(app:Scratch) {
		this.app = app;
		initCategories(Specs.categories.slice(1, 11));
	}

	public function select(id:int):void {
		for (var i:int = 0; i < numChildren; i++) {
			var item:PaletteSelectorItem = getChildAt(i) as PaletteSelectorItem;
			item.setSelected(item.categoryID == id);
		}
		selectedCategory = id;
		new PaletteBuilder(app).showBlocksForCategory(selectedCategory);
	}

	private function initCategories(specs:Array):void {
		const numberOfRows:int = 5;
		const w:int = 200;
		const startY:int = 3;
		var itemH:int;
		var x:int;
		var y:int = startY;
		for (var i:int = 0; i < specs.length; i++) {
			if (i == numberOfRows) {
				x = w / 2;
				y = startY;
			}
			var entry:Array = specs[i];
			var item:PaletteSelectorItem = new PaletteSelectorItem(entry[0], entry[1], entry[2]);
			itemH = item.height;
			item.x = x;
			item.y = y;
			addChild(item);
			y += itemH;
		}
		setWidthHeightColor(w, startY + (numberOfRows * itemH) + 5);
	}

	private function setWidthHeightColor(w:int, h:int):void {
		var g:Graphics = graphics;
		g.clear();
		g.beginFill(0xFFFF00, 0); // invisible (alpha = 0) rectangle used to set size
		g.drawRect(0, 0, w, h);
	}

}}
