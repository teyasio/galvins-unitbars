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
local ConvertReputation = Main.ConvertReputation
local ConvertCombatColor = Main.ConvertCombatColor
local LSM = Main.LSM

local HelpText = GUB.DefaultUB.HelpText

-- localize some globals.
local _
local floor, ceil =
      floor, ceil
local strupper, strlower, strtrim, strfind, format, strmatch, strsplit, strsub, strjoin, tostring =
      strupper, strlower, strtrim, strfind, format, strmatch, strsplit, strsub, strjoin, tostring
local tonumber, gsub, min, max, tremove, tinsert, wipe, strsub =
      tonumber, gsub, min, max, tremove, tinsert, wipe, strsub
local ipairs, pairs, type, next, sort, select =
      ipairs, pairs, type, next, sort, select
local InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print, GameTooltip, message, GetSpellInfo, IsModifierKeyDown =
      InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print, GameTooltip, message, GetSpellInfo, IsModifierKeyDown
local UnitReaction =
      UnitReaction

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
-- GUB.Options.ATOFrame          Contains the alignment tool options window.
--
-- DoFunctions                   Table used to save and call functions thru DoFunction()

-- AlignSwapAnchor               Contains the current anchor of the Unitbar that was clicked on to open
--                               the align and swap options window.
--
-- LSMStatusBarDropdown
-- LSMBorderDropdown
-- LSMBackgroundDropdown
-- LSMFontDropdown               LSM:hashtable() drop down menus.
--
-- FontStyleDropdown             Table used for the dialog drop down for FontStyles.
-- PositionDropdown              Table used for the diaglog drop down for fonts and runes.
-- FontHAlignDropDown            Table used for the dialog drop down for font horizontal alignment.
-- ValueTypeDropdown             Table used for the dialog drop down for Health and power text type.
-- ValueNameDropdown             Table used for the dialog drop down for health and power text type.
-- DirectionDropdown             Table used to pick vertical or horizontal.
-- RuneModeDropdown              Table used to pick which mode runes are shown in.
-- RuneEnergizeDropdown          Table used for changing rune energize.
-- FrameStrataDropdown           Table used for changing the frame strats for any unitbar.
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
local O = {}
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

local O = {

  -- Test mode
  TestModeRechargeMin = 0,
  TestModeRechargeMax = 6,
  TestModeEnergizeMin = 0,
  TestModeEnergizeMax = 7,

  -- Fade for all unitbars.
  FadeOutTime = 1,
  FadeInTime = 1,

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
  FontSizeMin = 6,
  FontSizeMax = 64,
  FontFieldWidthMin = 20,
  FontFieldWidthMax = 400,
  FontFieldHeightMin = 10,
  FontFieldHeightMax = 200,

  -- Trigger settings
  TriggerTextureScaleMin = 0.1,
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

  -- Layout settings
  LayoutBorderPaddingMin = -25,
  LayoutBorderPaddingMax = 50,
  LayoutRotationMin = 45,
  LayoutRotationMax = 360,
  LayoutSlopeMin = -100,
  LayoutSlopeMax = 100,
  LayoutPaddingMin = -50,
  LayoutPaddingMax = 50,
  LayoutSmoothFillMin = 0,
  LayoutSmoothFillMax = 1,
  LayoutTextureScaleMin = 0.1,
  LayoutTextureScaleMax = 4.6,
  LayoutFadeInTimeMin = 0,
  LayoutFadeInTimeMax = 1,
  LayoutFadeOutTimeMin = 0,
  LayoutFadeOutTimeMax = 1,
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
  MainOptionsWidth = 750,
  MainOptionsHeight = 500,

  -- Other options
  UnitBarScaleMin = 0.10,

  -- Barsize options.
  UnitBarScaleMax = 4,
  UnitBarSizeMin = 10,
  UnitBarSizeMax = 500,
  UnitBarSizeAdvancedMinMax = 25,

  RuneOffsetXMin = -50,
  RuneOffsetXMax = 50,
  RuneOffsetYMin = -50,
  RuneOffsetYMax = 50,
  RuneEnergizeTimeMin = 0,
  RuneEnergizeTimeMax = 5,

  EclipseBox3OffsetXMin = -125,
  EclipseBox3OffsetXMax = 125,
  EclipseBox3OffsetYMin = -125,
  EclipseBox3OffsetYMax = 125,
  EclipseBox2OffsetXMin = -125,
  EclipseBox2OffsetXMax = 125,
  EclipseBox2OffsetYMin = -125,
  EclipseBox2OffsetYMax = 125,
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

local ValueName_AllDropdown = {
         'Current Value',       -- 1
         'Maximum Value',       -- 2
         'Predicted Value',     -- 3
         'Name',                -- 4
         'Time',                -- 5
  [99] = 'None',                -- 99
}

local ValueName_HAPDropdown = {
         'Current Value',       -- 1
         'Maximum Value',       -- 2
         'Predicted Value',     -- 3
         'Name',                -- 4
  [99] = 'None',                -- 99
}

local ValueName_TimeDropdown = {
  [5]  = 'Time',          -- 5
  [6]  = 'Charges',       -- 6
  [99] = 'None',          -- 99
}

local ValueName_RuneDropdown = {
  [5]  = 'Time',          -- 5
  [99] = 'None',          -- 99
}

local ValueName_EclipseDropdown = {
  [7]  = 'Number',
  [99] = 'None',
}

local ValueNameMenuDropdown = {
  all          = ValueName_AllDropdown,
  hap          = ValueName_HAPDropdown,
  rune         = ValueName_RuneDropdown,
  anticipation = ValueName_TimeDropdown,
  demonic      = ValueName_HAPDropdown,
  eclipse      = ValueName_EclipseDropdown,
  maelstrom    = ValueName_TimeDropdown,
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

local ValueType_TimeDropdown = {
  [20] = 'Seconds',
  [21] = 'Seconds.0',
  [22] = 'Seconds.00',
}

local ValueType_NameDropdown = {
  [30] = 'Unit Name',
  [31] = 'Realm Name',
  [32] = 'Unit Name and Realm',
}

local ValueType_WholeDropdown = {
  'Whole', -- 1
}

local ValueType_NoneDropdown = {
  [100] = '',
}

local ValueTypeMenuDropdown = {
  current   = ValueType_ValueDropdown,
  maximum   = ValueType_ValueDropdown,
  predicted = ValueType_ValueDropdown,
  time      = ValueType_TimeDropdown,
  name      = ValueType_NameDropdown,
  charges   = ValueType_WholeDropdown,
  number    = ValueType_WholeDropdown,
  none      = ValueType_NoneDropdown,

  -- prevent error if these values are found.
  unitname = ValueType_NoneDropdown,
  realmname = ValueType_NoneDropdown,
  unitnamerealm = ValueType_NoneDropdown,
}

local ConvertValueName = {
         current       = 1,
         maximum       = 2,
         predicted     = 3,
         name          = 4,
         time          = 5,
         charges       = 6,
         number        = 7,
         none          = 99,
         'current',    -- 1
         'maximum',    -- 2
         'predicted',  -- 3
         'name',       -- 4
         'time',       -- 5
         'charges',    -- 6
         'number',     -- 7
  [99] = 'none',       -- 99
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

local RuneEnergizeDropdown = {
  rune = 'Runes',
  bar = 'Bars',
  runebar = 'Bars and Runes',
  none = 'None',
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

local Operator_WholePercentDropdown = {
  '<',             -- 1
  '>',             -- 2
  '<=',            -- 3
  '>=',            -- 4
  '=',             -- 5
  '<>',            -- 6
}

local Operator_AurasDropdown = {
  'and',    -- 1
  'or',     -- 2
}

local TriggerOperatorDropdown = {
  whole   = Operator_WholePercentDropdown,
  percent = Operator_WholePercentDropdown,
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

local TriggerColorIcon          = [[Interface\AddOns\GalvinUnitBarsTest\Textures\GUB_TriggerColor.tga]]
local TriggerBarIcon            = [[Interface\AddOns\GalvinUnitBarsTest\Textures\GUB_TriggerBar.tga]]
local TriggerBorderIcon         = [[Interface\AddOns\GalvinUnitBarsTest\Textures\GUB_TriggerBorder.tga]]
local TriggerChangeSizeIcon     = [[Interface\AddOns\GalvinUnitBarsTest\Textures\GUB_TriggerChangeSize.tga]]
local TriggerSoundIcon          = [[Interface\AddOns\GalvinUnitBarsTest\Textures\GUB_TriggerSound.tga]]
local TriggerBackgroundIcon     = [[Interface\AddOns\GalvinUnitBarsTest\Textures\GUB_TriggerBackground.tga]]
local TriggerTextChangeSizeIcon = [[Interface\AddOns\GalvinUnitBarsTest\Textures\GUB_TriggerTextChangeSize.tga]]
local TriggerTextColorIcon      = [[Interface\AddOns\GalvinUnitBarsTest\Textures\GUB_TriggerTextColor.tga]]
local TriggerTextTypeIcon       = [[Interface\AddOns\GalvinUnitBarsTest\Textures\GUB_TriggerTextType.tga]]
local TriggerTextOutlineIcon    = [[Interface\AddOns\GalvinUnitBarsTest\Textures\GUB_TriggerTextOutline.tga]]

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
               AceConfigDialog:SetDefaultSize(AddonMainOptions, O.MainOptionsWidth, O.MainOptionsHeight)

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
-- CreateAlphaOption
--
-- Creates an alpha option slider.
--
-- BarType       Type of options being created.
-- Order         Order number.
--
-- AlphaOption   Option table for changing the alpha of any bar.
-------------------------------------------------------------------------------
-- Commented out for now since there is a bug with animationgroups with the frame not being an alpha of 1.

--[[local function CreateAlphaOption(BarType, Order)
  local c = 0

  local AlphaOption = {
    type = 'range',
    name = 'Alpha',
    order = 2,
    desc = 'Changes the alpha of the bar',
    min = 0,
    max = 100,
    step = 1,
    get = function()
            return UnitBars[BarType].General.Alpha * 100
          end,
    set = function(Info, Value)
            UnitBars[BarType].General.Alpha = Value / 100
            UnitBarsF[BarType]:SetAttr('frame', 'alpha')
          end,
  }
  return AlphaOption
end --]]

-------------------------------------------------------------------------------
-- CreateColorAllOptions
--
-- Creates all color options that support multiple colors.
--
-- Subfunction of CreateBackdropOptions()
-- Subfunction of CreateBarOptions()
-- Subfunction of CreateTextOptions()
-- Subfunction of CreateRuneBarOptions()
--
--
-- BarType            Type of options being created.
-- TableName          Where the color is stored.
-- TablePath          Path to where the color data is stored.
-- KeyName            Name of the color table.
-- Order              Position in the options list.
-- Name               Name of the options.
--
-- ColorAllOptions  Options table for the bartype.
-------------------------------------------------------------------------------
local function CreateColorAllOptions(BarType, TableName, TablePath, KeyName, Order, Name)
  local UBF = UnitBarsF[BarType]
  local Names = UBF.Names

  -- Get max colors
  local MaxColors = #Main:GetUB(BarType, TablePath)

  local ColorAllOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local ColorIndex = tonumber(Info[#Info])
            local c = Main:GetUB(BarType, TablePath)

            if ColorIndex > 0 then
              c = c[ColorIndex]
            end
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local ColorIndex = tonumber(Info[#Info])
            local c = Main:GetUB(BarType, TablePath)

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
                return Main:GetUB(BarType, TablePath).All
              end,
        set = function(Info, Value)
                Main:GetUB(BarType, TablePath).All = Value

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
                   return not Main:GetUB(BarType, TablePath).All
                 end,
      },
      Spacer = CreateSpacer(3),
    },
  }
  local t = ColorAllOptions.args

  for c = 1, #Main:GetUB(BarType, TablePath) do
    local Name = Names[c]
    local ColorOption = {}

    --- Create the color table
    ColorOption.type = 'color'
    ColorOption.name = Name
    ColorOption.order = c + 3
    ColorOption.hasAlpha = true
    ColorOption.hidden = function()
                           return Main:GetUB(BarType, TablePath).All
                         end

    -- Add it to the options table
    t[format('%s', c)] = ColorOption
  end

  return ColorAllOptions
end

-------------------------------------------------------------------------------
-- CreatePredictedColorOptions
--
-- Creates color options for bars that uses predicted health
--
-- Subfunction of CreateBarOptions()
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
--
-- PredictedColorOptions   Options table for setting options for predicted color
-------------------------------------------------------------------------------
local function CreatePredictedColorOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local PredictedColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            -- Info.arg[1] = color index.
            local c = UBF.UnitBar.Bar.PredictedColor
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local c = UBF.UnitBar.Bar.PredictedColor
            c.r, c.g, c.b, c.a = r, g, b, a

            -- Set the color to the bar
            UBF:SetAttr('bar')
          end,
    args = {
      PredictedColor = {
        type = 'color',
        name = 'Color',
        hasAlpha = true,
        order = 1,
      },
    },
  }

  return PredictedColorOptions
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
    name = Name,
    order = Order,
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
                  if UBD[TableName].ColorGreen then
                    if UBF.GreenFire then
                      UBF:SetAttr(TableName, 'BorderColorGreen')
                    else
                      UBF:SetAttr(TableName, 'BorderColor')
                    end
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
            min = O.UnitBarBgTileSizeMin,
            max = O.UnitBarBgTileSizeMax,
            step = 1,
          },
          Spacer20 = CreateSpacer(20),
          BorderSize = {
            type = 'range',
            name = 'Border Thickness',
            order = 21,
            min = O.UnitBarBorderSizeMin,
            max = O.UnitBarBorderSizeMax,
            step = 2,
          },
        },
      },
    },
  }

  local BackdropArgs = BackdropOptions.args
  local GeneralArgs = BackdropOptions.args.General.args

  if Name ~= 'Region' then

    -- Ember bar color options
    if UBD[TableName].ColorGreen then
      GeneralArgs.Spacer30 = CreateSpacer(30)
      GeneralArgs.EnableBorderColor = {
        type = 'toggle',
        name = 'Enable Border Color',
        order = 32,
      }
      BackdropArgs.ColorAll = CreateColorAllOptions(BarType, TableName, 'Background.Color', 'Color', 2, 'Color')
      BackdropArgs.ColorAll.hidden = function()
                                       return UBF.GreenFire
                                     end
      BackdropArgs.ColorAllGreen = CreateColorAllOptions(BarType, TableName, 'Background.ColorGreen', 'ColorGreen', 2, 'Color [green fire]')
      BackdropArgs.ColorAllGreen.hidden = function()
                                            return not UBF.GreenFire
                                          end

      BackdropArgs.BorderColorAll = CreateColorAllOptions(BarType, TableName, 'Background.BorderColor', 'BorderColor', 3, 'Border Color')
      BackdropArgs.BorderColorAll.hidden = function()
                                             return UBF.GreenFire or not UBF.UnitBar[TableName].EnableBorderColor
                                           end
      BackdropArgs.BorderColorAllGreen = CreateColorAllOptions(BarType, TableName, 'Background.BorderColorGreen', 'BorderColorGreen', 3, 'Border Color [green fire]')
      BackdropArgs.BorderColorAllGreen.hidden = function()
                                                  return not UBF.GreenFire or not UBF.UnitBar[TableName].EnableBorderColor
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
      if UBD[TableName].EnableBorderColor ~= nil then
        GeneralArgs.Spacer30 = CreateSpacer(30)
        GeneralArgs.EnableBorderColor = {
          type = 'toggle',
          name = 'Enable Border Color',
          order = 32,
        }
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
        BackdropArgs.BorderColorAll.hidden = function()
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
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
        step = 1,
      },
      Left = {
        type = 'range',
        name = 'Left',
        order = 4,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
        step = 1,
      },
      Right = {
        type = 'range',
        name = 'Right',
        order = 5,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
        step = 1,
      },
      Top = {
        type = 'range',
        name = 'Top',
        order = 6,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
        step = 1,
      },
      Bottom = {
        type = 'range',
        name = 'Bottom',
        order = 7,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
        step = 1,
      },
    },
  }

  return BackdropOptions
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

    for KeyName, _ in pairs(BarSizeOptions.args) do
      local SliderArgs = BarSizeOptions.args[KeyName]
      local Min = nil
      local Max = nil

      if KeyName == 'Width' or KeyName == 'Height' then
        Min = O.UnitBarSizeMin
        Max = O.UnitBarSizeMax
      end
      if Min and Max then
        local Value = UB[KeyName]

        if UB.Advanced then
          Value = Value < Min and Min or Value > Max and Max or Value
          UB[KeyName] = Value
          SliderArgs.min = Value - O.UnitBarSizeAdvancedMinMax
          SliderArgs.max = Value + O.UnitBarSizeAdvancedMinMax
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
            local KeyName = Info[#Info]

            UBF.UnitBar[TableName][KeyName] = Value
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
    name = Name,
    order = Order,
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
  }

  local BarArgs = BarOptions.args
  local GeneralArgs = BarOptions.args.General.args

  if UBD[TableName].StatusBarTexture ~= nil then
    GeneralArgs.StatusBarTexture = {
      type = 'select',
      name = 'Bar Texture',
      order = 1,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }
  end

  -- Health and Power bar
  if UBD[TableName].PredictedBarTexture ~= nil then
    GeneralArgs.PredictedBarTexture = {
      type = 'select',
      name = 'Bar Texture (predicted)',
      order = 2,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }
  end

  -- Demonic bar
  if UBD[TableName].MetaStatusBarTexture ~= nil then
    GeneralArgs.MetaStatusBarTexture = {
      type = 'select',
      name = 'Bar Texture (metamorphosis)',
      order = 2,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }
  end

  -- Ember bar
  if UBD[TableName].FieryStatusBarTexture ~= nil then
    GeneralArgs.FieryStatusBarTexture = {
      type = 'select',
      name = 'Bar Texture (fiery embers)',
      order = 2,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }
  end

  -- Eclipse bar
  if UBD[TableName].StatusBarTextureLunar ~= nil then
    GeneralArgs.StatusBarTextureLunar = {
      type = 'select',
      name = 'Bar Texture (lunar)',
      order = 1,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }
  end
  if UBD[TableName].StatusBarTextureSolar ~= nil then
    GeneralArgs.StatusBarTextureSolar = {
      type = 'select',
      name = 'Bar Texture (solar)',
      order = 2,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
    }
  end
  GeneralArgs.Spacer10 = CreateSpacer(10)

  if UBD[TableName].FillDirection ~= nil then
    GeneralArgs.FillDirection = {
      type = 'select',
      name = 'Fill Direction',
      order = 11,
      values = DirectionDropdown,
      style = 'dropdown',
    }
  end
  if UBD[TableName].RotateTexture ~= nil then
    GeneralArgs.RotateTexture = {
      type = 'toggle',
      name = 'Rotate Texture',
      order = 16,
    }
  end
  GeneralArgs.Spacer20 = CreateSpacer(20)

  -- Regular color for pet health or anticipation bar or eclipse bar
  if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' or
     BarType == 'PetHealth' or BarType == 'AnticipationBar' and TableName == 'BarTime' or
     BarType == 'EclipseBar' and  (TableName == 'BarMoon' or TableName == 'BarSun') or
     strfind(BarType, 'Power') then
    GeneralArgs.Color = {
      type = 'color',
      name = 'Color',
      hasAlpha = true,
      order = 21,
    }
    if UBD.General.UseBarColor ~= nil then
      GeneralArgs.Color.disabled = function()

                                     return not UBF.UnitBar.General.UseBarColor
                                   end
    end
  end

  -- Lunar and solar color for power.
  if TableName == 'BarPower' then
    GeneralArgs.ColorLunar = {
      type = 'color',
      name = 'Color (lunar)',
      hasAlpha = true,
      order = 21,
    }
    GeneralArgs.ColorSolar = {
      type = 'color',
      name = 'Color (solar)',
      hasAlpha = true,
      order = 22,
    }
  end

  -- Predicted color or tagged color
  if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' or BarType == 'PetHealth' or
     BarType == 'PlayerPower' then
    GeneralArgs.PredictedColor = {
      type = 'color',
      name = 'Color (predicted)',
      hasAlpha = true,
      order = 22,
    }
  end
  GeneralArgs.Spacer30 = CreateSpacer(30)

  -- Demonic bar
  if UBD[TableName].MetaColor ~= nil then
    GeneralArgs.DemonicColor = {
      type = 'group',
      name = 'Color',
      order = 31,
      dialogInline = true,
      args = {
        Color = {
          type = 'color',
          name = 'Normal',
          order = 1,
          hasAlpha = true,
        },
        MetaColor = {
          type = 'color',
          name = 'Metamorphosis',
          order = 2,
          hasAlpha = true,
        },
      },
    }
  end

  -- Eclipsebar sun and moon
  if UBD[TableName].SunMoon ~= nil then
    GeneralArgs.SunMoon = {
      type = 'group',
      name = 'Color',
      order = 31,
      dialogInline = true,
      args = {
        SunMoon = {
          type = 'toggle',
          name = 'Sun and Moon',
          order = 1,
          desc = 'The sun and moon color will be used',
        },
        Color = {
          type = 'color',
          name = 'Color',
          hasAlpha = true,
          order = 2,
          hidden = function()
                     return UBF.UnitBar[TableName].SunMoon
                   end,
        },
      },
    }
  end

  -- Demonic bar.
  if UBD[TableName].ColorGreen ~= nil then
    GeneralArgs.ColorAll = CreateColorAllOptions(BarType,  TableName, 'Bar.Color', 'Color', 31, 'Color')
    GeneralArgs.ColorAllFiery = CreateColorAllOptions(BarType, TableName, 'Bar.ColorFiery', 'ColorFiery', 31, 'Color (fiery embers)')
    GeneralArgs.ColorAllGreen = CreateColorAllOptions(BarType, TableName, 'Bar.ColorGreen', 'ColorGreen', 31, 'Color [green fire]')
    GeneralArgs.ColorAllFieryGreen = CreateColorAllOptions(BarType, TableName, 'Bar.ColorFieryGreen', 'ColorFieryGreen', 32, 'Color (fiery embers) [green fire]')
    GeneralArgs.ColorAll.hidden = function()
                                    return UBF.GreenFire
                                  end
    GeneralArgs.ColorAllFiery.hidden = function()
                                         return UBF.GreenFire
                                       end
    GeneralArgs.ColorAllGreen.hidden = function()
                                         return not UBF.GreenFire
                                       end
    GeneralArgs.ColorAllFieryGreen.hidden = function()
                                              return not UBF.GreenFire
                                            end
  else
    -- Standard color all
    local Color = UBD[TableName].Color
    if Color and Color.All ~= nil then
      GeneralArgs.ColorAll = CreateColorAllOptions(BarType, TableName, TableName .. '.Color', 'Color', 31, 'Color')
    end
  end

  GeneralArgs.BoxSize = CreateBarSizeOptions(BarType, TableName, 41, 'Bar Size')

  BarOptions.args.Padding = {
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
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
        step = 1,
      },
      Left = {
        type = 'range',
        name = 'Left',
        order = 4,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
        step = 1,
      },
      Right = {
        type = 'range',
        name = 'Right',
        order = 5,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
        step = 1,
      },
      Top = {
        type = 'range',
        name = 'Top',
        order = 6,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
        step = 1,
      },
      Bottom = {
        type = 'range',
        name = 'Bottom',
        order = 7,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
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
-- BarType       Bar the text options belongs to
-- TextOptions   Font options will be inserted into this table.
-- TxtLine       Used to convert TextOptions.name to number.
-- Order         Positions on the options panel.
-------------------------------------------------------------------------------
local function CreateTextFontOptions(BarType, TextOptions, TxtLine, Order)
  local UBF = UnitBarsF[BarType]
  local TS = UBF.UnitBar.Text[TxtLine[TextOptions.name]]

  TextOptions.args.Font = {
    type = 'group',
    name = function()

             -- highlight the text in green.
             Bar:SetHighlightFont(BarType, Main.UnitBars.HideTextHighlight, TxtLine[TextOptions.name])
             return 'Font'
           end,
    dialogInline = true,
    order = Order + 1,
    get = function(Info)
            return TS[Info[#Info]]
          end,
    set = function(Info, Value)
            TS[Info[#Info]] = Value
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
        min = O.FontFieldWidthMin,
        max = O.FontFieldWidthMax,
        step = 1,
      },
      Height = {
        type = 'range',
        name = 'Field Height',
        order = 12,
        min = O.FontFieldHeightMin,
        max = O.FontFieldHeightMax,
        step = 1,
      },
      Spacer20 = CreateSpacer(20),
      FontSize = {
        type = 'range',
        name = 'Size',
        order = 21,
        min = O.FontSizeMin,
        max = O.FontSizeMax,
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
            desc = 'Set the font location relative to the bar',
            values = PositionDropdown,
          },
          FontPosition = {
            type = 'select',
            name = 'Font Position',
            order = 12,
            style = 'dropdown',
            desc = 'Set the font location relative to Position',
            values = PositionDropdown,
          },
        },
      },
    },
  }

  -- Add color all text option for the runebar only.
  if BarType == 'RuneBar' then
    TextOptions.args.TextColors = CreateColorAllOptions(BarType, 'Text', 'Text.1.Color', '_Font', Order, 'Color')
  else
    TextOptions.args.Font.args.TextColor = {
      type = 'color',
      name = 'Color',
      order = 22,
      hasAlpha = true,
      get = function()
              local c = TS.Color

              return c.r, c.g, c.b, c.a
            end,
      set = function(Info, r, g, b, a)
              local c = TS.Color

              c.r, c.g, c.b, c.a = r, g, b, a
              UBF:SetAttr('Text', '_Font')
            end,
    }
  end

  TextOptions.args.Font.args.Offsets = {
    type = 'group',
    name = 'Offsets',
    dialogInline = true,
    order = 41,
    get = function(Info)
            return TS[Info[#Info]]
          end,
    set = function(Info, Value)
            TS[Info[#Info]] = Value
            UBF:SetAttr('Text', '_Font')
          end,
    args = {
      OffsetX = {
        type = 'range',
        name = 'Horizonal',
        order = 2,
        min = O.FontOffsetXMin,
        max = O.FontOffsetXMax,
        step = 1,
      },
      OffsetY = {
        type = 'range',
        name = 'Vertical',
        order = 3,
        min = O.FontOffsetYMin,
        max = O.FontOffsetYMax,
        step = 1,
      },
      ShadowOffset = {
        type = 'range',
        name = 'Shadow',
        order = 4,
        min = O.FontShadowOffsetMin,
        max = O.FontShadowOffsetMax,
        step = 1,
      },
    },
  }
end

-------------------------------------------------------------------------------
-- CreateTextValueOptions
--
-- Creates dynamic drop down options for text value names and types
--
-- Subfunction of CreateTextOptions()
--
-- BarType        Options will be added for this bar.
-- TL             Current Text Line options being used.
-- TxtLine        Used to retrieve what text line number is being used.
-- Order          Order number in the options frame.
-------------------------------------------------------------------------------
local function ModifyTextValueOptions(BarType, VOA, Action, ValueName, ValueIndex)
  local ValueNameMenu = DUB[BarType].Text._ValueNameMenu
  local ValueNameDropdown = ValueNameMenuDropdown[ValueNameMenu]

  local ValueNameKey = format('ValueName%s', ValueIndex)
  local ValueTypeKey = format('ValueType%s', ValueIndex)

  if Action == 'add' then
    VOA[ValueNameKey] = {
      type = 'select',
      name = format('Value Name %s', ValueIndex),
      values = ValueNameDropdown,
      order = 10 * ValueIndex + 1,
      arg = ValueIndex,
    }
    VOA[ValueTypeKey] = {
      type = 'select',
      name = format('Value Type %s', ValueIndex),
      disabled = function()
                   -- Disable if the ValueName is not found in the menu.
                   return ValueName[ValueIndex] == 'none' or
                          ValueNameDropdown[ConvertValueName[ValueName[ValueIndex]]] == nil
                 end,
      values = function()
                 local VName = ValueName[ValueIndex]
                 if ValueNameDropdown[ConvertValueName[VName]] == nil then

                   -- Valuename not found in the menu so return an empty menu
                   return ValueType_NoneDropdown
                 else
                   return ValueTypeMenuDropdown[VName]
                 end
               end,
      order = 10 * ValueIndex + 2,
      arg = ValueIndex,
    }
    VOA[format('Spacer%s', 10 * ValueIndex + 3)] = CreateSpacer(10 * ValueIndex + 3)

  elseif Action == 'remove' then
    VOA[ValueNameKey] = nil
    VOA[ValueTypeKey] = nil
    VOA[format('Spacer%s', 10 * ValueIndex + 3)] = nil
  end
end

local function CreateTextValueOptions(BarType, TL, TxtLine, Order)
  local UBF = UnitBarsF[BarType]
  local UB = UBF.UnitBar
  local ValueNameMenu = DUB[BarType].Text._ValueNameMenu

  local TS = UB.Text[TxtLine[TL.name]]
  local ValueName = TS.ValueName
  local ValueType = TS.ValueType
  local NumValues = 0
  local MaxValueNames = O.MaxValueNames
  local VOA = nil

  TL.args.Value = {
    type = 'group',
    name = 'Value',
    order = Order,
    dialogInline = true,
    get = function(Info)
            local St = Info[#Info]
            local ValueIndex = Info.arg

            if strfind(St, 'ValueName') then

              -- Check if the valuename is not found in the menu.
              return ConvertValueName[ValueName[ValueIndex]]

            elseif strfind(St, 'ValueType') then
              return ConvertValueType[ValueType[ValueIndex]]
            end
          end,
    set = function(Info, Value)
            local St = Info[#Info]
            local ValueIndex = Info.arg

            if strfind(St, 'ValueName') then
              local VName = ConvertValueName[Value]
              ValueName[ValueIndex] = VName

              -- ValueType menu may have changed, so we need to update ValueType.
              local Dropdown = ValueTypeMenuDropdown[VName]
              local Value = ConvertValueType[ValueType[ValueIndex]]

              if Dropdown[Value] == nil then
                Value = 100
                for Index, _ in pairs(Dropdown) do
                  if Value > Index then
                    Value = Index
                  end
                end
                ValueType[ValueIndex] = ConvertValueType[Value]
              end
            elseif strfind(St, 'ValueType') then
              ValueType[ValueIndex] = ConvertValueType[Value]
            end

            -- Update the font.
            UBF:SetAttr('Text', '_Font')
          end,
    args = {
      Layout = {
        type = 'input',
        name = function()
                 if TS.Custom then
                   return 'Custom Layout'
                 else
                   return 'Layout'
                 end
               end,
        order = 1,
        multiline = true,
        width = 'double',
        desc = 'To customize the layout change it here',
        get = function()
                return gsub(TS.Layout, '|', '||')
              end,
        set = function(Info, Value)
                TS.Custom = true
                TS.Layout = gsub(Value, '||', '|')

                -- Update the bar.
                UBF:SetAttr('Text', '_Font')
              end,
      },
      Spacer2 = CreateSpacer(2),
      RemoveValue = {
        type = 'execute',
        name = 'Remove',
        order = 3,
        width = 'half',
        desc = 'Remove a value',
        disabled = function()

                     -- Hide the tooltip since the button will be disabled.
                     return HideTooltip(NumValues == 1)
                   end,
        func = function()
                 ModifyTextValueOptions(BarType, VOA, 'remove', ValueName, NumValues)

                 -- remove last value type.
                 tremove(ValueName, NumValues)
                 tremove(ValueType, NumValues)

                 NumValues = NumValues - 1

                 -- Update the font to reflect changes
                 UBF:SetAttr('Text', '_Font')
               end,
      },
      AddValue = {
        type = 'execute',
        name = 'Add',
        order = 4,
        width = 'half',
        desc = 'Add another value',
        disabled = function()

                     -- Hide the tooltip since the button will be disabled.
                     return HideTooltip(NumValues == MaxValueNames)
                   end,
        func = function()
                 NumValues = NumValues + 1
                 ModifyTextValueOptions(BarType, VOA, 'add', ValueName, NumValues)

                 -- Add a new value setting.
                 ValueName[NumValues] = DUB[BarType].Text[1].ValueName[1]
                 ValueType[NumValues] = DUB[BarType].Text[1].ValueType[1]

                 -- Update the font to reflect changes
                 UBF:SetAttr('Text', '_Font')
               end,
      },
      Spacer5 = CreateSpacer(5, 'half'),
      ExitCustomLayout = {
        type = 'execute',
        name = 'Exit',
        order = 6,
        width = 'half',
        hidden = function()
                   return HideTooltip(not TS.Custom)
                 end,
        desc = 'Exit custom layout mode',
        func = function()
                 TS.Custom = false

                 -- Call setattr to reset layout without changing the text settings.
                 UBF:SetAttr()
               end,
      },
      Spacer7 = CreateSpacer(7),
    },
  }

  VOA = TL.args.Value.args

  -- Add additional value options if needed
  for Index, _ in ipairs(ValueName) do
    ModifyTextValueOptions(BarType, VOA, 'add', ValueName, Index)
    NumValues = Index
  end
end

-------------------------------------------------------------------------------
-- CreateTextLineOptions
--
-- Creates a new set of options for a textline, each one will have a new number.
--
-- Subfunction of CreateTextOptions()
--
-- BarType           Bar the options will be added for.
-- TextLineOptions   Used for recursive calls. On recursive calls more
--                   options are inserted into this table.
-- TxtLine           Used to convert TextLineOptions.name into a number.
-------------------------------------------------------------------------------
local function CreateTextLineOptions(BarType, TextLineOptions, TxtLine)
  local UBF = UnitBarsF[BarType]
  local UB = UBF.UnitBar
  local Text = UB.Text

  local TL = nil
  local TextLine = 0
  local TextLineKey = ''
  local MaxTextLines = O.MaxTextLines
  local NumValues = 0
  local Line = 'Line%s'
  local LineName = 'Line %s'

  if TextLineOptions == nil then
    TextLineOptions = {}
  end

  -- Find a new text line.
  while true do
    TextLine = TextLine + 1
    TextLineKey = format(Line, TextLine)

    if TextLineOptions[TextLineKey] == nil then
      TL = {
        type = 'group',
        name = format(LineName, TextLine),
        order = 10,
        args = {},
      }
      TextLineOptions[TextLineKey] = TL
      break
    end
  end

  if TxtLine == nil then
    TxtLine = {}
  end

  -- Set the txtline table with the current text line number.
  if TxtLine[TL.name] == nil then
    TxtLine[TL.name] = TextLine
  end

  -- Check to see if another text line needs to be created.
  if UB.Text[TextLine + 1] ~= nil then
    CreateTextLineOptions(BarType, TextLineOptions, TxtLine)
  end

  TL.args = {
    RemoveTextLine = {
      type = 'execute',
      name = 'Remove',
      width = 'half',
      order = 1,
      name = function()
               return format('- Line %s', TxtLine[TL.name])
             end,
      desc = function()
               return format('Remove Text Line %s', TxtLine[TL.name])
             end,
      disabled = function()
                 local TextLine = TxtLine[TL.name]

                 -- Hide the tooltip since the button will be disabled.
                 return HideTooltip(TextLine == 1 and TextLineOptions[format(Line, TextLine + 1)] == nil)
               end,
      confirm = function()
                  return format('Remove Text Line %s ?', TxtLine[TL.name])
                end,
      func = function()
               local Index = TxtLine[TL.name]

               -- Delete the text setting.
               tremove(Text, Index)

               -- Delete the curent text line options and move all others down one.
               local TL = ''
               local TLO = nil
               local TextLineKey = ''

               repeat
                 TLO = TextLineOptions[format(Line, Index + 1)]

                 if TLO ~= nil then
                   TextLineKey = format(Line, Index)

                   TextLineOptions[TextLineKey] = TLO
                   TextLineOptions[TextLineKey].name = format(LineName, Index)

                   Index = Index + 1
                 end
               until TLO == nil

               -- Delete the last text line.
               TextLineOptions[format(Line, Index)] = nil

               -- Update the the bar to reflect changes
               UBF:SetAttr('Text', '_Font')
             end,
    },
    AddTextLine = {
      type = 'execute',
      order = 2,
      name = function()
               return format('+ Line %s', TxtLine[TL.name] + 1)
             end,
      desc = function()
               return format('Add Text Line %s', TxtLine[TL.name] + 1)
             end,
      width = 'half',
      disabled = function()
                 local TextLine = TxtLine[TL.name]

                 -- Hide the tooltip since the button will be disabled.
                 return HideTooltip(TextLine == MaxTextLines or TextLineOptions[format(Line, TextLine + 1)] ~= nil)
               end,
      func = function()

               -- Add text on to end.
               -- Deep Copy first text setting from defaults into text table.
               local TextTable = {}

               Main:CopyTableValues(DUB[BarType].Text[1], TextTable, true)
               Text[#Text + 1] = TextTable

               -- Add options for new text line.
               CreateTextLineOptions(BarType, TextLineOptions, TxtLine)

               -- Update the the bar to reflect changes
               UBF:SetAttr('Text', '_Font')
             end,
    },
    Seperator = {
      type = 'header',
      name = '',
      order = 3,
    },
  }

  -- Add text value options to TextLineOptions
  CreateTextValueOptions(BarType, TL, TxtLine, 4)

  -- Add text font options.
  CreateTextFontOptions(BarType, TL, TxtLine, 5)

  return TextLineOptions
end

-------------------------------------------------------------------------------
-- CreateTextOptions
--
-- Creates dyanmic text options for a unitbar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType               Type options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- TextOptions     Options table for text options.
--
-- NOTES:  Since DoFunction is being used.  When it gets called UnitBarF[].UnitBar
--         is not upto date at that time.  So Main.UnitBars[BarType] must be used
--         instead.
-------------------------------------------------------------------------------
local function CreateTextOptions(BarType, Order, Name)
  local TextOptions = {
    type = 'group',
    name = Name,
    order = Order,
  }
  local TxtLine = {
    [Name] = 1,
  }

  -- This will modify text options table if the profile changed.
  -- Basically rebuild the text options when ever the profile changes.
  Options:DoFunction(BarType, 'CreateTextOptions', function()
    if DUB[BarType].Text._Multi then
      TextOptions.childGroups = 'tab'
      TextOptions.args = CreateTextLineOptions(BarType)
    else
      TextOptions.args = {}

      -- Add text value and font options.
      CreateTextValueOptions(BarType, TextOptions, TxtLine, 1)
      CreateTextFontOptions(BarType, TextOptions, TxtLine, 2)
    end
  end)

  -- Set up the options
  Options:DoFunction(BarType, 'CreateTextOptions')

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
  local ConditionValue = 'ConditionValue' .. HexSt
  local ConditionDelete = 'ConditionDelete' .. HexSt
  local ConditionSpacer = 'ConditionSpacer' .. HexSt

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
            return FindMenuItem(TriggerOperatorDropdown[Trigger.ValueTypeID], Condition.Operator)
          end,
    set = function(Info, Value)
            Condition.Operator = TriggerOperatorDropdown[Trigger.ValueTypeID][Value]

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
             if Trigger.ValueTypeID == 'percent' then
               return 'Enter a number between 0 and 100'
             else
               return 'Enter any number'
             end
           end,
    get = function()
            -- Turn into a string. Input takes strings.
            return tostring(Condition.Value)
          end,
    set = function(Info, Value)
            -- Change to number
            Condition.Value = floor(tonumber(Value) or 0)

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
      Own = {
        type = 'toggle',
        name = 'Own',
        desc = 'This aura must be cast by you',
        order = 3,
        width = 'half',
      },
      Spacer10 = CreateSpacer(10),
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
    }
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
        min = O.TriggerBarOffsetAllMin,
        max = O.TriggerBarOffsetAllMax,
        step = 1,
      },
      Left = {
        type = 'range',
        name = 'Left',
        order = 4,
        hidden = function()
                   return Trigger.OffsetAll
                 end,
        min = O.TriggerBarOffsetLeftMin,
        max = O.TriggerBarOffsetLeftMax,
        step = 1,
      },
      Right = {
        type = 'range',
        name = 'Right',
        order = 5,
        hidden = function()
                   return Trigger.OffsetAll
                 end,
        min = O.TriggerBarOffsetRightMin,
        max = O.TriggerBarOffsetRightMax,
        step = 1,
      },
      Top = {
        type = 'range',
        name = 'Top',
        order = 6,
        hidden = function()
                   return Trigger.OffsetAll
                 end,
        min = O.TriggerBarOffsetTopMin,
        max = O.TriggerBarOffsetTopMax,
        step = 1,
      },
      Bottom = {
        type = 'range',
        name = 'Bottom',
        order = 7,
        hidden = function()
                   return Trigger.OffsetAll
                 end,
        min = O.TriggerBarOffsetBottomMin,
        max = O.TriggerBarOffsetBottomMax,
        step = 1,
      },
    },
  }

  return OffsetOption
end

-------------------------------------------------------------------------------
-- AddTriggerOption
--
-- Adds an option window under a group to modify the trigger settings.
--
-- SubFunction of CreateTriggerOptions
--
-- BarType         Type of bar being worked on.
-- UBF             Unitbar frame to access the bar functions.
-- BBar            The bar object to access the bar DB functions.
-- GroupNames      Quick access to keyname for groups.
-- TOA             Trigger option arguments. Trigger options get added here.
-- Groups          So each option knows what pull down menus to use, etc
-- Triggers        Whole triggers table.
-- ClipBoard       Clipboard to swap, copy, move triggers.
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

    elseif TypeID == 'baroffset' then
      p1, p2, p3, p4 = tonumber(p1) or 0, tonumber(p2) or 0, tonumber(p3) or 0, tonumber(p4) or 0

    elseif strfind(TypeID, 'color') then
      p1, p2, p3, p4 = tonumber(p1) or 1, tonumber(p2) or 1, tonumber(p3) or 1, tonumber(p4) or 1

    elseif strfind(TypeID, 'fontoffset') then
      p3, p4 = nil, nil
      p1, p2 = tonumber(p1) or 0, tonumber(p2) or 0

      -- check for out of bounds
      if p1 < O.FontOffsetXMin or p1 > O.FontOffsetXMax then
        p1 = 0
      end
      if p2 < O.FontOffsetYMin or p2 > O.FontOffsetYMax then
        p2 = 0
      end
    elseif TypeID == 'fontsize' then
      local Default = (O.FontSizeMin + O.FontSizeMax) / 2
      p2, p3, p4 = nil, nil, nil

      p1 = tonumber(p1) or Default

      -- check for out of bounds
      if p1 < O.FontSizeMin or p1 > O.FontSizeMax then
        p1 = Default
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
               local TypeID = Trigger.TypeID
               local Texture = nil
               local rgb = '0.7, 0.7, 0.7'

               if TypeID == 'fontcolor' then
                 Texture = TriggerTextColorIcon
               elseif strfind(TypeID, 'color') then
                 Texture = TriggerColorIcon
               elseif strfind(TypeID, 'border') then
                 Texture = TriggerBorderIcon
               elseif TypeID == 'background' then
                 Texture = TriggerBackgroundIcon
               elseif TypeID == 'texturescale' or TypeID == 'baroffset' then
                 Texture = TriggerChangeSizeIcon
               elseif strfind(TypeID, 'bar') then
                 Texture = TriggerBarIcon
               elseif TypeID == 'fontsize' or TypeID == 'fontoffset' then
                 Texture = TriggerTextChangeSizeIcon
               elseif TypeID == 'fonttype' then
                 Texture = TriggerTextTypeIcon
               elseif TypeID == 'fontstyle' then
                 Texture = TriggerTextOutlineIcon
               elseif TypeID == 'sound' then
                 Texture = TriggerSoundIcon
               end

               if not Trigger.Enabled then
                 rgb = '0.75, 0, 0'
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
    Spacer8 = CreateSpacer(8, 'full', function() return not Trigger.Select end),
    ActionType = {
      type = 'input',
      order = 9,
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
      order = 10,
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
      order = 11,
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
    ActionSpacer12 = CreateSpacer(12, 'half', function() return not Trigger.Select end),
    ActionUtil = {
      type = 'input',
      order = 13,
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
                   return not Trigger.Enabled
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
                       return Trigger.Static or not Trigger.Enabled
                     end,
        },
        Type = {
          type = 'select',
          name = 'Type',
          order = 2,
          desc = 'Type of trigger',
          values = function()
                     return Group.Types
                   end,
          style = 'dropdown',
        },
        Spacer5 = CreateSpacer(5, nil, function()
                                         local TypeID = Trigger.TypeID

                                         return Trigger.TextMultiLine == nil or TypeID ~= 'fontcolor' and TypeID ~= 'fontoffset' and
                                                TypeID ~= 'fontsize' and TypeID ~= 'fonttype'
                                       end),
        TextLine = {
          type = 'select',
          name = 'Text Line',
          order = 6,
          values = TextLineDropdown,
          style = 'dropdown',
          hidden = function()
                     local TypeID = Trigger.TypeID

                     return Trigger.TextMultiLine == nil or TypeID ~= 'fontcolor' and TypeID ~='fontoffset' and
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
          min = O.TriggerTextureScaleMin,
          max = O.TriggerTextureScaleMax,
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
          min = O.FontOffsetXMin,
          max = O.FontOffsetXMax,
          step = 1,
          hidden = function()
                     return Trigger.TypeID ~= 'fontoffset'
                   end,
        },
        ParsTextOffsetY = {
          type = 'range',
          name = 'Vertical',
          order = 19,
          min = O.FontOffsetYMin,
          max = O.FontOffsetYMax,
          step = 1,
          hidden = function()
                     return Trigger.TypeID ~= 'fontoffset'
                   end,
        },
        ParsTextSize = {
          type = 'range',
          name = 'Size',
          order = 20,
          min = O.FontSizeMin,
          max = O.FontSizeMax,
          step = 1,
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
                   return not Trigger.Enabled
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
          desc = 'Hide auras',
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
                       return ClipBoard.Move ~= nil or #Triggers == 1
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
             BBar:CheckTriggers()
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

  if UBD.Status.HideNotUsable ~= nil then
    StatusArgs.HideNotUsable = {
      type = 'toggle',
      name = 'Hide not Usable',
      order = 1,
      desc = 'Hides the bar if it can not be used by your class or spec.  Bar will stay hidden even with bars unlocked or in test mode',
    }
  end
  StatusArgs.ShowAlways = {
    type = 'toggle',
    name = 'Show Always',
    order = 2,
    desc = "Always show the bar in and out of combat.  Doesn't override Hide not Usuable",
  }
  StatusArgs.HideWhenDead = {
    type = 'toggle',
    name = 'Hide when Dead',
    order = 3,
    desc = "Hides the bar when you're dead",
  }
  StatusArgs.HideNoTarget = {
    type = 'toggle',
    name = 'Hide no Target',
    order = 4,
    desc = 'Hides the bar when you have no target selected',
  }
  StatusArgs.HideInVehicle = {
    type = 'toggle',
    name = 'Hide in Vehicle',
    order = 5,
    desc = "Hides the bar when you're in a vehicle",
  }
  StatusArgs.HideInPetBattle = {
    type = 'toggle',
    name = 'Hide in Pet Battle',
    order = 6,
    desc = "Hides the bar when you're in a pet battle",
  }
  if UBD.Status.HideNotActive ~= nil then
    StatusArgs.HideNotActive = {
      type = 'toggle',
      name = 'Hide not Active',
      order = 7,
      desc = 'Bar will be hidden if its not active. This only gets checked out of combat',
    }
  end
  StatusArgs.HideNoCombat = {
    type = 'toggle',
    name = 'Hide no Combat',
    order = 8,
    desc = 'When not in combat the bar will be hidden',
  }

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
            UBF.UnitBar.TestMode[KeyName] = Value

            -- Update the bar to show test mode changes.
            UBF:SetAttr('TestMode', KeyName)
          end,
    hidden = function()
               return not Main.UnitBars.Testing
             end,
    args = {},
  }
  local TestModeArgs = TestModeOptions.args

  if UBD.TestMode.ShowEmpoweredChi ~= nil then
    TestModeArgs.ShowEmpoweredChi = {
      type = 'toggle',
      name = 'Show Empowered Chi',
      order = 1,
    }
  end
  if UBD.TestMode.ShowDeathRunes ~= nil then
    TestModeArgs.ShowDeathRunes = {
      type = 'toggle',
      name = 'Show Death Runes',
      desc = 'Shows death runes',
      order = 2,
    }
  end
  if UBD.TestMode.ShowMeta ~= nil then
    TestModeArgs.ShowMeta = {
      type = 'toggle',
      name = 'Show Metamorphosis',
      desc = 'Show metamorphosis',
      order = 3,
    }
  end
  if UBD.TestMode.ShowFiery ~= nil then
    TestModeArgs.ShowFiery = {
      type = 'toggle',
      name = 'Show Fiery Embers',
      desc = 'Show fiery embers',
      order = 4,
    }
  end
  if UBD.TestMode.ShowEnhancedShadowOrbs then
    TestModeArgs.ShowEnhancedShadowOrbs = {
      type = 'toggle',
      name = 'Show Enhanced Shadow Orbs',
      order = 5,
      width = 'double',
    }
  end
  if UBD.TestMode.Value ~= nil then
    TestModeArgs.Value = {
      type = 'range',
      name = 'Value',
      order = 100,
      desc = 'Change the bars value',
      step = .01,
      width = 'double',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.PredictedValue ~= nil then
    TestModeArgs.PredictedValue = {
      type = 'range',
      name = 'Predicted Value',
      order = 101,
      desc = 'Change the precicted value',
      step = .01,
      width = 'double',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.Time ~= nil then
    TestModeArgs.Time = {
      type = 'range',
      name = 'Time',
      order = 102,
      desc = 'Change the amount of time',
      step = .01,
      width = 'double',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.Recharge ~= nil then
    TestModeArgs.Recharge = {
      type = 'range',
      name = 'Recharge',
      order = 103,
      desc = 'Change the number of runes recharging',
      width = 'double',
      step = 1,
      min = O.TestModeRechargeMin,
      max = O.TestModeRechargeMax,
    }
  end
  if UBD.TestMode.Energize ~= nil then
    TestModeArgs.Energize = {
      type = 'range',
      name = 'Empowerment',
      order = 104,
      desc = 'Change a rune to empowered. Max turns them all to empowered',
      width = 'double',
      step = 1,
      min = O.TestModeEnergizeMin,
      max = O.TestModeEnergizeMax,
    }
  end

  return TestModeOptions
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
    dialogInline = true,
    order = Order,
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
  }

  local LayoutArgs = LayoutOptions.args
  local Spacer = false

  if UBD.Layout.BoxMode ~= nil then
    Spacer = true
    LayoutArgs.BoxMode = {
      type = 'toggle',
      name = 'Box Mode',
      order = 1,
      desc = 'Switches from texture mode to box mode',
    }
  end
  if Spacer then
    LayoutArgs.Spacer10 = CreateSpacer(10)
    Spacer = false
  end
  if UBD.Layout.EnableTriggers ~= nil then
    Spacer = true
    LayoutArgs.EnableTriggers = {
      type = 'toggle',
      name = 'Enable Triggers',
      order = 11,
      desc = 'Acitvates all triggers for this bar and shows the trigger options',
    }
  end
  if UBD.Layout.HideRegion ~= nil then
    Spacer = true
    LayoutArgs.HideRegion = {
      type = 'toggle',
      name = 'Hide Region',
      order = 12,
      desc = "Hides the bar's region",
    }
  end
  if Spacer then
    LayoutArgs.Spacer20 = CreateSpacer(20)
    Spacer = false
  end

  if UBD.Layout.Swap ~= nil then
    Spacer = true
    LayoutArgs.Swap = {
      type = 'toggle',
      name = 'Swap',
      order = 21,
      desc = 'Allows you to swap one bar object with another by dragging it',
    }
  end
  if UBD.Layout.Float ~= nil then
    Spacer = true
    LayoutArgs.Float = {
      type = 'toggle',
      name = 'Float',
      order = 22,
      desc = 'Switches to floating mode.  Bar objects can be placed anywhere. Float options will be open below',
    }
  end
  if Spacer then
    LayoutArgs.Spacer30 = CreateSpacer(30)
    Spacer = false
  end

  if UBD.Layout.ReverseFill ~= nil then
    Spacer = true
    LayoutArgs.ReverseFill = {
      type = 'toggle',
      name = 'Reverse fill',
      order = 31,
      desc = 'Fill in reverse',
    }
  end
  if UBD.Layout.HideText ~= nil then
    Spacer = true
    LayoutArgs.HideText = {
      type = 'toggle',
      name = 'Hide Text',
      order = 32,
      desc = 'Hides all text',
    }
  end
  if Spacer then
    LayoutArgs.Spacer40 = CreateSpacer(40)
    Spacer = false
  end

  if UBD.Layout.BorderPadding ~= nil then
    Spacer = true
    LayoutArgs.BorderPadding = {
      type = 'range',
      name = 'Border Padding',
      order = 41,
      desc = "Changes the distance between the region's border and the bar objects",
      step = 1,
      disabled = function()
                   return UBF.UnitBar.Layout.HideRegion
                 end,
      min = O.LayoutBorderPaddingMin,
      max = O.LayoutBorderPaddingMax,
    }
  end
  if UBD.Layout.Rotation ~= nil then
    Spacer = true
    LayoutArgs.Rotation = {
      type = 'range',
      name = 'Rotation',
      order = 42,
      desc = 'Changes the orientation of the bar objects',
      step = 45,
      disabled = function()
                   return Flag(false, UBF.UnitBar.Layout.Float)
                 end,
      min = O.LayoutRotationMin,
      max = O.LayoutRotationMax,
    }
  end
  if Spacer then
    LayoutArgs.Spacer50 = CreateSpacer(50)
    Spacer = false
  end

  if UBD.Layout.Slope ~= nil then
    Spacer = true
    LayoutArgs.Slope = {
      type = 'range',
      name = 'Slope',
      order = 51,
      desc = 'Makes the bar objects slope up or down when the rotation is horizontal or vertical',
      step = 1,
      disabled = function()
                   return Flag(false, UBF.UnitBar.Layout.Float) or UBF.UnitBar.Layout.Rotation % 90 ~= 0
                 end,
      min = O.LayoutSlopeMin,
      max = O.LayoutSlopeMax,
    }
  end
  if UBD.Layout.Padding ~= nil then
    Spacer = true
    LayoutArgs.Padding = {
      type = 'range',
      name = 'Padding',
      order = 52,
      desc = 'Changes the space between each bar object',
      step = 1,
      disabled = function()
                   return Flag(false, UBF.UnitBar.Layout.Float)
                 end,
      min = O.LayoutPaddingMin,
      max = O.LayoutPaddingMax,
    }
  end
  if Spacer then
    LayoutArgs.Spacer60 = CreateSpacer(60)
    Spacer = false
  end

  if UBD.Layout.SmoothFill ~= nil then
    Spacer = true
    LayoutArgs.SmoothFill = {
      type = 'range',
      name = 'Smooth Fill',
      order = 61,
      desc = 'The amount of time in seconds to do a smooth fill update',
      step = 0.01,
      min = O.LayoutSmoothFillMin,
      max = O.LayoutSmoothFillMax,
    }
  end
  if UBD.Layout.TextureScale ~= nil then
    Spacer = true
    LayoutArgs.TextureScale = {
      type = 'range',
      name = 'Texture Scale',
      order = 62,
      desc = 'Changes the texture size of the bar objects',
      step = 0.01,
      isPercent = true,
      disabled = function()
                   return BarType ~= 'RuneBar' and Flag(true, UBF.UnitBar.Layout.BoxMode) or
                          BarType == 'RuneBar' and strsub(UBF.UnitBar.General.RuneMode, 1, 4) ~= 'rune'
                 end,
      min = O.LayoutTextureScaleMin,
      max = O.LayoutTextureScaleMax,
    }
  end
  if Spacer then
    LayoutArgs.Spacer70 = CreateSpacer(70)
    Spacer = false
  end

  if UBD.Layout.FadeInTime ~= nil then
    Spacer = true
    LayoutArgs.FadeInTime = {
      type = 'range',
      name = BarType == 'EmberBar' and 'Fiery Ember Fade-in' or
             BarType == 'EclipseBar' and 'Eclipse Fade-in' or
             'Fade-in',
      order = 71,
      desc = 'Amount of time in seconds to fade in a bar object',
      step = 0.1,
      min = O.LayoutFadeInTimeMin,
      max = O.LayoutFadeInTimeMax,
    }
  end
  if UBD.Layout.FadeOutTime ~= nil then
    Spacer = true
    LayoutArgs.FadeOutTime = {
      type = 'range',
      name = BarType == 'EmberBar' and 'Fiery Ember Fade-out' or
             BarType == 'EclipseBar' and 'Eclipse Fade-out' or
             'Fade-out',
      order = 72,
      desc = 'Amount of time in seconds to fade out a bar object',
      step = 0.1,
      min = O.LayoutFadeOutTimeMin,
      max = O.LayoutFadeOutTimeMax,
    }
  end
  if Spacer then
    LayoutArgs.Spacer100 = CreateSpacer(100)
    Spacer = false
  end

  -- Float options
  if UBD.Layout.Float ~= nil then
    LayoutArgs.FloatOptions = {
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
              min = O.LayoutAlignPaddingXMin,
              max = O.LayoutAlignPaddingXMax,
            },
            AlignPaddingY = {
              type = 'range',
              name = 'Padding Vertical',
              order = 12,
              desc = 'Sets the distance between two or more bar objects that are aligned vertically',
              step = 1,
              min = O.LayoutAlignPaddingXMin,
              max = O.LayoutAlignPaddingXMax,
            },
            Spacer20 = CreateSpacer(20),
            AlignOffsetX = {
              type = 'range',
              name = 'Horizontal Offset',
              order = 21,
              desc = 'Offsets the padding group',
              step = 1,
              min = O.LayoutAlignOffsetXMin,
              max = O.LayoutAlignOffsetXMax,
            },
            AlignOffsetY = {
              type = 'range',
              name = 'Vertical Offset',
              order = 22,
              desc = 'Offsets the padding group',
              step = 1,
              min = O.LayoutAlignOffsetYMin,
              max = O.LayoutAlignOffsetYMax,
            },
          },
        },
      },
    }
    if UBF.UnitBar.Layout.Float ~= nil then
      local FloatArgs = LayoutArgs.FloatOptions.args

      FloatArgs.Spacer30 = CreateSpacer(30)
      FloatArgs.ResetFloat = {
        type = 'execute',
        name = 'Reset Float',
        order = 3,
        desc = 'Resets the floating layout by copying the normal mode layout to float',
        confirm = true,
        disabled = function()
                     return not UBF.UnitBar.Layout.Float
                   end,
        func = function()
                 UBF.BBar:ResetFloatBar()
                 UBF.BBar:Display()
               end
      }
    end
  end

  return LayoutOptions
end

-------------------------------------------------------------------------------
-- CreateGeneralOptions
--
-- Subfunction of CreateUnitBarOptions
--
-- Creates general options for all bars.  This includes options that don't
-- fit into layout options.
--
-- BarType     Type of bar options being craeted for.
-- Order       Where to place options on screen.
-- Name        Name of the options.
-------------------------------------------------------------------------------
local function CreateGeneralOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local GeneralOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.General[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local Gen = UBF.UnitBar.General

            if KeyName == 'ClassColor' and Value then
              Gen.CombatColor = false
            elseif KeyName == 'CombatColor' and Value then
              Gen.ClassColor = false
            end

            Gen[KeyName] = Value
            UBF:SetAttr('General', KeyName)
          end,
    args = {}
  }

  local GeneralArgs = GeneralOptions.args

  -- Health and power bar options.
  if UBD.General.UseBarColor ~= nil then
    GeneralArgs.UseBarColor = {
      type = 'toggle',
      name = 'Use Bar Color',
      order = 1,
      desc = 'Use bar color instead of power color',
    }
  end
  if UBD.General.PredictedHealth ~= nil then
    GeneralArgs.PredictedHealth = {
      type = 'toggle',
      name = 'Predicted Health',
      order = 2,
      desc = 'Predicted health will be shown',
    }
  end
  if UBD.General.PredictedPower ~= nil then
    GeneralArgs.PredictedPower = {
      type = 'toggle',
      name = 'Predicted Power',
      order = 3,
      desc = 'Predicted power will be shown (Hunters Only)',
    }
  end
  if UBD.General.ClassColor ~= nil then
    GeneralArgs.ClassColor = {
      type = 'toggle',
      name = 'Class Color',
      order = 4,
      desc = 'Show class color',
    }
  end
  if UBD.General.CombatColor ~= nil then
    GeneralArgs.CombatColor = {
      type = 'toggle',
      name = 'Combat Color',
      order = 5,
      desc = 'Show combat color',
    }
  end
  if UBD.General.TaggedColor ~= nil then
    GeneralArgs.TaggedColor = {
      type = 'toggle',
      name = 'Tagged Color',
      order = 6,
      desc = 'Shows if the target is tagged by another player',
    }
  end

  if BarType == 'AnticipationBar' or BarType == 'MaelstromBar' then
    local BarName = BarType == 'AnticipationBar' and 'anticipation' or 'maelstrom'

    if UBD.General.HideCharges ~= nil then
      GeneralArgs.HideCharges = {
        type = 'toggle',
        name = 'Hide Charges',
        order = 1,
        desc = format('Hides the %s charges', BarName),
        disabled = function()
                     return UBF.UnitBar.General.HideTime
                   end,
      }
    end

    if UBD.General.HideTime ~= nil then
      GeneralArgs.HideTime = {
        type = 'toggle',
        name = 'Hide Time',
        order = 1,
        desc = format('Hides the %s timer', BarName),
        disabled = function()
                     return UBF.UnitBar.General.HideCharges
                   end,
      }
    end

    if UBD.General.ShowSpark ~= nil then
      GeneralArgs.ShowSpark = {
        type = 'toggle',
        name = 'Show Spark',
        order = 2,
        desc = format('Shows a spark on the %s timer', BarName),
      }
    end
  end

  -- Ember bar options.
  if UBD.General.GreenFire ~= nil then
    GeneralArgs.GreenFire = {
      type = 'toggle',
      name = 'Green Fire',
      order = 1,
      desc = 'Use green fire',
      disabled = function()
                   return UBF.UnitBar.General.GreenFireAuto
                 end,
    }
  end
  if UBD.General.GreenFireAuto ~= nil then
    GeneralArgs.GreenFireAuto = {
      type = 'toggle',
      name = 'Green Fire Auto',
      order = 4,
      desc = 'Use green fire if available',
      disabled = function()
                   return UBF.UnitBar.General.GreenFire
                 end,
    }
  end

  return GeneralOptions
end

-------------------------------------------------------------------------------
-- CreateGeneralRuneBarOptions
--
-- Creates options for a Rune Bar.
--
-- Subfunction of CreateUnitBarOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateGeneralRuneBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local GeneralRuneBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.General[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            UBF.UnitBar.General[KeyName] = Value

            -- Update the layout to show changes.
            UBF:SetAttr('General', KeyName)
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
      EnergizeShow = {
        type = 'select',
        name = 'Empowerment',
        order = 2,
        desc = 'Select the way empowerment is shown',
        values = RuneEnergizeDropdown,
        style = 'dropdown',
      },
      Spacer20 = CreateSpacer(20),
      CooldownAnimation = {
        type = 'toggle',
        name = 'Cooldown Animation',
        order = 21,
        hidden = function()
                   return strfind(UBF.UnitBar.General.RuneMode, 'rune') == nil
                 end,
        desc = 'Shows the cooldown animation',
      },
      HideCooldownFlash = {
        type = 'toggle',
        name = 'Hide Flash',
        order = 22,
        hidden = function()
                   return strfind(UBF.UnitBar.General.RuneMode, 'rune') == nil
                 end,
        disabled = function()
                     return not UBF.UnitBar.General.CooldownAnimation
                   end,
        desc = 'Hides the flash animation after a rune comes off cooldown',
      },
      Spacer30 = CreateSpacer(30),
      BarSpark = {
        type = 'toggle',
        name = 'Bar Spark',
        order = 31,
        hidden = function()
                   return UBF.UnitBar.General.RuneMode == 'rune'
                 end,
        desc = 'Shows a spark on the bar animation',
      },
      CooldownLine = {
        type = 'toggle',
        name = 'Cooldown Line',
        order = 32,
        hidden = function()
                   return strfind(UBF.UnitBar.General.RuneMode, 'rune') == nil
                 end,
        disabled = function()
                     return not UBF.UnitBar.General.CooldownAnimation
                   end,
        desc = 'Shows a line on the cooldown animation',
      },
      RuneLocation = {
        type = 'group',
        name = 'Rune Location',
        dialogInline = true,
        order = 32,
        set = function(Info, Value)
                local KeyName = Info[#Info]
                UBF.UnitBar.General[KeyName] = Value

                -- Update the rune location.
                UBF:SetAttr('General', '_RuneLocation')
              end,
        hidden = function()
                   return UBF.UnitBar.General.RuneMode ~= 'runebar'
                 end,
        args = {
          RuneOffsetX = {
            type = 'range',
            name = 'Horizontal Offset',
            order = 1,
            min = O.RuneOffsetXMin,
            max = O.RuneOffsetYMax,
            step = 1,
          },
          RuneOffsetY = {
            type = 'range',
            name = 'Vertical Offset',
            order = 2,
            min = O.RuneOffsetYMin,
            max = O.RuneOffsetYMax,
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
      RuneEnergize = {
        type = 'group',
        name = 'Empowerment',
        dialogInline = true,
        order = 33,
        hidden = function()
                   return UBF.UnitBar.General.EnergizeShow == 'none'
                 end,
        args = {
          EnergizeTime = {
            type = 'range',
            name = 'Time',
            order = 1,
            desc = 'Amount of time to wait before removing empowerment overlay',
            min = O.RuneEnergizeTimeMin,
            max = O.RuneEnergizeTimeMax,
            step = 1,
          },
          Color = CreateColorAllOptions(BarType, 'General', 'General.ColorEnergize', 'ColorEnergize', 2, 'Color'),
        },
      },
    },
  }
  return GeneralRuneBarOptions
end

-------------------------------------------------------------------------------
-- CreateGeneralEclipseBarOptions
--
-- Creates options for a eclipse bar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateGeneralEclipseBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local GeneralEclipseBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.General[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            UBF.UnitBar.General[KeyName] = Value

            UBF:SetAttr('General', KeyName)
          end,
    args = {
      SliderInside = {
        type = 'toggle',
        name = 'Slider Inside',
        order = 1,
        desc = 'The slider will stay inside the bar',
      },
      HideSlider = {
        type = 'toggle',
        name = 'Hide Slider',
        order = 2,
        desc = 'The slider will be hidden',
      },
      PowerHalfLit = {
        type = 'toggle',
        name = 'Power Half Lit',
        order = 3,
        desc = 'The lunar or solar part will light to show slider direction',
      },
      PowerText = {
        type = 'toggle',
        name = 'Power Text',
        order = 4,
        desc = 'Eclipse power text will be shown',
        disabled = function()
                     return UBF.UnitBar.Layout.HideText
                   end,
      },
      HidePeak = {
        type = 'toggle',
        name = 'Hide Peak',
        order = 5,
        desc = 'The sun and moon will not light up during a solar or lunar peak',
      },
      Spacer10 = CreateSpacer(10),
      SliderDirection = {
        type = 'select',
        name = 'Slider Direction',
        order = 11,
        values = DirectionDropdown,
        style = 'dropdown',
        desc = 'Specifies the direction the slider will move in'
      },
    },
  }
  return GeneralEclipseBarOptions
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
-- NOTES:  Exact = true means the KeyName must match exactly to the UnitBar data.
--         Name is the name of the check box.
-------------------------------------------------------------------------------
local function CreateResetOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
  local DBd = DUB[BarType]
  local Enabled = {}

  TableData = TableData or {
    {Name = 'All'},
    {Name = 'Location', KeyName = {'x', 'y'},                             Exact = true},
    {Name = 'Status',   KeyName = 'Status',                               Exact = true},
    {Name = 'Test',     KeyName = 'TestMode',                             Exact = true,  Desc = 'Test Mode'},
    {Name = 'Layout',   KeyName = {'Layout', 'BoxLocations', 'BoxOrder'}, Exact = true},
    {Name = 'General',  KeyName = 'General',                              Exact = true},
    {Name = 'Other',    KeyName = 'Other',                                Exact = true},
    {Name = 'BG',       KeyName = 'Background',                           Exact = false, Desc = 'Background'},
    {Name = 'Bar',      KeyName = 'Bar',                                  Exact = false},
    {Name = 'Text',     KeyName = 'Text',                                 Exact = true},
    {Name = 'Triggers', KeyName = 'Triggers',                             Exact = true},
  }

  local ResetOptions = {
    type = 'group',
    name = Name,
    order = Order,
    get = function(Info)
            local Index = Info.arg
            local Name = TableData[Index].Name

            if Enabled[Name] ~= nil then
              return Main.UnitBars.Reset[Name]
            else
              return false
            end
          end,
    set = function(Info, Value)
            local Index = Info.arg
            local Name = TableData[Index].Name

            if Enabled[Name] ~= nil then
              Main.UnitBars.Reset[Name] = Value
            end
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
                 local OldUB = nil

                 if Main.UnitBars.Reset.All then
                   Main:CopyTableValues(DUB[BarType], UB, true)
                 else
                   OldUB = {}

                   Main:CopyTableValues(UB, OldUB, true)
                   for k, v in pairs(OldUB) do

                     -- search for key in the TableData
                     local FoundIndex = 0
                     local Checked = false
                     local Table = false

                     for Index = 1, #TableData do
                       local TD = TableData[Index]

                       if TD.Name ~= 'All' then
                         local KeyName = TD.KeyName
                         local Exact = TD.Exact
                         local Found = false

                         -- If KeyName is a table then search all names inside of it.
                         if type(KeyName) == 'table' then
                           for _, Name in pairs(KeyName) do
                             if not Exact and strfind(k, Name) or Exact and Name == k then
                               Found = true
                               break
                             end
                           end
                         elseif not Exact and strfind(k, KeyName) or Exact and KeyName == k then
                           Found = true
                         end
                         if Found then
                           Checked = Main.UnitBars.Reset[TableData[Index].Name]
                           FoundIndex = Index
                           break
                         end
                       end
                     end
                     if type(v) == 'table' then
                       Table = true
                     end
                     if FoundIndex > 0 then
                       if Checked then
                         if not Table then -- copy key
                           UB[k] = DBd[k]
                         elseif DBd[k] then  -- copy table
                           Main:CopyTableValues(DBd[k], UB[k], true)
                         else -- empty table
                           wipe(UB[k])
                         end
                       end
                     elseif not Table then -- not found and not on list
                       UB[k] = DBd[k]
                     end
                   end
                 end
                 -- Update the layout.
                 Main.Reset = true

                 UBF:SetAttr()
                 UBF:StatusCheck()
                 UBF:Update()

                 -- Update any dynamic options.
                 Options:DoFunction()

                 Main.Reset = false
                 OldUB = nil
               end,
        disabled = function()
                     local Disabled = true

                     for Index = 1, #TableData do
                       local Name = TableData[Index].Name

                       if Enabled[Name] and Main.UnitBars.Reset[Name] then
                         Disabled = false
                       end
                     end
                     return Disabled
                   end,
      },
      Spacer20 = CreateSpacer(20),
      Notes = {
        type = 'description',
        name = 'Check off what to reset, then click reset',
        order = 21,
        hidden = function()
                   return Main.UnitBars.Reset.Minimize
                 end
      },
      Spacer100 = CreateSpacer(100),
    },
  }
  local Args = ResetOptions.args

  -- Create check boxes
  for Index, Table in ipairs(TableData) do
    local Name = Table.Name

    Args[Name] = {
      type = 'toggle',
      name = Name,
      desc = Table.Desc,
      order = 100 + Index,
      width = Name ~= 'Background' and 'half' or nil,
      arg = Index,
      hidden = function()
                 local Minimize = Main.UnitBars.Reset.Minimize

                 if Name == 'All' then
                   return Minimize
                 else
                   return Minimize or Main.UnitBars.Reset.All
                 end
               end,
      disabled = function()
                   return Enabled[Name] == nil
                 end,
    }
  end

  -- initialize Enabled
  for Index = 1, #TableData do
    local TD = TableData[Index]
    local KeyName = TD.KeyName
    local Name = TD.Name

    if Name == 'All' or type(KeyName) == 'table' then
      Enabled[Name] = true
    else
      for k, v in pairs(DUB[BarType]) do
        if type(v) == 'table' and strfind(k, KeyName) then
          Enabled[Name] = true
          break
        end
      end
    end
  end

  return ResetOptions
end

-------------------------------------------------------------------------------
-- CreateOtherOptions
--
-- SubFunction of CreateUnitBarOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateOtherOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local OtherOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            local KeyName = Info[#Info]

            if KeyName == 'FrameStrata' then
              return ConvertFrameStrata[UBF.UnitBar.Other.FrameStrata]
            else
              return UBF.UnitBar.Other[KeyName]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            if KeyName == 'FrameStrata' then
              Value = ConvertFrameStrata[Value]
            end
            UBF.UnitBar.Other[KeyName] = Value
            UBF:SetAttr('Other', KeyName)
          end,
    args = {
      Scale = {
        type = 'range',
        name = 'Scale',
        order = 1,
        desc = 'Changes the scale of the bar',
        min = O.UnitBarScaleMin,
        max = O.UnitBarScaleMax,
        step = 1,
        step = 0.01,
        isPercent  = true,
      },
      FrameStrata = {
        type = 'select',
        name = 'Frame Strata',
        order = 2,
        desc = 'Sets the frame strata making the bar appear below or above other frames',
        values = FrameStrataDropdown,
        style = 'dropdown',
      },
    },
  }
  OtherOptions.args.ResetOptions = CreateResetOptions(BarType, 3, 'Reset', OtherOptions)

  return OtherOptions
end

-------------------------------------------------------------------------------
-- CreateCopyPasteOptions
--
-- Creates options for to copy and paste bars.
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateCopyPasteOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
  local BBar = UBF.BBar

  MenuButtons = MenuButtons or {
    Main = { Order = 1, Width = 'half',
      { Name = 'All'       , All = false, TablePath = ''                  },
      { Name = 'Status'    , All = true,  TablePath = 'Status'            },
      { Name = 'Layout'    , All = true,  TablePath = 'Layout'            },
      { Name = 'Other'     , All = true,  TablePath = 'Other'             }},

    Background = { Order = 2, Width = 'normal',
      { Name = 'Background', All = true,  TablePath = 'Background'        },
      { Name = 'Moon'      , All = true,  TablePath = 'BackgroundMoon'    },
      { Name = 'Power'     , All = true,  TablePath = 'BackgroundPower'   },
      { Name = 'Sun'       , All = true,  TablePath = 'BackgroundSun'     },
      { Name = 'Slider'    , All = true,  TablePath = 'BackgroundSlider'  },
      { Name = 'Charges'   , All = true,  TablePath = 'BackgroundCharges' },
      { Name = 'Time'      , All = true,  TablePath = 'BackgroundTime'    }},

    Bar = { Order = 3, Width = 'half',
      { Name = 'Bar'       , All = true,  TablePath = 'Bar'               },
      { Name = 'Moon'      , All = true,  TablePath = 'BarMoon'           },
      { Name = 'Power'     , All = true,  TablePath = 'BarPower'          },
      { Name = 'Sun'       , All = true,  TablePath = 'BarSun'            },
      { Name = 'Slider'    , All = true,  TablePath = 'BarSlider'         },
      { Name = 'Charges'   , All = true,  TablePath = 'BarCharges'        },
      { Name = 'Time'      , All = true,  TablePath = 'BarTime'           }},

    Text = { Order = 4, Width = 'half',
      { Name = 'All Text'  , All = false, TablePath = 'Text'              },
      { Name = 'Text 1'    , All = true,  TablePath = 'Text.1'            },
      { Name = 'Text 2'    , All = true,  TablePath = 'Text.2'            },
      { Name = 'Text 3'    , All = true,  TablePath = 'Text.3'            },
      { Name = 'Text 4'    , All = true,  TablePath = 'Text.4'            }},

    Triggers = { Order = 5, Width = 'half',
      { Name = 'Triggers'  , All = true,  TablePath = 'Triggers'          }}
  }

  local CopyPasteOptions = {
    type = 'group',
    name = function()
             if ClipBoard then
               return format('%s: |cffffff00%s [ %s ]|r', Name, ClipBoard.BarName or '', ClipBoard.SelectButtonName)
             else
               return Name
             end
           end,
    dialogInline = true,
    order = Order,
    confirm = function(Info)
                local Name = Info[#Info]

                if ClipBoard then
                  if Name == 'AppendTriggers' then
                    return format('Append Triggers from %s to\n%s', DUB[BarType].Name, DUB[ClipBoard.BarType].Name)

                  else
                    -- Paste
                    local Arg = Info.arg
                    local PasteName = Arg and Arg.PasteName

                    if Name ~= 'Clear' then
                      if PasteName then
                        return format('Copy %s [ %s ] to \n%s [ %s ]', ClipBoard.BarName or '', ClipBoard.SelectButtonName, DUB[BarType].Name, PasteName)
                      else
                        return format('Copy %s [ %s ] to %s', ClipBoard.BarName or '', ClipBoard.SelectButtonName, DUB[BarType].Name)
                      end
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
               ClipBoard.TablePath = Arg.TablePath
               ClipBoard.BarName = UBF.UnitBar.Name
               ClipBoard.MenuButtonName = Arg.MenuButtonName
               ClipBoard.SelectButtonName = Arg.SelectButtonName
               ClipBoard.TextNumber = Arg.TextNumber
               ClipBoard.AllButton = Arg.AllButton
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

                 if ClipBoard.SelectButtonName == 'All' then
                   for SelectIndex, SelectButton in pairs(MenuButtons) do
                     for _, SB in ipairs(SelectButton) do
                       if SB.All then
                         local TablePath = SB.TablePath

                         Main:CopyUnitBar(ClipBoard.BarType, BarType, TablePath, TablePath)
                       end
                     end
                   end
                 else
                   local TablePath = Arg and Arg.TablePath or ClipBoard.TablePath

                   Main:CopyUnitBar(ClipBoard.BarType, BarType, ClipBoard.TablePath, TablePath)
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
               -- Update any text highlights.  We use 'on' since its always on when options are opened.
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
    order = 10,
    width = 'full',
  }

  -- Create menu buttons
  for MenuButtonName, MenuButton in pairs(MenuButtons) do
    local Found = false

    -- Check for to see if any tables exist.
    for _, SelectButton in ipairs(MenuButton) do
      if Main:GetUB(BarType, SelectButton.TablePath) ~= nil then
        Found = true
        break
      end
    end

    if Found then
      if Main:GetUB(BarType, MenuButton.TablePath) ~= nil then
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
                       return ClipBoard ~= nil and ClipBoard.MenuButtonName ~= MenuButtonName
                     end,
          set = function()
                  SelectedMenuButtonName = MenuButtonName
                end,
          get = function() end,
        }
        local GA = {}

        Args[MenuButtonName .. '_Group'] = {
          type = 'group',
          name = '',
          order = 11,
          hidden = function()
                     return SelectedMenuButtonName ~= MenuButtonName
                   end,
          args = GA,
        }

        -- Create clear and paste buttons
        GA.Clear = {
          type = 'execute',
          name = 'Clear',
          order = 11,
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

        -- Create select buttons
        for SelectIndex, SelectButton in ipairs(MenuButton) do
          local AllButton = not SelectButton.All
          local SelectButtonName = SelectButton.Name
          local TablePath = SelectButton.TablePath
          local Text = strfind(TablePath, 'Text') ~= nil
          local TextNumber = nil

          if Text and TablePath ~= 'Text' then
            TextNumber = SelectIndex - 1
          end

          -- Create paste buttons for text.
          if Text then
            GA['PasteText' .. SelectIndex] = {
              type = 'execute',
              name = format('Paste (%s)', SelectButtonName),
              order = SelectIndex + 12,
              width = 'normal',
              hidden = function()
                         if ClipBoard then
                           -- Only allow past over existing text lines
                           if not AllButton and TextNumber > #UBF.UnitBar.Text then
                             return true
                           elseif ClipBoard.BarType == BarType then
                             return AllButton or ClipBoard.AllButton or ClipBoard.SelectButtonName == SelectButtonName
                           else
                             return ClipBoard.AllButton ~= AllButton
                           end
                         else
                           return true
                         end
                       end,
              arg = {TablePath = TablePath, PasteName = SelectButtonName},
            }
          else
            if SelectIndex == 1 then

              -- Create standard paste button
              GA.Paste = {
                type = 'execute',
                name = 'Paste',
                desc = function()
                         return 'Click to paste ' .. ClipBoard.SelectButtonName
                       end,
                order = 12,
                width = 'half',
                hidden = function()
                           return ClipBoard == nil or ClipBoard.MenuButtonName == 'Text'
                         end,
                disabled = function()
                             return ClipBoard.BarType == BarType
                           end,
              }
              -- Create append triggers.
              if MenuButtonName == 'Triggers' then
                GA.AppendTriggers = {
                  type = 'execute',
                  name = 'Append',
                  desc = 'Click to add triggers to your existing triggers',
                  order = 13,
                  width = 'half',
                  hidden = function()
                             return ClipBoard == nil
                           end,
                  disabled = function()
                               return ClipBoard.BarType == BarType
                             end,
                }
              end
            end
          end

          if Main:GetUB(BarType, TablePath) ~= nil or ( Text and not AllButton ) or MenuButtonName == 'Triggers' then
            GA[SelectButtonName] = {
              type = 'execute',
              order = SelectIndex,
              name = SelectButtonName,
              width = SelectButtonName == 'Background' and 'normal' or 'half',
              hidden = function()
                         return ClipBoard ~= nil
                       end,
              disabled = function()
                           -- Disable if the text# doesn't exist.
                           return Text and Main:GetUB(BarType, TablePath) == nil
                         end,
              arg = {TablePath = TablePath,
                     MenuButtonName = MenuButtonName,
                     SelectButtonName = SelectButtonName,
                     TextNumber = TextNumber,
                     AllButton = AllButton},
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
    name = Name,
    order = Order,
    desc = Desc,
    args = {},
  }

  local OptionArgs = UnitBarOptions.args

  -- Create Status options.
  OptionArgs.Status = CreateStatusOptions(BarType, 1, 'Status')

  -- Create test mode options.
  if UBD.TestMode ~= nil then
    OptionArgs.TestMode = CreateTestModeOptions(BarType, 2, 'Test Mode')
  end

  -- Create Layout options
  if UBD.Layout then
    OptionArgs.Layout = CreateLayoutOptions(BarType, 3, 'Layout')
  end

  -- Create General options.
  if UBD.General then
    if BarType == 'RuneBar' then
      OptionArgs.General = CreateGeneralRuneBarOptions(BarType, 4, 'General')
    elseif BarType == 'EclipseBar' then
      OptionArgs.General = CreateGeneralEclipseBarOptions(BarType, 4, 'General')
    else
      OptionArgs.General = CreateGeneralOptions(BarType, 4, 'General')
    end
    -- Delete general if it has no options.
    if next(OptionArgs.General.args) == nil then
      OptionArgs.General = nil
    end
  end

  -- Create Other options.
  if UBD.Other then
    OptionArgs.Other = CreateOtherOptions(BarType, 5, 'Other')
  end

  OptionArgs.CopyPaste = CreateCopyPasteOptions(BarType, 6,'Copy and Paste')

  -- Add border options if they exists.
  if UBD.Region then
    OptionArgs.Border = CreateBackdropOptions(BarType, 'Region', 1000, 'Region')
    OptionArgs.Border.hidden = function()
                                 return Flag(true, UBF.UnitBar.Layout.HideRegion)
                               end
  end

  -- Add background/bar options for anticipation bar or eclipse bar
  if BarType == 'AnticipationBar' or BarType == 'MaelstromBar' or BarType == 'EclipseBar' then
    OptionArgs.Background = {
      type = 'group',
      name = 'Background',
      order = 1001,
      childGroups = 'tab',
    }
    if BarType == 'AnticipationBar' or BarType == 'MaelstromBar' then
      OptionArgs.Background.args = {
        Points = CreateBackdropOptions(BarType, 'BackgroundCharges', 1, 'Charges'),
        Time = CreateBackdropOptions(BarType, 'BackgroundTime', 2, 'Time'),
      }
    else
      OptionArgs.Background.args = {
        Moon = CreateBackdropOptions(BarType, 'BackgroundMoon', 1, 'Moon'),
        Sun = CreateBackdropOptions(BarType, 'BackgroundSun', 2, 'Sun'),
        Power = CreateBackdropOptions(BarType, 'BackgroundPower', 3, 'Power'),
        Slider = CreateBackdropOptions(BarType, 'BackgroundSlider', 4, 'Slider'),
      }
    end
    OptionArgs.Bar = {
      type = 'group',
      name = 'Bar',
      order = 1002,
      childGroups = 'tab',
    }
    if BarType == 'AnticipationBar' or BarType == 'MaelstromBar' then
      OptionArgs.Bar.args = {
        Points = CreateBarOptions(BarType, 'BarCharges', 1, 'Charges'),
        Time = CreateBarOptions(BarType, 'BarTime', 2, 'Time'),
      }
    else
      OptionArgs.Bar.args = {
        Moon = CreateBarOptions(BarType, 'BarMoon', 1, 'Moon'),
        Sun = CreateBarOptions(BarType, 'BarSun', 2, 'Sun'),
        Power = CreateBarOptions(BarType, 'BarPower', 3, 'Power'),
        Slider = CreateBarOptions(BarType, 'BarSlider', 4, 'Slider'),
      }
    end
  else

    -- Add background options
    OptionArgs.Background = CreateBackdropOptions(BarType, 'Background', 1001, 'Background')
    if BarType == 'RuneBar' then
      OptionArgs.Background.hidden = function()
                                       return UBF.UnitBar.General.RuneMode == 'rune'
                                     end
    else
      OptionArgs.Background.hidden = function()
                                       return not Flag(true, UBF.UnitBar.Layout.BoxMode)
                                     end
    end

    -- add bar options for this bar.
    OptionArgs.Bar = CreateBarOptions(BarType, 'Bar', 1002, 'Bar')
    if BarType == 'RuneBar' then
      OptionArgs.Bar.hidden = function()
                                return UBF.UnitBar.General.RuneMode == 'rune'
                              end
    else
      OptionArgs.Bar.hidden = function()
                                return not Flag(true, UBF.UnitBar.Layout.BoxMode)
                              end
    end
  end

  -- Add text options
  if UBD.Text ~= nil then
    OptionArgs.Text = CreateTextOptions(BarType, 1003, 'Text')
    OptionArgs.Text.hidden = function()
                               return UBF.UnitBar.Layout.HideText
                             end
  end

  -- Add trigger options
  if UBD.Triggers ~= nil then
    OptionArgs.Triggers = CreateTriggerOptions(BarType, 1004, 'Triggers')
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
        local Name, _, Icon = GetSpellInfo(SpellID)
        Order = Order + 1

        local AuraInfo = {
          type = 'input',
          width = 'full',
          name = format('%s:24:14:(|cFF00FF00%s|r)', SpellID, SpellID),
          dialogControl = 'GUB_Spell_Info',
          get = function() end,
          set = function() end,
        }

        SortList[Order] = {Name = Name, AuraInfo = AuraInfo}
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
  for Key, _ in pairs(ALA) do
    if strfind(Key, 'AuraGroup') then
      ALA[Key] = nil
    end
  end
end

local function UpdateAuraTabs(ALA, Order)
  local TrackedAurasList = Main.TrackedAurasList
  local OrderNumber = Order

  if TrackedAurasList then
    for Unit, _ in pairs(TrackedAurasList) do
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
    for Key, _ in pairs(ALA) do
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
                 Main:CopyTableValues(DUB.PowerColor, Main.UnitBars.PowerColor)

                 -- Set the color to all the bars
                 for _, UBF in ipairs(Main.UnitBarsFE) do
                   UBF:Update()
                 end
               end,
      },
    },
  }

  -- Power types for the player power bar. '= 0' has no meaning.
  -- These cover classes with more than one power type.
  local PlayerPower = {
    DRUID = {MANA = 0, ENERGY = 0, RAGE = 0},
    MONK  = {MANA = 0, ENERGY = 0},
  }

  local PCOA = PowerColorOptions.args
  local ClassPowerType = PlayerPower[Main.PlayerClass]
  local Index = 0

  for PowerType, _ in pairs(Main.UnitBars.PowerColor) do
    local PowerTypeName = ConvertPowerType[PowerType]
    Index = Index + 1
    local Order = Index + 50
    local n = gsub(strlower(PowerTypeName), '%a', strupper, 1)

    if ClassPowerType and ClassPowerType[PowerTypeName] then
      Order = Index
    elseif PowerType == Main.PlayerPowerType then
      Order = 1
    end

    local Width = 'half'
    if PowerTypeName == 'RUNIC_POWER' then
      n = 'Runic Power'
      Width = 'normal'
    end

    PCOA[PowerTypeName] = {
      type = 'color',
      name = n,
      order = Order,
      width = Width,
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
  local ClassColorMenu = {
    'DEATHKNIGHT', 'DRUID',  'HUNTER', 'MAGE',  'MONK',
    'PALADIN',     'PRIEST', 'PRIEST', 'ROGUE', 'SHAMAN',
    'WARLOCK',     'WARRIOR'
  }

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
        desc = 'Use tagged color if unit is tagged',
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
  for Index, ClassName in ipairs(ClassColorMenu) do
    local Order = Index + 50
    local n = gsub(strlower(ClassName), '%a', strupper, 1)

    if ClassName == Main.PlayerClass then
      Order = 1
    end

    local Width = 'half'
    if Index == 1 then
      n = 'Death Knight'
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
        desc = 'Use tagged color if unit is tagged',
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
-- CreateHelpOptions
--
-- Displays help and links
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateHelpOptions(Order, Name)
  local HelpOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    args = {
      HelpText = {
        type = 'group',
        name = function()
                 return format('|cffffd200%s   version %.2f|r', AddonName, Version / 100)
               end,
        order = 10,
        args = {},
      },
    },
  }

  local HTA = HelpOptions.args.HelpText.args

  for HelpIndex = 1, #HelpText do
    local Text = HelpText[HelpIndex]
    local HelpKey = 'HelpText' .. HelpIndex
    local Pos = strfind(Text, 'http')

    if Pos then
      local Name = strsub(Text, 1, Pos - 1)
      local Link = strsub(Text, Pos)

      HTA[HelpKey] = {
        type = 'input',
        name = Name or '',
        order = HelpIndex,
        width = 'double',
        dialogControl = 'GUB_EditBox_Selected',
        get = function()
                return format('|Cffffff00%s|r', Link)
              end,
        set = function() end,
      }
    else
      HTA[HelpKey] = {
        type = 'description',
        name = Text,
        fontSize = 'medium',
        order = HelpIndex,
        width = 'full',
      }
    end
    HTA['Spacer' .. HelpIndex] = CreateSpacer(HelpIndex + 0.5)
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
                GUB:UnitBarsUpdateStatus()

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
              Fading = {
                name = 'Fading',
                type = 'group',
                order = 3,
                dialogInline = true,
                args = {
                  ReverseFading = {
                    type = 'toggle',
                    name = 'Reverse Fading',
                    order = 1,
                    desc = 'Fading in/out can switch direction smoothly',
                  },
                  FadeInTime = {
                    type = 'range',
                    name = 'Fade-in',
                    order = 8,
                    desc = 'The amount of time in seconds to fade in a bar',
                    min = 0,
                    max = O.FadeInTime,
                    step = 0.1,
                    get = function()
                            return Main.UnitBars.FadeInTime
                          end,
                    set = function(Info, Value)
                            Main.UnitBars.FadeInTime = Value
                            Main:UnitBarsSetAllOptions()
                          end,
                  },
                  FadeOutTime = {
                    type = 'range',
                    name = 'Fade-out',
                    order = 9,
                    desc = 'The amount of time in seconds to fade out a bar',
                    min = 0,
                    max = O.FadeOutTime,
                    step = 0.1,
                    get = function()
                            return Main.UnitBars.FadeOutTime
                          end,
                    set = function(Info, Value)
                            Main.UnitBars.FadeOutTime = Value
                            Main:UnitBarsSetAllOptions()
                          end,
                  },
                },
              },
            },
          },
          Colors = {
            type = 'group',
            name = 'Colors',
            order = 4,
            args = {
              PowerColors = CreatePowerColorOptions(5, 'Power Color'),
              ClassColors = CreateClassColorOptions(6, 'Class Color'),
              CombatColors = CreateCombatColorOptions(7, 'Combat Color'),
              TaggedColor = CreateTaggedColorOptions(8, 'Tagged color'),
            },
          },
          AuraList = CreateAuraOptions(5, 'Aura List'),
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
  MainOptionsArgs.Help = CreateHelpOptions(101, 'Help')

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
    for KeyName, _ in pairs(AlignSwapOptions.args) do
      local SliderArgs = AlignSwapOptions.args[KeyName]
      local Min = nil
      local Max = nil

      if strfind(KeyName, 'Padding') then
        Min = O.AlignSwapPaddingMin
        Max = O.AlignSwapPaddingMax
      elseif strfind(KeyName, 'Offset') then
        Min = O.AlignSwapOffsetMin
        Max = O.AlignSwapOffsetMax
      end
      if Min and Max then
        local Value = Main.UnitBars[KeyName]

        if Main.UnitBars.AlignSwapAdvanced then
          Value = Value < Min and Min or Value > Max and Max or Value
          Main.UnitBars[KeyName] = Value
          SliderArgs.min = Value - O.AlignSwapAdvancedMinMax
          SliderArgs.max = Value + O.AlignSwapAdvancedMinMax
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
              local BarX, BarY = Bar:GetRect(AlignSwapAnchor)

              BarX, BarY = floor(BarX + 0.5), floor(BarY + 0.5)
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
              AlignSwapAnchor:ClearAllPoints()
              AlignSwapAnchor:SetPoint('TOPLEFT', UB.x, UB.y)
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
                 return format('Bar Location (%s)', AlignSwapAnchor.Name)
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

    AceConfigDialog:SetDefaultSize(AddonAlignSwapOptions, O.AlignSwapWidth, O.AlignSwapHeight)
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
