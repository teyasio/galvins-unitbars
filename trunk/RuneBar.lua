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

-- shared from Main.lua
local CheckEvent = GUB.UnitBars.CheckEvent
local MouseOverDesc = GUB.UnitBars.MouseOverDesc

-- localize some globals.
local _
local pcall, abs, mod, floor, strconcat, tostring, pairs, ipairs, type, math, table, select =
      pcall, abs, mod, floor, strconcat, tostring, pairs, ipairs, type, math, table, select
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, GetComboPoints

-------------------------------------------------------------------------------
-- Locals
--
-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.UnitBar         Reference to the unitbar data for the runebar.
-- UnitBarF.OffsetFrame     Offset frame for rotation. This is a parent of RuneF[].
--                          This is used by SetLayoutRune()
-- UnitBarF.ColorAllNames[] List of names to be used in the color all options panel.
-- UnitBarF.RuneF[]         Frame array 1 to 6 that keeps all the death knight runes.
--                          This also contains the frame for the rune.
-- RuneF[Rune].Anchor       Reference to the unitbar anchor for moving.
-- RuneF[Rune].UnitBarF     Reference to the UnitBarF data for dragging/dropping and cooldown.
-- RuneF[Rune].RuneIcon     The texture containing the rune.
-- RuneF[Rune].RuneBorderFrame
--                          The frame containing the rune border.
-- RuneF[Rune].RuneBorder   The texture containing the rune.
-- RuneF[Rune].Cooldown     The cooldown frame also plays the cooldown animation.
-- RuneF[Rune].Highlight    Rune highlight frame to highlight a rune for dragging/dropping.
-- RuneF[Rune].RuneTrackingFrame
--                          Used for dragging/dropping.
--
-- RuneF[Rune].RuneLocation
--                          Reference to UnitBar.RuneBar.RuneLocation[Rune] table entry.
--
-- RuneF[Rune].RuneId       Number from 1 to 6. RuneId always matches the index into RuneF[].
-- RuneF[Rune].RuneType     Type of rune based on the rune type constants.
--
-- RuneF[Rune].TooltipName  Tooltip text to display for mouse over when bars are unlocked.
-- RuneF[Rune].TooltipDesc
-- RuneF[Rune].TooltipDesc2 Descriptions under the name for mouse over.
--
-- RuneEnter                When a rune frame is being dragged over another rune frame.  This contains
--                          the number of that frame.  Equals nil if a dragged rune is not touching
--                          another rune.
--
-- MaxRunes                 Currently six.
-- RuneTexture              Contains the locations of the four death knight runes.
-- RuneBorderTexture        Contains the location for the rune border.
-- RuneHighlightTexture     Contains the high light texture for rune dragging/dropping.
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
local RuneBorderTexture = 'Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Ring'
local RuneHighlightTexture = RuneBorderTexture

-- Rune textures
local RuneTexture = {
  [RuneBlood]  = 'Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood',  -- 1 and 2
  [RuneUnholy] = 'Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Unholy', -- 3 and 4
  [RuneFrost]  = 'Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Frost',  -- 5 and 6
  [RuneDeath]  = 'Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Death'
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
  if RuneType == RuneBlood or RuneType == RuneDeath then
    RuneName = 'Blood'
  elseif RuneType == RuneUnholy then
    RuneName = 'Unholy'
  elseif RuneType == RuneFrost then
    RuneName = 'Frost'
  end

  return ('%s %s'):format(RuneName, RuneNumber)
end

-------------------------------------------------------------------------------
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
  if GUB.UnitBars.UnitBarStartMoving(self.Anchor, Button) then
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
    GUB.UnitBars.UnitBarStopMoving(self.Anchor, Button)

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
      self.RuneLocation.x, self.RuneLocation.y = GUB.UnitBars:RestoreRelativePoints(self)
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
end

-------------------------------------------------------------------------------
-- UpdateRuneBar (Update)  [UnitBar assigned function]
--
-- Usage: UpdateRuneBar(Event, ...)
--
-- Event                    Rune type event.  If this is not a rune event
--                          function does nothing.
-- ...        RuneId        RuneId from 1 to 8. 7 and 8 are not used.
-- ...        RuneReady     True the rune is not on cooldown.  Otherwise false.
-------------------------------------------------------------------------------
function GUB.RuneBar:UpdateRuneBar(Event, ...)

  -- Do nothing if the event is not a rune event.
  local EventType = CheckEvent[Event]
  if not self.Enabled or EventType ~= 'runepower' and EventType ~= 'runetype' then
    return
  end

  -- Get the rune frame.
  local RuneId = select(1, ...)
  local RuneF = self.RuneF[RuneId]

  if RuneF then
    if EventType == 'runetype' then

      -- Flip between blood and death rune textures.
      RefreshRune(RuneF)

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
      RF:SetScript('OnHide', RuneBarStopMoving)
      RF:SetScript('OnEnter', function(self)
                                GUB.UnitBars.UnitBarTooltip(self, false)
                              end)
      RF:SetScript('OnLeave', function(self)
                                GUB.UnitBars.UnitBarTooltip(self, true)
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
  for _, RF in ipairs(self.RuneF) do

    -- Prevent runes from being moved off screen.
    RF:SetClampedToScreen(Enable)
  end
end

-------------------------------------------------------------------------------
-- SetAttrRune  (SetAttr) [UnitBar assigned function]
--
-- Sets different parts of the runebar.
--
-- Usage: SetAttrRune(Object, Attr)
--
-- Object       Object being changed:
--               'frame' for the frame.
--               'text' for text (StatusBar.Txt).
-- Attr         Type of attribute being applied to object:
--               'scale'   Scale settings being set to the object.
--               'color'     Color being set to the object.
--               'font'      Font settings being set to the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.RuneBar:SetAttrRune(Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Text = UB.Text

  -- Frame.
  if Object == nil or Object == 'frame' then
    if Attr == nil or Attr == 'scale' then
      self.ScaleFrame:SetScale(UB.Other.Scale)
    end
  end

  local FontSettings = Text.FontSettings
  for _, RF in pairs(self.RuneF) do
    local RuneId = RF.RuneId

    -- Text (StatusBar.Text).
    if Object == nil or Object == 'text' then
      local Txt = RF.Txt

      if Attr == nil or Attr == 'font' then
        GUB.UnitBars:SetFontString(Txt, FontSettings)
      end
      if Attr == nil or Attr == 'color' then
        local TextColor = nil

        -- Get all color if ColorAll is true.
        if Text.ColorAll then
          TextColor = Text.Color
        else
          TextColor = Text.Color[RuneId]
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
  local Padding = Gen.RunePadding
  local RuneSize = Gen.RuneSize
  local DrawEdge = Gen.CooldownDrawEdge
  local Angle = Gen.BarModeAngle

  local RuneLocation = UB.RuneLocation
  local x = 0
  local y = 0
  local BorderWidth = 0
  local BorderHeight = 0
  local OffsetFX = 0
  local OffsetFY = 0

  -- Get the offsets based on angle.
  local XOffset, YOffset = GUB.UnitBars:AngleToOffset(RuneSize + Padding, RuneSize + Padding, Angle)

  -- Set up the rune positions
  for RuneIndex, Rune in ipairs(UB.RuneBarOrder) do
    local RF = RuneF[Rune]
    local RL = RuneLocation[Rune]

    -- Set the draw edge.
    if DrawEdge then
      RF.Cooldown:SetDrawEdge(1)
    else
      RF.Cooldown:SetDrawEdge(0)
    end

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
        BorderWidth = RuneSize
      end

      -- Calculate the border height.
      if YOffset ~= 0 then
        BorderHeight = BorderHeight + abs(YOffset)
        if RuneIndex == 1 then
          BorderHeight = BorderHeight - Padding
        end
      else
        BorderHeight = RuneSize
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

    RF:SetWidth(RuneSize)
    RF:SetHeight(RuneSize)

    -- Update the cooldown size.
    SetCooldownSize(RF.Cooldown, RuneSize)

    -- Refresh the rune texture incase it changed server side after the reload ui.
    RefreshRune(RF)
  end

  -- Set the x, y location off the offset frame.
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

  -- Create the rune icon for the rune.
  local RuneIcon = RuneF:CreateTexture(nil, 'ARTWORK')
  RuneIcon:SetTexture(RuneTexture[RuneType])
  RuneIcon:SetAllPoints(RuneF)

  -- Create the cooldown frame for the rune.
  local Cooldown = CreateFrame('Cooldown', nil, RuneF)
  Cooldown:SetPoint('CENTER', RuneIcon, 'CENTER', 0, 1)

  -- Create the border frame for the border that gets drawn ontop of the cooldown frame.
  -- Also create the cooldown text.
  local RuneBorderFrame = CreateFrame('Frame', nil, RuneF)
  local Txt = RuneBorderFrame:CreateFontString(nil, 'OVERLAY')
  RuneBorderFrame:SetFrameLevel(Cooldown:GetFrameLevel() + 1)
  RuneBorderFrame:SetAllPoints(RuneF)

  -- Create the border frame for the rune.
  local RuneBorder = RuneBorderFrame:CreateTexture(nil, 'OVERLAY')
  RuneBorder:SetTexture(RuneBorderTexture)
  RuneBorder:SetAllPoints(RuneBorderFrame)
  RuneBorder:SetVertexColor(0.6, 0.6, 0.6, 1)

  -- Create the highlight texture.
  local Highlight = RuneF:CreateTexture(nil, 'ARTWORK')
  Highlight:SetPoint('TOPLEFT', -5, 5)
  Highlight:SetPoint('BOTTOMRIGHT', 5, -5)

  -- Save the rune type to RuneF.
  RuneF.RuneType = RuneType

  -- Save the frames and textures.
  RuneF.RuneIcon = RuneIcon
  RuneF.Cooldown = Cooldown
  RuneF.RuneBorderFrame = RuneBorderFrame
  RuneF.RuneBorder = RuneBorder
  RuneF.Txt = Txt
  RuneF.Highlight = Highlight
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

  -- Create the offset frame.
  local OffsetFrame = CreateFrame('Frame', nil, ScaleFrame)

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

    -- Make the rune top when clicked.
    RF:SetToplevel(true)

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

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the rune frames.
  UnitBarF.OffsetFrame = OffsetFrame
  UnitBarF.RuneF = RuneF
end


