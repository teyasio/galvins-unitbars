--
-- ShardBar.lua
--
-- Displays the Warlock shard bar.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.ShardBar = {}
local Main = GUB.Main

-- shared from Main.lua
local LSM = Main.LSM
local PowerTypeToNumber = Main.PowerTypeToNumber
local MouseOverDesc = Main.MouseOverDesc

-- localize some globals.
local _
local bitband,  bitbxor,  bitbor,  bitlshift =
      bit.band, bit.bxor, bit.bor, bit.lshift
local pcall, abs, mod, max, floor, strsub, strupper, strconcat, tostring, pairs, ipairs, type, math, table, select =
      pcall, abs, mod, max, floor, strsub, strupper, strconcat, tostring, pairs, ipairs, type, math, table, select
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType
local GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetPrimaryTalentTree, GetEclipseDirection, GetInventoryItemID

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
--                                   This is used for rotation offset in SetLayoutShard()
-- UnitBarF.SoulShardF[]             (SoulShardFrame) Frame array containing all 3 soul shards. This also
--                                   contains the frame of the soul shard.
-- SoulShardF[].SoulShardFrame       Frame. Parent of SoulShard, SoulShardBox, and SoulShardBoxFrame.
-- SoulShardF[].SoulShard            The texture containing the soul shard.
-- SoulShardF[].SoulShardBox         Statusbar used in BoxMode only. This is a child of SoulShardFrame
-- SoulShardF[].SoulShardDarkFrame   Parent of SoulShardDark
-- SoulShardF[].SoulShardDark        This is the texture for the soul shard dark.
-- SoulShardF[].SoulShardBoxFrame    Visible frame border for the SoulShardBox. This is a child of OffsetFrame.
--
-- SoulShardF[].Dark                 True then the soul shard is dark, otherwise it's lit.
-- SoulShardF[].FadeOut              Animation group for fadeout for the soul shard before hiding
--                                   This group is a child of the SoulShardFrame.
-- SoulShardF[].FadeOutA             Animation that contains the fade out.  This is a child
--                                   of FadeOut
-- SoulShardF[].Dark                 True then the soul shard is not lit.  True soul shard is lit.
--
-- SoulShardBoxFrame.Anchor          Anchor reference for moving.  Used in box mode.
-- SoulShardBoxFrame.TooltipName     Name of this soul shard for mouse over tooltips. Used in box mode.
-- SoulShardBoxFrame.TooltipDesc     Description to show with the name for mouse over tooltips.
--                                   Used in box mode.
--
-- SoulShardTexture                  Contains all the data for the soul shards texture.
--   Texture                         Path name to the texture file.
--   Width                           Width of the texture.
--   Height                          Height of the texture.
--   Left, Right, Top, Bottom        Coordinates inside the main texture for the texture we need.
-- SoulShardDarkColor                Used to make the light colored soulshard texture dark.
--
-- LastSoulShards                    Keeps track of change in the soulshard bar.
--
-- NOTE: SoulShard bar has two modes.  In BoxMode the soulshard bar is broken into 3 statusbars.
--       This works just like the combobar.  When not normal mode.  The bar uses textures instead.
-------------------------------------------------------------------------------
local MaxSoulShards = 3

-- Powertype constants
local PowerShard = PowerTypeToNumber['SOUL_SHARDS']

local LastSoulShards = nil

local SoulShardTexture = {
        Texture = [[Interface\PlayerFrame\UI-WarlockShard]],
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
  if Main.UnitBarStartMoving(self.Anchor, Button) then
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
    Main.UnitBarStopMoving(self.Anchor, Button)
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
  local FadeOutTime = nil

  if not FinishFadeOut then
    FadeOutTime = ShardBarF.UnitBar.General.ShardFadeOutTime
  end

  for ShardIndex, SSF in ipairs(ShardBarF.SoulShardF) do
    local FadeOut = SSF.FadeOut

    -- If FinishFadeOut is true then stop any fadout animation and darken the soul shard.
    if FinishFadeOut then
      if SSF.Dark then
        Main:AnimationFadeOut(FadeOut, 'finish', function() SSF:Hide() end)
      end

    -- Light a soul shard based on SoulShards.
    elseif SSF.Dark and ShardIndex <= SoulShards then
      if FadeOutTime > 0 then

        -- Finish animation if it's playing.
        Main:AnimationFadeOut(FadeOut, 'finish')
      end
      SSF:Show()
      SSF.Dark = false

    -- Darken a shard based on SoulShards.
    elseif not SSF.Dark and ShardIndex > SoulShards then
      if FadeOutTime > 0 then

        -- Fade out the soul shard then hide it.
        Main:AnimationFadeOut(FadeOut, 'start', function() SSF:Hide() end)
      else
        SSF:Hide()
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
-- usage: UpdateShardBar(Event)
--
-- Event         'change' then the bar will only get updated if there is a change.
-------------------------------------------------------------------------------
function GUB.ShardBar:UpdateShardBar(Event)
  local SoulShards = UnitPower('player', PowerShard)

  -- Return if no change.
  if Event == 'change' and SoulShards == LastSoulShards then
    return
  end

  LastSoulShards = SoulShards

  UpdateSoulShards(self, SoulShards)

    -- Set this IsActive flag
  self.IsActive = SoulShards > 0

  -- Do a status check for active status.
  self:StatusCheck()
end

-------------------------------------------------------------------------------
-- CancelAnimationShard (CancelAnimation) [UnitBar assigned function]
--
-- Usage: CancelAnimationShard()
--
-- Cancels all animation playing in the shard bar.
-------------------------------------------------------------------------------
function GUB.ShardBar:CancelAnimationShard()
  UpdateSoulShards(self, 0, true)
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
  local Border = self.Border

  -- Disable mouse clicks for border and SoulShardBoxFrame
  Border:EnableMouse(false)
  for _, SSF in ipairs(self.SoulShardF) do
    SSF.SoulShardBoxFrame:EnableMouse(false)
  end

  -- Check for boxmode
  if self.UnitBar.General.BoxMode then
    for _, SSF in ipairs(self.SoulShardF) do
      SSF.SoulShardBoxFrame:EnableMouse(Enable)
    end
  else
    self.Border:EnableMouse(Enable)
  end
end

-------------------------------------------------------------------------------
-- FrameSetScriptShard (FrameSetScript) [UnitBar assigned function]
--
-- Set up script handlers for the Shardbar.
-------------------------------------------------------------------------------
function GUB.ShardBar:FrameSetScriptShard(Enable)
  local Border = self.Border
  local ShardBarF = self

  local function FrameSetScript(Frame, Enable)
    if Enable then
      Frame:SetScript('OnMouseDown', ShardBarStartMoving)
      Frame:SetScript('OnMouseUp', ShardBarStopMoving)
      Frame:SetScript('OnHide', function(self)
                                   ShardBarStopMoving(self)
                                end)
      Frame:SetScript('OnEnter', function(self)
                                    Main.UnitBarTooltip(self, false)
                                 end)
      Frame:SetScript('OnLeave', function(self)
                                    Main.UnitBarTooltip(self, true)
                                 end)
    else
      Frame:SetScript('OnMouseDown', nil)
      Frame:SetScript('OnMouseUp', nil)
      Frame:SetScript('OnHide', nil)
      Frame:SetScript('OnEnter', nil)
      Frame:SetScript('OnLeave', nil)
    end
  end

  -- Check for boxmode
  if self.UnitBar.General.BoxMode then

    -- Disable the normal mode scripts.
    FrameSetScript(Border, false)

    -- Set the new scripts for each shard box.
    for _, SSF in ipairs(self.SoulShardF) do
      FrameSetScript(SSF.SoulShardBoxFrame, Enable)
    end
  else

    -- Disable the box mode scripts.
    for _, SSF in ipairs(self.SoulShardF) do
      FrameSetScript(SSF.SoulShardBoxFrame, false)
    end

    -- Set the new script for normal mode.
    FrameSetScript(Border, Enable)
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
-- Attr         Type of attribute being applied to object:
--               'color'     Color being set to the object.
--               'backdrop'  Backdrop settings being set to the object.
--               'scale'     Scale settings being set to the object.
--               'size'    Size being set to the object.
--               'padding' Amount of padding set to the object.
--               'texture' One or more textures set to the object.
--               'strata'    Frame strata for the object.
--
-- NOTE: To apply one attribute to all objects. Object must be nil.
--       To apply all attributes to one object. Attr must be nil.
--       To apply all attributes to all objects both must be nil.
-------------------------------------------------------------------------------
function GUB.ShardBar:SetAttrShard(Object, Attr)

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Border = self.Border

  -- Frame.
  if Object == nil or Object == 'frame' then
    if Attr == nil or Attr == 'scale' then
      self.ScaleFrame:SetScale(UB.Other.Scale)
    end
    if Attr == nil or Attr == 'strata' then
      self.Anchor:SetFrameStrata(UB.Other.FrameStrata)
    end
  end

  -- Check if we're in boxmode.
  if UB.General.BoxMode then
    local Bar = UB.Bar
    local Background = UB.Background
    local Padding = Bar.Padding

    -- Remove the border backdrop.
    Border:SetBackdrop(nil)

    for ShardIndex, SSF in ipairs(self.SoulShardF) do

      -- Background (Border).
      if Object == nil or Object == 'bg' then
        local BgColor = nil

        -- Get all color if ColorAll is true.
        if Background.ColorAll then
          BgColor = Background.Color
        else
          BgColor = Background.Color[ShardIndex]
        end

        local SoulShardBoxFrame = SSF.SoulShardBoxFrame

        if Attr == nil or Attr == 'backdrop' then
          SoulShardBoxFrame:SetBackdrop(Main:ConvertBackdrop(UB.Background.BackdropSettings))
          SoulShardBoxFrame:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
        if Attr == nil or Attr == 'color' then
          SoulShardBoxFrame:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
        end
      end

      -- Forground (Statusbar).
      if Object == nil or Object == 'bar' then
        local SoulShardBox = SSF.SoulShardBox

        if Attr == nil or Attr == 'texture' then
          SoulShardBox:SetStatusBarTexture(LSM:Fetch('statusbar', Bar.StatusBarTexture))
          SoulShardBox:GetStatusBarTexture():SetHorizTile(false)
          SoulShardBox:GetStatusBarTexture():SetVertTile(false)
          SoulShardBox:SetOrientation(Bar.FillDirection)
          SoulShardBox:SetRotatesTexture(Bar.RotateTexture)
        end
        if Attr == nil or Attr == 'color' then
          local BarColor = nil

          -- Get all color if ColorAll is true.
          if Bar.ColorAll then
            BarColor = Bar.Color
          else
            BarColor = Bar.Color[ShardIndex]
          end
          SoulShardBox:SetStatusBarColor(BarColor.r, BarColor.g, BarColor.b, BarColor.a)
        end
        if Attr == nil or Attr == 'padding' then
          SoulShardBox:ClearAllPoints()
          SoulShardBox:SetPoint('TOPLEFT', Padding.Left , Padding.Top)
          SoulShardBox:SetPoint('BOTTOMRIGHT', Padding.Right, Padding.Bottom)
        end
        if Attr == nil or Attr == 'size' then
          SSF:SetWidth(Bar.BoxWidth)
          SSF:SetHeight(Bar.BoxHeight)
        end
      end
    end
  else

    -- Else we're in normal bar mode.

    -- Background (Border).
    if Object == nil or Object == 'bg' then
      local BgColor = UB.Background.Color

      if Attr == nil or Attr == 'backdrop' then
        Border:SetBackdrop(Main:ConvertBackdrop(UB.Background.BackdropSettings))
        Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
      if Attr == nil or Attr == 'color' then
        Border:SetBackdropColor(BgColor.r, BgColor.g, BgColor.b, BgColor.a)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetLayoutShard (SetLayout) [UnitBar assigned function]
--
-- Set a shardbar to a new layout
--
-- Usage: SetLayoutShard()
-------------------------------------------------------------------------------
function GUB.ShardBar:SetLayoutShard()

  -- Get the unitbar data.
  local UB = self.UnitBar
  local Gen = self.UnitBar.General

  local Anchor = self.Anchor

  local BoxMode = Gen.BoxMode
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

  local BoxWidth = UB.Bar.BoxWidth
  local BoxHeight = UB.Bar.BoxHeight

  if BoxMode then
    -- Get the offsets based on angle for boxmode.
    XOffset, YOffset = Main:AngleToOffset(BoxWidth + Padding, BoxHeight + Padding, Angle)
  end

  for ShardIndex, SSF in ipairs(self.SoulShardF) do

    -- Set the duration of the fade out.
    SSF.FadeOutA:SetDuration(FadeOutTime)

    -- Check to see if we're in Boxmode
    if BoxMode then


      -- Hide the textures.
      SSF.SoulShard:Hide()
      SSF.SoulShardDark:Hide()

      -- Show the soul shard boxes.
      SSF.SoulShardBoxFrame:Show()
      SSF.SoulShardBox:Show()

      -- Set the Shard min/max values.
      local SoulShardBox = SSF.SoulShardBox
      SoulShardBox:SetMinMaxValues(0, 1)
      SoulShardBox:SetValue(1)

      -- Calculate the x and y location before setting the location if angle is > 180.
      if Angle > 180 and ShardIndex > 1 then
        x = x + XOffset
        y = y + YOffset
      end

      -- Set the location of the shard box.
      SSF:ClearAllPoints()
      SSF:SetPoint('TOPLEFT', x, y)
      SSF.SoulShardBoxFrame:SetAllPoints(SSF)

      -- Calculate the border width
      if XOffset == 0 then
        BorderWidth = BoxWidth
      end
      if YOffset == 0 then
        BorderHeight = BoxHeight
      end
    else

    -----------------------------------
    -- Normal mode
    -----------------------------------
      local SoulShard = SSF.SoulShard
      local SoulShardDarkFrame = SSF.SoulShardDarkFrame
      local SoulShardDark = SSF.SoulShardDark

      -- Hide the soul shard box frame.
      SSF.SoulShardBoxFrame:Hide()
      SSF.SoulShardBox:Hide()

      -- Show the textures.
      SoulShard:Show()
      SoulShardDark:Show()

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
      SoulShardDarkFrame:SetWidth(Width)
      SoulShardDarkFrame:SetHeight(Height)

      -- Center the soul shard.
      SoulShard:ClearAllPoints()
      SoulShard:SetPoint('CENTER', 0, 0)
      SoulShardDark:ClearAllPoints()
      SoulShardDark:SetPoint('CENTER', 0, 0)

      -- Set the scale of the soul shard texture.
      local ScaleX = Width * ShardScale
      local ScaleY = Height * ShardScale
      SoulShard:SetWidth(ScaleX)
      SoulShard:SetHeight(ScaleY)
      SoulShardDark:SetWidth(ScaleX)
      SoulShardDark:SetHeight(ScaleY)

      -- Get the offsets based on angle.
      XOffset, YOffset = Main:AngleToOffset(Width + Padding, Height + Padding, Angle)

      -- Calculate the x and y location before setting the location if angle is > 180.
      if Angle > 180 and ShardIndex > 1 then
        x = x + XOffset
        y = y + YOffset
      end

      -- Set the location of the soul shard.
      SSF:ClearAllPoints()
      SSF:SetPoint('TOPLEFT', x, y)
      SoulShardDarkFrame:SetAllPoints(SSF)

      -- Calculate the border width.
      if XOffset == 0  and BorderWidth < Width then
        BorderWidth = Width
      end

      -- Calculate the border height.
      if YOffset == 0 and BorderHeight < Height then
        BorderHeight = Height
      end
    end

    -- Calculate the border width for both types of shard bars.
    if XOffset ~= 0 then
      BorderWidth = BorderWidth + abs(XOffset)
      if ShardIndex == 1 then
        BorderWidth = BorderWidth - Padding
      end
    end

    -- Calculate the border height for both types of shard bars.
    if YOffset ~= 0 then
      BorderHeight = BorderHeight + abs(YOffset)
      if ShardIndex == 1 then
        BorderHeight = BorderHeight - Padding
      end
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

  local Border = self.Border
  Border:ClearAllPoints()
  Border:SetPoint('TOPLEFT', 0, 0)

  -- Set the size of the border.
  Border:SetWidth(BorderWidth)
  Border:SetHeight(BorderHeight)

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

  local ColorAllNames = {}
  local SoulShardF = {}

  for ShardIndex = 1, MaxSoulShards do

    -- Create a soul shard frame.
    local SoulShardFrame = CreateFrame('Frame', nil, OffsetFrame)

    -- Create a soul shard texture.
    local SoulShard = SoulShardFrame:CreateTexture(nil, 'OVERLAY')
    SoulShard:SetTexture(SoulShardTexture.Texture)
    SoulShard:SetTexCoord(SoulShardTexture.Left, SoulShardTexture.Right, SoulShardTexture.Top, SoulShardTexture.Bottom)

    -- Create a dark soul shard frame.
    local SoulShardDarkFrame = CreateFrame('Frame', nil, OffsetFrame)

    -- Create a dark soul shard textre.
    local SoulShardDark = SoulShardDarkFrame:CreateTexture(nil, 'ARTWORK')
    SoulShardDark:SetTexture(SoulShardTexture.Texture)
    SoulShardDark:SetTexCoord(SoulShardTexture.Left, SoulShardTexture.Right, SoulShardTexture.Top, SoulShardTexture.Bottom)
    SoulShardDark:SetVertexColor(SoulShardDarkColor.r, SoulShardDarkColor.g, SoulShardDarkColor.b, SoulShardDarkColor.a)

    -- Create the SoulShardBoxFrame
    local SoulShardBoxFrame = CreateFrame('Frame', nil, OffsetFrame)

    -- Create a soul shard statusbar texture.
    local SoulShardBox = CreateFrame('StatusBar', nil, SoulShardFrame)

    -- Create an animation for fade out.
    local FadeOut = SoulShardFrame:CreateAnimationGroup()
    local FadeOutA = FadeOut:CreateAnimation('Alpha')

    -- Set the animation group values.
    FadeOut:SetLooping('NONE')
    FadeOutA:SetChange(-1)
    FadeOutA:SetOrder(1)

    -- Set the soul shard to dark.
    SoulShardFrame.Dark = true
    SoulShardFrame:Hide()

    -- Save the animation.
    SoulShardFrame.FadeOut = FadeOut
    SoulShardFrame.FadeOutA = FadeOutA

    -- Save the normal and dark shard.
    SoulShardFrame.SoulShard = SoulShard
    SoulShardFrame.SoulShardDarkFrame = SoulShardDarkFrame
    SoulShardFrame.SoulShardDark = SoulShardDark
    SoulShardFrame.SoulShardBoxFrame = SoulShardBoxFrame
    SoulShardFrame.SoulShardBox = SoulShardBox

    -- Save a reference to the anchor for moving in box mode.
    SoulShardBoxFrame.Anchor = Anchor

    -- Save the name for tooltips for box mode.
    local Name = strconcat('Shard ', ShardIndex)
    SoulShardBoxFrame.TooltipName = Name
    SoulShardBoxFrame.TooltipDesc = MouseOverDesc
    ColorAllNames[ShardIndex] = Name

    SoulShardF[ShardIndex] = SoulShardFrame
  end

  -- Save the name for tooltips.
  Border.TooltipName = UB.Name
  Border.TooltipDesc = MouseOverDesc

  -- Save a reference to the anchor for moving.
  Border.Anchor = Anchor

  -- Save the color all names.
  UnitBarF.ColorAllNames = ColorAllNames

  -- Save the offsetframe and Border and soul shards.
  UnitBarF.Border = Border
  UnitBarF.OffsetFrame = OffsetFrame
  UnitBarF.SoulShardF = SoulShardF
end

