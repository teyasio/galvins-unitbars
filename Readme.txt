
Galvin's UnitBars is a very customizable addon.  It's main purpose is to only display a class resource.  Currently it
supports mana, rage, energy, runic power, focus, combo points, runes, and shards.


After making a lot of changes if you wish to start over you can restore default settings.  Just go to the bar
in the bars menu.  Click the bar you want to restore.  Then click the restore button you may have to scroll
down to see it.

If the configuration menu is getting in the way then close it and type: /gub config from the chat
box.  This will open a movable configuration window.  Everything in it works the same.

* Dragging and dropping

To drag any bar around the screen use the left mouse button while pressing any modifier key (alt, shift, or control).
To move a rune use the right mouse button while pressing down any modifier key.

* Status
All bars have status flags.  This tells a bar what to do based on a certain condition.  Each bar can have one or more
flags active at the same time.  A flag with a higher priority will always override one with a lower.  The flags listed
below are from highest priority to lowest.  Unlocking bars acts like a status.  It will override all flags to show the
bars, The only flag it can't override is never show.

   Never Show           Disables and hides the bar.
   Hide not usable      Disable and hides the bar if it's not usable by the class, spec, form, stance etc.
   Hide when Dead       Hide the bar when the player is dead.
   Hide in Vehicle      Hide the bar if a vehicle.
   Hide in Pet Battle   Hide the bar if in a pet battle.
   Hide not Active      Hide the bar when it's not active.
   Hide no Combat       Don't hide the bar when not in combat.

* Text Type
All health and Power bars have a text type.  This lets you control how the health or power values are to be displayed.
If you do not like the default layout, you can enter your own. Click the custom control box and an input box will appear.
In this box you can enter any layout you want.

The easist way to create a custom layout is to turn off custom, pick a default layout from the pull down menus.  Then
click custom.  This will let you edit the default layout generated.

You can select how many values you want to show.  Each value has two pull down menus.  The first menu tells what value
you want to show.  Can be Current Value or Max Value.  The second pull down menu tells what type of value will be
displayed.  If no value is selected that value will be skipped.  It's best to play around to get a feel for it.

If the layout causes an error you will see a Layout Error appear on the health or powerbar.  It will let you know if the
error came from text or text2.

You can add extra things to a custom layout.

Examples
(%d%%) : (%d) -> (20%) : (999)
Health %d / Percentage %d%% -> Health 999 / Percentage 20%
%.2fk -> 999.99k

For more information you can google stringformat for lua.

* Eclipse Bar - Predicted Power
When eclipse power is turned on.  The mod will add up all the flying spells and the one that's casting and show it
as predicted power.  Eclipse can also be predicted. 

For this to work smoothly every spell must hit and euphoria won't proc.  Since euphoria can't be predicted.  When
a spell lands and euphoria procs, the predicted power will jump beyond what the predicted power showed.

* Copy Settings
This allows you to copy the settings of one bar to another.  Not everything can be copied unless both bars are of the
same type.  For example a player health bar has all the same properties of a target health bar.  So everything can be
copied between the two.  The copy settings will only let you pick what can be copied.  There is a copy all which
will copy all the settings that are supported on the destination bar.

First select the bar you want to copy from.  Then select the bar you want to copy to.  Then pick which settings
you would like to copy.  Then click the copy button.  A warning will pop up to prevent accidental copying.

* Alignment
All bars can be lined up for perfection. Bars can be lined either vertically or horizontally.

You need to have bars unlocked.  To open the alignment tool you need to right click a bar.
Once the alignment tool is open you'll need to select a primary bar by right clicking it.

Then you'll need to select some bars to line up with that primary bar.  To do this left click the bars you want to use.  Then clicking 'align' will make the changes.

- Horizontal/Vertical:  This will either line up bars from left to right or top to bottom.
If Horizontal then the vertical location of the bars is unchanged.
If Vertical then the horizontal location of the bars is unchanged.
- Justify: Set the justification.  Bars will then be lined up by their left, right, top, bottom sides.
- Padding: Instead of just lining up bars you may want to have equal spacing between them as well.
This works the same in vertical or horizontal. All this does is make each bar have equal spacing.

* Profiles
Its recommended that once you have your perfect configuration made you make a backup of it using profiles.  Just
create a new profile named backup.  Then copy your config to backup.  All characters by default start with a new
config, but you can share one across all characters or any of your choosing.


You can leave feedback at http://wow.curse.com/downloads/wow-addons/details/galvins-unitbars.aspx
