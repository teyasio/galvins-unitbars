--
-- HolyBar.lua
--
-- Displays Paldin holy power.

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
-- UnitBarF.UnitBar                  Reference to the unitbar data for the holybar.
-- UnitBarF.HolyBar                  Contains the holy bar displayed on screen.
--
-- RuneBox                           Holy rune for box mode.
-- RuneDark                          Dark holy rune texture for texture mode.
-- RuneLight                         Lit holy rune texture for texture mode.
--
-- HolyData                          Contains the data to create the holy bar.
--   Texture                         Texture that contains the holy runes.
--   BoxWidth, BoxHeight             Size of the boxes in texture mode.
--   Runes[Rune].Width               Width of the rune texture.
--   [Rune Number]
--     Point                         Texture point inside the texture frame.
--     OffsetX, OffsetY              Offset the texture inside the texture frame.
--     Width, Height                 Width and Height of the rune texture and the texture frame.
--     Left, Right, Top, Bottom      Texture coordinates inside of the HolyPowerTexture
--                                   containing the holy rune.
--
-- LastHolyPower                     Keeps track if there is a change in the holy bar.
-------------------------------------------------------------------------------
local MaxHolyRunes = 5

-- Powertype constants
local PowerHoly = PowerTypeToNumber['HOLY_POWER']

-- Holyrune Texture constants
local RuneBox = 1
local RuneDark = 2
local RuneLight = 3

local LastHolyPower = nil

local HolyData = {
  Texture = [[Interface\PlayerFrame\PaladinPowerTextures]],

  -- TextureFrame size.
  BoxWidth = 42 + 8, BoxHeight = 31,
  DarkColor = {r = 0.15, g = 0.15, b = 0.15, a = 1},
  [1] = {
    Point = 'CENTER',
    OffsetX = 1, OffsetY = 0,
    Width = 36 + 5, Height = 22 + 5,
    Left = 0.00390625, Right = 0.14453125, Top = 0.78906250, Bottom = 0.96093750
  },
  [2] = {
    Point = 'CENTER',
    OffsetX = 1, OffsetY = 0,
    Width = 31 + 14, Height = 17 + 14,
    Left = 0.15234375, Right = 0.27343750, Top = 0.78906250, Bottom = 0.92187500
  },
  [3] = {
    Point = 'CENTER',
    OffsetX = 0, OffsetY = 0,
    Width = 27 + 10 , Height = 21 + 10,
    Left = 0.28125000, Right = 0.38671875, Top = 0.64843750, Bottom = 0.81250000
  },
  [4] = {  -- Rune1 texture that's rotated.
    Point = 'CENTER',
    OffsetX = -1, OffsetY = 0,
    Width = 36 + 5, Height = 17 + 12,
    Left = 0.14453125, Right = 0.00390625, Top = 0.78906250, Bottom = 0.96093750
  },
  [5] = {  -- Rune2 texture that's rotated.
    Point = 'CENTER',
    OffsetX = -1, OffsetY = 0,
    Width = 31 + 14, Height = 17 + 14,
    Left = 0.27343750, Right = 0.15234375, Top = 0.78906250, Bottom = 0.92187500
  },
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
GUB.UnitBarsF.HolyBar.StatusCheck = GUB.Main.StatusCheck

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
  local HolyBar = HolyBarF.HolyBar
  if FinishFadeOut then
    HolyBar:StopFade(0, RuneBox)
    HolyBar:StopFade(0, RuneLight)
    return
  end

  for RuneIndex = 1, MaxHolyRunes do
    if RuneIndex <= HolyPower then
      HolyBar:ShowTexture(RuneIndex, RuneBox)
      HolyBar:ShowTexture(RuneIndex, RuneLight)
    else
      HolyBar:HideTexture(RuneIndex, RuneBox)
      HolyBar:HideTexture(RuneIndex, RuneLight)
    end
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the holy power level of the player
--
-- usage: Update(Event)
--
-- Event         'change' then the bar will only get updated if there is a change.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.HolyBar:Update(Event, PowerType)
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

  PowerType = PowerType and PowerTypeToNumber[PowerType] or PowerHoly

  -- Return if not the correct powertype.
  if PowerType ~= PowerHoly then
    return
  end

  -- Set the time the bar was updated.
  self.LastTime = GetTime()

  local HolyPower = UnitPower('player', PowerHoly)

  -- Return if no change.
  if Event == 'change' and HolyPower == LastHolyPower then
    return
  end

  LastHolyPower = HolyPower

  UpdateHolyRunes(self, HolyPower)

    -- Set this IsActive flag
  self.IsActive = HolyPower > 0 and 1 or -1

  -- Do a status check.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- CancelAnimation    UnitBarsF function
--
-- Cancels all animation playing in the holy bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.HolyBar:CancelAnimation()
  UpdateHolyRunes(self, 0, true)
end

--*****************************************************************************
--
-- Holybar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the holy bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.HolyBar:EnableMouseClicks(Enable)
  local HolyBar = self.HolyBar

  -- Enable/Disable normal mode.
  HolyBar:SetEnableMouseClicks(nil, Enable)

  -- Enable/disable box mode.
  HolyBar:SetEnableMouseClicks(0, Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScript    UnitBarsF function
--
-- Set up script handlers for the Holybar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.HolyBar:FrameSetScript()
  local HolyBar = self.HolyBar

  -- Enable normal mode. for the bar.
  HolyBar:SetEnableMouse(nil)

  -- Enable box mode.
  HolyBar:SetEnableMouse(0)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the holybar.
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
--               'padding'   Amount of padding set to the object.
--               'texture'   One or more textures set to the object.
--               'strata'    Frame strata for the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.HolyBar:SetAttr(Object, Attr)
  local HolyBar = self.HolyBar

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

    for RuneIndex = 1, MaxHolyRunes do

      -- Background (Border).
      if Object == nil or Object == 'bg' then
        local BgColor = nil

        -- Get all color if ColorAll is true.
        if Background.ColorAll then
          BgColor = Background.Color
        else
          BgColor = Background.Color[RuneIndex]
        end

        if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
          HolyBar:SetBackdrop(RuneIndex, BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
      end

      -- Forground (Statusbar).
      if Object == nil or Object == 'bar' then
        if Attr == nil or Attr == 'texture' then
          HolyBar:SetTexture(RuneIndex, RuneBox, Bar.StatusBarTexture)
          HolyBar:SetFillDirection(RuneIndex, RuneBox, Bar.FillDirection)
          HolyBar:SetRotateTexture(RuneIndex, RuneBox, Bar.RotateTexture)
        end
        if Attr == nil or Attr == 'color' then
          local BarColor = nil

          -- Get all color if ColorAll is true.
          if Bar.ColorAll then
            BarColor = Bar.Color
          else
            BarColor = Bar.Color[RuneIndex]
          end
          HolyBar:SetColor(RuneIndex, RuneBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
        end
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      if Attr == nil or Attr == 'padding' then
        HolyBar:SetTexturePadding(0, RuneBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
      end
    end
  else

    -- Else in normal bar mode.

    -- Background (Border).
    if Object == nil or Object == 'bg' then
      local Border = self.Border

      local BgColor = UB.Background.Color

      if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
        HolyBar:SetBackdrop(nil, UB.Background.BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayout    UnitBarsF function
--
-- Set a holybar to a new layout
-------------------------------------------------------------------------------
function GUB.UnitBarsF.HolyBar:SetLayout()
  local HolyBar = self.HolyBar

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = self.UnitBar.General

  -- Convert old holy size to a default of 1.
  if Gen.HolySize > 9 then
    Gen.HolySize = 1
  end

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Set padding and rotation and fadeout
  HolyBar:SetPadding(0, Gen.HolyPadding)
  HolyBar:SetAngle(Gen.HolyAngle)
  HolyBar:SetFadeOutTime(0, RuneBox, Gen.HolyFadeOutTime)
  HolyBar:SetFadeOutTime(0, RuneLight, Gen.HolyFadeOutTime)

  -- Check for box mode.
  if Gen.BoxMode then

    -- Set size
    HolyBar:SetBoxSize(UB.Bar.BoxWidth, UB.Bar.BoxHeight)
    HolyBar:SetBoxScale(1)
    HolyBar:SetTextureScale(0, RuneDark, 1)
    HolyBar:SetTextureScale(0, RuneLight, 1)

    -- Hide/show Box mode.
    HolyBar:HideTextureFrame(0, RuneDark)
    HolyBar:HideTextureFrame(0, RuneLight)
    HolyBar:ShowTextureFrame(0, RuneBox)

    HolyBar:HideBorder(nil)
    HolyBar:ShowBorder(0)
  else

    -- Texture mode.
    local HolyScale = Gen.HolyScale

    -- Set Size
    HolyBar:SetBoxSize(HolyData.BoxWidth, HolyData.BoxHeight)
    HolyBar:SetBoxScale(Gen.HolySize)
    HolyBar:SetTextureScale(0, RuneDark, HolyScale)
    HolyBar:SetTextureScale(0, RuneLight, HolyScale)

    -- Hide/show Texture mode.
    HolyBar:ShowTextureFrame(0, RuneDark)
    HolyBar:ShowTextureFrame(0, RuneLight)
    HolyBar:HideTextureFrame(0, RuneBox)

    HolyBar:HideBorder(0)
    HolyBar:ShowBorder(nil)
  end

  -- Display the holybar.
  self:SetSize(HolyBar:Display())
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- Usage: GUB.HolyBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the holy rune bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.HolyBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
  local ColorAllNames = {}
  local DarkColor = HolyData.DarkColor

  -- Create the holybar.
  local HolyBar = Bar:CreateBar(ScaleFrame, Anchor, MaxHolyRunes)

  for RuneIndex, HD in ipairs(HolyData) do

      -- Create the textures for box and runes.
    HolyBar:CreateBoxTexture(RuneIndex, RuneBox, 'statusbar')
    HolyBar:CreateBoxTexture(RuneIndex, RuneDark, 'texture', 0, HD.Width, HD.Height)
    HolyBar:CreateBoxTexture(RuneIndex, RuneLight, 'texture', 1, HD.Width, HD.Height)

    -- Set the textures
    HolyBar:SetTexture(RuneIndex, RuneDark, HolyData.Texture)
    HolyBar:SetTexture(RuneIndex, RuneLight, HolyData.Texture)

    -- Set the holy rune dark texture
    HolyBar:SetTexCoord(RuneIndex, RuneDark, HD.Left, HD.Right, HD.Top, HD.Bottom)

    HolyBar:SetTextureSize(RuneIndex, RuneDark, HD.Width, HD.Height, HD.Point, HD.OffsetX, HD.OffsetY)
    HolyBar:SetDesaturated(RuneIndex, RuneDark, true)
    HolyBar:SetColor(RuneIndex, RuneDark, DarkColor.r, DarkColor.g, DarkColor.b, DarkColor.a)

    -- Set the holy rune light texture
    HolyBar:SetTexCoord(RuneIndex, RuneLight, HD.Left, HD.Right, HD.Top, HD.Bottom)
    HolyBar:SetTextureSize(RuneIndex, RuneLight, HD.Width, HD.Height, HD.Point, HD.OffsetX, HD.OffsetY)

     -- Set and save the name for tooltips for box mode.
    local Name = 'Holy Rune ' .. RuneIndex

    HolyBar:SetTooltip(RuneIndex, Name, MouseOverDesc)

    ColorAllNames[RuneIndex] = Name
  end

  -- Show the dark textures.
  HolyBar:ShowTexture(0 , RuneDark)

  -- Save the name for tooltips for normal mode.
  HolyBar:SetTooltip(nil, UB.Name, MouseOverDesc)

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the holybar
  UnitBarF.HolyBar = HolyBar
end

--*****************************************************************************
--
-- Holybar Enable/Disable functions
--
--*****************************************************************************

function GUB.UnitBarsF.HolyBar:Enable(Enable)
  Main:RegEvent(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end
