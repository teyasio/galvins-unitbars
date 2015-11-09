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
local TT = GUB.DefaultUB.TriggerTypes

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring =
      strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList
local UnitName, UnitReaction, UnitGetIncomingHeals, GetRealmName, UnitCanAttack, UnitPlayerControlled, UnitIsPVP =
      UnitName, UnitReaction, UnitGetIncomingHeals, GetRealmName, UnitCanAttack, UnitPlayerControlled, UnitIsPVP
local GetRuneCooldown, GetRuneType, GetSpellInfo, PlaySound, message =
      GetRuneCooldown, GetRuneType, GetSpellInfo, PlaySound, message
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
--
-------------------------------------------------------------------------------
local MaxAnticipationCharges = 5
local Display = false
local NamePrefix = 'Anticipation '

local BoxMode = 1
local AnticipationCharges = 2
local AnticipationTime = MaxAnticipationCharges + 1

local AnticipationSBar = 10
local AnticipationAura = 115189
local AnticipationSpell = 114015

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
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,            AnticipationSBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,              AnticipationSBar,
    GF = GF },
  { TT.TypeID_Sound,                 TT.Type_Sound }
}

local AnticipationTimeGroup = 6

local VTs = {'whole', 'Anticipation Charges', 'auras', 'Auras'}

local Groups = { -- BoxNumber, Name, ValueTypes,
  {1,   'Charge 1',    VTs,    TD}, -- 1
  {2,   'Charge 2',    VTs,    TD}, -- 2
  {3,   'Charge 3',    VTs,    TD}, -- 3
  {4,   'Charge 4',    VTs,    TD}, -- 4
  {5,   'Charge 5',    VTs,    TD}, -- 5
  {6,   'Time',        VTs,    TD}, -- 6
  {'a', 'All Charges', {'whole', 'Anticipation Charges', 'state', 'Active', 'auras', 'Auras'}, TD}, -- 7
}

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
    local TestMode = UB.TestMode
    local Charges = floor(MaxAnticipationCharges * TestMode.Value)
    local Time = TestMode.Time
    local EnableTriggers = UB.Layout.EnableTriggers

    for AnticipationIndex = 1, MaxAnticipationCharges do
      BBar:SetHiddenTexture(AnticipationIndex, AnticipationSBar, AnticipationIndex > Charges)

      if EnableTriggers then
        BBar:SetTriggers(AnticipationIndex, 'active', AnticipationIndex <= Charges)
        BBar:SetTriggers(AnticipationIndex, 'anticipation charges', Charges)
      end
    end
    BBar:SetFillTexture(AnticipationTime, AnticipationSBar, Time , true)
    if not UB.Layout.HideText then
      BBar:SetValueFont(AnticipationTime, nil, 'time', 10 * Time, 'charges', Charges)
    else
      BBar:SetValueRawFont(AnticipationTime, nil, '')
    end

    if EnableTriggers then
      BBar:SetTriggers(AnticipationTimeGroup, 'anticipation charges', Charges)
      BBar:DoTriggers()
    end
  else
    BBar:SetHiddenTexture(0, AnticipationSBar, true)
    BBar:SetHiddenTexture(AnticipationTime, AnticipationSBar, false)
    BBar:SetFillTexture(AnticipationTime, AnticipationSBar, 0, true)
    BBar:SetValueRawFont(AnticipationTime, nil, '')
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Event     Event that called this function.  If nil then it wasn't called by an event.
--           True bypasses visible and isactive flags.
-------------------------------------------------------------------------------
function Main.UnitBarsF.AnticipationBar:Update(Event)

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

  local BBar = self.BBar
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers
  local AnticipationCharges = 0

  -- Display anticipation charges
  if IsSpellKnown(AnticipationSpell) then
    local SpellID, Duration, Charges = Main:CheckAura('o', AnticipationAura)
    local DurationChanged = Duration == nil or Duration >= self.OldDuration

    self.OldDuration = Duration or 0
    AnticipationCharges = Charges or 0

    if self.NumCharges ~= AnticipationCharges or AnticipationCharges == MaxAnticipationCharges then
      if DurationChanged then
        BBar:SetFillTimeTexture(AnticipationTime, AnticipationSBar, nil, Duration, 1, 0)
      end
      if not self.UnitBar.Layout.HideText then
        BBar:SetValueTimeFont(AnticipationTime, nil, nil, Duration or 0, Duration, -1, 'charges', AnticipationCharges)
      end
      self.NumCharges = AnticipationCharges
    end
    for AnticipationIndex = 1, MaxAnticipationCharges do
      BBar:SetHiddenTexture(AnticipationIndex, AnticipationSBar, AnticipationIndex > AnticipationCharges)
      if EnableTriggers then
        BBar:SetTriggers(AnticipationIndex, 'active', AnticipationIndex <= AnticipationCharges)
        BBar:SetTriggers(AnticipationIndex, 'anticipation charges', AnticipationCharges)
      end
    end
    if EnableTriggers then
      BBar:SetTriggers(AnticipationTimeGroup, 'anticipation charges', AnticipationCharges)
      BBar:DoTriggers()
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

    BBar:SO('Layout', 'EnableTriggers', function(v) BBar:EnableTriggers(v, Groups) Display = true end)

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


    BBar:SO('Background', 'BgTexture',     function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdrop', BoxMode, v) end)
    BBar:SO('Background', 'BorderTexture', function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropBorder', BoxMode, v) end)
    BBar:SO('Background', 'BgTile',        function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropTile', BoxMode, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropTileSize', BoxMode, v) end)
    BBar:SO('Background', 'BorderSize',    function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropBorderSize', BoxMode, v) end)
    BBar:SO('Background', 'Padding',       function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropPadding', BoxMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v, UB, OD)
      if OD.TableName == 'BackgroundCharges' then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetBackdropColor(AnticipationTime, BoxMode, v.r, v.g, v.b, v.a)
      end
    end)
    BBar:SO('Background', 'BorderColor',   function(v, UB, OD)
      local TableName = OD.TableName
      local EnableBorderColor = UB[TableName].EnableBorderColor

      if TableName == 'BackgroundCharges' then
        if EnableBorderColor then
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
        else
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
        end
      elseif EnableBorderColor then
        BBar:SetBackdropBorderColor(AnticipationTime, BoxMode, v.r, v.g, v.b, v.a)
      else
        BBar:SetBackdropBorderColor(AnticipationTime, BoxMode, nil)
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

  local Names = {}

  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, AnticipationSBar)

  -- Create anticipation time text.
  BBar:CreateFont(AnticipationTime)

  BBar:SetChangeBox(AnticipationCharges, 1, 2, 3, 4, 5)
  BBar:SetChangeBox(AnticipationTime, AnticipationTime)
  local Name = nil

  for AnticipationIndex = 1, MaxAnticipationCharges do
    Name = NamePrefix .. Groups[AnticipationIndex][2]
    Names[AnticipationIndex] = Name
    BBar:SetTooltip(AnticipationIndex, nil, Name)
  end
  Name = NamePrefix .. Groups[AnticipationTime][2]
  Names[AnticipationTime] = Name

  BBar:SetTooltip(AnticipationTime, nil, Name)

  BBar:ChangeBox(AnticipationCharges, 'SetHidden', BoxMode, false)
  BBar:SetHidden(AnticipationTime, BoxMode, false)
  BBar:SetHiddenTexture(AnticipationTime, AnticipationSBar, false)
  BBar:SetFillTexture(AnticipationTime, AnticipationSBar, 0)

  UnitBarF.Names = Names
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

