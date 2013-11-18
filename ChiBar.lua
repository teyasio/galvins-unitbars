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

local ConvertPowerType = Main.ConvertPowerType

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
-------------------------------------------------------------------------------
local MaxChiOrbs = 5
local Display = false

-- Powertype constants
local PowerChi = ConvertPowerType['CHI']

-- shadow orbs Texture constants
local BoxMode = 1
local TextureMode = 2

local Orbs = 3

local OrbSBar = 10
local OrbDarkTexture = 20
local OrbLightTexture = 21

local ChiData = {
  Texture = [[Interface\PlayerFrame\MonkUI]],
  TextureWidth = 21 + 8, TextureHeight = 21 + 8,
  [OrbDarkTexture] = {
    Level = 1,
    Width = 21, Height = 21,
    Left = 0.09375000, Right = 0.17578125, Top = 0.71093750, Bottom = 0.87500000
  },
  [OrbLightTexture] = {
    Level = 2,
    Width = 21, Height = 21,
    Left = 0.00390625, Right = 0.08593750, Top = 0.71093750, Bottom = 0.87500000
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
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ChiBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerChi

  -- Return if not the correct powertype.
  if PowerType ~= PowerChi then
    return
  end

  local ChiOrbs = UnitPower('player', PowerChi)
  local NumOrbs = UnitPowerMax('player', PowerChi)

  -- Set default value if ChiOrbs returns zero.
  NumOrbs = NumOrbs > 0 and NumOrbs or MaxChiOrbs - 1
  local BBar = self.BBar

  -- Check for max chi change
  if NumOrbs ~= self.NumOrbs then

    -- Change the number of boxes in the bar.
    BBar:SetHidden(MaxChiOrbs, nil, NumOrbs ~= MaxChiOrbs)

    BBar:Display()
    self.NumOrbs = NumOrbs
  end

  if Main.UnitBars.Testing then
    if self.UnitBar.TestMode.MaxResource then
      ChiOrbs = MaxChiOrbs
    else
      ChiOrbs = 0
    end
  end

  for OrbIndex = 1, MaxChiOrbs do
    BBar:ChangeTexture(Orbs, 'SetHiddenTexture', OrbIndex, OrbIndex > ChiOrbs)
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

    BBar:SO('Region', 'BackdropSettings', function(v) BBar:SetBackdropRegion(v) end)
    BBar:SO('Region', 'Color',            function(v) BBar:SetBackdropColorRegion(v.r, v.g, v.b, v.a) end)

    BBar:SO('Background', 'BackdropSettings', function(v) BBar:SetBackdrop(0, BoxMode, v) end)
    BBar:SO('Background', 'Color',            function(v, UB, OD) BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a) end)

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

  local ColorAllNames = {}

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, OrbSBar)

  -- Create texture mode.
  for OrbIndex = 1, MaxChiOrbs do
    BBar:CreateTextureFrame(OrbIndex, TextureMode, 0)

    for TextureNumber, SD in pairs(ChiData) do
      if type(TextureNumber) == 'number' then
        BBar:CreateTexture(OrbIndex, TextureMode, 'texture', SD.Level, TextureNumber)

        BBar:SetTexture(OrbIndex, TextureNumber, ChiData.Texture)
        BBar:SetCoordTexture(OrbIndex, TextureNumber, SD.Left, SD.Right, SD.Top, SD.Bottom)
        BBar:SetSizeTexture(OrbIndex, TextureNumber, SD.Width, SD.Height)
      end
    end
    local Name = 'Chi Orb ' .. OrbIndex

    BBar:SetTooltip(OrbIndex, nil, Name)
    ColorAllNames[OrbIndex] = Name
  end

  BBar:SetHiddenTexture(0, OrbSBar, false)
  BBar:SetHiddenTexture(0, OrbDarkTexture, false)

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, ChiData.TextureWidth, ChiData.TextureHeight)

  BBar:SetChangeTexture(Orbs, OrbLightTexture, OrbSBar)

  BBar:SetTooltipRegion(UB.Name)
  UnitBarF.ColorAllNames = ColorAllNames

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

