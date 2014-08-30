--
-- HolyBar.lua
--
-- Displays Paladin holy power.

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
-- UnitBarF.BBar                     Contains the holy bar displayed on screen.
--
-- RuneSBar                          Holy rune for box mode.
-- RuneDarkTexture                   Dark holy rune texture for texture mode.
-- RuneLightTexture                  Lit holy rune texture for texture mode.
-- TextureMode                       TextureFrame number for texture mode.
-- BoxMode                           TextureFrame number for box mode.
-- Runes                             ChangeTexture number for RuneLightTexture and RuneBar.
-- Display                           Flag used to determin if a Display() call is needed.
--
-- AnyRuneTrigger                    Trigger for any rune that is currently active.
-- RegionTrigger                     Trigger for region changes.
-- TriggerGroups                     Table containing boxnumber and condition type for triggers.
-- DoTriggers                        True by passes visible and isactive flags. If not nil then calls
--                                   self:Update(DoTriggers)
-- HolyData                          Contains the data to create the holy bar.
--   Texture                         Texture that contains the holy runes.
--   BoxWidth, BoxHeight             Size of the boxes in texture mode.
--   Runes[Rune].Width               Width of the rune texture.
--   [Rune Number]
--     Point                         Texture point inside the texture frame.
--     OffsetX, OffsetY              Offset the texture inside the texture frame.
--     Width, Height                 Width and Height of the rune texture and the texture frame.
--     Left, Right, Top, Bottom      Texture coordinates inside of the HolyPowerTexture
--                                   containing the holy rune.
-------------------------------------------------------------------------------
local MaxHolyRunes = 5
local Display = false
local DoTriggers = false

-- Powertype constants
local PowerHoly = ConvertPowerType['HOLY_POWER']

-- Holyrune Texture constants
local BoxMode = 1
local TextureMode = 2

local Runes = 3

local RuneSBar = 10
local RuneDarkTexture = 12
local RuneLightTexture = 13

local AnyRuneTrigger = 6
local RegionTrigger = 7
local TGBoxNumber = 1
local TGName = 2
local TGValueTypes = 3
local VTs = {'whole:Holy Power', 'auras:Auras'}
local TriggerGroups = { -- BoxNumber, Name, ValueTypes,
  {1,  'Holy Rune 1',    VTs}, -- 1
  {2,  'Holy Rune 2',    VTs}, -- 2
  {3,  'Holy Rune 3',    VTs}, -- 3
  {4,  'Holy Rune 4',    VTs}, -- 4
  {5,  'Holy Rune 5',    VTs}, -- 5
  {0,  'Any Holy Rune', {'boolean:Active', 'auras:Auras'}},   -- 6
  {-1, 'Region',         VTs},                                -- 7
}


local HolyData = {
  Texture = [[Interface\PlayerFrame\PaladinPowerTextures]],

  -- TextureFrame size.
  BoxWidth = 42 + 8, BoxHeight = 31,
  DarkColor = {r = 0.15, g = 0.15, b = 0.15, a = 1},
  { -- 1
    OffsetX = 1, OffsetY = 0,
    Width = 36 + 5, Height = 22 + 5,
    Left = 0.00390625, Right = 0.14453125, Top = 0.78906250, Bottom = 0.96093750
  },
  { -- 2
    OffsetX = 1, OffsetY = 0,
    Width = 31 + 14, Height = 17 + 14,
    Left = 0.15234375, Right = 0.27343750, Top = 0.78906250, Bottom = 0.92187500
  },
  { -- 3
    OffsetX = 0, OffsetY = 0,
    Width = 27 + 10 , Height = 21 + 10,
    Left = 0.28125000, Right = 0.38671875, Top = 0.64843750, Bottom = 0.81250000
  },
  { -- 4 Rune1 texture that's rotated.
    OffsetX = -1, OffsetY = 0,
    Width = 36 + 5, Height = 17 + 12,
    Left = 0.14453125, Right = 0.00390625, Top = 0.78906250, Bottom = 0.96093750
  },
  { -- 5 Rune2 texture that's rotated.
    OffsetX = -1, OffsetY = 0,
    Width = 31 + 14, Height = 17 + 14,
    Left = 0.27343750, Right = 0.15234375, Top = 0.78906250, Bottom = 0.92187500
  },
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.HolyBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Holybar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the holy power level of the player
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.HolyBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerHoly

  -- Return if not the correct powertype.
  if PowerType ~= PowerHoly then
    return
  end

  local BBar = self.BBar
  local HolyPower = UnitPower('player', PowerHoly)
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers

  if Main.UnitBars.Testing then
    HolyPower = floor(MaxHolyRunes * self.UnitBar.TestMode.Value)
  end

  for RuneIndex = 1, MaxHolyRunes do
    if EnableTriggers then
      BBar:SetTriggers(AnyRuneTrigger, 'active', RuneIndex <= HolyPower, nil, RuneIndex)
      BBar:SetTriggers(RuneIndex, 'holy power', HolyPower)
    end

    BBar:ChangeTexture(Runes, 'SetHiddenTexture', RuneIndex, RuneIndex > HolyPower)
  end

  if EnableTriggers then
    BBar:SetTriggers(RegionTrigger, 'holy power', HolyPower)
    BBar:DoTriggers()
  end

  -- Set this IsActive flag
  self.IsActive = HolyPower > 0

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Holybar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the holy bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.HolyBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- Enable/disable for border.
  BBar:EnableMouseClicksRegion(Enable)

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the holybar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.HolyBar:SetAttr(TableName, KeyName)
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
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarTexture,            TT.Type_BarTexture,            'SetTexture', BoxNumber, RuneSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarColor,              TT.Type_BarColor,              'SetColorTexture', BoxNumber, RuneSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_TextureSize,           TT.Type_TextureSize,           'SetScaleTexture', BoxNumber, RuneDarkTexture, RuneLightTexture)
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
          BBar:SetScaleTexture(0, RuneDarkTexture, 1)
          BBar:SetScaleTexture(0, RuneLightTexture, 1)

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
    BBar:SO('Layout', 'BoxMode',        function(v)
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
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, RuneSBar, 'in', v)
                                                   BBar:SetFadeTimeTexture(0, RuneLightTexture, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, RuneSBar, 'out', v)
                                                   BBar:SetFadeTimeTexture(0, RuneLightTexture, 'out', v) end)
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

    BBar:SO('Bar', 'StatusBarTexture', function(v) BBar:SetTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v) BBar:SetRotateTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD) BBar:SetColorTexture(OD.Index, RuneSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',            function(v, UB) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v) BBar:SetPaddingTexture(0, RuneSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the holy rune bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.HolyBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxHolyRunes)

  local Names = {Trigger = {}, Color = {}}
  local Trigger = Names.Trigger
  local Color = Names.Color
  local DarkColor = HolyData.DarkColor

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, RuneSBar)

  -- Create texture mode.
  for RuneIndex, HD in ipairs(HolyData) do

    BBar:CreateTextureFrame(RuneIndex, TextureMode, 0)
      BBar:CreateTexture(RuneIndex, TextureMode, 'texture', 1, RuneDarkTexture)
      BBar:CreateTexture(RuneIndex, TextureMode, 'texture', 2, RuneLightTexture)

    BBar:SetTexture(RuneIndex, RuneDarkTexture, HolyData.Texture)
    BBar:SetTexture(RuneIndex, RuneLightTexture, HolyData.Texture)

    BBar:SetSizeTexture(RuneIndex, RuneDarkTexture, HD.Width, HD.Height)
    BBar:SetSizeTexture(RuneIndex, RuneLightTexture, HD.Width, HD.Height)

    BBar:SetCoordTexture(RuneIndex, RuneDarkTexture, HD.Left, HD.Right, HD.Top, HD.Bottom)
    BBar:SetGreyscaleTexture(RuneIndex, RuneDarkTexture, true)
    BBar:SetColorTexture(RuneIndex, RuneDarkTexture, DarkColor.r, DarkColor.g, DarkColor.b, DarkColor.a)

    BBar:SetCoordTexture(RuneIndex, RuneLightTexture, HD.Left, HD.Right, HD.Top, HD.Bottom)

     -- Set and save the name for tooltips for box mode.
    local Name = TriggerGroups[RuneIndex][TGName]

    BBar:SetTooltip(RuneIndex, nil, Name)

    Color[RuneIndex] = Name
    Trigger[RuneIndex] = Name
  end

  Trigger[AnyRuneTrigger] = TriggerGroups[AnyRuneTrigger][TGName]
  Trigger[RegionTrigger] = TriggerGroups[RegionTrigger][TGName]

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, HolyData.BoxWidth, HolyData.BoxHeight)

  BBar:SetChangeTexture(Runes, RuneLightTexture, RuneSBar)
  BBar:SetHiddenTexture(0, RuneDarkTexture, false)

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Holybar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.HolyBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
  Main:RegEventFrame(Enable, self, 'UNIT_POWER', self.Update, 'player')
end
