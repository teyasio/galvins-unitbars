--
-- HolyBar.lua
--
-- Displays Paldin holy power.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.HolyBar = {}

-- shared from Main.lua
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
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- Border.TooltipName                Tooltip text to display for mouse over when bars are unlocked.
-- Border.TooltipDesc                Description under the name for mouse over.
-- UnitBarF.UnitBar                  Reference to the unitbar data for the holybar.
-- UnitBarF.Border                   Border frame for the holy bar. This is a parent of
--                                   OffSetF.
-- UnitBarF.OffsetFrame              Offset frame this is a parent of HolyRuneF[]
--                                   This is used for rotation offset in SetHolyBarLayout()
-- UnitBarF.HolyRuneF[]              Frame array containing all 3 holy runes. This also
--                                   contains the frame of the holy rune.
-- HolyRuneF[Rune].HolyRuneIcon      The texture containing the holy rune.
-- HolyRuneF[Rune].FadeOut           Animation group for fadeout for the holy rune before hiding
--                                   This group is a child of the Holy Rune Frame.
-- HolyRuneF[Rune].FadeOutA          Animation that contains the fade out.  This is a child
--                                   of FadeOut
-- HolyRuneF[Rune].Dark              True then the holy rune is not lit.  True holy rune is lit.
--
-- HolyPowerTexture                  Texture file containing all the holy power textures.
-- HolyRunes[]                       Contains the texture layout data for the holyrunes.
-- HolyRunes[Rune].Width             Width of the rune texture.
-- HolyRunes[Rune].Height            Height of the rune texture.
-- Holyrunes[Rune]
--   Left, Right, Top, Bottom        Texture coordinates inside of the HolyPowerTexture
--                                   containing the holy rune.
-- HolyRunes.Padding
--   Left, Right, Top, Bottom        Amount of padding within each HolyRuneFrame.
--                                   This makes it so each holy rune texture doesn't
--                                   touch the border.  Makes it look nicer.
-------------------------------------------------------------------------------

-- Powertype constants
local PowerHoly = PowerTypeToNumber['HOLY_POWER']

local HolyPowerTexture = 'Interface\\PlayerFrame\\PaladinPowerTextures'
local HolyRunes = {
  DarkColor = {r = 0.15, g = 0.15, b = 0.15, a = 1},
  [1] = {
    Width = 36, Height = 22,
    Left = 0.00390625, Right = 0.14453125, Top = 0.64843750, Bottom = 0.82031250
  },
  [2] = {
    Width = 31, Height = 17,
    Left = 0.00390625, Right = 0.12500000, Top = 0.83593750, Bottom = 0.96875000
  },
  [3] = {
    Width = 27, Height = 21,
    Left = 0.15234375, Right = 0.25781250, Top = 0.64843750, Bottom = 0.81250000
  }
}


--*****************************************************************************
--
-- Holybar script functions (script/event)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- HolyBarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar parent frame will be moved.
-- Otherwise just the holybar will be moved.
-------------------------------------------------------------------------------
local function HolyBarStartMoving(self, Button)

  -- Call the base moving function for group or anchor movement.
  if GUB.UnitBars.UnitBarStartMoving(self.Anchor, Button) then
    self.UnitBarMoving = true
  end
end

-------------------------------------------------------------------------------
-- HolyBarStopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
-------------------------------------------------------------------------------
local function HolyBarStopMoving(self, Button)

  -- Call the stop moving base function if there was a group move or anchor move.
  if self.UnitBarMoving then
    self.UnitBarMoving = false
    GUB.UnitBars.UnitBarStopMoving(self.Anchor, Button)
  end
end

--*****************************************************************************
--
-- Holybar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateHolyRunes
--
-- Lights or darkens holy runes
--
-- Usage: UpdateHolyRunes(HolyRuneF, HolyPower, FinishFadeOut)
--
-- HolyBarF         HolyBar containing runes to update.
-- HolyPower        Updates the holy runes based on the holypower.
-- FinishFadeOut    If true then any fadeout animation currently playing
--                  will be stopped.
--                  If nil or false then does nothing.
-------------------------------------------------------------------------------
local function UpdateHolyRunes(HolyBarF, HolyPower, FinishFadeOut)
  local FadeOutTime = HolyBarF.UnitBar.General.HolyFadeOutTime

  for HolyIndex, HRF in ipairs(HolyBarF.HolyRuneF) do
    local FadeOut = HRF.FadeOut
    local HolyRuneIcon = HRF.HolyRuneIcon

    -- If FinishFadeOut is true then stop any fadout animation and darken the rune.
    if FinishFadeOut then
      if HRF.Dark then
        GUB.UnitBars:AnimationFadeOut(FadeOut, 'finish')
        HolyRuneIcon:SetAlpha(0)
      end

    -- Light a rune based on HolyPower.
    elseif HRF.Dark and HolyIndex <= HolyPower then
      if FadeOutTime > 0 then

        -- Finish animation if it's playing.
        GUB.UnitBars:AnimationFadeOut(FadeOut, 'finish')
      end
      HolyRuneIcon:SetAlpha(1)
      HRF.Dark = false

    -- Darken a rune based on HolyPower.
    elseif not HRF.Dark and HolyIndex > HolyPower then
      if FadeOutTime > 0 then

        -- Fade out the holy rune then hide it.
        GUB.UnitBars:AnimationFadeOut(FadeOut, 'start', function() HolyRuneIcon:SetAlpha(0) end)
      else
        HolyRuneIcon:SetAlpha(0)
      end
      HRF.Dark = true
    end
  end
end

-------------------------------------------------------------------------------
-- UpdateHolyBar (Update) [UnitBar assigned function]
--
-- Update the holy power level of the player
--
-- usage: UpdateHolyBar(Event, PowerType)
--
-- Event                If nil no event check will be done.
-- PowerType            If not equal to 'HOLY_POWER' then nothing will be updated
--                      unless it's nil
-------------------------------------------------------------------------------
function GUB.HolyBar:UpdateHolyBar(Event, PowerType)

  -- If PowerType is nil then set it to holy power type.
  if PowerType == nil then
    PowerType = 'HOLY_POWER'
  end

  -- Return if the unitbar is disabled, or event is not a power event, or its not holy power.
  if not self.Enabled or Event ~= nil and CheckEvent[Event] ~= 'power' or
     CheckPowerType[PowerType] ~= 'holy' then
    return
  end

  local HolyPower = UnitPower('player', PowerHoly)

  UpdateHolyRunes(self, HolyPower)

    -- Set this IsActive flag
  self.IsActive = HolyPower > 0

  -- Do a status check for active status.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Holybar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicksHoly (EnableMouseClicks) [UnitBar assigned function]
--
-- This will enable or disbable mouse clicks for the holy bar.
-------------------------------------------------------------------------------
function GUB.HolyBar:EnableMouseClicksHoly(Enable)
  self.Border:EnableMouse(Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScriptHoly (FrameSetScript) [UnitBar assigned function]
--
-- Set up script handlers for the Holybar.
-------------------------------------------------------------------------------
function GUB.HolyBar:FrameSetScriptHoly(Enable)
  local Border = self.Border
  local HolyBarF = self
  if Enable then
    Border:SetScript('OnMouseDown', HolyBarStartMoving)
    Border:SetScript('OnMouseUp', HolyBarStopMoving)
    Border:SetScript('OnHide', function(self)
                                 HolyBarStopMoving(self)

                                 -- Cancel any fadeout animations currently playing.
                                 UpdateHolyRunes(HolyBarF, 0, true)
                               end)
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

-------------------------------------------------------------------------------
-- EnableScreenClampCombo (EnableScreenClamp) [UnitBar assigned function]
--
-- Enables or disble screen clamp for the combo bar.
-------------------------------------------------------------------------------
function GUB.HolyBar:EnableScreenClampHoly(Enable)
  self.Border:SetClampedToScreen(Enable)
end

-------------------------------------------------------------------------------
-- SetAttrHoly  (SetAttr) [UnitBar assigned function]
--
-- Sets different parts of the holybar.
--
-- Usage: SetHolyCombo(Object, Attr)
--
-- Object       Object being changed:
--               'bg' for background (Border).
--               'bar' for forground (StatusBar).
--               'frame' for the frame.
--
--               'color'     Color being set to the object.
--               'backdrop'  Backdrop settings being set to the object.
--               'scale'     Scale settings being set to the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.HolyBar:SetAttrHoly(Object, Attr)

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
end

-------------------------------------------------------------------------------
-- SetHolyBarLayout
--
-- Set a holybar to a new layout
--
-- Usage: SetHolyBarLayout(UnitBarF)
--
-- UnitBarF     Unitbar that contains the holy bar that is being setup.
-------------------------------------------------------------------------------
function GUB.HolyBar:SetHolyBarLayout(UnitBarF)

  -- Get the unitbar data.
  local Gen = UnitBarF.UnitBar.General

  local Anchor = UnitBarF.Anchor

  local HolySize = Gen.HolySize
  local HolyScale = Gen.HolyScale
  local Padding = Gen.HolyPadding
  local FadeOutTime = Gen.HolyFadeOutTime
  local Angle = Gen.HolyAngle
  local x = 0
  local y = 0
  local XOffset = 0
  local YOffset = 0
  local BorderWidth = 0
  local BorderHeight = 0
  local OffsetFX = 0
  local OffsetFY = 0

  for RuneIndex, HRF in ipairs(UnitBarF.HolyRuneF) do

    -- Set the duration of the fade out.
    HRF.FadeOutA:SetDuration(FadeOutTime)

    local HR = HolyRunes[RuneIndex]

    -- Calculate the size of the holy rune.
    local Width = HR.Width
    local Height = HR.Height
    local Scale = 0

    -- Scale by width if the bar is vertical.
    if Angle == 180 or Angle == 360 then
      Scale = HolySize / Width
    else

      -- Scale by height
      Scale = HolySize / Height
    end
    Width = Width * Scale
    Height = Height * Scale

    -- Set the width and height of the holy rune.
    HRF:SetWidth(Width)
    HRF:SetHeight(Height)

    -- Center the holy rune.
    local HolyRuneIcon = HRF.HolyRuneIcon
    HolyRuneIcon:ClearAllPoints()
    HolyRuneIcon:SetPoint('CENTER', 0, 0)

    -- Set the scale of the holy texture.
    local ScaleX = Width * HolyScale
    local ScaleY = Height * HolyScale
    HolyRuneIcon:SetWidth(ScaleX)
    HolyRuneIcon:SetHeight(ScaleY)

    -- Center the dark holy rune.
    local HolyRuneIconDark = HRF.HolyRuneIconDark
    HolyRuneIconDark:ClearAllPoints()
    HolyRuneIconDark:SetPoint('CENTER', 0, 0)

    -- Set the scale to the dark holy texture.
    HolyRuneIconDark:SetWidth(ScaleX)
    HolyRuneIconDark:SetHeight(ScaleY)

    -- Get the offsets based on angle.
    XOffset, YOffset = GUB.UnitBars:AngleToOffset(Width + Padding, Height + Padding, Angle)

    -- Calculate the x and y location before setting the location if angle is > 180.
    if Angle > 180 and RuneIndex > 1 then
      x = x + XOffset
      y = y + YOffset
    end

    -- Set the location of the holy rune.
    HRF:ClearAllPoints()
    HRF:SetPoint('TOPLEFT', x, y)

    -- Calculate the border width.
    if XOffset ~= 0 then
      BorderWidth = BorderWidth + abs(XOffset)
      if RuneIndex == 1 then
        BorderWidth = BorderWidth - Padding
      end
    elseif BorderWidth < Width then
      BorderWidth = Width
    end

    -- Calculate the border height.
    if YOffset ~= 0 then
      BorderHeight = BorderHeight + abs(YOffset)
      if RuneIndex == 1 then
        BorderHeight = BorderHeight - Padding
      end
    elseif BorderHeight < Height then
      BorderHeight = Height
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

  local Border = UnitBarF.Border
  Border:ClearAllPoints()
  Border:SetPoint('TOPLEFT', 0, 0)

  -- Set the size of the border.
  Border:SetWidth(BorderWidth)
  Border:SetHeight(BorderHeight)

  -- Set the x, y location off the offset frame.
  local OffsetFrame = UnitBarF.OffsetFrame
  OffsetFrame:ClearAllPoints()
  OffsetFrame:SetPoint('TOPLEFT', OffsetFX, OffsetFY)
  OffsetFrame:SetWidth(1)
  OffsetFrame:SetHeight(1)

  -- Set all attributes.
  UnitBarF:SetAttr(nil, nil)

  -- Save size data to UnitBarF.
  UnitBarF.Width = BorderWidth
  UnitBarF.Height = BorderHeight
end

-------------------------------------------------------------------------------
-- CreateHolyBar
--
-- Usage: GUB.HolyBar:CreateHolyBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the combo bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.HolyBar:CreateHolyBar(UnitBarF, UB, Anchor, ScaleFrame)

  local Border = CreateFrame('Frame', nil, ScaleFrame)

  -- Make the border frame top when clicked.
  Border:SetToplevel(true)

  -- Create the offset frame.
  local OffsetFrame = CreateFrame('Frame', nil, Border)

  local DarkColor = HolyRunes.DarkColor
  local HolyRuneF = {}

  for RuneIndex, HR in ipairs(HolyRunes) do

    -- Create the holy rune frame.
    local HolyRuneFrame = CreateFrame('Frame', nil, OffsetFrame)

    -- Create the holy rune texture.
    local HolyRuneIcon = HolyRuneFrame:CreateTexture(nil, 'OVERLAY')
    HolyRuneIcon:SetTexture(HolyPowerTexture)
    HolyRuneIcon:SetTexCoord(HR.Left, HR.Right, HR.Top, HR.Bottom)
    HolyRuneIcon:SetAlpha(0)

    -- Create Dark holy rune texture.
    local HolyRuneIconDark = HolyRuneFrame:CreateTexture(nil, 'ARTWORK')
    HolyRuneIconDark:SetTexture(HolyPowerTexture)
    HolyRuneIconDark:SetTexCoord(HR.Left, HR.Right, HR.Top, HR.Bottom)
    HolyRuneIconDark:SetDesaturated(true)
    HolyRuneIconDark:SetVertexColor(DarkColor.r, DarkColor.g, DarkColor.b, DarkColor.a)

    -- Create an animation for fade out.
    local FadeOut = HolyRuneIcon:CreateAnimationGroup()
    local FadeOutA = FadeOut:CreateAnimation('Alpha')

    -- Set the animation group values.
    FadeOut:SetLooping('NONE')
    FadeOutA:SetChange(-1)
    FadeOutA:SetOrder(1)

    -- Set the holy rune to dark.
    HolyRuneFrame.Dark = true
    HolyRuneIcon:SetAlpha(0)

    -- Save the animation.
    HolyRuneFrame.FadeOut = FadeOut
    HolyRuneFrame.FadeOutA = FadeOutA

    -- Save the holy runeicon and dark one.
    HolyRuneFrame.HolyRuneIcon = HolyRuneIcon
    HolyRuneFrame.HolyRuneIconDark = HolyRuneIconDark

    HolyRuneF[RuneIndex] = HolyRuneFrame
  end

  -- Save the name for tooltips.
  Border.TooltipName = UB.Name
  Border.TooltipDesc = MouseOverDesc

  -- Save a reference to the anchor for moving.
  Border.Anchor = Anchor

  -- Save the offsetframe and Border and holyrunes.
  UnitBarF.Border = Border
  UnitBarF.OffsetFrame = OffsetFrame
  UnitBarF.HolyRuneF = HolyRuneF
end
