
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

   Hide not Usable      Hides the bar if it's not usable by the class, spec, form, stance etc.
   Show Always          Always show the bar.  This doesn't override Hide not usable.
   Hide when Dead       Hide the bar when the player is dead.
   Hide in Vehicle      Hide the bar if a vehicle.
   Hide in Pet Battle   Hide the bar if in a pet battle.
   Hide not Active      Hide the bar when it's not active.
   Hide no Combat       Hide the bar when not in combat.

* Text
Some bars support multiple text lines.  Each text line can have multiple values.  Click
the add/remove buttons to add or remove values.  To add another text line click the button that has the + or - button with
the name of the text line.  To add another text line beyond line 2.  Click the line 2 tab, then click the button with the
+ symbol.

You can add extra text to the layout.  Just modify the layout in the edit box.  After you click accept the layout will
become a custom layout.  Clicking exit will take you back to a normal layout.  You'll lose the custom layout though.

The layout supports world of warcraft's UI escape color codes.  The format for this is |cAARRGGBB<text>|r.  So for example to
make percentage show up in red you would do |c00FF0000%d%%|r.  If you want a "|" to appear on the bar you'll need to
use "||".

If the layout causes an error you will see a layout error appear in the format of Err (text line number). So Err (2) would
mean text line 2 is causing the error.

Here's some custom layout examples.

(%d%%) : (%d) -> (20%) : (999)
Health %d / Percentage %d%% -> Health 999 / Percentage 20%
%.2fk -> 999.99k

For more information you can check out the following links:
For Text: https://www.youtube.com/watch?v=mQVCDJLrCNI
UI escape codes: http://www.wowwiki.com/UI_escape_sequences

* Cut and Paste
Go to the copy and paste options.  Click on a button from the button menu on the top row.  This selects a bottom row of
buttons. Click on the bottom button you want to copy then pick another bar in the options and click
the same button to do the paste.  For text lines you can copy and paste within the same bar or to another bar.

* Align and Swap
Right click on any bar to open this tool up.  Then click on align or swap.
Align will allow you to line up a bar with another bar.  Just drag the bar near another till you see a green
rectangle.  The bar will then jump next to the other bar based on where you place it.  You can keep doing this
with more bars.  The tool remembers all the bars you aligned as long as you don't close the tool or
uncheck align or switch to swap.

You can use vertical or horizontal padding to space apart the aligned bars.  The vertical only works for bars
that were aligned vertically and the same for horizontal.  Once you have 2 or more aligned bars they become
an aligned group.  Then you can use offsets to move the group.

If you choose swap, then when you drag the bar near another bar. It will have a red rectangle around it.  Soon as
you place it there the two bars will switch places.

This same tool can be used on bar objects.  When you go to the bar options under layout you'll see swap and float.
Clicking float will open up the align tool further down.

You can also set the bar position manually by unchecking align.  You'll have a Horizontal and Vertical input box just
type in the location.  Moving the bar will automatically update the input boxes with the new location.

For more you can watch the video:
http://www.youtube.com/watch?v=STYa5d6riuk

* Test Mode
When in test mode the bars will behave as if they were unlocked.  But you can't click on them.  Test mode allows
you to make changes to the bar without having to go into combat to make certain parts of the bar become active.

Additional options will be found at the option panel for the bar when test mode is active

* Triggers
Triggers let you create an option that will only become active when a condition is met.

When you first go to triggers you'll see a pull down called Bar Object.  Health and power bars
only have one bar object, but bars like Ember Bar have more than one.  Select the bar
object you want if there is more than one.  Then click the add button.

You'll then see a trigger options panel come up.  There is no limit to how many triggers
you can create, create too many and you may experience lag in the options panel.  Minimizing
can help with this.

Action: The action pull down lets you pick an action.  Then a UI option will become visible.

  Add       Adds another copy of the current trigger.
  Delete    Removes the current trigger.
  Name      Changes the name of the trigger (Bar Object name) will be appear before the name.
  Swap      Lets you swap one trigger with another.
  Disable   Deactivates a trigger.  Triggers that are disabled do not consume cpu.
  Move      Move a trigger to a different bar object.
  Copy      Copy a trigger to a different bar object.
  None      To prevent accidents.

Value Type: lets you pick what type of value you want to trigger off of.  Each bar has its
own set of value types.
Type: lets you pick different parts of the bar.  Border, color, background, etc.

Condition: The condition that needs to be met for the trigger to activate

  <         Less than
  >         Greater than
  <=        Less than or equal
  >=        Greater than or equal
  =         Equal
  <>        No equal
  Static    Always on, static triggers use less cpu.

Value: The value you want to trigger off of based on condition.  If the condition is
met the trigger will activate. For percentages only 0 to 100 needs to be entered.

Trigger can also use auras.  Pick "auras" under value type. Then you'll see a box
to enter an aura name or ID into.  Type in the name then pick it from the list.  If you
already know the spellID then you can type that instead.

After the aura is added you change the following:
Cast by Player:   If checked then the aura has to have come from you.
Units: You can enter any number of units here seperated by a space.  But the aura will have to be on
all of them at the same time.

Condition:  Can set what type of condition you want to compare stacks to.
Stacks: 0 means no stacks so match any aura.

Under condition next to the aura name box.  You can change it to "or" for all auras
or "and" for just one aura out of the list to match.

For more you can watch the video:
https://www.youtube.com/watch?v=LUhCXoh6Ytk


* Aura List
Found under Utility.  This will list any auras the mod comes in contact with.  Type the different
units into the unit box.  The mod will only list auras from the units specified.
Then click refresh to update the aura list with the latest auras.


* Profiles
Its recommended that once you have your perfect configuration made you make a backup of it using profiles.  Just
create a new profile named backup.  Then copy your config to backup.  All characters by default start with a new
config, but you can share one across all characters or any of your choosing.


You can leave feedback at http://wow.curse.com/downloads/wow-addons/details/galvins-unitbars.aspx
