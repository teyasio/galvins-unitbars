--
-- EmberBar.lua
--
-- Displays the Warlock Burning Embers bar.

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
-- UnitBarF.UnitBar                  Reference to the unitbar data for the ember bar.
-- UnitBarF.EmberBar                 Contains the ember bar displayed on screen.
--
-- EmberData                         Contains all the data for the ember bar texture.
--   Texture                         Path name to the texture file.
--   TextureWidth, TextureHeight     Box size and size of the TextureFrame for texture mode.
--   [TextureType]
--     Point                         Texture point within the TextureFrame.
--     OffsetX, OffsetY              Offset from the point location of where the texture is placed.
--     Width, Height                 Width and Height of the texture.
--     Left, Right, Top, Bottom      Coordinates inside the main texture for the texture we need.
--
-- EmberBox                          Contains the box for box mode.
-- EmberFieryBox                     Contains the on fire color for box mode.
-- EmberBg                           Background texture for the ember bar.
-- EmberFill                         Fill texture for showing the ember fill up.
-- EmberFire                         Fire texture shown after the ember is filled.
--
-- MaxPowerPerEmber                  Amount of power for each ember.
-- CurrentNumEmbers                  Contains the current number of embers the player has.
--
-- BarOffsetX, BarOffsetY            Offset the whole bar within the border.
-------------------------------------------------------------------------------
local MaxEmbers = 4
local MaxPowerPerEmber = MAX_POWER_PER_EMBER

-- Powertype constants
local PowerEmber = PowerTypeToNumber['BURNING_EMBERS']

local CurrentNumEmbers = nil

-- Ember Texture constants
local EmberBox = 10
local EmberFieryBox = 11
local EmberBg = 1
local EmberFill = 2
local EmberFire = 3

local BarOffsetX = 0
local BarOffsetY = 2

local EmberData = {
  Texture = [[Interface\PlayerFrame\Warlock-DestructionUI]],

  -- TextureFrame size.
  TextureWidth = 36, TextureHeight = 39 + 3,
  [EmberBg] = {
    Level = 0,
    Point = 'BOTTOM',
    OffsetX = 0  + BarOffsetX, OffsetY = 0 + BarOffsetY,
    Width = 36, Height= 39,
    Left = 0.15234375, Right = 0.29296875, Top = 0.32812500, Bottom = 0.93750000,
  },
  [EmberFill] = {
    Level = 1,
    Point = 'BOTTOM',
    OffsetX = 0 + BarOffsetX, OffsetY = 7 + BarOffsetY,
    Width = 20, Height = 22,
    Left = 0.30078125, Right = 0.37890625, Top = 0.32812500, Bottom = 0.67187500,
  },
  [EmberFire] = {
    Level = 2,
    Point = 'BOTTOM',
    OffsetX = 0 + BarOffsetX, OffsetY = 0 + BarOffsetY,
    Width = 36, Height = 39,
    Left = 0.00390625, Right = 0.14453125, Top = 0.32812500, Bottom = 0.93750000,
  }
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
GUB.UnitBarsF.EmberBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Emberbar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateBurningEmbers
--
-- Updates the ember bar.
--
-- Usage: UpdateBurningEmbers(EmberBarF, EmberPower, NumEmbers)
--
-- EmberBarF      The unitbar frame being updated.
-- EmberPower     Total amount of ember power
-- NumEmbers      Number of embers the EmberPower will be displayed across.
-------------------------------------------------------------------------------
local function UpdateBurningEmbers(EmberBarF, EmberPower, NumEmbers)
  local EmberBar = EmberBarF.EmberBar

  for EmberIndex = 1, NumEmbers do

    -- Fill the ember.
    EmberBar:SetTextureFill(EmberIndex, EmberBox, EmberPower / MaxPowerPerEmber)
    EmberBar:SetTextureFill(EmberIndex, EmberFill, EmberPower / MaxPowerPerEmber)

    -- Check to light ember up.
    if EmberPower >= MaxPowerPerEmber then
      EmberBar:ShowTexture(EmberIndex, EmberFire)
      EmberBar:ShowTexture(EmberIndex, EmberFieryBox)
    else
      EmberBar:HideTexture(EmberIndex, EmberFire)
      EmberBar:HideTexture(EmberIndex, EmberFieryBox)
    end

    -- Left over for next ember.
    EmberPower = EmberPower - MaxPowerPerEmber
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the ember bar.
--
-- usage: Update(Event)
--
-- Event         'change' then the bar will only get updated if there is a change.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.EmberBar:Update(Event, Unit, PowerType)

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

  PowerType = PowerType and PowerTypeToNumber[PowerType] or PowerEmber

  -- Return if not the correct powertype.
  if PowerType ~= PowerEmber then
    return
  end

  -- Set the time the bar was updated.
  self.LastTime = GetTime()

  local EmberPower = UnitPower('player', PowerEmber, true)
  local MaxEmberPower = UnitPowerMax('player', PowerEmber, true)
  local NumEmbers = floor(MaxEmberPower / MaxPowerPerEmber)

  -- Set default value if NumEmbers returns zero.
  NumEmbers = NumEmbers > 0 and NumEmbers or MaxEmbers - 1

  -- Check for max ember change
  if NumEmbers ~= CurrentNumEmbers then
    CurrentNumEmbers = NumEmbers

    -- Change the number of boxes in the bar.
    self.EmberBar:SetNumBoxes(NumEmbers)

    -- Update the layout to reflect the change.
    self:SetLayout()
  end

  UpdateBurningEmbers(self, EmberPower, NumEmbers)

    -- Set this IsActive flag
  self.IsActive = EmberPower ~= 10

  -- Do a status check.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- CancelAnimation    UnitBarsF function
--
-- Cancels all animation playing in the ember bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.EmberBar:CancelAnimation()
  -- do nothing.
end

--*****************************************************************************
--
-- emberbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the ember bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.EmberBar:EnableMouseClicks(Enable)
  local EmberBar = self.EmberBar

  -- Enable/Disable normal mode.
  EmberBar:SetEnableMouseClicks(nil, Enable)

  -- Enable/disable box mode.
  EmberBar:SetEnableMouseClicks(0, Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScript    UnitBarsF function
--
-- Set up script handlers for the Emberbar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.EmberBar:FrameSetScript()
  local EmberBar = self.EmberBar

  -- Enable normal mode. for the bar.
  EmberBar:SetEnableMouse(nil)

  -- Enable box mode.
  EmberBar:SetEnableMouse(0)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the Emberbar.
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
function GUB.UnitBarsF.EmberBar:SetAttr(Object, Attr)
  local EmberBar = self.EmberBar

  -- Check scale and strata for 'frame'
  Main:UnitBarSetAttr(self, Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Border = self.Border

  -- Check if we're in boxmode.
  if UB.General.BoxMode then
    local Bar = UB.Bar
    local BarFiery = UB.BarFiery
    local Background = UB.Background
    local Padding = Bar.Padding
    local BackdropSettings = Background.BackdropSettings

    for EmberIndex = 1, MaxEmbers do

      -- Background (Border).
      if Object == nil or Object == 'bg' then
        local BgColor = nil

        -- Get all color if ColorAll is true.
        if Background.ColorAll then
          BgColor = Background.Color
        else
          BgColor = Background.Color[EmberIndex]
        end

        if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
          EmberBar:SetBackdrop(EmberIndex, BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
      end

      -- Forground (Statusbar).
      if Object == nil or Object == 'bar' then
        if Attr == nil or Attr == 'texture' then
          EmberBar:SetTexture(EmberIndex, EmberBox, Bar.StatusBarTexture)
          EmberBar:SetFillDirection(EmberIndex, EmberBox, Bar.FillDirection)
          EmberBar:SetRotateTexture(EmberIndex, EmberBox, Bar.RotateTexture)

          EmberBar:SetTexture(EmberIndex, EmberFieryBox, Bar.FieryStatusBarTexture)
          EmberBar:SetFillDirection(EmberIndex, EmberFieryBox, Bar.FillDirection)
          EmberBar:SetRotateTexture(EmberIndex, EmberFieryBox, Bar.RotateTexture)
        end
        if Attr == nil or Attr == 'color' then
          local BarColor = nil
          local BarFieryColor = nil

          -- Get all color if ColorAll is true.
          if Bar.ColorAll then
            BarColor = Bar.Color
          else
            BarColor = Bar.Color[EmberIndex]
          end
          if BarFiery.ColorAll then
            BarFieryColor = BarFiery.Color
          else
            BarFieryColor = BarFiery.Color[EmberIndex]
          end
          EmberBar:SetColor(EmberIndex, EmberBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
          EmberBar:SetColor(EmberIndex, EmberFieryBox, BarFieryColor.r, BarFieryColor.g, BarFieryColor.b, BarFieryColor.a)
        end
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      if Attr == nil or Attr == 'padding' then
        EmberBar:SetTexturePadding(0, EmberBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
        EmberBar:SetTexturePadding(0, EmberFieryBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
      end
    end
  else

    -- Else in normal bar mode.

    -- Background (Border).
    if Object == nil or Object == 'bg' then
      local Border = self.Border

      local BgColor = UB.Background.Color

      if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
        EmberBar:SetBackdrop(nil, UB.Background.BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayout    UnitBarsF function
--
-- Set an ember bar to a new layout
-------------------------------------------------------------------------------
function GUB.UnitBarsF.EmberBar:SetLayout()
  local EmberBar = self.EmberBar

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = self.UnitBar.General

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Set padding and rotation and fadeout
  EmberBar:SetPadding(0, Gen.EmberPadding)
  EmberBar:SetAngle(Gen.EmberAngle)

  -- Check for box mode.
  if Gen.BoxMode then

    -- Set size
    EmberBar:SetBoxSize(UB.Bar.BoxWidth, UB.Bar.BoxHeight)
    EmberBar:SetBoxScale(1)

    -- Hide/show Box mode.
    EmberBar:HideTextureFrame(0, EmberBg)
    EmberBar:HideTextureFrame(0, EmberFill)
    EmberBar:HideTextureFrame(0, EmberFire)
    EmberBar:ShowTextureFrame(0, EmberBox)
    EmberBar:ShowTextureFrame(0, EmberFieryBox)

    EmberBar:HideBorder(nil)
    EmberBar:ShowBorder(0)
  else

    -- Texture mode
    local EmberScale = Gen.EmberScale

    -- Set Size
    EmberBar:SetBoxSize(EmberData.TextureWidth, EmberData.TextureHeight)
    EmberBar:SetBoxScale(Gen.EmberSize)
    EmberBar:SetTextureScale(0, EmberBg, EmberScale)
    EmberBar:SetTextureScale(0, EmberFill, EmberScale)
    EmberBar:SetTextureScale(0, EmberFire, EmberScale)

    -- Hide/show Texture mode.
    EmberBar:ShowTextureFrame(0, EmberBg)
    EmberBar:ShowTextureFrame(0, EmberFill)
    EmberBar:ShowTextureFrame(0, EmberFire)
    EmberBar:HideTextureFrame(0, EmberBox)
    EmberBar:HideTextureFrame(0, EmberFieryBox)

    EmberBar:HideBorder(0)
    EmberBar:ShowBorder(nil)
  end

  -- Display the ember bar.
  self:SetSize(EmberBar:Display())
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- Usage: GUB.EmberBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the ember bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.EmberBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
  local ColorAllNames = {}

  -- Create the emberbar.
  local EmberBar = Bar:CreateBar(ScaleFrame, Anchor, MaxEmbers)

  for EmberIndex = 1, MaxEmbers do

    -- Create burning ember for box mode.
    EmberBar:CreateBoxTexture(EmberIndex, EmberBox, 'statusbar', 0)

    -- Create the fiery ember for box mode.
    EmberBar:CreateBoxTexture(EmberIndex, EmberFieryBox, 'statusbar', 1)

    for TextureNumber, ED in ipairs(EmberData) do

      -- Create the textures for the ember bar.
      EmberBar:CreateBoxTexture(EmberIndex, TextureNumber, 'texture', ED.Level,
                                EmberData.TextureWidth, EmberData.TextureHeight)

      -- Set the texture.
      EmberBar:SetTexture(EmberIndex, TextureNumber, EmberData.Texture)

      -- Set the texcoords for each texture
      EmberBar:SetTexCoord(EmberIndex, TextureNumber, ED.Left, ED.Right, ED.Top, ED.Bottom)

      -- Set texture size.
      EmberBar:SetTextureSize(EmberIndex, TextureNumber, ED.Width, ED.Height,
                              ED.Point, ED.OffsetX, ED.OffsetY)
    end

    -- Show the ember background and fill
    EmberBar:ShowTexture(EmberIndex, EmberBg)
    EmberBar:ShowTexture(EmberIndex, EmberBox)
    EmberBar:ShowTexture(EmberIndex, EmberFill)

    -- Set default fill.
    EmberBar:SetFillDirection(EmberIndex, EmberBox, 'VERTICAL')
    EmberBar:SetFillDirection(EmberIndex, EmberFill, 'VERTICAL')

    -- Set and save the name for tooltips for each ember.
    local Name = strconcat('Burning Ember ', EmberIndex)

    EmberBar:SetTooltip(EmberIndex, Name, MouseOverDesc)

    ColorAllNames[EmberIndex] = Name
  end

  -- Save the name for tooltips for normal mode.
  EmberBar:SetTooltip(nil, UB.Name, MouseOverDesc)

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the emberbar
  UnitBarF.EmberBar = EmberBar
end

--*****************************************************************************
--
-- Emberbar Enable/Disable functions
--
--*****************************************************************************

function GUB.UnitBarsF.EmberBar:Enable(Enable)
  Main:RegEvent(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end


