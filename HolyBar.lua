--
-- HolyBar.lua
--
-- Displays Paldin holy power.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.HolyBar = {}
local Main = GUB.Main

-- shared from Main.lua
local LSM = Main.LSM
local CheckPowerType = Main.CheckPowerType
local CheckEvent = Main.CheckEvent
local PowerTypeToNumber = Main.PowerTypeToNumber
local MouseOverDesc = Main.MouseOverDesc

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
-- Border.TooltipName                Tooltip text to display for mouse over when bars are unlocked.
-- Border.TooltipDesc                Description under the name for mouse over.
-- UnitBarF.UnitBar                  Reference to the unitbar data for the holybar.
-- UnitBarF.Border                   Border frame for the holy bar. This is a parent of
--                                   OffsetFrame.
-- UnitBarF.OffsetFrame              Offset frame this is a parent of HolyRuneF[]
--                                   This is used for rotation offset in SetLayoutHoly()
-- UnitBarF.HolyRuneF[]              (HolyRuneFrame) Frame array containing all 3 holy runes. This also
--                                   contains the frame of the holy rune.
-- HolyRuneF[].HolyRuneFrame         Frame. Parent of HolyRune, HolyRuneBox, and HolyRuneBoxFrame.
-- HolyRuneF[].HolyRune              The texture containing the holy rune.
-- HolyRuneF[].HolyRuneBox           Statusbar used in BoxMode only. This is a child of HolyRuneFrame
-- HolyRuneF[].HolyRuneDarkFrame     Frame. Parent of HolyRuneDark
-- HolyRuneF[].HolyRuneDark          This is the texture for the holy rune dark.
-- HolyRuneF[].HolyRuneBoxFrame      Visible frame border for the HolyruneBox. This is a child of OffsetFrame.
--
-- HolyRuneF[].FadeOut               Animation group for fadeout for the holy rune before hiding
--                                   This group is a child of the Holy Rune Frame.
-- HolyRuneF[].FadeOutA              Animation that contains the fade out.  This is a child
--                                   of FadeOut
-- HolyRuneF[].Dark                  True then the holy rune is not lit.  True holy rune is lit.
--
-- HolyRuneBoxFrame.Anchor           Anchor reference for moving.  Used in box mode.
-- HolyRuneBoxFrame.TooltipName      Name of this holy rune for mouse over tooltips. Used in box mode.
-- HolyRuneBoxFrame.TooltipDesc      Description to show with the name for mouse over tooltips.
--                                   Used in box mode.
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
-- NOTE: holy bar has two modes.  In BoxMode the holy bar is broken into 3 statusbars.
--       This works just like the combobar.  When not normal mode.  The bar uses textures instead.
-------------------------------------------------------------------------------

-- Powertype constants
local PowerHoly = PowerTypeToNumber['HOLY_POWER']

local HolyPowerTexture = [[Interface\PlayerFrame\PaladinPowerTextures]]
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
  if Main.UnitBarStartMoving(self.Anchor, Button) then
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
    Main.UnitBarStopMoving(self.Anchor, Button)
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
  local FadeOutTime = nil

  if not FinishFadeOut then
    FadeOutTime = HolyBarF.UnitBar.General.HolyFadeOutTime
  end

  for RuneIndex, HRF in ipairs(HolyBarF.HolyRuneF) do
    local FadeOut = HRF.FadeOut

    -- If FinishFadeOut is true then stop any fadout animation and darken the rune.
    if FinishFadeOut then
      if HRF.Dark then
        Main:AnimationFadeOut(FadeOut, 'finish', function() HRF:Hide() end)
      end

    -- Light a rune based on HolyPower.
    elseif HRF.Dark and RuneIndex <= HolyPower then
      if FadeOutTime > 0 then

        -- Finish animation if it's playing.
        Main:AnimationFadeOut(FadeOut, 'finish')
      end
      HRF:Show()
      HRF.Dark = false

    -- Darken a rune based on HolyPower.
    elseif not HRF.Dark and RuneIndex > HolyPower then
      if FadeOutTime > 0 then

        -- Fade out the holy rune then hide it.
        Main:AnimationFadeOut(FadeOut, 'start', function() HRF:Hide() end)
      else
        HRF:Hide()
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

-------------------------------------------------------------------------------
-- CancelAnimationHoly (CancelAnimation) [UnitBar assigned function]
--
-- Usage: CancelAnimationHoly()
--
-- Cancels all animation playing in the holy bar.
-------------------------------------------------------------------------------
function GUB.HolyBar:CancelAnimationHoly()
  UpdateHolyRunes(self, 0, true)
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
  local Border = self.Border

  -- Disable mouse clicks for border and HolyRuneBoxFrame
  Border:EnableMouse(false)
  for _, HRF in ipairs(self.HolyRuneF) do
    HRF.HolyRuneBoxFrame:EnableMouse(false)
  end

  -- Check for boxmode.
  if self.UnitBar.General.BoxMode then
    for _, HRF in ipairs(self.HolyRuneF) do
      HRF.HolyRuneBoxFrame:EnableMouse(Enable)
    end
  else
    self.Border:EnableMouse(Enable)
  end
end

-------------------------------------------------------------------------------
-- FrameSetScriptHoly (FrameSetScript) [UnitBar assigned function]
--
-- Set up script handlers for the Holybar.
-------------------------------------------------------------------------------
function GUB.HolyBar:FrameSetScriptHoly(Enable)
  local Border = self.Border
  local HolyBarF = self

  local function FrameSetScript(Frame, Enable)
    if Enable then
      Frame:SetScript('OnMouseDown', HolyBarStartMoving)
      Frame:SetScript('OnMouseUp', HolyBarStopMoving)
      Frame:SetScript('OnHide', function(self)
                                   HolyBarStopMoving(self)
                                end)
      Frame:SetScript('OnEnter', function(self)
                                    Main.UnitBarTooltip(self, false)
                                 end)
      Frame:SetScript('OnLeave', function(self)
                                    Main.UnitBarTooltip(self, true)
                                 end)
    else
      Frame:SetScript('OnMouseDown', nil)
      Frame:SetScript('OnMouseUp', nil)
      Frame:SetScript('OnHide', nil)
      Frame:SetScript('OnEnter', nil)
      Frame:SetScript('OnLeave', nil)
    end
  end

  -- Check for boxmode
  if self.UnitBar.General.BoxMode then

    -- Disable the normal mode scripts.
    FrameSetScript(Border, false)

    -- Set the new scripts for each holy rune box.
    for _, HRF in ipairs(self.HolyRuneF) do
      FrameSetScript(HRF.HolyRuneBoxFrame, Enable)
    end
  else

    -- Disable the box mode scripts.
    for _, HRF in ipairs(self.HolyRuneF) do
      FrameSetScript(HRF.HolyRuneBoxFrame, false)
    end

    -- Set the new script for normal mode.
    FrameSetScript(Border, Enable)
  end
end

-------------------------------------------------------------------------------
-- EnableScreenClampHoly (EnableScreenClamp) [UnitBar assigned function]
--
-- Enables or disble screen clamp for the holy bar.
-------------------------------------------------------------------------------
function GUB.HolyBar:EnableScreenClampHoly(Enable)
  self.Border:SetClampedToScreen(Enable)
end

-------------------------------------------------------------------------------
-- SetAttrHoly  (SetAttr) [UnitBar assigned function]
--
-- Sets different parts of the holybar.
--
-- Usage: SetAttrHoly(Object, Attr)
--
-- Object       Object being changed:
--               'bg' for background (Border).
--               'bar' for forground (StatusBar).
--               'frame' for the frame.
-- Attr         Type of attribute being applied to object:
--               'color'     Color being set to the object.
--               'backdrop'  Backdrop settings being set to the object.
--               'scale'     Scale settings being set to the object.
--               'size'      Size being set to the object.
--               'padding'   Amount of padding set to the object.
--               'texture'   One or more textures set to the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.HolyBar:SetAttrHoly(Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Border = self.Border

  -- Frame.
  if Object == nil or Object == 'frame' then
    if Attr == nil or Attr == 'scale' then
      self.ScaleFrame:SetScale(UB.Other.Scale)
    end
  end

  -- Check if we're in boxmode.
  if UB.General.BoxMode then
    local Bar = UB.Bar
    local Background = UB.Background
    local Padding = Bar.Padding

    -- Remove the border backdrop.
    Border:SetBackdrop(nil)

    for RuneIndex, HRF in ipairs(self.HolyRuneF) do

      -- Background (Border).
      if Object == nil or Object == 'bg' then
        local BgColor = nil

        -- Get all color if ColorAll is true.
        if Background.ColorAll then
          BgColor = Background.Color
        else
          BgColor = Background.Color[RuneIndex]
        end

        local HolyRuneBoxFrame = HRF.HolyRuneBoxFrame

        if Attr == nil or Attr == 'backdrop' then
          HolyRuneBoxFrame:SetBackdrop(Main:ConvertBackdrop(UB.Background.BackdropSettings))
          HolyRuneBoxFrame:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
        if Attr == nil or Attr == 'color' then
          HolyRuneBoxFrame:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
      end

      -- Forground (Statusbar).
      if Object == nil or Object == 'bar' then
        local HolyRuneBox = HRF.HolyRuneBox

        if Attr == nil or Attr == 'texture' then
          HolyRuneBox:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTexture))
          HolyRuneBox:GetStatusBarTexture():SetHorizTile(false)
          HolyRuneBox:GetStatusBarTexture():SetVertTile(false)
          HolyRuneBox:SetOrientation(Bar.FillDirection)
          HolyRuneBox:SetRotatesTexture(Bar.RotateTexture)
        end
        if Attr == nil or Attr == 'color' then
          local BarColor = nil

          -- Get all color if ColorAll is true.
          if Bar.ColorAll then
            BarColor = Bar.Color
          else
            BarColor = Bar.Color[RuneIndex]
          end
          HolyRuneBox:SetStatusBarColor(BarColor.r, BarColor.g, BarColor.b, BarColor.a)
        end
        if Attr == nil or Attr == 'padding' then
          HolyRuneBox:ClearAllPoints()
          HolyRuneBox:SetPoint('TOPLEFT', Padding.Left , Padding.Top)
          HolyRuneBox:SetPoint('BOTTOMRIGHT', Padding.Right, Padding.Bottom)
        end
        if Attr == nil or Attr == 'size' then
          HRF:SetWidth(Bar.BoxWidth)
          HRF:SetHeight(Bar.BoxHeight)
        end
      end
    end
  else

    -- Else we're in normal bar mode.

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
  end
end

-------------------------------------------------------------------------------
-- SetLayoutHoly (SetLayout) [UnitBar assigned function]
--
-- Set a holybar to a new layout
--
-- Usage: SetLayoutHoly()
-------------------------------------------------------------------------------
function GUB.HolyBar:SetLayoutHoly()

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = self.UnitBar.General

  local Anchor = self.Anchor

  local BoxMode = Gen.BoxMode
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

  local BoxWidth = UB.Bar.BoxWidth
  local BoxHeight = UB.Bar.BoxHeight

  if BoxMode then
    -- Get the offsets based on angle for boxmode.
    XOffset, YOffset = Main:AngleToOffset(BoxWidth + Padding, BoxHeight + Padding, Angle)
  end

  for RuneIndex, HRF in ipairs(self.HolyRuneF) do

    -- Set the duration of the fade out.
    HRF.FadeOutA:SetDuration(FadeOutTime)

    -- Check to see if we're in Boxmode
    if BoxMode then

      -- Hide the textures.
      HRF.HolyRune:Hide()
      HRF.HolyRuneDark:Hide()

      -- Show the holy rune boxes.
      HRF.HolyRuneBoxFrame:Show()
      HRF.HolyRuneBox:Show()

      -- Set the holy rune min/max values.
      local HolyRuneBox = HRF.HolyRuneBox
      HolyRuneBox:SetMinMaxValues(0, 1)
      HolyRuneBox:SetValue(1)

      -- Calculate the x and y location before setting the location if angle is > 180.
      if Angle > 180 and RuneIndex > 1 then
        x = x + XOffset
        y = y + YOffset
      end

      -- Set the location of the holy rune box.
      HRF:ClearAllPoints()
      HRF:SetPoint('TOPLEFT', x, y)
      HRF.HolyRuneBoxFrame:SetAllPoints(HRF)

      -- Calculate the border width
      if XOffset == 0 then
        BorderWidth = BoxWidth
      end
      if YOffset == 0 then
        BorderHeight = BoxHeight
      end
    else

    -----------------------------------
    -- Normal mode
    -----------------------------------
      local HolyRune = HRF.HolyRune
      local HolyRuneDarkFrame = HRF.HolyRuneDarkFrame
      local HolyRuneDark = HRF.HolyRuneDark

      -- Hide the holy rune box frame.
      HRF.HolyRuneBoxFrame:Hide()
      HRF.HolyRuneBox:Hide()

      -- Show the textures.
      HolyRune:Show()
      HolyRuneDark:Show()

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
      HolyRuneDarkFrame:SetWidth(Width)
      HolyRuneDarkFrame:SetHeight(Height)

      -- Center the holy rune.
      HolyRune:ClearAllPoints()
      HolyRune:SetPoint('CENTER', 0, 0)
      HolyRuneDark:ClearAllPoints()
      HolyRuneDark:SetPoint('CENTER', 0, 0)

      -- Set the scale of the holy texture.
      local ScaleX = Width * HolyScale
      local ScaleY = Height * HolyScale
      HolyRune:SetWidth(ScaleX)
      HolyRune:SetHeight(ScaleY)
      HolyRuneDark:SetWidth(ScaleX)
      HolyRuneDark:SetHeight(ScaleY)

      -- Get the offsets based on angle.
      XOffset, YOffset = Main:AngleToOffset(Width + Padding, Height + Padding, Angle)

      -- Calculate the x and y location before setting the location if angle is > 180.
      if Angle > 180 and RuneIndex > 1 then
        x = x + XOffset
        y = y + YOffset
      end

      -- Set the location of the holy rune.
      HRF:ClearAllPoints()
      HRF:SetPoint('TOPLEFT', x, y)
      HolyRuneDarkFrame:SetAllPoints(HRF)

      -- Calculate the border width.
      if XOffset == 0 and BorderWidth < Width then
        BorderWidth = Width
      end

      -- Calculate the border height.
      if YOffset == 0 and BorderHeight < Height then
        BorderHeight = Height
      end
    end

    -- Calculate the border width for both types of holy rune bars.
    if XOffset ~= 0 then
      BorderWidth = BorderWidth + abs(XOffset)
      if RuneIndex == 1 then
        BorderWidth = BorderWidth - Padding
      end
    end

    -- Calculate the border height for both types of holy rune bars.
    if YOffset ~= 0 then
      BorderHeight = BorderHeight + abs(YOffset)
      if RuneIndex == 1 then
        BorderHeight = BorderHeight - Padding
      end
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

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Save size data to self (UnitBarF).
  self.Width = BorderWidth
  self.Height = BorderHeight
end

-------------------------------------------------------------------------------
-- CreateHolyBar
--
-- Usage: GUB.HolyBar:CreateHolyBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the holy rune bar.
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

  local ColorAllNames = {}
  local DarkColor = HolyRunes.DarkColor
  local HolyRuneF = {}

  for RuneIndex, HR in ipairs(HolyRunes) do

    -- Create the holy rune frame.
    local HolyRuneFrame = CreateFrame('Frame', nil, OffsetFrame)

    -- Create the holy rune texture.
    local HolyRune = HolyRuneFrame:CreateTexture(nil, 'OVERLAY')
    HolyRune:SetTexture(HolyPowerTexture)
    HolyRune:SetTexCoord(HR.Left, HR.Right, HR.Top, HR.Bottom)

    -- Create a dark holy rune icon frame.
    local HolyRuneDarkFrame = CreateFrame('Frame', nil, OffsetFrame)

    -- Create Dark holy rune texture.
    local HolyRuneDark = HolyRuneDarkFrame:CreateTexture(nil, 'ARTWORK')
    HolyRuneDark:SetTexture(HolyPowerTexture)
    HolyRuneDark:SetTexCoord(HR.Left, HR.Right, HR.Top, HR.Bottom)
    HolyRuneDark:SetDesaturated(true)
    HolyRuneDark:SetVertexColor(DarkColor.r, DarkColor.g, DarkColor.b, DarkColor.a)

    -- Create the holy rune box frame.
    local HolyRuneBoxFrame = CreateFrame('Frame', nil, OffsetFrame)

    -- Create a holy rune statusbar texture.
    local HolyRuneBox = CreateFrame('StatusBar', nil, HolyRuneFrame)

    -- Create an animation for fade out.
    local FadeOut = HolyRuneFrame:CreateAnimationGroup()
    local FadeOutA = FadeOut:CreateAnimation('Alpha')

    -- Set the animation group values.
    FadeOut:SetLooping('NONE')
    FadeOutA:SetChange(-1)
    FadeOutA:SetOrder(1)

    -- Set the holy rune to dark.
    HolyRuneFrame.Dark = true
    HolyRuneFrame:Hide()

    -- Save the animation.
    HolyRuneFrame.FadeOut = FadeOut
    HolyRuneFrame.FadeOutA = FadeOutA

    -- Save the holy runeicon and dark one.
    HolyRuneFrame.HolyRune = HolyRune
    HolyRuneFrame.HolyRuneDarkFrame = HolyRuneDarkFrame
    HolyRuneFrame.HolyRuneDark = HolyRuneDark
    HolyRuneFrame.HolyRuneBoxFrame = HolyRuneBoxFrame
    HolyRuneFrame.HolyRuneBox = HolyRuneBox

    -- Save a reference to the anchor for moving in box mode.
    HolyRuneBoxFrame.Anchor = Anchor

    -- Save the name for tooltips for box mode.
    local Name = strconcat('Holy Rune ', RuneIndex)
    HolyRuneBoxFrame.TooltipName = Name
    HolyRuneBoxFrame.TooltipDesc = MouseOverDesc
    ColorAllNames[RuneIndex] = Name

    HolyRuneF[RuneIndex] = HolyRuneFrame
  end

  -- Save the name for tooltips.
  Border.TooltipName = UB.Name
  Border.TooltipDesc = MouseOverDesc

  -- Save a reference to the anchor for moving.
  Border.Anchor = Anchor

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the offsetframe and Border and holyrunes.
  UnitBarF.Border = Border
  UnitBarF.OffsetFrame = OffsetFrame
  UnitBarF.HolyRuneF = HolyRuneF
end
