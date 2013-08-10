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
local strupper, strlower, format, tonumber, strconcat, strfind, strmatch, gsub, strsub, min, max =
      strupper, strlower, format, tonumber, strconcat, strfind, strmatch, gsub, strsub, min, max
local ipairs, pairs, type =
      ipairs, pairs, type
local InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print, GameTooltip =
      InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, print, GameTooltip
-------------------------------------------------------------------------------
-- Locals
--
-- Options.Open                  If true then the options window is opened. Otherwise closed.
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
-- CapBarType                    Used for copy/paste. Contains the BarType of the bar being copied.
-- CapName                       Used for copy/paste. Contains the bars name of the data being copied.
-- CapTablePath                  Used for copy/paste. Contains the table path to be copied.
-- CapType                       Used for copy/paste. Type of data being copied.
-- CapButtons                    Used for copy/paste. Table containing the buttons for copy and pasting.
--
-- SetFunctions                  Table used to save and call functions thru SetFunction()
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
-- ACDOnHideFrame                Frame used for when the options window is closed.
-------------------------------------------------------------------------------
local AceConfigRegistery = LibStub('AceConfigRegistry-3.0')

-- Addon Constants
local AddonName = GetAddOnMetadata(MyAddon, 'Title')
local AddonVersion = GetAddOnMetadata(MyAddon, 'Version')
local AddonOptionsName = MyAddon .. 'options'
local AddonOptionsToGUBName = MyAddon .. 'options2'
local AddonProfileName = MyAddon .. 'profile'
local AddonSlashName = MyAddon

local SetFunctions = {}
local O = {}
local ACDOnHideFrame = CreateFrame('Frame', nil)

local OptionsToGUBFrame = nil
local MainOptionsFrame = nil
local ProfileFrame = nil

local SlashOptions = nil
local OptionsToGUB = nil
local MainOptions = nil
local ProfileOptions = nil

local UnitBars = nil
local PlayerClass = nil
local PlayerPowerType = nil

local CapBarType = nil
local CapName = nil
local CapTablePath = nil
local CapType = nil
local CapButtons = nil

local O = {
  FadeOutTime = 5,
  FadeInTime = 1,

  MaxTextLines = 4,
  MaxValueNames = 6,

  FontOffsetXMin = -150,
  FontOffsetXMax = 150,
  FontOffsetYMin = -150,
  FontOffsetYMax = 150,
  FontShadowOffsetMin = 0,
  FontShadowOffsetMax = 10,

  UnitBarPaddingMin = -20,
  UnitBarPaddingMax = 20,
  UnitBarBgTileSizeMin = 1,
  UnitBarBgTileSizeMax = 100,
  UnitBarBorderSizeMin = 2,
  UnitBarBorderSizeMax = 32,
  UnitBarFontSizeMin = 6,
  UnitBarFontSizeMax = 64,
  UnitBarFontFieldWidthMin = 20,
  UnitBarFontFieldWidthMax = 400,
  UnitBarFontFieldHeightMin = 10,
  UnitBarFontFieldHeightMax = 200,
  UnitBarScaleMin = 0.10,
  UnitBarScaleMax = 4,
  UnitBarWidthMin = 10,
  UnitBarWidthMax = 500,
  UnitBarHeightMin = 10,
  UnitBarHeightMax = 500,
  UnitBarOffset = 25,

  RuneBarAngleMin = 45,
  RuneBarAngleMax = 360,
  RuneBarSizeMin = 10,
  RuneBarSizeMax = 100,
  RuneBarPaddingMin = -10,
  RuneBarPaddingMax = 50,
  RuneOffsetXMin = -50,
  RuneOffsetXMax = 50,
  RuneOffsetYMin = -50,
  RuneOffsetYMax = 50,
  RuneEnergizeTimeMin = 0,
  RuneEnergizeTimeMax = 5,

  ComboBarPaddingMin = -10,
  ComboBarPaddingMax = 50,
  ComboBarFadeOutMin = 0,
  ComboBarFadeOutMax = 5,
  ComboBarFadeInMin = 0,
  ComboBarFadeInMax = 1,
  ComboBarAngleMin = 45,
  ComboBarAngleMax = 360,

  HolyBarSizeMin = 0.01,
  HolyBarSizeMax = 3,
  HolyBarScaleMin = 0.1,
  HolyBarScaleMax = 2,
  HolyBarPaddingMin = -50,
  HolyBarPaddingMax = 50,
  HolyBarFadeOutMin = 0,
  HolyBarFadeOutMax = 5,
  HolyBarFadeInMin = 0,
  HolyBarFadeInMax = 1,
  HolyBarAngleMin = 45,
  HolyBarAngleMax = 360,

  ShardBarSizeMin = 0.01,
  ShardBarSizeMax = 3,
  ShardBarScaleMin = 0.1,
  ShardBarScaleMax = 2,
  ShardBarPaddingMin = -50,
  ShardBarPaddingMax = 50,
  ShardBarFadeOutMin = 0,
  ShardBarFadeOutMax = 5,
  ShardBarFadeInMin = 0,
  ShardBarFadeInMax = 1,
  ShardBarAngleMin = 45,
  ShardBarAngleMax = 360,

  EmberBarSizeMin = 0.01,
  EmberBarSizeMax = 3,
  EmberBarScaleMin = 0.1,
  EmberBarScaleMax = 2,
  EmberBarPaddingMin = -50,
  EmberBarPaddingMax = 50,
  EmberBarAngleMin = 45,
  EmberBarAngleMax = 360,
  EmberBarFieryFadeInMin = 0,
  EmberBarFieryFadeInMax = 1,
  EmberBarFieryFadeOutMin = 0,
  EmberBarFieryFadeOutMax = 5,

  EclipseBarFadeOutMin = 0,
  EclipseBarFadeOutMax = 5,
  EclipseBarFadeInMin = 0,
  EclipseBarFadeInMax = 1,
  EclipseAngleMin = 90,
  EclipseAngleMax = 360,
  EclipseSunOffsetXMin = -50,
  EclipseSunOffsetXMax = 50,
  EclipseSunOffsetYMin = -50,
  EclipseSunOffsetYMax = 50,
  EclipseMoonOffsetXMin = -50,
  EclipseMoonOffsetXMax = 50,
  EclipseMoonOffsetYMin = -50,
  EclipseMoonOffsetYMax = 50,

  ShadowBarSizeMin = 0.01,
  ShadowBarSizeMax = 3,
  ShadowBarScaleMin = 0.1,
  ShadowBarScaleMax = 2,
  ShadowBarPaddingMin = -50,
  ShadowBarPaddingMax = 50,
  ShadowBarFadeOutMin = 0,
  ShadowBarFadeOutMax = 5,
  ShadowBarFadeInMin = 0,
  ShadowBarFadeInMax = 1,
  ShadowBarAngleMin = 45,
  ShadowBarAngleMax = 360,

  ChiBarSizeMin = 0.01,
  ChiBarSizeMax = 3,
  ChiBarScaleMin = 0.1,
  ChiBarScaleMax = 2,
  ChiBarPaddingMin = -50,
  ChiBarPaddingMax = 50,
  ChiBarFadeOutMin = 0,
  ChiBarFadeOutMax = 5,
  ChiBarFadeInMin = 0,
  ChiBarFadeInMax = 1,
  ChiBarAngleMin = 45,
  ChiBarAngleMax = 360,
}

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

local ValueNameDropdown = {
  'Current Value',       -- 1
  'Maximum Value',       -- 2
  'Predicted Value',     -- 3
  'Unit Name',           -- 4
  'Realm Name',          -- 5
  'Unit Name and Realm', -- 6
}

local ValueTypeDropdown = {
  'Whole',                -- 1
  'Short',                -- 2
  'Thousands',            -- 3
  'Millions',             -- 4
  'Whole (Digit Groups)', -- 5
  'Percentage',           -- 6
}

local ConvertValueName = {
  current          = 1,
  maximum          = 2,
  predicted        = 3,
  unitname         = 4,
  realmname        = 5,
  unitnamerealm    = 6,
  'current',       -- 1
  'maximum',       -- 2
  'predicted',     -- 3
  'unitname',      -- 4
  'realmname',     -- 5
  'unitnamerealm', -- 6
}

local ConvertValueType = {
  whole                    = 1,
  short                    = 2,
  thousands                = 3,
  millions                 = 4,
  whole_dgroups            = 5,
  percent                  = 6,
  'whole',                -- 1
  'short',                -- 2
  'thousands',            -- 3
  'millions',             -- 4
  'whole_dgroups',        -- 5
  'percent',              -- 6
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
-- Options creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- HideTooltip
--
-- Hides the tooltip based on a boolean value. Boolean value gets returned.
-- Used in for buttons that get disabled so the tooltip will close.
--
-- Usage: HideTooltip(true or false)
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
function GUB.Options:ShareData(UB, PC, PPT)
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
-- GetBg
--
-- Returns the background table.
--
-- Usage Background = GetBg(BarType, TableName)
--
-- BarType      The bar you're getting data from.
-- TableName    if nil then returns UnitBars[BarType].Background
--              else returns UnitBars[BarType].Background[TableName]
--
-- Background   Contains the background table
-------------------------------------------------------------------------------
local function GetBg(BarType, TableName)
  return TableName and UnitBars[BarType].Background[TableName] or UnitBars[BarType].Background
end

-------------------------------------------------------------------------------
-- GetBar
--
-- Returns the bar table.
--
-- Usage Bar = GetBar(BarType, TableName)
--
-- BarType      The bar you're getting data from.
-- TableName    if nil then returns UnitBars[BarType].Bar
--              else returns UnitBars[BarType].Bar[TableName]
--
-- Bar          Contains the bar table
-------------------------------------------------------------------------------
local function GetBar(BarType, TableName)
  return TableName and UnitBars[BarType].Bar[TableName] or UnitBars[BarType].Bar
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
-- Usage: OnOptions(Action)
--
-- Action     'open' then the options window was just opened.
--            'close' Options window was closed.
-------------------------------------------------------------------------------
local function OnOptions(Action)
  if Action == 'open' then
    Main:FontSetHighlight('on')
    GUB.Options.Open = true
  else
    Main:FontSetHighlight('off')
    GUB.Options.Open = false
  end
end

-------------------------------------------------------------------------------
-- CreateToGUBOptions
--
-- Creates an option that takes you to the GUB options frame.
--
-- Usage: CreateToGUBOptions()
-------------------------------------------------------------------------------
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

             -- Call OnOptions() for open
             OnOptions('open')

             -- Open a movable options frame.
             local ACD = LibStub('AceConfigDialog-3.0')
             ACD:Open(AddonOptionsName)

             -- Set the OnHideFrame's frame parent to AceConfigDialog's options frame.
             ACDOnHideFrame:SetParent(ACD.OpenFrames[AddonOptionsName].frame)

             -- When hidden call OnOptions() for close.
             ACDOnHideFrame:SetScript('OnHide', function()
                                                  ACDOnHideFrame:SetScript('OnHide', nil)
                                                  OnOptions('close')
                                                end)
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
                print(AddonName, 'Version ', AddonVersion)
               end,
      },
      config = CreateToGUBOptions(2, '', 'Opens a movable options frame'),
      c = CreateToGUBOptions(3, '', 'Same as config')
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
-- Creates all color options that support multiple colors.
--
-- Subfunction of CreateBackgroundOptions()
-- Subfunction of CreateBarOptions()
-- Subfunction of CreateTextOptions()
-- Subfunction of CreateRuneBarOptions()
--
-- Usage: ColorAllOptions = CreateColorAllOptions(BarType, TablePath, Object, Order, Name)
--
-- BarType       Type of options being created.
-- Object        Used for SetAttr().
-- TableName     Usually 'Background' or 'Bar'
-- ColorTable    Name of the color table to use.
-- Object        Type of object you're changing, examples: texture, bg, bar, etc.
-- Order         Order number.
-- Name          Name text
--
-- ColorAllOptions  Options table for the bartype.
-------------------------------------------------------------------------------
local function CreateColorAllOptions(BarType, TablePath, Object, Order, Name)
  local UBF = UnitBarsF[BarType]
  local ColorAllNames = UBF.ColorAllNames

  -- Get max colors
  local MaxColors = #Main:GetVP(BarType, TablePath)

  local ColorAllOptions = {
    type = 'group',
    name = Name,
    order = Order,
    hidden = function()
               if not UBF.UnitBar.General.BoxMode then
                 if Object == 'bg' then
                   if BarType == 'HolyBar' or BarType == 'ShardBar' or BarType == 'EmberBar' or
                      BarType == 'ShadowBar' or BarType == 'ChiBar' then
                     return true
                   end
                 end
               end

               -- Check for greenfire.
               if BarType == 'EmberBar' then
                 local GreenFire = strfind(TablePath, 'Green')
                 if GreenFire == nil and UBF.GreenFire or
                    GreenFire and not UBF.GreenFire then
                   return true
                 end
               end
               return false
             end,
    dialogInline = true,
    get = function(Info)
            local ColorIndex = tonumber(Info[#Info])
            local c = Main:GetVP(BarType, TablePath)

            if ColorIndex > 0 then
              c = c[ColorIndex]
            end
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local ColorIndex = tonumber(Info[#Info])
            local c = Main:GetVP(BarType, TablePath)

            if ColorIndex > 0 then
              c = c[ColorIndex]
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
                return Main:GetVP(BarType, TablePath).All
              end,
        set = function(Info, Value)
                Main:GetVP(BarType, TablePath).All = Value

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
                   return not Main:GetVP(BarType, TablePath).All
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
                          return Main:GetVP(BarType, TablePath).All
                        end

    -- Add it to the options table
    t[format('%s', c)] = ColorOption
  end

  return ColorAllOptions
end

-------------------------------------------------------------------------------
-- CreateEclipseColorOptions
--
-- Creates all color options for the eclipse slider.
--
-- Subfunction of CreateBarOptions()
--
-- Usage: SliderColorOptions = CreateEclipseSliderColorOptions(BarType, TableName, Object, Order, Name)
--
-- BarType       Type options being created.
-- TableName     Name of the table inside of Object.
-- Object        Can be 'bg', 'bar'
-- Order         Order number.
-- Name          Name text
--
-- SliderColorOptions  Options table for the eclipse slider
-------------------------------------------------------------------------------
local function CreateEclipseColorOptions(BarType, TableName, Object, Order, Name)
  local UBF = UnitBarsF[BarType]
  local UnitBarTable = nil

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
-- Usage: BackgroundOptions = CreateBackgroundOptions(BarType, TableName, Order, Name)
--
-- BarType               Type options being created.
-- TableName             if not nil points to a sub background table.
-- Order                 Order number.
-- Name                  Name text
--
-- BackgroundOptions     Options table for background options.
-------------------------------------------------------------------------------
local function CreateBackgroundOptions(BarType, TableName, Order, Name)
  local UBF = UnitBarsF[BarType]

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
                return GetBg(BarType, TableName).BackdropSettings[Info[#Info]]
              end,
        set = function(Info, Value)
                GetBg(BarType, TableName).BackdropSettings[Info[#Info]] = Value
                if TableName then
                  UBF:SetAttr('bg', 'backdrop', TableName)

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
                         return not GetBg(BarType, TableName).BackdropSettings.BgTile
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

  -- add background color option if its not a combo bar or runebar.
  if BarType ~= 'ComboBar' and BarType ~= 'RuneBar' then
    BackgroundOptions.args.General.args.BgColor = {
      type = 'color',
      name = 'Background Color',
      order = 22,
      hidden = function()
                 return ( BarType == 'HolyBar' or BarType == 'ShardBar' or BarType == 'EmberBar' or
                          BarType == 'ShadowBar' or BarType == 'ChiBar') and UBF.UnitBar.General.BoxMode
               end,
      hasAlpha = true,
      get = function()

              -- if GreenFire is not nil then we're working with an emberbar.
              local c = GetBg(BarType, TableName)[UBF.GreenFire and 'ColorGreen' or 'Color']
              return c.r, c.g, c.b, c.a
            end,
      set = function(Info, r, g, b, a)

              -- if GreenFire is not nil then we're working with an emberbar.
              local c = GetBg(BarType, TableName)[UBF.GreenFire and 'ColorGreen' or 'Color']
              c.r, c.g, c.b, c.a = r, g, b, a
              if TableName then
                UBF:SetAttr('bg', 'color', TableName)
              else
                UBF:SetAttr('bg', 'color')
              end
           end,
    }
  end

  -- Add color all options for background.
  if BarType == 'RuneBar' or BarType == 'ComboBar' or BarType == 'HolyBar' or
     BarType == 'ShardBar' or BarType == 'EmberBar' or BarType == 'ShadowBar' or BarType == 'ChiBar' then
    BackgroundOptions.args.BgColors = CreateColorAllOptions(BarType, 'Background.Color', 'bg', 2, 'Color')

    -- Add colorgreen background for emberbar.
    if BarType == 'EmberBar' then
      BackgroundOptions.args.BgColorsGreen = CreateColorAllOptions(BarType, 'Background.ColorGreen', 'bg', 2, 'Color')
    end
  end

  BackgroundOptions.args.Padding = {
    type = 'group',
    name = 'Padding',
    dialogInline = true,
    order = 3,
    get = function(Info)
            local Padding = GetBg(BarType, TableName).BackdropSettings.Padding
            if Info[#Info] == 'All' then
              return Padding.Left
            else
              return Padding[Info[#Info]]
            end
          end,
    set = function(Info, Value)
            local Padding = GetBg(BarType, TableName).BackdropSettings.Padding
            if Info[#Info] == 'All' then
              Padding.Left = Value
              Padding.Right = Value
              Padding.Top = Value
              Padding.Bottom = Value
            else
              Padding[Info[#Info]] = Value
            end
            if TableName then
              UBF:SetAttr('bg', 'backdrop', TableName)
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
                return GetBg(BarType, TableName).PaddingAll
              end,
        set = function(Info, Value)
                GetBg(BarType, TableName).PaddingAll = Value
              end,
        desc = 'Change padding with one value'
      },
      Spacer = CreateSpacer(2),
      All = {
        type = 'range',
        name = 'Offset',
        order = 3,
        hidden = function()
                   return not GetBg(BarType, TableName).PaddingAll
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
                   return GetBg(BarType, TableName).PaddingAll
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
                   return GetBg(BarType, TableName).PaddingAll
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
                   return GetBg(BarType, TableName).PaddingAll
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
                   return GetBg(BarType, TableName).PaddingAll
                 end,
        min = O.UnitBarPaddingMin,
        max = O.UnitBarPaddingMax,
        step = 1,
      },
    },
  }

  return BackgroundOptions
end

-------------------------------------------------------------------------------
-- CreateTextFontOptions
--
-- Creats font options to control color, size, etc for text.
--
-- Subfunction of CreateTextOptions()
--
-- Usage: CreateTextOptions(BarType, TextOptions, TxtLine, Order)
--
-- BarType       Bar the text options belongs to
-- TextOptions   Font options will be inserted into this table.
-- TxtLine       Used to convert TextOptions.name to number.
-- Order         Positions on the options panel.
-------------------------------------------------------------------------------
local function CreateTextFontOptions(BarType, TextOptions, TxtLine, Order)
  local UBF = UnitBarsF[BarType]

  TextOptions.args.Font = {
    type = 'group',
    name = function()

             -- highlight the text in green.
             Main:FontSetHighlight(BarType, TxtLine[TextOptions.name])
             return 'Font'
           end,
    dialogInline = true,
    order = Order + 1,
    get = function(Info)
            return UBF.UnitBar.Text[TxtLine[TextOptions.name]][Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.Text[TxtLine[TextOptions.name]][Info[#Info]] = Value
            UBF:SetAttr('text', 'font')
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
        min = O.UnitBarFontFieldWidthMin,
        max = O.UnitBarFontFieldWidthMax,
        step = 1,
      },
      Height = {
        type = 'range',
        name = 'Field Height',
        order = 12,
        min = O.UnitBarFontFieldHeightMin,
        max = O.UnitBarFontFieldHeightMax,
        step = 1,
      },
      Spacer20 = CreateSpacer(20),
      FontSize = {
        type = 'range',
        name = 'Size',
        order = 21,
        min = O.UnitBarFontSizeMin,
        max = O.UnitBarFontSizeMax,
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
          Position = {
            type = 'select',
            name = 'Position',
            order = 3,
            style = 'dropdown',
            values = PositionDropdown,
          },
        },
      },
    },
  }

  -- Add color all text option for the runebar only.
  if BarType == 'RuneBar' then
    TextOptions.args.TextColors = CreateColorAllOptions(BarType, 'Text.1.Color', 'text', Order, 'Color')
  else
    TextOptions.args.Font.args.TextColor = {
      type = 'color',
      name = 'Color',
      order = 22,
      hasAlpha = true,
      get = function()
              local c = UBF.UnitBar.Text[TxtLine[TextOptions.name]].Color
              return c.r, c.g, c.b, c.a
            end,
      set = function(Info, r, g, b, a)
              local c = UBF.UnitBar.Text[TxtLine[TextOptions.name]].Color
              c.r, c.g, c.b, c.a = r, g, b, a
              UBF:SetAttr('text', 'color')
            end,
    }
  end

  TextOptions.args.Font.args.Offsets = {
    type = 'group',
    name = 'Offsets',
    dialogInline = true,
    order = 41,
    get = function(Info)
            return UBF.UnitBar.Text[TxtLine[TextOptions.name]][Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.Text[TxtLine[TextOptions.name]][Info[#Info]] = Value
            UBF:SetAttr('text', 'font')
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
-- Usage: CreateTextValueOptions(BarType, TL, TxtLine, Order)
--
-- BarType        Options will be added for this bar.
-- TL             Current Text Line options being used.
-- TxtLine        Used to retrieve what text line number is being used.
-- Order          Order number in the options frame.
-- ValueIndex     Used for recursive calls to add more value options.
-------------------------------------------------------------------------------
local function ModifyTextValueOptions(VOA, Action, ValueName, ValueIndex)
  local ValueNameKey = format('ValueName%s', ValueIndex)
  local ValueTypeKey = format('ValueType%s', ValueIndex)

  if Action == 'add' then
    VOA[ValueNameKey] = {
      type = 'select',
      name = format('Value Name %s', ValueIndex),
      values = ValueNameDropdown,
      order = 10 * ValueIndex + 1,
    }
    VOA[ValueTypeKey] = {
      type = 'select',
      name = format('Value Type %s', ValueIndex),
      values = ValueTypeDropdown,
      order = 10 * ValueIndex + 2,
      disabled = function()
                   return strfind(ValueName[ValueIndex], 'name') ~= nil
                 end,
    }
    VOA[format('Spacer%s', 10 * ValueIndex + 3)] = CreateSpacer(10 * ValueIndex + 3)

  elseif Action == 'remove' then
    VOA[format('ValueName%s', ValueIndex)] = nil
    VOA[format('ValueType%s', ValueIndex)] = nil
    VOA[format('Spacer%s', 10 * ValueIndex + 3)] = nil
  end
end

local function CreateTextValueOptions(BarType, TL, TxtLine, Order)
  local UBF = UnitBarsF[BarType]
  local UB = UnitBars[BarType]

  local Text = UB.Text[TxtLine[TL.name]]
  local ValueName = Text.ValueName
  local ValueType = Text.ValueType
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
            local ValueIndex = tonumber(strsub(St, 10))

            if strfind(St, 'Name') then
              return ConvertValueName[ValueName[ValueIndex]]
            elseif strfind(St, 'Type') then
              return ConvertValueType[ValueType[ValueIndex]]
            end
          end,
    set = function(Info, Value)
            local St = Info[#Info]
            local ValueIndex = tonumber(strsub(St, 10))

            if strfind(St, 'Name') then
              UBF.FS:Modify('textsettings', 'change', TxtLine[TL.name], ValueIndex, ConvertValueName[Value], nil)
            elseif strfind(St, 'Type') then

              UBF.FS:Modify('textsettings', 'change', TxtLine[TL.name], ValueIndex, nil, ConvertValueType[Value])
            end

            -- Update the layout to update all changes.
            UBF:SetLayout()
            UBF:Update()
          end,
    args = {
      Layout = {
        type = 'input',
        name = function()
                 if UBF.UnitBar.Text[TxtLine[TL.name]].Custom then
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
                return gsub(UBF.UnitBar.Text[TxtLine[TL.name]].Layout, '|', '||')
              end,
        set = function(Info, Value)
                UBF.UnitBar.Text[TxtLine[TL.name]].Custom = true
                UBF.UnitBar.Text[TxtLine[TL.name]].Layout = gsub(Value, '||', '|')

                -- Update the bar.
                UBF:Update()
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
                     return HideTooltip(NumValues == 0)
                   end,
        func = function()
                 ModifyTextValueOptions(VOA, 'remove', ValueName, NumValues)

                 -- remove last value type.
                 UBF.FS:Modify('textsettings', 'remove', TxtLine[TL.name], NumValues)
                 NumValues = NumValues - 1

                 -- Update the the bar to reflect changes
                 UBF:Update()
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
                 ModifyTextValueOptions(VOA, 'add', ValueName, NumValues)

                 -- Add a new value setting.
                 UBF.FS:Modify('textsettings', 'add', TxtLine[TL.name], NumValues, 'current', 'whole' )

                 -- Update the the bar to reflect changes
                 UBF:Update()
               end,
      },
      Spacer5 = CreateSpacer(5, 'half'),
      ExitCustomLayout = {
        type = 'execute',
        name = 'Exit',
        order = 6,
        width = 'half',
        hidden = function()
                   return HideTooltip(not UBF.UnitBar.Text[TxtLine[TL.name]].Custom)
                 end,
        desc = 'Exit custom layout mode',
        func = function()
                 local TextLine = TxtLine[TL.name]
                 UBF.UnitBar.Text[TextLine].Custom = false

                 -- Call modify to reset layout without changing the text settings.
                 UBF.FS:Modify('textsettings', 'change', TextLine, NumValues)

                 UBF:Update()
               end,
      },
      Spacer7 = CreateSpacer(7),
    },
  }

  VOA = TL.args.Value.args

  -- Add additional value options if needed
  for Index, _ in ipairs(ValueName) do
    ModifyTextValueOptions(VOA, 'add', ValueName, Index)
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
-- Usage: CreateTextLineOptions(BarType, TextLineOptions, TxtLine)
--
-- BarType           Bar the options will be added for.
-- TextLineOptions   Used for recursive calls. On recursive calls more
--                   options are inserted into this table.
-- TxtLine           Used to convert TextLineOptions.name into a number.
-------------------------------------------------------------------------------
local function CreateTextLineOptions(BarType, TextLineOptions, TxtLine)
  local UBF = UnitBarsF[BarType]
  local UB = UnitBars[BarType]

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

               -- Remove the font string.
               UBF.FS:Modify('string', 'remove', Index)

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
               UBF:Update()
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

               -- Add a new font string
               UBF.FS:Modify('string', 'add')

               -- Add options for new text line.
               CreateTextLineOptions(BarType, TextLineOptions, TxtLine)

               -- Update the the bar to reflect changes
               UBF:Update()
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
-- Usage: TextOptions CreateTextOptions(BarType, Order, Name)
--
-- BarType               Type options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- TextOptions     Options table for text options.
-------------------------------------------------------------------------------
local function CreateTextOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]
  local Text = UBF.UnitBar.Text

  local FunctionLabel = format('%s%s', BarType, 'CreateTextOptions')

  local TextOptions = {
    type = 'group',
    name = Name,
    order = Order,
  }
  local TxtLine = {
    [Name] = 1,
  }

  -- This will modify text options table if the profile changed.
  SetFunction(FunctionLabel, function()
    if UnitBars[BarType].Text.Multi then
      TextOptions.childGroups = 'tab'
      TextOptions.args = CreateTextLineOptions(BarType)
    else
      TextOptions.args = {}

      -- Add text font options.
      CreateTextFontOptions(BarType, TextOptions, TxtLine, 1)
    end
  end)

  -- Set up the options
  SetFunction(FunctionLabel)

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
            local c = UBF.UnitBar.Bar.Color[Info[#Info]]
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local c = UBF.UnitBar.Bar.Color[Info[#Info]]
            c.r, c.g, c.b, c.a = r, g, b, a

             -- Update the bar to show the current power color change in real time.
            UBF:SetAttr('bar', 'color')
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

  local ClassPowerType = PlayerPower[PlayerClass]

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
                       PowerType == PlayerPowerType ) then
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
-- Usage: ClassColorOptions = CreateClassColorOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
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
            UBF:SetAttr('bar', 'color')
          end,
    args = {
      ClassColorToggle = {
        type = 'toggle',
        name = 'Class Color',
        order = 1,
        desc = 'If checked, class color will be used',
        get = function()
                return UBF.UnitBar.Bar.ClassColor
              end,
        set = function(Info, Value)
                UBF.UnitBar.Bar.ClassColor = Value

                -- Refresh color when changing between class color and normal.
                UBF:SetAttr('bar', 'color')
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

  local CCOA = ClassColorOptions.args
  for Index, ClassName in ipairs(ClassColorMenu) do
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

  return ClassColorOptions
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
-- TableName             if not nil then points to a subtable in bar.
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
  local FunctionLabel = format('%s%s', BarType, 'CreateBarSizeOptions')
  local ABarWidthKey = format('%s%s', 'Advanced', BarWidthKey)
  local ABarHeightKey = format('%s%s', 'Advanced', BarHeightKey)

  SetFunction(FunctionLabel, function()
    local t = GetBar(BarType, TableName)
    BarSizeOptions.args[ABarWidthKey].min = t[BarWidthKey] - O.UnitBarOffset
    BarSizeOptions.args[ABarWidthKey].max = t[BarWidthKey] + O.UnitBarOffset
    BarSizeOptions.args[ABarHeightKey].min = t[BarHeightKey] - O.UnitBarOffset
    BarSizeOptions.args[ABarHeightKey].max = t[BarHeightKey] + O.UnitBarOffset
  end)

  BarSizeOptions = {
    type = 'group',
    name = 'Bar size',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return GetBar(BarType, TableName)[gsub(Info[#Info], 'Advanced', '')]
          end,
    set = function(Info, Value)
            local Key = Info[#Info]

            -- Check for out of range.
            if Key == ABarWidthKey or Key == ABarHeightKey then
              Key = gsub(Key, 'Advanced', '')
              if strfind(Key, 'Width') then
                Value = min(max(Value + Width, O.UnitBarWidthMin), O.UnitBarWidthMax)
              else
                Value = min(max(Value + Height, O.UnitBarHeightMin), O.UnitBarHeightMax)
              end
            end

            GetBar(BarType, TableName)[Key] = Value

            -- Call the function that was saved from the above SetFunction call.
            SetFunction(FunctionLabel)

            -- Update layout.
            if BarType == 'RuneBar' or BarType == 'ComboBar' or BarType == 'HolyBar' or BarType == 'ShardBar' or
               BarType == 'DemonicBar' or BarType == 'EmberBar' or BarType == 'ShadowBar' or BarType == 'ChiBar' then
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
                return GetBar(BarType, TableName).Advanced
              end,
        set = function(Info, Value)
                GetBar(BarType, TableName).Advanced = Value
              end,
      },
      [BarWidthKey] = {
        type = 'range',
        name = 'Width',
        order = 1,
        desc = 'Slide or click anywhere on the slider to change the width',
        width = 'full',
        hidden = function()
                   return GetBar(BarType, TableName).Advanced
                 end,
        min = O.UnitBarWidthMin,
        max = O.UnitBarWidthMax,
        step = 1,
      },
      [BarHeightKey] = {
        type = 'range',
        name = 'Height',
        order = 2,
        desc = 'Slide or click anywhere on the slider to change the height',
        width = 'full',
        hidden = function()
                   return GetBar(BarType, TableName).Advanced
                 end,
        min = O.UnitBarHeightMin,
        max = O.UnitBarHeightMax,
        step = 1,
      },
      [ABarWidthKey] = {
        type = 'range',
        name = 'Advanced Width',
        order = 1,
        desc = 'Slide or click anywhere on the slider to change the width',
        width = 'full',
        hidden = function()
                   return not GetBar(BarType, TableName).Advanced
                 end,
        min = GetBar(BarType, TableName)[BarWidthKey] - O.UnitBarOffset,
        max = GetBar(BarType, TableName)[BarWidthKey] + O.UnitBarOffset,
        step = 1,
      },
      [ABarHeightKey] = {
        type = 'range',
        name = 'Advanced Height',
        order = 2,
        desc = 'Slide or click anywhere on the slider to change the height',
        width = 'full',
        hidden = function()
                   return not GetBar(BarType, TableName).Advanced
                 end,
        min = GetBar(BarType, TableName)[BarHeightKey] - O.UnitBarOffset,
        max = GetBar(BarType, TableName)[BarHeightKey] + O.UnitBarOffset,
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
-- Usage: BarOptions = CreateBarOptions(BarType, TableName, Order, Name)
--
-- BarType               Type of options being created.
-- TableName             If not nil then points to a sub table under bar
-- Order                 Order number.
-- Name                  Name text.
--
-- BarOptions            Options table for the unitbar.
-------------------------------------------------------------------------------
local function CreateBarOptions(BarType, TableName, Order, Name)
  local UBF = UnitBarsF[BarType]

  local BarOptions = {
    type = 'group',
    name = Name,
    order = Order,
    hidden = function()
               return BarType == 'RuneBar' and UBF.UnitBar.General.RuneMode == 'rune' or
                      ( BarType == 'HolyBar' or BarType == 'ShardBar' or BarType == 'DemonicBar' or
                        BarType == 'EmberBar' or BarType == 'ShadowBar' or BarType == 'ChiBar') and
                      not UBF.UnitBar.General.BoxMode
             end,
    args = {
      General = {
        type = 'group',
        name = 'General',
        dialogInline = true,
        order = 1,
        get = function(Info)
                return GetBar(BarType, TableName)[Info[#Info]]
              end,
        set = function(Info, Value)
                GetBar(BarType, TableName)[Info[#Info]] = Value

                -- Update layout.
                if BarType == 'RuneBar' or BarType == 'ComboBar' or BarType == 'HolyBar' or
                   BarType == 'ShardBar' or BarType == 'EmberBar' or BarType == 'ShadowBar' or BarType == 'ChiBar' then
                  UBF:SetLayout()
                else
                  if TableName then

                    -- This section mostly for eclipse bar.
                    -- Update the bar to recalculate the slider pos.
                    UBF:SetLayout()
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

  if BarType ~= 'EclipseBar' or BarType == 'EclipseBar' and TableName ~= 'Bar' then
    GA.StatusBarTexture = {
      type = 'select',
      name = 'Bar Texture',
      order = 1,
      dialogControl = 'LSM30_Statusbar',
      values = LSM:HashTable('statusbar'),
      arg = 'texture',
    }
    if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'PetHealth' or
       BarType == 'FocusHealth' or BarType == 'PetHealth' or
       BarType == 'PlayerPower' and PlayerClass == 'HUNTER' then

      GA.PredictedBarTexture = {
        type = 'select',
        name = 'Bar Texture (predicted)',
        order = 2,
        dialogControl = 'LSM30_Statusbar',
        values = LSM:HashTable('statusbar'),
        arg = 'texture',
      }
    end
    if BarType == 'DemonicBar' then
      GA.MetaStatusBarTexture = {
        type = 'select',
        name = 'Bar Texture (metamorphosis)',
        order = 2,
        dialogControl = 'LSM30_Statusbar',
        values = LSM:HashTable('statusbar'),
        arg = 'texture',
      }

    elseif BarType == 'EmberBar' then
      GA.FieryStatusBarTexture = {
        type = 'select',
        name = 'Bar Texture (fiery embers)',
        order = 2,
        dialogControl = 'LSM30_Statusbar',
        values = LSM:HashTable('statusbar'),
        arg = 'texture',
      }
    end
  end
  if BarType == 'EclipseBar' and TableName == 'Bar' then

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

  if BarType ~= 'ComboBar' and BarType ~= 'HolyBar' and BarType ~= 'ShardBar' and
     BarType ~= 'EclipseBar' and BarType ~= 'ShadowBar' and BarType ~= 'ChiBar' then

    GA.FillDirection = {
      type = 'select',
      name = 'Fill Direction',
      order = 11,
      values = DirectionDropdown,
      style = 'dropdown',
      arg = 'texture',
    }
    GA.ReverseFill = {
      type = 'toggle',
      name = 'Reverse Fill',
      order = 12,
      arg = 'texture',
    }
  end
  GA.Spacer15 = CreateSpacer(15)
  GA.RotateTexture = {
    type = 'toggle',
    name = 'Rotate Texture',
    order = 16,
    arg = 'texture',
  }
  GA.Spacer20 = CreateSpacer(20)

  if BarType == 'RuneBar' then
    GA.BoxSize = CreateBarSizeOptions(BarType, TableName, 100, 'RuneWidth', 'RuneHeight')
  elseif BarType == 'ComboBar' or BarType == 'HolyBar' or BarType == 'ShardBar' or
         BarType == 'DemonicBar' or BarType == 'EmberBar' or BarType == 'ShadowBar' or BarType == 'ChiBar' then
    GA.BoxSize = CreateBarSizeOptions(BarType, TableName, 100, 'BoxWidth', 'BoxHeight')
  elseif BarType == 'EclipseBar' then
    GA.BarSize = CreateBarSizeOptions(BarType, TableName, 100, TableName .. 'Width', TableName .. 'Height')

    if TableName == 'Bar' then
      GA.BarColorLunar = {
        type = 'color',
        name = 'Color (lunar)',
        order = 21,
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
        order = 22,
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
  if BarType == 'PetHealth' or BarType == 'EclipseBar' and ( TableName == 'Moon' or TableName == 'Sun' ) then
    GA.BarColor = {
      type = 'color',
      name = 'Color',
      order = 21,
      hasAlpha = true,
      get = function()
              local c = GetBar(BarType, TableName).Color
              return c.r, c.g, c.b, c.a
            end,
      set = function(Info, r, g, b, a)
              local c = GetBar(BarType, TableName).Color
              c.r, c.g, c.b, c.a = r, g, b, a
              if TableName then
                UBF:SetAttr('bar', 'color', TableName)
              else
                UBF:SetAttr('bar', 'color')
              end

              -- Update the bar for shared colors.
              UBF:Update()
            end,
    }
  end

  -- Add class color for Player, Target, and Focus health bars only.
  if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' then

    -- Add the class color options.
    BarOptions.args.ClassColor = CreateClassColorOptions(BarType, 2, 'Color')
  end

  -- Add power colors for power bars only.
  if BarType:find('Power') then

    -- Add the Power color options.
    BarOptions.args.PowerColors = CreatePowerColorsOptions(BarType, 2, 'Power Color')
  end

  -- Add bar color options if its a combobar or shardbar.
  if BarType == 'RuneBar' or BarType == 'ComboBar' or BarType == 'HolyBar' or
     BarType == 'ShardBar' or BarType == 'EmberBar' or BarType == 'ShadowBar' or BarType == 'ChiBar' then
    if BarType == 'EmberBar' then
      BarOptions.args.BarColors = CreateColorAllOptions(BarType, 'Bar.Color', 'bar', 2, 'Color')
      BarOptions.args.BarColorsGreen = CreateColorAllOptions(BarType, 'Bar.ColorGreen', 'bar', 2, 'Color')
      BarOptions.args.BarColorsFire = CreateColorAllOptions(BarType, 'Bar.ColorFiery', 'bar', 3, 'Color (fiery embers)')
      BarOptions.args.BarColorsFireGreen = CreateColorAllOptions(BarType, 'Bar.ColorFieryGreen', 'bar', 3, 'Color (fiery embers)')
    else
      BarOptions.args.BarColors = CreateColorAllOptions(BarType, 'Bar.Color', 'bar', 2, 'Color')
    end
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
        MetaColor = {
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
    if TableName == 'Slider' then
      BarOptions.args.SliderColor = CreateEclipseColorOptions(BarType, 'Slider', 'bar', 2, 'Color')
    end
    if TableName == 'Indicator' then
      BarOptions.args.IndicatorColor = CreateEclipseColorOptions(BarType, 'Indicator', 'bar',  2, 'Color')
    end
  end

  -- Add predicted color for Health bars only or for Player Power for hunters.
  if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' or BarType == 'PetHealth' or
     BarType == 'PlayerPower' and PlayerClass == 'HUNTER' then
    BarOptions.args.PredictedColors = CreatePredictedColorOptions(BarType, 3, 'Color (predicted)')
  end

  BarOptions.args.Padding = {
    type = 'group',
    name = 'Padding',
    dialogInline = true,
    order = 10,
    get = function(Info)
            local Padding = GetBar(BarType, TableName).Padding
            if Info[#Info] == 'All' then
              return Padding.Left
            else
              return Padding[Info[#Info]]
            end
          end,
    set = function(Info, Value)
            local Padding = GetBar(BarType, TableName).Padding
            if Info[#Info] == 'All' then
              Padding.Left = Value
              Padding.Right = -Value
              Padding.Top = -Value
              Padding.Bottom = Value
            else
              Padding[Info[#Info]] = Value
            end

            if TableName then
              UBF:SetAttr('bar', 'padding', TableName)
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
                return GetBar(BarType, TableName).PaddingAll
              end,
        set = function(Info, Value)
                GetBar(BarType, TableName).PaddingAll = Value
              end,
        desc = 'Change padding with one value'
      },
      Spacer = CreateSpacer(2),
      All = {
        type = 'range',
        name = 'Offset',
        order = 3,
        hidden = function()
                   return not GetBar(BarType, TableName).PaddingAll
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
                   return GetBar(BarType, TableName).PaddingAll
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
                   return GetBar(BarType, TableName).PaddingAll
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
                   return GetBar(BarType, TableName).PaddingAll
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
                   return GetBar(BarType, TableName).PaddingAll
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
            local Option = Info[#Info]
            UBF.UnitBar.General[Option] = Value

            if Option == 'PredictedPower' then
              UBF:SetAttr('ppower')
            end

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
  --[[    CooldownDrawEdge = {
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
      }, --]]
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
        min = O.RuneBarAngleMin,
        max = O.RuneBarAngleMax,
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
        min = O.RuneBarPaddingMin,
        max = O.RuneBarPaddingMax,
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
        min = O.RuneBarSizeMin,
        max = O.RuneBarSizeMax,
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
            min = O.RuneEnergizeTimeMin,
            max = O.RuneEnergizeTimeMax,
            step = 1,
          },
          Color = CreateColorAllOptions(BarType, 'General.ColorEnergize', 'texture', 2, 'Color'),
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
        min = O.ComboBarPaddingMin,
        max = O.ComboBarPaddingMax,
        step = 1,
      },
      ComboAngle = {
        type = 'range',
        name = 'Combo Rotation',
        order = 2,
        desc = 'Rotates the combo bar',
        min = O.ComboBarAngleMin,
        max = O.ComboBarAngleMax,
        step = 45,
      },
      ComboFadeInTime = {
        type = 'range',
        name = 'Combo Fade-in',
        order = 3,
        desc = 'The amount of time in seconds to fade in a combo point',
        min = O.ComboBarFadeInMin,
        max = O.ComboBarFadeInMax,
        step = 0.10,
      },
      ComboFadeOutTime = {
        type = 'range',
        name = 'Combo Fade-out',
        order = 4,
        desc = 'The amount of time in seconds to fade out a combo point',
        min = O.ComboBarFadeOutMin,
        max = O.ComboBarFadeOutMax,
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
        min = O.HolyBarPaddingMin,
        max = O.HolyBarPaddingMax,
        step = 1,
      },
      HolyAngle = {
        type = 'range',
        name = 'Holy Rotation',
        order = 3,
        desc = 'Rotates the holy bar',
        min = O.HolyBarAngleMin,
        max = O.HolyBarAngleMax,
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
        min = O.HolyBarSizeMin,
        max = O.HolyBarSizeMax,
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
        min = O.HolyBarScaleMin,
        max = O.HolyBarScaleMax,
        step = 0.01,
        isPercent = true,
      },
      HolyFadeInTime = {
        type = 'range',
        name = 'Holy Fade-in',
        order = 6,
        desc = 'The amount of time in seconds to fade in a holy rune',
        min = O.HolyBarFadeInMin,
        max = O.HolyBarFadeInMax,
        step = 0.10,
      },
      HolyFadeOutTime = {
        type = 'range',
        name = 'Holy Fade-out',
        order = 7,
        desc = 'The amount of time in seconds to fade out a holy rune',
        min = O.HolyBarFadeOutMin,
        max = O.HolyBarFadeOutMax,
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
        min = O.ShardBarPaddingMin,
        max = O.ShardBarPaddingMax,
        step = 1,
      },
      ShardAngle = {
        type = 'range',
        name = 'Shard Rotation',
        order = 3,
        desc = 'Rotates the shard bar',
        min = O.ShardBarAngleMin,
        max = O.ShardBarAngleMax,
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
        min = O.ShardBarSizeMin,
        max = O.ShardBarSizeMax,
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
        min = O.ShardBarScaleMin,
        max = O.ShardBarScaleMax,
        step = 0.01,
        isPercent = true,
      },
      ShardFadeInTime = {
        type = 'range',
        name = 'Shard Fade-in',
        order = 6,
        desc = 'The amount of time in seconds to fade in a soul shard',
        min = O.ShardBarFadeInMin,
        max = O.ShardBarFadeInMax,
        step = 0.10,
      },
      ShardFadeOutTime = {
        type = 'range',
        name = 'Shard Fade-out',
        order = 7,
        desc = 'The amount of time in seconds to fade out a soul shard',
        min = O.ShardBarFadeOutMin,
        max = O.ShardBarFadeOutMax,
        step = 1,
      },
    },
  }
  return ShardBarOptions
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
      ReverseFill = {
        type = 'toggle',
        name = 'Reverse fill',
        order = 2,
        desc = 'Reverse fill. In box mode this option can be found under "Bar"',
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        get = function()
                return UBF.UnitBar.Bar.ReverseFill
              end,
        set = function(Info, Value)
                UBF.UnitBar.Bar.ReverseFill = Value

                -- Set reverse fill to the bar.
                UBF:SetAttr('bar', 'texture')

                -- Update the bar.
                UBF:Update()
              end,
      },
    },
  }

  return DemonicBarOptions
end

-------------------------------------------------------------------------------
-- CreateEmberBarOptions
--
-- Creates options for a soul ember bar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: EmberBarOptions = CreateEmberBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- EmberBarOptions       Options table for the ember bar.
-------------------------------------------------------------------------------
local function CreateEmberBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local EmberBarOptions = {
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

            if KeyName == 'GreenFireAuto' or KeyName == 'GreenFire' then

              -- need to call Update() since that has the green fire auto detection.
              UBF:Update()
            else

              -- Update the layout to show changes.
              UBF:SetLayout()
            end
          end,
    args = {
      BoxMode = {
        type = 'toggle',
        name = 'Box Mode',
        order = 1,
        desc = 'If checked, this bar will show boxes instead of textures',
      },
      ReverseFill = {
        type = 'toggle',
        name = 'Reverse fill',
        order = 2,
        desc = 'Reverse fill. In box mode this option can be found under "Bar"',
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        get = function()
                return UBF.UnitBar.Bar.ReverseFill
              end,
        set = function(Info, Value)
                UBF.UnitBar.Bar.ReverseFill = Value

                -- Set reverse fill to the bar.
                UBF:SetAttr('bar', 'texture')

                -- Update the bar.
                UBF:Update()
              end,
      },
      GreenFire = {
        type = 'toggle',
        name = 'Green Fire',
        order = 3,
        desc = 'If checked will use green fire',
        disabled = function()
                     return UBF.UnitBar.General.GreenFireAuto
                   end,
      },
      GreenFireAuto = {
        type = 'toggle',
        name = 'Green Fire Auto',
        order = 4,
        desc = 'If checked will use green fire if available',
        disabled = function()
                     return UBF.UnitBar.General.GreenFire
                   end,
      },
      Spacer10 = CreateSpacer(10),
      EmberPadding = {
        type = 'range',
        name = 'Ember Padding',
        order = 11,
        desc = 'Set the Amount of space between each burning ember',
        min = O.EmberBarPaddingMin,
        max = O.EmberBarPaddingMax,
        step = 1,
      },
      EmberAngle = {
        type = 'range',
        name = 'Ember Rotation',
        order = 12,
        desc = 'Rotates the ember bar',
        min = O.EmberBarAngleMin,
        max = O.EmberBarAngleMax,
        step = 45,
      },
      EmberSize = {
        type = 'range',
        name = 'Ember Size',
        order = 13,
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        desc = 'Sets the size of all the burning embers',
        min = O.EmberBarSizeMin,
        max = O.EmberBarSizeMax,
        step = 0.01,
        isPercent = true
      },
      EmberScale = {
        type = 'range',
        name = 'Ember Scale',
        order = 14,
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        desc = 'Sets the scale of all the burning embers',
        min = O.EmberBarScaleMin,
        max = O.EmberBarScaleMax,
        step = 0.01,
        isPercent = true,
      },
      FieryEmberFadeInTime = {
        type = 'range',
        name = 'Fiery Ember Fade-in',
        order = 15,
        desc = 'The amount of time in seconds to fade in the fiery embers',
        min = O.EmberBarFieryFadeInMin,
        max = O.EmberBarFieryFadeInMax,
        step = 0.10,
      },
      FieryEmberFadeOutTime = {
        type = 'range',
        name = 'Fiery Ember Fade-out',
        order = 16,
        desc = 'The amount of time in seconds to fade out the fiery embers',
        min = O.EmberBarFieryFadeOutMin,
        max = O.EmberBarFieryFadeOutMax,
        step = 1,
      },
    },
  }
  return EmberBarOptions
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
      HideSlider = {
        type = 'toggle',
        name = 'Hide Slider',
        order = 2,
        desc = 'If checked, the slider will be hidden',
      },
      BarHalfLit = {
        type = 'toggle',
        name = 'Bar Half Lit',
        order = 3,
        desc = 'If checked, half the bar becomes lit to show the slider direction',
      },
      PowerText = {
        type = 'toggle',
        name = 'Power Text',
        order = 4,
        desc = 'If checked, then eclipse power text will be shown',
      },
      PredictedPower = {
        type = 'toggle',
        name = 'Predicted Power',
        order = 5,
        desc = 'If checked, the energy from wrath, starfire and starsurge will be shown ahead of time. Predicted options group will open up below when checked',
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
          PredictedBarHalfLit = {
            type = 'toggle',
            name = 'Bar Half Lit',
            order = 1,
            desc = 'If checked, bar half lit is based on predicted power',
            disabled = function()
                         return not UBF.UnitBar.General.BarHalfLit
                       end,
          },
          PredictedPowerText = {
            type = 'toggle',
            name = 'Power Text',
            order = 2,
            desc = 'If checked, predicted power text will be shown instead',
          },
          PredictedEclipse = {
            type = 'toggle',
            name = 'Eclipse',
            order = 3,
            desc = 'If checked, the sun or moon will light up based on predicted power',
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
      EclipseAngle = {
        type = 'range',
        name = 'Eclipse Rotation',
        order = 22,
        desc = 'Rotates the eclipse bar',
        min = O.EclipseAngleMin,
        max = O.EclipseAngleMax,
        step = 90,
      },
      Spacer30 = CreateSpacer(40),
      SunOffsetX = {
        type = 'range',
        name = 'Sun Horizontal Offset',
        order = 31,
        desc = 'Offsets the horizontal position of the sun',
        min = O.EclipseSunOffsetXMin,
        max = O.EclipseSunOffsetXMax,
        step = 1,
      },
      SunOffsetY = {
        type = 'range',
        name = 'Sun Vertical Offset',
        order = 32,
        desc = 'Offsets the horizontal position of the sun',
        min = O.EclipseSunOffsetYMin,
        max = O.EclipseSunOffsetYMax,
        step = 1,
      },
      Spacer40 = CreateSpacer(50),
      MoonOffsetX = {
        type = 'range',
        name = 'Moon Horizontal Offset',
        order = 41,
        desc = 'Offsets the horizontal position of the moon',
        min = O.EclipseMoonOffsetXMin,
        max = O.EclipseMoonOffsetXMax,
        step = 1,
      },
      MoonOffsetY = {
        type = 'range',
        name = 'Moon Vertical Offset',
        order = 42,
        desc = 'Offsets the horizontal position of the moon',
        min = O.EclipseMoonOffsetYMin,
        max = O.EclipseMoonOffsetYMax,
        step = 1,
      },
      Spacer50 = CreateSpacer(30),
      EclipseFadeInTime = {
        type = 'range',
        name = 'Eclipse Fade-in',
        order = 51,
        desc = 'The amount of time in seconds to fade in the sun, moon, and bar half lit',
        min = O.EclipseBarFadeInMin,
        max = O.EclipseBarFadeInMax,
        step = 0.10,
      },
      EclipseFadeOutTime = {
        type = 'range',
        name = 'Eclipse Fade-out',
        order = 52,
        desc = 'The amount of time in seconds to fade out the sun, moon, and bar half lit',
        min = O.EclipseBarFadeOutMin,
        max = O.EclipseBarFadeOutMax,
        step = 1,
      },
    },
  }
  return EclipseBarOptions
end

-------------------------------------------------------------------------------
-- CreateShadowBarOptions
--
-- Creates options for a soul shadow bar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: ShadowBarOptions = CreateShadowBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- ShadowBarOptions       Options table for the shadow bar.
-------------------------------------------------------------------------------
local function CreateShadowBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local ShadowBarOptions = {
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
      ShadowPadding = {
        type = 'range',
        name = 'Shadow Padding',
        order = 2,
        desc = 'Set the Amount of space between each shadow orb',
        min = O.ShadowBarPaddingMin,
        max = O.ShadowBarPaddingMax,
        step = 1,
      },
      ShadowAngle = {
        type = 'range',
        name = 'Shadow Rotation',
        order = 3,
        desc = 'Rotates the shadow bar',
        min = O.ShadowBarAngleMin,
        max = O.ShadowBarAngleMax,
        step = 45,
      },
      ShadowSize = {
        type = 'range',
        name = 'Shadow Size',
        order = 4,
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        desc = 'Sets the size of all the shadow orbs',
        min = O.ShadowBarSizeMin,
        max = O.ShadowBarSizeMax,
        step = 0.01,
        isPercent = true
      },
      ShadowScale = {
        type = 'range',
        name = 'Shadow Scale',
        order = 5,
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        desc = 'Sets the scale of all the shadow orbs',
        min = O.ShadowBarScaleMin,
        max = O.ShadowBarScaleMax,
        step = 0.01,
        isPercent = true,
      },
      ShadowFadeInTime = {
        type = 'range',
        name = 'Shadow Fade-in',
        order = 6,
        desc = 'The amount of time in seconds to fade in a shadow orb',
        min = O.ShadowBarFadeInMin,
        max = O.ShadowBarFadeInMax,
        step = 0.10,
      },
      ShadowFadeOutTime = {
        type = 'range',
        name = 'Shadow Fade-out',
        order = 7,
        desc = 'The amount of time in seconds to fade out a shadow orb',
        min = O.ShadowBarFadeOutMin,
        max = O.ShadowBarFadeOutMax,
        step = 1,
      },
    },
  }
  return ShadowBarOptions
end

-------------------------------------------------------------------------------
-- CreateChiBarOptions
--
-- Creates options for a soul chi bar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- Usage: ChiBarOptions = CreateChiBarOptions(BarType, Order, Name)
--
-- BarType               Type of options being created.
-- Order                 Order number.
-- Name                  Name text
--
-- ChiBarOptions       Options table for the chi bar.
-------------------------------------------------------------------------------
local function CreateChiBarOptions(BarType, Order, Name)
  local UBF = UnitBarsF[BarType]

  local ChiBarOptions = {
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
      ChiPadding = {
        type = 'range',
        name = 'Chi Padding',
        order = 2,
        desc = 'Set the Amount of space between each chi orb',
        min = O.ChiBarPaddingMin,
        max = O.ChiBarPaddingMax,
        step = 1,
      },
      ChiAngle = {
        type = 'range',
        name = 'Chi Rotation',
        order = 3,
        desc = 'Rotates the chi bar',
        min = O.ChiBarAngleMin,
        max = O.ChiBarAngleMax,
        step = 45,
      },
      ChiSize = {
        type = 'range',
        name = 'Chi Size',
        order = 4,
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        desc = 'Sets the size of all the chi orbs',
        min = O.ChiBarSizeMin,
        max = O.ChiBarSizeMax,
        step = 0.01,
        isPercent = true
      },
      ChiScale = {
        type = 'range',
        name = 'Chi Scale',
        order = 5,
        hidden = function()
                   return UBF.UnitBar.General.BoxMode
                 end,
        desc = 'Sets the scale of all the chi orbs',
        min = O.ChiBarScaleMin,
        max = O.ChiBarScaleMax,
        step = 0.01,
        isPercent = true,
      },
      ChiFadeInTime = {
        type = 'range',
        name = 'Chi Fade-in',
        order = 6,
        desc = 'The amount of time in seconds to fade in a chi orb',
        min = O.ChiBarFadeInMin,
        max = O.ChiBarFadeInMax,
        step = 0.10,
      },
      ChiFadeOutTime = {
        type = 'range',
        name = 'Chi Fade-out',
        order = 7,
        desc = 'The amount of time in seconds to fade out a chi orb',
        min = O.ChiBarFadeOutMin,
        max = O.ChiBarFadeOutMax,
        step = 1,
      },
    },
  }
  return ChiBarOptions
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

  CapButtons = CapButtons or {
    {Name = 'All'     , Order = 1,  All = false, Type = 'All',        TablePath = ''},
    {Name = 'Status'  , Order = 2,  All = true,  Type = 'Status',     TablePath = 'Status'},
    {Name = 'Other'   , Order = 3,  All = true,  Type = 'Other',      TablePath = 'Other'},
    {Name = 'BackG'   , Order = 4,  All = true,  Type = 'Background', TablePath = 'Background'},
    {Name = 'Bar'     , Order = 5,  All = true,  Type = 'Bar',        TablePath = 'Bar'},
    {Name = 'All Text', Order = 6,  All = true,  Type = 'TextAll',    TablePath = 'Text'},
    {Name = 'Text 1'  , Order = 7,  All = false, Type = 'Text',       TablePath = 'Text.1'},
    {Name = 'Text 2'  , Order = 8,  All = false, Type = 'Text',       TablePath = 'Text.2'},
    {Name = 'Text 3'  , Order = 9,  All = false, Type = 'Text',       TablePath = 'Text.3'},
    {Name = 'Text 4'  , Order = 10, All = false, Type = 'Text',       TablePath = 'Text.4'},
    {Name = 'Spacer'  , Order = 20},
    {Name = 'Clear'   , Order = 21},
  }

  local CopyPasteOptions = {
    type = 'group',
    name = function()
             if CapName and CapTablePath then

               return format('Copy and Paste: |cffffff00%s [ %s ]|r', CapName, CapTablePath == '' and CapType or CapTablePath)
             else
               return 'Copy and Paste'
             end
           end,
    dialogInline = true,
    order = Order,
    confirm = function(Info)
                if Info[#Info] ~= 'Clear' and CapBarType then
                  return format('Copy %s from %s to %s', CapTablePath == '' and CapType or CapTablePath, CapName, UnitBars[BarType].Name)
                end
              end,
    func = function(Info, Value)
             local Name = Info[#Info]

             if Name ~= 'Clear' then
               if CapBarType == nil then

                 -- Store the data to the clipboard.
                 CapBarType = BarType
                 CapName = UBF.UnitBar.Name
                 CapTablePath = Info.arg.TablePath
                 CapType = Info.arg.Type
               else

                 -- Save name and locaton.
                 local UB = UBF.UnitBar
                 local Name = UB.Name
                 local x, y = UB.x, UB.y

                 if CapType == 'All' then
                   for _, Value in ipairs(CapButtons) do
                     if Value.All then

                       -- Copy unit bar
                       local TablePath = Value.TablePath
                       Main:CopyUnitBar(CapBarType, BarType, TablePath, TablePath)
                     end
                   end
                 else
                   Main:CopyUnitBar(CapBarType, BarType, CapTablePath, Info.arg.TablePath)
                 end

                 -- Restore name and location.
                 UB.Name = Name
                 UB.x, UB.y = x, y

                 GUB.ProfileUpdate = true

                 -- Update the layout.
                 UBF:SetLayout()
                 UBF:StatusCheck()
                 UBF:Update()

                 GUB.ProfileUpdate = false

                 -- Update any dynamic options.
                 SetFunction()
               end
             else
               CapBarType = nil
               CapName = nil
               CapTablePath = nil
               CapType = nil
             end
           end,

    -- The args get converted into controls below.
    args = {},
  }

  local Args = CopyPasteOptions.args

  for _, Value in ipairs(CapButtons) do
    local t = {}
    local Order = Value.Order
    local Name = Value.Name

    if Name ~= 'Spacer' then
      t.type = 'execute'
      t.name = Name
      t.order = Order
      t.width = 'half'

      if Name == 'BackG' then
        t.desc = 'Background'
      end

      if Name == 'Clear' then

        -- Disable clear if theres nothing to paste.
        t.disabled = function()
                       return HideTooltip(CapBarType == nil)
                     end
      else
        t.arg = {Type = Value.Type, TablePath = Value.TablePath}

        -- Disable the button if in paste mode.
        t.disabled = function(Info)
                       local Disable = false
                       local Dest = Main:GetVP(BarType, Info.arg.TablePath)

                       if Dest == nil then
                         Disable = true
                       elseif CapBarType then
                         if CapType ~= Info.arg.Type or Main:GetVP(CapBarType, CapTablePath) == Dest then
                           Disable = true
                         end
                       end

                       return HideTooltip(Disable)
                     end
      end
      Args[Name] = t
    else

      -- create spacer
      Args[Name] = CreateSpacer(Order)
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
    hidden = function()
               return not UBF.UnitBar.Enabled
             end,
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

                -- Update the status of all bars.
                GUB:UnitBarsUpdateStatus()
              end,
        args = {
          HideNotUsable = {
            type = 'toggle',
            name = 'Hide not Usable',
            disabled = function()
                         return UBF.UnitBar.Status.HideNotUsable == nil
                       end,
            order = 1,
            desc = 'Hides the bar if it can not be used by your class or spec.  Bar will stay hidden even with bars unlocked',
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
            desc = "Hides the bar when you're in a vehicle",
          },
          HideInPetBattle = {
            type = 'toggle',
            name = 'Hide in Pet Battle',
            order = 4,
            desc = "Hides the bar when you're in a pet battle",
          },
          HideNotActive = {
            type = 'toggle',
            name = 'Hide not Active',
            disabled = function()
                         return BarType == 'EclipseBar'
                       end,
            order = 5,
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

  -- Add demonicbar options
  elseif BarType == 'DemonicBar' then
    UBOA.DemonicBar = CreateDemonicBarOptions(BarType, 2, 'General')

  -- Add emberbar options
  elseif BarType == 'EmberBar' then
    UBOA.ShardBar = CreateEmberBarOptions(BarType, 2, 'General')

  -- Add eclipsebar options
  elseif BarType == 'EclipseBar' then
    UBOA.EclipseBar = CreateEclipseBarOptions(BarType, 2, 'General')

  -- Add shadowbar options
  elseif BarType == 'ShadowBar' then
    UBOA.ShardBar = CreateShadowBarOptions(BarType, 2, 'General')

  -- Add chibar options
  elseif BarType == 'ChiBar' then
    UBOA.ChiBar = CreateChiBarOptions(BarType, 2, 'General')

  -- Add health and power bar options
  elseif BarType == 'PlayerPower' and PlayerClass == 'HUNTER' or strfind(BarType, 'Power') == nil then
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
        min = O.UnitBarScaleMin,
        max = O.UnitBarScaleMax,
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

                 UB = Main:DeepCopy(Defaults.profile[BarType])
                 UBF.UnitBar = UB
                 UnitBars[BarType] = UB
                 UB.x, UB.y = x, y

                 GUB.ProfileUpdate = true

                 -- Update the layout.
                 UBF:SetLayout()
                 UBF:StatusCheck()
                 UBF:Update()

                 GUB.ProfileUpdate = false

                 -- Update any dynamic options.
                 SetFunction()
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
        Moon = CreateBackgroundOptions(BarType, 'Moon', 1, 'Moon'),
        Sun = CreateBackgroundOptions(BarType, 'Sun', 2, 'Sun'),
        Bar = CreateBackgroundOptions(BarType, 'Bar', 3, 'Bar'),
        Slider = CreateBackgroundOptions(BarType, 'Slider', 4, 'Slider'),
        PredictedSlider = CreateBackgroundOptions(BarType, 'Indicator', 5, 'Indicator'),
      }
    }
    UBOA.Bar = {
      type = 'group',
      name = 'Bar',
      order = 1001,
      childGroups = 'tab',
      args = {
        Moon = CreateBarOptions(BarType, 'Moon', 1, 'Moon'),
        Sun = CreateBarOptions(BarType, 'Sun', 2, 'Sun'),
        Bar = CreateBarOptions(BarType, 'Bar', 3, 'Bar'),
        Slider = CreateBarOptions(BarType, 'Slider', 4, 'Slider'),
        PredictedSlider = CreateBarOptions(BarType, 'Indicator', 5, 'Indicator'),
      }
    }
  else

    -- Add background options
    UBOA.Background = CreateBackgroundOptions(BarType, nil, 1000, 'Background')

    -- add bar options for this bar.
    UBOA.Bar = CreateBarOptions(BarType, nil, 1001, 'Bar')
  end

  -- Add text options
  if BarType ~= 'ComboBar' and BarType ~= 'HolyBar' and BarType ~= 'ShardBar' and
     BarType ~= 'EmberBar' and BarType ~= 'ShadowBar' and BarType ~= 'ChiBar' then

    UBOA.Text = CreateTextOptions(BarType, 1002, 'Text')
  end

  return UnitBarOptions
end

-------------------------------------------------------------------------------
-- CreateEnableUnitBarOptions
--
-- Creates options that let you disable/enable unit bars.
--
-- Usage: CreateEnableUnitBarOptions(Args, Order, Name, Desc)
--
-- Args      Table containing the unitbars.
-- Order     Position in the options list.
-- Name      Name of the options.
-- Desc      Description when mousing over the options name.
-------------------------------------------------------------------------------
local function CreateEnableUnitBarOptions(Args, Order, Name, Desc)
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
        get = function(Info)
                return UnitBars.EnableClass
              end,
        set = function(Info, Value)
                UnitBars.EnableClass = Value
                Main:EnableUnitBars()
              end,
      },
      UnitBarList = {
        type = 'group',
        name = 'Check off the bars you want to enable',
        dialogInline = true,
        disabled = function()
                          return UnitBars.EnableClass
                        end,
        order = 2,
        get = function(Info)
                return UnitBars[Info[#Info]].Enabled
              end,
        set = function(Info, Value)
                UnitBars[Info[#Info]].Enabled = Value

                -- Enable unit bars.
                Main:EnableUnitBars()
              end,
        args = {
          Spacer10 = CreateSpacer(10),
        },
      },
    },
  }

  -- Create enable list
  local EUBOptions = EnableUnitBarOptions.args.UnitBarList.args

  for BarType, BarOptions in pairs(Args) do
    local UBToggle = {}
    UBToggle.type = 'toggle'
    UBToggle.name = BarOptions.name
    UBToggle.order = BarOptions.order * 10

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

  ProfileOptions.order = 100

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
                return UnitBars[Info[#Info]]
              end,
        set = function(Info, Value)
                UnitBars[Info[#Info]] = Value
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
              AlignmentToolEnabled = {
                type = 'toggle',
                name = 'Enable Alignment Tool',
                order = 4,
                desc = 'If unchecked, right clicking a unitbar will not open the alignment tool',
              },
              HideTextHighlight = {
                type = 'toggle',
                name = 'Hide Text Highlight',
                order = 5,
                desc = 'If checked, text will not be highlighted when options is opened',
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
                desc = 'If checked, fading in/out can switch direction smoothly',
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
                        return UnitBars.FadeInTime
                      end,
                set = function(Info, Value)
                        UnitBars.FadeInTime = Value
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
                        return UnitBars.FadeOutTime
                      end,
                set = function(Info, Value)
                        UnitBars.FadeOutTime = Value
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

      -- Main Power group. (druid mana)
      ManaPower = CreateUnitBarOptions('ManaPower', 9, 'Druid|Monk Mana', 'Shown when normal mana bar is not available'),

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

      -- Shardbar group.
      EmberBar = CreateUnitBarOptions('EmberBar', 15, 'Ember Bar', 'Destruction Warlocks only'),

      -- Eclipsebar group.
      EclipseBar = CreateUnitBarOptions('EclipseBar', 16, 'Eclipse Bar', 'Balance Druids only: Shown when in moonkin form or normal form'),

      -- Shadowbar group.
      ShadowBar = CreateUnitBarOptions('ShadowBar', 17, 'Shadow Bar'),

      -- Chibar group.
      ChiBar = CreateUnitBarOptions('ChiBar', 18, 'Chi Bar'),
    },
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
  MainOptionsArgs.Profile = ProfileOptions

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
                 return format('|cffffd200%s   version %s|r', AddonName, AddonVersion)
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

  OptionsToGUB = CreateOptionsToGUB()
  SlashOptions = CreateSlashOptions()
  MainOptions = CreateMainOptions()

  -- Register profile options with aceconfig.
  --LibStub('AceConfig-3.0'):RegisterOptionsTable(AddonProfileName, ProfileOptions)

  -- Register the options panels with aceconfig.
  LibStub('AceConfig-3.0'):RegisterOptionsTable(AddonSlashName, SlashOptions, 'gub')

  -- Register the options panel with aceconfig.
  LibStub('AceConfig-3.0'):RegisterOptionsTable(AddonOptionsName, MainOptions)

  -- Register the options to GUB panel with aceconfig.
  LibStub('AceConfig-3.0'):RegisterOptionsTable(AddonOptionsToGUBName, OptionsToGUB)


  -- Add the options panels to blizz options.
  --MainOptionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(AddonOptionsName, AddonName)
  OptionsToGUBFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(AddonOptionsToGUBName, AddonName)

  -- Add the Profiles UI as a subcategory below the main options.
  --ProfilesOptionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(AddonProfileName, 'Profiles', AddonName)

  -- Create the alignment tool options
  CreateAlignmentToolOptions()
end
