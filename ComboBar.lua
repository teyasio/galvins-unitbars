--
-- ComboBar.lua
--
-- Displays 5 rectangles for combo points.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
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
-- UnitBarF.UnitBar                    Reference to the unitbar data for the combobar.
-- UnitBarF.ComboBar                   Contains the combo bar displayed on screen.
-- LastComboPoints                     Keeps track of change in the combo bar.
-------------------------------------------------------------------------------
local MaxComboPoints = 5
local ComboBox = 1
local LastComboPoints = nil

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
GUB.UnitBarsF.ComboBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Combobar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateComboPoints
--
-- Lights or darkens combo point boxes.
--
-- Usage: UpdateComboPoints(ComboBarF, ComboPoints, FinishFadeOut)
--
-- ComboPointF      ComboBar containing combo points to update.
-- ComboPoints      Updates the combo points based on the combopoints.
-- FinishFadeOut    If true then any fadeout animation currently playing
--                  will be stopped.
--                  If nil or false then does nothing.
-------------------------------------------------------------------------------
local function UpdateComboPoints(ComboBarF, ComboPoints, FinishFadeOut)
  local ComboBar = ComboBarF.ComboBar
  if FinishFadeOut then
    ComboBar:StopFade(0, ComboBox)
    return
  end

  for ComboIndex = 1, MaxComboPoints do
    if ComboIndex <= ComboPoints then
      ComboBar:ShowTexture(ComboIndex, ComboBox)
    else
      ComboBar:HideTexture(ComboIndex, ComboBox)
    end
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Usage: Update(Event)
--
-- Event         'change' then the bar will only get updated if there is a change.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ComboBar:Update(Event)
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

  -- Set the time the bar was updated.
  self.LastTime = GetTime()

  -- Get the combo points.
  local ComboPoints = GetComboPoints('player', 'target')

  -- Return if no change.
  if Event == 'change' and ComboPoints == LastComboPoints then
    return
  end

  LastComboPoints = ComboPoints

  -- Display the combo points
  UpdateComboPoints(self, ComboPoints)

  -- Set the IsActive flag
  self.IsActive = ComboPoints > 0 and 1 or -1

  -- Do a status check.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- CancelAnimation    UnitBarsF function
--
-- Cancels all animation playing in the combo bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ComboBar:CancelAnimation()
  UpdateComboPoints(self, 0, true)
end

--*****************************************************************************
--
-- Combobar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbale mouse clicks for the combo bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ComboBar:EnableMouseClicks(Enable)
  local ComboBar = self.ComboBar

  -- Enable/disable bar.
  ComboBar:SetEnableMouseClicks(0, Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScript    UnitBarsF function
--
-- Set up script handlers for the Combobar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ComboBar:FrameSetScript()

  -- Enable bar.
  self.ComboBar:SetEnableMouse(0)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the combobar.
--
-- Usage: SetAttr(Object, Attr)
--
-- Object       Object being changed:
--               'bg' for background (Border).
--               'bar' for forground (StatusBar).
--               'frame' for the frame.
-- Attr         Type of attribute being applied to object:
--               'color'   Color being set to the object.
--               'size'    Size being set to the object.
--               'padding' Amount of padding set to the object.
--               'texture' One or more textures set to the object.
--               'scale'   Scale settings being set to the object.
--               'strata'  Frame strata for the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ComboBar:SetAttr(Object, Attr)
  local ComboBar = self.ComboBar

  -- Check scale and strata for 'frame'
  Main:UnitBarSetAttr(self, Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Border = self.Border

  -- Check if we're in boxmode.
  local Bar = UB.Bar
  local Background = UB.Background
  local Padding = Bar.Padding
  local BackdropSettings = Background.BackdropSettings

  for ComboIndex = 1, MaxComboPoints do

    -- Background (Border).
    if Object == nil or Object == 'bg' then
      local BgColor = nil

      -- Get all color if ColorAll is true.
      if Background.ColorAll then
        BgColor = Background.Color
      else
        BgColor = Background.Color[ComboIndex]
      end

      if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
        ComboBar:SetBackdrop(ComboIndex, BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      if Attr == nil or Attr == 'texture' then
        ComboBar:SetTexture(ComboIndex, ComboBox, Bar.StatusBarTexture)
        ComboBar:SetFillDirection(ComboIndex, ComboBox, Bar.FillDirection)
        ComboBar:SetRotateTexture(ComboIndex, ComboBox, Bar.RotateTexture)
      end
      if Attr == nil or Attr == 'color' then
        local BarColor = nil

        -- Get all color if ColorAll is true.
        if Bar.ColorAll then
          BarColor = Bar.Color
        else
          BarColor = Bar.Color[ComboIndex]
        end
        ComboBar:SetColor(ComboIndex, ComboBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
      end
    end
  end

  -- Forground (Statusbar).
  if Object == nil or Object == 'bar' then
    if Attr == nil or Attr == 'padding' then
      ComboBar:SetTexturePadding(0, ComboBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayout    UnitBarsF function
--
-- Sets a combo bar with a new layout.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ComboBar:SetLayout()
  local ComboBar = self.ComboBar

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = self.UnitBar.General

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Set padding and rotation and fadeout
  ComboBar:SetPadding(0, Gen.ComboPadding)
  ComboBar:SetAngle(Gen.ComboAngle)
  ComboBar:SetFadeOutTime(0, ComboBox, Gen.ComboFadeOutTime)

  -- Set size
  ComboBar:SetBoxSize(UB.Bar.BoxWidth, UB.Bar.BoxHeight)

  self:SetSize(ComboBar:Display())
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- Usage: GUB.ComboBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the combo bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ComboBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
  local ColorAllNames = {}

  -- Create the combo bar.
  local ComboBar = Bar:CreateBar(ScaleFrame, Anchor, MaxComboPoints)

  for ComboIndex = 1, MaxComboPoints do

      -- Create the textures for the boxes.
    ComboBar:CreateBoxTexture(ComboIndex, ComboBox, 'statusbar')

     -- Set and save the name for tooltips.
    local Name = 'Combo Point ' .. ComboIndex

    ComboBar:SetTooltip(ComboIndex, Name, MouseOverDesc)

    ColorAllNames[ComboIndex] = Name
  end

  -- Show the texture frames.
  ComboBar:ShowTextureFrame(0, ComboBox)

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the combo bar and frames.
  UnitBarF.ComboBar = ComboBar
end

--*****************************************************************************
--
-- Combobar Enable/Disable functions
--
--*****************************************************************************

function GUB.UnitBarsF.ComboBar:Enable(Enable)
  -- Combo bar doesn't use events.
end

