--
-- ChiBar.lua
--
-- Displays the monk chi bar.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
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
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, GetSpellInfo, GetTalentInfo, PlaySound =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, GetSpellInfo, GetTalentInfo, PlaySound
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
-- UnitBarF.UnitBar               Reference to the unitbar data for the chi bar.
-- UnitBarF.ChiBar                Contains the chi bar displayed on screen.
-------------------------------------------------------------------------------
local MaxChiOrbs = 5

-- Powertype constants
local PowerChi = PowerTypeToNumber['LIGHT_FORCE']

-- shadow orbs Texture constants
local OrbBox = 10
local OrbDark = 1
local OrbLight = 2

local LastOrbs = nil
local CurrentNumOrbs = nil

local ChiData = {
  Texture = [[Interface\PlayerFrame\MonkUI]],
  TextureWidth = 21 + 8, TextureHeight = 21 + 8,
  [OrbDark] = {
    Level = 0,
    Point = 'CENTER',
    Width = 21, Height = 21,
    Left = 0.09375000, Right = 0.17578125, Top = 0.71093750, Bottom = 0.87500000
  },
  [OrbLight] = {
    Level = 1,
    Point = 'CENTER',
    Width = 21, Height = 21,
    Left = 0.00390625, Right = 0.08593750, Top = 0.71093750, Bottom = 0.87500000
  },
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
GUB.UnitBarsF.ChiBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Chibar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateChiOrbs
--
-- Glows or darkens the shadow orbs
--
-- Usage: UpdateChiOrbs(ChiBarF, Orbs, FinishFadeOut)
--
-- ChiBarF       Chi bar containing orbs to update.
-- Orbs             Total amount of orbs to glow.
-- FinishFadeOut    If true then any fadeout animation currently playing
--                  will be stopped.
--                  If nil or false then does nothing.
-------------------------------------------------------------------------------
local function UpdateChiOrbs(ChiBarF, Orbs, NumOrbs, FinishFadeOut)
  local ChiBar = ChiBarF.ChiBar
  if FinishFadeOut then
    ChiBar:StopFade(0, OrbBox)
    ChiBar:StopFade(0, OrbLight)
    return
  end

  for OrbIndex = 1, NumOrbs do

    -- Make the orb glow.
    if OrbIndex <= Orbs then
      ChiBar:ShowTexture(OrbIndex, OrbBox)
      ChiBar:ShowTexture(OrbIndex, OrbLight)
    else

      -- Make the orb dark.
      ChiBar:HideTexture(OrbIndex, OrbBox)
      ChiBar:HideTexture(OrbIndex, OrbLight)
    end
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of chi orbs of the player
--
-- usage: Update(Event)
--
-- Event         'change' then the bar will only get updated if there is a change.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ChiBar:Update(Event, Unit, PowerType)
  if not self.Visible then

    -- Check to see if bar is waiting for activity.
    if self.IsActive == 0 then
      if Event == nil or Event == 'change' then
        return
      end
    else
      return
    end
  end

  PowerType = PowerType and PowerTypeToNumber[PowerType] or PowerChi

  -- Return if not the correct powertype.
  if PowerType ~= PowerChi then
    return
  end

  -- Set the time the bar was updated.
  self.LastTime = GetTime()

  local Orbs = UnitPower('player', PowerChi)
  local NumOrbs = UnitPowerMax('player', PowerChi)

  -- Set default value if NumShards returns zero.
  NumOrbs = NumOrbs > 0 and NumOrbs or MaxChiOrbs - 1

  -- Return if no change.
  if Event == 'change' and Orbs == LastOrbs and NumOrbs == CurrentNumOrbs then
    return
  end

  LastOrbs = Orbs

  -- Check for max soulshard change
  if NumOrbs ~= CurrentNumOrbs then
    CurrentNumOrbs = NumOrbs

    -- Change the number of boxes in the bar.
    self.ChiBar:SetNumBoxes(NumOrbs)

    -- Update the layout to reflect the change.
    self:SetLayout()
  end

  UpdateChiOrbs(self, Orbs, NumOrbs)

    -- Set this IsActive flag
  self.IsActive = Orbs > 0 and 1 or -1

  -- Do a status check.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- CancelAnimation    UnitBarsF function
--
-- Cancels all animation playing in the chi bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ChiBar:CancelAnimation()
  UpdateChiOrbs(self, 0, MaxChiOrbs, true)
end

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the chi bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ChiBar:EnableMouseClicks(Enable)
  local ChiBar = self.ChiBar

  -- Enable/Disable normal mode.
  ChiBar:SetEnableMouseClicks(nil, Enable)

  -- Enable/disable box mode.
  ChiBar:SetEnableMouseClicks(0, Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScript    UnitBarsF function
--
-- Set up script handlers for the chibar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ChiBar:FrameSetScript()
  local ChiBar = self.ChiBar

  -- Enable normal mode. for the bar.
  ChiBar:SetEnableMouse(nil)

  -- Enable box mode.
  ChiBar:SetEnableMouse(0)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the chibar.
--
-- Usage: SetAttr(Object, Attr)
--
-- Object       Object being changed:
--               'bg' for background (Border).
--               'bar' for forground (StatusBar).
--               'frame' for the frame.
-- Attr         Type of attribute being applied to object:
--               'color'     Color being set to the object.
--               'backdrop'  Backdrop settings being set to the object.
--               'scale'     Scale settings being set to the object.
--               'padding' Amount of padding set to the object.
--               'texture' One or more textures set to the object.
--               'strata'    Frame strata for the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ChiBar:SetAttr(Object, Attr)
  local ChiBar = self.ChiBar

  -- Check scale and strata for 'frame'
  Main:UnitBarSetAttr(self, Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Border = self.Border

  -- Check if we're in boxmode.
  if UB.General.BoxMode then
    local Bar = UB.Bar
    local Background = UB.Background
    local Padding = Bar.Padding
    local BackdropSettings = Background.BackdropSettings

    for OrbIndex = 1, MaxChiOrbs do

      -- Background (Border).
      if Object == nil or Object == 'bg' then
        local BgColor = nil

        -- Get all color if ColorAll is true.
        if Background.ColorAll then
          BgColor = Background.Color
        else
          BgColor = Background.Color[OrbIndex]
        end

        if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
          ChiBar:SetBackdrop(OrbIndex, BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
      end

      -- Forground (Statusbar).
      if Object == nil or Object == 'bar' then
        if Attr == nil or Attr == 'texture' then
          ChiBar:SetTexture(OrbIndex, OrbBox, Bar.StatusBarTexture)
          ChiBar:SetFillDirection(OrbIndex, OrbBox, Bar.FillDirection)
          ChiBar:SetRotateTexture(OrbIndex, OrbBox, Bar.RotateTexture)
        end
        if Attr == nil or Attr == 'color' then
          local BarColor = nil

          -- Get all color if ColorAll is true.
          if Bar.ColorAll then
            BarColor = Bar.Color
          else
            BarColor = Bar.Color[OrbIndex]
          end
          ChiBar:SetColor(OrbIndex, OrbBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
        end
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      if Attr == nil or Attr == 'padding' then
        ChiBar:SetTexturePadding(0, OrbBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
      end
    end
  else

    -- Else in normal bar mode.

    -- Background (Border).
    if Object == nil or Object == 'bg' then
      local Border = self.Border

      local BgColor = UB.Background.Color

      if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
        ChiBar:SetBackdrop(nil, UB.Background.BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayout    UnitBarsF function
--
-- Set a chibar to a new layout
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ChiBar:SetLayout()
  local ChiBar = self.ChiBar

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = self.UnitBar.General

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Set padding and rotation and fade times.
  ChiBar:SetPadding(0, Gen.ChiPadding)
  ChiBar:SetAngle(Gen.ChiAngle)
  ChiBar:SetFadeOutTime(0, OrbBox, Gen.ChiFadeOutTime)
  ChiBar:SetFadeOutTime(0, OrbLight, Gen.ChiFadeOutTime)
  ChiBar:SetFadeInTime(0, OrbBox, Gen.ChiFadeInTime)
  ChiBar:SetFadeInTime(0, OrbLight, Gen.ChiFadeInTime)

  -- Check for box mode.
  if Gen.BoxMode then

    -- Set size
    ChiBar:SetBoxSize(UB.Bar.BoxWidth, UB.Bar.BoxHeight)
    ChiBar:SetBoxScale(1)

    -- Hide/show Box mode.
    ChiBar:HideTextureFrame(0, OrbDark)
    ChiBar:HideTextureFrame(0, OrbLight)
    ChiBar:ShowTextureFrame(0, OrbBox)

    ChiBar:HideBorder(nil)
    ChiBar:ShowBorder(0)
  else

    -- Texture mode
    local ChiScale = Gen.ChiScale

    -- Set Size
    ChiBar:SetBoxSize(ChiData.TextureWidth, ChiData.TextureHeight)
    ChiBar:SetBoxScale(Gen.ChiSize)
    ChiBar:SetTextureScale(0, OrbDark, ChiScale)
    ChiBar:SetTextureScale(0, OrbLight, ChiScale)

    -- Hide/show Texture mode.
    ChiBar:ShowTextureFrame(0, OrbDark)
    ChiBar:ShowTextureFrame(0, OrbLight)
    ChiBar:HideTextureFrame(0, OrbBox)

    ChiBar:HideBorder(0)
    ChiBar:ShowBorder(nil)
  end

  -- Display the chibar.
  self:SetSize(ChiBar:Display())
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- Usage: GUB.ChiBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the chi bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ChiBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
  local ColorAllNames = {}

  -- Create the chibar.
  local ChiBar = Bar:CreateBar(ScaleFrame, Anchor, MaxChiOrbs)

  for OrbIndex = 1, MaxChiOrbs do

    -- Create chi orb for box mode.
    ChiBar:CreateBoxTexture(OrbIndex, OrbBox, 'statusbar')

    for TextureNumber, SD in ipairs(ChiData) do

      -- Create the textures for orb.
      ChiBar:CreateBoxTexture(OrbIndex, TextureNumber, 'texture', SD.Level, ChiData.TextureWidth, ChiData.TextureHeight)

      -- Set the textures
      ChiBar:SetTexture(OrbIndex, TextureNumber, ChiData.Texture)

      -- Set the chi orb texture
      ChiBar:SetTexCoord(OrbIndex, TextureNumber, SD.Left, SD.Right, SD.Top, SD.Bottom)

      -- Set the size of the texture
      if TextureNumber == OrbLight then
        ChiBar:SetTextureSize(OrbIndex, TextureNumber, SD.Width, SD.Height, SD.Point, 0, 0)
      else
        ChiBar:SetTextureSize(OrbIndex, TextureNumber, SD.Width, SD.Height, SD.Point, 0, 0)
      end
    end

     -- Set and save the name for tooltips for each chi orb.
    local Name = strconcat('Chi Orb ', OrbIndex)

    ChiBar:SetTooltip(OrbIndex, Name, MouseOverDesc)

    ColorAllNames[OrbIndex] = Name
  end

  -- Show the dark textures.
  ChiBar:ShowTexture(0 , OrbDark)

  -- Save the name for tooltips for normal mode.
  ChiBar:SetTooltip(nil, UB.Name, MouseOverDesc)

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the chibar.
  UnitBarF.ChiBar = ChiBar
end

--*****************************************************************************
--
-- Chibar Enable/Disable functions
--
--*****************************************************************************

function GUB.UnitBarsF.ChiBar:Enable(Enable)
  Main:RegEvent(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end
