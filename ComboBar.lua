--
-- ComboBar.lua
--
-- Displays the rogue or cat druid combo point bar.

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
local ipairs =
      ipairs
local UnitPower, UnitPowerMax =
      UnitPower, UnitPowerMax

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains an instance of bar functions for combo bar.
-------------------------------------------------------------------------------
local MaxComboPoints = 6
local Display = false
local Update = false

-- Powertype constants
local PowerPoint = ConvertPowerType['COMBO_POINTS']

local BoxMode = 1
local TextureMode = 2

local ChangePoints = 3
local ChangeComboPoints = 4

local AllTextures = 11

local ComboSBar = 10
local ComboDarkTexture = 11
local ComboLightTexture = 12

local ObjectsInfo = { -- type, id, additional menu text, textures
  { OT.BackgroundBorder,      1, '', BoxMode     },
  { OT.BackgroundBorderColor, 2, '', BoxMode     },
  { OT.BackgroundBackground,  3, '', BoxMode     },
  { OT.BackgroundColor,       4, '', BoxMode     },
  { OT.BarTexture,            5, '', ComboSBar   },
  { OT.BarColor,              6, '', ComboSBar   },
  { OT.BarOffset,             7, '', BoxMode     },
  { OT.TextureScale,          8, '', AllTextures },
  { OT.Sound,                 9, ''              },
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
    'whole', 'Combo Points',
    'whole', 'Maximum Points',
  },
  {1,    'Combo Point 1', ObjectsInfo},       -- 1
  {2,    'Combo Point 2', ObjectsInfo},       -- 2
  {3,    'Combo Point 3', ObjectsInfo},       -- 3
  {4,    'Combo Point 4', ObjectsInfo},       -- 4
  {5,    'Combo Point 5', ObjectsInfo},       -- 5
  {6,    'Combo Point 6', ObjectsInfo},       -- 6
  {'a',  'All',           ObjectsInfo},       -- 7
  {'aa', 'All Active',    ObjectsInfo},       -- 8
  {'ai', 'All Inactive',  ObjectsInfo},       -- 9
  {'r',  'Region',        ObjectsInfoRegion}, -- 10
}

local ComboData = {
  TextureWidth = 21 + 8, TextureHeight = 21 + 8,
  {  -- Level 1
    TextureNumber = ComboDarkTexture,
    Width = 21, Height = 21,
    AtlasName = 'ComboPoints-PointBg',
  },
  { -- Level 2
    TextureNumber = ComboLightTexture,
    Width = 21, Height = 21,
    AtlasName = 'ComboPoints-ComboPoint',
  },
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.ComboBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Combobar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of combo points of the player
--
-- Event         Event that called this function.  If nil then it wasn't called by an event.
-- Unit          Ignored just here for reference
-- PowerToken    String: PowerType in caps: MANA RAGE, etc
--               If nil then the units powertype is used instead
-------------------------------------------------------------------------------
function Main.UnitBarsF.ComboBar:Update(Event, Unit, PowerToken)

  -------------------
  -- Check Power Type
  -------------------
  local PowerType
  if PowerToken then
    PowerType = ConvertPowerType[PowerToken]
  else
    PowerType = PowerPoint
  end

  -- Return if power type doesn't match that of combo points
  if PowerType == nil or PowerType ~= PowerPoint then
    return
  end

  ---------------
  -- Set IsActive
  ---------------
  local ComboPoints = UnitPower('player', PowerPoint)

  self.IsActive = ComboPoints > 0

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
  local BBar = self.BBar
  local NumPoints = UnitPowerMax('player', PowerPoint)

  if Main.UnitBars.Testing then
    local TestMode = self.UnitBar.TestMode

    if TestMode.DeeperStratagem then
      NumPoints = MaxComboPoints
    else
      NumPoints = MaxComboPoints - 1
    end
    ComboPoints = TestMode.ComboPoints

    -- Clip combo points
   -- if ComboPoints > NumPoints then
   --   ComboPoints = NumPoints
   -- end
  end

  -------
  -- Draw
  -------
  if NumPoints > 0 and NumPoints ~= self.NumPoints then
    self.NumPoints = NumPoints

    -- Change the number of boxes in the bar.
    BBar:SetHidden(MaxComboPoints, nil, NumPoints ~= MaxComboPoints)

    BBar:Display()
  end

  local UB = self.UnitBar
  local EnableTriggers = UB.Layout.EnableTriggers

  for ComboIndex = 1, MaxComboPoints do
    BBar:ChangeTexture(ChangePoints, 'SetHiddenTexture', ComboIndex, ComboIndex > ComboPoints)

    if EnableTriggers then
      BBar:SetTriggersActive(ComboIndex, ComboIndex <= ComboPoints)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers('Combo Points', ComboPoints)
    BBar:SetTriggers('Maximum Points', NumPoints)
    BBar:DoTriggers()
  end
end

--*****************************************************************************
--
-- Combobar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the combo bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ComboBar:SetAttr(TableName, KeyName)
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
    BBar:SO('Layout', 'AnimationType',    function(v) BBar:SetAnimationTexture(0, ComboSBar, v)
                                                      BBar:SetAnimationTexture(0, ComboLightTexture, v) end)
    BBar:SO('Layout', 'BorderPadding',    function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',         function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',            function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',          function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'AnimationInTime',  function(v) BBar:SetAnimationDurationTexture(0, ComboSBar, 'in', v)
                                                      BBar:SetAnimationDurationTexture(0, ComboLightTexture, 'in', v) end)
    BBar:SO('Layout', 'AnimationOutTime', function(v) BBar:SetAnimationDurationTexture(0, ComboSBar, 'out', v)
                                                      BBar:SetAnimationDurationTexture(0, ComboLightTexture, 'out', v) end)
    BBar:SO('Layout', 'Align',            function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX',    function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY',    function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',     function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',     function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    -- More layout
    BBar:SO('Layout', 'TextureScaleCombo',         function(v) BBar:ChangeBox(ChangeComboPoints, 'SetScaleTextureFrame', TextureMode, v) Display = true end)

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

    BBar:SO('Background', 'BgTexture',     function(v, UB, OD) BBar:ChangeBox(ChangeComboPoints, 'SetBackdrop', BoxMode, v) end)
    BBar:SO('Background', 'BorderTexture', function(v, UB, OD) BBar:ChangeBox(ChangeComboPoints, 'SetBackdropBorder', BoxMode, v) end)
    BBar:SO('Background', 'BgTile',        function(v, UB, OD) BBar:ChangeBox(ChangeComboPoints, 'SetBackdropTile', BoxMode, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v, UB, OD) BBar:ChangeBox(ChangeComboPoints, 'SetBackdropTileSize', BoxMode, v) end)
    BBar:SO('Background', 'BorderSize',    function(v, UB, OD) BBar:ChangeBox(ChangeComboPoints, 'SetBackdropBorderSize', BoxMode, v) end)
    BBar:SO('Background', 'Padding',       function(v, UB, OD) BBar:ChangeBox(ChangeComboPoints, 'SetBackdropPadding', BoxMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v, UB, OD) BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB, OD)
      if UB[OD.TableName].EnableBorderColor then
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture', function(v, UB, OD) BBar:ChangeBox(ChangeComboPoints,'SetTexture', ComboSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v, UB, OD) BBar:ChangeBox(ChangeComboPoints,'SetRotationTexture', ComboSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD) BBar:SetColorTexture(OD.Index, ComboSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',            function(v, UB, OD) BBar:ChangeBox(ChangeComboPoints,'SetSizeTextureFrame', BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v, UB, OD) BBar:ChangeBox(ChangeComboPoints,'SetPaddingTextureFrame', BoxMode, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the combo bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ComboBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxComboPoints)

  local Names = {}
  local Name

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 1)
    BBar:CreateTexture(0, BoxMode, ComboSBar, 'statusbar')

  -- Create texture mode.
  for ComboIndex = 1, MaxComboPoints do
    BBar:SetFillTexture(ComboIndex, ComboSBar, 1)

    BBar:CreateTextureFrame(ComboIndex, TextureMode, 1)
    for _, CD in ipairs(ComboData) do
      local TextureNumber = CD.TextureNumber

      BBar:CreateTexture(ComboIndex, TextureMode, TextureNumber, 'texture')
      BBar:SetAtlasTexture(ComboIndex, TextureNumber, CD.AtlasName)
      BBar:SetSizeTexture(ComboIndex, TextureNumber, CD.Width, CD.Height)
    end
    Name = GroupsInfo[ComboIndex][2]

    BBar:SetTooltipBox(ComboIndex, Name)
    Names[ComboIndex] = Name
  end

  BBar:SetHiddenTexture(0, ComboSBar, true)
  BBar:SetHiddenTexture(0, ComboDarkTexture, false)

  BBar:SetChangeBox(ChangeComboPoints, 1, 2, 3, 4, 5, 6)

  BBar:ChangeBox(ChangeComboPoints, 'SetSizeTextureFrame', BoxMode, UB.Bar.Width, UB.Bar.Height)

  BBar:SetSizeTextureFrame(0, TextureMode, ComboData.TextureWidth, ComboData.TextureHeight)

  BBar:SetChangeTexture(ChangePoints, ComboLightTexture, ComboSBar)

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  -- Set the texture scale for bar offset triggers.
  BBar:SetScaleAllTexture(0, AllTextures, 1)
  BBar:SetOffsetTextureFrame(0, BoxMode, 0, 0, 0, 0)

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Combobar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.ComboBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end
