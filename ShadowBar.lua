--
-- ShadowBar.lua
--
-- Displays the priest shadow bar.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local ConvertPowerType = Main.ConvertPowerType
local TT = GUB.DefaultUB.TriggerTypes

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
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapped, UnitIsTappedByPlayer, UnitIsTappedByAllThreatList
local UnitName, UnitReaction, UnitGetIncomingHeals, GetRealmName, UnitCanAttack, UnitPlayerControlled, UnitIsPVP =
      UnitName, UnitReaction, UnitGetIncomingHeals, GetRealmName, UnitCanAttack, UnitPlayerControlled, UnitIsPVP
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
-- UnitBarF.ShadowBar                Contains the shadow bar displayed on screen.
--
-- ShadowData                        Contains all the data for the shadow bar.
--   Texture                         Path name to the texture.
--   TextureWidth, TextureHeight     Width and Height of the orbs in texture mode.
--   [TextureType]
--     Level                         Frame level to display the texture on.
--     Width, Height                 Width and Height of the texture.
--     Left, Right, Top, Bottom      Texcoords inside the Texture that locate each texture.
--
-- OrbSBar                           Texture for orb in box mode.
-- OrbDarkTexture                    Dark texture for orb in texture mode.
-- OrbGlowTexture                    Glowing texture for orb in texture mode.
-- Orbs                              Change texture for OrbSBar and OrbGlowTexture
--
-- ActiveOrbTrigger                  Trigger for any shadow orb that is currently active.
-- RegionTrigger                     Trigger to make changes to the region.
-- TriggerGroups                     Trigger groups for boxnumber and condition type.
-- DoTriggers                        True by passes visible and isactive flags. If not nil then calls
--                                   self:Update(DoTriggers)
-------------------------------------------------------------------------------
local MaxShadowOrbs = 5
local Display = false
local DoTriggers = false

-- Powertype constants
local PowerShadow = ConvertPowerType['SHADOW_ORBS']

-- shadow orbs Texture constants
local BoxMode = 1
local TextureMode = 2

local Orbs = 3

local OrbSBar = 10
local OrbDarkTexture = 20
local OrbGlowTexture = 21

local AnyOrbTrigger = 6
local RegionTrigger = 7
local TGBoxNumber = 1
local TGName = 2
local TGValueTypes = 3
local VTs = {'whole:Shadow Orbs', 'auras:Auras'}
local TriggerGroups = { -- BoxNumber, Name, ValueTypes,
  {1,  'Shadow Orb 1',    VTs}, -- 1
  {2,  'Shadow Orb 2',    VTs}, -- 2
  {3,  'Shadow Orb 3',    VTs}, -- 3
  {4,  'Shadow Orb 4',    VTs}, -- 4
  {5,  'Shadow Orb 5',    VTs}, -- 5
  {0,  'Any Shadow Orb',  {'boolean:Active', 'auras:Auras'}},   -- 6
  {-1, 'Region',          VTs}, -- 7
}

local ShadowData = {
  Texture = [[Interface\PlayerFrame\Priest-ShadowUI]],
  TextureWidth = 38 + 4, TextureHeight = 37 + 4,
  [OrbDarkTexture] = {
    Level = 1,
    Width = 38, Height = 37,
    Left = 0.30078125, Right = 0.44921875, Top = 0.44531250, Bottom = 0.73437500
  },
  [OrbGlowTexture] = {
    Level = 2,
    Width = 38, Height = 37,
    Left = 0.45703125, Right = 0.60546875, Top = 0.44531250, Bottom = 0.73437500
  },
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.ShadowBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Shadowbar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of shadow orbs of the player
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ShadowBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerShadow

  -- Return if not the correct powertype.
  if PowerType ~= PowerShadow then
    return
  end

  local ShadowOrbs = UnitPower('player', PowerShadow)
  local NumOrbs = UnitPowerMax('player', PowerShadow)
  local BBar = self.BBar
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers

  if Main.UnitBars.Testing then
    local TestMode = self.UnitBar.TestMode

    if TestMode.ShowEnhancedShadowOrbs then
      NumOrbs = MaxShadowOrbs
    else
      NumOrbs = MaxShadowOrbs - 2
    end

    ShadowOrbs = floor(MaxShadowOrbs * TestMode.Value)
  end

  -- Check for max chi change
  if NumOrbs ~= self.NumOrbs then

    -- Change the number of boxes in the bar.
    local Hide = NumOrbs ~= MaxShadowOrbs
    BBar:SetHidden(MaxShadowOrbs - 1, nil, NumOrbs ~= MaxShadowOrbs)
    BBar:SetHidden(MaxShadowOrbs,     nil, NumOrbs ~= MaxShadowOrbs)

    BBar:Display()
    self.NumOrbs = NumOrbs
  end

  for OrbIndex = 1, MaxShadowOrbs do
    BBar:ChangeTexture(Orbs, 'SetHiddenTexture', OrbIndex, OrbIndex > ShadowOrbs)

    if EnableTriggers then
      BBar:SetTriggers(AnyOrbTrigger, 'active', OrbIndex <= ShadowOrbs, nil, OrbIndex)
      BBar:SetTriggers(OrbIndex, 'shadow orbs', ShadowOrbs)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers(RegionTrigger, 'shadow orbs', ShadowOrbs)
    BBar:DoTriggers()
  end

  -- Set this IsActive flag
  self.IsActive = ShadowOrbs > 0

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Shadowbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the shadow bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ShadowBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- Enable/disable for border.
  BBar:EnableMouseClicksRegion(Enable)

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the shadowbar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.ShadowBar:SetAttr(TableName, KeyName)
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
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarTexture,            TT.Type_BarTexture,            'SetTexture', BoxNumber, OrbSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarColor,              TT.Type_BarColor,              'SetColorTexture', BoxNumber, OrbSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_TextureSize,           TT.Type_TextureSize,           'SetScaleTexture', BoxNumber, OrbDarkTexture, OrbGlowTexture)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_Sound,                 TT.Type_Sound,                 'PlaySound', BoxNumber)

              -- Class Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor, TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,       TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor,              TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)

              -- Power Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor, TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,       TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor,              TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)

              -- Combat Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor, TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,       TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor,              TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)

              -- Tagged Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor, TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,       TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor,              TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
            else
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBorder,          TT.Type_RegionBorder,          'SetBackdropBorderRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBorderColor,     TT.Type_RegionBorderColor,     'SetBackdropBorderColorRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBackground,      TT.Type_RegionBackground,      'SetBackdropRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBackgroundColor, TT.Type_RegionBackgroundColor, 'SetBackdropColorRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_Sound,                 TT.Type_Sound,                 'PlaySound', 1)

              -- Class Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_RegionBorderColor,     TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_RegionBackgroundColor, TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)

              -- Power Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_RegionBorderColor,     TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_RegionBackgroundColor, TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)

              -- Combat Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_RegionBorderColor,     TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_RegionBackgroundColor, TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)

              -- Tagged Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_RegionBorderColor,     TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_RegionBackgroundColor, TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
            end
          end
          -- Set the texture scale for Texture Size triggers.
          BBar:SetScaleTexture(0, OrbDarkTexture, 1)
          BBar:SetScaleTexture(0, OrbGlowTexture, 1)

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
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, OrbSBar, 'in', v)
                                                   BBar:SetFadeTimeTexture(0, OrbGlowTexture, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, OrbSBar, 'out', v)
                                                   BBar:SetFadeTimeTexture(0, OrbGlowTexture, 'out', v) end)
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

    BBar:SO('Bar', 'StatusBarTexture',  function(v) BBar:SetTexture(0, OrbSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',     function(v) BBar:SetRotateTexture(0, OrbSBar, v) end)
    BBar:SO('Bar', 'Color',             function(v, UB, OD) BBar:SetColorTexture(OD.Index, OrbSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',             function(v, UB) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',           function(v) BBar:SetPaddingTexture(0, OrbSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the shadow bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ShadowBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxShadowOrbs)

  local Names = {Trigger = {}, Color = {}}
  local Trigger = Names.Trigger
  local Color = Names.Color

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, OrbSBar)

  -- Create texture mode.
  for OrbIndex = 1, MaxShadowOrbs do
    BBar:CreateTextureFrame(OrbIndex, TextureMode, 0)

    for TextureNumber, SD in pairs(ShadowData) do
      if type(TextureNumber) == 'number' then
        BBar:CreateTexture(OrbIndex, TextureMode, 'texture', SD.Level, TextureNumber)

        BBar:SetTexture(OrbIndex, TextureNumber, ShadowData.Texture)
        BBar:SetCoordTexture(OrbIndex, TextureNumber, SD.Left, SD.Right, SD.Top, SD.Bottom)
        BBar:SetSizeTexture(OrbIndex, TextureNumber, SD.Width, SD.Height)
      end
    end
    local Name = TriggerGroups[OrbIndex][TGName]

    BBar:SetTooltip(OrbIndex, nil, Name)
    Color[OrbIndex] = Name
    Trigger[OrbIndex] = Name
  end

  Trigger[AnyOrbTrigger] = TriggerGroups[AnyOrbTrigger][TGName]
  Trigger[RegionTrigger] = TriggerGroups[RegionTrigger][TGName]

  BBar:SetHiddenTexture(0, OrbSBar, false)
  BBar:SetHiddenTexture(0, OrbDarkTexture, false)

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, ShadowData.TextureWidth, ShadowData.TextureHeight)

  BBar:SetChangeTexture(Orbs, OrbGlowTexture, OrbSBar)

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Shadowbar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.ShadowBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end

