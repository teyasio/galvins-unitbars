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
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring =
      strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList
local UnitName, UnitReaction, UnitGetIncomingHeals, UnitPlayerControlled, GetRealmName =
      UnitName, UnitReaction, UnitGetIncomingHeals, UnitPlayerControlled, GetRealmName
local GetRuneCooldown, GetRuneType, GetSpellInfo, PlaySound, message =
      GetRuneCooldown, GetRuneType, GetSpellInfo, PlaySound, message
local GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, C_TimerAfter,  UIParent =
      C_PetBattles, C_Timer.After, UIParent

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the ember bar displayed on screen.
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
-- Shards                            ChangeTexture number for ShardBar and ShardLightTexture
-- ShardSBar                         Contains the lit shard texture for box mode.
-- ShardDarkTexture                  Contains the dark shard texture for texture mode.
-- ShardLightTexture                 Contains the lit shard textuire for texture mode.
-- ShardBox                          Soul shard in box mode.  Statusbar
-- ShardDark                         Dark soul shard when not lit.
-- ShardLight                        Light sould shard used for lighting a dark soul shard.
--
-- AnyShardTrigger                   Trigger for any shard that is currently active.
-- RegionTrigger                     Trigger to make changes to the region.
-- TriggerGroups                     Trigger groups for boxnumber and condition type.
-- DoTriggers                        True by passes visible and isactive flags. If not nil then calls
--                                   self:Update(DoTriggers)
-------------------------------------------------------------------------------
local MaxSoulShards = 4
local Display = false
local DoTriggers = false

-- Powertype constants
local PowerShard = ConvertPowerType['SOUL_SHARDS']

-- Soulshard Texture constants
local BoxMode = 1
local TextureMode = 2

local Shards = 3

local ShardSBar = 10
local ShardDarkTexture = 11
local ShardLightTexture = 12


local AnyShardTrigger = 5
local RegionTrigger = 6
local TGBoxNumber = 1
local TGName = 2
local TGValueTypes = 3
local VTs = {'whole:Soul Shards', 'auras:Auras'}
local TriggerGroups = { -- BoxNumber, Name, ValueTypes,
  {1,  'Soul Shard 1',    VTs}, -- 1
  {2,  'Soul Shard 2',    VTs}, -- 2
  {3,  'Soul Shard 3',    VTs}, -- 3
  {4,  'Soul Shard 4',    VTs}, -- 4
  {0,  'Any Soul Shard', {'boolean:Active', 'auras:Auras'}},   -- 5
  {-1, 'Region',         VTs},  -- 6
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

  -- Set default value if NumShards returns zero.
  NumShards = NumShards > 0 and NumShards or MaxSoulShards

  if Main.UnitBars.Testing then
    SoulShards = floor(MaxSoulShards * self.UnitBar.TestMode.Value)

  -- Reduce cpu usage by checking for soulshard change.
  -- This is because unit_power_frequent is firing off more than it should.
  elseif SoulShards == self.SoulShards then
    return
  end

  self.SoulShards = SoulShards
  local BBar = self.BBar

  for ShardIndex = 1, MaxSoulShards do
    BBar:ChangeTexture(Shards, 'SetHiddenTexture', ShardIndex, ShardIndex > SoulShards)

    if EnableTriggers then
      BBar:SetTriggers(AnyShardTrigger, 'active', ShardIndex <= SoulShards, nil, ShardIndex)
      BBar:SetTriggers(ShardIndex, 'soul shards', SoulShards)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers(RegionTrigger, 'region', SoulShards)
    BBar:DoTriggers()
  end

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

    BBar:SO('Layout', '_UpdateTriggers', function(v)
      if v.EnableTriggers then
        DoTriggers = true
        Display = true
      end
    end)
    BBar:SO('Layout', 'EnableTriggers', function(v)
      if v then
        if not BBar:GroupsCreatedTriggers() then
          for GroupNumber = 1, #TriggerGroups do
            local TG = TriggerGroups[GroupNumber]
            local BoxNumber = TG[TGBoxNumber]

            BBar:CreateGroupTriggers(GroupNumber, unpack(TG[TGValueTypes]))
            if BoxNumber ~= -1 then
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,      'SetBackdropBorder', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor, 'SetBackdropBorderColor', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,  'SetBackdrop', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,       'SetBackdropColor', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarTexture,            TT.Type_BarTexture,            'SetTexture', BoxNumber, ShardSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarColor,              TT.Type_BarColor,              'SetColorTexture', BoxNumber, ShardSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_TextureSize,           TT.Type_TextureSize,           'SetScaleTexture', BoxNumber, ShardDarkTexture, ShardLightTexture)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_Sound,                 TT.Type_Sound,                 'PlaySound', BoxNumber)
            else
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBorder,          TT.Type_RegionBorder,          'SetBackdropBorderRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBorderColor,     TT.Type_RegionBorderColor,     'SetBackdropBorderColorRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBackground,      TT.Type_RegionBackground,      'SetBackdropRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBackgroundColor, TT.Type_RegionBackgroundColor, 'SetBackdropColorRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_Sound,                 TT.Type_Sound,                 'PlaySound', 1)
            end
          end
          -- Set the texture scale for Texture Size triggers.
          BBar:SetScaleTexture(0, ShardDarkTexture, 1)
          BBar:SetScaleTexture(0, ShardLightTexture, 1)

          -- Do this since all defaults need to be set first.
          BBar:DoOption()
        end
        BBar:UpdateTriggers()

        DoTriggers = true
        Display = true
      elseif BBar:ClearTriggers() then
        Display = true
      end
    end)
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
    BBar:SO('Layout', 'HideRegion',    function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'BorderPadding', function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',      function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',         function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',       function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',  function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, ShardSBar, 'in', v)
                                                   BBar:SetFadeTimeTexture(0, ShardLightTexture, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, ShardSBar, 'out', v)
                                                   BBar:SetFadeTimeTexture(0, ShardLightTexture, 'out', v) end)
    BBar:SO('Layout', 'Align',         function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX', function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY', function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',  function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',  function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('Region', 'BgTexture',     function(v) BBar:SetBackdropRegion(v) end)
    BBar:SO('Region', 'BorderTexture', function(v) BBar:SetBackdropBorderRegion(v) end)
    BBar:SO('Region', 'BgTile',        function(v) BBar:SetBackdropTileRegion(v) end)
    BBar:SO('Region', 'BgTileSize',    function(v) BBar:SetBackdropTileSizeRegion(v) end)
    BBar:SO('Region', 'BorderSize',    function(v) BBar:SetBackdropBorderSizeRegion(v) end)
    BBar:SO('Region', 'Padding',       function(v) BBar:SetBackdropPaddingRegion(v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Region', 'Color',         function(v) BBar:SetBackdropColorRegion(v.r, v.g, v.b, v.a) end)
    BBar:SO('Region', 'BorderColor',   function(v, UB)
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

  if DoTriggers or Main.UnitBars.Testing then
    self:Update(DoTriggers)
    DoTriggers = false
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

  local Names = {Trigger = {}, Color = {}}
  local Trigger = Names.Trigger
  local Color = Names.Color

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
    local Name = TriggerGroups[ShardIndex][TGName]

    BBar:SetTooltip(ShardIndex, nil, Name)
    Color[ShardIndex] = Name
    Trigger[ShardIndex] = Name
  end

  Trigger[AnyShardTrigger] = TriggerGroups[AnyShardTrigger][TGName]
  Trigger[RegionTrigger] = TriggerGroups[RegionTrigger][TGName]

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  BBar:SetChangeTexture(Shards, ShardLightTexture, ShardSBar)

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
