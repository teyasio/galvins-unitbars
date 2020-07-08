--
-- ChiBar.lua
--
-- Displays the monk chi bar.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local OT = Bar.TriggerObjectTypes

local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _, _G =
      _, _G
local ipairs, UnitPower, UnitPowerMax =
      ipairs, UnitPower, UnitPowerMax

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the ember bar displayed on screen.
-------------------------------------------------------------------------------
local MaxChiOrbs = 6
local ExtraChiOrbStart = 5
local Display = false
local Update = false

-- Powertype constants
local PowerChi = ConvertPowerType['CHI']

-- shadow orbs Texture constants
local BoxMode = 1
local TextureMode = 2

local ChangeChi = 3

local AllTextures = 20

local ChiSBar = 10
local ChiDarkTexture = 20
local ChiLightTexture = 21

local ObjectsInfo = { -- type, id, additional menu text, textures
  { OT.BackgroundBorder,      1, '', BoxMode     },
  { OT.BackgroundBorderColor, 2, '', BoxMode     },
  { OT.BackgroundBackground,  3, '', BoxMode     },
  { OT.BackgroundColor,       4, '', BoxMode     },
  { OT.BarTexture,            5, '', ChiSBar     },
  { OT.BarColor,              6, '', ChiSBar     },
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
    'whole', 'Chi',
    'whole', 'Maximum Chi',
  },
  {1,    'Chi Orb 1',    ObjectsInfo},       -- 1
  {2,    'Chi Orb 2',    ObjectsInfo},       -- 2
  {3,    'Chi Orb 3',    ObjectsInfo},       -- 3
  {4,    'Chi Orb 4',    ObjectsInfo},       -- 4
  {5,    'Chi Orb 5',    ObjectsInfo},       -- 5
  {6,    'Chi Orb 6',    ObjectsInfo},       -- 6
  {'a',  'All',          ObjectsInfo},       -- 7
  {'aa', 'All Active',   ObjectsInfo},       -- 8
  {'ai', 'All Inactive', ObjectsInfo},       -- 9
  {'r',  'Region',       ObjectsInfoRegion}, -- 10
}

local ChiData = {
  TextureWidth = 21 + 8, TextureHeight = 21 + 8,
  { -- Level 1
    TextureNumber = ChiDarkTexture,
    Width = 21, Height = 21,
    AtlasName = 'MonkUI-OrbOff',
  },
  { -- Level 2
    TextureNumber = ChiLightTexture,
    Width = 21, Height = 21,
    AtlasName = 'MonkUI-LightOrb',
  },
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.ChiBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Chibar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of chi orbs of the player
--
-- Event         Event that called this function.  If nil then it wasn't called by an event.
-- Unit          Ignored just here for reference
-- PowerToken    String: PowerType in caps: MANA RAGE, etc
--               If nil then the units powertype is used instead
-------------------------------------------------------------------------------
function Main.UnitBarsF.ChiBar:Update(Event, Unit, PowerToken)

  -------------------
  -- Check Power Type
  -------------------
  local PowerType
  if PowerToken then
    PowerType = ConvertPowerType[PowerToken]
  else
    PowerType = PowerChi
  end

  -- Return if power type doesn't match that of chi
  if PowerType == nil or PowerType ~= PowerChi then
    return
  end

  ---------------
  -- Set IsActive
  ---------------
  local ChiOrbs = UnitPower('player', PowerChi)

  self.IsActive = ChiOrbs > 0

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
  local NumOrbs = UnitPowerMax('player', PowerChi)

  if Main.UnitBars.Testing then
    local TestMode = self.UnitBar.TestMode

    if TestMode.Ascension then
      NumOrbs = MaxChiOrbs
    else
      NumOrbs = MaxChiOrbs - 1
    end
    ChiOrbs = TestMode.Chi

    -- clip chi
    if ChiOrbs > NumOrbs then
      ChiOrbs = NumOrbs
    end
  end

  -------
  -- Draw
  -------
  local BBar = self.BBar
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers

  -- Check for max chi change
  if NumOrbs > 0 and NumOrbs ~= self.NumOrbs then
    self.NumOrbs = NumOrbs

    -- Change the number of boxes in the bar.
    for ChiIndex = ExtraChiOrbStart, MaxChiOrbs do
      BBar:SetHidden(ChiIndex, nil, ChiIndex > NumOrbs)
    end
    BBar:Display()
  end

  for ChiIndex = 1, MaxChiOrbs do
    BBar:ChangeTexture(ChangeChi, 'SetHiddenTexture', ChiIndex, ChiIndex > ChiOrbs)

    if EnableTriggers then
      BBar:SetTriggersActive(ChiIndex, ChiIndex <= ChiOrbs)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers('Chi', ChiOrbs)
    BBar:SetTriggers('Maximum Chi', NumOrbs)
    BBar:DoTriggers()
  end
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the chibar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ChiBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers',   function(v) BBar:EnableTriggers(v, GroupsInfo) Display = true end)
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
    BBar:SO('Layout', 'AnimationType',    function(v) BBar:SetAnimationTexture(0, ChiSBar, v)
                                                      BBar:SetAnimationTexture(0, ChiLightTexture, v) end)
    BBar:SO('Layout', 'BorderPadding',    function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',         function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',            function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',          function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',     function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'AnimationInTime',  function(v) BBar:SetAnimationDurationTexture(0, ChiSBar, 'in', v)
                                                      BBar:SetAnimationDurationTexture(0, ChiLightTexture, 'in', v) end)
    BBar:SO('Layout', 'AnimationOutTime', function(v) BBar:SetAnimationDurationTexture(0, ChiSBar, 'out', v)
                                                      BBar:SetAnimationDurationTexture(0, ChiLightTexture, 'out', v) end)
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

    BBar:SO('Bar', 'StatusBarTexture', function(v) BBar:SetTexture(0, ChiSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v) BBar:SetRotationTexture(0, ChiSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD) BBar:SetColorTexture(OD.Index, ChiSBar, OD.r, OD.g, OD.b, OD.a) end)
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
-- UnitBarF     The unitbar frame which will contain the chi bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ChiBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxChiOrbs)

  local Names = {}

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, ChiSBar, 'statusbar')

  -- Create texture mode.
  for ChiIndex = 1, MaxChiOrbs do
    BBar:SetFillTexture(ChiIndex, ChiSBar, 1)

    BBar:CreateTextureFrame(ChiIndex, TextureMode, 0)
    for _, CD in ipairs(ChiData) do
      local TextureNumber = CD.TextureNumber

      BBar:CreateTexture(ChiIndex, TextureMode, TextureNumber, 'texture')
      BBar:SetAtlasTexture(ChiIndex, TextureNumber, CD.AtlasName)
      BBar:SetSizeTexture(ChiIndex, TextureNumber, CD.Width, CD.Height)
    end
    local Name = GroupsInfo[ChiIndex][2]

    BBar:SetTooltipBox(ChiIndex, Name)
    Names[ChiIndex] = Name
  end

  BBar:SetHiddenTexture(0, ChiSBar, true)
  BBar:SetHiddenTexture(0, ChiDarkTexture, false)

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, ChiData.TextureWidth, ChiData.TextureHeight)

  BBar:SetChangeTexture(ChangeChi, ChiLightTexture, ChiSBar)

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  -- Set the texture scale for bar offset triggers.
  BBar:SetScaleAllTexture(0, AllTextures, 1)
  BBar:SetOffsetTextureFrame(0, BoxMode, 0, 0, 0, 0)

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Chibar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.ChiBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end

