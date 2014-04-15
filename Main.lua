--
-- Main.lua
--
-- Displays different bars for each class.  Rage, Energy, Mana, Runic Power, etc.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local DefaultUB = GUB.DefaultUB
local Version = DefaultUB.Version
local DUB = DefaultUB.Default.profile

local Main = {}
local UnitBarsF = {}
local UnitBarsFE = {}
local Bar = {}
local HapBar = {}
local Options = {}

GUB.Main = Main
GUB.Bar = Bar
GUB.HapBar = HapBar
GUB.RuneBar = {}
GUB.ComboBar = {}
GUB.AnticipationBar = {}
GUB.HolyBar = {}
GUB.ShardBar = {}
GUB.DemonicBar = {}
GUB.EmberBar = {}
GUB.EclipseBar = {}
GUB.ShadowBar = {}
GUB.ChiBar = {}
GUB.MaelstromBar = {}
GUB.Options = Options

LibStub('AceAddon-3.0'):NewAddon(GUB, MyAddon, 'AceConsole-3.0', 'AceEvent-3.0')

local LSM = LibStub('LibSharedMedia-3.0')
local MistsVersion = select(4, GetBuildInfo()) >= 50000

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber =
      strfind, strsplit, strsub, strupper, strlower, strmatch, strrev, format, strconcat, gsub, tonumber
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

------------------------------------------------------------------------------
-- Register GUB textures with LibSharedMedia
------------------------------------------------------------------------------
LSM:Register('statusbar', 'GUB Bright Bar', [[Interface\Addons\GalvinUnitBars\Textures\GUB_SolidBrightBar.tga]])
LSM:Register('statusbar', 'GUB Dark Bar', [[Interface\Addons\GalvinUnitBars\Textures\GUB_SolidDarkBar.tga]])
LSM:Register('statusbar', 'GUB Empty', [[Interface\Addons\GalvinUnitBars\Textures\GUB_EmptyBar.tga]])

------------------------------------------------------------------------------
-- Unitbars frame layout and animation groups.
--
-- UnitBarsParent
--   Anchor
--     Fade
--     ScaleFrame
--       <Unitbar frames start here>
--
--
-- UnitBarsF structure    NOTE: To access UnitBarsF by index use UnitBarsFE[Index].
--                              UnitBarsFE is used to enable/disable bars in SetUnitBars().
--
-- UnitBarsParent         - Child of UIParent.  The perpose of this is so all bars can be moved as a group.
-- UnitBarsF[]            - UnitBarsF[] is a frame and table.  This is so each bar can have its own events,
--                          and all data for each bar.
--   Anchor               - Child of UnitBarsParent.  The root of every bar.  Controls hide/show
--                          and size of a bar and location on the screen.  Also brings the bar to top level when clicked.
--                          From my testing any frame that gets clicked on that is a child of a frame with SetToplevel(true)
--                          will bring the parent to top level even if the parent wasn't the actual frame clicked on.
--   Anchor.UnitBar       - This is used for moving since the move code needs to update the bars position data after each move.
--   Anchor.Name          - Name of the UnitBar.  This is used by the aling and swap options which uses MoveFrameStart()
--   ScaleFrame           - Child of Anchor.  Controls scaling of bars to be made larger or smaller thru SetScale().
--   Fade                 - Table containing the fading animation groups/methods.  The groups are a child of Anchor.
--
--
-- UnitBarsF has methods which make changing the state of a bar easier.  This is done in the form of
-- UnitBarsF[BarType]:MethodCall().  BarType is used through out the mod.  Its the type of bar being referenced.
-- Search thru the code to see how these are used.
--
--
-- List of UninBarsF methods:
--
--   Update()             - This is how information from the server gets to the bar.
--   Enable()             - Disables events if passed true otherwise enables events.
--   StatusCheck()        - All bars have flags that determin if a bar should be visible in combat or never shown.
--                          When this gets called the bar checks the flags to see if the bar should change its state.
--   EnableMouseClicks()  - Enable or disable mouse interaction with the bar.
--   SetAttr()            - This sets the layout and different parts of the bar. Color, size, font, etc.
--   BarVisible()         - This is used by StatusCheck() to determin if a bar should be hidden.  Bars like focus and target
--                          need to be hidden when the player doesn't have a target or focus.
--   SetSize()            - This can change the location and/or size of the Anchor.
--
--
-- UnitBarsF data.  Each bar has data that keeps track of the bars state.
--
-- List of UnitBarsF values.
--
--   Anchor               - Frame that holds the location of the bar.  This is a child of UnitBarsParent.
--   Created              - If nil then the bar has not been created yet, otherwise true.
--   OldEnabled           - Current state of the bar. This is used to detect if a bar is being changed from enabled to disabled or
--                          vice versa.  Used by SetUnitBars().
--   Visible              - True or false.  If true then the bar is visible otherwise hidden.
--   IsActive             - True, false, or 0.
--                            True   The bar is considered to be doing something.
--                            False  The bar is not active.
--                            0      The bar is waiting to be active again.  If the flag is checked by StatusCheck() and is false.
--                                   Then it sets it to zero.
--   BaseWidth            - Used by SetUnitBarSize() to control scaling.
--   BaseHeight           - Used by SetUnitBarSize() to control scaling.
--   Width                - Width of the bar based on Anchor.
--   Height               - Height of the bar based on Anchor.
--   BarType              - Mostly for debugging.  Contains the type of bar. 'PlayerHealth', 'RuneBar', etc.
--   UnitBar              - Reference to the current UnitBar data which is the current profile.  Each time the
--                          profile changes this value gets referenced to the new profile. This is the same
--                          as UnitBars[BarType].
--
--
-- UnitBar mod upvalues/tables.
--
-- GUBData                - Reference to GalvinUnitBarsData.  Anything stored in here gets saved in the profile.
-- PowerColorType         - Table used by InitializeColors()
-- ConvertPowerType       - Table to convert a string powertype into a number or back into a number.
-- InitOnce               - Used by OnEnable to initialize just one time.
-- MessageBox             - Contains the message box to show a message on screeen.
-- TrackingFrame          - Used by MoveFrameGetNearestFrame()
-- MouseOverDesc          - Mouse over tooltip displayed to drag bar.
-- UnitBarVersion         - Current version of the mod.
-- AlignAndSwapTooltipDesc - Tooltip to be shown when the alignment tool is active.
--
-- InCombat               - True or false. If true then the player is in combat.
-- InVehicle              - True or false. If true then the player is in a vehicle.
-- InPetBattle            - True or false. If true then the player is in a pet battle.
-- IsDead                 - True or false. If true then the player is dead.
-- HasTarget              - True or false. If true then the player has a target.
-- HasFocus               - True or false. If true then the player has a focus.
-- HasPet                 - True or false. If true then the player has a pet.

-- PlayerClass            - Name of the class for the player in english.
-- PlayerGUID             - Globally unique identifier for the player.  Used by CombatLogUnfiltered()
-- PlayerPowerType        - The current power type for the player.
-- PlayerStance           - The current form/stance the player is in.
-- PlayerSpecialization   - The current specialization for the player
--
-- RegEventFrames         - Table used by RegEvent()
--
-- MoonkinForm
-- CatForm
-- BearForm
-- MonkMistWeaveSpec      - Current specs used by their bars.
--
-- MoveAlignDistance      - Amount of distance in pixels when aligning bars or bar objects.
-- MoveSelectFrame        - Current frame that is selected when swapping or aligning bars or bar objects
-- MoveLastSelectFrame    - Used to keep track of when a MoveSelectFrame changed.
-- MovePoint              - Current point for moveframe when aligning.
-- MoveSelectPoint        - Relative point to anchor MovePoint to on the MoveSelectFrame.
-- MoveLastHighlightFrame - Keeps track of what frame was last highlighted for align and swap for both bars and boxes.
-- MoveOldSelectFrame     - For alingment, keeps track of the last selected frame.  To pick the next closest frame.
-- MoveOldMFCenterX
-- MoveOldMFCenterY       - For alingment, used to calculate the linedistance between the oldselectframe and new one.
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Spell tracker
--
-- Keeps track of spells casting.
--
-- SpellTrackerEvent        - Used by TrackSpell().
--                            Converts an event from CombatLogUnfiltered() and/or SpellCasting() to one of the following:
--                              EventSpellStart
--                              EventSpellSucceeded
--                              EventSpellEnergize
--                              EventSpellMissed
--                              EventSpellFailed
--
-- SpellTrackerMessage      - Used by TrackSpell()
--                            Used with EventSpellFailed.  If the Message is not found in the table.
--                            then the spell is considered failed.
--
-- SpellTrackerTimeout      - Used by ModifySpellTracker()
--                            Amount of time before clearing the casting spell.
--
-- SpellTrackerTime         - Used by ModifySpellTracker(), CheckSpellTrackerTimeout()
--                            Keeps track of the time based on SpellTrackerTimeout. When time is reached
--                            the casting spell is removed.
--
-- SpellTrackerTimer        - Used by SetSpellTracker(), ModifySpellTracker()
--                            Timer handle for CheckSpellTrackerTimeout()
--
-- SpellTrackerActive       - Table used by SetSpellTracker(), SetSpellTrackerActive(), HideUnitBar()
--                            Keeps track of which bar has spell tracking turned off or on.
--                            Also keeps track of which bar is using the spell tracker.
--
-- SpellTrackerCasting      - Used by ModifySpellTracker(), CheckSpellTrackerTimeout(), TrackSpell()
--   SpellID                   Spell that is being cast.
--   LineID                    LineID of Spell
--   CastTime                  Amount of time for the spell to finish casting in seconds.
--   Fn                        Call back function.
--   UnitBarF                  Bar that is using the SpellID.
--
-- TrackedSpell[SpellID]    - Used by SetSpellTracker(), TrackSpell()
--   SpellID                   SpellID to search for.
--   EndOn                       'energize' the spell will be cleared on an energize event.
--                               'casting'  the spell will be cleared when the spell ends due to success, failed, etc.
--   Fn                     -  This gets called when a spell starts casting, then on end, and on energize.
--                             Fn(UnitBarF, SpellID, CastTime, Message)
--                               Message
--                                 'start'  Gets called on spell cast start.
--                                 'end'    Gets called on spell success.
--                                 'failed' Gets called if the spell didn't complete.
--                                 'timeout' Gets called by CheckSpellTrackerTimeout() if the spell timed out.
--                               CastTime  The amount of time to cast the spell in seconds.
--                               SpellID is always negative on 'start', 'end', or 'failed'
--                               UnitBarF  Unitbar that is using the spell tracker.
--   UnitBarF               -  Bar that is using the SpellID.
--
--
-- NOTE: See the notes on each of the spell tracker functions for more details.  Also
--       See Eclipse.lua on how this is used.
--       The spell tracker will turn its self off if the frame its being used on is hidden.
--       Will turn back on when frame is shown.  Assuming the system wasn't turned off before hand.
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Equipment set bonus
--
-- Keeps track of gear set bonus.
--
-- EquipmentSet[Slot][ItemID]    Holds the Tier number based on ItemID and Slot.
--                               Used by CheckSetBonus().
-- EquipmentSetBonus             Keeps track of 1 or more equipment set bonus.
-- EquipmentSetBonus[Tier]       Contains the active bonus of that tier set.
--                               GetSetBonus() and CheckSetBonus().
--
-- EquipmentSetRegisterEvent     if false then events for equipment set hasn't been registed.
--                               Otherwise they've been registered.
--                               Used by GetSetBonus()
--
-- NOTE: See Eclipse.lua on how this is used.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Fading Animation
--
-- Handles all the micromanaging of fading bars in and out based on a rule set.
-- If the bar is fading out, then no animations are played on the children.
-- So if you have a combo point fading out, and the bar starts to fade out.
-- Then the combo point will stop fading.  If a new combo point tries
-- to fade while the bar is fading, then the combo point will not fade.
--
-- These rules prevent the parent and children from fading at the same time.
-- If this were to happen then the alpha state of a texture/frame can get
-- stuck and reloading UI is the only way to fix it.
--
-- If a frame or texture is currently fading, its fading can be reversed
-- without having to stop the fade, just SetAnimation() to change it and
-- it will pick up from where it left off.
--
--
-- FadingAnimation      Table used by CreateFade() and SetAnimation().
--                      Keeps track of every animation and what bar is using them.
--
-- FadingAnimation
--   [UnitBarF]                    - To keep track of what bar is using fading.
--     Total                       - Total number of fading animation groups in use.
--     [Index] = Fade              - Array element containing the fade animation group.
--
--
-- Fade                       - Animation group for fading.
--   FadeA                    - Animation for fading.
--   UnitBarF                 - Unitbar that is using the animation.
--   Object                   - Parent of the animation group.
--   Action                   - if false no animation playing.
--                              'in' currently fading in.
--                              'out' currently fading out.
--   Parent                   - If true then its a parent fade.
--   DurationIn               - Time in seconds for fade in.
--   DurationOut              - Time in seconds for fade out.

--
-- Read the notes on CreateFade() on what methods to use in Fade.
--
-- Fade methods
--   SetDuration()
--   SetAnimation()
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- MoveFrames
--
-- Before a moveframe is moved.  MoveFrameStart checks to see if each frame
-- has a MoveHighlghtFrame.  If not it creates one and saves it to each frame.
-- This is then used to highlight each frame for align and swap.
--
-- MoveFrames functions allow frames to be dragged, dropped, swapped, or aligned.
--
-- MoveFrameStart added a Move table to the frames table passed to it.
--
-- Move table data structure
--
--   Frame        Frame to be moved on screen.
--   Frames       Table of frames to interact with the Frame being moved.
--   Parent       Parent of Frames.
--   Flags        Table containing the flags for Float, Align, and Swap.
--   FrameStrata  Stores the framestrata before moving a frame.
--   FrameLevel   Stores the framelevel befoe moving a frame.
--
--   FrameStrata and FrameLevel are used to restore the MoveFrame.
--   Before the move the framestrata is set to 'TOOLTIP'. This fixes the lag
--   problem when dragging and dropping a frame.
--
-- MoveFrameModifyAlignFrames creates the AlignFrames table which is stored
--   in the Move table.
--
-- AlignFrames data structure
--
--   MoveFrame          Frame that was moved.
--   SelectFrame        MoveFrame is aligned to this frame.
--   MovePoint          Anchor point on MoveFrame.
--   SelectPoint        Relative point on selectframe to set movepoint's anchor to.
--   PaddingDirectionX  Horizontal padding
--                        -1 Padding goes from right to left
--                        1  Padding goes from left to right
--                        0  No padding allowed
--   PaddingDirectionY  Vertical padding
--                        -1 Padding goes from bottom to top
--                        1  Padding goes from top to bottom
--                        0  No padding allowed.
--   Offset             MoveFrame is the offset frame instead of being padded.
--                      This offsets all the other frames that are chain connected
--                      thru alignment.
-------------------------------------------------------------------------------
local AlignAndSwapTooltipDesc = 'Right mouse button to align and swap this bar'
local MouseOverDesc = 'Modifier + left mouse button to drag this bar'
local TrackingFrame = CreateFrame('Frame')
local InitOnce = true
local GUBData = nil
local MessageBox = nil

local InCombat = false
local InVehicle = false
local InPetBattle = false
local IsDead = false
local HasTarget = false
local HasFocus = false
local HasPet = false
local PlayerPowerType = nil
local PlayerClass = nil
local PlayerStance = nil
local PlayerSpecialization = nil
local PlayerGUID = nil

local MoonkinForm = MOONKIN_FORM
local CatForm = CAT_FORM
local BearForm = BEAR_FORM
local MonkMistWeaverSpec = SPEC_MONK_MISTWEAVER

local MoveAlignDistance = 20
local MoveSelectFrame = nil
local MoveLastSelectFrame = nil
local MovePoint = nil
local MoveSelectPoint = nil
local MoveLastHighlightFrame = nil
local MoveOldSelectFrame = nil
local MoveOldMFCenterX = nil
local MoveOldMFCenterY = nil

local EquipmentSetRegisterEvent = false

local SpellTrackerTimeout = 7
local SpellTrackerTime = nil
local SpellTrackerTimer = nil
local SpellTrackerActive = {}

local EventSpellStart       = 1
local EventSpellSucceeded   = 2
local EventSpellEnergize    = 3
local EventSpellMissed      = 4
local EventSpellFailed      = 5

DUB.TargetHealth.BarVisible = function() return HasTarget end
DUB.TargetPower.BarVisible  = function() return HasTarget end
DUB.FocusHealth.BarVisible  = function() return HasFocus end
DUB.FocusPower.BarVisible   = function() return HasFocus end
DUB.PetHealth.BarVisible    = function() return HasPet end
DUB.PetPower.BarVisible     = function() return HasPet end
DUB.ManaPower.BarVisible    = function()
                                return  -- PlayerPowerType 0 is mana
                                  (PlayerClass == 'DRUID' or PlayerClass == 'MONK') and PlayerPowerType ~= 0
                              end
DUB.ComboBar.BarVisible     = function() return HasTarget end
DUB.EclipseBar.BarVisible   = function() return PlayerClass == 'DRUID' and (PlayerStance == MoonkinForm or PlayerStance == nil) end

local SpellTrackerCasting = {
  SpellID = 0,
  LineID = -1,
  Time = 0,
  CastTime = 0,
}

local SpellTrackerEvent = {
  UNIT_SPELLCAST_START       = EventSpellStart,
  UNIT_SPELLCAST_SUCCEEDED   = EventSpellSucceeded,
  SPELL_ENERGIZE             = EventSpellEnergize,
  SPELL_MISSED               = EventSpellMissed,
  SPELL_CAST_FAILED          = EventSpellFailed,
}

local SpellTrackerMessage = {         -- These variables are blizzard globals. Must be used for foreign languages.
  [SPELL_FAILED_NOT_READY]         = 1, -- SPELL_FAILED_NOT_READY
  [SPELL_FAILED_SPELL_IN_PROGRESS] = 1, -- SPELL_FAILED_SPELL_IN_PROGRESS
}

local TrackedSpell = {}

-- letter before ID is only to format the data here making it easier to read.
local EquipmentSet = {

-- Balanced druid set, ID, Normal, Heroic (tier 12)
  a1  = {[71108] = 12, [71497] = 12}, -- helmet
  a3  = {[71111] = 12, [71500] = 12}, -- shoulders
  a5  = {[71110] = 12, [71499] = 12}, -- chest
  a7  = {[71109] = 12, [71498] = 12}, -- legs
  a10 = {[71107] = 12, [71496] = 12}, -- gloves

-- Hunter set, ID, LFR, Normal, Heroic (tier 13)
  b1  = {[78793] = 13, [77030] = 13, [78698] = 13}, -- helmet
  b3  = {[78832] = 13, [77032] = 13, [78737] = 13}, -- shoulders
  b5  = {[78756] = 13, [77028] = 13, [78661] = 13}, -- chest
  b7  = {[78804] = 13, [77031] = 13, [78709] = 13}, -- legs
  b10 = {[78769] = 13, [77029] = 13, [78674] = 13}, -- gloves
}

local EquipmentSetBonus = {}

local RegEventFrames = {}

local FadingAnimation = {}

local UnitBarsParent = nil
local UnitBars = nil

local SelectFrameBorder = {
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

local DialogBorder = {
  bgFile   = LSM:Fetch('background', 'Blizzard Dialog Background'),
  edgeFile = LSM:Fetch('border', 'Blizzard Dialog'),
  tile = true,
  tileSize = 20,
  edgeSize = 20,
  insets = {
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}


local ConvertPowerType = {
  MANA = 0, RAGE = 1, FOCUS = 2, ENERGY = 3, RUNIC_POWER = 6,
  SOUL_SHARDS = 7, ECLIPSE = 8, HOLY_POWER = 9, CHI = 12,
  SHADOW_ORBS = 13, BURNING_EMBERS = 14, DEMONIC_FURY = 15,
  [0] = 'MANA', [1] = 'RAGE', [2] = 'FOCUS', [3] = 'ENERGY', [6] = 'RUNIC_POWER',
  [7] = 'SOUL_SHARDS', [8] = 'ECLIPSE', [9] = 'HOLY_POWER', [12] = 'CHI',
  [13] = 'SHADOW_ORBS', [14] = 'BURNING_EMBERS', [15] = 'DEMONIC_FURY',
}


local PowerColorType = {
  MANA = 0, RAGE = 1, FOCUS = 2, ENERGY = 3, RUNIC_POWER = 6,
}

-- Share with the whole addon.
Main.LSM = LSM
Main.PowerColorType = PowerColorType
Main.ConvertPowerType = ConvertPowerType
Main.UnitBarsF = UnitBarsF
Main.UnitBarsFE = UnitBarsFE

-------------------------------------------------------------------------------
--
-- Initialize the UnitBarsF table
--
-------------------------------------------------------------------------------
do
  local Index = 0
  for BarType, UB in pairs(DUB) do
    if type(UB) == 'table' and UB.Name then
      Index = Index + 1
      local UBFTable = CreateFrame('Frame')
      UnitBarsF[BarType] = UBFTable
      UnitBarsFE[Index] = UBFTable
    end
  end
end

-------------------------------------------------------------------------------
-- RegisterEvents
--
-- Register/unregister events
--
-- Action       'unregister' or 'register'
-- EventType    'main'             Registers the main events for the mod.
--              'spelltracker'     Registers events for spell tracker.
--              'setbonus'         Registers events for equipment set bonus
-------------------------------------------------------------------------------
local function RegisterEvents(Action, EventType)

  if EventType == 'main' then

    -- Register events for the addon.
    Main:RegEvent(true, 'UNIT_ENTERED_VEHICLE',          GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_EXITED_VEHICLE',           GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_DISPLAYPOWER',             GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_MAXPOWER',                 GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_PET',                      GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'PLAYER_REGEN_ENABLED',          GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_REGEN_DISABLED',         GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_TARGET_CHANGED',         GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_FOCUS_CHANGED',          GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_DEAD',                   GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_UNGHOST',                GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_ALIVE',                  GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_LEVEL_UP',               GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_TALENT_UPDATE',          GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PLAYER_SPECIALIZATION_CHANGED', GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'UPDATE_SHAPESHIFT_FORM',        GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PET_BATTLE_OPENING_START',      GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'PET_BATTLE_CLOSE',              GUB.UnitBarsUpdateStatus)

    -- Rest of the events are defined at the end of each lua file for the bars.

  elseif EventType == 'spelltracker' then
    local Flag = Action == 'register'

    -- register events for spell tracker.
    Main:RegEvent(Flag, 'COMBAT_LOG_EVENT_UNFILTERED', GUB.CombatLogUnfiltered)
    Main:RegEvent(Flag, 'UNIT_SPELLCAST_START',        GUB.SpellCasting, 'player')
    Main:RegEvent(Flag, 'UNIT_SPELLCAST_SUCCEEDED',    GUB.SpellCasting, 'player')

  elseif EventType == 'setbonus' then
    local Flag = Action == 'register'

    -- register event for equipment set bonus tracking.
    Main:RegEvent(Flag, 'PLAYER_EQUIPMENT_CHANGED', GUB.PlayerEquipmentChanged)
  end
end

-------------------------------------------------------------------------------
-- InitializeColors
--
-- Copy blizzard's power colors and class colors into the Defaults profile.
-------------------------------------------------------------------------------
local function InitializeColors()

  -- Copy the power colors.
  for PCT, PowerType in pairs(PowerColorType) do
    local Color = PowerBarColor[PCT]
    local r, g, b = Color.r, Color.g, Color.b

    for BarType, UB in pairs(DUB) do
      if BarType == 'PlayerPower' or BarType == 'TargetPower' or
         BarType == 'FocusPower' or BarType == 'PetPower' or BarType == 'ManaPower' then
        local Bar = UB.Bar

        Bar.Color = Bar.Color or {}
        Bar.Color[PCT] = {r = r, g = g, b = b, a = 1}
      end
    end
  end

  -- Copy the class colors.
  for Class, Color in pairs(RAID_CLASS_COLORS) do
    local r, g, b = Color.r, Color.g, Color.b

    for BarType, UB in pairs(DUB) do
      if BarType == 'PlayerHealth' or BarType == 'TargetHealth' or BarType == 'FocusHealth' then
        local Bar = UB.Bar

        Bar.Color = Bar.Color or {}
        Bar.Color[Class] = {r = r, g = g, b = b, a = 1}
      end
    end
  end
end

--*****************************************************************************
--
-- Unitbar utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- RegEvent/RegEventFrame
--
-- Registers an event to call a function.
--
-- Usage: RegEvent(Reg, Event, Fn, Units)
--        RegEventFrame(Reg, Frame, Event, Fn, Units)
--
-- Reg      If true then event gets registered otherwise unregistered.
-- Event    Event to register
-- Fn       Function to call when event fires.
-- Units    1 or 2 units. The event only fires if its unit matches.
-------------------------------------------------------------------------------
function GUB.Main:RegEventFrame(Reg, Frame, Event, Fn, ...)
  if Reg then
    if ... then
      Frame:RegisterUnitEvent(Event, ...)
    else
      Frame:RegisterEvent(Event)
    end
    Frame:SetScript('OnEvent', Fn)
  else
    Frame:UnregisterEvent(Event)
  end
end

function GUB.Main:RegEvent(Reg, Event, Fn, ...)

  -- Get frame based on Fn.
  local Frame = RegEventFrames[Fn]

  -- Create a new frame if one wasn't found.
  if Frame == nil then

    -- Create a new event frame for this event
    Frame = CreateFrame('Frame')
    RegEventFrames[Fn] = Frame
  end
  Main:RegEventFrame(Reg, Frame, Event, Fn, ...)
end

-------------------------------------------------------------------------------
-- ShowMessage
--
-- Displays a message on the screen in a box, with an Okay button.
-------------------------------------------------------------------------------
local function ShowMessage(Message)
  if MessageBox == nil then
    MessageBox = CreateFrame('ScrollFrame', nil, UIParent)
    MessageBox:SetSize(600, 310)
    MessageBox:ClearAllPoints()
    MessageBox:SetPoint('CENTER')
    MessageBox:SetBackdrop(DialogBorder)
    MessageBox:SetMovable(true)
    MessageBox:SetToplevel(true)
    MessageBox:SetClampedToScreen(true)
    MessageBox:SetScript('OnMouseDown', MessageBox.StartMoving)
    MessageBox:SetScript('OnMouseUp', MessageBox.StopMovingOrSizing)
    MessageBox:SetScript('OnHide', MessageBox.StopMovingOrSizing)
    MessageBox:SetFrameStrata('DIALOG')

    local FontString = MessageBox:CreateFontString(nil)
    FontString:ClearAllPoints()
    FontString:SetPoint('TOPLEFT', 15, -15)
    FontString:SetPoint('BOTTOMRIGHT', -15, 15)
    FontString:SetFont(LSM:Fetch('font', 'Arial Narrow'), 13, 'NONE')
    FontString:SetJustifyH('LEFT')
    FontString:SetJustifyV('TOP')

    local OkButton =  CreateFrame('Button', nil, MessageBox, 'UIPanelButtonTemplate')
    OkButton:SetScale(1.25)
    OkButton:SetSize(50, 20)
    OkButton:ClearAllPoints()
    OkButton:SetPoint('BOTTOMRIGHT', -10, 10)
    OkButton:SetScript('OnClick', function()
                                    PlaySound('igMainMenuOptionCheckBoxOn')
                                    MessageBox:Hide()
                                  end)
    OkButton:SetText('Okay')

    MessageBox.FontString = FontString
    MessageBox.OkButton = OkButton
  end

  MessageBox:Show()
  MessageBox.FontString:SetText(Message)
end

-------------------------------------------------------------------------------
-- ConvertUnitBarData
--
-- Converts unitbar data to a newer format.
--
-- ConvertUBData format
--
-- ConvertUBData
--   Action
--     remove         Remove a table that matches Key
--     copy           Copy a value from Source to Dest
--     move           Move a value from source to Dest
--     movetable      Move a sub table from Source to Dest.  Keys is the subtable.
--     custom         Calls ConvertCustom to make changes.
--
--   []               Array of Keys.
--     Key            If action is movetable then the key is the sub table to move.
--                    The key only needs to partially match the key found in unitbars[BarType]
--                    A key can have two different prefixes:
--                      ! Will take the value if boolean and flip it before copying or moving the value.
--                        If the value is a number it will flip its sign. So negative to positive.
--                      = Will make the key have to match exactly to what is found in unitbars.  If the
--                        match fails its skipped.
--                      =! to both, they must be in that order.
--                    A key can also contain a destkey part format is Key:DestKey.  DestKey is the new
--                    name to copy, rename or move to.
--
-- NOTES: copy, move, movetable.  These keys must not exist in the default profile.
--        custom.  These keys can exist in the default profile.
-------------------------------------------------------------------------------
local function ConvertCustom(BarType, SourceUB, DestUB, SourceKey, DestKey)
  if BarType == 'RuneBar' then

    -- Convert RuneBarOrder to BoxOrder, then delete RuneBarOrder
    if SourceKey == 'RuneBarOrder' then
      local BoxOrder = DestUB.BoxOrder

      for k, v in pairs(SourceUB.RuneBarOrder) do
        BoxOrder[k] = v
      end
      SourceUB.RuneBarOrder = nil

    -- Convert RuneLocation to BoxLocations, then delete RuneLocation
    elseif SourceKey == 'RuneLocation' then
      local BoxLocations = {}

      for k, v in pairs(SourceUB.RuneLocation) do
        local BL = {}
        local x, y = v.x, v.y

        x = x == '' and 0 or x
        y = y == '' and 0 or y
        BL.x, BL.y = x, y
        BoxLocations[k] = BL
      end
      DestUB.BoxLocations = BoxLocations
      SourceUB.RuneLocation = nil

    -- Convert RuneSize into TextureScale, then remove RuneSize
    elseif SourceKey == 'RuneSize' then
      local TextureScale = SourceUB.RuneSize / 22
      DestUB.TextureScale = TextureScale - TextureScale % 0.01
      SourceUB.RuneSize = nil

    -- Convert rune mode and energize show
    elseif SourceKey == 'RuneMode' or SourceKey == 'EnergizeShow' then
      local Mode = SourceUB[SourceKey]

      if Mode == 'cooldownbar' then
        Mode = 'bar'
      elseif Mode == 'runecooldownbar' then
        Mode = 'runebar'
      end
      SourceUB[SourceKey] = Mode
    end
  end
  if BarType == 'EclipseBar' then
    if SourceUB.IndicatorHideShow == 'none' then
      SourceUB.IndicatorHideShow = 'auto'
    end
  end
  if SourceKey == 'Text' then
    local Text = SourceUB.Text
    for Index = 1, #Text do
      local TS = Text[Index]
      local ValueName = TS.ValueName
      local ValueType = TS.ValueType

      for ValueIndex = 1, #ValueName do
        local VName = ValueName[ValueIndex]
        local VType = ValueType[ValueIndex]

        if VName == 'unitname' or VName == 'realmname' or VName == 'unitnamerealm' then
          ValueName[ValueIndex] = 'name'
          ValueType[ValueIndex] = VName
        elseif VType == 'plain' then
          ValueType[ValueIndex] = 'whole'
        end
      end
    end
  end
end

local function ConvertUnitBarData()
  local KeysFound = {}
  local ConvertUBData = {
    {Action = 'custom',                                                 'RuneBarOrder', 'RuneLocation'},
    {Action = 'custom',    Source = 'General', Dest = 'Layout',         'RuneSize', 'IndicatorHideShow', 'RuneMode', 'EnergizeShow'},

    {Action = 'remove',    Source = 'General',                          'Scale', 'SunOffsetX', 'MoonOffsetX', 'SunOffsetY', 'MoonOffsetY'},
    {Action = 'move',      Source = 'General', Dest = 'General',        'CooldownBarDrawEdge:BarSpark'},
    {Action = 'copy',      Source = 'General', Dest = 'Layout',         'BoxMode:HideRegion'},
    {Action = 'move',      Source = 'General', Dest = 'Layout',         'BoxMode', 'Size:TextureScale', 'Padding', '=!BarMode:Float',
                                                                        'RuneSwap:Swap', 'Angle:Rotation', 'FadeInTime', 'FadeOutTime'},

    {Action = 'move',      Source = 'General', Dest = 'General',        '=BarHalfLit:PowerHalfLit', '=PredictedBarHalfLit:PredictedPowerHalfLit'},

    {Action = 'move',      Source = 'Bar',     Dest = 'Layout',         'ReverseFill'},

    {Action = 'move',      Source = 'Bar',     Dest = 'Bar',            '=ComboWidth:Width', '=ComboHeight:Height',
                                                                        '=RuneWidth:Width', '=RuneHeight:Height',
                                                                        '=HapWidth:Width', '=HapHeight:Height'},
    {Action = 'move',      Source = 'Bar',     Dest = 'Bar',            '=BoxWidth:Width', '=BoxHeight:Height'},
    {Action = 'move',      Source = 'Bar',     Dest = 'Bar.Color',      'ClassColor:Class'},

    {Action = 'move',      Source = 'Bar.Moon',      Dest = 'BarMoon',      '=MoonWidth:Width',      '=MoonHeight:Height'},
    {Action = 'move',      Source = 'Bar.Sun',       Dest = 'BarSun',       '=SunWidth:Width',       '=SunHeight:Height'},
    {Action = 'move',      Source = 'Bar.Bar',       Dest = 'BarPower',     '=BarWidth:Width',       '=BarHeight:Height'},
    {Action = 'move',      Source = 'Bar.Slider',    Dest = 'BarSlider',    '=SliderWidth:Width',    '=SliderHeight:Height'},
    {Action = 'move',      Source = 'Bar.Indicator', Dest = 'BarIndicator', '=IndicatorWidth:Width', '=IndicatorHeight:Height'},

    {Action = 'movetable', Source = 'Bar',                              '=Moon:BarMoon','=Sun:BarSun', '=Bar:BarPower',
                                                                        '=Slider:BarSlider', '=Indicator:BarIndicator'},
    {Action = 'movetable', Source = 'Background',                       '=Moon:BackgroundMoon', '=Sun:BackgroundSun', '=Bar:BackgroundPower',
                                                                        '=Slider:BackgroundSlider', '=Indicator:BackgroundIndicator' },
    {Action = 'custom',    Source = '', '=Text'},
  }

  local AlignmentToolEnabled = UnitBars.AlignmentToolEnabled
  if AlignmentToolEnabled ~= nil then
    UnitBars.AlignAndSwapEnabled = AlignmentToolEnabled
    UnitBars.AlignmentToolEnabled = nil
  end

  for BarType, UBF in pairs(UnitBarsF) do
    local UB = UBF.UnitBar

    -- Get source, dest and keylist
    for _, ConvertData in ipairs(ConvertUBData) do
      local SourceTable = ConvertData.Source or ''
      local SourceUB = Main:GetUB(BarType, SourceTable)
      local SourceUBD = Main:GetUB(BarType, SourceTable, DUB)

      -- Skip Unitbar if Source is not found
      if SourceUB then
        local Action = ConvertData.Action
        local DestTable = ConvertData.Dest or ''
        local DestUB = Main:GetUB(BarType, DestTable)

        -- Iterate thru the key list
        for _, Key in ipairs(ConvertData) do
          local NumKeys = 0
          local NotFlag = false
          local Exact = false

          -- check for exact match operator in key.
          if strfind(Key, '=') then
            Exact = true
            Key = strsub(Key, 2)
          end

          -- check for the not operator in Key.
          if strfind(Key, '!') then
            NotFlag = true
            Key = strsub(Key, 2)
          end

          local SourceKey, DestKey = strsplit(':', Key, 2)

          DestKey = DestKey or SourceKey

          -- Find the keys and store the results in KeysFound.
          for UBKey, Value in pairs(SourceUB) do
            if Exact and UBKey == SourceKey or not Exact and strfind(UBKey, SourceKey) then
              if Action ~= 'custom' and SourceUBD and SourceUBD[UBKey] ~= nil then
              else
                -- Check to see if the DestKey already exists in the dest table.
                if Action ~= 'custom' and Action ~= 'remove' and (DestUB == nil or DestUB and DestUB[DestKey] == nil) then
                else
                  NumKeys = NumKeys + 1
                  KeysFound[NumKeys] = UBKey
                end
              end
            end
          end
          for Index = 1, NumKeys do
            local KeyFound = KeysFound[Index]

            if Action == 'custom' then
              local ReturnOK, Msg = pcall(ConvertCustom, BarType, SourceUB, DestUB, SourceKey, DestKey)

              if not ReturnOK then
                print('ERROR (custom): Report message to author')
                print('MSG: ', Msg)
              end

            elseif Action == 'movetable' then
              Main:CopyTableValues(SourceUB[KeyFound], DestUB[DestKey])
              SourceUB[KeyFound] = nil

            elseif Action == 'move' or Action == 'copy' then
              local Value = SourceUB[KeyFound]

              if NotFlag then
                if type(Value) == 'boolean' then
                  Value = not Value
                elseif type(Value) == 'number' then
                  Value = Value * -1
                end
              end
              DestUB[DestKey] = Value
              if Action == 'move' then
                SourceUB[KeyFound] = nil
              end

            elseif Action ==  'remove' then
              SourceUB[KeyFound] = nil
            end

            -- delete empty table
            if next(SourceUB) == nil then
              Main:ListTable(SourceUB)
              Main:DelUB(BarType, SourceTable)
            end
          end
        end
      end
    end
  end
  UnitBars.Version = 3
end

-------------------------------------------------------------------------------
-- CheckTalent
--
-- Checks to see if the talent is chosen or not.
--
-- Unit   player, target, pet, focus, etc
-- Index  Talent index from 1 to 18.  Talents are index from left to right then down one.
--
-- Returns:
--   Status   If true then the talent is chosen, otherwise false.
-------------------------------------------------------------------------------
function GUB.Main:CheckTalent(Index)
  local _, _, _, _, Active = GetTalentInfo(Index, nil, nil)
  return Active
end

-------------------------------------------------------------------------------
-- ShowTooltip
--
-- Shows a tooltip at the frame location.
--
-- Frame                 Frame where the tooltip will be positioned at.
-- UnitBarDesc           if true then shows the standard unitbar description.
-- Name                  Name of the tooltip, set to '' to skip.
-- ...                   Additional lines.  Can be a table of strings or
--                       comma delimited strings. Set to nil to skip.
--
-- NOTES:  To hide the tooltip pass no paramaters.
-------------------------------------------------------------------------------
function GUB.Main:ShowTooltip(Frame, UnitBarDesc, Name, ...)
  if Frame and not UnitBars.HideTooltips then
    local St = nil

    GameTooltip:SetOwner(Frame, 'ANCHOR_TOPRIGHT')

    if Name ~= '' then
      GameTooltip:AddLine(Name)
    end

    -- Add unitbar description if true
    if not UnitBars.HideTooltipsDesc then
      if UnitBarDesc then
        if UnitBars.AlignAndSwapEnabled then
          GameTooltip:AddLine(AlignAndSwapTooltipDesc, 1, 1, 1)
        end
        GameTooltip:AddLine(MouseOverDesc, 1, 1, 1)
      end
      if ... then
        if type(...) == 'table' then
          St = ...
        end
        for Index = 1, St and #St or select('#', ...) do
          local Desc = St and St[Index] or select(Index, ...)

          GameTooltip:AddLine(Desc, 1, 1, 1)
        end
      end
    end
    GameTooltip:Show()
  else
    GameTooltip:Hide()
  end
end

-------------------------------------------------------------------------------
-- GetHighestFrameLevel
--
-- Returns the frame with the highest frame level in all of the frames children.
--
-- Frame            Frame to start searching its children for the highest frame.
-------------------------------------------------------------------------------
local function GetHighestFrameLevel(Frame)
  local HighestFrameLevel = -1

  local function FindHighestFrameLevel(...)
    local Found = false

    for Index = 1, select('#', ...) do
      local Frame = select(Index, ...)
      Found = true

      if not FindHighestFrameLevel(Frame:GetChildren()) then

        -- No children found so use this frame.
        local FL = Frame:GetFrameLevel()

        if FL > HighestFrameLevel then
          HighestFrameLevel = FL
        end
      end
    end
    return Found
  end
  FindHighestFrameLevel(Frame)
  return HighestFrameLevel
end

-------------------------------------------------------------------------------
-- SetUnitBarSize
--
-- Subfunction of UnitBarsF:SetSize
--
-- Sets the width and height for a unitbar.
--
-- UnitBarF    UnitBar to set the size for.
-- Width       Set width of the unitbar. if Width is nil then current width is used.
-- Height      Set height of the unitbar.
-- OffsetX     Move the unitbar from the current position by OffsetX.
-- OffsetY     Move the unitbar from the current position by OffsetY
--
-- NOTE:  This accounts for scale.  Width and Height must be unscaled when passed.
-------------------------------------------------------------------------------
local function SetUnitBarSize(self, Width, Height, OffsetX, OffsetY)

  -- Get Unitbar data and anchor
  local UB = self.UnitBar
  local Anchor = self.Anchor
  local Scale = UB.Other.Scale

  if Width == nil then
    Width = self.BaseWidth or 1
    Height = self.BaseHeight or 1
  else
    self.BaseWidth = Width
    self.BaseHeight = Height
  end

  -- Need to scale width and height since size is based on ScaleFrame.
  Width = Width * Scale
  Height = Height * Scale
  self.Width = Width
  self.Height = Height
  Anchor:SetSize(Width, Height)

  -- Need to scale offset since all offsets are based off of ScaleFrame.
  local x, y = UB.x + (OffsetX or 0) * Scale, UB.y + (OffsetY or 0) * Scale
  Anchor:SetPoint('TOPLEFT', Anchor:GetParent(), 'TOPLEFT', x, y)
  UB.x, UB.y = x, y

  -- Update alignment if alignswap is open
  if Options.AlignSwapOpen then
    Main:SetUnitBarsAlignSwap()
  end
end

-------------------------------------------------------------------------------
-- SetTimer
--
-- Will call a function based on a delay.
--
-- To start a timer
--   usage: SetTimer(Table, Delay, TimerFn)
-- To stop a timer
--   usage: SetTimer(Table, nil)
--
-- Table    Must be a table.
-- Delay    Amount of time to delay after each call to Fn()
-- TimerFn  Function to be added. If nil then the timer will be stopped.
--
-- NOTE:  TimerFn will be called as TimerFn(Frame, Elapsed) from AnimationGroup in StartTimer()
--        See CheckSpellTrackerTimeout() on how this is used.
--
--        To reduce garbage.  Only a new StartTimer() will get created when a new table is passed.
--
--        I decided to do it this way because the overhead of using indexed
--        arrays for multiple timers ended up using more cpu.
--
--        The function that gets called has the following passed to it:
--          Table      Table that was created with the timer.
--          Duration   This is the same value as Delay passed to starting the timer.
---------------------------------------------------------------------------------
function GUB.Main:SetTimer(Table, Delay, TimerFn)
  local AnimationGroup = nil
  local Animation = nil

  Table.SetTimer = Table.SetTimer or function(Start, Delay, TimerFn2)

    -- Create an animation Group timer if one doesn't exist.
    if AnimationGroup == nil then
      AnimationGroup = CreateFrame('Frame'):CreateAnimationGroup()
      Animation = AnimationGroup:CreateAnimation('Animation')
      Animation:SetOrder(1)
      AnimationGroup:SetLooping('REPEAT')

      local GetDuration = AnimationGroup.GetDuration
      AnimationGroup:SetScript('OnLoop' , function(self) TimerFn(Table, GetDuration(self)) end )
    end
    if Start then
      TimerFn = TimerFn2
      Animation:SetDuration(Delay)
      if Delay > 0 then
        AnimationGroup:Play()
      else
        -- Call Timer function if 0 is passed
        TimerFn(Table, 0)
      end
    else
      AnimationGroup:Stop()
    end
  end

  if TimerFn then

    -- Start timer since a function was passed
    Table.SetTimer(true, Delay, TimerFn)
  else

    -- Stop timer since no function was passed.
    Table.SetTimer(false)
  end
end

------------------------------------------------------------------------------
-- CheckSetBonus
--
-- Checks to see if a set bonus is active, if any have been set
-------------------------------------------------------------------------------
local function CheckSetBonus()
  local Tier = 0
  local SetBonus = 0
  local NewSetBonus = 0
  local ESItemID = nil

  -- Reset set bonus counter
  for Tier, _ in pairs(EquipmentSetBonus) do
    EquipmentSetBonus[Tier] = 0
  end

  -- Count each tier piece.
  for Slot, ES in pairs(EquipmentSet) do
    Tier = ES[GetInventoryItemID('player', strsub(Slot, 2))]
    if Tier then
      SetBonus = EquipmentSetBonus[Tier]
      if SetBonus then
        SetBonus = SetBonus + 1
      else
        SetBonus = 1
      end
      EquipmentSetBonus[Tier] = SetBonus
    end
  end

  -- Clip Set bonus.
  for Tier, SetBonus in pairs(EquipmentSetBonus) do
    if SetBonus >= 4 then
      NewSetBonus = 4
    elseif SetBonus >= 2 then
      NewSetBonus = 2
    else
      NewSetBonus = 0
    end
    EquipmentSetBonus[Tier] = NewSetBonus
  end
end

-------------------------------------------------------------------------------
-- GetSetBonus
--
-- Returns set bonus info.
--
-- Tier        Tier number of gear 11, 12 etc.
--
-- Returns:
--   SetBonus   Set bonus 2 or 4, 0 if no bonus is detected.
-------------------------------------------------------------------------------
function GUB.Main:GetSetBonus(Tier)

  -- Register event and do an equipmentset check if event hasn't been registered.
  if not EquipmentSetRegisterEvent then
    CheckSetBonus()
    RegisterEvents('register', 'setbonus')
    EquipmentSetRegisterEvent = true
  end

  local SetBonus = EquipmentSetBonus[Tier]
  if SetBonus then
    return SetBonus
  else
    return 0
  end
end

-------------------------------------------------------------------------------
-- CheckAura
--
-- Checks to see if one or more auras are active
--
-- Condition    - 'a' and.
--                   All auras must be found.
--                'o' or.
--                   Only one of the auras need to be found.
-- ...          - One or more spell IDs to search.
--
-- Returns:
--   Found        - If 'a' is used.
--                  Returns true if the aura was found. Or false.
--                  If 'o' is used.
--                  Returns the SpellID of the aura found or nil if no aura was found.
--   TimeLeft     - Time left on aura.  -1 if aura doesn't have a time left.
--                  This only gets returned when using the 'o' option.
--   Stacks       - Number of stacks of the buff gets returned when using the 'o' option.
-------------------------------------------------------------------------------
function GUB.Main:CheckAura(Condition, ...)
  local Name = nil
  local SpellID = 0
  local MaxSpellID = select('#', ...)
  local Found = 0
  local AuraIndex = 1

  repeat
    local Name, _, _, Stacks, _, _, ExpiresIn, _, _, _, SpellID = UnitBuff('player', AuraIndex)
    if Name then

      -- Search for the aura against the list of auras passed.
      for i = 1, MaxSpellID do
        if SpellID == select(i, ...) then
          Found = Found + 1
          break
        end
      end

      -- When using the 'o' option then return on the first found aura.
      if Condition == 'o' and Found > 0 then
        if ExpiresIn == 0 then
          return SpellID, -1, Stacks
        else
          return SpellID, ExpiresIn - GetTime(), Stacks
        end
      end
    end
    AuraIndex = AuraIndex + 1
  until Name == nil or Found == MaxSpellID
  if Condition == 'a' then
    return Found == MaxSpellID
  end
end

-------------------------------------------------------------------------------
-- CheckSpellTrackerTimeout
--
-- Timer that watches to timeout the current casting spell.
-------------------------------------------------------------------------------
local function CheckSpellTrackerTimeout(self, Elapsed)

  -- Check for spell tracker time out.
  if SpellTrackerTime > 0 then
    SpellTrackerTime = SpellTrackerTime - Elapsed
  else
    local SpellID = SpellTrackerCasting.SpellID
    local CastTime = SpellTrackerCasting.CastTime
    local Fn = SpellTrackerCasting.Fn
    local UnitBarF = SpellTrackerCasting.UnitBarF

    self.ModifySpellTracker('remove')

    if Fn then
      Fn(UnitBarF, SpellID, CastTime, 'timeout')
    end
  end
end

-------------------------------------------------------------------------------
-- ModifySpellTracker
--
-- Adds or Remove a spell from the spell tracker.
--
-- Action     'remove' or 'add'
--            'add'    will add the current spell to casting.
--            'remove' will remove the current casting spell.
-- UnitBarF   Bar that is using the SpellID.
-- SpellID    The spell to add.
-- LineID     LineID to add.
-- CastTime   Amount of time it takes to cast the spell.
-- Fn         Function to call when timeout happens.
-------------------------------------------------------------------------------
local function ModifySpellTracker(Action, UnitBarF, SpellID, LineID, CastTime, Fn)

  -- Stop the timeout checker.
  Main:SetTimer(SpellTrackerTimer, nil)

  if Action == 'add' then
    SpellTrackerCasting.SpellID = SpellID
    SpellTrackerCasting.LineID = LineID
    SpellTrackerCasting.CastTime = CastTime
    SpellTrackerCasting.Fn = Fn
    SpellTrackerCasting.UnitBarF = UnitBarF

    -- Set timeout
    SpellTrackerTime = SpellTrackerTimeout - 1 -- Takes one second for timer to start ticking.

    -- Start the timeout checker.
    Main:SetTimer(SpellTrackerTimer, 1, CheckSpellTrackerTimeout) -- Call timer once per second.

  elseif Action == 'remove' then
    SpellTrackerCasting.SpellID = 0
    SpellTrackerCasting.LineID = -1
    SpellTrackerCasting.CastTime = 0
    SpellTrackerCasting.Fn = nil
    SpellTrackerCasting.UnitBarF = nil
  end
end

-------------------------------------------------------------------------------
-- SetSpellTrackerActive
--
-- Turns spell tracking on or off.
--
-- UnitBarF  If this matches with what was set in SetSpellTracker() then
--           Action won't be ignored.
-- Action    True or False.  If true then the spell tracker is turned on.
--                           if false then the spell tracker is only turned off when there are no
--                           other bars using it.
--           'register'
--           'unregister'    registers and unregisters the events for spell tracking.  But doesn't
--                           set the active state.  Used internally by HideUnitBar()
--
-- NOTES:  If the bar is hidden and the Action is true, then spell tracking wont be enabled
--         until the bar is visible again.
-------------------------------------------------------------------------------
local function SetSpellTrackerActive(UnitBarF, Action)

  -- Check to see if the unitbar was already defined in SetSpellTracker()
  if SpellTrackerActive[UnitBarF] ~= nil then
    if type(Action) == 'boolean' then
      SpellTrackerActive[UnitBarF] = Action
    else
      Action = Action == 'register'
    end

    -- Only register events if the bar is not hidden.
    if Action and not UnitBarF.Hidden then
      RegisterEvents('register' , 'spelltracker')

    elseif not Action then

      -- Check to see if any other bars are using the spell tracker
      -- that are not hidden
      local Found = false
      for UBF, Active in pairs(SpellTrackerActive) do
        if UnitBarF ~= UBF and Active and not UBF.Hidden then
          Found = true
          break
        end
      end
      if not Found then
        RegisterEvents('unregister' , 'spelltracker')

        -- Remove any spell being tracked.
        ModifySpellTracker('remove')
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetSpellTracker
--
-- Adds a spellID to the list for spell tracking.
-- Can also turn off or on the spell tracker or reset it.
--
-- Usage: SetSpellTracker(UnitBarF, SpellID, EndOn, Fn)
--        SetSpellTracker(UnitBarF, true or false)
--        SetSpellTracker('reset')
--
-- UnitBarF      The type of bar the SpellID will be used with.
-- SpellID       ID of the spell to track.
-- EndOn         Tells how the spell will end.
--               'casting' means the spell will be cleared when the spell was stopped, cancled, succeeded, etc.
--               'energize' means the spell will end on an energize event.
-- Fn            See TrackSpell() and Eclipse.lua on how Fn() is used.
--
-- true          Turn on predicted power.
-- false         Turn off predicted power.
--
-- 'reset'       Sets all the bars active status to false and unregisters tracker events.
--
-- NOTE:   When using endon 'energize' you must add the energize spellID as well. Otherwise
--         the spell tracker will not see the energize event.  See EclipseBar.lua how this is set up.
-------------------------------------------------------------------------------
function GUB.Main:SetSpellTracker(UnitBarF, SpellID, EndOn, Fn)
  if UnitBarF == 'reset' then
    for UBF, v in pairs(SpellTrackerActive) do
      SpellTrackerActive[UBF] = false
    end

  -- Add spell to be tracked.
  elseif type(SpellID) ~= 'boolean' then
    local PS = {EndOn = EndOn, Fn = Fn, UnitBarF = UnitBarF}
    TrackedSpell[SpellID] = PS
    SpellTrackerActive[UnitBarF] = false
  else

    -- Set the active status, also create timer if doesn't exist.
    if SpellTrackerTimer == nil then
      SpellTrackerTimer = CreateFrame('Frame')
      SpellTrackerTimer.ModifySpellTracker = ModifySpellTracker
    end
    SetSpellTrackerActive(UnitBarF, SpellID)  -- SpellID is true or false when used here.
  end
end

-------------------------------------------------------------------------------
-- ListTable()
--
-- Like table.foreach except shows the details of all sub tables.
-------------------------------------------------------------------------------
function GUB.Main:ListTable(Table, Path)
  if Path == nil then
    Path = '.'
  end

  for k, v in pairs(Table) do
    if type(v) == 'table' then
      print(Path .. '.' .. k .. ' = ', v)

      Main:ListTable(v, Path .. '.' .. k)
    else
      print(Path .. '.' .. k .. ' = ', v)
    end
  end
end

-------------------------------------------------------------------------------
-- Check
--
-- Checks if the tablepath leads to data in a table.
-- If the check fails false is returned otherise true.
--
-- BarType              Table data for that bar.
-- Table                Table to seach in.  Must have same format as a UnitBar table.
-- TablePath            A string leading to the data you want to find.
-------------------------------------------------------------------------------
local function Check(BarType, Table, TablePath)
  local Value = Table[BarType]
  if Value == nil then
    return false
  end
  local Key = nil

  while true do
    if TablePath then
      Key, TablePath = strsplit('.', TablePath, 2)

      -- Get value by array index or hash index.
      Value = Value[tonumber(Key) or Key]
      if Value == nil then
        return false
      elseif type(Value) ~= 'table' and TablePath ~= nil then
        return false
      end
    else
      break
    end
  end
  return true
end

-------------------------------------------------------------------------------
-- GetUB
--
-- Gets a value or a table from a table based on BarType
--
-- BarType      Table of bartype
-- TablePath    String delimited by a '.'  Example 'table.1' = table[1] or 'table.subtable' = table['subtable']
-- Table        If not nil then this table will be searched instead.  Must have a unitbar table format.
--
-- Returns:
--   Value        Table or value returned
--   DC           If true then a _DC tag was found. _DC tag is only searched in default unitbars.
--
-- Notes:  If nil is found at anytime then a nil is returned.
--         If TablePath is '' or nil then UnitBars[BarType] is returned.
-------------------------------------------------------------------------------
function GUB.Main:GetUB(BarType, TablePath, Table)
  local Value = Table and Table[BarType] or UnitBars[BarType]
  local DUBValue = DUB[BarType]
  local DC = false
  local Key = nil

  if TablePath == '' then
    TablePath = nil
  end

  while true do
    if type(DUBValue) == 'table' and DUBValue._DC then
      DC = true
    end

    if TablePath then
      Key, TablePath = strsplit('.', TablePath, 2)

      -- Get value by array index or hash index.
      local Key = tonumber(Key) or Key
      Value = Value[Key]
      if DUBValue then
        DUBValue = DUBValue[Key]
      end

      if type(Value) ~= 'table' then
        break
      end
    else
      break
    end
  end

  return Value, DC
end

-------------------------------------------------------------------------------
-- DelUB
--
-- Deletes a key in a unitbar by tablepath.
--
-- BarType    UnitBar to delete a key from.
-- TablePath  Path leading to the key to delete.
-------------------------------------------------------------------------------
function GUB.Main:DelUB(BarType, TablePath)
  local Value = UnitBars[BarType]
  local Key = nil

  while true do
    if TablePath then
      Key, TablePath = strsplit('.', TablePath, 2)
      Key = tonumber(Key) or Key

      if TablePath == nil then
        Value[Key] = nil
        return
      else

        -- Get value by array index or hash index.
        Value = Value[Key]
        if type(Value) ~= 'table' then
          break
        end
      end
    else
      break
    end
  end
end

-------------------------------------------------------------------------------
-- CopyTableValues
--
-- Copies all the data from one table to another.
--
-- Source        Table to copy from.
-- Dest          Table to copy to.
-- DC            If true deep copies to the destination, but keeps the original.
--               table pointer intact.
--
-- NOTES: Types need to match, so the source found has to have the same type
--        in the destination.
--        Any source keys that start with an '_' will not get copied.  Even if DC is true.
-------------------------------------------------------------------------------
local function CopyTable(Source, Dest, DC)
  for k, v in pairs(Source) do
    local d = Dest[k]
    local ts = type(v)

    if (DC or ts == type(d)) and strsub(k, 1, 1) ~= '_' then
      if ts == 'table' then
        if d == nil then
          d = {}
          Dest[k] = d
        end
        CopyTable(v, d, DC)
      else
        Dest[k] = v
      end
    end
  end
end

function GUB.Main:CopyTableValues(Source, Dest, DC)
  if DC then

    -- Empty table for deep copy
    wipe(Dest)
  end
  CopyTable(Source, Dest, DC)
end

-------------------------------------------------------------------------------
-- CopyMissingTableValues
--
-- Copies the values that exist in the source but not in the destination.
-- Array indexes are skipped.
--
-- Source    The source table you're copying data from.
-- Dest      The destination table the data is being copied to.
-------------------------------------------------------------------------------
function GUB.Main:CopyMissingTableValues(Source, Dest)
  for k, v in pairs(Source) do
    local d = Dest[k]
    local ts = type(v)

    -- Key not found in destination so copy from source.
    if d == nil then

      -- if table then copy entire table and all subtables over.
      if ts == 'table' then
        d = {}
        CopyTable(v, d, true)
        Dest[k] = d

      -- skip the copy if its an array index.
      elseif type(k) ~= 'number' then
        Dest[k] = v
      end
    elseif ts == 'table' then

      -- keep searching for missing values in the sub table.
      Main:CopyMissingTableValues(v, d)
    end
  end
end

-------------------------------------------------------------------------------
-- CopyUnitBar
--
-- Copies all the data from one unitbar to another based on the TablePath
--
-- Source            BarType or Table
-- Dest              BarType or Table
-- SourceTablePath   Path leading to the table or value to copy for source
-- DestTablePath     Path leading to the table or value to copy for destination
--
-- NOTE:  If the _DC tag is found anywhere along the tablepath then a deep
--        copy will be done instead.
--        If path is not found in either source or dest no copy is done.
-------------------------------------------------------------------------------
function GUB.Main:CopyUnitBar(Source, Dest, SourceTablePath, DestTablePath)
  local Source, SourceDC = Main:GetUB(Source, SourceTablePath)
  local Dest, DestDC = Main:GetUB(Dest, DestTablePath)

  if Source and Dest then
    Main:CopyTableValues(Source, Dest, SourceDC and DestDC)
  end
end

-------------------------------------------------------------------------------
-- FinishAnimation
--
-- Finishes a fading animation or skips to the end of one.
--
-- Subfunction of SetAnimation()
--
-- Usage: FinishAnimation(self, NewAction)
--
-- self       Animation group to finish (Fade)
-- NewAction  If specified will use this instead of self.Action
--            Must be 'in' or 'out' or nil.
-------------------------------------------------------------------------------
local function FinishAnimation(self, NewAction)
  local Object = self.Object
  local Action = NewAction or self.Action

  self:SetScript('OnFinished', nil)
  self:Stop()

  -- Hide or show the object based on action.
  if Action == 'in' then
    Object:Show()
    Object:SetAlpha(1)
  else
    Object:Hide()
    Object:SetAlpha(1)
  end
  self.Action = false
end

-------------------------------------------------------------------------------
-- PlayAnimation
--
-- Plays a fading animation.
--
-- Subfunction of SetAnimation()
--
-- Usage: PlayAnimation(Fade, Action, ReverseFade)
--
-- Fade          Animation group to play.
-- Action        Must be 'in' or 'out'
-- ReverseFade   If true then the Fade passed must be currently fading.
--               The fading will get reversed.
-------------------------------------------------------------------------------
local function PlayAnimation(Fade, Action, ReverseFade)
  local Object = Fade.Object
  local FadeA = Fade.FadeA
  local Duration = 0
  local Change = 0

  -- Set up for reverse fading.
  if ReverseFade then
    Action = Fade.Action == 'in' and 'out' or 'in'
  else

    -- else set up for a new fade.
    Object:Show()
    if Action == 'in' then
      Object:SetAlpha(0)
    end
  end

  -- Get change and duration.
  if Action == 'in' then
    Change = 1
    Duration = Fade.DurationIn
  else
    Change = -1
    Duration = Fade.DurationOut
  end

  -- Check for zero duration or invisible frame.
  if Duration == 0 or Fade.Object:IsVisible() == nil then
    FinishAnimation(Fade, Action)
  else

    -- Set up for reverse fade.  This will reverse the current fade.
    if ReverseFade then
      local Alpha = Fade.Object:GetAlpha()

      Fade:Stop()
      Fade.Object:SetAlpha(Alpha)

      if Action == 'in' then
        Alpha = 1 - Alpha
      end
      Duration = Alpha * Duration
    else

      -- Starting a new fade, set the script.
      Fade:SetScript('OnFinished', FinishAnimation)
    end

    -- Set and play the fade.
    FadeA:SetChange(Change)
    FadeA:SetDuration(Duration)
    Fade:Play()
    Fade.Action = Action
  end
end

-------------------------------------------------------------------------------
-- SetAnimation  (fade method)
--
-- Stop or starts fading.
--
-- Usage:  Fade:SetAnimation(Action)
--
-- self        Animation group (Fade)
-- Action      'in'       Starts fading animation in. Stops any old animation first or reverses.
--             'out'      Starts fading animation out. Stops any old animation first or reverses.
--             'stop'     Stops fading animation and calls Fn
--             'stopall'  Stops all animation.
--
-- NOTE:  The perpose of this function is to never let a child frame fade in or out
--        while the parent is fading.  If this were to happen the alpha state of
--        a frame can get stuck and only a /console reloadui can fix it.
--        Blizzard please fix this, thanks.
--
--        A parent fade will only play but will stop all child animations first.
--        The current child fade animation will skip to the end instead of playing.
--        Child fades will not play if the parent is fading.  Instead they'll skip to the
--        end of their animation right away.
--
--        Fading can be reversed by doing SetAnimation() in the opposite direction
--        on a fade already playing.
-------------------------------------------------------------------------------
local function SetAnimation(self, Action)
  local ReverseFade = false
  local FadeAction = self.Action

  -- Stop or play the fade.
  if Action == 'stop' then
    if FadeAction then
      FinishAnimation(self)
    end
    return
  end
  if Action == 'in' or Action == 'out' then
    if FadeAction then
      if FadeAction ~= Action then

        -- Fade already playing, reverse fade if unitbar options is set.
        if UnitBars.ReverseFading then
          ReverseFade = true
        else
          FinishAnimation(self)
        end
      else

        -- Return since the same type of fade is already playing.
        return
      end
    end
  end

  -- Search for parent or children fading.
  local StopAll = Action == 'stopall'
  local NotParent = not self.Parent
  local FA = FadingAnimation[self.UnitBarF]

  for Index = 1, FA.Total do
    local Fade = FA[Index]
    if Fade.Action then

      -- Stop all animation if stopall is set.
      if StopAll then
        FinishAnimation(Fade)

      elseif Fade.Parent == NotParent then

        -- If parent is fading then stop all children animations.
        if self.Parent then
          FinishAnimation(Fade)
        else

          -- End current animation since the parent is fading, and return.
          -- Since Fade is not playing we need to specify an action.
          FinishAnimation(self, Action)
          return
        end
      end
    end
  end

  -- Return if stopall.
  if StopAll then
    return
  end

  -- Play the fading animation. in or out.
  PlayAnimation(self, Action, ReverseFade)
end

-------------------------------------------------------------------------------
-- SetDuration   (Fade method)
--
-- Sets the time in seconds that it will take for fading.
--
-- Usage: Fade:SetDuration(Action, Seconds)
--
-- self       Animation group (fade)
-- Seconds    Time in seconds.
-- Action     'in' for for fading in duration.
--            'out' for fading out duration.
--
-- NOTE:  The change doesn't change the current fading animation only new ones.
-------------------------------------------------------------------------------
local function SetDuration(self, Action, Seconds)

  -- Set the duration for in/out.
  if Action == 'in' then
    self.DurationIn = Seconds
  else
    self.DurationOut = Seconds
  end
end

-------------------------------------------------------------------------------
-- CreateFade
--
-- Create a fadein or fadeout animation.
--
-- Usage:  Fade = CreateFade(UnitBarF, Object, Parent)
--
-- UnitBarF   One or more fade animations being created under this bar.
-- Object     Must be a frame or texture.
-- Parent     If true then the fading animation is considered to belong to
--            the parent frame. Otherwise leave this nil.
--
-- Fade       Animation containing all the info needed to fade in or out.
--            See notes at top of the file for breakdown of this table.
--
-- List of methods used with fade
--
-- Fade:SetDuration('in' or 'out', Seconds)
-- Fade:SetAnimation('in' or 'out' or 'stop' or 'stopall')
--
-- See notes above on how each one is used.
-------------------------------------------------------------------------------
function GUB.Main:CreateFade(UnitBarF, Object, Parent)

  -- Create an animation for fading.
  local Fade = Object:CreateAnimationGroup()
  local FadeA = Fade:CreateAnimation('Alpha')

  -- Set the animation group values.
  Fade:SetLooping('NONE')
  FadeA:SetOrder(1)
  FadeA:SetDuration(0)

  Fade.FadeA = FadeA
  Fade.UnitBarF = UnitBarF
  Fade.Object = Object
  Fade.Action = false
  Fade.Parent = Parent or false
  Fade.DurationIn = 0
  Fade.DurationOut = 0

  -- Create a new entry for the UnitBar if one doesn't exist.
  local FA = FadingAnimation[UnitBarF]
  if FA == nil then
    FA = {Total = 0}
    FadingAnimation[UnitBarF] = FA
  end

  -- Store the fade animation
  local Total = FA.Total + 1
  FA[Total] = Fade
  FA.Total = Total

  -- Set methods.
  Fade.SetAnimation = SetAnimation
  Fade.SetDuration = SetDuration

  return Fade
end

-------------------------------------------------------------------------------
-- HideUnitBar
--
-- Usage: HideUnitBar(UnitBarF, HideBar)
--
-- UnitBarF       Unitbar frame to hide or show.
-- HideBar        Hide the bar if equal to true otherwise show.
-------------------------------------------------------------------------------
local function HideUnitBar(UnitBarF, HideBar)
  local Fade = UnitBarF.Fade
  local Anchor = UnitBarF.Anchor

  if HideBar ~= UnitBarF.Hidden then
    if HideBar then

      -- Disable TrackingSpells if active.
      if SpellTrackerActive[UnitBarF] then

        -- Disable spell tracking for this bar.
        SetSpellTrackerActive(UnitBarF, 'unregister')
      end

      -- Start the animation fadeout.
      Fade:SetAnimation('out')
      UnitBarF.Hidden = true
    else
      UnitBarF.Hidden = false

      -- Start the animation fadein.
      Fade:SetAnimation('in')

      -- Enable TrackingSpells if active.
      if SpellTrackerActive[UnitBarF] then
        SetSpellTrackerActive(UnitBarF, 'register')
      end
    end
  end
end

-------------------------------------------------------------------------------
-- StatusCheck    UnitBarsF function
--
-- Does a status check and updates the bar if it became visible.
--
-- Usage: StatusCheck()
-------------------------------------------------------------------------------
function GUB.Main:StatusCheck(Event)
  local UB = self.UnitBar
  local Status = UB.Status
  local Visible = true

  -- Check to see if the bar has a HideNotUsable flag.
  local HideNotUsable = Status.HideNotUsable or false
  if HideNotUsable then
    local Spec = UB.UsedByClass[PlayerClass]

    Visible = false

    -- Check if class found, then check spec.
    if Spec and (Spec == '' or PlayerSpecialization and strfind(Spec, PlayerSpecialization)) then
      Visible = true
    end
  end

  -- Show bars if not locked.
  if not UnitBars.IsLocked or UnitBars.Testing then

    -- use HideNotUsable visible flag if HideNotUsable is set.
    if not HideNotUsable then
      Visible = true
    end
  else

    -- Check to see if the bar has an enable function and call it.
    if Visible then
      local Fn = self.BarVisible
      if Fn then
        Visible = Fn()
      end
    end

    if Visible then

      -- Hide if the HideWhenDead status is set.
      if IsDead and Status.HideWhenDead then
        Visible = false

      -- Hide if in a vehicle if the HideInVehicle status is set
      elseif InVehicle and Status.HideInVehicle then
        Visible = false

      -- Hide if in a pet battle and the HideInPetBattle status is set.
      elseif InPetBattle and Status.HideInPetBattle then
        Visible = false

      -- Get the idle status based on HideNotActive when not in combat.
      -- If the flag is not present the it defaults to false.
      elseif not InCombat and Status.HideNotActive then
        local IsActive = self.IsActive
        Visible = IsActive == true

        -- if not visible then set IsActive to watch for activity.
        if not Visible then
          self.IsActive = 0
        end

      -- Hide if not in combat with the HideNoCombat status.
      elseif not InCombat and Status.HideNoCombat then
        Visible = false
      end
    end
  end

  -- Update the visible flag.
  self.Visible = Visible

  -- Hide/show the unitbar.
  HideUnitBar(self, not Visible)
end

--*****************************************************************************
--
-- Unitbar script functions (script/event)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- MoveFrameSetHighlightFrame
--
-- Sets a frame to be highlighted
--
-- Frame       Frame to highlight
-- Action      If true the box gets highlighted
-- r, g, b, a  Red, Green, Blue, and Alpha
-------------------------------------------------------------------------------
local function MoveFrameSetHighlightFrame(Action, SelectFrame, r, g, b, a)
  if MoveLastHighlightFrame then
    MoveLastHighlightFrame:Hide()
    MoveLastHighlightFrame = nil
  end
  if Action then
    local MoveHighlightFrame = SelectFrame.MoveHighlightFrame

    MoveHighlightFrame:Show()
    MoveHighlightFrame:SetBackdropBorderColor(r, g, b, a or 1)
    MoveLastHighlightFrame = MoveHighlightFrame
  end
end

-------------------------------------------------------------------------------
-- MoveFrameGetNearestFrame
--
-- Gets the closest frame to the one being moved.
--
-- Frames        List of boxframes or unitbar frames

-- NOTES: If the frame is inside of more than one frame.  Then the frame
--        that is closest is the selected frame.  Otherwise the 4 sides
--        of each frame is calculated to see which frame we're closest too.
--
--        F1: (SelectMFSize - MoveFrameSize) This is the amount of distance from
--        the center of the SelectFrame to the center of the moveframe if all
--        of the moveframe was just inside.
--
--        F2: Distance > MoveFrameSize * 2.  Distance is the amount of overlap
--        of SelectFrame and MoveFrame.  Once the overlap is greater than
--        the total width of MoveFrame.  Then the frame is inside.
--        At this point the SelectLineDistance will vary between F1 and zero.
-------------------------------------------------------------------------------
local function MoveFrameCalcDistance(Distance, SelectLineDistance, SelectMFSize, MoveFrameSize)
  SelectLineDistance = abs(SelectLineDistance)

  Distance = abs(SelectLineDistance - SelectMFSize - MoveFrameSize) -- Distance betwee the edges of both frames.
  if Distance >= MoveFrameSize then  -- at least half inside.
    if Distance > MoveFrameSize * 2 then   -- All of frame inside.
      Distance = 100 - (SelectLineDistance / (SelectMFSize - MoveFrameSize) * 100)
    else
      Distance = 0
    end
  elseif Distance ~= 0 then
    Distance = Distance * -1
  else
    Distance = -1
  end
  return Distance
end

local function MoveFrameGetNearestFrame(self)
  local Move = self.Move
  local Flags = Move.Flags
  local MoveFrame = Move.Frame
  local Swap = Flags.Swap
  local Float = Flags.Float
  local Align = Flags.Align

  if Float and (Align and not Swap or Swap and not Align) or not Float and Swap and not Align then
    local Type = self.Type
    local MoveFrames = Move.Frames

    local MoveFrameCenterX, MoveFrameCenterY = MoveFrame:GetCenter()
    local MoveFrameWidth = MoveFrame:GetWidth() * 0.5
    local MoveFrameHeight = MoveFrame:GetHeight() * 0.5
    local SmallestDistance = 65535
    local SmallestLineDistance = 65535

    local SelectMFCenterX = 0
    local SelectMFCenterY = 0
    local SelectMFWidth = 0
    local SelectMFHeight = 0
    local SelectLineDistanceX = 0
    local SelectLineDistanceY = 0
    local OldLineDistance = 0

    MoveSelectFrame = nil

    for MoveFrameIndex = 1, #MoveFrames do
      local MF = Type == 'box' and MoveFrames[MoveFrameIndex] or MoveFrames[MoveFrameIndex].Anchor

      -- needs to be visible and not the move frame.
      if MF:IsVisible() and MF ~= MoveFrame then
        local MFCenterX, MFCenterY = MF:GetCenter()
        local MFWidth = MF:GetWidth() * 0.5
        local MFHeight = MF:GetHeight() * 0.5
        local Width = MoveFrameWidth + MFWidth
        local Height = MoveFrameHeight + MFHeight

        local LineDistanceX = MoveFrameCenterX - MFCenterX
        local LineDistanceY = MoveFrameCenterY - MFCenterY

        local DistanceX = abs(LineDistanceX) - Width
        local DistanceY = abs(LineDistanceY) - Height

        DistanceX = DistanceX > 0 and DistanceX or 0
        DistanceY = DistanceY > 0 and DistanceY or 0

        -- Calculate the shortest distance between two frame in a straight line.
        local LineDistance = sqrt(LineDistanceX * LineDistanceX + LineDistanceY * LineDistanceY)

        -- Calculate distance between the moveframe and MF edges.
        local Distance = sqrt(DistanceX * DistanceX + DistanceY * DistanceY)

        if Swap or Align then
          if Align then

            -- Calculate the distance between the old select frame and the current select frame.
            if MoveOldSelectFrame then
              local OldLineDistanceX = abs(MoveOldMFCenterX - MFCenterX)
              local OldLineDistanceY = abs(MoveOldMFCenterY - MFCenterY)

              OldLineDistance = sqrt(OldLineDistanceX * OldLineDistanceX + OldLineDistanceY * OldLineDistanceY)
            end
            if Distance <= MoveAlignDistance then
              if MoveOldSelectFrame and SmallestLineDistance > OldLineDistance or MoveOldSelectFrame == nil then
                SmallestLineDistance = OldLineDistance
                MoveSelectFrame = MF
                SelectMFCenterX = MFCenterX
                SelectMFCenterY = MFCenterY
                SelectMFWidth = MFWidth
                SelectMFHeight = MFHeight
                SelectLineDistanceX = LineDistanceX
                SelectLineDistanceY = LineDistanceY
              end
            end
          elseif Distance == 0 then
            if LineDistance <= SmallestLineDistance then
              SmallestLineDistance = LineDistance
              MoveSelectFrame = MF

              SelectMFWidth = MFWidth
              SelectMFHeight = MFHeight
              SelectLineDistanceX = LineDistanceX
              SelectLineDistanceY = LineDistanceY
            end
          end
        end
      end
    end

    MoveOldSelectFrame = MoveSelectFrame
    if Align and MoveSelectFrame then
      MoveOldMFCenterX = SelectMFCenterX
      MoveOldMFCenterY = SelectMFCenterY

      local FlipX = 1
      local FlipY = 1
      local DistanceX = 0
      local DistanceY = 0
      local Point = nil
      local XMovePoint = ''
      local YMovePoint = ''
      local XSelectPoint = ''
      local YSelectPoint = ''
      local Flag = nil
      local XLessY = nil
      local PaddingDirectionX = 0
      local PaddingDirectionY = 0

      -- DistanceX and Y, if negative then outside the frame otherwise inside.
      if MoveFrameWidth <= SelectMFWidth then
        DistanceX = MoveFrameCalcDistance(DistanceX, SelectLineDistanceX, SelectMFWidth, MoveFrameWidth)
      else
        DistanceX = MoveFrameCalcDistance(DistanceX, SelectLineDistanceX, MoveFrameWidth, SelectMFWidth)
        FlipX = -1
      end

      if MoveFrameHeight <= SelectMFHeight then
        DistanceY = MoveFrameCalcDistance(DistanceY, SelectLineDistanceY, SelectMFHeight, MoveFrameHeight)
      else
        DistanceY = MoveFrameCalcDistance(DistanceY, SelectLineDistanceY, MoveFrameHeight, SelectMFHeight)
        FlipY = -1
      end
      XLessY = DistanceX < DistanceY
      if DistanceX > 50 or DistanceY > 50 then        -- Center inside or outside
        if XLessY then
          Flag         = SelectLineDistanceX > 0      -- > 0 right, left
          XMovePoint   = Flag and 'LEFT'  or 'RIGHT'
          XSelectPoint = Flag and 'RIGHT' or 'LEFT'
        else
          Flag         = SelectLineDistanceY > 0      -- > 0 top, bottom
          YMovePoint   = Flag and 'BOTTOM' or 'TOP'
          YSelectPoint = Flag and 'TOP' or 'BOTTOM'
        end
      else
        if XLessY then
          Flag         = SelectLineDistanceX > 0      -- > 0 right, left
          XMovePoint   = Flag and 'LEFT'  or 'RIGHT'
          XSelectPoint = Flag and 'RIGHT' or 'LEFT'

          if DistanceY >= 0 then                      -- >= 0 inside, outside
            Flag = SelectLineDistanceY * FlipY > 0    -- > 0 top, bottom
            YMovePoint = Flag and 'TOP' or 'BOTTOM'
            YSelectPoint = Flag and 'TOP' or 'BOTTOM'
          else
            Flag = SelectLineDistanceY > 0            -- > 0 top, bottom
            YMovePoint   = Flag and 'BOTTOM' or 'TOP'
            YSelectPoint = Flag and 'TOP' or 'BOTTOM'
          end
        else
          Flag         = SelectLineDistanceY > 0      -- > 0 top, bottom
          YMovePoint   = Flag and 'BOTTOM' or 'TOP'
          YSelectPoint = Flag and 'TOP' or 'BOTTOM'

          if DistanceX >= 0 then                      -- >= 0 inside, outside
            Flag = SelectLineDistanceX * FlipX > 0    -- > 0 right, left
            XMovePoint = Flag and 'RIGHT' or 'LEFT'
            XSelectPoint = Flag and 'RIGHT' or 'LEFT'
          else
            Flag = SelectLineDistanceX > 0            -- > 0 right, left
            XMovePoint = Flag and 'LEFT' or 'RIGHT'
            XSelectPoint = Flag and 'RIGHT' or 'LEFT'
          end
        end
      end

      MovePoint = YMovePoint .. XMovePoint
      MoveSelectPoint = YSelectPoint .. XSelectPoint
      if XSelectPoint ~= XMovePoint then
        if XSelectPoint == 'LEFT' then
          PaddingDirectionX = -1
        elseif XSelectPoint == 'RIGHT' then
          PaddingDirectionX = 1
        end
      end
      if YSelectPoint ~= YMovePoint then
        if YSelectPoint == 'TOP' then
          PaddingDirectionY = 1
        elseif YSelectPoint == 'BOTTOM' then
          PaddingDirectionY = -1
        end
      end
      Move.PaddingDirectionX = PaddingDirectionX
      Move.PaddingDirectionY = PaddingDirectionY
    end

    -- Highlight the MoveFrame.
    if MoveLastSelectFrame ~= MoveSelectFrame then
      MoveLastSelectFrame = MoveSelectFrame
      local TooltipDesc = ''

      if MoveSelectFrame then
        if Swap then
          MoveFrameSetHighlightFrame(true, MoveSelectFrame, 1, 0, 0) -- red
        else
          MoveFrameSetHighlightFrame(true, MoveSelectFrame, 0, 1, 0) -- green
        end
        TooltipDesc = format('Selected %s', MoveSelectFrame.Name or ' ')
      else
        MoveFrameSetHighlightFrame(false)
      end
      Main:ShowTooltip(MoveFrame, false, '', TooltipDesc)
    end
  end

  if MoveSelectFrame == nil and not UnitBars.HideLocationInfo and not UnitBars.HideTooltipsDesc then
    local x, y = Bar:GetRect(MoveFrame)

    Main:ShowTooltip(MoveFrame, false, '', format('%d, %d', floor(x + 0.5), floor(y + 0.5)))
  end
end

-------------------------------------------------------------------------------
-- MoveFrameStart
--
-- Starts moving a bar or box for swapping or alignment or just moving.
--
-- MoveFrames  List of frames that are being moved.
-- MoveFrame   Frame that is to be moved.
-- MoveFlags   Table containing the Swap, Float, Align, Type flags.
--
-- NOTES:  Swap and Align get ignored if both are true unless not in Float then
--         only Swap will work.
-------------------------------------------------------------------------------
function GUB.Main:MoveFrameStart(MoveFrames, MoveFrame, MoveFlags)
  local Move = MoveFrames.Move
  local Type = nil

  if Move == nil then
    Move = {}
    MoveFrames.Move = Move
  end
  local Flags = Move.Flags

  if Flags == nil then
    Flags = {}
    Move.Flags = Flags
  end

  Flags.Align = MoveFlags and MoveFlags.Align or false
  Flags.Swap = MoveFlags and MoveFlags.Swap or false
  Flags.Float = MoveFlags and MoveFlags.Float or false

  -- This is done to get rid of move lag.
  Move.FrameStrata = MoveFrame:GetFrameStrata()
  MoveFrame:SetFrameStrata('TOOLTIP')

  Move.Frame = MoveFrame
  Move.FrameOldX, Move.FrameOldY = Bar:GetRect(MoveFrame)
  Move.Frames = MoveFrames

  if MoveFrames[1].SetAttr then
    Type = 'bar'
    Flags.Float = true
  else
    Type = 'box'
  end
  TrackingFrame.Type = Type

  -- Create HighlightFrames if there are none.
  for Index = 1, #MoveFrames do
    local MF = Type == 'box' and MoveFrames[Index] or MoveFrames[Index].Anchor

    if MF.MoveHighlightFrame == nil then
      local MoveHighlightFrame = CreateFrame('Frame', nil, MF)

      MoveHighlightFrame:SetFrameLevel(GetHighestFrameLevel(MF) + 1)
      MoveHighlightFrame:SetPoint('TOPLEFT', -1, 1)
      MoveHighlightFrame:SetPoint('BOTTOMRIGHT', 1, -1)
      MoveHighlightFrame:SetBackdrop(SelectFrameBorder)
      MoveHighlightFrame:Hide()
      MF.MoveHighlightFrame = MoveHighlightFrame
    end
  end

  -- Show a box around the current bar being dragged
  if Type == 'bar' and UnitBars.HighlightDraggedBar then
    MoveFrame.MoveHighlightFrame:Show()
    MoveFrame.MoveHighlightFrame:SetBackdropBorderColor(0, 1, 0, 1) -- green
  end

  TrackingFrame.Move = Move
  MoveSelectFrame = nil
  MoveOldSelectFrame = nil
  MoveLastSelectFrame = nil

  TrackingFrame:SetParent(MoveFrame)
  TrackingFrame:ClearAllPoints()
  TrackingFrame:SetPoint('TOPRIGHT', MoveFrame, 'TOPLEFT')
  TrackingFrame:SetPoint('BOTTOMLEFT', MoveFrame:GetParent(), 'TOPLEFT')
  TrackingFrame:SetScript('OnSizeChanged', MoveFrameGetNearestFrame)
  MoveFrame:StartMoving()
end

-------------------------------------------------------------------------------
-- MoveFrameModifyAlignFrames
--
-- Adds/removes a frame from the aligned frames list.
--
-- Move         Contains the Move data.
-- MoveFrame    Frame that was moved by MoveFrameStart
-- SelectFrame  Frame that was selected by MoveFrameGetNearestFrame
--              If SelectFrame is nil then MoveFrame will be removed
--              from the list. Or if MoveFrame was being used by another
--              frame, then that frame is removed from the list.
-------------------------------------------------------------------------------
local function MoveFrameModifyAlignFrames(Move, MoveFrame, SelectFrame)
  local AlignFrames = Move.AlignFrames
  local AlignFrame = nil

  if AlignFrames == nil then
    AlignFrames = {}
    Move.AlignFrames = AlignFrames
  end
  local Index = 1

  if #AlignFrames > 0 then
    repeat
      local AlignFrame2 = AlignFrames[Index]
      local DelIndex = 1
      local Deleted = false

      -- Delete any entries using moveframe.
      repeat
        local AlignFrame3 = AlignFrames[DelIndex]
        local MF = AlignFrame3.MoveFrame

        -- Delete frame that was moved away from another frame that was using
        -- moveframe.  Or delete any moveframe in the list if SelectFrame is nil.
        if MoveFrame ~= MF and MoveFrame == AlignFrame3.SelectFrame or
           MoveFrame == MF and SelectFrame == nil then
          tremove(AlignFrames, DelIndex)
          Deleted = true
        else
          DelIndex = DelIndex + 1
        end
      until DelIndex > #AlignFrames

      if SelectFrame == nil then
        break
      elseif MoveFrame == AlignFrame2.MoveFrame then

        -- Found AlignFrame.
        AlignFrame = AlignFrame2
        break
      end
      if not Deleted then
        Index = Index + 1
      end
    until Index > #AlignFrames or SelectFrame == nil
  end

  if SelectFrame then

    -- Create new entry
    if AlignFrame == nil then
      AlignFrame = {}
      AlignFrames[#AlignFrames + 1] = AlignFrame
    end
    AlignFrame.MoveFrame = MoveFrame
    AlignFrame.SelectFrame = SelectFrame
    AlignFrame.MovePoint = MovePoint
    AlignFrame.SelectPoint = MoveSelectPoint
    AlignFrame.PaddingDirectionX = Move.PaddingDirectionX
    AlignFrame.PaddingDirectionY = Move.PaddingDirectionY
    AlignFrame.Offset = false
  end

  -- find offset frame
  local NumAlignFrames = #AlignFrames

  for Index = 1, NumAlignFrames do
    AlignFrame = AlignFrames[Index]
    local SF = AlignFrame.SelectFrame
    local MF = AlignFrame.MoveFrame
    local Offset = true

    for Index2 = 1, NumAlignFrames do
      local AlignFrame2 = AlignFrames[Index2]

      if SF == AlignFrame2.MoveFrame then
        Offset = false
      end
    end

    -- Offset found, but if its not being used by another frame then
    -- its not the offset frame.
    if Offset then
      Offset = false
      for Index2 = 1, NumAlignFrames do
        local AlignFrame2 = AlignFrames[Index2]

        if MF == AlignFrame2.SelectFrame then
          Offset = true
        end
      end
    end
    AlignFrame.Offset = Offset
  end
end

-------------------------------------------------------------------------------
-- MoveFrameStop
--
-- Stops moving the frame that was started by MoveStart
--
-- MoveFrames      The list of frames passed to MoveStart
--
-- Returns:
--   MoveSelectFrame        Frame that is selected by align or swap
--   MovePoint              Anchor point for the frame that was moved.
--   SelectPoint            Relative anchor point for the selected frame.
--
-- NOTES: if no frame was selected or aligned then MoveSelectFrame is nil
-------------------------------------------------------------------------------
function GUB.Main:MoveFrameStop(MoveFrames)
  local Move = MoveFrames.Move
  local MoveFrame = Move.Frame
  local Flags = Move.Flags

  MoveFrame:SetFrameStrata(Move.FrameStrata)

  TrackingFrame:SetScript('OnSizeChanged', nil)
  MoveFrameSetHighlightFrame(false)
  MoveFrame:StopMovingOrSizing()

  -- Add frame to AlignFrames list if align is on.
  if Flags.Align and Flags.Float then
    MoveFrameModifyAlignFrames(Move, MoveFrame, MoveSelectFrame)
  end

  -- Set frames
  if Flags.Float then
    if MoveSelectFrame then
      local MoveFrame = Move.Frame

      if Flags.Swap then
        -- Swap
        local x, y = Bar:GetRect(MoveSelectFrame)

        MoveFrame:ClearAllPoints()
        MoveFrame:SetPoint('TOPLEFT', x, y)
        MoveSelectFrame:ClearAllPoints()
        MoveSelectFrame:SetPoint('TOPLEFT', Move.FrameOldX, Move.FrameOldY)
      elseif Flags.Align then
        -- Align
        MoveFrame:ClearAllPoints()
        MoveFrame:SetPoint(MovePoint, MoveSelectFrame, MoveSelectPoint, 0, 0)
      end
    end
    if MoveSelectFrame == nil or not Flags.Swap and not Flags.Align then

      -- Place frame
      local x, y = Bar:GetRect(MoveFrame)

      MoveFrame:ClearAllPoints()
      MoveFrame:SetPoint('TOPLEFT', x, y)
    end
  end

  -- hide the box around the current bar being dragged
  if TrackingFrame.Type == 'bar' and UnitBars.HighlightDraggedBar then
    MoveFrame.MoveHighlightFrame:Hide()
  end

  return MoveSelectFrame
end

-------------------------------------------------------------------------------
-- MoveFrameSetAlignPadding
--
-- Adds padding to a frames padding group.  Can also offset the padding group.
--
-- MoveFrames        One or more frames to be padded
-- PaddingX          Distance between each frame set for horizontal alignment.
--                   'reset' then the padding info gets deleted.
-- PaddingY          Distance between each frame set for vertical alignment.
-- OffsetX           Horizontal Offset for the whole padding group.
-- OffsetY           Vertical Offset for the whole padding group.
--
-- NOTES:  There can be more than one padding group.  In this case each one
--         would get offset.
-------------------------------------------------------------------------------
function GUB.Main:MoveFrameSetAlignPadding(MoveFrames, PaddingX, PaddingY, OffsetX, OffsetY)
  local Move = MoveFrames.Move

  if Move then

    -- Erase Padding data if align is faled
    if PaddingX == 'reset'then
      Move.AlignFrames = nil
    else
      local AlignFrames = Move.AlignFrames
      local Index = 1

      if AlignFrames and #AlignFrames > 0 then

        -- Remove any invisible select frames
        repeat
          local AlignFrame = AlignFrames[Index]
          local SelectFrame = AlignFrame.SelectFrame

          if SelectFrame:IsVisible() == nil then
            tremove(AlignFrames, Index)
          else
            Index = Index + 1
          end
        until Index > #AlignFrames
        local NumAlignFrames = #AlignFrames

        -- Offset or pad frames
        for Index = 1, NumAlignFrames do
          local AlignFrame = AlignFrames[Index]
          local MF = AlignFrame.MoveFrame

          MF:ClearAllPoints()
          local PadX = AlignFrame.PaddingDirectionX * PaddingX
          local PadY = AlignFrame.PaddingDirectionY * PaddingY
          if AlignFrame.Offset then
            PadX = OffsetX or 0
            PadY = OffsetY or 0
          end
          MF:SetPoint(AlignFrame.MovePoint, AlignFrame.SelectFrame, AlignFrame.SelectPoint, PadX, PadY)
        end

        for Index = 1 , NumAlignFrames do
          local MF = AlignFrames[Index].MoveFrame
          local x, y = Bar:GetRect(MF)

          MF:ClearAllPoints()
          MF:SetPoint('TOPLEFT', x, y)
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- TrackSpell
--
-- Subfunction of CombatLogUnfiltered()
-- Subfunction of SpellCasting()
--
-- Sets the spell to be tracked based on events from CombatLogUnfiltered() and SpellCasting().
--
-- Usage: TrackSpell(Event, SpellID, LineID, Message)
--
-- Event        Event from CombatlogUnfiltered() or SpellCasting().
-- SpellID      SpellID of the spell.
-- LineID       Only valid for start, success, an events.
-- Message      Message from combatlog.
--
-- NOTES:
--         Timeouts are used so only events SPELL_MISS and SPELL_ENERGIZE needs to be tracked.
--         If one of those events didn't happen, then the timeout will remove the spell.
--
--         See the notes at the top of the file about the spell tracker.
--
--         Fn() can get called 3 times.
--         Fn(SpellID, CastTime, Message, UnitBarF)
--           Message = 'start'   Gets called on spell cast start.
--                   = 'end'     Gets called on spell success.
--                   = 'failed'  Gets called if the spell didn't complete.
--                   = 'timeout' Gets called by CheckSpellTrackerTimeout() if the spell timed out.
--           CastTime  The amount of time to cast the spell in seconds.
--           SpellID   is always negative on 'start', 'end', or 'failed'
--           UnitBarF  Type of bar that SpellID was defined with in SetSpellTracker()
--
--           If its energize then the message comes from the server.
-------------------------------------------------------------------------------
local function TrackSpell(Event, TimeStamp, SpellID, LineID, Message)
  local PSE = SpellTrackerEvent[Event]

  if PSE ~= nil then
    local PS = TrackedSpell[SpellID]

    -- Check for valid spellID.
    if PS ~= nil then
      local UnitBarF = PS.UnitBarF

      -- Check to see if spell tracker is active for this bar.
      if SpellTrackerActive[UnitBarF] then
        local Flight = PS.Flight
        local Fn = PS.Fn
        local CastTime = 0

        -- Detect start cast.
        if PSE == EventSpellStart then

          -- Get cast time for spell.
          local _, _, _, _, _, _, CastTime = GetSpellInfo(SpellID)

          -- Turn CastTime into seconds.
          CastTime = CastTime / 1000

          -- Call Fn.
          if Fn then
            Fn(UnitBarF, -SpellID, CastTime, 'start')
          end

          -- Set spell to be tracked.
          ModifySpellTracker('add', UnitBarF, SpellID, LineID, CastTime, Fn)
        else
          CastTime = SpellTrackerCasting.CastTime
        end

        -- Remove casting spell or a failed casting spell.
        if PSE == EventSpellSucceeded and LineID == SpellTrackerCasting.LineID or
           PSE == EventSpellFailed and SpellTrackerMessage[Message] == nil then

          if PS.EndOn == 'casting' or PSE == EventSpellFailed then
            ModifySpellTracker('remove')
          end

          -- Call Fn if one was set
          if Fn then
            if PSE == EventSpellFailed then
              Fn(UnitBarF, -SpellID, CastTime, 'failed')
            elseif PS.EndOn == 'casting' then
              Fn(UnitBarF, -SpellID, CastTime, 'end')
            end
          end
        end

        if PSE == EventSpellEnergize or PSE == EventSpellMissed then
          if PS.EndOn == 'energize' or PSE == EventSpellMissed then
            ModifySpellTracker('remove')
          end

          -- call Fn on energize.
          if PSE == EventSpellEnergize and Fn then
            Fn(UnitBarF, SpellID, CastTime, Message)
          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- PlayerEquipmentChanged (called by event)
--
-- Gets called when ever a player changes a piece of gear.
-- This function then calls CheckSetBonus()
-------------------------------------------------------------------------------
function GUB:PlayerEquipmentChanged()

  -- Update gear set bonus.
  CheckSetBonus()
end

-------------------------------------------------------------------------------
-- CombatLogUnfiltered (called by event)
--
-- Captures combat log events.
-------------------------------------------------------------------------------
function GUB:CombatLogUnfiltered(Event, TimeStamp, CombatEvent, HideCaster, SourceGUID, SourceName, SourceFlags, DestGUID, DestName, DestFlags, ...)

  -- track spell for player only.
  if SourceGUID == PlayerGUID then

    -- Pass spellID and Message.
    TrackSpell(CombatEvent, TimeStamp, select(3, ...), nil, select(6, ...))
  end
end

-------------------------------------------------------------------------------
-- SpellCasting (called by event)
--
-- Gets called when the player started or stopped casting a spell.
-------------------------------------------------------------------------------
function GUB:SpellCasting(Event, Unit, Name, Rank, LineID, SpellID)

  -- track spell for player only.
  TrackSpell(Event, nil, SpellID, LineID, '')
end

-------------------------------------------------------------------------------
-- UnitBarsUpdateStatus
--
-- Event handler that hides/shows the unitbars based on their current settings.
-- This also updates all unitbars that are visible.
-------------------------------------------------------------------------------
function GUB:UnitBarsUpdateStatus(Event, Unit)

  -- Do nothing if the unit is not 'player'.
  if Unit ~= nil and Unit ~= 'player' then
    return
  end

  InCombat = UnitAffectingCombat('player') == 1
  InVehicle = UnitHasVehicleUI('player')
  InPetBattle = C_PetBattles.IsInBattle()
  IsDead = UnitIsDeadOrGhost('player') == 1
  HasTarget = UnitExists('target') == 1
  HasFocus = UnitExists('focus') == 1
  HasPet = select(1, HasPetUI()) ~= nil
  PlayerStance = GetShapeshiftFormID()
  PlayerPowerType = UnitPowerType('player')
  PlayerSpecialization = GetSpecialization()

  for _, UBF in ipairs(UnitBarsFE) do
    UBF:StatusCheck()
    UBF:Update()
  end
end

-------------------------------------------------------------------------------
-- UnitBarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar parent frame will be moved.
-- Otherwise just the unitbar frame will be moved.
--
-- Note: To move a frame the unitbars anchor needs to be moved.
--       This function returns false if it didn't do anything, otherwise true.
-------------------------------------------------------------------------------
function GUB.Main:UnitBarStartMoving(Frame, Button)

  -- Handle selection of unitbars for the alignment tool.
  if Button == 'RightButton' and UnitBars.AlignAndSwapEnabled and not IsModifierKeyDown() then
    Options:OpenAlignSwapOptions()
    return false
  end

  if Button == 'LeftButton' and IsModifierKeyDown() then
    -- Set the moving flag.
    -- Group move check.
    if UnitBars.IsGrouped then
      UnitBarsParent.IsMoving = true
      UnitBarsParent:StartMoving()
    else
      Frame.IsMoving = true
      if Options.AlignSwapOpen then
        Main:MoveFrameStart(UnitBarsFE, Frame, UnitBars)
      else
        Main:MoveFrameStart(UnitBarsFE, Frame)
      end
    end
    return true
  else
    return false
  end
end

-------------------------------------------------------------------------------
-- SetUnitBarsAlignSwap
--
-- Align all unitbars
-------------------------------------------------------------------------------
function GUB.Main:SetUnitBarsAlignSwap()
  if not UnitBars.Align then
    Main:MoveFrameSetAlignPadding(UnitBarsFE, 'reset')
  else
    Main:MoveFrameSetAlignPadding(UnitBarsFE, UnitBars.AlignSwapPaddingX, UnitBars.AlignSwapPaddingY, UnitBars.AlignSwapOffsetX, UnitBars.AlignSwapOffsetY)
  end
  for _, UBF in ipairs(UnitBarsFE) do
    local UB = UBF.UnitBar
    local Anchor = UBF.Anchor
    local x, y = Bar:GetRect(Anchor)

    Anchor:ClearAllPoints()
    Anchor:SetPoint('TOPLEFT', x, y)
    UB.x, UB.y = x, y
  end
end

-------------------------------------------------------------------------------
-- UnitBarStopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
--
-- returns true if it stopped a frame that started with UnitBarsStartMoving()
-------------------------------------------------------------------------------
function GUB.Main:UnitBarStopMoving(Frame)
  if UnitBarsParent.IsMoving then
    UnitBarsParent.IsMoving = false
    UnitBarsParent:StopMovingOrSizing()

    -- Save the new position of the ParentFrame.
    UnitBars.Point, _, UnitBars.RelativePoint, UnitBars.Px, UnitBars.Py = UnitBarsParent:GetPoint()
    return true
  elseif Frame.IsMoving then
    Frame.IsMoving = false
    Main:MoveFrameStop(UnitBarsFE)
    if Options.AlignSwapOpen then
      Main:SetUnitBarsAlignSwap()
    else
      local x, y = Bar:GetRect(Frame)

      Frame.UnitBar.x, Frame.UnitBar.y = x, y
      Frame:ClearAllPoints()
      Frame:SetPoint('TOPLEFT', x, y)
    end
    return true
  end
  return false
end

--*****************************************************************************
--
-- Unitbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UnitBarsSetAllOptions
--
-- Handles the settings that effect all the unitbars.
--
-- Activates the current settings in UnitBars.
--
-- IsLocked
-- AlignmentToolEnabled
-- IsClamped
-- FadeOutTime
-- FadeInTime
-------------------------------------------------------------------------------
function GUB.Main:UnitBarsSetAllOptions()
  local ATOFrame = Options.ATOFrame
  local IsLocked = UnitBars.IsLocked
  local IsClamped = UnitBars.IsClamped
  local FadeOutTime = UnitBars.FadeOutTime
  local FadeInTime = UnitBars.FadeInTime

  -- Update text highlight only when options window is open
  if Options.MainOpen then
    Bar:SetHighlightFont('on', UnitBars.HideTextHighlight)
  end

  -- Update alignment tool status.
  if IsLocked or not UnitBars.AlignAndSwapEnabled then
    Options:CloseAlignSwapOptions()
  end

  -- Apply the settings.
  for _, UBF in ipairs(UnitBarsFE) do
    UBF:EnableMouseClicks(not IsLocked)
    UBF.Anchor:SetClampedToScreen(IsClamped)
    UBF.Fade:SetDuration('out', FadeOutTime)
    UBF.Fade:SetDuration('in', FadeInTime)
  end
end

-------------------------------------------------------------------------------
-- UnitBarSetAttr
--
-- Base unitbar set attribute. Handles attributes that are shared across all bars.
--
-- Usage    UnitBarSetAttr(UnitBarF, Object, Attr)
--
-- UnitBarF    The Unitbar frame to work on.
-------------------------------------------------------------------------------
function GUB.Main:UnitBarSetAttr(UnitBarF)

  -- Get the unitbar data.
  local UB = UnitBarF.UnitBar

  -- Frame.
  UnitBarF.ScaleFrame:SetScale(UB.Other.Scale)

  -- Update the unitbar to the correct size based on scale.
  UnitBarF:SetSize()
  UnitBarF.Anchor:SetFrameStrata(UB.Other.FrameStrata)
end

-------------------------------------------------------------------------------
-- SetUnitBarLayout
--
-- Sets the layout for a unitbar that is already created.
--
-- UnitBarF      UnitBarsF[BarType]
-- BarType       Type of bar
-------------------------------------------------------------------------------
local function SetUnitBarLayout(UnitBarF, BarType)
  local UB = UnitBarF.UnitBar
  local Anchor = UnitBarF.Anchor

  -- Stop any old fade animation for this unitbar.
  UnitBarF.Fade:SetAnimation('stopall')

  -- Set the anchor position and size.
  Anchor:ClearAllPoints()
  Anchor:SetPoint('TOPLEFT', UB.x, UB.y)
  Anchor:SetSize(1, 1)

  --Set a reference to UnitBar[BarType] for moving.
  Anchor.UnitBar = UB

  -- Set the IsActive flag to false.
  UnitBarF.IsActive = false

  -- Hide the unitbar.
  UnitBarF.Visible = false

  -- Set the hidden flag.
  UnitBarF.Hidden = true

  -- Hide the frame.
  UnitBarF.Anchor:Hide()

  -- Set Attributes for the bar.
  UnitBarF:SetAttr()
end

-------------------------------------------------------------------------------
-- CreateUnitBar
--
-- Creates a unitbar. If the UnitBar is already created this function does nothing.
--
-- UnitBarF    Subtable of UnitBarsF[BarType]
-- BarType     Type of bar.
-------------------------------------------------------------------------------
local function CreateUnitBar(UnitBarF, BarType)
  if UnitBarF.Created == nil then
    local UB = UnitBarF.UnitBar

    UnitBarF.Created = true

    -- Create the anchor frame.
    local Anchor = CreateFrame('Frame', nil, UnitBarsParent)
    Anchor:SetPoint('TOPLEFT', UB.x, UB.y)
    Anchor:SetSize(1, 1)

    -- Hide the anchor
    Anchor:Hide()

    -- Make the unitbar's anchor movable.
    Anchor:SetMovable(true)

    -- Make the unitbar come to top when clicked.
    Anchor:SetToplevel(true)

    -- Get name for align and swap.
    Anchor.Name = UnitBars[BarType].Name

    -- Create the scale frame.
    local ScaleFrame = CreateFrame('Frame', nil, Anchor)
    ScaleFrame:SetPoint('TOPLEFT', 0, 0)
    ScaleFrame:SetSize(1, 1)

    -- Save the bartype.
    UnitBarF.BarType = BarType

    --Set a reference to UnitBar[BarType] for moving.
    Anchor.UnitBar = UB

    -- Save a lookback to UnitBarF in anchor for selection (selectframe)
    Anchor.UnitBarF = UnitBarF

    -- Save the anchor.
    UnitBarF.Anchor = Anchor

    -- Save the scale frame.
    UnitBarF.ScaleFrame = ScaleFrame

    -- Save the enable bar function.
    UnitBarF.BarVisible = UB.BarVisible

    -- Add a SetSize function.
    UnitBarF.SetSize = SetUnitBarSize

    -- Create an animation for fade in/out.  Make this a parent fade.
    UnitBarF.Fade = Main:CreateFade(UnitBarF, Anchor, true)

    if strfind(BarType, 'Health') or strfind(BarType, 'Power') then
      HapBar:CreateBar(UnitBarF, UB, ScaleFrame)
    else
      GUB[BarType]:CreateBar(UnitBarF, UB, ScaleFrame)
    end
  end
end

--*****************************************************************************
--
-- Addon Enable/Disable functions
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetUnitBars
--
-- Sets the UnitBarsParent.
-- Creates/Enables/Disables unitbars.
-- Sets the layout.
-------------------------------------------------------------------------------
function GUB.Main:SetUnitBars(ProfileChanged)
  local EnableClass = UnitBars.EnableClass
  local ATOFrame = Options.ATOFrame
  local Index = 0
  local Total = 0

  Main.ProfileChanged = ProfileChanged or false
  if ProfileChanged then

    -- Create the unitbar parent frame.
    if UnitBarsParent == nil then
      UnitBarsParent = CreateFrame('Frame', nil, UIParent)
      UnitBarsParent:SetMovable(true)
    end

    -- Set the unitbar parent frame values.
    UnitBarsParent:ClearAllPoints()
    UnitBarsParent:SetPoint(UnitBars.Point, UIParent, UnitBars.RelativePoint, UnitBars.Px, UnitBars.Py)
    UnitBarsParent:SetWidth(1)
    UnitBarsParent:SetHeight(1)

    -- Reset the spell tracker.
    Main:SetSpellTracker('reset')
  end

  for BarType, UBF in pairs(UnitBarsF) do
    local UB = UBF.UnitBar

    -- Reset the OldEnabled flag during profile change.
    if ProfileChanged then
      UBF.OldEnabled = nil
    end
    Total = Total + 1

    -- Enable/Disable if player class option is true.
    local UsedByClass = UB.UsedByClass

    if EnableClass then
      UB.Enabled = UsedByClass == nil or UsedByClass[PlayerClass] ~= nil
    end
    local Enabled = UB.Enabled

    if Enabled then
      Index = Index + 1
      UnitBarsFE[Index] = UBF
    end
    if Enabled ~= UBF.OldEnabled then
      local JustCreated = false
      local Created = UBF.Created

      if Enabled then

        -- If the unitbar is being created for the first time or
        -- the profile was changed.  Then set layout, baroptions.
        if Created == nil then
          CreateUnitBar(UBF, BarType)
          JustCreated = true
        end

      elseif Created then

        if ProfileChanged then
          UBF.Hidden = true
          UBF.Anchor:Hide()
        else
          -- Hide the unitbar.
          HideUnitBar(UBF, true)
        end
      end
      if ProfileChanged and Created or JustCreated then
        SetUnitBarLayout(UBF, BarType)
      end
      UBF:Enable(Enabled)
    end
    UBF.OldEnabled = Enabled
  end

  -- Delete extra bars from the array.
  for Count = Index + 1, Total do
    UnitBarsFE[Count] = nil
  end

  Options:AddRemoveBarGroups()

  if ProfileChanged == nil then
    GUB:UnitBarsUpdateStatus()
    Main:UnitBarsSetAllOptions()
  end

  Main.ProfileChanged = false
end

-------------------------------------------------------------------------------
-- ShareData
--
-- Makes upvalues accessable to other parts of the addon.
-------------------------------------------------------------------------------
local function ShareData()

  -- Share data with rest of addon.
  Main.UnitBars = UnitBars
  Main.PlayerClass = PlayerClass
  Main.PlayerPowerType = PlayerPowerType

  -- Refresh reference to UnitBar[BarType]
  for BarType, UBF in pairs(UnitBarsF) do
    UBF.UnitBar = UnitBars[BarType]
  end
end

--*****************************************************************************
--
-- Addon Profile Management
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SharedMedia management
-------------------------------------------------------------------------------
function GUB:MediaUpdate(Name, MediaType, Key)
  for _, UBF in ipairs(UnitBarsFE) do
    if MediaType == 'border' or MediaType == 'background' then
      UBF:SetAttr('Background', nil)
    elseif MediaType == 'statusbar' then
      UBF:SetAttr('Bar', nil)
    elseif MediaType == 'font' then
      UBF:SetAttr('Text', nil)
    end
  end
end

-------------------------------------------------------------------------------
-- CleanUnitBars
--
-- Deletes anything not on the exclude list.
--
-- NOTES: Exclude list
--         * means a bartype like PlayerPower, EclipseBar, etc.
--         # Means an array element.
-------------------------------------------------------------------------------
local function CleanUnitBars(DefaultTable, Table, TablePath)
  local ExcludeList = {
    ['Version'] = 1,
    ['*.Text.#'] = 1,
    ['*.BoxLocations'] = 1,
    ['*.BoxOrder'] = 1,
  }

  if DefaultTable == nil then
    DefaultTable = DUB
    Table = UnitBars
    TablePath = ''
  end

  for Key, Value in pairs(Table) do
    local DefaultValue = DefaultTable[Key]
    local PathKey = Key

    if UnitBarsF[Key] then
      PathKey = '*'
    elseif type(Key) == 'number' then
      PathKey = '#'
    end
    if ExcludeList[format('%s%s', TablePath, PathKey)] == nil then
      if DefaultValue ~= nil then
        if type(Value) == 'table' then
          CleanUnitBars(DefaultValue, Value, format('%s%s.', TablePath, PathKey))
        end
      else
        --print('CLEAN:', format('%s%s', TablePath, PathKey))
        Table[Key] = nil
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Profile Apply
-------------------------------------------------------------------------------
function GUB:ApplyProfile()
  UnitBars = GUB.MainDB.profile

  -- Share the values with other parts of the addon.
  ShareData()

  if UnitBars.Version == nil then
    -- Convert profile from preversion 200.
    ConvertUnitBarData()
  end
  if UnitBars.Version ~= Version then
    CleanUnitBars()
    UnitBars.Version = Version
  end

  Main:SetUnitBars(true)

  -- Update options.
  Options:DoFunction()

  -- Reset align padding.
  Main:MoveFrameSetAlignPadding(UnitBarsFE, 'reset')

  Main:UnitBarsSetAllOptions()
  GUB:UnitBarsUpdateStatus()
end

-------------------------------------------------------------------------------
-- Profile New
-------------------------------------------------------------------------------
function GUB:ProfileNew(Event)
  GUB.MainDB.profile.Version = Version
  if Event == 'OnProfileReset' then
    GUB:ApplyProfile()
  end
end

-------------------------------------------------------------------------------
-- One time initialization.
--
-- This has to be done cause some of these functions don't return valid data
-- until after OnEnable()
-------------------------------------------------------------------------------
function GUB:OnEnable()
  if not InitOnce then
    return
  end
  InitOnce = false

  if GalvinUnitBarsData == nil then
    GalvinUnitBarsData = {}
  end
  GUBData = GalvinUnitBarsData

  -- Add blizzards powerbar colors and class colors to defaults.
  InitializeColors()

  -- Load the unitbars database
  GUB.MainDB = LibStub('AceDB-3.0'):New('GalvinUnitBarsDB', GUB.DefaultUB.Default, true)

  UnitBars = GUB.MainDB.profile

  _, PlayerClass = UnitClass('player')
  PlayerPowerType = UnitPowerType('player')

  -- Get the globally unique identifier for the player.
  PlayerGUID = UnitGUID('player')

  ShareData()
  Options:OnInitialize()
  GUB:ApplyProfile()

  GUB.MainDB.RegisterCallback(GUB, 'OnProfileReset', 'ProfileNew')
  GUB.MainDB.RegisterCallback(GUB, 'OnNewProfile', 'ProfileNew')
  GUB.MainDB.RegisterCallback(GUB, 'OnProfileChanged', 'ApplyProfile')
  GUB.MainDB.RegisterCallback(GUB, 'OnProfileCopied', 'ApplyProfile')
  LSM.RegisterCallback(GUB, 'LibSharedMedia_Registered', 'MediaUpdate')

  -- Initialize the events.
  RegisterEvents('register', 'main')

  if GUBData.ShowMessage ~= 1 then
    GUBData.ShowMessage = 1
    ShowMessage(DefaultUB.MessageText)
  end
end

