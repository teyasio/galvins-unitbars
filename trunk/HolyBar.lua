--
-- HolyBar.lua
--
-- Displays Paladin holy power.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local TT = GUB.DefaultUB.TriggerTypes

local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _, _G =
      _, _G
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt,      mhuge =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt, math.huge
local strfind, strmatch, strsplit, strsub, strtrim, strupper, strlower, format, gsub, gmatch =
      strfind, strmatch, strsplit, strsub, strtrim, strupper, strlower, format, gsub, gmatch
local GetTime, ipairs, pairs, next, pcall, print, select, tonumber, tostring, tremove, tinsert, type, unpack, sort =
      GetTime, ipairs, pairs, next, pcall, print, select, tonumber, tostring, tremove, tinsert, type, unpack, sort

local UnitPower =
      UnitPower

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the holy bar displayed on screen.
-------------------------------------------------------------------------------
local MaxHolyRunes = 5
local Display = false
local NamePrefix = 'Holy '

-- Powertype constants
local PowerHoly = ConvertPowerType['HOLY_POWER']

-- Holyrune Texture constants
local BoxMode = 1
local TextureMode = 2

local ChangeHoly = 3

local HolySBar = 10
local HolyDarkTexture = 12
local HolyLightTexture = 13

local RegionGroup = 7

local GF = { -- Get function data
  TT.TypeID_ClassColor,  TT.Type_ClassColor,
  TT.TypeID_PowerColor,  TT.Type_PowerColor,
  TT.TypeID_CombatColor, TT.Type_CombatColor,
  TT.TypeID_TaggedColor, TT.Type_TaggedColor,
}

local TD = { -- Trigger data
  { TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,      BoxMode },
  { TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor, BoxMode,
    GF = GF },
  { TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,  BoxMode },
  { TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,       BoxMode,
    GF = GF },
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,            HolySBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,              HolySBar,
    GF = GF },
  { TT.TypeID_BarOffset,             TT.Type_BarOffset,             BoxMode },
  { TT.TypeID_TextureScale,          TT.Type_TextureScale,          HolyDarkTexture, HolyLightTexture },
  { TT.TypeID_Sound,                 TT.Type_Sound }
}

local TDregion = { -- Trigger data for region
  { TT.TypeID_RegionBorder,          TT.Type_RegionBorder },
  { TT.TypeID_RegionBorderColor,     TT.Type_RegionBorderColor,
    GF = GF },
  { TT.TypeID_RegionBackground,      TT.Type_RegionBackground },
  { TT.TypeID_RegionBackgroundColor, TT.Type_RegionBackgroundColor,
    GF = GF },
  { TT.TypeID_Sound,                 TT.Type_Sound }
}

local VTs = {'whole', 'Holy Power',
             'auras', 'Auras'      }
local Groups = { -- BoxNumber, Name, ValueTypes,
  {1,   'Rune 1',    VTs, TD}, -- 1
  {2,   'Rune 2',    VTs, TD}, -- 2
  {3,   'Rune 3',    VTs, TD}, -- 3
  {4,   'Rune 4',    VTs, TD}, -- 4
  {5,   'Rune 5',    VTs, TD}, -- 5
  {'a', 'All', {'whole', 'Holy Power',
                'state', 'Active',
                'auras', 'Auras'      }, TD},  -- 6
  {'r', 'Region',         VTs, TDregion}, -- 7
}

local HolyData = {
  Texture = [[Interface\PlayerFrame\PaladinPowerTextures]],

  -- TextureFrame size.
  BoxWidth = 42 + 8, BoxHeight = 31,  -- width and height of the texture frame in texture mode.
  DarkColor = {r = 0.15, g = 0.15, b = 0.15, a = 1},
  { -- 1
    Width = 36 + 5, Height = 22 + 5,
    Left = 0.00390625, Right = 0.14453125, Top = 0.78906250, Bottom = 0.96093750
  },
  { -- 2
    Width = 31 + 14, Height = 17 + 14,
    Left = 0.15234375, Right = 0.27343750, Top = 0.78906250, Bottom = 0.92187500
  },
  { -- 3
    Width = 27 + 10 , Height = 21 + 10,
    Left = 0.28125000, Right = 0.38671875, Top = 0.64843750, Bottom = 0.81250000
  },
  { -- 4 Rune1 texture that's rotated.
    Width = 36 + 5, Height = 17 + 12,
    Left = 0.14453125, Right = 0.00390625, Top = 0.78906250, Bottom = 0.96093750
  },
  { -- 5 Rune2 texture that's rotated.
    Width = 31 + 14, Height = 17 + 14,
    Left = 0.27343750, Right = 0.15234375, Top = 0.78906250, Bottom = 0.92187500
  },
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.HolyBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Holybar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the holy power level of the player
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.HolyBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerHoly

  -- Return if not the correct powertype.
  if PowerType ~= PowerHoly then
    return
  end

  local BBar = self.BBar
  local HolyPower = UnitPower('player', PowerHoly)
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers

  if Main.UnitBars.Testing then
    HolyPower = self.UnitBar.TestMode.HolyPower
  end

  for HolyIndex = 1, MaxHolyRunes do
    if EnableTriggers then
      BBar:SetTriggers(HolyIndex, 'active', HolyIndex <= HolyPower)
      BBar:SetTriggers(HolyIndex, 'holy power', HolyPower)
    end

    BBar:ChangeTexture(ChangeHoly, 'SetHiddenTexture', HolyIndex, HolyIndex > HolyPower)
  end

  if EnableTriggers then
    BBar:SetTriggers(RegionGroup, 'holy power', HolyPower)
    BBar:DoTriggers()
  end

  -- Set this IsActive flag
  self.IsActive = HolyPower > 0

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Holybar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the holy bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.HolyBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- Enable/disable for border.
  BBar:EnableMouseClicksRegion(Enable)

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the holybar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.HolyBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then
    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers',   function(v) BBar:EnableTriggers(v, Groups) Display = true end)
    BBar:SO('Layout', 'BoxMode',          function(v)
      if v then

        -- Box mode
        BBar:ShowRowTextureFrame(BoxMode)
      else
        -- texture mode
        BBar:ShowRowTextureFrame(TextureMode)
      end
      Display = true
    end)
    BBar:SO('Layout', 'HideRegion',       function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',             function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',            function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'AnimationType',    function(v) BBar:SetAnimationTexture(0, HolySBar, v)
                                                      BBar:SetAnimationTexture(0, HolyLightTexture, v) end)
    BBar:SO('Layout', 'BorderPadding',    function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',         function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',            function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',          function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',     function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'AnimationInTime',  function(v) BBar:SetAnimationDurationTexture(0, HolySBar, 'in', v)
                                                      BBar:SetAnimationDurationTexture(0, HolyLightTexture, 'in', v) end)
    BBar:SO('Layout', 'AnimationOutTime', function(v) BBar:SetAnimationDurationTexture(0, HolySBar, 'out', v)
                                                      BBar:SetAnimationDurationTexture(0, HolyLightTexture, 'out', v) end)
    BBar:SO('Layout', 'Align',            function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX',    function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY',    function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',     function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',     function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('Region', 'BgTexture',        function(v) BBar:SetBackdropRegion(v) end)
    BBar:SO('Region', 'BorderTexture',    function(v) BBar:SetBackdropBorderRegion(v) end)
    BBar:SO('Region', 'BgTile',           function(v) BBar:SetBackdropTileRegion(v) end)
    BBar:SO('Region', 'BgTileSize',       function(v) BBar:SetBackdropTileSizeRegion(v) end)
    BBar:SO('Region', 'BorderSize',       function(v) BBar:SetBackdropBorderSizeRegion(v) end)
    BBar:SO('Region', 'Padding',          function(v) BBar:SetBackdropPaddingRegion(v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Region', 'Color',            function(v) BBar:SetBackdropColorRegion(v.r, v.g, v.b, v.a) end)
    BBar:SO('Region', 'BorderColor',      function(v, UB)
      if UB.Region.EnableBorderColor then
        BBar:SetBackdropBorderColorRegion(v.r, v.g, v.b, v.a)
      else
        BBar:SetBackdropBorderColorRegion(nil)
      end
    end)

    BBar:SO('Background', 'BgTexture',     function(v) BBar:SetBackdrop(0, BoxMode, v) end)
    BBar:SO('Background', 'BorderTexture', function(v) BBar:SetBackdropBorder(0, BoxMode, v) end)
    BBar:SO('Background', 'BgTile',        function(v) BBar:SetBackdropTile(0, BoxMode, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v) BBar:SetBackdropTileSize(0, BoxMode, v) end)
    BBar:SO('Background', 'BorderSize',    function(v) BBar:SetBackdropBorderSize(0, BoxMode, v) end)
    BBar:SO('Background', 'Padding',       function(v) BBar:SetBackdropPadding(0, BoxMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v, UB, OD) BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB, OD)
      if UB.Background.EnableBorderColor then
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture', function(v) BBar:SetTexture(0, HolySBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v) BBar:SetRotateTexture(0, HolySBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD) BBar:SetColorTexture(OD.Index, HolySBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',            function(v) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v) BBar:SetPaddingTextureFrame(0, BoxMode, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
  end

  -- Do the option.  This will call one of the options above or all.
  BBar:DoOption(TableName, KeyName)

  if Main.UnitBars.Testing then
    self:Update()
    Display = true
  end

  if Display then
    BBar:Display()
    Display = false
  end
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- UnitBarF     The unitbar frame which will contain the holy rune bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.HolyBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxHolyRunes)

  local Names = {}
  local DarkColor = HolyData.DarkColor

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, HolySBar)

  -- Create texture mode.
  for HolyIndex, HD in ipairs(HolyData) do

    BBar:CreateTextureFrame(HolyIndex, TextureMode, 0)
      BBar:CreateTexture(HolyIndex, TextureMode, 'texture', 1, HolyDarkTexture)
      BBar:CreateTexture(HolyIndex, TextureMode, 'texture', 2, HolyLightTexture)

    BBar:SetTexture(HolyIndex, HolyDarkTexture, HolyData.Texture)
    BBar:SetTexture(HolyIndex, HolyLightTexture, HolyData.Texture)

    BBar:SetSizeTexture(HolyIndex, HolyDarkTexture, HD.Width, HD.Height)
    BBar:SetSizeTexture(HolyIndex, HolyLightTexture, HD.Width, HD.Height)

    BBar:SetCoordTexture(HolyIndex, HolyDarkTexture, HD.Left, HD.Right, HD.Top, HD.Bottom)
    BBar:SetGreyscaleTexture(HolyIndex, HolyDarkTexture, true)
    BBar:SetColorTexture(HolyIndex, HolyDarkTexture, DarkColor.r, DarkColor.g, DarkColor.b, DarkColor.a)

    BBar:SetCoordTexture(HolyIndex, HolyLightTexture, HD.Left, HD.Right, HD.Top, HD.Bottom)

     -- Set and save the name for tooltips for box mode.
    local Name = NamePrefix .. Groups[HolyIndex][2]

    BBar:SetTooltip(HolyIndex, nil, Name)

    Names[HolyIndex] = Name
  end

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, HolyData.BoxWidth, HolyData.BoxHeight)

  -- Set the texture scale for Texture Size triggers.
  BBar:SetScaleTexture(0, HolyDarkTexture, 1)
  BBar:SetScaleTexture(0, HolyLightTexture, 1)
  BBar:SetScaleTextureFrame(0, BoxMode, 1)

  BBar:SetChangeTexture(ChangeHoly, HolyLightTexture, HolySBar)
  BBar:SetHiddenTexture(0, HolyDarkTexture, false)

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  -- Set offset for trigger bar offset
  BBar:SetOffsetTextureFrame(0, BoxMode, 0, 0, 0, 0)

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Holybar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.HolyBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_UPDATE', self.Update, 'player')
end
