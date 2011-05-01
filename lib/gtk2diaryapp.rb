require 'digest/md5'
require 'find'
require 'date'

class Integer
  def to_s2
    (self<10)? '0'+self.to_s: self.to_s
  end
end

module Gtk2DiaryApp
  TXT = 'txt'
  DIARY_TXT_FILE = Regexp.new('/(\d\d\d\d)/(\d\d)/(\d\d)/(\d\d\d).(\w+)\.' + TXT + '$')
  YEAR, MONTH, DAY, SORT, LABEL = 1, 2, 3, 4, 5

  STARTS = 100
  ENDS	= 999
  SPIN_BUTTON_OPTIONS = { :set_range  => [STARTS,ENDS], :set_increments => [1,10], }.freeze

  # Just going to avoid the leap year issue, 29 days for Feb. HOWTO FIX? :-??
  DAYS_IN_MONTH = [31,29,31,30,31,30,31,31,30,31,30,31]

  HOOKS = Hash.new
  HOOKS[:POPULATE_ACTIVE] = true
  HOOKS[:INVERT_SORT] = HOOKS[:CALENDAR] = HOOKS[:RESULTS_PANE] = HOOKS[:KEYWORD_SEARCH_FORM] = HOOKS[:VSCROLLBAR] = HOOKS[:LABELS_CLOUD] = nil

  def self.labels_cloud_add(label)
    if !HOOKS[:LABELS_CLOUD].labels.include?(label) then
      HOOKS[:LABELS_CLOUD].add(label)
      HOOKS[:LABELS_CLOUD].show_all
    end
  end

  def self.diary_entry_filename(date,sort_order,label)
    return "#{Configuration::DIARY_DIRECTORY}/#{date}/#{sort_order}.#{label}.#{TXT}"
  end

  # Searches can have a time frame specified.
  # This combo box sets the time frame.
  class TimeFrame < Gtk2AppLib::Widgets::ComboBox
    def initialize(pack)
      super(Configuration::TIME_FRAMES,pack)
      # Yes, a global, bite me!  Alright, adding some safeties...
      $active_time_frame = ($active_time_frame.nil?)? Configuration::ACTIVE_TIME_FRAME: $active_time_frame.to_i
      $active_time_frame = 0 if $active_time_frame < 0 || $active_time_frame > 6
      self.active = $active_time_frame
      self.signal_connect('changed'){ $active_time_frame = self.active }
    end

    def value
      date = HOOKS[:CALENDAR].date
      ret = nil
      case self.active
        when 1..3
          end_date = Date.today
          start_date = end_date - ((self.active==1)? 365: ((self.active==2)? 90: 30))
          ret = start_date..end_date
# The above equivalent to...
#       when 1
#         end_date = Date.today
#         start_date = end_date - 365
#         ret = start_date..end_date
#       when 2
#         end_date = Date.today
#         start_date = end_date - 90
#         ret = start_date..end_date
#       when 3
#         end_date = Date.today
#         start_date = end_date - 30
#         ret = start_date..end_date
        when 4
          start_date = Date.new(date[0],1,1)
          end_date = Date.new(date[0],12,31)
          ret = start_date..end_date
        when 5
          start_date = Date.new(date[0],date[1],1)
          end_date = start_date + DAYS_IN_MONTH[date[1]-1]
          ret = start_date..end_date
        when 6
          start_date = Date.new(date[0],date[1],date[2])
          ret = start_date..start_date
      end
      return ret
    end
  end

  class TitleBox < Gtk2AppLib::Widgets::HBox
    attr_reader :sort_order
    def diary_entry_filename
      return Gtk2DiaryApp.diary_entry_filename( @date.label, @sort_order.value.to_i, @label.text )
    end

    def label_entry
      if @previous && !(@previous[1] == @label.text) then
        # label needs to be filename friendly
        text = @label.text.strip.gsub(/\s+/,'_').gsub(/[^\w]/,'')
        @label.text = text if !(text == @label.text)
        filename = self.diary_entry_filename
        if File.exist?(filename) then
          # revert
          @label.text = @previous[1]
        else
          # move
          File.rename(@previous[0], filename)
          @previous[0] = filename
          @previous[1] = @label.text
          Gtk2DiaryApp.labels_cloud_add(@label.text)
        end
      end
    end

    def date_button_clicked(value)
      HOOKS[:POPULATE_ACTIVE] = false
      HOOKS[:CALENDAR].select_month(value[1],value[0])
      HOOKS[:POPULATE_ACTIVE] = true
      HOOKS[:CALENDAR].select_day(value[2])
    end

    def sort_order_focus_out_event
      if @previous && !(@previous[2] == @sort_order.value.to_i) then
        filename = self.diary_entry_filename
        if File.exist?(filename) then
          # revert
          @sort_order.value.to_i = @previous[2]
        else
          # move
          File.rename(@previous[0], filename)
          @previous[0] = filename
          @previous[2] = @sort_order.value.to_i
        end
      end
      false
    end

    def initialize(md,pack)
      super(pack)
      @previous = nil
      @label = Gtk2AppLib::Widgets::Entry.new(md[LABEL],self,'focus-out-event'){ label_entry; false }
      @label.width_request = Configuration::LABEL_ENTRY_WIDTH

      @date = Gtk2AppLib::Widgets::Button.new(md[YEAR]+'/'+md[MONTH]+'/'+md[DAY], self, 'clicked'){|value,*emits| date_button_clicked(value) }
      @date.is = [md[YEAR].to_i, md[MONTH].to_i, md[DAY].to_i]

      @sort_order = Gtk2AppLib::Widgets::SpinButton.new(self,SPIN_BUTTON_OPTIONS)
      # can't use Gtk2AppLib::SpinButton's changed signal
      @sort_order.signal_connect('focus-out-event'){ sort_order_focus_out_event }
      @sort_order.set_value(md[SORT].to_i)

      @previous = [self.diary_entry_filename, @label.text, @sort_order.value.to_i]
    end

    def can_focus=(opened)
      @label.can_focus = opened
      @sort_order.can_focus = opened
    end
  end

  # Single diary entries
  class DiaryEntry < Gtk2AppLib::Widgets::VBox
    def update
      filename = @title_box.diary_entry_filename
      if @text_view.text.length > 0 then
        md5sum = Digest::MD5.hexdigest(@text_view.text)
        if !(md5sum == @md5sum) then
          File.rename(filename, filename+'.bak') if File.exist?(filename)
          File.open(filename,'w'){|fh| fh.puts @text_view.text}
        end
      else
        File.rename(filename, filename+'.bak') if File.exist?(filename)
      end
    end

    def initialize(filename, md, pack)
      super(pack)
      @title_box = TitleBox.new(md,self)

      @text_view = nil # defined later
      @revert = Gtk2AppLib::Widgets::Button.new(*Configuration::RESTORE+[@title_box]){|value,*emits|
        filename = @title_box.diary_entry_filename
        if File.exist?(filename) then
          File.open(filename,'r'){|fh| @text_view.text = fh.read}
        else
          @text_view.text = ''
        end
      }
      @revert.is = true

      @delete = Gtk2AppLib::Widgets::Button.new(*Configuration::DELETE+[@title_box]){
        @text_view.text = ''
        pack.remove(self)
        self.destroy
      }
      @delete.is = true

      text = nil; File.open(filename,'r'){|fh| text = fh.read}
      @md5sum = Digest::MD5.hexdigest(text)
      @text_view = Gtk2AppLib::Widgets::TextView.new(text,self,Configuration::TEXTVIEW_OPTIONS)

      self.signal_connect('destroy'){ self.update }

      @text_view.grab_focus if @text_view.text.length == 0 && @text_view.can_focus?
    end

    def lock(locked)
      opened = !locked
      @text_view.can_focus = opened
      @delete.is = opened
      @revert.is = opened
      @title_box.can_focus = opened
      if opened then
        @delete.show
        @revert.show
        @title_box.sort_order.show
      else
        @delete.hide
        @revert.hide
        @title_box.sort_order.hide
      end
    end
  end

  # The form to search for entries by keywords
  class KeywordSearchForm < Gtk2AppLib::Widgets::HBox
    attr_reader :keywords
    def initialize(pack, time_frame)
      super(pack)
      @keywords = Gtk2AppLib::Widgets::Entry.new('',self)
      @keywords.width_request = Configuration::KEYWORDS_ENTRY_WIDTH
      search = Gtk2AppLib::Widgets::Button.new(*Configuration::SEARCH+[self]){|value,*emits|
        date_range = time_frame.value
        HOOKS[:RESULTS_PANE].populate(date_range, nil, nil, @keywords.text)
      }
      search.is = true
    end
  end

  # Shows a list of labels as buttons
  class LabelsCloud < Gtk2AppLib::Widgets::VBox
    attr_reader :labels

    def add(label)
      @labels.push(label)
      @length += label.length + Gtk2AppLib::Widgets::WIDGET[:Widgets][:pack_start].last
      if @length > Configuration::LABELS_CLOUD_WIDTH then
        @length = 0
        @hbox = Gtk2AppLib::Widgets::HBox.new(self)
      end
      search_label = Gtk2AppLib::Widgets::Button.new(label, @hbox, 'clicked'){|is,*emits|
        date_range = @time_frame.value
        keywords = HOOKS[:KEYWORD_SEARCH_FORM].keywords.text.strip
        keywords = nil if keywords.length==0
        HOOKS[:RESULTS_PANE].populate(date_range, nil, is, keywords)
      }
      search_label.is = label
    end

    def initialize(pack, time_frame)
      super(pack)
      @time_frame = time_frame
      labels = Hash.new(0.0)
      labels[Configuration::DEFAULT_LABEL] = 0.0
      now = Time.now
      Find.find(Configuration::DIARY_DIRECTORY){|fn|
        if md = DIARY_TXT_FILE.match(fn) then
          # abs incase mtime > now, but should not happen
          # newer files weighted more...
          labels[ md[LABEL] ] += Configuration::WEIGHT_SCALE / ( Configuration::WEIGHT_SCALE + (now - File.mtime(fn)).abs )
        end
      }

      @length = 0
      @hbox = Gtk2AppLib::Widgets::HBox.new(self)
      @labels = []
      labels.sort{|a,b| b[1]<=>a[1]}.map{|x| x[0]}[0..Configuration::MAX_LABELS].each{|label| self.add(label) }
    end
  end


  class Calendar < Gtk2AppLib::Widgets::Calendar
    def mark_days
      marked = false
      self.clear_marks
      subdir = "/#{self.year.to_s}/#{(self.month+1).to_s2}"
      marked = {}
      Find.find(Configuration::DIARY_DIRECTORY+subdir){|fn|
        if md = DIARY_TXT_FILE.match(fn) then
          day = md[DAY]
          if !marked[day] then
            marked[day] = true
            self.mark_day(day.to_i)
            marked = true if !marked
          end
        end
      } if File.exist?(Configuration::DIARY_DIRECTORY+subdir)
      return marked
    end

    def initialize(pack)
      super(pack)
      mark_days
      self.signal_connect('month-changed'){
        marked = mark_days
        if HOOKS[:POPULATE_ACTIVE] then
          HOOKS[:POPULATE_ACTIVE] = false
          start_date = Date.new(self.year,self.month+1,1)
          end_date = start_date + DAYS_IN_MONTH[self.month]
          date_range = start_date..end_date
          HOOKS[:RESULTS_PANE].populate(date_range, STARTS.to_s, Configuration::DEFAULT_LABEL)
          # if marked, we'll be going to day-selected next, so need to flag it as nil to skip it.
          HOOKS[:POPULATE_ACTIVE] = (marked)? nil: true
        end
      }
      self.signal_connect('day-selected'){
        if HOOKS[:POPULATE_ACTIVE] then
          start_date = Date.new(self.year, self.month+1,  self.day)
          HOOKS[:RESULTS_PANE].populate( start_date..start_date )
        elsif HOOKS[:POPULATE_ACTIVE].nil? then
          # skipped, but restoring to true
          HOOKS[:POPULATE_ACTIVE] = true
        end
      }
    end
  end

  class ResultsPane < Gtk2AppLib::Widgets::VBox
    def initialize(pack)
      super(pack)
      @lock = nil
      Gtk.timeout_add(250){ self.lock(Configuration::INITIAL_LOCK); false }
    end

    def clear
      while child = self.children.last do
        self.remove(child)
        child.destroy
      end
    end

    def lock(v)
      @lock = v
      self.children.each do |child|
        child.lock(@lock)
      end
    end

    def self.keywords_matches(fn,keywords,label)
      buffer = nil
      File.open(fn,'r'){|fh| buffer= fh.read}
      buffer += ' '+label
      words = buffer.split(/\W+/).map{|x| x.upcase}.uniq
      keys = keywords.split(/\W+/).map{|x| x.upcase}.uniq
      keys.each{|key| return false if !words.include?(key)}
      return true
    end

    def populate(date_range=nil, sort_int=nil, label=nil, keywords=nil, chop=Configuration::MAX_RESULTS)
      self.clear
      files = []
      Find.find(Configuration::DIARY_DIRECTORY){|fn|
        if md = DIARY_TXT_FILE.match(fn) then
          entry_date = Date.new(md[YEAR].to_i, md[MONTH].to_i, md[DAY].to_i)
          if !date_range || date_range.include?(entry_date) then
          if (!sort_int || md[SORT]==sort_int) && (!label || md[LABEL]==label) then
          if !keywords || ResultsPane.keywords_matches(fn, keywords, (label)? '': md[LABEL]) then
            files.push([fn,md])
          end
          end
          end
        end
      }

      sign = (HOOKS[:INVERT_SORT].active?)? -1: 1
      files.sort!{|a,b| sign*(a[0]<=>b[0])}
      files = files[0..(chop-1)]

      while fn_md = files.shift do
        DiaryEntry.new(*fn_md+[self])
      end
      self.show_all
      self.lock(@lock) if @lock
    end
  end

  # Creates the pane containing the calendar, search, and tags cloud.
  class ControlPane < Gtk2AppLib::Widgets::VBox

    def self.new_entry_button_clicked
      date = HOOKS[:CALENDAR].date
      year = date[0].to_s
      month = date[1].to_s2
      day = date[2].to_s2
      date = "#{year}/#{month}/#{day}"
      dir = Configuration::DIARY_DIRECTORY
      Gtk2AppLib::UserSpace.mkdir("#{dir}/#{year}")
      Gtk2AppLib::UserSpace.mkdir("#{dir}/#{year}/#{month}")
      Gtk2AppLib::UserSpace.mkdir("#{dir}/#{date}")
      # Find largest sort_int in the directory
      i = STARTS
      Find.find(Configuration::DIARY_DIRECTORY+'/'+date){|fn|
        if md = DIARY_TXT_FILE.match(fn) then
          i = md[SORT].to_i + 1	if md[SORT].to_i >= i
        end
      }
      if i > ENDS then
        i -= 1
        # Find highest non-collision
        fn = Gtk2DiaryApp.diary_entry_filename(date,i,Configuration::DEFAULT_LABEL)
        while File.exist?(fn) && (i >= STARTS) do
          i -= 1
          fn = Gtk2DiaryApp.diary_entry_filename(date,i,Configuration::DEFAULT_LABEL)
        end
      end
      if (i >= STARTS) && (i <= ENDS) then
        fn = Gtk2DiaryApp.diary_entry_filename(date,i,Configuration::DEFAULT_LABEL)
        File.open(fn,'w'){|fh|} # touch
        start_date = Date.new(year.to_i, month.to_i, day.to_i)
        HOOKS[:RESULTS_PANE].populate( start_date..start_date )
      else
        raise "Oh, no! WHY?? Why me!? Oh, the humanity!!!"
      end
      Gtk.timeout_add(250){
        # 100000, to be squash to actual limit
        HOOKS[:VSCROLLBAR].value = (HOOKS[:INVERT_SORT].active?)? 0: 100000
        false
      }
    end

    def self.today_button_clicked
      today = Date.today
      HOOKS[:POPULATE_ACTIVE] = false
      HOOKS[:CALENDAR].select_month(today.month,today.year)
      HOOKS[:POPULATE_ACTIVE] = true
      HOOKS[:CALENDAR].select_day(today.day)
    end

    def self.latest_button_clicked
      today = Date.today
      HOOKS[:POPULATE_ACTIVE] = false
      HOOKS[:CALENDAR].select_month(today.month,today.year)
      HOOKS[:CALENDAR].select_day(today.day)
      HOOKS[:POPULATE_ACTIVE] = true
      HOOKS[:RESULTS_PANE].populate(nil,nil,nil,nil,Configuration::LATEST)
    end

    def initialize(pack)
      super(pack)
      hbox = Gtk2AppLib::Widgets::HBox.new(self)

      HOOKS[:INVERT_SORT] = invert_sort = Gtk2AppLib::Widgets::CheckButton.new(*Configuration::INVERT+[hbox])
      Gtk2AppLib::Widgets::CheckButton.new(*Configuration::LOCK+[hbox]){|checkbox,*emits| HOOKS[:RESULTS_PANE].lock(checkbox.active?) }

      hbox = Gtk2AppLib::Widgets::HBox.new(self)

      Gtk2AppLib::Widgets::Button.new(*Configuration::NEW_ENTRY+[hbox]){ ControlPane.new_entry_button_clicked }
      Gtk2AppLib::Widgets::Button.new(*Configuration::TODAY+[hbox]){ ControlPane.today_button_clicked }
      Gtk2AppLib::Widgets::Button.new(*Configuration::LATEST_ENTRIES+[hbox]){ ControlPane.latest_button_clicked }

      HOOKS[:CALENDAR] = Calendar.new(self)
      time_frame = TimeFrame.new(self)
      HOOKS[:KEYWORD_SEARCH_FORM] = KeywordSearchForm.new( self, time_frame )
      HOOKS[:LABELS_CLOUD] = LabelsCloud.new( self, time_frame )
    end
  end
end
