--
-- StaggerBar.lua
--
-- Displays the staggar bar for brewmaster monks
-- Some parts of this bar is based on ideas from Redfellas weakauras

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local TT = GUB.DefaultUB.TriggerTypes
local DUB = GUB.DefaultUB.Default.profile

local UnitBarsF = Main.UnitBarsF
local LSM = Main.LSM

-- localize some globals.
local _, _G =
      _, _G
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt,      mhuge =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt, math.huge
local strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring =
      strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring
local pcall, pairs, ipairs, type, select, next, print, assert, unpack, sort, wipe, tremove, tinsert =
      pcall, pairs, ipairs, type, select, next, print, assert, unpack, sort, wipe, tremove, tinsert
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, PetHasActionBar, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, PetHasActionBar, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapDenied, UnitStagger =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapDenied, UnitStagger
local UnitName, UnitReaction, UnitLevel, UnitEffectiveLevel, UnitGetIncomingHeals, UnitCanAttack, UnitPlayerControlled, UnitIsPVP =
      UnitName, UnitReaction, UnitLevel, UnitEffectiveLevel, UnitGetIncomingHeals, UnitCanAttack, UnitPlayerControlled, UnitIsPVP
local GetRuneCooldown, GetSpellInfo, GetSpellBookItemInfo, PlaySound, message, UnitCastingInfo, GetSpellPowerCost =
      GetRuneCooldown, GetSpellInfo, GetSpellBookItemInfo, PlaySound, message, UnitCastingInfo, GetSpellPowerCost
local GetShapeshiftFormID, GetSpecialization, GetInventoryItemID, GetRealmName =
      GetShapeshiftFormID, GetSpecialization, GetInventoryItemID, GetRealmName
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, C_TimerAfter, UIParent =
      C_PetBattles, C_Timer.After, UIParent

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.StaggerValue    Contains the current Stagger used by DoStaggerPauseTime()
-- UnitBarF.MaxValue        Max health used by DoStaggerPauseTime()
-- UnitBarF.PauseTime       Set by DoStaggerPauseTime()
-------------------------------------------------------------------------------
local Display = false
local Update = false

local BlackoutComboAura = 228563
local IronskinBrewSpellID = 115308
local StaggerPauseTime = 3 -- in seconds

-- Stagger texture constants
local StaggerBarBox = 1
local StaggerPauseBox = 2
local StaggerBarTFrame = 1
local StaggerPauseTFrame = 1

local StaggerSBar = 10
local BStaggerSBar = 11
local StaggerPauseSBar = 20

local ChangeStagger = 30

local GF = { -- Get function data
  TT.TypeID_ClassColor,  TT.Type_ClassColor,
  TT.TypeID_PowerColor,  TT.Type_PowerColor,
  TT.TypeID_CombatColor, TT.Type_CombatColor,
  TT.TypeID_TaggedColor, TT.Type_TaggedColor,
}

local TDStagger = { -- Trigger data stagger
  { TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,             StaggerBarTFrame },
  { TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor,        StaggerBarTFrame,
    GF = GF },
  { TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,         StaggerBarTFrame },
  { TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,              StaggerBarTFrame,
    GF = GF },
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,                   StaggerSBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,                     StaggerSBar,
    GF = GF },
  { TT.TypeID_BarTexture,            TT.Type_BarTexture .. ' (continued)', BStaggerSBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor .. ' (continued)',   BStaggerSBar,
    GF = GF },
  { TT.TypeID_BarOffset,             TT.Type_BarOffset,                    StaggerBarTFrame },
  { TT.TypeID_TextFontColor,         TT.Type_TextFontColor,
    GF = GF },
  { TT.TypeID_TextFontOffset,        TT.Type_TextFontOffset },
  { TT.TypeID_TextFontSize,          TT.Type_TextFontSize },
  { TT.TypeID_TextFontType,          TT.Type_TextFontType },
  { TT.TypeID_TextFontStyle,         TT.Type_TextFontStyle },
  { TT.TypeID_Sound,                 TT.Type_Sound }
}

local TDPause = { -- Trigger data pause timer
  { TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,             StaggerPauseTFrame },
  { TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor,        StaggerPauseTFrame,
    GF = GF },
  { TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,         StaggerPauseTFrame },
  { TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,              StaggerPauseTFrame,
    GF = GF },
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,                   StaggerPauseSBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,                     StaggerPauseSBar,
    GF = GF },
  { TT.TypeID_BarOffset,             TT.Type_BarOffset,                    StaggerPauseTFrame },
  { TT.TypeID_TextFontColor,         TT.Type_TextFontColor,
    GF = GF },
  { TT.TypeID_TextFontOffset,        TT.Type_TextFontOffset },
  { TT.TypeID_TextFontSize,          TT.Type_TextFontSize },
  { TT.TypeID_TextFontType,          TT.Type_TextFontType },
  { TT.TypeID_TextFontStyle,         TT.Type_TextFontStyle },
  { TT.TypeID_Sound,                 TT.Type_Sound }
}

local VTStagger = {'whole',   'Stagger',
                   'percent', 'Stagger (percent)',
                   'float',   'Time',
                   'auras',   'Auras'             }
local VTPause = {'whole',   'Stagger',
                 'percent', 'Stagger (percent)',
                 'float',   'Time',
                 'auras',   'Auras'             }

local StaggerGroups = { -- BoxNumber, Name, ValueTypes,
  {1, '', VTStagger, TDStagger}, -- 1
  {2, '', VTPause, TDPause},     -- 2
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.StaggerBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Stagger bar - stagger pause
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- DoStaggerPauseTime
--
-- Gets called during stagger pause time
--
-- BBar           Current bar being used.
-- BoxNumber      Current box the call back happened on
-- Time           Current time
-- Done           If true then the timer is finished
-------------------------------------------------------------------------------
local function DoStaggerPauseTime(UnitBarF, BBar, BoxNumber, Time, Done)
  local Layout = UnitBarF.UnitBar.Layout

  if not Done then
    -- Display on the pause bar if text not hidden
    if Layout.PauseTimer and not Layout.HideTextPause then
      BBar:SetValueFont(StaggerPauseBox, 'time', Time)
    end

    -- Display on the stagger bar if text not hidden
    if not Layout.HideText then
      UnitBarF.PauseTime = Time
      BBar:SetValueFont(StaggerBarBox, 'current', UnitBarF.StaggerValue or 0, 'maximum', UnitBarF.MaxValue or 0, 'time', Time)
    end

    if Layout.EnableTriggers then
      BBar:SetTriggers(StaggerPauseBox, 'time', Time)
      BBar:SetTriggers(StaggerBarBox, 'time', Time)
      BBar:DoTriggers()
    end
  else
    BBar:SetValueRawFont(StaggerPauseBox, '')

    if Layout.PauseTimer and Layout.PauseTimerAutoHide then
      BBar:SetHidden(StaggerPauseBox, nil, true)
      BBar:Display()
    end
  end
end

-------------------------------------------------------------------------------
-- Casting
--
-- Gets called when a spell is being cast.
--
-- UnitBarF     Bar thats tracking casts
-- SpellID      Spell that is being cast
-- Message      See Main.lua for list of messages
-------------------------------------------------------------------------------
local function Casting(UnitBarF, SpellID, Message)
  if SpellID == IronskinBrewSpellID and Message == 'done' then
    if Main:CheckAura('a', BlackoutComboAura) then
      local BBar = UnitBarF.BBar
      local Layout = UnitBarF.UnitBar.Layout

      if not Main.UnitBars.Testing then
        local StartTime = GetTime()

        if Layout.PauseTimer then
          BBar:SetHidden(StaggerPauseBox, nil, false)
          BBar:Display()

          BBar:SetFillTimeTexture(StaggerPauseBox, StaggerPauseSBar, StartTime, StaggerPauseTime, 1, 0)
        end
        BBar:SetValueTime(StaggerPauseBox, StartTime, StaggerPauseTime, -1, DoStaggerPauseTime)
      end
    end
  end
end

--*****************************************************************************
--
-- Stagger bar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- HideStagger
--
-- Gets called each time the bar changes value only during layered mode
--
-- BBar           Current bar being used.
-- BoxNumber      Box that contains the texture
-- TextureNumber  Texture that gets hidden or shown
-- Value          Current value of the fill
-------------------------------------------------------------------------------
local function HideStagger(UnitBarF, BBar, BoxNumber, TextureNumber, Value)
  BBar:SetHiddenTexture(BoxNumber, TextureNumber, Value > UnitBarF.UnitBar.BarStagger.MaxPercent)
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Updates the stagger bar based on amount of health staggered
--
-- Event        If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
-------------------------------------------------------------------------------
function Main.UnitBarsF.StaggerBar:Update(Event)

  -- Check if bar is not visible or has active flag waiting for activity.
  if Event ~= true and not self.Visible and self.IsActive ~= 0 then
    return
  end

  local BBar = self.BBar
  local UB = self.UnitBar
  local PauseTime = self.PauseTime
  local Layout = UB.Layout
  local Testing = Main.UnitBars.Testing

  local Stagger = UnitStagger('player')
  local MaxValue = UnitHealthMax('player')

  if Testing then
    local TestMode = UB.TestMode
    local StaggerPause = TestMode.StaggerPause

    self.Testing = true

    PauseTime = StaggerPause
    Stagger = TestMode.StaggerPercent * MaxValue

    BBar:SetFillTexture(StaggerPauseBox, StaggerPauseSBar, StaggerPause / StaggerPauseTime)

    if not Layout.HideTextPause then
      BBar:SetValueFont(StaggerPauseBox, 'time', StaggerPause)
    end

  -- Just switched out of test mode do a clean up.
  elseif self.Testing then
    self.Testing = false

    BBar:SetFillTexture(StaggerPauseBox, StaggerPauseSBar, 0)
    BBar:SetValueRawFont(StaggerPauseBox, '')
  end

  local Value = 0
  if MaxValue > 0 then
    Value = Stagger / MaxValue
  end

  BBar:SetFillTexture(StaggerBarBox, StaggerSBar, Value)
  if Layout.Layered or Layout.SideBySide then
    BBar:SetFillTexture(StaggerBarBox, BStaggerSBar, Value)
  end

  if not Layout.HideText then
    BBar:SetValueFont(StaggerBarBox, 'current', Stagger, 'maximum', MaxValue, 'time', PauseTime)
    self.StaggerValue = Stagger
    self.MaxValue = MaxValue
  end

  -- Check triggers
  if UB.Layout.EnableTriggers then
    if Testing and Layout.PauseTimer then
      BBar:SetTriggers(StaggerPauseBox, 'time', PauseTime)
    end

    BBar:SetTriggers(StaggerBarBox, 'stagger', Stagger)
    BBar:SetTriggers(StaggerBarBox, 'stagger (percent)', Stagger, MaxValue)
    BBar:SetTriggers(StaggerBarBox, 'time', PauseTime)
    BBar:SetTriggers(StaggerPauseBox, 'stagger', Stagger)
    BBar:SetTriggers(StaggerPauseBox, 'stagger (percent)', Stagger, MaxValue)
    BBar:DoTriggers()
  end

  -- Set the IsActive flag.
  self.IsActive = Value > 0

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- Stagger bar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetLayout
--
-- Sets the bar layout based on settings
--
-- BBar      BBar Stagger Bar
-- UB        Unitbar Data containing layout
-------------------------------------------------------------------------------
local function SetLayout(BBar, UB)
  local Layout = UB.Layout
  local Layered = Layout.Layered
  local SideBySide = Layout.SideBySide
  local BarStagger = UB.BarStagger

  -- Remove fill clip from both textures
  BBar:SetFillClipRemoveTexture(StaggerBarBox, StaggerSBar)
  BBar:SetFillClipRemoveTexture(StaggerBarBox, BStaggerSBar)

  -- Show both textures
  BBar:SetHiddenTexture(StaggerBarBox, BStaggerSBar, false)
  BBar:SetHiddenTexture(StaggerBarBox, StaggerSBar, false)

  -- Remove call back
  BBar:SetFillFnTexture(StaggerBarBox, StaggerSBar, nil)

  BBar:SetFillMaxValueTextureFrame(StaggerBarBox, StaggerBarTFrame, BarStagger.MaxPercentBStagger)

  if Layered then
    BBar:SetFillMinMaxValuesTexture(StaggerBarBox, StaggerSBar, 0, BarStagger.MaxPercent)
    BBar:SetFillMinMaxValuesTexture(StaggerBarBox, BStaggerSBar, BarStagger.MaxPercent, BarStagger.MaxPercentBStagger)

    if not Layout.Overlay then
      -- Set call back to hide stagger
      BBar:SetFillFnTexture(StaggerBarBox, StaggerSBar, HideStagger)
    end

  elseif SideBySide then
    BBar:SetFillClipFlagsTexture(StaggerBarBox, StaggerSBar, 'reverse', 'enable')
    BBar:SetFillClipFlagsTexture(StaggerBarBox, BStaggerSBar, 'reverse', 'enable')

    BBar:SetFillClipTexture(StaggerBarBox, StaggerSBar, 'start')
    BBar:SetFillClipTexture(StaggerBarBox, StaggerSBar, 'end', BarStagger.MaxPercent)
    BBar:SetFillClipTexture(StaggerBarBox, BStaggerSBar, 'start', BarStagger.MaxPercent)
    BBar:SetFillClipTexture(StaggerBarBox, BStaggerSBar, 'end')

  else -- not Layered and SideBySide
    BBar:SetHiddenTexture(StaggerBarBox, BStaggerSBar, true)
    BBar:SetFillMaxValueTextureFrame(StaggerBarBox, StaggerBarTFrame, BarStagger.MaxPercent)
  end
  Update = true
end

------------------------------------------------------------------------------
-- EnableMouseClicks
--
-- This will enable or disable mouse clicks for the rune icons.
-------------------------------------------------------------------------------
function Main.UnitBarsF.StaggerBar:EnableMouseClicks(Enable)
  self.BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr
--
-- Sets different parts of the stagger bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.StaggerBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then          -- OD.p1            OD.p2              OD.p3
    BBar:SetOptionData('BackgroundStagger', StaggerBarBox,   StaggerBarTFrame)
    BBar:SetOptionData('BackgroundPause',   StaggerPauseBox, StaggerPauseTFrame)
    BBar:SetOptionData('BarStagger',        StaggerBarBox,   StaggerBarTFrame,   StaggerSBar )
    BBar:SetOptionData('BarPause',          StaggerPauseBox, StaggerPauseTFrame, StaggerPauseSBar )

    BBar:SO('Text', '_Font', function()
      BBar:UpdateFont(StaggerBarBox)
      BBar:UpdateFont(StaggerPauseBox)

      Update = true
    end)

    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers',     function(v) BBar:EnableTriggers(v, StaggerGroups) end)
    BBar:SO('Layout', 'Swap',               function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',              function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',        function(v) BBar:ChangeTexture(ChangeStagger, 'SetFillReverseTexture', StaggerBarBox, v) Update = true end)
    BBar:SO('Layout', 'HideText',           function(v)
      if v then
        BBar:SetValueRawFont(StaggerBarBox, '')
      else
        Update = true
      end
    end)
    BBar:SO('Layout', 'HideTextPause',           function(v)
      if v then
        BBar:SetValueRawFont(StaggerPauseBox, '')
      else
        Update = true
      end
    end)

    BBar:SO('Layout', 'Rotation',           function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',            function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'Align',              function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX',      function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY',      function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',       function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',       function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('Layout', 'SmoothFillMaxTime',  function(v) BBar:ChangeTexture(ChangeStagger, 'SetSmoothFillMaxTime', StaggerBarBox, v) end)
    BBar:SO('Layout', 'SmoothFillSpeed',    function(v) BBar:ChangeTexture(ChangeStagger, 'SetFillSpeedTexture', StaggerBarBox, v) end)

    -- More layout
    BBar:SO('Layout', 'Layered',            function(v, UB) SetLayout(BBar, UB) end)
    BBar:SO('Layout', 'Overlay',            function(v, UB) SetLayout(BBar, UB) end)
    BBar:SO('Layout', 'SideBySide',         function(v, UB) SetLayout(BBar, UB) end)
    BBar:SO('Layout', 'PauseTimer',         function(v, UB) BBar:SetHidden(StaggerPauseBox, nil, UB.Layout.PauseTimerAutoHide or not v) Display = true end)
    BBar:SO('Layout', 'PauseTimerAutoHide', function(v)     BBar:DoOption('Layout', 'PauseTimer') end)
    BBar:SO('Layout', '_PauseCastTracker',  function(v)
      -- Need to do this here incase of profile change.
      Main:SetCastTracker(self, 'fn', Casting)
    end)

    BBar:SO('Background', 'BgTexture',     function(v, UB, OD) BBar:SetBackdrop(OD.p1, OD.p2, v) end)
    BBar:SO('Background', 'BorderTexture', function(v, UB, OD) BBar:SetBackdropBorder(OD.p1, OD.p2, v) end)
    BBar:SO('Background', 'BgTile',        function(v, UB, OD) BBar:SetBackdropTile(OD.p1, OD.p2, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v, UB, OD) BBar:SetBackdropTileSize(OD.p1, OD.p2, v) end)
    BBar:SO('Background', 'BorderSize',    function(v, UB, OD) BBar:SetBackdropBorderSize(OD.p1, OD.p2, v) end)
    BBar:SO('Background', 'Padding',       function(v, UB, OD) BBar:SetBackdropPadding(OD.p1, OD.p2, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v, UB, OD) BBar:SetBackdropColor(OD.p1, OD.p2, v.r, v.g, v.b, v.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB, OD)
      if UB[OD.TableName].EnableBorderColor then
        BBar:SetBackdropBorderColor(OD.p1, OD.p2, v.r, v.g, v.b, v.a)
      else
        BBar:SetBackdropBorderColor(OD.p1, OD.p2, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',    function(v, UB, OD) BBar:SetTexture(OD.p1, OD.p3, v) end)
    BBar:SO('Bar', 'BStaggerBarTexture',  function(v, UB)     BBar:SetTexture(StaggerBarBox, BStaggerSBar, v) end)
    BBar:SO('Bar', 'FillDirection',       function(v, UB, OD)
      if OD.p1 == StaggerBarBox then
        BBar:ChangeTexture(ChangeStagger, 'SetFillDirectionTexture', StaggerBarBox, v)
      else
        BBar:SetFillDirectionTexture(StaggerPauseBox, StaggerPauseSBar, v)
      end
      Update = true
    end)
    BBar:SO('Bar', 'RotateTexture',       function(v, UB, OD)
      if OD.p1 == StaggerBarBox then
        BBar:ChangeTexture(ChangeStagger, 'SetRotateTexture', StaggerBarBox, v)
      else
        BBar:SetRotateTexture(StaggerPauseBox, StaggerPauseSBar, v)
      end
    end)
    BBar:SO('Bar', 'Color',               function(v, UB, OD) BBar:SetColorTexture(OD.p1, OD.p3, v.r, v.g, v.b, v.a) end)
    BBar:SO('Bar', 'BStaggerColor',       function(v, UB)     BBar:SetColorTexture(StaggerBarBox, BStaggerSBar, v.r, v.g, v.b, v.a) end)
    BBar:SO('Bar', 'MaxPercent',          function(v, UB)     SetLayout(BBar, UB) end)
    BBar:SO('Bar', 'MaxPercentBStagger',  function(v, UB)     SetLayout(BBar, UB) end)
    BBar:SO('Bar', '_Size',               function(v, UB, OD) BBar:SetSizeTextureFrame(OD.p1, OD.p2, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',             function(v, UB, OD) BBar:SetPaddingTextureFrame(OD.p1, OD.p2, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the stagger bar.
-- UB           Unitbar data.
-- Anchor       Unitbar's anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.StaggerBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, 2)

  -- Create the stagger bar
  BBar:CreateTextureFrame(StaggerBarBox, StaggerBarTFrame, 0)
    BBar:CreateTexture(StaggerBarBox, StaggerBarTFrame, 'statusbar', 1, StaggerSBar)
    BBar:CreateTexture(StaggerBarBox, StaggerBarTFrame, 'statusbar', 2, BStaggerSBar)

  -- Create the stagger pause bar
  BBar:CreateTextureFrame(StaggerPauseBox, StaggerPauseTFrame, 3)
    BBar:CreateTexture(StaggerPauseBox, StaggerPauseTFrame, 'statusbar', 4, StaggerPauseSBar)

  -- Create font for both boxes.
  BBar:CreateFont('Text', StaggerBarBox)
  BBar:CreateFont('Text2', StaggerPauseBox)

  -- Enable tooltip
  BBar:SetTooltip(StaggerBarBox, nil, UB.Name)
  BBar:SetTooltip(StaggerPauseBox, nil, 'Pause Timer')

  BBar:SetChangeTexture(ChangeStagger, StaggerSBar, BStaggerSBar)

  -- Show the bars.
  BBar:SetHidden(StaggerBarBox, StaggerBarTFrame, false)
  BBar:SetHidden(StaggerPauseBox, StaggerPauseTFrame, false)
  BBar:SetHiddenTexture(StaggerBarBox, StaggerSBar, false)
  BBar:SetHiddenTexture(StaggerBarBox, BStaggerSBar, false)
  BBar:SetHiddenTexture(StaggerPauseBox, StaggerPauseSBar, false)
  BBar:ChangeTexture(ChangeStagger, 'SetFillTexture', StaggerBarBox, 0)
  BBar:SetFillTexture(StaggerPauseBox, StaggerPauseSBar, 0)
  BBar:SetSizeTextureFrame(StaggerBarBox, StaggerBarTFrame, UB.BarStagger.Width, UB.BarStagger.Height)
  BBar:SetSizeTextureFrame(StaggerPauseBox, StaggerPauseTFrame, UB.BarPause.Width, UB.BarPause.Height)

  -- Set this for trigger bar offsets
  BBar:SetOffsetTextureFrame(StaggerBarBox, StaggerBarTFrame, 0, 0, 0, 0)
  BBar:SetOffsetTextureFrame(StaggerPauseBox, StaggerPauseTFrame, 0, 0, 0, 0)

  -- Make it so the pause box doesn't cause the stagger bar to shift around.
  BBar:SetIgnoreBorderBox(StaggerPauseBox, true)

  UnitBarF.PauseTime = 0 -- to have a timer on the stagger bar
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Stagger bar Enable/Disable functions
--
--*****************************************************************************
local function StaggerUpdate(StaggerBar)
  StaggerBar:Update()
end

function Main.UnitBarsF.StaggerBar:Enable(Enable)
  if Enable then
    Main:SetTimer(self, StaggerUpdate, 0.05)
  else
    Main:SetTimer(self, nil)
  end
end
