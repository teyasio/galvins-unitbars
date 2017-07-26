--
-- DefaultUB.lua
--
-- Contains the default unitbar profile.
-- And help text.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

GUB.DefaultUB = {}
GUB.DefaultUB.Version = 555

-------------------------------------------------------------------------------
-- UnitBar table data structure.
-- This data is used in the root of the unitbar data table and applies to all bars.  Accessed by UnitBar.Key.
--
-- Point                  - Current location of UnitBarsParent
-- RelativePoint          - Relative point of UIParent for UnitBarsParent.
-- Px, Py                 - The current location of the UnitBarsParent on the screen.
-- EnableClass            - Boolean. If true all unitbars get enabled for your class only.
-- IsGrouped              - Boolean. If true all unitbars get dragged as one object.
--                                         If false each unitbar can be dragged by its self.
-- IsLocked               - Boolean. If true all unitbars can not be clicked on.
-- IsClamped              - Boolean. If true all frames can't be moved off screen.
-- Testing                - Boolean. If true the bars are currently in test mode.
-- BarFillFPS             - Controls the frame rate of statusbar fill animation for timer bars and smooth fill.
--                          Higher values use more cpu.
-- Align                  - Boolean. If true then bars can be aligned.
-- Swap                   - Boolean. If true then bars can swap locations.
-- AlignSwapAdvanced      - Boolean. If true then advanced mode is set for align and swap.
-- AlignSwapPaddingX      - Horizontal padding between aligning bars.
-- AlignSwapPaddingY      - Vertical padding between aligned bars.
-- AlignSwapOffsetX       - Horizontal offset for a aligngroup of frames 2 or more.
-- AlignSwapOffsetY       - Vertical offset for a aligngroup of frames 2 or more.
-- HideTooltips           - Boolean. If true tooltips are not shown when mousing over unlocked bars.
-- HideTooltipsDesc       - Boolean. If true the descriptions inside the tooltips will not be shown when mousing over
-- HideTextHighlight      - Boolean. If true then text frames will not be highlighted when the options are opened.
-- AlignAndSwapEnabled    - Boolean. If true then align and swap can be accessed, otherwise cant be.
-- HideLocationInfo       - Boolean. If true the location information for bars and boxes is not shown in tooltips when mousing over.
-- AnimationType          - string. Type of animation to play when hiding and showing bars.
-- ReverseAnimation       - Boolean. If true then transition from animating in one direction then going to the other is smooth.
-- AnimationOutTime       - Time in seconds before a bar completely goes hidden.
-- AnimationInTime        - Time in seconds before a bar completely becomes visible.
-- HighlightDraggedBar    - Shows a box around the frame currently being dragged.
-- AuraListOn             - If true then the aura list utility is active.
-- AuraListUnits          - String. Contains a list of units seperated by spaces for the aura utility to track.
-- ClassTaggedColor       - Boolean.  If true then if the target is an NPC, then tagged color will be shown.
-- CombatClassColor       - If true then then the combat colors will use player class colors.
-- CombatTaggedColor      - If true then Tagged color will be used along with combat color if the unit is not a player..
-- CombatColor            - Table containing the colors hostile, attack, friendly, flagged, none.
-- PlayerCombatColor      - Same as CombatColor but for players only.
-- PowerColor             - Table containing the power colors, rage, focus, etc.  Set in Main.lua
-- ClassColor             - Table containing the class colors.  Set in Main.lua
-- TaggedTest             - If true then Tagged Color will always show the tagged color.
-- TaggedColor            - Table containing the color for tagged units.
-- Reset                  - Table containing the default settings for Reset found in General options.
--
--
-- Fields found in all unitbars:
--
--   _DC = 0              - This can appear anywhere in the table.  It's used by CopyUnitBar().  If this key is found
--                          in the source and destination during a copy.  It will deepcopy the table instead. Even if the table
--                          being copied is inside of a larger table that has the _DC tag.  Then it will still get deep copied.
--   _<key name>          - Any key that starts with '_' will never get copied even if there is a _DC tag present.
--   Name                 - Name of the bar.
--   UnitType             - Type of unit: 'player', 'pet', 'focus', 'target'
--   Enabled              - If true bar can be used, otherwise disabled.  Will not appear in options.
--   BarVisible()         - Returns true or false.  This gets referenced by UnitBarsF. Not all bars use this. Set in Main.lua
--   UsedByClass          - Contains the data for HideNotUsable flag.  Not all unitbars use this. This is also used for Enable Bar Options and
--                          Triggers for specializations.
--                          Example1: {DRUID = '1234'}
--                            Class has to be druid and any of the 4 specs can be used.
--                          Example2: {DRUID = '12', DEATHKNIGHT = ''}
--                            Class has to be druid or deathknight.  Spec 1 or 2 on the druid has to be used. Deathknight, spec isn't checked.
--                          '0' (zero) can be used for no specialization.
--
--   x, y                 - Current location of the Anchor relative to the UnitBarsParent.
--   Status               - Table that contains a list of flags marked as true or false.
--                          If a flag is found true then a statuscheck will be done to see what the
--                          bar should do. Flags with a higher priority override flags with a lower.
--                          Flags from highest priority to lowest.
--                            HideNotUsable    Disables and hides the unitbar if the bar is not usable
--                                             by class and/or specialization.
--                                             Not everybar has this flag.  If one is present then
--                                             the bar has a UsedByClass table.
--                            ShowAlways       Show the bar all the time.
--                            HideWhenDead     Hide the unitbar when the player is dead.
--                            HideNoTarget     Hide the unitbar when the player has no target.
--                            HideInVehicle    Hide the unitbar if in a vehicle.
--                            HideInPetBattle  Hide the unitbar if in a pet battle.
--                            HideNotActive    Hide the unitbar if its not active. Only checked out of combat.
--                            HideNoCombat     Hide the unitbar when not in combat.
--
--   TestMode             - Table used during test mode.
--   BoxLocations         - Only exists if the bar was set to Floating mode.  Contains the box frame positions.
--   BoxOrder             - Contains the order the boxes are displayed in for each bar.  Not all bars have this.
--
-- Layout                 - Not all bars use every field.
--   BoxMode              - If true the bar uses boxes (statusbars) instead of textures.
--   EnableTriggers       - If true then triggers are activated.
--   HideRegion           - A box with a background thats behind the bar.  If true then this is hidden.
--   Swap                 - If true then boxes inside of a bar can swap locations.
--   Float                - If true then boxes inside of a bar can be moved anywhere on screen.
--   ReverseFill          - If true then a bar fills from right to left.
--   HideText             - If true all text is hidden for this bar.
--   SmoothFillMaxTime    - The amount of time in seconds a smooth fill animation can take. 0 disables smooth fill.
--   SmoothFillSpeed      - 0.01 to 1. 0.01 is slowest, 1 is fastest.
--   BorderPadding        - Amount of pixel distance between the regions border and boxes inside the bar.
--   Rotation             - Angle in degrees the bar is drawn in from 45 to 360 in 45 degree increments.
--   Slope                - Tilts the bar up or down only when the bar is at 90, 180, 270, or 360 degrees.
--   Padding              - Distance in pixels between each box inside a bar.
--   TextureScale         - Scale of a texture when a bar is in not in boxmode.  Also the size of the runes for the runebar.
--   AnimationInTime      - Amount of time to play animation after showing a texture or box texture.
--   AnimationOutTime     - Amount of time to play animation before hiding a texture or box texture.
--   Align                - If true then boxes in a bar can be aligned.
--   AlignPaddingX        - Horizontal distance between each box when aligning.
--   AlignPaddingY        - Vertical distance between each box when aligning.
--   AlignOffsetX         - Horizontal offset for a group of aligned boxes 2 or more.
--   AlignOffsetY         - Vertical offset for a group of aligned boxes 2 or more.
--
--   _More                - If present then More layout options will appear in Layout.
--
-- More Layout (Health and power bars)
--   PredictedHealth      - Boolean.  Used by health bars only.
--                                    If true then predicted health will be shown.
--   ClassColor           - Boolean.  Used by health bars only.
--                                    If true then class color will be shown
--   CombatColor          - Boolean.  Used by health bars only.
--                                    If true then combat color will be shown
--   TaggedColor          - Boolean.  Used by health bars only.
--                                    If true then a tagged color will be shown if unit is tagged.
--
--   PredictedHealth      - Boolean.  Used by health bars.  If true then incoming healing will be shown.
--   PredictedPower       - Boolean.  Used by Player Power.  If true predicted power will be shown.
--   PredictedCost        - Boolean.  Used by power bars and Mana Power.  If true then cost of a spell with a cast time will be shown.
--
-- More Layout (Rune Bar)
--
--   RuneMode             - 'rune'     Only rune textures are shown.
--                          'bar'      Cooldown bars only are shown.
--                          'runebar'  Rune and a Cooldown bar are shown.
--   CooldownLine         - Boolean.  If true then a line is drawn on the cooldown texture.
--   BarSpark             - Boolean.  If true a spark is drawn on bar.
--   HideCooldownFlash    - Boolean.  If true a flash cooldown animation is not shown when a rune comes off cooldown.
--   CooldownAnimation    - Boolean.  If false cooldown animation is not shown.
--   RunePosition         - Frame position of the rune attached to bar.  When bars and runes are shown.
--   RuneOffsetX          - Horizontal offset from RunePosition.
--   RuneOffsetY          - Vertical offset from RunePosition.
--
-- Attributes             - Makes changes to the bar, every bar has this.
--   Scale                - Sets the scale of the unitbar frame.
--   Alpha                - Sets the transparency of the unitbar frame.
--   AnchorPoint          - Sets which point the anchor will use.
--   FrameStrata          - Sets the strata for the frame to appear on.
--   MainAnimationType    - true or false.  If true then uses the animation type settings in General -> Main.
--   AnimationTypeBar     - This setting gets used if MainAnimationType is false.

--
-- Region, Background*    - Not every bar has this.
--   PaddingAll           - If true then one value sets all 4 padding values.
--   BgTexture            - Name of the background texture in sharedmedia.
--   BorderTexture        - Name of the forground texture in sharedmedia.
--   BgTile               - True or false. If true then the background is tiled, otherwise not tiled.
--   BgTileSize           - Size (width or height) of the square repeating background tiles (in pixels).
--   BorderSize           - Size of the border texture thickness in pixels.
--   Padding
--     Left, Right,
--     Top, Bottom        - Positive values go inwards, negative values outward.
--   Color                - Table. Contains color for multiple boxes or for one.
--   EnableBorderColor    - If true then the border color can be changed.
--   BorderColor          - Table. This gets used for the border color if Enabled.
--
-- Bar
--   Advanced             - If true then the bar can size can be changed with small movements.
--   Width                - Width of the bar in box mode.
--   Height               - Height of the bar in box mode.
--   FillDirection        - 'HORIZONTAL' or 'VERTICAL'
--   RotateTexture        - if true then the statusbar texture is rotated vertically.
--   PaddingAll           - If true then one value sets all 4.
--   Padding
--
--     Left, Right        - Negative values go left.
--     Top, Bottom        - Negative values go down.
--   StatusBarTexture     - Texture used for the statusbar
--                          Health and Power bars used additional StatusBar textures.
--   Color                - Table, contains the color for one or more status bars.

-- Text                   - Text settings used for displaying numerical or string.
--   _Multi                 If key is not present then no text lines can be created.
--   _ValueNameMenu       - Tells the options what kind of menu to use for this bar.
--
--   [x]                  - Each array element is a text line (fontstring).
--                          If mutli is false or not present. Then [1] is used.
--
--     Custom             - If true a user inputed layout is used instead of one being automatically generated.
--     Layout             - Layout used in string.format for displaying the values.
--     ValueNames         - An array of strings that tell what each position will display.
--     ValueTypes         - Tells how the value will be displayed.
--
--     FontType           - Type of font to use.
--     FontSize           - Size of the font.
--     FontStyle          - Contains flags seperated by a comma: MONOCHROME, OUTLINE, THICKOUTLINE
--     FontHAlign         - Horizontal alignment.  LEFT  CENTER  RIGHT
--     Position           - Position relative to the font's parent.  Can be one of the 9 standard setpoints.
--     FontPosition       - Same as Position except its relative to Position.
--     Width              - Field width for the font.
--     OffsetX            - Horizontal offset position of the frame.
--     OffsetY            - Vertical offset position of the frame.
--     ShadowOffset       - Number of pixels to move the shadow towards the bottom right of the font.
--     Color              - Color of the text.  This also supports 'color all' for bars like runebar.
--
-- Triggers               - See Bar.lua triggers
--
-------------------------------------------------------------------------------
local DefaultBgTexture = 'Blizzard Tooltip'
local DefaultBorderTexture = 'Blizzard Tooltip'
local DefaultStatusBarTexture = 'Blizzard'
local GUBStatusBarTexture = 'GUB Bright Bar'
local DefaultSound = 'None'
local DefaultSoundChannel = 'SFX'
local UBFontType = 'Arial Narrow'
local DefaultAnimationType = 'alpha'
local DefaultAnimationOutTime = 0.7
local DefaultAnimationInTime = 0.30

GUB.DefaultUB.InCombatOptionsMessage = "Can't have options opened during combat"

GUB.DefaultUB.DefaultBgTexture = DefaultBgTexture
GUB.DefaultUB.DefaultBorderTexture = DefaultBorderTexture
GUB.DefaultUB.DefaultStatusBarTexture = DefaultStatusBarTexture
GUB.DefaultUB.DefaultSound = DefaultSound
GUB.DefaultUB.DefaultSoundChannel = DefaultSoundChannel
GUB.DefaultUB.DefaultFontType = UBFontType

GUB.DefaultUB.TriggerTypes = {
  TypeID_BackgroundBorder      = 'border',          Type_BackgroundBorder      = 'BG Border',
  TypeID_BackgroundBorderColor = 'bordercolor',     Type_BackgroundBorderColor = 'BG Border Color',
  TypeID_BackgroundBackground  = 'background',      Type_BackgroundBackground  = 'BG Background',
  TypeID_BackgroundColor       = 'backgroundcolor', Type_BackgroundColor       = 'BG Background Color',
  TypeID_BarTexture            = 'bartexture',      Type_BarTexture            = 'Bar Texture',
  TypeID_BarColor              = 'bartexturecolor', Type_BarColor              = 'Bar Color',
  TypeID_TextureScale          = 'texturescale',    Type_TextureScale          = 'Texture Scale',
  TypeID_BarOffset             = 'baroffset',       Type_BarOffset             = 'Bar Offset',
  TypeID_TextFontColor         = 'fontcolor',       Type_TextFontColor         = 'Text Font Color',
  TypeID_TextFontOffset        = 'fontoffset',      Type_TextFontOffset        = 'Text Font Offset',
  TypeID_TextFontSize          = 'fontsize',        Type_TextFontSize          = 'Text Font Size',
  TypeID_TextFontType          = 'fonttype',        Type_TextFontType          = 'Text Font Type',
  TypeID_TextFontStyle         = 'fontstyle',       Type_TextFontStyle         = 'Text Font Style',
  TypeID_RegionBorder          = 'border',          Type_RegionBorder          = 'Region Border',
  TypeID_RegionBorderColor     = 'bordercolor',     Type_RegionBorderColor     = 'Region Border Color',
  TypeID_RegionBackground      = 'background',      Type_RegionBackground      = 'Region Background',
  TypeID_RegionBackgroundColor = 'backgroundcolor', Type_RegionBackgroundColor = 'Region Background Color',
  TypeID_Sound                 = 'sound',           Type_Sound                 = 'Sound',

  TypeID_ClassColor  = 'classcolor',  Type_ClassColor  = 'Class Color',
  TypeID_PowerColor  = 'powercolor',  Type_PowerColor  = 'Power Color',
  TypeID_CombatColor = 'combatcolor', Type_CombatColor = 'Combat Color',
  TypeID_TaggedColor = 'taggedcolor', Type_TaggedColor = 'Tagged Color',
}

GUB.DefaultUB.Default = {
  profile = {
    Point = 'CENTER',
    RelativePoint = 'CENTER',
    Px = 0,
    Py = 0,
    EnableClass = true,
    IsGrouped = false,
    IsLocked = false,
    IsClamped = true,
    Testing = false,
    BarFillFPS = 60,
    Align = false,
    Swap = false,
    AlignSwapAdvanced = false,
    AlignSwapPaddingX = 0,
    AlignSwapPaddingY = 0,
    AlignSwapOffsetX = 0,
    AlignSwapOffsetY = 0,
    HideTooltips = false,
    HideTooltipsDesc = false,
    HideTextHighlight = false,
    AlignAndSwapEnabled = true,
    HideLocationInfo = false,
    ReverseAnimation = true,
    AnimationType = 'alpha',
    AnimationInTime = DefaultAnimationInTime,
    AnimationOutTime = DefaultAnimationOutTime,
    HighlightDraggedBar = false,
    AuraListOn = false,
    AuraListUnits = 'player',
    DebugOn = false,
    ClassTaggedColor = false,
    CombatClassColor = false,
    CombatTaggedColor = false,
    CombatColor = {
      Hostile  = {r = 1, g = 0, b = 0, a = 1},  -- Red
      Attack   = {r = 1, g = 1, b = 0, a = 1},  -- Yellow Can attack, but can't attack you
      Friendly = {r = 0, g = 1, b = 0, a = 1},  -- green  unit is friendly
    },
    PlayerCombatColor = {
      Hostile  = {r = 1, g = 0, b = 0, a = 1},  -- Red
      Attack   = {r = 1, g = 1, b = 0, a = 1},  -- Yellow Can attack, but can't attack you
      Flagged  = {r = 0, g = 1, b = 0, a = 1},  -- Green  player is flagged of same faction
      Friendly = {r = 0, g = 0, b = 1, a = 1},  -- Blue   player not engaged in pvp
    },
    TaggedTest = false,
    TaggedColor = {r = 0.5, g = 0.5, b = 0.5, a = 1},  -- grey
    Reset = {Minimize = false},
-- Player Health
    PlayerHealth = {
      Name = 'Player Health',
      OptionOrder = 1,
      UnitType = 'player',
      Enabled = true,
      UsedByClass = {DEATHKNIGHT = '', DEMONHUNTER = '', DRUID = '', HUNTER = '', MAGE    = '', MONK    = '',
                     PALADIN     = '', PRIEST      = '', ROGUE = '', SHAMAN = '', WARLOCK = '', WARRIOR = '' },
      x = -200,
      y = 230,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        PredictedHealth = 0.25,
        UnitLevel = 1,
        ScaledLevel = 1
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.15,

        _More = 1,

        PredictedHealth = true,
        ClassColor = false,
        CombatColor = false,
        TaggedColor = false,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Bar = {
        Advanced = false,
        Width = 170,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedBarTexture = DefaultStatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
        PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'health',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'current'},
          ValueTypes = {'whole'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- Player Power
    PlayerPower = {
      Name = 'Player Power',
      OptionOrder = 2,
      UnitType = 'player',
      Enabled = true,
      UsedByClass = {DEATHKNIGHT = '', DEMONHUNTER = '', DRUID = '', HUNTER = '', MAGE    = '', MONK    = '',
                     PALADIN     = '', PRIEST      = '', ROGUE = '', SHAMAN = '', WARLOCK = '', WARRIOR = '' },
      x = -200,
      y = 200,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.25,
        PredictedPower = 0.25,
        PredictedCost = 0.25,
        UnitLevel = 1,
        ScaledLevel = 1,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.2,

        _More = 1,

        PredictedPower = true,
        PredictedCost = true,
        UseBarColor = false,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Bar = {
        Advanced = false,
        Width = 170,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedBarTexture = DefaultStatusBarTexture,
        PredictedCostBarTexture = DefaultStatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
        PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
        PredictedCostColor = {r = 0, g = 0.447, b = 1, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'power',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'current'},
          ValueTypes = {'whole'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- Target Health
    TargetHealth = {
      Name = 'Target Health',
      OptionOrder = 3,
      UnitType = 'target',
      Enabled = true,
      UsedByClass = {DEATHKNIGHT = '', DEMONHUNTER = '', DRUID = '', HUNTER = '', MAGE    = '', MONK    = '',
                     PALADIN     = '', PRIEST      = '', ROGUE = '', SHAMAN = '', WARLOCK = '', WARRIOR = '' },
      x = -200,
      y = 170,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        PredictedHealth = 0.25,
        UnitLevel = 1,
        ScaledLevel = 1,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.15,

        _More = 1,

        PredictedHealth = true,
        ClassColor = false,
        CombatColor = false,
        TaggedColor = false,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Bar = {
        Advanced = false,
        Width = 170,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedBarTexture = DefaultStatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
        PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
        TaggedColor = {r = 0.5, g = 0.5, b = 0.5, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'health',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'current'},
          ValueTypes = {'whole'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- Target Power
    TargetPower = {
      Name = 'Target Power',
      OptionOrder = 4,
      UnitType = 'target',
      Enabled = true,
      UsedByClass = {DEATHKNIGHT = '', DEMONHUNTER = '', DRUID = '', HUNTER = '', MAGE    = '', MONK    = '',
                     PALADIN     = '', PRIEST      = '', ROGUE = '', SHAMAN = '', WARLOCK = '', WARRIOR = '' },
      x = -200,
      y = 140,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        UnitLevel = 1,
        ScaledLevel = 1,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.15,

        _More = 1,

        UseBarColor = false,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Bar = {
        Advanced = false,
        Width = 170,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'hap',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'current'},
          ValueTypes = {'whole'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- Focus Health
    FocusHealth = {
      Name = 'Focus Health',
      OptionOrder = 5,
      UnitType = 'focus',
      Enabled = true,
      UsedByClass = {DEATHKNIGHT = '', DEMONHUNTER = '', DRUID = '', HUNTER = '', MAGE    = '', MONK    = '',
                     PALADIN     = '', PRIEST      = '', ROGUE = '', SHAMAN = '', WARLOCK = '', WARRIOR = '' },
      x = -200,
      y = 110,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        PredictedHealth = 0.25,
        UnitLevel = 1,
        ScaledLevel = 1,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.15,

        _More = 1,

        PredictedHealth = true,
        ClassColor = false,
        CombatColor = false,
        TaggedColor = false,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Bar = {
        Advanced = false,
        Width = 170,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedBarTexture = DefaultStatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
        PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
        TaggedColor = {r = 0.5, g = 0.5, b = 0.5, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'health',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'current'},
          ValueTypes = {'whole'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- Focus Power
    FocusPower = {
      Name = 'Focus Power',
      OptionOrder = 6,
      UnitType = 'focus',
      Enabled = true,
      UsedByClass = {DEATHKNIGHT = '', DEMONHUNTER = '', DRUID = '', HUNTER = '', MAGE    = '', MONK    = '',
                     PALADIN     = '', PRIEST      = '', ROGUE = '', SHAMAN = '', WARLOCK = '', WARRIOR = '' },
      x = -200,
      y = 80,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        UnitLevel = 1,
        ScaledLevel = 1,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.15,

        _More = 1,

        UseBarColor = false,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Bar = {
        Advanced = false,
        Width = 170,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'hap',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'current'},
          ValueTypes = {'whole'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- Pet Health
    PetHealth = {
      Name = 'Pet Health',
      OptionOrder = 7,
      OptionText = 'Classes with pets only',
      UnitType = 'pet',
      Enabled = true,
      UsedByClass = {ROGUE = '2', DEATHKNIGHT = '', MAGE = '3', WARLOCK = '', HUNTER = ''},
      x = -200,
      y = 50,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        PredictedHealth = 0.25,
        UnitLevel = 1,
        ScaledLevel = 1,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.15,

        _More = 1,

        PredictedHealth = true,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Bar = {
        Advanced = false,
        Width = 170,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedBarTexture = DefaultStatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
        PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'health',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'current'},
          ValueTypes = {'whole'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- Pet Power
    PetPower = {
      Name = 'Pet Power',
      OptionOrder = 8,
      OptionText = 'Classes with pets only',
      UnitType = 'pet',
      Enabled = true,
      UsedByClass = {ROGUE = '2', DEATHKNIGHT = '', MAGE = '3', WARLOCK = '', HUNTER = ''},
      x = -200,
      y = 20,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        UnitLevel = 1,
        ScaledLevel = 1,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.15,

        _More = 1,

        UseBarColor = false,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Bar = {
        Advanced = false,
        Width = 170,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'hap',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'current'},
          ValueTypes = {'whole'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- Mana Power
    ManaPower = {
      Name = 'Mana Power',
      OptionOrder = 9,
      OptionText = 'Druid, Priest, Shaman, or Monk only: Shown when normal mana bar is not available',
      UnitType = 'player',
      Enabled = true,
      UsedByClass = {DRUID = '', MONK = '', PRIEST = '', SHAMAN = ''},
      x = -200,
      y = -10,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        PredictedCost = 0.25,
        UnitLevel = 1,
        ScaledLevel = 1,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.15,

        _More = 1,

        PredictedCost = true,
        UseBarColor = false,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Bar = {
        Advanced = false,
        Width = 170,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        PredictedCostBarTexture = DefaultStatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
        PredictedCostColor = {r = 0, g = 0.447, b = 1, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'mana',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'current'},
          ValueTypes = {'whole'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- StaggerBar
    StaggerBar = {
      Name = 'Stagger Bar',
      OptionOrder = 10,
      UnitType = 'player',
      Enabled = true,
      UsedByClass = {MONK = '1'},
      x = -200,
      y = -40,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        StaggerPercent = 0,
        StaggerPause = 0,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        HideTextPause = false,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.15,
        Swap = false,
        Float = false,
        Rotation = 360,
        Padding = 0,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,

        _More = 1,

        Layered = true,
        Overlay = false,
        SideBySide = false,
        PauseTimer = false,
        PauseTimerAutoHide = false,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      BackgroundStagger = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      BackgroundPause = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0, g = 0, b = 0, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      BarStagger = {
        Advanced = false,
        Width = 170,
        Height = 25,
        MaxPercent = 1,
        MaxPercentBStagger = 2,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        BStaggerBarTexture = DefaultStatusBarTexture,
        Color = {r = 0.52, g = 1, b = 0.52, a = 1},
        BStaggerColor = {r = 1, g = 0.42, b = 0.42, a = 1},
      },
      BarPause = {
        Advanced = false,
        Width = 170,
        Height = 20,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = DefaultStatusBarTexture,
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'stagger',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'current'},
          ValueTypes = {'percent'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Text2 = { -- Pause Timer
        _ValueNameMenu = 'staggerpause',

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'time'},
          ValueTypes = {'timeSS'},

          FontType = UBFontType,
          FontSize = 14,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 200,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- RuneBar
    RuneBar = {
      Name = 'Rune Bar',
      OptionOrder = 11,
      Enabled = true,
      UsedByClass = {DEATHKNIGHT = ''},
      x = 0,
      y = 229,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        BloodSpec = false,
        FrostSpec = true,
        UnHolySpec = false,
        RuneTime = 0,
        RuneOnCooldown = 1,
      },
      Layout = {
        EnableTriggers = false,
        HideRegion = false,
        ReverseFill = false,
        HideText = false,
        Swap = false,
        Float = false,
        BorderPadding = 6,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,

        _More = 1,

        RuneMode = 'rune',
        CooldownLine = true,
        BarSpark = false,
        CooldownFlash = true,
        CooldownAnimation = true,
        RunePosition = 'LEFT',
        RuneOffsetX = 0,
        RuneOffsetY = 0,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Region = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0.2, g = 0.2, b = 0.2, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        ColorAllSelect = {bg = 'Frost', border = 'Frost'},
        ColorBlood = {
          All = false,
          r = 0, g = 0, b = 0, a = 1,        -- All runes
          {r = 0, g = 0, b = 0, a = 1,},     -- 1
          {r = 0, g = 0, b = 0, a = 1,},     -- 2
          {r = 0, g = 0, b = 0, a = 1,},     -- 3
          {r = 0, g = 0, b = 0, a = 1,},     -- 4
          {r = 0, g = 0, b = 0, a = 1,},     -- 5
          {r = 0, g = 0, b = 0, a = 1,},     -- 6
        },
        ColorFrost = {
          All = false,
          r = 0, g = 0, b = 0, a = 1,        -- All runes
          {r = 0, g = 0, b = 0, a = 1,},     -- 1
          {r = 0, g = 0, b = 0, a = 1,},     -- 2
          {r = 0, g = 0, b = 0, a = 1,},     -- 3
          {r = 0, g = 0, b = 0, a = 1,},     -- 4
          {r = 0, g = 0, b = 0, a = 1,},     -- 5
          {r = 0, g = 0, b = 0, a = 1,},     -- 6
        },
        ColorUnholy = {
          All = false,
          r = 0, g = 0, b = 0, a = 1,        -- All runes
          {r = 0, g = 0, b = 0, a = 1,},     -- 1
          {r = 0, g = 0, b = 0, a = 1,},     -- 2
          {r = 0, g = 0, b = 0, a = 1,},     -- 3
          {r = 0, g = 0, b = 0, a = 1,},     -- 4
          {r = 0, g = 0, b = 0, a = 1,},     -- 5
          {r = 0, g = 0, b = 0, a = 1,},     -- 6
        },
        EnableBorderColor = false,
        BorderColorBlood = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,        -- All runes
          {r = 1, g = 1, b = 1, a = 1,},     -- 1
          {r = 1, g = 1, b = 1, a = 1,},     -- 2
          {r = 1, g = 1, b = 1, a = 1,},     -- 3
          {r = 1, g = 1, b = 1, a = 1,},     -- 4
          {r = 1, g = 1, b = 1, a = 1,},     -- 5
          {r = 1, g = 1, b = 1, a = 1,},     -- 6
        },
        BorderColorFrost = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,        -- All runes
          {r = 1, g = 1, b = 1, a = 1,},     -- 1
          {r = 1, g = 1, b = 1, a = 1,},     -- 2
          {r = 1, g = 1, b = 1, a = 1,},     -- 3
          {r = 1, g = 1, b = 1, a = 1,},     -- 4
          {r = 1, g = 1, b = 1, a = 1,},     -- 5
          {r = 1, g = 1, b = 1, a = 1,},     -- 6
        },
        BorderColorUnholy = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,        -- All runes
          {r = 1, g = 1, b = 1, a = 1,},     -- 1
          {r = 1, g = 1, b = 1, a = 1,},     -- 2
          {r = 1, g = 1, b = 1, a = 1,},     -- 3
          {r = 1, g = 1, b = 1, a = 1,},     -- 4
          {r = 1, g = 1, b = 1, a = 1,},     -- 5
          {r = 1, g = 1, b = 1, a = 1,},     -- 6
        },
      },
      Bar = {
        Advanced = false,
        Width = 40,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        ColorAllSelect = {bar = 'Frost'},
        ColorBlood = {
          All = false,
          r = 0.937, g = 0.156, b = 0.031, a = 1,       -- All runes
          {r = 0.937, g = 0.156, b = 0.031, a = 1},     -- 1
          {r = 0.937, g = 0.156, b = 0.031, a = 1},     -- 2
          {r = 0.937, g = 0.156, b = 0.031, a = 1},     -- 3
          {r = 0.937, g = 0.156, b = 0.031, a = 1},     -- 4
          {r = 0.937, g = 0.156, b = 0.031, a = 1},     -- 5
          {r = 0.937, g = 0.156, b = 0.031, a = 1},     -- 6
        },
        ColorFrost = {
          All = false,
          r = 0.419, g = 0.713, b = 0.937, a = 1,       -- All runes
          {r = 0.419, g = 0.713, b = 0.937, a = 1},     -- 1
          {r = 0.419, g = 0.713, b = 0.937, a = 1},     -- 2
          {r = 0.419, g = 0.713, b = 0.937, a = 1},     -- 3
          {r = 0.419, g = 0.713, b = 0.937, a = 1},     -- 4
          {r = 0.419, g = 0.713, b = 0.937, a = 1},     -- 5
          {r = 0.419, g = 0.713, b = 0.937, a = 1},     -- 6
        },
        ColorUnholy = {
          All = false,
          r = 0.678, g = 0.905, b = 0.290, a = 1,       -- All runes
          {r = 0.678, g = 0.905, b = 0.290, a = 1},     -- 1
          {r = 0.678, g = 0.905, b = 0.290, a = 1},     -- 2
          {r = 0.678, g = 0.905, b = 0.290, a = 1},     -- 3
          {r = 0.678, g = 0.905, b = 0.290, a = 1},     -- 4
          {r = 0.678, g = 0.905, b = 0.290, a = 1},     -- 5
          {r = 0.678, g = 0.905, b = 0.290, a = 1},     -- 6
        },
      },
      Text = {
        _ValueNameMenu = 'rune',

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueNames = {'time'},
          ValueTypes = {'timeSS'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 50,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {
            All = false,
            r = 1, g = 1, b = 1, a = 1,      -- All runes
            {r = 1, g = 1, b = 1, a = 1},    -- 1
            {r = 1, g = 1, b = 1, a = 1},    -- 2
            {r = 1, g = 1, b = 1, a = 1},    -- 3
            {r = 1, g = 1, b = 1, a = 1},    -- 4
            {r = 1, g = 1, b = 1, a = 1},    -- 5
            {r = 1, g = 1, b = 1, a = 1},    -- 6
          },
        },
      },
      Triggers = {
        _DC = 0,
        Notes = 'Empowered uses the Time settings from Empowerment in Layout settings.\nEven if turned off',
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '=', Value = 1} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- ComboBar
    ComboBar = {
      Name = 'Combo Bar',
      OptionOrder = 12,
      Enabled = true,
      UsedByClass = {ROGUE = '', DRUID = ''},
      x = 0,
      y = 195,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        ComboPoints = 0,
        DeeperStratagem = false,
        Anticipation = false,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        Swap = false,
        Float = false,
        BorderPadding = 6,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        AnimationType = DefaultAnimationType,
        AnimationInTime = DefaultAnimationInTime,
        AnimationOutTime = DefaultAnimationOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,

        _More = 1,

        TextureScaleCombo = 1,
        TextureScaleAnticipation = 1,
        InactiveAnticipationAlpha = 1,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Region = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0.176, g = 0.160, b = 0.094, a = 1},
        EnabelBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      BackgroundCombo = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {
          All = false,
          r = 0, g = 0, b = 0, a = 1,
          {r = 0, g = 0, b = 0, a = 1},  -- Combo point 1
          {r = 0, g = 0, b = 0, a = 1},  -- Combo point 2
          {r = 0, g = 0, b = 0, a = 1},  -- Combo point 3
          {r = 0, g = 0, b = 0, a = 1},  -- Combo point 4
          {r = 0, g = 0, b = 0, a = 1},  -- Combo point 5
          {r = 0, g = 0, b = 0, a = 1},  -- Combo point 6
        },
        EnableBorderColor = false,
        BorderColor = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,
          {r = 1, g = 1, b = 1, a = 1},  -- Combo point 1
          {r = 1, g = 1, b = 1, a = 1},  -- Combo point 2
          {r = 1, g = 1, b = 1, a = 1},  -- Combo point 3
          {r = 1, g = 1, b = 1, a = 1},  -- Combo point 4
          {r = 1, g = 1, b = 1, a = 1},  -- Combo point 5
          {r = 1, g = 1, b = 1, a = 1},  -- Combo point 6
        },
      },
      BackgroundAnticipation = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {
          _Offset = 6,
          All = false,
          r = 0, g = 0, b = 0, a = 1,
          {r = 0, g = 0, b = 0, a = 1},  -- Anticipation point 1
          {r = 0, g = 0, b = 0, a = 1},  -- Anticipation point 2
          {r = 0, g = 0, b = 0, a = 1},  -- Anticipation point 3
          {r = 0, g = 0, b = 0, a = 1},  -- Anticipation point 4
          {r = 0, g = 0, b = 0, a = 1},  -- Anticipation point 5
        },
        EnableBorderColor = false,
        BorderColor = {
          _Offset = 6,
          All = false,
          r = 1, g = 1, b = 1, a = 1,
          {r = 1, g = 1, b = 1, a = 1},  -- Anticipation point 1
          {r = 1, g = 1, b = 1, a = 1},  -- Anticipation point 2
          {r = 1, g = 1, b = 1, a = 1},  -- Anticipation point 3
          {r = 1, g = 1, b = 1, a = 1},  -- Anticipation point 4
          {r = 1, g = 1, b = 1, a = 1},  -- Anticipation point 5
        },
      },
      BarCombo = {
        Advanced = false,
        Width = 40,
        Height = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
          r = 0.784, g = 0.031, b = 0.031, a = 1,
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Combo point 1
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Combo point 2
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Combo point 3
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Combo point 4
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Combo point 5
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Combo point 6
        },
      },
      BarAnticipation = {
        Advanced = false,
        Width = 40,
        Height = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          _Offset = 6,
          All = false,
          r = 0.784, g = 0.031, b = 0.031, a = 1,
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Anticipation point 1
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Anticipation point 2
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Anticipation point 3
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Anticipation point 4
          {r = 0.784, g = 0.031, b = 0.031, a = 1}, -- Anticipation point 5
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- HolyBar
    HolyBar = {
      Name = 'Holy Bar',
      OptionOrder = 13,
      Enabled = true,
      UsedByClass = {PALADIN = '3'},
      x = 0,
      y = 154,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        HolyPower = 0,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        Swap = false,
        Float = false,
        BorderPadding = 6,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        AnimationType = DefaultAnimationType,
        AnimationInTime = DefaultAnimationInTime,
        AnimationOutTime = DefaultAnimationOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Region = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0.5, g = 0.5, b = 0.5, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {
          All = false,
          r = 0.121, g = 0.121, b = 0.121, a = 1,
          {r = 0.121, g = 0.121, b = 0.121, a = 1}, -- 1
          {r = 0.121, g = 0.121, b = 0.121, a = 1}, -- 2
          {r = 0.121, g = 0.121, b = 0.121, a = 1}, -- 3
          {r = 0.121, g = 0.121, b = 0.121, a = 1}, -- 4
          {r = 0.121, g = 0.121, b = 0.121, a = 1}, -- 5
        },
        EnableBorderColor = false,
        BorderColor = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,
          {r = 1, g = 1, b = 1, a = 1},  -- 1
          {r = 1, g = 1, b = 1, a = 1},  -- 2
          {r = 1, g = 1, b = 1, a = 1},  -- 3
          {r = 1, g = 1, b = 1, a = 1},  -- 4
          {r = 1, g = 1, b = 1, a = 1},  -- 5
        },
      },
      Bar = {
        Advanced = false,
        Width = 40,
        Height = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
          r = 1, g = 0.705, b = 0, a = 1,
          {r = 1, g = 0.705, b = 0, a = 1}, -- 1
          {r = 1, g = 0.705, b = 0, a = 1}, -- 2
          {r = 1, g = 0.705, b = 0, a = 1}, -- 3
          {r = 1, g = 0.705, b = 0, a = 1}, -- 4
          {r = 1, g = 0.705, b = 0, a = 1}, -- 5
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- ShardBar
    ShardBar = {
      Name = 'Shard Bar',
      OptionOrder = 14,
      Enabled = true,
      UsedByClass = {WARLOCK = '12'},
      x = 0,
      y = 112,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        SoulShards = 0,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        Swap = false,
        Float = false,
        BorderPadding = 6,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        AnimationType = DefaultAnimationType,
        AnimationInTime = DefaultAnimationInTime,
        AnimationOutTime = DefaultAnimationOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Region = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0.266, g = 0.290, b = 0.274, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {
          All = false,
          r = 0.329, g = 0.172, b = 0.337, a = 1,
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 1
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 2
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 3
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 4
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 5
        },
        EnableBorderColor = false,
        BorderColor = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,
          {r = 1, g = 1, b = 1, a = 1},  -- 1
          {r = 1, g = 1, b = 1, a = 1},  -- 2
          {r = 1, g = 1, b = 1, a = 1},  -- 3
          {r = 1, g = 1, b = 1, a = 1},  -- 4
          {r = 1, g = 1, b = 1, a = 1},  -- 5
        },
      },
      Bar = {
        Advanced = false,
        Width = 25,
        Height = 32,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
          r = 0.980, g = 0.517, b = 1, a = 1,
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 1
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 2
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 3
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 4
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 5
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- FragmentBar
    FragmentBar = {
      Name = 'Fragment Bar',
      OptionOrder = 15,
      OptionText = 'Destruction Warlocks only',
      Enabled = true,
      UsedByClass = {WARLOCK = '3'},
      x = 150,
      y = 112,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        ShowFull = true,
        ShardFragments = 0,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        ReverseFill = false,
        FillDirection = 'VERTICAL',
        Swap = false,
        Float = false,
        BorderPadding = 6,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        AnimationType = DefaultAnimationType,
        AnimationInTime = DefaultAnimationInTime,
        AnimationOutTime = DefaultAnimationOutTime,
        SmoothFillMaxTime = 0,
        SmoothFillSpeed = 0.15,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,

        _More = 1,

        BurningEmbers = false,
        GreenFire = false,
        GreenFireAuto = true,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Region = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0.266, g = 0.290, b = 0.274, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      BackgroundShard = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        ColorAllSelect = {bg = 'Color', border = 'Color'},
        Color = {
          All = false,
          r = 0.329, g = 0.172, b = 0.337, a = 1,
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 1
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 2
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 3
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 4
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 5
        },
        ColorGreen = {
          All = false,
          r = 0.123, g = 0.311, b = 0.039, a = 1,
          {r = 0.123, g = 0.311, b = 0.039, a = 1}, -- 1
          {r = 0.123, g = 0.311, b = 0.039, a = 1}, -- 2
          {r = 0.123, g = 0.311, b = 0.039, a = 1}, -- 3
          {r = 0.123, g = 0.311, b = 0.039, a = 1}, -- 4
          {r = 0.123, g = 0.311, b = 0.039, a = 1}, -- 5
        },
        EnableBorderColor = false,
        BorderColor = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,
          {r = 1, g = 1, b = 1, a = 1},  -- 1
          {r = 1, g = 1, b = 1, a = 1},  -- 2
          {r = 1, g = 1, b = 1, a = 1},  -- 3
          {r = 1, g = 1, b = 1, a = 1},  -- 4
          {r = 1, g = 1, b = 1, a = 1},  -- 5
        },
        BorderColorGreen = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,
          {r = 1, g = 1, b = 1, a = 1},  -- 1
          {r = 1, g = 1, b = 1, a = 1},  -- 2
          {r = 1, g = 1, b = 1, a = 1},  -- 3
          {r = 1, g = 1, b = 1, a = 1},  -- 4
          {r = 1, g = 1, b = 1, a = 1},  -- 5
        },
      },
      BackgroundEmber = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        ColorAllSelect = {bg = 'Color', border = 'Color'},
        Color = {
          All = false,
          r = 0.611, g = 0.137, b = 0.058, a = 1,
          {r = 0.611, g = 0.137, b = 0.058, a = 1}, -- 1
          {r = 0.611, g = 0.137, b = 0.058, a = 1}, -- 2
          {r = 0.611, g = 0.137, b = 0.058, a = 1}, -- 3
          {r = 0.611, g = 0.137, b = 0.058, a = 1}, -- 4
          {r = 0.611, g = 0.137, b = 0.058, a = 1}, -- 5
        },
        ColorGreen = {
          All = false,
          r = 0.223, g = 0.411, b = 0.039, a = 1,
          {r = 0.223, g = 0.411, b = 0.039, a = 1}, -- 1
          {r = 0.223, g = 0.411, b = 0.039, a = 1}, -- 2
          {r = 0.223, g = 0.411, b = 0.039, a = 1}, -- 3
          {r = 0.223, g = 0.411, b = 0.039, a = 1}, -- 4
          {r = 0.223, g = 0.411, b = 0.039, a = 1}, -- 5
        },
        EnableBorderColor = false,
        BorderColor = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,
          {r = 1, g = 1, b = 1, a = 1},  -- 1
          {r = 1, g = 1, b = 1, a = 1},  -- 2
          {r = 1, g = 1, b = 1, a = 1},  -- 3
          {r = 1, g = 1, b = 1, a = 1},  -- 4
          {r = 1, g = 1, b = 1, a = 1},  -- 5
        },
        BorderColorGreen = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,
          {r = 1, g = 1, b = 1, a = 1},  -- 1
          {r = 1, g = 1, b = 1, a = 1},  -- 2
          {r = 1, g = 1, b = 1, a = 1},  -- 3
          {r = 1, g = 1, b = 1, a = 1},  -- 4
          {r = 1, g = 1, b = 1, a = 1},  -- 5
        },
      },
      BarShard = {
        Advanced = false,
        Width = 25,
        Height = 32,
        FillDirection = 'VERTICAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        FullBarTexture = GUBStatusBarTexture,
        ColorAllSelect = {bar = 'Color', barfull = 'Color'},
        Color = {
          All = false,
          r = 0.792, g = 0.254, b = 0.913, a = 1,
          {r = 0.792, g = 0.254, b = 0.913, a = 1,}, -- 1
          {r = 0.792, g = 0.254, b = 0.913, a = 1,}, -- 2
          {r = 0.792, g = 0.254, b = 0.913, a = 1,}, -- 3
          {r = 0.792, g = 0.254, b = 0.913, a = 1,}, -- 4
          {r = 0.792, g = 0.254, b = 0.913, a = 1,}, -- 5
        },
        ColorGreen = {
          All = false,
          r = 0.203, g = 0.662, b = 0, a = 1,
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 1
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 2
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 3
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 4
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 5
        },
        ColorFull = {
          All = false,
          r = 0.980, g = 0.517, b = 1, a = 1,
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 1
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 2
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 3
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 4
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 5
        },
        ColorFullGreen = {
          All = false,
          r = 0, g = 1, b = 0.078, a = 1,
          {r = 0, g = 1, b = 0.078, a = 1}, -- 1
          {r = 0, g = 1, b = 0.078, a = 1}, -- 2
          {r = 0, g = 1, b = 0.078, a = 1}, -- 3
          {r = 0, g = 1, b = 0.078, a = 1}, -- 4
          {r = 0, g = 1, b = 0.078, a = 1}, -- 5
        },
      },
      BarEmber = {
        Advanced = false,
        Width = 25,
        Height = 32,
        FillDirection = 'VERTICAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        FullBarTexture = GUBStatusBarTexture,
        ColorAllSelect = {bar = 'Color', barfull = 'Color'},
        Color = {
          All = false,
          r = 1, g = 0.325, b = 0 , a = 1,
          {r = 1, g = 0.325, b = 0 , a = 1}, -- 1
          {r = 1, g = 0.325, b = 0 , a = 1}, -- 2
          {r = 1, g = 0.325, b = 0 , a = 1}, -- 3
          {r = 1, g = 0.325, b = 0 , a = 1}, -- 4
          {r = 1, g = 0.325, b = 0 , a = 1}, -- 5
        },
        ColorGreen = {
          All = false,
          r = 0.203, g = 0.662, b = 0, a = 1,
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 1
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 2
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 3
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 4
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 5
        },
        ColorFull = {
          All = false,
          r = 0.941, g = 0.690, b = 0.094, a = 1,
          {r = 0.941, g = 0.690, b = 0.094, a = 1}, -- 1
          {r = 0.941, g = 0.690, b = 0.094, a = 1}, -- 2
          {r = 0.941, g = 0.690, b = 0.094, a = 1}, -- 3
          {r = 0.941, g = 0.690, b = 0.094, a = 1}, -- 4
          {r = 0.941, g = 0.690, b = 0.094, a = 1}, -- 5
        },
        ColorFullGreen = {
          All = false,
          r = 0, g = 1, b = 0.078, a = 1,
          {r = 0, g = 1, b = 0.078, a = 1}, -- 1
          {r = 0, g = 1, b = 0.078, a = 1}, -- 2
          {r = 0, g = 1, b = 0.078, a = 1}, -- 3
          {r = 0, g = 1, b = 0.078, a = 1}, -- 4
          {r = 0, g = 1, b = 0.078, a = 1}, -- 5
        },
      },
      Triggers = {
        _DC = 0,
        Notes = '"Fragments" are based on the amount of fill from 0 to 10 or percentage per shard',
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- ChiBar
    ChiBar = {
      Name = 'Chi Bar',
      OptionOrder = 16,
      Enabled = true,
      UsedByClass = {MONK = '3'},
      x = 0,
      y = 69,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Chi = 0,
        Ascension = true,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        Swap = false,
        Float = false,
        BorderPadding = 6,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        AnimationType = DefaultAnimationType,
        AnimationInTime = DefaultAnimationInTime,
        AnimationOutTime = DefaultAnimationOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Region = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0.113, g = 0.192, b = 0.188, a = 1},
        EnabelBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {
          All = false,
          r = 0, g = 0, b = 0, a = 1,
          {r = 0, g = 0, b = 0, a = 1}, -- 1
          {r = 0, g = 0, b = 0, a = 1}, -- 2
          {r = 0, g = 0, b = 0, a = 1}, -- 3
          {r = 0, g = 0, b = 0, a = 1}, -- 4
          {r = 0, g = 0, b = 0, a = 1}, -- 5
          {r = 0, g = 0, b = 0, a = 1}, -- 6
        },
        EnableBorderColor = false,
        BorderColor = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,
          {r = 1, g = 1, b = 1, a = 1},  -- 1
          {r = 1, g = 1, b = 1, a = 1},  -- 2
          {r = 1, g = 1, b = 1, a = 1},  -- 3
          {r = 1, g = 1, b = 1, a = 1},  -- 4
          {r = 1, g = 1, b = 1, a = 1},  -- 5
          {r = 1, g = 1, b = 1, a = 1},  -- 6
        },
      },
      Bar = {
        Advanced = false,
        Width = 30,
        Height = 30,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
          r = 0.407, g = 0.764, b = 0.670, a = 1,
          {r = 0.407, g = 0.764, b = 0.670, a = 1}, -- 1
          {r = 0.407, g = 0.764, b = 0.670, a = 1}, -- 2
          {r = 0.407, g = 0.764, b = 0.670, a = 1}, -- 3
          {r = 0.407, g = 0.764, b = 0.670, a = 1}, -- 4
          {r = 0.407, g = 0.764, b = 0.670, a = 1}, -- 5
          {r = 0.407, g = 0.764, b = 0.670, a = 1}, -- 6
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
-- ArcaneBar
    ArcaneBar = {
      Name = 'Arcane Bar',
      OptionOrder = 17,
      Enabled = true,
      UsedByClass = {MAGE = '1'},
      x = 0,
      y = 30,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideNoTarget    = false,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        ArcaneCharges = 0,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        Swap = false,
        Float = false,
        BorderPadding = 6,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        AnimationType = DefaultAnimationType,
        AnimationInTime = DefaultAnimationInTime,
        AnimationOutTime = DefaultAnimationOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      Attributes = {
        Scale = 1,
        Alpha = 1,
        AnchorPoint = 'TOPLEFT',
        FrameStrata = 'MEDIUM',
        MainAnimationType = true,
        AnimationTypeBar = 'alpha',
      },
      Region = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0.188, g = 0.094, b = 0.313, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {
          All = false,
          r = 0.034, g = 0.129, b = 0.317, a = 1,
          {r = 0.034, g = 0.129, b = 0.317, a = 1}, -- 1
          {r = 0.034, g = 0.129, b = 0.317, a = 1}, -- 2
          {r = 0.034, g = 0.129, b = 0.317, a = 1}, -- 3
          {r = 0.034, g = 0.129, b = 0.317, a = 1}, -- 4
        },
        EnableBorderColor = false,
        BorderColor = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,
          {r = 1, g = 1, b = 1, a = 1},  -- 1
          {r = 1, g = 1, b = 1, a = 1},  -- 2
          {r = 1, g = 1, b = 1, a = 1},  -- 3
          {r = 1, g = 1, b = 1, a = 1},  -- 4
        },
      },
      Bar = {
        Advanced = false,
        Width = 40,
        Height = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
          r = 0.376, g = 0.784, b = 0.972, a = 1,
          {r = 0.376, g = 0.784, b = 0.972, a = 1}, -- 1
          {r = 0.376, g = 0.784, b = 0.972, a = 1}, -- 2
          {r = 0.376, g = 0.784, b = 0.972, a = 1}, -- 3
          {r = 0.376, g = 0.784, b = 0.972, a = 1}, -- 4
        },
      },
      Triggers = {
        _DC = 0,
        MenuSync = false,
        HideTabs = false,
        Action = {},
        ActionSync = {},

        Default = { -- Default trigger
          Enabled = true,
          Static = false,
          SpecEnabled = false,
          DisabledBySpec = false,
          ClassName = '',
          ClassSpecs = {},
          HideAuras = false,
          OffsetAll = true,
          Action = {Type = 1},
          Name = '',
          GroupNumber = 1,
          OrderNumber = 0,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          CanAnimate = false,
          Animate = false,
          AnimateSpeed = 0.01,
          State = true,
          AuraOperator = 'or',
          Conditions = { All = false, {Operator = '>', Value = 0} },
          Pars = {},
          GetFnTypeID = 'none',
          GetPars = {},
        },
      },
    },
  },
}

local HelpText = {}

--=============================================================================
--
-- To label HTTP address.  So the name appears above the input box.
-- You need to place the name on a line by its self.  Then the web address on
-- the next line by its self.
--
-- For inline text.  Format [[Title[]
--                             text inside here]]
--
-- Inline text must have the title followed by [], then the body starts on the
-- next line.
--=============================================================================

GUB.DefaultUB.HelpText = HelpText
HelpText[1] = [[

After making a lot of changes if you wish to start over you can reset default settings.  Just go to the bar in the bars menu.  Choose what to reset.  You may have to scroll down to see it.

You can get to the options in two ways.
First is going to interface -> addons -> Galvin's UnitBars.  Then click on "GUB Options".
The other way is to type "/gub config" or "/gub c".


|cff00ff00Dragging and Dropping|r
To drag any bar around the screen use the left mouse button while pressing any modifier key (alt, shift, or control).  To move a rune use the right mouse button while pressing down any modifier key.


|cff00ff00Status|r
All bars have status flags.  This tells a bar what to do based on a certain condition.  Each bar can have one or more flags active at the same time.  A flag with a higher priority will always override one with a lower.  The flags listed below are from highest priority to lowest.  Unlocking bars acts like a status.  It will override all flags to show the bars, The only flags it can't override is never show and hide not usable.

   |cff00ffffHide not Usable|r Disable and hides the bar if it's not usable by the class or spec.
   |cff00ffffShow Always|r Always show the bar.  This doesn't override Hide not usable.
   |cff00ffffHide when Dead|r Hide the bar when the player is dead.
   |cff00ffffHide in Vehicle|r Hide the bar if a vehicle.
   |cff00ffffHide in Pet Battle|r Hide the bar if in a pet battle.
   |cff00ffffHide not Active|r Hide the bar when it's not active and out of combat.
   |cff00ffffHide no Combat|r Hide the bar when not in combat.


|cff00ff00Text|r
Some bars support multiple text lines.  Each text line can have multiple values.  Click the add/remove buttons to add or remove values.  To add another text line click the button that has the + or - button with the name of the text line.  To add another text line beyond line 2.  Click the line 2 tab, then click the button with the + symbol.

You can add extra text to the layout.  Just modify the layout in the edit box.  After you click accept the layout will become a custom layout.  Clicking exit will take you back to a normal layout.  You'll lose the custom layout though.

The layout supports world of warcraft's UI escape color codes.  The format for this is ||cAARRGGBB<text>||r.  So for example to make percentage show up in red you would do ||c00FF0000%d%%||r.  If you want a "||" to appear on the bar you'll need to use "|||".

If the layout causes an error you will see a layout error appear in the format of Err (text line number). So Err (2) would mean text line 2 is causing the error.

Here's some custom layout examples.

(%d%%) : (%d) -> (20%) : (999)
Health %d / Percentage %d%% -> Health 999 / Percentage 20%
%.2fk -> 999.99k

For more information you can check out the following links:

For text:]]
HelpText[#HelpText + 1] = [[https://www.youtube.com/watch?v=mQVCDJLrCNI]]
HelpText[#HelpText + 1] = [[UI escape codes:]]
HelpText[#HelpText + 1] = [[http://wow.gamepedia.com/UI_escape_sequences]]
HelpText[#HelpText + 1] = [[

|cff00ff00Copy and Paste|r
Go to the copy and paste options.  Click on a button from the button menu on the top row.  This selects a bottom row of buttons. Click on the bottom button you want to copy then pick another bar and click "paste" to do the copy.  Can also copy and paste on the same bar if permitted.


|cff00ff00Align and Swap|r
Right click on any bar to open this tool up.  Then click on align or swap. Align will allow you to line up a bar with another bar.  Just drag the bar near another till you see a green rectangle.  The bar will then jump next to the other bar based on where you place it.  You can keep doing this with more bars.  The tool remembers all the bars you aligned as long as you don't close the tool or uncheck align or switch to swap.

You can use vertical or horizontal padding to space apart the aligned bars.  The vertical only works for bars that were aligned vertically and the same for horizontal.  Once you have 2 or more aligned bars they become an aligned group.  Then you can use offsets to move the group.

If you choose swap, then when you drag the bar near another bar. It will have a red rectangle around it.  Soon as you place it there the two bars will switch places.

This same tool can be used on bar objects.  When you go to the bar options under layout you'll see swap and float. Clicking float will open up the align tool further down.

You can also set the bar position manually by unchecking align.  You'll have a Horizontal and Vertical input box just type in the location.  Moving the bar will automatically update the input boxes with the new location.

For more you can watch the video:]]
HelpText[#HelpText + 1] = [[http://www.youtube.com/watch?v=STYa5d6riuk]]
HelpText[#HelpText + 1] = [[

|cff00ff00Test Mode|r
When in test mode the bars will behave as if they were unlocked.  Test mode allows you to make changes to the bar without having to go into combat to make certain parts of the bar become active.

Additional options will be found at the option panel for the bar when test mode is active
]]

HelpText[#HelpText + 1] = [[
|cff00ff00Triggers|r
Triggers let you create an option that will only become active when a condition is met.
Triggers activate in the following order. Static first, Conditional second, and Auras last.

Triggers are sorted by tabs.  Each tab is part of the bar.  If the tab is empty you'll see an 'add' button. Clicking this will add a new trigger options panel. There is no limit to how many triggers you can create, create too many and you may experience lag in the options panel.

Each trigger has 4 menu buttons.  These can be minimized or maximized by clicking them more than once.

|cff00ffffTYPE|r Creates the type of trigger, border, color, sound, etc.
    |cffff00ffValue Type|r Lets you pick what type of value you want to trigger off of.  Each bar has its own set of value types.
    |cffff00ffType|r Lets you pick different parts of the bar.  Border, color, background, etc.
    |cffff00ffAuras|r Use a buff or debuff to execute a trigger.

|cff00ffffVALUE|r Number to execute the trigger at, or can be inverse.  Depends on the Type.
    |cffff00ffInverse|r For triggers that use 'active' then you can inverse this. Make it do the opposite.
    |cffff00ffOperator|r If the trigger is a conditional trigger.
        <       Less than
        >       Greater than
        <=     Less than or equal
        >=     Greater than or equal
        =       Equal
        <>      Not equal
        and   All auras (auras only)
        or      At least one aura (auras only)
    |cffff00ffValue|r The trigger will execute at this value.  If this is a percentage then it must be between 0 and 100. You can also "add" another condition.  The 'all' option if checked will make it so that all conditions have to be met for the trigger to execute.
    |cffff00ffAdd|r Add another condition, this is the same as the current line, operator, value, etc.
    |cffff00ffAll|r If this is checked then all conditions must be true. Otherwise just one needs to be true.

    |cffff00ffAura name or SpellID|r  If auras was selected under type. Under the spell ID enter the exact spell or start typing part of the spell name.  As you do this, a dropdown box will appear.  If the mod already saw the spell then it will show it in white.  This works best if aura list is always on.  After the aura is added you change the following:

        |cffff00ffOwn|r If checked the aura has to be cast from you.
        |cffff00ffNot Active|r If checked then the aura can not be on the unit.
        |cffff00ffUnit|r Name of the unit that will contain the aura.
        |cffff00ffCondition|r Can set what type of condition you want to compare stacks to.
        |cffff00ffStacks|r Number of stacks to compare.

|cff00ffffNAME|r By default a trigger doesn't have a name.  Enter anything you want here.

|cff00ffffUTIL|r Allows you to Swap, Move, Copy, and Delete

    |cffff00ffSwap|r Swap a places with another trigger.  This option may not be available if the two triggers are not compatible.
    |cffff00ffMove|r Move a trigger to a different tab.  This option is not available with one tab.
    |cffff00ffCopy|r Copy a trigger to a different tab.  This option is not available if the trigger is not compatible with the destination tab.
    |cffff00ffDelete|r Removes the trigger.  This can not be undone.

Above the 4 menu buttons is Static and Disable.
Static makes the trigger more like an option. It's always on.
Disable makes the trigger not work.

For more you can watch the video:]]
HelpText[#HelpText + 1] = [[https://youtu.be/bey_dQBZlmA]]
HelpText[#HelpText + 1] = [[

|cff00ff00Aura List|r
Found under General.  This will list any auras the mod comes in contact with.  Type the different units into the unit box seperated by a space.  The mod will only list auras from the units specified. Then click refresh to update the aura list with the latest auras.


|cff00ff00Profiles|r
Its recommended that once you have your perfect configuration made you make a backup of it using profiles.  Just create a new profile named backup.  Then copy your config to backup.  All characters by default start with a new config, but you can share one across all characters or any of your choosing.
]]

-- Message Text
local ChangesText = {}

GUB.DefaultUB.ChangesText = ChangesText
ChangesText[1] = [[

Version 5.50

|cff00ff00Stagger bar|r added for brewmaster monks
|cff00ff00Copy and Paste|r can now copy between all color types
|cff00ff00Triggers|r can now take time as an option for the Rune Bar and Stagger Bar


Version 5.41

|cff00ff00Rune Bar|r changed to reflect UI changes
|cff00ff00Fragment bar|r replaces shard bar for destruction warlocks

|cff00ff00Triggers|r now have specialization.  This is found next to the disable option for each trigger
|cff00ff00Layout|r and General options moved to menu tree "Layout" found under the bar name in the menu tree left side
|cff00ff00General|r options has been merged with Layout
|cff00ff00Other|r options renamed to Attributes
|cff00ff00Test mode|r has been moved to Layout
|cff00ff00Debug|r added to help the author track bugs from text. Can be found under General options


Version 5.13

|cff00ff00Elvui|r compatability changes made
|cff00ff00ComboBar|r has been recoded.  Bar and Background settings will have to be redone

|cff00ff00Escape|r key can now close the pop up message box
|cff00ff00New power bar types added|r Astral Power, Maelstrom, Insanity, Fury, and Pain
|cff00ff00Bars removed|r Shadow, Maelstrom, Ember, Demonic, Anticipation
|cff00ff00Arcane bar|r for arcane mages added
|cff00ff00Predicted power|r (Player Power only) will auto detect any spell that returns a resource with a cast time
|cff00ff00Predicted cost|r (Power bars only) Similar to predicted power. except it shows how much resource will be spent
|cff00ff00All bars have an alpha setting|r Found under Other options for each bar. This changes transparency
|cff00ff00Font size can be much larger|r Found under text settings then font
|cff00ff00Rune bars animation|r should be stutter free
|cff00ff00Menu Sync|r setting should save after reloading ui
|cff00ff00Region|r added to the rune bar. This is on by default
|cff00ff00Region|r also added to reset options for each bar
|cff00ff00Predicted Value|r renamed to Predicted Health for health bars and Predicted Power for power bars.  Trigger options type "(predicted...)" is for Predicted Health or Power and "cost" is for Predicted Cost
|cff00ff00Copy and Paste|r had some improvements
|cff00ff00Each trigger|r "Type" has its own icon
|cff00ff00Level|r added under to Value Name in Text settings
|cff00ff00Level|r added for triggers, Unit Level and Scaled Level
|cff00ff00Anchor|r point can be changed for any bar.  Found under "other" settings
|cff00ff00Bar Fill FPS|r found under General -> Main -> Layout.  Changes the FPS of smooth fill and timer bars
|cff00ff00Animation|r rewritten. Replace fade. Animation Type settings found under Main -> Animation
|cff00ff00Animation Type Bar|r setting found under Other settings for each bar.  If you want the bar to use its own animation type
|cff00ff00Animation Type|r setting under Layout for each bar changes the way the bar objects hide and show
|cff00ff00Not Active|r option added to aura triggers.  You'll find it in each aura option
|cff00ff00Smooth fill|r settings will have to be redone.  Now have Smooth Fill Max Time and Smooth Fill Speed
|cff00ff00Animation Triggers|r Bar Offset, Texture Scale, Text Font Size, and Text Font Offset
|cff00ff00Smooth fill max time|r Sets the maximum time a smooth fill can take.  Found next to smooth fill speed
]]


