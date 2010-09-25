--
-- ComboBar.lua
--
-- Displays 5 rectangles for combo points.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.ComboBar = {}

-- shared tables from Main.lua
local CheckEvent = GUB.UnitBars.CheckEvent
local UnitBarsF = GUB.UnitBars.UnitBarsF
local LSM = GUB.UnitBars.LSM

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.UnitBar          Reference to the unitbar data for the combobar.
-- UnitBarF.ComboF           Reference to ComboF.
-- UnitBarF.ComboPoints      The number of combo points last displayed.
--
-- ComboF                    Array of combo points from 1 to 5
-- ComboF[ComboPoint].Anchor
--                           Reference to unitbar anchor for moving.
-------------------------------------------------------------------------------
local MaxComboPoints = 5

--*****************************************************************************
--
-- Combobar script functions (script/event)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- ComboBarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar parent frame will be moved.
-- Otherwise just the combobar will be moved.
-------------------------------------------------------------------------------
local function ComboBarStartMoving(self, Button)

  -- Call the base moving function for group or anchor movement.
  if GUB.UnitBars.UnitBarStartMoving(self.Anchor, Button) then
    self.UnitBarMoving = true
  end
end

-------------------------------------------------------------------------------
-- ComboBarStopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
-------------------------------------------------------------------------------
local function ComboBarStopMoving(self, Button)

  -- Call the stop moving base function if there was a group move or anchor move.
  if self.UnitBarMoving then
    self.UnitBarMoving = false
    GUB.UnitBars.UnitBarStopMoving(self.Anchor, Button)
  end
end


--*****************************************************************************
--
-- Combobar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- RefreshComboBar
--
-- Refreshes the combobar based on the server.
--
-- Usage: RefreshComboBar(ComboF)
--
-- ComboF     The bar containing the combo points.
-------------------------------------------------------------------------------
local function RefreshComboBar(ComboF)
  local ComboPoints = GetComboPoints('player', 'target')
  local ComboOn = 0

  for ComboIndex, CF in ipairs(ComboF) do
    if ComboIndex <= ComboPoints then
      ComboOn = 1
    else
      ComboOn = 0
    end
    CF.StatusBar:SetValue(ComboOn)
  end
end


-------------------------------------------------------------------------------
-- UpdateComboBar (Update) [UnitBar assigned function]
--
-- Usage: UpdateComboBar(Event)
--
-- Event     Combo point event.  If this is not a combo point event then the
--           function does nothing.
--           If event == nil then the bar will get updated.
-------------------------------------------------------------------------------
function GUB.ComboBar:UpdateComboBar(Event)

  -- Get the combo points.
  local ComboPoints = GetComboPoints('player', 'target')

  -- Return if combo points hasn't changed or event check fails.
  if not self.Enabled or self.ComboPoints == ComboPoints or
     Event ~= nil and CheckEvent[Event] ~= 'combo' then
    return
  end

  -- Set this IsActive flag
  local IsActive = ComboPoints > 0
  self.IsActive = IsActive

  -- Save the current number of combo points.
  self.ComboPoints = ComboPoints

  -- Display the combo points
  RefreshComboBar(self.ComboF)

  -- Do a status check for active status.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Combobar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicksCombo (EnableMouseClicks) [UnitBar assigned function]
--
-- This will enable or disbale mouse clicks for the combo bar.
-------------------------------------------------------------------------------
function GUB.ComboBar:EnableMouseClicksCombo(Enable)
  for _, CF in ipairs(self.ComboF) do
    CF.Border:EnableMouse(Enable)
  end
end

-------------------------------------------------------------------------------
-- FrameSetScriptCombo (FrameSetScript) [UnitBar assigned function]
--
-- Set up script handlers for the Combobar.
-------------------------------------------------------------------------------
function GUB.ComboBar:FrameSetScriptCombo(Enable)
  for _, CF in ipairs(self.ComboF) do
    local Border = CF.Border
    if Enable then
      Border:SetScript('OnMouseDown', ComboBarStartMoving)
      Border:SetScript('OnMouseUp', ComboBarStopMoving)
      Border:SetScript('OnHide', ComboBarStopMoving)
      Border:SetScript('OnEnter', function(self)
                                    GUB.UnitBars.UnitBarTooltip(self, false)
                                  end)
      Border:SetScript('OnLeave', function(self)
                                    GUB.UnitBars.UnitBarTooltip(self, true)
                                  end)

    else
      Border:SetScript('OnMouseDown', nil)
      Border:SetScript('OnMouseUp', nil)
      Border:SetScript('OnHide', nil)
      Border:SetScript('OnEnter', nil)
      Border:SetScript('OnLeave', nil)
    end
  end
end

-------------------------------------------------------------------------------
-- EnableScreenClampCombo (EnableScreenClamp) [UnitBar assigned function]
--
-- Enables or disble screen clamp for the combo bar.
-------------------------------------------------------------------------------
function GUB.ComboBar:EnableScreenClampCombo(Enable)
  for _, CF in ipairs(self.ComboF) do

    -- Prevent combo bar from being moved off screen.
    CF.Border:SetClampedToScreen(Enable)
  end
end

-------------------------------------------------------------------------------
-- SetAttrCombo  (SetAttr) [UnitBar assigned function]
--
-- Sets different parts of the combobar.
--
-- Usage: SetAttrCombo(Object, Attr)
--
-- Object       Object being changed:
--               'bg' for background (Border).
--               'bar' for forground (StatusBar).
-- Attr         Type of attribute being applied to object:
--               'color'   Color being set to the object.
--               'size'    Size being set to the object.
--               'padding' Amount of padding set to the object.
--               'texture' One or more textures set to the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.ComboBar:SetAttrCombo(Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local ComboColorAll = UB.ComboColorAll

  for ComboIndex, CF in ipairs(self.ComboF) do

      -- Background (Border).
    if Object == nil or Object == 'bg' then
      local Border = CF.Border
      local BgColor = nil

      -- Get all color if ComboColorAll is true.
      if ComboColorAll then
        BgColor = UB.Background.Color
      else
        BgColor = UB.Background.Color[ComboIndex]
      end

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
      local StatusBar = CF.StatusBar
      local Border = CF.Border

      local Bar = UB.Bar
      local Padding = Bar.Padding

      if Attr == nil or Attr == 'texture' then
        StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTexture))
        StatusBar:GetStatusBarTexture():SetHorizTile(false)
        StatusBar:GetStatusBarTexture():SetVertTile(false)
      end
      if Attr == nil or Attr == 'color' then
        local BarColor = nil

        -- Get all color if ComboColorAll is true.
        if ComboColorAll then
          BarColor = Bar.Color
        else
          BarColor = Bar.Color[ComboIndex]
        end
        StatusBar:SetStatusBarColor(BarColor.r, BarColor.g, BarColor.b, BarColor.a)
      end
      if Attr == nil or Attr == 'padding' then
        StatusBar:ClearAllPoints()
        StatusBar:SetPoint('TOPLEFT', Padding.Left , Padding.Top)
        StatusBar:SetPoint('BOTTOMRIGHT', Padding.Right, Padding.Bottom)
      end
      if Attr == nil or Attr == 'size' then
        Border:SetWidth(Bar.ComboWidth)
        Border:SetHeight(Bar.ComboHeight)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetComboBarLayout
--
-- Sets a combo bar with a new layout.
--
-- Usage: SetComboBarLayout(UnitBarF)
--
-- UnitBarF     Unitbar that contains the combo bar that is being setup.
-------------------------------------------------------------------------------
function GUB.ComboBar:SetComboBarLayout(UnitBarF)

  -- Get the unitbar data.
  local UB = UnitBarF.UnitBar

  local ComboWidth = UB.Bar.ComboWidth
  local ComboHeight = UB.Bar.ComboHeight
  local Padding = UB.ComboPadding
  local x = 0
  local y = 0

  -- Get the offsets based on angle.
  local XOffset, YOffset = GUB.UnitBars:AngleToOffset(ComboWidth + Padding, ComboHeight + Padding, UB.ComboAngle)

  -- Set up the combo point positions.
  for ComboIndex, CF in ipairs(UnitBarF.ComboF) do

    -- Set the location of the combo box.
    local Border = CF.Border
    Border:ClearAllPoints()
    Border:SetPoint('TOPLEFT', x, y)

    -- Set the combo box min/max values
    local StatusBar = CF.StatusBar
    StatusBar:ClearAllPoints()
    StatusBar:SetMinMaxValues(0, 1)
    StatusBar:SetValue(0)

    x = x + XOffset
    y = y + YOffset
  end

  -- Set the attributes for the combobar
  UnitBarF:SetAttr(nil, nil)

  -- Save size data to UnitBarF.
  UnitBarF.Width = (ComboWidth + Padding) * MaxComboPoints - Padding
  UnitBarF.Height = ComboHeight

  -- Update combo points
  RefreshComboBar(UnitBarF.ComboF)
end

-------------------------------------------------------------------------------
-- CreateComboFrame
--
-- Usage: ComboF = CreateComboFrame(Parent)
--
-- Anchor       The Unitbars anchor frame.
-- ComboF       Combo frame.
-------------------------------------------------------------------------------
local function CreateComboFrame(Anchor)
  local ComboF = {}

  local Border = CreateFrame('Frame', nil, Anchor)
  local StatusBar = CreateFrame('StatusBar', nil, Border)

  -- Make the border frame top when clicked.
  Border:SetToplevel(true)

  -- Save a reference to the anchor for moving.
  Border.Anchor = Anchor

  -- Save the frames.
  ComboF.Border = Border
  ComboF.StatusBar = StatusBar

  return ComboF
end

-------------------------------------------------------------------------------
-- CreateComboBar
--
-- Usage: GUB.ComboBar:CreateComboBar(UnitBarF, Anchor)
--
-- UnitBarF     The unitbar frame which will contain the combo bar.
-- Anchor       The unitbars anchor.
--
-- CB           Combo bar frame.
-------------------------------------------------------------------------------
function GUB.ComboBar:CreateComboBar(UnitBarF, Anchor)

  -- Save a reference to the parent frame for readability.
  local ComboF = {}
  local CF = nil

  for ComboPoint = 1, MaxComboPoints do
    local CF = CreateComboFrame(Anchor)

    -- Save the name for tooltips.
    CF.Border.Name = strconcat('Combo ', ComboPoint)

    -- Save a reference to the unitbar anchor for moving.
    CF.Anchor = Anchor

    ComboF[ComboPoint] = CF
  end


  -- Save a reference to ComboF.
  UnitBarF.ComboF = ComboF
end
