--
-- HealthPower.lua
--
-- Displays health and power bars.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local TT = GUB.DefaultUB.TriggerTypes

local UnitBarsF = Main.UnitBarsF
local LSM = Main.LSM
local ConvertPowerType = Main.ConvertPowerType
local ConvertFaction = Main.ConvertFaction

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
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar         Contains the Health and power bar displayed on screen.
-- StatusBar             TextureNumber for Status Bar
-- PredictedBar          TextureNumber for Predicted Bar
-- StatusBars            Change Texture for Status Bar and Predicted Bar.
-- SpellSteadyShot
-- SpellCobraShot        Hunter Spells to track for predicted power.
-- PredictedSpellValue   Predicted focus value based on the two above spells.
-- SteadyFocusAura       Buff hunters get that adds bonus focus.
-------------------------------------------------------------------------------
local Display = false
local Update = false

local StatusBar = 1
local PredictedBar = 2
local StatusBars = 1

-- Powertype constants
local PowerMana = ConvertPowerType['MANA']
local PowerEnergy = ConvertPowerType['ENERGY']
local PowerFocus = ConvertPowerType['FOCUS']

-- Predicted spell ID constants.
local SpellSteadyShot = 56641
local SpellCobraShot  = 77767
local FocusingShot    = 163485

local PredictedSpellValue = {
  [0]               = 0,
  [SpellSteadyShot] = 14,
  [SpellCobraShot]  = 14,
  [FocusingShot]    = 50,
}

--local SteadyFocusAura = 53220

-- Amount of focus that gets added on to SteadyShot.
local SteadyFocusBonus = 3

local GF = { -- Get function data
  TT.TypeID_ClassColor,  TT.Type_ClassColor,
  TT.TypeID_PowerColor,  TT.Type_PowerColor,
  TT.TypeID_CombatColor, TT.Type_CombatColor,
  TT.TypeID_TaggedColor, TT.Type_TaggedColor,
}

local TD = { -- Trigger data
  { TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,             1 },
  { TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor,        1,
    GF = GF },
  { TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,         1 },
  { TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,              1,
    GF = GF },
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,                   StatusBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,                     StatusBar,
    GF = GF },
  { TT.TypeID_BarTexture,            TT.Type_BarTexture .. ' (predicted)', PredictedBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor .. ' (predicted)',   PredictedBar,
    GF = GF },
  { TT.TypeID_BarOffset,             TT.Type_BarOffset,                    1 },
  { TT.TypeID_TextFontColor,         TT.Type_TextFontColor,
    GF = GF },
  { TT.TypeID_TextFontOffset,        TT.Type_TextFontOffset },
  { TT.TypeID_TextFontSize,          TT.Type_TextFontSize },
  { TT.TypeID_TextFontType,          TT.Type_TextFontType },
  { TT.TypeID_TextFontStyle,         TT.Type_TextFontStyle },
  { TT.TypeID_Sound,                 TT.Type_Sound }
}

local HealthVTs = {'whole', 'Health', 'percent', 'Health (percent)', 'whole', 'Predicted Health', 'auras', 'Auras'}
local PowerVTs = {'whole', 'Power', 'percent', 'Power (percent)', 'whole', 'Predicted Power', 'auras', 'Auras'}

local HealthGroups = { -- BoxNumber, Name, ValueTypes,
  {1, '', HealthVTs, TD}, -- 1
}
local PowerGroups = { -- BoxNumber, Name, ValueTypes,
  {1, '', PowerVTs, TD}, -- 1
}

-------------------------------------------------------------------------------
-- HapFunction
--
-- Assigns a function to all the health and power bars under one name.
--
-------------------------------------------------------------------------------
local function HapFunction(Name, Fn)
  for BarType, UBF in pairs(UnitBarsF) do
    if strfind(BarType, 'Health') or strfind(BarType, 'Power') then
      UBF[Name] = Fn
    end
  end
end

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
HapFunction('StatusCheck', Main.StatusCheck)

--*****************************************************************************
--
-- health and Power - predicted power and initialization
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- CheckSpell
--
-- Calls update on cast end
-------------------------------------------------------------------------------
local function CheckSpell(UnitBarF, SpellID, CastTime, Message)
  SpellID = abs(SpellID)

  if Message == 'start' then
    local PredictedPower = PredictedSpellValue[SpellID]

    -- Check for steady focus.  Will the aura drop off before steadyshot is finished casting.
    --if SpellID == SpellSteadyShot then
    --  local Spell, TimeLeft = Main:CheckAura('o', SteadyFocusAura)
    --  if Spell then

        -- Add bonus focus if buff will be up by the time the cast is finished.
    --    if CastTime < TimeLeft then
    --      PredictedPower = PredictedPower + SteadyFocusBonus
    --    end
    --  end
    --end

    -- Check for two piece bonus tier 13. hunters only.
    if Main:GetSetBonus(13) >= 2 then
      PredictedPower = PredictedPower * 2
    end

    -- Save predicted focus.
    UnitBarF.PredictedPower = PredictedPower
  else

    -- Set predictedfocus to zero.
    UnitBarF.PredictedPower = 0
  end

  -- Spell is done casting.  Update the power.
  UnitBarF:Update()
end

-------------------------------------------------------------------------------
-- Set Steady shot and cobra shot for predicted power.
-- Set a callback that will update the power bar when ever either of these spells are casting.
-------------------------------------------------------------------------------
Main:SetSpellTracker(UnitBarsF.PlayerPower, SpellSteadyShot, 'casting', CheckSpell)
Main:SetSpellTracker(UnitBarsF.PlayerPower, SpellCobraShot,  'casting', CheckSpell)
Main:SetSpellTracker(UnitBarsF.PlayerPower, FocusingShot,    'casting', CheckSpell)

--*****************************************************************************
--
-- Health and Power bar utility
--
--*****************************************************************************

-- Used by SetValueFont to calculate percentage.
local function PercentFn(Value, MaxValue)
  return ceil(Value / MaxValue * 100)
end

--*****************************************************************************
--
-- Health and Power bar script functions (script/event)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- HapBarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar parent frame will be moved.
-- Otherwise just the runes will be moved.
-------------------------------------------------------------------------------
local function HapBarStartMoving(self, Button)

  -- Call the base moving function for group or anchor movement.
  if Main.UnitBarStartMoving(self.Anchor, Button) then
    self.UnitBarMoving = true
  end
end

-------------------------------------------------------------------------------
-- HapBarStopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
-------------------------------------------------------------------------------
local function HapBarStopMoving(self, Button)

  -- Call the stop moving base function if there was a group move or anchor move.
  if self.UnitBarMoving then
    self.UnitBarMoving = false
    Main.UnitBarStopMoving(self.Anchor, Button)
  end
end

--*****************************************************************************
--
-- Health and Power bar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateHealthBar
--
-- Updates the health of the current player or target
--
-- self         UnitBarF contains the health bar to display.
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True by passes visible and isactive flags.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-------------------------------------------------------------------------------
local function UpdateHealthBar(self, Event, Unit)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  local BBar = self.BBar
  local UB = self.UnitBar
  local Gen = UB.General
  local Bar = UB.Bar

  local CurrValue = UnitHealth(Unit)
  local MaxValue = UnitHealthMax(Unit)
  local PredictedHealing = Gen.PredictedHealth and UnitGetIncomingHeals(Unit) or 0

  if Main.UnitBars.Testing then
    local TestMode = UB.TestMode
    local PredictedValue = TestMode.PredictedValue

    MaxValue = MaxValue == 0 and 10000 or MaxValue
    CurrValue = floor(MaxValue * TestMode.Value)
    PredictedHealing = PredictedValue and floor(MaxValue * PredictedValue) or 0
  end

  local ClassColor = Gen.ClassColor or false
  local CombatColor = Gen.CombatColor or false
  local TaggedColor = Gen.TaggedColor or false
  local BarColor = Bar.Color
  local r, g, b, a = BarColor.r, BarColor.g, BarColor.b, BarColor.a

  -- Get class color
  if ClassColor then
    r, g, b, a = Main:GetClassColor(Unit, nil, nil, nil, r, g, b, a)

  -- Get faction color
  elseif CombatColor then
    r, g, b, a = Main:GetCombatColor(Unit, nil, nil, nil, r, g, b, a)
  end

  -- Get tagged color
  if TaggedColor then
    r, g, b, a = Main:GetTaggedColor(Unit, nil, nil, nil, r, g, b, a)
  end

  -- Set the color and display the predicted health.
  local PredictedColor = Bar.PredictedColor
  if PredictedColor then
    if PredictedHealing > 0 and CurrValue < MaxValue then
      BBar:SetColorTexture(1, PredictedBar, PredictedColor.r, PredictedColor.g, PredictedColor.b, PredictedColor.a)
      BBar:SetFillTexture(1, PredictedBar, (CurrValue + PredictedHealing) / MaxValue)
    else
      PredictedHealing = 0
      BBar:SetFillTexture(1, PredictedBar, 0)
    end
  end

  -- Set the color and display the value.
  BBar:SetColorTexture(1, StatusBar, r, g, b, a)
  local Value = 0

  if MaxValue > 0 then
    Value = CurrValue / MaxValue
  end
  BBar:SetFillTexture(1, StatusBar, Value)
  if not UB.Layout.HideText then
    BBar:SetValueFont(1, 'current', CurrValue, 'maximum', MaxValue, 'predicted', PredictedHealing, 'unit', Unit)
  end

  -- Check triggers
  if UB.Layout.EnableTriggers then
    BBar:SetTriggers(1, 'health', CurrValue)
    BBar:SetTriggers(1, 'health (percent)', CurrValue, MaxValue)
    BBar:SetTriggers(1, 'predicted health', PredictedHealing)
    BBar:DoTriggers()
  end

  -- Set the IsActive flag.
  self.IsActive = CurrValue < MaxValue or PredictedHealing > 0

  -- Do a status check.
  self:StatusCheck()
end

function Main.UnitBarsF.PlayerHealth:Update(Event)
  UpdateHealthBar(self, Event, 'player')
end

function Main.UnitBarsF.TargetHealth:Update(Event)
  UpdateHealthBar(self, Event, 'target')
end

function Main.UnitBarsF.FocusHealth:Update(Event)
  UpdateHealthBar(self, Event, 'focus')
end

function Main.UnitBarsF.PetHealth:Update(Event)
  UpdateHealthBar(self, Event, 'pet')
end

-------------------------------------------------------------------------------
-- UpdatePowerBar
--
-- Updates the power of the unit.
--
-- self          UnitBarF contains the power bar to display.
-- Event         Event that called this function.  If nil then it wasn't called by an event.
--               True bypasses visible and isactive flags.
-- Unit          Unit name 'player' ,'target', etc
-- PowerType2    PowerType from server or when PowerMana update is called.
--               If nil then the unit's powertype is used if nots a ManaPower bar.
-------------------------------------------------------------------------------
local function UpdatePowerBar(self, Event, Unit, PowerType2)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  -- Convert string powertype into number.
  PowerType2 = ConvertPowerType[PowerType2]

  local PowerType = nil

  if self.BarType ~= 'ManaPower' then
    PowerType = UnitPowerType(Unit)
    if PowerType2 ~= nil and PowerType ~= PowerType2 then

      -- Return, not correct power type.
      return
    end

  -- ManaPower bar can only be a mana powertype.
  elseif PowerType2 == PowerMana then
    PowerType = PowerMana
  else

    -- Return, not correct power type.
    return
  end

  local BBar = self.BBar
  local UB = self.UnitBar
  local Bar = UB.Bar
  local Gen = UB.General

  local CurrValue = UnitPower(Unit, PowerType)
  local MaxValue = UnitPowerMax(Unit, PowerType)
  local PredictedPower = Gen and Gen.PredictedPower and (self.PredictedPower or 0) or 0
  local UseBarColor = Gen.UseBarColor or false
  local r, g, b, a = 1, 1, 1, 1

  if UseBarColor then
    local Color = Bar.Color
    r, g, b, a = Color.r, Color.g, Color.b, Color.a
  else
    r, g, b, a = Main:GetPowerColor(Unit, PowerType)
  end

  if Main.UnitBars.Testing then
    local TestMode = UB.TestMode
    local PredictedValue = TestMode.PredictedValue

    MaxValue = MaxValue == 0 and 10000 or MaxValue
    CurrValue = floor(MaxValue * TestMode.Value)
    PredictedPower = PredictedValue and floor(MaxValue * PredictedValue) or 0
  end

  -- Set the color and display the predicted health.
  local PredictedColor = Bar.PredictedColor

  if PredictedColor then
    if PredictedPower > 0 and CurrValue < MaxValue then
      BBar:SetColorTexture(1, PredictedBar, PredictedColor.r, PredictedColor.g, PredictedColor.b, PredictedColor.a)
      BBar:SetFillTexture(1, PredictedBar, (CurrValue + PredictedPower) / MaxValue)
    else
      PredictedPower = 0
      BBar:SetFillTexture(1, PredictedBar, 0)
    end
  end

  -- Set the color and display the value.
  BBar:SetColorTexture(1, StatusBar, r, g, b, a)
  local Value = 0

  if MaxValue > 0 then
    Value = CurrValue / MaxValue
  end
  BBar:SetFillTexture(1, StatusBar, Value)
  if not UB.Layout.HideText then
    BBar:SetValueFont(1, 'current', CurrValue, 'maximum', MaxValue, 'predicted', PredictedPower, 'unit', Unit)
  end

  -- Check triggers
  if UB.Layout.EnableTriggers then
    BBar:SetTriggers(1, 'power', CurrValue)
    BBar:SetTriggers(1, 'power (percent)', CurrValue, MaxValue)
    BBar:SetTriggers(1, 'predicted power', PredictedPower)
    BBar:DoTriggers()
  end

  -- Set the IsActive flag.
  local IsActive = false
  if PowerType == PowerMana or PowerType == PowerEnergy or PowerType == PowerFocus then
    if CurrValue < MaxValue or PredictedPower > 0 then
      IsActive = true
    end
  else
    if CurrValue > 0 then
      if self.BarType == 'PlayerPower' then
      end
      IsActive = true
    end
  end
  self.IsActive = IsActive

  -- Do a status check.
  self:StatusCheck()
end

function Main.UnitBarsF.PlayerPower:Update(Event)
  UpdatePowerBar(self, Event, 'player')
end

function Main.UnitBarsF.TargetPower:Update(Event)
  UpdatePowerBar(self, Event, 'target')
end

function Main.UnitBarsF.FocusPower:Update(Event)
  UpdatePowerBar(self, Event, 'focus')
end

function Main.UnitBarsF.PetPower:Update(Event)
  UpdatePowerBar(self, Event, 'pet')
end

function Main.UnitBarsF.ManaPower:Update(Event)
  UpdatePowerBar(self, Event, 'player', 'MANA')
end

--*****************************************************************************
--
-- Health and Power bar creation/setting
--
--*****************************************************************************

------------------------------------------------------------------------------
-- EnableMouseClicks
--
-- This will enable or disbale mouse clicks for the rune icons.
-------------------------------------------------------------------------------
HapFunction('EnableMouseClicks', function(self, Enable)
  self.BBar:EnableMouseClicks(1, nil, Enable)
end)

-------------------------------------------------------------------------------
-- SetAttr
--
-- Sets different parts of the health and power bars.
-------------------------------------------------------------------------------
HapFunction('SetAttr', function(self, TableName, KeyName)
  local BBar = self.BBar
  local BarType = self.BarType
  local UB = self.UnitBar
  local Gen = UB.General

  if not BBar:OptionsSet() then
    BBar:SetTexture(1, PredictedBar, 'GUB EMPTY')

    BBar:SO('Text', '_Font', function() BBar:UpdateFont(1) Update = true end)
    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers', function(v)
      if strfind(BarType, 'Power') then
        BBar:EnableTriggers(v, PowerGroups)
      else
        BBar:EnableTriggers(v, HealthGroups)
      end
      Display = true
    end)

    BBar:SO('Layout', 'ReverseFill',    function(v) BBar:ChangeTexture(StatusBars, 'SetFillReverseTexture', 1, v) end)
    BBar:SO('Layout', 'HideText',       function(v)
      if v then
        BBar:SetValueRawFont(1, '')
      else
        Update = true
      end
    end)
    BBar:SO('Layout', 'SmoothFill',  function(v) BBar:SetFillSmoothTimeTexture(1, StatusBar, v) end)

    if Gen then
      if Gen.UseBarColor ~= nil then
        BBar:SO('General', 'UseBarColor', function(v) Update = true end)
      end

      if Gen.PredictedHealth ~= nil then
        BBar:SO('General', 'PredictedHealth', function(v) Update = true end)
      end

      if Gen.ClassColor ~= nil then
        BBar:SO('General', 'ClassColor', function(v) Update = true end)
      end

      if Gen.CombatColor ~= nil then
        BBar:SO('General', 'CombatColor', function(v) Update = true end)
      end

      if Gen.TaggedColor ~= nil then
        BBar:SO('General', 'TaggedColor', function(v) Update = true end)
      end
    end

    if BarType == 'PlayerPower' and Main.PlayerClass == 'HUNTER' then
      BBar:SO('General', 'PredictedPower', function(v)
        if v then
          Main:SetSpellTracker(self, 'fn', SpellSteadyShot, 'casting', CheckSpell)
          Main:SetSpellTracker(self, 'fn', SpellCobraShot,  'casting', CheckSpell)
          Main:SetSpellTracker(self, 'fn', FocusingShot,    'casting', CheckSpell)
        else
          Main:SetSpellTracker(self, 'off')
        end
        self.PredictedPower = 0
        Update = true
      end)
    end

    BBar:SO('Background', 'BgTexture',     function(v) BBar:SetBackdrop(1, 1, v) end)
    BBar:SO('Background', 'BorderTexture', function(v) BBar:SetBackdropBorder(1, 1, v) end)
    BBar:SO('Background', 'BgTile',        function(v) BBar:SetBackdropTile(1, 1, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v) BBar:SetBackdropTileSize(1, 1, v) end)
    BBar:SO('Background', 'BorderSize',    function(v) BBar:SetBackdropBorderSize(1, 1, v) end)
    BBar:SO('Background', 'Padding',       function(v) BBar:SetBackdropPadding(1, 1, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v) BBar:SetBackdropColor(1, 1, v.r, v.g, v.b, v.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB)
      if UB.Background.EnableBorderColor then
        BBar:SetBackdropBorderColor(1, 1, v.r, v.g, v.b, v.a)
      else
        BBar:SetBackdropBorderColor(1, 1, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',    function(v) BBar:SetTexture(1, StatusBar, v) end)
    BBar:SO('Bar', 'FillDirection',       function(v) BBar:ChangeTexture(StatusBars, 'SetFillDirectionTexture', 1, v) end)
    BBar:SO('Bar', 'RotateTexture',       function(v) BBar:ChangeTexture(StatusBars, 'SetRotateTexture', 1, v) end)

    if UB.Bar.PredictedColor ~= nil then
      BBar:SO('Bar', 'PredictedBarTexture', function(v) BBar:SetTexture(1, PredictedBar, v) end)
      BBar:SO('Bar', 'PredictedColor',      function(v) BBar:SetColorTexture(1, PredictedBar, v.r, v.g, v.b, v.a) end)
    end

    if Gen and Gen.FactionColor ~= nil then
      BBar:SO('Bar', 'FactionColor',        function(v, UB) Update = true end)
    end

    if UB.Bar.Color ~= nil then
      BBar:SO('Bar', 'Color',               function(v) Update = true end)
    end
    BBar:SO('Bar', 'TaggedColor',           function(v, UB) Update = true end)

    BBar:SO('Bar', '_Size',                 function(v, UB) BBar:SetSizeTextureFrame(1, 1, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',               function(v) BBar:ChangeTexture(StatusBars, 'SetPaddingTexture', 1, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
end)

-------------------------------------------------------------------------------
-- CreateBar
--
-- UnitBarF     The unitbar frame which will contain the health and power bar.
-- UB           Unitbar data.
-- Anchor       Unitbar's anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.HapBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, 1)

  -- Create the health and predicted bar
  BBar:CreateTextureFrame(1, 1, 0)
    BBar:CreateTexture(1, 1, 'statusbar', 1, PredictedBar)
    BBar:CreateTexture(1, 1, 'statusbar', 2, StatusBar)

  -- Create font text for the box frame.
  BBar:CreateFont(1, PercentFn)

  -- Enable tooltip
  BBar:SetTooltip(1, nil, UB.Name)

  -- Use setchange for both statusbars.
  BBar:SetChangeTexture(StatusBars, PredictedBar, StatusBar)

  -- Show the bars.
  BBar:SetHidden(1, 1, false)
  BBar:ChangeTexture(StatusBars, 'SetHiddenTexture', 1, false)
  BBar:ChangeTexture(StatusBars, 'SetFillTexture', 1, 0)

  -- Set this for trigger bar offsets
  BBar:SetOffsetTextureFrame(1, 1, 0, 0, 0, 0)

  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Health and Power bar Enable/Disable functions
--
--*****************************************************************************

local function RegEventHealth(Enable, UnitBarF, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_HEAL_PREDICTION', UpdateHealthBar, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_HEALTH_FREQUENT', UpdateHealthBar, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_MAXHEALTH',       UpdateHealthBar, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_FACTION',         UpdateHealthBar, ...)
end

local function RegEventPower(Enable, UnitBarF, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_POWER_FREQUENT', UpdatePowerBar, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_MAXPOWER',       UpdatePowerBar, ...)
end

function Main.UnitBarsF.PlayerHealth:Enable(Enable)
  RegEventHealth(Enable, self, 'player')
end

function Main.UnitBarsF.TargetHealth:Enable(Enable)
  RegEventHealth(Enable, self, 'target')
end

function Main.UnitBarsF.FocusHealth:Enable(Enable)
  RegEventHealth(Enable, self, 'focus')
end

function Main.UnitBarsF.PetHealth:Enable(Enable)
  RegEventHealth(Enable, self, 'pet')
end

function Main.UnitBarsF.PlayerPower:Enable(Enable)
  RegEventPower(Enable, self, 'player')
end

function Main.UnitBarsF.TargetPower:Enable(Enable)
  RegEventPower(Enable, self, 'target')
end

function Main.UnitBarsF.FocusPower:Enable(Enable)
  RegEventPower(Enable, self, 'focus')
end

function Main.UnitBarsF.PetPower:Enable(Enable)
  RegEventPower(Enable, self, 'pet')
end

function Main.UnitBarsF.ManaPower:Enable(Enable)
  RegEventPower(Enable, self, 'player')
end
