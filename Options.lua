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
local strupper, strlower, strfind, format, strmatch, strsplit, strsub, strtrim =
      strupper, strlower, strfind, format, strmatch, strsplit, strsub, strtrim
local tonumber, gsub, min, max, tremove, tinsert, wipe, strsub =
      tonumber, gsub, min, max, tremove, tinsert, wipe, strsub
local ipairs, pairs, type, next, sort, select =
      ipairs, pairs, type, next, sort, select
local InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print, GameTooltip, message, GetSpellInfo =
      InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print, GameTooltip, message, GetSpellInfo
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
  TriggerTextureSizeMin = 0.1,
  TriggerTextureSizeMax = 5,

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

local Condition_WholePercentDropdown = {
  '<',             -- 1
  '>',             -- 2
  '<=',            -- 3
  '>=',            -- 4
  '=',             -- 5
  '<>',            -- 6
  'Static',        -- 7
}

local Condition_BooleanDropdown = {
  '=', -- 1
  'Static', -- 2
}

local Condition_AurasDropdown = {
  'and',    -- 1
  'or',     -- 2
  'Static', -- 3
}

local TriggerConditionDropdown = {
  ['whole']        = Condition_WholePercentDropdown,
  ['percent']      = Condition_WholePercentDropdown,
  ['boolean']      = Condition_BooleanDropdown,
  ['auras']        = Condition_AurasDropdown,
}

local TriggerBooleanDropdown = {
  'True', -- 1
  'False', -- 2
}

local TriggerSoundChannelDropdown = {
  Ambience = 'Ambience',
  Master = 'Master',
  Music = 'Music',
  SFX = 'Sound Effects',
  Dialog = 'Dialog',
}

local TriggerActionDropdown = {
  'Add',
  'Delete',
  'Name',
  'Swap',
  'Disable',
  'Move',
  'Copy',
  'None',
}

local AuraStackConditionDropdown = {
  '<',             -- 1
  '>',             -- 2
  '<=',            -- 3
  '>=',            -- 4
  '=',             -- 5
  '<>',            -- 6
}

--*****************************************************************************
--
-- Options Utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- FindMenuItem
--
-- Searches for a Value in an indexed array. Returns the Index found. or 0
--
-- Table       Any indexed array
-- Value       Value to search for.  Must be an exact match. Case is not sensitive.
--
-- Returns:
--   Index    Table element containing value
--   Item     Returns the item found in the menu in lowercase. If item is not found then
--            this equals the first item in the menu.
-------------------------------------------------------------------------------
local function FindMenuItem(Table, Value, IgnoreChar)
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
-- BarType         BarType to save the function under.
-- Name            Name to use to call the function.
--                 if 'clear' then all the functions under BarType are erased.
-- Fn              Function to be saved. If fn is nil then FunctionName() gets called.
--                 if 'erase' then will erase the function.
--
-- Returns:
--   Function      The function that was passed.
-------------------------------------------------------------------------------
function GUB.Options:DoFunction(BarType, Name, Fn)
  if Fn then

    -- Save the function under BarType FunctionName
    local DoFunction = DoFunctions[BarType]

    if DoFunction == nil then
      DoFunction = {}
      DoFunctions[BarType] = DoFunction
    end

    if Fn == 'erase' then
      Fn = nil
    end
    DoFunction[Name] = Fn

    return Fn
  elseif Name == 'clear' then
    if DoFunctions[BarType] then

      -- Wipe the table instead of nilling. Incase this function gets called thru DoFunction.
      wipe(DoFunctions[BarType])
    end
  elseif Name then

    -- Call function by name
    DoFunctions[BarType][Name]()
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
  local Names = UBF.Names.Color

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
  local DoCreateText = Options:DoFunction(BarType, 'CreateTextOptions', function()
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
  DoCreateText()

  return TextOptions
end

-------------------------------------------------------------------------------
-- AurasFound
--
-- Returns true if any auras are found
--
-- Subfunction of AddTriggerOption()
-------------------------------------------------------------------------------
local function AurasFound(Auras)
  local Found = false

  if Auras then
    for SpellID, Aura in pairs(Auras) do
      if type(Aura) == 'table' then
        return true
      end
    end
  end
  return false
end

-------------------------------------------------------------------------------
-- TriggersFound
--
-- Subfunction CreateTriggerListOptions()
--
-- returns true if there are any triggers found based on the
-- TriggerData.GroupNumber selected.
-------------------------------------------------------------------------------
local function TriggersFound(TriggerData)
  local GroupNumber = TriggerData.GroupNumber

  for TriggerIndex = 1, #TriggerData do
    if TriggerData[TriggerIndex].GroupNumber == GroupNumber then
      return true
    end
  end
  return false
end

-------------------------------------------------------------------------------
-- UpdateTriggerOrderNumbers
--
-- Subfunction of AddTriggerOption(), CreateTriggerListOptions()
--
-- This updates the index counters for each of the triggers.
-- Instead of showing the real trigger numbers, I keep a sequencial list
-- in each bar group.
--
-- TriggerData         All the triggers
-- GroupNames          Each name for bar objects.
-- TriggerOrderNumber  Turns a trigger number into an order number.
--                     This also can returns the max number of triggers
--                     for a certain group.
-------------------------------------------------------------------------------
local function UpdateTriggerOrderNumbers(TriggerData, GroupNames, TriggerOrderNumber)
  local NumTriggers = #TriggerData

  for Index = 1, #GroupNames do
    local Counter = 0

    for TriggerIndex = 1, NumTriggers do
      if TriggerData[TriggerIndex].GroupNumber == Index then
        Counter = Counter + 1
        TriggerOrderNumber[TriggerIndex] = Counter
      end
    end
    -- Store max index per group under -GroupNumber
    TriggerOrderNumber[-Index] = Counter
  end

  -- Truncate TriggerOrderNumber
  for Index = NumTriggers + 1, #TriggerOrderNumber do
    TriggerOrderNumber[Index] = nil
  end
end

-------------------------------------------------------------------------------
-- UpdateTriggerData
--
-- Modifies the trigger data based on the values set in TD.
-- If anything is incorrect this corrects it.
--
-- SubFunction of AddTriggerOption(), CreateTriggerListOptions()
--
-- TD                         Trigger data
-- GroupNumber                Bar object
-- TriggerTypeDropdown        Menu for different trigger types. Background, Border Color, etc
-- TriggerValueTypeDropdown   Value types for TriggerTypeDropdown
-- TriggerConditionDropdown   Menu for picking a condition, <, >, >=, etc
-- TypeIDs                    Contains the different Type identifiers for each group.
-- ValueTypeIDs               Contains the valueType identifiers for each group.
--
-- Returns
--   TypeIndex                This is used to get the correct barfunction inside of ModifyTriggers in bar.lua.
-------------------------------------------------------------------------------
local function UpdateTriggerData(TD, GroupNumber, TriggerTypeDropdown, TriggerValueTypeDropdown, TriggerConditionDropdown, TypeIDs, ValueTypeIDs)
  local TypeIndex = nil
  local ValueType = nil

  -- Find menu items
  local TypeIndex, Type = FindMenuItem(TriggerTypeDropdown[GroupNumber], TD.Type)

  -- Type not found, search by TypeID
  if Type ~= TD.Type then
    local TDTypeID = TD.TypeID

    for Type2, TypeID in pairs(TypeIDs[GroupNumber]) do
      if TypeID == TDTypeID then
        TypeIndex, Type = FindMenuItem(TriggerTypeDropdown[GroupNumber], Type2)
        break
      end
    end
  end

  local TypeID = TypeIDs[GroupNumber][Type]

  _, ValueType = FindMenuItem(TriggerValueTypeDropdown[GroupNumber], TD.ValueType)
  local ValueTypeID = ValueTypeIDs[GroupNumber][ValueType]

  _, TD.Condition = FindMenuItem(TriggerConditionDropdown[ValueTypeID], TD.Condition)

  local Pars = TD.Pars
  local GetPars = TD.GetPars
  local Change = false

  if not ( strfind(TypeID, 'color') and strfind(TD.TypeID, 'color') ) then
    Change = TypeID ~= TD.TypeID
  end

  if TD.Condition == 'static' then
    TD.GetFnTypeID = 'none'
  end

  -- Set default Pars when changing to a different type or moving to a different bar object.
  if TypeID == 'backgroundcolor' or TypeID == 'bordercolor' or TypeID == 'bartexturecolor' then
    if Change then
      Pars[1] = 1
      Pars[2] = 1
      Pars[3] = 1
      Pars[4] = 1
    end
  elseif TypeID == 'getclassbackgroundcolor' or TypeID == 'getclassbordercolor' or TypeID == 'getclassbartexturecolor' then
    if Change then
      GetPars[1] = ''
      GetPars[2] = ''
      GetPars[3] = ''
      GetPars[4] = ''
    end
  else
    local Pars1 = Pars[1]
    local Pars2 = Pars[2]

    if TypeID == 'sound' then
      Pars[3] = nil
      Pars[4] = nil

      if LSMSoundDropdown[Pars1] == nil then
        Pars[1] = DefaultSound
      end
      if TriggerSoundChannelDropdown[Pars2] == nil then
        Pars[2] = DefaultSoundChannel
      end
    else
      Pars[2] = nil
      Pars[3] = nil
      Pars[4] = nil
      if TypeID == 'texturesize' then
        if Change then
          Pars[1] = 1
        end
      elseif TypeID == 'bartexture' then
        if LSMStatusBarDropdown[Pars1] == nil then
          Pars[1] = DefaultStatusBarTexture
        end
      elseif TypeID == 'border' then
        if LSMBorderDropdown[Pars1] == nil then
          Pars[1] = DefaultBorderTexture
        end
      elseif TypeID == 'background' then
        if LSMBackgroundDropdown[Pars1] == nil then
          Pars[1] = DefaultBgTexture
        end
      end
    end
  end

  TD.Type = Type
  TD.TypeID = TypeID
  TD.ValueTypeID = ValueTypeID
  TD.ValueType = ValueType
  TD.GroupNumber = GroupNumber

  if ValueTypeID == 'boolean' then
    TD.Value = 1 -- true
  end

  return TypeIndex
end

-------------------------------------------------------------------------------
-- ModifyAuraOptions
--
-- Manages the aura options
--
-- Subfunction of AddTriggerOption()
--
-- Usage:  ModifyAuraOptions('create', Order, BBar, TriggerNumber, TO, TD)
--         ModifyAuraOptions('add', Order, BBar, TriggerNumber, TO, TD, Index, SpellID)
--         ModifyAuraOptions('clear', TO, TD)
--
-- TO             TriggerOptions aceconfig table options
-- Action          'create' will create all the aura options
--                 'add'    will add one aura option
--                 'clear'  will only clear the aura options, not the auras.
-- Order          What position to start placing the aura options in the trigger options panel.
-- BBar           Contains the bar object being used by this bar.
-- TriggerNumber  Current trigger the aura options belong to.
-- Index          Order + Index position for the aura.
-- TD             Trigger data
-- SpellID        ID of the aura to add an option for.
-------------------------------------------------------------------------------
local function ModifyAuraOptions(Action, ...)
  local AuraGroupSt = 'AuraGroup%s'

  if Action == 'create' then
    local Order = select(1, ...)
    local BBar = select(2, ...)
    local TriggerNumber = select(3, ...)
    local TO = select(4, ...)
    local TD = select(5, ...)
    local Auras = TD.Auras

    if Auras then
      local Index = 0

      for SpellID, Aura in pairs(Auras) do
        if type(Aura) == 'table' then
          Index = Index + 1
          ModifyAuraOptions('add', Order, BBar, TriggerNumber, TO, TD, Index, SpellID)
        end
      end
    end
  elseif Action == 'clear' then
    local TOA = (select(1, ...)).args
    local Auras = (select(2, ...)).Auras

    if Auras then
      for SpellID, Aura in pairs(Auras) do
        if type(Aura) == 'table' then
          TOA[format(AuraGroupSt, SpellID)] = nil
        end
      end
    end
  elseif Action == 'add' then
    local Order = select(1, ...)
    local BBar = select(2, ...)
    local TriggerNumber = select(3, ...)
    local TO = select(4, ...)
    local TD = select(5, ...)
    local Index = select(6, ...)
    local SpellID = select(7, ...)

    local Name, _, Icon = GetSpellInfo(SpellID)
    local Auras = TD.Auras
    local AuraGroup = format(AuraGroupSt, SpellID)
    local TOA = TO.args

    TOA[AuraGroup] = {
      type = 'group',
      name = format('|T%s:20:20:0:5|t |cFFFFFFFF%s|r (%s)', Icon, Name, SpellID),
      order = Order + Index,
      dialogInline = true,
      hidden = function()
                 return TD.Minimize or TD.HideAuras or TD.Condition == 'static' or TD.ValueTypeID ~= 'auras'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
      get = function(Info)
              local KeyName = Info[#Info]
              local Aura = Auras[SpellID]

              if KeyName == 'StackCondition' then
                return FindMenuItem(AuraStackConditionDropdown, Aura.StackCondition)
              elseif KeyName == 'Stacks' then
                return format('%s', Aura.Stacks or 0)
              elseif KeyName == 'Units' then
                local St = ''
                for Unit, _ in pairs(Aura.Units) do
                  St = St .. Unit .. ' '
                end
                return strtrim(St)
              else
                return Aura[KeyName]
              end
            end,
      set = function(Info, Value)
              local KeyName = Info[#Info]

              if KeyName == 'Stacks' then
                Value = tonumber(Value) or 0
              elseif KeyName == 'StackCondition' then
                Value = AuraStackConditionDropdown[Value]
              elseif KeyName == 'Units' then
                local Units = {Main:StringSplit(' ', Value)}
                Value = {}
                for Index = 1, #Units do
                  Value[Units[Index]] = true
                end
              end

              Auras[SpellID][KeyName] = Value

              BBar:ModifyAuraTriggers(TriggerNumber, TD)
            end,
      args = {
        RemoveAura = {
          type = 'execute',
          name = 'Remove',
          desc = 'Remove aura',
          order = 1,
          width = 'half',
          func = function()
                   TOA[AuraGroup] = nil
                   Auras[SpellID] = nil

                   -- Delete auras if Auras is empty
                   if next(Auras) == nil then
                     TD.Auras = nil
                   end
                   BBar:ModifyAuraTriggers(TriggerNumber, TD)

                   HideTooltip(true)
                 end,
        },
        SpacerHalf = CreateSpacer(2, 'half'),
        CastByPlayer = {
          type = 'toggle',
          name = 'Cast by Player',
          desc = 'This aura must be cast by your self',
          order = 3,
        },
        Spacer10 = CreateSpacer(10),
        Units = {
          type = 'input',
          name = 'Units',
          desc = 'Enter one or more units seperated by a space',
          order = 11,
        },
        StackCondition = {
          type = 'select',
          name = 'Condition',
          width = 'half',
          order = 12,
          values = AuraStackConditionDropdown,
        },
        Stacks = {
          type = 'input',
          name = 'Stacks',
          width = 'half',
          order = 13,
        },
      },
    }

    -- Update trigger aura since this option was just created.
    BBar:ModifyAuraTriggers(TriggerNumber, TD)
  end
end

-------------------------------------------------------------------------------
-- AddTriggerOption
--
-- Adds a trigger options panel
--
-- SubFunction of CreateTriggerListOptions
--
-- BarType                    Options will be added for this bar.
-- TOA                        TriggerOptions.args
-- TriggerNumber              Trigger to make options for.
-- GroupNames                 List of names for the trigger group.
-- TriggerTypeDropdown        Menu for different trigger types. Background, Border Color, etc
-- TriggerValueTypeDropdown   Value types for TriggerTypeDropdown
-- TriggerActionDropdown      Menu for picking an action. move, copy, etc
-- TriggerConditionDropdown   Menu for picking a condition, <, >, >=, etc
-- TypeIDs                    Contains the different Type identifiers for each group.
-- ValueTypeIDs               Contains the valueType identifiers for each group.
-- TriggerOrderNumber         Position in the options list for the trigger options panel to be listed at.
-- SwapTriggers               Clipboard for swapping one trigger with another.
-------------------------------------------------------------------------------
local function AddTriggerOption(BarType, TOA, TriggerNumber, GroupNames, TriggerTypeDropdown, TriggerValueTypeDropdown,
                                TriggerActionDropdown, TriggerConditionDropdown, TriggerGetFnTypeDropdown, TypeIDs, ValueTypeIDs, TriggerOrderNumber, SwapTriggers)
  local UBF = UnitBarsF[BarType]
  local BBar = UBF.BBar
  local Names = UBF.Names.Trigger
  local TriggerData = UBF.UnitBar.Triggers
  local TD = TriggerData[TriggerNumber]
  local UnitType = DUB[BarType].UnitType or 'player'
  local TriggerKey = 'Trigger' .. TriggerNumber
  local TriggerLineKey = 'TriggerLine' .. TriggerNumber
  local TriggerSt = 'Trigger%s'
  local TriggerLineSt = 'TriggerLine%s'
  local InvalidSpell = false
  local AuraGroupOrder = 200

  local AuraName = nil

  local TO = {}

  TOA[TriggerLineKey] = {
    type = 'header',
    name = '',
    order = function()
              return TriggerOrderNumber[TriggerNumber] - 0.01
            end,
    hidden = function()
               return TD.GroupNumber ~= TriggerData.GroupNumber
             end
  }

  TO.type = 'group'
  TO.name = function()
              local Name = TD.Name
              local Index = TriggerOrderNumber[TriggerNumber]
              local BarObject = GroupNames[TD.GroupNumber]

              if Name == '' then
                local Value = TD.Value
                local Condition = TD.Condition
                local Type = TD.Type

                if strsub(Type, 1, 10) == 'background' then
                  Type = 'bg' .. strsub(Type, 11)
                end

                if Condition == 'static' then
                  return format('|cFF00FF00%d|r:|cFFFFFF00%s||%s||%s|r', Index, BarObject, Condition, Type)
                else
                  if TD.ValueTypeID == 'boolean' then
                    Value = Value == 1 and 'true' or 'false'
                  end
                  return format('|cFF00FF00%d|r:|cFFFFFF00%s||%s||%s||%s||%s|r', Index, BarObject, Type, TD.ValueType, Condition, Value)
                end
              else
                return format('|cFF00FF00%d|r:|cFFFFFF00 (%s) %s|r', Index, BarObject, Name)
              end
            end
  TO.order = function(Info, Value)
               -- Using this function as a way to update the upvalues TriggerNumber and TD.
               -- When deleting/adding.
               if Info == 'update' then
                 TD = TriggerData[Value]
                 TriggerNumber = Value
               else
                 return TriggerOrderNumber[TriggerNumber]
               end
             end
  TO.dialogInline = true
  TO.hidden = function()
                return TD.GroupNumber ~= TriggerData.GroupNumber
              end
  TOA[TriggerKey] = TO

  TO.args = {
    Minimize = {
      type = 'execute',
      order = 1,
      name = function()
               if TD.Minimize then
                 return '+'
               else
                 return '_'
               end
             end,
      width = 'half',
      desc = function()
               if TD.Minimize then
                 return 'Click to maximize'
               else
                 return 'Click to minimize'
               end
             end,
      func = function()
               TD.Minimize = not TD.Minimize
               HideTooltip(true)
             end,
    },
    ActionMenu = {
      type = 'select',
      name = 'Action',
      width = 'half',
      order = 2,
      values = TriggerActionDropdown,
      style = 'dropdown',
      get = function()
              return FindMenuItem(TriggerActionDropdown, TriggerData.Action)
            end,
      set = function(Info, Value)
              TriggerData.Action = strlower(TriggerActionDropdown[Value])
            end,
    },
    SpacerHalf = CreateSpacer(5, 'half'),
    Add = {
      type = 'execute',
      order = 6,
      name = 'Add',
      width = 'half',
      desc = 'Add a trigger after this one',
      func = function()
               local Index = TriggerNumber + 1
               local TD = {}

               Main:CopyTableValues(TriggerData[Index - 1], TD, true)

               -- Set Trigger to selected group.
               TD.GroupNumber = TriggerData.GroupNumber

               tinsert(TriggerData, Index, TD)

               -- Insert new trigger data option.
               for TriggerIndex = #TriggerData, Index, -1 do
                 if TriggerIndex > Index  then
                   local t = TOA[format(TriggerSt, TriggerIndex - 1)]

                   TOA[format(TriggerSt, TriggerIndex)] = t

                   -- Update the upvalues in the function containing the options for trigger.
                   t.order('update', TriggerIndex)
                 end
               end
               UpdateTriggerOrderNumbers(TriggerData, GroupNames, TriggerOrderNumber)

               BBar:InsertTriggers(Index, TD)
               AddTriggerOption(BarType, TOA, Index, GroupNames, TriggerTypeDropdown, TriggerValueTypeDropdown,
                                TriggerActionDropdown, TriggerConditionDropdown, TriggerGetFnTypeDropdown, TypeIDs, ValueTypeIDs, TriggerOrderNumber, SwapTriggers)


               -- Update bar to reflect trigger changes
               BBar:UndoTriggers()

               UBF:SetAttr('Layout', '_UpdateTriggers')

               HideTooltip(true)
             end,
      hidden = function()
                 return TriggerData.Action ~= 'add'
               end,
    },
    Delete = {
      type = 'execute',
      order = 7,
      name = 'Delete',
      width = 'half',
      desc = function()
               return format('Delete trigger %s', TriggerOrderNumber[TriggerNumber])
             end,
      func = function()
               local NumTriggers = #TriggerData

               tremove(TriggerData, TriggerNumber)

               -- Delete trigger data option
               for TriggerIndex = TriggerNumber, NumTriggers do
                 local t = nil
                 local tl = nil

                 if TriggerIndex < NumTriggers then
                   t = TOA[format(TriggerSt, TriggerIndex + 1)]
                   tl = TOA[format(TriggerLineSt, TriggerIndex + 1)]

                   -- Update the upvalues in the function containing the options for trigger.
                   t.order('update', TriggerIndex)
                 end
                 TOA[format(TriggerSt, TriggerIndex)] = t
                 TOA[format(TriggerLineSt, TriggerIndex)] = tl
               end

               -- Update bar to reflect trigger changes
               BBar:UndoTriggers()
               BBar:RemoveTriggers(TriggerNumber)
               UBF:SetAttr('Layout', '_UpdateTriggers')

               -- Clear swap if source was deleted
               if TriggerNumber == SwapTriggers.Source then
                 SwapTriggers.Source = nil
               end
               UpdateTriggerOrderNumbers(TriggerData, GroupNames, TriggerOrderNumber)

               HideTooltip(true)
             end,
      hidden = function()
                 return TriggerData.Action ~= 'delete'
               end,
    },
    Name = {
      type = 'input',
      name = 'Name',
      order = 8,
      desc = 'Change the name',
      hidden = function()
                 return TriggerData.Action ~= 'name'
               end,
    },
    Clear = {
      type = 'execute',
      order = 9,
      name = 'Clear',
      width = 'half',
      desc = 'Clears the current swap',
      hidden = function()
                 return TriggerData.Action ~= 'swap' or SwapTriggers.Source == nil
               end,
      func = function()
               HideTooltip(true)
               SwapTriggers.Source = nil
             end,
    },
    Swap = {
      type = 'execute',
      order = 10,
      name = 'Swap',
      width = 'half',
      hidden = function()
                 return TriggerData.Action ~= 'swap'
               end,
      disabled = function()
                   HideTooltip(true)
                   return SwapTriggers.Source == TriggerNumber or #TriggerData == 1
                 end,
      desc = 'Click "Swap" on the two triggers you want to swap.  You can Swap accross Bar Objects',
      func = function()
               local Source = SwapTriggers.Source

               if Source == nil then
                 SwapTriggers.Source = TriggerNumber
                 SwapTriggers.TO = TO
               else
                 -- Swap by group number or trigger number.
                 local SourceTriggerNumber = SwapTriggers.Source
                 local SourceTO = SwapTriggers.TO
                 local SourceTD = TriggerData[SourceTriggerNumber]

                 local SourceGroupNumber = TriggerData[SourceTriggerNumber].GroupNumber
                 local GroupNumber = TD.GroupNumber
                 local Tdata = {}

                 -- Clear aura options before swapping
                 ModifyAuraOptions('clear', SourceTO,  SourceTD)
                 ModifyAuraOptions('clear', TO, TD)

                 -- Since each trigger option uses its own upvalues for trigger number and trigger data.
                 -- A copy needs to be done instead.
                 Main:CopyTableValues(SourceTD, Tdata, true)
                 Main:CopyTableValues(TD, SourceTD, true)
                 Main:CopyTableValues(Tdata, TD, true)
                 BBar:SwapTriggers(SourceTriggerNumber, TriggerNumber)

                 if SourceGroupNumber ~= GroupNumber then
                   local SourceTypeIndex = UpdateTriggerData(SourceTD, SourceGroupNumber, TriggerTypeDropdown,
                                                             TriggerValueTypeDropdown, TriggerConditionDropdown, TypeIDs, ValueTypeIDs)
                   local TypeIndex = UpdateTriggerData(TD, GroupNumber, TriggerTypeDropdown,
                                                       TriggerValueTypeDropdown, TriggerConditionDropdown, TypeIDs, ValueTypeIDs)

                   -- Update bar to reflect trigger changes
                   BBar:UndoTriggers()
                   BBar:ModifyTriggers(SourceTriggerNumber, SourceTD, SourceTypeIndex, true)
                   BBar:ModifyTriggers(TriggerNumber, TD, TypeIndex, true)
                 end

                 -- Recreate aura options if there any auras
                 ModifyAuraOptions('create', AuraGroupOrder, BBar, SourceTriggerNumber, SourceTO, SourceTD)
                 ModifyAuraOptions('create', AuraGroupOrder, BBar, TriggerNumber, TO, TD)

                 UBF:SetAttr('Layout', '_UpdateTriggers')

                 -- Clear the clipboard
                 SwapTriggers.Source = nil
                 SwapTriggers.TO = nil

                 HideTooltip(true)
               end
             end,
    },
    Disable = {
      type = 'execute',
      order = 11,
      width = 'half',
      name = function()
               if TD.Enabled then
                 return 'Disable'
               else
                 return 'Enable'
               end
             end,
      func = function()
               TD.Enabled = not TD.Enabled

               -- Update bar to reflect trigger changes
               BBar:UndoTriggers()
               BBar:ModifyTriggers(TriggerNumber, TD, nil, true)
               UBF:SetAttr('Layout', '_UpdateTriggers')
             end,
      hidden = function()
                 return TriggerData.Action ~= 'disable'
               end,
    },
    Move = {
      type = 'select',
      name = 'Move to',
      order = 12,
      desc = 'Select the bar object to move to',
      values = GroupNames,
      style = 'dropdown',
      hidden = function()
                 return TriggerData.Action ~= 'move'
               end,
      disabled = function()
                   return #GroupNames == 1
                 end,
    },
    Copy = {
      type = 'select',
      name = 'Copy to',
      order = 13,
      desc = 'Select the bar object to copy to',
      values = GroupNames,
      style = 'dropdown',
      set = function(Info, Value)
              local TD = {}
              local Index = #TriggerData + 1

              TriggerData[Index] = TD
              Main:CopyTableValues(TriggerData[TriggerNumber], TD, true)

              -- Set Trigger to selected group.
              TD.GroupNumber = Value
              -- Update bar to reflect changes.
              BBar:UndoTriggers()
              BBar:InsertTriggers(Index, TD)

              UpdateTriggerOrderNumbers(TriggerData, GroupNames, TriggerOrderNumber)
              AddTriggerOption(BarType, TOA, Index, GroupNames, TriggerTypeDropdown, TriggerValueTypeDropdown,
                               TriggerActionDropdown, TriggerConditionDropdown, TriggerGetFnTypeDropdown, TypeIDs, ValueTypeIDs, TriggerOrderNumber, SwapTriggers)

              UBF:SetAttr('Layout', '_UpdateTriggers')
            end,
      disabled = function()
                   return #GroupNames == 1
                 end,
      hidden = function()
                 return TriggerData.Action ~= 'copy'
               end,
    },
    Spacer20 = CreateSpacer(20),
    ValueType = {
      type = 'select',
      name = 'Value Type',
      order = 21,
      values = function()
                 return TriggerValueTypeDropdown[TD.GroupNumber]
               end,
      style = 'dropdown',
      hidden = function()
                 return TD.Minimize
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    Type = {
      type = 'select',
      name = 'Type',
      order = 22,
      desc = 'Type of trigger',
      values = function()
                 return TriggerTypeDropdown[TD.GroupNumber]
               end,
      style = 'dropdown',
      hidden = function()
                 return TD.Minimize
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    Spacer30 = CreateSpacer(30),
    ParsColor = {
      type = 'color',
      name = 'Color',
      order = 31,
      width = 'half',
      hasAlpha = true,
      hidden = function()
                 local TypeID = TD.TypeID
                 return TypeID ~= 'bordercolor' and TypeID ~= 'backgroundcolor' and TypeID ~= 'bartexturecolor'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    ParsTexture = {
      type = 'select',
      name = 'Texture',
      order = 32,
      dialogControl = 'LSM30_Statusbar',
      values = LSMStatusBarDropdown,
      hidden = function()
                 return TD.TypeID ~= 'bartexture'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    ParsTextureSize = {
      type = 'range',
      name = 'Texture Size',
      order = 33,
      desc = 'Change the texture size',
      step = .01,
      width = 'double',
      isPercent = true,
      hidden = function()
                 return TD.TypeID ~= 'texturesize'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
      min = O.TriggerTextureSizeMin,
      max = O.TriggerTextureSizeMax,
    },
    ParsBorder = {
      type = 'select',
      name = 'Border',
      order = 34,
      dialogControl = 'LSM30_Border',
      values = LSMBorderDropdown,
      hidden = function()
                 return TD.TypeID ~= 'border'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    ParsBackground = {
      type = 'select',
      name = 'Background',
      order = 35,
      dialogControl = 'LSM30_Background',
      values = LSMBackgroundDropdown,
      hidden = function()
                 return TD.TypeID ~= 'background'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    ParsSound = {
      type = 'select',
      name = 'Sound',
      order = 36,
      dialogControl = 'LSM30_Sound',
      values = LSMSoundDropdown,
      hidden = function()
                 return TD.TypeID ~= 'sound'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    ParsSoundChannel = {
      type = 'select',
      name = 'Sound Channel',
      order = 37,
      style = 'dropdown',
      values = TriggerSoundChannelDropdown,
      hidden = function()
                 return TD.TypeID ~= 'sound'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    Spacer50 = CreateSpacer(50, nil, function()
                                       local TypeID = TD.TypeID

                                       return TypeID ~= 'bordercolor' and TypeID ~= 'backgroundcolor' and TypeID ~= 'bartexturecolor' or
                                       TD.Condition == 'static' or next(TriggerGetFnTypeDropdown[TD.GroupNumber].color) == nil or
                                       TD.GetFnTypeID == 'none'
                                      end),
    ParsGetColorMenu = {
      type = 'select',
      name = 'Color Type',
      desc = 'This will override the current color, if there is a new one to replace it with',
      order = 50,
      values = function()
                 return TriggerGetFnTypeDropdown[TD.GroupNumber].color
               end,
      hidden = function()
                 HideTooltip(true)
                 local TypeID = TD.TypeID
                 return TypeID ~= 'bordercolor' and TypeID ~= 'backgroundcolor' and TypeID ~= 'bartexturecolor' or
                        TD.Condition == 'static' or next(TriggerGetFnTypeDropdown[TD.GroupNumber].color) == nil
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    GetParsColorUnit = {
      type = 'input',
      name = 'Color Unit',
      desc = 'Enter the unit you want to get the color from',
      order = 51,
      hidden = function()
                 local TypeID = TD.TypeID
                 local GetFnTypeID = TD.GetFnTypeID
                 return TypeID ~= 'bordercolor' and TypeID ~= 'backgroundcolor' and TypeID ~= 'bartexturecolor' or
                        GetFnTypeID ~= 'classcolor' and GetFnTypeID ~= 'powercolor' and GetFnTypeID ~= 'combatcolor' and
                        GetFnTypeID ~= 'taggedcolor'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    Spacer100 = CreateSpacer(100),
    Condition = {
      type = 'select',
      name = 'Condition',
      width = 'half',
      desc = function()
               if TD.ValueTypeID ~= 'auras' then
                 return 'Set the condition to activate at. Static means always on'
               else
                 return '"and" means all auras\n"or" at least one aura\nStactic means always on'
               end
             end,
      order = 101,
      values = function()
                 return TriggerConditionDropdown[TD.ValueTypeID]
               end,
      style = 'dropdown',
      hidden = function()
                 return TD.Minimize
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    Value = {
      type = 'input',
      name = function()
               return format('Value (%s)', TD.ValueTypeID)
             end,
      order = 102,
      desc = function()
               if TD.ValueTypeID == 'percent' then
                 return 'Enter a number between 0 and 100'
               else
                 return 'Enter any number'
               end
             end,
      hidden = function()
                 return TD.Minimize or TD.Condition == 'static' or
                        TD.ValueTypeID == 'boolean' or TD.ValueTypeID == 'auras'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    ValueBoolean = {
      type = 'select',
      name = function()
               return format('Value (%s)', TD.ValueTypeID)
             end,
      width = 'half',
      order = 103,
      values = TriggerBooleanDropdown,
      style = 'dropdown',
      hidden = function()
                 return TD.Minimize or TD.Condition == 'static' or TD.ValueTypeID ~= 'boolean'
               end,
      disabled = function()
                   return not TD.Enabled
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
      order = 104,
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

              -- Add aura to TD.Auras
              -- And create aura menu
              if not InvalidSpell then
                local Auras = TD.Auras

                if Auras == nil then
                  Auras = {}
                  TD.Auras = Auras
                end

                local Aura = Auras[SpellID]
                local Index = 0

                if Aura == nil then
                  Aura = {Units = {[UnitType] = true}, StackCondition = '>=', Stacks = 0}
                  Auras[SpellID] = Aura

                  for _, Aura in pairs(Auras) do
                    if type(Aura) == 'table' then
                      Index = Index + 1
                    end
                  end
                  -- Add aura option
                  ModifyAuraOptions('add', AuraGroupOrder, BBar, TriggerNumber, TO, TD, Index, SpellID)
                end
              end
            end,
      get = function()
            end,
      hidden = function()
                 return TD.Minimize or TD.Condition == 'static' or TD.ValueTypeID ~= 'auras'
               end,
      disabled = function()
                   return not TD.Enabled
                 end,
    },
    AurasHide = {
      type = 'execute',
      name = function()
               if TD.HideAuras then
                 return 'Show'
               else
                 return 'Hide'
               end
             end,
      desc = 'Hide auras',
      width = 'half',
      order = 105,
      func = function()
               TD.HideAuras = not TD.HideAuras
               HideTooltip(true)
             end,
      hidden = function()
                 return TD.Minimize or TD.Auras == nil or TD.Condition == 'static' or TD.ValueTypeID ~= 'auras'
               end,
    },
  }

  TO.args.SpacerHalf.hidden = function()
                                return TriggerData.Action == 'name' or TriggerData.Action == 'move' or
                                       TriggerData.Action == 'copy' or
                                       TriggerData.Action == 'swap' and SwapTriggers.Source ~= nil
                              end

  -- Add aura options
  ModifyAuraOptions('create', AuraGroupOrder, BBar, TriggerNumber, TO, TD)
end

-------------------------------------------------------------------------------
-- CreateTriggerListOptions
--
-- Creates a list of trigger options.
--
-- SubFunction of CreateTriggerOptions
--
-- BarType          Options will be added for this bar.
-- TriggerOptions   Options table for the triggers.
-------------------------------------------------------------------------------
local function CreateTriggerListOptions(BarType, TriggerOptions)
  local UBF = UnitBarsF[BarType]
  local Names = UBF.Names.Trigger
  local BBar = UBF.BBar
  local TriggerData = UBF.UnitBar.Triggers
  local DefaultTriggerData = DUB[BarType].Triggers
  local Notes = DefaultTriggerData.Notes
  local TriggerNameDropdown = {}
  local TriggerTypeDropdown = {}
  local TriggerValueTypeDropdown = {}
  local TriggerGetFnTypeDropdown = {}
  local TypeIDs = {}
  local ValueTypeIDs = {}
  local GetFnTypeIDs = {}
  local GroupNames = {}
  local Groups = BBar:GetGroupsTriggers()
  local TriggerOrderNumber = {}
  local SwapTriggers = {}
  local TOA = {}

  -- Create menus.
  for GroupNumber, Group in ipairs(Groups) do

    -- Change group number into a familiar name.
    local Name = Names[GroupNumber]

    TriggerNameDropdown[GroupNumber] = Name
    GroupNames[GroupNumber] = Name
    local TypeDropdown = {}
    local TypeID = {}
    local ValueTypeDropdown = {}
    local ValueTypeID = {}
    local GetFnTypeDropdown = {}
    local GetFnTypeID = {}

    TriggerTypeDropdown[GroupNumber] = TypeDropdown
    TypeIDs[GroupNumber] = TypeID
    TriggerValueTypeDropdown[GroupNumber] = ValueTypeDropdown
    ValueTypeIDs[GroupNumber] = ValueTypeID
    TriggerGetFnTypeDropdown[GroupNumber] = GetFnTypeDropdown
    GetFnTypeIDs[GroupNumber] = GetFnTypeID

    -- Buld Type menu.
    for TypeIndex, Object in ipairs(Group.Objects) do
      local Type = Object.Type
      local GetFnMenuTypeID = Object.GetFnMenuTypeID

      TypeDropdown[TypeIndex] = Type
      TypeID[strlower(Type)] = Object.TypeID

      -- Build the GetFunction menu.
      if GetFnMenuTypeID then
        local BarFunction = Object.BarFunction
        local GetFnIndex = 0

        for GetFnTypeIDKey, GetFn in pairs(BarFunction.GetFn) do
          GetFnIndex = GetFnIndex + 1
          local TypeDropdown = GetFnTypeDropdown[GetFnMenuTypeID]

          if TypeDropdown == nil then
            TypeDropdown = {}
            GetFnTypeDropdown[GetFnMenuTypeID] = TypeDropdown
          end

          if GetFn == 'none' then
            TypeDropdown[GetFnIndex] = 'None'
            GetFnTypeID.None = 'none'
            GetFnTypeID.none = 'None'
          else
            local GetFnType = GetFn.Type
            TypeDropdown[GetFnIndex] = GetFnType
            GetFnTypeID[GetFnType] = GetFnTypeIDKey
            GetFnTypeID[GetFnTypeIDKey] = GetFnType
          end
        end
      end
    end

    -- Build value type menu.
    for ValueTypeIndex, ValueType in ipairs(Group.ValueTypes) do
      ValueTypeDropdown[ValueTypeIndex] = ValueType
      ValueTypeID[strlower(ValueType)] = Group.ValueTypeIDs[ValueTypeIndex]
    end
  end

  local AddTriggerData = {}

  -- GET
  TriggerOptions.get = function(Info)
    local KeyName = Info[#Info]
    -- Get index from name of trigger option.

    local TriggerIndex = tonumber(strsub(Info[#Info - 1], 8))
    local TD = TriggerData[TriggerIndex]
    local GroupNumber = TD.GroupNumber

    if strfind(KeyName, 'Pars') then
      if KeyName == 'ParsGetColorMenu' then
        local MenuItem = GetFnTypeIDs[GroupNumber][TD.GetFnTypeID]

        return FindMenuItem(TriggerGetFnTypeDropdown[GroupNumber].color, MenuItem or 'None')
      elseif KeyName == 'GetParsColorUnit' then
        local GetPars1 = TD.GetPars[1]

        if GetPars1 == nil or GetPars1 == '' then
          GetPars1 = UBF.UnitBar.UnitType or 'player'
          TD.GetPars[1] = GetPars1

          -- Update trigger with new getpars
          BBar:ModifyTriggers(TriggerIndex, TD)
          UBF:SetAttr('Layout', '_UpdateTriggers')
        end

        return GetPars1
      elseif strfind(KeyName, 'Get') then
        local GetPars = TD.GetPars

        return GetPars[1], GetPars[2], GetPars[3], GetPars[4]
      else
        local Pars = TD.Pars

        if strfind(KeyName, 'Color') then
          return Pars[1], Pars[2], Pars[3], Pars[4]
        elseif KeyName == 'ParsSoundChannel' then
          return Pars[2]
        else
          return Pars[1]
        end
      end
    elseif KeyName == 'Condition' then
      return FindMenuItem(TriggerConditionDropdown[TD.ValueTypeID], TD.Condition)
    elseif KeyName == 'ValueType' then
      return FindMenuItem(TriggerValueTypeDropdown[GroupNumber], TD.ValueType)
    elseif KeyName == 'Type' then
      return FindMenuItem(TriggerTypeDropdown[GroupNumber], TD.Type)
    elseif KeyName == 'Value' then

      -- Turn into a string. Input takes strings.
      return format('%s', TD.Value)
    elseif KeyName == 'ValueBoolean' then
      local Value = TD.Value

      if Value < 1 or Value > 2 then
        Value = 1
      end
      return Value
    else
      return TD[KeyName]
    end
  end

  -- SET
  TriggerOptions.set = function(Info, Value, g, b, a)
    local KeyName = Info[#Info]

    -- Get index from name of trigger option.
    local TriggerIndex = tonumber(strsub(Info[#Info - 1], 8))
    local TD = TriggerData[TriggerIndex]
    local GroupNumber = TD.GroupNumber
    local ValueType = TD.ValueType
    local Undo = true
    local Sort = true
    local TypeIndex = nil

    if strfind(KeyName, 'Pars') then
      Undo = false
      Sort = false
      if KeyName == 'ParsGetColorMenu' then
        local GetFnType = TriggerGetFnTypeDropdown[GroupNumber].color[Value]

        TD.GetFnTypeID = GetFnTypeIDs[GroupNumber][GetFnType]
      elseif strfind(KeyName, 'Get') then
        local GetPars = TD.GetPars

        GetPars[1] = Value
      else
        local Pars = TD.Pars

        if strfind(KeyName, 'Color') then
          Pars[1] = Value
          Pars[2] = g
          Pars[3] = b
          Pars[4] = a
        elseif KeyName == 'ParsSound' or KeyName == 'ParsTextureSize' then
          Pars[1] = Value
        elseif KeyName == 'ParsSoundChannel' then
          Pars[2] = Value
        else
          Pars[1] = Value
          Pars[2] = nil
          Pars[3] = nil
          Pars[4] = nil
        end
      end
    elseif KeyName == 'Condition' then
      TD.Condition = strlower(TriggerConditionDropdown[TD.ValueTypeID][Value])
      UpdateTriggerData(TD, GroupNumber, TriggerTypeDropdown, TriggerValueTypeDropdown, TriggerConditionDropdown, TypeIDs, ValueTypeIDs)

    elseif KeyName == 'ValueType' then
      TD.ValueType = strlower(TriggerValueTypeDropdown[GroupNumber][Value])
      UpdateTriggerData(TD, GroupNumber, TriggerTypeDropdown, TriggerValueTypeDropdown, TriggerConditionDropdown, TypeIDs, ValueTypeIDs)

    elseif KeyName == 'Move' or KeyName == 'Type' then
      local OldType = TD.Type
      local Change = nil

      if KeyName == 'Type' then
        TD.Type = strlower(TriggerTypeDropdown[GroupNumber][Value])
      else
        GroupNumber = Value
      end

      TypeIndex = UpdateTriggerData(TD, GroupNumber, TriggerTypeDropdown, TriggerValueTypeDropdown, TriggerConditionDropdown, TypeIDs, ValueTypeIDs)

      if KeyName == 'Move' then
        -- Update order since trigger was moved.
        UpdateTriggerOrderNumbers(TriggerData, GroupNames, TriggerOrderNumber)
      end

    elseif KeyName == 'Value' then
      -- Change to number for profile. Input takes strings.
      TD.Value = floor(tonumber(Value) or 0)
    elseif KeyName == 'ValueBoolean' then
      TD.Value = Value
    else
      TD[KeyName] = Value
    end

    -- Apply changes
    if Undo then
      BBar:UndoTriggers()
    end
    BBar:ModifyTriggers(TriggerIndex, TD, TypeIndex, Sort)
    UBF:SetAttr('Layout', '_UpdateTriggers')
  end

  TriggerOptions.args = TOA

  if Notes then
    TOA.Notes = {
      type = 'description',
      name = Notes,
      order = 0.10,
    }
  end
  TOA.Spacer20 = CreateSpacer(0.20)

  TOA.BarObject = {
    type = 'select',
    name = 'Bar Object',
    order = 0.21,
    desc = 'Triggers will be shown that belong to this bar object.\nHighlighted means you have triggers',
    values = function()
               -- Tag menu items that have triggers.
               local NumTriggers = #TriggerData

               for Index = 1, #GroupNames do
                 local Name = GroupNames[Index]
                 local Found = false

                 for TriggerIndex = 1, NumTriggers do
                   if TriggerData[TriggerIndex].GroupNumber == Index then
                     Found = true
                   end
                 end
                 if Found then
                   TriggerNameDropdown[Index] = format('|cFF00FFFF%s|r', Name)
                 else
                   TriggerNameDropdown[Index] = format('%s', Name)
                 end
               end
               return TriggerNameDropdown
             end,
    style = 'dropdown',
    get = function()
            return TriggerData.GroupNumber
          end,
    set = function(Info, Value)
            TriggerData.GroupNumber = Value
          end,
  }
  TOA.MinimizeAll = {
    type = 'execute',
    order = 0.22,
    name = function()
             if TriggerData.MinimizeAll then
               return 'Maximize All'
             else
               return 'Minimize All'
             end
           end,
    func = function()
             local MinimizeAll = not TriggerData.MinimizeAll

             for Index = 1, #TriggerData do
               TriggerData[Index].Minimize = MinimizeAll
             end
             TriggerData.MinimizeAll = MinimizeAll
             HideTooltip(true)
           end,
    hidden = function()
               return not TriggersFound(TriggerData)
             end
  }
  TOA.Spacer30 = CreateSpacer(0.30)
  TOA.Add = {
    type = 'execute',
    order = 0.31,
    name = 'Add',
    width = 'half',
    desc = 'Click to add the first trigger',
    func = function()
             local TD = {}
             local Index = #TriggerData + 1

             TriggerData[Index] = TD
             Main:CopyTableValues(DefaultTriggerData.Default, TD, true)

             -- Set Trigger to selected group.
             TD.GroupNumber = TriggerData.GroupNumber

             UpdateTriggerData(TD, TriggerData.GroupNumber, TriggerTypeDropdown, TriggerValueTypeDropdown, TriggerConditionDropdown, TypeIDs, ValueTypeIDs)
             UpdateTriggerOrderNumbers(TriggerData, GroupNames, TriggerOrderNumber)

             BBar:InsertTriggers(Index, TD)

             AddTriggerOption(BarType, TOA, Index, GroupNames, TriggerTypeDropdown, TriggerValueTypeDropdown,
                              TriggerActionDropdown, TriggerConditionDropdown, TriggerGetFnTypeDropdown, TypeIDs, ValueTypeIDs, TriggerOrderNumber, SwapTriggers)

             -- Update bar to reflect changes.
             BBar:UndoTriggers()

             UBF:SetAttr('Layout', '_UpdateTriggers')
             HideTooltip(true)
           end,
    hidden = function()
               return TriggersFound(TriggerData)
             end,
  }

  UpdateTriggerOrderNumbers(TriggerData, GroupNames, TriggerOrderNumber)

  for TriggerIndex = 1, #TriggerData do
    AddTriggerOption(BarType, TOA, TriggerIndex, GroupNames, TriggerTypeDropdown, TriggerValueTypeDropdown,
                     TriggerActionDropdown, TriggerConditionDropdown, TriggerGetFnTypeDropdown, TypeIDs, ValueTypeIDs, TriggerOrderNumber, SwapTriggers)
  end

  return TriggerOptions
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
    args = {}, -- need this so ACE3 dont crash if triggers options are not created.
  }

  -- Create the trigger list options.
  local DoCreateTriggers = Options:DoFunction(BarType, 'CreateTriggerOptions', function()

    -- Only create triggers if they're enabled.
    if Main.UnitBars[BarType].Layout.EnableTriggers then
      local TOA = {}

      TriggerOptions.args = TOA
      CreateTriggerListOptions(BarType, TriggerOptions)
    end
  end)

  DoCreateTriggers()

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
        type = 'execute',
        order = 6,
        name = function()
                 if Main.UnitBars.Reset.Minimize then
                   return '+'
                 else
                   return '_'
                 end
               end,
        width = 'half',
        desc = function()
                 if Main.UnitBars.Reset.Minimize then
                   return 'Click to maximize'
                 else
                   return 'Click to minimize'
                 end
               end,
        func = function()
                 local Reset = Main.UnitBars.Reset

                 Reset.Minimize = not Reset.Minimize
                 HideTooltip(true)
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
                 UBF:SetAttr()
                 UBF:StatusCheck()
                 UBF:Update()

                 -- Update any dynamic options.
                 Options:DoFunction()

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
  local CopyPasteOptions = nil

  ClipBoard = ClipBoard or {
    SelectedGroup = 'GroupMain',

    {Name = 'Clear', Order = 1},

    {Name = 'Main', Order = 2,
      {Name = 'All'       , Order = 10, All = false, Type = 'All',        TablePath = ''},
      {Name = 'Status'    , Order = 11, All = true,  Type = 'Status',     TablePath = 'Status'},
      {Name = 'Layout'    , Order = 12, All = true,  Type = 'Layout',     TablePath = 'Layout'},
      {Name = 'Other'     , Order = 13, All = true,  Type = 'Other',      TablePath = 'Other'}},

    {Name = 'Spacer3', Order = 3},

    {Name = 'Backg', Order = 6,
      {Name = 'BG'        , Order = 10, All = true,  Type = 'Background', TablePath = 'Background'},
      {Name = 'Moon'      , Order = 11, All = true,  Type = 'Background', TablePath = 'BackgroundMoon'},
      {Name = 'Power'     , Order = 12, All = true,  Type = 'Background', TablePath = 'BackgroundPower'},
      {Name = 'Sun'       , Order = 13, All = true,  Type = 'Background', TablePath = 'BackgroundSun'},
      {Name = 'Slider'    , Order = 14, All = true,  Type = 'Background', TablePath = 'BackgroundSlider'},
      {Name = 'Charges'   , Order = 15, All = true,  Type = 'Background', TablePath = 'BackgroundCharges'},
      {Name = 'Time'      , Order = 16, All = true,  Type = 'Background', TablePath = 'BackgroundTime'}},

    {Name = 'Bar', Order = 7,
      {Name = 'Bar'       , Order = 10, All = true,  Type = 'Bar',        TablePath = 'Bar'},
      {Name = 'Moon'      , Order = 11, All = true,  Type = 'Bar',        TablePath = 'BarMoon'},
      {Name = 'Power'     , Order = 12, All = true,  Type = 'Bar',        TablePath = 'BarPower'},
      {Name = 'Sun'       , Order = 13, All = true,  Type = 'Bar',        TablePath = 'BarSun'},
      {Name = 'Slider'    , Order = 14, All = true,  Type = 'Bar',        TablePath = 'BarSlider'},
      {Name = 'Charges'   , Order = 15, All = true,  Type = 'Bar',        TablePath = 'BarCharges'},
      {Name = 'Time'      , Order = 16, All = true,  Type = 'Bar',        TablePath = 'BarTime'}},

    {Name = 'Text', Order = 8,
      {Name = 'All Text'  , Order = 10, All = true,   Type = 'TextAll',   TablePath = 'Text'},
      {Name = 'Text 1'    , Order = 11, All = false,  Type = 'Text',      TablePath = 'Text.1'},
      {Name = 'Text 2'    , Order = 12, All = false,  Type = 'Text',      TablePath = 'Text.2'},
      {Name = 'Text 3'    , Order = 13, All = false,  Type = 'Text',      TablePath = 'Text.3'},
      {Name = 'Text 4'    , Order = 14, All = false,  Type = 'Text',      TablePath = 'Text.4'}},

    {Name = 'Triggers', Order = 9,
      {Name = 'Triggers'  , Order = 10, All = true,   Type = 'Triggers',  TablePath = 'Triggers.#'}},

    {Name = 'Header10', Order = 10},
  }

  CopyPasteOptions = {
    type = 'group',
    name = function()
             if ClipBoard.ButtonName then
               return format('%s: |cffffff00%s [ %s ]|r', Name, ClipBoard.BarName, ClipBoard.ButtonName)
             else
               return Name
             end
           end,
    dialogInline = true,
    order = Order,
    confirm = function(Info)
                local Name = Info[#Info]

                if strfind(Name, 'Group') == nil and Name ~= 'GroupClear' and ClipBoard.BarType then
                  return format('Copy %s from %s to %s', ClipBoard.ButtonName, ClipBoard.BarName, Main.UnitBars[BarType].Name)
                end
              end,
    func = function(Info, Value)
             local Name = Info[#Info]

             if Name ~= 'GroupClear' then
               if ClipBoard.BarType == nil then
                 local Arg = Info.arg

                 -- Store the data to the clipboard.
                 ClipBoard.BarType = BarType
                 ClipBoard.BarName = UBF.UnitBar.Name
                 ClipBoard.TablePath = Arg.TablePath
                 ClipBoard.Type = Arg.Type
                 ClipBoard.ButtonName = Arg.ButtonName
               else

                 -- Save name and locaton.
                 local UB = UBF.UnitBar
                 local Name = UB.Name
                 local x, y = UB.x, UB.y

                 if Value.Type == 'All'then
                   for _, Group in ipairs(ClipBoard) do
                     for _, Value in ipairs(Group) do
                       if Value.All then

                         -- Copy unit bar
                         local TablePath = Value.TablePath
                         Main:CopyUnitBar(ClipBoard.BarType, BarType, TablePath, TablePath)
                       end
                     end
                   end
                 else
                   Main:CopyUnitBar(ClipBoard.BarType, BarType, ClipBoard.TablePath, Info.arg.TablePath)
                 end

                 -- Restore name and location.
                 UB.Name = Name
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
             else
               ClipBoard.BarType = nil
               ClipBoard.BarName = nil
               ClipBoard.TablePath = nil
               ClipBoard.Type = nil
               ClipBoard.ButtonName = nil
             end
           end,

    -- The args get converted into controls below.
    args = {},
  }

  local Args = CopyPasteOptions.args
  local Multi = false

  -- Create the group button
  for _, Group in ipairs(ClipBoard) do
    local GroupName = Group.Name

    if GroupName ~= 'Text' or GroupName == 'Text' and DUB[BarType].Text then
      local Order = Group.Order
      local t = nil

      if strfind(GroupName, 'Spacer') ~= nil then
        t = CreateSpacer(Order)
      else
        t = {order = Order}
        if strfind(GroupName, 'Header') then
          t.type = 'header'
          t.name = ''
        else
          t.type = 'execute'
          t.name = GroupName
          t.desc = GroupName == 'Backg' and 'Background' or nil
          t.width = 'half'

          if GroupName == 'Clear' then
            t.disabled = function()
                           return HideTooltip(ClipBoard.BarType == nil)
                         end
          else
            t.func = function(Info)
                       ClipBoard.SelectedGroup = Info[#Info]
                     end
            t.disabled = function()
                           return HideTooltip(strfind(ClipBoard.SelectedGroup or '', GroupName) ~= nil)
                         end
          end
        end
      end
      Args['Group' .. GroupName] = t
    end

    -- Create the child buttons.
    for _, Value in ipairs(Group) do
      local Name = Value.Name
      local TablePath = Value.TablePath
      local Table = TablePath and Main:GetUB(BarType, TablePath) or nil
      local Text = false

      -- Flag text if multi or not.
      if TablePath and strfind(TablePath, 'Text') then
        Text = true
        if Table then
          if TablePath == 'Text' then
            Multi = Table._Multi or false
          end
        elseif not Multi then
          Text = false
        end
      end

      if Table or Text then
        local t = {}
        local Type = Value.Type
        local ButtonName = Name

        Order = Value.Order
        if (GroupName == 'Backg' or GroupName == 'Bar') and Type ~= TablePath then
          ButtonName = (GroupName == 'Backg' and 'Background' or GroupName) .. '.' .. Name
        end

        t.type = 'execute'
        t.name = Name
        t.desc =  Name == 'BG' and 'Background' or nil
        t.order = Order
        t.width = Value.Width or 'half'

        t.arg = {Type = Value.Type, TablePath = TablePath, ButtonName = ButtonName}

        -- Hide buttons when group is not selected
        t.hidden = function()
                     return strfind(ClipBoard.SelectedGroup or '', GroupName) == nil
                   end

        -- Disable the button if in paste mode.
        t.disabled = function(Info)
                       local Disable = false
                       local Dest = Main:GetUB(BarType, Info.arg.TablePath)

                       if Dest == nil then
                         Disable = true
                       elseif ClipBoard.BarType then
                         if ClipBoard.Type ~= Info.arg.Type or Main:GetUB(ClipBoard.BarType, ClipBoard.TablePath) == Dest then
                           Disable = true
                         end
                       end

                       return HideTooltip(Disable)
                     end
        Args[GroupName .. Name] = t
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

local function RefreshAuraList(AL, TrackedAuras)
  if TrackedAuras and Main.UnitBars.AuraListOn then
    AL.args = {}
    local ALA = AL.args
    local Order = 0
    local SortList = {}

    for SpellID, _ in pairs(TrackedAuras) do
      if type(SpellID) == 'number' then
        local AuraKey = format('Auras%s', SpellID)

        if ALA[AuraKey] == nil then
          local Name, _, Icon = GetSpellInfo(SpellID)
          Order = Order + 1

          local AuraDesc = {
            type = 'description',
            width = 'full',
            fontSize = 'medium',
            order = Order,
            image = Icon,
            imageWidth = 20,
            imageHeight = 20,
            name = format('%s (|cFF00FF00%s|r)', Name, SpellID),
          }
          SortList[Order] = {Name = Name, AuraDesc = AuraDesc}
          ALA[AuraKey] = AuraDesc
        end
      end
    end
    sort(SortList, AuraSort)
    for Index = 1, #SortList do
      SortList[Index].AuraDesc.order = Index
    end
  end
end

local function CreateAuraOptions(Order, Name, Desc)
  local AL = nil

  local UpdateAuras = Options:DoFunction('AuraList', 'UpdateAuras', function()
    if not Main.UnitBars.AuraListOn then
      AL.args = {}
    end
  end)

  local AuraListOptions = {
    type = 'group',
    name = Name,
    order = Order,
    desc = Desc,
    get = function(Info)
            return Main.UnitBars[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            if KeyName == 'AuraListOn' and not Value then
              AL.args = {}
            end
            Main.UnitBars[KeyName] = Value
            Main:UnitBarsSetAllOptions()
            GUB:UnitBarsUpdateStatus()
          end,
    args = {
      Description = {
        type = 'description',
        name = 'List auras in the box below from the units specified',
        order = 1,
      },
      AuraListOn = {
        type = 'toggle',
        name = 'Enable',
        order = 2,
      },
      Spacer10 = CreateSpacer(10),
      AuraListUnits = {
        type = 'input',
        name = 'Units',
        order = 11,
        desc = 'Enter the units to track auras',
        disabled = function()
                     return not Main.UnitBars.AuraListOn
                   end,
      },
      RefreshAuras = {
        type = 'execute',
        name = 'Refresh',
        desc = 'Refresh aura list',
        width = 'half',
        order = 12,
        hidden = function()  -- use this to build list when aura list is first visible.
                   RefreshAuraList(AL, Main.TrackedAuras)
                   return false
                 end,
        func = function()
                 RefreshAuraList(AL, Main.TrackedAuras)
               end,
        disabled = function()
                     return not Main.UnitBars.AuraListOn
                   end
      },
      Spacer20 = CreateSpacer(20),
      Auras = {
        type = 'group',
        name = 'Auras',
        order = 21,
        dialogInline = true,
        disabled = function()
                     return not Main.UnitBars.AuraListOn
                   end,
        args = {},
      },
    },
  }

  AL = AuraListOptions.args.Auras

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
        desc = 'Include tagged color',
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
        desc = 'Include tagged color',
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
  MainOptionsArgs.Help = {
    type = 'group',
    name = 'Help',
    order = 101,
    args = {
      Verstion = {
        type = 'description',
        name = function()
                 return format('|cffffd200%s   version %.2f|r', AddonName, Version / 100)
               end,
        order = 1,
      },
      HelpText = {
        type = 'input',
        name = '',
        order = 2,
        multiline = 23,
        width = 'full',
        get = function()
                return HelpText
              end,
      },
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
