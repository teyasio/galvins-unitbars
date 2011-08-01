--
-- Options.lua
--
-- Handles all the options for GalvinUnitBars.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.Options = {}
local Main = GUB.Main

local LSM = Main.LSM
local UnitBarsF = Main.UnitBarsF
local Defaults = Main.Defaults
local HelpText = GUB.Help.HelpText

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
--
-- FontStyleDropdown             Table used for the dialog drop down for FontStyles.
-- PositionDropdown              Table used for the diaglog drop down for fonts and runes.
-- FontHAlignDropDown            Table used for the dialog drop down for font horizontal alignment.
-- ValueTypeDropdown             Table used for the dialog drop down for Health and power text type.
-- ValueNameDropdown             Table used for the dialog drop down for health and power text type.
-- ValueNameDropdownPredicted    Same as above except used for bars that support predicted value.
-- MaxValuesDropdown             Tanle used for the dialog drop down for Health and power text type.
-- UnitBarsSelectDropdown        Table used to pick from a list of unitbars.
-- AlignBarsDropdown             Table used for horizontal alignment dropdown.
-- AlignmentTypeDropdown         Table used to pick vertical or horizontal alignment.
-- DirectionDropdown             Table used to pick vertical or horizontal.
-- RuneModeDropdown              Table used to pick which mode runes are shown in.
-- IndicatorDropdown             Table used to for the indicator for predicted power.
-------------------------------------------------------------------------------

-- Addon Constants
local AddonName = GetAddOnMetadata(MyAddon, 'Title')
local AddonVersion = GetAddOnMetadata(MyAddon, 'Version')
local AddonOptionsName = MyAddon .. 'options'
local AddonProfileName = MyAddon .. 'profile'
local AddonSlashName = MyAddon

local MainOptionsFrame = nil
local ProfileFrame = nil

local SlashOptions = nil
local MainOptions = nil
local ProfileOptions = nil

local UnitBars = nil
local PlayerClass = nil
local PlayerPowerType = nil

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

local HapBarWidthMin = 10
local HapBarWidthMax = 500
local HapBarHeightMin = 10
local HapBarHeightMax = 500
local HapBarWidthSoftMax = 300
local HapBarHeightSoftMax = 300

local RuneBarAngleMin = 45
local RuneBarAngleMax = 360
local RuneBarSizeMin = 10
local RuneBarSizeMax = 100
local RuneBarPaddingMin = -10
local RuneBarPaddingMax = 50
local RuneBarWidthMin = 10
local RuneBarWidthMax = 200
local RuneBarHeightMin = 10
local RuneBarHeightMax = 200
local RuneOffsetXMin = -50
local RuneOffsetXMax = 50
local RuneOffsetYMin = -50
local RuneOffsetYMax = 50


local ComboBarPaddingMin = -10
local ComboBarPaddingMax = 50
local ComboBarFadeOutMin = 0
local ComboBarFadeOutMax = 5
local ComboBarAngleMin = 45
local ComboBarAngleMax = 360

local HolyBarSizeMin = 10
local HolyBarSizeMax = 100
local HolyBarScaleMin = 0.05
local HolyBarScaleMax = 1.20
local HolyBarPaddingMin = -50
local HolyBarPaddingMax = 50
local HolyBarFadeOutMin = 0
local HolyBarFadeOutMax = 5
local HolyBarAngleMin = 45
local HolyBarAngleMax = 360

local ShardBarSizeMin = 10
local ShardBarSizeMax = 100
local ShardBarScaleMin = 0.05
local ShardBarScaleMax = 1.20
local ShardBarPaddingMin = -50
local ShardBarPaddingMax = 50
local ShardBarFadeOutMin = 0
local ShardBarFadeOutMax = 5
local ShardBarAngleMin = 45
local ShardBarAngleMax = 360

local EclipseMoonWidthMin = 10
local EclipseMoonWidthMax = 50
local EclipseMoonHeightMin = 10
local EclipseMoonHeightMax = 50
local EclipseSunWidthMin = 10
local EclipseSunWidthMax = 50
local EclipseSunHeightMin = 10
local EclipseSunHeightMax = 50
local EclipseBarWidthMin = 10
local EclipseBarWidthMax = 200
local EclipseBarHeightMin = 10
local EclipseBarHeightMax = 200
local EclipseSliderWidthMin = 10
local EclipseSliderWidthMax = 50
local EclipseSliderHeightMin = 10
local EclipseSliderHeightMax = 50
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

local AlignmentPaddingMin = -10
local AlignmentPaddingMax = 50

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

local UnitBarsSelectDropdown = {
  PlayerHealth = Defaults.profile.PlayerHealth.Name,
  PlayerPower = Defaults.profile.PlayerPower.Name,
  TargetHealth = Defaults.profile.TargetHealth.Name,
  TargetPower = Defaults.profile.TargetPower.Name,
  FocusHealth = Defaults.profile.FocusHealth.Name,
  FocusPower = Defaults.profile.FocusPower.Name,
  PetHealth = Defaults.profile.PetHealth.Name,
  PetPower = Defaults.profile.PetPower.Name,
  MainPower = Defaults.profile.MainPower.Name,
  RuneBar = Defaults.profile.RuneBar.Name,
  ComboBar = Defaults.profile.ComboBar.Name,
  HolyBar = Defaults.profile.HolyBar.Name,
  ShardBar = Defaults.profile.ShardBar.Name,
  EclipseBar = Defaults.profile.EclipseBar.Name
}

local AlignBarsDropdown = {
  horizontal = {
    top = 'Top',
    bottom = 'Bottom',
  },
  vertical = {
    left = 'Left',
    right = 'Right',
  }
}

local AlignmentTypeDropdown = {
  vertical = 'Vertical Alignment',
  horizontal = 'Horizontal Alignment'
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

local IndicatorDropdown = {
  showalways = 'Show Always',
  hidealways = 'Hide always',
  none       = 'None',
}
--*****************************************************************************
--
-- Options creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SendOptionsData
--
-- Sends data to options.lua
--
-- Usage: SendOptionsData(UB, PC, PPT)
--
-- UB       UnitBar from Main.lua
-- PC       PlayerClass from main.lua
-- PPT      PlayerPowerType from main.lua
--
-- NOTE: Setting any of these to nil will not change that value.
-------------------------------------------------------------------------------
function GUB.Options:SendOptionsData(UB, PC, PPT)
  if UB then
    UnitBars = UB
  end
  if PC then
    PlayerClass = PC
  end
  if PPT then
    PlayerPowerType = PPT
  end
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
-- Returns a table depending on values passed.
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
--
-- Usage: ColorAllOptions = CreateColorAllOptions(BarType, Object, MaxColors, Order, Name)
--
-- BarType       Type of options being created.
-- Object        Can be 'bg', 'bar', or 'text'
-- MaxColors     Maximum number of colors can be 3, 5, 6 or 8.
-- Order         Order number.
-- Name          Name text
--
-- ColorAllOptions  Options table for the bartype.
-------------------------------------------------------------------------------
local function CreateColorAllOptions(BarType, Object, MaxColors, Order, Name)
  local ColorAllNames = UnitBarsF[BarType].ColorAllNames
  local UnitBarTable = nil

  if Object == 'bg' then
    UnitBarTable = 'Background'
  elseif Object == 'bar' then
    UnitBarTable = 'Bar'
  elseif Object == 'text' then
    UnitBarTable = 'Text'
  end

  local ColorAllOptions = {
    type = 'group',
    name = Name,
    order = Order,
    hidden = function()
               return Object == 'bg' and ( BarType == 'HolyBar' or BarType == 'ShardBar' ) and
                      not UnitBars[BarType].General.BoxMode
             end,
    dialogInline = true,
    get = function(Info)

            -- Info.arg[1] = color index.
            local c = UnitBars[BarType][UnitBarTable].Color

            if Info.arg[1] ~= 0 then
              c = c[Info.arg[1]]
            end
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local c = UnitBars[BarType][UnitBarTable].Color

            if Info.arg[1] ~= 0 then
              c = c[Info.arg[1]]
            end
            c.r, c.g, c.b, c.a = r, g, b, a

            -- Set the color to the bar
            UnitBarsF[BarType]:SetAttr(Object, 'color')
          end,
    args = {
      ColorAllToggle = {
        type = 'toggle',
        name = 'All',
        order = 1,
        desc = 'If checked everything can be set to one color',
        get = function()
                return UnitBars[BarType][UnitBarTable].ColorAll
              end,
        set = function(Info, Value)
                UnitBars[BarType][UnitBarTable].ColorAll = Value

                -- Refresh colors when changing between all and normal.
                UnitBarsF[BarType]:SetAttr(Object, 'color')
              end,
      },
      ColorAll = {
        type = 'color',
        name = 'Color',
        order = 2,
        hasAlpha = true,
        desc = 'Set everything to one color',
        hidden = function()
                   return not UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        arg = {0},
      },
      Spacer = {
        type = 'description',
        name = '',
        order = 3,
        width = 'full',
      },
      Color1 = {
        type = 'color',
        name = function()
                 return ColorAllNames[1]
               end,
        order = 4,
        hasAlpha = true,
        hidden = function()
                   return UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {1},
      },
      Color2 = {
        type = 'color',
        name = function()
                 return ColorAllNames[2]
               end,
        order = 5,
        hasAlpha = true,
        hidden = function()
                   return UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {2},
      },
      Color3 = {
        type = 'color',
        name = function()
                 return ColorAllNames[3]
               end,
        order = 6,
        hasAlpha = true,
        hidden = function()
                   return UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {3},
      },
      Color4 = {
        type = 'color',
        name = function()
                 return ColorAllNames[4]
               end,
        order = 7,
        hasAlpha = true,
        hidden = function()
                   return MaxColors < 4 or UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {4},
      },
      Color5 = {
        type = 'color',
        name = function()
                 return ColorAllNames[5]
               end,
        order = 8,
        hasAlpha = true,
        hidden = function()
                   return MaxColors < 5 or UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {5},
      },
      Color6 = {
        type = 'color',
        name = function()
                 return ColorAllNames[6]
               end,
        order = 9,
        hasAlpha = true,
        hidden = function()
                   return MaxColors < 6 or UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {6},
      },
      Color7 = {
        type = 'color',
        name = function()
                 return ColorAllNames[7]
               end,
        order = 10,
        hasAlpha = true,
        hidden = function()
                   return MaxColors < 7 or UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {7},
      },
      Color8 = {
        type = 'color',
        name = function()
                 return ColorAllNames[8]
               end,
        order = 11,
        hasAlpha = true,
        hidden = function()
                   return MaxColors < 8 or UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {8},
      },
    },
  }
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
  local UnitBarTable = nil
  TableName = ('%s%s'):format(strupper(strsub(TableName, 1, 1)), strsub(TableName, 2))

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
        desc = 'If checked the sun and moon color will be used',
        get = function()
                return UnitBars[BarType][UnitBarTable][TableName].SunMoon
              end,
        set = function(Info, Value)
                UnitBars[BarType][UnitBarTable][TableName].SunMoon = Value

                -- Update the bar to update shared colors.
                UnitBarsF[BarType]:Update()
              end,
      },
      SliderColor = {
        type = 'color',
        name = 'Color',
        hasAlpha = true,
        order = 2,
        hidden = function()
                   return UnitBars[BarType][UnitBarTable][TableName].SunMoon
                 end,
        get = function(Info)
                -- Info.arg[1] = color index.
                local c = UnitBars[BarType][UnitBarTable][TableName].Color
                return c.r, c.g, c.b, c.a
              end,
        set = function(Info, r, g, b, a)
                local c = UnitBars[BarType][UnitBarTable][TableName].Color
                c.r, c.g, c.b, c.a = r, g, b, a

                UnitBarsF[BarType]:SetAttr(Object, 'color', strlower(TableName))

                -- Set the color to the bar
                UnitBarsF[BarType]:Update()
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
  local TableName = nil
  if Object then
    TableName = ('%s%s'):format(strupper(strsub(Object, 1, 1)), strsub(Object, 2))
  end

  local BackgroundOptions = {
    type = 'group',
    name = Name,
    order = Order,
    hidden = function()
               return BarType == 'RuneBar' and UnitBars[BarType].General.RuneMode == 'rune'
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
                  UnitBarsF[BarType]:SetAttr('bg', 'backdrop', Object)

                  -- Update the bar
                  UnitBarsF[BarType]:Update()
                else
                  UnitBarsF[BarType]:SetAttr('bg', 'backdrop')
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
          Spacer10 = {
            type = 'description',
            name = '',
            order = 10,
            width = 'full',
          },
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
          Spacer20 = {
            type = 'description',
            name = '',
            order = 20,
            width = 'full',
          },
          BdSize = {
            type = 'range',
            name = 'Border Thickness',
            order = 21,
            min = UnitBarBorderSizeMin,
            max = UnitBarBorderSizeMax,
            step = 2,
          },
          BgColor = {
            type = 'color',
            name = 'Background Color',
            order = 22,
            hidden = function()
                       return BarType == 'ComboBar' or ( BarType == 'HolyBar' or BarType == 'ShardBar' ) and
                              UnitBars[BarType].General.BoxMode
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
                      UnitBarsF[BarType]:SetAttr('bg', 'color', Object)
                    else
                      UnitBarsF[BarType]:SetAttr('bg', 'color')
                    end
                  end,
          },
        },
      },
      Padding = {
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
                  UnitBarsF[BarType]:SetAttr('bg', 'backdrop', Object)
                else
                  UnitBarsF[BarType]:SetAttr('bg', 'backdrop')
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
          Spacer = {
            type = 'description',
            name = '',
            order = 2,
            width = 'full',
          },
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
      },
    },
  }

  -- Add color all options.
  if BarType == 'RuneBar' or BarType == 'ComboBar' or BarType == 'HolyBar' or BarType == 'ShardBar' then
    local MaxColors = 5
    if BarType == 'HolyBar' or BarType == 'ShardBar' then
      MaxColors = 3
    elseif BarType == 'RuneBar' then
      BackgroundOptions.args.General.args.BgColor = nil
      MaxColors = 8
    end
    BackgroundOptions.args.BgColors = CreateColorAllOptions(BarType, 'bg', MaxColors, 2, 'Colors')
  end

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
local function GetValueNameDropdown(BarType)
  return ValueNameDropdownPredicted
end

local function CreateTextOptions(BarType, Object, Order, Name)

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
    args = {
      TextType = {
        type = 'group',
        name = 'Text Type',
        dialogInline = true,
        order = 1,
        get = function(Info)
                local UBT = UnitBars[BarType][UnitBarTable].TextType
                if Info.arg[1] == 'name' then
                  return UBT.ValueName[Info.arg[2]]
                elseif Info.arg[1] == 'type' then
                  return UBT.ValueType[Info.arg[2]]
                else
                  return UBT[Info[#Info]]
                end
              end,
        set = function(Info, Value)
                local UBT = UnitBars[BarType][UnitBarTable].TextType
                if Info.arg[1] == 'name' then
                  UBT.ValueName[Info.arg[2]] = Value
                elseif Info.arg[1] == 'type' then
                  UBT.ValueType[Info.arg[2]] = Value
                else
                  UBT[Info[#Info]] = Value
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
                UnitBarsF[BarType]:Update()
              end,
        args = {
          MaxValues = {
            type = 'select',
            order = 1,
            name = 'Max Values',
            values = MaxValuesDropdown,
            style = 'dropdown',
            desc = 'Sets how many values to be shown',
            arg = {0},
          },
          Spacer = {
            type = 'description',
            name = '',
            order = 2,
            width = 'full',
          },
          ValueName1 = {
            type = 'select',
            order = 3,
            name = 'Value Name 1',
            hidden = function()
                       return UnitBars[BarType][UnitBarTable].TextType.MaxValues < 1
                     end,
            values = function()
                       return GetValueNameDropdown(BarType)
                     end,
            style = 'dropdown',
            desc = 'Pick the name of the value to show',
            arg = {'name', 1},
          },
          ValueType1 = {
            type = 'select',
            name = '',
            order = 4,
            name = 'Value Type 1',
            values = ValueTypeDropdown,
            hidden = function()
                       return UnitBars[BarType][UnitBarTable].TextType.MaxValues < 1
                     end,
            style = 'dropdown',
            desc = 'Changes how the value is shown',
            arg = {'type', 1},
          },
          Spacer2 = {
            type = 'description',
            name = '',
            order = 5,
            width = 'full',
          },
          ValueName2 = {
            type = 'select',
            order = 6,
            name = 'Value Name 2',
            hidden = function()
                       return UnitBars[BarType][UnitBarTable].TextType.MaxValues < 2
                     end,
            values = function()
                       return GetValueNameDropdown(BarType)
                     end,
            style = 'dropdown',
            desc = 'Pick the name of the value to show',
            arg = {'name', 2},
          },
          ValueType2 = {
            type = 'select',
            name = '',
            order = 7,
            name = 'Value Type 2',
            values = ValueTypeDropdown,
            hidden = function()
                       return UnitBars[BarType][UnitBarTable].TextType.MaxValues < 2
                     end,
            style = 'dropdown',
            desc = 'Changes how the value is shown',
            arg = {'type', 2},
          },
          Spacer3 = {
            type = 'description',
            name = '',
            order = 8,
            width = 'full',
          },
          ValueName3 = {
            type = 'select',
            order = 9,
            name = 'Value Name 3',
            hidden = function()
                       return UnitBars[BarType][UnitBarTable].TextType.MaxValues < 3
                     end,
            values = function()
                       return GetValueNameDropdown(BarType)
                     end,
            style = 'dropdown',
            desc = 'Pick the name of the value to show',
            arg = {'name', 3},
          },
          ValueType3 = {
            type = 'select',
            name = '',
            order = 10,
            name = 'Value Type 3',
            values = ValueTypeDropdown,
            hidden = function()
                       return UnitBars[BarType][UnitBarTable].TextType.MaxValues < 3
                     end,
            style = 'dropdown',
            desc = 'Changes how the value is shown',
            arg = {'type', 3},
          },
          Spacer4 = {
            type = 'description',
            name = '',
            order = 100,
            width = 'full',
          },
          Custom = {
            type = 'toggle',
            name = 'Custom Layout',
            order = 101,
            desc = 'If checked the layout can be changed',
            arg = {0},
          },
          Layout = {
            type = 'description',
            order = 102,
            name = function()
                     return strconcat('|cFFFFFF00 Layout:|r ', UnitBars[BarType][UnitBarTable].TextType.Layout)
                   end,
            fontSize = 'large',
          },
          CustomLayout = {
            type = 'input',
            name = 'Custom Layout',
            order = 103,
            multiline = false,
            hidden = function()
                       return not UnitBars[BarType][UnitBarTable].TextType.Custom
                     end,
            get = function()
                    return UnitBars[BarType][UnitBarTable].TextType.Layout
                  end,
            set = function(Info, Value)
                    UnitBars[BarType][UnitBarTable].TextType.Layout = Value
                  end,
          },
        },
      },
      Font = {
        type = 'group',
        name = 'Font',
        dialogInline = true,
        order = 2,
        get = function(Info)
                return UnitBars[BarType][UnitBarTable].FontSettings[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[BarType][UnitBarTable].FontSettings[Info[#Info]] = Value
                UnitBarsF[BarType]:SetAttr(Object, 'font')
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
          TextColor = {
            type = 'color',
            name = 'Color',
            order = 7,
            hasAlpha = true,
            get = function()
                    local c = UnitBars[BarType][UnitBarTable].Color
                    return c.r, c.g, c.b, c.a
                  end,
            set = function(Info, r, g, b, a)
                    local c = UnitBars[BarType][UnitBarTable].Color
                    c.r, c.g, c.b, c.a = r, g, b, a
                    UnitBarsF[BarType]:SetAttr(Object, 'color')
                  end,
          },
        },
      },
      Offsets = {
        type = 'group',
        name = 'Offsets',
        dialogInline = true,
        order = 3,
        get = function(Info)
                return UnitBars[BarType][UnitBarTable].FontSettings[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[BarType][UnitBarTable].FontSettings[Info[#Info]] = Value
                UnitBarsF[BarType]:SetAttr(Object, 'font')
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
      },
    },
  }

  -- Remove the text type and text color options and add a text Color options for runebar only.
  if BarType == 'RuneBar' or BarType == 'EclipseBar' then
    TextOptions.args.TextType = nil
    if BarType == 'RuneBar' then
      TextOptions.args.Font.args.TextColor = nil
      TextOptions.args.TextColors = CreateColorAllOptions(BarType, 'text', 8, 2, 'Colors')
    end
  end

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
  local PowerColorsOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            -- Info.arg[1] = power color index.
            local c = UnitBars[BarType].Bar.Color[Info.arg[1]]
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local c = UnitBars[BarType].Bar.Color[Info.arg[1]]
            c.r, c.g, c.b, c.a = r, g, b, a

             -- Update the bar to show the current power color change in real time.
            UnitBarsF[BarType]:Update()
          end,
    args = {
      ManaColor = {
        type = 'color',
        name = 'Mana',
        order = 1,
        width = 'half',
        hasAlpha = true,
        arg = {0},
      },
      RageColor = {
        type = 'color',
        name = 'Rage',
        order = 2,
        width = 'half',
        hasAlpha = true,
        arg = {1},
      },
      FocusColor = {
        type = 'color',
        name = 'Focus',
        order = 3,
        width = 'half',
        hasAlpha = true,
        arg = {2},
      },
      EnergyColor = {
        type = 'color',
        name = 'Energy',
        order = 4,
        width = 'half',
        hasAlpha = true,
        arg = {3},
      },
      RunicColor = {
        type = 'color',
        name = 'Runic Power',
        order = 5,
        hasAlpha = true,
        arg = {6},
      },
    },
  }

  -- Remove power color options based on class.
  if BarType == 'PlayerPower' or BarType == 'MainPower' then
    local PCO = PowerColorsOptions.args
    if PlayerPowerType ~= 'MANA' then
      PCO.ManaColor = nil
    end
    if PlayerPowerType ~= 'RAGE' and PlayerClass ~= 'DRUID' then
      PCO.RageColor = nil
    end
    if PlayerPowerType ~= 'FOCUS' then
      PCO.FocusColor = nil
    end
    if PlayerPowerType ~= 'ENERGY' and PlayerClass ~= 'DRUID' then
      PCO.EnergyColor = nil
    end
    if PlayerPowerType ~= 'RUNIC_POWER' then
      PCO.RunicColor = nil
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
  local ClassColorsOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            -- Info.arg[1] = color index.
            local c = UnitBars[BarType].Bar.Color

            if Info.arg[1] ~= 0 then
              c = c[Info.arg[1]]
            end
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local c = UnitBars[BarType].Bar.Color

            if Info.arg[1] ~= 0 then
              c = c[Info.arg[1]]
            end
            c.r, c.g, c.b, c.a = r, g, b, a

            -- Set the color to the bar
            UnitBarsF[BarType]:Update()
          end,
    args = {
      ClassColorToggle = {
        type = 'toggle',
        name = 'Class Colors',
        order = 1,
        desc = 'If checked class colors will be used',
        get = function()
                return UnitBars[BarType].Bar.ClassColor
              end,
        set = function(Info, Value)
                UnitBars[BarType].Bar.ClassColor = Value

                -- Refresh color when changing between class colors and normal.
                UnitBarsF[BarType]:Update()
              end,
      },
      Spacer = {
        type = 'description',
        name = '',
        order = 2,
        width = 'full',
      },
      NormalColor = {
        type = 'color',
        name = 'Color',
        order = 3,
        hasAlpha = true,
        desc = 'Set normal color',
        hidden = function()
                   return UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {0},
      },
      DeathKnightColor = {
        type = 'color',
        name = 'Death Knight',
        order = 4,
        width = 'normal',
        hasAlpha = true,
        hidden = function()
                   return not UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {'DEATHKNIGHT'},
      },
      DruidColor = {
        type = 'color',
        name = 'Druid',
        order = 5,
        width = 'half',
        hasAlpha = true,
        hidden = function()
                   return not UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {'DRUID'},
      },
      HunterColor = {
        type = 'color',
        name = 'Hunter',
        order = 6,
        width = 'half',
        hasAlpha = true,
        hidden = function()
                   return not UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {'HUNTER'},
      },
      MageColor = {
        type = 'color',
        name = 'Mage',
        order = 7,
        width = 'half',
        hasAlpha = true,
        hidden = function()
                   return not UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {'MAGE'},
      },
      PaladinColor = {
        type = 'color',
        name = 'Paladin',
        order = 8,
        width = 'half',
        hasAlpha = true,
        hidden = function()
                   return not UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {'PALADIN'},
      },
      PriestColor = {
        type = 'color',
        name = 'Priest',
        order = 9,
        width = 'half',
        hasAlpha = true,
        hidden = function()
                   return not UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {'PRIEST'},
      },
      RogueColor = {
        type = 'color',
        name = 'Rogue',
        order = 10,
        width = 'half',
        hasAlpha = true,
        hidden = function()
                   return not UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {'ROGUE'},
      },
      ShamanColor = {
        type = 'color',
        name = 'Shaman',
        order = 11,
        width = 'half',
        hasAlpha = true,
        hidden = function()
                   return not UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {'SHAMAN'},
      },
      WarlockColor = {
        type = 'color',
        name = 'Warlock',
        order = 12,
        width = 'half',
        hasAlpha = true,
        hidden = function()
                   return not UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {'WARLOCK'},
      },
      WarriorColor = {
        type = 'color',
        name = 'Warrior',
        order = 13,
        width = 'half',
        hasAlpha = true,
        hidden = function()
                   return not UnitBars[BarType].Bar.ClassColor
                 end,
        arg = {'WARRIOR'},
      },
    },
  }
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
  local PredictedColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            -- Info.arg[1] = color index.
            local c = UnitBars[BarType].Bar.PredictedColor
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local c = UnitBars[BarType].Bar.PredictedColor
            c.r, c.g, c.b, c.a = r, g, b, a

            -- Set the color to the bar
            UnitBarsF[BarType]:Update()
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
  local TableName = nil
  if Object then
    TableName = ('%s%s'):format(strupper(strsub(Object, 1, 1)), strsub(Object, 2))
  end

  local BarOptions = {
    type = 'group',
    name = Name,
    order = Order,
    hidden = function()
               return BarType == 'RuneBar' and UnitBars[BarType].General.RuneMode == 'rune' or
                      ( BarType == 'HolyBar' or BarType == 'ShardBar' ) and not UnitBars[BarType].General.BoxMode
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
                  UnitBarsF[BarType]:SetLayout()
                else
                  if Object then
                    UnitBarsF[BarType]:SetLayout()

                    -- Update the bar to recalculate the slider pos.
                    UnitBarsF[BarType]:Update()
                  else
                    UnitBarsF[BarType]:SetAttr('bar', Info.arg[1])
                  end
                end
              end,
        args = {
          StatusBarTexture = {
            type = 'select',
            name = 'Bar Texture',
            order = 1,
            hidden = function()
                       return BarType == 'EclipseBar' and Object == 'bar'
                     end,
            dialogControl = 'LSM30_Statusbar',
            values = LSM:HashTable('statusbar'),
            arg = {'texture'},
          },
          StatusBarTextureLunar = {
            type = 'select',
            name = 'Bar Texture (lunar)',
            order = 2,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'bar'
                     end,
            dialogControl = 'LSM30_Statusbar',
            values = LSM:HashTable('statusbar'),
            arg = {'texture'},
          },
          StatusBarTextureSolar = {
            type = 'select',
            name = 'Bar Texture (solar)',
            order = 3,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'bar'
                     end,
            dialogControl = 'LSM30_Statusbar',
            values = LSM:HashTable('statusbar'),
            arg = {'texture'},
          },
          PredictedBarTexture = {
            type = 'select',
            name = 'Predicted Bar Texture',
            order = 4,
            hidden = function()
                       return BarType ~= 'PlayerHealth' and BarType ~= 'TargetHealth' and
                              BarType ~= 'FocusHealth' and BarType ~= 'PlayerPower' or
                              BarType == 'PlayerPower' and PlayerClass ~= 'HUNTER'
                     end,
            dialogControl = 'LSM30_Statusbar',
            values = LSM:HashTable('statusbar'),
            arg = {'texture'},
          },
          Spacer10 = {
            type = 'description',
            name = '',
            order = 10,
            width = 'full',
          },
          FillDirection = {
            type = 'select',
            name = 'Fill Direction',
            order = 11,
            hidden = function()
                       return BarType == 'ComboBar' or BarType == 'HolyBar' or
                              BarType == 'ShardBar' or BarType == 'EclipseBar'
                     end,
            values = DirectionDropdown,
            style = 'dropdown',
            arg = {'texture'},
          },
          RotateTexture = {
            type = 'toggle',
            name = 'Rotate Texture',
            order = 12,
            arg = {'texture'},
          },
          Spacer20 = {
            type = 'description',
            name = '',
            order = 20,
            width = 'full',
          },
          HapWidth = {
            type = 'range',
            name = 'Width',
            order = 21,
            desc = 'Values up to 500 can be typed in',
            min = HapBarWidthMin,
            max = HapBarWidthMax,
            softMax = HapBarWidthSoftMax,
            step = 1,
            arg = {'size'},
          },
          HapHeight = {
            type = 'range',
            name = 'Height',
            order = 22,
            desc = 'Values up to 500 can be typed in',
            min = HapBarHeightMin,
            max = HapBarHeightMax,
            softMax = HapBarHeightSoftMax,
            step = 1,
            arg = {'size'},
          },
          BoxWidth = {
            type = 'range',
            name = 'Width',
            order = 23,
            hidden = function()
                       return BarType ~= 'ComboBar' and BarType ~= 'HolyBar' and BarType ~= 'ShardBar'
                     end,
            desc = 'Changes the width of all the boxes',
            min = BoxBarWidthMin,
            max = BoxBarWidthMax,
            step = 1,
            arg = {'size'},
          },
          BoxHeight = {
            type = 'range',
            name = 'Height',
            order = 24,
            hidden = function()
                       return BarType ~= 'ComboBar' and BarType ~= 'HolyBar' and BarType ~= 'ShardBar'
                     end,
            desc = 'Changes the height of all the boxes',
            min = BoxBarHeightMin,
            max = BoxBarHeightMax,
            step = 1,
            arg = {'size'},
          },
          RuneWidth = {
            type = 'range',
            name = 'Width',
            order = 25,
            hidden = function()
                       return BarType ~= 'RuneBar'
                     end,
            desc = 'Changes the width of all the boxes',
            min = RuneBarWidthMin,
            max = RuneBarWidthMax,
            step = 1,
            arg = {'size'},
          },
          RuneHeight = {
            type = 'range',
            name = 'Height',
            order = 26,
            hidden = function()
                       return BarType ~= 'RuneBar'
                     end,
            desc = 'Changes the height of all the boxes',
            min = RuneBarHeightMin,
            max = RuneBarHeightMax,
            step = 1,
            arg = {'size'},
          },
          MoonWidth = {
            type = 'range',
            name = 'Width',
            order = 27,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'moon'
                     end,
            min = EclipseMoonWidthMin,
            max = EclipseMoonWidthMax,
            step = 1,
            arg = {'size'},
          },
          MoonHeight = {
            type = 'range',
            name = 'Height',
            order = 28,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'moon'
                     end,
            desc = 'Changes the height of moon',
            min = EclipseMoonHeightMin,
            max = EclipseMoonHeightMax,
            step = 1,
            arg = {'size'},
          },
          SunWidth = {
            type = 'range',
            name = 'Width',
            order = 29,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'sun'
                     end,
            min = EclipseSunWidthMin,
            max = EclipseSunWidthMax,
            step = 1,
            arg = {'size'},
          },
          SunHeight = {
            type = 'range',
            name = 'Height',
            order = 30,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'sun'
                     end,
            min = EclipseSunHeightMin,
            max = EclipseSunHeightMax,
            step = 1,
            arg = {'size'},
          },
          BarWidth = {
            type = 'range',
            name = 'Width',
            order = 31,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'bar'
                     end,
            min = EclipseBarWidthMin,
            max = EclipseBarWidthMax,
            step = 1,
            arg = {'size'},
          },
          BarHeight = {
            type = 'range',
            name = 'Height',
            order = 32,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'bar'
                     end,
            min = EclipseBarHeightMin,
            max = EclipseBarHeightMax,
            step = 1,
            arg = {'size'},
          },
          SliderWidth = {
            type = 'range',
            name = 'Width',
            order = 33,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'slider'
                     end,
            min = EclipseSliderWidthMin,
            max = EclipseSliderWidthMax,
            step = 1,
            arg = {'size'},
          },
          SliderHeight = {
            type = 'range',
            name = 'Height',
            order = 34,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'slider'
                     end,
            min = EclipseSliderHeightMin,
            max = EclipseSliderHeightMax,
            step = 1,
            arg = {'size'},
          },
          IndicatorWidth = {
            type = 'range',
            name = 'Width',
            order = 35,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'indicator'
                     end,
            min = EclipseSliderWidthMin,
            max = EclipseSliderWidthMax,
            step = 1,
            arg = {'size'},
          },
          IndicatorHeight = {
            type = 'range',
            name = 'Height',
            order = 36,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'indicator'
                     end,
            min = EclipseSliderHeightMin,
            max = EclipseSliderHeightMax,
            step = 1,
            arg = {'size'},
          },
          BarColor = {
            type = 'color',
            name = 'Color',
            order = 100,
            hidden = function()
                       return BarType == 'EclipseBar' and Object == 'bar'
                     end,
            hasAlpha = true,
            get = function()
                    local c = GetTable(BarType, 'Bar', TableName).Color
                    return c.r, c.g, c.b, c.a
                  end,
            set = function(Info, r, g, b, a)
                    local c = GetTable(BarType, 'Bar', TableName).Color
                    c.r, c.g, c.b, c.a = r, g, b, a
                    if Object then
                      UnitBarsF[BarType]:SetAttr('bar', 'color', Object)
                    else
                      UnitBarsF[BarType]:SetAttr('bar', 'color')
                    end

                    -- Update the bar for shared colors.
                    UnitBarsF[BarType]:Update()
                  end,
          },
          Spacer101 = {
            type = 'description',
            name = '',
            order = 101,
            width = 'full',
          },
          BarColorLunar = {
            type = 'color',
            name = 'Color (lunar)',
            order = 102,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'bar'
                     end,
            hasAlpha = true,
            get = function()
                    local c = GetTable(BarType, 'Bar', TableName).ColorLunar
                    return c.r, c.g, c.b, c.a
                  end,
            set = function(Info, r, g, b, a)
                    local c = GetTable(BarType, 'Bar', TableName).ColorLunar
                    c.r, c.g, c.b, c.a = r, g, b, a
                    UnitBarsF[BarType]:SetAttr('bar', 'color', 'bar')
                  end,
          },
          BarColorSolar = {
            type = 'color',
            name = 'Color (solar)',
            order = 103,
            hidden = function()
                       return BarType ~= 'EclipseBar' or Object ~= 'bar'
                     end,
            hasAlpha = true,
            get = function()
                    local c = GetTable(BarType, 'Bar', TableName).ColorSolar
                    return c.r, c.g, c.b, c.a
                  end,
            set = function(Info, r, g, b, a)
                    local c = GetTable(BarType, 'Bar', TableName).ColorSolar
                    c.r, c.g, c.b, c.a = r, g, b, a
                    UnitBarsF[BarType]:SetAttr('bar', 'color', 'bar')
                  end,
          },
        },
      },
      Padding = {
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
                  UnitBarsF[BarType]:SetAttr('bar', 'padding', Object)
                else
                  UnitBarsF[BarType]:SetAttr('bar', 'padding')
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
          Spacer = {
            type = 'description',
            name = '',
            order = 2,
            width = 'full',
          },
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
      },
    },
  }

  -- Add predicted color for Health bars only or for Player Power for hunters.
  if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' or
     BarType == 'PlayerPower' and PlayerClass == 'HUNTER' then
    BarOptions.args.PredictedColors = CreatePredictedColorOptions(BarType, 3, 'Predicted Color')
  end

  -- Add class colors for Player, Target, and Focus health bars only.
  if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' then

    -- Remove the BarColor options
    BarOptions.args.General.args.BarColor = nil

    -- Add the Power color options.
    BarOptions.args.ClassColors = CreateClassColorsOptions(BarType, 2, 'Color')
  end

  -- Add power colors for power bars only.
  if BarType == 'PlayerPower' or BarType == 'TargetPower' or BarType == 'FocusPower' or BarType == 'PetPower' or
     BarType == 'MainPower' then

    -- Remove the BarColor options
    BarOptions.args.General.args.BarColor = nil

    -- Add the Power color options.
    BarOptions.args.PowerColors = CreatePowerColorsOptions(BarType, 2, 'Power Color')
  end

  -- Add bar color options if its a combobar or shardbar. And remove HapWidth and HapHeight options.
  if BarType == 'RuneBar' or BarType == 'ComboBar' or BarType == 'HolyBar' or BarType == 'ShardBar' then
    BarOptions.args.General.args.BarColor = nil
    BarOptions.args.General.args.HapWidth = nil
    BarOptions.args.General.args.HapHeight = nil
    local MaxColors = 5
    if BarType == 'HolyBar' or BarType == 'ShardBar' then
      MaxColors = 3
    elseif BarType == 'RuneBar' then
      MaxColors = 8
    end
    BarOptions.args.BarColors = CreateColorAllOptions(BarType, 'bar', MaxColors, 2, 'Colors')
  end

  -- Remove health and power options for eclipse bar
  if BarType == 'EclipseBar' then
    BarOptions.args.General.args.HapWidth = nil
    BarOptions.args.General.args.HapHeight = nil

    -- Add color options for the slider bar
    if Object == 'slider' then
      BarOptions.args.General.args.BarColor = nil
      BarOptions.args.SliderColor = CreateEclipseColorOptions(BarType, 'bar', 'slider', 2, 'Color')
    end
    if Object == 'indicator' then
      BarOptions.args.General.args.BarColor = nil
      BarOptions.args.IndicatorColor = CreateEclipseColorOptions(BarType, 'bar', 'indicator', 2, 'Color')
    end
  end

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
  local HealthBar = string.find(BarType, 'Health')

  local HapBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UnitBars[BarType].General[Info[#Info]]
          end,
    set = function(Info, Value)
            UnitBars[BarType].General[Info[#Info]] = Value

            -- Update the bar to show changes.
            UnitBarsF[BarType]:Update()
          end,
    args = {
      PredictedHealth = {
        type = 'toggle',
        name = 'Predicted Health',
        order = 1,
        hidden = function()
                   return not HealthBar
                 end,
        desc = 'If checked, predicted health will be shown',
      },
      PredictedPower = {
        type = 'toggle',
        name = 'Predicted Power',
        order = 2,
        hidden = function()
                   return HealthBar
                 end,
        desc = 'If checked, predicted power will be shown',
      },
    },
  }

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
  local RuneBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UnitBars[BarType].General[Info[#Info]]
          end,
    set = function(Info, Value)
            UnitBars[BarType].General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UnitBarsF.RuneBar:SetLayout()
          end,
    args = {
      RuneMode  = {
        type = 'select',
        name = 'Rune Mode',
        order = 1,
        desc = 'Select the way runes are shown',
        values = RuneModeDropdown,
        style = 'dropdown',
      },
      BarMode = {
        type = 'toggle',
        name = 'Bar Mode',
        order = 2,
        desc = "If checked the runes can't be moved anywhere on the screen",
      },
      RuneSwap = {
        type = 'toggle',
        name = 'Swap Runes',
        order = 3,
        desc = 'Runes can be swapped by dragging a rune on another rune',
      },
      CooldownText = {
        type = 'toggle',
        name = 'Cooldown Text',
        order = 4,
        desc = 'Show cooldown text',
      },
      CooldownAnimation = {
        type = 'toggle',
        name = 'Cooldown Animation',
        order = 5,
        hidden = function()
                   return BarType == 'RuneBar' and strsub(UnitBars[BarType].General.RuneMode, 1, 4) ~= 'rune'
                 end,
        desc = 'Shows the cooldown animation',
      },
      HideCooldownFlash = {
        type = 'toggle',
        name = 'Hide Flash',
        order = 6,
        hidden = function()
                   return BarType == 'RuneBar' and strsub(UnitBars[BarType].General.RuneMode, 1, 4) ~= 'rune'
                 end,
        disabled = function()
                     return not UnitBars[BarType].General.CooldownAnimation
                   end,
        desc = 'Hides the flash animation after a rune comes off cooldown',
      },
      CooldownDrawEdge = {
        type = 'toggle',
        name = 'Draw Edge',
        order = 7,
        hidden = function()
                   return BarType == 'RuneBar' and strsub(UnitBars[BarType].General.RuneMode, 1, 4) ~= 'rune'
                 end,
        disabled = function()
                     return not UnitBars[BarType].General.CooldownAnimation
                   end,
        desc = 'Shows a line on the cooldown animation',
      },
      CooldownBarDrawEdge = {
        type = 'toggle',
        name = 'Bar Draw Edge',
        order = 8,
        hidden = function()
                   return BarType == 'RuneBar' and UnitBars[BarType].General.RuneMode == 'rune'
                 end,
        desc = 'Shows a line on the cooldown bar animation',
      },
      Spacer10 = {
        type = 'description',
        name = '',
        order = 10,
        width = 'full',
      },
      RuneLocation = {
        type = 'group',
        name = 'Rune Location',
        dialogInline = true,
        order = 11,
        hidden = function()
                   return UnitBars[BarType].General.RuneMode ~= 'runecooldownbar'
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
      BarModeAngle = {
        type = 'range',
        name = 'Rune Rotation',
        order = 12,
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
        order = 13,
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
        order = 14,
        hidden = function()
                   return BarType == 'RuneBar' and strsub(UnitBars[BarType].General.RuneMode, 1, 4) ~= 'rune'
                 end,
        desc = 'Change the size of all the runes',
        min = RuneBarSizeMin,
        max = RuneBarSizeMax,
        step = 1,
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
  local ComboBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UnitBars[BarType].General[Info[#Info]]
          end,
    set = function(Info, Value)
            UnitBars[BarType].General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UnitBarsF.ComboBar:SetLayout()
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
  local HolyBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UnitBars[BarType].General[Info[#Info]]
          end,
    set = function(Info, Value)
            UnitBars[BarType].General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UnitBarsF.HolyBar:SetLayout()

            if Info[#Info] == 'BoxMode' then

              -- Set the scripts since we changed modes.
              UnitBarsF[BarType]:FrameSetScript(true)
            end
          end,
    args = {
      BoxMode = {
        type = 'toggle',
        name = 'Box Mode',
        order = 1,
        desc = 'If checked this bar will show boxes instead of textures',
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
                   return UnitBars[BarType].General.BoxMode
                 end,
        desc = 'Sets the size of all the holy power runes',
        min = HolyBarSizeMin,
        max = HolyBarSizeMax,
        step = 1,
      },
      HolyScale = {
        type = 'range',
        name = 'Holy Scale',
        order = 5,
        hidden = function()
                   return UnitBars[BarType].General.BoxMode
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
  local ShardBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UnitBars[BarType].General[Info[#Info]]
          end,
    set = function(Info, Value)
            UnitBars[BarType].General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UnitBarsF.ShardBar:SetLayout()
            if Info[#Info] == 'BoxMode' then

              -- Set the scripts since we changed modes.
              UnitBarsF[BarType]:FrameSetScript(true)
            end
          end,
    args = {
      BoxMode = {
        type = 'toggle',
        name = 'Box Mode',
        order = 1,
        desc = 'If checked this bar will show boxes instead of textures',
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
                   return UnitBars[BarType].General.BoxMode
                 end,
        desc = 'Sets the size of all the soul shards',
        min = ShardBarSizeMin,
        max = ShardBarSizeMax,
        step = 1,
      },
      ShardScale = {
        type = 'range',
        name = 'Shard Scale',
        order = 5,
        hidden = function()
                   return UnitBars[BarType].General.BoxMode
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
  local EclipseBarOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UnitBars[BarType].General[Info[#Info]]
          end,
    set = function(Info, Value)
            UnitBars[BarType].General[Info[#Info]] = Value

            -- Update the layout to show changes.
            UnitBarsF.EclipseBar:SetLayout()

            -- Update the bar
            UnitBarsF.EclipseBar:Update()
          end,
    args = {
      SliderInside = {
        type = 'toggle',
        name = 'Slider Inside',
        order = 1,
        desc = 'If checked the slider will stay inside the bar',
      },
      BarHalfLit = {
        type = 'toggle',
        name = 'Bar Half Lit',
        order = 2,
        desc = 'If checked half the bar becomes lit to show the slider direction',
      },
      PowerText = {
        type = 'toggle',
        name = 'Power Text',
        order = 3,
        desc = 'If checked then eclipse power text will be shown',
      },
      PredictedPower = {
        type = 'toggle',
        name = 'Predicted Power',
        order = 4,
        desc = 'If checked, the energy from wrath, starfire and starsurge will be shown ahead of time',
      },
      Spacer10 = {
        type = 'description',
        name = '',
        order = 10,
        width = 'full',
      },
      PredictedOptions = {
        type = 'group',
        name = 'Predicted Options',
        dialogInline = true,
        order = 11,
        hidden = function()
                   return not UnitBars[BarType].General.PredictedPower
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
          Spacer10 = {
            type = 'description',
            name = '',
            order = 10,
            width = 'full',
          },
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
      Spacer20 = {
        type = 'description',
        name = '',
        order = 20,
        width = 'full',
      },
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
      Spacer30 = {
        type = 'description',
        name = '',
        order = 30,
        width = 'full',
      },
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
    },
  }
  return EclipseBarOptions
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
  local UnitBarOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {
-------------------------------------------------------------------------------
--    Status
-------------------------------------------------------------------------------
      Status = {
        type = 'group',
        name = 'Status',
        dialogInline = true,
        order = 1,
        get = function(Info)
                return UnitBars[BarType].Status[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[BarType].Status[Info[#Info]] = Value

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
          HideWhenDead = {
            type = 'toggle',
            name = 'Hide when Dead',
            order = 2,
            desc = "Hides the bar when you're dead",
          },
          HideInVehicle = {
            type = 'toggle',
            name = 'Hide in Vehicle',
            order = 3,
            desc = "Hides the bar when your're in a vehicle",
          },
          ShowAlways = {
            type = 'toggle',
            name = 'Show Always',
            order = 4,
            desc = 'Bar will always be shown',
          },
          HideNotActive = {
            type = 'toggle',
            name = 'Hide not Active',
            order = 5,
            hidden  = function()
                        return BarType == 'RuneBar'
                      end,
            desc = 'Bar will be hidden if its not active. This only gets checked out of combat',
          },
          HideNoCombat = {
            type = 'toggle',
            name = 'Hide no Combat',
            order = 6,
            desc = 'When not in combat the bar will be hidden',
          },
        },
      },
      Other = {
        type = 'group',
        name = 'Other',
        dialogInline = true,
        order = 100,
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
                    return UnitBars[BarType].Other.Scale
            end,
            set = function(Info, Value)
                    UnitBars[BarType].Other.Scale = Value
                    UnitBarsF[BarType]:SetAttr('frame', 'scale')
                  end,
            step = 0.01,
            isPercent  = true,
          },
          Spacer = {
            type = 'description',
            name = '',
            order = 2,
            width = 'full',
          },
          Reset = {
            type = 'execute',
            name = 'Reset Defaults',
            order = 3,
            desc = "Sets the bar to its default values. Location doesn't get changed",
            confirm = true,
            func = function()

                     -- Preserve bar location
                     local UB = UnitBars[BarType]
                     local x, y =  UB.x, UB.y

                     Main:CopyTableValues(Defaults.profile[BarType], UB)

                     UB.x, UB.y = x, y

                     -- Update the layout.
                     UnitBarsF[BarType]:SetLayout()
                     UnitBarsF[BarType]:Update()
                   end,
          },
          ResetPosition = {
            type = 'execute',
            name = 'Reset Location',
            order = 4,
            desc = "Sets the bar to its default location",
            confirm = true,
            func = function()

                     -- Get the anchor and default bar location.
                     local Anchor = UnitBarsF[BarType].Anchor
                     local UBd = Defaults.profile[BarType]
                     local UB = UnitBars[BarType]
                     local x, y = UBd.x, UBd.y

                     -- Save the defalt location.
                     UB.x, UB.y = x, y

                     -- Set the bar location on screen.
                     Anchor:ClearAllPoints()
                     Anchor:SetPoint('TOPLEFT' , x, y)
                   end,
          },
        },
      },
    },
  }

  -- Add description if not nil.
  if Desc then
    UnitBarOptions.desc = Desc
  end

  local UBO = UnitBarOptions.args

  -- Add bar options for eclipse bar
  if BarType == 'EclipseBar' then
    UBO.Background = {
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
    UBO.Bar = {
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
    UBO.Background = CreateBackgroundOptions(BarType, nil, 1000, 'Background')

    -- add bar options for this bar.
    UBO.Bar = CreateBarOptions(BarType, nil, 1001, 'Bar')
  end

  -- Add text options
  if BarType ~= 'ComboBar' and BarType ~= 'HolyBar' and BarType ~= 'ShardBar' then
    UBO.Text = CreateTextOptions(BarType, 'text', 1002, 'Text')
    if BarType ~= 'RuneBar' and BarType ~= 'EclipseBar' then
      UBO.Text2 = CreateTextOptions(BarType, 'text2', 1003, 'Text2')
    end
  end

  -- Add runebar options
  if BarType == 'RuneBar' then
    UBO.RuneBar = CreateRuneBarOptions(BarType, 3, 'General')

  -- Add combobar options
  elseif BarType == 'ComboBar' then
    UBO.ComboBar =  CreateComboBarOptions(BarType, 4, 'General')

  -- Add holybar options
  elseif BarType == 'HolyBar' then
    UBO.HolyBar = CreateHolyBarOptions(BarType, 5, 'General')

  -- Add shardbar options
  elseif BarType == 'ShardBar' then
    UBO.ShardBar = CreateShardBarOptions(BarType, 6, 'General')

  -- Add eclipsebar options
  elseif BarType == 'EclipseBar' then
    UBO.EclipseBar = CreateEclipseBarOptions(BarType, 7, 'General')

  -- Add health and power bar options
  elseif BarType == 'PlayerPower' and PlayerClass == 'HUNTER' or string.find(BarType, 'Power') == nil and BarType ~= 'PetHealth' then
    UBO.HapBar = CreateHapBarOptions(BarType, 8, 'General')
  end

  return UnitBarOptions
end

-------------------------------------------------------------------------------
-- CreateCopySettingsOptions
--
-- Creates an options table for copying options from other bars.
--
-- Subfunction of CreateMainOptions()
--
-- Usage: CopyOptions = CreateCopySettingsOptions(Order, Name)
--
-- Order            Order number for the options.
-- Name             Name for the option to appear in the tree.
--
-- CopyOptions      Options table for a specific unitbar.
-------------------------------------------------------------------------------
local function CreateCopySettingsOptions(Order, Name)
  local CopySettingsFrom = nil
  local CopySettingsTo = nil

  local CopySettingsHidden = {}
  local CopySettings = {
    All = false,
    Status = false,
    General = false,
    Background = false,
    Bar = false,
    Text = false,
    Text2 = false,
  }

  local CopySettingsOptions = {
    type = 'group',
    name = Name,
    desc = 'Copy settings from one bar to another',
    order = Order,
    args = {
      CopyFrom = {
        type = 'select',
        name = 'Copy Settings from',
        order = 1,
        desc = 'Pick the bar to copy the settings from',
        values = UnitBarsSelectDropdown,
        style = 'dropdown',
        get = function()
                return CopySettingsFrom
              end,
        set = function(Info, Value)
                CopySettingsFrom = Value
              end,
      },
      CopyTo = {
        type = 'select',
        name = 'To',
        order = 2,
        disabled = function()
                     return CopySettingsFrom == nil
                   end,
        desc = 'Pick the bar to copy the settings to',
        values = UnitBarsSelectDropdown,
        style = 'dropdown',
        get = function()
                return CopySettingsTo
              end,
        set = function(Info, Value)
                CopySettingsTo = Value
                Key = Info[#Info]
              end,
      },
      Settings = {
        type = 'group',
        name = 'Settings to copy',
        dialogInline = true,
        order = 3,
        disabled = function()
                     return CopySettingsFrom == nil or CopySettingsTo == nil or
                            CopySettingsFrom == CopySettingsTo
                   end,
        get = function(Info)
                return CopySettings[Info[#Info]]
              end,
        set = function(Info, Value)
                CopySettings[Info[#Info]] = Value
                return
              end,
        args = {
          All = {
            type = 'toggle',
            name = 'All',
            order = 1,
            desc = 'Copy all the settings. Uncheck to pick certain settings',
          },
          Status = {
            type = 'toggle',
            name = 'Status',
            order = 2,
            hidden = function(Info)
                       CopySettingsHidden[Info[#Info]] = CopySettings.All
                       return CopySettings.All
                     end,
            desc = 'Copy the status settings',
          },
          General = {
            type = 'toggle',
            name = 'General',
            order = 3,
            hidden = function(Info)

                       -- General no longers needs to be copied.
                       return true
                     end,
            desc = 'Copy the general settings',
          },
          Other = {
            type = 'toggle',
            name = 'Other',
            order = 4,
            hidden = function(Info)
                       local Value = CopySettings.All
                       CopySettingsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = 'Copy the other settings',
          },
          Background = {
            type = 'toggle',
            name = 'Background',
            order = 5,
            hidden = function(Info)
                       local Value = CopySettings.All or
                         CopySettingsFrom == 'EclipseBar' or CopySettingsTo == 'EclipseBar'
                       CopySettingsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = 'Copy the background settings',
          },
          Bar = {
            type = 'toggle',
            name = 'Bar',
            order = 6,
            hidden = function(Info)
                       local Value = CopySettings.All or
                               CopySettingsFrom == 'EclipseBar' or CopySettingsTo == 'EclipseBar'
                       CopySettingsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = 'Copy the bar settings'
          },
          Text = {
            type = 'toggle',
            name = 'Text',
            order = 7,
            hidden = function(Info)
                       local Value = CopySettings.All or
                               CopySettingsFrom == 'ComboBar' or CopySettingsFrom == 'HolyBar' or CopySettingsFrom == 'ShardBar' or
                               CopySettingsTo == 'ComboBar' or CopySettingsTo == 'HolyBar' or CopySettingsTo == 'ShardBar'
                       CopySettingsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = 'Copy the text settings',
          },
          Text2 = {
            type = 'toggle',
            name = 'Text2',
            order = 7,
            hidden = function(Info)
                       local Value = CopySettings.All or
                               CopySettingsFrom == 'ComboBar' or CopySettingsFrom == 'HolyBar' or CopySettingsFrom == 'RuneBar' or CopySettingsFrom == 'ShardBar' or CopySettingsFrom == 'EclipseBar' or
                               CopySettingsTo == 'ComboBar' or CopySettingsTo == 'HolyBar' or CopySettingsTo == 'RuneBar' or CopySettingsTo == 'ShardBar' or CopySettingsTo == 'EclipseBar'
                       CopySettingsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = 'Copy the text2 settings',
          },
        },
      },
      Copy = {
        type = 'execute',
        name = 'Copy Settings',
        order = 100,
        disabled = function()
                     return CopySettingsFrom == nil or CopySettingsTo == nil or
                            CopySettingsFrom == CopySettingsTo or
                            not ListChecked(CopySettings, CopySettingsHidden)
                   end,
        confirm = function()
                    return ('Copy settings from %s to %s ?'):format(UnitBars[CopySettingsFrom].Name, UnitBars[CopySettingsTo].Name)
                  end,
        func = function()
                 local Source = UnitBars[CopySettingsFrom]
                 local Dest = UnitBars[CopySettingsTo]

                 -- Preserve name and location.
                 local Name = Dest.Name
                 local x, y = Dest.x, Dest.y

                 if CopySettings.All then
                   Main:CopyTableValues(Source, Dest)
                 else
                   if CopySettings.Status and not CopySettingsHidden.Status then
                     Main:CopyTableValues(Source.Status, Dest.Status)
                   end
                   if CopySettings.General and not CopySettingsHidden.General then
                     Main:CopyTableValues(Source.General, Dest.General)
                   end
                   if CopySettings.Other and not CopySettingsHidden.Other then
                     Main:CopyTableValues(Source.Other, Dest.Other)
                   end
                   if CopySettings.Background and not CopySettingsHidden.Background then
                     Main:CopyTableValues(Source.Background, Dest.Background)
                   end
                   if CopySettings.Bar and not CopySettingsHidden.Bar then
                     Main:CopyTableValues(Source.Bar, Dest.Bar)
                   end
                   if CopySettings.Text and not CopySettingsHidden.Text then
                     Main:CopyTableValues(Source.Text, Dest.Text)
                   end
                   if CopySettings.Text2 and not CopySettingsHidden.Text2 then
                     Main:CopyTableValues(Source.Text2, Dest.Text2)
                   end
                 end

                 -- Restore name and location.
                 Dest.Name = Name
                 Dest.x, Dest.y = x, y

                 -- Update unitbar with the new values.
                 UnitBarsF[CopySettingsTo]:SetAttr(nil, nil)
                 UnitBarsF[CopySettingsTo]:Update()
               end,
      },
    },
  }
  return CopySettingsOptions
end

-------------------------------------------------------------------------------
-- CreateAlignUnitBarsOptions
--
-- Create alignment options that allow you to line up bars with other bars.
--
-- Subfunction of CreateMainOptions()
--
-- Usage: AlignOptions = CreateAlignUnitBarsOptions(Order, Name)
--
-- Order            Order number for the options.
-- Name             Name for the option to appear in the tree.
--
-- AlignOptions     Options table for alignment.
--
-- NOTES:
-- BarsHidden[BarType]    If true then that bar can't be checked off.
--                        If false then then that bar can be checked off.
-- BarsChecked[BarType]   If true then that bar has been checked off.
--                        If false then thatb bar hasn't been checked off.
--
-- To build the BarsToAlign list:
-- If the bartype is not hidden then BarsToAlign[BarType] is set
-- to the true/false value found in BarsChecked.  If the bartype is hidden
-- then BarsToAlign[BarType] is set to false.
-------------------------------------------------------------------------------
local function CreateAlignUnitBarsOptions(Order, Name)
  local AlignmentType = 'vertical'
  local Padding = 0
  local PadEnabled = false

  local AlignmentBar = nil
  local AlignmentBarName = nil
  local ARealTime = false

  -- List of bars to align.
  local BarsToAlign = {}

  -- List of bars for the check boxes.
  local BarsChecked = {}
  local BarsHidden = {}

  local Alignment = {
    vertical = 'left',
    horizontal = 'top'
  }

  -- Function inside of a function.  But yeah I didn't want to call this huge thing in 4 different places.
  local function AlignBars()
    Main:AlignUnitBars(AlignmentBar, BarsToAlign, AlignmentType, Alignment[AlignmentType], PadEnabled, Padding)
  end

  local AlignOptions = {
    type = 'group',
    name = Name,
    desc = 'Align one or more bars with another',
    order = Order,
    args = {
      AlignmentBar = {
        type = 'select',
        name = 'Align Bars with',
        order = 1,
        desc = 'Pick the bar to align other bars with',
        values = UnitBarsSelectDropdown,
        style = 'dropdown',
        get = function()
                return AlignmentBar
              end,
        set = function(Info, Value)
                AlignmentBar = Value
                AlignmentBarName = UnitBars[AlignmentBar].Name
                ARealTime = false
              end,
      },
      AlignBars = {
        type = 'group',
        name = 'Bars to Align',
        dialogInline = true,
        order = 2,
        disabled = function()
                     return AlignmentBar == nil
                   end,
        get = function(Info)
                return BarsChecked[Info[#Info]]
              end,
        set = function(Info, Value)
                BarsChecked[Info[#Info]] = Value
                ARealTime = false
              end,
        args = {
          PlayerHealth = {
            type = 'toggle',
            name = 'Player Health',
            order = 1,
            hidden = function(Info)
                       local Value = AlignmentBar == 'PlayerHealth'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Player Health with %s'):format(AlignmentBarName)
                   end
          },
          PlayerPower = {
            type = 'toggle',
            name = 'Player Power',
            order = 2,
            hidden = function(Info)
                       local Value = AlignmentBar == 'PlayerPower'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Player Power with %s'):format(AlignmentBarName)
                   end
          },
          TargetHealth = {
            type = 'toggle',
            name = 'Target Health',
            order = 3,
            hidden = function(Info)
                       local Value = AlignmentBar == 'TargetHealth'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Target Health with %s'):format(AlignmentBarName)
                   end
          },
          TargetPower = {
            type = 'toggle',
            name = 'Target Power',
            order = 4,
            hidden = function(Info)
                       local Value = AlignmentBar == 'TargetPower'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Target Power with %s'):format(AlignmentBarName)
                   end
          },
          FocusHealth = {
            type = 'toggle',
            name = 'Focus Health',
            order = 5,
            hidden = function(Info)
                       local Value = AlignmentBar == 'FocusHealth'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Focus Health with %s'):format(AlignmentBarName)
                   end
          },
          FocusPower = {
            type = 'toggle',
            name = 'Focus Power',
            order = 6,
            hidden = function(Info)
                       local Value = AlignmentBar == 'FocusPower'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Focus Power with %s'):format(AlignmentBarName)
                   end
          },
          PetHealth = {
            type = 'toggle',
            name = 'Pet Health',
            order = 7,
            hidden = function(Info)
                       local Value = AlignmentBar == 'PetHealth'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Pet Health with %s'):format(AlignmentBarName)
                   end
          },
          PetPower = {
            type = 'toggle',
            name = 'Pet Power',
            order = 8,
            hidden = function(Info)
                       local Value = AlignmentBar == 'PetPower'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Pet Power with %s'):format(AlignmentBarName)
                   end
          },
          MainPower = {
            type = 'toggle',
            name = 'Main Power',
            order = 9,
            hidden = function(Info)
                       local Value = AlignmentBar == 'MainPower'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Main Power with %s'):format(AlignmentBarName)
                   end
          },
          RuneBar = {
            type = 'toggle',
            name = 'Rune Bar',
            order = 10,
            hidden = function(Info)
                       local Value = AlignmentBar == 'RuneBar'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Rune Bar with %s'):format(AlignmentBarName)
                   end
          },
          ComboBar = {
            type = 'toggle',
            name = 'Combo Bar',
            order = 11,
            hidden = function(Info)
                       local Value = AlignmentBar == 'ComboBar'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Combo Bar with %s'):format(AlignmentBarName)
                   end
          },
          HolyBar = {
            type = 'toggle',
            name = 'Holy Bar',
            order = 12,
            hidden = function(Info)
                       local Value = AlignmentBar == 'HolyBar'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Combo Bar with %s'):format(AlignmentBarName)
                   end
          },
          ShardBar = {
            type = 'toggle',
            name = 'Shard Bar',
            order = 13,
            hidden = function(Info)
                       local Value = AlignmentBar == 'ShardBar'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Shard Bar with %s'):format(AlignmentBarName)
                   end
          },
          EclipseBar = {
            type = 'toggle',
            name = 'Eclipse Bar',
            order = 14,
            hidden = function(Info)
                       local Value = AlignmentBar == 'EclipseBar'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return ('Align Eclipse Bar with %s'):format(AlignmentBarName)
                   end
          },
        },
      },
      AlignmentSettings = {
        type = 'group',
        name = 'Alignment Settings',
        dialogInline = true,
        order = 3,
        disabled = function()
                     return not ListChecked(BarsChecked, BarsHidden)
                   end,
        args = {
          AlignmentType = {
            type = 'select',
            name = 'Type of Alignment',
            order = 1,
            desc = 'Align bars vertically or horizontally',
            values = AlignmentTypeDropdown,
            get = function()
                    return AlignmentType
                  end,
            set = function(Info, Value)
                    AlignmentType = Value
                    if ARealTime then
                      AlignBars()
                    end
                  end,
          },
          Alignment = {
            type = 'select',
            name = 'Alignment',
            order = 2,
            desc = 'Align each bar to the left or right',
            values = function()
                       return AlignBarsDropdown[AlignmentType]
                     end,
            style = 'dropdown',
            get = function()
                    return Alignment[AlignmentType]
                  end,
            set = function(Info, Value)
                    Alignment[AlignmentType] = Value
                    if ARealTime then
                      AlignBars()
                    end
                  end,
          },
          PadEnabled = {
            type = 'toggle',
            name = 'Enable Padding',
            order = 3,
            get = function()
                    return PadEnabled
                  end,
            set = function(Info, Value)
                    PadEnabled = Value
                  end,
          },
          Padding = {
            type = 'range',
            name = 'Padding',
            order = 4,
            disabled = function()
                         return not PadEnabled
                       end,
            desc = 'The amount of padding between bars',
            min = AlignmentPaddingMin,
            max = AlignmentPaddingMax,
            step = 1,
            get = function()
                    return Padding
                  end,
            set = function(Info, Value)
                    Padding = Value
                    if ARealTime then
                      AlignBars()
                    end
                  end,
          },
        },
      },
      Align = {
        type = 'execute',
        name = 'Align',
        order = 100,
        desc = function()
                 if AlignmentBarName then
                   return ('Align with %s. Once clicked Alignment Settings can be changed without having to click this button'):format(AlignmentBarName)
                 else
                   return 'Align'
                 end
               end,
        disabled = function()
                     return not ListChecked(BarsChecked, BarsHidden)
                   end,
        func = function()
                 for BarType, Hidden in pairs(BarsHidden) do
                   if not Hidden then
                     BarsToAlign[BarType] = BarsChecked[BarType]
                   else
                     BarsToAlign[BarType] = false
                   end
                 end
                   AlignBars()

                 --Allow real time ajustments for Vertical Padding and alignement
                 ARealTime = true
               end,
      },
    },
  }
  return AlignOptions
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
          FadeOutTime = {
            type = 'range',
            name = 'Fadeout Time',
            order = 6,
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

          -- Holybar group.
          ShardBar = CreateUnitBarOptions('ShardBar', 13, 'Shard Bar'),

          -- Eclipsebar group.
          EclipseBar = CreateUnitBarOptions('EclipseBar', 14, 'Eclipse Bar', 'Balance Druids only: Shown when in moonkin form or normal form'),
        },
      },
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
          CopySettings = CreateCopySettingsOptions(1, 'Copy Settings'),
          AlignBars = CreateAlignUnitBarsOptions(2, 'Align Bars'),
        },
      },
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
                     return ('|cffffd200%s   version %s|r'):format(AddonName, AddonVersion)
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
--  ProfilesOptionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(AddonProfileName, 'Profiles', AddonName)
end
