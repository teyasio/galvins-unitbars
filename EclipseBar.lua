--
-- EclipseBar.lua
--
-- Displays the druid moonkin eclipse bar.
--
-- Predicted power:
--
-- Predicted power is calculated by taking any spell thats casting and any spells that are flying and totals them
-- up.  Flying spells on a 5sec timeout, if they take longer than 5secs to reach their target, they'll be removed
-- from the stack.  Spells that generate damage, energize, or miss the target are removed from the stack right away.
--
--
-- Wrath prediction explained:
--
-- When the player first logs in, the wrath sequence will be in sync with the server.  Since the wrath sequence
-- gets reset as well.  This is only true as long as the player has the eclipse bar turned on before casting
-- any spells.
--
-- As long as the player doesn't cast a wrath that will not move the energy bar, it will always be in sync.
-- Euphoria can't be predicted but the wrath sequence will still stay in sync.
--
--
-- Technical explanation of wrath prediction:
--
-- The wrath sequence is calculated by adding a constant value to a floating point number.
-- Wrath without 4pc bonus is 13.333333
-- Wrath with bonus is        16.666667
--
-- The wrath values are calculated by rounding the wrath sequence down.  But if the fractional part
-- is greater than 0.90 then its rounded up. Using positive values in this example.
--
-- Wrath Value   Sequence Value   Rounded       Current Wrath Value
--
-- 13.333333     13.333333        13            13 - 0    = 13
-- 13.333333     26.666666        26            26 - 13   = 13
-- 13.333333     39.999999        40            40 - 26   = 14
-- 13.333333     53.333332        53            53 - 40   = 13
-- Player gaines 4pc bonus
-- 16.666667     69.999999        70            70 - 53   = 17
-- 16.666667     86.666666        86            86 - 70   = 16
-- 16.666667     103.333333       103           103 - 86  = 17
-- 16.666667     120.0            120           120 - 103 = 17
-- Player loses 4pc bonus
-- 13.333333     133.333333       133           133 - 120 = 13
-- 13.333333     146.666666       146           146 - 133 = 13
-- Player gains 4pc bonus
-- 16.666667     163.333333       163           163 - 146 = 17
-- 16.666667     180.0            180           180 - 163 = 17
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local LSM = GUB.LSM
local PowerTypeToNumber = GUB.PowerTypeToNumber
local MouseOverDesc = GUB.MouseOverDesc

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin
local strfind, strsub, strupper, strlower, format, strconcat, strmatch, gsub, tonumber =
      strfind, strsub, strupper, strlower, format, strconcat, strmatch, gsub, tonumber
local pcall, pairs, ipairs, type, select, next, print, sort =
      pcall, pairs, ipairs, type, select, next, print, sort
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, PlaySound =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, PlaySound
local GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
-- UnitBarF.UnitBar                  Reference to the unitbar data for the eclipse bar.
-- UnitBarF.Border                   Border frame for the eclipse bar. This helps position the offsetframe.
-- UnitBarF.OffsetFrame              Used for rotation.
--
-- UnitBarF.EclipseF                 Table containing the frames that make up the eclipse bar.
--
-- Border.Anchor                     Anchor reference for moving.
--
-- EclipseF.Moon                     Table containing frame data for moon.
--   Dark                            If true the Moon is not lit.
--   Frame                           Child of MoonBorder. Used to hide/show the moon.
--   Border                          Child of OffsetFrame. Used to show a visible border for moon.
--   StatusBar                       Child of Moon.Frame.  Statusbar containing the visible texture.
--   FadeOut                         Animation group for fadeout.
--   FadeOutA                        Animation that contains the fade out. This animation is a child of FadeOut.
--
-- EclipseF.Sun                      Table containing frame data for sun.
--   Dark                            If true then the Sun is not lit.
--   Frame                           Child of MoonBorder. Used to hide/show the sun.
--   Border                          Child of OffsetFrame. Used to show a visible border for sun.
--   StatusBar                       Child of Sun.Frame.  Statusbar containing the visible texture.
--   FadeOut                         Animation group for fadeout.
--   FadeOutA                        Animation that contains the fade out. This animation is a child of FadeOut.
--
-- EclipseF.Bar                      Table containing the frame for the bar.
--   Frame                           Child of BarBorder. Used to hide/show the bar.
--   Border                          Child of OffsetFrame. Used to show a visible border for the bar.
--
-- EclipseF.Lunar                    Table containing the lunar statusbar.
--   Dark                            If true then the StatusBarLunar is not lit.
--   Frame                           Child of BarBorder.  This texture fills the lunar side of the bar.
--   FadeOut                         Animation group for fadeout.
--   FadeOutA                        Animation that contains the fade out. This animation is a child of FadeOut.
--
-- EclipseF.Solar
--   Dark                            If true then the StatusBarSolar is not lit.
--   Frame                           Child of BarBorder.  This texture fills the solar side of the bar.
--   FadeOut                         Animation group for fadeout.
--   FadeOutA                        Animation that contains the fade out. This animation is a child of FadeOut.
--
-- EclipseF.Slider                   Table containing the frame data for the slider.
--   Frame                           Child of OffsetFrame. Used to hide/show the slider.
--   Border                          Child of SliderFrame. Used to show a visible border for the slider.
--   StatusBar                       Child of SliderBorder.  Statusbar containing the visible texture.
--                                   This is set up so that Frame:Hide() will hide the whole Slider.
--
-- EclipseF.Indicator                Table containing the frame data for the indicator.
--   Frame                           Child of OffsetFrame. Used to hide/show the indicator.
--   Border                          Child of IndicatorFrame. Used to show a visible border for the indicator.
--   StatusBar                       Child of IndicatorBorder. Statusbar containing the visible texture.
--                                   This is set up so that Frame:Hide() will hide the whole Indicator.
--
-- Txt                               Standard text data.
--
-- RotateBar                         Table containing data for the bar rotation.
--
-- EclipseDirection                  Only gets when eclipse power is at max.
--                                   Sometimes the direction can change before the eclipse power hits
--                                   max power.  So to fix this, the direction gets updated when the
--                                   eclipsepower is at maxpower.  If EclipseDirection is nil or none then
--                                   it will be set to the current direction.
--
-- LastEclipseDirection
-- LastEclipse
-- LastEclipsePower
-- LastPredictedSpells               These four values keep track if there is a change in the eclipse bar.
--
-- WrathSequence                     A positive floating point number that keeps track of the wrath sequence.
-- SequenceRounded                   Rounded off value of WrathSequence used to calculate the next wrath value.
-- WrathNormalValue                  Floating point normal wrath to advance the sequence.
-- WrathFourPcValue                  Four pc tier 12 set bonus wrath value to advance the sequence.
-- SavedWrathSequence                Used to save the current value of WrathSequence.
-- SavedSequenceRounded              Used to save the current value of SequenceRounded.
-- LastWrathServerValue              Used to by SyncWrathSequence().  Helps to detect if the sequence is in sync with
--                                   the server. This contains the last wrath value from the server.
-- WrathSync                         If true then in sync otherwise false.
--
-- Eclipse bar frame layout:
--
-- ScaleFrame
--   Border
--     OffsetFrame
--       MoonBorder
--         MoonFrame
--           Moon
--       SunBorder
--         SunFrame
--           Sun
--       BarBorder
--         BarFrame
--           BarLunar
--           BarSolar
--       IndicatorFrame
--         IndicatorBorder
--           Indicator
--       SliderFrame
--         SliderBorder
--           Slider
--       TxtBorder
-------------------------------------------------------------------------------

-- Powertype constants
local PowerEclipse = PowerTypeToNumber['ECLIPSE']

local EclipseDirection = nil
local LastEclipsePower = nil
local LastEclipseDirection = nil
local LastEclipse = nil
local LastPredictedSpells = nil

local WrathSequence = 0
local SequenceRounded = 0
local SavedWrathSequence = 0
local SavedSequenceRounded = 0
local LastWrathServerValue = 0
local WrathSync = false
local WrathNormalValue = 13.333333
local WrathFourPcValue = 16.666667

local SolarBuff = 48517;
local LunarBuff = 48518;

-- Predicted spell ID constants.
local SpellWrath      = 5176
local SpellStarfire   = 2912
local SpellStarsurge  = 78674
local SpellEnergizeWS = 89265 -- Energize for Wrath and Starfire
local SpellEnergizeSS = 86605 -- Energize for Starsurge

local PredictedSpellValue = {
  [SpellWrath] = 13,
  [SpellStarfire] = 20,
  [SpellStarsurge] = 15,
}

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

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
GUB.UnitBarsF.EclipseBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Eclipsebar predicted power and initialization
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- ResetWrathSequence
--
-- Resets the wrath sequence.
--
-- Usage: ResetWrathSequence()
-------------------------------------------------------------------------------
local function ResetWrathSequence()
  SequenceRounded = 0
  WrathSequence = 0
end

-------------------------------------------------------------------------------
-- AdvanceWrathSequence
--
-- Advanced the wrath sequence to the next value.
--
-- Usage: WrathValue = AdvanceWrathSequence(Bonus)
--
-- Bonus        If true then the sequence gets advanced based on the set bonus.
--
-- WrathValue   Next value in the sequence.
--
-- NOTES:  The server uses the same math.  As long as the sequence matches the
--         server it will always return the correct value.
-------------------------------------------------------------------------------
local function AdvanceWrathSequence(Bonus)
  local Value = WrathNormalValue

  -- Get 4pc bonus value.
  if Bonus then
    Value = WrathFourPcValue
  end

  local LastSequenceRounded = SequenceRounded
  WrathSequence = WrathSequence + Value
  SequenceRounded = WrathSequence

  -- To return the correct value the WrathSequence has to be rounded.
  if SequenceRounded - floor(SequenceRounded) > 0.90 then
    SequenceRounded = floor(SequenceRounded) + 1
  else
    SequenceRounded = floor(SequenceRounded)
  end

  -- Return the wrath value.
  return SequenceRounded - LastSequenceRounded
end

-------------------------------------------------------------------------------
-- SyncWrathSequence
--
-- Sync the wrath sequence. Matches the wrath sequence with the server.  Takes 1 to 2 tries.
--
-- usage: SyncWrathSequence(Value)
--
-- Value       Value to sync to.
--
-- NOTES:      Matches the wrath sequence value.  If it doesn't then it
--             forwards the sequence till a match is found.
--             If its an euphoria value.  Then it advances the sequence till the sum
--             of two values equals the euphoria.
-------------------------------------------------------------------------------
local function SyncWrathSequence(Value)
  local LastWrathValue = 0
  local WrathValue = 0
  local WrathCount = 0
  local Found = false
  local Bonus = false

  Value = abs(Value)

  -- 4pc tier 12 bonus value. set bonus to true.
  if Value == 16 or Value == 17 or Value == 33 or Value == 34 then
    Bonus = true
  end

  -- Help sync faster.
  if not WrathSync and (LastWrathServerValue == 13 and Value == 13 or LastWrathServerValue == 17 and Value == 17) then
    Value = LastWrathServerValue + Value
  end

  -- Forward the sequence to the next matching value.
  while not Found and WrathCount < 10 do
    WrathCount = WrathCount + 1
    LastWrathValue = WrathValue
    WrathValue = AdvanceWrathSequence(Bonus)
    if Value == WrathValue or Value == LastWrathValue + WrathValue then
      Found = true
    end
  end

  -- Check to see if in sync.
  if Found then
    if WrathValue == 14 or WrathValue == 16 or Value == 26 or
       LastWrathServerValue == 13 and Value == 13 or LastWrathServerValue == 17 and Value == 17 then
      WrathSync = true
    end
    LastWrathServerValue = Value
  else
    print('Unable to find ', -Value, ' in the wrath sequence')
  end
end

-------------------------------------------------------------------------------
-- SaveRestoreWrathSequence
--
-- Saves/restores the current sequence.
--
-- Usage: SaveRestoreWrathSequence(Action)
--
-- Action     'save' saves the current wrath sequence.
--            'restore' restores the last saved wrath sequence.
--
-- NOTE: Since the prediction code needs to look ahead in the wrath sequence.
--       The sequence needs to be restored so that the prediction code
--       doesn't advance it.
-------------------------------------------------------------------------------
local function SaveRestoreWrathSequence(Action)
  if Action == 'save' then
    SavedWrathSequence = WrathSequence
    SavedSequenceRounded = SequenceRounded
  elseif Action == 'restore' then
    WrathSequence = SavedWrathSequence
    SequenceRounded = SavedSequenceRounded
  end
end

-------------------------------------------------------------------------------
-- CheckSpell [User defined function for predicted power] Only called by SetPredictedSpell()
--
-- This function gets called when a damage spell or energize spell hits the target.
--
-- If an energize spell comes in it checks to see what spellID triggered it.
-- then tells SetPredictedSpell() to remove that spellID.  If a damage spell
-- comes in it removes it from the spell stack if it doesn't produce an energize event.
--
-- The wrath sequence only gets updated on damage when a wrath energize event happens.
--
-- NOTE: See SetPredictedSpell() in Main.lua for details on how this function is called.
-------------------------------------------------------------------------------
local function CheckSpell(SpellID, Value)

  -- Remove spell from stack that will not generate an energize event.
  if SpellID == SpellWrath or SpellID == SpellStarfire  or SpellID == SpellStarsurge then
    local RemoveSpell = false
    if SpellID == SpellWrath and EclipseDirection == 'sun' then
      RemoveSpell = true
    elseif SpellID == SpellStarfire and EclipseDirection == 'moon' then
      RemoveSpell = true
    else

      -- Spell has an energize event, dont remove the spell from the stack.
      RemoveSpell = false
    end

    return RemoveSpell
  else

    -- Check for energize spell and convert it to spellID damage.
    -- Also a spell damage will happen or happened since energize happened.
    if SpellID == SpellEnergizeWS then

      -- Ignore energize if its from moonfire/sunfire.
      if abs(Value) ~= 8 then
        if Value < 0 then

          -- Update the sequence based on Value.
          SyncWrathSequence(Value)

          -- Spell is wrath from energize.
          SpellID = SpellWrath
        else

          -- Spell is starfire from energize.
          SpellID = SpellStarfire
        end
      else
        SpellID = -1
      end
    else

      -- Spell is starsurge from energize.
      SpellID = SpellStarsurge
    end

    -- pass back the SpellID to be removed.
    return SpellID
  end
end

-------------------------------------------------------------------------------
-- Set Wrath, Starfire, Starsurge to need a flight time. Also CheckSpell will be
-- called when either of the spells hit the target.
-- Set Energize to call CheckSpell as well.
-------------------------------------------------------------------------------
Main:SetPredictedSpells(SpellWrath,      true,  CheckSpell)
Main:SetPredictedSpells(SpellStarfire,   true,  CheckSpell)
Main:SetPredictedSpells(SpellStarsurge,  true,  CheckSpell)
Main:SetPredictedSpells(SpellEnergizeWS, false, CheckSpell)
Main:SetPredictedSpells(SpellEnergizeSS, false, CheckSpell)

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
-- usage: EclipsePowerType = GetEclipsePowerType(EclipsePower)
--
-- EclipsePower          Eclipse Power
--
-- EclipsePowerType      -1 = lunar, 1 = solar, 0 = neutral
-------------------------------------------------------------------------------
local function GetEclipsePowerType(Power)
  if Power < 0 then
    return -1
  elseif Power > 0 then
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
-- usage: PPower, PEclipse, PPowerType, PDirection , PowerChange =
--          GetPredictedEclipsePower(SpellID, Value, Power, MaxPower, Direction, PowerType)
--
-- SpellID         ID of the value being added.  See GetPredictedSpell()
-- Value           Positive value to add to Power.
-- Power           Current eclipse power.
-- MaxPower        Maximum eclipse power (constant)
-- Direction       Current direction the power is going in 'sun', 'moon', or 'none'.
-- PowerType       Type of power -1 lunar, 1 solar
--
-- The returned values are based on the Value passed being added to Power.
--
-- PPower          Value added to Power.
-- PEclipse        -1 = lunar eclipse, 1 = solar eclipse, 0 = none
-- PPowerType      -1 = lunar, 1 = solar, 0 = nuetral
-- PDirection      'moon' = lunar, 'sun' = solar, or 'none'.
-- PowerChange     If true then the SpellID actually caused a power change.
-------------------------------------------------------------------------------
local function GetPredictedEclipsePower(SpellID, Value, Power, MaxPower, Direction, PowerType)
  local PowerChange = false
  local Eclipse = 0

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

  -- Calc direction.
  if PowerChange then
    if Power <= -MaxPower then
      Direction = 'sun'
    elseif Power >= MaxPower then
      Direction = 'moon'
    end
  end

  -- Calc eclipse.
  if Direction == 'moon' and Power > 0 and Power <= MaxPower or Direction == 'sun' and Power < 0 and Power >= -MaxPower then
    Eclipse = PowerType
  end

  return Power, Eclipse, GetEclipsePowerType(Power), Direction, PowerChange
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
  if Main.UnitBarStartMoving(self.Anchor, Button) then
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
    Main.UnitBarStopMoving(self.Anchor, Button)
  end
end

--*****************************************************************************
--
-- Eclipsebar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EclipseBarHide
--
-- Hides/Shows the sun and moon
--
-- usage: EclipseBarHide(EF, Frame, FadeOutTime, Hide)
--
-- EF          EclipseFrame contains the frame data for the slider.
-- Frame       Frame to hide or show.  Can be 'Sun' or 'Moon'
-- Hide        If true frame is hidden else shown.
-- FadeOutTime if > 0 then fadeout animation will be used.
--             if -1 then all fadeout animation will be canceled.
-------------------------------------------------------------------------------
local function EclipseBarHide(EF, Frame, Hide, FadeOutTime)

  --Get frame.
  local SliderF = EF[Frame]
  local Frame = SliderF.Frame

  if FadeOutTime == -1 then
    if SliderF.Dark then
      Main:AnimationFadeOut(Frame.FadeOut, 'finish', function() Frame:Hide() end)
    end

  elseif not Hide and SliderF.Dark then
    if FadeOutTime > 0 then

      -- Finish animation if it's playing.
      Main:AnimationFadeOut(Frame.FadeOut, 'finish')
    end
    Frame:Show()
    SliderF.Dark = false

  elseif Hide and not SliderF.Dark then
    if FadeOutTime > 0 then

      -- Fade out the soul shard then hide it.
      Main:AnimationFadeOut(Frame.FadeOut, 'start', function() Frame:Hide() end)
    else
      Frame:Hide()
    end
    SliderF.Dark = true
  end
end

-------------------------------------------------------------------------------
-- DisplayEclipseSlider
--
-- Subfunction of Update()
--
-- Displays a slider on the eclipse bar.
--
-- usage: DisplayEclipseSlider(EF, UB, Slider, Power, MaxPower, Direction, PowerType)
--
-- EF           EclipseFrame contains the frame data for the slider.
-- UB           Unitbar data that is needed to display the slider.
-- Slider       Name of the slider table name.
-- Power        Current eclipse power
-- MaxPower     Maximum eclipse power
-- Eclipse      The current eclipse state.
-- PowerType    -1 = 'lunar', 1 = 'solar', 0 = neutral
-------------------------------------------------------------------------------
local function DisplayEclipseSlider(EF, UB, Slider, Power, MaxPower, Direction, PowerType)

  -- Get frame data.
  local Gen = UB.General
  local SliderDirection = Gen.SliderDirection
  local EclipseAngle = Gen.EclipseAngle
  local Background = UB.Background
  local Bar = UB.Bar
  local SliderF = EF[Slider]

  -- Clip eclipsepower if out of range.
  if abs(Power) > MaxPower then
    Power = Power * PowerType
  end

  local SliderPos = Power / MaxPower
  local BdSize = Background.Bar.BackdropSettings.BdSize / 2
  local BarSize = 0
  local SliderSize = 0

  -- Get slider direction.
  if SliderDirection == 'VERTICAL' then
    BarSize = Bar.Bar.BarHeight
    SliderSize = Bar[Slider][format('%sHeight', Slider)]
  else
    BarSize = Bar.Bar.BarWidth
    SliderSize = Bar[Slider][format('%sWidth', Slider)]
  end

  -- Calc rotate direction.
  if EclipseAngle == 180 or EclipseAngle == 270 then
    SliderPos = SliderPos * -1
  end

  -- Check the SliderInside option.  Need to divide by 2 since we have negative to positive coordinates.
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
  local SliderColor = Bar[Slider].Color

  -- Check for sun/moon color option.
  if Bar[Slider].SunMoon then
    if Direction == 'sun' then
      SliderColor = Bar.Sun.Color
    elseif Direction == 'moon' then
      SliderColor = Bar.Moon.Color
    end
  end
  SliderF.StatusBar:SetStatusBarColor(SliderColor.r, SliderColor.g, SliderColor.b, SliderColor.a)
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the eclipse bar power, sun, and moon.
--
-- usage: Update(Event)
--
-- Event     'change' then the bar will only get updated if there is a change.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.EclipseBar:Update(Event)
  if not self.Enabled then
    return
  end

  local UB = self.UnitBar
  local Gen = UB.General
  local PredictedPower = Gen.PredictedPower

  local EclipsePower = UnitPower('player', PowerEclipse)
  local EclipseMaxPower = UnitPowerMax('player', PowerEclipse)
  local SpellID = Main:CheckAura('o', SolarBuff, LunarBuff)
  local Eclipse = SpellID == SolarBuff and 1 or SpellID == LunarBuff and -1 or 0
  local EclipsePowerType = GetEclipsePowerType(EclipsePower)

  -- Update EclipseDirection on maxpower or nil or none.
  local ED = GetEclipseDirection()
  if abs(EclipsePower) == EclipseMaxPower or EclipsePower == 0 or EclipseDirection == nil then
    EclipseDirection = ED
  end

  local PredictedSpells = PredictedPower and Main:GetPredictedSpell(1) > 0 and 1 or 0

  -- Return if there is no change.
  if Event == 'change' and EclipsePower == LastEclipsePower and EclipseDirection == LastEclipseDirection and
     Eclipse == LastEclipse and PredictedSpells == 0 and LastPredictedSpells == 0 then
    return
  end

  local EF = self.EclipseF

  -- Check for real zero eclipse power.
  if EclipsePower == 0 then
    local EclipsePowerZeroTime = EF.EclipsePowerZeroTime

    -- Set the starting time and return.
    if EclipsePowerZeroTime == nil or EclipsePowerZeroTime == 0 then
      EF.EclipsePowerZeroTime = GetTime()
      return

    -- Keep returning if not enough time has passed.
    elseif GetTime() - EclipsePowerZeroTime < 0.4 then
      return
    end
  else
    EF.EclipsePowerZeroTime = 0
  end

  LastEclipsePower = EclipsePower
  LastEclipseDirection = EclipseDirection
  LastEclipse = Eclipse
  LastPredictedSpells = PredictedSpells

  local IndicatorHideShow = Gen.IndicatorHideShow
  local FadeOutTime = Gen.EclipseFadeOutTime
  local BarHalfLit = Gen.BarHalfLit
  local PredictedEclipse = Gen.PredictedEclipse
  local PredictedBarHalfLit = Gen.PredictedBarHalfLit

  local Value = 0
  local Bonus = false
  local PC = false
  local PEclipseDirection = nil
  local PEclipsePower = nil
  local PEclipsePowerType = nil
  local PEclipse = nil

  -- Check hide slider option.
  if PredictedPower and Gen.PredictedHideSlider then
    EF.Slider.Frame:Hide()
  else
    EF.Slider.Frame:Show()
    DisplayEclipseSlider(EF, UB, 'Slider', EclipsePower, EclipseMaxPower, EclipseDirection, EclipsePowerType)
  end

  -- Calculate predicted power.
  if PredictedPower then
    local Index = 1
    local PowerChange = false
    PEclipseDirection = EclipseDirection
    PEclipsePower = EclipsePower
    PEclipsePowerType = EclipsePowerType
    PEclipse = Eclipse

    -- Save the wrath sequence so that it can be looked ahead.
    SaveRestoreWrathSequence('save')
    repeat
      SpellID = Main:GetPredictedSpell(Index)

      if SpellID ~= 0 then
        Value = PredictedSpellValue[SpellID]
        Bonus = Main:GetSetBonus(12) == 4 and PEclipse == 0

        -- Get the next wrath value in the sequence. 4pc bonus is only active if predicted solar eclipse is 1.
        if SpellID == SpellWrath then
          Value = AdvanceWrathSequence(Bonus)

        -- Add 5 to starfire if predicted bonus is active.
        elseif SpellID == SpellStarfire and Bonus then
          Value = Value + 5
        end

        PEclipsePower, PEclipse, PEclipsePowerType, PEclipseDirection, PowerChange =
          GetPredictedEclipsePower(SpellID, Value, PEclipsePower, EclipseMaxPower, PEclipseDirection, PEclipsePowerType)

        -- Set power change flag.
        if PowerChange then
          PC = true
        end
      end
      Index = Index + 1
    until SpellID == 0

    -- Restore the wrath sequence.
    SaveRestoreWrathSequence('restore')

    -- Display indicator based on predicted power options.
    if PC and IndicatorHideShow ~= 'hidealways' or IndicatorHideShow == 'showalways' then
      EF.Indicator.Frame:Show()
      if PC or IndicatorHideShow == 'showalways' then
        DisplayEclipseSlider(EF, UB, 'Indicator', PEclipsePower, EclipseMaxPower, PEclipseDirection, PEclipsePowerType)
      end
    else
      EF.Indicator.Frame:Hide()
    end
  else
    EF.Indicator.Frame:Hide()
  end

  -- Display the eclipse power.
  Value = nil
  if Gen.PredictedPowerText then
    Value = PEclipsePower
  end
  if Gen.PowerText and Value == nil then
    Value = EclipsePower
  end
  if Value then
    EF.Txt:SetText(abs(Value))
  else
    EF.Txt:SetText('')
  end

  -- Hide/show sun and moon
  if PredictedEclipse and (EclipseDirection ~= 'moon' and PEclipse == 1 or PEclipse == 1 and Eclipse == 1) or
     (not PredictedEclipse or PEclipse ~= 0) and Eclipse == 1 then
    EclipseBarHide(EF, 'Sun', false, FadeOutTime)
  else
    EclipseBarHide(EF, 'Sun', true, FadeOutTime)
  end
  if PredictedEclipse and (EclipseDirection ~= 'sun' and PEclipse == -1 or PEclipse == -1 and Eclipse == -1) or
     (not PredictedEclipse or PEclipse ~= 0) and Eclipse == -1 then
   EclipseBarHide(EF, 'Moon', false, FadeOutTime)
  else
    EclipseBarHide(EF, 'Moon', true, FadeOutTime)
  end

  -- Check the HalfLit option, predicted power can change how this works.
  if PredictedBarHalfLit and PEclipseDirection == 'sun' or
     BarHalfLit and EclipseDirection == 'sun' then
    EclipseBarHide(EF, 'Lunar', true, FadeOutTime)
    EclipseBarHide(EF, 'Solar', false, FadeOutTime)
  elseif PredictedBarHalfLit and PEclipseDirection == 'moon' or
         BarHalfLit and EclipseDirection == 'moon' then
    EclipseBarHide(EF, 'Lunar', false, FadeOutTime)
    EclipseBarHide(EF, 'Solar', true, FadeOutTime)
  else
    EclipseBarHide(EF, 'Lunar', false, FadeOutTime)
    EclipseBarHide(EF, 'Solar', false, FadeOutTime)
  end
end

-------------------------------------------------------------------------------
-- CancelAnimation    UnitBarsF function
--
-- Cancels all animation playing in the eclipse bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.EclipseBar:CancelAnimation()
  local EF = self.EclipseF
  EclipseBarHide(EF, 'Moon', false, -1)
  EclipseBarHide(EF, 'Sun', false, -1)
  EclipseBarHide(EF, 'Lunar', false, -1)
  EclipseBarHide(EF, 'Solar', false, -1)
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
function GUB.UnitBarsF.EclipseBar:EnableMouseClicks(Enable)
  local EF = self.EclipseF

  EF.Moon.Border:EnableMouse(Enable)
  EF.Sun.Border:EnableMouse(Enable)
  EF.Bar.Border:EnableMouse(Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScript    UnitBarsF function
--
-- Set up script handlers for the eclipsebar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.EclipseBar:FrameSetScript(Enable)
  local EF = self.EclipseF

  local function FrameSetScript(Frame, Enable)
    if Enable then
      Frame:SetScript('OnMouseDown', EclipseBarStartMoving)
      Frame:SetScript('OnMouseUp', EclipseBarStopMoving)
      Frame:SetScript('OnHide', function(self)
                                   EclipseBarStopMoving(self)
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

  FrameSetScript(EF.Moon.Border, Enable)
  FrameSetScript(EF.Sun.Border, Enable)
  FrameSetScript(EF.Bar.Border, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the eclipsebar.
--
-- Usage: SetAttr(Object, Attr, Eclipse)
--
-- Object       Object being changed:
--               'bg'        for background (Border).
--               'bar'       for forground (StatusBar).
--               'text'      for the text.
--               'frame'     for the frame.
-- Attr         Type of attribute being applied to object:
--               'color'     Color being set to the object.
--               'backdrop'  Backdrop settings being set to the object.
--               'scale'     Scale settings being set to the object.
--               'size'      Size being set to the object.
--               'padding'   Amount of padding set to the object.
--               'texture'   One or more textures set to the object.
--               'strata'    Frame strata for the object.
-- Eclipse      Which part of the eclispe bar being changed
--               'moon'      Apply changes to the moon.
--               'sun'       Apply changes to the sun.
--               'bar'       Apply changes to the bar.
--               'slider'    Apply changes to the slider.
--               'Indicator' Apply changes to the predicted slider.
--              if Eclipse is nil then only frame scale, frame strata, or text can be changed.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.EclipseBar:SetAttr(Object, Attr, Eclipse)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local EclipseF = self.EclipseF

  -- Check scale and strata for 'frame'
  Main:UnitBarSetAttr(self, Object, Attr)

  -- Text (StatusBar.Txt).
  if Object == nil or Object == 'text' then
    local Txt = EclipseF.Txt

    local TextColor = UB.Text.Color

    if Attr == nil or Attr == 'font' then
      Main:SetFontString(Txt, UB.Text.FontSettings)
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
  Eclipse = gsub(Eclipse, '%a', strupper, 1)

  -- Get bar data.
  local Background = UB.Background[Eclipse]
  local Bar = UB.Bar[Eclipse]
  local UBF = EclipseF[Eclipse]

  -- Background (Border).
  if Object == nil or Object == 'bg' then
    local Border = UBF.Border
    local BgColor = Background.Color

    if Attr == nil or Attr == 'backdrop' then
      Border:SetBackdrop(Main:ConvertBackdrop(Background.BackdropSettings))
      Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
    end
    if Attr == nil or Attr == 'color' then
      Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
    end
  end

  -- Forground (Statusbar).
  if Object == nil or Object == 'bar' then
    local StatusBar = UBF.StatusBar
    local StatusBarLunar = EclipseF.Lunar.Frame
    local StatusBarSolar = EclipseF.Solar.Frame
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
      Frame:SetWidth(Bar[format('%sWidth', Eclipse)])
      Frame:SetHeight(Bar[format('%sHeight', Eclipse)])
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayout    UnitBarsF function
--
-- Set an eclipsebar to a new layout
-------------------------------------------------------------------------------
function GUB.UnitBarsF.EclipseBar:SetLayout()

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Bar = UB.Bar
  local Gen = UB.General

  local EclipseAngle = Gen.EclipseAngle
  local SunOffsetX = Gen.SunOffsetX
  local SunOffsetY = Gen.SunOffsetY
  local MoonOffsetX = Gen.MoonOffsetX
  local MoonOffsetY = Gen.MoonOffsetY
  local FadeOutTime = Gen.EclipseFadeOutTime
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
  local IndicatorFrame = EF.Indicator.Frame
  local OffsetFrame = self.OffsetFrame

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
  Frame1:SetPoint(RB.Point1, OffsetFrame, 0, 0)
  F.Border:SetAllPoints(Frame1)

  -- Set the bar.
  F = EF[RB.Frame2]
  local Frame2 = F.Frame

  -- Calculate the upper left for the bar.
  if TableName == 'Moon' then
    x, y = Main:CalcSetPoint(RB.RelativePoint2, MoonWidth, MoonHeight, MoonOffsetX, MoonOffsetY)
  else
    x, y = Main:CalcSetPoint(RB.RelativePoint2, SunWidth, SunHeight, SunOffsetX, SunOffsetY)
  end
  x1, y1 = Main:CalcSetPoint(RB.Point2, BarWidth, BarHeight, 0, 0)

  BarX = x - x1
  BarY = y - y1
  Frame2:ClearAllPoints()
  Frame2:SetPoint('TOPLEFT', OffsetFrame, BarX, BarY)
  F.Border:SetAllPoints(Frame2)

  -- Set the sun or moon.
  TableName = RB.Frame3
  F = EF[RB.Frame3]
  local Frame3 = F.Frame

  -- Caculate the upper left for sun or moon.
  Frame3:ClearAllPoints()
  x, y = Main:CalcSetPoint(RB.RelativePoint3, BarWidth, BarHeight, BarX, BarY)
  if TableName == 'Moon' then
    x1, y1 = Main:CalcSetPoint(RB.Point3, MoonWidth, MoonHeight, MoonOffsetX, MoonOffsetY)
    MoonX = x - x1
    MoonY = y - y1
    Frame3:SetPoint('TOPLEFT', OffsetFrame, MoonX, MoonY)
  else
    x1, y1 = Main:CalcSetPoint(RB.Point3, SunWidth, SunHeight, SunOffsetX, SunOffsetY)
    SunX = x - x1
    SunY = y - y1
    Frame3:SetPoint('TOPLEFT', OffsetFrame, SunX, SunY)
  end
  F.Border:SetAllPoints(Frame3)

  -- Set up the slider.
  -- Dont clear points, Ecplise:Update() sets the point.
  EF.Slider.Border:SetAllPoints(SliderFrame)

  -- Set up the indicator.
  -- Dont clear points, EclipseBar:Update() sets the point.
  EF.Indicator.Border:SetAllPoints(IndicatorFrame)

  -- Calculate upper left of slider for border calculation.
  SliderX, SliderY = Main:CalcSetPoint('CENTER', BarWidth, BarHeight, -(SliderWidth / 2), SliderHeight / 2)
  SliderX = BarX + SliderX
  SliderY = BarY + SliderY

  -- Calculate the offsets for the offsetframe, get the borderwidth and borderheight
  x, y, BorderWidth, BorderHeight = Main:GetBorder(SunX, SunY, SunWidth, SunHeight,
                                                               MoonX, MoonY, MoonWidth, MoonHeight,
                                                               BarX, BarY, BarWidth, BarHeight,
                                                               SliderX, SliderY, SliderWidth, SliderHeight)
  OffsetFX = -x
  OffsetFY = -y

  -- Set the x, y location off the offset frame.
  OffsetFrame:ClearAllPoints()
  OffsetFrame:SetPoint('LEFT', OffsetFX, OffsetFY)
  OffsetFrame:SetWidth(BorderWidth)
  OffsetFrame:SetHeight(BorderHeight)

  -- Set the duration of the fade out for sun, moon, lunar and solar.
  Frame1.FadeOutA:SetDuration(FadeOutTime)
  Frame3.FadeOutA:SetDuration(FadeOutTime)
  EF.Lunar.Frame.FadeOutA:SetDuration(FadeOutTime)
  EF.Solar.Frame.FadeOutA:SetDuration(FadeOutTime)

  -- Set all attributes.
  self:SetAttr(nil, nil, 'moon')
  self:SetAttr(nil, nil, 'bar')
  self:SetAttr(nil, nil, 'sun')
  self:SetAttr(nil, nil, 'slider')
  self:SetAttr(nil, nil, 'indicator')

  -- Save size data to self (UnitBarF).
  self:SetSize(BorderWidth, BorderHeight)
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- Usage: GUB.EclipseBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the eclipse bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.EclipseBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
  local EclipseFrame = {Moon = {}, Sun = {}, Bar = {}, Lunar = {}, Solar = {}, Slider = {}, Indicator = {}}

  -- Create a border to help position the offsetframe.
  local Border = CreateFrame('Frame', nil, ScaleFrame)
  Border:SetAllPoints(Anchor)

    -- Create the text frame.
    local TxtBorder = CreateFrame('Frame', nil, Border)
    TxtBorder:SetAllPoints(Border)
    local Txt = TxtBorder:CreateFontString(nil, 'OVERLAY')

    -- Create the offset frame.
    local OffsetFrame = CreateFrame('Frame', nil, Border)

  -- MOON

      -- Create the visible border for the moon.
      local MoonBorder = CreateFrame('Frame', nil, OffsetFrame)

        -- Create the moon frame.  This is used for hide/show
        local MoonFrame = CreateFrame('Frame', nil, MoonBorder)

          -- Create the statusbar for the moon.
          local Moon = CreateFrame('StatusBar', nil, MoonFrame)

  -- SUN

      -- Create the visible border for the sun.
      local SunBorder = CreateFrame('Frame', nil, OffsetFrame)

        -- Create the sun frame.  This is used for hide/show
        local SunFrame = CreateFrame('Frame', nil, SunBorder)

          -- Create the statusbar for the sun.
          local Sun = CreateFrame('StatusBar', nil, SunFrame)

  -- BAR

      -- Create the visible border for eclipse bar.
      local BarBorder = CreateFrame('Frame', nil, OffsetFrame)

        -- Create the eclipse bar for the slider.
        local BarFrame = CreateFrame('Frame', nil, BarBorder)

          -- Create the left stausbar for lunar and set it to lit.
          local BarLunar = CreateFrame('StatusBar', nil, BarFrame)

          -- Create the right stausbar for solar and set then to lit.
          local BarSolar = CreateFrame('StatusBar', nil, BarFrame)

  -- INDICATOR (predictor power)

      -- create the indicator frame.
      local IndicatorFrame = CreateFrame('Frame', nil, OffsetFrame)

        -- create the indicator border.
        local IndicatorBorder = CreateFrame('Frame', nil, IndicatorFrame)

          -- create the statusbar for the indicator slider.
          local Indicator = CreateFrame('StatusBar', nil, IndicatorBorder)

  -- SLIDER

      -- Create the slider frame.
      local SliderFrame = CreateFrame('Frame', nil, OffsetFrame)

        -- Create the slider border.
        local SliderBorder = CreateFrame('Frame', nil, SliderFrame)

          -- create the statusbar for slider.
          local Slider = CreateFrame('StatusBar', nil, SliderBorder)

  -- Set Frame levels

  -- Set Sun and Moon to be above the bar.
  MoonBorder:SetFrameLevel(BarLunar:GetFrameLevel() + 1)
  SunBorder:SetFrameLevel(BarSolar:GetFrameLevel() + 1)

  -- Indicator needs to be above everything but the Slider.
  IndicatorFrame:SetFrameLevel(Sun:GetFrameLevel() + 1)

  -- Slider needs to be above everything but text.
  SliderFrame:SetFrameLevel(Indicator:GetFrameLevel() + 1)

  -- Set the text to be above all.
  TxtBorder:SetFrameLevel(Slider:GetFrameLevel() + 1)

  -- Set the moon to dark.
  EclipseFrame.Moon.Dark = true
  MoonFrame:Hide()

  -- Set the sun to dark
  EclipseFrame.Sun.Dark = true
  SunFrame:Hide()

  -- Create fadeout for Sun, Moon, Lunar, and Solar.
  local FadeOut, FadeOutA = Main:CreateFadeOut(MoonFrame)
  MoonFrame.FadeOut = FadeOut
  MoonFrame.FadeOutA = FadeOutA

  FadeOut, FadeOutA = Main:CreateFadeOut(SunFrame)
  SunFrame.FadeOut = FadeOut
  SunFrame.FadeOutA = FadeOutA

  FadeOut, FadeOutA = Main:CreateFadeOut(BarLunar)
  BarLunar.FadeOut = FadeOut
  BarLunar.FadeOutA = FadeOutA

  FadeOut, FadeOutA = Main:CreateFadeOut(BarSolar)
  BarSolar.FadeOut = FadeOut
  BarSolar.FadeOutA = FadeOutA

  -- Save the name for tooltips.
  Main:SetTooltip(MoonBorder,  UB.Name, MouseOverDesc)
  Main:SetTooltip(SunBorder, UB.Name, MouseOverDesc)
  Main:SetTooltip(BarBorder, UB.Name, MouseOverDesc)

  -- Save a reference to the anchor for moving.
  MoonBorder.Anchor = Anchor
  SunBorder.Anchor = Anchor
  BarBorder.Anchor = Anchor

  EclipseFrame.Moon.Frame = MoonFrame
  EclipseFrame.Moon.Border = MoonBorder
  EclipseFrame.Moon.StatusBar = Moon
  EclipseFrame.Sun.Frame = SunFrame
  EclipseFrame.Sun.Border = SunBorder
  EclipseFrame.Sun.StatusBar = Sun
  EclipseFrame.Bar.Frame = BarFrame
  EclipseFrame.Bar.Border = BarBorder
  EclipseFrame.Lunar.Frame = BarLunar
  EclipseFrame.Lunar.Dark = false
  EclipseFrame.Solar.Frame = BarSolar
  EclipseFrame.Solar.Dark = false
  EclipseFrame.Slider.Frame = SliderFrame
  EclipseFrame.Slider.Border = SliderBorder
  EclipseFrame.Slider.StatusBar = Slider
  EclipseFrame.Indicator.Frame = IndicatorFrame
  EclipseFrame.Indicator.Border = IndicatorBorder
  EclipseFrame.Indicator.StatusBar = Indicator

  EclipseFrame.Txt = Txt

  -- Save the borders and Eclipse frames
  UnitBarF.Border = Border
  UnitBarF.TxtBorder = TxtBorder
  UnitBarF.OffsetFrame = OffsetFrame
  UnitBarF.EclipseF = EclipseFrame
end