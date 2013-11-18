--
-- Bar.lua
--
-- Allows bars to be coded easily.
--

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local DUB = GUB.DefaultUB.Default.profile
local Main = GUB.Main

local LSM = Main.LSM

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strupper, strlower, strmatch, format, strconcat, gsub, tonumber =
      strfind, strsplit, strsub, strupper, strlower, strmatch, format, strconcat, gsub, tonumber
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax
local UnitName, UnitGetIncomingHeals, GetRealmName =
      UnitName, UnitGetIncomingHeals, GetRealmName
local GetRuneCooldown, GetRuneType, GetSpellInfo, GetTalentInfo, PlaySound =
      GetRuneCooldown, GetRuneType, GetSpellInfo, GetTalentInfo, PlaySound
local GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, UIParent =
      C_PetBattles, UIParent

-------------------------------------------------------------------------------
-- Locals
--
-- BarDB                             Bar Database. All functions are called thru this except for CreateBar().
-- BarDB.UnitBarF                    The bar is a chiled of UnitBarF.
-- BarDB.ProfileChanged              Used by Display(). If true then the profile was changed in some way.
-- BarDB.Anchor                      Reference to the UnitBar's anchor frame.
-- BarDB.BarType                     The type of bar it belongs to.
-- BarDB.Options                     Used by SO() and DoOption().
-- BarDB.OptionsData                 Used by DoOption() and SetOptionData().
-- BarDB.ParentFrame                 The whole bar will be a child of this frame.
-- BarDB.Region                      Visible region around the bar. Child of ParentFrame.
--   Colors                          Saved color used by SetColor() and GetColor()
--   Hidden                          If true the region is hidden.
--   Anchor                          Reference to the UnitBarF.Anchor.  Used for Mouse interaction.
--   BarDB                           BarDB.  Reference to the Bar database.  Used for mouse interaction
--   Name                            Name for the tooltip.  Used for tooltip, dragging.
-- BarDB.NumBoxes                    Total number of boxes the bar was created with.
-- BarDB.TopFrame                    Contains a reference to the frame that has the highest frame level.
-- BarDB.Rotation                    Rotation in degrees for the bar.
-- BarDB.Slope                       Adjusts the horizontal or vertical slope of a bar.
-- BarDB.Swap                        Boxes can be swapped with eachother by dragging one on top of the other.
-- BarDB.Float                       Boxes can be dragged and dropped anywhere on the screen.
-- BarDB.Align                       If false then alignment is disabled.
-- BarDB.AlignOffsetX                Horizontal offset for the aligned group of boxes.
-- BarDB.AlignOffsetY                Vertical offset for the aligned group of boxes
-- BarDB.AlignPadding                Amount of horizontal distance to set the moving boxframe near another one when aligned
-- BarDB.BorderPadding               Amount of padding between the region's border of the bar and the boxes.
-- BarDB.Justify                     'SIDE' of boxframe or 'CORNER'.
-- BarDB.RegionEnabled               If false the bars region is not shown and doesn't interact with mouse.
--                                   HideRegion and ShowRegion functions no longer work.
-- BarDB.ChangeTextures[]            List of texture numbers used with SetChangeTexture() and ChangeTexture()
-- BarDB.BoxLocations[]              List of x, y coordinates for each boxframe when in floating mode.
-- BarDB.BoxOrder[]                  Table box indexes containing the order the boxes should be listed in.
--
-- BarDB.BoxFrames[]                 An array containing all the box frames in the bar.
--   TextureFrames[]                 An array containing all the texture frames for the box.
--     Texture[]                     An array containing all the texture/statusbars for the texture frame.
--       SubTexture                  Texture that is a child of Texture[].
--
-- BoxFrame data structure
--
--   Name                            Name of the boxframe.  This will appear on tooltips.
--   BoxNumber                       Current box number.  Needed for swapping.
--   Padding                         Amount of distance in pixels between the current box and the next one.
--   Hidden                          If true then the boxframe will not get shown in Display()
--   Colors                          Saved color used by SetColor() and GetColor()
--   TextureFrames[]                 Table of textureframes used by boxframe.
--   TFTextures[]                    Used by texture function, contains the texture.
--   FontTime                        Used by FontSetValueTime()
--   Anchor                          Reference to the UnitBarF.Anchor.  Used for tooltip, dragging.
--   BarDB                           BarDB.  Reference to the Bar database.  Used for tooltip, dragging.
--   BF                              Reference to boxframe.  Used for tooltip, dragging.
--
-- TextureFrame data structure
--
--   Hidden                          If true then the textureframe is hidden.
--   Bound                           If nil or true then textureframe is included in the bounding rect for the boxframe.
--                                   if not nil and false then its not included in the bounding rect.
--   Textures[]                      Textures contained in TextureFrame.
--   Colors                          Saved color used by SetColor() and GetColor()
--   FontTime                        Used by FontSetValueTime()
--   Anchor                          Reference to the UnitBarF.Anchor.  Used for tooltip, dragging.
--   BarDB                           BarDB.  Reference to the Bar database.  Used for tooltip, dragging.
--   BF                              Reference to boxframe.  Used for tooltip, dragging.
--
-- Texture data structure            A texture is actually a frame.  I call it Texture so its not confused with
--                                   TextureFrame.
--
--   Type                            Either 'statusbar' or 'texture'
--   SubFrame                        Child of Texture. Holds the StatusBar or Frame containing the actual texture.
--   Width, Height                   Width and height of the texture.
--   Hidden                          If true then the statusbar/texture is hidden.
--   RotateTexture                   If true then the texture is rotated 90 degrees.
--   ReverseFill                     If true then the texture will fill in the opposite direction.
--   FillDirection                   Can be 'HORIZONTAL' or 'VERTICAL'.
--   FadeOutTime                     Amount of time it takes for a texture to become hidden.
--   FadeInTime                      Amount of time it takes for a texture to become visible.
--   Value                           Current value, work around for padding function dealing with statusbars.
--                                   Also used by SetFill functions.
--   SmoothTime                      Amount of time it takes to fill a texture from current value to new value.
--                                   Used by SetFillSmoothTimeTexture() and SetFillTexture()
--   SetFill                         Flag used by OnSizeChangedTexture().  When a texture changes size SetFill()
--                                   will be called to update the fill.  This only works if SetFill() was called prior.
--   StartTime
--   Duration
--   StartValue
--   EndValue
--   Range
--   TimeElapsed                     Used by SetFillTimeTexture()
--   Spark                           Is a child of Texture.
--   SubTexture                      Is either the texture of a statusbar or a texture depending on type.
--                                   These are used by textures only.
--   TexLeft
--   TexRight
--   TexTop
--   TexBottom                       Text coords for a texture.  Used by SetFill() and SetTexCoord()
--
--   CooldownFrame                   Frame used to do a cooldown on the texture.
--   CooldownFrameLine               Frame used to show a line in the clockface cooldown.
--
--  Spark data structure
--    ParentFrame                    Contains a reference to Texture.
--
--  Upvalues                         Used by bars.lua
--
--    RotationPoint                  Used by Display() to rotate the bar.
--    BoxFrames                      Used by NextBox() for iteration.
--    NextColor                      Used by NextColor() for iteration of a ColorAll table.
--    ColorBarFn                     Used by NextColor() contains the barfunction passed.
--    TextureFillTime                Amount of times per second the fill timer is called.
--    TextureSmoothFillTime          Amount of times per second the smooth fill timer is called.
--    DoOptionData                   Resusable table for passing back information. Used by DoOption().
--
--  RotationPoint data structure
--
--  [Rotation]                       from 45 to 360.  Determins which direction to go in.
--    x, y                           Determins direction by using negative or positive values.
--                                   x or y will be 0 if there is no direction to go in.
--                                   For example x = 1 y = 0 means that there is no up/down just
--                                   horizontal.
--  SIDE or CORNER                   Is the alignment for the boxes.  Either their attached by their
--                                   corner or side.  Side would be the middle part of the box edge.
--    Point                          The anchor point for the boxframe to attach another boxframe.
--    ParentPoint                    Is the previos boxframe's anchor point that is attached.
--                                   So boxframe 2 Point would be attached to boxframe 1 ParentPoint.
--
--  Frame structure
--
--    ParentFrame
--      Region                       Bar border
--      BoxFrame                     border and BoxFrame
--        TextureFrame               Border and TextureFrame.
--          Texture (frame)          Container for SubFrame and SubTexture.
--            SubFrame               A frame that holds the texture.
--              SubTexture           Statusbar texture or texture.
--
-- NOTES:   When clearing all points on a frame.  Then do a SetPoint(Point, nil, Point)
--          Will cause GetLeft() etc to return a bad value.  But if you pass the frame
--          instead of nil you'll get good values.
--
-- Bar Display notes:
--
-- The bar gets drawn by letting the UI place the boxes.  The boxes will get drawn
-- forwards or backwards.  Then the boxes are offset to fit inside the bar region.
--
-- Textureframes that are inside of a boxframe.  The boxframe will always take on the
-- total size of all the textureframes inside of it.  The textureframe that is not
-- attached to another textureframe is attached to the boxframe.
--
-- Cause of the way boxframes and textureframes get offset.  The first boxframe or textureframe
-- that is attached to a boxframe can't contain an offset from SetPointTextureFrame or SetOffsetBox.
-- It just gets ignored if one is set.
--
-- After the boxframes are drawn.  SetFrames is called to offset them.  SetFrames also clears all the
-- points of each frame and sets it a new point TOPLEFT, with an x, y position.  The frame doens't
-- actually move unless it was offset.  The same thing is done for textureframes so they're always
-- inside of a boxframe.
--
-- When floating mode is activated a snap shot of the bar is taken then copied.  Then the boxframes
-- can be placed anywhere on the screen.  The floating layout is always kept seperate from the bar layout.
-- The floating code uses the x, y locations created by SetFrames.
--
-- The floating layout and boxorder for swapping is stored in the root of the unitbar.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Options Notes
--
-- The Options functions provide a way to apply changes to different parts of
-- a unitbar or all at once.
--
-- OptionsSet()     Returns true if options were set.
-- SO()             Sets a function to an option.
-- SetOptionData()  Sets extra data to be passed back to the function set in SO()
--
-- SO short for SetOption lets you specifiy a table name and key name.
-- When you call DoOptions() with a table name and key name the following can happen:
--
-- TableName is nil   - Then the SO TableName will match.
-- KeyName is nil     - Then the SO KeyName will match.
--
--   Each time an SO TableName is found.  Then the SO TableName has to be found in the
--   default unitbar data first then its checked to see if its in the UnitBar data second.
--   Each time an SO KeyName is found.  Then it has to match exactly to a key in the
--   unitbar data.
--
-- TableName is not nil - Then the SO TableName needs to be found within TableName.
-- KeyName is not nil   - Then the SO KeyName needs to match exatly to KeyName.  Then it also
--                        has to match exactly to the unitbar data keyname.
--
-- Virtual Key Name.
--   A virtual key starts with an underscore.  It still follows the matching rules of a normal
--   key except it doesn't get searched in the UnitBar data.  A virtual key of '_' will match
--   any keyname passed from DoOption.  But those keys never get searced in the unitbar data.
--
-- Everytime a match is made in the unitbar data the function passed to SO() gets called.
-- The following parameters are passed back.
--
--   v:   This equals UnitBars[BarType][TableName][KeyName]. If the KeyName is virtual
--        then this will equal UnitBars[BarType][TableName].
--   UB:  This equals the unitbar table UnitBars[BarType].
--   OD:  Table that contains the following:
--           TableName   The name of the table found in the unitbar data.
--           KeyName     Name of the key passed to SO()
--
--           If the KeyName is a table that contains 'All'.  Then its considered
--           a color all table.  And the following is returned.
--             Index       THe current element in the color all table.
--             r, g, b, a  The red, green, blue, and alpha colors KeyName[Index]
--
-- Additional information can be applied to the OD table thru SetOptionData.
-- SetOptionData takes a tablename and one or more paramaters for the data.
-- Once the SO TableName is found in the UnitBar data.  Then if the SO TableName
-- matches the one in SetOptionsData.  Then the following are added to the OD table:
--  p1..pN.   One or more paramaters containing the data passed thru SetOptionData.
--            Each paramater is always p1, p2, etc.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Fonts
--
-- A BoxFrame or TextureFrame can have a font.
--
-- FSS[BarType]         An array that keeps track of all the FS tables.
--                      This is used to help display the text frame boxes when options is opened.
--
-- FS Data structure.
--   BarType            Type of bar that created the fontstring.
--   NumStrings         Number of font strings or text lines.
--   TextFrames         Contains one or more frames used by the fontstrings.
--   PercentFn          Function used to calculate percentages from CurrentValue and MaximumValue.
--   Text               Reference to the current Text data found in UnitBars[BarType].Text
--
-- FS[]                 Array used to store each fontstring or textline.
--
--
-- Lowercase hash names are used for SetValueTimeFont and SetValueFont.
-------------------------------------------------------------------------------
local DragObjectMouseOverDesc = 'Modifier + right mouse button to drag this object'

local BarDB = {}
local Args = {}
local FontStrings = {}

local DoOptionData = {}
local VirtualFrameLevels = nil

local BoxFrames = nil
local NextBoxFrame = 0
local LastBox = true
local NextColor = 0
local ColorBarFn = nil

local TextureFillTime = 1 / 40  -- 40 times per second
local TextureSmoothFillTime = 1 / 60 -- 60 times per second.
local TextureSpark = [[Interface\CastingBar\UI-CastingBar-Spark]]
local TextureSparkSize = 32

-- Constants used in NumberToDigitGroups
local Thousands = strmatch(format('%.1f', 1/5), '([^0-9])') == '.' and ',' or '.'
local BillionFormat = '%s%d' .. Thousands .. '%03d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local MillionFormat = '%s%d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local ThousandFormat = '%s%d' .. Thousands..'%03d'

local RotationPoint = {
  [45]  = {x = 1,  y = 1,
           SIDE   = {Point = 'LEFT',        ParentPoint = 'TOPRIGHT'   },
           CORNER = {Point = 'BOTTOMLEFT',  ParentPoint = 'TOPRIGHT'   }},
  [90]  = {x = 1,  y = 0,
           SIDE   = {Point = 'LEFT',        ParentPoint = 'RIGHT'      },
           CORNER = {Point = 'TOPLEFT',     ParentPoint = 'TOPRIGHT'   }},
  [135] = {x = 1,  y = -1,
           SIDE   = {Point = 'LEFT',        ParentPoint = 'BOTTOMRIGHT'},
           CORNER = {Point = 'TOPLEFT',     ParentPoint = 'BOTTOMRIGHT'}},
  [180] = {x = 0,  y = -1,
           SIDE   = {Point = 'TOP',         ParentPoint = 'BOTTOM'     },
           CORNER = {Point = 'TOPLEFT',     ParentPoint = 'BOTTOMLEFT' }},
  [225] = {x = -1, y = -1,
           SIDE   = {Point = 'RIGHT',       ParentPoint = 'BOTTOMLEFT' },
           CORNER = {Point = 'TOPRIGHT',    ParentPoint = 'BOTTOMLEFT' }},
  [270] = {x = -1, y = 0,
           SIDE   = {Point = 'RIGHT',       ParentPoint = 'LEFT'       },
           CORNER = {Point = 'TOPRIGHT',    ParentPoint = 'TOPLEFT'    }},
  [315] = {x = -1, y = 1,
           SIDE   = {Point = 'RIGHT',       ParentPoint = 'TOPLEFT'    },
           CORNER = {Point = 'BOTTOMRIGHT', ParentPoint = 'TOPLEFT'    }},
  [360] = {x = 0,  y = 1,
           SIDE   = {Point = 'BOTTOM',      ParentPoint = 'TOP'        },
           CORNER = {Point = 'BOTTOMLEFT',  ParentPoint = 'TOPLEFT'    }},
}

local ValueLayout = {
  whole = '%d',
  whole_dgroups = '%s',
  thousands_dgroups = '%sk',
  millions_dgroups = '%sm',
  short_dgroups = '%s',
  percent = '%d%%',
  thousands = '%.fk',
  millions = '%.1fm',
  short = '%s',
  unitname = '%s',
  realmname = '%s',
  unitnamerealm = '%s',
  timeSS = '%d',
  timeSS_H = '%.1f',
  timeSS_HH = '%.2f',
  charges = '%d',
}

local Backdrop = {
  bgFile   = '', -- background texture
  edgeFile = '', -- border texture
  tile = true,   -- True to repeat the background texture to fill the frame, false to scale it.
  tileSize = 16,  -- Size (width or height) of the square repeating background tiles (in pixels).
  edgeSize = 12,  -- Thickness of edge segments and square size of edge corners (in pixels).
  insets = {      -- Positive values shrink the border inwards, negative expand it outwards.
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

local FrameBorder = {
  bgFile   = '',
  edgeFile = [[Interface\Addons\GalvinUnitBars\Textures\GUB_SquareBorder.tga]],
  tile = true,
  tileSize = 16,
  edgeSize = 6,
  insets = {
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Utility
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- NextBox
--
-- Iterates thru each box or returns just one box.
--
-- BarDB       The bar you want to iterate through.
-- BoxNumber   If 0 then iterates thru all the boxes. Otherwise returns just that box.
--
-- Returns:
--   BoxFrame  Current box frame.
--   Index     BoxNumber of BoxFrame.
--
-- Flags:
--   LastBox   If true then you're at the last box.
-------------------------------------------------------------------------------
local function NextBox(BarDB, BoxNumber)
  if LastBox then
    if BoxNumber ~= 0 then
      return BarDB.BoxFrames[BoxNumber], BoxNumber
    else

      -- Set up iteration
      LastBox = false
      NextBoxFrame = 0
      BoxFrames = BarDB.BoxFrames
    end
  end

  NextBoxFrame = NextBoxFrame + 1
  if NextBoxFrame == BarDB.NumBoxes then
    LastBox = true
  end
  return BoxFrames[NextBoxFrame], NextBoxFrame
end

-------------------------------------------------------------------------------
-- RotateSpark
--
-- Rotates the spark based on the texture direction.
--
-- Texture     Texture that contains the spark texture
-------------------------------------------------------------------------------
local function RotateSpark(Texture)
  local Spark = Texture.Spark
  if Texture.Spark then
    if Texture.FillDirection == 'VERTICAL' then

      -- Rotate 90 degrees.
      Spark:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
    else

      -- Rotate back to normal.
      Spark:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
    end
  end
end

-------------------------------------------------------------------------------
-- SetTopFrame
--
-- Keeps track of the top frame.
--
-- Frame     TextureFrame or StatusBar to get the framelevel of.
-------------------------------------------------------------------------------
local function SetTopFrame(BarDB, Frame)
  if Frame:GetFrameLevel() > BarDB.TopFrame:GetFrameLevel() then
    BarDB.TopFrame = Frame
  end
end

-------------------------------------------------------------------------------
-- SetVirtualFrameLevel
--
-- Creates a virtual frame level.  Each virtual frame level has a Base which
-- is the frame level it was created with.  If you call it again with another
-- frame level it will store it under highest.  And highest only gets updated
-- if a higher frame level was set again.
--
-- NOTES:  You can't go back and create a new virtual frame level lower than
--         one already created.
-------------------------------------------------------------------------------
local function SetVirtualFrameLevel(VirtualLevel, Level)
  if VirtualFrameLevels == nil then
    VirtualFrameLevels = {}
  end
  local VirtualFrameLevel = VirtualFrameLevels[VirtualLevel]

  if VirtualFrameLevel == nil then
    VirtualFrameLevel = {}
    VirtualFrameLevels[VirtualLevel] = VirtualFrameLevel
  end

  if VirtualFrameLevel.Base == nil then
    VirtualFrameLevel.Base = Level
  end
  if (VirtualFrameLevel.Highest or 0) <= Level then
    VirtualFrameLevel.Highest = Level
  end
end

-------------------------------------------------------------------------------
-- GetVirtualFrameLevel
--
-- Gets a frame level from the an existing virtual frame level or a new frame level.
--
-- If the VirtualLevel doesn't exist then it will return a frame level higher
-- than any frame level in the existing frame levels.  If the virtual frame does
-- exist then it returns the base level.
-------------------------------------------------------------------------------
local function GetVirtualFrameLevel(VirtualLevel)
  if VirtualFrameLevels == nil then
    return 0
  else
    local VirtualFrameLevel = VirtualFrameLevels[VirtualLevel]

    if VirtualFrameLevel then
      return VirtualFrameLevel.Base
    else
      -- Search for the higehst frame level
      local HighestLevel = 0

      for _, VirtualFrameLevel in pairs(VirtualFrameLevels) do
        if VirtualFrameLevel.Highest > HighestLevel then
          HighestLevel = VirtualFrameLevel.Highest
        end
      end
      return HighestLevel + 1
    end
  end
end

-------------------------------------------------------------------------------
-- SetColor
--
-- Saves color to be retrived with GetColor
--
-- Object       Object to save the color to.
-- Name         Name that the color was saved under.
-- r, g, b, a   red, green, blue, alpha
--
-- NOTES: All zeros and alpha 1 gets returned if SetColor wasn't called first.
-------------------------------------------------------------------------------
local function SetColor(Object, Name, r, g, b, a)
  local Colors = Object.Colors

  if Colors == nil then
    Colors = {}
    Object.Colors = Colors
  end
  local Color = Colors[Name]

  if Color == nil then
    Color = {}
    Colors[Name] = Color
  end
  Color.r, Color.g, Color.b, Color.a = r, g, b, a
end

-------------------------------------------------------------------------------
-- GetColor
--
-- Returns color set from SetColor()
--
-- Object        Object that color was saved to with SetColor()
-- Name          Name that the color was saved under.
--
-- Returns:
--   r, g, b, a
--
-- NOTES: All zeros and alpha 1 gets returned if SetColor wasn't called first.
-------------------------------------------------------------------------------
local function GetColor(Object, Name)
  local Colors = Object.Colors

  if Colors then
    local Color = Colors[Name]

    if Color then
      return Color.r, Color.g, Color.b, Color.a
    end
  end
  return 0, 0, 0, 1
end

-------------------------------------------------------------------------------
-- CreateBackdrop
--
-- Creates a backdrop from a backdrop settings table.
--
-- Bd               Backdrop settings table.  Look in main.lua defualt table
--                  for the format.
--
-- Returns:
--   Backdrop       Backdrop that can be used with SetBackdrop().  Do not
--                  modify this table.
--
-- NOTES:  If the Bd is not a backdrop settings table, then the table will
--         be returned.  This is so backdrop functions can use a native
--         backdrop instead.
-------------------------------------------------------------------------------
local function CreateBackdrop(Bd)
  if Bd.BgTexture == nil then

    -- return table since its not a backdrop settings table.
    return Bd
  else
    Backdrop.bgFile   = LSM:Fetch('background', Bd.BgTexture)
    Backdrop.edgeFile = LSM:Fetch('border', Bd.BdTexture)
    Backdrop.tile = Bd.BgTile
    Backdrop.tileSize = Bd.BgTileSize
    Backdrop.edgeSize = Bd.BdSize

    local Insets = Backdrop.insets
    local Padding = Bd.Padding

    Insets.left = Padding.Left
    Insets.right = Padding.Right
    Insets.top = Padding.Top
    Insets.bottom = Padding.Bottom

    return Backdrop
  end
end

-------------------------------------------------------------------------------
-- GetRect
--
-- Returns a frames position relative to its parent.
--
-- Frame       Frame to get the location info from.
--
-- OffsetX     Amount of offset to apply to the x location.
-- OffsetY     Amount of offset to apply to the y location
--
-- Returns:
--   x, y      Unscaled coordinates of Frame. Location is based from 'TOPLEFT' of
--             Frame:GetParent()
--   Width     Unscaled Width of the frame.
--   Height    Unscaled Height of the frame.
-------------------------------------------------------------------------------
local function GetRect(Frame, OffsetX, OffsetY)

  -- Calc frame location
  local ParentFrame = Frame:GetParent()

  -- Get left and top bounds of parent.
  local ParentLeft = ParentFrame:GetLeft()
  local ParentTop = ParentFrame:GetTop()

  -- Scale left and top bounds of child frame.
  local Scale = Frame:GetScale()
  local Left = Frame:GetLeft() * Scale
  local Top = Frame:GetTop() * Scale

  -- Convert bounds into a TOPLEFT anchor point, x, y.
  -- Add offsets. Then descale.
  local x = (Left - ParentLeft + (OffsetX or 0)) / Scale
  local y = (Top - ParentTop + (OffsetY or 0)) / Scale

  return x, y, Frame:GetWidth(), Frame:GetHeight()
end

function GUB.Bar:GetRect(Frame, OffsetX, OffsetY)
  return GetRect(Frame, OffsetX, OffsetY)
end

-------------------------------------------------------------------------------
-- GetBoundsRect
--
-- Gets the bounding rect of its children not including its parent.
--
-- ParentFrame   Frame containing the child frames.
-- Frames        Table of frames that belong to ParentFrame
--
-- NOTES: Hidden frames will not be included.
--        if no children found or no visible child frames, then nil gets returned.
--        Frames don't have to be a parent of ParentFrame.
--        Return values are not scaled.
-------------------------------------------------------------------------------
local function GetBoundsRect(ParentFrame, Frames)
  local Left = nil
  local Right = nil
  local Top = nil
  local Bottom = nil
  local LastLeft = nil
  local LastRight = nil
  local LastTop = nil
  local LastBottom = nil
  local FirstFrame = true

  -- For some reason ParentFrame:GetLeft() doesn't work right unless
  -- its called before dealing with child frame.
  local ParentLeft = ParentFrame:GetLeft()
  local ParentTop = ParentFrame:GetTop()

  for Index = 1, #Frames do
    local Frame = Frames[Index]

    if not Frame.Hidden and (Frame.Bound == nil or Frame.Bound) then
      local Scale = Frame:GetScale()

      Left = Frame:GetLeft() * Scale
      Right = Frame:GetRight() * Scale
      Top = Frame:GetTop() * Scale
      Bottom = Frame:GetBottom() * Scale

      if not FirstFrame  then
        Left = Left < LastLeft and Left or LastLeft
        Right = Right > LastRight and Right or LastRight
        Top = Top > LastTop and Top or LastTop
        Bottom = Bottom < LastBottom and Bottom or LastBottom
      else
        FirstFrame = false
      end

      LastLeft = Left
      LastRight = Right
      LastTop = Top
      LastBottom = Bottom
    end
  end

  if not FirstFrame then
    local x = Left - ParentLeft
    local y = Top - ParentTop

    return x, y, Right - Left, Top - Bottom
  else

    -- No frames found that were visible. return nil
    return nil, nil, nil, nil
  end
end

-------------------------------------------------------------------------------
-- SetFrames
--
-- Sets all frames points relative to their parent without moving them unless
-- an offset is applied.
--
-- ParentFrame   If specified then any Frames that are anchored to ParentFrame
--               will get their anchored changed and offsetted.
-- OffsetX  Amount of horizontal offset.
-- OffsetY  Amount of vertical offset.
--
-- NOTES: The reason for two loops is incase the frames have been setpoint to
-- another frame.  So we need to get all the locations first then set their
-- points again
-------------------------------------------------------------------------------
local function SetFrames(ParentFrame, Frames, OffsetX, OffsetY)
  local SetParent = false
  local PointFrame = nil
  local NumFrames = #Frames

  -- get all the points for each boxframe that will be relative to parent frame.
  for Index = 1, NumFrames do
    local Frame = Frames[Index]

    Frame.x, Frame.y = GetRect(Frame, OffsetX, OffsetY)
  end

  -- Set all frames using TOPLEFT point.
  for Index = 1, NumFrames do
    local Frame = Frames[Index]

    if ParentFrame then
      _, PointFrame = Frame:GetPoint()
    end
    -- If pointFrame is not nil then check to see if Frame is not setpoint to its self.
    if ParentFrame == nil or PointFrame == ParentFrame then

      -- Get x, y of BoxFrame thats relative to their parent.
      Frame:ClearAllPoints()
      Frame:SetPoint('TOPLEFT', Frame.x, Frame.y)
    end
  end
end

-------------------------------------------------------------------------------
-- BoxInfo
--
-- Returns bar, box location.  Box index information
--
-- Drag     If true then return the x, y location of the box while dragged.
-- BarDB    Current Bar
-- BF       BoxFrame
-------------------------------------------------------------------------------
local function BoxInfo(Frame)
  if not Main.UnitBars.HideLocationInfo then
    local BarDB = Frame.BarDB
    local BarX, BarY = GetRect(BarDB.Anchor)
    local BoxX, BoxY = 0, 0

    BarX, BarY = floor(BarX + 0.5), floor(BarY + 0.5)

    if Frame.BF then
      local BF = Frame.BF
      BoxX, BoxY = GetRect(BF)
      BoxX, BoxY = floor(BoxX + 0.5), floor(BoxY + 0.5)

      return format('Bar (%d, %d)  Box (%d, %d)', BarX, BarY, BoxX, BoxY)
    else
      return format('Bar (%d, %d)', BarX, BarY)
    end
  end
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Moving/Setscript functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- ShowTooltip
--
-- For onenter.
-------------------------------------------------------------------------------
local function ShowTooltip(self)
  local BarDB = self.BarDB
  local Drag = BarDB.Swap or BarDB.Float

  if self == BarDB.Region then
    Main:ShowTooltip(self, true, self.Name, BoxInfo(self))
  else
    Main:ShowTooltip(self, true, self.BF.Name, Drag and DragObjectMouseOverDesc or '', BoxInfo(self))
  end
end

------------------------------------------------------------------------------
-- HideTooltip
--
-- For onleave.
------------------------------------------------------------------------------
local function HideTooltip()
  Main:ShowTooltip()
end

-------------------------------------------------------------------------------
-- StartMoving
-------------------------------------------------------------------------------
local function StartMoving(self, Button)

  -- Check to see if we didn't move the bar.
  if not Main:UnitBarStartMoving(self.Anchor, Button) then

    -- Check to if its a boxframe shift/alt/control and left button are held down
    if Button == 'RightButton' and IsModifierKeyDown() then
      local BarDB = self.BarDB

      -- Ignore move if Swap and Float are both false.
      if self.BF and (BarDB.Swap or BarDB.Float) then
        self.IsMoving = true
        Main:MoveFrameStart(BarDB.BoxFrames, self, BarDB)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- StopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
-------------------------------------------------------------------------------
local function StopMoving(self)

  -- Check to see if the bar was being moved.
  if not Main:UnitBarStopMoving(self.Anchor) then
    if self.IsMoving then
      self.IsMoving = false
      local BarDB = self.BarDB
      local SelectFrame = Main:MoveFrameStop(BarDB.BoxFrames)

      if SelectFrame then

        -- swapping in normal mode.
        if not BarDB.Float then

          -- Create box order if one doesn't exist.
          local UB = BarDB.UnitBarF.UnitBar
          local BoxOrder = UB.BoxOrder
          local NumBoxes = BarDB.NumBoxes
          local BoxNumber = self.BoxNumber
          local SelectedBoxNumber = SelectFrame.BoxNumber

          if BoxOrder == nil then
            BoxOrder = {}
            UB.BoxOrder = BoxOrder
            for Index = 1, NumBoxes do
              BoxOrder[Index] = Index
            end
          end

          -- Find the box index numbers first.
          local Index1 = nil
          local Index2 = nil
          for Index = 1, NumBoxes do
            local BoxIndex = BoxOrder[Index]

            if BoxNumber == BoxIndex then
              Index1 = Index
            elseif SelectedBoxNumber == BoxIndex then
              Index2 = Index
            end
          end
          BoxOrder[Index1], BoxOrder[Index2] = BoxOrder[Index2], BoxOrder[Index1]
        end
      end
      self.BarDB:Display()
    end
  end
end

-------------------------------------------------------------------------------
-- EnableMouseClicksRegion
--
-- Allows the region to interact with the mouse.
--
-- Enable     if true then the region can be clicked and moved.
-------------------------------------------------------------------------------
function BarDB:EnableMouseClicksRegion(Enable)
  local Region = self.Region

  if Region:GetScript('OnMouseDown') == nil then
    Region.Anchor = self.Anchor
    Region.BarDB = self

    Region:SetScript('OnMouseDown', StartMoving)
    Region:SetScript('OnMouseUp', StopMoving)
    Region:SetScript('OnHide', StopMoving)
  end
  Region:EnableMouse(Enable)
end

-------------------------------------------------------------------------------
-- EnableMouseClicks
--
-- Allows the boxframe or textureframe to interact with the mouse.
--
-- BoxNumber            BoxFrame to enable for mouse.
-- TextureFrameNumber   If not nil then TextureFrame will be used instead.
-- Enable               If true thne the frame can interact with the mouse.
-------------------------------------------------------------------------------
function BarDB:EnableMouseClicks(BoxNumber, TextureFrameNumber, Enable)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)
    local Frame = nil

    if TextureFrameNumber then
      Frame = BoxFrame.TextureFrames[TextureFrameNumber]
    else
      Frame = BoxFrame
    end
    if Frame:GetScript('OnMouseDown') == nil then
      Frame.Anchor = self.Anchor
      Frame.BarDB = self
      Frame.BF = BoxFrame

      Frame:SetScript('OnMouseDown', StartMoving)
      Frame:SetScript('OnMouseUp', StopMoving)
      Frame:SetScript('OnHide', StopMoving)
    end
    Frame:EnableMouse(Enable)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetTooltipRegion
--
-- Set tooltip for the bars region.
--
-- Name      Name of the tooltip.
--
-- This tooltip will appear when the bars region is visible.
-------------------------------------------------------------------------------
function BarDB:SetTooltipRegion(Name)
  local Region = self.Region

  Region.BarDB = self
  Region.Name = Name
  if Region:GetScript('OnEnter') == nil then
    Region:SetScript('OnEnter', ShowTooltip)
    Region:SetScript('OnLeave', HideTooltip)
  end
end

-------------------------------------------------------------------------------
-- SetTooltip
--
-- Set tooltips to be shown on a boxframe or texture frame.
--
-- BoxNumber            Box frame to add a tooltip too.
-- TextureFrameNumber   if not nil then texture frame is used instead.
-- Name                 Name that will appear in the tooltip.
--
-- NOTES: The name is set to the boxframe.
-------------------------------------------------------------------------------
function BarDB:SetTooltip(BoxNumber, TextureFrameNumber, Name)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)
    local Frame = nil

    if TextureFrameNumber then
      Frame = BoxFrame.TextureFrames[TextureFrameNumber]
    else
      Frame = BoxFrame
    end
    Frame.BarDB = self
    Frame.BF = BoxFrame
    BoxFrame.Name = Name
    if Frame:GetScript('OnEnter') == nil then
      Frame:SetScript('OnEnter', ShowTooltip)
      Frame:SetScript('OnLeave', HideTooltip)
    end
  until LastBox
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Display functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- Display
--
-- Displays the bar. This needs to be called when ever anything causes something
-- to move or change size.
-------------------------------------------------------------------------------
local function OnUpdate_Display(self)
  self:SetScript('OnUpdate', nil)

  local ProfileChanged = self.ProfileChanged
  self.ProfileChanged = false

  local UBF = self.UnitBarF
  local UB = UBF.UnitBar

  local BoxLocations = UB.BoxLocations
  local BoxOrder = UB.BoxOrder

  local BoxFrames = self.BoxFrames
  local Region = self.Region
  local BoxBorder = self.BoxBorder

  local NumBoxes = self.NumBoxes
  local BorderPadding = self.BorderPadding
  local Rotation = self.Rotation
  local Slope = self.Slope
  local Justify = self.Justify
  local Float = self.Float
  local RegionEnabled = self.RegionEnabled

  local BoxFrameIndex = 0
  local FirstBF = nil
  local LastBF = nil

  local RP = RotationPoint[Rotation]
  local Point = RP[Justify].Point
  local ParentPoint = RP[Justify].ParentPoint

  -- PadX, PadY sets x or y to zero based on the rotation.
  local PadX = RP.x
  local PadY = RP.y

  -- Check if we're displaying in float for the first time.
  if ProfileChanged then
    self.OldFloat = nil
  end
  local FloatFirstTime = self.OldFloat ~= Float and Float
  self.OldFloat = Float

  -- Draw the box frames.
  for Index = 1, NumBoxes do
    local BoxIndex = BoxOrder and BoxOrder[Index] or Index
    local BF = BoxFrames[BoxIndex]

    if not BF.Hidden or BF.NoFrames then

      -- Get the bounding rect of the childframes of boxframe.
      local TextureFrames = BF.TextureFrames
      local OX, OY, Width, Height = GetBoundsRect(BF, TextureFrames)

      -- Hide or show the boxframe based on children found.  So bar
      -- size gets correctly calculated at the bottom of this function.
      if OX == nil then
        BF:Hide()
        BF.Hidden = true
        BF.NoFrames = true
      else
        BF:Show()
        BF.Hidden = false
        BF.NoFrames = nil

        -- Boxframe has childframes so continue.
        BoxFrameIndex = BoxFrameIndex + 1

        -- offset the child frames so their at the topleft corner of BoxFrame.
        -- But keep setpoints to other textureframes intact.
        SetFrames(BF, TextureFrames, OX * -1, OY * -1)
        BF:SetSize(Width, Height)

        if BoxLocations == nil or not Float then
          BF:ClearAllPoints(BF)
          BF.BoxIndex = BoxFrameIndex
          if BoxFrameIndex == 1 then
            BF:SetPoint('CENTER', BoxBorder, 'TOPLEFT')
          else
            local BoxPadding = BF.Padding
            local BoxPaddingX = BoxPadding * PadX
            local BoxPaddingY = BoxPadding * PadY

            -- Calculate slope
            if Rotation % 90 == 0 then
              if Rotation == 360 or Rotation == 180 then
                BoxPaddingX = BoxPaddingX + Slope
              else
                BoxPaddingY = BoxPaddingY + Slope
              end
            end

            BF:SetPoint(Point, LastBF, ParentPoint, BoxPaddingX, BoxPaddingY)
          end
          if FirstBF == nil then
            FirstBF = BF
          end
          LastBF = BF
        end
      end
    end
    if BoxLocations ~= nil and Float then

      -- in floating mode.
      local BL = BoxLocations[BoxIndex]

      -- Box locations that are nil will get displayed in the upper left.
      if FloatFirstTime then
        BF:ClearAllPoints()
        BF:SetPoint('TOPLEFT', BL.x, BL.y)
      else
        BL.x, BL.y = GetRect(BF)
      end
    end
  end

  -- Do any align padding
  if BoxLocations == nil and Float or ProfileChanged then
    Main:MoveFrameSetAlignPadding(BoxFrames, 'reset')
  elseif BoxLocations ~= nil and Float and not FloatFirstTime and self.Align then
    Main:MoveFrameSetAlignPadding(BoxFrames, self.AlignPaddingX, self.AlignPaddingY, self.AlignOffsetX, self.AlignOffsetY)
  end

  -- Calculate for offset.
  local OffsetX, OffsetY, Width, Height = GetBoundsRect(BoxBorder, BoxFrames)

  -- No visible boxframes found.
  if OffsetX == nil then
    OffsetX, OffsetY, Width, Height = 0, 0, 1, 1
  end

  -- If the region is hidden then set no padding.
  if Region.Hidden or not RegionEnabled then
    BorderPadding = 0
  end

  -- Set region to fit bar.  Includes border padding.
  Width = Width + BorderPadding * 2
  Height = Height + BorderPadding * 2
  Region:SetSize(Width, Height)

  SetFrames(nil, BoxFrames, OffsetX * -1 + BorderPadding, OffsetY * -1 - BorderPadding)
  UBF:SetSize(Width, Height)

  if Float then
    if BoxLocations then

      -- Offset unitbar so the boxes don't move. Shift bar to the left and up based on borderpadding.
      UBF:SetSize(Width, Height, OffsetX + BorderPadding * -1, OffsetY + BorderPadding)
    else
      BoxLocations = {}
      UB.BoxLocations = BoxLocations
    end
    local x = 0
    for Index = 1, NumBoxes do
      local BF = BoxFrames[Index]
      local BL = BoxLocations[Index]

      if BL == nil then
        BL = {}
        BoxLocations[Index] = BL

        -- Frame is hidden, but doesn't have a BL entry so create one.
        if BF.Hidden then
          local Height = BF:GetHeight()

          BF:SetPoint('TOPLEFT', x, Height)
          BF.x, BF.y = x, Height
          x = x + BF:GetWidth() + 5
        end
      end

      -- Set a reference to boxframe for dragging.
      BL.x, BL.y = BF.x, BF.y
    end
  end
end

function BarDB:Display()
  self.ProfileChanged = Main.ProfileChanged
  self:SetScript('OnUpdate', OnUpdate_Display)
end

-------------------------------------------------------------------------------
-- SetHiddenRegion
--
-- Hides or show the region for the bar
--
-- Hide if true the hidden is hidden otherwise shown.
-------------------------------------------------------------------------------
function BarDB:SetHiddenRegion(Hide)
  local Region = self.Region

  if self.RegionEnabled then
    if Hide == nil or Hide then
      Region:Hide()
    else
      Region:Show()
    end
  end
  Region.Hidden = Hide
end

-------------------------------------------------------------------------------
-- EnableRegion
--
-- Disables or enables the bar region
--
-- Enabled    if true the region is shown and ShowRegion and HideRegion work again.
--            if false the region is hidden and ShowRegion and HideRegion no longer work.
--
-- NOTES:  HideRegion and ShowRegion will still update the state of the region.  Its just not
--         shown.  Once the region is enabled its state is restored on screen.
-------------------------------------------------------------------------------
function BarDB:EnableRegion(Enabled)
  self.RegionEnabled = Enabled
  local Region = self.Region

  if not Enabled then
    Region:Hide()
  elseif not Region.Hidden then
    Region:Show()
  end
end

-------------------------------------------------------------------------------
-- SetHidden
--
-- Hide or show a boxframe or a texture frame.
--
-- BoxNumber            Box containing the texture frame.
-- TextureFrameNumber   If not nil then the textureframe gets shown.
-- Hide                 true to hide false to show.
-------------------------------------------------------------------------------
function BarDB:SetHidden(BoxNumber, TextureFrameNumber, Hide)
  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber]
    end

    if Hide then
      Frame:Hide()
    else
      Frame:Show()
    end
    Frame.Hidden = Hide
  until LastBox
end

-------------------------------------------------------------------------------
-- ShowRowTextureFrame
--
-- Hides everything but a row of textureframes.
--
-- TextureFrameNumber       TextureFrame to make visible across all boxes.
-------------------------------------------------------------------------------
function BarDB:ShowRowTextureFrame(TextureFrameNumber)
  repeat
    local BoxFrame = NextBox(self, 0)

    for Index, TF in pairs(BoxFrame.TextureFrames) do
      if Index ~= TextureFrameNumber then
        TF:Hide()
        TF.Hidden = true
      else
        TF:Show()
        TF.Hidden = false
      end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetHiddenTexture
--
-- hides a texture
--
-- BoxNumber       Box containing the texture frame.
-- TextureNumber   Texture to show.
-------------------------------------------------------------------------------
function BarDB:SetHiddenTexture(BoxNumber, TextureNumber, Hide)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local Hidden = Texture.Hidden

    if Hide ~= Hidden then
      local Fade = Texture.Fade

      if Hide then
        if Fade and Texture.FadeOutTime > 0 then
          -- Fadeout the texture frame then hide it.
          Fade:SetAnimation('out')
        else
          Texture:Hide()
        end
        Texture.Hidden = true
      else
        if Fade and Texture.FadeInTime > 0 then

          -- Fade in the texture.
          Fade:SetAnimation('in')
        else
          Texture:Show()
        end
        Texture.Hidden = false
      end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- StopFadeTexture
--
-- Stops fade in or fade out animation playing in the texture.
--
-- BoxNumber       Box containing the texture.
-- TextureNumber   Texture containing the fade.
-------------------------------------------------------------------------------
function BarDB:StopFadeTexture(BoxNumber, TextureNumber)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local Fade = Texture.Fade

    if Fade then
      Fade:SetAnimation('stop')
    end
  until LastBox
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Setting BAR functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetBackdropRegion
--
-- Sets the backdrop for the bars region.
--
-- BackdropSettings    Backdrop to set for the bar
--                     This can also be a wow formatted backdrop table.
-------------------------------------------------------------------------------
function BarDB:SetBackdropRegion(BackdropSettings)
  local Region = self.Region

  Region:SetBackdrop(CreateBackdrop(BackdropSettings))

  -- Need to set color since it gets lost when setting backdrop.
  Region:SetBackdropColor(GetColor(Region, 'backdrop'))
end

-------------------------------------------------------------------------------
-- SetBackdropColorRegion
--
-- Sets the color of the backdrop for the bar's region.
--
-- r, g, b, a     red, green, blue, alpha
-------------------------------------------------------------------------------
function BarDB:SetBackdropColorRegion(r, g, b, a)
  local Region = self.Region
  Region:SetBackdropColor(r, g, b, a)
  SetColor(Region, 'backdrop', r, g, b, a)
end

-------------------------------------------------------------------------------
-- SetBackdropBorderColorRegion
--
-- Sets the backdrop edge color of the bars region.
--
-- r, g, b, a              red, green, blue, alpha
-------------------------------------------------------------------------------
function BarDB:SetBackdropEdgeColorRegion(r, g, b, a)
  self.Region:SetBackdropBorderColor(r, g, b, a)
end

-------------------------------------------------------------------------------
-- SetSlopeBar
--
-- Sets the slope of a bar that has an rotation of vertical or horizontal.
--
-- Slope             Any value negative number will reverse the slop.
-------------------------------------------------------------------------------
function BarDB:SetSlopeBar(Slope)
  self.Slope = Slope
end

-------------------------------------------------------------------------------
-- SetPaddingBorder
--
-- Sets the padding between the boxframes and the bar region border
--
-- BorderPadding    Amount of padding to use.
-------------------------------------------------------------------------------
function BarDB:SetPaddingBorder(BorderPadding)
  self.BorderPadding = BorderPadding
end

--------------------------------------------------------------------------------
-- SetRotationBar
--
-- Sets the rotation the bar will be displayed in.
--
-- Rotation     Must be 45, 90, 135, 180, 225, 270, 315, or 360.
-------------------------------------------------------------------------------
function BarDB:SetRotationBar(Rotation)
  self.Rotation = Rotation
end

-------------------------------------------------------------------------------
-- SetJustifyBar
--
-- Sets the justification of the boxframes when displayed.
--
-- Justify      Can be 'SIDE' or 'CORNER'
-------------------------------------------------------------------------------
function BarDB:SetJustifyBar(Justify)
  self.Justify = Justify
end

-------------------------------------------------------------------------------
-- SetSwapBar
--
-- Sets the bar to allow the boxes to be swapped with eachoher by dragging one
-- over the other.
-------------------------------------------------------------------------------
function BarDB:SetSwapBar(Swap)
  self.Swap = Swap
end

-------------------------------------------------------------------------------
-- SetAlignBar
--
-- Enables or disables alignment for boxes.
-------------------------------------------------------------------------------
function BarDB:SetAlignBar(Align)
  self.Align = Align

  if not Align then
    Main:MoveFrameSetAlignPadding(self.BoxFrames, 'reset')
  end
end

-------------------------------------------------------------------------------
-- SetAlignOffsetBar
--
-- Offsets the aligned group of boxes
--
-- OffsetX      Horizontal alignment, if nil then not set.
-- OffsetY      Vertical alignment, if nil then not set.
-------------------------------------------------------------------------------
function BarDB:SetAlignOffsetBar(OffsetX, OffsetY)
  if OffsetX then
    self.AlignOffsetX = OffsetX
  end
  if OffsetY then
    self.AlignOffsetY = OffsetY
  end
end

-------------------------------------------------------------------------------
-- SetAlignPaddingBar
--
-- Sets the amount distance when aligning a box with another box.
--
-- PaddingX     Sets the amount of distance between two or more horizontal aligned boxes.
-- PaddingY     Sets the amount of distance between two or more vertical aligned boxes.
-------------------------------------------------------------------------------
function BarDB:SetAlignPaddingBar(PaddingX, PaddingY)
  if PaddingX then
    self.AlignPaddingX = PaddingX
  end
  if PaddingY then
    self.AlignPaddingY = PaddingY
  end
end

-------------------------------------------------------------------------------
-- SetFloatBar
--
-- Sets the bar to float which allows the boxes to be moved anywhere.
-------------------------------------------------------------------------------
function BarDB:SetFloatBar(Float)
  self.Float = Float
end

-------------------------------------------------------------------------------
-- ResetFloatBar()
--
-- Resets the floating layout by copying the none floating layout to float.
-- Same as going to float for the first time.
-------------------------------------------------------------------------------
function BarDB:ResetFloatBar()
  self.UnitBarF.UnitBar.BoxLocations = nil
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Setting Box Frame functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetPaddingBox
--
-- Sets the amount of padding between the boxframes.
--
-- BoxNumber    Box to set the distance bewteen the next boxframe.
-- Padding      Amount of distance to set
-------------------------------------------------------------------------------
function BarDB:SetPaddingBox(BoxNumber, Padding)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)

    BoxFrame.Padding = Padding
  until LastBox
end

-------------------------------------------------------------------------------
-- SetChangeBox
--
-- Sets one or more boxes so they can be changed easily
--
-- ChangeNumber         Number to assign multiple boxnumbers to.
-- ...                  One or more boxnumbers.
-------------------------------------------------------------------------------
function BarDB:SetChangeBox(ChangeNumber, ...)
  local ChangeBoxes = self.ChangeBoxes

  if ChangeBoxes == nil then
    ChangeBoxes = {}
    self.ChangeBoxes = ChangeBoxes
  end
  local ChangeBox = ChangeBoxes[ChangeNumber]

  if ChangeBox == nil then
    ChangeBox = {}
    ChangeBoxes[ChangeNumber] = ChangeBox
  end
  for Index = 1, select('#', ...) do
    ChangeBox[Index] = select(Index, ...)
  end
  ChangeBoxes[#ChangeBoxes + 1] = nil
end

-------------------------------------------------------------------------------
-- ChangeBox
--
-- Changes a texture based on boxnumber.  SetChange must be called prior.
--
-- ChangeNumber         Number you assigned the box numbers to.
-- BarFunction          Bar function that can be called by BarDB:Function
--                      Must be a function that can take a boxnumber.
--                      Function must be a string.
-- ...                  1 or more values passed to Function
--
-- Example:       BarDB:SetChangeBox(2, MyBoxFrameNumber)
--                BarDB:ChangeBox(2, 'SetFillTexture', Value)
--                This would be the same as:
--                BarDB:SetFillTexture(MyBoxNumber, Value)
-------------------------------------------------------------------------------
function BarDB:ChangeBox(ChangeNumber, BarFunction, ...)
  local Fn = self[BarFunction]
  local BoxNumbers = self.ChangeBoxes[ChangeNumber]

  for Index = 1, #BoxNumbers do
    Fn(self, BoxNumbers[Index], ...)
  end
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Setting Box Frame/Texture Frame functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetBackdrop
--
-- Sets a backdrop for a boxframe or textureframe.
--
-- BoxNumber             Box you want to set the backdrop.
-- TextureFrameNumber    If not nil then the backdrop will be set to the textureframe instead
-- BackdropSettings      Backdrop settings table.  Can also be a wow formatted backdrop table.
-------------------------------------------------------------------------------
function BarDB:SetBackdrop(BoxNumber, TextureFrameNumber, BackdropSettings)
  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber]
    end
    Frame:SetBackdrop(CreateBackdrop(BackdropSettings))

    -- Need to set color since it gets lost when setting backdrop.
    Frame:SetBackdropColor(GetColor(Frame, 'backdrop'))
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropColor
--
-- Changes the color of the backdrop
--
-- BoxNumber              BoxNumber to change the backdrop color of.
-- TextureFrameNumber     If not nil then the textureframe border color will be changed.
-- r, g, b, a             red, greem, blue, alpha.
-------------------------------------------------------------------------------
function BarDB:SetBackdropColor(BoxNumber, TextureFrameNumber, r, g, b, a)
  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber]
    end
    Frame:SetBackdropColor(r, g, b, a)
    SetColor(Frame, 'backdrop', r, g, b, a)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropBorderColor
--
-- Sets a backdrop border color for a boxframe or textureframe.
--
-- BoxNumber             Box you want to set the change the backdrop border color of.
-- TextureFrameNumber    If not nil then the TextureFrame backdrop be used instead.
-- r, g, b, a            red, green, blue, alpha
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderColor(BoxNumber, TextureFrameNumber, r, g, b, a)
  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber]
    end
    Frame:SetBackdropBorderColor(r, g, b, a)
  until LastBox
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Setting Texture Frame functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetSizeTextureFrame
--
-- Sets the size of a box frame or texture frame.
--
-- BoxNumber           Box containing textureframe.
-- TextureFrameNumber  Texture frame to change size.
-- Width, Height       New width and height to set.
--
-- NOTES:  The BoxFrame will be resized to fit the new size of the TextureFrame.
-------------------------------------------------------------------------------
function BarDB:SetSizeTextureFrame(BoxNumber, TextureFrameNumber, Width, Height)
  repeat
    local TextureFrame = NextBox(self, BoxNumber).TextureFrames[TextureFrameNumber]

    TextureFrame:SetSize(Width or TextureFrame:GetWidth(), Height or TextureFrame:GetHeight())
  until LastBox
end

-------------------------------------------------------------------------------
-- SetScaleTextureFrame
--
-- Changes the scale of the box frame or texture frame making things larger or smaller.
--
-- BoxNumber              Box containing the texture frame.
-- TextureFrameNumber     Texture frame to set scale to.
-- Scale                  New scale to set.
-------------------------------------------------------------------------------
function BarDB:SetScaleTextureFrame(BoxNumber, TextureFrameNumber, Scale)
  repeat
    local TextureFrame = NextBox(self, BoxNumber).TextureFrames[TextureFrameNumber]

    local Point, RelativeFrame, RelativePoint, OffsetX, OffsetY = TextureFrame:GetPoint()
    local OldScale = TextureFrame:GetScale()

    TextureFrame:SetScale(Scale)
    TextureFrame:SetPoint(Point, RelativeFrame, RelativePoint, OffsetX * OldScale / Scale, OffsetY * OldScale / Scale)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetPointTextureFrame
--
-- Allows you to set a textureframe point to another textureframe or to the boxframe.
--
-- BoxNumber                   Box containing the texture frame.
-- TextureFrameNumber          TextureFrame to setpoint.
-- Point                       'TOP' 'LEFT' etc
-- RelativeTextureFrameNumber  TextureFrame will be setpoint to this frame.  If nil
--                             then parent BoxFrame will be used instead.
-- RelativePoint               Reference to another textureframes point.
-- OffsetX, OffsetY            Offsets from point. 0, 0 us used if nil.
--
-- NOTES:  This will only allow one point active at anytime.
--         If point is nil then the TextureFrame is set to boxframe.
-------------------------------------------------------------------------------
function BarDB:SetPointTextureFrame(BoxNumber, TextureFrameNumber, Point, RelativeTextureFrameNumber, RelativePoint, OffsetX, OffsetY)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)
    local TextureFrames = BoxFrame.TextureFrames
    local TextureFrame = TextureFrames[TextureFrameNumber]

    TextureFrame:ClearAllPoints()
    if Point == nil or type(RelativePoint) ~= 'string' then
      TextureFrame:SetPoint('TOPLEFT')
    else
      local RelativeTextureFrame = TextureFrames[RelativeTextureFrameNumber]
      local Scale = TextureFrame:GetScale()

      TextureFrame.OffsetX = OffsetX
      TextureFrame.OffsetY = OffsetY
      TextureFrame:SetPoint(Point, RelativeTextureFrame, RelativePoint, (OffsetX / Scale) or 0, (OffsetY / Scale) or 0)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBoundTextureFrame
--
-- Makes a textureframe be excluded from the bounding rectangle of its parent
-- boxframe.
--
-- Enable               If false the boxframe will not be include this texture
--                      frame in its border, otherwise it will.
-- BoxNumber            Box containing the texture frame.
-- TextureFrameNumber   TextureFrame to setpoint.
-------------------------------------------------------------------------------
function BarDB:SetBoundTextureFrame(BoxNumber, TextureFrameNumber, Enable)
  repeat
    local TextureFrame = NextBox(self, BoxNumber).TextureFrames[TextureFrameNumber]

    TextureFrame.Bound = Enable
  until LastBox
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Setting Texture functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetBackdropTexture
--
-- Sets a backdrop for a texture
--
-- BoxNumber             Box containing the texture.
-- TextureNumber         Texture to set the backdrop to.
-- BackdropSettings      Backdrop settings table.  Can also be a wow formatted backdrop table.
-------------------------------------------------------------------------------
function BarDB:SetBackdropTexture(BoxNumber, TextureNumber, BackdropSettings)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetBackdrop(CreateBackdrop(BackdropSettings))

    -- Need to set color since it gets lost when setting backdrop.
    Texture:SetBackdropColor(GetColor(Texture, 'backdrop'))
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropColorTexture
--
-- Changes the color of the backdrop for a texture.
--
-- BoxNumber             Box containing the texture.
-- TextureNumber          Texture to set the backdrop to.
-- r, g, b, a             red, greem, blue, alpha.
-------------------------------------------------------------------------------
function BarDB:SetBackdropColorTexture(BoxNumber, TextureNumber, r, g, b, a)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetBackdropColor(r, g, b, a)
    SetColor(Texture, 'backdrop', r, g, b, a)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropBorderColorTexture
--
-- Sets the backdrop border color of the textures border.
--
-- BoxNumber             Box containing the texture.
-- TextureNumber         Texture to set the backdrop to.
-- r, g, b, a            red, green, blue, alpha
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderColorTexture(BoxNumber, TextureNumber, r, g, b, a)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetBackdropBorderColor(r, g, b, a)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetChangeTexture
--
-- Sets one or more textures so they can be changed easily
--
-- ChangeNumber         Number to assign multiple textures to.
-- ...                  One or more texturenumbers.
-------------------------------------------------------------------------------
function BarDB:SetChangeTexture(ChangeNumber, ...)
  local ChangeTextures = self.ChangeTextures

  if ChangeTextures == nil then
    ChangeTextures = {}
    self.ChangeTextures = ChangeTextures
  end
  local ChangeTexture = ChangeTextures[ChangeNumber]

  if ChangeTexture == nil then
    ChangeTexture = {}
    ChangeTextures[ChangeNumber] = ChangeTexture
  end
  for Index = 1, select('#', ...) do
    ChangeTexture[Index] = select(Index, ...)
  end
  ChangeTexture[#ChangeTexture + 1] = nil
end

-------------------------------------------------------------------------------
-- ChangeTexture
--
-- Changes a texture based on boxnumber.  SetChange must be called prior.
--
-- ChangeNumber         Number you assigned the textures to.
-- BarFunction          Bar function that can be called by BarDB:Function
--                      Must be a function that can take boxnumber, texturenumber.
--                      Function must be a string.
-- BoxNumber            BoxNumber containing the texture.
-- ...                  1 or more values passed to Function
--
-- Example:       BarDB:SetChange(2, MyTextureFrameNumber)
--                BarDB:Change(2, 'SetFillTexture', Value)
--                This would be the same as:
--                BarDB:SetFillTexture(2, MyTextureFrameNumber, Value)
-------------------------------------------------------------------------------
function BarDB:ChangeTexture(ChangeNumber, BarFunction, BoxNumber, ...)
  local Fn = self[BarFunction]
  local TextureNumbers = self.ChangeTextures[ChangeNumber]

  if BoxNumber > 0 then
    for Index = 1, #TextureNumbers do
      Fn(self, BoxNumber, TextureNumbers[Index], ...)
    end
  else
    local NumTextures = #TextureNumbers

    for BoxIndex = 1, self.NumBoxes do
      for Index = 1, NumTextures do
        Fn(self, BoxNumber, TextureNumbers[Index], ...)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetPaddingTexture
--
-- BoxNumber                  Box containing the texture.
-- TextureNumber              Texture to apply padding.
-- Left, Right, Top, Bottom   Paddding values.
-------------------------------------------------------------------------------
function BarDB:SetPaddingTexture(BoxNumber, TextureNumber, Left, Right, Top, Bottom)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local SubFrame = Texture.SubFrame

    SubFrame:ClearAllPoints()
    SubFrame:SetPoint('TOPLEFT', Left, Top)
    SubFrame:SetPoint('BOTTOMRIGHT', Right, Bottom)

    local Value = Texture.Value

    -- Force the statusbar to reflect the changes.
    if Texture.Type == 'statusbar' then
      SubFrame:SetValue(Value - 1)
      SubFrame:SetValue(Value)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetRotateTexture
--
-- Rotates a status bar texture 90 degrees.
--
-- BoxNumber      Box containing the texture.
-- TextureNumber  Texture to rotate.
-- Action         true   texture is rotated
--                false  no rotation
--
-- NOTE:  Works on statusbars only.
-------------------------------------------------------------------------------
function BarDB:SetRotateTexture(BoxNumber, TextureNumber, Action)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    if Texture.Type == 'statusbar' then

      -- Need to check if statusbar:settexture was done first otherwise
      -- game client crashes.
      if Texture.SubTexture then
        Texture.SubFrame:SetRotatesTexture(Action)
      end
      Texture.RotateTexture = Action
    end
    RotateSpark(Texture)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFadeTimeTexture
--
-- BoxNumber       BoxFrame containing the texture.
-- TextureNumber   Texture to set fade for.
-- Action          'in' sets the amount of time in seconds for fading in.
--                 'out' sets the amount of time in seconds for fading out.
-- Seconds         Number of seconds to fade in or out.
-------------------------------------------------------------------------------
function BarDB:SetFadeTimeTexture(BoxNumber, TextureNumber, Action, Seconds)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local Fade = Texture.Fade

    if Seconds > 0 or Fade then

      -- Create fade if one doesn't exist.
      if Fade == nil then
        Fade = Main:CreateFade(self.UnitBarF, Texture)
        Texture.Fade = Fade
      end

      -- Set the duration of the fade in.
      Fade:SetDuration(Action, Seconds)
      if Action == 'in' then
        Texture.FadeInTime = Seconds
      else
        Texture.FadeOutTime = Seconds
      end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFill
--
-- Subfunction of SetFillTexture, SetFillTimeTexture
--
-- Texture        Texture to setfill to.
-- Value          Between 0 and 1
-- Spark          Internal use only. If not nil then a spark is shown on the
--                texture edge.
--
-- NOTE: SetFillDirectionTexture() will control the fill that this function will use.
--       Cant set texture width to 0 so use 0.001 this will make the texture not be
--       visible.  Setting texture size to 0 doesn't hide the texture.
-------------------------------------------------------------------------------
local function SetFill(Texture, Value, Spark)
  local ReverseFill = Texture.ReverseFill
  local FillDirection = Texture.FillDirection
  local Width, Height = Texture.Width, Texture.Height

  -- Flag setfill for onsizechanged.
  Texture.SetFill = 1

  if Texture.Type == 'texture' then
    local SubTexture = Texture.SubTexture
    local TexLeft, TexRight, TexTop, TexBottom = Texture.TexLeft, Texture.TexRight, Texture.TexTop, Texture.TexBottom
    local TextureWidth = Width
    local TextureHeight = Height

    -- Clip the amount if out of range.
    Value = Value > 1 and 1 or Value < 0 and 0 or Value

    -- Calculate the texture width
    if FillDirection == 'HORIZONTAL' then
      TextureWidth = Width * Value

      -- Check for reverse fill.
      if ReverseFill then
        TexLeft = TexRight - (TexRight - TexLeft) * Value
        SubTexture:SetPoint('TOPLEFT', Width - TextureWidth, 0)
      else
        TexRight = TexLeft + (TexRight - TexLeft) * Value
        SubTexture:SetPoint('TOPLEFT')
      end
    else

      -- Calculate the texture height.
      TextureHeight = Height * Value

      -- Check for reverse fill
      if ReverseFill then
        TexBottom = TexTop + (TexBottom - TexTop) * Value
        SubTexture:SetPoint('TOPLEFT')
      else
        TexTop = TexBottom - (TexBottom - TexTop) * Value
        SubTexture:SetPoint('TOPLEFT', 0, (Height - TextureHeight) * -1)
      end
    end
    SubTexture:SetSize(TextureWidth > 0 and TextureWidth or 0.001, TextureHeight > 0 and TextureHeight or 0.001)
    SubTexture:SetTexCoord(TexLeft, TexRight, TexTop, TexBottom)
  else

    -- Set statusbar value.
    Texture.SubFrame:SetValue(Value)
  end
  Texture.Value = Value

  -- Display spark if not nil
  if Spark then
    local x = nil
    local y = nil

    if FillDirection == 'HORIZONTAL' then
      y = Height * 0.5 * -1
      if ReverseFill then
        x = Width - Width * Value + 1 -- Offset spark by 1
      else
        x = Width * Value
      end

      -- Set spark size.
      Spark:SetSize(TextureSparkSize, Height * 2.3)
    else
      x = Width * 0.5
      if ReverseFill then
        y = Height * Value * -1 + 1 -- Offset spark by 1
      else
        y = (Height - Height * Value) * -1
      end

      -- Set spark size.
      Spark:SetSize(Width * 2.3, TextureSparkSize)
    end
    Spark:Show()
    Spark:SetPoint('CENTER', Spark.ParentFrame, 'TOPLEFT', x, y)
  end
end

-------------------------------------------------------------------------------
-- SetFillTimer (timer function for filling)
--
-- Subfunction of SetFillTime
--
-- Fills a bar over time
-------------------------------------------------------------------------------
local function SetFillTimer(self)
  local CurrentTime = GetTime()

  if CurrentTime >= self.StartTime then
    local TimeElapsed = CurrentTime - self.StartTime
    local Duration = self.Duration

    if TimeElapsed <= Duration then

      -- Calculate current value.
      local Value = self.StartValue + self.Range * (TimeElapsed / Duration)
      SetFill(self, Value, self.Spark)
    else

      -- Stop timer
      Main:SetTimer(self, nil)

      -- set the end value.
      SetFill(self, self.EndValue)

      -- Hide spark
      if self.Spark then
        self.Spark:Hide()
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetFillTime
--
-- Subfunction of SetFillTimeTexture
--
-- Fills a texture over a period of time.
--
-- Texture           Texture to fill over time.
-- TPS               Times per second.  This is how many times per second
--                   The timer will be called. The higher the number the smoother
--                   the animation but also the more cpu is consumed.
-- StartTime         Starting time if nil the starts instantly.
-- Duration          Time it will take to reach from StartValue to EndValue.
-- StartValue        Starting value between 0 and 1.  If nill the current value
--                   is used instead.
-- EndValue          Ending value between 0 and 1. If nill 1 is used.
-------------------------------------------------------------------------------
local function SetFillTime(Texture, TPS, StartTime, Duration, StartValue, EndValue)
  Main:SetTimer(Texture, nil)
  Duration = Duration or 0
  StartValue = StartValue and StartValue or Texture.Value
  EndValue = EndValue and EndValue or 1

  -- Only start a timer if startvalue and endvalues are not equal.
  if StartValue ~= EndValue and Duration > 0 then

    -- Set up the paramaters.
    Texture.StartTime = StartTime and StartTime or GetTime()

    Texture.Duration = Duration
    Texture.Range = EndValue - StartValue
    Texture.Value = StartValue
    Texture.StartValue = StartValue
    Texture.EndValue = EndValue

    Main:SetTimer(Texture, TPS, SetFillTimer)
  else
    local Spark = Texture.Spark

    SetFill(Texture, EndValue)
    if Spark then
      Spark:Hide()
    end
  end
end

-------------------------------------------------------------------------------
-- SetFillTimeTexture
--
-- Fills a texture over a period of time.
--
-- BoxNumber         Box containing the texture to fill over time.
-- TextureNumber     Texture being used in fill.
-- StartTime         Starting time if nil then starts instantly.
-- Duration          Time it will take to reach from StartValue to EndValue.
-- StartValue        Starting value between 0 and 1.  If nill the current value
--                   is used instead.
-- EndValue          Ending value between 0 and 1. If nill 1 is used.
--
-- NOTES:  To stop a timer just call this function with just the BoxNumber and TextureNumber
-------------------------------------------------------------------------------
function BarDB:SetFillTimeTexture(BoxNumber, TextureNumber, StartTime, Duration, StartValue, EndValue)
  local Texture = self.BoxFrames[BoxNumber].TFTextures[TextureNumber]

  SetFillTime(Texture, TextureFillTime, StartTime, Duration, StartValue, EndValue)
end

-------------------------------------------------------------------------------
-- SetFillTexture
--
-- Shows more of the texture instead of stretching.
-- Works for status bars too, but can't control texture stretching.
--
-- BoxNumber        Box containing texture to fill
-- TextureNumber    Texture to apply fill to
-- Value            A number between 0 and 1
-- ShowSpark        If true spark will be shown, else hidden.  If nil nothing.
--
-- NOTE: See SetFill().
-------------------------------------------------------------------------------
function BarDB:SetFillTexture(BoxNumber, TextureNumber, Value, ShowSpark)
  local Texture = self.BoxFrames[BoxNumber].TFTextures[TextureNumber]
  local SmoothTime = Texture.SmoothTime or 0

  -- If smoothtime > 0 then fill the texture from its current value to new value.
  if SmoothTime > 0 then
    SetFillTime(Texture, TextureSmoothFillTime, nil, SmoothTime, nil, Value)
  else
    local Spark = nil

    if ShowSpark ~= nil then
      Spark = Texture.Spark
    end
    SetFill(Texture, Value, Spark)
    if Spark and not ShowSpark then
      Spark:Hide()
    end
  end
end

-------------------------------------------------------------------------------
-- SetReverseFillTexture
--
-- Action    true         The fill will be reversed.  Right to left or top to bottom.
--           false        Default fill.  Left to right or bottom to top.
-------------------------------------------------------------------------------
function BarDB:SetFillReverseTexture(BoxNumber, TextureNumber, Action)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.ReverseFill = Action
    if Texture.Type == 'statusbar' then
      Texture.SubFrame:SetReverseFill(Action)
    else
      SetFill(Texture, Texture.Value)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillSmoothTimeTexture
--
-- Makes SetFillTexture fill a bar over time as it changes value.
-- Also sets how long it will take a bar to fill.
--
-- BoxNumber       Box containing the texture
-- TextureNumber   Texture to smooth fill on.
-- Time            If 0 then this is disabled.
-------------------------------------------------------------------------------
function BarDB:SetFillSmoothTimeTexture(BoxNumber, TextureNumber, Time)
  repeat
    NextBox(self, BoxNumber).TFTextures[TextureNumber].SmoothTime = Time
  until LastBox
end

-------------------------------------------------------------------------------
-- SetCooldownTexture
--
-- Starts a cooldown animation for the current texture.
--
-- BoxNumber        Box containing the texture to cooldown.
-- TextureNumber    Texture to cooldown.
-- StartTime        Starting time. if nill then starts instantly
-- Duration         Time it will take to cooldown the texture. I duration is 0 timer is stopped.
-- Line             If true a line will be added to the cooldown.
-- HideFlash        If true hides the flash animation.
--
-- NOTES:  To stop timer just set duration to 0
-------------------------------------------------------------------------------
local function HideFlashTimer(self, Elapsed)
  Main:SetTimer(self, nil)

  self:SetCooldown(0, 0)
  if self.HideFlash then
    self:SetBlingDuration(0)
  end
  local CooldownFrameLine = self.CooldownFrameLine
  CooldownFrameLine:SetCooldown(0, 0)
  CooldownFrameLine:SetBlingDuration(0)
end

function BarDB:SetCooldownTexture(BoxNumber, TextureNumber, StartTime, Duration, Line, HideFlash)
  local Texture = self.BoxFrames[BoxNumber].TFTextures[TextureNumber]
  local CooldownFrame = Texture.CooldownFrame
  local CooldownFrameLine = Texture.CooldownFrameLine

  if HideFlash ~= nil then
    CooldownFrame.HideFlash = HideFlash
  end

  Duration = Duration or 0
  StartTime = StartTime or 0

  CooldownFrame:SetCooldown(StartTime, Duration)

  if Line or Duration == 0 then
    CooldownFrameLine:SetCooldown(StartTime, Duration, 1, 1)
  end
  if Duration == 0 then
    if CooldownFrame.HideFlash then
      CooldownFrame:SetBlingDuration(0)
      CooldownFrameLine:SetBlingDuration(0)
    end
  else
    CooldownFrame.CooldownFrameLine = CooldownFrameLine
    Main:SetTimer(CooldownFrame, StartTime - GetTime() + Duration, HideFlashTimer)
  end
end

-------------------------------------------------------------------------------
-- SetSizeCooldownTexture
--
-- Sets the size of the cooldown animation.
--
-- BoxNumber        Box containing the cooldown texture.
-- TextureNumber    Cooldown that is used on this texture.
-- Width            Width of texture.  If nil then doesn't get set.
-- Height           Height of texture.  If nil then doesn't get set.
-- OffsetX          Offset from center for horizontal.
-- OffsetY          Offset from center for vertical.
-------------------------------------------------------------------------------
function BarDB:SetSizeCooldownTexture(BoxNumber, TextureNumber, Width, Height, OffsetX, OffsetY)
  repeat
    local Texture = self.BoxFrames[BoxNumber].TFTextures[TextureNumber]
    local CooldownFrame = Texture.CooldownFrame
    local SubTexture = Texture.SubTexture

    CooldownFrame:SetSize(Width or SubTexture:GetWidth(), Height or SubTexture:GetHeight())

    if OffsetX or OffsetY then
      CooldownFrame:SetPoint('CENTER', SubTexture, 'CENTER', OffsetX or 0, OffsetY or 0)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetHiddenSpark
--
-- Shows or hides a spark version time using SetFillTime
--
-- BoxNumber       Box containing the texture.
-- TextureNumber   Texture to apply the spark to during filling over time.
-------------------------------------------------------------------------------
function BarDB:SetHiddenSpark(BoxNumber, TextureNumber, Hide)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local Spark = Texture.Spark

    if Spark == nil then
      local SubFrame = Texture.SubFrame

      Spark = SubFrame:CreateTexture(nil, 'OVERLAY')
      Spark:SetTexture(TextureSpark)
      Spark:SetBlendMode('ADD')
      Spark.ParentFrame = SubFrame
    end

    if Hide then
      if Spark then
        Texture.HiddenSpark = Spark

        -- Make it false so setfill doesn't show it.
        Texture.Spark = false
        Spark:Hide()
      end
    else

      -- Set spark to shown status if hidden.
      if Spark == false then
        Spark = Texture.HiddenSpark
      end
      Spark:Hide()
      Texture.Spark = Spark
      RotateSpark(Texture)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillDirectionTexture
--
-- Direction    'HORIZONTAL'   Fill from left to right.
--              'VERTICAL'     Fill from bottom to top.
-------------------------------------------------------------------------------
function BarDB:SetFillDirectionTexture(BoxNumber, TextureNumber, Direction)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    if Texture.Type == 'statusbar' then
      Texture.SubFrame:SetOrientation(Direction)
    end
    Texture.FillDirection = Direction
    RotateSpark(Texture)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetColorTexture
--
-- BoxNumber       Box containging texture
-- TextureNumber   Texture to change the color of.
-- r, g, b, a      red, green, blue, alpha
-------------------------------------------------------------------------------
function BarDB:SetColorTexture(BoxNumber, TextureNumber, r, g, b, a)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    if Texture.Type == 'statusbar' then
      Texture.SubFrame:SetStatusBarColor(r, g, b, a)
      SetColor(Texture, 'statusbar', r, g, b, a)
    else
      Texture.SubTexture:SetVertexColor(r, g, b, a)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetGreyscaleTexture
--
-- Turns a texture into black and white color.
--
-- BoxNumber      Box containing texture
-- TextureNumber  Texture to change.
-- Action         true then Desaturation gets set. Otherwise not.
-------------------------------------------------------------------------------
function BarDB:SetGreyscaleTexture(BoxNumber, TextureNumber, Action)
  repeat
    NextBox(self, BoxNumber).TFTextures[TextureNumber].SubTexture:SetDesaturated(Action)

  until LastBox
end

-------------------------------------------------------------------------------
-- SetTexture
--
-- Sets the texture of a statusbar or texture.
--
-- BoxNumber         BoxNumber to change the texture in.
-- TextureNumber     Texture to change.
-- TextureName       Name if it statusbar otherwise its the path to the texture.
-------------------------------------------------------------------------------
function BarDB:SetTexture(BoxNumber, TextureNumber, TextureName)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    if Texture.Type == 'statusbar' then
      local SubFrame = Texture.SubFrame

      SubFrame:SetStatusBarTexture(LSM:Fetch('statusbar', TextureName))
      local SubTexture = SubFrame:GetStatusBarTexture()

      SubTexture:SetHorizTile(false)
      SubTexture:SetVertTile(false)
      SubFrame:SetOrientation(Texture.FillDirection)
      SubFrame:SetReverseFill(Texture.ReverseFill)
      SubFrame:SetRotatesTexture(Texture.RotateTexture)
      Texture.SubTexture = SubTexture

      SubFrame:SetStatusBarColor(GetColor(Texture, 'statusbar'))
    else
      Texture.SubTexture:SetTexture(TextureName)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- ClearAllPointsTexture
--
-- Clears all the points of a texture
--
-- BoxNumber      Box containing the texture
-- TextureNumber  Texture to clear points of.
--
-- NOTES: Works on statusbars only.
-------------------------------------------------------------------------------
function BarDB:ClearAllPointsTexture(BoxNumber, TextureNumber)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:ClearAllPoints()
  until LastBox
end

-------------------------------------------------------------------------------
-- SetPointTexture
--
-- Sets the texture location inside of the texture frame.
--
-- BoxNumber              Box containing texture.
-- TextureNumber          Texture to modify.
-- Point                  String. Point to set.
-- RelativeTextureNumber  If specified then the texture point is set relative to this texture.
--                        If nil then the parent TextureFrame is used instead.
-- RelativePoint          If specified then the texture point is set to the relative texture point.
-- OffsetX, OffsetY       X, Y offset in pixels from Point.
-------------------------------------------------------------------------------
function BarDB:SetPointTexture(BoxNumber, TextureNumber, Point, ...)
  local RelativeTextureNumber = select(1, ...)
  local RelativePoint = select(2, ...)
  local OffsetX = select(3, ...) or 0
  local OffsetY = select(4, ...) or 0
  local Relative = true

  if RelativePoint == nil or type(RelativePoint) == 'number' then
    OffsetX = RelativeTextureNumber or 0
    OffsetY = RelativePoint or 0
    Relative = false
  end
  repeat
    local TFTextures = NextBox(self, BoxNumber).TFTextures
    local Texture = TFTextures[TextureNumber]
    local Scale = Texture:GetScale()

    OffsetX = OffsetX / Scale
    OffsetY = OffsetY / Scale

    if Relative then
      if RelativeTextureNumber then
        Texture:SetPoint(Point, TFTextures[RelativeTextureNumber], RelativePoint, OffsetX, OffsetY)
      else
        Texture:SetPoint(Point, Texture:GetParent(), RelativePoint, OffsetX, OffsetY)
      end
    else
      Texture:SetPoint(Point, OffsetX, OffsetY)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetSizeTexture
--
-- Sets the size of a texture inside of a texture frame.
--
-- BoxNumber         Box containing texture.
-- TextureNumber     Texture to modify.
-- Width, Height     Sets the texture in pixels to width and height.
--
-- NOTES: Works with textures only.
-------------------------------------------------------------------------------
function BarDB:SetSizeTexture(BoxNumber, TextureNumber, Width, Height)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetSize(Width or Texture:GetWidth(), Height or Texture:GetHeight())
  until LastBox
end

-------------------------------------------------------------------------------
-- SetScaleTexture
--
-- Changes the width and height based on scale.
--
-- BoxNumber             Box containing the texture.
-- TextureNumber         Texture to change the scale of.
-- Scale                 New scale to set.
-------------------------------------------------------------------------------
function BarDB:SetScaleTexture(BoxNumber, TextureNumber, Scale)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local Point, RelativeFrame, RelativePoint, OffsetX, OffsetY = Texture:GetPoint()
    local OldScale = Texture:GetScale()

    Texture:SetScale(Scale)
    Texture:SetPoint(Point, RelativeFrame, RelativePoint, OffsetX * OldScale / Scale, OffsetY * OldScale / Scale)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetCoordTexture
--
-- Sets the texture coordinates.  Used to cut out a smaller texture from a larger one.
--
-- BoxNumber                  Box containing texture
-- TextureNumber              Texture to modify
-- Left, Right, Top, Bottom   Tex coordinates range from 0 to 1.
-------------------------------------------------------------------------------
function BarDB:SetCoordTexture(BoxNumber, TextureNumber, Left, Right, Top, Bottom)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    if Texture.Type == 'texture' then
      Texture.SubTexture:SetTexCoord(Left, Right, Top, Bottom)
      Texture.TexLeft, Texture.TexRight, Texture.TexTop, Texture.TexBottom = Left, Right, Top, Bottom
    end
  until LastBox
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Create functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- CreateBar
--
-- Sets up a bar that will contain boxes which hold textures/statusbars.
--
-- UnitBarF           The bar will belong to UnitBarF as a child.
-- ParentFrame        Parent frame the bar will be a child of.
-- NumBoxes           Total boxes that the bar will contain.
--
-- Returns:
--   BarDB            Bar database containing everything to work with the bar.
--
-- Note:  All bar functions are called thru the returned table.
--        CreateBar will embed certain functions like dragging/moving.
-------------------------------------------------------------------------------
function GUB.Bar:CreateBar(UnitBarF, ParentFrame, NumBoxes)

  -- Make bar a frame so it can be used in onupdate for Display()
  local Bar = CreateFrame('Frame')

  -- Copy the functions.
  for FnName, Fn in pairs(BarDB) do
    if type(Fn) == 'function' then
      Bar[FnName] = Fn
    end
  end

  -- Reset the virtual frame levels
  VirtualFrameLevels = nil

  Bar.UnitBarF = UnitBarF
  Bar.Anchor = UnitBarF.Anchor
  Bar.BarType = UnitBarF.BarType
  Bar.NumBoxes = NumBoxes
  Bar.Rotation = 90
  Bar.Slope = 0
  Bar.Swap = false
  Bar.Float = false
  Bar.BorderPadding = 0
  Bar.Justify = 'CORNER'
  Bar.Align = false
  Bar.AlignOffsetX = 0
  Bar.AlignOffsetY = 0
  Bar.AlignPaddingX = 0
  Bar.AlignPaddingY = 0
  Bar.RegionEnabled = true
  Bar.TopFrame = ParentFrame
  Bar.BoxFrames = {}

  -- Create the region frame.
  local Region = CreateFrame('Frame', nil, ParentFrame)
  Region:SetSize(1, 1)
  Region:SetPoint('TOPLEFT')
  Region.Hidden = false
  Bar.Region = Region

  -- Create the box border.  All boxes will be a child of this frame.
  local BoxBorder = CreateFrame('Frame', nil, ParentFrame)
  BoxBorder:SetAllPoints(Region)
  Bar.BoxBorder = BoxBorder

  -- Create the boxes for the bar.
  for BoxFrameIndex = 1, NumBoxes do

    -- Create the BoxFrame and Border.
    local BoxFrame = CreateFrame('Frame', nil, BoxBorder)

    BoxFrame:SetSize(1, 1)
    BoxFrame:SetPoint('TOPLEFT')

    -- Make the boxframe movable.
    BoxFrame:SetMovable(true)

    -- Save frame data to the bar database.
    BoxFrame.BoxNumber = BoxFrameIndex
    BoxFrame.Padding = 0
    BoxFrame.Hidden = false
    BoxFrame.TextureFrames = {}
    BoxFrame.TFTextures = {}
    Bar.BoxFrames[BoxFrameIndex] = BoxFrame
  end

  SetVirtualFrameLevel(0, BoxBorder:GetFrameLevel() + 2)

  return Bar
end

-------------------------------------------------------------------------------
-- CreateTextureFrame
--
-- BoxNumber            Which box you're creating a TexureFrame in.
-- TextureFrameNumber   A number assigned to the TextureFrame
-- Level                Current virtual level for the texture frame.
--
-- NOTES:   TextureFrames are alwasy the same size as BoxFrame, unless you do a SetPoint on it.
-------------------------------------------------------------------------------
function BarDB:CreateTextureFrame(BoxNumber, TextureFrameNumber, Level)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)
    local TextureFrames = BoxFrame.TextureFrames

    -- Create the texture frame.
    local TF = CreateFrame('Frame', nil, BoxFrame)

    TF:SetPoint('TOPLEFT')
    TF:SetSize(1, 1)

    -- Add the framelevel passed to the current framelevel.
    local FrameLevel = GetVirtualFrameLevel(Level)
    SetVirtualFrameLevel(Level, FrameLevel)

    TF:SetFrameLevel(FrameLevel)
    TF:Hide()
    TF.Hidden = true

    TextureFrames[TextureFrameNumber] = TF

    -- Update TopFrameLevel counter
    SetTopFrame(self, TF)
  until LastBox
end

-------------------------------------------------------------------------------
-- OnSizeChangedTexture
--
-- Updates the width and height of a statusbar or texture.
--
-- self            StatusBar
-- Width, Height   Width and Height of the StatusBar
--
-- NOTES:  This function makes sure a texture always stretches to the size of
--         the textures subframe.  It also makes sure that statusbar gets updated
--         if its size was changed and it was setfilled.
-------------------------------------------------------------------------------
local function OnSizeChangedTexture(self, Width, Height)
  local Texture = self:GetParent()

  Texture.Width = Width
  Texture.Height = Height
  if Texture.SetFill then
    local Value = Texture.Value

    if Texture.Type == 'statusbar' then
      Texture.SubFrame:SetValue(Value - 1)
    end
    SetFill(Texture, Value)
  elseif Texture.Type == 'texture' then

    -- Update the texture to be the same size as the SubFrame
    Texture.SubTexture:SetSize(Width, Height)
  end
end

-------------------------------------------------------------------------------
-- CreateTexture
--
-- BoxNumber              Box you're creating a texture in.
-- TextureFrameNumber     Texture frame that you're creating a texture in.
-- TextureType            either 'statusbar' or 'texture'
--                        'cooldown' is the same as texture.  Except it can use SetCooldownTexture()
-- Level                  Current virtual level for the texture.
-- TextureNumber          Must be a unique number per box.  Only time the number
--                        can be the same is if the same texture used in two or more
--                        different boxes.
--
-- NOTES:  Textures are always the same size as the texture frame, unless changed with setpointtexture.
-------------------------------------------------------------------------------
function BarDB:CreateTexture(BoxNumber, TextureFrameNumber, TextureType, Level, TextureNumber)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)
    local TextureFrame = BoxFrame.TextureFrames[TextureFrameNumber]
    local SubFrame = nil
    local Texture = CreateFrame('Frame', nil, TextureFrame)

    -- Set base frame level.
    local FrameLevel = GetVirtualFrameLevel(Level)
    SetVirtualFrameLevel(Level, FrameLevel)
    Texture:SetFrameLevel(FrameLevel)

    -- Create a statusbar or texture.
    if TextureType == 'statusbar' then
      SubFrame = CreateFrame('StatusBar', nil, Texture)
      SubFrame:SetMinMaxValues(0, 1)
      SubFrame:SetValue(1)
      SubFrame:SetOrientation('HORIZONTAL')

      -- Status bar is always the same size of the texture frame.
      Texture:SetAllPoints(TextureFrame)

      -- Set defaults for statusbar.
      Texture.Type = 'statusbar'

      FrameLevel = FrameLevel + 1
    else
      SubFrame = CreateFrame('Frame', nil, Texture)
      local SubTexture = SubFrame:CreateTexture()

      Texture.SubTexture = SubTexture

      -- Set to topleft of the Texture.
      -- SubTexture of type texture always are topleft.
      SubTexture:SetPoint('TOPLEFT')

      -- Textures are always centered in the texture frame by default.
      Texture:SetPoint('CENTER')

      -- Set defaults for texture.
      Texture.Type = 'texture'
      Texture.TexLeft = 0
      Texture.TexRight = 1
      Texture.TexTop = 0
      Texture.TexBottom = 1

      FrameLevel = FrameLevel + 1

      if TextureType == 'cooldown' then
        TextureType = 'texture'

        local CooldownFrame = CreateFrame('Cooldown', nil, SubFrame)
        CooldownFrame:SetPoint('CENTER', SubTexture, 'CENTER', 0, 0)
        Texture.CooldownFrame = CooldownFrame

        local CooldownFrameLine = CreateFrame('Cooldown', nil, CooldownFrame)
        CooldownFrameLine:SetAllPoints(CooldownFrame)
        Texture.CooldownFrameLine = CooldownFrameLine

        FrameLevel = FrameLevel + 2
      end
    end

    -- Make sure subframe is always the same size as texture.
    SubFrame:SetAllPoints(Texture)

    -- Set highest frame level.
    SetVirtualFrameLevel(Level, FrameLevel)

    -- Update TopFrame.
    SetTopFrame(self, SubFrame)

    -- Set onsize changed to update texture size.
    SubFrame:SetScript('OnSizeChanged', OnSizeChangedTexture)

    -- Set defaults.
    Texture.SubFrame = SubFrame
    Texture.Width = 1
    Texture.Height = 1
    Texture.Value = 1
    Texture.RotateTexture = false
    Texture.FillDirection = 'HORIZONTAL'
    Texture.ReverseFill = false
    Texture.FadeOutTime = 0
    Texture.FadeInTime = 0

    -- Hide the texture or statusbar
    Texture:Hide()
    Texture.Hidden = true

    if TextureFrame.Texture == nil then
      TextureFrame.Texture = {}
    end

    TextureFrame.Texture[TextureNumber] = Texture
    BoxFrame.TFTextures[TextureNumber] = Texture
  until LastBox
end


--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Font functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetHighlightFont
--
-- Places a highlight rectangle around all the text of all bars.  And allows
-- one to be highlighted in addition to the existing ones.
--
-- BarType:
--   'on'       Put a white rectangle around all the fonts used by all bars.
--   'off'      Turns off all the rectangles.
--   BarType    'on' must already be set.  This will highlight the bar of bartype
--              with a green rectangle.
-- TextIndex  The text line in the bar to highlight.
-------------------------------------------------------------------------------
function GUB.Bar:SetHighlightFont(BarType, HideTextHighlight, TextIndex)
  local UnitBars = Main.UnitBars

  -- Iterate thru fontstrings
  for BT, FSA in pairs(FontStrings) do

    -- Iterate thru the fontstring array.
    for _, FS in ipairs(FSA) do
      local Text = FS.Text

      if Text then
        local NumStrings = #Text

        for Index, TF in ipairs(FS.TextFrames) do
          local r, g, b, a = 1, 1, 1, 0

          if not HideTextHighlight and not UnitBars[FS.BarType].Layout.HideText then

            -- Check if fontstring is active.
            if Index <= NumStrings then

              -- if on default to white.
              if BarType == 'on' then
                a = 1

              -- if off hide all borders.
              elseif BarType == 'off' then
                a = 0

              -- match bartype and text index then set it to green.
              -- if bartype matches but not the index then set to white.
              elseif FS.BarType == BarType and TextIndex == Index then
                r, g, b, a = 0, 1, 0, 1
              else
                a = 1
              end
            end
          end
          TF:SetBackdropBorderColor(r, g, b, a)
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Round
--
-- Rounds a number down or up
--
-- Value           Number to be rounded.
-- DecimalPlaces   If the number is a floating then you can specify how many
--                 decimal places to round at.
-- Returns:
--   RoundValue      New value rounded.
-------------------------------------------------------------------------------
local function Round(Value, DecimalPlaces)
   if DecimalPlaces then
     local Mult = 10 ^ DecimalPlaces
     return floor(Value * Mult + 0.5) / Mult
   else
     return floor(Value + 0.5)
   end
end

-------------------------------------------------------------------------------
-- NumberToDigitGroups
--
-- Takes a number and returns it in groups of three. 999,999,999
--
--
-- Value       Number to convert to a digit group.
-- Returns:
--   String    String containing Value in digit groups.
-------------------------------------------------------------------------------
local function NumberToDigitGroups(Value)
  local Sign = ''
  if Value < 0 then
    Sign = '-'
    Value = abs(Value)
  end

  if Value >= 1000000000 then
    return format(BillionFormat, Sign, Value / 1000000000, (Value / 1000000) % 1000, (Value / 1000) % 1000, Value % 1000)
  elseif Value >= 1000000 then
    return format(MillionFormat, Sign, Value / 1000000, (Value / 1000) % 1000, Value % 1000)
  elseif Value >= 1000 then
    return format(ThousandFormat, Sign, Value / 1000, Value % 1000)
  else
    return format('%s', Value)
  end
end

-------------------------------------------------------------------------------
-- FontGetValue
--
--  Subfunction of SetValue()
--
--  Usage: Value = FontGetValue[Type](FS, Value, ValueType)
--
--  FS          FS object created by Main:CreateFontString()
--  Value       Value to be modifed in some way.
--  ValueType   Same value as Type below.
--  Type        Will call a certain function based on Type.
--
--  Value       Value returned based on ValueType
-------------------------------------------------------------------------------
local FontGetValue = {}

  local function FontGetValue_Short(FS, Value, ValueType)
    if Value >= 10000000 then
      if ValueType == 'short_dgroups' then
        return format('%sm', NumberToDigitGroups(Round(Value / 1000000, 1)))
      else
        return format('%.1fm', Value / 1000000)
      end
    elseif Value >= 1000000 then
      return format('%.2fm', Value / 1000000)
    elseif Value >= 100000 then
      return format('%.0fk', Value / 1000)
    elseif Value >= 10000 then
      return format('%.1fk', Value / 1000)
    else
      if ValueType == 'short_dgroups' then
        return NumberToDigitGroups(Value)
      else
        return format('%s', Value)
      end
    end
  end

  FontGetValue['short'] = FontGetValue_Short
  FontGetValue['short_dgroups'] = FontGetValue_Short

  -- whole (no function needed)

  FontGetValue['whole_dgroups'] = function(FS, Value, ValueType)
    return NumberToDigitGroups(Value)
  end

  FontGetValue['percent'] = function(FS, Value, ValueType)
    local MaxValue = FS.maximum

    if MaxValue == 0 then
      return 0
    else
      return FS.PercentFn(Value, MaxValue)
    end
  end

  FontGetValue['thousands'] = function(FS, Value, ValueType)
    return Value / 1000
  end

  FontGetValue['thousands_dgroups'] = function(FS, Value, ValueType)
    return NumberToDigitGroups(Round(Value / 1000))
  end

  FontGetValue['millions'] = function(FS, Value, ValueType)
    return Value / 1000000
  end

  FontGetValue['millions_dgroups'] = function(FS, Value, ValueType)
    return NumberToDigitGroups(Round(Value / 1000000, 1))
  end

  -- unitname, realmname, unitnamerealm  (no function needed)

  -- timeSS, timeSS_H, timeSS_HH (no function needed)

-------------------------------------------------------------------------------
-- SetValue (method for Font)
--
-- BoxNumber          Boxnumber that contains the font string.
-- TextureNumber      If not nil then this the fontstring is used for the TextureFrmae.
-- ...                Type, Value pairs.  Example:
--                      'current', CurrValue, 'maximum', MaxValue, 'predicted', PredictedPower, 'unit', Unit)
--
-- NOTES: SetValue() is optimized for speed since this function gets called a lot.
-------------------------------------------------------------------------------
local function SetValue(FS, FontString, Layout, NumValues, ValueName, ValueType, ...)

  -- if we have paramters left then get them.
  local Name = ValueName[NumValues]

  if NumValues > 1 then
    if Name ~= 'none' then
      local Type = ValueType[NumValues]
      local Value = FS[Name] or FS[Type]
      local GetValue = FontGetValue[Type]

      SetValue(FS, FontString, Layout, NumValues - 1, ValueName, ValueType, Value ~= '' and GetValue and GetValue(FS, Value, Type) or Value, ...)
    else
      SetValue(FS, FontString, Layout, NumValues - 1, ValueName, ValueType, ...)
    end
  elseif Name ~= 'none' then
    local Type = ValueType[NumValues]
    local Value = FS[Name] or FS[Type]
    local GetValue = FontGetValue[Type]

    FontString:SetFormattedText(Layout, Value ~= '' and GetValue and GetValue(FS, Value, Type) or Value, ...)
  else
    FontString:SetFormattedText(Layout, ...)
  end
end

function BarDB:SetValueFont(BoxNumber, TextureFrameNumber, ...)
  local Frame = self.BoxFrames[BoxNumber]
  if TextureFrameNumber then
    Frame = Frame.TextureFrames[TextureFrameNumber]
  end

  local FS = Frame.FS
  local TextFrame = FS.TextFrame

  for Index = 1, select('#', ...), 2 do
    local ParType = select(Index, ...)
    local ParValue = select(Index + 1, ...)

    if ParType == 'unit' then
      local Name, Realm = UnitName(ParValue)
      Name = Name or ''
      Realm = Realm or ''

      FS.unitname = Name
      FS.realmname = Realm
      if Realm ~= '' then
        Realm = '-' .. Realm
      end
      FS.unitnamerealm = Name .. Realm
    else
      FS[ParType] = ParValue
    end
  end
  local Text = FS.Text

  for Index = 1, FS.NumStrings do
    local FontString = FS[Index]
    local TS = Text[Index]
    local ValueName = TS.ValueName

    -- Display the font string
    local ReturnOK, Msg = pcall(SetValue, FS, FontString, TS.Layout, #ValueName, ValueName, TS.ValueType)

    if not ReturnOK then
      FontString:SetFormattedText('Err (%d)', Index)
    end
  end
end

-------------------------------------------------------------------------------
-- SetValueRawFont
--
-- Allows you to set text directly to all the text lines.
--
-- BoxNumber       Boxnumber that contains the font string.
-- TextureNumber   If not nil then this the fontstring is used for output.
-- Text            Output to display to the text lines
-------------------------------------------------------------------------------
function BarDB:SetValueRawFont(BoxNumber, TextureFrameNumber, Text)
  repeat
    local Frame = NextBox(self, BoxNumber)
    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber]
    end
    local FS = Frame.FS

    for Index = 1, FS.NumStrings do
      FS[Index]:SetText(Text)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetValueTimer
--
-- Timer function for FontSetValueTime
-------------------------------------------------------------------------------
local function SetValueTimer(self)
  local TimeElapsed = GetTime() - self.StartTime
  local TimeReached = self.TimeReached

  if not TimeReached then
    TimeReached = true
    self.TimeReached = true
    local Counter = self.Counter

    if self.Step < 0 then
      Counter = self.Duration - TimeElapsed
    else
      Counter = Counter + TimeElapsed
    end
    -- Truncate down to 1 decimal place.
    self.Counter = abs(Counter - (Counter % 0.1))
    Main:SetTimer(self, 0.1, SetValueTimer)
  end

  if TimeReached then
    if TimeElapsed < self.Duration then
      local Counter = self.Counter
      local FS = self.FS
      local Text = FS.Text

      FS.time = Counter

      if FS.Multi then
        for Index = 1, FS.NumStrings do
          local FontString = FS[Index]
          local TS = Text[Index]
          local ValueName = TS.ValueName

          -- Display the font string
          local ReturnOK, Msg = pcall(SetValue, FS, FontString, TS.Layout, #ValueName, ValueName, TS.ValueType)

          if not ReturnOK then
            FontString:SetFormattedText('Err (%d)', Index)
          end
        end
      else
        local TS = FS.Text[1]
        local ValueName = TS.ValueName

        -- Display the font string
        local ReturnOK, Msg = pcall(SetValue, FS, FS[1], TS.Layout, #ValueName, ValueName, TS.ValueType)

        if not ReturnOK then
          FS[1]:SetFormattedText('Err (%d)', 1)
        end
      end
      Counter = Counter + self.Step
      Counter = Counter > 0 and Counter or 0
      self.Counter = Counter
    else

      -- stop timer
      Main:SetTimer(self, nil)
      local FS = self.FS
      for Index = 1, FS.NumStrings do
        FS[Index]:SetText('')
      end
    end
  end
end

-------------------------------------------------------------------------------
-- FontSetValueTime
--
-- Displays time in seconds over time.
--
-- BoxNumber            BoxNumber to display time on.
-- TextureFrameNumber   If specified then TextureFrame will be used instead.
-- StartTime            Starting time if nil then the current time will be used.
-- Duration             Duration in seconds.  Duration of 0 or less will stop the current timer.
-- StartValue           Starting value in seconds.  This will start dipslaying seconds from this value.
-- Direction            Direction to go in +1 or -1
-- ...                  Type, Value pairs.  Example:
--                        'current', CurrValue, 'maximum', MaxValue, 'predicted', PredictedPower, 'unit', Unit)
-------------------------------------------------------------------------------
function BarDB:SetValueTimeFont(BoxNumber, TextureFrameNumber, StartTime, Duration, StartValue, Direction, ...)
  local Step = Direction == 1 and 0.1 or Direction == -1 and -0.1 or 0.1

  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber ~= nil then
      Frame = Frame.TextureFrames[TextureFrameNumber]
    end

    local FontTime = Frame.FontTime
    if FontTime == nil then
      FontTime = {}
      Frame.FontTime = FontTime
    end

    Main:SetTimer(FontTime, nil)

    Duration = Duration or 0
    local FS = Frame.FS

    if Duration > 0 then
      local CurrentTime = GetTime()

      -- Set up the paramaters.
      StartTime = StartTime and StartTime or CurrentTime
      FontTime.StartTime = StartTime
      FontTime.Duration = Duration
      FontTime.StartValue = StartValue
      FontTime.Counter = StartValue
      FontTime.Step = Step
      FontTime.TimeReached = false
      FontTime.FS = FS
      FontTime.Frame = Frame

      for Index = 1, select('#', ...), 2 do
        local ParType = select(Index, ...)
        local ParValue = select(Index + 1, ...)

        if ParType == 'unit' then
          local Name, Realm = UnitName(ParValue)
          Name = Name or ''
          Realm = Realm or ''

          FS.unitname = Name
          FS.realmname = Realm
          if Realm ~= '' then
            Realm = '-' .. Realm
          end
          FS.unitnamerealm = Name .. Realm
        else
          FS[ParType] = ParValue
        end
      end

      local WaitTime = 0
      if StartTime > CurrentTime then
        WaitTime = StartTime - CurrentTime
      end
      Main:SetTimer(FontTime, WaitTime, SetValueTimer)
    else
      for Index = 1, FS.NumStrings do
        FS[Index]:SetText('')
      end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- FontGetLayout
--
-- ValueName      Array containing the names.
-- ValueType      Array containing the types.
--
-- Returns:
--   Layout       String containing the new layout.
-------------------------------------------------------------------------------
local function GetLayoutFont(ValueName, ValueType)
  local LastName = nil
  local Sep = ''
  local SepFlag = false

  local Layout = ''

  for NameIndex, Name in ipairs(ValueName) do
    if Name ~= 'none' then

      -- Add a '/' between current and maximum.
      if NameIndex > 1 then
        if not SepFlag and (LastName == 'current' and Name == 'maximum' or
                            LastName == 'maximum' and Name == 'current') then
          Sep = ' / '
          SepFlag = true
        else
          Sep = ' '
        end
      end

      LastName = Name
      Layout = Layout .. Sep .. (ValueLayout[ValueType[NameIndex]] or '')
    end
  end

  return Layout
end

-------------------------------------------------------------------------------
-- UpdateFont
--
-- Updates a font based on the text settings in UniBar.Text
--
-- BoxNumber            BoxFrame that contains the font.
-- TextureFrameNumber   If specified then the font in TextureFrame is used instead.
-- ColorIndex           Sets color[ColorIndex] bypassing Color.All setting.
-------------------------------------------------------------------------------
function BarDB:UpdateFont(BoxNumber, TextureFrameNumber, ColorIndex)
  local Text = self.UnitBarF.UnitBar.Text
  local TopFrame = self.TopFrame
  local UBD = DUB[self.BarType]
  local DefaultTextSettings = UBD.Text[1]
  local Multi = UBD.Text.Multi

  repeat
    local Frame, BoxIndex = NextBox(self, BoxNumber)

    if TextureFrameNumber ~= nil then
      Frame = Frame.TextureFrames[TextureFrameNumber]
    end
    local FS = Frame.FS
    local TextFrames = FS.TextFrames
    local TF = nil
    local NumStrings = nil

    -- Adjust the fontstring array based on the text settings.
    for Index = 1, #Text do
      local FontString = FS[Index]
      local TS = Text[Index]
      local TF = TextFrames[Index]
      local Color = TS.Color
      local c = nil
      local ColorAll = Color.All

      -- Colorall dont exist then fake colorall.
      if ColorAll == nil then
        ColorAll = true
      end
      NumStrings = Index

      -- Since Text is dynamic we need to make sure no values are missing.
      -- If they are they'll be copied from defaults.
      Main:CopyMissingTableValues(DefaultTextSettings, TS)

      -- Update the layout if not in custom mode.
      if not TS.Custom then
        TS.Layout = GetLayoutFont(TS.ValueName, TS.ValueType)
      end

      -- Create a new fontstring if one doesn't exist.
      if FontString == nil then
        TF = CreateFrame('Frame', nil, Frame)
        TF:SetBackdrop(FrameBorder)
        TF:SetBackdropBorderColor(1, 1, 1, 0)

        TextFrames[Index] = TF
        FontString = TF:CreateFontString(nil)

        FontString:SetAllPoints(TF)
        FS[Index] = FontString
      end

      -- Set font to current settings from text.
      local ReturnOK, Msg = pcall(FontString.SetFont, FontString, LSM:Fetch('font', TS.FontType), TS.FontSize, TS.FontStyle)

      if not ReturnOK then
        FontString:SetFont(LSM:Fetch('font', TS.FontType), TS.FontSize, 'NONE')
      end
      FontString:SetJustifyH(TS.FontHAlign)
      FontString:SetJustifyV(TS.FontVAlign)
      FontString:SetShadowOffset(TS.ShadowOffset, -TS.ShadowOffset)

      -- Position the font by moving textframe.
      TF:ClearAllPoints()
      TF:SetPoint(TS.FontPosition, Frame, TS.Position, TS.OffsetX, TS.OffsetY)
      TF:SetSize(TS.Width, TS.Height)

      -- Set the texture frame to be on top.
      TF:SetFrameLevel(TopFrame:GetFrameLevel() + 1)

      if FontString:GetText() == nil then
        FontString:SetText('')
      end

      if ColorAll then
        c = Color
      elseif ColorIndex then
        c = Color[ColorIndex]
      else
        c = Color[BoxIndex]
      end
      FontString:SetTextColor(c.r, c.g, c.b, c.a)
    end

    -- Erase font string data no longer used.
    for Index = NumStrings + 1, FS.NumStrings do
      FS[Index]:SetText('')
    end
    FS.Multi = Multi
    FS.NumStrings = NumStrings
    FS.Text = Text
  until LastBox
end

-------------------------------------------------------------------------------
-- CreateFont
--
-- Creates a font object to display text on the bar.
--
-- BoxNumber            Boxframe you want the font to be displayed on.
-- TextureFrameNumber   If specified then TextureFrame is used instead.
-- PercentFn            Function to calculate percents in FontSetValue()
--                      Not all percent calculations are the same. So this
--                      adds that flexibility.
-------------------------------------------------------------------------------
function BarDB:CreateFont(BoxNumber, TextureFrameNumber, PercentFn)
  local BarType = self.BarType

  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber ~= nil then
      Frame = Frame.TextureFrames[TextureFrameNumber]
    end
    local FS = {}

    -- Add font strings to the fontstrings table.
    if FontStrings[BarType] == nil then
      FontStrings[BarType] = {}
    end
    local FSS = FontStrings[BarType]
    FSS[#FSS + 1] = FS

    -- Store the font data and save it to the BoxFrame or TextureFrame.
    FS.BarType = BarType
    FS.NumStrings = 0
    FS.TextFrames = {}
    FS.PercentFn = PercentFn
    Frame.FS = FS
  until LastBox
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Options management functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-----------------------------------------------------------------------------
-- OptionsSet
--
-- Returns true if any onptions were set by SO
-----------------------------------------------------------------------------
function BarDB:OptionsSet()
  return self.Options ~= nil
end

-----------------------------------------------------------------------------
-- SO
--
-- Sets an option under TableName and KeyName
--

-- TableName    This is the name that is looked up in DoFunction()
--              Only part of this name needs to match the TableName passed to DoFunction()
-- KeyName      This is the keyname that is looked up in DoFunction()
--              KeyName can be virtual by prefixing it with an underscore.
-- Fn           function to call for TableName and KeyName
-----------------------------------------------------------------------------
function BarDB:SO(TableName, KeyName, Fn)
  local Options = self.Options

  -- Create options table if one doesn't exist.
  if Options == nil then
    Options = {}
    self.Options = Options
  end

  -- Search for existing table name
  local Option = nil
  local NumOptions = #Options

  for Index = 1, NumOptions do
    if TableName == Options[Index].TableName then
      Option = Options[Index]
      break
    end
  end

  -- Create new keyname table if one doesn't exist.
  if Option == nil then
    Option = {TableName = TableName, KeyNames = {} }
    Options[NumOptions + 1] = Option
  end
  local KeyNames = Option.KeyNames

  KeyNames[#KeyNames + 1] = {Name = KeyName, Fn = Fn}
end

-------------------------------------------------------------------------------
-- SetOptionData
--
-- Assigns user data to a TableName.  When a table name is found in the unitbar
-- data.  Additional information set in this function will get passed back.
--
-- TableName      Once the TableName is SO() is found in the default unitbar data, then unitbar data.
--                Then if this table matches that. The data is passed back.
-- ...            Data to pass back thru DoFunction()
-------------------------------------------------------------------------------
function BarDB:SetOptionData(TableName, ...)
  local OptionsData = self.OptionsData

  -- Create a new OptionsData table if one doesn't exist.
  if OptionsData == nil then
    OptionsData = {}
    self.OptionsData = OptionsData
  end

  local OptionData = OptionsData[TableName]

  -- Create option data if one doesn't exist.
  if OptionData == nil then
    OptionData = {}
    OptionsData[TableName] = OptionData
  end
  for Index = 1, select('#', ...) do
    OptionData['p' .. Index] = (select(Index, ...))
  end
end

-------------------------------------------------------------------------------
-- DoOption
--
-- Calls a function thats set to TableName and KeyName
--
-- If TableName is nil then matches all TableNames
-- If KeyName is nil then it matches all KeyNames
--
-- Read the notes at the top for details.
-------------------------------------------------------------------------------
function BarDB:DoOption(OTableName, OKeyName)
  local UB = self.UnitBarF.UnitBar
  local UBD = DUB[self.BarType]

  local Options = self.Options
  local OptionsData = self.OptionsData

  -- Search for TableName in Options
  for TableNameIndex = 1, #Options do
    local Option = Options[TableNameIndex]
    local TName = Option.TableName
    local KeyNames = Option.KeyNames

    if OTableName == nil or strfind(OTableName, TName) then
      local TableName2 = OTableName or TName

      -- Search KeyName in Option.
      for KeyNameIndex = 1, #KeyNames do
        local KeyName = KeyNames[KeyNameIndex]
        local KName = KeyName.Name

        -- Check for recursion.  We don't want to recursivly call the same function.
        if not KeyName.Recursive and (OKeyName == nil or KName == '_' or KName == OKeyName) then

          -- Search for the tablename found in the unitbar defaults data.
          for DUBTableName, DUBData in pairs(UBD) do
            if type(DUBData) == 'table' then

              -- Does the tablename partially match.
              if strfind(DUBTableName, TableName2) then

                -- Check the default data found exists in the unitbar data
                local UBData = UB[DUBTableName]

                if UBData then
                  local OptionData = OptionsData and OptionsData[DUBTableName] or DoOptionData
                  local Value = UBData[KName]

                  -- Call Fn if keyname is virtual or keyname was found in unitbar data.
                  if Value ~= nil or KName == '_' or strfind(KName, '_') then
                    OptionData.TableName = DUBTableName
                    OptionData.KeyName = KName ~= '' and KName or OKeyName
                    if Value == nil then
                      Value = UBData
                    end
                    KeyName.Recursive = true
                    local Fn = KeyName.Fn

                    -- Is this not a color all table?
                    if type(Value) ~= 'table' or Value.All == nil then
                      Fn(Value, UB, OptionData)
                    else
                      local ColorAll = Value.All
                      local c = Value

                      for Index = 1, #Value do
                        if not ColorAll then
                          c = Value[Index]
                        end
                        OptionData.Index = Index
                        OptionData.r = c.r
                        OptionData.g = c.g
                        OptionData.b = c.b
                        OptionData.a = c.a
                        Fn(Value, UB, OptionData)
                      end
                    end
                    KeyName.Recursive = false
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
