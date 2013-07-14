--
-- HealthPower.lua
--
-- Displays health and power bars.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local UnitBarsF = GUB.UnitBarsF
local LSM = GUB.LSM
local PowerTypeToNumber = GUB.PowerTypeToNumber
local MouseOverDesc = GUB.MouseOverDesc

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin
local strfind, strsub, strupper, strlower, format, strconcat, strmatch, gsub, tonumber =
      strfind, strsub, strupper, strlower, format, strconcat, strmatch, gsub, tonumber
local pcall, pairs, ipairs, type, select, next, print, sort =
      pcall, pairs, ipairs, type, select, next, print, sort
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, GetSpellInfo, GetTalentInfo, PlaySound =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, GetSpellInfo, GetTalentInfo, PlaySound
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
-- UnitBarF.UnitBar           Reference to the unitbar data for the health and power bar.
-- UnitBarF.Border            Border frame for the health and power bar.
-- UnitBarF.StatusBar         The Statusbar for the health and power bar.
-- UnitBarF.PredictedBar      This is another statusbar that sits behind StatusBar.  This is used for
--                            predicted health.
--
-- Border.Anchor              Reference to the anchor for moving.
-- Border.UnitBarF            Reference to unitbarF for for onsizechange.
--
-- StatusBar.UnitBar          Reference to unitbar data for GetStatusBarTextValue()
--
-- PlayerClass                The players class.
-------------------------------------------------------------------------------
local PlayerClass = nil

-- Powertype constants
local PowerMana = PowerTypeToNumber['MANA']
local PowerEnergy = PowerTypeToNumber['ENERGY']
local PowerFocus = PowerTypeToNumber['FOCUS']

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
-- Usage:  HapFunction(Name, function()
--           -- do function stuff here
--         end)
-------------------------------------------------------------------------------
local function HapFunction(Name, Fn)
  for BarType, UBF in pairs(UnitBarsF) do
    if strfind(BarType, 'Health') or strfind(BarType, 'Power') then
      UBF[Name] = Fn
    end
  end
end

-------------------------------------------------------------------------------
-- ShareData
--
-- Main.lua calls this when values change.
--
-- NOTE: See Main.lua on how this is called.
-------------------------------------------------------------------------------
HapFunction('ShareData', function(UB, PC, PPT)
  PlayerClass = PC
end)

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

  -- Remove
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

-------------------------------------------------------------------------------
-- SetStatusBarValue
--
-- Sets the minimum, maximum, and text value to the StatusBar.
--
-- Usage: SetStatusBarValue(UnitBarF, CurrValue, MaxValue, PredictedValue)
--
-- UnitBarF        Frame that text is being created for.
-- CurrValue       Current value to set.
-- MaxValue        Maximum value to set.
-- PredictedValue  Predicted health or power.
--
-- Note: If there's an error in setting the text value then an error message will
--       be set instead.
-------------------------------------------------------------------------------

-- Used by SetTextValues to calculate percentage.
local function PercentFn(Value, MaxValue)
  return ceil(Value / MaxValue * 100)
end

local function SetStatusBarValue(UnitBarF, CurrValue, MaxValue, PredictedValue)
  local StatusBar = UnitBarF.StatusBar

  StatusBar:SetMinMaxValues(0, MaxValue)
  StatusBar:SetValue(CurrValue)

  local returnOK, msg = Main:SetTextValues(UnitBarF.UnitBar.Text.TextType, UnitBarF.Txt, PercentFn, CurrValue, MaxValue, PredictedValue)
  if not returnOK then
    UnitBarF.Txt:SetText('Layout Err Text')
  end

  returnOK, msg = Main:SetTextValues(UnitBarF.UnitBar.Text2.TextType, UnitBarF.Txt2, PercentFn, CurrValue, MaxValue, PredictedValue)
  if not returnOK then
    UnitBarF.Txt2:SetText('Layout Err Text2')
  end
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
-- Usage: UpdateHealthBar(self, Event, Unit)

-- self         UnitBarF contains the health bar to display.
-- Event        Event that called this function.  If nil then it wasn't called by an event.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-------------------------------------------------------------------------------
local function UpdateHealthBar(self, Event, Unit)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible and self.IsActive ~= 0 then
    return
  end

  local CurrValue = UnitHealth(Unit)
  local MaxValue = UnitHealthMax(Unit)

  local Gen = self.UnitBar.General
  local PredictedHealing = UnitGetIncomingHeals(Unit) or 0
  local Bar = self.UnitBar.Bar
  local PredictedBar = self.PredictedBar

  -- Get the class color if classcolor flag is true.
  local Color = Bar.Color
  if Bar.ClassColor then
    local Class = select(2, UnitClass(Unit))
    if Class ~= nil then
      Color = Color[Class]
    end
  end

  -- Set the color and display the predicted health.
  local PredictedColor = Bar.PredictedColor
  if PredictedColor and PredictedHealing > 0 and CurrValue < MaxValue then
    PredictedBar:SetStatusBarColor(PredictedColor.r, PredictedColor.g, PredictedColor.b, PredictedColor.a)
    PredictedBar:SetMinMaxValues(0, MaxValue)
    PredictedBar:SetValue(CurrValue + PredictedHealing)
  else
    PredictedHealing = 0
    PredictedBar:SetValue(0)
  end

  -- Set the color and display the value.
  self.StatusBar:SetStatusBarColor(Color.r, Color.g, Color.b, Color.a)
  SetStatusBarValue(self, CurrValue, MaxValue, PredictedHealing)

  -- Set the IsActive flag.
  self.IsActive = CurrValue < MaxValue or PredictedHealing > 0

  -- Do a status check.
  self:StatusCheck()
end

function GUB.UnitBarsF.PlayerHealth:Update(Event)
  UpdateHealthBar(self, Event, 'player')
end

function GUB.UnitBarsF.TargetHealth:Update(Event)
  UpdateHealthBar(self, Event, 'target')
end

function GUB.UnitBarsF.FocusHealth:Update(Event)
  UpdateHealthBar(self, Event, 'focus')
end

function GUB.UnitBarsF.PetHealth:Update(Event)
  UpdateHealthBar(self, Event, 'pet')
end

-------------------------------------------------------------------------------
-- UpdatePowerBar
--
-- Updates the power of the unit.
--
-- Usage: UpdatePowerBar(self, Event, Unit, PowerType2)
--
-- self          UnitBarF contains the power bar to display.
-- Event         'change' then the bar will only get updated if there is a change.
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
  PowerType2 = PowerTypeToNumber[PowerType2]

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

  local CurrValue = UnitPower(Unit, PowerType)
  local MaxValue = UnitPowerMax(Unit, PowerType)
  local PredictedPower = self.PredictedPower or 0

  local Bar = self.UnitBar.Bar
  local Color = Bar.Color[PowerType]

  local PredictedBar = self.PredictedBar

  -- Set the color and display the predicted health.
  local PredictedColor = Bar.PredictedColor
  if PredictedColor and PredictedPower > 0 and CurrValue < MaxValue then
    PredictedBar:SetStatusBarColor(PredictedColor.r, PredictedColor.g, PredictedColor.b, PredictedColor.a)
    PredictedBar:SetMinMaxValues(0, MaxValue)
    PredictedBar:SetValue(CurrValue + PredictedPower)
  else
    PredictedPower = 0
    PredictedBar:SetValue(0)
  end

  -- Set the color and display the value.
  self.StatusBar:SetStatusBarColor(Color.r, Color.g, Color.b, Color.a)
  SetStatusBarValue(self, CurrValue, MaxValue, PredictedPower)

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

function GUB.UnitBarsF.PlayerPower:Update(Event)
  UpdatePowerBar(self, Event, 'player')
end

function GUB.UnitBarsF.TargetPower:Update(Event)
  UpdatePowerBar(self, Event, 'target')
end

function GUB.UnitBarsF.FocusPower:Update(Event)
  UpdatePowerBar(self, Event, 'focus')
end

function GUB.UnitBarsF.PetPower:Update(Event)
  UpdatePowerBar(self, Event, 'pet')
end

function GUB.UnitBarsF.ManaPower:Update(Event)
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
  self.Border:EnableMouse(Enable)
end)

-------------------------------------------------------------------------------
-- FrameSetScript
--
-- Set up script handlers for the unitbars.
-------------------------------------------------------------------------------
HapFunction('FrameSetScript', function(self, Enable)
  local Border = self.Border
  if Enable then

    -- Set mouse scripts for all the unitbars.
    -- Set UnitBar to OnHide when any of the frames are hidden.
    Border:SetScript('OnMouseDown', HapBarStartMoving)
    Border:SetScript('OnMouseUp', HapBarStopMoving)
    Border:SetScript('OnHide', HapBarStopMoving)
    Border:SetScript('OnEnter', function(self)
                                  Main.UnitBarTooltip(self, false)
                                end)
    Border:SetScript('OnLeave', function(self)
                                  Main.UnitBarTooltip(self, true)
                                end)
  else
    Border:SetScript('OnMouseDown', nil)
    Border:SetScript('OnMouseUp', nil)
    Border:SetScript('OnHide', nil)
    Border:SetScript('OnEnter', nil)
    Border:SetScript('OnLeave', nil)
  end
end)

-------------------------------------------------------------------------------
-- SetAttr
--
-- Sets different parts of the health and power bars.
--
-- Usage: SetAttr(Object, Attr)
--        SetAttr('ppower')
--
-- Object       Object being changed:
--               'bg'        for background (Border).
--               'bar'       for forground (StatusBar).
--               'text'      for text (StatusBar.Txt).
--               'text2'     for text2 (StatusBar.Txt2).
--               'ppower'    for predicted power.
--               'frame'     for the frame.
-- Attr         Type of attribute being applied to object:
--               'color'     Color being set to the object.
--               'pcolor'    Predicted color being set to the object.
--               'size'      Size being set to the object.
--               'padding'   Amount of padding set to the object.
--               'texture'   One or more textures set to the object.
--               'font'      Font settings being set to the object.
--               'backdrop'  Backdrop settings being set to the object.
--               'scale'     Scale settings being set to the object.
--               'strata'    Frame strata for the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
--
--       Since health bars and power bars can have multiple colors.  This function
--       no longer sets them.
-------------------------------------------------------------------------------
HapFunction('SetAttr', function(self, Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = UB.General

  -- Check scale and strata for 'frame'
  Main:UnitBarSetAttr(self, Object, Attr)

  -- Set predicted power settings.
  if self.BarType == 'PlayerPower' and PlayerClass == 'HUNTER' and (Object == nil or Object == 'ppower') then
    Main:SetSpellTracker(self, Gen.PredictedPower)
  end

  -- Background (Border).
  if Object == nil or Object == 'bg' then
    local Border = self.Border
    local BgColor = UB.Background.Color

    if Attr == nil or Attr == 'backdrop' then
      Border:SetBackdrop(Main:ConvertBackdrop(UB.Background.BackdropSettings))
      Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
    end
    if Attr == nil or Attr == 'color' then
      Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
    end
  end

  -- Forground (Statusbar).
  if Object == nil or Object == 'bar' then
    local StatusBar = self.StatusBar
    local PredictedBar = self.PredictedBar
    local Border = self.Border

    local Bar = UB.Bar
    local Padding = Bar.Padding
    local BarColor = Bar.Color
    local PredictedColor = Bar.PredictedColor

    if Attr == nil or Attr == 'texture' then
      StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTexture))
      StatusBar:GetStatusBarTexture():SetHorizTile(false)
      StatusBar:GetStatusBarTexture():SetVertTile(false)
      StatusBar:SetOrientation(Bar.FillDirection)
      StatusBar:SetReverseFill(Bar.ReverseFill)
      StatusBar:SetRotatesTexture(Bar.RotateTexture)

      local PredictedBarTexture = Bar.PredictedBarTexture
      if PredictedBarTexture then
        PredictedBar:SetStatusBarTexture(LSM:Fetch('statusbar', PredictedBarTexture))
      else
        PredictedBar:SetStatusBarTexture(LSM:Fetch('statusbar', 'GUB Empty'))
      end
      PredictedBar:GetStatusBarTexture():SetHorizTile(false)
      PredictedBar:GetStatusBarTexture():SetVertTile(false)
      PredictedBar:SetOrientation(Bar.FillDirection)
      PredictedBar:SetReverseFill(Bar.ReverseFill)
      PredictedBar:SetRotatesTexture(Bar.RotateTexture)
    end

    if Attr == nil or Attr == 'color' then
      StatusBar:SetStatusBarColor(BarColor.r, BarColor.g, BarColor.b, BarColor.a)
    end

    if PredictedColor and ( Attr == nil or Attr == 'pcolor' ) then
      PredictedBar:SetStatusBarColor(PredictedColor.r, PredictedColor.g, PredictedColor.b, PredictedColor.a)
    end

    if Attr == nil or Attr == 'padding' then
      StatusBar:ClearAllPoints()
      StatusBar:SetPoint('TOPLEFT', Padding.Left , Padding.Top)
      StatusBar:SetPoint('BOTTOMRIGHT', Padding.Right, Padding.Bottom)

      PredictedBar:ClearAllPoints()
      PredictedBar:SetPoint('TOPLEFT', Padding.Left , Padding.Top)
      PredictedBar:SetPoint('BOTTOMRIGHT', Padding.Right, Padding.Bottom)

      -- Update the statusbars to reflect change.
      local Value = StatusBar:GetValue()
      local Value2 = PredictedBar:GetValue()

      StatusBar:SetValue(Value - 1)
      StatusBar:SetValue(Value)
      PredictedBar:SetValue(Value2 - 1)
      PredictedBar:SetValue(Value2)
    end
    if Attr == nil or Attr == 'size' then
      self:SetSize(Bar.HapWidth, Bar.HapHeight)
    end

  end

  -- Text (StatusBar.Txt).
  if Object == nil or Object == 'text' then
    local Txt = self.Txt

    local TextColor = UB.Text.Color

    if Attr == nil or Attr == 'font' then
      Main:SetFontString(Txt, UB.Text.FontSettings)
    end
    if Attr == nil or Attr == 'color' then
      Txt:SetTextColor(TextColor.r, TextColor.g, TextColor.b, TextColor.a)
    end
  end

  -- Text2 (StatusBar.Txt2).
  if Object == nil or Object == 'text2' then
    local Txt = self.Txt2

    local TextColor = UB.Text2.Color

    if Attr == nil or Attr == 'font' then
      Main:SetFontString(Txt, UB.Text2.FontSettings)
    end
    if Attr == nil or Attr == 'color' then
      Txt:SetTextColor(TextColor.r, TextColor.g, TextColor.b, TextColor.a)
    end
  end
end)

-------------------------------------------------------------------------------
-- SetLayout
--
-- Sets a health and power bar with a new layout.
-------------------------------------------------------------------------------
HapFunction('SetLayout', function(self)

  -- Get the unitbar data.
  local UB = self.UnitBar

  local StatusBar = self.StatusBar
  StatusBar:SetMinMaxValues(0, 100)
  StatusBar:SetValue(0)

  local PredictedBar = self.PredictedBar
  PredictedBar:SetMinMaxValues(0, 100)
  PredictedBar:SetValue(0)

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Save a reference of unitbar data.
  StatusBar.UnitBar = self.UnitBar
end)

-------------------------------------------------------------------------------
-- CreateBar
--
-- Usage: CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the health and power bar.
-- UB           Unitbar data.
-- Anchor       Unitbar's anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.HapBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
  local Border = CreateFrame('Frame', nil, ScaleFrame)

  local StatusBar = CreateFrame('StatusBar', nil, Border)
  local PredictedBar = CreateFrame('StatusBar', nil, Border)

  local Txt = StatusBar:CreateFontString(nil, 'OVERLAY')
  local Txt2 = StatusBar:CreateFontString(nil, 'OVERLAY')

  -- Set the border to always be the same size as the anchor.
  Border:SetAllPoints(Anchor)

  -- The predictedbar needs to be below the health/power bar.
  StatusBar:SetFrameLevel(StatusBar:GetFrameLevel() + 1)

  -- Save the text for tooltips.
  Main:SetTooltip(Border, UB.Name, MouseOverDesc)

  -- Save a reference to the anchor for moving.
  Border.Anchor = Anchor

  -- Save a reference of UnitBarF to the border for onsizechange.
  Border.UnitBarF = UnitBarF

  -- Save the frames.
  UnitBarF.Border = Border
  UnitBarF.StatusBar = StatusBar
  UnitBarF.PredictedBar = PredictedBar
  UnitBarF.Txt = Txt
  UnitBarF.Txt2 = Txt2
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

function GUB.UnitBarsF.PlayerHealth:Enable(Enable)
  RegEventHealth(Enable, self, 'player')
end

function GUB.UnitBarsF.TargetHealth:Enable(Enable)
  RegEventHealth(Enable, self, 'target')
end

function GUB.UnitBarsF.FocusHealth:Enable(Enable)
  RegEventHealth(Enable, self, 'focus')
end

function GUB.UnitBarsF.PetHealth:Enable(Enable)
  RegEventHealth(Enable, self, 'pet')
end

function GUB.UnitBarsF.PlayerPower:Enable(Enable)
  RegEventPower(Enable, self, 'player')
end

function GUB.UnitBarsF.TargetPower:Enable(Enable)
  RegEventPower(Enable, self, 'target')
end

function GUB.UnitBarsF.FocusPower:Enable(Enable)
  RegEventPower(Enable, self, 'focus')
end

function GUB.UnitBarsF.PetPower:Enable(Enable)
  RegEventPower(Enable, self, 'pet')
end

function GUB.UnitBarsF.ManaPower:Enable(Enable)
  RegEventPower(Enable, self, 'player')
end
