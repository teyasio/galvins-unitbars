--
-- RuneBar.lua
--
-- Displays a runebar similiar to blizzards runebar. The runes can be dragged and dropped
-- to change the order.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.RuneBar = {}
local Main = GUB.Main

-- shared from Main.lua
local LSM = Main.LSM
local CheckEvent = Main.CheckEvent
local MouseOverDesc = Main.MouseOverDesc

-- localize some globals.
local _
local pcall, abs, mod, max, floor, strsub, strupper, strconcat, tostring, pairs, ipairs, type, math, table, select =
      pcall, abs, mod, max, floor, strsub, strupper, strconcat, tostring, pairs, ipairs, type, math, table, select
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.UnitBar         Reference to the unitbar data for the runebar.
-- UnitBarF.OffsetFrame     Offset frame for rotation. This is a parent of RuneF[].
--                          This is used by SetLayoutRune()
-- UnitBarF.Border          Ivisible border thats surrounds the unitbar. This is used
--                          by SetScreenClamp.
-- UnitBarF.ColorAllNames[] List of names to be used in the color all options panel.
-- UnitBarF.RuneF[]         Frame array 1 to 6 that keeps all the death knight runes.
--                          This also contains the frame for the rune.
-- RuneF[].Anchor           Reference to the unitbar anchor for moving.
-- RuneF[].UnitBarF         Reference to the UnitBarF data for dragging/dropping and cooldown.
-- RuneF[].RuneNormalFrame  Frame to hide/show all textures/frames dealing with normal runes.
--                          Child of RuneFrame (RuneF[])
-- RuneF[].RuneCooldownBarFrame
--                          Frame to hide/show all cooldown bars dealing with cooldown bar runes.
--                          Child of RuneFrame (RuneF[])
-- RuneF[].RuneBarTimer     Statusbar to keep track of the cooldown for the rune.  Used in cooldownbar mode.
--                          Child of RuneFrame (RuneF[])
-- RuneF[].TxtFrame         Frame for text. Child of RuneFrame (RuneF[])
-- RuneF[].Txt              Fontstring for the rune.  This is used for the timer text.
-- RuneF[].RuneIcon         The texture containing the rune.
-- RuneF[].RuneBorderFrame  The frame containing the rune border. Child of RuneNormalFrame
-- RuneF[].RuneBorder       The texture containing the rune.
-- RuneF[].Cooldown         The cooldown frame also plays the cooldown animation.
-- RuneF[].Highlight        Rune highlight frame to highlight a rune for dragging/dropping.
-- RuneF[].CooldownBarHighlight
--                          Cooldown bar highlight frame to highlight a bar for dragging/dropping
-- RuneF[].CooldownEdgeFrame
--                          Frame that holds the spark texture in the cooldown bar.
-- RuneF[].CooldownEdge     CooldownEdge texture that is a child of CooldownEdgeFrame

-- RuneF[].RuneTrackingFrame
--                          Used for dragging/dropping.
--
-- RuneF[].RuneLocation     Reference to UnitBar.RuneBar.RuneLocation[Rune] table entry.
--
-- RuneF[].RuneId           Number from 1 to 6. RuneId always matches the index into RuneF[].
-- RuneF[].RuneType         Type of rune based on the rune type constants.
--
-- RuneF[].TooltipName      Tooltip text to display for mouse over when bars are unlocked.
-- RuneF[].TooltipDesc
-- RuneF[].TooltipDesc2     Descriptions under the name for mouse over.
--
-- RuneEnter                When a rune frame is being dragged over another rune frame.  This contains
--                          the number of that frame.  Equals nil if a dragged rune is not touching
--                          another rune.
--
-- MaxRunes                 Currently six.
-- RuneTexture              Contains the locations of the four death knight runes.
-- RuneBorderTexture        Contains the location for the rune border.
-- RuneHighlightTexture     Contains the highlight texture for rune dragging/dropping.
-- CooldownBarHighlightBackdrop
--                          Backdrop for highlight when using cooldown bars.
-- CooldownBarSparkTexture  Contains the spark texture to be used in cooldown bars.
-------------------------------------------------------------------------------
local MouseOverDesc2 = 'Modifier + right mouse button to drag this rune'

-- Rune type constants.
local RuneBlood = 1
local RuneUnholy = 2
local RuneFrost = 3
local RuneDeath = 4

local RuneEnter = nil
local MaxRunes = 6

-- Textures
local RuneBorderTexture = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Ring]]
local RuneHighlightTexture = RuneBorderTexture
local CooldownBarSparkTexture = {
        Texture = [[Interface\CastingBar\UI-CastingBar-Spark]],
        Width = 32, Height = 32,
      }

-- Rune textures
local RuneTexture = {
  [RuneBlood]  = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Blood]],  -- 1 and 2
  [RuneUnholy] = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Unholy]], -- 3 and 4
  [RuneFrost]  = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Frost]],  -- 5 and 6
  [RuneDeath]  = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-Death]]
}

--*****************************************************************************
--
-- Runebar utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetCooldownSize(Cooldown, Size)
--
-- Sets the cooldown frame based on the width and height of its rune frame.
-- This is needed so the cooldown animation fits within the rune texture.
-------------------------------------------------------------------------------
local function SetCooldownSize(Cooldown, Size)
  local CooldownSize = Size * 0.625
  Cooldown:SetWidth(CooldownSize)
  Cooldown:SetHeight(CooldownSize)
end

-------------------------------------------------------------------------------
-- GetRuneName
--
-- Returns a text name of the rune
--
-- Usage: Name = GetRuneName(RuneF, RuneId)
--
-- RuneF               The rune you want to save the name to in its Name field.
--
-- Name                Name of the rune.
-------------------------------------------------------------------------------
local function GetRuneName(RuneF)
  local RuneName = nil
  local RuneNumber = nil
  local RuneId = RuneF.RuneId
  local RuneType = RuneF.RuneType

  if mod(RuneF.RuneId, 2) == 0 then
    RuneNumber = '2'
  else
    RuneNumber = '1'
  end
  if RuneType == RuneBlood then
    RuneName = 'Blood'
  elseif RuneType == RuneUnholy then
    RuneName = 'Unholy'
  elseif RuneType == RuneFrost then
    RuneName = 'Frost'
  elseif RuneType == RuneDeath then
    RuneName = 'Death'
  end

  return ('%s %s'):format(RuneName, RuneNumber)
end

-------------------------------------------------------------------------------
-- SwapRunes
--
-- Swaps the X Y location when not in barmode or swap the bar rune order when in
-- bar mode.
--
-- Usage: SwapRuneLocations(UnitBarF, Rune1, Rune2)
--
-- UnitBarF        The unitbar that contains the runebar that the two runes are being
--                 swapped on.
-- Rune1, Rune2    The two rune frames you want to swap positions.
-------------------------------------------------------------------------------
local function SwapRunes(UnitBarF, Rune1, Rune2)
  local RuneBarOrder = UnitBarF.UnitBar.RuneBarOrder

  local RuneIndex1 = nil
  local RuneIndex2 = nil
  local RuneId1 = Rune1.RuneId
  local RuneId2 = Rune2.RuneId

  -- Only swap the rune order in barmode.
  if UnitBarF.UnitBar.General.BarMode then

    -- Find the runes first.
    for RuneIndex, Rune in ipairs(RuneBarOrder) do
      if RuneIndex1 == nil and RuneId1 == Rune then
        RuneIndex1 = RuneIndex
      elseif RuneIndex2 == nil and RuneId2 == Rune then
        RuneIndex2 = RuneIndex
      end
    end

    -- Swap the runes in rune bar order.
    RuneBarOrder[RuneIndex1], RuneBarOrder[RuneIndex2] = RuneBarOrder[RuneIndex2], RuneBarOrder[RuneIndex1]
  else

    -- Swap the runes by screen location.
    Rune1.RuneLocation.x, Rune2.RuneLocation.x = Rune2.RuneLocation.x, Rune1.RuneLocation.x
    Rune1.RuneLocation.y, Rune2.RuneLocation.y = Rune2.RuneLocation.y, Rune1.RuneLocation.y
  end
end

--*****************************************************************************
--
-- Runebar script functions (script/event)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- RuneOnEnter
--
-- Gets called once when a rune is dragged over another rune.
--
-- RuneF    Frame of the rune you're dragging over
-------------------------------------------------------------------------------
local function RuneOnEnter(RuneF)
  RuneF.Highlight:SetTexture(RuneHighlightTexture)

  local Backdrop = Main:ConvertBackdrop(RuneF.UnitBarF.UnitBar.Background.BackdropSettings)
  Backdrop.bgFile = ''
  RuneF.CooldownBarHighlight:SetBackdrop(Backdrop)
end

-------------------------------------------------------------------------------
-- RuneOnLeave
--
-- Gets called once when a rune has left the rune it was being dragged over.
--
-- RuneF    Frame of the rune you left.
-------------------------------------------------------------------------------
local function RuneOnLeave(RuneF)
  RuneF.Highlight:SetTexture('')
  RuneF.CooldownBarHighlight:SetBackdrop(nil)
end

-------------------------------------------------------------------------------
-- RuneTrackerOnResize
--
-- Keeps track of the location of a rune being dragged to make swapping runes
-- thru drag and drop possible.
-------------------------------------------------------------------------------
local function RuneTrackerOnResize(self, Width, Height)
  local DragRune = self:GetParent()

  -- Do nothing if runeswap is not turned on
  if not DragRune.UnitBarF.UnitBar.General.RuneSwap then
    return
  end
  local RuneF = DragRune.UnitBarF.RuneF
  local RuneTouch = nil
  local RuneId = DragRune.RuneId
  for RuneIndex, RF in ipairs(RuneF) do
    if RuneTouch == nil and RuneId ~= RF.RuneId and MouseIsOver(RF) then
      RuneTouch = RuneIndex
    end
  end

  -- Did the rune get dragged into empty space or off a rune onto another.  If so then the
  -- last rune we entered needs to be cleared.
  if RuneTouch == nil or RuneEnter and RuneTouch ~= RuneEnter then
    if RuneEnter then
      RuneOnLeave(RuneF[RuneEnter])
      RuneEnter = nil
    end
  end

  -- Is the dragged rune on top of another rune?
  if RuneTouch and RuneEnter == nil then
    RuneOnEnter(RuneF[RuneTouch])
    RuneEnter = RuneTouch
  end
end

-------------------------------------------------------------------------------
-- RuneBarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar anchor frame will be moved.
-- Otherwise just the runes will be moved.
-------------------------------------------------------------------------------
local function RuneBarStartMoving(self, Button)

  -- Check to see if shift/alt/control and left button are held down
  if not IsModifierKeyDown() then
    return
  end

  -- Call the base moving function for group or anchor movement.
  if Main.UnitBarStartMoving(self.Anchor, Button) then
    self.UnitBarMoving = true
  else
    if Button == 'RightButton' then

      self.IsMoving = true

      -- Initialize the RuneEnter flag.
      RuneEnter = nil

      -- Set the script for dragging.
      self.RuneTrackingFrame:SetScript('OnSizeChanged', RuneTrackerOnResize)

      -- Start moving the rune.
      self:StartMoving()
    end
  end
end

-------------------------------------------------------------------------------
-- RuneBarStopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
-------------------------------------------------------------------------------
local function RuneBarStopMoving(self, Button)

  local UnitBarF = self.UnitBarF

  -- Call the stop moving base function if there was a group move or anchor move.
  if self.UnitBarMoving then
    self.UnitBarMoving = false
    Main.UnitBarStopMoving(self.Anchor, Button)

  -- Stop moving a rune if it was moving.
  elseif self.IsMoving then
    self.IsMoving = false
    self:StopMovingOrSizing()

    -- Clear the dragging script.
    self.RuneTrackingFrame:SetScript('OnSizeChanged', nil)

    -- Check to see if a rune needs a swap.
    if RuneEnter then
      local RuneF = UnitBarF.RuneF[RuneEnter]
      RuneOnLeave(RuneF)
      SwapRunes(UnitBarF, self, RuneF)

    -- Move the rune if we're not in bar mode.
    elseif not UnitBarF.UnitBar.General.BarMode then
      self.RuneLocation.x, self.RuneLocation.y = Main:RestoreRelativePoints(self)
    end

    -- Update the layout.
    UnitBarF:SetLayout()
  end
end

--*****************************************************************************
--
-- RuneBar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- RuneCooldownOnUpdate
--
-- Displays numeric cooldown text and stops the flash animation.
-------------------------------------------------------------------------------
local function RuneCooldownOnUpdate(self, Elapsed)
  local Start, Duration, RuneReady = GetRuneCooldown(self.RuneId)

  -- Get the amount of time left on cooldown.
  local TimeElapsed = GetTime() - Start
  local RuneTime = Duration - TimeElapsed

  -- Display the time left if cooldowntext is true
  if self.CooldownText then
    if TimeElapsed >= 0 then
      local Seconds = floor(RuneTime)
      if Seconds < self.LastTime then
        self.LastTime = Seconds
        if Seconds < 0 then
          self.Txt:SetText('')
        else
          self.Txt:SetText(Seconds + 1)
        end
      end
    end
  end

  if RuneReady then
    self.OnCooldown = false

    -- Set text to blank in case rune came off cooldown early.
    self.Txt:SetText('')

    -- Hide cooldown flash if HideCooldownFlash is set to true.
    -- Or stop the animation if the rune came off cooldown early.
    if RuneTime > 0 then
      Main:CooldownBarSetTimer(self.RuneCooldownBar, 0, 0, 0)
    end
    if self.CooldownAnimation and (self.HideCooldownFlash or RuneTime > 0) then
      CooldownFrame_SetTimer(self.Cooldown, 0, 0, 0)
    end
    self:SetScript('OnUpdate', nil)
  end
end

-------------------------------------------------------------------------------
-- StartRuneCooldown
--
-- Start a rune cooldown onevent timer.
--
-- Usage: StartRuneCooldown(RuneF)
--
-- RuneF      A cooldown will be started for this runeframe.
-- Start      Start time for the cooldown.
-- Duration   Duration of the cooldown.
-------------------------------------------------------------------------------
local function StartRuneCooldown(RuneF, Start, Duration)

  -- Since blizzard sends us rune events while the rune is on cooldown
  -- We need to ignore them.
  if not RuneF.OnCooldown then
    RuneF.OnCooldown = true

    local Gen = RuneF.UnitBarF.UnitBar.General

    -- Get the options.
    RuneF.HideCooldownFlash = Gen.HideCooldownFlash
    RuneF.CooldownAnimation = Gen.CooldownAnimation
    RuneF.CooldownText = Gen.CooldownText

    RuneF.LastTime = 100

    Main:CooldownBarSetTimer(RuneF.RuneCooldownBar, Start, Duration, 1)

    -- Start a cooldown timer if cooldown animation is true.
    if RuneF.CooldownAnimation then
      CooldownFrame_SetTimer(RuneF.Cooldown, Start, Duration, 1)
    end
    RuneF:SetScript('OnUpdate' , RuneCooldownOnUpdate)
  end
end

-------------------------------------------------------------------------------
-- RefreshRune
--
-- Refreshes a rune based on its setting server side.
--
-- Usage: RefreshRune(RuneF)
--
-- RuneF   Rune frame that is to be refreshed.
-------------------------------------------------------------------------------
local function RefreshRune(RuneF, HideCooldownFlash)
  local RuneType = GetRuneType(RuneF.RuneId)
  RuneF.RuneType = RuneType
  RuneF.RuneIcon:SetTexture(RuneTexture[RuneType])

  -- Update tooltip name.
  RuneF.TooltipName = GetRuneName(RuneF)
end

-------------------------------------------------------------------------------
-- UpdateRuneBar (Update)  [UnitBar assigned function]
--
-- Usage: UpdateRuneBar(Event, ...)
--
-- Event                    Rune type event.  If this is not a rune event
--                          function does nothing.
-- ...        RuneId        RuneId from 1 to 6.
-- ...        RuneReady     True the rune is not on cooldown.  Otherwise false.
-------------------------------------------------------------------------------
function GUB.RuneBar:UpdateRuneBar(Event, ...)

  -- Return if the unitbar is disabled or if the event is not a rune event.
  local EventType = CheckEvent[Event]
  if not self.Enabled or EventType ~= 'runepower' and EventType ~= 'runetype' then
    return
  end

  -- Get the rune frame.
  local RuneId = select(1, ...)
  local RuneF = self.RuneF[RuneId]

  if RuneF then
    if EventType == 'runetype' then

      -- Flip between default and death rune textures.
      RefreshRune(RuneF)

      -- Update the bar color for blood/death runes for cooldownbar mode.
      self:SetAttr(nil, 'color')

    -- Update the rune cooldown.
    elseif EventType == 'runepower' then
      local Start, Duration, RuneReady = GetRuneCooldown(RuneId)
      if not RuneReady then
        StartRuneCooldown(RuneF, Start, Duration)
      end
    end
  end
end

--*****************************************************************************
--
-- Runebar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicksRune (EnableMouseClicks) [UnitBar assigned function]
--
-- This will enable or disbale mouse clicks for the rune icons.
-------------------------------------------------------------------------------
function GUB.RuneBar:EnableMouseClicksRune(Enable)
  for _, RF in ipairs(self.RuneF) do
    RF:EnableMouse(Enable)
  end
end

-------------------------------------------------------------------------------
-- FrameSetScriptRune (FrameSetScript) [UnitBar assigned function]
--
-- Set up script handlers for the Runebar.
-------------------------------------------------------------------------------
function GUB.RuneBar:FrameSetScriptRune(Enable)
  for _, RF in ipairs(self.RuneF) do
    if Enable then
      RF:SetScript('OnMouseDown', RuneBarStartMoving)
      RF:SetScript('OnMouseUp', RuneBarStopMoving)
      RF:SetScript('OnHide', function(self)
                                   RuneBarStopMoving(self)

                                   -- stop any cooldown timers currently running.
                                   Main:CooldownBarSetTimer(self.RuneCooldownBar, 0, 0, 0)
                                   CooldownFrame_SetTimer(self.Cooldown, 0, 0, 0)
                                end)
      RF:SetScript('OnEnter', function(self)
                                Main.UnitBarTooltip(self, false)
                              end)
      RF:SetScript('OnLeave', function(self)
                                Main.UnitBarTooltip(self, true)
                              end)
    else
      RF:SetScript('OnMouseDown', nil)
      RF:SetScript('OnMouseUp', nil)
      RF:SetScript('OnHide', nil)
      RF:SetScript('OnEnter', nil)
      RF:SetScript('OnLeave', nil)
    end
  end
end

-------------------------------------------------------------------------------
-- EnableScreenClampRune (EnableScreenClamp) [UnitBar assigned function]
--
-- Enables or disble screen clamp for runes
-------------------------------------------------------------------------------
function GUB.RuneBar:EnableScreenClampRune(Enable)
  self.Border:SetClampedToScreen(Enable)
end

-------------------------------------------------------------------------------
-- SetAttrRune  (SetAttr) [UnitBar assigned function]
--
-- Sets different parts of the runebar.
--
-- Usage: SetAttrRune(Object, Attr)
--
-- Object       Object being changed:
--               'bg'        for background (Border).
--               'bar'       for forground (StatusBar).
--               'text'      for text (StatusBar.Txt).
--               'frame'     for the frame.
-- Attr         Type of attribute being applied to object:
--               'color'     Color being set to the object.
--               'padding'   Amount of padding set to the object.
--               'texture'   One or more textures set to the object.
--               'font'      Font settings being set to the object.
--               'backdrop'  Backdrop settings being set to the object.
--               'scale'     Scale settings being set to the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.RuneBar:SetAttrRune(Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Background = UB.Background
  local Bar = UB.Bar
  local Padding = Bar.Padding
  local Text = UB.Text
  local FontSettings = Text.FontSettings

  local RuneMode = UB.General.RuneMode
  local RuneF = self.RuneF

  -- Frame.
  if Object == nil or Object == 'frame' then
    if Attr == nil or Attr == 'scale' then
      self.ScaleFrame:SetScale(UB.Other.Scale)
    end
  end

  for _, Rune in ipairs(UB.RuneBarOrder) do
    local RF = RuneF[Rune]

    -- Get rune color based on runetype
    local RuneColorIndex = RF.RuneType * 2 - mod(Rune, 2)

    if RuneMode ~= 'rune' then

      -- Background (Border).
      if Object == nil or Object == 'bg' then
        local RuneCooldownBarFrame = RF.RuneCooldownBarFrame
        local BgColor = nil

        -- Get all color if ColorAll is true.
        if Background.ColorAll then
          BgColor = Background.Color
        else

          -- Get color based on runetype
          BgColor = Background.Color[RuneColorIndex]
        end

        if Attr == nil or Attr == 'backdrop' then
          RuneCooldownBarFrame:SetBackdrop(Main:ConvertBackdrop(Background.BackdropSettings))
          RuneCooldownBarFrame:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
        if Attr == nil or Attr == 'color' then
          RuneCooldownBarFrame:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
      end

      -- Forground (Statusbar).
      if Object == nil or Object == 'bar' then
        local RuneCooldownBar = RF.RuneCooldownBar

        if Attr == nil or Attr == 'texture' then
          RuneCooldownBar:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTexture))
          RuneCooldownBar:GetStatusBarTexture():SetHorizTile(false)
          RuneCooldownBar:GetStatusBarTexture():SetVertTile(false)
          RuneCooldownBar:SetOrientation(Bar.FillDirection)
          RuneCooldownBar:SetRotatesTexture(Bar.RotateTexture)
        end
        if Attr == nil or Attr == 'color' then
          local BarColor = nil

          -- Get all color if ColorAll is true.
          if Bar.ColorAll then
            BarColor = Bar.Color
          else

            -- Get color based on runetype
            BarColor = Bar.Color[RuneColorIndex]
          end
          RuneCooldownBar:SetStatusBarColor(BarColor.r, BarColor.g, BarColor.b, BarColor.a)
        end
        if Attr == nil or Attr == 'padding' then
          RuneCooldownBar:ClearAllPoints()
          RuneCooldownBar:SetPoint('TOPLEFT', Padding.Left , Padding.Top)
          RuneCooldownBar:SetPoint('BOTTOMRIGHT', Padding.Right, Padding.Bottom)
        end
      end
    end

    -- Text (StatusBar.Text).
    if Object == nil or Object == 'text' then
      local Txt = RF.Txt

      if Attr == nil or Attr == 'font' then
        Main:SetFontString(Txt, FontSettings)
      end
      if Attr == nil or Attr == 'color' then
        local TextColor = nil

        -- Get all color if ColorAll is true.
        if Text.ColorAll then
          TextColor = Text.Color
        else

          -- Get color based on runetype
          TextColor = Text.Color[RuneColorIndex]
        end
        Txt:SetTextColor(TextColor.r, TextColor.g, TextColor.b, TextColor.a)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayoutRune (SetLayout) [UnitBar assigned function]
--
-- Sets a runebar with a new layout.
--
-- Usage: SetLayoutRune(UnitBarF)
-------------------------------------------------------------------------------
function GUB.RuneBar:SetLayoutRune()

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = UB.General

  local RuneF = self.RuneF

  local BarMode = Gen.BarMode
  local RuneMode = Gen.RuneMode
  local Padding = Gen.RunePadding
  local RuneSize = Gen.RuneSize
  local DrawEdge = Gen.CooldownDrawEdge
  local BarDrawEdge = Gen.CooldownBarDrawEdge
  local Angle = Gen.BarModeAngle
  local RunePosition = Gen.RunePosition
  local RuneOffsetX = Gen.RuneOffsetX
  local RuneOffsetY = Gen.RuneOffsetY

  local RuneHeight = UB.Bar.RuneHeight
  local RuneWidth = UB.Bar.RuneWidth
  local FillDirection = UB.Bar.FillDirection

  local RuneLocation = UB.RuneLocation
  local x = 0
  local y = 0
  local BorderWidth = 0
  local BorderHeight = 0
  local OffsetFX = 0
  local OffsetFY = 0
  local XOffset = 0
  local YOffset = 0
  local Width = 0
  local Height = 0
  local CooldownBarOffsetX = 0
  local CooldownBarOffsetY = 0

  -- Get the offsets based on angle.
  -- for normal mode
  if RuneMode == 'rune' then
    Width = RuneSize
    Height = RuneSize
  else
    if RuneMode == 'cooldownbar' then

      -- for cooldown bar mode.
      Width = RuneWidth
      Height = RuneHeight
    end

    -- for rune and cooldown bar mode.
    if RuneMode == 'runecooldownbar' then

      -- Get the upper left location of rune location.
      -- Make RuneSize / 2 a negative value since we're looking for upper left.
      local x, y = Main:CalcSetPoint(RunePosition, RuneWidth, RuneHeight, -(RuneSize / 2), RuneSize / 2)

      -- Apply the offsets to the rune location.
      x = x + RuneOffsetX
      y = y + RuneOffsetY

      -- Get the offsets for the cooldown bar frame.
      CooldownBarOffsetX = x < 0 and -x or 0
      CooldownBarOffsetY = y > 0 and -y or 0

      -- Calculate the new size of the rune frame.
      _, _, Width, Height = Main:GetBorder(x, y, RuneSize, RuneSize, 0, 0, RuneWidth, RuneHeight)
    end
  end

  -- Get the offsets for rotation.
  XOffset, YOffset = Main:AngleToOffset(Width + Padding, Height + Padding, Angle)

  -- Set up the rune positions
  for RuneIndex, Rune in ipairs(UB.RuneBarOrder) do
    local RF = RuneF[Rune]
    local RL = RuneLocation[Rune]
    local RuneNormalFrame = RF.RuneNormalFrame
    local RuneCooldownBarFrame = RF.RuneCooldownBarFrame

    -- If barmode is false then get the rune location from saved data or
    -- from x, y.
    if not BarMode then
      if RL.x == '' then

        -- set the floating location if one wasn't found. This should only
        -- happen once when the user switches out of barmode for the first time.
        RL.x = x
        RL.y = y
      else
        x = RL.x
        y = RL.y
      end

      -- Save a reference of the rune location.
      RF.RuneLocation = RL

      -- Set the location in floating mode.
      RF:ClearAllPoints()
      RF:SetPoint('TOPLEFT', x, y)

      -- Save a copy of x ,y for rune mode calculations.
      x1, y1 = x, y

      -- Calculate the next x or y location.
      x = x + XOffset
      y = y + YOffset
    else

      -- Calculate the x and y location before setting the location if angle is > 180.
      if Angle > 180 and RuneIndex > 1 then
        x = x + XOffset
        y = y + YOffset
      end

      -- Set the location in barmode.
      RF:ClearAllPoints()
      RF:SetPoint('TOPLEFT', x, y)

      -- Calculate the border width.
      if XOffset ~= 0 then
        BorderWidth = BorderWidth + abs(XOffset)
        if RuneIndex == 1 then
          BorderWidth = BorderWidth - Padding
        end
      else
        BorderWidth = Width
      end

      -- Calculate the border height.
      if YOffset ~= 0 then
        BorderHeight = BorderHeight + abs(YOffset)
        if RuneIndex == 1 then
          BorderHeight = BorderHeight - Padding
        end
      else
        BorderHeight = Height
      end

      -- Get the x y for the frame offset.
      if x < 0 then
        OffsetFX = abs(x)
      end
      if y > 0 then
        OffsetFY = -y
      end

      -- Calculate the x and y location after setting location if angle <= 180.
      if Angle <= 180 then
        x = x + XOffset
        y = y + YOffset
      end
    end

    -- Rune or Rune with Cooldown bar mode.
    if strsub(RuneMode, 1, 4) == 'rune' then

      -- Hide/Show then cooldownbar.
      if RuneMode == 'rune' then
        RuneCooldownBarFrame:Hide()
        RuneNormalFrame:SetAllPoints(RF)
        RuneNormalFrame:Show()

        -- In rune mode we can set width/height here.
        RF:SetWidth(RuneSize)
        RF:SetHeight(RuneSize)
      end

      -- Update the cooldown size.
      SetCooldownSize(RF.Cooldown, RuneSize)

      -- Set the draw edge.
      if DrawEdge then
        RF.Cooldown:SetDrawEdge(1)
      else
        RF.Cooldown:SetDrawEdge(0)
      end
    end

    -- Cooldown mode with or without rune.
    if RuneMode == 'cooldownbar' or RuneMode == 'runecooldownbar' then

      -- Hide show the normal rune.
      if RuneMode == 'cooldownbar' then
        RuneNormalFrame:Hide()
        RuneCooldownBarFrame:SetAllPoints(RF)
        RuneCooldownBarFrame:Show()

        -- in cooldownbar mode we can set width/height here.
        RF:SetWidth(RuneWidth)
        RF:SetHeight(RuneHeight)
      else

        -- cooldown bar frame.
        RuneCooldownBarFrame:ClearAllPoints()
        RuneCooldownBarFrame:SetPoint('TOPLEFT', CooldownBarOffsetX, CooldownBarOffsetY)
        RuneCooldownBarFrame:SetWidth(RuneWidth)
        RuneCooldownBarFrame:SetHeight(RuneHeight)
        RuneCooldownBarFrame:Show()

        -- Set the rune based off the cooldown bar frame position.
        RuneNormalFrame:ClearAllPoints()
        RuneNormalFrame:SetPoint('CENTER', RuneCooldownBarFrame, RunePosition, RuneOffsetX, RuneOffsetY)
        RuneNormalFrame:SetWidth(RuneSize)
        RuneNormalFrame:SetHeight(RuneSize)
        RuneNormalFrame:Show()

        RF:SetWidth(Width)
        RF:SetHeight(Height)
      end

      -- Show the cooldown bar
      RF.RuneCooldownBarFrame:Show()

      -- Set the cooldownbar edge frame based on fill direction.
      -- 0.57142 is a scale calculation to be sure the spark is always the right size.
      if BarDrawEdge then
        if FillDirection == 'HORIZONTAL' then
          RF.CooldownEdge:SetTexCoord(0, 1, 0, 1)
          Main:SetCooldownBarEdgeFrame(RF.RuneCooldownBar, RF.CooldownEdgeFrame, FillDirection,
                                               CooldownBarSparkTexture.Width, RuneHeight / 0.57142)
        else
          RF.CooldownEdge:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
          Main:SetCooldownBarEdgeFrame(RF.RuneCooldownBar, RF.CooldownEdgeFrame, FillDirection,
                                               RuneWidth / 0.57142, CooldownBarSparkTexture.Height)
        end
      else
        Main:SetCooldownBarEdgeFrame(RF.RuneCooldownBar, nil)
      end
    end

    -- Refresh the rune texture incase it changed server side after the reload ui.
    RefreshRune(RF)
  end

  local Border = self.Border
  Border:ClearAllPoints()
  Border:SetPoint('TOPLEFT', 0, 0)

  -- Calculate the offsets for the offset frame for when not in bar mode.
  -- Also get the width/height for the border.
  -- The border gets offsetted, but then we need to shift the offset frame in the opposite direction.
  -- So the runes appear in the correct location on the screen.
  if not BarMode then
    x, y, BorderWidth, BorderHeight = Main:GetBorder(RuneLocation[1].x, RuneLocation[1].y, Width, Height,
                                                             RuneLocation[2].x, RuneLocation[2].y, Width, Height,
                                                             RuneLocation[3].x, RuneLocation[3].y, Width, Height,
                                                             RuneLocation[4].x, RuneLocation[4].y, Width, Height,
                                                             RuneLocation[5].x, RuneLocation[5].y, Width, Height,
                                                             RuneLocation[6].x, RuneLocation[6].y, Width, Height)
    OffsetFX = -x
    OffsetFY = -y
    Border:SetPoint('TOPLEFT', x, y)
  end

  -- Set the size of the border.
  Border:SetWidth(BorderWidth)
  Border:SetHeight(BorderHeight)

  -- Set the offsets to the offset frame.
  local OffsetFrame = self.OffsetFrame
  OffsetFrame:ClearAllPoints()
  OffsetFrame:SetPoint('TOPLEFT', OffsetFX, OffsetFY)
  OffsetFrame:SetWidth(1)
  OffsetFrame:SetHeight(1)

    -- Set all attributes.
  self:SetAttr(nil, nil)

  -- Save size data to self (UnitBarF).
  self.Width = BorderWidth
  self.Height = BorderHeight
end

-------------------------------------------------------------------------------
-- CreateRune
--
-- Creates one of the 4 different death knight runes.
--
-- Usage: RuneFrame = CreateRune(RuneType, RF)
--
-- RuneType      One of the four different death knight runes.
-- RF            RuneFrame to put the created rune into.
-------------------------------------------------------------------------------
local function CreateRune(RuneType, RuneF)

  -- Create a RuneNormalFrame for easy hiding/showing of runes.
  local RuneNormalFrame = CreateFrame('Frame', nil, RuneF)
  RuneNormalFrame:SetFrameLevel(RuneNormalFrame:GetFrameLevel() + 5)

  -- Create the text frame so that it can work with cooldown bars or rune textures.
  -- Set the frame level so its higher than the RuneBorderFrame.
  local TxtFrame = CreateFrame('Frame', nil, RuneF)
  TxtFrame:SetAllPoints(RuneF)
  TxtFrame:SetFrameLevel(TxtFrame:GetFrameLevel() + 10)
  local Txt = TxtFrame:CreateFontString(nil, 'OVERLAY')

  -- Create the rune icon for the rune.
  local RuneIcon = RuneNormalFrame:CreateTexture(nil, 'BACKGROUND')
  RuneIcon:SetTexture(RuneTexture[RuneType])
  RuneIcon:SetAllPoints(RuneNormalFrame)

  -- Create the cooldown frame for the rune.
  local Cooldown = CreateFrame('Cooldown', nil, RuneNormalFrame)
  Cooldown:SetPoint('CENTER', RuneIcon, 'CENTER', 0, 1)

  -- Create the border frame for the border that gets drawn ontop of the cooldown frame.
  local RuneBorderFrame = CreateFrame('Frame', nil, RuneNormalFrame)
  RuneBorderFrame:SetFrameLevel(Cooldown:GetFrameLevel() + 1)
  RuneBorderFrame:SetAllPoints(RuneNormalFrame)

  -- Create the border frame for the rune.
  local RuneBorder = RuneBorderFrame:CreateTexture(nil, 'OVERLAY')
  RuneBorder:SetTexture(RuneBorderTexture)
  RuneBorder:SetAllPoints(RuneBorderFrame)
  RuneBorder:SetVertexColor(0.6, 0.6, 0.6, 1)

  -- Create the highlight texture.
  local Highlight = RuneNormalFrame:CreateTexture(nil, 'OVERLAY')
  Highlight:SetPoint('TOPLEFT', -5, 5)
  Highlight:SetPoint('BOTTOMRIGHT', 5, -5)

  -- Create the RuneCooldownBarFrame for easy hiding/showing of the cooldown bars.
  local RuneCooldownBarFrame = CreateFrame('Frame', nil, RuneF)

  -- Create a statusbar texture for the cooldown bar timer.
  local RuneCooldownBar = CreateFrame('StatusBar', nil, RuneCooldownBarFrame)
  RuneCooldownBar:SetMinMaxValues(0, 1)
  RuneCooldownBar:SetValue(0)

  -- Create the cooldown edge frame
  local CooldownEdgeFrame = CreateFrame('Frame', nil, RuneCooldownBarFrame)

  -- Create the cooldown edge texture
  local CooldownEdge = CooldownEdgeFrame:CreateTexture(nil, 'OVERLAY')
  CooldownEdge:SetTexture(CooldownBarSparkTexture.Texture)
  CooldownEdge:SetBlendMode('ADD')
  CooldownEdge:SetAllPoints(CooldownEdgeFrame)

  -- Create the highlight border for the cooldown bar
  local CooldownBarHighlight = CreateFrame('Frame', nil, RuneCooldownBarFrame)
  CooldownBarHighlight:SetPoint('TOPLEFT', -3, 3)
  CooldownBarHighlight:SetPoint('BOTTOMRIGHT', 3, -3)

  -- Save the rune type to RuneF.
  RuneF.RuneType = RuneType

  -- Save the frames and textures.
  RuneF.RuneNormalFrame = RuneNormalFrame
  RuneF.TxtFrame = TxtFrame
  RuneF.Txt = Txt
  RuneF.RuneIcon = RuneIcon
  RuneF.Cooldown = Cooldown
  RuneF.RuneBorderFrame = RuneBorderFrame
  RuneF.RuneBorder = RuneBorder
  RuneF.Highlight = Highlight
  RuneF.CooldownBarHighlight = CooldownBarHighlight
  RuneF.RuneCooldownBarFrame = RuneCooldownBarFrame
  RuneF.RuneCooldownBar = RuneCooldownBar
  RuneF.CooldownEdgeFrame = CooldownEdgeFrame
  RuneF.CooldownEdge = CooldownEdge
end

-------------------------------------------------------------------------------
-- CreateRuneBar
--
-- Creates the main rune bar frame that contains the death knight runes
--
-- Usage: GUB.RuneBar:CreateRuneBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the rune bar.
-- UB           Unitbar data.
-- Anchor       The unitbar's anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.RuneBar:CreateRuneBar(UnitBarF, UB, Anchor, ScaleFrame)

  local Border = CreateFrame('Frame', nil, ScaleFrame)

  -- Make the border frame top when clicked.
  Border:SetToplevel(true)

  -- Create the offset frame.
  local OffsetFrame = CreateFrame('Frame', nil, Border)

  local RuneF = {}
  local ColorAllNames = {}

  -- Create the rune frames for the runebar.
  for Rune = 1, MaxRunes do
    local RF = CreateFrame('Frame', nil, OffsetFrame)

    -- Save the rune number as a runeId
    RF.RuneId = Rune

    -- Create the tracking frame.
    local RuneTrackingFrame =  CreateFrame('Frame', nil, RF)
    RuneTrackingFrame:SetPoint('BOTTOMLEFT', Anchor, 'BOTTOMLEFT')
    RuneTrackingFrame:SetPoint('TOPRIGHT', RF, 'TOPLEFT')
    RF.RuneTrackingFrame = RuneTrackingFrame

    -- Create the rune. This math converts rune into runetype.
    CreateRune(math.ceil(Rune / 2), RF)

    -- Make the rune movable.
    RF:SetMovable(true)

    -- Save a reference of the anchor for moving.
    RF.Anchor = Anchor

    -- Save a reference of UnitBarF for dragging/dropping.
    RF.UnitBarF = UnitBarF

    -- Set the text for tooltips/options.
    local Name = GetRuneName(RF)
    RF.TooltipName = Name
    RF.TooltipDesc = MouseOverDesc
    RF.TooltipDesc2 = MouseOverDesc2
    ColorAllNames[RF.RuneId] = Name

    RuneF[Rune] = RF
  end

  -- Add death rune name for options.
  ColorAllNames[7] = 'Death 1'
  ColorAllNames[8] = 'Death 2'

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the rune frames and border.
  UnitBarF.Border = Border
  UnitBarF.OffsetFrame = OffsetFrame
  UnitBarF.RuneF = RuneF
end

