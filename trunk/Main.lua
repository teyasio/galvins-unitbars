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
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
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
LSM:Register('statusbar', 'GUB Empty', [[Interface\Addons\GalvinUnitBars\Textures\GUB_EmptyBar.tga]])

------------------------------------------------------------------------------
-- Unitbars frame layout and animation groups.
--
-- UnitBarsParent
--   Anchor
--     Fade
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
--   Fade                 - Table containing the fading animation groups/methods.  The groups are a child of Anchor.
--
--
-- UnitBarsF has methods which make changing the state of a bar easier.  This is done in the form of
-- UnitBarsF[BarType]:MethodCall().  BarType is used through out the mod.  Its the type of bar being referenced.
-- Search thru the code to see how these are used.
--
-- List of UninBarsF methods:
--
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
--   IsActive             - True, false, or 0.
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
-- DefaultFadeInTime      - Default fade in time for all bars and objects.
-- DefaultFadeOutTime     - Default fade out time for all bars and objects.
-- CooldownBarTimerDelay  - Delay for the cooldown timer bar measured in times per second.
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
-- DefaultBgTexture       - Default background texture for the backdrop and all bars.
-- DefaultBdTexture       - Default border texture for the backdrop and all bars.
-- DefaultStatusBarTexture- Default bar texture for the health and power bars.
--
-- PointCalc              - Table used by CalcSetPoint() to return a location inside a parent frame.
--
-- GetTextValuePercentFn  - Contains the function to do percent calculations. Gets set by
--                          GetTextValues() and called by SetTextValue().
--
-- RegEventFrames         - Table used by RegEvent()
--
-- Thousands              - Contains the digit group delimeter based on language.
-- BillionFormat
-- MillionFormat
-- ThousandFormat         - Used by NumberToDigitGroups()
--
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
-- ReverseFading          - True of false. If true then transition from fading in one direction then going to the other is smooth.
-- FadeOutTime            - Time in seconds before a bar completely goes hidden.
-- FadeInTime             - Time in seconds before a bar completely becomes visible.
-- Px, Py                 - The current location of the UnitBarsParent on the screen.
--
--
-- Fields found in all unitbars:
--
--   Name                 - Name of the bar.
--   Enabled              - If true bar can be used, otherwise disabled.  Will not appear in options.
--   BarVisible()         - Returns true or false.  This gets referenced by UnitBarsF. Not all bars use this.
--   UsedByClass          - If a bar doesn't have this key then any class can use the bar and be any spec or no spec.
--                          Contains the data for HideNotUsable flag.  Not all unitbars use this. This is also used for Enable Bar Options.
--                          Example1: {DRUID = '1234'}
--                            Class has to be druid and any of the 4 specs can be used.
--                          Example2: {DRUID = '12', DEATHKNIGHT = ''}
--                            Class has to be druid or deathknight.  Spec 1 or 2 on the druid has to be used. Deathknight, spec isn't checked.
--
--   x, y                 - Current location of the Anchor relative to the UnitBarsParent.
--   Status               - Table that contains a list of flags marked as true or false.
--                          If a flag is found true then a statuscheck will be done to see what the
--                          bar should do. Flags with a higher priority override flags with a lower.
--                          Flags from highest priority to lowest.
--                            HideNotUsable    Disables and hides the unitbar if the bar is not usable
--                                             by class and/or specialization.
--                                             Not everybar has this flag.  If one is present then
--                                             the bar has a UsedByClass table.
--                            HideWhenDead     Hide the unitbar when the player is dead.
--                            HideInVehicle    Hide the unitbar if in a vehicle.
--                            HideInPetBattle  Hide the unitbar if in a pet battle.
--                            HideNotActive    Hide the unitbar if its not active. Only checked out of combat.
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
--     PredictedHealth    - True or false.  Used by health bars only.
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
--     ReverseFill        - If true then the bar fills in the opposite direction.
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
--       Color            - Color used for all the energize borders when Color.All is true.
--         All            - True or false.  If true then all energize borders use the same color.
--       Color[1 to 8]    - Colors used for each energize border when Color.All is false.
--
--   Background           - Only used for cooldown bars.
--     PaddingAll         - True or false. If true then padding can be set with one value otherwise four.
--     BackdropSettings   - Contains the settings for background, border, and padding for each cooldown bar.
--                          This is used for cooldown bars only.
--     Color              - Color used for all the cooldown bars when Color.All is true
--       All              - True or false. If true then all cooldown bars use the same color.
--     Color[1 to 8]      - Colors used for each cooldown bar when Color.All is false.
--
--   Bar                  - Only used for cooldown bars.
--     Advanced           - True or false.  If true then you change the size of the bar in small steps.
--     RuneWidth          - Width of the cooldown bar.
--     RuneHeight         - Height of the cooldown bar.
--     FillDirection      - Changes the fill direction. 'VERTICAL' or 'HORIZONTAL'.
--     ReverseFill        - If true then the bar fills in the opposite direction.
--     RotateTexture      - True or false.  If true then the bar texture will be rotated 90 degree counter-clockwise
--                                          If false no rotation takes place.
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     Padding            - The amount of pixels to be added or subtracted from the bar texture.
--     StatusBarTexture   - Texture for the cooldown bar.
--     Color              - Current color of the cooldown bar.
--       All              - True or false.  If true then all cooldown bars use the same color.
--
--   Text
--     FontSettings       - Contains the settings for the text.
--     Color              - Current color of the text for the bar.
--       All              - True or false.  If true then all the combo boxes are set to one color.
--                                          If false then each combo box can be set a different color.
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
--     ComboFadeInTime    - Time in seconds for a combo point to become visible.
--     ComboFadeOutTime   - Time in seconds for a combo point to go invisible.
--
--   Background
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     BackdropSettings   - Contains the settings for background, border, and padding for each combo point box.
--     Color              - Contains just one background color for all the combo point boxes.
--       All              - True or false.  If true then all the combo boxes are set to one color.
--                                          If false then each combo box can be set a different color.
--                          Only works when Color.All is true.
--     Color[1 to 5]      - Contains the background colors of all the combo point boxes.
--
--   Bar
--     Advanced           - True or false.  If true then you change the size of the bar in small steps.
--     BoxWidth           - The width of each combo point box.
--     BoxHeight          - The height of each combo point box.
--     RotateTexture      - True or false.  If true then the bar texture will be rotated 90 degree counter-clockwise
--                                          If false no rotation takes place.
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     Padding            - Amount of padding on the forground of each combo point box.
--     StatusbarTexture   - Texture used for the forground of each combo point box.
--     Color              - Contains just one bar color for all the combo point boxes.
--       All              - True or false.  If true then all the combo boxes are set to one color.
--                                          If false then each combo box can be set a different color.
--                        - Only works when Color.All is true.
--     Color[1 to 5]      - Contains the bar colors of all the combo point boxes.
--
--
-- Holybar fields
--   General
--     BoxMode            - True or false.  If true the bar uses boxes instead of textures.
--     HolySize           - Size of the holy rune with and height.  Not used in Box Mode.
--     HolyPadding        - Amount of space between each holy rune.  Works in both modes.
--     HolyScale          - Scale of the rune without changing the holy bar size. Not used in box mode.
--     HolyFadeInTime     - Amount of time in seconds before a holy rune is lit. Works in both modes.
--     HolyFadeOutTime    - Amount of time in seconds before a holy rune goes dark.  Works in both modes.
--     HolyAngle          - Angle in degrees in which way the bar will be displayed.
--
--   Background
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     BackdropSettings   - Contains the settings for background, border, and padding for each holy rune box.
--                          When in box mode each holy box uses this setting.
--     Color              - Contains just one background color for all the holy rune boxes.
--       All              - True or false.  If true then all the holy rune boxes are set to one color.
--                                          If false then each holy rune box can be set a different color.
--                                          Only works in box mode.
--     Color[1 to 3]      - Contains the background colors of all the holy rune boxes.
--
--   Bar
--     Advanced           - True or false.  If true then you change the size of the bar in small steps.
--     BoxWidth           - Width of each holy rune box.
--     BoxHeight          - Height of each holy rune box.
--     RotateTexture      - True or false.  If true then the bar texture will be rotated 90 degree counter-clockwise
--                                          If false no rotation takes place.
--     PaddingAll         - True or false.  If true then padding can be set with one value otherwise four.
--     Padding            - Amount of padding on the forground of each holy rune box.
--     StatusbarTexture   - Texture used for the forground of each holy rune box.
--     Color              - Contains just one bar color for all the holy rune boxes.
--       All              - True or false.  If true then all the holy rune boxes are set to one color.
--                                          If false then each holy rune box can be set a different color.
--     Color[1 to 3]      - Contains the bar colors of all the holy rune boxes.
--
--
-- Shardbar fields        Same as Holybar fields except for the following:
--                          Uses 4 colors.
-- EmberBar fields        Same as ShardBar fields
--
-- ChiBar fields          Same as ShardBar fields except for the following:
--                          Uses 5 colors.
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
--     FillDirection      - Direction of fill in box mode.  Works in both modes.
--     ReverseFill        - If true then the bar fills in the opposite direction.
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
--     HideSlider         - True or false.  If true then the slider is hidden.
--     BarHalfLit         - True or false.  If true only half of the bar is lit based on the direction the slider is going in.
--     PowerText          - True or false.  If true then eclipse power text will be shown.
--     PredictedPowerText - True or false.  If true then predicted power is shown instead.
--     EclipseAngle       - Angle in degrees in which the bar will be displayed.
--     SliderDirection    - if 'HORIZONTAL' slider will move left to right and right to left.
--                          if 'VERTICAL' slider will move top to bottom and bottom to top.
--     PredictedPower     - True or false.  If true then predicted power will be activated.
--     IndicatorHideShow  - 'showalways' the indicator will never auto hide.
--                          'hidealways' the indicator will never be shown.
--                          'none'       default.
--     PredictedEclipse   - True or false.  If true then show an eclipse proc based on predicted power.
--     PredictedBarHalfLit- True or false.  Same as BarHalfLit except it is based on predicted power.
--                                          BarHalfLit has to be true for this to be enabled.
--     EclipseFadeInTime  - Amount of time in seconds for bar half lit, sun, and moon to fade in.
--     EclipseFadeOutTime - Amount of time in seconds for bar half lit, sun, and moon to fade out.
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
-- Spell tracker
--
-- Keeps track of spells casting.
--
-- SpellTrackerEvent        - Used by TrackSpell().
--                            Converts an event from CombatLogUnfiltered() and/or SpellCasting() to one of the following:
--                              EventSpellStart
--                              EventSpellSucceeded
--                              EventSpellEnergize
--                              EventSpellMissed
--                              EventSpellFailed
--
-- SpellTrackerMessage      - Used by TrackSpell()
--                            Used with EventSpellFailed.  If the Message is not found in the table.
--                            then the spell is considered failed.
--
-- SpellTrackerTimeout      - Used by ModifySpellTracker()
--                            Amount of time before clearing the casting spell.
--
-- SpellTrackerTime         - Used by ModifySpellTracker(), CheckSpellTrackerTimeout()
--                            Keeps track of the time based on SpellTrackerTimeout. When time is reached
--                            the casting spell is removed.
--
-- SpellTrackerTimer        - Used by SetSpellTracker(), ModifySpellTracker()
--                            Timer handle for CheckSpellTrackerTimeout()
--
-- SpellTrackerActive       - Table used by SetSpellTracker(), SetSpellTrackerActive(), HideUnitBar()
--                            Keeps track of which bar has spell tracking turned off or on.
--                            Also keeps track of which bar is using the spell tracker.
--
-- SpellTrackerCasting      - Used by ModifySpellTracker(), CheckSpellTrackerTimeout(), TrackSpell()
--   SpellID                   Spell that is being cast.
--   LineID                    LineID of Spell
--   CastTime                  Amount of time for the spell to finish casting in seconds.
--   Fn                        Call back function.
--   UnitBarF                  Bar that is using the SpellID.
--
-- TrackedSpell[SpellID]    - Used by SetSpellTracker(), TrackSpell()
--   SpellID                   SpellID to search for.
--   EndOn                       'energize' the spell will be cleared on an energize event.
--                               'casting'  the spell will be cleared when the spell ends due to success, failed, etc.
--   Fn                     -  This gets called when a spell starts casting, then on end, and on energize.
--                             Fn(UnitBarF, SpellID, CastTime, Message)
--                               Message
--                                 'start'  Gets called on spell cast start.
--                                 'end'    Gets called on spell success.
--                                 'failed' Gets called if the spell didn't complete.
--                                 'timeout' Gets called by CheckSpellTrackerTimeout() if the spell timed out.
--                               CastTime  The amount of time to cast the spell in seconds.
--                               SpellID is always negative on 'start', 'end', or 'failed'
--                               UnitBarF  Unitbar that is using the spell tracker.
--   UnitBarF               -  Bar that is using the SpellID.
--
--
-- NOTE: See the notes on each of the spell tracker functions for more details.  Also
--       See Eclipse.lua on how this is used.
--       The spell tracker will turn its self off if the frame its being used on is hidden.
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

-------------------------------------------------------------------------------
-- Fading Animation
--
-- Handles all the micromanaging of fading bars in and out based on a rule set.
-- If the bar is fading out, then no animations are played on the children.
-- So if you have a combo point fading out, and the bar starts to fade out.
-- Then the combo point will stop fading.  If a new combo point tries
-- to fade while the bar is fading, then the combo point will not fade.
--
-- These rules prevent the parent and children from fading at the same time.
-- If this were to happen then the alpha state of a texture/frame can get
-- stuck and reloading UI is the only way to fix it.
--
-- If a frame or texture is currently fading, its fading can be reversed
-- without having to stop the fade, just SetAnimation() to change it and
-- it will pick up from where it left off.
--
--
-- FadingAnimation      Table used by CreateFade() and SetAnimation().
--                      Keeps track of every animation and what bar is using them.
--
-- FadingAnimation
--   [UnitBarF]                    - To keep track of what bar is using fading.
--     Total                       - Total number of fading animation groups in use.
--     [Index] = Fade              - Array element containing the fade animation group.


-- Fade                       - Animation group for fading.
--   FadeA                    - Animation for fading.
--   UnitBarF                 - Unitbar that is using the animation.
--   Object                   - Parent of the animation group.
--   Action                   - if false no animation playing.
--                              'in' currently fading in.
--                              'out' currently fading out.
--   Parent                   - If true then its a parent fade.
--   DurationIn               - Time in seconds for fade in.
--   DurationOut              - Time in seconds for fade out.

--
-- Read the notes on CreateFade() on what methods to use in Fade.
--
-- Fade methods
--   SetDuration()
--   SetAnimation()
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

local SpellTrackerTimeout = 7
local SpellTrackerTime = nil
local SpellTrackerTimer = nil
local SpellTrackerActive = {}

local EventSpellStart       = 1
local EventSpellSucceeded   = 2
local EventSpellEnergize    = 3
local EventSpellMissed      = 4
local EventSpellFailed      = 5

local SpellTrackerCasting = {
  SpellID = 0,
  LineID = -1,
  Time = 0,
  CastTime = 0,
}

local SpellTrackerEvent = {
  UNIT_SPELLCAST_START       = EventSpellStart,
  UNIT_SPELLCAST_SUCCEEDED   = EventSpellSucceeded,
  SPELL_ENERGIZE             = EventSpellEnergize,
  SPELL_MISSED               = EventSpellMissed,
  SPELL_CAST_FAILED          = EventSpellFailed,
}

local SpellTrackerMessage = {         -- These variables are blizzard globals. Must be used for foreign languages.
  [SPELL_FAILED_NOT_READY]         = 1, -- SPELL_FAILED_NOT_READY
  [SPELL_FAILED_SPELL_IN_PROGRESS] = 1, -- SPELL_FAILED_SPELL_IN_PROGRESS
}

local TrackedSpell = {}

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

local RegEventFrames = {}

local FadingAnimation = {}

local CooldownBarTimerDelay = 1 / 40 -- 40 times per second

local UnitBarsParent = nil
local UnitBars = nil

local DefaultBgTexture = 'Blizzard Tooltip'
local DefaultBdTexture = 'Blizzard Tooltip'
local DefaultStatusBarTexture = 'Blizzard'
local GUBStatusBarTexture = 'GUB Bright Bar'
local UBFontType = 'Friz Quadrata TT'
local DefaultFadeOutTime = 1
local DefaultFadeInTime = 0.30

local Backdrop = {
  bgFile   = LSM:Fetch('background', DefaultBgTexture), -- background texture
  edgeFile = LSM:Fetch('border', DefaultBdTexture),     -- border texture
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
    ReverseFading = true,
    FadeInTime = DefaultFadeInTime,
    FadeOutTime = DefaultFadeOutTime,
-- Player Health
    PlayerHealth = {
      Name = 'Player Health',
      Enabled = true,
      x = -200,
      y = 230,
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
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
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
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedBarTexture = DefaultStatusBarTexture,
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
      x = -200,
      y = 200,
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
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
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
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedBarTexture = DefaultStatusBarTexture,
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
      x = -200,
      y = 170,
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
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
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
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedBarTexture = DefaultStatusBarTexture,
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
      x = -200,
      y = 140,
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
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
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
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
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
      x = -200,
      y = 110,
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
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
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
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedBarTexture = DefaultStatusBarTexture,
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
      x = -200,
      y = 80,
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
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
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
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
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
      x = -200,
      y = 50,
      Status = {
        HideNotUsable   = true,
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
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
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
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedBarTexture = DefaultStatusBarTexture,
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
-- Pet Power
    PetPower = {
      Name = 'Pet Power',
      Enabled = true,
      BarVisible = function() return HasPet end,
      UsedByClass = {DEATHKNIGHT = '', MAGE = '3', WARLOCK = '', HUNTER = ''},
      x = -200,
      y = 20,
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
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
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
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
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
                     return  -- PlayerPowerType 0 is mana
                       (PlayerClass == 'DRUID' or PlayerClass == 'MONK') and PlayerPowerType ~= 0
                     end,
      UsedByClass = {DRUID = '', MONK = '2'},
      x = -200,
      y = -10,
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
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
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
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
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
      x = 0,
      y = 229,
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
        ColorEnergize = {
          All = false,
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
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
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
        RuneWidth = 40,
        RuneHeight = 25,
        FillDirection = 'HORIZONTAL',
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
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
          All = false,
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
      UsedByClass = {ROGUE = '', DRUID = ''},
      x = 0,
      y = 201,
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
        ComboFadeInTime = DefaultFadeInTime,
        ComboFadeOutTime = DefaultFadeOutTime,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
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
        BoxWidth = 40,
        BoxHeight = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
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
      x = 0,
      y = 171,
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
        HolyFadeInTime = DefaultFadeInTime,
        HolyFadeOutTime = DefaultFadeOutTime,
        HolyAngle = 90
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
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
        BoxWidth = 40,
        BoxHeight = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
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
      x = 0,
      y = 134,
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
        ShardFadeInTime = DefaultFadeInTime,
        ShardFadeOutTime = DefaultFadeOutTime,
        ShardAngle = 90
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
          r = 0.329, g = 0.172, b = 0.337, a = 1,
          [1] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
          [2] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
          [3] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
          [4] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
        },
      },
      Bar = {
        Advanced = false,
        BoxWidth = 40,
        BoxHeight = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
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
      x = 0,
      y = 98,
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
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
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
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        MetaStatusBarTexture = GUBStatusBarTexture,
        Color = {r = 0.627, g = 0.298, b = 1, a = 1},
        MetaColor = {r = 0.922, g = 0.549, b = 0.972, a = 1},
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
      x = 0,
      y = 60,
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
        GreenFire = false,
        GreenFireAuto = true,
        EmberSize = 1,
        EmberPadding = 5,
        EmberScale = 1,
        EmberAngle = 90,
        FieryEmberFadeInTime = DefaultFadeInTime,
        FieryEmberFadeOutTime = DefaultFadeOutTime,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
          r = 0.180, g = 0.047, b = 0.031, a = 1,
          [1] = {r = 0.180, g = 0.047, b = 0.031, a = 1},
          [2] = {r = 0.180, g = 0.047, b = 0.031, a = 1},
          [3] = {r = 0.180, g = 0.047, b = 0.031, a = 1},
          [4] = {r = 0.180, g = 0.047, b = 0.031, a = 1},
        },
        ColorGreen = {
          All = false,
          r = 0.043, g = 0.188, b = 0, a = 1,
          [1] = {r = 0.043, g = 0.188, b = 0, a = 1},
          [2] = {r = 0.043, g = 0.188, b = 0, a = 1},
          [3] = {r = 0.043, g = 0.188, b = 0, a = 1},
          [4] = {r = 0.043, g = 0.188, b = 0, a = 1},
        },
      },
      Bar = {
        Advanced = false,
        BoxWidth = 25,
        BoxHeight = 34,
        FillDirection = 'VERTICAL',
        ReverseFill = false,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        FieryStatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
          r = 1, g = 0.325, b = 0 , a = 1,
          [1] = {r = 1, g = 0.325, b = 0 , a = 1},
          [2] = {r = 1, g = 0.325, b = 0 , a = 1},
          [3] = {r = 1, g = 0.325, b = 0 , a = 1},
          [4] = {r = 1, g = 0.325, b = 0 , a = 1},
        },
        ColorFiery = {
          All = false,
          r = 0.941, g = 0.690, b = 0.094, a = 1,
          [1] = {r = 0.941, g = 0.690, b = 0.094, a = 1},
          [2] = {r = 0.941, g = 0.690, b = 0.094, a = 1},
          [3] = {r = 0.941, g = 0.690, b = 0.094, a = 1},
          [4] = {r = 0.941, g = 0.690, b = 0.094, a = 1},
        },
        ColorGreen = {
          All = false,
          r = 0.203, g = 0.662, b = 0, a = 1,
          [1] = {r = 0.203, g = 0.662, b = 0, a = 1},
          [2] = {r = 0.203, g = 0.662, b = 0, a = 1},
          [3] = {r = 0.203, g = 0.662, b = 0, a = 1},
          [4] = {r = 0.203, g = 0.662, b = 0, a = 1},
        },
        ColorFieryGreen = {
          All = false,
          r = 0, g = 1, b = 0.078, a = 1,
          [1] = {r = 0, g = 1, b = 0.078, a = 1},
          [2] = {r = 0, g = 1, b = 0.078, a = 1},
          [3] = {r = 0, g = 1, b = 0.078, a = 1},
          [4] = {r = 0, g = 1, b = 0.078, a = 1},
        },
      },
    },
-- EclipseBar
    EclipseBar = {
      Name = 'Eclipse Bar',
      Enabled = true,
      BarVisible = function() return PlayerClass == 'DRUID' and (PlayerStance == MoonkinForm or PlayerStance == nil) end,
      UsedByClass = {DRUID = '1'},
      x = 0,
      y = 11,
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
        HideSlider = false,
        BarHalfLit = false,
        PowerText = true,
        EclipseAngle = 90,
        SliderDirection = 'HORIZONTAL',
        EclipseFadeInTime = DefaultFadeInTime,
        EclipseFadeOutTime = DefaultFadeOutTime,
        SunOffsetX = 0,
        SunOffsetY = 0,
        MoonOffsetX = 0,
        MoonOffsetY = 0,
        PredictedPower = false,
        IndicatorHideShow = 'none',
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
            BgTexture = DefaultBgTexture,
            BdTexture = DefaultBdTexture,
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
            BgTexture = DefaultBgTexture,
            BdTexture = DefaultBdTexture,
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
            BgTexture = DefaultBgTexture,
            BdTexture = DefaultBdTexture,
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
            BgTexture = DefaultBgTexture,
            BdTexture = DefaultBdTexture,
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
            BgTexture = DefaultBgTexture,
            BdTexture = DefaultBdTexture,
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
      x = 161,
      y = 60,
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
        ShadowFadeInTime = DefaultFadeInTime,
        ShadowFadeOutTime = DefaultFadeOutTime,
        ShadowAngle = 90
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
          r = 0.329, g = 0.172, b = 0.337, a = 1,
          [1] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
          [2] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
          [3] = {r = 0.329, g = 0.172, b = 0.337, a = 1},
        },
      },
      Bar = {
        Advanced = false,
        BoxWidth = 38,
        BoxHeight = 37,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
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
      x = 161,
      y = 98,
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
        ChiFadeInTime = DefaultFadeInTime,
        ChiFadeOutTime = DefaultFadeOutTime,
        ChiAngle = 90
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
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
        BoxWidth = 30,
        BoxHeight = 30,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
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

local PowerTypeToNumber = {
  MANA = 0, RAGE = 1, FOCUS = 2, ENERGY = 3, RUNIC_POWER = 6,
  SOUL_SHARDS = 7, ECLIPSE = 8, HOLY_POWER = 9, CHI = 12,
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
--              'spelltracker'     Registers events for spell tracker.
--              'setbonus'         Registers events for equipment set bonus
-------------------------------------------------------------------------------
local function RegisterEvents(Action, EventType)

  if EventType == 'main' then

    -- Register events for the addon.
    Main:RegEvent(true, 'UNIT_ENTERED_VEHICLE',          GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_EXITED_VEHICLE',           GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_DISPLAYPOWER',             GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_MAXPOWER',                 GUB.UnitBarsUpdateStatus, 'player')
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

  elseif EventType == 'spelltracker' then
    local Flag = Action == 'register'

    -- register events for spell tracker.
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
-- RegEvent/RegEventFrame
--
-- Registers an event to call a function.
--
-- Usage: RegEvent(Reg, Event, Fn, Units)
--        RegEventFrame(Reg, Frame, Event, Fn, Units)
--
-- Reg      If true then event gets registered otherwise unregistered.
-- Event    Event to register
-- Fn       Function to call when event fires.
-- Units    1 or 2 units. The event only fires if its unit matches.
-------------------------------------------------------------------------------
function GUB.Main:RegEventFrame(Reg, Frame, Event, Fn, ...)
  if Reg then
    if ... then
      Frame:RegisterUnitEvent(Event, ...)
    else
      Frame:RegisterEvent(Event)
    end
    Frame:SetScript('OnEvent', Fn)
  else
    Frame:UnregisterEvent(Event)
  end
end

function GUB.Main:RegEvent(Reg, Event, Fn, ...)

  -- Get frame based on Fn.
  local Frame = RegEventFrames[Fn]

  -- Create a new frame if one wasn't found.
  if Frame == nil then

    -- Create a new event frame for this event
    Frame = CreateFrame('Frame')
    RegEventFrames[Fn] = Frame
  end
  Main:RegEventFrame(Reg, Frame, Event, Fn, ...)
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
  local _, _, _, _, Active = GetTalentInfo(Index, nil, nil)
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

    -- Search one or more frames.
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
--        See CheckSpellTrackerTimeout() on how this is used.
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

-- Condition    - 'a' and.
--                   All auras must be found.
--                'o' or.
--                   Only one of the auras need to be found.
-- Found        - If 'a' is used.
--                Returns true if the aura was found. Or false.
--                If 'o' is used.
--                Returns the SpellID of the aura found or nil if no aura was found.
-- TimeLeft     - Time left on aura.  -1 if aura doesn't have a time left.
--                This only gets returned when using the 'o' option.
-------------------------------------------------------------------------------
function GUB.Main:CheckAura(Condition, ...)
  local Name = nil
  local SpellID = 0
  local MaxSpellID = select('#', ...)
  local Found = 0
  local AuraIndex = 1

  repeat
    local Name, _, _, _, _, _, ExpiresIn, _, _, _, SpellID = UnitBuff('player', AuraIndex)
    if Name then

      -- Search for the aura against the list of auras passed.
      for i = 1, MaxSpellID do
        if SpellID == select(i, ...) then
          Found = Found + 1
          break
        end
      end

      -- When using the 'o' option then return on the first found aura.
      if Condition == 'o' and Found > 0 then
        if ExpiresIn == 0 then
          return SpellID, -1
        else
          return SpellID, ExpiresIn - GetTime()
        end
      end
    end
    AuraIndex = AuraIndex + 1
  until Name == nil or Found == MaxSpellID
  if Condition == 'a' then
    return Found == MaxSpellID
  end
end

-------------------------------------------------------------------------------
-- CheckSpellTrackerTimeout
--
-- Timer that watches to timeout the current casting spell.
-------------------------------------------------------------------------------
local function CheckSpellTrackerTimeout(self, Elapsed)

  -- Check for spell tracker time out.
  if SpellTrackerTime > 0 then
    SpellTrackerTime = SpellTrackerTime - Elapsed
  else
    local SpellID = SpellTrackerCasting.SpellID
    local CastTime = SpellTrackerCasting.CastTime
    local Fn = SpellTrackerCasting.Fn
    local UnitBarF = SpellTrackerCasting.UnitBarF

    self.ModifySpellTracker('remove')

    if Fn then
      Fn(UnitBarF, SpellID, CastTime, 'timeout')
    end
  end
end

-------------------------------------------------------------------------------
-- ModifySpellTracker
--
-- Adds or Remove a spell from the spell tracker.
--
-- Usage: ModifySpellTracker(Action, UnitBarF, SpellID, LineID, CastTime, Fn)
--
-- Action     'remove' or 'add'
--            'add'    will add the current spell to casting.
--            'remove' will remove the current casting spell.
-- UnitBarF   Bar that is using the SpellID.
-- SpellID    The spell to add.
-- LineID     LineID to add.
-- CastTime   Amount of time it takes to cast the spell.
-- Fn         Function to call when timeout happens.
-------------------------------------------------------------------------------
local function ModifySpellTracker(Action, UnitBarF, SpellID, LineID, CastTime, Fn)

  -- Stop the timeout checker.
  Main:SetTimer(SpellTrackerTimer, nil)

  if Action == 'add' then
    SpellTrackerCasting.SpellID = SpellID
    SpellTrackerCasting.LineID = LineID
    SpellTrackerCasting.CastTime = CastTime
    SpellTrackerCasting.Fn = Fn
    SpellTrackerCasting.UnitBarF = UnitBarF

    -- Set timeout
    SpellTrackerTime = SpellTrackerTimeout - 1 -- Takes one second for timer to start ticking.

    -- Start the timeout checker.
    Main:SetTimer(SpellTrackerTimer, 1, CheckSpellTrackerTimeout) -- Call timer once per second.

  elseif Action == 'remove' then
    SpellTrackerCasting.SpellID = 0
    SpellTrackerCasting.LineID = -1
    SpellTrackerCasting.CastTime = 0
    SpellTrackerCasting.Fn = nil
    SpellTrackerCasting.UnitBarF = nil
  end
end

-------------------------------------------------------------------------------
-- SetSpellTrackerActive
--
-- Turns spell tracking on or off.
--
-- Usage: SetSpellTrackerActive(UnitBarF, Action)
--
-- UnitBarF  If this matches with what was set in SetSpellTracker() then
--           Action won't be ignored.
-- Action    True or False.  If true then the spell tracker is turned on.
--                           if false then the spell tracker is only turned off when there are no
--                           other bars using it.
--           'register'
--           'unregister'    registers and unregisters the events for spell tracking.  But doesn't
--                           set the active state.  Used internally by HideUnitBar()
--
-- NOTES:  If the bar is hidden and the Action is true, then spell tracking wont be enabled
--         until the bar is visible again.
-------------------------------------------------------------------------------
local function SetSpellTrackerActive(UnitBarF, Action)

  -- Check to see if the unitbar was already defined in SetSpellTracker()
  if SpellTrackerActive[UnitBarF] ~= nil then
    if type(Action) == 'boolean' then
      SpellTrackerActive[UnitBarF] = Action
    else
      Action = Action == 'register'
    end

    -- Only register events if the bar is not hidden.
    if Action and not UnitBarF.Hidden then
      RegisterEvents('register' , 'spelltracker')

    elseif not Action then

      -- Check to see if any other bars are using the spell tracker
      -- that are not hidden
      local Found = false
      for UBF, Active in pairs(SpellTrackerActive) do
        if UnitBarF ~= UBF and Active and not UBF.Hidden then
          Found = true
          break
        end
      end
      if not Found then
        RegisterEvents('unregister' , 'spelltracker')

        -- Remove any spell being tracked.
        ModifySpellTracker('remove')
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetSpellTracker
--
-- Adds a spellID to the list for spell tracking.
-- Can also turn off or on the spell tracker or reset it.
--
-- Usage: SetSpellTracker(UnitBarF, SpellID, EndOn, Fn)
--        SetSpellTracker(UnitBarF, true or false)
--        SetSpellTracker('reset')
--
-- UnitBarF      The type of bar the SpellID will be used with.
-- SpellID       ID of the spell to track.
-- EndOn         Tells how the spell will end.
--               'casting' means the spell will be cleared when the spell was stopped, cancled, succeeded, etc.
--               'energize' means the spell will end on an energize event.
-- Fn            See TrackSpell() and Eclipse.lua on how Fn() is used.
--
-- true          Turn on predicted power.
-- false         Turn off predicted power.
--
-- 'reset'       Sets all the bars active status to false and unregisters tracker events.
--
-- NOTE:   When using endon 'energize' you must add the energize spellID as well. Otherwise
--         the spell tracker will not see the energize event.  See EclipseBar.lua how this is set up.
-------------------------------------------------------------------------------
function GUB.Main:SetSpellTracker(UnitBarF, SpellID, EndOn, Fn)
  if UnitBarF == 'reset' then
    for UBF, v in pairs(SpellTrackerActive) do
      SpellTrackerActive[UBF] = false
    end

  -- Add spell to be tracked.
  elseif type(SpellID) ~= 'boolean' then
    local PS = {EndOn = EndOn, Fn = Fn, UnitBarF = UnitBarF}
    TrackedSpell[SpellID] = PS
    SpellTrackerActive[UnitBarF] = false
  else

    -- Set the active status, also create timer if doesn't exist.
    if SpellTrackerTimer == nil then
      SpellTrackerTimer = CreateFrame('Frame')
      SpellTrackerTimer.ModifySpellTracker = ModifySpellTracker
    end
    SetSpellTrackerActive(UnitBarF, SpellID)  -- SpellID is true or false when used here.
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
-- Usage: SetCooldownBarEdgeFrame(StatusBar, EdgeFrame, FillDirection, ReverseFill, Width, Height)
--
-- StatusBar     Statusbar containing the cooldownbar timer.
-- EdgeFrame     Frame containing objects to be displayed.
-- FillDirection 'HORIZONTAL' left to right, 'VERTICAL' bottom to top.
-- ReverseFill   True   left to right or bottom to top.
--               False  right to left or top to bottom.
-- Width         Width set to EdgeFrame
-- Height        Height set to EdgeFrame
--
-- If EdgeFrame is nil then no EdgeFrame will be shown or the existing EdgeFrame
-- will be removed.
-------------------------------------------------------------------------------
function GUB.Main:SetCooldownBarEdgeFrame(StatusBar, EdgeFrame, FillDirection, ReverseFill, Width, Height)
  if EdgeFrame then
    EdgeFrame:Hide()

    -- Set the width and height.
    EdgeFrame:SetWidth(Width)
    EdgeFrame:SetHeight(Height)

    StatusBar.EdgeFrame = EdgeFrame
    StatusBar.FillDirection = FillDirection
    StatusBar.ReverseFill = ReverseFill
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
            if self.ReverseFill then
              x = self:GetWidth() - x
            end
            if x ~= LastX then
              EdgeFrame:SetPoint('CENTER', self, 'LEFT', x, 0)
              LastX = x
            end
          else
            local y = TimeElapsed / Duration * self:GetHeight()
            if self.ReverseFill then
              y = self:GetHeight() - y
            end
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
-- FinishAnimation
--
-- Finishes a fading animation or skips to the end of one.
--
-- Subfunction of SetAnimation()
--
-- Usage: FinishAnimation(self, NewAction)
--
-- self       Animation group to finish (Fade)
-- NewAction  If specified will use this instead of self.Action
--            Must be 'in' or 'out' or nil.
-------------------------------------------------------------------------------
local function FinishAnimation(self, NewAction)
  local Object = self.Object
  local Action = NewAction or self.Action

  self:SetScript('OnFinished', nil)
  self:Stop()

  -- Hide or show the object based on action.
  if Action == 'in' then
    Object:Show()
    Object:SetAlpha(1)
  else
    Object:Hide()
    Object:SetAlpha(1)
  end
  self.Action = false
end

-------------------------------------------------------------------------------
-- PlayAnimation
--
-- Plays a fading animation.
--
-- Subfunction of SetAnimation()
--
-- Usage: PlayAnimation(Fade, Action, ReverseFade)
--
-- Fade          Animation group to play.
-- Action        Must be 'in' or 'out'
-- ReverseFade   If true then the Fade passed must be currently fading.
--               The fading will get reversed.
-------------------------------------------------------------------------------
local function PlayAnimation(Fade, Action, ReverseFade)
  local Object = Fade.Object
  local FadeA = Fade.FadeA
  local Duration = 0
  local Change = 0

  -- Set up for reverse fading.
  if ReverseFade then
    Action = Fade.Action == 'in' and 'out' or 'in'
  else

    -- else set up for a new fade.
    Object:Show()
    if Action == 'in' then
      Object:SetAlpha(0)
    end
  end

  -- Get change and duration.
  if Action == 'in' then
    Change = 1
    Duration = Fade.DurationIn
  else
    Change = -1
    Duration = Fade.DurationOut
  end

  -- Check for zero duration.
  if Duration == 0 then
    FinishAnimation(Fade, Action)
  else

    -- Set up for reverse fade.  This will reverse the current fade.
    if ReverseFade then
      local Alpha = Fade.Object:GetAlpha()

      Fade:Stop()
      Fade.Object:SetAlpha(Alpha)

      if Action == 'in' then
        Alpha = 1 - Alpha
      end
      Duration = Alpha * Duration
    else

      -- Starting a new fade, set the script.
      Fade:SetScript('OnFinished', FinishAnimation)
    end

    -- Set and play the fade.
    FadeA:SetChange(Change)
    FadeA:SetDuration(Duration)
    Fade:Play()
    Fade.Action = Action
  end
end

-------------------------------------------------------------------------------
-- SetAnimation  (fade method)
--
-- Stop or starts fading.
--
-- Usage:  Fade:SetAnimation(Action)
--
-- self        Animation group (Fade)
-- Action      'in'       Starts fading animation in. Stops any old animation first or reverses.
--             'out'      Starts fading animation out. Stops any old animation first or reverses.
--             'stop'     Stops fading animation and calls Fn
--             'stopall'  Stops all animation.
--
-- NOTE:  The perpose of this function is to never let a child frame fade in or out
--        while the parent is fading.  If this were to happen the alpha state of
--        a frame can get stuck and only a /console reloadui can fix it.
--        Blizzard please fix this, thanks.
--
--        A parent fade will only play but will stop all child animations first.
--        The current child fade animation will skip to the end instead of playing.
--        Child fades will not play if the parent is fading.  Instead they'll skip to the
--        end of their animation right away.
--
--        Fading can be reversed by doing SetAnimation() in the opposite direction
--        on a fade already playing.
-------------------------------------------------------------------------------
local function SetAnimation(self, Action)
  local ReverseFade = false
  local FadeAction = self.Action

  -- Stop or play the fade.
  if Action == 'stop' then
    if FadeAction then
      FinishAnimation(self)
    end
    return
  end
  if Action == 'in' or Action == 'out' then
    if FadeAction then
      if FadeAction ~= Action then

        -- Fade already playing, reverse fade if unitbar options is set.
        if UnitBars.ReverseFading then
          ReverseFade = true
        else
          FinishAnimation(self)
        end
      else

        -- Return since the same type of fade is already playing.
        return
      end
    end
  end

  -- Search for parent or children fading.
  local StopAll = Action == 'stopall'
  local NotParent = not self.Parent
  local FA = FadingAnimation[self.UnitBarF]

  for Index = 1, FA.Total do
    local Fade = FA[Index]
    if Fade.Action then

      -- Stop all animation if stopall is set.
      if StopAll then
        FinishAnimation(Fade)

      elseif Fade.Parent == NotParent then

        -- If parent is fading then stop all children animations.
        if self.Parent then
          FinishAnimation(Fade)
        else

          -- End current animation since the parent is fading, and return.
          -- Since Fade is not playing we need to specify an action.
          FinishAnimation(self, Action)
          return
        end
      end
    end
  end

  -- Return if stopall.
  if StopAll then
    return
  end

  -- Play the fading animation. in or out.
  PlayAnimation(self, Action, ReverseFade)
end

-------------------------------------------------------------------------------
-- SetDuration   (Fade method)
--
-- Sets the time in seconds that it will take for fading.
--
-- Usage: Fade:SetDuration(Action, Seconds)
--
-- self       Animation group (fade)
-- Seconds    Time in seconds.
-- Action     'in' for for fading in duration.
--            'out' for fading out duration.
--
-- NOTE:  The change doesn't change the current fading animation only new ones.
-------------------------------------------------------------------------------
local function SetDuration(self, Action, Seconds)

  -- Set the duration for in/out.
  if Action == 'in' then
    self.DurationIn = Seconds
  else
    self.DurationOut = Seconds
  end
end

-------------------------------------------------------------------------------
-- CreateFade
--
-- Create a fadein or fadeout animation.
--
-- Usage:  Fade = CreateFade(UnitBarF, Object, Parent)
--
-- UnitBarF   One or more fade animations being created under this bar.
-- Object     Must be a frame or texture.
-- Parent     If true then the fading animation is considered to belong to
--            the parent frame. Otherwise leave this nil.
--
-- Fade       Animation containing all the info needed to fade in or out.
--            See notes at top of the file for breakdown of this table.
--
-- List of methods used with fade
--
-- Fade:SetDuration('in' or 'out', Seconds)
-- Fade:SetAnimation('in' or 'out' or 'stop' or 'stopall')
--
-- See notes above on how each one is used.
-------------------------------------------------------------------------------
function GUB.Main:CreateFade(UnitBarF, Object, Parent)

  -- Create an animation for fading.
  local Fade = Object:CreateAnimationGroup()
  local FadeA = Fade:CreateAnimation('Alpha')

  -- Set the animation group values.
  Fade:SetLooping('NONE')
  FadeA:SetOrder(1)
  FadeA:SetDuration(0)

  Fade.FadeA = FadeA
  Fade.UnitBarF = UnitBarF
  Fade.Object = Object
  Fade.Action = false
  Fade.Parent = Parent or false
  Fade.DurationIn = 0
  Fade.DurationOut = 0

  -- Create a new entry for the UnitBar if one doesn't exist.
  local FA = FadingAnimation[UnitBarF]
  if FA == nil then
    FA = {Total = 0}
    FadingAnimation[UnitBarF] = FA
  end

  -- Store the fade animation
  local Total = FA.Total + 1
  FA[Total] = Fade
  FA.Total = Total

  -- Set methods.
  Fade.SetAnimation = SetAnimation
  Fade.SetDuration = SetDuration

  return Fade
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
  local Fade = UnitBarF.Fade
  local Anchor = UnitBarF.Anchor

  if HideBar ~= UnitBarF.Hidden then
    if HideBar then

      -- Disable TrackingSpells if active.
      if SpellTrackerActive[UnitBarF] then

        -- Disable spell tracking for this bar.
        SetSpellTrackerActive(UnitBarF, 'unregister')
      end

      -- Deselect a unitbar if selected.
      if UnitBarF == PSelectedUnitBarF then
        PSelectedUnitBarF = nil
      end
      SelectUnitBar(UnitBarF, 'clear')

      -- Start the animation fadeout.
      Fade:SetAnimation('out')
      UnitBarF.Hidden = true
    else
      UnitBarF.Hidden = false

      -- Start the animation fadein.
      Fade:SetAnimation('in')

      -- Enable TrackingSpells if active.
      if SpellTrackerActive[UnitBarF] then
        SetSpellTrackerActive(UnitBarF, 'register')
      end
    end
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
    if Spec and (Spec == '' or PlayerSpecialization and strfind(Spec, PlayerSpecialization)) then
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
        Visible = IsActive == true

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
-- TrackSpell
--
-- Subfunction of CombatLogUnfiltered()
-- Subfunction of SpellCasting()
--
-- Sets the spell to be tracked based on events from CombatLogUnfiltered() and SpellCasting().
--
-- Usage: TrackSpell(Event, SpellID, LineID, Message)
--
-- Event        Event from CombatlogUnfiltered() or SpellCasting().
-- SpellID      SpellID of the spell.
-- LineID       Only valid for start, success, an events.
-- Message      Message from combatlog.
--
-- NOTES:
--         Timeouts are used so only events SPELL_MISS and SPELL_ENERGIZE needs to be tracked.
--         If one of those events didn't happen, then the timeout will remove the spell.
--
--         See the notes at the top of the file about the spell tracker.
--
--         Fn() can get called 3 times.
--         Fn(SpellID, CastTime, Message, UnitBarF)
--           Message = 'start'   Gets called on spell cast start.
--                   = 'end'     Gets called on spell success.
--                   = 'failed'  Gets called if the spell didn't complete.
--                   = 'timeout' Gets called by CheckSpellTrackerTimeout() if the spell timed out.
--           CastTime  The amount of time to cast the spell in seconds.
--           SpellID   is always negative on 'start', 'end', or 'failed'
--           UnitBarF  Type of bar that SpellID was defined with in SetSpellTracker()
--
--           If its energize then the message comes from the server.
-------------------------------------------------------------------------------
local function TrackSpell(Event, TimeStamp, SpellID, LineID, Message)
  local PSE = SpellTrackerEvent[Event]

  if PSE ~= nil then
    local PS = TrackedSpell[SpellID]

    -- Check for valid spellID.
    if PS ~= nil then
      local UnitBarF = PS.UnitBarF

      -- Check to see if spell tracker is active for this bar.
      if SpellTrackerActive[UnitBarF] then
        local Flight = PS.Flight
        local Fn = PS.Fn
        local CastTime = 0

        -- Detect start cast.
        if PSE == EventSpellStart then

          -- Get cast time for spell.
          local _, _, _, _, _, _, CastTime = GetSpellInfo(SpellID)

          -- Turn CastTime into seconds.
          CastTime = CastTime / 1000

          -- Call Fn.
          if Fn then
            Fn(UnitBarF, -SpellID, CastTime, 'start')
          end

          -- Set spell to be tracked.
          ModifySpellTracker('add', UnitBarF, SpellID, LineID, CastTime, Fn)
        else
          CastTime = SpellTrackerCasting.CastTime
        end

        -- Remove casting spell or a failed casting spell.
        if PSE == EventSpellSucceeded and LineID == SpellTrackerCasting.LineID or
           PSE == EventSpellFailed and SpellTrackerMessage[Message] == nil then

          if PS.EndOn == 'casting' or PSE == EventSpellFailed then
            ModifySpellTracker('remove')
          end

          -- Call Fn if one was set
          if Fn then
            if PSE == EventSpellFailed then
              Fn(UnitBarF, -SpellID, CastTime, 'failed')
            elseif PS.EndOn == 'casting' then
              Fn(UnitBarF, -SpellID, CastTime, 'end')
            end
          end
        end

        if PSE == EventSpellEnergize or PSE == EventSpellMissed then
          if PS.EndOn == 'energize' or PSE == EventSpellMissed then
            ModifySpellTracker('remove')
          end

          -- call Fn on energize.
          if PSE == EventSpellEnergize and Fn then
            Fn(UnitBarF, SpellID, CastTime, Message)
          end
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

  -- track spell for player only.
  if SourceGUID == PlayerGUID then

    -- Pass spellID and Message.
    TrackSpell(CombatEvent, TimeStamp, select(3, ...), nil, select(6, ...))
  end
end

-------------------------------------------------------------------------------
-- SpellCasting (called by event)
--
-- Gets called when the player started or stopped casting a spell.
-------------------------------------------------------------------------------
function GUB:SpellCasting(Event, Unit, Name, Rank, LineID, SpellID)

  -- track spell for player only.
  TrackSpell(Event, nil, SpellID, LineID, '')
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
-- FadeInTime
-------------------------------------------------------------------------------
function GUB.Main:UnitBarsSetAllOptions()
  local ATOFrame = Options.ATOFrame

  -- Update alignment tool status.
  if UnitBars.IsLocked or not UnitBars.AlignmentToolEnabled then
    Options.ATOFrame:Hide()
  end

  -- Apply the settings.
  for _, UBF in pairs(UnitBarsF) do
    local IsLocked, IsClamped = UnitBars.IsLocked, UnitBars.IsClamped

    UBF:EnableMouseClicks(not IsLocked)
    UBF.Anchor:SetClampedToScreen(IsClamped)
  end

  local FadeOutTime = UnitBars.FadeOutTime

  for _, UBF in pairs(UnitBarsF) do
    UBF.Fade:SetDuration('out', FadeOutTime)
  end

  local FadeInTime = UnitBars.FadeInTime

  for _, UBF in pairs(UnitBarsF) do
    UBF.Fade:SetDuration('in', FadeInTime)
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
  Options.ATOFrame:Hide()

  -- Reset the spell tracker.
  Main:SetSpellTracker('reset')

  for BarType, UnitBarF in pairs(UnitBarsF) do
    local UB = UnitBars[BarType]
    local Anchor = UnitBarF.Anchor
    local ScaleFrame = UnitBarF.ScaleFrame
    local SelectFrame = UnitBarF.SelectFrame

    -- Stop any old fade animation for this unitbar.
    UnitBarF.Fade:SetAnimation('stopall')

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

    -- Set the layout for the bar.
    UnitBarF:SetLayout()
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

    -- Create an animation for fade in/out.  Make this a parent fade.
    UnitBarF.Fade = Main:CreateFade(UnitBarF, Anchor, true)

    if strfind(BarType, 'Health') or strfind(BarType, 'Power') then
      HapBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
    else
      GUB[BarType]:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
    end
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

  -- Set the unitbars global settings
  Main:UnitBarsSetAllOptions()

  -- Enable unit bars.
  Main:EnableUnitBars()

  -- Initialize the events.
  RegisterEvents('register', 'main')

  -- Set the unitbars status and show the unitbars.
  GUB:UnitBarsUpdateStatus()

--@do-not-package@
  GSB = GUB -- for debugging OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
  GUBdataf = UnitBarsF
  GUBdata = UnitBars
--@end-do-not-package@
end


