--
-- EssenceBar.lua
--
-- Displays essence
--
-- Took the idea of using the remaining cooldown of the previous essence from Buds weakaura for Evoker essence
-- I do this by just moving the start time of the last cooldown, and apply it as a start time on the new cooldown
--==========================================================================================================

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local OT = Bar.TriggerObjectTypes

local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _, _G, print =
      _, _G, print
local ipairs, UnitPower, UnitPowerMax, GetPowerRegenForPowerType, GetTime, strfind, CreateFrame =
      ipairs, UnitPower, UnitPowerMax, GetPowerRegenForPowerType, GetTime, strfind, CreateFrame

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the essence bar displayed on screen.
-------------------------------------------------------------------------------
local MaxEssence = 6
local BaseEssence = 5
local Display = false
local Update = false
local SparksCreated = false
local SparksOn = false
local OneMinute = 60

-- Powertype constants
local PowerEssence = ConvertPowerType['ESSENCE']

local BoxMode = 1
local TextureMode = 2

local EssenceSBar = 10
local EssenceFullSBar = 11
local EssenceSBarSpark = 15
local EssenceBGDarkerTexture = 20
local EssenceBGTexture = 21
local EssenceIconTexture = 22
local EssenceCooldownTexture = 30
local EssenceCooldownSpinnerTexture = 31

local EssenceSBarSparkTexture = [[Interface\CastingBar\UI-CastingBar-Spark]]

local ObjectsInfo = { -- type, id, additional menu text, textures
  { OT.BackgroundBorder,      1,  '', BoxMode                },
  { OT.BackgroundBorderColor, 2,  '', BoxMode                },
  { OT.BackgroundBackground,  3,  '', BoxMode                },
  { OT.BackgroundColor,       4,  '', BoxMode                },
  { OT.BarTexture,            5,  '', EssenceSBar            },
  { OT.BarColor,              6,  '', EssenceSBar            },
  { OT.BarOffset,             7,  '', BoxMode                },
  { OT.TextureScale,          8,  '', EssenceCooldownTexture },
  { OT.TextFontColor,         9,  ''                         },
  { OT.TextFontOffset,        10, ''                         },
  { OT.TextFontSize,          11, ''                         },
  { OT.TextFontType,          12, ''                         },
  { OT.TextFontStyle,         13, ''                         },
  { OT.Sound,                 14, ''                         },
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
    'decimal', 'Time',
  },
  {1,    'Essence 1',    ObjectsInfo},       -- 1
  {2,    'Essence 2',    ObjectsInfo},       -- 2
  {3,    'Essence 3',    ObjectsInfo},       -- 3
  {4,    'Essence 4',    ObjectsInfo},       -- 4
  {5,    'Essence 5',    ObjectsInfo},       -- 5
  {6,    'Essence 6',    ObjectsInfo},       -- 6
  {'a',  'All',          ObjectsInfo},       -- 7
  {'aa', 'All Active',   ObjectsInfo},       -- 8
  {'ai', 'All Inactive', ObjectsInfo},       -- 9
  {'r',  'Region',       ObjectsInfoRegion}, -- 10
  {'c',  'Recharging',   ObjectsInfo},       -- 12
}

local EssenceTextures = {
  SparkTexture         = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_UF-Essence-TimerSpin]],
  SparkSpinnerTexture  = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_UF-Essence-Spinner]],
  BGTexture            = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_UF-Essence-BG]],
  IconTexture          = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_UF-Essence-Icon]],
  IconActiveTexture    = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_UF-Essence-Icon-Active]],
  BGActiveTexture      = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_UF-Essence-BG-Active]],
  BGActiveFillTexture  = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_UF-Essence-BG-Active-Fill]],
  FXBurstTexture       = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_UF-Essence-FX-Burst]],
}

local EssenceData = {
  TextureWidth = 24, TextureHeight = 24,
  {  -- Level 1   This one is only to make empty essence darker
    Cooldown = false,
    TextureNumber = EssenceBGDarkerTexture,
    Width = 24, Height = 24,
    Texture = EssenceTextures.BGTexture,
  },
  {  -- Level 2
    Cooldown = false,
    TextureNumber = EssenceBGTexture,
    Width = 24, Height = 24,
    Texture = EssenceTextures.BGTexture,
  },
  {  -- Level 3
    x = 1,
    Cooldown = false,
    TextureNumber = EssenceIconTexture,
    Width = 24, Height = 24,
    Texture = EssenceTextures.IconTexture,
  },
  {  -- Level 4
    Cooldown = true,
    TextureNumber = EssenceCooldownTexture,
    Width = 24, Height = 24,
    SwipeTexture = EssenceTextures.BGActiveFillTexture,
    EdgeTexture = EssenceTextures.SparkTexture,
    BlingTexture = EssenceTextures.FXBurstTexture,
  },
  {  -- Level 5
    Cooldown = true,
    TextureNumber = EssenceCooldownSpinnerTexture,
    Width = 24, Height = 24,
    SwipeTexture = '', -- no swipe texture so this just displays the spinner texture only
    EdgeTexture = EssenceTextures.SparkSpinnerTexture,
  },
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.EssenceBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- EssenceBar spark
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
    BBar:CreateTexture(0, BoxMode, EssenceSBarSpark, 'statusbar_noclip', 1)
    BBar:SetTexture(0, EssenceSBarSpark, EssenceSBarSparkTexture)
    BBar:SetBlendModeTexture(0, EssenceSBarSpark, 'ADD')

    -- Set the pixel length
    BBar:SetFillPixelLengthTexture(0, EssenceSBarSpark, 16)

    -- Make sure the spark gets scaled horizontally or vertically only
    -- when in those modes
    BBar:SetFillScaleHorizontalTexture(0, EssenceSBarSpark, 1, 2) --2.3
    BBar:SetFillScaleVerticalTexture(0, EssenceSBarSpark, 2, 1) --2.3

    -- Center spark on the edge of the statusbar
    BBar:SetFillPointPixelTexture(0, EssenceSBarSpark, 'CENTER')

    -- Set to 1 since the spark is a normal statusbar texture.
    -- Otherwise it won't be visible
    for EssenceIndex = 1, MaxEssence do
      BBar:SetFillTexture(EssenceIndex, EssenceSBarSpark, 1)
    end

    -- Tag sparks to statusbar
    BBar:TagFillTexture(0, EssenceSBarSpark, 'left-right', EssenceSBar)
  end
  -- Hide all the sparks
  if SparksCreated then
    BBar:SetHiddenTexture(0, EssenceSBarSpark, true)
  end
end

-------------------------------------------------------------------------------
-- ShowSpark
--
-- Shows or hides the spark
-------------------------------------------------------------------------------
local function ShowSpark(BBar, EssenceCooldown, Show)
  if SparksOn then
    BBar:SetHiddenTexture(EssenceCooldown, EssenceSBarSpark, not Show)
  end
end

--*****************************************************************************
--
-- Essencebar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- GetEssenceCooldown
--
-- Subfunction of Update()
--
-- Returns
--   Essence                Essence left
--   NumEssence             Max amount of essence
--   Action                 'stop'   : whole bar is fully recharged. Stop last cooldown
--                          'start'  : start a new cooldown
--                          'change' : change the duration of a cooldown in progress
--                          nil      : nothing to update
--   LastEssenceCooldown    Contains the last Essence on cooldown, otherwise nil
--   EssenceCooldown        Essence that is on cooldown (Essence + 1)
--                          This is nil if no essence is on cooldown
--   StartTime              Time the cooldown started.  This will be set into the past
--                          to handle duration changes/spent essence. Nil if nothing is on cooldown
--   Duration               Length of the cooldown in seconds
-------------------------------------------------------------------------------
local function GetEssenceCooldown(EssenceBar)
  local Testing = Main.UnitBars.Testing
  local Essence
  local NumEssence
  local Duration
  local LastEssenceCooldown
  local EssenceCooldown
  local StartTime
  local Action
  local CurrentTime = GetTime()

  if Testing then
    local UB = EssenceBar.UnitBar
    local TestMode = UB.TestMode
    local EssenceTime = TestMode.EssenceTime
    Essence = TestMode.Essence
    NumEssence = BaseEssence + TestMode.ExtraEssence

    -- Clip essence to max essence
    if NumEssence > MaxEssence then
      NumEssence = MaxEssence
    end
    -- Clip essence
    if Essence > NumEssence then
      Essence = NumEssence
    end

    EssenceBar.Testing = true

    Duration = OneMinute
    StartTime = CurrentTime - OneMinute * EssenceTime

    if Essence < NumEssence then
      EssenceCooldown = Essence + 1
    end
    LastEssenceCooldown = EssenceBar.LastEssenceCooldown
    EssenceBar.LastEssenceCooldown = EssenceCooldown

    if EssenceTime == 1 then
      Action = 'stop'
    else
      Action = 'start'
    end
  else
    -- Just switched out of test mode do a clean up
    if EssenceBar.Testing then
      EssenceBar.Testing = false
      local BBar = EssenceBar.BBar

      BBar:SetCooldownPauseTexture(0, EssenceCooldownTexture, false)
      BBar:SetCooldownPauseTexture(0, EssenceCooldownSpinnerTexture, false)
    end

    Essence = UnitPower('player', PowerEssence)
    NumEssence = UnitPowerMax('player', PowerEssence)

    local Peace = GetPowerRegenForPowerType(PowerEssence)
    if Peace == nil or Peace == 0 then
      Peace = 0.2
    end
    Duration = 1 / Peace

    local LastEssence = EssenceBar.LastEssence or NumEssence

    -- Check for essence change
    if Essence ~= LastEssence then
      -- Can only have something on cooldown if essence is less than max
      if Essence < NumEssence then
        StartTime = CurrentTime

        -- Check for essence spent
        if Essence < LastEssence then
          local LastTime = EssenceBar.LastTime
          if LastTime then
            StartTime = LastTime
          end
        end
        EssenceCooldown = Essence + 1
        LastEssenceCooldown = EssenceBar.LastEssenceCooldown
        EssenceBar.LastEssenceCooldown = EssenceCooldown
        EssenceBar.LastTime = StartTime
        Action = 'start'
      end
      EssenceBar.LastEssence = Essence
    end

    -- Stop. Nothing is cooling down
    if Essence == NumEssence then
      LastEssenceCooldown = EssenceBar.LastEssenceCooldown
      EssenceBar.LastTime = false
      Action = 'stop'

    else
      -- Initialize duration
      local LastDuration = EssenceBar.LastDuration
      if LastDuration == nil then
        LastDuration = Duration
        EssenceBar.LastDuration = LastDuration
      end

      -- No need to check for duration change if a fresh cooldown started
      if Action == nil then
        -- Check for duration change from haste or talents of a cooldown in progress
        local LastTime = EssenceBar.LastTime

        if Duration ~= LastDuration and LastTime then
          local TimeElapsed = CurrentTime - LastTime
          local Value = TimeElapsed / EssenceBar.LastDuration
          StartTime = CurrentTime - Value * Duration

          EssenceCooldown = Essence + 1

          EssenceBar.LastTime = StartTime
          EssenceBar.LastDuration = Duration
          Action = 'change'
        end
      end
    end
  end
  return Essence, NumEssence, Action, LastEssenceCooldown, EssenceCooldown, StartTime, Duration
end

-------------------------------------------------------------------------------
-- DoEssenceTime
--
-- Gets called during essence cooldown
--
-- BBar           Current bar being used.
-- BoxNumber      Current box the call back happened on (Essence)
-- Time           Current time
-- Done           If true then the timer is finished
-------------------------------------------------------------------------------
local function DoEssenceTime(UnitBarF, BBar, BoxNumber, Time, Done)
  if not Done then
    local Layout = UnitBarF.UnitBar.Layout

    if not Layout.HideText then
      BBar:SetValueFont(BoxNumber, 'time', Time)
    end
    if Layout.EnableTriggers then
      BBar:SetTriggers('Time', Time)
      BBar:DoTriggers()
    end
  else
    BBar:SetValueRawFont(BoxNumber, '')
  end
end

-------------------------------------------------------------------------------
-- DoEssenceCooldown
--
-- EssenceBar        The bar containing the essence
-- Action            'start'    Starts a new cooldown
--                   'stop'     Stops the last active cooldown
--                   'change'   Changes the duration of a cooldown already in progress
--
-- EssenceCooldown   Contains the essence that is currently at peace (cooling down)
--
-- ---------------
-- StartTime         Time in seconds when the cooldown will start. If StartTime is nil then
--                   the cooldown is stopped
-- Duration          Amount of time in seconds the cooldown will animate for
-------------------------------------------------------------------------------
local function DoEssenceCooldown(EssenceBar, Action, EssenceCooldown, StartTime, Duration)
  local UB = EssenceBar.UnitBar
  local Layout = UB.Layout
  local TestMode = UB.TestMode
  local BBar = EssenceBar.BBar
  local Testing = Main.UnitBars.Testing
  local Mode = Layout.Mode
  local TextureMode = strfind(Mode, 'texture')
  local BoxMode = strfind(Mode, 'box')
  local BarSpark = Layout.BarSpark

  if EssenceCooldown then
    if Action == 'stop' then
      if BoxMode then
        ShowSpark(BBar, EssenceCooldown, false)

        -- stop the timer
        BBar:SetFillTimeTexture(EssenceCooldown, EssenceSBar)
      end
      -- Stop the essence texture cooldown
      if TextureMode then
        if Testing then
          BBar:SetCooldownPauseTexture(EssenceCooldown, EssenceCooldownTexture, false)
          BBar:SetCooldownPauseTexture(EssenceCooldown, EssenceCooldownSpinnerTexture, false)
        end
        BBar:SetCooldownTexture(EssenceCooldown, EssenceCooldownTexture)
        BBar:SetCooldownTexture(EssenceCooldown, EssenceCooldownSpinnerTexture)
      end
      -- stop the text timer
      if not Layout.HideText then
        BBar:SetValueTime(EssenceCooldown, DoEssenceTime)
        if Layout.EnableTriggers then
          BBar:SetTriggers('Time', 0)
          BBar:DoTriggers()
        end
      end
    end

    if Action ~= 'stop' then

      -- Start
      if Action == 'start' then
        if BoxMode then
          ShowSpark(BBar, EssenceCooldown, BarSpark)
          if Testing then
            -- test duration for this bar between 0 and 1
            local EssenceTime = TestMode.EssenceTime

            BBar:SetFillTexture(EssenceCooldown, EssenceSBar, EssenceTime)

            if Layout.EnableTriggers then
              BBar:SetTriggers('Time', 5 * (1 - EssenceTime))
              BBar:DoTriggers()
            end
          else
            BBar:SetFillTimeTexture(EssenceCooldown, EssenceSBar, StartTime, Duration, 0, 1)
          end
        end

      -- Change
      else
        if BoxMode then
          -- Change the duration of an exisiting cooldown in progress.
          -- This gives a stutter free bar animation.
          BBar:SetFillTimeDurationTexture(EssenceCooldown, EssenceSBar, Duration)
        end
        -- Stop the essence texture cooldown
        if TextureMode then
          BBar:SetCooldownTexture(EssenceCooldown, EssenceCooldownTexture)
          BBar:SetCooldownTexture(EssenceCooldown, EssenceCooldownSpinnerTexture)
        end
      end
      if Testing then
        BBar:SetCooldownPauseTexture(EssenceCooldown, EssenceCooldownTexture, true)
        BBar:SetCooldownPauseTexture(EssenceCooldown, EssenceCooldownSpinnerTexture, true)
      end
      if TextureMode and Layout.CooldownAnimation then
        BBar:SetCooldownTexture(EssenceCooldown, EssenceCooldownTexture, StartTime, Duration)
        if Layout.CooldownEssence then
          BBar:SetCooldownTexture(EssenceCooldown, EssenceCooldownSpinnerTexture, StartTime, Duration)
        end
      end

      -- Start the text timer
      if Testing then
        if not Layout.HideText then
          BBar:SetValueFont(EssenceCooldown, 'time', 5 * (1 - TestMode.EssenceTime))
        end
      else
        BBar:SetValueTime(EssenceCooldown, StartTime, Duration, -1, DoEssenceTime)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the essence of the player
--
-- Event         Event that called this function.  If nil then it wasn't called by an event.
-- Unit          Ignored just here for reference
-- PowerToken    String: PowerType in caps: MANA RAGE, etc
--               If nil then the units powertype is used instead
-------------------------------------------------------------------------------
function Main.UnitBarsF.EssenceBar:Update(Event, Unit, PowerToken)

  -------------------
  -- Check Power Type
  -------------------
  local PowerType
  if PowerToken then
    PowerType = ConvertPowerType[PowerToken]
  else
    PowerType = PowerEssence
  end

  -- Return if power type doesn't match that of essence
  if PowerType == nil or PowerType ~= PowerEssence then
    return
  end

  ---------------
  -- Set IsActive
  ---------------
  local Essence, NumEssence, Action, LastEssenceCooldown, EssenceCooldown, StartTime, Duration = GetEssenceCooldown(self)

  self.IsActive = Essence < NumEssence

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

  -------
  -- Draw
  -------
  local DarkTexture = EssenceTextures.BGTexture
  local LightTexture = EssenceTextures.BGActiveTexture
  local UB = self.UnitBar
  local ShowFull = UB.Bar.ShowFull
  local EnableTriggers = UB.Layout.EnableTriggers

  -- Check for max essence change
  if NumEssence > 0 and NumEssence ~= self.NumEssence then
    self.NumEssence = NumEssence

    -- Change the number of boxes in the bar
    for EssenceIndex = BaseEssence, MaxEssence do
      BBar:SetHidden(EssenceIndex, nil, EssenceIndex > NumEssence)
    end
    BBar:Display()
  end

  for EssenceIndex = 1, MaxEssence do
    if EssenceIndex <= Essence then
      -- Show full
      BBar:SetTexture(EssenceIndex, EssenceBGTexture, LightTexture)
      BBar:SetFillTexture(EssenceIndex, EssenceSBar, 1)

      BBar:SetHiddenTexture(EssenceIndex, EssenceIconTexture, false)
      if ShowFull then
        BBar:SetHiddenTexture(EssenceIndex, EssenceFullSBar, false)
      end
    else
      -- Show empty
      BBar:SetTexture(EssenceIndex, EssenceBGTexture, DarkTexture)
      if not Main.UnitBars.Testing or EssenceIndex ~= EssenceCooldown then
        BBar:SetFillTexture(EssenceIndex, EssenceSBar, 0)
      end
      BBar:SetHiddenTexture(EssenceIndex, EssenceIconTexture, true)
      if ShowFull then
        BBar:SetHiddenTexture(EssenceIndex, EssenceFullSBar, true)
      end
    end
    if EnableTriggers then
      BBar:SetTriggers('Recharging ' .. EssenceIndex, EssenceIndex == EssenceCooldown)
      BBar:SetTriggersActive(EssenceIndex, EssenceIndex <= Essence)
    end
  end
  if EnableTriggers then
    BBar:SetTriggers('Any Recharging', EssenceCooldown ~= nil)
    BBar:SetTriggersCustomGroup('Recharging', EssenceCooldown ~= nil, EssenceCooldown)
    BBar:DoTriggers()
  end

  if Action then
    -- stop
    DoEssenceCooldown(self, 'stop', LastEssenceCooldown)

    if Action == 'start' then
      DoEssenceCooldown(self, 'start', EssenceCooldown, StartTime, Duration)
    elseif Action == 'change' then
      DoEssenceCooldown(self, 'change', EssenceCooldown, StartTime, Duration)
    end
  end
end

-- Unit power frequent doesn't fire when duration changes
-- So need to use onupdate to check for the change
local function EssenceDurationOnUpdate(EDF)
  if not Main.UnitBars.Testing then
    local Peace = GetPowerRegenForPowerType(PowerEssence)
    if Peace == nil or Peace == 0 then
      Peace = 0.2
    end
    local Duration = 1 / Peace
    if EDF.Duration ~= Duration then
      EDF.Duration = Duration
      EDF.EssenceBar.Update(EDF.EssenceBar, 'OnUpdate', 'player', 'ESSENCE')
    end
  end
end

--*****************************************************************************
--
-- Essencebar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the essencebar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EssenceBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then
    BBar:SO('Text', '_Font', function()
      for Index = 1, MaxEssence do
        BBar:UpdateFont(Index)
      end
    end)

    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers', function(v) BBar:EnableTriggers(v, GroupsInfo) Update = true end)
    BBar:SO('Layout', 'Mode',           function(v)
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
    BBar:SO('Layout', 'CooldownFlash',    function(v) BBar:SetCooldownDrawFlashTexture(0, EssenceCooldownTexture, v) end)
    BBar:SO('Layout', 'CooldownLine',     function(v) BBar:SetCooldownDrawEdgeTexture(0, EssenceCooldownTexture, v) end)
    BBar:SO('Layout', 'CooldownEssence',  function(v) BBar:SetHiddenTexture(0, EssenceCooldownSpinnerTexture, v) end)
    BBar:SO('Layout', 'CooldownFill',     function(v) BBar:SetCooldownDrawSwipeTexture(0, EssenceCooldownTexture, v) end)

    BBar:SO('Layout', 'HideRegion',       function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',             function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',            function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'BorderPadding',    function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',      function(v) BBar:SetFillReverseTexture(0, EssenceSBar, v) Update = true end)
    BBar:SO('Layout', 'AnimationType',    function(v) BBar:SetAnimationTexture(0, EssenceIconTexture, v)
                                                      BBar:SetAnimationTexture(0, EssenceFullSBar, v)    end)
    BBar:SO('Layout', 'HideText',         function(v)
      if v then
        BBar:SetValueRawFont(0, '')
      end
    end)
    BBar:SO('Layout', 'Rotation',         function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',            function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',          function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'TextureScale',     function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'AnimationInTime',  function(v) BBar:SetAnimationDurationTexture(0, EssenceIconTexture, 'in', v)
                                                      BBar:SetAnimationDurationTexture(0, EssenceFullSBar, 'in', v)     end)
    BBar:SO('Layout', 'AnimationOutTime', function(v) BBar:SetAnimationDurationTexture(0, EssenceIconTexture, 'out', v)
                                                      BBar:SetAnimationDurationTexture(0, EssenceFullSBar, 'out', v)    end)
    BBar:SO('Layout', 'Align',            function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX',    function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY',    function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',     function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',     function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    -- More layout
    BBar:SO('Layout', 'BarSpark',         function(v) SetSparksOn(BBar, v) end)
    BBar:SO('Layout', '_TextureLocation', function(v) BBar:SetPointTextureFrame(0, TextureMode, 'CENTER', BoxMode, v.TexturePosition, v.TextureOffsetX, v.TextureOffsetY) Display = true end)

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

    BBar:SO('Background', 'BgTexture',     function(v) BBar:SetBackdrop(0, BoxMode, v) end)
    BBar:SO('Background', 'BorderTexture', function(v) BBar:SetBackdropBorder(0, BoxMode, v) end)
    BBar:SO('Background', 'BgTile',        function(v) BBar:SetBackdropTile(0, BoxMode, v) end)
    BBar:SO('Background', 'BgTileSize',    function(v) BBar:SetBackdropTileSize(0, BoxMode, v) end)
    BBar:SO('Background', 'BorderSize',    function(v) BBar:SetBackdropBorderSize(0, BoxMode, v) end)
    BBar:SO('Background', 'Padding',       function(v) BBar:SetBackdropPadding(0, BoxMode, v.Left, v.Right, v.Top, v.Bottom) end)
    BBar:SO('Background', 'Color',         function(v, UB, OD) BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Background', 'BorderColor',   function(v, UB, OD)
      if UB[OD.TableName].EnableBorderColor then
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      else
        BBar:SetBackdropBorderColor(OD.Index, BoxMode, nil)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',  function(v) BBar:SetTexture(0, EssenceSBar, v) end)
    BBar:SO('Bar', 'FullBarTexture',    function(v) BBar:SetTexture(0, EssenceFullSBar, v) end)
    BBar:SO('Bar', 'ShowFull',          function(v) BBar:SetHiddenTexture(0, EssenceFullSBar, not v) end)
    BBar:SO('Bar', 'SyncFillDirection', function(v) BBar:SyncFillDirectionTexture(0, EssenceSBar, v) Update = true end)
    BBar:SO('Bar', 'Clipping',          function(v) BBar:SetFillClippingTexture(0, EssenceSBar, v) Update = true end)
    BBar:SO('Bar', 'FillDirection',     function(v) BBar:SetFillDirectionTexture(0, EssenceSBar, v) Update = true end)
    BBar:SO('Bar', 'RotateTexture',     function(v) BBar:SetFillRotationTexture(0, EssenceSBar, v) end)
    BBar:SO('Bar', 'Color',             function(v, UB, OD) BBar:SetColorTexture(OD.Index, EssenceSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', 'ColorFull',         function(v, UB, OD) BBar:SetColorTexture(OD.Index, EssenceFullSBar, OD.r, OD.g, OD.b, OD.a) end)
    BBar:SO('Bar', '_Size',             function(v) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',           function(v) BBar:SetPaddingTextureFrame(0, BoxMode, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
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
-- UnitBarF     The unitbar frame which will contain the essence bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.EssenceBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxEssence)

  local Names = {}

  BBar:CreateTextureFrame(0, BoxMode, 1, 'statusbar')
    BBar:CreateTexture(0, BoxMode, EssenceSBar, 'statusbar', 1)
    BBar:CreateTexture(0, BoxMode, EssenceFullSBar, 'statusbar', 2)

  for EssenceIndex = 1, MaxEssence do
    BBar:CreateTextureFrame(EssenceIndex, TextureMode, 1)
    for _, ED in ipairs(EssenceData) do
      local TextureNumber = ED.TextureNumber

      if not ED.Cooldown then
        BBar:CreateTexture(EssenceIndex, TextureMode, TextureNumber, 'texture')
          BBar:SetTexture(EssenceIndex, TextureNumber, ED.Texture)
          BBar:SetSizeTexture(EssenceIndex, TextureNumber, ED.Width, ED.Height)
      else
        local BlingTexture = ED.BlingTexture

        BBar:CreateTexture(EssenceIndex, TextureMode, TextureNumber, 'cooldown')
          -- No texture is set on this cooldown so the cooldown is only
          -- visible during cooldown animation
          BBar:SetCooldownReverseTexture(EssenceIndex, TextureNumber, true)
          BBar:SetCooldownSwipeTexture(EssenceIndex, TextureNumber, ED.SwipeTexture)
          BBar:SetCooldownEdgeTexture(EssenceIndex, TextureNumber, ED.EdgeTexture)
          if BlingTexture then
            BBar:SetCooldownBlingTexture(EssenceIndex, TextureNumber, BlingTexture)
          end
          BBar:SetSizeTexture(EssenceIndex, TextureNumber, ED.Width, ED.Height)
          BBar:SetSizeCooldownTexture(EssenceIndex, TextureNumber, ED.Width, ED.Height, 0, 0)

          -- Hide flash animation and make the cooldown a circle
          BBar:SetCooldownDrawFlashTexture(EssenceIndex, TextureNumber, false)
          BBar:SetCooldownCircularTexture(EssenceIndex, TextureNumber, true)
      end
    end
    -- Need to set the full status bar texture to 1 so its visible
    BBar:SetFillTexture(EssenceIndex, EssenceFullSBar, 1)

    local Name = GroupsInfo[EssenceIndex][2]
    Names[EssenceIndex] = Name
    BBar:SetTooltipBox(EssenceIndex, Name)
  end

  BBar:SetTooltipRegion(UB._Name .. ' - Region')

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, EssenceData.TextureWidth, EssenceData.TextureHeight)

  -- Set the texture scale default for Texture Size triggers.
  BBar:SetScaleAllTexture(0, EssenceBGTexture, 1)

  BBar:SetHiddenTexture(0, EssenceBGDarkerTexture, false)
  BBar:SetHiddenTexture(0, EssenceBGTexture, false)
  BBar:SetHiddenTexture(0, EssenceSBar, false)

  BBar:CreateFont('Text', 0)

  -- Set the texture scale for bar offset triggers.
  BBar:SetOffsetTextureFrame(0, BoxMode, 0, 0, 0, 0)

  local EssenceDurationFrame = CreateFrame('Frame')
  EssenceDurationFrame.EssenceBar = UnitBarF
  UnitBarF.EssenceDurationFrame = EssenceDurationFrame

  UnitBarF.Names = Names
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Essencebar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.EssenceBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_UPDATE', self.Update, 'player')

  local EssenceDurationFrame = self.EssenceDurationFrame
  if EssenceDurationFrame then
    if Enable then
      EssenceDurationFrame:SetScript('OnUpdate', EssenceDurationOnUpdate)
    else
      EssenceDurationFrame:SetScript('OnUpdate', nil)
    end
  end
end


