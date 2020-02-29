--
-- RuneBar.lua
--
-- Displays a runebar similiar to blizzards runebar.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local TT = GUB.DefaultUB.TriggerTypes

-- localize some globals.
local _, _G =
      _, _G
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt,      mhuge =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt, math.huge
local strfind, strmatch, strsplit, strsub, strtrim, strupper, strlower, format, gsub, gmatch =
      strfind, strmatch, strsplit, strsub, strtrim, strupper, strlower, format, gsub, gmatch
local GetTime, ipairs, pairs, next, pcall, print, select, tonumber, tostring, tremove, tinsert, type, unpack, sort =
      GetTime, ipairs, pairs, next, pcall, print, select, tonumber, tostring, tremove, tinsert, type, unpack, sort

local GetRuneCooldown, CreateFrame =
      GetRuneCooldown, CreateFrame

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the holy bar displayed on screen
-- UnitBarF.LastDuration             Keeps track of each runes last duration
-- UnitBarF.RuneOnCooldown           Keeps track of which rune is recharging
-- UnitBarF.OnUpdateFrame            Used to batch up events that happen on the same
--                                   frame.  So if 6 events come in on the same frame
--                                   only one call will be made instead of 6
-------------------------------------------------------------------------------
local MaxRunes = 6
local Display = false
local Update = false
local SortedRunes = {1, 2, 3, 4, 5, 6}
local RuneCooldownRuneBar = nil
local OneHour = 3600

local BarMode = 1
local RuneMode = 2

local AllTextures = 20

local RuneSBar = 10
local RuneTexture = 20
local RuneEmptyTexture = 21

local RegionGroup = 8

local GF = { -- Get function data
  TT.TypeID_ClassColor,  TT.Type_ClassColor,
  TT.TypeID_PowerColor,  TT.Type_PowerColor,
  TT.TypeID_CombatColor, TT.Type_CombatColor,
  TT.TypeID_TaggedColor, TT.Type_TaggedColor,
}

local TD = { -- Trigger data
  { TT.TypeID_BackgroundBorder,      TT.Type_BackgroundBorder,      BarMode },
  { TT.TypeID_BackgroundBorderColor, TT.Type_BackgroundBorderColor, BarMode,
    GF = GF },
  { TT.TypeID_BackgroundBackground,  TT.Type_BackgroundBackground,  BarMode },
  { TT.TypeID_BackgroundColor,       TT.Type_BackgroundColor,       BarMode,
    GF = GF },
  { TT.TypeID_BarTexture,            TT.Type_BarTexture,            RuneSBar },
  { TT.TypeID_BarColor,              TT.Type_BarColor,              RuneSBar,
    GF = GF },
  { TT.TypeID_BarOffset,             TT.Type_BarOffset,             BarMode },
  { TT.TypeID_TextureScale,          TT.Type_TextureScale,          AllTextures },
  { TT.TypeID_TextFontColor,         TT.Type_TextFontColor,
    GF = GF },
  { TT.TypeID_TextFontOffset,        TT.Type_TextFontOffset },
  { TT.TypeID_TextFontSize,          TT.Type_TextFontSize },
  { TT.TypeID_TextFontType,          TT.Type_TextFontType },
  { TT.TypeID_TextFontStyle,         TT.Type_TextFontStyle },
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

local VTs = {'state', 'Recharging',
             'float', 'Time',
             'auras', 'Auras'      }
local VTsNoTime = {'state', 'Recharging',
                  'auras', 'Auras'      }

local Groups = { -- BoxNumber, Name, ValueTypes,
  {1,   'Rune 1',    VTs, TD},  -- 1
  {2,   'Rune 2',    VTs, TD},  -- 2
  {3,   'Rune 3',    VTs, TD},  -- 3
  {4,   'Rune 4',    VTs, TD},  -- 4
  {5,   'Rune 5',    VTs, TD},  -- 5
  {6,   'Rune 6',    VTs, TD},  -- 6
  {'a', 'All',       VTs, TD},  -- 7
  {'r', 'Region',    VTsNoTime, TDregion},  -- 8
}

local RuneCooldownFillTexture = {
  [[Interface\PlayerFrame\DK-Blood-Rune-CDFill]],   -- 1
  [[Interface\PlayerFrame\DK-Frost-Rune-CDFill]],   -- 2
  [[Interface\PlayerFrame\DK-Unholy-Rune-CDFill]],  -- 3
}

local RuneCooldownSparkTexture = {
  [[Interface\PlayerFrame\DK-BloodUnholy-Rune-CDSpark]],  -- 1
  [[Interface\PlayerFrame\DK-Frost-Rune-CDSpark]],        -- 2
  [[Interface\PlayerFrame\DK-BloodUnholy-Rune-CDSpark]],  -- 3
}

local RuneReadyTexture = {
  'DK-Blood-Rune-Ready',  -- 1
  'DK-Frost-Rune-Ready',  -- 2
  'DK-Unholy-Rune-Ready', -- 3
}

local RuneDataWidth = 24
local RuneDataHeight = 24  -- Width and height used for texture mode
local RuneDataAtlasEmptyRune = 'DK-Rune-CD'

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.RuneBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- RuneBar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- GetRuneCooldown2
--
-- Roots cooldown so things like testmode are possible
-------------------------------------------------------------------------------
local function GetRuneCooldown2(RuneID)
  local StartTime = 0
  local Duration = 0
  local RuneReady = true

  if not Main.UnitBars.Testing then
    if Main.PlayerClass == 'DEATHKNIGHT' then
      StartTime, Duration, RuneReady = GetRuneCooldown(RuneID)
    end
  else
    local UB = RuneCooldownRuneBar.UnitBar
    local TestMode = UB.TestMode
    local RuneTime = TestMode.RuneTime
    local CurrentTime = GetTime()

    if TestMode.RuneOnCooldown >= RuneID then

      -- Use a 10 hour clock to simulate a test cooldown
      StartTime = CurrentTime - OneHour * RuneTime
      Duration = OneHour
      RuneReady = RuneTime == 0
    else
      StartTime = 0
      Duration = 0
      RuneReady = true
    end
  end

  return StartTime, Duration, RuneReady
end

-------------------------------------------------------------------------------
-- DoRuneTime
--
-- Gets called during rune cooldown
--
-- BBar           Current bar being used.
-- BoxNumber      Current box the call back happened on (RuneIndex)
-- Time           Current time
-- Done           If true then the timer is finished
-------------------------------------------------------------------------------
local function DoRuneTime(UnitBarF, BBar, BoxNumber, Time, Done)
  if not Done then
    local Layout = UnitBarF.UnitBar.Layout

    if not Layout.HideText then
      BBar:SetValueFont(BoxNumber, 'time', Time)
    end
    if Layout.EnableTriggers then
      BBar:SetTriggers(BoxNumber, 'time', Time)
      BBar:DoTriggers()
    end
  else
    BBar:SetValueRawFont(BoxNumber, '')
  end
end

-------------------------------------------------------------------------------
-- DoRuneCooldown
--
-- Start or stop a rune cooldown.
--
-- RuneBar        The bar containing the runes.
-- Action         'start'    Start a new cooldown
--                'stop'     Stop an existing cooldown
--                'change'   changes the duration of a cooldown already in progress
--
-- RuneIndex      Current rune index
--
-- -------------  if using 'stop' the parameters below get ignored.
-- StartTime      Time in seconds when the cooldown will start. If StartTime is nil then
--                the cooldown is stopped
-- Duration       Amount of time in seconds the cooldown will animate for
-------------------------------------------------------------------------------
local function DoRuneCooldown(RuneBar, Action, RuneIndex, StartTime, Duration)
  local UB = RuneBar.UnitBar
  local Layout = UB.Layout
  local BBar = RuneBar.BBar
  local RuneFlag = Layout.RuneMode
  local ModeBar = strfind(RuneFlag, 'bar')
  local RuneMode = strfind(RuneFlag, 'rune')
  local BarSpark = Layout.BarSpark

  if Action == 'stop' then
    if BarMode then
      -- stop the timer then clear the bar
      BBar:SetFillTimeTexture(RuneIndex, RuneSBar)
      BBar:SetFillTexture(RuneIndex, RuneSBar, 0)
    end
    -- stop rune cooldown
    if RuneMode then
      BBar:SetCooldownTexture(RuneIndex, RuneEmptyTexture)
      BBar:SetCooldownTexture(RuneIndex, RuneTexture)
    end
    -- stop text timer
    if not Layout.HideText then
      BBar:SetValueTime(RuneIndex, DoRuneTime)
    end
  end

  if Action ~= 'stop' then
    local TestDuration = nil
    if Main.UnitBars.Testing then
      TestDuration = (GetTime() - StartTime) / OneHour
    end

    if Action ~= 'change' then
      if BarMode then
        if TestDuration then
          BBar:SetFillTexture(RuneIndex, RuneSBar, TestDuration, BarSpark)

          if Layout.EnableTriggers then
            BBar:SetTriggers(RuneIndex, 'time', TestDuration * 10)
            BBar:DoTriggers()
           end
        else
          BBar:SetFillTimeTexture(RuneIndex, RuneSBar, StartTime, Duration, 0, 1)
        end
      end
    elseif BarMode then
      -- Change the duration of an exisiting cooldown in progress.
      -- This gives a stutter free bar animation.
      if TestDuration then
        BBar:SetFillTexture(RuneIndex, RuneSBar, TestDuration, BarSpark)
      else
        BBar:SetFillTimeDurationTexture(RuneIndex, RuneSBar, Duration)
      end
    end
    if RuneMode and Layout.CooldownAnimation then
      BBar:SetCooldownTexture(RuneIndex, RuneEmptyTexture, StartTime, Duration)

      -- Set the cooldown for flash
      BBar:SetCooldownTexture(RuneIndex, RuneTexture, StartTime, Duration)
    end
    -- Start the text timer
    if Main.UnitBars.Testing then
      if not Layout.HideText then
        BBar:SetValueFont(RuneIndex, 'time', 10 * UB.TestMode.RuneTime)
      end
    else
      BBar:SetValueTime(RuneIndex, StartTime, Duration, -1, DoRuneTime)
    end
  end
end

-------------------------------------------------------------------------------
-- OnUpdateRunes    UnitBarsF function
--
-- Gets called by OnUpdate, see below
-------------------------------------------------------------------------------
local function RuneSwap(RuneIDA, RuneIDB)
  local StartTimeA, DurationA, RuneReadyA = GetRuneCooldown2(RuneIDA)
  local StartTimeB, DurationB, RuneReadyB = GetRuneCooldown2(RuneIDB)

  if RuneReadyA ~= RuneReadyB then
    return RuneReadyA
  end
  if StartTimeA ~= StartTimeB then
    return StartTimeA < StartTimeB
  end

  return RuneIDA < RuneIDB
end

local function OnUpdateRunes(self)
  self:SetScript('OnUpdate', nil)

  ---------------
  -- Set IsActive
  ---------------
  local RuneBar = self.RuneBar
  local AnyRecharging = false

  for RuneIndex = 1, MaxRunes do
    local _, _, RuneReady = GetRuneCooldown(RuneIndex)

    if RuneReady ~= nil and not RuneReady then
      AnyRecharging = true
    end
  end

  -- Set the IsActive flag.
  RuneBar.IsActive = AnyRecharging

  --------
  -- Check
  --------
  local LastHidden = self.Hidden
  RuneBar:StatusCheck()
  local Hidden = self.Hidden

  -- If not called by an event and Hidden is true then return
  if RuneBar.Event == nil and Hidden or LastHidden and Hidden then
    return
  end

  ------------
  -- Test Mode
  ------------
  local Testing = Main.UnitBars.Testing
  local UB = RuneBar.UnitBar
  local TestMode = UB.TestMode
  local PlayerSpecialization = Main.PlayerSpecialization

  if Testing then
    PlayerSpecialization = TestMode.BloodSpec and 1 or TestMode.FrostSpec and 2 or TestMode.UnHolySpec and 3 or 1
  end

  -------
  -- Draw
  -------
  local LastDuration = RuneBar.LastDuration
  local RuneOnCooldown = RuneBar.RuneOnCooldown

  if LastDuration == nil then
    LastDuration = {}
    RuneOnCooldown = {}
    RuneBar.LastDuration = LastDuration
    RuneBar.RuneOnCooldown = RuneOnCooldown
    for RuneID = 1, MaxRunes do
      LastDuration[RuneID] = false
      RuneOnCooldown[RuneID] = false
    end
  end


  local BBar = RuneBar.BBar
  local Layout = UB.Layout
  local EnableTriggers = Layout.EnableTriggers
  local RuneTime = TestMode.RuneTime
  local CurrentTime = GetTime()

  -- Update textures/colors if player specialization has changed
  if RuneBar.PlayerSpecialization ~= PlayerSpecialization then
    RuneBar.PlayerSpecialization = PlayerSpecialization
    RuneBar:SetAttr()
    return
  end

  -- Set this so RuneCooldown2 can access the RuneBar table in testmode
  RuneCooldownRuneBar = RuneBar

  sort(SortedRunes, RuneSwap)

  for RuneIndex = 1, MaxRunes do
    local RuneID = SortedRunes[RuneIndex]
    local StartTime, Duration, RuneReady = GetRuneCooldown2(RuneID)

    if not RuneReady then
      local LD = LastDuration[RuneID]
      local ROC = RuneOnCooldown[RuneID]

      -- Fresh timers always start from the bottom first due to sorting
      if not ROC then

        -- Clear bar of any previous timer
        DoRuneCooldown(RuneBar, 'stop', RuneIndex)
        DoRuneCooldown(RuneBar, 'start', RuneIndex, StartTime, Duration)

      -- Refresh only if rune moved or if its a dark rune. Since dark runes
      -- start times can change. This is done so stutter don't happen
      -- on bar animations.
      -- Dark rune is when the StartTime >= CurrentTime
      elseif ROC ~= RuneIndex or StartTime >= CurrentTime or Testing then

        -- Clear bar if dark rune
        if StartTime > CurrentTime then
          DoRuneCooldown(RuneBar, 'stop', RuneIndex)
        end
        DoRuneCooldown(RuneBar, 'start', RuneIndex, StartTime, Duration)

      -- Change speed of rune due to haste changing.
      elseif LD ~= false and LD ~= Duration then
        DoRuneCooldown(RuneBar, 'change', RuneIndex, StartTime, Duration)
      end
      RuneOnCooldown[RuneID] = RuneIndex
      LastDuration[RuneID] = Duration
      BBar:SetHiddenTexture(RuneIndex, RuneTexture, true)
    else
      DoRuneCooldown(RuneBar, 'stop', RuneIndex)
      LastDuration[RuneID] = false
      RuneOnCooldown[RuneID] = false
      BBar:SetHiddenTexture(RuneIndex, RuneTexture, false)
    end
    if EnableTriggers then
      BBar:SetTriggers(RuneIndex, 'recharging', not RuneReady)
    end
  end

  if EnableTriggers then
    BBar:SetTriggers(RegionGroup, 'recharging', AnyRecharging)
    BBar:DoTriggers()
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the number of arcane charges of the player
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
--
-- NOTES:  The events for each rune all come in at once.  Inside of one frame.
--         The OnUpdate script will only fire after the last event comes in within one frame.
--         Then OnUpdate will fire on the very next frame and call UpDateRunes
-------------------------------------------------------------------------------
function Main.UnitBarsF.RuneBar:Update(Event, ...)
  local OnUpdateFrame = self.OnUpdateFrame

  OnUpdateFrame.RuneBar = self
  self.Event = Event

  -- Calling the function directly for testing creates less glitches
  if not Main.UnitBars.Testing then
    OnUpdateFrame:SetScript('OnUpdate', OnUpdateRunes)
  else
    OnUpdateRunes(OnUpdateFrame)
  end
end

--*****************************************************************************
--
-- Runebar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetAttr
--
-- Sets different parts of the runebar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.RuneBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then
    BBar:SO('Text', '_Font', function()
      for Index = 1, MaxRunes do
        BBar:UpdateFont(Index)
      end
    end)

    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers', function(v) BBar:EnableTriggers(v, Groups) Update = true end)
    BBar:SO('Layout', 'RuneMode',       function(v)
      BBar:SetHidden(0, BarMode, true)
      BBar:SetHidden(0, RuneMode, true)
      if strfind(v, 'rune') then
        BBar:SetHidden(0, RuneMode, false)
      end
      if strfind(v, 'bar') then
        BBar:SetHidden(0, BarMode, false)
      end
      Display = true
    end)
    BBar:SO('Layout', 'CooldownFlash',  function(v) BBar:SetCooldownDrawFlash(0, RuneTexture, v) end)
    BBar:SO('Layout', 'CooldownLine',   function(v) BBar:SetCooldownDrawEdge(0, RuneEmptyTexture, v) end)

    BBar:SO('Layout', 'HideRegion',     function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',           function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',          function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'BorderPadding',  function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',    function(v) BBar:SetFillReverseTexture(0, RuneSBar, v) Update = true end)
    BBar:SO('Layout', 'HideText',       function(v)
      if v then
        BBar:SetValueRawFont(0, '')
      end
    end)
    BBar:SO('Layout', 'Rotation',       function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',          function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',        function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',   function(v) BBar:SetScaleTextureFrame(0, RuneMode, v) Display = true end)
    BBar:SO('Layout', 'Align',          function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX',  function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY',  function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',   function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',   function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    -- More layout
    BBar:SO('Layout', 'BarSpark',       function(v) BBar:SetHiddenSpark(0, RuneSBar, not v) end)
    BBar:SO('Layout', '_RuneLocation',  function(v) BBar:SetPointTextureFrame(0, RuneMode, 'CENTER', BarMode, v.RunePosition, v.RuneOffsetX, v.RuneOffsetY) Display = true end)
    -- This is needed for when SetAttr() is called from Update()
    BBar:SO('Layout', '_Texture',       function(v)
      local PlayerSpecialization = self.PlayerSpecialization

      if PlayerSpecialization then
        BBar:SetCooldownSwipeTexture(0, RuneEmptyTexture, RuneCooldownFillTexture[PlayerSpecialization])
        BBar:SetCooldownEdgeTexture(0, RuneEmptyTexture, RuneCooldownSparkTexture[PlayerSpecialization])
        BBar:SetAtlasTexture(0, RuneTexture, RuneReadyTexture[PlayerSpecialization])
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

    BBar:SO('Background', 'BgTexture',         function(v) BBar:SetBackdrop(0, BarMode, v) end)
    BBar:SO('Background', 'BorderTexture',     function(v) BBar:SetBackdropBorder(0, BarMode, v) end)
    BBar:SO('Background', 'BgTile',            function(v) BBar:SetBackdropTile(0, BarMode, v) end)
    BBar:SO('Background', 'BgTileSize',        function(v) BBar:SetBackdropTileSize(0, BarMode, v) end)
    BBar:SO('Background', 'BorderSize',        function(v) BBar:SetBackdropBorderSize(0, BarMode, v) end)
    BBar:SO('Background', 'Padding',           function(v) BBar:SetBackdropPadding(0, BarMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'ColorBlood',        function(v, UB, OD)
      if self.PlayerSpecialization == 1 then
        BBar:SetBackdropColor(OD.Index, BarMode, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Background', 'ColorFrost',        function(v, UB, OD)
      if self.PlayerSpecialization == 2 then
        BBar:SetBackdropColor(OD.Index, BarMode, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Background', 'ColorUnholy',       function(v, UB, OD)
      if self.PlayerSpecialization == 3 then
        BBar:SetBackdropColor(OD.Index, BarMode, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Background', 'BorderColorBlood',  function(v, UB, OD)
      if UB.Background.EnableBorderColor then
        if self.PlayerSpecialization == 1 then
          BBar:SetBackdropBorderColor(OD.Index, BarMode, OD.r, OD.g, OD.b, OD.a)
        end
      else
        BBar:SetBackdropBorderColor(OD.Index, BarMode, nil)
      end
    end)
    BBar:SO('Background', 'BorderColorFrost',  function(v, UB, OD)
      if UB.Background.EnableBorderColor then
        if self.PlayerSpecialization == 2 then
          BBar:SetBackdropBorderColor(OD.Index, BarMode, OD.r, OD.g, OD.b, OD.a)
        end
      else
        BBar:SetBackdropBorderColor(OD.Index, BarMode, nil)
      end
    end)
    BBar:SO('Background', 'BorderColorUnholy', function(v, UB, OD)
      if UB.Background.EnableBorderColor then
        if self.PlayerSpecialization == 3 then
          BBar:SetBackdropBorderColor(OD.Index, BarMode, OD.r, OD.g, OD.b, OD.a)
        end
      else
        BBar:SetBackdropBorderColor(OD.Index, BarMode, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',  function(v) BBar:SetTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'SyncFillDirection', function(v) BBar:SyncFillDirectionTexture(0, RuneSBar, v) Update = true end)
    BBar:SO('Bar', 'Clipping',          function(v) BBar:SetClippingTexture(0, RuneSBar, v) Update = true end)
    BBar:SO('Bar', 'FillDirection',     function(v) BBar:SetFillDirectionTexture(0, RuneSBar, v) Update = true end)
    BBar:SO('Bar', 'RotateTexture',     function(v) BBar:SetRotationTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'ColorBlood',        function(v, UB, OD)
      if self.PlayerSpecialization == 1 then
        BBar:SetColorTexture(OD.Index, RuneSBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorFrost',       function(v, UB, OD)
      if self.PlayerSpecialization == 2 then
        BBar:SetColorTexture(OD.Index, RuneSBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorUnholy',      function(v, UB, OD)
      if self.PlayerSpecialization == 3 then
        BBar:SetColorTexture(OD.Index, RuneSBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', '_Size',            function(v) BBar:SetSizeTextureFrame(0, BarMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',          function(v) BBar:SetPaddingTextureFrame(0, BarMode, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- Creates the main rune bar frame that contains the death knight runes
--
-- UnitBarF     The unitbar frame which will contain the rune bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.RuneBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxRunes)

  local Names = {}
  local Name = nil

  BBar:CreateTextureFrame(0, BarMode, 1)
    BBar:CreateTexture(0, BarMode, RuneSBar, 'statusbar')

  for RuneIndex = 1, MaxRunes do
    BBar:SetFillTexture(RuneIndex, RuneSBar, 0)

    BBar:CreateTextureFrame(RuneIndex, RuneMode, 20)
      BBar:CreateTexture(RuneIndex, RuneMode, RuneEmptyTexture, 'cooldown')
        BBar:SetAtlasTexture(RuneIndex, RuneEmptyTexture, RuneDataAtlasEmptyRune)
        BBar:SetCooldownReverse(RuneIndex, RuneEmptyTexture, true)
        BBar:SetCooldownSwipeTexture(RuneIndex, RuneEmptyTexture, RuneCooldownFillTexture[1])
        BBar:SetCooldownEdgeTexture(RuneIndex, RuneEmptyTexture, RuneCooldownSparkTexture[1])
        BBar:SetSizeTexture(RuneIndex, RuneEmptyTexture, RuneDataWidth, RuneDataHeight)
        BBar:SetSizeCooldownTexture(RuneIndex, RuneEmptyTexture, RuneDataWidth, RuneDataHeight, 0, 1.5)

        -- Hide flash animation and make the cooldown a circle
        BBar:SetCooldownDrawFlash(RuneIndex, RuneEmptyTexture, false)
        BBar:SetCooldownCircular(RuneIndex, RuneEmptyTexture, true)

      BBar:CreateTexture(RuneIndex, RuneMode, RuneTexture, 'cooldown')
        BBar:SetAtlasTexture(RuneIndex, RuneTexture, RuneReadyTexture[1])
        BBar:SetSizeTexture(RuneIndex, RuneTexture, RuneDataWidth, RuneDataHeight)
        BBar:SetSizeCooldownTexture(RuneIndex, RuneTexture, RuneDataWidth, RuneDataHeight)

        -- Create an invisible cooldown, this is for flash animation only.
        -- Also hide the edge texture
        BBar:SetCooldownSwipeColorTexture(RuneIndex, RuneTexture, 0, 0, 0, 0)
        BBar:SetCooldownDrawEdge(RuneIndex, RuneTexture, false)

    local Name = Groups[RuneIndex][2]
    Names[RuneIndex] = Name
    BBar:SetTooltipBox(RuneIndex, Name)
  end

  BBar:SetTooltipRegion(UB.Name .. ' - Region')

  BBar:SetSizeTextureFrame(0, BarMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, RuneMode, RuneDataWidth, RuneDataHeight)

  -- Set the texture scale default for Texture Size triggers.
  BBar:SetScaleAllTexture(0, AllTextures, 1)

  BBar:SetHiddenTexture(0, RuneSBar, false)
  BBar:SetHiddenTexture(0, RuneEmptyTexture, false)
  BBar:SetHiddenTexture(0, RuneTexture, false)

  BBar:CreateFont('Text', 0)

  -- set offset for trigger bar offset.
  BBar:SetOffsetTextureFrame(0, BarMode, 0, 0, 0, 0)

  UnitBarF.OnUpdateFrame = CreateFrame('Frame')
  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Runebar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.RuneBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'RUNE_POWER_UPDATE', self.Update)
end
