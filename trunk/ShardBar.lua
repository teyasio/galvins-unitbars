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
-- UnitBarF.UnitBar                  Reference to the unitbar data for the shard bar.
-- UnitBarF.ShardBar                 Contains the shard bar displayed on screen.
--
-- SoulShardTexture                  Contains all the data for the soul shards texture.
--   Texture                         Path name to the texture file.
--   Width                           Width of the texture.
--   Height                          Height of the texture.
--   Left, Right, Top, Bottom        Coordinates inside the main texture for the texture we need.
-- SoulShardDarkColor                Used to make the light colored soulshard texture dark.
--
-- LastSoulShards                    Keeps track of change in the soulshard bar.
--
-- NOTE: SoulShard bar has two modes.  In BoxMode the soulshard bar is broken into 3 statusbars.
--       This works just like the combobar.  When not normal mode.  The bar uses textures instead.
-------------------------------------------------------------------------------
local MaxSoulShards = 3

-- Powertype constants
local PowerShard = PowerTypeToNumber['SOUL_SHARDS']

-- Soulshard Texture constants
local SoulShardBox = 1
local SoulShardDark = 2
local SoulShardLight = 3

local LastSoulShards = nil

local SoulShardTexture = {
        Texture = [[Interface\PlayerFrame\UI-WarlockShard]],
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
-- Usage: UpdateSoulShards(ShardBarF, SoulShards, FinishFadeOut)
--
-- ShardBarF        SoulShard bar containing shards to update.
-- SoulShards       Updates the soul shards based on the number to light up.
-- FinishFadeOut    If true then any fadeout animation currently playing
--                  will be stopped.
--                  If nil or false then does nothing.
-------------------------------------------------------------------------------
local function UpdateSoulShards(ShardBarF, SoulShards, FinishFadeOut)
  local ShardBar = ShardBarF.ShardBar
  local Action = nil
  if FinishFadeOut then
    Action = 'finishfadeout'
  end

  for ShardIndex = 1, MaxSoulShards do
    if ShardIndex <= SoulShards then
      ShardBar:ShowTexture(ShardIndex, SoulShardBox)
      ShardBar:ShowTexture(ShardIndex, SoulShardLight)
    else
      ShardBar:HideTexture(ShardIndex, SoulShardBox, Action)
      ShardBar:HideTexture(ShardIndex, SoulShardLight, Action)
    end
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of shards of the player
--
-- usage: Update(Event)
--
-- Event         'change' then the bar will only get updated if there is a change.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShardBar:Update(Event)
  if not self.Enabled then
    return
  end

  local SoulShards = UnitPower('player', PowerShard)

  -- Return if no change.
  if Event == 'change' and SoulShards == LastSoulShards then
    return
  end

  LastSoulShards = SoulShards

  UpdateSoulShards(self, SoulShards)

    -- Set this IsActive flag
  self.IsActive = SoulShards > 0

  -- Do a status check for active status.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- CancelAnimation    UnitBarsF function
--
-- Cancels all animation playing in the shard bar.
-------------------------------------------------------------------------------
function GUB.UnitBarsF.ShardBar:CancelAnimation()
  UpdateSoulShards(self, 0, true)
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
--               'size'    Size being set to the object.
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
          ShardBar:SetTexture(ShardIndex, SoulShardBox, Bar.StatusBarTexture)
          ShardBar:SetFillDirection(ShardIndex, SoulShardBox, Bar.FillDirection)
          ShardBar:SetRotateTexture(ShardIndex, SoulShardBox, Bar.RotateTexture)
        end
        if Attr == nil or Attr == 'color' then
          local BarColor = nil

          -- Get all color if ColorAll is true.
          if Bar.ColorAll then
            BarColor = Bar.Color
          else
            BarColor = Bar.Color[ShardIndex]
          end
          ShardBar:SetColor(ShardIndex, SoulShardBox, BarColor.r, BarColor.g, BarColor.b, BarColor.a)
        end
      end
    end

    -- Forground (Statusbar).
    if Object == nil or Object == 'bar' then
      if Attr == nil or Attr == 'padding' then
        ShardBar:SetTexturePadding(0, SoulShardBox, Padding.Left, Padding.Right, Padding.Top, Padding.Bottom)
      end
    end
  else

    -- Else in normal bar mode.

    -- Background (Border).
    if Object == nil or Object == 'bg' then
      local Border = self.Border

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

  -- Convert old shard size to a default of 1.
  if Gen.ShardSize > 9 then
    Gen.ShardSize = 1
  end

  -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Set padding and rotation and fadeout
  ShardBar:SetPadding(0, Gen.ShardPadding)
  ShardBar:SetAngle(Gen.ShardAngle)
  ShardBar:SetFadeOutTime(0, SoulShardBox, Gen.ShardFadeOutTime)
  ShardBar:SetFadeOutTime(0, SoulShardLight, Gen.ShardFadeOutTime)

  -- Check for box mode.
  if Gen.BoxMode then

    -- Set size
    ShardBar:SetBoxSize(UB.Bar.BoxWidth, UB.Bar.BoxHeight)
    ShardBar:SetBoxScale(1)
    ShardBar:SetTextureScale(0, SoulShardDark, 1)
    ShardBar:SetTextureScale(0, SoulShardLight, 1)

    -- Hide/show Box mode.
    ShardBar:HideTextureFrame(0, SoulShardDark)
    ShardBar:HideTextureFrame(0, SoulShardLight)
    ShardBar:ShowTextureFrame(0, SoulShardBox)

    ShardBar:HideBorder(nil)
    ShardBar:ShowBorder(0)
  else

    -- Texture mode
    local ShardScale = Gen.ShardScale

    -- Set Size
    ShardBar:SetBoxSize(SoulShardTexture.Width, SoulShardTexture.Height)
    ShardBar:SetBoxScale(Gen.ShardSize)
    ShardBar:SetTextureScale(0, SoulShardDark, ShardScale)
    ShardBar:SetTextureScale(0, SoulShardLight, ShardScale)

    -- Hide/show Texture mode.
    ShardBar:ShowTextureFrame(0, SoulShardDark)
    ShardBar:ShowTextureFrame(0, SoulShardLight)
    ShardBar:HideTextureFrame(0, SoulShardBox)

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
  local ShardBar = Bar:CreateBar(ScaleFrame, Anchor, MaxSoulShards)

  for ShardIndex = 1, MaxSoulShards do

      -- Create the textures for box and runes.
    ShardBar:CreateBoxTexture(ShardIndex, SoulShardBox, 'statusbar')
    ShardBar:CreateBoxTexture(ShardIndex, SoulShardDark, 'texture', 'ARTWORK')
    ShardBar:CreateBoxTexture(ShardIndex, SoulShardLight, 'texture', 'OVERLAY')

    -- Set the textures
    ShardBar:SetTexture(ShardIndex, SoulShardDark, SoulShardTexture.Texture)
    ShardBar:SetTexture(ShardIndex, SoulShardLight, SoulShardTexture.Texture)

    -- Set the soulshard dark texture
    ShardBar:SetTexCoord(ShardIndex, SoulShardDark, SoulShardTexture.Left, SoulShardTexture.Right, SoulShardTexture.Top, SoulShardTexture.Bottom)

    ShardBar:SetTextureSize(ShardIndex, SoulShardDark, SoulShardTexture.Width, SoulShardTexture.Height)
    ShardBar:SetDesaturated(ShardIndex, SoulShardDark, true)
    ShardBar:SetColor(ShardIndex, SoulShardDark, SoulShardDarkColor.r, SoulShardDarkColor.g, SoulShardDarkColor.b, SoulShardDarkColor.a)

    -- Set the soulshard light texture
    ShardBar:SetTexCoord(ShardIndex, SoulShardLight, SoulShardTexture.Left, SoulShardTexture.Right, SoulShardTexture.Top, SoulShardTexture.Bottom)
    ShardBar:SetTextureSize(ShardIndex, SoulShardLight, SoulShardTexture.Width, SoulShardTexture.Height)

     -- Set and save the name for tooltips for box mode.
    local Name = strconcat('Shard ', ShardIndex)

    ShardBar:SetTooltip(ShardIndex, Name, MouseOverDesc)

    ColorAllNames[ShardIndex] = Name
  end

  -- Show the dark textures.
  ShardBar:ShowTexture(0 , SoulShardDark)

  -- Save the name for tooltips for normal mode.
  ShardBar:SetTooltip(nil, UB.Name, MouseOverDesc)

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the shardbar
  UnitBarF.ShardBar = ShardBar
end

