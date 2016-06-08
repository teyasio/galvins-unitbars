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
local TT = GUB.DefaultUB.TriggerTypes
local TexturePath = GUB.DefaultUB.TexturePath

local LSM = Main.LSM

-- localize some globals.
local _, _G =
      _, _G
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring =
      strfind, strsplit, strsub, strtrim, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber, tostring
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe, tremove, tinsert
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip, PlaySoundFile
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, PetHasActionBar, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, PetHasActionBar, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapDenied =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitAura, UnitPowerMax, UnitIsTapDenied
local UnitName, UnitReaction, UnitLevel, UnitEffectiveLevel, UnitGetIncomingHeals, UnitCanAttack, UnitPlayerControlled, UnitIsPVP =
      UnitName, UnitReaction, UnitLevel, UnitEffectiveLevel, UnitGetIncomingHeals, UnitCanAttack, UnitPlayerControlled, UnitIsPVP
local GetRuneCooldown, GetSpellInfo, GetSpellBookItemInfo, PlaySound, message, UnitCastingInfo, GetSpellPowerCost =
      GetRuneCooldown, GetSpellInfo, GetSpellBookItemInfo, PlaySound, message, UnitCastingInfo, GetSpellPowerCost
local GetShapeshiftFormID, GetSpecialization, GetInventoryItemID, GetRealmName =
      GetShapeshiftFormID, GetSpecialization, GetInventoryItemID, GetRealmName
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, C_TimerAfter, UIParent =
      C_PetBattles, C_Timer.After, UIParent

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
--     Colors                        Saved color used by SetColor() and GetColor()
--     Hidden                        If true the region is hidden.
--     Anchor                        Reference to the UnitBarF.Anchor.  Used for Mouse interaction.
--     BarDB                         BarDB.  Reference to the Bar database.  Used for mouse interaction
--     Name                          Name for the tooltip.  Used for tooltip, dragging.
--     Backdrop                      Table containing the backdrop. Set by GetBackDrop()
--
--   NumBoxes                        Total number of boxes the bar was created with.
--   TopFrame                        Contains a reference to the frame that has the highest frame level.
--   Rotation                        Rotation in degrees for the bar.
--   Slope                           Adjusts the horizontal or vertical slope of a bar.
--   Swap                            Boxes can be swapped with eachother by dragging one on top of the other.
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
--         SubTexture                Texture that is a child of Texture[].
--
--   Settings                        Used by triggers to keep track of the original settings for each frame/texture.
--   Groups                          Used by triggers.  Used to keep track of triggers.
--
--   AGroups                         Used by animation to keep track of animation groups. Created by GetAnimation() in SetAnimationBar()
--   AGroup                          Used to play animation when showing or hiding the bar. Created by GetAnimation() in SetAnimationBar()
--
--   IsDisplayWaiting                Used by Display() and DisplayWaiting().  If Display() was called when the bar
--                                   was hidden.  It will not display, instead it will set this flag to true.
--                                   Then you call DisplayWaiting() only works once unless the bar is still invisible.
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
--   Backdrop                        Table containing the backdrop.
--
-- TextureFrame data structure
--
--   Hidden                          If true then the textureframe is hidden.
--   Textures[]                      Textures contained in TextureFrame.
--   Colors                          Saved color used by SetColor() and GetColor()
--   FontTime                        Used by FontSetValueTime()
--   Anchor                          Reference to the UnitBarF.Anchor.  Used for tooltip, dragging.
--   BarDB                           BarDB.  Reference to the Bar database.  Used for tooltip, dragging.
--   BF                              Reference to boxframe.  Used for tooltip, dragging.
--   BorderFrame                     Contains the backdrop and allows the textureframe to be sized without effecting box size.
--     Backdrop                      Table containing the backdrop.
--
-- Texture data structure            A texture is actually a frame.  I call it Texture so its not confused with
--                                   TextureFrame.
--
--   Type                            Either 'statusbar' or 'texture'
--   SubFrame                        Child of Texture. Holds the StatusBar or Frame containing the actual texture.
--   Width, Height                   Width and height of the texture.
--   CurrentTexture                  Contains the current texture name.  This is to prevent the texture from getting
--                                   set to the same texture.  Which would cause a graphical glitch.  Used by SetTexture()
--   Hidden                          If true then the statusbar/texture is hidden.
--   ShowHideFn                      This function will get called after calling SetHiddenTexture().  If animation is set then
--                                   the function will get called after the animation has ended.  Otherwise it happens instantly.
--   RotateTexture                   If true then the texture is rotated 90 degrees.
--   ReverseFill                     If true then the texture will fill in the opposite direction.
--   FillDirection                   Can be 'HORIZONTAL' or 'VERTICAL'.
--   Value                           Current value, work around for padding function dealing with statusbars.
--                                   Also used by SetFill functions.
--   SliderSize                      If not nill then the texture is being used as a slider.
--   Speed                           Like duration except its speed.  So if this was 10secs.  Then it would be 10secs to go from 0 to 1
--                                   or 5secs from 0 to 0.5 or 0.25 to 0.75.
--                                   Used by SetFillSpeedTexture() and SetFillTexture()
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
--
--   Backdrop                        Table containing the backdrop.  Created by GetBackdrop()
--   AGroup                          Contains the animation to play when showing or hiding a texture.  Created by GetAnimation() in SetAnimationTexture()
--
--  Spark data structure
--    ParentFrame                    Contains a reference to Texture.
--
--  Upvalues                         Used by bars.lua
--
--    RotationPoint                  Used by Display() to rotate the bar.
--    BoxFrames                      Used by NextBox() for iteration.
--    DoOptionData                   Resusable table for passing back information. Used by DoOption().
--
--  RotationPoint data structure
--
--  [Rotation]                       from 45 to 360.  Determins which direction to go in.
--    x, y                           Determins direction by using negative or positive values.
--                                   x or y will be 0 if there is no direction to go in.
--                                   For example x = 1 y = 0 means that there is no up/down just
--                                   horizontal.
--  SIDE or CORNER                   Is the alignment for the boxes.  Either they're attached by their
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
--        TextureFrame               TextureFrame.
--          BorderFrame              Border and also allows the textureFrame to be larger without effecting Boxsize.
--            Texture (frame)        Container for SubFrame and SubTexture.
--              PaddingFrame         Used by SetPaddingTexture()
--                SubFrame           A frame that holds the texture or statusbar
--                  SubTexture       Statusbar texture or texture.
--
-- NOTES:   When clearing all points on a frame.  Then do a SetPoint(Point, nil, Point)
--          Will cause GetLeft() etc to return a bad value.  But if you pass the frame
--          instead of nil you'll get a good values.
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
-- When you call DoOption() with a table name and key name the following can happen:
--
-- TableName is nil   - Then will match any SO TableName.
-- KeyName is nil     - Then will match any SO KeyName.
--
--   Each time an SO TableName is found.  Then the SO TableName has to be found in the
--   default unitbar data first then its checked to see if its in the UnitBar data second.
--   Each time an SO KeyName is found.  Then it has to match exactly to a key in the
--   unitbar data.
--
-- TableName is not nil - Then can partially match SO TableName.
-- KeyName is not nil   - Then has to exact match SO KeyName.
--                        If its '_' then its a empty virtual key name and will match any SO KeyName.
--                        Empty virtual key names dont get searched in the unitbar data.
--
-- After TableName and KeyName are found in the SO data.  Then the TableName is searched in the default UnitBarData
-- for the current BarType.  This can partially match.  After that it takes the full name of the table
-- found in the default unitbar.  And looks for it in the unitbar profile.  If found then then
-- the KeyName has to be an exact match to UnitBar[TableName][KeyName].  Unless KeyName is virtual.

-- Virtual Key Name.
--   A virtual key starts with an underscore.  It still follows the matching rules of a normal
--   key except it doesn't get searched in the UnitBar data.
--
-- Each time DoOption matches data from SO(). The following parametrs are passed back.
--
--   v:   This equals UnitBars[BarType][TableName][KeyName].
--        If the KeyName is virtual then this will equal UnitBars[BarType][TableName].
--   UB:  This equals the unitbar table UnitBars[BarType].
--   OD:  Table that contains the following:
--           TableName   The name of the table found in the unitbar data.
--           KeyName     Name of the key passed to SO()
--
--           If the KeyName is a table that contains 'All'.  Then its considered
--           a color all table.  The following is returned in interation till
--           the end of table is reached.
--             Index       The current element in the color all table.
--             r, g, b, a  The red, green, blue, and alpha colors KeyName[Index]
--
--           p1..pN.   Paramater data passed from SetOptionData.  See below for details.
--
-- If there was a SetOptionData() and the TableName found in SO data, default unitbar data, and unitbardata.
-- If the tablename matches exactly to what was passed from SetOptionData.  Then p1..pN get added to OD.
--
--
-- Options Data structure
-- Options[]                   Array containing all the options.
--   TableName                 string: TableName this is looked up in DoOption()
--   KeyNames[]                Array containing a list of KeyName and Functions.
--     Name                    string: Keyname that is looked up in DoOption()
--     Fn                      Function to call after searching for TableName and Name
--
-- OptionsData[TableName]      Table containing additional data that can be used with DoOption()
--   p1..pN                    Series of keys that go in p1, p2, p3, etc.  These contain
--                             the paramaters passed from SetOptionData()
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

-------------------------------------------------------------------------------
-- Triggers
--
-- TypeIDfn                        Table of function names. Converts a type ID to a function name.
--                                 If the boxnumber is nil then Region is appended to the function name.
-- TypeIDGetfn                     Table of get functions.  Converts a get function type id to a function.
--
-- TypeIDCanAnimate                Table containing which TypeIDs support animation.
--
-- CalledByTrigger                 true or false. if true then the function was called out side of the trigger system.
-- AnimateTimeTrigger              if not nil then the trigger is animated.  This contains the time in seconds for the animation.
--
-- Settings data structure.
-- Settings[Bar function name]     Hash table using the function name that it was called by to store.
--                                 Used by SaveSettings() and RestoreSettings().
--   Setting[ID]                   Array using an ID to store the paramaters under.
--                                 ID is two numbers combined into one.
--     Par[]                       Array containing the paramaters for the settings.
--
-- Groups structure.

-- Groups
--   Triggers                               Reference to triggers stored in the profile.
--   SortedTriggers                         Reference to triggers that are sorted and enabled only.
--   AuraTriggers                           Reference to triggers that are auras and enabled only.
--   LastValues[Object]                     Hash table. Uses Object = Objects[TypeIndex] as the index.
--
--   VirtualGroupList[VirtualGroupNumber]   hash table of virtual groups for any group thats using a box number.
--                                          This is nil if there's no virtual groups.
--                                          This only contains data if there was a virtual group defined.
--     [GroupNumber]                        Contains the virtual group based on each virtual group.
--        Hidden                            True or false.  If true the virtual group is hidden, otherwise visible.
--        BoxNumber                         Boxnumber that the virtual group is using.
--        Objects[TypeIndex]                Objects copied from Groups[VirtualGroupNumber]
--          Group                           Points back to [GroupNumber]
--          Virtual                         Number.  Tag so that UndoTriggers() knows its a virtual object.
--
-- Groups[GroupNumber]
--   Name                          Name of the group.
--   Hidden                        True or false. If true the group is hidden, otherwise visible. Used by virtual triggers.
--   VirtualGroupNumber            If not 0 then this group has a virtual trigger in its place.  The number is the virtual trigger group.
--   GroupType                     Group type
--                                 'b' for boxes.
--                                 'a' for all. Can match any group that has a numerical boxnumber.  Also will match virtual groups.
--                                 'r' for region.  Group will not use boxes.
--                                 'v' for virtual.  A virtual group has to be shown with HideVirtualGroupTriggers() first.
--                                                   Once that is done then the virtual group works like a normal group.
--   BoxNumber                     Box number of the bar or type.  Either > 0 for boxes or -1 if not.
--
--   TriggersInGroup               Contains the amount of triggers in the group.
--   ValueTypeIDs[]                Array of the value type IDs. Has reverse lookup.
--   ValueTypes[]                  Array of names for the value type IDs. Name can be anything. Appears in option menus.
--   RValueTypes[]                 Reverse lookup of ValueTypes[].  Hash table is in lowercase.
--   TypeIDs[]                     Array The ID of Type. Has reverse lookup.
--   Types[]                       Array Name of Type.  Name can be anything. Appears in option menus.
--   RTypes[]                      Reverse lookup of Types[]. Hash table is in lowercase.
--
--   Objects[TypeIndex]            TypeIndex comes from TypeID and Type
--     OneTime[Trigger]            Hash table based off trigger, aura trigger, and static trigger for index.
--                                 If true then the object executed once, otherwise false for haven't executed yet
--     CanAnimate                  true or false. If true then the object can use animation.
--     Group                       Parent reference to Groups[GroupNumber]
--     TexN[]                      Array of texture number or texture frame number.
--                                 If nil then the object doesn't use textures.
--     Function                    Function to call based on TypeIndex.
--     FunctionName                Name of Function.
--     Restore                     If true and theres no active triggers using this object.  Then it'll restore to its original state.
--                                 Otherwise false.
--
--     GetFnTypeIDs[]              Array that contains the IDs of each function type. Has reverse lookup.
--     GetFnTypes[]                Array that contains the name of each function type.  Name can be anything. Appears in option menus.
--     GetFn[GetFnTypeID]          Returns the get function based on Get function type ID.
--                                 NOTE: These 3 tables will not exist if there is no get function.
--
--     ------------------------    Values below here are added/modified after.
--     Trigger                     = false no trigger using this object.  Otherwise contains a reference to the trigger.
--     AuraTrigger                 = false no aura trigger using this object. Otherwise contains a reference to the aura trigger.
--     StaticTrigger               Triger is static. Otherwise nil.  Reference to trigger using this as static.
--
--
-- Trigger structure.
--
--   HideTabs                      true or false.  Used by options to hide empty tabs.
--   MenuSync                      true or false.  If true all triggers use ActionSync instead of Action
--   ActionSync                    Same table as Action.  Except this is used when MenuSync is true
--
-- Triggers[]                      Non sequencial array containing the triggers.
--   Enabled                       true or false.  If enabled then trigger works.
--   Static                        true or false.  If true trigger is always on, otherwise false.
--   GroupNumber                   Number to assign 1 or more triggers under. Group numbers must be contiguous.
--
--   HideAuras                     True or false.  if true auras are hidden in options.
--   Name                          Name of the trigger in options.
--
--   ValueTypeID                   'state'     Trigger can support state
--                                 'whole'     Trigger can support whole numbers (integers).
--                                 'percent'   Trigger can support percentages.
--                                 'auras'     Trigger can support a buff or debuff.
--
--   ValueType                     Discribes what the value type is in english.
--
--   TypeID                        Defines what type of barfunction. See DefaultUB.lua
--
--   Type                          Name that discribes the type that will appear in option menus
--
--   GetFnTypeID                   Indentifier for the type of GetFunction. 'none' if no function is specified.
--
--   Pars[1 to 4]                  Array containing elements passed to the SetFunction.
--   GetPars[1 to 4]               Array containing elements passed to the GetFunction.
--
--   CanAnimate                    true or false.  If true then the trigger can animate.
--   Animate                       true or false. if true then the trigger will animate
--   AnimateTime                   Time in seconds to play animation.
--
--   AuraOperator                  and' or 'or'. Used by auras only.
--   State                         True or False. Used when ValueTypeID = 'state'
--                                   If true then a trigger is the current state.
--                                   If false then its not in that state.
--
--   Conditions.All                True or False.  If true then all conditions have to be true, otherwise just one.
--   Conditions[]                  Contains one or more conditions. Not used by Aura or Static.
--     OrderNumber                 Used by options. This is updated in CheckTriggers()
--     Operator                    can be '<', '>', '<=', '>=', '==', '<>'
--     Value                       Value to trigger off of. Default to 1 if using auras.
--
--   Auras[SpellID]
--     Unit                        Unit that the aura is being searched.
--     StackOperator               Operator to be compared based on stacks for the aura.
--     Stacks                      Number of stacks compare with StackOperator.
--     Own                         true or false.  If true then the aura was created by you.
--
--   -----------------     Values below this line are always created/modified during CheckTriggers() or Options.
--   Action[MenuButton]            Contains the currently active menu button.
--     0                           Menu is closed
--     1                           Menu is opened
--   OrderNumber                   Used by options
--   Index                         Current position in the Triggers array.
--   OneTime                       Tag. if not nil then the trigger only executes once, then has to reset. Otherwise can run many times.
--   TypeIndex                     Based on TypeID and Type.
--   GroupNumbers                  Array of group numbers that box number of zero would match. Otherwise nil
--   Virtual                       true or false.  If true trigger belongs to a virtual group, otherwise normal.
--   TextMultiLine                 true or false. If boolean then trigger has multi line or not.  If nil then the trigger is not using text.
--   TextLine                      0 for all text lines or contains the current text line. If nil then the trigger is not using text.
--   Select                        true or false. Only one trigger per group can be selected.
--   OffsetAll                     true or false. Used for bar offset size.  By options.
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
--   GroupType                 string. Type of group:
--                               'Parent'     This is created for the the bar when hiding or showing.
--                               'Children'   This is created for any textures or frame the bar uses.
--   Type                      string.  Type of animation to play can be 'scale' or 'alpha'.
--   StopPlayingFn             Call back function.  This gets called when ever StopPlaying() is called
--
--   -----------------------   These keys are only used for alpha and scale, otherwise nil
--
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
local Args = {}
local BarTextData = {}

local DoOptionData = {}
local VirtualFrameLevels = nil
local CalledByTrigger = false
local AnimateTimeTrigger = nil
local MaxTextLines = 4

local BoxFrames = nil
local NextBoxFrame = 0
local LastBox = true

local TextureSpark = [[Interface\CastingBar\UI-CastingBar-Spark]]
local TextureSparkSize = 32

local SettingID = '%s:%s'
local RegionTrigger = -1

-- Constants used in NumberToDigitGroups
local Thousands = strmatch(format('%.1f', 1/5), '([^0-9])') == '.' and ',' or '.'
local BillionFormat = '%s%d' .. Thousands .. '%03d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local MillionFormat = '%s%d' .. Thousands .. '%03d' .. Thousands .. '%03d'
local ThousandFormat = '%s%d' .. Thousands ..'%03d'

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

local TypeIDfn = {
  [TT.TypeID_BackgroundBorder]      = 'SetBackdropBorder',
  [TT.TypeID_BackgroundBorderColor] = 'SetBackdropBorderColor',
  [TT.TypeID_BackgroundBackground]  = 'SetBackdrop',
  [TT.TypeID_BackgroundColor]       = 'SetBackdropColor',
  [TT.TypeID_BarTexture]            = 'SetTexture',
  [TT.TypeID_BarColor]              = 'SetColorTexture',
  [TT.TypeID_TextureScale]          = 'SetScaleTexture',
  [TT.TypeID_BarOffset]             = 'SetOffsetTextureFrame',
  [TT.TypeID_TextFontColor]         = 'SetColorFont',
  [TT.TypeID_TextFontOffset]        = 'SetOffsetFont',
  [TT.TypeID_TextFontSize]          = 'SetSizeFont',
  [TT.TypeID_TextFontType]          = 'SetTypeFont',
  [TT.TypeID_TextFontStyle]         = 'SetStyleFont',
  [TT.TypeID_Sound]                 = 'PlaySound',
}

-- For animation functions
local TypeIDCanAnimate = {
  [TT.TypeID_TextFontOffset]        = true,
  [TT.TypeID_TextFontSize]          = true,
}

local TypeIDGetfn = {
  [TT.TypeID_ClassColor]  = Main.GetClassColor,
  [TT.TypeID_PowerColor]  = Main.GetPowerColor,
  [TT.TypeID_CombatColor] = Main.GetCombatColor,
  [TT.TypeID_TaggedColor] = Main.GetTaggedColor,
}

local AnimationType = {
  alpha = 'Alpha',
  scale = 'Scale',
  move = 'Translation',
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
  unitlevel = '%s',
  scaledlevel = '%s',
  unitlevelscaled = '%s',
  timeSS = '%d',
  timeSS_H = '%.1f',
  timeSS_HH = '%.2f',
}

local SetValueParSize = {
  level = 3
}

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
-- Gets a frame level from an existing virtual frame level or a new frame level.
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
  return 1, 1, 1, 1
end

-------------------------------------------------------------------------------
-- SaveSettings
--
-- Saves parameters from set a set function. Used for triggers.
--
-- Usage:    SaveSettings(BarDB, FunctionName, BoxNumber, TexN, ...)
--           SaveSettings(BarDB, FunctionName, nil, nil, ...)
--
-- BarDB            Contains the settings.
-- FunctionName     Name of function.
-- BoxNumber        If 0 then settings are saved under all boxes. Otherwise > 0.
-- TexN             Texture number or texture frame number or text line.
-- ...              Paramater data to save.
--
-- This only saves if the set function wasn't called by a trigger.
--
-- NOTE ****** If the ID formula is changed make sure to change the 1809 constant
--             in RestoreSettings.
-------------------------------------------------------------------------------
local function SaveSettings(BarDB, FunctionName, BoxNumber, TexN, ...)
  if not CalledByTrigger then
    local Settings = BarDB.Settings

    if Settings == nil then
      Settings = {}
      BarDB.Settings = Settings
    end
    local Setting = Settings[FunctionName]

    if Setting == nil then
      Setting = {}
      Settings[FunctionName] = Setting
    end

    if BoxNumber == nil and TexN == nil then
      BoxNumber = -1
      TexN = -1
    end

    local BoxNumberStart = BoxNumber
    local NumBoxes = BoxNumber

    -- loop all boxes if box number is zero.
    if BoxNumber == 0 then
      BoxNumberStart = 1
      NumBoxes = BarDB.NumBoxes
    end

    for BoxNumber = BoxNumberStart, NumBoxes do
      -- Should never have to use anything even close to 190 or -10.
      local ID = (BoxNumber + 10) * 200 + TexN + 10
      local Par = Setting[ID]

      if Par == nil then
        Setting[ID] = {...}
      else
        for Index = 1, select('#', ...) do
          Par[Index] = select(Index, ...)
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
-- Usage:    RestoreSettings(BarDB, FunctionName, BoxNumber, TexN)
--           RestoreSettings(BarDB, FunctionName, BoxNumber)
--           RestoreSettings(BarDB, FunctionName)
--
-- BarDB          Contains the settings.
-- FunctionName   Function to call. Must exist in settings.
-- BoxNumber      Box to restore in the bar. If nil or can specify -1 for nil. Then TexN is ignored. Cant use 0.
-- TexN           Texture number or texture frame number or text line. If nil then matches all textures
--                under BoxNumber.
-------------------------------------------------------------------------------
local function RestoreSettings(BarDB, FunctionName, BoxNumber, TexN)
  local Settings = BarDB.Settings

  if Settings then
    local Setting = Settings[FunctionName]

    if Setting then
      local Fn = BarDB[FunctionName]

      if Fn then
        if BoxNumber == nil or BoxNumber == -1 then

          -- If ID formula is changed then 1809 (-1, -1) will be wrong.
          Fn(BarDB, unpack(Setting[1809]))

        elseif TexN ~= nil then
          Fn(BarDB, BoxNumber, TexN, unpack(Setting[ (BoxNumber + 10) * 200 + TexN + 10 ]) )

        else
          for ID, Par in pairs(Setting) do
            local BN = floor(ID / 200) - 10
            local TN = ID % 200 - 10

            if BoxNumber == BN then
              Fn(BarDB, BN, TN, unpack(Par))
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
--  Backdrop   Reference to backdrop saved to Object.
--             If object already has a backdrop it returns that one instead.
-------------------------------------------------------------------------------
local function GetBackdrop(Object)
  local Backdrop = Object.Backdrop

  if Backdrop == nil then
    Backdrop = {}

    Main:CopyTableValues(DefaultBackdrop, Backdrop, true)
    Object.Backdrop = Backdrop
  end

  return Backdrop
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
--
-- returns:
--   Left     < 0 then outside the parent frame.
--   Top      > 0 then outside the parent frame.
--   width    Total width that covers the child frames.
--   height   Total height that covers the child drames.
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

    if not Frame.Hidden then
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
    local UB = BarDB.Anchor.UnitBar
    local AnchorPoint = AnchorPointWord[UB.Other.AnchorPoint]
    local BarX, BarY = floor(UB.x + 0.5), floor(UB.y + 0.5)
    local BoxX, BoxY = 0, 0

    if Frame.BF then
      local BF = Frame.BF
      BoxX, BoxY = GetRect(BF)
      BoxX, BoxY = floor(BoxX + 0.5), floor(BoxY + 0.5)

      return format('Bar - %s (%d, %d)  Box (%d, %d)', AnchorPoint, BarX, BarY, BoxX, BoxY)
    else
      return format('Bar - %s (%d, %d)', AnchorPoint, BarX, BarY)
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
-- Animation functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-------------------------------------------------------------------------------
-- GetAnimation
--
-- Get an animation of type for an object
--
-- Usage: AGroup = GetAnimation(BarDB, Object, GroupType, Type)
--
-- Object      Frame or Texture
-- GroupType   'parent' or 'children'
-- Type        'alpha', 'scale', or 'move'
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
    local Animation = nil
    local OnFrame = nil

    if GroupType == 'parent' then
      AGroup = CreateFrame('Frame'):CreateAnimationGroup()
      if Object.IsAnchor then
        OnFrame = Object.AnchorPointFrame
      else
        OnFrame = Object
      end
    else
      AGroup = Object:CreateAnimationGroup()
    end

    -- Uppercase the first letter in Type
    local Animation = AGroup:CreateAnimation(AnimationType[Type])
    Animation:SetOrder(1)

    AGroup.Animation = Animation

    AGroup.DurationIn = 0
    AGroup.DurationOut = 0
    AGroup.GroupType = GroupType
    AGroup.Type = Type
    AGroup.StopPlayingFn = nil

    AGroup.Object = Object
    AGroup.OnFrame = OnFrame
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
-- NOTES:  If GroupType is 'all' then all animation is stopped
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
-- StopAnimation (called direct or by OnFinish
--
-- Stops an animation and restores the object.
--
-- AGroup             Animation group
-- ReverseAnimation   If true just stops playing.
--
-- NOTES: Only alpha and scale support the call back AGroup.Fn
--        This functions returns the current x, y of a Move animation.
-------------------------------------------------------------------------------
local function StopAnimation(AGroup, ReverseAnimation)
  local Type = AGroup.Type

  ReverseAnimation = ReverseAnimation or false
  AGroup:SetScript('OnFinished', nil)

  if Type ~= 'move' then
    AGroup:Stop()
  end

  if not ReverseAnimation then
    local Object = AGroup.Object
    local Direction = AGroup.Direction
    local Fn = AGroup.Fn
    local OnFrame = AGroup.OnFrame
    local IsVisible = Object:IsVisible()

    if OnFrame then
      OnFrame:SetAlpha(1)
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

        if OnFrame then

          -- Restore anchor
          Object.IsScaling = false
          OnFrame:SetScale(1)
          Main:SetAnchorPoint(Object, 'UB')
        end
      end
      if Fn and IsVisible then
        Fn(Direction)
      end

      AGroup.Direction = ''
    elseif Type == 'move' then
      local Progress = AGroup:IsPlaying() and AGroup:GetProgress() or 1
      AGroup:Stop()

      local x = AGroup.FromValueX + AGroup.OffsetX * Progress
      local y = AGroup.FromValueY + AGroup.OffsetY * Progress

      Object:ClearAllPoints()
      Object:SetPoint(AGroup.Point, AGroup.RRegion, AGroup.RPoint, AGroup.ToValueX, AGroup.ToValueY)

      return x, y
    end
  end
end

-------------------------------------------------------------------------------
-- OnFrame (OnUpdate functions)
--
-- Functions for Alpha, Scale, Move
--
-- NOTES: Blizzards animation group for alpha alters the alpha of all child
--        frames.  This causes conflicts with other alpha settings in the bar.
--        So by doing SetAlpha() here.  These conflicts are avoided.
--
--        Blizzard built in animation scaling doesn't work well with child frames.
--        So this has to be done instead.
-------------------------------------------------------------------------------
local function OnAlphaFrame(AGroup)
  local Value = AGroup.FromValue

  -- Calculate current alpha off of progress.
  local Alpha = Value + (AGroup.ToValue - Value) * AGroup:GetProgress()

  AGroup.OnFrame:SetAlpha(Alpha)
end

local function OnScaleFrame(AGroup)
  local Value = AGroup.FromValue

  -- Calculate current scale off of progress.
  local Scale = Value + (AGroup.ToValue - Value) * AGroup:GetProgress()

  if Scale > 0 then
    AGroup.OnFrame:SetScale(Scale)
  end
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
--            StopAnimation() will return the x, y of the last animated position.
--
-- AGroup             Animation group to be played
-- 'in'               Animation gets played after object is shown.
-- 'out'              Animation gets played then object is hidden.
-- Duration           Amount of time in seconds to play animation
-- RRegion            Relative region
-- RPoint             Relative point
-- x, y               This is where object will be SetPointed to after animation.
-- OffsetX, OffsetY   Amount of offset to be animated.
-------------------------------------------------------------------------------
local function PlayAnimation(AGroup, ...)
  local Animation = AGroup.Animation

  AGroup.StopPlayingFn = StopAnimation

  local Object = AGroup.Object
  local Type = AGroup.Type
  local OnFrame = AGroup.OnFrame
  local Direction = nil
  local OffsetX = nil
  local OffsetY = nil
  local Duration = 0
  local FromValue = 0
  local ToValue = 0

  if Type == 'alpha' or Type == 'scale' then
    Direction = ...
    AGroup.Direction = Direction

    Object:Show()
    if Direction == 'in' then
      ToValue = 1
      Duration = AGroup.DurationIn
    elseif Direction == 'out' then
      FromValue = 1
      ToValue = 0
      Duration = AGroup.DurationOut
    end
  elseif Type == 'move' then
    Duration = ...
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

    Object:ClearAllPoints()
    Object:SetPoint(Point, RRegion, RPoint, FromX, FromY)
    Animation:SetOffset(OffsetX, OffsetY)
  end

  -- Check if frame is invisible or nothing to do.
  if Duration == 0 or (OffsetX == 0 and OffsetY == 0) or not Object:IsVisible() then
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

      if OnFrame then
        AGroup:SetScript('OnUpdate', OnAlphaFrame)
      end
    else
      Animation:SetFromScale(FromValue, FromValue)
      Animation:SetToScale(ToValue, ToValue)
      Animation:SetOrigin('CENTER', 0, 0)

      if OnFrame then

        -- Object is Anchor
        -- IsScaling tells SetAnchorPoint() not to change the AnchorPointFrame point
        Object.IsScaling = true
        OnFrame:SetScale(0.01)
        OnFrame:ClearAllPoints()
        OnFrame:SetPoint('CENTER')
        AGroup:SetScript('OnUpdate', OnScaleFrame)
      end
    end
  end

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
-- Sets a new animation type to play the bar gets hidden or shown.
--
-- Type  'scale' or 'alpha'
--
-- NOTES: This function must be called before any animation can be done.
--        if type is 'stopall' then all children animation gets stopped.
-------------------------------------------------------------------------------
function BarDB:SetAnimationBar(Type)
  local AGroup = self.AGroup

  if Type == 'stopall' then
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
local function OnUpdate_Display(self)
  self:SetScript('OnUpdate', nil)

  local ProfileChanged = self.ProfileChanged
  self.ProfileChanged = false

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

        Main:SetAnchorSize(Anchor, Width, Height, OffsetX + BorderPadding * -1, OffsetY + BorderPadding)
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

function BarDB:Display()
  if not self.Anchor:IsVisible() then
    self.IsDisplayWaiting = true
  else
    self.ProfileChanged = Main.ProfileChanged
    self:SetScript('OnUpdate', OnUpdate_Display)
  end
end

function BarDB:DisplayWaiting()
  if self.IsDisplayWaiting then
    self.IsDisplayWaiting = false
    self:Display()
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
-- Fn               function to call.
--
-- Parms passed to Fn
--   self           BarDB
--   BN             BoxNumber
--   TextureNumber
--   Action         'hide' or 'show'
-------------------------------------------------------------------------------
function BarDB:SetShowHideFnTexture(BoxNumber, TextureNumber, Fn)
  repeat
    local BoxFrame, BN = NextBox(self, BoxNumber)
    local Texture = BoxFrame.TFTextures[TextureNumber]
    local ShowHideFn = nil

    Texture.ShowHideFn = function(Direction)
                           Fn(self, BN, TextureNumber, Direction == 'in' and 'show' or 'hide')
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
-- Sets the background texture to the backdrop.
--
-- TextureName           New texture to set to backdrop
-- PathName              If true then TextureName is a pathname. Otherwise nil
-------------------------------------------------------------------------------
function BarDB:SetBackdropRegion(TextureName, PathName)
  SaveSettings(self, 'SetBackdropRegion', nil, nil, TextureName, PathName)

  local Region = self.Region
  local Backdrop = GetBackdrop(Region)

  Backdrop.bgFile = PathName and TextureName or LSM:Fetch('background', TextureName)
  Region:SetBackdrop(Backdrop)

  -- Need to set color since it gets lost when setting backdrop.
  Region:SetBackdropColor(GetColor(Region, 'backdrop'))
  Region:SetBackdropBorderColor(GetColor(Region, 'backdrop border'))
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

  Backdrop.edgeFile = PathName and TextureName or LSM:Fetch('border', TextureName)
  Region:SetBackdrop(Backdrop)

  -- Need to set color since it gets lost when setting backdrop.
  Region:SetBackdropColor(GetColor(Region, 'backdrop'))
  Region:SetBackdropBorderColor(GetColor(Region, 'backdrop border'))
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

  Backdrop.tile = Tile
  Region:SetBackdrop(Backdrop)

  -- Need to set color since it gets lost when setting backdrop.
  Region:SetBackdropColor(GetColor(Region, 'backdrop'))
  Region:SetBackdropBorderColor(GetColor(Region, 'backdrop border'))
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

  Backdrop.tileSize = TileSize
  Region:SetBackdrop(Backdrop)

  -- Need to set color since it gets lost when setting backdrop.
  Region:SetBackdropColor(GetColor(Region, 'backdrop'))
  Region:SetBackdropBorderColor(GetColor(Region, 'backdrop border'))
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

  Backdrop.edgeSize = BorderSize
  Region:SetBackdrop(Backdrop)

  -- Need to set color since it gets lost when setting backdrop.
  Region:SetBackdropColor(GetColor(Region, 'backdrop'))
  Region:SetBackdropBorderColor(GetColor(Region, 'backdrop border'))
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

  Insets.left = Left
  Insets.right = Right
  Insets.top = Top
  Insets.bottom = Bottom
  Region:SetBackdrop(Backdrop)

  -- Need to set color since it gets lost when setting backdrop.
  Region:SetBackdropColor(GetColor(Region, 'backdrop'))
  Region:SetBackdropBorderColor(GetColor(Region, 'backdrop border'))
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
  Region:SetBackdropColor(r, g, b, a)
  SetColor(Region, 'backdrop', r, g, b, a)
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

  -- Clear if no color is specified.
  if r == nil then
    r, g, b, a = 1, 1, 1, 1
  end
  SetColor(Region, 'backdrop border', r, g, b, a)
  Region:SetBackdropBorderColor(r, g, b, a)
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
-- Setting Box Frame/Texture Frame functions
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
    Frame:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Frame:SetBackdropColor(GetColor(Frame, 'backdrop'))
    Frame:SetBackdropBorderColor(GetColor(Frame, 'backdrop border'))
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
    Frame:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Frame:SetBackdropColor(GetColor(Frame, 'backdrop'))
    Frame:SetBackdropBorderColor(GetColor(Frame, 'backdrop border'))
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
    Frame:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Frame:SetBackdropColor(GetColor(Frame, 'backdrop'))
    Frame:SetBackdropBorderColor(GetColor(Frame, 'backdrop border'))
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
    Frame:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Frame:SetBackdropColor(GetColor(Frame, 'backdrop'))
    Frame:SetBackdropBorderColor(GetColor(Frame, 'backdrop border'))
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
    Frame:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Frame:SetBackdropColor(GetColor(Frame, 'backdrop'))
    Frame:SetBackdropBorderColor(GetColor(Frame, 'backdrop border'))
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

    Frame:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Frame:SetBackdropColor(GetColor(Frame, 'backdrop'))
    Frame:SetBackdropBorderColor(GetColor(Frame, 'backdrop border'))
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

    -- Clear if no color is specified.
    if r == nil then
      r, g, b, a = 1, 1, 1, 1
    end
    Frame:SetBackdropBorderColor(r, g, b, a)
    SetColor(Frame, 'backdrop border', r, g, b, a)
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
-- Sets the size of a texture frame.
--
-- BoxNumber           Box containing textureframe.
-- TextureFrameNumber  Texture frame to change size.
-- Width, Height       New width and height to set.
--
-- NOTES:  The BoxFrame will be resized to fit the new size of the TextureFrame.
-------------------------------------------------------------------------------
function BarDB:SetSizeTextureFrame(BoxNumber, TextureFrameNumber, Width, Height)
  SaveSettings(self, 'SetSizeTextureFrame', BoxNumber, TextureFrameNumber, Width, Height)

  repeat
    local TextureFrame = NextBox(self, BoxNumber).TextureFrames[TextureFrameNumber]
    local Width = Width or TextureFrame:GetWidth()
    local Height = Height or TextureFrame:GetHeight()

    TextureFrame:SetSize(Width, Height)
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

    BorderFrame:ClearAllPoints()

    BorderFrame:SetPoint('LEFT', Left, 0)
    BorderFrame:SetPoint('RIGHT', Right, 0)
    BorderFrame:SetPoint('TOP', 0, Top)
    BorderFrame:SetPoint('BOTTOM', 0, Bottom)

    -- Check for invalid offset
    local x, y = BorderFrame:GetSize()

    if x < 10 or y < 10 then
      BorderFrame:SetPoint('LEFT')
      BorderFrame:SetPoint('RIGHT')
      BorderFrame:SetPoint('TOP')
      BorderFrame:SetPoint('BOTTOM')
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

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Setting Texture functions
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    local Backdrop = GetBackdrop(Texture)

    Backdrop.bgFile = PathName and TextureName or LSM:Fetch('background', TextureName)
    Texture:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Texture:SetBackdropColor(GetColor(Texture, 'backdrop'))
    Texture:SetBackdropBorderColor(GetColor(Texture, 'backdrop border'))
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
    local Backdrop = GetBackdrop(Texture)

    Backdrop.edgeFile = PathName and TextureName or LSM:Fetch('border', TextureName)
    Texture:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Texture:SetBackdropColor(GetColor(Texture, 'backdrop'))
    Texture:SetBackdropBorderColor(GetColor(Texture, 'backdrop border'))
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
    local Backdrop = GetBackdrop(Texture)

    Backdrop.tile = Tile
    Texture:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Texture:SetBackdropColor(GetColor(Texture, 'backdrop'))
    Texture:SetBackdropBorderColor(GetColor(Texture, 'backdrop border'))
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
    local Backdrop = GetBackdrop(Texture)

    Backdrop.tileSize = TileSize
    Texture:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Texture:SetBackdropColor(GetColor(Texture, 'backdrop'))
    Texture:SetBackdropBorderColor(GetColor(Texture, 'backdrop border'))
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
    local Backdrop = GetBackdrop(Texture)

    Backdrop.edgeSize = BorderSize
    Texture:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Texture:SetBackdropColor(GetColor(Texture, 'backdrop'))
    Texture:SetBackdropBorderColor(GetColor(Texture, 'backdrop border'))
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
    local Backdrop = GetBackdrop(Texture)
    local Insets = Backdrop.insets

    Insets.left = Left
    Insets.right = Right
    Insets.top = Top
    Insets.bottom = Bottom
    Texture:SetBackdrop(Backdrop)

    -- Need to set color since it gets lost when setting backdrop.
    Texture:SetBackdropColor(GetColor(Texture, 'backdrop'))
    Texture:SetBackdropBorderColor(GetColor(Texture, 'backdrop border'))
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
--
-- Notes: To clear color just set nil instead of r, g, b, a.
-------------------------------------------------------------------------------
function BarDB:SetBackdropBorderColorTexture(BoxNumber, TextureNumber, r, g, b, a)
  SaveSettings(self, 'SetBackdropBorderColorTexture', BoxNumber, TextureNumber, r, g, b, a)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    Texture:SetBackdropBorderColor(r, g, b, a)

    -- Clear if no color is specified.
    if r == nil then
      r, g, b, a = 1, 1, 1, 1
    end
    Texture:SetBackdropBorderColor(r, g, b, a)
    SetColor(Texture, 'backdrop border', r, g, b, a)
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
-- Example:       BarDB:SetChange(2, MyTextureFrameNumber)
--                BarDB:Change(2, 'SetFillTexture', Value)
--                This would be the same as:
--                BarDB:SetFillTexture(2, MyTextureFrameNumber, Value)
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
    local PaddingFrame = Texture.PaddingFrame

    PaddingFrame:ClearAllPoints()
    PaddingFrame:SetPoint('TOPLEFT', Left, Top)
    PaddingFrame:SetPoint('BOTTOMRIGHT', Right, Bottom)

    local Value = Texture.Value

    -- Force the statusbar to reflect the changes.
    if Texture.Type == 'statusbar' then
      local SubFrame = Texture.SubFrame
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
  local SliderSize = Texture.SliderSize

  -- Flag setfill for onsizechanged.
  Texture.SetFill = 1

  -- if this is a slider bypass filling
  if SliderSize == nil then
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
  else
    -- This is a slider
    local SubFrame = Texture.SubFrame
    local SliderValue = Value

    -- Clip slider if outside.
    if Value + SliderSize > 1 then
      SliderSize = 1 - Value

    elseif SliderValue < 0 then
      SliderSize = SliderSize + SliderValue
      SliderValue = 0
    end

    if SliderSize > 0 then
      SubFrame:Show()
    else
      SubFrame:Hide()
    end

    if FillDirection == 'HORIZONTAL' then
      local x = nil

      -- Turn slidersize into pixels
      SliderSize = Width * SliderSize

      if ReverseFill then
        x = Width - Width * SliderValue - SliderSize
      else
        x = Width * SliderValue
      end

      SubFrame:SetWidth(SliderSize)
      SubFrame:SetPoint('LEFT', x, 0)
    else
      local y = nil

      -- Turn slidersize into pixels
      SliderSize = Height * SliderSize

      if ReverseFill then
        y = Height - Height * SliderValue - SliderSize
      else
        y = Height * SliderValue
      end

      SubFrame:SetHeight(SliderSize)
      SubFrame:SetPoint('BOTTOM', 0, y)
    end
    SubFrame:SetValue(1)
  end

  Texture.Value = Value
end

-------------------------------------------------------------------------------
-- SetFillTimer (timer function for filling)
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
    SetFill(Texture, Value, Texture.Spark)
  else

    -- Stop timer
    Main:SetTimer(Texture, nil)

    -- set the end value.
    SetFill(Texture, Texture.EndValue)

    -- Hide spark
    if Texture.Spark then
      Texture.Spark:Hide()
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
-- StartTime         Starting time if nil then starts instantly.
-- Duration          Time it will take to go from StartValue to EndValue.
-- StartValue        Starting value between 0 and 1.  If nill the current value
--                   is used instead.
-- EndValue          Ending value between 0 and 1. If nill 1 is used.
-- Constant          If true then the bar fills at a constant speed
--                   Duration becomes Speed. The speed is is equal to the amount of
--                   time it would take to go from 0 to 1.
-------------------------------------------------------------------------------
local function SetFillTime(Texture, TPS, StartTime, Duration, StartValue, EndValue, Constant)
  Main:SetTimer(Texture, nil)
  Duration = Duration or 0
  StartValue = StartValue and StartValue or Texture.Value
  EndValue = EndValue and EndValue or 1

  -- Only start a timer if startvalue and endvalues are not equal.
  if StartValue ~= EndValue and Duration > 0 then
    -- Set up the paramaters.
    local CurrentTime = GetTime()
    local Range = EndValue - StartValue

    -- Turn duration into constant speed if set.
    if Constant then
      Duration = abs(Range) * (Duration / 1)
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
    local Spark = Texture.Spark

    SetFill(Texture, EndValue)
    if Spark then
      Spark:Hide()
    end
  end
end

-------------------------------------------------------------------------------
-- SetFillTimeDurationTexture
--
-- Changes the duration of a fill timer already in progress.  This will cause
-- the bar to speed up or slow down without stutter.
--
-- BoxNumber         Box containing the texture being changed
-- TextureNumber     Texture being used in fill.
-- NewDuration       The bar will fill over time using this duration from where it left off.
-------------------------------------------------------------------------------
function BarDB:SetFillTimeDurationTexture(BoxNumber, TextureNumber, NewDuration)
  local Texture = self.BoxFrames[BoxNumber].TFTextures[TextureNumber]

  -- Make sure a timer has already been intialized.
  if Texture.Duration ~= nil then
    local Time = GetTime()
    local TimeElapsed = Time - Texture.StartTime
    local Duration = Texture.Duration

    -- Make sure bar is currently filling.
    if TimeElapsed <= Duration then
      Texture.StartTime = Time
      Texture.StartValue = Texture.StartValue + Texture.Range * (TimeElapsed / Duration)
      Texture.Duration = NewDuration
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

  SetFillTime(Texture, 1 / Main.UnitBars.BarFillFPS, StartTime, Duration, StartValue, EndValue)
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
--       This fills at a constant speed.  The speed is calculated from the time
--       it would take to fill the bar from empty to full.
-------------------------------------------------------------------------------
function BarDB:SetFillTexture(BoxNumber, TextureNumber, Value, ShowSpark)
  local Texture = self.BoxFrames[BoxNumber].TFTextures[TextureNumber]
  local Speed = Texture.Speed or 0

  -- If Speed > 0 then fill the texture from its current value to a new value.
  if Speed > 0 then
    SetFillTime(Texture, 1 / Main.UnitBars.BarFillFPS, nil, Speed, nil, Value, true)
  else
    local Spark = nil

    if ShowSpark ~= nil then
      Spark = Texture.Spark
    end
    SetFill(Texture, Value, Spark)
    if Spark and ShowSpark == false then
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
-- SetFillSpeedTexture
--
-- Changes the speed from the bar will fill at.
--
-- BoxNumber       Box containing the texture
-- TextureNumber   Texture to smooth fill on.
-- Speed           The amount of time it takes to fill from 0 to 1.
--                 So a speed of 10 would take 10sec from 0 to 1.  Or 5sec from 0 to 0.5
-------------------------------------------------------------------------------
function BarDB:SetFillSpeedTexture(BoxNumber, TextureNumber, Speed)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    -- Stop any fill timers currently running, to avoid bugs.
    local Duration = Texture.Duration
    if Duration and Duration > 0 then

      Main:SetTimer(Texture, nil)

      -- set the end value.
      SetFill(Texture, Texture.EndValue)

      -- Hide spark
      local Spark = Texture.Spark
      if Spark then
        Spark:Hide()
      end

      Texture.Duration = 0
    end

    Texture.Speed = Speed
  until LastBox
end

-------------------------------------------------------------------------------
-- SetSliderTexture
--
-- Makes a status bar or texture act as a slider.
--
-- Usage:  SetSliderTexture(Texture)  <-- local function call
--         SetSliderTexture(Texture, SliderSizer)
--
-- BoxNumber       Box containing the texture or statusbar
-- TextureNumber   The number refering to the texture or statusbar
-- SliderSize      Size between 0 to 1.
--
-- NOTES: The slider gets drawn from the value specified in SetFill calls.
-------------------------------------------------------------------------------
local function SetSliderTexture(Texture)
  local FillDirection = Texture.FillDirection
  local SubFrame = Texture.SubFrame

  SubFrame:ClearAllPoints()
  if FillDirection == 'HORIZONTAL' then
    SubFrame:SetPoint('TOP')
    SubFrame:SetPoint('BOTTOM')
  else
    SubFrame:SetPoint('LEFT')
    SubFrame:SetPoint('RIGHT')
  end
end

function BarDB:SetSliderTexture(BoxNumber, TextureNumber, SliderSize)
  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    if Texture.SliderSize == nil then
      SetSliderTexture(Texture)
    end
    Texture.SliderSize = SliderSize
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
function BarDB:SetCooldownTexture(BoxNumber, TextureNumber, StartTime, Duration, Line, HideFlash)
  local Texture = self.BoxFrames[BoxNumber].TFTextures[TextureNumber]
  local CooldownFrame = Texture.CooldownFrame

  CooldownFrame:SetDrawEdge(Line or false)
  CooldownFrame:SetDrawBling(not HideFlash)

  CooldownFrame:SetCooldown(StartTime or 0, Duration or 0)
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

    Texture.FillDirection = Direction

    if Texture.Type == 'statusbar' then
      Texture.SubFrame:SetOrientation(Direction)
    end

    -- need to set filldirection on sliders
    if Texture.SliderSize then
      SetSliderTexture(Texture)
    end

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
  SaveSettings(self, 'SetColorTexture', BoxNumber, TextureNumber, r, g, b, a)

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
  SaveSettings(self, 'SetTexture', BoxNumber, TextureNumber, TextureName)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    if Texture.Type == 'statusbar' then
      if Texture.CurrentTexture ~= TextureName then
        local SubFrame = Texture.SubFrame

        SubFrame:SetStatusBarTexture(LSM:Fetch('statusbar', TextureName))
        Texture.CurrentTexture = TextureName

        local SubTexture = SubFrame:GetStatusBarTexture()

        SubTexture:SetHorizTile(false)
        SubTexture:SetVertTile(false)
        SubFrame:SetOrientation(Texture.FillDirection)
        SubFrame:SetReverseFill(Texture.ReverseFill)

        local RotateTexture = Texture.RotateTexture

        -- Needed to add a check, because if you hold the mouse button down in the color picker.
        -- it causes the bar texture to change. Cosmetic fix.
        if SubFrame:GetRotatesTexture() ~= RotateTexture then
          SubFrame:SetRotatesTexture(RotateTexture)
        end
        Texture.SubTexture = SubTexture
        SubFrame:SetStatusBarColor(GetColor(Texture, 'statusbar'))
      end
    else
      Texture.SubTexture:SetTexture(TextureName)
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
-- UseSize        Assuming if false then it uses the whole atlas. If nil defaults to true.
--
-- NOTES: Only works on textures.
-------------------------------------------------------------------------------
function BarDB:SetAtlasTexture(BoxNumber, TextureNumber, AtlasName, UseSize)
  SaveSettings(self, 'SetAtlasTexture', BoxNumber, TextureNumber, AtlasName, UseSize)

  repeat
    local Texture = NextBox(self, BoxNumber).TFTextures[TextureNumber]

    if Texture.Type ~= 'statusbar' then
      Texture.SubTexture:SetAtlas(AtlasName, UseSize or true)
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
  local RelativeTextureNumber, RelativePoint = select(1, ...)
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
  SaveSettings(self, 'SetSizeTexture', BoxNumber, TextureNumber, Width, Height)

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
  SaveSettings(self, 'SetScaleTexture', BoxNumber, TextureNumber, Scale)

  repeat
    NextBox(self, BoxNumber).TFTextures[TextureNumber]:SetScale(Scale)
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
-- PathName     If true then the SoundName becomes a path to the sound to play.
--              Otherwise nil.
-------------------------------------------------------------------------------
function BarDB:PlaySound(SoundName, Channel, PathName)
  -- No SaveSettings for sound. Since there is nothing visual to restore.

  if not Main.ProfileChanged and not Main.IsDead then
    SoundName = PathName and SoundName or LSM:Fetch('sound', SoundName)
    PlaySoundFile(SoundName, Channel)
  end
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
  local Anchor = UnitBarF.Anchor

  -- Copy the functions.
  for FnName, Fn in pairs(BarDB) do
    if type(Fn) == 'function' then
      Bar[FnName] = Fn
    end
  end

  -- Reset the virtual frame levels
  VirtualFrameLevels = nil

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

    -- Create texture frame border for border, but also allow the texture frame to change size
    -- without effecting the box size.
    local BorderFrame = CreateFrame('Frame', nil, TF)
    BorderFrame:SetPoint('LEFT')
    BorderFrame:SetPoint('RIGHT')
    BorderFrame:SetPoint('TOP')
    BorderFrame:SetPoint('BOTTOM')

    -- Add the framelevel passed to the current framelevel.
    local FrameLevel = GetVirtualFrameLevel(Level)
    SetVirtualFrameLevel(Level, FrameLevel)

    BorderFrame:SetFrameLevel(FrameLevel)
    TF:Hide()
    TF.Hidden = true
    TF.BorderFrame = BorderFrame

    TextureFrames[TextureFrameNumber] = TF

    -- Update TopFrameLevel counter
    SetTopFrame(self, TF)
  until LastBox
end

-------------------------------------------------------------------------------
-- OnSizeChangedTexture (called by setscript)
--
-- Updates the width and height of a statusbar or texture.
--
-- self            PaddingFrame
-- Width, Height   Width and Height of the StatusBar
--
-- NOTES:  This function makes sure a texture always stretches to the size of
--         the textures subframe.  It also makes sure that statusbar gets updated
--         if its size was changed and it was setfilled.
-------------------------------------------------------------------------------
local function OnSizeChangedTexture(PaddingFrame, Width, Height)
  local Texture = PaddingFrame:GetParent()

  Texture.Width = Width
  Texture.Height = Height

  if Texture.SetFill then
    local Value = Texture.Value

    if Texture.Type == 'statusbar' then
      Texture.SubFrame:SetValue(Value - 1)
    end
    SetFill(Texture, Value)
    Texture:SetSize(Width, Height)
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
    local BorderFrame = TextureFrame.BorderFrame
    local SubFrame = nil
    local Texture = CreateFrame('Frame', nil, BorderFrame)
    local PaddingFrame = CreateFrame('Frame', nil,  Texture)

    -- Set base frame level.
    local FrameLevel = GetVirtualFrameLevel(Level)
    SetVirtualFrameLevel(Level, FrameLevel)
    Texture:SetFrameLevel(FrameLevel)

    -- Create a statusbar or texture.
    if TextureType == 'statusbar' then
      SubFrame = CreateFrame('StatusBar', nil, PaddingFrame)
      SubFrame:SetMinMaxValues(0, 1)
      SubFrame:SetValue(1)
      SubFrame:SetOrientation('HORIZONTAL')

      -- Status bar is always the same size of the texture frame.
      Texture:SetAllPoints(BorderFrame)

      -- Set defaults for statusbar.
      Texture.Type = 'statusbar'

      FrameLevel = FrameLevel + 1
    else
      SubFrame = CreateFrame('Frame', nil, PaddingFrame)
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

        local CooldownFrame = CreateFrame('Cooldown', nil, SubFrame, 'CooldownFrameTemplate')
        CooldownFrame:ClearAllPoints()  -- Undoing template SetAllPoints
        CooldownFrame:SetPoint('CENTER', SubTexture, 'CENTER')
        CooldownFrame:SetHideCountdownNumbers(true)

        Texture.CooldownFrame = CooldownFrame
        FrameLevel = FrameLevel + 1
      end
    end

    -- Make sure subframe is always the same size as texture.
    PaddingFrame:SetAllPoints(Texture)
    SubFrame:SetAllPoints(PaddingFrame)

    -- Set highest frame level.
    SetVirtualFrameLevel(Level, FrameLevel)

    -- Update TopFrame.
    SetTopFrame(self, SubFrame)

    -- Set onsize changed to update texture size.
    PaddingFrame:SetScript('OnSizeChanged', OnSizeChangedTexture)

    -- Set defaults.
    Texture.SubFrame = SubFrame
    Texture.PaddingFrame = PaddingFrame
    Texture.Width = 1
    Texture.Height = 1
    Texture.Value = 1
    Texture.RotateTexture = false
    Texture.FillDirection = 'HORIZONTAL'
    Texture.ReverseFill = false

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

  -- Iterate thru text data
  for BT, TextData in pairs(BarTextData) do

    -- Iterate thru the fontstring array.
    for _, TD in ipairs(TextData) do
      local Text = TD.Text

      if Text then
        local NumStrings = #Text

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

  local function FontGetValue_Short(TextData, Value, ValueType)
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

  FontGetValue['whole_dgroups'] = function(TextData, Value, ValueType)
    return NumberToDigitGroups(Value)
  end

  FontGetValue['percent'] = function(TextData, Value, ValueType)
    local MaxValue = TextData.maximum

    if MaxValue == 0 then
      return 0
    else
      local PercentFn = TextData.PercentFn

      if PercentFn then
        return PercentFn(Value, MaxValue)
      else
        return ceil(Value / MaxValue * 100)
      end
    end
  end

  FontGetValue['thousands'] = function(TextData, Value, ValueType)
    return Value / 1000
  end

  FontGetValue['thousands_dgroups'] = function(TextData, Value, ValueType)
    return NumberToDigitGroups(Round(Value / 1000))
  end

  FontGetValue['millions'] = function(TextData, Value, ValueType)
    return Value / 1000000
  end

  FontGetValue['millions_dgroups'] = function(TextData, Value, ValueType)
    return NumberToDigitGroups(Round(Value / 1000000, 1))
  end

  local function SetNameData(TextData, Value, ValueType)
    local Name, Realm = UnitName(TextData.name)

    Name = Name or ''

    if ValueType == 'unitname' then
      return Name
    else
      Realm = Realm or ''
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

  local function SetLevelData(TextData, Value, ValueType)
    local UnitLevelScaled = nil
    local Level = TextData.level
    local ScaledLevel = TextData.level2

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
    else
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

  -- timeSS, timeSS_H, timeSS_HH (no function needed)

-------------------------------------------------------------------------------
-- SetValue (method for Font)
--
-- BoxNumber          Boxnumber that contains the font string.
-- ...                Type, Value pairs.  Example:
--                      'current', CurrValue, 'maximum', MaxValue, 'predicted', PredictedPower, 'name', Unit)
--
-- NOTES: SetValue() is optimized for speed since this function gets called a lot.
-------------------------------------------------------------------------------
local function SetValue(TextData, FontString, Layout, NumValues, ValueNames, ValueTypes, ...)

  -- if we have paramters left then get them.
  local Name = ValueNames[NumValues]

  if NumValues > 1 then
    if Name ~= 'none' then
      local ValueType = ValueTypes[NumValues]
      local Value = TextData[Name]
      local GetValue = FontGetValue[ValueType]

      SetValue(TextData, FontString, Layout, NumValues - 1, ValueNames, ValueTypes, Value ~= '' and GetValue and GetValue(TextData, Value, ValueType) or Value, ...)
    else
      SetValue(TextData, FontString, Layout, NumValues - 1, ValueNames, ValueTypes, ...)
    end
  elseif Name ~= 'none' then
    local ValueType = ValueTypes[NumValues]
    local Value = TextData[Name]
    local GetValue = FontGetValue[ValueType]

    FontString:SetFormattedText(Layout, Value ~= '' and GetValue and GetValue(TextData, Value, ValueType) or Value, ...)
  else
    FontString:SetFormattedText(Layout, ...)
  end
end

-- SetValueFont
function BarDB:SetValueFont(BoxNumber, ...)
  local Frame = self.BoxFrames[BoxNumber]

  local TextData = Frame.TextData
  local TextFrame = TextData.TextFrame
  local MaxPar = select('#', ...)
  local ParValue2 = nil
  local Index = 1

  repeat
    local ParType, ParValue = select(Index, ...)
    local ParSize = SetValueParSize[ParType] or 2

    TextData[ParType] = ParValue
    if ParSize == 3 then
      TextData[ParType .. '2'] = select(Index + 2, ...)
    end
    Index = Index + ParSize
  until Index > MaxPar

  local Text = TextData.Text

  for Index = 1, TextData.NumStrings do
    local FontString = TextData[Index]
    local Txt = Text[Index]
    local ValueNames = Txt.ValueNames

    -- Display the font string
    local ReturnOK, Msg = pcall(SetValue, TextData, FontString, Txt.Layout, #ValueNames, ValueNames, Txt.ValueTypes)

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
-- Text            Output to display to the text lines
-------------------------------------------------------------------------------
function BarDB:SetValueRawFont(BoxNumber, Text)
  repeat
    local Frame = NextBox(self, BoxNumber)

    local TextData = Frame.TextData

    for Index = 1, TextData.NumStrings do
      TextData[Index]:SetText(Text)
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- SetValueTimer
--
-- Timer function for FontSetValueTime
-------------------------------------------------------------------------------
local function SetValueTimer(FontTime)
  local TimeElapsed = GetTime() - FontTime.StartTime

  if TimeElapsed < FontTime.Duration then
    local Counter = FontTime.Counter
    local TextData = FontTime.TextData
    local Text = TextData.Text

    TextData.time = Counter

    if TextData.Multi then
      for Index = 1, TextData.NumStrings do
        local FontString = TextData[Index]
        local Txt = Text[Index]
        local ValueNames = Txt.ValueNames

        -- Display the font string
        local ReturnOK, Msg = pcall(SetValue, TextData, FontString, Txt.Layout, #ValueNames, ValueNames, Txt.ValueTypes)

        if not ReturnOK then
          FontString:SetFormattedText('Err (%d)', Index)
        end
      end
    else
      local Txt = TextData.Text[1]
      local ValueNames = Txt.ValueNames

      -- Display the font string
      local ReturnOK, Msg = pcall(SetValue, TextData, TextData[1], Txt.Layout, #ValueNames, ValueNames, Txt.ValueTypes)

      if not ReturnOK then
        TextData[1]:SetFormattedText('Err (%d)', 1)
      end
    end
    Counter = Counter + FontTime.Step
    Counter = Counter > 0 and Counter or 0
    FontTime.Counter = Counter
  else

    -- stop timer
    Main:SetTimer(FontTime, nil)
    local TextData = FontTime.TextData
    for Index = 1, TextData.NumStrings do
      TextData[Index]:SetText('')
    end
  end
end

-------------------------------------------------------------------------------
-- FontSetValueTime
--
-- Displays time in seconds over time.
--
-- BoxNumber            BoxNumber to display time on.
-- StartTime            Starting time if nil then the current time will be used.
-- Duration             Duration in seconds.  Duration of 0 or less will stop the current timer.
-- StartValue           Starting value in seconds.  This will start dipslaying seconds from this value.
-- Direction            Direction to go in +1 or -1
-- ...                  Additional Type, Value pairs. Optional.  Example:
--                        'current', CurrValue, 'maximum', MaxValue, 'predicted', PredictedPower, 'name', Unit)
-------------------------------------------------------------------------------
function BarDB:SetValueTimeFont(BoxNumber, StartTime, Duration, StartValue, Direction, ...)
  local Step = Direction == 1 and 0.1 or Direction == -1 and -0.1 or 0.1

  repeat
    local Frame = NextBox(self, BoxNumber)

    local FontTime = Frame.FontTime
    if FontTime == nil then
      FontTime = {}
      Frame.FontTime = FontTime
    end

    Main:SetTimer(FontTime, nil)

    Duration = Duration or 0
    local TextData = Frame.TextData

    if Duration > 0 then
      local CurrentTime = GetTime()
      local WaitTime = 0
      local TimeElapsed = 0

      StartTime = StartTime and StartTime or CurrentTime

      if StartTime > CurrentTime then
        WaitTime = StartTime - CurrentTime
      else
        TimeElapsed = CurrentTime - StartTime
      end

      if Step < 0 then
        StartValue = Duration - TimeElapsed
      else
        StartValue = StartValue + TimeElapsed
      end

      -- Truncate down to 1 decimal place.
      StartValue = abs(StartValue - (StartValue % 0.1))

      -- Set up the paramaters.
      FontTime.StartTime = StartTime
      FontTime.Duration = Duration
      FontTime.StartValue = StartValue
      FontTime.Counter = StartValue
      FontTime.Step = Step
      FontTime.TextData = TextData
      FontTime.Frame = Frame

      local MaxPar = select('#', ...)
      if MaxPar > 0 then
        local Index = 1

        repeat
          local ParType, ParValue = select(Index, ...)
          local ParSize = SetValueParSize[ParType] or 2

          TextData[ParType] = ParValue
          if ParSize == 3 then
            TextData[ParType .. '2'] = select(Index + 2, ...)
          end
          Index = Index + ParSize
        until Index > MaxPar
      end

      Main:SetTimer(FontTime, SetValueTimer, 0.1, WaitTime)
    else
      for Index = 1, TextData.NumStrings do
        TextData[Index]:SetText('')
      end
    end
  until LastBox
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
  local LastName = nil
  local Sep = ''
  local SepFlag = false

  local Layout = ''

  for NameIndex, Name in ipairs(ValueNames) do
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
      Layout = Layout .. Sep .. (ValueLayout[ValueTypes[NameIndex]] or '')
    end
  end

  return Layout
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
        FontString:SetTextColor(r, g, b, a)
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

  local Text = self.UnitBarF.UnitBar.Text

  repeat
    local Frame = NextBox(self, BoxNumber)
    local TextData = Frame.TextData

    -- Check for fontstrings
    if TextData then
      local Txt = Text[TextLine]
      local TF = TextData.TextFrames[TextLine]

      if TF and Txt then
        local AGroup = TF.AGroup
        local IsPlaying = AGroup and AGroup:IsPlaying() or false
        local Ox = Txt.OffsetX
        local Oy = Txt.OffsetY

        if AnimateTimeTrigger then
          local LastX = TF.LastX or 0
          local LastY = TF.LastY or 0

          if OffsetX ~= LastX or OffsetY ~= LastY then
            TF.LastX = OffsetX
            TF.LastY = OffsetY
            TF.Animate = false

            -- Create animation if not found
            if AGroup == nil then
              AGroup = GetAnimation(self, TF, 'children', 'move')
              TF.AGroup = AGroup
            end

            if IsPlaying then
              LastX, LastY = StopAnimation(AGroup)
              LastX = LastX - Ox
              LastY = LastY - Oy
            end
            PlayAnimation(AGroup, AnimateTimeTrigger, Txt.FontPosition, Frame, Txt.Position, Ox + LastX, Oy + LastY, Ox + OffsetX, Oy + OffsetY)

          -- offset hasn't changed
          elseif not IsPlaying then
            TF:ClearAllPoints()
            TF:SetPoint(Txt.FontPosition, Frame, Txt.Position, Ox + OffsetX, Oy + OffsetY)
          end
        else
          -- Non animated trigger call or called outside of triggers or trigger disabled.
          if IsPlaying then
            StopAnimation(AGroup)
          end
          -- This will get called if changing profiles cause UndoTriggers() will get called.
          if CalledByTrigger or Main.ProfileChanged then
            print('clear lastxy', CalledByTrigger, Main.ProfileChanged)
            TF.LastX = OffsetX
            TF.LastY = OffsetY
          end

          TF:ClearAllPoints()
          TF:SetPoint(Txt.FontPosition, Frame, Txt.Position, Ox + (OffsetX or 0), Oy + (OffsetY or 0))
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
-------------------------------------------------------------------------------
function BarDB:SetSizeFont(BoxNumber, TextLine, Size)
  SaveSettings(self, 'SetSizeFont', BoxNumber, TextLine, Size)

  local Text = self.UnitBarF.UnitBar.Text

  repeat
    local Frame = NextBox(self, BoxNumber)
    local TextData = Frame.TextData

    -- Check for fontstrings
    if TextData then
      local FontString = TextData[TextLine]
      local Txt = Text[TextLine]

      if FontString and Txt then
        Size = Size or Txt.FontSize

        -- Set font size
        local ReturnOK = pcall(FontString.SetFont, FontString, LSM:Fetch('font', Txt.FontType), Size, Txt.FontStyle)

        if not ReturnOK then
          FontString:SetFont(LSM:Fetch('font', Txt.FontType), Size, 'NONE')
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

  local Text = self.UnitBarF.UnitBar.Text

  repeat
    local Frame = NextBox(self, BoxNumber)
    local TextData = Frame.TextData

    -- Check for fontstrings
    if TextData then
      local FontString = TextData[TextLine]
      local Txt = Text[TextLine]

      if FontString and Txt then
        Type = Type or Txt.FontType

        -- Set font size
        local ReturnOK, Message = pcall(FontString.SetFont, FontString, LSM:Fetch('font', Type), Txt.FontSize, Txt.FontStyle)

        if not ReturnOK then
          FontString:SetFont(LSM:Fetch('font', Type), Txt.FontSize, 'NONE')
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

  local Text = self.UnitBarF.UnitBar.Text

  repeat
    local Frame = NextBox(self, BoxNumber)
    local TextData = Frame.TextData

    -- Check for fontstrings
    if TextData then
      local FontString = TextData[TextLine]
      local Txt = Text[TextLine]

      if FontString and Txt then

        -- Set font size
        local ReturnOK = pcall(FontString.SetFont, FontString, LSM:Fetch('font', Txt.FontType), Txt.FontSize, Style or Txt.FontStyle)

        if not ReturnOK then
          FontString:SetFont(LSM:Fetch('font', Txt.FontType), Txt.FontSize, 'NONE')
        end
      end
    end
  until LastBox
end

-------------------------------------------------------------------------------
-- UpdateFont
--
-- Updates a font based on the text settings in UnitBar.Text
--
-- BoxNumber            BoxFrame that contains the font.
-- ColorIndex           Sets color[ColorIndex] bypassing Color.All setting.
-------------------------------------------------------------------------------
function BarDB:UpdateFont(BoxNumber, ColorIndex)
  local Text = self.UnitBarF.UnitBar.Text
  local TopFrame = self.TopFrame
  local UBD = DUB[self.BarType]
  local DefaultTextSettings = UBD.Text[1]
  local Multi = UBD.Text._Multi

  repeat
    local Frame, BoxIndex = NextBox(self, BoxNumber)

    local TextData = Frame.TextData
    local TextFrames = TextData.TextFrames
    local NumStrings = nil

    -- Adjust the fontstring array based on the text settings.
    for Index = 1, #Text do
      local FontString = TextData[Index]
      local Txt = Text[Index]
      local TextFrame = TextFrames[Index]
      local Color = Txt.Color
      local c = nil
      local ColorAll = Color.All

      -- Colorall dont exist then fake colorall.
      if ColorAll == nil then
        ColorAll = true
      end
      NumStrings = Index

      -- Since Text is dynamic we need to make sure no values are missing.
      -- If they are they'll be copied from defaults.
      Main:CopyMissingTableValues(DefaultTextSettings, Txt)

      -- Update the layout if not in custom mode.
      if not Txt.Custom then
        Txt.Layout = GetLayoutFont(Txt.ValueNames, Txt.ValueTypes)
      end

      -- Create a new fontstring if one doesn't exist.
      if FontString == nil then
        TextFrame = CreateFrame('Frame', nil, Frame)
        TextFrame:SetBackdrop(FrameBorder)
        TextFrame:SetBackdropBorderColor(1, 1, 1, 0)

        TextFrames[Index] = TextFrame
        FontString = TextFrame:CreateFontString()

        FontString:SetAllPoints(TextFrame)
        TextData[Index] = FontString
      end

      -- Set font size, type, and style
      self:SetTypeFont(BoxNumber, Index)
      self:SetSizeFont(BoxNumber, Index)
      self:SetStyleFont(BoxNumber, Index)

      -- Set font location
      FontString:SetJustifyH(Txt.FontHAlign)
      FontString:SetJustifyV(Txt.FontVAlign)
      FontString:SetShadowOffset(Txt.ShadowOffset, -Txt.ShadowOffset)

      -- Position the font by moving textframe.
      self:SetOffsetFont(BoxNumber, Index)
      TextFrame:SetSize(Txt.Width, Txt.Height)

      -- Set the text frame to be on top.
      TextFrame:SetFrameLevel(TopFrame:GetFrameLevel() + 1)

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
      self:SetColorFont(BoxNumber, Index, c.r, c.g, c.b, c.a)
    end

    -- Erase font string data no longer used.
    for Index = NumStrings + 1, TextData.NumStrings do
      TextData[Index]:SetText('')
    end
    TextData.Multi = Multi
    TextData.NumStrings = NumStrings
    TextData.Text = Text
  until LastBox
end

-------------------------------------------------------------------------------
-- CreateFont
--
-- Creates a font object to display text on the bar.
--
-- BoxNumber            Boxframe you want the font to be displayed on.
-- PercentFn            Function to calculate percents in FontSetValue()
--                      Not all percent calculations are the same. So this
--                      adds that flexibility. If nil uses its own math.
-------------------------------------------------------------------------------
function BarDB:CreateFont(BoxNumber, PercentFn)
  local BarType = self.BarType

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
    TextData.NumStrings = 0
    TextData.TextFrames = {}
    TextData.PercentFn = PercentFn
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
-- If OTableName is nil then matches all TableNames
-- If OKeyName is nil then it matches all KeyNames
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
-- UndoTriggers
--
-- Undoes triggers as if they never existed.
-------------------------------------------------------------------------------
local function UndoTriggers(BarDB)
  CalledByTrigger = true

  local Groups = BarDB.Groups

  if Groups then
    local LastValues = Groups.LastValues

    for Object in pairs(LastValues) do
      local Group = Object.Group

      RestoreSettings(BarDB, Object.FunctionName, Group.BoxNumber)

      Object.Trigger = nil
      Object.AuraTrigger = nil
      Object.StaticTrigger = nil
      Object.Restore = false
      Object.OneTime = {}

      if Object.Virtual then
        Group.Hidden = true
      else
        Group.Hidden = false
      end

      LastValues[Object] = nil
    end
  end

  CalledByTrigger = false
end

-------------------------------------------------------------------------------
-- CheckTriggers
--
-- Removes or modifies triggers to best fit the groups. Also filters
-- triggers into sorted, static, and auras.
-------------------------------------------------------------------------------
local function FindLowestValue(Conditions)
  local LowestValue = nil

  for TriggerIndex = 1, #Conditions do
    local Value = Conditions[TriggerIndex].Value

    if LowestValue == nil or Value < LowestValue then
      LowestValue = Value
    end
  end

  return LowestValue
end

local function SortTriggers(a, b)
  return FindLowestValue(a.Conditions) < FindLowestValue(b.Conditions)
end

function BarDB:CheckTriggers()
  local Groups = self.Groups
  local VirtualGroupList = Groups.VirtualGroupList
  local Triggers = Groups.Triggers
  local LastValues = {}
  local OrderNumbers = {}
  local SortedTriggers = {}
  local AuraTriggers = {}
  local GroupNumbers = {}
  local Units = {}
  local AllDeleted = true
  local TriggerIndex = 1

  -- Check for text multiline.
  local Text = DUB[self.BarType].Text
  local TextMultiLine = Text and Text._Multi

  -- Undo triggers first
  UndoTriggers(self)

  while TriggerIndex <= #Triggers do
    local Trigger = Triggers[TriggerIndex]
    local GroupNumber = Trigger.GroupNumber
    local Group = Groups[GroupNumber]
    local DeleteTrigger = true

    -- Group not found, so put it in group 1.
    if Group == nil then
      Trigger.Name = format('[From %s] %s', GroupNumber, Trigger.Name)

      GroupNumber = 1
      Trigger.GroupNumber = GroupNumber
      Group = Groups[GroupNumber]
    end

    -- Delete trigger if groupnumber not found.
    if Group then
      -- delete trigger if typeID and type not found in group.
      local TypeIndex = Group.RTypes[strlower(Trigger.Type)] or Group.TypeIDs[Trigger.TypeID] or 0

      if TypeIndex > 0 then
        DeleteTrigger = false
        AllDeleted = false

        local TypeID = Group.TypeIDs[TypeIndex]
        Trigger.TypeID = TypeID
        Trigger.Type = strlower(Group.Types[TypeIndex])
        Trigger.TypeIndex = TypeIndex

        local Object = Group.Objects[TypeIndex]
        local ValueTypeIDs = Group.ValueTypeIDs
        local ValueTypeID = Trigger.ValueTypeID
        local Operator = Trigger.Operator
        local GroupType = Group.GroupType

        -- Only want sound triggers firing once so its not annoying.
        if TypeID == 'sound' then
          Trigger.OneTime = 1
        else
          Trigger.OneTime = nil
        end

        -- Modify value types.
        local ValueTypeIndex = Group.RValueTypes[strlower(Trigger.ValueType)] or ValueTypeIDs[ValueTypeID] or 0

        if ValueTypeIndex == 0 then
          ValueTypeIndex = 1
        end
        local ValueTypeID = ValueTypeIDs[ValueTypeIndex]
        Trigger.ValueTypeID = ValueTypeID
        Trigger.ValueType = strlower(Group.ValueTypes[ValueTypeIndex])

        -- Check conditions.
        local Conditions = Trigger.Conditions

        for ConditionIndex = 1, #Conditions do
          local Condition = Conditions[ConditionIndex]

          Condition.OrderNumber = ConditionIndex
        end

        -- Set Animation data if theres animation
        local AnimateTime = Trigger.AnimateTime

        if AnimateTime == nil then
          Trigger.AnimateTime = 0.01
          Trigger.Animate = false
        else
          Trigger.CanAnimate = Object.CanAnimate or false
          Trigger.AnimateTime = AnimateTime <= 0 and 0.01 or AnimateTime
        end

        -- Validate get function type ID
        -- For now get function is used for color.
        local GetFnTypeID = Trigger.GetFnTypeID or 'none'

        if GetFnTypeID ~= 'none' then
          local GetFn = Object.GetFn

          if GetFn and GetFn[GetFnTypeID] == nil then
            GetFnTypeID = 'none'
          end
        end
        Trigger.GetFnTypeID = GetFnTypeID

        Trigger.Index = TriggerIndex

        -- Set virtual tag
        Trigger.Virtual = GroupType == 'v'

        local OrderNumber = (OrderNumbers[GroupNumber] or 0) + 1

        Trigger.OrderNumber = OrderNumber
        OrderNumbers[GroupNumber] = OrderNumber

        -- Check for text
        if strfind(TypeID, 'font') then
          local TextLine = Trigger.TextLine or 1

          if TextMultiLine == nil then
            TextLine = 1
          end

          Trigger.TextLine = TextLine
          Trigger.TextMultiLine = TextMultiLine
        else
          Trigger.TextLine = nil
          Trigger.TextMultiLine = nil
        end

        -- Filter triggers into static, sorted, and auras.
        Object.StaticTrigger = nil

        local GroupNumbers = nil

        -- Check for all
        if GroupType == 'a' then
          GroupNumbers = {}

          -- Create group numbers table for all
          for GN = 1, #Groups do
            local Group = Groups[GN]
            local BoxNumber = Group.BoxNumber
            local Obj = Group.Objects[TypeIndex]

            if Obj and BoxNumber > 0 then
              GroupNumbers[GN] = 1
            end
          end
          Trigger.GroupNumbers = GroupNumbers
        else
          Trigger.GroupNumbers = nil
        end

        if Trigger.Enabled then
          if Trigger.Static then
            if GroupNumbers then

              -- apply to all groups
              for GN in pairs(GroupNumbers) do
                local Obj = Groups[GN].Objects[TypeIndex]

                LastValues[Obj] = 1
                Obj.StaticTrigger = Trigger
              end

              -- Apply to all virtual groups
              if VirtualGroupList then
                for _, VirtualGroups in pairs(VirtualGroupList) do
                  for _, VirtualGroup in pairs(VirtualGroups) do
                    local VirtualObj = VirtualGroup.Objects[TypeIndex]

                    LastValues[VirtualObj] = 1
                    VirtualObj.StaticTrigger = Trigger
                  end
                end
              end
            else
              -- apply non virtual trigger to one group
              if GroupType ~= 'v' then
                LastValues[Object] = 1
                Object.StaticTrigger = Trigger
              end

              -- Apply virtual trigger to one virtual group
              if GroupType == 'v' and VirtualGroupList then
                for _, VirtualGroup in pairs(VirtualGroupList[GroupNumber]) do
                  local VirtualObj = VirtualGroup.Objects[TypeIndex]

                  LastValues[VirtualObj] = 1
                  VirtualObj.StaticTrigger = Trigger
                end
              end
            end
          -- Build a unit list
          elseif ValueTypeID == 'auras' then
            local Auras = Trigger.Auras

            AuraTriggers[#AuraTriggers + 1] = Trigger
            if Auras == nil then
              Auras = {}
              Trigger.Auras = Auras
            else
              for SpellID, Aura in pairs(Auras) do
                Units[Aura.Unit] = 1
              end
            end
          else
            SortedTriggers[#SortedTriggers + 1] = Trigger
          end
        end
      end
    end
    if DeleteTrigger then
      tremove(Triggers, TriggerIndex)
    else
      TriggerIndex = TriggerIndex + 1
    end
  end

  -- Set number of triggers per group.
  for GroupNumber = 1, #Groups do
    Groups[GroupNumber].TriggersInGroup = OrderNumbers[GroupNumber] or 0
  end

  if #Triggers > 0 then
    sort(SortedTriggers, SortTriggers)
  end
  Groups.SortedTriggers = SortedTriggers
  Groups.AuraTriggers = AuraTriggers
  Groups.LastValues = LastValues

  -- units exist so turn on the aura tracker.
  if next(Units) then
    local St = ''
    for Unit in pairs(Units) do
      St = St .. Unit .. ' '
    end
    Main:SetAuraTracker(self.UnitBarF, 'fn', function(TrackedAurasList)
                                               self:SetAuraTriggers(TrackedAurasList)
                                             end)
    Main:SetAuraTracker(self.UnitBarF, 'units', Main:StringSplit(' ', St))
  else
    Main:SetAuraTracker(self.UnitBarF, 'off')
  end
end

-------------------------------------------------------------------------------
-- EnableTriggers
--
-- Enables or disabled triggers. Also creates the groups.
--
--
-- Enable                        true or false.  If true then groups will be created.  And triggers turned on.
--                               if false then groups are destroyed and triggers turned off.  Turning off triggers
--                               doesn't delete them.
--
-- TriggerGroups[GroupNumber]    GroupNumber must be sequential. Starts from 1.
--   [1]                         'r' for region.
--                               'a' for all. Will match any groups that have a box number.
--                               'v' for virtual.
--   [2]                         Name of the group.  This is usually the name of the box.
--                               If name is empty ('') then it will use BoxFrames[BoxNumber].Name
--
--   [3][]                       Array containing the valueTypeIDs and ValueTypes. In pairs of 2.
--      [1]                      ValueTypeID
--      [2]                      ValueType
--
--   [4][]                       Array containing data for the group.
--     [1]                       TypeID
--     [2]                       Type
--     [3 and up]                Contains texture numbers or texture frame numbers. Nil if not needed.
--
--     GF                        Add get functions.  This will appear as a sub menu under Type. This is when
--                               You want a trigger to get a value from somewhere else and use it.
--                               Each GetFn is paired up in 2s. So 1 to 2, 3 to 4, 5 to 6, and so on.
--       GF[1]                   GetFnTypeID      Indentifier for the type of GetFunction (used for color)
--                                                This is used to determin what get function to call.
--       GF[2]                   GetFnType        Name that appears in the menus. (used for color)
--     FN                        String. Optional, when you need to use a different function than what the Type uses.
--                               EclipseBar.lua uses this.
--   [5][]                       Array containing the groups being used by the virtual group.  Only
--                               if TriggerGroups[1] = 'v'
--
-- NOTES: When using 'a' for all.  The textures and texture numbers dont actually get used. Instead the group
--        in that slot gets used instead.
--        When using 'v' for virtual.  The textures do get used from the virtual trigger.  But they get displayed
--        in groups place.
-------------------------------------------------------------------------------
function BarDB:EnableTriggers(Enable, TriggerGroups)
  if Enable then
    local Groups = self.Groups
    local Triggers = self.UnitBarF.UnitBar.Triggers

    -- Check if triggers was reset thru reset options
    if Groups and Main.Reset and Triggers[1] == nil then
      UndoTriggers(self)
      self.Groups = nil
      Groups = nil
    end

    -- Groups is nil then create
    if Groups == nil then
      local VirtualGroupList = {}

      Groups = {}
      Groups.LastValues = {}

      for GroupNumber, TriggerGroup in ipairs(TriggerGroups) do
        local Group = {}
        local ValueTypeIDs = {}
        local ValueTypes = {}
        local RValueTypes = {}
        local TypeIDs = {}
        local Types = {}
        local RTypes = {}
        local Objects = {}
        local GroupType = TriggerGroup[1]
        local BoxNumber = -1
        local Name = TriggerGroup[2]

        if type(GroupType) == 'number' then
          BoxNumber = GroupType
          GroupType = 'b'
        end

        Groups[GroupNumber] = Group
        Group.VirtualGroupNumber = 0
        Group.Hidden = false
        Group.BoxNumber = BoxNumber
        Group.GroupType = GroupType
        Group.ValueTypeIDs = ValueTypeIDs
        Group.ValueTypes = ValueTypes
        Group.RValueTypes = RValueTypes
        Group.TypeIDs = TypeIDs
        Group.Types = Types
        Group.RTypes = RTypes
        Group.Objects = Objects

        if Name == '' then
          Group.Name = self.BoxFrames[BoxNumber].Name
        else
          Group.Name = Name
        end

        -- Set value types.
        local VT = TriggerGroup[3]
        local Index = 0

        for ValueIndex = 1, #VT, 2 do
          Index = Index + 1
          local ValueTypeID = VT[ValueIndex]
          local ValueType = VT[ValueIndex + 1]

          ValueTypeIDs[Index] = ValueTypeID
          ValueTypes[Index] = ValueType

          -- Reverse lookup
          ValueTypeIDs[ValueTypeID] = Index
          RValueTypes[strlower(ValueType)] = Index
        end

        -- create object.
        for TypeIndex, TG in ipairs(TriggerGroup[4]) do
          local Object = {}
          local TypeID = TG[1]
          local Type = TG[2]

          Object.Group = Group
          Object.OneTime = {}

          Objects[TypeIndex] = Object

          TypeIDs[TypeIndex] = TypeID
          Types[TypeIndex] = Type

          -- Reverse lookup
          TypeIDs[TypeID] = TypeIndex
          RTypes[strlower(Type)] = TypeIndex

          -- Are there textures?
          if TG[3] then
            local TexN = {}

            Object.TexN = TexN

            -- Set texture number or texture frame numbers.
            for Index = 3, #TG do
              TexN[Index - 2] = TG[Index]
            end
          end

          -- set the function name if FN is not defined.
          local FunctionName = nil

          if TG.FN then
            FunctionName = TG.FN
          else
            FunctionName = TypeIDfn[TypeID]
            if GroupType == 'r' and TypeID ~= 'sound' then
              FunctionName = format('%s%s', FunctionName, 'Region')
            end
          end

          Object.Function = self[FunctionName]
          Object.FunctionName = FunctionName

          -- For animation
          Object.CanAnimate = TypeIDCanAnimate[TypeID] or false

          Object.Restore = false

          -- set function data
          local GF = TG.GF

          if GF then
            local GetFnTypeIDs = {}
            local GetFnTypes = {}
            local GetFn = {}

            Object.GetFnTypeIDs = GetFnTypeIDs
            Object.GetFnTypes = GetFnTypes
            Object.GetFn = GetFn

            local GetFnIndex = 0
            for Index = 1, #GF, 2 do
              local GetFnTypeID = GF[Index]
              local GetFnType = GF[Index + 1]

              GetFnIndex = GetFnIndex + 1

              GetFnTypeIDs[GetFnIndex] = GetFnTypeID
              GetFnTypes[GetFnIndex] = GetFnType
              GetFn[GetFnTypeID] = TypeIDGetfn[GetFnTypeID]

              -- Add reverse lookup
              GetFnTypeIDs[GetFnTypeID] = GetFnIndex
            end
            -- do this for option menus.
            GetFnTypes[#GetFnTypes + 1] = 'None'
            GetFnTypeIDs['none'] = #GetFnTypes
          end
        end

        if GroupType == 'v' then
          local VirtualGroups = {}
          VirtualGroupList[GroupNumber] = VirtualGroups

          for VirtualGroupIndex = 5, #TriggerGroup do
            VirtualGroups[TriggerGroup[VirtualGroupIndex]] = {}
          end
        end
      end

      -- Build virtual groups
      if next(VirtualGroupList) then
        Groups.VirtualGroupList = VirtualGroupList

        for VirtualGroupNumber, VirtualGroups in pairs(VirtualGroupList) do
          for GroupNumber, VirtualGroup in pairs(VirtualGroups) do
            local Group = Groups[GroupNumber]
            local BoxNumber = Group.BoxNumber

            -- only include groups that use boxes
            if BoxNumber > 0 then
              local VirtualObjects = {}

              VirtualGroup.Hidden = true
              VirtualGroup.Name = Group.Name
              VirtualGroup.BoxNumber = BoxNumber
              VirtualGroup.Objects = VirtualObjects

              for Key, Object in pairs(Groups[VirtualGroupNumber].Objects) do
                local Table = {}
                local GroupCopy = Object.Group

                Object.Group = nil

                -- Copy virtual group object
                Main:CopyTableValues(Object, Table, true)

                Object.Group = GroupCopy

                -- Point Group in virtual object to the group.
                Table.Group = VirtualGroup
                Table.Virtual = 1

                VirtualObjects[Key] = Table
              end
            end
          end
        end
      end
    end
    -- Reference and check triggers if something changed.
    if self.Groups == nil or Main.ProfileChanged or Main.CopyPasted then
      self.Groups = Groups
      Groups.Triggers = Triggers
      self:CheckTriggers()
    end
  else
    -- disable triggers
    Main:SetAuraTracker(self.UnitBarF, 'off')

    UndoTriggers(self)
    self.Groups = nil
  end
end

-------------------------------------------------------------------------------
-- CompTriggers
--
-- Checks if a trigger is compatable with another group
--
-- Trigger      Trigger to test.
-- GroupNumber  Group number being tested against
--
-- returns
--   false      If the trigger is not compatable. Otherwise true.
-------------------------------------------------------------------------------
function BarDB:CompTriggers(Trigger, GroupNumber)
  local Group = self.Groups[GroupNumber]

  local TypeIndex = Group.RTypes[strlower(Trigger.Type)] or Group.TypeIDs[Trigger.TypeID] or 0

  return TypeIndex > 0
end

-------------------------------------------------------------------------------
-- CreateDefaultTriggers
--
-- GroupNumber     Creates a trigger thats compatable with this group number.
--
-- returns
--   Trigger       Newly created default trigger
-------------------------------------------------------------------------------
function BarDB:CreateDefaultTriggers(GroupNumber)
  local Group = self.Groups[GroupNumber]
  local Trigger = {}

  Main:CopyTableValues(DUB[self.BarType].Triggers.Default, Trigger, true)

  if not self:CompTriggers(Trigger, GroupNumber) then
    Trigger.TypeID = Group.TypeIDs[1]
    Trigger.Type = strlower(Group.Types[1])
  end

  Trigger.GroupNumber = GroupNumber

  if Trigger.ValueTypeID == '' then
    Trigger.ValueTypeID = Group.ValueTypeIDs[1]
  end
  if Trigger.ValueType == '' then
    Trigger.ValueType = strlower(Group.ValueTypes[1])
  end

  return Trigger
end

-------------------------------------------------------------------------------
-- InsertTriggers
--
-- Trigger   Trigger being inserted
-- Index     Trigger position to insert at. If index is nil then trigger gets
--           added to the end.
-------------------------------------------------------------------------------
function BarDB:InsertTriggers(Trigger, Index)
  local Triggers = self.Groups.Triggers

  if Index == nil then
    Triggers[#Triggers + 1] = Trigger
  else
    tinsert(Triggers, Index, Trigger)
  end

  self:CheckTriggers()
end

-------------------------------------------------------------------------------
-- RemoveTriggers
--
-- Index     Trigger to delete.
-------------------------------------------------------------------------------
function BarDB:RemoveTriggers(Index)
  tremove(self.Groups.Triggers, Index)

  self:CheckTriggers()
end

-------------------------------------------------------------------------------
-- SwapTriggers
--
-- Source, Dest    Swaps triggers with source and dest.  Also checks for group numbers
--
-- returns
--   true          If the triggers were swapped across groups. otherwise false
-------------------------------------------------------------------------------
function BarDB:SwapTriggers(Source, Dest)
  local Triggers = self.Groups.Triggers
  local SourceIndex = Source.Index
  local DestIndex = Dest.Index
  local SourceGroupNumber = Source.GroupNumber
  local DestGroupNumber = Dest.GroupNumber
  local GroupSwap = false

  Triggers[SourceIndex], Triggers[DestIndex] = Triggers[DestIndex], Triggers[SourceIndex]

  -- Check cross group swap
  if SourceGroupNumber ~= DestGroupNumber then
    Source.GroupNumber = DestGroupNumber
    Dest.GroupNumber = SourceGroupNumber
    GroupSwap = true
  end

  self:CheckTriggers()

  return GroupSwap
end

-------------------------------------------------------------------------------
-- MoveTriggers
--
-- Source       Trigger to move. Deletes source after move.
-- GroupNumber  Group number to assign trigger.
-- Index        Position to move trigger to. If nil then adds at the end
--
-- returns
--   Trigger    Newly created copy of the Source.
-------------------------------------------------------------------------------
function BarDB:MoveTriggers(Source, GroupNumber, Index)
  local Triggers = self.Groups.Triggers
  local SourceIndex = Source.Index
  local Trigger = {}

  Main:CopyTableValues(Source, Trigger, true)

  if Index == nil then
    Triggers[#Triggers + 1] = Trigger
  else
    tinsert(Triggers, Index, Trigger)

    -- Check if index has to be offset by 1.
    if Index <= Source.Index then
      SourceIndex = SourceIndex + 1
    end
  end
  Trigger.GroupNumber = GroupNumber

  tremove(Triggers, SourceIndex)

  self:CheckTriggers()

  return Trigger
end

-------------------------------------------------------------------------------
-- CopyTriggers
--
-- Source       Trigger to copy.
-- GroupNumber  Group number to assign trigger.
-- Index        Position to copy trigger to. If nil then adds at the end
--
-- returns
--   Trigger    Newly created copy of the Source.
-------------------------------------------------------------------------------
function BarDB:CopyTriggers(Source, GroupNumber, Index)
  local Triggers = self.Groups.Triggers
  local Trigger = {}

  Main:CopyTableValues(Source, Trigger, true)

  if Index == nil then
    Triggers[#Triggers + 1] = Trigger
  else
    tinsert(Triggers, Index, Trigger)
  end
  Trigger.GroupNumber = GroupNumber

  self:CheckTriggers()

  return Trigger
end

-------------------------------------------------------------------------------
-- AppendTriggers
--
-- Adds triggers from another bar without overwriting the existing ones.
--
-- SourceBarType      Bar the source triggers are coming from.
-------------------------------------------------------------------------------
function BarDB:AppendTriggers(SourceBarType)
  local SourceTriggers = Main.UnitBars[SourceBarType].Triggers
  local SourceBarName = DUB[SourceBarType].Name
  local Triggers = self.UnitBarF.UnitBar.Triggers

  for TriggerIndex = 1, #SourceTriggers do
    local Trigger = {}
    local SourceTrigger = SourceTriggers[TriggerIndex]
    local Name = SourceTrigger.Name

    -- Copy trigger and modify name
    Main:CopyTableValues(SourceTrigger, Trigger, true)
    Trigger.Name = format('[ %s ] %s', SourceBarName, Name)

    -- Append trigger
    Triggers[#Triggers + 1] = Trigger
  end

  -- Cant do check triggers here.
end

-------------------------------------------------------------------------------
-- SetSelectTrigger
--
-- Sets one trigger in a group to be selected. Used by options
--
-- GroupNumber   Group to select a trigger under.
-- Index         Trigger to select.
-------------------------------------------------------------------------------
function BarDB:SetSelectTrigger(GroupNumber, Index)
  local Triggers = self.Groups.Triggers

  for TriggerIndex = 1, #Triggers do
    local Trigger = Triggers[TriggerIndex]

    if Trigger.GroupNumber == GroupNumber then
      if Trigger.Index == Index then
        Trigger.Select = not Trigger.Select
      else
        Trigger.Select = false
      end
    end
  end
end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- SetAuraTriggers
--
-- Called by AuraUpdate()
-------------------------------------------------------------------------------
local function SetAuraTrigger(Execute, LastValues, Object, Trigger)
  local Change = false

  if Execute then
    LastValues[Object] = 1
    Object.AuraTrigger = Trigger
    return true

  elseif Object.AuraTrigger == Trigger then
    Object.OneTime[Trigger] = false
    Object.AuraTrigger = false
    return true

  end
  return false
end

function BarDB:SetAuraTriggers(TrackedAurasList)
  local Groups = self.Groups
  local AuraTriggers = Groups.AuraTriggers
  local LastValues = Groups.LastValues
  local Change = false

  for Index = 1, #AuraTriggers do
    local Trigger = AuraTriggers[Index]
    local Auras = Trigger.Auras
    local Operator = Trigger.AuraOperator
    local NumAuras = 0
    local NumFound = 0

    for SpellID, Aura in pairs(Auras) do
      NumAuras = NumAuras + 1

      local StackOperator = Aura.StackOperator
      local TrackedAuras = TrackedAurasList[Aura.Unit]
      local TrackedAura = TrackedAuras and TrackedAuras[SpellID]

      if TrackedAura and TrackedAura.Active then
        local StackOperator = Aura.StackOperator
        local Stacks = Aura.Stacks
        local TrackedAuraStacks = TrackedAura.Stacks
        local Own = Aura.Own or false

        if (Own and TrackedAura.Own or not Own) and
           (StackOperator == '<'  and TrackedAuraStacks <  Stacks or
            StackOperator == '>'  and TrackedAuraStacks >  Stacks or
            StackOperator == '<=' and TrackedAuraStacks <= Stacks or
            StackOperator == '>=' and TrackedAuraStacks >= Stacks or
            StackOperator == '='  and TrackedAuraStacks == Stacks or
            StackOperator == '<>' and TrackedAuraStacks ~= Stacks   ) then
          NumFound = NumFound + 1
          if Operator == 'or' then -- dont need to check all on 'or'
            break
          end
        elseif Operator == 'and' then
          break
        end
      elseif Operator == 'and' then -- need to stop since it's 'and'
        break
      end
    end

    local GroupNumbers = Trigger.GroupNumbers
    local Execute = NumFound > 0 and ( Operator == 'or' or Operator == 'and' and NumFound == NumAuras )

    local TypeIndex = Trigger.TypeIndex
    local VirtualGroupList = Groups.VirtualGroupList

    if GroupNumbers then

      for GN in pairs(GroupNumbers) do
        local Group = Groups[GN]
        local VirtualGroupNumber = Group.VirtualGroupNumber

        -- Do virtual
        if VirtualGroupNumber ~= 0 then
          if SetAuraTrigger(Execute, LastValues, VirtualGroupList[VirtualGroupNumber][GN].Objects[TypeIndex], Trigger) then
            Change = true
          end
        end

        -- Do normal
        if SetAuraTrigger(Execute, LastValues, Groups[GN].Objects[TypeIndex], Trigger) then
          Change = true
        end
      end
    elseif Trigger.Virtual then
      for _, VirtualGroup in pairs(VirtualGroupList[Trigger.GroupNumber]) do
        if SetAuraTrigger(Execute, LastValues, VirtualGroup.Objects[TypeIndex], Trigger) then
          Change = true
        end
      end
    elseif SetAuraTrigger(Execute, LastValues, Groups[Trigger.GroupNumber].Objects[TypeIndex], Trigger) then
      Change = true
    end
  end

  -- Only call do triggers if theres something to change.
  if Change then
    self:DoTriggers()

    -- Since auras dont get called thru self:update().  A display call has to be done here.
    self:Display()
  end
end

-------------------------------------------------------------------------------
-- SetTriggers
--
-- Usage:  SetTriggers(GroupNumber, ValueType, CompValue)
--         SetTriggers(GroupNumber, ValueType, CurrValue, MaxValue)
--         SetTriggers(GroupNumber, ValueType, true or false)
--         SetTriggers(GroupNumber, 'off', ValueType or nil)
--
-- GroupNumber       Triggers belonging to this group will get executed.
-- ValueType         Type of value. must be lower case. If nil then matches by GroupNumber only.
--                   nil only works with 'off' option.
-- CompValue         Value that each trigger will be compared against.
--                   otherwise this can be nil.
-- CurrValue
-- MaxValue          If these are set then the trigger will work with a percentage.
-- true or false     Matches true or false with the state of the triggers.
-- 'off'             Any trigger matching ValueType will be turned off.  Not case sensitive.
-------------------------------------------------------------------------------
local function SetTrigger(Execute, LastValues, Object, Trigger)
  local Change = false

  if Execute then
    LastValues[Object] = 1
    Object.Trigger = Trigger

  elseif Object.Trigger == Trigger then
    Object.OneTime[Trigger] = false
    Object.Trigger = false
  end
end

function BarDB:SetTriggers(GroupNumber, p2, p3, p4)
  local Groups = self.Groups

  if Groups then
    local Off = false
    local ValueType = nil
    local CompValue = nil
    local CompState = nil

    if p2 == 'off' then
      Off = true
      ValueType = p3
    else
      ValueType = p2

      -- Check for compare state.
      if type(p3) == 'boolean' then
        CompState = p3

      -- Check for Current value and max value
      elseif p4 then
        if p4 == 0 then
          CompValue = 0
        else
          CompValue = ceil(p3 / p4 * 100)
        end
      else
        -- Whole number.
        CompValue = p3
      end
    end
    local Group = Groups[GroupNumber]
    local GroupType = Group.GroupType

    if GroupType == 'v' then
      assert(false, 'BarDB:SetTriggers(): Group can not be type: virtual')
    elseif GroupType == 'a' then
      assert(false, 'BarDB:SetTriggers(): Group can not be type: all')
    end

    local VirtualGroupNumber = Group.VirtualGroupNumber
    local SortedTriggers = Groups.SortedTriggers
    local LastValues = Groups.LastValues
    local VirtualGroupList = Groups.VirtualGroupList
    local Objects = Group.Objects
    local Index = 0

    for Index = 1, #SortedTriggers do
      local Trigger = SortedTriggers[Index]
      local Virtual = Trigger.Virtual
      local GroupNumbers = Trigger.GroupNumbers
      local TriggerGroupNumber = Trigger.GroupNumber

      if Virtual and VirtualGroupNumber == TriggerGroupNumber or
         not Virtual and ( GroupNumbers and GroupNumbers[GroupNumber] or GroupNumber == TriggerGroupNumber ) then

        local TriggerValueType = Trigger.ValueType

        if ( Off and ValueType == nil or TriggerValueType == ValueType ) or ( not Off and TriggerValueType == ValueType ) then
          local Execute = nil

          -- Check for state.
          if CompState ~= nil then
            Execute = not Off and CompState == Trigger.State

          elseif not Off then
            local Conditions = Trigger.Conditions
            local All = Conditions.All
            local NumConditions = #Conditions
            local NumFound = 0

            -- Search thru conditions to find one or more that are true.
            for ConditionIndex = 1, NumConditions do
              local Condition = Conditions[ConditionIndex]
              local Operator = Condition.Operator
              local Value = Condition.Value

              if Operator == '<'  and CompValue <  Value or
                 Operator == '>'  and CompValue >  Value or
                 Operator == '<=' and CompValue <= Value or
                 Operator == '>=' and CompValue >= Value or
                 Operator == '='  and CompValue == Value or
                 Operator == '<>' and CompValue ~= Value then
                NumFound = NumFound + 1
                if not All then -- dont need to check all conditions.
                  break
                end
              elseif All then -- dont need to keep checking since all would have to match.
                break
              end
            end
            Execute = not Off and NumFound > 0 and ( not All or NumFound == NumConditions )
          end
          local TriggerTypeIndex = Trigger.TypeIndex

          -- Apply 'all' triggers to virtual as well.
          if VirtualGroupNumber ~= 0 and ( Virtual or GroupNumbers ) then
            local Object = VirtualGroupList[VirtualGroupNumber][GroupNumber].Objects[TriggerTypeIndex]

            SetTrigger(Execute, LastValues, Object, Trigger)
          end

          -- Do normal triggers.
          if not Virtual or GroupNumbers then
            SetTrigger(Execute, LastValues, Objects[TriggerTypeIndex], Trigger)
          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- HideVirtualGroupTriggers
--
-- Hide or shows a virtual group at groupnumber.
--
-- VirtualGroupNumber   Virtual group.
-- Hide                 If true then the group is hidden otherwise shown.
-- GroupNumber          Location of the normal group.
-------------------------------------------------------------------------------
function BarDB:HideVirtualGroupTriggers(VirtualGroupNumber, Hidden, GroupNumber)
  CalledByTrigger = true

  local Groups = self.Groups
  local VirtualGroupList = Groups.VirtualGroupList
  local VirtualGroup = VirtualGroupList[VirtualGroupNumber][GroupNumber]
  local Group = Groups[GroupNumber]

  if Groups[VirtualGroupNumber].GroupType ~= 'v' then
    assert(false, format('BarDB:HideGroupTriggers(): Group "%s" must be virtual', Group.Name))
  end
  local BoxNumber = Group.BoxNumber

  Group.Hidden = not Hidden
  VirtualGroup.Hidden = Hidden

  if Hidden then
    -- Clear the normal group.
    for _, Object in pairs(Group.Objects) do
      RestoreSettings(self, Object.FunctionName, BoxNumber)
    end

    Group.VirtualGroupNumber = 0
  else
    -- clear the virtual group.
    for _, Object in pairs(VirtualGroup.Objects) do
      RestoreSettings(self, Object.FunctionName, BoxNumber)
    end

    Group.VirtualGroupNumber = VirtualGroupNumber
  end

  CalledByTrigger = false
end

-------------------------------------------------------------------------------
-- DoTriggers
--
-- Executes triggers done by SetTriggers()
-------------------------------------------------------------------------------
function BarDB:DoTriggers()
  CalledByTrigger = true

  local Groups = self.Groups
  local LastValues = Groups.LastValues

  for Object in pairs(LastValues) do
    local Group = Object.Group
    local BoxNumber = Group.BoxNumber
    local Hidden = Group.Hidden
    local Trigger = nil

    -- Get trigger
    if Object.AuraTrigger then
      Trigger = Object.AuraTrigger
    elseif Object.Trigger then
      Trigger = Object.Trigger
    else
      Trigger = Object.StaticTrigger
    end

    -- Execute trigger
    if Trigger then
      local OneTime = Object.OneTime[Trigger]

      if Trigger.OneTime == nil or ( OneTime == nil or not OneTime ) then
        Object.OneTime[Trigger] = true

        local OneTime = Trigger.OneTime

        if not Hidden then
          local Fn = Object.Function
          local AnimateTime = Trigger.AnimateTime
          local Pars = Trigger.Pars
          local GetFnTypeID = Trigger.GetFnTypeID
          local p1, p2, p3, p4 = Pars[1], Pars[2], Pars[3], Pars[4]

          AnimateTimeTrigger = Trigger.CanAnimate and Trigger.Animate and Trigger.AnimateTime or nil

          -- Do get function
          if GetFnTypeID ~= 'none' then
            local GetFn = Object.GetFn

            if GetFn then
              local GetPars = Trigger.GetPars

              -- use nil as first par to fill in 'self'.
              p1, p2, p3, p4 = Object.GetFn[GetFnTypeID](nil, GetPars[1], GetPars[2], GetPars[3], GetPars[4],
                                                                      p1,         p2,         p3,         p4 )
            end
          end
          local TexN = Object.TexN

          if TexN == nil then
            local TextLine = Trigger.TextLine

            -- Check to see if its a text object
            if TextLine then

              -- Do all text lines
              if TextLine == 0 then
                for TextLine = 1, MaxTextLines do
                  Fn(self, BoxNumber, TextLine, p1, p2, p3, p4)
                end
              else
                Fn(self, BoxNumber, TextLine, p1, p2, p3, p4)
              end
            else
              Fn(self, p1, p2, p3, p4)
            end
          else
            local Fn = Object.Function

            -- Do textures.
            for Index = 1, #TexN do
              Fn(self, BoxNumber, TexN[Index], p1, p2, p3, p4)
            end
          end

          -- Animation must be deactivated.
          AnimateTimeTrigger = nil
        end
        Object.Restore = true
      end

    -- no triggers executed so restore the object to its original settings
    elseif Object.Restore then
      Object.Restore = false

      if not Hidden then
        RestoreSettings(self, Object.FunctionName, BoxNumber)
      end
    end
  end

  CalledByTrigger = false
end
