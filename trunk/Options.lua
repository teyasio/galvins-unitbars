--
-- Options.lua
--
-- Handles all the options for GalvinUnitBars.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local WoWUI = GUB.WoWUI
local UnitBarsF = GUB.UnitBarsF
local PowerColorType = GUB.PowerColorType
local LSM = GUB.LSM

local Defaults = GUB.Defaults
local HelpText = GUB.Help.HelpText

-- localize some globals.
local _
local strupper, strlower, format, tonumber, strconcat, strfind, gsub, strsub, min, max =
      strupper, strlower, format, tonumber, strconcat, strfind, gsub, strsub, min, max
local ipairs, pairs, type =
      ipairs, pairs, type
local InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print =
      InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print
-------------------------------------------------------------------------------
-- Locals
--
-- MainOptionsFrame              Main options frame used by this addon.
-- ProfilesOptionsFrame          Used to show the profile settings in the blizzard
--                               options tree.
-- MainOptions                   Table containing the options data to display in
--                               options frame.
-- SlashOptions                  Options only used by slash commands. This is accessed
--                               by typing '/gub'.
-- ProfileOptions                Options for the profiles.
-- GUB.Options.ATOFrame          Contains the alignment tool options window.
--
-- CapCopyUB                     Used for copy/paste. Contains the UnitBar data being copied.
-- CapCopyName                   Used for copy/paste. Contains the bars name of the data being copied.
-- CapCopyKey                    Used for copy/paste. Contains the unitbar key for copying.
--
-- SetFunctions                  Table used to save and call functions thru SetFunction()
-- FontStyleDropdown             Table used for the dialog drop down for FontStyles.
-- PositionDropdown              Table used for the diaglog drop down for fonts and runes.
-- FontHAlignDropDown            Table used for the dialog drop down for font horizontal alignment.
-- ValueTypeDropdown             Table used for the dialog drop down for Health and power text type.
-- ValueNameDropdown             Table used for the dialog drop down for health and power text type.
-- ValueNameDropdownPredicted    Same as above except used for bars that support predicted value.
-- MaxValuesDropdown             Tanle used for the dialog drop down for Health and power text type.
-- DirectionDropdown             Table used to pick vertical or horizontal.
-- RuneModeDropdown              Table used to pick which mode runes are shown in.
-- RuneEnergizeDropdown          Table used for changing rune energize.
-- IndicatorDropdown             Table used to for the indicator for predicted power.
-- FrameStrataDropdown           Table used for changing the frame strats for any unitbar.
-------------------------------------------------------------------------------

-- Addon Constants
local AddonName = GetAddOnMetadata(MyAddon, 'Title')
local AddonVersion = GetAddOnMetadata(MyAddon, 'Version')
local AddonOptionsName = MyAddon .. 'options'
local AddonProfileName = MyAddon .. 'profile'
local AddonSlashName = MyAddon

local SetFunctions = {}

local MainOptionsFrame = nil
local ProfileFrame = nil

local SlashOptions = nil
local MainOptions = nil
local ProfileOptions = nil

local UnitBars = nil
local PlayerClass = nil
local PlayerPowerType = nil

local CapCopyUB = nil
local CapCopyName = nil
local CapCopyKey = nil

local FontOffsetXMin = -150
local FontOffsetXMax = 150
local FontOffsetYMin = -150
local FontOffsetYMax = 150
local FontShadowOffsetMin = 0
local FontShadowOffsetMax = 10

local UnitBarPaddingMin = -20
local UnitBarPaddingMax = 20
local UnitBarBgTileSizeMin = 1
local UnitBarBgTileSizeMax = 100
local UnitBarBorderSizeMin = 2
local UnitBarBorderSizeMax = 32
local UnitBarFontSizeMin = 6
local UnitBarFontSizeMax = 64
local UnitBarFontFieldWidthMin = 20
local UnitBarFontFieldWidthMax = 400
local UnitBarScaleMin = 0.10
local UnitBarScaleMax = 4
local UnitBarWidthMin = 10
local UnitBarWidthMax = 500
local UnitBarHeightMin = 10
local UnitBarHeightMax = 500
local UnitBarSoftMin = 10
local UnitBarSoftMax = 500
local UnitBarOffset = 25

local RuneBarAngleMin = 45
local RuneBarAngleMax = 360
local RuneBarSizeMin = 10
local RuneBarSizeMax = 100
local RuneBarPaddingMin = -10
local RuneBarPaddingMax = 50
local RuneOffsetXMin = -50
local RuneOffsetXMax = 50
local RuneOffsetYMin = -50
local RuneOffsetYMax = 50
local RuneEnergizeTimeMin = 0
local RuneEnergizeTimeMax = 5

local ComboBarPaddingMin = -10
local ComboBarPaddingMax = 50
local ComboBarFadeOutMin = 0
local ComboBarFadeOutMax = 5
local ComboBarAngleMin = 45
local ComboBarAngleMax = 360

local HolyBarSizeMin = 0.01
local HolyBarSizeMax = 3
local HolyBarScaleMin = 0.1
local HolyBarScaleMax = 2
local HolyBarPaddingMin = -50
local HolyBarPaddingMax = 50
local HolyBarFadeOutMin = 0
local HolyBarFadeOutMax = 5
local HolyBarAngleMin = 45
local HolyBarAngleMax = 360

local ShardBarSizeMin = 0.01
local ShardBarSizeMax = 3
local ShardBarScaleMin = 0.1
local ShardBarScaleMax = 2
local ShardBarPaddingMin = -50
local ShardBarPaddingMax = 50
local ShardBarFadeOutMin = 0
local ShardBarFadeOutMax = 5
local ShardBarAngleMin = 45
local ShardBarAngleMax = 360

local EclipseBarFadeOutMin = 0
local EclipseBarFadeOutMax = 5
local EclipseAngleMin = 90
local EclipseAngleMax = 360
local EclipseSunOffsetXMin = -50
local EclipseSunOffsetXMax = 50
local EclipseSunOffsetYMin = -50
local EclipseSunOffsetYMax = 50
local EclipseMoonOffsetXMin = -50
local EclipseMoonOffsetXMax = 50
local EclipseMoonOffsetYMin = -50
local EclipseMoonOffsetYMax = 50

-- Size variables for combo, holy, and shard bars.
local BoxBarWidthMin = 10
local BoxBarWidthMax = 100
local BoxBarHeightMin = 10
local BoxBarHeightMax = 100

local FontStyleDropdown = {
  NONE = 'None',
  OUTLINE = 'Outline',
  THICKOUTLINE = 'Thick Outline',
  ['NONE, MONOCHROME'] = 'No Outline, Mono',
  ['OUTLINE, MONOCHROME'] = 'Outline, Mono',
  ['THICKOUTLINE, MONOCHROME'] = 'Thick Outline, Mono',
}

local FontHAlignDropdown = {
  LEFT = 'Left',
  CENTER = 'Center',
  RIGHT = 'Right'
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

local ValueTypeDropdown = {
  none = 'No value',
  whole = 'Whole',
  whole_dgroups = 'Whole (Digit Groups)',
  percent = 'Percentage',
  thousands = 'Thousands',
  millions = 'Millions',
  short = 'Short',
}

local MaxValuesDropdown = {
  [0] = 'None',
  [1] = '1',
  [2] = '2',
  [3] = '3',
}

local ValueNameDropdown = {
  current = 'Current Value',
  maximum = 'Maximum Value',
}

local ValueNameDropdownPredicted = {
  current = 'Current Value',
  maximum = 'Maximum Value',
  predicted = 'Predicted Value',
}

local TextTypeLayout = {
  none = '',
  whole = '%d',
  whole_dgroups = '%s',
  percent = '%d%%',
  thousands = '%.fk',
  millions = '%.1fm',
  short = '%s',
}

local DirectionDropdown = {
  HORIZONTAL = 'Horizontal',
  VERTICAL = 'Vertical'
}

local RuneModeDropdown = {
  rune = 'Runes',
  cooldownbar = 'Cooldown Bars',
  runecooldownbar = 'Cooldown Bars and Runes'
}

local RuneEnergizeDropdown = {
  rune = 'Runes',
  cooldownbar = 'Cooldown Bars',
  runecooldownbar = 'Cooldown Bars and Runes',
  none = 'None',
}

local IndicatorDropdown = {
  showalways = 'Show Always',
  hidealways = 'Hide always',
  none       = 'None',
}

local FrameStrataDropdown = {
  [1] = 'Background',
  [2] = 'Low',
  [3] = 'Medium (default)',
  [4] = 'High',
  [5] = 'Dialog',
  [6] = 'Full Screen',
  [7] = 'Full Screen Dialog',
  [8] = 'Tooltip',
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
  [1] = 'BACKGROUND',
  [2] = 'LOW',
  [3] = 'MEDIUM',
  [4] = 'HIGH',
  [5] = 'DIALOG',
  [6] = 'FULLSCREEN',
  [7] = 'FULLSCREEN_DIALOG',
  [8] = 'TOOLTIP',
}

--*****************************************************************************
--
-- Options creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetFunction
--
-- Stores a list of functions that can be called on to change settings.
--
-- Usage:  SetFunction(Label, Fn)
--
-- Label     Name to save the function under.
-- Fn        Function to be saved. If fn is nil or not specified then
--           the function saved under Label gets called.
--
-- Note:     To call all the functions saved call it as SetFunction()
-------------------------------------------------------------------------------
local function SetFunction(Label, Fn)

  if Fn then

    -- Save function under new label.
    if SetFunctions[Label] == nil then
      SetFunctions[Label] = Fn
    end
  elseif Label then

    -- Call function saved to label.
    SetFunctions[Label]()
  else

    -- Call all functions if label or Fn not passed.
    for _, f in pairs(SetFunctions) do
      f()
    end
  end
end

-------------------------------------------------------------------------------
-- ShareData
--
-- Main.lua calls this when values change.
--
-- NOTE: See Main.lua on how this is called.
-------------------------------------------------------------------------------
function GUB.Options:ShareData(UB, PC, PCID, PPT)
  UnitBars = UB
  PlayerClass = PC
  PlayerPowerType = PPT

  -- Set all min/max
  SetFunction()
end

-------------------------------------------------------------------------------
-- ListChecked
--
-- Checks a list of true and false values.  If true is found then it returns
-- true otherwise false
--
-- Usage: Checked = ListChecked(List, HiddenList)
--
-- List           Table containing true/false values
-- HiddenList     Table containing the check boxes that are hidden.
--
-- Checked        Returns true if true was found in the list that wasn't hidden otherwise false.
-------------------------------------------------------------------------------
local function ListChecked(List, HiddenList)
  local Checked = false
  for k, v in pairs(List) do
    if v and not HiddenList[k] then
      Checked = true
    end
  end
  return Checked
end

-------------------------------------------------------------------------------
-- GetTable
--
-- Returns a unitbar table depending on values passed.
--
-- Usage Table = GetTable(BarType, TableName, SubTableName)
--
-- BarType        Name of the bar.
-- TableName      Table inside of UnitBars[BarType]
-- SubTableName   Sub table inside of Unitbars[BarType][TableName]
--                if SubTableName is nil then just UnitBars[BarType][TableName] is returned
--
-- Table          Table returned.
-------------------------------------------------------------------------------
local function GetTable(BarType, TableName, SubTableName)
  if SubTableName then
    return UnitBars[BarType][TableName][SubTableName]
  else
    return UnitBars[BarType][TableName]
  end
end

-------------------------------------------------------------------------------
-- CreateSpacer
--
-- Creates type 'description' for full width.  This is used to create a blank
-- line so that option elements appear in certain places on the screen.
--
-- Usage Table = CreateSpacer(Order)
--
-- Order         Order number
-- Table         Table for the spacer
-------------------------------------------------------------------------------
local function CreateSpacer(Order)
  return {
    type = 'description',
    name = '',
    order = Order,
  }
end

-------------------------------------------------------------------------------
-- CreateSlashOptions()
--
-- Returns a slash options table for unitbars.
-------------------------------------------------------------------------------

--=============================================================================
--=============================================================================
--Galvin's Slash Options Group.
--=============================================================================
--=============================================================================
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
                print(AddonName, 'Version ', AddonVersion)
               end,
      },
      config = {
        type = 'execute',
        name = 'config',
        order = 2,
        desc = 'Opens a movable options frame',
        func = function()

                 -- Hide blizz blizz options if it's opened.
                 if InterfaceOptionsFrame:IsVisible() then
                   InterfaceOptionsFrame:Hide()

                   -- Hide the UI panel behind blizz options.
                   HideUIPanel(GameMenuFrame)
                 end

                 -- Open a movable options frame.
                 LibStub('AceConfigDialog-3.0'):Open(AddonOptionsName)
               end,
      },
    },
  }
  return SlashOptions
end

-------------------------------------------------------------------------------
-- CreateAlphaOption
--
-- Creates an alpha option slider.
--
-- Usage: AlphaOption = CreateAlphaOption(BarType, Order)
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
-- Creates all color options for background, bar, and text. That support multiple colors.
--
-- Subfunction of CreateBackgroundOptions()
-- Subfunction of CreateBarOptions()
-- Subfunction of CreateTextOptions()
-- Subfunction of CreateRuneBarOptions()
--
-- Usage: ColorAllOptions = CreateColorAllOptions(BarType, Object, MaxColors, Order, Name)
--
-- BarType       Type of options being created.
-- Object        Can be 'bg', 'bar', or 'text'
-- TableName     Table inside of Object.  If nil then its ignored.
-- MaxColors     Maximum number of colors can be 3, 5, 6 or 8.
-- Order         Order number.
-- Name          Name text
--
-- ColorAllOptions  Options table for the bartype.
-------------------------------------------------------------------------------
local function CreateColorAllOptions(BarType, Object, MaxColors, Order, Name)
  local UBF = UnitBarsF[BarType]
  local ColorAllNames = UBF.ColorAllNames
  local UnitBarTable = nil
  local TableName = nil

  if Object == 'bg' then
    UnitBarTable = 'Background'
  elseif Object == 'bar' then
    UnitBarTable = 'Bar'
  elseif Object == 'text' then
    UnitBarTable = 'Text'
  elseif Object == 'runebarenergize' then
    Object = 'texture'
    UnitBarTable = 'General'
    TableName = 'Energize'
  end

  local ColorAllOptions = {
    type = 'group',
    name = Name,
    order = Order,
    hidden = function()
               return Object == 'bg' and ( BarType == 'HolyBar' or BarType == 'ShardBar' ) and
                      not UBF.UnitBar.General.BoxMode
             end,
    dialogInline = true,
    get = function(Info)
            local ColorIndex = tonumber(Info[#Info])
            local CurrentTable = GetTable(BarType, UnitBarTable, TableName)
            local c = CurrentTable.Color

            if ColorIndex > 0 then
              c = CurrentTable.Color[ColorIndex]
            end
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local ColorIndex = tonumber(Info[#Info])
            local CurrentTable = GetTable(BarType, UnitBarTable, TableName)
            local c = CurrentTable.Color

            if ColorIndex > 0 then
              c = CurrentTable.Color[ColorIndex]
            end

            c.r, c.g, c.b, c.a = r, g, b, a

            -- Set the color to the bar
            UBF:SetAttr(Object, 'color')
          end,
    args = {
      ColorAllToggle = {
        type = 'toggle',
        name = 'All',
        order = 1,
        desc = 'If checked, everything can be set to one color',
        get = function()
                return GetTable(BarType, UnitBarTable, TableName).ColorAll
              end,
        set = function(Info, Value)
                GetTable(BarType, UnitBarTable, TableName).ColorAll = Value

                -- Refresh colors when changing between all and normal.
                UBF:SetAttr(Object, 'color')
              end,
      },
      ['0'] = {
        type = 'color',
        name = 'Color',
        order = 2,
        hasAlpha = true,
        desc = 'Set everything to one color',
        hidden = function()
                   return not GetTable(BarType, UnitBarTable, TableName).ColorAll
                 end,
      },
      Spacer = CreateSpacer(3),
    },
  }
  local t = ColorAllOptions.args

  for c = 1, MaxColors do
    local ColorTable = {}

    --- Create the color table
    ColorTable.type = 'color'
    ColorTable.name = ColorAllNames[c]
    ColorTable.order = c + 3
    ColorTable.hasAlpha = true
    ColorTable.hidden = function()
                          return GetTable(BarType, UnitBarTable, TableName).ColorAll
                        end

    -- Add it to the options table
    t[format('%s', c)] = ColorTable
  end

  return ColorAllOptions
end

-------------------------------------------------------------------------------
-- CreateEclipseColorOptions
--
-- Creates all color options for the eclipse slider.
--
-- Subfunction of CreateBackgroundOptions()
-- Subfunction of CreateBarOptions()
--
-- Usage: SliderColorOptions = CreateEclipseSliderColorOptions(BarType, Object, TableName, Order, Name)
--
-- BarType       Type options being created.
-- Object        Can be 'bg', 'bar'
-- TableName     Name of the table inside of Object.
-- Order         Order number.
-- Name          Name text
--
-- SliderColorOptions  Options table for the eclipse slider
-------------------------------------------------------------------------------
local function CreateEclipseColorOptions(BarType, Object, TableName, Order, Name)
  local UBF = UnitBarsF[BarType]
  local UnitBarTable = nil
  TableName = gsub(TableName, '%a', strupper, 1)

  if Object == 'bg' then
    UnitBarTable = 'Background'
  elseif Object == 'bar' then
    UnitBarTable = 'Bar'
  end

  local EclipseColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    args = {
      SunMoon = {
        type = 'toggle',
        name = 'Sun and Moon',
        order = 1,
        desc = 'If checked, the sun and moon color will be used',
        get = function()
                return UBF.UnitBar[UnitBarTable][TableName].SunMoon
              end,
        set = function(Info, Value)
                UBF.UnitBar[UnitBarTable][TableName].SunMoon = Value

                -- Update the bar to update shared colors.
                UBF:Update()
              end,
      },
      SliderColor = {
        type = 'color',
        name = 'Color',
        hasAlpha = true,
        order = 2,
        hidden = function()
                   return UBF.UnitBar[UnitBarTable][TableName].SunMoon
                 end,
        get = function(Info)
                local c = UBF.UnitBar[UnitBarTable][TableName].Color
                return c.r, c.g, c.b, c.a
              end,
        set = function(Info, r, g, b, a)
                local c = UBF.UnitBar[UnitBarTable][TableName].Color
                c.r, c.g, c.b, c.a = r, g, b, a

                UBF:SetAttr(Object, 'color', strlower(TableName))

                -- Set the color to the bar
                UBF:Update()
              end,
      },
    },
  }

  return EclipseColorOptions
end

-------------------------------------------------------------------------------
-- CreateBackgroundOptions
--
-- Creates background options for a unitbar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: BackgroundOptions = CreateBackgroundOptions(BarType, Object, Order, Name)
--
-- BarType               Type options being created.
-- Object                If not nil then UnitBars[BarType].Background[Object] is used.
-- Order                 Order number.
-- Name                  Name text
--
-- BackgroundOptions     Options table for background options.
-------------------------------------------------------------------------------
local function CreateBackgroundOptions(BarType, Object, Order, Name)
  local UBF = UnitBarsF[BarType]
  local TableName = nil
  if Object then
    TableName = gsub(Object, '%a', strupper, 1)
  end

  local BackgroundOptions = {
    type = 'group',
    name = Name,
    order = Order,
    hidden = function()
               return BarType == 'RuneBar' and UBF.UnitBar.General.RuneMode == 'rune' or
                      BarType == 'DemonicBar' and not UBF.UnitBar.General.BoxMode
             end,
    args = {
      General = {
        type = 'group',
        name = 'General',
        dialogInline = true,
        order = 1,
        get = function(Info)
                return GetTable(BarType, 'Background', TableName).BackdropSettings[Info[#Info]]
              end,
        set = function(Info, Value)
                GetTable(BarType, 'Background', TableName).BackdropSettings[Info[#Info]] = Value
                if Object then
                  UBF:SetAttr('bg', 'backdrop', Object)

                  -- Update the bar
                  UBF:Update()
                else
                  UBF:SetAttr('bg', 'backdrop')
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
                         return not GetTable(BarType, 'Background', TableName).BackdropSettings.BgTile
                       end,
            min = UnitBarBgTileSizeMin,
            max = UnitBarBgTileSizeMax,
            step = 1,
          },
          Spacer20 = CreateSpacer(20),
          BdSize = {
            type = 'range',
            name = 'Border Thickness',
            order = 21,
            min = UnitBarBorderSizeMin,
            max = UnitBarBorderSizeMax,
            step = 2,
          },
        },
      },
    },
  }

  -- add background color option if its not a combo bar.
  if BarType ~= 'ComboBar' then
    BackgroundOptions.args.General.args.BgColor = {
      type = 'color',
      name = 'Background Color',
      order = 22,
      hidden = function()
                 return ( BarType == 'HolyBar' or BarType == 'ShardBar' ) and
                        UBF.UnitBar.General.BoxMode
               end,
      hasAlpha = true,
      get = function()
              local c = GetTable(BarType, 'Background', TableName).Color
              return c.r, c.g, c.b, c.a
            end,
      set = function(Info, r, g, b, a)
              local c = GetTable(BarType, 'Background', TableName).Color
              c.r, c.g, c.b, c.a = r, g, b, a
              if Object then
                UBF:SetAttr('bg', 'color', Object)
              else
                UBF:SetAttr('bg', 'color')
              end
           end,
    }
  end

  -- Add color all options.
  if BarType == 'RuneBar' or BarType == 'ComboBar' or BarType == 'HolyBar' or BarType == 'ShardBar' then
    local MaxColors = 5
    if BarType == 'HolyBar' or BarType == 'ShardBar' then
      MaxColors = 3
    elseif BarType == 'RuneBar' then
      MaxColors = 8
    end
    BackgroundOptions.args.BgColors = CreateColorAllOptions(BarType, 'bg', MaxColors, 2, 'Colors')
  end

  BackgroundOptions.args.Padding = {
    type = 'group',
    name = 'Padding',
    dialogInline = true,
    order = 3,
    get = function(Info)
            local Padding = GetTable(BarType, 'Background', TableName).BackdropSettings.Padding
            if Info[#Info] == 'All' then
              return Padding.Left
            else
              return Padding[Info[#Info]]
            end
          end,
    set = function(Info, Value)
            local Padding = GetTable(BarType, 'Background', TableName).BackdropSettings.Padding
            if Info[#Info] == 'All' then
              Padding.Left = Value
              Padding.Right = Value
              Padding.Top = Value
              Padding.Bottom = Value
            else
              Padding[Info[#Info]] = Value
            end
            if Object then
              UBF:SetAttr('bg', 'backdrop', Object)
            else
              UBF:SetAttr('bg', 'backdrop')
            end
          end,
    args = {
      PaddingAll = {
        type = 'toggle',
        name = 'All',
        order = 1,
        get = function()
                return GetTable(BarType, 'Background', TableName).PaddingAll
              end,
        set = function(Info, Value)
                GetTable(BarType, 'Background', TableName).PaddingAll = Value
              end,
        desc = 'Change padding with one value'
      },
      Spacer = CreateSpacer(2),
      All = {
        type = 'range',
        name = 'Offset',
        order = 3,
        hidden = function()
                   return not GetTable(BarType, 'Background', TableName).PaddingAll
                 end,
        min = UnitBarPaddingMin,
        max = UnitBarPaddingMax,
        step = 1,
      },
      Left = {
        type = 'range',
        name = 'Left',
        order = 4,
        hidden = function()
                   return GetTable(BarType, 'Background', TableName).PaddingAll
                 end,
        min = UnitBarPaddingMin,
        max = UnitBarPaddingMax,
        step = 1,
      },
      Right = {
        type = 'range',
        name = 'Right',
        order = 5,
        hidden = function()
                   return GetTable(BarType, 'Background', TableName).PaddingAll
                 end,
        min = UnitBarPaddingMin,
        max = UnitBarPaddingMax,
        step = 1,
      },
      Top = {
        type = 'range',
        name = 'Top',
        order = 6,
        hidden = function()
                   return GetTable(BarType, 'Background', TableName).PaddingAll
                 end,
        min = UnitBarPaddingMin,
        max = UnitBarPaddingMax,
        step = 1,
      },
      Bottom = {
        type = 'range',
        name = 'Bottom',
        order = 7,
        hidden = function()
                   return GetTable(BarType, 'Background', TableName).PaddingAll
                 end,
        min = UnitBarPaddingMin,
        max = UnitBarPaddingMax,
        step = 1,
      },
    },
  }

  return BackgroundOptions
end

-------------------------------------------------------------------------------
-- CreateTextOptions
--
-- Creates text options for a unitbar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: TextOptions CreateTextOptions(BarType, Object, Order, Name)
--
-- BarType               Type options being created.
-- Order                 Order number.
-- Object                Can be 'text' or 'text2'
-- Name                  Name text
--
-- TextOptions     Options table for background options.
-------------------------------------------------------------------------------
local function CreateTextOptions(BarType, Object, Order, Name)
  local UBF = UnitBarsF[BarType]

  -- Set the object.
  local UnitBarTable = nil

  if Object == 'text' then
    UnitBarTable = 'Text'
  elseif Object == 'text2' then
    UnitBarTable = 'Text2'
  end

  local TextOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {},
  }

  -- Add text type if its not a runebar and eclipsebar.
  if BarType ~= 'RuneBar' and BarType ~= 'EclipseBar' then
    TextOptions.args.TextType = {
      type = 'group',
      name = 'Text Type',
      dialogInline = true,
      order = 1,
      get = function(Info)
              local UBT = UBF.UnitBar[UnitBarTable].TextType
              local St = Info[#Info]
              local Index = tonumber(strsub(St, -1))

              if Index then
                return UBT[strsub(St, 1, -2)][Index]
              else
                return UBT[St]
              end
            end,
      set = function(Info, Value)
              local UBT = UBF.UnitBar[UnitBarTable].TextType
              local St = Info[#Info]
              local Index = tonumber(strsub(St, -1))

              if Index then
                UBT[strsub(St, 1, -2)][Index] = Value
              else
                UBT[St] = Value
              end

              -- Create the layout.
              if not UBT.Custom then
                local MaxValues = UBT.MaxValues
                local ValueType = UBT.ValueType
                local ValueName = UBT.ValueName

                local n = 0
                local SepFlag = false
                local LastName = nil
                local CurName = nil
                local Sep = '  '
                local TTL = nil

                UBT.Layout = ''
                for i, v in ipairs(ValueType) do
                  if i <= MaxValues then
                    if n > 0 then
                      Sep = '  '
                    else
                      Sep = ''
                    end
                    if v ~= 'none' then
                      CurName = ValueName[i]
                      if LastName and not SepFlag then
                        if LastName == 'current' and CurName == 'maximum' or
                           LastName == 'maximum' and CurName == 'current' then
                          Sep = ' / '
                          SepFlag = true
                        end
                      end
                      LastName = CurName
                      local TTL = TextTypeLayout[v]
                      if TTL then
                        UBT.Layout = strconcat(UBT.Layout, Sep, TTL)
                        n = n + 1
                      end
                    end
                  end
                end
              end

              -- Update the bar.
              UBF:Update()
            end,
      args = {
        MaxValues = {
          type = 'select',
          order = 1,
          name = 'Max Values',
          values = MaxValuesDropdown,
          style = 'dropdown',
          desc = 'Sets how many values to be shown',
        },
        Spacer = CreateSpacer(2),
        ValueName1 = {
          type = 'select',
          order = 3,
          name = 'Value Name 1',
          hidden = function()
                     return UBF.UnitBar[UnitBarTable].TextType.MaxValues < 1
                   end,
          values = ValueNameDropdownPredicted,
          style = 'dropdown',
          desc = 'Pick the name of the value to show',
        },
        ValueType1 = {
          type = 'select',
          name = '',
          order = 4,
          name = 'Value Type 1',
          values = ValueTypeDropdown,
          hidden = function()
                     return UBF.UnitBar[UnitBarTable].TextType.MaxValues < 1
                   end,
          style = 'dropdown',
          desc = 'Changes how the value is shown',
        },
        Spacer2 = CreateSpacer(5),
        ValueName2 = {
          type = 'select',
          order = 6,
          name = 'Value Name 2',
          hidden = function()
                     return UBF.UnitBar[UnitBarTable].TextType.MaxValues < 2
                   end,
          values = ValueNameDropdownPredicted,
          style = 'dropdown',
          desc = 'Pick the name of the value to show',
        },
        ValueType2 = {
          type = 'select',
          name = '',
          order = 7,
          name = 'Value Type 2',
          values = ValueTypeDropdown,
          hidden = function()
                     return UBF.UnitBar[UnitBarTable].TextType.MaxValues < 2
                   end,
          style = 'dropdown',
          desc = 'Changes how the value is shown',
        },
        Spacer3 = CreateSpacer(8),
        ValueName3 = {
          type = 'select',
          order = 9,
          name = 'Value Name 3',
          hidden = function()
                     return UBF.UnitBar[UnitBarTable].TextType.MaxValues < 3
                   end,
          values = ValueNameDropdownPredicted,
          style = 'dropdown',
          desc = 'Pick the name of the value to show',
        },
        ValueType3 = {
          type = 'select',
          name = '',
          order = 10,
          name = 'Value Type 3',
          values = ValueTypeDropdown,
          hidden = function()
                     return UBF.UnitBar[UnitBarTable].TextType.MaxValues < 3
                   end,
          style = 'dropdown',
          desc = 'Changes how the value is shown',
        },
        Spacer4 = CreateSpacer(100),
        Custom = {
          type = 'toggle',
          name = 'Custom Layout',
          order = 101,
          desc = 'If checked, the layout can be changed',
        },
        Layout = {
          type = 'description',
          order = 102,
          name = function()
                   return strconcat('|cFFFFFF00 Layout:|r ', UBF.UnitBar[UnitBarTable].TextType.Layout)
                 end,
          fontSize = 'large',
        },
        CustomLayout = {
          type = 'input',
          name = 'Custom Layout',
          order = 103,
          multiline = false,
          hidden = function()
                     return not UBF.UnitBar[UnitBarTable].TextType.Custom
                   end,
          get = function()
                  return UBF.UnitBar[UnitBarTable].TextType.Layout
                end,
          set = function(Info, Value)
                  UBF.UnitBar[UnitBarTable].TextType.Layout = Value

                  -- Update the bar.
                  UBF:Update()
                end,
        },
      },
    }
  end

  TextOptions.args.Font = {
    type = 'group',
    name = 'Font',
    dialogInline = true,
    order = 2,
    get = function(Info)
            return UBF.UnitBar[UnitBarTable].FontSettings[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar[UnitBarTable].FontSettings[Info[#Info]] = Value
            UBF:SetAttr(Object, 'font')
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
      FontHAlign = {
        type = 'select',
        name = 'Horizontal Alignment',
        order = 3,
        style = 'dropdown',
        values = FontHAlignDropdown,
      },
      FontSize = {
        type = 'range',
        name = 'Size',
        order = 4,
        min = UnitBarFontSizeMin,
        max = UnitBarFontSizeMax,
        step = 1,
      },
      Width = {
        type = 'range',
        name = 'Field Width',
        order = 5,
        min = UnitBarFontFieldWidthMin,
        max = UnitBarFontFieldWidthMax,
        step = 1,
      },
      Position = {
        type = 'select',
        name = 'Position',
        order = 6,
        style = 'dropdown',
        values = PositionDropdown,
      },
    },
  }

  -- Add color all text option for the runebar only.
  if BarType == 'RuneBar' then
    TextOptions.args.TextColors = CreateColorAllOptions(BarType, 'text', 8, 2, 'Colors')
  else
    TextOptions.args.Font.args.TextColor = {
      type = 'color',
      name = 'Color',
      order = 7,
      hasAlpha = true,
      get = function()
              local c = UBF.UnitBar[UnitBarTable].Color
              return c.r, c.g, c.b, c.a
            end,
      set = function(Info, r, g, b, a)
              local c = UBF.UnitBar[UnitBarTable].Color
              c.r, c.g, c.b, c.a = r, g, b, a
              UBF:SetAttr(Object, 'color')
            end,
    }
  end

  TextOptions.args.Offsets = {
    type = 'group',
    name = 'Offsets',
    dialogInline = true,
    order = 3,
    get = function(Info)
            return UBF.UnitBar[UnitBarTable].FontSettings[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar[UnitBarTable].FontSettings[Info[#Info]] = Value
            UBF:SetAttr(Object, 'font')
          end,
    args = {
      OffsetX = {
        type = 'range',
        name = 'Horizonal',
        order = 2,
        min = FontOffsetXMin,
        max = FontOffsetXMax,
        step = 1,
      },
      OffsetY = {
        type = 'range',
        name = 'Vertical',
        order = 3,
        min = FontOffsetYMin,
        max = FontOffsetYMax,
        step = 1,
      },
      ShadowOffset = {
        type = 'range',
        name = 'Shadow',
        order = 4,
        min = FontShadowOffsetMin,
        max = FontShadowOffsetMax,
        step = 1,
      },
    },
  }

  return TextOptions
end

-------------------------------------------------------------------------------
-- CreatePowerColorsOptions
--
-- Creates power color options for a UnitBar.
--
-- Subfunction of CreateBarOptions()
--
-- Usage: PowerColorsOptions = CreatePowerColorsOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
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
            local c = UBF.UnitBar.Bar.Color[Info.arg]
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local c = UBF.UnitBar.Bar.Color[Info.arg]
            c.r, c.g, c.b, c.a = r, g, b, a

             -- Update the bar to show the current power color change in real time.
            UBF:Update()
          end,
    args = {},
  }

  local AllColor = true
  local PCOA = PowerColorsOptions.args
  if BarType == 'PlayerPower' or BarType == 'MainPower' then
    AllColor = false
  end

  for PowerTypeSt, PowerType in pairs(PowerColorType) do
    local n = gsub(strlower(PowerTypeSt), '%a', strupper, 1)

    local Width = 'half'
    if PowerTypeSt == 'RUNIC_POWER' then
      n = 'Runic Power'
      Width = 'normal'
    end

    if AllColor or PowerTypeSt == PlayerPowerType or
       PlayerClass == 'DRUID' and BarType ~= 'MainPower' and (PowerTypeSt == 'RAGE' or PowerTypeSt == 'ENERGY') then
      PCOA['Color' .. PowerType] = {
        type = 'color',
        name = n,
        order = PowerType,
        width = Width,
        hasAlpha = true,
        arg = PowerType,
      }
    end
  end

  return PowerColorsOptions
end

-------------------------------------------------------------------------------
-- CreateClassColorsOptions
--
-- Creates class color options for a UnitBar.
--
-- Subfunction of CreateBarOptions()
--
-- Usage: ClassColorsOptions = CreateClassColorsOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- PowerColorsOptions    Options table for class colors.
-------------------------------------------------------------------------------
local function CreateClassColorsOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
  local ClassColorsMenu = {
    [1] = 'DEATHKNIGHT', [2] = 'DRUID',  [3] = 'HUNTER', [4] = 'MAGE',     [5] = 'PALADIN', [6] = 'PRIEST',
    [7] = 'PRIEST',      [8] = 'ROGUE',  [9] = 'SHAMAN', [10] = 'WARLOCK', [11] = 'WARRIOR'
  }

  local ClassColorsOptions = {
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
            UBF:Update()
          end,
    args = {
      ClassColorToggle = {
        type = 'toggle',
        name = 'Class Colors',
        order = 1,
        desc = 'If checked, class colors will be used',
        get = function()
                return UBF.UnitBar.Bar.ClassColor
              end,
        set = function(Info, Value)
                UBF.UnitBar.Bar.ClassColor = Value

                -- Refresh color when changing between class colors and normal.
                UBF:Update()
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
                   return UBF.UnitBar.Bar.ClassColor
                 end,
        arg = 0,
      },
    },
  }

  local CCOA = ClassColorsOptions.args
  for Index, ClassName in ipairs(ClassColorsMenu) do
    local n = gsub(strlower(ClassName), '%a', strupper, 1)
    local Width = 'half'
    if Index == 1 then
      n = 'Death Knight'
      Width = 'normal'
    end

    -- Add class color option that will be used.
    if BarType ~= 'PlayerHealth' or PlayerClass == ClassName then
      CCOA[ClassName] = {
        type = 'color',
        name = n,
        order = 3 + Index,
        width = Width,
        hasAlpha = true,
        hidden = function()
                   return not UBF.UnitBar.Bar.ClassColor
                 end,
      }
    end
  end

  return ClassColorsOptions
end

-------------------------------------------------------------------------------
-- CreatePredictedColorOptions
--
-- Creates color options for bars that uses predicted health
--
-- Subfunction of CreateBarOptions()
--
-- Usage: PredictedColorOptions = CreatePredictedColorOptions(BarType, Order, Name)
--
-- BarType                 Type of options being created.
-- Order                   Order number.
-- Name                    Name Text.
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
            UBF:Update()
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
-- CreateBarSizeOptions
--
-- Subfunction of CreateBarOptions()
--
-- Allows the user to change size of bars then offset them for finer sizing.
--
-- Usage: Table = CreateBarSizeOptions(BarType, TableName, Order, BarWidthKey, BarHeightKey)
--
-- BarType               Type of options being created.
-- TableName             If not nil then it access options data in UnitBars[BarType].Bar[TableName]
--                       Object must be lowercase.
-- BarWidthKey           Key name for the width slider.
-- BarHeightKey          Key name for the height slider.
--
-- Table                 Options table returned
-------------------------------------------------------------------------------
local function CreateBarSizeOptions(BarType, TableName, Order, BarWidthKey, BarHeightKey)
  local UBF = UnitBarsF[BarType]
  local Width = 0
  local Height = 0

  local BarSizeOptions = {}
  local FunctionLabel = format('%s%s', BarType, TableName or '')
  local ABarWidthKey = format('%s%s', 'Advanced', BarWidthKey)
  local ABarHeightKey = format('%s%s', 'Advanced', BarHeightKey)

  SetFunction(FunctionLabel, function()
    local t = GetTable(BarType, 'Bar', TableName)
    BarSizeOptions.args[ABarWidthKey].min = t[BarWidthKey] - UnitBarOffset
    BarSizeOptions.args[ABarWidthKey].max = t[BarWidthKey] + UnitBarOffset
    BarSizeOptions.args[ABarHeightKey].min = t[BarHeightKey] - UnitBarOffset
    BarSizeOptions.args[ABarHeightKey].max = t[BarHeightKey] + UnitBarOffset
  end)

  BarSizeOptions = {
    type = 'group',
    name = 'Bar size',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return GetTable(BarType, 'Bar', TableName)[gsub(Info[#Info], 'Advanced', '')]
          end,
    set = function(Info, Value)
            local Key = Info[#Info]

            -- Check for out of range.
            if Key == ABarWidthKey or Key == ABarHeightKey then
              Key = gsub(Key, 'Advanced', '')
              if strfind(Key, 'Width') then
                Value = min(max(Value + Width, UnitBarWidthMin), UnitBarWidthMax)
              else
                Value = min(max(Value + Height, UnitBarHeightMin), UnitBarHeightMax)
              end
            end

            GetTable(BarType, 'Bar', TableName)[Key] = Value

            -- Call the function that was saved from the above SetFunction call.
            SetFunction(FunctionLabel)

            -- Update combobar, holybar, or shardbar layout.
            if BarType == 'RuneBar' or BarType == 'ComboBar' or BarType == 'HolyBar' or BarType == 'ShardBar' or BarType == 'DemonicBar' then
              UBF:SetLayout()
            else
              if TableName then
                UBF:SetLayout()

                -- This section for eclipse bar mostly.
                -- Update the bar to recalculate the slider pos.
                UBF:Update()
              else

                -- This part usually used for health and power bars
                UBF:SetAttr('bar', 'size')
              end
            end
          end,
    args = {
      Advanced = {
        type = 'toggle',
        name = 'Advanced',
        desc = 'If checked, allows you to make fine tune adjustments easier',
        order = 1,
        get = function()
                return GetTable(BarType, 'Bar', TableName).Advanced
              end,
        set = function(Info, Value)
                GetTable(BarType, 'Bar', TableName).Advanced = Value
              end,
      },
      [BarWidthKey] = {
        type = 'range',
        name = 'Width',
        order = 1,
        desc = 'Slide or click anywhere on the slider to change the width',
        width = 'full',
        hidden = function()
                   return GetTable(BarType, 'Bar', TableName).Advanced
                 end,
        min = UnitBarWidthMin,
        max = UnitBarWidthMax,
        step = 1,
      },
      [BarHeightKey] = {
        type = 'range',
        name = 'Height',
        order = 2,
        desc = 'Slide or click anywhere on the slider to change the height',
        width = 'full',
        hidden = function()
                   return GetTable(BarType, 'Bar', TableName).Advanced
                 end,
        min = UnitBarHeightMin,
        max = UnitBarHeightMax,
        step = 1,
      },
      [ABarWidthKey] = {
        type = 'range',
        name = 'Advanced Width',
        order = 1,
        desc = 'Slide or click anywhere on the slider to change the width',
        width = 'full',
        hidden = function()
                   return not GetTable(BarType, 'Bar', TableName).Advanced
                 end,
        min = GetTable(BarType, 'Bar', TableName)[BarWidthKey] - UnitBarOffset,
        max = GetTable(BarType, 'Bar', TableName)[BarWidthKey] + UnitBarOffset,
        step = 1,
      },
      [ABarHeightKey] = {
        type = 'range',
        name = 'Advanced Height',
        order = 2,
        desc = 'Slide or click anywhere on the slider to change the height',
        width = 'full',
        hidden = function()
                   return not GetTable(BarType, 'Bar', TableName).Advanced
                 end,
        min = GetTable(BarType, 'Bar', TableName)[BarHeightKey] - UnitBarOffset,
        max = GetTable(BarType, 'Bar', TableName)[BarHeightKey] + UnitBarOffset,
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
-- Usage: BarOptions = CreateBarOptions(BarType, Object, Order, Name)
--
-- BarType               Type of options being created.
-- Object                If not nil then it access options data in UnitBars[BarType].Bar[Object]
--                       Object must be lowercase
-- Order                 Order number.
-- Name                  Name text.
--
-- BarOptions            Options table for the unitbar.
-------------------------------------------------------------------------------
local function CreateBarOptions(BarType, Object, Order, Name)
  local UBF = UnitBarsF[BarType]
  local TableName = nil
  if Object then
    TableName = gsub(Object, '%a', strupper, 1)
  end

  local BarOptions = {
    type = 'group',
    name = Name,
    order = Order,
    hidden = function()
               return BarType == 'RuneBar' and UBF.UnitBar.General.RuneMode == 'rune' or
                      ( BarType == 'HolyBar' or BarType == 'ShardBar' or BarType == 'DemonicBar') and
                      not UBF.UnitBar.General.BoxMode
             end,
    args = {
      General = {
        type = 'group',
        name = 'General',
        dialogInline = true,
        order = 1,
        get = function(Info)
                return GetTable(BarType, 'Bar', TableName)[Info[#Info]]
              end,
        set = function(Info, Value)
                GetTable(BarType, 'Bar', TableName)[Info[#Info]] = Value

                -- Update combobar, holybar, or shardbar layout.
                if BarType == 'RuneBar' or BarType == 'ComboBar' or BarType == 'HolyBar' or BarType == 'ShardBar' then
                  UBF:SetLayout()
                else
                  if Object then
                    UBF:SetLayout()

                    -- This section mostly for eclipse bar.
                    -- Update the bar to recalculate the slider pos.
                    UBF:Update()
                  else

                    -- This section usually for health and power bars.
                    UBF:SetAttr('bar', Info.arg)
                  end
                end
              end,
        args = {},
      },
    },
  }
  local GA = BarOptions.args.General.args

  if BarType ~= 'EclipseBar' or BarType == 'EclipseBar' and Object ~= 'bar' then

    GA.StatusBarTexture = {
      type = 'select',
      name = 'Bar Texture',
      order = 1,
      dialogControl = 'LSM30_Statusbar',
      values = LSM:HashTable('statusbar'),
      arg = 'texture',
    }
    if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or
       BarType == 'FocusHealth' or
       BarType == 'PlayerPower' and PlayerClass == 'HUNTER' then

      GA.PredictedBarTexture = {
        type = 'select',
        name = 'Predicted Bar Texture',
        order = 2,
        dialogControl = 'LSM30_Statusbar',
        values = LSM:HashTable('statusbar'),
        arg = 'texture',
      }
    end
  end
  if BarType == 'EclipseBar' and Object == 'bar' then

    GA.StatusBarTextureLunar = {
      type = 'select',
      name = 'Bar Texture (lunar)',
      order = 1,
      dialogControl = 'LSM30_Statusbar',
      values = LSM:HashTable('statusbar'),
      arg = 'texture',
    }
    GA.StatusBarTextureSolar = {
      type = 'select',
      name = 'Bar Texture (solar)',
      order = 2,
      dialogControl = 'LSM30_Statusbar',
      values = LSM:HashTable('statusbar'),
      arg = 'texture',
    }
  end
  GA.Spacer10 = CreateSpacer(10)

  if BarType ~= 'ComboBar' and BarType ~= 'HolyBar' and
     BarType ~= 'ShardBar' and BarType ~= 'EclipseBar' then

    GA.FillDirection = {
      type = 'select',
      name = 'Fill Direction',
      order = 11,
      values = DirectionDropdown,
      style = 'dropdown',
      arg = 'texture',
    }
  end
  GA.RotateTexture = {
    type = 'toggle',
    name = 'Rotate Texture',
    order = 12,
    arg = 'texture',
  }
  GA.Spacer20 = CreateSpacer(20)

  if BarType == 'RuneBar' then
    GA.BoxSize = CreateBarSizeOptions(BarType, TableName, 100, 'RuneWidth', 'RuneHeight')
  elseif BarType == 'ComboBar' or BarType == 'HolyBar' or BarType == 'ShardBar' or BarType == 'DemonicBar' then
    GA.BoxSize = CreateBarSizeOptions(BarType, TableName, 100, 'BoxWidth', 'BoxHeight')
  elseif BarType == 'EclipseBar' then
    local o = gsub(Object, '%a', strupper, 1)
    GA.BarSize = CreateBarSizeOptions(BarType, TableName, 100, o .. 'Width', o .. 'Height')
    GA.Spacer30 = CreateSpacer(30)

    if Object == 'bar' then
      GA.BarColorLunar = {
        type = 'color',
        name = 'Color (lunar)',
        order = 31,
        hasAlpha = true,
        get = function()
                local c = UBF.UnitBar.Bar.Bar.ColorLunar
                return c.r, c.g, c.b, c.a
              end,
        set = function(Info, r, g, b, a)
                local c = UBF.UnitBar.Bar.Bar.ColorLunar
                c.r, c.g, c.b, c.a = r, g, b, a
                UBF:SetAttr('bar', 'color', 'bar')
              end,
        }
      GA.BarColorSolar = {
        type = 'color',
        name = 'Color (solar)',
        order = 32,
        hasAlpha = true,
        get = function()
                local c = UBF.UnitBar.Bar.Bar.ColorSolar
                return c.r, c.g, c.b, c.a
              end,
        set = function(Info, r, g, b, a)
                local c = UBF.UnitBar.Bar.Bar.ColorSolar
                c.r, c.g, c.b, c.a = r, g, b, a
                UBF:SetAttr('bar', 'color', 'bar')
              end,
      }
    end
  else
    GA.BarSize = CreateBarSizeOptions(BarType, TableName, 100, 'HapWidth', 'HapHeight')
  end
  if BarType == 'PetHealth' or BarType == 'EclipseBar' and ( Object == 'moon' or Object == 'sun' ) then
    GA.Spacer40 = CreateSpacer(40)
    GA.BarColor = {
      type = 'color',
      name = 'Color',
      order = 41,
      hasAlpha = true,
      get = function()
              local c = GetTable(BarType, 'Bar', TableName).Color
              return c.r, c.g, c.b, c.a
            end,
      set = function(Info, r, g, b, a)
              local c = GetTable(BarType, 'Bar', TableName).Color
              c.r, c.g, c.b, c.a = r, g, b, a
              if Object then
                UBF:SetAttr('bar', 'color', Object)
              else
                UBF:SetAttr('bar', 'color')
              end

              -- Update the bar for shared colors.
              UBF:Update()
            end,
    }
  end

  -- Add class colors for Player, Target, and Focus health bars only.
  if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' then

    -- Add the class color options.
    BarOptions.args.ClassColors = CreateClassColorsOptions(BarType, 2, 'Color')
  end

  -- Add power colors for power bars only.
  if BarType:find('Power') then

    -- Add the Power color options.
    BarOptions.args.PowerColors = CreatePowerColorsOptions(BarType, 2, 'Power Color')
  end

  -- Add bar color options if its a combobar or shardbar.
  if BarType == 'RuneBar' or BarType == 'ComboBar' or BarType == 'HolyBar' or BarType == 'ShardBar' then
    local MaxColors = 5
    if BarType == 'HolyBar' or BarType == 'ShardBar' then
      MaxColors = 3
    elseif BarType == 'RuneBar' then
      MaxColors = 8
    end
    BarOptions.args.BarColors = CreateColorAllOptions(BarType, 'bar', MaxColors, 2, 'Colors')
  end

  -- Add color options for demonicbar
  if BarType == 'DemonicBar' then
    BarOptions.args.DemonicBarColor = {
      type = 'group',
      name = 'Color',
      dialogInline = true,
      order = 2,
      get = function(Info)
              local c = UBF.UnitBar.Bar[Info[#Info]]
              return c.r, c.g, c.b, c.a
            end,
      set = function(Info, r, g, b, a)
              local c = UBF.UnitBar.Bar[Info[#Info]]
              c.r, c.g, c.b, c.a = r, g, b, a
              UBF:SetAttr('bar', 'color')
            end,
      args = {
        Color = {
          type = 'color',
          name = 'Normal',
          order = 1,
          hasAlpha = true,
        },
        ColorMeta = {
          type = 'color',
          name = 'Metamorphosis',
          order = 2,
          hasAlpha = true,
        },
      },
    }
  end

  -- Add slider and indicator for eclipsebar
  if BarType == 'EclipseBar' then

    -- Add color options for the slider bar
    if Object == 'slider' then
      BarOptions.args.SliderColor = CreateEclipseColorOptions(BarType, 'bar', 'slider', 2, 'Color')
    end
    if Object == 'indicator' then
      BarOptions.args.IndicatorColor = CreateEclipseColorOptions(BarType, 'bar', 'indicator', 2, 'Color')
    end
  end

  -- Add predicted color for Health bars only or for Player Power for hunters.
  if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' or
     BarType == 'PlayerPower' and PlayerClass == 'HUNTER' then
    BarOptions.args.PredictedColors = CreatePredictedColorOptions(BarType, 3, 'Predicted Color')
  end

  BarOptions.args.Padding = {
    type = 'group',
    name = 'Padding',
    dialogInline = true,
    order = 4,
    get = function(Info)
            local Padding = GetTable(BarType, 'Bar', TableName).Padding
            if Info[#Info] == 'All' then
              return Padding.Left
            else
              return Padding[Info[#Info]]
            end
          end,
    set = function(Info, Value)
            local Padding = GetTable(BarType, 'Bar', TableName).Padding
            if Info[#Info] == 'All' then
              Padding.Left = Value
              Padding.Right = -Value
              Padding.Top = -Value
              Padding.Bottom = Value
            else
              Padding[Info[#Info]] = Value
            end

            if Object then
              UBF:SetAttr('bar', 'padding', Object)
            else
              UBF:SetAttr('bar', 'padding')
            end
          end,
    args = {
      PaddingAll = {
        type = 'toggle',
        name = 'All',
        order = 1,
        get = function()
                return GetTable(BarType, 'Bar', TableName).PaddingAll
              end,
        set = function(Info, Value)
                GetTable(BarType, 'Bar', TableName).PaddingAll = Value
              end,
        desc = 'Change padding with one value'
      },
      Spacer = CreateSpacer(2),
      All = {
        type = 'range',
        name = 'Offset',
        order = 3,
        hidden = function()
                   return not GetTable(BarType, 'Bar', TableName).PaddingAll
                 end,
        min = UnitBarPaddingMin,
        max = UnitBarPaddingMax,
        step = 1,
      },
      Left = {
        type = 'range',
        name = 'Left',
        order = 4,
        hidden = function()
                   return GetTable(BarType, 'Bar', TableName).PaddingAll
                 end,
        min = UnitBarPaddingMin,
        max = UnitBarPaddingMax,
        step = 1,
      },
      Right = {
        type = 'range',
        name = 'Right',
        order = 5,
        hidden = function()
                   return GetTable(BarType, 'Bar', TableName).PaddingAll
                 end,
        min = UnitBarPaddingMin,
        max = UnitBarPaddingMax,
        step = 1,
      },
      Top = {
        type = 'range',
        name = 'Top',
        order = 6,
        hidden = function()
                   return GetTable(BarType, 'Bar', TableName).PaddingAll
                 end,
        min = UnitBarPaddingMin,
        max = UnitBarPaddingMax,
        step = 1,
      },
      Bottom = {
        type = 'range',
        name = 'Bottom',
        order = 7,
        hidden = function()
                   return GetTable(BarType, 'Bar', TableName).PaddingAll
                 end,
        min = UnitBarPaddingMin,
        max = UnitBarPaddingMax,
        step = 1,
      },
    },
  }

  return BarOptions
end

-------------------------------------------------------------------------------
-- CreateHapBarOptions
--
-- Creates health and power bar options
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: HapBarOptions = CreateHapBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- HapBarOptions         Options table for the health and power bar.
-------------------------------------------------------------------------------
local function CreateHapBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local HapBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.General[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.General[Info[#Info]] = Value

            -- Update the bar to show changes.
            UBF:Update()
          end,
    args = {},
  }
  if strfind(BarType, 'Health') then
    HapBarOptions.args.PredictedHealth = {
      type = 'toggle',
      name = 'Predicted Health',
      order = 1,
      desc = 'If checked, predicted health will be shown',
    }
  else
    HapBarOptions.args.PredictedPower = {
      type = 'toggle',
      name = 'Predicted Power',
      order = 1,
      desc = 'If checked, predicted power will be shown',
    }
  end

  return HapBarOptions
end

-------------------------------------------------------------------------------
-- CreateRuneBarOptions
--
-- Creates options for a Rune Bar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: RuneBarOptions = CreateRuneBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- RuneBarOptions        Options table for the rune bar.
-------------------------------------------------------------------------------
local function CreateRuneBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local RuneBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.General[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UBF:SetLayout()
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
      Spacer10 = CreateSpacer(10),
      BarMode = {
        type = 'toggle',
        name = 'Bar Mode',
        order = 11,
        desc = "If checked, the runes can't be moved anywhere on the screen",
      },
      RuneSwap = {
        type = 'toggle',
        name = 'Swap Runes',
        order = 12,
        desc = 'Runes can be swapped by dragging a rune on another rune',
      },
      CooldownText = {
        type = 'toggle',
        name = 'Cooldown Text',
        order = 13,
        desc = 'Show cooldown text',
      },
      CooldownAnimation = {
        type = 'toggle',
        name = 'Cooldown Animation',
        order = 14,
        hidden = function()
                   return BarType == 'RuneBar' and strsub(UBF.UnitBar.General.RuneMode, 1, 4) ~= 'rune'
                 end,
        desc = 'Shows the cooldown animation',
      },
      HideCooldownFlash = {
        type = 'toggle',
        name = 'Hide Flash',
        order = 15,
        hidden = function()
                   return BarType == 'RuneBar' and strsub(UBF.UnitBar.General.RuneMode, 1, 4) ~= 'rune'
                 end,
        disabled = function()
                     return not UBF.UnitBar.General.CooldownAnimation
                   end,
        desc = 'Hides the flash animation after a rune comes off cooldown',
      },
      CooldownDrawEdge = {
        type = 'toggle',
        name = 'Draw Edge',
        order = 16,
        hidden = function()
                   return BarType == 'RuneBar' and strsub(UBF.UnitBar.General.RuneMode, 1, 4) ~= 'rune'
                 end,
        disabled = function()
                     return not UBF.UnitBar.General.CooldownAnimation
                   end,
        desc = 'Shows a line on the cooldown animation',
      },
      CooldownBarDrawEdge = {
        type = 'toggle',
        name = 'Bar Draw Edge',
        order = 17,
        hidden = function()
                   return BarType == 'RuneBar' and UBF.UnitBar.General.RuneMode == 'rune'
                 end,
        desc = 'Shows a line on the cooldown bar animation',
      },
      Spacer20 = CreateSpacer(20),
      BarModeAngle = {
        type = 'range',
        name = 'Rune Rotation',
        order = 21,
        desc = 'Rotates the rune bar',
        disabled = function()
                     return not UnitBars.RuneBar.General.BarMode
                   end,
        min = RuneBarAngleMin,
        max = RuneBarAngleMax,
        step = 45,
      },
      RunePadding = {
        type = 'range',
        name = 'Rune Padding',
        order = 22,
        desc = 'Set the Amount of space between each rune',
        disabled = function()
                     return not UnitBars.RuneBar.General.BarMode
                   end,
        min = RuneBarPaddingMin,
        max = RuneBarPaddingMax,
        step = 1,
      },
      RuneSize = {
        type = 'range',
        name = 'Rune Size',
        order = 23,
        hidden = function()
                   return BarType == 'RuneBar' and strsub(UBF.UnitBar.General.RuneMode, 1, 4) ~= 'rune'
                 end,
        desc = 'Change the size of all the runes',
        min = RuneBarSizeMin,
        max = RuneBarSizeMax,
        step = 1,
      },
      Spacer30 = CreateSpacer(30),
      RuneLocation = {
        type = 'group',
        name = 'Rune Location',
        dialogInline = true,
        order = 31,
        hidden = function()
                   return UBF.UnitBar.General.RuneMode ~= 'runecooldownbar'
                 end,
        args = {
          RuneOffsetX = {
            type = 'range',
            name = 'Horizontal Offset',
            order = 1,
            min = RuneOffsetXMin,
            max = RuneOffsetYMax,
            step = 1,
          },
          RuneOffsetY = {
            type = 'range',
            name = 'Vertical Offset',
            order = 2,
            min = RuneOffsetYMin,
            max = RuneOffsetYMax,
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
        order = 32,
        hidden = function()
                   return UBF.UnitBar.General.EnergizeShow == 'none'
                 end,
        args = {
          EnergizeTime = {
            type = 'range',
            name = 'Time',
            order = 1,
            desc = 'Amount of time to wait before removing empowerment overlay',
            min = RuneEnergizeTimeMin,
            max = RuneEnergizeTimeMax,
            step = 1,
          },
          Color = CreateColorAllOptions(BarType, 'runebarenergize', 8, 2, 'Colors'),
        },
      },
    },
  }
  return RuneBarOptions
end

-------------------------------------------------------------------------------
-- CreateComboBarOptions
--
-- Creates options for a combo points bar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: ComboBarOptions = CreateComboBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- ComboBarOptions       Options table for the combo points bar.
-------------------------------------------------------------------------------
local function CreateComboBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local ComboBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.General[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UBF:SetLayout()
          end,
    args = {
      ComboPadding = {
        type = 'range',
        name = 'Combo Padding',
        order = 1,
        desc = 'Set the Amount of space between each combo point box',
        min = ComboBarPaddingMin,
        max = ComboBarPaddingMax,
        step = 1,
      },
      ComboAngle = {
        type = 'range',
        name = 'Combo Rotation',
        order = 2,
        desc = 'Rotates the combo bar',
        min = ComboBarAngleMin,
        max = ComboBarAngleMax,
        step = 45,
      },
      ComboFadeOutTime = {
        type = 'range',
        name = 'Combo Fadeout Time',
        order = 3,
        desc = 'The amount of time in seconds to fade out a combo point',
        min = ComboBarFadeOutMin,
        max = ComboBarFadeOutMax,
        step = 1,
      },
    },
  }
  return ComboBarOptions
end

-------------------------------------------------------------------------------
-- CreateHolyBarOptions
--
-- Creates options for a holy power bar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: HolyBarOptions = CreateHolyBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- HolyBarOptions       Options table for the holy bar.
-------------------------------------------------------------------------------
local function CreateHolyBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local HolyBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.General[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UBF:SetLayout()
          end,
    args = {
      BoxMode = {
        type = 'toggle',
        name = 'Box Mode',
        order = 1,
        desc = 'If checked, this bar will show boxes instead of textures',
      },
      HolyPadding = {
        type = 'range',
        name = 'Holy Padding',
        order = 2,
        desc = 'Set the Amount of space between each holy rune',
        min = HolyBarPaddingMin,
        max = HolyBarPaddingMax,
        step = 1,
      },
      HolyAngle = {
        type = 'range',
        name = 'Holy Rotation',
        order = 3,
        desc = 'Rotates the holy bar',
        min = HolyBarAngleMin,
        max = HolyBarAngleMax,
        step = 45,
      },
      HolySize = {
        type = 'range',
        name = 'Holy Size',
        order = 4,
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        desc = 'Sets the size of all the holy power runes',
        min = HolyBarSizeMin,
        max = HolyBarSizeMax,
        step = 0.01,
        isPercent = true
      },
      HolyScale = {
        type = 'range',
        name = 'Holy Scale',
        order = 5,
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        desc = 'Sets the scale of all the holy power runes',
        min = HolyBarScaleMin,
        max = HolyBarScaleMax,
        step = 0.01,
        isPercent = true,
      },
      HolyFadeOutTime = {
        type = 'range',
        name = 'Holy Fadeout Time',
        order = 6,
        desc = 'The amount of time in seconds to fade out a holy rune',
        min = HolyBarFadeOutMin,
        max = HolyBarFadeOutMax,
        step = 1,
      },
    },
  }
  return HolyBarOptions
end

-------------------------------------------------------------------------------
-- CreateShardBarOptions
--
-- Creates options for a soul shard bar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: ShardBarOptions = CreateShardBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- ShardBarOptions       Options table for the shard bar.
-------------------------------------------------------------------------------
local function CreateShardBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local ShardBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.General[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UBF:SetLayout()
          end,
    args = {
      BoxMode = {
        type = 'toggle',
        name = 'Box Mode',
        order = 1,
        desc = 'If checked, this bar will show boxes instead of textures',
      },
      ShardPadding = {
        type = 'range',
        name = 'Shard Padding',
        order = 2,
        desc = 'Set the Amount of space between each soul shard',
        min = ShardBarPaddingMin,
        max = ShardBarPaddingMax,
        step = 1,
      },
      ShardAngle = {
        type = 'range',
        name = 'Shard Rotation',
        order = 3,
        desc = 'Rotates the shard bar',
        min = ShardBarAngleMin,
        max = ShardBarAngleMax,
        step = 45,
      },
      ShardSize = {
        type = 'range',
        name = 'Shard Size',
        order = 4,
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        desc = 'Sets the size of all the soul shards',
        min = ShardBarSizeMin,
        max = ShardBarSizeMax,
        step = 0.01,
        isPercent = true
      },
      ShardScale = {
        type = 'range',
        name = 'Shard Scale',
        order = 5,
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        desc = 'Sets the scale of all the soul shards',
        min = ShardBarScaleMin,
        max = ShardBarScaleMax,
        step = 0.01,
        isPercent = true,
      },
      ShardFadeOutTime = {
        type = 'range',
        name = 'Shard Fadeout Time',
        order = 6,
        desc = 'The amount of time in seconds to fade out a soul shard',
        min = ShardBarFadeOutMin,
        max = ShardBarFadeOutMax,
        step = 1,
      },
    },
  }
  return ShardBarOptions
end

-------------------------------------------------------------------------------
-- CreateEclipseBarOptions
--
-- Creates options for a eclipse bar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: EclipseBarOptions = CreateEclipseBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- EclipseBarOptions     Options table for the eclipse bar.
-------------------------------------------------------------------------------
local function CreateEclipseBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local EclipseBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.General[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UBF:SetLayout()

            -- Update the bar
            UBF:Update()
          end,
    args = {
      SliderInside = {
        type = 'toggle',
        name = 'Slider Inside',
        order = 1,
        desc = 'If checked, the slider will stay inside the bar',
      },
      BarHalfLit = {
        type = 'toggle',
        name = 'Bar Half Lit',
        order = 2,
        desc = 'If checked, half the bar becomes lit to show the slider direction',
      },
      PowerText = {
        type = 'toggle',
        name = 'Power Text',
        order = 3,
        desc = 'If checked, then eclipse power text will be shown',
      },
      PredictedPower = {
        type = 'toggle',
        name = 'Predicted Power',
        order = 4,
        desc = 'If checked, the energy from wrath, starfire and starsurge will be shown ahead of time. Predicted options group will open up below when checked',
      },
      Spacer10 = CreateSpacer(10),
      SliderDirection = {
        type = 'select',
        name = 'Slider Direction',
        order = 12,
        values = DirectionDropdown,
        style = 'dropdown',
        desc = 'Specifies the direction the slider will move in'
      },
      EclipseAngle = {
        type = 'range',
        name = 'Eclipse Rotation',
        order = 13,
        desc = 'Rotates the eclipse bar',
        min = EclipseAngleMin,
        max = EclipseAngleMax,
        step = 90,
      },
      EclipseFadeOutTime = {
        type = 'range',
        name = 'Eclipse Fadeout Time',
        order = 14,
        desc = 'The amount of time in seconds to fade out sun and moon',
        min = EclipseBarFadeOutMin,
        max = EclipseBarFadeOutMax,
        step = 1,
      },
      Spacer20 = CreateSpacer(20),
      SunOffsetX = {
        type = 'range',
        name = 'Sun Horizontal Offset',
        order = 21,
        desc = 'Offsets the horizontal position of the sun',
        min = EclipseSunOffsetXMin,
        max = EclipseSunOffsetXMax,
        step = 1,
      },
      SunOffsetY = {
        type = 'range',
        name = 'Sun Vertical Offset',
        order = 22,
        desc = 'Offsets the horizontal position of the sun',
        min = EclipseSunOffsetYMin,
        max = EclipseSunOffsetYMax,
        step = 1,
      },
      Spacer30 = CreateSpacer(30),
      MoonOffsetX = {
        type = 'range',
        name = 'Moon Horizontal Offset',
        order = 31,
        desc = 'Offsets the horizontal position of the moon',
        min = EclipseMoonOffsetXMin,
        max = EclipseMoonOffsetXMax,
        step = 1,
      },
      MoonOffsetY = {
        type = 'range',
        name = 'Moon Vertical Offset',
        order = 32,
        desc = 'Offsets the horizontal position of the moon',
        min = EclipseMoonOffsetYMin,
        max = EclipseMoonOffsetYMax,
        step = 1,
      },
      PredictedOptions = {
        type = 'group',
        name = 'Predicted Options',
        dialogInline = true,
        order = 33,
        hidden = function()
                   return not UBF.UnitBar.General.PredictedPower
                 end,
        args = {
          IndicatorHideShow  = {
            type = 'select',
            name = 'Indicator (predicted power)',
            order = 1,
            desc = 'Hide or Show the indicator',
            values = IndicatorDropdown,
            style = 'dropdown',
          },
          Spacer10 = CreateSpacer(10),
          PredictedBarHalfLit = {
            type = 'toggle',
            name = 'Bar Half Lit',
            order = 11,
            desc = 'If checked, bar half lit is based on predicted power',
          },
          PredictedPowerText = {
            type = 'toggle',
            name = 'Power Text',
            order = 12,
            desc = 'If checked, predicted power text will be shown instead',
          },
          PredictedHideSlider = {
            type = 'toggle',
            name = 'Hide Slider',
            order = 13,
            desc = 'If checked, the slider will be hidden',
          },
          PredictedEclipse = {
            type = 'toggle',
            name = 'Eclipse',
            order = 14,
            desc = 'If checked, the sun or moon will light up based on predicted power',
          },
        },
      },
    },
  }
  return EclipseBarOptions
end

-------------------------------------------------------------------------------
-- CreateDemonicBarOptions
--
-- Creates options for a demonic bar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: DemonicBarOptions = CreateDemonicBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- DemonicBarOptions     Options table for the eclipse bar.
-------------------------------------------------------------------------------
local function CreateDemonicBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local DemonicBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.General[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UBF:SetLayout()

            -- Update the bar
            UBF:Update()
          end,
    args = {
      BoxMode = {
        type = 'toggle',
        name = 'Box Mode',
        order = 1,
        desc = 'If checked, this bar will show boxes instead of textures',
      },
    },
  }

  return DemonicBarOptions
end

-------------------------------------------------------------------------------
-- CreateCopyPasteOptions
--
-- Creates options for to copy and paste bars.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: CopyPasteOptions = CreateCopyPasteOptions(BarType, Order)
--
-- BarType               Type of options being created.
-- Order                 Order number.
--
-- EclipseBarOptions     Options table for the copy paste options.
-------------------------------------------------------------------------------
local function CreateCopyPasteOptions(BarType, Order)
  local UBF = UnitBarsF[BarType]

  local CopyPasteOptions = nil
  CopyPasteOptions = {
    type = 'group',
    name = function()
             if CapCopyName and CapCopyKey then
               return format('Copy and Paste ( %s -> %s )', CapCopyName, CapCopyKey)
             else
               return 'Copy and Paste'
             end
           end,
    dialogInline = true,
    order = Order,
    confirm = function(Info)
                if Info[#Info] == 'Paste' then
                  return format('Copy %s from %s to %s', CapCopyKey, CapCopyName, UBF.UnitBar.Name)
                end
              end,
    func = function(Info, Value)
             local Name = Info[#Info]
             if Name ~= 'Paste' and Name ~= 'Clear' then

               -- Store the data to the clipboard.
               CapCopyUB = UBF.UnitBar
               CapCopyName = UBF.UnitBar.Name
               CapCopyKey = Name
             else
               if Name == 'Paste' then

                 -- Save name and locaton.
                 local UB = UBF.UnitBar
                 local Name = UB.Name
                 local x, y = UB.x, UB.y

                 if CapCopyKey == 'All' then
                   Main:CopyTableValues(CapCopyUB, UBF.UnitBar)
                 else
                   Main:CopyTableValues(CapCopyUB[CapCopyKey], UBF.UnitBar[CapCopyKey])
                 end

                 -- Restore name and location.
                 UB.Name = Name
                 UB.x, UB.y = x, y

                 -- Update the bar.
                 UBF:SetAttr(nil, nil)
                 UBF:Update()

               end
               CapCopyUB = nil
               CapCopyName = nil
               CapCopyKey = nil
             end
           end,
    args = {
      All = 1,
      Status = 2,
      Other = 3,
      Background = 4,
      Bar = 5,
      Text = 6,
      Text2 = 7,
      Spacer = 10,
      Paste = 11,
      Clear = 12,
    },
  }

  -- Create buttons
  local Order = 0
  local Args = CopyPasteOptions.args
  for Key, Order in pairs(Args) do
    if strfind(Key, 'Spacer') == nil then
      local t = {}

      t.type = 'execute'
      t.name = Key == 'Backgrnd' and 'Background' or Key
      t.order = Order
      t.width = 'half'
      if Key == 'Paste' then

        -- Disable paste if nothing to paste.
        t.disabled = function()
                       return CapCopyUB == nil or CapCopyKey ~= 'All' and
                              ( UBF.UnitBar[CapCopyKey] == nil or CapCopyUB[CapCopyKey] == UBF.UnitBar[CapCopyKey] )
                     end
      elseif Key == 'Clear' then

        -- Disable clear if theres nothing to paste.
        t.disabled = function()
                       return CapCopyUB == nil
                     end
      else

        -- Disable the button if the source doesn't exist.
        t.disabled = Key ~= 'All' and UBF.UnitBar[Key] == nil
      end
      Args[Key] = t
    else
      Args[Key] = CreateSpacer(Order)
    end
  end

  return CopyPasteOptions
end

-------------------------------------------------------------------------------
-- CreateUnitBarOptions
--
-- Creates an options table for a UnitBar.
--
-- Subfunction of CreateMainOptions()
--
-- Usage: UnitBarOptions = CreateUnitBarOptions(BarType, Order, Name, Desc)
--
-- BarType          Type of options table to create.
-- Order            Order number for the options.
-- Name             Name for the option to appear in the tree.
-- Desc             Description for option.  Set to nil for no description.
--
-- UnitBarOptions   Options table for a specific unitbar.
-------------------------------------------------------------------------------
local function CreateUnitBarOptions(BarType, Order, Name, Desc)
  local UBF = UnitBarsF[BarType]

  local UnitBarOptions = {
    type = 'group',
    name = Name,
    order = Order,
    desc = Desc,
    args = {
      Status = {
        type = 'group',
        name = 'Status',
        dialogInline = true,
        order = 1,
        get = function(Info)
                return UBF.UnitBar.Status[Info[#Info]]
              end,
        set = function(Info, Value)
                UBF.UnitBar.Status[Info[#Info]] = Value

                -- Must do a status check/update.
                GUB:UnitBarsUpdateStatus()
              end,
        args = {
          ShowNever = {
            type = 'toggle',
            name = 'Never Show',
            order = 1,
            desc = 'Disables and hides the bar',
          },
          HideNotUsable = {
            type = 'toggle',
            name = 'Hide not Usable',
            disabled = function()
                         return UBF.UnitBar.Status.HideNotUsable == nil
                       end,
            order = 2,
            desc = 'Disables and hides the bar if it can not be used by your class, spec, stance, or form, etc',
          },
          HideWhenDead = {
            type = 'toggle',
            name = 'Hide when Dead',
            order = 3,
            desc = "Hides the bar when you're dead",
          },
          HideInVehicle = {
            type = 'toggle',
            name = 'Hide in Vehicle',
            order = 4,
            desc = "Hides the bar when your're in a vehicle",
          },
          ShowAlways = {
            type = 'toggle',
            name = 'Show Always',
            order = 5,
            desc = 'Bar will always be shown',
          },
          HideNotActive = {
            type = 'toggle',
            name = 'Hide not Active',
            disabled = function()
                         return BarType == 'EclipseBar'
                       end,
            order = 6,
            desc = 'Bar will be hidden if its not active. This only gets checked out of combat',
          },
          HideNoCombat = {
            type = 'toggle',
            name = 'Hide no Combat',
            order = 7,
            desc = 'When not in combat the bar will be hidden',
          },
        },
      },
    },
  }

--  local UBOSA = UnitBarOptions.args.Status.args

  local UBOA = UnitBarOptions.args

  -- Add general options for each bar.
    -- Add runebar options
  if BarType == 'RuneBar' then
    UBOA.RuneBar = CreateRuneBarOptions(BarType, 2, 'General')

  -- Add combobar options
  elseif BarType == 'ComboBar' then
    UBOA.ComboBar =  CreateComboBarOptions(BarType, 2, 'General')

  -- Add holybar options
  elseif BarType == 'HolyBar' then
    UBOA.HolyBar = CreateHolyBarOptions(BarType, 2, 'General')

  -- Add shardbar options
  elseif BarType == 'ShardBar' then
    UBOA.ShardBar = CreateShardBarOptions(BarType, 2, 'General')

  elseif BarType == 'DemonicBar' then
    UBOA.DemonicBar = CreateDemonicBarOptions(BarType, 2, 'General')

  -- Add eclipsebar options
  elseif BarType == 'EclipseBar' then
    UBOA.EclipseBar = CreateEclipseBarOptions(BarType, 2, 'General')

  -- Add health and power bar options
  elseif BarType == 'PlayerPower' and PlayerClass == 'HUNTER' or strfind(BarType, 'Power') == nil and BarType ~= 'PetHealth' then
    UBOA.HapBar = CreateHapBarOptions(BarType, 2, 'General')
  end

  UnitBarOptions.args.Other = {
    type = 'group',
    name = 'Other',
    dialogInline = true,
    order = 3,
    args = {
      Scale = {
        type = 'range',
        name = 'Scale',
        order = 1,
        desc = 'Changes the scale of the bar',
        min = UnitBarScaleMin,
        max = UnitBarScaleMax,
        step = 1,
        get = function()
                return UBF.UnitBar.Other.Scale
        end,
        set = function(Info, Value)
                UBF.UnitBar.Other.Scale = Value
                UBF:SetAttr('frame', 'scale')
              end,
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
        get = function()
                return ConvertFrameStrata[UBF.UnitBar.Other.FrameStrata]
              end,
        set = function(Info, Value)
                UBF.UnitBar.Other.FrameStrata = ConvertFrameStrata[Value]
                UBF:SetAttr('frame', 'strata')
              end,
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

                 Main:CopyTableValues(Defaults.profile[BarType], UB)

                 UB.x, UB.y = x, y

                 -- Update the layout.
                 UBF:SetLayout()
                 UBF:StatusCheck()
                 UBF:Update()
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
                 local UBd = Defaults.profile[BarType]
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

  UnitBarOptions.args.CopyPaste = CreateCopyPasteOptions(BarType, 4)

  -- Add bar options for eclipse bar
  if BarType == 'EclipseBar' then
    UBOA.Background = {
      type = 'group',
      name = 'Background',
      order = 1000,
      childGroups = 'tab',
      args = {
        Moon = CreateBackgroundOptions(BarType, 'moon', 1, 'Moon'),
        Sun = CreateBackgroundOptions(BarType, 'sun', 2, 'Sun'),
        Bar = CreateBackgroundOptions(BarType, 'bar', 3, 'Bar'),
        Slider = CreateBackgroundOptions(BarType, 'slider', 4, 'Slider'),
        PredictedSlider = CreateBackgroundOptions(BarType, 'indicator', 5, 'Indicator'),
      }
    }
    UBOA.Bar = {
      type = 'group',
      name = 'Bar',
      order = 1001,
      childGroups = 'tab',
      args = {
        Moon = CreateBarOptions(BarType, 'moon', 1, 'Moon'),
        Sun = CreateBarOptions(BarType, 'sun', 2, 'Sun'),
        Bar = CreateBarOptions(BarType, 'bar', 3, 'Bar'),
        Slider = CreateBarOptions(BarType, 'slider', 4, 'Slider'),
        PredictedSlider = CreateBarOptions(BarType, 'indicator', 5, 'Indicator'),
      }
    }
  else

    -- Add background options
    UBOA.Background = CreateBackgroundOptions(BarType, nil, 1000, 'Background')

    -- add bar options for this bar.
    UBOA.Bar = CreateBarOptions(BarType, nil, 1001, 'Bar')
  end

  -- Add text options
  if BarType ~= 'ComboBar' and BarType ~= 'HolyBar' and BarType ~= 'ShardBar' and BarType ~= 'DemonicBar' then
    UBOA.Text = CreateTextOptions(BarType, 'text', 1002, 'Text')
    if BarType ~= 'RuneBar' and BarType ~= 'EclipseBar' then
      UBOA.Text2 = CreateTextOptions(BarType, 'text2', 1003, 'Text2')
    end
  end

  return UnitBarOptions
end

-------------------------------------------------------------------------------
-- CreateMainOptions
--
-- Returns the main options table.
-------------------------------------------------------------------------------
local function CreateMainOptions()

  ProfileOptions.order = 100

--=============================================================================
--=============================================================================
--Galvin's UnitBars Group.
--=============================================================================
--=============================================================================
  local MainOptions = {
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
                return UnitBars[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[Info[#Info]] = Value
                Main:UnitBarsSetAllOptions()
                GUB:UnitBarsUpdateStatus()
              end,
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
          HideTooltips = {
            type = 'toggle',
            name = 'Hide Tooltips',
            order = 4,
            desc = 'Turns off mouse over tooltips when bars are not locked',
          },
          HideTooltipsDesc = {
            type = 'toggle',
            name = 'Hide Tooltips Desc',
            order = 5,
            desc = 'Turns off the description in mouse over tooltips when bars are not locked',
          },
          AlignmentToolEnabled = {
            type = 'toggle',
            name = 'Enable Alignment Tool',
            order = 6,
            desc = 'If unchecked, right clicking a unitbar will not open the alignment tool',
          },
          FadeOutTime = {
            type = 'range',
            name = 'Fadeout Time',
            order = 7,
            desc = 'The amount of time in seconds to fade out a bar',
            min = 0,
            max = 5,
            step = 1,
            get = function()
                    return UnitBars.FadeOutTime
                  end,
            set = function(Info, Value)
                    UnitBars.FadeOutTime = Value
                    Main:UnitBarsSetAllOptions()
                  end,
          },
          HideAllBars = {
            type = 'execute',
            name = 'Hide All Bars',
            order = 8,
            desc = 'Sets all the bars to never show',
            confirm = true,
            func = function()

                     -- Hide all bars.
                     for BarType, v in pairs(UnitBars) do
                       if type(v) == 'table' then

                         -- Set the show never flag to true.
                         UnitBars[BarType].Status.ShowNever = true

                         -- Must do a status check/update.
                         GUB:UnitBarsUpdateStatus()
                       end
                     end
                   end,
          },
        },
      },
--=============================================================================
-------------------------------------------------------------------------------
--    BARS group.
-------------------------------------------------------------------------------
--=============================================================================
      UnitBars = {
        type = 'group',
        name = 'Bars',
        order = 2,
        args = {

          -- Player Health group.
          PlayerHealth = CreateUnitBarOptions('PlayerHealth', 1, 'Player Health'),

          -- Player Power group.
          PlayerPower = CreateUnitBarOptions('PlayerPower', 2, 'Player Power'),

          -- Target Health group.
          TargetHealth = CreateUnitBarOptions('TargetHealth', 3, 'Target Health'),

          -- Target Power group.
          TargetPower = CreateUnitBarOptions('TargetPower', 4, 'Target Power'),

          -- Focus Health group.
          FocusHealth = CreateUnitBarOptions('FocusHealth', 5, 'Focus Health'),

          -- Focus Power group.
          FocusPower = CreateUnitBarOptions('FocusPower', 6, 'Focus Power'),

          -- Pet Health group.
          PetHealth = CreateUnitBarOptions('PetHealth', 7, 'Pet Health', 'Classes with pets only'),

          -- Pet Power group.
          PetPower = CreateUnitBarOptions('PetPower', 8, 'Pet Power', 'Classes with pets only'),

          -- Main Power group.
          MainPower = CreateUnitBarOptions('MainPower', 9, 'Main Power', 'Druids only: Shown when in cat or bear form'),

          -- Runebar group.
          RuneBar = CreateUnitBarOptions('RuneBar', 10, 'Rune Bar'),

          -- Combobar group.
          ComboBar = CreateUnitBarOptions('ComboBar', 11, 'Combo Bar'),

          -- Holybar group.
          HolyBar = CreateUnitBarOptions('HolyBar', 12, 'Holy Bar'),

          -- Shardbar group.
          ShardBar = CreateUnitBarOptions('ShardBar', 13, 'Shard Bar', 'Affliction Warlocks only'),

          -- Demonicbar group.
          DemonicBar = CreateUnitBarOptions('DemonicBar', 14, 'Demonic Bar', 'Demonology Warlocks only'),

          -- Eclipsebar group.
          EclipseBar = CreateUnitBarOptions('EclipseBar', 15, 'Eclipse Bar', 'Balance Druids only: Shown when in moonkin form or normal form'),
        },
      },
--[[ --=============================================================================
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
]]
--=============================================================================
-------------------------------------------------------------------------------
--    PROFILES group.
-------------------------------------------------------------------------------
--=============================================================================
      Profile = ProfileOptions,
      -- order = 100 -- make sure its always at the end.
--=============================================================================
-------------------------------------------------------------------------------
--    HELP group.
-------------------------------------------------------------------------------
--=============================================================================
      Help = {
        type = 'group',
        name = 'Help',
        order = 101,
        args = {
          Verstion = {
            type = 'description',
            name = function()
                     return format('|cffffd200%s   version %s|r', AddonName, AddonVersion)
                   end,
            order = 1,
          },
          HelpText = {
            type = 'description',
            name = HelpText,
            order = 2,
          },
        },
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
-- Alignment tool options window
-------------------------------------------------------------------------------
local function CreateAlignmentToolOptions()

  -- Options
  local PaddingEnabled = false
  local Alignment = nil
  local Justify = nil
  local Padding = nil

  local HorizontalRadio = nil
  local VerticalRadio = nil
  local JustifyRadio1 = nil
  local JustifyRadio2 = nil
  local PaddingSlider = nil

  -- Horizontal radio button.
  local function HRadioSet(self)
    if self.Checked then
      VerticalRadio:SetValue(false)
      JustifyRadio1:SetLabel('Justify Top')
      JustifyRadio2:SetLabel('Justify Bottom')
      Alignment = 'horizontal'
    end
  end

  -- Vertical radio button.
  local function VRadioSet(self)
    if self.Checked then
      HorizontalRadio:SetValue(false)
      JustifyRadio1:SetLabel('Justify Left')
      JustifyRadio2:SetLabel('Justify Right')
      Alignment = 'vertical'
    end
  end

  -- Justify radio button 1
  local function JustifyRadioSet1(self)
    if self.Checked then
      JustifyRadio2:SetValue(false)
      Justify = 1
    end
  end

  -- Justify radio button 2.
  local function JustifyRadioSet2(self)
    if self.Checked then
      JustifyRadio1:SetValue(false)
      Justify = 2
    end
  end

  -- Enable padding slider checkbox.
  local function EnablePaddingSet(self)
    PaddingEnabled = self.Checked
    PaddingSlider:SetEnabled(PaddingEnabled)
  end

  -- Align button.
  local function AButtonSet(self)
    Main:AlignUnitBars(Alignment, Justify, PaddingEnabled, Padding)
  end

  -- Padding slider.
  local function PaddingSet(self)
    Padding = self:GetValue()
    AButtonSet()
  end

  -- Gets called when the ATOFrame is shown, hidden, or closed.
  local function WindowFrame(self, Event)

    -- If the alignment tool window button was clicked then hide.
    if Event == 'close' then
      self:Hide()

    -- if the window is hidden then disable select mode.
    elseif Event == 'hide' then
      Main:EnableSelectMode(false)

    -- if the window is shown then enable select mode.
    elseif Event == 'show' then

      -- If the tool is enabled then open.
      if UnitBars.AlignmentToolEnabled then
        Main:EnableSelectMode(true)
      else
        self:Hide()
      end
    end
  end


  -- Create Alignment Control frame.
  local ATOFrame = WoWUI:CreateControlWindow('CENTER', 150, 0, 0, 360, WindowFrame)
  ATOFrame:Hide()

  HorizontalRadio = WoWUI:CreateSelectButton(ATOFrame.ControlPaneFrame, 'radio', 'Left to Right', 'TOPLEFT', '', 5, -5, HRadioSet)
  VerticalRadio = WoWUI:CreateSelectButton(HorizontalRadio, 'radio', 'Top to Bottom', 'TOPLEFT', 'BOTTOMLEFT', 0, 5, VRadioSet)

  JustifyRadio1 = WoWUI:CreateSelectButton(HorizontalRadio, 'radio', '', 'LEFT', 'RIGHT', 20, 0, JustifyRadioSet1)
  JustifyRadio2 = WoWUI:CreateSelectButton(JustifyRadio1, 'radio', '', 'TOPLEFT', 'BOTTOMLEFT', 0, 5, JustifyRadioSet2)

  local EnablePaddingCheck = WoWUI:CreateSelectButton(VerticalRadio, 'check', 'Padding', 'TOPLEFT', 'BOTTOMLEFT', 0, 0, EnablePaddingSet)
  PaddingSlider = WoWUI:CreateSlider(EnablePaddingCheck, 'Padding', 'LEFT', 'RIGHT', 30, -10, 220, -10 , 50, PaddingSet)

  local AlignButton = WoWUI:CreatePanelButton(EnablePaddingCheck, 'Align', 'TOPLEFT', 'BOTTOMLEFT', 0, -5, 90, AButtonSet)
  local HelpButton = WoWUI:CreatePanelButton(ATOFrame.ControlPaneFrame, 'Help', 'TOPRIGHT', '', -10, -7, 60, function() end)

  -- Set values
  VerticalRadio:SetValue(true)
  JustifyRadio1:SetValue(true)
  EnablePaddingCheck:SetValue(false)
  PaddingSlider:SetValue(-10)

  -- Set help tooltip text
  HelpButton:SetTooltip('Alignment Help')
  HelpButton:SetTooltip(nil, '|cff00ff00Left to Right|r  Bars will be lined up horizontally')
  HelpButton:SetTooltip(nil, '|cff00ff00Top to Bottom|r  Bars will be lined up vertically')
  HelpButton:SetTooltip(nil, '|cff00ff00Justify|r  Bars are lined up by a side')
  HelpButton:SetTooltip(nil, '|cff00ff00Padding|r  This sets the amount of space between bars')
  HelpButton:SetTooltip(nil, '|cff00ff00Align|r  Click this to set the alignment')
  HelpButton:SetTooltip(nil, ' ')
  HelpButton:SetTooltip(nil, '|cff00ff00Right click|r to select a primary bar (green) to line bars up with')
  HelpButton:SetTooltip(nil, '|cff00ff00Left click|r a bar (white) to line up with the primary bar')
  GUB.Options.ATOFrame = ATOFrame
end

-------------------------------------------------------------------------------
-- OnInitialize()
--
-- Initializes the options panel and slash options
-------------------------------------------------------------------------------
function GUB.Options:OnInitialize()

  -- Create the unitbars options.
  ProfileOptions = LibStub('AceDBOptions-3.0'):GetOptionsTable(GUB.MainDB)

  SlashOptions = CreateSlashOptions()
  MainOptions = CreateMainOptions()

  -- Register the slash command options.
  LibStub('AceConfig-3.0'):RegisterOptionsTable(AddonSlashName, SlashOptions, 'gub')

  -- Register the options panel with aceconfig and add it to blizz options.
  LibStub('AceConfig-3.0'):RegisterOptionsTable(AddonOptionsName, MainOptions)
  MainOptionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(AddonOptionsName, AddonName)

  -- Add the Profiles UI as a subcategory below the main options.
  LibStub('AceConfig-3.0'):RegisterOptionsTable(AddonProfileName, ProfileOptions)
  -- ProfilesOptionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(AddonProfileName, 'Profiles', AddonName)

  -- Create the alignment tool options
  CreateAlignmentToolOptions()
end
