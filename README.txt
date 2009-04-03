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

New Entry
Pressing this button adds a new entry to the
selected date on the calendar.
By default, new entries are labeled "Today".
You can edit this label, but the application
expects there to be at least a "Today" entry
in any date entry (beta, might change this).
It works best if the user makes "Today" a short
summary of the day's activities.

Today
The Today button navigates the application
back to today's date.

Search [All Time, ..., Year, Month, Day]
The search time frame combo box allows one
to limit the keywords or label search to
a particular timeframe.
Defaults to last thirty days.

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

Delete
The Delete button deletes the entry.
Actually, it moves the file to file.bak, so
if you need to revert, go to
	~/.gtk2diaryapp/diary/Year/Month/Day/
and move
	***.deleted_entry.txt.bak
back to
	***.deleted_entry.txt
I'll be adding a revert option in the app menu for
the next release (well, sometime soon, anyways).
But keep the app running...
The app cleans-up (deletes) all these *.bak files on exit.
