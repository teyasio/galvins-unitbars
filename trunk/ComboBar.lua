--
-- ComboBar.lua
--
-- Displays 5 rectangles for combo points.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.ComboBar = {}

-- shared from Main.lua
local LSM = GUB.UnitBars.LSM
local CheckEvent = GUB.UnitBars.CheckEvent
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

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.UnitBar          Reference to the unitbar data for the combobar.
-- UnitBarF.OffsetFrame      Offset frame this is a parent of ComboF[]
--                           This is used for rotation offset in SetComboBarLayout()
-- UnitBarF.ColorAllNames[]  List of names to be used in the color all options panel.
-- UnitBarF.ComboF[]         Array of combo points from 1 to 5. This also
--                           contains the frame of the combo point.
--
-- UnitBarF.ComboPoints      The number of combo points last displayed.
--
-- ComboF[Combo].Anchor
--                           Reference to unitbar anchor for moving.
-- ComboF[Combo].Border      Border frame for each combo point.
-- ComboF[Combo].StatusBar   Statusbar for each combo point.
-- Border.TooltipName        Tooltip text to display for mouse over when bars are unlocked.
-- Border.TooltipDesc        Description under the name for mouse over.
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

  -- Save the current number of combo points.
  self.ComboPoints = ComboPoints

  -- Display the combo points
  RefreshComboBar(self.ComboF)

  -- Set this IsActive flag
  self.IsActive = ComboPoints > 0

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
--               'frame' for the frame.
-- Attr         Type of attribute being applied to object:
--               'color'   Color being set to the object.
--               'size'    Size being set to the object.
--               'padding' Amount of padding set to the object.
--               'texture' One or more textures set to the object.
--               'scale'   Scale settings being set to the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.ComboBar:SetAttrCombo(Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Background = UB.Background
  local Bar = UB.Bar
  local Padding = Bar.Padding

  -- Frame.
  if Object == nil or Object == 'frame' then
    if Attr == nil or Attr == 'scale' then
      self.ScaleFrame:SetScale(UB.Other.Scale)
    end
  end

  for ComboIndex, CF in ipairs(self.ComboF) do

      -- Background (Border).
    if Object == nil or Object == 'bg' then
      local Border = CF.Border
      local BgColor = nil

      -- Get all color if ColorAll is true.
      if Background.ColorAll then
        BgColor = Background.Color
      else
        BgColor = Background.Color[ComboIndex]
      end

      if Attr == nil or Attr == 'backdrop' then
        Border:SetBackdrop(GUB.UnitBars:ConvertBackdrop(Background.BackdropSettings))
        Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
      if Attr == nil or Attr == 'color' then
        Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      local Border = CF.Border
      local StatusBar = CF.StatusBar

      if Attr == nil or Attr == 'texture' then
        StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTexture))
        StatusBar:GetStatusBarTexture():SetHorizTile(false)
        StatusBar:GetStatusBarTexture():SetVertTile(false)
        StatusBar:SetOrientation(Bar.FillDirection)
        StatusBar:SetRotatesTexture(Bar.RotateTexture)
      end
      if Attr == nil or Attr == 'color' then
        local BarColor = nil

        -- Get all color if ColorAll is true.
        if Bar.ColorAll then
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
  local Gen = UB.General

  local ComboWidth = UB.Bar.ComboWidth
  local ComboHeight = UB.Bar.ComboHeight
  local Padding = Gen.ComboPadding
  local Angle = Gen.ComboAngle
  local x = 0
  local y = 0
  local BorderWidth = 0
  local BorderHeight = 0
  local OffsetFX = 0
  local OffsetFY = 0

  -- Get the offsets based on angle.
  local XOffset, YOffset = GUB.UnitBars:AngleToOffset(ComboWidth + Padding, ComboHeight + Padding, Angle)

  -- Set up the combo point positions.
  for ComboIndex, CF in ipairs(UnitBarF.ComboF) do

    -- Set the combo box min/max values
    local StatusBar = CF.StatusBar
    StatusBar:ClearAllPoints()
    StatusBar:SetMinMaxValues(0, 1)
    StatusBar:SetValue(0)

    -- Calculate the x and y location before setting the location if angle is > 180.
    if Angle > 180 and ComboIndex > 1 then
      x = x + XOffset
      y = y + YOffset
    end

    -- Set the location of the combo box.
    local Border = CF.Border
    Border:ClearAllPoints()
    Border:SetPoint('TOPLEFT', x, y)

    -- Calculate the border width
    if XOffset ~= 0 then
      BorderWidth = BorderWidth + abs(XOffset)
      if ComboIndex == 1 then
        BorderWidth = BorderWidth - Padding
      end
    else
      BorderWidth = ComboWidth
    end

    -- Calculate the border height.
    if YOffset ~= 0 then
      BorderHeight = BorderHeight + abs(YOffset)
      if ComboIndex == 1 then
        BorderHeight = BorderHeight - Padding
      end
    else
      BorderHeight = ComboHeight
    end

    -- Get the x y for the frame offset.
    if x < 0 then
      OffsetFX = abs(x)
    end
    if y > 0 then
      OffsetFY = -y
    end

    -- Calculate the x and y location after setting location if angle <= 180.
    if Angle <= 180 then
      x = x + XOffset
      y = y + YOffset
    end
  end

  -- Set the x, y location off the offset frame.
  local OffsetFrame = UnitBarF.OffsetFrame
  OffsetFrame:ClearAllPoints()
  OffsetFrame:SetPoint('TOPLEFT', OffsetFX, OffsetFY)
  OffsetFrame:SetWidth(1)
  OffsetFrame:SetHeight(1)

  -- Set the attributes for the combobar
  UnitBarF:SetAttr(nil, nil)

  -- Update combo points
  RefreshComboBar(UnitBarF.ComboF)

  -- Save size data to UnitBarF.
  UnitBarF.Width = BorderWidth
  UnitBarF.Height = BorderHeight
end

-------------------------------------------------------------------------------
-- CreateComboBar
--
-- Usage: GUB.ComboBar:CreateComboBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the combo bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ComboBar:CreateComboBar(UnitBarF, UB, Anchor, ScaleFrame)

  -- Create the offset frame.
  local OffsetFrame = CreateFrame('Frame', nil, ScaleFrame)

  local ColorAllNames = {}
  local ComboF = {}

  for ComboPoint = 1, MaxComboPoints do
    local CF = {}

    local Border = CreateFrame('Frame', nil, OffsetFrame)

    local StatusBar = CreateFrame('StatusBar', nil, Border)

    -- Make the border frame top when clicked.
    Border:SetToplevel(true)

    -- Save a reference to the anchor for moving.
    Border.Anchor = Anchor

    -- Save the frames.
    CF.Border = Border
    CF.StatusBar = StatusBar

    -- Save the text for tooltips/options.
    local Name = strconcat('Combo ', ComboPoint)
    CF.Border.TooltipName = Name
    CF.Border.TooltipDesc = MouseOverDesc
    ColorAllNames[ComboPoint] = Name

    -- Save a reference to the unitbar anchor for moving.
    CF.Anchor = Anchor

    ComboF[ComboPoint] = CF
  end

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the offset frame and Combo frame.
  UnitBarF.OffsetFrame = OffsetFrame
  UnitBarF.ComboF = ComboF
end
