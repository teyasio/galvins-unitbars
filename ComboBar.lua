--
-- ComboBar.lua
--
-- Displays 5 rectangles for combo points.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.ComboBar = {}
local Main = GUB.Main
local Bar = GUB.Bar

-- shared from Main.lua
local LSM = Main.LSM
local MouseOverDesc = Main.MouseOverDesc

-- localize some globals.
local _
local bitband,  bitbxor,  bitbor,  bitlshift =
      bit.band, bit.bxor, bit.bor, bit.lshift
local pcall, abs, mod, max, floor, strsub, strupper, strconcat, tostring, pairs, ipairs, type, math, table, select =
      pcall, abs, mod, max, floor, strsub, strupper, strconcat, tostring, pairs, ipairs, type, math, table, select
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType
local GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection, GetInventoryItemID

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.UnitBar                    Reference to the unitbar data for the combobar.
-- UnitBarF.ComboBar                   Contains the combo bar displayed on screen.
-- LastComboPoints                     Keeps track of change in the combo bar.
-------------------------------------------------------------------------------
local MaxComboPoints = 5
local ComboBarBox = 1
local LastComboPoints = nil

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
  local Action = nil
  if FinishFadeOut then
    Action = 'finishfadeout'
  end

  for ComboIndex = 1, MaxComboPoints do
    if ComboIndex <= ComboPoints then
      ComboBar:ShowTexture(ComboIndex, ComboBarBox)
    else
      ComboBar:HideTexture(ComboIndex, ComboBarBox, Action)
    end
  end
end

-------------------------------------------------------------------------------
-- UpdateComboBar (Update) [UnitBar assigned function]
--
-- Usage: UpdateComboBar(Event)
--
-- Event         'change' then the bar will only get updated if there is a change.
-------------------------------------------------------------------------------
function GUB.ComboBar:UpdateComboBar(Event)

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
  self.IsActive = ComboPoints > 0

  -- Do a status check for active status.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- CancelAnimationCombo (CancelAnimation) [UnitBar assigned function]
--
-- Usage: CancelAnimationCombo()
--
-- Cancels all animation playing in the combo bar.
-------------------------------------------------------------------------------
function GUB.ComboBar:CancelAnimationCombo()
  UpdateComboPoints(self, 0, true)
end

--*****************************************************************************
--
-- Combobar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicksCombo (EnableMouseClicks) [UnitBar assigned function]
--
-- This will enable or disbale mouse clicks for the combo bar.
-------------------------------------------------------------------------------
function GUB.ComboBar:EnableMouseClicksCombo(Enable)
  local ComboBar = self.ComboBar

  -- Enable/disable bar.
  ComboBar:SetEnableMouseClicks(0, Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScriptCombo (FrameSetScript) [UnitBar assigned function]
--
-- Set up script handlers for the Combobar.
-------------------------------------------------------------------------------
function GUB.ComboBar:FrameSetScriptCombo()

  -- Enable bar.
  self.ComboBar:SetEnableMouse(0)
end

-------------------------------------------------------------------------------
-- EnableScreenClampCombo (EnableScreenClamp) [UnitBar assigned function]
--
-- Enables or disble screen clamp for the combo bar.
-------------------------------------------------------------------------------
function GUB.ComboBar:EnableScreenClampCombo(Enable)
  self.ComboBar:SetClamp(Enable)
end

-------------------------------------------------------------------------------
-- SetAttrCombo  (SetAttr) [UnitBar assigned function]
--
-- Sets different parts of the combobar.
--
-- Usage: SetAttrCombo(Object, Attr)
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
function GUB.ComboBar:SetAttrCombo(Object, Attr)
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
        ComboBar:SetTexture(ComboIndex, ComboBarBox, Bar.StatusBarTexture)
        ComboBar:SetFillDirection(ComboIndex, ComboBarBox, Bar.FillDirection)
        ComboBar:SetRotateTexture(ComboIndex, ComboBarBox, Bar.RotateTexture)
      end
      if Attr == nil or Attr == 'color' then
        local BarColor = nil

        -- Get all color if ColorAll is true.
        if Bar.ColorAll then
          BarColor = Bar.Color
        else
          BarColor = Bar.Color[ComboIndex]
        end
        ComboBar:SetColor(ComboIndex, ComboBarBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
      end
    end
  end

  -- Forground (Statusbar).
  if Object == nil or Object == 'bar' then
    if Attr == nil or Attr == 'padding' then
      ComboBar:SetTexturePadding(0, ComboBarBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayoutCombo (SetLayout) [UnitBar assigned function]
--
-- Sets a combo bar with a new layout.
--
-- Usage: SetLayoutCombo()
-------------------------------------------------------------------------------
function GUB.ComboBar:SetLayoutCombo()
  local ComboBar = self.ComboBar

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = self.UnitBar.General

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Set padding and rotation and fadeout
  ComboBar:SetPadding(0, Gen.ComboPadding)
  ComboBar:SetAngle(Gen.ComboAngle)
  ComboBar:SetFadeOutTime(0, ComboBarBox, Gen.ComboFadeOutTime)

  -- Set size
  ComboBar:SetBoxSize(UB.Bar.BoxWidth, UB.Bar.BoxHeight)

  -- Display the combo bar.
  self.Width, self.Height = ComboBar:Display()
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
    ComboBar:CreateBoxTexture(ComboIndex, ComboBarBox, 'statusbar')

     -- Set and save the name for tooltips.
    local Name = strconcat('Combo Point ', ComboIndex)

    ComboBar:SetTooltip(ComboIndex, Name, MouseOverDesc)

    ColorAllNames[ComboIndex] = Name
  end

  -- Show the texture frames.
  ComboBar:ShowTextureFrame(0, ComboBarBox)

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the combo bar
  UnitBarF.ComboBar = ComboBar
end
