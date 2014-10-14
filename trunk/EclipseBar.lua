--
-- EclipseBar.lua
--
-- Displays the druid moonkin eclipse bar.
--
-- Predicted power:
--
-- Predicted power is calculated by taking the current spell being cast.  And figuring out what
-- the state of the eclipse bar will be in after that spell is finished.
-- The predicted power accounts for Soul of the Forest and Celestial Alignment.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local TT = GUB.DefaultUB.TriggerTypes

local UnitBarsF = Main.UnitBarsF
local LSM = Main.LSM
local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring =
      strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList
local UnitName, UnitReaction, UnitGetIncomingHeals, GetRealmName, UnitCanAttack, UnitPlayerControlled, UnitIsPVP =
      UnitName, UnitReaction, UnitGetIncomingHeals, GetRealmName, UnitCanAttack, UnitPlayerControlled, UnitIsPVP
local GetRuneCooldown, GetRuneType, GetSpellInfo, PlaySound, message =
      GetRuneCooldown, GetRuneType, GetSpellInfo, PlaySound, message
local GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, UIParent =
      C_PetBattles, UIParent

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the eclipse bar displayed on screen.
--
-- BoxMode                           TextureFrame number for boxmode.  Currently no texturemode.
-- MoonBox                           BoxFrame number for moon texture.
-- PowerBox                          BoxFrame number for solar, lunar, slider, and indicator textures.
-- SunBox                            BoxFrame number for sun texture.
-- MoonSBar                          Texture number for moon texture.
-- LunarSBar                         Texture number for lunar texture.
-- SolarSBar                         Texture number for solar texture.
-- SunSBar                           Texture number for sun texture.
-- SliderSBar                        Texture number for slider texture.
--
-- SolarPeakAura                     SpellID for the solar peak aura.
-- LunarPeakAura                     SpellID for the lunar peak aura.
--
-- TriggerGroups                     Table containing data needed to do DoTriggers() and create the trigger groups.
-- DoTriggers                        True by passes visible and isactive flags. If not nil then calls
--                                   self:Update(DoTriggers)
-------------------------------------------------------------------------------
local Display = false
local DoTriggers = false

-- Powertype constants
local PowerEclipse = ConvertPowerType['ECLIPSE']

local BoxMode = 1
local MoonBox = 1
local PowerBox = 2
local SunBox = 3
local MoonSBar = 20
local SunSBar = 21
local LunarSBar = 30
local SolarSBar = 31
local SliderSBar = 40

local LunarPeakAura = 171743
local SolarPeakAura = 171744

local TGBoxNumber = 1
local TGTpar = 2
local TGName = 3
local TGValueTypes = 4
local VTs = {'whole:Lunar Energy', 'whole:Solar Energy', 'boolean:Lunar Peak', 'boolean:Solar Peak', 'auras:Auras'}
local TriggerGroups = { -- BoxNumber, TPar, Name, ValueTypes,
  {MoonBox,  MoonSBar,      'Moon',      VTs}, -- 1
  {SunBox,   SunSBar,       'Sun',       VTs}, -- 2
  {PowerBox, 0,             'Power',     VTs}, -- 3
  {PowerBox, SliderSBar,    'Slider',    VTs}, -- 4
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.EclipseBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Eclipsebar utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- GetEclipsePowerType
--
-- Returns -1 for lunar or 1 for solar or 0 for nuetral.
--
-- Power          Eclipse Power
-- Direction      Direction the power is moving in.
--
-- Returns:
--   EclipsePowerType      -1 = lunar, 1 = solar, 0 = neutral
-------------------------------------------------------------------------------
local function GetEclipsePowerType(Power, Direction)
  if Power < 0 then
    return -1
  elseif Power > 0 then
    return 1
  elseif Direction == 'moon' then
    return -1
  elseif Direction == 'sun' then
    return 1
  else
    return 0
  end
end


--*****************************************************************************
--
-- Eclipsebar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- DisplayEclipseSlider
--
-- Subfunction of Update()
--
-- Displays a slider on the eclipse bar.
--
-- UB           Unitbar data that is needed to display the slider.
-- BBar         Current Eclipsebar created by Bar:CreateBar()
-- Slider       Name of the slider table name.
-- Power        Current eclipse power
-- MaxPower     Maximum eclipse power
-- Direction    'sun' or 'moon'
-- PowerType    -1 = 'lunar', 1 = 'solar', 0 = neutral
-------------------------------------------------------------------------------
local function DisplayEclipseSlider(UB, BBar, KeyName, Power, MaxPower, Direction, PowerType)

  -- Get frame data.
  local Gen = UB.General
  local SliderDirection = Gen.SliderDirection
  local EclipseRotation = UB.Layout.Rotation
  local BackgroundSlider = UB[format('Background%s', KeyName)]
  local BarSlider = UB[format('Bar%s', KeyName)]
  local BarPower = UB.BarPower
  local BackgroundPower = UB.BackgroundPower
  local Slider = nil

  if KeyName == 'Slider' then
    Slider = SliderSBar
--  else
--    Slider = IndicatorSBar
  end

  -- Clip eclipsepower if out of range.
  if abs(Power) > MaxPower then
    Power = Power * PowerType
  end

  -- Check for devision by zero.  Only happens when bar is displayed by a class/spec that can't use the bar.
  local SliderPos = 0
  if MaxPower > 0 then
    SliderPos = Power / MaxPower
  end
  local BorderSize = BackgroundPower.BorderSize / 2
  local BarSize = 0
  local SliderSize = 0

  -- Get slider direction.
  if SliderDirection == 'VERTICAL' then
    BarSize = BarPower.Height
    SliderSize = BarSlider.Height
  else
    BarSize = BarPower.Width
    SliderSize = BarSlider.Width
  end

  -- Check the SliderInside option.  Need to divide by 2 since we have negative to positive coordinates.
  if Gen.SliderInside then
    SliderPos = SliderPos * ((BarSize - BorderSize - SliderSize) / 2)
  else
    SliderPos = SliderPos * (BarSize - BorderSize) / 2
  end

  if SliderDirection == 'VERTICAL' then
    BBar:SetPointTexture(PowerBox, Slider, 'CENTER', 0, SliderPos)
  else
    BBar:SetPointTexture(PowerBox, Slider, 'CENTER', SliderPos, 0)
  end

  -- Set slider color.
  local BarSliderColor = BarSlider.Color

  -- Check for sun/moon color option.
  if BarSlider.SunMoon then
    if Direction == 'sun' then
      BarSliderColor = UB.BarSun.Color
    elseif Direction == 'moon' then
      BarSliderColor = UB.BarMoon.Color
    end
  end
  BBar:SetColorTexture(PowerBox, Slider, BarSliderColor.r, BarSliderColor.g, BarSliderColor.b, BarSliderColor.a)
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the eclipse bar power, sun, and moon.
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible flag.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EclipseBar:Update(Event, Unit, PowerType, ...)
  if Event ~= true and not self.Visible then
    return
  end
  local BBar = self.BBar

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerEclipse

  -- Return if not the correct powertype.
  if PowerType ~= PowerEclipse then
    return
  end

  local Testing = Main.UnitBars.Testing
  local UB = self.UnitBar
  local Gen = UB.General

  local EclipsePower = UnitPower('player', PowerEclipse)
  local EclipseMaxPower = UnitPowerMax('player', PowerEclipse)
  local SpellID = Main:CheckAura('o', SolarPeakAura, LunarPeakAura)
  local LunarPeak = SpellID == LunarPeakAura and true or false
  local SolarPeak = SpellID == SolarPeakAura and true or false
  local EclipseDirection = GetEclipseDirection()

  local EclipsePowerType = GetEclipsePowerType(EclipsePower, EclipseDirection)

  local IndicatorHideShow = Gen.IndicatorHideShow
  local FadeInTime = Gen.EclipseFadeInTime
  local FadeOutTime = Gen.EclipseFadeOutTime
  local PowerHalfLit = Gen.PowerHalfLit
  local HideSlider = Gen.HideSlider
  local HidePeak = Gen.HidePeak

  if Testing then
    local TestMode = UB.TestMode
    local TestEclipsePower = self.TestEclipsePower

    EclipseMaxPower = 100
    EclipsePower = floor(EclipseMaxPower * 2 * TestMode.Value) - abs(EclipseMaxPower)

    if EclipsePower ~= TestEclipsePower then
      if TestEclipsePower then
        if EclipsePower < TestEclipsePower then
          EclipseDirection = 'moon'
        else
          EclipseDirection = 'sun'
        end
      else
        EclipseDirection = 'none'
      end
      self.TestEclipsePower = EclipsePower
      self.TestEclipseDirection = EclipseDirection
    else
      EclipseDirection = self.TestEclipseDirection
    end
    EclipsePowerType = GetEclipsePowerType(EclipsePower, EclipseDirection)

    LunarPeak = EclipsePower == -EclipseMaxPower
    SolarPeak = EclipsePower == EclipseMaxPower
  end

  -- Check hide slider option.
  if not HideSlider then
    DisplayEclipseSlider(UB, BBar, 'Slider', EclipsePower, EclipseMaxPower, EclipseDirection, EclipsePowerType)
  end

  -- Display the eclipse power.
  if not UB.Layout.HideText then
    BBar:SetValueFont(PowerBox, nil, 'number', abs(EclipsePower))
  else
    BBar:SetValueRawFont(PowerBox, nil, '')
  end

  BBar:SetHiddenTexture(SunBox, SunSBar, HidePeak or not SolarPeak)
  BBar:SetHiddenTexture(MoonBox, MoonSBar, HidePeak or not LunarPeak)

  BBar:SetHiddenTexture(PowerBox, LunarSBar, PowerHalfLit and EclipseDirection == 'sun')
  BBar:SetHiddenTexture(PowerBox, SolarSBar, PowerHalfLit and EclipseDirection == 'moon')

  -- Triggers
  if UB.Layout.EnableTriggers then
    for Index = 1, #TriggerGroups do
      if EclipsePower <= 0 then
        BBar:SetTriggers(Index, 'off', 'solar energy')
        BBar:SetTriggers(Index, 'lunar energy', abs(EclipsePower))
      else
        BBar:SetTriggers(Index, 'off', 'lunar energy')
        BBar:SetTriggers(Index, 'solar energy', EclipsePower)
      end

      BBar:SetTriggers(Index, 'lunar peak', LunarPeak)
      BBar:SetTriggers(Index, 'solar peak', SolarPeak)
    end
    BBar:DoTriggers()
  end

  self.IsActive = true

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Eclipsebar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the eclipse bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EclipseBar:EnableMouseClicks(Enable)
  self.BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the eclipsebar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EclipseBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SetOptionData('BackgroundMoon', '', MoonBox, BoxMode)
    BBar:SetOptionData('BackgroundSun', '', SunBox, BoxMode)
    BBar:SetOptionData('BackgroundPower', '', PowerBox, BoxMode)
    BBar:SetOptionData('BackgroundSlider', 'Texture', PowerBox, SliderSBar)
    BBar:SetOptionData('BarMoon', MoonBox,  MoonSBar)
    BBar:SetOptionData('BarSun', SunBox, SunSBar)
    BBar:SetOptionData('BarPower', PowerBox)
    BBar:SetOptionData('BarSlider', PowerBox, SliderSBar)

    BBar:SO('Text', '_Font', function() BBar:UpdateFont(PowerBox) self:Update() end)
    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', '_UpdateTriggers', function(v)
      if v.EnableTriggers then
        DoTriggers = true
        Display = true
      end
    end)
    BBar:SO('Layout', 'EnableTriggers', function(v)
      if v then
        if not BBar:GroupsCreatedTriggers() then
          for GroupNumber = 1, #TriggerGroups do
            local TG = TriggerGroups[GroupNumber]
            local BoxNumber, Tpar, Name = TG[TGBoxNumber],  TG[TGTpar], TG[TGName]

            BBar:CreateGroupTriggers(GroupNumber, unpack(TG[TGValueTypes]))
            if Name == 'Moon' or Name == 'Sun' or Name == 'Power' then
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,         'SetBackdropBorder', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor,    'SetBackdropBorderColor', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,     'SetBackdrop', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,          'SetBackdropColor', BoxNumber, BoxMode)
            else
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,         'SetBackdropBorderTexture', BoxNumber, Tpar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor,    'SetBackdropBorderColorTexture', BoxNumber, Tpar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,     'SetBackdropTexture', BoxNumber, Tpar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,          'SetBackdropColorTexture', BoxNumber, Tpar)
            end

            -- Class Color
            BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor, TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
            BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,       TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)

            -- Power Color
            BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor, TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
            BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,       TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)

            -- Combat Color
            BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor, TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
            BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,       TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)

            -- Tagged Color
            BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor, TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
            BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,       TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)

            if Name == 'Power' then
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarTexture,            TT.Type_BarTexture .. ' (lunar)', 'SetTexture', BoxNumber, LunarSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarColor,              TT.Type_BarColor   .. ' (lunar)', 'SetColorTexture', BoxNumber, LunarSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarTexture,            TT.Type_BarTexture .. ' (solar)', 'SetTexture', BoxNumber, SolarSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarColor,              TT.Type_BarColor   .. ' (solar)', 'SetColorTexture', BoxNumber, SolarSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_Sound,                 TT.Type_Sound,                    'PlaySound', 1)

              -- Class Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (lunar)', TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor, TT.Type_ClassColor, Main.GetClassColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (solar)', TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor, TT.Type_ClassColor, Main.GetClassColor)

              -- Power Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (lunar)', TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor, TT.Type_PowerColor, Main.GetPowerColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (solar)', TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor, TT.Type_PowerColor, Main.GetPowerColor)

              -- Combat Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (lunar)', TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (solar)', TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)

              -- Tagged Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (lunar)', TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (solar)', TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)

            else
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarTexture,            TT.Type_BarTexture,               'SetTexture', BoxNumber, Tpar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarColor,              TT.Type_BarColor,                 'SetColorTexture', BoxNumber, Tpar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_Sound,                 TT.Type_Sound,                    'PlaySound', 1)

              -- Class Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor, TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)

              -- Power Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor, TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)

              -- Combat Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor, TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)

              -- Tagged Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor, TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
            end
          end

          -- Do this since all defaults need to be set first.
          BBar:DoOption()
        end
        BBar:UpdateTriggers()

        DoTriggers = true
        Display = true
      elseif BBar:ClearTriggers() then
        Display = true
      end
    end)
    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'HideText',      function(v)
      if v then
        BBar:SetValueRawFont(PowerBox, nil, '')
      else
        self:Update()
      end
    end)
    BBar:SO('Layout', 'Rotation',      function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',         function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',       function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(MoonBox, MoonSBar, 'in', v)
                                                   BBar:SetFadeTimeTexture(SunBox, SunSBar, 'in', v)
                                                   BBar:SetFadeTimeTexture(PowerBox, LunarSBar, 'in', v)
                                                   BBar:SetFadeTimeTexture(PowerBox, SolarSBar, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(MoonBox, MoonSBar, 'out', v)
                                                   BBar:SetFadeTimeTexture(SunBox, SunSBar, 'out', v)
                                                   BBar:SetFadeTimeTexture(PowerBox, LunarSBar, 'out', v)
                                                   BBar:SetFadeTimeTexture(PowerBox, SolarSBar, 'out', v) end)
    BBar:SO('Layout', 'Align',         function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX', function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY', function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',  function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',  function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('Background', 'BgTexture',     function(v, UB, OD) BBar[format('SetBackdrop%s', OD.p1)](BBar, OD.p2, OD.p3, v) end)
    BBar:SO('Background', 'BorderTexture', function(v, UB, OD) BBar[format('SetBackdropBorder%s', OD.p1)](BBar, OD.p2, OD.p3, v) end)
    BBar:SO('Background', 'BgTile',        function(v, UB, OD) BBar[format('SetBackdropTile%s', OD.p1)](BBar, OD.p2, OD.p3, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v, UB, OD) BBar[format('SetBackdropTileSize%s', OD.p1)](BBar, OD.p2, OD.p3, v) end)
    BBar:SO('Background', 'BorderSize',    function(v, UB, OD) BBar[format('SetBackdropBorderSize%s', OD.p1)](BBar,OD.p2, OD.p3, v) end)
    BBar:SO('Background', 'Padding',       function(v, UB, OD) BBar[format('SetBackdropPadding%s', OD.p1)](BBar, OD.p2, OD.p3, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v, UB, OD) BBar[format('SetBackdropColor%s', OD.p1)](BBar, OD.p2, OD.p3, v.r, v.g, v.b, v.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB, OD)
      if UB[OD.TableName].EnableBorderColor then
        BBar[format('SetBackdropBorderColor%s', OD.p1)](BBar, OD.p2, OD.p3, v.r, v.g, v.b, v.a)
      else
        BBar[format('SetBackdropBorderColor%s', OD.p1)](BBar, OD.p2, OD.p3, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTextureLunar', function(v) BBar:SetTexture(PowerBox, LunarSBar, v) end)
    BBar:SO('Bar', 'StatusBarTextureSolar', function(v) BBar:SetTexture(PowerBox, SolarSBar, v) end)
    BBar:SO('Bar', 'StatusBarTexture',      function(v, UB, OD) BBar:SetTexture(OD.p1, OD.p2, v) end)
    BBar:SO('Bar', 'RotateTexture',         function(v, UB, OD)
      if OD.TableName == 'BarPower' then
        BBar:SetRotateTexture(PowerBox, LunarSBar, v)
        BBar:SetRotateTexture(PowerBox, SolarSBar, v)

        BBar:ClearAllPointsTexture(PowerBox, LunarSBar)
        BBar:ClearAllPointsTexture(PowerBox, SolarSBar)
        local Padding = UB.BarPower.Padding

        BBar:DoOption('Bar', 'Padding')

        -- Vertical
        if v then
          BBar:SetPointTexture(PowerBox, LunarSBar, 'TOPLEFT')
          BBar:SetPointTexture(PowerBox, LunarSBar, 'BOTTOMRIGHT', nil, 'RIGHT')
          BBar:SetPointTexture(PowerBox, SolarSBar, 'TOPLEFT', nil, 'LEFT')
          BBar:SetPointTexture(PowerBox, SolarSBar, 'BOTTOMRIGHT')
        else
          -- Horizontal
          BBar:SetPointTexture(PowerBox, LunarSBar, 'TOPLEFT')
          BBar:SetPointTexture(PowerBox, LunarSBar, 'BOTTOMRIGHT', nil, 'BOTTOM')
          BBar:SetPointTexture(PowerBox, SolarSBar, 'TOPLEFT', nil, 'TOP')
          BBar:SetPointTexture(PowerBox, SolarSBar, 'BOTTOMRIGHT')
        end
      else
        BBar:SetRotateTexture(OD.p1, OD.p2, v)
      end
    end)
    BBar:SO('Bar', 'ColorLunar',            function(v) BBar:SetColorTexture(PowerBox, LunarSBar, v.r, v.g, v.b, v.a) end)
    BBar:SO('Bar', 'ColorSolar',            function(v) BBar:SetColorTexture(PowerBox, SolarSBar, v.r, v.g, v.b, v.a) end)
    BBar:SO('Bar', 'SunMoon',               function() self:Update() end)
    BBar:SO('Bar', 'Color',                 function(v, UB, OD)
      local TableName = OD.TableName

      BBar:SetColorTexture(OD.p1, OD.p2, v.r, v.g, v.b, v.a)
      if TableName == 'BarMoon' or TableName == 'BarSun' then
        self:Update()
      end
    end)
    BBar:SO('Bar', '_Size',                 function(v, UB, OD)
      local TableName = OD.TableName
      if OD.p1 == nil then
        return
      end

      if TableName == 'BarIndicator' or TableName == 'BarSlider' then
        BBar:SetSizeTexture(OD.p1, OD.p2, v.Width, v.Height)
      else
        BBar:SetSizeTextureFrame(OD.p1, BoxMode, v.Width, v.Height)
      end
      self:Update()
      Display = true
    end)
    BBar:SO('Bar', 'Padding',               function(v, UB, OD)
      if OD.TableName == 'BarPower' then
        local Rotation = UB.Layout.Rotation

        -- Check for vertical
        if UB.BarPower.RotateTexture then
          BBar:SetPaddingTexture(PowerBox, LunarSBar, v.Left, v.Right, v.Top, 0)
          BBar:SetPaddingTexture(PowerBox, SolarSBar, v.Left, v.Right, 0, v.Bottom)
        else
          BBar:SetPaddingTexture(PowerBox, LunarSBar, v.Left, 0, v.Top, v.Bottom)
          BBar:SetPaddingTexture(PowerBox, SolarSBar, 0, v.Right, v.Top, v.Bottom)
        end
      else
        BBar:SetPaddingTexture(OD.p1, OD.p2, v.Left, v.Right, v.Top, v.Bottom)
      end
      Display = true
    end)
  end

  -- Do the option.  This will call one of the options above or all.
  if TableName == nil or TableName == 'General' then
    local Gen = self.UnitBar.General

    if KeyName == nil or KeyName == 'HideSlider' then
      BBar:SetHiddenTexture(PowerBox, SliderSBar, Gen.HideSlider)
    end
    self:Update()
    Display = true
  end
  if TableName == nil or TableName ~= 'General' then
    BBar:DoOption(TableName, KeyName)
  end

  if DoTriggers or Main.UnitBars.Testing then
    self:Update(DoTriggers)
    DoTriggers = false
  end

  if Display then
    BBar:Display()
    Display = false
  end
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- UnitBarF     The unitbar frame which will contain the eclipse bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.EclipseBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, 3)

  local Names = {Trigger = {}}
  local Trigger = Names.Trigger

  -- Create the sun, moon, and power.
  BBar:CreateTextureFrame(PowerBox, BoxMode, 0)
    -- Create the lunar and solar statusbar for the bar section.
    BBar:CreateTexture(PowerBox, BoxMode, 'statusbar', 1, LunarSBar)
    BBar:CreateTexture(PowerBox, BoxMode, 'statusbar', 1, SolarSBar)

    -- Create slider and indicator
    BBar:CreateTexture(PowerBox, BoxMode, 'statusbar', 2, SliderSBar)

  BBar:CreateTextureFrame(MoonBox, BoxMode, 4)
    BBar:CreateTexture(MoonBox, BoxMode, 'statusbar', 5, MoonSBar)
  BBar:CreateTextureFrame(SunBox, BoxMode, 4)
    BBar:CreateTexture(SunBox, BoxMode, 'statusbar', 5, SunSBar)


  -- Show all the texture frames.
  BBar:SetHidden(0, BoxMode, false)

  BBar:SetHiddenTexture(PowerBox, LunarSBar, true)
  BBar:SetHiddenTexture(PowerBox, SolarSBar, true)

  -- Set up the default slider/indicator positions
  BBar:ClearAllPointsTexture(PowerBox, SliderSBar)
  BBar:SetPointTexture(PowerBox, SliderSBar, 'CENTER')

  -- Create font for displaying power.
  -- This will be displayed on the powerbar section.
  BBar:CreateFont(PowerBox)

  -- Set tooltips
  BBar:SetTooltip(MoonBox, nil, 'Eclipse - Moon')
  BBar:SetTooltip(SunBox, nil, 'Eclipse - Sun')
  BBar:SetTooltip(PowerBox, nil, 'Eclipse - Power')

  -- This will make all the bar objects be aligned by their sides.
  BBar:SetJustifyBar('SIDE')

  for GroupNumber = 1, #TriggerGroups do
    Trigger[GroupNumber] = TriggerGroups[GroupNumber][TGName]
  end

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Eclipsebar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.EclipseBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_AURA', self.Update, 'player')
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
  Main:RegEventFrame(Enable, self, 'ECLIPSE_DIRECTION_CHANGE', self.Update, 'player')
end


