--
-- ShadowBar.lua
--
-- Displays the Shadow Priest shadow bar.

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

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.UnitBar                  Reference to the unitbar data for the shadow bar.
-- UnitBarF.ShadowBar                Contains the shadow bar displayed on screen.
-------------------------------------------------------------------------------
local MaxShadowOrbs = 3

-- Powertype constants
local PowerShadow = PowerTypeToNumber['SHADOW_ORBS']

-- shadow orbs Texture constants
local OrbBox = 10
local OrbDark = 1
local OrbGlow = 2

local LastOrbs = nil

local ShadowData = {
  Texture = [[Interface\PlayerFrame\Priest-ShadowUI]],
  TextureWidth = 38 + 4, TextureHeight = 37 + 4,
  [OrbDark] = {
    Level = 0,
    Point = 'CENTER',
    Width = 38, Height = 37,
    Left = 0.30078125, Right = 0.44921875, Top = 0.44531250, Bottom = 0.73437500
  },
  [OrbGlow] = {
    Level = 1,
    Point = 'CENTER',
    Width = 38, Height = 37,
    Left = 0.45703125, Right = 0.60546875, Top = 0.44531250, Bottom = 0.73437500
  },
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
GUB.UnitBarsF.ShadowBar.StatusCheck = GUB.Main.StatusCheck

-------------------------------------------------------------------------------
-- UpdateShadowOrbs
--
-- Glows or darkens the shadow orbs
--
-- Usage: UpdateShadowOrbs(ShadowBarF, Orbs, FinishFadeOut)
--
-- ShadowBarF       Shadow bar containing orbs to update.
-- Orbs             Total amount of orbs to glow.
-- FinishFadeOut    If true then any fadeout animation currently playing
--                  will be stopped.
--                  If nil or false then does nothing.
-------------------------------------------------------------------------------
local function UpdateShadowOrbs(ShadowBarF, Orbs, FinishFadeOut)
  local ShadowBar = ShadowBarF.ShadowBar
  if FinishFadeOut then
    ShadowBar:StopFade(0, OrbBox)
    ShadowBar:StopFade(0, OrbGlow)
    return
  end

  for OrbIndex = 1, MaxShadowOrbs do

    -- Make the orb glow.
    if OrbIndex <= Orbs then
      ShadowBar:ShowTexture(OrbIndex, OrbBox)
      ShadowBar:ShowTexture(OrbIndex, OrbGlow)
    else

      -- Make the orb dark.
      ShadowBar:HideTexture(OrbIndex, OrbBox)
      ShadowBar:HideTexture(OrbIndex, OrbGlow)
    end
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of shadow orbs of the player
--
-- usage: Update(Event)
--
-- Event         'change' then the bar will only get updated if there is a change.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShadowBar:Update(Event)
  if not self.Enabled then
    return
  end

  -- Set the time the bar was updated.
  self.LastTime = GetTime()

  local Orbs = UnitPower('player', PowerShadow)

  -- Return if no change.
  if Event == 'change' and Orbs == LastOrbs then
    return
  end

  LastOrbs = Orbs

  UpdateShadowOrbs(self, Orbs)

    -- Set this IsActive flag
  self.IsActive = Orbs > 0

  -- Do a status check for active status.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- CancelAnimation    UnitBarsF function
--
-- Cancels all animation playing in the shadow bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShadowBar:CancelAnimation()
  UpdateShadowOrbs(self, 0, true)
end

--*****************************************************************************
--
-- Shadowbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the shadow bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShadowBar:EnableMouseClicks(Enable)
  local ShadowBar = self.ShadowBar

  -- Enable/Disable normal mode.
  ShadowBar:SetEnableMouseClicks(nil, Enable)

  -- Enable/disable box mode.
  ShadowBar:SetEnableMouseClicks(0, Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScript    UnitBarsF function
--
-- Set up script handlers for the shadowbar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShadowBar:FrameSetScript()
  local ShadowBar = self.ShadowBar

  -- Enable normal mode. for the bar.
  ShadowBar:SetEnableMouse(nil)

  -- Enable box mode.
  ShadowBar:SetEnableMouse(0)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the shadowbar.
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
function GUB.UnitBarsF.ShadowBar:SetAttr(Object, Attr)
  local ShadowBar = self.ShadowBar

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

    for OrbIndex = 1, MaxShadowOrbs do

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
          ShadowBar:SetBackdrop(OrbIndex, BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
      end

      -- Forground (Statusbar).
      if Object == nil or Object == 'bar' then
        if Attr == nil or Attr == 'texture' then
          ShadowBar:SetTexture(OrbIndex, OrbBox, Bar.StatusBarTexture)
          ShadowBar:SetFillDirection(OrbIndex, OrbBox, Bar.FillDirection)
          ShadowBar:SetRotateTexture(OrbIndex, OrbBox, Bar.RotateTexture)
        end
        if Attr == nil or Attr == 'color' then
          local BarColor = nil

          -- Get all color if ColorAll is true.
          if Bar.ColorAll then
            BarColor = Bar.Color
          else
            BarColor = Bar.Color[OrbIndex]
          end
          ShadowBar:SetColor(OrbIndex, OrbBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
        end
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      if Attr == nil or Attr == 'padding' then
        ShadowBar:SetTexturePadding(0, OrbBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
      end
    end
  else

    -- Else in normal bar mode.

    -- Background (Border).
    if Object == nil or Object == 'bg' then
      local Border = self.Border

      local BgColor = UB.Background.Color

      if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
        ShadowBar:SetBackdrop(nil, UB.Background.BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayout    UnitBarsF function
--
-- Set a shadowbar to a new layout
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShadowBar:SetLayout()
  local ShadowBar = self.ShadowBar

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = self.UnitBar.General

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Set padding and rotation and fadeout
  ShadowBar:SetPadding(0, Gen.ShadowPadding)
  ShadowBar:SetAngle(Gen.ShadowAngle)
  ShadowBar:SetFadeOutTime(0, OrbBox, Gen.ShadowFadeOutTime)
  ShadowBar:SetFadeOutTime(0, OrbGlow, Gen.ShadowFadeOutTime)

  -- Check for box mode.
  if Gen.BoxMode then

    -- Set size
    ShadowBar:SetBoxSize(UB.Bar.BoxWidth, UB.Bar.BoxHeight)
    ShadowBar:SetBoxScale(1)

    -- Hide/show Box mode.
    ShadowBar:HideTextureFrame(0, OrbDark)
    ShadowBar:HideTextureFrame(0, OrbGlow)
    ShadowBar:ShowTextureFrame(0, OrbBox)

    ShadowBar:HideBorder(nil)
    ShadowBar:ShowBorder(0)
  else

    -- Texture mode
    local ShadowScale = Gen.ShadowScale

    -- Set Size
    ShadowBar:SetBoxSize(ShadowData.TextureWidth, ShadowData.TextureHeight)
    ShadowBar:SetBoxScale(Gen.ShadowSize)
    ShadowBar:SetTextureScale(0, OrbDark, ShadowScale)
    ShadowBar:SetTextureScale(0, OrbGlow, ShadowScale)

    -- Hide/show Texture mode.
    ShadowBar:ShowTextureFrame(0, OrbDark)
    ShadowBar:ShowTextureFrame(0, OrbGlow)
    ShadowBar:HideTextureFrame(0, OrbBox)

    ShadowBar:HideBorder(0)
    ShadowBar:ShowBorder(nil)
  end

  -- Display the shadowbar.
  self:SetSize(ShadowBar:Display())
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- Usage: GUB.ShadowBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the shadow bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ShadowBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
  local ColorAllNames = {}

  -- Create the shadowbar.
  local ShadowBar = Bar:CreateBar(ScaleFrame, Anchor, MaxShadowOrbs)

  for OrbIndex = 1, MaxShadowOrbs do

    -- Create shadow orb for box mode.
    ShadowBar:CreateBoxTexture(OrbIndex, OrbBox, 'statusbar')

    for TextureNumber, SD in ipairs(ShadowData) do

      -- Create the textures for box and orbs
      ShadowBar:CreateBoxTexture(OrbIndex, TextureNumber, 'texture', SD.Level, ShadowData.TextureWidth, ShadowData.TextureHeight)

      -- Set the textures
      ShadowBar:SetTexture(OrbIndex, TextureNumber, ShadowData.Texture)

      -- Set the shadow orb texture
      ShadowBar:SetTexCoord(OrbIndex, TextureNumber, SD.Left, SD.Right, SD.Top, SD.Bottom)

      -- Set the size of the texture
      ShadowBar:SetTextureSize(OrbIndex, TextureNumber, SD.Width, SD.Height, SD.Point)
    end

     -- Set and save the name for tooltips for each shadow orb.
    local Name = strconcat('Orb ', OrbIndex)

    ShadowBar:SetTooltip(OrbIndex, Name, MouseOverDesc)

    ColorAllNames[OrbIndex] = Name
  end

  -- Show the dark textures.
  ShadowBar:ShowTexture(0 , OrbDark)

  -- Save the name for tooltips for normal mode.
  ShadowBar:SetTooltip(nil, UB.Name, MouseOverDesc)

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the shadowbar
  UnitBarF.ShadowBar = ShadowBar
end

