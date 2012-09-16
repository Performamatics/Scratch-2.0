// BlockPalette.as
// John Maloney, August 2009
//
// A BlockPalette holds the blocks for the selected category.
// The mouse handling code detects when a Block's parent is a BlocksPalette and
// creates a copy of that block when it is dragged out of the palette.

package ui {
	import uiwidgets.ScrollFrameContents;

public class BlockPalette extends ScrollFrameContents {

	public function BlockPalette():void {
		super();
		this.color = 0xE0E0E0;
	}

}}
