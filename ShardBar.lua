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
local OT = Bar.TriggerObjectTypes

local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _, _G, print =
      _, _G, print
local ipairs, UnitPower =
      ipairs, UnitPower

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains an instance of bar functions for shard bar.
-------------------------------------------------------------------------------
local MaxSoulShards = 5
local Display = false
local Update = false

-- Powertype constants
local PowerShard = ConvertPowerType['SOUL_SHARDS']

-- Soulshard Texture constants
local BoxMode = 1
local TextureMode = 2

local ChangeShards = 3

local ShardSBar = 10
local ShardDarkTexture = 11
local ShardLightTexture = 12

local ObjectsInfo = { -- type, id, additional menu text, textures
  {OT.BackgroundBorder,      1, '', BoxMode          },
  {OT.BackgroundBorderColor, 2, '', BoxMode          },
  {OT.BackgroundBackground,  3, '', BoxMode          },
  {OT.BackgroundColor,       4, '', BoxMode          },
  {OT.BarTexture,            5, '', ShardSBar        },
  {OT.BarColor,              6, '', ShardSBar        },
  {OT.BarOffset,             7, '', BoxMode          },
  {OT.TextureScale,          8, '', ShardDarkTexture },
  {OT.Sound,                 9, ''                   }
}

local ObjectsInfoRegion = { -- type, id, additional text
  { OT.RegionBorder,          1, '' },
  { OT.RegionBorderColor,     2, '' },
  { OT.RegionBackground,      3, '' },
  { OT.RegionBackgroundColor, 4, '' },
  { OT.Sound,                 5, '' },
}

local GroupsInfo = { -- BoxNumber, Name, ValueTypes
  ValueNames = {
    'whole', 'Soul Shards',
  },
  {1,   'Soul Shard 1',  ObjectsInfo},       -- 1
  {2,   'Soul Shard 2',  ObjectsInfo},       -- 2
  {3,   'Soul Shard 3',  ObjectsInfo},       -- 3
  {4,   'Soul Shard 4',  ObjectsInfo},       -- 4
  {5,   'Soul Shard 5',  ObjectsInfo},       -- 5
  {'a',  'All',          ObjectsInfo},       -- 6
  {'aa', 'All Active',   ObjectsInfo},       -- 7
  {'ai', 'All Inactive', ObjectsInfo},       -- 8
  {'r', 'Region',        ObjectsInfoRegion}, -- 9
}

local ShardData = {
  TextureWidth = 17 + 10, TextureHeight = 22 + 10,
  { -- Level 1
    TextureNumber = ShardDarkTexture,
    Width = 17 + 4, Height = 22 + 4,
    AtlasName = 'Warlock-ReadyShard',
  },
  { -- Level 2
    TextureNumber = ShardLightTexture,
    Width = 17 + 4, Height = 22 + 4,
    AtlasName = 'Warlock-ReadyShard',
  },
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
-- Event         Event that called this function.  If nil then it wasn't called by an event.
-- Unit          Ignored just here for reference
-- PowerToken    String: PowerType in caps: MANA RAGE, etc
--               If nil then the units powertype is used instead
-------------------------------------------------------------------------------
function Main.UnitBarsF.ShardBar:Update(Event, Unit, PowerToken)

  -------------------
  -- Check Power Type
  -------------------
  local PowerType
  if PowerToken then
    PowerType = ConvertPowerType[PowerToken]
  else
    PowerType = PowerShard
  end

  -- Return if power type doesn't match that of shard
  if PowerType == nil or PowerType ~= PowerShard then
    return
  end

  ---------------
  -- Set IsActive
  ---------------
  local SoulShards = UnitPower('player', PowerShard)

  self.IsActive = SoulShards ~= 3

  --------
  -- Check
  --------
  local LastHidden = self.Hidden
  self:StatusCheck()
  local Hidden = self.Hidden

  -- If not called by an event and Hidden is true then return
  if Event == nil and Hidden or LastHidden and Hidden then
    return
  end

  ------------
  -- Test Mode
  ------------
  if Main.UnitBars.Testing then
    SoulShards = self.UnitBar.TestMode.SoulShards
  end

  -------
  -- Draw
  -------
  local BBar = self.BBar
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers

  for ShardIndex = 1, MaxSoulShards do
    BBar:ChangeTexture(ChangeShards, 'SetHiddenTexture', ShardIndex, ShardIndex > SoulShards)

    if EnableTriggers then
      BBar:SetTriggersActive(ShardIndex, ShardIndex <= SoulShards)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers('Soul Shards', SoulShards)
    BBar:DoTriggers()
  end
end

--*****************************************************************************
--
-- Shardbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the shardbar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ShardBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers',   function(v) BBar:EnableTriggers(v, GroupsInfo) Update = true end)
    BBar:SO('Layout', 'BoxMode',          function(v)
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

    BBar:SO('Bar', 'StatusBarTexture', function(v) BBar:SetTexture(0, ShardSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v) BBar:SetFillRotationTexture(0, ShardSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD) BBar:SetColorTexture(OD.Index, ShardSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',            function(v) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v) BBar:SetPaddingTextureFrame(0, BoxMode, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
  BBar:CreateTextureFrame(0, BoxMode, 1, 'statusbar')
    BBar:CreateTexture(0, BoxMode, ShardSBar, 'statusbar', 1)

  -- Create texture mode.
  for ShardIndex = 1, MaxSoulShards do
    BBar:SetFillTexture(ShardIndex, ShardSBar, 1)

    BBar:CreateTextureFrame(ShardIndex, TextureMode, 0)
    for _, SD in ipairs(ShardData) do
      local TextureNumber = SD.TextureNumber

      BBar:CreateTexture(ShardIndex, TextureMode, TextureNumber, 'texture')
      BBar:SetAtlasTexture(ShardIndex, TextureNumber, SD.AtlasName)
      BBar:SetSizeTexture(ShardIndex, TextureNumber, SD.Width, SD.Height)

      if TextureNumber == ShardDarkTexture then
        BBar:SetGreyscaleTexture(ShardIndex, TextureNumber, true)
        BBar:SetColorTexture(ShardIndex, TextureNumber, SoulShardDarkColor.r, SoulShardDarkColor.g, SoulShardDarkColor.b, SoulShardDarkColor.a)
      end
    end
    local Name = GroupsInfo[ShardIndex][2]

    BBar:SetTooltipBox(ShardIndex, Name)
    Names[ShardIndex] = Name
  end

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, ShardData.TextureWidth, ShardData.TextureHeight)

  BBar:SetHiddenTexture(0, ShardDarkTexture, false)

  BBar:SetTooltipRegion(UB._Name .. ' - Region')

  BBar:SetChangeTexture(ChangeShards, ShardLightTexture, ShardSBar)

  -- Set the texture scale for bar offset triggers.
  BBar:SetScaleAllTexture(0, ShardDarkTexture, 1)
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
