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
local TT = GUB.DefaultUB.TriggerTypes

local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _, _G =
      _, _G
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt,      mhuge =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt, math.huge
local strfind, strmatch, strsplit, strsub, strtrim, strupper, strlower, format, gsub, gmatch =
      strfind, strmatch, strsplit, strsub, strtrim, strupper, strlower, format, gsub, gmatch
local GetTime, ipairs, pairs, next, pcall, print, select, tonumber, tostring, tremove, tinsert, type, unpack, sort =
      GetTime, ipairs, pairs, next, pcall, print, select, tonumber, tostring, tremove, tinsert, type, unpack, sort

local UnitPower, UnitPowerMax =
      UnitPower, UnitPowerMax

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains an instance of bar functions for combo bar.
--
-- NOTES:  For anticipation alpha to work correctly.  SetAttr() gets called after
--         The whole bar is faded in.  Then I use SetShowHideFnTexture() during creation.
--         So when an anticipation point fades out.  The anticipation alpha gets set to that
--         box after.  Then the Update() code sets the alpha back to 1 for lit anticipation
--         points.  This creates a fade animation that looks good.
-------------------------------------------------------------------------------
local MaxComboPoints = 11
local ExtraComboPointStart = 6
local Display = false
local Update = false
local NamePrefix = 'Combo '
local NamePrefix2 = 'Point '

-- Powertype constants
local PowerPoint = ConvertPowerType['COMBO_POINTS']

local BoxMode = 1
local TextureMode = 2

local ChangePoints = 3
local ChangeComboPoints = 4
local ChangeAnticipationPoints = 5

local AllTextures = 11

local ComboSBar = 10
local ComboDarkTexture = 11
local ComboLightTexture = 12

local RegionGroup = 11

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
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,            ComboSBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,              ComboSBar,
    GF = GF },
  { TT.TypeID_BarOffset,             TT.Type_BarOffset,             BoxMode },
  { TT.TypeID_TextureScale,          TT.Type_TextureScale,          AllTextures },
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

local VTs = {'whole', 'Total Points',
             'whole', 'Combo Points',
             'whole', 'Anticipation Points',
             'auras', 'Auras'               }

local Groups = { -- BoxNumber, Name, ValueTypes,
  {1,   'Point 1',  VTs, TD}, -- 1
  {2,   'Point 2',  VTs, TD}, -- 2
  {3,   'Point 3',  VTs, TD}, -- 3
  {4,   'Point 4',  VTs, TD}, -- 4
  {5,   'Point 5',  VTs, TD}, -- 5
  {6,   'Point 6',  VTs, TD}, -- 6
  {7,   'Ant 1',    VTs, TD}, -- 7
  {8,   'Ant 2',    VTs, TD}, -- 8
  {9,   'Ant 3',    VTs, TD}, -- 9
  {10,  'Ant 4',    VTs, TD}, -- 10
  {11,  'Ant 5',    VTs, TD}, -- 11
  {'a', 'All', {'whole', 'Total Points',
                'whole', 'Combo Points',
                'whole', 'Anticipation Points',
                'state', 'Active',
                'auras', 'Auras'               }, TD},   -- 10
  {'r', 'Region',     VTs, TDregion},  -- 11
}

-- Combo layouts
local ComboLayout = {
  [5]  = {[6] = true,  [7] = true,  [8] = true,  [9] = true,  [10] = true,  [11] = true  },
  [6]  = {[6] = false, [7] = true,  [8] = true,  [9] = true,  [10] = true,  [11] = true  },
  [10] = {[6] = true,  [7] = false, [8] = false, [9] = false, [10] = false, [11] = false },
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
-- SetAnticipationAlpha
--
-- Called when one of the anticipation textures get hidden or shown.
-- Then this will appy the alpha setting.
--
-- BBar           Current bar being used.
-- BoxNumber      Box that contains the texture
-- TextureNumber  Texture that got hidden or shown
-- Action         'hide' or 'show'
-------------------------------------------------------------------------------
local function SetAnticipationAlpha(UnitBarF, BBar, BoxNumber, TextureNumber, Action)
  if Action == 'hide' then
    BBar:SetAlpha(BoxNumber, nil, UnitBarF.UnitBar.Layout.InactiveAnticipationAlpha)
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of combo points of the player
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
--
-- NOTES: Normally the invisibility check is at the top.  But I need to check
--        for total boxes first. So the first BBar:Display() contains the
--        total boxes on the first call.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ComboBar:Update(Event, Unit, PowerType)
  PowerType = PowerType and ConvertPowerType[PowerType] or PowerPoint

  -- Return if not the correct powertype.
  if PowerType ~= PowerPoint then
    return
  end

  local BBar = self.BBar
  local NumPointsChanged = false
  local ComboPoints = UnitPower('player', PowerPoint)
  local NumPoints = UnitPowerMax('player', PowerPoint)

  if Main.UnitBars.Testing then
    local TestMode = self.UnitBar.TestMode

    if TestMode.Anticipation then
      NumPoints = MaxComboPoints - 1
    elseif TestMode.DeeperStratagem then
      NumPoints = ExtraComboPointStart
    else
      NumPoints = ExtraComboPointStart - 1
    end
    ComboPoints = TestMode.ComboPoints

    -- Clip combo points
    if ComboPoints > NumPoints then
      ComboPoints = NumPoints
    end
  end

  if NumPoints ~= self.NumPoints then
    self.NumPoints = NumPoints

    -- Change the number of boxes in the bar.
    for Index, Hidden in pairs(ComboLayout[NumPoints] or ComboLayout[5]) do
      BBar:SetHidden(Index, nil, Hidden)
    end
    BBar:Display()
    NumPointsChanged = true
  end

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  local UB = self.UnitBar
  local InactiveAnticipationAlpha = UB.Layout.InactiveAnticipationAlpha
  local EnableTriggers = UB.Layout.EnableTriggers
  local CPoints = 0
  local APoints = 0
  local TotalPoints = 0

  -- Convert combo points
  if NumPoints == MaxComboPoints - 1 and ComboPoints > ExtraComboPointStart - 1 then
    ComboPoints = ComboPoints + 1
  end

  for ComboIndex = 1, MaxComboPoints do
    BBar:ChangeTexture(ChangePoints, 'SetHiddenTexture', ComboIndex, ComboIndex > ComboPoints)

    if ComboIndex > ExtraComboPointStart then
      if ComboIndex <= ComboPoints then
        BBar:SetAlpha(ComboIndex, nil, 1)

      -- if size of bar changed then reset anticipation alpha
      elseif NumPointsChanged then
        BBar:SetAlpha(ComboIndex, nil, InactiveAnticipationAlpha)
      end
    end

    if EnableTriggers then
      if ComboPoints > ExtraComboPointStart then
        APoints = ComboPoints - ExtraComboPointStart
        CPoints = ExtraComboPointStart - 1
      else
        CPoints = ComboPoints
      end
      TotalPoints = CPoints + APoints

      BBar:SetTriggers(ComboIndex, 'combo points', CPoints)
      BBar:SetTriggers(ComboIndex, 'anticipation points', APoints)
      BBar:SetTriggers(ComboIndex, 'total points', TotalPoints)
      BBar:SetTriggers(ComboIndex, 'active', ComboIndex <= ComboPoints)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers(RegionGroup, 'combo points', ComboPoints)
    BBar:SetTriggers(RegionGroup, 'anticipation points', APoints)
    BBar:SetTriggers(RegionGroup, 'total points', TotalPoints)
    BBar:DoTriggers()
  end

  -- Set the IsActive flag.
  self.IsActive = ComboPoints > 0

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Combobar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the combo bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ComboBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- Enable/disable for border.
  BBar:EnableMouseClicksRegion(Enable)

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the combo bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ComboBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then
    BBar:SetOptionData('BackgroundCombo', ChangeComboPoints)
    BBar:SetOptionData('BackgroundAnticipation', ChangeAnticipationPoints)
    BBar:SetOptionData('BarCombo', ChangeComboPoints)
    BBar:SetOptionData('BarAnticipation', ChangeAnticipationPoints)

    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers',   function(v) BBar:EnableTriggers(v, Groups) Update = true end)
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
    BBar:SO('Layout', 'TextureScaleAnticipation',  function(v) BBar:ChangeBox(ChangeAnticipationPoints, 'SetScaleTextureFrame', TextureMode, v) Display = true end)
    BBar:SO('Layout', 'InactiveAnticipationAlpha', function(v) BBar:ChangeBox(ChangeAnticipationPoints, 'SetAlpha', nil, v) Display = true end)

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

    BBar:SO('Background', 'BgTexture',     function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdrop', BoxMode, v) end)
    BBar:SO('Background', 'BorderTexture', function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropBorder', BoxMode, v) end)
    BBar:SO('Background', 'BgTile',        function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropTile', BoxMode, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropTileSize', BoxMode, v) end)
    BBar:SO('Background', 'BorderSize',    function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropBorderSize', BoxMode, v) end)
    BBar:SO('Background', 'Padding',       function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropPadding', BoxMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v, UB, OD) BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB, OD)
      if UB[OD.TableName].EnableBorderColor then
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture', function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetTexture', ComboSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetRotationTexture', ComboSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD) BBar:SetColorTexture(OD.Index, ComboSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',            function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetSizeTextureFrame', BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetPaddingTextureFrame', BoxMode, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
  local Name = nil

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
    if ComboIndex < ExtraComboPointStart + 1 then
      Name = NamePrefix .. Groups[ComboIndex][2]
    else
      local Left, Right = strsplit(' ', Groups[ComboIndex][2], 2)
      Name = Left .. ' ' .. NamePrefix2 .. Right
    end

    -- Set call backs for anticpation point hiding/showing
    if ComboIndex > ExtraComboPointStart then
      BBar:SetShowHideFnTexture(ComboIndex, ComboSBar, SetAnticipationAlpha)
      BBar:SetShowHideFnTexture(ComboIndex, ComboLightTexture, SetAnticipationAlpha)
    end

    BBar:SetTooltip(ComboIndex, nil, Name)
    Names[ComboIndex] = Name
  end

  BBar:SetHiddenTexture(0, ComboSBar, true)
  BBar:SetHiddenTexture(0, ComboDarkTexture, false)

  BBar:SetChangeBox(ChangeComboPoints, 1, 2, 3, 4, 5, 6)
  BBar:SetChangeBox(ChangeAnticipationPoints, 7, 8, 9, 10, 11)

  BBar:ChangeBox(ChangeComboPoints, 'SetSizeTextureFrame', BoxMode, UB.BarCombo.Width, UB.BarCombo.Height)
  BBar:ChangeBox(ChangeAnticipationPoints, 'SetSizeTextureFrame', BoxMode, UB.BarAnticipation.Width, UB.BarAnticipation.Height)

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
