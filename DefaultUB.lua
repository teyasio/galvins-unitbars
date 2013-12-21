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
GUB.DefaultUB.Version = 201

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
--
--
-- Fields found in all unitbars:
--
--   _DC = 0              - This can appear anywhere in the table.  It's used by CopyUnitBar().  If this key is found
--                          in the source and destination during a copy.  It will deepcopy the table instead. Even if the table
--                          being copied is inside of a larger table that has the _DC tag.  Then it will still get deep copied.
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
-- Region                 - Not every bar has this.
--   PaddingAll           - If true then one value sets all 4 padding values.
--   BackdropSettings     - See below for format.
--
--
-- BackdropSettings       - Backdrop settings table. Must be converted into a backdrop before using.
--
--   BgTexture            - Name of the background textured in sharedmedia.
--   BdTexture            - Name of the forground texture 'statusbar' in sharedmedia.
--   BgTile               - True or false. If true then the background is tiled, otherwise not tiled.
--   BgTileSize           - Size (width or height) of the square repeating background tiles (in pixels).
--   BdSize               - Size of the border texture thickness in pixels.
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
--
-- General (Health and power bars)
--   PredictedHealth      - Boolean.  Used by health bars only.
--                                    If true then predicted health will be shown.
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
local DefaultBdTexture = 'Blizzard Tooltip'
local DefaultStatusBarTexture = 'Blizzard'
local GUBStatusBarTexture = 'GUB Bright Bar'
local UBFontType = 'Arial Narrow'
local DefaultFadeOutTime = 1
local DefaultFadeInTime = 0.30

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
-- Player Health
    PlayerHealth = {
      Name = 'Player Health',
      OptionOrder = 1,
      UnitType = 'player',
      Enabled = true,
      x = -200,
      y = 230,
      Status = {
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
        Color = {
          Class = false,
          r = 0, g = 1, b = 0, a = 1,
        },
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Layout = {
        ReverseFill = false,
        HideText = false,
        SmoothFill = 0,
      },
      General = {
        PredictedPower = true,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
        Color = {
          Class = false,
          r = 0, g = 1, b = 0, a = 1,
        },
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
        Color = {
          Class = false,
          r = 0, g = 1, b = 0, a = 1,
        },
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        ShowDeathRunes = false,
        ShowEnergize = false,
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = true,
        HideNoCombat    = false,
      },
      TestMode = {
        MaxResource = false,
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
          r = 0, g = 0, b = 0, a = 1,
          {r = 0, g = 0, b = 0, a = 1},  -- 1
          {r = 0, g = 0, b = 0, a = 1},  -- 2
          {r = 0, g = 0, b = 0, a = 1},  -- 3
          {r = 0, g = 0, b = 0, a = 1},  -- 4
          {r = 0, g = 0, b = 0, a = 1},  -- 5
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
      }
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = true,
        HideNoCombat    = false,
      },
      TestMode = {
        MaxResource = false,
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
          r = 0, g = 0, b = 0, a = 1,
          {r = 0, g = 0, b = 0, a = 1},  -- 1
          {r = 0, g = 0, b = 0, a = 1},  -- 2
          {r = 0, g = 0, b = 0, a = 1},  -- 3
          {r = 0, g = 0, b = 0, a = 1},  -- 4
          {r = 0, g = 0, b = 0, a = 1},  -- 5
        },
      },
      BackgroundTime = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        MaxResource = false,
      },
      Layout = {
        BoxMode = false,
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0.5, g = 0.5, b = 0.5, a = 1}
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
          r = 0.121, g = 0.121, b = 0.121, a = 1,
          {r = 0.121, g = 0.121, b = 0.121, a = 1}, -- 1
          {r = 0.121, g = 0.121, b = 0.121, a = 1}, -- 2
          {r = 0.121, g = 0.121, b = 0.121, a = 1}, -- 3
          {r = 0.121, g = 0.121, b = 0.121, a = 1}, -- 4
          {r = 0.121, g = 0.121, b = 0.121, a = 1}, -- 5
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        MaxResource = false,
      },
      Layout = {
        BoxMode = false,
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0.266, g = 0.290, b = 0.274, a = 1}
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
          r = 0.329, g = 0.172, b = 0.337, a = 1,
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 1
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 2
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 3
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 4
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        ShowMeta = false,
      },
      Layout = {
        BoxMode = false,
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0.082, g = 0.219, b = 0.019, a = 1},
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        MaxResource = false,
        ShowFiery = false,
      },
      Layout = {
        BoxMode = false,
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1}
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNoCombat    = false
      },
      TestMode = {
        ShowEclipseSun = false,
      },
      Layout = {
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
        SliderDirection = 'HORIZONTAL',
        PredictedPower = false,
        IndicatorHideShow = 'auto',
        PredictedEclipse = true,
        PredictedPowerHalfLit = false,
        PredictedPowerText = true,
      },
      Other = {
        Scale = 1,
        FrameStrata = 'MEDIUM',
      },
      BackgroundMoon = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      BackgroundSun = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      BackgroundPower = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      BackgroundSlider = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      BackgroundIndicator = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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
      BarIndicator = {
        Advanced = false,
        SunMoon = false,
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        MaxResource = false,
      },
      Layout = {
        BoxMode = false,
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0.156, g = 0.156, b = 0.156, a = 1}
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
          r = 0.329, g = 0.172, b = 0.337, a = 1,
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 1
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 2
          {r = 0.329, g = 0.172, b = 0.337, a = 1}, -- 3
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = false,
        HideNoCombat    = false
      },
      TestMode = {
        MaxResource = false,
      },
      Layout = {
        BoxMode = false,
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0.113, g = 0.192, b = 0.188, a = 1}
      },
      Background = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
          r = 0, g = 0, b = 0, a = 1,
          {r = 0, g = 0, b = 0, a = 1}, -- 1
          {r = 0, g = 0, b = 0, a = 1}, -- 2
          {r = 0, g = 0, b = 0, a = 1}, -- 3
          {r = 0, g = 0, b = 0, a = 1}, -- 4
          {r = 0, g = 0, b = 0, a = 1}, -- 5
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
        HideWhenDead    = true,
        HideInVehicle   = true,
        HideInPetBattle = true,
        HideNotActive   = true,
        HideNoCombat    = false,
      },
      TestMode = {
        MaxResource = false,
      },
      Layout = {
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
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          All = false,
          r = 0, g = 0, b = 0, a = 1,
          {r = 0, g = 0, b = 0, a = 1},  -- 1
          {r = 0, g = 0, b = 0, a = 1},  -- 2
          {r = 0, g = 0, b = 0, a = 1},  -- 3
          {r = 0, g = 0, b = 0, a = 1},  -- 4
          {r = 0, g = 0, b = 0, a = 1},  -- 5
        },
      },
      BackgroundTime = {
        PaddingAll = true,
        BackdropSettings = {
          BgTexture = DefaultBgTexture,
          BdTexture = DefaultBdTexture,
          BgTile = false,
          BgTileSize = 16,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
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

   Hide not Usable       Disable and hides the bar if it's not usable by the class or spec.
   Hide when Dead      Hide the bar when the player is dead.
   Hide in Vehicle        Hide the bar if a vehicle.
   Hide in Pet Battle     Hide the bar if in a pet battle.
   Hide not Active        Hide the bar when it's not active and out of combat.
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


|cff00ff00Eclipse Bar - Predicted Power|r
When predicted eclipse power is turned on.  The mod will show what state the eclipse bar will be in before the cast is finished.


|cff00ff00Copy and Paste|r
Go to the copy and paste options.  Click on a button from the button menu on the top row.  This selects a bottom row of buttons. Click on the bottom button you want to copy then pick another bar in the options and click the same button to do the paste.  For text lines you can copy and paste within the same bar or to another bar.


|cff00ff00Align and Swap|r
Right click on any bar to open this tool up.  Then click on align or swap.
Align will allow you to line up a bar with another bar.  Just drag the bar near another till you see a green rectangle.  The bar will then jump next the other bar based on where you place it.  You can keep doing this with more bars.  The tool remembers all the bars you aligned as long as you don't close the tool or uncheck align or switch to swap.

You can use vertical or horizontal padding to space apart the aligned bars.  The vertical only works for bars that were aligned vertically and the same for horizontal.  Once you have 2 or more aligned bars they become an aligned group.  Then you can use offsets to move the group.

If you choose swap, then when you drag the bar near another bar. It will have a red rectangle around it.  Soon as you place it there the two bars will switch places.

This same tool can be used on bar objects.  When you go to the bar options under layout you'll see swap and float.  Clicking float will open up the align tool further down.

For more you can watch the video:
|Cffffff00http://www.youtube.com/watch?v=STYa5d6riuk|r


|cff00ff00Test Mode|r
When in test mode the bars will behave as if they were unlocked.  But you can't click on them.  Test mode allows you to make changes to the bar without having to go into combat to make certain parts of the bar become active.

Additional options will be found at the option panel for the bar when test mode is active


|cff00ff00Profiles|r
Its recommended that once you have your perfect configuration made you make a backup of it using profiles.  Just create a new profile named backup.  Then copy your config to backup.  All characters by default start with a new config, but you can share one across all characters or any of your choosing.
]]

-- Message Text
GUB.DefaultUB.MessageText = [[
|Cffffff00Galvin's UnitBars|r

Tons of changes have been made.  Please read the help text.  If something is not working please check that bar's settings.

|cff00ff00Eclipse Bar|r
Sun and Moon offsets have been removed.  Use float mode and alignment to offset these.

|cff00ff00New Features|r
Anticipation bar for rogues and Maelstrom bar for shaman added.
Smooth Fill:  Makes a bar change smoothly when its value changes.
Align and Swap:  Replaces the alingment tool. Can also be used on boxes in a bar.
Slope:  Adds a curve to a bar when vertical or horizontal.
Test Mode:  Make changes to bars without having to use combat to do it.
Hide Location Info:  Bars show their current location when being moved.  This hides it.
Border Padding:  Sets the amount of distance between the boxes and the bars border.
Float:  Same as the rune bars.  When in float the bars objects can be moved anywhere.
Texture Scale:  Changes the size of any textures when not in box mode.
Hide Text:  Hides any text displayed by the bar.

For a full list of changes go to http://www.curse.com/addons/wow/galvins-unitbars
]]



