--
-- AltPowerBar.lua
--
-- Displays the alternate power bar

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local OT = Bar.TriggerObjectTypes

local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _, _G =
      _, _G
local GetTime, floor =
      GetTime, floor
local UnitAlternatePowerInfo, UnitPowerBarTimerInfo, UnitAlternatePowerCounterInfo, UnitAlternatePowerTextureInfo =
      UnitAlternatePowerInfo, UnitPowerBarTimerInfo, UnitAlternatePowerCounterInfo, UnitAlternatePowerTextureInfo
local UnitPower, UnitPowerMax, CreateFrame =
      UnitPower, UnitPowerMax, CreateFrame

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
-------------------------------------------------------------------------------
local Display = false
local Update = false

local EventTimerUpdate = 'UNIT_POWER_BAR_TIMER_UPDATE'
local EventPowerBarHide = 'UNIT_POWER_BAR_HIDE'
local EventPowerBarShow = 'UNIT_POWER_BAR_SHOW'

-- Powertype constants
local PowerAlternate = ConvertPowerType['ALTERNATE']
local AltPowerTypeCounter = 4

-- Not all of these are used atm.
local AltColorFill = 2

-- Alt power bar texture constants
local AltPowerBarBox = 1
local AltCounterBarBox = 2
local AltPowerBarTFrame = 1
local AltCounterBarTFrame = 1

local AltPowerSBar = 10
local AltCounterSBar = 20

local ObjectsInfoPower = { -- type, id, additional menu text, textures
  { OT.BackgroundBorder,      1,  '', AltPowerBarTFrame },
  { OT.BackgroundBorderColor, 2,  '', AltPowerBarTFrame },
  { OT.BackgroundBackground,  3,  '', AltPowerBarTFrame },
  { OT.BackgroundColor,       4,  '', AltPowerBarTFrame },
  { OT.BarTexture,            5,  '', AltPowerSBar      },
  { OT.BarColor,              6,  '', AltPowerSBar      },
  { OT.BarOffset,             7,  '', AltPowerBarTFrame },
  { OT.TextFontColor,         8,  ''                    },
  { OT.TextFontOffset,        9,  ''                    },
  { OT.TextFontSize,          10, ''                    },
  { OT.TextFontType,          11, ''                    },
  { OT.TextFontStyle,         12, ''                    },
  { OT.Sound,                 13, ''                    },
}

local ObjectsInfoCounter = { -- type, id, additional menu text, textures
  { OT.BackgroundBorder,      1,  '', AltCounterBarTFrame },
  { OT.BackgroundBorderColor, 2,  '', AltCounterBarTFrame },
  { OT.BackgroundBackground,  3,  '', AltCounterBarTFrame },
  { OT.BackgroundColor,       4,  '', AltCounterBarTFrame },
  { OT.BarTexture,            5,  '', AltCounterSBar      },
  { OT.BarColor,              6,  '', AltCounterSBar      },
  { OT.BarOffset,             7,  '', AltCounterBarTFrame },
  { OT.TextFontColor,         8,  ''                      },
  { OT.TextFontOffset,        9,  ''                      },
  { OT.TextFontSize,          10, ''                      },
  { OT.TextFontType,          11, ''                      },
  { OT.TextFontStyle,         12, ''                      },
  { OT.Sound,                 13, ''                      },
}

local GroupsInfoPower = { -- BoxNumber, Name, ValueTypes
  ValueNames = {
    'whole',   'Power',
    'percent', 'Power (percent)',
    'whole',   'Counter',
    'whole',   'Current Counter',
    'whole',   'Maximum Counter',
    'decimal', 'Counter Time',
    'text',    'Power Name',
    'whole',   'Bar ID',
  },
  {1, 'Power',   ObjectsInfoPower},   -- 1
  {2, 'Counter', ObjectsInfoCounter}, -- 2
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.AltPowerBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Alt power bar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- DoAltTimer
--
-- Handles timers that go along with the alternate power bar
--
-------------------------------------------------------------------------------
local function DoAltTimer(TimeFrame)
  local UnitBarF = TimeFrame.UnitBarF
  local BBar = UnitBarF.BBar
  local PowerName = TimeFrame.PowerName

  local Duration, EndTime, BarID, AuraID = UnitPowerBarTimerInfo('player', 1)
  local TimeLeft = (EndTime or 0) - GetTime()

  if Duration and TimeLeft and TimeLeft > 0 then

    -- Truncate to 1 decimal place
    TimeLeft = TimeLeft - TimeLeft % 0.1

    -- Only update when value in whole seconds changes.
    if TimeLeft ~= TimeFrame.LastTime then
      local CurrValue = TimeFrame.CurrValue
      local MaxValue = TimeFrame.MaxValue
      local Layout = UnitBarF.UnitBar.Layout
      TimeFrame.LastTime = TimeLeft
      TimeFrame.TimeLeft = TimeLeft

      BBar:SetFillTexture(AltCounterBarBox, AltCounterSBar, TimeLeft / Duration)

      if not Layout.HideTextCounter then
        if CurrValue then
          if MaxValue then
            BBar:SetValueFont(AltCounterBarBox, 'countermin', CurrValue, 'countermax', MaxValue, 'powername', PowerName, 'time', TimeLeft)
          else
            BBar:SetValueFont(AltCounterBarBox, 'counter', CurrValue, 'powername', PowerName, 'time', TimeLeft)
          end
        else
          BBar:SetValueFont(AltCounterBarBox, 'time', TimeLeft)
        end
      end
            -- Check triggers
      if Layout.EnableTriggers then
        BBar:SetTriggers('Counter Time', TimeLeft)
        BBar:DoTriggers()
      end
    end
  else
    Main:SetTimer(TimeFrame, nil)
    TimeFrame.Active = false

    BBar:SetValueRawFont(AltCounterBarBox, '')
    BBar:SetSmoothFillMaxTime(AltCounterBarBox, AltCounterSBar, UnitBarF.UnitBar.Layout.SmoothFillMaxTime)
  end
end

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Updates the alt power bar based on color, counters, or just power.
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
--              True bypasses visible and isactive flags.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.AltPowerBar:Update(Event, Unit, PowerToken)

  -------------------
  -- Check Power Type
  -------------------
  local PowerType
  if PowerToken then
    PowerType = ConvertPowerType[PowerToken]
  else
    PowerType = PowerAlternate
  end

  -- Return if power type doesn't match that of alternate
  if PowerType == nil or PowerType ~= PowerAlternate then
    return
  end

  -- Clear text if power bar gets hidden
  -- This needs to be done here since the bar gets hidden on this event by Main.lua
  -- This also needs to be done before the hide check
  local BBar = self.BBar

  if Event == EventPowerBarHide then
    self.AltPowerType = false

    BBar:SetValueRawFont(AltPowerBarBox, '')
    BBar:SetValueRawFont(AltCounterBarBox, '')

    BBar:SetHidden(AltPowerBarBox, AltPowerBarTFrame, false)
    BBar:SetHidden(AltCounterBarBox, AltCounterBarTFrame, true)
    BBar:Display()
  end

  ------------------------------
  -- Set IsActive
  -- IsActive is always set to false
  ------------------------------
  self.IsActive = false

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
  local UB = self.UnitBar
  local Layout = UB.Layout

  local BBar = self.BBar
  local TimeFrame = self.TimeFrame

  local UseMaxValue
  local Testing = Main.UnitBars.Testing
  local TestTypeBoth = false
  local TimeFrameActive = false

  local AltPowerType, MinPower, _, _, _, _, _, _, _, _, PowerName, _, _, BarID = UnitAlternatePowerInfo('player')

  -- Incase the timer event went off first.
  local AltPowerType2 = AltPowerType

  -- For now theres only one timer, so Index is always 1.
  -- BarID and AuraID not used for now
  local Duration, EndTime, BarID, AuraID = UnitPowerBarTimerInfo('player', 1)
  local CurrValue = UnitPower('player', PowerAlternate)
  local MaxValue = UnitPowerMax('player', PowerAlternate)

  -- Check if the counter supports maxvalue
  if AltPowerType == AltPowerTypeCounter then
    UseMaxValue = UnitAlternatePowerCounterInfo('player')
  end

  if Event == nil and AltPowerType == nil then
    AltPowerType = -3
  end

  if Testing then
    local TestMode = UB.TestMode
    local AltPowerTime = TestMode.AltPowerTime
    self.Testing = true

    TestTypeBoth = TestMode.AltTypeBoth
    AltPowerType = TestTypeBoth and -2 or TestMode.AltTypeCounter and AltPowerTypeCounter or -1

    CurrValue = TestMode.AltPower
    MaxValue = TestMode.AltPowerMax
    PowerName = TestMode.AltPowerName
    BarID = TestMode.AltPowerBarID
    UseMaxValue = MaxValue > 0

    -- If test time > 0 then fake time
    if AltPowerTime > 0 then
      TimeFrameActive = true
      TimeFrame.TimeLeft = AltPowerTime

      BBar:SetFillTexture(AltCounterBarBox, AltCounterSBar, AltPowerTime / 60)

      -- Do time here for triggers during testing
      if Layout.EnableTriggers then
        BBar:SetTriggers('Counter Time', AltPowerTime)
        BBar:DoTriggers()
      end
    else
      TimeFrameActive = false
    end

  -- Just switched out of test mode do a clean up.
  elseif self.Testing then
    self.Testing = false
    self.AltPowerType = false

    BBar:SetHidden(AltPowerBarBox, AltPowerBarTFrame, false)
    BBar:SetHidden(AltCounterBarBox, AltCounterBarTFrame, true)
    BBar:Display()
  end

  -------
  -- Draw
  -------
  local BarPower = UB.BarPower
  local HideTextCounter = Layout.HideTextCounter
  local BarCounter = UB.BarCounter
  local HideText = Layout.HideText
  local AltTexture


  if AltPowerType then
    if not Testing then
      TimeFrameActive = TimeFrame.Active or false

      -- Start a timer if there is one
      if Duration and not TimeFrameActive and not Testing then
        TimeFrame.PowerName = PowerName
        TimeFrame.TimeLeft = floor(EndTime - GetTime())
        TimeFrame.LastTime = false
        TimeFrame.Active = true

        -- Turn smooth fill off for timers, since this gives a bad effect to have it on.
        BBar:SetSmoothFillMaxTime(AltCounterBarBox, AltCounterSBar, 0)

        Main:SetTimer(TimeFrame, DoAltTimer, 0.016, 0)
      end
    end

    if self.AltPowerType ~= AltPowerType then
      if AltPowerType then
        self.AltPowerType = AltPowerType

        if AltPowerType ~= AltPowerTypeCounter or TestTypeBoth then
          BBar:SetHidden(AltPowerBarBox, AltPowerBarTFrame, false)

          -- Hide Counter if not testing both
          BBar:SetHidden(AltCounterBarBox, AltCounterBarTFrame, not TestTypeBoth)
        end
        if AltPowerType == AltPowerTypeCounter or TestTypeBoth then
          BBar:SetHidden(AltCounterBarBox, AltCounterBarTFrame, false)

          -- Hide power if not testing both
          BBar:SetHidden(AltPowerBarBox, AltPowerBarTFrame, not TestTypeBoth)
        end
        BBar:Display()
      else
        self.AltPowerType = false

        BBar:SetHidden(AltPowerBarBox, AltPowerBarTFrame, true)
        BBar:SetHidden(AltCounterBarBox, AltCounterBarTFrame, true)
        BBar:Display()
        return
      end
    end

    local UseBarColor = Layout.UseBarColor or false
    local r, g, b, a
    local r1, g1, b1, a1

    -- Use bar color if there is no active alternate power bar.
    if UseBarColor or AltPowerType2 == nil then
      local Color = BarPower.Color
      r, g, b, a = Color.r, Color.g, Color.b, Color.a
      local Color = BarCounter.Color
      r1, g1, b1, a1 = Color.r, Color.g, Color.b, Color.a
    else
      local TimeIndex
      if TimeFrameActive then
        TimeIndex = 1
      end

      a = 1
      AltTexture, r, g, b = UnitAlternatePowerTextureInfo('player', AltColorFill, TimeIndex)
      r1, g1, b1, a1 = r, g, b, 1
    end

    local Value = 0
    if MaxValue > 0 then
      Value = CurrValue / MaxValue
    end

    -- Use standard power
    if AltPowerType ~= AltPowerTypeCounter or TestTypeBoth then
      BBar:SetColorTexture(AltPowerBarBox, AltPowerSBar, r, g, b, a)
      BBar:SetFillTexture(AltPowerBarBox, AltPowerSBar, Value)

      if not HideText then
        BBar:SetValueFont(AltPowerBarBox, 'current', CurrValue, 'maximum', MaxValue, 'powername', PowerName)
      end

      -- Check triggers
      if Layout.EnableTriggers then
        BBar:SetTriggers('Power', CurrValue)
        BBar:SetTriggers('Power (percent)', CurrValue, MaxValue)
        BBar:SetTriggers('Power Name', PowerName)
        BBar:SetTriggers('Bar ID', BarID)
        BBar:DoTriggers()
      end
    end
    -- Use counter or time
    if AltPowerType == AltPowerTypeCounter or TestTypeBoth then
      BBar:SetColorTexture(AltCounterBarBox, AltCounterSBar, r1, g1, b1, a1)

      if UseMaxValue then
        if TimeFrameActive == false then
          BBar:SetFillTexture(AltCounterBarBox, AltCounterSBar, Value)

          if not HideTextCounter then
            BBar:SetValueFont(AltCounterBarBox, 'countermin', CurrValue, 'countermax', MaxValue, 'powername', PowerName)
          end
        else
          if not HideTextCounter then
            BBar:SetValueFont(AltCounterBarBox, 'countermin', CurrValue, 'countermax', MaxValue, 'powername', PowerName, 'time', TimeFrame.TimeLeft)
          end
          TimeFrame.CurrValue = CurrValue
          TimeFrame.MaxValue = MaxValue
        end
      else
        if TimeFrameActive == false then
          BBar:SetFillTexture(AltCounterBarBox, AltCounterSBar, 1)

          if not HideTextCounter then
            BBar:SetValueFont(AltCounterBarBox, 'counter', CurrValue, 'powername', PowerName)
          end
        else
          if not HideTextCounter then
            BBar:SetValueFont(AltCounterBarBox, 'counter', CurrValue, 'powername', PowerName, 'time', TimeFrame.TimeLeft)
          end
          TimeFrame.CurrValue = CurrValue
          TimeFrame.MaxValue = nil
        end
      end
      -- Check triggers
      if Layout.EnableTriggers then
        BBar:SetTriggers('Counter', CurrValue)
        BBar:SetTriggers('Current Counter', CurrValue)
        BBar:SetTriggers('Maximum Counter', MaxValue)
        BBar:SetTriggers('Power Name', PowerName)
        BBar:SetTriggers('Bar ID', BarID)
        BBar:DoTriggers()
      end
    end
  end
end

--*****************************************************************************
--
-- Alt Power bar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetAttr
--
-- Sets different parts of the alt power bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.AltPowerBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then          -- OD.p1             OD.p2                OD.p3
    BBar:SetOptionData('BackgroundPower',   AltPowerBarBox,   AltPowerBarTFrame)
    BBar:SetOptionData('BackgroundCounter', AltCounterBarBox, AltCounterBarTFrame)
    BBar:SetOptionData('BarPower',          AltPowerBarBox,   AltPowerBarTFrame,   AltPowerSBar)
    BBar:SetOptionData('BarCounter',        AltCounterBarBox, AltCounterBarTFrame, AltCounterSBar)

    BBar:SO('TestMode', 'BothRotation', function(v) BBar:SetRotationBar(v) Display = true end)

    BBar:SO('Text', '_Font', function()
      BBar:UpdateFont(AltPowerBarBox)
      BBar:UpdateFont(AltCounterBarBox)
      Update = true
    end)

    BBar:SO('Attributes', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'EnableTriggers',    function(v) BBar:EnableTriggers(v, GroupsInfoPower) end)
    BBar:SO('Layout', 'HideText',          function(v) BBar:SetValueRawFont(AltPowerBarBox, '') Update = true end)
    BBar:SO('Layout', 'ReverseFill',       function(v) BBar:SetFillReverseTexture(AltPowerBarBox, AltPowerSBar, v)
                                                       BBar:SetFillReverseTexture(AltCounterBarBox, AltCounterSBar, v) Update = true end)
    BBar:SO('Layout', 'HideText',          function(v)
      if v then
        BBar:SetValueRawFont(AltPowerBarBox, '')
      else
        Update = true
      end
    end)
    BBar:SO('Layout', 'HideTextCounter',   function(v)
      if v then
        BBar:SetValueRawFont(AltCounterBarBox, '')
      else
        Update = true
      end
    end)
    BBar:SO('Layout', 'SmoothFillMaxTime', function(v) BBar:SetSmoothFillMaxTime(AltPowerBarBox, AltPowerSBar, v)
                                                       BBar:SetSmoothFillMaxTime(AltCounterBarBox, AltCounterSBar, v) end)
    BBar:SO('Layout', 'SmoothFillSpeed',   function(v) BBar:SetFillSpeedTexture(AltPowerBarBox, AltPowerSBar, v)
                                                       BBar:SetFillSpeedTexture(AltCounterBarBox, AltCounterSBar, v) end)

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
    BBar:SO('Bar', 'SyncFillDirection',   function(v, UB, OD) BBar:SyncFillDirectionTexture(OD.p1, OD.p3, v) Update = true end)
    BBar:SO('Bar', 'Clipping',            function(v, UB, OD) BBar:SetClippingTexture(OD.p1, OD.p3, v) Update = true end)
    BBar:SO('Bar', 'FillDirection',       function(v, UB, OD) BBar:SetFillDirectionTexture(OD.p1, OD.p3, v) Update = true end)
    BBar:SO('Bar', 'RotateTexture',       function(v, UB, OD) BBar:SetRotationTexture(OD.p1, OD.p3, v) end)
    BBar:SO('Bar', 'Color',               function(v) Update = true end)
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
-- UnitBarF     The unitbar frame which will contain the alt power bar.
-- UB           Unitbar data.
-- Anchor       Unitbar's anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.AltPowerBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, 2)

  BBar:SetJustifyBar('CORNER')

  -- Create the alt power bar
  BBar:CreateTextureFrame(AltPowerBarBox, AltPowerBarTFrame, 1)
    BBar:CreateTexture(AltPowerBarBox, AltPowerBarTFrame, AltPowerSBar, 'statusbar')

  -- Create the counter bar
  BBar:CreateTextureFrame(AltCounterBarBox, AltCounterBarTFrame, 1)
    BBar:CreateTexture(AltCounterBarBox, AltCounterBarTFrame, AltCounterSBar, 'statusbar')

  -- Create font
  BBar:CreateFont('Text', AltPowerBarBox)
  BBar:CreateFont('Text2', AltCounterBarBox)

  -- Enable tooltip
  BBar:SetTooltipBox(AltPowerBarBox, UB.Name .. ' (Power)')
  BBar:SetTooltipBox(AltCounterBarBox, UB.Name .. ' (Counter)')

  -- Show the textures, but not the frames
  BBar:SetHiddenTexture(AltPowerBarBox, AltPowerSBar, false)
  BBar:SetHiddenTexture(AltCounterBarBox, AltCounterSBar, false)

  BBar:SetFillTexture(AltPowerBarBox, AltPowerSBar, 0)
  BBar:SetFillTexture(AltCounterBarBox, AltCounterSBar, 0)

  -- Set this for triggeer bar offsets
  BBar:SetOffsetTextureFrame(AltPowerBarBox, AltPowerBarTFrame, 0, 0, 0, 0)
  BBar:SetOffsetTextureFrame(AltCounterBarBox, AltCounterBarTFrame, 0, 0, 0, 0)

  local TimeFrame = CreateFrame('Frame')
  TimeFrame.Active = false
  TimeFrame.UnitBarF = UnitBarF

  UnitBarF.TimeFrame = TimeFrame
  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Alt Power bar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.AltPowerBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, EventTimerUpdate, self.Update, 'player')
  Main:RegEventFrame(Enable, self, EventPowerBarHide, self.Update, 'player')
  Main:RegEventFrame(Enable, self, EventPowerBarShow, self.Update, 'player')

  Main:RegEventFrame(Enable, self, 'UNIT_POWER_UPDATE', self.Update, 'player')
  Main:RegEventFrame(Enable, self, 'UNIT_MAXPOWER', self.Update, 'player')
end
