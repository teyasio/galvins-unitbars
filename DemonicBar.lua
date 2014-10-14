--
-- DemonicBar.lua
--
-- Displays the Warlock demonic fury bar.

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
local C_PetBattles, UIParent =
      C_PetBattles, UIParent

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.UnitBar                  Reference to the unitbar data for the demonic bar.
--
-- UnitBarF.BBar                     Contains the demonic bar displayed on screen.
--
-- FBar                              FurySBar and FuryMetaSBar.
-- FMeta                             FuryTexture, FuryBdTexture, FuryNotch, and FurySBar for meta.
-- FNormal                           Same as FMeta except for when not in meta.
--
-- FurySBar                          Demonic Fury in box mode statusbar.
-- FuryMetaSBar                      Like FurySBar except shown in metamorphosis.
-- FuryBgTexture                     Background for the demonic bar texture.
-- FuryTexture                       The bar that shows how much demonic fury is present.
-- FuryMetaTexture                   Like FuryTexture except shown in metamorphosis.
-- FuryBdTexture                     Texture that fits around the demonic bar.
-- FuryBdMetaTexture                 Like FuryBdTexture except shown in metamorphosis.
-- FuryNotchTexture                  Shows the 20% mark on the normal bar.
-- FuryNotchMetaTexture              Shows the 20% mark on the metamorphosis bar.
--                                   These 8 variables are used to reference the different textures/statusbar.
--
-- LastDemonicFury                   Keeps track of change in demonic fury.
-- MaxDemonicFury                    Keeps track if max demonic fury changes.
--
-- BarOffsetX, BarOffsetY            Offset the whole bar within the border.
--
-- MetaAura                          SpellID for the metamorphosis aura.
--
-- BothValueTrigger                  Trigger works in metamorphosis or normal.
-- NormalValueTrigger                Trigger for fury when not in metamorphosis
-- MetaValueTrigger                  Trigger for fury when in metamorphosis
-- MetaTrigger                       Trigger for detecting metamorphosis
-- TriggerGroups                     Contains the condition type for each trigger.
-- DoTriggers                        True by passes visible and isactive flags. If not nil then calls
--                                   self:Update(DoTriggers)
--
-- DemonicData                       Table containing all the data to build the demonic fury bar.
--   Texture                         Path to the texture file.
--   BoxWidth, BoxHeight             Width and Height of the bars border for texture mode.
--   TextureWidth, TextureHeight     Size of all the TextureFrames in the bar.
--   [TextureType]                   Texture Number containing the type of texture to use.
--      Point                        Setpoint() position.
--      Level                        Texture level that the texture is displayed on.
--      OffsetX, OffsetY             Offset from the point location of where the texture is placed.
--      ReverseX                     Used to position the notch in reverse fill.
--      Width, Height                Width and Height of the texture.
--      Left, Right, Top, Bottom     Texcoordinates of the texture.
-------------------------------------------------------------------------------
local Display = false
local DoTriggers = false

-- Powertype constants
local PowerDemonicFury = ConvertPowerType['DEMONIC_FURY']

local BoxMode = 1
local TextureMode = 2

local FBar = 3
local FMeta = 4
local FNormal = 5

local FuryBgTexture = 10
local FuryTexture = 11
local FuryMetaTexture = 12
local FuryBdTexture = 13
local FuryBdMetaTexture = 14
local FuryNotchTexture = 15
local FuryNotchMetaTexture = 16
local FurySBar = 20
local FuryMetaSBar = 21

local MetaAura = 103958 -- Warlock metamorphosis spell ID aura.

local ReverseFuryNotchOffset = 124.6  -- Used in texture mode in reverse fill.

local BarOffsetX = 2
local BarOffsetY = 0

local DemonicData = {
  Texture = [[Interface\PlayerFrame\Warlock-DemonologyUI]],
  BoxWidth = 145, BoxHeight = 35,

  -- TextureFrame size
  TextureWidth = 169, TextureHeight = 52,
  [FuryBgTexture] = {
    Level = 1,
    Point = 'CENTER',
    OffsetX = -2 + BarOffsetX, OffsetY = -1 + BarOffsetY,
    Width = 132, Height= 24,
    Left = 0.03906250, Right = 0.55468750, Top = 0.20703125, Bottom = 0.30078125
  },
  [FuryTexture] = {
    Level = 2,
    Point = 'LEFT',
    OffsetX = 17 + BarOffsetX -12, OffsetY = -1 + BarOffsetY,
    Width = 132, Height = 24,
    Left = 0.03906250, Right = 0.55468750, Top= 0.10546875, Bottom = 0.19921875
  },
  [FuryMetaTexture] = {
    Level = 2,
    Point = 'LEFT',
    OffsetX = 17 + BarOffsetX -12, OffsetY = -1 + BarOffsetY,
    Width = 132, Height = 24,
    Left = 0.03906250, Right = 0.55468750, Top = 0.00390625, Bottom = 0.09765625
  },
  [FuryBdTexture] = {
    Level = 3,
    Point = 'LEFT',
    OffsetX = 0 + BarOffsetX - 12, OffsetY = 0 + BarOffsetY,
    Width = 169, Height = 52,
    Left = 0.03906250, Right = 0.69921875, Top = 0.51953125, Bottom = 0.72265625
  },
  [FuryBdMetaTexture] = {
    Level = 3,
    Point = 'LEFT',
    OffsetX = 0 + BarOffsetX - 12, OffsetY = 0 + BarOffsetY,
    Width = 169, Height = 52,
    Left = 0.03906250, Right = 0.69921875, Top = 0.30859375, Bottom = 0.51171875
  },
  [FuryNotchTexture] = {
    Level = 4,
    Point = 'LEFT',
    OffsetX = 40 + BarOffsetX -12, OffsetY = -1 + BarOffsetY, ReverseX = 121 - 12,
    Width = 7, Height = 22,
    Left = 0.00390625, Right = 0.03125000, Top = 0.09765625, Bottom = 0.18359375
  },
  [FuryNotchMetaTexture] = {
    Level = 4,
    Point = 'LEFT',
    OffsetX = 40 + BarOffsetX -12, OffsetY = -1 + BarOffsetY, ReverseX = 121 - 12,
    Width = 7, Height = 22,
    Left = 0.00390625, Right = 0.03125000, Top = 0.00390625, Bottom = 0.08984375
  }
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.DemonicBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Demonicbar display
--
--*****************************************************************************

-- Used by SetValueFont to calculate percentage.
local function PercentFn(Value, MaxValue)
  return ceil(Value / MaxValue * 100)
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the amount of demonic fury.
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True by passes visible and isactive flags.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.DemonicBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerDemonicFury

  -- Return if not the correct powertype.
  if PowerType ~= PowerDemonicFury then
    return
  end

  local BBar = self.BBar
  local UB = self.UnitBar
  local DemonicFury = UnitPower('player', PowerDemonicFury)
  local MaxDemonicFury = UnitPowerMax('player', PowerDemonicFury)
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers

  -- Check for metamorphosis.
  local Meta = Main:CheckAura('a', MetaAura)

  if Main.UnitBars.Testing then
    local TestMode = UB.TestMode

    MaxDemonicFury = 1000
    DemonicFury = floor(MaxDemonicFury * TestMode.Value)
    Meta = TestMode.ShowMeta
  end

  -- If meta then change texture or box color.
  if Meta ~= self.MetaActive then
    local BBar = self.BBar

    self.MetaActive = Meta
    BBar:ChangeTexture(FNormal, 'SetHiddenTexture', 1, Meta)
    BBar:ChangeTexture(FMeta, 'SetHiddenTexture', 1, not Meta)
  end

  local Value = 0

  -- Check for devision by zero
  if MaxDemonicFury > 0 then
    Value = DemonicFury / MaxDemonicFury
  end

  BBar:ChangeTexture(FBar, 'SetFillTexture', 1, Value)
  if not UB.Layout.HideText then
    BBar:SetValueFont(1, nil, 'current', DemonicFury, 'maximum', MaxDemonicFury, 'unit', 'player')
  end

  if EnableTriggers then
    BBar:SetTriggers(1, 'fury both', DemonicFury, MaxDemonicFury)
    BBar:SetTriggers(1, 'fury both (percent)', DemonicFury, MaxDemonicFury)

    if not Meta then
      BBar:SetTriggers(1, 'off', 'fury meta')
      BBar:SetTriggers(1, 'off', 'fury meta (percent)')
      BBar:SetTriggers(1, 'fury normal', DemonicFury, MaxDemonicFury)
      BBar:SetTriggers(1, 'fury normal (percent)', DemonicFury, MaxDemonicFury)
    else
      BBar:SetTriggers(1, 'off', 'fury normal')
      BBar:SetTriggers(1, 'off', 'fury normal (percent)')
      BBar:SetTriggers(1, 'fury meta', DemonicFury, MaxDemonicFury)
      BBar:SetTriggers(1, 'fury meta (percent)', DemonicFury, MaxDemonicFury)
    end
    BBar:SetTriggers(1, 'metamorphosis', Meta)

    BBar:DoTriggers()
  end

  -- Set this IsActive flag when not 20% or in metamorphosis.
  self.IsActive = Value ~= 0.20 or Meta

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Demonicbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the demonic bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.DemonicBar:EnableMouseClicks(Enable)
  self.BBar:EnableMouseClicks(1, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the Demonic bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.DemonicBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then
    BBar:SO('Text', '_Font', function()  BBar:UpdateFont(1) self:Update() end)
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
          BBar:CreateGroupTriggers(1, 'whole:Fury Both',   'percent:Fury Both (percent)',
                                      'whole:Fury Normal', 'percent:Fury Normal (percent)',
                                      'whole:Fury Meta',   'percent:Fury Meta (percent)',
                                      'boolean: Metamorphosis', 'auras:Auras')

          BBar:CreateTypeTriggers(1, TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,          'SetBackdropBorder', 1, BoxMode)
          BBar:CreateTypeTriggers(1, TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor,     'SetBackdropBorderColor', 1, BoxMode)
          BBar:CreateTypeTriggers(1, TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,      'SetBackdrop', 1, BoxMode)
          BBar:CreateTypeTriggers(1, TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,           'SetBackdropColor', 1, BoxMode)
          BBar:CreateTypeTriggers(1, TT.TypeID_BarTexture,            TT.Type_BarTexture .. ' (both)',   'SetTexture', 1, FurySBar, FuryMetaSBar)
          BBar:CreateTypeTriggers(1, TT.TypeID_BarColor,              TT.Type_BarColor   .. ' (both)',   'SetColorTexture', 1, FurySBar, FuryMetaSBar)
          BBar:CreateTypeTriggers(1, TT.TypeID_BarTexture,            TT.Type_BarTexture .. ' (normal)', 'SetTexture', 1, FurySBar)
          BBar:CreateTypeTriggers(1, TT.TypeID_BarColor,              TT.Type_BarColor   .. ' (normal)', 'SetColorTexture', 1, FurySBar)
          BBar:CreateTypeTriggers(1, TT.TypeID_BarTexture,            TT.Type_BarTexture .. ' (meta)',   'SetTexture', 1, FuryMetaSBar)
          BBar:CreateTypeTriggers(1, TT.TypeID_BarColor,              TT.Type_BarColor   .. ' (meta)',   'SetColorTexture', 1, FuryMetaSBar)
          BBar:CreateTypeTriggers(1, TT.TypeID_Sound,                 TT.Type_Sound,                     'PlaySound', 1)

          -- Class Color
          BBar:CreateGetFunctionTriggers(1, TT.Type_BackgroundBorderColor,   TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BackgroundColor,         TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (both)',   TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (normal)', TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (meta)',   TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)

          -- Power Color
          BBar:CreateGetFunctionTriggers(1, TT.Type_BackgroundBorderColor,   TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BackgroundColor,         TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (both)',   TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (normal)', TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (meta)',   TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)

          -- Combat Color
          BBar:CreateGetFunctionTriggers(1, TT.Type_BackgroundBorderColor,   TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BackgroundColor,         TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (both)',   TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (normal)', TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (meta)',   TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)

          -- Tagged Color
          BBar:CreateGetFunctionTriggers(1, TT.Type_BackgroundBorderColor,   TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BackgroundColor,         TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (both)',   TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (normal)', TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
          BBar:CreateGetFunctionTriggers(1, TT.Type_BarColor .. ' (meta)',   TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)

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
        BBar:SetHidden(1, TextureMode, true)
        BBar:SetHidden(1, BoxMode, false)
        BBar:SetChangeTexture(FBar, FurySBar, FuryMetaSBar)
      else

        -- Texture mode
        BBar:SetHidden(1, BoxMode, true)
        BBar:SetHidden(1, TextureMode, false)
        BBar:SetChangeTexture(FBar, FuryTexture, FuryMetaTexture)
      end
      BBar:DoOption()
      Display = true
    end)
    BBar:SO('Layout', 'ReverseFill', function(v)
      BBar:ChangeTexture(FBar, 'SetFillReverseTexture', 1, v)
      local FN = DemonicData[FuryNotchTexture]
      local FNM = DemonicData[FuryNotchMetaTexture]

      if v then
        BBar:SetPointTexture(1, FuryNotchTexture, FN.Point, FN.ReverseX, FN.OffsetY)
        BBar:SetPointTexture(1, FuryNotchMetaTexture, FNM.Point, FNM.ReverseX, FNM.OffsetY)
      else
        BBar:SetPointTexture(1, FuryNotchTexture, FN.Point, FN.OffsetX, FN.OffsetY)
        BBar:SetPointTexture(1, FuryNotchMetaTexture, FNM.Point, FNM.OffsetX, FNM.OffsetY)
      end
    end)
    BBar:SO('Layout', 'HideText',    function(v)
      if v then
        BBar:SetValueRawFont(1, nil, '')
      else
        self:Update()
      end
    end)
    BBar:SO('Layout', 'SmoothFill',  function(v) BBar:ChangeTexture(FBar, 'SetFillSmoothTimeTexture', 1, v) end)

    BBar:SO('Background', 'BgTexture',     function(v) BBar:SetBackdrop(1, BoxMode, v) end)
    BBar:SO('Background', 'BorderTexture', function(v) BBar:SetBackdropBorder(1, BoxMode, v) end)
    BBar:SO('Background', 'BgTile',        function(v) BBar:SetBackdropTile(1, BoxMode, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v) BBar:SetBackdropTileSize(1, BoxMode, v) end)
    BBar:SO('Background', 'BorderSize',    function(v) BBar:SetBackdropBorderSize(1, BoxMode, v) end)
    BBar:SO('Background', 'Padding',       function(v) BBar:SetBackdropPadding(1, BoxMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v) BBar:SetBackdropColor(1, BoxMode, v.r, v.g, v.b, v.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB)
      if UB.Background.EnableBorderColor then
        BBar:SetBackdropBorderColor(1, BoxMode, v.r, v.g, v.b, v.a)
      else
        BBar:SetBackdropBorderColor(1, BoxMode, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',     function(v) BBar:SetTexture(1, FurySBar, v) end)
    BBar:SO('Bar', 'MetaStatusBarTexture', function(v) BBar:SetTexture(1, FuryMetaSBar, v) end)
    BBar:SO('Bar', 'FillDirection',        function(v) BBar:SetFillDirectionTexture(1, FurySBar, v)
                                                       BBar:SetFillDirectionTexture(1, FuryMetaSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',        function(v) BBar:SetRotateTexture(1, FurySBar, v)
                                                       BBar:SetRotateTexture(1, FuryMetaSBar, v) end)
    BBar:SO('Bar', 'Color',                function(v) BBar:SetColorTexture(1, FurySBar, v.r, v.g, v.b, v.a) end)
    BBar:SO('Bar', 'MetaColor',            function(v) BBar:SetColorTexture(1, FuryMetaSBar, v.r, v.g, v.b, v.a) end)
    BBar:SO('Bar', 'Padding',              function(v) BBar:SetPaddingTexture(1, FurySBar, v.Left, v.Right, v.Top, v.Bottom)
                                                       BBar:SetPaddingTexture(1, FuryMetaSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
    BBar:SO('Bar', '_Size',                function(v) BBar:SetSizeTextureFrame(1, BoxMode, v.Width, v.Height) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the demonic bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.DemonicBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, 1)

  local Names = {Trigger = {}}
  local Trigger = Names.Trigger

  -- Create box mode
  BBar:CreateTextureFrame(1, BoxMode, 0)
    BBar:CreateTexture(1, BoxMode, 'statusbar', 1, FurySBar)
    BBar:CreateTexture(1, BoxMode, 'statusbar', 2, FuryMetaSBar)

  BBar:SetSizeTextureFrame(1, BoxMode, DemonicData.BoxWidth, DemonicData.BoxHeight)
  BBar:SetHiddenTexture(1, FurySBar, false)

  -- Create texture mode
  BBar:CreateTextureFrame(1, TextureMode, 0)
  BBar:SetSizeTextureFrame(1, TextureMode, DemonicData.BoxWidth, DemonicData.BoxHeight)

  for TextureNumber, DD in pairs(DemonicData) do
    if type(TextureNumber) == 'number' then
      BBar:CreateTexture(1, TextureMode, 'texture', DD.Level, TextureNumber)

      BBar:SetTexture(1, TextureNumber, DemonicData.Texture)
      BBar:SetCoordTexture(1, TextureNumber, DD.Left, DD.Right, DD.Top, DD.Bottom)
      BBar:SetSizeTexture(1, TextureNumber, DD.Width, DD.Height)
      BBar:SetPointTexture(1, TextureNumber, DD.Point, DD.OffsetX, DD.OffsetY)
      BBar:SetHiddenTexture(1, TextureNumber, false)
    end
  end
  local Name = UB.Name
  Trigger[1] = Name

  -- Create font for displaying power.
  BBar:CreateFont(1, nil, PercentFn)

  -- Save the name for tooltips for normal mode.
  BBar:SetTooltip(1, nil, Name)

  -- Set up set change
  BBar:SetChangeTexture(FMeta, FuryMetaTexture, FuryBdMetaTexture, FuryNotchMetaTexture, FuryMetaSBar)
  BBar:SetChangeTexture(FNormal, FuryTexture, FuryBdTexture, FuryNotchTexture, FurySBar)

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Demonicbar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.DemonicBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end
