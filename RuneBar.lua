--
-- RuneBar.lua
--
-- Displays a runebar similiar to blizzards runebar.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local TT = GUB.DefaultUB.TriggerTypes

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

-- temp fix till blizzard fixes GetRuneCooldown() from crashing client if you're not a death knight
local GetRuneCooldown1 = GetRuneCooldown

local function GetRuneCooldown(RuneIndex)
  if Main.PlayerClass ~= 'DEATHKNIGHT' then
    return 0, 0, true
  else
    return GetRuneCooldown1(RuneIndex)
  end
end

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the holy bar displayed on screen.
-- UnitBarF.LastDuration             Keeps track of each runes last duration
-- UnitBarF.EnergizeTimers           Keeps track of the amount of time to show an energize frame.
--
-- Color, BorderColor                Flag used to determin if any color should be changed.
--
-- BarMode                           Used to show bars.
-- RuneMode                          Used to show runes.
-- RuneSBar                          Texture used for bars.
-- RuneEnergizeSBar                  Border used for energize for bars.
-- RuneTexture                       Texture used for runes.
-- RuneBorderTexture                 Rune border used to show above the rune texture.
-- RuneEnergizeBorder                Border to show around the rune texture for energize.
--
-- RuneTextureData                   Contains information for runes.
--   Width, Height                   Width and Height of the runes.
--   Border                          Border texture that surrounds a rune.
--   BorderEnergize                  Same as border, except only shown during energize.
--   Background                      Texture of the rune its self.
--   CDwidth, CDheight               Multiplier to make the cooldown animation fit the rune size.
--
-- BarEnergizeBorder                 Border texture used to show an energize border for the bars.
-------------------------------------------------------------------------------
local MaxRunes = 6
local Display = false
local Update = false
local Color = false

-- Rune type constants.
local RuneBlood = 1
local RuneUnholy = 2
local RuneFrost = 3
local RuneDeath = 4

local BarMode = 1
local RuneMode = 2

local RuneSBar = 10
local RuneEnergizeSBar = 11
local RuneTexture = 20
local RuneBorderTexture = 21
local RuneEnergizeTexture = 22

local RegionGroup = 8

local GF = { -- Get function data
  TT.TypeID_ClassColor,  TT.Type_ClassColor,
  TT.TypeID_PowerColor,  TT.Type_PowerColor,
  TT.TypeID_CombatColor, TT.Type_CombatColor,
  TT.TypeID_TaggedColor, TT.Type_TaggedColor,
}

local TD = { -- Trigger data
  { TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,      BarMode },
  { TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor, BarMode,
    GF = GF },
  { TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,  BarMode },
  { TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,       BarMode,
    GF = GF },
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,            RuneSBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,              RuneSBar,
    GF = GF },
  { TT.TypeID_BarOffset,             TT.Type_BarOffset,             BarMode },
  { TT.TypeID_TextureScale,          TT.Type_TextureScale,          RuneTexture, RuneBorderTexture, RuneEnergizeTexture },
  { TT.TypeID_TextFontColor,         TT.Type_TextFontColor,
    GF = GF },
  { TT.TypeID_TextFontOffset,        TT.Type_TextFontOffset },
  { TT.TypeID_TextFontSize,          TT.Type_TextFontSize },
  { TT.TypeID_TextFontType,          TT.Type_TextFontType },
  { TT.TypeID_TextFontStyle,         TT.Type_TextFontStyle },
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

local VTs = {'state', 'Recharging', 'state', 'Empowered', 'auras', 'Auras'}
local Groups = { -- BoxNumber, Name, ValueTypes,
  {1,   'Rune 1',    VTs, TD},  -- 1
  {2,   'Rune 2',    VTs, TD},  -- 2
  {3,   'Rune 3',    VTs, TD},  -- 3
  {4,   'Rune 4',    VTs, TD},  -- 4
  {5,   'Rune 5',    VTs, TD},  -- 5
  {6,   'Rune 6',    VTs, TD},  -- 6
  {'a', 'All Runes', VTs, TD},  -- 7
  {'r', 'Region',    VTs, TDregion},  -- 8
}

local RuneTextureData = {
  Width = 22, Height = 22,

  Border = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Ring]],
  BorderEnergize = [[Interface\Addons\GalvinUnitBars\Textures\GUB_DeathknightRingEnergize]],
  BorderColor = { r = 0.6, g = 0.6, b = 0.6, a = 1 },
  Background = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-SingleRune]],
  CDwidth = 0.625,
  CDheight = 0.625,
}

local BarEnergizeBorder = [[Interface\Addons\GalvinUnitBars\Textures\GUB_SquareBorder.tga]]
local BarEnergizeBorderSize = 12

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.RuneBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Runebar utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- DoEnergize
--
-- Shows an energize border for a period of time.
--
-- RuneBar     Bar to use.
-- RuneIndex   Rune to show a border around.
-------------------------------------------------------------------------------
local function DoEnergizeTimer(self)
  local BBar = self.BBar
  local RuneIndex = self.RuneIndex

  BBar:SetHiddenTexture(RuneIndex, RuneEnergizeSBar, true)
  BBar:SetHiddenTexture(RuneIndex, RuneEnergizeTexture, true)

  if self.Layout.EnableTriggers then
    BBar:SetTriggers(RuneIndex, 'off')
    BBar:SetTriggers(RegionGroup, 'off')
    BBar:SetTriggers(RuneIndex, 'empowered', false)
    BBar:SetTriggers(RegionGroup, 'empowered', false)
    BBar:DoTriggers()
  end
  self.Energized = false
  Main:SetTimer(self, nil)
end

local function DoEnergize(RuneBar, RuneIndex)
  local BBar = RuneBar.BBar
  local UB = RuneBar.UnitBar
  local Gen = UB.General
  local EnergizeShow = Gen.EnergizeShow
  local EnergizeTimers = RuneBar.EnergizeTimers
  local EnergizeTimer = EnergizeTimers[RuneIndex]

  if EnergizeTimer == nil then
    EnergizeTimer = {}
    EnergizeTimers[RuneIndex] = EnergizeTimer
  end

  EnergizeTimer.BBar = BBar
  EnergizeTimer.RuneIndex = RuneIndex
  EnergizeTimer.Layout = UB.Layout
  EnergizeTimer.Energized = true

  if strfind(EnergizeShow, 'bar') then
    BBar:SetHiddenTexture(RuneIndex, RuneEnergizeSBar, false)
  end
  if strfind(EnergizeShow, 'rune') then
    BBar:SetHiddenTexture(RuneIndex, RuneEnergizeTexture, false)
  end

  if UB.Layout.EnableTriggers then
    BBar:SetTriggers(RuneIndex, 'empowered', true)
    BBar:SetTriggers(RegionGroup, 'empowered', true)
    BBar:DoTriggers()
  end

  Main:SetTimer(EnergizeTimer, nil)
  Main:SetTimer(EnergizeTimer, DoEnergizeTimer, Gen.EnergizeTime)
end

--*****************************************************************************
--
-- RuneBar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateTestMode
--
-- Display the rune bar in a testmode pattern.
--
-- RuneBar      The runebar to show in test mode.
-- Testing      If true shows the test pattern, if false clears it.
-------------------------------------------------------------------------------
local function UpdateTestMode(RuneBar, Testing)
  local BBar = RuneBar.BBar

  if Testing then
    local UB = RuneBar.UnitBar
    local Layout = UB.Layout
    local HideText = Layout.HideText
    local EnableTriggers = Layout.EnableTriggers
    local TestMode = UB.TestMode
    local Time = TestMode.RuneTime
    local Recharge = TestMode.RuneRecharge
    local Energize = TestMode.RuneEnergize
    local EnergizeShow = UB.General.EnergizeShow
    local ShowEnergize = false

    local TriggerRecharging = false
    local TriggerEnergize = false

    for RuneIndex = 1, MaxRunes do

      if RuneIndex == Energize or Energize > MaxRunes then
        ShowEnergize = true
      else
        ShowEnergize = false
      end

      BBar:SetFillTexture(RuneIndex, RuneSBar, Time, true)

      if not HideText then
        BBar:SetValueFont(RuneIndex, 'time', 10 * Time)
      else
        BBar:SetValueRawFont(RuneIndex, '')
      end

      BBar:SetHiddenTexture(RuneIndex, RuneEnergizeSBar, not ShowEnergize or strfind(EnergizeShow, 'bar') == nil)
      BBar:SetHiddenTexture(RuneIndex, RuneEnergizeTexture, not ShowEnergize or strfind(EnergizeShow, 'rune') == nil)

      if EnableTriggers then
        local Recharge = RuneIndex == Recharge or Recharge > MaxRunes

        if Recharge then
          TriggerRecharging = true
        end
        if ShowEnergize then
          TriggerEnergize = true
        end

        BBar:SetTriggers(RuneIndex, 'recharging', Recharge)
        BBar:SetTriggers(RuneIndex, 'empowered', ShowEnergize)
      end
    end

    if EnableTriggers then
      BBar:SetTriggers(RegionGroup, 'recharging', TriggerRecharging)
      BBar:SetTriggers(RegionGroup, 'empowered', TriggerEnergize)

      BBar:DoTriggers()
    end
  else
    for RuneIndex = 1, MaxRunes do
      BBar:SetFillTexture(RuneIndex, RuneSBar, 0, false)
      BBar:SetTriggers(RuneIndex, 'off')

      BBar:SetHiddenTexture(RuneIndex, RuneEnergizeSBar, true)
      BBar:SetHiddenTexture(RuneIndex, RuneEnergizeTexture, true)
    end
    BBar:SetValueRawFont(0, '')
  end
end

-------------------------------------------------------------------------------
-- StartRuneCooldown
--
-- Start a rune cooldown onevent timer.
--
-- RuneBar    The bar containing the runes.
-- RuneIndex  Current rune to cooldown.
-- Energize   If true then creates a colored border around the frame.
-------------------------------------------------------------------------------
local function StartRuneCooldown(RuneBar, RuneIndex, Energize)
  local UB = RuneBar.UnitBar
  local Layout = UB.Layout
  local Gen = UB.General
  local BBar = RuneBar.BBar
  local LastDuration = RuneBar.LastDuration

  local StartTime, Duration, RuneReady = GetRuneCooldown(RuneIndex)

  if LastDuration == nil then
    LastDuration = {}
    RuneBar.LastDuration = LastDuration
  end

  if not RuneReady and not Energize then

    -- Start bar timer.
    if strfind(Gen.RuneMode, 'bar') then
      local LastDuration = LastDuration[RuneIndex]

      -- To prevent stutter only start the bar animation if its first time.
      -- or change the bars animation starttime if it hasn't already started.
      if StartTime >= GetTime() or LastDuration == nil or LastDuration == false then
        BBar:SetFillTimeTexture(RuneIndex, RuneSBar, StartTime, Duration, 0, 1)

      -- If the bar already started and the duration has changed then
      -- change it, this gives a stutter free bar animation.
      elseif LastDuration ~= Duration then
        BBar:SetFillTimeDurationTexture(RuneIndex, RuneSBar, Duration)
      end
    end
    if Gen.CooldownAnimation and strfind(Gen.RuneMode, 'rune') then
      BBar:SetCooldownTexture(RuneIndex, RuneTexture, StartTime, Duration, Gen.CooldownLine, Gen.HideCooldownFlash)
    end
    if not Layout.HideText then
      BBar:SetValueTimeFont(RuneIndex, StartTime, Duration, Duration, -1)
    end

    LastDuration[RuneIndex] = Duration
  else
    -- stop timer and text.
    if strfind(Gen.RuneMode, 'bar') then
      BBar:SetFillTimeTexture(RuneIndex, RuneSBar)
      BBar:SetFillTexture(RuneIndex, RuneSBar, 0)
    end
    if not Layout.HideText then
      BBar:SetValueTimeFont(RuneIndex)
    end
    if Energize then
      DoEnergize(RuneBar, RuneIndex)
      if Gen.CooldownAnimation and strfind(Gen.RuneMode, 'rune') then

        -- stop the current rune cooldown.
        BBar:SetCooldownTexture(RuneIndex, RuneTexture)
      end
    end
    LastDuration[RuneIndex] = false
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Event                    Event that called this function.  If nil then it wasn't called by an event.
--                          True bypasses visible and isactive flags.
-- ...        RuneIndex     RuneIndex from 1 to MaxRunes.
-- ...        RuneReady     True the rune is not on cooldown.  Otherwise false.
-------------------------------------------------------------------------------
function Main.UnitBarsF.RuneBar:Update(Event, ...)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  -- Check for testmode.
  local Testing = Main.UnitBars.Testing
  if Testing or self.Testing then
    self.Testing = Testing
    UpdateTestMode(self, Testing)
    if Testing then
      return
    end
  end

  -- Update rune bar if this is the first call since reloadui or logging in.
  if self.FirstTime then
    self.FirstTime = false
    for RuneIndex = 1, MaxRunes do
      StartRuneCooldown(self, RuneIndex, false)
    end
  end

  local RuneIndex = select(1, ...)
  local Energize = false

  if RuneIndex and RuneIndex > 0 and RuneIndex <= MaxRunes then
    Energize = select(2, ...) or false
    StartRuneCooldown(self, RuneIndex, Energize)
  end

  -- Calculate active status.
  local BBar = self.BBar
  local Active = false
  local EnergizeTimers = self.EnergizeTimers

  -- Find any rune that is recharging.
  for RuneIndex = 1, MaxRunes do
    local Start, Duration, RuneReady = GetRuneCooldown(RuneIndex)

    if not RuneReady then
      Active = true
      break
    end
  end

  if self.UnitBar.Layout.EnableTriggers then
    local TriggerRecharging = false

    for RuneIndex = 1, MaxRunes do
      local Start, Duration, RuneReady = GetRuneCooldown(RuneIndex)

      if not RuneReady then
        TriggerRecharging = true
      end

      BBar:SetTriggers(RuneIndex, 'recharging', not RuneReady)

      -- Do this so empowered inverse works.
      local EnergizeTimer = EnergizeTimers[RuneIndex]

      if EnergizeTimer == nil or not EnergizeTimer.Energized then
        BBar:SetTriggers(RuneIndex, 'empowered', false)
      end
    end
    BBar:SetTriggers(RegionGroup, 'recharging', TriggerRecharging)

    BBar:DoTriggers()
  end

  -- Set the IsActive flag.
  self.IsActive = Active

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Runebar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbale mouse clicks for the rune icons.
-------------------------------------------------------------------------------
function Main.UnitBarsF.RuneBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- Enable/disable for border.
  BBar:EnableMouseClicksRegion(Enable)

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr
--
-- Sets different parts of the runebar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.RuneBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then
    BBar:SO('Text', '_Font', function()
      for Index = 1, MaxRunes do
        BBar:UpdateFont(Index)
      end
    end)

    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers', function(v) BBar:EnableTriggers(v, Groups) Update = true end)

    BBar:SO('General', 'RuneMode', function(v)
      BBar:SetHidden(0, BarMode, true)
      BBar:SetHidden(0, RuneMode, true)
      if strfind(v, 'rune') then
        BBar:SetHidden(0, RuneMode, false)
      end
      if strfind(v, 'bar') then
        BBar:SetHidden(0, BarMode, false)
      end
      Display = true
    end)

    BBar:SO('Layout', 'HideRegion',    function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'BorderPadding', function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',   function(v) BBar:SetFillReverseTexture(0, RuneSBar, v) end)
    BBar:SO('Layout', 'HideText',      function(v)
      if v then
        BBar:SetValueTimeFont(0)
      end
    end)
    BBar:SO('Layout', 'Rotation',      function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',         function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',       function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',  function(v) BBar:SetScaleTextureFrame(0, RuneMode, v) Display = true end)
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

    BBar:SO('General', 'BarSpark',      function(v) BBar:SetHiddenSpark(0, RuneSBar, not v) end)
    BBar:SO('General', 'ColorEnergize', function(v, UB, OD) BBar:SetBackdropBorderColorTexture(OD.Index, RuneEnergizeSBar, OD.r, OD.g, OD.b, OD.a)
                                                            BBar:SetColorTexture(OD.Index, RuneEnergizeTexture, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('General', '_RuneLocation', function(v) BBar:SetPointTextureFrame(0, RuneMode, 'CENTER', BarMode, v.RunePosition, v.RuneOffsetX, v.RuneOffsetY) Display = true end)

    BBar:SO('Background', 'BgTexture',     function(v) BBar:SetBackdrop(0, BarMode, v) end)
    BBar:SO('Background', 'BorderTexture', function(v) BBar:SetBackdropBorder(0, BarMode, v) end)
    BBar:SO('Background', 'BgTile',        function(v) BBar:SetBackdropTile(0, BarMode, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v) BBar:SetBackdropTileSize(0, BarMode, v) end)
    BBar:SO('Background', 'BorderSize',    function(v) BBar:SetBackdropBorderSize(0, BarMode, v) end)
    BBar:SO('Background', 'Padding',       function(v) BBar:SetBackdropPadding(0, BarMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v, UB, OD) BBar:SetBackdropColor(OD.Index, BarMode, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB, OD)
      if UB.Background.EnableBorderColor then
        BBar:SetBackdropBorderColor(OD.Index, BarMode, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetBackdropBorderColor(OD.Index, BarMode, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture', function(v) BBar:SetTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'FillDirection',    function(v) BBar:SetFillDirectionTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v) BBar:SetRotateTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD) BBar:SetColorTexture(OD.Index, RuneSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',            function(v, UB) BBar:SetSizeTextureFrame(0, BarMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v) BBar:SetPaddingTexture(0, RuneSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- Creates the main rune bar frame that contains the death knight runes
--
-- UnitBarF     The unitbar frame which will contain the rune bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.RuneBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxRunes)

  local Names = {}
  local Name = nil

  BBar:CreateTextureFrame(0, BarMode, 0)
    BBar:CreateTexture(0, BarMode, 'statusbar', 1, RuneSBar)
    BBar:CreateTexture(0, BarMode, 'statusbar', 2, RuneEnergizeSBar)

    BBar:SetBackdropBorderTexture(0, RuneEnergizeSBar, BarEnergizeBorder, true)
    BBar:SetBackdropBorderSizeTexture(0, RuneEnergizeSBar, BarEnergizeBorderSize)

  local Color = RuneTextureData.BorderColor

  for RuneIndex = 1, MaxRunes do
    BBar:SetFillTexture(RuneIndex, RuneSBar, 0)

    BBar:CreateTextureFrame(RuneIndex, RuneMode, 3)
      BBar:CreateTexture(RuneIndex, RuneMode, 'cooldown', 4, RuneTexture)
      BBar:SetTexture(RuneIndex, RuneTexture, RuneTextureData.Background)
      BBar:SetSizeTexture(RuneIndex, RuneTexture, RuneTextureData.Width, RuneTextureData.Height)
      BBar:SetSizeCooldownTexture(RuneIndex, RuneTexture, RuneTextureData.Width * RuneTextureData.CDwidth,
                                                          RuneTextureData.Height * RuneTextureData.CDheight, 0, 1)

      BBar:CreateTexture(RuneIndex, RuneMode, 'texture', 5, RuneBorderTexture)
      BBar:SetTexture(RuneIndex, RuneBorderTexture, RuneTextureData.Border)
      BBar:SetColorTexture(RuneIndex, RuneBorderTexture, Color.r, Color.g, Color.b, Color.a)
      BBar:SetSizeTexture(RuneIndex, RuneBorderTexture, RuneTextureData.Width, RuneTextureData.Height)

      BBar:CreateTexture(RuneIndex, RuneMode, 'texture', 6, RuneEnergizeTexture)
      BBar:SetTexture(RuneIndex, RuneEnergizeTexture, RuneTextureData.BorderEnergize)
      BBar:SetSizeTexture(RuneIndex, RuneEnergizeTexture, RuneTextureData.Width, RuneTextureData.Height)

      local Name = Groups[RuneIndex][2]
      Names[RuneIndex] = Name
      BBar:SetTooltip(RuneIndex, nil, Name)
  end

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  BBar:SetSizeTextureFrame(0, BarMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, RuneMode, RuneTextureData.Width, RuneTextureData.Height)

  -- Set the texture scale for Texture Size triggers.
  BBar:SetScaleTexture(0, RuneTexture, 1)
  BBar:SetScaleTexture(0, RuneBorderTexture, 1)
  BBar:SetScaleTexture(0, RuneEnergizeTexture, 1)

  BBar:SetHiddenTexture(0, RuneSBar, false)
  BBar:SetHiddenTexture(0, RuneTexture, false)
  BBar:SetHiddenTexture(0, RuneBorderTexture, false)

  BBar:CreateFont(0)

  -- set offset for trigger bar offset.
  BBar:SetOffsetTextureFrame(0, BarMode, 0, 0, 0, 0)

  UnitBarF.FirstTime = true
  UnitBarF.EnergizeTimers = {}
  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Runebar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.RuneBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'RUNE_POWER_UPDATE', self.Update)
end
