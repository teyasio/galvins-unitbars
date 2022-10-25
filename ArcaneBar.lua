--
-- ArcaneBar.lua
--
-- Displays the mage arcane bar.

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
local UnitPower =
      UnitPower

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains an instance of bar functions for arcane bar.
-------------------------------------------------------------------------------
local MaxArcaneCharges = 4
local Display = false
local Update = false

-- Powertype constants
local PowerArcane = ConvertPowerType['ARCANE_CHARGES']

-- Arcane charges texture constants
local BoxMode = 1
local TextureMode = 2

local ChangeArcane = 3

local AllTextures = 11

local ArcaneSBar = 10
local ArcaneDarkTexture = 11
local ArcaneLightTexture = 12

local ObjectsInfo = { -- type, id, additional menu text, textures
  { OT.BackgroundBorder,      1, '', BoxMode     },
  { OT.BackgroundBorderColor, 2, '', BoxMode     },
  { OT.BackgroundBackground,  3, '', BoxMode     },
  { OT.BackgroundColor,       4, '', BoxMode     },
  { OT.BarTexture,            5, '', ArcaneSBar  },
  { OT.BarColor,              6, '', ArcaneSBar  },
  { OT.BarOffset,             7, '', BoxMode     },
  { OT.TextureScale,          8, '', AllTextures },
  { OT.Sound,                 9, '', Sound       }
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
    'whole', 'Arcane Charges'
  },
  {1,    'Arcane Charge 1',  ObjectsInfo},       -- 1
  {2,    'Arcane Charge 2',  ObjectsInfo},       -- 2
  {3,    'Arcane Charge 3',  ObjectsInfo},       -- 3
  {4,    'Arcane Charge 4',  ObjectsInfo},       -- 4
  {'a',  'All',              ObjectsInfo},       -- 5
  {'aa', 'All Active',       ObjectsInfo},       -- 6
  {'ai', 'All Inactive',     ObjectsInfo},       -- 7
  {'r',  'Region',           ObjectsInfoRegion}, -- 8
}

local ArcaneData = {
  AtlasName = [[Mage-ArcaneCharge]],
  Width = 31, Height = 31,
  DarkAlpha = 0.3
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.ArcaneBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Arcanebar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of arcane charges of the player
--
-- Event         Event that called this function.  If nil then it wasn't called by an event.
-- Unit          Ignored just here for reference
-- PowerToken    String: PowerType in caps: MANA RAGE, etc
--               If nil then the units powertype is used instead
-------------------------------------------------------------------------------
function Main.UnitBarsF.ArcaneBar:Update(Event, Unit, PowerToken)

  -------------------
  -- Check Power Type
  -------------------
  local PowerType
  if PowerToken then
    PowerType = ConvertPowerType[PowerToken]
  else
    PowerType = PowerArcane
  end

  -- Return if power type doesn't match that of arcane
  if PowerType == nil or PowerType ~= PowerArcane then
    return
  end

  ---------------
  -- Set IsActive
  ---------------
  local ArcaneCharges = UnitPower('player', PowerArcane)

  self.IsActive = ArcaneCharges > 0

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
    ArcaneCharges = self.UnitBar.TestMode.ArcaneCharges
  end

  -------
  -- Draw
  -------
  local BBar = self.BBar
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers

  for ArcaneIndex = 1, MaxArcaneCharges do
    BBar:ChangeTexture(ChangeArcane, 'SetHiddenTexture', ArcaneIndex, ArcaneIndex > ArcaneCharges)

    if EnableTriggers then
      BBar:SetTriggersActive(ArcaneIndex, ArcaneIndex <= ArcaneCharges)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers('Arcane Charges', ArcaneCharges)
    BBar:DoTriggers()
  end
end

--*****************************************************************************
--
-- Arcanebar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the arcanebar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ArcaneBar:SetAttr(TableName, KeyName)
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
    BBar:SO('Layout', 'AnimationType',    function(v) BBar:SetAnimationTexture(0, ArcaneSBar, v)
                                                      BBar:SetAnimationTexture(0, ArcaneLightTexture, v) end)
    BBar:SO('Layout', 'BorderPadding',    function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',         function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',            function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',          function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',     function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'AnimationInTime',  function(v) BBar:SetAnimationDurationTexture(0, ArcaneSBar, 'in', v)
                                                      BBar:SetAnimationDurationTexture(0, ArcaneLightTexture, 'in', v) end)
    BBar:SO('Layout', 'AnimationOutTime', function(v) BBar:SetAnimationDurationTexture(0, ArcaneSBar, 'out', v)
                                                      BBar:SetAnimationDurationTexture(0, ArcaneLightTexture, 'out', v) end)
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

    BBar:SO('Bar', 'StatusBarTexture',  function(v) BBar:SetTexture(0, ArcaneSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',     function(v) BBar:SetFillRotationTexture(0, ArcaneSBar, v) end)
    BBar:SO('Bar', 'Color',             function(v, UB, OD) BBar:SetColorTexture(OD.Index, ArcaneSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',             function(v) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',           function(v) BBar:SetPaddingTextureFrame(0, BoxMode, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the arcane bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ArcaneBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxArcaneCharges)

  local Names = {}

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0, 'statusbar')
    BBar:CreateTexture(0, BoxMode, ArcaneSBar, 'statusbar', 1)

  -- Create texture mode.
  BBar:CreateTextureFrame(0, TextureMode, 0)

  BBar:CreateTexture(0, TextureMode, ArcaneDarkTexture, 'texture')
  BBar:CreateTexture(0, TextureMode, ArcaneLightTexture, 'texture')

  BBar:SetAtlasTexture(0, ArcaneDarkTexture, ArcaneData.AtlasName)
  BBar:SetAtlasTexture(0, ArcaneLightTexture, ArcaneData.AtlasName)

  BBar:SetAlphaTexture(0, ArcaneDarkTexture, ArcaneData.DarkAlpha)

  BBar:SetSizeTexture(0, ArcaneDarkTexture, ArcaneData.Width, ArcaneData.Height)
  BBar:SetSizeTexture(0, ArcaneLightTexture, ArcaneData.Width, ArcaneData.Height)

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, ArcaneData.Width, ArcaneData.Height)

  BBar:SetHiddenTexture(0, ArcaneSBar, true)
  BBar:SetHiddenTexture(0, ArcaneDarkTexture, false)

  for ArcaneIndex = 1, MaxArcaneCharges do
    BBar:SetFillTexture(ArcaneIndex, ArcaneSBar, 1)

    local Name = GroupsInfo[ArcaneIndex][2]

    BBar:SetTooltipBox(ArcaneIndex, Name)
    Names[ArcaneIndex] = Name
  end

  BBar:SetTooltipRegion(UB._Name .. ' - Region')

  BBar:SetChangeTexture(ChangeArcane, ArcaneLightTexture, ArcaneSBar)

  -- Set the texture scale for bar offset triggers.
  BBar:SetScaleAllTexture(0, AllTextures, 1)
  BBar:SetOffsetTextureFrame(0, BoxMode, 0, 0, 0, 0)

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Arcanebar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.ArcaneBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end
