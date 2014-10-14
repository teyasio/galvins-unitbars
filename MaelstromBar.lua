--
-- MaelstromBar.lua
--
-- Displays 5 rectangles for maelstrom charges.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
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
local C_PetBattles, UIParent =
      C_PetBattles, UIParent

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                  Contains the maelstrom bar displayed on screen.
--
-- Display                        Flag used to determin if a Display() call is needed.
-- BoxMode                        Textureframe number used for boxmode.
-- MaelstromSBar                  Texture for maelstrom charges and time.
-- Maelstrom                      Changebox number for all the maelstrom boxframes.
-- MaelstromTime                  The boxnumber for the time statusbar.
--
-- MaelstromAura                  Buff containing the maelstrom charges.
-- MaelstromSpell                 Spell the player knows or doens't know to gain maelstrom.
--
-- TriggerGroups                  Table to create each group for triggers.
-- AnyMaelstromTrigger            Trigger group for any active Maelstrom boxes lit.
-- MaelstromTimeTrigger           Trigger group to modify the Maelstrom time box.
-- DoTriggers                     True by passes visible and isactive flags. If not nil then calls
--                                self:Update(DoTriggers)
-------------------------------------------------------------------------------
local MaxMaelstromCharges = 5
local Display = false
local DoTriggers = false

local BoxMode = 1
local MaelstromCharges = 2
local MaelstromTime = MaxMaelstromCharges + 1

local MaelstromSBar = 10
local MaelstromAura = 53817
local MaelstromSpell = 51530

local MaelstromTimeTrigger = 6
local AnyMaelstromChargeTrigger = 7
local TGBoxNumber = 1
local TGName = 2
local TGValueTypes = 3
local VTs = {'whole:Maelstrom Charges', 'auras:Auras'}
local TriggerGroups = { -- BoxNumber, Name, ValueTypes,
  {1, 'Maelstrom Charge 1',    VTs}, -- 1
  {2, 'Maelstrom Charge 2',    VTs}, -- 2
  {3, 'Maelstrom Charge 3',    VTs}, -- 3
  {4, 'Maelstrom Charge 4',    VTs}, -- 4
  {5, 'Maelstrom Charge 5',    VTs}, -- 5
  {6, 'Maelstrom Time',        VTs}, -- 6
  {0, 'Any Maelstrom Charge',  {'boolean: Active', 'auras:Auras'}},  -- 7
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.MaelstromBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Maelstrom bar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateTestMode
--
-- Display the maelstrom bar in a testmode pattern.
--
-- maelstromBar  The maelstrom bar to show in test mode.
-- Testing       If true shows the test pattern, if false clears it.
-------------------------------------------------------------------------------
local function UpdateTestMode(MaelstromBar, Testing)
  local BBar = MaelstromBar.BBar
  local UB = MaelstromBar.UnitBar

  if Testing then
    local TestMode = UB.TestMode
    local Charges = floor(MaxMaelstromCharges * TestMode.Value)
    local Time = TestMode.Time
    local EnableTriggers = UB.Layout.EnableTriggers

    for MaelstromIndex = 1, MaxMaelstromCharges do
      BBar:SetHiddenTexture(MaelstromIndex, MaelstromSBar, MaelstromIndex > Charges)

      if EnableTriggers then
        BBar:SetTriggers(AnyMaelstromChargeTrigger, 'active', MaelstromIndex <= Charges, nil, MaelstromIndex)
        BBar:SetTriggers(MaelstromIndex, 'maelstrom charges', Charges)
      end
    end
    BBar:SetFillTexture(MaelstromTime, MaelstromSBar, Time, true)
    if not UB.Layout.HideText then
      BBar:SetValueFont(MaelstromTime, nil, 'time', 10 * Time, 'charges', Charges)
    else
      BBar:SetValueRawFont(MaelstromTime, nil, '')
    end

    if EnableTriggers then
      BBar:SetTriggers(MaelstromTimeTrigger, 'maelstrom charges', Charges)
      BBar:DoTriggers()
    end
  else
    BBar:SetHiddenTexture(0, MaelstromSBar, true)
    BBar:SetHiddenTexture(MaelstromTime, MaelstromSBar, false)
    BBar:SetFillTexture(MaelstromTime, MaelstromSBar, 0, true)
    BBar:SetValueRawFont(MaelstromTime, nil, '')
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Event     Event that called this function.  If nil then it wasn't called by an event.
--           True bypasses visible and isactive flags.
-------------------------------------------------------------------------------
function Main.UnitBarsF.MaelstromBar:Update(Event)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  -- Check for testmode.
  local Testing = Main.UnitBars.Testing
  if Testing or self.Testing then
    self.Testing = Testing
    UpdateTestMode(self, Testing)
    if Testing then
      return
    end
  end

  local BBar = self.BBar
  local Maelstrom = IsSpellKnown(MaelstromSpell)
  local EnableTriggers = self.UnitBar.Layout.EnableTriggers
  local MaelstromCharges = 0

  -- Display maelstrom charges
  if Maelstrom then
    local SpellID, Duration, Charges = Main:CheckAura('o', MaelstromAura)
    local DurationChanged = Duration == nil or Duration >= self.OldDuration

    self.OldDuration = Duration or 0
    MaelstromCharges = Charges or 0

    if self.NumCharges ~= MaelstromCharges or MaelstromCharges == MaxMaelstromCharges then
      if DurationChanged then
        BBar:SetFillTimeTexture(MaelstromTime, MaelstromSBar, nil, Duration, 1, 0)
      end
      if not self.UnitBar.Layout.HideText then
        BBar:SetValueTimeFont(MaelstromTime, nil, nil, Duration or 0, Duration, -1, 'charges', MaelstromCharges)
      end
      self.NumCharges = MaelstromCharges
    end
    for MaelstromIndex = 1, MaxMaelstromCharges do
      BBar:SetHiddenTexture(MaelstromIndex, MaelstromSBar, MaelstromIndex > MaelstromCharges)

      if EnableTriggers then
        BBar:SetTriggers(AnyMaelstromChargeTrigger, 'active', MaelstromIndex <= MaelstromCharges, nil, MaelstromIndex)
        BBar:SetTriggers(MaelstromIndex, 'maelstrom charges', MaelstromCharges)
      end
    end
    if EnableTriggers then
      BBar:SetTriggers(MaelstromTimeTrigger, 'maelstrom charges', MaelstromCharges)
      BBar:DoTriggers()
    end
  end

  -- Set the IsActive flag
  self.IsActive = MaelstromCharges > 0

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Maelstrom bar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbale mouse clicks for the maelstrom bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.MaelstromBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the maelstrom bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.MaelstromBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SetOptionData('BackgroundCharges', MaelstromCharges)
    BBar:SetOptionData('BackgroundTime', MaelstromTime)
    BBar:SetOptionData('BarCharges', MaelstromCharges)
    BBar:SetOptionData('BarTime', MaelstromTime)

    BBar:SO('Text', '_Font', function() BBar:UpdateFont(MaelstromTime) end)
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
            BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,      'SetBackdropBorder', BoxNumber, BoxMode)
            BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor, 'SetBackdropBorderColor', BoxNumber, BoxMode)
            BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,  'SetBackdrop', BoxNumber, BoxMode)
            BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,       'SetBackdropColor', BoxNumber, BoxMode)
            BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarTexture,            TT.Type_BarTexture,            'SetTexture', BoxNumber, MaelstromSBar)
            BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_BarColor,              TT.Type_BarColor,              'SetColorTexture', BoxNumber, MaelstromSBar)
            BBar:CreateTypeTriggers(GroupNumber, TT.TypeID_Sound,                 TT.Type_Sound,                 'PlaySound', 1)

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
          end

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
    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',   function(v) BBar:SetFillReverseTexture(0, MaelstromSBar, v) end)
    BBar:SO('Layout', 'HideText',      function(v)
      if v then
        BBar:SetValueTimeFont(MaelstromTime, nil)
      end
    end)
    BBar:SO('Layout', 'Rotation',      function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',         function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',       function(v) BBar:ChangeBox(MaelstromCharges, 'SetPaddingBox', v) Display = true end)
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, MaelstromSBar, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, MaelstromSBar, 'out', v) end)
    BBar:SO('Layout', 'Align',         function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX', function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY', function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',  function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',  function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('General', 'HideCharges', function(v) BBar:ChangeBox(MaelstromCharges, 'SetHidden', nil, v) Display = true end)
    BBar:SO('General', 'HideTime',    function(v) BBar:SetHidden(MaelstromTime, nil, v) Display = true end)
    BBar:SO('General', 'ShowSpark',   function(v) BBar:SetHiddenSpark(0, MaelstromSBar, not v) end)

    BBar:SO('Background', 'BgTexture',     function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdrop', BoxMode, v) end)
    BBar:SO('Background', 'BorderTexture', function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropBorder', BoxMode, v) end)
    BBar:SO('Background', 'BgTile',        function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropTile', BoxMode, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropTileSize', BoxMode, v) end)
    BBar:SO('Background', 'BorderSize',    function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropBorderSize', BoxMode, v) end)
    BBar:SO('Background', 'Padding',       function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetBackdropPadding', BoxMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',             function(v, UB, OD)
      if OD.TableName == 'BackgroundCharges' then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetBackdropColor(MaelstromTime, BoxMode, v.r, v.g, v.b, v.a)
      end
    end)
    BBar:SO('Background', 'BorderColor',   function(v, UB, OD)
      local TableName = OD.TableName
      local EnableBorderColor = UB[TableName].EnableBorderColor

      if TableName == 'BackgroundCharges' then
        if EnableBorderColor then
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
        else
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
        end
      elseif EnableBorderColor then
        BBar:SetBackdropBorderColor(MaelstromTime, BoxMode, v.r, v.g, v.b, v.a)
      else
        BBar:SetBackdropBorderColor(MaelstromTime, BoxMode, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture', function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetTexture', MaelstromSBar, v) end)
    BBar:SO('Bar', 'FillDirection',    function(v)         BBar:SetFillDirectionTexture(MaelstromTime, MaelstromSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',    function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetRotateTexture', MaelstromSBar, v) end)
    BBar:SO('Bar', 'Color',            function(v, UB, OD)
      if OD.TableName == 'BarCharges' then
        BBar:SetColorTexture(OD.Index, MaelstromSBar, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetColorTexture(MaelstromTime, MaelstromSBar, v.r, v.g, v.b, v.a)
      end
    end)
    BBar:SO('Bar', '_Size',            function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetSizeTextureFrame', BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v, UB, OD) BBar:ChangeBox(OD.p1, 'SetPaddingTexture', MaelstromSBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the maelstrom bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.MaelstromBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxMaelstromCharges + 1)

  local Names = {Trigger = {}, Color = {}}
  local Trigger = Names.Trigger
  local Color = Names.Color

  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, MaelstromSBar)

  -- Create maelstrom time text.
  BBar:CreateFont(MaelstromTime)

  BBar:SetChangeBox(MaelstromCharges, 1, 2, 3, 4, 5)
  BBar:SetChangeBox(MaelstromTime, MaelstromTime)
  local Name = nil

  for MaelstromIndex = 1, MaxMaelstromCharges do
    Name = TriggerGroups[MaelstromIndex][TGName]
    Color[MaelstromIndex] = Name
    Trigger[MaelstromIndex] = Name
    BBar:SetTooltip(MaelstromIndex, nil, Name)
  end
  Name = TriggerGroups[MaelstromTimeTrigger][TGName]
  Color[MaelstromTime] = Name
  Trigger[MaelstromTimeTrigger] = Name
  Trigger[AnyMaelstromChargeTrigger] = TriggerGroups[AnyMaelstromChargeTrigger][TGName]

  BBar:SetTooltip(MaelstromTime, nil, Name)

  BBar:ChangeBox(MaelstromCharges, 'SetHidden', BoxMode, false)
  BBar:SetHidden(MaelstromTime, BoxMode, false)
  BBar:SetHiddenTexture(MaelstromTime, MaelstromSBar, false)
  BBar:SetFillTexture(MaelstromTime, MaelstromSBar, 0)

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Maelstrom bar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.MaelstromBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_AURA', self.Update, 'player')
end

