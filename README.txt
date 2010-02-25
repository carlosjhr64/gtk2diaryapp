	Ruby-Gnome Diary

Ruby-Gnome Diary makes it easy to maintain and
search through short journal entries.
Keep short notes on your daily activities.
It's easy to figure out how to label your short entries and
quickly get to any item you want to review.

Invert Sort
Entries are shown in chronlogical/sort_id order and
one can reverse this order.

Lock
Setting the lock will prevent entries from accidently being edited,
by preventing "focus" on them.
It's a good idea to set the lock if you're just reading/reviewing
your entries.
The app starts unlocked, but I strongly advice you edit appconfig
and set INITIAL_LOCK to true.
	INITIAL_LOCK = true

New Entry
Pressing this button adds a new entry to the
selected date on the calendar.
By default, new entries are labeled "Today" --
You can edit this label in the appconfig file.

Today
The Today button navigates the application
back to today's date.

Last <N> Days
The Last <N> Days button will show the entries for the last <N> days.
You can edit <N> in the appconfig file.

Calendar/Date
Clicking on a date will display all entries for that date.

Calendar/Month
Changing the month will show all default labeled entries ("Today")
with a starting sort id ("100") for the selected month.
It is in this way that "/100.Today.txt" entries are special, and
works best if these entries are summaries for the day.

[All Time, Last 365 Days, ... , Year, Month, Day]
The search time frame combo box allows one
to limit the keywords and/or label search to
a particular timeframe.

Keyword Search
The Search button searches the text entries by keywords
within the specified time frame.
If no keywords are entered, it'll return all entries
within the specified time frame.

"Cloud" Label Buttons
Searches for the entries by label within the
specified time frame (and keywords if any).

Year/Month/Day
The date button above a pariticular entry
will search and display all enties on that date.

Sort Integer (100-999)
This allow the user to manage the sort order of
the entries within a date.
100 to 999 gives one plenty of room, but
it is possible to saturate and the application will
quit and complain bitterly if you do.

Restore
The Restore button restores the text back
to it's last saved content.
Saves happen automatically whenever the
text widget is destroyed.

Delete
The Delete button deletes the entry.
Actually, it moves the file to file.bak, so
if you need to revert, go to
	~/.gtk2diaryapp-1/diary/Year/Month/Day/
and move
	***.deleted_entry.txt.bak
back to
	***.deleted_entry.txt

The appconfig file, the configuration file for this app, is
	~/.gtk2diaryapp-1/appconfig-1.4.rb
The appconfig file defines a MAX_RESULTS constant.
This is the maximum number of results the app will display.
