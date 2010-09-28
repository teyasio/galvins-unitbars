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


|cff00ff00Copy Settings|r
This allows you to copy the settings of one bar to another.  Not everything can be copied unless both bars are of the same type.  For example a player health bar has all the same properties of a target health bar.  So everything can be copied between the two.  The copy settings will only let you pick what can be copied.  There is a copy all which will copy all the settings that are supported on the destination bar. First select the bar you want to copy from.  Then select the bar you want to copy to.  Then pick which settingsyou would like to copy.  Then click the copy button.  A warning will pop up to prevent accidentally copying.


|cff00ff00Align|r
All bars can be aligned for perfection.  Before doing any alignment pick out a bar you want to align with. This acts like an anchor.  The other bars will get aligned with this bar.  Then pick the bars you want to align with the anchor bar.  You can align bars without changing their vertical position or you can use vertical padding for perfect spacing.

Vertical padding works by placing a number of pixels between each aligned bar going up or down.  Which way the padding happens is based on the location of the bars relative to the bar you're aligning with.

For example you have a health, rage, and target health bar.  You want all three to be perfectly lined up with each other.  So if the rage bar is the bar you want first, then health second, and target health third.  First you move the health bar in the exact spot you want the other two bars to be lined up with.  It doesn't matter where the other two bars are as long as the rage bar is above or below the other two.  Horizontal position is not important.

Once that is done go to tools then align.  Pick player power since this contains your rage if you're a warrior.  Next pick the two other bars from the list below.  So you would check off player health and target health.  Since we want our bars to be perfectly spaced apart vertically we'll enable vertical padding.  Then use the slider to pick how much padding you want.  Also since we want our bars to be lined up by their right side we need to choose 'right' from the alignment drop down menu.  After that click align.  You should instantly see the three bars all lined up vertically by their right side.

Once align is clicked the tool will go into a real time mode.  What this allows you to do is change the alignment left or right or change the padding without having to click align each time.  But if you change the bars or the primary bar to align with you'll need to click align again.

|cff00ff00Profiles|r
Its recommended that once you have your perfect configuration made you make a backup of it using profiles.  Just create a new profile named backup.  Then copy your config to backup.  All characters by default start with a new config, but you can share one across all characters or any of your choosing.
]]
