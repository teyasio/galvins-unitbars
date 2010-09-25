--
-- HealthPower.lua
--
-- Displays health and power bars.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.HapBar = {}

-- shared tables from Main.lua
local CheckEvent = GUB.UnitBars.CheckEvent
local UnitBarsF = GUB.UnitBars.UnitBarsF
local LSM = GUB.UnitBars.LSM

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.Border          Border frame for the health and power bar.
-- UnitBarF.StatusBar       The Statusbar for the health and power bar.
--
-- Border.Anchor            Reference to the anchor for moving.
-- Border.Name              Name to display when mouse over while the bars are
--                          not locked.
-- Border.UnitBarF          Reference to unitbarF for for onsizechange.
--
-- StatusBar.UnitBar        Reference to unitbar data for GetStatusBarTextValue()
-------------------------------------------------------------------------------

-- Powertype constants
local PowerMana = 0
local PowerRage = 1
local PowerFocus = 2
local PowerEnergy = 3
local PowerRunic = 6

--*****************************************************************************
--
-- Health and Power bar utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- GetStatusBarTextValue
--
-- Returns two parameters to be used in SetFormattedText.  In percent, whole number,
-- max, or ''.
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
  local TextType = StatusBar.UnitBar.TextType
  if MaxValue == 0 then
    return ''
  elseif TextType == 'whole' then
    return '%d', CurrValue
  elseif TextType == 'percent' then
    return '%d%%', math.ceil(CurrValue / MaxValue * 100)
  elseif TextType == 'max' then
    return '%d / %d', CurrValue, MaxValue
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

  -- Display the value.
  SetStatusBarValue(self.StatusBar, CurrValue, MaxValue)

  -- Set the IsActive flag.
  local IsActive = CurrValue < MaxValue
  self.IsActive = IsActive

  -- Do a status check for active status.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- UpdatePowerBar (Update) [UnitBar assigned function]
--
-- Updates the power of the current player or target.
--
-- Usage: UpdatePowerBar(Event, Unit, PowerType)
--
-- Event      * If nil then PowerType will be used instead.
--            * If it's not a power event then the power bar doesn't get updated.
--            * If it didn't match with the units powertype or the powertype
--              passed then the bar won't be updated.
--            Example: UNIT_MANA wouldn't match powertype rage.
-- Unit       player or target.
-- PowerType  If nil then units current powertype is used.
--
-- NOTE:  When updating 'player' power the PowerType must match the players
--        default power type.
-------------------------------------------------------------------------------
function GUB.HapBar:UpdatePowerBar(Event, Unit, PowerType)

  -- Return if the unitbar is disabled.
  if not self.Enabled then
    return
  end

  -- If event is not nil then get unit's powertype.
  if PowerType == nil then
    PowerType = UnitPowerType(Unit)
  end
  if Event ~= nil then
    local Value = CheckEvent[Event]

    -- If the converted event doesn't match the powertype then return.
    if Value ~= PowerType then
      return
    end
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

-------------------------------------------------------------------------------
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
-- Attr         Type of attribute being applied to object:
--               'color'     Color being set to the object.
--               'size'      Size being set to the object.
--               'padding'   Amount of padding set to the object.
--               'texture'   One or more textures set to the object.
--               'font'      Font settings being set to the object.
--               'backdrop'  Backdrop settings being set to the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.HapBar:SetAttrHap(Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar

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
    end

    -- Make sure theres a hash table for color.  Power bars don't use hash color tables.
    if BarColor.r and (Attr == nil or Attr == 'color') then
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

  -- Save the name for tooltips.
  Border.Name = UnitBarF.UnitBar.Name

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
-- Usage: CreateHapBar(UnitBarF, Anchor)
--
-- UnitBarF     The unitbar frame which will contain the health and power bar.
-- Anchor       Unitbar's anchor.
--
-- SB           StatusBar frame.
-------------------------------------------------------------------------------
function GUB.HapBar:CreateHapBar(UnitBarF, Anchor)
  local Border = CreateFrame('Frame', nil, Anchor)
  local StatusBar = CreateFrame('StatusBar', nil, Border)
  StatusBar.Txt = StatusBar:CreateFontString(nil, 'OVERLAY')

  -- Make the border frame top when clicked.
  Border:SetToplevel(true)

  -- Save a reference to the anchor for moving.
  Border.Anchor = Anchor

  -- Save a reference of UnitBarF to the border for onsizechange.
  Border.UnitBarF = UnitBarF

  -- Save the frames.
  UnitBarF.Border = Border
  UnitBarF.StatusBar = StatusBar
end

