--
-- Bar.lua
--
-- Allows bars to be coded easily.  Currently used by ComboBar, HolyBar, and ShardBar.
--
-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local LSM = GUB.LSM

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin
local strfind, strsub, strupper, strlower, format, strconcat, strmatch, gsub, tonumber =
      strfind, strsub, strupper, strlower, format, strconcat, strmatch, gsub, tonumber
local pcall, pairs, ipairs, type, select, next, print, sort =
      pcall, pairs, ipairs, type, select, next, print, sort
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, GetSpellInfo, GetTalentInfo, PlaySound =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, GetSpellInfo, GetTalentInfo, PlaySound
local GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable

-------------------------------------------------------------------------------
-- Locals
--
-- BarDB                             Bar Database. All functions are called thru this except for CreateBar().
-- BarDB.ParentFrame                 The whole bar will be a child of this frame.
-- BarDB.TotalBoxes                  Total number of boxes the bar was created with.
-- BarDB.NumBoxes                    Current number of boxes in the bar.
-- BarDB.Border                      Visible or invisible border around the bar. Child of ParentFrame.
--                                   This is also used for handling mouse events for the whole bar.
-- BarDB.OffsetFrame                 Child of ParentFrame.  This is used to help with rotation
-- BarDB.Padding                     Amount of distance between the boxes and the bars border.
-- BarDB.Angle                       Angle in degrees in which way the bar will be displayed.
-- BarDB.FadeOutTime                 Time in seconds to fade a box out to hide it.  If zero fadeout is disabled.
-- BarDB.BoxScale                    Change the scale of all the boxes in the bar.
-- BarDB.BoxWidth                    Width of all the boxes.
-- BarDB.BoxHeight                   Height of all the boxes.
-- BarDB.TextFrame                   TextFrame for one or more fontstrings.  Only exists after CreateFontString()
--                                   The TextFrame is always set one higher than the highest frame level.
--                                   Also the TextFrame will always be the same size as the BarDB.Border.
-- BarDB.TopFrameLevel               Contains the highest frame level in use by the bar.
--
-- BarDB.BoxFrame[]                  An array of frames containing textures or statusbars or both.
--
-- BoxFrame[]                        Invisible frame containing the textures/statusbars.
--                                   Child of OffsetFrame. This is also used to scale the box.
-- BoxFrame[].Padding                Amount of distance from the current box and next one.
-- BoxFrame[].Border                 Visible border surrounding the box.  Child of BoxFrame. Border changes size
--                                   based on BoxFrame.
-- BoxFrame[].TextureFrame[]         An array of frames holding the textures/statusbar for the box.
-- TextureFrame[]                    Invisible frame containing the textures/statusbars.  Child of BoxFrame.
--                                   This can be used to change the scale of a texture or hide/show it.
-- TextureFrame[].FillDirection      'HORIZONTAL' or 'VERTICAL'
-- TextureFrame[].RotateTexture      Statusbar only.  If true then texture is rotated 90 degrees.
--                                   If false no rotation takes place.
-- TextureFrame[].TexLeft
-- TextureFrame[].TexRight
-- TextureFrame[].TexTop
-- TextureFrame[].TexBottom          Texcoordinates for the texture.
--
-- TextureFrame[].Type               Contains the type of texture.
--                                   'statusbar'  then its a statusbar.
--                                   'texture'    contains a texture.
-- TextureFrame[].Texture            Statusbar or texture.  Child of TextureFrame.
-- Texture.Width                     Texture only. Width of the texture frame and texture.
-- Texture.Height                    Texture only. Height of the texture frame and texture.
-- Texture.FadeOutTime               Time in seconds to fade out a texture.  If 0 then this frame doesn't have a fadeout.
-- Texture.FadeOut                   Fadeout animation group for TextureFrame
-- Texture.FadeOutA                  Fadeout animation
-- Texture.Hidden                    If true the frame is hidden otherwise it's visible.
--
-- Bar frame layout:
--
-- ParentFrame
--   Border
--   OffsetFrame
--     BoxFrame
--       Border
--       TextureFrame
--         Texture (frame or texture)
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Creating a bar
--
-- Functions list in order to create a bar.
--
-- CreateBar()
-- CreateBoxTexture()
--
-- If you have textures then you need to call these.
--   SetTexture()
--   SetTexCoord()    If the texture file has multiple textures.
--   SetTexureSize()
--   SetBoxSize()     Without this nothing will show.
--
-- After adding all your textures.  Then you can do CreateFontString if you need one.  The fontstring
-- will always be on top unless you do another CreateBoxTexture.  So this should always be done when
-- you're sure no more
-- textures wil be added
--
-- Once you've done that then to make the bar display on screen.
--   ShowTextureFrame()
--   ShowTexture()
--   Display()
--
-- For enable/disable of the bar.
--   SetEnableMouse(nil or BoxNumber)   A bar always has a border even if no backdrop was set to
--      it.  This function will allow the bar to be dragged/dropped by clicking on the border. if
--      a box number is used then that box has to be clicked on to drag/drop the whole bar.
--
--   SetEnableMouseClicks(nil or BoxNumber)  If set to nil then the bar's border won't respond
--      to mouse clicks or mousing over for tooltips.  If a box number is used then that box
--      wont respond to mouse clicks or mousing over for tooltips.
--
-- Hiding and showing of the border.
--   HideBorder/ShowBorder(nil or BoxNumber)  So in this mod. Most bars have two modes, box mode and texture mode.
--      Sometimes we want a visible border in bar mode then hide it in box mode.  Nil means hide the border
--      surrounding the whole bar.  If not nil then it hides or shows the border for that box instead.
--      One a border/box is hidden it can't interact with mouse or be dragged/dropped.
--
-- There are more functions to use depending on what you're doing.
-------------------------------------------------------------------------------
local BarDB = {}

--*****************************************************************************
--
-- Bar script functions (script/event)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- BarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar parent frame will be moved.
-- Otherwise just the bar will be moved.
-------------------------------------------------------------------------------
local function BarStartMoving(self, Button)

  -- Call the base moving function for group or anchor movement.
  if Main.UnitBarStartMoving(self.Anchor, Button) then
    self.UnitBarMoving = true
  end
end

-------------------------------------------------------------------------------
-- BarStopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
-------------------------------------------------------------------------------
local function BarStopMoving(self, Button)

  -- Call the stop moving base function if there was a group move or anchor move.
  if self.UnitBarMoving then
    self.UnitBarMoving = false
    Main.UnitBarStopMoving(self.Anchor, Button)
  end
end

--*****************************************************************************
--
-- Bar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Display
--
-- Displays the bar and returns the height and width.
--
-- Usage: Width, Height = Display()
--
-- Width           Width of the bar
-- Height          Height of the bar
-------------------------------------------------------------------------------
function BarDB:Display()
  local BoxFrame = self.BoxFrame

  local NumBoxes = self.NumBoxes
  local Padding = self.Padding
  local BoxWidth = self.BoxWidth
  local BoxHeight = self.BoxHeight
  local BoxScale = self.BoxScale
  local Angle = self.Angle
  local x = 0
  local y = 0
  local BorderWidth = 0
  local BorderHeight = 0
  local OffsetFX = 0
  local OffsetFY = 0

  for BoxFrameIndex = 1, NumBoxes do
    local BF = BoxFrame[BoxFrameIndex]
    local BoxPadding = BF.Padding

    -- Get the offsets based on angle.
    local XOffset, YOffset = Main:AngleToOffset(BoxWidth + BoxPadding, BoxHeight + BoxPadding, Angle)

    -- Calculate the x and y location before setting the location if angle is > 180.
    if Angle > 180 and BoxFrameIndex > 1 then
      x = x + XOffset
      y = y + YOffset
    end

    -- Set the location of the box.
    BF:ClearAllPoints()
    BF:SetPoint('TOPLEFT', x, y)

    -- Calculate the border width
    if XOffset ~= 0 then
      BorderWidth = BorderWidth + abs(XOffset)
      if BoxFrameIndex == 1 then
        BorderWidth = BorderWidth - BoxPadding
      end
    else
      BorderWidth = BoxWidth
    end

    -- Calculate the border height.
    if YOffset ~= 0 then
      BorderHeight = BorderHeight + abs(YOffset)
      if BoxFrameIndex == 1 then
        BorderHeight = BorderHeight - BoxPadding
      end
    else
      BorderHeight = BoxHeight
    end

    -- Get the x y for the frame offset. Also scale it.
    if x < 0 then
      OffsetFX = abs(x) * BoxScale
    end
    if y > 0 then
      OffsetFY = -y * BoxScale
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

  -- Scale the width and height of the border and add padding.
  BorderWidth = BorderWidth * BoxScale + Padding * 2
  BorderHeight = BorderHeight * BoxScale + Padding * 2

  -- Set the size of the border.
  Border:SetWidth(BorderWidth)
  Border:SetHeight(BorderHeight)

  -- Set the x, y location off the offset frame. Padding included.
  local OffsetFrame = self.OffsetFrame
  OffsetFrame:ClearAllPoints()
  OffsetFrame:SetPoint('TOPLEFT', Border, 'TOPLEFT', OffsetFX + Padding, OffsetFY - Padding)
  OffsetFrame:SetWidth(1)
  OffsetFrame:SetHeight(1)

  return BorderWidth, BorderHeight
end

--*****************************************************************************
--
-- Bar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetFrame
--
-- Sets a frame to be moved or have tooltips, or disable mouse clicks.
--
-- Usage: SetFrame(Frame, Object, Action)
--
-- Frame        Frame that will work with tooltips moving, etc.
-- Object       'enablemouse' or 'tooltip' or 'enablemouseclicks'
-- Action       if true then the script is set for Object otherwise script is removed from Object.
-------------------------------------------------------------------------------
local function SetFrame(Frame, Object, Action)
  if Object == 'enablemouseclicks' then
    Frame:EnableMouse(Action)

  elseif Object == 'enablemouse' then
    Frame:SetScript('OnMouseDown', function(self, Button)
                                   BarStartMoving(Frame, Button)
                                 end)
    Frame:SetScript('OnMouseUp', function(self, Button)
                                   BarStopMoving(Frame, Button)
                                 end)
    Frame:SetScript('OnHide', function(self)
                                BarStopMoving(self)
                              end)
  end
  if Object == 'tooltip' then
    Frame:SetScript('OnEnter', function(self)
                                 Main.UnitBarTooltip(Frame, false)
                               end)
    Frame:SetScript('OnLeave', function(self)
                                 Main.UnitBarTooltip(Frame, true)
                               end)
  end
end

-------------------------------------------------------------------------------
-- DoBar
--
-- Sub function for set functions.
--
-- Usage: DoBar(BarDB, BoxNumber, TextureNumber, Fn)
--
-- BarDB          Bar database.
-- BoxNumber      If 0 refers to all boxes, if greater than 0 then it refers to just
--                that one box.  If nil then bar is assumed.
-- TextureNumber  Only valid if BoxNumber is non nil.
-- Fn             Function.  Passes back one of the following:
--                Fn(Border)
--                   Bar Border.  If BoxNumber is nil
--                Fn(Border, BoxFrame)
--                   If BoxNumber is not nil
--                Fn(Border, BoxFrame, TextureFrame, Texture, Type)
--                   If BoxNumber and TextureNumber are not nil.
-------------------------------------------------------------------------------
local function DoBar(BarDB, BoxNumber, TextureNumber, Fn)

  -- Return border if BoxNumber is nill.
  if BoxNumber == nil then
    Fn(BarDB.Border)
  else

    -- Return box frames since there is a boxnumber.
    local BoxFrame = BarDB.BoxFrame
    local IndexStart = BoxNumber
    local IndexEnd = BoxNumber

    -- Check to see if BoxNumber is equal to 0
    if BoxNumber == 0 then
      IndexStart = 1
      IndexEnd = BarDB.NumBoxes
    end

    -- Loop thru 1 or all of the boxes.
    for BoxFrameIndex = IndexStart, IndexEnd do
      local BF = BoxFrame[BoxFrameIndex]
      local Border = BF.Border

      -- If texure number is not nil then pass back Border, BoxFrame, TextureFrame, Texture, and Type
      if TextureNumber then
        local TF = BF.TextureFrame[TextureNumber]
        Fn(Border, BF, TF, TF.Texture, TF.Type)
      else
        Fn(Border, BF)
      end
    end
  end
end

--=============================================================================
-- Set Functions
--
-- NOTES:  If BoxNumber is nil then it applies to the bar instead of boxes.
--         If BoxNumber is 0 then it applies to all boxes.
--         If BoxNumber is greater than 0 then it applies to just that box.
--=============================================================================

--=============================================================================
-- Set Functions that should be used first.
--
-- These are ordered in what to use first, second, third, etc.
--=============================================================================

-------------------------------------------------------------------------------
-- SetTexture
--
-- Sets a up a box to be a statusbar or a texture.
--
-- Usage: SetTexture(BoxNumber, TextureNumber, TextureName)
--
-- FileWidth     Width in pixels of the texture file.
-- FileHeight    Width in pixels of the texture file.

-- NOTES: TexureNumber can be any number but zero.
--        If its a statusbar then just the name of the texture is needed.
--        Otherwise a full pathname to the texture is needed.
-------------------------------------------------------------------------------
function BarDB:SetTexture(BoxNumber, TextureNumber, TextureName)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture, Type)
    if Type == 'statusbar' then
      Texture:SetStatusBarTexture(LSM:Fetch('statusbar', TextureName))
      Texture:GetStatusBarTexture():SetHorizTile(false)
      Texture:GetStatusBarTexture():SetVertTile(false)
      Texture:SetOrientation(TextureFrame.FillDirection)
      Texture:SetRotatesTexture(TextureFrame.RotateTexture)
    else
      Texture:SetTexture(TextureName)
    end
  end)
end

-------------------------------------------------------------------------------
-- SetTexCoord
--
-- Usage: SetTexCoord(BoxNumber, TextureNumber, Left, Right, Top, Bottom)
-------------------------------------------------------------------------------
function BarDB:SetTexCoord(BoxNumber, TextureNumber, Left, Right, Top, Bottom)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture:SetTexCoord(Left, Right, Top, Bottom)
    TextureFrame.TexLeft, TextureFrame.TexRight, TextureFrame.TexTop, TextureFrame.TexBottom = Left, Right, Top, Bottom
  end)
end

-------------------------------------------------------------------------------
-- SetDesaturated
--
-- Usage: SetDesaturated(BoxNumber, TextureNumber, Action)
--
-- Action   true then Desaturation gets set. Otherwise not.
-------------------------------------------------------------------------------
function BarDB:SetDesaturated(BoxNumber, TextureNumber, Action)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture:SetDesaturated(Action)
  end)
end

-------------------------------------------------------------------------------
-- CreateFontString
--
-- Usage FontString = CreateFontString(Layer, [Inherits])
--
-- Layer          Graphic layer on which to create the font string
-- Inherits       Name of a template from which the new front string should inherit (string)
--
-- FontString     Font string that can be used to display text on the bar.
--
-- NOTES:    The FontString gets made for the whole bar and not any of the boxes in the bar.
-------------------------------------------------------------------------------
function BarDB:CreateFontString(Layer, Inherits)
  local FS = nil
  DoBar(self, nil, nil, function(Border)
    local TextFrame = self.TextFrame

    -- Frame hasn't been created yet.
    if TextFrame == nil then
      TextFrame = CreateFrame('Frame', nil, Border)

      -- Set all points to border
      TextFrame:SetAllPoints(Border)

      -- Set frame to be above all else. So text shows up.
      TextFrame:SetFrameLevel(self.TopFrameLevel + 1)
      self.TextFrame = TextFrame

    end
    FS = TextFrame:CreateFontString(nil, Layer, Inherits)
  end)
  return FS
end

--=============================================================================
-- Set Functions that can be used at any time.
--=============================================================================

-------------------------------------------------------------------------------
-- HideBorder
--
-- Usage: HideBorder(BoxNumber)
-------------------------------------------------------------------------------
function BarDB:HideBorder(BoxNumber)
  DoBar(self, BoxNumber, nil, function(Border)
    Border:Hide()
  end)
end

-------------------------------------------------------------------------------
-- ShowBorder
--
-- Usage: ShowBorder(BoxNumber)
-------------------------------------------------------------------------------
function BarDB:ShowBorder(BoxNumber)
  DoBar(self, BoxNumber, nil, function(Border)
    Border:Show()
  end)
end

-------------------------------------------------------------------------------
-- HideTextureFrame
--
-- Usage: HideTextureFrame(BoxNumber, TextureNumber)
-------------------------------------------------------------------------------
function BarDB:HideTextureFrame(BoxNumber, TextureNumber)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame)
    TextureFrame:Hide()
  end)
end

-------------------------------------------------------------------------------
-- ShowTextureFrame
--
-- Usage: ShowTextureFrame(BoxNumber, TextureNumber)
-------------------------------------------------------------------------------
function BarDB:ShowTextureFrame(BoxNumber, TextureNumber)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame)
    TextureFrame:Show()
  end)
end

-------------------------------------------------------------------------------
-- HideTexture
--
-- Usage: HideTexture(BoxNumber, TextureNumber, Action)
--
-- Action      'finishfadeout' Then any textures currently fadingout will get hidden right away.
--               And the fadeout animation will be cancled.
-------------------------------------------------------------------------------
function BarDB:HideTexture(BoxNumber, TextureNumber, Action)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    if Action == 'finishfadeout' then
      if Texture.Hidden then
        Main:AnimationFadeOut(Texture.FadeOut, 'finish', function() Texture:Hide() end)
      end
    elseif not Texture.Hidden then
      if Texture.FadeOutTime > 0 then

        -- Fadeout the texture frame then hide it.
        Main:AnimationFadeOut(Texture.FadeOut, 'start', function() Texture:Hide() end)
      else
        Texture:Hide()
      end
      Texture.Hidden = true
    end
  end)
end

-------------------------------------------------------------------------------
-- ShowTexture
--
-- Usage: ShowTexture(BoxNumber, TextureNumber)
-------------------------------------------------------------------------------
function BarDB:ShowTexture(BoxNumber, TextureNumber)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    if Texture.Hidden then
      if Texture.FadeOutTime > 0 then

        -- Finish animation if it's playing.
        Main:AnimationFadeOut(Texture.FadeOut, 'finish')
      end
      Texture:Show()
      Texture.Hidden = false
    end
  end)
end

-------------------------------------------------------------------------------
-- SetFadeOutTime
--
-- Usage: SetFadeOutTime(BoxNumber, TextureNumber, Seconds)
-------------------------------------------------------------------------------
function BarDB:SetFadeOutTime(BoxNumber, TextureNumber, Seconds)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture.FadeOutTime = Seconds

    -- Set the duration of the fade out.
    Texture.FadeOutA:SetDuration(Seconds)
  end)
end

-------------------------------------------------------------------------------
-- SetBoxSize
--
-- Set the size of all the boxes to Width and Height
--
-- Usage: SetBoxSize(Width, Height)
-------------------------------------------------------------------------------
function BarDB:SetBoxSize(Width, Height)

  -- Save width and height in the BarDB.
  self.BoxWidth = Width
  self.BoxHeight = Height
  DoBar(self, 0, nil, function(Border, BoxFrame)
    BoxFrame:SetWidth(Width)
    BoxFrame:SetHeight(Height)
  end)
end

-------------------------------------------------------------------------------
-- SetEnableMouseClicks
--
-- Usage: SetEnableMouseClicks(BoxNumber, Action)
--
-- Action    false   Disables mouse interaction with frame.
--           true    Enables mouse interaction with frame.
--
-- NOTE:  If BoxNumber is nil then it will use the box's border to enable
--        mouse clicks.  Otherwise it will use the box's frame instead.
-------------------------------------------------------------------------------
function BarDB:SetEnableMouseClicks(BoxNumber, Action)
  DoBar(self, BoxNumber, nil, function(Border, Frame)
    if BoxNumber == nil then

      -- If boxnumber is nil then then the border has to be used.
      Frame = Border
    end
    SetFrame(Frame, 'enablemouseclicks', Action)
  end)
end

-------------------------------------------------------------------------------
-- SetEnableMouse
--
-- Enables box or bar to be dragged and dropped and to show mouse over tooltips.
--
-- Usage: SetEnableMouse(BoxNumber, Action)
--
-- Action    false  The box or bar can not be dragged/dropped and tooltips disabled
--           true   The box or bar can be dragged/dropped and tooltips enabled.
--
-- NOTE:  This function should be used after SetTooltip
--        If BoxNumber is nil then the bar's border is allowed to be dragged/dropped.
--        Otherwise the box's frame is used instead to drag/drop the bar.
-------------------------------------------------------------------------------
function BarDB:SetEnableMouse(BoxNumber, Action)
  DoBar(self, BoxNumber, nil, function(Border, Frame)
    if BoxNumber == nil then

      -- If boxnumber is nil then the border has to be used.
      Frame = Border
    end
    SetFrame(Frame, 'enablemouse', Action)
    if Frame.TooltipName then
      SetFrame(Frame, 'tooltip', Action)
    end
  end)
end

-------------------------------------------------------------------------------
-- SetTooltip
--
-- Usage: SetTooltip(BoxNumber, TooltipName, TooltipDescription)
-------------------------------------------------------------------------------
function BarDB:SetTooltip(BoxNumber, TooltipName, TooltipDescription)
  DoBar(self, BoxNumber, nil, function(Border, Frame)
    if BoxNumber == nil then

      -- If boxnumber is nil then the border has to be used.
      Frame = Border
    end
    Main:SetTooltip(Frame, TooltipName, TooltipDescription)
  end)
end

-------------------------------------------------------------------------------
-- SetAngle
--
-- Changes the way the bar is drawn.
--
-- Usage: SetAngle(Angle)
--
-- Notes: Angle can be 45 90 135 180 225 270 315 or 360
-------------------------------------------------------------------------------
function BarDB:SetAngle(Angle)
  self.Angle = Angle
end

-------------------------------------------------------------------------------
-- SetBackdrop
--
-- SetBackdrop(BoxNumber, BackdropSettings, r, g, b, a)
-------------------------------------------------------------------------------
function BarDB:SetBackdrop(BoxNumber, BackdropSettings, r, g, b, a)
  DoBar(self, BoxNumber, nil, function(Border)
    Border:SetBackdrop(Main:ConvertBackdrop(BackdropSettings))
    if r then
      Border:SetBackdropColor(r, g, b, a)
    else

      -- Set background color to invisible.
      Border:SetBackdropColor(0, 0, 0, 0)
    end
  end)
end

--------------------------------------------------------------------------------
-- SetPadding
--
-- Usage: SetPadding(BoxNumber, Padding)
--------------------------------------------------------------------------------
function BarDB:SetPadding(BoxNumber, Padding)
  DoBar(self, BoxNumber, nil, function(Border, Frame)
    if BoxNumber == nil then

      -- Set frame to self since this is for bar and not box.
      Frame = self
    end
    Frame.Padding = Padding
  end)
end

-------------------------------------------------------------------------------
-- SetBoxScale
--
-- Usage: SetBoxScale(Scale)
-------------------------------------------------------------------------------
function BarDB:SetBoxScale(Scale)
  self.BoxScale = Scale
  DoBar(self, 0, nil, function(Border, Frame)
    Frame:SetScale(Scale)
  end)
end

-------------------------------------------------------------------------------
-- SetColor
--
-- Usage: SetColor(BoxNumber, TextureNumber, r, g, b, a)
-------------------------------------------------------------------------------
function BarDB:SetColor(BoxNumber, TextureNumber, r, g, b, a)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture, Type)
    if Type == 'statusbar' then
      Texture:SetStatusBarColor(r, g, b, a)
    else
      Texture:SetVertexColor(r, g, b, a)
    end
  end)
end

-------------------------------------------------------------------------------
-- SetTexturePadding
--
-- SetTexturePadding(BoxNumber, TextureNumber, Left, Right, Top, Bottom)
--
-- NOTES: Works with statusbars only
-------------------------------------------------------------------------------
function BarDB:SetTexturePadding(BoxNumber, TextureNumber, Left, Right, Top, Bottom)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture, Type)
    if Type == 'statusbar' then
      Texture:ClearAllPoints()
      Texture:SetPoint('TOPLEFT', Left , Top)
      Texture:SetPoint('BOTTOMRIGHT', Right, Bottom)
    end
  end)
end

-------------------------------------------------------------------------------
-- SetTextureSize
--
-- Usage: SetTextureSize(BoxNumber, TextureNumber, Width, Height, Point, OffsetX, OffsetY)
--
-- Width              Width of the texture
-- Height             Height of the texture.
-- Point              Texture position within the frame.
-- OffsetX            Amount in pixels to offset. Positive goes right, negative goes left.
-- OffsetY            Amount in pixels to offset. Positive goes up, negative goes down.
--                    If OffsetX and OffsetY are not specified then zero is used.
--
-- NOTES: Works with textures only.
-------------------------------------------------------------------------------
function BarDB:SetTextureSize(BoxNumber, TextureNumber, Width, Height, Point, OffsetX, OffsetY)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture, Type)
    if Type == 'texture' then
      Texture:SetWidth(Width)
      Texture:SetHeight(Height)
      Texture:SetPoint(Point, OffsetX or 0, OffsetY or 0)
      Texture.Width = Width
      Texture.Height = Height
    end
  end)
end

-------------------------------------------------------------------------------
-- SetTextureScale
--
-- Usage: SetTextureScale(BoxNumber, TextureNumber, Scale)
-------------------------------------------------------------------------------
function BarDB:SetTextureScale(BoxNumber, TextureNumber, Scale)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame)
    TextureFrame:SetScale(Scale)
  end)
end

-------------------------------------------------------------------------------
-- SetRotateTexture
--
-- Usage: SetRotateTexture(BoxNumber, TextureNumber, Action)
--
-- Action    true   texture is rotated
--           false  no rotation
-------------------------------------------------------------------------------
function BarDB:SetRotateTexture(BoxNumber, TextureNumber, Action)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture:SetRotatesTexture(Action)
    TextureFrame.RotateTexture = Action
  end)
end

-------------------------------------------------------------------------------
-- SetFillDirection
--
-- Usage: SetFillDirection(BoxNumber, TextureNumber, Action)
--
-- Action    'HORIZONTAL'   Fill from left to right.
--           'VERTICAL'     Fill from bottom to top.
-------------------------------------------------------------------------------
function BarDB:SetFillDirection(BoxNumber, TextureNumber, Action)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture, Type)
    if Type == 'statusbar' then
      Texture:SetOrientation(Action)
    end
    TextureFrame.FillDirection = Action
  end)
end

-------------------------------------------------------------------------------
-- SetTextureFill
--
-- Shows more of the texture instead of stretching.
--
-- Usage: SetTextureFill(BoxNumber, TextureNumber, Amount)
--
-- Amount    A number between 0 and 1.  If Amount > 1 then its set to 1.
--             If Amount < 0 then its set to 0.
--
-- NOTE: SetFillDirection will control the fill that this function will use.
--       Cant set texture width to 0 so use 0.001 this will make the texture not be
--       visible.  Setting texture size to 0 doesn't hide the texture.
-------------------------------------------------------------------------------
function BarDB:SetTextureFill(BoxNumber, TextureNumber, Amount)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture, Type)
    if Type == 'texture' then
      local TexLeft, TexRight, TexTop, TexBottom = TextureFrame.TexLeft, TextureFrame.TexRight, TextureFrame.TexTop, TextureFrame.TexBottom
      local Width, Height =  Texture.Width, Texture.Height

      -- Clip amount if not equal to 1
      Amount = Amount > 1 and 1 or Amount < 0 and 0 or Amount

      -- Calculate the texture width
      if TextureFrame.FillDirection == 'HORIZONTAL' then
        local TextureWidth = Amount * Width

        -- Calc the position betwen left and right
        TexRight = TexLeft + Amount * (TexRight - TexLeft)
        Texture:SetWidth(TextureWidth > 0 and TextureWidth or 0.001)
      else
        local TextureHeight = Amount * Height

        -- Calc the position between top and bottom.
        TexTop = TexBottom - Amount * (TexBottom - TexTop)
        Texture:SetHeight(TextureHeight > 0 and TextureHeight or 0.001)
      end
      Texture:SetTexCoord(TexLeft, TexRight, TexTop, TexBottom)
    else

      -- Set statusbar value.
      Texture:SetValue(Amount)
    end
  end)
end

-------------------------------------------------------------------------------
-- SetNumBoxes
--
-- Changes the number of boxes to be displayed in the bar
--
-- Usage: SetNumBoxes(NumBoxes)
--
-- NumBoxes    Number of boxes to show.
--
-- NOTES: The bars Display() function will need to be called to reflect the change.
-------------------------------------------------------------------------------
function BarDB:SetNumBoxes(NumBoxes)
  local BoxFrame = self.BoxFrame

  for BoxFrameIndex = 1, self.TotalBoxes do
    local BF = BoxFrame[BoxFrameIndex]

    if BoxFrameIndex <= NumBoxes then
      BF:Show()
    else
      BF:Hide()
    end
  end
  self.NumBoxes = NumBoxes
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- Sets up a bar that will contain boxes which hold textures/statusbars.
--
-- Usage: BarDB = CreateBar(ParentFrame, Anchor, NumBoxes)
--
-- ParentFrame        Parent frame the bar will be a child of.
-- Anchor             Anchor that is used for moving.
-- NumBoxes           Total boxes that the bar will contain.
-- BarDB              Bar database containing everything to work with the bar.
--
-- Note:  All bar functions are called thru the returned table.
-------------------------------------------------------------------------------
function GUB.Bar:CreateBar(ParentFrame, Anchor, NumBoxes)
  local BDB = Main:DeepCopy(BarDB)

  -- initialize the bar database.
  BDB.ParentFrame = ParentFrame
  BDB.TotalBoxes = NumBoxes
  BDB.NumBoxes = NumBoxes
  BDB.Angle = 90
  BDB.Padding = 0
  BDB.BoxWidth = 1
  BDB.BoxHeight = 1
  BDB.BoxScale = 1
  BDB.BoxFrame = {}

  -- Create the border frame.
  local Border = CreateFrame('Frame', nil, ParentFrame)

  -- Save the Anchor to the border
  Border.Anchor = Anchor

  -- Create the offset frame.
  local OffsetFrame = CreateFrame('Frame', nil, ParentFrame)

  BDB.OffsetFrame = OffsetFrame
  BDB.Border = Border

  -- Create the boxes for the bar.
  for BoxFrameIndex = 1, NumBoxes do

    -- Create the BoxFrame and Border.
    local BoxFrame = CreateFrame('Frame', nil, OffsetFrame)
    local Border = CreateFrame('Frame', nil, BoxFrame)

    -- Set the SetScriptFrame and border to always be the size of the boxframe.
    Border:SetAllPoints(BoxFrame)

    -- Save frame data to the bar database.
    BoxFrame.Border = Border
    BoxFrame.Anchor = Anchor
    BoxFrame.Padding = 0
    BoxFrame.TextureFrame = {}
    BDB.BoxFrame[BoxFrameIndex] = BoxFrame
  end

  return BDB
end
-------------------------------------------------------------------------------
-- CreateBoxTexture
--
-- Creates a frame to hold a texture for the bar.
--
-- Usage: CreateBoxTexture(BoxNumber, TextureNumber, 'statusbar (TextureType)')
--        CreateBoxTexture(BoxNumber, TextureNumber, 'texture (TextureType)', FrameLevel, Width, Height)

--
-- BoxNumber          Box to be modified.
-- TextureNumber      Numerical value to reference the texture.
-- TextureType        'statusbar' statusbar texture.
--                    'texture'   standard texture.
-- FrameLevel         Used for 'texture' only.
--                    If level is used then the TexureFrame level is set.
--                    Level is counted from its current level and up.  So setting 2 would
--                    be current level frame level + 2.
--
-- Width, Height      Used for 'texture' only. Width and Height of the TextureFrame.
--
-- Note: Statusbars get stretched to the box edges.
-------------------------------------------------------------------------------
function BarDB:CreateBoxTexture(BoxNumber, TextureNumber, TextureType, FrameLevel, Width, Height)
  local BoxFrame = self.BoxFrame[BoxNumber]
  local Texture = nil

  -- Create the texture frame.
  local TextureFrame = CreateFrame('Frame', nil, BoxFrame)
  TextureFrame:SetWidth(1)
  TextureFrame:SetHeight(1)
  TextureFrame:Hide()

  -- Set default rotation to false and fill direction to horizontal
  TextureFrame.Rotate = false
  TextureFrame.FillDirection = 'HORIZONTAL'

  -- Create a statusbar or texture.
  if TextureType == 'statusbar' then
    Texture = CreateFrame('StatusBar', nil, TextureFrame)
    Texture:SetPoint('TOPLEFT', 0, 0)
    Texture:SetPoint('BOTTOMRIGHT' ,Value1 or 0, Value2 or 0)
    Texture:SetMinMaxValues(0, 1)
    Texture:SetValue(1)

    -- Statusbar gets streched to the boxframe size.
    TextureFrame:SetAllPoints(BoxFrame)

    -- Set defaults for statusbar.
    TextureFrame.RotateTexture = false
    TextureFrame.Type = 'statusbar'
  else
    Texture = TextureFrame:CreateTexture(nil)

    -- Add 1 to account for the border in the boxframe being the same frame level.
    TextureFrame:SetFrameLevel(TextureFrame:GetFrameLevel() + FrameLevel + 1)
    TextureFrame:SetWidth(Width)
    TextureFrame:SetHeight(Height)

    -- Save width and height
    TextureFrame.Width = Width
    TextureFrame.Height = Height

    -- Texture Frame is centered in the boxframe.
    TextureFrame:SetPoint('CENTER', 0, 0)
    TextureFrame.Type = 'texture'
  end

  -- Update TopFrameLevel counter
  local TopFrameLevel = self.TopFrameLevel or 0
  local CurrentFrameLevel = TextureFrame:GetFrameLevel()
  self.TopFrameLevel = TopFrameLevel < CurrentFrameLevel and CurrentFrameLevel or TopFrameLevel

  -- Create an animation for fade out for the Texture.
  Texture.FadeOut, Texture.FadeOutA = Main:CreateFadeOut(Texture)
  Texture.FadeOutTime = 0

  -- Hide the texture or statusbar
  Texture:Hide()
  Texture.Hidden = true

  -- Save texture data to the bar database.
  TextureFrame.Texture = Texture
  BoxFrame.TextureFrame[TextureNumber] = TextureFrame
end
