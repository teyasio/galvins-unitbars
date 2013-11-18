--
-- ComboBar.lua
--
-- Displays 5 rectangles for combo points.

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

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the combo bar displayed on screen.
--
-- Display                           Flag used to determin if a Display() call is needed.
--
-- BoxMode                           Boxframe number for boxmode.
-- Combo                             Changebox number for all the combo points.
-- ComboSBar                         Texture for combo point.
-------------------------------------------------------------------------------
local MaxComboPoints = 5
local Display = false

local BoxMode = 1
local Combo = 3
local ComboSBar = 10

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.ComboBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Combobar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ComboBar:Update(Event)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible and self.IsActive ~= 0 then
    return
  end

  -- Get the combo points.
  local ComboPoints = GetComboPoints('player', 'target')
  local BBar = self.BBar

  if Main.UnitBars.Testing then
    if self.UnitBar.TestMode.MaxResource then
      ComboPoints = MaxComboPoints
    else
      ComboPoints = 0
    end
  end

  -- Display the combo points
  for ComboIndex = 1, MaxComboPoints do
    BBar:SetHiddenTexture(ComboIndex, ComboSBar, ComboIndex > ComboPoints)
  end

  -- Set the IsActive flag
  self.IsActive = ComboPoints > 0

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Combobar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbale mouse clicks for the combo bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ComboBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the combobar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ComboBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'Rotation',      function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',         function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',       function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, ComboSBar, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, ComboSBar, 'out', v) end)
    BBar:SO('Layout', 'Align',         function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX', function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY', function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',  function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',  function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('Background', 'BackdropSettings',  function(v) BBar:SetBackdrop(0, BoxMode, v) end)
    BBar:SO('Background', 'Color',             function(v, UB, OD) BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', 'StatusBarTexture',         function(v) BBar:ChangeBox(Combo, 'SetTexture', ComboSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',            function(v) BBar:ChangeBox(Combo, 'SetRotateTexture', ComboSBar, v) end)
    BBar:SO('Bar', 'Color',                    function(v, UB, OD) BBar:SetColorTexture(OD.Index, ComboSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',                    function(v, UB) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',                  function(v) BBar:SetPaddingTexture(0, ComboSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the combo bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ComboBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxComboPoints)

  local ColorAllNames = {}

  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, ComboSBar)

  BBar:SetChangeBox(Combo, 1, 2, 3, 4, 5)

  for ComboIndex = 1, MaxComboPoints do
    local Name = nil

    Name = 'Combo Point ' .. ComboIndex
    ColorAllNames[ComboIndex] = Name
    BBar:SetTooltip(ComboIndex, nil, Name)
  end

  UnitBarF.ColorAllNames = ColorAllNames
  BBar:ChangeBox(Combo, 'SetHidden', BoxMode, false)

  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Combobar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.ComboBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_COMBO_POINTS', self.Update, 'player')
end

