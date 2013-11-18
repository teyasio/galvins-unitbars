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
-- UnitBarF.BBar                     Contains the holy bar displayed on screen.
--
-- RuneSBar                          Holy rune for box mode.
-- RuneDarkTexture                   Dark holy rune texture for texture mode.
-- RuneLightTexture                  Lit holy rune texture for texture mode.
-- TextureMode                       TextureFrame number for texture mode.
-- BoxMode                           TextureFrame number for box mode.
-- Runes                             ChangeTexture number for RuneLightTexture and RuneBar.
-- Display                           Flag used to determin if a Display() call is needed.
--
-- HolyData                          Contains the data to create the holy bar.
--   Texture                         Texture that contains the holy runes.
--   BoxWidth, BoxHeight             Size of the boxes in texture mode.
--   Runes[Rune].Width               Width of the rune texture.
--   [Rune Number]
--     Point                         Texture point inside the texture frame.
--     OffsetX, OffsetY              Offset the texture inside the texture frame.
--     Width, Height                 Width and Height of the rune texture and the texture frame.
--     Left, Right, Top, Bottom      Texture coordinates inside of the HolyPowerTexture
--                                   containing the holy rune.
-------------------------------------------------------------------------------
local MaxHolyRunes = 5
local Display = false

-- Powertype constants
local PowerHoly = ConvertPowerType['HOLY_POWER']

-- Holyrune Texture constants
local BoxMode = 1
local TextureMode = 2

local Runes = 3

local RuneSBar = 10
local RuneDarkTexture = 12
local RuneLightTexture = 13

local HolyData = {
  Texture = [[Interface\PlayerFrame\PaladinPowerTextures]],

  -- TextureFrame size.
  BoxWidth = 42 + 8, BoxHeight = 31,
  DarkColor = {r = 0.15, g = 0.15, b = 0.15, a = 1},
  { -- 1
    OffsetX = 1, OffsetY = 0,
    Width = 36 + 5, Height = 22 + 5,
    Left = 0.00390625, Right = 0.14453125, Top = 0.78906250, Bottom = 0.96093750
  },
  { -- 2
    OffsetX = 1, OffsetY = 0,
    Width = 31 + 14, Height = 17 + 14,
    Left = 0.15234375, Right = 0.27343750, Top = 0.78906250, Bottom = 0.92187500
  },
  { -- 3
    OffsetX = 0, OffsetY = 0,
    Width = 27 + 10 , Height = 21 + 10,
    Left = 0.28125000, Right = 0.38671875, Top = 0.64843750, Bottom = 0.81250000
  },
  { -- 4 Rune1 texture that's rotated.
    OffsetX = -1, OffsetY = 0,
    Width = 36 + 5, Height = 17 + 12,
    Left = 0.14453125, Right = 0.00390625, Top = 0.78906250, Bottom = 0.96093750
  },
  { -- 5 Rune2 texture that's rotated.
    OffsetX = -1, OffsetY = 0,
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
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.HolyBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerHoly

  -- Return if not the correct powertype.
  if PowerType ~= PowerHoly then
    return
  end

  local BBar = self.BBar
  local HolyPower = UnitPower('player', PowerHoly)

  if Main.UnitBars.Testing then
    if self.UnitBar.TestMode.MaxResource then
      HolyPower = MaxHolyRunes
    else
      HolyPower = 0
    end
  end

  for RuneIndex = 1, MaxHolyRunes do
    BBar:ChangeTexture(Runes, 'SetHiddenTexture', RuneIndex, RuneIndex > HolyPower)
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

    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'BoxMode',        function(v)
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
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, RuneSBar, 'in', v)
                                                   BBar:SetFadeTimeTexture(0, RuneLightTexture, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, RuneSBar, 'out', v)
                                                   BBar:SetFadeTimeTexture(0, RuneLightTexture, 'out', v) end)
    BBar:SO('Layout', 'Align',         function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX', function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY', function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',  function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',  function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('Region', 'BackdropSettings', function(v) BBar:SetBackdropRegion(v) end)
    BBar:SO('Region', 'Color',            function(v) BBar:SetBackdropColorRegion(v.r, v.g, v.b, v.a) end)

    BBar:SO('Background', 'BackdropSettings', function(v) BBar:SetBackdrop(0, BoxMode, v) end)
    BBar:SO('Background', 'Color',            function(v, UB, OD) BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a) end)

    BBar:SO('Bar', 'StatusBarTexture', function(v) BBar:SetTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v) BBar:SetRotateTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD) BBar:SetColorTexture(OD.Index, RuneSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',            function(v, UB) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v) BBar:SetPaddingTexture(0, RuneSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the holy rune bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.HolyBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxHolyRunes)

  local ColorAllNames = {}
  local DarkColor = HolyData.DarkColor

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, RuneSBar)

  -- Create texture mode.
  for RuneIndex, HD in ipairs(HolyData) do

    BBar:CreateTextureFrame(RuneIndex, TextureMode, 0)
      BBar:CreateTexture(RuneIndex, TextureMode, 'texture', 1, RuneDarkTexture)
      BBar:CreateTexture(RuneIndex, TextureMode, 'texture', 2, RuneLightTexture)

    BBar:SetTexture(RuneIndex, RuneDarkTexture, HolyData.Texture)
    BBar:SetTexture(RuneIndex, RuneLightTexture, HolyData.Texture)

    BBar:SetSizeTexture(RuneIndex, RuneDarkTexture, HD.Width, HD.Height)
    BBar:SetSizeTexture(RuneIndex, RuneLightTexture, HD.Width, HD.Height)

    BBar:SetCoordTexture(RuneIndex, RuneDarkTexture, HD.Left, HD.Right, HD.Top, HD.Bottom)
    BBar:SetGreyscaleTexture(RuneIndex, RuneDarkTexture, true)
    BBar:SetColorTexture(RuneIndex, RuneDarkTexture, DarkColor.r, DarkColor.g, DarkColor.b, DarkColor.a)

    BBar:SetCoordTexture(RuneIndex, RuneLightTexture, HD.Left, HD.Right, HD.Top, HD.Bottom)

     -- Set and save the name for tooltips for box mode.
    local Name = 'Holy Rune ' .. RuneIndex

    BBar:SetTooltip(RuneIndex, nil, Name)

    ColorAllNames[RuneIndex] = Name
  end

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, HolyData.BoxWidth, HolyData.BoxHeight)

  BBar:SetChangeTexture(Runes, RuneLightTexture, RuneSBar)
  BBar:SetHiddenTexture(0, RuneDarkTexture, false)

  BBar:SetTooltipRegion(UB.Name)
  UnitBarF.ColorAllNames = ColorAllNames

  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Holybar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.HolyBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
  Main:RegEventFrame(Enable, self, 'UNIT_POWER', self.Update, 'player')
end
