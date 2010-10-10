--
-- Options.lua
--
-- Handles all the options for GalvinUnitBars.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.Options = {}

local LSM = GUB.UnitBars.LSM
local UnitBarsF = GUB.UnitBars.UnitBarsF
local Defaults = GUB.UnitBars.Defaults
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
-- FontHAlignDropDown            Table used for the dialog drop down for font horizontal alignment.
-- TextTypeDropdown              Table used for the dialog drop down for Healh and power text type.
-- UnitBarsSelectDropdown        Table used to pick from a list of unitbars.
-- AlignmentBarsDropdown            Table used for horizontal alignment dropdown.
-------------------------------------------------------------------------------

-- Addon Constants
local AddonName = GetAddOnMetadata(MyAddon, "Title")
local AddonVersion = GetAddOnMetadata(MyAddon, "Version")
local AddonOptionsName = MyAddon .. 'options'
local AddonProfileName = MyAddon .. 'profile'
local AddonSlashName = MyAddon .. 'slash'

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

local ComboBarPaddingMin = -10
local ComboBarPaddingMax = 50
local ComboBarAngleMin = 45
local ComboBarAngleMax = 360
local ComboBarWidthMin = 10
local ComboBarWidthMax = 100
local ComboBarHeightMin = 10
local ComboBarHeightMax = 100

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

local AlignmentPaddingMin = -10
local AlignmentPaddingMax = 50

local FontStyleDropdown = {
  NONE = "None",
  OUTLINE = "Outline",
  THICKOUTLINE = "Thick Outline",
  ["NONE, MONOCHROME"] = "No Outline, Mono",
  ["OUTLINE, MONOCHROME"] = "Outline, Mono",
  ["THICKOUTLINE, MONOCHROME"] = "Thick Outline, Mono",
}

local FontHAlignDropdown = {
  LEFT = 'Left',
  CENTER = 'Center',
  RIGHT = 'Right'
}

local FontPositionDropdown = {
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

local TextTypeDropdown = {
  none = 'No value',
  percent = 'Percentage',
  max = 'Value / Max Value',
  whole = 'Whole',
  maxpercent = 'Max and Percentage',
  wholepercent = 'Whole and Percentage'
}

local UnitBarsSelectDropdown = {
  PlayerHealth = Defaults.profile.PlayerHealth.Name,
  PlayerPower = Defaults.profile.PlayerPower.Name,
  TargetHealth = Defaults.profile.TargetHealth.Name,
  TargetPower = Defaults.profile.TargetPower.Name,
  MainPower = Defaults.profile.MainPower.Name,
  RuneBar = Defaults.profile.RuneBar.Name,
  ComboBar = Defaults.profile.ComboBar.Name,
  HolyBar = Defaults.profile.HolyBar.Name
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

local BarFillDirectionDropdown = {
  HORIZONTAL = 'Horizontal',
  VERTICAL = 'Vertical'
}

--local BarTileDropdown = {

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
-- Usage SendOptionsData(UB, PC, PPT)
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
                  -- HideUIPanel(GameMenuFrame)
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
-- Creates all color options for background and bar. That support multiple colors.
--
-- Subfunction of CreateBackgroundOptions()
-- Subfunction of CreateBarOptions()
-- Subfunction of CreateTextOptions()
--
-- Usage: ColorAllOptions = (BarType, Object, MaxColors, Order, Name)
--
-- BarType       Type of options being created.
-- Object        Can be 'bg', 'bar', or 'text'
-- MaxColors     Maximum number of colors can be 5 or 6.
-- Order         Order number.
-- Name          Name text
--
-- ColorAllOptions  Options table for the Combobar.
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
      Color1 = {
        type = 'color',
        name = function()
                 return ColorAllNames[1]
               end,
        order = 3,
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
        order = 4,
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
        order = 5,
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
        order = 6,
        hasAlpha = true,
        hidden = function()
                   return UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {4},
      },
      Color5 = {
        type = 'color',
        name = function()
                 return ColorAllNames[5]
               end,
        order = 7,
        hasAlpha = true,
        hidden = function()
                   return UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {5},
      },
      Color6 = {
        type = 'color',
        name = function()
                 return ColorAllNames[6]
               end,
        order = 8,
        hasAlpha = true,
        hidden = function()
                   return MaxColors < 6 or UnitBars[BarType][UnitBarTable].ColorAll
                 end,
        hasAlpha = true,
        arg = {6},
      },
    },
  }
  return ColorAllOptions
end

-------------------------------------------------------------------------------
-- CreateBackgroundOptions
--
-- Creates background options for a unitbar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: BackgroundOptions = CreateBackgroundOptions(BarType, Order, Name)
--
-- BarType               Type options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- BackgroundOptions     Options table for background options.
-------------------------------------------------------------------------------
local function CreateBackgroundOptions(BarType, Order, Name)
  local BackgroundOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {
      Textures = {
        type = 'group',
        name = 'Textures',
        dialogInline = true,
        order = 1,
        get = function(Info)
                return UnitBars[BarType].Background.BackdropSettings[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[BarType].Background.BackdropSettings[Info[#Info]] = Value
                UnitBarsF[BarType]:SetAttr('bg', 'backdrop')
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
          BdTile = {
            type = 'toggle',
            name = 'Tile Background',
            order = 3,
          },
          BdTileSize = {
            type = 'range',
            name = 'Background Tile Size',
            order = 4,
            disabled = function()
                         return not UnitBars[BarType].Background.BackdropSettings.BdTile
                       end,
            min = UnitBarBgTileSizeMin,
            max = UnitBarBgTileSizeMax,
            step = 1,
          },
          BdSize = {
            type = 'range',
            name = 'Border Thickness',
            order = 5,
            min = UnitBarBorderSizeMin,
            max = UnitBarBorderSizeMax,
            step = 2,
          },
          BgColor = {
            type = 'color',
            name = 'Background Color',
            order = 6,
            hasAlpha = true,
            get = function()
                    local c = UnitBars[BarType].Background.Color
                    return c.r, c.g, c.b, c.a
                  end,
            set = function(Info, r, g, b, a)
                    local c = UnitBars[BarType].Background.Color
                    c.r, c.g, c.b, c.a = r, g, b, a
                    UnitBarsF[BarType]:SetAttr('bg', 'color')
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
                return UnitBars[BarType].Background.BackdropSettings.Padding[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[BarType].Background.BackdropSettings.Padding[Info[#Info]] = Value
                UnitBarsF[BarType]:SetAttr('bg', 'backdrop')
              end,
        args = {
          Left = {
          type = 'range',
            name = 'Left',
            order = 1,
            min = UnitBarPaddingMin,
            max = UnitBarPaddingMax,
            step = 1,
          },
          Right = {
            type = 'range',
            name = 'Right',
            order = 2,
            min = UnitBarPaddingMin,
            max = UnitBarPaddingMax,
            step = 1,
          },
          Top = {
            type = 'range',
            name = 'Top',
            order = 3,
            min = UnitBarPaddingMin,
            max = UnitBarPaddingMax,
            step = 1,
          },
          Bottom = {
            type = 'range',
            name = 'Bottom',
            order = 4,
            min = UnitBarPaddingMin,
            max = UnitBarPaddingMax,
            step = 1,
          },
        },
      },
    },
  }

  -- Remove the Background color options and add a Combo Color options for combobar only.
  if BarType == 'ComboBar' then
    BackgroundOptions.args.Textures.args.BgColor = nil
    BackgroundOptions.args.ComboColors = CreateColorAllOptions(BarType, 'bg', 5, 2, 'Colors')
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
-- Usage: TextOptions CreateTextOptions(BarType, Order, Name)
--
-- BarType               Type options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- TextOptions     Options table for background options.
-------------------------------------------------------------------------------
local function CreateTextOptions(BarType, Order, Name)
  local TextOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {
      Font = {
        type = 'group',
        name = 'Font',
        dialogInline = true,
        order = 1,
        get = function(Info)
                return UnitBars[BarType].Text.FontSettings[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[BarType].Text.FontSettings[Info[#Info]] = Value
                UnitBarsF[BarType]:SetAttr('text', 'font')
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
            values = FontPositionDropdown,
          },
          TextColor = {
            type = 'color',
            name = 'Color',
            order = 7,
            hasAlpha = true,
            get = function()
                    local c = UnitBars[BarType].Text.Color
                    return c.r, c.g, c.b, c.a
                  end,
            set = function(Info, r, g, b, a)
                    local c = UnitBars[BarType].Text.Color
                    c.r, c.g, c.b, c.a = r, g, b, a
                    UnitBarsF[BarType]:SetAttr('text', 'color')
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
                return UnitBars[BarType].Text.FontSettings[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[BarType].Text.FontSettings[Info[#Info]] = Value
                UnitBarsF[BarType]:SetAttr('text', 'font')
              end,
        args = {
          OffsetX = {
            type = 'range',
            name = 'Horizonal',
            order = 1,
            min = FontOffsetXMin,
            max = FontOffsetXMax,
            step = 1,
          },
          OffsetY = {
            type = 'range',
            name = 'Vertical',
            order = 2,
            min = FontOffsetYMin,
            max = FontOffsetYMax,
            step = 1,
          },
          ShadowOffset = {
            type = 'range',
            name = 'Shadow',
            order = 3,
            min = FontShadowOffsetMin,
            max = FontShadowOffsetMax,
            step = 1,
          },
        },
      },
    },
  }

  -- Remove the text color options and add a text Color options for runebar only.
  if BarType == 'RuneBar' then
    TextOptions.args.Font.args.TextColor = nil
    TextOptions.args.TextColors = CreateColorAllOptions(BarType, 'text', 6, 2, 'Colors')
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
        hasAlpha = true,
        arg = {0},
      },
      RageColor = {
        type = 'color',
        name = 'Rage',
        order = 2,
        hasAlpha = true,
        arg = {1},
      },
      FocusColor = {
        type = 'color',
        name = 'Focus',
        order = 3,
        hasAlpha = true,
        arg = {2},
      },
      EnergyColor = {
        type = 'color',
        name = 'Energy',
        order = 4,
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
-- CreateBarOptions
--
-- Creates bar options for a unitbar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: BarOptions = CreateBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- BarOptions            Options table for the unitbar.
-------------------------------------------------------------------------------
local function CreateBarOptions(BarType, Order, Name)
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
                return UnitBars[BarType].Bar[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[BarType].Bar[Info[#Info]] = Value

                -- Update combobar layout if its a combobar.
                if BarType == 'ComboBar' then
                  GUB.ComboBar:SetComboBarLayout(UnitBarsF.ComboBar)
                else
                  UnitBarsF[BarType]:SetAttr('bar', Info.arg[1])
                end
              end,
        args = {
          StatusBarTexture = {
            type = 'select',
            name = 'Bar Texture',
            order = 1,
            dialogControl = 'LSM30_Statusbar',
            values = LSM:HashTable('statusbar'),
            arg = {'texture'},
          },
          FillDirection = {
            type = 'select',
            name = 'Fill Direction',
            order = 2,
            values = BarFillDirectionDropdown,
            style = 'dropdown',
            arg = {'texture'},
          },
          RotateTexture = {
            type = 'toggle',
            name = 'Rotate Texture',
            order = 3,
            arg = {'texture'},
          },
          HapWidth = {
            type = 'range',
            name = 'Width',
            order = 6,
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
            order = 7,
            desc = 'Values up to 500 can be typed in',
            min = HapBarHeightMin,
            max = HapBarHeightMax,
            softMax = HapBarHeightSoftMax,
            step = 1,
            arg = {'size'},
          },
          ComboWidth = {
            type = 'range',
            name = 'Width',
            order = 8,
            desc = 'Changes the width of all the combo boxes',
            min = ComboBarWidthMin,
            max = ComboBarWidthMax,
            step = 1,
            arg = {'size'},
          },
          ComboHeight = {
            type = 'range',
            name = 'Height',
            order =9,
            desc = 'Changes the height of all the combo boxes',
            min = ComboBarHeightMin,
            max = ComboBarHeightMax,
            step = 1,
            arg = {'size'},
          },
          BarColor = {
            type = 'color',
            name = 'Color',
            order = 10,
            hasAlpha = true,
            get = function()
                    local c = UnitBars[BarType].Bar.Color
                    return c.r, c.g, c.b, c.a
                  end,
            set = function(Info, r, g, b, a)
                    local c = UnitBars[BarType].Bar.Color
                    c.r, c.g, c.b, c.a = r, g, b, a
                    UnitBarsF[BarType]:SetAttr('bar', 'color')
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
                return UnitBars[BarType].Bar.Padding[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[BarType].Bar.Padding[Info[#Info]] = Value
                UnitBarsF[BarType]:SetAttr('bar', 'padding')
              end,
        args = {
          Left = {
            type = 'range',
            name = 'Left',
            order = 1,
            min = UnitBarPaddingMin,
            max = UnitBarPaddingMax,
            step = 1,
          },
          Right = {
            type = 'range',
            name = 'Right',
            order = 2,
            min = UnitBarPaddingMin,
            max = UnitBarPaddingMax,
            step = 1,
          },
          Top = {
            type = 'range',
            name = 'Top',
            order = 3,
            min = UnitBarPaddingMin,
            max = UnitBarPaddingMax,
            step = 1,
          },
          Bottom = {
            type = 'range',
            name = 'Bottom',
            order = 4,
            min = UnitBarPaddingMin,
            max = UnitBarPaddingMax,
            step = 1,
          },
        },
      },
    },
  }

  -- Add power colors for power bars only.
  if BarType == 'PlayerPower' or BarType == 'TargetPower' or BarType == 'MainPower' then

    -- Remove the BarColor options
    BarOptions.args.General.args.BarColor = nil

    -- Add the Power color options.
    BarOptions.args.PowerColors = CreatePowerColorsOptions(BarType, 2, 'Power Colors')
  end

  -- Add combo bar color options if its a combobar. And remove HapWidth and HapHeight options.
  if BarType == 'ComboBar' then
    BarOptions.args.General.args.BarColor = nil
    BarOptions.args.General.args.HapWidth = nil
    BarOptions.args.General.args.HapHeight = nil
    BarOptions.args.ComboColors = CreateColorAllOptions(BarType, 'bar', 5, 2, 'Colors')
  else
    BarOptions.args.General.args.ComboWidth = nil
    BarOptions.args.General.args.ComboHeight = nil
  end
  return BarOptions
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
            GUB.RuneBar:SetRuneBarLayout(UnitBarsF[BarType])
          end,
    args = {
      BarMode = {
        type = 'toggle',
        name = 'Bar Mode',
        order = 1,
        desc = "If checked the runes can't be moved anywhere on the screen",
      },
      RuneSwap = {
        type = 'toggle',
        name = 'Swap Runes',
        order = 2,
        desc = 'Runes can be swapped by dragging a rune on another rune',
      },
      CooldownText = {
        type = 'toggle',
        name = 'Cooldown Text',
        order = 3,
        desc = 'Show cooldown text',
      },
      CooldownAnimation = {
        type = 'toggle',
        name = 'Cooldown Animation',
        order = 4,
        desc = 'Shows the cooldown animation',
      },
      HideCooldownFlash = {
        type = 'toggle',
        name = 'Hide Flash',
        order = 5,
        disabled = function()
                     return not UnitBars[BarType].General.CooldownAnimation
                   end,
        desc = 'Hides the flash animation after a rune comes off cooldown',
      },
      CooldownDrawEdge = {
        type = 'toggle',
        name = 'Draw Edge',
        order = 6,
        disabled = function()
                     return not UnitBars[BarType].General.CooldownAnimation
                   end,
        desc = 'Shows a line on the cooldown animation',
      },
      BarModeAngle = {
        type = 'range',
        name = 'Rotation',
        order = 7,
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
        order = 6,
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
        order = 7,
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
            GUB.ComboBar:SetComboBarLayout(UnitBarsF[BarType])
          end,
    args = {
      ComboPadding = {
        type = 'range',
        name = 'Combo Padding',
        order = 6,
        desc = 'Set the Amount of space between each combo point box',
        min = ComboBarPaddingMin,
        max = ComboBarPaddingMax,
        step = 1,
      },
      ComboAngle = {
        type = 'range',
        name = 'Rotation',
        order = 5,
        desc = 'Rotates the combo bar',
        min = ComboBarAngleMin,
        max = ComboBarAngleMax,
        step = 45,
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
-- HolyBarOptions       Options table for the combo points bar.
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
            GUB.HolyBar:SetHolyBarLayout(UnitBarsF[BarType])
          end,
    args = {
      HolyAngle = {
        type = 'range',
        name = 'Holy Rotation',
        order = 1,
        desc = 'Rotates the holy bar',
        min = HolyBarAngleMin,
        max = HolyBarAngleMax,
        step = 45,
      },
      HolySize = {
        type = 'range',
        name = 'Holy Size',
        order = 2,
        desc = 'Sets the size of all the holy power runes',
        min = HolyBarSizeMin,
        max = HolyBarSizeMax,
        step = 1,
      },
      HolyScale = {
        type = 'range',
        name = 'Holy Scale',
        order = 3,
        desc = 'Sets the scale of all the holy power runes',
        min = HolyBarScaleMin,
        max = HolyBarScaleMax,
        step = 0.01,
        isPercent = true,
      },
      HolyPadding = {
        type = 'range',
        name = 'Holy Padding',
        order = 4,
        desc = 'Set the Amount of space between each holy rune',
        min = HolyBarPaddingMin,
        max = HolyBarPaddingMax,
        step = 1,
      },
      HolyFadeOutTime = {
        type = 'range',
        name = 'Holy Fadeout Time',
        order = 5,
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
            name = "Hide when Dead",
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
      General = {
        type = 'group',
        name = 'General',
        dialogInline = true,
        order = 2,
        args = {
          TextType = {
            type = 'select',
            name = 'Text Type',
            order = 1,
            values = TextTypeDropdown,
            style = 'dropdown',
            desc = 'Changes the look of the value text in the bar',
            get = function()
                    return UnitBars[BarType].General.TextType
                  end,
            set = function(Info, Value)
                    UnitBars[BarType].General.TextType = Value

                    -- Redraw the bar to show the texttype change.
                    UnitBarsF[BarType]:Update()
                  end,
          },
--          Alpha = CreateAlphaOption(BarType, 3),
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
          Reset = {
            type = 'execute',
            name = 'Reset to Defaults',
            order = 2,
            desc = 'Resets back to the defaults for this bar without changing its location',
            confirm = true,
            func = function()

                     -- Preserve bar location
                     local UB = UnitBars[BarType]
                     local x, y =  UB.x, UB.y

                     GUB.UnitBars:CopyTableValues(Defaults.profile[BarType], UB)

                     UB.x, UB.y = x, y

                     -- Redo everything to show any possible changes.
                     GUB:OnEnable()
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

  -- Add background options
  if BarType ~= 'RuneBar' then
    UBO.Background = CreateBackgroundOptions(BarType, 1000, 'Background')
  end

  -- Add bar options
  if BarType ~= 'RuneBar' and BarType ~= 'HolyBar' then
    UBO.Bar = CreateBarOptions(BarType, 1001, 'Bar')
  end

  -- Add text options
  if BarType ~= 'ComboBar' and BarType ~= 'HolyBar' then
    UBO.Text = CreateTextOptions(BarType, 1002, 'Text')
    if BarType == 'RuneBar' then
      UBO.General = nil
    end
  else

    -- Remove the general options
    UBO.General = nil
  end

  -- Add runebar options
  if BarType == 'RuneBar' then
    UBO.RuneBar = CreateRuneBarOptions(BarType, 3, 'General')
  end

  -- Add combobar options
  if BarType == 'ComboBar' then
    UBO.ComboBar =  CreateComboBarOptions(BarType, 4, 'General')
  end

  -- Add holybar options
  if BarType == 'HolyBar' then
    UBO.HolyBar = CreateHolyBarOptions(BarType, 5, 'General')
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
                        local Value = CopySettings.All or
                                CopySettingsFrom == 'RuneBar' or CopySettingsFrom == 'ComboBar' or CopySettingsFrom == 'HolyBar' or
                                CopySettingsTo == 'RuneBar' or CopySettingsTo == 'ComboBar' or CopySettingsTo == 'HolyBar'
                        CopySettingsHidden[Info[#Info]] = Value
                        return Value
                     end,
            desc = 'Copy the general settings',
          },
          Other = {
            type = 'toggle',
            name = 'Other',
            order = 4,
            hidden = function(Info)
                       CopySettingsHidden[Info[#Info]] = true
                       return false
                     end,
            desc = 'Copy the other settings',
          },
          Background = {
            type = 'toggle',
            name = 'Background',
            order = 5,
            hidden = function(Info)
                       local Value = CopySettings.All or
                               CopySettingsFrom == 'RuneBar' or CopySettingsTo == 'RuneBar'
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
                               CopySettingsFrom == 'RuneBar' or CopySettingsFrom == 'HolyBar' or
                               CopySettingsTo == 'RuneBar' or CopySettingsTo == 'HolyBar'
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
                               CopySettingsFrom == 'ComboBar' or CopySettingsFrom == 'HolyBar' or
                               CopySettingsTo == 'ComboBar' or CopySettingsTo == 'HolyBar'
                       CopySettingsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = 'Copy the text settings',
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
                    return string.format('Copy settings from %s to %s ?',
                           UnitBars[CopySettingsFrom].Name, UnitBars[CopySettingsTo].Name)
                  end,
        func = function()
                 local Source = UnitBars[CopySettingsFrom]
                 local Dest = UnitBars[CopySettingsTo]

                 -- Preserve name and location.
                 local Name = Dest.Name
                 local x, y = Dest.x, Dest.y

                 if CopySettings.All then
                   GUB.UnitBars:CopyTableValues(Source, Dest)
                 else
                   if CopySettings.Status and not CopySettingsHidden.Status then
                     GUB.UnitBars:CopyTableValues(Source.Status, Dest.Status)
                   end
                   if CopySettings.General and not CopySettingsHidden.General then
                     GUB.UnitBars:CopyTableValues(Source.General, Dest.General)
                   end
                   if CopySettings.Other and not CopySettingsHidden.Other then
                     GUB.UnitBars:CopyTableValues(Source.Other, Dest.Other)
                   end
                   if CopySettings.Background and not CopySettingsHidden.Background then
                     GUB.UnitBars:CopyTableValues(Source.Background, Dest.Background)
                   end
                   if CopySettings.Bar and not CopySettingsHidden.Bar then
                     GUB.UnitBars:CopyTableValues(Source.Bar, Dest.Bar)
                   end
                   if CopySettings.Text and not CopySettingsHidden.Text then
                     GUB.UnitBars:CopyTableValues(Source.Text, Dest.Text)
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
    GUB.UnitBars:AlignUnitBars(AlignmentBar, BarsToAlign, AlignmentType, Alignment[AlignmentType], PadEnabled, Padding)
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
                     return string.format('Align Player Health with %s', AlignmentBarName)
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
                     return string.format('Align Player Power with %s', AlignmentBarName)
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
                     return string.format('Align Target Health with %s', AlignmentBarName)
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
                     return string.format('Align Target Power with %s', AlignmentBarName)
                   end
          },
          MainPower = {
            type = 'toggle',
            name = 'Main Power',
            order = 5,
            hidden = function(Info)
                       local Value = AlignmentBar == 'MainPower'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return string.format('Align Main Power with %s', AlignmentBarName)
                   end
          },
          RuneBar = {
            type = 'toggle',
            name = 'Rune Bar',
            order = 6,
            hidden = function(Info)
                       local Value = AlignmentBar == 'RuneBar'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return string.format('Align Rune Bar with %s', AlignmentBarName)
                   end
          },
          ComboBar = {
            type = 'toggle',
            name = 'Combo Bar',
            order = 7,
            hidden = function(Info)
                       local Value = AlignmentBar == 'ComboBar'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return string.format('Align Combo Bar with %s', AlignmentBarName)
                   end
          },
          HolyBar = {
            type = 'toggle',
            name = 'Holy Bar',
            order = 7,
            hidden = function(Info)
                       local Value = AlignmentBar == 'HolyBar'
                       BarsHidden[Info[#Info]] = Value
                       return Value
                     end,
            desc = function()
                     return string.format('Align Combo Bar with %s', AlignmentBarName)
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
                   return string.format('Align with %s. Once clicked Alignment Settings can be changed without having to click this button', AlignmentBarName)
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
                GUB.UnitBars:UnitBarsSetAllOptions()
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
          SmoothUpdate = {
            type = 'toggle',
            name = 'Smooth Update',
            order = 6,
            desc = 'Health and power bars will update smoothly if checked',
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
                    GUB.UnitBars:UnitBarsSetAllOptions()
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
          TargetHealth = CreateUnitBarOptions('TargetHealth', 2, 'Target Health'),

          -- Target Power group.
          TargetPower = CreateUnitBarOptions('TargetPower', 3, 'Target Power'),

          -- Main Power group.
          MainPower = CreateUnitBarOptions('MainPower', 4, 'Main Power', 'Druids only: Shown when in cat or bear form'),

          -- Runebar group.
          RuneBar = CreateUnitBarOptions('RuneBar', 4, 'Rune Bar'),

          -- Combobar group.
          ComboBar = CreateUnitBarOptions('ComboBar', 5, 'Combo Bar'),

          -- Holybar group.
          HolyBar = CreateUnitBarOptions('HolyBar', 6, 'Holy Bar'),
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
                     return string.format('|cffffd200%s   version %s|r', AddonName, AddonVersion)
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
  ProfileOptions = LibStub('AceDBOptions-3.0'):GetOptionsTable(GUB.UnitBarsDB)

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
