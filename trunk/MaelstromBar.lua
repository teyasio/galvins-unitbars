--
-- MaelstromBar.lua
--
-- Displays 5 rectangles for maelstrom charges.

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
-- UnitBarF.BBar                  Contains the maelstrom bar displayed on screen.
--
-- Display                        Flag used to determin if a Display() call is needed.
-- BoxMode                        Textureframe number used for boxmode.
-- MaelstromSBar                  Texture for maelstrom charges and time.
-- Maelstrom                      Changebox number for all the maelstrom boxframes.
-- MaelstromTime                  The boxnumber for the time statusbar.
--
-- MaelstromAura                  Buff containing the maelstrom charges.
-- MaelstromSpell                 Spell the player knows or doens't know to gain maelstrom.
-------------------------------------------------------------------------------
local MaxMaelstromCharges = 5
local Display = false

local BoxMode = 1
local MaelstromCharges = 2
local MaelstromTime = MaxMaelstromCharges + 1

local MaelstromSBar = 10
local MaelstromAura = 53817
local MaelstromSpell = 51530

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.MaelstromBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Maelstrom bar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateTestMode
--
-- Display the maelstrom bar in a testmode pattern.
--
-- maelstromBar  The maelstrom bar to show in test mode.
-- Testing       If true shows the test pattern, if false clears it.
-------------------------------------------------------------------------------
local function UpdateTestMode(MaelstromBar, Testing)
  local BBar = MaelstromBar.BBar
  local UB = MaelstromBar.UnitBar

  if Testing then
    local MaxResource = UB.TestMode.MaxResource
    local Charges = MaxResource and MaxMaelstromCharges or 0

    for MaelstromIndex = 1, MaxMaelstromCharges do
      BBar:SetHiddenTexture(MaelstromIndex, MaelstromSBar, not MaxResource)
    end
    BBar:SetFillTexture(MaelstromTime, MaelstromSBar, 0.5, true)
    if not UB.Layout.HideText then
      BBar:SetValueFont(MaelstromTime, nil, 'time', 9, 'charges', Charges)
    else
      BBar:SetValueRawFont(MaelstromTime, nil, '')
    end
  else
    BBar:SetFillTexture(MaelstromTime, MaelstromSBar, 0, true)
    BBar:SetValueRawFont(MaelstromTime, nil, '')
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
-------------------------------------------------------------------------------
function Main.UnitBarsF.MaelstromBar:Update(Event)

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

  local BBar = self.BBar
  local Maelstrom = IsSpellKnown(MaelstromSpell)
  local MaelstromCharges = 0

  -- Display maelstrom charges
  if Maelstrom then
    local SpellID, Duration, Charges = Main:CheckAura('o', MaelstromAura)

    MaelstromCharges = Charges or 0
    if self.NumCharges ~= MaelstromCharges or MaelstromCharges == MaxMaelstromCharges then
      BBar:SetFillTimeTexture(MaelstromTime, MaelstromSBar, nil, Duration, 1, 0)
      if not self.UnitBar.Layout.HideText then
        BBar:SetValueTimeFont(MaelstromTime, nil, nil, Duration or 0, Duration, -1, 'charges', MaelstromCharges)
      end
      self.NumCharges = MaelstromCharges
    end
    for MaelstromIndex = 1, MaxMaelstromCharges do
      BBar:SetHiddenTexture(MaelstromIndex, MaelstromSBar, MaelstromIndex > MaelstromCharges)
    end
  end

  -- Set the IsActive flag
  self.IsActive = MaelstromCharges > 0

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Maelstrom bar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbale mouse clicks for the maelstrom bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.MaelstromBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the maelstrom bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.MaelstromBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SetOptionData('BackgroundCharges', MaelstromCharges)
    BBar:SetOptionData('BackgroundTime', MaelstromTime)
    BBar:SetOptionData('BarCharges', MaelstromCharges)
    BBar:SetOptionData('BarTime', MaelstromTime)

    BBar:SO('Text', '_Font', function() BBar:UpdateFont(MaelstromTime) end)
    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',   function(v) BBar:SetFillReverseTexture(0, MaelstromSBar, v) end)
    BBar:SO('Layout', 'HideText',      function(v)
      if v then
        BBar:SetValueTimeFont(MaelstromTime, nil)
      end
    end)
    BBar:SO('Layout', 'Rotation',      function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',         function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',       function(v) BBar:ChangeBox(MaelstromCharges, 'SetPaddingBox', v) Display = true end)
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, MaelstromSBar, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, MaelstromSBar, 'out', v) end)
    BBar:SO('Layout', 'Align',         function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX', function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY', function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',  function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',  function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('General', 'HideCharges', function(v) BBar:ChangeBox(MaelstromCharges, 'SetHidden', nil, v) Display = true end)
    BBar:SO('General', 'HideTime',    function(v) BBar:SetHidden(MaelstromTime, nil, v) Display = true end)
    BBar:SO('General', 'ShowSpark',   function(v) BBar:SetHiddenSpark(0, MaelstromSBar, not v) end)

    BBar:SO('Background', 'BackdropSettings',  function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdrop', BoxMode, v) end)
    BBar:SO('Background', 'Color',             function(v, UB, OD)
      if OD.TableName == 'BackgroundCharges' then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetBackdropColor(MaelstromTime, BoxMode, v.r, v.g, v.b, v.a)
      end
    end)
    BBar:SO('Bar', 'StatusBarTexture', function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetTexture', MaelstromSBar, v) end)
    BBar:SO('Bar', 'FillDirection',    function(v)         BBar:SetFillDirectionTexture(MaelstromTime, MaelstromSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetRotateTexture', MaelstromSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD)
      if OD.TableName == 'BarCharges' then
        BBar:SetColorTexture(OD.Index, MaelstromSBar, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetColorTexture(MaelstromTime, MaelstromSBar, v.r, v.g, v.b, v.a)
      end
    end)
    BBar:SO('Bar', '_Size',            function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetSizeTextureFrame', BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetPaddingTexture', MaelstromSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the maelstrom bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.MaelstromBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxMaelstromCharges + 1)

  local ColorAllNames = {}

  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, MaelstromSBar)

  -- Create maelstrom time text.
  BBar:CreateFont(MaelstromTime)

  BBar:SetChangeBox(MaelstromCharges, 1, 2, 3, 4, 5)
  BBar:SetChangeBox(MaelstromTime, MaelstromTime)
  local Name = nil

  for MaelstromIndex = 1, MaxMaelstromCharges do
    Name = 'Maelstrom Charge ' .. MaelstromIndex

    ColorAllNames[MaelstromIndex] = Name
    BBar:SetTooltip(MaelstromIndex, nil, Name)
  end
  Name = 'Maelstrom Time'
  ColorAllNames[MaelstromTime] = Name
  BBar:SetTooltip(MaelstromTime, nil, Name)

  UnitBarF.ColorAllNames = ColorAllNames
  BBar:ChangeBox(MaelstromCharges, 'SetHidden', BoxMode, false)
  BBar:SetHidden(MaelstromTime, BoxMode, false)
  BBar:SetHiddenTexture(MaelstromTime, MaelstromSBar, false)
  BBar:SetFillTexture(MaelstromTime, MaelstromSBar, 0)

  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Maelstrom bar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.MaelstromBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_AURA', self.Update, 'player')
end

