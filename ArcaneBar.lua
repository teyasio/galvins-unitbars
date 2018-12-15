--
-- ArcaneBar.lua
--
-- Displays the mage arcane bar.

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

local UnitPower, UnitPowerMax =
      UnitPower, UnitPowerMax

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains an instance of bar functions for arcane bar.
-------------------------------------------------------------------------------
local MaxArcaneCharges = 4
local Display = false
local Update = false
local NamePrefix = 'Arcane '

-- Powertype constants
local PowerArcane = ConvertPowerType['ARCANE_CHARGES']

-- Arcane charges texture constants
local BoxMode = 1
local TextureMode = 2

local ChangeArcane = 3

local AllTextures = 11

local ArcaneSBar = 10
local ArcaneDarkTexture = 11
local ArcaneLightTexture = 12

local RegionGroup = 6

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
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,            ArcaneSBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,              ArcaneSBar,
    GF = GF },
  { TT.TypeID_BarOffset,             TT.Type_BarOffset,             BoxMode },
  { TT.TypeID_TextureScale,          TT.Type_TextureScale,          AllTextures },
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

local VTs = {'whole', 'Arcane Charges',
             'auras', 'Auras'          }
local Groups = { -- BoxNumber, Name, ValueTypes,
  {1,   'Charge 1',    VTs, TD}, -- 1
  {2,   'Charge 2',    VTs, TD}, -- 2
  {3,   'Charge 3',    VTs, TD}, -- 3
  {4,   'Charge 4',    VTs, TD}, -- 4
  {'a', 'All', {'whole', 'Arcane Charges',
                'state', 'Active',
                'auras', 'Auras'          }, TD}, -- 5
  {'r', 'Region',     VTs, TDregion}, -- 6
}

local ArcaneData = {
  AtlasName = [[Mage-ArcaneCharge]],
  Width = 31, Height = 31,
  DarkAlpha = 0.3
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.ArcaneBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Arcanebar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of arcane charges of the player
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ArcaneBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerArcane

  -- Return if not the correct powertype.
  if PowerType ~= PowerArcane then
    return
  end

  local BBar = self.BBar
  local ArcaneCharges = UnitPower('player', PowerArcane)
  local NumCharges = UnitPowerMax('player', PowerArcane)
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers

  if Main.UnitBars.Testing then
    ArcaneCharges = self.UnitBar.TestMode.ArcaneCharges
  end

  for ArcaneIndex = 1, MaxArcaneCharges do
    BBar:ChangeTexture(ChangeArcane, 'SetHiddenTexture', ArcaneIndex, ArcaneIndex > ArcaneCharges)

    if EnableTriggers then
      BBar:SetTriggers(ArcaneIndex, 'active', ArcaneIndex <= ArcaneCharges)
      BBar:SetTriggers(ArcaneIndex, 'arcane charges', ArcaneCharges)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers(RegionGroup, 'arcane charges', ArcaneCharges)
    BBar:DoTriggers()
  end

  -- Set the IsActive flag.
  self.IsActive = ArcaneCharges > 0

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Arcanebar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the arcane bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ArcaneBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- Enable/disable for border.
  BBar:EnableMouseClicksRegion(Enable)

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the arcanebar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ArcaneBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers',   function(v) BBar:EnableTriggers(v, Groups) Update = true end)
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
    BBar:SO('Layout', 'AnimationType',    function(v) BBar:SetAnimationTexture(0, ArcaneSBar, v)
                                                      BBar:SetAnimationTexture(0, ArcaneLightTexture, v) end)
    BBar:SO('Layout', 'BorderPadding',    function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',         function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',            function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',          function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',     function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'AnimationInTime',  function(v) BBar:SetAnimationDurationTexture(0, ArcaneSBar, 'in', v)
                                                      BBar:SetAnimationDurationTexture(0, ArcaneLightTexture, 'in', v) end)
    BBar:SO('Layout', 'AnimationOutTime', function(v) BBar:SetAnimationDurationTexture(0, ArcaneSBar, 'out', v)
                                                      BBar:SetAnimationDurationTexture(0, ArcaneLightTexture, 'out', v) end)
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

    BBar:SO('Bar', 'StatusBarTexture',  function(v) BBar:SetTexture(0, ArcaneSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',     function(v) BBar:SetRotationTexture(0, ArcaneSBar, v) end)
    BBar:SO('Bar', 'Color',             function(v, UB, OD) BBar:SetColorTexture(OD.Index, ArcaneSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',             function(v) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',           function(v) BBar:SetPaddingTextureFrame(0, BoxMode, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
  end

  -- Do the option.  This will call one of the options above or all.
  BBar:DoOption(TableName, KeyName)

  if Update or Main.UnitBars.Testing then
    self:Update()
    Update = false
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
-- UnitBarF     The unitbar frame which will contain the arcane bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ArcaneBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxArcaneCharges)

  local Names = {}

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, ArcaneSBar, 'statusbar')

  -- Create texture mode.
  BBar:CreateTextureFrame(0, TextureMode, 0)

  BBar:CreateTexture(0, TextureMode, ArcaneDarkTexture, 'texture')
  BBar:CreateTexture(0, TextureMode, ArcaneLightTexture, 'texture')

  BBar:SetAtlasTexture(0, ArcaneDarkTexture, ArcaneData.AtlasName)
  BBar:SetAtlasTexture(0, ArcaneLightTexture, ArcaneData.AtlasName)

  BBar:SetAlphaTexture(0, ArcaneDarkTexture, ArcaneData.DarkAlpha)

  BBar:SetSizeTexture(0, ArcaneDarkTexture, ArcaneData.Width, ArcaneData.Height)
  BBar:SetSizeTexture(0, ArcaneLightTexture, ArcaneData.Width, ArcaneData.Height)

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, ArcaneData.Width, ArcaneData.Height)

  BBar:SetHiddenTexture(0, ArcaneSBar, true)
  BBar:SetHiddenTexture(0, ArcaneDarkTexture, false)

  for ArcaneIndex = 1, MaxArcaneCharges do
    BBar:SetFillTexture(ArcaneIndex, ArcaneSBar, 1)

    local Name = NamePrefix .. Groups[ArcaneIndex][2]

    BBar:SetTooltip(ArcaneIndex, nil, Name)
    Names[ArcaneIndex] = Name
  end

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  BBar:SetChangeTexture(ChangeArcane, ArcaneLightTexture, ArcaneSBar)

  -- Set the texture scale for bar offset triggers.
  BBar:SetScaleAllTexture(0, AllTextures, 1)
  BBar:SetOffsetTextureFrame(0, BoxMode, 0, 0, 0, 0)

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Arcanebar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.ArcaneBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end
