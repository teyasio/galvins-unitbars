--
-- ChiBar.lua
--
-- Displays the monk chi bar.

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
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring =
      strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, PetHasActionBar, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, PetHasActionBar, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapDenied =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapDenied
local UnitName, UnitReaction, UnitGetIncomingHeals, GetRealmName, UnitCanAttack, UnitPlayerControlled, UnitIsPVP =
      UnitName, UnitReaction, UnitGetIncomingHeals, GetRealmName, UnitCanAttack, UnitPlayerControlled, UnitIsPVP
local GetRuneCooldown, GetSpellInfo, GetSpellBookItemInfo, PlaySound, message, UnitCastingInfo, GetSpellPowerCost =
      GetRuneCooldown, GetSpellInfo, GetSpellBookItemInfo, PlaySound, message, UnitCastingInfo, GetSpellPowerCost
local GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID =
      GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, C_TimerAfter, UIParent =
      C_PetBattles, C_Timer.After, UIParent

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the ember bar displayed on screen.
--
-- UnitBarF.ShadowBar                Contains the shadow bar displayed on screen.
--
-- ChiData                           Contains all the data for the chi bar.
--   Texture                         Path name to the texture.
--   TextureWidth, TextureHeight     Width and Height of the orbs in texture mode.
--   [TextureType]
--     Level                         Frame level to display the texture on.
--     Width, Height                 Width and Height of the texture.
--     Left, Right, Top, Bottom      Texcoords inside the Texture that locate each texture.
--
-- OrbSBar                           Texture for orb in box mode.
-- OrbDarkTexture                    Dark texture for orb in texture mode.
-- OrbLightTexture                   Light texture for orb in texture mode.
-- Orbs                              Change texture for OrbSBar and OrbLightTexture
--
-------------------------------------------------------------------------------
local MaxChiOrbs = 6
local ExtraChiOrbStart = 5
local Display = false
local NamePrefix = 'Chi '

-- Powertype constants
local PowerChi = ConvertPowerType['CHI']

-- shadow orbs Texture constants
local BoxMode = 1
local TextureMode = 2

local Orbs = 3

local OrbSBar = 10
local OrbDarkTexture = 20
local OrbLightTexture = 21

local GF = { -- Get function data
  TT.TypeID_ClassColor,  TT.Type_ClassColor,
  TT.TypeID_PowerColor,  TT.Type_PowerColor,
  TT.TypeID_CombatColor, TT.Type_CombatColor,
  TT.TypeID_TaggedColor, TT.Type_TaggedColor,
}

local TD = { -- Trigger data
  { TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,                BoxMode },
  { TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor,           BoxMode,
    GF = GF },
  { TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,            BoxMode },
  { TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,                 BoxMode,
    GF = GF },
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,                      OrbSBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,                        OrbSBar,
    GF = GF },
  { TT.TypeID_BarOffset,             TT.Type_BarOffset,                       BoxMode },
  { TT.TypeID_TextureScale,          TT.Type_TextureScale,                    OrbDarkTexture, OrbLightTexture },
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

local RegionGroup = 8

local VTs = {'whole', 'Chi', 'auras', 'Auras'}
local Groups = { -- BoxNumber, Name, ValueTypes,
  {1,   'Orb 1',    VTs, TD}, -- 1
  {2,   'Orb 2',    VTs, TD}, -- 2
  {3,   'Orb 3',    VTs, TD}, -- 3
  {4,   'Orb 4',    VTs, TD}, -- 4
  {5,   'Orb 5',    VTs, TD}, -- 5
  {6,   'Orb 6',    VTs, TD}, -- 6
  {'a', 'All', {'whole', 'Chi', 'state', 'Active', 'auras', 'Auras'}, TD}, -- 7
  {'r', 'Region',   VTs, TDregion}, -- 8
}

local ChiData = {
  TextureWidth = 21 + 8, TextureHeight = 21 + 8,
  [OrbDarkTexture] = {
    Level = 1,
    Width = 21, Height = 21,
    AtlasName = 'MonkUI-OrbOff',
  },
  [OrbLightTexture] = {
    Level = 2,
    Width = 21, Height = 21,
    AtlasName = 'MonkUI-LightOrb',
  },
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.ChiBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Chibar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of chi orbs of the player
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ChiBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerChi

  -- Return if not the correct powertype.
  if PowerType ~= PowerChi then
    return
  end

  local ChiOrbs = UnitPower('player', PowerChi)
  local NumOrbs = UnitPowerMax('player', PowerChi)
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers

  local BBar = self.BBar

  if Main.UnitBars.Testing then
    local TestMode = self.UnitBar.TestMode

    if TestMode.Ascension then
      NumOrbs = MaxChiOrbs
    else
      NumOrbs = MaxChiOrbs - 1
    end
    ChiOrbs = TestMode.Chi
  end

  -- Check for max chi change
  if NumOrbs ~= self.NumOrbs then
    self.NumOrbs = NumOrbs

    -- Change the number of boxes in the bar.
    for OrbIndex = ExtraChiOrbStart, MaxChiOrbs do
      BBar:SetHidden(OrbIndex, nil, OrbIndex > NumOrbs)
    end

    BBar:Display()
  end

  for OrbIndex = 1, MaxChiOrbs do
    BBar:ChangeTexture(Orbs, 'SetHiddenTexture', OrbIndex, OrbIndex > ChiOrbs)

    if EnableTriggers then
      BBar:SetTriggers(OrbIndex, 'active', OrbIndex <= ChiOrbs)
      BBar:SetTriggers(OrbIndex, 'chi', ChiOrbs)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers(RegionGroup, 'chi', ChiOrbs)
    BBar:DoTriggers()
  end

  -- Set this IsActive flag
  self.IsActive = ChiOrbs > 0

  -- Do a status check.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the chi bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ChiBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- Enable/disable for border.
  BBar:EnableMouseClicksRegion(Enable)

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the chibar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ChiBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers', function(v) BBar:EnableTriggers(v, Groups) Display = true end)

    BBar:SO('Layout', 'BoxMode',       function(v)
      if v then
        -- Box mode
        BBar:ShowRowTextureFrame(BoxMode)
      else
        -- texture mode
        BBar:ShowRowTextureFrame(TextureMode)
      end
      Display = true
    end)
    BBar:SO('Layout', 'HideRegion',    function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'BorderPadding', function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',      function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',         function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',       function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',  function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, OrbSBar, 'in', v)
                                                   BBar:SetFadeTimeTexture(0, OrbLightTexture, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, OrbSBar, 'out', v)
                                                   BBar:SetFadeTimeTexture(0, OrbLightTexture, 'out', v) end)
    BBar:SO('Layout', 'Align',         function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX', function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY', function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',  function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',  function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('Region', 'BgTexture',     function(v) BBar:SetBackdropRegion(v) end)
    BBar:SO('Region', 'BorderTexture', function(v) BBar:SetBackdropBorderRegion(v) end)
    BBar:SO('Region', 'BgTile',        function(v) BBar:SetBackdropTileRegion(v) end)
    BBar:SO('Region', 'BgTileSize',    function(v) BBar:SetBackdropTileSizeRegion(v) end)
    BBar:SO('Region', 'BorderSize',    function(v) BBar:SetBackdropBorderSizeRegion(v) end)
    BBar:SO('Region', 'Padding',       function(v) BBar:SetBackdropPaddingRegion(v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Region', 'Color',         function(v) BBar:SetBackdropColorRegion(v.r, v.g, v.b, v.a) end)
    BBar:SO('Region', 'BorderColor',   function(v, UB)
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

    BBar:SO('Bar', 'StatusBarTexture', function(v) BBar:SetTexture(0, OrbSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v) BBar:SetRotateTexture(0, OrbSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD) BBar:SetColorTexture(OD.Index, OrbSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',            function(v, UB) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v) BBar:SetPaddingTexture(0, OrbSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the chi bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ChiBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxChiOrbs)

  local Names = {}

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, OrbSBar)

  -- Create texture mode.
  for OrbIndex = 1, MaxChiOrbs do
    BBar:CreateTextureFrame(OrbIndex, TextureMode, 0)

    for TextureNumber, CD in pairs(ChiData) do
      if type(TextureNumber) == 'number' then
        BBar:CreateTexture(OrbIndex, TextureMode, 'texture', CD.Level, TextureNumber)
        BBar:SetAtlasTexture(OrbIndex, TextureNumber, CD.AtlasName)
        BBar:SetSizeTexture(OrbIndex, TextureNumber, CD.Width, CD.Height)
      end
    end
    local Name = NamePrefix .. Groups[OrbIndex][2]

    BBar:SetTooltip(OrbIndex, nil, Name)
    Names[OrbIndex] = Name
  end

  BBar:SetHiddenTexture(0, OrbSBar, true)
  BBar:SetHiddenTexture(0, OrbDarkTexture, false)

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, ChiData.TextureWidth, ChiData.TextureHeight)

  BBar:SetChangeTexture(Orbs, OrbLightTexture, OrbSBar)

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  -- Set the texture scale for bar offset triggers.
  BBar:SetScaleTexture(0, OrbDarkTexture, 1)
  BBar:SetScaleTexture(0, OrbLightTexture, 1)
  BBar:SetOffsetTextureFrame(0, BoxMode, 0, 0, 0, 0)

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Chibar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.ChiBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end

