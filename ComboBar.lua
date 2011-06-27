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
local pcall, abs, mod, max, floor, strsub, strupper, strconcat, tostring, pairs, ipairs, type, math, table, select =
      pcall, abs, mod, max, floor, strsub, strupper, strconcat, tostring, pairs, ipairs, type, math, table, select
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.UnitBar                    Reference to the unitbar data for the combobar.
-- UnitBarF.OffsetFrame                Offset frame this is a parent of ComboF[]
--                                     This is used for rotation offset in SetLayoutCombo()
-- UnitBarF.Border                     Ivisible border thats surrounds the unitbar. This is used
--                                     by SetScreenClamp.
-- UnitBarF.ColorAllNames[]            List of names to be used in the color all options panel.
-- UnitBarF.ComboPointF[]              Array of combo points from 1 to 5. This also contains the
--                                     frame of the combo point.
--
-- ComboPointF[].ComboPointFrame       Frame containing the ComboPointBox.  This is used for show/hide.
-- ComboPointF[].ComboPointBox         Statusbar child of ComboPointFrame
-- ComboPointF[].ComboPointBoxFrame    Visible border for ComboPointBox. Since we fadeout ComboPointFrame
--                                     This frame must be a child of OffsetFrame.
-- ComboPointF[].FadeOut               Animation group for fadeout for the combo point before hiding
--                                     This group is a child of the ComboPointFrame.
-- ComboPointF[].FadeOutA              Animation that contains the fade out.  This is a child
--                                     of FadeOut
-- ComboPointF[].Dark                  True then the combo point is not lit.  True combo point is lit.
--
-- ComboPointBoxFrame.Anchor           Anchor reference for moving.
-- ComboPointBoxFrame.TooltipName      Name of this combopoint for mouse over tooltips.
-- ComboPointBoxFrame.TooltipDesc      Description to show with the name for mouse over tooltips.
-------------------------------------------------------------------------------
local MaxComboPoints = 5

local SoulShardTexture = {
        Texture = [[Interface\PlayerFrame\UI-WarlockShard]],
        Width = 17, Height = 16,
        Left = 0.01562500, Right = 0.28125000, Top = 0.00781250, Bottom = 0.13281250
      }

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
-- UpdateComboPoints
--
-- Lights or darkens combo point boxes.
--
-- Usage: UpdateComboPoints(ComboBarF, ComboPoints, FinishFadeOut)
--
-- ComboPointF      ComboBar containing combo points to update.
-- ComboPoints      Updates the combo points based on the combopoints.
-- FinishFadeOut    If true then any fadeout animation currently playing
--                  will be stopped.
--                  If nil or false then does nothing.
-------------------------------------------------------------------------------
local function UpdateComboPoints(ComboBarF, ComboPoints, FinishFadeOut)
  local FadeOutTime = nil

  if not FinishFadeOut then
    FadeOutTime = ComboBarF.UnitBar.General.ComboFadeOutTime
  end

  for ComboIndex, CPF in ipairs(ComboBarF.ComboPointF) do
    local FadeOut = CPF.FadeOut

    -- If FinishFadeOut is true then stop any fadout animation and darken the combo point.
    if FinishFadeOut then
      if CPF.Dark then
        GUB.UnitBars:AnimationFadeOut(FadeOut, 'finish', function() CPF:Hide() end)
      end

    -- Light a combo point based on ComboPoints.
    elseif CPF.Dark and ComboIndex <= ComboPoints then
      if FadeOutTime > 0 then

        -- Finish animation if it's playing.
        GUB.UnitBars:AnimationFadeOut(FadeOut, 'finish')
      end
      CPF:Show()
      CPF.Dark = false

    -- Darken a combo point based on ComboPoints.
    elseif not CPF.Dark and ComboIndex > ComboPoints then
      if FadeOutTime > 0 then

        -- Fade out the combo point then hide it.
        GUB.UnitBars:AnimationFadeOut(FadeOut, 'start', function() CPF:Hide() end)
      else
        CPF:Hide()
      end
      CPF.Dark = true
    end
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
  if not self.Enabled or Event ~= nil and CheckEvent[Event] ~= 'combo' then
    return
  end

  -- Display the combo points
  UpdateComboPoints(self, ComboPoints)

  -- Set this IsActive flag
  self.IsActive = ComboPoints > 0

  -- Do a status check for active status.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- CancelAnimationCombo (CancelAnimation) [UnitBar assigned function]
--
-- Usage: CancelAnimationCombo()
--
-- Cancels all animation playing in the combo bar.
-------------------------------------------------------------------------------
function GUB.ComboBar:CancelAnimationCombo()
  UpdateComboPoints(self, 0, true)
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
  for _, CPF in ipairs(self.ComboPointF) do
    CPF.ComboPointBoxFrame:EnableMouse(Enable)
  end
end

-------------------------------------------------------------------------------
-- FrameSetScriptCombo (FrameSetScript) [UnitBar assigned function]
--
-- Set up script handlers for the Combobar.
-------------------------------------------------------------------------------
function GUB.ComboBar:FrameSetScriptCombo(Enable)
  local ComboPointF = self

  for _, CPF in ipairs(self.ComboPointF) do
    local ComboPointBoxFrame = CPF.ComboPointBoxFrame
    if Enable then
      ComboPointBoxFrame:SetScript('OnMouseDown', ComboBarStartMoving)
      ComboPointBoxFrame:SetScript('OnMouseUp', ComboBarStopMoving)
      ComboPointBoxFrame:SetScript('OnHide', function(self)
                                               ComboBarStopMoving(self)
                                             end)
      ComboPointBoxFrame:SetScript('OnEnter', function(self)
                                                GUB.UnitBars.UnitBarTooltip(self, false)
                                              end)
      ComboPointBoxFrame:SetScript('OnLeave', function(self)
                                                GUB.UnitBars.UnitBarTooltip(self, true)
                                              end)
    else
      ComboPointBoxFrame:SetScript('OnMouseDown', nil)
      ComboPointBoxFrame:SetScript('OnMouseUp', nil)
      ComboPointBoxFrame:SetScript('OnHide', nil)
      ComboPointBoxFrame:SetScript('OnEnter', nil)
      ComboPointBoxFrame:SetScript('OnLeave', nil)
    end
  end
end

-------------------------------------------------------------------------------
-- EnableScreenClampCombo (EnableScreenClamp) [UnitBar assigned function]
--
-- Enables or disble screen clamp for the combo bar.
-------------------------------------------------------------------------------
function GUB.ComboBar:EnableScreenClampCombo(Enable)
  self.Border:SetClampedToScreen(Enable)
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

  for ComboIndex, CPF in ipairs(self.ComboPointF) do

      -- Background (Border).
    if Object == nil or Object == 'bg' then
      local ComboPointBoxFrame = CPF.ComboPointBoxFrame
      local BgColor = nil

      -- Get all color if ColorAll is true.
      if Background.ColorAll then
        BgColor = Background.Color
      else
        BgColor = Background.Color[ComboIndex]
      end

      if Attr == nil or Attr == 'backdrop' then
        ComboPointBoxFrame:SetBackdrop(GUB.UnitBars:ConvertBackdrop(Background.BackdropSettings))
        ComboPointBoxFrame:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
      if Attr == nil or Attr == 'color' then
        ComboPointBoxFrame:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      local ComboPointBox = CPF.ComboPointBox

      if Attr == nil or Attr == 'texture' then
        ComboPointBox:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTexture))
        ComboPointBox:GetStatusBarTexture():SetHorizTile(false)
        ComboPointBox:GetStatusBarTexture():SetVertTile(false)
        ComboPointBox:SetOrientation(Bar.FillDirection)
        ComboPointBox:SetRotatesTexture(Bar.RotateTexture)
      end
      if Attr == nil or Attr == 'color' then
        local BarColor = nil

        -- Get all color if ColorAll is true.
        if Bar.ColorAll then
          BarColor = Bar.Color
        else
          BarColor = Bar.Color[ComboIndex]
        end
        ComboPointBox:SetStatusBarColor(BarColor.r, BarColor.g, BarColor.b, BarColor.a)
      end
      if Attr == nil or Attr == 'padding' then
        ComboPointBox:ClearAllPoints()
        ComboPointBox:SetPoint('TOPLEFT', Padding.Left , Padding.Top)
        ComboPointBox:SetPoint('BOTTOMRIGHT', Padding.Right, Padding.Bottom)
      end
      if Attr == nil or Attr == 'size' then
        CPF:SetWidth(Bar.BoxWidth)
        CPF:SetHeight(Bar.BoxHeight)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayoutCombo (SetLayout) [UnitBar assigned function]
--
-- Sets a combo bar with a new layout.
--
-- Usage: SetLayoutCombo()
-------------------------------------------------------------------------------
function GUB.ComboBar:SetLayoutCombo()

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = UB.General

  local BoxWidth = UB.Bar.BoxWidth
  local BoxHeight = UB.Bar.BoxHeight
  local Padding = Gen.ComboPadding
  local FadeOutTime = Gen.ComboFadeOutTime
  local Angle = Gen.ComboAngle
  local x = 0
  local y = 0
  local BorderWidth = 0
  local BorderHeight = 0
  local OffsetFX = 0
  local OffsetFY = 0

  -- Get the offsets based on angle.
  local XOffset, YOffset = GUB.UnitBars:AngleToOffset(BoxWidth + Padding, BoxHeight + Padding, Angle)

  -- Set up the combo point positions.
  for ComboIndex, CPF in ipairs(self.ComboPointF) do

    -- Set the duration of the fade out.
    CPF.FadeOutA:SetDuration(FadeOutTime)

    -- Set the combo point min/max values.
    local ComboPointBox = CPF.ComboPointBox
    ComboPointBox:SetMinMaxValues(0, 1)
    ComboPointBox:SetValue(1)

    -- Calculate the x and y location before setting the location if angle is > 180.
    if Angle > 180 and ComboIndex > 1 then
      x = x + XOffset
      y = y + YOffset
    end

    -- Set the location of the combo point box.
    CPF:ClearAllPoints()
    CPF:SetPoint('TOPLEFT', x, y)
    CPF.ComboPointBoxFrame:SetAllPoints(CPF)

    -- Calculate the border width
    if XOffset ~= 0 then
      BorderWidth = BorderWidth + abs(XOffset)
      if ComboIndex == 1 then
        BorderWidth = BorderWidth - Padding
      end
    else
      BorderWidth = BoxWidth
    end

    -- Calculate the border height.
    if YOffset ~= 0 then
      BorderHeight = BorderHeight + abs(YOffset)
      if ComboIndex == 1 then
        BorderHeight = BorderHeight - Padding
      end
    else
      BorderHeight = BoxHeight
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

  local Border = self.Border
  Border:ClearAllPoints()
  Border:SetPoint('TOPLEFT', 0, 0)

  -- Set the size of the border.
  Border:SetWidth(BorderWidth)
  Border:SetHeight(BorderHeight)

  -- Set the x, y location off the offset frame.
  local OffsetFrame = self.OffsetFrame
  OffsetFrame:ClearAllPoints()
  OffsetFrame:SetPoint('TOPLEFT', OffsetFX, OffsetFY)
  OffsetFrame:SetWidth(1)
  OffsetFrame:SetHeight(1)

  -- Set the attributes for the combobar
  self:SetAttr(nil, nil)

  -- Save size data to self (UnitBarF).
  self.Width = BorderWidth
  self.Height = BorderHeight
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

  local Border = CreateFrame('Frame', nil, ScaleFrame)

  -- Make the border frame top when clicked.
  Border:SetToplevel(true)

  -- Create the offset frame.
  local OffsetFrame = CreateFrame('Frame', nil, Border)

  local ColorAllNames = {}
  local ComboPointF = {}

  for ComboIndex = 1, MaxComboPoints do

    -- Create the combo point frame.
    local ComboPointFrame = CreateFrame('Frame', nil, OffsetFrame)

    -- Create the combo point box frame.
    local ComboPointBoxFrame = CreateFrame('Frame', nil, OffsetFrame)

    -- Create a combo point statusbar texture.
    local ComboPointBox = CreateFrame('StatusBar', nil, ComboPointFrame)

    -- Create an animation for fade out.
    local FadeOut = ComboPointFrame:CreateAnimationGroup()
    local FadeOutA = FadeOut:CreateAnimation('Alpha')

    -- Set the animation group values.
    FadeOut:SetLooping('NONE')
    FadeOutA:SetChange(-1)
    FadeOutA:SetOrder(1)

    -- Set the combo point to dark.
    ComboPointFrame.Dark = true
    ComboPointFrame:Hide()

    -- Save the animation.
    ComboPointFrame.FadeOut = FadeOut
    ComboPointFrame.FadeOutA = FadeOutA

    -- Save the combo point frames.
    ComboPointFrame.ComboPointBoxFrame = ComboPointBoxFrame
    ComboPointFrame.ComboPointBox = ComboPointBox

    -- Save a reference to the anchor for moving.
    ComboPointBoxFrame.Anchor = Anchor

    -- Save the text for tooltips/options.
    local Name = strconcat('Combo Point ', ComboIndex)
    ComboPointBoxFrame.TooltipName = Name
    ComboPointBoxFrame.TooltipDesc = MouseOverDesc
    ColorAllNames[ComboIndex] = Name

    ComboPointF[ComboIndex] = ComboPointFrame
  end

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the offset frame and Combo Point frame and border.
  UnitBarF.Border = Border
  UnitBarF.OffsetFrame = OffsetFrame
  UnitBarF.ComboPointF = ComboPointF
end
