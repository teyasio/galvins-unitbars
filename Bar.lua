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
local DefaultUB = GUB.DefaultUB

local Main = GUB.Main
local Options = GUB.Options

local LSM = Main.LSM

-- localize some globals.
local _, _G, print =
      _, _G, print
local abs, max, floor, ceil, sqrt,      mhuge =
      abs, max, floor, ceil, math.sqrt, math.huge
local strfind, strmatch, strsub, strtrim, strsplit, strlower, strupper, format, gsub =
      strfind, strmatch, strsub, strtrim, strsplit, strlower, strupper, format, gsub
local GetTime, ipairs, pairs, next, pcall, select, tonumber, tostring, tremove, type, unpack =
      GetTime, ipairs, pairs, next, pcall, select, tonumber, tostring, tremove, type, unpack
local IsModifierKeyDown, CreateFrame, assert, PlaySoundFile, wipe, UnitExists =
      IsModifierKeyDown, CreateFrame, assert, PlaySoundFile, wipe, UnitExists

-------------------------------------------------------------------------------
-- Locals
--
-- BarDB                             Bar Database. All functions are called thru this except for CreateBar().
--   UnitBarF                        The bar is a child of UnitBarF.
--   ProfileChanged                  Used by Display(). If true then the profile was changed in some way.
--   Anchor                          Reference to the UnitBar's anchor frame.
--   BarType                         The type of bar it belongs to.
--   Options                         Used by SO() and DoOption().
--   OptionsData                     Used by DoOption() and SetOptionData().
--   ParentFrame                     The whole bar will be a child of this frame.
--
--   Region                          Visible region around the bar. Child of ParentFrame.
--     Hidden                        If true the region is hidden.
--     Anchor                        Reference to the UnitBarF.Anchor.  Used for Mouse interaction.
--     BarDB                         BarDB.  Reference to the Bar database.  Used for mouse interaction
--     EnableDrag                    true or false. If true then the Region can be dragged
--     Name                          Name for the tooltip.  Used for tooltip, dragging.
--     Backdrop                      Table containing the backdrop. Set by GetBackDrop()
--
--   NumBoxes                        Total number of boxes the bar was created with.
--   Rotation                        Rotation in degrees for the bar.
--   Slope                           Adjusts the horizontal or vertical slope of a bar.
--   Swap                            Boxes can be swapped with each other by dragging one on top of the other.
--   Float                           Boxes can be dragged and dropped anywhere on the screen.
--   Align                           If false then alignment is disabled.
--   AlignOffsetX                    Horizontal offset for the aligned group of boxes.
--   AlignOffsetY                    Vertical offset for the aligned group of boxes
--   AlignPadding                    Amount of horizontal distance to set the moving boxframe near another one when aligned
--   BorderPadding                   Amount of padding between the region's border of the bar and the boxes.
--   Justify                         'SIDE' of boxframe or 'CORNER'.
--   RegionEnabled                   If false the bars region is not shown and doesn't interact with mouse.
--                                   HideRegion and ShowRegion functions no longer work.
--   ChangeTextures[]                List of texture numbers used with SetChangeTexture() and ChangeTexture()
--   BoxLocations[]                  List of x, y coordinates for each boxframe when in floating mode.
--   BoxOrder[]                      Table box indexes containing the order the boxes should be listed in.
--
--   BoxFrames[]                     An array containing all the box frames in the bar.
--     TextureFrames[]               An array containing all the texture frames for the box.
--       Texture[]                   An array containing all the texture/statusbars for the texture frame.
--
--   Settings                        Used by triggers to keep track of the original settings for each frame/texture.
--   TriggerData                     See triggers below.  Nil if Triggers are not enabled
--
--   AGroups                         Used by animation to keep track of animation groups. Created by GetAnimation() in SetAnimationBar()
--   AGroup                          Used to play animation when showing or hiding the bar. Created by GetAnimation() in SetAnimationBar()
--
-- BoxFrame
--   Name                            Name of the boxframe.  This will appear on tooltips.
--   BoxNumber                       Current box number.  Needed for swapping.
--   Padding                         Amount of distance in pixels between the current box and the next one.
--   Hidden                          If true then the boxframe will not get shown in Display()
--   MaxFrameLevel                   Contains the highest frame level used by CreateBar() and CreateTexture()
--   TextureFrames[]                 Table of textureframes used by boxframe.
--   TFTextures[]                    Used by texture function, contains the texture.
--   ValueTime                       Used by SetValueTime()
--   Anchor                          Reference to the UnitBarF.Anchor.  Used for tooltip, dragging.
--   BarDB                           BarDB.  Reference to the Bar database.  Used for tooltip, dragging.
--   BF                              Reference to boxframe.  Used for tooltip, dragging.
--   EnableDrag                      true or false. If true then the box frame can be dragged
--   Backdrop                        Table containing the backdrop.
--   TextData                        This gets added by CreateFont()
--
-- TextureFrame
--   _Width, _Height                 Width and height
--   TextureFrameNumber              Used for debugging
--   Hidden                          If true then the textureframe is hidden.
--   ValueTime                       Used by SetValueTime()
--   MaxFrameLevel                   Contains the max frame level used by its children
--   BorderFrame                     Contains the backdrop. Child of TextureFrame
--     Backdrop                        Table containing the backdrop.
--     AGroup                          Contains the animation group for offsetting.
--   PaddingFrame                    Child of BorderFrame. Used by SetPaddingTextureFrame()
--   ScaleFrame                      Child of PaddingFrame.  This lets the statusbars or textures to be scaled
--     AGroup                          Animation used when scaling the texture thru SetScaleTexture()
--   SizeFrame                       Child of ScaleFrame.  This manages relative size of Texture.Frame
--     ScaleFrame                      Used by OnSizeChangedFrame().
--     Frames[]                      Contains one or more Frames that hold each texture. Used by OnSizeChangedFrame()
--                                   Also can contain cooldown frames
--   SBF                             Statusbar frame if the TextureFrame was created with a type of statusbar, otherwise nil
--                                   Used by CreateTexture()
--
-- Texture                           Texture is only a texture if created a statusbar, otherwise its a frame containing the texture.
--   Type                            'statusbar', 'texture' or 'cooldown'
--   Texture                         Contains the statusbar, texture or cooldown
--
--   ScaleFrame                      Reference of TextureFrame.ScaleFrame used by SetScaleAllTexture()
--   BorderFrame                     Reference of TextureFrame.BorderFrame used by SetOffsetTextureFrame()
--
--   Frame  (nil if statusbar)       Frame child of ScaleFrame.  This is used to manage frame levels
--                                   and size and position of the texture.
--     _Width, _Height               used by SetSizeTexture() and OnSizeChanged() to scale
--
--
--   StatusBars only
--   ---------------
--   Value                           Keeps track of the current value of the fill
--   MaxValue                        Specifies the maximum value that can reached for setfill
--
--   StartTime
--   Duration
--   StartValue
--   EndValue
--   Range
--   TimeElapsed                     Used by SetFillTimeTexture()
--   SmoothFillMaxTime               Max time in seconds for a smooth fill to complete.
--   Speed                           How fast animation draws. Between 0.01 and 1.
--                                   or 5secs from 0 to 0.5 or 0.25 to 0.75.
--                                   Used by SetFillSpeedTexture() and SetFillTexture()
--
--
--   Textures only
--   -------------
--   Frame                           Child of ScaleFrame. Holds the Texture
--   CooldownFrame                   Frame used to do a cooldown on the texture.
--                                     This works like Frame
--     _Width
--     _Height                       Used by SetSizeCooldownTexture() and SetScaleTextureFrame()
--
--
--   Hidden                          If true then the statusbar/texture is hidden.
--   ShowHideFn                      This function will get called after calling SetHiddenTexture().  If animation is set then
--                                   the function will get called after the animation has ended.  Otherwise it happens instantly.
--   TexLeft
--   TexRight
--   TexTop
--   TexBottom                       Text coords for a texture.  Used by SetTexCoord()
--
--   Backdrop                        Table containing the backdrop.  Created by GetBackdrop()
--   AGroup                          Contains the animation to play when showing or hiding a texture.  Created by GetAnimation() in SetAnimationTexture()
--
--
--  Upvalues                         Used by bars.lua
--    RotationPoint                    Used by Display() to rotate the bar.
--    BoxFrames                        Used by NextBox() for iteration.
--    DoOptionData                     Reusable table for passing back information. Used by DoOption().
--    ParValues                        Contains the parameter data passed to SetValueFont()
--    ParValuesTest                    Contains test data to create sample text used by ParseLayoutFont()
--    ValueLayout                      Converts value types into format strings.
--    ValueLayoutTest                  Used to test each formatted string. Used by ParseLayoutFont()
--    ValueLayoutTag                   Converts value names into shorter names.  Used by ParseLayoutFont()
--    GetValueLayout                   Converts value type to a format string. Used by GetLayoutFont()
--    FrameBorder                      Used to show a border around font text. Used by UpdateFont()
--    AnchorPointWord                  Displays anchor point in text when moving bars around. Used by BoxInfo()
--
--    LastSBF[]                        Used by CreateTexture()
--    RotationFillDirection[]          Converts Rotation to a fill direction used by statusbars
--    ConvertSubLayer[]                Converts a number from 1 to 16 to a sub layer.
--
--  RotationPoint
--
--  [Rotation]                       from 45 to 360.  Determines which direction to go in.
--    x, y                           Determines direction by using negative or positive values.
--                                   x or y will be 0 if there is no direction to go in.
--                                   For example x = 1 y = 0 means that there is no up/down just
--                                   horizontal.
--  SIDE or CORNER                   Is the alignment for the boxes.  Either they're attached by their
--                                   corner or side.  Side would be the middle part of the box edge.
--    Point                          The anchor point for the boxframe to attach another boxframe.
--    ParentPoint                    Is the previous boxframe's anchor point that is attached.
--                                   So boxframe 2 Point would be attached to boxframe 1 ParentPoint.
--
--  Frame structure
--    ParentFrame
--      Region                              Bar border
--      BoxFrame                            border and BoxFrame
--        TextureFrame                      TextureFrame.
--          BorderFrame                     Border
--            PaddingFrame                  Used by SetPaddingTextureFrame()
--              SizeFrame                   For texture size management.  Used by OnSizeChangedFrame()
--                ScaleFrame                For scaling without changing the size of the textureframe
--                  Frame[] (Texture.Frame) Frame for the texture
--                                          Frame is also used for SetPointTexture, Padding, Backdrops.
--                    Texture               Statusbar texture or texture. Child of Frame
--                  CooldownFrame           Child of ScaleFrame. Optional, only exists if the 'cooldown' option was specified in CreateTexture()
--
-- NOTES: When clearing all points on a frame.  Then do a SetPoint(Point, nil, Point)
--        Will cause GetLeft() etc to return a bad value.  But if you pass the frame
--        instead of nil you'll get a good values.
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
-- points of each frame and sets it a new point TOPLEFT, with an x, y position.  The frame doesn't
-- actually move unless it was offset.  The same thing is done for textureframes so they're always
-- inside of a boxframe.
--
-- When floating mode is activated a snap shot of the bar is taken then copied.  Then the boxframes
-- can be placed anywhere on the screen.  The floating layout is always kept separate from the bar layout.
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
-- SO short for SetOption lets you specify a table name and key name.
-- When you call DoOption() with a table name and key name the following can happen:
--
-- TableName is nil   - Then will match any SO TableName.
-- KeyName is nil     - Then will match any SO KeyName.
--
--   The way SO TableName is searched, is the TableNames set with SO is partially matched
--   in the SO TableName. For exmaple it could be 'BAR BACKGROUND' and it would match
--   any tablenames that have BAR or BACKGROUND.

--   Each time an SO TableName is found.  Then the SO TableName has to be found in the
--   default unitbar data first then its checked to see if its in the UnitBar data second.
--   Each time an SO KeyName is found.  Then it has to match exactly to a key in the
--   unitbar data.
--
-- TableName is not nil - The SO TableName can be found in TableName, doesn't have to be an exact match
-- KeyName is not nil   - Then has to exact match SO KeyName.
--                        If its '_' then its an empty virtual key name and will match any SO KeyName.
--                        Empty virtual key names don't get searched in the unitbar data. NOTE: the '_'
--                        can be found anywhere in the KeyName, but to keep it simple I always use it
--                        at the start of the name
--
-- After TableName and KeyName are found in the SO data.  Then the TableName is searched in the default UnitBarData
-- for the current BarType.  This can partially match.  After that it takes the full name of the table
-- found in the default unitbar.  And looks for it in the unitbar profile.  If found then then
-- the KeyName has to be an exact match to UnitBar[TableName][KeyName].  Unless KeyName is virtual.
--
-- Virtual Key Name.
--   A virtual key starts with an underscore.  It still follows the matching rules of a normal
--   key except it doesn't get searched in the UnitBar data.
--
-- Each time DoOption matches data from SO(). The following parameters are passed back.
--
--   v:   This equals UnitBars[BarType][TableName][KeyName].
--        If the KeyName is virtual then this will equal UnitBars[BarType][TableName].
--   UB:  This equals the unitbar table UnitBars[BarType].
--   OD:  Table that contains the following:
--           TableName   The name of the table found in the unitbar data.
--           KeyName     Name of the key passed to SO()
--
--           If the KeyName is a table that contains 'All'.  Then its considered
--           a color all table.  The following is returned in iteration till
--           the end of table is reached.
--             Index       The current element in the color all table.
--             r, g, b, a  The red, green, blue, and alpha colors KeyName[Index]
--
--           p1..pN   Parameter data passed from SetOptionData.  See below for details.
--
-- If there was a SetOptionData() and the TableName found in SO data, default unitbar data, and unitbardata.
-- If the tablename matches exactly to what was passed from SetOptionData.  Then p1..pN get added to OD.
--
--
-- Options[]                   Array containing all the options.
--   TableName                 string: TableName this is looked up in DoOption()
--   KeyNames[]                Array containing a list of KeyName and Functions.
--     Name                    string: Keyname that is looked up in DoOption()
--     Fn                      Function to call after searching for TableName and Name
--
-- OptionsData[TableName]      Table containing additional data that can be used with DoOption()
--   p1..pN                    Series of keys that go in p1, p2, p3, etc.  These contain
--                             the parameters passed from SetOptionData()
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Fonts
--
-- A BoxFrame can have a font.
--
-- BarTextData[BarType] An array that keeps track of all the TextData tables.
--                      This is used to help display the text frame boxes when options is opened.
--
-- TextData
--   Multi                 Can support more than one text line.
--   BarType               Type of bar that created the fontstring.
--   TextFrames[TextLine]  Contains one or more frames used by the fontstrings.
--   PercentFn             Function used to calculate percentages from CurrentValue and MaximumValue.
--   Texts[]               Reference to the current Text data found in UnitBars[BarType].Text
--     ErrorMessage        Used to pass back format error message in custom mode to the options UI. Created by ParseLayoutFont()
--     SampleText          Same as above except for valid formatted text.  Shows a sample of what it'll look like. Created by ParseLayoutFont()
--   TextTableName         Contains the name of the table being used for text. UnitBars[BarType][TextTableName]
--   ValueLayouts[]        Array containing parsed layouts.  This sets the order the layouts are shown. Created by ParseLayoutFont()
--
-- TextData[TextLine]      Array used to store the fontstring for each textline
--   LastSize              For animation. Contains the last size set by a text font size trigger.  SetSizeFont()
--   LastX
--   LastY                 For animation. Contains the last position set by an offset trigger.  SetOffsetFont()
--   AGroupSSF             Animation for changing text size. Used by SetSizeFont()
--   AGroupOSF             Animation for changing the offset. Used by SetOffsetFont()
--
--
-- Parsed Layouts
--   ValueLayouts[TextIndex]
--     ValueOrder[Index]         -- Contains the real Value Index.  This sets the order that the
--                                  values will appear in.
--     FormatStrings[ValueIndex] -- Contains the formatted string for each value.
--     Layout                    -- Compiled formatted string created by SetValueFont()
--                                  The string is stored here so its not garbage collected. Since
--                                  SetValueFont can be called a lot.
--
-- Lowercase hash names are used for SetValueFont.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Triggers
--
--  InputValueTypesCheck             Checks the value type of the InputValue. Used by EnableTriggers()
--  DebuffTypesCheck                 Used for checking debuff magic types in CreateTriggerAuraCode()
--  TriggerObjectTypes[Type]         Types of triggers. Border, border color, font color, etc
--  TriggerMenuItems[Type]           This table is used to build the menus to pick what you are changing in the options
--  TriggerFns[Type]                 BarDB function to call to modify the bar object based on the Trigger Type
--  TriggerCanAnimate[Type]          Flags if the particular trigger type support animation
--  TriggerColorFnTypes[]            Types for color functions
--  TriggerColorFns[]                References to the functions based on ColorFnTypes
--  TriggerConvertColorIndex[]       Converts index into a color type or vise versa
--  TriggerConvertRegionBackdrop[]   Converts between region and backdrop type IDs
--
--  Settings
--  Settings[Bar function name]      Hash table using the function name that it was called by to store
--    [BoxNumber:Number]             BoxNumber:Number is stored as a string.
--                                     BoxNumber: -1 means region. otherwise boxnumber starting from 1
--                                     Number:    -1 means no BoxNumber and Number
--      Par[]                        Array containing the parameters for the settings
--
--  TriggerData
--    ActiveTriggers                           Contains reference to triggers that will be used during combat
--    ActiveBoxesAll[BoxNumber]                true or false. Used by the 'ALL' options.  This tells which boxes are active
--    ActiveBoxesCustom[Group][BoxNumber]      true or false. Used by SetTriggersCustomGroup()
--    ActiveObjects[BoxNumber][ObjectTypeID]   Objects actively being used. Contains the trigger index that last used the object
--                                             Used by DoTriggers(), CheckTriggers() and EnableTriggers()
--                                               0 : means no trigger modified that object so restore it
--                                              -1 : means restored.  Can't be restored till its used again first
--
--    InputValueTypes[]                        string: Type of input value:
--                                               'state'     Trigger can support state (boolean)
--                                               'whole'     Trigger can support whole numbers (integers)
--                                               'decimal'   Trigger can support floating point numbers
--                                               'percent'   Trigger can support percentages
--                                               'text'      Trigger can support strings
--    InputValueNames[]                        string: Name of the input value
--    InputValueNamesDropdown[]                Array: Used by trigger options
--    InputValues[InputName]                   This keeps track of the values set thru SetTriggers(). InputName is the name used in SetTriggers()
--
--    GroupsDropdown                           Pulldown menu contains the name of each group. Used by options
--    NameToGroup[GroupName]                   Returns group based on the name of that group
--
--    Groups[Index]
--      Name                        Name of the group. Usually this is the name of each box, like Rune 1, Rune 2, etc
--      BoxNumber                   Number of box or -1 for region
--      Type                        Type of group.
--                                    b   : Standard box 1 to 5 etc
--                                    r   : Region
--                                    a   : All boxes get changed
--                                    aa  : All active boxes get changed
--                                    ai  : All inactive boxes get changed
--      ObjectsDropdown[]           Pulldown menu contains the name of each object. Used by options
--      IndexObjectTypeID[]         Converts Index from ObjectDropdown into a type id. Used by options
--      ObjectTypeTypeID[]          Converts ObjectType into ObjectTypeID. This contains the first Type found in the objects
--      Objects[TypeID]             Object Type ID
--        Index                     Used by options
--        CanAnimate                true or false. If true then the object can use animation.
--        TexN[]                    Array of texture number or texture frame number.
--                                  If nil then the object doesn't use textures.
--        Fn                        Function to call
--
--
--                                  That are active. This is used by DoTriggers()
--
-- Triggers                          Array: Contains all the triggers created by the user
--   Static                          if true the trigger is always on
--   Disabled                        if true the trigger is not active
--   SpecEnabled                     If true then specializations are used by this trigger
--   OneTime                         number or false. A trigger can only execute once, then has to reactivate, Unless false.
--                                   Used by DoTriggers() and CheckTriggers()
--   Name                            Name of the trigger
--   GroupNumber                     GroupNumber in TriggerData.Groups[GroupNumber]
--   ObjectTypeID                    string: Tells which object is being used
--   Par1, Par2, Par3, Par4          Paramater data used in calling different functions
--                                   The type is variable based on what kind of function
--                                   is being used
--   ColorFnType                     Type of color function being used. Used by options and CheckTriggers()
--   ColorUnit                       string: Used for color triggers. Contains the unit
--   TextLine                        0 for all text lines or contains the current text line. If nil then the trigger is not using text.
--   CanAnimate                      true or false.  If true then the trigger can animate.
--   Animate                         true or false. if true then the trigger will animate
--   AnimateSpeed                    Speed to play the animation at.
--   OffsetAll                       true or false. Used for bar offset size or padding  By options.
--   ColorFn                         Color function
--   BarFn                           Bar Function to call to make changes to the bar
--
--   AurasOn                         true or false: Auras are either disabled or no aura options created
--   ConditionsOn                    true or false: Conditions are either disabled or no condition options created
--   ActiveAuras                     true or false: Auras was found to be active based on options
--
--   Conditions
--     Disabled                      if true all conditions are ignored
--     All                           if true then all conditions need to be true, otherwise just one
--     [Index]                       Array: Contains 0 or more conditions. 0 is reserved as the default
--        InputValueName             Name of the input being used
--        Operator                   Condition operator.  This changes based on the type of the InputValueName
--        Value                      Can be string, number, boolean.  Based on the type of the InputValueName
--
--   Talents
--     Disabled                      if true then all talents are ignored
--     All                           if true then all talents need to be found, otherwise just one
--     [Index]
--       SpellID                     The Spell ID of the talent
--       Equal                       if true then the talent has to match, otherwise has to not match
--       IsPvP                       if true then the talent is for PvP otherwise PvE
--       Minimized                   if true then the options are mostly hidden to save space
--
--   Auras
--     Disabled                      if true all auras are ignored
--     All                           if true then all auras need to be true, otherwise just one
--     [Index]
--       Minimized                   if true then the options are mostly hidden to save space
--       Inverse                     if true then the matching for the whole aura is reversed. Good for looking for inactive auras
--       Units[Index]                table: One or more units: player, target, focus, etc
--         'player'                  default, there will always be a default
--       SpellID                     SpellID of the aura. 0 means matches any aura
--       Own                         Number. Multi toggle:
--                                     0  Aura can be cast by the player or anyone else
--                                     1  Aura must be cast by the player
--                                     2  Aura must be cast by someone else
--
--       Type                        Type of buff. Multi toggle:
--                                     0  Aura can be a buff or debuff
--                                     1  Aura must be a buff
--                                     2  Aura must be a debuff
--       StackOperator               Operator for the number of stacks of the aura
--       Stacks                      Number of stacks the aura has or 0 for no stacks
--                                     each aura can match any of the debuff types to become true
--                                     each aura type can be true or false
--
--       CheckDebuffTypes            If true then the debuffs below will be checked
--       <debuff types>              Each of the debuff types can be true or false
--                                   if true then the aura has to match that debuff type
--                                   just one debuff type needs to match to be true
--       Curse
--       Disease
--       Enrage
--       Magic
--       Poison
--
-- If a triggers ObjectType can't be found.  That trigger is deleted.  If a condition
-- is using an Input Value Name that's not found.  That condition gets deleted.
-- Both of these things are done since if a trigger is copied to another bar.  That
-- bar may not have the same exact object or inputname
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- StatusBar Texture Frame
--
-- These work like blizzard status bars, except this can use 2 or more textures
-- as one statusbar. Can have as many statusbars or linked status bars as you want
--
-- To avoid conflicts and to make using this code in my bar code.  All keys start with
-- an underscore
--
--
-- Status Bar Frame
--
-- SBF              Status bar texture frame
-- SBF[Texture]     Hash lookup for texture
-- SBF[]            Array keeps track of all textures
--
-- SBF
--   _Width
--   _Height              Width and Height gets updated when ever something causes the statusbar to change size
--   _ScrollFrame         This combined with ContentFrame creates a way to do clipping.
--   _ContentFrame        Child of ScrollFrame.  This is where the textures go
--
-- OrientTexture          This keeps track of the where the Texure is positioned inside the statusbar frame.
--                        The perpose of OrientTexture is to be able to freely position the Texture anywhere
--                        while the Texture gets filled.
--                        In order to show the Texture getting filled. Its size needs to be changed. If the Texture
--                        below was position directly. It would effect were the Texture would appear
--                        using PixelOffsetX and PixelOffsetY. So the OrientTexture gets offset instead
--                        This is hard to explain.  Hope I was clear enough. Offsets are used by Fragment.lua
--
-- Texture
--   _SBF                 Reference to the SBF table
--   _OrientTexture       Rerrence to OrientTexture above
--
--   _Value               Current value of the texture. This is needed for StatusBarDrawTexture() when not
--                        specifying a value. Set by StatusBarSetValue()
--   _MaxRange            The maximum value it takes to draw all of the texture
--                        In a linktexture it sets the range of all the linked texture as a whole
--
--   _MaxValue            Limits the texture to this value.  Textures will be clipped to this value
--                        Used by StatusBarSetValue() and StatusBarDrawTexture()
--
--                        NOTES: In a linktexture in overlap mode.  If the value is equal to MaxValue then
--                               the whole texture will be drawn
--
--   _ScaleHorizontalX    Only applies in horizontal mode
--   _ScaleHorizontalY    Only applies in horizontal mode
--   _ScaleVerticalX      Only applies in vertical mode
--   _ScaleVerticalY      Only applies in vertical mode
--
--                        NOTES: ScaleX and ScaleY change the size of the texture. That's it.  ScaleX and ScaleY is relative
--                               to size of the statusbar frame
--
--   _Hidden              If true then the texture is hidden, otherwise false
--
--   _TexLeft
--   _TexRight
--   _TexTop
--   _TexBottom           Texture coordinates
--
--   _PixelPoint
--   _PixelOffsetX
--   _PixelOffsetY        These 3 values are a setpoint(PixelPoint, PixelOffsetX, PixelOffsetY
--                        if not set then these values are nil
--
--   _PixelWidth          Width of the texture in pixels. Overrides _Width
--   _PixelHeight         Height of the texture in pixels. Overrides _Height
--   _PixelLength         Overrides _PixelWidth when FillDirection is horizontal
--                        Overrides _PixelHeight when FillDirection is vertical
--                        NOTES: _PixelWidth, _PixelHeight, and _PixelLength are nil
--                               if not set
--
--   _EdgeFrames[Texture] Contains a pool of edgeframes for reuse
--
--
--   In a link. Only the first texture is used for these values
--   ----------------------------------------------------------
--   _Rotation            -90  : Rotated 90 degrees counter clockwise
--                         0   : No rotation. Textures are displayed from left to right
--                         90  : Rotated 90 degrees clockwise
--                         180 : Rotated 180 degrees.  This makes the textures upsidedown
--   _FillDirection       'HORIZONTAL'  : Draw from left to right
--                        'VERTICAL'    : Draw from bottom to top
--   _SyncFillDirection   true or false : Makes it so the fill direction changes based on _Rotation
--   _ReverseFill         true or false : Reverse the fill direction
--   _Clipping            true or false : Texture is clipped instead of being stretched
--
--
--   Linked (first texture only)
--   ---------------------------
--   _Textures             Array containing all the textures linked. Only exists in the first texture of a link
--   _Textures[Texture]    Hash table used to find matching textures used by StatusBarLink()
--   _HideFull             true or false : Hides the texture if full in a linked texture
--   _Overlap              true or false : Makes linked textures overlap eachother instead of next to eachother
--
--
--   Linked
--   ---------------------
--   _Link                 (in all textures)             Means the texture is part of a link. Also contains a reference
--                                                       to the first texture in the link
--   _Prev                 (Isn't in the first texture)  Previous texture in the link. Doesn't exist in the first link
--
--
--   Tagged
--   ------
--   _Tagged[]          Hash table of all the textures or linked. Tagged to this one
--   _TaggedToTexture   Contains the texture or linked texture that it's tagged to. Used by StatusBarTag()
--
--   _TagRightToLeft    Tagged textures will grow from right to left from the texture they're tagged to
--                      If nil then the tagged textures will grow from left to right instead
--   _EdgeFrame         A frame that keeps the same length of a texture or link textures. Used by tagged
--                      textures. StatusBarTag()
--   _TagInherit        true or false : if false, then it will not pull stats like FILLDIRECTION from the
--                      texture it's tagged to
--
--
--   Frame/Texture layout
--   --------------------
--   StatusBar Frame
--     ScrollFrame           Scroller for the ContentFrame. Except this will never scroll
--       ContentFrame        All textures that need clipping are contained in here
--         OrientTexture     This holds the texture in place as the texture changes size
--                           to grow or shrink
--         Texture           One or more textures
--     NoClipFrame           Only difference is textures don't get clipped
--         OrientTexture     This holds the texture in place as the texture changes size
--                           to grow or shrink
--         Texture           One or more textures
--
--
-- NOTES: Theres no limit to how many statusbars you can have. But there's a max of
--        16 sublayers. Don't think I'll ever need more than this.
--
--        Can have as many linked textures as you want
--        Can only tag a texture or a link texture to another texture or linked texture
--        Can not tag a texture or linked texture that is already tagged to something else
--
--        Each texture has its own maxvalue and maxrange.  The texture can never draw past this
--
--        Linked textures use Rotation, SyncFillDirection, FillDirection, ReverseFill from
--        the first texture in the link.  If the texture or linked texture is tagged to something. Then
--        these values are pulled from that texture or first texture if its a linked texture.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Animation
--
-- AnimationType               Table that converts type into a usable type for CreateAnimation.  Used by GetAnimation()
--
-- AGroups[AType]              Contains animation groups and animations.  This is created and used by GetAnimation()
--                             AType is address of the Object and the Type.  See below for different types.
--   Animation                 Child of AGroup. Created by CreateAnimationGroup()
--
--   ScaleFrame                Currently used for scaling the Anchor (unitbar)
--     x, y                    Coordinates of the Objects 'CENTER'
--     ObjectParent            The Objects Parent.  Object:GetParent()
--   Group                     Contains the Animation Group.  child of Object
--     Animation               Reference to Animation. Used by StopAnimation()
--   Object                    Object that will be animated. Can be frame or texture.
--   OnObject                  Used by custom animations.  Points to the object being used in OnUpdate scripts.
--   GroupType                 string. Type of group:
--                               'Parent'     This is created for the the bar when hiding or showing.
--                               'Children'   This is created for any textures or frame the bar uses.
--   Type                      string. See GetAnimation() for a list.
--   StopPlayingFn             Call back function.  This gets called when ever StopPlaying() is called
--
--
--   These keys are only used for alpha and scale, otherwise nil
--   -----------------------------------------------------------
--   Direction                 'in' or 'out' out means will hide after done, otherwise show.
--   DurationIn                Duration in seconds to play animation after showing an Object.
--   DurationOut               Duration in seconds to play animation before hiding an object.
--   -----------------------
--
--   FromValue                 Where the animation is starting from.
--   ToValue                   Where the animation is going to.
--
--   InUse                     Contains a list of Animations being used for each Object.
--     AGroup                  reference to AGroup.
-------------------------------------------------------------------------------
local DragObjectMouseOverDesc = 'Modifier + right mouse button to drag this object'

local BarDB = {}
local BarTextData = {}

local DoOptionData = {}
local CalledByTrigger = false
local AnimateSpeedTrigger
local MaxTextLines = 4

local BoxFrames
local NextBoxFrame = 0
local LastBox = true

-- Used by ParseLayoutFont() for validating formatted text.
local TestFontString = CreateFrame('Frame'):CreateFontString()
      TestFontString:SetFont(LSM:Fetch('font', Type), 10, 'NONE')

-- Constants used in NumberToDigitGroups
local Thousands = strmatch(format('%.1f', 1/5), '([^0-9])') == '.' and ',' or '.'
local BillionFormat = '%s%d' .. Thousands .. '%03d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local MillionFormat = '%s%d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local ThousandFormat = '%s%d' .. Thousands ..'%03d'

                       -- 1   2   3   4   5   6   7   8  9 10 11 12 13 14 15 16
local ConvertSublayer = {-8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7}

local RotationFillDirection = {
  [-90] = 'VERTICAL',
  [0]   = 'HORIZONTAL',
  [90]  = 'VERTICAL',
  [180] = 'HORIZONTAL',
}

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

local TriggerObjectTypes = {
  BackgroundBorder      = 'border',
  BackgroundBorderColor = 'bordercolor',
  BackgroundBackground  = 'background',
  BackgroundColor       = 'backgroundcolor',
  BarTexture            = 'bartexture',
  BarColor              = 'bartexturecolor',
  TextureScale          = 'texturescale',
  BarOffset             = 'baroffset',
  TextFontColor         = 'fontcolor',
  TextFontOffset        = 'fontoffset',
  TextFontSize          = 'fontsize',
  TextFontType          = 'fonttype',
  TextFontStyle         = 'fontstyle',
  RegionBorder          = 'regionborder',
  RegionBorderColor     = 'regionbordercolor',
  RegionBackground      = 'regionbackground',
  RegionBackgroundColor = 'regionbackgroundcolor',
  Sound                 = 'sound',
}
GUB.Bar.TriggerObjectTypes = TriggerObjectTypes
local OT = TriggerObjectTypes

local TriggerMenuItems = {
  [OT.BackgroundBorder     ] = 'BG: Border',
  [OT.BackgroundBorderColor] = 'BG: Border Color',
  [OT.BackgroundBackground ] = 'BG: Background',
  [OT.BackgroundColor      ] = 'BG: Background Color',
  [OT.BarTexture           ] = 'Bar: Texture',
  [OT.BarColor             ] = 'Bar: Color',
  [OT.TextureScale         ] = 'Texture Scale',
  [OT.BarOffset            ] = 'Bar: Offset',
  [OT.TextFontColor        ] = 'Text: Font Color',
  [OT.TextFontOffset       ] = 'Text: Font Offset',
  [OT.TextFontSize         ] = 'Text: Font Size',
  [OT.TextFontType         ] = 'Text: Font Type',
  [OT.TextFontStyle        ] = 'Text: Font Style',
  [OT.RegionBorder         ] = 'Region: Border',
  [OT.RegionBorderColor    ] = 'Region: Border Color',
  [OT.RegionBackground     ] = 'Region: Background',
  [OT.RegionBackgroundColor] = 'Region: Background Color',
  [OT.Sound                ] = 'Sound',
}

local TriggerFns = {
  [OT.BackgroundBorder     ] = 'SetBackdropBorder',
  [OT.BackgroundBorderColor] = 'SetBackdropBorderColor',
  [OT.BackgroundBackground ] = 'SetBackdrop',
  [OT.BackgroundColor      ] = 'SetBackdropColor',
  [OT.BarTexture           ] = 'SetTexture',
  [OT.BarColor             ] = 'SetColorTexture',
  [OT.TextureScale         ] = 'SetScaleAllTexture',
  [OT.BarOffset            ] = 'SetOffsetTextureFrame',
  [OT.TextFontColor        ] = 'SetColorFont',
  [OT.TextFontOffset       ] = 'SetOffsetFont',
  [OT.TextFontSize         ] = 'SetSizeFont',
  [OT.TextFontType         ] = 'SetTypeFont',
  [OT.TextFontStyle        ] = 'SetStyleFont',
  [OT.RegionBorder         ] = 'SetBackdropBorderRegion',
  [OT.RegionBorderColor    ] = 'SetBackdropBorderColorRegion',
  [OT.RegionBackground     ] = 'SetBackdropRegion',
  [OT.RegionBackgroundColor] = 'SetBackdropColorRegion',
  [OT.Sound                ] = 'PlaySound',
}

-- For animation functions
local TriggerCanAnimate = {
  [OT.TextureScale         ] = true,
  [OT.BarOffset            ] = true,
  [OT.TextFontOffset       ] = true,
  [OT.TextFontSize         ] = true,
}

-- Convert 6.60 trigger type to ObjectType
local Trigger660TypeObjectType = {
  ['bg border'               ] = OT.BackgroundBorder,
  ['bg border color'         ] = OT.BackgroundBorderColor,
  ['bg background'           ] = OT.BackgroundBackground,
  ['bg background color'     ] = OT.BackgroundColor,
  ['bar texture'             ] = OT.BarTexture,
  ['bar color'               ] = OT.BarColor,
  ['texture scale'           ] = OT.TextureScale,
  ['bar offset'              ] = OT.BarOffset,
  ['text font color'         ] = OT.TextFontColor,
  ['text font offset'        ] = OT.TextFontOffset,
  ['text font size'          ] = OT.TextFontSize,
  ['text font type'          ] = OT.TextFontType,
  ['text font style'         ] = OT.TextFontStyle,
  ['region border'           ] = OT.RegionBorder,
  ['region border color'     ] = OT.RegionBorderColor,
  ['region background'       ] = OT.RegionBackground,
  ['region background color' ] = OT.RegionBackgroundColor,
  ['sound'                   ] = OT.Sound,
}

-- Convert 6.60 trigger type to ObjectTypeID
local Trigger660TypeOldTypeID = {

  -- Health bar
  ['bar texture (predicted...)'] = OT.BarTexture .. ':7',
  ['bar color (predicted...)'  ] = OT.BarColor   .. ':8',
  ['bar texture (cost)'        ] = OT.BarTexture .. ':9',
  ['bar color (cost)'          ] = OT.BarColor   .. ':10',

  -- fragment bar
  ['bg border  [ shard ]'          ] = OT.BackgroundBorder .. ':1',
  ['bg border  [ ember ]'          ] = OT.BackgroundBorder .. ':2',
  ['bg border color  [ shard ]'    ] = OT.BackgroundBorderColor .. ':3',
  ['bg border color  [ ember ]'    ] = OT.BackgroundBorderColor .. ':4',
  ['bg background  [ shard ]'      ] = OT.BackgroundBackground .. ':5',
  ['bg background  [ ember ]'      ] = OT.BackgroundBackground .. ':6',
  ['bg background color  [ shard ]'] = OT.BackgroundColor .. ':7',
  ['bg background color  [ ember ]'] = OT.BackgroundColor .. ':8',
  ['bar texture  [ shard ]'        ] = OT.BarTexture .. ':9',
  ['bar texture  [ ember ]'        ] = OT.BarTexture .. ':10',
  ['bar texture (full)  [ shard ]' ] = OT.BarTexture .. ':11',
  ['bar texture (full)  [ ember ]' ] = OT.BarTexture .. ':12',
  ['bar color  [ shard ]'          ] = OT.BarColor .. ':13',
  ['bar color  [ ember ]'          ] = OT.BarColor .. ':14',
  ['bar color (full)  [ shard ]'   ] = OT.BarColor .. ':15',
  ['bar color (full)  [ ember ]'   ] = OT.BarColor .. ':16',
  ['bar offset  [ shard ]'         ] = OT.BarOffset .. ':17',
  ['bar offset  [ ember ]'         ] = OT.BarOffset .. ':18',

  -- stagger vbar,
  ['bar texture (continued)'       ] = OT.BarTexture .. ':6',
  ['bar color (continued)'         ] = OT.BarColor .. ':7',
}

local Trigger660IsAll = {
  ComboBar    = {[12] = 7},
  ArcaneBar   = {[5]  = 5},
  ChiBar      = {[7]  = 7},
  FragmentBar = {[6]  = 6},
  HolyBar     = {[6]  = 6},
  RuneBar     = {[7]  = 7},
  ShardBar    = {[6]  = 6},
}

local Trigger660Region = {
  ComboBar    = {[13] = 10},
  ArcaneBar   = {[6]  = 8 },
  ChiBar      = {[8]  = 10},
  FragmentBar = {[7]  = 9 },
  HolyBar     = {[7]  = 9 },
  RuneBar     = {[8]  = 10},
  ShardBar    = {[7]  = 9 },
}

local Trigger660ValueType = {
  AltPowerBar = { ['Counter Time']        = 'Counter Time'           },
  ComboBar    = { ['Total Points']        = 'Combo Points'           },
  FragmentBar = { ['Fragments']           = 'Fragments %s',
                  ['Fragments (percent)'] = 'Fragments %s (percent)' },
  RuneBar     = { ['Recharging']          = 'Recharging %s',
                  ['Time']                = 'Time %s'                }
}

local TriggerColorFnTypes = {
  ClassColor  = 'GetClassColor',
  PowerColor  = 'GetPowerColor',
  CombatColor = 'GetCombatColor',
  TaggedColor = 'GetTaggedColor',
}

local TriggerColorFns = {
  [TriggerColorFnTypes.ClassColor ] = Main.GetClassColor,
  [TriggerColorFnTypes.PowerColor ] = Main.GetPowerColor,
  [TriggerColorFnTypes.CombatColor] = Main.GetCombatColor,
  [TriggerColorFnTypes.TaggedColor] = Main.GetTaggedColor,
}

GUB.Bar.TriggerConvertColorIndex = {
  [1] = TriggerColorFnTypes.ClassColor,
  [2] = TriggerColorFnTypes.PowerColor,
  [3] = TriggerColorFnTypes.CombatColor,
  [4] = TriggerColorFnTypes.TaggedColor,
  [5] = '',
  [TriggerColorFnTypes.ClassColor ] = 1,
  [TriggerColorFnTypes.PowerColor ] = 2,
  [TriggerColorFnTypes.CombatColor] = 3,
  [TriggerColorFnTypes.TaggedColor] = 4,
  ['']                              = 5,
}

local TriggerConvertRegionBackdrop = {
  [OT.RegionBorder         ] = OT.BackgroundBorder,
  [OT.RegionBorderColor    ] = OT.BackgroundBorderColor,
  [OT.RegionBackground     ] = OT.BackgroundBackground,
  [OT.RegionBackgroundColor] = OT.BackgroundColor,
  [OT.BackgroundBorder     ] = OT.RegionBorder,
  [OT.BackgroundBorderColor] = OT.RegionBorderColor,
  [OT.BackgroundBackground ] = OT.RegionBackground,
  [OT.BackgroundColor      ] = OT.RegionBackgroundColor,
}

GUB.Bar.TriggerColorPulldown = {
  'Class Color',   -- 1
  'Power Color',   -- 2
  'Combat Color',  -- 3
  'Tagged Color',  -- 4
  'None',          -- 5
}

local AnimationType = {
  alpha        = 'Alpha',
  scale        = 'Scale',
  texturescale = 'Scale',
  move         = 'Alpha', -- Custom animation.  Animate moving and sizing text dont work together. So need to use custom.
  fontsize     = 'Alpha', -- Custom animation
  offset       = 'Alpha', -- Custom animation
}

-- Convert ValueName to a Tag name
local ValueLayoutTag = {
  current         = 'value',
  maximum         = 'max',
  predictedhealth = 'phealth',
  predictedpower  = 'ppower',
  predictedcost   = 'pcost',
  absorbhealth    = 'ahealth',
  name            = 'name',
  level           = 'level',
  time            = 'time',
  powername       = 'ptext',
  counter         = 'count',
  countermin      = 'minc',
  countermax      = 'maxc',
}

-- To generate sample text
local ParValuesTest = {
  current         = 100000,
  maximum         = 200000,
  predictedhealth = 50000,
  predictedpower  = 5000,
  predictedcost   = 5000,
  absorbhealth    = 50000,
  name            = 'Testname',
  name2           = 'Testrealm',
  level           = 100,
  level2          = 99,
  time            = 1.00,
  powername       = 'Test text',
  counter         = 100,
  countermin      = 1,
  countermax      = 99,
}

-- Used to validate each formatted string
local ValueLayoutTest = {
  whole = 1,
  whole_dgroups = 'string',
  thousands_dgroups = 'string',
  millions_dgroups = 'string',
  short_dgroups = 'string',
  percent = 1,
  thousands = 1,
  millions = 1,
  short = 'string',
  unitname = 'string',
  realmname = 'string',
  unitnamerealm = 'string',
  unitlevel = 'string',
  scaledlevel = 'string',
  unitlevelscaled = 'string',
  timeSS = 1,
  timeSS_H = 1,
  timeSS_HH = 1,
  text = 'string',
  counter = 1,
  countermin = 1,
  countermax = 1,
}

-- Convert ValueType to a format string
local GetValueLayout = {
  whole = '%.f',
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
  unitlevel = '%s',
  scaledlevel = '%s',
  unitlevelscaled = '%s',
  timeSS = '%d',
  timeSS_H = '%.1f',
  timeSS_HH = '%.2f',
  text = '%s',
}

-- Used to hold parameter values passed to SetValueFont()
local ParValues = {}

local DefaultBackdrop = {
  bgFile   = '' ,
  edgeFile = '',
  tile = false,  -- True to repeat the background texture to fill the frame, false to scale it.
  tileSize = 16, -- Size (width or height) of the square repeating background tiles (in pixels).
  edgeSize = 12, -- Thickness of edge segments and square size of edge corners (in pixels).
  insets = {     -- Positive values shrink the border inwards, negative expand it outwards.
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

local FrameBorder = {
  bgFile   = '',
  edgeFile = [[Interface\Addons\GalvinUnitBars\Textures\GUB_SquareBorder]],
  tile = false,
  tileSize = 16,
  edgeSize = 6,
  insets = {
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

local AnchorPointWord = {
  LEFT = 'Left',
  RIGHT = 'Right',
  TOP = 'Top',
  BOTTOM = 'Bottom',
  TOPLEFT = 'Top Left',
  TOPRIGHT = 'Top Right',
  BOTTOMLEFT = 'Bottom Left',
  BOTTOMRIGHT = 'Bottom Right',
  CENTER = 'Center'
}

local InputValueTypesCheck = {
  state   = 1,
  whole   = 1,
  decimal = 1,
  percent = 1,
  text    = 1,
}

local DebuffTypesCheck = {
  'Curse',      -- 1
  'Disease',    -- 2
  'Enrage',     -- 3
  'Magic',      -- 4
  'Poison',     -- 5
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
-- RestoreBackdrops
--
-- Goes thru every child frame and child of that frame and so on.  And resets
-- the backdrop.
--
-- Frame            Starting frame
--
-- NOTES: The perpose of this function is when you scale a frame thats hidden
--        the backdrop border gets corrupted.  So this will go thru each frame
--        and reset the backdrop on the next frame update.
--        You'll see a quick flicker of the corrupted border, best I can do.
--        Maybe once blizzard gets rid of backdrops and makes it part of the frame
--        its self these types of bugs won't happen.
-------------------------------------------------------------------------------
--[[
local function RestoreFrameOnUpdate(RestoreFrame)
  RestoreFrame:SetScript('OnUpdate', nil)

  local r, g, b, a = RestoreFrame:GetBackdropColor()
  local r1, g1, b1, a1 = RestoreFrame:GetBackdropBorderColor()

  RestoreFrame:SetBackdrop(RestoreFrame.Backdrop)
  RestoreFrame:SetBackdropColor(r, g, b, a)
  RestoreFrame:SetBackdropBorderColor(r1, g1, b1, a1)
end

local function RestoreBackdrops(Frame)
  if true then return end
  local function RestoreBackdrop(...)
    local Found = false

    for Index = 1, select('#', ...) do
      local Frame = select(Index, ...)

      if not RestoreBackdrop(Frame:GetChildren()) then

        -- No children found so use this frame.
        -- Check if frame has a backdrop
        local Backdrop = Frame.GetBackdrop and Frame:GetBackdrop()

        if Backdrop then
          local RestoreFrame = Frame.RestoreFrame

          if RestoreFrame == nil then
            RestoreFrame = {}
            Frame.RestoreFrame = RestoreFrame
          end
          RestoreFrame.Backdrop = Backdrop
          Frame:SetScript('OnUpdate', RestoreFrameOnUpdate)
        end
      end
    end
    return Found
  end
  --RestoreBackdrop(Frame)
end ]]

-------------------------------------------------------------------------------
-- GetSpeed
--
-- Returns how fast a value is changing
--
-- LastValue      The last value before updating Value.
-- Value          Current Value.
-- LastTime       Time that LastValue was set
-- Time           Current time.
-------------------------------------------------------------------------------
local function GetSpeed(LastValue, Value, LastTime, Time)
  local Diff = abs(LastValue - Value)
  local TimeDiff = Time - LastTime

  if TimeDiff > 0 then
    return Diff / TimeDiff
  else
    return 0
  end
end

-------------------------------------------------------------------------------
-- GetSpeedDuration
--
-- Returns a speed in duration in seconds.
--
-- Range          Amount of units to complete.
-- Speed          Speed must be between 0 and 1. 0 gives back a duration of 0
--
-- Returns:
--   Duration     Time in seconds to play the animation.
--                This will always create a constant animation speed.
-------------------------------------------------------------------------------
local function GetSpeedDuration(Range, Speed)
  if Speed <= 0 then
    return 0
  end
  return abs(Range) / (1000 * Speed)
end

-------------------------------------------------------------------------------
-- SaveSettings
--
-- Saves parameters from set a set function. Used for triggers.
--
-- Usage:    SaveSettings(BarDB, BarFnName, BoxNumber, TexN, ...)
--           SaveSettings(BarDB, BarFnName, nil, nil, ...)
--
-- BarDB            Contains the settings.
-- BarFnName        string: Bar function to call
-- BoxNumber        If 0 then settings are saved under all boxes. Otherwise > 0
--                  If -1, then no boxnumber or number is used. Used for Region
-- Number           Texture number or texture frame number or text line.
-- ...              Paramater data to save.
--
-- This only saves if the set function wasn't called by a trigger.
-------------------------------------------------------------------------------
local function SaveSettings(BarDB, BarFnName, BoxNumber, Number, ...)
  if BarFnName == nil or BarDB[BarFnName] == nil then
    assert(false, 'SaveSettings - function not found or nil')
  end

  if not CalledByTrigger then
    local Settings = BarDB.Settings

    if Settings == nil then
      Settings = {}
      BarDB.Settings = Settings
    end
    local Setting = Settings[BarFnName]

    if Setting == nil then
      Setting = {}
      Settings[BarFnName] = Setting
    end

    if BoxNumber == nil and Number == nil then
      BoxNumber = -1
      Number = -1
    end

    local BoxNumberStart = BoxNumber
    local NumBoxes = BoxNumber

    -- loop all boxes if box number is zero.
    if BoxNumber == 0 then
      BoxNumberStart = 1
      NumBoxes = BarDB.NumBoxes
    end

    for BoxNumber = BoxNumberStart, NumBoxes do
      local ID = BoxNumber .. ':' .. Number
      local Pars = Setting[ID]

      if Pars == nil then
        Setting[ID] = {...}
      else
        for Index = 1, select('#', ...) do
          Pars[Index] = select(Index, ...)
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- RestoreSettings
--
-- Calls a function with the same settings that it was last called outside
-- of the trigger system.
--
-- Usage:    RestoreSettings(BarDB, BarFnName, BoxNumber, Number)
--             Restore just the BoxNumber and Number under this function
--
--           RestoreSettings(BarDB, BarFnName, BoxNumber)
--             Restore everything matching BoxNumber under this function
--
--           RestoreSettings(BarDB, BarFnName)
--             Restore just this function
--
--           RestoreSettings(BarDB) This will restore everything
--             Restore Everything
--
-- BarDB          Contains the settings.
-- BarFn          Bar function to call. Must exist in settings.
-- BoxNumber      Box to restore in the bar. If nil or can specify -1 for nil. Then Number is ignored. Cant use 0.
-- Number         Texture number or texture frame number or text line. If nil then matches all textures
--                under BoxNumber.
-------------------------------------------------------------------------------
local function RestoreSettings(BarDB, BarFnName, BoxNumber, Number)
  local Settings = BarDB.Settings

  if Settings then
    -- Check for full restore
    if BarFnName == nil then
      for BarFnName, Setting in pairs(Settings) do
        for Location, Pars in pairs(Setting) do
          local BarFn = BarDB[BarFnName]

          BoxNumber, Number = strsplit(':', Location)
          BoxNumber = tonumber(BoxNumber)
          Number = tonumber(Number)

          if BoxNumber == -1 then
            BarFn(BarDB, unpack(Pars))
          else
            BarFn(BarDB, BoxNumber, Number, unpack(Pars))
          end
        end
      end
    else
      local Setting = Settings[BarFnName]

      if Setting then
        local BarFn = BarDB[BarFnName]

        if BoxNumber == nil or BoxNumber == -1 then
          BarFn(BarDB, unpack(Setting['-1:-1']))

        elseif Number ~= nil then
          BarFn(BarDB, BoxNumber, Number, unpack(Setting[ format('%s:%s', BoxNumber, Number) ]) )

        else
          for ID, Pars in pairs(Setting) do
            local BN, Number = strsplit(':', ID)
            BN = tonumber(BN)
            Number = tonumber(Number)

            if BoxNumber == BN then
              BarFn(BarDB, BN, Number, unpack(Pars))
            end
          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- GetBackdrop
--
-- Gets a backdrop from a backdrop settings table. And saves it to Object.
--
-- Object     Object to save the backdrop to.
--
-- Returns:
--  BackdropInfo   Blizzards backdrop table
--                 If object already has a backdrop it returns that one instead.
-------------------------------------------------------------------------------
local function GetBackdrop(Object)
  local Backdrop = Object.backdropInfo

  if Backdrop == nil then
    Backdrop = {}

    Main:CopyTableValues(DefaultBackdrop, Backdrop, true)
    Object.backdropInfo = Backdrop
  end

  return Backdrop
end

-------------------------------------------------------------------------------
-- SetBackdrop
--
-- Sets a backdrop while preserving the backdrop color and border color.
-- These colors will get reset each time backdrop is set.
--
-- Frame       Frame that backdrop is being set to
-------------------------------------------------------------------------------
local function SetBackdrop(Frame)
  local r, g, b, a = Frame:GetBackdropColor()
  local r1, g1, b1, a1 = Frame:GetBackdropBorderColor()

  -- Call ApplyBackdrop. Frame.backdropInfo gets used there
  Frame:ApplyBackdrop()
  Frame:SetBackdropColor(r or 1, g or 1, b or 1, a or 1)
  Frame:SetBackdropBorderColor(r1 or 1, g1 or 1, b1 or 1, a1 or 1)
end

-------------------------------------------------------------------------------
-- SetOffsetFrame
--
-- Offsets the current frame by its 4 sides.
--
-- Returns false if the frame was too small.
-------------------------------------------------------------------------------
local function SetOffsetFrame(Frame, Left, Right, Top, Bottom)

  Frame:ClearAllPoints()

  Frame:SetPoint('LEFT', Left, 0)
  Frame:SetPoint('RIGHT', Right, 0)
  Frame:SetPoint('TOP', 0, Top)
  Frame:SetPoint('BOTTOM', 0, Bottom)

  -- Check for invalid offset
  local x, y = Frame:GetSize()

  if x < 10 or y < 10 then
    Frame:SetPoint('LEFT')
    Frame:SetPoint('RIGHT')
    Frame:SetPoint('TOP')
    Frame:SetPoint('BOTTOM')

    return false
  else
    return true
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
--
-- returns:
--   OffsetX  < 0 then outside the parent frame.
--   OffsetY  > 0 then outside the parent frame.
--   width    Total width that covers the child frames.
--   height   Total height that covers the child frames.
-------------------------------------------------------------------------------
local function GetBoundsRect(ParentFrame, Frames)
  local Left
  local Right
  local Top
  local Bottom
  local LastLeft
  local LastRight
  local LastTop
  local LastBottom
  local FirstFrame = true

  -- For some reason ParentFrame:GetLeft() doesn't work right unless
  -- its called before dealing with child frame.
  local ParentLeft = ParentFrame:GetLeft()
  local ParentTop = ParentFrame:GetTop()

  for Index = 1, #Frames do
    local Frame = Frames[Index]

    if not Frame.Hidden and not Frame.IgnoreBorder then
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
    -- See comments above
    return Left - ParentLeft, Top - ParentTop,   Right - Left, Top - Bottom
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
--        another frame.  So we need to get all the locations first then set their
--        points again
-------------------------------------------------------------------------------
local function SetFrames(ParentFrame, Frames, OffsetX, OffsetY)
  local PointFrame
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
    local UB = BarDB.Anchor.UnitBar
    local AnchorPoint = AnchorPointWord[UB.Attributes.AnchorPoint]
    local BarX, BarY = floor(UB._x + 0.5), floor(UB._y + 0.5)

    -- Is this a boxframe?
    if Frame.BF then
      local BF = Frame.BF
      local BoxX, BoxY = GetRect(BF)
      BoxX, BoxY = floor(BoxX + 0.5), floor(BoxY + 0.5)

      return format('Bar - %s (%d, %d)  Box (%d, %d)', AnchorPoint, BarX, BarY, BoxX, BoxY)
    else
      return format('Bar - %s (%d, %d)', AnchorPoint, BarX, BarY)
    end
  end
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Misc functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- PlaySound
--
-- Plays the sound file specified.
--
-- SoundName    Name of the sound to play.
-- Channel      Sound channel.
-------------------------------------------------------------------------------
function BarDB:PlaySound(SoundName, Channel)
  -- No SaveSettings for sound. Since there is nothing visual to restore.

  if not Main.ProfileChanged and not Main.IsDead then
    local SoundFile = LSM:Fetch('sound', SoundName, true)

    if SoundFile then
      pcall(PlaySoundFile, SoundFile, Channel)
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
          local Index1
          local Index2
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
-- EnableDragRegion
--
-- Allows the region to be dragged with the mouse
--
-- Enable     true or false. Enables or disables mouse dragging
-------------------------------------------------------------------------------
function BarDB:EnableDragRegion(Enable)
  local Region = self.Region

  Region.Anchor = self.Anchor
  Region.BarDB = self

  if Enable then
    Region:SetScript('OnMouseDown', StartMoving)
    Region:SetScript('OnMouseUp', StopMoving)
    Region:SetScript('OnHide', StopMoving)
  else
    Region:SetScript('OnMouseDown', nil)
    Region:SetScript('OnMouseUp', nil)
    Region:SetScript('OnHide', nil)
  end
  Region:EnableMouse(Enable)
  Region:SetMouseClickEnabled(Enable)
  Region.EnableDrag = Enable
end

-------------------------------------------------------------------------------
-- EnableDragBox
--
-- Allows the box frame to be dragged with the mouse
--
-- BoxNumber            BoxFrame to drag
-- Enable               true or false. Enables or disables mouse dragging
-------------------------------------------------------------------------------
function BarDB:EnableDragBox(BoxNumber, Enable)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)

    BoxFrame.Anchor = self.Anchor
    BoxFrame.BarDB = self
    BoxFrame.BF = BoxFrame

    if Enable then
      BoxFrame:SetScript('OnMouseDown', StartMoving)
      BoxFrame:SetScript('OnMouseUp', StopMoving)
      BoxFrame:SetScript('OnHide', StopMoving)
    else
      BoxFrame:SetScript('OnMouseDown', nil)
      BoxFrame:SetScript('OnMouseUp', nil)
      BoxFrame:SetScript('OnHide', nil)
    end
    BoxFrame:EnableMouse(Enable)
    BoxFrame:SetMouseClickEnabled(Enable)
    BoxFrame.EnableDrag = Enable
  until LastBox
end

-------------------------------------------------------------------------------
-- EnableTooltipsRegion
--
-- Enable or disable tooltips for the region
--
-- Enable               true or false. Enables or disables mouse dragging
-------------------------------------------------------------------------------
function BarDB:EnableTooltipsRegion(Enable)
  local Region = self.Region
  local EnableDrag = Region.EnableDrag

  if Enable then
    Region:SetScript('OnEnter', ShowTooltip)
    Region:SetScript('OnLeave', HideTooltip)
  else
    Region:SetScript('OnEnter', nil)
    Region:SetScript('OnLeave', nil)
  end
  Region:SetMouseClickEnabled(EnableDrag)
end

-------------------------------------------------------------------------------
-- EnableTooltipsBox
--
-- Enable or disable tooltips for the box frame
--
-- BoxNumber            BoxFrame to drag
-- Enable               true or false. Enables or disables mouse dragging
-------------------------------------------------------------------------------
function BarDB:EnableTooltipsBox(BoxNumber, Enable)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)
    local EnableDrag = BoxFrame.EnableDrag

    if Enable then
      BoxFrame:SetScript('OnEnter', ShowTooltip)
      BoxFrame:SetScript('OnLeave', HideTooltip)
    else
      BoxFrame:SetScript('OnEnter', nil)
      BoxFrame:SetScript('OnLeave', nil)
    end
    BoxFrame:SetMouseClickEnabled(EnableDrag)
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
end

-------------------------------------------------------------------------------
-- SetTooltipBox
--
-- Set tooltips to be shown on a boxframe or texture frame.
--
-- BoxNumber            Box frame to add a tooltip too.
-- TextureFrameNumber   if not nil then texture frame is used instead.
-- Name                 Name that will appear in the tooltip.
--
-- NOTES: The name is set to the boxframe.
-------------------------------------------------------------------------------
function BarDB:SetTooltipBox(BoxNumber, Name)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)

    BoxFrame.BarDB = self
    BoxFrame.BF = BoxFrame
    BoxFrame.Name = Name
  until LastBox
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Custom Statusbar functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- StatusBarDrawTexture
--
-- Draws a texture in the statusbar frame.
--
-- Subfunction of StatusBarSetValue()
--
-- NOTES: When using texcoord to rotate texture 90 degrees clockwise
--        BOTTOM and TOP work horizontally for clipping the texture
--
-- ULx ULy   LLx LLy    URx URy   LRx LRy
-------------------------------------------------------------------------------
local function StatusBarDrawTexture(SBF, Texture, Value, MaxValue, SBFWidth, SBFHeight, Rotation, FillDirection, ReverseFill, Clipping)
  if Value == nil then
    assert(false, "DrawTexture - Value can't be nill")
  elseif Value > 1 then
    assert(false, "DrawTexture - Value can't be greater than 1")
  end

  local TexLeft, TexRight, TexTop, TexBottom = Texture._TexLeft, Texture._TexRight, Texture._TexTop, Texture._TexBottom
  local Width = Texture._PixelWidth or SBFWidth
  local Height = Texture._PixelHeight or SBFHeight
  local OrientWidth = Width
  local OrientHeight = Height

  -- Texcoords can't be greater than 1
  if FillDirection == 'HORIZONTAL' then
    -- Get pixel width
    Width = Texture._PixelLength or Width
    OrientWidth = Width * MaxValue
    Width = Width * Value

    if Clipping then
      if Rotation == 0 or Rotation == 180 then -- Horizontal or Upsidedown
        if ReverseFill then
          if Rotation == 0 then
            TexLeft = TexRight - (TexRight - TexLeft) * Value
          else
            TexRight = TexLeft + (TexRight - TexLeft) * Value
          end
        elseif Rotation == 0 then
          TexRight = TexLeft + (TexRight - TexLeft) * Value
        else
          TexLeft = TexRight - (TexRight - TexLeft) * Value
        end
      -- OTHER drawing rotations
      elseif ReverseFill then
        if Rotation == 90 then
          TexBottom = TexTop + (TexBottom - TexTop) * Value
        elseif Rotation == -90 then
          TexTop = TexBottom - (TexBottom - TexTop) * Value
        end
      elseif Rotation == 90 then
        TexTop = TexBottom - (TexBottom - TexTop) * Value
      elseif Rotation == -90 then
        TexBottom = TexTop + (TexBottom - TexTop) * Value
      end
    end

  -- VERTICAL fill direction
  else
    -- Get pixel height
    Height = Texture._PixelLength or Height
    OrientHeight = Height * MaxValue
    Height = Height * Value

    if Clipping then
      if Rotation == 0 or Rotation == 180 then -- Horizontal or Upsidedown
        if ReverseFill then
          if Rotation == 0 then
            TexBottom = TexTop + (TexBottom - TexTop) * Value
          else
            TexTop = TexBottom - (TexBottom - TexTop) * Value
          end
        elseif Rotation == 0 then
          TexTop = TexBottom - (TexBottom - TexTop) * Value
        else
          TexBottom = TexTop + (TexBottom - TexTop) * Value
        end
      -- OTHER drawing rotation
      elseif ReverseFill then
        if Rotation == 90 then
          TexRight = TexLeft + (TexRight - TexLeft) * Value
        elseif Rotation == -90 then
           TexLeft = TexRight - (TexRight - TexLeft) * Value
        end
      elseif Rotation == 90 then
        TexLeft = TexRight - (TexRight - TexLeft) * Value
      elseif Rotation == -90 then
        TexRight = TexLeft + (TexRight - TexLeft) * Value
      end
    end
  end

  -- Scale if set
  if FillDirection == 'HORIZONTAL' then
    local ScaleHorizontalX = Texture._ScaleHorizontalX
    local ScaleHorizontalY = Texture._ScaleHorizontalY

    Width = Width * ScaleHorizontalX
    Height = Height * ScaleHorizontalY
    OrientWidth = OrientWidth * ScaleHorizontalX
    OrientHeight = OrientHeight * ScaleHorizontalY
  else
    local ScaleVerticalX = Texture._ScaleVerticalX
    local ScaleVerticalY = Texture._ScaleVerticalY

    Width = Width * ScaleVerticalX
    Height = Height * ScaleVerticalY
    OrientWidth = OrientWidth * ScaleVerticalX
    OrientHeight = OrientHeight * ScaleVerticalY
  end

  -- Need to use a very small number since Size cant be set to zero
  Texture:SetSize(Width > 0 and Width or 0.00001, Height > 0 and Height or 0.00001)

  -- Orient texture needs to be set to thefull size of the texture above
  Texture._OrientTexture:SetSize(OrientWidth > 0 and OrientWidth or 0.00001, OrientHeight > 0 and OrientHeight or 0.00001)

  -- ULx ULy   LLx LLy    URx URy   LRx LRy
  if Rotation == 90 then
    -- Rotate texture 90 degrees clockwise
    Texture:oSetTexCoord(TexLeft, TexBottom,     TexRight, TexBottom,   TexLeft, TexTop,       TexRight, TexTop)
  elseif Rotation == 0 then
    -- No rotation: horizontal
    Texture:oSetTexCoord(TexLeft, TexTop,        TexLeft, TexBottom,    TexRight, TexTop,      TexRight, TexBottom)
  elseif Rotation == -90 then
    -- Rotate 90 degrees counter clockwise
    Texture:oSetTexCoord(TexRight, TexTop,       TexLeft, TexTop,       TexRight, TexBottom,   TexLeft, TexBottom)
  elseif Rotation == 180 then
    -- Rotate 180 degrees clockwise. This draws upsidedown
    Texture:oSetTexCoord(TexRight, TexBottom,    TexRight, TexTop,      TexLeft, TexBottom,    TexLeft, TexTop)
  end
  return Width, Height
end

-------------------------------------------------------------------------------
-- StatusBarSetValue (texture method)
--
-- Changes the value of the current status bar
--
--
-- Texture       if not specified all textures will get redrawn
--               otherwise just that texture gets drawn
-- Value         For non linked textures this will draw the bar
--
-- NOTES: For linked textures.  MaxRange limits the range of the linked texture.
--        MaxRange is used from the first texture in the link.
--        When in overlap mode.  Each bar in the link fills the whole statusbar frame
--        The range is 0 to MaxValue
-------------------------------------------------------------------------------
local function StatusBarSetValue(Texture, Value)
  local SBF = Texture._SBF
  local SBFWidth = SBF._Width
  local SBFHeight = SBF._Height
  local MaxRange = Texture._MaxRange

  -- Get values before possible texture jump
  local TagRightToLeft = Texture._TagRightToLeft
  local TagInherit = Texture._TagInherit
  local T = (TagInherit == nil or TagInherit) and Texture._TaggedToTexture or Texture

  local Rotation = T._Rotation
  local FillDirection
  local SyncFillDirection = T._SyncFillDirection
  local ReverseFill = T._ReverseFill
  local Clipping = T._Clipping or false

  if TagRightToLeft then
    ReverseFill = not ReverseFill
  end

  if SyncFillDirection then
    FillDirection = RotationFillDirection[Rotation]
  else
    FillDirection = T._FillDirection
  end

  if Value then
    Texture._Value = Value
  else
    Value = Texture._Value
  end

  -- Not a linked texture
  if Texture._Link == nil then

    -- Clip value if greater than texture max value
    local MaxValue = Texture._MaxValue

    if MaxValue > MaxRange then
      MaxValue = MaxRange
    end
    if Value > MaxValue then
      Value = MaxValue
    end
    MaxValue = MaxValue / MaxRange

    StatusBarDrawTexture(SBF, Texture, Value / MaxRange, MaxValue, SBFWidth, SBFHeight, Rotation, FillDirection, ReverseFill, Clipping)
  else
    -- Linked textures
    local Textures = Texture._Textures
    if Textures == nil then
      assert(false, 'SetValue - Must be the first texture in the link')
    end

    local LastTexture
    local HideRemaining = false
    local TotalMaxValue = 0
    local HideFull = Texture._HideFull or false
    local Overlap = Texture._Overlap or false
    local EdgeFrame = Texture._EdgeFrame
    local EdgeWidth = 0
    local EdgeHeight = 0

    -- Clip value to texture max range
    if Value > MaxRange then
      Value = MaxRange
    end
    if not Overlap then
      Value = Value / MaxRange
    end

    local Width, Height = 0, 0

    for Index = 1, #Textures do
      local Texture = Textures[Index]

      if HideRemaining then
        if not Texture._Hidden then
          Texture:Hide()
        end
      else
        local MaxValue = Texture._MaxValue or 1

        -- clip max value
        if not Overlap then
          if MaxValue > MaxRange then
            MaxValue = MaxRange
          end
          MaxValue = MaxValue / MaxRange
        end

        if Texture._Hidden then
          Texture:Show()
        end

        -- Hide the previous texture since it's full
        if Index > 1 and HideFull then
          LastTexture:Hide()
        end
        LastTexture = Texture

        -- Just draw the texture
        if TotalMaxValue + MaxValue >= Value then
          -- Overlap then scale texture
          -- this is the final iteration so it's safe to modify value
          if Overlap then
            Value = Value - TotalMaxValue
            Value = Value / MaxValue
            TotalMaxValue = 0
          end
          Width, Height = StatusBarDrawTexture(SBF, Texture, Value - TotalMaxValue, Overlap and 1 or MaxValue, SBFWidth, SBFHeight, Rotation, FillDirection, ReverseFill, Clipping)

          -- Hide remaining textures
          HideRemaining = true
        else
          -- Draw the texture in value of max value
          -- In overlap the whole texture needs to be drawn and fill the bar
          local NewMaxValue = Overlap and 1 or MaxValue
          Width, Height = StatusBarDrawTexture(SBF, Texture, NewMaxValue, NewMaxValue, SBFWidth, SBFHeight, Rotation, FillDirection, ReverseFill, Clipping)
          TotalMaxValue = TotalMaxValue + MaxValue
        end

        -- calc size of edgeframe in pixels
        if EdgeFrame then
          if Overlap then
            EdgeWidth = Width
            EdgeHeight = Height
          elseif FillDirection == 'HORIZONTAL' then
            EdgeWidth = EdgeWidth + Width
            EdgeHeight = Height
          else
            EdgeWidth = Width
            EdgeHeight = EdgeHeight + Height
          end
        end
      end
    end
    -- Set edgeframe size
    if EdgeFrame then
      EdgeFrame:SetSize(EdgeWidth > 0 and EdgeWidth or 0.00001, EdgeHeight > 0 and EdgeHeight or 0.00001)
    end
  end
end

-------------------------------------------------------------------------------
-- StatusBarDrawAllTextures
--
-- Draws all textures in the statusbar frame
-------------------------------------------------------------------------------
local function StatusBarDrawAllTextures(SBF)
  for Index = 1, #SBF do
    local Texture = SBF[Index]

    -- Setvalue if first texture in a link, or a normal texture
    if Texture._Textures or Texture._Link == nil then
      StatusBarSetValue(Texture)
    end
  end
end

-------------------------------------------------------------------------------
-- StatusBarOrientTextures
--
-- Repositions one or more textures based on fill direction or reverse fill
-------------------------------------------------------------------------------
local function StatusBarOrientTextures(SBF)
  for Index = 1, #SBF do
    local Texture = SBF[Index]
    local OrientTexture = Texture._OrientTexture
    local FillDirection
    local Link = Texture._Link
    local EdgeFrame = Texture._EdgeFrame

    -- Check for settings from first texture in a link, then normal texture
    local T = Link or Texture

    -- Get values before possible texture jump
    local TagRightToLeft = T._TagRightToLeft
    local Overlap = T._Overlap
    local TaggedToTexture = T._TaggedToTexture

    local TagInherit = T._TagInherit
    T = (TagInherit == nil or TagInherit) and TaggedToTexture or T

    local SyncFillDirection = T._SyncFillDirection
    local ReverseFill = T._ReverseFill

    if SyncFillDirection then
      FillDirection = RotationFillDirection[T._Rotation]
    else
      FillDirection = T._FillDirection
    end

    -- Setpoint the edgeframe to the content frame
    if EdgeFrame and Link then
      EdgeFrame:ClearAllPoints()

      -- Set points
      if FillDirection == 'HORIZONTAL' then
        if ReverseFill then
          EdgeFrame:SetPoint('RIGHT', Texture, 'RIGHT')
        else
          EdgeFrame:SetPoint('LEFT', Texture, 'LEFT')
        end
      -- Vertical
      elseif ReverseFill then
        EdgeFrame:SetPoint('TOP', Texture, 'TOP')
      else
        EdgeFrame:SetPoint('BOTTOM', Texture, 'BOTTOM')
      end
    end

    OrientTexture:ClearAllPoints()
    Texture:ClearAllPoints()

    -- Do first link texture or normal texture
    if Link == nil or Texture._Textures or Overlap then
      local Point = Texture._PixelPoint
      local OffsetX = Texture._PixelOffsetX or 0
      local OffsetY = Texture._PixelOffsetY or 0

      -- A texture or link texture that has an edgeframe can not be used
      -- to setpoint. Basically a texture/link can't attach its self to its own edgeframe
      if EdgeFrame == nil then
        if Link and Link._EdgeFrame == nil or Link == nil then
          EdgeFrame = TaggedToTexture and TaggedToTexture._EdgeFrame
        end
      else
        EdgeFrame = nil
      end

      if FillDirection == 'HORIZONTAL' then
        if ReverseFill then
          if EdgeFrame then
            if TagRightToLeft then
              OrientTexture:SetPoint(Point or 'LEFT', EdgeFrame, 'LEFT', OffsetX, OffsetY)
              Texture:SetPoint('LEFT', OrientTexture, 'LEFT')
            else
              OrientTexture:SetPoint(Point or 'RIGHT', EdgeFrame, 'LEFT', OffsetX, OffsetY)
              Texture:SetPoint('RIGHT', OrientTexture, 'RIGHT')
            end
          else
            OrientTexture:SetPoint(Point or 'RIGHT', OffsetX, OffsetY)
            Texture:SetPoint('RIGHT', OrientTexture, 'RIGHT')
          end
        -- not reversefill
        elseif EdgeFrame then
          if TagRightToLeft then
            OrientTexture:SetPoint(Point or 'RIGHT', EdgeFrame, 'RIGHT', OffsetX, OffsetY)
            Texture:SetPoint('RIGHT', OrientTexture, 'RIGHT')
          else
            OrientTexture:SetPoint(Point or 'LEFT', EdgeFrame, 'RIGHT', OffsetX, OffsetY)
            Texture:SetPoint('LEFT', OrientTexture, 'LEFT')
          end
        else
          OrientTexture:SetPoint(Point or 'LEFT', OffsetX, OffsetY)
          Texture:SetPoint('LEFT', OrientTexture, 'LEFT')
        end
      -- VERTICAL
      elseif ReverseFill then
        if EdgeFrame then
          if TagRightToLeft then
            OrientTexture:SetPoint(Point or 'BOTTOM', EdgeFrame, 'BOTTOM', OffsetX, OffsetY)
            Texture:SetPoint('BOTTOM', OrientTexture, 'BOTTOM')
          else
            OrientTexture:SetPoint(Point or 'TOP', EdgeFrame, 'BOTTOM', OffsetX, OffsetY)
            Texture:SetPoint('TOP', OrientTexture, 'TOP')
          end
        else
          OrientTexture:SetPoint(Point or 'TOP', OffsetX, OffsetY)
          Texture:SetPoint('TOP', OrientTexture, 'TOP')
        end
      -- not reversefill
      elseif EdgeFrame then
        if TagRightToLeft then
          OrientTexture:SetPoint(Point or 'TOP', EdgeFrame, 'TOP', OffsetX, OffsetY)
          Texture:SetPoint('TOP', OrientTexture, 'TOP')
        else
          OrientTexture:SetPoint(Point or 'BOTTOM', EdgeFrame, 'TOP', OffsetX, OffsetY)
          Texture:SetPoint('BOTTOM', OrientTexture, 'BOTTOM')
        end
      else
        OrientTexture:SetPoint(Point or 'BOTTOM', OffsetX, OffsetY)
        Texture:SetPoint('BOTTOM', OrientTexture, 'BOTTOM')
      end
    else
      -- Linked
      local OrientPrev = Texture._OrientPrev

      -------------------
      -- Do link textures
      -------------------
      if FillDirection == 'HORIZONTAL' then
        if ReverseFill then
          if TagRightToLeft then
            OrientTexture:SetPoint('LEFT', OrientPrev, 'RIGHT')
            Texture:SetPoint('LEFT', OrientTexture, 'LEFT')
          else
            OrientTexture:SetPoint('RIGHT', OrientPrev, 'LEFT')
            Texture:SetPoint('RIGHT', OrientTexture, 'RIGHT')
          end
        -- not reversefill
        elseif TagRightToLeft then
          OrientTexture:SetPoint('RIGHT', OrientPrev, 'LEFT')
          Texture:SetPoint('RIGHT', OrientTexture, 'RIGHT')
        else
          OrientTexture:SetPoint('LEFT', OrientPrev, 'RIGHT')
          Texture:SetPoint('LEFT', OrientTexture, 'LEFT')
        end
      -- VERTICAL fill direction
      elseif ReverseFill then
        if TagRightToLeft then
          OrientTexture:SetPoint('BOTTOM', OrientPrev, 'TOP')
          Texture:SetPoint('BOTTOM', OrientTexture, 'BOTTOM')
        else
          OrientTexture:SetPoint('TOP', OrientPrev, 'BOTTOM')
          Texture:SetPoint('TOP', OrientTexture, 'TOP')
        end
      -- not reversefill
      elseif TagRightToLeft then
        OrientTexture:SetPoint('TOP', OrientPrev, 'BOTTOM')
        Texture:SetPoint('TOP', OrientTexture, 'TOP')
      else
        OrientTexture:SetPoint('BOTTOM', OrientPrev, 'TOP')
        Texture:SetPoint('BOTTOM', OrientTexture, 'BOTTOM')
      end
    end
  end
  -- Draw all textures
  StatusBarDrawAllTextures(SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetPointPixel
--
-- Setpoint(Point, OffsetX, OffsetY)
--
-- NOTES: Only works on normal texture or first texture in a link
--        Set nil to clear on Point, OffsetX, OffsetY
-------------------------------------------------------------------------------
local function StatusBarSetPointPixel(Texture, Point, OffsetX, OffsetY)
  if Texture._Link and Texture._Textures == nil then
    assert(false, 'SetPointPixel - Texture must be first when centering a texture in a link')
  end
  Texture._PixelPoint = Point
  Texture._PixelOffsetX = OffsetX
  Texture._PixelOffsetY = OffsetY

  StatusBarOrientTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetPixelSize
--
-- Sets the width and height of the statusbar in pixels
-------------------------------------------------------------------------------
local function StatusBarSetPixelSize(Texture, PixelWidth, PixelHeight)
  Texture._PixelWidth = PixelWidth
  Texture._PixelHeight = PixelHeight

  StatusBarDrawAllTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusbarSetPixelWidth
--
-- Sets the width of the statusbar in pixels
--
-- PixelWidth   Width in pixels, use nil to clear
--
-- NOTES: Overrides Width
-------------------------------------------------------------------------------
local function StatusBarSetPixelWidth(Texture, PixelWidth)
  Texture._PixelWidth = PixelWidth

  StatusBarDrawAllTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusbarSetPixelHeight
--
-- Sets the height of the statusbar in pixels
--
-- PixelHeight   Height in pixels, use nil to clear
--
-- NOTES: Overrides Height
-------------------------------------------------------------------------------
local function StatusBarSetPixelHeight(Texture, PixelHeight)
  Texture._PixelHeight = PixelHeight

  StatusBarDrawAllTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusbarSetPixelLength
--
-- Sets the length of a statusbar in pixels
--
-- PixelLength  Length in pixels, use nil to clear
--
-- NOTES: Overrides width in horizontal mode or
--        overrides height in vertical mode
-------------------------------------------------------------------------------
local function StatusBarSetPixelLength(Texture, PixelLength)
  Texture._PixelLength = PixelLength

  StatusBarDrawAllTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetScaleHorizontal (texture method)
--
-- Sets the scale of a statusbar by x and y only when the bar is horizontal
--
-- Use 1 for scale to not do scaling
-------------------------------------------------------------------------------
local function StatusBarSetScaleHorizontal(Texture, ScaleX, ScaleY)
  if type(ScaleX) ~= 'number' or type(ScaleY) ~= 'number' then
    assert(false, 'SetScale - Must be a number')
  end

  Texture._ScaleHorizontalX = ScaleX
  Texture._ScaleHorizontalY = ScaleY

  StatusBarDrawAllTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetScaleVertical (texture method)
--
-- Sets the scale of a statusbar by x and y only when the bar is vertical
--
-- Use 1 for scale to not do scaling
-------------------------------------------------------------------------------
local function StatusBarSetScaleVertical(Texture, ScaleX, ScaleY)
  if type(ScaleX) ~= 'number' or type(ScaleY) ~= 'number' then
    assert(false, 'SetScale - Must be a number')
  end

  Texture._ScaleVerticalX = ScaleX
  Texture._ScaleVerticalY = ScaleY

  StatusBarDrawAllTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetTexCoord (texture method)
--
-- Sets the texture coordinates.  This can be used to use a whole texture
-- or part of one.
-------------------------------------------------------------------------------
local function StatusBarSetTexCoord(Texture, Left, Right, Top, Bottom)
  Texture._TexLeft = Left
  Texture._TexRight = Right
  Texture._TexTop = Top
  Texture._TexBottom = Bottom

  -- Draw texture
  StatusBarDrawAllTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarHide (texture method)
-------------------------------------------------------------------------------
local function StatusBarHide(Texture)
  Texture._Hidden = true
  Texture:oHide()
end

-------------------------------------------------------------------------------
-- StatusBarShow (texture method)
-------------------------------------------------------------------------------
local function StatusBarShow(Texture)
  Texture._Hidden = false
  Texture:oShow()
end

-------------------------------------------------------------------------------
-- StatusBarHideFull (texture method)
--
-- Linked textures
--
-- Hides the texture when its full (linked textures)
-------------------------------------------------------------------------------
local function StatusBarHideFull(Texture, HideFull)
  if type(HideFull) ~= 'boolean' then
    assert(false, 'HideFull - Must be true or false')
  elseif Texture._Link == nil then
    assert(false, 'HideFull - Texture is not linked')
  elseif Texture._Textures == nil then
    assert(false, 'HideFull - Texture must be the first in the link')
  end
  Texture._HideFull = HideFull

  StatusBarSetValue(Texture)
end

-------------------------------------------------------------------------------
-- StatusBarSetOverlap (texture method)
--
-- Linked textures
--
-- Hides the texture when its full (linked textures only)
-------------------------------------------------------------------------------
local function StatusBarSetOverlap(Texture, Overlap)
  if type(Overlap) ~= 'boolean' then
    assert(false, 'SetOverlap - Must be true or false')
  elseif Texture._Link == nil then
    assert(false, 'SetOverlap - Texture is not linked')
  elseif Texture._Textures == nil then
    assert(false, 'SetOverlap - Texture must be the first in the link')
  end
  Texture._Overlap = Overlap

  StatusBarOrientTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetRotation (texture method)
--
-- Rotates the texture vertical or horizontal
-- true for vertical
-------------------------------------------------------------------------------
local function StatusBarSetRotation(Texture, Rotation)
  if Rotation ~= 0 and Rotation ~= 180 and abs(Rotation) ~= 90 then
    assert(false, 'SetRotation - Must be -90, 0, 90 or 180')
  end
  Texture._Rotation = Rotation

  StatusBarOrientTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSyncFillDirection (texture method)
--
-- Makes it so the fill direction will change based on the rotation
-------------------------------------------------------------------------------
local function StatusBarSyncFillDirection(Texture, Action)
  if type(Action) ~= 'boolean' then
    assert(false, 'SyncFillDirection - Must be true or false')
  end
  Texture._SyncFillDirection = Action

  StatusBarOrientTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetFillDirection (texture method)
--
-- Sets fill direction for horizontal or vertical
--
-- Direction    'HORIZONTAL'   Fill from left to right.
--              'VERTICAL'     Fill from bottom to top.
-------------------------------------------------------------------------------
local function StatusBarSetFillDirection(Texture, Direction)
  if Direction ~= 'HORIZONTAL' and Direction ~= 'VERTICAL' then
    assert(false, 'SetFillDirection - Must be HORIZONTAL or VERTICAL')
  end
  Texture._FillDirection = Direction

  StatusBarOrientTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetFillReverse (texture method)
--
-- Changes the fill direction to reverse
--
-- Action    true         The fill will be reversed.  Right to left or top to bottom.
--           false        Default fill.  Left to right or bottom to top.
-------------------------------------------------------------------------------
local function StatusBarSetFillReverse(Texture, Action)
  if type(Action) ~= 'boolean' then
    assert(false, 'SetReverseFill - Must be true or false')
  end
  Texture._ReverseFill = Action

  StatusBarOrientTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetClipping (texture method)
--
-- Texture is clipped instead of being stretched
-------------------------------------------------------------------------------
local function StatusBarSetClipping(Texture, Action)
  if type(Action) ~= 'boolean' then
    assert(false, 'SetClipping - Must be true or false')
  end
  Texture._Clipping = Action

  StatusBarDrawAllTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarLink (texture method)
--
-- Links two or more textures into a linked texture
--
-- FirstTexture  Starting texture in the link
-- ...           One or more textures to form a link
-------------------------------------------------------------------------------
local function StatusBarLink(FirstTexture, ...)

  -- do nothing if already linked
  if FirstTexture and FirstTexture._Textures then
    return
  end

  local FnName = 'Link'
  local SBF = FirstTexture._SBF

  local Textures = {FirstTexture, ...}
  local NumTextures = #Textures

  if NumTextures < 2 then
    assert(false, FnName .. ' - Need at least two textures to link')
  end

  -- Validate first
  for Index = 1, NumTextures do
    local Texture = Textures[Index]

    if SBF[Texture] == nil then
      assert(false, FnName .. ' - Texture #' .. (Index - 1) .. " doesn't exist")
    elseif Texture._Link then
      assert(false, FnName .. ' - Texture #' .. (Index - 1) .. ' already linked')
    elseif Textures[Texture] then
      assert(false, FnName .. ' - Two textures found matching each other')
    elseif Texture._EdgeFrame then
      assert(false, FnName .. ' - Texture #' .. (Index - 1) .. ' currently has textures tagged to it')
    elseif Texture._TaggedTexture then
      assert(false, FnName .. ' - Texture #' .. (Index - 1) .. ' currently tagged to another texture')
    end
    Textures[Texture] = 1
  end

  FirstTexture._Link = FirstTexture
  FirstTexture._Textures = Textures
  FirstTexture._HideFull = false
  FirstTexture._Overlap = false

  for Index = 2, NumTextures do
    local Texture = Textures[Index]

    Texture._Link = FirstTexture
    Texture._OrientPrev = Textures[Index - 1]._OrientTexture
  end

  StatusBarOrientTextures(SBF)
end

-------------------------------------------------------------------------------
-- StatusBarUnLink (texture method)
--
-- Remove links from textures, returning them back to normal textures
--
-- Texture    Must be the start of the link
-------------------------------------------------------------------------------
local function StatusBarUnLink(Texture)

  -- do nothing if already unlinked
  if Texture and Texture._Textures == nil then
    return
  end

  local FnName = 'UnLink'
  local SBF = Texture._SBF
  local Textures

  if SBF[Texture] == nil then
    assert(false, FnName .. " - Texture doesn't exist")
  elseif Texture._Link == nil then
    assert(false, FnName .. ' - Texture must be linked')
  else
    Textures = Texture._Textures
    if Textures == nil then
      assert(false, FnName .. ' - Texture must be the first in the link')
    end
  end

  -- Unlink this texture link
  for Index = 1, #Textures do
    local T = Textures[Index]

    T._Link = nil
    T._Prev = nil

    T._HideFull = nil
    T._Overlap = nil
  end
  Texture._Textures = nil

  StatusBarOrientTextures(SBF)
end

-------------------------------------------------------------------------------
-- StatusBarTag (texture method)
--
-- Tags one texture or linked texture to another texture or linked texture
-- Can't tag a texture already tagged
--
-- Texture           Texture or linked texture that is being tagged to TargetTexture
-- Action
--   left-right      Tagged textures will grow from left to right starting from the target links edge
--   right-left      Tagged textures will grow from right to left starting from the target links edge
-- TargetTexture     Texture or linked texture
-------------------------------------------------------------------------------
local function StatusBarTag(Texture, Action, TargetTexture)

  -- do nothing if already tagged
  if Texture and Texture._TaggedToTexture then
    return
  end

  local FnName = 'Tag'
  local SBF = Texture._SBF

  if SBF[Texture] == nil then
    assert(false, FnName .. " - Texture doesn't exist")
  elseif SBF[TargetTexture] == nil then
    assert(false, FnName .. " - Target Texture doesn't exist")
  -- Don't check target texture for a tag, since more than one texture can be tagged to the other texture
  elseif Texture._EdgeFrame then
    assert(false, FnName .. " - Texture already has one or more textures tagged to it")
  elseif TargetTexture._TaggedToTexture then
    assert(false, FnName .. " - Target Texture already tagged to another texture")
  elseif TargetTexture == Texture then
    assert(false, FnName .. " - Target texture and texture can't be the same")
  elseif Texture._Link and Texture._Textures == nil then
    assert(false, FnName .. ' - Texture must be first when tagging a linked texture')
  elseif TargetTexture._Link and TargetTexture._Textures == nil then
    assert(false, FnName .. ' - Target texture must be first when tagging to a link')
  end

  if Action == 'right-left' then
    Action = '_TagRightToLeft'
  elseif Action == 'left-right' then
    Action = nil
  else
    assert(false, FnName .. ' - Action must be left-right or right-left')
  end

  -- Create edge frame if it doesn't exist
  local EdgeFrames = SBF._EdgeFrames
  local EdgeFrame = EdgeFrames[TargetTexture]
  if EdgeFrame == nil then
    EdgeFrame = CreateFrame('Frame', nil, SBF)
    EdgeFrames[TargetTexture] = EdgeFrame
  end
  TargetTexture._EdgeFrame = EdgeFrame

  -- Set all points if not a link texture
  if EdgeFrame and TargetTexture._Link == nil then
    EdgeFrame:SetAllPoints(TargetTexture)
  end

  local Tagged = TargetTexture._Tagged
  if Tagged == nil then
    Tagged = {}
    TargetTexture._Tagged = Tagged
  end
  Tagged[Texture] = 1

  Texture._TaggedToTexture = TargetTexture

  if Action then
    Texture[Action] = 1
  end

  StatusBarOrientTextures(SBF)
end

-------------------------------------------------------------------------------
-- StatusBarUnTag (texture method)
--
-- Removes a tag from a texture or linked textures
--
-- Texture     The texture that will be untagged
-------------------------------------------------------------------------------
local function StatusBarUnTag(Texture)

  -- do nothing if already untagged
  if Texture and Texture._TaggedToTexture == nil then
    return
  end

  local FnName = 'UnTag'
  local SBF = Texture._SBF

  if SBF[Texture] == nil then
    assert(false, FnName .. " - Texture doesn't exist")
  end

  -- Remove texture from tagged list
  local TaggedToTexture = Texture._TaggedToTexture
  local Tagged = TaggedToTexture._Tagged
  Tagged[Texture] = nil

  -- Remove tagged if empty
  if next(Tagged) == nil then
    TaggedToTexture._Tagged = nil
    TaggedToTexture._EdgeFrame:ClearAllPoints()
    TaggedToTexture._EdgeFrame = nil
  end
  Texture._TagRightToLeft = nil
  Texture._TaggedToTexture = nil
  Texture._TagInherit = nil

  StatusBarOrientTextures(SBF)
end

-------------------------------------------------------------------------------
-- StatusBarTagInherit
--
-- A texture will not inherit the stats from the texture it's tagged to
--
-- Inherit    false then don't inherit, otherwise true
-------------------------------------------------------------------------------
local function StatusBarTagInherit(Texture, Inherit)
  local FnName = 'TagInherit'

  if Texture._TaggedToTexture == nil then
    assert(false, FnName .. ' - Texture must be tagged to another texture')
  elseif type(Inherit) ~= 'boolean' then
    assert(false, FnName .. ' - Inherit: must be true or false')
  end

  Texture._TagInherit = Inherit

  StatusBarOrientTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetMaxRange (texture method)
--
-- Sets the maximum value it takes to to draw all of the bar
-------------------------------------------------------------------------------
local function StatusBarSetMaxRange(Texture, MaxRange)
  Texture._MaxRange = MaxRange

  StatusBarDrawAllTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetMaxValue (texture method)
--
-- Limits the texture to maxvalue. Good for making some textures shorter than
-- the width of the texture frame.
--
-- NOTES: MaxValue is stored based on value and not pixels. Can be greater than 1
--        MaxValue will always get clipped to the maxvalue of the statusbar frame
-------------------------------------------------------------------------------
local function StatusBarSetMaxValue(Texture, MaxValue)
  Texture._MaxValue = MaxValue

  -- Draw all textures
  StatusBarDrawAllTextures(Texture._SBF)
end

-------------------------------------------------------------------------------
-- StatusBarSetMethod
--
-- If the table already has a function of the same name.  It will create
-- a link to that function with an 'o' before it. o for Original function
--
-- Example:  Table.SetTexture would become Table.oSetTexture
-------------------------------------------------------------------------------
local function StatusBarSetMethod(Table, Key, Fn)
  -- Check if Key name already exists as a function
  if Table[Key] ~= nil then
    Table['o' .. Key] = Table[Key]
  end
  Table[Key] = Fn
end

-------------------------------------------------------------------------------
-- StatusBarCreateTexture (SBF method)
--
-- Creates a texture and returns it
--
-- Sublayer          To make things simple this takes a value from 1 onward.
--                   2 is drawn above 1, etc
--
-- Methods:
--   SetPointPixel(Point, Point, OffsetX, OffsetY)
--   SetPixelSize(Width, Height)
--   SetPixelWidth(Width)
--   SetPixelHeight(Height)
--   SetPixelWidth(Width)
--
--   SetValue(Value)
--   SetMaxRange(MaxRange)
--   SetMaxValue(MaxValue)
--   SetScaleHorizontal(ScaleX, ScaleY)
--   SetScaleVertical(ScaleX, ScaleY)
--   SetTexCoord(Texture, Left, Right, Top, Bottom)
--   Hide()
--   Show()
--
--   HideFull(true or false)
--   SetOverlap(true or false)
--
--   SetFillDirection(VERTICAL or HORIZONTAL)
--   SyncFillDirection(true or false)
--   SetRotation(-90, 0, 90, or 180)
--   SetReverseFill(true or false)
--   SetClipping(true or false)
--
--   Texture:Link(...)
--   Texture:UnLink()
--   Texture:Tag(Action, TargetTexture)
--   Texture:UnTag()
--   Texture:TagInherit(true or false)
--
-- NOTES: Since noclip is in a different frame. It can use it's own sublayers
--        and will not conflict with textures in the content frame
-------------------------------------------------------------------------------
local function StatusBarCreateTexture(SBF, Sublayer, Action)
  if Action ~= nil and Action ~= 'noclip' then
    assert(false, 'CreateTexture - Invalid action: must be noclip or nil')
  end

  Sublayer = ConvertSublayer[Sublayer]
  if Sublayer == nil then
    assert(false, format('CreateTexture - Invalid Sublayer: 1 to %s', #ConvertSublayer))
  end

  local Texture
  local OrientTexture
  if Action == 'noclip' then
    Texture = SBF._NoClipFrame:CreateTexture(nil, 'ARTWORK', nil, Sublayer)
    OrientTexture = SBF._NoClipFrame:CreateTexture(nil, 'ARTWORK', nil, Sublayer)
    Texture._NOCLIP = 1
  else
    Texture = SBF._ContentFrame:CreateTexture(nil, 'ARTWORK', nil, Sublayer)
    OrientTexture = SBF._ContentFrame:CreateTexture(nil, 'ARTWORK', nil, Sublayer)
  end

  Texture._OrientTexture = OrientTexture

  Texture._Value = 0
  Texture._MaxRange = 1
  Texture._MaxValue = 1
  Texture._ScaleHorizontalX = 1
  Texture._ScaleHorizontalY = 1
  Texture._ScaleVerticalX = 1
  Texture._ScaleVerticalY = 1

  Texture._Hidden = false

  Texture._Rotation = 0
  Texture._FillDirection = 'HORIZONTAL'
  Texture._SyncFillDirection = false
  Texture._ReverseFill = false
  Texture._Clipping = true

  Texture._TexLeft = 0
  Texture._TexRight = 1
  Texture._TexTop = 0
  Texture._TexBottom = 1

  Texture._SBF = SBF
  SBF[Texture] = true
  SBF[#SBF + 1] = Texture

  -- Set methods
  StatusBarSetMethod(Texture, 'SetPointPixel',       StatusBarSetPointPixel)
  StatusBarSetMethod(Texture, 'SetPixelSize',        StatusBarSetPixelSize)
  StatusBarSetMethod(Texture, 'SetPixelWidth',       StatusBarSetPixelWidth)
  StatusBarSetMethod(Texture, 'SetPixelHeight',      StatusBarSetPixelHeight)
  StatusBarSetMethod(Texture, 'SetPixelLength',      StatusBarSetPixelLength)

  StatusBarSetMethod(Texture, 'SetValue',            StatusBarSetValue)
  StatusBarSetMethod(Texture, 'SetScaleHorizontal',  StatusBarSetScaleHorizontal)
  StatusBarSetMethod(Texture, 'SetScaleVertical',    StatusBarSetScaleVertical)
  StatusBarSetMethod(Texture, 'SetMaxRange',         StatusBarSetMaxRange)
  StatusBarSetMethod(Texture, 'SetMaxValue',         StatusBarSetMaxValue)
  StatusBarSetMethod(Texture, 'SetTexCoord',         StatusBarSetTexCoord)
  StatusBarSetMethod(Texture, 'Hide',                StatusBarHide)
  StatusBarSetMethod(Texture, 'Show',                StatusBarShow)

  StatusBarSetMethod(Texture, 'HideFull',            StatusBarHideFull)
  StatusBarSetMethod(Texture, 'SetOverlap',          StatusBarSetOverlap)

  StatusBarSetMethod(Texture, 'SetRotation',         StatusBarSetRotation)
  StatusBarSetMethod(Texture, 'SyncFillDirection',   StatusBarSyncFillDirection)
  StatusBarSetMethod(Texture, 'SetFillDirection',    StatusBarSetFillDirection)
  StatusBarSetMethod(Texture, 'SetFillReverse',      StatusBarSetFillReverse)
  StatusBarSetMethod(Texture, 'SetClipping',         StatusBarSetClipping)

  StatusBarSetMethod(Texture, 'Link',                StatusBarLink)
  StatusBarSetMethod(Texture, 'UnLink',              StatusBarUnLink)
  StatusBarSetMethod(Texture, 'TagInherit',          StatusBarTagInherit)
  StatusBarSetMethod(Texture, 'Tag',                 StatusBarTag)
  StatusBarSetMethod(Texture, 'UnTag',               StatusBarUnTag)

  StatusBarOrientTextures(Texture._SBF)

  return Texture
end

-------------------------------------------------------------------------------
-- StatusBarOnSizeChanged (called by event)
--
-- Keeps track of the width and height, and redraws the bar when ever
-- there is a change in size
-------------------------------------------------------------------------------
local function StatusBarOnSizeChanged(SBF, Width, Height)
  SBF._Width = Width
  SBF._Height = Height

  -- Content Frame must be the same size ass the statusbar frame
  SBF._ContentFrame:SetSize(Width, Height)

  -- do nothing if no textures been created
  if #SBF > 0 then
    StatusBarOrientTextures(SBF)
  end
end

-------------------------------------------------------------------------------
-- CreateStatusBarFrame
--
-- Creates a status bar that can contain one or more textures
--
-- Methods:
--   CreateTexture(Sublayer)  -- Returns texture created
--
-- NOTES: Using a contentframe and scroll frame. Makes the texture clipping
--        less jittery. It's very faint, but you can see it. Maybe this doesn't
--        happen in 10.0. Also just need the clipping so textures don't go beyond
--        the bounds
-------------------------------------------------------------------------------
local function CreateStatusBarFrame(ParentFrame)
  local SBF = CreateFrame('Frame', nil, ParentFrame)

  local NoClipFrame = CreateFrame('Frame', nil, SBF)
  NoClipFrame:SetAllPoints()

  -- Make sure the noclip frame is above the content frame
  NoClipFrame:SetFrameLevel(SBF:GetFrameLevel() + 3)
  SBF._NoClipFrame = NoClipFrame

  -- Use Scrollframe and content frame to handle clipping
  local ScrollFrame = CreateFrame('ScrollFrame', nil, SBF)
  local ContentFrame = CreateFrame('Frame', nil, ScrollFrame)
  ScrollFrame:SetAllPoints()
  ScrollFrame:SetScrollChild(ContentFrame)

  SBF._ScrollFrame = ScrollFrame
  SBF._ContentFrame = ContentFrame

  SBF._Width = 1
  SBF._Height = 1

  SBF._EdgeFrames = {}

  SBF:SetScript('OnSizeChanged', StatusBarOnSizeChanged)

  -- Set methods
  StatusBarSetMethod(SBF, 'CreateTexture', StatusBarCreateTexture)

  return SBF
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Animation and timing functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetValueTimer
--
-- Timer function for SetValueTime
-------------------------------------------------------------------------------
local function SetValueTimer(ValueTime)
  local TimeElapsed = GetTime() - ValueTime.StartTime
  local Time

  -- Wait until the start time is reached
  if TimeElapsed < ValueTime.Duration then
    if ValueTime.Direction == -1 then
      Time = ValueTime.Duration - TimeElapsed
    else
      Time = TimeElapsed
    end

    -- Truncate to 1 decimal place
    -- This way only calling Fn 10 times per second
    Time = Time - Time % 0.1
    if Time ~= ValueTime.LastTime then
      ValueTime.LastTime = Time
      ValueTime.Fn(ValueTime.UnitBarF, ValueTime.BarDB, ValueTime.BoxNumber, Time, false)
    end
  else
    -- stop timer
    Main:SetTimer(ValueTime, nil)
    ValueTime.Fn(ValueTime.UnitBarF, ValueTime.BarDB, ValueTime.BoxNumber, 0, true)
  end
end

-------------------------------------------------------------------------------
-- SetValueTime
--
-- Sets a timer that returns a value within the timing range.  The call back function
-- then uses this value.
--
-- Usage: SetValueTime(BoxNumber, StartTime, Duration, Direction, Fn)
--        SetValueTime(BoxNumber, Fn) -- This turns off the timer
--
-- BoxNumber            The timer will use this box number.
-- StartTime            Starting time if nil then the current time will be used.
-- Duration             Duration in seconds.  Duration of 0 or less will stop the current timer.
-- Direction            Direction to go in +1 or -1
--                      if Direction is -1 then the timer will start counting down from StartTime
--                      otherwise starts counting from 0 to StartTime
-- Fn                   Call back function
--
-- Parms passed back to Fn:
--   UnitBarF      Bar that the timer was started in.
--   self(BarDB)   Bar object the bar was created in.
--   BN            Current box number.
--   Time          Current time progress.
--   Done          If true then the timer has finished.  Any values at this point are not valid.
--                 This can also be true if SetValueTime was called to stop the current timer.
-------------------------------------------------------------------------------
function BarDB:SetValueTime(BoxNumber, StartTime, Duration, Direction, Fn)
  repeat
    local Frame, BN = NextBox(self, BoxNumber)

    local ValueTime = Frame.ValueTime
    if ValueTime == nil then
      ValueTime = {}
      Frame.ValueTime = ValueTime
    end

    Main:SetTimer(ValueTime, nil)
    Duration = Duration or 0

    if Duration > 0 then
      local CurrentTime = GetTime()
      local WaitTime = 0

      StartTime = StartTime and StartTime or CurrentTime

      if StartTime > CurrentTime then
        WaitTime = StartTime - CurrentTime
      end

      -- Set up the paramaters.
      ValueTime.StartTime = StartTime
      ValueTime.Duration = Duration
      ValueTime.Direction = Direction
      ValueTime.LastTime = false

      ValueTime.UnitBarF = self.UnitBarF
      ValueTime.BarDB = self
      ValueTime.BoxNumber = BN
      ValueTime.Fn = Fn

      Main:SetTimer(ValueTime, SetValueTimer, 0.01, WaitTime)
    else
      -- Check if Fn is nil. If so then StartTime is the callback
      StartTime = Fn or StartTime
      StartTime(self.UnitBarF, self, BN, 0, true)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- GetAnimation
--
-- Get an animation of type for an object
--
-- Usage: AGroup = GetAnimation(BarDB, Object, GroupType, Type)
--
-- Object      Frame or Texture
-- GroupType   'parent' or 'children'
-- Type        'alpha', 'scale', 'move', or 'fontsize'
--
-- NOTES: AGroup.StopPlayingFn gets passed AGroup
-------------------------------------------------------------------------------
local function GetAnimation(BarDB, Object, GroupType, Type)
  local AGroups = BarDB.AGroups
  if AGroups == nil then
    AGroups = {}
    BarDB.AGroups = AGroups
  end

  local AType = tostring(Object) .. Type
  local AGroup = AGroups[AType]

  local InUse = AGroups.InUse
  if InUse == nil then
    InUse = {}
    AGroups.InUse = InUse
  end

  -- Create if not found.
  if AGroup == nil then
    local OnObject

    if GroupType == 'parent' or Type == 'move' or Type == 'offset' or Type == 'fontsize' or Type == 'texturescale' then
      AGroup = CreateFrame('Frame'):CreateAnimationGroup()
      if Object.IsAnchor then
        OnObject = Object.AnimationFrame
      else
        OnObject = Object
      end
    else
      AGroup = Object:CreateAnimationGroup()
    end

    local Animation = AGroup:CreateAnimation(AnimationType[Type])
    Animation:SetOrder(1)

    AGroup.Animation = Animation

    AGroup.DurationIn = 0
    AGroup.DurationOut = 0
    AGroup.GroupType = GroupType
    AGroup.Type = Type
    AGroup.StopPlayingFn = nil

    AGroup.Object = Object
    AGroup.OnObject = OnObject
    AGroup.InUse = InUse

    AGroups[AType] = AGroup
  end

  -- Call stop playing function if changing types
  local AGroupInUse = InUse[Object]

  if AGroupInUse and AGroupInUse ~= AGroup then

    -- Copy other animation group settings
    AGroup.DurationIn = AGroupInUse.DurationIn
    AGroup.DurationOut = AGroupInUse.DurationOut
    AGroup.StopPlayingFn = AGroupInUse.StopPlayingFn

    if AGroupInUse:IsPlaying() then
      local Fn = AGroupInUse.StopPlayingFn

      if Fn then
        Fn(AGroupInUse)
      end
    end
  end
  InUse[Object] = AGroup

  return AGroup
end

-------------------------------------------------------------------------------
-- StopPlaying
--
-- Calls StopPlayingFn on all Animation groups
--
-- AGroup      Animation group from GetAnimation()
-- GroupType  'parent' or 'children' or 'all'
--
-- NOTES: If GroupType is 'all' then all animation is stopped
-------------------------------------------------------------------------------
local function StopPlaying(AGroup, GroupType)
  for _, AG in pairs(AGroup.InUse) do
    if (GroupType == 'all' or AG.GroupType == GroupType) and AG:IsPlaying() then
      local Fn = AG.StopPlayingFn

      if Fn then
        Fn(AG)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- AnyPlaying
--
-- Returns true if any animation is playing that matches GroupType
--
-- Animation   Animation from GetAnimation()
-- GroupType  'parent' or 'children'
-------------------------------------------------------------------------------
local function AnyPlaying(AGroup, GroupType)
  for _, AG in pairs(AGroup.InUse) do
    if AG.GroupType == GroupType and AG:IsPlaying() then
      return true
    end
  end
  return false
end

-------------------------------------------------------------------------------
-- StopAnimation (called direct or by OnFinish)
--
-- Stops an animation and restores the object.
--
-- AGroup             Animation group
-- ReverseAnimation   If true just stops playing.
--
-- NOTES: Only alpha and scale support the call back AGroup.Fn
--        This function returns the current x, y of a Move animation.
-------------------------------------------------------------------------------
local function StopAnimation(AGroup, ReverseAnimation)
  local Type = AGroup.Type
  local Progress = AGroup:IsPlaying() and AGroup:GetProgress() or 1

  ReverseAnimation = ReverseAnimation or false
  AGroup:SetScript('OnFinished', nil)

  AGroup:Stop()

  if not ReverseAnimation then
    local Object = AGroup.Object
    local Direction = AGroup.Direction
    local Fn = AGroup.Fn
    local OnObject = AGroup.OnObject
    local IsVisible = Object:IsVisible()

    if OnObject then
      OnObject:SetAlpha(1)
      AGroup:SetScript('OnUpdate', nil)
    end

    -- Alpha or Scale.
    if Direction then
      if Direction == 'in' then
        Object:Show()
      elseif Direction == 'out' then
        Object:Hide()
      end
      if Type == 'alpha' then
        Object:SetAlpha(1)

      elseif Type == 'scale' then
        Object:SetScale(1)
        if OnObject then

          -- Restore anchor
          if Object.IsAnchor then
            -- AnimationFrame needs no restoring. Leave here for reference
          end
          OnObject:SetScale(1)
        end
      end
      if Fn and IsVisible then
        Fn(Direction)
      end

      AGroup.Direction = ''
    elseif Type == 'move' then
      local x = AGroup.FromValueX + AGroup.OffsetX * Progress
      local y = AGroup.FromValueY + AGroup.OffsetY * Progress

      Object:ClearAllPoints()
      Object:SetPoint(AGroup.Point, AGroup.RRegion, AGroup.RPoint, AGroup.ToValueX, AGroup.ToValueY)

      return x, y
    elseif Type == 'fontsize' then
      local Value = AGroup.FromValue
      local ToValue = AGroup.ToValue
      local FontType, _, FontStyle = OnObject:GetFont()

      OnObject:SetFont(FontType, ToValue, FontStyle)

      return Value + (ToValue - Value) * Progress

    elseif Type == 'texturescale' then
      local Value = AGroup.FromValue
      local ToValue = AGroup.ToValue

      OnObject:SetScale(ToValue)

      return Value + (ToValue - Value) * Progress

    elseif Type == 'offset' then
      local Left = AGroup.FromValueLeft + AGroup.DistanceLeft * Progress
      local Right = AGroup.FromValueRight + AGroup.DistanceRight * Progress
      local Top = AGroup.FromValueTop + AGroup.DistanceTop * Progress
      local Bottom = AGroup.FromValueBottom + AGroup.DistanceBottom * Progress

      SetOffsetFrame(OnObject, AGroup.ToValueLeft, AGroup.ToValueRight, AGroup.ToValueTop, AGroup.ToValueBottom)

      return Left, Right, Top, Bottom
    end
  end
end

-------------------------------------------------------------------------------
-- OnObject (OnUpdate functions)
--
-- Functions for alpha, scale, fontsize
--
-- NOTES: Blizzards animation group for alpha alters the alpha of all child
--        frames.  This causes conflicts with other alpha settings in the bar.
--        So by doing SetAlpha() here.  These conflicts are avoided.
--
--        Blizzard built in animation scaling doesn't work well with child frames.
--        So this has to be done instead.
--
--        I haven't rechecked these for WoW 8.x or after.  Basically don't try to
--        fix what's not broken.
-------------------------------------------------------------------------------
local function OnObjectAlpha(AGroup)
  local Value = AGroup.FromValue
  local Alpha = Value + (AGroup.ToValue - Value) * AGroup:GetProgress()

  AGroup.OnObject:SetAlpha(Alpha < 0 and 0 or Alpha > 1 and 1 or Alpha)
end

local function OnObjectScale(AGroup)
  local Value = AGroup.FromValue
  local Scale = Value + (AGroup.ToValue - Value) * AGroup:GetProgress()

  -- getting a huge number somehow, no idea why.
  if Scale ~= mhuge and Scale > 0 then
    AGroup.OnObject:SetScale(Scale)
  end
end

local function OnObjectFontSize(AGroup)
  local OnObject = AGroup.OnObject
  local Value = AGroup.FromValue
  local FontSize = Value + (AGroup.ToValue - Value) * AGroup:GetProgress()

  local FontType, _, FontStyle = OnObject:GetFont()

  OnObject:SetFont(FontType, FontSize, FontStyle)
end

local function OnObjectMove(AGroup)
  local OnObject = AGroup.OnObject
  local Progress = AGroup:GetProgress()
  local x = AGroup.FromValueX + AGroup.OffsetX * Progress
  local y = AGroup.FromValueY + AGroup.OffsetY * Progress

  OnObject:ClearAllPoints()
  OnObject:SetPoint(AGroup.Point, AGroup.RRegion, AGroup.RPoint, x, y)
end

local function OnObjectOffset(AGroup)
  local Progress = AGroup:GetProgress()
  local Left = AGroup.FromValueLeft + AGroup.DistanceLeft * Progress
  local Right = AGroup.FromValueRight + AGroup.DistanceRight * Progress
  local Top = AGroup.FromValueTop + AGroup.DistanceTop * Progress
  local Bottom = AGroup.FromValueBottom + AGroup.DistanceBottom * Progress

  SetOffsetFrame(AGroup.OnObject, Left, Right, Top, Bottom)
end

-------------------------------------------------------------------------------
-- PlayAnimation
--
-- Plays the animation for showing or hiding.
--
-- Usage:  PlayAnimation(AGroup, 'in' or 'out')
--            Fades or Scales amimation in or out.
--            Used with animation types: alpha or scale
--         PlayAnimation(AGroup, Duration, Point, RRegion, RPoint, FromX, FromY, ToX, ToY)
--            Moves an object from FromX, FromY to ToX, ToY
--            Used with animation type: move
--            StopAnimation() will return the current x, y of the animation.
--         PlayAnimation(AGroup, Duration, FromSize, ToSize)
--            Animates the size of the object which is a font
--            StopAnimation() will return the current size of the animation.
--         PlayAnimation(AGroup, Duration, FromScale, ToScale)
--            Same as scale excepts uses SetScale to change scale thru OnUpdate.
--            StopAnimation() will return the current scale of the animation.
--         PlayAnimation(AGroup, Duration, FromLeft, FromRight, FromTop, FromBottom,
--                                         ToLeft, ToRight, ToTop, ToBottom)
--            Offsets the 4 sides of the frame as animation.
--            StopAnimation() will return the current 4 offsets of the animation.
--
-- AGroup                      Animation group to be played
-- 'in'                        Animation gets played after object is shown.
-- 'out'                       Animation gets played then object is hidden.
-- Duration                    Amount of time in seconds to play animation
-- RRegion                     Relative region
-- RPoint                      Relative point
-- x, y                        This is where object will be SetPointed to after animation.
-- OffsetX, OffsetY            Amount of offset to be animated.
-- FromSize, ToSize            Source and destination for font size.
-- FromScale, ToScale          Source and destination for texture scale.
-- FromLeft, ToLeft            Starting and ending position for the left side of the frame.
-- FromRight, ToRight          Starting and ending position for the right side of the frame.
-- FromTop, ToTop              Starting and ending position for the top side of the frame.
-- FromBottom, ToBottom        Starting and ending position for the bottom side of the frame.
-------------------------------------------------------------------------------
local function PlayAnimation(AGroup, ...)
  local Animation = AGroup.Animation

  AGroup.StopPlayingFn = StopAnimation

  local Object = AGroup.Object
  local Type = AGroup.Type
  local OnObject = AGroup.OnObject
  local Direction
  local OffsetX
  local OffsetY
  local Duration = 0
  local FromValue = 0
  local ToValue = 0

  if Type == 'alpha' or Type == 'scale' then
    Direction = ...

    Object:Show()
    if Direction == 'in' then
      ToValue = 1
      Duration = AGroup.DurationIn
    elseif Direction == 'out' then
      FromValue = 1
      ToValue = 0
      Duration = AGroup.DurationOut
    end
  else
    Duration = ...
    if Type == 'move' then
      local Point, RRegion, RPoint, FromX, FromY, ToX, ToY = select(2, ...)

      OffsetX = ToX - FromX
      OffsetY = ToY - FromY

      AGroup.Point = Point
      AGroup.RRegion = RRegion
      AGroup.RPoint = RPoint
      AGroup.OffsetX = OffsetX
      AGroup.OffsetY = OffsetY
      AGroup.FromValueX = FromX
      AGroup.FromValueY = FromY
      AGroup.ToValueX = ToX
      AGroup.ToValueY = ToY

      Animation:SetFromAlpha(0)
      Animation:SetToAlpha(1)

      OnObject:ClearAllPoints()
      OnObject:SetPoint(Point, RRegion, RPoint, FromX, FromY)
      AGroup:SetScript('OnUpdate', OnObjectMove)

    elseif Type == 'fontsize' then
      local FromValue, ToValue = select(2, ...)

      AGroup.FromValue = FromValue
      AGroup.ToValue = ToValue

      Animation:SetFromAlpha(0)
      Animation:SetToAlpha(1)

      local FontType, _, FontStyle = OnObject:GetFont()

      OnObject:SetFont(FontType, FromValue, FontStyle)
      AGroup:SetScript('OnUpdate', OnObjectFontSize)

    elseif Type == 'texturescale' then
      local FromScale, ToScale = select(2, ...)

      AGroup.FromValue = FromScale
      AGroup.ToValue = ToScale

      Animation:SetScaleFrom(FromScale, FromScale)
      Animation:SetScaleTo(ToScale, ToScale)
      Animation:SetOrigin('CENTER', 0, 0)

      OnObject:SetScale(FromScale)
      AGroup:SetScript('OnUpdate', OnObjectScale)

    elseif Type == 'offset' then
      local FromLeft, FromRight, FromTop, FromBottom, ToLeft, ToRight, ToTop, ToBottom = select(2, ...)

      AGroup.DistanceLeft = ToLeft - FromLeft
      AGroup.DistanceRight = ToRight - FromRight
      AGroup.DistanceTop = ToTop - FromTop
      AGroup.DistanceBottom = ToBottom - FromBottom
      AGroup.FromValueLeft = FromLeft
      AGroup.FromValueRight = FromRight
      AGroup.FromValueTop = FromTop
      AGroup.FromValueBottom = FromBottom
      AGroup.ToValueLeft = ToLeft
      AGroup.ToValueRight = ToRight
      AGroup.ToValueTop = ToTop
      AGroup.ToValueBottom = ToBottom

      Animation:SetFromAlpha(0) -- Use From and To alpha as a way to fake offset
      Animation:SetToAlpha(1)

      SetOffsetFrame(OnObject, FromLeft, FromRight, FromTop, FromBottom)
      AGroup:SetScript('OnUpdate', OnObjectOffset)
    end
  end

  -- Check if frame is invisible or nothing to do.
  if Duration == 0 or (OffsetX == 0 and OffsetY == 0) or not Object:IsVisible() then

    -- Need to set direction here for StopAnimation(), since the animation never played
    AGroup.Direction = Direction
    StopAnimation(AGroup)
    return
  end

  if AGroup:IsPlaying() then
    -- Check for reverse animation for alpha or scale.
    if Direction then
      if Main.UnitBars.ReverseAnimation then
        local Value = AGroup.FromValue
        local Progress = AGroup:GetProgress()

        -- Calculate FromValue and duration
        FromValue = Value + (AGroup.ToValue - Value) * Progress
        if Direction then
          if Direction == 'in' then
            Duration = abs(1 - FromValue) * Duration
          else
            Duration = FromValue * Duration
          end
        end

        StopAnimation(AGroup, true)
      else
        StopAnimation(AGroup)
        Object:Show()
      end
    end
  end

  -- Alpha or scale
  if Direction then
    AGroup.FromValue = FromValue
    AGroup.ToValue = ToValue

    -- Set and play a new animation
    if Type == 'alpha' then
      Animation:SetFromAlpha(FromValue)
      Animation:SetToAlpha(ToValue)

      if OnObject then
        AGroup:SetScript('OnUpdate', OnObjectAlpha)
      end
    -- Scale
    else
      Animation:SetScaleFrom(FromValue, FromValue)
      Animation:SetScaleTo(ToValue, ToValue)
      Animation:SetOrigin('CENTER', 0, 0)

      if OnObject then

        -- Object is Anchor
        if Object.IsAnchor then
          -- AnimationFrame is already centered.  Leave this here for reference
        end
        OnObject:SetScale(0.01)
        AGroup:SetScript('OnUpdate', OnObjectScale)
      end
    end
  end

  -- Need to set direction here since StopAnimation() gets called.
  -- StopAnimation() clears the direction. So direction needs to be
  -- set here.
  -- If direction is nil then nothing is set
  AGroup.Direction = Direction

  Animation:SetDuration(Duration)
  AGroup:SetScript('OnFinished', StopAnimation)
  AGroup:Play()
end

-------------------------------------------------------------------------------
-- SetAnimationDurationBar
--
-- Sets the amount of time an animation will play for a bar
-- After being hidden or shown.
--
-- Direction      'in' or 'out'
-- Duration       Time in seconds to play for
-------------------------------------------------------------------------------
function BarDB:SetAnimationDurationBar(Direction, Duration)
  local AGroup = self.AGroup

  if Direction == 'in' then
    AGroup.DurationIn = Duration
  else
    AGroup.DurationOut = Duration
  end
end

-------------------------------------------------------------------------------
-- SetAnimationDurationTexture
--
-- Sets the amount of time an animation will play for a texture
-- After being hidden or shown.
--
-- BoxNumber      Box containing the texture
-- TextureNumber  Number that reference to the actual texture
-- Direction      'in' or 'out'
-- Duration       Time in seconds to play for
-------------------------------------------------------------------------------
function BarDB:SetAnimationDurationTexture(BoxNumber, TextureNumber, Direction, Duration)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local AGroup = Texture.AGroup

    if Direction == 'in' then
      AGroup.DurationIn = Duration
    else
      AGroup.DurationOut = Duration
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetAnimationBar
--
-- Sets a new animation type to play when the bar gets hidden or shown.
--
-- Type  'scale' or 'alpha'
--
-- NOTES: This function must be called before any animation can be done.
--        if type is 'stopall' will stop both the parent and the children animation
--        if type is 'stopchildren' then all children animation gets stopped.
-------------------------------------------------------------------------------
function BarDB:SetAnimationBar(Type)
  local AGroup = self.AGroup

  if Type == 'stopall' then
    if AGroup then
      StopPlaying(AGroup, 'all')
    end
  elseif Type == 'stopchildren' then
    if AGroup then
      StopPlaying(AGroup, 'children')
    end
  else
    self.AGroup = GetAnimation(self, self.Anchor, 'parent', Type)
  end
end

-------------------------------------------------------------------------------
-- PlayAnimationBar
--
-- Same as PlayAnimation() except its for the bar.
--
-- Hide if true otherwise shown.
-------------------------------------------------------------------------------
function BarDB:PlayAnimationBar(Direction)
  PlayAnimation(self.AGroup, Direction)
end

-------------------------------------------------------------------------------
-- SetAnimationTexture
--
-- Sets a new animation type to play when textures get hidden or shown.
--
-- BoxNumber       Box containing the texture
-- TextureNumber   Number that is a reference to the actual texture
-- Type            'scale' or 'alpha'
--
-- NOTES: This function must be called before any animation can be done.
--        This also sets the ShowHideFn call back.
-------------------------------------------------------------------------------
function BarDB:SetAnimationTexture(BoxNumber, TextureNumber, Type)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local ShowHideFn = Texture.ShowHideFn

    Texture.AGroup = GetAnimation(self, Texture, 'children', Type)

    if ShowHideFn then
      Texture.AGroup.Fn = ShowHideFn
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
function BarDB:Display()
  local ProfileChanged = Main.ProfileChanged

  local UBF = self.UnitBarF
  local UB = UBF.UnitBar
  local Anchor = UBF.Anchor

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
  local FirstBF
  local LastBF

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

  -- Cant let width and height go negative. Bad things happen.
  if Width < 1 then
    Width = 1
  end
  if Height < 1 then
    Height = 1
  end

  Region:SetSize(Width, Height)
  SetFrames(nil, BoxFrames, OffsetX * -1 + BorderPadding, OffsetY * -1 - BorderPadding)

  local SetSize = true

  if Float then
    if BoxLocations then

      -- Offset unitbar so the boxes don't move. Shift bar to the left and up based on borderpadding.
      -- Skip offsetting when switching to floating mode first time.
      if not FloatFirstTime then
        Main:SetAnchorSize(Anchor, Width, Height, OffsetX + BorderPadding * -1, OffsetY + BorderPadding, true)
        SetSize = false
      end
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
  if SetSize then
    Main:SetAnchorSize(Anchor, Width, Height)
  end
end

-------------------------------------------------------------------------------
-- SetHiddenRegion
--
-- Hides or show the region for the bar
--
-- Hide if true otherwise shown.
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
-- NOTES: HideRegion and ShowRegion will still update the state of the region.  Its just not
--        shown.  Once the region is enabled its state is restored on screen.
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
-- SetAlpha
--
-- Sets the transparency for a boxframe or texture frame.
--
-- BoxNumber        Box to set alpha on.
-- TextureNumber    if not nil then the texture frame gets alpha.
-- Alpha            Between 0 and 1.
-------------------------------------------------------------------------------
function BarDB:SetAlpha(BoxNumber, TextureFrameNumber, Alpha)
  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber]
    end

    Frame:SetAlpha(Alpha)
  until LastBox
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
      --RestoreBackdrops(Frame)
    end
    Frame.Hidden = Hide
  until LastBox
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- BAR functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetBackdropRegion
--
-- Sets the background texture to the backdrop.
--
-- TextureName           New texture to set to backdrop
-- PathName              If true then TextureName is a pathname. Otherwise nil
-------------------------------------------------------------------------------
function BarDB:SetBackdropRegion(TextureName, PathName)
  SaveSettings(self, 'SetBackdropRegion', nil, nil, TextureName, PathName)

  local Region = self.Region
  local Backdrop = GetBackdrop(Region)

  Backdrop.bgFile = PathName and TextureName or LSM:Fetch('background', TextureName) or DefaultBackdrop.bgFile
  SetBackdrop(Region, Backdrop)
end

-------------------------------------------------------------------------------
-- SetBackdropBorderRegion
--
-- Sets the border texture to the backdrop.
--
-- TextureName           New texture to set to backdrop
-- PathName              If true then TextureName is a pathname. Otherwise nil
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderRegion(TextureName, PathName)
  SaveSettings(self, 'SetBackdropBorderRegion', nil, nil, TextureName, PathName)

  local Region = self.Region
  local Backdrop = GetBackdrop(Region)

  Backdrop.edgeFile = PathName and TextureName or LSM:Fetch('border', TextureName) or DefaultBackdrop.edgeFile
  SetBackdrop(Region, Backdrop)
end

-------------------------------------------------------------------------------
-- SetBackdropTileRegion
--
-- Turns tiles off or on for the backdrop.
--
-- Tile     If true then use tiles, otherwise false.
-------------------------------------------------------------------------------
function BarDB:SetBackdropTileRegion(Tile)
  local Region = self.Region
  local Backdrop = GetBackdrop(Region)

  Backdrop.tile = Tile or DefaultBackdrop.tile
  SetBackdrop(Region, Backdrop)
end

-------------------------------------------------------------------------------
-- SetBackdropTileSizeRegion
--
-- Sets the size of the tiles for the backdrop.
--
-- TileSize            Set the size of each tile for the backdrop texture.
-------------------------------------------------------------------------------
function BarDB:SetBackdropTileSizeRegion(TileSize)
  local Region = self.Region
  local Backdrop = GetBackdrop(Region)

  Backdrop.tileSize = TileSize or DefaultBackdrop.tileSize
  SetBackdrop(Region, Backdrop)
end

-------------------------------------------------------------------------------
-- SetBackdropBorderSizeRegion
--
-- Sets the size of border for the backdrop.
--
-- BorderSize            Set the size of the border.
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderSizeRegion(BorderSize)
  local Region = self.Region
  local Backdrop = GetBackdrop(Region)

  Backdrop.edgeSize = BorderSize or DefaultBackdrop.edgeSize
  SetBackdrop(Region, Backdrop)
end

-------------------------------------------------------------------------------
-- SetBackdropPaddingRegion
--
-- Sets the amount of space between the background and the border.
--
-- Left, Right, Top, Bottom   Amount of distance to set between border and background.
-------------------------------------------------------------------------------
function BarDB:SetBackdropPaddingRegion(Left, Right, Top, Bottom)
  local Region = self.Region
  local Backdrop = GetBackdrop(Region)
  local Insets = Backdrop.insets
  local DefaultInsets = DefaultBackdrop.insets

  Insets.left =   Left   or DefaultInsets.left
  Insets.right =  Right  or DefaultInsets.right
  Insets.top =    Top    or DefaultInsets.top
  Insets.bottom = Bottom or DefaultInsets.bottom

  SetBackdrop(Region, Backdrop)
end

-------------------------------------------------------------------------------
-- SetBackdropColorRegion
--
-- Sets the color of the backdrop for the bar's region.
--
-- r, g, b, a     red, green, blue, alpha
-------------------------------------------------------------------------------
function BarDB:SetBackdropColorRegion(r, g, b, a)
  SaveSettings(self, 'SetBackdropColorRegion', nil, nil, r, g, b, a)

  local Region = self.Region
  Region:SetBackdropColor(r or 1, g or 1, b or 1, a or 1)
end

-------------------------------------------------------------------------------
-- SetBackdropBorderColorRegion
--
-- Sets the backdrop edge color of the bars region.
--
-- r, g, b, a              red, green, blue, alpha
--
-- Notes: To clear color just set nil instead of r, g, b, a.
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderColorRegion(r, g, b, a)
  SaveSettings(self, 'SetBackdropBorderColorRegion', nil, nil, r, g, b, a)

  local Region = self.Region

  Region:SetBackdropBorderColor(r or 1, g or 1, b or 1, a or 1)
end

-------------------------------------------------------------------------------
-- SetSlopeBar
--
-- Sets the slope of a bar that has a rotation of vertical or horizontal.
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

-------------------------------------------------------------------------------
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
-- CopyLayoutFloatBar()
--
-- Copies the the none floating mode layout to float.
--
-- Notes: Display() does the copy.
-------------------------------------------------------------------------------
function BarDB:CopyLayoutFloatBar()
  self.UnitBarF.UnitBar.BoxLocations = nil
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Box Frame functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetIgnoreBorderBox
--
-- The box frame will not reposition to stay within the border.
--
-- BoxNumber     Box to set the distance bewteen the next boxframe.
-- IgnoreBorder  If true the boxframe will ignore the border.
-------------------------------------------------------------------------------
function BarDB:SetIgnoreBorderBox(BoxNumber, IgnoreBorder)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)

    BoxFrame.IgnoreBorder = IgnoreBorder
  until LastBox
end

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
-- Changes a texture based on boxnumber.  SetChangeBox must be called prior.
--
-- ChangeNumber         Number you assigned the box numbers to.
-- BarFn                Bar function that can be called by BarDB:Function
--                      Must be a function that can take a boxnumber.
--                      Function must be a string.
-- ...                  1 or more values passed to Function
--
-- Example:       BarDB:SetChangeBox(2, MyBoxFrameNumber)
--                BarDB:ChangeBox(2, 'SetFillTexture', Value)
--                This would be the same as:
--                BarDB:SetFillTexture(MyBoxNumber, Value)
-------------------------------------------------------------------------------
function BarDB:ChangeBox(ChangeNumber, BarFn, ...)
  local Fn = self[BarFn]
  local BoxNumbers = self.ChangeBoxes[ChangeNumber]

  for Index = 1, #BoxNumbers do
    Fn(self, BoxNumbers[Index], ...)
  end
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Box Frame/Texture Frame functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetBackdrop
--
-- Sets the background texture to the backdrop.
--
-- BoxNumber             Box you want to set the modify the backdrop for.
-- TextureFrameNumber    If not nil then the backdrop will be set to the textureframe instead
-- TextureName           New texture to set to backdrop
-- PathName              If true then TextureName is a pathname. Otherwise nil
-------------------------------------------------------------------------------
function BarDB:SetBackdrop(BoxNumber, TextureFrameNumber, TextureName, PathName)
  SaveSettings(self, 'SetBackdrop', BoxNumber, TextureFrameNumber, TextureName, PathName)

  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber].BorderFrame
    end
    local Backdrop = GetBackdrop(Frame)

    Backdrop.bgFile = PathName and TextureName or LSM:Fetch('background', TextureName)
    SetBackdrop(Frame, Backdrop)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetbackdropBorder
--
-- Sets the border texture to the backdrop.
--
-- BoxNumber             Box you want to set the modify the backdrop for.
-- TextureFrameNumber    If not nil then the backdrop will be set to the textureframe instead
-- TextureName           New texture to set to backdrop border.
-- PathName              If true then TextureName is a pathname. Otherwise nil
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorder(BoxNumber, TextureFrameNumber, TextureName, PathName)
  SaveSettings(self, 'SetBackdropBorder', BoxNumber, TextureFrameNumber, TextureName, PathName)

  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber].BorderFrame
    end
    local Backdrop = GetBackdrop(Frame)

    Backdrop.edgeFile = PathName and TextureName or LSM:Fetch('border', TextureName)
    SetBackdrop(Frame, Backdrop)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropTile
--
-- Turns tiles off or on for the backdrop.
--
-- BoxNumber             Box you want to set the modify the backdrop for.
-- TextureFrameNumber    If not nil then the backdrop will be set to the textureframe instead
-- Tile                  If true then use tiles, otherwise false.
-------------------------------------------------------------------------------
function BarDB:SetBackdropTile(BoxNumber, TextureFrameNumber, Tile)
  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber].BorderFrame
    end
    local Backdrop = GetBackdrop(Frame)

    Backdrop.tile = Tile
    SetBackdrop(Frame, Backdrop)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropTileSize
--
-- Sets the size of the tiles for the backdrop.
--
-- BoxNumber             Box you want to set the modify the backdrop for.
-- TextureFrameNumber    If not nil then the backdrop will be set to the textureframe instead
-- TileSize              Set the size of each tile for the backdrop texture.
-------------------------------------------------------------------------------
function BarDB:SetBackdropTileSize(BoxNumber, TextureFrameNumber, TileSize)
  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber].BorderFrame
    end
    local Backdrop = GetBackdrop(Frame)

    Backdrop.tileSize = TileSize
    SetBackdrop(Frame, Backdrop)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetbackdropBorderSize
--
-- Sets the size of the border texture of the backdrop.
--
-- BoxNumber             Box you want to set the modify the backdrop for.
-- TextureFrameNumber    If not nil then the backdrop will be set to the textureframe instead
-- BorderSize            Set the size of the border.
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderSize(BoxNumber, TextureFrameNumber, BorderSize)
  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber].BorderFrame
    end
    local Backdrop = GetBackdrop(Frame)

    Backdrop.edgeSize = BorderSize
    SetBackdrop(Frame, Backdrop)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetbackdropPadding
--
-- Sets the amount of space between the background and the border.
--
-- BoxNumber                  Box you want to set the modify the backdrop for.
-- TextureFrameNumber         If not nil then the backdrop will be set to the textureframe instead
-- Left, Right, Top, Bottom   Amount of distance to set between border and background.
-------------------------------------------------------------------------------
function BarDB:SetBackdropPadding(BoxNumber, TextureFrameNumber, Left, Right, Top, Bottom)
  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber].BorderFrame
    end
    local Backdrop = GetBackdrop(Frame)
    local Insets = Backdrop.insets

    Insets.left = Left
    Insets.right = Right
    Insets.top = Top
    Insets.bottom = Bottom

    SetBackdrop(Frame, Backdrop)
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
  SaveSettings(self, 'SetBackdropColor', BoxNumber, TextureFrameNumber, r, g, b, a)

  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber].BorderFrame
    end

    Frame:SetBackdropColor(r or 1, g or 1, b or 1, a or 1)
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
--
-- Notes: To clear color just set nil instead of r, g, b, a.
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderColor(BoxNumber, TextureFrameNumber, r, g, b, a)
  SaveSettings(self, 'SetBackdropBorderColor', BoxNumber, TextureFrameNumber, r, g, b, a)

  repeat
    local Frame = NextBox(self, BoxNumber)

    if TextureFrameNumber then
      Frame = Frame.TextureFrames[TextureFrameNumber].BorderFrame
    end

    Frame:SetBackdropBorderColor(r or 1, g or 1, b or 1, a or 1)
  until LastBox
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Texture Frame functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
-- SetSizeTextureFrame
--
-- Sets the size of a texture frame.
--
-- BoxNumber           Box containing textureframe.
-- TextureFrameNumber  Texture frame to change size.
-- Width, Height       New width and height to set.
--
-- NOTES: The BoxFrame will be resized to fit the new size of the TextureFrame.
-------------------------------------------------------------------------------
function BarDB:SetSizeTextureFrame(BoxNumber, TextureFrameNumber, Width, Height)
  SaveSettings(self, 'SetSizeTextureFrame', BoxNumber, TextureFrameNumber, Width, Height)

  repeat
    local TextureFrame = NextBox(self, BoxNumber).TextureFrames[TextureFrameNumber]

    TextureFrame:SetSize(Width, Height)
    TextureFrame._Width = Width
    TextureFrame._Height = Height
  until LastBox
end

-------------------------------------------------------------------------------
-- SetOffsetsTexureFrame
--
-- Offsets the textureframe from its original size.  This will not effect the box size.
--
-- BoxNumber                 Box containing textureframe.
-- TextureFrameNumber        Texture frame to change size.
-- Left, Right, Top, Bottom  Offsets
-------------------------------------------------------------------------------
function BarDB:SetOffsetTextureFrame(BoxNumber, TextureFrameNumber, Left, Right, Top, Bottom)
  SaveSettings(self, 'SetOffsetTextureFrame', BoxNumber, TextureFrameNumber, Left, Right, Top, Bottom)

  repeat
    local BorderFrame = NextBox(self, BoxNumber).TextureFrames[TextureFrameNumber].BorderFrame

    local AGroup = BorderFrame.AGroup
    local IsPlaying = AGroup and AGroup:IsPlaying() or false

    if AnimateSpeedTrigger then
      local LastLeft = BorderFrame.LastLeft or 0
      local LastRight = BorderFrame.LastRight or 0
      local LastTop = BorderFrame.LastTop or 0
      local LastBottom = BorderFrame.LastBottom or 0

      if Left ~= LastLeft or Right ~= LastRight or Top ~= LastTop or Bottom ~= LastBottom then
        BorderFrame.LastLeft = Left
        BorderFrame.LastRight = Right
        BorderFrame.LastTop = Top
        BorderFrame.LastBottom = Bottom

        -- Create animation if not found
        if AGroup == nil then
          AGroup = GetAnimation(self, BorderFrame, 'children', 'offset')
          BorderFrame.AGroup = AGroup
        end

        if IsPlaying then
          LastLeft, LastRight, LastTop, LastBottom = StopAnimation(AGroup)
        end
        local Distance = max(abs(Left - LastLeft), abs(Right - LastRight), abs(Top - LastTop), abs(Bottom - LastBottom))
        local Duration = GetSpeedDuration(Distance, AnimateSpeedTrigger)

        PlayAnimation(AGroup, Duration, LastLeft, LastRight, LastTop, LastBottom, Left, Right, Top, Bottom)

      -- offset hasn't changed
      elseif not IsPlaying then
        SetOffsetFrame(BorderFrame, Left, Right, Top, Bottom)
      end
    else
      -- Non animated trigger call or called outside of triggers or trigger disabled.
      if IsPlaying then
        StopAnimation(AGroup)
      end
      -- This will get called if changing profiles cause UndoTriggers() will get called.
      if CalledByTrigger or Main.ProfileChanged then
        BorderFrame.LastLeft = Left
        BorderFrame.LastRight = Right
        BorderFrame.LastTop = Top
        BorderFrame.LastBottom = Bottom
      end
      SetOffsetFrame(BorderFrame, Left, Right, Top, Bottom)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetScaleTextureFrame
--
-- Changes the scale of a texture frame making things larger or smaller.
--
-- BoxNumber              Box containing the texture frame.
-- TextureFrameNumber     Texture frame to set scale to.
-- Scale                  New scale to set.
-------------------------------------------------------------------------------
function BarDB:SetScaleTextureFrame(BoxNumber, TextureFrameNumber, Scale)
  SaveSettings(self, 'SetScaleTextureFrame', BoxNumber, TextureFrameNumber, Scale)

  repeat
    local TextureFrame = NextBox(self, BoxNumber).TextureFrames[TextureFrameNumber]

    local Point, RelativeFrame, RelativePoint, OffsetX, OffsetY = TextureFrame:GetPoint()
    local OldScale = TextureFrame:GetScale()

    TextureFrame:SetScale(Scale)
    TextureFrame:SetPoint(Point, RelativeFrame, RelativePoint, OffsetX * OldScale / Scale, OffsetY * OldScale / Scale)

    --[[
    local Textures = TextureFrame.Textures
    if Textures then
      for TextureNumber, Texture in pairs(Textures) do
        if Texture.Type == 'texture' then
          local CooldownFrame = Texture.CooldownFrame

          -- descale cooldown frame
          -- Needs to be done this way, since cooldown edge texture doesn't play nice with normal scaling.
          if CooldownFrame then
            CooldownFrame:SetScale(1 / Scale)
            CooldownFrame:SetSize(CooldownFrame._Width * Scale, CooldownFrame._Height * Scale)
          end
        end
      end
    end ]]
  until LastBox
end

-------------------------------------------------------------------------------
-- SetPaddingTextureFrame
--
-- BoxNumber                  Box containing the texture.
-- TextureFrameNumber         Texture frame to apply padding.
-- Left, Right, Top, Bottom   Paddding values.
-------------------------------------------------------------------------------
function BarDB:SetPaddingTextureFrame(BoxNumber, TextureFrameNumber, Left, Right, Top, Bottom)
  repeat
    local TextureFrame = NextBox(self, BoxNumber).TextureFrames[TextureFrameNumber]
    local PaddingFrame = TextureFrame.PaddingFrame

    PaddingFrame:ClearAllPoints()
    PaddingFrame:SetPoint('TOPLEFT', Left, Top)
    PaddingFrame:SetPoint('BOTTOMRIGHT', Right, Bottom)
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
-- NOTES: This will only allow one point active at anytime.
--        If point is nil then the TextureFrame is set to boxframe.
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

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Texture functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetAlphaTexture
--
-- Sets the transparency for a texture
--
-- BoxNumber       Box containg the texture
-- TextureNumber   Texture to change the alpha of.
-- Alpha           Between 0 and 1.
-------------------------------------------------------------------------------
function BarDB:SetAlphaTexture(BoxNumber, TextureNumber, Alpha)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetAlpha(Alpha)
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
    local ShowHideFn = Texture.ShowHideFn

    if Hide ~= Hidden then
      local AGroup = Texture.AGroup

      if Hide then
        if AGroup then
          PlayAnimation(AGroup, 'out')
        else
          Texture:Hide()
          if ShowHideFn then
            ShowHideFn('out')
          end
        end
      else
        if AGroup then
          PlayAnimation(AGroup, 'in')
        else
          Texture:Show()
          if ShowHideFn then
            ShowHideFn('in')
          end
        end
      end
      Texture.Hidden = Hide
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetShowHideFnTexture
--
-- Sets a function to be called after a Texture has been hidden or shown.
--
-- BoxNumber        BoxNumber containing the texture.
-- TextureNumber    Texture that will call Fn
-- Fn               Function to call. If nil then function gets removed.
--
-- Parms passed to Fn
--   UnitBarF
--   self(BarDB)
--   BN             BoxNumber
--   TextureNumber
--   Action         'hide' or 'show'
-------------------------------------------------------------------------------
function BarDB:SetShowHideFnTexture(BoxNumber, TextureNumber, Fn)
  repeat
    local BoxFrame, BN = NextBox(self, BoxNumber)
    local Texture = BoxFrame.TFTextures[TextureNumber]

    if Fn == nil then
      Texture.ShowHideFn = nil

    elseif Texture.ShowHideFn ~= Fn then
      Texture.ShowHideFn = function(Direction)
                             Fn(self.UnitBarF, self, BN, TextureNumber, Direction == 'in' and 'show' or 'hide')
                           end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropTexture
--
-- Sets the background texture to the backdrop.
--
-- BoxNumber             Box containing the texture.
-- TextureNumber         Texture to set the backdrop to.
-- TextureName           New texture to set to backdrop
-- PathName              If true then TextureName is a pathname. Otherwise nil
-------------------------------------------------------------------------------
function BarDB:SetBackdropTexture(BoxNumber, TextureNumber, TextureName, PathName)
  SaveSettings(self, 'SetBackdropTexture', BoxNumber, TextureNumber, TextureName, PathName)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    local Frame = Texture.Frame
    local Backdrop = GetBackdrop(Frame)

    Backdrop.bgFile = PathName and TextureName or LSM:Fetch('background', TextureName)
    SetBackdrop(Frame, Backdrop)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropBorderTexture
--
-- Sets the border texture to the backdrop.
--
-- BoxNumber             Box containing the texture.
-- TextureNumber         Texture to set the backdrop to.
-- TextureName           New texture to set to backdrop border.
-- PathName              If true then TextureName is a pathname. Otherwise nil
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderTexture(BoxNumber, TextureNumber, TextureName, PathName)
  SaveSettings(self, 'SetBackdropBorderTexture', BoxNumber, TextureNumber, TextureName, PathName)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    local Frame = Texture.Frame
    local Backdrop = GetBackdrop(Frame)

    Backdrop.edgeFile = PathName and TextureName or LSM:Fetch('border', TextureName)
    SetBackdrop(Frame, Backdrop)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropTileTexture
--
-- Turns tiles off or on for the backdrop.
--
-- BoxNumber             Box containing the texture.
-- TextureNumber         Texture to set the backdrop to.
-- Tile                  If true then use tiles, otherwise false.
-------------------------------------------------------------------------------
function BarDB:SetBackdropTileTexture(BoxNumber, TextureNumber, Tile)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    local Frame = Texture.Frame
    local Backdrop = GetBackdrop(Frame)

    Backdrop.tile = Tile
    SetBackdrop(Frame, Backdrop)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropTileSizeTexture
--
-- Sets the size of the tiles for the backdrop.
--
-- BoxNumber             Box containing the texture.
-- TextureNumber         Texture to set the backdrop to.
-- TileSize              Set the size of each tile for the backdrop texture.
-------------------------------------------------------------------------------
function BarDB:SetBackdropTileSizeTexture(BoxNumber, TextureNumber, TileSize)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    local Frame = Texture.Frame
    local Backdrop = GetBackdrop(Frame)

    Backdrop.tileSize = TileSize
    SetBackdrop(Frame, Backdrop)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropBorderSizeTexture
--
-- Sets the size of the border texture of the backdrop.
--
-- BoxNumber             Box containing the texture.
-- TextureNumber         Texture to set the backdrop to.
-- BorderSize            Set the size of the border.
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderSizeTexture(BoxNumber, TextureNumber, BorderSize)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    local Frame = Texture.Frame
    local Backdrop = GetBackdrop(Frame)

    Backdrop.edgeSize = BorderSize
    SetBackdrop(Frame, Backdrop)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBackdropPaddingTexture
--
-- Sets the amount of space between the background and the border.
--
-- BoxNumber                  Box containing the texture.
-- TextureNumber              Texture to set the backdrop to.
-- Left, Right, Top, Bottom   Amount of distance to set between border and background.
-------------------------------------------------------------------------------
function BarDB:SetBackdropPaddingTexture(BoxNumber, TextureNumber, Left, Right, Top, Bottom)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    local Frame = Texture.Frame
    local Backdrop = GetBackdrop(Frame)
    local Insets = Backdrop.insets

    Insets.left = Left
    Insets.right = Right
    Insets.top = Top
    Insets.bottom = Bottom

    SetBackdrop(Frame, Backdrop)
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
  SaveSettings(self, 'SetBackdropColorTexture', BoxNumber, TextureNumber, r, g, b, a)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.Frame:SetBackdropColor(r or 1, g or 1, b or 1, a or 1)
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
--
-- Notes: To clear color just set nil instead of r, g, b, a.
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderColorTexture(BoxNumber, TextureNumber, r, g, b, a)
  SaveSettings(self, 'SetBackdropBorderColorTexture', BoxNumber, TextureNumber, r, g, b, a)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local Frame = Texture.Frame

    Frame:SetBackdropBorderColor(r or 1, g or 1, b or 1, a or 1)
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
-- BarFn                Bar function that can be called by BarDB:Function
--                      Must be a function that can take boxnumber, texturenumber.
--                      Function must be a string.
-- BoxNumber            BoxNumber containing the texture.
-- ...                  1 or more values passed to Function
--
-- Example:       BarDB:SetChangeTexture(2, TextureNumber)
--                BarDB:ChangeTexture(2, 'SetFillTexture', 0, Value)
--                This would be the same as:
--                BarDB:SetFillTexture(0, TextureNumber, Value)
-------------------------------------------------------------------------------
function BarDB:ChangeTexture(ChangeNumber, BarFn, BoxNumber, ...)
  local Fn = self[BarFn]
  local TextureNumbers = self.ChangeTextures[ChangeNumber]

  if BoxNumber > 0 then
    for Index = 1, #TextureNumbers do
      Fn(self, BoxNumber, TextureNumbers[Index], ...)
    end
  else
    local NumTextures = #TextureNumbers

    for BoxIndex = 1, self.NumBoxes do
      for Index = 1, NumTextures do
        Fn(self, BoxIndex, TextureNumbers[Index], ...)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetFillMaxRangeTexture
--
-- Statusbars
--
-- Sets the maximum value it will take to fully show the whole statusbar
--
-- BoxNumber           Box containing the fill texture
-- TextureNumber       Texture frame that contains the statusbar frame
-- MaxRange            Any value above 0
-------------------------------------------------------------------------------
function BarDB:SetFillMaxRangeTexture(BoxNumber, TextureNumber, MaxRange)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetMaxRange(MaxRange)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillMaxValueTexture
--
-- Statusbars
--
-- Sets the max value setfill can use on any statusbar that's created in the
-- texture frame.
--
-- BoxNumber           Box containing the fill texture
-- TextureNumber       Texture frame that contains the statusbar frame
-- Value               New maximum for the fill part of all textures
--
-- NOTES: This must be the texture that was created with type 'statusbar' in CreateTexture()
-------------------------------------------------------------------------------
function BarDB:SetFillMaxValueTexture(BoxNumber, TextureNumber, Value)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetMaxValue(Value)
    Texture.MaxValue = Value
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillTimer (timer function for filling)
--
-- Statusbars
--
-- Subfunction of SetFillTime
--
-- Fills a bar over time
-------------------------------------------------------------------------------
local function SetFillTimer(Texture)
  local TimeElapsed = GetTime() - Texture.StartTime
  local Duration = Texture.Duration

  if TimeElapsed <= Duration then

    -- Calculate current value.
    local Value = Texture.StartValue + Texture.Range * (TimeElapsed / Duration)
    Texture:SetValue(Value)
    Texture.Value = Value
  else
    -- Stop timer
    Main:SetTimer(Texture, nil)

    -- set the end value.
    local EndValue = Texture.EndValue
    Texture:SetValue(EndValue)
    Texture.Value = EndValue
  end
end

-------------------------------------------------------------------------------
-- SetFillTime
--
-- Statusbars
--
-- Subfunction of SetFillTimeTexture
--
-- Fills a texture over a period of time.
--
-- Texture           Texture to fill over time.
-- TPS               Times per second.  This is how many times per second
--                   The timer will be called. The higher the number the smoother
--                   the animation but also the more cpu is consumed.
-- StartTime         Starting time if nil then starts instantly.
-- Duration          Time it will take to go from StartValue to EndValue.
-- StartValue        Starting value between 0 and MaxValue.  If nill the current value
--                   is used instead.
-- EndValue          Ending value between 0 and MaxValue. If nill then MaxValue is used.
-- Constant          If true then the bar fills at a constant speed
--                   Duration becomes Speed. Must be between 0 and 1
-------------------------------------------------------------------------------
local function SetFillTime(Texture, TPS, StartTime, Duration, StartValue, EndValue, Constant)
  Main:SetTimer(Texture, nil)
  local MaxValue = Texture.MaxValue

  Duration = Duration or 0
  StartValue = StartValue and StartValue or Texture.Value
  EndValue = EndValue and EndValue or MaxValue

  -- Only start a timer if startvalue and endvalues are not equal.
  if StartValue ~= EndValue and Duration > 0 then
    -- Set up the paramaters.
    local CurrentTime = GetTime()
    local Range = EndValue - StartValue

    -- Turn duration into constant speed if set.
    if Constant then
      local SmoothFillMaxTime = Texture.SmoothFillMaxTime

      Duration = GetSpeedDuration(Range * 100, Duration)
      if Duration > SmoothFillMaxTime then
        Duration = SmoothFillMaxTime
      end
    end

    StartTime = StartTime and StartTime or CurrentTime
    Texture.StartTime = StartTime

    Texture.Duration = Duration
    Texture.Range = Range
    Texture.Value = StartValue
    Texture.StartValue = StartValue
    Texture.EndValue = EndValue

    Main:SetTimer(Texture, SetFillTimer, TPS, StartTime - CurrentTime)
  else
    Texture:SetValue(EndValue)
    Texture.Value = EndValue
  end
end

-------------------------------------------------------------------------------
-- SetFillTimeDurationTexture
--
-- Statusbars
--
-- Changes the duration of a fill timer already in progress.  This will cause
-- the bar to speed up or slow down without stutter.
--
-- BoxNumber         Box containing the texture being changed
-- TextureNumber     Texture being used in fill.
-- NewDuration       Time in seconds. The bar will fill over time using this
--                   duration from where it left off.
-------------------------------------------------------------------------------
function BarDB:SetFillTimeDurationTexture(BoxNumber, TextureNumber, NewDuration)
  local Texture = self.BoxFrames[BoxNumber].TFTextures[TextureNumber]

  -- Make sure a timer has already been intialized
  if Texture.Duration ~= nil then
    local Time = GetTime()
    local TimeElapsed = Time - Texture.StartTime
    local Duration = Texture.Duration

    -- Bar must be currently filling
    if TimeElapsed <= Duration then

      -- Bring Current Value up to date
      local Value = Texture.StartValue + Texture.Range * (TimeElapsed / Duration)
      Texture.Value = Value

      --Calc new start time based on NewDuration and Value
      --Value is usually between 0 and 1
      Texture.StartTime = Time - Value * NewDuration
      Texture.Duration = NewDuration
    end
  end
end

-------------------------------------------------------------------------------
-- SetFillTimeTexture
--
-- Statusbars
--
-- Fills a texture over a period of time.
--
-- BoxNumber         Box containing the texture to fill over time.
-- TextureNumber     Texture being used in fill.
-- StartTime         Starting time if nil then starts instantly.
-- Duration          Time it will take to reach from StartValue to EndValue.
-- StartValue        Starting value between 0 and MaxValue.  If nill the current value
--                   is used instead.
-- EndValue          Ending value between 0 and MaxValue. If nill MaxValue is used.
--
-- NOTES: To stop a timer just call this function with just the BoxNumber and TextureNumber
-------------------------------------------------------------------------------
function BarDB:SetFillTimeTexture(BoxNumber, TextureNumber, StartTime, Duration, StartValue, EndValue)
  local Texture = self.BoxFrames[BoxNumber].TFTextures[TextureNumber]

  SetFillTime(Texture, 1 / Main.UnitBars.BarFillFPS, StartTime, Duration, StartValue, EndValue)
end

-------------------------------------------------------------------------------
-- SetFillTexture
--
-- Statusbars
--
-- Changes the value of a statusbar
--
-- BoxNumber        Box containing texture to fill
-- TextureNumber    Texture to apply fill to
-- Value            A number between 0 and MaxValue
--
-- NOTES: See SetFill().
--        This fills at a constant speed.  The speed is calculated from the time
--        it would take to fill the bar from empty to full.
-------------------------------------------------------------------------------
function BarDB:SetFillTexture(BoxNumber, TextureNumber, Value)
  local Texture = self.BoxFrames[BoxNumber].TFTextures[TextureNumber]
  local SmoothFillMaxTime = Texture.SmoothFillMaxTime
  local Speed = SmoothFillMaxTime and SmoothFillMaxTime > 0 and Texture.Speed or 0

  -- If Speed > 0 then fill the texture from its current value to a new value.
  if Speed > 0 then
    SetFillTime(Texture, 1 / Main.UnitBars.BarFillFPS, nil, Speed, nil, Value, true)
  else
    Texture:SetValue(Value)
    Texture.Value = Value
  end
end

-------------------------------------------------------------------------------
-- SetFillScaleHorizontalTexture
--
-- Statusbars
--
-- Changes the scale of the fill only in horizontal mode
--
-- BoxNumber        Box that contains the texture
-- TextureNumber    Texture to change the scaling of the fill
-- ScaleX           Scale in horizontal
-- ScaleY           Scale in vertical
-------------------------------------------------------------------------------
function BarDB:SetFillScaleHorizontalTexture(BoxNumber, TextureNumber, ScaleX, ScaleY)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetScaleHorizontal(ScaleX, ScaleY)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillScaleVerticalTexture
--
-- Statusbars
--
-- Changes the scale of the fill only in horizontal mode
--
-- BoxNumber        Box that contains the texture
-- TextureNumber    Texture to change the scaling of the fill
-- ScaleX           Scale in horizontal
-- ScaleY           Scale in vertical
-------------------------------------------------------------------------------
function BarDB:SetFillScaleVerticalTexture(BoxNumber, TextureNumber, ScaleX, ScaleY)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetScaleVertical(ScaleX, ScaleY)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillPointPixelTexture
--
-- statusbars
--
-- BoxNumber              Box containing texture.
-- TextureNumber          Texture to modify.
-- Point                  String. Point to set. Set nil to clear
-- OffsetX, OffsetY       X, Y offset in pixels from Point. Set nill to clear
--
-- NOTES: If Point is nil then OffSetX, OffsetY is only used unless nil also
-------------------------------------------------------------------------------
function BarDB:SetFillPointPixelTexture(BoxNumber, TextureNumber, Point, OffsetX, OffsetY)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetPointPixel(Point, OffsetX, OffsetY)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillPixelSizeTexture
--
-- Statusbars
--
-- Sets the width and height in pixels instead of in value
--
-- BoxNumber        Box containing texture
-- TextureNumber    Texture to set width
-- PixelWidth       Width in pixels. Use nil to clear
-- PixelHeight      Height in pixels. Use nil to clear
-------------------------------------------------------------------------------
function BarDB:SetFillPixelSizeTexture(BoxNumber, TextureNumber, PixelWidth, PixelHeight)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetPixelSize(PixelWidth, PixelHeight)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillPixelWidthTexture
--
-- Statusbars
--
-- Sets the width in pixels instead of in value
--
-- BoxNumber        Box containing texture
-- TextureNumber    Texture to set width
-- PixelWidth       Width in pixels. Use nil to clear
-------------------------------------------------------------------------------
function BarDB:SetFillPixelWidthTexture(BoxNumber, TextureNumber, PixelWidth)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetPixelWidth(PixelWidth)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillPixelHeightTexture
--
-- Statusbars
--
-- Sets the height in pixels instead of in value
--
-- BoxNumber        Box containing texture
-- TextureNumber    Texture to set height
-- PixelHeight      Height in pixels. Use nil to clear
-------------------------------------------------------------------------------
function BarDB:SetFillPixelHeightTexture(BoxNumber, TextureNumber, PixelHeight)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetPixelHeight(PixelHeight)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillPixelLengthTexture
--
-- Statusbars
--
-- Sets the length in pixels instead of in value
--
-- BoxNumber        Box containing texture
-- TextureNumber    Texture to set width
-- PixelLength      Length in pixels. Use nil to clear
--
-- NOTES: Overrides width in horizontal mode and overrirdes
--        height in vertical mode
-------------------------------------------------------------------------------
function BarDB:SetFillPixelLengthTexture(BoxNumber, TextureNumber, PixelLength)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetPixelLength(PixelLength)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillReverseTexture
--
-- Statusbars
--
-- BoxNumber        Box containing texture
-- TextureNumber    Texture to reverse fill
-- Action           true         The fill will be reversed.  Right to left or top to bottom.
--                  false        Default fill.  Left to right or bottom to top.
-------------------------------------------------------------------------------
function BarDB:SetFillReverseTexture(BoxNumber, TextureNumber, Action)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetFillReverse(Action)
  until LastBox
end

-------------------------------------------------------------------------------
-- SyncFillDirectionTexture
--
-- Statusbars
--
-- Makes it so the fill direction changes based on rotation
--
-- BoxNumber        Box containing texture
-- TextureNumber    Texture to sync the fill direction
-- Action           true then the texture will change direction based on rotation
-------------------------------------------------------------------------------
function BarDB:SyncFillDirectionTexture(BoxNumber, TextureNumber, Action)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SyncFillDirection(Action)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillRotationTexture
--
-- Statusbars
--
-- Rotates a statusbar texture.
--
-- BoxNumber      Box containing the texture.
-- TextureNumber  Texture to rotate.
-- Rotation       Can be -90, 0, 90, 180
-------------------------------------------------------------------------------
function BarDB:SetFillRotationTexture(BoxNumber, TextureNumber, Rotation)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    if Texture.Type == 'statusbar' then
      Texture:SetRotation(Rotation)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillClippingTexture
--
-- Statusbars
--
-- Turns off and on clipping. Causing textures to stretch instead
--
-- BoxNumber        Box containing texture
-- TextureNumber    Texture to change clipping
-- Action           false then the texture will not be clipped
-------------------------------------------------------------------------------
function BarDB:SetFillClippingTexture(BoxNumber, TextureNumber, Action)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetClipping(Action)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillDirectionTexture
--
-- Statusbars
--
-- BoxNumber        Box containing texture
-- TextureNumber    Texture to apply the fill direction to
-- Direction        'HORIZONTAL'   Fill from left to right.
--                  'VERTICAL'     Fill from bottom to top.
-------------------------------------------------------------------------------
function BarDB:SetFillDirectionTexture(BoxNumber, TextureNumber, Direction)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetFillDirection(Direction)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillMaxValueTexture
--
-- Statusbars
--
-- Sets the length of a texture in a statusbar
--
-- BoxNumber      Box containing the texture.
-- TextureNumber  Texture to change the max value of
-- MaxValue         Max value of texture in scale.  This is not in pixels
-------------------------------------------------------------------------------
function BarDB:SetFillMaxValueTexture(BoxNumber, TextureNumber, MaxValue)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetMaxValue(MaxValue)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillHideFullTexture
--
-- Statusbars
--
-- Hides the texture when fill has reached max
--
-- BoxNumber        Box containing texture
-- TextureNumber    Texture to hide
-- HideFull     true or false
-------------------------------------------------------------------------------
function BarDB:SetFillHideFullTexture(BoxNumber, TextureNumber, HideFull)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:HideFull(HideFull)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillOverlapTexture
--
-- Statusbars
--
-- Hides the texture when fill has reached max
--
-- BoxNumber        Box containing texture
-- TextureNumber    Texture to hide
-- Overlap          true or false
-------------------------------------------------------------------------------
function BarDB:SetFillOverlapTexture(BoxNumber, TextureNumber, Overlap)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetOverlap(Overlap)
  until LastBox
end

-------------------------------------------------------------------------------
-- LinkFillTexture
--
-- Statusbars
--
-- Links one or more textures to another texture
--
-- BoxNumber           Box containing texture frame
-- FirstTextureNumber  First texture in the link
-- ...                 One or or more textures linked to FirstTexture
-------------------------------------------------------------------------------
function BarDB:LinkFillTexture(BoxNumber, FirstTextureNumber, ...)
  repeat
    local TFTextures = NextBox(self, BoxNumber).TFTextures
    local FirstTexture = TFTextures[FirstTextureNumber]
    local Textures = {...}

    for Index = 1, #Textures do
      Textures[Index] = TFTextures[Textures[Index]]
    end

    FirstTexture:Link(unpack(Textures))
  until LastBox
end

-------------------------------------------------------------------------------
-- UnLinkFillTexture
--
-- Statusbars
--
-- Removes one or all linked textures
--
-- BoxNumber            Box containing texture frame
-- TextureNumber        Must be the start of the link
-------------------------------------------------------------------------------
function BarDB:UnLinkFillTexture(BoxNumber, TextureNumber)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:UnLink()
  until LastBox
end

-------------------------------------------------------------------------------
-- TagTexture
--
-- Statusbars
--
-- Tags a texture to another. Texture can be a linked texture
--
-- BoxNumber            Box containing texture frame
-- TextureNumber        Texture that will be tagged to another texture
-- Action
--   left               Tagged textures will grow from left to right starting from the target links edge
--   right              Tagged textures will grow from right to left starting from the target links edge
-- TargetTextureNumber  Texture or linked texture that the texture is being tagged to
-------------------------------------------------------------------------------
function BarDB:TagFillTexture(BoxNumber, TextureNumber, Action, TargetTextureNumber)
  repeat
    local TFTextures = NextBox(self, BoxNumber).TFTextures

    TFTextures[TextureNumber]:Tag(Action, TFTextures[TargetTextureNumber])
  until LastBox
end

-------------------------------------------------------------------------------
-- UnTagFillTexture
--
-- Statusbars
--
-- Removes a tag on a texturem, returning it to normal
--
-- BoxNumber            Box containing texture frame
-- TextureNumber        Texture to remove the tag from
-------------------------------------------------------------------------------
function BarDB:UnTagFillTexture(BoxNumber, TextureNumber)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:UnTag()
  until LastBox
end

-------------------------------------------------------------------------------
-- TagInheritTexture
--
-- A texture will not inherit the stats from the texture it's tagged to
--
-- BoxNumber            Box containing texture frame
-- TextureNumber
-- Inherit              true or false: if false it will not inherit
-------------------------------------------------------------------------------
function BarDB:TagFillInheritTexture(BoxNumber, TextureNumber, Inherit)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:TagInherit(Inherit)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetFillSpeedTexture
--
-- Statusbars
--
-- Changes the speed from the bar will fill at.
--
-- BoxNumber       Box containing the texture
-- TextureNumber   Texture to smooth fill on.
-- Speed           Must be between 0 and 1. 1 = max speed.
-------------------------------------------------------------------------------
function BarDB:SetFillSpeedTexture(BoxNumber, TextureNumber, Speed)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    -- Stop any fill timers currently running, to avoid bugs.
    local Duration = Texture.Duration
    if Duration and Duration > 0 then

      Main:SetTimer(Texture, nil)

      -- set the end value.
      local EndValue = Texture.EndValue
      Texture:SetValue(EndValue)
      Texture.Value = EndValue

      Texture.Duration = 0
    end

    Texture.Speed = Speed
  until LastBox
end

-------------------------------------------------------------------------------
-- SetSmoothFillMaxTimeTexture
--
-- Statusbars
--
-- Set the amount of time in seconds a smooth fill animation can take.
--
-- BoxNumber       Box containing the texture
-- TextureNumber   Texture to smooth fill on.
-- SmoothFill      Time in seconds, if 0 then smooth fill is disabled.
-------------------------------------------------------------------------------
function BarDB:SetSmoothFillMaxTimeTexture(BoxNumber, TextureNumber, SmoothFillMaxTime)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.SmoothFillMaxTime = SmoothFillMaxTime
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
-- Duration         Time it will take to cooldown the texture. If duration is 0 timer is stopped.
--
-- NOTES: To stop timer just set duration to 0
-------------------------------------------------------------------------------
function BarDB:SetCooldownTexture(BoxNumber, TextureNumber, StartTime, Duration)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local CooldownFrame = Texture.CooldownFrame

    CooldownFrame:SetCooldown(StartTime or 0, Duration or 0)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetCooldownReverseTexture
--
-- Inverts the bright and dark portions of the cooldown animation
--
-- BoxNumber        Box containing the texture to cooldown.
-- TextureNumber    Texture to cooldown.
-- Reverse          If true then invert.
-------------------------------------------------------------------------------
function BarDB:SetCooldownReverseTexture(BoxNumber, TextureNumber, Reverse)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.CooldownFrame:SetReverse(Reverse)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetCooldownCircularTexture
--
-- Changes a cooldown to use a round border instead of a square
--
-- BoxNumber        Box containing the texture to cooldown.
-- TextureNumber    Texture to cooldown.
-- Circular         If true then use a circular border
-------------------------------------------------------------------------------
function BarDB:SetCooldownCircularTexture(BoxNumber, TextureNumber, Circular)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.CooldownFrame:SetUseCircularEdge(Circular)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetCooldownDrawEdgeTexture
--
-- Hides or shows the edge texture thats drawn during a cooldown animation
--
-- BoxNumber        Box containing the texture to cooldown.
-- TextureNumber    Texture to cooldown.
-- Edge             If true then show the edge texture
-------------------------------------------------------------------------------
function BarDB:SetCooldownDrawEdgeTexture(BoxNumber, TextureNumber, Edge)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.CooldownFrame:SetDrawEdge(Edge)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetCooldownDrawFlashTexture
--
-- Hides or shows the flash animation at the end of a cooldown
--
-- BoxNumber        Box containing the texture to cooldown.
-- TextureNumber    Texture to cooldown.
-- Flash            If true then show then show the flash animation
-------------------------------------------------------------------------------
function BarDB:SetCooldownDrawFlashTexture(BoxNumber, TextureNumber, Flash)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.CooldownFrame:SetDrawBling(Flash)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetCooldownSwipeColorTexture
--
-- Set the color of the swipe texture.
--
-- BoxNumber        Box containing the texture to cooldown.
-- TextureNumber    Texture to cooldown.
-- r, g, b, a       red, green, blue, alpha
-------------------------------------------------------------------------------
function BarDB:SetCooldownSwipeColorTexture(BoxNumber, TextureNumber, r, g, b, a)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.CooldownFrame:SetSwipeColor(r or 1, g or 1, b or 1, a or 1)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetCooldownSwipeTexture
--
-- Changes the texture that is used in the cooldown clock animation
--
-- BoxNumber        Box containing the texture to cooldown.
-- TextureNumber    Texture to cooldown.
-- SwipeTexture     New texture used for the cooldown animation.
-------------------------------------------------------------------------------
function BarDB:SetCooldownSwipeTexture(BoxNumber, TextureNumber, SwipeTexture)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.CooldownFrame:SetSwipeTexture(SwipeTexture)

    -- Set color so colored textures have color.
    Texture.CooldownFrame:SetSwipeColor(1, 1, 1, 1)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetCooldownEdgeTexture
--
-- Replaces the default bright line that is on the moving edge of the cooldown
-- animation
--
-- BoxNumber        Box containing the texture to cooldown.
-- TextureNumber    Texture to cooldown.
-- EdgeTexture      New bright line texture to use.
-------------------------------------------------------------------------------
function BarDB:SetCooldownEdgeTexture(BoxNumber, TextureNumber, EdgeTexture)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.CooldownFrame:SetEdgeTexture(EdgeTexture)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetCooldownBlingTexture
--
-- Replaces the default bling texture animation
--
-- BoxNumber        Box containing the texture to cooldown.
-- TextureNumber    Texture to cooldown.
-- BlingTexture     New texture to replace the old bling one
-------------------------------------------------------------------------------
function BarDB:SetCooldownBlingTexture(BoxNumber, TextureNumber, BlingTexture)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture.CooldownFrame:SetBlingTexture(BlingTexture)
  until LastBox
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
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local TextureFrame = Texture.TextureFrame
    local CooldownFrame = Texture.CooldownFrame

    CooldownFrame._Width = Width
    CooldownFrame._Height = Height

    local _Width = TextureFrame._Width
    local _Height = TextureFrame._Height
    local ScaledWidth  = Width / _Width
    local ScaledHeight = Height / _Height

    CooldownFrame:SetSize(_Width * ScaledWidth, _Height * ScaledHeight)

    if OffsetX or OffsetY then
      CooldownFrame:ClearAllPoints()
      CooldownFrame:SetPoint('CENTER', OffsetX or 0, OffsetY or 0)
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
-------------------------------------------------------------------------------
function BarDB:SetSizeTexture(BoxNumber, TextureNumber, Width, Height)
  SaveSettings(self, 'SetSizeTexture', BoxNumber, TextureNumber, Width, Height)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]
    local TextureFrame = Texture.TextureFrame
    local Frame = Texture.Frame

    Frame._Width = Width
    Frame._Height = Height

    local _Width = TextureFrame._Width
    local _Height = TextureFrame._Height
    local ScaledWidth  = Width / _Width
    local ScaledHeight = Height / _Height

    Frame:SetSize(_Width * ScaledWidth, _Height * ScaledHeight)

    -- This is needd so textures show for the first time
    if Frame:GetSize() then end
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
  SaveSettings(self, 'SetColorTexture', BoxNumber, TextureNumber, r, g, b, a)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetBlendModeTexture
--
-- Does Texture:SetBlendMode(Type)
--
-- BoxNumber      Box containing texture
-- TextureNumber  Texture to blend
-- Type           Type of blend
-------------------------------------------------------------------------------
function BarDB:SetBlendModeTexture(BoxNumber, TextureNumber, Type)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetBlendMode(Type)
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
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetDesaturated(Action)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetTexture
--
-- Sets the texture of a statusbar or texture.
--
-- BoxNumber         BoxNumber to change the texture in.
-- TextureNumber     Texture to change.
-- TextureName       Name if its statusbar otherwise it's the path to the texture.
-------------------------------------------------------------------------------
function BarDB:SetTexture(BoxNumber, TextureNumber, TextureName)
  SaveSettings(self, 'SetTexture', BoxNumber, TextureNumber, TextureName)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    if LSM:IsValid('statusbar', TextureName) then
      Texture:SetTexture(LSM:Fetch('statusbar', TextureName))
    else
      Texture:SetTexture(TextureName)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetAtlasTexture
--
-- Sets a texture via atlas.  Only blizzard atlas can be used.
--
-- BoxNumber      BoxNumber to change the texture in.
-- TextureNumber  Texture to change.
-- AtlasName      Name of the atlas you want to set.  Must be a string.
-- UseSize        Assuming if true then it uses the actual atlas texture size
--                overwriting the original texture size. If nil defaults to false.
-------------------------------------------------------------------------------
function BarDB:SetAtlasTexture(BoxNumber, TextureNumber, AtlasName, UseSize)
  SaveSettings(self, 'SetAtlasTexture', BoxNumber, TextureNumber, AtlasName, UseSize)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetAtlas(AtlasName, UseSize or false)
  until LastBox
end

-------------------------------------------------------------------------------
-- SetScaleAllTexture
--
-- Changes the size based on scale. All textures that belong to the same
-- textureframe will get scaled at the same time.
--
-- BoxNumber             Box containing the texture.
-- TextureNumber         Texture to change the scale of. All other textures
--                       in the same textureframe will get scaled too
-- Scale                 New scale to set.
--
-- NOTES: Supports animation if called by a trigger.
-------------------------------------------------------------------------------
function BarDB:SetScaleAllTexture(BoxNumber, TextureNumber, Scale)
  SaveSettings(self, 'SetScaleAllTexture', BoxNumber, TextureNumber, Scale)

  repeat
    local ScaleFrame = NextBox(self, BoxNumber).TFTextures[TextureNumber].ScaleFrame

    local AGroup = ScaleFrame.AGroup
    local IsPlaying = AGroup and AGroup:IsPlaying() or false

    if AnimateSpeedTrigger then
      local LastScale = ScaleFrame.LastScale or 0

      if Scale ~= LastScale then
        ScaleFrame.LastScale = Scale

        -- Create animation if not found
        if AGroup == nil then
          AGroup = GetAnimation(self, ScaleFrame, 'children', 'texturescale')
          ScaleFrame.AGroup = AGroup
        end

        if IsPlaying then
          LastScale = StopAnimation(AGroup)
        end
        local FromScale = LastScale > 0 and LastScale or 0.01
        local ToScale = Scale > 0 and Scale or 0.1

        local Duration = GetSpeedDuration(abs(ToScale - FromScale) * 50, AnimateSpeedTrigger)

        PlayAnimation(AGroup, Duration, FromScale, ToScale)

      -- Scale hasn't changed
      elseif not IsPlaying then
        ScaleFrame:SetScale(Scale)
      end
    else
      -- Non animated trigger call or called outside of triggers or trigger disabled.
      if IsPlaying then
        StopAnimation(AGroup)
      end
      -- This will get called if changing profiles cause UndoTriggers() will get called.
      if CalledByTrigger or Main.ProfileChanged then
        ScaleFrame.LastScale = Scale
      end

      ScaleFrame:SetScale(Scale)
    end
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

    if Texture.Type == 'statusbar' then
      Texture:SetTexCoord(Left, Right, Top, Bottom)
    else
      Texture:SetTexCoord(Left, Right, Top, Bottom)
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
-- NOTES: All bar functions are called thru the returned table.
--        CreateBar will embed certain functions like dragging/moving.
-------------------------------------------------------------------------------
function GUB.Bar:CreateBar(UnitBarF, ParentFrame, NumBoxes)

  -- Make bar a frame so it can be used in onupdate for Display()
  local Bar = CreateFrame('Frame')
  local Anchor = UnitBarF.Anchor

  -- Copy the functions.
  for FnName, Fn in pairs(BarDB) do
    if type(Fn) == 'function' then
      Bar[FnName] = Fn
    end
  end

  Bar.Hidden = nil
  Bar.UnitBarF = UnitBarF
  Bar.Anchor = Anchor
  Bar.BarType = UnitBarF.BarType
  Bar.NumBoxes = NumBoxes
  Bar.Rotation = 90
  Bar.Slope = 0
  Bar.Swap = false
  Bar.Float = false
  Bar.BorderPadding = 0
  Bar.Justify = 'SIDE'
  Bar.Align = false
  Bar.AlignOffsetX = 0
  Bar.AlignOffsetY = 0
  Bar.AlignPaddingX = 0
  Bar.AlignPaddingY = 0
  Bar.RegionEnabled = true
  Bar.BoxFrames = {}

  -- Create the region frame.
  local Region = CreateFrame('Frame', nil, ParentFrame, 'BackdropTemplate')
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
    local BoxFrame = CreateFrame('Frame', nil, BoxBorder, 'BackdropTemplate')

    BoxFrame:SetSize(1, 1)
    BoxFrame:SetPoint('TOPLEFT')

    -- Make the boxframe movable.
    BoxFrame:SetMovable(true)

    -- Save frame data to the bar database.
    BoxFrame.BoxNumber = BoxFrameIndex
    BoxFrame.Padding = 0
    BoxFrame.Hidden = false
    BoxFrame.MaxFrameLevel = 0
    BoxFrame.TextureFrames = {}
    BoxFrame.TFTextures = {}
    Bar.BoxFrames[BoxFrameIndex] = BoxFrame
  end

  return Bar
end

-------------------------------------------------------------------------------
-- OnSizeChangedFrame (called by setscript)
--
-- Updates the width and height of the Texture.Frame
--
-- SizeFrame       Frame whos size has changed
-- Width, Height   Width and Height of the StatusBar
--
-- NOTES: This makes sure that Texture.Frame size stays relative to the
--        size of the SizeFrame.  Things like padding, offsets etc can effect size
-------------------------------------------------------------------------------
local function OnSizeChangedFrame(SizeFrame, Width, Height)
  local TextureFrame = SizeFrame.TextureFrame
  local Frames = SizeFrame.Frames

  local _Width = TextureFrame._Width
  local _Height = TextureFrame._Height

  SizeFrame.ScaleFrame:SetSize(Width, Height)

  for Index = 1, #Frames do
    local Frame = Frames[Index]

    -- if width and height not set then use TextureFrame width and height
    local FrameWidth = Frame._Width or _Width
    local FrameHeight = Frame._Height or _Height

    -- Get scaled width and height based on the width and height
    -- Set by SetSizeTexture()
    local ScaledWidth = FrameWidth / _Width
    local ScaledHeight = FrameHeight / _Height

    Frame:SetSize(Width * ScaledWidth, Height * ScaledHeight)
  end
end

-------------------------------------------------------------------------------
-- CreateTextureFrame
--
-- Usage: CreateTextureFrame(BoxNumber, TextureFrameNumber, FrameLevel)
--        CreateTextureFrame(BoxNumber, TextureFrameNumber, FrameLevel, 'statusbar')
--
-- BoxNumber            Which box you're creating a TexureFrame in.
-- TextureFrameNumber   A number assigned to the TextureFrame
-- FrameLevel           FrameLevel for the texture frame.
-- statusbar            Works the same as a texture frame, plus it can store statusbar
--                      frome create texture
--
-- NOTES: TextureFrames are always the same size as BoxFrame, unless you do a SetPoint on it.
--        TextureFrameNumber must be linier.  So you can't do a TextureFrameNumber of 1 then 2, and 5.
--        Must be 1,2,3.  You can create them out of order so long as there's no holes.
-------------------------------------------------------------------------------
function BarDB:CreateTextureFrame(BoxNumber, TextureFrameNumber, FrameLevel, TextureFrameType)
  repeat
    local BoxFrame = NextBox(self, BoxNumber)
    local TextureFrames = BoxFrame.TextureFrames

    -- Create the texture frame.
    local TF = CreateFrame('Frame', nil, BoxFrame)
    local FrameLevel = FrameLevel + TF:GetFrameLevel()
    TF:SetFrameLevel(FrameLevel)

    TF:SetPoint('TOPLEFT')
    TF:SetSize(1, 1)

    local BorderFrame = CreateFrame('Frame', nil, TF, 'BackdropTemplate')
    local PaddingFrame = CreateFrame('Frame', nil, BorderFrame)
    local SizeFrame = CreateFrame('Frame', nil, PaddingFrame)
    local ScaleFrame = CreateFrame('Frame', nil, SizeFrame)

    if TextureFrameType == 'statusbar' then
      local SBF = CreateStatusBarFrame(ScaleFrame)
      SBF:ClearAllPoints()
      SBF:SetAllPoints()

      TF.SBF = SBF
    elseif TextureFrameType then
      assert(false, 'CreateTextureFrame - Invalid texture type')
    end

    SizeFrame:SetScript('OnSizeChanged', OnSizeChangedFrame)

    SizeFrame.Frames = {}
    SizeFrame.TextureFrame = TF
    SizeFrame.ScaleFrame = ScaleFrame

    BorderFrame:SetAllPoints()
    PaddingFrame:SetAllPoints()

    -- Scale frame's size is done thru OnSizeChangedFrame().  So ScaleFrame has to be
    -- set CENTER. SetScale() doesn't work well with frames that have SetAllPoints()
    ScaleFrame:SetPoint('CENTER')
    SizeFrame:SetAllPoints()

    FrameLevel = FrameLevel + 7

    TF:Hide()
    TF.Hidden = true

    TF._Width = 1
    TF._Height = 1

    TF.BorderFrame = BorderFrame
    TF.PaddingFrame = PaddingFrame
    TF.ScaleFrame = ScaleFrame
    TF.SizeFrame = SizeFrame

    TF.TextureFrameNumber = TextureFrameNumber

    TF.MaxFrameLevel = FrameLevel
    TextureFrames[TextureFrameNumber] = TF
  until LastBox
end

-------------------------------------------------------------------------------
-- CreateTexture
--
-- BoxNumber              Box you're creating a texture in.
-- TextureFrameNumber     Texture frame that you're creating a texture in. Used in CreateTextureFrame()
-- Level                  Current virtual level for the texture.
-- TextureNumber          Must be a unique number per box.  Only time the number
--                        can be the same is if the same texture used in two or more
--                        different boxes.
-- TextureType             cooldown          is the same as texture Except it can use SetCooldownTexture()
--                         statusbar         can only be used if the TextureFrame was created with type statusbar
--                         statusbar_noclip  same as statusbar except it will not get clipped by the statusbar frame
--                         texture           standard texture, nothing special
-- StatusBarSubLayer      Statusbar only.  Set the layer for the statusbar texture. layer can be 1 to 16.
--                        If nil defaults to 1
--
-- NOTES: When creating a texture of type statusbar.  The textureframe must be of type statusbar too
-------------------------------------------------------------------------------
function BarDB:CreateTexture(BoxNumber, TextureFrameNumber, TextureNumber, TextureType, StatusBarSubLayer)
  local TextureTypes = {cooldown = 1, statusbar = 1, statusbar_noclip = 1, texture = 1}
  if TextureTypes[TextureType] == nil then
    assert(false, 'CreateTexture - Invalid texture type')
  end

  local TextureTypeNoClip = false
  if TextureType == 'statusbar_noclip' then
    TextureType = 'statusbar'
    TextureTypeNoClip = true
  end

  repeat
    local BoxFrame = NextBox(self, BoxNumber)
    local TextureFrame = BoxFrame.TextureFrames[TextureFrameNumber]
    local ScaleFrame = TextureFrame.ScaleFrame
    local Frames = TextureFrame.SizeFrame.Frames
    local MaxFrameLevel = TextureFrame.MaxFrameLevel
    local Texture
    local Frame

    -- Add a statusbar to the statusbar frame created with CreateTextureFrame
    -- Frame don't need to be stored since the StatusBar freme is in the textureframe
    if TextureType == 'statusbar' then
      local SBF = TextureFrame.SBF

      if SBF == nil then
        assert(false, 'CreateTexture - Texture frame is not of type statusbar')
      elseif type(StatusBarSubLayer) ~= 'number' then
        assert(false, 'CreateTexture - SubLayer is invalid')
      end
      if TextureTypeNoClip then
        Texture = SBF:CreateTexture(StatusBarSubLayer, 'noclip')
      else
        Texture = SBF:CreateTexture(StatusBarSubLayer)
      end
      Texture:SetRotation(0) -- horizontal

      Texture.SBF = SBF

      -- Statusbars default to zero when first created
      Texture.Value = 0

    elseif TextureType == 'texture' or TextureType == 'cooldown' then
      Frame = CreateFrame('Frame', nil, ScaleFrame)
      Frame:SetPoint('CENTER')
      Frame:SetFrameLevel(MaxFrameLevel)

      Texture = Frame:CreateTexture()
      Texture:SetAllPoints()

      -- Set defaults for texture.
      Texture.TexLeft = 0
      Texture.TexRight = 1
      Texture.TexTop = 0
      Texture.TexBottom = 1

      Texture.Frame = Frame
      Texture.Hidden = true

      Frames[#Frames + 1] = Frame

      MaxFrameLevel = MaxFrameLevel + 1

      if TextureType == 'cooldown' then
        TextureType = 'texture'

        local CooldownFrame = CreateFrame('Cooldown', nil, ScaleFrame, 'CooldownFrameTemplate')
        CooldownFrame:SetPoint('CENTER')  -- Undoing template SetAllPoints
        CooldownFrame:SetFrameLevel(MaxFrameLevel)
        CooldownFrame:SetHideCountdownNumbers(true)

        Texture.CooldownFrame = CooldownFrame

        -- Add this to frames since this is the same thing
        Frames[#Frames + 1] = CooldownFrame

        MaxFrameLevel = MaxFrameLevel + 1
      end
    end

    TextureFrame.MaxFrameLevel = MaxFrameLevel

    Texture:Hide()

    -- Set max framelevel for the boxframe
    if BoxFrame.MaxFrameLevel < MaxFrameLevel then
      BoxFrame.MaxFrameLevel = MaxFrameLevel
    end

    if TextureFrame.Textures == nil then
      TextureFrame.Textures = {}
    end

    -- Set a reference to the scale frame for Scaling of textures
    Texture.ScaleFrame = TextureFrame.ScaleFrame
    Texture.BorderFrame  = TextureFrame.BorderFrame
    Texture.TextureFrame = TextureFrame

    Texture.Type = TextureType

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

  -- Iterate thru text data
  for BT, TextData in pairs(BarTextData) do

    -- Iterate thru the fontstring array.
    for _, TD in ipairs(TextData) do
      local Texts = TD.Texts

      if Texts then
        local NumStrings = #Texts

        for Index, TF in ipairs(TD.TextFrames) do
          local r, g, b, a = 1, 1, 1, 0

          if not HideTextHighlight and not UnitBars[TD.BarType].Layout.HideText then

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
              elseif TD.BarType == BarType and TextIndex == Index then
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
--  Usage: Value = FontGetValue[Type](TextData, Value, ValueType)
--
--  TextData    TextData object created by CreateFont()
--  Value       Value to be modifed in some way.
--  ValueType   Same value as Type below.
--  Type        Will call a certain function based on Type.
--
--  Value       Value returned based on ValueType
-------------------------------------------------------------------------------
local FontGetValue = {}

  local function FontGetValue_Short(ParValues, Value, ValueType)
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

  FontGetValue['whole_dgroups'] = function(ParValues, Value, ValueType)
    return NumberToDigitGroups(Value)
  end

  FontGetValue['percent'] = function(ParValues, Value, ValueType)
    local MaxValue = ParValues.maximum

    if MaxValue == 0 then
      return 0
    else
      local PercentFn = ParValues.PercentFn

      if PercentFn then
        return PercentFn(Value, MaxValue)
      else
        return ceil(Value / MaxValue * 100)
      end
    end
  end

  FontGetValue['thousands'] = function(ParValues, Value, ValueType)
    return Value / 1000
  end

  FontGetValue['thousands_dgroups'] = function(ParValues, Value, ValueType)
    return NumberToDigitGroups(Round(Value / 1000))
  end

  FontGetValue['millions'] = function(ParValues, Value, ValueType)
    return Value / 1000000
  end

  FontGetValue['millions_dgroups'] = function(ParValues, Value, ValueType)
    return NumberToDigitGroups(Round(Value / 1000000, 1))
  end

  local function SetNameData(ParValues, Value, ValueType)
    local Name = ParValues.name or ''

    if ValueType == 'unitname' then
      return Name
    else
      local Realm = ParValues.name2 or ''

      if ValueType == 'realmname' then
        return Realm
      else
        if Realm ~= '' then
          Realm = '-' .. Realm
        end
        return Name .. Realm
      end
    end
  end

  FontGetValue['unitname'] = SetNameData
  FontGetValue['realmname'] = SetNameData
  FontGetValue['unitnamerealm'] = SetNameData

  local function SetLevelData(ParValues, Value, ValueType)
    local UnitLevelScaled
    local Level = ParValues.level
    local ScaledLevel = ParValues.level2

    if Level == -1 or ScaledLevel == -1 then
      Level = [[|TInterface\TargetingFrame\UI-TargetingFrame-Skull:0:0|t]]
      if ScaledLevel == -1 then
        ScaledLevel = Level
      end
      UnitLevelScaled = Level
    end

    if ValueType == 'unitlevel' then
      return Level
    elseif ValueType == 'scaledlevel' then
      return ScaledLevel
    else -- unitlevelscaled
      if Level ~= ScaledLevel then
        return format('%s (%s)', ScaledLevel, Level)
      else
        return UnitLevelScaled or Level
      end
    end
  end

  FontGetValue['unitlevel'] = SetLevelData
  FontGetValue['scaledlevel'] = SetLevelData
  FontGetValue['unitlevelscaled'] = SetLevelData

  -- timeSS, timeSS_H, timeSS_HH, powername, counter, countermin, countermax (no function needed)

-------------------------------------------------------------------------------
-- SetValue (method for Font)
--
-- BoxNumber          Boxnumber that contains the font string.
-- ...                Type, Value pairs.  Example:
--                      'current', CurrValue, 'maximum', MaxValue, 'predicted', PredictedPower, 'name', Unit)
-------------------------------------------------------------------------------
local function SetValue(FontString, Layout, ParValues, ValueOrder, FormatStrings, NumValues, ValueNames, ValueTypes, ...)
  if NumValues > 0 then

    -- ParValue will be nil if Name is 'none'
    local ValueIndex = ValueOrder[NumValues]
    local Name = ValueNames[ValueIndex]
    local ParValue = ParValues[Name]

    if ValueIndex and ParValue ~= nil then
      Layout = FormatStrings[ValueIndex] .. Layout
    end

    if ParValue ~= nil then
      local ValueType = ValueTypes[ValueIndex]
      local GetValue = FontGetValue[ValueType]

      return SetValue(FontString, Layout, ParValues, ValueOrder, FormatStrings, NumValues - 1, ValueNames, ValueTypes,
                      ParValue ~= '' and GetValue and GetValue(ParValues, ParValue, ValueType) or ParValue, ...)
    else
      return SetValue(FontString, Layout, ParValues, ValueOrder, FormatStrings, NumValues - 1, ValueNames, ValueTypes, ...)
    end
  else
    FontString:SetFormattedText(Layout, ...)
  end
  return Layout
end

-- SetValueFont
function BarDB:SetValueFont(BoxNumber, ...)
  local Frame = self.BoxFrames[BoxNumber]

  local TextData = Frame.TextData
  local MaxPar = select('#', ...)
  local Index = 1

  wipe(ParValues)
  while Index <= MaxPar do
    local ParType, ParValue = select(Index, ...)
    ParValues[ParType] = ParValue

    -- Handle parms with 2 values
    if ParType == 'level' or ParType == 'name' then
      Index = Index + 1
      ParValues[format('%s2', ParType)] = select(Index + 1, ...)
    end
    Index = Index + 2
  end

  local Texts = TextData.Texts
  local ValueLayouts = TextData.ValueLayouts

  for Index = 1, #Texts do
    local Text = Texts[Index]
    local ErrorMessage = Text.ErrorMessage
    local FontString = TextData[Index]

    if ErrorMessage == nil then
      local ValueLayout = ValueLayouts[Index]
      local ValueNames = Text.ValueNames

      -- Display the font string
      -- Call with an empty layout so each call doesn't create a longer string each time.
      ValueLayout.Layout = SetValue(FontString, '', ParValues, ValueLayout.ValueOrder, ValueLayout.FormatStrings, #ValueNames, ValueNames, Text.ValueTypes)
    else
      FontString:SetFormattedText('Err (%d)', Index)
      Options:AddDebugLine(format('%s - Err (%d) :%s', self.BarType, Index, ErrorMessage))
    end
  end
end

-------------------------------------------------------------------------------
-- SetValueRawFont
--
-- Allows you to set text directly to all the text lines.
--
-- BoxNumber       Boxnumber that contains the font string.
-- Text            Output to display to the text lines
-------------------------------------------------------------------------------
function BarDB:SetValueRawFont(BoxNumber, Text)
  repeat
    local Frame = NextBox(self, BoxNumber)

    local TextData = Frame.TextData

    for Index = 1, #TextData do
      TextData[Index]:SetText(Text)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetColorFont
--
-- Changes the font color
--
-- BoxNumber      Boxframe that contains the font.
-- TextLine       Which line of text is being changed.
-------------------------------------------------------------------------------
function BarDB:SetColorFont(BoxNumber, TextLine, r, g, b, a)
  SaveSettings(self, 'SetColorFont', BoxNumber, TextLine, r, g, b, a)

  repeat
    local Frame = NextBox(self, BoxNumber)
    local TextData = Frame.TextData

    -- Check for fontstrings
    if TextData then
      local FontString = TextData[TextLine]

      if FontString then
        FontString:SetTextColor(r or 1, g or 1, b or 1, a or 1)
      end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetOffsetFont
--
-- Offsets the font without changing the location.
--
-- BoxNumber          Boxframe that contains the font.
-- TextLine           Which line of text is being changed.
-- OffsetX            Distance in pixels to offset horizontally
-- OffsetY            Distance in pixels to offset vertically
--                    If OffsetX and OffsetY are nil then option setting is used.
--
-- NOTES: Supports animation if called by a trigger.
-------------------------------------------------------------------------------
function BarDB:SetOffsetFont(BoxNumber, TextLine, OffsetX, OffsetY)
  SaveSettings(self, 'SetOffsetFont', BoxNumber, TextLine, OffsetX, OffsetY)

  repeat
    local Frame = NextBox(self, BoxNumber)
    local TextData = Frame.TextData
    local Texts = TextData.Texts

    -- Check for fontstrings
    if TextData then
      local Text = Texts[TextLine]
      local FontString = TextData[TextLine]

      if FontString and Text then
        local AGroup = FontString.AGroupOSF
        local IsPlaying = AGroup and AGroup:IsPlaying() or false
        local Ox = Text.OffsetX
        local Oy = Text.OffsetY

        if AnimateSpeedTrigger then
          local LastX = FontString.LastX or 0
          local LastY = FontString.LastY or 0

          if OffsetX ~= LastX or OffsetY ~= LastY then
            FontString.LastX = OffsetX
            FontString.LastY = OffsetY

            -- Create animation if not found
            if AGroup == nil then
              AGroup = GetAnimation(self, FontString, 'children', 'move')
              FontString.AGroupOSF = AGroup
            end

            if IsPlaying then
              LastX, LastY = StopAnimation(AGroup)
              LastX = LastX - Ox
              LastY = LastY - Oy
            end
            -- Find the distance
            local FromX = Ox + LastX
            local FromY = Oy + LastY
            local ToX = Ox + OffsetX
            local ToY = Oy + OffsetY

            local DistanceX = abs(ToX - FromX)
            local DistanceY = abs(ToY - FromY)
            local Distance = sqrt(DistanceX * DistanceX + DistanceY * DistanceY)

            local Duration = GetSpeedDuration(Distance, AnimateSpeedTrigger)
            PlayAnimation(AGroup, Duration, Text.FontAnchorPosition, Frame, Text.FontBarPosition, FromX, FromY, ToX, ToY)

          -- offset hasn't changed
          elseif not IsPlaying then
            FontString:ClearAllPoints()
            FontString:SetPoint(Text.FontAnchorPosition, Frame, Text.FontBarPosition, Ox + OffsetX, Oy + OffsetY)
          end
        else
          -- Non animated trigger call or called outside of triggers or trigger disabled.
          if IsPlaying then
            StopAnimation(AGroup)
          end
          -- This will get called if changing profiles cause UndoTriggers() will get called.
          if CalledByTrigger or Main.ProfileChanged then
            FontString.LastX = OffsetX or 0
            FontString.LastY = OffsetY or 0
          end

          FontString:ClearAllPoints()
          FontString:SetPoint(Text.FontAnchorPosition, Frame, Text.FontBarPosition, Ox + (OffsetX or 0), Oy + (OffsetY or 0))
        end
      end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetSizeFont
--
-- Changes the size of the font.
--
-- BoxNumber      Boxframe that contains the font.
-- TextLine       Which line of text is being changed.
-- Size           Size of the font. If nil uses option setting.
--
-- NOTES: Supports animation if called by a trigger.
-------------------------------------------------------------------------------
local function ClipFont(Size)
  if Size < 1 then
    return 1
  elseif Size > 185 then
    return 185
  else
    return Size
  end
end

local function SetFont(FontString, Text, Type, Size, Style)
  Size = ClipFont(Size)
  local ReturnOK = pcall(FontString.SetFont, FontString, Type, Size, Style)
  if not ReturnOK then
    FontString:SetFont(LSM:Fetch('font', Text.FontType), Size, 'NONE')
  end
end

function BarDB:SetSizeFont(BoxNumber, TextLine, Size)
  SaveSettings(self, 'SetSizeFont', BoxNumber, TextLine, Size)

  repeat
    local Frame = NextBox(self, BoxNumber)
    local TextData = Frame.TextData
    local Texts = TextData.Texts

    -- Check for fontstrings
    if TextData then
      local FontString = TextData[TextLine]
      local Text = Texts[TextLine]

      if FontString and Text then
        local AGroup = FontString.AGroupSSF
        local IsPlaying = AGroup and AGroup:IsPlaying() or false
        local OSize = Text.FontSize

        if AnimateSpeedTrigger then
          local LastSize = FontString.LastSize or 0

          if Size ~= LastSize then
            FontString.LastSize = Size

            -- Create animation if not found
            if AGroup == nil then
              AGroup = GetAnimation(self, FontString, 'children', 'fontsize')
              FontString.AGroupSSF = AGroup
            end
            if IsPlaying then
              LastSize = StopAnimation(AGroup)
              LastSize = LastSize - OSize
            end
            local FromSize = ClipFont(OSize + LastSize)
            local ToSize = ClipFont(OSize + Size)

            local Duration = GetSpeedDuration(abs(ToSize - FromSize), AnimateSpeedTrigger)

            PlayAnimation(AGroup, Duration, FromSize, ToSize)

          -- size hasn't changed
          elseif not IsPlaying then
            SetFont(FontString, Text, LSM:Fetch('font', Text.FontType), ClipFont(OSize + Size), Text.FontStyle)
          end
        else
          -- Non animated trigger call or called outside of triggers or trigger disabled.
          if IsPlaying then
            StopAnimation(AGroup)
          end
          -- This will get called if changing profiles cause UndoTriggers() will get called.
          if CalledByTrigger or Main.ProfileChanged then
            FontString.LastSize = Size or 0
          end

          SetFont(FontString, Text, LSM:Fetch('font', Text.FontType), ClipFont(OSize + (Size or 0)), Text.FontStyle)
        end
      end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetTypeFont
--
-- Changes what type of font is used.
--
-- BoxNumber      Boxframe that contains the font.
-- TextLine       Which line of text is being changed.
-- Type           Type of font. If nil uses option setting.
-------------------------------------------------------------------------------
function BarDB:SetTypeFont(BoxNumber, TextLine, Type)
  SaveSettings(self, 'SetTypeFont', BoxNumber, TextLine, Type)

  repeat
    local Frame = NextBox(self, BoxNumber)
    local TextData = Frame.TextData
    local Texts = TextData.Texts

    -- Check for fontstrings
    if TextData then
      local FontString = TextData[TextLine]
      local Text = Texts[TextLine]

      if FontString and Text then
        Type = Type or Text.FontType

        -- Set font size
        local ReturnOK, Message = pcall(FontString.SetFont, FontString, LSM:Fetch('font', Type), Text.FontSize, Text.FontStyle)

        if not ReturnOK then
          FontString:SetFont(LSM:Fetch('font', Type), Text.FontSize, 'NONE')
        end
      end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetStyleFont
--
-- Changes the font style: Outline, thick, etc
--
-- BoxNumber      Boxframe that contains the font.
-- TextLine       Which line of text is being changed.
-- Style          Can be, NONE, OUTLINE, THICK. or a combination.
--                If nil uses option setting.
-------------------------------------------------------------------------------
function BarDB:SetStyleFont(BoxNumber, TextLine, Style)
  SaveSettings(self, 'SetStyleFont', BoxNumber, TextLine, Style)

  repeat
    local Frame = NextBox(self, BoxNumber)
    local TextData = Frame.TextData
    local Texts = TextData.Texts

    -- Check for fontstrings
    if TextData then
      local FontString = TextData[TextLine]
      local Text = Texts[TextLine]

      if FontString and Text then

        -- Set font size
        local ReturnOK = pcall(FontString.SetFont, FontString, LSM:Fetch('font', Text.FontType), Text.FontSize, Style or Text.FontStyle)

        if not ReturnOK then
          FontString:SetFont(LSM:Fetch('font', Text.FontType), Text.FontSize, 'NONE')
        end
      end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- ParseLayoutFont
--
-- Parses the layout so it can be used in SetValueFont()
-------------------------------------------------------------------------------
local function ParseLayoutFont(TextData)
  local ValueLayouts = TextData.ValueLayouts

  if ValueLayouts == nil then
    ValueLayouts = {}
    TextData.ValueLayouts = ValueLayouts
  end

  local Texts = TextData.Texts

  for TextIndex = 1, #Texts do
    local Text = Texts[TextIndex]
    local ValueNames = Text.ValueNames
    local ValueTypes = Text.ValueTypes
    local Layout = strtrim(Text.Layout)
    Text.Layout = Layout

    local ValueLayout = ValueLayouts[TextIndex]
    if ValueLayout == nil then
      ValueLayout = {}
      ValueLayouts[TextIndex] = ValueLayout
    end

    local ValueOrder = {}
    local FormatStrings = {}
    ValueLayout.Layout = ''
    ValueLayout.ValueOrder = ValueOrder
    ValueLayout.FormatStrings = FormatStrings

    if Layout ~= '' then
      local StartIndex = 1
      local Index
      local ValueIndex
      local ErrorMessage = ''
      local LeftBracket
      local OrderIndex = 0
      local ReturnOK
      local Msg

      repeat
        OrderIndex = OrderIndex + 1
        Layout = strtrim(strsub(Layout, StartIndex))

        if Layout ~= '' then
          -- Validate tag and get ValueIndex
          -- Search for letters only until the first non letter is found
          -- Next keep searching until a non number is found
          -- If the final character is '(' then stop search.
          _, StartIndex, ValueIndex, LeftBracket = strfind(Layout, '^[%a]*([%d]*)(%()')

          ValueIndex = tonumber(ValueIndex)
          if ValueIndex == nil or LeftBracket == nil then
            ErrorMessage = 'Invalid tag or "(" not found'
          else
            Index = StartIndex + 1

            -- Get the format string.
            while true do
              Index = strfind(Layout, ')', Index, true)

              if Index == nil then
                ErrorMessage = '")" not found'
                break
              else
                Index = Index + 1

                -- Skip if 2 in a row
                if strsub(Layout, Index, Index) == ')' then
                  Index = Index + 1
                else
                  local FormatString = strsub(Layout, StartIndex + 1, Index - 2)

                  if FormatString == '' then
                    ErrorMessage = 'No format string found'
                  else
                    FormatString = gsub(FormatString, '%)%)', ')')
                    ReturnOK = true

                    -- Validate format string
                    if ValueNames[ValueIndex] ~= 'none' then
                      local ValueType = ValueTypes[ValueIndex]
                      local TestData = ValueLayoutTest[ValueType]

                      ReturnOK, Msg = pcall(TestFontString.SetFormattedText, TestFontString, FormatString, TestData)
                    end

                    if not ReturnOK then
                      ErrorMessage = Msg
                    else
                      ValueOrder[OrderIndex] = ValueIndex
                      -- make sure \n works
                      FormatStrings[ValueIndex] = gsub(FormatString, '\\n', '\n' )
                      StartIndex = Index
                    end
                  end
                  break
                end
              end
            end
          end
        end
      until Layout == '' or ErrorMessage ~= ''
      if ErrorMessage ~= '' then
        Text.ErrorMessage =  OrderIndex .. ':' .. ErrorMessage
      else
        Text.ErrorMessage = nil

        -- Create sample text
        SetValue(TestFontString, '', ParValuesTest, ValueOrder, FormatStrings, #ValueNames, ValueNames, ValueTypes)
        Text.SampleText = 'Sample Text: \n' .. (TestFontString:GetText() or '')
      end
    end
  end
end

-------------------------------------------------------------------------------
-- GetLayoutFont
--
-- ValueNames      Array containing the names.
-- ValueTypes      Array containing the types.
--
-- Returns:
--   Layout       String containing the new layout.
-------------------------------------------------------------------------------
local function GetLayoutFont(ValueNames, ValueTypes)
  local LastName
  local Sep = ''
  local Space
  local Layout = ''
  local SepFlag = false
  local ValueIndex = 0
  local MaxValueNames = 0

  -- Get the real number of value names
  for NameIndex, Name in ipairs(ValueNames) do
    if Name ~= 'none' then
      MaxValueNames = MaxValueNames + 1
    end
  end

  for NameIndex, Name in ipairs(ValueNames) do
    if Name ~= 'none' then

      -- Check for valid tag
      local Tag = ValueLayoutTag[ValueNames[NameIndex]]

      if Tag then
        ValueIndex = ValueIndex + 1
        Tag = Tag .. NameIndex .. '('

        -- Add a '/' between current and maximum.
        if NameIndex > 1 then
          if not SepFlag and (LastName == 'current' and Name == 'maximum' or
                              LastName == 'maximum' and Name == 'current') then
            Sep = '/ '
            SepFlag = true
          else
            Sep = ''
          end
        end
        if Name == 'countermax' then
          Sep = '/ '
        end

        if ValueIndex < MaxValueNames then
          Space = ' '
        else
          Space = ''
        end

        LastName = Name
        Layout = Layout .. Tag .. Sep .. (GetValueLayout[ValueTypes[NameIndex]] or '') .. Space .. ')   '
      end
    end
  end

  return Layout
end

-------------------------------------------------------------------------------
-- UpdateFont
--
-- Updates a font based on the text settings in UnitBar.Text
--
-- BoxNumber            BoxFrame that contains the font. Cant use 0.
-- ColorIndex           Sets color[ColorIndex] bypassing Color.All setting.
-------------------------------------------------------------------------------
function BarDB:UpdateFont(BoxNumber, ColorIndex)
  local MaxFrameLevel = self.BoxFrames[BoxNumber].MaxFrameLevel
  local UBD = DUB[self.BarType]

  local Frame = self.BoxFrames[BoxNumber]

  local TextData = Frame.TextData
  local TextTableName = TextData.TextTableName
  local Texts = self.UnitBarF.UnitBar[TextTableName]

  local Multi = UBD[TextTableName]._Multi

  TextData.Texts = Texts

  local TextFrames = TextData.TextFrames

  -- Adjust the fontstring array based on the text settings.
  for Index = 1, #Texts do
    local FontString = TextData[Index]
    local Text = Texts[Index]
    local TextFrame = TextFrames[Index]
    local Color = Text.Color
    local c
    local ColorAll = Color.All

    -- Colorall dont exist then fake colorall.
    if ColorAll == nil then
      ColorAll = true
    end

    -- Update the layout if not in custom mode.
    if not Text.Custom then
      Text.Layout = GetLayoutFont(Text.ValueNames, Text.ValueTypes)
    end

    -- Create a new fontstring if one doesn't exist.
    if FontString == nil then
      TextFrame = CreateFrame('Frame', nil, Frame, 'BackdropTemplate')
      TextFrame:SetBackdrop(FrameBorder)
      TextFrame:SetBackdropBorderColor(1, 1, 1, 0)

      FontString = TextFrame:CreateFontString()

      TextFrame:ClearAllPoints()
      TextFrame:SetAllPoints(FontString)

      TextFrames[Index] = TextFrame
      TextData[Index] = FontString
    end

    -- Set font size, type, and style
    self:SetTypeFont(BoxNumber, Index)
    self:SetSizeFont(BoxNumber, Index)
    self:SetStyleFont(BoxNumber, Index)

    -- Set font location
    FontString:SetJustifyH(Text.FontHAlign)
    FontString:SetJustifyV(Text.FontVAlign)
    FontString:SetShadowOffset(Text.ShadowOffset, -Text.ShadowOffset)

    -- Position the font by moving the font.
    self:SetOffsetFont(BoxNumber, Index)

    -- Set the text frame to be on top.
    TextFrame:SetFrameLevel(MaxFrameLevel)

    if FontString:GetText() == nil then
      FontString:SetText('')
    end

    if ColorAll then
      c = Color
    elseif ColorIndex then
      c = Color[ColorIndex]
    else
      c = Color[BoxNumber]
    end
    self:SetColorFont(BoxNumber, Index, c.r, c.g, c.b, c.a)
  end

  -- Erase font string data no longer used.
  for Index = 1, 10 do
    if Texts[Index] == nil then
      local FontString = TextData[Index]

      if FontString then
        FontString:SetText('')
      end
    end
  end
  TextData.Multi = Multi
  TextData.Texts = Texts

  ParseLayoutFont(TextData)
end

-------------------------------------------------------------------------------
-- CreateFont
--
-- Creates a font object to display text on the bar.
--
-- TextTableName        Name of the table that contains the text in the unitbar
-- BoxNumber            Boxframe you want the font to be displayed on.
-- PercentFn            Function to calculate percents in FontSetValue()
--                      Not all percent calculations are the same. So this
--                      adds that flexibility. If nil uses its own math.
-------------------------------------------------------------------------------
function BarDB:CreateFont(TextTableName, BoxNumber, PercentFn)
  local BarType = self.BarType
  local Texts = self.UnitBarF.UnitBar[TextTableName]

  repeat
    local Frame = NextBox(self, BoxNumber)

    local TextData = {}

    -- Add text data to the bar text data table.
    if BarTextData[BarType] == nil then
      BarTextData[BarType] = {}
    end
    local BTD = BarTextData[BarType]
    BTD[#BTD + 1] = TextData

    -- Store the text data.
    TextData.BarType = BarType
    TextData.TextFrames = {}
    TextData.PercentFn = PercentFn
    TextData.Texts = Texts
    TextData.TextTableName = TextTableName

    Frame.TextData = TextData
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
-- Returns true if any options were set by SO
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
--              Only part of this name needs to match the TableName passed to DoOption()
-- KeyName      This is the keyname that is looked up in DoOption()
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
  local Option
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
-- TableName      Once the TableName in SO() is found in the default unitbar data, then unitbar data.
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
    OptionData[format('p%s', Index)] = (select(Index, ...))
  end
end

-------------------------------------------------------------------------------
-- DoOption
--
-- Calls a function thats set to TableName and KeyName
--
-- If PTableName is nil then matches all TableNames
-- If PKeyName is nil then it matches all KeyNames
--
-- Read the notes at the top for details.
-------------------------------------------------------------------------------
function BarDB:DoOption(PTableName, PKeyName)
  local UB = self.UnitBarF.UnitBar
  local UBD = DUB[self.BarType]

  local Options = self.Options
  local OptionsData = self.OptionsData

  -- Search for TableName in Options
  for TableNameIndex = 1, #Options do
    local Option = Options[TableNameIndex]
    local TName = Option.TableName
    local KeyNames = Option.KeyNames

    if PTableName == nil or strfind(PTableName, TName) then
      local TableName2 = PTableName or TName

      -- Search KeyName in Option.
      for KeyNameIndex = 1, #KeyNames do
        local KeyName = KeyNames[KeyNameIndex]
        local KName = KeyName.Name

        -- Check for recursion.  We don't want to recursivly call the same function.
        if not KeyName.Recursive and (PKeyName == nil or KName == '_' or KName == PKeyName) then

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
                    OptionData.KeyName = KName
                    if Value == nil then
                      Value = UBData
                    end
                    KeyName.Recursive = true
                    local Fn = KeyName.Fn

                    -- Is this not a color all table?
                    if type(Value) ~= 'table' or Value.All == nil then
                      Fn(Value, UB, OptionData)
                    else
                      local Offset = UBD[DUBTableName][KName]._Offset or 0
                      local ColorAll = Value.All
                      local c = Value

                      for ColorIndex = 1, #Value do
                        if not ColorAll then
                          c = Value[ColorIndex]
                        end
                        OptionData.Index = ColorIndex + Offset
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

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Trigger functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- SetTriggersCustomGroup
--
-- Works with custom groups only
-- Like SetTriggers accept it turns on or off a custom groups boxnumber
--
-- NOTES: ... can be a index table containing the boxes or parms
-------------------------------------------------------------------------------
function BarDB:SetTriggersCustomGroup(GroupName, Active, ...)
  local TriggerData = self.TriggerData
  local Group = TriggerData.NameToGroup[GroupName]

  if Group == nil then
    assert(false, 'SetTriggersCustomGroup - Invalid GroupName: ' .. GroupName)
  else
    local ActiveBoxes = TriggerData.ActiveBoxesCustom[Group]

    if ActiveBoxes == nil then
      ActiveBoxes = {}
      TriggerData.ActiveBoxesCustom[Group] = ActiveBoxes
    end

    for Index = 1, #ActiveBoxes do
      ActiveBoxes[Index] = -1
    end

    if Active then
      if type(...) == 'table' then
        local BoxNumbers = ...

        for Index = 1, #BoxNumbers do
          ActiveBoxes[Index] = BoxNumbers[Index] or -1
        end
      else
        for Index = 1, select('#', ...) do
          local BoxNumber = select(Index, ...) or -1

          ActiveBoxes[Index] = BoxNumber
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetTriggersActive
--
-- Sets which box is currently active or inactive.  This is used by
-- the ALL option
-------------------------------------------------------------------------------
function BarDB:SetTriggersActive(BoxNumber, Active)
  self.TriggerData.ActiveBoxesAll[BoxNumber] = Active
end

-------------------------------------------------------------------------------
-- SetTriggers
--
-- InputName       Name of the input defined by the bar, also appears in options
-- Value           boolean, number, string.  Must be a number when using MaxValue
-- MaxValue        Only used when dealing with perecent
-------------------------------------------------------------------------------
function BarDB:SetTriggers(InputName, Value, MaxValue)

  -- Check inputname
  if self.TriggerData.InputValueNames[InputName] == nil then
    assert(false, 'SetTriggers - Invalid InputName: ' .. InputName)
  end

  -- Check for percentage
  if MaxValue ~= nil then
    if MaxValue == 0 then
      Value = 0
    else
      Value = ceil(Value / MaxValue * 100)
    end
  end
  self.TriggerData.InputValues[InputName] = Value
end

-------------------------------------------------------------------------------
-- UndoTriggers
--
-- Undoes triggers as if they never existed.
-------------------------------------------------------------------------------
function BarDB:UndoTriggers(Triggers)
  -- Set CallbyTrigger true so there's no recursion
  CalledByTrigger = true
  RestoreSettings(self)
  CalledByTrigger = false
end
local UndoTriggers = BarDB.UndoTriggers

-------------------------------------------------------------------------------
-- CheckTriggersAuras
--
-- Subfunction of CheckTriggers()
-------------------------------------------------------------------------------
function BarDB:CheckTriggersAuras()
  local ActiveTriggers = self.TriggerData.ActiveTriggers
  local AuraTrackersData = Main.AuraTrackersData

  for TriggerIndex = 1, #ActiveTriggers do
    local ActiveTrigger = ActiveTriggers[TriggerIndex]
    local Auras = ActiveTrigger.Auras
    local All = Auras.All
    local BreakLoop = false
    local Result

    for AuraIndex = 1, #Auras do
      local Aura = Auras[AuraIndex]
      local SpellID = Aura.SpellID
      local Units = Aura.Units

      for UnitIndex = 1, #Units do
        local Unit = Units[UnitIndex]
        -- Unit must exist for valid results
        local GameAuras = UnitExists(Unit) and AuraTrackersData[Unit]
        Result = false

        if GameAuras then
          local Own = Aura.Own
          local Stacks = Aura.Stacks
          local StackOperator = Aura.StackOperator
          local Type = Aura.Type
          local CheckDebuffTypes = Aura.CheckDebuffTypes
          local GameAura
          local GameActive
          local GameStacks
          local GameOwn
          local GameType

          if SpellID > 0 then
            GameAura = GameAuras[SpellID]
            if GameAura then
              GameActive = GameAura.Active
              GameStacks = GameAura.Stacks
              GameOwn = GameAura.Own
              GameType = GameAura.Type
            end
          else
            -- NO spell ID, check any spell
            -- Check for buff or debuffs
            -- Type:  1 = buff      2 = debuff
            if Type == 1 then
              GameAuras = GameAuras.Buff
              GameType = 1
            elseif Type == 2 then
              GameAuras = GameAuras.Debuff
              GameType = 2
            end
            GameActive = GameAuras.Active
            GameStacks = GameAuras.Stacks
            GameOwn = GameAuras.Own
          end

          -- Aura must be active
          if GameActive then
            -- Check stacks
            Result = StackOperator == '<'  and GameStacks <  Stacks or
                     StackOperator == '>'  and GameStacks >  Stacks or
                     StackOperator == '<=' and GameStacks <= Stacks or
                     StackOperator == '>=' and GameStacks >= Stacks or
                     StackOperator == '='  and GameStacks == Stacks or
                     StackOperator == '<>' and GameStacks ~= Stacks or false

            -- Own:  0 = option not selected. 1 = own     2 = not own
            Result = Result and ( Own == 0 or GameOwn == (Own == 1) ) and
                                ( Type == 0 or GameType == Type )
            if Result then
              -- Check debuff   1 = buff    2 = debuff    0 = both
              if CheckDebuffTypes and Aura.Type ~= 1 and GameType ~= 1 then
                if SpellID > 0 then
                  Result = Aura[GameAura.DebuffType] or false
                else
                  -- Check debuff for any aura
                  local GameDebuffTypes = GameAuras.DebuffTypes
                  local NumDebuffTypesCheck = #DebuffTypesCheck
                  Result = false

                  for DebuffIndex = 1, NumDebuffTypesCheck do
                    local DebuffTypeCheck = DebuffTypesCheck[DebuffIndex]

                    -- Check to see if debuff type option is selected
                    if Aura[DebuffTypeCheck] and GameDebuffTypes[DebuffTypeCheck] then
                      Result = true
                      break
                    end
                  end
                end
              end
            end
          end
          -- Invert result
          if Aura.Inverse then
            Result = not Result
          end
        end
        if not All then
          -- Stop checking if one aura is true
          if Result then
            BreakLoop = true
            break
          end
        -- Stop checking if one aura if false
        elseif not Result then
          BreakLoop = true
          break
        end
      end
      if BreakLoop then
        break
      end
    end
    ActiveTrigger.ActiveAuras = Result
  end
end

-------------------------------------------------------------------------------
-- CheckTriggersTalents
--
-- Sunfunction of CheckTriggers()
--
-- Match the talents
-------------------------------------------------------------------------------
local function CheckTriggersTalents(Trigger, GameTalents)
  local Talents = Trigger.Talents
  local All = Talents.All
  local Result = true

  for TalentIndex = 1, #Talents do
    local Talent = Talents[TalentIndex]
    local SpellID = Talent.SpellID
    local Match = Talent.Match
    local GameTalent = GameTalents[SpellID]

    if type(SpellID) == 'number' and SpellID > 0 and (Match and GameTalent or not Match and GameTalent == nil) then
      Result = true
    else
      Result = false
    end
    if not All then
      -- Stop checking if one talent is true
      if Result then
        break
      end
    -- Stop checking if one talent is false
    elseif not Result then
      break
    end
  end

  return Result
end

-------------------------------------------------------------------------------
-- CheckTriggers
--
-- Creates and checks triggers
--
-- Action       'default'  if the type ID is not found it'll set it the default
--                         ID that is found first
-------------------------------------------------------------------------------
function BarDB:CheckTriggers(Action)
  local UnitBarF = self.UnitBarF
  local BarType = self.BarType
  local Triggers = UnitBarF.UnitBar.Triggers
  local TriggerData = self.TriggerData
  local Groups = TriggerData.Groups
  local InputValueNamesDropdown = TriggerData.InputValueNamesDropdown
  local InputValueNames = TriggerData.InputValueNames
  local InputValueTypes = TriggerData.InputValueTypes
  local Units = ''
  local TrackTalents = false
  local TriggerIndex = 1
  local TriggersHasStances = next(DUB[BarType].Triggers.Default.ClassStances) ~= nil

  -- Undo triggers first
  UndoTriggers(self)

  local ActiveTriggers = {}
  TriggerData.ActiveTriggers = ActiveTriggers

  -- Reset Active
  local ActiveBoxesAll = TriggerData.ActiveBoxesAll
  local ActiveObjects = TriggerData.ActiveObjects

  for BoxNumber, ActiveObject in pairs(ActiveObjects) do
    ActiveObjects[BoxNumber] = {}
    if BoxNumber > 0 then
      ActiveBoxesAll[BoxNumber] = false
    end
  end

  -- Turn on TalentTracking for the talenttracking data
  Main:SetTalentTracker(UnitBarF, 'fn', function() end)
  local TalentTrackersData = Main.TalentTrackersData
  local GameTalents = TalentTrackersData.Active
  local GameTalentsSpellIDs = TalentTrackersData.SpellIDs

  while TriggerIndex <= #Triggers do
    local Trigger = Triggers[TriggerIndex]
    local GroupNumber = Trigger.GroupNumber
    local Group = Groups[GroupNumber]

    -- Group not found, so put it in group 1.
    if Group == nil then
      Trigger.Name = format('[From %s] %s', GroupNumber, Trigger.Name)

      GroupNumber = 1
      Trigger.GroupNumber = GroupNumber
      Group = Groups[GroupNumber]
    end

    local Objects = Group.Objects
    local ObjectTypeID = Trigger.ObjectTypeID

    -- set default
    if ObjectTypeID == '' then
      ObjectTypeID = Group.IndexObjectTypeID[1]
    end
    local ObjectType = strsplit(':', ObjectTypeID, 2)

    -- if not found then get the first Type that matches in
    -- list of objects
    if Objects[ObjectTypeID] == nil then
      local ObjectTypeTypeID = Group.ObjectTypeTypeID

      -- Find first object type in the objecttypeID list
      ObjectTypeID = ObjectTypeTypeID[ObjectType]
      if ObjectTypeID == nil then
        -- Convert between region and background types
        ObjectTypeID = ObjectTypeTypeID[ TriggerConvertRegionBackdrop[ObjectType] ]
      end
    end
    local Object = Objects[ObjectTypeID]

    if Action and Action == 'default' and Object == nil then
      ObjectTypeID = Group.IndexObjectTypeID[1]
      Object = Objects[ObjectTypeID]
      -- need to set pars to nil to force a default
      Trigger.Par1, Trigger.Par2, Trigger.Par3, Trigger.Par4 = nil, nil, nil, nil
    end

    -- if still not found then delete trigger
    if Object then
      -- Do display stuff

      Trigger.ObjectTypeID = ObjectTypeID
      ObjectType = strsplit(':', ObjectTypeID, 2)
      Trigger.ObjectType = ObjectType
      Trigger.BarFn = Object.Fn
      Trigger.CanAnimate = Object.CanAnimate or false

      local Disabled = Trigger.Disabled
      local Static = Trigger.Static
      local Talents = Trigger.Talents
      local Auras = Trigger.Auras
      local Conditions = Trigger.Conditions
      local TalentsDisabled = Talents.Disabled
      local ClassStances = Trigger.ClassStances

      -- Par Defaults
      if Trigger.Par1 == nil then
        local Par1, Par2, Par3, Par4 = Trigger.Par1, Trigger.Par2, Trigger.Par3, Trigger.Par4

        if ObjectType == OT.BackgroundBorder or ObjectType == OT.RegionBorder then
          Par1 = DefaultUB.DefaultBorderTexture
        elseif (ObjectType == OT.BackgroundBackground or ObjectType == OT.RegionBackground) then
          Par1 = DefaultUB.DefaultBgTexture
        elseif ObjectType == OT.BarTexture then
          Par1 = DefaultUB.DefaultStatusBarTexture
        elseif ObjectType == OT.TextureScale then
          Par1 = 1
        elseif ObjectType == OT.BarOffset then
          Par1, Par2, Par3, Par4 = 0, 0, 0, 0
        elseif strfind(ObjectType, 'color') then
          Par1, Par2, Par3, Par4 = 1, 1, 1, 1
        elseif ObjectType == OT.TextFontOffset then
          Par1, Par2 = 0, 0
        elseif ObjectType == OT.TextFontSize then
          Par1 = 0
        elseif ObjectType == OT.TextFontType then
          Par1 = DefaultUB.DefaultFontType
        elseif ObjectType == OT.TextFontStyle then
          Par1 = 'NONE'
        elseif ObjectType == OT.Sound then
          Par1 = DefaultUB.DefaultSound
          Par2 = DefaultUB.DefaultSoundChannel
        end
        Trigger.Par1, Trigger.Par2, Trigger.Par3, Trigger.Par4 = Par1, Par2, Par3, Par4
      end

      if strfind(ObjectType, 'color') then
        Trigger.ColorFn = TriggerColorFns[Trigger.ColorFnType]

        if Trigger.ColorUnit == '' then
          Trigger.ColorUnit = 'player'
        end
      else
        Trigger.ColorFn = nil
      end

      -- Sound
      if strfind(ObjectType, 'sound') then
        Trigger.OneTime = 0
      else
        Trigger.OneTime = false
      end

      -- Text
      if strfind(ObjectType, 'font') then
        Trigger.TextLine = Trigger.TextLine or 1
      else
        Trigger.TextLine = false
      end

      -- Conditions. Delete any conditions if the InputValueName is not found
      local ConditionIndex = 1

      while ConditionIndex <= #Conditions do
        local Condition = Conditions[ConditionIndex]
        local InputValueName = Condition.InputValueName

        -- Set default since ''
        if InputValueName == '' then
          Condition.InputValueName = InputValueNamesDropdown[1]

        elseif InputValueNames[InputValueName] == nil then
          tremove(Conditions, ConditionIndex)
        else
          ConditionIndex = ConditionIndex + 1
        end
      end

      for ConditionIndex = 1, #Conditions do
        local Condition = Conditions[ConditionIndex]
        local Operator = Condition.Operator
        local Value = Condition.Value
        local InputValueName = Condition.InputValueName
        local InputValueType = InputValueTypes[InputValueName]

        if InputValueTypesCheck[InputValueType] then
          if InputValueType ~= 'state' then
            -- string
            if InputValueType == 'text' then
              if Operator ~= '<>' and Operator ~= '=' then
                Condition.Operator = '='
              end
              Value = type(Value) ~= 'string' and '' or Value

            -- numbers
            elseif type(Value) ~= 'number' then
              Value = tonumber(Value) or 0
            end
          else
            -- boolean
            Condition.Operator = '='
            if type(Value) ~= 'boolean' then
              Value = true
            end
          end
        end
        Condition.InputValueName = InputValueName
        Condition.Value = Value
        Condition.OrderNumber = ConditionIndex
      end

      -- Auras
      for AuraIndex = 1, #Auras do
        local Aura = Auras[AuraIndex]
        local SpellID = Aura.SpellID
        local Stacks = Aura.Stacks
        local AuraUnits = Aura.Units

        if type(SpellID) ~= 'number' then
          Aura.SpellID = 0
        end
        if type(Stacks) ~= 'number' then
          Aura.Stacks = tonumber(Stacks) or 0
        end

        if not Auras.Disabled then
          for UnitIndex = 1, #AuraUnits do
            local AuraUnit = gsub( (AuraUnits[UnitIndex] or '') , '[%c%p%s]', '')

            -- Remove if blank or is just all numbers. Must start with a letter
            if AuraUnit == '' then
              tremove(AuraUnits, UnitIndex)
            else
              AuraUnits[UnitIndex] = AuraUnit

              -- Only add to Units if the trigger is not static and not disabled
              if not Disabled and not Static then
                Units = Units .. ' ' .. AuraUnit
              end
            end
          end
        end
        if #AuraUnits == 0 then
          AuraUnits[1] = 'player'
        end

        Aura.OrderNumber = AuraIndex
        Aura.Own = tonumber(Aura.Own) or 0
      end

      -- Talents
      for TalentIndex = 1, #Talents do
        local Talent = Talents[TalentIndex]
        local SpellID = Talent.SpellID

        -- If SpellID is a string, that means it was from a converted from an earlier version
        -- Try to convert to a spellID, if fail then skip incase its from a different class
        if type(SpellID) == 'string' then
          SpellID = GameTalentsSpellIDs[SpellID] or SpellID
        else
          SpellID = tonumber(Talent.SpellID) or 0
        end

        Talent.SpellID = SpellID
        Talent.OrderNumber = TalentIndex
      end

      if not Disabled and not Static and not TalentsDisabled and #Talents > 0 then
        TrackTalents = true
      end

      -- Update stance data
      Main:UpdatePlayerStances(BarType, ClassStances, true)  -- true for triggers
      if not TriggersHasStances then
        Trigger.StanceEnabled = false
      end

      Trigger.AurasOn      = not Auras.Disabled      and #Auras > 0
      Trigger.ConditionsOn = not Conditions.Disabled and #Conditions > 0

      Trigger.ActiveAuras = false

      if not Disabled then
        local ClassSpecs = Trigger.ClassSpecs
        Main:UpdateClassSpecs(BarType, ClassSpecs, true) -- true for triggers
        if Static or ( not Trigger.SpecEnabled or Main:CheckClassSpecs(BarType, ClassSpecs) ) and
                     ( TalentsDisabled or CheckTriggersTalents(Trigger, GameTalents)        ) and
                     ( not Trigger.StanceEnabled or Main:CheckPlayerStances(BarType, ClassStances) ) then
          ActiveTriggers[#ActiveTriggers + 1] = Trigger
        end
      end
      TriggerIndex = TriggerIndex + 1
    else
      -- Delete trigger
      tremove(Triggers, TriggerIndex)
    end
  end

  if TrackTalents then
    Main:SetTalentTracker(UnitBarF, 'fn', function()
                                            self:CheckTriggers()
                                            self:DoTriggers()
                                          end)
  else
    Main:SetTalentTracker(UnitBarF, 'off')
  end

  Units = strtrim(Units)
  if Units ~= '' then
    Main:SetAuraTracker(UnitBarF, 'fn', function()
                                          self:CheckTriggersAuras()
                                          self:DoTriggers()
                                        end)
    Main:SetAuraTracker(UnitBarF, 'units', Main:SplitString(' ', Units))
  else
    Main:SetAuraTracker(UnitBarF, 'off')
  end

  self:CheckTriggersAuras()
end

-------------------------------------------------------------------------------
-- EnableTriggers
--
-- Enables or disabled triggers
--
-- GroupInfo structure.          Contains info to build the trigger data
--
--   ValueNames[]                This contains the type and inputvalue name pairs
--     [1] = type                  type: See the top of this file for InputValue types
--     [2] = name                  The name of the input value
--
--   [1+] = [GroupIndex]         Table containing table name, box name, and objects info
--     [1] = Group Type            number   : Boxnumber of the box for the bar
--                                 'r'      : Region
--                                 'c'      : Custom: Can be on any box. Gets set thru SetTriggersGroup()
--                                 'a'      : Triggers will change ALL boxes
--                                 'aa'     : Triggers will only change active boxes
--                                 'ai'     : Triggers will only change inactive boxes
--     [2] = Group Name          string: Name of the group. Usually after a box in the bar or the bar its self
--     [3] = ObjectsInfo         Contains info about what is being changed
--       [1]  = Type               Type. Color, texture, text.  This is used to help build the option menus.
--       [2]  = ID                 Number: This is combined with Type to create a uniqie entry
--       [3]  = Text               String: This gets added to the existing menu item for this type
--       [4+] = TextureNumber      1 or more texture numbers. This is the actual texture that gets modified
-------------------------------------------------------------------------------
function BarDB:EnableTriggers(Enable, GroupsInfo)
  local Triggers = self.UnitBarF.UnitBar.Triggers
  local TriggerData = self.TriggerData

  if Enable then
    -- Check if triggers was reset thru reset options
    -- If old trigger data exists, an undo needs to be done first
    if TriggerData and Main.Reset and #Triggers == 0 then
      UndoTriggers(self)
      self.TriggerData = nil
      TriggerData = nil
    end

    if TriggerData == nil then
      TriggerData = {}
      local InputValueNames = {}
      local ValueNames = GroupsInfo.ValueNames
      local InputValueTypes = {}
      local InputValueNamesDropdown = {}
      local Groups = {}
      local GroupsDropdown = {}
      local NameToGroup = {}
      local ActiveObjects = {}
      local DropdownIndex = 1

      for BoxNumber = -1, self.NumBoxes do
        if BoxNumber ~= 0 then
          ActiveObjects[BoxNumber] = {}
        end
      end

      -- Input value names
      for ValueIndex = 1, #ValueNames, 2 do
        local InputValueName = ValueNames[ValueIndex + 1]
        local InputValueType = ValueNames[ValueIndex]

        if InputValueTypesCheck[InputValueType] == nil then
          assert(false, 'EnableTriggers - Invalid ValueName Type: ' .. InputValueType)
        end

        InputValueTypes[InputValueName] = InputValueType
        InputValueNames[InputValueName] = 1

        InputValueNamesDropdown[DropdownIndex] = InputValueName
        DropdownIndex = DropdownIndex + 1
      end
      TriggerData.ActiveTriggers = {}
      TriggerData.ActiveObjects = ActiveObjects
      TriggerData.ActiveBoxesAll = {}
      TriggerData.ActiveBoxesCustom = {}
      TriggerData.InputValueTypes = InputValueTypes
      TriggerData.InputValueNames = InputValueNames
      TriggerData.InputValueNamesDropdown = InputValueNamesDropdown
      TriggerData.InputValues = {}

      TriggerData.Groups = Groups
      TriggerData.GroupsDropdown = GroupsDropdown
      TriggerData.NameToGroup = NameToGroup

      -- do boxes, region, any etc
      for GroupIndex = 1, #GroupsInfo do
        local GroupInfo = GroupsInfo[GroupIndex]
        local Group = {}
        local BoxNumber = -1
        local GroupType = GroupInfo[1]
        local GroupName = GroupInfo[2]

        if type(GroupType) ~= 'number' and GroupType ~= 'r' and GroupType ~= 'c' and
           GroupType ~= 'a' and GroupType ~= 'aa' and GroupType ~= 'ai' then
          assert(false, 'EnableTriggers - Invalid GroupType: ' .. GroupType)
        end

        if type(GroupType) == 'number' then
          BoxNumber = GroupType
          GroupType = 'b'
        end

        Groups[GroupIndex] = Group
        Group.Name = GroupName
        Group.BoxNumber = BoxNumber
        Group.Type = GroupType
        GroupsDropdown[GroupIndex] = GroupName
        NameToGroup[GroupName] = Group

        -- Objects
        local ObjectTypeTypeID = {}
        local Objects = {}
        local ObjectsDropdown = {}
        local IndexObjectTypeID = {}

        Group.ObjectTypeTypeID = ObjectTypeTypeID
        Group.Objects = Objects
        Group.ObjectsDropdown = ObjectsDropdown
        Group.IndexObjectTypeID = IndexObjectTypeID

        local ObjectsInfo = GroupInfo[3]
        for ObjectsIndex = 1, #ObjectsInfo do
          local ObjectInfo = ObjectsInfo[ObjectsIndex]
          local Object = {}
          local ObjectType = ObjectInfo[1]
          local ObjectTypeID = format('%s:%s', ObjectType, ObjectInfo[2])
          local TexN = {}

          IndexObjectTypeID[ObjectsIndex] = ObjectTypeID
          Objects[ObjectTypeID] = Object
          if ObjectTypeTypeID[ObjectType] == nil then
            ObjectTypeTypeID[ObjectType] = ObjectTypeID
          end

          -- Set object name plus additional text to dropdown
          ObjectsDropdown[ObjectsIndex] = TriggerMenuItems[ObjectType] .. ObjectInfo[3]

          -- Get texture data
          for TextureIndex = 4, #ObjectInfo do
            TexN[TextureIndex - 3] = ObjectInfo[TextureIndex]
          end
          if #TexN > 0 then
            Object.TexN = TexN
          end
          Object.Fn = self[ TriggerFns[ObjectType] ]
          Object.CanAnimate = TriggerCanAnimate[ObjectType] or false
          Object.Index = ObjectsIndex
        end
      end
    end

    if self.TriggerData == nil or Main.ProfileChanged or Main.CopyPasted or Main.PlayerChanged then
      self.Triggers = Triggers
      self.TriggerData = TriggerData
      self:CheckTriggers()
    end
  elseif self.TriggerData then

    -- disable triggers
    UndoTriggers(self)

    local UnitBarF = self.UnitBarF
    Main:SetAuraTracker(UnitBarF, 'off')
    Main:SetTalentTracker(UnitBarF, 'off')

    self.TriggerData = nil
  end
end

-------------------------------------------------------------------------------
-- AppendTriggers
--
-- Adds triggers from another bar without overwriting the existing ones.
--
-- Source      string: Then this a bartype otherwise this contains the table to append
-------------------------------------------------------------------------------
function BarDB:AppendTriggers(SourceTriggers)
  if type(SourceTriggers) == 'string' then
    SourceTriggers = Main.UnitBars[SourceTriggers].Triggers
  end
  local Triggers = self.UnitBarF.UnitBar.Triggers

  for TriggerIndex = 1, #SourceTriggers do
    local Trigger = {}
    local SourceTrigger = SourceTriggers[TriggerIndex]

    -- Copy trigger
    Main:CopyTableValues(SourceTrigger, Trigger, true)

    -- Append trigger
    Triggers[#Triggers + 1] = Trigger
  end

  -- Cant do check triggers here
end

-------------------------------------------------------------------------------
-- DoTriggerConditions
--
-- Subfunction of DoTriggers()
--
-- Returns true or false
-------------------------------------------------------------------------------
local function DoTriggerConditions(TriggerData, Conditions)
  local InputValues = TriggerData.InputValues
  local InputValueTypes = TriggerData.InputValueTypes
  local All = Conditions.All
  local Result

  for ConditionIndex = 1, #Conditions do
    local Condition = Conditions[ConditionIndex]
    local InputValueName = Condition.InputValueName
    local InputValue = InputValues[InputValueName]

    -- InputValue can be nil if that particular value hasn't been set yet
    -- So skip if nil
    if InputValue then
      local Operator = Condition.Operator
      local Value = Condition.Value

      Result = false

      if InputValueTypes[InputValueName] == 'text' then
        if Operator == '='  and strfind(strlower(InputValue), strlower(Value), 1, true) or
           Operator == '<>' and strfind(strlower(InputValue), strlower(Value), 1, true) == nil then
          Result = true
        end
      elseif Operator == '<'  and InputValue <  Value or
             Operator == '>'  and InputValue >  Value or
             Operator == '<=' and InputValue <= Value or
             Operator == '>=' and InputValue >= Value or
             Operator == '='  and InputValue == Value or
             Operator == '<>' and InputValue ~= Value    then
        Result = true
      end
      if not All then
        -- Stop checking if one condition is true
        if Result then
          break
        end
      -- Stop checking if one condition is false
      elseif not Result then
        break
      end
    end
  end

  return Result
end

-------------------------------------------------------------------------------
-- DoTriggers
--
-- Executes triggers based on talents, auras, conditions, etc
-------------------------------------------------------------------------------
function BarDB:DoTriggers()
  local TriggerData = self.TriggerData
  local ActiveTriggers = TriggerData.ActiveTriggers
  local ActiveObjects = TriggerData.ActiveObjects
  local ActiveBoxesAll = TriggerData.ActiveBoxesAll
  local ActiveBoxesCustom = TriggerData.ActiveBoxesCustom
  local NumBoxes = self.NumBoxes
  local OTSound = OT.Sound

  local Groups = TriggerData.Groups

  for TriggerIndex = 1, #ActiveTriggers do
    local ActiveTrigger = ActiveTriggers[TriggerIndex]
    local Group = Groups[ActiveTrigger.GroupNumber]
    local Type = Group.Type
    local BoxNumber = Group.BoxNumber
    local ObjectTypeID = ActiveTrigger.ObjectTypeID

    -- Check active status
    local Active = ActiveTrigger.Static or
                   ( not ActiveTrigger.AurasOn       or ActiveTrigger.ActiveAuras   ) and
                   ( not ActiveTrigger.ConditionsOn  or DoTriggerConditions(TriggerData, ActiveTrigger.Conditions) )

    if not Active then
      if ActiveTrigger.OneTime then
        ActiveTrigger.OneTime = 0
      end
    end

    -- Custom group
    if Type == 'c' then
      local ActiveBoxes = ActiveBoxesCustom[Group]

      if ActiveBoxes then
        for Index = 1, #ActiveBoxes do
          local BoxNumber = ActiveBoxes[Index]

          if BoxNumber ~= -1 then
            ActiveObjects[BoxNumber][ObjectTypeID] = TriggerIndex
          end
        end
      end

    -- all
    elseif Type == 'a' or Type == 'aa' or Type == 'ai' then
      for BoxNumber = 1, NumBoxes do
        local ActiveBoxAll = ActiveBoxesAll[BoxNumber]

        if Active and
           ( Type == 'a' or
             Type == 'aa' and ActiveBoxAll or
             Type == 'ai' and not ActiveBoxAll ) then
          ActiveObjects[BoxNumber][ObjectTypeID] = TriggerIndex
        end
      end
    elseif Active then
      ActiveObjects[BoxNumber][ObjectTypeID] = TriggerIndex
    end
  end

  -- Do functions
  CalledByTrigger = true

  for BoxNumber = -1, NumBoxes do
    if BoxNumber ~= 0 then
      local ActiveObject = ActiveObjects[BoxNumber]

      for ObjectTypeID, TriggerIndex in pairs(ActiveObject) do
        if TriggerIndex == 0 then
          local ObjectType = strsplit(':', ObjectTypeID, 2)

          -- Set to -1 so it don't keep restoring until used again first
          ActiveObject[ObjectTypeID] = -1

          if ObjectType ~= OTSound then
            RestoreSettings(self, TriggerFns[ObjectType], BoxNumber)
          end

        elseif TriggerIndex > 0 then
          local ActiveTrigger = ActiveTriggers[TriggerIndex]
          local BarFn = ActiveTrigger.BarFn
          local OneTime = ActiveTrigger.OneTime

          ActiveObject[ObjectTypeID] = 0

          if not OneTime or OneTime == 0 then
            if OneTime then
              ActiveTrigger.OneTime = 1
            end

            AnimateSpeedTrigger = ActiveTrigger.CanAnimate and ActiveTrigger.Animate and ActiveTrigger.AnimateSpeed or nil

            local p1, p2, p3, p4 = ActiveTrigger.Par1, ActiveTrigger.Par2, ActiveTrigger.Par3, ActiveTrigger.Par4
            local ColorFn = ActiveTrigger.ColorFn
            local TextLine = ActiveTrigger.TextLine

            -- Do color
            if ColorFn then
              -- use nil as first par to fill in 'self'
              p1, p2, p3, p4 = ColorFn(nil, ActiveTrigger.ColorUnit, nil, nil, nil, p1, p2, p3, p4)
            end

            if TextLine then
              -- Do all text lines
              if TextLine == 0 then
                for TextLineIndex = 1, MaxTextLines do
                  BarFn(self, BoxNumber, TextLineIndex, p1, p2, p3, p4)
                end
              else
                -- Single text line
                BarFn(self, BoxNumber, TextLine, p1, p2, p3, p4)
              end
            else
              local TexN = Groups[ActiveTrigger.GroupNumber].Objects[ObjectTypeID].TexN

              -- Do textures
              if TexN then
                for Index = 1, #TexN do
                  BarFn(self, BoxNumber, TexN[Index], p1, p2, p3, p4)
                end
              else
                -- Do sound or color
                BarFn(self, p1, p2, p3, p4)
              end
            end

            AnimateSpeedTrigger = nil
          end
        end
      end
    end
  end
  CalledByTrigger = false
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Trigger Convert functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- ConvertTriggers
--
-- Converts triggers from version 6.60
--
-- Used by ConvertCustom() from Main.lua
--
-- Notes: No need to delete old keys since the cleaner will take care of it
-------------------------------------------------------------------------------
function GUB.Bar:ConvertTriggers(BarType, Triggers)
  local TriggerIsAll = Trigger660IsAll[BarType]
  local TriggerRegion = Trigger660Region[BarType]
  local TriggerValueType = Trigger660ValueType[BarType]

  for TriggerIndex = 1, #Triggers do
    local Trigger = Triggers[TriggerIndex]
    local Type = Trigger.Type
    local ObjectType = Trigger660TypeObjectType[Type] -- Convert old to new
    local GroupNumber = Trigger.GroupNumber
    local ValueTypeID = Trigger.ValueTypeID
    local Pars = Trigger.Pars
    local Conditions = {}
    local Talents = {}
    local Auras = {}

    -- If no object type then try to convert to a specified object type id
    if ObjectType == nil then
      Trigger.ObjectTypeID = Trigger660TypeOldTypeID[Type]
    else
      -- Fake object type ID and let CheckTriggers parse it out
      Trigger.ObjectType = ObjectType
      Trigger.ObjectTypeID = ObjectType .. ':0'
    end

    -- Convert group numbers
    -- Check for All and Region
    local GroupNumberAll = TriggerIsAll and TriggerIsAll[GroupNumber]
    if GroupNumberAll then
      if ValueTypeID == 'state' then
        if Trigger.State then
          GroupNumber = GroupNumberAll + 1
        else
          GroupNumber = GroupNumberAll + 2
        end
      end
    else
      GroupNumber = TriggerRegion and TriggerRegion[GroupNumber] or GroupNumber
    end

    -- Convert conditions and talents
    if ValueTypeID ~= 'auras' then
      -- Capitalize the first character in each word for InputValueName
      local InputValueName = gsub(' ' .. Trigger.ValueType, '%W%l', strupper):sub(2)
      local ConditionsOld = Trigger.Conditions
      local ConditionsOldAll = ConditionsOld.All

      InputValueName = gsub(InputValueName, 'Percent', 'percent')
      InputValueName = TriggerValueType and TriggerValueType[InputValueName] or InputValueName
      Conditions.All = ConditionsOldAll
      Conditions.Disabled = false
      Talents.All = ConditionsOldAll

      for ConditionIndex = 1, #ConditionsOld do
        local ConditionOld = ConditionsOld[ConditionIndex]
        local Operator = ConditionOld.Operator

        -- Check for talents
        if Operator == 'T=' or Operator == 'T<>' or
           Operator == 'P=' or Operator == 'P<>'    then
          local Talent = {}

          Talent.SpellID = ConditionOld.Value
          Talent.Match = Operator == 'T=' or Operator == 'P=' or false
          Talent.IsPvP = Operator == 'P=' or Operator == 'P<>' or false
          Talent.Minimized = false
          Talents[#Talents + 1] = Talent
        else
          -- normal condition
          local Condition = {}
          local Value

          Condition.Operator = ConditionOld.Operator
          if ValueTypeID == 'state' then
            Value = Trigger.State
          else
            Value = ConditionOld.Value
          end
          Condition.Value = Value

          -- Do inputvaluename for groups
          if strfind(InputValueName, '%s', 1, true) then
            Condition.InputValueName = format(InputValueName, GroupNumber)
          else
            Condition.InputValueName = InputValueName
          end
          Conditions[#Conditions + 1] = Condition
        end
      end

    elseif ValueTypeID == 'auras' then
      local AurasOld = Trigger.Auras
      Auras.All = Trigger.AuraOperator == 'and' or false

      for SpellID, AuraOld in pairs(AurasOld) do
        local Aura = {}

        Aura.SpellID = SpellID
        Aura.Units = {AuraOld.Unit}
        Aura.StackOperator = AuraOld.StackOperator
        Aura.Stacks = AuraOld.Stacks
        Aura.Own = AuraOld.Own and 1 or 0
        Aura.Inverse = AuraOld.NotActive

        Auras[#Auras + 1] = Aura
      end
    end

    Trigger.Conditions = #Conditions > 0 and Conditions or nil
    Trigger.Talents = #Talents > 0 and Talents or nil
    Trigger.Auras = #Auras > 0 and Auras or nil

    -- Convert disabled
    Trigger.Disabled = not Trigger.Enabled
    Trigger.GroupNumber = GroupNumber

    Trigger.Par1, Trigger.Par2, Trigger.Par3, Trigger.Par4 = Pars[1], Pars[2], Pars[3], Pars[4]
  end
end

GUB.Bar.GetRect = function(self, ...) return GetRect(...) end
