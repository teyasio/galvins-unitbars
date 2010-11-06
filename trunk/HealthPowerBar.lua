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
local abs, floor, pairs, ipairs, type, math, table, select =
      abs, floor, pairs, ipairs, type, math, table, select
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.UnitBar         Reference to the unitbar data for the health and power bar.
-- UnitBarF.Border          Border frame for the health and power bar.
-- UnitBarF.StatusBar       The Statusbar for the health and power bar.
--
-- Border.Anchor            Reference to the anchor for moving.
-- Border.TooltipName       Tooltip text to display for mouse over when bars are unlocked.
-- Border.TooltipDesc       Description under the name for mouse over.
-- Border.UnitBarF          Reference to unitbarF for for onsizechange.
--
-- StatusBar.UnitBar        Reference to unitbar data for GetStatusBarTextValue()
-------------------------------------------------------------------------------

-- Powertype constants
local PowerMana = PowerTypeToNumber['MANA']
local PowerEnergy = PowerTypeToNumber['ENERGY']

--*****************************************************************************
--
-- Health and Power bar utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- GetStatusBarTextValue
--
-- Returns one or more args to be used in SetFormattedText.
--
-- Usage: FormatString, ... = GetStatusBarTextValue(StatusBar, CurrValue, MaxValue)
--
-- StatusBar      StatusBar frame we're returning values for.
-- CurrValue
-- MaxValue       These values are used to calculate the bar percentage, whole number.
-- FormatString   Fromatted string to be used in SetFromattedText.
-- ...            One or more values.
--
-- Note: If the TextType is not found or MaxValue is equal to zero then '' gets returned.
-------------------------------------------------------------------------------
local function GetStatusBarTextValue(StatusBar, CurrValue, MaxValue)
  local TextType = StatusBar.UnitBar.General.TextType

  if MaxValue == 0 then
    return ''
  elseif TextType == 'whole' then
    return '%d', CurrValue
  elseif TextType == 'percent' then
    return '%d%%', math.ceil(CurrValue / MaxValue * 100)
  elseif TextType == 'max' then
    return '%d / %d', CurrValue, MaxValue
  elseif TextType == 'maxpercent' then
    return '%d / %d %d%%', CurrValue, MaxValue, math.ceil(CurrValue / MaxValue * 100)
  elseif TextType == 'wholepercent' then
    return '%d %d%%', CurrValue, math.ceil(CurrValue / MaxValue * 100)
  else
    return ''
  end
end

-------------------------------------------------------------------------------
-- SetStatusBarValue
--
-- Sets the minimum, maximum, and text value to the StatusBar.
--
-- Usage: SetStatusBarValue(StatusBar, UB, CurrValue, MaxValue)
--
-- StatusBar    StatusBar frame.
-- CurrValue    Current value to set.
-------------------------------------------------------------------------------
local function SetStatusBarValue(StatusBar, CurrValue, MaxValue)
  StatusBar:SetMinMaxValues(0, MaxValue)
  StatusBar:SetValue(CurrValue)
  StatusBar.Txt:SetFormattedText(GetStatusBarTextValue(StatusBar, CurrValue, MaxValue))
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

  -- Get the class color if classcolor flag is true.
  local Color = Bar.Color
  if Bar.ClassColor then
    local Class = select(2, UnitClass(Unit))
    if Class ~= nil then
      Color = Color[Class]
    end
  end

  -- Set the color and display the value.
  local StatusBar = self.StatusBar
  StatusBar:SetStatusBarColor(Color.r, Color.g, Color.b, Color.a)
  SetStatusBarValue(StatusBar, CurrValue, MaxValue)

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
--               'frame' for the frame.
-- Attr         Type of attribute being applied to object:
--               'color'     Color being set to the object.
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
    local Border = self.Border

    local BgColor = UB.Background.Color

    if Attr == nil or Attr == 'backdrop' then
      Border:SetBackdrop(GUB.UnitBars:ConvertBackdrop(UB.Background.BackdropSettings))
      Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
    end
    if Attr == nil or Attr == 'color' then
      Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
    end
  end

  -- Forground (Statusbar).
  if Object == nil or Object == 'bar' then
    local StatusBar = self.StatusBar
    local Border = self.Border

    local Bar = UB.Bar
    local Padding = Bar.Padding
    local BarColor = Bar.Color

    if Attr == nil or Attr == 'texture' then
      StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTexture))
      StatusBar:GetStatusBarTexture():SetHorizTile(false)
      StatusBar:GetStatusBarTexture():SetVertTile(false)
      StatusBar:SetOrientation(Bar.FillDirection)
      StatusBar:SetRotatesTexture(Bar.RotateTexture)
    end

    -- Should only set color on bars that are not a target or focus health bar.
    -- Otherwise Update() should be used instead.
    if Attr == nil or Attr == 'color' then
      StatusBar:SetStatusBarColor(BarColor.r, BarColor.g, BarColor.b, BarColor.a)
    end

    if Attr == nil or Attr == 'padding' then
      StatusBar:ClearAllPoints()
      StatusBar:SetPoint('TOPLEFT', Padding.Left , Padding.Top)
      StatusBar:SetPoint('BOTTOMRIGHT', Padding.Right, Padding.Bottom)
    end
    if Attr == nil or Attr == 'size' then
      Border:SetWidth(Bar.HapWidth)
      Border:SetHeight(Bar.HapHeight)
    end
  end

  -- Text (StatusBar.Text).
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
end

-------------------------------------------------------------------------------
-- SetHapBarLayout
--
-- Sets a health and power bar with a new layout.
--
-- Usage: SetHapBarLayout(UnitBarF)
--
-- UnitBarF     Unitbar that contains the health and power bar that is being setup.
-------------------------------------------------------------------------------
function GUB.HapBar:SetHapBarLayout(UnitBarF)

  -- Get the unitbar data.
  local UB = UnitBarF.UnitBar

  local Border = UnitBarF.Border
  Border:ClearAllPoints()
  Border:SetPoint('TOPLEFT', 0, 0)

  local StatusBar = UnitBarF.StatusBar
  StatusBar:SetMinMaxValues(0, 100)
  StatusBar:SetValue(0)

    -- Set all attributes.
  UnitBarF:SetAttr(nil, nil)

  -- Save size data to UnitBarF.
  UnitBarF.Width = UB.Bar.HapWidth
  UnitBarF.Height = UB.Bar.HapHeight

  -- Save a reference of unitbar data.
  StatusBar.UnitBar = UnitBarF.UnitBar

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
end
