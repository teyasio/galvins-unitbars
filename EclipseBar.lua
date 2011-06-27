--
-- EclipseBar.lua
--
-- Displays the druid moonkin eclipse bar.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.EclipseBar = {}

-- shared from Main.lua
local LSM = GUB.UnitBars.LSM
local CheckPowerType = GUB.UnitBars.CheckPowerType
local CheckEvent = GUB.UnitBars.CheckEvent
local PowerTypeToNumber = GUB.UnitBars.PowerTypeToNumber
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
-- UnitBarF.UnitBar                  Reference to the unitbar data for the eclipse bar.
-- UnitBarF.Border                   Border frame for the eclipse bar. This is a parent of
-- UnitBarF.SunMoonBorder            Frame level border for sun and moon.
-- UnitBarF.SliderBorder             Frame level border for the slider.
-- UnitBarF.EclipseF                 Table containing the frames that make up the eclipse bar.
--
-- Border.Anchor                     Anchor reference for moving.
-- Border.TooltipName                Tooltip text to display for mouse over when bars are unlocked.
-- Border.TooltipDesc                Description under the name for mouse over.
--
-- EclipseF.Moon                     Table containing frame data for moon.
--   Frame                           Child of SunMoonBorder. Used to hide/show the moon.
--   Border                          Child of SunMoonBorder. Used to show a visible border for moon.
--   StatusBar                       Child of Moon.Frame.  Statusbar containing the visible texture.
--
-- EclipseF.Sun                      Table containing frame data for sun.
--   Frame                           Child of SunMoonBorder. Used to hide/show the sun.
--   Border                          Child of SunMoonBorder. Used to show a visible border for sun.
--   StatusBar                       Child of Sun.Frame.  Statusbar containing the visible texture.
--
-- EclipseF.Bar                      Table containing the frame for the bar.
--   Frame                           Child of Border. Used to hide/show the bar.
--   Border                          Child of Border. Used to show a visible border for the bar.
--   StatusBarLunar                  Child of Bar.Frame.  This texture fills the lunar side of the bar.
--   StatusBarSolar                  Child of Bar.Frame.  This texture fills the solar side of the bar.
--
-- EclipseF.Slider                   Table containing the frame data for the slider.
--   Frame                           Child of SliderBorder. Used to hide/show the slider.
--   Border                          Child of SliderBorder. Used to show a visible border for the slider.
--   StatusBar                       Child of Slider.Frame.  Statusbar containing the visible texture.
-- Txt                               Standard text data.
--
-- RotateBar                         Table containing data for the bar rotation.
-------------------------------------------------------------------------------

-- Powertype constants
local PowerEclipse = PowerTypeToNumber['ECLIPSE']

local SolarBuff = 48517;
local LunarBuff = 48518;
local LastDirection = nil

local RotateBar = {
  [90] = {  -- Left to right.
    Frame1 = 'Moon', Point1 = 'TOPLEFT',
    Frame2 = 'Bar',  Point2 = 'LEFT',     RelativePoint2 = 'RIGHT',
    Frame3 = 'Sun',  Point3 = 'LEFT',     RelativePoint3 = 'RIGHT',
    LunarPoint1 = 'TOPLEFT',     LunarRelativePoint1 = 'TOPLEFT',     LunarPadding1X = 1, LunarPadding1Y = 1,
    LunarPoint2 = 'BOTTOMRIGHT', LunarRelativePoint2 = 'BOTTOM',      LunarPadding2X = 0, LunarPadding2Y = 1,
    SolarPoint1 = 'TOPLEFT',     SolarRelativePoint1 = 'TOP',         SolarPadding1X = 0, SolarPadding1Y = 1,
    SolarPoint2 = 'BOTTOMRIGHT', SolarRelativePoint2 = 'BOTTOMRIGHT', SolarPadding2X = 1, SolarPadding2Y = 1
  },
  [180] = { -- Top to bottom.
    Frame1 = 'Moon', Point1 = 'TOPLEFT',
    Frame2 = 'Bar',  Point2 = 'TOP',      RelativePoint2 = 'BOTTOM',
    Frame3 = 'Sun',  Point3 = 'TOP',      RelativePoint3 = 'BOTTOM',
    LunarPoint1 = 'TOPLEFT',     LunarRelativePoint1 = 'TOPLEFT',     LunarPadding1X = 1, LunarPadding1Y = 1,
    LunarPoint2 = 'BOTTOMRIGHT', LunarRelativePoint2 = 'RIGHT',       LunarPadding2X = 1, LunarPadding2Y = 0,
    SolarPoint1 = 'TOPLEFT',     SolarRelativePoint1 = 'LEFT',        SolarPadding1X = 1, SolarPadding1Y = 0,
    SolarPoint2 = 'BOTTOMRIGHT', SolarRelativePoint2 = 'BOTTOMRIGHT', SolarPadding2X = 1, SolarPadding2Y = 1,
  },
  [270] = { -- Right to left.
    Frame1 = 'Sun',  Point1 = 'TOPLEFT',
    Frame2 = 'Bar',  Point2 = 'LEFT',     RelativePoint2 = 'RIGHT',
    Frame3 = 'Moon', Point3 = 'LEFT',     RelativePoint3 = 'RIGHT',
    LunarPoint1 = 'TOPLEFT',     LunarRelativePoint1 = 'TOP',         LunarPadding1X = 0, LunarPadding1Y = 1,
    LunarPoint2 = 'BOTTOMRIGHT', LunarRelativePoint2 = 'BOTTOMRIGHT', LunarPadding2X = 1, LunarPadding2Y = 1,
    SolarPoint1 = 'TOPLEFT',     SolarRelativePoint1 = 'TOPLEFT',     SolarPadding1X = 1, SolarPadding1Y = 1,
    SolarPoint2 = 'BOTTOMRIGHT', SolarRelativePoint2 = 'BOTTOM',      SolarPadding2X = 0, SolarPadding2Y = 1,
  },
  [360] = { -- Bottom to top.
    Frame1 = 'Sun',  Point1 = 'TOPLEFT',
    Frame2 = 'Bar',  Point2 = 'TOP',      RelativePoint2 = 'BOTTOM',
    Frame3 = 'Moon', Point3 = 'TOP',      RelativePoint3 = 'BOTTOM',
    LunarPoint1 = 'TOPLEFT',     LunarRelativePoint1 = 'LEFT',        LunarPadding1X = 1, LunarPadding1Y = 0,
    LunarPoint2 = 'BOTTOMRIGHT', LunarRelativePoint2 = 'BOTTOMRIGHT', LunarPadding2X = 1, LunarPadding2Y = 1,
    SolarPoint1 = 'TOPLEFT',     SolarRelativePoint1 = 'TOPLEFT',     SolarPadding1X = 1, SolarPadding1Y = 1,
    SolarPoint2 = 'BOTTOMRIGHT', SolarRelativePoint2 = 'RIGHT',       SolarPadding2X = 1, SolarPadding2Y = 0,
  },
}

--*****************************************************************************
--
-- Eclipsebar utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- CheckSolarLunar
--
-- Checks for the solar or lunar buffs
--
-- Usage Solar, Lunar = CheckSolarLunar()
--
-- Solar           If true then Unit has the solar buff.
-- Lunar           If true then the Unit has the lunar buff.
-------------------------------------------------------------------------------
local function CheckSolarLunar()
  local Name = nil
  local SpellID = 0
  local Solar = false
  local Lunar = false
  local i = 1
  repeat
    Name, _, _, _, _, _, _, _, _, _, SpellID = UnitBuff('player', i)
    if Name then
      if SpellID == SolarBuff then
        Solar = true
      elseif SpellID == LunarBuff then
        Lunar = true
      end
    end
    i = i + 1
  until Name == nil
  return Solar, Lunar
end

--*****************************************************************************
--
-- Eclipsebar script functions (script/event)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EclipseBarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar parent frame will be moved.
-- Otherwise just the eclipsebar will be moved.
-------------------------------------------------------------------------------
local function EclipseBarStartMoving(self, Button)

  -- Call the base moving function for group or anchor movement.
  if GUB.UnitBars.UnitBarStartMoving(self.Anchor, Button) then
    self.UnitBarMoving = true
  end
end

-------------------------------------------------------------------------------
-- EclipseBarStopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
-------------------------------------------------------------------------------
local function EclipseBarStopMoving(self, Button)

  -- Call the stop moving base function if there was a group move or anchor move.
  if self.UnitBarMoving then
    self.UnitBarMoving = false
    GUB.UnitBars.UnitBarStopMoving(self.Anchor, Button)
  end
end

--*****************************************************************************
--
-- Eclipsebar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateEclipseBar (Update) [UnitBar assigned function]
--
-- Update the eclipse bar energy, sun, and moon.
--
-- usage: UpdateEclipseBar(Event, ...)
--
-- Event                If nil no event check will be done.
-- ...                  Event data depending on one of three events passed.
-------------------------------------------------------------------------------
function GUB.EclipseBar:UpdateEclipseBar(Event, ...)

  -- Do nothing if the event is not an eclipse event.
  if Event ~= nil or not self.Enabled then
    local EventType = CheckEvent[Event]
    if not self.Enabled or EventType ~= 'power' and EventType ~= 'eclipsedirection' and EventType ~= 'aura' then
      return
    end
    if EventType ~= 'eclipsedirection' and select(1, ...) ~= 'player' or
       EventType == 'power' and CheckPowerType[select(2, ...)] ~= 'eclipse' then
      return
    end
  end

  -- Get frame data.
  local UB = self.UnitBar
  local Background = UB.Background
  local Bar = UB.Bar
  local Gen = UB.General
  local EF = self.EclipseF
  local SliderDirection = Gen.SliderDirection
  local EclipseAngle = Gen.EclipseAngle
  local SunFrame = EF.Sun.Frame
  local MoonFrame = EF.Moon.Frame
  local StatusBarLunar = EF.Bar.StatusBarLunar
  local StatusBarSolar = EF.Bar.StatusBarSolar
  local SliderF = EF.Slider

  -- Get eclipse data from server.
  local Direction = GetEclipseDirection()
  local EclipsePower = UnitPower('player', PowerEclipse)
  local EclipseMaxPower = UnitPowerMax('player', PowerEclipse)
  local Solar, Lunar = CheckSolarLunar()

  -- Display the eclipse power
  if UB.General.Text then
    EF.Txt:SetText(abs(EclipsePower))
  else
    EF.Txt:SetText('')
  end

  -- Update slider position.
  local SliderPos = EclipsePower / EclipseMaxPower
  local BdSize = Background.Bar.BackdropSettings.BdSize / 2
  local BarSize = 0
  local SliderSize = 0

  -- Get slider direction.
  if SliderDirection == 'VERTICAL' then
    BarSize = Bar.Bar.BarHeight
    SliderSize = Bar.Slider.SliderHeight
  else
    BarSize = Bar.Bar.BarWidth
    SliderSize = Bar.Slider.SliderWidth
  end

  -- Calc rotate direction
  if EclipseAngle == 180 or EclipseAngle == 270 then
    SliderPos = SliderPos * -1
  end

  -- Check the SliderInside option
  if Gen.SliderInside then
    SliderPos = SliderPos * ((BarSize - BdSize - SliderSize) / 2)
  else
    SliderPos = SliderPos * (BarSize - BdSize) / 2
  end

  if SliderDirection == 'VERTICAL' then
    SliderF.Frame:SetPoint('CENTER', EF.Bar.Frame, 'CENTER', 0, SliderPos)
  else
    SliderF.Frame:SetPoint('CENTER', EF.Bar.Frame, 'CENTER', SliderPos, 0)
  end

  -- Set slider color.
  local SliderColor = Bar.Slider.Color

  -- Check for sun/moon color option.
  if Bar.Slider.SunMoon then
    if Direction == 'sun' then
      SliderColor = Bar.Sun.Color
    elseif Direction == 'moon' then
      SliderColor = Bar.Moon.Color
    end
  end
  SliderF.StatusBar:SetStatusBarColor(SliderColor.r, SliderColor.g, SliderColor.b, SliderColor.a)

  -- Check the HalfLit option.
  if Gen.BarHalfLit then
    if Direction == 'sun' then
      StatusBarLunar:Hide()
      StatusBarSolar:Show()
    elseif Direction == 'moon' then
      StatusBarLunar:Show()
      StatusBarSolar:Hide()
    else
      StatusBarLunar:Show()
      StatusBarSolar:Show()
    end
  else
    StatusBarLunar:Show()
    StatusBarSolar:Show()
  end

  -- Hide/show sun and moon
  if Solar then
    SunFrame:Show()
  else
    SunFrame:Hide()
  end
  if Lunar then
    MoonFrame:Show()
  else
    MoonFrame:Hide()
  end
end

-------------------------------------------------------------------------------
-- CancelAnimationEclipse (CancelAnimation) [UnitBar assigned function]
-------------------------------------------------------------------------------

--*****************************************************************************
--
-- Eclipsebar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicksEclipse (EnableMouseClicks) [UnitBar assigned function]
--
-- This will enable or disbable mouse clicks for the eclipse bar.
-------------------------------------------------------------------------------
function GUB.EclipseBar:EnableMouseClicksEclipse(Enable)
  self.Border:EnableMouse(Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScriptEclipse (FrameSetScript) [UnitBar assigned function]
--
-- Set up script handlers for the eclipsebar.
-------------------------------------------------------------------------------
function GUB.EclipseBar:FrameSetScriptEclipse(Enable)
  local Border = self.Border
  if Enable then
    Border:SetScript('OnMouseDown', EclipseBarStartMoving)
    Border:SetScript('OnMouseUp', EclipseBarStopMoving)
    Border:SetScript('OnHide', function(self)
                                 EclipseBarStopMoving(self)
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
-- EnableScreenClampEclipse (EnableScreenEclipse) [UnitBar assigned function]
--
-- Enables or disble screen clamp for the eclipse bar.
-------------------------------------------------------------------------------
function GUB.EclipseBar:EnableScreenClampEclipse(Enable)
  self.Border:SetClampedToScreen(Enable)
end

-------------------------------------------------------------------------------
-- SetAttrEclipse  (SetAttr) [UnitBar assigned function]
--
-- Sets different parts of the eclipsebar.
--
-- Usage: SetAttrEclipse(Object, Attr, Eclipse)
--
-- Object       Object being changed:
--               'bg'        for background (Border).
--               'bar'       for forground (StatusBar).
--               'frame'     for the frame.
-- Attr         Type of attribute being applied to object:
--               'color'     Color being set to the object.
--               'backdrop'  Backdrop settings being set to the object.
--               'scale'     Scale settings being set to the object.
--               'size'      Size being set to the object.
--               'padding'   Amount of padding set to the object.
--               'texture'   One or more textures set to the object.
-- Eclipse      Which part of the eclispe bar being changed
--               'moon'      Apply changes to the moon.
--               'sun'       Apply changes to the sun.
--               'bar'       Apply changes to the bar.
--               'slider'    Apply changes to the slider.
--              if Eclipse is nil then only frame scale can be changed.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.EclipseBar:SetAttrEclipse(Object, Attr, Eclipse)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local EclipseF = self.EclipseF

  -- Frame.
  if Object == nil or Object == 'frame' then
    if Attr == nil or Attr == 'scale' then
      self.ScaleFrame:SetScale(UB.Other.Scale)
    end
  end

  -- Text (StatusBar.Txt).
  if Object == nil or Object == 'text' then
    local Txt = EclipseF.Txt

    local TextColor = UB.Text.Color

    if Attr == nil or Attr == 'font' then
      GUB.UnitBars:SetFontString(Txt, UB.Text.FontSettings)
    end
    if Attr == nil or Attr == 'color' then
      Txt:SetTextColor(TextColor.r, TextColor.g, TextColor.b, TextColor.a)
    end
  end

  -- if Eclipse is nil then return.
  if not Eclipse then
    return
  end

  -- Uppercase the first character.
  Eclipse = ('%s%s'):format(strupper(strsub(Eclipse, 1, 1)), strsub(Eclipse, 2))

  -- Get bar data.
  local Background = UB.Background[Eclipse]
  local Bar = UB.Bar[Eclipse]
  local UBF = EclipseF[Eclipse]

  -- Background (Border).
  if Object == nil or Object == 'bg' then
    local Border = UBF.Border
    local BgColor = Background.Color

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
    local StatusBar = UBF.StatusBar
    local StatusBarLunar = UBF.StatusBarLunar
    local StatusBarSolar = UBF.StatusBarSolar
    local Frame = UBF.Frame

    local Padding = Bar.Padding
    local BarColor = Bar.Color
    local BarColorLunar = Bar.ColorLunar
    local BarColorSolar = Bar.ColorSolar

    if Attr == nil or Attr == 'texture' then
      if Eclipse ~= 'Bar' then
        StatusBar:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTexture))
        StatusBar:GetStatusBarTexture():SetHorizTile(false)
        StatusBar:GetStatusBarTexture():SetVertTile(false)
        StatusBar:SetOrientation(Bar.FillDirection)
        StatusBar:SetRotatesTexture(Bar.RotateTexture)
      else
        StatusBarLunar:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTextureLunar))
        StatusBarSolar:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTextureSolar))
        StatusBarLunar:GetStatusBarTexture():SetHorizTile(false)
        StatusBarLunar:GetStatusBarTexture():SetVertTile(false)
        StatusBarLunar:SetOrientation(Bar.FillDirection)
        StatusBarLunar:SetRotatesTexture(Bar.RotateTexture)
        StatusBarSolar:GetStatusBarTexture():SetHorizTile(false)
        StatusBarSolar:GetStatusBarTexture():SetVertTile(false)
        StatusBarSolar:SetOrientation(Bar.FillDirection)
        StatusBarSolar:SetRotatesTexture(Bar.RotateTexture)
      end
    end

    if Attr == nil or Attr == 'color' then
      if Eclipse ~= 'Bar' then
        StatusBar:SetStatusBarColor(BarColor.r, BarColor.g, BarColor.b, BarColor.a)
      else
        StatusBarLunar:SetStatusBarColor(BarColorLunar.r, BarColorLunar.g, BarColorLunar.b, BarColorLunar.a)
        StatusBarSolar:SetStatusBarColor(BarColorSolar.r, BarColorSolar.g, BarColorSolar.b, BarColorSolar.a)
      end
    end

    if Attr == nil or Attr == 'padding' then
      if Eclipse ~= 'Bar' then
        StatusBar:ClearAllPoints()
        StatusBar:SetPoint('TOPLEFT', Padding.Left , Padding.Top)
        StatusBar:SetPoint('BOTTOMRIGHT', Padding.Right, Padding.Bottom)
      else
        local RB = RotateBar[UB.General.EclipseAngle]

        StatusBarLunar:ClearAllPoints()
        StatusBarLunar:SetPoint(RB.LunarPoint1, Frame, RB.LunarRelativePoint1,
                                Padding.Left * RB.LunarPadding1X, Padding.Top * RB.LunarPadding1Y)
        StatusBarLunar:SetPoint(RB.LunarPoint2, Frame, RB.LunarRelativePoint2,
                                Padding.Right * RB.LunarPadding2X, Padding.Bottom * RB.LunarPadding2Y)
        StatusBarSolar:ClearAllPoints()
        StatusBarSolar:SetPoint(RB.SolarPoint1, Frame, RB.SolarRelativePoint1,
                                Padding.Left * RB.SolarPadding1X, Padding.Top * RB.SolarPadding1Y)
        StatusBarSolar:SetPoint(RB.SolarPoint2, Frame, RB.SolarRelativePoint2,
                                Padding.Right * RB.SolarPadding2X, Padding.Bottom * RB.SolarPadding2Y)
      end
    end

    if Attr == nil or Attr == 'size' then
      Frame:SetWidth(Bar[('%sWidth'):format(Eclipse)])
      Frame:SetHeight(Bar[('%sHeight'):format(Eclipse)])
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayoutEclipse (SetLayout) [UnitBar assigned function]
--
-- Set an eclipsebar to a new layout
--
-- Usage: SetLayoutEclipse()
-------------------------------------------------------------------------------
function GUB.EclipseBar:SetLayoutEclipse()

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Bar = UB.Bar
  local Gen = UB.General

  local EclipseAngle = Gen.EclipseAngle
  local SunOffsetX = Gen.SunOffsetX
  local SunOffsetY = Gen.SunOffsetY
  local MoonOffsetX = Gen.MoonOffsetX
  local MoonOffsetY = Gen.MoonOffsetY
  local SunWidth = Bar.Sun.SunWidth
  local SunHeight = Bar.Sun.SunHeight
  local MoonWidth = Bar.Moon.MoonWidth
  local MoonHeight = Bar.Moon.MoonHeight
  local BarWidth = Bar.Bar.BarWidth
  local BarHeight = Bar.Bar.BarHeight
  local SliderWidth = Bar.Slider.SliderWidth
  local SliderHeight = Bar.Slider.SliderHeight
  local EF = self.EclipseF
  local SliderFrame = EF.Slider.Frame

  local SunX, SunY = 0, 0
  local MoonX, MoonY = 0, 0
  local BarX, BarY = 0, 0
  local SliderX, SliderY = 0, 0
  local x,y = 0, 0
  local x1,y1 = 0, 0
  local OffsetFX = 0
  local OffsetFY = 0
  local BorderWidth = 0
  local BorderHeight = 0

  -- Set angle to 90 if it's invalid.
  if RotateBar[EclipseAngle] == nil then
    EclipseAngle = 90
    UB.General.EclipseAngle = 90
  end

  -- Get rotate data.
  local RB = RotateBar[EclipseAngle]

  -- Set sun or moon.
  local TableName = RB.Frame1
  local F = EF[TableName]
  local Frame1 = F.Frame
  local MoonX = 0
  local MoonY = 0
  Frame1:ClearAllPoints()
  Frame1:SetPoint(RB.Point1, 0, 0)
  F.Border:SetAllPoints(Frame1)

  -- Set the bar.
  F = EF[RB.Frame2]
  local Frame2 = F.Frame

  -- Calculate the upper left for the bar.
  if TableName == 'Moon' then
    x, y = GUB.UnitBars:CalcSetPoint(RB.RelativePoint2, MoonWidth, MoonHeight, MoonOffsetX, MoonOffsetY)
  else
    x, y = GUB.UnitBars:CalcSetPoint(RB.RelativePoint2, SunWidth, SunHeight, SunOffsetX, SunOffsetY)
  end
  x1, y1 = GUB.UnitBars:CalcSetPoint(RB.Point2, BarWidth, BarHeight, 0, 0)

  BarX = x - x1
  BarY = y - y1
  Frame2:ClearAllPoints()
  Frame2:SetPoint('TOPLEFT', BarX, BarY)
  F.Border:SetAllPoints(Frame2)

  -- Set the sun or moon.
  TableName = RB.Frame3
  F = EF[RB.Frame3]
  local Frame3 = F.Frame

  -- Caculate the upper left for sun or moon.
  Frame3:ClearAllPoints()
  x, y = GUB.UnitBars:CalcSetPoint(RB.RelativePoint3, BarWidth, BarHeight, BarX, BarY)
  if TableName == 'Moon' then
    x1, y1 = GUB.UnitBars:CalcSetPoint(RB.Point3, MoonWidth, MoonHeight, MoonOffsetX, MoonOffsetY)
    MoonX = x - x1
    MoonY = y - y1
    Frame3:SetPoint('TOPLEFT', MoonX, MoonY)
  else
    x1, y1 = GUB.UnitBars:CalcSetPoint(RB.Point3, SunWidth, SunHeight, SunOffsetX, SunOffsetY)
    SunX = x - x1
    SunY = y - y1
    Frame3:SetPoint('TOPLEFT', SunX, SunY)
  end
  F.Border:SetAllPoints(Frame3)

  -- Set up the slider.
  SliderFrame:ClearAllPoints()
  EF.Slider.Border:SetAllPoints(SliderFrame)

  -- Calculate upper left of slider for border calculation.
  SliderX, SliderY = GUB.UnitBars:CalcSetPoint('CENTER', BarWidth, BarHeight, -(SliderWidth / 2), SliderHeight / 2)
  SliderX = BarX + SliderX
  SliderY = BarY + SliderY

  -- Set the size of the border.
  local Border = self.Border
  Border:ClearAllPoints()
  Border:SetPoint('TOPLEFT', 0, 0)

  -- Calculate the offsets for the offsetframe, get the borderwidth and borderheight
  x, y, BorderWidth, BorderHeight = GUB.UnitBars:GetBorder(SunX, SunY, SunWidth, SunHeight,
                                                                MoonX, MoonY, MoonWidth, MoonHeight,
                                                                BarX, BarY, BarWidth, BarHeight,
                                                                SliderX, SliderY, SliderWidth, SliderHeight)
  OffsetFX = -x
  OffsetFY = -y

  Border:SetWidth(BorderWidth)
  Border:SetHeight(BorderHeight)

  -- Set the x, y location off the offset frame.
  local OffsetFrame = self.OffsetFrame
  OffsetFrame:ClearAllPoints()
  OffsetFrame:SetPoint('LEFT', OffsetFX, OffsetFY)
  OffsetFrame:SetWidth(BorderWidth)
  OffsetFrame:SetHeight(BorderHeight)

  -- Set all attributes.
  self:SetAttr(nil, nil, 'moon')
  self:SetAttr(nil, nil, 'bar')
  self:SetAttr(nil, nil, 'sun')
  self:SetAttr(nil, nil, 'slider')

  -- Save size data to self (UnitBarF).
  self.Width = BorderWidth
  self.Height = BorderHeight
end

-------------------------------------------------------------------------------
-- CreateEclipseBar
--
-- Usage: GUB.EclipseBar:CreateEclipseBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the eclipse bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.EclipseBar:CreateEclipseBar(UnitBarF, UB, Anchor, ScaleFrame)

  local Border = CreateFrame('Frame', nil, ScaleFrame)

  -- Create the offset frame.
  local OffsetFrame = CreateFrame('Frame', nil, Border)

  -- Create a BorderFrame for Sun and moon for frame level
  local SunMoonBorder = CreateFrame('Frame', nil, OffsetFrame)
  SunMoonBorder:SetAllPoints(OffsetFrame)
  SunMoonBorder:SetFrameLevel(SunMoonBorder:GetFrameLevel() + 10)

  -- Create a borderframe for slider frame level
  local SliderBorder = CreateFrame('Frame', nil, SunMoonBorder)
  SliderBorder:SetAllPoints(OffsetFrame)
  SliderBorder:SetFrameLevel(SliderBorder:GetFrameLevel() + 20)

  -- Create the text frame.
  local TxtBorder = CreateFrame('Frame', nil, Border)
  TxtBorder:SetAllPoints(Border)
  TxtBorder:SetFrameLevel(TxtBorder:GetFrameLevel() + 40)
  local Txt = TxtBorder:CreateFontString(nil, 'OVERLAY')

  -- MOON
  -- Make the border frame top when clicked.
  Border:SetToplevel(true)

  -- Create the moon frame.  This is used for hide/show
  local MoonFrame = CreateFrame('Frame', nil, SunMoonBorder)

  -- Set the moon to dark.
  MoonFrame:Hide()

  -- Create the visible border for the moon.
  local MoonBorder = CreateFrame('Frame', nil, SunMoonBorder)

  -- Create the statusbar for the moon.
  local Moon = CreateFrame('StatusBar', nil, MoonFrame)

  -- SUN
  -- Create the sun frame.  This is used for hide/show
  local SunFrame = CreateFrame('Frame', nil, SunMoonBorder)

  -- Set the sun to dark
  SunFrame:Hide()

  -- Create the visible border for the sun.
  local SunBorder = CreateFrame('Frame', nil, SunMoonBorder)

  -- Create the statusbar for the sun.
  local Sun = CreateFrame('StatusBar', nil, SunFrame)

  -- BAR
  -- Create the eclipse bar for the slider.
  local BarFrame = CreateFrame('Frame', nil, OffsetFrame)

  -- Create the visible border for eclipse bar.
  local BarBorder = CreateFrame('Frame', nil, OffsetFrame)

  -- Create the left and right statusbars for the bar.
  local BarLunar = CreateFrame('StatusBar', nil, BarFrame)
  local BarSolar = CreateFrame('StatusBar', nil, BarFrame)

  -- SLIDER
  -- Create the slider frame.
  local SliderFrame = CreateFrame('Frame', nil, SliderBorder)

  -- Create the slider border.
  local SliderBorder = CreateFrame('Frame', nil, SliderBorder)

  -- Create the statusbar for slider.
  local Slider = CreateFrame('StatusBar', nil, SliderFrame)

  local EclipseFrame = {Moon = {}, Sun = {}, Bar = {}, Slider = {}}
  EclipseFrame.Moon.Frame = MoonFrame
  EclipseFrame.Moon.Border = MoonBorder
  EclipseFrame.Moon.StatusBar = Moon
  EclipseFrame.Sun.Frame = SunFrame
  EclipseFrame.Sun.Border = SunBorder
  EclipseFrame.Sun.StatusBar = Sun
  EclipseFrame.Bar.Frame = BarFrame
  EclipseFrame.Bar.Border = BarBorder
  EclipseFrame.Bar.StatusBarLunar = BarLunar
  EclipseFrame.Bar.StatusBarSolar = BarSolar
  EclipseFrame.Slider.Frame = SliderFrame
  EclipseFrame.Slider.Border = SliderBorder
  EclipseFrame.Slider.StatusBar = Slider
  EclipseFrame.Txt = Txt

  -- Save the name for tooltips.
  Border.TooltipName = UB.Name
  Border.TooltipDesc = MouseOverDesc

  -- Save a reference to the anchor for moving.
  Border.Anchor = Anchor

  -- Save the borders and Eclipse frames
  UnitBarF.Border = Border
  UnitBarF.SunMoonBorder = SunMoonBorder
  UnitBarF.SliderBorder = SliderBorder
  UnitBarF.TxtBorder = TxtBorder
  UnitBarF.OffsetFrame = OffsetFrame
  UnitBarF.EclipseF = EclipseFrame
end
