module Configuration
  DIARY_DIRECTORY = UserSpace::DIRECTORY+'/diary'
  KEYWORDS_ENTRY_WIDTH = 220
  LABELS_CLOUD_WIDTH = 32
  DEFAULT_LABEL = 'Today'
  PANE_POSITION	= 310
  ACTIVE_TIME_FRAME = 0

# open/close are so fast, dock seems wasteful.
# MENU[:dock] = '_Dock'	# Dock only hides GUI
  MENU[:close] = '_Close' #  Close destroys GUI, but keeps daemon running. Goes to tray.

  GUI[:window_size] = [750, 500]
end
