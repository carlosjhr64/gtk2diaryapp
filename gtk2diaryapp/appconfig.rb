module Configuration
  # Stuff you might want to edit...
  INITIAL_LOCK = false # set this to true to have the diary start out locked
  DAYS_TO_HOLD_BAK = 7 # number of day to hold *.bak file before deleting on exit, nil if never delete.
  DEFAULT_LABEL = 'Today'
  MAX_LABELS = 28
  MAX_RESULTS = 100

  # Stuff you probably won't edit..
  KEYWORDS_ENTRY_WIDTH = 220
  LABEL_ENTRY_WIDTH = 100
  LABELS_CLOUD_WIDTH = 32
  PANE_POSITION	= 310
  TEXTVIEW_OPTIONS = {
	:wrap_mode=>Gtk::TextTag::WRAP_WORD,
	:border_window_size=>[Gtk::TextView::WINDOW_TOP, 10]
	}.freeze
  MENU[:close] = '_Close' #  Close destroys GUI.
  GUI[:window_size] = [750, 500]
  INVERT_SORT_OPTIONS = {:active=>true,:font=>FONT[:small]}
  LOCK_OPTIONS = {:active=>INITIAL_LOCK,:font=>FONT[:small]}
  WEIGHT_SCALE = 86400.0 # seconds in a day is 60*60*24

  # Stuff you'll probably mess up very badly if you edit...
  DIARY_DIRECTORY = UserSpace::DIRECTORY+'/diary'
  UserSpace.mkdir('/diary')
  # Do not edit semantically, nor reorder :-B
  TIME_FRAMES = ['All Time', 'Last 365 Days', 'Last 90 Days', 'Last 30 Days', 'Year', 'Month', 'Day'].freeze
  ACTIVE_TIME_FRAME = 1

  LATEST = 7 # days
end
