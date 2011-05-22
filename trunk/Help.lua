--
-- Help.lua
--
-- Contains help text to be displayed in options.lua

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.Help = {}

GUB.Help.HelpText = [[

After making a lot of changes if you wish to start over you can restore default settings.  Just go to the bar in the bars menu.  Click the bar you want to restore.  Then click the restore button you may have to scroll down to see it.

If the configuration menu is getting in the way then close it and type: /gub config
This will open a movable configuration window.  Everything in it works the same.


|cff00ff00Dragging and Dropping|r
To drag any bar around the screen use the left mouse button while pressing any modifier key (alt, shift, or control).  To move a rune use the right mouse button while pressing down any modifier key.


|cff00ff00Status|r
All bars have status flags.  This tells a bar what to do based on a certain condition.  Each bar can have one or more flags active at the same time.  A flag with a higher priority will always override one with a lower.  The flags listed below are from highest priority to lowest.  Unlocking bars acts like a status.  It will override all flags to show the bars, The only flag it can't override is never show.

   Never Show           Disables and hides the bar.
   Hide when Dead       Hide the bar when the player is dead.
   Hide in Vehicle      Hide the bar if a vehicle.
   Show Always          The bar will be shown all the time.
   Hide not Active      Hide the bar when it's not active.
   Hide no Combat       Don't hide the bar when not in combat.

|cff00ff00Text Type|r
All health and Power bars text have a text type.  This lets you control how the health or power values are to be displayed.  If you do not like the default layout, you can enter your own. Click the custom control box and an input box will appear.  In this box you can enter any layout you want.

If the layout causes an error you will see a Layout Error appear on the health or powerbar.  It will let you know if the error came from text or text2.

The easist way to create a custom layout is to turn off custom, pick a default layout from the pull down menus.  Then click custom.  This will let you edit the default layout generated.

You can add extra things to a custom layout.

Examples
(%d%%) : (%d) -> (20%) : (999)
Health %d / Percentage %d%% -> Health 999 / Percentage 20%
%.2fk -> 999.99k

|cff00ff00Copy Settings|r
This allows you to copy the settings of one bar to another.  Not everything can be copied unless both bars are of the same type.  For example a player health bar has all the same properties of a target health bar.  So everything can be copied between the two.  The copy settings will only let you pick what can be copied.  There is a copy all which will copy all the settings that are supported on the destination bar. First select the bar you want to copy from.  Then select the bar you want to copy to.  Then pick which settingsyou would like to copy.  Then click the copy button.  A warning will pop up to prevent accidental copying.


|cff00ff00Align Bars|r
All bars can be aligned for perfection. Bars can be aligned either vertically or horizontally.

- Align Bars with:  Here you choose the bar you want to align other bars with.
- Bars to Align:  Pick the bars you want to align.
- Type of Alignment:  You need specify if you want to line up the bars vertically your horizontally.
- Alignment: This specifies if you want the top, bottom, left, or right of each bar to be lined up with the bar you picked in 'Align Bars With'.  If you're doing vertical then you'll have left or right as a choice.  If horizontal then you'll have top or bottom as a choice.
- Padding: Instead of just lining up bars you may want to have equal spacing between them as well.  This works the same in vertical or horizontal. All this does is make each bar have equal spacing.

Once Align is clicked the tool goes into a real time mode.  What this means is if Type of Alignment, Alignment, or Padding gets changed.  The bars will get aligned again automatically.  But if you make any changes in bars to align or align bars with.  Then you'll need to click align again.

|cff00ff00Profiles|r
Its recommended that once you have your perfect configuration made you make a backup of it using profiles.  Just create a new profile named backup.  Then copy your config to backup.  All characters by default start with a new config, but you can share one across all characters or any of your choosing.
]]
