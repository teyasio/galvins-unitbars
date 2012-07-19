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

You can get to the options in two ways.
First is going to interface options -> addons -> Galvin's UnitBars.  Then click on "GUB Options".
The other way is to type "/gub config" or "/gub c".


|cff00ff00Dragging and Dropping|r
To drag any bar around the screen use the left mouse button while pressing any modifier key (alt, shift, or control).  To move a rune use the right mouse button while pressing down any modifier key.


|cff00ff00Status|r
All bars have status flags.  This tells a bar what to do based on a certain condition.  Each bar can have one or more flags active at the same time.  A flag with a higher priority will always override one with a lower.  The flags listed below are from highest priority to lowest.  Unlocking bars acts like a status.  It will override all flags to show the bars, The only flags it can't override is never show and hide not usable.

   Never Show          Disables and hides the bar.
   Hide not Usable     Disable and hides the bar if it's not usable by the class, spec, form, stance etc.
   Hide when Dead      Hide the bar when the player is dead.
   Hide in Vehicle     Hide the bar if a vehicle.
   Hide in Pet Battle  Hide the bar if in a pet battle.
   Hide not Active     Hide the bar when it's not active.
   Hide no Combat      Hide the bar when not in combat.

|cff00ff00Text Type|r
All health and Power bars and the Demonic bar have a text type.  This lets you control how the health or power values are to be displayed.  If you do not like the default layout, you can enter your own. Click the custom control box and an input box will appear.  In this box you can enter any layout you want.

The easist way to create a custom layout is to turn off custom, pick a default layout from the pull down menus.  Then click custom.  This will let you edit the default layout generated.

You can select how many values you want to show.  Each value has two pull down menus.  The first menu tells what value you want to show.  Can be Current Value or Max Value.  The second pull down menu tells what type of value will be displayed.  If no value is selected that value will be skipped.  It's best to play around to get a feel for it.

If the layout causes an error you will see a Layout Error appear on the health or powerbar.  It will let you know if the error came from text or text2.

You can add extra things to a custom layout.

Examples
(%d%%) : (%d) -> (20%) : (999)
Health %d / Percentage %d%% -> Health 999 / Percentage 20%
%.2fk -> 999.99k

For more information you can google stringformat for lua.


|cff00ff00Eclipse Bar - Predicted Power|r
When predicted eclipse power is turned on.  The mod will show what state the eclipse bar will be in before the cast is finished.


|cff00ff00Copy and Paste|r
To copy settings from one bar to the next. Go to the Copy and Paste options on the bar you want to copy from. Click on the type you want to copy.  Then go the Copy and Paste options on the bar you want to copy to.  Then click "Paste".  A confirmation box will pop up asking if you're sure.  Clicking "Clear" will clear the clipboard.


|cff00ff00Align Bars|r
All bars can be lined up for perfection. Bars can be lined either vertically or horizontally.

You need to have bars unlocked.  To open the alignment tool you need to right click a bar.
Once the alignment tool is open you'll need to select a primary bar by right clicking it.

Then you'll need to select some bars to line up with that primary bar.  To do this left click the bars you want to use.
Then clicking 'align' will make the changes.

Left to Right: Bars will be lined up horizontally. Without changing their vertical position.
Top to Bottom: Bars wil be lined up vertically. Without changing their horizontal position.
Justify: Sets the justification.  Bars will then be lined up by their left, right, top, bottom sides.
Padding: Instead of just lining up bars you may want to have equal spacing between them as well.
                This works the same in vertical or horizontal. All this does is make each bar have equal spacing.


|cff00ff00Profiles|r
Its recommended that once you have your perfect configuration made you make a backup of it using profiles.  Just create a new profile named backup.  Then copy your config to backup.  All characters by default start with a new config, but you can share one across all characters or any of your choosing.
]]
