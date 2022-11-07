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
local OT = Bar.TriggerObjectTypes

-- localize some globals.
local _, _G, print =
      _, _G, print
local GetTime, strfind, sort =
      GetTime, strfind, sort
local GetRuneCooldown, CreateFrame =
      GetRuneCooldown, CreateFrame

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the rune bar displayed on screen
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
local RuneCooldownRuneBar
local OneMinute = 60
local SparksCreated = false
local SparksOn = false

local BoxMode = 1
local TextureMode = 2

local RuneSBar = 10
local RuneSBarSpark = 15
local RuneCooldownTexture = 20

local ObjectsInfo = { -- type, id, additional menu text, textures
  { OT.BackgroundBorder,      1,  '', BoxMode             },
  { OT.BackgroundBorderColor, 2,  '', BoxMode             },
  { OT.BackgroundBackground,  3,  '', BoxMode             },
  { OT.BackgroundColor,       4,  '', BoxMode             },
  { OT.BarTexture,            5,  '', RuneSBar            },
  { OT.BarColor,              6,  '', RuneSBar            },
  { OT.BarOffset,             7,  '', BoxMode             },
  { OT.TextureScale,          8,  '', RuneCooldownTexture },
  { OT.TextFontColor,         9,  ''                      },
  { OT.TextFontOffset,        10, ''                      },
  { OT.TextFontSize,          11, ''                      },
  { OT.TextFontType,          12, ''                      },
  { OT.TextFontStyle,         13, ''                      },
  { OT.Sound,                 14, ''                      },
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
    'state',   'Any Recharging',
    'state',   'Recharging 1',
    'state',   'Recharging 2',
    'state',   'Recharging 3',
    'state',   'Recharging 4',
    'state',   'Recharging 5',
    'state',   'Recharging 6',
    'decimal', 'Time 1',
    'decimal', 'Time 2',
    'decimal', 'Time 3',
    'decimal', 'Time 4',
    'decimal', 'Time 5',
    'decimal', 'Time 6',
  },
  {1,    'Rune 1',             ObjectsInfo},       -- 1
  {2,    'Rune 2',             ObjectsInfo},       -- 2
  {3,    'Rune 3',             ObjectsInfo},       -- 3
  {4,    'Rune 4',             ObjectsInfo},       -- 4
  {5,    'Rune 5',             ObjectsInfo},       -- 5
  {6,    'Rune 6',             ObjectsInfo},       -- 6
  {'a',  'All',                ObjectsInfo},       -- 7
  {'aa', 'All Recharging',     ObjectsInfo},       -- 8
  {'ai', 'All not Recharging', ObjectsInfo},       -- 9
  {'r',  'Region',             ObjectsInfoRegion}, -- 10
}

local RuneSBarSparkTexture = [[Interface\CastingBar\UI-CastingBar-Spark]]

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
-- RuneBar spark
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetSparksOn
--
-- Turns sparks on or off. When off then the sparks will not get shown even if
-- not hidden
-------------------------------------------------------------------------------
local function SetSparksOn(BBar, On)
  SparksOn = On
  if SparksOn and not SparksCreated then
    SparksCreated = true

    -- Create spark textures
    BBar:CreateTexture(0, BoxMode, RuneSBarSpark, 'statusbar_noclip', 1)
    BBar:SetTexture(0, RuneSBarSpark, RuneSBarSparkTexture)
    BBar:SetBlendModeTexture(0, RuneSBarSpark, 'ADD')

    -- Set the pixel length
    BBar:SetFillPixelLengthTexture(0, RuneSBarSpark, 16)

    -- Make sure the spark gets scaled horizontally or vertically only
    -- when in those modes
    BBar:SetFillScaleHorizontalTexture(0, RuneSBarSpark, 1, 2) --2.3
    BBar:SetFillScaleVerticalTexture(0, RuneSBarSpark, 2, 1) --2.3

    -- Center spark on the edge of the statusbar
    BBar:SetFillPointPixelTexture(0, RuneSBarSpark, 'CENTER')

    -- Set to 1 since the spark is a normal statusbar texture.
    -- Otherwise it won't be visible
    for RuneIndex = 1, MaxRunes do
      BBar:SetFillTexture(RuneIndex, RuneSBarSpark, 1)
    end

    -- Tag sparks to statusbar
    BBar:TagFillTexture(0, RuneSBarSpark, 'left-right', RuneSBar)
  end
  -- Hide all the sparks
  if SparksCreated then
    BBar:SetHiddenTexture(0, RuneSBarSpark, true)
  end
end

-------------------------------------------------------------------------------
-- ShowSpark
--
-- Shows or hides the spark
-------------------------------------------------------------------------------
local function ShowSpark(BBar, RuneIndex, Show)
  if SparksOn then
    BBar:SetHiddenTexture(RuneIndex, RuneSBarSpark, not Show)
  end
end

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

      -- Use a 1 hour clock to simulate a test cooldown
      StartTime = CurrentTime - OneMinute * RuneTime
      Duration = OneMinute
      RuneReady = RuneTime == 1
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
      BBar:SetTriggers('Time ' .. BoxNumber, Time)
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
  local TestMode = UB.TestMode
  local BBar = RuneBar.BBar
  local Testing = Main.UnitBars.Testing
  local Mode = Layout.Mode
  local TextureMode = strfind(Mode, 'texture')
  local BoxMode = strfind(Mode, 'box')
  local BarSpark = Layout.BarSpark

  if Action == 'stop' then
    if BoxMode then
      ShowSpark(BBar, RuneIndex, false)

      -- stop the timer then clear the bar
      BBar:SetFillTimeTexture(RuneIndex, RuneSBar)
      BBar:SetFillTexture(RuneIndex, RuneSBar, 0)
    end
    -- stop rune cooldown
    if TextureMode then
      if Testing then
        BBar:SetCooldownPauseTexture(RuneIndex, RuneCooldownTexture, false)
      end
      BBar:SetCooldownTexture(RuneIndex, RuneCooldownTexture)
    end
    -- stop text timer
    if not Layout.HideText then
      BBar:SetValueTime(RuneIndex, DoRuneTime)
      if Layout.EnableTriggers then
        BBar:SetTriggers('Time ' .. RuneIndex, 0)
        BBar:DoTriggers()
      end
    end
  end

  if Action ~= 'stop' then

    -- start
    if Action == 'start' then
      if BoxMode then
        ShowSpark(BBar, RuneIndex, BarSpark)
        if Testing then
          local RuneTime = TestMode.RuneTime

          BBar:SetFillTexture(RuneIndex, RuneSBar, RuneTime)

          if Layout.EnableTriggers then
            BBar:SetTriggers('Time ' .. RuneIndex, 10 * (1 - RuneTime))
            BBar:DoTriggers()
           end
        else
          BBar:SetFillTimeTexture(RuneIndex, RuneSBar, StartTime, Duration, 0, 1)
        end
      end

    -- change
    elseif BoxMode then
      -- Change the duration of an exisiting cooldown in progress.
      -- This gives a stutter free bar animation.
      BBar:SetFillTimeDurationTexture(RuneIndex, RuneSBar, Duration)
    end
    if TextureMode and Layout.CooldownAnimation then
      if Testing then
        BBar:SetCooldownPauseTexture(RuneIndex, RuneCooldownTexture, true)
      end
      BBar:SetCooldownTexture(RuneIndex, RuneCooldownTexture, StartTime, Duration)
    end
    -- Start the text timer
    if Testing then
      if not Layout.HideText then
        BBar:SetValueFont(RuneIndex, 'time', 10 * (1 - TestMode.RuneTime))
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
  local self = self.RuneBar

  ---------------
  -- Set IsActive
  ---------------
  local AnyRecharging = false

  for RuneIndex = 1, MaxRunes do
    local _, _, RuneReady = GetRuneCooldown(RuneIndex)

    if RuneReady ~= nil and not RuneReady then
      AnyRecharging = true
    end
  end

  -- Set the IsActive flag.
  self.IsActive = AnyRecharging

  --------
  -- Check
  --------
  local LastHidden = self.Hidden
  self:StatusCheck()
  local Hidden = self.Hidden

  -- If not called by an event and Hidden is true then return
  if self.Event == nil and Hidden or LastHidden and Hidden then
    return
  end

  ------------
  -- Test Mode
  ------------
  local BBar = self.BBar
  local Testing = Main.UnitBars.Testing
  local UB = self.UnitBar
  local TestMode = UB.TestMode
  local PlayerSpecialization = Main.PlayerClass == 'DEATHKNIGHT' and Main.PlayerSpecialization or 1

  if Testing then
    self.Testing = true
    AnyRecharging = TestMode.RuneOnCooldown > 0
    PlayerSpecialization = TestMode.BloodSpec and 1 or TestMode.FrostSpec and 2 or TestMode.UnHolySpec and 3 or 1

  -- Just switched out of test mode do a clean up
  elseif self.Testing then
    self.Testing = false
    BBar:SetCooldownPauseTexture(0, RuneCooldownTexture, false)
  end

  -------
  -- Draw
  -------
  local LastDuration = self.LastDuration
  local RuneOnCooldown = self.RuneOnCooldown

  if LastDuration == nil then
    LastDuration = {}
    RuneOnCooldown = {}
    self.LastDuration = LastDuration
    self.RuneOnCooldown = RuneOnCooldown
    for RuneID = 1, MaxRunes do
      LastDuration[RuneID] = false
      RuneOnCooldown[RuneID] = false
    end
  end

  local Layout = UB.Layout
  local EnableTriggers = Layout.EnableTriggers
  local CurrentTime = GetTime()

  -- Update textures/colors if player specialization has changed
  if self.PlayerSpecialization ~= PlayerSpecialization then
    self.PlayerSpecialization = PlayerSpecialization
    self:SetAttr()
    return
  end

  -- Set this so RuneCooldown2 can access the RuneBar table in testmode
  RuneCooldownRuneBar = self

  sort(SortedRunes, RuneSwap)

  for RuneIndex = 1, MaxRunes do
    local RuneID = SortedRunes[RuneIndex]
    local StartTime, Duration, RuneReady = GetRuneCooldown2(RuneID)

    -- If StartTime is nil that means GetRuneCooldown() return all nils.
    -- This happens during a zone change. Caused when hearthing while
    -- some of the runes are still on cooldown
    if StartTime then
      if not RuneReady then
        local LD = LastDuration[RuneID]
        local ROC = RuneOnCooldown[RuneID]

        -- Fresh timers always start from the bottom first due to sorting
        if not ROC then

          -- Clear bar of any previous timer
          DoRuneCooldown(self, 'stop', RuneIndex)
          DoRuneCooldown(self, 'start', RuneIndex, StartTime, Duration)

        -- Refresh only if rune moved or if its a dark rune. Since dark runes
        -- start times can change. This is done so stutter don't happen
        -- on bar animations.
        -- Dark rune is when the StartTime >= CurrentTime
        elseif ROC ~= RuneIndex or StartTime >= CurrentTime or Testing then

          -- Clear bar if dark rune
          if StartTime > CurrentTime then
            DoRuneCooldown(self, 'stop', RuneIndex)
          end
          DoRuneCooldown(self, 'start', RuneIndex, StartTime, Duration)

        -- Change speed of rune due to haste changing.
        elseif LD ~= false and LD ~= Duration then
          DoRuneCooldown(self, 'change', RuneIndex, StartTime, Duration)
        end
        RuneOnCooldown[RuneID] = RuneIndex
        LastDuration[RuneID] = Duration
        -- Set empty texture to show during cooldown
        BBar:SetAtlasTexture(RuneIndex, RuneCooldownTexture, RuneDataAtlasEmptyRune)
      else
        DoRuneCooldown(self, 'stop', RuneIndex)
        LastDuration[RuneID] = false
        RuneOnCooldown[RuneID] = false
        -- Set rune ready texture after cooldown is over
        BBar:SetAtlasTexture(0, RuneCooldownTexture, RuneReadyTexture[PlayerSpecialization])
      end
      if EnableTriggers then
        BBar:SetTriggers('Recharging ' .. RuneIndex, not RuneReady)
        BBar:SetTriggersActive(RuneIndex, not RuneReady)
      end
    end
  end
  if EnableTriggers then
    BBar:SetTriggers('Any Recharging', AnyRecharging)
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

  OnUpdateFrame.RuneBar.Event = Event

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

    BBar:SO('Layout', 'EnableTriggers',   function(v) BBar:EnableTriggers(v, GroupsInfo) Update = true end)
    BBar:SO('Layout', 'Mode',             function(v)
      BBar:SetHidden(0, BoxMode, true)
      BBar:SetHidden(0, TextureMode, true)
      if strfind(v, 'texture') then
        BBar:SetHidden(0, TextureMode, false)
      end
      if strfind(v, 'box') then
        BBar:SetHidden(0, BoxMode, false)
      end
      Display = true
    end)
    BBar:SO('Layout', 'CooldownFlash',    function(v) BBar:SetCooldownDrawFlashTexture(0, RuneCooldownTexture, v) end)
    BBar:SO('Layout', 'CooldownLine',     function(v) BBar:SetCooldownDrawEdgeTexture(0, RuneCooldownTexture, v) end)

    BBar:SO('Layout', 'HideRegion',       function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',             function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',            function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'BorderPadding',    function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',      function(v) BBar:SetFillReverseTexture(0, RuneSBar, v) Update = true end)
    BBar:SO('Layout', 'HideText',         function(v)
      if v then
        BBar:SetValueRawFont(0, '')
      end
    end)
    BBar:SO('Layout', 'Rotation',         function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',            function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',          function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',     function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'Align',            function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX',    function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY',    function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',     function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',     function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    -- More layout
    BBar:SO('Layout', 'BarSpark',         function(v) SetSparksOn(BBar, v) end)
    BBar:SO('Layout', '_TextureLocation', function(v) BBar:SetPointTextureFrame(0, TextureMode, 'CENTER', BoxMode, v.TexturePosition, v.TextureOffsetX, v.TextureOffsetY) Display = true end)
    -- This is needed for when SetAttr() is called from Update()
    BBar:SO('Layout', '_Texture',         function(v)
      local PlayerSpecialization = self.PlayerSpecialization

      if PlayerSpecialization then
        BBar:SetCooldownSwipeTexture(0, RuneCooldownTexture, RuneCooldownFillTexture[PlayerSpecialization])
        BBar:SetCooldownEdgeTexture(0, RuneCooldownTexture, RuneCooldownSparkTexture[PlayerSpecialization])
        BBar:SetAtlasTexture(0, RuneCooldownTexture, RuneReadyTexture[PlayerSpecialization])
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

    BBar:SO('Background', 'BgTexture',         function(v) BBar:SetBackdrop(0, BoxMode, v) end)
    BBar:SO('Background', 'BorderTexture',     function(v) BBar:SetBackdropBorder(0, BoxMode, v) end)
    BBar:SO('Background', 'BgTile',            function(v) BBar:SetBackdropTile(0, BoxMode, v) end)
    BBar:SO('Background', 'BgTileSize',        function(v) BBar:SetBackdropTileSize(0, BoxMode, v) end)
    BBar:SO('Background', 'BorderSize',        function(v) BBar:SetBackdropBorderSize(0, BoxMode, v) end)
    BBar:SO('Background', 'Padding',           function(v) BBar:SetBackdropPadding(0, BoxMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'ColorBlood',        function(v, UB, OD)
      if self.PlayerSpecialization == 1 then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Background', 'ColorFrost',        function(v, UB, OD)
      if self.PlayerSpecialization == 2 then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Background', 'ColorUnholy',       function(v, UB, OD)
      if self.PlayerSpecialization == 3 then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Background', 'BorderColorBlood',  function(v, UB, OD)
      if UB.Background.EnableBorderColor then
        if self.PlayerSpecialization == 1 then
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
        end
      else
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
      end
    end)
    BBar:SO('Background', 'BorderColorFrost',  function(v, UB, OD)
      if UB.Background.EnableBorderColor then
        if self.PlayerSpecialization == 2 then
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
        end
      else
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
      end
    end)
    BBar:SO('Background', 'BorderColorUnholy', function(v, UB, OD)
      if UB.Background.EnableBorderColor then
        if self.PlayerSpecialization == 3 then
          BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
        end
      else
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',  function(v) BBar:SetTexture(0, RuneSBar, v) end)
    BBar:SO('Bar', 'SyncFillDirection', function(v) BBar:SyncFillDirectionTexture(0, RuneSBar, v) Update = true end)
    BBar:SO('Bar', 'Clipping',          function(v) BBar:SetFillClippingTexture(0, RuneSBar, v) Update = true end)
    BBar:SO('Bar', 'FillDirection',     function(v) BBar:SetFillDirectionTexture(0, RuneSBar, v) Update = true end)
    BBar:SO('Bar', 'RotateTexture',     function(v) BBar:SetFillRotationTexture(0, RuneSBar, v) end)
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
-- Creates the main rune bar frame that contains the death knight runes
--
-- UnitBarF     The unitbar frame which will contain the rune bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.RuneBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxRunes)

  local Names = {}

  BBar:CreateTextureFrame(0, BoxMode, 1, 'statusbar')
    BBar:CreateTexture(0, BoxMode, RuneSBar, 'statusbar', 1)

  for RuneIndex = 1, MaxRunes do
    BBar:CreateTextureFrame(RuneIndex, TextureMode, 20)
      BBar:CreateTexture(RuneIndex, TextureMode, RuneCooldownTexture, 'cooldown')
        BBar:SetAtlasTexture(RuneIndex, RuneCooldownTexture, RuneDataAtlasEmptyRune)
        BBar:SetCooldownReverseTexture(RuneIndex, RuneCooldownTexture, true)
        BBar:SetCooldownSwipeTexture(RuneIndex, RuneCooldownTexture, RuneCooldownFillTexture[1])
        BBar:SetCooldownEdgeTexture(RuneIndex, RuneCooldownTexture, RuneCooldownSparkTexture[1])
        BBar:SetSizeTexture(RuneIndex, RuneCooldownTexture, RuneDataWidth, RuneDataHeight)
        BBar:SetSizeCooldownTexture(RuneIndex, RuneCooldownTexture, RuneDataWidth, RuneDataHeight, 0, 1.5)

        -- show flash animation and make the cooldown a circle
        BBar:SetCooldownDrawFlashTexture(RuneIndex, RuneCooldownTexture, true)
        BBar:SetCooldownCircularTexture(RuneIndex, RuneCooldownTexture, true)

    local Name = GroupsInfo[RuneIndex][2]
    Names[RuneIndex] = Name
    BBar:SetTooltipBox(RuneIndex, Name)
  end

  BBar:SetTooltipRegion(UB._Name .. ' - Region')

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, RuneDataWidth, RuneDataHeight)

  -- Set the texture scale default for Texture Size triggers.
  BBar:SetScaleAllTexture(0, RuneCooldownTexture, 1)

  BBar:SetHiddenTexture(0, RuneSBar, false)
  BBar:SetHiddenTexture(0, RuneCooldownTexture, false)

  BBar:CreateFont('Text', 0)

  -- set offset for trigger bar offset.
  BBar:SetOffsetTextureFrame(0, BoxMode, 0, 0, 0, 0)

  local OnUpdateFrame = CreateFrame('Frame')
  OnUpdateFrame.RuneBar = UnitBarF
  UnitBarF.OnUpdateFrame = OnUpdateFrame

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
