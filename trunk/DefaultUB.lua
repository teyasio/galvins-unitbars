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
GUB.DefaultUB.Version = 322

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
-- HideLocationInfo       - Boolean. If true the location information for bars and boxes is not shown in tooltips when mousing over.
-- ReverseFading          - Boolean. If true then transition from fading in one direction then going to the other is smooth.
-- FadeOutTime            - Time in seconds before a bar completely goes hidden.
-- FadeInTime             - Time in seconds before a bar completely becomes visible.
-- HighlightDraggedBar    - Shows a box around the frame currently being dragged.
-- AuraListOn             - If true then the aura list utility is active.
-- AuraListUnits          - String. Contains a list of units seperated by spaces for the aura utility to track.
-- CombatClassColor       - If true thne then the combat colors will use player class colors.
-- CombatTaggedColor      - If true then Tagged color will be used along with combat color.
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
--   BarVisible()         - Returns true or false.  This gets referenced by UnitBarsF. Not all bars use this.
--   UsedByClass          - If a bar doesn't have this key then any class can use the bar and be any spec or no spec.
--                          Contains the data for HideNotUsable flag.  Not all unitbars use this. This is also used for Enable Bar Options.
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
--                            HideWhenDead     Hide the unitbar when the player is dead.
--                            HideInVehicle    Hide the unitbar if in a vehicle.
--                            HideInPetBattle  Hide the unitbar if in a pet battle.
--                            HideNotActive    Hide the unitbar if its not active. Only checked out of combat.
--                            HideNoCombat     Hide the unitbar when not in combat.
--
--   BoxLocations         - Only exists if the bar was set to Floating mode.  Contains the box frame positions.
--   BoxOrder             - Contains the order the boxes are displayed in for each bar.  Not all bars have this.
--
-- Layout                 - Not all bars use every field.
--   BoxMode              - If true the bar uses boxes (statusbars) instead of textures.
--   HideRegion           - A box with a background thats behind the bar.  If true then this is hidden.
--   Swap                 - If true then boxes inside of a bar can swap locations.
--   Float                - If true then boxes inside of a bar can be moved anywhere on screen.
--   ReverseFill          - If true then a bar fills from right to left.
--   HideText             - If true all text is hidden for this bar.
--   BorderPadding        - Amount of pixel distance between the regions border and boxes inside the bar.
--   Rotation             - Angle in degrees the bar is drawn in from 45 to 360 in 45 degree increments.
--   Slope                - Tilts the bar up or down only when the bar is at 90, 180, 270, or 360 degrees.
--   Padding              - Distance in pixels between each box inside a bar.
--   TextureScale         - Scale of a texture when a bar is in not in boxmode.  Also the size of the runes for the runebar.
--   FadeInTime           - Amount of time to fade in a texture or box texture.
--   FadeOutTime          - Amount of time to fade out a texture or box texture.
--   Align                - If true then boxes in a bar can be aligned.
--   AlignPaddingX        - Horizontal distance between each box when aligning.
--   AlignPaddingY        - Vertical distance between each box when aligning.
--   AlignOffsetX         - Horizontal offset for a group of aligned boxes 2 or more.
--   AlignOffsetY         - Vertical offset for a group of aligned boxes 2 or more.
--
-- Other                  - For anything not related mostly this will be for scale and maybe alpha
--   Scale                - Sets the scale of the unitbar frame.
--   FrameStrata          - Sets the strata for the frame to appear on.
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
--
-- Text                   - Text settings used for displaying numerical or string.
--   Multi                  If key is not present then no text lines can be created.
--   ValueNameMenu        - Tells the options what kind of menu to use for this bar.
--
--   [x]                  - Each array element is a text line (fontstring).
--                          If mutli is false or not present. Then [1] is used.
--
--     Custom             - If true a user inputed layout is used instead of one being automatically generated.
--     Layout             - Layout used in string.format for displaying the values.
--     ValueName          - An array of strings that tell what each position will display.
--     ValueType          - Tells how the value will be displayed.
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
-- Triggers               - Contains all the raw data for triggers.
--   MinimizeAll          - If true all the triggers are minimized in the options panel.
--   GroupNumber          - Current group number selected in the trigger options.
--   Action               - Current action selected in the trigger options.
--
--   Default              - Default trigger.  This can't be copied from one bar to another.
--     Enabled            - True or False.  Enable or disable the trigger.
--     Minimize           - True or False.  Minimizes just the trigger, not all.
--     Name               - Name of trigger.  If blank then used a default name in the options.
--     GroupNumber        - Group for the trigger.  Can be any number.
--     Value              - Value of the trigger.  For boolean triggers 1 = true and 2 = false.
--     TypeID             - Identifies what the type is. See Bar.lua for details.
--     Type               - Can be anything that describes what type it is.
--     ValueTypeID        - Indentifies what value type it is.
--     ValueType          - Can be anything that best describes what type of value is being used.
--     GetFnTypeID        - Identifier to determin which GetFunction to be used.
--                          '' means not GetFunction is defined for this trigger.
--     Condition          - Logical conditonal that is used to activate a trigger.
--     Pars[1 to 4]       - Contains raw data that is used to modify the bar object.
--
--
-- General (Health and power bars)
--   PredictedHealth      - Boolean.  Used by health bars only.
--                                    If true then predicted health will be shown.
--   ClassColor           - Boolean.  Used by health bars only.
--                                    If true then class color will be shown
--   CombatColor          - Boolean.  Used by health bars only.
--                                    If true then combat color will be shown
--   TaggedColor          - Boolean.  Used by health bars only.
--                                    If true then a tagged color will be shown if unit is tagged.
--
--   PredictedPower       - Boolean.  Used by Player Power for hunters only.
--                                    If true predicted power will be shown.
-- General (Rune Bar)
--
--   RuneMode             - 'rune'     Only rune textures are shown.
--                          'bar'      Cooldown bars only are shown.
--                          'runebar'  Rune and a Cooldown bar are shown.
--   EnergizeShow         - When a rune energizes it shows a border around the rune.
--                            'none'    Don't show any energize borders.
--                            'rune'    Only show an energize border around a rune.
--                            'bar'     Only show an energize border around a cooldown bar.
--                            'runebar' Show an energize border around a rune and cooldown bar.
--   EnergizeTime         - Time in seconds to show the energize border.
--   CooldownLine         - Boolean.  If true then a line is drawn on the cooldown texture.
--   BarSpark             - Boolean.  If true a spark is drawn on bar.
--   HideCooldownFlash    - Boolean.  If true a flash cooldown animation is not shown when a rune comes off cooldown.
--   CooldownAnimation    - Boolean.  If false cooldown animation is not shown.
--   CooldownText         - Boolean.  If true then cooldown text gets displayed.
--   RunePosition         - Frame position of the rune attached to bar.  When bars and runes are shown.
--   RuneOffsetX          - Horizontal offset from RunePosition.
--   RuneOffsetY          - Vertical offset from RunePosition.
--   Energize             - Color all table for the energized borders.
--
-- General (Anticipation Bar and Maelstrom Bar)
--
--   HideCharges          - Hide the boxes that show how many charges there are.
--   HideTime             - Hide the timer box that shows how much time is left and how many charges there are.
--   ShowSpark            - If true then a spark will be shown on the timer animation.
--
-- General (Ember Bar)
--   GreenFire            - If true then green fire is manual set.
--   GreenFireAuto        - If true then green fire is activated if the warlock knows green fire.
--
-- General (Eclipse Bar)
--
--   SliderInside         - If true then the slider doesn't clip out side the power bar.
--   HideSlider           - If true then the slider is hidden.
--   PowerHalfLit         - If true then the half of the power bars background is visible.
--   PowerText            - Power text is not shown on the power bar.
--   SliderDirection      - HORIZONTAL or VERTICAL.  Changes the orientation of the slider movement.
--   PrecictedPower       - If true then predicted power will be active.
--   IndicatorHideShow    - 'showalways' the indicator will never auto hide.
--                          'hidealways' the indicator will never be shown.
--                          'auto' Show when there is predicted power to be shown, otherwise hide.
--   PredictedEclipse     - If true then show an eclipse proc based on predicted power.
--   PredictedPowerHalfLit - Same as PowerHalfLit except it is based on predicted power.
--                             PowerHalfLit has to be true for this to be enabled.
--   PredictedPowerText   - If true then predicted power is shown instead.
-------------------------------------------------------------------------------
local DefaultBgTexture = 'Blizzard Tooltip'
local DefaultBorderTexture = 'Blizzard Tooltip'
local DefaultStatusBarTexture = 'Blizzard'
local GUBStatusBarTexture = 'GUB Bright Bar'
local DefaultSound = 'None'
local DefaultSoundChannel = 'SFX'
local UBFontType = 'Arial Narrow'
local DefaultFadeOutTime = 1
local DefaultFadeInTime = 0.30

GUB.DefaultUB.InCombatOptionsMessage = "Can't have options opened during combat"

GUB.DefaultUB.DefaultBgTexture = DefaultBgTexture
GUB.DefaultUB.DefaultBorderTexture = DefaultBorderTexture
GUB.DefaultUB.DefaultStatusBarTexture = DefaultStatusBarTexture
GUB.DefaultUB.DefaultSound = DefaultSound
GUB.DefaultUB.DefaultSoundChannel = DefaultSoundChannel

GUB.DefaultUB.TriggerTypes = {
  TypeID_BackgroundBorder      = 'border',          Type_BackgroundBorder      = 'BG Border',
  TypeID_BackgroundBorderColor = 'bordercolor',     Type_BackgroundBorderColor = 'BG Border Color',
  TypeID_BackgroundBackground  = 'background',      Type_BackgroundBackground  = 'BG Background',
  TypeID_BackgroundColor       = 'backgroundcolor', Type_BackgroundColor       = 'BG Background Color',
  TypeID_BarTexture            = 'bartexture',      Type_BarTexture            = 'Bar Texture',
  TypeID_BarColor              = 'bartexturecolor', Type_BarColor              = 'Bar Color',
  TypeID_TextureSize           = 'texturesize',     Type_TextureSize           = 'Texture Size',
  TypeID_RegionBorder          = 'border',          Type_RegionBorder          = 'Region Border',
  TypeID_RegionBorderColor     = 'bordercolor',     Type_RegionBorderColor     = 'Region Border Color',
  TypeID_RegionBackground      = 'background',      Type_RegionBackground      = 'Region Background',
  TypeID_RegionBackgroundColor = 'backgroundcolor', Type_RegionBackgroundColor = 'Region Background Color',
  TypeID_Sound                 = 'sound',           Type_Sound                 = 'Sound',

  TypeID_ClassColorMenu  = 'color', TypeID_ClassColor  = 'classcolor',  Type_ClassColor  = 'Class Color',
  TypeID_PowerColorMenu  = 'color', TypeID_PowerColor  = 'powercolor',  Type_PowerColor  = 'Power Color',
  TypeID_CombatColorMenu = 'color', TypeID_CombatColor = 'combatcolor', Type_CombatColor = 'Combat Color',
  TypeID_TaggedColorMenu = 'color', TypeID_TaggedColor = 'taggedcolor', Type_TaggedColor = 'Tagged Color',
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
    ReverseFading = true,
    FadeInTime = DefaultFadeInTime,
    FadeOutTime = DefaultFadeOutTime,
    HighlightDraggedBar = false,
    AuraListOn = false,
    AuraListUnits = 'player',
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
    Reset = {
      Minimize = false,

      All = false,
      Location = true,
      Status = true,
      Test = true,
      Layout = true,
      General = true,
      Other = true,
      BG = true,
      Bar = true,
      Text = false,
      Triggers = false,
   },
-- Player Health
    PlayerHealth = {
      Name = 'Player Health',
      OptionOrder = 1,
      UnitType = 'player',
      Enabled = true,
      x = -200,
      y = 230,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        PredictedValue = 0.25,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      General = {
        PredictedHealth = true,
        ClassColor = false,
        CombatColor = false,
        TaggedColor = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
        _ValueNameMenu = 'hap',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueName = {'current'},
          ValueType = {'whole'},

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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- Player Power
    PlayerPower = {
      Name = 'Player Power',
      OptionOrder = 2,
      UnitType = 'player',
      Enabled = true,
      x = -200,
      y = 200,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        PredictedValue = 0.25,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      General = {
        PredictedPower = true,
        UseBarColor = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
        _ValueNameMenu = 'hap',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueName = {'current'},
          ValueType = {'whole'},

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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- Target Health
    TargetHealth = {
      Name = 'Target Health',
      OptionOrder = 3,
      UnitType = 'target',
      Enabled = true,
      x = -200,
      y = 170,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        PredictedValue = 0.25,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      General = {
        PredictedHealth = true,
        ClassColor = false,
        CombatColor = false,
        TaggedColor = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
        _ValueNameMenu = 'hap',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueName = {'current'},
          ValueType = {'whole'},

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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- Target Power
    TargetPower = {
      Name = 'Target Power',
      OptionOrder = 4,
      UnitType = 'target',
      Enabled = true,
      x = -200,
      y = 140,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      General = {
        UseBarColor = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
          ValueName = {'current'},
          ValueType = {'whole'},

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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- Focus Health
    FocusHealth = {
      Name = 'Focus Health',
      OptionOrder = 5,
      UnitType = 'focus',
      Enabled = true,
      x = -200,
      y = 110,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        PredictedValue = 0.25,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      General = {
        PredictedHealth = true,
        ClassColor = false,
        CombatColor = false,
        TaggedColor = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
        _ValueNameMenu = 'hap',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueName = {'current'},
          ValueType = {'whole'},

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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- Focus Power
    FocusPower = {
      Name = 'Focus Power',
      OptionOrder = 6,
      UnitType = 'focus',
      Enabled = true,
      x = -200,
      y = 80,
      Status = {
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      General = {
        UseBarColor = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
          ValueName = {'current'},
          ValueType = {'whole'},

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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
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
      UsedByClass = {DEATHKNIGHT = '', MAGE = '3', WARLOCK = '', HUNTER = ''},
      x = -200,
      y = 50,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
        PredictedValue = 0.25,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      General = {
        PredictedHealth = true,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
        _ValueNameMenu = 'hap',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueName = {'current'},
          ValueType = {'whole'},

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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
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
      UsedByClass = {DEATHKNIGHT = '', MAGE = '3', WARLOCK = '', HUNTER = ''},
      x = -200,
      y = 20,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      General = {
        UseBarColor = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
          ValueName = {'current'},
          ValueType = {'whole'},

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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- Mana Power
    ManaPower = {
      Name = 'Mana Power',
      OptionOrder = 9,
      OptionText = 'Druid or Monks only: Shown when normal mana bar is not available',
      UnitType = 'player',
      Enabled = true,
      UsedByClass = {DRUID = '', MONK = '2'},
      x = -200,
      y = -10,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
      },
      Layout = {
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      General = {
        UseBarColor = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
          ValueName = {'current'},
          ValueType = {'whole'},

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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- RuneBar
    RuneBar = {
      Name = 'Rune Bar',
      OptionOrder = 10,
      Enabled = true,
      UsedByClass = {DEATHKNIGHT = ''},
      x = 0,
      y = 229,
      BoxOrder = {1, 2, 5, 6, 3, 4},
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        ShowDeathRunes = false,
        Energize = 0,
        Value = 0.50,
        Recharge = 1,
      },
      Layout = {
        EnableTriggers = false,
        Swap = false,
        Float = false,
        ReverseFill = false,
        HideText = false,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      General = {
        RuneMode = 'rune',
        EnergizeShow = 'rune',
        EnergizeTime = 3,
        CooldownLine = false,
        BarSpark = false,
        HideCooldownFlash = true,
        CooldownAnimation = true,
        RunePosition = 'LEFT',
        RuneOffsetX = 0,
        RuneOffsetY = 0,
        ColorEnergize = {
          All = false,
          r = 1, g = 0, b = 0, a = 1,         -- All runes
          {r = 1, g = 0, b = 0, a = 1},       -- 1 Blood
          {r = 1, g = 0, b = 0, a = 1},       -- 2 Blood
          {r = 0, g = 1, b = 0, a = 1},       -- 3 Unholy
          {r = 0, g = 1, b = 0, a = 1},       -- 4 Unholy
          {r = 0, g = 0.7, b = 1, a = 1},     -- 5 Frost
          {r = 0, g = 0.7, b = 1, a = 1},     -- 6 Frost
          {r = 1, g = 0, b = 1, a = 1},       -- 7 Death
          {r = 1, g = 0, b = 1, a = 1},       -- 8 Death
        },
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
          r = 0, g = 0, b = 0, a = 1,                               -- All runes
          {r = 1 * 0.5, g = 0,           b = 0,       a = 1},       -- 1 Blood
          {r = 1 * 0.5, g = 0,           b = 0,       a = 1},       -- 2 Blood
          {r = 0,       g = 1   * 0.5,   b = 0,       a = 1},       -- 3 Unholy
          {r = 0,       g = 1   * 0.5,   b = 0,       a = 1},       -- 4 Unholy
          {r = 0,       g = 0.7 * 0.5,   b = 1 * 0.5, a = 1},       -- 5 Frost
          {r = 0,       g = 0.7 * 0.5,   b = 1 * 0.5, a = 1},       -- 6 Frost
          {r = 1 * 0.5, g = 0,           b = 1 * 0.5, a = 1},       -- 7 Death
          {r = 1 * 0.5, g = 0,           b = 1 * 0.5, a = 1},       -- 8 Death
        },
        EnableBorderColor = false,
        BorderColor = {
          All = false,
          r = 1, g = 1, b = 1, a = 1,          -- All runes
          {r = 1, g = 1, b = 1, a = 1,},       -- 1 Blood
          {r = 1, g = 1, b = 1, a = 1,},       -- 2 Blood
          {r = 1, g = 1, b = 1, a = 1,},       -- 3 Unholy
          {r = 1, g = 1, b = 1, a = 1,},       -- 4 Unholy
          {r = 1, g = 1, b = 1, a = 1,},       -- 5 Frost
          {r = 1, g = 1, b = 1, a = 1,},       -- 6 Frost
          {r = 1, g = 1, b = 1, a = 1,},       -- 7 Death
          {r = 1, g = 1, b = 1, a = 1,},       -- 8 Death
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
        Color = {
          All = false,
          r = 1, g = 0, b = 0, a = 1,         -- All runes
          {r = 1, g = 0, b = 0, a = 1},       -- 1 Blood
          {r = 1, g = 0, b = 0, a = 1},       -- 2 Blood
          {r = 0, g = 1, b = 0, a = 1},       -- 3 Unholy
          {r = 0, g = 1, b = 0, a = 1},       -- 4 Unholy
          {r = 0, g = 0.7, b = 1, a = 1},     -- 5 Frost
          {r = 0, g = 0.7, b = 1, a = 1},     -- 6 Frost
          {r = 1, g = 0, b = 1, a = 1},       -- 7 Death
          {r = 1, g = 0, b = 1, a = 1},       -- 8 Death
        },
      },
      Text = {
        _ValueNameMenu = 'rune',

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueName = {'time'},
          ValueType = {'timeSS'},

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
            r = 1, g = 1, b = 1, a = 1,         -- All runes
            {r = 1, g = 1, b = 1, a = 1},       -- 1 Blood
            {r = 1, g = 1, b = 1, a = 1},       -- 2 Blood
            {r = 1, g = 1, b = 1, a = 1},       -- 3 Unholy
            {r = 1, g = 1, b = 1, a = 1},       -- 4 Unholy
            {r = 1, g = 1, b = 1, a = 1},       -- 5 Frost
            {r = 1, g = 1, b = 1, a = 1},       -- 6 Frost
            {r = 1, g = 1, b = 1, a = 1},       -- 7 Death
            {r = 1, g = 1, b = 1, a = 1},       -- 8 Death
          },
        },
      },
      Triggers = {
        _DC = 0,
        Notes = 'Empowered uses the Time settings from Empowerment in General settings\neven if turned off',
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '=',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- ComboBar
    ComboBar = {
      Name = 'Combo Bar',
      OptionOrder = 11,
      Enabled = true,
      UsedByClass = {ROGUE = '', DRUID = ''},
      x = 0,
      y = 201,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = true,
        HideNoCombat    = false,
      },
      TestMode = {
        Value = 0.50,
      },
      Layout = {
        EnableTriggers = false,
        Swap = false,
        Float = false,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        FadeInTime = DefaultFadeInTime,
        FadeOutTime = DefaultFadeOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
          {r = 0, g = 0, b = 0, a = 1},  -- 1
          {r = 0, g = 0, b = 0, a = 1},  -- 2
          {r = 0, g = 0, b = 0, a = 1},  -- 3
          {r = 0, g = 0, b = 0, a = 1},  -- 4
          {r = 0, g = 0, b = 0, a = 1},  -- 5
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
          r = 1, g = 0, b = 0, a = 1,
          {r = 1, g = 0, b = 0, a = 1}, -- 1
          {r = 1, g = 0, b = 0, a = 1}, -- 2
          {r = 1, g = 0, b = 0, a = 1}, -- 3
          {r = 1, g = 0, b = 0, a = 1}, -- 4
          {r = 1, g = 0, b = 0, a = 1}, -- 5
        },
      },
      Triggers = {
        _DC = 0,
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- AnticipationBar
    AnticipationBar = {
      Name = 'Anticipation Bar',
      OptionOrder = 12,
      Enabled = true,
      UsedByClass = {ROGUE = ''},
      x = 220,
      y = 201,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = true,
        HideNoCombat    = false,
      },
      TestMode = {
        Value = 0.50,
        Time = 0.50,
      },
      Layout = {
        EnableTriggers = false,
        Swap = false,
        Float = false,
        ReverseFill = false,
        HideText = false,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        FadeInTime = DefaultFadeInTime,
        FadeOutTime = DefaultFadeOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      General = {
        HideCharges = false,
        HideTime = false,
        ShowSpark = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      BackgroundCharges = {
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
          {r = 0, g = 0, b = 0, a = 1},  -- 1
          {r = 0, g = 0, b = 0, a = 1},  -- 2
          {r = 0, g = 0, b = 0, a = 1},  -- 3
          {r = 0, g = 0, b = 0, a = 1},  -- 4
          {r = 0, g = 0, b = 0, a = 1},  -- 5
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
      BackgroundTime = {
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
      BarCharges = {
        Advanced = false,
        Width = 40,
        Height = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
          r = 1, g = 1, b = 0, a = 1,
          {r = 1, g = 1, b = 0, a = 1}, -- 1
          {r = 1, g = 1, b = 0, a = 1}, -- 2
          {r = 1, g = 1, b = 0, a = 1}, -- 3
          {r = 1, g = 1, b = 0, a = 1}, -- 4
          {r = 1, g = 1, b = 0, a = 1}, -- 5
        },
      },
      BarTime = {
        Advanced = false,
        Width = 100,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {r = 1, g = 0, b = 0, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'anticipation',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueName = {'time'},
          ValueType = {'timeSS'},

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
          Color = {r = 1, g = 1, b = 1, a = 1},
        }
      },
      Triggers = {
        _DC = 0,
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- HolyBar
    HolyBar = {
      Name = 'Holy Bar',
      OptionOrder = 13,
      Enabled = true,
      UsedByClass = {PALADIN = ''},
      x = 0,
      y = 171,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        Swap = false,
        Float = false,
        BorderPadding = 0,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        FadeInTime = DefaultFadeInTime,
        FadeOutTime = DefaultFadeOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- ShardBar
    ShardBar = {
      Name = 'Shard Bar',
      OptionOrder = 14,
      OptionText = 'Affliction Warlocks only',
      Enabled = true,
      UsedByClass = {WARLOCK = '1'},
      x = 0,
      y = 134,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        Swap = false,
        Float = false,
        BorderPadding = 0,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        FadeInTime = DefaultFadeInTime,
        FadeOutTime = DefaultFadeOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
          r = 0.980, g = 0.517, b = 1, a = 1,
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 1
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 2
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 3
          {r = 0.980, g = 0.517, b = 1, a = 1}, -- 4
        },
      },
      Triggers = {
        _DC = 0,
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- DemonicBar
    DemonicBar = {
      Name = 'Demonic Bar',
      OptionOrder = 15,
      OptionText = 'Demonology Warlocks only',
      Enabled = true,
      UsedByClass = {WARLOCK = '2'},
      x = 0,
      y = 98,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        ShowMeta = false,
        Value = 0.50,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0.082, g = 0.219, b = 0.019, a = 1},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
      },
      Bar = {
        Advanced = false,
        Width = 150,
        Height = 24,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        MetaStatusBarTexture = GUBStatusBarTexture,
        Color = {r = 0.627, g = 0.298, b = 1, a = 1},
        MetaColor = {r = 0.922, g = 0.549, b = 0.972, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'demonic',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueName = {'current'},
          ValueType = {'whole'},

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
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color (both)',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- EmberBar
    EmberBar = {
      Name = 'Ember Bar',
      OptionOrder = 16,
      OptionText = 'Destruction Warlocks only',
      Enabled = true,
      UsedByClass = {WARLOCK = '3'},
      x = 0,
      y = 60,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        ShowFiery = false,
        Value = 0.50,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        Swap = false,
        Float = false,
        ReverseFill = false,
        SmoothFill = 0.15,
        BorderPadding = 0,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        FadeInTime = DefaultFadeInTime,
        FadeOutTime = DefaultFadeOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      General = {
        GreenFire = false,
        GreenFireAuto = true,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Region = {
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
          r = 0.611, g = 0.137, b = 0.058, a = 1,
          {r = 0.611, g = 0.137, b = 0.058, a = 1}, -- 1
          {r = 0.611, g = 0.137, b = 0.058, a = 1}, -- 2
          {r = 0.611, g = 0.137, b = 0.058, a = 1}, -- 3
          {r = 0.611, g = 0.137, b = 0.058, a = 1}, -- 4
        },
        ColorGreen = {
          All = false,
          r = 0.223, g = 0.411, b = 0.039, a = 1,
          {r = 0.223, g = 0.411, b = 0.039, a = 1}, -- 1
          {r = 0.223, g = 0.411, b = 0.039, a = 1}, -- 2
          {r = 0.223, g = 0.411, b = 0.039, a = 1}, -- 3
          {r = 0.223, g = 0.411, b = 0.039, a = 1}, -- 4
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
        BorderColorGreen = {
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
        Width = 25,
        Height = 34,
        FillDirection = 'VERTICAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        FieryStatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
          r = 1, g = 0.325, b = 0 , a = 1,
          {r = 1, g = 0.325, b = 0 , a = 1}, -- 1
          {r = 1, g = 0.325, b = 0 , a = 1}, -- 2
          {r = 1, g = 0.325, b = 0 , a = 1}, -- 3
          {r = 1, g = 0.325, b = 0 , a = 1}, -- 4
        },
        ColorFiery = {
          All = false,
          r = 0.941, g = 0.690, b = 0.094, a = 1,
          {r = 0.941, g = 0.690, b = 0.094, a = 1}, -- 1
          {r = 0.941, g = 0.690, b = 0.094, a = 1}, -- 2
          {r = 0.941, g = 0.690, b = 0.094, a = 1}, -- 3
          {r = 0.941, g = 0.690, b = 0.094, a = 1}, -- 4
        },
        ColorGreen = {
          All = false,
          r = 0.203, g = 0.662, b = 0, a = 1,
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 1
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 2
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 3
          {r = 0.203, g = 0.662, b = 0, a = 1}, -- 4
        },
        ColorFieryGreen = {
          All = false,
          r = 0, g = 1, b = 0.078, a = 1,
          {r = 0, g = 1, b = 0.078, a = 1}, -- 1
          {r = 0, g = 1, b = 0.078, a = 1}, -- 2
          {r = 0, g = 1, b = 0.078, a = 1}, -- 3
          {r = 0, g = 1, b = 0.078, a = 1}, -- 4
        },
      },
      Triggers = {
        _DC = 0,
        Notes = '"Full Burning Embers" go by the total number that are on fire \n "Burning Embers" are based on the amount of fill from 0 to 10 or percentage per ember',
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- EclipseBar
    EclipseBar = {
      Name = 'Eclipse Bar',
      OptionOrder = 17,
      OptionText = 'Balance Druids only: Shown when in moonkin or normal form',
      Enabled = true,
      UsedByClass = {DRUID = '1'},
      x = 0,
      y = 11,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNoCombat    = false
      },
      TestMode = {
        Value = 0.50,
      },
      Layout = {
        EnableTriggers = false,
        Swap = false,
        Float = false,
        HideText = false,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        FadeInTime = DefaultFadeInTime,
        FadeOutTime = DefaultFadeOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      General = {
        SliderInside = true,
        HideSlider = false,
        PowerHalfLit = false,
        PowerText = true,
        HidePeak = false,
        SliderDirection = 'HORIZONTAL',
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      BackgroundMoon = {
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
      BackgroundSun = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        EnableBorderColor = false,
        BorderColor = {r = 1, g = 1, b = 1, a = 1},
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      BackgroundPower = {
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
      BackgroundSlider = {
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
      BarMoon = {
        Advanced = false,
        Width = 25,
        Height = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {r = 0.847, g = 0.988, b = 0.972, a = 1},
      },
      BarSun = {
        Advanced = false,
        Width = 25,
        Height = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {r = 0.96, g = 0.925, b = 0.113, a = 1},
      },
      BarPower = {
        Advanced = false,
        Width = 170,
        Height = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTextureLunar = GUBStatusBarTexture,
        StatusBarTextureSolar = GUBStatusBarTexture,
        ColorLunar = {r = 0.364, g = 0.470, b = 0.627, a = 1}, -- moon
        ColorSolar = {r = 0.631, g = 0.466, b = 0.184, a = 1}, -- sun
      },
      BarSlider = {
        Advanced = false,
        SunMoon = true,
        Width = 16,
        Height = 20,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
      },
      Text = {
        _ValueNameMenu = 'eclipse',

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueName = {'number'},
          ValueType = {'whole'},

          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'OUTLINE',
          FontHAlign = 'CENTER',
          FontVAlign = 'MIDDLE',
          Position = 'CENTER',
          FontPosition = 'CENTER',
          Width = 50,
          Height = 18,
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
          Color = {r = 1, g = 1, b = 1, a = 1},
        },
      },
      Triggers = {
        _DC = 0,
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- ShadowBar
    ShadowBar = {
      Name = 'Shadow Bar',
      OptionOrder = 18,
      Enabled = true,
      UsedByClass = {PRIEST = '3'},
      x = 161,
      y = 60,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        ShowEnhancedShadowOrbs = true,
        Value = 0.50,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        Swap = false,
        Float = false,
        BorderPadding = 0,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        FadeInTime = DefaultFadeInTime,
        FadeOutTime = DefaultFadeOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Region = {
        PaddingAll = true,
        BgTexture = DefaultBgTexture,
        BorderTexture = DefaultBorderTexture,
        BgTile = false,
        BgTileSize = 16,
        BorderSize = 12,
        Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        Color = {r = 0.156, g = 0.156, b = 0.156, a = 1},
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
        Width = 38,
        Height = 37,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
          r = 0.729, g = 0.466, b = 1, a = 1,
          {r = 0.729, g = 0.466, b = 1, a = 1}, -- 1
          {r = 0.729, g = 0.466, b = 1, a = 1}, -- 2
          {r = 0.729, g = 0.466, b = 1, a = 1}, -- 3
          {r = 0.729, g = 0.466, b = 1, a = 1}, -- 4
          {r = 0.729, g = 0.466, b = 1, a = 1}, -- 5
        },
      },
      Triggers = {
        _DC = 0,
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- ChiBar
    ChiBar = {
      Name = 'Chi Bar',
      OptionOrder = 19,
      Enabled = true,
      UsedByClass = {MONK = ''},
      x = 161,
      y = 98,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        ShowEmpoweredChi = true,
        Value = 0.50,
      },
      Layout = {
        BoxMode = false,
        EnableTriggers = false,
        HideRegion = false,
        Swap = false,
        Float = false,
        BorderPadding = 0,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        TextureScale = 1,
        FadeInTime = DefaultFadeInTime,
        FadeOutTime = DefaultFadeOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
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
        },
      },
      Triggers = {
        _DC = 0,
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
-- MaelstromBar
    MaelstromBar = {
      Name = 'Maelstrom Bar',
      OptionOrder = 20,
      Enabled = true,
      UsedByClass = {SHAMAN = '2'},
      x = 220,
      y = 231,
      Status = {
        HideNotUsable   = true,
        ShowAlways      = false,
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = true,
        HideNoCombat    = false,
      },
      TestMode = {
        Value = 0.50,
        Time = 0.50,
      },
      Layout = {
        EnableTriggers = false,
        Swap = false,
        Float = false,
        ReverseFill = false,
        HideText = false,
        Rotation = 90,
        Slope = 0,
        Padding = 0,
        FadeInTime = DefaultFadeInTime,
        FadeOutTime = DefaultFadeOutTime,
        Align = false,
        AlignPaddingX = 0,
        AlignPaddingY = 0,
        AlignOffsetX = 0,
        AlignOffsetY = 0,
      },
      General = {
        HideCharges = false,
        HideTime = false,
        ShowSpark = false,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      BackgroundCharges = {
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
          {r = 0, g = 0, b = 0, a = 1},  -- 1
          {r = 0, g = 0, b = 0, a = 1},  -- 2
          {r = 0, g = 0, b = 0, a = 1},  -- 3
          {r = 0, g = 0, b = 0, a = 1},  -- 4
          {r = 0, g = 0, b = 0, a = 1},  -- 5
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
      BackgroundTime = {
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
      BarCharges = {
        Advanced = false,
        Width = 40,
        Height = 25,
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {
          All = false,
          r = 0.780, g = 0.905, b = 1, a = 1,
          {r = 0.780, g = 0.905, b = 1, a = 1}, -- 1
          {r = 0.780, g = 0.905, b = 1, a = 1}, -- 2
          {r = 0.780, g = 0.905, b = 1, a = 1}, -- 3
          {r = 0.780, g = 0.905, b = 1, a = 1}, -- 4
          {r = 0.780, g = 0.905, b = 1, a = 1}, -- 5
        },
      },
      BarTime = {
        Advanced = false,
        Width = 100,
        Height = 25,
        FillDirection = 'HORIZONTAL',
        RotateTexture = false,
        PaddingAll = true,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = GUBStatusBarTexture,
        Color = {r = 0.254, g = 0.443, b = 0.929, a = 1},
      },
      Text = {
        _DC = 0,
        _ValueNameMenu = 'maelstrom',
        _Multi = 1,

        { -- 1
          Custom    = false,
          Layout    = '',
          ValueName = {'time'},
          ValueType = {'timeSS'},

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
          Color = {r = 1, g = 1, b = 1, a = 1},
        }
      },
      Triggers = {
        _DC = 0,
        MinimizeAll = false,
        GroupNumber = 1,
        Action = 'none',

        Default = { -- Default trigger
          Enabled = true,
          Minimize = false,
          HideAuras = false,
          Name = '',
          GroupNumber = 1,
          Value = 1,
          TypeID = 'bartexturecolor',
          Type = 'bar color',
          ValueTypeID = '',
          ValueType = '',
          Condition = '>',
          Pars = {1, 1, 1, 1},
          GetFnTypeID = 'none',
          GetPars = {'', '', '', ''},
        },
      },
    },
  },
}

GUB.DefaultUB.HelpText = [[

After making a lot of changes if you wish to start over you can restore default settings.  Just go to the bar in the bars menu.  Click the bar you want to restore.  Then click the restore button you may have to scroll down to see it.

You can get to the options in two ways.
First is going to interface options -> addons -> Galvin's UnitBars.  Then click on "GUB Options".
The other way is to type "/gub config" or "/gub c".


|cff00ff00Dragging and Dropping|r
To drag any bar around the screen use the left mouse button while pressing any modifier key (alt, shift, or control).  To move a rune use the right mouse button while pressing down any modifier key.


|cff00ff00Status|r
All bars have status flags.  This tells a bar what to do based on a certain condition.  Each bar can have one or more flags active at the same time.  A flag with a higher priority will always override one with a lower.  The flags listed below are from highest priority to lowest.  Unlocking bars acts like a status.  It will override all flags to show the bars, The only flags it can't override is never show and hide not usable.

   Hide not Usable      Disable and hides the bar if it's not usable by the class or spec.
   Show Always          Always show the bar.  This doesn't override Hide not usable.
   Hide when Dead       Hide the bar when the player is dead.
   Hide in Vehicle      Hide the bar if a vehicle.
   Hide in Pet Battle   Hide the bar if in a pet battle.
   Hide not Active      Hide the bar when it's not active and out of combat.
   Hide no Combat       Hide the bar when not in combat.


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
For Text: |Cffffff00https://www.youtube.com/watch?v=mQVCDJLrCNI|r
UI escape codes: |Cffffff00http://www.wowwiki.com/UI_escape_sequences|r


|cff00ff00Copy and Paste|r
Go to the copy and paste options.  Click on a button from the button menu on the top row.  This selects a bottom row of buttons. Click on the bottom button you want to copy then pick another bar in the options and click the same button to do the paste.  For text lines you can copy and paste within the same bar or to another bar.


|cff00ff00Align and Swap|r
Go to the copy and paste options.  Click on a button from the button menu on the top row.  This selects a bottom row of buttons. Click on the bottom button you want to copy then pick another bar in the options and click the same button to do the paste.  For text lines you can copy and paste within the same bar or to another bar.

* Align and Swap
Right click on any bar to open this tool up.  Then click on align or swap. Align will allow you to line up a bar with another bar.  Just drag the bar near another till you see a green rectangle.  The bar will then jump next to the other bar based on where you place it.  You can keep doing this with more bars.  The tool remembers all the bars you aligned as long as you don't close the tool or uncheck align or switch to swap.

You can use vertical or horizontal padding to space apart the aligned bars.  The vertical only works for bars that were aligned vertically and the same for horizontal.  Once you have 2 or more aligned bars they become an aligned group.  Then you can use offsets to move the group.

If you choose swap, then when you drag the bar near another bar. It will have a red rectangle around it.  Soon as you place it there the two bars will switch places.

This same tool can be used on bar objects.  When you go to the bar options under layout you'll see swap and float. Clicking float will open up the align tool further down.

You can also set the bar position manually by unchecking align.  You'll have a Horizontal and Vertical input box just type in the location.  Moving the bar will automatically update the input boxes with the new location.

For more you can watch the video:
|Cffffff00http://www.youtube.com/watch?v=STYa5d6riuk|r


|cff00ff00Test Mode|r
When in test mode the bars will behave as if they were unlocked.  But you can't click on them.  Test mode allows you to make changes to the bar without having to go into combat to make certain parts of the bar become active.

Additional options will be found at the option panel for the bar when test mode is active


|cff00ff00Triggers|r
Triggers let you create an option that will only become active when a condition is met.

When you first go to triggers you'll see a pull down called Bar Object.  Health and power bars only have one bar object, but bars like Ember Bar have more than one.  Select the bar object you want if there is more than one.  Then click the add button.
You'll then see a trigger options panel come up.  There is no limit to how many triggers you can create, create too many and you may experience lag in the options panel.  Minimizing can help with this.

Action: The action pull down lets you pick an action.  Then a UI option will become visible.

  Add       Adds another copy of the current trigger.
  Delete    Removes the current trigger.
  Name      Changes the name of the trigger (Bar Object name) will be appear before the name.
  Swap      Lets you swap one trigger with another.
  Disable   Deactivates a trigger.  Triggers that are disabled do not consume cpu.
  Move      Move a trigger to a different bar object.
  Copy      Copy a trigger to a different bar object.
  None      To prevent accidents.

Value Type: lets you pick what type of value you want to trigger off of.  Each bar has its own set of value types.
Type: lets you pick different parts of the bar.  Border, color, background, etc.

Condition: The condition that needs to be met for the trigger to activate

  <         Less than
  >         Greater than
  <=        Less than or equal
  >=        Greater than or equal
  =         Equal
  <>        No equal
  Static    Always on, static triggers use less cpu.

Value: The value you want to trigger off of based on condition.  If the condition is met the trigger will activate. For percentages only 0 to 100 needs to be entered.

Trigger can also use auras.  Pick "auras" under value type. Then you'll see a box to enter an aura name or ID into.  Type in the name then pick it from the list.  If you already know the spellID then you can type that instead.

After the aura is added you change the following:
Cast by Player:   If checked then the aura has to have come from you.
Units: You can enter any number of units here seperated by a space.  But the aura will have to be on
all of them at the same time.

Condition:  Can set what type of condition you want to compare stacks to.
Stacks: 0 means no stacks so match any aura.

Under condition next to the aura name box.  You can change it to "or" for all auras
or "and" for just one aura out of the list to match.

For more you can watch the video:
|Cffffff00http://www.youtube.com/watch?v=LUhCXoh6Ytk|r


|cff00ff00Aura List|r
Found under General.  This will list any auras the mod comes in contact with.  Type the different units into the unit box.  The mod will only list auras from the units specified. Then click refresh to update the aura list with the latest auras.


|cff00ff00Profiles|r
Its recommended that once you have your perfect configuration made you make a backup of it using profiles.  Just create a new profile named backup.  Then copy your config to backup.  All characters by default start with a new config, but you can share one across all characters or any of your choosing.
]]

-- Message Text
GUB.DefaultUB.MessageText = [[
|Cffffff00Galvin's UnitBars|r

Tons of changes have been made.  Please read the help text.  If something is not working please check that bar's settings.


|cff00ff00New Features|r
* GUB Square Border added for border texture. This can be used thru shared media.
* Border color can be changed.  Found under Region and Background options.
* In testmode you can change the resource value up or down.  You can use this to test triggers without being in combat.
* Triggers - Can change color, textures, or play a sound, etc.  When a condition is met based on the resource value, time, etc.
* Align and Swap has bar location setting.  Align has to be turned off first.  The bar that was right clicked on is the
one that you can set the location to.
* Reset Defauls has been recoded as reset.  You can choose what parts of the bar to reset.
* Options can not be opened during combat.  Having options opened during combat could cause a lua error.  With the test mode
recode theres no need to have this.

3.10 changes (warlords)
* Combo bar is now only visible as a rogue or as a druid when in catform or no form.
* Show Always flag added to Status.
* Faction Colors added to the health bars.  Displays if you're hated, etc.
* Tagged Color added to target health and focus health.  Shows if the target is tagged by another player.

For a full list of changes go to http://www.curse.com/addons/wow/galvins-unitbars
]]



