			# Gtk defined in gtk
module Gtk2AppLib	# Gtk2AppLib defined
module Configuration	# Configuration defined
  # WINDOW_DEFAULT_SIZE defined in gtk2applib/configuration
  WINDOW_DEFAULT_SIZE[0], WINDOW_DEFAULT_SIZE[1] = 750, 500
  # MENU defined in gtk2applib/configuration
  if HILDON then
    if Gtk2AppLib::Configuration::OSTYPE == 'Internet Tablet OS: maemo Linux based OS2008' then
      # Icon works on N800, but not N800 (Maemo 5)
      MENU[:close] = '_Close'
    end
  else
    MENU[:close] = '_Close'
  end
end
end

module Gtk2DiaryApp
module Configuration
  # Stuff you might want to edit...
  INITIAL_LOCK = false # set this to true to have the diary start out locked
  DAYS_TO_HOLD_BAK = nil # number of day to hold *.bak file before deleting on exit, nil if never delete.
  DEFAULT_LABEL = 'Today'
  MAX_LABELS = 28
  MAX_RESULTS = 100
  LATEST = 7 # days

  # Stuff you probably won't edit..
  KEYWORDS_ENTRY_WIDTH = 220
  LABEL_ENTRY_WIDTH = 100
  LABELS_CLOUD_WIDTH = 32
  PANE_POSITION	= 310
  TEXTVIEW_OPTIONS = {
	:wrap_mode= => Gtk::TextTag::WRAP_WORD,
	:border_window_size => [Gtk::TextView::WINDOW_TOP, 10]
	}.freeze
  INVERT_SORT_OPTIONS = {:active= => true, :modify_font => Gtk2AppLib::Configuration::FONT[:Small]}
  LOCK_OPTIONS = {:active= =>INITIAL_LOCK, :modify_font => Gtk2AppLib::Configuration::FONT[:Small]}
  WEIGHT_SCALE = 86400.0 # seconds in a day is 60*60*24

  # Stuff you'll probably mess up very badly if you edit...
  DIARY_DIRECTORY = Gtk2AppLib::USERDIR+'/diary'
  Gtk2AppLib::UserSpace.mkdir(DIARY_DIRECTORY)
  # Do not edit semantically, nor reorder :-B
  TIME_FRAMES = ['All Time', 'Last 365 Days', 'Last 90 Days', 'Last 30 Days', 'Year', 'Month', 'Day'].freeze
  ACTIVE_TIME_FRAME = 1
end
end
