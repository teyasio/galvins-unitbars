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
--
-- UnitBarF.UnitBar                  Reference to the unitbar data for the holybar.
-- UnitBarF.HolyBar                  Contains the holy bar displayed on screen.
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
--
-- LastHolyPower                     Keeps track if there is a change in the holy bar.
--
-- NOTE: holy bar has two modes.  In BoxMode the holy bar is broken into 3 statusbars.
--       This works just like the combobar.  When not normal mode.  The bar uses textures instead.
-------------------------------------------------------------------------------
local MaxHolyRunes = 3
local HolyRuneWidth = 42
local HolyRuneHeight = 31
local BAR = nil

-- Powertype constants
local PowerHoly = PowerTypeToNumber['HOLY_POWER']

-- Holyrune Texture constants
local HolyRuneBox = 1
local HolyRuneDark = 2
local HolyRuneLight = 3

local LastHolyPower = nil

local HolyPowerTexture = [[Interface\PlayerFrame\PaladinPowerTextures]]
local HolyRunes = {
  DarkColor = {r = 0.15, g = 0.15, b = 0.15, a = 1},
  [1] = {
    Width = 36 + 5, Height = 22 + 5,
    Left = 0.00390625, Right = 0.14453125, Top = 0.64843750, Bottom = 0.82031250
  },
  [2] = {
    Width = 31 + 12, Height = 17 + 12,
    Left = 0.00390625, Right = 0.12500000, Top = 0.83593750, Bottom = 0.96875000
  },
  [3] = {
    Width = 27 + 10 , Height = 21 + 10,
    Left = 0.15234375, Right = 0.25781250, Top = 0.64843750, Bottom = 0.81250000
  }
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
  local Action = nil
  if FinishFadeOut then
    Action = 'finishfadeout'
  end

  for RuneIndex = 1, MaxHolyRunes do
    if RuneIndex <= HolyPower then
      HolyBar:ShowTexture(RuneIndex, HolyRuneBox)
      HolyBar:ShowTexture(RuneIndex, HolyRuneLight)
    else
      HolyBar:HideTexture(RuneIndex, HolyRuneBox, Action)
      HolyBar:HideTexture(RuneIndex, HolyRuneLight, Action)
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
function GUB.UnitBarsF.HolyBar:Update(Event)
  if not self.Enabled then
    return
  end

  local HolyPower = UnitPower('player', PowerHoly)

  -- Return if no change.
  if Event == 'change' and HolyPower == LastHolyPower then
    return
  end

  LastHolyPower = HolyPower

  UpdateHolyRunes(self, HolyPower)

    -- Set this IsActive flag
  self.IsActive = HolyPower > 0

  -- Do a status check for active status.
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
          HolyBar:SetTexture(RuneIndex, HolyRuneBox, Bar.StatusBarTexture)
          HolyBar:SetFillDirection(RuneIndex, HolyRuneBox, Bar.FillDirection)
          HolyBar:SetRotateTexture(RuneIndex, HolyRuneBox, Bar.RotateTexture)
        end
        if Attr == nil or Attr == 'color' then
          local BarColor = nil

          -- Get all color if ColorAll is true.
          if Bar.ColorAll then
            BarColor = Bar.Color
          else
            BarColor = Bar.Color[RuneIndex]
          end
          HolyBar:SetColor(RuneIndex, HolyRuneBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
        end
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      if Attr == nil or Attr == 'padding' then
        HolyBar:SetTexturePadding(0, HolyRuneBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
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
  HolyBar:SetFadeOutTime(0, HolyRuneBox, Gen.HolyFadeOutTime)
  HolyBar:SetFadeOutTime(0, HolyRuneLight, Gen.HolyFadeOutTime)

  -- Check for box mode.
  if Gen.BoxMode then

    -- Set size
    HolyBar:SetBoxSize(UB.Bar.BoxWidth, UB.Bar.BoxHeight)
    HolyBar:SetBoxScale(1)
    HolyBar:SetTextureScale(0, HolyRuneDark, 1)
    HolyBar:SetTextureScale(0, HolyRuneLight, 1)

    -- Hide/show Box mode.
    HolyBar:HideTextureFrame(0, HolyRuneDark)
    HolyBar:HideTextureFrame(0, HolyRuneLight)
    HolyBar:ShowTextureFrame(0, HolyRuneBox)

    HolyBar:HideBorder(nil)
    HolyBar:ShowBorder(0)
  else
    local HolyScale = Gen.HolyScale

    -- Set Size
    HolyBar:SetBoxSize(HolyRuneWidth, HolyRuneHeight)
    HolyBar:SetBoxScale(Gen.HolySize)
    HolyBar:SetTextureScale(0, HolyRuneDark, HolyScale)
    HolyBar:SetTextureScale(0, HolyRuneLight, HolyScale)

    -- Hide/show Texture mode.
    HolyBar:ShowTextureFrame(0, HolyRuneDark)
    HolyBar:ShowTextureFrame(0, HolyRuneLight)
    HolyBar:HideTextureFrame(0, HolyRuneBox)

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
  local DarkColor = HolyRunes.DarkColor

  -- Create the holybar.
  local HolyBar = Bar:CreateBar(ScaleFrame, Anchor, MaxHolyRunes)

  for RuneIndex, HR in ipairs(HolyRunes) do

      -- Create the textures for box and runes.
    HolyBar:CreateBoxTexture(RuneIndex, HolyRuneBox, 'statusbar')
    HolyBar:CreateBoxTexture(RuneIndex, HolyRuneDark, 'texture', 'ARTWORK')
    HolyBar:CreateBoxTexture(RuneIndex, HolyRuneLight, 'texture', 'OVERLAY')

    -- Set the textures
    HolyBar:SetTexture(RuneIndex, HolyRuneDark, HolyPowerTexture)
    HolyBar:SetTexture(RuneIndex, HolyRuneLight, HolyPowerTexture)

    -- Set the holy rune dark texture
    HolyBar:SetTexCoord(RuneIndex, HolyRuneDark, HR.Left, HR.Right, HR.Top, HR.Bottom)

    HolyBar:SetTextureSize(RuneIndex, HolyRuneDark, HR.Width, HR.Height)
    HolyBar:SetDesaturated(RuneIndex, HolyRuneDark, true)
    HolyBar:SetColor(RuneIndex, HolyRuneDark, DarkColor.r, DarkColor.g, DarkColor.b, DarkColor.a)

    -- Set the holy rune light texture
    HolyBar:SetTexCoord(RuneIndex, HolyRuneLight, HR.Left, HR.Right, HR.Top, HR.Bottom)
    HolyBar:SetTextureSize(RuneIndex, HolyRuneLight, HR.Width, HR.Height)

     -- Set and save the name for tooltips for box mode.
    local Name = 'Holy Rune ' .. RuneIndex

    HolyBar:SetTooltip(RuneIndex, Name, MouseOverDesc)

    ColorAllNames[RuneIndex] = Name
  end

  -- Show the dark textures.
  HolyBar:ShowTexture(0 , HolyRuneDark)

  -- Save the name for tooltips for normal mode.
  HolyBar:SetTooltip(nil, UB.Name, MouseOverDesc)

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the holybar
  UnitBarF.HolyBar = HolyBar
end
