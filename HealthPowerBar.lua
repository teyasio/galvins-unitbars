--
-- HealthPower.lua
--
-- Displays health and power bars.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.HapBar = {}

-- shared from Main.lua
local LSM = GUB.UnitBars.LSM
local CheckPowerType = GUB.UnitBars.CheckPowerType
local CheckEvent = GUB.UnitBars.CheckEvent
local PowerTypeToNumber = GUB.UnitBars.PowerTypeToNumber
local MouseOverDesc = GUB.UnitBars.MouseOverDesc

-- localize some globals.
local _
local pcall, abs, mod, floor, strconcat, tostring, pairs, ipairs, type, math, table, select =
      pcall, abs, mod, floor, strconcat, tostring, pairs, ipairs, type, math, table, select
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.UnitBar           Reference to the unitbar data for the health and power bar.
-- UnitBarF.Border            Border frame for the health and power bar.
-- UnitBarF.StatusBar         The Statusbar for the health and power bar.
-- UnitBarF.PredictedBorder   This is the visible border you see around the statusbar.  Since
--                            the predicted bar has to sit behind the statusbar. The statusbar can't
--                            have a border otherwise the predictedbar would not be visible. So
--                            predicted border becomes the visible border.
-- UnitBarF.PredictedBar      This is another statusbar that sits behind StatusBar.  This is used for
--                            predicted health
--
-- Border.Anchor              Reference to the anchor for moving.
-- Border.TooltipName         Tooltip text to display for mouse over when bars are unlocked.
-- Border.TooltipDesc         Description under the name for mouse over.
-- Border.UnitBarF            Reference to unitbarF for for onsizechange.
--
-- StatusBar.UnitBar          Reference to unitbar data for GetStatusBarTextValue()
-------------------------------------------------------------------------------

-- Powertype constants
local PowerMana = PowerTypeToNumber['MANA']
local PowerEnergy = PowerTypeToNumber['ENERGY']

-- Constants used in NumberToDigitGroups
local Thousands = ('%.1f'):format(1/5):match('([^0-9])') == '.' and ',' or '.'
local BillionFormat = '%d' .. Thousands .. '%03d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local MillionFormat = '%d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local ThousandFormat = '%d' .. Thousands..'%03d'


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
    return (Sign .. BillionFormat):format(Value / 1000000000, (Value / 1000000) % 1000, (Value / 1000) % 1000, Value % 1000)
  elseif Value >= 1000000 then
    return (Sign .. MillionFormat):format(Value / 1000000, (Value / 1000) % 1000, Value % 1000)
  elseif Value >= 1000 then
    return (Sign .. ThousandFormat):format(Value / 1000, Value % 1000)
  else
    return tostring(Value)
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
    return tostring(Value)
  elseif Value < 1000000 then
    return ('%.fk'):format(Value / 1000)
  else
    return ('%.1fm'):format(Value / 1000000)
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
    return math.ceil(Value / MaxValue * 100)
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
local function SetStatusBarTextValues(StatusBar, TextFrame, CurrValue, MaxValue, PredictedValue)
  local TextTable = 'Text'

  if TextFrame == 'Txt2' then
    TextTable = 'Text2'
  end

  local TextType = StatusBar.UnitBar[TextTable].TextType
  local MaxValues = TextType.MaxValues
  local ValueName = TextType.ValueName
  local ValueType = TextType.ValueType
  local Layout = TextType.Layout

  -- Use recursion to build a parameter list to pass back to setformat.
  local function GetTextValues(Position, ...)
    if Position > 0 then
      local Type = ValueType[Position]
      if Type ~= 'none' then
        return GetTextValues(Position - 1, GetTextValue(ValueName[Position], Type, CurrValue, MaxValue, PredictedValue), ...)
      else
        return GetTextValues(Position - 1, ...)
      end
    else
      return ...
    end
  end

  StatusBar[TextFrame]:SetFormattedText(Layout, GetTextValues(MaxValues))
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
-- HapBarOnSizeChanged
--
-- Gets called when ever the border of the health and power bar changes.
-- This sets the size data for all health and power bars to the UnitBarF.
-------------------------------------------------------------------------------
local function HapBarOnSizeChanged(self, Width, Height)
  local UBF = self.UnitBarF
  UBF.Width = Width
  UBF.Height = Height
end

-------------------------------------------------------------------------------
-- HapBarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar parent frame will be moved.
-- Otherwise just the runes will be moved.
-------------------------------------------------------------------------------
local function HapBarStartMoving(self, Button)

  -- Call the base moving function for group or anchor movement.
  if GUB.UnitBars.UnitBarStartMoving(self.Anchor, Button) then
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
    GUB.UnitBars.UnitBarStopMoving(self.Anchor, Button)
  end
end

--*****************************************************************************
--
-- Health and Power bar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateHealthBar (Update) [UnitBar assigned function]
--
-- Updates the health of the current player or target
--
-- Usage: UpdateHealthBar(UnitBarF, Event, Unit)
--
-- UnitBarF   The unitbar that contains the Health and Power bar frame.
-- Event      If it's not a health event then health bar doesn't
--            get updated. Set to nil to bypass this check
-- Unit       player or target
-------------------------------------------------------------------------------
function GUB.HapBar:UpdateHealthBar(Event, Unit)

  -- Do nothing if this bar is not enabled or not a health event.
  if not self.Enabled or Event ~= nil and CheckEvent[Event] ~= 'health' then
    return
  end
  local CurrValue = UnitHealth(Unit)
  local MaxValue = UnitHealthMax(Unit)
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
  local PredictedHealing = UnitGetIncomingHeals(Unit) or 0

  if PredictedColor and PredictedHealing > 0 then
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
  self.IsActive = CurrValue < MaxValue

  -- Do a status check for active status.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- UpdatePowerBar (Update) [UnitBar assigned function]
--
-- Updates the power of the current player or target.
--
-- Usage: UpdatePowerBar(Event, Unit, UpdatePowerType, PowerType)
--
-- Event                If nil no event check will be done.
-- UpdatePowerType      If true then the current unit power type must equal
--                      this value.
--                      If false then the PowerType gets updated instead.
-- PowerType            String format. This is based on UpdatePowerType.
--                      If nil then current units powertype is used only
--                      if UpdatePowerType is equal to false.
-------------------------------------------------------------------------------
function GUB.HapBar:UpdatePowerBar(Event, Unit, UpdatePowerType, PowerType)

  -- Return if the unitbar is disabled, or event is not a power event.
  -- or powertype is not for a powerbar
  if not self.Enabled or Event ~= nil and CheckEvent[Event] ~= 'power' or
     PowerType ~= nil and CheckPowerType[PowerType] ~= 'power' then
    return
  end

  -- Convert powertype into a number.
  PowerType = PowerTypeToNumber[PowerType]

  local CurrPowerType = UnitPowerType(Unit)

  -- If PowerType is nil then use the current units powertype.
  if PowerType == nil then
    PowerType = CurrPowerType
  end

  -- Return if UpdatePowerType is true and PowerType is not equal to CurrPowerType
  if UpdatePowerType and PowerType ~= CurrPowerType then
    return
  end

  local CurrValue = UnitPower(Unit, PowerType)
  local MaxValue = UnitPowerMax(Unit, PowerType)
  local UB = self.UnitBar

  local Color = UB.Bar.Color[PowerType]

  -- Set the color and display the value.
  local StatusBar = self.StatusBar
  StatusBar:SetStatusBarColor(Color.r, Color.g, Color.b, Color.a)
  SetStatusBarValue(StatusBar, CurrValue, MaxValue)

  -- Set the IsActive flag.
  local IsActive = false
  if PowerType == PowerMana or PowerType == PowerEnergy then
    if CurrValue < MaxValue then
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

--*****************************************************************************
--
-- Health and Power bar creation/setting
--
--*****************************************************************************

------------------------------------------------------------------------------
-- EnableMouseClicksHap (EnableMouseClicks) [UnitBar assigned function]
--
-- This will enable or disbale mouse clicks for the rune icons.
-------------------------------------------------------------------------------
function GUB.HapBar:EnableMouseClicksHap(Enable)
  self.Border:EnableMouse(Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScriptHap (FrameSetScript) [UnitBar assigned function]
--
-- Set up script handlers for the unitbars.
-------------------------------------------------------------------------------
function GUB.HapBar:FrameSetScriptHap(Enable)
  local Border = self.Border
  if Enable then

    -- Set mouse scripts for all the unitbars.
    -- Set UnitBar to OnHide when any of the frames are hidden.
    Border:SetScript('OnMouseDown', HapBarStartMoving)
    Border:SetScript('OnMouseUp', HapBarStopMoving)
    Border:SetScript('OnHide', HapBarStopMoving)
    Border:SetScript('OnEnter', function(self)
                                  GUB.UnitBars.UnitBarTooltip(self, false)
                                end)
    Border:SetScript('OnLeave', function(self)
                                  GUB.UnitBars.UnitBarTooltip(self, true)
                                end)
    Border:SetScript('OnSizeChanged', HapBarOnSizeChanged)
  else
    Border:SetScript('OnMouseDown', nil)
    Border:SetScript('OnMouseUp', nil)
    Border:SetScript('OnHide', nil)
    Border:SetScript('OnEnter', nil)
    Border:SetScript('OnLeave', nil)
    Border:SetScript('OnSizeChanged', nil)
  end
end

-------------------------------------------------------------------------------
-- EnableScreenClampHap (EnableScreenClamp) [UnitBar assigned function]
--
-- Enables or disble screen clamp for runes
-------------------------------------------------------------------------------
function GUB.HapBar:EnableScreenClampHap(Enable)

  -- Prevent the border from being moved off the screen.
  self.Border:SetClampedToScreen(Enable)
end

-------------------------------------------------------------------------------
-- SetAttrHap (SetAttr) [UnitBar assigned function]
--
-- Sets different parts of the health and power bars.
--
-- Usage: SetAttrHap(Object, Attr)
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
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
--
--       Since health bars and power bars can have multiple colors.  This function
--       no longer sets them.
-------------------------------------------------------------------------------
function GUB.HapBar:SetAttrHap(Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar

  -- Frame.
  if Object == nil or Object == 'frame' then
    if Attr == nil or Attr == 'scale' then
      self.ScaleFrame:SetScale(UB.Other.Scale)
    end
  end

  -- Background (Border).
  if Object == nil or Object == 'bg' then
    local PredictedBorder = self.PredictedBorder

    local BgColor = UB.Background.Color

    if Attr == nil or Attr == 'backdrop' then
      PredictedBorder:SetBackdrop(GUB.UnitBars:ConvertBackdrop(UB.Background.BackdropSettings))
      PredictedBorder:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
    end
    if Attr == nil or Attr == 'color' then
      PredictedBorder:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
    end
  end

  -- Forground (Statusbar).
  if Object == nil or Object == 'bar' then
    local StatusBar = self.StatusBar
    local PredictedBar = self.PredictedBar
    local Border = self.Border
    local PredictedBorder = self.PredictedBorder

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
      Border:SetWidth(Bar.HapWidth)
      Border:SetHeight(Bar.HapHeight)

      PredictedBorder:SetWidth(Bar.HapWidth)
      PredictedBorder:SetHeight(Bar.HapHeight)
    end
  end

  -- Text (StatusBar.Txt).
  if Object == nil or Object == 'text' then
    local Txt = self.StatusBar.Txt

    local TextColor = UB.Text.Color

    if Attr == nil or Attr == 'font' then
      GUB.UnitBars:SetFontString(Txt, UB.Text.FontSettings)
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
      GUB.UnitBars:SetFontString(Txt, UB.Text2.FontSettings)
    end
    if Attr == nil or Attr == 'color' then
      Txt:SetTextColor(TextColor.r, TextColor.g, TextColor.b, TextColor.a)
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayoutHap (SetLayout) [UnitBar assigned function]
--
-- Sets a health and power bar with a new layout.
--
-- Usage: SetLayoutHap()
-------------------------------------------------------------------------------
function GUB.HapBar:SetLayoutHap()

  -- Get the unitbar data.
  local UB = self.UnitBar

  local Border = self.Border
  Border:ClearAllPoints()
  Border:SetPoint('TOPLEFT', 0, 0)

  local StatusBar = self.StatusBar
  StatusBar:SetMinMaxValues(0, 100)
  StatusBar:SetValue(0)

  -- Set the predicted bar values to the same values as the StatusBar.
  local PredictedBorder = self.PredictedBorder
  PredictedBorder:ClearAllPoints()
  PredictedBorder:SetPoint('TOPLEFT', 0, 0)

  local PredictedBar = self.PredictedBar
  PredictedBar:SetMinMaxValues(0, 100)
  PredictedBar:SetValue(0)

    -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Save size data to self (UnitBarF).
  self.Width = UB.Bar.HapWidth
  self.Height = UB.Bar.HapHeight

  -- Save a reference of unitbar data.
  StatusBar.UnitBar = self.UnitBar
end

-------------------------------------------------------------------------------
-- CreateHapBar
--
-- Usage: CreateHapBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the health and power bar.
-- UB           Unitbar data.
-- Anchor       Unitbar's anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.HapBar:CreateHapBar(UnitBarF, UB, Anchor, ScaleFrame)
  local Border = CreateFrame('Frame', nil, ScaleFrame)
  local StatusBar = CreateFrame('StatusBar', nil, Border)
  StatusBar.Txt = StatusBar:CreateFontString(nil, 'OVERLAY')
  StatusBar.Txt2 = StatusBar:CreateFontString(nil, 'OVERLAY')

  local PredictedBorder = CreateFrame('Frame', nil, ScaleFrame)
  local PredictedBar = CreateFrame('StatusBar', nil, PredictedBorder)

  -- The predicted Bar needs to be above the Healthbar.
  Border:SetFrameLevel(1)
  PredictedBorder:SetFrameLevel(0)

  -- Make the border frame top when clicked.
  Border:SetToplevel(true)

  -- Save the text for tooltips.
  Border.TooltipName = UB.Name
  Border.TooltipDesc = MouseOverDesc

  -- Save a reference to the anchor for moving.
  Border.Anchor = Anchor

  -- Save a reference of UnitBarF to the border for onsizechange.
  Border.UnitBarF = UnitBarF

  -- Save the frames.
  UnitBarF.Border = Border
  UnitBarF.StatusBar = StatusBar
  UnitBarF.PredictedBorder = PredictedBorder
  UnitBarF.PredictedBar = PredictedBar
end
