//------------------------------------------------------------------------------
//  
//  Package
//  
//------------------------------------------------------------------------------

package soundui
{
	
	//--------------------------------------------------------------------------
	//  
	//  Imports
	//  
	//--------------------------------------------------------------------------
	
	import flash.display.Sprite;
	
	import soundutil.SoundController;
	import soundutil.SoundControllerState;
	import soundutil.SoundControllerStateEvent;
	import soundutil.SoundRecorder;
	import soundutil.SoundRecorderState;
	import soundutil.SoundRecorderStateEvent;
	
	import uiwidgets.DialogBox;
	
	//--------------------------------------------------------------------------
	//  
	//  Class
	//  
	//--------------------------------------------------------------------------
	
	/**
	 * Provides the sound recording interface as a DialogBox.
	 * 
	 * @author Anton Nguyen
	 * @date 20110307
	 */
	public class SoundRecorderPane extends DialogBox
	{
		
		//----------------------------------------------------------------------
		//  
		//  Fields
		//  
		//----------------------------------------------------------------------
		
		private var _activityBar:MicrophoneActivityBar;
		private var _edit:Function;
		private var _playPauseButton:PlayPauseButton;
		private var _recordButton:RecordButton;
		private var _save:Function;
		private var _stopButton:StopButton;
		private var _soundController:SoundController;
		private var _soundRecorder:SoundRecorder;
		private var _waveForm:RecordedWaveForm;
		private var _widgetContainer:Sprite;
		
		//----------------------------------------------------------------------
		//  
		//  Constructor Method
		//  
		//----------------------------------------------------------------------
		
		/**
		 * Makes a SoundRecorderPane.
		 */
		public function SoundRecorderPane(saveFunc:Function, editFunc:Function)
		{
			super();
			
			addTitle("Sound Recorder");
			//addAcceptCancelButtons("Save");
			_save = saveFunc;
			_edit = editFunc;
			addButton("Save", save);
			addButton("Edit", edit);
//			addButton("Cancel", cancel);
			
			// sound control objects
			_soundRecorder = new SoundRecorder();
			_soundController = new SoundController(_soundRecorder.recording);
			
			// widget container
			_widgetContainer = new Sprite();
			addWidget(_widgetContainer);
			
			// activity bar in the upper left corner
			_activityBar = new MicrophoneActivityBar(10, 50);
			_activityBar.setMicrophone(_soundRecorder.microphone)
			_widgetContainer.addChild(_activityBar);
			
			// wave form
			_waveForm = new RecordedWaveForm(_soundRecorder);
			_waveForm.x = 50;
			_widgetContainer.addChild(_waveForm);
			
			// playback control buttons
			_playPauseButton = new PlayPauseButton(playPause);
			_playPauseButton.turnOff();
			_playPauseButton.x = 50;
			_playPauseButton.y = 60;
			_widgetContainer.addChild(_playPauseButton);
			
			_recordButton = new RecordButton(record);
			_recordButton.turnOn();
			_recordButton.x = 120;
			_recordButton.y = 60;
			_widgetContainer.addChild(_recordButton);
			
			_stopButton = new StopButton(stop);
			_stopButton.turnOff();
			_stopButton.x = 190;
			_stopButton.y = 60;
			_widgetContainer.addChild(_stopButton);
			
			// listeners to update buttons
			_soundController.addEventListener(SoundControllerStateEvent.ENTER, updatePlaybackControls, false, 0, true);
			_soundRecorder.addEventListener(SoundRecorderStateEvent.ENTER, updateRecordingControls, false, 0, true);
		}
		
		//----------------------------------------------------------------------
		//  
		//  Properties
		//  
		//----------------------------------------------------------------------
		
		//------------------------------
		//  soundRecorder
		//------------------------------
		
		/**
		 * The SoundRecorder object used in this pane.
		 */
		public function get soundRecorder():SoundRecorder
		{
			return _soundRecorder;
		}
		
		//----------------------------------------------------------------------
		//  
		//  Event Handlers
		//  
		//----------------------------------------------------------------------
		
		/**
		 * @private
		 * 
		 * Plays or pauses playback.
		 */
		private function playPause():void
		{
			if (_soundRecorder.state == SoundRecorderState.STOPPED)
			{
				switch (_soundController.state)
				{
					case SoundControllerState.PLAYING:
					{
						_soundController.pause();
					}
						break;
					case SoundControllerState.PAUSED:
					case SoundControllerState.STOPPED:
					{
						_soundController.play();
					}
						break;
				}
			}
		}
		
		/**
		 * @private
		 * 
		 * Begins recording.
		 */
		private function record():void
		{
			if (_soundController.state == SoundControllerState.STOPPED)
			{
				_soundRecorder.record();
			}
		}
		
		/**
		 * @private
		 * 
		 * Stops anything currently running.
		 */
		public function stop():void
		{
			if (_soundController.state != SoundControllerState.STOPPED)
			{
				_soundController.stop();
			}
			
			if (_soundRecorder.state != SoundRecorderState.STOPPED)
			{
				_soundRecorder.stop();
			}
		}
		
		/**
		 * @private
		 * 
		 * Toggles buttons.
		 */
		private function updatePlaybackControls(event:SoundControllerStateEvent):void
		{
			switch (event.state)
			{
				case SoundControllerState.PLAYING:
				{
					_playPauseButton.turnOn();
					_playPauseButton.playing = true;
					_recordButton.turnOff();
					_stopButton.turnOn();
				}
					break;
				case SoundControllerState.PAUSED:
				{
					_playPauseButton.turnOn();
					_playPauseButton.playing = false;
					_recordButton.turnOff();
					_stopButton.turnOn();
				}
					break;
				case SoundControllerState.STOPPED:
				{
					_playPauseButton.turnOn();
					_playPauseButton.playing = false;
					_recordButton.turnOn();
					_stopButton.turnOff();
				}
					break;
			}
		}
		
		/**
		 * @private
		 * 
		 * Toggles buttons.
		 */
		private function updateRecordingControls(event:SoundRecorderStateEvent):void
		{
			switch (event.state)
			{
				case SoundRecorderState.RECORDING:
				{
					_playPauseButton.turnOff();
					_recordButton.turnOff();
					_stopButton.turnOn();
				}
					break;
				case SoundRecorderState.STOPPED:
				{
					_playPauseButton.turnOn();
					_recordButton.turnOn();
					_stopButton.turnOff();
				}
					break;
			}
		}
		
		//----------------------------------------------------------------------
		//  
		//  Methods
		//  
		//----------------------------------------------------------------------
		
		override public function cancel():void
		{
			// stop all playback or recording
			stop();
			super.cancel();
		}
		
		public function edit():void
		{
			// technically not really a cancel, but close enough
			cancel();
			
			// invokes callback passed in constructor
			_edit(soundRecorder.recording);
		}
		
		public function save():void
		{
			// also not a cancel, but close enough 
			cancel();
			
			// invokes callback passed in constructor
			_save(soundRecorder.recording);
		}
	}
}