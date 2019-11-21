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
local InCombatOptionsMessage = GUB.DefaultUB.InCombatOptionsMessage

local Main = {}
local UnitBarsF = {}
local UnitBarsFE = {}
local Bar = {}
local HapBar = {}
local Options = {}

GUB.Main = Main
GUB.Bar = Bar
GUB.HapBar = HapBar
GUB.StaggerBar = {}
GUB.AltPowerBar = {}
GUB.RuneBar = {}
GUB.ComboBar = {}
GUB.HolyBar = {}
GUB.ShardBar = {}
GUB.FragmentBar = {}
GUB.ChiBar = {}
GUB.ArcaneBar = {}
GUB.Options = Options

LibStub('AceAddon-3.0'):NewAddon(GUB, MyAddon, 'AceConsole-3.0', 'AceEvent-3.0')

local LSM = LibStub('LibSharedMedia-3.0')

-- localize some globals.
local _, _G =
      _, _G
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt,      mhuge =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt, math.huge
local strfind, strmatch, strsplit, strsub, strtrim, strupper, strlower, format, gsub, gmatch =
      strfind, strmatch, strsplit, strsub, strtrim, strupper, strlower, format, gsub, gmatch
local GetTime, ipairs, pairs, next, pcall, print, select, tonumber, tostring, tremove, type, unpack =
      GetTime, ipairs, pairs, next, pcall, print, select, tonumber, tostring, tremove, type, unpack

local CreateFrame, IsModifierKeyDown, PetHasActionBar, PlaySound, message, HasPetUI, GameTooltip, UIParent =
      CreateFrame, IsModifierKeyDown, PetHasActionBar, PlaySound, message, HasPetUI, GameTooltip, UIParent
local C_PetBattles, C_TimerAfter,  GetShapeshiftFormID, GetSpecialization, GetSpellBookItemInfo, GetSpellInfo =
      C_PetBattles, C_Timer.After, GetShapeshiftFormID, GetSpecialization, GetSpellBookItemInfo, GetSpellInfo
local C_SpecializationInfoGetPvpTalentSlotInfo,  GetTalentInfo, GetPvpTalentInfoByID, GetCursorPosition =
      C_SpecializationInfo.GetPvpTalentSlotInfo, GetTalentInfo, GetPvpTalentInfoByID, GetCursorPosition
local UnitAlternatePowerInfo, UnitAura, UnitCanAttack, UnitCastingInfo, UnitClass, UnitExists =
      UnitAlternatePowerInfo, UnitAura, UnitCanAttack, UnitCastingInfo, UnitClass, UnitExists
local UnitGUID, UnitHasVehicleUI, UnitIsDeadOrGhost, UnitIsPVP, UnitIsTapDenied, UnitPlayerControlled, UnitPowerMax =
      UnitGUID, UnitHasVehicleUI, UnitIsDeadOrGhost, UnitIsPVP, UnitIsTapDenied, UnitPlayerControlled, UnitPowerMax
local UnitPowerType, UnitReaction, wipe, GetZoneText, GetMinimapZoneText, UnitPowerBarAlt_TearDown, UnitPowerBarAlt_UpdateAll =
      UnitPowerType, UnitReaction, wipe, GetZoneText, GetMinimapZoneText, UnitPowerBarAlt_TearDown, UnitPowerBarAlt_UpdateAll
local PowerBarColor, RAID_CLASS_COLORS, PlayerFrame, TargetFrame, PlayerBuffTimerManager, GetBuildInfo, LibStub =
      PowerBarColor, RAID_CLASS_COLORS, PlayerFrame, TargetFrame, PlayerBuffTimerManager, GetBuildInfo, LibStub
local SoundKit, hooksecurefunc, PlayerPowerBarAlt, ExtraActionButton1, InCombatLockdown, UnitAffectingCombat =
      SOUNDKIT, hooksecurefunc, PlayerPowerBarAlt, ExtraActionButton1, InCombatLockdown, UnitAffectingCombat

------------------------------------------------------------------------------
-- Register GUB textures with LibSharedMedia
------------------------------------------------------------------------------
LSM:Register('statusbar', 'GUB Bright Bar', [[Interface\Addons\GalvinUnitBars\Textures\GUB_SolidBrightBar]])
LSM:Register('statusbar', 'GUB Dark Bar', [[Interface\Addons\GalvinUnitBars\Textures\GUB_SolidDarkBar]])
LSM:Register('statusbar', 'GUB Empty', [[Interface\Addons\GalvinUnitBars\Textures\GUB_EmptyBar]])
LSM:Register('border',    'GUB Square Border', [[Interface\Addons\GalvinUnitBars\Textures\GUB_SquareBorder]])

------------------------------------------------------------------------------
-- To fix some problems with elvui.  I had to change Width and Height
-- to _Width and _Height in some code through out the addon.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Unitbars frame layout.
--
-- UnitBarsParent
--   Anchor
--     AnchorPointFrame
--       AlphaFrame
--         ScaleFrame
--           <Unitbar frames start here>
--
--
-- UnitBarsF structure    NOTE: To access UnitBarsF by index use UnitBarsFE[Index].
--                              UnitBarsFE is used to enable/disable bars in SetUnitBars().
--
-- UnitBarsParent             - Child of UIParent.  The perpose of this is so all bars can be moved as a group.
-- UnitBarsF[]                - UnitBarsF[] is a frame and table.  This is so each bar can have its own events,
--                              and all data for each bar.
--   Anchor                   - Child of UnitBarsParent.  The root of every bar.  Controls hide/show
--                              and size of a bar and location on the screen.  Also brings the bar to top level when clicked.
--                              From my testing any frame that gets clicked on that is a child of a frame with SetToplevel(true)
--                              will bring the parent to top level even if the parent wasn't the actual frame clicked on.
--     IsAnchor               - Flag to determin if a frame is an anchor.
--     UnitBar                - This is used for moving since the move code needs to update the bars position data after each move.
--     UnitBarF               - Reference to UnitBarF for selectframe or animation.
--     Name                   - Name of the UnitBar.  This is used by the align and swap options which uses MoveFrameStart()
--     Width, Height          - Size of the anchor
--     AnchorPointFrame       - Reference to AnchorPointFrame
--
--   AlphaFrame               - Child of Anchor.  Controls the transparency of the bar. Used by UnitBarSetAttr()
--   ScaleFrame               - Child of AlphaFrame.  Controls scaling of bars to be made larger or smaller thru SetScale().
--   AnchorPointFrame         - Allows the bar to have different points, without causing the anchor to move.
--     Width, Height          - Size of the AnchorPointFrame
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
--   BarVisible()         - This is used by StatusCheck() to determin if a bar should be hidden.  Bars like focus
--                          need to be hidden when the player doesn't have a target or focus.
--
--
-- UnitBarsF data.  Each bar has data that keeps track of the bars state.
--
-- List of UnitBarsF values.
--
--   Anchor               - Frame that holds the location of the bar.  This is a child of UnitBarsParent.
--
--   Created              - If nil then the bar has not been created yet, otherwise true.
--   OldEnabled           - Current state of the bar. This is used to detect if a bar is being changed from enabled to disabled or
--                          vice versa.  Used by SetUnitBars().
--   Hidden               - True or false.  If true then the bar is hidden
--   IsActive             - True, false, or 0.
--                            True   The bar is considered to be doing something.
--                            False  The bar is not active.
--                            0      The bar is waiting to be active again.  If the flag is checked by StatusCheck() and is false.
--                                   Then it sets it to zero.
--   IsHealth             - Is a health bar. Part of health and power.
--   IsPower              - Is a power bar. Part of health and power.
--   ClassSpecEnabled     - If true then the bar is enabled by CheckClassSpecs()
--   BarType              - Mostly for debugging.  Contains the type of bar. 'PlayerHealth', 'RuneBar', etc.
--   UnitBar              - Reference to the current UnitBar data which is the current profile.  Each time the
--                          profile changes this value gets referenced to the new profile. This is the same
--                          as UnitBars[BarType].
--
--
-- UnitBar mod upvalues/tables.
--
-- Main.UnitBarsF         - Reference to UnitBarsF
-- Main.UnitBarsFE        - Reference to UnitBarsFE
-- Main.LSM               - Reference to Lib Shared Media.
-- Main.ProfileChanged    - If true then profile is currently being changed. This is set by SetUnitBars()
-- Main.CopyPasted        - If true then a copy and paste happened.  This is set by CreateCopyPasteOptions() in Options.lua.
-- Main.Reset             - If true then a reset happened.  This is set by CreateResetOptions() in options.lua.
-- Main.PlayerSpecializationChanged
--                        - If true then the player changed their specialization.
-- Main.PlayerSpecialization
--                          - Number. Contains the current specialization of the player.
-- Main.UnitBars            - Set by ShareData()
-- Main.Gdata               - Set by ShareData()
-- Main.PlayerClass         - Set by ShareData()
-- Main.PlayerPowerType     - Set by ShareData() and UnitBarsUpdateStatus()
-- Main.ConvertCombatColor  - Reference to ConvertCombatColor
-- Main.ConvertPowerTypeHAP - Reference to ConvertPowerTypeHAP
-- Main.ConvertPowerType    - Rerference to ConvertPowerType
-- Main.InCombat            - set by UnitBarsUpdateStatus()
-- Main.IsDead              - set by UnitBarsUpdateStatus()
-- Main.HasTarget           - set by UnitBarsUpdateStatus()
-- Main.HasAltPower         - set by UnitBarsUpdateStatus()
-- Main.TrackedAurasList    - Set by SetAuraTracker()
-- Main.PlayerGUID          - Set by ShareData()
--
-- Main.APBUsed           - Contains list of used power bars. Contains what minimap zone they were used in.
--                          set by UnitBarsUpdateStatus(). Used by ShareData()
-- Main.APBUseBlizz       - Contains a list of which power bars should use blizzards own, and not the GUB version
--                          set by CreateAltPowerBarOptions(). Used by ShareData() and DoBlizzAltPowerBar()
-- Main.APBMoverEnabled   - If true then the blizzard alternate power can be moved to a new location
-- Main.APBBuffTimerMoverEnabled - If true then the blizzard alternate power bar timer can be moved to a new location
-- Main.EABMoverEnabled   - If true then the extra action button can be moved to a new location
--
-- Main.Talents           - Contains the table Talents
--
-- UnitBars               - Contains the currently selected profile
-- Gdata                  - Anything stored in here can be seen by all characters on the same account
-- ConvertPowerType       - Table to convert a string powertype into a number
-- ConvertPowerTypeHAP    - Table used by InitializeColors()
--                          Same as ConvertPowerType except only has power types for power bars in HAP
-- ConvertCombatColor     - Converts combat color into a number.
-- InitOnce               - Used by OnEnable to initialize just one time.
-- MessageBox             - Contains the message box to show a message on screeen.
-- TrackingFrame          - Used by MoveFrameGetNearestFrame()
-- MouseOverDesc          - Mouse over tooltip displayed to drag bar.
-- UnitBarVersion         - Current version of the mod.
-- AlignAndSwapTooltipDesc - Tooltip to be shown when the alignment tool is active.
-- AnchorOffset           - Table used when changing the Anchor size.  Used by SetAnchorSize()
--
-- InCombat               - True or false. If true then the player is in combat.
-- InVehicle              - True or false. If true then the player is in a vehicle.
-- InPetBattle            - True or false. If true then the player is in a pet battle.
-- IsDead                 - True or false. If true then the player is dead.
-- HasTarget              - True or false. If true then the player has a target.
-- HasFocus               - True or false. If true then the player has a focus.
-- HasPet                 - True or false. If true then the player has a pet.
-- HasAltPower            - True or false. If true then the player has alternate power bar.
-- BlizzAltPowerVisible   - True or false. If true then the blizzard alt power bar is visible, otherwise hidden.
--                          Set by DoBlizzAltPowerBar(). Used by StatusCheck()
--
-- AltPowerBarID          - Current ID of the power bar if one is being used.
--                          Set by UnitBarsUpdateStatus(). Used by DoBlizzAltPowerBar()
-- APBMover               - Used to move the blizzard style alternate power bar
--                          Set by InitAltPowerBar(). Used by DoBlizzAltPowerBar()
-- APBBuffTimerMover      - Used to move the blizzard style buff timer alternate power bar
--                          Set by InitAltPowerBar(). Used by DoBlizzAltPowerBar()
-- EABMover               - Used to move the extra action button.
--                        - Set by InitExtraActionButton()
--
-- PlayerClass            - Name of the class for the player in uppercase, no spaces. not langauge sensitive.
-- PlayerGUID             - Globally unique identifier for the player.  Used by CombatLogUnfiltered()
-- PlayerPowerType        - String: The current power type for the player.
-- PlayerStance           - The current form/stance the player is in.
-- PlayerSpecialization   - The current specialization for the player, 0 for none.
--
-- RegEventFrames         - Table used by RegEvent()
-- RegUnitEventFrames     - Table used by RegUnitEvent()
-- Talents                - Table that contains talents, active, and used by options. See GetTalents()
--
-- MoonkinForm            - Current forms used by their bars.
-- CatForm
-- BearForm
-- MonkBrewMasterSpec     - Current specs used by their bars.
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
-- AuraListName           - Name used to keep track of the aura list.
--
-- ScanTooltip            - Used by CheckPredictedSpells(), CreateScanTooltip(), GetTooltip()
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Cast tracker
--
-- Keeps track of any spell being cast.
--
-- CastTrackers[UnitBarF]      - Keeps track of the casting info for the bar.
--   Enabled                   - Used by SetCastTracker()
--                                 if true then Fn will get called for this bar
--   Fn                        - Function to call when a cast is starting or stopped
--
-- CastTracking                - Used by TrackCast()
--                               Keeps track of a spell being cast.
--   SpellID                       The spell being cast
--   CastID                        Unit ID for the current spell cast.
--
-- CastTrackerEvent            - Filters out the events that are being looked for.
--                                 EventCastStart
--                                 EventCastStop
--                                 EventCastFailed
--                                 EventCastSucceeded
--                                 EventCastDelayed
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Aura Tracker
--
-- Tracks all auras on different units and caches them.
--
-- TrackedAurasOnUpdateFrame - Frame containing the onupdate for updating auras.
--
-- TrackedAuras[Object]      - Table containing which bar has auras.
--   Enabled                 - If true then events for this bar are turned on.
--   Units                   - Hash table of units for this object.
--   Fn                      - Function to call for this objeect.

-- TrackedAurasList.All      - Contains a list of all the spells not broken by unit.
--   All[SpellID]            - Reference to SpellID below, but only used by Spell.lua
--
-- TrackedAurasList[Unit]    - Table of units containing the auras
--   [SpellID]               - SpellID of each aura
--      Active               - If true then aura is on the unit, otherwise its false.
--      Own                  - If true then the player created this aura.
--      Stacks               - Amount of stacks the aura has.
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Predicted Spells
--
-- Keeps track of spells that give back power with a cast time.
--
-- PredictedSpells[-Index]    Cache of spells found in the spell book. -1 onward.
--   SpellID
--
-- PredictedSpells[SpellID]   Contains the amount of power a spell returns
--   Amount
--   PowerType                Type of power
--
-- PredictedSpells[UnitBarF]  Contains which bars are using predicted spells.
--   Fn                       if not nil this function will get called
--                            when a spells amount of power returned changes.
--
-- Notes on predicted spell tracking.
--
-- If the spell book changes a rescan of the spellbook takes place.  Just spells
-- that has a cast time and generate resource gets tracked.
--
-- When an aura changes the same function is called except this time it just
-- refresh the predicted power values.  If an aura buffs a spell that causes
-- it to return more resource, its tooltip will be updated while the aura is up.
-- So the spellbook gets scanned to find this change and the value is updated.
-- Same with equipment changing.
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
local APBMover = nil
local EABMover = nil
local APBBuffTimerMover = nil
local ScanTooltip = nil
local AuraListName = 'AuraList'
local InitOnce = true
local MessageBox = nil
local UnitBarsParent = nil
local UnitBars = nil
local Gdata = nil

local InCombat = false
local InVehicle = false
local InPetBattle = false
local IsDead = false
local HasTarget = false
local HasFocus = false
local HasPet = false
local HasAltPower = false
local BlizzAltPowerVisible = false
local AltPowerBarID = nil
local PlayerPowerType = nil
local PlayerClass = nil
local PlayerStance = nil
local PlayerSpecialization = nil
local PlayerGUID = nil
local APBUsed = nil
local APBUseBlizz = nil

local MoonkinForm = MOONKIN_FORM
local CatForm = CAT_FORM
local BearForm = BEAR_FORM
local MonkBrewmasterSpec = SPEC_MONK_BREWMASTER

local MoveAlignDistance = 8
local MoveSelectFrame = nil
local MoveLastSelectFrame = nil
local MovePoint = nil
local MoveSelectPoint = nil
local MoveLastHighlightFrame = nil
local MoveOldSelectFrame = nil
local MoveOldMFCenterX = nil
local MoveOldMFCenterY = nil

local SpellBookChanged = 'SPELLS_CHANGED'

local EventCastStart     = 1
local EventCastSucceeded = 2
local EventCastDelayed   = 3
local EventCastStop      = 4
local EventCastFailed    = 5

local CastTrackerEvent = {
  UNIT_SPELLCAST_START       = EventCastStart,
  UNIT_SPELLCAST_SUCCEEDED   = EventCastSucceeded,
  UNIT_SPELLCAST_DELAYED     = EventCastDelayed,
  UNIT_SPELLCAST_STOP        = EventCastStop,
  UNIT_SPELLCAST_FAILED      = EventCastFailed,
  UNIT_SPELLCAST_INTERRUPTED = EventCastFailed,
}

local CastTracking = nil
local CastTrackers = nil

local TrackedAurasOnUpdateFrame = nil
local TrackedAuras = nil
local TrackedAurasList = nil

local PredictedSpells = nil

local RegEventFrames = {}
local RegUnitEventFrames = {}
local Talents = {}

local SelectFrameBorder = {
  bgFile   = '',
  edgeFile = [[Interface\Addons\GalvinUnitBars\Textures\GUB_SquareBorder]],
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
  bgFile   = LSM:Fetch('background', 'Blizzard Dialog Background Dark'),
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

local AnchorOffset = {
  LEFT         = {x =  0,   y =  0.5},
  RIGHT        = {x = -1,   y =  0.5},
  TOP          = {x = -0.5, y =  0  },
  BOTTOM       = {x = -0.5, y =  1  },
  TOPLEFT      = {x =  0,   y =  0  },
  TOPRIGHT     = {x = -1,   y =  0  },
  BOTTOMLEFT   = {x =  0,   y =  1  },
  BOTTOMRIGHT  = {x = -1,   y =  1  },
  CENTER       = {x = -0.5, y =  0.5},
}

local ConvertPowerType = {
  MANA           = 0,
  RAGE           = 1,
  FOCUS          = 2,
  ENERGY         = 3,
  COMBO_POINTS   = 4,
  RUNIC_POWER    = 6,
  SOUL_SHARDS    = 7,
  LUNAR_POWER    = 8,
  ASTRAL_POWER   = 8,
  HOLY_POWER     = 9,
  ALTERNATE      = 10,
  MAELSTROM      = 11,
  CHI            = 12,
  INSANITY       = 13,
  ARCANE_CHARGES = 16,
  FURY           = 17,
  PAIN           = 18,

  -- In InitializeColors() power types in foreign languages added here.
  -- This is so CheckPredictedSpells() can find the power names in the tooltips
  -- string = number.
}

local ConvertPowerTypeHAP = {
  MANA           = 0,
  RAGE           = 1,
  FOCUS          = 2,
  ENERGY         = 3,
  RUNIC_POWER    = 6,
  LUNAR_POWER    = 8,
  MAELSTROM      = 11,
  INSANITY       = 13,
  FURY           = 17,
  PAIN           = 18,

  -- In InitializeColors() power types in foreign languages added here.
  -- This is so CheckPredictedSpells() can find the power names in the tooltips
  -- string = number.
}

local ConvertCombatColor = {
  Hostile = 1, Attack = 2, Flagged = 3, Friendly = 4,
}

DUB.FocusHealth.BarVisible  = function() return HasFocus end
DUB.FocusPower.BarVisible   = function() return HasFocus end
DUB.PetHealth.BarVisible    = function() return HasPet end
DUB.PetPower.BarVisible     = function() return HasPet and UnitPowerMax('pet', UnitPowerType('pet')) ~= 0 end
DUB.ComboBar.BarVisible     = function() return PlayerClass == 'ROGUE' or
                                                (PlayerClass == 'DRUID' and PlayerStance == CatForm) end

-- Share with the whole addon.
Main.LSM = LSM
Main.ConvertPowerType = ConvertPowerType
Main.ConvertPowerTypeHAP = ConvertPowerTypeHAP
Main.ConvertCombatColor = ConvertCombatColor
Main.Talents = Talents
Main.UnitBarsF = UnitBarsF
Main.UnitBarsFE = UnitBarsFE
Main.APBBuffTimerMoverEnabled = false
Main.APBMoverEnabled = false
Main.EABMoverEnabled = false

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

      if strfind(BarType, 'Health') then
        UBFTable.IsHealth = true
      elseif BarType ~= 'AltPowerBar' and strfind(BarType, 'Power') then
        UBFTable.IsPower = true
      end

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
-- EventType    Type of events to register.
-------------------------------------------------------------------------------
local function RegisterEvents(Action, EventType)

  if EventType == 'main' then

    -- Register events for the addon.
    Main:RegEvent(true, 'UNIT_ENTERED_VEHICLE',          GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_EXITED_VEHICLE',           GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_DISPLAYPOWER',             GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_MAXPOWER',                 GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_POWER_BAR_SHOW',           GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_POWER_BAR_HIDE',           GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'UNIT_PET',                      GUB.UnitBarsUpdateStatus, 'player')
    Main:RegEvent(true, 'PET_UI_UPDATE',                 GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'UNIT_FACTION',                  GUB.UnitBarsUpdateStatus)
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
    Main:RegEvent(true, 'ZONE_CHANGED_NEW_AREA',         GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'ZONE_CHANGED',                  GUB.UnitBarsUpdateStatus)
    Main:RegEvent(true, 'ZONE_CHANGED_INDOORS',          GUB.UnitBarsUpdateStatus)

    -- Rest of the events are defined at the end of each lua file for the bars.
  elseif EventType == 'casttracker' then
    local Flag = Action == 'register'

    -- Register events for cast tracking.
    Main:RegEvent(Flag, 'UNIT_SPELLCAST_START',       GUB.TrackCast, 'player')
    Main:RegEvent(Flag, 'UNIT_SPELLCAST_SUCCEEDED',   GUB.TrackCast, 'player')
    Main:RegEvent(Flag, 'UNIT_SPELLCAST_STOP',        GUB.TrackCast, 'player')
    Main:RegEvent(Flag, 'UNIT_SPELLCAST_FAILED',      GUB.TrackCast, 'player')
    Main:RegEvent(Flag, 'UNIT_SPELLCAST_INTERRUPTED', GUB.TrackCast, 'player')
    Main:RegEvent(Flag, 'UNIT_SPELLCAST_DELAYED',     GUB.TrackCast, 'player')

  elseif EventType == 'predictedspells' then
    local Flag = Action == 'register'

    -- register events for predicted spell tracking.
    Main:RegEvent(Flag, 'UNIT_AURA',                GUB.CheckPredictedSpells, 'player')
    Main:RegEvent(Flag, 'SPELLS_CHANGED',           GUB.CheckPredictedSpells)
    Main:RegEvent(Flag, 'PLAYER_EQUIPMENT_CHANGED', GUB.CheckPredictedSpells)
  end
end

-------------------------------------------------------------------------------
-- InitializeColors
--
-- Copy blizzard's power bar colors and class colors into the Defaults profile.
-------------------------------------------------------------------------------
local function InitializeColors()
  local ConvertPowerTypeL = {}
  local ConvertPowerTypeHAPL = {}

  -- Copy the power colors.
  -- Add foreign language or english to ConvertPowerTypeHAP
  for PowerType, Value in pairs(ConvertPowerTypeHAP) do
    local Color = PowerBarColor[Value]
    local r, g, b = Color.r, Color.g, Color.b
    local PowerTypeL = _G[PowerType]

    DUB.PowerColor = DUB.PowerColor or {}
    DUB.PowerColor[Value] = {r = r, g = g, b = b, a = 1}

    if PowerTypeL then
      ConvertPowerTypeHAPL[strupper(PowerTypeL)] = Value
    end
    ConvertPowerTypeHAPL[PowerType] = Value
  end
  ConvertPowerTypeHAP = ConvertPowerTypeHAPL

  -- Copy the class colors.
  for Class, Color in pairs(RAID_CLASS_COLORS) do
    local r, g, b = Color.r, Color.g, Color.b

    DUB.ClassColor = DUB.ClassColor or {}
    DUB.ClassColor[Class] = {r = r, g = g, b = b, a = 1}
  end

  -- Add foreign language or english to ConvertPowerType
  for PowerType, Value in pairs(ConvertPowerType) do
    local PowerTypeL = _G[PowerType]

    if PowerTypeL then
      ConvertPowerTypeL[strupper(PowerTypeL)] = Value
    end
    ConvertPowerTypeL[PowerType] = Value
  end
  ConvertPowerType = ConvertPowerTypeL
end

--*****************************************************************************
--
-- Unitbar utility (APB and EAB)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- APBStopMoving
--
-- Stops moving the alternate power bars
-------------------------------------------------------------------------------
local function APBStopMoving(Frame)
  if Frame == APBMover then
    UnitBars.APBPos = { Frame:GetPoint() }
  else
    UnitBars.APBTimerPos = { Frame:GetPoint() }
  end
  Frame:StopMovingOrSizing()
end

-------------------------------------------------------------------------------
-- APBSetMover
--
-- Turns moving on or off for both Alternate Power Bars
--
-- Type : 'apb' and 'timer'. or nil for both
-------------------------------------------------------------------------------
function GUB.Main:APBSetMover(Type)
  local Hide = false
  if UnitBars.APBMoverOptionsDisabled then
    Hide = true
  end

  if Type == nil or Type == 'apb' then
    if not Hide and Main.APBMoverEnabled then
      APBMover:Show()
    else
      APBMover:Hide()
    end
  end
  if Type == nil or Type == 'timer' then
    if not Hide and Main.APBBuffTimerMoverEnabled then
      APBBuffTimerMover:Show()
    else
      APBBuffTimerMover:Hide()
    end
  end
end

-------------------------------------------------------------------------------
-- APBReset
--
-- Reset the alternate power bar movers to default position
-------------------------------------------------------------------------------
function GUB.Main:APBReset()
  APBMover:ClearAllPoints()
  APBMover:SetPoint('CENTER', 0, 0)

  APBBuffTimerMover:ClearAllPoints()
  APBBuffTimerMover:SetPoint('CENTER', 0, -75)

  UnitBars.APBPos = {'CENTER', 0, 0}
  UnitBars.APBTimerPos = {'CENTER', 0, -75}

  Main:DoBlizzAltPowerBar()
end

-------------------------------------------------------------------------------
-- InitAltPowerBar
--
-- This sets up the blizzard alternate power bar for hiding/showing/moving
-------------------------------------------------------------------------------
local function InitAltPowerBar()
  local APBPos = UnitBars.APBPos
  local APBTimerPos = UnitBars.APBTimerPos

  APBMover = CreateFrame('Frame', nil, UIParent)
  APBMover:SetSize(75, 50)
  APBMover:SetMovable(true)
  APBMover:SetBackdrop(SelectFrameBorder)
  APBMover:SetScript('OnMouseDown', APBMover.StartMoving)
  APBMover:SetScript('OnMouseUp', APBStopMoving)
  APBMover:SetFrameStrata('HIGH')
  APBMover:SetClampedToScreen(true)

  local FontString = APBMover:CreateFontString(nil)
  FontString:SetAllPoints()
  FontString:SetFont([[Fonts\FRIZQT__.TTF]], 13, 'THICKOUTLINE')
  FontString:SetJustifyH('CENTER')
  FontString:SetJustifyV('MIDDLE')
  FontString:SetText('APB')

  APBMover:ClearAllPoints()
  if next(APBPos) == nil then
    APBMover:SetPoint('CENTER', 0, 0)
  else
    APBMover:SetPoint(unpack(APBPos))
  end

  APBBuffTimerMover = CreateFrame('Frame', nil, UIParent)
  APBBuffTimerMover:SetPoint('CENTER')
  APBBuffTimerMover:SetSize(250, 75)
  APBBuffTimerMover:SetMovable(true)
  APBBuffTimerMover:SetBackdrop(SelectFrameBorder)
  APBBuffTimerMover:SetScript('OnMouseDown', APBBuffTimerMover.StartMoving)
  APBBuffTimerMover:SetScript('OnMouseUp', APBStopMoving)
  APBBuffTimerMover:SetFrameStrata('HIGH')
  APBBuffTimerMover:SetClampedToScreen(true)

  local FontString = APBBuffTimerMover:CreateFontString(nil)
  FontString:SetAllPoints()
  FontString:SetFont([[Fonts\FRIZQT__.TTF]], 13, 'THICKOUTLINE')
  FontString:SetJustifyH('CENTER')
  FontString:SetJustifyV('MIDDLE')
  FontString:SetText('TIMER')

  APBBuffTimerMover:ClearAllPoints()
  if next(APBTimerPos) == nil then
    APBBuffTimerMover:SetPoint('CENTER', 0, -75)
  else
    APBBuffTimerMover:SetPoint(unpack(APBTimerPos))
  end

  -- Hook secure func for alt power bars
  hooksecurefunc('PlayerBuffTimerManager_UpdateTimers', function()
    if not InCombatLockdown() then
      Main.DoBlizzAltPowerBar()
    end
  end)

  -- This is used to make sure the power bar can be repositioned after reload UI
  hooksecurefunc('UIParent_ManageFramePositions', function()
    if not InCombatLockdown() then

      local APBMoverOptionsDisabled = UnitBars.APBMoverOptionsDisabled
      PlayerPowerBarAlt:SetMovable(true)
      PlayerPowerBarAlt:SetUserPlaced(not APBMoverOptionsDisabled)

      if not APBMoverOptionsDisabled then
        PlayerPowerBarAlt:ClearAllPoints()
        PlayerPowerBarAlt:SetPoint('CENTER', APBMover, 'CENTER')
      end
    end
  end)

  Main:APBSetMover()
end

-------------------------------------------------------------------------------
-- DoBlizzAltPowerBar
--
-- Hides and shows the blizzard alt power bar and BuffTimer frame
-- And positions them if moving is enable
--
-- Blizzard code will not modify the positon of the alt power bar when
-- SetUserPlaced is set to true
-- This also hides things like the darkmoon faire timers
--
-- NOTES: This function is also called when PlayerBuffTimerManager_UpdateTimers()
--        is called. This secure function call is done in InitAltPowerBar()
-------------------------------------------------------------------------------
function GUB.Main:DoBlizzAltPowerBar()
  local BuffTimer = nil
  local APBMoverOptionsDisabled = UnitBars.APBMoverOptionsDisabled
  BlizzAltPowerVisible = not UnitBars.AltPowerBar.Enabled or APBUseBlizz[AltPowerBarID] or false

  -- Look for bufftimers for darkmoon fair or similar
  for TimerIndex = 1, 10 do
    BuffTimer = _G[format('BuffTimer%s', TimerIndex)]

    if BuffTimer then
      if BuffTimer:IsVisible() then
        break
      else
        -- Clear points incase mover is disabled
        BuffTimer:ClearAllPoints()
      end
    end
  end

  -- Need to do SetMovable otherwise SetUserPlaced causes an error
  PlayerPowerBarAlt:SetMovable(true)

  if not BlizzAltPowerVisible then -- hide
    PlayerPowerBarAlt:SetUserPlaced(false)
    PlayerPowerBarAlt:Hide()

    if BuffTimer then
      BuffTimer:Hide()
      BuffTimer:ClearAllPoints()
    end
  else -- show
    PlayerPowerBarAlt:SetUserPlaced(not APBMoverOptionsDisabled)

    if not APBMoverOptionsDisabled then
      PlayerPowerBarAlt:ClearAllPoints()
      PlayerPowerBarAlt:SetPoint('CENTER', APBMover, 'CENTER')

      if BuffTimer then
        BuffTimer:ClearAllPoints()
        BuffTimer:SetPoint('CENTER', APBBuffTimerMover, 'CENTER')
      end
    end
  end
end

-------------------------------------------------------------------------------
-- EABReset
--
-- Reset the extra action button to default position
-------------------------------------------------------------------------------
function GUB.Main:EABReset()
  EABMover:ClearAllPoints()
  EABMover:SetPoint('CENTER', 0, -150)

  UnitBars.EABPos = {'CENTER', 0, -150}

  Main:DoBlizzAltPowerBar()
end

-------------------------------------------------------------------------------
-- InitExtraActionButton
--
-- This sets up the extra action button for hiding/showing/moving
-------------------------------------------------------------------------------
local function InitExtraActionButton()
  local EABPos = UnitBars.EABPos

  EABMover = CreateFrame('Frame', nil, UIParent)
  EABMover:SetSize(ExtraActionButton1:GetSize())
  EABMover:SetMovable(true)
  EABMover:SetBackdrop(SelectFrameBorder)
  EABMover:SetScript('OnMouseDown', EABMover.StartMoving)
  EABMover:SetScript('OnMouseUp', function()
    UnitBars.EABPos = { EABMover:GetPoint() }
    EABMover:StopMovingOrSizing()
  end)
  EABMover:SetFrameStrata('HIGH')
  EABMover:SetClampedToScreen(true)

  local FontString = EABMover:CreateFontString(nil)
  FontString:SetAllPoints()
  FontString:SetFont([[Fonts\FRIZQT__.TTF]], 13, 'THICKOUTLINE')
  FontString:SetJustifyH('CENTER')
  FontString:SetJustifyV('MIDDLE')
  FontString:SetText('EAB')

  -- Hook secure func for extra action button
  hooksecurefunc('UIParent_ManageFramePositions', function()
    if not InCombatLockdown() then
      Main.DoExtraActionButton()
    end
  end)

  if next(EABPos) == nil then
    EABMover:SetPoint(ExtraActionButton1:GetPoint())
  else
    EABMover:SetPoint(unpack(EABPos))
  end
  Main:DoExtraActionButton()
end

-------------------------------------------------------------------------------
-- DoExtraActionButton
--
-- Hides and shows the blizzard extra action button frame
-- And positions them if moving is enable
-------------------------------------------------------------------------------
function GUB.Main:DoExtraActionButton()
  if not UnitBars.EABMoverOptionsDisabled then
    if Main.EABMoverEnabled then
      EABMover:Show()
    else
      EABMover:Hide()
    end
    ExtraActionButton1:ClearAllPoints()
    ExtraActionButton1:SetPoint('CENTER', EABMover, 'CENTER')
  else
    EABMover:Hide()
  end
end

--*****************************************************************************
--
-- Unitbar utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- HideWowFrame
--
-- Hides different frames in the game.
--
-- Ussage: HideWowFrame(FrameName, Flag)
--
-- FrameName   Name of frame.
--               'player' - Player frame
--               'target' - Target frame
--
-- Flag        true hides the frame otherwise false
--
-- NOTES:  Can have more than one FrameName, Flag pair
--------------------------------------------------------------------------------
function GUB.Main:HideWowFrame(...)
  for FrameIndex = 1, select('#', ...), 2 do
    local FrameName, Hide = select(FrameIndex, ...)
    local Frame = nil

    if FrameName == 'player' then
      Frame = PlayerFrame
    elseif FrameName == 'target' then
      -- Don't show the target player frame if there is no target.
      if Hide or not Hide and HasTarget then
        Frame = TargetFrame
      end
    end
    if Frame then
      if Hide then
        Frame:Hide()
      else
        Frame:Show()
      end
    end
  end
end

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
--
-- Notes:  To access the "Frame" from the calling function "Fn" use self.Frame
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
-- RegUnitEvent
--
-- Works like RegisterUnitEvent, except it can take more than 2 units.
--
-- Usage: RegUnitEvent(true, Event, Fn, Units)
--        RegUnitEvent(false, Event, Fn)
--
-- Reg      If true then event gets registered otherwise unregistered.
-- Event    Event to register
-- Fn       Function to call when event fires
--
-- Units    1 or more units. Must have at least one unit.
--          If units is nil, then it will register the event with
--          all the existing units.
-------------------------------------------------------------------------------
local function RegUnitEvent(Reg, Event, Fn, ...)

  local SubFrames = RegUnitEventFrames[Fn]

  if Reg then
    -- Create sub frames for units.
    if SubFrames == nil then
      SubFrames = {}
      RegUnitEventFrames[Fn] = SubFrames
    end

    -- Register events
    for Index = 1, select('#', ...) do
      local Unit = select(Index, ...)
      local Frame = SubFrames[Unit]

      if Frame == nil then
        Frame = CreateFrame('Frame')
        SubFrames[Unit] = Frame
      end
      Frame:RegisterUnitEvent(Event, Unit)
      Frame:SetScript('OnEvent', Fn)
    end

  elseif SubFrames then
    for Unit, Frame in pairs(SubFrames) do
      Frame:UnregisterEvent(Event)
    end
  end
end

-------------------------------------------------------------------------------
-- CreateScanTooltip
--
-- Creates the ScanTooltip upvalue
-------------------------------------------------------------------------------
local function CreateScanTooltip()
  if ScanTooltip == nil then
    ScanTooltip = CreateFrame('GameTooltip')

    ScanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
    for Index = 1, 8 do
       local Left = ScanTooltip:CreateFontString()
       local Right = ScanTooltip:CreateFontString()
       ScanTooltip['L' .. Index] = Left
       ScanTooltip['R' .. Index] = Right

       ScanTooltip:AddFontStrings(Left, Right)
    end
  end
end

-------------------------------------------------------------------------------
-- GetTooltip
--
-- Returns the tooltip for a given spellID
--
-- SpellID    Tooltip returned for this spell
--
-- Returns
--    Reference to ScanTooltip
-------------------------------------------------------------------------------
function GUB.Main:GetTooltip(SpellID)
  CreateScanTooltip()
  ScanTooltip:ClearLines()
  ScanTooltip:SetHyperlink(format('spell:%s', SpellID))

  return ScanTooltip
end

-------------------------------------------------------------------------------
-- GetTaggedColor (also used by triggers)
--
-- Returns the tagged color of a unit
--
-- Unit         Unit that may be tagged.
-- p2 .. p4     Dummy pars, not used
-- r, g, b, a   If there is no tagged color, then these values get passed back
--
-- Returns:
--   r, g, b, a     Power color
-------------------------------------------------------------------------------
function GUB.Main:GetTaggedColor(Unit, p2, p3, p4, r, g, b, a)
  Unit = Unit or ''

  if UnitBars.TaggedTest or UnitExists(Unit) and not UnitPlayerControlled(Unit) and UnitIsTapDenied(Unit) then
    local Color = UnitBars.TaggedColor

    return Color.r, Color.g, Color.b, Color.a
  else
    return r, g, b, a
  end
end
local GetTaggedColor = Main.GetTaggedColor

-------------------------------------------------------------------------------
-- GetPowerColor (also used by triggers)
--
-- Returns the power color of a unit
--
-- Unit         Unit whos power color to be retrieved
-- PowerType    Powertype of the unit. If nil uses the current power type of the unit.
-- p3 .. p4     Dummy pars, not used
-- r, g, b, a   If there is no power color, then these values get passed back
--
-- Returns:
--   r, g, b, a     Power color
-------------------------------------------------------------------------------
function GUB.Main:GetPowerColor(Unit, PowerType, p3, p4, r, g, b, a)
  local Color = nil

  Unit = Unit or ''
  if UnitExists(Unit) then
    PowerType = PowerType or UnitPowerType(Unit)
    Color = UnitBars.PowerColor[PowerType] or nil
  end

  if Color then
    return Color.r, Color.g, Color.b, Color.a
  else
    return r, g, b, a
  end
end

-------------------------------------------------------------------------------
-- GetClassColor (also used by triggers)
--
-- Returns the class color of a unit
--
-- Unit     Unit whos class color to be retrieved
-- p2 .. p4     Dummy pars, not used
-- r, g, b, a   If there is no class color, then these values get passed back
--
-- Returns:
--   r, g, b, a     Class color
-------------------------------------------------------------------------------
function GUB.Main:GetClassColor(Unit, p2, p3, p4, r, g, b, a)
  Unit = Unit or ''
  if UnitExists(Unit) then
    local ClassColor = UnitBars.ClassColor
    local _, Class = UnitClass(Unit)

    if Class then
      local c = UnitBars.ClassColor[Class]
      r, g, b, a = c.r, c.g, c.b, c.a
    end

    if UnitBars.ClassTaggedColor then
      return GetTaggedColor(nil, Unit, p2, p3, p4, r, g, b, a)
    end
  end

  return r, g, b, a
end
local GetClassColor = Main.GetClassColor

-------------------------------------------------------------------------------
-- GetCombatColor (also used by triggers)
--
-- Returns the combat state color of a target vs you.
--
-- Unit             Unit who you want to check the combat state of
-- p2 .. p4         Dummy pars, not used
-- r1, g1, b1, a1   If there is no combat color, then these values get passed back
--
-- Returns:
--   r, g, b, a   Combat color
-------------------------------------------------------------------------------
function GUB.Main:GetCombatColor(Unit, p2, p3, p4, r1, g1, b1, a1)
  local r, g, b, a = 1, 1, 1, 1
  local Color = nil

  Unit = Unit or ''
  if UnitExists(Unit) then
    if UnitPlayerControlled(Unit) then
      local PlayerCombatColor = UnitBars.PlayerCombatColor
      -- Check player characters first

      if UnitCanAttack(Unit, 'player') then
        -- Hostile
        if UnitBars.CombatClassColor then
          return GetClassColor(nil, Unit, p2, p3, p4, r1, g1, b1, a1)
        else
          Color = PlayerCombatColor.Hostile
          return Color.r, Color.g, Color.b, Color.a
        end
      end
      if UnitCanAttack('player', Unit) then
        -- can be attacked, but can't attack you
        if UnitBars.CombatClassColor then
          return GetClassColor(nil, Unit, p2, p3, p4, r1, g1, b1, a1)
        else
          Color = PlayerCombatColor.Attack
          return Color.r, Color.g, Color.b, Color.a
        end
      end
      if UnitIsPVP(Unit) then
        -- Player is flagged for pvp
        Color = PlayerCombatColor.Flagged
        return Color.r, Color.g, Color.b, Color.a
      end
      -- Player is a friendly
      Color = PlayerCombatColor.Friendly
      return Color.r, Color.g, Color.b, Color.a
    else
      -- NPCs
      local CombatColor = UnitBars.CombatColor
      local Reaction = UnitReaction(Unit, 'player')

      -- If reaction returns nil then return white
      if Reaction == nil then
        Color = {r = 1, g = 1, b = 1, a = 1}

      elseif Reaction == 4 then -- yellow
        -- Unit can be attacked, but cant attack you
        Color = CombatColor.Attack

      elseif Reaction < 4 then -- red
        -- Hostile
        Color = CombatColor.Hostile

      elseif Reaction > 4 then -- green
        -- Friendly
        Color = CombatColor.Friendly
      end

      if UnitBars.CombatTaggedColor then
        return GetTaggedColor(nil, Unit, p2, p3, p4, Color.r, Color.g, Color.b, Color.a)
      else
        return Color.r, Color.g, Color.b, Color.a
      end
    end
  end

  return r1, g1, b1, a1
end

-------------------------------------------------------------------------------
-- ShowMessage
--
-- Displays a message on the screen in a box, with an Okay button.
--
-- Width        Width or box, if nil uses default
-- Height       Height of box, if nil uses default
-- Font         Type of font, if nil uses default
-- FontSize     Size of font, if nil uses default.
-------------------------------------------------------------------------------
function GUB.Main:MessageBox(Message, Width, Height, Font, FontSize)
  Width = Width or 600
  Height = Height or 310

  if MessageBox == nil then
    MessageBox = CreateFrame('Frame', nil, UIParent)
    MessageBox:SetSize(Width, Height)
    MessageBox:SetPoint('CENTER')
    MessageBox:SetBackdrop(DialogBorder)
    MessageBox:SetMovable(true)
    MessageBox:EnableKeyboard(true)
    MessageBox:SetToplevel(true)
    MessageBox:SetClampedToScreen(true)
    MessageBox:SetScript('OnMouseDown', MessageBox.StartMoving)
    MessageBox:SetScript('OnMouseUp', MessageBox.StopMovingOrSizing)
    MessageBox:SetScript('OnHide', MessageBox.StopMovingOrSizing)
    MessageBox:SetFrameStrata('TOOLTIP')

    -- Create the scroll frame.
    -- This is a window that shows a smaller part of the contentframe.
    local ScrollFrame = CreateFrame('ScrollFrame', nil, MessageBox)
    ScrollFrame:SetPoint('TOPLEFT', 15, -15)
    ScrollFrame:SetPoint('BOTTOMRIGHT', -30, 44)
    MessageBox.ScrollFrame = ScrollFrame

    -- Create the contents that will be viewed thru the ScrollFrame.
    local ContentFrame = CreateFrame('Frame', nil, ScrollFrame)
      MessageBox.ContentFrame = ContentFrame

      local FontString = ContentFrame:CreateFontString(nil)
      FontString:SetAllPoints()
      FontString:SetFont(LSM:Fetch('font', Font or 'Arial Narrow'), FontSize or 13, 'NONE')
      FontString:SetJustifyH('LEFT')
      FontString:SetJustifyV('TOP')
      MessageBox.FontString = FontString

    ScrollFrame:SetScrollChild(ContentFrame)

    -- Create the scroller that appears on the message box.
    local Scroller = CreateFrame('slider', nil, ScrollFrame, 'UIPanelScrollBarTemplate')
    Scroller:SetPoint('TOPRIGHT', MessageBox, -8, -25)
    Scroller:SetPoint('BOTTOMRIGHT', MessageBox, -8, 25)
    MessageBox.Scroller = Scroller

    -- Create the dark background for the Scroller
    local ScrollerBG = Scroller:CreateTexture(nil, 'BACKGROUND')
    ScrollerBG:SetAllPoints()
    ScrollerBG:SetTexture(0, 0, 0, 0.4)
    Scroller.ScrollerBG = ScrollerBG

    -- Create the ok button to close the message box
    local OkButton =  CreateFrame('Button', nil, MessageBox, 'UIPanelButtonTemplate')
    OkButton:SetScale(1.25)
    OkButton:SetSize(50, 20)
    OkButton:ClearAllPoints()
    OkButton:SetPoint('BOTTOMLEFT', 10, 10)
    OkButton:SetScript('OnClick', function()
                                    PlaySound(SoundKit.IG_MAINMENU_OPTION_CHECKBOX_ON)
                                    MessageBox:Hide()
                                  end)
    OkButton:SetText('Okay')
    MessageBox.OkButton = OkButton

    -- Add scroll wheel
    MessageBox:SetScript('OnMouseWheel', function(self, Dir)
                                           local Scroller = self.Scroller

                                           Scroller:SetValue(Scroller:GetValue() + ( 17 * Dir * -1))
                                         end)
    -- esc key to close
    MessageBox:SetScript('OnKeyDown', function(self, Key)
                                        if Key == 'ESCAPE' then
                                          PlaySound(SoundKit.IG_MAINMENU_OPTION_CHECKBOX_ON)
                                          MessageBox:Hide()
                                        end
                                      end)
  end

  -- Set the size of the content frame based on text
  local FontString = MessageBox.FontString
  local ContentFrame = MessageBox.ContentFrame
  ContentFrame:SetSize(Width - 45, 1000)

  FontString:SetText("Galvin's Unit Bars\n\n" .. '|cffffff00This list can be viewed under Help -> Changes|r' .. '\n\n' .. Message .. '\n')

  local Height = FontString:GetStringHeight()
  local Scroller = MessageBox.Scroller

  Scroller:SetMinMaxValues(1, Height - 40)
  Scroller:SetValueStep(1)
  Scroller:SetValue(0)
  Scroller:SetWidth(16)

  MessageBox:Show()
end

-------------------------------------------------------------------------------
-- Contains
--
-- Returns the key of the item being searched for.
--
-- Table    Can be any table, wont search sub tables
-- Value    Search for value
--
-- Returns nil if not found
-------------------------------------------------------------------------------
local function Contains(Table, Value)
  for k, v in pairs(Table) do
    if v == Value then
      return k
    end
  end
end

-------------------------------------------------------------------------------
-- StringSplit
--
-- Splits and trims a string and returns it as paramaters. Removes any extra spaces.
--
-- Sep       Separator
-- St        String to split
--
-- Returns:
--   ...     Multiple strings
-------------------------------------------------------------------------------
local function SplitString(Sep, St)
  local Part = nil

  if St == nil then
    St = ''
  end

  Part, St = strsplit(Sep, St, 2)
  Part = strtrim(Part)
  if St then
    if Part ~= '' then
      return Part, SplitString(Sep, St)
    else
      return SplitString(Sep, St)
    end
  elseif Part ~= '' then
    return Part
  end
end

function GUB.Main:StringSplit(Sep, St)
  return SplitString(Sep, St)
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
--     copy           Copy a value from Source to Dest. Keys is the name of the value being copied.
--     move           Move a value from source to Dest. Keys is the name of the value being moved.
--     movetable      Move a sub table from Source to Dest.  Keys is the subtable.
--     custom         Calls ConvertCustom to make changes.
--
--   Source           Table to look in.  If not specified then uses the root of the table.
--   Dest             Table to look in.  If not specified then uses the root of the table.
--
--   []               Array of Keys.  Keys are searched for inside of source.
--     Key            If action is movetable then the key is the sub table to move.
--                    The key only needs to partially match the key found in unitbars[BarType]
--                    A key can have three different prefixes:
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
--        When a table is empty cause everything was removed or moved out of it'll then be deleted.
-------------------------------------------------------------------------------
local function ConvertCustom(Ver, BarType, SourceUB, DestUB, SourceKey, DestKey, KeyFound)
  if Ver < 3 then
    if BarType == 'RuneBar' then

      -- Convert RuneBarOrder to BoxOrder, then delete RuneBarOrder
      if SourceKey == 'RuneBarOrder' then
        local BoxOrder = DestUB.BoxOrder

        -- Make BoxOrder here so conversion doesn't bug out in some way.
        -- Boxorder will get removed after all the conversions are complete.
        if BoxOrder == nil then
          BoxOrder = {1, 2, 5, 6, 3, 4}
          DestUB.BoxOrder = BoxOrder
        end

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
    if SourceKey == 'Text' then
      local Text = SourceUB.Text
      for Index = 1, #Text do
        local TS = Text[Index]
        local ValueName = TS.ValueName or TS.ValueNames
        local ValueType = TS.ValueType or TS.ValueTypes

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
  elseif Ver == 3 then
    if SourceKey == 'Triggers' then -- triggers
      local Triggers = SourceUB.Triggers

      for Index, Trigger in ipairs(SourceUB.Triggers) do

        -- Convert auras to the new format.
        local Auras = Trigger.Auras
        if Auras then
          for _, Aura in pairs(Auras) do
            local Units = Aura.Units
            local St = 'player'

            if Units then
              -- Convert table into a string
              St = ''
              for Unit in pairs(Units) do
                St = St .. Unit .. ' '
              end
              if St == '' then
                St = 'player'
              end
            end
            -- Remove table and add unit
            Aura.Units = nil
            Aura.Unit = strtrim(St)

            -- Convert cast by player
            if Aura.CastByPlayer then
              Aura.Own = Aura.CastByPlayer
              Aura.CastByPlayer = nil
            else
              Aura.Own = false
            end
            -- Convert StackCondition in to StackOperator
            Aura.StackOperator = Aura.StackCondition or '>='
            Aura.StackCondition = nil
          end

          if Trigger.Condition ~= 'static' then
            Trigger.AuraOperator = Trigger.Condition
          else
            Trigger.AuraOperator = 'or'
          end
        else
          Trigger.AuraOperator = 'or'
        end
        -- Convert static to new format.
        local Condition = Trigger.Condition or '>'
        local Value = Trigger.Value

        if Condition == 'static' then
          Trigger.Static = true
          Condition = '>'
        else
          Trigger.Static = false
          if Condition == 'or' or Condition == 'and' then
            Condition = '>'
          end
        end
        -- Convert boolean to state
        if Trigger.ValueTypeID == 'boolean' then
          Trigger.State = tonumber(Value) == 1
          Condition = '>'
          Value = 0
        else
          Trigger.State = true
        end
        local Pars = Trigger.Pars
        local GetPars = Trigger.GetPars

        if Pars == nil then
          Pars = {}
          Trigger.Pars = Pars
        end
        if GetPars == nil then
          GetPars = {}
          Trigger.GetPars = GetPars
        end

        -- Convert GetPars and Pars empty strings to nil
        for Index = 1, 4 do
          local Par = Pars[Index]
          local GetPar = GetPars[Index]

          if type(Par) == 'string' then
            Par = strtrim(Par)
            if Par == '' then
              Par = nil
            end
          end
          if type(GetPar) == 'string' then
            GetPar = strtrim(GetPar)
            if GetPar == '' then
              GetPar = nil
            end
          end
          Pars[Index] = Par
          GetPars[Index] = GetPar
        end

        Trigger.Action = {Type = 1}

        -- Convert Condition in to Conditions
        Trigger.Conditions = { All = false, {Operator = Condition, Value = Value} }
        Trigger.Condition = nil
        Trigger.Value = nil
      end

      -- Remove action.
      Triggers.Action = nil
    end
  elseif Ver == 4 then
    if SourceKey == 'Triggers' then -- triggers
      local Triggers = SourceUB.Triggers

      for Index, Trigger in ipairs(SourceUB.Triggers) do

        -- Convert texture size to texture scale.
        if Trigger.TypeID == 'texturesize' then
          Trigger.TypeID = 'texturescale'
        end
        if Trigger.Type == 'texture size' then
          Trigger.Type = 'texture scale'
        end

        -- add default for bar offsets
        Trigger.OffsetAll = true
      end
    end
  elseif Ver == 5 then
    if SourceKey == 'Triggers' then -- triggers
      local Triggers = SourceUB.Triggers

      for Index, Trigger in ipairs(SourceUB.Triggers) do

        -- Remove Mimimize key
        Trigger.Minimize = nil
      end
    end
  elseif Ver == 6 then
    if BarType == 'RuneBar' then
      if SourceKey == 'BoxOrder' then
        SourceUB.BoxOrder = nil
      elseif SourceKey == 'Text' then
        local Text = SourceUB.Text

        -- remove color 7 and 8
        Text[1].Color[7] = nil
        Text[1].Color[8] = nil
      end

    -- move trigger groups over by one that start from 5+
    elseif BarType == 'ShardBar' and SourceKey == 'Triggers' then
      local Triggers = SourceUB.Triggers

      for Index, Trigger in ipairs(SourceUB.Triggers) do
        local GroupNumber = Trigger.GroupNumber

        if GroupNumber >= 5 then
          Trigger.GroupNumber = GroupNumber + 1
        end
      end
    end

    -- Convert value name Predicted to PredictedHealth or PredictedPower
    if SourceKey == 'Text' then
      local Text = SourceUB.Text
      local Hap = strfind(BarType, 'Health') ~= nil or strfind(BarType, 'Power') ~= nil
      local Health = strfind(BarType, 'Health') ~= nil

      for Index = 1, #Text do
        local TS = Text[Index]
        local ValueName = TS.ValueName or TS.ValueNames
        local ValueType = TS.ValueType or TS.ValueTypes

        for ValueIndex = 1, #ValueName do
          local VName = ValueName[ValueIndex]

          if Hap then
            if VName == 'predicted' then
              if Health then
                VName = 'predictedhealth'
              else
                VName = 'predictedpower'
              end
            end
            ValueName[ValueIndex] = VName
          end
        end
      end
    end
  elseif Ver == 7 then
    -- Convert ValueName and ValueType to plural
    if SourceKey == 'Text' then
      local Text = SourceUB.Text
      local DubText = DUB[BarType].Text

      for Index = 1, #Text do
        local TS = Text[Index]
        local DubTS = DubText[Index]
        local ValueName = TS.ValueName
        local ValueType = TS.ValueType

        if ValueName then
          TS.ValueNames = {}
          TS.ValueTypes = {}

          Main:CopyTableValues(TS.ValueName, TS.ValueNames, true)
          Main:CopyTableValues(TS.ValueType, TS.ValueTypes, true)

          -- Since the defaults was changed to ValueNames and ValueTypes
          -- A nil has to be filled in for the first index.
          if TS.ValueNames[1] == nil then
            TS.ValueNames[1] = DubTS.ValueNames[1]
          end
          if TS.ValueTypes[1] == nil then
            TS.ValueTypes[1] = DubTS.ValueTypes[1]
          end

          TS.ValueName = nil
          TS.ValueType = nil
        end
      end
    end
  elseif Ver == 8 then
    -- Convert SmoothFill into SmoothFillMaxTime
    if SourceKey == 'SmoothFill' then
      local SmoothFill = SourceUB.SmoothFill

      SourceUB.SmoothFillMaxTime = SmoothFill and SmoothFill or 0
    end
  elseif Ver == 10 then
    if SourceKey == 'Triggers' then -- triggers
      local Triggers = SourceUB.Triggers

      for Index, Trigger in ipairs(SourceUB.Triggers) do
        Trigger.ClassName = nil
        Trigger.ClassSpecs = nil
      end
    end
  elseif Ver == 11 then
    local SUB = SourceUB[KeyFound]
    if type(SUB) == 'table' then
      local RotateTexture = SUB.RotateTexture

      if type(RotateTexture) == 'boolean' then
        if RotateTexture then
          RotateTexture = 90
        else
          RotateTexture = 0
        end
        SUB.RotateTexture = RotateTexture
      end
    end
  end
end

local function ConvertUnitBarData(Ver)
  local KeysFound = {}
  local ConvertUBData = nil

  local ConvertUBData1 = {
    {Action = 'custom',                                                 'RuneBarOrder', 'RuneLocation'},
    {Action = 'custom',    Source = 'General', Dest = 'Layout',         'RuneSize', 'IndicatorHideShow', 'RuneMode', 'EnergizeShow'},

    {Action = 'remove',    Source = 'General',                          'Scale'},
    {Action = 'move',      Source = 'General', Dest = 'General',        'CooldownBarDrawEdge:BarSpark'},
    {Action = 'copy',      Source = 'General', Dest = 'Layout',         'BoxMode:HideRegion'},
    {Action = 'move',      Source = 'General', Dest = 'Layout',         'BoxMode', 'Size:TextureScale', 'Padding', '=!BarMode:Float',
                                                                        'RuneSwap:Swap', 'Angle:Rotation', 'FadeInTime', 'FadeOutTime'},

    {Action = 'move',      Source = 'Bar',     Dest = 'Layout',         'ReverseFill'},

    {Action = 'move',      Source = 'Bar',     Dest = 'Bar',            '=ComboWidth:Width', '=ComboHeight:Height',
                                                                        '=RuneWidth:Width', '=RuneHeight:Height',
                                                                        '=HapWidth:Width', '=HapHeight:Height'},
    {Action = 'move',      Source = 'Bar',     Dest = 'Bar',            '=BoxWidth:Width', '=BoxHeight:Height'},
    {Action = 'move',      Source = 'Bar',     Dest = 'Bar.Color',      'ClassColor:Class'},

    {Action = 'custom',    Source = '',                                 '=Text'},
  }

  local ConvertUBData2 = {
    {Action = 'movetable', Source = 'Region.BackdropSettings',         Dest = 'Region',              'Padding'},
    {Action = 'movetable', Source = 'Background.BackdropSettings',     Dest = 'Background',          'Padding'},

    {Action = 'move', Source = 'Region.BackdropSettings',              Dest = 'Region',              'BgTexture', 'BdTexture:BorderTexture',
                                                                                                     '=BgTile', 'BgTileSize', 'BdSize:BorderSize'},
    {Action = 'move', Source = 'Background.BackdropSettings',          Dest = 'Background',          'BgTexture', 'BdTexture:BorderTexture',
                                                                                                     '=BgTile', 'BgTileSize', 'BdSize:BorderSize'},
  }

  local ConvertUBData345 = {
    {Action = 'custom',    Source = '',                                 '=Triggers'},
  }

  local ConvertUBData6 = {
    {Action = 'custom',    Source = '',                                 '=BoxOrder', '=Text', '=Triggers'},
  }

  local ConvertUBData7 = {
    {Action = 'custom',    Source = '',                                 '=Text'},
  }
  local ConvertUBData8 = {
    {Action = 'custom',    Source = 'Layout',                           '=SmoothFill'},
  }
  local ConvertUBData9 = {
    {Action = 'movetable', Source = '',                                 Dest = '',                 '=Other:Attributes'},
    {Action = 'movetable', Source = 'General',                          Dest = 'Layout',           'ColorEnergize'},
    {Action = 'move',      Source = 'General',                          Dest = 'Layout',           'BarSpark', 'ClassColor', 'CombatColor',
                                                                                                   'CooldownAnimation', 'CooldownLine',
                                                                                                   'EnergizeShow', 'EnergizeTime', '!HideCooldownFlash:CooldownFlash',
                                                                                                   'InactiveAnticipationAlpha', 'PredictedCost',
                                                                                                   'PredictedHealth', 'PredictedPower', 'RuneMode',
                                                                                                   'RuneOffsetX', 'RuneOffsetY', 'RunePosition',
                                                                                                   'TaggedColor', 'TextureScaleAnticipation',
                                                                                                   'TextureScaleCombo', 'UseBarColor' },
  }
  local ConvertUBData10 = {
    {Action = 'custom',    Source = '',                                 '=Triggers'},
    {Action = 'copy',      Source = 'Status', Dest = 'ClassSpecs',      '!HideNotUsable:All'},
  }
  local ConvertUBData11 = {
    {Action = 'custom',    Source = '',                                 'Bar'},
  }

  if Ver == 1 then -- First time conversion
    ConvertUBData = ConvertUBData1

    local AlignmentToolEnabled = UnitBars.AlignmentToolEnabled
    if AlignmentToolEnabled ~= nil then
      UnitBars.AlignAndSwapEnabled = AlignmentToolEnabled
      UnitBars.AlignmentToolEnabled = nil
    end
  elseif Ver == 2 then -- For version 210 or lower.
    ConvertUBData = ConvertUBData2
  elseif Ver == 3 or Ver == 4 or Ver == 5 then -- 3 = 350, 4 = 4.01, 4 = 4.10
    ConvertUBData = ConvertUBData345
  elseif Ver == 6 then
    ConvertUBData = ConvertUBData6
  elseif Ver == 7 then
    ConvertUBData = ConvertUBData7
  elseif Ver == 8 then
    ConvertUBData = ConvertUBData8
  elseif Ver == 9 then
    ConvertUBData = ConvertUBData9
  elseif Ver == 10 then
    ConvertUBData = ConvertUBData10
  elseif Ver == 11 then
    ConvertUBData = ConvertUBData11
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
              -- Check to see if the source key exists in the defaults.
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
              local ReturnOK, Msg = pcall(ConvertCustom, Ver, BarType, SourceUB, DestUB, SourceKey, DestKey, KeyFound)

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
              Main:DelUB(BarType, SourceTable)
            end
          end
        end
      end
    end
  end
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
-- SetAnchorPoint
--
-- Usage: SetAnchorPoint(Anchor)
--          Recalculates the anchor point at its new screen location.
--        SetAnchorPoint(Anchor, 'UB')
--          Use the anchor at the unitbar x,y value.
--        SetAnchorPoint(Anchor, x, y)
--          Moves the anchor position on its current point or a new point.
-------------------------------------------------------------------------------
function GUB.Main:SetAnchorPoint(Anchor, x, y)
  local UB = Anchor.UnitBar
  local AnchorPointFrame = Anchor.AnchorPointFrame

  if x == nil then
    x, y = Bar:GetRect(Anchor)
  elseif x == 'UB' then
    x, y = UB.x, UB.y
  end

  Anchor:ClearAllPoints()
  Anchor:SetPoint('TOPLEFT', x, y)

  if not Anchor.IsScaling then
    AnchorPointFrame:ClearAllPoints()
    AnchorPointFrame:SetPoint(UB.Attributes.AnchorPoint)
  end

  UB.x, UB.y = x, y
end

-------------------------------------------------------------------------------
-- SetAnchorSize
--
-- Sets the width and height for a unitbar.
--
-- Usage:  SetAnchorSize('reset')
--           Resets the size of all anchors and anchorpointframes.
--         SetAnchorSize(Anchor, Width, Height) or
--         SetAnchorSize(Anchor, Width, Height, OffsetX, OffsetY)
--
-- Width       Set width of the unitbar. if Width is nil then current width is used.
-- Height      Set height of the unitbar.
--
-- OffsetX
-- OffsetY     Internal use, used by floating mode BBar:Display()
--             This changes the size of the frame without moving the objects inside
--             of it.
--
-- NOTE:  This accounts for scale.  Width and Height must be unscaled when passed.
--        When using OffsetX and Y.
-------------------------------------------------------------------------------
function GUB.Main:SetAnchorSize(Anchor, Width, Height, OffsetX, OffsetY)
  local AnchorPointFrame = Anchor.AnchorPointFrame

  -- Reset size
  if Anchor == 'reset' then
    for _, UBF in pairs(UnitBarsF) do
      local Anchor = UBF.Anchor

      if Anchor then
        local AnchorPointFrame = UBF.AnchorPointFrame

        Anchor._Width = nil
        Anchor._Height = nil
        AnchorPointFrame._Width = nil
        AnchorPointFrame._Height = nil
      end
    end
    return
  end

  -- Get Unitbar data and anchor
  local UB = Anchor.UnitBar
  local Scale = UB.Attributes.Scale

  if Width then
    Anchor._Width = Width
    Anchor._Height = Height
  else
    Width = Anchor._Width or 0.1
    Height = Anchor._Height or 0.1
  end

  -- Need to scale width and height since size is based on ScaleFrame.
  Width = Width * Scale
  Height = Height * Scale

  if Anchor._Width then
    local APWidth = AnchorPointFrame._Width
    local APHeight = AnchorPointFrame._Height

    if APWidth then
      if Width ~= APWidth or Height ~= APHeight then
        local DiffX = Width - APWidth
        local DiffY = Height - APHeight
        local AnchorPoint = UB.Attributes.AnchorPoint

        --If offsetting then fake TOPLEFT
        if OffsetX then
          AnchorPoint = 'TOPLEFT'
        end

        local Offset = AnchorOffset[AnchorPoint]

        AnchorPointFrame._Width = Width
        AnchorPointFrame._Height = Height

        UB.x = UB.x + DiffX * Offset.x + (OffsetX or 0) * Scale
        UB.y = UB.y + DiffY * Offset.y + (OffsetY or 0) * Scale
      end
    else
      AnchorPointFrame._Width = Width
      AnchorPointFrame._Height = Height
    end
  end

  Anchor:SetSize(Width, Height)
  AnchorPointFrame:SetSize(Width, Height)

  Main:SetAnchorPoint(Anchor, UB.x, UB.y)

  -- Update alignment if alignswap is open
  if Options.AlignSwapOptionsOpen then
    Main:SetUnitBarsAlignSwap()
  end
end

-------------------------------------------------------------------------------
-- SetTimer
--
-- Will call a function based on a delay.
--
-- To start a timer
--   usage: SetTimer(Table, TimerFn, Delay, Wait)
-- To stop a timer
--   usage: SetTimer(Table, nil)
--
-- Table    Must be a table.
-- TimerFn  Function to be added. If nil then the timer will be stopped.
-- Delay    Amount of time to delay after each call to Fn(). First call happens after Delay seconds.
-- Wait     Amount of time to wait before starting to Delay. After Wait time has elapsed TimerFn will
--          be called once, then Delay seconds later and so on TimerFn will be called.
--          if 0 or less than 0. TimerFn will be called instantly.  If nil then Delay takes over.
--
--
-- NOTE:  TimerFn will be called as TimerFn(Table) from AnimationGroup in StartTimer()
--
--        To reduce garbage.  Only a new StartTimer() will get created when a new table is passed.
--
--        The function that gets called has the following passed to it:
--          Table      Table that was created with the timer.
--
--        You'll get unpredictable results if the timer is changed without stopping it first.
---------------------------------------------------------------------------------
function GUB.Main:SetTimer(Table, TimerFn, Delay, Wait)
  local AnimationGroup = nil
  local Animation = nil

  local SetTimer = Table._SetTimer
  if SetTimer == nil then

    -- SetTimer
    function SetTimer(Start, TimerFn2, Delay2, Wait)

      -- Create an animation Group timer if one doesn't exist.
      if AnimationGroup == nil then

        -- Create OnLoop function
        if Table._OnLoop == nil then
          Table._OnLoop = function()
            TimerFn(Table)
          end
        end

        AnimationGroup = CreateFrame('Frame'):CreateAnimationGroup()
        Animation = AnimationGroup:CreateAnimation('Animation')
        Animation:SetOrder(1)
        AnimationGroup:SetLooping('REPEAT')
      end
      if Start then
        TimerFn = TimerFn2
        if Wait and Wait > 0 then
          local WaitTimer = Table._WaitTimer
          if WaitTimer == nil then

            -- WaitTimer
            function WaitTimer()
              TimerFn(Table)
              AnimationGroup:Stop()
              Animation:SetDuration(Delay)
              AnimationGroup:SetScript('OnLoop', Table._OnLoop)
              AnimationGroup:Play()
            end

            Table._WaitTimer = WaitTimer
          end
          Delay = Delay2
          Animation:SetDuration(Wait)
          AnimationGroup:SetScript('OnLoop', WaitTimer)
          AnimationGroup:Play()
        else
          if Wait and Wait == 0 then
            TimerFn(Table)
          end
          Animation:SetDuration(Delay2)
          AnimationGroup:SetScript('OnLoop', Table._OnLoop)
          AnimationGroup:Play()
        end
      else
        AnimationGroup:Stop()
      end
    end

    Table._SetTimer = SetTimer
  end

  if TimerFn then

    -- Start timer since a function was passed
    SetTimer(true, TimerFn, Delay, Wait)
  else

    -- Stop timer since no function was passed.
    SetTimer(false)
  end
end

-------------------------------------------------------------------------------
-- CheckAura
--
-- Checks to see if one or more auras are active
--
-- Operator     - 'a' and.
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
function GUB.Main:CheckAura(Operator, ...)
  local Name = nil
  local SpellID = 0
  local MaxSpellID = select('#', ...)
  local Found = 0
  local AuraIndex = 1

  repeat
    local Name, _, Stacks, _, _, ExpiresIn, _, _, _, SpellID = UnitAura('player', AuraIndex)
    if Name then

      -- Search for the aura against the list of auras passed.
      for i = 1, MaxSpellID do
        if SpellID == select(i, ...) then
          Found = Found + 1
          break
        end
      end

      -- When using the 'o' option then return on the first found aura.
      if Operator == 'o' and Found > 0 then
        if ExpiresIn == 0 then
          return SpellID, -1, Stacks
        else
          return SpellID, ExpiresIn - GetTime(), Stacks
        end
      end
    end
    AuraIndex = AuraIndex + 1
  until Name == nil or Found == MaxSpellID
  if Operator == 'a' then
    return Found == MaxSpellID
  end
end

-------------------------------------------------------------------------------
-- SetCastTracker
--
-- Calls a function when a cast has begun and ended.
--
-- Usage:   SetCastTracker(UnitBarF, 'fn', Fn)
--          SetCastTracker(UnitBarF, 'off')
--          SetCastTracker(UnitBarF, 'register' or 'unregister')
--          SetCastTracker('reset')
--
-- UnitBarF    The bar thats tracking spell casting.
-- 'fn'        This sets up a function to call and starts tracking casts.
-- Fn          The function to call when a cast is being made.
--               Fn will get called with the following
--                 UnitBarF  -  The bar thats tracking casts.
--                 SpellID   -  Spell being cast.
--                 Message   -  Message  -- See TrackCast() for details.
--                                'start'   - Cast begun.
--                                'stop'    - Cast was stopped.
--                                'failed'  - Cast failed to go off.
--                                'done'    - Cast successful.
--                                'timeout' - Something went wrong and cast got timed out. Due to lag maybe.
--                                'enable'  - Cast tracking got enabled.  No SpellID with this message
--                                'disable' - Cast tracking got disabled. No SpellID with this message.
-- 'off'       Turn off cast tracking.
-- unregister  Disabled cast tracking.
-- register    Enables cast tracking.
-- 'reset'     Turn off all cast tracking
-------------------------------------------------------------------------------
function GUB.Main:SetCastTracker(UnitBarF, Action, Fn)
  if UnitBarF == 'reset' then
    CastTrackers = nil
    CastTracking = nil
  else
    local CastTracker = CastTrackers and CastTrackers[UnitBarF]

    -- Turn cast tracking on and set Fn
    if Action == 'fn' then
      if CastTrackers == nil then
        CastTrackers = {}
      end

      if CastTracker == nil then
        CastTracker = {Enabled = true}
        CastTrackers[UnitBarF] = CastTracker
      end

      if CastTracking == nil then
        CastTracking = {SpellID =0, CastID = ''}
      end

      CastTracker.Fn = Fn

    -- Turn off cast tracking for this bar
    elseif CastTracker then
      if Action == 'off' then
        CastTrackers[UnitBarF] = nil

      -- track events on or off.
      elseif Action == 'register' or Action == 'unregister' then
        CastTracker.Enabled = Action == 'register'
      end
    end
  end

  RegisterEvents('unregister', 'casttracker')

  if CastTrackers then
    for UBF, CastTracker in pairs(CastTrackers) do
      if CastTracker.Enabled then
        RegisterEvents('register', 'casttracker')
        break
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetAuraTracker
--
-- Adds or removes units to track auras on.
-- unregister or registers aura tracking or resets it.
--
-- Usage: SetAuraTracker(Object, 'fn', Fn)
--        SetAuraTracker(Object, 'off')
--        SetAuraTracker(Object, 'units', Units)
--        SetAuraTracker(Object, 'unregister' or 'register')
--        SetAuraTracker('reset')
--
-- Object         The table, string, etc to assign the aura tracker to.
-- Fn             Turns on aura tracking and calls Fn when auras change.
--                Function to call for this unitbar.
--                  Fn gets called with (TrackedAurasList) from AuraUpdate()
-- 'off'          Turns off all auratracking for this bar
-- Units          List of units to add.  If nil then units are removed for this bar.
-- 'reset'        Clears all units and turns off all events for all bars.
-------------------------------------------------------------------------------
local function EventUpdateAura(self, Event, Unit)
  Main:AuraUpdate()
end

function GUB.Main:SetAuraTracker(Object, Action, ...)
  local RefreshAuraList = false

  if Object == 'reset' then
    TrackedAuras = nil
    TrackedAurasList = nil
  else
    local TrackedAura = TrackedAuras and TrackedAuras[Object]

    -- Turn aura tracking on and set Fn
    if Action == 'fn' then
      if TrackedAuras == nil then
        TrackedAuras = {}
      end

      if TrackedAura == nil then
        TrackedAura = {Enabled = true}
        TrackedAuras[Object] = TrackedAura
      end

      TrackedAura.Fn = ...
      return

    -- Turn off aura tracking for this object
    elseif TrackedAuras and Action == 'off' then
      TrackedAuras[Object] = nil
      RefreshAuraList = true
    end

    -- Register or unregister.
    if TrackedAura and (Action == 'register' or Action == 'unregister') then
      TrackedAura.Enabled = Action == 'register'

    elseif Action == 'units' then
      RefreshAuraList = true
      if TrackedAurasList == nil then
        TrackedAurasList = {All = {} }
      end

      -- Add units to the object
      local Units = {}
      TrackedAura.Units = Units

      if ... then
        for Index = 1, select('#', ...) do
          local Unit = select(Index, ...)

          if Unit ~= 'All' then
            Units[Unit] = 1
          end
        end
      end
    end
    if RefreshAuraList and TrackedAurasList then
      local AllUnits = {}

      for _, TrackedAura in pairs(TrackedAuras) do
        local Units = TrackedAura.Units

        if Units then
          for Unit in pairs(Units) do
            AllUnits[Unit] = 1
            if TrackedAurasList[Unit] == nil then
              TrackedAurasList[Unit] = {}
            end
          end
        end
      end

      for Unit in pairs(TrackedAurasList) do
        if Unit ~= 'All' then
          if AllUnits[Unit] == nil then
            TrackedAurasList[Unit] = nil
          end
        end
      end
    end
  end

  RegUnitEvent(false, 'UNIT_AURA', EventUpdateAura)

  local EventRegistered = false

  -- Only register events if the tracked auras list table is not empty.
  if TrackedAurasList and TrackedAuras and next(TrackedAuras) then

    -- Reg events for any enabled units.
    for Object, TrackedAura in pairs(TrackedAuras) do
      if TrackedAura.Enabled then
        local Units = TrackedAura.Units

        if Units then
          for _, Unit in pairs(Units) do
            RegUnitEvent(true, 'UNIT_AURA', EventUpdateAura, Unit)
            EventRegistered = true
          end
        end
      end
    end

    -- Refresh auras for anything listening to auras.
    if EventRegistered then
      Main:AuraUpdate()
    end
  end
  Main.TrackedAurasList = TrackedAurasList

  -- Update aura options
  if RefreshAuraList then
    Options:UpdateAuras()
  end
end

-------------------------------------------------------------------------------
-- GetPredictedSpell
--
-- Returns the amount of power that a predicted spell currently has otherise 0
--
-- UnitBarF   The bar thats using predicted spells
-- SpellID    Spell whos power you're getting
-------------------------------------------------------------------------------
function GUB.Main:GetPredictedSpell(UnitBarF, SpellID)
  if PredictedSpells and PredictedSpells[UnitBarF] then

    -- Check the spell book if it hasn't been checked
    if PredictedSpells.SpellBook == nil then
      GUB:CheckPredictedSpells()
    end

    local SpellInfo = PredictedSpells[SpellID]

    if SpellInfo then
      return SpellInfo.Amount, SpellInfo.PowerType
    else
      return 0, 0
    end
  else
    return 0, 0
  end
end

-------------------------------------------------------------------------------
-- SetPredictedSpells
--
-- Finds spells in the players spellbook with cast times that return a primary resource.
--
-- Usage: SetPredictedSpells(UnitBarF, 'on', [ fn ])
--        SetPredictedSpells(UnitBarF, 'off')
--        SetPredictedSpells('reset')
--
-- UnitBarF     The bar thats using predicted spells
-- 'on'         Predicted spells will start getting tracked.
-- fn           Optional. Each time the amount of predicted power changes this will get called.
--                        fn() will get called with the following:
--                           UnitBarF     Bar thats spell tracking
--                           SpellID      Spell that was found.
--                           Amount       New amount.
--              for each predicted spell.
-- 'off'        Predicted spells will stop getting tracked.
-- 'reset'      Turn off all predicted spell tracking.

-- NOTES:  This doesn't have an unregister or register option.  The
--         Tracker needs to run all the time even out of combat to detect spellbook changes.
-------------------------------------------------------------------------------
function GUB.Main:SetPredictedSpells(UnitBarF, Action, Fn)
  if UnitBarF == 'reset' then
    PredictedSpells = nil
  else
    local PredictedSpell = PredictedSpells and PredictedSpells[UnitBarF]

    -- Turn on predicted spells
    if Action == 'on' then
      if PredictedSpells == nil then
        PredictedSpells = {}
      end

      if PredictedSpell == nil then
        PredictedSpell = {}
        PredictedSpells[UnitBarF] = PredictedSpell
      end

      if Fn then
        PredictedSpell.Fn = Fn
      end

    -- Turn off predicted spells for this bar
    elseif PredictedSpell then
      if Action == 'off' then
        PredictedSpells[UnitBarF] = nil
      end
    end
  end

  RegisterEvents('unregister', 'predictedspells')

  if PredictedSpells then
    for UnitBarF, PredictedSpell in pairs(PredictedSpells) do
      if type(UnitBarF) ~= 'number' then
        RegisterEvents('register', 'predictedspells')
        break
      end
    end
  end
end

-------------------------------------------------------------------------------
-- GetTalents
--
-- Stores which talents are active. Also contains pulldown menu data for options.
--
-- NOTES: PvP talent table
--   enabled            - Enable or disable talents. True if enabled.
--
-- Talents data structure:
--   Talents.Active[Talent Name]   Talent Name is a string, if not nil then talent is in use
--   Talents.PvE                   Array showing all the available talents for PvE
--     Dropdown                    Dropdown menu used by options
--     IconDropdown                Same as dropdown with icons
--   Talents.PvP                   Same as above except for PvP
-------------------------------------------------------------------------------
function GUB.Main:GetTalents()
  local Active = Talents.Active
  local AllTalentIDs = nil -- To handle repeats for PvP talents

  if Active == nil then
    Active = {}
    Talents.Active = Active
    Talents.PvE = {}
    Talents.PvP = {}
  end
  wipe(Active)

  for Key in pairs(Talents) do
    if Key ~= 'Active' then
      local DropdownIndex = 0
      local DropdownDefined = true

      local Dropdowns = Talents[Key]
      local Dropdown = Dropdowns.Dropdown
      local IconDropdown = Dropdowns

      if Dropdown == nil then
        Dropdown = {}
        IconDropdown = {}
        Dropdowns.Dropdown = Dropdown
        Dropdowns.IconDropdown = IconDropdown

        DropdownDefined = false
        AllTalentIDs = {}
      end

      -- Get PvE talents
      if Key == 'PvE' then
        DropdownIndex = 0
        for Tier = 1, 10 do
          for Column = 1, 3 do
            local _, Name, Icon, Selected, _, _, _, _, _, _, Known  = GetTalentInfo(Tier, Column, 1)

            if Name then
              if Selected or Known then
                Active[Name] = true
              end
              if not DropdownDefined then
                DropdownIndex = DropdownIndex + 1
                Dropdown[DropdownIndex] = Name
                IconDropdown[DropdownIndex] = format('|T%s:0|t %s', Icon, Name)
              end
            end
          end
        end
      else
        -- Get PvP talents
        DropdownIndex = 0
        for SlotIndex = 1, 4 do
          -- Sometimes this returns, nil so need to check it. Why does blizzard do stuff like this.
          local SlotInfo = C_SpecializationInfoGetPvpTalentSlotInfo(SlotIndex)

          if SlotInfo then
            local TalentID = SlotInfo.selectedTalentID
            local TalentIDs = SlotInfo.availableTalentIDs

            if TalentID then
              local _, Name = GetPvpTalentInfoByID(TalentID)

              Active[Name] = true
            end

            if not DropdownDefined then
              for PvPIndex = 1, #TalentIDs do
                TalentID = TalentIDs[PvPIndex]

                -- Only add if its a new talent
                if AllTalentIDs[TalentID] == nil then
                  DropdownIndex = DropdownIndex + 1

                  AllTalentIDs[TalentID] = true
                  local _, Name, Icon = GetPvpTalentInfoByID(TalentID)

                  Dropdown[DropdownIndex] = Name
                  IconDropdown[DropdownIndex] = format('|T%s:0|t %s', Icon, Name)
                end
              end
            end
          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- PrintRaw()
--
-- Shows all escapes codes in a string.
-------------------------------------------------------------------------------
function GUB.Main:PrintRaw(Text)
  print(gsub(Text, '|', '||'))
end

-------------------------------------------------------------------------------
-- ListTable()
--
-- Like table.foreach except shows the details of all sub tables.
-------------------------------------------------------------------------------
function GUB.Main:ListTable(Table, Path, Exclude)
  local kst = nil
  if Path == nil then
    Path = '.'
  end

  -- Exclude will prevent tables from causing an infinite loop
  if Exclude == nil then
    Exclude = {}
  else
    Exclude[Table] = true
  end

  for k, v in pairs(Table) do
    if type(k) == 'table' then
      kst = tostring(k)
    else
      kst = k
    end

    if type(v) == 'table' then
      local Recursive = Exclude[v]

      print(Path .. '.' .. kst .. ' = ', v, (Recursive == true and '(recursive)' or ''))

      -- Only call if the table hasn't been seen before.
      if Recursive ~= true then
        Main:ListTable(v, Path .. '.' .. kst, Exclude)
      end
    else
      if type(k) == 'table' or type(k) == 'function' then
        local _, Address = strsplit(' ', tostring(k), 2)

        print(Path .. '.' .. Address .. ' = ', v)

      elseif type(v) == 'boolean' then
        print(Path .. '.' .. kst .. ' = ', format('boolean: %s', tostring(v)))
      else
        print(Path .. '.' .. kst .. ' = ', v)
      end
    end
  end

  -- Remove table from Exclude
  Exclude[Table] = nil
end

-------------------------------------------------------------------------------
-- Check
--
-- Checks if the tablepath leads to data in a table.
-- If the check fails false is returned otherwise true.
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
-- BarType      Type of bar to search.
-- TablePath    String delimited by a '.'  Example 'table.1' = table[1] or 'table.subtable' = table['subtable']
-- Table        If not nil then this table will be searched instead.  Must have a unitbar table format.
--
-- Returns:
--   Value        Table or value returned
--   DC           If true then a _DC tag was found. _DC tag is only searched in default unitbars.
--
-- Notes:  If nil is found at anytime then a nil is returned.
--         If TablePath is '' or nil then UnitBars[BarType] is returned.
--         If '#' is at the end then then an array has to be found.  If found then
--         The array table is returned.  If the array is empty then a nil value is returned.
-------------------------------------------------------------------------------
function GUB.Main:GetUB(BarType, TablePath, Table)
  local Value = Table and Table[BarType] or UnitBars[BarType]
  local DUBValue = DUB[BarType]
  local DC = false
  local Key = nil
  local Array = nil

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

      -- Check if theres array elements
      elseif TablePath == '#' then
        TablePath = nil
        if #Value == 0 then
          Value = nil
        end
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
--               table address intact.
-- Array         If not nil then will copy Array index from source only. Sub tables
--               dont need to be array indexes only.
--
-- NOTES: Types need to match, so the source found has to have the same type
--        in the destination.
--        Any source keys that start with an '_' will not get copied.  Even if DC is true.
--        If DC is true the dest table gets emptied prior to copy. If DC is true and
--        Array is true then only the array part of the table gets emptied.
-------------------------------------------------------------------------------
local function CopyTable(Source, Dest, DC, Array)
  for k, v in pairs(Source) do
    local d = Dest[k]
    local ts = type(v)

    if (DC or ts == type(d)) and strsub(k, 1, 1) ~= '_' then
      if Array == nil or type(k) == 'number' then
        if ts == 'table' then
          if d == nil then
            d = {}
            Dest[k] = d
          end
          CopyTable(v, d, DC)
        else
          Dest[k] = v
          --print(k, '=', v)
        end
      end
    end
  end
end

function GUB.Main:CopyTableValues(Source, Dest, DC, Array)
  if DC then
    if Array == nil then

      -- Empty table for deep copy
      wipe(Dest)
    else
      -- Empty array indexes only
      for k in pairs(Dest) do
        if type(k) == 'number' then
          Dest[k] = nil
        end
      end
    end
  end
  CopyTable(Source, Dest, DC, Array)
end

-------------------------------------------------------------------------------
-- CopyMissingTableValues
--
-- Copies the values that exist in the source but do not exist in the destination.
-- Array indexes are skipped.
--
-- Source       The source table you're copying data from.
-- Dest         The destination table the data is being copied to.
-- Root         true or nil. Only copy missing values from the root of the table.  Dont
--              search sub tables to copy missing values.
-------------------------------------------------------------------------------
function GUB.Main:CopyMissingTableValues(Source, Dest, Root)
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
    elseif Root == nil and ts == 'table' then

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
-- Source            BarType
-- Dest              BarType
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
-- HideUnitBar
--
-- Usage: HideUnitBar(UnitBarF, HideBar)
--
-- UnitBarF       Unitbar frame to hide or show.
-- HideBar        Hide the bar if equal to true otherwise show.
-------------------------------------------------------------------------------
local function HideUnitBar(UnitBarF, HideBar)
  if HideBar ~= UnitBarF.Hidden then
    local BBar = UnitBarF.BBar

    if HideBar then

      -- Disable cast tracking if active
      Main:SetCastTracker(UnitBarF, 'unregister')

      -- Disable Aura tracking if active
      Main:SetAuraTracker(UnitBarF, 'unregister')

      BBar:PlayAnimationBar('out')
      BBar:SetAnimationBar('stopall')

      UnitBarF.Hidden = true
    else
      UnitBarF.Hidden = false

      -- Disable cast tracking if active
      Main:SetCastTracker(UnitBarF, 'register')

      -- Enable Aura tracking if active
      Main:SetAuraTracker(UnitBarF, 'register')

      BBar:PlayAnimationBar('in')
    end
  end
end

-------------------------------------------------------------------------------
-- CheckClassSpecs
--
-- Checks the class and or spec against a table. The spec must be supported by the
-- bar first.
--
-- BarType      The bar thats being checked
-- ClassSpecs   Table containing the class and specs
-- IsTriggers   Used by triggers
-- Returns true if the spec is found
--
-- NOTES:  This will remove entries in ClassSpecs if those are not found
--         in the bar.  This is so when triggers or flag options get copied
--         to a different bar, specs that matched on the old bar are removed
--         if they'll never match on the new bar
--
--   ClassSpecs                    A list of classes in uppercase.  Each class has an array where the index is the specialization
--                                 Example: ClassSpecs.WARRIOR[3] = true, warrior protection spec
--     Inverse                     Does the opposite.  So if you had Warrior arms.  Then inverse would mean everything thats
--                                 not arms or not a Warrior.
--     ClassName                   Current class selected in the Class Specialization options pull down.
--                                 and the value is true or false.
--     All                         if true matches all specs, ignores any class spec settings.
--
-------------------------------------------------------------------------------
function GUB.Main:CheckClassSpecs(BarType, ClassSpecs, IsTriggers)
  local Match = nil

  if IsTriggers then
    -- Only need to do this for triggers.
    -- Since specs in non triggers gets checked by
    -- FixUnitBars()
    local CSD = DUB[BarType].Triggers.Default.ClassSpecs
    Main:CopyMissingTableValues(CSD, ClassSpecs)

    for KeyName, ClassSpec in pairs(ClassSpecs) do
      local SpecD = CSD[KeyName]

      if SpecD ~= nil then
        if type(ClassSpec) == 'table' then
          for Index in pairs(ClassSpec) do

            -- Does the spec exist in defaults
            if SpecD[Index] == nil then
              ClassSpec[Index] = nil
            end
          end
        end
      else
        -- Remove keys not found in defaults
        ClassSpecs[KeyName] = nil
      end
    end
  end

  if not ClassSpecs.All then

    -- Check for spec match
    local ClassSpec = ClassSpecs[PlayerClass]
    Match = ClassSpec and ClassSpec[PlayerSpecialization] or false

    -- Check for inverse
    if ClassSpecs.Inverse then
      Match = not Match
    end
  else
    Match = true
  end

  return Match
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

  -- Need to check enabled here cause when a bar gets enabled its layout gets set.
  -- Causing this function to get called even if the bar is disabled.
  if UB.Enabled then
    local Status = UB.Status
    local Hide = false
    local ClassSpecEnabled = false

    ClassSpecEnabled = Main:CheckClassSpecs(self.BarType, UB.ClassSpecs)
    self.ClassSpecEnabled = ClassSpecEnabled

    if not ClassSpecEnabled then
      Hide = true

    -- Show bars if not locked or testing.
    elseif UnitBars.IsLocked or not UnitBars.Testing then

      -- Continue if show always is false.
      if not Status.ShowAlways then

        -- Check to see if the bar has an enable function and call it.
        local Fn = self.BarVisible
        if Fn then
          Hide = not Fn()
        end
        if not Hide then
          -- Hide if the HideWhenDead status is set.
          if IsDead and Status.HideWhenDead then
            Hide = true
          -- Hide if the player has no target.
          elseif not HasTarget and Status.HideNoTarget then
            Hide = true
          -- Hide if in a vehicle if the HideInVehicle status is set
          elseif InVehicle and Status.HideInVehicle then
            Hide = true
          -- Hide if in a pet battle and the HideInPetBattle status is set.
          elseif InPetBattle and Status.HideInPetBattle then
            Hide = true
          -- Get the idle status based on HideNotActive when not in combat.
          -- If the flag is not present then it defaults to false.
          elseif not InCombat and Status.HideNotActive then
            local IsActive = self.IsActive
            Hide = IsActive == false
            -- if not visible then set IsActive to watch for activity.
            if Hide then
              self.IsActive = 0
            end
          -- Hide if not in combat with the HideNoCombat status.
          elseif not InCombat and Status.HideNoCombat then
            Hide = true
          -- Hide if the blizzard alternate power bar is visible otherwise hide
          -- Hide if there is no active blizzard alternate power bar
          elseif Status.HideIfBlizzAltPowerVisible ~= nil then
            if not HasAltPower then
              Hide = true
            elseif Status.HideIfBlizzAltPowerVisible then
              if BlizzAltPowerVisible then
                Hide = true
              end
            end
          end
        end
      end
    end
    -- Hide/show the unitbar.

    HideUnitBar(self, Hide)
  end
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
-- MoveFrameGetNearestFrame (called by setscript)
--
-- Gets the closest frame to the one being moved.
--
-- Frames        List of boxframes or unitbar frames
--
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

local function MoveFrameGetNearestFrame(TrackingFrame)
  local Move = TrackingFrame.Move
  local Flags = Move.Flags
  local MoveFrame = Move.Frame
  local Swap = Flags.Swap
  local Float = Flags.Float
  local Align = Flags.Align

  if Float and (Align and not Swap or Swap and not Align) or not Float and Swap and not Align then
    local Type = TrackingFrame.Type
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
local function TrackMouse(TrackingFrame)
  local x, y = GetCursorPosition()

  if x ~= TrackingFrame.LastX or y ~= TrackingFrame.LastY then
    MoveFrameGetNearestFrame(TrackingFrame)
    TrackingFrame.LastX = x
    TrackingFrame.LastY = y
  end
end

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

  TrackingFrame.LastX = nil
  TrackingFrame.LastY = nil
  Main:SetTimer(TrackingFrame, TrackMouse, 0.10, 0)

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

  Main:SetTimer(TrackingFrame, nil)

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
        MoveFrame:SetPoint(MovePoint, MoveSelectFrame, MoveSelectPoint)
      end
    end
    if MoveSelectFrame == nil or not Flags.Swap and not Flags.Align then

      -- Place frame, doesn't matter if its the anchor frame or not.
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

        for Index = 1, NumAlignFrames do
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
-- TrackCast (called by event)
--
-- Used by SetCastTracker()
--
-- Calls Fn and sends a message when a cast starts or stops
-------------------------------------------------------------------------------
local function TrackCastSendMessage(Message)
  local Timeout = type(Message) == 'table'

  if CastTrackers then
    for UnitBarF, CastTracker in pairs(CastTrackers) do
      if CastTracker.Enabled then
        CastTracker.Fn(UnitBarF, CastTracking.SpellID, Timeout and 'timeout' or Message)
      end
    end
  end

  -- Stop timeout timer
  if Timeout then
    Main:SetTimer(CastTracking, nil)
  end
end

function GUB:TrackCast(Event, Unit, CastID, SpellID)
  local CastEvent = CastTrackerEvent[Event]

  if CastEvent then
    -- Start a new cast or delay the timeout on an existing cast.
    if CastEvent == EventCastStart  or CastEvent == EventCastDelayed then
      local _, _, _, StartTime, EndTime, _, _, _, SpellID = UnitCastingInfo('player')
      local Duration = (EndTime or 0) / 1000 - (StartTime or 0) / 1000

      if CastEvent == EventCastStart then
        CastTracking.SpellID = SpellID
        CastTracking.CastID = CastID

        TrackCastSendMessage('start')
      end

      -- Set timeout to 1 second after cast should end.
      Main:SetTimer(CastTracking, nil)
      Main:SetTimer(CastTracking, TrackCastSendMessage, Duration + 1)

    else
      local CastTrackingCastID = CastTracking.CastID

      if CastTrackingCastID == CastID or CastTrackingCastID == '' then

        -- Check for instant cast
        if CastTrackingCastID == '' then
          CastTracking.SpellID = SpellID
        end

        -- Stop timeout
        Main:SetTimer(CastTracking, nil)

        if CastEvent == EventCastSucceeded then
          TrackCastSendMessage('done')

        elseif CastEvent == EventCastStop then
          TrackCastSendMessage('stop')

        elseif CastEvent == EventCastFailed then
          TrackCastSendMessage('failed')
        end
        CastTracking.SpellID = 0
        CastTracking.CastID = ''
      end
    end
  end
end

-------------------------------------------------------------------------------
-- AuraUpdate (called by setscript)
--
-- Used by SetAuraTracker()
--
-- Gets called when ever an aura changes on a unit.
--
-- Object        If specified then uses TrackedAuras[Object]
--               If nil all objects get updated.
-------------------------------------------------------------------------------
local function OnUpdateAuraUpdate(self)
  local BarCount = self.BarCount
  local Object = self.Object

  if TrackedAuras then
    local TrackedAura = nil

    -- Find the next UnitBar
    Object, TrackedAura = next(TrackedAuras, Object)

    if Object then
      BarCount = BarCount + 1
      if TrackedAura.Enabled then
        TrackedAura.Fn(TrackedAurasList)
      end
    else
      BarCount = 0
    end
  end

  -- Check for end
  if TrackedAuras == nil or BarCount == self.BarStop then
    BarCount = 0
    Object = nil
    self.BarStop = 0
    self:SetScript('OnUpdate', nil)
  end

  self.BarCount = BarCount
  self.Object = Object
end

function GUB.Main:AuraUpdate(Object)
  if TrackedAuras and TrackedAurasList then
    local TrackedAura = nil
    local All = TrackedAurasList.All

    -- If Object is specified then just update the object instantly.
    if Object then
      TrackedAura = TrackedAuras[Object]

      -- Return no trackedaura found or not enabled
      if TrackedAura == nil or not TrackedAura.Enabled then
        return
      end
    end

    -- Reset source unit status
    for Unit, Auras in pairs(TrackedAurasList) do
      for SpellID, Aura in pairs(Auras) do
        Aura.Active = false
        Aura.Stacks = 0
      end
    end

    for Unit, Auras in pairs(TrackedAurasList) do
      local AuraIndex = 1

      repeat
        local Name, _, Stacks, _, _, _, UnitCaster, _, _, SpellID, _, _, _ = UnitAura(Unit, AuraIndex, 'HELPFUL')
        if Name == nil then
          Name, _, Stacks, _, _, _, UnitCaster, _, _, SpellID, _, _, _ = UnitAura(Unit, AuraIndex, 'HARMFUL')
        end
        if Name then
          local Aura = Auras[SpellID]

          if Aura == nil then
            Aura = {}
            Auras[SpellID] = Aura
            All[SpellID] = Aura
          end
          Aura.Active = true
          Aura.Stacks = Stacks or 0
          Aura.Own = UnitCaster == 'player'
          AuraIndex = AuraIndex + 1
        end
      until Name == nil
    end

    if Object then
      TrackedAura.Fn(TrackedAurasList)
    else
      if TrackedAurasOnUpdateFrame == nil then
        TrackedAurasOnUpdateFrame = CreateFrame('Frame')
        TrackedAurasOnUpdateFrame.Object = nil
        TrackedAurasOnUpdateFrame.BarCount = 0
        TrackedAurasOnUpdateFrame.BarStop = 0
      end
      local BarCount = TrackedAurasOnUpdateFrame.BarCount

      -- Check to see if an auraupdate onupdate is in progress.
      if BarCount > 0 then
        TrackedAurasOnUpdateFrame.BarStop = BarCount
      else
        -- Loop thru each bar one frame at a time to split the load.
        TrackedAurasOnUpdateFrame:SetScript('OnUpdate', OnUpdateAuraUpdate)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- CheckPredictedSpells (called by event)
--
-- Scans the spell book for predicted power
-------------------------------------------------------------------------------
function GUB:CheckPredictedSpells(Event)

  -- Create a tooltip scanner if one doesn't exist.
  CreateScanTooltip()

  if PredictedSpells.SpellBook == nil then
    PredictedSpells.SpellBook = 1
    Event = SpellBookChanged
  end

  -- Clear spells if the spellbook changes or event is nil.
  if Event == SpellBookChanged then
    for Index in pairs(PredictedSpells) do
      if type(Index) == 'number' then
        PredictedSpells[Index] = nil
      end
    end
  -- Scan spellbook if cache is empty.
  elseif PredictedSpells[-1] == nil then
    Event = SpellBookChanged
  end

  local SpellID = 0
  local SkillType = 0
  local BookIndex = 0

  -- Scan the spell book or used the cached spells.
  for Index = 1, 512 do
    if Event == SpellBookChanged or Event == nil then
      SkillType, SpellID = GetSpellBookItemInfo(Index, 'spell')

      -- Check for end of spell book
      if SpellID == nil then
        break
      end
    else
      SkillType = 'SPELL'
      SpellID = PredictedSpells[-Index]

      if SpellID == nil then
        break
      end
    end

    if SpellID and SkillType == 'SPELL' then
      local Name, _, _, CastTime = GetSpellInfo(SpellID)

      -- Only need spells that have cast time.
      -- Sometimes spells from the spell book don't exist. So check
      -- Name to be not nil
      if Name and CastTime > 0 then
        ScanTooltip:ClearLines()
        ScanTooltip:SetHyperlink(format('spell:%s', SpellID))

        for LineIndex = 2, ScanTooltip:NumLines() do
          local Text = strupper(ScanTooltip['L' .. LineIndex]:GetText())
          local StartPos = strfind(Text, '|CFFFFFFFF')

          if StartPos then
            -- Look for a number followed by the power name
            local Amount, PowerName = strmatch(strsub(Text, StartPos), '(%d+)([%a ]+)')

            if Amount then
              -- Check if the power name matches the player's powertype
              -- ConvertPowerType contains current language as well.
              local PowerType = ConvertPowerTypeHAP[strtrim(PowerName)]

              if PowerType then
                local SpellInfo = PredictedSpells[SpellID]
                Amount = tonumber(Amount)

                if SpellInfo == nil then
                  SpellInfo = {Amount = Amount, PowerType = PowerType}
                  PredictedSpells[SpellID] = SpellInfo

                  BookIndex = BookIndex - 1
                  PredictedSpells[BookIndex] = SpellID
                end

                if SpellInfo.Amount ~= Amount then

                  -- Only do a call back if Event is not nil
                  if Event then
                    for UnitBarF, PredictedSpell in pairs(PredictedSpells) do
                      if UnitBarF ~= 'SpellBook' and type(UnitBarF) ~= 'number' then
                        local Fn = PredictedSpell.Fn

                        if Fn then
                          Fn(UnitBarF, SpellID, Amount, PowerType)
                        end
                      end
                    end
                  end
                  PredictedSpells[SpellID].Amount = Amount
                end
              end
            end
          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- UnitBarsUpdateStatus
--
-- Event handler that hides/shows the unitbars based on their current settings.
-- This also updates all unitbars that are visible.
-------------------------------------------------------------------------------
function GUB:UnitBarsUpdateStatus(Event, Unit)
  InCombat = UnitAffectingCombat('player')
  InVehicle = UnitHasVehicleUI('player')
  InPetBattle = C_PetBattles.IsInBattle()
  IsDead = UnitIsDeadOrGhost('player')
  HasTarget = UnitExists('target')
  HasFocus = UnitExists('focus')
  HasPet = PetHasActionBar() or HasPetUI()
  BlizzAltPowerVisible = PlayerPowerBarAlt:IsVisible()
  PlayerStance = GetShapeshiftFormID()
  PlayerPowerType = UnitPowerType('player')
  PlayerSpecialization = GetSpecialization() or 0

  local AltPowerType, _, _, _, _, _, _, _, _, _, _, _, _, BarID = UnitAlternatePowerInfo('player')
  HasAltPower = AltPowerType ~= nil
  AltPowerBarID = BarID

  -- Save for alt bar history and hide blizz alt power bar
  if HasAltPower then
    APBUsed[BarID] = GetMinimapZoneText() or 'No Area'
    Main:DoBlizzAltPowerBar()
  end

  Main.InCombat = InCombat
  Main.IsDead = IsDead
  Main.HasTarget = HasTarget
  Main.HasAltPower = HasAltPower
  Main.PlayerPowerType = PlayerPowerType

  -- Check for talent changes
  Main:GetTalents()

  -- Alternate power bar options needs to be disabled when there is a bar active
  if Event == 'UNIT_POWER_BAR_SHOW' or Event == 'UNIT_POWER_BAR_HIDE' then
    Options:RefreshMainOptions()
  end

  -- Need to do this here since hiding targetframe at startup doesn't work.
  Main:UnitBarsSetAllOptions('frames')

  -- Call for a checktrigger change thru setattr if player specialization has changed.
  -- This is for triggers since specialization is supported now.
  local PlayerSpecializationChanged = Main.PlayerSpecialization ~= PlayerSpecialization

  Main.PlayerSpecializationChanged = PlayerSpecializationChanged
  Main.PlayerSpecialization = PlayerSpecialization

  -- Close options when in combat.
  if InCombat then
    local Closed = false

    if Options.AlignSwapOptionsOpen then
      Options:CloseAlignSwapOptions()
      Closed = true
    end
    if Options.MainOptionsOpen then
      Options:CloseMainOptions()
      Closed = true
    end
    if Closed then
      print(InCombatOptionsMessage)
    end
  end

  Main:AuraUpdate(AuraListName)

  for _, UBF in ipairs(UnitBarsFE) do
    if PlayerSpecializationChanged then
      UBF:SetAttr('Layout', 'EnableTriggers')
    end
    UBF:Update()
  end
  Main.PlayerSpecializationChanged = false
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
    Options:OpenAlignSwapOptions(Frame)  -- Frame is anchor
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
      if Options.AlignSwapOptionsOpen then
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

    -- Update bar location info in the alignswap options window.
    Options:RefreshAlignSwapOptions()
  else
    Main:MoveFrameSetAlignPadding(UnitBarsFE, UnitBars.AlignSwapPaddingX, UnitBars.AlignSwapPaddingY, UnitBars.AlignSwapOffsetX, UnitBars.AlignSwapOffsetY)
  end

  -- Make sure all frame locations are saved.
  for _, UBF in ipairs(UnitBarsFE) do
    Main:SetAnchorPoint(UBF.Anchor)
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
    if Options.AlignSwapOptionsOpen then
      Main:SetUnitBarsAlignSwap()
    else
      Main:SetAnchorPoint(Frame)
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
-- SetAnimationTypeUnitBar
--
-- Sets the animation for the bar based on animation settings in 'other'
--
-- UnitBarF    The Unitbar frame to change the type of.
-------------------------------------------------------------------------------
local function SetAnimationTypeUnitBar(UnitBarF)
  local UBO = UnitBarF.UnitBar.Attributes
  local BBar = UnitBarF.BBar

  -- Set animation type
  if UBO.MainAnimationType then
    BBar:SetAnimationBar(UnitBars.AnimationType)
  else
    BBar:SetAnimationBar(UBO.AnimationTypeBar)
  end
end

-------------------------------------------------------------------------------
-- UnitBarsSetAllOptions
--
-- Handles the settings that effect all the unitbars.
--
-- Activates the current settings in UnitBars.
--
-- If Action is 'frames' then it'll just do the frames options only
-- Otherwise it does both.
-------------------------------------------------------------------------------
function GUB.Main:UnitBarsSetAllOptions(Action)
  local ATOFrame = Options.ATOFrame
  local IsLocked = UnitBars.IsLocked
  local IsClamped = UnitBars.IsClamped
  local AnimationOutTime = UnitBars.AnimationOutTime
  local AnimationInTime = UnitBars.AnimationInTime

  local HidePlayerFrame = UnitBars.HidePlayerFrame
  local HideTargetFrame = UnitBars.HideTargetFrame

  if Action ~= 'frames' then
    -- Update text highlight only when options window is open
    if Options.MainOptionsOpen then
      Bar:SetHighlightFont('on', UnitBars.HideTextHighlight)
    end

    -- Update alignment tool status.
    if IsLocked or not UnitBars.AlignAndSwapEnabled then
      Options:CloseAlignSwapOptions()
    end

    -- Apply the settings.
    for _, UBF in ipairs(UnitBarsFE) do
      local BBar = UBF.BBar
      UBF:EnableMouseClicks(not IsLocked)
      UBF.Anchor:SetClampedToScreen(IsClamped)

      SetAnimationTypeUnitBar(UBF)
      BBar:SetAnimationDurationBar('out', AnimationOutTime)
      BBar:SetAnimationDurationBar('in', AnimationInTime)
    end

    -- Last Auras
    if UnitBars.AuraListOn then
      -- use a dummy function since nothing needs to be done.
      Main:SetAuraTracker(AuraListName, 'fn', function() end)
      Main:SetAuraTracker(AuraListName, 'units', Main:StringSplit(' ', UnitBars.AuraListUnits))
    else
      Main:SetAuraTracker(AuraListName, 'off')
    end
  end

  -- Frames
  if HidePlayerFrame ~= 0 then
    Main:HideWowFrame('player', HidePlayerFrame == 1)
  end
  if HideTargetFrame ~= 0 then
    Main:HideWowFrame('target', HideTargetFrame == 1)
  end
end

-------------------------------------------------------------------------------
-- UnitBarSetAttr
--
-- Base unitbar set attributes. Handles attributes that are shared across all bars.
--
-- Usage    UnitBarSetAttr(UnitBarF, Object, Attr)
--
-- UnitBarF    The Unitbar frame to work on.
-------------------------------------------------------------------------------
function GUB.Main:UnitBarSetAttr(UnitBarF)

  -- Get the unitbar data.
  local UBO = UnitBarF.UnitBar.Attributes
  local Alpha = UBO.Alpha
  local Anchor = UnitBarF.Anchor
  local BBar = UnitBarF.BBar

  -- Set animation type
  SetAnimationTypeUnitBar(UnitBarF)

  -- Scale.
  UnitBarF.ScaleFrame:SetScale(UBO.Scale)

  -- Alpha.
  UnitBarF.AlphaFrame:SetAlpha(Alpha or 1)

  -- Force anchor offset
  local Anchor = UnitBarF.Anchor

  -- Update the unitbar to the correct size based on scale.
  Main:SetAnchorSize(Anchor)

  -- Strata
  Anchor:SetFrameStrata(UBO.FrameStrata)
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
  local BBar = UnitBarF.BBar
  local Anchor = UnitBarF.Anchor

  -- Set a reference to UnitBar[BarType] for moving.
  -- This needs to be first incase animation functions need
  -- this reference.
  Anchor.UnitBar = UB

  -- Stop any old animation for this unitbar.
  BBar:SetAnimationBar('stopall')

  UnitBarF.IsActive = false
  UnitBarF.ClassSpecEnabled = false

  -- Hide the unitbar.
  UnitBarF.Hidden = true
  Anchor:Hide()

  -- Show the unitbar.  Then SetAttr and then hide.
  -- Weird things happen when the bar gets drawn when hidden.
  UnitBarF:SetAttr()
end

-------------------------------------------------------------------------------
-- CreateUnitBar
--
-- Creates a unitbar. If the UnitBar is already created this function does nothing.
--
-- UnitBarF    Subtable of UnitBarsF[BarType]
-- BarType     Type of bar.
--
-- Notes: Anchor size is left up to SetAttr()
-------------------------------------------------------------------------------
local function CreateUnitBar(UnitBarF, BarType)
  if UnitBarF.Created == nil then
    local UB = UnitBarF.UnitBar

    UnitBarF.Created = true

    -- Create the anchor frame.
    -- Anchor gets hidden in SetUnitBarLayout()
    local Anchor = CreateFrame('Frame', 'GUB-Anchor-' .. BarType, UnitBarsParent)

    -- Weird stuff happens if I dont hide here.
    Anchor:Hide()

    -- This is needed because the runebar wouldn't show textures correctly
    -- after reloadui
    Anchor:SetPoint('TOPLEFT')
    Anchor:SetSize(1, 1)

    -- Save a lookback to UnitBarF in anchor for selection (selectframe)
    Anchor.IsAnchor = true
    Anchor.UnitBar = UB
    Anchor.UnitBarF = UnitBarF

    Anchor:SetMovable(true)
    Anchor:SetToplevel(true)

    -- Get name for align and swap.
    Anchor.Name = UnitBars[BarType].Name

    -- Create placement frame.
    local AnchorPointFrame = CreateFrame('Frame', nil, Anchor)
    AnchorPointFrame:SetPoint('TOPLEFT')
    AnchorPointFrame:SetSize(1, 1)
    Anchor.AnchorPointFrame = AnchorPointFrame

    -- Create the alpha frame.
    local AlphaFrame = CreateFrame('Frame', nil, AnchorPointFrame)
    AlphaFrame:SetPoint('TOPLEFT')
    AlphaFrame:SetSize(1, 1)

    -- Create the scale frame.
    local ScaleFrame = CreateFrame('Frame', nil, AlphaFrame)
    ScaleFrame:SetPoint('TOPLEFT')
    ScaleFrame:SetSize(1, 1)

    -- Save the frames.
    UnitBarF.Anchor = Anchor
    UnitBarF.AnchorPointFrame = AnchorPointFrame
    UnitBarF.AlphaFrame = AlphaFrame
    UnitBarF.ScaleFrame = ScaleFrame

    UnitBarF.BarType = BarType

    -- Save the enable bar function.
    UnitBarF.BarVisible = UB.BarVisible

    if UnitBarF.IsHealth or UnitBarF.IsPower then
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

    -- Reset stuff
    Main:SetAnchorSize('reset')
    Main:SetCastTracker('reset')
    Main:SetAuraTracker('reset')
    Main:SetPredictedSpells('reset')
  end

  for BarType, UBF in pairs(UnitBarsF) do
    local UB = UBF.UnitBar

    -- Reset the OldEnabled flag during profile change.
    if ProfileChanged then
      UBF.OldEnabled = nil
    end
    Total = Total + 1

    -- Enable/Disable if player class option is true.
    -- Must use default classspecs
    if EnableClass then
      local ClassSpecs = DUB[BarType].ClassSpecs[PlayerClass]

      UB.Enabled = ClassSpecs ~= nil and Contains(ClassSpecs, true) ~= nil
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

      -- disabled
      elseif Created and not ProfileChanged then
        HideUnitBar(UBF, true)
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
    Main:UnitBarsSetAllOptions()
    GUB:UnitBarsUpdateStatus()
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
  Main.PlayerGUID = PlayerGUID
  Main.Gdata = Gdata

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
-- FixText
--
-- Adds keys that are in the defaults but not in the profile
-- Removes keys that are in the profile but not in the default
-------------------------------------------------------------------------------
local function FixText(BarType, UBD, UnitBar, TextTableName)
  local DefaultText = UBD[TextTableName]
  local Text = UnitBar[TextTableName]

  if Text and DefaultText then
    -- First text line is the default
    DefaultText = DefaultText[1]

    if DefaultText then
      for TextLine, Txt in ipairs(Text) do

        -- Copy any keys that are not in the profile from defaults.
        Main:CopyMissingTableValues(DefaultText, Txt, true)

        for Key in pairs(Txt) do
          if DefaultText[Key] == nil then
            --print('ERASED:', format('%s.%s.%s.%s', BarType, TextTableName, TextLine, Key))
            Txt[Key] = nil
          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- FixTriggers
--
-- Adds keys that are in the defaults but not in the profile
-- Removes keys that are in the profile but not in the default
-------------------------------------------------------------------------------
local TriggerExcludeList =  {
  ['Auras'] = 1,
  ['Index'] = 1,
  ['Virtual'] = 1,
  ['Select'] = 1,
  ['TypeIndex'] = 1,
  ['TextLine'] = 1,
  ['GroupNumbers'] = 1,
  ['OneTime'] = 1,
  ['OffsetAll'] = 1,
  ['OrderNumber'] = 1,
}

local function FixTriggers(BarType, UBD, Triggers)
  if Triggers then
    local DefaultTrigger = UBD.Triggers
    DefaultTrigger = DefaultTrigger and DefaultTrigger.Default

    if DefaultTrigger then
      for TriggerIndex, Trigger in ipairs(Triggers) do

        -- Copy any keys that are not in the profile from defaults.
        Main:CopyMissingTableValues(DefaultTrigger, Trigger, true)

        for Key in pairs(Trigger) do
          if DefaultTrigger[Key] == nil and TriggerExcludeList[Key] == nil then
            --print('ERASED:', format('%s.Triggers.%s.%s', BarType, TriggerIndex, Key))
            Trigger[Key] = nil
          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- FixUnitBars
--
-- Deletes anything not on the exclude list.
--
-- NOTES: Exclude list
--         * means a bartype like PlayerPower, RuneBar, etc.
--         # Means an array element.
-------------------------------------------------------------------------------
local ExcludeList = {
  ['Version'] = 1,
  ['Reset'] = 1,
  ['APBPos'] = 1,
  ['APBTimerPos'] = 1,
  ['EABPos'] = 1,
  ['*.BoxLocations'] = 1,
  ['*.BoxOrder'] = 1,
  ['*.Text.#'] = 1,
  ['*.Text2.#'] = 1,
  ['*.Triggers.#'] = 1,
  ['*.Triggers.ActionSync'] = 1,
}

local function FixUnitBars(DefaultTable, Table, TablePath, RTablePath)
  if DefaultTable == nil then
    DefaultTable = DUB
    Table = UnitBars
    TablePath = ''
    RTablePath = ''
  end

  for Key, Value in pairs(Table) do
    local DefaultValue = DefaultTable[Key]
    local PathKey = Key
    local RPathKey = Key

    if UnitBarsF[Key] then
      PathKey = '*'
      RPathKey = Key

      FixText(Key, DefaultValue, Value, 'Text')
      FixText(Key, DefaultValue, Value, 'Text2') -- Stagger Pause Timer Text
      FixTriggers(Key, DefaultValue, Value.Triggers)

    elseif type(Key) == 'number' then
      PathKey = '#'
      RPathKey = Key
    end

    if ExcludeList[format('%s%s', TablePath, PathKey)] == nil then
      if DefaultValue ~= nil then
        if type(Value) == 'table' then
          FixUnitBars(DefaultValue, Value, format('%s%s.', TablePath, PathKey), format('%s%s.', RTablePath, RPathKey))
        end
      else
        --print('ERASED:', format('%s%s', RTablePath, RPathKey))
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
  local Ver = UnitBars.Version

  -- Share the values with other parts of the addon.
  ShareData()

  if Ver == nil then
    -- Convert profile from preversion 200.
    ConvertUnitBarData(1)
  end
  if Ver == nil or Ver < 300 then
    -- Convert profile from a version before 3.00
    ConvertUnitBarData(2)
  end
  if Ver == nil or Ver < 400 then
    -- Convert profile from a version before 3.50
    ConvertUnitBarData(3)
  end
  if Ver == nil or Ver < 401 then
    -- Convert profile from a version before 4.01
    ConvertUnitBarData(4)
  end
  if Ver == nil or Ver < 410 then
    -- Convert profile from a version before 4.10
    ConvertUnitBarData(5)
  end
  if Ver == nil or Ver < 500 then
    -- Convert profile from a version before 5.00
    ConvertUnitBarData(6)
  end
  if Ver == nil or Ver < 501 then
    -- Convert profile from a version before 5.01
    ConvertUnitBarData(7)
  end
  if Ver == nil or Ver < 513 then
    -- Convert profile from a version before 5.13
    ConvertUnitBarData(8)
  end
  if Ver == nil or Ver < 541 then
    -- Convert profile from a version before 5.41
    ConvertUnitBarData(9)
  end
  if Ver == nil or Ver < 570 then
    -- Convert profile from a version before 5.70
    ConvertUnitBarData(10)
  end
  if Ver == nil or Ver < 610 then
    -- Convert profile from a version before 6.10
    ConvertUnitBarData(11)
  end

  -- Make sure profile is accurate.
  FixUnitBars()
  UnitBars.Version = Version

  Main:SetUnitBars(true)

  -- Update options.
  Options:DoFunction()

  -- Reset align padding.
  Main:MoveFrameSetAlignPadding(UnitBarsFE, 'reset')

  Main:UnitBarsSetAllOptions()

  GUB.UnitBarsUpdateStatus()
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
  if select(4, GetBuildInfo()) < 80000 then
    message("Galvin's UnitBars\nThis will work on WoW 8.x or higher only")
    return
  end

  -- Check for a bar not loaded
  local Exit = false
  for BarType, UBF in pairs(UnitBarsF) do
    if UBF.IsHealth or UBF.IsPower then
      if GUB.HapBar.CreateBar == nil then
        Exit = true
      end
    elseif GUB[BarType].CreateBar == nil then
      Exit = true
    end
    if Exit then
      message("Galvin's UnitBars\nGame needs to be restarted since a new lua file was added since the last update")
      return
    end
  end

  if not InitOnce then
    return
  end
  InitOnce = false

  -- Add blizzards powerbar colors and class colors to defaults.
  InitializeColors()

  -- Load the unitbars database
  -- true default to shared "Default" profile instead of per-char to start with
  GUB.MainDB = LibStub('AceDB-3.0'):New('GalvinUnitBarsDB', GUB.DefaultUB.Default, true)

  UnitBars = GUB.MainDB.profile
  Gdata = GUB.MainDB.global

  -- Let ace3 handle GalvinUnitBarsData. This will only run once
  if Gdata.ShowMessage == 0 then
    if GalvinUnitBarsData then

      -- Copy data to global profile
      Gdata.ShowMessage = GalvinUnitBarsData.ShowMessage
      Gdata.APBUsed     = GalvinUnitBarsData.AltPowerBarUsed
      Gdata.APBUseBlizz = GalvinUnitBarsData.APBUseBlizz
      Gdata.APBShowUsed = UnitBars.APBShowUsed
    end
  else
    -- Delete old data since its not used any more
    GalvinUnitBarsData = nil
  end
  APBUsed = Gdata.APBUsed
  APBUseBlizz = Gdata.APBUseBlizz

  -- Get player stuff
  -- Get the globally unique identifier for the player.
  _, PlayerClass = UnitClass('player')
  _, PlayerPowerType = UnitPowerType('player')
  PlayerSpecialization = GetSpecialization() or 0
  PlayerGUID = UnitGUID('player')

  ShareData()
  Options:OnInitialize()
  InitAltPowerBar()
  InitExtraActionButton()
  Main:GetTalents()

  GUB:ApplyProfile()

  GUB.MainDB.RegisterCallback(GUB, 'OnProfileReset', 'ProfileNew')
  GUB.MainDB.RegisterCallback(GUB, 'OnNewProfile', 'ProfileNew')
  GUB.MainDB.RegisterCallback(GUB, 'OnProfileChanged', 'ApplyProfile')
  GUB.MainDB.RegisterCallback(GUB, 'OnProfileCopied', 'ApplyProfile')
  LSM.RegisterCallback(GUB, 'LibSharedMedia_Registered', 'MediaUpdate')

  -- Initialize the events.
  RegisterEvents('register', 'main')

  if Gdata.ShowMessage ~= 34 then
    Gdata.ShowMessage = 34
    Main:MessageBox(DefaultUB.ChangesText[1])
  end
end

