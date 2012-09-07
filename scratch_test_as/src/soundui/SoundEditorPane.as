//------------------------------------------------------------------------------
//  
//  Package
//  
//------------------------------------------------------------------------------

package soundui
{
	
	//--------------------------------------------------------------------------
	//  
	//  Import
	//  
	//--------------------------------------------------------------------------
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.media.Sound;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import sound.mp3.*;
	
	import soundutil.SampledSound;
	import soundutil.SoundController;
	import soundutil.SoundControllerState;
	import soundutil.SoundControllerStateEvent;
	import soundutil.filters.FadeInFilter;
	import soundutil.filters.FadeOutFilter;
	import soundutil.filters.Filter;
	import soundutil.filters.ReverseFilter;
	
	import uiwidgets.Button;
	import uiwidgets.Menu;
	import uiwidgets.DialogBox;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * Provides the sound editing interface as a DialogBox.
	 * 
	 * @author Anton Nguyen
	 * @date 20110314
	 */
	public class SoundEditorPane extends DialogBox
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		private var _deleteButton:DeleteButton;
		private var _playPauseButton:PlayPauseButton;
		private var _file:FileReference;
		private var _filterButton:Button;
		private var _importButton:Button;
		private var _menu:Menu;
		private var _recording:SampledSound;
		private var _oldRecording:SampledSound;
		private var _originalRecording:SampledSound;
		private var _soundController:SoundController;
		private var _stopButton:StopButton;
		private var _undoButton:UndoButton;
		private var _waveForm:SelectableWaveForm;
		private var _widgetContainer:Sprite;
		
		private var _playheadStart:Number = NaN;
		private var _playheadEnd:Number = NaN;
		
		private var _save:Function;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Creates a new SoundEditorPane.
		 */
		public function SoundEditorPane(saveFunc:Function, recording:SampledSound)
		{
			super();
			
			addTitle("Sound Editor");
			//addAcceptCancelButtons("Save");
			_save = saveFunc;
			addButton("Save", save);
//			addButton("Cancel", cancel);
			
			// work on a clone, if "save" occurs, then write the sound editor's 
			// version as the correct one, if "cancel" occurs, then use the 
			// one that should've been saved by the sound recorder
			_recording = recording.clone();
			_oldRecording = _recording;
			_soundController = new SoundController(_recording);
			_soundController.addEventListener(SoundControllerStateEvent.ENTER, updatePlaybackControls, false, 0, true);
			
			_widgetContainer = new Sprite();
			addWidget(_widgetContainer);
			
			_waveForm = new SelectableWaveForm(_recording, 400, 100);
			_waveForm.y = 75;
			_waveForm.addEventListener(SelectableWaveFormStateEvent.ENTER, updateSelectionTools, false, 0, true);
			_widgetContainer.addChild(_waveForm);
			
			var btnScale:Number = 0.80
			
			_playPauseButton = new PlayPauseButton(playPause);
			_playPauseButton.scaleX = btnScale;
			_playPauseButton.scaleY = btnScale;
			_playPauseButton.turnOn();
			_playPauseButton.x = 0;
			_widgetContainer.addChild(_playPauseButton);
			
			_stopButton = new StopButton(stop);
			_stopButton.scaleX = btnScale;
			_stopButton.scaleY = btnScale;
			_stopButton.turnOff();
			_stopButton.x = _playPauseButton.x + _playPauseButton.width + 5;
			_widgetContainer.addChild(_stopButton);
			
			_deleteButton = new DeleteButton(deleteSelection);
			_deleteButton.scaleX = btnScale;
			_deleteButton.scaleY = btnScale;
			_deleteButton.turnOff();
			_deleteButton.x = _stopButton.x + _stopButton.width + 5;
			_widgetContainer.addChild(_deleteButton);
			
			_undoButton = new UndoButton(undo);
			_undoButton.scaleX = btnScale;
			_undoButton.scaleY = btnScale;
			_undoButton.turnOff();
			_undoButton.x = _deleteButton.x + _deleteButton.width + 5;
			_widgetContainer.addChild(_undoButton);
			
			_menu = new Menu();
			_menu.addItem("Crop", crop);
			_menu.addItem("Reverse", reverseFilter);
			_menu.addItem("Fade In", fadeInFilter);
			_menu.addItem("Fade Out", fadeOutFilter);
//			_menu.addItem("Close Menu", null); 
			
			_filterButton = new Button("Edit", openFilterMenu);
			_filterButton.x = 250;
			_widgetContainer.addChild(_filterButton);
			
			_importButton = new Button("Import MP3", importMP3);
			_importButton.x = 310;
			_widgetContainer.addChild(_importButton);
		}
		
		//  
		//  Properties
		//  
		//----------------------------------------------------------------------
		
		//------------------------------
		//  recording
		//------------------------------
		
		/**
		//----------------------------------------------------------------------
		 * The recording being edited.
		 */
		public function get recording():SampledSound
		{
			return _recording;
		}
		
		public function set recording(value:SampledSound):void
		{
			// it will always remain on
			_undoButton.turnOn();
			
			_oldRecording = _recording;
			
			_recording = value;
			_waveForm.recording = _recording;
			_soundController.sound = _recording;
		}
		
		//------------------------------
		//  selectionStart
		//------------------------------
		
		/**
		 * Returns the byte offset for the recorded sound based on the selection.
		 */
		public function get selectionOffset():int
		{
			var offset:int = int(_waveForm.selectionStart * _recording.bytesTotal / _waveForm.waveWidth);
			offset -= offset % 4;
			
			return offset;
		}
		
		//------------------------------
		//  selectionLimit
		//------------------------------
		
		/**
		 * Returns the byte limit of the selection.
		 */
		public function get selectionLimit():int
		{
			var limit:int = int(_waveForm.selectionEnd * _recording.bytesTotal / _waveForm.waveWidth);
			limit -= limit % 4;
			
			return limit;
		}
		
		//------------------------------
		//  selectionLength
		//------------------------------
		
		/**
		 * Returns the length of the selection.
		 */
		public function get selectionLength():int
		{
			return selectionLimit - selectionOffset;
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		protected function applyFilter(filter:Filter):void
		{
			// stop playback!
			_soundController.stop();
			
			var bytes:ByteArray = new ByteArray();
			bytes.writeBytes(_recording.samples);
			
			filter.apply(bytes, selectionOffset, selectionLength);
			
			// set everything to the new filtered sound
			recording = new SampledSound(bytes);
			
			_waveForm.drawWaveForm();
		}
		
		override public function cancel():void
		{
			// stop playback
			_soundController.stop();
			
			super.cancel();
		}
		
		private function crop():void
		{
			// stop playback!
			_soundController.stop();
			
			var bytes:ByteArray = new ByteArray();
			if (selectionLength > 0)
			{
				bytes.writeBytes(_recording.samples, selectionOffset, selectionLength);
			}
			
			// set everything to the new filtered sound
			recording = new SampledSound(bytes);
			
			_waveForm.drawWaveForm();
			_waveForm.clearSelection();
		}
		
		private function fadeInFilter():void
		{
			applyFilter(new FadeInFilter());
		}
		
		private function fadeOutFilter():void
		{
			applyFilter(new FadeOutFilter());
		}
		
		private function importMP3():void
		{
			// stop playback!
			_soundController.stop();

			_file = new FileReference();
			_file.addEventListener(Event.SELECT, loadMP3, false, 0, true);
			_file.browse([new FileFilter("MP3 files (*.mp3)", "*.mp3")]);
		}
		
		private function reverseFilter():void
		{
			applyFilter(new ReverseFilter());
		}
		
		public function save():void
		{
			// sort of like a cancel
			cancel();
			
			_save(recording);
		}
		
		//----------------------------------------------------------------------
		//  
		//  Event Handlers
		//  
		//----------------------------------------------------------------------
		
		private function loadMP3(event:Event):void
		{
			function fileLoaded(e:Event):void { MP3Loader.load(_file.data, analyzeMP3) }

			_file.addEventListener(Event.COMPLETE, fileLoaded);
			_file.load();
		}
		
		private function analyzeMP3(mp3:Sound):void
		{
			var bytes:ByteArray = new ByteArray();
			var samplesWritten:Number = 0;
			
			do
			{
				samplesWritten = mp3.extract(bytes, 8192);
			} while (samplesWritten > 0);
			
			// average each set of stereo samples to mono samples
			// (tried to do it in the same byte array, for some reason
			// kept getting eof)
			
			/*
			var avgSample:Number = 0;
			var byteLimit:uint = bytes.length / 2;
			for (var i:uint = 0; i < byteLimit; i++)
			{
				bytes.position = i * 2;
				avgSample = (bytes.readFloat() + bytes.readFloat()) / 2;
				bytes.position = i;
				bytes.writeFloat(avgSample);
			}
			
			// truncates
			bytes.length = bytes.position;
			*/
			
			var avgBytes:ByteArray = new ByteArray();
			bytes.position = 0;
			while (bytes.bytesAvailable)
			{
				avgBytes.writeFloat((bytes.readFloat() + bytes.readFloat()) / 2);
			}
			
			// resets stuff
			recording = new SampledSound(avgBytes, 44100);
			
			_waveForm.drawWaveForm();
		}
		
		private function openFilterMenu():void
		{
			var pt:Point = new Point(_filterButton.x, _filterButton.y);
			pt = _filterButton.parent.localToGlobal(pt);
			
			_menu.showOnStage(stage, pt.x, pt.y);
		}
		
		private function undo():void
		{
			// stop playback
			_soundController.stop();
			
			// set a new recording
			recording = _oldRecording;
			
			// redraw form
			_waveForm.drawWaveForm();
		}
		
		private function deleteSelection():void
		{
			// stop playback first
			_soundController.stop();
			
			var startPos:int = int(_waveForm.selectionStart * _recording.bytesTotal / _waveForm.waveWidth);
			startPos -= startPos % 4;
			var endPos:int = int(_waveForm.selectionEnd * _recording.bytesTotal / _waveForm.waveWidth);
			endPos -= endPos % 4;
			
			var newBytes:ByteArray = new ByteArray();
			
			if (startPos > 0)
			{
				newBytes.writeBytes(_recording.samples, 0, startPos);
			}
			
			if (endPos + 4 < _recording.bytesTotal)
			{
				newBytes.writeBytes(_recording.samples, endPos + 4);
			}
			
			// keep the old one for 1 level of undo
			recording = new SampledSound(newBytes);
			
			// redraw form
			_waveForm.drawWaveForm();
		}
		
		private function playPause():void
		{
			switch (_soundController.state)
			{
				case SoundControllerState.PLAYING:
				{
					_soundController.pause();
				}
					break;
				case SoundControllerState.PAUSED:
				{
					if (_waveForm.state == SelectableWaveFormState.SELECTED)
					{
						// need to make sure playhead is in bounds of selection
						if (_waveForm.playhead.x >= _waveForm.selectionStart && _waveForm.playhead.x <= _waveForm.selectionEnd)
						{
							// within bounds, just resume playback
							_soundController.play();
						}
						else
						{
							// THIS GENERALLY WON'T HAPPEN
							// the code in SelectableWaveForm prevents most 
							// out of bounds from occurring
							
							// not within bounds, meaning, the selection was recently added
							// or the selection was changed when paused
							// reassign the samples used for playback
							var startPos:int = int(_waveForm.selectionStart * _recording.bytesTotal / _waveForm.waveWidth);
							startPos -= startPos % 4;
							var endPos:int = int(_waveForm.selectionEnd * _recording.bytesTotal / _waveForm.waveWidth);
							endPos -= endPos % 4;
							
							// ensures the playhead is always on its own track
							// independent of selection when playback occurs
							_playheadStart = _waveForm.selectionStart;
							_playheadEnd = _waveForm.selectionEnd;
							
							var newBytes:ByteArray = new ByteArray();
							newBytes.writeBytes(_recording.samples, startPos, endPos - startPos);
							_soundController.sound = new SampledSound(newBytes, _recording.rate);
							_soundController.stop();
							_soundController.play();
						}
					}
					else
					{
						// just simply resume
						_soundController.play();
					}
				}
					break;
				case SoundControllerState.STOPPED:
				{
					if (_waveForm.state == SelectableWaveFormState.SELECTED)
					{
						// ensures the playhead is always on its own track
						// independent of selection when playback occurs
						_playheadStart = _waveForm.selectionStart;
						_playheadEnd = _waveForm.selectionEnd;
						
						// pos stuff
						startPos = _waveForm.selectionStart * _recording.bytesTotal / _waveForm.waveWidth;
						startPos -= startPos % 4;
						endPos = _waveForm.selectionEnd * _recording.bytesTotal / _waveForm.waveWidth;
						endPos -= endPos % 4;
						
						newBytes = new ByteArray();
						newBytes.writeBytes(_recording.samples, startPos, endPos - startPos);
						_soundController.sound = new SampledSound(newBytes, _recording.rate);
						_soundController.play();
					}
					else
					{
						_playheadStart = NaN;
						_playheadEnd = NaN;
						
						_soundController.sound = _recording;
						_soundController.play();
					}
				}
					break;
			}
		}
		
		/**
		 * Stops playback.
		 */
		private function stop():void
		{
			if (_soundController.state != SoundControllerState.STOPPED)
			{
				_soundController.stop();
			}
		}
		
		/**
		 * @private
		 * 
		 * Updates the playhead during playback.
		 */
		private function updatePlayhead(event:Event):void
		{
			// selection in the works
			if (!isNaN(_playheadStart) && !isNaN(_playheadEnd) && _waveForm.state == SelectableWaveFormState.SELECTED)
			{
				_waveForm.playhead.x = _soundController.position / _soundController.sound.length * (_playheadEnd - _playheadStart) + _playheadStart;
			}
			else
			{
				_waveForm.playhead.x = _soundController.position / _soundController.sound.length * _waveForm.waveWidth;
			}
		}
		
		/**
		 * @private
		 * 
		 * Updates playback controls (includes playhead) upon entering a state.
		 */
		private function updatePlaybackControls(event:SoundControllerStateEvent):void
		{
			switch (event.state)
			{
				case SoundControllerState.PLAYING:
				{
					_deleteButton.turnOff();
					_playPauseButton.turnOn();
					_playPauseButton.playing = true;
					_stopButton.turnOn();
					
					_waveForm.playhead.addEventListener(Event.ENTER_FRAME, updatePlayhead, false, 0, true); 
				}
					break;
				case SoundControllerState.PAUSED:
				{
					_deleteButton.turnOff();
					_playPauseButton.turnOn();
					_playPauseButton.playing = false;
					_stopButton.turnOn();
					
					_waveForm.playhead.removeEventListener(Event.ENTER_FRAME, updatePlayhead);
				}
					break;
				case SoundControllerState.STOPPED:
				{
					_playPauseButton.turnOn();
					_playPauseButton.playing = false;
					_stopButton.turnOff();
					
					_waveForm.playhead.removeEventListener(Event.ENTER_FRAME, updatePlayhead);
					
					if (_waveForm.state == SelectableWaveFormState.SELECTED)
					{
						_deleteButton.turnOn();
						_waveForm.playhead.x = _waveForm.selectionStart;
					}
					else
					{
						_waveForm.playhead.x = 0;
					}
				}
					break;
			}
		}
		
		/**
		 * @private
		 * 
		 * Updates the selection tools.
		 */
		private function updateSelectionTools(event:SelectableWaveFormStateEvent):void
		{
			if (event.state == SelectableWaveFormState.SELECTED)
			{
				_deleteButton.turnOn();
			}
			else
			{
				_deleteButton.turnOff();
			}
		}
	}
}