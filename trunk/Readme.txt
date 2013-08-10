
Galvin's UnitBars is a very customizable addon.  It's main purpose is to only display a class resource.
Currently it supports all the resource bars in the default UI.


After making a lot of changes if you wish to start over you can restore default settings.  Just go to the bar
in the bars menu.  Click the bar you want to restore.  Then click the restore button you may have to scroll
down to see it.

You can get to the options in two ways.
First is going to interface options -> addons -> Galvin's UnitBars.  Then click on "GUB Options".
The other way is to type "/gub config" or "/gub c".


* Dragging and dropping

To drag any bar around the screen use the left mouse button while pressing any modifier key (alt, shift, or control).
To move a rune use the right mouse button while pressing down any modifier key.

* Status
All bars have status flags.  This tells a bar what to do based on a certain condition.  Each bar can have one or more
flags active at the same time.  A flag with a higher priority will always override one with a lower.  The flags listed
below are from highest priority to lowest.  Unlocking bars acts like a status.  It will override all flags to show the
bars, The only flag it can't override is never show.

   Hide not usable      Hides the bar if it's not usable by the class, spec, form, stance etc.
   Hide when Dead       Hide the bar when the player is dead.
   Hide in Vehicle      Hide the bar if a vehicle.
   Hide in Pet Battle   Hide the bar if in a pet battle.
   Hide not Active      Hide the bar when it's not active.
   Hide no Combat       Hide the bar when not in combat.

* Text
All health and Power bars and the Demonic bar support multiple text lines.  Each text line can have multiple values.  Click
the add/remove buttons to add or remove values.  To add another text line click the button that has the + or - button with
the name of the text line.  To add another text line beyond line 2.  Click the line 2 tab, then click the button with the
+ symbol.

You can add extra text to the layout.  Just modify the layout in the edit box.  After you click accept the layout will 
become a custom layout.  Clicking exit will take you back to a normal layout.  You'll lose the custom layout though.

The layout supports world of warcraft's UI escape color codes.  The format for this is |cAARRGGBB<text>|r.  So for example to
make percentage show up in red you would do |c00FF0000%d%%|r.  If you want a "|" to appear on the bar you'll need to
use "|||".

If the layout causes an error you will see a layout error appear in the format of Err (text line number). So Err (2) would
mean text line 2 is causing the error.

Here's some custom layout examples.

(%d%%) : (%d) -> (20%) : (999)
Health %d / Percentage %d%% -> Health 999 / Percentage 20%
%.2fk -> 999.99k

For more information you can check out the following links:
For Text: https://www.youtube.com/watch?v=mQVCDJLrCNI
UI escape codes: http://www.wowwiki.com/UI_escape_sequences

* Eclipse Bar - Predicted Power
When eclipse power is turned on.  The mod will show what state the eclipse bar will be in before the cast is finished.

* Cut and Paste
Go to the copy and paste options.  Click on the button you want to copy then pick another bar in the options and click
the same button to do the paste.  For text lines you can copy and paste within the same bar or to another bar.

* Align bars
All bars can be lined up for perfection. Bars can be lined either vertically or horizontally.

You need to have bars unlocked.  To open the alignment tool you need to right click a bar.
Once the alignment tool is open you'll need to select a primary bar by right clicking it.

Then you'll need to select some bars to line up with that primary bar.  To do this left click the bars you want to use.  
Then clicking 'align' will make the changes.

Left to Right: Bars will be lined up horizontally. Without changing their vertical position.
Top to Bottom: Bars will be lined up vertically. Without changing their horizontal position.
Justify: Sets the justification.  Bars will then be lined up by their left, right, top, bottom sides.
Padding: Instead of just lining up bars you may want to have equal spacing between them as well.
         This works the same in vertical or horizontal. All this does is make each bar have equal spacing.

* Profiles
Its recommended that once you have your perfect configuration made you make a backup of it using profiles.  Just
create a new profile named backup.  Then copy your config to backup.  All characters by default start with a new
config, but you can share one across all characters or any of your choosing.


You can leave feedback at http://wow.curse.com/downloads/wow-addons/details/galvins-unitbars.aspx
