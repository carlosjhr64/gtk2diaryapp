require 'digest/md5'
require 'find'
require 'date'

class Integer
  def to_s2
    (self<10)? '0'+self.to_s: self.to_s
  end
end

module Gtk2Diary
  TXT = 'txt'
  DIARY_TXT_FILE = Regexp.new('/(\d\d\d\d)/(\d\d)/(\d\d)/(\d\d\d).(\w+)\.' + TXT + '$')
  YEAR, MONTH, DAY, SORT, LABEL = 1, 2, 3, 4, 5

  STARTS = 100
  ENDS	= 999
  SPIN_BUTTON_OPTIONS = {:min=>STARTS,:max=>ENDS,:step=>1}.freeze

  # Just going to avoid the leap year issue, 29 days for Feb. HOWTO FIX? :-??
  DAYS_IN_MONTH = [31,29,31,30,31,30,31,31,30,31,30,31]

  HOOKS = Hash.new
  HOOKS[:populate_active] = true
  HOOKS[:invert_sort] = HOOKS[:calendar] = HOOKS[:results_pane] = HOOKS[:keyword_search_form] = HOOKS[:vscrollbar] = HOOKS[:labels_cloud] = nil

  def self.labels_cloud_add(label)
    if !HOOKS[:labels_cloud].labels.include?(label) then
      HOOKS[:labels_cloud].add(label)
      HOOKS[:labels_cloud].show_all
    end
  end

  def self.diary_entry_filename(date,sort_order,label)
    return "#{Configuration::DIARY_DIRECTORY}/#{date}/#{sort_order}.#{label}.#{TXT}"
  end

  # Searches can have a time frame specified.
  # This combo box sets the time frame.
  class TimeFrame < Gtk2App::ComboBox
    def initialize(pack)
      super(Configuration::TIME_FRAMES,pack)
      # Yes, a global, bite me!  Alright, adding some safeties...
      $active_time_frame = ($active_time_frame.nil?)? Configuration::ACTIVE_TIME_FRAME: $active_time_frame.to_i
      $active_time_frame = 0 if $active_time_frame < 0 || $active_time_frame > 6
      self.active = $active_time_frame
      self.signal_connect('changed'){ $active_time_frame = self.active }
    end

    def value
      date = HOOKS[:calendar].date
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

  class TitleBox < Gtk::HBox
    attr_reader :sort_order
    def diary_entry_filename
      return Gtk2Diary.diary_entry_filename( @date.label, @sort_order.value.to_i, @label.text )
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
          Gtk2Diary.labels_cloud_add(@label.text)
        end
      end
    end

    def date_button_clicked
      HOOKS[:populate_active] = false
      HOOKS[:calendar].select_month(value[1],value[0])
      HOOKS[:populate_active] = true
      HOOKS[:calendar].select_day(value[2])
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
      super()
      @previous = nil
      @label = Gtk2App::Entry.new(md[LABEL],self){ label_entry }
      @label.width_request = Configuration::LABEL_ENTRY_WIDTH
      @date = Gtk2App::Button.new(md[YEAR]+'/'+md[MONTH]+'/'+md[DAY], self){ date_button_clicked }
      @date.value = [md[YEAR].to_i, md[MONTH].to_i, md[DAY].to_i]
      @sort_order = Gtk2App::SpinButton.new(self,SPIN_BUTTON_OPTIONS)
      # can't use Gtk2App::SpinButton's changed signal
      @sort_order.signal_connect('focus-out-event'){ date_button_clicked }

      @sort_order.set_value(md[SORT].to_i)
      @previous = [self.diary_entry_filename, @label.text, @sort_order.value.to_i]
      Gtk2App.pack(self,pack)
    end

    def can_focus=(opened)
      @label.can_focus = opened
      @sort_order.can_focus = opened
    end
  end

  # Single diary entries
  class DiaryEntry < Gtk::VBox
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
      super()
      @title_box = TitleBox.new(md,self)

      @text_view = nil # defined later
      @revert = Gtk2App::Button.new('Restore', @title_box){|value|
        filename = @title_box.diary_entry_filename
        if File.exist?(filename) then
          File.open(filename,'r'){|fh| @text_view.text = fh.read}
        else
          @text_view.text = ''
        end
      }
      @revert.value = true

      @delete = Gtk2App::Button.new('Delete', @title_box){
        @text_view.text = ''
        pack.remove(self)
        self.destroy
      }
      @delete.value = true

      text = nil; File.open(filename,'r'){|fh| text = fh.read}
      @md5sum = Digest::MD5.hexdigest(text)
      @text_view = Gtk2App::TextView.new(text,self,Configuration::TEXTVIEW_OPTIONS)

      Gtk2App.pack(self, pack)
      self.signal_connect('destroy'){ self.update }

      @text_view.grab_focus if @text_view.text.length == 0 && @text_view.can_focus?
    end

    def lock(locked)
      opened = !locked
      @text_view.can_focus = opened
      @delete.value = opened
      @revert.value = opened
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
  class KeywordSearchForm < Gtk::HBox
    attr_reader :keywords
    def initialize(pack, time_frame)
      super()
      @keywords = Gtk2App::Entry.new('',self)
      @keywords.width_request = Configuration::KEYWORDS_ENTRY_WIDTH
      search = Gtk2App::Button.new('Search', self){|value|
        date_range = time_frame.value
        HOOKS[:results_pane].populate(date_range, nil, nil, @keywords.text)
      }
      search.value = true
      Gtk2App.pack(self,pack)
    end
  end

  # Shows a list of labels as buttons
  class LabelsCloud < Gtk::VBox
    include Configuration
    attr_reader :labels

    def add(label)
      @length += label.length + GUI[:padding]
      if @length > LABELS_CLOUD_WIDTH then
        @length = 0
        @hbox = Gtk::HBox.new
        Gtk2App.pack(@hbox,self)
      end
      search_label = Gtk2App::Button.new(label, @hbox){|value|
        date_range = @time_frame.value
        keywords = HOOKS[:keyword_search_form].keywords.text.strip
        keywords = nil if keywords.length==0
        HOOKS[:results_pane].populate(date_range, nil, value, keywords)
      }
      search_label.value = label
    end

    def initialize(pack, time_frame)
      super()
      @time_frame = time_frame
      labels = Hash.new(0.0)
      labels[DEFAULT_LABEL] = 0.0
      now = Time.now
      Find.find(DIARY_DIRECTORY){|fn|
        if md = DIARY_TXT_FILE.match(fn) then
          # abs incase mtime > now, but should not happen
          # newer files weighted more...
          labels[ md[LABEL] ] += WEIGHT_SCALE / ( WEIGHT_SCALE + (now - File.mtime(fn)).abs )
        end
      }
      @labels = labels.sort{|a,b| b[1]<=>a[1]}.map{|x| x[0]}[0..MAX_LABELS]

      @length = 0
      @hbox = Gtk::HBox.new
      Gtk2App.pack(@hbox,self)
      @labels.each{|label| add(label) }
      Gtk2App.pack(self,pack)
    end
  end


  class Calendar < Gtk::Calendar
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

    def initialize
      super()
      mark_days
      self.signal_connect('month-changed'){
        marked = mark_days
        if HOOKS[:populate_active] then
          HOOKS[:populate_active] = false
          start_date = Date.new(self.year,self.month+1,1)
          end_date = start_date + DAYS_IN_MONTH[self.month]
          date_range = start_date..end_date
          HOOKS[:results_pane].populate(date_range, STARTS.to_s, Configuration::DEFAULT_LABEL)
          # if marked, we'll be going to day-selected next, so need to flag it as nil to skip it.
          HOOKS[:populate_active] = (marked)? nil: true
        end
      }
      self.signal_connect('day-selected'){
        if HOOKS[:populate_active] then
          start_date = Date.new(self.year, self.month+1,  self.day)
          HOOKS[:results_pane].populate( start_date..start_date )
        elsif HOOKS[:populate_active].nil? then
          # skipped, but restoring to true
          HOOKS[:populate_active] = true
        end
      }
    end
  end

  class ResultsPane < Gtk::VBox
    def initialize
      super
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

    def populate(date_range=nil, sort_int=nil, label=nil, keywords=nil)
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

      sign = (HOOKS[:invert_sort].active?)? -1: 1
      files.sort{|a,b| sign*(a[0]<=>b[0])}[0..Configuration::MAX_RESULTS].each {|fn,md|
        DiaryEntry.new(fn, md, self)
      }
      self.show_all
      self.lock(@lock) if @lock
    end
  end

  # Creates the pane containing the calendar, search, and tags cloud.
  class ControlPane < Gtk::VBox
    include Configuration

    def self.new_entry_button_clicked(value)
      date = HOOKS[:calendar].date
      year = date[0].to_s
      month = date[1].to_s2
      day = date[2].to_s2
      date = "#{year}/#{month}/#{day}"
      UserSpace.mkdir("/diary/#{year}")
      UserSpace.mkdir("/diary/#{year}/#{month}")
      UserSpace.mkdir("/diary/#{date}")
      # Find largest sort_int in the directory
      i = STARTS
      Find.find(DIARY_DIRECTORY+'/'+date){|fn|
        if md = DIARY_TXT_FILE.match(fn) then
          i = md[SORT].to_i + 1	if md[SORT].to_i >= i
        end
      }
      if i > ENDS then
        i -= 1
        # Find highest non-collision
        fn = Gtk2Diary.diary_entry_filename(date,i,value)
        while File.exist?(fn) && (i >= STARTS) do
          i -= 1
          fn = Gtk2Diary.diary_entry_filename(date,i,value)
        end
      end
      if (i >= STARTS) && (i <= ENDS) then
        fn = Gtk2Diary.diary_entry_filename(date,i,value)
        File.open(fn,'w'){|fh|} # touch
        start_date = Date.new(year.to_i, month.to_i, day.to_i)
        HOOKS[:results_pane].populate( start_date..start_date )
      else
        raise "Oh, no! WHY?? Why me!? Oh, the humanity!!!"
      end
      Gtk.timeout_add(250){
        # 100000, to be squash to actual limit
        HOOKS[:vscrollbar].value = (HOOKS[:invert_sort].active?)? 0: 100000
        false
      }
    end

    def self.today_button_clicked
      date_today = Date.today
      HOOKS[:populate_active] = false
      HOOKS[:calendar].select_month(date_today.month,date_today.year)
      HOOKS[:populate_active] = true
      HOOKS[:calendar].select_day(date_today.day)
    end

    def initialize
      super()
      hbox = Gtk::HBox.new

      HOOKS[:invert_sort] = invert_sort = Gtk2App::CheckButtonLabel.new('Invert Sort', hbox, INVERT_SORT_OPTIONS)
      Gtk2App::CheckButtonLabel.new('Lock', hbox, LOCK_OPTIONS){|checkbox| HOOKS[:results_pane].lock(checkbox.active?) }
      Gtk2App.pack(hbox,self)
      HOOKS[:calendar] = Calendar.new
      hbox = Gtk::HBox.new
      new_entry = Gtk2App::Button.new('New Entry', hbox){|value| ControlPane.new_entry_button_clicked(value) }
      new_entry.value = DEFAULT_LABEL

      today = Gtk2App::Button.new('Today', hbox){ ControlPane.today_button_clicked }
      today.value = true

      Gtk2App.pack(hbox,self)
      Gtk2App.pack(HOOKS[:calendar], self)
      time_frame = TimeFrame.new(self)
      HOOKS[:keyword_search_form] = KeywordSearchForm.new( self, time_frame )
      HOOKS[:labels_cloud] = LabelsCloud.new( self, time_frame )
    end
  end
end
