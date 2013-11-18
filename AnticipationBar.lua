--
-- AnticipationBar.lua
--
-- Displays 5 rectangles for anticipation points.

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
-- UnitBarF.BBar                     Contains the anticipation bar displayed on screen.
--
-- Display                           Flag used to determin if a Display() call is needed.
-- BoxMode                           Textureframe number used for boxmode.
-- AnticipationSBar                  Texture for anticipation charges and time.
-- Anticipation                      Changebox number for all the anticipation boxframes.
-- AnticipationTime                  The boxnumber for the time statusbar.
--
-- AnticipationAura                  Buff containing the anticipation charges.
-- AnticipationSpell                 Spell the player knows or doens't know to gain anticipation.
-------------------------------------------------------------------------------
local MaxAnticipationCharges = 5
local Display = false

local BoxMode = 1
local AnticipationCharges = 2
local AnticipationTime = MaxAnticipationCharges + 1

local AnticipationSBar = 10
local AnticipationAura = 115189
local AnticipationSpell = 114015

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.AnticipationBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Anticipation bar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateTestMode
--
-- Display the anticipation bar in a testmode pattern.
--
-- AnticipationBar  The anticipation bar to show in test mode.
-- Testing          If true shows the test pattern, if false clears it.
-------------------------------------------------------------------------------
local function UpdateTestMode(AnticipationBar, Testing)
  local BBar = AnticipationBar.BBar
  local UB = AnticipationBar.UnitBar

  if Testing then
    local MaxResource = UB.TestMode.MaxResource
    local Charges = MaxResource and MaxAnticipationCharges or 0

    for AnticipationIndex = 1, MaxAnticipationCharges do
      BBar:SetHiddenTexture(AnticipationIndex, AnticipationSBar, not MaxResource)
    end
    BBar:SetFillTexture(AnticipationTime, AnticipationSBar, 0.5, true)
    if not UB.Layout.HideText then
      BBar:SetValueFont(AnticipationTime, nil, 'time', 9, 'charges', Charges)
    else
      BBar:SetValueRawFont(AnticipationTime, nil, '')
    end
  else
    BBar:SetFillTexture(AnticipationTime, AnticipationSBar, 0, true)
    BBar:SetValueRawFont(AnticipationTime, nil, '')
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
-------------------------------------------------------------------------------
function Main.UnitBarsF.AnticipationBar:Update(Event)

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
  local AnticipationCharges = 0

  -- Display anticipation charges
  if IsSpellKnown(AnticipationSpell) then
    local SpellID, Duration, Charges = Main:CheckAura('o', AnticipationAura)

    AnticipationCharges = Charges or 0
    if self.NumCharges ~= AnticipationCharges or AnticipationCharges == MaxAnticipationCharges then
      BBar:SetFillTimeTexture(AnticipationTime, AnticipationSBar, nil, Duration, 1, 0)
      if not self.UnitBar.Layout.HideText then
        BBar:SetValueTimeFont(AnticipationTime, nil, nil, Duration or 0, Duration, -1, 'charges', AnticipationCharges)
      end
      self.NumCharges = AnticipationCharges
    end
    for AnticipationIndex = 1, MaxAnticipationCharges do
      BBar:SetHiddenTexture(AnticipationIndex, AnticipationSBar, AnticipationIndex > AnticipationCharges)
    end
  end

  -- Set the IsActive flag
  self.IsActive = AnticipationCharges > 0

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Anticipation bar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbale mouse clicks for the anticipation bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.AnticipationBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the anticipation bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.AnticipationBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SetOptionData('BackgroundCharges', AnticipationCharges)
    BBar:SetOptionData('BackgroundTime', AnticipationTime)
    BBar:SetOptionData('BarCharges', AnticipationCharges)
    BBar:SetOptionData('BarTime', AnticipationTime)

    BBar:SO('Text', '_Font', function() BBar:UpdateFont(AnticipationTime) end)
    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',   function(v) BBar:SetFillReverseTexture(0, AnticipationSBar, v) end)
    BBar:SO('Layout', 'HideText',      function(v)
      if v then
        BBar:SetValueTimeFont(AnticipationTime, nil)
      end
    end)
    BBar:SO('Layout', 'Rotation',      function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',         function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',       function(v) BBar:ChangeBox(AnticipationCharges, 'SetPaddingBox', v) Display = true end)
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, AnticipationSBar, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, AnticipationSBar, 'out', v) end)
    BBar:SO('Layout', 'Align',         function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX', function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY', function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',  function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',  function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('General', 'HideCharges', function(v) BBar:ChangeBox(AnticipationCharges, 'SetHidden', nil, v) Display = true end)
    BBar:SO('General', 'HideTime',    function(v) BBar:SetHidden(AnticipationTime, nil, v) Display = true end)
    BBar:SO('General', 'ShowSpark',   function(v) BBar:SetHiddenSpark(0, AnticipationSBar, not v) end)

    BBar:SO('Background', 'BackdropSettings',  function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdrop', BoxMode, v) end)
    BBar:SO('Background', 'Color',             function(v, UB, OD)
      if OD.TableName == 'BackgroundCharges' then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetBackdropColor(AnticipationTime, BoxMode, v.r, v.g, v.b, v.a)
      end
    end)
    BBar:SO('Bar', 'StatusBarTexture', function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetTexture', AnticipationSBar, v) end)
    BBar:SO('Bar', 'FillDirection',    function(v)         BBar:SetFillDirectionTexture(AnticipationTime, AnticipationSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetRotateTexture', AnticipationSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD)
      if OD.TableName == 'BarCharges' then
        BBar:SetColorTexture(OD.Index, AnticipationSBar, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetColorTexture(AnticipationTime, AnticipationSBar, v.r, v.g, v.b, v.a)
      end
    end)
    BBar:SO('Bar', '_Size',            function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetSizeTextureFrame', BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetPaddingTexture', AnticipationSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the anticipation bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.AnticipationBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxAnticipationCharges + 1)

  local ColorAllNames = {}

  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, AnticipationSBar)

  -- Create anticipation time text.
  BBar:CreateFont(AnticipationTime)

  BBar:SetChangeBox(AnticipationCharges, 1, 2, 3, 4, 5)
  BBar:SetChangeBox(AnticipationTime, AnticipationTime)
  local Name = nil

  for AnticipationIndex = 1, MaxAnticipationCharges do
    Name = 'Anticipation Charge ' .. AnticipationIndex

    ColorAllNames[AnticipationIndex] = Name
    BBar:SetTooltip(AnticipationIndex, nil, Name)
  end
  Name = 'Anticipation Time'
  ColorAllNames[AnticipationTime] = Name
  BBar:SetTooltip(AnticipationTime, nil, Name)

  UnitBarF.ColorAllNames = ColorAllNames
  BBar:ChangeBox(AnticipationCharges, 'SetHidden', BoxMode, false)
  BBar:SetHidden(AnticipationTime, BoxMode, false)
  BBar:SetHiddenTexture(AnticipationTime, AnticipationSBar, false)
  BBar:SetFillTexture(AnticipationTime, AnticipationSBar, 0)

  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Anticipation bar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.AnticipationBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_AURA', self.Update, 'player')
end

