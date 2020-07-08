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
local OT = Bar.TriggerObjectTypes
local DUB = GUB.DefaultUB.Default.profile

local UnitBarsF = Main.UnitBarsF
local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _, _G =
      _, _G
local floor, strfind, pairs, print =
      floor, strfind, pairs, print
local GetSpellPowerCost, UnitHealth, UnitHealthMax, UnitLevel, UnitEffectiveLevel, UnitGetIncomingHeals, UnitGetTotalAbsorbs =
      GetSpellPowerCost, UnitHealth, UnitHealthMax, UnitLevel, UnitEffectiveLevel, UnitGetIncomingHeals, UnitGetTotalAbsorbs
local UnitExists, UnitName, UnitPowerType, UnitPower, UnitPowerMax =
      UnitExists, UnitName, UnitPowerType, UnitPower, UnitPowerMax

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.PredictedSpellID   The current spell whos predicted power is being shown.
-- UnitBarF.PredictedPower     Current predicted power in progress
-------------------------------------------------------------------------------
local Display = false
local Update = false

local HapBox = 1
local HapTFrame = 1

local StatusBar = 10
local PredictedBar = 20
local AbsorbBar = 30
local PredictedCostBar = 40

-- Powertype constants
local PowerMana = ConvertPowerType['MANA']
local PowerEnergy = ConvertPowerType['ENERGY']
local PowerFocus = ConvertPowerType['FOCUS']

local ObjectsInfo = { -- type, id, additional menu text, textures
  { OT.BackgroundBorder,      1,  '',                HapTFrame        },
  { OT.BackgroundBorderColor, 2,  '',                HapTFrame        },
  { OT.BackgroundBackground,  3,  '',                HapTFrame        },
  { OT.BackgroundColor,       4,  '',                HapTFrame        },
  { OT.BarTexture,            5,  '',                StatusBar        },
  { OT.BarColor,              6,  '',                StatusBar        },
  { OT.BarTexture,            7,  ' (predicted...)', PredictedBar     },
  { OT.BarColor,              8,  ' (predicted...)', PredictedBar     },
  { OT.BarTexture,            9,  ' (cost)',         PredictedCostBar },
  { OT.BarColor,              10, ' (cost)',         PredictedCostBar },
  { OT.BarOffset,             11, '',                HapTFrame        },
  { OT.TextFontColor,         12, ''                                  },
  { OT.TextFontOffset,        13, ''                                  },
  { OT.TextFontSize,          14, ''                                  },
  { OT.TextFontType,          15, ''                                  },
  { OT.TextFontStyle,         16, ''                                  },
  { OT.Sound,                 17, ''                                  },
}

local GroupsInfoHealth = { -- BoxNumber, Name, ValueTypes
  ValueNames = {
    'whole',   'Health',
    'percent', 'Health (percent)',
    'whole',   'Predicted Health',
    'whole',   'Absorb Health',
    'whole',   'Unit Level',
    'whole',   'Scaled Level',
  },
  {1, 'Health', ObjectsInfo}, -- 1
}
local GroupsInfoPower = { -- BoxNumber, Name, ValueTypes,
  ValueNames = {
    'whole',   'Power',
    'percent', 'Power (percent)',
    'whole',   'Predicted Power',
    'whole',   'Predicted Cost',
    'whole',   'Unit Level',
    'whole',   'Scaled Level',
  },
  {1, 'Power', ObjectsInfo}, -- 1
}

-------------------------------------------------------------------------------
-- HapFunction
--
-- Assigns a function to all the health and power bars under one name.
--
-------------------------------------------------------------------------------
local function HapFunction(Name, Fn)
  for BarType, UBF in pairs(UnitBarsF) do
    if UBF.IsHealth or UBF.IsPower then
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
-- Casting
--
-- Gets called when a spell is being cast.
--
-- UnitBarF     Bar thats tracking casts
-- SpellID      Spell that is being cast
-- Message      See Main.lua for list of messages
-------------------------------------------------------------------------------
local function Casting(UnitBarF, SpellID, Message)
  UnitBarF.PredictedSpellID = 0
  UnitBarF.PredictedPower = 0
  UnitBarF.PredictedCost = 0

  if Message == 'start' then
    local BarPowerType

    if UnitBarF.BarType == 'ManaPower' then
      BarPowerType = PowerMana
    else
      BarPowerType = Main.PlayerPowerType
    end

    -- get predicted power
    local PredictedPower, PowerType = Main:GetPredictedSpell(UnitBarF, SpellID)

    if PredictedPower > 0 and PowerType == BarPowerType then
      UnitBarF.PredictedSpellID = SpellID
      UnitBarF.PredictedPower = PredictedPower

    -- Get predicted cost
    elseif UnitBarF.UnitBar.Layout.PredictedCost then
      local CostTable = GetSpellPowerCost(SpellID)

      for _, CostInfo in pairs(CostTable) do
        if CostInfo.type == BarPowerType then
          UnitBarF.PredictedCost = CostInfo.cost
          break
        end
      end
    end
  end

  UnitBarF:Update()
end

-------------------------------------------------------------------------------
-- PredictedSpells
--
-- Gets called when a spell in the spellbook has a power value change
--
-- UnitBarF      Bar thats using predicted spells.
-- SpellID       Spell whos amount of power changed.
-- Amount        New amount.
-------------------------------------------------------------------------------
local function PredictedSpells(UnitBarF, SpellID, Amount)

  -- Only change the one thats currently casting.
  if UnitBarF.PredictedSpellID == SpellID then
    UnitBarF.PredictedPower = Amount
    UnitBarF:Update()
  end
end

-------------------------------------------------------------------------------
-- SetPredictedCost
--
-- Turns on predicted cost.  This will show how much resource a spell will cost
-- that has a cast time.
--
-- Usage: SetPredictedCost(UnitBarF, true or false)
--
-- UnitBarF   Tracks cost just for this bar.
-- true       Turn on predicted cost otherwise turn it off.
-------------------------------------------------------------------------------
local function SetPredictedCost(UnitBarF, Action)
  UnitBarF.BBar:SetHiddenTexture(HapBox, PredictedCostBar, not Action)

  if Action then
    Main:SetCastTracker(UnitBarF, 'fn', Casting)

  else
    local PredictedPower = UnitBarF.UnitBar.Layout.PredictedPower or false

    if not PredictedPower then
      Main:SetCastTracker(UnitBarF, 'off')
      UnitBarF.PredictedCost = 0
    end
  end
end

-------------------------------------------------------------------------------
-- SetPredictedPower
--
-- Finds spells in the player spellbook with cast times that return power.
--
-- Usage: SetPredictedPower(UnitBarF, true or false)
--
-- UnitBarF   Tracks spells just for this bar.
-- true       Turn on predicted power otherwise turn it off.
-------------------------------------------------------------------------------
local function SetPredictedPower(UnitBarF, Action)
  UnitBarF.BBar:SetHiddenTexture(HapBox, PredictedBar, not Action)

  if Action then
    Main:SetPredictedSpells(UnitBarF, 'on', PredictedSpells)
    Main:SetCastTracker(UnitBarF, 'fn', Casting)
  else
    Main:SetPredictedSpells(UnitBarF, 'off')
    local PredictedCost = UnitBarF.UnitBar.Layout.PredictedCost or false

    if not PredictedCost then
      Main:SetCastTracker(UnitBarF, 'off')
    end

    UnitBarF.PredictedPower = 0
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
-- Unit         Ignored just here for reference
-------------------------------------------------------------------------------
local function UpdateHealthBar(self, Event, Unit)

  ---------------
  -- Set IsActive
  ---------------
  local UB = self.UnitBar
  Unit = UB.UnitType
  local Layout = UB.Layout

  local CurrValue = UnitHealth(Unit)
  local MaxValue = UnitHealthMax(Unit)
  local Level = UnitLevel(Unit)
  local ScaledLevel = UnitEffectiveLevel(Unit)
  local PredictedHealing = Layout.PredictedHealth and UnitGetIncomingHeals(Unit) or 0

  self.IsActive = CurrValue < MaxValue or PredictedHealing > 0

  --------
  -- Check
  --------
  local LastHidden = self.Hidden
  self:StatusCheck()
  local Hidden = self.Hidden

  -- If not called by an event and Hidden is true then return
  if Event == nil and Hidden or LastHidden and Hidden then
    return
  end

  ------------
  -- Test Mode
  ------------
  local BBar = self.BBar
  local AbsorbHealth = Layout.AbsorbHealth and UnitGetTotalAbsorbs(Unit) or 0

  if Main.UnitBars.Testing then
    local TestMode = UB.TestMode
    local PredictedHealth = Layout.PredictedHealth and TestMode.PredictedHealth or 0
    local AbsorbHealth2 = Layout.AbsorbHealth and TestMode.AbsorbHealth or 0

    self.Testing = true

    MaxValue = MaxValue > 10000 and MaxValue or 10000
    CurrValue = floor(MaxValue * TestMode.Value)
    PredictedHealing = floor(MaxValue * PredictedHealth)
    AbsorbHealth = floor(MaxValue * AbsorbHealth2)

    Level = TestMode.UnitLevel
    ScaledLevel = TestMode.ScaledLevel

  -- Just switched out of test mode do a clean up.
  elseif self.Testing then
    self.Testing = false

    if MaxValue == 0 then
      BBar:SetFillTexture(HapBox, PredictedBar, 0)
      BBar:SetFillTexture(HapBox, AbsorbBar, 0)
    end
  end

  -------
  -- Draw
  -------
  local Bar = UB.Bar
  local AbsorbBarDontClip = Bar.AbsorbBarDontClip or false
  local AbsorbBarSize = Bar.AbsorbBarSize

  local Name, Realm = UnitName(Unit)
  Name = Name or ''

  local ClassColor = Layout.ClassColor or false
  local CombatColor = Layout.CombatColor or false
  local TaggedColor = Layout.TaggedColor or false
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

  AbsorbHealth = AbsorbHealth * AbsorbBarSize
  local Value = 0
  local AbsorbValue = 0
  local PredictedValue = 0

  if MaxValue > 0 then
    Value = CurrValue / MaxValue
    PredictedValue = PredictedHealing / MaxValue
    AbsorbValue = AbsorbHealth / MaxValue

    -- Clip AbsorbValue
    if AbsorbValue > AbsorbBarSize then
      AbsorbValue = AbsorbBarSize
    end
    local Total = Value + PredictedValue + AbsorbValue

    -- Calculate clipping. It's done this way to look good
    -- with smooth fill
    if AbsorbBarDontClip and AbsorbHealth > 0 and Total > 1 then
      Value = Value - (Total - 1)
    end
  end

  if MaxValue > 0 then

    -- Do predicted healing
    if self.LastPredictedHealing ~= PredictedHealing then
      BBar:SetFillLengthTexture(HapBox, PredictedBar, PredictedValue)
      self.LastPredictedHealing = PredictedHealing
    end

    -- Do absorb health
    if self.LastAbsorbValue ~= AbsorbValue then
      BBar:SetFillLengthTexture(HapBox, AbsorbBar, AbsorbValue)
      self.LastAbsorbValue = AbsorbValue
    end
  end

  -- Set the color and display the value.
  BBar:SetColorTexture(HapBox, StatusBar, r, g, b, a)
  BBar:SetFillTexture(HapBox, StatusBar, Value)

  if not UB.Layout.HideText then
    if PredictedHealing > 0 and AbsorbHealth > 0 then
      BBar:SetValueFont(HapBox, 'current', CurrValue, 'maximum', MaxValue, 'predictedhealth', PredictedHealing, 'absorbhealth', AbsorbHealth, 'level', Level, ScaledLevel, 'name', Name, Realm)
    elseif PredictedHealing > 0 and AbsorbHealth == 0 then
      BBar:SetValueFont(HapBox, 'current', CurrValue, 'maximum', MaxValue, 'predictedhealth', PredictedHealing, 'level', Level, ScaledLevel, 'name', Name, Realm)
    elseif PredictedHealing == 0 and AbsorbHealth > 0 then
      BBar:SetValueFont(HapBox, 'current', CurrValue, 'maximum', MaxValue, 'absorbhealth', AbsorbHealth, 'level', Level, ScaledLevel, 'name', Name, Realm)
    else
      BBar:SetValueFont(HapBox, 'current', CurrValue, 'maximum', MaxValue, 'level', Level, ScaledLevel, 'name', Name, Realm)
    end
  end

  -- Check triggers
  if UB.Layout.EnableTriggers then
    BBar:SetTriggers('Health', CurrValue)
    BBar:SetTriggers('Health (percent)', CurrValue, MaxValue)
    BBar:SetTriggers('Predicted Health', PredictedHealing)
    BBar:SetTriggers('Absorb Health', AbsorbHealth)
    BBar:SetTriggers('Unit Level', Level)
    BBar:SetTriggers('Scaled Level', ScaledLevel)
    BBar:DoTriggers()
  end
end

Main.UnitBarsF.PlayerHealth.Update = UpdateHealthBar
Main.UnitBarsF.TargetHealth.Update = UpdateHealthBar
Main.UnitBarsF.FocusHealth.Update  = UpdateHealthBar
Main.UnitBarsF.PetHealth.Update    = UpdateHealthBar

-------------------------------------------------------------------------------
-- UpdatePowerBar
--
-- Updates the power of the unit.
--
-- self          UnitBarF contains the power bar to display.
-- Event         Event that called this function.  If nil then it wasn't called by an event.
-- Unit          Ignored just here for reference
-- PowerToken    String: PowerType in caps: MANA RAGE, etc
--               If nil then the units powertype is used instead
-------------------------------------------------------------------------------
local function UpdatePowerBar(self, Event, Unit, PowerToken)

  -------------------
  -- Check Power Type
  -------------------
  local UB = self.UnitBar
  local BarType = self.BarType
  local PowerType
  Unit = UB.UnitType
  PowerToken = ConvertPowerType[PowerToken]

  if BarType ~= 'ManaPower' then
    PowerType = UnitPowerType(Unit)

    -- Return if power types doesn't match that of the powerbar
    if PowerToken ~= nil and PowerToken ~= PowerType then
      return
    end
  elseif PowerToken == nil or PowerToken == PowerMana then
    PowerType = PowerMana
  else
    -- Return, not correct power type
    return
  end

  ---------------
  -- Set IsActive
  ---------------
  local CurrValue = UnitPower(Unit, PowerType)
  local MaxValue = UnitPowerMax(Unit, PowerType)
  local Level = UnitLevel(Unit)
  local ScaledLevel = UnitEffectiveLevel(Unit)

  local PredictedPower = self.PredictedPower or 0
  local PredictedCost = self.PredictedCost or 0

  local IsActive = false
  if UnitExists(Unit) then
    if PowerType == PowerMana or PowerType == PowerEnergy or PowerType == PowerFocus then
      if CurrValue < MaxValue or PredictedPower > 0 or PredictedCost > 0 then
        IsActive = true
      end
    else
      IsActive = CurrValue > 0
    end
  end
  self.IsActive = IsActive

  --------
  -- Check
  --------
  local LastHidden = self.Hidden
  self:StatusCheck()
  local Hidden = self.Hidden

  -- If not called by an event and Hidden is true then return
  if Event == nil and Hidden or LastHidden and Hidden then
    return
  end

  ------------
  -- Test Mode
  ------------
  local BBar = self.BBar
  local Layout = UB.Layout

  if Main.UnitBars.Testing then
    local TestMode = UB.TestMode
    local TestPredictedPower = Layout.PredictedPower and TestMode.PredictedPower or 0
    local TestPredictedCost = Layout.PredictedCost and TestMode.PredictedCost or 0

    self.Testing = true

    MaxValue = MaxValue > 10000 and MaxValue or 10000
    CurrValue = floor(MaxValue * TestMode.Value)
    PredictedPower = floor(MaxValue * TestPredictedPower)
    PredictedCost = floor(MaxValue * TestPredictedCost)

    Level = TestMode.UnitLevel
    ScaledLevel = TestMode.ScaledLevel

  -- Just switched out of test mode do a clean up.
  elseif self.Testing then
    self.Testing = false

    self.PredictedPower = 0
    self.PredictedCost = 0
    PredictedPower = 0
    PredictedCost = 0

    if MaxValue == 0 then
      BBar:SetFillTexture(HapBox, PredictedBar, 0)
      BBar:SetFillTexture(HapBox, PredictedCostBar, 0)
    end
  end

  -------
  -- Draw
  -------
  local Bar = UB.Bar

  local Name, Realm = UnitName(Unit)
  Name = Name or ''

  local UseBarColor = Layout.UseBarColor or false
  local r, g, b, a = 1, 1, 1, 1

  if UseBarColor then
    local Color = Bar.Color
    r, g, b, a = Color.r, Color.g, Color.b, Color.a
  else
    r, g, b, a = Main:GetPowerColor(Unit, PowerType, nil, nil, r, g, b, a)
  end

  local Value = 0

  if MaxValue > 0 then
    Value = CurrValue / MaxValue
  end

  if MaxValue > 0 then

    -- Do predicted power
    if self.LastPredictedPower ~= PredictedPower then
      BBar:SetFillLengthTexture(HapBox, PredictedBar, PredictedPower / MaxValue)
      self.LastPredictedPower = PredictedPower
    end

    -- Do predicted cost
    if self.LastPredictedCost ~= PredictedCost then
      BBar:SetFillLengthTexture(HapBox, PredictedCostBar, PredictedCost / MaxValue)
      self.LastPredictedCost = PredictedCost
    end
  end

  BBar:SetColorTexture(HapBox, StatusBar, r, g, b, a)
  BBar:SetFillTexture(HapBox, StatusBar, Value)

  if not UB.Layout.HideText then
    if PredictedPower > 0 and PredictedCost > 0 then
      BBar:SetValueFont(HapBox, 'current', CurrValue, 'maximum', MaxValue, 'predictedpower', PredictedPower, 'predictedcost', PredictedCost, 'level', Level, ScaledLevel, 'name', Name, Realm)
    elseif PredictedPower > 0 and PredictedCost == 0 then
      BBar:SetValueFont(HapBox, 'current', CurrValue, 'maximum', MaxValue, 'predictedpower', PredictedPower, 'level', Level, ScaledLevel, 'name', Name, Realm)
    elseif PredictedPower == 0 and PredictedCost > 0 then
      BBar:SetValueFont(HapBox, 'current', CurrValue, 'maximum', MaxValue, 'predictedcost', PredictedCost, 'level', Level, ScaledLevel, 'name', Name, Realm)
    else
      BBar:SetValueFont(HapBox, 'current', CurrValue, 'maximum', MaxValue, 'level', Level, ScaledLevel, 'name', Name, Realm)
    end
  end

  -- Check triggers
  if UB.Layout.EnableTriggers then
    BBar:SetTriggers('Power', CurrValue)
    BBar:SetTriggers('Power (percent)', CurrValue, MaxValue)
    BBar:SetTriggers('Predicted Power', PredictedPower)
    BBar:SetTriggers('Predicted Cost', PredictedCost)
    BBar:SetTriggers('Unit Level', Level)
    BBar:SetTriggers('Scaled Level', ScaledLevel)
    BBar:DoTriggers()
  end
end

Main.UnitBarsF.PlayerPower.Update = UpdatePowerBar
Main.UnitBarsF.TargetPower.Update = UpdatePowerBar
Main.UnitBarsF.FocusPower.Update  = UpdatePowerBar
Main.UnitBarsF.PetPower.Update    = UpdatePowerBar
Main.UnitBarsF.ManaPower.Update   = UpdatePowerBar

--*****************************************************************************
--
-- Health and Power bar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetAttr
--
-- Sets different parts of the health and power bars.
-------------------------------------------------------------------------------
HapFunction('SetAttr', function(self, TableName, KeyName)
  local BBar = self.BBar
  local BarType = self.BarType
  local UBD = DUB[BarType]
  local DLayout = UBD.Layout
  local DBar = UBD.Bar

  if not BBar:OptionsSet() then
    BBar:SetTexture(1, PredictedBar, 'GUB EMPTY')
    BBar:SetTexture(1, AbsorbBar, 'GUB EMPTY')
    BBar:SetTexture(1, PredictedCostBar, 'GUB EMPTY')

    BBar:SO('Text', '_Font', function() BBar:UpdateFont(1) Update = true end)

    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers', function(v)
      if strfind(BarType, 'Power') then
        BBar:EnableTriggers(v, GroupsInfoPower)
      else
        BBar:EnableTriggers(v, GroupsInfoHealth)
      end
      Update = true
    end)
    BBar:SO('Layout', 'ReverseFill',     function(v) BBar:SetFillReverseTexture(HapBox, StatusBar, v) Update = true end)
    BBar:SO('Layout', 'HideText',        function(v)
      if v then
        BBar:SetValueRawFont(1, '')
      else
        Update = true
      end
    end)
    BBar:SO('Layout', 'SmoothFillMaxTime', function(v) BBar:SetSmoothFillMaxTime(HapBox, StatusBar, v) end)
    BBar:SO('Layout', 'SmoothFillSpeed',   function(v) BBar:SetFillSpeedTexture(HapBox, StatusBar, v) end)

    if DLayout then
      -- More layout
      if DLayout.UseBarColor ~= nil then
        BBar:SO('Layout', 'UseBarColor', function(v) Update = true end)
      end
      if DLayout.PredictedHealth ~= nil then
        BBar:SO('Layout', 'PredictedHealth', function(v) Update = true end)
      end
      if DLayout.AbsorbHealth ~= nil then
        BBar:SO('Layout', 'AbsorbHealth', function(v) Update = true end)
      end

      if DLayout.ClassColor ~= nil then
        BBar:SO('Layout', 'ClassColor', function(v) Update = true end)
      end

      if DLayout.CombatColor ~= nil then
        BBar:SO('Layout', 'CombatColor', function(v) Update = true end)
      end

      if DLayout.TaggedColor ~= nil then
        BBar:SO('Layout', 'TaggedColor', function(v) Update = true end)
      end
    end

    -- More layout
    if DLayout.PredictedPower ~= nil then
      BBar:SO('Layout', 'PredictedPower', function(v) SetPredictedPower(self, v) Update = true end)
    end

    if DLayout.PredictedCost ~= nil then
      BBar:SO('Layout', 'PredictedCost', function(v) SetPredictedCost(self, v) Update = true end)
    end

    BBar:SO('Background', 'BgTexture',     function(v) BBar:SetBackdrop(HapBox, HapTFrame, v) end)
    BBar:SO('Background', 'BorderTexture', function(v) BBar:SetBackdropBorder(HapBox, HapTFrame, v) end)
    BBar:SO('Background', 'BgTile',        function(v) BBar:SetBackdropTile(HapBox, HapTFrame, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v) BBar:SetBackdropTileSize(HapBox, HapTFrame, v) end)
    BBar:SO('Background', 'BorderSize',    function(v) BBar:SetBackdropBorderSize(HapBox, HapTFrame, v) end)
    BBar:SO('Background', 'Padding',       function(v) BBar:SetBackdropPadding(HapBox, HapTFrame, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v) BBar:SetBackdropColor(HapBox, HapTFrame, v.r, v.g, v.b, v.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB)
      if UB.Background.EnableBorderColor then
        BBar:SetBackdropBorderColor(HapBox, HapTFrame, v.r, v.g, v.b, v.a)
      else
        BBar:SetBackdropBorderColor(HapBox, HapTFrame, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',    function(v) BBar:SetTexture(HapBox, StatusBar, v) end)
    BBar:SO('Bar', 'SyncFillDirection',   function(v) BBar:SyncFillDirectionTexture(HapBox, StatusBar, v) Update = true end)
    BBar:SO('Bar', 'Clipping',            function(v) BBar:SetClippingTexture(HapBox, StatusBar, v) Update = true end)
    BBar:SO('Bar', 'FillDirection',       function(v) BBar:SetFillDirectionTexture(HapBox, StatusBar, v) Update = true end)
    BBar:SO('Bar', 'RotateTexture',       function(v)


    BBar:SetRotationTexture(HapBox, StatusBar, v) end)

    if DBar.PredictedColor ~= nil then
      BBar:SO('Bar', 'PredictedBarTexture', function(v) BBar:SetTexture(HapBox, PredictedBar, v) end)
      BBar:SO('Bar', 'PredictedColor',      function(v) BBar:SetColorTexture(HapBox, PredictedBar, v.r, v.g, v.b, v.a) end)
    end

    if DBar.AbsorbColor ~= nil then
      BBar:SO('Bar', 'AbsorbBarTexture', function(v) BBar:SetTexture(HapBox, AbsorbBar, v) end)
      BBar:SO('Bar', 'AbsorbColor',      function(v) BBar:SetColorTexture(HapBox, AbsorbBar, v.r, v.g, v.b, v.a) end)
    end

    if DBar.PredictedCostColor ~= nil then
      BBar:SO('Bar', 'PredictedCostBarTexture', function(v) BBar:SetTexture(HapBox, PredictedCostBar, v) end)
      BBar:SO('Bar', 'PredictedCostColor',      function(v) BBar:SetColorTexture(HapBox, PredictedCostBar, v.r, v.g, v.b, v.a) end)
    end

    if DBar.Color ~= nil then
      BBar:SO('Bar', 'Color',               function(v) Update = true end)
    end
    BBar:SO('Bar', 'TaggedColor',           function(v, UB) Update = true end)

    BBar:SO('Bar', '_Absorb',               function()  Update = true end)
    BBar:SO('Bar', '_Size',                 function(v) BBar:SetSizeTextureFrame(HapBox, HapTFrame, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',               function(v) BBar:SetPaddingTextureFrame(HapBox, HapTFrame, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
  BBar:CreateTextureFrame(HapBox, HapTFrame, 1)
    BBar:CreateTexture(HapBox, HapTFrame, StatusBar, 'statusbar')
    BBar:CreateTexture(HapBox, HapTFrame, PredictedBar)
    BBar:CreateTexture(HapBox, HapTFrame, AbsorbBar)
    BBar:CreateTexture(HapBox, HapTFrame, PredictedCostBar)

  -- Create font text for the box frame.
  BBar:CreateFont('Text', HapBox)

  -- Enable tooltip
  BBar:SetTooltipBox(HapBox, UB.Name)

  -- Show the bar.
  BBar:SetHidden(HapBox, HapTFrame, false)
  BBar:SetHiddenTexture(HapBox, StatusBar, false)
  BBar:SetHiddenTexture(HapBox, PredictedBar, false)
  BBar:SetHiddenTexture(HapBox, PredictedCostBar, false)
  BBar:SetHiddenTexture(HapBox, AbsorbBar, false)

  BBar:SetFillTexture(HapBox, StatusBar, 0)
  BBar:SetFillTexture(HapBox, PredictedBar, 1)
  BBar:SetFillTexture(HapBox, PredictedCostBar, 1)
  BBar:SetFillTexture(HapBox, AbsorbBar, 1)

  -- Set this for trigger bar offsets
  BBar:SetOffsetTextureFrame(HapBox, HapTFrame, 0, 0, 0, 0)

  -- Set the tagged bars
  BBar:TagTexture(HapBox, StatusBar, PredictedBar, AbsorbBar)
  BBar:TagTexture(HapBox, StatusBar, PredictedCostBar)

  BBar:SetFillLengthTexture(HapBox, AbsorbBar, 0)
  BBar:SetFillLengthTexture(HapBox, PredictedBar, 0)
  BBar:SetFillLengthTexture(HapBox, PredictedCostBar, 0)
  BBar:TagLeftTexture(HapBox, PredictedCostBar, true)

  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Health and Power bar Enable/Disable functions
--
--*****************************************************************************

local function RegEventHealth(Enable, UnitBarF, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_HEAL_PREDICTION',       UpdateHealthBar, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_ABSORB_AMOUNT_CHANGED', UpdateHealthBar, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_HEALTH_FREQUENT',       UpdateHealthBar, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_MAXHEALTH',             UpdateHealthBar, ...)
  Main:RegEventFrame(Enable, UnitBarF, 'UNIT_FACTION',               UpdateHealthBar, ...)
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
