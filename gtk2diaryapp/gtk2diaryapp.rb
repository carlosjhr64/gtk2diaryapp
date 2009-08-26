# $Date: 2009/03/18 21:51:32 $
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

  # Just going to avoid the leapyear issue, 29 days for Feb. HOWTO FIX? :-??
  DAYS_IN_MONTH = [31,29,31,30,31,30,31,31,30,31,30,31]

  @@populate_active = true
  def self.populate_active
    @@populate_active
  end
  def self.populate_active=(value)
    @@populate_active = value
  end

  @@calendar_hook = nil
  def self.calendar_hook
    @@calendar_hook
  end
  def self.calendar_hook=(value)
    @@calendar_hook = value
  end

  @@populate_hook = nil
  def self.populate_hook(*argvs)
    @@populate_hook.populate(*argvs)
  end
  def self.populate_hook=(value)
    @@populate_hook = value
  end
  def self.lock(v)
    @@populate_hook.lock(v)
  end


  @@add_label_hook = nil
  def self.add_label_hook(label)
    if !@@add_label_hook.labels.include?(label) then
      @@add_label_hook.add(label)
      @@add_label_hook.show_all
    end
  end
  def self.add_label_hook=(value)
    @@add_label_hook = value
  end

  @@vscrollbar_hook = nil
  def self.vscrollbar_hook
    @@vscrollbar_hook
  end
  def self.vscrollbar_hook=(value)
    @@vscrollbar_hook = value
  end

  @@invert_sort_hook = nil
  def self.invert_sort_hook
    @@invert_sort_hook.active?
  end
  def self.invert_sort_hook=(value)
    @@invert_sort_hook = value
  end

  def self.diary_entry_filename(date,sort_order,label)
    return "#{Configuration::DIARY_DIRECTORY}/#{date}/#{sort_order}.#{label}.#{TXT}"
  end

  class TimeFrame < Gtk::ComboBox
    def initialize(pack)
      super()
      Gtk2App.common(self,pack)
      ['All Time', 'Last 365 Days', 'Last 90 Days', 'Last 30 Days', 'Year', 'Month', 'Day'].each {|item|
        self.append_text("Search #{item}")
      }
      # Yes, a global, bite me!  Alright, adding some safeties...
      $active_time_frame = ($active_time_frame.nil?)? Configuration::ACTIVE_TIME_FRAME: $active_time_frame.to_i
      $active_time_frame = 0 if $active_time_frame < 0 || $active_time_frame > 6
      self.active = $active_time_frame
      self.signal_connect('changed'){ $active_time_frame = self.active }
    end

    def value
      date = Gtk2Diary.calendar_hook.date
      ret = nil
      case self.active
        when 1
          end_date = Date.today
          start_date = end_date - 365
          ret = start_date..end_date
        when 2
          end_date = Date.today
          start_date = end_date - 90
          ret = start_date..end_date
        when 3
          end_date = Date.today
          start_date = end_date - 30
          ret = start_date..end_date
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
    def diary_entry_filename
      return Gtk2Diary.diary_entry_filename( @date.label, @sort_order.value.to_i, @label.text )
    end

    def initialize(md,pack)
      super()
      @previous = nil
      @label = Gtk2App::Entry.new(md[LABEL],self){
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
            if File.rename(@previous[0], filename) then
              @previous[0] = filename
              @previous[1] = @label.text
              Gtk2Diary.add_label_hook(@label.text)
            end
          end
        end
      }
      @label.width_request = 100 # Configurable?
      @date = Gtk2App::Button.new(md[YEAR]+'/'+md[MONTH]+'/'+md[DAY], self){|value|
        Gtk2Diary.populate_active = false
        Gtk2Diary.calendar_hook.select_month(value[1],value[0])
        Gtk2Diary.populate_active = true
        Gtk2Diary.calendar_hook.select_day(value[2])
      }
      @date.value = [md[YEAR].to_i, md[MONTH].to_i, md[DAY].to_i]
      @sort_order = Gtk2App::SpinButton.new(self,ENDS,STARTS)
      @sort_order.signal_connect('focus-out-event'){ # can't use Gtk2App::SpinButton's changed signal
        if @previous && !(@previous[2] == @sort_order.value.to_i) then
          filename = self.diary_entry_filename
          if File.exist?(filename) then
            # revert
            @sort_order.value.to_i = @previous[2]
          else
            # move
            if File.rename(@previous[0], filename) then
              @previous[0] = filename
              @previous[2] = @sort_order.value.to_i
            end
          end
        end
        false
      }
      @sort_order.value = md[SORT].to_i
      @previous = [self.diary_entry_filename, @label.text, @sort_order.value.to_i]
      pack.pack_start(self, false, false, Configuration::GUI[:padding])
    end

    def can_focus=(v)
      @label.can_focus = v
      @sort_order.can_focus = v
    end
  end

  class DiaryEntry < Gtk::VBox
    def update
      filename = @title_box.diary_entry_filename
      if @buffer.text.length > 0 then
        md5sum = Digest::MD5.hexdigest(@buffer.text)
        if !(md5sum == @md5sum) then
          File.rename(filename, filename+'.bak')
          File.open(filename,'w'){|fh| fh.puts @buffer.text}
        end
      else
        File.rename(filename, filename+'.bak')
      end
    end

    def initialize(filename, md, pack)
      super()
      @title_box = TitleBox.new(md,self)
      @buffer = Gtk::TextBuffer.new

      @revert = Gtk2App::Button.new('Restore', @title_box){|value|
        filename = @title_box.diary_entry_filename
        File.open(filename,'r'){|fh| @buffer.text = fh.read}
      }
      @revert.value = true

      @delete = Gtk2App::Button.new('Delete', @title_box){
        @buffer.text = ''
        pack.remove(self)
        self.destroy
      }
      @delete.value = true

      File.open(filename,'r'){|fh| @buffer.text = fh.read}
      @md5sum = Digest::MD5.hexdigest(@buffer.text)
      @text_view = Gtk::TextView.new(@buffer)
      @text_view.wrap_mode = Gtk::TextTag::WRAP_WORD
      @text_view.set_border_window_size(Gtk::TextView::WINDOW_TOP, 10)

      Gtk2App.common(@text_view, self)
      Gtk2App.common(self, pack)
      self.signal_connect('destroy'){ self.update }

      @text_view.grab_focus if @buffer.text.length == 0 && @text_view.can_focus?
    end

    def lock(v)
      v = !v
      @text_view.can_focus = v
      @delete.value = v
      @revert.value = v
      @title_box.can_focus = v
    end
  end

  class KeywordSearchForm < Gtk::HBox
    def initialize(pack, time_frame)
      super()
      keywords = Gtk2App::Entry.new('',self)
      keywords.width_request = Configuration::KEYWORDS_ENTRY_WIDTH
      search = Gtk2App::Button.new('Search', self){|value|
        date_range = time_frame.value
        Gtk2Diary.populate_hook(date_range, nil, nil, keywords.text)
      }
      search.value = true
      pack.pack_start( self, false, false, Configuration::GUI[:padding] )
    end
  end

  class LabelsCloud < Gtk::VBox
    attr_reader :labels
    def add(label)
      @length += label.length + Configuration::GUI[:padding]
      if @length > Configuration::LABELS_CLOUD_WIDTH then
        @length = 0
        @hbox = Gtk::HBox.new
        self.pack_start( @hbox, false, false, Configuration::GUI[:padding] )
      end
      search_label = Gtk2App::Button.new(label, @hbox){|value|
        date_range = @time_frame.value
        Gtk2Diary.populate_hook(date_range, nil, value)
      }
      search_label.value = label
    end

    def initialize(pack, time_frame)
      super()
      # note @labels gets redifined a bit later
      @time_frame = time_frame
      @labels = Hash.new(0)
      @labels[Configuration::DEFAULT_LABEL] = 0
      Find.find(Configuration::DIARY_DIRECTORY){|fn|
        if md = DIARY_TXT_FILE.match(fn) then
          @labels[ md[LABEL] ] += 1
        end
      }
      # note redefinition of @labels here
      @labels = @labels.sort{|a,b|
        ret = b[1] <=> a[1]
        ret = a[0].length <=> b[0].length	if ret == 0
        ret = a[0] <=> b[0]			if ret == 0
        ret
      }.map{|x| x[0]}

      @length = 0
      @hbox = Gtk::HBox.new
      self.pack_start( @hbox, false, false, Configuration::GUI[:padding] )
      @labels.each{|label| add(label) }
      pack.pack_start( self, false, false, Configuration::GUI[:padding] )
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
        if Gtk2Diary.populate_active then
          Gtk2Diary.populate_active = false
          marked = mark_days
          start_date = Date.new(self.year,self.month+1,1)
          end_date = start_date + DAYS_IN_MONTH[self.month]
          date_range = start_date..end_date
          Gtk2Diary.populate_hook(date_range, STARTS.to_s, Configuration::DEFAULT_LABEL)
          # if marked, we'll be going to day-selected next, so need to flag it as nil to skip it.
          Gtk2Diary.populate_active = (marked)? nil: true
        end
      }
      self.signal_connect('day-selected'){
        if Gtk2Diary.populate_active then
          start_date = Date.new(self.year, self.month+1,  self.day)
          Gtk2Diary.populate_hook( start_date..start_date )
        elsif Gtk2Diary.populate_active.nil?
          # skipped, but restoring to true
          Gtk2Diary.populate_active = true
        end
      }
    end
  end

  class ResultsPane < Gtk::VBox
    def initialize
      super
      @lock = Configuration::INITIAL_LOCK
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

    def keywords_matches(fn,keywords)
      buffer = nil
      File.open(fn,'r'){|fh| buffer= fh.read}
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
            files.push([fn,md]) if !keywords || keywords_matches(fn,keywords)
          end
          end
        end
      }
      sign = (Gtk2Diary.invert_sort_hook)? -1: 1
      files.sort{|a,b| sign*(a[0]<=>b[0])}.each {|fn,md|
        DiaryEntry.new(fn, md, self)
      }
      self.lock(@lock) if @lock
      self.show_all
    end
  end

  class ControlPane < Gtk::VBox
    def initialize
      super()
      hbox = Gtk::HBox.new
      Gtk2Diary.invert_sort_hook = invert_sort =
	Gtk2App::CheckButtonLabel.new('Invert Sort', hbox, true, Configuration::FONT[:small])
      Gtk2App::CheckButtonLabel.new('Lock', hbox, Configuration::INITIAL_LOCK, Configuration::FONT[:small]){|c|
	Gtk2Diary.lock(c.active?)
      }
      Gtk2App.common(hbox,self)
      Gtk2Diary.calendar_hook = calendar = Calendar.new
      hbox = Gtk::HBox.new
      new_entry = Gtk2App::Button.new('New Entry', hbox){|value|
        date = calendar.date
        year = date[0].to_s
        month = date[1].to_s2
        day = date[2].to_s2
        date = "#{year}/#{month}/#{day}"
        UserSpace.mkdir("/diary/#{year}")
        UserSpace.mkdir("/diary/#{year}/#{month}")
        UserSpace.mkdir("/diary/#{date}")
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
          Gtk2Diary.populate_hook( start_date..start_date )
        else
          raise "Oh, no! WHY?? Why me!? Oh, the humanity!!!"
        end
        Gtk.timeout_add(1000*Configuration::SLEEP[:short]){
          # 100000, to be squash to actual limit
          Gtk2Diary.vscrollbar_hook.value = (Gtk2Diary.invert_sort_hook)? 0: 100000
          false
        }
      }
      new_entry.value = Configuration::DEFAULT_LABEL

      today = Gtk2App::Button.new('Today', hbox){|value|
        date_today = Date.today
        Gtk2Diary.populate_active = false
        calendar.select_month(date_today.month,date_today.year)
        Gtk2Diary.populate_active = true
        calendar.select_day(date_today.day)
      }
      today.value = true

      Gtk2App.common(hbox,self)
      Gtk2App.common(calendar,self)
      time_frame = TimeFrame.new(self)
      keyword_search_form = KeywordSearchForm.new( self, time_frame )
      Gtk2Diary.add_label_hook = LabelsCloud.new( self, time_frame )
    end
  end
end

  class Gtk2DiaryApp
    def initialize(window)
      # Create paned windows
      hpaned = Gtk::HPaned.new
      hpaned.position = Configuration::PANE_POSITION
  
      # Control pane
      control_pane = Gtk2Diary::ControlPane.new
      sw_control = Gtk::ScrolledWindow.new
      sw_control.add_with_viewport(control_pane)
      hpaned.add(sw_control)

      # Results pane
      results_pane = Gtk2Diary::ResultsPane.new
      Gtk2Diary.populate_hook = results_pane
      today = Date.today
      Gtk2Diary.populate_hook( today..today )
      sw_results = Gtk::ScrolledWindow.new
      Gtk2Diary.vscrollbar_hook = sw_results.vscrollbar
      sw_results.add_with_viewport(results_pane)
      hpaned.add(sw_results)
  
      window.add(hpaned)
    end
  end
