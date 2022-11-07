--
-- FragmentBar.lua
--
-- Displays the Destruction Warlock shard bar with fragments.

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
local floor, pairs, ipairs, type =
      floor, pairs, ipairs, type
local UnitPower, IsSpellKnown =
      UnitPower, IsSpellKnown

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains an instance of bar functions for shard bar.
--
-- UnitBarF.FragmentBar              Contains the shard bar displayed on screen.
-- UnitBarF.FillTexture              Current texture being used as fill
-- UnitBarF.FullTexture              Current texture being used as for when the shard is ready.
-------------------------------------------------------------------------------
local MaxSoulShards = 5
local MaxFragmentsPerShard = 10
local Display = false
local Update = false

local WarlockGreenFire = WARLOCK_GREEN_FIRE

-- Powertype constants
local PowerShard = ConvertPowerType['SOUL_SHARDS']

-- Soulshard Texture constants
local BoxMode = 1
local BoxModeEmber = 2
local TextureMode = 3
local TextureModeGreen = 4
local TextureModeEmber = 5
local TextureModeEmberGreen = 6

local ShardFill = 10
local ShardFull = 11

local ShardFillSBar = 20
local ShardFullSBar = 21
local EmberFillSBar = 22
local EmberFullSBar = 23

local ShardBgTexture = 50
local ShardFillTexture = 51
local ShardFullTexture = 52

local EmberBgTexture = 60
local EmberFillTexture = 61
local EmberFullTexture = 62

local GreenShardBgTexture = 70
local GreenShardFillTexture = 71
local GreenShardFullTexture = 72

local GreenEmberBgTexture = 80
local GreenEmberFillTexture = 81
local GreenEmberFullTexture = 82

local BarOffsetX = 0
local BarOffsetY = 0.5

local ObjectsInfo = { -- type, id, additional menu text, textures
  -- BACKGROUND border
  { OT.BackgroundBorder,      1,  '  [ Shard ]',        BoxMode                                  },
  { OT.BackgroundBorder,      2,  '  [ Ember ]',        BoxModeEmber                             },

  -- BACKGROUND border color
  { OT.BackgroundBorderColor, 3,  '  [ Shard ]',        BoxMode                                  },
  { OT.BackgroundBorderColor, 4,  '  [ Ember ]',        BoxModeEmber                             },

  -- BG BACKGROUND
  { OT.BackgroundBackground,  5,  '   [ Shard ]',       BoxMode                                  },
  { OT.BackgroundBackground,  6,  '   [ Ember ]',       BoxModeEmber                             },

  -- BACKGROUND color
  { OT.BackgroundColor,       7,  '   [ Shard ]',       BoxMode                                  },
  { OT.BackgroundColor,       8,  '   [ Ember ]',       BoxModeEmber                             },

  -- BAR texture
  { OT.BarTexture,            9,  '   [ Shard ]',       ShardFillSBar                            },
  { OT.BarTexture,            10, '   [ Ember ]',       EmberFillSBar                            },

  -- BAR texture full
  { OT.BarTexture,            11, ' (full)  [ Shard ]', ShardFullSBar                            },
  { OT.BarTexture,            12, ' (full)  [ Ember ]', EmberFullSBar                            },

  -- BAR color
  { OT.BarColor,              13, '  [ Shard ]',        ShardFillSBar                            },
  { OT.BarColor,              14, '  [ Ember ]',        EmberFillSBar                            },

  -- BAR color full
  -- Shard
  { OT.BarColor,              15, ' (full)  [ Shard ]', ShardFullSBar                            },
  { OT.BarColor,              16, ' (full)  [ Ember ]', EmberFullSBar                            },

  { OT.BarOffset,             17, '  [ Shard ]',        BoxMode                                  },
  { OT.BarOffset,             18, '  [ Ember ]',        BoxModeEmber                             },

  { OT.TextureScale,          19, '',                   ShardBgTexture, EmberBgTexture,
                                                        GreenShardBgTexture, GreenEmberBgTexture },
  { OT.Sound,                 20, ''                                                             }
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
    'whole',   'Soul Shards',
    'whole',   'Total Fragments',
    'whole',   'Fragments 1',
    'whole',   'Fragments 2',
    'whole',   'Fragments 3',
    'whole',   'Fragments 4',
    'whole',   'Fragments 5',
    'percent', 'Fragments 1 (percent)',
    'percent', 'Fragments 2 (percent)',
    'percent', 'Fragments 3 (percent)',
    'percent', 'Fragments 4 (percent)',
    'percent', 'Fragments 5 (percent)',
  },
  {1,    'Soul Shard 1',  ObjectsInfo},       -- 1
  {2,    'Soul Shard 2',  ObjectsInfo},       -- 2
  {3,    'Soul Shard 3',  ObjectsInfo},       -- 3
  {4,    'Soul Shard 4',  ObjectsInfo},       -- 4
  {5,    'Soul Shard 5',  ObjectsInfo},       -- 5
  {'a',  'All',           ObjectsInfo},       -- 6
  {'aa', 'All Active',    ObjectsInfo},       -- 7
  {'ai', 'All Inactive',  ObjectsInfo},       -- 8
  {'r',  'Region',        ObjectsInfoRegion}, -- 9
}

  --local EmberTexture = [[Interface\PlayerFrame\Warlock-DestructionUI]],
  --local EmberTextureGreen = [[Interface\PlayerFrame\Warlock-DestructionUI-Green]],

local ShardTextureGreen = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_WarlockSoulShardGreen]]
local EmberTexture      = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_WarlockDestructionUI]]
local EmberTextureGreen = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_WarlockDestructionUIGreen]]

local ShardData = {
  TextureWidth = 17 + 10, TextureHeight = 22 + 10,         -- extra space around the shard texture
  EmberTextureWidth = 36 - 5, EmberTextureHeight = 39 - 7, -- extra space around the ember texture
  EmberScale = 0.92,                                       -- makes the ember larger or smaller

  [TextureMode] = {
    { -- Level 1
      TextureNumber = ShardBgTexture,
      Width = 17 + 4, Height = 22 + 4,
      AtlasName = 'Warlock-ReadyShard',
    },
    { -- Level 2
      TextureNumber = ShardFillTexture,
      Width = 17 + 4, Height = 22 + 4,
      AtlasName = 'Warlock-FillShard',
    },
    { -- Level 3
      TextureNumber = ShardFullTexture,
      Width = 17 + 4, Height = 22 + 4,
      AtlasName = 'Warlock-ReadyShard',
    },
  },
  [TextureModeGreen] = {
    { -- Level 1
      TextureNumber = GreenShardBgTexture,
      Width = 17 + 4, Height = 22 + 4,
      Texture = ShardTextureGreen,
      Left = 0.0898438, Right = 0.15625, Top = 0.390625, Bottom = 0.734375,
    },
    { -- Level 2
      TextureNumber = GreenShardFillTexture,
      Width = 17 + 4, Height = 22 + 4,
      Texture = ShardTextureGreen,
      Left = 0.0898438, Right = 0.15625, Top = 0.015625, Bottom = 0.359375,
    },
    { -- Level 3
      TextureNumber = GreenShardFullTexture,
      Width = 17 + 4, Height = 22 + 4,
      Texture = ShardTextureGreen,
      Left = 0.0898438, Right = 0.15625, Top = 0.390625, Bottom = 0.734375,
    },
  },
  [TextureModeEmber] = {
    { -- Level 1
      TextureNumber = EmberBgTexture,
      OffsetX = BarOffsetX, OffsetY = BarOffsetY, -- position within the texture frame
      Width = 36, Height = 39,
      Texture = EmberTexture,
      Left = 0.15234375, Right = 0.29296875, Top = 0.32812500, Bottom = 0.93750000,
    },
    { -- Level 2
      TextureNumber = EmberFillTexture,
      OffsetX = BarOffsetX, OffsetY = BarOffsetY - 1.5, -- position within the texture frame
      Width = 20, Height = 22,
      Texture = EmberTexture,
      Left = 0.30078125, Right = 0.37890625, Top = 0.32812500, Bottom = 0.67187500,
    },
    { -- Level 3
      TextureNumber = EmberFullTexture,
      OffsetX = BarOffsetX, OffsetY = BarOffsetY, -- position within the texture frame
      Width = 36, Height = 39,
      Texture = EmberTexture,
      Left = 0.00390625, Right = 0.14453125, Top = 0.32812500, Bottom = 0.93750000,
    },
  },
  [TextureModeEmberGreen] = {
    { -- Level 1
      TextureNumber = GreenEmberBgTexture,
      OffsetX = BarOffsetX, OffsetY = BarOffsetY, -- position within the texture frame
      Width = 36, Height= 39,
      Texture = EmberTextureGreen,
      Left = 0.15234375, Right = 0.29296875, Top = 0.32812500, Bottom = 0.93750000,
    },
    { -- Level 2
      TextureNumber = GreenEmberFillTexture,
      OffsetX = BarOffsetX, OffsetY = BarOffsetY - 1.5, -- position within the texture frame
      Width = 20, Height = 22,
      Texture = EmberTextureGreen,
      Left = 0.30078125, Right = 0.37890625, Top = 0.32812500, Bottom = 0.67187500,
    },
    { -- Level 3
      TextureNumber = GreenEmberFullTexture,
      OffsetX = BarOffsetX, OffsetY = BarOffsetY, -- position within the texture frame
      Width = 36, Height = 39,
      Texture = EmberTextureGreen,
      Left = 0.00390625, Right = 0.14453125, Top = 0.32812500, Bottom = 0.93750000,
    },
  },
}
local ShardBgColor = {r = 0.25, g = 0.25, b = 0.25, a = 1}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.FragmentBar.StatusCheck = GUB.Main.StatusCheck

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
function Main.UnitBarsF.FragmentBar:Update(Event, Unit, PowerToken)

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
  local ShardFragments = UnitPower('player', PowerShard, true)

  self.IsActive = ShardFragments ~= MaxFragmentsPerShard * 3

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
  local UB = self.UnitBar
  local SoulShards = UnitPower('player', PowerShard)

  local ShowFull

  if Main.UnitBars.Testing then
    local TestMode = UB.TestMode

    ShowFull = TestMode.ShowFull
    ShardFragments = TestMode.ShardFragments
    SoulShards = floor(ShardFragments / MaxFragmentsPerShard)
  end

  -------
  -- Draw
  -------
  local BBar = self.BBar
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers
  local Layout = UB.Layout
  local FillTexture = self.FillTexture
  local FullTexture = self.FullTexture

  -- Check for green fire if auto is set
  local GreenFire = Layout.GreenFireAuto and IsSpellKnown(WarlockGreenFire) or Layout.GreenFire
  if self.GreenFire ~= GreenFire then
    self.GreenFire = GreenFire
    self:SetAttr()
    return
  end

  local ShardFragments2 = ShardFragments

  for ShardIndex = 1, MaxSoulShards do
    local Value = 1

    if ShardFragments2 <= MaxFragmentsPerShard then

      -- Get fragments as a value between 0 and 1.
      Value = ShardFragments2 / MaxFragmentsPerShard
      if Value < 0 then
        Value = 0
      end
    end
    BBar:SetFillTexture(ShardIndex, FillTexture, Value)
    if ShowFull == nil then
      BBar:SetHiddenTexture(ShardIndex, FullTexture, ShardIndex > SoulShards)
    else
      BBar:SetHiddenTexture(ShardIndex, FullTexture, not ShowFull or ShardIndex > SoulShards)
    end

    -- Left over fragments for next shard
    ShardFragments2 = ShardFragments2 - MaxFragmentsPerShard

    if EnableTriggers then
      BBar:SetTriggersActive(ShardIndex, ShardIndex <= SoulShards)
      BBar:SetTriggers('Fragments ' .. ShardIndex,                 Value * MaxFragmentsPerShard) -- because value between 0 and 1
      BBar:SetTriggers('Fragments ' .. ShardIndex .. ' (percent)', Value * MaxFragmentsPerShard, MaxFragmentsPerShard)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers('Soul Shards', SoulShards)
    BBar:SetTriggers('Total Fragments', ShardFragments)
    BBar:DoTriggers()
  end
end

--*****************************************************************************
--
-- Fragmentbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the shardbar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.FragmentBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then             -- OD.p1          OD.p2          OD.p3
    BBar:SetOptionData('BackgroundShard',      BoxMode)
    BBar:SetOptionData('BackgroundEmber',      BoxModeEmber)
    BBar:SetOptionData('BarShard',             BoxMode,       ShardFillSBar, ShardFullSBar)
    BBar:SetOptionData('BarEmber',             BoxModeEmber,  EmberFillSBar, EmberFullSBar)

    BBar:SetOptionData('BackgroundShardGreen', BoxMode)
    BBar:SetOptionData('BackgroundEmberGreen', BoxModeEmber)
    BBar:SetOptionData('BarShardGreen',        BoxMode,       ShardFillSBar, ShardFullSBar)
    BBar:SetOptionData('BarEmberGreen',        BoxModeEmber,  EmberFillSBar, EmberFullSBar)

    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers',    function(v) BBar:EnableTriggers(v, GroupsInfo) Update = true end)
    BBar:SO('Layout', 'BoxMode',           function(v, UB)
      local GreenFire = self.GreenFire
      local BurningEmbers = UB.Layout.BurningEmbers
      local FillTexture
      local FullTexture
      local ModeType

      -- Shards
      if not BurningEmbers then
        if v then
          ModeType = BoxMode
          FillTexture = ShardFillSBar
          FullTexture = ShardFullSBar
        elseif not GreenFire then
          ModeType = TextureMode
          FillTexture = ShardFillTexture
          FullTexture = ShardFullTexture
        else
          ModeType = TextureModeGreen
          FillTexture = GreenShardFillTexture
          FullTexture = GreenShardFullTexture
        end

      -- Embers
      elseif v then
        ModeType = BoxModeEmber
        FillTexture = EmberFillSBar
        FullTexture = EmberFullSBar
      elseif not GreenFire then
        ModeType = TextureModeEmber
        FillTexture = EmberFillTexture
        FullTexture = EmberFullTexture
      else
        ModeType = TextureModeEmberGreen
        FillTexture = GreenEmberFillTexture
        FullTexture = GreenEmberFullTexture
      end
      BBar:ShowRowTextureFrame(ModeType)
      self.FillTexture = FillTexture
      self.FullTexture = FullTexture

      Update = true
    end)

    BBar:SO('Layout', 'HideRegion',        function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',              function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',             function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',       function(v) BBar:ChangeTexture(ShardFill, 'SetFillReverseTexture', 0, v) Update = true end)
    BBar:SO('Layout', 'AnimationType',     function(v) BBar:ChangeTexture(ShardFull, 'SetAnimationTexture', 0, v) end)
    BBar:SO('Layout', 'FillDirection',     function(v) BBar:ChangeTexture(ShardFillTexture, 'SetFillDirectionTexture', 0, v) Update = true end)
    BBar:SO('Layout', 'BorderPadding',     function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',          function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',             function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',           function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',      function(v) BBar:SetScaleTextureFrame(0, TextureMode, v)
                                                       BBar:SetScaleTextureFrame(0, TextureModeGreen, v)
                                                       BBar:SetScaleTextureFrame(0, TextureModeEmber, v)
                                                       BBar:SetScaleTextureFrame(0, TextureModeEmberGreen, v)
                                                       Display = true end)
    BBar:SO('Layout', 'AnimationInTime',   function(v) BBar:ChangeTexture(ShardFull, 'SetAnimationDurationTexture', 0, 'in', v) end)
    BBar:SO('Layout', 'AnimationOutTime',  function(v) BBar:ChangeTexture(ShardFull, 'SetAnimationDurationTexture', 0, 'out', v) end)
    BBar:SO('Layout', 'SmoothFillMaxTime', function(v) BBar:ChangeTexture(ShardFill, 'SetSmoothFillMaxTimeTexture', 0, v) end)
    BBar:SO('Layout', 'SmoothFillSpeed',   function(v) BBar:ChangeTexture(ShardFill, 'SetFillSpeedTexture', 0, v) end)
    BBar:SO('Layout', 'Align',             function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX',     function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY',     function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',      function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',      function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    -- More layout
    BBar:SO('Layout', 'BurningEmbers',     function(v) BBar:DoOption('Layout', 'BoxMode') end)
    BBar:SO('Layout', 'GreenFire',         function(v) BBar:DoOption('Layout', 'BoxMode') end)
    BBar:SO('Layout', 'GreenFireAuto',     function(v) Update = true end)

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

    BBar:SO('Background', 'BgTexture',        function(v, UB, OD) BBar:SetBackdrop(0, OD.p1, v) end)
    BBar:SO('Background', 'BorderTexture',    function(v, UB, OD) BBar:SetBackdropBorder(0, OD.p1, v) end)
    BBar:SO('Background', 'BgTile',           function(v, UB, OD) BBar:SetBackdropTile(0, OD.p1, v) end)
    BBar:SO('Background', 'BgTileSize',       function(v, UB, OD) BBar:SetBackdropTileSize(0, OD.p1, v) end)
    BBar:SO('Background', 'BorderSize',       function(v, UB, OD) BBar:SetBackdropBorderSize(0, OD.p1, v) end)
    BBar:SO('Background', 'Padding',          function(v, UB, OD) BBar:SetBackdropPadding(0, OD.p1, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',            function(v, UB, OD)
      if not self.GreenFire then
        BBar:SetBackdropColor(OD.Index, OD.p1, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Background', 'BorderColor',      function(v, UB, OD)
      if not self.GreenFire then
        if UB[OD.TableName].EnableBorderColor then
          BBar:SetBackdropBorderColor(OD.Index, OD.p1, OD.r, OD.g, OD.b, OD.a)
        else
          BBar:SetBackdropBorderColor(OD.Index, OD.p1, nil)
        end
      end
    end)
    BBar:SO('Background', 'ColorGreen',       function(v, UB, OD)
      if self.GreenFire then
        BBar:SetBackdropColor(OD.Index, OD.p1, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Background', 'BorderColorGreen', function(v, UB, OD)
      if self.GreenFire then
        if UB[OD.TableName].EnableBorderColor then
          BBar:SetBackdropBorderColor(OD.Index, OD.p1, OD.r, OD.g, OD.b, OD.a)
        else
          BBar:SetBackdropBorderColor(OD.Index, OD.p1, nil)
        end
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',  function(v, UB, OD) BBar:SetTexture(0, OD.p2, v) end)
    BBar:SO('Bar', 'FullBarTexture',    function(v, UB, OD) BBar:SetTexture(0, OD.p3, v) end)
    BBar:SO('Bar', 'SyncFillDirection', function(v, UB, OD) BBar:SyncFillDirectionTexture(0, OD.p2, v) end)
    BBar:SO('Bar', 'Clipping',          function(v, UB, OD) BBar:SetFillClippingTexture(0, OD.p2, v) end)
    BBar:SO('Bar', 'FillDirection',     function(v, UB, OD) BBar:SetFillDirectionTexture(0, OD.p2, v) end)
    BBar:SO('Bar', 'RotateTexture',     function(v, UB, OD) BBar:SetFillRotationTexture(0, OD.p2, v)
                                                            BBar:SetFillRotationTexture(0, OD.p3, v) end)
    BBar:SO('Bar', 'Color',             function(v, UB, OD)
      if not self.GreenFire then
        BBar:SetColorTexture(OD.Index, OD.p2, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorFull',         function(v, UB, OD)
      if not self.GreenFire then
        BBar:SetColorTexture(OD.Index, OD.p3, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorGreen',        function(v, UB, OD)
      if self.GreenFire then
        BBar:SetColorTexture(OD.Index, OD.p2, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorFullGreen',    function(v, UB, OD)
      if self.GreenFire then
        BBar:SetColorTexture(OD.Index, OD.p3, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', '_Size',             function(v, UB, OD) BBar:SetSizeTextureFrame(0, OD.p1, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',           function(v, UB, OD) BBar:SetPaddingTextureFrame(0, OD.p1, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
function GUB.FragmentBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxSoulShards)

  local Names = {}

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 1, 'statusbar')
    BBar:CreateTexture(0, BoxMode, ShardFillSBar, 'statusbar', 1)
    BBar:CreateTexture(0, BoxMode, ShardFullSBar, 'statusbar', 2)

  BBar:CreateTextureFrame(0, BoxModeEmber, 1, 'statusbar')
    BBar:CreateTexture(0, BoxModeEmber, EmberFillSBar, 'statusbar', 1)
    BBar:CreateTexture(0, BoxModeEmber, EmberFullSBar, 'statusbar', 2)

  -- Create texture mode.
  for ShardIndex = 1, MaxSoulShards do
    for ModeType, SD in pairs(ShardData) do
      if type(ModeType) == 'number' then
        BBar:CreateTextureFrame(ShardIndex, ModeType, 1, 'statusbar')

        for Index, SSD in ipairs(SD) do
          local TextureNumber = SSD.TextureNumber

          BBar:CreateTexture(ShardIndex, ModeType, TextureNumber, 'statusbar', Index) -- use index for layer
          if SSD.Texture then
            BBar:SetTexture(ShardIndex, TextureNumber, SSD.Texture)
          else
            BBar:SetAtlasTexture(ShardIndex, TextureNumber, SSD.AtlasName)
          end
          if SSD.Left then
            BBar:SetCoordTexture(ShardIndex, TextureNumber, SSD.Left, SSD.Right, SSD.Top, SSD.Bottom)
          end
          BBar:SetFillPixelSizeTexture(ShardIndex, TextureNumber, SSD.Width, SSD.Height)
          BBar:SetFillPointPixelTexture(ShardIndex, TextureNumber, 'CENTER', SSD.OffsetX, SSD.OffsetY)
          if TextureNumber == ShardBgTexture or TextureNumber == GreenShardBgTexture then
            BBar:SetGreyscaleTexture(ShardIndex, TextureNumber, true)
            BBar:SetColorTexture(ShardIndex, TextureNumber, ShardBgColor.r, ShardBgColor.g, ShardBgColor.b, ShardBgColor.a)
          end
          -- Need to setfill 1 to each BG texture so they're visible
          if Index == 1 then
            BBar:SetFillTexture(ShardIndex, TextureNumber, 1)
          end
        end
      end
    end

    local Name = GroupsInfo[ShardIndex][2]

    BBar:SetTooltipBox(ShardIndex, Name)
    Names[ShardIndex] = Name
  end

  -- Since shard is default, use that.
  BBar:SetSizeTextureFrame(0, BoxMode, UB.BarShard.Width, UB.BarShard.Height)
  BBar:SetSizeTextureFrame(0, BoxModeEmber, UB.BarEmber.Width, UB.BarEmber.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, ShardData.TextureWidth, ShardData.TextureHeight)
  BBar:SetSizeTextureFrame(0, TextureModeGreen, ShardData.TextureWidth, ShardData.TextureHeight)
  BBar:SetSizeTextureFrame(0, TextureModeEmber, ShardData.EmberTextureWidth, ShardData.EmberTextureHeight)
  BBar:SetSizeTextureFrame(0, TextureModeEmberGreen, ShardData.EmberTextureWidth, ShardData.EmberTextureHeight)

  BBar:SetTooltipRegion(UB._Name .. ' - Region')

  BBar:SetChangeTexture(ShardFill, ShardFillTexture, GreenShardFillTexture, EmberFillTexture, GreenEmberFillTexture, ShardFillSBar,
                        EmberFillSBar)
  BBar:SetChangeTexture(ShardFull, ShardFullTexture, GreenShardFullTexture, EmberFullTexture, GreenEmberFullTexture, ShardFullSBar,
                        EmberFullSBar)
  BBar:SetChangeTexture(ShardFillTexture, ShardFillTexture, GreenShardFillTexture, EmberFillTexture, GreenEmberFillTexture)

  BBar:ChangeTexture(ShardFill, 'SetHiddenTexture', 0, false)
  BBar:SetHiddenTexture(0, ShardBgTexture, false)
  BBar:SetHiddenTexture(0, GreenShardBgTexture, false)
  BBar:SetHiddenTexture(0, EmberBgTexture, false)
  BBar:SetHiddenTexture(0, GreenEmberBgTexture, false)

  -- Need to set the full texture full to 1 so its visible
  BBar:ChangeTexture(ShardFull, 'SetFillTexture', 0, 1)

  -- Set default fill direction.
  BBar:ChangeTexture(ShardFill, 'SetFillDirectionTexture', 0, 'VERTICAL')

  -- Set the texture scale triggers.
  BBar:SetScaleAllTexture(0, ShardBgTexture, 1)
  BBar:SetScaleAllTexture(0, EmberBgTexture, 1)
  BBar:SetScaleAllTexture(0, GreenShardBgTexture, 1)
  BBar:SetScaleAllTexture(0, GreenEmberBgTexture, 1)

  -- Set bar offsets for triggers
  BBar:SetOffsetTextureFrame(0, BoxMode, 0, 0, 0, 0)
  BBar:SetOffsetTextureFrame(0, BoxModeEmber, 0, 0, 0, 0)

  UnitBarF.FillTexture = ShardFillTexture
  UnitBarF.FullTexture = ShardFullTexture
  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Fragmentbar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.FragmentBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end
