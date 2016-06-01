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
local TT = GUB.DefaultUB.TriggerTypes

local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _, _G =
      _, _G
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring =
      strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, PetHasActionBar, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, PetHasActionBar, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapDenied =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapDenied
local UnitName, UnitReaction, UnitLevel, UnitEffectiveLevel, UnitGetIncomingHeals, UnitCanAttack, UnitPlayerControlled, UnitIsPVP =
      UnitName, UnitReaction, UnitLevel, UnitEffectiveLevel, UnitGetIncomingHeals, UnitCanAttack, UnitPlayerControlled, UnitIsPVP
local GetRuneCooldown, GetSpellInfo, GetSpellBookItemInfo, PlaySound, message, UnitCastingInfo, GetSpellPowerCost =
      GetRuneCooldown, GetSpellInfo, GetSpellBookItemInfo, PlaySound, message, UnitCastingInfo, GetSpellPowerCost
local GetShapeshiftFormID, GetSpecialization, GetInventoryItemID, GetRealmName =
      GetShapeshiftFormID, GetSpecialization, GetInventoryItemID, GetRealmName
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, C_TimerAfter, UIParent =
      C_PetBattles, C_Timer.After, UIParent

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains an instance of bar functions for shard bar.
--
-- UnitBarF.ShardBar                 Contains the shard bar displayed on screen.
--
-- ShardData                         Contains all the data for the soul shards texture.
--   Texture                         Path name to the texture file.
--   Width                           Width of the texture and box size in texture mode.
--   Height                          Height of the texture and box size in texture mode.
--   Left, Right, Top, Bottom        Coordinates inside the main texture for the texture we need.
-- SoulShardDarkColor                Used to make the light colored soulshard texture dark.
--
-- ChangeShards                      ChangeTexture number for ShardBar and ShardLightTexture
-- ShardSBar                         Contains the lit shard texture for box mode.
-- ShardDarkTexture                  Contains the dark shard texture for texture mode.
-- ShardLightTexture                 Contains the lit shard textuire for texture mode.
-------------------------------------------------------------------------------
local MaxSoulShards = 5
local Display = false
local Update = false
local NamePrefix = 'Soul '

-- Powertype constants
local PowerShard = ConvertPowerType['SOUL_SHARDS']

-- Soulshard Texture constants
local BoxMode = 1
local TextureMode = 2

local ChangeShards = 3

local ShardSBar = 10
local ShardDarkTexture = 11
local ShardLightTexture = 12

local RegionGroup = 7

local GF = { -- Get function data
  TT.TypeID_ClassColor,  TT.Type_ClassColor,
  TT.TypeID_PowerColor,  TT.Type_PowerColor,
  TT.TypeID_CombatColor, TT.Type_CombatColor,
  TT.TypeID_TaggedColor, TT.Type_TaggedColor,
}

local TD = { -- Trigger data
  { TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,      BoxMode },
  { TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor, BoxMode,
    GF = GF },
  { TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,  BoxMode },
  { TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,       BoxMode,
    GF = GF },
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,            ShardSBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,              ShardSBar,
    GF = GF },
  { TT.TypeID_BarOffset,             TT.Type_BarOffset,             BoxMode },
  { TT.TypeID_TextureScale,          TT.Type_TextureScale,          ShardDarkTexture, ShardLightTexture },
  { TT.TypeID_Sound,                 TT.Type_Sound }
}

local TDregion = { -- Trigger data for region
  { TT.TypeID_RegionBorder,          TT.Type_RegionBorder },
  { TT.TypeID_RegionBorderColor,     TT.Type_RegionBorderColor,
    GF = GF },
  { TT.TypeID_RegionBackground,      TT.Type_RegionBackground },
  { TT.TypeID_RegionBackgroundColor, TT.Type_RegionBackgroundColor,
    GF = GF },
  { TT.TypeID_Sound,                 TT.Type_Sound }
}

local VTs = {'whole', 'Soul Shards',
             'auras', 'Auras'       }
local Groups = { -- BoxNumber, Name, ValueTypes,
  {1,   'Shard 1',    VTs, TD}, -- 1
  {2,   'Shard 2',    VTs, TD}, -- 2
  {3,   'Shard 3',    VTs, TD}, -- 3
  {4,   'Shard 4',    VTs, TD}, -- 4
  {5,   'Shard 5',    VTs, TD}, -- 5
  {'a', 'All', {'whole', 'Soul Shards',
                'state', 'Active',
                'auras', 'Auras'       }, TD},   -- 6
  {'r', 'Region',     VTs, TDregion},  -- 7
}

local ShardData = {
  Texture = [[Interface\PlayerFrame\UI-WarlockShard]],
  BoxWidth = 17 + 15, BoxHeight = 16 + 15,
  Width = 17 + 15 - 7, Height = 16 + 15 - 7,
  Left = 0.01562500, Right = 0.28125000, Top = 0.00781250, Bottom = 0.13281250
}
local SoulShardDarkColor = {r = 0.25, g = 0.25, b = 0.25, a = 1}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.ShardBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Shardbar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of shards of the player
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ShardBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerShard

  -- Return if not the correct powertype.
  if PowerType ~= PowerShard then
    return
  end

  local SoulShards = UnitPower('player', PowerShard)
  local NumShards = UnitPowerMax('player', PowerShard)
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers

  if Main.UnitBars.Testing then
    SoulShards = self.UnitBar.TestMode.SoulShards
  end

  local BBar = self.BBar

  for ShardIndex = 1, MaxSoulShards do
    BBar:ChangeTexture(ChangeShards, 'SetHiddenTexture', ShardIndex, ShardIndex > SoulShards)

    if EnableTriggers then
      BBar:SetTriggers(ShardIndex, 'active', ShardIndex <= SoulShards)
      BBar:SetTriggers(ShardIndex, 'soul shards', SoulShards)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers(RegionGroup, 'soul shards', SoulShards)
    BBar:DoTriggers()
  end

  -- Set the IsActive flag.
  self.IsActive = SoulShards > 0

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
function Main.UnitBarsF.ShardBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- Enable/disable for border.
  BBar:EnableMouseClicksRegion(Enable)

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the shardbar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ShardBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers', function(v) BBar:EnableTriggers(v, Groups) Update = true end)

    BBar:SO('Layout', 'BoxMode',       function(v)
      if v then
        -- Box mode
        BBar:ShowRowTextureFrame(BoxMode)
      else
        -- texture mode
        BBar:ShowRowTextureFrame(TextureMode)
      end
      Display = true
    end)
    BBar:SO('Layout', 'HideRegion',       function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',             function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',            function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'AnimationType',    function(v) BBar:SetAnimationTexture(0, ShardSBar, v)
                                                      BBar:SetAnimationTexture(0, ShardLightTexture, v) end)
    BBar:SO('Layout', 'BorderPadding',    function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',         function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',            function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',          function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',     function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'AnimationInTime',  function(v) BBar:SetAnimationDurationTexture(0, ShardSBar, 'in', v)
                                                      BBar:SetAnimationDurationTexture(0, ShardLightTexture, 'in', v) end)
    BBar:SO('Layout', 'AnimationOutTime', function(v) BBar:SetAnimationDurationTexture(0, ShardSBar, 'out', v)
                                                      BBar:SetAnimationDurationTexture(0, ShardLightTexture, 'out', v) end)
    BBar:SO('Layout', 'Align',            function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX',    function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY',    function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',     function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',     function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('Region', 'BgTexture',        function(v) BBar:SetBackdropRegion(v) end)
    BBar:SO('Region', 'BorderTexture',    function(v) BBar:SetBackdropBorderRegion(v) end)
    BBar:SO('Region', 'BgTile',           function(v) BBar:SetBackdropTileRegion(v) end)
    BBar:SO('Region', 'BgTileSize',       function(v) BBar:SetBackdropTileSizeRegion(v) end)
    BBar:SO('Region', 'BorderSize',       function(v) BBar:SetBackdropBorderSizeRegion(v) end)
    BBar:SO('Region', 'Padding',          function(v) BBar:SetBackdropPaddingRegion(v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Region', 'Color',            function(v) BBar:SetBackdropColorRegion(v.r, v.g, v.b, v.a) end)
    BBar:SO('Region', 'BorderColor',      function(v, UB)
      if UB.Region.EnableBorderColor then
        BBar:SetBackdropBorderColorRegion(v.r, v.g, v.b, v.a)
      else
        BBar:SetBackdropBorderColorRegion(nil)
      end
    end)

    BBar:SO('Background', 'BgTexture',     function(v) BBar:SetBackdrop(0, BoxMode, v) end)
    BBar:SO('Background', 'BorderTexture', function(v) BBar:SetBackdropBorder(0, BoxMode, v) end)
    BBar:SO('Background', 'BgTile',        function(v) BBar:SetBackdropTile(0, BoxMode, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v) BBar:SetBackdropTileSize(0, BoxMode, v) end)
    BBar:SO('Background', 'BorderSize',    function(v) BBar:SetBackdropBorderSize(0, BoxMode, v) end)
    BBar:SO('Background', 'Padding',       function(v) BBar:SetBackdropPadding(0, BoxMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v, UB, OD) BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB, OD)
      if UB.Background.EnableBorderColor then
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',  function(v) BBar:SetTexture(0, ShardSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',     function(v) BBar:SetRotateTexture(0, ShardSBar, v) end)
    BBar:SO('Bar', 'Color',             function(v, UB, OD) BBar:SetColorTexture(OD.Index, ShardSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',             function(v, UB) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',           function(v) BBar:SetPaddingTexture(0, ShardSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
  end

  -- Do the option.  This will call one of the options above or all.
  BBar:DoOption(TableName, KeyName)

  if Update or Main.UnitBars.Testing then
    self:Update()
    Update = false
    Display = true
  end

  if Display then
    BBar:Display()
    Display = false
  end
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- UnitBarF     The unitbar frame which will contain the shard bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ShardBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxSoulShards)

  local Names = {}

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, ShardSBar)

  -- Create texture mode.
  BBar:CreateTextureFrame(0, TextureMode, 0)

  BBar:CreateTexture(0, TextureMode, 'texture', 1, ShardDarkTexture)
  BBar:CreateTexture(0, TextureMode, 'texture', 2, ShardLightTexture)

  BBar:SetTexture(0, ShardDarkTexture, ShardData.Texture)
  BBar:SetTexture(0, ShardLightTexture, ShardData.Texture)

  BBar:SetCoordTexture(0, ShardDarkTexture, ShardData.Left, ShardData.Right, ShardData.Top, ShardData.Bottom)
  BBar:SetCoordTexture(0, ShardLightTexture, ShardData.Left, ShardData.Right, ShardData.Top, ShardData.Bottom)

  BBar:SetGreyscaleTexture(0, ShardDarkTexture, true)
  BBar:SetColorTexture(0, ShardDarkTexture, SoulShardDarkColor.r, SoulShardDarkColor.g, SoulShardDarkColor.b, SoulShardDarkColor.a)

  BBar:SetSizeTexture(0, ShardDarkTexture, ShardData.Width, ShardData.Height)
  BBar:SetSizeTexture(0, ShardLightTexture, ShardData.Width, ShardData.Height)

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, ShardData.BoxWidth, ShardData.BoxHeight)

  BBar:SetHiddenTexture(0, ShardDarkTexture, false)

  for ShardIndex = 1, MaxSoulShards do
    local Name = NamePrefix .. Groups[ShardIndex][2]

    BBar:SetTooltip(ShardIndex, nil, Name)
    Names[ShardIndex] = Name
  end

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  BBar:SetChangeTexture(ChangeShards, ShardLightTexture, ShardSBar)

  -- Set the texture scale for bar offset triggers.
  BBar:SetScaleTexture(0, ShardDarkTexture, 1)
  BBar:SetScaleTexture(0, ShardLightTexture, 1)
  BBar:SetOffsetTextureFrame(0, BoxMode, 0, 0, 0, 0)

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Shardbar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.ShardBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end
