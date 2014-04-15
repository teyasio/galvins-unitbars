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

local Main = GUB.Main
local Bar = GUB.Bar
local Options = GUB.Options

local UnitBarsF = Main.UnitBarsF
local PowerColorType = Main.PowerColorType
local LSM = Main.LSM

local HelpText = GUB.DefaultUB.HelpText

-- localize some globals.
local _
local strupper, strlower, strfind, format, strconcat, strmatch, strsplit, strsub =
      strupper, strlower, strfind, format, strconcat, strmatch, strsplit, strsub
local tonumber, gsub, min, max, tremove, wipe =
      tonumber, gsub, min, max, tremove, wipe
local ipairs, pairs, type, next =
      ipairs, pairs, type, next
local InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print, GameTooltip =
      InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print, GameTooltip
-------------------------------------------------------------------------------
-- Locals
--
-- Options.Open                  If true then the options window is opened. Otherwise closed.
-- MainOptionsFrame              Main options frame used by this addon.
-- ProfilesOptionsFrame          Used to show the profile settings in the blizzard
--                               options tree.
-- SlashOptions                  Options only used by slash commands. This is accessed
--                               by typing '/gub'.
-- GUB.Options.ATOFrame          Contains the alignment tool options window.
--
-- DoFunctions                   Table used to save and call functions thru DoFunction()
-- FontStyleDropdown             Table used for the dialog drop down for FontStyles.
-- PositionDropdown              Table used for the diaglog drop down for fonts and runes.
-- FontHAlignDropDown            Table used for the dialog drop down for font horizontal alignment.
-- ValueTypeDropdown             Table used for the dialog drop down for Health and power text type.
-- ValueNameDropdown             Table used for the dialog drop down for health and power text type.
-- DirectionDropdown             Table used to pick vertical or horizontal.
-- RuneModeDropdown              Table used to pick which mode runes are shown in.
-- RuneEnergizeDropdown          Table used for changing rune energize.
-- IndicatorDropdown             Table used to for the indicator for predicted power.
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

local ClipBoard = nil

local O = {

  -- Fade for all unitbars.
  FadeOutTime = 5,
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
  LayoutFadeOutTimeMax = 5,
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

local IndicatorDropdown = {
  showalways = 'Show Always',
  hidealways = 'Hide Always',
  auto       = 'Auto',
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

--*****************************************************************************
--
-- Options Utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- RefreshOptions
--
-- Refreshes the option panels.
-- Use this if something needs updating.
-------------------------------------------------------------------------------
function GUB.Options:RefreshOptions()
  AceConfigRegistery:NotifyChange(AddonMainOptions)
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
-- Fn              Function to be saved. If fn is nil then FunctionName() gets called.
--                 if 'clear' then all the functions under BarType are erased.
--
-- Returns:
--   Function      The function that was passed.
--
-- Note:     To call all the functions saved call it as LocalFunction()
-------------------------------------------------------------------------------
function GUB.Options:DoFunction(BarType, Fn)
  if type(Fn) == 'function' then

    -- Save the function under BarType FunctionName
    local DoFunction = DoFunctions[BarType]

    if DoFunction == nil then
      DoFunction = {}
      DoFunctions[BarType] = DoFunction
    end
    DoFunction[#DoFunction + 1] = Fn

    return Fn
  elseif Fn == 'clear' then
    if DoFunctions[BarType] then

      -- Wipe the table instead of nilling. Incase this function gets called thru DoFunction.
      wipe(DoFunctions[BarType])
    end
  else

    -- Call all functions if Fn not passed.
    for _, DF in pairs(DoFunctions) do
      for _, Fn in ipairs(DF) do
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
-- Table         Table for the spacer
-------------------------------------------------------------------------------
local function CreateSpacer(Order, Width)
  return {
    type = 'description',
    name = '',
    order = Order,
    width = Width or 'full',
  }
end

-------------------------------------------------------------------------------
-- OnOptions
--
-- Subfunction of CreateToGUBOptions()
--
-- Gets called when options is opened then again when closed.
--
-- Action     'open' then the options window was just opened.
--            'close' Options window was closed.
-------------------------------------------------------------------------------
local function OnOptions(Action)
  if Action == 'open' then
    Bar:SetHighlightFont('on', Main.UnitBars.HideTextHighlight)
    GUB.Options.Open = true
  else
    Bar:SetHighlightFont('off', Main.UnitBars.HideTextHighlight)
    GUB.Options.Open = false
  end
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
  Options.Open = false
end

local function CreateToGUBOptions(Order, Name, Desc)
  local ToGUBOptions = {
    type = 'execute',
    name = Name,
    order = Order,
    desc = Desc,
    func = function()

             -- Hide blizz blizz options if it's opened.
             if InterfaceOptionsFrame:IsVisible() then
               InterfaceOptionsFrame:Hide()

               -- Hide the UI panel behind blizz options.
               HideUIPanel(GameMenuFrame)
             end

             Bar:SetHighlightFont('on', Main.UnitBars.HideTextHighlight)
             Options.MainOpen = true

             -- Open a movable options frame.
             AceConfigDialog:Open(AddonMainOptions)

             -- Set the OnHideFrame's frame parent to AceConfigDialog's options frame.
             MainOptionsHideFrame:SetParent(AceConfigDialog.OpenFrames[AddonMainOptions].frame)

             -- When hidden call OnOptions() for close.
             MainOptionsHideFrame:SetScript('OnHide', OnHideToGUBOptions)
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
-- ColorAllTableName  Name of the table that contains the color.
--                    If nil then defauls to 'ColorAllNames'
-- Order              Position in the options list.
-- Name               Name of the options.
--
-- ColorAllOptions  Options table for the bartype.
-------------------------------------------------------------------------------
local function CreateColorAllOptions(BarType, ColorAllTableName, TableName, TablePath, KeyName, Order, Name)
  local UBF = UnitBarsF[BarType]
  local ColorAllNames = UBF[ColorAllTableName or 'ColorAllNames']

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

  for c = 1, MaxColors do
    local ColorOption = {}

    --- Create the color table
    ColorOption.type = 'color'
    ColorOption.name = ColorAllNames[c]
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
-- CreatePowerColorsOptions
--
-- Creates power color options for a UnitBar.
--
-- Subfunction of CreateBarOptions()
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
--
-- PowerColorsOptions    Options table for power colors.
-------------------------------------------------------------------------------
local function CreatePowerColorsOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local PowerColorsOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local c = UBF.UnitBar.Bar.Color[Info[#Info]]

            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local c = UBF.UnitBar.Bar.Color[Info[#Info]]

            c.r, c.g, c.b, c.a = r, g, b, a

             -- Update the bar to show the current power color change in real time.
            UBF:SetAttr('Bar', 'Color')
          end,
    args = {},
  }

  -- Power types for the player power bar. '= 0' has no meaning.
  -- These cover classes with more than one power type.
  local PlayerPower = {
    DRUID = {MANA = 0, ENERGY = 0, RAGE = 0},
    MONK  = {MANA = 0, ENERGY = 0},
  }

  local AllColor = true
  local PCOA = PowerColorsOptions.args
  if BarType == 'PlayerPower' or BarType == 'ManaPower' then
    AllColor = false
  end

  local ClassPowerType = PlayerPower[Main.PlayerClass]

  for PowerTypeName, PowerType in pairs(PowerColorType) do
    local n = gsub(strlower(PowerTypeName), '%a', strupper, 1)

    local Width = 'half'
    if PowerTypeName == 'RUNIC_POWER' then
      n = 'Runic Power'
      Width = 'normal'
    end

    if AllColor or BarType == 'ManaPower' and PowerTypeName == 'MANA' or
                   BarType ~= 'ManaPower' and
                     ( ClassPowerType and ClassPowerType[PowerTypeName] or
                       PowerType == Main.PlayerPowerType ) then
      PCOA[PowerTypeName] = {
        type = 'color',
        name = n,
        order = PowerType,
        width = Width,
        hasAlpha = true,
      }
    end
  end

  return PowerColorsOptions
end

-------------------------------------------------------------------------------
-- CreateClassColorOptions
--
-- Creates class color options for a UnitBar.
--
-- Subfunction of CreateBarOptions()
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
--
-- PowerColorsOptions    Options table for class color.
-------------------------------------------------------------------------------
local function CreateClassColorOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
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
            -- info.arg is not nil then use the hash portion of Color.
            local c = UBF.UnitBar.Bar.Color

            if Info.arg == nil then
              c = c[Info[#Info]]
            end
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            -- info.arg is not nil then use the hash portion of Color.
            local c = UBF.UnitBar.Bar.Color

            if Info.arg == nil then
              c = c[Info[#Info]]
            end

            c.r, c.g, c.b, c.a = r, g, b, a

            -- Set the color to the bar
            UBF:SetAttr('Bar', 'Color')
          end,
    args = {
      ClassColorToggle = {
        type = 'toggle',
        name = 'Class Color',
        order = 1,
        desc = 'Class color will be used',
        get = function()
                return UBF.UnitBar.Bar.Color.Class
              end,
        set = function(Info, Value)
                UBF.UnitBar.Bar.Color.Class = Value

                -- Refresh color when changing between class color and normal.
                UBF:SetAttr('Bar', 'Color')
              end,
      },
      Spacer = CreateSpacer(2),
      NormalColor = {
        type = 'color',
        name = 'Color',
        order = 3,
        hasAlpha = true,
        desc = 'Set normal color',
        hidden = function()
                   return UBF.UnitBar.Bar.Color.Class
                 end,
        arg = 0,
      },
    },
  }

  local CCOA = ClassColorOptions.args
  for Index, ClassName in ipairs(ClassColorMenu) do
    local n = gsub(strlower(ClassName), '%a', strupper, 1)
    local Width = 'half'
    if Index == 1 then
      n = 'Death Knight'
      Width = 'normal'
    end

    -- Add class color option that will be used.
    if BarType ~= 'PlayerHealth' or Main.PlayerClass == ClassName then
      CCOA[ClassName] = {
        type = 'color',
        name = n,
        order = 3 + Index,
        width = Width,
        hasAlpha = true,
        hidden = function()
                   return not UBF.UnitBar.Bar.Color.Class
                 end,
      }
    end
  end

  return ClassColorOptions
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

                if strfind(KeyName, 'Color') then
                  local c = UBF.UnitBar[TableName][KeyName]

                  return c.r, c.g, c.b, c.a
                else
                  return UBF.UnitBar[TableName].BackdropSettings[KeyName]
                end
              end,
        set = function(Info, Value, g, b, a)
                local KeyName = Info[#Info]

                if strfind(KeyName, 'Color') then
                  local c = UBF.UnitBar[TableName][KeyName]

                  c.r, c.g, c.b, c.a = Value, g, b, a
                  UBF:SetAttr(TableName, KeyName)
                else
                  UBF.UnitBar[TableName].BackdropSettings[KeyName] = Value
                  UBF:SetAttr(TableName, 'BackdropSettings')
                end
              end,
        args = {
          BdTexture = {
            type = 'select',
            name = 'Border',
            order = 1,
            dialogControl = 'LSM30_Border',
            values = LSM:HashTable('border'),
          },
          BgTexture = {
            type = 'select',
            name = 'Background',
            order = 2,
            dialogControl = 'LSM30_Background',
            values = LSM:HashTable('background'),
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
                         return not UBF.UnitBar[TableName].BackdropSettings.BgTile
                       end,
            min = O.UnitBarBgTileSizeMin,
            max = O.UnitBarBgTileSizeMax,
            step = 1,
          },
          Spacer20 = CreateSpacer(20),
          BdSize = {
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
      BackdropArgs.ColorAll = CreateColorAllOptions(BarType, nil, TableName, 'Background.Color', 'Color', 2, 'Color')
      BackdropArgs.ColorAll.hidden = function()
                                       return UBF.GreenFire
                                     end
      BackdropArgs.ColorAllGreen = CreateColorAllOptions(BarType, nil, TableName, 'Background.ColorGreen', 'ColorGreen', 2, 'Color [green fire]')
      BackdropArgs.ColorAllGreen.hidden = function()
                                            return not UBF.GreenFire
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
        BackdropArgs.ColorAll = CreateColorAllOptions(BarType, nil, TableName, TableName .. '.Color', 'Color', 2, 'Color')
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
  end

  BackdropArgs.Padding = {
    type = 'group',
    name = 'Padding',
    dialogInline = true,
    order = 10,
    get = function(Info)
            local Padding = UBF.UnitBar[TableName].BackdropSettings.Padding
            local KeyName = Info[#Info]

            if KeyName == 'All' then
              return Padding.Left
            else
              return Padding[KeyName]
            end
          end,
    set = function(Info, Value)
            local Padding = UBF.UnitBar[TableName].BackdropSettings.Padding
            local KeyName = Info[#Info]

            if KeyName == 'All' then
              Padding.Left = Value
              Padding.Right = Value
              Padding.Top = Value
              Padding.Bottom = Value
            else
              Padding[KeyName] = Value
            end
            UBF:SetAttr(TableName, 'BackdropSettings')
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
      values = LSM:HashTable('statusbar'),
    }
  end

  -- Health and Power bar
  if BarType == 'PlayerPower' and Main.PlayerClass == 'HUNTER' or
     BarType ~= 'PlayerPower' and UBD[TableName].PredictedBarTexture ~= nil then
    GeneralArgs.PredictedBarTexture = {
      type = 'select',
      name = 'Bar Texture (predicted)',
      order = 2,
      dialogControl = 'LSM30_Statusbar',
      values = LSM:HashTable('statusbar'),
    }
  end

  -- Demonic bar
  if UBD[TableName].MetaStatusBarTexture ~= nil then
    GeneralArgs.MetaStatusBarTexture = {
      type = 'select',
      name = 'Bar Texture (metamorphosis)',
      order = 2,
      dialogControl = 'LSM30_Statusbar',
      values = LSM:HashTable('statusbar'),
    }
  end

  -- Ember bar
  if UBD[TableName].FieryStatusBarTexture ~= nil then
    GeneralArgs.FieryStatusBarTexture = {
      type = 'select',
      name = 'Bar Texture (fiery embers)',
      order = 2,
      dialogControl = 'LSM30_Statusbar',
      values = LSM:HashTable('statusbar'),
    }
  end

  -- Eclipse bar
  if UBD[TableName].StatusBarTextureLunar ~= nil then
    GeneralArgs.StatusBarTextureLunar = {
      type = 'select',
      name = 'Bar Texture (lunar)',
      order = 1,
      dialogControl = 'LSM30_Statusbar',
      values = LSM:HashTable('statusbar'),
    }
  end
  if UBD[TableName].StatusBarTextureSolar ~= nil then
    GeneralArgs.StatusBarTextureSolar = {
      type = 'select',
      name = 'Bar Texture (solar)',
      order = 2,
      dialogControl = 'LSM30_Statusbar',
      values = LSM:HashTable('statusbar'),
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
  if BarType == 'PetHealth' or BarType == 'AnticipationBar' and TableName == 'BarTime' or
     BarType == 'EclipseBar' and  (TableName == 'BarMoon' or TableName == 'BarSun') then
    GeneralArgs.Color = {
      type = 'color',
      name = 'Color',
      hasAlpha = true,
      order = 21,
    }
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

  -- Predicted color
  if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' or BarType == 'PetHealth' or
     BarType == 'PlayerPower' and Main.PlayerClass == 'HUNTER' then
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

  -- Health bars    Class colors
  local Color = UBD[TableName].Color

  if Color and Color.Class ~= nil then
    GeneralArgs.ClassColor = CreateClassColorOptions(BarType, 32, 'Color')
  end

  -- Add power colors for power bars only.
  if BarType:find('Power') then

    -- Add the Power color options.
    GeneralArgs.PowerColors = CreatePowerColorsOptions(BarType, 32, 'Power Color')
  end

  -- Demonic bar.
  if UBD[TableName].ColorGreen ~= nil then
    GeneralArgs.ColorAll = CreateColorAllOptions(BarType, nil,  TableName, 'Bar.Color', 'Color', 31, 'Color')
    GeneralArgs.ColorAllFiery = CreateColorAllOptions(BarType, nil, TableName, 'Bar.ColorFiery', 'ColorFiery', 31, 'Color (fiery embers)')
    GeneralArgs.ColorAllGreen = CreateColorAllOptions(BarType, nil, TableName, 'Bar.ColorGreen', 'ColorGreen', 31, 'Color [green fire]')
    GeneralArgs.ColorAllFieryGreen = CreateColorAllOptions(BarType, nil, TableName, 'Bar.ColorFieryGreen', 'ColorFieryGreen', 32, 'Color (fiery embers) [green fire]')
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
      GeneralArgs.ColorAll = CreateColorAllOptions(BarType, nil, TableName, TableName .. '.Color', 'Color', 31, 'Color')
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
        values = LSM:HashTable('font'),
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
    TextOptions.args.TextColors = CreateColorAllOptions(BarType, nil, 'Text', 'Text.1.Color', '_Font', Order, 'Color')
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
                ValueType[ValueIndex] =  ConvertValueType[Value]
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
  local DoCreateText = Options:DoFunction(BarType, function()
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
  StatusArgs.HideWhenDead = {
    type = 'toggle',
    name = 'Hide when Dead',
    order = 2,
    desc = "Hides the bar when you're dead",
  }
  StatusArgs.HideInVehicle = {
    type = 'toggle',
    name = 'Hide in Vehicle',
    order = 3,
    desc = "Hides the bar when you're in a vehicle",
  }
  StatusArgs.HideInPetBattle = {
    type = 'toggle',
    name = 'Hide in Pet Battle',
    order = 4,
    desc = "Hides the bar when you're in a pet battle",
  }
  if UBD.Status.HideNotActive ~= nil then
    StatusArgs.HideNotActive = {
      type = 'toggle',
      name = 'Hide not Active',
      order = 5,
      desc = 'Bar will be hidden if its not active. This only gets checked out of combat',
    }
  end
  StatusArgs.HideNoCombat = {
    type = 'toggle',
    name = 'Hide no Combat',
    order = 6,
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

  if UBD.TestMode.MaxResource ~= nil then
    TestModeArgs.MaxResource = {
      type = 'toggle',
      name = 'Show Max Resource',
      desc = 'Show the maximum amount of resource',
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
  if UBD.TestMode.ShowEnergize ~= nil then
    TestModeArgs.ShowEnergize = {
      type = 'toggle',
      name = 'Show Empowerment',
      desc = 'Shows empowered runes',
      order = 3,
    }
  end
  if UBD.TestMode.ShowMeta ~= nil then
    TestModeArgs.ShowMeta = {
      type = 'toggle',
      name = 'Show Metamorphosis',
      desc = 'Show metamorphosis',
      order = 4,
    }
  end
  if UBD.TestMode.ShowFiery ~= nil then
    TestModeArgs.ShowFiery = {
      type = 'toggle',
      name = 'Show Fiery Embers',
      desc = 'Show fiery embers',
      order = 5,
    }
  end
  if UBD.TestMode.ShowEclipseSun ~= nil then
    TestModeArgs.ShowEclipseSun = {
      type = 'toggle',
      name = 'Show Eclipse Sun',
      desc = 'Show a sun eclipse',
      order = 6,
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
  if UBD.Layout.HideRegion ~= nil then
    Spacer = true
    LayoutArgs.HideRegion = {
      type = 'toggle',
      name = 'Hide Region',
      order = 2,
      desc = "Hides the bar's region",
    }
  end
  if Spacer then
    LayoutArgs.Spacer10 = CreateSpacer(10)
    Spacer = false
  end

  if UBD.Layout.Swap ~= nil then
    Spacer = true
    LayoutArgs.Swap = {
      type = 'toggle',
      name = 'Swap',
      order = 11,
      desc = 'Allows you to swap one bar object with another by dragging it',
    }
  end
  if UBD.Layout.Float ~= nil then
    Spacer = true
    LayoutArgs.Float = {
      type = 'toggle',
      name = 'Float',
      order = 12,
      desc = 'Switches to floating mode.  Bar objects can be placed anywhere. Float options will be open below',
    }
  end
  if Spacer then
    LayoutArgs.Spacer20 = CreateSpacer(20)
    Spacer = false
  end

  if UBD.Layout.ReverseFill ~= nil then
    Spacer = true
    LayoutArgs.ReverseFill = {
      type = 'toggle',
      name = 'Reverse fill',
      order = 21,
      desc = 'Fill in reverse',
    }
  end
  if UBD.Layout.HideText ~= nil then
    Spacer = true
    LayoutArgs.HideText = {
      type = 'toggle',
      name = 'Hide Text',
      order = 22,
      desc = 'Hides all text',
    }
  end
  if Spacer then
    LayoutArgs.Spacer30 = CreateSpacer(30)
    Spacer = false
  end

  if UBD.Layout.BorderPadding ~= nil then
    Spacer = true
    LayoutArgs.BorderPadding = {
      type = 'range',
      name = 'Border Padding',
      order = 31,
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
      order = 32,
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
    LayoutArgs.Spacer40 = CreateSpacer(40)
    Spacer = false
  end

  if UBD.Layout.Slope ~= nil then
    Spacer = true
    LayoutArgs.Slope = {
      type = 'range',
      name = 'Slope',
      order = 41,
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
      order = 42,
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
    LayoutArgs.Spacer50 = CreateSpacer(50)
    Spacer = false
  end

  if UBD.Layout.SmoothFill ~= nil then
    Spacer = true
    LayoutArgs.SmoothFill = {
      type = 'range',
      name = 'Smooth Fill',
      order = 51,
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
      order = 52,
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
    LayoutArgs.Spacer60 = CreateSpacer(60)
    Spacer = false
  end

  if UBD.Layout.FadeInTime ~= nil then
    Spacer = true
    LayoutArgs.FadeInTime = {
      type = 'range',
      name = BarType == 'EmberBar' and 'Fiery Ember Fade-in' or
             BarType == 'EclipseBar' and 'Eclipse Fade-in' or
             'Fade-in',
      order = 61,
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
      order = 62,
      desc = 'Amount of time in seconds to fade out a bar object',
      step = 1,
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
            UBF.UnitBar.General[KeyName] = Value

            UBF:SetAttr('General', KeyName)
          end,
    args = {}
  }

  local GeneralArgs = GeneralOptions.args

  -- Health and power bar options.
  if UBD.General.PredictedHealth ~= nil then
    GeneralArgs.PredictedHealth = {
      type = 'toggle',
      name = 'Predicted Health',
      order = 1,
      desc = 'Predicted health will be shown',
    }
  end
  if BarType == 'PlayerPower' and Main.PlayerClass == 'HUNTER' or
     BarType ~= 'PlayerPower' and UBD.General.PredictedPower ~= nil then
    GeneralArgs.PredictedPower = {
      type = 'toggle',
      name = 'Predicted Power',
      order = 1,
      desc = 'Predicted power will be shown',
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
          Color = CreateColorAllOptions(BarType, nil, 'General', 'General.ColorEnergize', 'ColorEnergize', 2, 'Color'),
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
      PredictedPower = {
        type = 'toggle',
        name = 'Predicted Power',
        order = 5,
        desc = 'The energy from wrath, starfire and starsurge will be shown ahead of time. Predicted options group will open up below',
      },
      Spacer10 = CreateSpacer(10),
      PredictedOptions = {
        type = 'group',
        name = 'Predicted Options',
        dialogInline = true,
        order = 11,
        hidden = function()
                   return not UBF.UnitBar.General.PredictedPower
                 end,
        args = {
          PredictedPowerHalfLit = {
            type = 'toggle',
            name = 'Power Half Lit',
            order = 1,
            desc = 'Power Half Lit is based on predicted power',
            disabled = function()
                         return not UBF.UnitBar.General.PowerHalfLit
                       end,
          },
          PredictedPowerText = {
            type = 'toggle',
            name = 'Power Text',
            order = 2,
            desc = 'Predicted power text will be shown instead',
            disabled = function()
                         return UBF.UnitBar.Layout.HideText
                       end,
          },
          PredictedEclipse = {
            type = 'toggle',
            name = 'Eclipse',
            order = 3,
            desc = 'The sun or moon will light up based on predicted power',
          },
          IndicatorHideShow  = {
            type = 'select',
            name = 'Indicator (predicted power)',
            order = 4,
            desc = 'Hide or Show the indicator',
            values = IndicatorDropdown,
            style = 'dropdown',
          },
        },
      },
      Spacer20 = CreateSpacer(20),
      SliderDirection = {
        type = 'select',
        name = 'Slider Direction',
        order = 21,
        values = DirectionDropdown,
        style = 'dropdown',
        desc = 'Specifies the direction the slider will move in'
      },
    },
  }
  return GeneralEclipseBarOptions
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
      Spacer = CreateSpacer(10),
      Reset = {
        type = 'execute',
        name = 'Reset Defaults',
        order = 11,
        desc = "Sets the bar to its default values. Location doesn't get changed",
        confirm = true,
        func = function()

                 -- Preserve bar location
                 local UB = UBF.UnitBar
                 local x, y =  UB.x, UB.y

                 -- Copy defaults to UnitBar wihout deleting the table.  This will empty it
                 -- then fill it with contents from default.
                 Main:CopyTableValues(DUB[BarType], UBF.UnitBar, true)
                 UB.x, UB.y = x, y

                 -- Update the layout.
                 UBF:SetAttr()
                 UBF:StatusCheck()
                 UBF:Update()

                 -- Update any dynamic options.
                 Options:DoFunction()
               end,
      },
      ResetPosition = {
        type = 'execute',
        name = 'Reset Location',
        order = 12,
        desc = 'Sets the bar to its default location',
        confirm = true,
        func = function()

                 -- Get the anchor and default bar location.
                 local Anchor = UBF.Anchor
                 local UBd = DUB[BarType]
                 local UB = UBF.UnitBar
                 local x, y = UBd.x, UBd.y

                 -- Save the defalt location.
                 UB.x, UB.y = x, y

                 -- Set the bar location on screen.
                 Anchor:ClearAllPoints()
                 Anchor:SetPoint('TOPLEFT' , x, y)
               end,
      },
    },
  }

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
    {Name = 'Spacer2', Order = 2},

    {Name = 'Main', Order = 5,
      {Name = 'All'          , Order = 10, All = false, Type = 'All',        TablePath = ''},
      {Name = 'Status'       , Order = 11, All = true,  Type = 'Status',     TablePath = 'Status'},
      {Name = 'Layout'       , Order = 12, All = true,  Type = 'Layout',     TablePath = 'Layout'},
      {Name = 'Other'        , Order = 13, All = true,  Type = 'Other',      TablePath = 'Other'}},

    {Name = 'Backg', Order = 6,
      {Name = 'BG'        , Order = 10, All = true,  Type = 'Background', TablePath = 'Background'},
      {Name = 'Moon'      , Order = 11, All = true,  Type = 'Background', TablePath = 'BackgroundMoon'},
      {Name = 'Power'     , Order = 12, All = true,  Type = 'Background', TablePath = 'BackgroundPower'},
      {Name = 'Sun'       , Order = 13, All = true,  Type = 'Background', TablePath = 'BackgroundSun'},
      {Name = 'Slider'    , Order = 14, All = true,  Type = 'Background', TablePath = 'BackgroundSlider'},
      {Name = 'Indicator' , Order = 15, All = true,  Type = 'Background', TablePath = 'BackgroundIndicator'},
      {Name = 'Charges'   , Order = 16, All = true,  Type = 'Background', TablePath = 'BackgroundCharges'},
      {Name = 'Time'      , Order = 17, All = true,  Type = 'Background', TablePath = 'BackgroundTime'}},

    {Name = 'Bar', Order = 7,
      {Name = 'Bar'       , Order = 10, All = true,  Type = 'Bar',        TablePath = 'Bar'},
      {Name = 'Moon'      , Order = 11, All = true,  Type = 'Bar',        TablePath = 'BarMoon'},
      {Name = 'Power'     , Order = 12, All = true,  Type = 'Bar',        TablePath = 'BarPower'},
      {Name = 'Sun'       , Order = 13, All = true,  Type = 'Bar',        TablePath = 'BarSun'},
      {Name = 'Slider'    , Order = 14, All = true,  Type = 'Bar',        TablePath = 'BarSlider'},
      {Name = 'Indicator' , Order = 15, All = true,  Type = 'Bar',        TablePath = 'BarIndicator'},
      {Name = 'Charges'   , Order = 16, All = true,  Type = 'Bar',        TablePath = 'BarCharges'},
      {Name = 'Time'      , Order = 17, All = true,  Type = 'Bar',        TablePath = 'BarTime'}},

    {Name = 'Text', Order = 8,
      {Name = 'All Text'  , Order = 10, All = true,   Type = 'TextAll',    TablePath = 'Text'},
      {Name = 'Text 1'    , Order = 11, All = false,  Type = 'Text',       TablePath = 'Text.1'},
      {Name = 'Text 2'    , Order = 12, All = false,  Type = 'Text',       TablePath = 'Text.2'},
      {Name = 'Text 3'    , Order = 13, All = false,  Type = 'Text',       TablePath = 'Text.3'},
      {Name = 'Text 4'    , Order = 14, All = false,  Type = 'Text',       TablePath = 'Text.4'}},
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
                 UBF:SetAttr()
                 UBF:StatusCheck()
                 UBF:Update()

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
        PredictedSlider = CreateBackdropOptions(BarType, 'BackgroundIndicator', 5, 'Indicator'),
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
        PredictedSlider = CreateBarOptions(BarType, 'BarIndicator', 5, 'Indicator'),
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
        order = 1,
        get = function(Info)
                return Main.UnitBars[Info[#Info]]
              end,
        set = function(Info, Value)
                Main.UnitBars[Info[#Info]] = Value
                Main:UnitBarsSetAllOptions()
                GUB:UnitBarsUpdateStatus()
              end,
        args = {
          Main = {
            name = 'Main',
            type = 'group',
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
                step = 0.10,
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
                step = 1,
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

--[[
--=============================================================================
-------------------------------------------------------------------------------
--    TOOLS group.
-------------------------------------------------------------------------------
--=============================================================================
      Tools = {
        type = 'group',
        name = 'Tools',
        order = 3,
        args = {
        },
      },
--]]
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
            SetSize()
            return Main.UnitBars[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            if KeyName == 'Swap' and Value then
              Main.UnitBars.Align = false
            elseif KeyName == 'Align' and Value then
              Main.UnitBars.Swap = false
            end
            Main.UnitBars[KeyName] = Value
            SetSize()
            Main:SetUnitBarsAlignSwap()
          end,
    args = {
      Align = {
        type = 'toggle',
        name = 'Align',
        order = 1,
        width = 'half',
        desc = 'When a bar is dragged near another it will align its self to it',
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
      },
      AlignSwapPaddingX = {
        type = 'range',
        name = 'Padding Horizontal',
        order = 11,
        desc = 'Sets the distance between two or more bars that are aligned horizontally',
        step = 1,
      },
      AlignSwapPaddingY = {
        type = 'range',
        name = 'Padding Vertical',
        order = 12,
        desc = 'Sets the distance between two or more bars that are aligned vertically',
        step = 1,
      },
      AlignSwapOffsetX = {
        type = 'range',
        name = 'Offset Horizontal',
        order = 21,
        desc = 'Offsets the padding group',
        step = 1,
      },
      AlignSwapOffsetY = {
        type = 'range',
        name = 'Offset Vertical',
        order = 22,
        desc = 'Offsets the padding group',
        step = 1,
      },
    }
  }

  return AlignSwapOptions
end

-------------------------------------------------------------------------------
-- OpenAlignSwapOptions
--
-- Opens up a window with the align and swap options for unitbars.
-------------------------------------------------------------------------------
local function OnHideAlignSwapOptions(self)
  self:SetScript('OnHide', nil)
  self.OptionFrame:SetClampedToScreen(self.IsClamped)

  Options.AlignSwapOpen = false
  Main:MoveFrameSetAlignPadding(Main.UnitBarsFE, 'reset')
end

function GUB.Options:OpenAlignSwapOptions()
  AceConfigDialog:SetDefaultSize(AddonAlignSwapOptions, 400, 200)
  AceConfigDialog:Open(AddonAlignSwapOptions)

  local OptionFrame = AceConfigDialog.OpenFrames[AddonAlignSwapOptions].frame
  SwapAlignOptionsHideFrame:SetParent(OptionFrame)

  SwapAlignOptionsHideFrame:SetScript('OnHide', OnHideAlignSwapOptions)
  SwapAlignOptionsHideFrame.IsClamped = OptionFrame:IsClampedToScreen() and true or false
  SwapAlignOptionsHideFrame.OptionFrame = OptionFrame
  OptionFrame:SetClampedToScreen(true)

  Options.AlignSwapOpen = true
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
