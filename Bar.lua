--
-- Bar.lua
--
-- Allows bars to be coded easily.  Currently used by ComboBar, HolyBar, and ShardBar.
--
-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.Bar = {}
local Main = GUB.Main

-- shared from Main.lua
local LSM = Main.LSM

-- localize some globals.
local _
local bitband,  bitbxor,  bitbor,  bitlshift,  stringfind =
      bit.band, bit.bxor, bit.bor, bit.lshift, string.find
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
--
-- BarDB                             Bar Database. All functions are called thru this except for CreateBar().
-- BarDB.ParentFrame                 The whole bar will be a child of this frame.
-- BarDB.NumBoxes                    Total number of boxes in the bar.
-- BarDB.Border                      Visible or invisible border around the bar. Child of ParentFrame.
--                                   This is also used for handling mouse events for the whole bar.
-- BarDB.OffsetFrame                 Child of ParentFrame.  This is used to help with rotation
-- BarDB.Padding                     Amount of distance between the boxes and the bars border.
-- BarDB.Angle                       Angle in degrees in which way the bar will be displayed.
-- BarDB.FadeOutTime                 Time in seconds to fade a box out to hide it.  If zero fadeout is disabled.
-- BarDB.BoxScale                    Change the scale of all the boxes in the bar.
-- BarDB.BoxWidth                    Width of all the boxes.
-- BarDB.BoxHeight                   Height of all the boxes.
-- BarDB.BoxFrame[]                  An array of frames containing textures or statusbars or both.
--
-- BoxFrame[]                        Invisible frame containing the textures/statusbars.
--                                   Child of OffsetFrame. This is also used to scale the box.
-- BoxFrame[].Padding                Amount of distance from the current box and next one.
-- BoxFrame[].Border                 Visible border surrounding the box.  Child of OffsetFrame. Border changes size
--                                   based on BoxFrame.
-- BoxFrame[].TextureFrame[]         An array of frames holding the textures/statusbar for the box.
-- TextureFrame[]                    Invisible frame containing the textures/statusbars.  Child of BoxFrame.
--                                   This can be used to change the scale of a texture or hide/show it.
-- TextureFrame[].FillDirection      Statusbar only.  'HORIZONTAL' or 'VERTICAL'
-- TextureFrame[].RotateTexture      Statusbar only.  If true then texture is rotated 90 degrees.
--                                   If false no rotation takes place.
-- TextureFrame[].Type               Contains the type of texture.
--                                   'statusbar'  then its a statusbar.
--                                   'texture'    contains a texture.
-- TextureFrame[].Texture            Statusbar or texture.  Child of TextureFrame.
-- Texture.FadeOutTime               Time in seconds to fade out a texture.  If 0 then this frame doesn't have a fadeout.
-- Texture.FadeOut                   Fadeout animation group for TextureFrame
-- Texture.FadeOutA                  Fadeout animation
-- Texture.Hidden                    If true the frame is hidden otherwise it's visible.
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

  -- Scale the width and height of the border.
  BorderWidth = BorderWidth * BoxScale
  BorderHeight = BorderHeight * BoxScale

  -- Set the size of the border including padding.
  Border:SetWidth(BorderWidth + Padding * 2)
  Border:SetHeight(BorderHeight + Padding * 2)

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

-------------------------------------------------------------------------------
-- Set functions
--
-- Functions that change the bar.
--
-- HideBorder (BoxNumber)
-- ShowBorder (BoxNumber)
-- HideTextureFrame (BoxNumber, TextureNumber)
-- ShowTextureFrame (BoxNumber, TextureNumber)
-- HideTexture (BoxNumber, TextureNumber, ['finishfadeout'])
--             If finishfadeout is specified.  Then any textures currently fadingout will get hidden right away.
--             And the fadeout animation will be cancled.
-- ShowTexture (BoxNumber, TextureNumber)
-- SetFadeOutTime (BoxNumber, TextureNumber, Seconds)
-- SetBoxSize (Width, Height)
-- SetEnableMouseClicks (BoxNumber, true or false)
--             Disables or enables mouse interaction with frame.
-- SetEnableMouse (BoxNumber)
--             Enables box or bar to be dragged and dropped and to show mouse over tooltips.
-- SetClamp (true or false)
-- SetTooltip (BoxNumber, TooltipName, TooltipDescription)
-- SetAngle (Angle)
--             Angle can be 45 90 135 180 225 270 315 or 360
-- SetBackdrop (BoxNumber, BackdropSettings, r, g, b, a)
-- SetPadding (BoxNumber, Padding)
-- SetBoxScale (Scale)
-- SetColor (BoxNumber, TextureNumber, r, g, b, a)
-- SetTexturePadding (BoxNumber, TextureNumber, Left, Right, Top, Bottom)
-- SetTextureSize (BoxNumber, TextureNumber, Width, Height)
-- SetTextureScale (BoxNumber, TextureNumber, Scale)
-- SetRotateTexture (BoxNumber, TextureNumber, true or false)
-- SetFillDirection (BoxNumber, TextureNumber, 'HORIZONTAL' or 'VERTICAL')
-- SetTexture (BoxNumber, TextureNumber, TextureName)
--             If its a statusbar then just the name of the texture is needed.
--             Otherwise a full pathname to the texture is needed.
-- SetTexCoord (BoxNumber, TextureNumber, Left, Right, Top, Bottom)
-- SetDesaturated (BoxNumber, TextureNumber, true or false)
--
-- NOTES:  If BoxNumber is nil then it applies to the bar instead of boxes.
--         If BoxNumber is 0 then it applies to all boxes.
--         If BoxNumber is greater than 0 then it applies to just that box.
-------------------------------------------------------------------------------
function BarDB:HideBorder(BoxNumber)
  DoBar(self, BoxNumber, nil, function(Border)
    Border:Hide()
  end)
end

-- ShowBorder
function BarDB:ShowBorder(BoxNumber)
  DoBar(self, BoxNumber, nil, function(Border)
    Border:Show()
  end)
end

-- HideTextureFrame
function BarDB:HideTextureFrame(BoxNumber, TextureNumber)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame)
    TextureFrame:Hide()
  end)
end

-- ShowTextureFrame
function BarDB:ShowTextureFrame(BoxNumber, TextureNumber)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame)
    TextureFrame:Show()
  end)
end

-- HideTexture
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

-- ShowTexture
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

-- SetFadeOutTime
function BarDB:SetFadeOutTime(BoxNumber, TextureNumber, Seconds)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture.FadeOutTime = Seconds

    -- Set the duration of the fade out.
    Texture.FadeOutA:SetDuration(Seconds)
  end)
end

-- SetBoxSize
function BarDB:SetBoxSize(Width, Height)

  -- Save width and height in the BarDB.
  self.BoxWidth = Width
  self.BoxHeight = Height
  DoBar(self, 0, nil, function(Border, BoxFrame)
    BoxFrame:SetWidth(Width)
    BoxFrame:SetHeight(Height)
  end)
end

-- SetEnableMouseClicks
function BarDB:SetEnableMouseClicks(BoxNumber, Action)
  DoBar(self, BoxNumber, nil, function(Border, Frame)
    if BoxNumber == nil then

      -- If boxnumber is nil then then the border has to be used.
      Frame = Border
    end
    SetFrame(Frame, 'enablemouseclicks', Action)
  end)
end

-- SetEnableMouse
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

-- SetClamp
function BarDB:SetClamp(Action)
  DoBar(self, nil, nil, function(Border)
    Border:SetClampedToScreen(Action)
  end)
end


-- SetTooltip
function BarDB:SetTooltip(BoxNumber, TooltipName, TooltipDescription)
  DoBar(self, BoxNumber, nil, function(Border, Frame)
    if BoxNumber == nil then

      -- If boxnumber is nil then the border has to be used.
      Frame = Border
    end
    Frame.TooltipName = TooltipName
    Frame.TooltipDesc = TooltipDescription
  end)
end

-- SetAngle
function BarDB:SetAngle(Angle)
  self.Angle = Angle
end

-- SetBackdrop
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

-- SetPadding
function BarDB:SetPadding(BoxNumber, Padding)
  DoBar(self, BoxNumber, nil, function(Border, Frame)
    if BoxNumber == nil then

      -- Set frame to self since this is for bar and not box.
      Frame = self
    end
    Frame.Padding = Padding
  end)
end

-- SetBoxScale
function BarDB:SetBoxScale(Scale)
  self.BoxScale = Scale
  DoBar(self, 0, nil, function(Border, Frame)
    Frame:SetScale(Scale)
  end)
end

-- SetColor
function BarDB:SetColor(BoxNumber, TextureNumber, r, g, b, a)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture, Type)
    if Type == 'statusbar' then
      Texture:SetStatusBarColor(r, g, b, a)
    else
      Texture:SetVertexColor(r, g, b, a)
    end
  end)
end

-- SetTexurePadding
function BarDB:SetTexturePadding(BoxNumber, TextureNumber, Left, Right, Top, Bottom)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture:ClearAllPoints()
    Texture:SetPoint('TOPLEFT', Left , Top)
    Texture:SetPoint('BOTTOMRIGHT', Right, Bottom)
  end)
end

-- SetTextureSize
function BarDB:SetTextureSize(BoxNumber, TextureNumber, Width, Height)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture:SetWidth(Width)
    Texture:SetHeight(Height)
  end)
end

-- SetTextureScale
function BarDB:SetTextureScale(BoxNumber, TextureNumber, Scale)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame)
    TextureFrame:SetScale(Scale)
  end)
end

-- SetRotateTexture
function BarDB:SetRotateTexture(BoxNumber, TextureNumber, Action)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture:SetRotatesTexture(Action)
    TextureFrame.RotateTexture = Action
  end)
end

-- SetFillDirection
function BarDB:SetFillDirection(BoxNumber, TextureNumber, Action)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture:SetOrientation(Action)
    TextureFrame.FillDirection = Action
  end)
end

-- SetTexture
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

-- SetTexCoord
function BarDB:SetTexCoord(BoxNumber, TextureNumber, Left, Right, Top, Bottom)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture:SetTexCoord(Left, Right, Top, Bottom)
  end)
end

-- SetDesaturated
function BarDB:SetDesaturated(BoxNumber, TextureNumber, Action)
  DoBar(self, BoxNumber, TextureNumber, function(Border, Frame, TextureFrame, Texture)
    Texture:SetDesaturated(Action)
  end)
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

    -- Create the border, Frame, and SetScriptFrame.  These are child of OffsetFrame.
    local BoxFrame = CreateFrame('Frame', nil, OffsetFrame)
    local Border = CreateFrame('Frame', nil, OffsetFrame)

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
-- Usage: CreateBoxTexture(BoxNumber, TextureNumber, TextureType, [Layer])
--
-- BoxNumber          Box to be modified.
-- TextureNumber      Numerical value to reference the texture.
-- TextureType        'statusbar' statusbar texture.
--                    'texture'   standard texture.
-- Layer              Used for 'texture' only.  Sets the layer for texture.
--
-- Note: Statusbars get stretched to the box edges.  Textures are centered in the box.
--       Textures and Statusbars are hidden by default.
-------------------------------------------------------------------------------
function BarDB:CreateBoxTexture(BoxNumber, TextureNumber, TextureType, Layer)
  local BoxFrame = self.BoxFrame[BoxNumber]
  local Texture = nil

  -- Create the texture frame.
  local TextureFrame = CreateFrame('Frame', nil, BoxFrame)
  TextureFrame:SetWidth(1)
  TextureFrame:SetHeight(1)
  TextureFrame:Hide()

  -- Set default rotation to false.
  TextureFrame.Rotate = false

  -- Create a statusbar or texture.
  if TextureType == 'statusbar' then
    Texture = CreateFrame('StatusBar', nil, TextureFrame)
    Texture:SetPoint('TOPLEFT', 0, 0)
    Texture:SetPoint('BOTTOMRIGHT' ,0, 0)
    Texture:SetMinMaxValues(0, 1)
    Texture:SetValue(1)

    -- Set defaults for statusbar.
    TextureFrame.FillDirection = 'HORIZONTAL'
    TextureFrame.RotateTexture = false
    TextureFrame.Type = 'statusbar'
  else
    Texture = TextureFrame:CreateTexture(nil, Layer)
    Texture:SetWidth(1)
    Texture:SetHeight(1)
    Texture:SetPoint('CENTER', 0, 0)
    TextureFrame.Type = 'texture'
  end
  TextureFrame:SetAllPoints(BoxFrame)

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
