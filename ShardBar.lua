--
-- ShardBar.lua
--
-- Displays the Warlock shard bar.

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
-- UnitBarF.UnitBar                  Reference to the unitbar data for the shard bar.
-- UnitBarF.ShardBar                 Contains the shard bar displayed on screen.
--
-- ShardData                         Contains all the data for the soul shards texture.
--   Texture                         Path name to the texture file.
--   Point                           Texture position inside the texture frame.
--   Width                           Width of the texture and box size in texture mode.
--   Height                          Height of the texture and box size in texture mode.
--   Left, Right, Top, Bottom        Coordinates inside the main texture for the texture we need.
-- SoulShardDarkColor                Used to make the light colored soulshard texture dark.
--
-- ShardBox                          Soul shard in box mode.  Statusbar
-- ShardDark                         Dark soul shard when not lit.
-- ShardLight                        Light sould shard used for lighting a dark soul shard.
-------------------------------------------------------------------------------
local MaxSoulShards = 4

-- Powertype constants
local PowerShard = PowerTypeToNumber['SOUL_SHARDS']

-- Soulshard Texture constants
local ShardBox = 1
local ShardDark = 2
local ShardLight = 3

local ShardData = {
  Texture = [[Interface\PlayerFrame\UI-WarlockShard]],
  Point = 'CENTER',
  Width = 17 + 15, Height = 16 + 15,
  Left = 0.01562500, Right = 0.28125000, Top = 0.00781250, Bottom = 0.13281250
}
local SoulShardDarkColor = {r = 0.25, g = 0.25, b = 0.25, a = 1}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
GUB.UnitBarsF.ShardBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Shardbar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateSoulShards
--
-- Lights or darkens the soul shards
--
-- Usage: UpdateSoulShards(ShardBarF, SoulShards, NumShards, FinishFade)
--
-- ShardBarF        SoulShard bar containing shards to update.
-- SoulShards       Total amount of shards to light up.
-- NumShards        Total amount of shards that can be displayed.
-------------------------------------------------------------------------------
local function UpdateSoulShards(ShardBarF, SoulShards, NumShards, FinishFade)
  local ShardBar = ShardBarF.ShardBar

  for ShardIndex = 1, NumShards do

    -- Light the shard.
    if ShardIndex <= SoulShards then
      ShardBar:ShowTexture(ShardIndex, ShardBox)
      ShardBar:ShowTexture(ShardIndex, ShardLight)
    else

      -- Darken the shard.
      ShardBar:HideTexture(ShardIndex, ShardBox)
      ShardBar:HideTexture(ShardIndex, ShardLight)
    end
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of shards of the player
--
-- Usage: Update(Event, Unit, PowerType)
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShardBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and PowerTypeToNumber[PowerType] or PowerShard

  -- Return if not the correct powertype.
  if PowerType ~= PowerShard then
    return
  end

  local SoulShards = UnitPower('player', PowerShard)
  local NumShards = UnitPowerMax('player', PowerShard)

  -- Set default value if NumShards returns zero.
  NumShards = NumShards > 0 and NumShards or MaxSoulShards - 1

  -- Check for total shard change.
  if NumShards ~= self.NumShards then
    local ShardBar = self.ShardBar

    -- Change the number of boxes in the bar.
    ShardBar:SetNumBoxes(NumShards)

    -- Update the layout to reflect the change.
    self:SetLayout()

    self.NumShards = NumShards

  -- Reduce cpu usage by checking for soulshard change.
  -- This is because unit_power_frequent is firing off more than it should.
  elseif SoulShards == self.SoulShards then
    return
  end

  self.SoulShards = SoulShards
  UpdateSoulShards(self, SoulShards, NumShards)

  -- Set the IsActive flag.
  self.IsActive = SoulShards < NumShards

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Shardbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the shard bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShardBar:EnableMouseClicks(Enable)
  local ShardBar = self.ShardBar

  -- Enable/Disable normal mode.
  ShardBar:SetEnableMouseClicks(nil, Enable)

  -- Enable/disable box mode.
  ShardBar:SetEnableMouseClicks(0, Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScript    UnitBarsF function
--
-- Set up script handlers for the Shardbar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShardBar:FrameSetScript()
  local ShardBar = self.ShardBar

  -- Enable normal mode. for the bar.
  ShardBar:SetEnableMouse(nil)

  -- Enable box mode.
  ShardBar:SetEnableMouse(0)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the shardbar.
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
function GUB.UnitBarsF.ShardBar:SetAttr(Object, Attr)
  local ShardBar = self.ShardBar

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

    for ShardIndex = 1, MaxSoulShards do

      -- Background (Border).
      if Object == nil or Object == 'bg' then
        local BgColor = nil

        -- Get all color if ColorAll is true.
        if Background.ColorAll then
          BgColor = Background.Color
        else
          BgColor = Background.Color[ShardIndex]
        end

        if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
          ShardBar:SetBackdrop(ShardIndex, BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
      end

      -- Forground (Statusbar).
      if Object == nil or Object == 'bar' then
        if Attr == nil or Attr == 'texture' then
          ShardBar:SetTexture(ShardIndex, ShardBox, Bar.StatusBarTexture)
          ShardBar:SetRotateTexture(ShardIndex, ShardBox, Bar.RotateTexture)
        end
        if Attr == nil or Attr == 'color' then
          local BarColor = nil

          -- Get all color if ColorAll is true.
          if Bar.ColorAll then
            BarColor = Bar.Color
          else
            BarColor = Bar.Color[ShardIndex]
          end
          ShardBar:SetColor(ShardIndex, ShardBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
        end
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      if Attr == nil or Attr == 'padding' then
        ShardBar:SetStatusBarPadding(0, ShardBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
      end
    end
  else

    -- Else in texture mode.

    -- Background (Border).
    if Object == nil or Object == 'bg' then
      local BgColor = UB.Background.Color

      if Attr == nil or Attr == 'backdrop' or Attr == 'color' then
        ShardBar:SetBackdrop(nil, UB.Background.BackdropSettings, BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayout    UnitBarsF function
--
-- Set a shardbar to a new layout
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShardBar:SetLayout()
  local ShardBar = self.ShardBar

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = self.UnitBar.General
  local ShardFadeInTime = Gen.ShardFadeInTime
  local ShardFadeOutTime = Gen.ShardFadeOutTime

  -- Convert old shard size to a default of 1.
  if Gen.ShardSize > 9 then
    Gen.ShardSize = 1
  end

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Set padding and rotation and fade.
  ShardBar:SetPadding(0, Gen.ShardPadding)
  ShardBar:SetAngle(Gen.ShardAngle)
  ShardBar:SetFadeTime(0, ShardBox, 'in', ShardFadeInTime)
  ShardBar:SetFadeTime(0, ShardLight, 'in', ShardFadeInTime)
  ShardBar:SetFadeTime(0, ShardBox, 'out', ShardFadeOutTime)
  ShardBar:SetFadeTime(0, ShardLight, 'out', ShardFadeOutTime)

  -- Check for box mode.
  if Gen.BoxMode then

    -- Set size
    ShardBar:SetBoxSize(UB.Bar.BoxWidth, UB.Bar.BoxHeight)
    ShardBar:SetBoxScale(1)

    -- Stop any fading animation.
    ShardBar:StopFade(0, ShardBox)

    -- Hide/show Box mode.
    ShardBar:HideTextureFrame(0, ShardDark)
    ShardBar:HideTextureFrame(0, ShardLight)
    ShardBar:ShowTextureFrame(0, ShardBox)

    ShardBar:HideBorder(nil)
    ShardBar:ShowBorder(0)
  else

    -- Texture mode
    local ShardScale = Gen.ShardScale

    -- Set Size
    ShardBar:SetBoxSize(ShardData.Width, ShardData.Height)
    ShardBar:SetBoxScale(Gen.ShardSize)
    ShardBar:SetTextureScale(0, ShardDark, ShardScale)
    ShardBar:SetTextureScale(0, ShardLight, ShardScale)

    -- Stop any fading animation.
    ShardBar:StopFade(0, ShardLight)

    -- Hide/show Texture mode.
    ShardBar:ShowTextureFrame(0, ShardDark)
    ShardBar:ShowTextureFrame(0, ShardLight)
    ShardBar:HideTextureFrame(0, ShardBox)

    ShardBar:HideBorder(0)
    ShardBar:ShowBorder(nil)
  end

  -- Display the shardbar.
  self:SetSize(ShardBar:Display())
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- Usage: GUB.ShardBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the shard bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ShardBar:CreateBar(UnitBarF, UB, Anchor, ScaleFrame)
  local ColorAllNames = {}

  -- Create the shardbar.
  local ShardBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxSoulShards)

  for ShardIndex = 1, MaxSoulShards do

      -- Create the textures for box and runes.
    ShardBar:CreateBoxTexture(ShardIndex, ShardBox, 'statusbar', 0)
    ShardBar:CreateBoxTexture(ShardIndex, ShardDark, 'texture', 0, ShardData.Width, ShardData.Height)
    ShardBar:CreateBoxTexture(ShardIndex, ShardLight, 'texture', 1, ShardData.Width, ShardData.Height)

    -- Set the textures
    ShardBar:SetTexture(ShardIndex, ShardDark, ShardData.Texture)
    ShardBar:SetTexture(ShardIndex, ShardLight, ShardData.Texture)

    -- Set the soulshard dark texture
    ShardBar:SetTexCoord(ShardIndex, ShardDark, ShardData.Left, ShardData.Right, ShardData.Top, ShardData.Bottom)

    ShardBar:SetTextureSize(ShardIndex, ShardDark, ShardData.Width, ShardData.Height)
    ShardBar:SetDesaturated(ShardIndex, ShardDark, true)
    ShardBar:SetColor(ShardIndex, ShardDark, SoulShardDarkColor.r, SoulShardDarkColor.g, SoulShardDarkColor.b, SoulShardDarkColor.a)

    -- Set the soulshard light texture
    ShardBar:SetTexCoord(ShardIndex, ShardLight, ShardData.Left, ShardData.Right, ShardData.Top, ShardData.Bottom)
    ShardBar:SetTextureSize(ShardIndex, ShardLight, ShardData.Width, ShardData.Height)

    -- Set texture points.
    ShardBar:SetTexturePoint(ShardIndex, ShardDark, ShardData.Point)
    ShardBar:SetTexturePoint(ShardIndex, ShardLight, ShardData.Point)

     -- Set and save the name for tooltips for each shard.
    local Name = 'Soul Shard ' .. ShardIndex

    ShardBar:SetTooltip(ShardIndex, Name, MouseOverDesc)

    ColorAllNames[ShardIndex] = Name
  end

  -- Show the dark textures.
  ShardBar:ShowTexture(0 , ShardDark)

  -- Save the name for tooltips for normal mode.
  ShardBar:SetTooltip(nil, UB.Name, MouseOverDesc)

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the shardbar
  UnitBarF.ShardBar = ShardBar
end

--*****************************************************************************
--
-- Shardbar Enable/Disable functions
--
--*****************************************************************************

function GUB.UnitBarsF.ShardBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end
