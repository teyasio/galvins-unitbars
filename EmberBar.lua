--
-- EmberBar.lua
--
-- Displays the Warlock Burning Embers bar.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local Options = GUB.Options
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
local C_PetBattles, C_TimerAfter,  UIParent =
      C_PetBattles, C_Timer.After, UIParent

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the ember bar displayed on screen.
--
-- UnitBarF.GreenFire                This key is made inside of Update(). Used with GreenFireAuto or GreenFire
--                                   option setting.  Used by Update() and SetAttr()
--
-- EmberData                         Contains all the data for the ember bar texture.
--   Texture                         Path name to the texture file.
--   TextureGreen                    Same as Texture except its green themed.
--   TextureWidth, TextureHeight     Box size and size of the TextureFrame for texture mode.
--   [TextureType]
--     Point                         Texture point within the TextureFrame.
--     OffsetX, OffsetY              Offset from the point location of where the texture is placed.
--     Width, Height                 Width and Height of the texture.
--     Left, Right, Top, Bottom      Coordinates inside the main texture for the texture we need.
--
-- EmberSBar                         Contains the box for box mode.
-- EmberFierySBar                    Contains the on fire color for box mode.
-- EmberBgTexture                    Background texture for the ember bar.
-- EmberTexture                      Fill texture for showing the ember fill up.
-- EmberFieryTexture                 Fire texture shown after the ember is filled.
-- Fiery                             Change Number for hiding and showing fiery bar/texture.
-- EmberFill                         Change Number to set fill to bar/texture.
--
-- MaxPowerPerEmber                  Amount of power for each ember.
--
-- BarOffsetX, BarOffsetY            Offset the whole bar within the border.
--
-- AnyFullEmberTrigger               Trigger for any ember that is currently on fire.
-- AnyEmberTrigger                   Trigger for any ember that is activly filling.
-- RegionTrigger                     Trigger to make changes to the region.
-- TriggerGroups                     Trigger groups for boxnumber and condition type.
-- DoTriggers                        True by passes visible and isactive flags. If not nil then calls
--                                   self:Update(DoTriggers)
-------------------------------------------------------------------------------
local MaxEmbers = 4
local Display = false
local DoTriggers = false

local MaxPowerPerEmber = MAX_POWER_PER_EMBER
local WarlockGreenFire = WARLOCK_GREEN_FIRE

-- Powertype constants
local PowerEmber = ConvertPowerType['BURNING_EMBERS']

-- Ember Texture constants
local BoxMode = 1
local TextureMode = 2

local Fiery = 3
local EmberFill = 4

local EmberSBar = 10
local EmberFierySBar = 11
local EmberBgTexture = 20
local EmberTexture = 21
local EmberFieryTexture = 22

local BarOffsetX = 0
local BarOffsetY = 0.5

local AnyEmberTrigger = 5
local RegionTrigger = 6
local TGBoxNumber = 1
local TGName = 2
local TGValueTypes = 3
local VTs = {'whole:Full Burning Embers', 'whole:Burning Embers', 'percent:Burning Embers (percent)', 'auras:Auras'}
local TriggerGroups = { -- BoxNumber, Name, ValueTypes,
  {1,  'Burning Ember 1',    VTs}, -- 1
  {2,  'Burning Ember 2',    VTs}, -- 2
  {3,  'Burning Ember 3',    VTs}, -- 3
  {4,  'Burning Ember 4',    VTs}, -- 4
  {0,  'Any Burning Ember',  {'boolean:Active', 'auras:Auras'}},  -- 5
  {-1, 'Region',             VTs}, -- 6
}

local EmberData = {
  Texture = [[Interface\PlayerFrame\Warlock-DestructionUI]],
  TextureGreen = [[Interface\PlayerFrame\Warlock-DestructionUI-Green]],

  -- TextureFrame size.
  TextureWidth = 36, TextureHeight = 39 + 3,
  [EmberBgTexture] = {
    Level = 1,
    Point = 'CENTER',
    OffsetX = BarOffsetX, OffsetY = BarOffsetY,
    Width = 36, Height= 39,
    Left = 0.15234375, Right = 0.29296875, Top = 0.32812500, Bottom = 0.93750000,
  },
  [EmberTexture] = {
    Level = 2,
    Point = 'CENTER',
    OffsetX = BarOffsetX, OffsetY = BarOffsetY - 1.5,
    Width = 20, Height = 22,
    Left = 0.30078125, Right = 0.37890625, Top = 0.32812500, Bottom = 0.67187500,
  },
  [EmberFieryTexture] = {
    Level = 3,
    Point = 'CENTER',
    OffsetX = BarOffsetX, OffsetY = BarOffsetY,
    Width = 36, Height = 39,
    Left = 0.00390625, Right = 0.14453125, Top = 0.32812500, Bottom = 0.93750000,
  }
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.EmberBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Emberbar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the ember bar.
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EmberBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerEmber

  -- Return if not the correct powertype.
  if PowerType ~= PowerEmber then
    return
  end

  local BBar = self.BBar
  local EmberPower = UnitPower('player', PowerEmber, true)
  local MaxEmberPower = UnitPowerMax('player', PowerEmber, true)
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers
  local ShowFiery = nil

  if Main.UnitBars.Testing then
    local TestMode = self.UnitBar.TestMode

    ShowFiery = TestMode.ShowFiery
    EmberPower = floor(MaxPowerPerEmber * MaxEmbers * TestMode.Value)
    if MaxEmberPower == 0 then
      MaxEmberPower = MaxEmbers * MaxPowerPerEmber
    end
  end

  local NumEmbers = floor(MaxEmberPower / MaxPowerPerEmber)
  local Embers = floor(EmberPower / MaxPowerPerEmber)

  -- Set default value if NumEmbers returns zero.
  NumEmbers = NumEmbers > 0 and NumEmbers or MaxEmbers

  -- Check for green fire if auto is set
  local Gen = self.UnitBar.General
  local GreenFire = Gen.GreenFireAuto and IsSpellKnown(WarlockGreenFire) or Gen.GreenFire
  if self.GreenFire ~= GreenFire then
    self.GreenFire = GreenFire
    self:SetAttr()
    Options:RefreshMainOptions()
  end
  local EmberPower2 = EmberPower

  for EmberIndex = 1, NumEmbers do
    local Value = 1

    if EmberPower2 <= MaxPowerPerEmber then

      -- Get ember power as a value between 0 and 1.
      Value = EmberPower2 / MaxPowerPerEmber
      if Value < 0 then
        Value = 0
      end
    end

    BBar:ChangeTexture(EmberFill, 'SetFillTexture', EmberIndex, Value)
    if ShowFiery == nil then
      BBar:ChangeTexture(Fiery, 'SetHiddenTexture', EmberIndex, EmberIndex > Embers)
    else
      BBar:ChangeTexture(Fiery, 'SetHiddenTexture', EmberIndex, not ShowFiery or EmberIndex > Embers)
    end

    if EnableTriggers then
      BBar:SetTriggers(AnyEmberTrigger, 'active', EmberIndex <= Embers, nil, EmberIndex)
      BBar:SetTriggers(AnyEmberTrigger, 'burning embers', Value * MaxPowerPerEmber, nil, EmberIndex)
      BBar:SetTriggers(AnyEmberTrigger, 'burning embers (percent)', Value * MaxPowerPerEmber, MaxPowerPerEmber, EmberIndex)

      BBar:SetTriggers(EmberIndex, 'full burning embers', Embers)
      BBar:SetTriggers(EmberIndex, 'burning embers', Value * MaxPowerPerEmber)
      BBar:SetTriggers(EmberIndex, 'burning embers (percent)', Value * MaxPowerPerEmber, MaxPowerPerEmber)

      -- Base off of the current ember filling.
      if EmberIndex - 1 == Embers then
        BBar:SetTriggers(RegionTrigger, 'burning embers', Value * MaxPowerPerEmber)
        BBar:SetTriggers(RegionTrigger, 'burning embers (percent)', Value * MaxPowerPerEmber, MaxPowerPerEmber)
      end
    end

    -- Left over for next ember.
    EmberPower2 = EmberPower2 - MaxPowerPerEmber
  end

  if EnableTriggers then
    BBar:SetTriggers(RegionTrigger, 'full burning embers', Embers)
    BBar:DoTriggers()
  end

  -- Set the IsActive flag
  self.IsActive = EmberPower ~= MaxPowerPerEmber

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- emberbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the ember bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EmberBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- Enable/disable for border.
  BBar:EnableMouseClicksRegion(Enable)

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the Emberbar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EmberBar:SetAttr(TableName, KeyName)
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
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,                'SetBackdropBorder', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor,           'SetBackdropBorderColor', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,            'SetBackdrop', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,                 'SetBackdropColor', BoxNumber, BoxMode)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarTexture,            TT.Type_BarTexture,                      'SetTexture', BoxNumber, EmberSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarColor,              TT.Type_BarColor,                        'SetColorTexture', BoxNumber, EmberSBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarTexture,            TT.Type_BarTexture .. ' (fiery embers)', 'SetTexture', BoxNumber, EmberFierySBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarColor,              TT.Type_BarColor   .. ' (fiery embers)', 'SetColorTexture', BoxNumber, EmberFierySBar)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_TextureSize,           TT.Type_TextureSize,                     'SetScaleTexture', BoxNumber, EmberBgTexture, EmberTexture, EmberFieryTexture)
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_Sound,                 TT.Type_Sound,                           'PlaySound', BoxNumber)

              -- Class Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor,         TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,               TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor,                      TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (fiery embers)', TT.TypeID_ClassColorMenu,  TT.TypeID_ClassColor,  TT.Type_ClassColor,  Main.GetClassColor)

              -- Power Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor,         TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,               TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor,                      TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (fiery embers)', TT.TypeID_PowerColorMenu,  TT.TypeID_PowerColor,  TT.Type_PowerColor,  Main.GetPowerColor)

              -- Combat Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor,         TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,               TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor,                      TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (fiery embers)', TT.TypeID_CombatColorMenu, TT.TypeID_CombatColor, TT.Type_CombatColor, Main.GetCombatColor)

              -- Tagged Color
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundBorderColor,         TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BackgroundColor,               TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor,                      TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
              BBar:CreateGetFunctionTriggers(GroupNumber, TT.Type_BarColor .. ' (fiery embers)', TT.TypeID_TaggedColorMenu, TT.TypeID_TaggedColor, TT.Type_TaggedColor, Main.GetTaggedColor)
            else
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBorder,          TT.Type_RegionBorder,                    'SetBackdropBorderRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBorderColor,     TT.Type_RegionBorderColor,               'SetBackdropBorderColorRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBackground,      TT.Type_RegionBackground,                'SetBackdropRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_RegionBackgroundColor, TT.Type_RegionBackgroundColor,           'SetBackdropColorRegion')
              BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_Sound,                 TT.Type_Sound,                           'PlaySound', 1)

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
          BBar:SetScaleTexture(0, EmberBgTexture, 1)
          BBar:SetScaleTexture(0, EmberTexture, 1)
          BBar:SetScaleTexture(0, EmberFieryTexture, 1)

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
        BBar:SetChangeTexture(EmberFill, EmberSBar)
      else
        -- texture mode
        BBar:ShowRowTextureFrame(TextureMode)
        BBar:SetChangeTexture(EmberFill, EmberTexture)
      end
      BBar:DoOption()
      Display = true
    end)
    BBar:SO('Layout', 'HideRegion',    function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',   function(v) BBar:ChangeTexture(EmberFill, 'SetFillReverseTexture', 0, v) end)
    BBar:SO('Layout', 'BorderPadding', function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',      function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',         function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',       function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'SmoothFill',    function(v) BBar:ChangeTexture(EmberFill, 'SetFillSmoothTimeTexture', 0, v) end)
    BBar:SO('Layout', 'TextureScale',  function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, EmberFierySBar, 'in', v)
                                                   BBar:SetFadeTimeTexture(0, EmberFieryTexture, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, EmberFierySBar, 'out', v)
                                                   BBar:SetFadeTimeTexture(0, EmberFieryTexture, 'out', v) end)
    BBar:SO('Layout', 'Align',         function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX', function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY', function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',  function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',  function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('General', 'GreenFire',     function(v) self:Update() end)
    BBar:SO('General', 'GreenFireAuto', function(v)
      self:Update()
      local GreenFire = self.GreenFire

      for EmberIndex = 1, MaxEmbers do
        for TextureNumber, ED in pairs(EmberData) do
          if type(TextureNumber) == 'number' then
            BBar:SetTexture(EmberIndex, TextureNumber, GreenFire and EmberData.TextureGreen or EmberData.Texture)
          end
        end
      end
    end)

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
    BBar:SO('Background', 'Color',         function(v, UB, OD)
      if not self.GreenFire then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Background', 'ColorGreen', function(v, UB, OD)
      if self.GreenFire then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      end
    end)

    BBar:SO('Background', 'BorderColor', function(v, UB, OD)
      if not self.GreenFire then
        if UB.Background.EnableBorderColor then
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
        else
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
        end
      end
    end)
    BBar:SO('Background', 'BorderColorGreen', function(v, UB, OD)
      if self.GreenFire then
        if UB.Background.EnableBorderColor then
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
        else
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
        end
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',      function(v) BBar:SetTexture(0, EmberSBar, v) end)
    BBar:SO('Bar', 'FieryStatusBarTexture', function(v) BBar:SetTexture(0, EmberFierySBar, v) end)
    BBar:SO('Bar', 'FillDirection',         function(v) BBar:SetFillDirectionTexture(0, EmberSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',         function(v) BBar:SetRotateTexture(0, EmberSBar, v)
                                                        BBar:SetRotateTexture(0, EmberFierySBar, v) end)
    BBar:SO('Bar', 'Color',                 function(v, UB, OD)
      if not self.GreenFire then
        BBar:SetColorTexture(OD.Index, EmberSBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorFiery',            function(v, UB, OD)
      if not self.GreenFire then
        BBar:SetColorTexture(OD.Index, EmberFierySBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorGreen',            function(v, UB, OD)
      if self.GreenFire then
        BBar:SetColorTexture(OD.Index, EmberSBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorFieryGreen',       function(v, UB, OD)
      if self.GreenFire then
        BBar:SetColorTexture(OD.Index, EmberFierySBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', '_Size',                 function(v, UB) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',               function(v) BBar:SetPaddingTexture(0, EmberSBar, v.Left, v.Right, v.Top, v.Bottom)
                                                        BBar:SetPaddingTexture(0, EmberFierySBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the ember bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.EmberBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxEmbers)

  local Names = {Trigger = {}, Color = {}}
  local Trigger = Names.Trigger
  local Color = Names.Color

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, EmberSBar)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 2, EmberFierySBar)

  -- Create texture mode.
  for EmberIndex = 1, MaxEmbers do
    BBar:CreateTextureFrame(EmberIndex, TextureMode, 0)

    for TextureNumber, ED in pairs(EmberData) do
      if type(TextureNumber) == 'number' then
        BBar:CreateTexture(EmberIndex, TextureMode, 'texture', ED.Level, TextureNumber)

        BBar:SetTexture(EmberIndex, TextureNumber, EmberData.Texture)
        BBar:SetCoordTexture(EmberIndex, TextureNumber, ED.Left, ED.Right, ED.Top, ED.Bottom)
        BBar:SetSizeTexture(EmberIndex, TextureNumber, ED.Width, ED.Height)
        BBar:SetPointTexture(EmberIndex, TextureNumber, ED.Point, ED.OffsetX, ED.OffsetY)
      end
    end

    -- Set default fill.
    BBar:SetFillDirectionTexture(EmberIndex, EmberSBar, 'VERTICAL')
    BBar:SetFillDirectionTexture(EmberIndex, EmberTexture, 'VERTICAL')

    local Name = TriggerGroups[EmberIndex][TGName]

    BBar:SetTooltip(EmberIndex, nil, Name)
    Color[EmberIndex] = Name
    Trigger[EmberIndex] = Name
  end

  Trigger[AnyEmberTrigger] = TriggerGroups[AnyEmberTrigger][TGName]
  Trigger[RegionTrigger] = TriggerGroups[RegionTrigger][TGName]

  -- Show the ember background and fill
  BBar:SetHiddenTexture(0, EmberSBar, false)
  BBar:SetHiddenTexture(0, EmberBgTexture, false)
  BBar:SetHiddenTexture(0, EmberTexture, false)

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, EmberData.TextureWidth, EmberData.TextureHeight)

  BBar:SetChangeTexture(Fiery, EmberFieryTexture, EmberFierySBar)

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Emberbar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.EmberBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end


