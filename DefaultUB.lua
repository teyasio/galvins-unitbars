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
GUB.DefaultUB.Version = GetAddOnMetadata(MyAddon, 'Version') * 100

-------------------------------------------------------------------------------
-- UnitBar table data structure.
-- This data is used in the root of the unitbar data table and applies to all bars.  Accessed by UnitBar.Key.
--
-- Point                  - Current location of UnitBarsParent
-- RelativePoint          - Relative point of UIParent for UnitBarsParent.
-- Px, Py                 - The current location of the UnitBarsParent on the screen.
-- EnableClass            - Boolean. If true all unitbars get enabled for your class only.
-- Grouped                - Boolean. If true all unitbars get dragged as one object.
--                                         If false each unitbar can be dragged by its self.
-- Locked                 - Boolean. If true all unitbars can not be clicked on.
-- Clamped                - Boolean. If true all frames can't be moved off screen.
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
--
-- HidePlayerFrame        - Hides the player frame
--                           0 -- doesn't do anything after reload UI. To avoid conflicts with other addons.
--                           1 -- hide
--                           2 -- show
-- HideTargetFrame        - Same as above.
--
-- HideTooltipsLocked     - Boolean. If true tooltips are not shown when mousing over locked bars.
-- HideTooltipsNotLocked  - Boolean. If true tooltips are not shown when mousing over unlocked bars.
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
-- DebugOn                - If true then the debug options will show any errors.
-- AltPowerBarDisabled    - If true then all the alt power bar options are disabled. And blizzard style bars will be used.
-- AltPowerBarShowUsed    - If true then show only bars that you used in the alt power bar options
-- ClassTaggedColor       - Boolean.  If true then if the target is an NPC, then tagged color will be shown.
-- APBMoverOptionsDisabled - If true then blizzards alternate power bars will not be moved.
-- EABMoverOptionsDisabled - If true then extra action button will not be moved.
-- APBPos                 - Contains the position of the blizzards alternate power bar relative to UIParent
-- APBTimerPos            - Contains the position of the blizzards alternate power timer relative to UIParent
-- EABPos                 - Contains the position of the extra action button relative to UIParent
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
--   UnitType             - For Health and Power bars. Type of unit: 'player', 'pet', 'focus', 'target'
--   Enabled              - If true bar can be used, otherwise disabled.  Will not appear in options.
--   BarVisible()         - Returns true or false.  This gets referenced by UnitBarsF. Not all bars use this. Set in Main.lua
--   ClassSpecs           - See main.lua CheckClassSpecs()
--
--   x, y                 - Current location of the Anchor relative to the UnitBarsParent.
--   Status               - Table that contains a list of flags marked as true or false.
--                          If a flag is found true then a statuscheck will be done to see what the
--                          bar should do. Flags with a higher priority override flags with a lower.
--                          Flags from highest priority to lowest.
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
--     FontBarPosition    - Position relative to the font's parent.  Can be one of the 9 standard setpoints.
--     FontAnchorPosition - Same as Position except its the font's anchor
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
local GUBSquareBorderTexture = 'GUB Square Border'
local DefaultSound = 'None'
local DefaultSoundChannel = 'SFX'
local UBFontType = 'Arial Narrow'
local DefaultAnimationType = 'alpha'
local DefaultAnimationOutTime = 0.7
local DefaultAnimationInTime = 0.30

GUB.DefaultUB.InCombatOptionsMessage  = "Can't have options opened during combat"
GUB.DefaultUB.InCombatOptionsMessage2 = 'Options will open after combat ends'

GUB.DefaultUB.DefaultBgTexture = DefaultBgTexture
GUB.DefaultUB.DefaultBorderTexture = DefaultBorderTexture
GUB.DefaultUB.DefaultStatusBarTexture = DefaultStatusBarTexture
GUB.DefaultUB.DefaultSound = DefaultSound
GUB.DefaultUB.DefaultSoundChannel = DefaultSoundChannel
GUB.DefaultUB.DefaultFontType = UBFontType

-- Default trigger array stuff
GUB.DefaultUB.TriggerTalentsArray = {
  SpellID = 0,
  Match = true,
  IsPvP = false,
  Minimized = false,
}
GUB.DefaultUB.TriggerConditionsArray = {
  InputValueName = '', -- check triggers sets default
  Operator = '>',
  Value = 0,
}
GUB.DefaultUB.TriggerAurasArray = {
  Minimized = false,
  Inverse = false,
  Units = {'player'},
  SpellID = 0,
  Own = 0,
  Type = 0,
  StackOperator = '>=',
  Stacks = 0,
  CheckDebuffTypes = false,

  -- Debuff types
  Curse = false,
  Disease = false,
  Enrage = false,
  Magic = false,
  Poison = false,
}

local DefaultTriggers = {
  Static = false,
  Disabled = false,
  SpecEnabled = false,
  OneTime = false,
  -- ClassSpecs is deepcopied in down below in each bar
  -- ClassSpecs = SetClassSpecs(ClassSpecs, false),
  Talents    = { Disabled = false, All = false },
  Conditions = { Disabled = false, All = false },
  Auras      = { Disabled = false, All = false },
  Name = '',
  GroupNumber = 1,
  ObjectType = '',
  ObjectTypeID = '',
  ColorUnit = '',
  ColorFnType = '',
  CanAnimate = false,
  Animate = false,
  AnimateSpeed = 0.01,
  OffsetAll = true,
  TextLine = false,
  AurasOn = false,
  ActiveAuras = false,
  ConditionsOn = false,

  -- These are functions.  But functions can't be saved
  -- So set false as a default
  ColorFn = false,
  BarFn = false,
--Par1
--Par2
--Par3
--Par4   These are not in defaults for nil default checks
--       These are on the CheckTriggers exclude list
}

local abs, assert, format, pairs, ipairs, type, next =
      abs, assert, format, pairs, ipairs, type, next
local GetNumSpecializationsForClassID, GetSpecializationInfoForClassID, GetNumClasses, GetClassInfo =
      GetNumSpecializationsForClassID, GetSpecializationInfoForClassID, GetNumClasses, GetClassInfo

-- Build spec list.  Should work at loadup
local ClassSpecializations = {}

for ClassIndex = 1, GetNumClasses() do
  local Specs = {}
  local _, Class = GetClassInfo(ClassIndex)

  ClassSpecializations[Class] = Specs

  for ClassSpec = 1, GetNumSpecializationsForClassID(ClassIndex) do
    local _, SpecName = GetSpecializationInfoForClassID(ClassIndex, ClassSpec)

    Specs[ClassSpec] = SpecName
  end
end
GUB.DefaultUB.ClassSpecializations = ClassSpecializations


--[[
GUB.DefaultUB.ClassSpecializations = {
  DEATHKNIGHT = {'Blood', 'Frost', 'Unholy'},
  DEMONHUNTER = {'Havoc', 'Vengeance'},
  DRUID       = {'Balance', 'Feral', 'Guardian', 'Restoration'},
  HUNTER      = {'Beast Mastery', 'Marksmanship', 'Survival'},
  MAGE        = {'Arcane', 'Fire', 'Frost'},
  MONK        = {'Brewmaster', 'Mistweaver', 'Windwalker'},
  PALADIN     = {'Holy', 'Protection', 'Retribution'},
  PRIEST      = {'Discipline', 'Holy', 'Shadow'},
  ROGUE       = {'Assassination', 'Outlaw', 'Subtlety'},
  SHAMAN      = {'Elemental', 'Enhancement', 'Restoration'},
  WARLOCK     = {'Affliction', 'Demonology', 'Destruction'},
  WARRIOR     = {'Arms', 'Fury', 'Protection'},
}
]]

local function MergeTable(Source, Dest)
  for k, v in pairs(Dest) do
    Source[k] = v
  end

  return Source
end

-- Same as deepcopy except it can add a new key and table
-- SourceKey must be an existing key in the source
-- AddTableWithKey must contain a key and table
local function DeepCopy(Source, SourceKey, AddTableWithKey)
  local Copy = {}

  for k, v in pairs(Source) do
    if type(v) == 'table' then
      v = DeepCopy(v)
    end
    Copy[k] = v
  end

  if AddTableWithKey then
    local AddKey = next(AddTableWithKey)
    if SourceKey then
      Copy[SourceKey][AddKey] = DeepCopy(AddTableWithKey[AddKey])
    end
    Copy[AddKey] = DeepCopy(AddTableWithKey[AddKey])
  end

  return Copy
end

-- Flag = false: set everything to false
-- True doesn't do anything
-- Negative number means false for that spec
local function SetClassSpecs(ClassSpecs, Flag)
  local CS = {}
  Flag = Flag == nil or Flag

  for ClassName, ClassSpec in pairs(ClassSpecs) do
    if type(ClassSpec) == 'table' then
      local t = {}
      CS[ClassName] = t

      -- Check for empty table
      if next(ClassSpec) == nil then
        assert(false, format('Class Table Empty: %s', ClassName))
      end

      if #ClassSpec == 1 and type(ClassSpec[1]) == 'boolean' then
        local SpecFlag = Flag

        if Flag then
          SpecFlag = ClassSpec[1]
        end
        for Index in ipairs(ClassSpecializations[ClassName]) do
          t[Index] = SpecFlag
        end
      else
        local SpecFlag = Flag

        for Index, SpecNumber in pairs(ClassSpec) do
          if Flag then
            SpecFlag = SpecNumber > 0
          end
          t[abs(SpecNumber)] = SpecFlag
        end
      end
    else
      CS[ClassName] = ClassSpec
    end
  end

  return CS
end

--=============================================================================
-- Default Profile Database
--=============================================================================
GUB.DefaultUB.Default = {
  -- global can be seen by any character on the same account
  global = {
    ShowMessage = 0,
    APBShowUsed = true,
    AutoExpand = true,
    ExpandAll = false,
    APBUsed = {},
    APBUseBlizz = {}
  },
  profile = {
    Point = 'CENTER',
    RelativePoint = 'CENTER',
    Px = 0,
    Py = 0,
    Show = false,
    EnableClass = true,
    Grouped = false,
    Locked = false,
    Clamped = true,
    Testing = false,
    HideTooltipsLocked = false,
    HideTooltipsNotLocked = false,
    HideTooltipsDesc = false,
    HideLocationInfo = false,
    BarFillFPS = 60,
    Align = false,
    Swap = false,
    AlignSwapAdvanced = false,
    AlignSwapPaddingX = 0,
    AlignSwapPaddingY = 0,
    AlignSwapOffsetX = 0,
    AlignSwapOffsetY = 0,
    HidePlayerFrame = 0, -- 0 means do nothing not checked 1 = hide, 2 = show
    HideTargetFrame = 0, -- 0 means do nothing not checked 1 = hide, 2 = show
    HideTextHighlight = false,
    AlignAndSwapEnabled = true,
    ReverseAnimation = true,
    AnimationType = 'alpha',
    AnimationInTime = DefaultAnimationInTime,
    AnimationOutTime = DefaultAnimationOutTime,
    HighlightDraggedBar = false,
    AuraListOn = false,
    AuraListUnits = 'player',
    DebugOn = false,
    APBMoverOptionsDisabled = true,
    APBPos = {},
    APBTimerPos = {},
    EABMoverOptionsDisabled = true,
    EABPos = {},
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
    Reset = {}
  },
}
local Profile = GUB.DefaultUB.Default.profile
local ClassSpecs

-- for empty tables
local T = true
local F = false


--=============================================================================
-- Player Health
--=============================================================================
ClassSpecs = { -- This is used for all health and power bars
  All = true, Inverse = false, ClassName = '',
  DEATHKNIGHT = {T}, DEMONHUNTER = {T}, DRUID = {T}, HUNTER = {T}, MAGE    = {T}, MONK    = {T},
  PALADIN     = {T}, PRIEST      = {T}, ROGUE = {T}, SHAMAN = {T}, WARLOCK = {T}, WARRIOR = {T}
}

Profile.PlayerHealth = {
  _Name = 'Player Health',
  _OptionOrder = 1,
  _UnitType = 'player',
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = 230,
}
MergeTable(Profile.PlayerHealth, {
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
    AbsorbHealth = 0.25,
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
    AbsorbHealth = true,
    ClassColor = false,
    CombatColor = false,
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
    AbsorbBarSize = 1,
    AbsorbBarDontClip = true,
    PaddingAll = true,
    Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
    StatusBarTexture = DefaultStatusBarTexture,
    PredictedBarTexture = DefaultStatusBarTexture,
    AbsorbBarTexture = DefaultStatusBarTexture,
    Color = {r = 0, g = 1, b = 0, a = 1},
    PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
    AbsorbColor = {r = 0, g = 0.752, b = 1, a = 1},
  },
  Text = {
    _DC = 0,
    _ValueNameMenu = 'health',

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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- Player Power
--=============================================================================
Profile.PlayerPower = {
  _Name = 'Player Power',
  _OptionOrder = 2,
  _UnitType = 'player',
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = 200,
}
MergeTable(Profile.PlayerPower, {
  Status = {
    ShowAlways      = false,
    HideWhenDead    = true,
    HideNoTarget    = false,
    HideInVehicle   = true,
    HideInPetBattle = true,
    HideNotActive   = false,
    HideNoCombat    = false,
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- Target Health
--=============================================================================
Profile.TargetHealth = {
  _Name = 'Target Health',
  _OptionOrder = 3,
  _UnitType = 'target',
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = 170,
}
MergeTable(Profile.TargetHealth, {
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
    AbsorbHealth = 0.25,
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
    AbsorbHealth = true,
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
    AbsorbBarSize = 1,
    AbsorbBarDontClip = true,
    PaddingAll = true,
    Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
    StatusBarTexture = DefaultStatusBarTexture,
    PredictedBarTexture = DefaultStatusBarTexture,
    AbsorbBarTexture = DefaultStatusBarTexture,
    Color = {r = 0, g = 1, b = 0, a = 1},
    PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
    TaggedColor = {r = 0.5, g = 0.5, b = 0.5, a = 1},
    AbsorbColor = {r = 0, g = 0.752, b = 1, a = 1},
  },
  Text = {
    _DC = 0,
    _ValueNameMenu = 'health',

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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- Target Power
--=============================================================================
Profile.TargetPower = {
  _Name = 'Target Power',
  _OptionOrder = 4,
  _UnitType = 'target',
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = 140,
}
MergeTable(Profile.TargetPower, {
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
    PaddingAll = true,
    Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
    StatusBarTexture = DefaultStatusBarTexture,
    Color = {r = 0, g = 1, b = 0, a = 1},
  },
  Text = {
    _DC = 0,
    _ValueNameMenu = 'hap',

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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- Focus Health
--=============================================================================
Profile.FocusHealth = {
  _Name = 'Focus Health',
  _OptionOrder = 5,
  _UnitType = 'focus',
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = 110,
}
MergeTable(Profile.FocusHealth, {
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
    AbsorbHealth = 0.25,
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
    AbsorbHealth = true,
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
    AbsorbBarSize = 1,
    AbsorbBarDontClip = true,
    PaddingAll = true,
    Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
    StatusBarTexture = DefaultStatusBarTexture,
    PredictedBarTexture = DefaultStatusBarTexture,
    AbsorbBarTexture = DefaultStatusBarTexture,
    Color = {r = 0, g = 1, b = 0, a = 1},
    PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
    TaggedColor = {r = 0.5, g = 0.5, b = 0.5, a = 1},
    AbsorbColor = {r = 0, g = 0.752, b = 1, a = 1},
  },
  Text = {
    _DC = 0,
    _ValueNameMenu = 'health',

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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- Focus Power
--=============================================================================
Profile.FocusPower = {
  _Name = 'Focus Power',
  _OptionOrder = 6,
  _UnitType = 'focus',
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = 80,
}
MergeTable(Profile.FocusPower, {
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
    PaddingAll = true,
    Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
    StatusBarTexture = DefaultStatusBarTexture,
    Color = {r = 0, g = 1, b = 0, a = 1},
  },
  Text = {
    _DC = 0,
    _ValueNameMenu = 'hap',

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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- Pet Health
--=============================================================================
ClassSpecs = { -- This is used for pet health and power
  All = false, Inverse = false, ClassName = '',
  DEATHKNIGHT = { 1, 2, 3 },
  WARLOCK     = { 1, 2, 3 },
  HUNTER      = { 1, 2, 3 },
  MAGE        = { -1, -2, 3 },
  DEMONHUNTER = {F}, DRUID = {F}, MONK   = {F}, PALADIN = {F},
  PRIEST      = {F}, ROGUE = {F}, SHAMAN = {F}, WARRIOR = {F}
}

Profile.PetHealth = {
  _Name = 'Pet Health',
  _OptionOrder = 7,
  _OptionText = 'Classes with pets only',
  _UnitType = 'pet',
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = 50,
}
MergeTable(Profile.PetHealth, {
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
    AbsorbHealth = 0.25,
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
    AbsorbHealth = true,
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
    AbsorbBarSize = 1,
    AbsorbBarDontClip = true,
    PaddingAll = true,
    Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
    StatusBarTexture = DefaultStatusBarTexture,
    PredictedBarTexture = DefaultStatusBarTexture,
    AbsorbBarTexture = DefaultStatusBarTexture,
    Color = {r = 0, g = 1, b = 0, a = 1},
    PredictedColor = {r = 0, g = 0.827, b = 0.765, a = 1},
    AbsorbColor = {r = 0, g = 0.752, b = 1, a = 1},
  },
  Text = {
    _DC = 0,
    _ValueNameMenu = 'health',

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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- Pet Power
--=============================================================================
Profile.PetPower = {
  _Name = 'Pet Power',
  _OptionOrder = 8,
  _OptionText = 'Classes with pets only',
  _UnitType = 'pet',
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = 20,
}
MergeTable(Profile.PetPower, {
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
    PaddingAll = true,
    Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
    StatusBarTexture = DefaultStatusBarTexture,
    Color = {r = 0, g = 1, b = 0, a = 1},
  },
  Text = {
    _DC = 0,
    _ValueNameMenu = 'hap',

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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- Mana Power
--=============================================================================
ClassSpecs = {
  All = false, Inverse = false, ClassName = '',
  DRUID  = { 1, -2, -3, -4 },
  PRIEST = { 3 },
  SHAMAN = { 1, 2 },
}

Profile.ManaPower = {
  _Name = 'Mana Power',
  _OptionOrder = 9,
  _OptionText = 'Druid, Priest, Shaman, or Monk only: Shown when normal mana bar is not available',
  _UnitType = 'player',
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = -10,
}
MergeTable(Profile.ManaPower, {
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- StaggerBar
--=============================================================================
ClassSpecs = {
  All = false, Inverse = false, ClassName = '',
  MONK = { 1 },
}

Profile.StaggerBar = {
  _Name = 'Stagger Bar',
  _OptionOrder = 10,
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = -40,
}
MergeTable(Profile.StaggerBar, {
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
    PaddingAll = true,
    Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
    StatusBarTexture = DefaultStatusBarTexture,
    Color = {r = 1, g = 1, b = 1, a = 1},
  },
  Text = {
    _DC = 0,
    _ValueNameMenu = 'stagger',

    { -- 1
      Custom = false,
      Layout = '',
      ValueNames = {'current'},
      ValueTypes = {'percent'},

      FontType = UBFontType,
      FontSize = 16,
      FontStyle = 'NONE',
      FontHAlign = 'CENTER',
      FontVAlign = 'MIDDLE',
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- AlternatePowerBar
--=============================================================================
ClassSpecs = {
  All = true, Inverse = false, ClassName = '',
  DEATHKNIGHT = {T}, DEMONHUNTER = {T}, DRUID = {T}, HUNTER = {T}, MAGE    = {T}, MONK    = {T},
  PALADIN     = {T}, PRIEST      = {T}, ROGUE = {T}, SHAMAN = {T}, WARLOCK = {T}, WARRIOR = {T}
}

Profile.AltPowerBar = {
  _Name = 'Alternate Power Bar',
  _OptionOrder = 11,
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = -200,
  _y = -70,
}
MergeTable(Profile.AltPowerBar, {
  Status = {
    ShowAlways      = false,
    HideWhenDead    = true,
    HideInVehicle   = false,
    HideInPetBattle = false,
    HideIfBlizzAltPowerVisible = true,
  },
  TestMode = {
    AltTypePower = true,
    AltTypeCounter = false,
    AltTypeBoth = false,
    AltPowerName = 'This is test mode',
    AltPower = 0,
    AltPowerMax = 0,
    AltPowerTime = 0,
    AltPowerBarID = 0,
    BothRotation = 180,
  },
  Layout = {
    EnableTriggers = false,
    ReverseFill = false,
    HideText = false,
    HideTextCounter = false,
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
  BackgroundPower = {
    PaddingAll = true,
    BgTexture = DefaultBgTexture,
    BorderTexture = GUBSquareBorderTexture,
    BgTile = false,
    BgTileSize = 16,
    BorderSize = 12,
    Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
    Color = {r = 0, g = 0, b = 0, a = 1},
    EnableBorderColor = false,
    BorderColor = {r = 1, g = 1, b = 1, a = 1},
  },
  BackgroundCounter = {
    PaddingAll = true,
    BgTexture = DefaultBgTexture,
    BorderTexture = GUBSquareBorderTexture,
    BgTile = false,
    BgTileSize = 16,
    BorderSize = 12,
    Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
    Color = {r = 0, g = 0, b = 0, a = 1},
    EnableBorderColor = false,
    BorderColor = {r = 1, g = 1, b = 1, a = 1},
  },
  BarPower = {
    Advanced = false,
    Width = 170,
    Height = 35,
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
    PaddingAll = true,
    Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
    StatusBarTexture = GUBStatusBarTexture,
    Color = {r = 0, g = 1, b = 0, a = 1},
  },
  BarCounter = {
    Advanced = false,
    Width = 170,
    Height = 35,
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
    PaddingAll = true,
    Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
    StatusBarTexture = GUBStatusBarTexture,
    Color = {r = 0, g = 1, b = 0, a = 1},
  },
  Text = {
    _DC = 0,
    _ValueNameMenu = 'altpower',

    { -- 1
      Custom    = false,
      Layout    = '',
      ValueNames = {'current', 'maximum'},
      ValueTypes = {'whole', 'whole'},

      FontType = UBFontType,
      FontSize = 16,
      FontStyle = 'OUTLINE',
      FontHAlign = 'CENTER',
      FontVAlign = 'MIDDLE',
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    }
  },
  Text2 = {
    _DC = 0,
    _ValueNameMenu = 'altcounter',
    Notes = '|cff00ff00Current and maximum counter are used when a counter has a max|r\n',

    { -- 1
      Custom    = false,
      Layout    = '',
      ValueNames = {'counter', 'countermin', 'countermax'},
      ValueTypes = {'whole', 'whole', 'whole'},

      FontType = UBFontType,
      FontSize = 16,
      FontStyle = 'OUTLINE',
      FontHAlign = 'CENTER',
      FontVAlign = 'MIDDLE',
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
      OffsetX = 0,
      OffsetY = 0,
      ShadowOffset = 0,
      Color = {r = 1, g = 1, b = 1, a = 1},
    },
  },
  Triggers = {
    _DC = 0,
    Notes = '|cff00ff00Counter is used for Darkmoon Faire games and anything else like it|r\n',
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- RuneBar
--=============================================================================
ClassSpecs = {
  All = false, Inverse = false, ClassName = '',
  DEATHKNIGHT = {T},
}

Profile.RuneBar = {
  _Name = 'Rune Bar',
  _OptionOrder = 12,
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = 0,
  _y = 229,
}
MergeTable(Profile.RuneBar, {
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'HORIZONTAL',
    RotateTexture = 0,
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
    _DC = 0,
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
      FontBarPosition = 'CENTER',
      FontAnchorPosition = 'CENTER',
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
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- ComboBar
--=============================================================================
ClassSpecs = {
  All = false, Inverse = false, ClassName = '',
  ROGUE = {T}, DRUID = {T},
}

Profile.ComboBar = {
  _Name = 'Combo Bar',
  _OptionOrder = 13,
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = 0,
  _y = 195,
}
MergeTable(Profile.ComboBar, {
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
    ComboPoints = 0,
    DeeperStratagem = false,
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
  Bar = {
    Advanced = false,
    Width = 40,
    Height = 25,
    RotateTexture = 0,
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
  Triggers = {
    _DC = 0,
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- HolyBar
--=============================================================================
ClassSpecs = {
  All = false, Inverse = false, ClassName = '',
  PALADIN = { 3 },
}

Profile.HolyBar = {
  _Name = 'Holy Bar',
  _OptionOrder = 14,
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = 0,
  _y = 154,
}
MergeTable(Profile.HolyBar, {
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
    RotateTexture = 0,
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
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- ShardBar
--=============================================================================
ClassSpecs = {
  All = false, Inverse = false, ClassName = '',
  WARLOCK = { 1, 2 },
}

Profile.ShardBar = {
  _Name = 'Shard Bar',
  _OptionOrder = 15,
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = 0,
  _y = 112,
}
MergeTable(Profile.ShardBar, {
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
    RotateTexture = 0,
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
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- FragmentBar
--=============================================================================
ClassSpecs = {
  All = false, Inverse = false, ClassName = '',
  WARLOCK = { 3 },
}

Profile.FragmentBar = {
  _Name = 'Fragment Bar',
  _OptionOrder = 16,
  _OptionText = 'Destruction Warlocks only',
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = 150,
  _y = 112,
}
MergeTable(Profile.FragmentBar, {
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'VERTICAL',
    RotateTexture = 0,
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
    SyncFillDirection = true,
    Clipping = true,
    FillDirection = 'VERTICAL',
    RotateTexture = 0,
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
    Notes = '"|cff00ff00Fragments" are based on the amount of fill from 0 to 10 or percentage per shard|r\n',
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- ChiBar
--=============================================================================
ClassSpecs = {
  All = false, Inverse = false, ClassName = '',
  MONK = { 3 },
}

Profile.ChiBar = {
  _Name = 'Chi Bar',
  _OptionOrder = 17,
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = 0,
  _y = 69,
}
MergeTable(Profile.ChiBar, {
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
    RotateTexture = 0,
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
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )
--=============================================================================
-- ArcaneBar
--=============================================================================
ClassSpecs = {
  All = false, Inverse = false, ClassName = '',
  MAGE = { 1 },
}

Profile.ArcaneBar = {
  _Name = 'Arcane Bar',
  _OptionOrder = 18,
  _Enabled = true,
  ClassSpecs = SetClassSpecs(ClassSpecs),
  _x = 0,
  _y = 30,
}
MergeTable(Profile.ArcaneBar, {
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
    RotateTexture = 0,
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
    Default = DeepCopy(DefaultTriggers, nil, { ClassSpecs = SetClassSpecs(ClassSpecs, false) }),
  },
} )


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

|cff00ff00Importing and Exporting|r
To export all the settings for a unitbar.  Go to Import Export tab for that bar.  Unitbar settings can only be imported to the same bar.
To export a trigger go to Triggers -> List.  You'll see the import and export buttons there.  Triggers can be imported into other bars and they always get appended.

|cff00ff00Dragging and Dropping|r
To drag any bar around the screen use the left mouse button while pressing any modifier key (alt, shift, or control).  To move a things like runes use the right mouse button while pressing down any modifier key.


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
Each text line can have multiple values.  Click the add/remove buttons to add or remove values.  To add another text line click the add text line button.

You can add extra text to the layout.  Just modify the layout in the edit box.  After you click accept the layout will become a custom layout.  Clicking exit will take you back to a normal layout.  You'll lose the custom layout though.

The layout supports world of warcraft's UI escape color codes.  The format for this is ||cAARRGGBB<text>||r.  So for example to make percentage show up in red you would do ||c00FF0000%d%%||r.

The characters ||, %, ) are reserved.  To make these appear in the format string you need to double them so use "||||", "%%", or "))"

If the layout causes an error you will see a layout error appear in the format of Err (text line number). So Err (2) would mean text line 2 is causing the error.
Also the same error will appear above the edit box in the format of #:<Error Message>.  The # is the parameter the error happened on.

Here's some custom layout examples.

value1(%d%%) max2( : %d) -> (20%) : (999)
value1(Health %.f /) value2(Percentage %d%%) -> Health 999 / Percentage 20%
value1(%.2fk) -> 999.99k

You can also add \n for multiline

value1(%d%%\n) max2(%d) ->
(20%)
(999)

For more information you can check out the following links:

For text:]]
HelpText[#HelpText + 1] = [[https://youtu.be/GWyw_x1gHn8]]
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
Triggers lets you modify things based on Specialization, Talents, Auras, and Conditions.
They are executed in the order they appear from top to bottom.

The Trigger UI has 3 tabs:
   |cffff00ffList tab|r shows all the triggers and allows you to move, copy, delete, etc
   |cffff00ffActivation tab|r is what will cause a trigger to execute.
   |cffff00ffDisplay tab|r is what a trigger will modify.

|cff00ffffList Tab|r
If there are no triggers. Then you will only be able to add a trigger.  Click add. And the trigger will be added.
    |cffff00ffStatic|r Will always make the trigger active.  Cause of this the Activate tab will be greyed out.
    |cffff00ffDisable|r Will always make the trigger inactive. The Activate and Display tabs will be greyed out.
    |cffff00ffAdd|r Will list <add here> tags.  Select the tag where you want the trigger to go. Then click add here button. Copy and Move work in the same way.
    |cffff00ffSwap|r Works a little different.  When you click swap.  The swap tags will appear under each trigger.  The tag that appears under the trigger is the one it'll be swapped with.
    |cffff00ffDelete|r Will remove the trigger.  To bypass the dialog box just hold down a modifier key (alt, shift, or control) while clicking the delete button.
    |cffff00ffCancel|r Will exit the current edit function.

|cff00ffffActivate Tab|r
Talents, auras and conditions edit functions are the same.  They're self explanatory.
    |cffff00ffSpecialization|r Works the same way for bars except things are unchecked by default.
    |cffff00ffTalents|r There are two pull down menus one for PvE and PvP.  Just pick a talent and it'll appear above.  Selecting 'none' from the menu will remove the talent.
    |cffff00ffAuras|r By default an aura can match any debuff or buff based on the options picked. So for example you want to find any debuff that was of type disease.  You would click 'Buff' till it turns into 'Debuff'. Then click 'Check Debuff Types' and check off disease.
      |cffa6c4ffAura input box|r This will auto match spell names as you type.  Or you can type in the spell ID of the aura instead.  If you want to use an aura that was on you.  Then start to type that aura name and it'll be the first in the list. To remove the aura listed above. Just hit enter without typing anything.
    |cffff00ffConditions|r Self explanatory. But some bars will have input value names with a number after it.  That number matches the box of the bar.

|cff00ffffDisplay Tab|r
Some bars only have one component.  So the name pulldown menu will only have one name in it.  The type pulldown menu picks what part of the bar you want to change.  The 'All' items work well with static triggers.


|cff00ff00Aura List|r
Found under General.  This will list any auras the mod comes in contact with.  Type the different units into the unit box seperated by a space.  The mod will only list auras from the units specified. Then click refresh to update the aura list with the latest auras.


|cff00ff00Frames|r
Found under General.

|cff00ffffPORTRAITS|r Leave these unchecked to avoid conflicting with another addon doing the same thing.  Clicking on the option again changes it to 'show' and clicking again changes it back to unchecked.

|cff00ffffBLIZZARD ALTERNATE POWER BAR|r This lets you move the blizzard style alternate power bar and the timer.  The timers are used in places like the Darkmoon Faire.  Leave disabled to avoid conflicting with another addon doing the same thing.

|cff00ffffEXTRA ACTION BUTTON|r This lets you move the extra action button.  Leave disabled to avoid conflicting with another addon doing the same thing.


|cff00ff00Alt Power Bar|r
Found under General.  This lists all the alternate power bars in the game.  You can use this information to create triggers that go off of bar ID.  Not every bar will use a color, since blizzards alternate power bar uses textures that may have the color already baked in.

So a trigger may have to be created to solve the problem. Also a history is kept of which area alternate power bars were used.

To use the blizzard style alternate power bar.  Just check off the bar in the list.  Or if you want to use the blizzard style for all just disable.


|cff00ff00Profiles|r
Its recommended that once you have your perfect configuration made you make a backup of it using profiles.  Just create a new profile named backup.  Then copy your config to backup.  All characters by default start with a new config, but you can share one across all characters or any of your choosing.
]]


-- Videos text
local LinksText = {}

GUB.DefaultUB.LinksText = LinksText
LinksText[1] = [[
Fragment Bar video:]]
LinksText[#LinksText + 1] = [[https://youtu.be/snFdzm7c4M8]]
LinksText[#LinksText + 1] = [[

Rune Bar video:]]
LinksText[#LinksText + 1] = [[https://youtu.be/F02vOl7I8Q8]]
LinksText[#LinksText + 1] = [[

Stagger Bar video:]]
LinksText[#LinksText + 1] = [[https://youtu.be/7kHvv8Di0OY]]
LinksText[#LinksText + 1] = [[

Triggers video:]]
LinksText[#LinksText + 1] = [[https://youtu.be/bey_dQBZlmA]]
LinksText[#LinksText + 1] = [[

Align and Swap video:]]
LinksText[#LinksText + 1] = [[https://youtu.be/STYa5d6riuk]]
LinksText[#LinksText + 1] = [[

Align and Swap video:]]
LinksText[#LinksText + 1] = [[https://youtu.be/GWyw_x1gHn8]]
LinksText[#LinksText + 1] = [[

Alternate Power Bar video:]]
LinksText[#LinksText + 1] = [[https://youtu.be/g8WgT_6tid8]]
LinksText[#LinksText + 1] = [[

UI escape codes:]]
LinksText[#LinksText + 1] = [[http://wow.gamepedia.com/UI_escape_sequences]]

-- Message Text
local ChangesText = {}

GUB.DefaultUB.ChangesText = ChangesText
ChangesText[1] = [[
Version 6.73
|cff00ff00Import and Export|r added to Unitbars and Triggers.  For Unitbars, the export and import tab can be found at the root menu for each bar.  For triggers, can be found under list tab under triggers

Version 6.70
|cff00ff00Triggers|r has been rewritten.  GUB will attempt to convert all your triggers over.  You may need to fix some triggers
|cff00ff00ComboBar|r Removed all anticipation code

Version 6.60
|cff00ff00Text|r font options has Changed.  Field width and field height has been removed. \n can be added in custom layout inside the () to do multiline text.  You may have to redo text options if you find something not where it was

Version 6.53
|cff00ff00Bars and Tooltips|r has Changed. You'll need to redo these settings found in General -> Main

Version 6.49
|cff00ff00Anchor|r setting in attributes has been reset to "TOPLEFT" due to code changes to how anchors work.  This is to fix the bar shifting bug

Version 6.40
|cff00ff00UI changes for the bar menu|r
|cff00ff00Auto Expand option added|r Found at the root of each bar menu.  It will expand the menu currently selected
|cff00ff00Expand all|r Expands all the bar menus at once.  Both these settings apply to all characters on the same account

Version 6.33
|cff00ff00Trigger|r talents menu now has a scrollbar

Version 6.31
|cff00ff00Blizzards Alternate Power Bar|r will show when GUBs alt power bar is turned off.  This replaces the disable option under General -> Alt Power Bar
|cff00ff00Aura Triggers|r The time it takes to load the spells pulldown menu has been greatly reduced
|cff00ff00Options|r Will automatically open after combat ends if you try to open during combat

Version 6.30
|cff00ff00|cff00ff00Frames|r Extra Action Button mover added

Version 6.20
|cff00ff00|cff00ff00Frames|r Alt Power Bar settings has changed.  This now lets you move blizzards APB
|cff00ff00|cff00ff00Alternate Power Bar|r Now lets you pick which bars you want to use as the blizzard style instead of GUB

Version 6.10
|cff00ff00|cff00ff00StatusBars|r no longer uses Blizzards.  This means no more texture stretching

|cff00ff00Bar Options|r now has 'Sync Fill Direction' and 'Clipping' for bars that fill
|cff00ff00Rotation|r now has 4 different angles (-90, 0, 90, and 180)
|cff00ff00Sync Fill Direction|r default on.  This will change the fill direction to fit the rotation
|cff00ff00Clipping|r default on.  This can turn clipping off making textures stretch when filling

Version 6.01
|cff00ff00Conditions|r for triggers.  New operators added 'T<>', 'T=', 'P<>', and 'P='. Works like normal operators except these check talents that are active. P is for PvP talents. These are only available for Percent and Whole Number

Version 6.00
|cff00ff00Specializations|r for mana power and pet bars.  Now have defaults set for class or specs that always have a pet.  All other specs set to unchecked

Version 5.72
|cff00ff00Absorb Health|r added to all health bars.  Options found under 'Layout' and 'Bar'
|cff00ff00Text|r for health and power bars.  Predicted Power, Predicted Cost, Predicted Health, and Absorb Health. Will not show if their value is zero

Version 5.70
|cff00ff00Specialization|r settings in triggers will have to be redone.  This has been recoded
|cff00ff00Specializations|r has been added to all bars.  This is found above 'Status'. This replaces the Hide not Usable option which has been ported to the 'All' setting

Version 5.60
** ALL CUSTOM TEXT WILL CAUSE AN ERROR
** You'll need to go into text options, exit custom text and create a new one.

|cff00ff00Alternate Power Bar|r has been added
|cff00ff00Alt Power Bar List|r found under 'General' options. Use this to help with triggers for Alternate Power Bar
|cff00ff00Text|r has been given a few changes
|cff00ff00Frames|r found under 'General' options.  Lets you hide/show the Player and Target Frame or Alternate Power Bar
|cff00ff00"%d"|r no longer used for whole numbers in text. Since it can cause an integer overflow if the number is too high such as on bosses
|cff00ff00Reset options|r now has pause text, this was missing
|cff00ff00Links|r added to 'Help'.  Has all the links to videos and websites

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
