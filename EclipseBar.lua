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

local UnitBarsF = Main.UnitBarsF
local LSM = Main.LSM
local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strupper, strlower, strmatch, format, strconcat, gsub, tonumber =
      strfind, strsplit, strsub, strupper, strlower, strmatch, format, strconcat, gsub, tonumber
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax
local UnitName, UnitGetIncomingHeals, GetRealmName =
      UnitName, UnitGetIncomingHeals, GetRealmName
local GetRuneCooldown, GetRuneType, GetSpellInfo, GetTalentInfo, PlaySound =
      GetRuneCooldown, GetRuneType, GetSpellInfo, GetTalentInfo, PlaySound
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
-- IndicatorSBar                     Texture number for indicator texture.
--
-- SolarAura                         SpellID for the solar aura.
-- LunarAura                         SpellID for the lunar aura.
-- CAAura                            SpellID for Celestial Alignment aura.
-- SoTF                              Soul of the forest talent number. Used to check to see if the player has this
--                                   talent active.
-- SoTFPower                         Amount of power soul of the forest gives.
-- SpellWrath                        SpellID for wrath.
-- SpellStarfire                     SpellID for starefire.
-- SpellStarsurge                    SpellID for starsurge.
-- SpellEnergize                     SpellID for energize that come back from the server when
--                                   Wrath, Starfire, or Starsurge is cast.
-- PredictedSpellValue               Table containing the power that each of the spells gives.  Used for prediction.
-------------------------------------------------------------------------------
local Display = false

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
local IndicatorSBar = 41

local SolarAura = 48517
local LunarAura = 48518
local CAAura = 112071    -- Celestial Alignment
--local SoTF = 114107  -- Soul of the forest
--local SoTFPower = 20 -- Amount of power that soul of the forest gives.

-- Predicted spell ID constants.
local SpellWrath     = 5176
local SpellStarfire  = 2912
local SpellStarsurge = 78674
local SpellEnergize  = 89265 -- Wrath, Starfire, Starsurge

local PredictedSpellValue = {
  [SpellWrath] = 15,
  [SpellStarfire] = 20,
  [SpellStarsurge] = 20
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.EclipseBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Eclipsebar predicted power and initialization
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Sets UnitBarF.PredictedSpell
--
-- If Celestial Alignment is active at the end of the cast then the spell
-- will generate no energy and cause no energize event.
--
-- So the function checks to see if the spell will finish without a CA aura.
-- If the spell will finish before CA drops off then the PredictedSpell is set
-- to the spellID otherwise its set to 0.
-------------------------------------------------------------------------------
local function CheckSpell(UnitBarF, SpellID, CastTime, Message)
  local PredictedSpell = 0

  if SpellID < 0 then
    if Message == 'start' then
      SpellID = abs(SpellID)

      -- Check for Celestial Alignment aura.  Will the aura drop off before spell
      -- is done casting?
      local Spell, TimeLeft = Main:CheckAura('o', CAAura)
      if Spell then
        if CastTime < TimeLeft then
          PredictedSpell = SpellID
        end
      else
        PredictedSpell = SpellID
      end
    end
  end

  -- Set PredictedSpell
  UnitBarF.PredictedSpell = PredictedSpell

  -- afterstart, end, failed, energize.
  -- Show the predicted power changes on the bar.
  UnitBarF:Update()
end

-------------------------------------------------------------------------------
-- Set Wrath, Starfire, Starsurge. Since 'energize' is being used the energize
-- spell has to be added as well.
-------------------------------------------------------------------------------
Main:SetSpellTracker(UnitBarsF.EclipseBar, SpellWrath,     'energize', CheckSpell)
Main:SetSpellTracker(UnitBarsF.EclipseBar, SpellStarfire,  'energize', CheckSpell)
Main:SetSpellTracker(UnitBarsF.EclipseBar, SpellStarsurge, 'energize', CheckSpell)
Main:SetSpellTracker(UnitBarsF.EclipseBar, SpellEnergize,  'energize', CheckSpell)

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

-------------------------------------------------------------------------------
-- GetPredictedEclipsePower
--
-- Calculates different parts of the eclipse bar for prediction.
--
-- SpellID         ID of the value being added.  See GetPredictedSpell()
-- Value           Positive value to add to Power.
-- Power           Current eclipse power.
-- MaxPower        Maximum eclipse power (constant)
-- Direction       Current direction the power is going in 'sun', 'moon', or 'none'.
-- PowerType       Type of power -1 lunar, 1 solar
-- Eclipse         -1 = lunar eclipse, 1 = solar eclipse, 0 = none
-- SoTFActive      If true then soul of the forest is active, otherwise false
--
-- The returned values are based on the Value passed being added to Power.
--
-- Returns:
--   PPower          Value added to Power.
--   PEclipse        -1 = lunar eclipse, 1 = solar eclipse, 0 = none
--   PPowerType      -1 = lunar, 1 = solar, 0 = nuetral
--   PDirection      'moon' = lunar, 'sun' = solar, or 'none'.
--   PowerChange     If true then the SpellID actually caused a power change.
-------------------------------------------------------------------------------
local function GetPredictedEclipsePower(SpellID, Value, Power, MaxPower, Direction, PowerType, Eclipse) --, SoTFActive)
  local PowerChange = false
  local OldPower = Power

  -- Double power if there is no eclipse state.
  if Eclipse == 0 then
    Value = Value * 2
  end

  -- Add value based on eclipse direction.
  if Direction == 'moon' then
    if SpellID == SpellWrath or SpellID == SpellStarsurge then
      Power = Power - Value
      PowerChange = true
    end
  elseif Direction == 'sun' then
    if SpellID == SpellStarfire or SpellID == SpellStarsurge then
      Power = Power + Value
      PowerChange = true
    end
  elseif SpellID == SpellWrath then
    Power = Power - Value
    PowerChange = true
  elseif SpellID == SpellStarfire then
    Power = Power + Value
    PowerChange = true
  elseif SpellID == SpellStarsurge then
    if PowerType == 0 then
      Power = Power + Value
    else
      Power = Power + Value * PowerType
    end
    PowerChange = true
  end

  -- Clip power if its greater than maxpower.
  if abs(Power) > MaxPower then
    Power = MaxPower * PowerType
  end

  -- Calc direction. Check to see if power went out of bounds.
  if PowerChange then
    if Power == -MaxPower then
      Direction = 'sun'
    elseif Power == MaxPower then
      Direction = 'moon'
    end
  end

  -- Check for soul of the forest and add the correct power.
 -- if SoTFActive then

    -- Lost solar eclipse.
 --   if OldPower > 0 and Power <= 0 then
 --     Power = Power - SoTFPower

    -- Lost lunar eclipse.
 --   elseif OldPower < 0 and Power >= 0 then
 --     Power = Power + SoTFPower
 --   end
 -- end

  -- Calc eclipse.
  if Direction == 'moon' and Power > 0 and Power <= MaxPower or Direction == 'sun' and Power < 0 and Power >= -MaxPower then

    -- Set the eclipse state.
    Eclipse = PowerType
  else

    -- No eclipse state.
    Eclipse = 0
  end

  return Power, Eclipse, GetEclipsePowerType(Power, Direction), Direction, PowerChange
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
  local BackgroundSlider = UB['Background' .. KeyName]
  local BarSlider = UB['Bar' .. KeyName]
  local BarPower = UB.BarPower
  local BackgroundPower = UB.BackgroundPower
  local Slider = nil

  if KeyName == 'Slider' then
    Slider = SliderSBar
  else
    Slider = IndicatorSBar
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
  local BdSize = BackgroundPower.BackdropSettings.BdSize / 2
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
    SliderPos = SliderPos * ((BarSize - BdSize - SliderSize) / 2)
  else
    SliderPos = SliderPos * (BarSize - BdSize) / 2
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
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EclipseBar:Update(Event, Unit, PowerType)
  if not self.Visible then
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
  local PredictedPower = Gen.PredictedPower

  local EclipsePower = UnitPower('player', PowerEclipse)
  local EclipseMaxPower = UnitPowerMax('player', PowerEclipse)
  local SpellID = Main:CheckAura('o', SolarAura, LunarAura)
  local Eclipse = SpellID == SolarAura and 1 or SpellID == LunarAura and -1 or 0
  local EclipseDirection = GetEclipseDirection()

  local EclipsePowerType = GetEclipsePowerType(EclipsePower, EclipseDirection)

  local IndicatorHideShow = Gen.IndicatorHideShow
  local FadeInTime = Gen.EclipseFadeInTime
  local FadeOutTime = Gen.EclipseFadeOutTime
  local PowerHalfLit = Gen.PowerHalfLit
  local HideSlider = Gen.HideSlider
  local PredictedEclipse = Gen.PredictedEclipse
  local PredictedPowerHalfLit = Gen.PredictedPowerHalfLit

  local Value = 0
  local PC = false
  local PEclipseDirection = nil
  local PEclipsePower = nil
  local PEclipsePowerType = nil
  local PEclipse = nil

  if Testing then
    if EclipseMaxPower == 0 then
      EclipseMaxPower = 100
    end
    if UB.TestMode.ShowEclipseSun then
      EclipseDirection = 'moon'
      EclipsePower = EclipseMaxPower
      SpellID = SpellStarsurge
      Eclipse = 1
    else
      EclipseDirection = 'sun'
      EclipsePower = EclipseMaxPower * -1
      SpellID = SpellStarsurge
      Eclipse = -1
    end
    EclipsePowerType = GetEclipsePowerType(EclipsePower, EclipseDirection)
  end


  -- Check hide slider option.
  if not HideSlider then
    DisplayEclipseSlider(UB, BBar, 'Slider', EclipsePower, EclipseMaxPower, EclipseDirection, EclipsePowerType)
  end

  -- Calculate predicted power.
  if PredictedPower then

    -- Check to see if soul of the forest talent is active.
   -- local SoTFActive = false --IsSpellKnown(SoTF)

    local PowerChange = false
    PEclipseDirection = EclipseDirection
    PEclipsePower = EclipsePower
    PEclipsePowerType = EclipsePowerType
    PEclipse = Eclipse

    if not Testing then
      SpellID = self.PredictedSpell or 0
    end

    if SpellID ~= 0 then
      Value = PredictedSpellValue[SpellID]
      PEclipsePower, PEclipse, PEclipsePowerType, PEclipseDirection, PowerChange =
        GetPredictedEclipsePower(SpellID, Value, PEclipsePower, EclipseMaxPower, PEclipseDirection, PEclipsePowerType, PEclipse)--, SoTFActive)

      -- Set power change flag.
      if PowerChange then
        PC = true
      end
    end

    -- Display indicator based on predicted power options.
    if PC and IndicatorHideShow ~= 'hidealways' or IndicatorHideShow == 'showalways' then
      BBar:SetHiddenTexture(PowerBox, IndicatorSBar, false)
      if PC or IndicatorHideShow == 'showalways' then
        DisplayEclipseSlider(UB, BBar, 'Indicator', PEclipsePower, EclipseMaxPower, PEclipseDirection, PEclipsePowerType)
      end
    else
      BBar:SetHiddenTexture(PowerBox, IndicatorSBar, true)
    end
  else
    BBar:SetHiddenTexture(PowerBox, IndicatorSBar, true)
  end

  -- Display the eclipse power.
  Value = nil

  -- if PC is true then we had predicted power.
  if PC and Gen.PredictedPowerText then
    Value = PEclipsePower

  -- Otherwise get current power.
  elseif Gen.PowerText then
    Value = EclipsePower
  end
  if not UB.Layout.HideText then
    if Value then
      BBar:SetValueFont(PowerBox, nil, 'number', abs(Value))
    else
      BBar:SetValueRawFont(PowerBox, nil, '')
    end
  end

  -- Use PEclise if PredictedEclipse and PEclipse are set.
  if PredictedEclipse and PEclipse ~= nil then
    Eclipse = PEclipse
  end
  BBar:SetHiddenTexture(SunBox, SunSBar, Eclipse ~= 1)
  BBar:SetHiddenTexture(MoonBox, MoonSBar, Eclipse ~= -1)

  -- Use PEclipseDirection if PowerHalfLit and PredictedPowerHalfLit is true and there is PEclispeDirection.
  if PowerHalfLit and PredictedPowerHalfLit and PEclipseDirection ~= nil then
    EclipseDirection = PEclipseDirection
  end
  BBar:SetHiddenTexture(PowerBox, LunarSBar, PowerHalfLit and EclipseDirection == 'sun')
  BBar:SetHiddenTexture(PowerBox, SolarSBar, PowerHalfLit and EclipseDirection == 'moon')

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

    BBar:SetOptionData('BackgroundMoon', MoonBox)
    BBar:SetOptionData('BackgroundSun', SunBox)
    BBar:SetOptionData('BackgroundPower', PowerBox)
    BBar:SetOptionData('BackgroundSlider', PowerBox, SliderSBar)
    BBar:SetOptionData('BackgroundIndicator', PowerBox, IndicatorSBar)
    BBar:SetOptionData('BarMoon', MoonBox,  MoonSBar)
    BBar:SetOptionData('BarSun', SunBox, SunSBar)
    BBar:SetOptionData('BarPower', PowerBox)
    BBar:SetOptionData('BarSlider', PowerBox, SliderSBar)
    BBar:SetOptionData('BarIndicator', PowerBox, IndicatorSBar)

    BBar:SO('Text', '_Font', function() BBar:UpdateFont(PowerBox) self:Update() end)
    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

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

    BBar:SO('Background', 'BackdropSettings', function(v, UB, OD)
      local TableName = OD.TableName

      if TableName == 'BackgroundSlider' or TableName == 'BackgroundIndicator' then
        BBar:SetBackdropTexture(OD.p1, OD.p2, v)
      else
        BBar:SetBackdrop(OD.p1, BoxMode, v)
      end
    end)
    BBar:SO('Background', 'Color',            function(v, UB, OD)
      local TableName = OD.TableName

      if TableName == 'BackgroundSlider' or TableName == 'BackgroundIndicator' then
        BBar:SetBackdropColorTexture(OD.p1, OD.p2, v.r, v.g, v.b, v.a)
      else
        BBar:SetBackdropColor(OD.p1, BoxMode, v.r, v.g, v.b, v.a)
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
    if KeyName == nil or KeyName == 'PredictedPower' then
      Main:SetSpellTracker(self, Gen.PredictedPower)
    end
    self:Update()
    Display = true
  end
  if TableName == nil or TableName ~= 'General' then
    BBar:DoOption(TableName, KeyName)
  end

  if Main.UnitBars.Testing then
    self:Update()
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

  -- Create the sun, moon, and power.
  BBar:CreateTextureFrame(PowerBox, BoxMode, 0)
    -- Create the lunar and solar statusbar for the bar section.
    BBar:CreateTexture(PowerBox, BoxMode, 'statusbar', 1, LunarSBar)
    BBar:CreateTexture(PowerBox, BoxMode, 'statusbar', 1, SolarSBar)

    -- Create slider and indicator
    BBar:CreateTexture(PowerBox, BoxMode, 'statusbar', 2, SliderSBar)
    BBar:CreateTexture(PowerBox, BoxMode, 'statusbar', 3, IndicatorSBar)

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
  BBar:ClearAllPointsTexture(PowerBox, IndicatorSBar)
  BBar:SetPointTexture(PowerBox, SliderSBar, 'CENTER')
  BBar:SetPointTexture(PowerBox, IndicatorSBar, 'CENTER')

  -- Create font for displaying power.
  -- This will be displayed on the powerbar section.
  BBar:CreateFont(PowerBox)

  -- Set tooltips
  BBar:SetTooltip(MoonBox, nil, 'Eclipse - Moon')
  BBar:SetTooltip(SunBox, nil, 'Eclipse - Sun')
  BBar:SetTooltip(PowerBox, nil, 'Eclipse - Power')

  -- This will make all the bar objects be aligned by their sides.
  BBar:SetJustifyBar('SIDE')

  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Eclipsebar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.EclipseBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_AURA', self.Update, 'player')
  Main:RegEventFrame(Enable, self, 'UNIT_POWER', self.Update, 'player')
  Main:RegEventFrame(Enable, self, 'ECLIPSE_DIRECTION_CHANGE', self.Update, 'player')
end


