module Configuration
  DIARY_DIRECTORY = UserSpace::DIRECTORY+'/diary'
  KEYWORDS_ENTRY_WIDTH = 220
  LABELS_CLOUD_WIDTH = 32
  DEFAULT_LABEL = 'Today'
  PANE_POSITION	= 310
  ACTIVE_TIME_FRAME = 1
  DAYS_TO_HOLD_BAK = 7 # number of day to hold *.bak file before deleting on exit, nil if never delete.
  INITIAL_LOCK = false # set this to true to have the diary start out locked

# open/close are so fast, dock seems wasteful.
  MENU[:dock] = '_Dock'	# Dock only hides GUI
  MENU[:close] = '_Close' #  Close destroys GUI, but keeps daemon running. Goes to tray.

  GUI[:window_size] = [750, 500]
end
