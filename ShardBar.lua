--
-- ShardBar.lua
--
-- Displays the Warlock shard bar.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.ShardBar = {}

-- shared from Main.lua
local CheckPowerType = GUB.UnitBars.CheckPowerType
local CheckEvent = GUB.UnitBars.CheckEvent
local PowerTypeToNumber = GUB.UnitBars.PowerTypeToNumber
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

-- UnitBarF = UnitBarsF[]
--
-- Border.TooltipName                Tooltip text to display for mouse over when bars are unlocked.
-- Border.TooltipDesc                Description under the name for mouse over.
-- UnitBarF.UnitBar                  Reference to the unitbar data for the shard bar.
-- UnitBarF.Border                   Border frame for the shard bar. This is a parent of
--                                   OffsetFrame.
-- UnitBarF.OffsetFrame              Offset frame this is a parent of SoulShardF[]
--                                   This is used for rotation offset in SetShardBarLayout()
-- UnitBarF.SoulShardF[]             Frame array containing all 3 soul shards. This also
--                                   contains the frame of the soul shard.
-- SoulShardF[].SoulShard            Normal soul shard.
-- SoulShardF[].SoulShardDark        Darkened soul shard.
-- SoulShardF[].Dark                 True then the soul shard is dark, otherwise it's lit.
-- SoulShardTexture                  Contains all the data for the soul shards texture.
--   Texture                         Path name to the texture file.
--   Width                           Width of the texture.
--   Height                          Height of the texture.
--   Left, Right, Top, Bottom        Coordinates inside the main texture for the texture we need.
-- SoulShardDarkColor                Used to make the light colored soulshard texture dark.
-------------------------------------------------------------------------------
local MaxSoulShards = 3

-- Powertype constants
local PowerShard = PowerTypeToNumber['SOUL_SHARDS']

local SoulShardTexture = {
        Texture = 'Interface\\PlayerFrame\\UI-WarlockShard',
        Width = 17, Height = 16,
        Left = 0.01562500, Right = 0.28125000, Top = 0.00781250, Bottom = 0.13281250
      }
local SoulShardDarkColor = {r = 0.25, g = 0.25, b = 0.25, a = 1}

--*****************************************************************************
--
-- Shardbar script functions (script/event)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- ShardBarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar parent frame will be moved.
-- Otherwise just the shardbar will be moved.
-------------------------------------------------------------------------------
local function ShardBarStartMoving(self, Button)

  -- Call the base moving function for group or anchor movement.
  if GUB.UnitBars.UnitBarStartMoving(self.Anchor, Button) then
    self.UnitBarMoving = true
  end
end

-------------------------------------------------------------------------------
-- ShardBarStopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
-------------------------------------------------------------------------------
local function ShardBarStopMoving(self, Button)

  -- Call the stop moving base function if there was a group move or anchor move.
  if self.UnitBarMoving then
    self.UnitBarMoving = false
    GUB.UnitBars.UnitBarStopMoving(self.Anchor, Button)
  end
end

--*****************************************************************************
--
-- Shardbar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UpdateSoulShards
--
-- Lights or darkens the soul shards
--
-- Usage: UpdateSoulShards(ShardBarF, SoulShards, FinishFadeOut)
--
-- ShardBarF        SoulShard bar containing shards to update.
-- SoulShards       Updates the soul shards based on the number to light up.
-- FinishFadeOut    If true then any fadeout animation currently playing
--                  will be stopped.
--                  If nil or false then does nothing.
-------------------------------------------------------------------------------
local function UpdateSoulShards(ShardBarF, SoulShards, FinishFadeOut)
  local FadeOutTime = ShardBarF.UnitBar.General.ShardFadeOutTime

  for ShardIndex, SSF in ipairs(ShardBarF.SoulShardF) do
    local FadeOut = SSF.FadeOut
    local SoulShard = SSF.SoulShard

    -- If FinishFadeOut is true then stop any fadout animation and darken the soul shard.
    if FinishFadeOut then
      if SSF.Dark then
        GUB.UnitBars:AnimationFadeOut(FadeOut, 'finish')
        SoulShard:SetAlpha(0)
      end

    -- Light a soul shard based on SoulShards.
    elseif SSF.Dark and ShardIndex <= SoulShards then
      if FadeOutTime > 0 then

        -- Finish animation if it's playing.
        GUB.UnitBars:AnimationFadeOut(FadeOut, 'finish')
      end
      SoulShard:SetAlpha(1)
      SSF.Dark = false

    -- Darken a shard based on SoulShards.
    elseif not SSF.Dark and ShardIndex > SoulShards then
      if FadeOutTime > 0 then

        -- Fade out the soul shard then hide it.
        GUB.UnitBars:AnimationFadeOut(FadeOut, 'start', function() SoulShard:SetAlpha(0) end)
      else
        SoulShard:SetAlpha(0)
      end
      SSF.Dark = true
    end
  end
end

-------------------------------------------------------------------------------
-- UpdateShardBar (Update) [UnitBar assigned function]
--
-- Update the number of shards of the player
--
-- usage: UpdateShardBar(Event, PowerType)
--
-- Event                If nil no event check will be done.
-- PowerType            If not equal to 'SOUL_SHARDS' then nothing will be updated
--                      unless it's nil
-------------------------------------------------------------------------------
function GUB.ShardBar:UpdateShardBar(Event, PowerType)

  -- If PowerType is nil then set it to soul shard power type.
  if PowerType == nil then
    PowerType = 'SOUL_SHARDS'
  end

  -- Return if the unitbar is disabled, or event is not a power event, or its not soul shard.
  if not self.Enabled or Event ~= nil and CheckEvent[Event] ~= 'power' or
     CheckPowerType[PowerType] ~= 'shards' then
    return
  end

  local SoulShards = UnitPower('player', PowerShard)

  UpdateSoulShards(self, SoulShards)

    -- Set this IsActive flag
  self.IsActive = SoulShards > 0

  -- Do a status check for active status.
  self:StatusCheck()

end

--*****************************************************************************
--
-- Shardbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicksShard (EnableMouseClicks) [UnitBar assigned function]
--
-- This will enable or disbable mouse clicks for the shard bar.
-------------------------------------------------------------------------------
function GUB.ShardBar:EnableMouseClicksShard(Enable)
  self.Border:EnableMouse(Enable)
end

-------------------------------------------------------------------------------
-- FrameSetScriptShard (FrameSetScript) [UnitBar assigned function]
--
-- Set up script handlers for the Shardbar.
-------------------------------------------------------------------------------
function GUB.ShardBar:FrameSetScriptShard(Enable)
  local Border = self.Border
  local ShardBarF = self
  if Enable then
    Border:SetScript('OnMouseDown', ShardBarStartMoving)
    Border:SetScript('OnMouseUp', ShardBarStopMoving)
    Border:SetScript('OnHide', function(self)
                                 ShardBarStopMoving(self)

                                 -- Cancel any fadeout animations currently playing.
                                 UpdateSoulShards(ShardBarF, 0, true)
                               end)
    Border:SetScript('OnEnter', function(self)
                                  GUB.UnitBars.UnitBarTooltip(self, false)
                                end)
    Border:SetScript('OnLeave', function(self)
                                  GUB.UnitBars.UnitBarTooltip(self, true)
                                end)
  else
    Border:SetScript('OnMouseDown', nil)
    Border:SetScript('OnMouseUp', nil)
    Border:SetScript('OnHide', nil)
    Border:SetScript('OnEnter', nil)
    Border:SetScript('OnLeave', nil)
  end
end

-------------------------------------------------------------------------------
-- EnableScreenClampShard (EnableScreenClamp) [UnitBar assigned function]
--
-- Enables or disble screen clamp for the shard bar.
-------------------------------------------------------------------------------
function GUB.ShardBar:EnableScreenClampShard(Enable)
  self.Border:SetClampedToScreen(Enable)
end

-------------------------------------------------------------------------------
-- SetAttrShard  (SetAttr) [UnitBar assigned function]
--
-- Sets different parts of the shardbar.
--
-- Usage: SetAttrShard(Object, Attr)
--
-- Object       Object being changed:
--               'bg' for background (Border).
--               'bar' for forground (StatusBar).
--               'frame' for the frame.
--
--               'color'     Color being set to the object.
--               'backdrop'  Backdrop settings being set to the object.
--               'scale'     Scale settings being set to the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.ShardBar:SetAttrShard(Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar

  -- Frame.
  if Object == nil or Object == 'frame' then
    if Attr == nil or Attr == 'scale' then
      self.ScaleFrame:SetScale(UB.Other.Scale)
    end
  end

  -- Background (Border).
  if Object == nil or Object == 'bg' then
    local Border = self.Border

    local BgColor = UB.Background.Color

    if Attr == nil or Attr == 'backdrop' then
      Border:SetBackdrop(GUB.UnitBars:ConvertBackdrop(UB.Background.BackdropSettings))
      Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
    end
    if Attr == nil or Attr == 'color' then
      Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
    end
  end
end

-------------------------------------------------------------------------------
-- SetShardBarLayout
--
-- Set a shardbar to a new layout
--
-- Usage: SetShardBarLayout(UnitBarF)
--
-- UnitBarF     Unitbar that contains the shard bar that is being setup.
-------------------------------------------------------------------------------
function GUB.ShardBar:SetShardBarLayout(UnitBarF)

  -- Get the unitbar data.
  local Gen = UnitBarF.UnitBar.General

  local Anchor = UnitBarF.Anchor

  local ShardSize = Gen.ShardSize
  local ShardScale = Gen.ShardScale
  local Padding = Gen.ShardPadding
  local FadeOutTime = Gen.ShardFadeOutTime
  local Angle = Gen.ShardAngle
  local x = 0
  local y = 0
  local XOffset = 0
  local YOffset = 0
  local BorderWidth = 0
  local BorderHeight = 0
  local OffsetFX = 0
  local OffsetFY = 0

  for ShardIndex, SSF in ipairs(UnitBarF.SoulShardF) do

    -- Set the duration of the fade out.
    SSF.FadeOutA:SetDuration(FadeOutTime)

    -- Calculate the size of the soul shard.
    local Width = SoulShardTexture.Width
    local Height = SoulShardTexture.Height
    local Scale = 0

    -- Scale by width if the bar is vertical.
    if Angle == 180 or Angle == 360 then
      Scale = ShardSize / Width
    else

      -- Scale by height
      Scale = ShardSize / Height
    end
    Width = Width * Scale
    Height = Height * Scale

    -- Set the width and height of the soul shard.
    SSF:SetWidth(Width)
    SSF:SetHeight(Height)

    -- Center the soul shard.
    local SoulShard = SSF.SoulShard
    SoulShard:ClearAllPoints()
    SoulShard:SetPoint('CENTER', 0, 0)

    -- Set the scale of the soul shard texture.
    local ScaleX = Width * ShardScale
    local ScaleY = Height * ShardScale
    SoulShard:SetWidth(ScaleX)
    SoulShard:SetHeight(ScaleY)

    -- Center the dark soul shard.
    local SoulShardDark = SSF.SoulShardDark
    SoulShardDark:ClearAllPoints()
    SoulShardDark:SetPoint('CENTER', 0, 0)

    -- Set the scale of the dark soul shard.
    SoulShardDark:SetWidth(ScaleX)
    SoulShardDark:SetHeight(ScaleY)

    -- Get the offsets based on angle.
    XOffset, YOffset = GUB.UnitBars:AngleToOffset(Width + Padding, Height + Padding, Angle)

    -- Calculate the x and y location before setting the location if angle is > 180.
    if Angle > 180 and ShardIndex > 1 then
      x = x + XOffset
      y = y + YOffset
    end

    -- Set the location of the soul shard.
    SSF:ClearAllPoints()
    SSF:SetPoint('TOPLEFT', x, y)

    -- Calculate the border width.
    if XOffset ~= 0 then
      BorderWidth = BorderWidth + abs(XOffset)
      if ShardIndex == 1 then
        BorderWidth = BorderWidth - Padding
      end
    elseif BorderWidth < Width then
      BorderWidth = Width
    end

    -- Calculate the border height.
    if YOffset ~= 0 then
      BorderHeight = BorderHeight + abs(YOffset)
      if ShardIndex == 1 then
        BorderHeight = BorderHeight - Padding
      end
    elseif BorderHeight < Height then
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

  local Border = UnitBarF.Border
  Border:ClearAllPoints()
  Border:SetPoint('TOPLEFT', 0, 0)

  -- Set the size of the border.
  Border:SetWidth(BorderWidth)
  Border:SetHeight(BorderHeight)

  -- Set the x, y location off the offset frame.
  local OffsetFrame = UnitBarF.OffsetFrame
  OffsetFrame:ClearAllPoints()
  OffsetFrame:SetPoint('TOPLEFT', OffsetFX, OffsetFY)
  OffsetFrame:SetWidth(1)
  OffsetFrame:SetHeight(1)

  -- Set all attributes.
  UnitBarF:SetAttr(nil, nil)

  -- Save size data to UnitBarF.
  UnitBarF.Width = BorderWidth
  UnitBarF.Height = BorderHeight
end



-------------------------------------------------------------------------------
-- CreateShardBar
--
-- Usage: GUB.ShardBar:CreateShardBar(UnitBarF, UB, Anchor, ScaleFrame)
--
-- UnitBarF     The unitbar frame which will contain the shard bar.
-- UB           Unitbar data.
-- Anchor       The unitbars anchor.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.ShardBar:CreateShardBar(UnitBarF, UB, Anchor, ScaleFrame)

  local Border = CreateFrame('Frame', nil, ScaleFrame)

  -- Make the border frame top when clicked.
  Border:SetToplevel(true)

  -- Create the offset frame.
  local OffsetFrame = CreateFrame('Frame', nil, Border)

  local SoulShardF = {}

  for ShardIndex = 1, MaxSoulShards do

    -- Create a soul shard frame.
    local SoulShardFrame = CreateFrame('Frame', nil, OffsetFrame)

    -- Create a soul shard texture.
    local SoulShard = SoulShardFrame:CreateTexture(nil, 'OVERLAY')
    SoulShard:SetTexture(SoulShardTexture.Texture)
    SoulShard:SetTexCoord(SoulShardTexture.Left, SoulShardTexture.Right, SoulShardTexture.Top, SoulShardTexture.Bottom)

    -- Create a dark soul shard textre.
    local SoulShardDark = SoulShardFrame:CreateTexture(nil, 'ARTWORK')
    SoulShardDark:SetTexture(SoulShardTexture.Texture)
    SoulShardDark:SetTexCoord(SoulShardTexture.Left, SoulShardTexture.Right, SoulShardTexture.Top, SoulShardTexture.Bottom)
    SoulShardDark:SetVertexColor(SoulShardDarkColor.r, SoulShardDarkColor.g, SoulShardDarkColor.b, SoulShardDarkColor.a)

    -- Create an animation for fade out.
    local FadeOut = SoulShard:CreateAnimationGroup()
    local FadeOutA = FadeOut:CreateAnimation('Alpha')

    -- Set the animation group values.
    FadeOut:SetLooping('NONE')
    FadeOutA:SetChange(-1)
    FadeOutA:SetOrder(1)

    -- Set the soul shard to dark.
    SoulShardFrame.Dark = true
    SoulShard:SetAlpha(0)

    -- Save the animation.
    SoulShardFrame.FadeOut = FadeOut
    SoulShardFrame.FadeOutA = FadeOutA

    -- Save the normal and dark shard.
    SoulShardFrame.SoulShard = SoulShard
    SoulShardFrame.SoulShardDark = SoulShardDark

    SoulShardF[ShardIndex] = SoulShardFrame
  end

  -- Save the name for tooltips.
  Border.TooltipName = UB.Name
  Border.TooltipDesc = MouseOverDesc

  -- Save a reference to the anchor for moving.
  Border.Anchor = Anchor

  -- Save the offsetframe and Border and soul shards.
  UnitBarF.Border = Border
  UnitBarF.OffsetFrame = OffsetFrame
  UnitBarF.SoulShardF = SoulShardF
end

