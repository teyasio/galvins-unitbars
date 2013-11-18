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

local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strupper, strlower, strmatch, format, strconcat, gsub, tonumber =
      strfind, strsplit, strsub, strupper, strlower, strmatch, format, strconcat, gsub, tonumber
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax
local UnitName, UnitGetIncomingHeals, GetRealmName =
      UnitName, UnitGetIncomingHeals, GetRealmName
local GetRuneCooldown, GetRuneType, GetSpellInfo, GetTalentInfo, PlaySound =
      GetRuneCooldown, GetRuneType, GetSpellInfo, GetTalentInfo, PlaySound
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
-------------------------------------------------------------------------------
local MaxSoulShards = 4
local Display = false

-- Powertype constants
local PowerShard = ConvertPowerType['SOUL_SHARDS']

-- Soulshard Texture constants
local BoxMode = 1
local TextureMode = 2

local Shards = 3

local ShardSBar = 10
local ShardDarkTexture = 11
local ShardLightTexture = 12

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
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ShardBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerShard

  -- Return if not the correct powertype.
  if PowerType ~= PowerShard then
    return
  end

  local SoulShards = UnitPower('player', PowerShard)
  local NumShards = UnitPowerMax('player', PowerShard)

  -- Set default value if NumShards returns zero.
  NumShards = NumShards > 0 and NumShards or MaxSoulShards

  if Main.UnitBars.Testing then
    if self.UnitBar.TestMode.MaxResource then
      SoulShards = MaxSoulShards
    else
      SoulShards = 0
    end

  -- Reduce cpu usage by checking for soulshard change.
  -- This is because unit_power_frequent is firing off more than it should.
  elseif SoulShards == self.SoulShards then
    return
  end

  self.SoulShards = SoulShards
  local BBar = self.BBar

  for ShardIndex = 1, MaxSoulShards do
    BBar:ChangeTexture(Shards, 'SetHiddenTexture', ShardIndex, ShardIndex > SoulShards)
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

    BBar:SO('Region', 'BackdropSettings', function(v) BBar:SetBackdropRegion(v) end)
    BBar:SO('Region', 'Color',            function(v) BBar:SetBackdropColorRegion(v.r, v.g, v.b, v.a) end)

    BBar:SO('Background', 'BackdropSettings', function(v) BBar:SetBackdrop(0, BoxMode, v) end)
    BBar:SO('Background', 'Color',            function(v, UB, OD) BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a) end)

    BBar:SO('Bar', 'StatusBarTexture',  function(v) BBar:SetTexture(0, ShardSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',     function(v) BBar:SetRotateTexture(0, ShardSBar, v) end)
    BBar:SO('Bar', 'Color',             function(v, UB, OD) BBar:SetColorTexture(OD.Index, ShardSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',             function(v, UB) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',           function(v) BBar:SetPaddingTexture(0, ShardSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
  end

  -- Do the option.  This will call one of the options above or all.
  BBar:DoOption(TableName, KeyName)

  if Main.UnitBars.Testing then
    self:Update()
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

  local ColorAllNames = {}

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
    local Name = 'Soul Shard ' .. ShardIndex

    BBar:SetTooltip(ShardIndex, nil, Name)
    ColorAllNames[ShardIndex] = Name
  end
  BBar:SetTooltipRegion(UB.Name)

  BBar:SetChangeTexture(Shards, ShardLightTexture, ShardSBar)

  UnitBarF.ColorAllNames = ColorAllNames
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
