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
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, PlaySound =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, PlaySound
local GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable


local SquareBorder = {
  bgFile   = '',
  edgeFile = [[Interface\Addons\GalvinUnitBars\Textures\GUB_SquareBorder.tga]],
  tile = true,
  tileSize = 16,
  edgeSize = 12,
  insets = {
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

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
-- LastCurrValue
-- LastMaxValue
-- LastPowerType              These three values keep track of any changes in the health and power bars.
--
-- LastPredictedValue         Hunters only.  Keeps track of predicted power change.
--
-- PlayerClass                The players class.
-------------------------------------------------------------------------------
local PlayerClass = nil

-- Powertype constants
local PowerMana = PowerTypeToNumber['MANA']
local PowerEnergy = PowerTypeToNumber['ENERGY']
local PowerFocus = PowerTypeToNumber['FOCUS']

local LastCurrValue = {}
local LastMaxValue = {}
local LastPowerType = {}
local LastPredictedValue = {}

-- Predicted spell ID constants.
local SpellSteadyShot = 56641
local SpellCobraShot  = 77767

local PredictedSpellValue = {
  [0]               = 0,
  [SpellSteadyShot] = 14,
  [SpellCobraShot]  = 14,
}

-- Constants used in NumberToDigitGroups
local Thousands = strmatch(format('%.1f', 1/5), '([^0-9])') == '.' and ',' or '.'
local BillionFormat = '%s%d' .. Thousands .. '%03d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local MillionFormat = '%s%d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local ThousandFormat = '%s%d' .. Thousands..'%03d'

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
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
HapFunction('StatusCheck', Main.StatusCheck)

--*****************************************************************************
--
-- health and Power - predicted power and initialization
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Set Steady shot and cobra shot for predicted power.
-- Set a callback that will update the power bar when ever either of these spells are casting.
-------------------------------------------------------------------------------
Main:SetPredictedSpells(SpellSteadyShot, 'casting', function(SpellID, Message) UnitBarsF.PlayerPower:Update('change') end)
Main:SetPredictedSpells(SpellCobraShot,  'casting', function(SpellID, Message) UnitBarsF.PlayerPower:Update('change') end)

--*****************************************************************************
--
-- Health and Power bar utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- NumberToDigitGroups
--
-- Takes a number and returns it in groups of three. 999,999,999
--
-- Usage: String = NumberToDigitGroups(Value)
--
-- Value       Number to convert to a digit group.
--
-- String      String containing Value in digit groups.
-------------------------------------------------------------------------------
local function NumberToDigitGroups(Value)
  local Sign = ''
  if Value < 0 then
    Sign = '-'
    Value = abs(Value)
  end

  if Value >= 1000000000 then
    return format(BillionFormat, Sign, Value / 1000000000, (Value / 1000000) % 1000, (Value / 1000) % 1000, Value % 1000)
  elseif Value >= 1000000 then
    return format(MillionFormat, Sign, Value / 1000000, (Value / 1000) % 1000, Value % 1000)
  elseif Value >= 1000 then
    return format(ThousandFormat, Sign, Value / 1000, Value % 1000)
  else
    return format('%s', Value)
  end
end

-------------------------------------------------------------------------------
-- GetShortTextValue
--
-- Takes a number and returns it in a shorter format for formatted text.
--
-- Usage: Value2 = GetShortTextValue(Value)
--
-- Value       Number to convert for formatted text.
--
-- Value2      Formatted text made from Value.
-------------------------------------------------------------------------------
local function GetShortTextValue(Value)
  if Value < 1000 then
    return format('%s', Value)
  elseif Value < 1000000 then
    return format('%.fk', Value / 1000)
  else
    return format('%.1fm', Value / 1000000)
  end
end

-------------------------------------------------------------------------------
-- GetTextValue
--
-- Returns either CurrValue or MaxValue based on the ValueName and ValueType
--
-- Usage: Value = GetTextValue(ValueName, ValueType, CurrValue, MaxValue, PredictedValue)
--
-- ValueName        Must be 'current', 'maximum', or 'predicted'.
-- ValueType        The type of value, see texttype in main.lua for a list.
-- CurrValue        Values to be used.
-- MaxValue         Values to be used.
-- PredictedValue   Predicted health or power value.  If nil won't be used.
--
-- Value            The value returned based on the ValueName and ValueType.
--                  Can be a string or number.
-------------------------------------------------------------------------------
local function GetTextValue(ValueName, ValueType, CurrValue, MaxValue, PredictedValue)
  local Value = nil

  -- Get the value based on ValueName
  if ValueName == 'current' then
    Value = CurrValue
  elseif ValueName == 'maximum' then
    Value = MaxValue
  elseif ValueName == 'predicted' then
    Value = PredictedValue or 0
  end

  if ValueType == 'whole' then
    return Value
  elseif ValueType == 'whole_dgroups' then
    return NumberToDigitGroups(Value)
  elseif ValueType == 'percent' and Value > 0 then
    if MaxValue == 0 then
      return 0
    else
      return ceil(Value / MaxValue * 100)
    end
  elseif ValueType == 'thousands' then
    return Value / 1000
  elseif ValueType == 'millions' then
    return Value / 1000000
  elseif ValueType == 'short' then
    return GetShortTextValue(Value)
  else
    return 0
  end
end

-------------------------------------------------------------------------------
-- SetStatusBarTextValues
--
-- Sets one or more values on a bar based on the text type settings
--
-- Usage: SetStatusBarTextValues(StatusBar, TextFrame, CurrValue, MaxValue, PredictedValue)
--
-- StatusBar        The bar to set the values to.
-- TextFrame        Must be 'Txt' or 'Txt2' this is the text frame.
-- CurrValue        Current value.  Used for percentage.
-- MaxValue         Maximum value.  Used for percentage.
-- PredictedValue   Predicted health or power value.
-------------------------------------------------------------------------------

-- Use recursion to build a parameter list to pass back to setformat.
local function GetTextValues(ValueName, ValueType, CurrValue, MaxValue, PredictedValue, Position, ...)
  if Position > 0 then
    local Type = ValueType[Position]
    if Type ~= 'none' then
      return GetTextValues(ValueName, ValueType, CurrValue, MaxValue, PredictedValue, Position - 1,
                           GetTextValue(ValueName[Position], Type, CurrValue, MaxValue, PredictedValue), ...)
    else
      return GetTextValues(ValueName, ValueType, CurrValue, MaxValue, PredictedValue, Position - 1, ...)
    end
  else
    return ...
  end
end

local function SetStatusBarTextValues(StatusBar, TextFrame, CurrValue, MaxValue, PredictedValue)
  local TextTable = 'Text'

  if TextFrame == 'Txt2' then
    TextTable = 'Text2'
  end

  local TextType = StatusBar.UnitBar[TextTable].TextType
  local MaxValues = TextType.MaxValues

  if MaxValues > 0 then
    StatusBar[TextFrame]:SetFormattedText(TextType.Layout,
      GetTextValues(TextType.ValueName, TextType.ValueType, CurrValue, MaxValue, PredictedValue, MaxValues))
  else
    StatusBar[TextFrame]:SetText('')
  end
end

-------------------------------------------------------------------------------
-- SetStatusBarValue
--
-- Sets the minimum, maximum, and text value to the StatusBar.
--
-- Usage: SetStatusBarValue(StatusBar, CurrValue, MaxValue, PredictedValue)
--
-- StatusBar       Frame that text is being created for.
-- CurrValue       Current value to set.
-- MaxValue        Maximum value to set.
-- PredictedValue  Predicted health or power.
--
-- Note: If there's an error in setting the text value then an error message will
--       be set instead.
-------------------------------------------------------------------------------
local function SetStatusBarValue(StatusBar, CurrValue, MaxValue, PredictedValue)
  StatusBar:SetMinMaxValues(0, MaxValue)
  StatusBar:SetValue(CurrValue)


  local returnOK, msg = pcall(SetStatusBarTextValues, StatusBar, 'Txt', CurrValue, MaxValue, PredictedValue)
  if not returnOK then
    StatusBar.Txt:SetText('Layout Err Text')
  end


  returnOK, msg = pcall(SetStatusBarTextValues, StatusBar, 'Txt2', CurrValue, MaxValue, PredictedValue)
  if not returnOK then
    StatusBar.Txt2:SetText('Layout Err Text2')
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
--
-- Event      'change' then the bar will only get updated if there is a change.
-- Unit       player, target, pet, etc
-------------------------------------------------------------------------------
local function UpdateHealthBar(self, Event, Unit)
  local CurrValue = UnitHealth(Unit)
  local MaxValue = UnitHealthMax(Unit)

  local BarType = self.BarType
  local Gen = self.UnitBar.General
  local PredictedHealing = Gen and Gen.PredictedHealth and UnitGetIncomingHeals(Unit) or 0

  -- Return if there is no change.
  if Event == 'change' and
     CurrValue == LastCurrValue[BarType] and MaxValue == LastMaxValue[BarType] and
     PredictedHealing == LastPredictedValue[BarType] then
    return
  end

  LastCurrValue[BarType] = CurrValue
  LastMaxValue[BarType] = MaxValue
  LastPredictedValue[BarType] = PredictedHealing

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
  local StatusBar = self.StatusBar
  StatusBar:SetStatusBarColor(Color.r, Color.g, Color.b, Color.a)
  SetStatusBarValue(StatusBar, CurrValue, MaxValue, PredictedHealing)

  -- Set the IsActive flag.
  self.IsActive = CurrValue < MaxValue or PredictedHealing > 0

  -- Do a status check for active status.
  self:StatusCheck()
end

function GUB.UnitBarsF.PlayerHealth:Update(Event)
  if self.Enabled then
    UpdateHealthBar(self, Event, 'player')
  end
end

function GUB.UnitBarsF.TargetHealth:Update(Event)
  if self.Enabled then
    UpdateHealthBar(self, Event, 'target')
  end
end

function GUB.UnitBarsF.FocusHealth:Update(Event)
  if self.Enabled then
    UpdateHealthBar(self, Event, 'focus')
  end
end

function GUB.UnitBarsF.PetHealth:Update(Event)
  if self.Enabled then
    UpdateHealthBar(self, Event, 'pet')
  end
end

-------------------------------------------------------------------------------
-- UpdatePowerBar
--
-- Updates the power of the unit.
--
-- Usage: UpdatePowerBar(Event, Unit, PowerType, PlayerClass)
--
-- Event         'change' then the bar will only get updated if there is a change.
-- Unit          Unit name 'player' ,'target', etc
-- PowerType     If not nil then this value will be used as the powertype.
--               if nil then the Unit's powertype will be used instead.
-- PlayerClass   Name of the class. If nil not used.
-------------------------------------------------------------------------------
local function UpdatePowerBar(self, Event, Unit, PowerType, PlayerClass)
  PowerType = PowerType or UnitPowerType(Unit)

  local BarType = self.BarType
  local CurrValue = UnitPower(Unit, PowerType)
  local MaxValue = UnitPowerMax(Unit, PowerType)

  local Gen = self.UnitBar.General

  -- Get predicted power for hunters only.
  local PredictedPower = Gen and Gen.PredictedPower and Unit == 'player' and PlayerClass == 'HUNTER' and
                         PredictedSpellValue[Main:GetPredictedSpell()] or 0

  -- Return if there is no change.
  if Event == 'change' and
     CurrValue == LastCurrValue[BarType] and MaxValue == LastMaxValue[BarType] and
     PowerType == LastPowerType[BarType] and PredictedPower == 0 and LastPredictedValue[BarType] == 0 then
    return
  end

  -- Check for two piece bonus hunters only.
  if PlayerClass == 'HUNTER' and PredictedPower > 0 and Main:GetSetBonus(13) >= 2 then
    PredictedPower = PredictedPower * 2
  end

  LastCurrValue[BarType] = CurrValue
  LastMaxValue[BarType] = MaxValue
  LastPowerType[BarType] = PowerType
  LastPredictedValue[BarType] = PredictedPower

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
  local StatusBar = self.StatusBar
  StatusBar:SetStatusBarColor(Color.r, Color.g, Color.b, Color.a)
  SetStatusBarValue(StatusBar, CurrValue, MaxValue, PredictedPower)

  -- Set the IsActive flag.
  local IsActive = false
  if PowerType == PowerMana or PowerType == PowerEnergy or PowerType == PowerFocus then
    if CurrValue < MaxValue or PredictedPower > 0 then
      IsActive = true
    end
  else
    if CurrValue > 0 then
      IsActive = true
    end
  end
  self.IsActive = IsActive

  -- Do a status check for active status.
  self:StatusCheck()
end

function GUB.UnitBarsF.PlayerPower:Update(Event)
  if self.Enabled then
    if PlayerClass == nil then
      _, PlayerClass = UnitClass('player')
    end
    UpdatePowerBar(self, Event, 'player', nil, PlayerClass)
  end
end

function GUB.UnitBarsF.TargetPower:Update(Event)
  if self.Enabled then
    UpdatePowerBar(self, Event, 'target')
  end
end

function GUB.UnitBarsF.FocusPower:Update(Event)
  if self.Enabled then
    UpdatePowerBar(self, Event, 'focus')
  end
end

function GUB.UnitBarsF.PetPower:Update(Event)
  if self.Enabled then
    UpdatePowerBar(self, Event, 'pet')
  end
end

function GUB.UnitBarsF.MainPower:Update(Event)
  if self.Enabled then
    UpdatePowerBar(self, Event, 'player', PowerMana)
  end
end

-------------------------------------------------------------------------------
-- CancelAnimation    UnitBarsF function
--
-- Usage: CancelAnimation()
--
-- Cancels all animation playing in the combo bar.
-------------------------------------------------------------------------------
HapFunction('CancelAnimation', function()
  -- do nothing.
end)

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
--
-- Object       Object being changed:
--               'bg' for background (Border).
--               'bar' for forground (StatusBar).
--               'text' for text (StatusBar.Txt).
--               'text2' for text2 (StatusBar.Txt2).
--               'frame' for the frame.
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

  -- Check scale and strata for 'frame'
  Main:UnitBarSetAttr(self, Object, Attr)

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
      StatusBar:SetRotatesTexture(Bar.RotateTexture)

      local PredictedBarTexture = Bar.PredictedBarTexture
      if PredictedBarTexture then
        PredictedBar:SetStatusBarTexture(LSM:Fetch('statusbar', PredictedBarTexture))
      else
        PredictedBar:SetStatusBarTexture(LSM:Fetch('statusbar', 'Empty'))
      end
      PredictedBar:GetStatusBarTexture():SetHorizTile(false)
      PredictedBar:GetStatusBarTexture():SetVertTile(false)
      PredictedBar:SetOrientation(Bar.FillDirection)
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
    end
    if Attr == nil or Attr == 'size' then
      self:SetSize(Bar.HapWidth, Bar.HapHeight)
    end

  end

  -- Text (StatusBar.Txt).
  if Object == nil or Object == 'text' then
    local Txt = self.StatusBar.Txt

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
    local Txt = self.StatusBar.Txt2

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

  StatusBar.Txt = StatusBar:CreateFontString(nil, 'OVERLAY')
  StatusBar.Txt2 = StatusBar:CreateFontString(nil, 'OVERLAY')

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
end
