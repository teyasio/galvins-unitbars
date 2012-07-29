--
-- DemonicBar.lua
--
-- Displays the Warlock demonic fury bar.

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
-- UnitBarF.UnitBar                  Reference to the unitbar data for the demonic bar.
-- UnitBarF.DemonicBar               Contains the demonic bar displayed on screen.

-- FuryBox                           Demonic Fury in box mode statusbar.
-- FuryBG                            Background for the demonic bar texture.
-- FuryBar                           The bar that shows how much demonic fury is present.
-- FuryBarMeta                       Like FuryBar except shown in metamorphosis.
-- FuryBorder                        Texture that fits around the demonic bar.
-- FuryBorderMeta                    Like FuryBorder except shown in metamorphosis.
-- FuryNotch                         Shows the 20% mark on the normal bar.
-- FuryNotchMeta                     Shows the 20% mark on the metamorphosis bar.
--                                   These 8 variables are used to reference the different textures/statusbar.
--
-- LastDemonicFury                   Keeps track of change in demonic fury.
-- MaxDemonicFury                    Keeps track if max demonic fury changes.
--
-- BarOffsetX, BarOffsetY            Offset the whole bar within the border.
--
-- MetaBuff                          SpellID for the metamorphosis buff.
-- MetaActive                        True then you have the metamorphosis buff, otherwise no.
-- DemonicData                Table containing all the data to build the demonic fury bar.
--   Texture                         Path to the texture file.
--   BoxWidth, BoxHeight             Width and Height of the bars border for texture mode.
--   TextureWidth, TextureHeight     Size of all the TextureFrames in the bar.
--   [TextureType]                   Texture Number containing the type of texture to use.
--      Point                        Setpoint() position.
--      Level                        Texture level that the texture is displayed on.
--      OffsetX, OffsetY             Offset from the point location of where the texture is placed.
--      Width, Height                Width and Height of the texture.
--      Left, Right, Top, Bottom     Texcoordinates of the texture.
-------------------------------------------------------------------------------

-- Powertype constants
local PowerDemonicFury = PowerTypeToNumber['DEMONIC_FURY']

local FuryBox = 10
local FuryBg = 1
local FuryBar = 2
local FuryBarMeta = 3
local FuryBorder = 4
local FuryBorderMeta = 5
local FuryNotch = 6
local FuryNotchMeta = 7

local MetaBuff = 103958 -- Warlock metamorphosis spell ID buff.
local MetaActive = false

local BarOffsetX = 2
local BarOffsetY = 0

local DemonicData = {
  Texture = [[Interface\PlayerFrame\Warlock-DemonologyUI]],
  BoxWidth = 145, BoxHeight = 35,

  -- TextureFrame size
  TextureWidth = 169, TextureHeight = 52,
  [FuryBg] = {
    Level = 0,
    Point = 'CENTER',
    OffsetX = -2 + BarOffsetX, OffsetY = -1 + BarOffsetY,
    Width = 132, Height= 24,
    Left = 0.03906250, Right = 0.55468750, Top = 0.20703125, Bottom = 0.30078125
  },
  [FuryBar] = {
    Level = 1,
    Point = 'LEFT',
    OffsetX = 17 + BarOffsetX, OffsetY = -1 + BarOffsetY,
    Width = 132, Height = 24,
    Left = 0.03906250, Right = 0.55468750, Top= 0.10546875, Bottom = 0.19921875
  },
  [FuryBarMeta] = {
    Level = 1,
    Point = 'LEFT',
    OffsetX = 17 + BarOffsetX, OffsetY = -1 + BarOffsetY,
    Width = 132, Height = 24,
    Left = 0.03906250, Right = 0.55468750, Top = 0.00390625, Bottom = 0.09765625
  },
  [FuryBorder] = {
    Level = 2,
    Point = 'LEFT',
    OffsetX = 0 + BarOffsetX, OffsetY = 0 + BarOffsetY,
    Width = 169, Height = 52,
    Left = 0.03906250, Right = 0.69921875, Top = 0.51953125, Bottom = 0.72265625
  },
  [FuryBorderMeta] = {
    Level = 2,
    Point = 'LEFT',
    OffsetX = 0 + BarOffsetX, OffsetY = 0 + BarOffsetY,
    Width = 169, Height = 52,
    Left = 0.03906250, Right = 0.69921875, Top = 0.30859375, Bottom = 0.51171875
  },
  [FuryNotch] = {
    Level = 3,
    Point = 'LEFT',
    OffsetX = 40 + BarOffsetX, OffsetY = -1 + BarOffsetY,
    Width = 7, Height = 22,
    Left = 0.00390625, Right = 0.03125000, Top = 0.09765625, Bottom = 0.18359375
  },
  [FuryNotchMeta] = {
    Level = 3,
    Point = 'LEFT',
    OffsetX = 40 + BarOffsetX, OffsetY = -1 + BarOffsetY,
    Width = 7, Height = 22,
    Left = 0.00390625, Right = 0.03125000, Top = 0.00390625, Bottom = 0.08984375
  }
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
GUB.UnitBarsF.DemonicBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Demonicbar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateDemonicFury
--
-- Updates demonic fury and metamorphosis.
--
-- Usage: UpdateDemonicFury(DemonicBarF, DemonicFury)
--
-- DemonicBarF      Demonic fury bar to be updated.
-- DemonicFury      Shows the amount of demonic fury to be displayed.
-------------------------------------------------------------------------------

-- Used by SetTextValues to calculate percentage.
local function PercentFn(Value, MaxValue)
  return floor(abs(Value / MaxValue * 100))
end

local function UpdateDemonicFury(DemonicBarF, DemonicFury, CurrValue, MaxValue)
  local DemonicBar = DemonicBarF.DemonicBar

  DemonicBar:SetTextureFill(1, FuryBox, DemonicFury)
  DemonicBar:SetTextureFill(1, FuryBar, DemonicFury)
  DemonicBar:SetTextureFill(1, FuryBarMeta, DemonicFury)

    -- Update display values.
  local returnOK, msg = Main:SetTextValues(DemonicBarF.UnitBar.Text.TextType, DemonicBarF.Txt, PercentFn, CurrValue, MaxValue)
  if not returnOK then
    DemonicBarF.Txt:SetText('Layout Err Text')
  end

  returnOK, msg = Main:SetTextValues(DemonicBarF.UnitBar.Text2.TextType, DemonicBarF.Txt2, PercentFn, CurrValue, MaxValue)
  if not returnOK then
    DemonicBarF.Txt2:SetText('Layout Err Text2')
  end
end
-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the amount of demonic fury.
--
-- usage: Update(Event)
--
-- Event         'change' then the bar will only get updated if there is a change.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.DemonicBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible then
    if self.IsActive == 0 then
      if Event == nil then
        return
      end
    else
      return
    end
  end

  PowerType = PowerType and PowerTypeToNumber[PowerType] or PowerDemonicFury

  -- Return if not the correct powertype.
  if PowerType ~= PowerDemonicFury then
    return
  end

  -- Set the time the bar was updated.
  self.LastTime = GetTime()

  local DemonicFury = UnitPower('player', PowerDemonicFury)
  local MaxDemonicFury = UnitPowerMax('player', PowerDemonicFury)

  -- Check for metamorphosis.
  local Meta = Main:CheckAura('o', MetaBuff)
  local DemonicBar = self.DemonicBar

  -- If meta then change texture or box color.
  MetaActive = self.MetaActive or false
  if Meta and not MetaActive then
    DemonicBar:HideTexture(1, FuryBar)
    DemonicBar:HideTexture(1, FuryBorder)
    DemonicBar:HideTexture(1, FuryNotch)
    DemonicBar:ShowTexture(1, FuryBarMeta)
    DemonicBar:ShowTexture(1, FuryBorderMeta)
    DemonicBar:ShowTexture(1, FuryNotchMeta)

    local BarColor = self.UnitBar.Bar.ColorMeta
    DemonicBar:SetColor(1, FuryBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)

   self.MetaActive = true
  elseif not Meta and MetaActive then
    DemonicBar:ShowTexture(1, FuryBar)
    DemonicBar:ShowTexture(1, FuryBorder)
    DemonicBar:ShowTexture(1, FuryNotch)
    DemonicBar:HideTexture(1, FuryBarMeta)
    DemonicBar:HideTexture(1, FuryBorderMeta)
    DemonicBar:HideTexture(1, FuryNotchMeta)

    local BarColor = self.UnitBar.Bar.Color
    DemonicBar:SetColor(1, FuryBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)

    self.MetaActive = false
  end

  local Value = 0
  -- Check for device by zero
  if MaxDemonicFury > 0 then
    Value = DemonicFury / MaxDemonicFury
  end
  UpdateDemonicFury(self, Value, DemonicFury, MaxDemonicFury)

    -- Set this IsActive flag when not 20% or in metamorphosis.
  self.IsActive = Value ~= 0.20 or MetaActive

  -- Do a status check.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- CancelAnimation    UnitBarsF function
--
-- Cancels all animation playing in the demonic bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.DemonicBar:CancelAnimation()
  -- do nothing.
end

--*****************************************************************************
--
-- Demonicbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the demonic bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.DemonicBar:EnableMouseClicks(Enable)
  local DemonicBar = self.DemonicBar
  DemonicBar:SetEnableMouseClicks(nil, Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScript    UnitBarsF function
--
-- Set up script handlers for the Demonicbar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.DemonicBar:FrameSetScript()
  local DemonicBar = self.DemonicBar
  DemonicBar:SetEnableMouse(nil)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the Demonic bar.
--
-- Usage: SetAttr(Object, Attr)
--
-- Object       Object being changed:
--               'bg' for background (Border).
--               'bar' for forground (StatusBar).
--               'text' for text.
--               'text2' for text2.
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
function GUB.UnitBarsF.DemonicBar:SetAttr(Object, Attr)
  local DemonicBar = self.DemonicBar

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

    -- Background (Border).
    if Object == nil or Object == 'bg' then
      local BgColor = Background.Color
      if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
        DemonicBar:SetBackdrop(1, BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      if Attr == nil or Attr == 'texture' then
        DemonicBar:SetTexture(1, FuryBox, Bar.StatusBarTexture)
        DemonicBar:SetFillDirection(1, FuryBox, Bar.FillDirection)
        DemonicBar:SetRotateTexture(1, FuryBox, Bar.RotateTexture)
      end
      if Attr == nil or Attr == 'color' then
        local BarColor = nil
        if not MetaActive then
          BarColor = Bar.Color
        else
          BarColor = Bar.ColorMeta
        end
        DemonicBar:SetColor(1, FuryBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
      end
      if Attr == nil or Attr == 'padding' then
        DemonicBar:SetTexturePadding(1, FuryBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
      end
    end
  end

  -- Text (self.Txt).
  if Object == nil or Object == 'text' then
    local Txt = self.Txt

    local TextColor = UB.Text.Color

    if Attr == nil or Attr == 'font' then
      Main:SetFontString(Txt, UB.Text.FontSettings)
    end
    if Attr == nil or Attr == 'color' then
      Txt:SetTextColor(TextColor.r, TextColor.g, TextColor.b, TextColor.a)
    end
  end

  -- Text2 (self.Txt2).
  if Object == nil or Object == 'text2' then
    local Txt = self.Txt2

    local TextColor = UB.Text2.Color

    if Attr == nil or Attr == 'font' then
      Main:SetFontString(Txt, UB.Text2.FontSettings)
    end
    if Attr == nil or Attr == 'color' then
      Txt:SetTextColor(TextColor.r, TextColor.g, TextColor.b, TextColor.a)
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayout    UnitBarsF function
--
-- Set a demonicbar to a new layout
-------------------------------------------------------------------------------
function GUB.UnitBarsF.DemonicBar:SetLayout()
  local DemonicBar = self.DemonicBar

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = self.UnitBar.General

  -- Check for box mode.
  if Gen.BoxMode then

    -- Set size.
    DemonicBar:SetBoxSize(UB.Bar.BoxWidth, UB.Bar.BoxHeight)

    -- Hide/show Box mode.
    DemonicBar:HideTextureFrame(1, FuryBg)
    DemonicBar:HideTextureFrame(1, FuryBar)
    DemonicBar:HideTextureFrame(1, FuryBarMeta)
    DemonicBar:HideTextureFrame(1, FuryBorder)
    DemonicBar:HideTextureFrame(1, FuryBorderMeta)
    DemonicBar:HideTextureFrame(1, FuryNotch)
    DemonicBar:HideTextureFrame(1, FuryNotchMeta)
    DemonicBar:ShowTextureFrame(1, FuryBox)
    DemonicBar:ShowBorder(1)
  else

    -- Set size
    DemonicBar:SetBoxSize(DemonicData.BoxWidth, DemonicData.BoxHeight)

    -- Hide/show Texture mode.
    DemonicBar:ShowTextureFrame(1, FuryBg)
    DemonicBar:ShowTextureFrame(1, FuryBar)
    DemonicBar:ShowTextureFrame(1, FuryBarMeta)
    DemonicBar:ShowTextureFrame(1, FuryBorder)
    DemonicBar:ShowTextureFrame(1, FuryBorderMeta)
    DemonicBar:ShowTextureFrame(1, FuryNotch)
    DemonicBar:ShowTextureFrame(1, FuryNotchMeta)
    DemonicBar:HideTextureFrame(1, FuryBox)
    DemonicBar:HideBorder(1)
  end

  -- Display the demonic bar.
  self:SetSize(DemonicBar:Display())
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- Usage: GUB.DemonicBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the demonic bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.DemonicBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)

  -- Create the demonicbar.
  local DemonicBar = Bar:CreateBar(ScaleFrame, Anchor, 1)

  -- Create the demonic bar for box mode.
  DemonicBar:CreateBoxTexture(1, FuryBox, 'statusbar', 0)

  -- Create the demonic bar for texture mode.
  for TextureNumber, DD in ipairs(DemonicData) do

    -- Create the textures for the demonic bar.
    DemonicBar:CreateBoxTexture(1, TextureNumber, 'texture', DD.Level, DemonicData.TextureWidth, DemonicData.TextureHeight)

    -- Set the texture.
    DemonicBar:SetTexture(1, TextureNumber, DemonicData.Texture)

    -- Set the texcoords for each texture
    DemonicBar:SetTexCoord(1, TextureNumber, DD.Left, DD.Right, DD.Top, DD.Bottom)

    -- Set texture size.
    DemonicBar:SetTextureSize(1, TextureNumber, DD.Width, DD.Height,
                              DD.Point, DD.OffsetX, DD.OffsetY)
  end

  -- Create Txt and Txt2 for displaying power.
  UnitBarF.Txt = DemonicBar:CreateFontString()
  UnitBarF.Txt2 = DemonicBar:CreateFontString()

  -- Show textures.
  DemonicBar:ShowTexture(1, FuryBox)
  DemonicBar:ShowTexture(1, FuryBg)
  DemonicBar:ShowTexture(1, FuryBar)
  DemonicBar:ShowTexture(1, FuryBorder)
  DemonicBar:ShowTexture(1, FuryNotch)

  -- Save the name for tooltips for normal mode.
  DemonicBar:SetTooltip(nil, UB.Name, MouseOverDesc)

  -- Save the demonic bar
  UnitBarF.DemonicBar = DemonicBar
end

--*****************************************************************************
--
-- Demonicbar Enable/Disable functions
--
--*****************************************************************************

function GUB.UnitBarsF.DemonicBar:Enable(Enable)
  Main:RegEvent(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end
