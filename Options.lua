--
-- Options.lua
--
-- Handles all the options for GalvinUnitBars.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local DUB = GUB.DefaultUB.Default.profile
local Version = GUB.DefaultUB.Version
local InCombatOptionsMessage = GUB.DefaultUB.InCombatOptionsMessage

local DefaultBgTexture        = GUB.DefaultUB.DefaultBgTexture
local DefaultBorderTexture    = GUB.DefaultUB.DefaultBorderTexture
local DefaultStatusBarTexture = GUB.DefaultUB.DefaultStatusBarTexture
local DefaultSound            = GUB.DefaultUB.DefaultSound
local DefaultSoundChannel     = GUB.DefaultUB.DefaultSoundChannel
local DefaultFontType         = GUB.DefaultUB.DefaultFontType

local Main = GUB.Main
local Bar = GUB.Bar
local Options = GUB.Options

local UnitBarsF = Main.UnitBarsF
local PowerColorType = Main.PowerColorType
local ConvertPowerType = Main.ConvertPowerType
local ConvertCombatColor = Main.ConvertCombatColor
local ConvertPlayerClass = Main.ConvertPlayerClass
local LSM = Main.LSM
local Talents = Main.Talents

local HelpText = GUB.DefaultUB.HelpText
local ChangesText = GUB.DefaultUB.ChangesText
local LinksText = GUB.DefaultUB.LinksText
local ClassSpecialization = GUB.DefaultUB.ClassSpecialization

-- localize some globals.
local _
local floor, ceil =
      floor, ceil

local strupper, strlower, strtrim, strfind, format, gmatch, strsplit, strsub, strjoin, tostring =
      strupper, strlower, strtrim, strfind, format, gmatch, strsplit, strsub, strjoin, tostring
local tonumber, gsub, min, max, tremove, tinsert, wipe, strsub =
      tonumber, gsub, min, max, tremove, tinsert, wipe, strsub
local ipairs, pairs, type, next, sort, select =
      ipairs, pairs, type, next, sort, select
local InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print, GameTooltip, message, GetSpellInfo, IsModifierKeyDown =
      InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print, GameTooltip, message, GetSpellInfo, IsModifierKeyDown
local UnitReaction, GetAlternatePowerInfoByID =
      UnitReaction, GetAlternatePowerInfoByID

-------------------------------------------------------------------------------
-- Locals
--
-- Options.MainOptionsOpen       If true then the options window is opened. Otherwise closed.
-- Options.AlignSwapOptionsOpen  If true then the align and swap options window is opened.  otherwise closed.
-- MainOptionsFrame              Main options frame used by this addon.
-- ProfilesOptionsFrame          Used to show the profile settings in the blizzard
--                               options tree.
-- SlashOptions                  Options only used by slash commands. This is accessed
--                               by typing '/gub'.
--
-- DoFunctions                   Table used to save and call functions thru DoFunction()
--
-- AlignSwapAnchor               Contains the current anchor of the Unitbar that was clicked on to open
--                               the align and swap options window.
--
-- MainOptionsHideFrame          Frame used for when the main options window is closed.
-------------------------------------------------------------------------------
local AceConfigRegistery = LibStub('AceConfigRegistry-3.0')
local AceConfig = LibStub('AceConfig-3.0')
local AceDBOptions = LibStub('AceDBOptions-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')

-- Addon Constants
local AddonName = GetAddOnMetadata(MyAddon, 'Title')
local AddonMainOptions = MyAddon .. 'options'
local AddonAlignSwapOptions = MyAddon .. 'options2'
local AddonOptionsToGUB = MyAddon .. 'options3'
local AddonMessageBoxOptions = MyAddon .. 'options4'
local AddonProfileName = MyAddon .. 'profile'
local AddonSlashOptions = MyAddon

local DoFunctions = {}
local MainOptionsHideFrame = CreateFrame('Frame')
local SwapAlignOptionsHideFrame = CreateFrame('Frame')

local SlashOptions = nil
local OptionsToGUB = nil
local MainOptions = nil
local AlignSwapOptions = nil
local MessageBoxOptions = nil
local AlignSwapAnchor = nil

local ClipBoard = nil
local TableData = nil
local SelectedMenuButtonName = 'Main'
local MenuButtons = nil
local AltPowerBarSearch = ''

local DebugText = ''

local o = {

  -- Test mode
  TestModeUnitLevelMin = -1,
  TestModeUnitLevelMax = 200,
  TestModeOnCooldownMin = 0,
  TestModeOnCooldownMax = 6,
  TestModeEnergizeMin = 0,
  TestModeEnergizeMax = 7,
  TestModeShardMin = 0,
  TestModeShardMax = 5,
  TestModeShardFragmentMin = 0,
  TestModeShardFragmentMax = 50,
  TestModeHolyPowerMin = 0,
  TestModeHolyPowerMax = 5,
  TestModeChiMin = 0,
  TestModeChiMax = 6,
  TestModePointsMin = 0,
  TestModePointsMax = 10,
  TestModeArcaneChargesMin = 0,
  TestModeArcaneChargesMax = 4,
  TestModeStaggerMin = 0,
  TestModeStaggerMax = 4,
  TestModeStaggerPauseMin = 0,
  TestModeStaggerPauseMax = 3,
  TestModeAltPowerMin = 0,
  TestModeAltPowerMax = 100,
  TestModeAltMaxPowerMin = 0,
  TestModeAltMaxPowerMax = 99,
  TestModeAltPowerBarIDMin = 0,
  TestModeAltPowerBarIDMax = 500,
  TestModeAltPowerTimeMin = 0,
  TestModeAltPowerTimeMax = 60,

  -- Animation for all unitbars.
  AnimationOutTime = 1,
  AnimationInTime = 1,

  -- Bar fill FPS for all unitbars
  BarFillFPSMin = 10,
  BarFillFPSMax = 200,

  -- Text settings.
  MaxTextLines = 4,
  MaxValueNames = 6,

  -- Font text settings
  FontOffsetXMin = -150,
  FontOffsetXMax = 150,
  FontOffsetYMin = -150,
  FontOffsetYMax = 150,
  FontShadowOffsetMin = 0,
  FontShadowOffsetMax = 10,
  FontSizeMin = 1,
  FontSizeMax = 180,
  FontFieldWidthMin = 20,
  FontFieldWidthMax = 400,
  FontFieldHeightMin = 10,
  FontFieldHeightMax = 200,

  -- Trigger settings
  TriggerAnimateSpeedMin = 0.01,
  TriggerAnimateSpeedMax = 1,
  TriggerTextureScaleMin = 0.2,
  TriggerTextureScaleMax = 5,
  TriggerBarOffsetAllMin = -100,
  TriggerBarOffsetAllMax = 100,
  TriggerBarOffsetLeftMin = -100,
  TriggerBarOffsetLeftMax = 100,
  TriggerBarOffsetRightMin = -100,
  TriggerBarOffsetRightMax = 100,
  TriggerBarOffsetTopMin = -100,
  TriggerBarOffsetTopMax = 100,
  TriggerBarOffsetBottomMin = -100,
  TriggerBarOffsetBottomMax = 100,
  TriggerFontSizeMin = -180,
  TriggerFontSizeMax = 180,

  -- Layout settings
  LayoutBorderPaddingMin = -25,
  LayoutBorderPaddingMax = 50,
  LayoutRotationMin = 45,
  LayoutRotationMax = 360,
  LayoutSlopeMin = -100,
  LayoutSlopeMax = 100,
  LayoutPaddingMin = -50,
  LayoutPaddingMax = 50,
  LayoutSmoothFillMaxTimeMin = 0,
  LayoutSmoothFillMaxTimeMax = 2,
  LayoutSmoothFillSpeedMin = 0.01,
  LayoutSmoothFillSpeedMax = 1,
  LayoutTextureScaleMin = 0.55,
  LayoutTextureScaleMax = 5,
  LayoutAnimationInTimeMin = 0,
  LayoutAnimationInTimeMax = 1,
  LayoutAnimationOutTimeMin = 0,
  LayoutAnimationOutTimeMax = 1,
  LayoutAlignOffsetXMin = - 50,
  LayoutAlignOffsetXMax = 50,
  LayoutAlignOffsetYMin = -50,
  LayoutAlignOffsetYMax = 50,
  LayoutAlignPaddingXMin = -50,
  LayoutAlignPaddingXMax = 50,
  LayoutAlignPaddingYMin = -50,
  LayoutAlignPaddingYMax = 50,

  -- Backdrop and bar settings.
  UnitBarPaddingMin = -20,
  UnitBarPaddingMax = 20,

  -- Backdrop settings (Region and Background).
  UnitBarBgTileSizeMin = 1,
  UnitBarBgTileSizeMax = 100,
  UnitBarBorderSizeMin = 2,
  UnitBarBorderSizeMax = 32,

  -- Align and swap
  AlignSwapWidth = 415,
  AlignSwapHeight = 205,

  AlignSwapPaddingMin = -50,
  AlignSwapPaddingMax = 500,
  AlignSwapOffsetMin = -50,
  AlignSwapOffsetMax = 500,
  AlignSwapAdvancedMinMax = 25,

  -- Main options window size
  MainOptionsWidth = 770,
  MainOptionsHeight = 500,

  -- Attribute options
  UnitBarScaleMin = 0.10,
  UnitBarScaleMax = 4,
  UnitBarAlphaMin = 0.10,
  UnitBarAlphaMax = 1,

  -- Max Percent options
  UnitBarMaxPercentMin = .5,
  UnitBarMaxPercentMax = 2,

  -- Absorb size options
  UnitBarAbsorbSizeMin = .01,
  UnitBarAbsorbSizeMax = 1,

  -- Bar rotation options
  UnitBarRotationMin = -90,
  UnitBarRotationMax = 180,

  -- Bar size options
  UnitBarSizeMin = 15,
  UnitBarSizeMax = 500,
  UnitBarSizeAdvancedMinMax = 25,

  RuneOffsetXMin = -50,
  RuneOffsetXMax = 50,
  RuneOffsetYMin = -50,
  RuneOffsetYMax = 50,
}

local LSMStatusBarDropdown = LSM:HashTable('statusbar')
local LSMBorderDropdown = LSM:HashTable('border')
local LSMBackgroundDropdown = LSM:HashTable('background')
local LSMFontDropdown = LSM:HashTable('font')
local LSMSoundDropdown = LSM:HashTable('sound')

local FontStyleDropdown = {
  NONE = 'None',
  OUTLINE = 'Outline',
  THICKOUTLINE = 'Thick Outline',
 -- ['NONE, MONOCHROME'] = 'No Outline, Mono',  Disabled due to causing a client crash.
  ['OUTLINE, MONOCHROME'] = 'Outline, Mono',
  ['THICKOUTLINE, MONOCHROME'] = 'Thick Outline, Mono',
}

local FontHAlignDropdown = {
  LEFT = 'Left',
  CENTER = 'Center',
  RIGHT = 'Right'
}

local FontVAlignDropdown = {
  TOP = 'Top',
  MIDDLE = 'Middle',
  BOTTOM = 'Bottom',
}

local PositionDropdown = {
  LEFT = 'Left',
  RIGHT = 'Right',
  TOP = 'Top',
  BOTTOM = 'Bottom',
  TOPLEFT = 'Top Left',
  TOPRIGHT = 'Top Right',
  BOTTOMLEFT = 'Bottom Left',
  BOTTOMRIGHT = 'Bottom Right',
  CENTER = 'Center'
}

local ValueName_AllDropdown = { -- this isn't used anymore
  [99] = 'None',                -- 99
}

local ValueName_HapDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [7]  = 'Name',
  [8]  = 'Level',
  [99] = 'None',
}

local ValueName_HealthDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [3]  = 'Predicted Health',
  [6]  = 'Absorb Health',
  [7]  = 'Name',
  [8]  = 'Level',
  [99] = 'None',
}

local ValueName_PowerDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [4]  = 'Predicted Power',
  [5]  = 'Predicted Cost',
  [7]  = 'Name',
  [8]  = 'Level',
  [99] = 'None',
}

local ValueName_ManaDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [5]  = 'Predicted Cost',
  [7]  = 'Name',
  [8]  = 'Level',
  [99] = 'None',
}

local ValueName_RuneDropdown = {
  [12] = 'Time',
  [99] = 'None',
}

local ValueName_StaggerDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [12] = 'Time',
  [99] = 'None',
}

local ValueName_AltPowerDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [13] = 'Power Name',
}

local ValueName_AltCounterDropdown = {
  [9]  = 'Counter',
  [10] = 'Current Counter',
  [11] = 'Maximum Counter',
  [12] = 'Time',
  [13] = 'Power Name',
}

local ValueNameMenuDropdown = {
  all          = ValueName_AllDropdown,
  health       = ValueName_HealthDropdown,
  power        = ValueName_PowerDropdown,
  mana         = ValueName_ManaDropdown,
  hap          = ValueName_HapDropdown,
  rune         = ValueName_RuneDropdown,
  stagger      = ValueName_StaggerDropdown,
  staggerpause = ValueName_RuneDropdown,
  altpower     = ValueName_AltPowerDropdown,
  altcounter   = ValueName_AltCounterDropdown,
}

local ValueType_ValueDropdown = {
  'Whole',                -- 1
  'Short',                -- 2
  'Thousands',            -- 3
  'Millions',             -- 4
  'Whole (Groups)',       -- 5
  'Short (Groups)',       -- 6
  'Thousands (Groups)',   -- 7
  'Millions (Groups)',    -- 8
  'Percentage',           -- 9
}

local ValueType_NameDropdown = {
  [30] = 'Unit Name',
  [31] = 'Realm Name',
  [32] = 'Unit Name and Realm',
}

local ValueType_LevelDropdown = {
  [40] = 'Unit Level',
  [41] = 'Scaled Level',
  [42] = 'Unit Level and Scaled',
}

local ValueType_TimeDropdown = {
  [20] = 'Seconds',
  [21] = 'Seconds.0',
  [22] = 'Seconds.00',
}

local ValueType_WholeDropdown = {
  'Whole', -- 1
}

local ValueType_TextDropdown = {
  [50] = 'Text',
}

local ValueType_NoneDropdown = {
  [100] = '',
}

local ValueTypeMenuDropdown = {
  current         = ValueType_ValueDropdown,
  maximum         = ValueType_ValueDropdown,
  predictedhealth = ValueType_ValueDropdown,
  predictedpower  = ValueType_ValueDropdown,
  predictedcost   = ValueType_ValueDropdown,
  absorbhealth    = ValueType_ValueDropdown,
  name            = ValueType_NameDropdown,
  level           = ValueType_LevelDropdown,
  time            = ValueType_TimeDropdown,
  powername       = ValueType_TextDropdown,
  counter         = ValueType_WholeDropdown,
  countermin      = ValueType_WholeDropdown,
  countermax      = ValueType_WholeDropdown,
  none            = ValueType_NoneDropdown,

  -- prevent error if these values are found.
  unitname      = ValueType_NoneDropdown,
  realmname     = ValueType_NoneDropdown,
  unitnamerealm = ValueType_NoneDropdown,
}

local ConvertValueName = {
         current           = 1,
         maximum           = 2,
         predictedhealth   = 3,
         predictedpower    = 4,
         predictedcost     = 5,
         absorbhealth      = 6,
         name              = 7,
         level             = 8,
         counter           = 9,
         countermin        = 10,
         countermax        = 11,
         time              = 12,
         powername         = 13,
         none              = 99,
         'current',         -- 1
         'maximum',         -- 2
         'predictedhealth', -- 3
         'predictedpower',  -- 4
         'predictedcost',   -- 5
         'absorbhealth',    -- 6
         'name',            -- 7
         'level',           -- 8
         'counter',         -- 9
         'countermin',      -- 10
         'countermax',      -- 11
         'time',            -- 12
         'powername',       -- 13
  [99] = 'none',            -- 99
}

local ConvertValueType = {
  whole                    = 1,
  short                    = 2,
  thousands                = 3,
  millions                 = 4,
  whole_dgroups            = 5,
  short_dgroups            = 6,
  thousands_dgroups        = 7,
  millions_dgroups         = 8,
  percent                  = 9,
  timeSS                   = 20,
  timeSS_H                 = 21,
  timeSS_HH                = 22,
  unitname                 = 30,
  realmname                = 31,
  unitnamerealm            = 32,
  unitlevel                = 40,
  scaledlevel              = 41,
  unitlevelscaled          = 42,
  text                     = 50,
  [1]  = 'whole',
  [2]  = 'short',
  [3]  = 'thousands',
  [4]  = 'millions',
  [5]  = 'whole_dgroups',
  [6]  = 'short_dgroups',
  [7]  = 'thousands_dgroups',
  [8]  = 'millions_dgroups',
  [9]  = 'percent',
  [20] = 'timeSS',
  [21] = 'timeSS_H',
  [22] = 'timeSS_HH',
  [30] = 'unitname',
  [31] = 'realmname',
  [32] = 'unitnamerealm',
  [40] = 'unitlevel',
  [41] = 'scaledlevel',
  [42] = 'unitlevelscaled',
  [50] = 'text',
}

local TextLineDropdown = {
  [0] = 'All',
  [1] = 'Line 1',
  [2] = 'Line 2',
  [3] = 'Line 3',
  [4] = 'Line 4',
}

local DirectionDropdown = {
  HORIZONTAL = 'Horizontal',
  VERTICAL = 'Vertical'
}

local RuneModeDropdown = {
  rune = 'Runes',
  bar = 'Bars',
  runebar = 'Bars and Runes'
}

local FrameStrataDropdown = {
  'Background',
  'Low',
  'Medium (default)',
  'High',
  'Dialog',
  'Full Screen',
  'Full Screen Dialog',
  'Tooltip',
}

local ConvertFrameStrata = {
  BACKGROUND        = 1,
  LOW               = 2,
  MEDIUM            = 3,
  HIGH              = 4,
  DIALOG            = 5,
  FULLSCREEN        = 6,
  FULLSCREEN_DIALOG = 7,
  TOOLTIP           = 8,
  'BACKGROUND',           -- 1
  'LOW',                  -- 2
  'MEDIUM',               -- 3
  'HIGH',                 -- 4
  'DIALOG',               -- 5
  'FULLSCREEN',           -- 6
  'FULLSCREEN_DIALOG',    -- 7
  'TOOLTIP',              -- 8
}

local TalentType = {
  ['T=']  = 'PvE',
  ['T<>'] = 'PvE',
  ['P=']  = 'PvP',
  ['P<>'] = 'PvP'
}

local Operator_WholePercentDropdown = {
  '<',             -- 1
  '>',             -- 2
  '<=',            -- 3
  '>=',            -- 4
  '=',             -- 5
  '<>',            -- 6
  'T=',            -- 7
  'T<>',           -- 8
  'P=',            -- 9
  'P<>',           -- 10
}

local Operator_AurasDropdown = {
  'and',    -- 1
  'or',     -- 2
}

local Operator_StringDropdown = {
  '=',  -- 1
  '<>', -- 2
}

local TriggerOperatorDropdown = {
  whole   = Operator_WholePercentDropdown,
  percent = Operator_WholePercentDropdown,
  float   = Operator_WholePercentDropdown,
  string  = Operator_StringDropdown,
  auras   = Operator_AurasDropdown,
}

local TriggerSoundChannelDropdown = {
  Ambience = 'Ambience',
  Master = 'Master',
  Music = 'Music',
  SFX = 'Sound Effects',
  Dialog = 'Dialog',
}

local AuraStackOperatorDropdown = {
  '<',             -- 1
  '>',             -- 2
  '<=',            -- 3
  '>=',            -- 4
  '=',             -- 5
  '<>',            -- 6
}

local AnimationTypeDropdown = {
  alpha = 'Alpha',
  scale = 'Scale',
}

local ConvertTypeIDColorIcon = {
  bartexturecolor = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBarColor]],
  bartexture      = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBar]],
  border          = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBorder]],
  bordercolor     = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBorderColor]],
  texturescale    = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextureScale]],
  baroffset       = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerChangeOffset]],
  sound           = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerSound]],
  background      = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBackground]],
  backgroundcolor = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBackgroundColor]],
  fontsize        = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextChangeSize]],
  fontoffset      = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextChangeOffset]],
  fontcolor       = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextColor]],
  fonttype        = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextType]],
  fontstyle       = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextOutline]],
}

--*****************************************************************************
--
-- Options Utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- ToHex
--
-- Returns a hexidecimal address of a function or table.
-------------------------------------------------------------------------------
local function ToHex(Object)
   return strtrim(select(2, strsplit(':', tostring(Object))))
end

-------------------------------------------------------------------------------
-- FindMenuItem
--
-- Searches for a Value in an indexed array. Returns the Index found. or 1
--
-- Table       Any indexed array
-- Value       Value to search for.  Must be an exact match. Case is not sensitive.
--
-- Returns:
--   Index    Table element containing value
--   Item     Returns the item found in the menu in lowercase. If item is not found then
--            this equals the first item in the menu.
-------------------------------------------------------------------------------
local function FindMenuItem(Table, Value)
  local Item = nil

  Value = strlower(Value)
  for Index = 1, #Table do
    local i = strlower(Table[Index])

    if Index == 1 then
      Item = i
    end
    if i == Value then
      return Index, i
    end
  end
  return 1, Item
end

-------------------------------------------------------------------------------
-- RefreshMainOptions
--
-- Refreshes the option panels.
-- Use this if something needs updating.
-------------------------------------------------------------------------------
function GUB.Options:RefreshMainOptions()
  AceConfigRegistery:NotifyChange(AddonMainOptions)
end

-------------------------------------------------------------------------------
-- RefreshAlignSwapOptions
--
-- Refreshes the option panels.
-- Use this if something needs updating.
-------------------------------------------------------------------------------
function GUB.Options:RefreshAlignSwapOptions()
  AceConfigRegistery:NotifyChange(AddonAlignSwapOptions)
end

-------------------------------------------------------------------------------
-- CloseMainOptions
--
-- Closes the main options window.
-------------------------------------------------------------------------------
function GUB.Options:CloseMainOptions()
  AceConfigDialog:Close(AddonMainOptions)
end

-------------------------------------------------------------------------------
-- CloseAlignSwapOptions
--
-- Closes the aling and swap options window
-------------------------------------------------------------------------------
function GUB.Options:CloseAlignSwapOptions()
  AceConfigDialog:Close(AddonAlignSwapOptions)
end

-------------------------------------------------------------------------------
-- Flag
--
-- Returns true if the flag is nil or its value if it does.
--
-- NilValue   The value returned if the Value is nil.
-------------------------------------------------------------------------------
local function Flag(NilValue, Value)
  if Value == nil then
    return NilValue
  else
    return Value
  end
end

-------------------------------------------------------------------------------
-- HideTooltip
--
-- Hides the tooltip based on a boolean value. Boolean value gets returned.
-- Used in for buttons that get disabled so the tooltip will close.
--
-- If true then tooltip is hidden, otherwise nothing is done.
-------------------------------------------------------------------------------
local function HideTooltip(Action)
  if Action then
    GameTooltip:Hide()
  end
  return Action
end

-------------------------------------------------------------------------------
-- DoFunction
--
-- Stores a list of functions that can be called on to change settings.
--
-- Object          Object to save the function under.
-- Name            Name to use to call the function.
--                 if 'clear' then all the functions under Object are erased.
-- Fn              Function to be saved. If fn is nil then FunctionName() gets called.
--                 if 'erase' then will erase the function.
--
-- Returns:
--   Function      The function that was passed.
-------------------------------------------------------------------------------
function GUB.Options:DoFunction(Object, Name, Fn)
  if Fn then

    -- Save the function under Object FunctionName
    local DoFunction = DoFunctions[Object]

    if DoFunction == nil then
      DoFunction = {}
      DoFunctions[Object] = DoFunction
    end

    if Fn == 'erase' then
      Fn = nil
    end
    DoFunction[Name] = Fn

    return Fn
  elseif Name == 'clear' then
    if DoFunctions[Object] then

      -- Wipe the table instead of nilling. Incase this function gets called thru DoFunction.
      wipe(DoFunctions[Object])
    end
  elseif Name then

    -- Call function by name
    DoFunctions[Object][Name]()
  else
    -- Call all functions if Fn not passed.
    for _, DF in pairs(DoFunctions) do
      for _, Fn in pairs(DF) do
        Fn()
      end
    end
  end
end

-------------------------------------------------------------------------------
-- CreateSpacer
--
-- Creates type 'description' for full width.  This is used to create a blank
-- line so that option elements appear in certain places on the screen.
--
-- Order         Order number
-- Width         Optional width.
-- HiddenFn      If not nil then will supply a function that will make the
--               spacer hidden or not.
-------------------------------------------------------------------------------
local function CreateSpacer(Order, Width, HiddenFn)
  return {
    type = 'description',
    name = '',
    order = Order,
    width = Width or 'full',
    hidden = HiddenFn,
  }
end

--*****************************************************************************
--
-- Options creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- CreateToGUBOptions
--
-- Creates an option that takes you to the GUB options frame.
--
-- Order     Position in the options list.
-- Name      Name of the options.
-- Desc      Description when mousing over the options name.
-------------------------------------------------------------------------------
local function OnHideToGUBOptions()
  MainOptionsHideFrame:SetScript('OnHide', nil)
  Bar:SetHighlightFont('off', Main.UnitBars.HideTextHighlight)
  Options.MainOptionsOpen = false
end

local function CreateToGUBOptions(Order, Name, Desc)
  local ToGUBOptions = {
    type = 'execute',
    name = Name,
    order = Order,
    desc = Desc,
    func = function()

             -- check for in combat
             if not Main.InCombat then

               -- Hide blizz blizz options if it's opened.
               if InterfaceOptionsFrame:IsVisible() then
                 InterfaceOptionsFrame:Hide()

                 -- Hide the UI panel behind blizz options.
                 HideUIPanel(GameMenuFrame)
               end

               Bar:SetHighlightFont('on', Main.UnitBars.HideTextHighlight)
               Options.MainOptionsOpen = true

               -- Open a movable options frame.
               AceConfigDialog:SetDefaultSize(AddonMainOptions, o.MainOptionsWidth, o.MainOptionsHeight)

               AceConfigDialog:Open(AddonMainOptions)

               -- Set the OnHideFrame's frame parent to AceConfigDialog's options frame.
               MainOptionsHideFrame:SetParent(AceConfigDialog.OpenFrames[AddonMainOptions].frame)

               -- When hidden call OnHideToGUBOptions for close.
               MainOptionsHideFrame:SetScript('OnHide', OnHideToGUBOptions)
             else
               print(InCombatOptionsMessage)
             end
           end,
  }
  return ToGUBOptions
end

-------------------------------------------------------------------------------
-- CreateSlashOptions()
--
-- Returns a slash options table for unitbars.
-------------------------------------------------------------------------------
local function CreateSlashOptions()
  local SlashOptions = {
    type = 'group',
    name = 'slash command',
    order = 1,
    args = {
      about = {
        type = 'execute',
        name = 'about',
        order = 2,
        func = function()
                 print(AddonName, format('Version %.2f', Version / 100))
               end,
      },
      config = CreateToGUBOptions(2, '', 'Opens a movable options frame'),
      c = CreateToGUBOptions(3, '', 'Same as config'),
    },
  }
  return SlashOptions
end

-------------------------------------------------------------------------------
-- CreateOptionsToGUB()
--
-- Creates options to be used in blizz options that takes you to GUB options
-- that can be moved.
-------------------------------------------------------------------------------
local function CreateOptionsToGUB()
  local OptionsToGUB = {
    name = AddonName,
    type = 'group',
    order = 1,
    args = {
      ToGUBOptions = CreateToGUBOptions(1, 'GUB Options', 'Opens GUB options'),
    },
  }
  return OptionsToGUB
end

-------------------------------------------------------------------------------
-- CreateColorAllOptions
--
-- Creates all color options that support multiple colors.
--
-- Subfunction of CreateBackdropOptions()
-- Subfunction of CreateBarOptions()
-- Subfunction of CreateTextOptions()
-- Subfunction of CreateMoreLayoutRuneBarOptions()
--
--
-- BarType            Type of options being created.
-- TableName          Where the color is stored.
-- ColorPath          Table path to where the color data is stored.
-- KeyName            Name of the color table.
-- Order              Position in the options list.
-- Name               Name of the options.
--
-- ColorAllOptions  Options table for the bartype.
-------------------------------------------------------------------------------
local function CreateColorAllOptions(BarType, TableName, ColorPath, KeyName, Order, Name)
  local UBF = UnitBarsF[BarType]
  local Names = UBF.Names

  -- Get max colors
  local MaxColors = #Main:GetUB(BarType, ColorPath)

  local ColorAllOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local ColorIndex = tonumber(Info[#Info])
            local c = Main:GetUB(BarType, ColorPath)

            if ColorIndex > 0 then
              c = c[ColorIndex]
            end
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local ColorIndex = tonumber(Info[#Info])
            local c = Main:GetUB(BarType, ColorPath)

            if ColorIndex > 0 then
              c = c[ColorIndex]
            end
            c.r, c.g, c.b, c.a = r, g, b, a

            -- Set the color to the bar
            UBF:SetAttr(TableName, KeyName)
          end,
    args = {
      ColorAllToggle = {
        type = 'toggle',
        name = 'All',
        order = 1,
        desc = 'Everything can be set to one color',
        get = function()
                return Main:GetUB(BarType, ColorPath).All
              end,
        set = function(Info, Value)
                Main:GetUB(BarType, ColorPath).All = Value

                -- Refresh colors when changing between all and normal.
                UBF:SetAttr(TableName, KeyName)
              end,
      },
      ['0'] = {
        type = 'color',
        name = 'Color',
        order = 2,
        hasAlpha = true,
        desc = 'Set everything to one color',
        hidden = function()
                   return not Main:GetUB(BarType, ColorPath).All
                 end,
      },
      Spacer = CreateSpacer(3),
    },
  }
  local CAOA = ColorAllOptions.args
  local Offset = Main:GetUB(BarType, ColorPath .. '._Offset', DUB) or 0

  for ColorIndex = 1, #Main:GetUB(BarType, ColorPath) do
    local Name = Names[ColorIndex + Offset]
    local ColorOption = {}

    --- Create the color table
    ColorOption.type = 'color'
    ColorOption.name = Name
    ColorOption.order = ColorIndex + 3
    ColorOption.hasAlpha = true
    ColorOption.hidden = function()
                           return Main:GetUB(BarType, ColorPath).All
                         end

    -- Add it to the options table
    CAOA[format('%s', ColorIndex)] = ColorOption
  end

  return ColorAllOptions
end

-------------------------------------------------------------------------------
-- GroupDisabled
--
-- Returns true if the DisableGroup should be disabled
--
-- Subfunction of CreateColorAllSelectOptions()
--
-- BarType     Type options being created.
-- TableName   Name of the table in the unitbar
-- UBF         Unitbar Frame
-------------------------------------------------------------------------------
local function GroupDisabled(BarType, TableName, UBF)
  local GreenFire = UBF.GreenFire
  local BurningEmbers = UBF.UnitBar.Layout.BurningEmbers

  if BarType == 'FragmentBar' then
    if TableName == 'BackgroundShard' or TableName == 'BarShard' then
      return BurningEmbers
    elseif TableName == 'BackgroundEmber' or TableName == 'BarEmber' then
      return not BurningEmbers
    end
  else
    return false
  end
end

-------------------------------------------------------------------------------
-- CreateColorAllSelectOptions
--
-- Allows multiple color all options to be selected by choosing a check box
--
-- BarType            Type of options being created.
-- TableName          Where the color is stored.
-- TableType          bar, bg, border
-- Order              Position in the options list.
-- Name               Name of the options.
--
-- NOTES: This saves the current menu selection into SelectedMenuButtonName
--        So if you had Green Fire selected on Ember.  The table would be like this:
--        SelectedMenuButtonName = { EmberShard = 'Green Fire' }
--        Each background and bar has one of these that uses this function in the defaults.
-------------------------------------------------------------------------------
local function CreateColorAllSelectOptions(BarType, TableType, TableName, Order, Name)
  local UBF = UnitBarsF[BarType]
  local SelectedMenuButtonName = UBF.UnitBar[TableName].ColorAllSelect[TableType]
  local MenuAllButtons = nil

  if BarType == 'FragmentBar' then
    if TableType == 'bar' then
      MenuAllButtons = {
        Color                 = { Order = 1, Width = 'half',   KeyName = 'Color',             ColorPath = '.Color',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or UBF.GreenFire end },
        ['Green Fire']        = { Order = 2, Width = 'normal', Keyname = 'ColorGreen',        ColorPath = '.ColorGreen',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or not UBF.GreenFire end },
      }
    end
    if TableType == 'barfull' then
      MenuAllButtons = {
        Color                 = { Order = 1, Width = 'half',   KeyName = 'ColorFull',         ColorPath = '.ColorFull',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or UBF.GreenFire end },
        ['Green Fire']        = { Order = 2, Width = 'normal', KeyName = 'ColorFullGreen',    ColorPath = '.ColorFullGreen',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or not UBF.GreenFire end },
      }
    end
    if TableType == 'bg' then
      MenuAllButtons = {
        Color                 = { Order = 1, Width = 'half',   KeyName = 'Color',             ColorPath = '.Color',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or UBF.GreenFire end },
        ['Green Fire']        = { Order = 2, Width = 'normal', Keyname = 'ColorGreen',        ColorPath = '.ColorGreen',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or not UBF.GreenFire end },
      }
    end
    if TableType == 'border' then
      MenuAllButtons = {
        Color                 = { Order = 1, Width = 'half',   KeyName = 'BorderColor',       ColorPath = '.BorderColor',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or UBF.GreenFire or
                                                                not UBF.UnitBar[TableName].EnableBorderColor end },
        ['Green Fire']        = { Order = 2, Width = 'normal', Keyname = 'BorderColorGreen',  ColorPath = '.BorderColorGreen',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or not UBF.GreenFire or
                                                                not UBF.UnitBar[TableName].EnableBorderColor end },
      }
    end
  end
  if BarType == 'RuneBar' then
    if TableType == 'bar' then
      MenuAllButtons = {
        Blood                 = { Order = 1, Width = 'half',   KeyName = 'ColorBlood',        ColorPath = '.ColorBlood',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 1 end },
        Frost                 = { Order = 2, Width = 'half',   KeyName = 'ColorFrost',        ColorPath = '.ColorFrost',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 2 end },
        Unholy                = { Order = 3, Width = 'half',   KeyName = 'ColorUnholy',       ColorPath = '.ColorUnholy',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 3 end },
      }
    end
    if TableType == 'bg' then
      MenuAllButtons = {
        Blood                 = { Order = 1, Width = 'half',   KeyName = 'ColorBlood',        ColorPath = '.ColorBlood',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 1 end },
        Frost                 = { Order = 2, Width = 'half',   KeyName = 'ColorFrost',        ColorPath = '.ColorFrost',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 2 end },
        Unholy                = { Order = 3, Width = 'half',   KeyName = 'ColorUnholy',       ColorPath = '.ColorUnholy',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 3 end },
      }
    end
    if TableType == 'border' then
      MenuAllButtons = {
        Blood                 = { Order = 1, Width = 'half',   KeyName = 'BorderColorBlood',  ColorPath = '.BorderColorBlood',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 1 end },
        Frost                 = { Order = 2, Width = 'half',   KeyName = 'BorderColorFrost',  ColorPath = '.BorderColorFrost',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 2 end },
        Unholy                = { Order = 3, Width = 'half',   KeyName = 'BorderColorUnholy', ColorPath = '.BorderColorUnholy',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 3 end },
      }
    end
  end

  local ColorAllSelectOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    args = {},
  }

  local Args = ColorAllSelectOptions.args

  Args.MenuLine = {
    type = 'header',
    name = '',
    order = 10,
    width = 'full',
  }

  -- Create the menu buttons
  for MenuButtonName, MenuButton in pairs(MenuAllButtons) do
    Args[MenuButtonName] = {
      type = 'input',
      order = MenuButton.Order,
      name = function()
               if SelectedMenuButtonName == MenuButtonName then
                   return format('%s:2', MenuButtonName)
                 else
                   return format('%s', MenuButtonName)
                 end
               end,
      width = MenuButton.Width,
      dialogControl = 'GUB_Menu_Button',
      set = function()
              SelectedMenuButtonName = MenuButtonName
              -- Save selection
              UBF.UnitBar[TableName].ColorAllSelect[TableType] = SelectedMenuButtonName
            end,
    }
    -- Create color group
    local ColorAllOptions = CreateColorAllOptions(BarType, TableName, TableName .. MenuButton.ColorPath, MenuButton.KeyName, 100, '')
    ColorAllOptions.hidden = function()
                               return SelectedMenuButtonName ~= MenuButtonName
                             end
    ColorAllOptions.disabled = MenuButton.DisableFn
    Args[MenuButtonName .. '_Group'] = ColorAllOptions
  end

  return ColorAllSelectOptions
end

-------------------------------------------------------------------------------
-- CreateBackdropOptions
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType     Type options being created.
-- TableName   Background + TableName
-- Order       Position in the options list.
-- Name        Name of the options.
-------------------------------------------------------------------------------
local function CreateBackdropOptions(BarType, TableName, Order, Name)
  local UBF = UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local BackdropOptions = {
    type = 'group',
    name = function()
             local Tag = ''
             if BarType == 'FragmentBar' and TableName ~= 'Region' then
               if UBF.GreenFire then
                 Tag = ' [Green Fire]'
               end
               if not GroupDisabled(BarType, TableName, UBF) then
                 return Name .. Tag .. ' *'
               end
             end
             return Name .. Tag
           end,
    order = Order,
    args = {
      DisableGroup = {
        type = 'group',
        name = '',
        dialogInline = true,
        order = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
        args = {
          General = {
            type = 'group',
            name = 'General',
            dialogInline = true,
            order = 1,
            get = function(Info)
                    local KeyName = Info[#Info]
                    local Value = UBF.UnitBar[TableName][KeyName]

                    if KeyName ~= 'EnableBorderColor' and strfind(KeyName, 'Color') then
                      return Value.r, Value.g, Value.b, Value.a
                    else
                      return Value
                    end
                  end,
            set = function(Info, Value, g, b, a)
                    local KeyName = Info[#Info]

                    if KeyName == 'EnableBorderColor' then
                      UBF.UnitBar[TableName][KeyName] = Value
                      if BarType == 'FragmentBar' then

                        UBF:SetAttr(TableName, 'BorderColor')
                        UBF:SetAttr(TableName, 'BorderColorGreen')
                      elseif BarType == 'RuneBar' then

                        UBF:SetAttr(TableName, 'BorderColorBlood')
                        UBF:SetAttr(TableName, 'BorderColorFrost')
                        UBF:SetAttr(TableName, 'BorderColorUnholy')
                      else
                        UBF:SetAttr(TableName, 'BorderColor')
                      end

                    elseif strfind(KeyName, 'Color') then
                      local c = UBF.UnitBar[TableName][KeyName]

                      c.r, c.g, c.b, c.a = Value, g, b, a
                      UBF:SetAttr(TableName, KeyName)
                    else
                      UBF.UnitBar[TableName][KeyName] = Value
                      UBF:SetAttr(TableName, KeyName)
                    end
                  end,
            args = {
              BorderTexture = {
                type = 'select',
                name = 'Border',
                order = 1,
                dialogControl = 'LSM30_Border',
                values = LSMBorderDropdown,
              },
              BgTexture = {
                type = 'select',
                name = 'Background',
                order = 2,
                dialogControl = 'LSM30_Background',
                values = LSMBackgroundDropdown,
              },
              Spacer10 = CreateSpacer(10),
              BgTile = {
                type = 'toggle',
                name = 'Tile Background',
                order = 11,
              },
              BgTileSize = {
                type = 'range',
                name = 'Background Tile Size',
                order = 12,
                disabled = function()
                             return not UBF.UnitBar[TableName].BgTile
                           end,
                min = o.UnitBarBgTileSizeMin,
                max = o.UnitBarBgTileSizeMax,
                step = 1,
              },
              Spacer20 = CreateSpacer(20),
              BorderSize = {
                type = 'range',
                name = 'Border Thickness',
                order = 21,
                min = o.UnitBarBorderSizeMin,
                max = o.UnitBarBorderSizeMax,
                step = 2,
              },
            },
          },
        },
      },
    },
  }

  local BackdropArgs = BackdropOptions.args.DisableGroup.args
  local GeneralArgs = BackdropArgs.General.args

  if TableName ~= 'Region' then
    if UBD[TableName].EnableBorderColor ~= nil then
      GeneralArgs.Spacer30 = CreateSpacer(30)
      GeneralArgs.EnableBorderColor = {
        type = 'toggle',
        name = 'Enable Border Color',
        order = 32,
      }
    end
    -- Fragment bar options
    if BarType == 'FragmentBar' or BarType == 'RuneBar' then
      -- Remove default color all options
      BackdropArgs.ColorAllSelect = CreateColorAllSelectOptions(BarType, 'bg',  TableName, 2, 'Color')
      BackdropArgs.BorderColorAllSelect = CreateColorAllSelectOptions(BarType, 'border',  TableName, 3, 'Border Color')
      BackdropArgs.BorderColorAllSelect.disabled = function()
                                                     return not UBF.UnitBar[TableName].EnableBorderColor
                                                   end
    else
      -- All other unitbar color options.
      if UBD[TableName].Color.All == nil then
        GeneralArgs.Color = {
          type = 'color',
          name = 'Background Color',
          order = 22,
          hasAlpha = true,
        }
      else
        BackdropArgs.ColorAll = CreateColorAllOptions(BarType, TableName, TableName .. '.Color', 'Color', 2, 'Color')
      end
      if UBD[TableName].BorderColor.All == nil then
        GeneralArgs.BorderColor = {
          type = 'color',
          name = 'Border Color',
          order = 33,
          hasAlpha = true,
          disabled = function()
                      return not UBF.UnitBar[TableName].EnableBorderColor
                    end,
        }
      else
        BackdropArgs.BorderColorAll = CreateColorAllOptions(BarType, TableName, TableName .. '.BorderColor', 'BorderColor', 3, 'Border Color')
        BackdropArgs.BorderColorAll.disabled = function()
                                                 return not UBF.UnitBar[TableName].EnableBorderColor
                                               end
      end
    end
  else
    -- Region option
    GeneralArgs.Color = {
      type = 'color',
      name = 'Background Color',
      order = 22,
      hasAlpha = true,
    }
    GeneralArgs.Spacer30 = CreateSpacer(30)
    GeneralArgs.EnableBorderColor = {
      type = 'toggle',
      name = 'Enable Border Color',
      order = 32,
    }
    GeneralArgs.BorderColor = {
      type = 'color',
      name = 'Border Color',
      order = 33,
      hasAlpha = true,
      disabled = function()
                   return not UBF.UnitBar[TableName].EnableBorderColor
                 end,
    }
  end

  BackdropArgs.Padding = {
    type = 'group',
    name = 'Padding',
    dialogInline = true,
    order = 10,
    get = function(Info)
            local Padding = UBF.UnitBar[TableName].Padding
            local KeyName = Info[#Info]

            if KeyName == 'All' then
              return Padding.Left
            else
              return Padding[KeyName]
            end
          end,
    set = function(Info, Value)
            local Padding = UBF.UnitBar[TableName].Padding
            local KeyName = Info[#Info]

            if KeyName == 'All' then
              Padding.Left = Value
              Padding.Right = Value
              Padding.Top = Value
              Padding.Bottom = Value
            else
              Padding[KeyName] = Value
            end
            UBF:SetAttr(TableName, 'Padding')
          end,
    args = {
      PaddingAll = {
        type = 'toggle',
        name = 'All',
        order = 1,
        get = function()
                return UBF.UnitBar[TableName].PaddingAll
              end,
        set = function(Info, Value)
                UBF.UnitBar[TableName].PaddingAll = Value
              end,
        desc = 'Change padding with one value'
      },
      Spacer = CreateSpacer(2),
      All = {
        type = 'range',
        name = 'Offset',
        order = 3,
        hidden = function()
                   return not UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
      },
      Left = {
        type = 'range',
        name = 'Left',
        order = 4,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
      },
      Right = {
        type = 'range',
        name = 'Right',
        order = 5,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
      },
      Top = {
        type = 'range',
        name = 'Top',
        order = 6,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
      },
      Bottom = {
        type = 'range',
        name = 'Bottom',
        order = 7,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
      },
    },
  }

  return BackdropOptions
end

-------------------------------------------------------------------------------
-- CreateAbsorbOptions
--
-- Subfunction of CreateBarOptions()
--
-- Allows the user to set the way absorbs are shown
--
-- BarType     Type of options being created.
-- Order       Position in the options list.
-- Name        Name of the options.
-------------------------------------------------------------------------------
local function CreateAbsorbOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local AbsorbOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Bar[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            UBF.UnitBar.Bar[KeyName] = Value
            UBF:SetAttr('Bar', '_Absorb')
          end,
    args = {
      AbsorbBarDontClip = {
        type = 'toggle',
        name = "Don't Clip Absorb Bar",
        desc = 'Will always show the absorb bar instead of being pushed off',
        width = 'double',
        order = 1,
      },
      AbsorbBarSize = {
        type = 'range',
        name = 'Absorb Bar Size',
        order = 2,
        desc = 'Shrinks the absorb bar by the percentage set',
        width = 'full',
        step = .01,
        isPercent = true,
        min = o.UnitBarAbsorbSizeMin,
        max = o.UnitBarAbsorbSizeMax,
      },
    },
  }

  return AbsorbOptions
end

-------------------------------------------------------------------------------
-- CreateBarSizeOptions
--
-- Subfunction of CreateBarOptions()
--
-- Allows the user to change size of bars then offset them for finer sizing.
--
-- BarType     Type of options being created.
-- TableName   Table found in UnitBars[BarType]
-- Order       Position in the options list.
-- Name        Name of the options.
-------------------------------------------------------------------------------
local function CreateBarSizeOptions(BarType, TableName, Order, Name)
  local UBF = UnitBarsF[BarType]
  local BarSizeOptions = nil

  local function SetSize()
    local UB = UBF.UnitBar[TableName]
    for KeyName in pairs(BarSizeOptions.args) do
      local SliderArgs = BarSizeOptions.args[KeyName]
      local Min = nil
      local Max = nil

      if KeyName == 'Width' or KeyName == 'Height' then
        Min = o.UnitBarSizeMin
        Max = o.UnitBarSizeMax
      end
      if Min and Max then
        local Value = UB[KeyName]

        if UB.Advanced then
          Value = Value < Min and Min or Value > Max and Max or Value
          UB[KeyName] = Value
          SliderArgs.min = Value - o.UnitBarSizeAdvancedMinMax
          SliderArgs.max = Value + o.UnitBarSizeAdvancedMinMax
          SliderArgs.name = format('Advanced %s', KeyName)
        else
          SliderArgs.min = Min
          SliderArgs.max = Max
          SliderArgs.name = KeyName
        end
      end
    end
  end

  BarSizeOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            SetSize()
            return UBF.UnitBar[TableName][Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar[TableName][Info[#Info]] = Value
            SetSize()
            UBF:SetAttr(TableName, '_Size')
          end,
    args = {
      Advanced = {
        type = 'toggle',
        name = 'Advanced',
        desc = 'Allows you to make fine tune adjustments easier',
        order = 1,
        get = function()
                SetSize()
                return UBF.UnitBar[TableName].Advanced
              end,
        set = function(Info, Value)
                UBF.UnitBar[TableName].Advanced = Value
                SetSize()
              end,
      },
      Width = {
        type = 'range',
        name = '',
        order = 2,
        desc = 'Slide or click anywhere on the slider to change the width',
        width = 'full',
        step = 1,
      },
      Height = {
        type = 'range',
        name = '',
        order = 3,
        desc = 'Slide or click anywhere on the slider to change the height',
        width = 'full',
        step = 1,
      },
    },
  }

  return BarSizeOptions
end

-------------------------------------------------------------------------------
-- CreateBarOptions
--
-- Creates bar options for a unitbar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType     Type of options being created.
-- TableName   Name of the table containing the options.
-- Order       Position in the options list.
-- Name        Name of the options.
-------------------------------------------------------------------------------
local function CreateBarOptions(BarType, TableName, Order, Name)
  local UBF = UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local BarOptions = {
    type = 'group',
    name = function()
             local Tag = ''
             if BarType == 'FragmentBar' and TableName ~= 'Region' then
               if UBF.GreenFire then
                 Tag = ' [Green Fire]'
               end
               if not GroupDisabled(BarType, TableName, UBF) then
                 return Name .. Tag .. ' *'
               end
             end
             return Name .. Tag
           end,
    order = Order,
    args = {
      DisableGroup = {
        type = 'group',
        name = '',
        dialogInline = true,
        order = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
        args = {
          General = {
            type = 'group',
            name = 'General',
            dialogInline = true,
            order = 1,
            get = function(Info)
                    local KeyName = Info[#Info]

                    if strfind(KeyName, 'Color') then
                      local c = UBF.UnitBar[TableName][KeyName]

                      return c.r, c.g, c.b, c.a
                    else
                      return UBF.UnitBar[TableName][KeyName]
                    end
                  end,
            set = function(Info, Value, g, b, a)
                    local KeyName = Info[#Info]


                    if strfind(KeyName, 'Color') then
                      local c = UBF.UnitBar[TableName][KeyName]

                      c.r, c.g, c.b, c.a = Value, g, b, a
                      UBF:SetAttr(TableName, KeyName)
                    else
                      UBF.UnitBar[TableName][KeyName] = Value
                      UBF:SetAttr(TableName, KeyName)
                    end
                  end,
            args = {},
          },
        },
      },
    },
  }

  local BarArgs = BarOptions.args.DisableGroup.args
  local GeneralArgs = BarArgs.General.args

  -- Normal health and power bar.
  if UBD[TableName].StatusBarTexture ~= nil then
    GeneralArgs.StatusBarTexture = {
      type = 'select',
      name = 'Bar Texture',
      order = 1,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }

    GeneralArgs.Spacer2 = CreateSpacer(2, 'half')

    -- Regular color
    local Color = UBD[TableName].Color
    if Color ~= nil and Color.All == nil then
      GeneralArgs.Color = {
        type = 'color',
        name = 'Color',
        hasAlpha = true,
        order = 3,
      }
      -- Only for power bars
      if UBD.Layout.UseBarColor ~= nil then
        GeneralArgs.Color.disabled = function()
                                       return not UBF.UnitBar.Layout.UseBarColor
                                     end
      end
      -- Only for health bars
      if UBD.Layout.ClassColor ~= nil then
        GeneralArgs.Color.disabled = function()
                                       return UBF.UnitBar.Layout.ClassColor or UBF.UnitBar.Layout.CombatColor
                                     end
      end
    end
  end

  -- Predicted Health and Power bar.
  if UBD[TableName].PredictedBarTexture ~= nil then
    GeneralArgs.Spacer10 = CreateSpacer(10)

    GeneralArgs.PredictedBarTexture = {
      type = 'select',
      name = UBF.IsHealth and 'Bar Texture (predicted health)' or
                              'Bar Texture (predicted power)' ,
      order = 11,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }

    GeneralArgs.Spacer12 = CreateSpacer(12, 'half')

    -- Predicted color
    if UBD[TableName].PredictedColor ~= nil then
      GeneralArgs.PredictedColor = {
        type = 'color',
        name = UBF.IsHealth and 'Color (predicted health)' or
                                'Color (predicted power)' ,
        hasAlpha = true,
        order = 13,
      }
    end
  end

  -- Absorb Health bar.
  if UBD[TableName].AbsorbBarTexture ~= nil then
    GeneralArgs.Spacer14 = CreateSpacer(14)

    GeneralArgs.AbsorbBarTexture = {
      type = 'select',
      name = 'Bar Texture (absorb health)',
      order = 15,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }

    GeneralArgs.Spacer16 = CreateSpacer(16, 'half')

    -- absorb color
    if UBD[TableName].AbsorbColor ~= nil then
      GeneralArgs.AbsorbColor = {
        type = 'color',
        name = 'Color (absorb health)',
        hasAlpha = true,
        order = 17,
      }
    end
  end

  -- Predicted cost bar
  if UBD[TableName].PredictedCostBarTexture ~= nil then
    GeneralArgs.Spacer20 = CreateSpacer(20)

    GeneralArgs.PredictedCostBarTexture = {
      type = 'select',
      name = 'Bar Texture (predicted cost)',
      order = 21,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }

    GeneralArgs.Spacer22 = CreateSpacer(22, 'half')

    -- Predicted cost color
    if UBD[TableName].PredictedCostColor ~= nil then
      GeneralArgs.PredictedCostColor = {
        type = 'color',
        name = 'Color (predicted cost)',
        hasAlpha = true,
        order = 23,
      }
    end
  end

  -- For fragment bar
  -- Can use the same order numbers as predictedbartexture
  -- since both of these never happen at the same time.
  if BarType == 'FragmentBar' then
    GeneralArgs.Spacer20 = CreateSpacer(20)

    GeneralArgs.FullBarTexture = {
      type = 'select',
      name = 'Bar Texture (full)',
      order = 21,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }
  end

  -- Stagger bar
  if BarType == 'StaggerBar' and TableName == 'BarStagger' then
    -- Stagger group
    GeneralArgs.StaggerGroup = {
      type = 'group',
      order = 9,
      dialogInline = true,
      hidden = function()
                 return not UBF.UnitBar.Layout.Layered and not UBF.UnitBar.Layout.SideBySide
               end,
      args = {}
    }
    local StaggerGeneralArgs = GeneralArgs.StaggerGroup.args

    GeneralArgs.StaggerGroup.name = function()
                                      return format('|cffffff00Continued (%s%% to %s%%)|r', StaggerGeneralArgs.MaxPercentBStagger.min * 100,
                                                                                            UBF.UnitBar[TableName].MaxPercentBStagger * 100)
                                    end
    -- This section cant be part of the group
    GeneralArgs.MaxPercent = {
      type = 'range',
      name = 'Max Percent',
      desc = 'Changes how much percentage it takes to fill the bar',
      order = 5,
      step = .01,
      width = 'full',
      isPercent = true,
      get = function()
              local Value = UBF.UnitBar[TableName].MaxPercent

              -- Set the min/max percents for second bar
              local Min = Value + .01
              local Max = Value + o.UnitBarMaxPercentMax

              StaggerGeneralArgs.MaxPercentBStagger.min = Min
              StaggerGeneralArgs.MaxPercentBStagger.max = Max
              local Value2 = UBF.UnitBar[TableName].MaxPercentBStagger
              UBF.UnitBar[TableName].MaxPercentBStagger = Value2 < Min and Min or Value2 > Max and Max or Value2

              return Value
            end,
      set = function(Info, Value)
              UBF.UnitBar[TableName].MaxPercent = Value
              UBF:SetAttr(TableName, 'MaxPercent')

              -- Set the min/max percents for second bar
              local Min = Value + .01
              local Max = Value + o.UnitBarMaxPercentMax

              StaggerGeneralArgs.MaxPercentBStagger.min = Min
              StaggerGeneralArgs.MaxPercentBStagger.max = Max
              local Value2 = UBF.UnitBar[TableName].MaxPercentBStagger
              UBF.UnitBar[TableName].MaxPercentBStagger = Value2 < Min and Min or Value2 > Max and Max or Value2
            end,
      min = o.UnitBarMaxPercentMin,
      max = o.UnitBarMaxPercentMax,
    }

    StaggerGeneralArgs.Spacer20 = CreateSpacer(20)
    StaggerGeneralArgs.BStaggerBarTexture = {
      type = 'select',
      name = function()
               return format('Bar Texture', UBF.UnitBar[TableName].MaxPercent * 100)
             end,
      order = 21,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }

    StaggerGeneralArgs.Spacer22 = CreateSpacer(22, 'half')
    StaggerGeneralArgs.BStaggerColor = {
      type = 'color',
      name = 'Color',
      hasAlpha = true,
      order = 23,
    }
    StaggerGeneralArgs.Spacer24 = CreateSpacer(24)
    StaggerGeneralArgs.MaxPercentBStagger = {
      type = 'range',
      name = 'Max Percent',
      desc = 'This continues the percentage from Max Percent above',
      order = 25,
      step = .01,
      width = 'full',
      isPercent = true,
      min = o.UnitBarMaxPercentMin,
      max = o.UnitBarMaxPercentMax,
    }
  end

  GeneralArgs.Spacer30 = CreateSpacer(30)

  if UBD[TableName].SyncFillDirection ~= nil then
    GeneralArgs.SyncFillDirection = {
      type = 'toggle',
      name = 'Sync Fill Direction',
      order = 31,
      desc = 'Fill direction changes based on rotation',
    }
  end

  if UBD[TableName].Clipping ~= nil then
    if UBD[TableName].SyncFillDirection ~= nil then
      GeneralArgs.Spacer32 = CreateSpacer(32, 'half')
    end

    GeneralArgs.Clipping = {
      type = 'toggle',
      name = 'Clipping',
      order = 33,
      desc = 'Texture is clipped instead of being stretched',
    }
  end
  GeneralArgs.Spacer34 = CreateSpacer(34)

  if UBD[TableName].FillDirection ~= nil then
    GeneralArgs.FillDirection = {
      type = 'select',
      name = 'Fill Direction',
      order = 35,
      values = DirectionDropdown,
      style = 'dropdown',
      disabled = function()
                   return UBF.UnitBar[TableName].SyncFillDirection or false
                 end,
    }
    GeneralArgs.Spacer36 = CreateSpacer(36, 'half')
  end

  if UBD[TableName].RotateTexture ~= nil then
    GeneralArgs.RotateTexture = {
      type = 'range',
      name = 'Rotate Texture',
      order = 37,
      min = o.UnitBarRotationMin,
      max = o.UnitBarRotationMax,
      step = 90,
    }
  end

  -- Standard color all
  local Color = UBD[TableName].Color
  if Color and Color.All ~= nil then
    BarArgs.ColorAll = CreateColorAllOptions(BarType, TableName, TableName .. '.Color', 'Color', 2, 'Color')
  end

  -- Fragment bar options
  if BarType == 'FragmentBar' or BarType == 'RuneBar' then
    -- Remove default color all options
    BarArgs.ColorAll = nil
    BarArgs.ColorAllSelect     = CreateColorAllSelectOptions(BarType, 'bar', TableName, 2, 'Color')

    if BarType == 'FragmentBar' then
      BarArgs.ColorAllFullSelect = CreateColorAllSelectOptions(BarType, 'barfull', TableName, 2, 'Color (full)')
    end
  end

  if UBF.IsHealth then
    BarArgs.Absorb = CreateAbsorbOptions(BarType, 9, 'Absorb')
  end
  BarArgs.BoxSize = CreateBarSizeOptions(BarType, TableName, 10, 'Bar Size')

  BarArgs.Padding = {
    type = 'group',
    name = 'Padding',
    dialogInline = true,
    order = 10,
    get = function(Info)
            local KeyName = Info[#Info]
            local Padding = UBF.UnitBar[TableName].Padding

            if KeyName == 'All' then
              return Padding.Left
            else
              return Padding[KeyName]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local Padding = UBF.UnitBar[TableName].Padding

            if KeyName == 'All' then
              Padding.Left = Value
              Padding.Right = -Value
              Padding.Top = -Value
              Padding.Bottom = Value
            else
              Padding[KeyName] = Value
            end
            UBF:SetAttr(TableName, 'Padding')
          end,
    args = {
      PaddingAll = {
        type = 'toggle',
        name = 'All',
        order = 1,
        get = function()
                return UBF.UnitBar[TableName].PaddingAll
              end,
        set = function(Info, Value)
                UBF.UnitBar[TableName].PaddingAll = Value
              end,
        desc = 'Change padding with one value'
      },
      Spacer = CreateSpacer(2),
      All = {
        type = 'range',
        name = 'Offset',
        order = 3,
        hidden = function()
                   return not UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
      },
      Left = {
        type = 'range',
        name = 'Left',
        order = 4,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
      },
      Right = {
        type = 'range',
        name = 'Right',
        order = 5,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
      },
      Top = {
        type = 'range',
        name = 'Top',
        order = 6,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
      },
      Bottom = {
        type = 'range',
        name = 'Bottom',
        order = 7,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
      },
    },
  }

  return BarOptions
end

-------------------------------------------------------------------------------
-- CreateTextFontOptions
--
-- Creats font options to control color, size, etc for text.
--
-- Subfunction of CreateTextOptions()
--
-- BarType       Name of the bar using these options.
-- TableName     Name of the table containing the text.
-- UBF           Unitbar Frame to acces the unitbar functions
-- TLA           Font options will be inserted into this table.
-- Texts         Texts[] option data
-- TextLine      Texts[TextLine]
-- Order         Position to place the options at
-------------------------------------------------------------------------------
local function CreateTextFontOptions(BarType, TableName, UBF, TLA, Texts, TextLine, Order)
  local UBF = UnitBarsF[BarType]
  local Text = Texts[TextLine]

  TLA.FontOptions = {
    type = 'group',
    name = function()
             -- highlight the text in green.
             Bar:SetHighlightFont(BarType, Main.UnitBars.HideTextHighlight, TextLine)
             return 'Font'
           end,
    dialogInline = true,
    order = Order + 1,
    get = function(Info)
            return Text[Info[#Info]]
          end,
    set = function(Info, Value)
            Text[Info[#Info]] = Value
            UBF:SetAttr('Text', '_Font')
          end,
    args = {
      FontType = {
        type = 'select',
        name = 'Type',
        order = 1,
        dialogControl = 'LSM30_Font',
        values = LSMFontDropdown,
      },
      FontStyle = {
        type = 'select',
        name = 'Style',
        order = 2,
        style = 'dropdown',
        values = FontStyleDropdown,
        },
      Spacer10 = CreateSpacer(10),
      Width = {
        type = 'range',
        name = 'Field Width',
        order = 11,
        min = o.FontFieldWidthMin,
        max = o.FontFieldWidthMax,
        step = 1,
      },
      Height = {
        type = 'range',
        name = 'Field Height',
        order = 12,
        min = o.FontFieldHeightMin,
        max = o.FontFieldHeightMax,
        step = 1,
      },
      Spacer20 = CreateSpacer(20),
      FontSize = {
        type = 'range',
        name = 'Size',
        order = 21,
        min = o.FontSizeMin,
        max = o.FontSizeMax,
        step = 1,
      },
      Spacer30 = CreateSpacer(30),
      Location = {
        type = 'group',
        name = 'Location',
        dialogInline = true,
        order = 31,
        args = {
          FontHAlign = {
            type = 'select',
            name = 'Horizontal Alignment',
            order = 1,
            style = 'dropdown',
            values = FontHAlignDropdown,
          },
          FontVAlign = {
            type = 'select',
            name = 'Vertical Alignment',
            order = 2,
            style = 'dropdown',
            values = FontVAlignDropdown,
          },
          Spacer10 = CreateSpacer(10),
          Position = {
            type = 'select',
            name = 'Position',
            order = 11,
            style = 'dropdown',
            desc = 'Location of the font around the bar',
            values = PositionDropdown,
          },
          FontPosition = {
            type = 'select',
            name = 'Font Position',
            order = 12,
            style = 'dropdown',
            desc = 'Change the anchor position of the font',
            values = PositionDropdown,
          },
        },
      },
    },
  }

  -- Add color all text option for the runebar only.
  if BarType == 'RuneBar' then
    TLA.TextColors = CreateColorAllOptions(BarType, 'Text', TableName .. '.1.Color', '_Font', Order, 'Color')
  else
    TLA.FontOptions.args.TextColor = {
      type = 'color',
      name = 'Color',
      order = 22,
      hasAlpha = true,
      get = function()
              local c = Text.Color

              return c.r, c.g, c.b, c.a
            end,
      set = function(Info, r, g, b, a)
              local c = Text.Color

              c.r, c.g, c.b, c.a = r, g, b, a
              UBF:SetAttr('Text', '_Font')
            end,
    }
  end

  TLA.FontOptions.args.Offsets = {
    type = 'group',
    name = 'Offsets',
    dialogInline = true,
    order = 41,
    get = function(Info)
            return Text[Info[#Info]]
          end,
    set = function(Info, Value)
            Text[Info[#Info]] = Value
            UBF:SetAttr('Text', '_Font')
          end,
    args = {
      OffsetX = {
        type = 'range',
        name = 'Horizonal',
        order = 2,
        min = o.FontOffsetXMin,
        max = o.FontOffsetXMax,
        step = 1,
      },
      OffsetY = {
        type = 'range',
        name = 'Vertical',
        order = 3,
        min = o.FontOffsetYMin,
        max = o.FontOffsetYMax,
        step = 1,
      },
      ShadowOffset = {
        type = 'range',
        name = 'Shadow',
        order = 4,
        min = o.FontShadowOffsetMin,
        max = o.FontShadowOffsetMax,
        step = 1,
      },
    },
  }
end

-------------------------------------------------------------------------------
-- AddValueIndexOptions
--
-- Creates dynamic drop down options for text value names and types
--
-- Subfunction of CreateTextValueOptions()
--
-- DUBTexts       Default unitbar text
-- ValueNames     Current array, both value name and value type menus are made from this.
-- ValueIndex     Index into ValueNames
-- Order          Position to place the options at
-------------------------------------------------------------------------------
local function AddValueIndexOptions(DUBTexts, ValueNames, ValueIndex, Order)
  local ValueNameDropdown = ValueNameMenuDropdown[DUBTexts._ValueNameMenu]

  local ValueIndexOptions = {
    type = 'group',
    name = '',
    order = Order + ValueIndex,
    dialogInline = true,
    args = {
      ValueName = {
        type = 'select',
        name = format('Value Name %s', ValueIndex),
        values = ValueNameDropdown,
        order = 1,
        arg = ValueIndex,
      },
      ValueType = {
        type = 'select',
        name = format('Value Type %s', ValueIndex),
        disabled = function()
                     -- Disable if the ValueName is not found in the menu.
                     return ValueNames[ValueIndex] == 'none' or
                            ValueNameDropdown[ConvertValueName[ValueNames[ValueIndex]]] == nil
                   end,
        values = function()
                   local VName = ValueNames[ValueIndex]
                   if ValueNameDropdown[ConvertValueName[VName]] == nil then

                     -- Valuename not found in the menu so return an empty menu
                     return ValueType_NoneDropdown
                   else
                     return ValueTypeMenuDropdown[VName]
                   end
                 end,
        arg = ValueIndex,
      },
    },
  }

  return ValueIndexOptions
end

-------------------------------------------------------------------------------
-- CreateTextValueOptions
--
-- Creates dynamic drop down options for text value names and types
--
-- Subfunction of AddTextLineOptions()
--
-- UBF            Unitbar Frame to acces the unitbar functions
-- TLA            Current Text Line options being used.
-- Texts          Texts[] option data
-- TextLine       Texts[TextLine]
-- Order          Position to place the options at
-------------------------------------------------------------------------------
local function CreateTextValueOptions(UBF, TLA, DUBTexts, Texts, TextLine, Order)
  local ValueNameMenu = DUBTexts._ValueNameMenu

  local Text = Texts[TextLine]
  local ValueNames = Text.ValueNames
  local ValueTypes = Text.ValueTypes
  local NumValues = 0
  local MaxValueNames = o.MaxValueNames
  local ValueIndexName = 'ValueIndexOptions%s'

  -- Forward Value option arguments
  local VOA = nil

  TLA.ValueOptions = {
    type = 'group',
    name = 'Value',
    order = Order,
    dialogInline = true,
    get = function(Info)
            local KeyName = Info[#Info]
            local ValueIndex = Info.arg

            if KeyName == 'ValueName' then

              -- Check if the valuename is not found in the menu.
              return ConvertValueName[ValueNames[ValueIndex]]

            elseif KeyName == 'ValueType' then
              return ConvertValueType[ValueTypes[ValueIndex]]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local ValueIndex = Info.arg

            if KeyName == 'ValueName' then
              local VName = ConvertValueName[Value]
              ValueNames[ValueIndex] = VName

              -- ValueType menu may have changed, so need to update ValueTypes.
              local Dropdown = ValueTypeMenuDropdown[VName]
              local Value = ConvertValueType[ValueTypes[ValueIndex]]

              -- Find the first menu entry
              if Dropdown[Value] == nil then
                Value = 100
                for Index in pairs(Dropdown) do
                  if Value > Index then
                    Value = Index
                  end
                end
                ValueTypes[ValueIndex] = ConvertValueType[Value]
              end
            elseif KeyName == 'ValueType' then
              ValueTypes[ValueIndex] = ConvertValueType[Value]
            end

            -- Update the font.
            UBF:SetAttr('Text', '_Font')
          end,
    args = {
      Message = {
        type = 'description',
        name = 'Custom Layout - use "))" for ")", "%%" for "%", or "|||" for "|" in the format string',
        order = 1,
        hidden = function()
                   return not Text.Custom
                 end,
      },
      Output = {
        type = 'description',
        fontSize = 'medium',
        name = function()
                 return format('|cff00ff00%s|r', Text.ErrorMessage or Text.SampleText or '')
               end,
        order = 2,
      },
      Layout = {
        type = 'input',
        name = 'Layout',
        order = 3,
        multiline = true,
        width = 'full',
        desc = 'To customize the layout change it here',
        get = function()
                return gsub(Text.Layout, '|', '||')
              end,
        set = function(Info, Value)
                Text.Custom = true
                Text.Layout = gsub(Value, '||', '|')

                -- Update the bar.
                UBF:SetAttr('Text', '_Font')
              end,
      },
      Spacer4 = CreateSpacer(4),
      RemoveValue = {
        type = 'execute',
        name = 'Remove',
        order = 5,
        width = 'half',
        desc = 'Remove a value',
        disabled = function()
                     -- Hide the tooltip since the button will be disabled.
                     return HideTooltip(NumValues == 1)
                   end,
        func = function()
                 -- remove last value type.
                 tremove(ValueNames, NumValues)
                 tremove(ValueTypes, NumValues)

                 VOA[format(ValueIndexName, NumValues)] = nil

                 NumValues = NumValues - 1

                 -- Update the font to reflect changes
                 UBF:SetAttr('Text', '_Font')
               end,
      },
      AddValue = {
        type = 'execute',
        name = 'Add',
        order = 6,
        width = 'half',
        desc = 'Add another value',
        disabled = function()
                     -- Hide the tooltip since the button will be disabled.
                     return HideTooltip(NumValues == MaxValueNames)
                   end,
        func = function()
                 NumValues = NumValues + 1
                 VOA[format(ValueIndexName, NumValues)] = AddValueIndexOptions(DUBTexts, ValueNames, NumValues, 10)

                 -- Add a new value setting.
                 ValueNames[NumValues] = DUBTexts[1].ValueNames[1]
                 ValueTypes[NumValues] = DUBTexts[1].ValueTypes[1]

                 -- Update the font to reflect changes
                 UBF:SetAttr('Text', '_Font')
               end,
      },
      Spacer7 = CreateSpacer(7, 'half'),
      ExitCustomLayout = {
        type = 'execute',
        name = 'Exit',
        order = 8,
        width = 'half',
        hidden = function()
                   return HideTooltip(not Text.Custom)
                 end,
        desc = 'Exit custom layout mode',
        func = function()
                 Text.Custom = false

                 -- Call setattr to reset layout without changing the text settings.
                 UBF:SetAttr()
               end,
      },
      Spacer9 = CreateSpacer(9),
    },
  }

  VOA = TLA.ValueOptions.args

  -- Add additional value options if needed
  for ValueIndex, Value in ipairs(ValueNames) do
    VOA[format(ValueIndexName, ValueIndex)] = AddValueIndexOptions(DUBTexts, ValueNames, ValueIndex, 10)
    NumValues = ValueIndex
  end
end

-------------------------------------------------------------------------------
-- AddTextLineOptions
--
-- Creates a new set of options for a textline.
--
-- Subfunction of CreateTextOptions()
--
-- BarType           Name of the bar using these options.
-- TableName         Name of the table containing the text options data.
-- UBF               Unitbar Frame to acces the unitbar functions
-- TOA               TextOptions.args
-- DUBTexts          Defalt unitbar text
-- Texts             Texts[] option data
-- TextLine          Texts[TextLine]
-------------------------------------------------------------------------------
local function AddTextLineOptions(BarType, TableName, UBF, TOA, DUBTexts, Texts, TextLine)
  local MaxTextLines = o.MaxTextLines

  local TextLineOptions = {
    type = 'group',
    name = format('Text Line %s', TextLine),
    order = TextLine,
    args = {},
  }

  -- Add text line to TextOptions
  local TextLineName = 'TextLine%s'
  local TLA = TextLineOptions.args
  TOA[format(TextLineName, TextLine)] = TextLineOptions

  if DUBTexts.Notes ~= nil then
    TLA.Notes = {
      type = 'description',
      order = 0.1,
      name = DUBTexts.Notes,
    }
  end

  TLA.RemoveTextLine = {
    type = 'execute',
    name = function()
             return format('Remove Text Line', TextLine)
           end,
    width = 'normal',
    order = 1,
    desc = function()
             return format('Remove Text Line %s', TextLine)
           end,
    disabled = function()
               -- Hide the tooltip since the button will be disabled.
               return HideTooltip(#Texts == 1)
             end,
    confirm = function()
                return format('Remove Text Line %s ?', TextLine)
              end,
    func = function()
             -- Delete the text setting.
             tremove(Texts, TextLine)

             -- Move options down by one by deleting and recreating
             for TextLine = #Texts, MaxTextLines do
               TOA[format(TextLineName, TextLine)] = nil

               if TextLine <= #Texts then
                 AddTextLineOptions(BarType, TableName, UBF, TOA, DUBTexts, Texts, TextLine)
               end
             end

             -- Update the the bar to reflect changes
             UBF:SetAttr('Text', '_Font')
           end,
  }
  TLA.AddTextLine = {
    type = 'execute',
    order = 2,
    name = 'Add Text Line',
    width = 'normal',
    disabled = function()
               -- Hide the tooltip since the button will be disabled.
               return HideTooltip(#Texts == MaxTextLines)
             end,
    func = function()

             -- Add text on to end.
             -- Deep Copy first text setting from defaults into text table.
             local TextTable = {}

             Main:CopyTableValues(DUBTexts[1], TextTable, true)
             Texts[#Texts + 1] = TextTable

             -- Add options for new text line.
             AddTextLineOptions(BarType, TableName, UBF, TOA, DUBTexts, Texts, #Texts)

             -- Update the the bar to reflect changes
             UBF:SetAttr('Text', '_Font')
           end,
  }

  CreateTextValueOptions(UBF, TLA, DUBTexts, Texts, TextLine, 10)
  CreateTextFontOptions(BarType, TableName, UBF, TLA, Texts, TextLine, 11)
end

-------------------------------------------------------------------------------
-- CreateTextOptions
--
-- Creates dyanmic text options for a unitbar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType               Type options being created.
-- TableName             Name of the table containing the text.
-- Order                 Order number.
-- Name                  Name text
--
-- TextOptions     Options table for text options.
--
-- NOTES:  Since DoFunction is being used.  When it gets called UnitBarF[].UnitBar
--         is not upto date at that time.  So Main.UnitBars[BarType] must be used
--         instead.
-------------------------------------------------------------------------------
local function CreateTextOptions(BarType, TableName, Order, Name)
  local TextOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    args = {}, -- need this so ACE3 dont crash if text options are not created.
  }

  local DoFunctionTextName = 'CreateTextOptions' .. TableName

  -- This will modify text options table if the profile changed.
  -- Basically rebuild the text options when ever the profile changes.
  Options:DoFunction(BarType, DoFunctionTextName, function()
    local TOA = {}
    TextOptions.args = TOA

    local UBF = UnitBarsF[BarType]
    local Texts = UBF.UnitBar[TableName]
    local DUBTexts = DUB[BarType][TableName]

    -- Add the textlines
    for TextLine = 1, #Texts do
      AddTextLineOptions(BarType, TableName, UBF, TOA, DUBTexts, Texts, TextLine)
    end
  end)

  -- Set up the options
  Options:DoFunction(BarType, DoFunctionTextName)

  return TextOptions
end

-------------------------------------------------------------------------------
-- AddConditionOption
--
-- Adds a condition options for the trigger.
--
-- Subfunction of AddTriggerOption()
--
-- Order       Position inside the trigger option.
-- TO          Trigger options to modify.
-- UBF         Unit bar frame to update the bar.
-- BBar        Access to the bar functions to update triggers.
-- Condition   Condition being worked on.
-- Trigger     The trigger that contains the condition.
-------------------------------------------------------------------------------
local function AddConditionOption(Order, TO, UBF, BBar, Condition, Trigger)
  local TOA = TO.args
  local HexSt = ToHex(Condition)
  local ConditionOperator = 'ConditionOperator' .. HexSt
  local ConditionValue  = 'ConditionValue'  .. HexSt
  local ConditionTalent = 'ConditionTalent' .. HexSt
  local ConditionDelete = 'ConditionDelete' .. HexSt
  local ConditionSpacer = 'ConditionSpacer' .. HexSt

  local IsTalent = nil

  -- Operator
  TOA[ConditionOperator] = {
    type = 'select',
    name = 'Operator',
    width = 'half',
    desc = 'Set the operator to activate at',
    order = function()
              return Condition.OrderNumber + Order + 0.1
            end,
    get = function()
            local Value = FindMenuItem(TriggerOperatorDropdown[Trigger.ValueTypeID], Condition.Operator)

            -- Convert value to operator (string)
            local Operator = TriggerOperatorDropdown[Trigger.ValueTypeID][Value]
            IsTalent = TalentType[Operator]

            return Value
          end,
    set = function(Info, Value)
            local Operator = TriggerOperatorDropdown[Trigger.ValueTypeID][Value]
            Condition.Operator = Operator
            IsTalent = TalentType[Value]

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()
          end,
    values = function()
               return TriggerOperatorDropdown[Trigger.ValueTypeID]
             end,
    style = 'dropdown',
    hidden = function()
               local ValueTypeID = Trigger.ValueTypeID

               return Trigger.Static or ValueTypeID == 'auras' or ValueTypeID == 'state'
             end,
  }

  -- Value
  TOA[ConditionValue] = {
    type = 'input',
    name = function()
             return format('Value (%s)', Trigger.ValueTypeID)
           end,
    order = function()
              return Condition.OrderNumber + Order + 0.2
            end,
    desc = function()
             local ValueTypeID = Trigger.ValueTypeID

             if ValueTypeID == 'percent' then
               return 'Enter a percentage as a whole number'
             elseif ValueTypeID == 'string' then
               return 'Enter any text, match is not case sensitive and not exact'
             else
               return 'Enter any number'
             end
           end,
    get = function()
            -- Turn into a string. Input takes strings.
            return tostring(tonumber(Condition.Value) or 0)
          end,
    set = function(Info, Value)
            -- Change to number
            local ValueTypeID = Trigger.ValueTypeID

            if ValueTypeID == 'string' then
              Condition.Value = Value
            elseif ValueTypeID == 'float' then
              Condition.Value = tonumber(Value) or 0
            else
              Condition.Value = floor(tonumber(Value) or 0)
            end

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()
          end,
    hidden = function()
               local ValueTypeID = Trigger.ValueTypeID

               return IsTalent ~= nil or Trigger.Static or ValueTypeID == 'auras' or ValueTypeID == 'state'
             end,
  }
  -- Value Talents
  TOA[ConditionTalent] = {
    type = 'select',
    name = function()
             return format('Talent (%s)', IsTalent or '')
           end,
    order = function()
              return Condition.OrderNumber + Order + 0.2
            end,
    get = function()
            local Value = tostring(Condition.Value)
            local Dropdown = nil

            if IsTalent == 'PvE' then
              Dropdown = Talents.Dropdown
            else
              Dropdown = Talents.PvPDropdown
            end

            Value = FindMenuItem(Dropdown, Value)

            -- Save value as a string
            Condition.Value = Dropdown[Value]

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()

            return Value
          end,
    set = function(Info, Value)
            local Dropdown = nil

            if IsTalent == 'PvE' then
              Dropdown = Talents.Dropdown
            else
              Dropdown = Talents.PvPDropdown
            end
            Condition.Value = Dropdown[Value]

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()
          end,
    values = function()
               if IsTalent == 'PvE' then
                 return Talents.IconDropdown
               else
                 return Talents.IconPvPDropdown
               end
             end,
    style = 'dropdown',
    hidden = function()
               return IsTalent == nil
             end,
  }
  -- Delete
  TOA[ConditionDelete] = {
    type = 'execute',
    order = function()
              return Condition.OrderNumber + Order + 0.3
            end,
    name = 'Delete',
    width = 'half',
    desc = 'Delete this condition',
    func = function()
             tremove(Trigger.Conditions, Condition.OrderNumber)

             -- Delete this option.
             TOA[ConditionOperator] = nil
             TOA[ConditionValue] = nil
             TOA[ConditionTalent] = nil
             TOA[ConditionDelete] = nil
             TOA[ConditionSpacer] = nil

             -- Update bar to reflect trigger changes
             BBar:CheckTriggers()
             UBF:Update()
             BBar:Display()

             HideTooltip(true)
           end,
    hidden = function()
               local ValueTypeID = Trigger.ValueTypeID

               return Trigger.Static or ValueTypeID == 'auras' or ValueTypeID == 'state' or #Trigger.Conditions == 1
             end,
  }
  -- Add
  if TOA.ConditionAdd == nil then
    TOA.ConditionAdd = {
      type = 'execute',
      order = function()
                return #Trigger.Conditions + Order + 0.4
              end,
      name = 'Add',
      width = 'half',
      desc = 'Add a new condition below this one',
      func = function()
               local Conditions = Trigger.Conditions
               local C = {}

               Main:CopyTableValues(Conditions[#Conditions], C, true)
               Conditions[#Conditions + 1] = C

               -- Add new condition option.
               BBar:CheckTriggers()
               AddConditionOption(Order, TO, UBF, BBar, C, Trigger)

               -- Update bar to reflect trigger changes
               UBF:Update()
               BBar:Display()

               HideTooltip(true)
             end,
      hidden = function()
                 local ValueTypeID = Trigger.ValueTypeID

                 return Trigger.Static or ValueTypeID == 'auras' or ValueTypeID == 'state'
               end,
    }
  end
  -- All
  if TOA.ConditionAll == nil then
    TOA.ConditionAll = {
      type = 'toggle',
      name = 'All',
      width = 'half',
      desc = 'If checked, then all conditions must be true',
      order = Order + 1.5,
      get = function()
              return Trigger.Conditions.All
            end,
      set = function(Info, Value)
              Trigger.Conditions.All = Value

              -- Update bar to reflect trigger changes
              BBar:CheckTriggers()
              UBF:Update()
              BBar:Display()
            end,
      hidden = function()
                 local ValueTypeID = Trigger.ValueTypeID

                 return Trigger.Static or ValueTypeID == 'auras' or ValueTypeID == 'state'
               end,
    }
  end
  -- Create spacer that can move.
  TOA[ConditionSpacer] = {
    type = 'description',
    name = '',
    order = function()
              return Condition.OrderNumber + Order + 0.9
            end,
    width = 'full',
    hidden = function()
               local ValueTypeID = Trigger.ValueTypeID

               return Trigger.Static or ValueTypeID == 'auras' or ValueTypeID == 'state'
             end,
  }
end

-------------------------------------------------------------------------------
-- AddAuraOption
--
-- Adds an aura that can be modified
--
-- Subfunction of AddTriggerOption()
--
-- Order    Position in the options.
-- UBF      Unitbar frame to access the bar functions.
-- BBar     Access to bar functions.
-- TO       Trigger option space to add the aura in
-- SpellID  Aura to add.
-- Trigger  Trigger holding the aura.
-------------------------------------------------------------------------------
local function AddAuraOption(Order, UBF, BBar, TO, SpellID, Trigger)
  local AuraGroup = 'Aura' .. SpellID
  local Name, _, Icon = GetSpellInfo(SpellID)

  -- Check if the spell was removed from the game.
  if Name == nil then
    Name = format('%s removed from the game', SpellID)
    Icon = [[INTERFACE\ICONS\INV_MISC_QUESTIONMARK]]
  end

  TO.args[AuraGroup] = {
    type = 'group',
    name = format('|T%s:20:20:0:5|t |cFFFFFFFF%s|r (%s)', Icon, Name, SpellID),
    order = Order + SpellID,
    dialogInline = true,
    hidden = function()
               return Trigger.HideAuras or Trigger.Static or Trigger.ValueTypeID ~= 'auras'
             end,
    get = function(Info)
            local KeyName = Info[#Info]
            local Aura = Trigger.Auras[SpellID]

            if KeyName == 'StackOperator' then
              return FindMenuItem(AuraStackOperatorDropdown, Aura.StackOperator)
            elseif KeyName == 'Stacks' then
              return tostring(Aura.Stacks or 0)
            else
              return Aura[KeyName]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            if KeyName == 'Stacks' then
              Value = tonumber(Value) or 0
            elseif KeyName == 'StackOperator' then
              Value = AuraStackOperatorDropdown[Value]
            elseif KeyName == 'Unit' then
              Value = strtrim(Value)
            end

            Trigger.Auras[SpellID][KeyName] = Value

            -- update the bar
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()
          end,
    args = {
      RemoveAura = {
        type = 'execute',
        name = 'Remove',
        desc = 'Remove aura',
        order = 1,
        width = 'half',
        func = function()
                 TO.args[AuraGroup] = nil
                 Trigger.Auras[SpellID] = nil

                 -- update the bar
                 BBar:CheckTriggers()
                 UBF:Update()
                 BBar:Display()

                 HideTooltip(true)
               end,
      },
      SpacerHalf = CreateSpacer(2, 'half'),
      NotActive = {
        type = 'toggle',
        name = 'Not Active',
        desc = 'If check, the aura can not be on the unit',
        order = 3,
      },
      Own = {
        type = 'toggle',
        name = 'Own',
        desc = 'This aura must be cast by you',
        order = 4,
        width = 'half',
        hidden = function()
                   return Trigger.Auras[SpellID].NotActive
                 end,
      },
      AuraGroup = {
        type = 'group',
        name = '',
        hidden = function()
                   HideTooltip(true)
                   return Trigger.Auras[SpellID].NotActive
                 end,
        args = {
          Unit = {
            type = 'input',
            name = 'Unit',
            order = 11,
          },
          StackOperator = {
            type = 'select',
            name = 'Operator',
            width = 'half',
            order = 12,
            values = AuraStackOperatorDropdown,
          },
          Stacks = {
            type = 'input',
            name = 'Stacks',
            width = 'half',
            order = 13,
          },
        },
      },
    },
  }
end

-------------------------------------------------------------------------------
-- CreateOffsetOption
--
-- Create options to offset the size of bar
--
-- Subfunction of AddTriggerOption()
--
-- Order    Position in the options.
-- UBF      Unitbar frame to access the bar functions.
-- BBar     Access to bar functions.
-- Trigger  Trigger being modified.
-------------------------------------------------------------------------------
local function CreateOffsetOption(Order, UBF, BBar, Trigger)
  local OffsetOption = {
    type = 'group',
    name = '',
    order = Order,
    get = function(Info)
            local KeyName = Info[#Info]
            local Pars = Trigger.Pars
            local p1, p2, p3, p4 = Pars[1], Pars[2], Pars[3], Pars[4]

            if KeyName == 'Left' or KeyName == 'All' then
              return p1
            elseif KeyName == 'Right' then
              return p2
            elseif KeyName == 'Top' then
              return p3
            elseif KeyName == 'Bottom' then
              return p4
            end

            return p1, p2, p3, p4
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local Pars = Trigger.Pars
            local p1, p2, p3, p4 = Pars[1], Pars[2], Pars[3], Pars[4]

            if KeyName == 'All' then
              p1 = Value
              p2 = -Value
              p3 = -Value
              p4 = Value
            elseif KeyName == 'Left' then
              p1 = Value
            elseif KeyName == 'Right' then
              p2 = Value
            elseif KeyName == 'Top' then
              p3 = Value
            elseif KeyName == 'Bottom' then
              p4 = Value
            end

            Pars[1], Pars[2], Pars[3], Pars[4] = p1, p2, p3, p4

            -- Update the triggers here for better performance
            -- Dont need to do a checktriggers here.
            UBF:Update()
            BBar:Display()
          end,
    hidden = function()
               return Trigger.TypeID ~= 'baroffset'
             end,
    args = {
      OffsetAll = {
        type = 'toggle',
        name = 'All',
        order = 1,
        get = function()
                return Trigger.OffsetAll
              end,
        set = function(Info, Value)
                Trigger.OffsetAll = Value
              end,
        desc = 'Change offset with one value'
      },
      Spacer = CreateSpacer(2),
      All = {
        type = 'range',
        name = 'Offset',
        order = 3,
        width = 'double',
        hidden = function()
                   return not Trigger.OffsetAll
                 end,
        min = o.TriggerBarOffsetAllMin,
        max = o.TriggerBarOffsetAllMax,
        step = 1,
      },
      Left = {
        type = 'range',
        name = 'Left',
        order = 4,
        hidden = function()
                   return Trigger.OffsetAll
                 end,
        min = o.TriggerBarOffsetLeftMin,
        max = o.TriggerBarOffsetLeftMax,
        step = 1,
      },
      Right = {
        type = 'range',
        name = 'Right',
        order = 5,
        hidden = function()
                   return Trigger.OffsetAll
                 end,
        min = o.TriggerBarOffsetRightMin,
        max = o.TriggerBarOffsetRightMax,
        step = 1,
      },
      Top = {
        type = 'range',
        name = 'Top',
        order = 6,
        hidden = function()
                   return Trigger.OffsetAll
                 end,
        min = o.TriggerBarOffsetTopMin,
        max = o.TriggerBarOffsetTopMax,
        step = 1,
      },
      Bottom = {
        type = 'range',
        name = 'Bottom',
        order = 7,
        hidden = function()
                   return Trigger.OffsetAll
                 end,
        min = o.TriggerBarOffsetBottomMin,
        max = o.TriggerBarOffsetBottomMax,
        step = 1,
      },
    },
  }

  return OffsetOption
end

-------------------------------------------------------------------------------
-- CreateSpecOptions
--
-- Create options to change specializations for the trigger
--
-- Subfunction of AddTriggerOption(), CreateUnitBarOptions()
--
-- Order         Position in the options.
-- UBF           Unitbar frame to access the bar functions.
-- BBar          Access to bar functions.
-- ClassSpecsTP  String or table, if string then its a table path to the ClassSpecs table
-- BBar          Only used with triggers
-------------------------------------------------------------------------------
local function MarkMenuSpec(ClassDropdown, SelectClassDropdown, ClassSpecs)

  -- Mark menu items that have specializations
  for Index, ClassName in pairs(ClassDropdown) do
    local ClassNameUpper = ConvertPlayerClass[ClassName]
    local ClassSpec = ClassSpecs[ClassNameUpper]

    if ClassSpec then
      local CN = ClassName
      local Found = false

      for _, Active in pairs(ClassSpec) do
        if Active then
          Found = true
          break
        end
      end
      if Found then
        CN = CN .. '*'
      end
      SelectClassDropdown[Index] = CN
    end
  end
end

local function GetClassSpecsTable(BarType, ClassSpecsTP)
  if type(ClassSpecsTP) == 'string' then
    return Main:GetUB(BarType, ClassSpecsTP)
  else
    return ClassSpecsTP
  end
end

local function CreateSpecOptions(BarType, Order, ClassSpecsTP, BBar)
  local UBF = UnitBarsF[BarType]
  local PlayerClass = Main.PlayerClass
  local ClassDropdown = {}
  local SelectClassDropdown = {}
  local SpecDropdown = {}
  local MyClassFound = false
  local CSD = nil
  local ClassSpecs = GetClassSpecsTable(BarType, ClassSpecsTP)
  local Index = 1

  if BBar then
    CSD = DUB[BarType].Triggers.Default.ClassSpecs
  else
    CSD = DUB[BarType].ClassSpecs
  end

  -- Build pulldown menus
  for ClassName, Specs in pairs(CSD) do
    if type(Specs) == 'table' then
      local ClassNameLower =  ConvertPlayerClass[ClassName]

      if ClassName ~= PlayerClass then

        ClassDropdown[Index] = ClassNameLower
        SelectClassDropdown[Index] = ClassNameLower
        Index = Index + 1
      else
        MyClassFound = true
      end
      -- Create spec dropdown
      local CS = ClassSpecialization[ClassName]
      local SpecList = {}
      local NumSpecs = #Specs

      for Index in pairs(Specs) do
        SpecList[Index] = CS[Index]
      end
      SpecDropdown[ClassNameLower] = SpecList
    end
  end
  sort(ClassDropdown)
  sort(SelectClassDropdown)

  -- Set class you're on to the first entry
  -- Only if the bar supports your class
  if MyClassFound then
    local CN = ConvertPlayerClass[PlayerClass]
    tinsert(ClassDropdown, 1, CN)
    tinsert(SelectClassDropdown, 1, CN)
  end

  MarkMenuSpec(ClassDropdown, SelectClassDropdown, ClassSpecs)

  local SpecOptions = {
    type = 'group',
    dialogInline = true,
    name = function()
             MarkMenuSpec(ClassDropdown, SelectClassDropdown, GetClassSpecsTable(BarType, ClassSpecsTP))
             return 'Specialization'
           end,
    order = Order,
    get = function(Info, Index)
            ClassSpecs = GetClassSpecsTable(BarType, ClassSpecsTP)
            local KeyName = Info[#Info]

            if KeyName == 'All' then
              return ClassSpecs.All
            elseif KeyName == 'Inverse' then
              return ClassSpecs.Inverse or false
            elseif KeyName == 'Class' then
              local ClassIndex = FindMenuItem(ClassDropdown, ClassSpecs.ClassName or '')

              -- Set default classname
              ClassSpecs.ClassName = ClassDropdown[ClassIndex]

              return ClassIndex
            else
              local ClassSpec = ClassSpecs[ConvertPlayerClass[ClassSpecs.ClassName]]

              return ClassSpec and ClassSpec[Index] or false
            end
          end,
    set = function(Info, Value, Active)
            ClassSpecs = GetClassSpecsTable(BarType, ClassSpecsTP)
            local KeyName = Info[#Info]

            if KeyName == 'All' then
              ClassSpecs.All = Value
            elseif KeyName == 'Inverse' then
              ClassSpecs.Inverse = Value
            elseif KeyName == 'Class' then
              ClassSpecs.ClassName = ClassDropdown[Value]
            else
              local ClassName = ClassSpecs.ClassName
              local ClassNameUpper = ConvertPlayerClass[ClassName]
              local ClassSpec = ClassSpecs[ClassNameUpper]

              if ClassSpec == nil then
                ClassSpec = {}
                ClassSpecs[ClassNameUpper] = ClassSpec
              end

              ClassSpec[Value] = Active
            end
            -- Update bar to reflect specialization setting.
            if BBar then
              BBar:CheckTriggers()
            end
            if BBar == nil then
              UBF:StatusCheck()
            end
            UBF:Update()
            if BBar then
              BBar:Display()
            end
          end,
    args = {
      All = {
        type = 'toggle',
        name = 'All',
        desc = 'Matches all classes and specializations',
        width = 'half',
        order = 1,
      },
      Inverse = {
        type = 'toggle',
        name = 'Inverse',
        order = 2,
        disabled = function()
                     return GetClassSpecsTable(BarType, ClassSpecsTP).All
                   end,
      },
      Reset = {
        type = 'execute',
        order = 3,
        desc = 'Sets all specialization options to default',
        name = 'Reset',
        width = 'half',
        func = function()
                 ClassSpecs = GetClassSpecsTable(BarType, ClassSpecsTP)
                 Main:CopyTableValues(CSD, ClassSpecs, true)

                 if BBar then
                   BBar:CheckTriggers()
                 end
                 UBF:Update()
                 if BBar == nil then
                   UBF:StatusCheck()
                 end
                 if BBar then
                   BBar:Display()
                 end
               end,
        confirm = function()
                    return 'This will reset your class specialization settings'
                  end
      },
      Clear = {
        type = 'execute',
        order = 4,
        desc = 'Uncheck all class specialization settings',
        name = 'Clear',
        width = 'half',
        func = function()
                 ClassSpecs = GetClassSpecsTable(BarType, ClassSpecsTP)

                 for _, ClassSpec in pairs(ClassSpecs) do
                   if type(ClassSpec) == 'table' then
                     for Index in pairs(ClassSpec) do
                       ClassSpec[Index] = false
                     end
                   end
                 end

                 if BBar then
                   BBar:CheckTriggers()
                 end
                 UBF:Update()
                 if BBar == nil then
                   UBF:StatusCheck()
                 end
                 if BBar then
                   BBar:Display()
                 end
               end,
        confirm = function()
                    return 'This will uncheck your class specialization settings'
                  end,
        hidden = function()
                   return BBar ~= nil
                 end,
      },
      Spacer10 = CreateSpacer(10),
      Class = {
        type = 'select',
        name = 'Class',
        order = 11,
        style = 'dropdown',
        values = SelectClassDropdown,
        disabled = function()
                     return GetClassSpecsTable(BarType, ClassSpecsTP).All
                   end,
      },
      Spec = {
        type = 'multiselect',
        name = 'Specialization',
        order = 12,
        width = 'double',
        dialogControl = 'Dropdown',
        values = function()
                   return SpecDropdown[ClassSpecs.ClassName]
                 end,
        disabled = function()
                     return GetClassSpecsTable(BarType, ClassSpecsTP).All
                   end
      },
    },
  }

  return SpecOptions
end

-------------------------------------------------------------------------------
-- AddTriggerOption
--
-- Adds an option window under a group to modify the trigger settings.
--
-- SubFunction of CreateTriggerOptions
--
-- UBF             Unitbar frame to access the bar functions.
-- BBar            The bar object to access the bar DB functions.
-- TOA             Trigger option arguments. Trigger options get added here.
-- GroupNames      Quick access to keyname for groups.
-- ClipBoard       Clipboard to swap, copy, move triggers.
-- Groups          So each option knows what pull down menus to use, etc
-- Triggers        Whole triggers table.
-- Trigger         Trigger to add. or GroupNumber to add 'add' and util buttons.
-------------------------------------------------------------------------------
local function DeleteTriggerOption(TGA, Trigger)
  local ToHexSt = ToHex(Trigger)

  TGA['Trigger' .. ToHexSt] = nil
  TGA['Clear' .. ToHexSt] = nil
  TGA['Paste' .. ToHexSt] = nil
end

local function AddTriggerOption(UBF, BBar, TOA, GroupNames, ClipBoard, Groups, Triggers, Trigger)
  local TriggerType = type(Trigger)
  local GroupNumber = TriggerType == 'number' and Trigger or Trigger.GroupNumber
  local Group = Groups[GroupNumber]
  local TGA = TOA[ GroupNames[GroupNumber] ].args
  local AuraGroupOrder = 200
  local ConditionOrder = 100
  local InvalidSpell = false

  --====================================
  -- SUB FUNCTION Utility
  --====================================
  local function ToggleMenuButton(MenuButton)
    local Action = nil

    if Triggers.MenuSync then
      Action = Triggers.ActionSync
    else
      Action = Trigger.Action
    end
    local State = Action[MenuButton] or 0

    -- Empty table so only one menu can be active at time.
    wipe(Action)
    Action[MenuButton] = State * -1 + 1
  end

  local function GetMenuButton(MenuButton)
    if Triggers.MenuSync then
      return Triggers.ActionSync[MenuButton] or ''
    else
      return Trigger.Action[MenuButton] or ''
    end
  end

  local function TriggerAction(Action)
    if Triggers.MenuSync then
      Action = Triggers.ActionSync[Action]
    else
      Action = Trigger.Action[Action]
    end

    if Action == nil or Action == 0 then
      return 0
    else
      return 1
    end
  end

  --====================================
  -- SUB FUNCTION SetDefaultPars()
  --====================================
  local function SetDefaultPars(Trigger)

    -- Validate pars
    local TypeID = Trigger.TypeID
    local Pars = Trigger.Pars
    local p1, p2, p3, p4 = Pars[1], Pars[2], Pars[3], Pars[4]

    if TypeID == 'border' then
      p2, p3, p4 = nil, nil, nil
      if LSMBorderDropdown[p1] == nil then
        p1 = DefaultBorderTexture
      end

    elseif TypeID == 'background' then
      p2, p3, p4 = nil, nil, nil
      if LSMBackgroundDropdown[p1] == nil then
        p1 = DefaultBgTexture
      end

    elseif TypeID == 'bartexture' then
      p2, p3, p4 = nil, nil, nil
      if LSMStatusBarDropdown[p1] == nil then
        p1 = DefaultStatusBarTexture
      end

    elseif TypeID == 'texturescale' then
      p2, p3, p4 = nil, nil, nil
      p1 = tonumber(p1) or 1

      -- check for out of bounds
      if p1 < o.TriggerTextureScaleMin then
        p1 = o.TriggerTextureScaleMin
      elseif p1 > o.TriggerTextureScaleMax then
        p1 = o.TriggerTextureScaleMax
      end

    elseif TypeID == 'baroffset' then
      p1, p2, p3, p4 = tonumber(p1) or 0, tonumber(p2) or 0, tonumber(p3) or 0, tonumber(p4) or 0

    elseif strfind(TypeID, 'color') then
      p1, p2, p3, p4 = tonumber(p1) or 1, tonumber(p2) or 1, tonumber(p3) or 1, tonumber(p4) or 1
      if p1 < 0 or p1 > 1 then p1 = 1 end
      if p2 < 0 or p2 > 1 then p2 = 1 end
      if p3 < 0 or p3 > 1 then p3 = 1 end
      if p4 < 0 or p4 > 1 then p4 = 1 end

    elseif strfind(TypeID, 'fontoffset') then
      p3, p4 = nil, nil
      p1, p2 = tonumber(p1) or 0, tonumber(p2) or 0

      -- check for out of bounds
      if p1 < o.FontOffsetXMin or p1 > o.FontOffsetXMax then
        p1 = 0
      end
      if p2 < o.FontOffsetYMin or p2 > o.FontOffsetYMax then
        p2 = 0
      end
    elseif TypeID == 'fontsize' then
      p2, p3, p4 = nil, nil, nil

      p1 = tonumber(p1) or 0

      -- check for out of bounds
      if p1 < o.TriggerFontSizeMin or p1 > o.TriggerFontSizeMax then
        p1 = 0
      end
    elseif TypeID == 'fonttype' then
      p2, p3, p4 = nil, nil, nil
      p1 = LSMFontDropdown[p1] or DefaultFontType
    elseif TypeID == 'fontstyle' then
      p2, p3, p4 = nil, nil, nil
      p1 = FontStyleDropdown[p1] or 'NONE'

    elseif TypeID == 'sound' then
      p3, p4 = nil, nil, nil
      if LSMSoundDropdown[p1] == nil then
        p1 = DefaultSound
      end
      if TriggerSoundChannelDropdown[p2] == nil then
        p2 = DefaultSoundChannel
      end
    end
    Pars[1], Pars[2], Pars[3], Pars[4] = p1, p2, p3, p4

    -- Validate getpars
    local GetFnTypeID = Trigger.GetFnTypeID
    local GetPars = Trigger.GetPars
    p1, p2, p3, p4 = GetPars[1], GetPars[2], GetPars[3], GetPars[4]

    if GetFnTypeID == 'classcolor' or GetFnTypeID == 'powercolor' or
       GetFnTypeID == 'combatcolor' or GetFnTypeID == 'taggedcolor' then
      p2, p3, p4 = nil, nil, nil
    end

    GetPars[1], GetPars[2], GetPars[3], GetPars[4] = p1, p2, p3, p4
  end

  --====================================
  -- SUB FUNCTION CreateClearPasteButton
  --====================================
  local function CreateClearButton(Order, ButtonType)
    -- top     Top of all triggers or empty group
    -- bottom  Next trigger

    local Clear = {
      type = 'execute',
      order = function()
                if ButtonType == 'top' then
                  return Order
                else
                  return Trigger.OrderNumber + Order
                end
              end,
      name = 'Clear',
      width = 'half',
      desc = function()
               if ClipBoard.Move then
                 return 'Clears the current move'
               elseif ClipBoard.Copy then
                 return 'Clears the current copy'
               end
             end,
      func = function()
               HideTooltip(true)

               ClipBoard.Move = nil
               ClipBoard.Copy = nil
             end,
      hidden = function()
                 return ClipBoard.Move == nil and ClipBoard.Copy == nil
               end
    }
    return Clear
  end

  local function CreatePasteButton(Order, ButtonType)
    local Paste = {
      type = 'execute',
      order = function()
                if ButtonType == 'top' then
                  return Order
                else
                  return Trigger.OrderNumber + Order
                end
              end,
      name = 'Paste',
      width = 'half',
      desc = 'Click to paste trigger here',
      disabled = function()
                   local CB = ClipBoard.Move or ClipBoard.Copy

                   if CB then
                     return not BBar:CompTriggers(CB.Source, GroupNumber)
                   end
                 end,
      hidden = function()
                 return ClipBoard.Move == nil and ClipBoard.Copy == nil
               end,
      func = function()
               local CB = ClipBoard.Move or ClipBoard.Copy

               local Source = CB.Source
               local T = nil
               local Index = nil

               if ButtonType == 'top' then
                 Index = 1
               elseif ButtonType == 'bottom' then
                 Index = Trigger.Index + 1
               end
               if ClipBoard.Move then
                 T = BBar:MoveTriggers(Source, GroupNumber, Index)
               else
                 T = BBar:CopyTriggers(Source, GroupNumber, Index)
                 T.Name = '[Copy] ' .. T.Name

                 -- Set select so there is not two selected triggers at the same time.
                 T.Select = false
               end

               -- Paste trigger options
               AddTriggerOption(UBF, BBar, TOA, GroupNames, ClipBoard, Groups, Triggers, T)

               if ClipBoard.Move then

                 -- Delete old option
                 DeleteTriggerOption(CB.SourceTGA, Source)

                 -- Clear the clipboard
                 ClipBoard.Move = nil
               else
                 ClipBoard.Copy = nil
               end

               -- update the bar
               UBF:Update()
               BBar:Display()

               HideTooltip(true)
             end,
    }
    return Paste
  end

  --====================================
  -- SUB FUNCTION CreateSwapButton
  --====================================
  local function CreateSwapButton(Order, ButtonType)
    -- select   swap button for the selected trigger
    -- other    for other triggers not selected.

    local Swap = {
      type = 'execute',
      order = Order,
      name = 'Swap',
      width = 'half',
      hidden = function()
                 if ButtonType == 'select' and Trigger.Select then
                   return ClipBoard.Move ~= nil or ClipBoard.Copy ~= nil
                 elseif ButtonType == 'other' and not Trigger.Select then
                   return ClipBoard.Swap == nil
                 else
                   return true
                 end
               end,
      disabled = function()
                   local Swap = ClipBoard.Swap

                   HideTooltip(true)

                   if #Triggers == 1 then
                     return true
                   elseif Swap then
                     if Swap.Source == Trigger then
                       return true
                     else
                       local Source = Swap.Source

                       return not BBar:CompTriggers(Source, GroupNumber) or not BBar:CompTriggers(Trigger, Source.GroupNumber)
                     end
                   end
                 end,
      desc = 'Click "Swap" on the two triggers you want to swap.',
      func = function()
               local Swap = ClipBoard.Swap

               if Swap == nil then
                 Swap = {}
                 Swap.Source = Trigger
                 Swap.SourceTGA = TGA
                 ClipBoard.Swap = Swap
               else
                 local Source = Swap.Source

                 if BBar:SwapTriggers(Source, Trigger) then

                   -- Swap the option tables
                   AddTriggerOption(UBF, BBar, TOA, GroupNames, ClipBoard, Groups, Triggers, Source)
                   AddTriggerOption(UBF, BBar, TOA, GroupNames, ClipBoard, Groups, Triggers, Trigger)

                   -- Delete the old options.
                   DeleteTriggerOption(TGA, Trigger)
                   DeleteTriggerOption(Swap.SourceTGA, Source)
                 end

                 -- Clear the clipboard
                 ClipBoard.Swap = nil

                 -- update the bar
                 UBF:Update()
                 BBar:Display()

                 HideTooltip(true)
               end
             end,
    }
    return Swap
  end

  --====================================
  -- SUB FUNCTION CreateClearSwapButton
  --====================================
  local function CreateClearSwapButton(Order, ButtonType)
    -- select   swap button for the selected trigger
    -- other    for other triggers not selected.

    local ClearSwap = {
      type = 'execute',
      order = Order,
      name = 'Clear',
      width = 'half',
      desc = 'Clears the current swap',
      hidden = function()
                 if ButtonType == 'select' and Trigger.Select then
                   return ClipBoard.Swap == nil
                 elseif ButtonType == 'other' and not Trigger.Select then
                   return ClipBoard.Swap == nil
                 else
                   return true
                 end
               end,
      func = function()
               HideTooltip(true)
               ClipBoard.Swap = nil
             end,
    }
    return ClearSwap
  end

  -- Adding 'add' button and util buttons for empty groups
  -- Then return
  if TriggerType == 'number' then
    TGA.Add = {
      type = 'execute',
      order = 0.1,
      name = 'Add',
      width = 'half',
      desc = 'Click to add the first trigger',
      func = function()
               local T = BBar:CreateDefaultTriggers(GroupNumber)

               -- Make sure pars is correct.
               SetDefaultPars(T)

               BBar:InsertTriggers(T)
               AddTriggerOption(UBF, BBar, TOA, GroupNames, ClipBoard, Groups, Triggers, T)

               -- Update bar to reflect trigger changes
               UBF:Update()
               BBar:Display()

               HideTooltip(true)
             end,
      hidden = function()
                 return Group.TriggersInGroup > 0 or ClipBoard.Move or ClipBoard.Copy
               end,
    }
    TGA.ClearButton = CreateClearButton(0.2, 'top')
    TGA.PasteButton = CreatePasteButton(0.3, 'top')
    return
  end

  -- Create 'clear' and 'paste' buttons at the bottom of the trigger.
  local TriggerHex = ToHex(Trigger)
  TGA['Clear' .. TriggerHex] = CreateClearButton(0.1, 'bottom')
  TGA['Paste' .. TriggerHex] = CreatePasteButton(0.2, 'bottom')

  --===================================
  -- Main Trigger UI starts here
  --===================================

  -- create trigger header
  local TO = {
    type = 'group',
    guiInline = true,
    name = ' ',
    order = function()
              return Trigger.OrderNumber
            end,
  }

  TGA['Trigger' .. ToHex(Trigger)] = TO

  TO.args = {

    --================================
    -- Clear, Paste, and move buttons
    --================================
    ClearSwapButton = CreateClearSwapButton(32, 'other'),
    SwapButton = CreateSwapButton(33, 'other'),

    --================================
    -- Name button
    --================================
    Select = {
      type = 'input',
      order = 5,
      name = function()
               local Texture = ConvertTypeIDColorIcon[Trigger.TypeID]
               local rgb = '0.7, 0.7, 0.7'

               if not Trigger.Enabled then
                 rgb = '0.75, 0, 0'
               elseif Trigger.SpecEnabled and Trigger.DisabledBySpec then
                 rgb = '0.75, 0.75, 0'
               elseif Trigger.Static then
                 rgb = '0, 0.75, 0'
               end

               if Texture then
                 return format('%s:%s  |T%s:16|t  |cFFFFFF00%s|r', rgb, Trigger.OrderNumber, Texture, Trigger.Name)
               else
                 return format('%s:%s %s', rgb, Trigger.OrderNumber, Trigger.Name)
               end
             end,
      width = 'full',
      dialogControl = 'GUB_Text_Button',
      desc = 'click test',
      set = function()
              BBar:SetSelectTrigger(Trigger.GroupNumber, Trigger.Index)
            end
    },
    Spacer55 = CreateSpacer(5.5),

    --================================
    -- Action
    --================================
    Static = {
      type = 'toggle',
      order = 6,
      width = 'half',
      name = 'Static',
      desc = 'Click to make the trigger always on',
      get = function()
              return Trigger.Static
            end,
      set = function(Info, Value)
              Trigger.Static = Value

              -- update the bar
              BBar:CheckTriggers()
              UBF:Update()
              BBar:Display()
            end,
      hidden = function()
                 return not Trigger.Select
               end,
      disabled = function()
                   return not Trigger.Enabled
                 end,
    },
    Disabled = {
      type = 'toggle',
      order = 7,
      width = 'half',
      name = 'Disable',
      desc = 'If checked, this trigger will no longer function',
      get = function()
              return not Trigger.Enabled
            end,
      set = function(Info, Value)
               Trigger.Enabled = not Value

               -- update the bar
               BBar:CheckTriggers()
               UBF:Update()
               BBar:Display()
             end,
      hidden = function()
                 return not Trigger.Select
               end,
    },
    SpecEnabled = {
      type = 'toggle',
      order = 8,
      name = 'Specialization',
      desc = 'If checked, this trigger will only function on class and specialization',
      hidden = function()
                 return not Trigger.Select
               end,
      disabled = function()
                   HideTooltip(true)
                   return not Trigger.Enabled
                 end,
    },
    SpecOptions = CreateSpecOptions(BBar.BarType, 9, Trigger.ClassSpecs, BBar),
    Spacer10 = CreateSpacer(10, 'full', function() return not Trigger.Select end),
    ActionType = {
      type = 'input',
      order = 11,
      name = function()
               return format('Type:%s', GetMenuButton('Type'))
             end,
      width = 'half',
      dialogControl = 'GUB_Menu_Button',
      set = function()
              ToggleMenuButton('Type')

              HideTooltip(true)
            end,
      get = function() end,
      hidden = function()
                 return not Trigger.Select
               end,
    },
    ActionValue = {
      type = 'input',
      order = 12,
      name = function()
               return format('Value:%s', GetMenuButton('Value'))
             end,
      width = 'half',
      dialogControl = 'GUB_Menu_Button',
      set = function()
              ToggleMenuButton('Value')

              HideTooltip(true)
            end,
      get = function() end,
      hidden = function()
                 return not Trigger.Select
               end,
      disabled = function()
                   return Trigger.Static
                 end
    },
    ActionName = {
      type = 'input',
      order = 13,
      name = function()
               return format('Name:%s', GetMenuButton('Name'))
             end,
      width = 'half',
      dialogControl = 'GUB_Menu_Button',
      set = function()
              ToggleMenuButton('Name')

              HideTooltip(true)
            end,
      get = function() end,
      hidden = function()
                 return not Trigger.Select
               end,
    },
    ActionSpacer14 = CreateSpacer(14, 'half', function() return not Trigger.Select end),
    ActionUtil = {
      type = 'input',
      order = 15,
      name = function()
               return format('Util:%s', GetMenuButton('Util'))
             end,
      width = 'half',
      dialogControl = 'GUB_Menu_Button',
      set = function()
              ToggleMenuButton('Util')

              HideTooltip(true)
            end,
      get = function() end,
      hidden = function()
                 return not Trigger.Select
               end,
    },
    Name = {
      type = 'input',
      name = 'Name',
      order = 21,
      width = 'full',
      get = function()
              return Trigger.Name or ''
            end,
      set = function(Info, Value)
              Trigger.Name = Value
            end,
      hidden = function()
                 return not Trigger.Select or TriggerAction('Name') == 0
               end,
    },
    SepLineBottom = {
      type = 'header',
      name = '',
      order = 20,
      hidden = function()
                 return not Trigger.Select
               end,
    },

    --=============================
    -- Type
    --=============================
    Type = {
      type = 'group',
      order = 21,
      name = '',
      hidden = function()
                 return TriggerAction('Type') == 0 or not Trigger.Select
               end,
      disabled = function()
                   return not Trigger.Enabled or Trigger.DisabledBySpec
                 end,
      args = {
        ValueType = {
          type = 'select',
          name = 'Value Type',
          order = 1,
          values = function()
                     return Group.ValueTypes
                   end,
          style = 'dropdown',
          disabled = function()
                       return Trigger.Static or not Trigger.Enabled or Trigger.DisabledBySpec
                     end,
        },
        Type = {
          type = 'select',
          name = 'Type',
          width = BBar.BarType ~= 'FragmentBar' and 'normal' or 'double',
          order = 2,
          desc = 'Type of trigger',
          values = function()
                     return Group.Types
                   end,
          style = 'dropdown',
        },
        Spacer3 = CreateSpacer(3, nil, function()
                                         return Trigger.CanAnimate
                                       end),
        Animate = {
          type = 'toggle',
          name = 'Animate',
          desc = 'Apply animation to this trigger',
          order = 4,
          hidden = function()
                     return not Trigger.CanAnimate
                   end,
        },
        AnimateSpeed = {
          type = 'range',
          name = 'Animate Speed',
          order = 5,
          desc = 'Changes the speed of the animation',
          step = .01,
          isPercent = true,
          disabled = function()
                       return not Trigger.Animate
                     end,
          hidden = function()
                     return not Trigger.CanAnimate
                   end,
          min = o.TriggerAnimateSpeedMin,
          max = o.TriggerAnimateSpeedMax,
        },
        Spacer6 = CreateSpacer(6, nil, function()
                                         local TypeID = Trigger.TypeID

                                         return TypeID ~= 'fontcolor' and TypeID ~= 'fontoffset' and
                                                TypeID ~= 'fontsize' and TypeID ~= 'fonttype'
                                       end),
        TextLine = {
          type = 'select',
          name = 'Text Line',
          order = 7,
          values = TextLineDropdown,
          style = 'dropdown',
          hidden = function()
                     local TypeID = Trigger.TypeID

                     return TypeID ~= 'fontcolor' and TypeID ~='fontoffset' and
                            TypeID ~= 'fontsize' and TypeID ~= 'fonttype' and TypeID ~= 'fontstyle'
                   end,
        },
        Spacer10 = CreateSpacer(10),
        ParsColor = {
          type = 'color',
          name = 'Color',
          order = 11,
          width = 'half',
          hasAlpha = true,
          hidden = function()
                     local TypeID = Trigger.TypeID

                     return TypeID ~= 'bordercolor' and TypeID ~= 'backgroundcolor' and TypeID ~= 'bartexturecolor' and
                            TypeID ~= 'fontcolor'
                   end,
        },
        ParsTexture = {
          type = 'select',
          name = 'Texture',
          order = 12,
          dialogControl = 'LSM30_Statusbar',
          values = LSMStatusBarDropdown,
          hidden = function()
                     return Trigger.TypeID ~= 'bartexture'
                   end,
        },
        ParsTextureScale = {
          type = 'range',
          name = 'Texture Scale',
          order = 13,
          desc = 'Change the texture size',
          step = .01,
          width = 'double',
          isPercent = true,
          hidden = function()
                     return Trigger.TypeID ~= 'texturescale'
                   end,
          min = o.TriggerTextureScaleMin,
          max = o.TriggerTextureScaleMax,
        },

        ParsBarOffsets = CreateOffsetOption(13.5, UBF, BBar, Trigger),
        ParsBorder = {
          type = 'select',
          name = 'Border',
          desc = function()
                   return Trigger.Pars[1] or ''
                 end,
          order = 15,
          dialogControl = 'LSM30_Border',
          values = LSMBorderDropdown,
          hidden = function()
                     return Trigger.TypeID ~= 'border'
                   end,
        },
        ParsBackground = {
          type = 'select',
          name = 'Background',
          width = 'double',
          desc = function()
                   return Trigger.Pars[1] or ''
                 end,
          order = 16,
          dialogControl = 'LSM30_Background',
          values = LSMBackgroundDropdown,
          hidden = function()
                     return Trigger.TypeID ~= 'background'
                   end,
        },
        ParsSound = {
          type = 'select',
          name = 'Sound',
          desc = function()
                   return Trigger.Pars[1] or ''
                 end,
          order = 17,
          dialogControl = 'LSM30_Sound',
          values = LSMSoundDropdown,
          hidden = function()
                     return Trigger.TypeID ~= 'sound'
                   end,
        },
        ParsTextOffsetX = {
          type = 'range',
          name = 'Horizonal',
          order = 18,
          min = o.FontOffsetXMin,
          max = o.FontOffsetXMax,
          step = 1,
          hidden = function()
                     return Trigger.TypeID ~= 'fontoffset'
                   end,
        },
        ParsTextOffsetY = {
          type = 'range',
          name = 'Vertical',
          order = 19,
          min = o.FontOffsetYMin,
          max = o.FontOffsetYMax,
          step = 1,
          hidden = function()
                     return Trigger.TypeID ~= 'fontoffset'
                   end,
        },
        ParsTextSize = {
          type = 'range',
          name = 'Size',
          order = 20,
          min = o.TriggerFontSizeMin,
          max = o.TriggerFontSizeMax,
          step = 1,
          width = 'double',
          hidden = function()
                     return Trigger.TypeID ~= 'fontsize'
                   end,
        },
        ParsTextType = {
          type = 'select',
          name = 'Type',
          order = 21,
          dialogControl = 'LSM30_Font',
          values = LSMFontDropdown,
          hidden = function()
                     return Trigger.TypeID ~= 'fonttype'
                   end,
        },
        ParsTextStyle = {
          type = 'select',
          name = 'Style',
          order = 22,
          style = 'dropdown',
          values = FontStyleDropdown,
          hidden = function()
                     return Trigger.TypeID ~= 'fontstyle'
                   end,
        },
        ParsSoundChannel = {
          type = 'select',
          name = 'Sound Channel',
          order = 23,
          style = 'dropdown',
          values = TriggerSoundChannelDropdown,
          hidden = function()
                     return Trigger.TypeID ~= 'sound'
                   end,
        },
        GetParsColorType = {
          type = 'select',
          name = 'Color Type',
          desc = 'This will override the current color, if there is a new one to replace it with',
          order = 24,
          values = function()
                     return Group.Objects[Trigger.TypeIndex].GetFnTypes
                   end,
          hidden = function()
                     HideTooltip(true)
                     return Group.Objects[Trigger.TypeIndex].GetFnTypes == nil or strfind(Trigger.TypeID, 'color') == nil
                   end,
        },
        GetParsColorUnit = {
          type = 'input',
          name = 'Color Unit',
          desc = 'Enter the unit you want to get the color from',
          order = 25,
          hidden = function()
                     local GetFnTypeID = Trigger.GetFnTypeID

                     return Group.Objects[Trigger.TypeIndex].GetFnTypes == nil or
                            GetFnTypeID ~= 'classcolor' and GetFnTypeID ~= 'powercolor' and GetFnTypeID ~= 'combatcolor' and
                            GetFnTypeID ~= 'taggedcolor'
                   end,
        },
      },
    },
    --=============================
    -- Value
    --=============================

    --================================================
    -- Condition UI here. See bottom of this function.
    --================================================
    Value = {
      type = 'group',
      order = 21,
      name = '',
      hidden = function()
                 return TriggerAction('Value') == 0 or not Trigger.Select
               end,
      disabled = function()
                   return not Trigger.Enabled or Trigger.DisabledBySpec
                 end,
      args = {
        AuraOperator = {
          type = 'select',
          name = 'Operator',
          width = 'half',
          desc = '"and" means all auras\n"or" at least one aura',
          order = 1,
          values = TriggerOperatorDropdown.auras,
          style = 'dropdown',
          hidden = function()
                     return Trigger.Static or Trigger.ValueTypeID ~= 'auras'
                   end,
        },
        State = {
          type = 'toggle',
          name = 'Inverse',
          order = 2,
          hidden = function()
                     return Trigger.Static or Trigger.ValueTypeID ~= 'state'
                   end,
        },
        AuraValue = {
          type = 'input',
          name = function()
                   if InvalidSpell then
                     return 'Invalid aura'
                   else
                     return 'Aura name or Spell ID'
                   end
                 end,
          order = 3,
          dialogControl = 'GUB_Aura_EditBox',
          set = function(Info, Value, SpellID)
                  InvalidSpell = false
                  Value = strtrim(Value)

                  if Value == '' then
                    return
                  end

                  -- Must be valid SpellID or selected spell.
                  if SpellID == nil then

                    -- Check to make sure spellID is a number
                    Value = tonumber(Value)
                    if Value == nil then
                      InvalidSpell = true
                    else
                      -- Check to make sure the spellID exists.
                      local Name = GetSpellInfo(Value)

                      if Name == nil or Name == '' then
                        InvalidSpell = true
                      else
                        SpellID = Value
                      end
                    end
                  end

                  -- Add aura to Trigger.Auras
                  -- And create aura menu
                  if not InvalidSpell then
                    if Trigger.Auras[SpellID] == nil then
                      Trigger.Auras[SpellID] = {
                        Own = false,
                        Unit = 'player',
                        StackOperator = '>=',
                        Stacks = 0,
                      }

                      -- Add option
                      BBar:CheckTriggers()
                      AddAuraOption(AuraGroupOrder, UBF, BBar, TO.args.Value, SpellID, Trigger)

                      -- update the bar
                      UBF:Update()
                      BBar:Display()
                    end
                  end
                end,
          get = function()
                end,
          hidden = function()
                     return Trigger.Static or Trigger.ValueTypeID ~= 'auras'
                   end,
        },
        AurasHide = {
          type = 'execute',
          name = function()
                   if Trigger.HideAuras then
                     return 'Show'
                   else
                     return 'Hide'
                   end
                 end,
          width = 'half',
          order = 5,
          func = function()
                   Trigger.HideAuras = not Trigger.HideAuras
                   HideTooltip(true)
                 end,
          hidden = function()
                     return Trigger.Auras == nil or Trigger.Static or Trigger.ValueTypeID ~= 'auras'
                   end,
        },
        --================================================
        -- Auras UI here. See bottom of this function.
        --================================================
      },
    },
    --================================
    -- Utility
    --================================
    Utility = {
      type = 'group',
      order = 21,
      name = '',
      hidden = function()
                 return TriggerAction('Util') == 0 or not Trigger.Select
               end,
      args = {
        ClearSwap = CreateClearSwapButton(3, 'select'),
        Swap = CreateSwapButton(4, 'select'),
        Move = {
          type = 'execute',
          order = 5,
          name = 'Move',
          width = 'half',
          hidden = function()
                     return next(ClipBoard) ~= nil
                   end,
          disabled = function()
                       HideTooltip(true)
                       return ClipBoard.Move ~= nil
                     end,
          desc = 'Click "Move" on the trigger you want moved. Then click on "paste" for the destination.',
          func = function()
                   local Move = {}

                   Move.Source = Trigger
                   Move.SourceTGA = TGA
                   ClipBoard.Move = Move

                   HideTooltip(true)
                 end,
        },
        Copy = {
          type = 'execute',
          order = 6,
          name = 'Copy',
          width = 'half',
          hidden = function()
                     return next(ClipBoard) ~= nil
                   end,
          desc = 'Click "Copy" on the trigger you want copied. Then click on "paste" for the destination.',
          func = function()
                   local Copy = {}

                   Copy.Source = Trigger
                   Copy.SourceTGA = TGA
                   ClipBoard.Copy = Copy

                   HideTooltip(true)
                 end,
        },
        Spacer7 = CreateSpacer(7, 'half'),
        Delete = {
          type = 'execute',
          order = 8,
          name = 'Delete',
          width = 'half',
          desc = function()
                   return format('Delete trigger %s', Trigger.OrderNumber)
                 end,
          confirm = function()
                      if not IsModifierKeyDown() then
                        return 'Are you sure you want to delete this trigger?\n Hold a modifier key down and click delete to bypass this warning'
                      end
                    end,
          func = function()
                   BBar:RemoveTriggers(Trigger.Index)
                   DeleteTriggerOption(TGA, Trigger)

                   -- update the bar
                   UBF:Update()
                   BBar:Display()

                   HideTooltip(true)
                 end,
          hidden = function()
                     return next(ClipBoard) ~= nil
                   end,
        },
      },
    },
  }

  --============
  -- Specialization options modification
  --============
  TO.args.SpecOptions.hidden = function()
                                 return not Trigger.Select or not Trigger.SpecEnabled
                               end
  TO.args.SpecOptions.disabled = function()
                                   return not Trigger.Enabled
                                 end
  --============
  -- GET and SET
  --============
  TO.get = function(Info)
             local KeyName = Info[#Info]

             if strfind(KeyName, 'Pars') then
               if KeyName == 'GetParsColorType' then
                 return Group.Objects[Trigger.TypeIndex].GetFnTypeIDs[Trigger.GetFnTypeID]

               -- Color unit for a get function. so GetPars[1] is used.
               elseif KeyName == 'GetParsColorUnit' then
                 return Trigger.GetPars[1] or ''
               else
                 local Pars = Trigger.Pars
                 local p1, p2, p3, p4 = Pars[1], Pars[2], Pars[3], Pars[4]

                 if KeyName == 'ParsColor' then
                   return p1 or 0, p2 or 0, p3 or 0, p4 or 1

                 elseif KeyName == 'ParsTextOffsetX' then
                   return p1
                 elseif KeyName == 'ParsTextOffsetY' then
                   return p2
                 elseif KeyName == 'ParsTextSize' then
                   return p1
                 elseif KeyName == 'ParsTextType' then
                   return p1
                 elseif KeyName == 'ParsTextStyle' then
                   return p1

                 elseif KeyName == 'ParsSoundChannel' then
                   return p2

                 else
                   return p1
                 end
               end
             elseif KeyName == 'AuraOperator' then
               return FindMenuItem(TriggerOperatorDropdown.auras, Trigger.AuraOperator)
             elseif KeyName == 'ValueType' then
               return Group.RValueTypes[Trigger.ValueType]
             elseif KeyName == 'Type' then
               return Group.RTypes[Trigger.Type]
             elseif KeyName == 'State' then
               return not Trigger.State
             else
               return Trigger[KeyName]
             end
           end
  TO.set = function(Info, Value, g, b, a)
             local KeyName = Info[#Info]

             if strfind(KeyName, 'Pars') then
               if KeyName == 'GetParsColorType' then
                 Trigger.GetFnTypeID = Group.Objects[Trigger.TypeIndex].GetFnTypeIDs[Value]

                 -- make sure pars are correct.
                 SetDefaultPars(Trigger)

               -- Color unit for a get function. so GetPars[1] is used.
               elseif KeyName == 'GetParsColorUnit' then
                 Trigger.GetPars[1] = Value
               else
                 local Pars = Trigger.Pars

                 if KeyName == 'ParsColor' then
                   Pars[1], Pars[2], Pars[3], Pars[4] =  Value, g, b, a

                   -- Update the triggers here for better performance
                   -- Dont need to do a checktriggers here.
                   UBF:Update()
                   BBar:Display()
                   return

                 elseif KeyName == 'ParsTextureScale' then
                   Pars[1] = Value

                   -- Update the triggers here for better performance
                   -- Dont need to do a checktriggers here.
                   UBF:Update()
                   BBar:Display()
                   return

                 elseif strfind(KeyName, 'TextOffset') or KeyName == 'ParsTextSize' or
                        KeyName == 'ParsTextType' or KeyName == 'ParsTextStyle' then
                   if KeyName == 'ParsTextOffsetY' then
                     Pars[2] = Value
                   else
                     Pars[1] = Value
                   end
                   -- Update the triggers here for better performance
                   -- Dont need to do a checktriggers here.
                   UBF:Update()
                   BBar:Display()
                   return

                 elseif KeyName == 'ParsSoundChannel' then
                   Pars[2] = Value
                 else
                   Pars[1] = Value
                 end
               end
             elseif KeyName == 'AuraOperator' then
               Trigger.AuraOperator = TriggerOperatorDropdown.auras[Value]

             elseif KeyName == 'ValueType' then
               Trigger.ValueTypeID = Group.ValueTypeIDs[Value]
               Trigger.ValueType = strlower(Group.ValueTypes[Value])

             elseif KeyName == 'Type' then
               Trigger.TypeID = Group.TypeIDs[Value]
               Trigger.Type = strlower(Group.Types[Value])

               -- make sure pars are correct.
               SetDefaultPars(Trigger)
             elseif KeyName == 'State' then
               Trigger.State = not Value
             else
               Trigger[KeyName] = Value
             end

             -- Update bar to reflect trigger changes
             if KeyName ~= 'AnimateSpeed' and KeyName ~= 'Animate' then
               BBar:CheckTriggers()
             end
             UBF:Update()
             BBar:Display()
           end

  -- Add aura options
  local Auras = Trigger.Auras

  if Auras then
    for SpellID, Aura in pairs(Auras) do
      AddAuraOption(AuraGroupOrder, UBF, BBar, TO.args.Value, SpellID, Trigger)
    end
  end

  -- Add condition options
  for _, Condition in ipairs(Trigger.Conditions) do
    AddConditionOption(ConditionOrder, TO.args.Value, UBF, BBar, Condition, Trigger)
  end
end

-------------------------------------------------------------------------------
-- CreateTriggerOptions
--
-- Creates trigger options that lets you add, remove, insert.
--
-- SubFunction of CreateUnitBarOptions
--
-- BarType        Options will be added for this bar.
-- Order          Order number in the options frame
-- Name           Name as it appears in the options frame.
-------------------------------------------------------------------------------
local function CreateTriggerOptions(BarType, Order, Name)

  local TriggerOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    args = {}, -- need this so ACE3 dont crash if triggers options are not created.
  }

  -- Create the trigger list options.
  Options:DoFunction(BarType, 'CreateTriggerOptions', function()

    -- Only create triggers if they're enabled.
    if Main.UnitBars[BarType].Layout.EnableTriggers then
      local TOA = {}
      TriggerOptions.args = TOA

      local UBF = UnitBarsF[BarType]
      local BBar = UBF.BBar
      local Triggers = UBF.UnitBar.Triggers
      local Groups = BBar.Groups
      local Notes = DUB[BarType].Triggers.Notes
      local GroupNames = {} -- so I dont have to use format to index the tabs.
      local ClipBoard = {}

      if Notes then
        TOA.Notes = {
          type = 'description',
          name = Notes,
          order = 0.10,
        }
      end

      TOA.MenuSync = {
        type = 'toggle',
        order = 0.3,
        name = 'Menu Sync',
        desc = 'If checked, all triggers will switch to the same menu selection',
        set = function(Info, Value)
                Triggers.MenuSync = Value
              end,
        get = function()
                return Triggers.MenuSync
              end,
      }

      TOA.HideTabs = {
        type = 'toggle',
        order = 0.4,
        name = 'Hide Tabs',
        width = 'half',
        desc = 'If checked, empty tabs will be hidden',
        set = function(Info, Value)
                Triggers.HideTabs = Value
              end,
        get = function()
                return Triggers.HideTabs
              end,
      }

      -- Create tabs
      for GroupNumber = 1, #Groups do
        local GroupName = format('Group%s', GroupNumber)
        local Group = Groups[GroupNumber]

        GroupNames[GroupNumber] = GroupName
        TOA[GroupName] = {
          type = 'group',
          name = function()
                   -- color tabs that have at least one trigger.
                   if Group.TriggersInGroup > 0 and #Groups > 1 then
                     return format('%s *', Group.Name)
                   else
                     return Group.Name
                   end
                 end,
          order = GroupNumber,
          hidden = function()
                     local AllEmpty = true

                     for Index = 1, #Groups do
                       if Groups[Index].TriggersInGroup > 0 then
                         AllEmpty = false
                         break
                       end
                     end

                     if Group.TriggersInGroup == 0 and not AllEmpty then
                       return Triggers.HideTabs
                     else
                       return false
                     end
                   end,
          args = {}
        }

        -- Initialize each group.
        AddTriggerOption(UBF, BBar, TOA, GroupNames, ClipBoard, Groups, Triggers, GroupNumber)
      end

      -- Add options for each trigger.
      for Index = 1, #Triggers do
        local Trigger = Triggers[Index]

        AddTriggerOption(UBF, BBar, TOA, GroupNames, ClipBoard, Groups, Triggers, Trigger)
      end
    end
  end)

  Options:DoFunction(BarType, 'CreateTriggerOptions')

  return TriggerOptions
end

-------------------------------------------------------------------------------
-- CreateStatusOptions
--
-- Creates the status flags for all unitbars.
--
-- Subfunction of CreateUnitBarOptions
--
-- BarType       The options being created for.
-- Order         Where the options appear on screen.
-- Name          Name of the options.
-------------------------------------------------------------------------------
local function CreateStatusOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local StatusOptions = {
    type = 'group',
    name = 'Status',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Status[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.Status[Info[#Info]] = Value

            -- Update the status of all bars.
            GUB:UnitBarsUpdateStatus()
          end,
    args = {}
  }

  local StatusArgs = StatusOptions.args

  if UBD.Status.ShowAlways ~= nil then
    StatusArgs.ShowAlways = {
      type = 'toggle',
      name = 'Show Always',
      order = 3,
      desc = "Always show the bar in and out of combat",
    }
  end
  if UBD.Status.HideWhenDead ~= nil then
    StatusArgs.HideWhenDead = {
      type = 'toggle',
      name = 'Hide when Dead',
      order = 4,
      desc = "Hides the bar when you're dead",
    }
  end
  if UBD.Status.HideNoTarget ~= nil then
    StatusArgs.HideNoTarget = {
      type = 'toggle',
      name = 'Hide no Target',
      order = 5,
      desc = 'Hides the bar when you have no target selected',
    }
  end
  if UBD.Status.HideInVehicle ~= nil then
    StatusArgs.HideInVehicle = {
      type = 'toggle',
      name = 'Hide in Vehicle',
      order = 6,
      desc = "Hides the bar when you're in a vehicle",
    }
  end
  if UBD.Status.HideInPetBattle ~= nil then
    StatusArgs.HideInPetBattle = {
      type = 'toggle',
      name = 'Hide in Pet Battle',
      order = 7,
      desc = "Hides the bar when you're in a pet battle",
    }
  end
  if UBD.Status.HideNotActive ~= nil then
    StatusArgs.HideNotActive = {
      type = 'toggle',
      name = 'Hide not Active',
      order = 8,
      desc = 'Bar will be hidden if its not active. This only gets checked out of combat',
    }
  end
  if UBD.Status.HideNoCombat ~= nil then
    StatusArgs.HideNoCombat = {
      type = 'toggle',
      name = 'Hide no Combat',
      order = 9,
      desc = 'When not in combat the bar will be hidden',
    }
  end
  if UBD.Status.HideIfBlizzAltPowerVisible ~= nil then
    StatusArgs.HideIfBlizzAltPowerVisible = {
      type = 'toggle',
      name = 'Hide if Blizzard Visible',
      order = 10,
      desc = 'Hide when the blizzard alternate power bar is visible. This only works while the alternate power bar is active',
    }
  end

  return StatusOptions
end

-------------------------------------------------------------------------------
-- CreateTestModeOptions
--
-- Subfunction of CreateUnitBarOptions
--
-- BarType       The options being created for.
-- Order         Where the options appear on screen.
-- Name          Name of the options.
-------------------------------------------------------------------------------
local function CreateTestModeOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local TestModeOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.TestMode[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local TestMode = UBF.UnitBar.TestMode
            TestMode[KeyName] = Value

            if Value then
              if KeyName == 'DeeperStratagem' then
                TestMode.Anticipation = false
              elseif KeyName == 'Anticipation' then
                TestMode.DeeperStratagem = false
              end
              if KeyName == 'BloodSpec' then
                TestMode.FrostSpec = false
                TestMode.UnHolySpec = false
              elseif KeyName == 'FrostSpec' then
                TestMode.BloodSpec = false
                TestMode.UnHolySpec = false
              elseif KeyName == 'UnHolySpec' then
                TestMode.BloodSpec = false
                TestMode.FrostSpec = false
              end
              if KeyName == 'AltTypePower' then
                TestMode.AltTypeCounter = false
              end
              if KeyName == 'AltTypeCounter' then
                TestMode.AltTypePower = false
              end
            elseif KeyName == 'BloodSpec' or KeyName == 'FrostSpec' or KeyName == 'UnHolySpec' then
              if not TestMode.BloodSpec and not TestMode.FrostSpec and not TestMode.UnHolySpec then
                TestMode[KeyName] = true
              end
            elseif KeyName == 'AltTypePower' or KeyName == 'AltTypeCounter' then
              TestMode[KeyName] = true
            end

            -- Update the bar to show test mode changes.
            UBF:SetAttr('TestMode', KeyName)
          end,
    hidden = function()
               return not Main.UnitBars.Testing
             end,
    args = {},
  }
  local TestModeArgs = TestModeOptions.args

  if UBD.TestMode.Value ~= nil then
    TestModeArgs.Value = {
      type = 'range',
      name = 'Value',
      order = 100,
      desc = 'Change the bars value',
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.PredictedHealth ~= nil then
    TestModeArgs.PredictedHealth = {
      type = 'range',
      name = 'Predicted Health',
      order = 101,
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.AbsorbHealth ~= nil then
    TestModeArgs.AbsorbHealth = {
      type = 'range',
      name = 'Absorb Health',
      order = 102,
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.PredictedPower ~= nil then
    TestModeArgs.PredictedPower = {
      type = 'range',
      name = 'Predicted Power',
      order = 103,
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.PredictedCost ~= nil then
    TestModeArgs.PredictedCost = {
      type = 'range',
      name = 'Predicted Cost',
      order = 104,
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.UnitLevel ~= nil then
    TestModeArgs.UnitLevel = {
      type = 'range',
      name = 'Unit Level',
      order = 105,
      desc = 'Change the bars level',
      step = 1,
      width = 'full',
      min = o.TestModeUnitLevelMin,
      max = o.TestModeUnitLevelMax,
    }
  end
  if UBD.TestMode.ScaledLevel ~= nil then
    TestModeArgs.ScaledLevel = {
      type = 'range',
      name = 'Scaled Level',
      order = 106,
      desc = 'Change the bars scaled level',
      step = 1,
      width = 'full',
      min = o.TestModeUnitLevelMin,
      max = o.TestModeUnitLevelMax,
    }
  end
  if UBD.TestMode.BloodSpec ~= nil then
    TestModeArgs.DeathKnightSpecGroup = {
      type = 'group',
      name = '',
      order = 200,
      args = {
        BloodSpec = {
          type = 'toggle',
          name = 'Blood',
          width = 'half',
          order = 1,
        },
        FrostSpec = {
          type = 'toggle',
          name = 'Frost',
          width = 'half',
          order = 2,
        },
        UnHolySpec = {
          type = 'toggle',
          name = 'Unholy',
          width = 'half',
          order = 3,
        },
      },
    }
  end
  if UBD.TestMode.RuneTime ~= nil then
    TestModeArgs.RuneTime = {
      type = 'range',
      name = 'Time',
      order = 201,
      desc = '',
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.RuneOnCooldown ~= nil then
    TestModeArgs.RuneOnCooldown = {
      type = 'range',
      name = 'On Cooldown',
      order = 202,
      desc = 'Set which rune is on cooldown, max for all',
      width = 'full',
      step = 1,
      min = o.TestModeOnCooldownMin,
      max = o.TestModeOnCooldownMax,
    }
  end
  if UBD.TestMode.SoulShards ~= nil then
    TestModeArgs.SoulShards = {
      type = 'range',
      name = 'Shards',
      order = 300,
      desc = 'Change how many shards are lit',
      width = 'full',
      step = 1,
      min = o.TestModeShardMin,
      max = o.TestModeShardMax,
    }
  end
  -- Fragement bar
  if UBD.TestMode.ShowFull ~= nil then
    TestModeArgs.ShowFull = {
      type = 'toggle',
      name = 'Show Full',
      order = 300,
    }
  end
  if UBD.TestMode.ShardFragments ~= nil then
    TestModeArgs.ShardFragments = {
      type = 'range',
      name = 'Shard Fragments',
      order = 301,
      desc = 'Change how many shards are filled',
      width = 'full',
      step = 1,
      min = o.TestModeShardFragmentMin,
      max = o.TestModeShardFragmentMax,
    }
  end
  if UBD.TestMode.HolyPower ~= nil then
    TestModeArgs.HolyPower = {
      type = 'range',
      name = 'Holy Power',
      order = 400,
      desc = 'Change how many holy runes are lit',
      width = 'full',
      step = 1,
      min = o.TestModeHolyPowerMin,
      max = o.TestModeHolyPowerMax,
    }
  end
  if UBD.TestMode.Ascension ~= nil then
    TestModeArgs.Ascension = {
      type = 'toggle',
      name = 'Ascension',
      order = 500,
    }
  end
  if UBD.TestMode.Chi ~= nil then
    TestModeArgs.Chi = {
      type = 'range',
      name = 'Chi',
      order = 501,
      desc = 'Change how many chi orbs are lit',
      width = 'full',
      step = 1,
      min = o.TestModeChiMin,
      max = o.TestModeChiMax,
    }
  end
  if UBD.TestMode.DeeperStratagem ~= nil then
    TestModeArgs.DeeperStratagem = {
      type = 'toggle',
      name = 'Deeper Stratagem',
      order = 600,
    }
  end
  if UBD.TestMode.Anticipation ~= nil then
    TestModeArgs.Anticipation = {
      type = 'toggle',
      name = 'Anticipation',
      order = 601,
    }
  end
  if UBD.TestMode.ComboPoints ~= nil then
    TestModeArgs.ComboPoints = {
      type = 'range',
      name = 'Combo Points',
      order = 602,
      desc = 'Change how many combo points are lit',
      width = 'full',
      step = 1,
      min = o.TestModePointsMin,
      max = o.TestModePointsMax,
    }
  end
  if UBD.TestMode.ArcaneCharges ~= nil then
    TestModeArgs.ArcaneCharges = {
      type = 'range',
      name = 'Arcane Charges',
      order = 700,
      desc = 'Change how many arcane charges are lit',
      width = 'full',
      step = 1,
      min = o.TestModeArcaneChargesMin,
      max = o.TestModeArcaneChargesMax,
    }
  end
  if UBD.TestMode.StaggerPercent ~= nil then
    TestModeArgs.StaggerPercent = {
      type = 'range',
      name = 'Stagger',
      order = 800,
      step = .01,
      width = 'full',
      isPercent = true,
      min = o.TestModeStaggerMin,
      max = o.TestModeStaggerMax,
    }
  end
  if UBD.TestMode.StaggerPause ~= nil then
    TestModeArgs.StaggerPause = {
      type = 'range',
      name = 'Pause (seconds)',
      order = 801,
      step = .1,
      width = 'full',
      min = o.TestModeStaggerPauseMin,
      max = o.TestModeStaggerPauseMax,
    }
  end
  if UBD.TestMode.AltTypePower ~= nil then
    TestModeArgs.AltTypePower = {
      type = 'toggle',
      name = 'Power',
      order = 900,
      width = 'half',
      disabled = function()
                   return UBF.UnitBar.TestMode.AltTypeBoth
                 end,
    }
  end
  if UBD.TestMode.AltTypeCounter ~= nil then
    TestModeArgs.AltTypeCounter = {
      type = 'toggle',
      name = 'Counter',
      order = 901,
      width = 'half',
      disabled = function()
                   return UBF.UnitBar.TestMode.AltTypeBoth
                 end,
    }
  end
  if UBD.TestMode.AltTypeBoth ~= nil then
    TestModeArgs.AltTypeBoth = {
      type = 'toggle',
      name = 'Show Both',
      order = 902,
      desc = 'Lets you compare side by side, normally only one is visible'
    }
  end
  if UBD.TestMode.BothRotation ~= nil then
    TestModeArgs.BothRotation = {
      type = 'range',
      name = 'Rotation',
      order = 903,
      desc = 'Changes the orientation of the bar objects',
      step = 45,
      hidden = function()
                 return not UBF.UnitBar.TestMode.AltTypeBoth
               end,
      min = o.LayoutRotationMin,
      max = o.LayoutRotationMax,
    }
  end
  if UBD.TestMode.AltPowerName ~= nil then
    TestModeArgs.AltPowerName = {
      type = 'input',
      name = 'Power Name',
      order = 904,
    }
  end
  if UBD.TestMode.AltPower ~= nil then
    TestModeArgs.AltPower = {
      type = 'range',
      name = 'Alternate Power',
      order = 905,
      step = 1,
      width = 'full',
      min = o.TestModeAltPowerMin,
      max = o.TestModeAltPowerMax,
    }
  end
  if UBD.TestMode.AltPowerMax ~= nil then
    TestModeArgs.AltPowerMax = {
      type = 'range',
      name = 'Alternate Power Max',
      order = 906,
      step = 1,
      width = 'full',
      min = o.TestModeAltMaxPowerMin,
      max = o.TestModeAltMaxPowerMax,
    }
  end
  if UBD.TestMode.AltPowerBarID ~= nil then
    TestModeArgs.AltPowerBarID = {
      type = 'range',
      name = 'Alternate Power Bar ID',
      order = 907,
      step = 1,
      width = 'full',
      min = o.TestModeAltPowerBarIDMin,
      max = o.TestModeAltPowerBarIDMax,
    }
  end
  if UBD.TestMode.AltPowerTime ~= nil then
    TestModeArgs.AltPowerTime = {
      type = 'range',
      name = 'Alternate Power Time (counter only)',
      order = 908,
      step = 1,
      width = 'full',
      min = o.TestModeAltPowerTimeMin,
      max = o.TestModeAltPowerTimeMax,
      disabled = function()
                   local TestMode = UBF.UnitBar.TestMode
                   return TestMode.AltTypePower and not TestMode.AltTypeBoth
                 end,
    }
  end

  return TestModeOptions
end

-------------------------------------------------------------------------------
-- CreateMoreLayoutRuneBarOptions
--
-- Creates additional options that appear under layout for the rune bar.
--
-- Subfunction of CreateLayoutOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-------------------------------------------------------------------------------
local function CreateMoreLayoutRuneBarOptions(BarType, Order)
  local UBF = UnitBarsF[BarType]

  local MoreLayoutRuneBarOptions = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Layout[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            UBF.UnitBar.Layout[KeyName] = Value

            -- Update the layout to show changes.
            UBF:SetAttr('Layout', KeyName)
          end,
    args = {
      RuneMode = {
        type = 'select',
        name = 'Rune Mode',
        order = 1,
        desc = 'Select the way runes are shown',
        values = RuneModeDropdown,
        style = 'dropdown',
      },
      Spacer20 = CreateSpacer(20),
      CooldownAnimation = {
        type = 'toggle',
        name = 'Cooldown Animation',
        order = 21,
        hidden = function()
                   return strfind(UBF.UnitBar.Layout.RuneMode, 'rune') == nil
                 end,
        desc = 'Shows the cooldown animation',
      },
      CooldownFlash = {
        type = 'toggle',
        name = 'Cooldown Flash',
        order = 22,
        hidden = function()
                   return strfind(UBF.UnitBar.Layout.RuneMode, 'rune') == nil
                 end,
        disabled = function()
                     return not UBF.UnitBar.Layout.CooldownAnimation
                   end,
        desc = 'Shows the flash animation after a rune comes off cooldown',
      },
      Spacer30 = CreateSpacer(30),
      BarSpark = {
        type = 'toggle',
        name = 'Bar Spark',
        order = 31,
        hidden = function()
                   return UBF.UnitBar.Layout.RuneMode == 'rune'
                 end,
        desc = 'Shows a spark on the bar animation',
      },
      CooldownLine = {
        type = 'toggle',
        name = 'Cooldown Line',
        order = 32,
        hidden = function()
                   return strfind(UBF.UnitBar.Layout.RuneMode, 'rune') == nil
                 end,
        disabled = function()
                     return not UBF.UnitBar.Layout.CooldownAnimation
                   end,
        desc = 'Shows a line on the cooldown animation',
      },
      RuneLocation = {
        type = 'group',
        name = 'Rune Location',
        dialogInline = true,
        order = 32,
        set = function(Info, Value)
                UBF.UnitBar.Layout[Info[#Info]] = Value

                -- Update the rune location.
                UBF:SetAttr('Layout', '_RuneLocation')
              end,
        hidden = function()
                   return UBF.UnitBar.Layout.RuneMode ~= 'runebar'
                 end,
        args = {
          RuneOffsetX = {
            type = 'range',
            name = 'Horizontal Offset',
            order = 1,
            min = o.RuneOffsetXMin,
            max = o.RuneOffsetYMax,
            step = 1,
          },
          RuneOffsetY = {
            type = 'range',
            name = 'Vertical Offset',
            order = 2,
            min = o.RuneOffsetYMin,
            max = o.RuneOffsetYMax,
            step = 1,
          },
          RunePosition = {
            type = 'select',
            name = 'Rune Position',
            order = 3,
            values = PositionDropdown,
            style = 'dropdown',
            desc = 'Position of the rune around the cooldown bar'
          },
        },
      },
    },
  }
  return MoreLayoutRuneBarOptions
end

-------------------------------------------------------------------------------
-- CreateMoreLayoutStaggerBarOptions
--
-- Creates additional options that appear under layout for the stagger bar.
--
-- Subfunction of CreateLayoutOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-------------------------------------------------------------------------------
local function CreateMoreLayoutStaggerBarOptions(BarType, Order)
  local UBF = UnitBarsF[BarType]

  local MoreLayoutStaggerBarOptions = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Layout[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            UBF.UnitBar.Layout[KeyName] = Value

            -- Update the layout to show changes.
            UBF:SetAttr('Layout', KeyName)
          end,
    args = {
      Layered = {
        type = 'toggle',
        name = 'Layered',
        order = 1,
        desc = 'When the main stagger bar is full, it will be hidden while the second bar fills. Bar will have new options when this is active',
        disabled = function()
                     return UBF.UnitBar.Layout.SideBySide
                   end,
      },
      Overlay = {
        type = 'toggle',
        name = 'Overlay',
        order = 2,
        desc = 'When the main stagger bar is full it will remain visible while the second bar fills',
        disabled = function()
                     return UBF.UnitBar.Layout.SideBySide or not UBF.UnitBar.Layout.Layered
                   end,
      },
      SideBySide = {
        type = 'toggle',
        name = 'Side by Side',
        order = 3,
        desc = 'Main stagger and second bar is merged as one. Bar will have new options when this is active',
        disabled = function()
                     return UBF.UnitBar.Layout.Layered
                   end,
      },
      Spacer10 = CreateSpacer(10),
      PauseTimer = {
        type = 'toggle',
        name = 'Pause Timer',
        order = 11,
        desc = 'Displays a bar for when stagger gets paused',
      },
      PauseTimerAutoHide = {
        type = 'toggle',
        name = 'Pause Timer Autohide',
        order = 12,
        desc = "Hides the Pause Timer after it's finished",
        disabled = function()
                     return not UBF.UnitBar.Layout.PauseTimer
                   end
      },
    },
  }
  return MoreLayoutStaggerBarOptions
end

-------------------------------------------------------------------------------
-- CreateMoreLayoutAltPowerBarOptions
--
-- Creates additional options that appear under layout for the alternate power bar.
--
-- Subfunction of CreateLayoutOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-------------------------------------------------------------------------------
local function CreateMoreLayoutAltPowerBarOptions(BarType, Order)
  local UBF = UnitBarsF[BarType]

  local MoreLayoutAltPowerBarOptions = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Layout[Info[#Info] ]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            UBF.UnitBar.Layout[KeyName] = Value

            -- Update the layout to show changes.
            UBF:SetAttr('Layout', KeyName)
          end,
    args = {
      UseBarColor = {
        type = 'toggle',
        name = 'Use Bar Color',
        order = 1,
        desc = 'Use bar color instead of alternate power color. Testmode always uses bar color',
      },
    },
  }

  return MoreLayoutAltPowerBarOptions
end

-------------------------------------------------------------------------------
-- CreateMoreLayoutOptions
--
-- Subfunction of CreateLayoutOptions
--
-- Creates additional options that appear in the layout. Not all bars use this.
--
-- BarType     Type of bar options being craeted for.
-- Order       Where to place options on screen.
-------------------------------------------------------------------------------
local function CreateMoreLayoutOptions(BarType, Order)
  local UBF = UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local MoreLayoutOptions = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Layout[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local Layout = UBF.UnitBar.Layout

            if KeyName == 'ClassColor' and Value then
              Layout.CombatColor = false
            elseif KeyName == 'CombatColor' and Value then
              Layout.ClassColor = false
            end

            Layout[KeyName] = Value
            UBF:SetAttr('Layout', KeyName)
          end,
    args = {}
  }

  local MoreLayoutArgs = MoreLayoutOptions.args

  -- Health and power bar options.
  if UBD.Layout.UseBarColor ~= nil then
    MoreLayoutArgs.UseBarColor = {
      type = 'toggle',
      name = 'Use Bar Color',
      order = 1,
      desc = 'Use bar color instead of power color',
    }
  end
  if UBD.Layout.PredictedHealth ~= nil then
    MoreLayoutArgs.PredictedHealth = {
      type = 'toggle',
      name = 'Predicted Health',
      order = 2,
      desc = 'Predicted health will be shown',
    }
  end
  if UBD.Layout.AbsorbHealth ~= nil then
    MoreLayoutArgs.AbsorbHealth = {
      type = 'toggle',
      name = 'Absorb Health',
      desc = 'Shows how much health in absorbs you have left',
      order = 3,
      desc = 'Absorb health will be shown',
    }
  end
  if UBD.Layout.PredictedPower ~= nil then
    MoreLayoutArgs.PredictedPower = {
      type = 'toggle',
      name = 'Predicted Power',
      order = 4,
      desc = 'Show predicted power of spells that return power with a cast time',
    }
  end
  if UBD.Layout.PredictedCost ~= nil then
    MoreLayoutArgs.PredictedCost = {
      type = 'toggle',
      name = 'Predicted Cost',
      order = 6,
      desc = 'Show predicted cost of spells that cost power with a cast time',
    }
  end
  if UBD.Layout.ClassColor ~= nil then
    MoreLayoutArgs.ClassColor = {
      type = 'toggle',
      name = 'Class Color',
      order = 6,
      desc = 'Show class color',
    }
  end
  if UBD.Layout.CombatColor ~= nil then
    MoreLayoutArgs.CombatColor = {
      type = 'toggle',
      name = 'Combat Color',
      order = 7,
      desc = 'Show combat color',
    }
  end
  if UBD.Layout.TaggedColor ~= nil then
    MoreLayoutArgs.TaggedColor = {
      type = 'toggle',
      name = 'Tagged Color',
      order = 8,
      desc = 'Shows if the target is tagged by another player',
    }
  end
  if UBD.Layout.TextureScaleCombo ~= nil then
    MoreLayoutArgs.TextureScaleCombo = {
      type = 'range',
      name = 'Texture Scale (Combo)',
      order = 9,
      desc = 'Changes the texture size of the combo point objects',
      step = 0.01,
      isPercent = true,
      disabled = function()
                   return Flag(true, UBF.UnitBar.Layout.BoxMode)
                 end,
      min = o.LayoutTextureScaleMin,
      max = o.LayoutTextureScaleMax,
    }
  end
  if UBD.Layout.TextureScaleAnticipation ~= nil then
    MoreLayoutArgs.TextureScaleAnticipation = {
      type = 'range',
      name = 'Texture Scale (Anticipation)',
      order = 10,
      desc = 'Changes the texture size of the anticipation point objects',
      step = 0.01,
      isPercent = true,
      disabled = function()
                   return Flag(true, UBF.UnitBar.Layout.BoxMode)
                 end,
      min = o.LayoutTextureScaleMin,
      max = o.LayoutTextureScaleMax,
    }
  end
  if UBD.Layout.InactiveAnticipationAlpha ~= nil then
    MoreLayoutArgs.InactiveAnticipationAlpha = {
      type = 'range',
      name = 'Inactive Anticipation Alpha',
      order = 11,
      desc = 'Changes the transparency of inactive anticipation points',
      min = 0,
      max = 1,
      step = 0.01,
      isPercent = true,
    }
  end
  if UBD.Layout.BurningEmbers ~= nil then
    MoreLayoutArgs.BurningEmbers = {
      type = 'toggle',
      name = 'Burning Embers',
      order = 12,
      desc = 'Changes the shards into burning embers',
    }
  end
  if UBD.Layout.GreenFire ~= nil then
    MoreLayoutArgs.GreenFire = {
      type = 'toggle',
      name = 'Green Fire',
      order = 13,
      desc = 'Use green fire',
      disabled = function()
                   return UBF.UnitBar.Layout.GreenFireAuto
                 end,
    }
  end
  if UBD.Layout.GreenFireAuto ~= nil then
    MoreLayoutArgs.GreenFireAuto = {
      type = 'toggle',
      name = 'Green Fire Auto',
      order = 14,
      desc = 'Use green fire if available',
      disabled = function()
                   return UBF.UnitBar.Layout.GreenFire
                 end,
    }
  end

  return MoreLayoutOptions
end

-------------------------------------------------------------------------------
-- CreateLayoutOptions
--
-- Subfunction of CreateUnitBarOptions
--
-- BarType       The options being created for.
-- Order         Where the options appear on screen.
-- Name          Name of the options.
-------------------------------------------------------------------------------
local function CreateLayoutOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local LayoutOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {
      General = {
        type = 'group',
        name = 'General',
        dialogInline = true,
        order = 2,
        get = function(Info)
                return UBF.UnitBar.Layout[Info[#Info]]
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]

                if KeyName == 'Swap' and Value then
                  UBF.UnitBar.Layout.Align = false
                  UBF:SetAttr('Layout', 'Align')
                elseif KeyName == 'Align' and Value then
                  UBF.UnitBar.Layout.Swap = false
                  UBF:SetAttr('Layout', 'Swap')
                end
                UBF.UnitBar.Layout[KeyName] = Value

                if KeyName == 'HideText' then

                  -- Update any text highlights.  We use 'on' since its always on when options are opened.
                  Bar:SetHighlightFont('on', Main.UnitBars.HideTextHighlight)
                end

                -- Update the layout to show changes.
                UBF:SetAttr('Layout', KeyName)

                -- Create triggers only after layout has been set.
                if KeyName == 'EnableTriggers' and Value then
                  Options:DoFunction(BarType, 'CreateTriggerOptions')
                end
              end,
        args = {},
      },
    },
  }

  -- Create test mode options.
  if UBD.TestMode ~= nil then
    LayoutOptions.args.TestMode = CreateTestModeOptions(BarType, 1, 'Test Mode')
  end

  local GeneralArgs = LayoutOptions.args.General.args
  local Spacer = false

  -- Create more layout options.
  if UBD.Layout._More then
    if BarType == 'RuneBar' then
      GeneralArgs.MoreLayout = CreateMoreLayoutRuneBarOptions(BarType, 1)
    elseif BarType == 'StaggerBar' then
      GeneralArgs.MoreLayout = CreateMoreLayoutStaggerBarOptions(BarType, 1)
    elseif BarType == 'AltPowerBar' then
      GeneralArgs.MoreLayout = CreateMoreLayoutAltPowerBarOptions(BarType, 1)
    else
      GeneralArgs.MoreLayout = CreateMoreLayoutOptions(BarType, 1)
    end
    -- Delete more layout if it has no options.
    if next(GeneralArgs.MoreLayout.args) == nil then
      GeneralArgs.MoreLayout = nil
      GeneralArgs.Seperator = nil
    else
      -- Create seperator line
      GeneralArgs.Seperator = {
        type = 'header',
        name = '',
        order = 2,
      }
    end
  end

  if UBD.Layout.BoxMode ~= nil then
    Spacer = true
    GeneralArgs.BoxMode = {
      type = 'toggle',
      name = 'Box Mode',
      order = 10,
      desc = 'Switches from texture mode to box mode',
    }
  end
  if Spacer then
    GeneralArgs.Spacer11 = CreateSpacer(11)
    Spacer = false
  end

  if UBD.Layout.EnableTriggers ~= nil then
    Spacer = true
    GeneralArgs.EnableTriggers = {
      type = 'toggle',
      name = 'Enable Triggers',
      order = 12,
      desc = 'Acitvates all triggers for this bar and shows the trigger options',
    }
  end
  if UBD.Layout.HideRegion ~= nil then
    Spacer = true
    GeneralArgs.HideRegion = {
      type = 'toggle',
      name = 'Hide Region',
      order = 13,
      desc = "Hides the bar's region",
    }
  end
  if Spacer then
    GeneralArgs.Spacer20 = CreateSpacer(20)
    Spacer = false
  end

  if UBD.Layout.ReverseFill ~= nil then
    Spacer = true
    GeneralArgs.ReverseFill = {
      type = 'toggle',
      name = 'Reverse fill',
      order = 21,
      desc = 'Fill in reverse',
    }
  end
  if UBD.Layout.HideText ~= nil then
    Spacer = true
    GeneralArgs.HideText = {
      type = 'toggle',
      name = 'Hide Text',
      order = 22,
      desc = 'Hides all text',
    }
  end

  if BarType == 'StaggerBar' or BarType == 'AltPowerBar' then
    Spacer = true

    if BarType == 'StaggerBar' then
      GeneralArgs.HideTextPause = {
        type = 'toggle',
        name = 'Hide Text (pause)',
        order = 23,
        desc = 'Hides all text on the pause timer',
        disabled = function()
                     return not UBF.UnitBar.Layout.PauseTimer
                   end,
      }
    else
      GeneralArgs.HideTextCounter = {
        type = 'toggle',
        name = 'Hide Text (counter)',
        order = 23,
        desc = 'Hides all text on the counter bar',
      }
    end
  end

  if Spacer then
    GeneralArgs.Spacer30 = CreateSpacer(30)
    Spacer = false
  end

  if UBD.Layout.FillDirection ~= nil then
    Spacer = true
    GeneralArgs.FillDirection = {
      type = 'select',
      name = 'Fill Direction',
      order = 31,
      values = DirectionDropdown,
      style = 'dropdown',
    }
    if BarType == 'FragmentBar' then
      local FillDirection = GeneralArgs.FillDirection
      FillDirection.name = 'Fill Direction (texture mode)'
      FillDirection.disabled = function()
                                 return UBF.UnitBar.Layout.BoxMode
                               end
    end
  end
  if Spacer then
    GeneralArgs.Spacer40 = CreateSpacer(40)
    Spacer = false
  end

  if UBD.Layout.SmoothFillMaxTime ~= nil then
    Spacer = true
    GeneralArgs.SmoothFillMaxTime = {
      type = 'range',
      name = 'Smooth Fill Max Time',
      order = 41,
      desc = 'Sets the maximum amount of time in seconds a smooth fill can take',
      step = 0.01,
      min = o.LayoutSmoothFillMaxTimeMin,
      max = o.LayoutSmoothFillMaxTimeMax,
    }
    GeneralArgs.SmoothFillSpeed = {
      type = 'range',
      name = 'Smooth Fill Speed',
      order = 42,
      desc = 'Changes the fill animaton speed',
      step = 0.01,
      isPercent = true,
      disabled = function()
                   return UBF.UnitBar.Layout.SmoothFillMaxTime == 0
                 end,
      min = o.LayoutSmoothFillSpeedMin,
      max = o.LayoutSmoothFillSpeedMax,
    }
  end

  if Spacer then
    GeneralArgs.Spacer80 = CreateSpacer(80)
    Spacer = false
  end

  -------------------------
  -- Create objects options
  -------------------------
  GeneralArgs.Objects = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = 81,
    hidden = function()
               if BarType == 'StaggerBar' then
                 return not UBF.UnitBar.Layout.PauseTimer
               else
                 return false
               end
             end,
    args = {},
  }
  local ObjectsArgs = GeneralArgs.Objects.args
  local ObjectsFlag = false

  -- Create seperator line
  ObjectsArgs.Seperator = {
    type = 'header',
    name = '',
    order = 0,
  }

  if UBD.Layout.Swap ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Swap = {
      type = 'toggle',
      name = 'Swap',
      order = 1,
      desc = 'Allows you to swap one bar object with another by dragging it',
    }
  end
  if UBD.Layout.Float ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Float = {
      type = 'toggle',
      name = 'Float',
      order = 2,
      desc = 'Switches to floating mode.  Bar objects can be placed anywhere. Float options will be open below',
    }
  end

  if UBD.Layout.AnimationType ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Spacer10 = CreateSpacer(10)

    ObjectsArgs.AnimationType = {
      type = 'select',
      name = BarType ~= 'FragmentBar' and 'Animation Type' or 'Animation Type (full)',
      order = 11,
      style = 'dropdown',
      desc = 'Changes the type of animation played when showing or hiding bar objects',
      values = AnimationTypeDropdown,
    }
  end
  if Spacer then
    ObjectsArgs.Spacer20 = CreateSpacer(20)
    Spacer = false
  end

  if UBD.Layout.BorderPadding ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.BorderPadding = {
      type = 'range',
      name = 'Border Padding',
      order = 21,
      desc = "Changes the distance between the region's border and the bar objects",
      step = 1,
      disabled = function()
                   return UBF.UnitBar.Layout.HideRegion
                 end,
      min = o.LayoutBorderPaddingMin,
      max = o.LayoutBorderPaddingMax,
    }
  end

  if UBD.Layout.Rotation ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Rotation = {
      type = 'range',
      name = 'Rotation',
      order = 22,
      desc = 'Changes the orientation of the bar objects',
      step = 45,
      disabled = function()
                   return Flag(false, UBF.UnitBar.Layout.Float)
                 end,
      min = o.LayoutRotationMin,
      max = o.LayoutRotationMax,
    }
  end
  if Spacer then
    ObjectsArgs.Spacer30 = CreateSpacer(30)
    Spacer = false
  end

  if UBD.Layout.Slope ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Slope = {
      type = 'range',
      name = 'Slope',
      order = 31,
      desc = 'Makes the bar objects slope up or down when the rotation is horizontal or vertical',
      step = 1,
      disabled = function()
                   return Flag(false, UBF.UnitBar.Layout.Float) or UBF.UnitBar.Layout.Rotation % 90 ~= 0
                 end,
      min = o.LayoutSlopeMin,
      max = o.LayoutSlopeMax,
    }
  end
  if UBD.Layout.Padding ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Padding = {
      type = 'range',
      name = 'Padding',
      order = 32,
      desc = 'Changes the space between each bar object',
      step = 1,
      disabled = function()
                   return Flag(false, UBF.UnitBar.Layout.Float)
                 end,
      min = o.LayoutPaddingMin,
      max = o.LayoutPaddingMax,
    }
  end
  if Spacer then
    ObjectsArgs.Spacer40 = CreateSpacer(40)
    Spacer = false
  end

  if UBD.Layout.TextureScale ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.TextureScale = {
      type = 'range',
      name = 'Texture Scale',
      order = 41,
      desc = 'Changes the texture size of the bar objects',
      step = 0.01,
      isPercent = true,
      disabled = function()
                   return BarType ~= 'RuneBar' and Flag(true, UBF.UnitBar.Layout.BoxMode) or
                          BarType == 'RuneBar' and strsub(UBF.UnitBar.Layout.RuneMode, 1, 4) ~= 'rune'
                 end,
      min = o.LayoutTextureScaleMin,
      max = o.LayoutTextureScaleMax,
    }
  end
  if Spacer then
    ObjectsArgs.Spacer50 = CreateSpacer(50)
    Spacer = false
  end

  if UBD.Layout.AnimationInTime ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.AnimationInTime = {
      type = 'range',
      name = BarType ~= 'FragmentBar' and 'Animation-in' or 'Animation-in (full)',
      order = 51,
      desc = 'The amount of time in seconds to play animation after showing a bar object',
      step = 0.1,
      min = o.LayoutAnimationInTimeMin,
      max = o.LayoutAnimationInTimeMax,
    }
  end
  if UBD.Layout.AnimationOutTime ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.AnimationOutTime = {
      type = 'range',
      name = BarType ~= 'FragmentBar' and 'Animation-out' or 'Animation-out (full)',
      order = 52,
      desc = 'The amount of time in seconds to play animation after showing a bar object',
      step = 0.1,
      min = o.LayoutAnimationOutTimeMin,
      max = o.LayoutAnimationOutTimeMax,
    }
  end
  if Spacer then
    ObjectsArgs.Spacer60 = CreateSpacer(60)
    Spacer = false
  end

  -- Float options
  if UBD.Layout.Float ~= nil then
    ObjectsFlag = true
    ObjectsArgs.FloatOptions = {
      type = 'group',
      name = 'Float Options',
      dialogInline = true,
      order = 101,
      hidden = function()
                 return not UBF.UnitBar.Layout.Float
               end,
      args = {
        Align = {
          type = 'toggle',
          name = 'Align',
          order = 1,
          desc = 'When a bar object is dragged near another it will align its self to it',
        },
        AlignGroup = {
          type = 'group',
          name = 'Align',
          dialogInline = true,
          order = 2,
          hidden = function()
                     return not UBF.UnitBar.Layout.Align
                   end,
          args = {
            Spacer10 = CreateSpacer(10),
            AlignPaddingX = {
              type = 'range',
              name = 'Padding Horizontal',
              order = 11,
              desc = 'Sets the distance between two or more bar objects that are aligned horizontally',
              step = 1,
              min = o.LayoutAlignPaddingXMin,
              max = o.LayoutAlignPaddingXMax,
            },
            AlignPaddingY = {
              type = 'range',
              name = 'Padding Vertical',
              order = 12,
              desc = 'Sets the distance between two or more bar objects that are aligned vertically',
              step = 1,
              min = o.LayoutAlignPaddingXMin,
              max = o.LayoutAlignPaddingXMax,
            },
            Spacer20 = CreateSpacer(20),
            AlignOffsetX = {
              type = 'range',
              name = 'Horizontal Offset',
              order = 21,
              desc = 'Offsets the padding group',
              step = 1,
              min = o.LayoutAlignOffsetXMin,
              max = o.LayoutAlignOffsetXMax,
            },
            AlignOffsetY = {
              type = 'range',
              name = 'Vertical Offset',
              order = 22,
              desc = 'Offsets the padding group',
              step = 1,
              min = o.LayoutAlignOffsetYMin,
              max = o.LayoutAlignOffsetYMax,
            },
          },
        },
      },
    }
    if UBF.UnitBar.Layout.Float ~= nil then
      local FloatArgs = ObjectsArgs.FloatOptions.args

      ObjectsFlag = true
      FloatArgs.Spacer30 = CreateSpacer(30)
      FloatArgs.ResetFloat = {
        type = 'execute',
        name = 'Copy Layout',
        order = 3,
        desc = 'Copy the normal mode layout to float',
        confirm = true,
        disabled = function()
                     return not UBF.UnitBar.Layout.Float
                   end,
        func = function()
                 UBF.BBar:CopyLayoutFloatBar()
                 UBF.BBar:Display()
               end
      }
    end
  end
  if not ObjectsFlag then
    GeneralArgs.Objects = nil
  end

  return LayoutOptions
end

-------------------------------------------------------------------------------
-- CreateResetOptions
--
-- SubFunction of CreateOtherOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
--
-- NOTES:  Reset options are created here and saved into defaults.
--         This way I don't have to maintain two sets of lists.
--         TablePath must lead to a table only if its more than one level deep.
-------------------------------------------------------------------------------
local function CreateResetOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
  local UBD = DUB[BarType]
  local ResetList = {}

  TableData = TableData or { -- For keynames, only the first one has to exist.
    All                       = { Name = 'All',                  Order =   1, Width = 'half' },
    Location                  = { Name = 'Location',             Order =   2, Width = 'half',   TablePaths = {'x', 'y'} },
    Specialization            = { Name = 'Spec',                 Order =   3, Width = 'half',   TablePaths = {'ClassSpecs'} },
    Status                    = { Name = 'Status',               Order =   4, Width = 'half',   TablePaths = {'Status'} },
    Test                      = { Name = 'Test',                 Order =   5, Width = 'half',   TablePaths = {'TestMode'} },
    Layout                    = { Name = 'Layout',               Order =   6, Width = 'half',   TablePaths = {'Layout', 'BoxLocations', 'BoxOrder'} },
    Region                    = { Name = 'Region',               Order =   7, Width = 'half',   TablePaths = {'Region'} },
    Text                      = { Name = 'Text',                 Order =   8, Width = 'half',   TablePaths = {'Text'} },
    TextPause                 = { Name = 'Text (pause)',         Order =   9, Width = 'normal', BarType = 'StaggerBar',  TablePaths = {'Text2'} },
    TextCounter               = { Name = 'Text (counter)',       Order =  10, Width = 'normal', BarType = 'AltPowerBar', TablePaths = {'Text2'} },
    Triggers                  = { Name = 'Triggers',             Order =  11, Width = 'half',   TablePaths = {'Triggers'} },
    Attributes                = { Name = 'Attributes',           Order =  12, Width = 'normal', TablePaths = {'Attributes'} },
    --------------------------
    HEADER2 = { Order = 100, Name = 'Background' },

    BG                        = { Name = 'Background',           Order = 101, Width = 'wide',   TablePaths = {'Background'} },
    BGCombo                   = { Name = 'Combo',                Order = 102, Width = 'wide',   TablePaths = {'BackgroundCombo'} },
    BGAnticipation            = { Name = 'Anticipation',         Order = 103, Width = 'wide',   TablePaths = {'BackgroundAnticipation'} },

    BGShard                   = { Name = 'Shard',                Order = 104, Width = 'wide',   TablePaths = {'BackgroundShard'} },
    BGEmber                   = { Name = 'Ember',                Order = 105, Width = 'wide',   TablePaths = {'BackgroundEmber'} },

    BGStagger                 = { Name = 'Stagger',              Order = 106, Width = 'wide',   TablePaths = {'BackgroundStagger'} },
    BGPause                   = { Name = 'Pause',                Order = 107, Width = 'wide',   TablePaths = {'BackgroundPause'} },

    BGAltPower                = { Name = 'Power',                Order = 108, Width = 'wide',   TablePaths = {'BackgroundPower'} },
    BGAltCounter              = { Name = 'Counter',              Order = 109, Width = 'wide',   TablePaths = {'BackgroundCounter'} },
    --------------------------
    HEADER3 = { Order = 200, Name = 'Bar' },

    Bar                       = { Name = 'Bar',                  Order = 201, Width = 'wide',   TablePaths = {'Bar'} },
    BarCombo                  = { Name = 'Combo',                Order = 202, Width = 'wide',   TablePaths = {'BarCombo'} },
    BarAnticipation           = { Name = 'Anticipation',         Order = 203, Width = 'wide',   TablePaths = {'BarAnticipation'} },

    BarShard                  = { Name = 'Shard',                Order = 204, Width = 'wide',   TablePaths = {'BarShard'} },
    BarEmber                  = { Name = 'Ember',                Order = 205, Width = 'wide',   TablePaths = {'BarEmber'} },

    BarStagger                = { Name = 'Stagger',              Order = 206, Width = 'wide',   TablePaths = {'BarStagger'} },
    BarPause                  = { Name = 'Pause',                Order = 207, Width = 'wide',   TablePaths = {'BarPause'} },

    BarAltPower               = { Name = 'Power',                Order = 208, Width = 'wide',   TablePaths = {'BarPower'} },
    BarAltCounter             = { Name = 'Counter',              Order = 209, Width = 'wide',   TablePaths = {'BarCounter'} },
    --------------------------
    HEADER1 = { Order = 300, Name = 'Region Color', CheckTable = 'Region.Color' },

    RegionColorBG             = { Name = 'Background',           Order = 301, Width = 'wide',   TablePaths = {'Region.Color'} },
    RegionBorderColor         = { Name = 'Border',               Order = 302, Width = 'wide',   TablePaths = {'Region.BorderColor'} },
    --------------------------
    HEADER5 = { Order = 400, Name = 'Background Color' },

    BGColor                   = { Name = 'Background Color',     Order = 401, Width = 'wide',   TablePaths = {'Background.Color'} },
    BGBorderColor             = { Name = 'Border Color',         Order = 401, Width = 'wide',   TablePaths = {'Background.BorderColor'} },

    BGColorCombo              = { Name = 'Combo',                Order = 402, Width = 'wide',   TablePaths = {'BackgroundCombo.Color'} },
    BGColorAnticipation       = { Name = 'Anticipation',         Order = 403, Width = 'wide',   TablePaths = {'BackgroundAnticipation.Color'} },
    BGBorderColorCombo        = { Name = 'Combo Border',         Order = 404, Width = 'wide',   TablePaths = {'BackgroundCombo.BorderColor'} },
    BGBorderColorAnticipation = { Name = 'Anticipation Border',  Order = 405, Width = 'wide',   TablePaths = {'BackgroundAnticipation.BorderColor'} },

    BGColorShard              = { Name = 'Shard',                Order = 406, Width = 'wide',   TablePaths = {'BackgroundShard.Color'} },
    BGColorEmber              = { Name = 'Ember',                Order = 407, Width = 'wide',   TablePaths = {'BackgroundEmber.Color'} },
    BGBorderColorShard        = { Name = 'Shard Border',         Order = 408, Width = 'wide',   TablePaths = {'BackgroundShard.BorderColor'} },
    BGBorderColorEmber        = { Name = 'Ember Border',         Order = 409, Width = 'wide',   TablePaths = {'BackgroundEmber.BorderColor'} },
    BGColorShardGreen         = { Name = 'Shard [Green]',        Order = 410, Width = 'wide',   TablePaths = {'BackgroundShard.ColorGreen'} },
    BGColorEmberGreen         = { Name = 'Ember [Green]',        Order = 411, Width = 'wide',   TablePaths = {'BackgroundEmber.ColorGreen'} },
    BGBorderColorShardGreen   = { Name = 'Shard Border [Green]', Order = 412, Width = 'wide',   TablePaths = {'BackgroundShard.BorderColorGreen'} },
    BGBorderColorEmberGreen   = { Name = 'Ember Border [Green]', Order = 413, Width = 'wide',   TablePaths = {'BackgroundEmber.BorderColorGreen'} },

    BGColorBlood              = { Name = 'Blood',                Order = 414, Width = 'wide',   TablePaths = {'Background.ColorBlood'} },
    BGColorFrost              = { Name = 'Frost',                Order = 415, Width = 'wide',   TablePaths = {'Background.ColorFrost'} },
    BGColorUnholy             = { Name = 'Unholy',               Order = 416, Width = 'wide',   TablePaths = {'Background.ColorUnholy'} },
    BGBorderColorBlood        = { Name = 'Blood Border',         Order = 417, Width = 'wide',   TablePaths = {'Background.BorderColorBlood'} },
    BGBorderColorFrost        = { Name = 'Frost Border',         Order = 418, Width = 'wide',   TablePaths = {'Background.BorderColorFrost'} },
    BGBorderColorUnholy       = { Name = 'Unholy Border',        Order = 419, Width = 'wide',   TablePaths = {'Background.BorderColorUnholy'} },

    BGColorStagger            = { Name = 'Stagger',              Order = 420, Width = 'wide',   TablePaths = {'BackgroundStagger.Color'} },
    BGColorPause              = { Name = 'Pause',                Order = 421, Width = 'wide',   TablePaths = {'BackgroundPause.Color'} },
    BGBorderColorStagger      = { Name = 'Stagger Border',       Order = 422, Width = 'wide',   TablePaths = {'BackgroundStagger.BorderColor'} },
    BGBorderColorPause        = { Name = 'Pause Border',         Order = 423, Width = 'wide',   TablePaths = {'BackgroundPause.BorderColor'} },

    BGColorAltPower           = { Name = 'Power',                Order = 424, Width = 'wide',   TablePaths = {'BackgroundPower.Color'} },
    BGColorAltCounter         = { Name = 'Counter',              Order = 425, Width = 'wide',   TablePaths = {'BackgroundCounter.Color'} },
    BGBorderColorAltPower     = { Name = 'Power Border',         Order = 426, Width = 'wide',   TablePaths = {'BackgroundPower.BorderColor'} },
    BGBorderColorAltCounter   = { Name = 'Counter Border',       Order = 427, Width = 'wide',   TablePaths = {'BackgroundCounter.BorderColor'} },
    --------------------------
    HEADER4 = { Order = 500, Name = 'Bar Color' },

    BarColor                  = { Name = 'Bar Color',            Order = 501, Width = 'wide',   TablePaths = {'Bar.Color'} },
    BarColorPredicted         = { Name = 'Predicted',            Order = 502, Width = 'wide',   TablePaths = {'Bar.PredictedColor'} },
    BarColorPredictedCost     = { Name = 'Predicted Cost',       Order = 503, Width = 'wide',   TablePaths = {'Bar.PredictedCostColor'} },
    BarColorAbsorbHealth      = { Name = 'Absorb Health',        Order = 504, Width = 'wide',   TablePaths = {'Bar.AbsorbColor'} },

    BarColorCombo             = { Name = 'Combo',                Order = 505, Width = 'wide',   TablePaths = {'BarCombo.Color'} },
    BarColorAnticipation      = { Name = 'Anticipation',         Order = 506, Width = 'wide',   TablePaths = {'BarAnticipation.Color'} },

    BarColorShard             = { Name = 'Shard',                Order = 507, Width = 'wide',   TablePaths = {'BarShard.Color'} },
    BarColorEmber             = { Name = 'Ember',                Order = 508, Width = 'wide',   TablePaths = {'BarEmber.Color'} },
    BarColorShardFull         = { Name = 'Shard (full)',         Order = 509, Width = 'wide',   TablePaths = {'BarShard.ColorFull'} },
    BarColorEmberFull         = { Name = 'Ember (full)',         Order = 510, Width = 'wide',   TablePaths = {'BarEmber.ColorFull'} },
    BarColorShardGreen        = { Name = 'Shard [Green]',        Order = 511, Width = 'wide',   TablePaths = {'BarShard.ColorGreen'} },
    BarColorEmberGreen        = { Name = 'Ember [Green]',        Order = 512, Width = 'wide',   TablePaths = {'BarEmber.ColorGreen'} },
    BarColorShardFullGreen    = { Name = 'Shard (full) [Green]', Order = 513, Width = 'wide',   TablePaths = {'BarShard.ColorFullGreen'} },
    BarColorEmberFullGreen    = { Name = 'Ember (full) [Green]', Order = 514, Width = 'wide',   TablePaths = {'BarEmber.ColorFullGreen'} },

    BarColorBlood             = { Name = 'Blood',                Order = 515, Width = 'wide',   TablePaths = {'Bar.ColorBlood'} },
    BarColorFrost             = { Name = 'Frost',                Order = 516, Width = 'wide',   TablePaths = {'Bar.ColorFrost'} },
    BarColorUnholy            = { Name = 'Unholy',               Order = 517, Width = 'wide',   TablePaths = {'Bar.ColorUnholy'} },

    BarColorStagger           = { Name = 'Stagger',              Order = 518, Width = 'wide',   TablePaths = {'BarStagger.Color'} },
    BarColorStaggerCont       = { Name = 'Stagger (Continued)',  Order = 519, Width = 'wide',   TablePaths = {'BarStagger.BStaggerColor'} },
    BarColorPause             = { Name = 'Pause',                Order = 520, Width = 'wide',   TablePaths = {'BarPause.Color'} },

    BarColorAltPower          = { Name = 'Power',                Order = 521, Width = 'wide',   TablePaths = {'BarPower.Color'} },
    BarColorAltCounter        = { Name = 'Counter',              Order = 522, Width = 'wide',   TablePaths = {'BarCounter.Color'} },
  }

  Options:DoFunction(BarType, 'ResetOptions', function()
    local Reset = Main.UnitBars.Reset

    -- Set defauls for reset in the unitbar
    for Name in pairs(TableData) do
      if strfind(Name, 'HEADER') == nil and Reset[Name] == nil then
        Reset[Name] = false
      end    end
    -- Delete entries that don't exist
    for Name in pairs(Reset) do
      if strfind(Name, 'HEADER') ~= nil or Name ~= 'Minimize' and TableData[Name] == nil then
        Reset[Name] = nil
      end
    end
  end)

  Options:DoFunction(BarType, 'ResetOptions')

  local ResetOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return Main.UnitBars.Reset[Info.arg]
          end,
    set = function(Info, Value)
            Main.UnitBars.Reset[Info.arg] = Value
          end,
    args = {
      Spacer5 = CreateSpacer(5),
      Minimize = {
        type = 'input',
        order = 5,
        name = function()
                 if Main.UnitBars.Reset.Minimize then
                   return '+'
                 else
                   return '_'
                 end
               end,
        width = 'half',
        dialogControl = 'GUB_Flex_Button',
        desc = function()
                 if Main.UnitBars.Reset.Minimize then
                   return 'Click to maximize'
                 else
                   return 'Click to minimize'
                 end
               end,
        set = function()
                 local Reset = Main.UnitBars.Reset

                 Reset.Minimize = not Reset.Minimize
                 HideTooltip(true)
               end,
        get = function()
                return 'L,40'
              end,
      },
      Spacer10 = CreateSpacer(10, 'half'),
      Reset = {
        type = 'execute',
        order = 11,
        name = 'Reset',
        width = 'half',
        desc = 'Clicking this will reset the current items checked off below',
        confirm = true,
        func = function()
                 local UB = UBF.UnitBar

                 if Main.UnitBars.Reset.All then
                   Main:CopyTableValues(UBD, UB, true)
                 else

                   -- Find the keys
                   for Name, TablePaths in pairs(ResetList) do

                     -- Only do the ones that are checked
                     if Main.UnitBars.Reset[Name] then
                       for _, TablePath in ipairs(TablePaths) do

                         -- Get from default
                         local UBDv = Main:GetUB(BarType, TablePath, DUB)
                         -- Get from unitbar
                         local UBv = Main:GetUB(BarType, TablePath)

                         if UBv ~= nil then
                           if type(UBv) ~= 'table' then -- copy key
                             UB[TablePath] = UBD[TablePath]
                           elseif UBDv then  -- copy table if found in defaults
                             Main:CopyTableValues(UBDv, UBv, true)
                           else -- empty table since its not in defaults
                             wipe(UBv)
                           end
                         end
                       end
                     end
                   end
                 end

                 -- Update the layout.
                 Main.Reset = true

                 UBF:SetAttr()
                 UBF:StatusCheck()
                 UBF:Update()

                 -- Update any text highlights.  Use 'on' since its always on when options are opened.
                 Bar:SetHighlightFont('on', Main.UnitBars.HideTextHighlight)

                 -- Update any dynamic options.
                 Options:DoFunction()

                 Main.Reset = false
               end,
        disabled = function()
                     if Main.UnitBars.Reset.All then
                       return false
                     else
                       local Disabled = true


                       for Name in pairs(ResetList) do
                         if Main.UnitBars.Reset[Name] then
                           Disabled = false
                         end
                       end
                       return Disabled
                     end
                   end,
      },
      Spacer20 = CreateSpacer(20),
      Notes = {
        type = 'description',
        name = 'Check off what to reset',
        order = 21,
        hidden = function()
                   return Main.UnitBars.Reset.Minimize
                 end
      },
      Spacer1000 = CreateSpacer(1000),
    },
  }

  local Args = ResetOptions.args
  local Index = 1

  -- Only add check boxes that are found in the unitbar
  for Name, Table in pairs(TableData) do
    if strfind(Name, 'HEADER') then
      local CheckTable = Table.CheckTable

      if CheckTable == nil or Main:GetUB(BarType, CheckTable) ~= nil then
        Args[Name] = {
          type = 'header',
          name = Table.Name,
          order = 1000 + Table.Order,
          hidden = function()
                     return Main.UnitBars.Reset.Minimize or Name ~= 'All' and Main.UnitBars.Reset.All
                   end,
        }
      end
    else
      local TablePaths = Table.TablePaths

      -- option button if table path found.
      if ( Name == 'All' or Main:GetUB(BarType, TablePaths[1]) ) and (Table.BarType == nil or Table.BarType == BarType) then
        Args['ResetOption' .. Index] = {
          type = 'toggle',
          name = Table.Name,
          order = 1000 + Table.Order,
          width = Table.Width,
          hidden = function()
                     return Main.UnitBars.Reset.Minimize or Name ~= 'All' and Main.UnitBars.Reset.All
                   end,
          arg = Name,
        }
        if Name ~= 'All' then
          ResetList[Name] = TablePaths
        end
        Index = Index + 1
      end
    end
  end

  return ResetOptions
end

-------------------------------------------------------------------------------
-- CreateAttributeOptions
--
-- SubFunction of CreateUnitBarOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateAttributeOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local AttributeOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            local KeyName = Info[#Info]

            if KeyName == 'FrameStrata' then
              return ConvertFrameStrata[UBF.UnitBar.Attributes.FrameStrata]
            else
              return UBF.UnitBar.Attributes[KeyName]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            if KeyName == 'FrameStrata' then
              Value = ConvertFrameStrata[Value]
            end
            UBF.UnitBar.Attributes[KeyName] = Value
            UBF:SetAttr('Attributes', KeyName)
          end,
    args = {
      Scale = {
        type = 'range',
        name = 'Scale',
        order = 1,
        desc = 'Changes the scale of the bar',
        min = o.UnitBarScaleMin,
        max = o.UnitBarScaleMax,
        step = 0.01,
        isPercent  = true,
      },
      Alpha = {
        type = 'range',
        name = 'Alpha',
        order = 2,
        desc = 'Changes the transparency of the bar',
        min = o.UnitBarAlphaMin,
        max = o.UnitBarAlphaMax,
        step = 0.01,
        isPercent = true,
      },
      AnchorPoint = {
        type = 'select',
        name = 'Anchor Point',
        order = 3,
        style = 'dropdown',
        desc = 'Change the anchor point of the bar.  This effects where the bar will change size from',
        values = PositionDropdown,
      },
      FrameStrata = {
        type = 'select',
        name = 'Frame Strata',
        order = 4,
        desc = 'Sets the frame strata making the bar appear below or above other frames',
        values = FrameStrataDropdown,
        style = 'dropdown',
      },
      MainAnimationType = {
        type = 'toggle',
        name = 'Main Animation Type',
        order = 5,
        desc = 'Uses the Animation Type setting in Main Animation',
      },
      AnimationTypeBar = {
        type = 'select',
        name = 'Animation Type Bar',
        order = 6,
        style = 'dropdown',
        desc = 'Changes the type of animation played when showing or hiding the bar',
        values = AnimationTypeDropdown,
        disabled = function()
                     return UBF.UnitBar.Attributes.MainAnimationType
                   end
      },
    },
  }

  return AttributeOptions
end

-------------------------------------------------------------------------------
-- CreateCopyPasteOptions
--
-- Creates options for copy and paste bars.
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType   Bar thats using copy and paste.
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateCopyPasteOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
  local BBar = UBF.BBar
  local IsText = { ['Text']  = 1, ['Text.1']  = 1, ['Text.2']  = 1, ['Text.3']  = 1, ['Text.4']  = 1,
                   ['Text2'] = 1, ['Text2.1'] = 1, ['Text2.2'] = 1, ['Text2.3'] = 1, ['Text2.4'] = 1 } -- Stagger Pause Timer Text

  MenuButtons = MenuButtons or { -- Include means that these menu items will be usable during copy paste.
    ['Main'] = { Order = 1, Width = 'half',
      { Name = 'All',                  Width = 'half',   All = false, TablePath = '',                                   },  -- 1
      { Name = 'Spec',                 Width = 'half',   All = true,  TablePath = 'ClassSpecs',                         },  -- 2
      { Name = 'Status',               Width = 'half',   All = true,  TablePath = 'Status',                             },  -- 3
      { Name = 'Layout',               Width = 'half',   All = true,  TablePath = 'Layout',                             },  -- 4
      { Name = 'Region',               Width = 'half',   All = true,  TablePath = 'Region',                             },  -- 5
      { Name = 'Attributes',           Width = 'normal', All = true,  TablePath = 'Attributes',                         }}, -- 6

    ['Background'] = { Order = 2, Width = 'normal',
      { Name = 'Background',           Width = 'normal', All = true,  TablePath = 'Background',                         },  -- 1
      { Name = 'Combo',                Width = 'half',   All = false, TablePath = 'BackgroundCombo',                    },  -- 2
      { Name = 'Anticipation',         Width = 'normal', All = false, TablePath = 'BackgroundAnticipation',             },  -- 3
      { Name = 'Shard',                Width = 'half',   All = false, TablePath = 'BackgroundShard',                    },  -- 4
      { Name = 'Ember',                Width = 'half',   All = false, TablePath = 'BackgroundEmber',                    },  -- 5
      { Name = 'Stagger',              Width = 'half',   All = false, TablePath = 'BackgroundStagger',                  },  -- 6
      { Name = 'Pause',                Width = 'half',   All = false, TablePath = 'BackgroundPause',                    },  -- 7
      { Name = 'Power',                Width = 'half',   All = false, TablePath = 'BackgroundPower',                    },  -- 8
      { Name = 'Counter',              Width = 'half',   All = false, TablePath = 'BackgroundCounter',                  }}, -- 9

    ['Bar'] = { Order = 3, Width = 'half',
      { Name = 'Bar',                  Width = 'half',   All = true,  TablePath = 'Bar',                                },  -- 1
      { Name = 'Combo',                Width = 'half',   All = false, TablePath = 'BarCombo',                           },  -- 2
      { Name = 'Anticipation',         Width = 'normal', All = false, TablePath = 'BarAnticipation',                    },  -- 3
      { Name = 'Shard',                Width = 'half',   All = false, TablePath = 'BarShard',                           },  -- 4
      { Name = 'Ember',                Width = 'half',   All = false, TablePath = 'BarEmber',                           },  -- 5
      { Name = 'Stagger',              Width = 'half',   All = false, TablePath = 'BarStagger',                         },  -- 6
      { Name = 'Pause',                Width = 'half',   All = false, TablePath = 'BarPause',                           },  -- 7
      { Name = 'Power',                Width = 'half',   All = false, TablePath = 'BarPower',                           },  -- 8
      { Name = 'Counter',              Width = 'half',   All = false, TablePath = 'BarCounter',                         }}, -- 9

    ['Region Color'] = { Order = 4, Width = 'normal', Include = { ['Region Color'] = 1, ['Background Color'] = 1, ['Bar Color'] = 1 },
      { Name = 'Background',           Width = 'normal', All = true,  TablePath = 'Region.Color',                       },  -- 1
      { Name = 'Border',               Width = 'half',   All = true,  TablePath = 'Region.BorderColor',                 }}, -- 2

    ['Background Color'] = { Order = 5, Width = 'normal', Include = { ['Region Color'] = 1, ['Background Color'] = 1, ['Bar Color'] = 1 },
      { Name = 'Background Color',     Width = 'normal', All = true,  TablePath = 'Background.Color',                   },  -- 1
      { Name = 'Border Color',         Width = 'normal', All = true,  TablePath = 'Background.BorderColor',             },  -- 2
      { Name = 'Combo',                Width = 'half',   All = false, TablePath = 'BackgroundCombo.Color',              },  -- 3
      { Name = 'Anticipation',         Width = 'normal', All = false, TablePath = 'BackgroundAnticipation.Color',       },  -- 4
      { Name = 'Combo Border',         Width = 'normal', All = false, TablePath = 'BackgroundCombo.BorderColor',        },  -- 5
      { Name = 'Anticipation Border',  Width = 'normal', All = false, TablePath = 'BackgroundAnticipation.BorderColor', },  -- 6
      { Name = 'Shard',                Width = 'half',   All = false, TablePath = 'BackgroundShard.Color',              },  -- 7
      { Name = 'Ember',                Width = 'half',   All = false, TablePath = 'BackgroundEmber.Color',              },  -- 8
      { Name = 'Shard [Green]',        Width = 'normal', All = false, TablePath = 'BackgroundShard.ColorGreen',         },  -- 9
      { Name = 'Ember [Green]',        Width = 'normal', All = false, TablePath = 'BackgroundEmber.ColorGreen',         },  -- 10
      { Name = 'Shard Border',         Width = 'normal', All = false, TablePath = 'BackgroundShard.BorderColor',        },  -- 11
      { Name = 'Ember Border',         Width = 'normal', All = false, TablePath = 'BackgroundEmber.BorderColor',        },  -- 12
      { Name = 'Shard Border [Green]', Width = 'normal', All = false, TablePath = 'BackgroundShard.BorderColorGreen',   },  -- 13
      { Name = 'Ember Border [Green]', Width = 'normal', All = false, TablePath = 'BackgroundEmber.BorderColorGreen',   },  -- 14
      { Name = 'Blood',                Width = 'half',   All = false, TablePath = 'Background.ColorBlood',              },  -- 15
      { Name = 'Frost',                Width = 'half',   All = false, TablePath = 'Background.ColorFrost',              },  -- 16
      { Name = 'Unholy',               Width = 'half',   All = false, TablePath = 'Background.ColorUnholy',             },  -- 17
      { Name = 'Blood Border',         Width = 'normal', All = false, TablePath = 'Background.BorderColorBlood',        },  -- 18
      { Name = 'Frost Border',         Width = 'normal', All = false, TablePath = 'Background.BorderColorFrost',        },  -- 19
      { Name = 'Unholy Border',        Width = 'normal', All = false, TablePath = 'Background.BorderColorUnholy',       },  -- 20
      { Name = 'Stagger',              Width = 'half',   All = false, TablePath = 'BackgroundStagger.Color',            },  -- 21
      { Name = 'Pause',                Width = 'half',   All = false, TablePath = 'BackgroundPause.Color',              },  -- 22
      { Name = 'Stagger Border',       Width = 'normal', All = false, TablePath = 'BackgroundStagger.BorderColor',      },  -- 23
      { Name = 'Pause Border',         Width = 'normal', All = false, TablePath = 'BackgroundPause.BorderColor',        },  -- 24
      { Name = 'Power',                Width = 'half',   All = false, TablePath = 'BackgroundPower.Color',              },  -- 25
      { Name = 'Counter',              Width = 'half',   All = false, TablePath = 'BackgroundCounter.Color',            },  -- 26
      { Name = 'Power Border',         Width = 'normal', All = false, TablePath = 'BackgroundPower.BorderColor',        },  -- 27
      { Name = 'Counter Border',       Width = 'normal', All = false, TablePath = 'BackgroundCounter.BorderColor',      }}, -- 28

    ['Bar Color'] = { Order = 6, Width = 'normal', Include = { ['Region Color'] = 1, ['Background Color'] = 1, ['Bar Color'] = 1 },
      { Name = 'Bar Color',            Width = 'normal', All = true,  TablePath = 'Bar.Color',                          },  -- 1
      { Name = 'Predicted',            Width = 'normal', All = true,  TablePath = 'Bar.PredictedColor',                 },  -- 2
      { Name = 'Predicted Cost',       Width = 'normal', All = true,  TablePath = 'Bar.PredictedCostColor',             },  -- 3
      { Name = 'Absorb Health',        Width = 'normal', All = true,  TablePath = 'Bar.AbsorbColor',                    },  -- 4
      { Name = 'Combo',                Width = 'half',   All = false, TablePath = 'BarCombo.Color',                     },  -- 5
      { Name = 'Anticipation',         Width = 'normal', All = false, TablePath = 'BarAnticipation.Color',              },  -- 6
      { Name = 'Shard',                Width = 'half',   All = false, TablePath = 'BarShard.Color',                     },  -- 7
      { Name = 'Ember',                Width = 'half',   All = false, TablePath = 'BarEmber.Color',                     },  -- 8
      { Name = 'Shard (full)',         Width = 'normal', All = false, TablePath = 'BarShard.ColorFull',                 },  -- 9
      { Name = 'Ember (full)',         Width = 'normal', All = false, TablePath = 'BarEmber.ColorFull',                 },  -- 10
      { Name = 'Shard [Green]',        Width = 'normal', All = false, TablePath = 'BarShard.ColorGreen',                },  -- 11
      { Name = 'Ember [Green]',        Width = 'normal', All = false, TablePath = 'BarEmber.ColorGreen',                },  -- 12
      { Name = 'Shard (full) [Green]', Width = 'normal', All = false, TablePath = 'BarShard.ColorFullGreen',            },  -- 13
      { Name = 'Ember (full) [Green]', Width = 'normal', All = false, TablePath = 'BarEmber.ColorFullGreen',            },  -- 14
      { Name = 'Blood',                Width = 'half',   All = false, TablePath = 'Bar.ColorBlood',                     },  -- 15
      { Name = 'Frost',                Width = 'half',   All = false, TablePath = 'Bar.ColorFrost',                     },  -- 16
      { Name = 'Unholy',               Width = 'half',   All = false, TablePath = 'Bar.ColorUnholy',                    },  -- 17
      { Name = 'Stagger',              Width = 'half',   All = false, TablePath = 'BarStagger.Color',                   },  -- 18
      { Name = 'Pause',                Width = 'half',   All = false, TablePath = 'BarPause.Color',                     },  -- 19
      { Name = 'Power',                Width = 'half',   All = false, TablePath = 'BarPower.Color',                     },  -- 20
      { Name = 'Counter',              Width = 'half',   All = false, TablePath = 'BarCounter.Color',                   }}, -- 21

    ['Text'] = { Order = 7, Width = 'half', Include = { ['Text'] = 1, ['Text (pause)'] = 1 },
      { Name  = 'All Text',            Width = 'half',   All = true,  TablePath = 'Text',                               },  -- 1
      { Name  = 'Text 1',              Width = 'half',   All = false, TablePath = 'Text.1',                             },  -- 2
      { Name  = 'Text 2',              Width = 'half',   All = false, TablePath = 'Text.2',                             },  -- 3
      { Name  = 'Text 3',              Width = 'half',   All = false, TablePath = 'Text.3',                             },  -- 4
      { Name  = 'Text 4',              Width = 'half',   All = false, TablePath = 'Text.4',                             }}, -- 5

    ['Text (pause)'] = { Order = 8, Width = 'normal', BarType = 'StaggerBar', Include = { ['Text'] = 1, ['Text (pause)'] = 1 },
      { Name  = 'All Text',            Width = 'half',   All = true,  TablePath = 'Text2',                              },  -- 1
      { Name  = 'Text 1',              Width = 'half',   All = false, TablePath = 'Text2.1',                            },  -- 2
      { Name  = 'Text 2',              Width = 'half',   All = false, TablePath = 'Text2.2',                            },  -- 3
      { Name  = 'Text 3',              Width = 'half',   All = false, TablePath = 'Text2.3',                            },  -- 4
      { Name  = 'Text 4',              Width = 'half',   All = false, TablePath = 'Text2.4',                            }}, -- 5

    ['Text (counter)'] = { Order = 8, Width = 'normal', BarType = 'AltPowerBar', Include = { ['Text'] = 1, ['Text (counter)'] = 1 },
      { Name  = 'All Text',            Width = 'half',   All = true,  TablePath = 'Text2',                              },  -- 1
      { Name  = 'Text 1',              Width = 'half',   All = false, TablePath = 'Text2.1',                            },  -- 2
      { Name  = 'Text 2',              Width = 'half',   All = false, TablePath = 'Text2.2',                            },  -- 3
      { Name  = 'Text 3',              Width = 'half',   All = false, TablePath = 'Text2.3',                            },  -- 4
      { Name  = 'Text 4',              Width = 'half',   All = false, TablePath = 'Text2.4',                            }}, -- 5

    ['Triggers'] = { Order = 9, Width = 'half',
      { Name = 'Triggers',             Width = 'half',   All = true,  TablePath = 'Triggers',                           }}, -- 1
  }

  local CopyPasteOptions = {
    type = 'group',
    name = function()
             if ClipBoard then
               return format('%s: |cffffff00%s - %s [ %s ]|r', Name, ClipBoard.BarName or '', ClipBoard.MenuButtonName, ClipBoard.SelectButtonName)
             else
               return Name
             end
           end,
    dialogInline = true,
    order = Order,
    confirm = function(Info)
                local Name = Info[#Info]
                local Arg = Info.arg

                -- Make sure a select button was clicked
                if Arg then
                  if ClipBoard then
                    if Name == 'AppendTriggers' then
                      return format('Append Triggers from %s to\n%s', DUB[BarType].Name, DUB[ClipBoard.BarType].Name)
                    elseif Name ~= 'Clear' then
                      return format('Copy %s [ %s ] to \n%s [ %s ]', ClipBoard.BarName or '', ClipBoard.SelectButtonName, DUB[BarType].Name, Arg.PasteName)
                    end
                  end
                end
              end,
    func = function(Info)
             local Name = Info[#Info]
             local Arg = Info.arg

             -- First click initialize.
             if ClipBoard == nil then
               ClipBoard = {}
               ClipBoard.BarType = BarType
               ClipBoard.BarName = UBF.UnitBar.Name
               ClipBoard.Hide = Arg.Hide
               ClipBoard.TablePath = Arg.TablePath
               ClipBoard.MenuButtonName = Arg.MenuButtonName
               ClipBoard.SelectButtonName = Arg.SelectButtonName
               ClipBoard.AllButton = Arg.AllButton
               ClipBoard.AllButtonText = Arg.AllButtonText
               ClipBoard.Include = Arg.Include
             else
               -- Save name and locaton.
               local UB = UBF.UnitBar
               local UBName = UB.Name
               local x, y = UB.x, UB.y

               if Name == 'AppendTriggers' then
                 BBar:AppendTriggers(ClipBoard.BarType)
               else
                 -- Paste
                 local SourceBarType = ClipBoard.BarType
                 local SourceTablePath = ClipBoard.TablePath
                 local SourceTable = Main:GetUB(BarType, SourceTablePath)

                 if ClipBoard.AllButton then
                   for SelectIndex, SelectButton in pairs(MenuButtons) do
                     for _, SB in ipairs(SelectButton) do
                       if SB.All then
                         local TablePath = SB.TablePath

                         Main:CopyUnitBar(ClipBoard.BarType, BarType, TablePath, TablePath)
                       end
                     end
                   end
                 else
                   Main:CopyUnitBar(ClipBoard.BarType, BarType, ClipBoard.TablePath, Arg.TablePath)
                 end
               end

               -- Restore name and location.
               UB.Name = UBName
               UB.x, UB.y = x, y

               -- Update the layout.
               Main.CopyPasted = true

               UBF:SetAttr()
               UBF:StatusCheck()
               UBF:Update()

               Main.CopyPasted = false
               -- Update any text highlights.  Use 'on' since its always on when options are opened.
               Bar:SetHighlightFont('on', Main.UnitBars.HideTextHighlight)

               -- Update any dynamic options.
               Options:DoFunction()
             end
             HideTooltip(true)
           end,
    args = {},
  }

  local Args = CopyPasteOptions.args

  Args.MenuLine = {
    type = 'header',
    name = '',
    order = 20,
    width = 'full',
  }

  -- Create clear button
  Args.Clear = {
    type = 'execute',
    name = 'Clear',
    order = 10,
    width = 'half',
    func = function()
             ClipBoard = nil

             HideTooltip(true)
           end,
    hidden = function()
               return ClipBoard == nil
             end,
    disabled = function()
                 HideTooltip(true)

                 return ClipBoard == nil
               end,
  }

  -- Create menu buttons
  for MenuButtonName, MenuButton in pairs(MenuButtons) do
    local Found = false

    -- Check to see if any tables exist.
    for _, SelectButton in ipairs(MenuButton) do
      if SelectButton.Name == 'All' or Main:GetUB(BarType, SelectButton.TablePath) ~= nil then
        Found = true
        break
      end
    end

    if Found and (MenuButton.BarType == nil or MenuButton.BarType == BarType) then

      -- Create the menu button
      Args[MenuButtonName] = {
        type = 'input',
        order = MenuButton.Order,
        name = function()
                 if SelectedMenuButtonName == MenuButtonName then
                   return format('%s:2', MenuButtonName)
                 else
                   return format('%s', MenuButtonName)
                 end
               end,
        width = MenuButton.Width,
        dialogControl = 'GUB_Menu_Button',
        disabled = function()
                     if ClipBoard ~= nil then
                       if ClipBoard.MenuButtonName ~= MenuButtonName then
                         local Include = ClipBoard.Include

                         -- Check for inclusion
                         if Include == nil or Include[MenuButtonName] == nil then
                           return true
                         end
                       end
                     end
                     return false
                   end,
        set = function()
                SelectedMenuButtonName = MenuButtonName
              end,
        get = function() end,
      }

      -- Create the group
      local GA = {}

      Args[MenuButtonName .. '_Group'] = {
        type = 'group',
        name = '',
        order = 21,
        hidden = function()
                   return SelectedMenuButtonName ~= MenuButtonName
                 end,
        args = GA,
      }

      -- Create the select buttons
      for SelectIndex, SelectButton in ipairs(MenuButton) do
        local TablePath = SelectButton.TablePath
        local SelectButtonName = SelectButton.Name
        local AllButton = SelectButtonName == 'All'
        local AllButtonText = SelectButtonName == 'All Text'
        local Text = IsText[TablePath] ~= nil

        if AllButton or Text or Main:GetUB(BarType, TablePath) ~= nil then
          GA[MenuButtonName .. SelectButtonName] = {
            type = 'execute',
            name =  SelectButtonName,
            width = SelectButton.Width,
            order = SelectIndex,
            hidden = function()
                       return Text and Main:GetUB(BarType, TablePath) == nil or ClipBoard ~= nil
                     end,
            arg = {Hide                 = SelectButton.Hide,
                   TablePath            = TablePath,
                   MenuButtonName       = MenuButtonName,
                   SelectButtonName     = SelectButtonName,
                   AllButton            = AllButton,
                   AllButtonText        = AllButtonText,
                   Include              = MenuButton.Include },
          }

          -- Create paste button
          GA['Paste' .. MenuButtonName .. SelectButtonName] = {
            type = 'execute',
            name = format('Paste %s', SelectButtonName),
            width = 'normal',
            order = SelectIndex,
            hidden = function()
                       if ClipBoard then
                         -- Hide all buttons if All was picked except for paste all on other bars
                         if ClipBoard.AllButton then
                           return ClipBoard.BarType == BarType or not AllButton
                         elseif AllButton then
                           return true

                         -- Hide text buttons that are not needed (this is dynamic)
                         elseif Text and Main:GetUB(BarType, TablePath) == nil then
                           return true
                         else
                           -- Check if this is the source menu
                           if ClipBoard.MenuButtonName == MenuButtonName and ClipBoard.BarType == BarType then

                             -- Check for all text
                             if ClipBoard.AllButtonText or AllButtonText then
                               return true
                             else
                               -- Check for same button pressed
                               return ClipBoard.SelectButtonName == SelectButtonName
                             end
                           -- Destination menu or same menu on a different bar
                           else
                             -- Hide all text buttons if all text was clicked
                             if ClipBoard.AllButtonText then
                               return not AllButtonText
                             else
                               return AllButtonText
                             end
                           end
                         end
                       else
                         return true
                       end
                     end,
            arg = {TablePath = TablePath, PasteName = SelectButtonName},
          }

          if SelectButtonName == 'Triggers' then
            GA.AppendTriggers = {
              type = 'execute',
              name = 'Append Triggers',
              width = 'normal',
              order = 30,
              hidden = function()
                         return ClipBoard == nil or ClipBoard.BarType == BarType
                       end,
              arg = {TablePath = TablePath, PasteName = SelectButtonName},
            }
          end
        end
      end
    end
  end

  return CopyPasteOptions
end

-------------------------------------------------------------------------------
-- CreateUnitBarOptions
--
-- Subfunction of CreateMainOptions
--
-- BarType          Type of options table to create.
-- Order            Order number for the options.
-- Name             Name for the option to appear in the tree.
-- Desc             Description for option.  Set to nil for no description.
-------------------------------------------------------------------------------
local function CreateUnitBarOptions(BarType, Order, Name, Desc)
  local UBF = UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local UnitBarOptions = {
    type = 'group',
    name = function()
             local Tag = ''
             if BarType == 'FragmentBar' then
               if UBF.UnitBar.Layout.BurningEmbers then
                 Tag = ' (Ember)'
               else
                 Tag = ' (Shard)'
               end
             end
             return Name .. Tag
           end,
    order = Order,
    desc = Desc,
    args = {},
  }

  local OptionArgs = UnitBarOptions.args

  if UBD.Notes ~= nil then
    OptionArgs.Notes = {
      type = 'description',
      name = UBD.Notes,
      order = 0.1,
    }
  end

  OptionArgs.SpecOptions = CreateSpecOptions(BarType, 0.5, 'ClassSpecs')

  -- Create Status options.
  OptionArgs.Status = CreateStatusOptions(BarType, 1, 'Status')

  -- Create Attribute options.
  if UBD.Attributes then
    OptionArgs.Attributes = CreateAttributeOptions(BarType, 5, 'Attributes')
  end

  OptionArgs.Reset = CreateResetOptions(BarType, 6, 'Reset')

  OptionArgs.CopyPaste = CreateCopyPasteOptions(BarType, 7,'Copy and Paste')

  -- Add layout options if they exist.
  if UBD.Layout then
    OptionArgs.Layout = CreateLayoutOptions(BarType, 1000, 'Layout')
  end

  -- Add region options if they exist.
  if UBD.Region then
    OptionArgs.Border = CreateBackdropOptions(BarType, 'Region', 1001, 'Region')
    OptionArgs.Border.hidden = function()
                                 return Flag(true, UBF.UnitBar.Layout.HideRegion)
                               end
  end

  -- Add tab background options
  if BarType == 'FragmentBar' or BarType == 'ComboBar' or BarType == 'StaggerBar' or BarType == 'AltPowerBar' then
    if BarType == 'FragmentBar' then
      OptionArgs.Background = {
        type = 'group',
        name = 'Background',
        order = 1002,
        childGroups = 'tab',
      }
      OptionArgs.Background.args = {
        Shard = CreateBackdropOptions(BarType, 'BackgroundShard', 1, 'Shard'),
        Ember = CreateBackdropOptions(BarType, 'BackgroundEmber', 2, 'Ember'),
      }
    -- Combo bar
    elseif BarType == 'ComboBar' then
      OptionArgs.Background = {
        type = 'group',
        name = 'Background',
        order = 1002,
        childGroups = 'tab',
      }
      OptionArgs.Background.args = {
        Combo = CreateBackdropOptions(BarType, 'BackgroundCombo', 1, 'Combo'),
        Anticipation = CreateBackdropOptions(BarType, 'BackgroundAnticipation', 2, 'Anticipation'),
      }
    -- Stagger bar
    elseif BarType == 'StaggerBar' then
      OptionArgs.Background = {
        type = 'group',
        name = 'Background',
        order = 1002,
        childGroups = 'tab',
      }
      OptionArgs.Background.args = {
        Stagger = CreateBackdropOptions(BarType, 'BackgroundStagger', 1, 'Stagger'),
        Pause = CreateBackdropOptions(BarType, 'BackgroundPause', 2, 'Pause'),
      }
    -- Alternate Power Bar
    else
      OptionArgs.Background = {
        type = 'group',
        name = 'Background',
        order = 1002,
        childGroups = 'tab',
      }
      OptionArgs.Background.args = {
        AltPower = CreateBackdropOptions(BarType, 'BackgroundPower', 1, 'Power'),
        AltCounter = CreateBackdropOptions(BarType, 'BackgroundCounter', 2, 'Counter'),
      }
    end
    OptionArgs.Background.hidden = function()
                                     return not Flag(true, UBF.UnitBar.Layout.BoxMode)
                                   end
  else
    -- Add background options
    OptionArgs.Background = CreateBackdropOptions(BarType, 'Background', 1002, 'Background')
    if BarType == 'RuneBar' then
      OptionArgs.Background.hidden = function()
                                       return UBF.UnitBar.Layout.RuneMode == 'rune'
                                     end
    else
      OptionArgs.Background.hidden = function()
                                       return not Flag(true, UBF.UnitBar.Layout.BoxMode)
                                     end
    end
  end

  -- add tab bar options
  if BarType == 'FragmentBar' or BarType == 'ComboBar' or BarType == 'StaggerBar' or BarType == 'AltPowerBar' then
    if BarType == 'FragmentBar' then
      OptionArgs.Bar = {
        type = 'group',
        name = 'Bar',
        order = 1003,
        childGroups = 'tab',
      }
      OptionArgs.Bar.args = {
        Shard = CreateBarOptions(BarType, 'BarShard', 1, 'Shard'),
        Ember = CreateBarOptions(BarType, 'BarEmber', 2, 'Ember'),
      }
    -- Combo bar
    elseif BarType == 'ComboBar' then
      OptionArgs.Bar = {
        type = 'group',
        name = 'Bar',
        order = 1003,
        childGroups = 'tab',
      }
      OptionArgs.Bar.args = {
        Combo = CreateBarOptions(BarType, 'BarCombo', 1, 'Combo'),
        Anticipation = CreateBarOptions(BarType, 'BarAnticipation', 2, 'Anticipation'),
      }
    -- Stagger bar
    elseif BarType == 'StaggerBar' then
      OptionArgs.Bar = {
        type = 'group',
        name = 'Bar',
        order = 1003,
        childGroups = 'tab',
      }
      OptionArgs.Bar.args = {
        Stagger = CreateBarOptions(BarType, 'BarStagger', 1, 'Stagger'),
        Pause = CreateBarOptions(BarType, 'BarPause', 2, 'Pause'),
      }
    -- Alternate Power bar
    else
      OptionArgs.Bar = {
        type = 'group',
        name = 'Bar',
        order = 1003,
        childGroups = 'tab',
      }
      OptionArgs.Bar.args = {
        Power = CreateBarOptions(BarType, 'BarPower', 1, 'Power'),
        Counter = CreateBarOptions(BarType, 'BarCounter', 2, 'Counter'),
      }
    end
    OptionArgs.Bar.hidden = function()
                              return not Flag(true, UBF.UnitBar.Layout.BoxMode)
                            end
  else
    -- add bar options
    OptionArgs.Bar = CreateBarOptions(BarType, 'Bar', 1003, 'Bar')
    if BarType == 'RuneBar' then
      OptionArgs.Bar.hidden = function()
                                return UBF.UnitBar.Layout.RuneMode == 'rune'
                              end
    else
      OptionArgs.Bar.hidden = function()
                                return not Flag(true, UBF.UnitBar.Layout.BoxMode)
                              end
    end
  end

  -- Add text options
  if UBD.Text ~= nil then
    if BarType == 'StaggerBar' or BarType == 'AltPowerBar' then
      if BarType == 'StaggerBar' then
        OptionArgs.Text = {
          type = 'group',
          name = 'Text',
          order = 1004,
          childGroups = 'tab',
        }
        OptionArgs.Text.args = {
          Stagger = CreateTextOptions(BarType, 'Text', 1, 'Stagger'),
          Pause = CreateTextOptions(BarType, 'Text2', 2, 'Pause'),
        }
      else
        OptionArgs.Text = {
          type = 'group',
          name = 'Text',
          order = 1004,
          childGroups = 'tab',
        }
        OptionArgs.Text.args = {
          Power = CreateTextOptions(BarType, 'Text', 1, 'Power'),
          Counter = CreateTextOptions(BarType, 'Text2', 2, 'Counter'),
        }
      end
    else
      OptionArgs.Text = CreateTextOptions(BarType, 'Text', 1004, 'Text')
      OptionArgs.Text.hidden = function()
                                 return UBF.UnitBar.Layout.HideText
                               end
    end
  end

  -- Add trigger options
  if UBD.Triggers ~= nil then
    OptionArgs.Triggers = CreateTriggerOptions(BarType, 1005, 'Triggers')
    OptionArgs.Triggers.hidden = function()
                                   return not Flag(false, UBF.UnitBar.Layout.EnableTriggers)
                                 end
  end

  return UnitBarOptions
end

-------------------------------------------------------------------------------
-- AddRemoveBarGroups
--
-- Adds or remove unitbar groups from the options panel based on whats
-- enables or disabled.
--
-- BarGroups   Table pointing to where the option bargroups are stored.
--             If nil then retreives it from the source.
-------------------------------------------------------------------------------
function GUB.Options:AddRemoveBarGroups(BarGroups)
  local BarGroups = BarGroups or MainOptions.args.UnitBars.args
  local Order = 0
  local UnitBars = Main.UnitBars

  -- Add or remove multiple bargroups.
  for BarType, UBF in pairs(Main.UnitBarsF) do
    local UB = UBF.UnitBar

    Order = Order + 1

    if UB.Enabled then
      if BarGroups[BarType] == nil then
        BarGroups[BarType] = CreateUnitBarOptions(BarType, UB.OptionOrder, UB.Name, UB.OptionText or '')
      end
    else
      Options:DoFunction(BarType, 'clear')
      BarGroups[BarType] = nil
    end
  end
end

-------------------------------------------------------------------------------
-- CreateEnableUnitBarOptions
--
-- Creates options that let you disable/enable unit bars.
--
-- Args      Table containing the unitbars.
-- Order     Position in the options list.
-- Name      Name of the options.
-- Desc      Description when mousing over the options name.
-------------------------------------------------------------------------------
local function CreateEnableUnitBarOptions(BarGroups, Order, Name, Desc)
  local EnableUnitBarOptions = {
    type = 'group',
    name = Name,
    order = Order,
    desc = Desc,
    args = {
      EnableClass = {
        type = 'toggle',
        name = 'Enable Class Bars',
        desc = 'Enable bars for your class only',
        order = 1,
        get = function()
                return Main.UnitBars.EnableClass
              end,
        set = function(Info, Value)
                Main.UnitBars.EnableClass = Value
                Main:SetUnitBars()
              end
      },
      UnitBarList = {
        type = 'group',
        name = 'Check off the bars you want to enable',
        dialogInline = true,
        disabled = function()
                     return Main.UnitBars.EnableClass
                   end,
        order = 2,
        get = function(Info)
                return Main.UnitBars[Info[#Info]].Enabled
              end,
        set = function(Info, Value)
                Main.UnitBars[Info[#Info]].Enabled = Value
                Main:SetUnitBars()
              end,
        args = {
          Spacer10 = CreateSpacer(10),
        },
      },
    },
  }

  -- Create enable list
  local EUBOptions = EnableUnitBarOptions.args.UnitBarList.args

  for BarType, UBF in pairs(Main.UnitBarsF) do
    local UBToggle = {}
    local UB = UBF.UnitBar

    UBToggle.type = 'toggle'
    UBToggle.name = UB.Name
    UBToggle.order = UB.OptionOrder * 10

    EUBOptions[BarType] = UBToggle
  end

  return EnableUnitBarOptions
end

-------------------------------------------------------------------------------
-- CreateAuraOptions
--
-- Creates options that let you view the aura list.
--
-- Order     Position in the options list.
-- Name      Name of the options.
-- Desc      Description when mousing over the options name.
-------------------------------------------------------------------------------
local function AuraSort(a, b)
  return a.Name < b.Name
end

local function RefreshAuraList(AG, Unit, TrackedAurasList)
  if TrackedAurasList and Main.UnitBars.AuraListOn then
    AG.args = {}

    local AGA = AG.args
    local Order = 0
    local SortList = {}
    local AuraList = {}

    -- Build aura list
    local Auras = TrackedAurasList[Unit]

    if Auras then
      for SpellID, Aura in pairs(Auras) do
        AuraList[SpellID] = Aura
      end
    end

    for SpellID, Aura in pairs(AuraList) do
      local AuraKey = format('Auras%s', SpellID)

      if AGA[AuraKey] == nil then
        Order = Order + 1

        local AuraInfo = {
          type = 'input',
          width = 'full',
          name = format('%s:24:14:(|cFF00FF00%s|r)', SpellID, SpellID),
          dialogControl = 'GUB_Spell_Info',
          get = function() end,
          set = function() end,
        }

        SortList[Order] = {Name = GetSpellInfo(SpellID), AuraInfo = AuraInfo}
        AGA[AuraKey] = AuraInfo
      end
    end
    sort(SortList, AuraSort)
    for Index = 1, #SortList do
      SortList[Index].AuraInfo.order = Index
    end
  end
end

local function DeleteAuraTabs(ALA)
  for Key in pairs(ALA) do
    if strfind(Key, 'AuraGroup') then
      ALA[Key] = nil
    end
  end
end

local function UpdateAuraTabs(ALA, Order)
  local TrackedAurasList = Main.TrackedAurasList
  local OrderNumber = Order

  if TrackedAurasList then
    for Unit in pairs(TrackedAurasList) do
      local Key = 'AuraGroup_' .. Unit

      if ALA[Key] == nil then
        ALA[Key] = {
          type = 'group',
          order = function()
                    if Unit == 'All' then
                      return OrderNumber - 0.5
                    else
                      return Order
                    end
                  end,
          name = Unit,
          args = {},
        }
      end
      Order = Order + 1
    end

    -- Remove units no longer in use.
    for Key in pairs(ALA) do
      local _, Unit = strsplit('_', Key)

      if Unit then
        if TrackedAurasList[Unit] == nil then
          ALA[Key] = nil
        else
          RefreshAuraList(ALA[Key], Unit, TrackedAurasList)
        end
      end
    end
  else
    DeleteAuraTabs(ALA)
  end
end

local function CreateAuraOptions(Order, Name, Desc)
  local ALA = nil

  -- This is needed so the aura list is always updated.
  function GUB.Options:UpdateAuras()
    if Main.UnitBars.AuraListOn then
      UpdateAuraTabs(ALA, 100)
    else
      DeleteAuraTabs(ALA)
    end
  end

  local AuraListOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    desc = Desc,
    get = function(Info)
            return Main.UnitBars[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            -- remove extra spaces
            if KeyName == 'AuraListUnits' then
              Value = strjoin(' ', Main:StringSplit(' ', Value))
            end

            Main.UnitBars[KeyName] = Value
            Main:UnitBarsSetAllOptions()
            GUB:UnitBarsUpdateStatus()
          end,
    args = {
      Description = {
        type = 'description',
        name = 'Lists all units and auras that the mod is using.  Can add additional units in the box below.  All tab shows all units',
        order = 1,
      },
      AuraListUnits = {
        type = 'input',
        name = 'Units',
        order = 2,
        desc = 'Enter the units to track auras. Each unit can be seperated by a space',
        disabled = function()
                     return not Main.UnitBars.AuraListOn
                   end,
      },
      RefreshAuras = {
        type = 'execute',
        name = 'Refresh',
        desc = 'Refresh aura list',
        width = 'half',
        order = 5,
        func = function()
                 Options:UpdateAuras()
               end,
        disabled = function()
                     return not Main.UnitBars.AuraListOn
                   end
      },
      AuraListOn = {
        type = 'toggle',
        name = 'Enable',
        order = 6,
      },
      Spacer20 = CreateSpacer(20),
    }
  }

  ALA = AuraListOptions.args
  return AuraListOptions
end

-------------------------------------------------------------------------------
-- CreateAltPowerBarOptions
--
-- Creates options that let you view all the alternate power bars
--
-- Order     Position in the options list.
-- Name      Name of the options.
-- TableName Will create the tab under this table.
--
-- NOTES: The list needs to be built over time so no lag is caused.
-------------------------------------------------------------------------------
local function BuildAltPowerBarList(APA, Order, Name, TableName)
  local APBUsed = Main.APBUsed
  local APBUseBlizz = Main.APBUseBlizz

  local PowerBarList = {
    type = 'group',
    name = Name,
    order = Order,
    args = {},
    disabled = function()
                 return Main.UnitBars.APBDisabled
               end,
  }
  APA[TableName] = PowerBarList
  local PBA = PowerBarList.args

  for BarID = 1, 10000 do
    local AltPowerType, MinPower, _, _, _, _, _, _, _, _, PowerName, PowerTooltip = GetAlternatePowerInfoByID(BarID)
    local ZoneName = APBUsed[BarID]

    if TableName ~= 'APB' then
      if AltPowerType and APBUseBlizz[BarID] then
        local Index = 'APBUseBlizz' .. BarID
        PBA[Index] = APA.APB.args[Index]
      end
    elseif AltPowerType then
      if AltPowerBarSearch == '' or BarID == tonumber(AltPowerBarSearch) or
                                    strfind(strlower(PowerName),    strlower(AltPowerBarSearch)) or
                                    strfind(strlower(PowerTooltip), strlower(AltPowerBarSearch)) or
                                    ZoneName and strfind(strlower(ZoneName), strlower(AltPowerBarSearch)) then
        PBA['APBUseBlizz' .. BarID] = {
          type = 'toggle',
          width = 'full',
          arg = BarID,
          name = function()
                   if ZoneName then
                     return format('|cff00ff00%s|r : |cffffff00%s|r (|cff00ffff%s|r)', BarID, PowerName, ZoneName)
                   else
                     return format('|cff00ff00%s|r : |cffffff00%s|r', BarID, PowerName)
                   end
                 end,
          order = function()
                    if APBUsed[BarID] then
                      return BarID
                    else
                      return BarID + 1000
                    end
                  end,
          hidden = function()
                     return APBUsed[BarID] == nil and Main.UnitBars.APBShowUsed
                   end,
          disabled = function()
                       return Main.HasAltPower
                     end,
        }
        PBA['Line2' .. BarID] = {
          type = 'description',
          name = PowerTooltip,
          fontSize = 'medium',
          order = function()
                    if APBUsed[BarID] then
                      return BarID + 0.2
                    else
                      return BarID + 1000.3
                    end
                  end,
          hidden = function()
                     return APBUsed[BarID] == nil and Main.UnitBars.APBShowUsed
                   end,
        }
      end
    end
  end
end

local function CreateAltPowerBarOptions(Order, Name)
  local APA = nil

  local AltPowerBarOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    get = function(Info)
            local KeyName = Info[#Info]

            if strfind(KeyName, 'APBUseBlizz') then
              return Main.APBUseBlizz[Info.arg]
            elseif KeyName == 'Search' then
              return AltPowerBarSearch
            else
              return Main.UnitBars[KeyName]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            if strfind(KeyName, 'APBUseBlizz') then
              Main.APBUseBlizz[Info.arg] = Value
            elseif KeyName == 'Search' then
              AltPowerBarSearch = Value
              BuildAltPowerBarList(APA, 100, 'Alternate Power Bar', 'APB')
              BuildAltPowerBarList(APA, 101, 'Use Blizzard', 'APBUseBlizz')
            else
              if APA and strfind(KeyName, 'APBDisabled') and Value then
                APA.PowerBarList = nil
              end
              Main.UnitBars[KeyName] = Value
            end
          end,
    disabled = function()
                 if not Main.UnitBars.APBDisabled then
                   BuildAltPowerBarList(APA, 100, 'Alternate Power Bar', 'APB')
                   BuildAltPowerBarList(APA, 101, 'Use Blizzard', 'APBUseBlizz')
                 end
                 return Main.HasAltPower
               end,
    args = {
      Description = {
        type = 'description',
        name = 'May take a few seconds to build the list. Bars already used have an area name.\nChecking off a bar will use the blizzard bar instead',
        order = 1,
      },
      Search = {
        type = 'input',
        name = 'Search',
        order = 3,
        disabled = function()
                     return Main.UnitBars.APBDisabled or Main.HasAltPower
                   end,
      },
      clearSearch = {
        type = 'execute',
        name = 'Clear',
        desc = 'Clear search',
        width = 'half',
        order = 4,
        func = function()
                 AltPowerBarSearch = ''
                 BuildAltPowerBarList(APA, 100, 'Alternate Power Bar', 'APB')
                 BuildAltPowerBarList(APA, 101, 'Use Blizzard', 'APBUseBlizz')
                 HideTooltip(true)
               end,
        disabled = function()
                     return Main.UnitBars.APBDisabled or Main.HasAltPower
                   end,
      },
      APBShowUsed = {
        type = 'toggle',
        name = 'Show used bars only',
        width = 'normal',
        order = 5,
        disabled = function()
                     return Main.UnitBars.APBDisabled or Main.HasAltPower
                   end,
      },
      APBDisabled = {
        type = 'toggle',
        name = 'Disable',
        width = 'half',
        order = 6,
      },
      Spacer10 = CreateSpacer(10),
    },
  }

  APA = AltPowerBarOptions.args
  BuildAltPowerBarList(APA, 100, 'Alternate Power Bar', 'APB')
  BuildAltPowerBarList(APA, 101, 'Use Blizzard', 'APBUseBlizz')

  return AltPowerBarOptions
end

-------------------------------------------------------------------------------
-- CreateDebugOptions
--
-- Lists error messages in an edit box
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateDebugOptions(Order, Name)
  local DebugOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {
      Description = {
        type = 'description',
        name = 'Track error messages, works only for text',
        order = 1,
      },
      Clear = {
        type = 'execute',
        name = 'Clear',
        order = 2,
        width = 'half',
        func = function()
                 DebugText = ''
               end,
        disabled = function()
                     return not Main.UnitBars.DebugOn
                   end,
      },
      DebugOn = {
        type = 'toggle',
        name = 'Enable',
        order = 3,
      },
      DebugWindow = {
        type = 'input',
        name = '',
        order = 4,
        dialogControl = 'GUB_MultiLine_EditBox',
        width = 'full',
        get = function(text)
                return DebugText
              end,
        set = function() end,
      },
    },
  }

  return DebugOptions
end

function GUB.Options:AddDebugLine(Text)
  if Main.UnitBars.DebugOn then
    local Text, _, ErrorText = strsplit(':', Text, 3)

    ErrorText = Text .. ErrorText
    if strfind(DebugText, ErrorText, 1, true) == nil then
      DebugText = DebugText .. ErrorText .. '\n'
    end
  end
end

-------------------------------------------------------------------------------
-- CreatePowerColorOptions
--
-- Creates power color options for a UnitBar.
--
-- Subfunction of CreateMainOptions()
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
--
-- PowerColorOptions    Options table for power colors.
-------------------------------------------------------------------------------
local function CreatePowerColorOptions(Order, Name)
  local PowerColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local KeyName = Info[#Info]
            local c = Main.UnitBars.PowerColor

            c = c[ConvertPowerType[KeyName]]

            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local KeyName = Info[#Info]
            local c = Main.UnitBars.PowerColor

            c = c[ConvertPowerType[KeyName]]
            c.r, c.g, c.b, c.a = r, g, b, a

            -- Set the color to all the bars
            for _, UBF in ipairs(Main.UnitBarsFE) do
              UBF:Update()
            end
          end,
    args = {
    --  Spacer10 = CreateSpacer(10),
      Spacer50 = CreateSpacer(50),
      Spacer100 = CreateSpacer(100),
      Reset = {
        type = 'execute',
        name = 'Reset',
        desc = 'Reset colors back to defaults',
        width = 'half',
        confirm = true,
        order = 101,
        func = function()
                 Main:CopyTableValues(DUB.PowerColor, Main.UnitBars.PowerColor)

                 -- Set the color to all the bars
                 for _, UBF in ipairs(Main.UnitBarsFE) do
                   UBF:Update()
                 end
               end,
      },
    },
  }

  -- Power types for the player power bar.
  -- These cover classes with more than one power type.
  local PlayerPower = {
    DRUID = {MANA = 0, ENERGY = 0, RAGE = 0, LUNAR_POWER = 8},
    MONK  = {MANA = 0, ENERGY = 0},
    SHAMAN = {MANA = 0, MAELSTROM = 11},
    PRIEST = {MANA = 0, INSANITY = 12},
    DEMONHUNTER = {FURY = 17, PAIN = 18},
  }
  local PowerWidth = {
    RUNIC_POWER = 'normal',
    LUNAR_POWER = 'normal',
    MAELSTROM = 'normal',
  }
  local PowerName = {
    RUNIC_POWER = 'Runic Power',
    LUNAR_POWER = 'Astral Power',
    MAELSTROM = 'Maelstrom',
  }

  -- Set up a power order.  half goes first, then normal
  local PowerOrder = {}
  local Index = 1

  for PowerType in pairs(PowerColorType) do
    if PowerWidth[PowerType] == nil then
      PowerOrder[Index] = PowerType
      Index = Index + 1
    end
  end

  for PowerType in pairs(PowerColorType) do
    if PowerWidth[PowerType] then
      PowerOrder[Index] = PowerType
      Index = Index + 1
    end
  end

  local PCOA = PowerColorOptions.args
  local ClassPowerType = PlayerPower[Main.PlayerClass]
  local PlayerPowerType = ConvertPowerType[Main.PlayerPowerType]
  Index = 0

  for _, PowerType in pairs(PowerOrder) do
    local n = gsub(strlower(PowerType), '%a', strupper, 1)
    Index = Index + 1

    if ClassPowerType and ClassPowerType[PowerType] or PowerType == PlayerPowerType then
      Order = Index
    else
      Order = Index + 50
    end

    PCOA[PowerType] = {
      type = 'color',
      name = PowerName[PowerType] or n,
      order = Order,
      width = PowerWidth[PowerType] or 'half',
      hasAlpha = true,
    }
  end

  return PowerColorOptions
end

-------------------------------------------------------------------------------
-- CreateClassColorOptions
--
-- Creates class color options for a UnitBar.
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateClassColorOptions(Order, Name)
  local ClassColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local KeyName = Info[#Info]

            if KeyName == 'ClassTaggedColor' then
              return Main.UnitBars.ClassTaggedColor
            else
              local c = Main.UnitBars.ClassColor[KeyName]
              return c.r, c.g, c.b, c.a
            end
          end,
    set = function(Info, r, g, b, a)
            local KeyName = Info[#Info]

            if KeyName == 'ClassTaggedColor' then
              Main.UnitBars.ClassTaggedColor = r
            else
              local c = Main.UnitBars.ClassColor[KeyName]
              c.r, c.g, c.b, c.a = r, g, b, a
            end

            -- Set the color to all the bars
            for _, UBF in ipairs(Main.UnitBarsFE) do
              UBF:Update()
            end
          end,
    args = {
      ClassTaggedColor = {
        type = 'toggle',
        name = 'Tagged Color',
        desc = 'Use tagged color if the unit is tagged and not a player',
        order = 9,
      },
      Spacer10 = CreateSpacer(10),
      Spacer50 = CreateSpacer(50),
      Spacer100 = CreateSpacer(100),
      Reset = {
        type = 'execute',
        name = 'Reset',
        desc = 'Reset colors back to defaults',
        width = 'half',
        confirm = true,
        order = 101,
        func = function()
                 Main:CopyTableValues(DUB.ClassColor, Main.UnitBars.ClassColor)

                 -- Set the color to all the bars
                 for _, UBF in ipairs(Main.UnitBarsFE) do
                   UBF:Update()
                 end
               end,
      },
    },
  }

  local CCOA = ClassColorOptions.args

  for Index, ClassName in ipairs(ConvertPlayerClass) do
    local Order = Index + 50
    local n = ConvertPlayerClass[ClassName]

    if ClassName == Main.PlayerClass then
      Order = 1
    end

    local Width = 'half'
    if Index == 1 or Index == 2 then
      Width = 'normal'
    end

    CCOA[ClassName] = {
      type = 'color',
      name = n,
      order = Order,
      desc = n == 'None' and 'Used if the unit has no class' or nil,
      width = Width,
      hasAlpha = true,
    }
  end
  CCOA.Spacer50 = CreateSpacer(50)

  return ClassColorOptions
end

-------------------------------------------------------------------------------
-- CreateCombatColorOptions
--
-- Creates option to change combat colors.
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateCombatColorOptions(Order, Name)
  local CombatColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local KeyName = Info[#Info]
            local UB = Main.UnitBars
            local c = nil

            if strfind(KeyName, 'Player') then
              c = UB.PlayerCombatColor[strsub(KeyName, 7)]
            else
              c = UB.CombatColor[KeyName]
            end
            if type(c) ~= 'table' then
              return UB[KeyName]
            else
              return c.r, c.g, c.b, c.a
            end
          end,
    set = function(Info, r, g, b, a)
            local KeyName = Info[#Info]
            local UB = Main.UnitBars
            local c = nil

            if strfind(KeyName, 'Player') then
              c = UB.PlayerCombatColor[strsub(KeyName, 7)]
            else
              c = UB.CombatColor[KeyName]
            end
            if type(c) ~= 'table' then
              UB[KeyName] = r
            else
              c.r, c.g, c.b, c.a = r, g, b, a
            end

            -- Set the color to all the bars
            for _, UBF in ipairs(Main.UnitBarsFE) do
              UBF:Update()
            end
          end,
    args = {
      CombatClassColor = {
        type = 'toggle',
        name = 'Class Color',
        desc = 'Replace Player Hostile and Attack with Class Color',
        order = 1,
      },
      CombatTaggedColor = {
        type = 'toggle',
        name = 'Tagged Color',
        desc = 'Use tagged color if the unit is tagged and not a player',
        order = 2,
      },
      -- NPC
      Player = {
        type = 'header',
        name = 'NPC',
        order = 10,
      },
      -- Players
      NPC = {
        type = 'header',
        name = 'Player',
        order = 50,
      },
      Spacer100 = CreateSpacer(100),
      Reset = {
        type = 'execute',
        name = 'Reset',
        desc = 'Reset colors back to defaults',
        width = 'half',
        confirm = true,
        order = 101,
        func = function()
                 Main:CopyTableValues(DUB.CombatColor, Main.UnitBars.CombatColor)
                 Main:CopyTableValues(DUB.PlayerCombatColor, Main.UnitBars.PlayerCombatColor)

                 -- Set the color to all the bars
                 for _, UBF in ipairs(Main.UnitBarsFE) do
                   UBF:Update()
                 end
               end,
      },
    },
  }

  local FCOA = CombatColorOptions.args
  local Index = nil

  -- Create NPC combat color options
  for CombatColor, Color in pairs(DUB.CombatColor) do
    local Order = ConvertCombatColor[CombatColor] + 10

    FCOA[CombatColor] = {
      type = 'color',
      name = CombatColor,
      order = Order,
      width = 'half',
      hasAlpha = true,
    }
  end

  -- Create combat color options
  for CombatColor, Color in pairs(DUB.PlayerCombatColor) do
    local Order = ConvertCombatColor[CombatColor] + 50
    local Desc = nil
    local Disabled = nil

    if CombatColor == 'Hostile' then
      Desc = 'Target can attack you'
    elseif CombatColor == 'Attack' then
      Desc = "Target can't attack you, but you can attack them"
    elseif CombatColor == 'Flagged' then
      Desc = 'PvP flagged'
    elseif CombatColor == 'Ally' then
      Desc = 'Target is not PvP flagged'
    end

    if CombatColor == 'Hostile' or CombatColor == 'Attack' then
      Disabled = function()
                   return Main.UnitBars.CombatClassColor
                 end
    end

    FCOA['Player' .. CombatColor] = {
      type = 'color',
      name = CombatColor,
      desc = Desc,
      order = Order,
      width = 'half',
      hasAlpha = true,
      disabled = Disabled,
    }
  end

  return CombatColorOptions
end

-------------------------------------------------------------------------------
-- CreateTaggedColorOptions
--
-- Creates option to change tagged color.
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateTaggedColorOptions(Order, Name)
  local TaggedColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local KeyName = Info[#Info]
            local c = Main.UnitBars[KeyName]

            if KeyName ~= 'TaggedTest' then
              return c.r, c.g, c.b, c.a
            else
              return c
            end
          end,
    set = function(Info, r, g, b, a)
            local KeyName = Info[#Info]
            local UB = Main.UnitBars

            if KeyName ~= 'TaggedTest' then
              local c = UB[KeyName]
              c.r, c.g, c.b, c.a = r, g, b, a
            else
              UB.TaggedTest = r
            end

            -- Set the color to all the bars
            for _, UBF in ipairs(Main.UnitBarsFE) do
              UBF:Update()
            end
          end,
    args = {
      TaggedColor = {
        type = 'color',
        name = 'Tagged',
        order = 1,
        width = 'half',
        hasAlpha = true,
      },
      TaggedTest = {
        type = 'toggle',
        name = 'Test',
        order = 11,
        desc = 'Tagging is always on. For testing',
      },
      Spacer100 = CreateSpacer(100),
      Reset = {
        type = 'execute',
        name = 'Reset',
        desc = 'Reset colors back to defaults',
        width = 'half',
        confirm = true,
        order = 101,
        func = function()
                 Main:CopyTableValues(DUB.TaggedColor, Main.UnitBars.TaggedColor)

                 -- Set the color to all the bars
                 for _, UBF in ipairs(Main.UnitBarsFE) do
                   UBF:Update()
                 end
               end,
      },
    },
  }

  return TaggedColorOptions
end

-------------------------------------------------------------------------------
-- CreateFrameOptions
--
-- Creates options for frames dealing with player, target, and alternate power bar.
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateFrameOptions(Order, Name)
  local FrameOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {
      PortraitGroup = {
        type = 'group',
        order = 1,
        name = 'Portraits',
        dialogInline = true,
        get = function(Info)
                local MultiValue = tonumber(Main.UnitBars[Info[#Info]]) or 0
                Main.UnitBars[Info[#Info]] = MultiValue
                return MultiValue ~= 0
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]
                local MultiValue = tonumber(Main.UnitBars[KeyName]) or 0

                MultiValue = MultiValue + 1
                if MultiValue > 2 then
                  MultiValue = 0
                end
                Main.UnitBars[KeyName] = MultiValue
                Main:UnitBarsSetAllOptions()
              end,
        args = {
          Notes = {
            type = 'description',
            name = 'Unchecked means do nothing. If you checked, then unchecked an option.\nYou may need to reload UI to avoid a conflict with another addon doing the same thing',
            order = 1,
          },
          HidePlayerFrame = {
            type = 'toggle',
            width = 'full',
            order = 2,
            name = function()
                     local HidePlayerFrame = tonumber(Main.UnitBars.HidePlayerFrame) or 0

                     if HidePlayerFrame <= 1 then
                       return 'Hide Player Frame'
                     elseif HidePlayerFrame == 2 then
                       return 'Show Player Frame'
                     end
                   end,
          },
          HideTargetFrame = {
            type = 'toggle',
            width = 'full',
            order = 3,
            tristate = true,
            name = function()
                     local HideTargetFrame = tonumber(Main.UnitBars.HideTargetFrame) or 0

                     if HideTargetFrame <= 1 then
                       return 'Hide Target Frame'
                     elseif HideTargetFrame == 2 then
                       return 'Show Target Frame'
                     end
                   end,
          },
        },
      },
      APBGroup = {
        type = 'group',
        order = 2,
        name = 'Blizzard Alternate Power Bar',
        dialogInline = true,
        get = function(Info)
                local KeyName = Info[#Info]
                return Main.UnitBars[KeyName]
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]
                Main.UnitBars[KeyName] = Value

                if KeyName == 'APBMoverOptionsDisabled' then
                  Main:APBSetMover()
                end
              end,
        args = {
          Notes = {
            type = 'description',
            name = 'This will let you move the blizzard alternate power bar and the timer like those in the Darkmoon Faire\nIf this conflicts with other addons just disable.  May have to reload UI',
            order = 1,
          },
          APBMoverOptionsDisabled = {
            type = 'toggle',
            name = 'Disable mover',
            width = 'normal',
            order = 2,
          },
          Spacer5 = CreateSpacer(5, 'normal'),
          Reset = {
            type = 'execute',
            name = 'Reset',
            width = 'half',
            order = 6,
            confirm = function()
                        return 'Are you sure?'
                      end,
            func = function()
                     Main:APBReset()
                   end,
            disabled = function()
                         return Main.UnitBars.APBMoverOptionsDisabled
                       end,
          },
          Spacer7 = CreateSpacer(7),
          MoveAPB = {
            type = 'execute',
            name = function()
                     if Main.APBMoverEnabled then
                       return 'Stop Moving APB'
                     else
                       return 'Move APB'
                     end
                   end,
            order = 8,
            func = function()
                     Main.APBMoverEnabled = not Main.APBMoverEnabled
                     Main:APBSetMover('apb')
                   end,
            disabled = function()
                         return Main.UnitBars.APBMoverOptionsDisabled
                       end,
          },
          Spacer10 = CreateSpacer(10),
          MoveAPBTimer = {
            type = 'execute',
            name = function()
                     if Main.APBBuffTimerMoverEnabled then
                       return 'Stop moving Timer'
                     else
                       return 'Move Timer'
                     end
                   end,
            order = 11,
            func = function()
                     Main.APBBuffTimerMoverEnabled = not Main.APBBuffTimerMoverEnabled
                     Main:APBSetMover('timer')
                   end,
            disabled = function()
                         return Main.UnitBars.APBMoverOptionsDisabled
                       end,
          },
        },
      },
      EABGroup = {
        type = 'group',
        order = 3,
        name = 'Extra Action Button',
        dialogInline = true,
        get = function(Info)
                local KeyName = Info[#Info]
                return Main.UnitBars[KeyName]
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]
                Main.UnitBars[KeyName] = Value

                if KeyName == 'EABMoverOptionsDisabled' then
                  Main:DoExtraActionButton()
                end
              end,
        args = {
          Notes = {
            type = 'description',
            name = 'This will let you move the extra action button. If this conflicts with other addons just disable.  May have to reload UI',
            order = 1,
          },
          EABMoverOptionsDisabled = {
            type = 'toggle',
            name = 'Disable mover',
            width = 'normal',
            order = 2,
          },
          Spacer5 = CreateSpacer(5, 'normal'),
          Reset = {
            type = 'execute',
            name = 'Reset',
            width = 'half',
            order = 6,
            confirm = function()
                        return 'Are you sure?'
                      end,
            func = function()
                     Main:EABReset()
                   end,
            disabled = function()
                         return Main.UnitBars.EABMoverOptionsDisabled
                       end,
          },
          Spacer7 = CreateSpacer(7),
          MoveEAB = {
            type = 'execute',
            name = function()
                     if Main.EABMoverEnabled then
                       return 'Stop Moving EAB'
                     else
                       return 'Move EAB'
                     end
                   end,
            order = 8,
            func = function()
                     Main.EABMoverEnabled = not Main.EABMoverEnabled
                     Main:DoExtraActionButton()
                   end,
            disabled = function()
                         return Main.UnitBars.EABMoverOptionsDisabled
                       end,
          },
        },
      },
    },
  }

  return FrameOptions
end

-------------------------------------------------------------------------------
-- CreateHelpOptions
--
-- Displays help and links
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-- Text      Array containing the text to display.
-------------------------------------------------------------------------------
local function CreateHelpOptions(Order, Name, Text)
  local HelpOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {},
  }

  local HOA = HelpOptions.args

  for TextIndex = 1, #Text do
    local Text = Text[TextIndex]
    local TextKey = 'Text' .. TextIndex
    local Pos = strfind(Text, 'http')

    if Pos then
      local Name = strsub(Text, 1, Pos - 1)
      local Link = strsub(Text, Pos)

      HOA[TextKey] = {
        type = 'input',
        name = Name or '',
        order = TextIndex,
        width = 'double',
        dialogControl = 'GUB_EditBox_Selected',
        get = function()
                return format('|Cffffff00%s|r', Link)
              end,
        set = function() end,
      }
    else
      Pos = strfind(Text, '[]', 1, true)

      if Pos then
        local Name = strsub(Text, 1, Pos - 1)
        local SubText = strsub(Text, Pos + 3) -- +1 to skip newline \n

        HOA[TextKey] = {
          type = 'group',
          name = Name,
          order = TextIndex,
          dialogInline = true,
          args = {
            SubText = {
              type = 'description',
              name = SubText,
              fontSize = 'medium',
              order = 1,
              width = 'full',
            }
          }
        }
      else
        HOA[TextKey] = {
          type = 'description',
          name = Text,
          fontSize = 'medium',
          order = TextIndex,
          width = 'full',
        }
      end
    end
    HOA['Spacer' .. TextIndex] = CreateSpacer(TextIndex + 0.5)
  end

  return HelpOptions
end

-------------------------------------------------------------------------------
-- CreateMainOptions
--
-- Returns the main options table.
-------------------------------------------------------------------------------
local function CreateMainOptions()
  MainOptions = {
    name = AddonName,
    type = 'group',
    order = 1,
    childGroups = 'tab',
    args = {
--=============================================================================
-------------------------------------------------------------------------------
--    GENERAL group.
-------------------------------------------------------------------------------
--=============================================================================
      General = {
        name = 'General',
        type = 'group',
        childGroups = 'tab',
        order = 1,
        get = function(Info)
                return Main.UnitBars[Info[#Info]]
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]

                Main.UnitBars[KeyName] = Value
                Main:UnitBarsSetAllOptions()

                if strfind(KeyName, 'Animation') == nil then
                  GUB:UnitBarsUpdateStatus()
                end

                -- Update align and swap bar location if needed if clamped cause bar to go off screen.
                if KeyName == 'IsClamped' and not Main.UnitBars.Align and Options.AlignSwapOptionsOpen then
                  Options:RefreshAlignSwapOptions()
                end
              end,
        args = {
          Main = {
            type = 'group',
            name = 'Main',
            order = 1,
            args = {
              Layout = {
                type = 'group',
                name = 'Layout',
                order = 1,
                dialogInline = true,
                args = {
                  IsLocked = {
                    type = 'toggle',
                    name = 'Lock Bars',
                    order = 1,
                    desc = 'Prevent bars from being dragged around',
                  },
                  IsClamped = {
                    type = 'toggle',
                    name = 'Screen Clamp',
                    order = 2,
                    desc = 'Prevent bars from going off the screen',
                  },
                  IsGrouped = {
                    type = 'toggle',
                    name = 'Group Drag',
                    order = 3,
                    desc = 'Drag all the bars as one instead of one at a time',
                  },
                  AlignAndSwapEnabled = {
                    type = 'toggle',
                    name = 'Enable Align & Swap',
                    order = 4,
                    desc = 'If unchecked, right clicking a unitbar will not open align and swap',
                  },
                  HideTextHighlight = {
                    type = 'toggle',
                    name = 'Hide Text Highlight',
                    order = 5,
                    desc = 'Text will not be highlighted when options is opened',
                  },
                  HighlightDraggedBar = {
                    type = 'toggle',
                    name = 'Highlight Dragged Bar',
                    order = 6,
                    desc = 'The bar being dragged will show a box around it',
                  },
                  Testing = {
                    type = 'toggle',
                    name = 'Test Mode',
                    order = 7,
                    desc = 'All bars will be displayed using fixed values',
                  },
                  BarFillFPS = {
                    type = 'range',
                    name = 'Bar Fill FPS',
                    order = 8,
                    desc = 'Change the frame rate of smooth fill and timer bars. Higher values will reduce choppyness, but will consume more cpu',
                    min = o.BarFillFPSMin,
                    max = o.BarFillFPSMax,
                    step = 1,
                  },
                },
              },
              Tooltips = {
                name = 'Tooltips',
                type = 'group',
                order = 2,
                dialogInline = true,
                args = {
                  HideTooltips = {
                    type = 'toggle',
                    name = 'Hide Tooltips',
                    order = 1,
                    desc = 'Turns off mouse over tooltips when bars are not locked',
                  },
                  HideTooltipsDesc = {
                    type = 'toggle',
                    name = 'Hide Tooltips Desc',
                    order = 2,
                    desc = 'Turns off the description in mouse over tooltips when bars are not locked',
                  },
                  HideLocationInfo = {
                    type = 'toggle',
                    name = 'Hide Location Info',
                    order = 3,
                    desc = 'Turns off the location information for bars and boxes in mouse over tooltips when bars are not locked',
                  },
                },
              },
              Animation = {
                name = 'Animation',
                type = 'group',
                order = 3,
                dialogInline = true,
                args = {
                  ReverseAnimation = {
                    type = 'toggle',
                    name = 'Reverse Animation',
                    order = 1,
                    desc = 'Animation in/out can switch direction smoothly',
                  },
                  AnimationType = {
                    type = 'select',
                    name = 'Animation Type',
                    order = 2,
                    style = 'dropdown',
                    desc = 'Changes the type of animation played when showing or hiding bars',
                    values = AnimationTypeDropdown,
                  },
                  Spacer = CreateSpacer(3),
                  AnimationInTime = {
                    type = 'range',
                    name = 'Animation-in',
                    order = 8,
                    desc = 'The amount of time in seconds to play animation after showing a bar',
                    min = 0,
                    max = o.AnimationInTime,
                    step = 0.1,
                  },
                  AnimationOutTime = {
                    type = 'range',
                    name = 'Animation-out',
                    order = 9,
                    desc = 'The amount of time in seconds to play animation before hiding a bar',
                    min = 0,
                    max = o.AnimationOutTime,
                    step = 0.1,
                  },
                },
              },
            },
          },
          Frames = CreateFrameOptions(4, 'Frames'),
          Colors = {
            type = 'group',
            name = 'Colors',
            order = 5,
            args = {
              PowerColors = CreatePowerColorOptions(5, 'Power Color'),
              ClassColors = CreateClassColorOptions(6, 'Class Color'),
              CombatColors = CreateCombatColorOptions(7, 'Combat Color'),
              TaggedColor = CreateTaggedColorOptions(8, 'Tagged color'),
            },
          },
          AuraOptions = CreateAuraOptions(6, 'Aura List'),
          AltPowerBar = CreateAltPowerBarOptions(7, 'Alt Power Bar'),
          DebugOptions = CreateDebugOptions(8, 'Debug'),
        },
      },
    },
  }

--=============================================================================
-------------------------------------------------------------------------------
--    BARS group.
-------------------------------------------------------------------------------
--=============================================================================
  local MainOptionsArgs = MainOptions.args

  MainOptionsArgs.UnitBars = {
    type = 'group',
    name = 'Bars',
    order = 2,
    args = {}
  }

  -- Enable Unitbar options.
  MainOptionsArgs.UnitBars.args.EnableBars = CreateEnableUnitBarOptions(MainOptionsArgs.UnitBars.args, 0, 'Enable', 'Enable or Disable bars')

--=============================================================================
-------------------------------------------------------------------------------
--    UTILITY group.
-------------------------------------------------------------------------------
--=============================================================================
--  MainOptionsArgs.Utility = {
--    type = 'group',
--    name = 'Utility',
--    order = 3,
--    args = {
--      AuraList = CreateAuraOptions(1, 'Aura List'),
--    },
--  }

--=============================================================================
-------------------------------------------------------------------------------
--    PROFILES group.
-------------------------------------------------------------------------------
--=============================================================================
  MainOptionsArgs.Profile = AceDBOptions:GetOptionsTable(GUB.MainDB)
  MainOptionsArgs.Profile.order = 100

--=============================================================================
-------------------------------------------------------------------------------
--    HELP group.
-------------------------------------------------------------------------------
--=============================================================================
  MainOptionsArgs.Help = {
    type = 'group',
    name = 'Help',
    order = 101,
    childGroups = 'tab',
    args = {
      HelpText = CreateHelpOptions(1, format('|cffffd200%s   version %.2f|r', AddonName, Version / 100), HelpText),
      LinksText = CreateHelpOptions(2, 'Links', LinksText),
      Changes = CreateHelpOptions(3, 'Changes', ChangesText),
    },
  }

  return MainOptions
end

--*****************************************************************************
--
-- Options Initialization
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- CreateMessageBoxOptions
--
-- Creates a simple table to display a message box in an options frame.
-------------------------------------------------------------------------------
local function CreateMessageBoxOptions()
  local MessageBoxOptions = {
    type = 'group',
    name = AddonName,
    order = 1,
    args = {
      Message = {
        type = 'description',
        name = '',
      },
    },
  }

  return MessageBoxOptions
end

-------------------------------------------------------------------------------
-- MessageBox
--
-- Opens a message box to display a message
-------------------------------------------------------------------------------
function GUB.Options:MessageBox(Message)
  MessageBoxOptions.args.Message.name = Message
  AceConfigDialog:Open(AddonMessageBoxOptions)
end

-------------------------------------------------------------------------------
-- CreateAlingSwapOptions
--
-- Creates align and swap options for unitbars.
-------------------------------------------------------------------------------
local function CreateAlignSwapOptions()
  local AlignSwapOptions = nil

  local function SetSize()
    for KeyName in pairs(AlignSwapOptions.args) do
      local SliderArgs = AlignSwapOptions.args[KeyName]
      local Min = nil
      local Max = nil

      if strfind(KeyName, 'Padding') then
        Min = o.AlignSwapPaddingMin
        Max = o.AlignSwapPaddingMax
      elseif strfind(KeyName, 'Offset') then
        Min = o.AlignSwapOffsetMin
        Max = o.AlignSwapOffsetMax
      end
      if Min and Max then
        local Value = Main.UnitBars[KeyName]

        if Main.UnitBars.AlignSwapAdvanced then
          Value = Value < Min and Min or Value > Max and Max or Value
          Main.UnitBars[KeyName] = Value
          SliderArgs.min = Value - o.AlignSwapAdvancedMinMax
          SliderArgs.max = Value + o.AlignSwapAdvancedMinMax
        else
          SliderArgs.min = Min
          SliderArgs.max = Max
        end
      end
    end
  end

  AlignSwapOptions = {
    type = 'group',
    name = 'Align and Swap',
    order = 1,
    get = function(Info)
            local KeyName = Info[#Info]

            if KeyName == 'x' or KeyName == 'y' then
              local UB = AlignSwapAnchor.UnitBar
              local BarX, BarY = floor(UB.x + 0.5), floor(UB.y + 0.5)

              if KeyName == 'x' then
                return format('%s', floor(BarX + 0.5))
              else
                return format('%s', floor(BarY + 0.5))
              end
            else
              SetSize()
              return Main.UnitBars[Info[#Info]]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            if KeyName == 'x' or KeyName == 'y' then
              Value = tonumber(Value)
              if Value then
                AlignSwapAnchor.UnitBar[KeyName] = Value
              end
              local UB = AlignSwapAnchor.UnitBar

              -- Position unitbar in new location.
              Main:SetAnchorPoint(AlignSwapAnchor, UB.x, UB.y)
            else
              if KeyName == 'Swap' and Value then
                Main.UnitBars.Align = false
              elseif KeyName == 'Align' and Value then
                Main.UnitBars.Swap = false
              end
              Main.UnitBars[KeyName] = Value
              SetSize()
              Main:SetUnitBarsAlignSwap()
            end
          end,
    args = {
      Align = {
        type = 'toggle',
        name = 'Align',
        order = 1,
        width = 'half',
        desc = 'When a bar is dragged near another it will align its self to it. \nThis needs to be unchecked to set bar location',
      },
      Swap = {
        type = 'toggle',
        name = 'Swap',
        order = 2,
        width = 'half',
        desc = 'Allows you to swap one bar with another',
      },
      AlignSwapAdvanced = {
        type = 'toggle',
        name = 'Advanced',
        order = 3,
        desc = 'Allows you to make fine tune adjustments easier with the sliders',
        hidden = function()
                     return not Main.UnitBars.Align
                   end,
      },
      AlignSwapPaddingX = {
        type = 'range',
        name = 'Padding Horizontal',
        order = 11,
        desc = 'Sets the distance between two or more bars that are aligned horizontally',
        step = 1,
        hidden = function()
                     return not Main.UnitBars.Align
                   end,
      },
      AlignSwapPaddingY = {
        type = 'range',
        name = 'Padding Vertical',
        order = 12,
        desc = 'Sets the distance between two or more bars that are aligned vertically',
        step = 1,
        hidden = function()
                     return not Main.UnitBars.Align
                   end,
      },
      AlignSwapOffsetX = {
        type = 'range',
        name = 'Offset Horizontal',
        order = 21,
        desc = 'Offsets the padding group',
        step = 1,
        hidden = function()
                     return not Main.UnitBars.Align
                   end,
      },
      AlignSwapOffsetY = {
        type = 'range',
        name = 'Offset Vertical',
        order = 22,
        desc = 'Offsets the padding group',
        step = 1,
        hidden = function()
                     return not Main.UnitBars.Align
                   end,
      },
      BarLocation = {
        type = 'group',
        name = function()
                 return format('Bar Location (%s)    Anchor Point (%s)', AlignSwapAnchor.Name, PositionDropdown[AlignSwapAnchor.UnitBar.Attributes.AnchorPoint])
               end,
        dialogInline = true,
        order = 30,
        hidden = function()
                   return Main.UnitBars.Align
                 end,
        args = {
          x = {
            type = 'input',
            name = 'Horizontal',
            order = 1,
          },
          y = {
            type = 'input',
            name = 'Vertical',
            order = 2,
          },
        },
      },
    },
  }

  return AlignSwapOptions
end

-------------------------------------------------------------------------------
-- OpenAlignSwapOptions
--
-- Opens up a window with the align and swap options for unitbars.
--
-- UnitBar   Unitbar that was right clicked on.
-------------------------------------------------------------------------------
local function OnHideAlignSwapOptions(self)
  self:SetScript('OnHide', nil)
  self.OptionFrame:SetClampedToScreen(self.IsClamped)
  self.OptionFrame = nil

  Options.AlignSwapOptionsOpen = false
  Main:MoveFrameSetAlignPadding(Main.UnitBarsFE, 'reset')
end

function GUB.Options:OpenAlignSwapOptions(Anchor)
  if not Main.InCombat then
    AlignSwapAnchor = Anchor

    AceConfigDialog:SetDefaultSize(AddonAlignSwapOptions, o.AlignSwapWidth, o.AlignSwapHeight)
    AceConfigDialog:Open(AddonAlignSwapOptions)

    local OptionFrame = AceConfigDialog.OpenFrames[AddonAlignSwapOptions].frame
    SwapAlignOptionsHideFrame:SetParent(OptionFrame)

    SwapAlignOptionsHideFrame:SetScript('OnHide', OnHideAlignSwapOptions)
    SwapAlignOptionsHideFrame.IsClamped = OptionFrame:IsClampedToScreen() and true or false
    SwapAlignOptionsHideFrame.OptionFrame = OptionFrame
    OptionFrame:SetClampedToScreen(true)

    Options.AlignSwapOptionsOpen = true
  else
    print(InCombatOptionsMessage)
  end
end

-------------------------------------------------------------------------------
-- OnInitialize()
--
-- Initializes the options panel and slash options
-------------------------------------------------------------------------------
function GUB.Options:OnInitialize()

  OptionsToGUB = CreateOptionsToGUB()
  SlashOptions = CreateSlashOptions()
  MainOptions = CreateMainOptions()
  AlignSwapOptions = CreateAlignSwapOptions()
  MessageBoxOptions = CreateMessageBoxOptions()

  -- Register profile options with aceconfig.
  --LibStub('AceConfig-3.0'):RegisterOptionsTable(AddonProfileName, ProfileOptions)

  -- Register the options panels with aceconfig.
  AceConfig:RegisterOptionsTable(AddonSlashOptions, SlashOptions, 'gub')
  AceConfig:RegisterOptionsTable(AddonMainOptions, MainOptions)
  AceConfig:RegisterOptionsTable(AddonAlignSwapOptions, AlignSwapOptions)
  AceConfig:RegisterOptionsTable(AddonOptionsToGUB, OptionsToGUB)
  AceConfig:RegisterOptionsTable(AddonMessageBoxOptions, MessageBoxOptions)

  -- Add the options panels to blizz options.
  --MainOptionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(AddonMainOptions, AddonName)
  local OptionsToGUBFrame = AceConfigDialog:AddToBlizOptions(AddonOptionsToGUB, AddonName)

  -- Add the Profiles UI as a subcategory below the main options.
  --ProfilesOptionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(AddonProfileName, 'Profiles', AddonName)
end
