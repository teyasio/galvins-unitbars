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

local UnitBarsF = Main.UnitBarsF
local LSM = Main.LSM
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
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar         Contains the Health and power bar displayed on screen.
-- Display               Flag used to determin if a Display() call is needed.
-- StatusBar             TextureNumber for Status Bar
-- PredictedBar          TextureNumber for Predicted Bar
-- StatusBars            Change Texture for Status Bar and Predicted Bar.
-- SpellSteadyShot
-- SpellCobraShot        Hunter Spells to track for predicted power.
-- PredictedSpellValue   Predicted focus value based on the two above spells.
-- SteadyFocusAura       Buff hunters get that adds bonus focus.
-------------------------------------------------------------------------------
local Display = false

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

local PredictedSpellValue = {
  [0]               = 0,
  [SpellSteadyShot] = 14,
  [SpellCobraShot]  = 14,
}

local SteadyFocusAura = 53220

-- Amount of focus that gets added on to SteadyShot.
local SteadyFocusBonus = 3

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
    if SpellID == SpellSteadyShot then
      local Spell, TimeLeft = Main:CheckAura('o', SteadyFocusAura)
      if Spell then

        -- Add bonus focus if buff will be up by the time the cast is finished.
        if CastTime < TimeLeft then
          PredictedPower = PredictedPower + SteadyFocusBonus
        end
      end
    end

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
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-------------------------------------------------------------------------------
local function UpdateHealthBar(self, Event, Unit)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible and self.IsActive ~= 0 then
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
    PredictedHealing = Gen.PredictedHealth and 2500 or 0
    MaxValue = 10000
    CurrValue = 5000
  end

  -- Get the class color if classcolor flag is true.
  local Color = Bar.Color
  if Color.Class then
    local _, Class = UnitClass(Unit)
    if Class ~= nil then
      Color = Color[Class]
    end
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
  BBar:SetColorTexture(1, StatusBar, Color.r, Color.g, Color.b, Color.a)
  local Value = 0

  if MaxValue > 0 then
    Value = CurrValue / MaxValue
  end
  BBar:SetFillTexture(1, StatusBar, Value)
  if not UB.Layout.HideText then
    BBar:SetValueFont(1, nil, 'current', CurrValue, 'maximum', MaxValue, 'predicted', PredictedHealing, 'unit', Unit)
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
-- Unit          Unit name 'player' ,'target', etc
-- PowerType2    PowerType from server or when PowerMana update is called.
--               If nil then the unit's powertype is used if nots a ManaPower bar.
-------------------------------------------------------------------------------
local function UpdatePowerBar(self, Event, Unit, PowerType2)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible and self.IsActive ~= 0 then
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
  local Color = Bar.Color[ConvertPowerType[PowerType]]

  if Main.UnitBars.Testing then
    PredictedPower = Gen and Gen.PredictedPower and 2500 or 0
    MaxValue = 10000
    CurrValue = 5000
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
  BBar:SetColorTexture(1, StatusBar, Color.r, Color.g, Color.b, Color.a)
  local Value = 0

  if MaxValue > 0 then
    Value = CurrValue / MaxValue
  end
  BBar:SetFillTexture(1, StatusBar, Value)
  if not UB.Layout.HideText then
    BBar:SetValueFont(1, nil, 'current', CurrValue, 'maximum', MaxValue, 'predicted', PredictedPower, 'unit', Unit)
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

  if not BBar:OptionsSet() then
    BBar:SetTexture(1, PredictedBar, 'GUB EMPTY')

    BBar:SO('Text', '_Font', function() BBar:UpdateFont(1) self:Update() end)
    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'ReverseFill', function(v) BBar:ChangeTexture(StatusBars, 'SetFillReverseTexture', 1, v) end)
    BBar:SO('Layout', 'HideText',    function(v)
      if v then
        BBar:SetValueRawFont(1, nil, '')
      else
        self:Update()
      end
    end)
    BBar:SO('Layout', 'SmoothFill',  function(v) BBar:SetFillSmoothTimeTexture(1, StatusBar, v) end)

    local Gen = self.UnitBar.General
    if Gen and Gen.PredictedHealth ~= nil then
      BBar:SO('General', 'PredictedHealth', function() self:Update() end)
    end

    if BarType == 'PlayerPower' and Main.PlayerClass == 'HUNTER' then
      BBar:SO('General', 'PredictedPower', function(v)
        Main:SetSpellTracker(self, v)
        self.PredictedPower = 0
        self:Update()
      end)
    end

    BBar:SO('Background', 'BackdropSettings', function(v) BBar:SetBackdrop(1, 1, v) end)
    BBar:SO('Background', 'Color',            function(v) BBar:SetBackdropColor(1, 1, v.r, v.g, v.b, v.a) end)

    BBar:SO('Bar', 'StatusBarTexture',    function(v) BBar:SetTexture(1, StatusBar, v) end)
    BBar:SO('Bar', 'FillDirection',       function(v) BBar:ChangeTexture(StatusBars, 'SetFillDirectionTexture', 1, v) end)
    BBar:SO('Bar', 'RotateTexture',       function(v) BBar:ChangeTexture(StatusBars, 'SetRotateTexture', 1, v) end)

    if self.UnitBar.Bar.PredictedColor ~= nil then
      BBar:SO('Bar', 'PredictedBarTexture', function(v) BBar:SetTexture(1, PredictedBar, v) end)
      BBar:SO('Bar', 'PredictedColor',      function(v) BBar:SetColorTexture(1, PredictedBar, v.r, v.g, v.b, v.a) end)
    end
    BBar:SO('Bar', 'Color',               function(v, UB)
      local BarColor = nil

      -- Get the Unit and then Powertype for power bars.
      if strfind(BarType, 'Power') then
        local PowerType = nil

        if BarType == 'ManaPower' then
          PowerType = PowerMana
        else
          PowerType = UnitPowerType(UB.UnitType)
        end
        if PowerType then
          BarColor = v[ConvertPowerType[PowerType]]
        end

      -- Get the class color on bars that support it.
      else
        BarColor = v
        if BarColor.Class then
          local _, Class = UnitClass(UB.UnitType)

          if Class ~= nil then
            BarColor = BarColor[Class]
          end
        end
      end
      if BarColor then
        BBar:SetColorTexture(1, StatusBar, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
      end
    end)
    BBar:SO('Bar', '_Size',               function(v, UB) BBar:SetSizeTextureFrame(1, 1, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',             function(v) BBar:ChangeTexture(StatusBars, 'SetPaddingTexture', 1, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
  end

  -- Do the option.  This will call one of the options above or all.
  BBar:DoOption(TableName, KeyName)

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
  BBar:CreateFont(1, nil, PercentFn)

  -- Enable tooltip
  BBar:SetTooltip(1, nil, UB.Name)

  -- Use setchange for both statusbars.
  BBar:SetChangeTexture(StatusBars, PredictedBar, StatusBar)

  -- Show the bars.
  BBar:SetHidden(1, 1, false)
  BBar:ChangeTexture(StatusBars, 'SetHiddenTexture', 1, false)
  BBar:ChangeTexture(StatusBars, 'SetFillTexture', 1, 0)

  -- save the health and power bar
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
