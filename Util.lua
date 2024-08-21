--
-- Util.lua
--
-- Mostly utility for main.lua

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local DefaultUB = GUB.DefaultUB

local Util = GUB.Util
local Main = GUB.Main
local Options = GUB.Options

local ConvertPowerTypeHAP = GUB.DefaultUB.ConvertPowerTypeHAP
local HyperlinkSt = GUB.DefaultUB.HyperlinkSt

-- localize some globals.
local _, _G, print =
      _, _G, print
local Enum =
      Enum
local strfind, strmatch, strupper, format =
      strfind, strmatch, strupper, format
local pairs, next, select, tonumber, tinsert, type, sort, CreateFrame =
      pairs, next, select, tonumber, tinsert, type, sort, CreateFrame
local GetFlyoutInfo, GetFlyoutSlotInfo =
      GetFlyoutInfo, GetFlyoutSlotInfo
local GetPvpTalentInfoByID =
      GetPvpTalentInfoByID
local C_ClassTalents, C_Traits, C_UnitAuras, C_SpecializationInfo, C_SpellBook, C_Spell, AuraUtil =
      C_ClassTalents, C_Traits, C_UnitAuras, C_SpecializationInfo, C_SpellBook, C_Spell, AuraUtil
local UnitCastingInfo =
      UnitCastingInfo
local wipe, C_TooltipInfo_GetHyperlink =
      wipe, C_TooltipInfo.GetHyperlink

------------------------------------------------------------------------------
-- RegEventFrames         - Table used by RegEvent()
-- RegUnitEventFrames     - Table used by RegUnitEvent()
-- TalentTrackersData     - Table that contains talents, active, and used by options. See TalentUpdate()
--
-- Util.AuraTrackersData    - Reference to AuraTrackersData
-- Util.TalentTrackersData  - Reference to TalentTrackersData
------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Cast tracker
--
-- Keeps track of any spell being cast.
--
-- CastTrackers[Object]        - Keeps track of the casting info for the bar.
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
-- AuraTrackers[Object]      - Table containing which bar has auras.
--   Enabled                 - If true then events for this bar are turned on.
--   Units                   - Hash table of units for this object.
--   Fn                      - Function to call for this objeect.
--
-- AuraTrackersData.All      - Contains a list of all the spells not broken by unit.
--   All[SpellID]            - Reference to SpellID below, but only used by Spell.lua
--
-- AuraTrackersData[Unit]    - Table of units containing the auras
--   InstanceIDsAuraSpellID  - Table containing the aura spellIDs that can be looked up
--                             by aura instance IDs. Used by AuraUpdate()
--   DebuffTypes[]           - All the debuff types for all auras for this unit
--   Active                  - If true then at least one aura is present
--   Own                     - If true then at at least one aura is created by the owner
--   Stacks                  - Highest stacks of all the auras for this unit
--   Buff                    - All aura buffs
--     Active
--     Own
--     Stacks
--   Debuff                  - All aura debuffs
--     DebuffTypes[]         - Reference to DebuffTypes above
--     Active
--     Own
--     Stacks
--
--   [SpellID]               - SpellID of each aura
--      Active               - If true then aura is on the unit, otherwise its false
--      Type                 - Type of aura
--                              - 1  Buff
--                              - 2  Debuff
--      Own                  - If true then the player created this aura
--      Stacks               - Amount of stacks the aura has
--      DebuffType           - String: type for debuffs
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Talent Tracker
--
-- Tracks all talents
--
-- TalentTrackers[Object]        - Keeps track of the talent info fhr the bar
--   Enabled                     - Used by SetTalentTracker()
--                                   if true then Fn will get called for this bar
--   Fn                          - Function to call when a talent is changed
--
-- TalentTrackersData
--   Active[SpellID]             - All the talents currently in use. Talent SpellID
--   SpellIDs[TalentName]        - Used by options to convert menu items into spellIDs
--   TalentIsPvP[SpellID]        - if true then the talent is PvP otherwise PvE
--
--   ClassDropdown               - Talents currently being used. Dropdown menu used by options
--   ClassIconDropdown           - Same as PvEDropdown with icons
--
--   SpecDropdown                - Same as class except for specialization
--   SpecIconDropdown            - Same as class except for specialization
--
--   HeroDropdown                - Same as class except for hero
--   HeroIconDropdown            - Same as class except for hero
--   The above dropdowns include talents not in use
--
--   <same as PvE>
--   PvPDropdown                 - Dropdown menu used by options
--   PvPIconDropdown             - Same as dropdown with icons
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Predicted Spells
--
-- Keeps track of spells that give back power with a cast time.
--
-- PredictedSpells
--   SpellBook                if nil then tthe spellbook needs to be read
--
-- PredictedSpells[SpellID]   Contains the amount of power a spell returns
--   Amount                   Amount of power
--   PowerType                Type of power
--
-- PredictedSpells[UnitBarF]  Contains which bars are using predicted spells.
--   Fn                       if not nil this function will get called
--                            when a spells amount of power returned changes.
--
-- Notes on predicted spell tracking.
--
-- If the spell book changes a rescan of the spellbook takes place.  Just spells
-- that have a cast time and generate resource gets tracked.
--
-- If an aura buffs a spell that causes it to return more resource, its tooltip
-- will be updated while the aura is up. So the spellbook gets scanned to find
-- this change and the value is updated. Same with equipment changing.
-------------------------------------------------------------------------------
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

local CastTracking
local CastTrackers

local AuraTrackers
local AuraTrackersData = {}

local TalentTrackers
local TalentTrackersData = {}

local PredictedSpells

local RegEventFrames = {}
local RegUnitEventFrames = {}

Util.AuraTrackersData = AuraTrackersData
Util.TalentTrackersData = TalentTrackersData

-------------------------------------------------------------------------------
-- RegisterUtilEvents
--
-- Register/unregister events
--
-- Action       'unregister' or 'register'
-- EventType    Type of events to register.
-- Unit         used for auratracking
-------------------------------------------------------------------------------
local function RegisterUtilEvents(Action, EventType, Unit)
  local Flag = Action == 'register'

  if EventType == 'casttracker' then
    Util:RegEvent(Flag, 'UNIT_SPELLCAST_START',       Util.TrackCast, 'player')
    Util:RegEvent(Flag, 'UNIT_SPELLCAST_SUCCEEDED',   Util.TrackCast, 'player')
    Util:RegEvent(Flag, 'UNIT_SPELLCAST_STOP',        Util.TrackCast, 'player')
    Util:RegEvent(Flag, 'UNIT_SPELLCAST_FAILED',      Util.TrackCast, 'player')
    Util:RegEvent(Flag, 'UNIT_SPELLCAST_INTERRUPTED', Util.TrackCast, 'player')
    Util:RegEvent(Flag, 'UNIT_SPELLCAST_DELAYED',     Util.TrackCast, 'player')

  elseif EventType == 'predictedspells' then
    Util:RegEvent(Flag, 'SPELLS_CHANGED',         Util.CheckPredictedSpells)
    Util:RegEvent(Flag, 'UPDATE_SHAPESHIFT_FORM', Util.CheckPredictedSpells)

  elseif EventType == 'talenttracker' then
    Util:RegEvent(Flag, 'TRAIT_CONFIG_UPDATED',     Util.TalentUpdate)
    Util:RegEvent(Flag, 'PLAYER_PVP_TALENT_UPDATE', Util.TalentUpdate)

  elseif EventType == 'auratracker' then
    Util:RegUnitEvent(Flag, 'UNIT_AURA', Util.AuraUpdate, Unit) -- Use this cause more than 2 units
    Util:RegEvent(Flag, 'PLAYER_TARGET_CHANGED', Util.AuraUpdate)
    Util:RegEvent(Flag, 'PLAYER_FOCUS_CHANGED', Util.AuraUpdate)
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
function Util:RegEventFrame(Reg, Frame, Event, Fn, ...)
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

function Util:RegEvent(Reg, Event, Fn, ...)

  -- Get frame based on Fn.
  local Frame = RegEventFrames[Fn]

  -- Create a new frame if one wasn't found.
  if Frame == nil then

    -- Create a new event frame for this event
    Frame = CreateFrame('Frame')
    RegEventFrames[Fn] = Frame
  end
  Util:RegEventFrame(Reg, Frame, Event, Fn, ...)
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
function Util:RegUnitEvent(Reg, Event, Fn, ...)

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
-- SetTalentTracker
--
-- Calls a function when a talent gets changed
--
-- Usage:  SetTalentTracker(Object, 'fn', Fn)
--         SetTalentTracker(Object, 'off')
--         SetTalentTracker(Object, 'register' or 'unregister')
--         SetTalentTracker('reset')
--
-- Object         The table, string, etc to assign the talent tracker to.
-- Fn             Turns on talent tracking and calls Fn when talents change.
--                Function to call for this unitbar.
--                  Fn gets called with (TalentTrackersData) from TalentUpdate()
-- 'off'          Turns off all talenttracking for this bar
-- 'reset'        turns off all talent tracking
-------------------------------------------------------------------------------
function Util:SetTalentTracker(Object, Action, Fn)
  local RefreshTalentList = false

  if Object == 'reset' then
    TalentTrackers = nil
    wipe(TalentTrackersData)
  else
    local TalentTracker = TalentTrackers and TalentTrackers[Object]

    -- Turn talent tracking on and set Fn
    if Action == 'fn' then
      RefreshTalentList = true
      if TalentTrackers == nil then
        TalentTrackers = {}
      end

      if TalentTracker == nil then
        TalentTracker = {Enabled = true}
        TalentTrackers[Object] = TalentTracker
      end

      TalentTracker.Fn = Fn

    -- Turn off talent tracker for this object
    elseif TalentTrackers and Action == 'off' then
      TalentTrackers[Object] = nil
      RefreshTalentList = true
    end

    -- Register or unregister
    if TalentTracker and (Action == 'register' or Action == 'unregister') then
      TalentTracker.Enabled = Action == 'register'
    end
  end

  RegisterUtilEvents('unregister', 'talenttracker')

  -- Only register events if the tracked talents list table is not empty
  if TalentTrackers and next(TalentTrackers) then

    -- Reg events for anything enabled
    for Object, TalentTracker in pairs(TalentTrackers) do
      if TalentTracker.Enabled then
        RegisterUtilEvents('register', 'talenttracker')
        RefreshTalentList = true
        break
      end
    end
  end
  -- Refresh talents for anything listening to talents
  if RefreshTalentList then
    Util:TalentUpdate()
  end
end

-------------------------------------------------------------------------------
-- SetCastTracker
--
-- Calls a function when a cast has begun and ended.
--
-- Usage:   SetCastTracker(Object, 'fn', Fn)
--          SetCastTracker(Object, 'off')
--          SetCastTracker(Object, 'register' or 'unregister')
--          SetCastTracker('reset')
--
-- UnitBarF    The bar thats tracking spell casting.
-- 'fn'        This sets up a function to call and starts tracking casts.
-- Fn          The function to call when a cast is being made.
--               Fn will get called with the following
--                 Object    -  The table, string, etc to assign the spell tracker to.
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
function Util:SetCastTracker(Object, Action, Fn)
  if Object == 'reset' then
    CastTrackers = nil
    CastTracking = nil
  else
    local CastTracker = CastTrackers and CastTrackers[Object]

    -- Turn cast tracking on and set Fn
    if Action == 'fn' then
      if CastTrackers == nil then
        CastTrackers = {}
      end

      if CastTracker == nil then
        CastTracker = {Enabled = true}
        CastTrackers[Object] = CastTracker
      end

      if CastTracking == nil then
        CastTracking = {SpellID =0, CastID = ''}
      end

      CastTracker.Fn = Fn

    -- Turn off cast tracking for this bar
    elseif CastTracker then
      if Action == 'off' then
        CastTrackers[Object] = nil

      -- track events on or off.
      elseif Action == 'register' or Action == 'unregister' then
        CastTracker.Enabled = Action == 'register'
      end
    end
  end

  RegisterUtilEvents('unregister', 'casttracker')

  if CastTrackers then
    for UBF, CastTracker in pairs(CastTrackers) do
      if CastTracker.Enabled then
        RegisterUtilEvents('register', 'casttracker')
        break
      end
    end
  end
end

--*****************************************************************************
--
-- Get and setters
--
--*****************************************************************************

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
--                  Fn gets called with (AuraTrackersData) from AuraUpdate()
-- 'off'          Turns off all auratracking for this bar
-- Units          List of units to add.  If nil then units are removed for this bar.
-- 'reset'        Clears all units and turns off all events for all bars.
-------------------------------------------------------------------------------
function Util:SetAuraTracker(Object, Action, ...)
  local RefreshAuraList = false

  if Object == 'reset' then
    AuraTrackers = nil
    wipe(AuraTrackersData)
  else
    local AuraTracker = AuraTrackers and AuraTrackers[Object]

    -- Turn aura tracking on and set Fn
    if Action == 'fn' then
      if AuraTrackers == nil then
        AuraTrackers = {}
      end

      if AuraTracker == nil then
        AuraTracker = {Enabled = true}
        AuraTrackers[Object] = AuraTracker
      end

      AuraTracker.Fn = ...
      return

    -- Turn off aura tracking for this object
    elseif AuraTrackers and Action == 'off' then
      AuraTrackers[Object] = nil
      RefreshAuraList = true
    end

    -- Register or unregister.
    if AuraTracker and (Action == 'register' or Action == 'unregister') then
      AuraTracker.Enabled = Action == 'register'

    elseif Action == 'units' then
      RefreshAuraList = true
      if AuraTrackersData.All == nil then
        -- Create a fake unit 'All'
        AuraTrackersData.All = {}
      end
      if next(AuraTrackersData) == nil then
        wipe(AuraTrackersData.All)
      end

      -- Add units to the object
      local Units = {}
      AuraTracker.Units = Units

      if ... then
        for Index = 1, select('#', ...) do
          local Unit = select(Index, ...)

          if Unit ~= 'All' then
            Units[Unit] = 1
          end
        end
      end
    end
    if RefreshAuraList then
      local AllUnits = {}

      for _, AuraTracker in pairs(AuraTrackers) do
        local Units = AuraTracker.Units

        if Units then
          for Unit in pairs(Units) do
            AllUnits[Unit] = 1
            if AuraTrackersData[Unit] == nil then
              local DebuffTypes = {}
              AuraTrackersData[Unit] = { InstanceIDsAuraSpellID = {},
                                         DebuffTypes = DebuffTypes,
                                         Buff = {},
                                         Debuff = { DebuffTypes = DebuffTypes },
                                         Active = false,
                                         Own = false,
                                         Stacks = 0                             }
            end
          end
        end
      end

      for Unit in pairs(AuraTrackersData) do
        if Unit ~= 'All' then
          if AllUnits[Unit] == nil then
            AuraTrackersData[Unit] = nil
          end
        end
      end
    end
  end

  RegisterUtilEvents('unregister', 'auratracker')

  -- Only register events if the tracked auras list table is not empty.
  if AuraTrackers and next(AuraTrackers) then

    -- Reg events for any enabled units.
    for Object, AuraTracker in pairs(AuraTrackers) do
      if AuraTracker.Enabled then
        local Units = AuraTracker.Units

        if Units then
          for Unit in pairs(Units) do
            RegisterUtilEvents('register', 'auratracker', Unit)
            RefreshAuraList = true
          end
        end
      end
    end
  end
  -- Refresh auras for anything listening to auras.
  if RefreshAuraList then
    Util:AuraUpdate()
  end
end

-------------------------------------------------------------------------------
-- GetPredictedSpell
--
-- Returns the amount of power and powertype that a predicted spell currently has otherise 0
--
-- UnitBarF   The bar thats using predicted spells
-- SpellID    Spell whos power you're getting
-------------------------------------------------------------------------------
function Util:GetPredictedSpell(UnitBarF, SpellID)
  if PredictedSpells and PredictedSpells[UnitBarF] then

    -- Check the spell book if it hasn't been checked
    if PredictedSpells.SpellBook == nil then
      Util:CheckPredictedSpells()
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
function Util:SetPredictedSpells(UnitBarF, Action, Fn)
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

  RegisterUtilEvents('unregister', 'predictedspells')

  if PredictedSpells then
    for UnitBarF, PredictedSpell in pairs(PredictedSpells) do
      if type(UnitBarF) ~= 'number' then
        RegisterUtilEvents('register', 'predictedspells')
        break
      end
    end
  end
end

--*****************************************************************************
--
-- Script functions (script/event)
--
--*****************************************************************************

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
    for Object, CastTracker in pairs(CastTrackers) do
      if CastTracker.Enabled then
        CastTracker.Fn(Object, CastTracking.SpellID, Timeout and 'timeout' or Message)
      end
    end
  end

  -- Stop timeout timer
  if Timeout then
    Main:SetTimer(CastTracking, nil)
  end
end

function Util:TrackCast(Event, Unit, CastID, SpellID)
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
-- SortDropdown
--
-- Subfunction of TalentUpdate()
--
-- Sorts a dropdown alphabetical
-------------------------------------------------------------------------------
local function SortDropdown(Dropdown, NotUseDropdown, IconDropdown, Tagged, Icons, NoneSt, ActiveRanks)
  if #Dropdown > 0 then
    local NotUseSt = DefaultUB.NotUseSt
    sort(Dropdown)
    sort(NotUseDropdown)

    Dropdown[#Dropdown + 1] = NotUseSt

    local NotUseDropdownIndex = 0
    local InUse = true

    for Index = #Dropdown + 1, #Dropdown + #NotUseDropdown + 1 do
      NotUseDropdownIndex = NotUseDropdownIndex + 1
      Dropdown[Index] = NotUseDropdown[NotUseDropdownIndex]
    end

    for Index = 1, #Dropdown do
      local Name = Dropdown[Index]
      local TaggedName = Tagged[Name]
      if Name == NotUseSt then
        InUse = false
        IconDropdown[Index + 1] = NotUseSt
      elseif InUse then
        if ActiveRanks == nil then --> for PvP
          IconDropdown[Index + 1] = format('|T%s:15|t %s', Icons[Name], Name)
        elseif TaggedName then
          IconDropdown[Index + 1] = format('|T%s:15|t %s |c00FFFF00%s%s|r', Icons[Name], ActiveRanks[Name], Name, TaggedName)
        else
          IconDropdown[Index + 1] = format('|T%s:15|t %s %s', Icons[Name], ActiveRanks[Name], Name)
        end
      elseif TaggedName then
        IconDropdown[Index + 1] = format('|T%s:15|t |c00FFFF00%s%s|r', Icons[Name], Name, TaggedName)
      else
        IconDropdown[Index + 1] = format('|T%s:15|t %s', Icons[Name], Name)
      end
    end
    IconDropdown[1] = NoneSt
    tinsert(Dropdown, 1, NoneSt)
  else
    local NoTalentsSt = DefaultUB.NoTalentsSt

    IconDropdown[1] = NoTalentsSt
    tinsert(Dropdown, 1, NoTalentsSt)
  end
end

-------------------------------------------------------------------------------
-- TalentUpdate (called by event)
--
-- Used by SetTalentTracker()
--
-- Gets called when ever a talent is changed or talents change
-- Stores which talents are active. Also contains pulldown menu data for options.
-------------------------------------------------------------------------------
function Util:TalentUpdate(Event, ...)
  if TalentTrackers then
    if next(TalentTrackersData) == nil then
      TalentTrackersData.Active = {}
      TalentTrackersData.SpellIDs = {}
      TalentTrackersData.TalentIsPvP = {}
      TalentTrackersData.PvPDropdown = {}
      TalentTrackersData.PvPIconDropdown = {}
      TalentTrackersData.ClassDropdown = {}
      TalentTrackersData.ClassIconDropdown = {}
      TalentTrackersData.SpecDropdown = {}
      TalentTrackersData.SpecIconDropdown = {}
      TalentTrackersData.HeroDropdown = {}
      TalentTrackersData.HeroIconDropdown = {}
    end
    local PvPTalentIDs = {}
    local SpellIDs = TalentTrackersData.SpellIDs
    local Active = TalentTrackersData.Active
    local TalentIsPvP = TalentTrackersData.TalentIsPvP
    wipe(Active)
    wipe(SpellIDs)
    wipe(TalentIsPvP)

    local ClassDropdown = TalentTrackersData.ClassDropdown
    local ClassIconDropdown = TalentTrackersData.ClassIconDropdown
    local SpecDropdown = TalentTrackersData.SpecDropdown
    local SpecIconDropdown = TalentTrackersData.SpecIconDropdown
    local HeroDropdown = TalentTrackersData.HeroDropdown
    local HeroIconDropdown = TalentTrackersData.HeroIconDropdown

    local ClassNotUseDropdown = {}
    local SpecNotUseDropdown = {}
    local HeroNotUseDropdown = {}

    local ClassDropdownIndex = 0
    local ClassNotUseDropdownIndex = 0
    local SpecDropdownIndex = 0
    local SpecNotUseDropdownIndex = 0
    local HeroDropdownIndex = 0
    local HeroNotUseDropdownIndex = 0

    local ActiveRanks = {}
    local Tagged = {}
    local Icons = {}
    local NoneSt = 'None'

    wipe(ClassDropdown)
    wipe(ClassIconDropdown)
    wipe(SpecDropdown)
    wipe(SpecIconDropdown)
    wipe(HeroDropdown)
    wipe(HeroIconDropdown)

    local C_Traits_GetNodeInfo = C_Traits.GetNodeInfo
    local C_Traits_GetEntryInfo = C_Traits.GetEntryInfo
    local C_Traits_GetDefinitionInfo = C_Traits.GetDefinitionInfo
    local C_SpecializationInfo_GetPvpTalentSlotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo

    local C_Spell_GetSpellName = C_Spell.GetSpellName
    local C_Spell_GetSpellTexture = C_Spell.GetSpellTexture

    local ConfigID = C_ClassTalents.GetActiveConfigID()

   -- local MaxX = 0

    if ConfigID then
      local ConfigInfo = C_Traits.GetConfigInfo(ConfigID)
      local NodeIDs = C_Traits.GetTreeNodes(ConfigInfo.treeIDs[1])

      -- Get all the talents
      for NodeIndex = 1, #NodeIDs do
        local NodeInfo = C_Traits_GetNodeInfo(ConfigID, NodeIDs[NodeIndex])
        local EntryIDs = NodeInfo.entryIDs
        local CommittedRankEntryID = NodeInfo.entryIDsWithCommittedRanks[1]

        -- Need to loop anyway for pulldown menus
        -- 1 Entry ID is a normal node
        -- 2 Entry ID's is a choice node
        for EntryIndex = 1, #EntryIDs do
          local EntryID = EntryIDs[EntryIndex]
          local ActiveRank = NodeInfo.activeRank
          local GrantedForFree = NodeInfo.ranksPurchased == 0 and ActiveRank > 0 or false
          local Committed = false

          if GrantedForFree or EntryID == CommittedRankEntryID then
            Committed = true
          end
          local EntryInfo = C_Traits_GetEntryInfo(ConfigID, EntryID)

          -- Skip if hero tree or EntryInfo is nil
          -- if it's a SubTree then definitionID will be nill
          local DefinitionID = EntryInfo and EntryInfo.definitionID

          if DefinitionID then
            local DefinitionInfo = C_Traits_GetDefinitionInfo(DefinitionID)
            local SpellID = DefinitionInfo.spellID

            -- Some nodes can have bad data, so skip on nil spellID
            if SpellID then
              local Name = C_Spell_GetSpellName(SpellID)
              local TalentType = 'none'

              if NodeInfo.subTreeID then
                if NodeInfo.subTreeActive then
                  TalentType = 'hero'
                end
              elseif NodeInfo.posX > 7000 then
                TalentType = 'spec'
              else
                TalentType = 'class'
              end

              SpellIDs[Name] = SpellID
              Icons[Name] = C_Spell_GetSpellTexture(SpellID)
              TalentIsPvP[SpellID] = false

              if Committed then
                Active[SpellID] = true
                ActiveRanks[Name] = ActiveRank
                if TalentType == 'class' then
                  ClassDropdownIndex = ClassDropdownIndex + 1
                  ClassDropdown[ClassDropdownIndex] = Name
                elseif TalentType == 'spec' then
                  SpecDropdownIndex = SpecDropdownIndex + 1
                  SpecDropdown[SpecDropdownIndex] = Name
                elseif TalentType == 'hero' then
                  HeroDropdownIndex = HeroDropdownIndex + 1
                  HeroDropdown[HeroDropdownIndex] = Name
                end
              elseif TalentType == 'class' then
                ClassNotUseDropdownIndex = ClassNotUseDropdownIndex + 1
                ClassNotUseDropdown[ClassNotUseDropdownIndex] = Name
              elseif TalentType == 'spec' then
                SpecNotUseDropdownIndex = SpecNotUseDropdownIndex + 1
                SpecNotUseDropdown[SpecNotUseDropdownIndex] = Name
              elseif TalentType == 'hero' then
                HeroNotUseDropdownIndex = HeroNotUseDropdownIndex + 1
                HeroNotUseDropdown[HeroNotUseDropdownIndex] = Name
              end
              -- Tag talent if granted for free
              if GrantedForFree then
                Tagged[Name] = '*'
              end
            end
          end
        end
      end
    end

    SortDropdown(ClassDropdown, ClassNotUseDropdown, ClassIconDropdown, Tagged, Icons, NoneSt, ActiveRanks)
    SortDropdown(SpecDropdown,  SpecNotUseDropdown,  SpecIconDropdown,  Tagged, Icons, NoneSt, ActiveRanks)
    SortDropdown(HeroDropdown,  HeroNotUseDropdown,  HeroIconDropdown,  Tagged, Icons, NoneSt, ActiveRanks)

    -- PvP
    local PvPDropdown = TalentTrackersData.PvPDropdown
    local PvPIconDropdown = TalentTrackersData.PvPIconDropdown
    local PvPNotUseDropdown = {}
    local SelectedID = {}
    local DropdownIndex = 0
    local NonUseDropdownIndex = 0
    wipe(PvPDropdown)
    wipe(PvPIconDropdown)

    -- Find selected
    for SlotIndex = 1, 3 do
      -- Sometimes this returns nil, so need to check it. Why does blizzard do stuff like this.
      local SlotInfo = C_SpecializationInfo_GetPvpTalentSlotInfo(SlotIndex)

      if SlotInfo then
        local SelectedTalentID = SlotInfo.selectedTalentID

        if SelectedTalentID then
          SelectedID[SelectedTalentID] = true
        end
      end
    end

    -- No need to check all 3 slots. Since the selected ones are already known
    -- Sometimes this returns nil, so need to check it. Why does blizzard do stuff like this.
    local SlotInfo = C_SpecializationInfo_GetPvpTalentSlotInfo(1)

    if SlotInfo then
      local TalentIDs = SlotInfo.availableTalentIDs
      local SelectedTalentID = SlotInfo.selectedTalentID

      for PvPIndex = 1, #TalentIDs do
        local TalentID = TalentIDs[PvPIndex]
        local _, Name, Icon, _, _, SpellID = GetPvpTalentInfoByID(TalentID)

        if PvPTalentIDs[TalentID] == nil then
          PvPTalentIDs[TalentID] = true
          SpellIDs[Name] = SpellID
          Icons[Name] = Icon
          TalentIsPvP[SpellID] = true

          if SelectedID[TalentID] then
            DropdownIndex = DropdownIndex + 1
            PvPDropdown[DropdownIndex] = Name
            Active[SpellID] = true
          else
            NonUseDropdownIndex = NonUseDropdownIndex + 1
            PvPNotUseDropdown[NonUseDropdownIndex] = Name
          end
        end
      end
    end
    -- Leave out the activeranks since this is for pvp
    SortDropdown(PvPDropdown,  PvPNotUseDropdown,  PvPIconDropdown,  Tagged, Icons, NoneSt)

 --[[   -- Sort pvp dropdown
    sort(Dropdown)
    for Index = 1, #Dropdown do
      local Name = Dropdown[Index]
      local TaggedName = Tagged[Name]
      if TaggedName then
        IconDropdown[Index + 1] = format('|T%s:15|t |c00FFFF00%s%s|r', Icons[Name], Name, TaggedName)
      else
        IconDropdown[Index + 1] = format('|T%s:15|t %s', Icons[Name], Name)
      end
    end
    if #Dropdown == 0 then
      NoneSt = DefaultUB.NoTalentsSt
    else
      NoneSt = 'None'
    end
    IconDropdown[1] = NoneSt
    tinsert(Dropdown, 1, NoneSt)
]]
    -- Only call back on event
    if Event then
      for _, TalentTracker in pairs(TalentTrackers) do
        TalentTracker.Fn(TalentTrackersData)
      end
    end
    Options:RefreshMainOptions()
  end
end

-------------------------------------------------------------------------------
-- GetAura
--
-- Gets the aura and saves it
--
-- Subfunction of AuraUpdate()
--
-- AuraTrackersDataUnit    AuraTrackersData[Unit]
-- UnitAura                Aura data from UNIT_AURA event
-------------------------------------------------------------------------------
local function GetAura(AuraTrackersDataUnit, UnitAura)
  local SpellID = UnitAura.spellId

  local Aura = AuraTrackersDataUnit[SpellID]
  if Aura == nil then
    Aura = {}
    AuraTrackersDataUnit[SpellID] = Aura
  end

  Aura.Active     = true
  Aura.Type       = UnitAura.isHelpful and 1 or 2
  Aura.Own        = UnitAura.sourceUnit == 'player'
  Aura.Stacks     = UnitAura.applications or 0
  Aura.DebuffType = UnitAura.dispelName
end

-------------------------------------------------------------------------------
-- TallyAuras
--
-- Goes thru all auras and gets the highest stack, at least one that is own, etc
--
-- Subfunction of AuraUpdate()
--
-- AuraTrackersDataUnit    AuraTrackersData[Unit]
-- All                     List of all auras ever seen
-------------------------------------------------------------------------------
local function TallyAuras(AuraTrackersDataUnit, All)

  -- Tally some stuff
  local DebuffTypes = AuraTrackersDataUnit.DebuffTypes
  for DebuffType in pairs(DebuffTypes) do
    DebuffTypes[DebuffType] = false
  end
  AuraTrackersDataUnit.Active = false
  AuraTrackersDataUnit.Own = false
  AuraTrackersDataUnit.Stacks = 0

  local BuffAura = AuraTrackersDataUnit.Buff
  BuffAura.Active = false
  BuffAura.Own = false
  BuffAura.Stacks = 0

  local DebuffAura = AuraTrackersDataUnit.Debuff
  DebuffAura.Active = false
  DebuffAura.Own = false
  DebuffAura.Stacks = 0

  for SpellID, SpellIDAura in pairs(AuraTrackersDataUnit) do
    if type(SpellID) == 'number' then

      -- Add aura to All
      if All[SpellID] == nil then
        All[SpellID] = SpellIDAura
      end

      if SpellIDAura.Active then
        local Type = SpellIDAura.Type
        local Own = SpellIDAura.Own
        local Stacks = SpellIDAura.Stacks

        -- do all debuffs
        if Type == 2 then
          local DebuffType = SpellIDAura.DebuffType
          if DebuffType then
            DebuffTypes[DebuffType] = true
          end
        end

        -- do all
        AuraTrackersDataUnit.Active = true
        if Own then
          AuraTrackersDataUnit.Own = Own
        end
        if Stacks > AuraTrackersDataUnit.Stacks then
          AuraTrackersDataUnit.Stacks = Stacks
        end

        -- Do all buffs or debufs
        local Aura = AuraTrackersDataUnit[Type == 1 and 'Buff' or 'Debuff']
        Aura.Active = true
        if Own then
          Aura.Own = Own
        end
        if Stacks > Aura.Stacks then
          Aura.Stacks = Stacks
        end
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
-- Event         This is used if called by a UNIT_AURA event.  Otherwise
--               it'll iterate thru all units currently active
-- Unit          Unit: player, target, etc
-- Info          Aura information
-------------------------------------------------------------------------------
local AuraTrackersDataUnit

local function GetAuraData(Aura)
  if Aura then
    AuraTrackersDataUnit.InstanceIDsAuraSpellID[Aura.auraInstanceID] = Aura.spellId
    GetAura(AuraTrackersDataUnit, Aura)
  end
end

function Util:AuraUpdate(Event, Unit, Info)
  if AuraTrackers and AuraTrackersData then
    local All = AuraTrackersData.All

    -- Refresh all auras if there is no event or unit
    if Info == nil or Info.isFullUpdate then
      local AuraUtil_ForEachAura = AuraUtil.ForEachAura

      for SpellID, Aura in pairs(AuraTrackersData.All) do
        Aura.Active = false
        -- no need to change anything else since its active = false
      end
      for Unit in pairs(AuraTrackersData) do
        if Unit ~= 'All' then
          AuraTrackersDataUnit = AuraTrackersData[Unit]

                                             -- BatchCount  CallBack     UsePackedAura
          AuraUtil_ForEachAura(Unit, 'HELPFUL', nil,        GetAuraData, true)
          AuraUtil_ForEachAura(Unit, 'HARMFUL', nil,        GetAuraData, true)
          TallyAuras(AuraTrackersDataUnit, All)
        end
      end
    -- Update changes in auras
    else
      local AddedAuras = Info.addedAuras
      local UpdatedIDs = Info.updatedAuraInstanceIDs
      local RemovedIDs = Info.removedAuraInstanceIDs

      local AuraTrackersDataUnit = AuraTrackersData[Unit]
      local InstanceIDsAuraSpellID = AuraTrackersDataUnit.InstanceIDsAuraSpellID

      -- Add new auras
      if AddedAuras then
        for Index = 1, #AddedAuras do
          local AddedAura = AddedAuras[Index]
          InstanceIDsAuraSpellID[AddedAura.auraInstanceID] = AddedAura.spellId

          GetAura(AuraTrackersDataUnit, AddedAura)
        end
      end
      -- Apply auras that changed
      if UpdatedIDs then
        local C_UnitAuras_GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID
        for Index = 1, #UpdatedIDs do
          local UpdatedID = UpdatedIDs[Index]
          local UpdatedAura = C_UnitAuras_GetAuraDataByAuraInstanceID(Unit, UpdatedID)
          if UpdatedAura then
            InstanceIDsAuraSpellID[UpdatedID] = UpdatedAura.spellId

            GetAura(AuraTrackersDataUnit, UpdatedAura)
          end
        end
      end
      -- Remove auras
      if RemovedIDs then
        for Index = 1, #RemovedIDs do
          local RemovedID = RemovedIDs[Index]
          local AuraSpellID = InstanceIDsAuraSpellID[RemovedID]
          InstanceIDsAuraSpellID[RemovedID] = nil

          if AuraSpellID then
            -- Set spell to not active
            AuraTrackersDataUnit[AuraSpellID].Active = false
          end
        end
      end
      TallyAuras(AuraTrackersDataUnit, All)
    end
    -- Only call back if there was an event
    if Event then
      for _, AuraTracker in pairs(AuraTrackers) do
        AuraTracker.Fn(AuraTrackersData)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- SetPredictedSpellInfo
--
-- Sub function of CheckPredictedSpells
-------------------------------------------------------------------------------
local function SetPredictedSpellInfo(SpellID)
  local SpellInfo = C_Spell.GetSpellInfo(SpellID)
  local Name, CastTime = SpellInfo.name, SpellInfo.castTime
  local PlayerPowerType = Main.PlayerPowerType
  local PlayerPowerTypeL = Main.PlayerPowerTypeL

  -- Only need spells that have cast time.
  if Name and CastTime > 0 then
    local Hyperlink = C_TooltipInfo_GetHyperlink(format(HyperlinkSt, SpellID))

    if Hyperlink then
      local Lines = Hyperlink.lines

      for LineIndex = 1, #Lines do
        local Line = Lines[LineIndex]
        local Text = Line.leftText or '' .. Line.rightText or ''

        if #Text > 0 then
          -- get the chunk of text that has: generates <number> <powertype>
          local Text, Amount = strmatch(Text, '|cFFFFFFFF(.-(%d+).-|r)')

          if Text then
            Text = strupper(Text)
            if strfind(Text, strupper(PlayerPowerTypeL)) then
              -- Check to see if the power type found exists in the health and power as well
              local PowerType = ConvertPowerTypeHAP[PlayerPowerType]

              if PowerType then
                local Amount = tonumber(Amount)
                PredictedSpells[SpellID] = { Amount = Amount, PowerType = PowerType }

                -- do call backs
                for UnitBarF, PredictedSpell in pairs(PredictedSpells) do
                  if UnitBarF ~= 'SpellBook' and type(UnitBarF) ~= 'number' then
                    local Fn = PredictedSpell.Fn

                    if Fn then
                      Fn(UnitBarF, SpellID, Amount, PowerType)
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
end

-------------------------------------------------------------------------------
-- CheckPredictedSpells (called by event)
--
-- Scans the spell book for predicted power
-------------------------------------------------------------------------------
function Util:CheckPredictedSpells(Event)
  if PredictedSpells then
    if PredictedSpells.SpellBook == nil then
      PredictedSpells.SpellBook = 1
    end

    -- Clear spells
    for Index = 1, #PredictedSpells do
      PredictedSpells[Index] = nil
    end

    local C_SpellBook_GetSpellBookSkillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo
    local C_SpellBook_GetSpellBookItemInfo      = C_SpellBook.GetSpellBookItemInfo
    local SpellBankPlayer                       = Enum.SpellBookSpellBank.Player
    local ItemTypeFlyout                        = Enum.SpellBookItemType.Flyout
    local ItemTypeSpell                         = Enum.SpellBookItemType.Spell

    for SkillLine = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local LineInfo = C_SpellBook_GetSpellBookSkillLineInfo(SkillLine)
      local Offset = LineInfo.itemIndexOffset

      -- Only scan the book that have spells that can be used
      if LineInfo.offSpecID == nil then
        for BookIndex = Offset + 1, Offset + LineInfo.numSpellBookItems do
          local ItemInfo = C_SpellBook_GetSpellBookItemInfo(BookIndex, SpellBankPlayer)
          local ItemType, SpellID, ActionID = ItemInfo.itemType, ItemInfo.spellID, ItemInfo.actionID

          -- Handle flyout spell IDs
          if ItemType == ItemTypeFlyout then
            local _, _, NumFlyoutSlots = GetFlyoutInfo(ActionID)

            for SlotIndex = 1, NumFlyoutSlots do
              local SpellID = GetFlyoutSlotInfo(ActionID, SlotIndex)
              SetPredictedSpellInfo(SpellID)
            end
          -- Handle spell IDs
          elseif ItemType == ItemTypeSpell then
            SetPredictedSpellInfo(SpellID)
          end
        end
      end
    end
  end
end
