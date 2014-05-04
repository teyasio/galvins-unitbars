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

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strupper, strlower, strmatch, format, strconcat, gsub, tonumber =
      strfind, strsplit, strsub, strupper, strlower, strmatch, format, strconcat, gsub, tonumber
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax
local UnitName, UnitGetIncomingHeals, GetRealmName =
      UnitName, UnitGetIncomingHeals, GetRealmName
local GetRuneCooldown, GetRuneType, GetSpellInfo, GetTalentInfo, PlaySound =
      GetRuneCooldown, GetRuneType, GetSpellInfo, GetTalentInfo, PlaySound
local GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, UIParent =
      C_PetBattles, UIParent

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the holy bar displayed on screen.
-- UnitBarF.OnCooldown               Keeps track of each rune being on cooldown.
-- UnitBarF.EnergizeTimers           Keeps track of the amount of time to show an energize frame.
--
-- Display                           Flag used to determin if a Display() call is needed.
-- Color                             Flag used to determin if any color should be changed.
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
--   RuneBlood .. RuneDeath          4 runes that make up the rune bar.
--
-- BarEnergizeBorder                 Backdrop used to show an energize border for the bars.
-------------------------------------------------------------------------------
local MaxRunes = 6
local Display = false
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

local RuneName = {
  [RuneBlood] = 'Blood Rune',
  [RuneUnholy] = 'Unholy Rune',
  [RuneFrost] = 'Frost Rune',
  [RuneDeath] = 'Death Rune',
}

local RuneTextureData = {
  Width = 22, Height = 22,

  Border = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Ring]],
  BorderEnergize = [[Interface\Addons\GalvinUnitBars\Textures\GUB_DeathknightRingEnergize]],

  [RuneBlood]  = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Blood]],  -- 1 and 2
  [RuneUnholy] = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Unholy]], -- 3 and 4
  [RuneFrost]  = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Frost]],  -- 5 and 6
  [RuneDeath]  = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Death]]
}

local BarEnergizeBorder = {
  bgFile   = '',
  edgeFile = [[Interface\Addons\GalvinUnitBars\Textures\GUB_SquareBorder.tga]],
  tile = true,
  tileSize = 16,
  edgeSize = 12,
  insets = {
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.RuneBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Runebar utility
--
--*****************************************************************************

--------------------------------------------------------------------------------
-- ChangeRune
--
-- Changes a runes texture, bar color, and tooltip based on its rune type
--
-- RuneBar           The bar that the runes were created under.
-- RuneIndex         1 to MaxRunes
-- TestModeRuneType  For testmode only.
--------------------------------------------------------------------------------
local function ChangeRune(RuneBar, RuneID, TestModeRuneType)
  local BBar = RuneBar.BBar
  local UB = RuneBar.UnitBar
  local BgColor = UB.Background.Color
  local BarColor = UB.Bar.Color
  local ColorEnergize = UB.General.ColorEnergize
  local RuneType = TestModeRuneType or GetRuneType(RuneID)

  BBar:SetTexture(RuneID, RuneTexture, RuneTextureData[RuneType])

  -- Turn runetype into color index 1 to 8.
  local ColorIndex = RuneType * 2 - RuneID % 2

  local c = BarColor
  if not c.All then
    c = BarColor[ColorIndex]
  end
  BBar:SetColorTexture(RuneID, RuneSBar, c.r, c.g, c.b, c.a)

  c = BgColor
  if not c.All then
    c = BgColor[ColorIndex]
  end
  BBar:SetBackdropColor(RuneID, BarMode, c.r, c.g, c.b, c.a)

  BBar:UpdateFont(RuneID, nil, ColorIndex)

  c = ColorEnergize
  if not c.All then
    c = ColorEnergize[ColorIndex]
  end
  BBar:SetBackdropBorderColorTexture(RuneID, RuneEnergizeSBar, c.r, c.g, c.b, c.a)
  BBar:SetColorTexture(RuneID, RuneEnergizeTexture, c.r, c.g, c.b, c.a)

  BBar:SetTooltip(RuneID, nil, format('%s %s', RuneName[RuneType], 2 - RuneID % 2))
end

-------------------------------------------------------------------------------
-- DoEnergize
--
-- Shows an energize border for a period of time.
--
-- RuneBar   Bar to use.
-- RuneID    Rune to show a border around.
-------------------------------------------------------------------------------
local function DoEnergizeTimer(self, Elapsed)
  if Elapsed > 0 then
    local BBar = self.BBar
    local RuneID = self.RuneID

    BBar:SetHiddenTexture(RuneID, RuneEnergizeSBar, true)
    BBar:SetHiddenTexture(RuneID, RuneEnergizeTexture, true)
    Main:SetTimer(self, nil)
  end
end

local function DoEnergize(RuneBar, RuneID)
  local BBar = RuneBar.BBar
  local Gen = RuneBar.UnitBar.General
  local EnergizeTimers = RuneBar.EnergizeTimers
  local EnergizeShow = Gen.EnergizeShow

  if EnergizeTimers == nil then
    EnergizeTimers = {}
    RuneBar.EnergizeTimers = EnergizeTimers
  end
  local EnergizeTimer = EnergizeTimers[RuneID]

  if EnergizeTimer == nil then
    EnergizeTimer = {}
    EnergizeTimers[RuneID] = EnergizeTimer
  end

  EnergizeTimer.BBar = BBar
  EnergizeTimer.RuneID = RuneID

  if strfind(EnergizeShow, 'bar') then
    BBar:SetHiddenTexture(RuneID, RuneEnergizeSBar, false)
  end
  if strfind(EnergizeShow, 'rune') then
    BBar:SetHiddenTexture(RuneID, RuneEnergizeTexture, false)
  end

  Main:SetTimer(EnergizeTimer, nil)
  Main:SetTimer(EnergizeTimer, Gen.EnergizeTime, DoEnergizeTimer)
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
    local HideText = UB.Layout.HideText
    local TestMode = UB.TestMode
    local ShowDeathRunes = TestMode.ShowDeathRunes
    local ShowEnergize = TestMode.ShowEnergize
    local EnergizeShow = UB.General.EnergizeShow

    for RuneIndex = 1, MaxRunes do
      local RuneType = ceil(RuneIndex / 2)

      BBar:SetFillTexture(RuneIndex, RuneSBar, 0.50, true)

      if ShowDeathRunes and RuneType == RuneBlood then
        RuneType = RuneDeath
      end
      ChangeRune(RuneBar, RuneIndex, RuneType)
      if not HideText then
        BBar:SetValueFont(RuneIndex, nil, 'time', 9)
      else
        BBar:SetValueRawFont(RuneIndex, nil, '')
      end
    end
    BBar:SetHiddenTexture(0, RuneEnergizeSBar, not ShowEnergize or strfind(EnergizeShow, 'bar') == nil)
    BBar:SetHiddenTexture(0, RuneEnergizeTexture, not ShowEnergize or strfind(EnergizeShow, 'rune') == nil)

  else
    for RuneIndex = 1, MaxRunes do
      BBar:SetFillTexture(RuneIndex, RuneSBar, 0, false)
      ChangeRune(RuneBar, RuneIndex)
    end
    BBar:SetHiddenTexture(0, RuneEnergizeSBar, true)
    BBar:SetHiddenTexture(0, RuneEnergizeTexture, true)
    BBar:SetValueRawFont(0, nil, '')
  end
end

-------------------------------------------------------------------------------
-- StartRuneCooldown
--
-- Start a rune cooldown onevent timer.
--
-- RuneBar    The bar containing the runes.
-- StartTime  Start time for the cooldown.
-- Duration   Duration of the cooldown.
-- RuneReady  If true all cooldown timers are stopped, otherwise they're started.
-- Energize   If true then creates a colored border around the frame.
-------------------------------------------------------------------------------
local function StartRuneCooldown(RuneBar, RuneID, StartTime, Duration, RuneReady, Energize)
  local UB = RuneBar.UnitBar
  local Layout = UB.Layout
  local Gen = UB.General
  local BBar = RuneBar.BBar
  local OnCooldown = RuneBar.OnCooldown

  if OnCooldown == nil then
    OnCooldown = {}
    RuneBar.OnCooldown = OnCooldown
  end

  if not RuneReady and not Energize then
    if OnCooldown[RuneID] ~= Duration then -- We do this to make the bars not jitter.  This detects runic corruption.

      -- Start bar timer.
      if strfind(Gen.RuneMode, 'bar') then
        BBar:SetFillTimeTexture(RuneID, RuneSBar, StartTime, Duration, 0, 1)
      end
      if Gen.CooldownAnimation and strfind(Gen.RuneMode, 'rune') then
        BBar:SetCooldownTexture(RuneID, RuneTexture, StartTime, Duration, Gen.CooldownLine, Gen.HideCooldownFlash)
      end
      if not Layout.HideText then
        BBar:SetValueTimeFont(RuneID, nil, StartTime, Duration, Duration, -1)
      end

      OnCooldown[RuneID] = Duration
    end
  else
    -- stop timer and text.
    if strfind(Gen.RuneMode, 'bar') then
      BBar:SetFillTimeTexture(RuneID, RuneSBar)
      BBar:SetFillTexture(RuneID, RuneSBar, 0)
    end
    if not Layout.HideText then
      BBar:SetValueTimeFont(RuneID, nil)
    end
    if Energize then
      DoEnergize(RuneBar, RuneID)
      if Gen.CooldownAnimation and strfind(Gen.RuneMode, 'rune') then

        -- stop the current rune cooldown.
        BBar:SetCooldownTexture(RuneID, RuneTexture)
      end
    end
    OnCooldown[RuneID] = false
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Event                    Rune type event.  If this is not a rune event
--                          function does nothing.
-- ...        RuneID        RuneId from 1 to 6.
-- ...        RuneReady     True the rune is not on cooldown.  Otherwise false.
-------------------------------------------------------------------------------
function Main.UnitBarsF.RuneBar:Update(Event, ...)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible and self.IsActive ~= 0 then
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

  local RuneID = select(1, ...)

  if RuneID then
    if Event == 'RUNE_TYPE_UPDATE' then

      -- Flip between default and death rune textures.
      ChangeRune(self, RuneID)

    -- Update the rune cooldown.
    else  -- RUNE_POWER_UPDATE
      local Energize = select(2, ...)
      local Start, Duration, RuneReady = GetRuneCooldown(RuneID)

      StartRuneCooldown(self, RuneID, Start, Duration, RuneReady, Energize)
    end
  end

  -- Calculate active status.
  local Active = false
  for Index = 1, MaxRunes do
    local Start, Duration, RuneReady = GetRuneCooldown(Index)

    if not RuneReady then
      Active = true
      break
    end
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
    BBar:SO('Text', '_Font', function() Color = true end)
    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

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

    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',   function(v) BBar:SetFillReverseTexture(0, RuneSBar, v) end)
    BBar:SO('Layout', 'HideText',      function(v)
      if v then
        BBar:SetValueTimeFont(0, nil)
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

    BBar:SO('General', 'BarSpark',      function(v) BBar:SetHiddenSpark(0, RuneSBar, not v) end)
    BBar:SO('General', 'ColorEnergize', function() Color = true end)
    BBar:SO('General', '_RuneLocation', function(v) BBar:SetPointTextureFrame(0, RuneMode, 'CENTER', BarMode, v.RunePosition, v.RuneOffsetX, v.RuneOffsetY) Display = true end)

    BBar:SO('Background', 'BackdropSettings', function(v) BBar:SetBackdrop(0, BarMode, v) end)
    BBar:SO('Background', 'Color',            function(v) Color = true end)

    BBar:SO('Bar', 'StatusBarTexture', function(v) BBar:SetTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'FillDirection',    function(v) BBar:SetFillDirectionTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v) BBar:SetRotateTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'Color',            function() Color = true end)
    BBar:SO('Bar', '_Size',            function(v, UB) BBar:SetSizeTextureFrame(0, BarMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v) BBar:SetPaddingTexture(0, RuneSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
  end

  -- Do the option.  This will call one of the options above or all.
  BBar:DoOption(TableName, KeyName)

  -- Change color if flagged
  if Color then
    for RuneIndex = 1, MaxRunes do
      ChangeRune(self, RuneIndex)
    end
    Color = false
  end

  if Main.UnitBars.Testing then
    self:Update()
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
  local ColorAllNames = {}

  BBar:CreateTextureFrame(0, BarMode, 0)
    BBar:CreateTexture(0, BarMode, 'statusbar', 1, RuneSBar)
    BBar:CreateTexture(0, BarMode, 'statusbar', 2, RuneEnergizeSBar)
    BBar:SetBackdropTexture(0, RuneEnergizeSBar, BarEnergizeBorder)

  local Width = RuneTextureData.Width
  local Height = RuneTextureData.Height

  for RuneIndex = 1, MaxRunes do
    local RuneType = GetRuneType(RuneIndex)

    BBar:SetFillTexture(RuneIndex, RuneSBar, 0)

    BBar:CreateTextureFrame(RuneIndex, RuneMode, 3)
      BBar:CreateTexture(RuneIndex, RuneMode, 'cooldown', 4, RuneTexture)
      BBar:SetTexture(RuneIndex, RuneTexture, RuneTextureData[RuneType])
      BBar:SetSizeTexture(RuneIndex, RuneTexture, Width, Height)
      BBar:SetSizeCooldownTexture(RuneIndex, RuneTexture, Width * 0.625, Height * 0.625, 0, 1)

      BBar:CreateTexture(RuneIndex, RuneMode, 'texture', 5, RuneBorderTexture)
      BBar:SetTexture(RuneIndex, RuneBorderTexture, RuneTextureData.Border)
      BBar:SetColorTexture(RuneIndex, RuneBorderTexture, 0.6, 0.6, 0.6, 1)
      BBar:SetSizeTexture(RuneIndex, RuneBorderTexture, Width, Height)

      BBar:CreateTexture(RuneIndex, RuneMode, 'texture', 6, RuneEnergizeTexture)
      BBar:SetTexture(RuneIndex, RuneEnergizeTexture, RuneTextureData.BorderEnergize)
      BBar:SetSizeTexture(RuneIndex, RuneEnergizeTexture, Width, Height)

      ColorAllNames[RuneIndex] = format('%s %s', RuneName[ceil(RuneIndex / 2)], 2 - RuneIndex % 2)
  end

  ColorAllNames[7] = 'Death Rune 1'
  ColorAllNames[8] = 'Death Rune 2'

  BBar:SetSizeTextureFrame(0, BarMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, RuneMode, RuneTextureData.Width, RuneTextureData.Height)

  BBar:SetHiddenTexture(0, RuneSBar, false)
  BBar:SetHiddenTexture(0, RuneTexture, false)
  BBar:SetHiddenTexture(0, RuneBorderTexture, false)

  BBar:CreateFont(0)

  UnitBarF.ColorAllNames = ColorAllNames
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Runebar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.RuneBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'RUNE_POWER_UPDATE', self.Update)
  Main:RegEventFrame(Enable, self, 'RUNE_TYPE_UPDATE', self.Update)
end
