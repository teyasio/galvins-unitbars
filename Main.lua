--
-- Main.lua
--
-- Displays different bars for each class.  Rage, Energy, Mana, Runic Power, etc.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.Main = {}
local Main = GUB.Main

-------------------------------------------------------------------------------
-- Setup Ace3
-------------------------------------------------------------------------------
LibStub('AceAddon-3.0'):NewAddon(GUB, MyAddon, 'AceConsole-3.0', 'AceEvent-3.0')

-------------------------------------------------------------------------------
-- Setup shared media
-------------------------------------------------------------------------------
local LSM = LibStub('LibSharedMedia-3.0')
local CataVersion = select(4,GetBuildInfo()) >= 40000


-- localize some globals.
local _
local bitband,  bitbxor,  bitbor,  bitlshift,  stringfind =
      bit.band, bit.bxor, bit.bor, bit.lshift, string.find
local pcall, abs, mod, max, floor, strsub, strupper, strconcat, tostring, pairs, ipairs, type, math, table, select =
      pcall, abs, mod, max, floor, strsub, strupper, strconcat, tostring, pairs, ipairs, type, math, table, select
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType
local GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection, GetInventoryItemID

------------------------------------------------------------------------------
-- Register GUB textures with LibSharedMedia
------------------------------------------------------------------------------
LSM:Register('statusbar', 'GUB Bright Bar', [[Interface\Addons\GalvinUnitBars\Textures\GUB_SolidBrightBar.tga]])
LSM:Register('statusbar', 'GUB Dark Bar', [[Interface\Addons\GalvinUnitBars\Textures\GUB_SolidDarkBar.tga]])

------------------------------------------------------------------------------
-- Locals
--
-- UnitBarsF[Bartype].Anchor
--                      This is the unitbars anchor/location frame on screen.
--                      This frame also controls the hiding and showing of all unitbars.
-- UnitBarsF[BarType].Anchor.UnitBar
--                      Reference to the UnitBars[BarType] for moving.
-- UnitBarsF[BarType].ScaleFrame
--                      This is the parent of the unitbar and the child of the anchor.
--                      It's only function is to scale unitbars.
-- UnitBarsF[BarType]:CancelAnimation()
--                      This will cancel any animation that is playing in the bar.
--                      This was added as a work around to prevent alpha animations playing while the whole
--                      bar is getting faded out.  If this work around wasn't in then alpha animations can
--                      get stuck and become permanently transparent.
--
--                      This is used by HideUnitBar().  The creator passes back this function if the bar
--                      does alpha animations.
-- UnitBarsF[BarType]:Update()
--                      Based on the bartype this will be assigned a function for displaying the data for
--                      the unitbar.
-- UnitBarsF[BarType]:StatusCheck()
--                      Based on the bartype this will be assigned a function to check the status against
--                      each unitbar.
-- UnitBarsF[BarType]:EnableScreenClamp(Enable)
--                      If true prevents any frames attached to the unitbar from moving off the screen.
--                      Otherwise frames can move off screen.
-- UnitBarsF[BarType]:EnableMouseClicks(Enable)
--                      Enables the controlling frame or frames to take mouse clicks. Each unitbar has a
--                      different method to enable frames.
-- UnitBarsF[BarType]:FrameSetScript(Enable)
--                      Based on the bartype a specific function will be called to set up scripts for
--                      anchor frame.  But sometimes a different frame needs to have scripts set.
-- UnitBarsF[BarType]:SetAttr(Object, Attr, [Eclipse])
--                      Sets texture, font, color, etc.  To anybar. See eclipsebar.lua for Eclipse.
-- UnitBarsF[BarType]:SetLayout()
--                      Sets/Updates the layout.
-- UnitBarsF[BarType].Enabled
--                      True or false.  Enabled setting for each unitbar frame.
-- UnitBarsF[BarType].Hidden
--                      True then the unitbar is not visible.
-- UnitBarsF[BarType].IsActive
--                      True then the unitbar is active else false for no activity.
--                      Defaults to true if not supported.
-- UnitBarsF[BarType].FadeOut
--                      Animation group for fadeout. This group is a child of the UnitBar frame.
-- UnitBarsF[BarType].FadeOutA
--                      Animation that contains the fade out. This animation is a child of FadeOut.
-- UnitBarsF[BarType].UnitBar
--                      This is a reference into UnitBars[BarType].
-- UnitBarsF[BarType].Width
--                      This contains the width of the unitbar.
-- UnitBarsF[BarType].Height
--                      This contains the height of the unitbar.  Width and Height are used by the unitbars
--                      alignment tool.
-- UnitBarsF[BarType].BarType
--                      Some functions need to know what frame they're working on. Also for debugging.
--
-- UnitBarsParent       This is the parent frame for all unitbars.  This frame is used to control group
--                      dragging.
--
-- Defaults             The default unitbar table.  Used for first time initialization.
--
-- CooldownBarTimerDelay
--                      Delay for the cooldown timer bar.
-- UnitBarDelay      Delay for health and power bars.
--
-- PowerColorType       Table used by InitializeColors()
-- PowerTypeToNumber    Converts a string powertype into a number.
-- CheckEvent           Check to see if an event is correct.  Converts an event into one of the following:
--                       * 'runepower', 'runetype' for a rune event.
-- ClassToPowerType     Converts class string to the primary power type for that class.
-- PlayerClass          Name of the class for the player in english.
-- PlayerGUID           Globally unique identifier for the player.  Used by CombatLogUnfiltered()
--
-- Backdrop             This contains a Backdrop table that has texture path names.  Since this addon uses
--                      shared media.  Texture names need to be converted into path names.  So ConvertBackdrop()
--                      needs to be called.  ConvertBackdrop then sets this table to a real backdrop table that
--                      can be used in SetBackdrop().  This table should never be reference to another table
--                      since convertbackdrop passes back a reference to this table.
--
-- InCombat             Set to true when the player is in combat.
-- InVehicle            Set to true if the player is in a vehicle.
-- IsDead               Set to true if the player is dead.
-- HasTarget            Set to true if the player has a target.
-- HasFocus             Set to true if the player has a focus.
-- HasPet               Set to true if the player has a pet.
--
-- PlayerPowerType      The main power type for the player.
-- Initialized          Flag for OnInitializeOnce().
--
-- BgTexure             Default background texture for the backdrop.
-- BdTexture            Default border texture for the backdrop.
-- StatusBarTexure      Default bar texture for the health and power bars.
--
-- UnitBarsFList        Reusable table used by the alignment tool.
--
-- PointCalc            Table used by CalcSetPoint() to return a location inside a parent frame.
--
-- FontSettings         Standard container for setting a font. Used by SetFontString()
--   FontType           Type of font to use.
--   FontSize           Size of the font.
--   FontStyle          Contains flags seperated by a comma: MONOCHROME, OUTLINE, THICKOUTLINE
--   FontHAlign         Horizontal alignment.  LEFT  CENTER  RIGHT
--   Position           Position relative to the font's parent.  Can be one of the 9 standard setpoints.
--   Width              Field width for the font.
--   OffsetX            Horizontal offset position of the frame.
--   OffsetY            Vertical offset position of the frame.
--   ShadowOffset       Number of pixels to move the shadow towards the bottom right of the font.
--
-- BackdropSettings     Backdrop settings table. Must be converted into a backdrop before using.
--   BgTexture          Name of the background textured in sharedmedia.
--   BdTexture          Name of the forground texture 'statusbar' in sharedmedia.
--   BgTile             If true then the background is tiled, otherwise not tiled.
--   BgTileSize         Size (width or height) of the square repeating background tiles (in pixels).
--   BdSize             Size of the border texture thickness in pixels.
--   Padding
--     Left, Right, Top, Bottom
--                      Positive values go inwards, negative values outward.
--
-- UnitBars.IsGrouped   If true all unitbars get dragged as one object.  If false each unitbar can be dragged
--                      by its self.
-- UnitBars.IsLocked    If true all unitbars can not be clicked on.
-- UnitBars.IsClamped   If true all frames can't be moved off screen.
-- UnitBars.HideTooltips
--                      If true tooltips are not shown when mousing over unlocked bars.
-- UnitBars.HideTooltipsDesc
--                      If true the descriptions inside the tooltips will not be shown when mousing over
--                      unlocked bars.
-- UnitBars.FadeOutTime Time in seconds before a bar completely goes hidden.
--
-- UnitBars.Px and Py   The current location of the UnitBarsParent on the screen.
--
-- Fields found in all unitbars.
--   x, y               Current location of the unitbar anchor relative to the UnitBarsParent.
--   Status             Table that contains a list of flags marked as true or false.
--                      If a flag is found true then a statuscheck will be done to see what the
--                      bar should do. Flags with a higher priority override flags with a lower.
--                      Flags from highest priority to lowest.
--                        ShowNever        Disables and hides the unitbar.
--                        HideWhenDead     Hide the unitbar when the player is dead.
--                        HideInVehicle    Hide the unitbar if in a vehicle.
--                        ShowAlways       The unitbar will be shown all the time.
--                        HideNotActive    Hide the unitbar if its not active.
--                        HideNoCombat     Don't hide the unitbar when not in combat.
--
-- Other                For anything not related mostly this will be for scale and maybe alpha
--   Scale              Sets the scale of the unitbar frame.
--
-- UnitBars health and power fields
--   General
--     PredictedHealth      Used by health bars only, except Pet Health.
--                          If true then predicted health will be shown.
--     PredictedPower       Used by Player Power for hunters only.
--                          If true predicted power will be shown.
--   Background
--     PaddingAll           If true then padding can be set with one value other four.
--     BackdropSettings     Contains the settings for the background, background, and padding.
--     Color                Current color of the background texture of the border frame.
--   Bar
--     ClassColor           (Target and Focus Health bars only) If true then the health bar uses the
--                          class color otherwise uses the normal color.
--     HapWidth, HapHeight
--                          The current width and height.
--     FillDirection        Direction to the fill the bar in 'HORIZONTAL' or 'VERTICAL'.
--     RotateTexture        If true then the bar texture will be rotated 90 degree counter-clockwise
--                          If false no rotation takes place.
--     PaddingAll           If true then padding can be set with one value otherwise four.
--     Padding              The amount of pixels to be added or subtracted from the bar texture.
--     StatusBarTexture     Texture for the bar its self.
--     PredictedBarTexture  Used for Player, Target, Focus.  Texture used for the predicted health.
--     PredictedColor       Used for Player, Target, Focus.  Color of the predicted health bar.
--     Color                hash table for current color of the bar. Health bars only.
--     Color[PowerType]
--                          This array is for powerbars only.  By default they're loaded from blizzards default
--                          colors.
--   Text
--     TextType
--       Custom           If true then a user layout is specified otherwise the default layout is used.
--       Layout           Layout to display the text, this can vary depending on the ValueType.
--                        If this is set to zero nothing will get displayed.
--       MaxValues        Maximum number of values to be displayed on the bar.
--       ValueName        Table containing which value to be displayed.
--                          ValueNames:
--                            'current'        - Current Value of the health or power bar.
--                            'maximum'        - Maximum Value of the health or power bar.
--                            'predicted'      - Predicted value of the health or power bar.
--                                               Not all bars support predicted.
--       ValueType        Type of value to be displayed based on the ValueName.
--                          ValueTypes:
--                            'whole'             - Whole number
--                            'whole_dgroups'     - Whole number in digit groups 999,999,999
--                            'percent'           - Percentage
--                            'thousands'         - In thousands 999.9k
--                            'millions'          - In millions  999.9m
--                            'short'             - In thousands or millions depending on the value.
--                            'none'              - No value gets displayed
--     FontSettings       Contains the settings for the text.
--     Color              Current color of the text for the bar.
--   Text2                Same as Text, provides a second text frame.
--
-- Runebar fields
--   General
--     BarModeAngle       Angle in degrees in which way the bar will be displayed.  Only works in barmode.
--                        Must be a multiple of 45 degrees and not 360.
--     BarMode            If true the runes are displayed from left to right forming a bar of runes.
--     RuneMode             'rune'             Only rune textures are shown.
--                          'cooldownbar'      Cooldown bars only are shown.
--                          'runecooldownbar'  Rune and a Cooldown bar are shown.
--     RuneSwap           If true runes can be dragged and drop to swap positions. Otherwise
--                        nothing happens when a rune is dropped on another rune.
--     CooldownDrawEdge   If true a line is drawn on the clock face cooldown animation.
--     CooldownBarDrawEdge
--                        If true a line is draw on the cooldown bar edge animation.
--     CooldownAnimation  If true cooldown animation is shown otherwise false.
--     CooldownText       If true then cooldown text gets displayed otherwise false.

--     HideCooldownFlash  If true a flash cooldown animation is not shown when a rune comes off cooldown.
--     RuneSize           Width and Hight of all the runes.
--     RunePadding        For barmode only, the amount of space between the runes.
--     RunePosition       Position of the rune attached to Cooldownbar.  In runecooldownbar mode.
--     RuneOffsetX        Offset X from RunePosition.
--     RuneOffsetY        Offset Y from RunePosition.
--   Background           Only used for cooldown bars.
--     ColorAll           If true then all cooldown bars use the same color.
--     PaddingAll         If true then padding can be set with one value otherwise four.
--     BackdropSettings   Contains the settings for background, border, and padding for each cooldown bar.
--                        This is used for cooldown bars only.
--     Color              Color used for all the cooldown bars when ColorAll is true
--     Color[1 to 8]      Colors used for each cooldown bar when ColorAll is false.
--   Bar                  Only used for cooldown bars.
--     ColorAll           If true then all cooldown bars use the same color.
--     RuneWidth          Width of the cooldown bar.
--     RuneHeight         Height of the cooldown bar.
--     FillDirection      Changes the fill direction. 'VERTICAL' or 'HORIZONTAL'.
--     RotateTexture      If true then the bar texture will be rotated 90 degree counter-clockwise
--                        If false no rotation takes place.
--     PaddingAll         If true then padding can be set with one value otherwise four.
--     Padding            The amount of pixels to be added or subtracted from the bar texture.
--     StatusBarTexture   Texture for the cooldown bar.
--     Color              Current color of the cooldown bar.
--   Text
--     ColorAll           If true then all the combo boxes are set to one color.
--                        if false then each combo box can be set a different color.
--     FontSettings       Contains the settings for the text.
--     Color              Current color of the text for the bar.
--
--   RuneBarOrder         The order the runes are displayed from left to right in barmode.
--                        RuneBarOrder[Rune slot 1 to 6] = The rune frame on screen.
--   RuneLocation         Contains the x, y location of the runes on screen when not in barmode.
--
-- Combobar fields
--   General
--     ComboPadding       The amount of space in pixels between each combo point box.
--     ComboAngle         Angle in degrees in which way the bar will be displayed.
--     ComboFadeOutTime   Time in seconds for a combo point to go invisible.
--   Background
--     ColorAll           If true then all the combo boxes are set to one color.
--                        if false then each combo box can be set a different color.
--     PaddingAll         If true then padding can be set with one value otherwise four.
--     BackdropSettings   Contains the settings for background, border, and padding for each combo point box.
--     Color              Contains just one background color for all the combo point boxes.
--                        Only works when ColorAll is true.
--     Color[1 to 5]      Contains the background colors of all the combo point boxes.
--   Bar
--     ColorAll           If true then all the combo boxes are set to one color.
--                        if false then each combo box can be set a different color.
--     BoxWidth           The width of each combo point box.
--     BoxHeight          The height of each combo point box.
--     FillDirection      Currently not used.
--     RotateTexture      If true then the bar texture will be rotated 90 degree counter-clockwise
--                        If false no rotation takes place.
--     PaddingAll         If true then padding can be set with one value otherwise four.
--     Padding            Amount of padding on the forground of each combo point box.
--     StatusbarTexture   Texture used for the forground of each combo point box.
--     Color              Contains just one bar color for all the combo point boxes.
--                        Only works when ComboColorAll is true.
--     Color[1 to 5]      Contains the bar colors of all the combo point boxes.
--
-- Holybar fields
--   General
--     BoxMode            If true the bar uses boxes instead of textures.
--     HolySize           Size of the holy rune with and height.  Not used in Box Mode.
--     HolyPadding        Amount of space between each holy rune.  Works in both modes.
--     HolyScale          Scale of the rune without changing the holy bar size. Not used in box mode.
--     HolyFadeOutTime    Amount of time in seconds before a holy rune goes dark.  Works in both modes.
--     HolyAngle          Angle in degrees in which way the bar will be displayed.
--   Background
--     ColorAll           If true then all the holy rune boxes are set to one color.
--                        if false then each holy rune box can be set a different color.
--                        Only works in box mode.
--     PaddingAll         If true then padding can be set with one value otherwise four.
--     BackdropSettings   Contains the settings for background, border, and padding for each holy rune box.
--                        When in box mode each holy box uses this setting.
--     Color              Contains just one background color for all the holy rune boxes.
--                        Only works when ColorAll is true.
--     Color[1 to 3]      Contains the background colors of all the holy rune boxes.
--   Bar
--     ColorAll           If true then all the holy rune boxes are set to one color.
--                        if false then each holy rune box can be set a different color.
--                        Only works in box mode.
--     BoxWidth           Width of each holy rune box.
--     BoxHeight          Height of each holy rune box.
--     PaddingAll         If true then padding can be set with one value otherwise four.
--     Padding            Amount of padding on the forground of each holy rune box.
--     StatusbarTexture   Texture used for the forground of each holy rune box.
--     Color              Contains just one bar color for all the holy rune boxes.
--                        Only works when ComboColorAll is true.
--     Color[1 to 3]      Contains the bar colors of all the holy rune boxes.
--
-- Shardbar fields        Same as Holybar fields just uses shards instead.
--
-- Eclipsebar fields
--   General
--     SliderInside       If true the slider is kept inside the bar is slides on.
--                        Otherwise the slider box will appear a little out side when it reaches edges of the bar.
--     BarHalfLit         Only half of the bar is lit based on the direction the slider is going in.
--     PowerText          If true then eclipse power text will be shown.
--     EclipseAngle       Angle in degrees in which the bar will be displayed.
--     SliderDirection    if 'HORIZONTAL' slider will move left to right and right to left.
--                        if 'VERTICAL' slider will move top to bottom and bottom to top.
--     PredictedPower     if true then predicted power will be activated.
--     IndicatorHideShow  'showalways' the indicator will never auto hide.
--                        'hidealways' the indicator will never be shown.
--                        'none'       default.
--     PredictedHideSlider
--                        Hide the slider when predicted power is on.
--     PredictedEclipse   Show an eclipse proc based on predicted power.
--     PredictedHalfLit   Same as BarHalfLit except it is based on predicted power
--     PredictedPowerText If true predicted power text is shown in place of power text.
--   Background
--     Moon, Sun, Bar, Slider, and Indicator
--       PaddingAll       If true then padding can be set with one value otherwise four.
--       BackdropSettings Contains the settings for background, border, and padding.
--       Color            Contains the color.
--   Bar
--     All fields have the following:
--       FillDirection    Currently not used.
--       RotateTexture    If true then the bar texture will be rotated 90 degree counter-clockwise
--                        If false no rotation takes place.
--       PaddingAll       If true then padding can be set with one value otherwise four.
--       Padding          Amount of padding for the forground of the sun and moon.
--       StatusBarTexture Texture used for the forground.  Not used for the Bar field.
--       Color            Contains the color of the StatusBarTexture. Not used for the Bar field.
--     Sun and Moon
--       Sun/MoonWidth    Width of the sun/moon.
--       Sun/MoonHeight   Width of the sun/moon.
--     Slider
--       SunMoon          If true the slider uses the Sun and Moon color based on which direction it's going in.
--       SliderWidth      Width of the slider.
--       SliderHeight     Height of the slider.
--     Indicator          Same as slider except used for predicted power.
--     Bar
--       BarWidth         Width of the bar.
--       BarHeight        Height of the bar.
--       StatusBarTextureLunar
--                        Texture that fills up the solar half of the bar.
--       StatusBarTextureSolar
--                        Texture that fills up the lunar half of the bar.
--       ColorLunar       Color of the StatusBarTextureLunar.
--       ColorSolar       Color of the StatusBarTextureSolar.
--   Text
--     FontSettings       Contains the settings for the text.
--     Color              Current color of the text for the bar.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Predicted Power
--
-- Keeps track of spells flying and casting.
--
-- PredictedSpellEvent  Used by SetPredictedSpell().
-- PredictedSpellMessage
--                      Used with EventSpellFailed.  If the Message is not found in the table.
--                      then the spell is considered failed.
-- PredictedSpellStackTimeout
--                      Amount of time in seconds before removing a spell from the stack.
--                      This is used by GetPredictedSpell().  This way SetPredictedSpell()
--                      doesn't haev to check for every event.
--
-- PredictedSpellCasting
--   SpellID            Spell that is casting
--   LineID             LineID of Spell
--
-- PredictedSpellStack  Used by SetPredictedSpell() and GetPredictedSpell()
--   SpellID            Spell in flight.
--   Time               Starting time when spell started to fly.
--
-- PredictedSpellCount  Keeps count of how many spells are on the stack.
--
-- PredictedSpells[SpellID]  Used by SetPredictedSpells() and SetPredictedSpell()
--   SpellID            SpellID to search for.
--   Flight             If true the spell must fly to the target before its considered done.
--   Fn                 User defined function to override a spell being removed from the stack
--                      or not.  See SetPredictedSpell() on how it's used.
--                      Fn() is only called when the spell damages or generates an energize event.
--
-- EventSpellStart
-- EventSpellSucceeded
-- EventSpellDamage
-- EventSpellEnergize
-- EventSpellMissed
-- EventSpellFailed    These constants are used to track the spell events in SetPredictedSpell()
--
-- PredictedSpellsTime Time since last GetPredictedSpell() call.  If this timer reaches 0 then
--                     predicted spells sytem unregistes events that make it work.
--                     Used by CreateUnitBarTimers()
-- PredictedSpellsWaitTime
--                     Time in seconds to wait after the last GetPredictedSpell() call to turn
--                     off.
--
-- NOTE: See the notes on each of the predicted power functions for more details.  Also
--       See Eclipse.lua on how this is used.
--
--       The eventspell system will disable its self if not used after a PredictedSpellsWaitTime.
--       When GetPredictedSpell() is used it'll be renabled.
--       By default predicted spells is disabled until used.
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
--
-- NOTE: See CreateUnitBarTimers() on how this is used.
-------------------------------------------------------------------------------
local InCombat = false
local InVehicle = false
local IsDead = false
local HasTarget = false
local HasFocus = false
local HasPet = false
local PlayerPowerType = nil
local PlayerClass = nil
local PlayerGUID = nil
local MoonkinForm = 31
local Initialized = false

local EquipmentSetRegisterEvent = false

local PredictedPowerID = -1
local PredictedSpellCount = 0
local PredictedSpellStackTimeout = 5

local EventSpellStart       = 1
local EventSpellSucceeded   = 2
local EventSpellDamage      = 3
local EventSpellEnergize    = 4
local EventSpellMissed      = 5
local EventSpellFailed      = 6

local CooldownBarTimerDelay = 1 / 40 -- 40 times per second
local UnitBarDelay = 1 / 12   -- 12 times per second.

local PredictedSpellsTime = 0
local PredictedSpellsWaitTime = 5 -- 5 secs

local UnitBarsParent = nil
local UnitBars = nil
local UnitBarsF = {}

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
    IsGrouped = false,
    IsLocked = false,
    IsClamped = true,
    HideTooltips = false,
    HideTooltipsDesc = false,
    FadeOutTime = 1.0,
-- Player Health
    PlayerHealth = {
      Name = 'Player Health',
      x = 0,
      y = 150,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        HideNotActive = false,
        HideNoCombat  = false
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
      x = 0,
      y = 120,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        HideNotActive = false,
        HideNoCombat  = false
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
      x = 0,
      y = 90,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        HideNotActive = false,
        HideNoCombat  = false
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
      x = 0,
      y = 60,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        HideNotActive = false,
        HideNoCombat  = false
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
      x = 0,
      y = 30,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        HideNotActive = false,
        HideNoCombat  = false
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
      x = 0,
      y = 0,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        HideNotActive = false,
        HideNoCombat  = false
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
      x = 0,
      y = -30,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        HideNotActive = false,
        HideNoCombat  = false
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
      x = 0,
      y = -60,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        HideNotActive = false,
        HideNoCombat  = false
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
-- Main Power
    MainPower = {
      Name = 'Main Power',
      x = 0,
      y = -90,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        HideNotActive = false,
        HideNoCombat  = false
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
      x = 0,
      y = -120,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        HideNotActive = false,
        HideNoCombat  = false
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
      x = 0,
      y = -150,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = false,
        HideNotActive = true,
        HideNoCombat  = false
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
      x = 0,
      y = -180,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = false,
        HideNotActive = false,
        HideNoCombat  = false
      },
      General = {
        BoxMode = false,
        HolySize = 31,
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
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          r = 0.5, g = 0.5, b = 0.5, a = 1,
          [1] = {r = 0.5, g = 0.5, b = 0.5, a = 1},
          [2] = {r = 0.5, g = 0.5, b = 0.5, a = 1},
          [3] = {r = 0.5, g = 0.5, b = 0.5, a = 1},
        },
      },
      Bar = {
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
        },
      },
    },
-- ShardBar
    ShardBar = {
      Name = 'Shard Bar',
      x = 0,
      y = -215,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = false,
        HideNotActive = false,
        HideNoCombat  = false
      },
      General = {
        BoxMode = false,
        ShardSize = 31,
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
        },
      },
    },
-- EclipseBar
    EclipseBar = {
      Name = 'Eclipse Bar',
      x = 0,
      y = -250,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = false,
        HideNotActive = false,
        HideNoCombat  = false
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
  },
}

local UnitBarsFList = {}

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

-- first ID is normal, second is heroic. Last number is tier.
local EquipmentSet = {
  [1]  = {[71108] = 12, [71497] = 12}, -- Balance druid helmet
  [3]  = {[71111] = 12, [71500] = 12}, -- Balance druid shoulders
  [5]  = {[71110] = 12, [71499] = 12}, -- Balance druid chest
  [7]  = {[71109] = 12, [71498] = 12}, -- Balance druid legs
  [10] = {[71107] = 12, [71496] = 12}, -- Balance druid gloves
}

local EquipmentSetBonus = {}

local PredictedSpellEvent = {
  UNIT_SPELLCAST_START       = EventSpellStart,
  UNIT_SPELLCAST_SUCCEEDED   = EventSpellSucceeded,
  SPELL_DAMAGE               = EventSpellDamage,
  SPELL_ENERGIZE             = EventSpellEnergize,
  SPELL_MISSED               = EventSpellMissed,
  SPELL_CAST_FAILED          = EventSpellFailed,
}

local PredictedSpellMessage = {
  ['Not yet recovered']             = 1,     -- SPELL_FAILED_NOT_READY
  ['Another action is in progress'] = 1,     -- SPELL_FAILED_SPELL_IN_PROGRESS
}

local PredictedSpells = {}

local PredictedSpellCasting = {
  SpellID = 0,
  LineID = -1,
}

local PredictedSpellStack = {}

local PowerColorType = {MANA = 0, RAGE = 1, FOCUS = 2, ENERGY = 3, RUNIC_POWER = 6}
local PowerTypeToNumber = {MANA = 0, RAGE = 1, FOCUS = 2, ENERGY = 3,
                           RUNIC_POWER = 6, SOUL_SHARDS = 7, ECLIPSE = 8, HOLY_POWER = 9}

local ClassToPowerType = {
  MAGE = 'MANA', PALADIN = 'MANA', PRIEST = 'MANA', DRUID = 'MANA', SHAMAN = 'MANA', WARLOCK = 'MANA',
  HUNTER = 'FOCUS', ROGUE = 'ENERGY', WARRIOR = 'RAGE', DEATHKNIGHT = 'RUNIC_POWER'
}

local CheckEvent = {
  RUNE_POWER_UPDATE = 'runepower', RUNE_TYPE_UPDATE = 'runetype',
}

-- Share with the whole addon.
Main.LSM = LSM
Main.UnitBarsF = UnitBarsF
Main.Defaults = Defaults
Main.PowerTypeToNumber = PowerTypeToNumber
Main.CheckEvent = CheckEvent
Main.MouseOverDesc = 'Modifier + left mouse button to drag'

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
    GUB:RegisterEvent('UNIT_ENTERED_VEHICLE', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('UNIT_EXITED_VEHICLE', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('UNIT_DISPLAYPOWER', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('UNIT_PET', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('PLAYER_REGEN_ENABLED', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('PLAYER_REGEN_DISABLED', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('PLAYER_TARGET_CHANGED', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('PLAYER_FOCUS_CHANGED', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('PLAYER_DEAD', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('PLAYER_UNGHOST', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('PLAYER_ALIVE', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('PLAYER_LEVEL_UP', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('PLAYER_TALENT_UPDATE', 'UnitBarsUpdateStatus')
    GUB:RegisterEvent('UPDATE_SHAPESHIFT_FORM', 'UnitBarsUpdateStatus')

    -- Register rune power events.
    GUB:RegisterEvent('RUNE_POWER_UPDATE', 'UnitBarsUpdate')
    GUB:RegisterEvent('RUNE_TYPE_UPDATE', 'UnitBarsUpdate')

  elseif EventType == 'predictedspells' then
    if Action == 'register' then

      -- register events for predicted spells.
      GUB:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', 'CombatLogUnfiltered')
      GUB:RegisterEvent('UNIT_SPELLCAST_START', 'SpellCasting')
      GUB:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED', 'SpellCasting')
    else
      GUB:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
      GUB:UnregisterEvent('UNIT_SPELLCAST_START')
      GUB:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')
    end

  elseif EventType == 'setbonus' then
    if Action == 'register' then

      -- register event for equipment set bonus tracking.
      GUB:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 'PlayerEquipmentChanged')
    else
      GUB:UnregisterEvent('PLAYER_EQUIPMENT_CHANGED')
    end
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
         BarType == 'FocusPower' or BarType == 'PetPower' or BarType == 'MainPower' then
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
-- AlignUnitBars
--
-- Aligns one or more unitbars with a single unitbar.
--
-- Subfunction of GUB.Options:CreateAlignUnitBarsOptions()
--
-- Usage: AlignUnitBars(AlignmentBar, BarsToAlign, AlignType, Align, PadEnabled, Padding)
--
-- AlignmentBar     Unitbar to align other bars with.
-- BarsToAlign      List of unitbars to align with AlignmentBar
-- AlignType        Type of alignment being done. 'horizontal' or 'vertical'
-- Align            If doing vertical alignment then this is set to 'left' or 'right'
--                  if doing horizontal alignment then this is set to 'top' or 'bottom'
--                  'right' Align each bar to the right side the AlignmentBar.
-- PadEnabled       If true Padding will be applied, otherwise ignored.
-- Padding          Each bar will be spaced apart in pixels equal to padding.
--
-- NOTES:  Since this is a slightly complex function I need some notes for it.
--
-- UnitBarsFList (UBFL)    This is designed to be a reusable table since this function
--                         can get called a lot when setting up alignment.
-- UBFL                    Contains a reference to UnitBarsF[BarType]
-- UBFL.Valid              If true then the UnitBarsF[BarType] reference can be used.
--                         If false then the reference is left over from another alignement call
--                         and will not be used.
--
-- When the function gets called it first adds the list of bars to be aligned to the
-- UBFL.  Then it adds the main alignment bar to the list.  Flagging each entry added
-- as valid.
--
-- Then it sorts the list, the reason for having the valid flags is so when sort
-- the data we can tell which is the new data and the old.
--
-- Now we need to find our alignment bar in the sorted list.
--
-- For PadEnabled only
--   Bars can be aligned vertically or horizontally.  When we start out and are going
--   right or down.  We need to push our X or Y (XY) value to the next location.  So before
--   entering the main loop.  We push XY by the size of the alignmentbar.  Then inside the
--   loop we need to set that new XY value before pushing XY again.
--   When going left or up we dont push XY and when we go into the main loop we then push
--   XY forward because we first need to get the new width and heigh of the bar thats behind
--   the alignment bar.  This can only be done once we're in the loop.  Then we set the value
--   after.
--
-- For left/right top/bottom alignment we don't adjust XY.  We just line up the bars.
--
-- The Flip value acts as a flag to tell us if we're doing vertical or horizontal.  It's also
-- used to flip negative values to positive or vice versa.  This is because when doing
-- vertical alignment.  The screen coordinates says that -1 goes down and +1 goes up.  So
-- as we go down our list we also want to go down on the screen.  So we take +1 and change it
-- to -1.  Flip = 1 for horizontal because -1 goes left and +1 goes right.  No need to flip values.
--
-- This code was a doozy to write, but it works and it's awesome. Who knows if theres a
-- better way to do it.
-------------------------------------------------------------------------------
local function SortY(a, b)
  return a.UBF.UnitBar.y > b.UBF.UnitBar.y
end

local function SortX(a, b)
  return a.UBF.UnitBar.x < b.UBF.UnitBar.x
end

function GUB.Main:AlignUnitBars(AlignmentBar, BarsToAlign, AlignType, Align, PadEnabled, Padding)

  -- Add the BarsToAlign data to UnitBarsFList.
  local UnitBarI = 1
  local UBFL = nil
  local MaxUnitBars = 0

  for BarType, v in pairs(BarsToAlign) do
    MaxUnitBars = MaxUnitBars + 1
    if v or BarType == AlignmentBar then
      UBFL = UnitBarsFList[UnitBarI]
      if UBFL == nil then
        UBFL = {}
        UnitBarsFList[UnitBarI] = UBFL
      end
      UBFL.Valid = true
      UBFL.UBF = UnitBarsF[BarType]
      UnitBarI = UnitBarI + 1
    end
  end

  -- Set the remaining entries to false.
  for i, v in ipairs(UnitBarsFList) do
    if i >= UnitBarI then
      v.Valid = false
    end
  end

  local Flip = 0

  -- Initialize Flip and sort on alignment type.
  if AlignType == 'vertical' then
    Flip = -1
    table.sort(UnitBarsFList, SortY)
  elseif AlignType == 'horizontal' then
    Flip = 1
    table.sort(UnitBarsFList, SortX)
  end

  local AWidth = 0
  local AHeight = 0
  local AlignmentBarI = 0
  local AScale = 0

  -- Find the alignementbar first
  for i, UBFL in ipairs(UnitBarsFList) do
    if UBFL.Valid and UBFL.UBF.BarType == AlignmentBar then
      AlignmentBarI = i
      local UBF = UBFL.UBF
      AScale = UBF.UnitBar.Other.Scale
      AWidth = UBF.Width * AScale
      AHeight = UBF.Height * AScale
    end
  end

  -- Get the starting x, y location
  local StartX = UnitBars[AlignmentBar].x
  local StartY = UnitBars[AlignmentBar].y

  -- Direction tells us which direction to go in.
  for Direction = -1, 1, 2 do
    local x = StartX
    local y = StartY
    local i = AlignmentBarI + Direction * Flip

    -- Initialize the starting location for padding.
    -- Only if going down or right
    if Flip == -1 then
      if PadEnabled and Direction == -1 then
        y = y + (AHeight + Padding) * Flip
      end
    elseif PadEnabled and Direction == 1 then
      x = x + (AWidth + Padding)
    end

    while i > 0 and i <= MaxUnitBars do
      local UBFL = UnitBarsFList[i]
      if UBFL.Valid then
        local UBF = UBFL.UBF
        local UB = UBF.UnitBar
        local Scale = UB.Other.Scale

        local UBX = UB.x
        local UBY = UB.y
        local Width = UBF.Width * Scale
        local Height = UBF.Height * Scale

        -- Do left/right alignment if doing vertical.
        if Flip == -1 then
          local XOffset = 0
          if Align == 'right' then
            XOffset = AWidth - Width
          end
          UBX = x + XOffset

        -- do top/bottom alignment if doing horizontal.
        else
          local YOffset = 0
          if Align == 'bottom' then
            YOffset = (AHeight - Height) * -1
          end
          UBY = y + YOffset
        end

        -- Check for padding
        if PadEnabled then
          if Flip == -1 then

            -- Set the Y location before changing it if the direction is going down.
            if Direction == -1 then
              UBY = y
            end

            -- Increment the Y based on Direction
            y = y + (Height + Padding) * Direction

            -- Set the Y location after its changed if the direction is going up.
            if Direction == 1 then
              UBY = y
            end
          else

            -- Set the X location before changing it if the direction is going down.
            if Direction == 1 then
              UBX = x
            end

            -- Increment the X based on Direction
            x = x + (Width + Padding) * Direction

            -- Set the X location after its changed if the direction is going up.
            if Direction == -1 then
              UBX = x
            end
          end
        end

        -- Update the unitbars location based on the scale.
        UB.x = UBX
        UB.y = UBY
        local Anchor = UBF.Anchor

        Anchor:ClearAllPoints()
        Anchor:SetPoint('TOPLEFT', UBX, UBY)
      end
      i = i + Direction * Flip
    end
  end
end

-------------------------------------------------------------------------------
-- CreateFadeOut
--
-- Creates a fadeout animation group
--
-- Usage FadeOut, FadeOutA = CreateFadeOut(Frame)
--
-- Frame       Frame that the fadeout is being created for.
--
-- FadeOut     The fadeout animation group.
-- FadeOutA    The fadeout animation.
-------------------------------------------------------------------------------
function GUB.Main:CreateFadeOut(Frame)

  -- Create an animation for fade out.
  local FadeOut = Frame:CreateAnimationGroup()
  local FadeOutA = FadeOut:CreateAnimation('Alpha')

  -- Set the animation group values.
  FadeOut:SetLooping('NONE')
  FadeOutA:SetChange(-1)
  FadeOutA:SetOrder(1)

  return FadeOut, FadeOutA
end

-------------------------------------------------------------------------------
-- SetTimer
--
-- Will call a function based on a delay.
--
-- To start a timer
--   usage: SetTimer(Frame, Delay, TimerFn)
-- To stop a timer
--   usage: SetTimer(Frame, nil)
--
-- Object   Object the timer is attached to. Can be anything, numbers, tables, functions, etc.
-- Delay    Amount of time to delay after each call to Fn()
-- TimerFn  Function to be added. If nil then the timer will be stopped.
--
-- NOTE:  TimerFn will be called as TimerFn(Frame, Elapsed) from AnimationGroup in StartTimer()
--        See CreateUnitBarTimers() on how this is used.
--
--        To reduce garbage.  Only a new StartTimer() will get created when a new object is passed.
--
--        I decided to do it this way because the overhead of using indexed
--        arrays for multiple timers ended up using more cpu.
---------------------------------------------------------------------------------
function GUB.Main:SetTimer(Object, Delay, TimerFn)
  local AnimationGroup = nil
  local Animation = nil

  Object.SetTimer = Object.SetTimer or function(Start, Delay, TimerFn2)

    -- Create an animation Group timer if one doesn't exist.
    if AnimationGroup == nil then
      AnimationGroup = CreateFrame('Frame'):CreateAnimationGroup()
      Animation = AnimationGroup:CreateAnimation('Animation')
      Animation:SetOrder(1)
      AnimationGroup:SetLooping('REPEAT')
      AnimationGroup:SetScript('OnLoop' , function(self) TimerFn(Object, self:GetDuration()) end )
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
    Object.SetTimer(true, Delay, TimerFn)
  else

    -- Stop timer since no function was passed.
    Object.SetTimer(false)
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
    Tier = ES[GetInventoryItemID('player', Slot)]
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
-- Usage: Found = CheckAura(Condition, ...)
--
-- Condition    'a' for 'and' or 'o' for 'or'.  If 'a' is specified then all
--              auras have to be active.  If 'o' then only one of the auras needs
--              to be active.
-- ...          One or more auras specified as a SpellID.
--
-- Found        Returns true if condition 'a' is used and all auras were found.
--              Returns the SpellID of the aura found if condition 'o' is used.
-------------------------------------------------------------------------------
function GUB.Main:CheckAura(Condition, ...)
  local Name = nil
  local SpellID = 0
  local MaxSpellID = select('#', ...)
  local Found = 0
  local i = 1
  repeat
    Name, _, _, _, _, _, _, _, _, _, SpellID = UnitBuff('player', i)
    if Name then
      for i = 1, MaxSpellID do
        if SpellID == select(i, ...) then
          Found = Found + 1
          break
        end
      end
      if Condition == 'o' and Found > 0 then
        return SpellID
      end
    end
    i = i + 1
  until Name == nil or Found == MaxSpellID
  return Found == MaxSpellID
end

-------------------------------------------------------------------------------
-- ModifyPredictedSpellStack
--
-- Adds/removes spells from the spell stack. Or checks for timeouts on the stack.

-- usage: ModifyPredictedSpellStack(Action, SpellID)
--
-- Action          'add'     Will add a spell.
--                 'remove   will remove spell.
--                 'timeout' will remove all spells that have timed out.
-- SpellID         Used for 'add' or 'remove'.
-------------------------------------------------------------------------------
local function RemovePredictedSpellStack(Index)
  local PST = nil
  for Index2 = Index, PredictedSpellCount - 1 do
    PST = PredictedSpellStack[Index2]
    PST.SpellID = PredictedSpellStack[Index2 + 1].SpellID
    PST.Time = PredictedSpellStack[Index2 + 1].Time
  end
  PST = PredictedSpellStack[PredictedSpellCount]
  PST.SpellID = 0
  PST.Time = 0
  PredictedSpellCount = PredictedSpellCount - 1
end

local function ModifyPredictedSpellStack(Action, SpellID)
  if Action == 'add' then
    PredictedSpellCount = PredictedSpellCount + 1
    local PST = PredictedSpellStack[PredictedSpellCount]
    if PST then
      PST.SpellID = SpellID
      PST.Time = GetTime()
    else

      -- Create an entry if one doesn't exist.
      PredictedSpellStack[PredictedSpellCount] = {SpellID = SpellID, Time = GetTime()}
    end
  elseif Action == 'remove' and SpellID > 0 then
    local Index = 0
    local Found = false
    local SpellID2 = 0

    while not Found and Index < PredictedSpellCount do
      Index = Index + 1
      Found = PredictedSpellStack[Index].SpellID == SpellID
    end
    if Found then
      RemovePredictedSpellStack(Index)
    end
  elseif Action == 'timeout' and PredictedSpellCount > 0 then
    local Time = 0
    repeat
      Time = GetTime() - PredictedSpellStack[1].Time
      if Time > PredictedSpellStackTimeout then
        RemovePredictedSpellStack(1)
      end
    until Time < PredictedSpellStackTimeout or PredictedSpellCount == 0
  end
end

-------------------------------------------------------------------------------
-- GetPredictedSpell
--
-- Returns a predicted powerID.
--
-- usage: SpellID = GetPredictedSpell(Index)
--
-- Index        Ranged from 1 onward.  1 would return the first ID of a spell in flight or being cast.
--
-- SpellID      Returns the spell ID or 0 for no spell.
--
-- NOTE:  So if there was 2 spells in flight and one casting.  Then using an index of 4 would
--        return 0.  See eclipsebar.lua on how this is used.
--        Spells that been flying too long are removed here.  This way SetPredictedSpell() doesn't have
--        to check for every event.
-------------------------------------------------------------------------------
function GUB.Main:GetPredictedSpell(Index)

  -- Register events if the wait time expired.
  if PredictedSpellsTime == 0 then
    RegisterEvents('register', 'predictedspells')

    -- Remove any casting spell left over.
    PredictedSpellCasting.SpellID = 0
    PredictedSpellCasting.LineID = -1
  end
  PredictedSpellsTime = PredictedSpellsWaitTime

  ModifyPredictedSpellStack('timeout')
  if Index > PredictedSpellCount then
    if Index == PredictedSpellCount + 1 then
      return PredictedSpellCasting.SpellID
    else
      return 0
    end
  else
    return PredictedSpellStack[Index].SpellID
  end
end

-------------------------------------------------------------------------------
-- SetPredictedSpells
--
-- Adds a spellID to the list for predicted spells.
--
-- usage: SetPredictedSpells(SpellID, Flight, Energized, Fn)
--
-- SpellID       ID of the spell to track.
-- Flight        if true the spell can be tracked till it reaches its target.
-- Fn            See SetPredictedSpell() and Eclipse.lua on how Fn() is used.
-------------------------------------------------------------------------------
function GUB.Main:SetPredictedSpells(SpellID, Flight, Fn)
  local PS = {Flight = Flight, Fn = Fn}
  PredictedSpells[SpellID] = PS
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
  local Angle = math.rad(Angle)
  if math.sin(Angle) < 0 then
    XOffset = -XOffset
  end
  if math.cos(Angle) < 0 then
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
--                  reference the local table in main.lua
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
-- AnimationFadeOut
--
-- Starts or finishes an alpha animation fade out.
--
-- Usage:  AnimationFadeOut(AG, Action, Fn)
--
-- AG        Must be an alpha animation group.
-- Action    'start'   Starts the animation for fading out.
--           'finish'  Finish the animation for fadeout early.
--                     This will call Fn() only if AG was playing.
-- Fn        Function to call after the animation fades out.
--           If set to nil then does nothing.
-------------------------------------------------------------------------------
function GUB.Main:AnimationFadeOut(AG, Action, Fn)

  -- Stop animation if its playing
  if AG:IsPlaying() then

    -- Disable the animation script.
    AG:SetScript('OnFinished', nil)
    AG:Stop()

    -- Call the function.
    if Fn then
      Fn()
    end
  end
  if Action == 'start' then
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
-------------------------------------------------------------------------------
local function HideUnitBar(UnitBarF, HideBar, FinishFadeOut)
  local FadeOut = UnitBarF.FadeOut
  local Anchor = UnitBarF.Anchor

  if HideBar and not UnitBarF.Hidden then

    -- Cancel any animations playing inside this bar.
    UnitBarF:CancelAnimation()

    if UnitBars.FadeOutTime > 0 then

      -- Start the animation fadeout.
      Main:AnimationFadeOut(FadeOut, 'start', function() Anchor:Hide() end)
    else
      Anchor:Hide()
    end
    UnitBarF.Hidden = true
  else
    if not HideBar and UnitBarF.Hidden then
      if UnitBars.FadeOutTime > 0 then

        -- Finish the animation fade out if its still playing.
        Main:AnimationFadeOut(FadeOut, 'finish')
      end
      Anchor:Show()
      UnitBarF.Hidden = false
    end
  end
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
  if not Hide then
    GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
    GameTooltip:AddLine(self.TooltipName)
    if not UnitBars.HideTooltipsDesc then
      if self.TooltipDesc then
        GameTooltip:AddLine(self.TooltipDesc, 1, 1, 1)
      end
      if self.TooltipDesc2 then
        GameTooltip:AddLine(self.TooltipDesc2, 1, 1, 1)
      end
    end
    GameTooltip:Show()
  else
    GameTooltip:Hide()
  end
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
-- NOTES:  Spells with cast times, flight times, and instant cast spells are tracked.
--         When a spell has a cast time, it's set to PredictedSpellCasting.
--         When a spell is done casting or was an instant. It's then added to the PredictedSpellStack.
--         And removed from the PredictedSpellCasting if it wasn't instant otherwise it was never
--         added to PredictedSpellCasting.
--
--         When a spell is flagged as not requiring a flight time.  Then its never added to the stack.
--         Each time a spell is retrieved thru GetPredictedSpell().  A timeout check is done.  Any spells
--         on the stack will be removed if they've been on the stack longer than PredictedSpellStackTimeout.
--
--         Timeouts are used so only events SPELL_DAMAGE, SPELL_MISS, and SPELL_ENERGIZE needs to be tracked.
--         If one of those events didn't happen, then the timeout will remove the spell.
--
--         See the notes at the top of the file about Predicted Spells.
--
--         Fn() will only get called on SPELL_ENERGIZE or SPELL_DAMAGE.  If Fn() gets called on
--         an energize event.  Then Fn() needs to return a spellID to remove the spell from the stack
--         otherwise 0 to leave it.
--         If its a SPELL_DAMAGE event then Fn() needs to return true to remove the spell from
--         the stack.  Otherwise false to leave it. See Eclipse.lua on how this is used.
--
--         The only thing I couldn't account for is when you already cast a spell and then cast
--         a second spell that has no travel time.  Theres no way to figure out ahead of time if that
--         new spell will hit the target before the previous one.
--
--         Hopefully blizzard will add a way to get predicted spells from the server.
-------------------------------------------------------------------------------
local function SetPredictedSpell(Event, TimeStamp, SpellID, LineID, Message)
  local PSE = PredictedSpellEvent[Event]

  if PSE ~= nil then
    local PS = PredictedSpells[SpellID]

    -- Check for valid spellID.
    if PS ~= nil then
      local Flight = PS.Flight

      -- Detect start cast.
      if PSE == EventSpellStart then

        -- Set casting spell.
        PredictedSpellCasting.SpellID = SpellID
        PredictedSpellCasting.LineID = LineID
      end

      -- Detect instant spell or finished casting.
      if PSE == EventSpellSucceeded then

        -- Convert spell into a flying spell if the flight flag is true.
        if Flight then
          ModifyPredictedSpellStack('add', SpellID)
        end
      end

      -- Remove casting spell or a failed casting spell.
      if PSE == EventSpellSucceeded and LineID == PredictedSpellCasting.LineID or
         PSE == EventSpellFailed and PredictedSpellMessage[Message] == nil then
        PredictedSpellCasting.SpellID = 0
        PredictedSpellCasting.LineID = -1
      end

      if PSE == EventSpellDamage or PSE == EventSpellEnergize or PSE == EventSpellMissed then
        local Fn = PS.Fn

        -- Call user defined function to see which spell to remove from stack.
        -- This is only gets called for energize event.
        -- Fn() must return a SpellID or -1 if no spell is to be removed.
        if PSE == EventSpellEnergize and Fn then
          SpellID = Fn(SpellID, Message)
        end

        -- Call user defined function for a spell damage event.
        -- Fn() must return true or false.
        if PSE == EventSpellDamage and Fn and not Fn(SpellID, Message) then
          return
        end

        -- Search for a flying spell to remove.
        ModifyPredictedSpellStack('remove', SpellID)
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
  if Unit == 'player' then
    SetPredictedSpell(Event, nil, SpellID, LineID, '')
  end
end

-------------------------------------------------------------------------------
-- UpdateUnitBars
--
-- Displays all the unitbars unless Event, Unit are specified.
-------------------------------------------------------------------------------
local function UpdateUnitBars(Event, ...)
  for _, UBF in pairs(UnitBarsF) do
    UBF:Update(Event, ...)
  end
end

-------------------------------------------------------------------------------
-- UnitBarsUpdate
--
-- Event handler for updating the unitbars. Also can be used to update all bars.
--
-- Usage: UnitBarsUpdate()
--
--   Updates all unitbars.
--
-- Usage: UnitBarsUpdate(Event, ...)
--
--   Update the unitbars that match Event and ...
-------------------------------------------------------------------------------
function GUB:UnitBarsUpdate(Event, ...)
  UpdateUnitBars(Event, ...)
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

  -- Set the vehicle and combat flags
  InCombat = UnitAffectingCombat('player') == 1
  InVehicle = UnitHasVehicleUI('player')
  IsDead = UnitIsDeadOrGhost('player') == 1
  HasTarget = UnitExists('target') == 1
  HasFocus = UnitExists('focus') == 1
  HasPet = select(1, HasPetUI()) ~= nil
  for _, UBF in pairs(UnitBarsF) do
    UBF:StatusCheck()

    -- Update incase some unitbars went from disabled to enabled.
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

  -- Check to see if shift/alt/control and left button are held down
  if Button ~= 'LeftButton' or not IsModifierKeyDown() then
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
-- UnitBar assigned functions
--
-- Usage: UnitBarsF[BarType]:Update(Event, ...)
--
--    This function can take a variable number of parameters that get passed from
--    the event handler.  The unitbar that its called on checks to see if the
--    event data matches with what that unitbar is suppose to show.  If it doesn't then
--    the unitbar will not be updated.
--
-- Usage: UnitBarsF[BarType]:Update()
--
--    This will just update the bar, no checks are done.
--    If 'change' is specified as a parameter, bars that look for this flag will only update
--    if there is change.
--
-- Usage: UnitBarsF[BarType]:StatusCheck()
--
--    Check the status of the unitbar frame.
--
-- Usage: UnitBarsF[BarType]:FrameSetScript(Enable)
--
--    Sets up scripts for the unitbar frame.
--    Enable    If true then scripts get enabled otherwise disabled.
--
-- Usage: UnitBarsF[BarType]:EnableScreenClamp(Enable)
--
--    Clamps the current unitbar to the screen.

-- Usage: UnitBarsF[BarType]:EnableMouseClicks(Enable)
--
--    Sets up mouse clicks to be captured for this unitbar frame.
--
-- Usage: UnitBarsF[BarType]:SetAttr(Object, Attr)
--
--    Look at SetAttr assigned functions.
--
-- Usage: UnitBarsF[BarType]:SetLayout()
--
--    Updates the layout of the bar.
--
-- Usage: UnitBarsF[BarType]:CancelAnimation()
--
--    Cancels any animation for this bar, otherwise it does nothing.
--
-- NOTE: Any function labled as a unitbar assigned function shouldn't be called directly.
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- StatusCheckShowNever (StatusCheck) [UnitBar assigned function]
--
-- Disables the unitbar frame if the ShowNever flag is set.
-- Returns true if the unitbar was enabled.
-------------------------------------------------------------------------------
local function StatusCheckShowNever(UnitBarF)

  -- Enable the unitbar frame if the ShowNever flag is not set.
  UnitBarF.Enabled = not UnitBarF.UnitBar.Status.ShowNever

  return UnitBarF.Enabled
end

-------------------------------------------------------------------------------
-- StatusCheckShowHide (StatusCheck) [UnitBar assigned function]
--
-- Checks the status on the unitbar frame to see if it should be shown/hidden.
-------------------------------------------------------------------------------
local function StatusCheckShowHide(UnitBarF)
  local ShowUnitBar = UnitBarF.Enabled
  local UB = UnitBarF.UnitBar
  local Status = UB.Status

  if ShowUnitBar then

    -- Hide if the HideWhenDead status is set.
    if IsDead and Status.HideWhenDead then
      ShowUnitBar = false

    -- Hide if in a vehicle if the HideInVehicle status is set
    elseif InVehicle and Status.HideInVehicle then
      ShowUnitBar = false

    -- Show the unitbar if ShowAlways status is set.
    elseif Status.ShowAlways then
      ShowUnitBar = true

    -- Get the idle status based on HideNotActive when not in combat.
    elseif not InCombat and Status.HideNotActive then
      ShowUnitBar = UnitBarF.IsActive

    -- Hide if not in combat with the HideNoCombat status.
    elseif not InCombat and Status.HideNoCombat then
      ShowUnitBar = false
    end
  end

  -- Make all unitbars visible when they are not locked. Can't override ShowNever.
  if not UnitBars.IsLocked and not Status.ShowNever then
    ShowUnitBar = true
  end

  -- Hide/show the unitbar.
  HideUnitBar(UnitBarF, not ShowUnitBar)
end

-------------------------------------------------------------------------------
-- StatusCheckTarget (StatusCheck) [UnitBar assigned function]
--
-- Disable/Enable the target unitbar frame.
-------------------------------------------------------------------------------
local function StatusCheckTarget(UnitBarF)
  if StatusCheckShowNever(UnitBarF) then

    -- If the player has a target then enable this unitbar frame.
    UnitBarF.Enabled = HasTarget
  end
  StatusCheckShowHide(UnitBarF)
end

-------------------------------------------------------------------------------
-- StatusCheckFocus (StatusCheck) [UnitBar assigned function]
--
-- Disable/Enable the focus unitbar frame.
-------------------------------------------------------------------------------
local function StatusCheckFocus(UnitBarF)
  if StatusCheckShowNever(UnitBarF) then

    -- If the player has a focus then enable this unitbar frame.
    UnitBarF.Enabled = HasFocus
  end
  StatusCheckShowHide(UnitBarF)
end

-------------------------------------------------------------------------------
-- StatusCheckPet (StatusCheck) [UnitBar assigned function]
--
-- Disable/Enable the pet unitbar frame.
-------------------------------------------------------------------------------
local function StatusCheckPet(UnitBarF)
  if StatusCheckShowNever(UnitBarF) then

    -- If the player has a pet then enable this unitbar frame.
    UnitBarF.Enabled = HasPet
  end
  StatusCheckShowHide(UnitBarF)
end

-------------------------------------------------------------------------------
-- StatusCheckMainPower (StatusCheck) [UnitBar assigned function]
--
-- Disable/Enable the mainpower unitbar frame.
-------------------------------------------------------------------------------
local function StatusCheckMainPower(UnitBarF)
  if StatusCheckShowNever(UnitBarF) then

    -- Enable the mainpower bar if the player is in a different form.
    UnitBarF.Enabled = PlayerPowerType ~= select(2, UnitPowerType('player'))
  end
  StatusCheckShowHide(UnitBarF)
end

-------------------------------------------------------------------------------
-- StatusCheckEclipse (StatusCheck) [UnitBar assigned function]
--
-- Disable/Enable the Eclipsebar.
-------------------------------------------------------------------------------
local function StatusCheckEclipse(UnitBarF)
  if StatusCheckShowNever(UnitBarF) then
    local Form = GetShapeshiftFormID()

    -- Enable the Eclipse bar if the player is a druid, is in normal or moonkin form and is speced balance.
    UnitBarF.Enabled = PlayerClass == 'DRUID' and (Form == MoonkinForm or not Form) and GetPrimaryTalentTree() == 1
  end
  StatusCheckShowHide(UnitBarF)
end

-------------------------------------------------------------------------------
-- SetFunction
--
-- Sets a function to a list of bartypes in the function table.
-- This is only used with the function below.
--
-- Usage: SetFunction(Func, FunctionName, Fn, ...)
--
-- Func          The function table.
-- FunctionName  The name of the function to assign to each bartype.
-- Fn            The function to assign to each bartype.
-- ...           List of bartypes.
-------------------------------------------------------------------------------
local function SetFunction(Func, FunctionName, Fn, ...)
  for i = 1, select('#', ...) do
    Func[select(i, ...)][FunctionName] = Fn
  end
end

-------------------------------------------------------------------------------
-- UnitBarsAssignFunctions
--
-- Assigns the functions to all of the unitbars.
-- This function is only called once.
-- The functions in here are only added to the unitbar if its found in the
-- unitbarf table.
-------------------------------------------------------------------------------
local function UnitBarsAssignFunctions()

  -- Build a temporary function table.
  local Func = {}
  for BarType, UB in pairs(Defaults.profile) do
    if type(UB) == 'table' then
      Func[BarType] = {}
    end
  end

  -- Update functions.

  local n = 'Update'  -- UnitBarF[]:Update(Event, Unit, [...])
  local f = nil
  local DoNothing = function() return end

  local UpdateHealthBar  = GUB.HapBar.UpdateHealthBar
  local UpdatePowerBar   = GUB.HapBar.UpdatePowerBar
  local UpdateRuneBar    = GUB.RuneBar.UpdateRuneBar
  local UpdateComboBar   = GUB.ComboBar.UpdateComboBar
  local UpdateHolyBar    = GUB.HolyBar.UpdateHolyBar
  local UpdateShardBar   = GUB.ShardBar.UpdateShardBar
  local UpdateEclipseBar = GUB.EclipseBar.UpdateEclipseBar

  local PowerMana = PowerTypeToNumber['MANA']

  Func.PlayerHealth[n] = function(self, Event)
                           if self.Enabled then
                             UpdateHealthBar(self, Event, 'player')
                           end
                         end
  Func.PlayerPower[n]  = function(self, Event)
                           if self.Enabled then
                             UpdatePowerBar(self, Event, 'player', nil, PlayerClass)
                           end
                         end
  Func.TargetHealth[n] = function(self, Event)
                           if self.Enabled then
                             UpdateHealthBar(self, Event, 'target')
                           end
                         end
  Func.TargetPower[n]  = function(self, Event)
                           if self.Enabled then
                             UpdatePowerBar(self, Event, 'target')
                           end
                         end
  Func.FocusHealth[n]  = function(self, Event)
                           if self.Enabled then
                             UpdateHealthBar(self, Event, 'focus')
                           end
                          end
  Func.FocusPower[n]   = function(self, Event)
                           if self.Enabled then
                             UpdatePowerBar(self, Event, 'focus')
                           end
                         end
  Func.PetHealth[n]    = function(self, Event)
                           if self.Enabled then
                             UpdateHealthBar(self, Event, 'pet')
                           end
                         end
  Func.PetPower[n]     = function(self, Event)
                           if self.Enabled then
                             UpdatePowerBar(self, Event, 'pet')
                           end
                         end
  Func.MainPower[n]    = function(self, Event)
                           if self.Enabled then
                             UpdatePowerBar(self, Event, 'player', PowerMana)
                           end
                         end
  Func.RuneBar[n]      = function(self, Event, ...)
                           if self.Enabled then
                             UpdateRuneBar(self, Event, ...)
                           end
                         end
  Func.ComboBar[n]     = function(self, Event)
                           if self.Enabled then
                             UpdateComboBar(self, Event)
                           end
                         end
  Func.HolyBar[n]      = function(self, Event)
                           if self.Enabled then
                             UpdateHolyBar(self, Event)
                           end
                         end
  Func.ShardBar[n]     = function(self, Event)
                           if self.Enabled then
                             UpdateShardBar(self, Event)
                           end
                         end
  Func.EclipseBar[n]   = function(self, Event)
                           if self.Enabled then
                             UpdateEclipseBar(self, Event)
                           end
                         end

  -- StatusCheck functions.
  n = 'StatusCheck'  -- UnitBarF[]:StatusCheck()
  f = function(self)
        StatusCheckShowNever(self)
        StatusCheckShowHide(self)
      end

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'RuneBar', 'HolyBar', 'ShardBar')
  SetFunction(Func, n, StatusCheckTarget, 'TargetHealth', 'TargetPower', 'ComboBar')
  SetFunction(Func, n, StatusCheckFocus, 'FocusHealth', 'FocusPower')
  SetFunction(Func, n, StatusCheckMainPower, 'MainPower')
  SetFunction(Func, n, StatusCheckPet, 'PetHealth', 'PetPower')
  SetFunction(Func, n, StatusCheckEclipse, 'EclipseBar')

  -- Enable mouse click functions.
  n = 'EnableMouseClicks' -- UnitBarF[]:EnableMouseClicks(Enable)
  f = GUB.HapBar.EnableMouseClicksHap

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'TargetHealth', 'TargetPower',
                          'FocusHealth', 'FocusPower', 'PetHealth', 'PetPower', 'MainPower')
  SetFunction(Func, n, GUB.RuneBar.EnableMouseClicksRune, 'RuneBar')
  SetFunction(Func, n, GUB.ComboBar.EnableMouseClicksCombo, 'ComboBar')
  SetFunction(Func, n, GUB.HolyBar.EnableMouseClicksHoly, 'HolyBar')
  SetFunction(Func, n, GUB.ShardBar.EnableMouseClicksShard, 'ShardBar')
  SetFunction(Func, n, GUB.EclipseBar.EnableMouseClicksEclipse, 'EclipseBar')

  -- Enable clamp to screen functions.
  n = 'EnableScreenClamp' -- UnitBarF[]:EnableScreenClamp(Enable)
  f = GUB.HapBar.EnableScreenClampHap

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'TargetHealth', 'TargetPower',
                          'FocusHealth', 'FocusPower', 'PetHealth', 'PetPower', 'MainPower')
  SetFunction(Func, n, GUB.RuneBar.EnableScreenClampRune, 'RuneBar')
  SetFunction(Func, n, GUB.ComboBar.EnableScreenClampCombo, 'ComboBar')
  SetFunction(Func, n, GUB.HolyBar.EnableScreenClampHoly, 'HolyBar')
  SetFunction(Func, n, GUB.ShardBar.EnableScreenClampShard, 'ShardBar')
  SetFunction(Func, n, GUB.EclipseBar.EnableScreenClampEclipse, 'EclipseBar')

  -- Set script functions.
  n = 'FrameSetScript'  -- UnitBarF[]:FrameSetScript(Enable)
  f = GUB.HapBar.FrameSetScriptHap

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'TargetHealth', 'TargetPower',
                          'FocusHealth', 'FocusPower', 'PetHealth', 'PetPower', 'MainPower')
  SetFunction(Func, n, GUB.RuneBar.FrameSetScriptRune, 'RuneBar')
  SetFunction(Func, n, GUB.ComboBar.FrameSetScriptCombo, 'ComboBar')
  SetFunction(Func, n, GUB.HolyBar.FrameSetScriptHoly, 'HolyBar')
  SetFunction(Func, n, GUB.ShardBar.FrameSetScriptShard, 'ShardBar')
  SetFunction(Func, n, GUB.EclipseBar.FrameSetScriptEclipse, 'EclipseBar')

  -- Set attribute functions.
  n = 'SetAttr' -- UnitBarF[]:SetAttr(Object, Attr)
  f = GUB.HapBar.SetAttrHap

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'TargetHealth', 'TargetPower',
                          'FocusHealth', 'FocusPower', 'PetHealth', 'PetPower', 'MainPower')
  SetFunction(Func, n, GUB.RuneBar.SetAttrRune, 'RuneBar')
  SetFunction(Func, n, GUB.ComboBar.SetAttrCombo, 'ComboBar')
  SetFunction(Func, n, GUB.HolyBar.SetAttrHoly, 'HolyBar')
  SetFunction(Func, n, GUB.ShardBar.SetAttrShard, 'ShardBar')
  SetFunction(Func, n, GUB.EclipseBar.SetAttrEclipse, 'EclipseBar')

  -- Set layout functions.
  n = 'SetLayout' -- UnitBarF[]:SetLayout()
  f = GUB.HapBar.SetLayoutHap

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'TargetHealth', 'TargetPower',
                          'FocusHealth', 'FocusPower', 'PetHealth', 'PetPower', 'MainPower')
  SetFunction(Func, n, GUB.RuneBar.SetLayoutRune, 'RuneBar')
  SetFunction(Func, n, GUB.ComboBar.SetLayoutCombo, 'ComboBar')
  SetFunction(Func, n, GUB.HolyBar.SetLayoutHoly, 'HolyBar')
  SetFunction(Func, n, GUB.ShardBar.SetLayoutShard, 'ShardBar')
  SetFunction(Func, n, GUB.EclipseBar.SetLayoutEclipse, 'EclipseBar')

  -- Set the cancel animation functions.
  n = 'CancelAnimation' -- UnitBarF[]:CancelAnimation()

  SetFunction(Func, n, DoNothing, 'PlayerHealth', 'PlayerPower', 'TargetHealth', 'TargetPower',
                                  'FocusHealth', 'FocusPower', 'PetHealth', 'PetPower', 'MainPower',
                                  'RuneBar')
  SetFunction(Func, n, GUB.ComboBar.CancelAnimationCombo, 'ComboBar')
  SetFunction(Func, n, GUB.HolyBar.CancelAnimationHoly, 'HolyBar')
  SetFunction(Func, n, GUB.ShardBar.CancelAnimationShard, 'ShardBar')
  SetFunction(Func, n, GUB.EclipseBar.CancelAnimationEclipse, 'EclipseBar')

  -- Add the functions to the unitbars frame table.
  for BarType, UBF in pairs(UnitBarsF) do
    for FuncName, FuncCall in pairs(Func[BarType]) do
      UBF[FuncName] = Func[BarType][FuncName]
    end
  end
end

--*****************************************************************************
--
-- Unitbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UnitBarsSetAllOptions
--
-- Handles the settings that effect all the unitbars.
--
-- Usage: UnitBarSetAllOption()
--
-- Activates the current settings in UnitBars.
--
-- IsLocked
-- IsClamped
-- FadeOutTime
-------------------------------------------------------------------------------
function GUB.Main:UnitBarsSetAllOptions()

  -- Apply the settings.
  for _, UBF in pairs(UnitBarsF) do
    UBF:EnableMouseClicks(not UnitBars.IsLocked)
    UBF:EnableScreenClamp(UnitBars.IsClamped)
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

  for BarType, UnitBarF in pairs(UnitBarsF) do
    local UB = UnitBars[BarType]
    local Anchor = UnitBarF.Anchor
    local ScaleFrame = UnitBarF.ScaleFrame

    -- Stop any old fadeout animation for this unitbar.
    UnitBarF:CancelAnimation()
    Main:AnimationFadeOut(UnitBarF.FadeOut, 'finish')

    -- Set the anchor position and size.
    Anchor:ClearAllPoints()
    Anchor:SetPoint('TOPLEFT' , UB.x, UB.y)
    Anchor:SetWidth(1)
    Anchor:SetHeight(1)

    -- Set scaleframe width/height.
    ScaleFrame:ClearAllPoints()
    ScaleFrame:SetPoint('TOPLEFT', 0, 0)
    ScaleFrame:SetWidth(1)
    ScaleFrame:SetHeight(1)

    -- Set a reference in the unitbar frame to UnitBars[BarType] and Anchor.
    UnitBarF.UnitBar = UB
    Anchor.UnitBar = UB

    -- Set the layout for the bar.
    UnitBarF:SetLayout()

    -- Set the IsActive flag to true.
    UnitBarF.IsActive = false

    -- Disable the unitbar.
    UnitBarF.Enabled = false

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

  for BarType, UB in pairs(Defaults.profile) do
    if type(UB) == 'table' then
      local UnitBarF = {}

      -- Create the anchor frame.
      local Anchor = CreateFrame('Frame', nil, UnitBarsParent)

      -- Hide the anchor
      Anchor:Hide()

      -- Make the unitbar's anchor movable.
      Anchor:SetMovable(true)

      -- Create the scale frame.
      local ScaleFrame = CreateFrame('Frame', nil, Anchor)

      if stringfind(BarType, 'Health') or stringfind(BarType, 'Power') then
        GUB.HapBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
      else
        GUB[BarType]:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
      end

      if next(UnitBarF) then

        -- Create an animation for fade out.
        local FadeOut, FadeOutA = Main:CreateFadeOut(Anchor)

        -- Save the animation to the unitbar frame.
        UnitBarF.FadeOut = FadeOut
        UnitBarF.FadeOutA = FadeOutA

        -- Save the bartype.
        UnitBarF.BarType = BarType

        -- Save the anchor.
        UnitBarF.Anchor = Anchor

        -- Save the scale frame.
        UnitBarF.ScaleFrame = ScaleFrame

        UnitBarsF[BarType] = UnitBarF
      end
    end
  end
  UnitBarsAssignFunctions()
end

-------------------------------------------------------------------------------
-- CreateUnitBarTimers
--
-- All unitbars are controlled thru SetTimer()
-------------------------------------------------------------------------------
local function CreateUnitBarTimers()
  local HapBarsF = {}
  local OtherBarsF = {}
  local OtherBarsTime = 0
  local HapBarsCount = 0
  local OtherBarsCount = 0

  -- Timer for updating health and power bars and keeping track of predicted spells.
  local function UnitBarsTimer(self, Elapsed)

    -- Turn off the events for Predicted spells if they're
    -- not used after a certain amount of time.
    if PredictedSpellsTime > 0 then
      PredictedSpellsTime = PredictedSpellsTime - Elapsed
      if PredictedSpellsTime == 0 then
        PredictedSpellsTime = -1
      end
    end
    if PredictedSpellsTime < 0 then
      RegisterEvents('unregister' , 'predictedspells')
      PredictedSpellsTime = 0
    end

    -- Update health and power bars if there is change.
    for i = 1, HapBarsCount do
      HapBarsF[i]:Update('change')
    end

    -- Update other bars at 4 times per second.
    OtherBarsTime = OtherBarsTime + 1
    if OtherBarsTime == 3 then
      OtherBarsTime = 0
      for i = 1, OtherBarsCount do
        OtherBarsF[i]:Update('change')
      end
    end
  end

  -- For speed store reference of bars into an indexed array.
  local Index = 0
  for BarType, UBF in pairs(UnitBarsF) do
    if stringfind(BarType, 'Health') or stringfind(BarType, 'Power') then
      HapBarsCount = HapBarsCount + 1
      HapBarsF[HapBarsCount] = UBF
    else
      OtherBarsCount = OtherBarsCount + 1
      OtherBarsF[OtherBarsCount] = UBF
    end
  end

  -- Create health and power bars timer.
  Main:SetTimer(CreateFrame('Frame'), UnitBarDelay, UnitBarsTimer)
end

--*****************************************************************************
--
-- Addon Enable/Disable functions
--
-- Placed at the bottom was tired of doing function forwarding.
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Profile management
-------------------------------------------------------------------------------
function GUB:ProfileChanged(Event, Database, NewProfileKey)

  -- set Unitbars to the new database.
  UnitBars = Database.profile

  -- Set unitbars to the new profile in options.lua.
  GUB.Options:SendOptionsData(UnitBars, nil, nil)

  GUB:OnEnable()
end

-------------------------------------------------------------------------------
-- SharedMedia management
-------------------------------------------------------------------------------
function GUB:MediaUpdate(Name, MediaType, Key)
  for _, UBF in pairs(UnitBarsF) do
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

    -- Get the main power type for the player.
    PlayerPowerType = ClassToPowerType[PlayerClass]

    -- Get the globally unique identifier for the player.
    PlayerGUID = UnitGUID('player')

    -- Set PlayerClass and PlayerPowerType in options.lua
    GUB.Options:SendOptionsData(nil, PlayerClass, PlayerPowerType)

    -- Initialize the options panel.
    -- Delaying Options init to make sure PlayerClass is accessible first.
    GUB.Options:OnInitialize()

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

  -- Set unitbars to the new profile in options.lua.
  GUB.Options:SendOptionsData(UnitBars, nil, nil)

  -- Create the unitbars.
  CreateUnitBars()

  -- Create the unitbar timers.
  CreateUnitBarTimers()

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

  -- Initialize the events.
  RegisterEvents('register', 'main')

  -- Set the unitbars global settings
  Main:UnitBarsSetAllOptions()

  -- Set the unitbars status and show the unitbars.
  GUB:UnitBarsUpdateStatus()

--@do-not-package@
  GSB = GUB -- for debugging OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
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
