--
-- Main.lua
--
-- Displays different bars for each class.  Rage, Energy, Mana, Runic Power, etc.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = {}
local UnitBarsF = {}
local UnitBarsFI = {}
local HapBar = {}
local Options = {}

GUB.Main = Main
GUB.UnitBarsF = UnitBarsF
GUB.Bar = {}
GUB.WoWUI = {}
GUB.HapBar = HapBar
GUB.RuneBar = {}
GUB.ComboBar = {}
GUB.HolyBar = {}
GUB.ShardBar = {}
GUB.DemonicBar = {}
GUB.EmberBar = {}
GUB.EclipseBar = {}
GUB.ShadowBar = {}
GUB.ChiBar = {}
GUB.Options = Options

-------------------------------------------------------------------------------
-- Setup Ace3
-------------------------------------------------------------------------------
LibStub('AceAddon-3.0'):NewAddon(GUB, MyAddon, 'AceConsole-3.0', 'AceEvent-3.0')

-------------------------------------------------------------------------------
-- Setup shared media
-------------------------------------------------------------------------------
local LSM = LibStub('LibSharedMedia-3.0')
local MistsVersion = select(4, GetBuildInfo()) >= 50000

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin
local strfind, strsub, strupper, strlower, format, strconcat, strmatch, gsub, tonumber =
      strfind, strsub, strupper, strlower, format, strconcat, strmatch, gsub, tonumber
local pcall, pairs, ipairs, type, select, next, print, sort =
      pcall, pairs, ipairs, type, select, next, print, sort
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, GetSpellInfo, GetTalentInfo, PlaySound =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, GetSpellInfo, GetTalentInfo, PlaySound
local GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, UIParent =
      C_PetBattles, UIParent

------------------------------------------------------------------------------
-- Register GUB textures with LibSharedMedia
------------------------------------------------------------------------------
LSM:Register('statusbar', 'GUB Bright Bar', [[Interface\Addons\GalvinUnitBars\Textures\GUB_SolidBrightBar.tga]])
LSM:Register('statusbar', 'GUB Dark Bar', [[Interface\Addons\GalvinUnitBars\Textures\GUB_SolidDarkBar.tga]])

------------------------------------------------------------------------------
-- Unitbars frame layout and animation groups.
--
-- UnitBarsParent
--   Anchor
--     FadeOut
--     FadeOutA
--     ScaleFrame
--       <Unitbar frames start here>
--     SelectFrame
--
--
-- UnitBarsF structure    NOTE: To access UnitBarsF by index use UnitBarsFI[Index].
--                              UnitBarsFI is used to enable/disable bars in EnableUnitBars().
--
-- UnitBarsParent         - Child of UIParent.  The perpose of this is so all bars can be moved as a group.
-- UnitBarsF[]            - UnitBarsF[] is a frame and table.  This is so each bar can have its own events,
--                          and all data for each bar.
--   Anchor               - Child of UnitBarsParent.  The root of every bar.  Controls hide/show
--                          and size of a bar and location on the screen.  Also brings the bar to top level when clicked.
--                          From my testing any frame that gets clicked on that is a child of a frame with SetToplevel(true)
--                          will bring the parent to top level even if the parent wasn't the actual frame clicked on.
--     UnitBar            - This is used for moving since the move code needs to update the bars position data after each move.
--   ScaleFrame           - Child of Anchor.  Controls scaling of bars to be made larger or smaller thru SetScale().
--   SelectFrame          - Child of Anchor.  Places a colored border around a selected frame used for the alignment tool.
--                          Its frame level is always the highest since it doesn't get scaled and needs to appear
--                          on the top most level.
--   FadeOut              - Child of anchor. Animation group for fadeout.
--   FadeOutA             - Child of FadeOut. This contains the animation to fade out a bar.  Anything attached to the Anchor frame
--                          will get faded out.
--
--
-- UnitBarsF has methods which make changing the state of a bar easier.  This is done in the form of
-- UnitBarsF[BarType]:MethodCall().  BarType is used through out the mod.  Its the type of bar being referenced.
-- Search thru the code to see how these are used.
--
-- List of UninBarsF methods:
--
--   CancelAnimation()    - Some bars have alpha animations.  If a childframe has an alpha animation fadeout/fadein being
--                          played and its parent also has an animation fadeout being played at the same time.  The
--                          child can get stuck in a transparent state.  Only way to fix is to reload ui.  This is a bug
--                          in the wow ui.  The work around is when a bar is to be hidden which would trigger a fadeout.
--                          The code calls this method to cancel any fadeout animations currently in play.  Then fadeout the
--                          bar.
--   Update()             - This is how information from the server gets to the bar.
--   StatusCheck()        - All bars have flags that determin if a bar should be visible in combat or never shown.
--                          When this gets called the bar checks the flags to see if the bar should change its state.
--   EnableMouseClicks()  - Enable or disable mouse interaction with the bar.
--   FrameSetScript()     - Enable or disable scripts for the bar.
--   SetAttr()            - Set different parts of the bar. Color, size, font, etc.
--   SetLayout()          - Before a bar can start taking data this must be called.  This will load the profile data
--                          into the bar.  This is used for initializing after firstload or during a profile change.
--   BarVisible()         - This is used by StatusCheck() to determin if a bar should be hidden.  Bars like focus and target
--                          need to be hidden when the player doesn't have a target or focus.
--   SetSize()            - This can change the location and/or size of the Anchor.
--
--
-- UnitBarsF data.  Each bar has data that keeps track of the bars state.
--
-- List of UnitBarsF values.
--
--   WasEnabled           - True or false.  Flag used to keep track of enable/disable by EnableUnitBars()
--   Visible              - True or false.  If true then the bar is visible otherwise hidden.
--   WaitTime             - Amount of time to wait before updating the bar again. Used by CreateUnitBarTimers().
--   LastTime             - Last time the bars Update() function was called. Updated by the bars Update() function.
--                          Used by CreateUnitBarTimers().
--                          This was created so when a bar gets updated thru an event, it wont get updated right away
--                          in CreateUnitBarsTimers() unless the WaitTime has elapsed.
--   IsActive             - True, false, or 0.  If true the bar is considered to be doing something, otherwise doing nothing.
--                            True   The bar is considered to be doing something.
--                            False  The bar is not active.
--                            0      The bar is waiting to be active again.  If the flag is checked by StatusCheck() and is false.
--                                   Then it sets it to zero.
--   ScaleWidth           - Contains the scaled width of the Anchor.
--   ScaleHeight          - Contains the scaled height of the Anchor.
--   Width                - Contains the unscaled width of the Anchor.  ScaleWidth * scale.
--   Height               - Contains the unscaled height of the Anchor.  ScaleHeight * scale.
--   Selected             - True of false.  If true then the bar has a select rectangle around it.
--   SelectColor          - Color of the select retangle in r, g, b format.
--   BarType              - Mostly for debugging.  Contains the type of bar. 'PlayerHealth', 'RuneBar', etc.
--   UnitBar              - Reference to the current UnitBar data which is the current profile.  Each time the
--                          profile changes this value gets referenced to the new profile. UnitBar points to
--                          the current profile.
--
--
-- UnitBar mod upvalues/tables.
--
-- Defaults               - The default unitbar table.  Used for first time initialization.
-- CooldownBarTimerDelay  - Delay for the cooldown timer bar measured in times per second.
-- UnitBarDelay           - Used by CreateUnitBarTimers(). Tells the timer how often to call the function to update each bar.
-- PowerColorType           Table used by InitializeColors()
-- PowerTypeToNumber      - Table to convert a string powertype into a number.
-- Backdrop                 This contains a Backdrop table that has texture path names.  Since this addon uses
--                          shared media.  Texture names need to be converted into path names.  So ConvertBackdrop()
--                          needs to be called.  ConvertBackdrop then sets this table to a real backdrop table that
--                          can be used in SetBackdrop().  This table should never be reference to another table
--                          since convertbackdrop passes back a reference to this table.
--
-- AlignmentTooltipDesc     Tooltip to be shown when the alignment tool is active.
--
-- InCombat               - True or false. If true then the player is in combat.
-- InVehicle              - True or false. If true then the player is in a vehicle.
-- InPetBattle            - True or false. If true then the player is in a pet battle.
-- IsDead                 - True or false. If true then the player is dead.
-- HasTarget              - True or false. If true then the player has a target.
-- HasFocus               - True or false. If true then the player has a focus.
-- HasPet                 - True or false. If true then the player has a pet.

-- PlayerClass            - Name of the class for the player in english.
-- PlayerGUID             - Globally unique identifier for the player.  Used by CombatLogUnfiltered()
-- PlayerPowerType        - The current power type for the player.
-- PlayerStance           - The current form/stance the player is in.
-- PlayerSpecialization   - The current specialization for the player
-- Initialized            - True of false. Flag for OnInitializeOnce().
-- PSelectedUnitBarF      - Contains a reference to UnitBarF.  Contains the primary selected UnitBar.
--                          Alignment tool currently uses this.
-- SelectMode             - true or false.  If true then bars can be left or right clicked on to select.
--                                          Otherwise nothing happens.
--
-- BgTexure               - Default background texture for the backdrop and all bars.
-- BdTexture              - Default border texture for the backdrop and all bars.
-- StatusBarTexure        - Default bar texture for the health and power bars.
--
-- PointCalc              - Table used by CalcSetPoint() to return a location inside a parent frame.
--
-- GetTextValuePercentFn  - Contains the function to do percent calculations. Gets set by
--                          GetTextValues() and called by SetTextValue().
--
-- RegEventFrames         - Table used by RegisterEvent() and UnregisterEvent() functions
--
-- UnitBar table data structure.
-- This data is used in the root of the unitbar data table and applies to all bars.  Accessed by UnitBar.Key.
--
-- EnableClass            - True or false. If true all unitbars get enabled for your class only.
-- IsGrouped              - True or false. If true all unitbars get dragged as one object.
--                                         If false each unitbar can be dragged by its self.
-- IsLocked               - True or false. If true all unitbars can not be clicked on.
-- IsClamped              - True or false. If true all frames can't be moved off screen.
-- HideTooltips           - True or false. If true tooltips are not shown when mousing over unlocked bars.
-- HideTooltipsDesc       - True or false. If true the descriptions inside the tooltips will not be shown when mousing over
--                                         unlocked bars.
-- FadeOutTime            - Time in seconds before a bar completely goes hidden.
-- Px, Py                 - The current location of the UnitBarsParent on the screen.
--
--
-- Fields found in all unitbars:
--
--   Name                 - Name of the bar.
--   Enabled              - If true bar can be used, otherwise disabled.  Will not appear in options.
--   BarVisible()         - Returns true or false.  This gets referenced by UnitBarsF. Not all bars has this.
--   UsedByClass          - If a bar doesn't have this key then any class can use the bar and be any spec or no spec.
--                          Contains the data for HideNotUsable flag.  Not all unitbars has this. This is also used for Enable Bar Options.
--                          Example1: {DRUID = '1234'}
--                            Class has to be druid and any of the 4 specs can be used.
--                          Example2: {DRUID = '12', DEATHKNIGHT = ''}
--                            Class has to be druid or deathknight.  Spec 1 or 2 on the druid has to be used. Deathknight, spec isn't checked.
--
--  WaitTime              - Used for UnitBarsF. See UnitBarsF values.
--
--   x, y                 - Current location of the Anchor relative to the UnitBarsParent.
--   Status               - Table that contains a list of flags marked as true or false.
--                          If a flag is found true then a statuscheck will be done to see what the
--                          bar should do. Flags with a higher priority override flags with a lower.
--                          Flags from highest priority to lowest.
--                            HideNotUsable    Disables and hides the unitbar if the bar is not usable
--                                             by class, specialization, stance or form, etc.
--                                             Not everybar has this flag.  If one is present then
--                                             the bar has a UsedByClass table.
--                            HideWhenDead     Hide the unitbar when the player is dead.
--                            HideInVehicle    Hide the unitbar if in a vehicle.
--                            HideInPetBattle  Hide the unitbar if in a pet battle.
--                            HideNotActive    Hide the unitbar if its not active.
--                            HideNoCombat     Hide the unitbar when not in combat.
-- Other                  - For anything not related mostly this will be for scale and maybe alpha
--   Scale                - Sets the scale of the unitbar frame.
--   FrameStrata          - Sets the strata for the frame to appear on.

--
-- Tables used in any unitbar:
--
-- FontSettings           - Standard container for setting a font. Used by SetFontString()
--   FontType             - Type of font to use.
--   FontSize             - Size of the font.
--   FontStyle            - Contains flags seperated by a comma: MONOCHROME, OUTLINE, THICKOUTLINE
--   FontHAlign           - Horizontal alignment.  LEFT  CENTER  RIGHT
--   Position             - Position relative to the font's parent.  Can be one of the 9 standard setpoints.
--   Width                - Field width for the font.
--   OffsetX              - Horizontal offset position of the frame.
--   OffsetY              - Vertical offset position of the frame.
--   ShadowOffset         - Number of pixels to move the shadow towards the bottom right of the font.
--
-- BackdropSettings       - Backdrop settings table. Must be converted into a backdrop before using.
--   BgTexture            - Name of the background textured in sharedmedia.
--   BdTexture            - Name of the forground texture 'statusbar' in sharedmedia.
--   BgTile               - True or false. If true then the background is tiled, otherwise not tiled.
--   BgTileSize           - Size (width or height) of the square repeating background tiles (in pixels).
--   BdSize               - Size of the border texture thickness in pixels.
--   Padding
--     Left, Right,
--     Top, Bottom        - Positive values go inwards, negative values outward.
--
-- UnitBars health and power fields
--   General
--     PredictedHealth    - True or false.  Used by health bars only, except Pet Health.
--                                          If true then predicted health will be shown.
--     PredictedPower     - True or false.  Used by Player Power for hunters only.
--                                          If true predicted power will be shown.
--   Background
--     PaddingAll         - If true then padding can be set with one value other four.
--     BackdropSettings   - Contains the settings for the background, and padding.
--     Color              - Current color of the background texture of the border frame.
--   Bar
--     ClassColor         - True or false.  Used by Target and Focus Health bars only.
--                                          If true then the health bar uses the
--                                          class color otherwise uses the normal color.
--     HapWidth, HapHeight- The current width and height.
--     FillDirection      - Direction to the fill the bar in 'HORIZONTAL' or 'VERTICAL'.
--     RotateTexture      - True or false.  If true then the bar texture will be rotated 90 degree counter-clockwise
--                                          If false no rotation takes place.
--     PaddingAll         - If true then padding can be set with one value otherwise four.
--     Padding            - The amount of pixels to be added or subtracted from the bar texture.
--     StatusBarTexture   - Texture for the bar its self.
--     PredictedBarTexture- Used for Player, Target, Focus.  Texture used for the predicted health.
--     PredictedColor     - Used for Player, Target, Focus.  Color of the predicted health bar.
--     Color              - Hash table for current color of the bar. Health bars only.
--     Color[PowerType]   - This array is for powerbars only.  By default they're loaded from
--                          blizzards default colors.
--   Text
--     TextType
--       Custom           - True or false.  If true then a user custom layout is specified otherwise the
--                                          default layout is used.
--       Layout           - Layout to display the text, this can vary depending on the ValueType.
--                          If this is set to zero nothing will get displayed.
--       MaxValues        - Maximum number of values to be displayed on the bar.
--       ValueName        - Table containing which value to be displayed.
--                            ValueNames:
--                              'current'        - Current Value of the health or power bar.
--                              'maximum'        - Maximum Value of the health or power bar.
--                              'predicted'      - Predicted value of the health or power bar.
--                                                 Not all bars support predicted.
--       ValueType        - Type of value to be displayed based on the ValueName.
--                            ValueTypes:
--                              'whole'             - Whole number
--                              'whole_dgroups'     - Whole number in digit groups 999,999,999
--                              'percent'           - Percentage
--                              'thousands'         - In thousands 999.9k
--                              'millions'          - In millions  999.9m
--                              'short'             - In thousands or millions depending on the value.
--                              'none'              - No value gets displayed
--     FontSettings       - Contains the settings for the text.
--     Color              - Current color of the text for the bar.
--   Text2                - Same as Text, provides a second text frame.
--
--
-- Runebar fields
--   General
--     BarModeAngle       - Angle in degrees in which way the bar will be displayed.  Only works in barmode.
--                        - Must be a multiple of 45 degrees and not 360.
--     BarMode            - If true the runes are displayed from left to right forming a bar of runes.
--     RuneMode           - 'rune'             Only rune textures are shown.
--                          'cooldownbar'      Cooldown bars only are shown.
--                          'runecooldownbar'  Rune and a Cooldown bar are shown.
--     EnergizeShow       - When a rune energizes it shows a border around the rune.
--                            'none'            Don't show any energize borders.
--                            'rune'            Only show an energize border around a rune.
--                            'cooldownbar'     Only show an energize border around a cooldown bar.
--                            'runecooldownbar' Show an energize border around a rune and cooldown bar.
--     EnergizeTime       - Time in seconds to show the energize border for.
--     RuneSwap           - True or false.  If true runes can be dragged and dropped to swap positions. Otherwise
--                                          nothing happens when a rune is dropped on another rune.
--     CooldownDrawEdge   - True or false.  If true a line is drawn on the clock face cooldown animation.
--     CooldownBarDrawEdge- True or false.  If true a line is draw on the cooldown bar edge animation.
--     CooldownAnimation  - True or false.  If true cooldown animation is shown otherwise false.
--     CooldownText       - True or false.  If true then cooldown text gets displayed.
--     HideCooldownFlash  - True or false.  If true a flash cooldown animation is not shown when a rune comes off cooldown.
--     RuneSize           - Width and Hight of all the runes.
--     RunePadding        - For barmode only, the amount of space between the runes.
--     RunePosition       - Frame position of the rune attached to Cooldownbar.  In runecooldownbar mode.
--     RuneOffsetX        - Offset X from RunePosition.
--     RuneOffsetY        - Offset Y from RunePosition.
--
--     Energize           - Table used for energize borders.
--       ColorAll         - True or false.  If true then all energize borders use the same color.
--       Color            - Color used for all the energize borders when ColorAll is true.
--       Color[1 to 8]    - Colors used for each energize border when ColorAll is false.
--
--   Background           - Only used for cooldown bars.
--     ColorAll           - True or false. If true then all cooldown bars use the same color.
--     PaddingAll         - True or false. If true then padding can be set with one value otherwise four.
--     BackdropSettings   - Contains the settings for background, border, and padding for each cooldown bar.
--                          This is used for cooldown bars only.
--     Color              - Color used for all the cooldown bars when ColorAll is true
--     Color[1 to 8]      - Colors used for each cooldown bar when ColorAll is false.
--
--   Bar                  - Only used for cooldown bars.
--     Advanced           - True or false.  If true then you change the size of the bar in small steps.
--     ColorAll           - True or false.  If true then all cooldown bars use the same color.
--     RuneWidth          - Width of the cooldown bar.
--     RuneHeight         - Height of the cooldown bar.
--     FillDirection      - Changes the fill direction. 'VERTICAL' or 'HORIZONTAL'.
--     RotateTexture      - True or false.  If true then the bar texture will be rotated 90 degree counter-clockwise
--                                          If false no rotation takes place.
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     Padding            - The amount of pixels to be added or subtracted from the bar texture.
--     StatusBarTexture   - Texture for the cooldown bar.
--     Color              - Current color of the cooldown bar.
--
--   Text
--     ColorAll           - True or false.  If true then all the combo boxes are set to one color.
--                                          If false then each combo box can be set a different color.
--     FontSettings       - Contains the settings for the text.
--     Color              - Current color of the text for the bar.
--
--   RuneBarOrder         - The order the runes are displayed from left to right in barmode.
--                          RuneBarOrder[Rune slot 1 to 6] = The rune frame on screen.
--   RuneLocation         - Contains the x, y location of the runes on screen when not in barmode.
--
--
-- Combobar fields
--   General
--     ComboPadding       - The amount of space in pixels between each combo point box.
--     ComboAngle         - Angle in degrees in which way the bar will be displayed.
--     ComboFadeOutTime   - Time in seconds for a combo point to go invisible.
--
--   Background
--     ColorAll           - True or false.  If true then all the combo boxes are set to one color.
--                        - True or false.  If false then each combo box can be set a different color.
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     BackdropSettings   - Contains the settings for background, border, and padding for each combo point box.
--     Color              - Contains just one background color for all the combo point boxes.
--                          Only works when ColorAll is true.
--     Color[1 to 5]      - Contains the background colors of all the combo point boxes.
--
--   Bar
--     Advanced           - True or false.  If true then you change the size of the bar in small steps.
--     ColorAll           - True or false.  If true then all the combo boxes are set to one color.
--                                          If false then each combo box can be set a different color.
--     BoxWidth           - The width of each combo point box.
--     BoxHeight          - The height of each combo point box.
--     FillDirection      - Currently not used.
--     RotateTexture      - True or false.  If true then the bar texture will be rotated 90 degree counter-clockwise
--                                          If false no rotation takes place.
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     Padding            - Amount of padding on the forground of each combo point box.
--     StatusbarTexture   - Texture used for the forground of each combo point box.
--     Color              - Contains just one bar color for all the combo point boxes.
--                        - Only works when ComboColorAll is true.
--     Color[1 to 5]      - Contains the bar colors of all the combo point boxes.
--
--
-- Holybar fields
--   General
--     BoxMode            - True or false.  If true the bar uses boxes instead of textures.
--     HolySize           - Size of the holy rune with and height.  Not used in Box Mode.
--     HolyPadding        - Amount of space between each holy rune.  Works in both modes.
--     HolyScale          - Scale of the rune without changing the holy bar size. Not used in box mode.
--     HolyFadeOutTime    - Amount of time in seconds before a holy rune goes dark.  Works in both modes.
--     HolyAngle          - Angle in degrees in which way the bar will be displayed.
--
--   Background
--     ColorAll           - True or false.  If true then all the holy rune boxes are set to one color.
--                                          If false then each holy rune box can be set a different color.
--                                          Only works in box mode.
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     BackdropSettings   - Contains the settings for background, border, and padding for each holy rune box.
--                          When in box mode each holy box uses this setting.
--     Color              - Contains just one background color for all the holy rune boxes.
--                          Only works when ColorAll is true.
--     Color[1 to 3]      - Contains the background colors of all the holy rune boxes.
--
--   Bar
--     Advanced           - True or false.  If true then you change the size of the bar in small steps.
--     ColorAll           - True or false.  If true then all the holy rune boxes are set to one color.
--                                          If false then each holy rune box can be set a different color.
--                                          Only works in box mode.
--     BoxWidth           - Width of each holy rune box.
--     BoxHeight          - Height of each holy rune box.
--     FillDirection      - Currently not used.
--     RotateTexture      - True or false.  If true then the bar texture will be rotated 90 degree counter-clockwise
--                                          If false no rotation takes place.
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     Padding            - Amount of padding on the forground of each holy rune box.
--     StatusbarTexture   - Texture used for the forground of each holy rune box.
--     Color              - Contains just one bar color for all the holy rune boxes.
--                          Only works when ComboColorAll is true.
--     Color[1 to 3]      - Contains the bar colors of all the holy rune boxes.
--
--
-- Shardbar fields        Same as Holybar fields except for the following:
--                          Uses 4 colors.
-- EmberBar fields        Same as ShardBar fields except for the following:
--                          no fadeout time.
--
-- DemonicBar fields
--   General
--     BoxMode            - True or false.  If true the bar uses boxes instead of textures.
--
--   Background
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     BackdropSettings   - Contains the settings for background, border, and padding for each holy rune box.
--                          When in box mode each holy box uses this setting.
--     Color              - Background color for the demonic bar in box and texture mode.
--
--   Bar
--     Advanced           - True or false.  If true then you change the size of the bar in small steps.
--     BoxWidth           - Width of the bar in box mode.
--     BoxHeight          - Height of the bar in box mode.
--     FillDirection      - Direction of fill in box mode.
--     RotateTexture      - True or false.  If true then the bar texture will be rotated 90 degree counter-clockwise
--                                          If false no rotation takes place.
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     Padding            - Amount of padding on the forground of the bar in box mode.
--     StatusbarTexture   - Texture used for the forground in box mode.
--     Color              - Color of the bar in box mode.
--     ColorMeta          - Color of the bar when in metamorphosis for box mode.
--
--   Text
--   Text2                - Same as the ones for health and power bars.
--
--
-- Eclipsebar fields
--   General
--     SliderInside       - True or false.  If true the slider is kept inside the bar is slides on.
--                                          Otherwise the slider box will appear a little out side
--                                          when it reaches edges of the bar.
--     BarHalfLit         - True or false.  If true only half of the bar is lit based on the direction the slider is going in.
--     PowerText          - True or false.  If true then eclipse power text will be shown.
--     EclipseAngle       - Angle in degrees in which the bar will be displayed.
--     SliderDirection    - if 'HORIZONTAL' slider will move left to right and right to left.
--                          if 'VERTICAL' slider will move top to bottom and bottom to top.
--     PredictedPower     - True or false.  If true then predicted power will be activated.
--     IndicatorHideShow  - 'showalways' the indicator will never auto hide.
--                          'hidealways' the indicator will never be shown.
--                          'none'       default.
--     PredictedHideSlider- True or false.  If true then hide the slider when predicted power is on.
--     PredictedEclipse   - True or false.  If true then show an eclipse proc based on predicted power.
--     PredictedHalfLit   - True or false.  Same as BarHalfLit except it is based on predicted power
--     PredictedPowerText - True or false.  If true predicted power text is shown in place of power text.
--
--   Background
--     Moon, Sun, Bar,
--     Slider, and
--     Indicator
--       PaddingAll       - True or false.  If true then padding can be set with one value otherwise four.
--       BackdropSettings - Contains the settings for background, border, and padding.
--       Color            - Contains the color.
--
--   Bar
--     All fields have the following:
--       FillDirection    - Currently not used.
--       RotateTexture    - True or false.  If true then the bar texture will be rotated 90 degree counter-clockwise
--                                          If false no rotation takes place.
--       PaddingAll       - True or false.  If true then padding can be set with one value otherwise four.
--       Padding          - Amount of padding for the forground of the sun and moon.
--       StatusBarTexture - Texture used for the forground.  Not used for the Bar field.
--       Color            - Contains the color of the StatusBarTexture. Not used for the Bar field.
--     Sun and Moon
--       Sun/MoonWidth    - Width of the sun/moon.
--       Sun/MoonHeight   - Height of the sun/moon.
--     Slider
--       SunMoon          - True or false.  If true the slider uses the Sun and Moon color based on which direction it's going in.
--       SliderWidth      - Width of the slider.
--       SliderHeight     - Height of the slider.
--     Indicator          - Same as slider except used for predicted power.
--
--     Bar
--       BarWidth         - Width of the bar.
--       BarHeight        - Height of the bar.
--       StatusBarTextureLunar
--                        - Texture that fills up the solar half of the bar.
--       StatusBarTextureSolar
--                        - Texture that fills up the lunar half of the bar.
--       ColorLunar       - Color of the StatusBarTextureLunar.
--       ColorSolar       - Color of the StatusBarTextureSolar.
--
--   Text
--     FontSettings       - Contains the settings for the text.
--     Color              - Current color of the text for the bar.
--
--
-- ShadowBar fields       - Same as shardbar fields except for:
--                            Uses 3 colors.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Predicted Power
--
-- Keeps track of spells casting.
--
-- PredictedSpellEvent       - Used by SetPredictedSpell().
--                             Converts an event from CombatLogUnfiltered()/SpellCasting() to one of the following:
--                               EventSpellStart
--                               EventSpellSucceeded
--                               EventSpellEnergize
--                               EventSpellMissed
--                               EventSpellFailed
--
-- PredictedSpellMessage     - Used by SetPredictedSpell()
--                             Used with EventSpellFailed.  If the Message is not found in the table.
--                             then the spell is considered failed.
-- PredictedSpellsTimeout     - Used by ModifyCastingSpell()
--                             Amount of time before clearing the casting spell.
--
-- PredictedSpellsTime        - Used by ModifyCastingSpell(), CheckPredictedSpellsTimeout()
--                             Keeps track of the time based on PredictedSpellsTimeout. When time is reached
--                             the casting spell is removed.
--
-- PredictedSpellsTimer       - Used by SetPredictedSpells(), ModifyCastingSpell()
--                             Timer handle for CheckPredictedSpellsTimeout()
--
-- PredictedSpellsActive     - Used by SetPredictedSeplls(), HideUnitBar()
--                             If true then predictedspells is turned on, otherwise its off.
--
-- PredictedSpellCasting     - Used by ModifyCastingSpell(), CheckPredictedSpellsTimeout(),
--                                     GetPredictedSpells(), SetPredictedSpell()
--   SpellID                   Spell that is casting
--   LineID                    LineID of Spell
--   CastTime                  Amount of time for the spell to finish casting in seconds.
--
-- PredictedSpells[SpellID]  - Used by SetPredictedSpells(), SetPredictedSpell()
--   SpellID                   SpellID to search for.
--   EndOn                       'energize' the spell will be cleared on an energize event.
--                               'casting'  the spell will be cleared when the spell ends due to success, failed, etc.
--   Fn                        This gets called when a spell starts casting, then on end, and on energize.
--                             Fn(SpellID, CastTime, Message)
--                               Message
--                                 'start'  Gets called on spell cast start.
--                                   on 'start' you can return -1 to not add the spell to be tracked.
--                                   see EclipseBar.lua on how this is done.
--                                 'afterstart'  Gets called right after 'cast start'.
--                                 'end'    Gets called on spell success.
--                                 'failed' Gets called if the spell didn't complete.
--                                 'timeout' Gets called by CheckPredictedSpellsTimeout() if the spell timed out.
--                               CastTime  The amount of time to cast the spell in seconds.
--                               SpellID is always negative on 'start', 'afterstart', 'end', or 'failed'
--
--
-- NOTE: See the notes on each of the predicted power functions for more details.  Also
--       See Eclipse.lua on how this is used.
--       PredictedSpells will turn its self off if the frame its being used on is hidden.
--       Will turn back on when frame is shown.  Assuming the system wasn't turned off before hand.
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Equipment set bonus
--
-- Keeps track of gear set bonus.
--
-- EquipmentSet[Slot][ItemID]    Holds the Tier number based on ItemID and Slot.
--                               Used by CheckSetBonus().
-- EquipmentSetBonus             Keeps track of 1 or more equipment set bonus.
-- EquipmentSetBonus[Tier]       Contains the active bonus of that tier set.
--                               GetSetBonus() and CheckSetBonus().
--
-- EquipmentSetRegisterEvent     if false then events for equipment set hasn't been registed.
--                               Otherwise they've been registered.
--                               Used by GetSetBonus()
--
-- NOTE: See Eclipse.lua on how this is used.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- SetTimer
--
-- Calls functions based on a delay.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Alignment tool
--
-- The alignment tool uses green and white selected bars.  The green bar is the bar
-- that the white bars will be lined up with.  When you right click a bar it
-- opens up the alignement tool. Right click again to select the bar which will have
-- a green border around it and the alignment tool panel will open up.
--
-- The UnitBarStartMoving() function handles that right/left clicking of a bar
-- to select/unselect.
--
-- SetLayout()  Will disable select mode and hide the alignment tool if its visible.
-- SetAllOptions()  Checks to see if alignment tool is enabled.
--
-- Options.ATOFrame:Hide()    Hides the alignment tool.
-- Options.ATOFrame:Show()    Shows the alignment tool.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ShareData()
--
-- Other parts of the mod if needed can have a BarType:ShareData() function.
-- This is used to pass upvalues to other parts of the mod.
-- If this function exists it'll be called. ShareData gets called during runtime
-- and when things change.  Check bottom of this file on hows it used.
-- Options:ShareData() is included as well.
-------------------------------------------------------------------------------
local AlignmentTooltipDesc = 'Right mouse button to align'

local InCombat = false
local InVehicle = false
local InPetBattle = false
local IsDead = false
local HasTarget = false
local HasFocus = false
local HasPet = false
local PlayerPowerType = nil
local PlayerClass = nil
local PlayerStance = nil
local PlayerSpecialization = nil
local PlayerGUID = nil

local MoonkinForm = MOONKIN_FORM
local CatForm = CAT_FORM
local BearForm = BEAR_FORM
local MonkMistWeaverSpec = SPEC_MONK_MISTWEAVER

local Initialized = false
local GetTextValuePercentFn = nil

local EquipmentSetRegisterEvent = false
local PSelectedUnitBarF = nil
local SelectMode = false

local PredictedSpellsTimeout = 7
local PredictedSpellsTime = nil
local PredictedSpellsTimer = nil
local PredictedSpellsActive = false
local PredictedSpellsBarType = nil

local EventSpellStart       = 1
local EventSpellSucceeded   = 2
local EventSpellEnergize    = 3
local EventSpellMissed      = 4
local EventSpellFailed      = 5

local CooldownBarTimerDelay = 1 / 40 -- 40 times per second
local UnitBarDelay = 1 -- Once per second. (1000 ms)

local UnitBarsParent = nil
local UnitBars = nil

local BgTexture = 'Blizzard Tooltip'
local BdTexture = 'Blizzard Tooltip'
local StatusBarTexture = 'Blizzard'
local GUBStatusBarTexture = 'GUB Bright Bar'
local UBFontType = 'Friz Quadrata TT'

local Backdrop = {
  bgFile   = LSM:Fetch('background', BgTexture), -- background texture
  edgeFile = LSM:Fetch('border', BdTexture),     -- border texture
  tile = true,      -- True to repeat the background texture to fill the frame, false to scale it.
  tileSize = 16,    -- Size (width or height) of the square repeating background tiles (in pixels).
  edgeSize = 12,    -- Thickness of edge segments and square size of edge corners (in pixels).
  insets = {        -- Positive values shrink the border inwards, negative expand it outwards.
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

local SelectFrameBorder = {
  bgFile   = '',
  edgeFile = [[Interface\Addons\GalvinUnitBars\Textures\GUB_SquareBorder.tga]],
  tile = true,
  tileSize = 16,
  edgeSize = 6,
  insets = {
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

local FontSettings = {  -- for debugging
  FontType = UBFontType,
  FontSize = 16,
  FontStyle = 'OUTLINE',
  FontHAlign = 'CENTER',
  Position = 'CENTER',
  Width = 200,
  OffsetX = 0,
  OffsetY = 0,
  ShadowOffset = 0,
}

local Defaults = {
  profile = {
    Point = 'CENTER',
    RelativePoint = 'CENTER',
    Px = 0,
    Py = 0,
    EnableClass = true,
    IsGrouped = false,
    IsLocked = false,
    IsClamped = true,
    HideTooltips = false,
    HideTooltipsDesc = false,
    AlignmentToolEnabled = true,
    FadeOutTime = 1.0,
-- Player Health
    PlayerHealth = {
      Name = 'Player Health',
      Enabled = true,
      WaitTime = 1,
      x = 0,
      y = 150,
      Status = {
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        PredictedHealth = true,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        Advanced = false,
        HapWidth = 170,
        HapHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
        PredictedBarTexture = StatusBarTexture,
        ClassColor = false,
        Color = {r = 0, g = 1, b = 0, a = 1},
        PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
      },
      Text = {
        TextType = {
          Custom = false,
          Layout = '%d%%',
          MaxValues = 1,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text2 = {
        TextType = {
          Custom = false,
          Layout = '',
          MaxValues = 0,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'RIGHT',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
-- Player Power
    PlayerPower = {
      Name = 'Player Power',
      Enabled = true,
      WaitTime = 1,
      x = 0,
      y = 120,
      Status = {
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        PredictedPower = true,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        Advanced = false,
        HapWidth = 170,
        HapHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
        PredictedBarTexture = StatusBarTexture,
        PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
      },
      Text = {
        TextType = {
          Custom = false,
          Layout = '%d%%',
          MaxValues = 1,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text2 = {
        TextType = {
          Custom = false,
          Layout = '',
          MaxValues = 0,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'RIGHT',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
-- Target Health
    TargetHealth = {
      Name = 'Target Health',
      Enabled = true,
      BarVisible = function() return HasTarget end,
      WaitTime = 1,
      x = 0,
      y = 90,
      Status = {
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        PredictedHealth = true,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        Advanced = false,
        HapWidth = 170,
        HapHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
        PredictedBarTexture = StatusBarTexture,
        ClassColor = false,
        Color = {r = 0, g = 1, b = 0, a = 1},
        PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
      },
      Text = {
        TextType = {
          Custom = false,
          Layout = '%d%%',
          MaxValues = 1,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text2 = {
        TextType = {
          Custom = false,
          Layout = '',
          MaxValues = 0,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'RIGHT',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
-- Target Power
    TargetPower = {
      Name = 'Target Power',
      Enabled = true,
      BarVisible = function() return HasTarget end,
      WaitTime = 1,
      x = 0,
      y = 60,
      Status = {
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        Advanced = false,
        HapWidth = 170,
        HapHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
      },
      Text = {
        TextType = {
          Custom = false,
          Layout = '%d%%',
          MaxValues = 1,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text2 = {
        TextType = {
          Custom = false,
          Layout = '',
          MaxValues = 0,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'RIGHT',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
-- Focus Health
    FocusHealth = {
      Name = 'Focus Health',
      Enabled = true,
      BarVisible = function() return HasFocus end,
      WaitTime = 1,
      x = 0,
      y = 30,
      Status = {
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        PredictedHealth = true,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        Advanced = false,
        HapWidth = 170,
        HapHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
        PredictedBarTexture = StatusBarTexture,
        ClassColor = false,
        Color = {r = 0, g = 1, b = 0, a = 1},
        PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
      },
      Text = {
        TextType = {
          Custom = false,
          Layout = '%d%%',
          MaxValues = 1,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text2 = {
        TextType = {
          Custom = false,
          Layout = '',
          MaxValues = 0,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'RIGHT',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
-- Focus Power
    FocusPower = {
      Name = 'Focus Power',
      Enabled = true,
      BarVisible = function() return HasFocus end,
      WaitTime = 1,
      x = 0,
      y = 0,
      Status = {
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        Advanced = false,
        HapWidth = 170,
        HapHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
      },
      Text = {
        TextType = {
          Custom = false,
          Layout = '%d%%',
          MaxValues = 1,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text2 = {
        TextType = {
          Custom = false,
          Layout = '',
          MaxValues = 0,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'RIGHT',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
-- Pet Health
    PetHealth = {
      Name = 'Pet Health',
      Enabled = true,
      BarVisible = function() return HasPet end,
      UsedByClass = {DEATHKNIGHT = '', MAGE = '3', WARLOCK = '', HUNTER = ''},
      WaitTime = 1,
      x = 0,
      y = -30,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        Advanced = false,
        HapWidth = 170,
        HapHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
      },
      Text = {
        TextType = {
          Custom = false,
          Layout = '%d%%',
          MaxValues = 1,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text2 = {
        TextType = {
          Custom = false,
          Layout = '',
          MaxValues = 0,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'RIGHT',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
-- Pet Power
    PetPower = {
      Name = 'Pet Power',
      Enabled = true,
      BarVisible = function() return HasPet end,
      UsedByClass = {DEATHKNIGHT = '', MAGE = '3', WARLOCK = '', HUNTER = ''},
      WaitTime = 1,
      x = 0,
      y = -60,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        Advanced = false,
        HapWidth = 170,
        HapHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
      },
      Text = {
        TextType = {
          Custom = false,
          Layout = '%d%%',
          MaxValues = 1,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text2 = {
        TextType = {
          Custom = false,
          Layout = '',
          MaxValues = 0,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'RIGHT',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
-- Mana Power
    ManaPower = {
      Name = 'Druid or Monk Mana',
      Enabled = true,
      BarVisible = function()
                     return
                       ( PlayerClass == 'DRUID' and ( PlayerStance ==  CatForm or PlayerStance == BearForm ) or
                         PlayerClass == 'MONK' and PlayerSpecialization == MonkMistWeaverSpec ) and
                       PlayerPowerType ~= 0 end, -- 0 = Mana
      UsedByClass = {DRUID = '', MONK = '2'},
      WaitTime = 1,
      x = 0,
      y = -90,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        Advanced = false,
        HapWidth = 170,
        HapHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
      },
      Text = {
        TextType = {
          Custom = false,
          Layout = '%d%%',
          MaxValues = 1,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text2 = {
        TextType = {
          Custom = false,
          Layout = '',
          MaxValues = 0,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'RIGHT',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
-- RuneBar
    RuneBar = {
      Name = 'Rune Bar',
      Enabled = true,
      UsedByClass = {DEATHKNIGHT = ''},
      WaitTime = 1,
      x = 0,
      y = -120,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        BarModeAngle = 90,
        BarMode = true,  -- Must be true for default or no default rune positions gets created.
        RuneMode = 'rune',
        EnergizeShow = 'rune',
        EnergizeTime = 3,
        CooldownDrawEdge = false,
        CooldownBarDrawEdge = false,
        HideCooldownFlash = true,
        CooldownAnimation = true,
        CooldownText = false,
        RuneSize = 22,
        RuneSwap = true,
        RunePadding = 0,
        RunePosition = 'LEFT',
        RuneOffsetX = 0,
        RuneOffsetY = 0,
        Energize = {
          ColorAll = false,
          Color = {
            r = 1, g = 0, b = 0, a = 1,               -- All runes
            [1] = {r = 1, g = 0, b = 0, a = 1},       -- Blood
            [2] = {r = 1, g = 0, b = 0, a = 1},       -- Blood
            [3] = {r = 0, g = 1, b = 0, a = 1},       -- Unholy
            [4] = {r = 0, g = 1, b = 0, a = 1},       -- Unholy
            [5] = {r = 0, g = 0.7, b = 1, a = 1},     -- Frost
            [6] = {r = 0, g = 0.7, b = 1, a = 1},     -- Frost
            [7] = {r = 1, g = 0, b = 1, a = 1},       -- Death
            [8] = {r = 1, g = 0, b = 1, a = 1},       -- Death
          },
        },
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        ColorAll = false,
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          r = 0, g = 0, b = 0, a = 1,                                     -- All runes
          [1] = {r = 1 * 0.5, g = 0,           b = 0,       a = 1},       -- Blood
          [2] = {r = 1 * 0.5, g = 0,           b = 0,       a = 1},       -- Blood
          [3] = {r = 0,       g = 1   * 0.5,   b = 0,       a = 1},       -- Unholy
          [4] = {r = 0,       g = 1   * 0.5,   b = 0,       a = 1},       -- Unholy
          [5] = {r = 0,       g = 0.7 * 0.5,   b = 1 * 0.5, a = 1},       -- Frost
          [6] = {r = 0,       g = 0.7 * 0.5,   b = 1 * 0.5, a = 1},       -- Frost
          [7] = {r = 1 * 0.5, g = 0,           b = 1 * 0.5, a = 1},       -- Death
          [8] = {r = 1 * 0.5, g = 0,           b = 1 * 0.5, a = 1},       -- Death
        },
      },
      Bar = {
        Advanced = false,
        ColorAll = false,
        RuneWidth = 40,
        RuneHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          r = 1, g = 0, b = 0, a = 1,               -- All runes
          [1] = {r = 1, g = 0, b = 0, a = 1},       -- Blood
          [2] = {r = 1, g = 0, b = 0, a = 1},       -- Blood
          [3] = {r = 0, g = 1, b = 0, a = 1},       -- Unholy
          [4] = {r = 0, g = 1, b = 0, a = 1},       -- Unholy
          [5] = {r = 0, g = 0.7, b = 1, a = 1},     -- Frost
          [6] = {r = 0, g = 0.7, b = 1, a = 1},     -- Frost
          [7] = {r = 1, g = 0, b = 1, a = 1},       -- Death
          [8] = {r = 1, g = 0, b = 1, a = 1},       -- Death
        },
      },
      Text = {
        ColorAll = false,
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {
          r = 1, g = 1, b = 1, a = 1,               -- All runes
          [1] = {r = 1, g = 1, b = 1, a = 1},       -- Blood
          [2] = {r = 1, g = 1, b = 1, a = 1},       -- Blood
          [3] = {r = 1, g = 1, b = 1, a = 1},       -- Unholy
          [4] = {r = 1, g = 1, b = 1, a = 1},       -- Unholy
          [5] = {r = 1, g = 1, b = 1, a = 1},       -- Frost
          [6] = {r = 1, g = 1, b = 1, a = 1},       -- Frost
          [7] = {r = 1, g = 1, b = 1, a = 1},       -- Death
          [8] = {r = 1, g = 1, b = 1, a = 1},       -- Death
        },
      },
      RuneBarOrder = {[1] = 1, [2] = 2, [3] = 5, [4] = 6, [5] = 3, [6] = 4},
      RuneLocation = {
        [1] = {x = '', y = ''},
        [2] = {x = '', y = ''},
        [3] = {x = '', y = ''},
        [4] = {x = '', y = ''},
        [5] = {x = '', y = ''},
        [6] = {x = '', y = ''},
      },
    },
-- ComboBar
    ComboBar = {
      Name = 'Combo Bar',
      Enabled = true,
      BarVisible = function() return HasTarget end,
      UsedByClass = {ROGUE = '', DRUID = '1234'},
      WaitTime = 1,
      x = 0,
      y = -150,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = true,
        HideNoCombat    = false,
      },
      General = {
        ComboAngle = 90,
        ComboPadding = 5,
        ComboFadeOutTime = 1,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        ColorAll = false,
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          r = 0, g = 0, b = 0, a = 1,
          [1] = {r = 0, g = 0, b = 0, a = 1},
          [2] = {r = 0, g = 0, b = 0, a = 1},
          [3] = {r = 0, g = 0, b = 0, a = 1},
          [4] = {r = 0, g = 0, b = 0, a = 1},
          [5] = {r = 0, g = 0, b = 0, a = 1},
        },
      },
      Bar = {
        Advanced = false,
        ColorAll = false,
        BoxWidth = 40,
        BoxHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          r = 1, g = 0, b = 0, a = 1,
          [1] = {r = 1, g = 0, b = 0, a = 1},
          [2] = {r = 1, g = 0, b = 0, a = 1},
          [3] = {r = 1, g = 0, b = 0, a = 1},
          [4] = {r = 1, g = 0, b = 0, a = 1},
          [5] = {r = 1, g = 0, b = 0, a = 1},
        }
      }
    },
-- HolyBar
    HolyBar = {
      Name = 'Holy Bar',
      Enabled = true,
      UsedByClass = {PALADIN = ''},
      WaitTime = 1,
      x = 0,
      y = -180,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        BoxMode = false,
        HolySize = 1,
        HolyPadding = -2,
        HolyScale = 1,
        HolyFadeOutTime = 1,
        HolyAngle = 90
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        ColorAll = false,
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          r = 0.5, g = 0.5, b = 0.5, a = 1,
          [1] = {r = 0.5, g = 0.5, b = 0.5, a = 1},
          [2] = {r = 0.5, g = 0.5, b = 0.5, a = 1},
          [3] = {r = 0.5, g = 0.5, b = 0.5, a = 1},
          [4] = {r = 0.5, g = 0.5, b = 0.5, a = 1},
          [5] = {r = 0.5, g = 0.5, b = 0.5, a = 1},
        },
      },
      Bar = {
        Advanced = false,
        ColorAll = false,
        BoxWidth = 40,
        BoxHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          r = 1, g = 0.705, b = 0, a = 1,
          [1] = {r = 1, g = 0.705, b = 0, a = 1},
          [2] = {r = 1, g = 0.705, b = 0, a = 1},
          [3] = {r = 1, g = 0.705, b = 0, a = 1},
          [4] = {r = 1, g = 0.705, b = 0, a = 1},
          [5] = {r = 1, g = 0.705, b = 0, a = 1},
        },
      },
    },
-- ShardBar
    ShardBar = {
      Name = 'Shard Bar',
      Enabled = true,
      UsedByClass = {WARLOCK = '1'},
      WaitTime = 1,
      x = 0,
      y = -215,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        BoxMode = false,
        ShardSize = 1,
        ShardPadding = 10,
        ShardScale = 0.80,
        ShardFadeOutTime = 1,
        ShardAngle = 90
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        ColorAll = false,
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          r = 0.329, g = 0.172, b = 0.337, a = 1,
          [1] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
          [2] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
          [3] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
          [4] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
        },
      },
      Bar = {
        Advanced = false,
        ColorAll = false,
        BoxWidth = 40,
        BoxHeight = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          r = 0.980, g = 0.517, b = 1, a = 1,
          [1] = {r = 0.980, g = 0.517, b = 1, a = 1},
          [2] = {r = 0.980, g = 0.517, b = 1, a = 1},
          [3] = {r = 0.980, g = 0.517, b = 1, a = 1},
          [4] = {r = 0.980, g = 0.517, b = 1, a = 1},
        },
      },
    },
-- DemonicBar
    DemonicBar = {
      Name = 'Demonic Bar',
      Enabled = true,
      UsedByClass = {WARLOCK = '2'},
      WaitTime = 1,
      x = -200,
      y = -215,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        BoxMode = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0.082, g = 0.219, b = 0.019, a = 1},
      },
      Bar = {
        Advanced = false,
        BoxWidth = 150,
        BoxHeight = 24,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {r = 0.627, g = 0.298, b = 827, a = 1},
        ColorMeta = {r = 0.752, g = 0.439, b = 0.909, a = 1},
      },
      Text = {
        TextType = {
          Custom = false,
          Layout = '%d%%',
          MaxValues = 1,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 11,
          FontStyle = 'OUTLINE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = -1,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text2 = {
        TextType = {
          Custom = false,
          Layout = '',
          MaxValues = 0,
          ValueName = {'current', 'maximum', 'current'},
          ValueType = {'percent', 'whole',   'none'},
        },
        FontSettings = {
          FontType = UBFontType,
          FontSize = 11,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          Position = 'RIGHT',
          Width = 200,
          OffsetX = 0,
          OffsetY = -1,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
-- EmberBar
    EmberBar = {
      Name = 'Ember Bar',
      Enabled = true,
      UsedByClass = {WARLOCK = '3'},
      WaitTime = 1,
      x = -200,
      y = -215,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        BoxMode = false,
        EmberSize = 1,
        EmberPadding = 5,
        EmberScale = 1,
        EmberAngle = 90,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        ColorAll = false,
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          r = 0.180, g = 0.047, b = 0.031, a = 1,
          [1] = {r = 0.180, g = 0.047, b = 0.031, a = 1},
          [2] = {r = 0.180, g = 0.047, b = 0.031, a = 1},
          [3] = {r = 0.180, g = 0.047, b = 0.031, a = 1},
          [4] = {r = 0.180, g = 0.047, b = 0.031, a = 1},
        },
      },
      Bar = {
        Advanced = false,
        ColorAll = false,
        BoxWidth = 25,
        BoxHeight = 34,
        FillDirection = 'VERTICAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          r = 1, g = 0.325, b = 0 , a = 1,
          [1] = {r = 1, g = 0.325, b = 0 , a = 1},
          [2] = {r = 1, g = 0.325, b = 0 , a = 1},
          [3] = {r = 1, g = 0.325, b = 0 , a = 1},
          [4] = {r = 1, g = 0.325, b = 0 , a = 1},
        },
      },
    },
-- EclipseBar
    EclipseBar = {
      Name = 'Eclipse Bar',
      Enabled = true,
      BarVisible = function() return PlayerClass == 'DRUID' and (PlayerStance == MoonkinForm or PlayerStance == nil) end,
      UsedByClass = {DRUID = '1'},
      WaitTime = 0.333,
      x = 0,
      y = -250,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        SliderInside = true,
        BarHalfLit = false,
        PowerText = false,
        EclipseAngle = 90,
        SliderDirection = 'HORIZONTAL',
        EclipseFadeOutTime = 1,
        SunOffsetX = 0,
        SunOffsetY = 0,
        MoonOffsetX = 0,
        MoonOffsetY = 0,
        PredictedPower = false,
        IndicatorHideShow = 'none',
        PredictedHideSlider = false,
        PredictedEclipse = true,
        PredictedBarHalfLit = false,
        PredictedPowerText = true,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        Moon = {
          PaddingAll = true,
          BackdropSettings = {
            BgTexture = BgTexture,
            BdTexture = BdTexture,
            BgTile = false,
            BgTileSize = 16,
            BdSize = 12,
            Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
          },
          Color = {r = 0, g = 0, b = 0, a = 1},
        },
        Sun = {
          PaddingAll = true,
          BackdropSettings = {
            BgTexture = BgTexture,
            BdTexture = BdTexture,
            BgTile = false,
            BgTileSize = 16,
            BdSize = 12,
            Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
          },
          Color = {r = 0, g = 0, b = 0, a = 1},
        },
        Bar = {
          PaddingAll = true,
          BackdropSettings = {
            BgTexture = BgTexture,
            BdTexture = BdTexture,
            BgTile = false,
            BgTileSize = 16,
            BdSize = 12,
            Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
          },
          Color = {r = 0, g = 0, b = 0, a = 1},
        },
        Slider = {
          PaddingAll = true,
          BackdropSettings = {
            BgTexture = BgTexture,
            BdTexture = BdTexture,
            BgTile = false,
            BgTileSize = 16,
            BdSize = 12,
            Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
          },
          Color = {r = 0, g = 0, b = 0, a = 1},
        },
        Indicator = {
          PaddingAll = true,
          BackdropSettings = {
            BgTexture = BgTexture,
            BdTexture = BdTexture,
            BgTile = false,
            BgTileSize = 16,
            BdSize = 12,
            Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
          },
          Color = {r = 0, g = 0, b = 0, a = 1},
        },
      },
      Bar = {
        Moon = {
          Advanced = false,
          MoonWidth = 25,
          MoonHeight = 25,
          FillDirection = 'HORIZONTAL',
          RotateTexture = false,
          PaddingAll = true,
          Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
          StatusBarTexture = GUBStatusBarTexture,
          Color = {r = 0.847, g = 0.988, b = 0.972, a = 1},
        },
        Sun = {
          Advanced = false,
          SunWidth = 25,
          SunHeight = 25,
          FillDirection = 'HORIZONTAL',
          RotateTexture = false,
          PaddingAll = true,
          Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
          StatusBarTexture = GUBStatusBarTexture,
          Color = {r = 0.96, g = 0.925, b = 0.113, a = 1},
        },
        Bar = {
          Advanced = false,
          BarWidth = 170,
          BarHeight = 25,
          FillDirection = 'HORIZONTAL',
          RotateTexture = false,
          PaddingAll = true,
          Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
          StatusBarTextureLunar = GUBStatusBarTexture,
          StatusBarTextureSolar = GUBStatusBarTexture,
          ColorLunar = {r = 0.364, g = 0.470, b = 0.627, a = 1}, -- moon
          ColorSolar = {r = 0.631, g = 0.466, b = 0.184, a = 1}, -- sun
        },
        Slider = {
          Advanced = false,
          SunMoon = true,
          SliderWidth = 16,
          SliderHeight = 20,
          FillDirection = 'HORIZONTAL',
          RotateTexture = false,
          PaddingAll = true,
          Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
          StatusBarTexture = GUBStatusBarTexture,
          Color = {r = 0, g = 1, b = 0, a = 1},
        },
        Indicator = {
          Advanced = false,
          SunMoon = false,
          IndicatorWidth = 16,
          IndicatorHeight = 20,
          FillDirection = 'HORIZONTAL',
          RotateTexture = false,
          PaddingAll = true,
          Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
          StatusBarTexture = GUBStatusBarTexture,
          Color = {r = 0, g = 1, b = 0, a = 1},
        },
      },
      Text = {
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'OUTLINE',
          FontHAlign = 'CENTER',
          Position = 'CENTER',
          Width = 200,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1}
      },
    },
-- ShadowBar
    ShadowBar = {
      Name = 'Shadow Bar',
      Enabled = true,
      UsedByClass = {PRIEST = '3'},
      WaitTime = 1,
      x = -200,
      y = -215,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        BoxMode = false,
        ShadowSize = 1,
        ShadowPadding = 1,
        ShadowScale = 1,
        ShadowFadeOutTime = 1,
        ShadowAngle = 90
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        ColorAll = false,
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          r = 0.329, g = 0.172, b = 0.337, a = 1,
          [1] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
          [2] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
          [3] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
        },
      },
      Bar = {
        Advanced = false,
        ColorAll = false,
        BoxWidth = 38,
        BoxHeight = 37,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          r = 0.729, g = 0.466, b = 1, a = 1,
          [1] = {r = 0.729, g = 0.466, b = 1, a = 1},
          [2] = {r = 0.729, g = 0.466, b = 1, a = 1},
          [3] = {r = 0.729, g = 0.466, b = 1, a = 1},
        },
      },
    },
-- ChiBar
    ChiBar = {
      Name = 'Chi Bar',
      Enabled = true,
      UsedByClass = {MONK = ''},
      WaitTime = 1,
      x = -200,
      y = -215,
      Status = {
        HideNotUsable   = true,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      General = {
        BoxMode = false,
        ChiSize = 1,
        ChiPadding = 5,
        ChiScale = 1,
        ChiFadeOutTime = 1,
        ChiFadeInTime = 0.5,
        ChiAngle = 90
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        ColorAll = false,
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          r = 0.113, g = 0.192, b = 0.188, a = 1,
          [1] = {r = 0.113, g = 0.192, b = 0.188, a = 1},
          [2] = {r = 0.113, g = 0.192, b = 0.188, a = 1},
          [3] = {r = 0.113, g = 0.192, b = 0.188, a = 1},
          [4] = {r = 0.113, g = 0.192, b = 0.188, a = 1},
          [5] = {r = 0.113, g = 0.192, b = 0.188, a = 1},
        },
      },
      Bar = {
        Advanced = false,
        ColorAll = false,
        BoxWidth = 30,
        BoxHeight = 30,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          r = 0.407, g = 0.764, b = 0.670, a = 1,
          [1] = {r = 0.407, g = 0.764, b = 0.670, a = 1},
          [2] = {r = 0.407, g = 0.764, b = 0.670, a = 1},
          [3] = {r = 0.407, g = 0.764, b = 0.670, a = 1},
          [4] = {r = 0.407, g = 0.764, b = 0.670, a = 1},
          [5] = {r = 0.407, g = 0.764, b = 0.670, a = 1},
        },
      },
    },
  },
}

local PointCalc = {
        TOPLEFT     = {x = 0,   y = 0},
        TOP         = {x = 0.5, y = 0},
        TOPRIGHT    = {x = 1,   y = 0},
        LEFT        = {x = 0,   y = 0.5},
        CENTER      = {x = 0.5, y = 0.5},
        RIGHT       = {x = 1,   y = 0.5},
        BOTTOMLEFT  = {x = 0,   y = 1},
        BOTTOM      = {x = 0.5, y = 1},
        BOTTOMRIGHT = {x = 1,   y = 1}
      }

-- letter before ID is only to format the data here making it easier to read.
-- its ignored
local EquipmentSet = {

-- Balanced druid set, ID, Normal, Heroic (tier 12)
  a1  = {[71108] = 12, [71497] = 12}, -- helmet
  a3  = {[71111] = 12, [71500] = 12}, -- shoulders
  a5  = {[71110] = 12, [71499] = 12}, -- chest
  a7  = {[71109] = 12, [71498] = 12}, -- legs
  a10 = {[71107] = 12, [71496] = 12}, -- gloves

-- Hunter set, ID, LFR, Normal, Heroic (tier 13)
  b1  = {[78793] = 13, [77030] = 13, [78698] = 13}, -- helmet
  b3  = {[78832] = 13, [77032] = 13, [78737] = 13}, -- shoulders
  b5  = {[78756] = 13, [77028] = 13, [78661] = 13}, -- chest
  b7  = {[78804] = 13, [77031] = 13, [78709] = 13}, -- legs
  b10 = {[78769] = 13, [77029] = 13, [78674] = 13}, -- gloves
}

local EquipmentSetBonus = {}

local PredictedSpellEvent = {
  UNIT_SPELLCAST_START       = EventSpellStart,
  UNIT_SPELLCAST_SUCCEEDED   = EventSpellSucceeded,
  SPELL_ENERGIZE             = EventSpellEnergize,
  SPELL_MISSED               = EventSpellMissed,
  SPELL_CAST_FAILED          = EventSpellFailed,
}

local PredictedSpellMessage = {         -- These variables are blizzard globals. Must be used for foreign languages.
  [SPELL_FAILED_NOT_READY]         = 1, -- SPELL_FAILED_NOT_READY
  [SPELL_FAILED_SPELL_IN_PROGRESS] = 1, -- SPELL_FAILED_SPELL_IN_PROGRESS
}

local PredictedSpells = {}

local RegEventFrames = {}

local PredictedSpellCasting = {
  SpellID = 0,
  LineID = -1,
  Time = 0,
  CastTime = 0,
}

local PowerTypeToNumber = {
  MANA = 0, RAGE = 1, FOCUS = 2, ENERGY = 3, RUNIC_POWER = 6,
  SOUL_SHARDS = 7, ECLIPSE = 8, HOLY_POWER = 9, LIGHT_FORCE = 12,
  SHADOW_ORBS = 13, BURNING_EMBERS = 14, DEMONIC_FURY = 15
}

local PowerColorType = {
  MANA = 0, RAGE = 1, FOCUS = 2, ENERGY = 3, RUNIC_POWER = 6
}

-- Constants used in NumberToDigitGroups
local Thousands = strmatch(format('%.1f', 1/5), '([^0-9])') == '.' and ',' or '.'
local BillionFormat = '%s%d' .. Thousands .. '%03d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local MillionFormat = '%s%d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local ThousandFormat = '%s%d' .. Thousands..'%03d'

-- Share with the whole addon.
GUB.LSM = LSM
GUB.Defaults = Defaults
GUB.PowerColorType = PowerColorType
GUB.PowerTypeToNumber = PowerTypeToNumber
GUB.MouseOverDesc = 'Modifier + left mouse button to drag'

-------------------------------------------------------------------------------
--
-- Initialize the UnitBarsF table
--
-------------------------------------------------------------------------------
do
  local Index = 0
  for BarType, UB in pairs(Defaults.profile) do
    if type(UB) == 'table' then
      Index = Index + 1
      local UBFTable = CreateFrame('Frame')
      UnitBarsF[BarType] = UBFTable
      UnitBarsFI[Index] = UBFTable
    end
  end
end

-------------------------------------------------------------------------------
-- RegisterEvents
--
-- Register/unregister events
--
-- Usage: RegisterEvents(Action, EventType)
--
-- Action       'unregister' or 'register'
-- EventType    'main'             Registers the main events for the mod.
--              'predictedspell'   Registers events for predicted spells.
--              'setbonus'         Registers events for equipment set bonus
-------------------------------------------------------------------------------
local function RegisterEvents(Action, EventType)

  if EventType == 'main' then

    -- Register events for the addon.
    Main:RegEvent(true, 'UNIT_ENTERED_VEHICLE',          GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_EXITED_VEHICLE',           GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_DISPLAYPOWER',             GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_PET',                      GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'PLAYER_REGEN_ENABLED',          GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_REGEN_DISABLED',         GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_TARGET_CHANGED',         GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_FOCUS_CHANGED',          GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_DEAD',                   GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_UNGHOST',                GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_ALIVE',                  GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_LEVEL_UP',               GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_TALENT_UPDATE',          GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_SPECIALIZATION_CHANGED', GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'UPDATE_SHAPESHIFT_FORM',        GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PET_BATTLE_OPENING_START',      GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PET_BATTLE_CLOSE',              GUB.UnitBarsUpdateStatus)

    -- Rest of the events are defined at the end of each lua file for the bars.

  elseif EventType == 'predictedspells' then
    local Flag = Action == 'register'

    -- register events for predicted spells.
    Main:RegEvent(Flag, 'COMBAT_LOG_EVENT_UNFILTERED', GUB.CombatLogUnfiltered)
    Main:RegEvent(Flag, 'UNIT_SPELLCAST_START',        GUB.SpellCasting, 'player')
    Main:RegEvent(Flag, 'UNIT_SPELLCAST_SUCCEEDED',    GUB.SpellCasting, 'player')

  elseif EventType == 'setbonus' then
    local Flag = Action == 'register'

    -- register event for equipment set bonus tracking.
    Main:RegEvent(Flag, 'PLAYER_EQUIPMENT_CHANGED', GUB.PlayerEquipmentChanged)
  end
end

-------------------------------------------------------------------------------
-- InitializeColors
--
-- Copy blizzard's power colors and class colors into the Defaults profile.
-------------------------------------------------------------------------------
local function InitializeColors()
  local UnitBars = Defaults.profile

  -- Copy the power colors.
  for PCT, PowerType in pairs(PowerColorType) do
    local Color = PowerBarColor[PCT]
    local r, g, b = Color.r, Color.g, Color.b
    for BarType, UB in pairs(UnitBars) do
      if BarType == 'PlayerPower' or BarType == 'TargetPower' or
         BarType == 'FocusPower' or BarType == 'PetPower' or BarType == 'ManaPower' then
        local Bar = UB.Bar
        Bar.Color = Bar.Color or {}
        Bar.Color[PowerType] = {r = r, g = g, b = b, a = 1}
      end
    end
  end

  -- Copy the class colors.
  for Class, Color in pairs(RAID_CLASS_COLORS) do
    local r, g, b = Color.r, Color.g, Color.b
    for BarType, UB in pairs(UnitBars) do
      if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' then
        local Bar = UB.Bar
        Bar.Color = Bar.Color or {}
        Bar.Color[Class] = {r = r, g = g, b = b, a = 1}
      end
    end
  end
end

--*****************************************************************************
--
-- Unitbar utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- RegEvent
--
-- Registers an event to call a function.
--
-- Usage: RegEvent(Reg, Event, Fn, Units)
--        RegEvent(Reg, Frame, Event, Fn, Units)
--
-- Reg    If true then event gets registered otherwise unregistered.
--
-- If Units is specified then it uses RegisterUnitEvent instead.
-------------------------------------------------------------------------------
function GUB.Main:RegEvent(Reg, Value1, Value2, Value3, ...)
  local Frame = nil
  local Event = nil
  local Fn = nil

  if type(Value1) == 'string' then
    Frame = nil
    Event = Value1
    Fn = Value2
  else
    Frame = Value1
    Event = Value2
    Fn = Value3
  end

  -- Find if this event already has an event frame.
  -- Use frame if one was passed instead.
  local F = Frame or RegEventFrames[Event]
  if F == nil then

    -- Create a new event frame for this event
    F = CreateFrame('Frame')
    RegEventFrames[Event] = F
  end

  if Reg then
    if Frame and ... or Frame == nil then

      -- if units specified then use RegisterUnitEvent.
      if Frame then
        F:RegisterUnitEvent(Event, ...)
      else
        F:RegisterUnitEvent(Event, Value3, ...)
      end
    else
      F:RegisterEvent(Event)
    end
    F:SetScript('OnEvent', Fn)
  else
    F:UnregisterEvent(Event)
  end
end

-------------------------------------------------------------------------------
-- NumberToDigitGroups
--
-- Takes a number and returns it in groups of three. 999,999,999
--
-- Usage: String = NumberToDigitGroups(Value)
--
-- Value       Number to convert to a digit group.
--
-- String      String containing Value in digit groups.
-------------------------------------------------------------------------------
local function NumberToDigitGroups(Value)
  local Sign = ''
  if Value < 0 then
    Sign = '-'
    Value = abs(Value)
  end

  if Value >= 1000000000 then
    return format(BillionFormat, Sign, Value / 1000000000, (Value / 1000000) % 1000, (Value / 1000) % 1000, Value % 1000)
  elseif Value >= 1000000 then
    return format(MillionFormat, Sign, Value / 1000000, (Value / 1000) % 1000, Value % 1000)
  elseif Value >= 1000 then
    return format(ThousandFormat, Sign, Value / 1000, Value % 1000)
  else
    return format('%s', Value)
  end
end

-------------------------------------------------------------------------------
-- GetShortTextValue
--
-- Takes a number and returns it in a shorter format for formatted text.
--
-- Usage: Value2 = GetShortTextValue(Value)
--
-- Value       Number to convert for formatted text.
--
-- Value2      Formatted text made from Value.
-------------------------------------------------------------------------------
local function GetShortTextValue(Value)
  if Value < 1000 then
    return format('%s', Value)
  elseif Value < 1000000 then
    return format('%.fk', Value / 1000)
  else
    return format('%.1fm', Value / 1000000)
  end
end

-------------------------------------------------------------------------------
-- GetTextValue
--
-- Returns either CurrValue or MaxValue based on the ValueName and ValueType
--
-- Usage: Value = GetTextValue(ValueName, ValueType, CurrValue, MaxValue, PredictedValue)
--
-- ValueName        Must be 'current', 'maximum', or 'predicted'.
-- ValueType        The type of value, see texttype in main.lua for a list.
-- CurrValue        Values to be used.
-- MaxValue         Values to be used.
-- PredictedValue   Predicted health or power value.  If nil won't be used.
--
-- Value            The value returned based on the ValueName and ValueType.
--                  Can be a string or number.
-------------------------------------------------------------------------------
local function GetTextValue(ValueName, ValueType, CurrValue, MaxValue, PredictedValue)
  local Value = nil

  -- Get the value based on ValueName
  if ValueName == 'current' then
    Value = CurrValue
  elseif ValueName == 'maximum' then
    Value = MaxValue
  elseif ValueName == 'predicted' then
    Value = PredictedValue or 0
  end

  if ValueType == 'whole' then
    return Value
  elseif ValueType == 'whole_dgroups' then
    return NumberToDigitGroups(Value)
  elseif ValueType == 'percent' and Value > 0 then
    if MaxValue == 0 then
      return 0
    else
      return GetTextValuePercentFn(Value, MaxValue)
    end
  elseif ValueType == 'thousands' then
    return Value / 1000
  elseif ValueType == 'millions' then
    return Value / 1000000
  elseif ValueType == 'short' then
    return GetShortTextValue(Value)
  else
    return 0
  end
end

-------------------------------------------------------------------------------
-- SetTextValues
--
-- Sets one or more values on a fontstring based on the text type settings
--
-- Usage: returnOK, msg = SetTextValues(TextType, FontString, CurrValue, PercentFn, MaxValue, PredictedValue)
--
-- TextType         Contains the data from UB.Text.TextType
-- FontString       Contains the font string to display data on.
-- PercentFn        Function containing the percentage formula.  The function gets passed the min/max values.
--                  and must return the result.
-- CurrValue        Current value.  Used for percentage.
-- MaxValue         Maximum value.  Used for percentage.
-- PredictedValue   Predicted health or power value.  Set value to nil if you have no predicted value to set.
--
-- returnOK         If any errors happend then this flag will not be nill
-- msg              Error message returned.
-------------------------------------------------------------------------------

-- Use recursion to build a parameter list to pass back to setformat.
local function GetTextValues(ValueName, ValueType, CurrValue, MaxValue, PredictedValue, Position, ...)
  if Position > 0 then
    local Type = ValueType[Position]
    if Type ~= 'none' then
      return GetTextValues(ValueName, ValueType, CurrValue, MaxValue, PredictedValue, Position - 1,
                           GetTextValue(ValueName[Position], Type, CurrValue, MaxValue, PredictedValue), ...)
    else
      return GetTextValues(ValueName, ValueType, CurrValue, MaxValue, PredictedValue, Position - 1, ...)
    end
  else
    return ...
  end
end

local function SetTextValues2(TextType, FontString, CurrValue, MaxValue, PredictedValue)
  local MaxValues = TextType.MaxValues

  if MaxValues > 0 then
    FontString:SetFormattedText(TextType.Layout,
      GetTextValues(TextType.ValueName, TextType.ValueType, CurrValue, MaxValue, PredictedValue, MaxValues))
  else
    FontString:SetText('')
  end
end

function GUB.Main:SetTextValues(TextType, FontString, PercentFn, CurrValue, MaxValue, PredictedValue)
  GetTextValuePercentFn = PercentFn
  return pcall(SetTextValues2, TextType, FontString, CurrValue, MaxValue, PredictedValue)
end

-------------------------------------------------------------------------------
-- CheckTalent
--
-- Checks to see if the talent is chosen or not.
--
-- Usage: Status = CheckTalent(Index)
--
-- Unit   player, target, pet, focus, etc
-- Index  Talent index from 1 to 18.  Talents are index from left to right then down one.
--
-- Status   If true then the talent is chosen, otherwise false.
-------------------------------------------------------------------------------
function GUB.Main:CheckTalent(Index)
  local _, _, _, _, Active, _ = GetTalentInfo(Index, nil, nil)
  return Active
end

-------------------------------------------------------------------------------
-- SetTooltip
--
-- Adds a tooltip to an object to be used with ShowTooltip
--
-- Usage: SetTooltip(Object, Name, Description)
--
-- Object        Object to add a tooltip too.
-- Name          Appears a yellow at the top of the tooltip.
--               If nil then gets ignored.
-- Description   Description to appear in the tooltip.
--               If nil then gets ignored.
--
-- Note: Too add more lines just call this function again.
-------------------------------------------------------------------------------
function GUB.Main:SetTooltip(Object, Name, Description)
  if Description then
    local TooltipDesc = Object.TooltipDesc
    if TooltipDesc == nil then
      TooltipDesc = {}
      Object.TooltipDesc = TooltipDesc
    end
    TooltipDesc[#TooltipDesc + 1] = Description
  end
  if Name then
    Object.TooltipName = Name
  end
end

-------------------------------------------------------------------------------
-- ShowTooltip
--
-- Usage: ShowTooltip(Object, Show)
--
-- Object    Object that contains the tooltip
-- Show      True or false.  If true then the tooltip is shown otherwise hidden.
--
-- The self.TooltipDesc is a variable array can contain 1 or more indexes.
-------------------------------------------------------------------------------
function GUB.Main:ShowTooltip(Object, Show)
  local TooltipName = Object.TooltipName
  local TooltipDesc = Object.TooltipDesc
  if TooltipDesc or TooltipName then
    if Show then
      GameTooltip:SetOwner(Object, 'ANCHOR_TOPRIGHT')
      if TooltipName then
        GameTooltip:AddLine(TooltipName)
      end
      if not UnitBars.HideTooltipsDesc or Object.WoWUI then
        if TooltipDesc then
          for _, Desc in ipairs(TooltipDesc) do
            GameTooltip:AddLine(Desc, 1, 1, 1)
          end
        end
        if UnitBars.AlignmentToolEnabled and Object.WoWUI == nil then
          GameTooltip:AddLine(AlignmentTooltipDesc, 1, 1, 1)
        end
      end
      GameTooltip:Show()
    else
      GameTooltip:Hide()
    end
  end
end

-------------------------------------------------------------------------------
-- GetHighestFrameLevel
--
-- Returns the highest frame level in all of the frames children.
--
-- Usage: FrameLevel = GetHighestFrameLevel(IgnoreFrame, Frame)
--
-- IgnoreFrame      It will skip this frame if it finds it in the children.
-- Frame            Frame to start searching its children for the highest level.
-- FrameLevel       Highest frame level found in the child frames.
-------------------------------------------------------------------------------
local function GetHighestFrameLevel(IgnoreFrame, ...)

  local function GetHighestLevel(FrameLevel, ...)
    local Found = false

    -- Search the one or more frames.
    for i = 1, select('#', ...) do
      local Frame = select(i, ...)

      -- skip the ignored frame,
      if Frame ~= IgnoreFrame then
        Found = true

        -- recursive call to search more children if they exist.
        local FL = GetHighestLevel(FrameLevel, Frame:GetChildren())
        if FL == nil then

          -- no children found so get the frame level of this frame.
          FL = Frame:GetFrameLevel()
        end
        if FL > FrameLevel then
          FrameLevel = FL
        end
      end
    end

    -- return framelevel if a frame was searched or nil
    return Found and FrameLevel or nil
  end

  return GetHighestLevel(0, ...)
end

-------------------------------------------------------------------------------
-- SelectUnitBar
--
-- Selects or deselects a unitbar.
--
-- Usage: SelectUnitBar(UnitBarF, Action, r, g, b)
--
-- UnitBarF      Unitbar being selected.
-- Action        'set' to select or 'clear' to unselect.  RGB is ignored when using 'clear'
-- r, g, b       Color of the selected unitbar.
-------------------------------------------------------------------------------
local function SelectUnitBar(UnitBarF, Action, r, g, b)
  local SelectFrame = UnitBarF.SelectFrame

  -- Set the border color and show it.
  if Action == 'set' then

    -- Set selectframe to the top level
    SelectFrame:SetFrameLevel(GetHighestFrameLevel(SelectFrame, UnitBarF.Anchor) + 1)
    SelectFrame:SetBackdropBorderColor(r, g, b, 1)
    UnitBarF.Selected = true

    -- If color setting doesn't exist then create one.
    if UnitBarF.SelectColor == nil then
      UnitBarF.SelectColor = {r = r, g = g, b = b}
    else

      -- Use existing color setting.
      local Color = UnitBarF.SelectColor
      Color.r, Color.g, Color.b = r, g, b
    end

  -- Hide the border by setting its alpha to zero.
  elseif Action == 'clear' then
    SelectFrame:SetBackdropBorderColor(1, 1, 1, 0)
    UnitBarF.Selected = false
  end
end

-------------------------------------------------------------------------------
-- EnableSelectMode
--
-- Enable or disable select mode.
--
-- Usage: EnableSelectMode(true or false)
-------------------------------------------------------------------------------
function GUB.Main:EnableSelectMode(Action)
  for _, UBF in ipairs(UnitBarsFI) do
    if Action then
      UBF.SelectFrame:Show()
    else
      UBF.SelectFrame:Hide()
    end
  end
  SelectMode = Action

  -- Set PSelectedUnitBarF to nil if SelectMode was turned off.
  if not SelectMode then
    PSelectedUnitBarF = nil
  end
end

-------------------------------------------------------------------------------
-- SetUnitBarSize
--
-- Subfunction of UnitBarsF:SetSize
--
-- Sets the width and height for a unitbar.
--
-- Usage: SetUnitBarSize(UnitBarF, Width2, Height2, OffsetX, OffsetT)
--
-- UnitBarF    UnitBar to set the size for.
-- Width2      Set width of the unitbar. if Width is nil then current width is used.
-- Height2     Set height of the unitbar.
-- OffsetX     Move the unitbar from the current position by OffsetX.
-- OffsetY     Move the unitbar from the current position by OffsetY
--
-- NOTE:  This accounts for scale.  Width and Height must be unscaled when passed.
-------------------------------------------------------------------------------
local function SetUnitBarSize(self, Width2, Height2, OffsetX, OffsetY)

  -- Get Unitbar data and anchor
  local UB = self.UnitBar
  local Anchor = self.Anchor
  local Scale = UB.Other.Scale

  -- Get width and height
  local Width = nil
  local Height = nil

  -- If width then scale it.
  if Width2 then
    Width = Width2
    Height = Height2
  else

    -- If not width specified then use the current scale width and height
    Width = self.ScaleWidth
    Height = self.ScaleHeight
  end

  -- Offset the Anchor and setsize.
  if OffsetX ~= nil then
    local x, y = UB.x + OffsetX * Scale, UB.y + OffsetY * Scale
    Anchor:SetPoint('TOPLEFT' , x, y)
    UB.x, UB.y = x, y
  end

  if Width ~= nil and Height ~= nil then

    -- Set scale width and height.
    local ScaleWidth = Width
    local ScaleHeight = Height

    -- Unscale width and height
    Width = Width * Scale
    Height = Height * Scale

    -- save width and heiht
    self.ScaleWidth = ScaleWidth
    self.ScaleHeight = ScaleHeight
    self.Width = Width
    self.Height = Height

    Anchor:SetWidth(Width)
    Anchor:SetHeight(Height)
  end
end

-------------------------------------------------------------------------------
-- AlignUnitBars
--
-- Align unitbars by horizontal/vertical.
--
-- Usage: AlignUnitBars(Alignment, Justify, PaddingEnabled, Padding)
--
-- Alignment        'vertical', 'horizontal'
-- Justify          1 = left or 2 = right for vertical.
--                  1 = top  or 2 = bottom for horizontal.
-- PaddingEnabled   true or false. If true then the bars will be spaced apart in pixels.
-- Padding          Amount of pixels to space bars apart.
--
-- NOTE:  Function will not do anything unless you have at one primary selected bar and
--        one or more selected bars.
-------------------------------------------------------------------------------
local function SortY(a, b)
  return a.UnitBar.y > b.UnitBar.y
end

local function SortX(a, b)
  return a.UnitBar.x < b.UnitBar.x
end

function GUB.Main:AlignUnitBars(Alignment, Justify, PaddingEnabled, Padding)
  local StartIndex = 0
  local DestIndex = 0
  local MaxUnitBars = 0
  local x = 0
  local y = 0
  local UB = nil
  local LastUB = nil
  local UnitBarF = nil
  local LastUnitBarF = nil

  -- Do nothing if no primary selected bar.
  if PSelectedUnitBarF == nil then
    return
  end

  -- sort UnitBarsF
  if Alignment == 'vertical' then
    sort(UnitBarsF, SortY)
  elseif Alignment == 'horizontal' then
    sort(UnitBarsF, SortX)
  end

  -- Find the primary selected unitbar.
  for Index, UBF in ipairs(UnitBarsFI) do
    MaxUnitBars = MaxUnitBars + 1
    if UBF == PSelectedUnitBarF then
      StartIndex = Index
    end
  end

  for Direction = -1, 1, 2 do

    -- Set destination index.
    DestIndex = Direction == -1 and 1 or MaxUnitBars

    -- Set the starting x, y location.
    LastUB = PSelectedUnitBarF.UnitBar
    LastUnitBarF = PSelectedUnitBarF

    -- loop from the center outward.
    for AlignmentIndex = StartIndex + Direction, DestIndex, Direction do
      UnitBarF = UnitBarsFI[AlignmentIndex]

      -- Only check selected bars.
      if UnitBarF.Selected then
        UB = UnitBarF.UnitBar
        x, y = UB.x, UB.y
        if Alignment == 'vertical' then
          if PaddingEnabled then
            if Direction == -1 then
              y = LastUB.y + Padding + UnitBarF.Height
            else
              y = LastUB.y - LastUnitBarF.Height - Padding
            end
          end

          -- Handle left/right justification.
          if Justify == 1 then
            x = LastUB.x
          else
            x = LastUB.x + (LastUnitBarF.Width - UnitBarF.Width)
          end
        else
          if PaddingEnabled then
            if Direction == -1 then
              x = LastUB.x - Padding - UnitBarF.Width
            else
              x = LastUB.x + LastUnitBarF.Width + Padding
            end
          end

          -- Handle top/bottom justification
          if Justify == 1 then
            y = LastUB.y
          else
            y = LastUB.y - (LastUnitBarF.Height - UnitBarF.Height)
          end
        end
        UnitBarF.Anchor:SetPoint('TOPLEFT', x, y)
        UB.x, UB.y = x, y
        LastUB = UB
        LastUnitBarF = UnitBarF
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetTimer
--
-- Will call a function based on a delay.
--
-- To start a timer
--   usage: SetTimer(Table, Delay, TimerFn)
-- To stop a timer
--   usage: SetTimer(Table, nil)
--
-- Table    Must be a table.
-- Delay    Amount of time to delay after each call to Fn()
-- TimerFn  Function to be added. If nil then the timer will be stopped.
--
-- NOTE:  TimerFn will be called as TimerFn(Frame, Elapsed) from AnimationGroup in StartTimer()
--        See CheckPredictedSpellsTimeout() on how this is used.
--
--        To reduce garbage.  Only a new StartTimer() will get created when a new table is passed.
--
--        I decided to do it this way because the overhead of using indexed
--        arrays for multiple timers ended up using more cpu.
---------------------------------------------------------------------------------
function GUB.Main:SetTimer(Table, Delay, TimerFn)
  local AnimationGroup = nil
  local Animation = nil

  Table.SetTimer = Table.SetTimer or function(Start, Delay, TimerFn2)

    -- Create an animation Group timer if one doesn't exist.
    if AnimationGroup == nil then
      AnimationGroup = CreateFrame('Frame'):CreateAnimationGroup()
      Animation = AnimationGroup:CreateAnimation('Animation')
      Animation:SetOrder(1)
      AnimationGroup:SetLooping('REPEAT')
      AnimationGroup:SetScript('OnLoop' , function(self) TimerFn(Table, self:GetDuration()) end )
    end
    if Start then
      TimerFn = TimerFn2
      Animation:SetDuration(Delay)
      AnimationGroup:Play()
    else
      AnimationGroup:Stop()
    end
  end

  if TimerFn then

    -- Start timer since a function was passed
    Table.SetTimer(true, Delay, TimerFn)
  else

    -- Stop timer since no function was passed.
    Table.SetTimer(false)
  end
end

------------------------------------------------------------------------------
-- CheckSetBonus
--
-- Checks to see if a set bonus is active, if any have been set
-------------------------------------------------------------------------------
local function CheckSetBonus()
  local Tier = 0
  local SetBonus = 0
  local NewSetBonus = 0
  local ESItemID = nil

  -- Reset set bonus counter
  for Tier, _ in pairs(EquipmentSetBonus) do
    EquipmentSetBonus[Tier] = 0
  end

  -- Count each tier piece.
  for Slot, ES in pairs(EquipmentSet) do
    Tier = ES[GetInventoryItemID('player', strsub(Slot, 2))]
    if Tier then
      SetBonus = EquipmentSetBonus[Tier]
      if SetBonus then
        SetBonus = SetBonus + 1
      else
        SetBonus = 1
      end
      EquipmentSetBonus[Tier] = SetBonus
    end
  end

  -- Clip Set bonus.
  for Tier, SetBonus in pairs(EquipmentSetBonus) do
    if SetBonus >= 4 then
      NewSetBonus = 4
    elseif SetBonus >= 2 then
      NewSetBonus = 2
    else
      NewSetBonus = 0
    end
    EquipmentSetBonus[Tier] = NewSetBonus
  end
end

-------------------------------------------------------------------------------
-- GetSetBonus
--
-- Returns set bonus info.
--
-- Usage: SetBonus = GetSetBonus(Tier)
--
-- Tie        Tier number of gear 11, 12 etc.
--
-- SetBonus   Set bonus 2 or 4, 0 if no bonus is detected.
-------------------------------------------------------------------------------
function GUB.Main:GetSetBonus(Tier)

  -- Register event and do an equipmentset check if event hasn't been registered.
  if not EquipmentSetRegisterEvent then
    CheckSetBonus()
    RegisterEvents('register', 'setbonus')
    EquipmentSetRegisterEvent = true
  end

  local SetBonus = EquipmentSetBonus[Tier]
  if SetBonus then
    return SetBonus
  else
    return 0
  end
end

-------------------------------------------------------------------------------
-- CheckAura
--
-- Checks to see if one or more auras are active
--
-- Usage: Found, [TimeLeft] = CheckAura(Condition, ...)
--
-- Condition    'a' for 'and' or 'o' for 'or'.  If 'a' is specified then all
--              auras have to be active.  If 'o' then only one of the auras needs
--              to be active.
-- ...          One or more auras specified as a SpellID.
--
-- Found        Returns true if condition 'a' is used and all auras were found.
--              Returns the SpellID of the aura found if condition 'o' is used.
-- TimeLeft     If 'o' was used then the amount of time the buff has left is
--              returned along for the SpellID.  See EclipseBar.lua how this is done.
-------------------------------------------------------------------------------
function GUB.Main:CheckAura(Condition, ...)
  local Name = nil
  local SpellID = 0
  local MaxSpellID = select('#', ...)
  local Found = 0
  local i = 1
  repeat
    local Name, _, _, _, _, _, ExpiresIn, _, _, _, SpellID = UnitBuff('player', i)
    if Name then
      for i = 1, MaxSpellID do
        if SpellID == select(i, ...) then
          Found = Found + 1
          break
        end
      end
      if Condition == 'o' and Found > 0 then
        return SpellID, ExpiresIn - GetTime()
      end
    end
    i = i + 1
  until Name == nil or Found == MaxSpellID
  return Found == MaxSpellID
end

-------------------------------------------------------------------------------
-- CheckPredictedSpellsTimeout
--
-- Timer that watches to timeout the current casting spell.
-------------------------------------------------------------------------------
local function CheckPredictedSpellsTimeout(self, Elapsed)

  -- Check for predicted spell time out.
  if PredictedSpellsTime > 0 then
    PredictedSpellsTime = PredictedSpellsTime - Elapsed
  else
    local SpellID = PredictedSpellCasting.SpellID
    local CastTime = PredictedSpellCasting.CastTime
    local Fn = PredictedSpellCasting.Fn

    self.ModifyCastingSpell('remove')

    if Fn then
      Fn(SpellID, CastTime, 'timeout')
    end
  end
end

-------------------------------------------------------------------------------
-- ModifyCastingSpell
--
-- Adds or Remove a spell that is casting.
--
-- usage ModifyCastingSpell(Action, SpellID, LineID, CastTime, Fn)
--
-- Action   'remove' or 'add'
--            'add'    will add the current spell to casting.
--            'remove' will remove the current casting spell.
--
-- SpellID     The spell to add.
-- LineID      LineID to add.
-- CastTime    Amount of time it takes to cast the spell.
-- Fn          Function to call when timeout happens.
-------------------------------------------------------------------------------
local function ModifyCastingSpell(Action, SpellID, LineID, CastTime, Fn)

  -- Stop the timeout checker.
  Main:SetTimer(PredictedSpellsTimer, nil)

  if Action == 'add' then
    PredictedSpellCasting.SpellID = SpellID
    PredictedSpellCasting.LineID = LineID
    PredictedSpellCasting.CastTime = CastTime
    PredictedSpellCasting.Fn = Fn

    -- Set timeout
    PredictedSpellsTime = PredictedSpellsTimeout - 1 -- Takes one second for timer to start ticking.

    -- Start the timeout checker.
    Main:SetTimer(PredictedSpellsTimer, 1, CheckPredictedSpellsTimeout)

  elseif Action == 'remove' then
    PredictedSpellCasting.SpellID = 0
    PredictedSpellCasting.LineID = -1
    PredictedSpellCasting.CastTime = 0
    PredictedSpellCasting.Fn = nil
  end
end

------------------------------------------------------------------------------
-- GetPredictedSpell
--
-- Returns a predicted powerID.
--
-- usage: SpellID = GetPredictedSpell()
--
-- SpellID      Returns the spell ID or 0 for no spell.
-------------------------------------------------------------------------------
function GUB.Main:GetPredictedSpell()
  return PredictedSpellCasting.SpellID
end

-------------------------------------------------------------------------------
-- SetPredictedSpellsActive
--
-- Turns predicted spells on or off.
--
-- Usage: SetPredictedSpellsActive(BarType, Action)
--
-- BarType   If BarType matches with what was set in SetPredictedSpells() then
--           Action won't be ignored.
-- Action    True or False.  If true then predictedspells if turned on otherwise off.
-------------------------------------------------------------------------------
local function SetPredictedSpellsActive(BarType, Action)
  if BarType == PredictedSpellsBarType then
    if Action then
      RegisterEvents('register' , 'predictedspells')
    else
      RegisterEvents('unregister' , 'predictedspells')

      -- Remove any casting spell left over.
      ModifyCastingSpell('remove')
    end
  end
end

-------------------------------------------------------------------------------
-- SetPredictedSpells
--
-- Adds a spellID to the list for predicted spells.
-- Can also turn off or on predicted spells.
--
-- Usage: SetPredictedSpells(SpellID, EndOn, Fn)
--        SetPredictedSpells(true or false, BarType)
--
-- SpellID       ID of the spell to track.
-- EndOn         Tells how the spell will end.
--               'casting' means the spell will be cleared when the spell was stopped, cancled, succedded, etc.
--               'energize' means the spell will end on energize event.
-- Fn            See SetPredictedSpell() and Eclipse.lua on how Fn() is used.
--
-- BarType       Type of bar the spells will be used with.  This is needed for hiding/showing by HideUnitBar()
-- true          Turn on predicted power.
-- false         Turn off predicted power.
--
-- NOTE:   When using endon 'energize' you must add the energize spellID as well otherwise
--         the predictedspell system will not see the energize event.  See EclipseBar.lua how this is set up.
-------------------------------------------------------------------------------
function GUB.Main:SetPredictedSpells(SpellID, EndOn, Fn)
  if type(SpellID) ~= 'boolean' then
    local PS = {EndOn = EndOn, Fn = Fn}
    PredictedSpells[SpellID] = PS
  else
    if PredictedSpellsTimer == nil then
      PredictedSpellsTimer = CreateFrame('Frame')
      PredictedSpellsTimer.ModifyCastingSpell = ModifyCastingSpell
    end
    PredictedSpellsBarType = EndOn
    PredictedSpellsActive = SpellID
    SetPredictedSpellsActive(PredictedSpellsBarType, PredictedSpellsActive)
  end
end

-------------------------------------------------------------------------------
-- CalcSetPoint
--
-- Returns where a child sub frame point would be set on another frame.
--
-- Usage x, y = CalcSetPoint(Point, Width, Height, OffsetX, OffsetY)
--
-- Point      One of the 9 different points. 'TOP', 'LEFT', etc.
-- Width      Width of the frame.
-- Height     Height of the frame.
-- OffsetX    Screen position X offset from Point.
-- OffsetY    Screen position Y offset from point.
--
-- x, y       New screen location within the frame.
-------------------------------------------------------------------------------
function GUB.Main:CalcSetPoint(Point, Width, Height, OffsetX, OffSetY)
  return Width * PointCalc[Point].x + OffsetX, -(Height * PointCalc[Point].y + -OffSetY)
end

-------------------------------------------------------------------------------
-- GetBorder
--
-- Returns the four values to create a frame that can surround sub frames.
--
-- Usage: x, y, Width, Height = GetBorder(x1, y1, Width1, Height1, ...)
--
-- x1, y1      Top left location of a frame.
-- Width1      Width of the frame
-- Height      Height of the frame
-- ...         One or more (x1, y1, Width1, Height1) groups
--
-- x, y        Location based on the left (x1) and top most (y1) values passed.
-- Width       Based on the distance from x1 to x1 + Width1.  Returns the largest.
-- Height      Based on the distance from y1 to y1 + Height1.  Returns the largest.
-------------------------------------------------------------------------------
function GUB.Main:GetBorder(...)
  local Left = 0
  local Top = 0
  local Right = 0
  local Bottom = 0

  for i = 1, select('#', ...), 4 do
    local Left2 = select(i, ...)
    local Top2 = select(i + 1, ...)
    local Right2 = select(i + 2, ...)
    local Bottom2 = select(i + 3, ...)

    -- Convert Right and Bottom into screen coordinates.
    Right2 = Left2 + Right2
    Bottom2 = Top2 - Bottom2

    -- If this is the first set, set the values.
    if i == 1 then
      Left, Top, Right, Bottom = Left2, Top2, Right2, Bottom2
    else

      -- Get the left and top most values.
      Left = Left2 < Left and Left2 or Left
      Top = Top2 > Top and Top2 or Top

      -- Get the right and bottom most values.
      Right = Right2 > Right and Right2 or Right
      Bottom = Bottom2 < Bottom and Bottom2 or Bottom
    end
  end
  return Left, Top, Right - Left, Top - Bottom
end

-------------------------------------------------------------------------------
-- SetCooldownBarEdgeFrame
--
-- Creates a frame that gets placed on the edge of the bar.
--
-- Usage: SetCooldownBarEdgeFrame(StatusBar, EdgeFrame, Width, Height)
--
-- StatusBar     Statusbar containing the cooldownbar timer.
-- EdgeFrame     Frame containing objects to be displayed.
-- FillDirection 'HORIZONTAL' left to right, 'VERTICAL' bottom to top.
-- Width         Width set to EdgeFrame
-- Height        Height set to EdgeFrame
--
-- If EdgeFrame is nil then no EdgeFrame will be shown or the existing EdgeFrame
-- will be removed.
-------------------------------------------------------------------------------
function GUB.Main:SetCooldownBarEdgeFrame(StatusBar, EdgeFrame, FillDirection, Width, Height)
  if EdgeFrame then
    EdgeFrame:Hide()

    -- Set the width and height.
    EdgeFrame:SetWidth(Width)
    EdgeFrame:SetHeight(Height)

    StatusBar.EdgeFrame = EdgeFrame
    StatusBar.FillDirection = FillDirection
  else

    -- Hide the old edgeframe
    EdgeFrame = StatusBar.EdgeFrame
    if EdgeFrame then
      EdgeFrame:Hide()
    end
    StatusBar.EdgeFrame = nil
  end

  StatusBar.ShowEdgeFrame = false
end

-------------------------------------------------------------------------------
-- CooldownBarSetTimer
--
-- Creates a bar timer using an existing statusbar.
--
-- Usage: CooldownBarSetTimer(StatusBar, StartTime, Duration, Enable)
--
-- StatusBar     StatusBar you want to use for the cooldown bar.
-- StartTime     Starting time in seconds that you want the timer to start at.
-- Duration      Time in seconds you want the bar to keep track of once StartTime has Been reached.
--               If Duration is 0 then no timer is started.
-- Enable        if set to 1 the timer will be set to start at StartTime.
--               if set to 0 the existing timer will be stopped
-------------------------------------------------------------------------------
function GUB.Main:CooldownBarSetTimer(StatusBar, StartTime, Duration, Enable)
  local LastX = nil
  local LastY = nil

  StatusBar.CooldownBarSetTimer = StatusBar.CooldownBarSetTimer or function(self)
    local CurrentTime = GetTime()

    -- Check to see if the start time has been reached
    if CurrentTime >= StartTime then
      local TimeElapsed = CurrentTime - StartTime

       -- Check to see if we're less than duration
      if TimeElapsed <= Duration then
        local EdgeFrame = self.EdgeFrame
        self:SetMinMaxValues(0, Duration)
        self:SetValue(TimeElapsed)
        self:Show()

        -- Position and show the edgeframe if one is present.
        if EdgeFrame then
          if self.FillDirection == 'HORIZONTAL' then
            local x = TimeElapsed / Duration * self:GetWidth()
            if x ~= LastX then
              EdgeFrame:SetPoint('CENTER', self, 'LEFT', x, 0)
              LastX = x
            end
          else
            local y = TimeElapsed / Duration * self:GetHeight()
            if y ~= LastY then
              EdgeFrame:SetPoint('CENTER', self, 'BOTTOM', 0, y)
              LastY = y
            end
          end
          EdgeFrame:Show()
        end

      else
        if self.EdgeFrame then

          -- Hide the edgeframe.
          self.EdgeFrame:Hide()
        end

        -- stop the timer.
        self.Start = false
        self:SetValue(0)
        Main:SetTimer(self, nil)
      end
    end
  end

  StatusBar.CooldownBarSetTimer2 = StatusBar.CooldownBarSetTimer2 or function(StartTime2, Duration2)
    StartTime = StartTime2
    Duration = Duration2
  end

  if Enable == 1 then

    -- Check to see if the timer is not already running and only start a timer if duration > 0.
    if Duration > 0 and (StatusBar.Start == nil or not StatusBar.Start) then
      StatusBar.Start = true
      StatusBar.Delay = -1

      StatusBar.CooldownBarSetTimer2(StartTime, Duration)
      Main:SetTimer(StatusBar, CooldownBarTimerDelay, StatusBar.CooldownBarSetTimer)
    end
  else
    local EdgeFrame = StatusBar.EdgeFrame
    if EdgeFrame then

      -- Hide the edgeframe.
      EdgeFrame:Hide()
    end

    -- stop the timer.
    StatusBar:SetValue(0)
    StatusBar.Start = false
    Main:SetTimer(StatusBar, nil)
  end
end

-------------------------------------------------------------------------------
-- DeepCopy
--
-- Copies a table and any subtables
--
-- Usage: CopiedTable = DeepCopy(OldTable)
--
-- CopiedTable      Copy of OldTable.
-- OldTable         Table to be copied.
-------------------------------------------------------------------------------
function GUB.Main:DeepCopy(t)
  if type(t) ~= 'table' then
    return t
  end
  local MT = getmetatable(t)
  local NewTable = {}
  for k, v in pairs(t) do
    if type(v) == 'table' then
      v = Main:DeepCopy(v)
    end
    NewTable[k] = v
  end
  setmetatable(NewTable, MT)
  return NewTable
end

-------------------------------------------------------------------------------
-- CopyTableValues
--
-- Copies all the values and sub table values of one table to another.
--
-- Usage: CopyTableValues(Source, Dest)
--
-- Source    The source table you're copying data from.
-- Dest      The destination table the data is being copied to.
--
-- NOTE: The source and dest tables must have the same keys.
-------------------------------------------------------------------------------
function GUB.Main:CopyTableValues(Source, Dest)
  for k, v in pairs(Source) do
    if type(v) == 'table' then

      -- Make sure value is not nil.
      if Dest[k] ~= nil then
        Main:CopyTableValues(v, Dest[k])
      end

    -- Check to see if key exists in destination before setting value
    elseif Dest[k] ~= nil then
      Dest[k] = v
    end
  end
end

-------------------------------------------------------------------------------
-- AngleToOffset
--
-- Passes back an x y offset based on angle.
--
-- Usage XO, YO = AngleToOffset(XOffset, YOffset, Angle)
--
-- XOffset      The offset value for X.
-- YOffset      The offset Value for Y.
-- Angle        Must be 45 90 135 180 225 270 315 or 360
--
-- XO           Negative or positive value of XOffset depending on angle.
-- YO           Negative or positive value of YOffset depending on angle.
-------------------------------------------------------------------------------
function GUB.Main:AngleToOffset(XO, YO, Angle)
  local XOffset = 0
  local YOffset = 0

  -- Set the offsets.
  if Angle == 90 or Angle == 270 then
    XOffset = XO
  elseif Angle == 180 or Angle == 360 then
    YOffset = YO
  elseif Angle == 45 or Angle == 135 or Angle == 225 or Angle == 315 then
    XOffset = XO
    YOffset = YO
  end

  -- Calculate the direction.
  local Angle = mrad(Angle)
  if msin(Angle) < 0 then
    XOffset = -XOffset
  end
  if mcos(Angle) < 0 then
    YOffset = -YOffset
  end
  return XOffset, YOffset
end

-------------------------------------------------------------------------------
-- ConvertBackdrop
--
-- Converts BackdropSettings that can be used in SetBackdrop()
--
-- Usage: Backdrop = GUB.Main:ConvertBackdrop(Bd)
--
-- Bd               Usually from saved unitbar data that has shared media
--                  strings for textures.
-- Backdrop         A table that is usable by blizzard. This table always
--                  references the local table in main.lua
-------------------------------------------------------------------------------
function GUB.Main:ConvertBackdrop(Bd)
  Backdrop.bgFile   = LSM:Fetch('background', Bd.BgTexture)
  Backdrop.edgeFile = LSM:Fetch('border', Bd.BdTexture)
  Backdrop.tile = Bd.BgTile
  Backdrop.tileSize = Bd.BgTileSize
  Backdrop.edgeSize = Bd.BdSize
  local Insets = Backdrop.insets
  local Padding = Bd.Padding
  Insets.left = Padding.Left
  Insets.right = Padding.Right
  Insets.top = Padding.Top
  Insets.bottom = Padding.Bottom

  return Backdrop
end

-------------------------------------------------------------------------------
-- SetFontString
--
-- Set new settings to fontstring.
--
-- Usage: GUB.Main:SetFontString(FontString, FS)
--
-- FontString        Fontstring object.
-- FS                Reference to the FontSettings table.
-------------------------------------------------------------------------------
function GUB.Main:SetFontString(FontString, FS)
  FontString:SetFont(LSM:Fetch('font', FS.FontType), FS.FontSize, FS.FontStyle)
  FontString:ClearAllPoints()
  FontString:SetPoint('CENTER', FontString:GetParent(), FS.Position, FS.OffsetX, FS.OffsetY)
  FontString:SetWidth(FS.Width)
  FontString:SetJustifyH(FS.FontHAlign)
  FontString:SetJustifyV('CENTER')
  FontString:SetShadowOffset(FS.ShadowOffset, -FS.ShadowOffset)
end

-------------------------------------------------------------------------------
-- RestoreRelativePoints
--
-- Restores lost relative points that are relative to its parent and returns
-- back the restored points.
--
-- Usage: x, y = RestoreRelativePoints(Frame)
--
-- Frame   The frame you want to restore relative points.
-------------------------------------------------------------------------------
function GUB.Main:RestoreRelativePoints(Frame)
  local Parent = Frame:GetParent()
  local Scale = Frame:GetScale()
  local PScale = Parent:GetScale()

  -- Get the left and top location of the current frame and scale it.
  local Left = Frame:GetLeft() * Scale
  local Top = Frame:GetTop() * Scale

  -- Get the left and top of the parent frame and scale it.
  local LeftP = Parent:GetLeft() * PScale
  local TopP = Parent:GetTop() * PScale

  -- Calculate the X, Y location relative to the parent frame.
  local x = (Left - LeftP) / Scale
  local y = (Top - TopP) / Scale

  -- Set the frame location relative to the parent frame.
  Frame:ClearAllPoints()
  Frame:SetPoint('TOPLEFT', x, y)

  return x, y
end

-------------------------------------------------------------------------------
-- CreateFade
--
-- Creates a fadeout or fadein animation group
--
-- Usage Fade, FadeA = CreateFade(Frame, Action)
--
-- Frame       Frame that the fadeout is being created for.
-- Action      If 'out' then fading out, if 'in then fading in.
--
-- Fade        The fade animation group.
-- FadeA       The fade animation.
-------------------------------------------------------------------------------
function GUB.Main:CreateFade(Frame, Action)

  -- Create an animation for fade out.
  local FadeOut = Frame:CreateAnimationGroup()
  local FadeOutA = FadeOut:CreateAnimation('Alpha')

  -- Set the animation group values.
  FadeOut:SetLooping('NONE')
  FadeOutA:SetChange(Action == 'out' and -1 or Action == 'in' and 1)
  FadeOutA:SetOrder(1)

  return FadeOut, FadeOutA
end

-------------------------------------------------------------------------------
-- Animation
--
-- Stops or plays an animation.
--
-- Usage: Animation(AG, Action, Fn)
--
-- AG        Animation Group to start or finish.
-- Action    'play'  Starts a new animation group then calls Fn when the
--                    animation is done.  Gets ignored if an existing animation is playing.
--           'stop' Stops the animation.
-- Fn        Function to call when used with 'play'.  If set to nil then its ignored.
-------------------------------------------------------------------------------
function GUB.Main:Animation(AG, Action, Fn)

  -- Stop animation if its playing
  if AG:IsPlaying() then
    if Action == 'stop' then

      -- Disable the animation script.
      AG:SetScript('OnFinished', nil)
      AG:Stop()
    end
    return
  end
  if Action == 'play' then
    AG:SetScript('OnFinished', function(self)

                                 -- Call the function Fn when finished.
                                 if Fn then
                                   Fn()
                                 end
                                 self:SetScript('OnFinished', nil)
                               end )

    AG:Play()
  end
end

-------------------------------------------------------------------------------
-- HideUnitBar
--
-- Usage: HideUnitBar(UnitBarF, HideBar)
--
-- UnitBarF       Unitbar frame to hide or show.
-- HideBar        Hide the bar if equal to true otherwise show.
--
-- NOTE:  Hiding a selected unitbar will deselect it.
-------------------------------------------------------------------------------
local function HideUnitBar(UnitBarF, HideBar)
  local FadeOut = UnitBarF.FadeOut
  local Anchor = UnitBarF.Anchor

  if HideBar and not UnitBarF.Hidden then

    -- Disable PredictedSpells if active.
    if PredictedSpellsActive then
      SetPredictedSpellsActive(UnitBarF.BarType, false)
    end

    -- Deselect a unitbar if selected.
    if UnitBarF == PSelectedUnitBarF then
      PSelectedUnitBarF = nil
    end
    SelectUnitBar(UnitBarF, 'clear')

    -- Cancel any animations playing inside this bar.
    UnitBarF:CancelAnimation()

    if UnitBars.FadeOutTime > 0 then

      -- Start the animation fadeout.
      Main:Animation(FadeOut, 'play', function() Anchor:Hide() end)
    else
      Anchor:Hide()
    end
    UnitBarF.Hidden = true

  elseif not HideBar and UnitBarF.Hidden then

    -- Enable PredictedSpells if active.
    if PredictedSpellsActive then
      SetPredictedSpellsActive(UnitBarF.BarType, true)
    end

    if UnitBars.FadeOutTime > 0 then

      -- Finish the animation fade out if its still playing.
      Main:Animation(FadeOut, 'stop')
    end
    Anchor:Show()
    UnitBarF.Hidden = false
  end
end

-------------------------------------------------------------------------------
-- StatusCheck    UnitBarsF function
--
-- Does a status check and updates the bar if it became visible.
--
-- Usage: StatusCheck()
-------------------------------------------------------------------------------
function GUB.Main:StatusCheck(Event)
  local UB = self.UnitBar
  local Status = UB.Status
  local Visible = true

  -- Check to see if the bar has a HideNotUsable flag.
  local HideNotUsable = Status.HideNotUsable or false
  if HideNotUsable then
    local Spec = UB.UsedByClass[PlayerClass]

    Visible = false
    -- Check if class found, then check spec.
    if Spec and PlayerSpecialization and (Spec == '' or strfind(Spec, PlayerSpecialization)) then
      Visible = true
    end
  end

  -- Show bars if not locked.
  if not UnitBars.IsLocked then

    -- use HideNotUsable visible flag if HideNotUsable is set.
    if not HideNotUsable then
      Visible = true
    end
  else

    -- Check to see if the bar has an enable function and call it.
    if Visible then
      local Fn = self.BarVisible
      if Fn then
        Visible = Fn()
      end
    end

    if Visible then

      -- Hide if the HideWhenDead status is set.
      if IsDead and Status.HideWhenDead then
        Visible = false

      -- Hide if in a vehicle if the HideInVehicle status is set
      elseif InVehicle and Status.HideInVehicle then
        Visible = false

      -- Hide if in a pet battle and the HideInPetBattle status is set.
      elseif InPetBattle and Status.HideInPetBattle then
        Visible = false

      -- Get the idle status based on HideNotActive when not in combat.
      elseif not InCombat and Status.HideNotActive then
        local IsActive = self.IsActive
        Visible = type(IsActive) == 'boolean' and IsActive

        -- if not visible then set IsActive to watch for activity.
        if not Visible then
          self.IsActive = 0
        end

      -- Hide if not in combat with the HideNoCombat status.
      elseif not InCombat and Status.HideNoCombat then
        Visible = false
      end
    end
  end

  -- Update the visible flag.
  self.Visible = Visible

  -- Hide/show the unitbar.
  HideUnitBar(self, not Visible)
end

--*****************************************************************************
--
-- Unitbar script functions (script/event)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UnitBarTooltip
--
-- Display a tooltip of a frame that has a name.
--
-- This function is called by setscript OnEnter and OnLeave
-------------------------------------------------------------------------------
function GUB.Main:UnitBarTooltip(Hide)
  if UnitBars.HideTooltips then
    return
  end
  Main:ShowTooltip(self, not Hide)
end

-------------------------------------------------------------------------------
-- SetPredictedSpell
--
-- Subfunction of CombatLogUnfiltered()
-- Subfunction of SpellCasting()
--
-- Sets the predicted spell based on events from CombatLogUnfiltered() and SpellCasting().
--
-- Usage: SetPredictedSpell(Event, SpellID, LineID, Message)
--
-- Event        Event from CombatlogUnfiltered() or SpellCasting().
-- SpellID      SpellID of the spell.
-- LineID       Only valid for start, success, an events.
-- Message      Message from combatlog.
--
-- NOTES:
--         Timeouts are used so only events SPELL_DAMAGE, SPELL_MISS, and SPELL_ENERGIZE needs to be tracked.
--         If one of those events didn't happen, then the timeout will remove the spell.
--
--         See the notes at the top of the file about Predicted Spells.
--
--         Fn() can get called 3 times.
--         Fn(SpellID, CastTime, Message)
--           Message = 'start'  Gets called on spell cast start.
--                        on 'start' you can return -1 to not add the spell to be tracked.
--                        see EclipseBar.lua on how this is done.
--                   = 'afterstart'  Gets called right after the spell starts casting.
--                   = 'end'    Gets called on spell success.
--                   = 'failed' Gets called if the spell didn't complete.
--                   = 'timeout' Gets called by CheckPredictedSpellsTimeout() if the spell timed out.
--           CastTime  The amount of time to cast the spell in seconds.
--           SpellID is always negative on 'start', 'end', 'afterstart', or 'failed'
--
--           If its energize then the message comes from the server.
-------------------------------------------------------------------------------
local function SetPredictedSpell(Event, TimeStamp, SpellID, LineID, Message)
  local PSE = PredictedSpellEvent[Event]

  if PSE ~= nil then
    local PS = PredictedSpells[SpellID]

    -- Check for valid spellID.
    if PS ~= nil then
      local Flight = PS.Flight
      local Fn = PS.Fn
      local CastTime = 0

      -- Detect start cast.
      if PSE == EventSpellStart then

        -- Get cast time for spell.
        local _, _, _, _, _, _, CastTime, _, _ = GetSpellInfo(SpellID)

        -- Turn CastTime info seconds.
        CastTime = CastTime / 1000

        -- Call Fn if Fn returns -1 then don't add the spell.
        if Fn then
          SpellID = Fn(-SpellID, CastTime, 'start')
        end
        if SpellID > -1 then

          -- Set casting spell.
          ModifyCastingSpell('add', SpellID, LineID, CastTime, Fn)
        end

        if Fn then
          Fn(-SpellID, CastTime, 'afterstart')
        end
      else
        CastTime = PredictedSpellCasting.CastTime
      end

      -- Remove casting spell or a failed casting spell.
      if PSE == EventSpellSucceeded and LineID == PredictedSpellCasting.LineID or
         PSE == EventSpellFailed and PredictedSpellMessage[Message] == nil then

        if PS.EndOn == 'casting' or PSE == EventSpellFailed then
          ModifyCastingSpell('remove')
        end

        -- Call Fn if one was set
        if Fn then
          if PSE == EventSpellFailed then
            Fn(-SpellID, CastTime, 'failed')
          else
            Fn(-SpellID, CastTime, 'end')
          end
        end
      end

      if PSE == EventSpellEnergize or PSE == EventSpellMissed then

        -- Remove casting spell if SpellID > 0
        if PS.EndOn == 'energize' or PSE == EventSpellMissed then
          ModifyCastingSpell('remove')
        end

        -- call Fn on energize.
        if PSE == EventSpellEnergize and Fn then
          Fn(SpellID, CastTime, Message)
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- PlayerEquipmentChanged (called by event)
--
-- Gets called when ever a player changes a piece of gear.
-- This function then calls CheckSetBonus()
-------------------------------------------------------------------------------
function GUB:PlayerEquipmentChanged()

  -- Update gear set bonus.
  CheckSetBonus()
end

-------------------------------------------------------------------------------
-- CombatLogUnfiltered (called by event)
--
-- Captures combat log events.
-------------------------------------------------------------------------------
function GUB:CombatLogUnfiltered(Event, TimeStamp, CombatEvent, HideCaster, SourceGUID, SourceName, SourceFlags, DestGUID, DestName, DestFlags, ...)

  -- Predicted spell for player only.
  if SourceGUID == PlayerGUID then

    -- Pass spellID and Message.
    SetPredictedSpell(CombatEvent, TimeStamp, select(3, ...), nil, select(6, ...))
  end
end

-------------------------------------------------------------------------------
-- SpellCasting (called by event)
--
-- Gets called when the player started or stopped casting a spell.
-------------------------------------------------------------------------------
function GUB:SpellCasting(Event, Unit, Name, Rank, LineID, SpellID)

  -- Predicted spell for player only.
  SetPredictedSpell(Event, nil, SpellID, LineID, '')
end

-------------------------------------------------------------------------------
-- UnitBarsUpdateStatus
--
-- Event handler that hides/shows the unitbars based on their current settings.
-- This also updates all unitbars that are visible.
-------------------------------------------------------------------------------
function GUB:UnitBarsUpdateStatus(Event, Unit)

  -- Do nothing if the unit is not 'player'.
  if Unit ~= nil and Unit ~= 'player' then
    return
  end

  InCombat = UnitAffectingCombat('player') == 1
  InVehicle = UnitHasVehicleUI('player')
  InPetBattle = C_PetBattles.IsInBattle()
  IsDead = UnitIsDeadOrGhost('player') == 1
  HasTarget = UnitExists('target') == 1
  HasFocus = UnitExists('focus') == 1
  HasPet = select(1, HasPetUI()) ~= nil
  PlayerStance = GetShapeshiftFormID()
  PlayerPowerType = UnitPowerType('player')
  PlayerSpecialization = GetSpecialization()

  for _, UBF in ipairs(UnitBarsFI) do
    UBF:StatusCheck()
    UBF:Update()
  end
end

-------------------------------------------------------------------------------
-- UnitBarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar parent frame will be moved.
-- Otherwise just the unitbar frame will be moved.
--
-- Note: To move a frame the unitbars anchor needs to be moved.
--       This function returns false if it didn't do anything otherwise true.
-------------------------------------------------------------------------------
function GUB.Main:UnitBarStartMoving(Button)

  -- Handle selection of unitbars for the alignment tool.
  if ( Button == 'LeftButton' or Button == 'RightButton' ) and not IsModifierKeyDown() then
    local UBF = self.UnitBarF

    -- Left click select bar if alignment tool is open.
    -- Must have selected a bar (green) first.
    if Button == 'LeftButton' and SelectMode and PSelectedUnitBarF then
      if UBF ~= PSelectedUnitBarF then
        if UBF.Selected then
          SelectUnitBar(UBF, 'clear')
        else
          SelectUnitBar(UBF, 'set', 1, 1, 1, 1)  -- white
        end
      end

    -- Right click select main bar and open alignment tool.
    elseif Button == 'RightButton' then
      if SelectMode then
        if PSelectedUnitBarF and PSelectedUnitBarF ~= UBF then
          SelectUnitBar(PSelectedUnitBarF, 'clear')
        end
        if PSelectedUnitBarF then
          SelectUnitBar(PSelectedUnitBarF, 'set', 1, 1, 1, 1)  -- white
        end
        PSelectedUnitBarF = UBF
        SelectUnitBar(UBF, 'set', 0, 1, 0, 1)  -- green
      else
        Options.ATOFrame:Show()
      end
    end
    return false
  end

  if Button ~= 'LeftButton' then
    return false
  end

  -- Set the moving flag.
  -- Group move check.
  if UnitBars.IsGrouped then
    UnitBarsParent.IsMoving = true
    UnitBarsParent:StartMoving()
  else
    self.IsMoving = true
    self:StartMoving()
  end

  return true
end

-------------------------------------------------------------------------------
-- UnitBarStopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
-------------------------------------------------------------------------------
function GUB.Main:UnitBarStopMoving(Button)
  if UnitBarsParent.IsMoving then
    UnitBarsParent.IsMoving = false
    UnitBarsParent:StopMovingOrSizing()

    -- Save the new position of the ParentFrame.
    UnitBars.Point, _, UnitBars.RelativePoint, UnitBars.Px, UnitBars.Py = UnitBarsParent:GetPoint()
  elseif self.IsMoving then
    self.IsMoving = false
    self:StopMovingOrSizing()

    -- StartMoving() sets the coordinates of the frame relative to UIParent, so we
    -- Need to recalculate where it is relative to frames parent.
    -- Update the UnitBar data with the new coordinates.
    self.UnitBar.x, self.UnitBar.y = Main:RestoreRelativePoints(self)
  end
end

--*****************************************************************************
--
-- Unitbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UnitBarSetAttr
--
-- Base unitbar set attribute. Handles attributes that are shared across all bars.
--
-- Usage    UnitBarSetAttr(UnitBarF, Object, Attr)
--
-- UnitBarF    The Unitbar frame to work on.
-- Object       Object being changed:
--               'frame' for the frame.
-- Attr         Type of attribute being applied to object:
--               'scale'     Scale settings being set to the object.
--               'strata'    Frame strata for the object.
-------------------------------------------------------------------------------
function GUB.Main:UnitBarSetAttr(UnitBarF, Object, Attr)

  -- Get the unitbar data.
  local UB = UnitBarF.UnitBar
  local Border = UnitBarF.Border

  -- Frame.
  if Object == nil or Object == 'frame' then
    if Attr == nil or Attr == 'scale' then
      UnitBarF.ScaleFrame:SetScale(UB.Other.Scale)

      -- Update the unitbar to the correct size based on scale.
      UnitBarF:SetSize()
    end
    if Attr == nil or Attr == 'strata' then
      UnitBarF.Anchor:SetFrameStrata(UB.Other.FrameStrata)
    end
  end
end

-------------------------------------------------------------------------------
-- UnitBarsSetAllOptions
--
-- Handles the settings that effect all the unitbars.
--
-- Usage: UnitBarSetAllOptions()
--
-- Activates the current settings in UnitBars.
--
-- IsLocked
-- IsClamped
-- FadeOutTime
-------------------------------------------------------------------------------
function GUB.Main:UnitBarsSetAllOptions()
  local ATOFrame = Options.ATOFrame

  -- Update alignment tool status.
  if UnitBars.IsLocked or not UnitBars.AlignmentToolEnabled then
    Options.ATOFrame:Hide()
  end

  -- Apply the settings.
  for _, UBF in pairs(UnitBarsF) do
    UBF:EnableMouseClicks(not UnitBars.IsLocked)
    UBF.Anchor:SetClampedToScreen(UnitBars.IsClamped)
  end
  if UnitBars.FadeOutTime then
    for _, UBF in pairs(UnitBarsF) do
      UBF.FadeOutA:SetDuration(UnitBars.FadeOutTime)
    end
  end
end

-------------------------------------------------------------------------------
-- UnitBarsSetScript
--
-- Set up script handlers for the unitbars.
--
-- Usage: UnitBarsSetScript(Enable)
--
-- Enable     If true scripts get set otherwise they get disabled.
-------------------------------------------------------------------------------
local function UnitBarsSetScript(Enable)
  for _, UBF in pairs(UnitBarsF) do
    UBF:FrameSetScript(Enable)
  end
end

-------------------------------------------------------------------------------
-- SetUnitBarsLayout
--
-- Sets all the unitbars with new data.
-------------------------------------------------------------------------------
local function SetUnitBarsLayout()

  -- Set the unitbar parent frame values.
  UnitBarsParent:ClearAllPoints()
  UnitBarsParent:SetPoint(UnitBars.Point, UIParent, UnitBars.RelativePoint, UnitBars.Px, UnitBars.Py)
  UnitBarsParent:SetWidth(1)
  UnitBarsParent:SetHeight(1)

  -- Hide the alignment control panel and turn off selectmode
  SelectMode = false
  Options.ATOFrame:Hide()

  for BarType, UnitBarF in pairs(UnitBarsF) do
    local UB = UnitBars[BarType]
    local Anchor = UnitBarF.Anchor
    local ScaleFrame = UnitBarF.ScaleFrame
    local SelectFrame = UnitBarF.SelectFrame

    -- Stop any old fade animation for this unitbar.
    UnitBarF:CancelAnimation()
    Main:Animation(UnitBarF.FadeOut, 'stop')

    -- Set the anchor position and size.
    Anchor:ClearAllPoints()
    Anchor:SetPoint('TOPLEFT' , UB.x, UB.y)
    Anchor:SetWidth(1)
    Anchor:SetHeight(1)

    -- Set the size of the scale frame.
    ScaleFrame:SetPoint('TOPLEFT', 0, 0)
    ScaleFrame:SetWidth(1)
    ScaleFrame:SetHeight(1)

    -- Set the selectframe width/height.
    SelectFrame:SetAllPoints(Anchor)

    -- Set a reference in the unitbar frame to UnitBars[BarType] and Anchor.
    UnitBarF.UnitBar = UB
    Anchor.UnitBar = UB

    -- Set the layout for the bar.
    UnitBarF:SetLayout()

    -- Set the IsActive flag to false.
    UnitBarF.IsActive = false

    -- Hide the unitbar.
    UnitBarF.Visible = false

    -- Reset the WasEnabled flag
    UnitBarF.WasEnabled = nil

    -- Set selected to false.
    SelectUnitBar(UnitBarF, 'clear')

    -- Hide the select frame.
    SelectFrame:Hide()

    -- Set the hidden flag.
    UnitBarF.Hidden = true

    -- Hide the frame.
    UnitBarF.Anchor:Hide()
  end
end

-------------------------------------------------------------------------------
-- CreateUnitBars
--
-- Creates all the bars used by GalvinUnitBars.
-------------------------------------------------------------------------------
local function CreateUnitBars(UnitBarDB)

  -- Create the unitbar parent frame.
  UnitBarsParent = CreateFrame('Frame', nil, UIParent)
  UnitBarsParent:SetMovable(true)

  for BarType, UnitBarF in pairs(UnitBarsF) do
    local UB = UnitBars[BarType]

    -- Create the anchor frame.
    local Anchor = CreateFrame('Frame', nil, UnitBarsParent)

    -- Hide the anchor
    Anchor:Hide()

    -- Make the unitbar's anchor movable.
    Anchor:SetMovable(true)

    -- Make the unitbar come to top when clicked.
    Anchor:SetToplevel(true)

    -- Create the selectframe.
    local SelectFrame = CreateFrame('Frame', nil, Anchor)
    SelectFrame:SetBackdrop(SelectFrameBorder)
    SelectFrame:SetBackdropBorderColor(1, 1, 1, 0)
    SelectFrame:SetBackdropColor(0, 0, 0, 0)

    -- Create the scale frame.
    local ScaleFrame = CreateFrame('Frame', nil, Anchor)

    if strfind(BarType, 'Health') or strfind(BarType, 'Power') then
      HapBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
    else
      GUB[BarType]:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
    end

    -- Create an animation for fade out.
    local FadeOut, FadeOutA = Main:CreateFade(Anchor, 'out')

    -- Save the animation to the unitbar frame.
    UnitBarF.FadeOut = FadeOut
    UnitBarF.FadeOutA = FadeOutA

    -- Save the bartype.
    UnitBarF.BarType = BarType

    -- Create a reference in the unitbar frame to UnitBars[BarType] and Anchor.
    UnitBarF.UnitBar = UB
    Anchor.UnitBar = UB

    -- Save a lookback to UnitBarF in anchor for selection.
    Anchor.UnitBarF = UnitBarF

    -- Save the anchor.
    UnitBarF.Anchor = Anchor

    -- Save the select frame.
    UnitBarF.SelectFrame = SelectFrame

    -- Save the scale frame.
    UnitBarF.ScaleFrame = ScaleFrame

    -- Save the enable bar function.
    UnitBarF.BarVisible = UB.BarVisible

    -- Add a SetSize function.
    UnitBarF.SetSize = SetUnitBarSize

    -- Add time fields.
    UnitBarF.WaitTime = UB.WaitTime
    UnitBarF.LastTime = 0
  end
end


--*****************************************************************************
--
-- Addon Enable/Disable functions
--
-- Placed at the bottom was tired of doing function forwarding.
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableUnitBars
--
-- Enables/Disables the unitbars.
-------------------------------------------------------------------------------
function GUB.Main:EnableUnitBars()
  local Index = 0
  local Total = 0
  local EnableClass = UnitBars.EnableClass

  for BarType, UBF in pairs(UnitBarsF) do
    local UB = UBF.UnitBar

    Total = Total + 1

    -- Enable/Disable if player class option is true.
    local UsedByClass = UB.UsedByClass

    if EnableClass then
      UB.Enabled = UsedByClass == nil or UsedByClass[PlayerClass] ~= nil
    end
    local Enabled = UB.Enabled

    if Enabled then
      Index = Index + 1
      UnitBarsFI[Index] = UBF

      if UBF.WasEnabled ~= Enabled then
        UBF:Enable(Enabled)

        -- Do a status check.
        UBF:StatusCheck()
        UBF:Update()
      end
    else
      if UBF.WasEnabled ~= Enabled then
        UBF:Enable(Enabled)
      end

      -- Hide the unitbar.
      HideUnitBar(UBF, true)
    end
    UBF.WasEnabled = Enabled
  end

  -- Delete extra bars from the array.
  for Count = Index + 1, Total do
    UnitBarsFI[Count] = nil
  end
end

-------------------------------------------------------------------------------
-- ShareData
--
-- Any bar that needs to share variable from main.lua that can change during
-- runtime can do it thru this ShareData()
--
-- Currently shares  UnitBars, PlayerClass, and PlayerPowerType
-------------------------------------------------------------------------------
local function ShareData()
  for BarType, UBF in pairs(UnitBarsF) do
    local Fn = UBF.ShareData
    if Fn then
      Fn(UnitBars, PlayerClass, PlayerPowerType)
    end
  end
  Options:ShareData(UnitBars, PlayerClass, PlayerPowerType)
end

-------------------------------------------------------------------------------
-- Profile management
-------------------------------------------------------------------------------
function GUB:ProfileChanged(Event, Database, NewProfileKey)

  -- set Unitbars to the new database.
  UnitBars = Database.profile

  -- Share the values with other parts of the addon.
  ShareData()

  GUB:OnEnable()
end

-------------------------------------------------------------------------------
-- SharedMedia management
-------------------------------------------------------------------------------
function GUB:MediaUpdate(Name, MediaType, Key)
  for BarType, UBF in pairs(UnitBarsF) do
    if MediaType == 'border' or MediaType == 'background' then
      UBF:SetAttr('bg', 'backdrop')
    elseif MediaType == 'statusbar' then
      UBF:SetAttr('bar', 'texture')
    elseif MediaType == 'font' then
      UBF:SetAttr('text', 'font')
    end
  end
end

-------------------------------------------------------------------------------
-- One time initialization.
-------------------------------------------------------------------------------
local function OnInitializeOnce()
  if not Initialized then

    -- Get the player class.
    _, PlayerClass = UnitClass('player')

    -- Get the player power type for the player.
    PlayerPowerType = UnitPowerType('player')

    -- Get the globally unique identifier for the player.
    PlayerGUID = UnitGUID('player')

    -- Share the values with other parts of the addon.
    ShareData()

    -- Initialize the options panel.
    -- Delaying Options init to make sure PlayerClass is accessible first.
    Options:OnInitialize()

    GUB.MainDB.RegisterCallback(GUB, 'OnProfileReset', 'ProfileChanged')
    GUB.MainDB.RegisterCallback(GUB, 'OnProfileChanged', 'ProfileChanged')
    GUB.MainDB.RegisterCallback(GUB, 'OnProfileCopied', 'ProfileChanged')

    LSM.RegisterCallback(GUB, 'LibSharedMedia_Registered', 'MediaUpdate')

    Initialized = true
  end
end

-------------------------------------------------------------------------------
-- Initialize when addon is loaded.
-------------------------------------------------------------------------------
function GUB:OnInitialize()

  -- Add blizzards powerbar colors and class colors to defaults.
  InitializeColors()

  -- Load the unitbars database
  GUB.MainDB = LibStub('AceDB-3.0'):New('GalvinUnitBarsDB', Defaults, true)

  -- Save the unitbars data from the current profile.
  UnitBars = GUB.MainDB.profile

  -- Share the values with other parts of the addon.
  ShareData()

  -- Create the unitbars.
  CreateUnitBars()

--@do-not-package@
  GUBfdata = UnitBarsF -- debugging 00000000000000000000000000000000000
--@end-do-not-package@
end

-------------------------------------------------------------------------------
-- Initialize after addon is enabled.
-------------------------------------------------------------------------------
function GUB:OnEnable()

  -- Do one time initialization.
  OnInitializeOnce()

  -- Update all the unitbars according to the new data.
  SetUnitBarsLayout()

  -- Set up the scripts.
  UnitBarsSetScript(true)

  -- Enable unit bars.
  Main:EnableUnitBars()

  -- Initialize the events.
  RegisterEvents('register', 'main')

  -- Set the unitbars global settings
  Main:UnitBarsSetAllOptions()

  -- Set the unitbars status and show the unitbars.
  GUB:UnitBarsUpdateStatus()

--@do-not-package@
  GSB = GUB -- for debugging OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
  GUBdataf = UnitBarsF
  GUBdata = UnitBars
--@end-do-not-package@
end

function GUB:OnDisable()

  -- Disable all the scripts.
  UnitBarsSetScript(false)

  -- Hide all the bars.
  for _, UBF in pairs(UnitBarsF) do
    UBF.Anchor:Hide()
  end

  -- All registered events automatically get disabled by ace3.
end
