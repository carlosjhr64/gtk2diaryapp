	Ruby-Gnome Diary

Ruby-Gnome Diary makes it easy to maintain and
search through short journal entries.
Keep short notes on your daily activities,
such as your phone call to a client,
your milestones on a project,
what you had for breakfast,
how many chin ups you did on your work out,
your weight....
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
The app starts unlocked, but I strongly advice you edit
	~/.gtk2diaryapp-1/appconfig-1.3.rb
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

Search [All Time, ..., Year, Month, Day]
The search time frame combo box allows one
to limit the keywords or label search to
a particular timeframe.

Keyword Search
The Search button searches the text entries,
within the specified time frame.

"Cloud" Label Buttons
Searches for the entries by label within the
specified time frame.

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
