--
-- Main.lua
--
-- Displays different bars for each class.  Rage, Energy, Mana, Runic Power, etc.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

-------------------------------------------------------------------------------
-- Setup Ace3
-------------------------------------------------------------------------------
LibStub('AceAddon-3.0'):NewAddon(GUB, MyAddon, 'AceConsole-3.0', 'AceEvent-3.0')

-------------------------------------------------------------------------------
-- Setup shared media
-------------------------------------------------------------------------------
local LSM = LibStub('LibSharedMedia-3.0')

GUB.UnitBars = {}

------------------------------------------------------------------------------
-- Locals
--
-- UnitBarsF[Bartype].Anchor
--                      This is the unitbars anchor/location frame on screen.  Controls the showing/hiding
--                      of all unitbars.
-- UnitBarsF[BarType].Anchor.UnitBar
--                      Reference to the UnitBars[BarType] for moving.
-- UnitBarsF[BarType]:Update()
--                      Based on the bartype this will be assigned a function for displaying the data for
--                      the unitbar.
-- UnitBarsF[BarType]:StatusCheck()
--                      Based on the bartype this will be assigned a function to check the status against
--                      each unitbar.
-- UnitBarsF[BarType]:EnableScreenClamp(Enable)
--                      If true prevents any frames attached to the unitbar from moving off the screen.
--                      Otherwise frames can move off screen.
-- UnitBarsF[BarType]:EnableMouseClicks(Enable)
--                      Enables the controlling frame or frames to take mouse clicks. Each unitbar has a
--                      different method to enable frames.
-- UnitBarsF[BarType]:FrameSetScript(Enable)
--                      Based on the bartype a specific function will be called to set up scripts for
--                      anchor frame.  But sometimes a different frame needs to have scripts set.
-- UnitBarsF[BarType]:SetAttr(Object, Attr)
--                      Sets texture, font, color, etc.  To anybar except the runebar.
-- UnitBarsF[BarType].Enabled
--                      True or false.  Enabled setting for each unitbar frame.
-- UnitBarsF[BarType].Hidden
--                      True then the unitbar is not visible.
-- UnitBarsF[BarType].IsActive
--                      True then the unitbar is active else false for no activity.
--                      Defaults to true if not supported.
-- UnitBarsF[BarType].FadeOut
--                      Animation group for fadeout. This group is a child of the UnitBar frame.
-- UnitBarsF[BarType].FadeOutA
--                      Animation that contains the fade out. This animation is a child of FadeOut.
-- UnitBarsF[BarType].UnitBar
--                      This is a reference into UnitBars[BarType].
-- UnitBarsF[BarType].Width
--                      This contains the width of the unitbar.
-- UnitBarsF[BarType].Height
--                      This contains the height of the unitbar.  Width and Height are used by the unitbars
--                      alignment tool.
-- UnitBarsF[BarType].BarType
--                      Some functions need to know what frame they're working on. Also for debugging.
--
-- UnitBarsParent       This is the parent frame for all unitbars.  This frame is used to control group
--                      dragging.  Also this frame has a setscript for an OnUpdate that updates
--                      unitbars.
--
-- DefaultUnitBars      The default unitbar table.  Used for first time initialization.
--
-- UnitBarRefresh       Time in seconds before updating all the unit bars.  Once the timer
--                      goes off this is set to nil.  To start a timer UnitBarRefresh = <time to wait>
--                      Setting this to nil will cancel the timer.
-- UnitBarInterval      Time to wait before doing the next update in the onupdate handler.
--
--                      This works for health and power bars only.  If true then the updates happen thru
--                      UnitBarsOnUpdate. If false then the UnitBarEventHandler does the updates.
-- PowerTypeToString    Converts a powertype into a string: RAGE MANA, etc
-- CheckEvent           Check to see if an event is correct.  Converts an event into one of the following:
--                       * Power type value from 0 to 6.
--                       * 'health' for a health event.
--                       * 'runepower', 'runetype' for a rune event.
-- ClassToPowerType     Converts class string to the primary power type for that class.
-- PlayerClass          Name of the class for the player in english.
--
-- Backdrop             This contains a Backdrop table that has texture path names.  Since this addon uses
--                      shared media.  Texture names need to be converted into path names.  So ConvertBackdrop()
--                      needs to be called.  ConvertBackdrop then sets this table to a real backdrop table that
--                      can be used in SetBackdrop().  This table should never be reference to another table
--                      since convertbackdrop passes back a reference to this table.
--
-- InCombat             Set to true when the player is in combat.
-- InVehicle            Set to true if the player is in a vehicle.
-- IsDead               Set to true if the player is dead.
-- HasTarget            Set to true if the player has a target.
--
-- PlayerPowerType      The main power type for the player.
-- FadeOutTime          Time in seconds to fade the unitbars.
-- Initialized          Flag for OnInitializeOnce().
--
-- BgTexure             Default background texture for the backdrop.
-- BdTexture            Default border texture for the backdrop.
-- StatusBarTexure      Default bar texture for the health and power bars.
--
-- UnitBarsFList        Table used by the alignment tool.
--
-- FontSettings         Standard container for setting a font. Used by SetFontString()
--   FontType           Type of font to use.
--   FontSize           Size of the font.
--   FontStyle          Contains flags seperated by a comma: MONOCHROME, OUTLINE, THICKOUTLINE
--   FontHAlign         Horizontal alignment.  LEFT  CENTER  RIGHT
--   OffsetX            Horizontal offset position of the frame.
--   OffsetY            Vertical offset position of the frame.
--   ShadowOffset       Number of pixels to move the shadow towards the bottom right of the font.
--
-- BackdropSettings     Backdrop settings table. Must be converted into a backdrop before using.
--   BgTexture          Name of the background textured in sharedmedia.
--   BdTexture          Name of the forground texture 'statusbar' in sharedmedia.
--   BdSize             Size of the border texture thickness in pixels.
--   Padding
--     Left, Right, Top, Bottom
--                      Positive values go inwards, negative values outward.
--
-- UnitBars.IsGrouped   If true all unitbars get dragged as one object.  If false each unitbar can be dragged
--                      by its self.
-- UnitBars.IsLocked    If true all unitbars can not be clicked on.
-- UnitBars.IsClamped   If true all frames can't be moved off screen.
-- UnitBars.SmoothUpdate
--                      If true all health and power bars update 10x per second.  Other wise the bars update
--                      by waiting for events.
-- UnitBars.HideTooltips
--                      If true tooltips are not shown when mousing over unlocked bars.
-- UnitBars.FadeOutTime Time in seconds before a bar completely goes hidden.
--
-- UnitBars.Px and Py   The current location of the UnitBarsParent on the screen.
--
-- Fields found in all unitbars.
--   x, y               Current location of the unitbar anchor relative to the UnitBarsParent.
--   Status             Table that contains a list of flags marked as true or false.
--                      if a flag is found true then a statuscheck will be done to see what the
--                      bar should do. Flags with a higher priority override flags with a lower.
--                      Flags from highest priority to lowest.
--                        ShowNever        Disables and hides the unitbar.
--                        HideWhenDead     Hide the unitbar when the player is dead.
--                        HideInVehicle    Hide the unitbar if a vehicle.
--                        ShowAlways       The unitbar will be shown all the time.
--                        ShowActive       Show the unitbar if there is activity.
--                        HideNoCombat     Don't hide the unitbar when not in combat.
--
-- UnitBars health and power fields
--   TextType           What type of numeric text to display.
--                        'none'     No value gets displayed.
--                        'whole'    Value gets displayed as a Whole number.
--                        'percent'  Value gets displayed as a percentage.
--                        'max'      Value/Max value gets displayed.
--   Background
--     BackdropSettings   Contains the settings for the background, forground, and padding.
--     Color              Current color of the background texture of the border frame.
--   Bar
--     HapWidth, HapHeight
--                        The current width and height.
--     Padding            The amount of pixels to be added or subtracted from the bar texture.
--     StatusBarTexture   Texture for the bar its self.
--     Color              hash table for current color of the bar. Health bars only.
--     Color[PowerType]
--                        This array is for powerbars only.  By default they're loaded from blizzards default
--                        colors.
--   Text
--     FontSettings       Contains the settings for the text.
--     Color              Current color of the text for the bar.

--
-- Runebar fields
--   BarModeAngle         Angle in degrees in which way the bar will be displayed.  Only works in barmode.
--                        Must be a multiple of 45 degrees and not 360.
--   BarMode              If true the runes are displayed from left to right forming a bar of runes.
--   RuneSwap             If true runes can be dragged and drop to swap positions. Otherwise
--                        nothing happens when a rune is dropped on another rune.
--   CooldownDrawEdge     If true a line is drawn on the clock face cooldown animation.
--   HideCooldownFlash    If true a flash cooldown animation is not shown when a rune comes off cooldown.
--   RuneSize             Width and Hight of all the runes.
--   RunePadding          For barmode only, the amount of space between the runes.
--   RuneBarOrder         The order the runes are displayed from left to right in barmode.
--                        RuneBarOrder[Rune slot 1 to 6] = The rune frame on screen.
--   RuneLocation         Contains the x, y location of the runes on screen when not in barmode.
--
-- Combobar fields
--   ComboPadding         The amount of space in pixels between each combo point box.
--   ComboAngle           Angle in degrees in which way the bar will be displayed.
--                        Must be a multiple of 45 degrees and not 360.
--   ComboColorAll        If true then all the combo boxes are set to one color.
--                        if false then each combo box can be set a different color.
--   Background
--     BackdropSettings   Contains the settings for background, forground, and padding for each combo point box.
--     Color              Contains just one background color for all the combo point boxes.
--                        Only works when ComboColorAll is true.
--     Color[1 to 5]      Contains the background colors of all the combo point boxes.
--   Bar
--     ComboWidth         The width of each combo point box.
--     ComboHeight        The height of each combo point box.
--     Padding            Amount of padding on the forground of each combo point box.
--     StatusbarTexture   Texture used for the forground of each combo point box.
--     Color              Contains just one bar color for all the combo point boxes.
--                        Only works when ComboColorAll is true.
--     Color[1 to 5]      Contains the bar colors of all the combo point boxes.
-------------------------------------------------------------------------------
local InCombat = false
local InVehicle = false
local IsDead = false
local HasTarget = false
local PlayerPowerType = nil
local PlayerClass = nil
local Initialized = false

local UnitBarInterval = 0.10
local UnitBarTimeLeft = -1
local UnitBarRefresh = nil

local UnitBarsParent = nil
local UnitBars = nil
local UnitBarsF = {}

local BgTexture = 'Blizzard Tooltip'
local BdTexture = 'Blizzard Tooltip'
local StatusBarTexture = 'Blizzard'
local UBFontType = 'Friz Quadrata TT'

local UnitBarsFList = {}

local Backdrop = {
  bgFile   = LSM:Fetch('background', BgTexture), -- background texture
  edgeFile = LSM:Fetch('border', BdTexture),     -- border texture
  tile = true,      -- True to repeat the background texture to fill the frame, false to scale it.
  tileSize = 16,    -- Size (width or height) of the square repeating background tiles (in pixels).
  edgeSize = 12,    -- Thickness of edge segments and square size of edge corners (in pixels).
  insets = {        -- Positive values shrink the border inwards, negative expand it outwards.
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

local FontSettings = {  -- for debugging
  FontType = UBFontType,
  FontSize = 16,
  FontStyle = 'OUTLINE',
  FontHAlign = 'CENTER',
  OffsetX = 0,
  OffsetY = 0,
  ShadowOffset = 0,
}

local Defaults = {
  profile = {
    Point = 'CENTER',
    RelativePoint = 'CENTER',
    Px = 0,
    Py = 0,
    IsGrouped = false,
    IsLocked = false,
    IsClamped = true,
    SmoothUpdate = false,
    HideTooltips = false,
    FadeOutTime = 1.0,
    PlayerHealth = {
      Name = 'Player Health',
      x = 0,
      y = 0,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        ShowActive    = false,
        HideNoCombat  = false
      },
      TextType = 'percent',
      Background = {
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        HapWidth = 170,
        HapHeight = 25,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
      },
      Text = {
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      }
    },
    PlayerPower = {
      Name = 'Player Power',
      x = 0,
      y = -30,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        ShowActive    = false,
        HideNoCombat  = false
      },
      TextType = 'percent',
      Background = {
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        HapWidth = 170,
        HapHeight = 25,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
      },
      Text = {
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
    TargetHealth = {
      Name = 'Target Health',
      x = 0,
      y = -60,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        ShowActive    = false,
        HideNoCombat  = false
      },
      TextType = 'percent',
      Background = {
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        HapWidth = 170,
        HapHeight = 25,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
        Color = {r = 0, g = 1, b = 0, a = 1},
      },
      Text = {
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      }
    },
    TargetPower = {
      Name = 'Target Power',
      x = 0,
      y = -90,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        ShowActive    = false,
        HideNoCombat  = false
      },
      TextType = 'percent',
      Background = {
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        HapWidth = 170,
        HapHeight = 25,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
      },
      Text = {
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
    MainPower = {
      Name = 'Main Power',
      x = 0,
      y = -120,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        ShowActive    = false,
        HideNoCombat  = false
      },
      TextType = 'percent',
      Background = {
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {r = 0, g = 0, b = 0, a = 1},
      },
      Bar = {
        HapWidth = 170,
        HapHeight = 25,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
      },
      Text = {
        FontSettings = {
          FontType = UBFontType,
          FontSize = 16,
          FontStyle = 'NONE',
          FontHAlign = 'CENTER',
          OffsetX = 0,
          OffsetY = 0,
          ShadowOffset = 0,
        },
        Color = {r = 1, g = 1, b = 1, a = 1},
      },
    },
    RuneBar = {
      Name = 'Rune Bar',
      x = 0,
      y = -150,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = true,
        ShowActive    = false,
        HideNoCombat  = false
      },
      BarModeAngle = 90,
      BarMode = true,  -- Must be true for default or no default rune positions get created.
      CooldownDrawEdge = false,
      HideCooldownFlash = true,
      RuneSize = 22,
      RuneSwap = true,
      RunePadding = 0,
      RuneBarOrder = {[1] = 1, [2] = 2, [3] = 5, [4] = 6, [5] = 3, [6] = 4},
      RuneLocation = {[1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}},
    },
    ComboBar = {
      Name = 'Combo Bar',
      x = 0,
      y = -180,
      Status = {
        ShowNever     = false,
        HideWhenDead  = true,
        HideInVehicle = true,
        ShowAlways    = false,
        ShowActive    = true,
        HideNoCombat  = false
      },
      ComboAngle = 90,
      ComboPadding = 5,
      ComboColorAll = false,
      Background = {
        BackdropSettings = {
          BgTexture = BgTexture,
          BdTexture = BdTexture,
          BdSize = 12,
          Padding = {Left = 4, Right = 4, Top = 4, Bottom = 4},
        },
        Color = {
          {r = 0, g = 0, b = 0, a = 1},
          [1] = {r = 0, g = 0, b = 0, a = 1},
          [2] = {r = 0, g = 0, b = 0, a = 1},
          [3] = {r = 0, g = 0, b = 0, a = 1},
          [4] = {r = 0, g = 0, b = 0, a = 1},
          [5] = {r = 0, g = 0, b = 0, a = 1},
        },
      },
      Bar = {
        ComboWidth = 40,
        ComboHeight = 25,
        Padding = {Left = 4, Right = -4, Top = -4, Bottom = 4},
        StatusBarTexture = StatusBarTexture,
        Color = {
          {r = 0.75, g = 0, b = 0, a = 1},
          [1] = {r = 0.75, g = 0, b = 0, a = 1},
          [2] = {r = 0.75, g = 0, b = 0, a = 1},
          [3] = {r = 0.75, g = 0, b = 0, a = 1},
          [4] = {r = 0.75, g = 0, b = 0, a = 1},
          [5] = {r = 0.75, g = 0, b = 0, a = 1},
        }
      }
    }
  }
}


local PowerTypeToString = {[0] = 'MANA', [1] = 'RAGE', [2] = 'FOCUS', [3] = 'ENERGY', [6] = 'RUNIC_POWER'}
local ClassToPowerType = {
  DRUID = 0, HUNTER = 0, MAGE = 0, PALADIN = 0, PRIEST = 0,
  ROGUE = 3, SHAMAN = 0, WARLOCK = 0, WARRIOR = 1,  DEATHKNIGHT = 6

}
local CheckEvent = {
  UNIT_HEALTH = 'health', UNIT_MAXHEALTH = 'health',
  UNIT_MANA = 0, UNIT_MAXMANA = 0,
  UNIT_RAGE = 1, UNIT_MAXRAGE = 1,
  UNIT_FOCUS = 2, UNIT_MAXFOCUS = 2,
  UNIT_ENERGY = 3, UNIT_MAXENERGY = 3,
  UNIT_RUNIC_POWER = 6, UNIT_RUNIC_POWER = 6,
  RUNE_POWER_UPDATE = 'runepower', RUNE_TYPE_UPDATE = 'runetype',
  UNIT_COMBO_POINTS = 'combo',
  PLAYER_TARGET_CHANGED = 'targetchanged'
}

-- Share tables with the whole addon.
GUB.UnitBars.CheckEvent = CheckEvent
GUB.UnitBars.FontSettings = FontSettings
GUB.UnitBars.UnitBarsF = UnitBarsF
GUB.UnitBars.LSM = LSM
GUB.UnitBars.Defaults = Defaults

-------------------------------------------------------------------------------
-- Register and unregister functions for unitbars.
-------------------------------------------------------------------------------
local function UnitBarsRegisterEvents()
  GUB:RegisterEvent('UNIT_HEALTH', 'UnitBarsUpdate')
  GUB:RegisterEvent('UNIT_MAXHEALTH', 'UnitBarsUpdate')
  GUB:RegisterEvent('UNIT_RAGE', 'UnitBarsUpdate')
  GUB:RegisterEvent('UNIT_MAXRAGE', 'UnitBarsUpdate')
  GUB:RegisterEvent('UNIT_MANA', 'UnitBarsUpdate')
  GUB:RegisterEvent('UNIT_MAXMANA', 'UnitBarsUpdate')
  GUB:RegisterEvent('UNIT_ENERGY', 'UnitBarsUpdate')
  GUB:RegisterEvent('UNIT_MAXENERGY', 'UnitBarsUpdate')
  GUB:RegisterEvent('UNIT_RUNIC_POWER', 'UnitBarsUpdate')
  GUB:RegisterEvent('UNIT_MAXRUNIC_POWER', 'UnitBarsUpdate')
  GUB:RegisterEvent('UNIT_COMBO_POINTS', 'UnitBarsUpdate')
end

local function UnitBarsUnregisterEvents()
  print('unregister events')
  GUB:UnregisterEvent('UNIT_HEALTH')
  GUB:UnregisterEvent('UNIT_MAXHEALTH')
  GUB:UnregisterEvent('UNIT_RAGE')
  GUB:UnregisterEvent('UNIT_MAXRAGE')
  GUB:UnregisterEvent('UNIT_MANA')
  GUB:UnregisterEvent('UNIT_MAXMANA')
  GUB:UnregisterEvent('UNIT_ENERGY')
  GUB:UnregisterEvent('UNIT_MAXENERGY')
  GUB:UnregisterEvent('UNIT_RUNIC_POWER')
  GUB:UnregisterEvent('UNIT_MAXRUNIC_POWER')
  GUB:UnregisterEvent('UNIT_COMBO_POINTS')
end

local function UnitBarsRegisterSpecialEvents()
  GUB:RegisterEvent('RUNE_POWER_UPDATE', 'UnitBarsUpdate')
  GUB:RegisterEvent('RUNE_TYPE_UPDATE', 'UnitBarsUpdate')
end

-------------------------------------------------------------------------------
-- Register status events for unitbars
-------------------------------------------------------------------------------
local function UnitBarsStatusRegisterEvents()
  GUB:RegisterEvent('UNIT_ENTERED_VEHICLE', 'UnitBarsUpdateStatus')
  GUB:RegisterEvent('UNIT_EXITED_VEHICLE', 'UnitBarsUpdateStatus')
  GUB:RegisterEvent('PLAYER_REGEN_ENABLED', 'UnitBarsUpdateStatus')
  GUB:RegisterEvent('PLAYER_REGEN_DISABLED', 'UnitBarsUpdateStatus')
  GUB:RegisterEvent('PLAYER_TARGET_CHANGED', 'UnitBarsUpdateStatus')
  GUB:RegisterEvent('UNIT_DISPLAYPOWER', 'UnitBarsUpdateStatus')
  GUB:RegisterEvent('PLAYER_DEAD', 'UnitBarsUpdateStatus')
  GUB:RegisterEvent('PLAYER_UNGHOST', 'UnitBarsUpdateStatus')
  GUB:RegisterEvent('PLAYER_ALIVE', 'UnitBarsUpdateStatus')
end

-------------------------------------------------------------------------------
-- InitializePowerTypeColor
--
-- Copy blizzard's power colors into the Defaults profile.
-------------------------------------------------------------------------------
local function InitializePowerTypeColor()
  local UnitBars = Defaults.profile

  for PowerType, Power in pairs(PowerTypeToString) do
    local Color = PowerBarColor[Power]
    local r, g, b = Color.r, Color.g, Color.b
    for BarType, UB in pairs(UnitBars) do
      if BarType == 'PlayerPower' or BarType == 'TargetPower' or BarType == 'MainPower' then
        local Bar = UB.Bar
        if Bar.Color == nil then
          Bar.Color = {}
        end
        Bar.Color[PowerType] = {r = r, g = g, b = b, a = 1}
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
-- CopyTableValues
--
-- Copies all the values and sub table values of one table to another.
--
-- Usage: CopyTableValues(Source, Dest)
--
-- Source    The source table you're copying data from.
-- Dest      The destination table the data is being copied to.
--
-- NOTE: The source and dest tables must have the same keys.
-------------------------------------------------------------------------------
function GUB.UnitBars:CopyTableValues(Source, Dest)
  for k, v in pairs(Source) do
    if type(v) == 'table' then
      -- Make sure value is not nil.
      if Dest[k] then
        GUB.UnitBars:CopyTableValues(v, Dest[k])
      end

    -- Check to see if key exists in destination before setting value
    elseif Dest[k] then
      print(k, v)
      Dest[k] = v
    end
  end
end

-------------------------------------------------------------------------------
-- AngleToOffset
--
-- Passes back an x y offset based on angle.
--
-- Usage XO, YO = AngleToOffset(XOffset, YOffset, Angle)
--
-- XOffset      The offset value for X.
-- YOffset      The offset Value for Y.
-- Angle        Must be 0 5 90 135 180 225 270 or 315.
--
-- XO           Negative or positive value of XOffset depending on angle.
-- YO           Negative or positive value of YOffset depending on angle.
-------------------------------------------------------------------------------
function GUB.UnitBars:AngleToOffset(XO, YO, Angle)
  local XOffset = 0
  local YOffset = 0

  -- Set the offsets.
  if Angle == 90 or Angle == 270 then
    XOffset = XO
  elseif Angle == 0 or Angle == 180 then
    YOffset = YO
  elseif Angle == 45 or Angle == 135 or Angle == 225 or Angle == 315 then
    XOffset = XO
    YOffset = YO
  end

  -- Calculate the direction.
  local Angle = math.rad(Angle)
  if math.sin(Angle) < 0 then
    XOffset = -XOffset
  end
  if math.cos(Angle) < 0 then
    YOffset = -YOffset
  end
  return XOffset, YOffset
end

-------------------------------------------------------------------------------
-- ConvertBackdrop
--
-- Converts BackdropSettings that can be used in SetBackdrop()
--
-- Usage: Backdrop = GUB.UnitBars:ConvertBackdrop(Bd)
--
-- Bd               Usually from saved unitbar data that has shared media
--                  strings for textures.
-- Backdrop         A table that is usable by blizzard. This table always
--                  reference the local table in main.lua
-------------------------------------------------------------------------------
function GUB.UnitBars:ConvertBackdrop(Bd)
  Backdrop.bgFile   = LSM:Fetch('background', Bd.BgTexture)
  Backdrop.edgeFile = LSM:Fetch('border', Bd.BdTexture)
  Backdrop.tile = false
  Backdrop.tileSize = 16
  Backdrop.edgeSize = Bd.BdSize
  local Insets = Backdrop.insets
  local Padding = Bd.Padding
  Insets.left = Padding.Left
  Insets.right = Padding.Right
  Insets.top = Padding.Top
  Insets.bottom = Padding.Bottom

  return Backdrop
end

-------------------------------------------------------------------------------
-- SetFontString
--
-- Set new settings to fontstring.
--
-- Usage: GUB.UnitBars:SetFontString(FontString, FS)
--
-- FontString        The frame the contains a fontstring.
-- FS                Reference to the FontSettings table.
-------------------------------------------------------------------------------
function GUB.UnitBars:SetFontString(FontString, FS)
  FontString:SetFont(LSM:Fetch('font', FS.FontType), FS.FontSize, FS.FontStyle)
  FontString:SetPoint('TOPLEFT', FS.OffsetX, FS.OffsetY)
  FontString:SetPoint('BOTTOMRIGHT', FS.OffsetX, FS.OffsetY)
  FontString:SetJustifyH(FS.FontHAlign)
  FontString:SetJustifyV('CENTER')
  FontString:SetShadowOffset(FS.ShadowOffset, -FS.ShadowOffset)
end

-------------------------------------------------------------------------------
-- RestoreRelativePoints
--
-- Restores lost relative points that are relative to its parent and returns
-- back the restored points.
--
-- Usage: x, y = RestoreRelativePoints(Frame)
--
-- Frame   The frame you want to restore relative points.
--
-- Note: This function can be accessed by the whole mod
-------------------------------------------------------------------------------
function GUB.UnitBars:RestoreRelativePoints(Frame)
  local Parent = Frame:GetParent()
  local Scale = Frame:GetScale()

  -- Get the left and top location of the current frame and scale it.
  local Left = Frame:GetLeft() * Scale
  local Top = Frame:GetTop() * Scale

  -- Get the left and top of the parent frame. Parent frame will always be set to a scale of 1.
  local LeftP = Parent:GetLeft()
  local TopP = Parent:GetTop()

  -- Calculate the X, Y location relative to the parent frame.
  local x = (Left - LeftP) / Scale
  local y = (Top - TopP) / Scale

  -- Set the frame location relative to the parent frame.
  Frame:ClearAllPoints()
  Frame:SetPoint('TOPLEFT', x, y)

  return x, y
end

-------------------------------------------------------------------------------
-- UpdateUnitBars
--
-- Displays all the unitbars unless Event, Unit are specified.
-------------------------------------------------------------------------------
local function UpdateUnitBars(Event, ...)
  for _, UBF in pairs(UnitBarsF) do
    UBF:Update(Event, ...)
  end
end

-------------------------------------------------------------------------------
-- HideUnitBar
--
-- Usage: HideUnitBar(UnitBarF, HideBar)
--
-- UnitBarF  Unitbar frame to hide or show.
-- HideBar   Hide the bar if equal to true otherwise show.
--
-- Note: If the unitbar frame is set to hide in vehicle then the bar will not
--       be shown even if HideBar is equal to false.
-------------------------------------------------------------------------------
local function HideUnitBar(UnitBarF, HideBar)
  local FadeOut = UnitBarF.FadeOut

  if HideBar and not UnitBarF.Hidden then
    if UnitBars.FadeOutTime > 0 then

      -- Fade the unitbar out then hide it.
      -- Set fadeout frames to hide them selves after they fade out.
      FadeOut:SetScript('OnFinished', function(self)
                                        self:GetParent():Hide()
                                        self:SetScript('OnFinished', nil)
                                      end)
      FadeOut:Play()
    else
      UnitBarF.Anchor:Hide()
    end
    UnitBarF.Hidden = true
  else
    if not HideBar and UnitBarF.Hidden then
      if FadeOut:IsPlaying() then
        FadeOut:Stop()
      end
      UnitBarF.Hidden = false
      UnitBarF.Anchor:Show()
    end
  end
end

--*****************************************************************************
--
-- Unitbar script functions (script/event)
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- UnitBarTooltip
--
-- Display a tooltip of a frame that has a name.
--
-- This function is called by setscript OnEnter and OnLeave
-------------------------------------------------------------------------------
function GUB.UnitBars:UnitBarTooltip(Hide)
  if UnitBars.HideTooltips then
    return
  end
  if not Hide then
    GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
    GameTooltip:AddLine(self.Name)
    GameTooltip:Show()
  else
    GameTooltip:Hide()
  end
end

-------------------------------------------------------------------------------
-- UnitBarsUpdate
--
-- Event handler for updating the unitbars. Also can be used to update all bars.
--
-- Usage: UnitBarsUpdate()
--
--   Updates all unitbars.
--
-- Usage: UnitBarsUpdate(Event, ...)
--
--   Update the unitbars that match Event and ...
-------------------------------------------------------------------------------
function GUB:UnitBarsUpdate(Event, ...)

  -- Start unit bar refresh timer.
  UnitBarRefresh = 4.0
  UpdateUnitBars(Event, ...)
end

-------------------------------------------------------------------------------
-- UnitBarsUpdateStatus
--
-- Event handler that hides/shows the unitbars based on their current settings.
-- This also updates all unitbars that are visible.
-------------------------------------------------------------------------------
function GUB:UnitBarsUpdateStatus(Event)

  -- Set the vehicle and combat flags
  InCombat = UnitAffectingCombat('player') == 1
  InVehicle = UnitHasVehicleUI('player')
  IsDead = UnitIsDeadOrGhost('player') == 1
  HasTarget = UnitExists('target') == 1
  for _, UBF in pairs(UnitBarsF) do
    UBF:StatusCheck()

    -- Update incase some unitbars went from disabled to enabled.
    UBF:Update()
  end
end

-------------------------------------------------------------------------------
-- UnitBarsOnUpdate
--
-- This OnUpdate is attached to UnitBarsParent frame.
-- Main OnUpdate handler unit bars.
--
-- self     Frame that the OnUpdate is called from.
-- Elapsed  Amount of time since the last OnUpdate call.
-------------------------------------------------------------------------------
local function UnitBarsOnUpdate(self,  Elapsed)
  local UpdateBars = false

  -- Check for smooth update
  if UnitBars.SmoothUpdate then
    UnitBarTimeLeft = UnitBarTimeLeft - Elapsed

    -- Check if timeleft reached zero.
    -- Don't update the bars more times than what interval is set at.
    if UnitBarTimeLeft < 0 then
      UnitBarTimeLeft = UnitBarInterval
      UpdateBars = true
    end
  end

  -- Refresh unit bars if a refresh timer was set.
  if UnitBarRefresh then

    -- Timer is not nil start counting down.
    UnitBarRefresh = UnitBarRefresh - Elapsed
    if UnitBarRefresh < 0 then
      UnitBarRefresh = nil
      UpdateBars = true
    end
  end
  if UpdateBars then
    UpdateUnitBars()
  end
end

-------------------------------------------------------------------------------
-- UnitBarStartMoving
--
-- If UnitBars.IsGrouped is true then the unitbar parent frame will be moved.
-- Otherwise just the unitbar frame will be moved.
--
-- Note: To move a frame the unitbars anchor needs to be moved.
--       This function returns false if it didn't do anything otherwise true.
-------------------------------------------------------------------------------
function GUB.UnitBars:UnitBarStartMoving(Button)

  -- Check to see if shift/alt/control and left button are held down
  if Button ~= 'LeftButton' or not IsModifierKeyDown() then
    return false
  end

  -- Set the moving flag.
  -- Group move check.
  if UnitBars.IsGrouped then
    UnitBarsParent.IsMoving = true
    UnitBarsParent:StartMoving()
  else
    self.IsMoving = true
    self:StartMoving()
  end

  return true
end

-------------------------------------------------------------------------------
-- UnitBarStopMoving
--
-- Same as above except it stops moving and saves the new coordinates.
-------------------------------------------------------------------------------
function GUB.UnitBars:UnitBarStopMoving(Button)
  if UnitBarsParent.IsMoving then
    UnitBarsParent.IsMoving = false
    UnitBarsParent:StopMovingOrSizing()

    -- Save the new position of the ParentFrame.
    UnitBars.Point, _, UnitBars.RelativePoint, UnitBars.Px, UnitBars.Py = UnitBarsParent:GetPoint()
  elseif self.IsMoving then
    self.IsMoving = false
    self:StopMovingOrSizing()

    -- StartMoving() sets the coordinates of the frame relative to UIParent, so we
    -- Need to recalculate where it is relative to frames parent.
    -- Update the UnitBar data with the new coordinates.
    self.UnitBar.x, self.UnitBar.y = GUB.UnitBars:RestoreRelativePoints(self)
  end
end

--*****************************************************************************
--
-- UnitBar assigned functions
--
-- Usage: UnitBarsF[BarType]:Update(Event, ...)
--
--    This function can take a variable number of parameters that get passed from
--    the event handler.  The unitbar that its called on checks to see if the
--    event data matches with what that unitbar is suppose to show.  If it doesn't then
--    the unitbar will not be updated.
--
-- Usage: UnitBarsF[BarType]:Update()
--
--    This will just update the bar, no checks are done.
--
-- Usage: UnitBarsF[BarType]:StatusCheck()
--
--    Check the status of the unitbar frame.
--
-- Usage: UnitBarsF[BarType]:FrameSetScript(Enable)
--
--    Sets up scripts for the unitbar frame.
--    Enable    If true then scripts get enabled otherwise disabled.
--
-- Usage: UnitBarsF[BarType]:EnableScreenClamp(Enable)
--
--    Clamps the current unitbar to the screen.

-- Usage: UnitBarsF[BarType]:EnableMouseClicks(Enable)
--
--    Sets up mouse clicks to be captured for this unitbar frame.
--
-- Usage: UnitBarsF[BarType]:SetAttr(Object, Attr)
--
--    Look at SetAttr assigned functions in HealthPowerBar.lua and ComboBar.lua.
--    Runebar doesn't support attributes and calling a SetAttr on a runebar will do nothing.
--
-- NOTE: Any function labled as a unitbar assigned function shouldn't be called directly.
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- StatusCheckShowNever (StatusCheck) [UnitBar assigned function]
--
-- Disables the unitbar frame if the ShowNever flag is set.
-- Returns true if the unitbar was enabled.
-------------------------------------------------------------------------------
local function StatusCheckShowNever(UnitBarF)

  -- Enable the unitbar frame if the ShowNever flag is not set.
  UnitBarF.Enabled = not UnitBarF.UnitBar.Status.ShowNever

  return UnitBarF.Enabled
end

-------------------------------------------------------------------------------
-- StatusCheckShowHide (StatusCheck) [UnitBar assigned function]
--
-- Checks the status on the unitbar frame to see if it should be shown/hidden.
-------------------------------------------------------------------------------
local function StatusCheckShowHide(UnitBarF)
  local ShowUnitBar = UnitBarF.Enabled
  local UB = UnitBarF.UnitBar
  local Status = UB.Status

  if ShowUnitBar then

    -- Hide if the HideWhenDead status is set.
    if IsDead and Status.HideWhenDead then
      ShowUnitBar = false

    -- Hide if in a vehicle if the HideInVehicle status is set
    elseif InVehicle and Status.HideInVehicle then
      ShowUnitBar = false

    -- Show the unitbar if ShowAlways status is set.
    elseif Status.ShowAlways then
      ShowUnitBar = true

    -- Get the active status based on ShowActive when not in combat.
    elseif not InCombat and Status.ShowActive then
      ShowUnitBar = UnitBarF.IsActive

    -- Hide if not in combat with the HideNoCombat status.
    elseif not InCombat and Status.HideNoCombat then
      ShowUnitBar = false
    end
  end

  -- Make all unitbars visible when they are not locked. Can't override ShowNever.
  if not UnitBars.IsLocked and not Status.ShowNever then
    ShowUnitBar = true
  end

  -- Hide/show the unitbar.
  HideUnitBar(UnitBarF, not ShowUnitBar)
end

-------------------------------------------------------------------------------
-- StatusCheckTarget (StatusCheck) [UnitBar assigned function]
--
-- Disable/Enable the target unitbar frame.
-------------------------------------------------------------------------------
local function StatusCheckTarget(UnitBarF)
  if StatusCheckShowNever(UnitBarF) then

    -- If the player has a target then enable this unitbar frame.
    UnitBarF.Enabled = HasTarget
  end
  StatusCheckShowHide(UnitBarF)
end

-------------------------------------------------------------------------------
-- StatusCheckMainPower (StatusCheck) [UnitBar assigned function]
--
-- Disable/Enable the mainpower unitbar frame.
-------------------------------------------------------------------------------
local function StatusCheckMainPower(UnitBarF)
  if StatusCheckShowNever(UnitBarF) then

    -- Enable the mainpower bar if the player is in a different form.
    UnitBarF.Enabled = PlayerPowerType ~= UnitPowerType('player')
  end
  StatusCheckShowHide(UnitBarF)
end

------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- SetFunction
--
-- Sets a function to a list of bartypes in the function table.
-- This is only used with the function below.
--
-- Usage: SetFunction(Func, FunctionName, Fn, ...)
--
-- Func          The function table.
-- FunctionName  The name of the function to assign to each bartype.
-- Fn            The function to assign to each bartype.
-- ...           List of bartypes.
-------------------------------------------------------------------------------
local function SetFunction(Func, FunctionName, Fn, ...)
  for i = 1, select('#', ...) do
    Func[select(i, ...)][FunctionName] = Fn
  end
end

-------------------------------------------------------------------------------
-- UnitBarsAssignFunctions
--
-- Assigns the functions to all of the unitbars.
-- This function is only called once.
-- The functions in here are only added to the unitbar if its found in the
-- unitbarf table.
-------------------------------------------------------------------------------
local function UnitBarsAssignFunctions()

  -- Build a temporary function table.
  local Func = {}
  for BarType, UB in pairs(Defaults.profile) do
    if type(UB) == 'table' then
      Func[BarType] = {}
    end
  end

  -- Update functions.

  local n = 'Update'  -- UnitBarF[]:Update(Event, Unit, [...])
  local f = nil

  Func.PlayerHealth[n] = function(self, Event, Unit)
                           if Unit == nil or Unit == 'player' then
                             GUB.HapBar.UpdateHealthBar(self, Event, 'player')
                           end
                         end
  Func.PlayerPower[n]  = function(self, Event, Unit)
                           if Unit == nil or Unit == 'player' then
                             GUB.HapBar.UpdatePowerBar(self, Event, 'player', nil)
                           end
                         end
  Func.TargetHealth[n] = function(self, Event, Unit)
                           if Unit == nil or Unit == 'target' then
                             GUB.HapBar.UpdateHealthBar(self, Event, 'target')
                           end
                         end
  Func.TargetPower[n]  = function(self, Event, Unit)
                           if Unit == nil or Unit == 'target' then
                             GUB.HapBar.UpdatePowerBar(self, Event, 'target', nil)
                           end
                         end
  Func.MainPower[n]    = function(self, Event, Unit)
                           if  Unit == nil or Unit == 'player' then
                             GUB.HapBar.UpdatePowerBar(self, Event, 'player', PlayerPowerType)
                           end
                         end
  Func.RuneBar[n]      = function(self, Event, ...)
                           if Event ~= nil then
                             GUB.RuneBar.UpdateRuneBar(self, Event, ...)
                           end
                         end
  Func.ComboBar[n]     = function(self, Event, Unit)
                           if Unit == nil or Unit == 'player' then
                             GUB.ComboBar.UpdateComboBar(self, Event)
                           end
                         end

  -- StatusCheck functions.

  n = 'StatusCheck'  -- UnitBarF[]:StatusCheck()
  f = function(self)
        StatusCheckShowNever(self)
        StatusCheckShowHide(self)
      end

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'RuneBar')
  SetFunction(Func, n, StatusCheckTarget, 'TargetHealth', 'TargetPower', 'ComboBar')
  Func.MainPower[n] = StatusCheckMainPower

  -- Enable mouse click functions.

  n = 'EnableMouseClicks' -- UnitBarF[]:EnableMouseClicks(Enable)
  f = GUB.HapBar.EnableMouseClicksHap

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'TargetHealth', 'TargetPower', 'MainPower')
  SetFunction(Func, n, GUB.RuneBar.EnableMouseClicksRune, 'RuneBar')
  SetFunction(Func, n, GUB.ComboBar.EnableMouseClicksCombo, 'ComboBar')

  -- Enable clamp to screen functions.

  n = 'EnableScreenClamp' -- UnitBarF[]:EnableScreenClamp(Enable)
  f = GUB.HapBar.EnableScreenClampHap

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'TargetHealth', 'TargetPower', 'MainPower')
  SetFunction(Func, n, GUB.RuneBar.EnableScreenClampRune, 'RuneBar')
  SetFunction(Func, n, GUB.ComboBar.EnableScreenClampCombo, 'ComboBar')

  -- Set script functions.

  n = 'FrameSetScript'  -- UnitBarF[]:FrameSetScript(Enable)
  f = GUB.HapBar.FrameSetScriptHap

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'TargetHealth', 'TargetPower', 'MainPower')
  SetFunction(Func, n, GUB.RuneBar.FrameSetScriptRune, 'RuneBar')
  SetFunction(Func, n, GUB.ComboBar.FrameSetScriptCombo, 'ComboBar')

  -- Set attribute functions.

  n = 'SetAttr' -- UnitBarF[]:SetAttr(Object, Attr)
  f = GUB.HapBar.SetAttrHap

  SetFunction(Func, n, f, 'PlayerHealth', 'PlayerPower', 'TargetHealth', 'TargetPower', 'MainPower')
  Func.RuneBar[n] = function() end
--  SetFunction(Func, n, function() end, 'RuneBar')
  SetFunction(Func, n, GUB.ComboBar.SetAttrCombo, 'ComboBar')

  -- Add the functions to the unitbars frame table.

  for BarType, UBF in pairs(UnitBarsF) do
    for FuncName, FuncCall in pairs(Func[BarType]) do
      UBF[FuncName] = Func[BarType][FuncName]
    end
  end
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
-- Usage: UnitBarSetAllOption()
--
-- Activates the current settings in UnitBars.
--
-- SmoothUpdate
-- IsLocked
-- IsClamped
-- FadeOutTime
-------------------------------------------------------------------------------
function GUB.UnitBars:UnitBarsSetAllOptions()

  -- Apply the settings.
  if UnitBars.SmoothUpdate then
    UnitBarsUnregisterEvents()
  else
    UnitBarsRegisterEvents()
  end
  for _, UBF in pairs(UnitBarsF) do
    UBF:EnableMouseClicks(not UnitBars.IsLocked)
    UBF:EnableScreenClamp(UnitBars.IsClamped)
  end
  if UnitBars.FadeOutTime then
    for _, UBF in pairs(UnitBarsF) do
      UBF.FadeOutA:SetDuration(UnitBars.FadeOutTime)
    end
  end
end

-------------------------------------------------------------------------------
-- UnitBarsSetScript
--
-- Set up script handlers for the unitbars.
--
-- Usage: UnitBarsSetScript(Enable)
--
-- Enable     If true scripts get set otherwise they get disabled.
-------------------------------------------------------------------------------
local function UnitBarsSetScript(Enable)

  -- Set the unitbar parent frame to call UnitBarsOnUpdate.
  if Enable then
    UnitBarsParent:SetScript('OnUpdate', UnitBarsOnUpdate)
  else
    UnitBarsParent:SetScript('OnUpdate', nil)
  end
  for _, UBF in pairs(UnitBarsF) do
    UBF:FrameSetScript(Enable)
  end
end

-------------------------------------------------------------------------------
-- SetUnitBarsLayout
--
-- Sets all the unitbars with new data.
-------------------------------------------------------------------------------
local function SetUnitBarsLayout()

  -- Set the unitbar parent frame values
  UnitBarsParent:ClearAllPoints()
  UnitBarsParent:SetPoint(UnitBars.Point, 'UIParent', UnitBars.RelativePoint, UnitBars.Px, UnitBars.Py)
  UnitBarsParent:SetWidth(1)
  UnitBarsParent:SetHeight(1)

  for BarType, UnitBarF in pairs(UnitBarsF) do
    local UB = UnitBars[BarType]

    local Anchor = UnitBarF.Anchor

    -- Set the unitbar frame values.
    Anchor:ClearAllPoints()
    Anchor:SetPoint('TOPLEFT', UB.x, UB.y)
    Anchor:SetWidth(1)
    Anchor:SetHeight(1)

    -- Set a reference in the unitbar frame to UnitBars[BarType]
    UnitBarF.UnitBar = UB
    Anchor.UnitBar = UB

    if BarType == 'RuneBar' then
      GUB.RuneBar:SetRuneBarLayout(UnitBarF)
    elseif BarType == 'ComboBar' then
      GUB.ComboBar:SetComboBarLayout(UnitBarF)
    else
      GUB.HapBar:SetHapBarLayout(UnitBarF)
    end

    -- Set the IsActive flag to true.
    UnitBarF.IsActive = true

    -- Disable the unitbar.
    UnitBarF.Enabled = false

    -- Set the hidden flag.
    UnitBarF.Hidden = true

    -- Hide the frame.
    UnitBarF.Anchor:Hide()
  end
end

-------------------------------------------------------------------------------
-- CreateUnitBars
--
-- Creates all the bars used by GalvinUnitBars.
-------------------------------------------------------------------------------
local function CreateUnitBars(UnitBarDB)

  -- Create the unitbar parent frame.
  UnitBarsParent = CreateFrame('Frame', nil, UIParent)
  UnitBarsParent:SetMovable(true)

  for BarType, UB in pairs(Defaults.profile) do
    if type(UB) == 'table' then
      local UnitBarF = {}

      -- Create the unitbar base as the anchor frame.
      local Anchor = CreateFrame('Frame', nil, UnitBarsParent)

      -- Hide the anchor
      Anchor:Hide()

      -- Make the unitbar's anchor movable.
      Anchor:SetMovable(true)

      if BarType == 'RuneBar' then
        GUB.RuneBar:CreateRuneBar(UnitBarF, Anchor)
      elseif BarType == 'ComboBar' then
        GUB.ComboBar:CreateComboBar(UnitBarF, Anchor)
      else
        GUB.HapBar:CreateHapBar(UnitBarF, Anchor)
      end
      if next(UnitBarF) then
        -- Create an animation for fade out.
        local FadeOut = Anchor:CreateAnimationGroup()
        local FadeOutA = FadeOut:CreateAnimation('Alpha')

        -- Set the animation group values.
        FadeOut:SetLooping('NONE')
        FadeOutA:SetChange(-1)

        -- Save the animation and border to the unitbar frame.
        UnitBarF.FadeOut = FadeOut
        UnitBarF.FadeOutA = FadeOutA

        -- Save the bartype.
        UnitBarF.BarType = BarType

        -- Save the anchor.
        UnitBarF.Anchor = Anchor

        UnitBarsF[BarType] = UnitBarF
      end
    end
  end
  UnitBarsAssignFunctions()
end

--*****************************************************************************
--
-- Unitbar setter functions (global to the whole mod).
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- AlignUnitBars
--
-- Aligns one or more unitbars with a single unitbar.
--
-- Subfunction of GUB.Options:CreateAlignUnitBarsOptions()
--
-- Usage: AlignUnitBars(AlignmentBar, BarsToAlign, Align, VPadEnabled, VPadding)
--
-- AlignmentBar     Unitbar to align other bars with.
-- BarsToAlign      List of unitbars to align with AlignmentBar
-- Align            'left' Align each bar to the left side of the AlignmentBar
--                  'right' Align each bar to the right side the AlignmentBar.
-- VPadEnabled      If true VPadding will be applied, otherwise ignored.
-- VPadding         Each bar will also be aligned from top down spaced apart in
--                  pixels equal to VPadding.
-------------------------------------------------------------------------------
local function SortY(a, b)
  return a.UBF.UnitBar.y > b.UBF.UnitBar.y
end

function GUB.UnitBars:AlignUnitBars(AlignmentBar, BarsToAlign, Align, VPadEnabled, VPadding)

  -- Initialize the array
  for i, UBFL in ipairs(UnitBarsFList) do
    if UBFL.Valid then
      UBFL.Valid = false
    end
  end

  -- Add the BarsToAlign data to UnitBarsFList.
  local UnitBarI = 1
  local UBFL = nil
  for BarType, v in pairs(BarsToAlign) do
    if v then
      if UnitBarsFList[UnitBarI] == nil then
        UBFL = {}
        UBFL.Valid = false
        UnitBarsFList[UnitBarI] = UBFL
      end
      UBFL = UnitBarsFList[UnitBarI]
      UBFL.UBF = UnitBarsF[BarType]
      UBFL.Valid = true
      UnitBarI = UnitBarI + 1
    end
  end
  UBFL = {}
  UBFL.Valid = true
  UBFL.UBF = UnitBarsF[AlignmentBar]
  UnitBarsFList[UnitBarI] = UBFL
  local MaxUnitBars = UnitBarI

  -- Sort the table.
  table.sort(UnitBarsFList, SortY)

  local AWidth = 0
  local AHeight = 0
  local AlignmentBarI = 0

  -- Find the alignementbar first
  for i, UBFL in ipairs(UnitBarsFList) do
    if UBFL.Valid and UBFL.UBF.BarType == AlignmentBar then
      AlignmentBarI = i
      local UBF = UBFL.UBF
      AWidth = UBF.Width
      AHeight = UBF.Height
    end
  end

  -- Get the starting x, y location
  local StartX = UnitBars[AlignmentBar].x
  local StartY = UnitBars[AlignmentBar].y

  -- DirectionY tells us which direction to go in.
  for DirectionY = -1, 1, 2 do
    local x = StartX
    local y = StartY
    local XOffset = 0
    local i = AlignmentBarI + DirectionY * -1

    -- Initialize the starting location for vertical padding.
    -- Only if going down.
    if VPadEnabled and DirectionY == -1 then
      y = y + (AHeight + VPadding) * DirectionY
    end

    while i > 0 and i <= MaxUnitBars do
      local UBFL = UnitBarsFList[i]
      if i ~= AlignmentBarI and UBFL.Valid then
        local UBF = UBFL.UBF
        XOffset = 0
        if Align == 'right' then
          XOffset = AWidth - UBF.Width
        end
        UBF.UnitBar.x = x + XOffset

        -- Check for vertical padding.
        if VPadEnabled then

          if DirectionY == -1 then
            UBF.UnitBar.y = y
          end

          -- Increment the y based on DirectionY
          y = y + (UBF.Height + VPadding) * DirectionY

          if DirectionY == 1 then
            UBF.UnitBar.y = y
          end
        end

        -- Update the unitbars location.
        local Anchor = UBF.Anchor
        local UB = UBF.UnitBar

        Anchor:ClearAllPoints()
        Anchor:SetPoint('TOPLEFT', UB.x, UB.y)
      end
      i = i + DirectionY * -1
    end
  end

end


--*****************************************************************************
--
-- Addon Enable/Disable functions
--
-- Placed at the bottom was tired of doing function forwarding.
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Profile management
-------------------------------------------------------------------------------
function GUB:ProfileChanged(Event, Database, NewProfileKey)

  -- set Unitbars to the new database.
  UnitBars = Database.profile

  -- Set unitbars to the new profile in options.lua.
  GUB.Options:SendOptionsData(UnitBars, nil, nil)

  GUB:OnEnable()
end

-------------------------------------------------------------------------------
-- SharedMedia management
-------------------------------------------------------------------------------
function GUB:MediaUpdate(Name, MediaType, Key)
  for _, UBF in pairs(UnitBarsF) do
    if MediaType == 'border' or MediaType == 'background' then
      UBF:SetAttr('bg', 'backdrop')
    elseif MediaType == 'statusbar' then
      UBF:SetAttr('bar', 'texture')
    elseif MediaType == 'font' then
      UBF:SetAttr('text', 'font')
    end
  end
end

-------------------------------------------------------------------------------
-- One time initialization.
-------------------------------------------------------------------------------
local function OnInitializeOnce()
  if not Initialized then

    -- Get the player class.
    _, PlayerClass = UnitClass('player')

    -- Get the main power type for the player.
    PlayerPowerType = ClassToPowerType[PlayerClass]

    -- Set PlayerClass and PlayerPowerType in options.lua
    GUB.Options:SendOptionsData(nil, PlayerClass, PlayerPowerType)

    -- Initialize the options panel.
    -- Delaying Options init to make sure PlayerClass is accessible first.
    GUB.Options:OnInitialize()

    GUB.UnitBarsDB.RegisterCallback(GUB, 'OnProfileReset', 'ProfileChanged')
    GUB.UnitBarsDB.RegisterCallback(GUB, 'OnProfileChanged', 'ProfileChanged')
    GUB.UnitBarsDB.RegisterCallback(GUB, 'OnProfileCopied', 'ProfileChanged')

    LSM.RegisterCallback(GUB, 'LibSharedMedia_Registered', 'MediaUpdate')

    Initialized = true
  end
end

-------------------------------------------------------------------------------
-- Initialize when addon is loaded.
-------------------------------------------------------------------------------
function GUB:OnInitialize()

  -- Add blizzards powerbar colors to defaults.
  InitializePowerTypeColor()

  -- Load the unitbars database
  GUB.UnitBarsDB = LibStub('AceDB-3.0'):New('GalvinUnitBarsDB', Defaults, true)

  -- Save the unitbars data from the current profile.
  UnitBars = GUB.UnitBarsDB.profile

  -- Set unitbars to the new profile in options.lua.
  GUB.Options:SendOptionsData(UnitBars, nil, nil)

  -- Create the unitbars.
  CreateUnitBars()

  GUBfdata = UnitBarsF -- debugging 00000000000000000000000000000000000
end

-------------------------------------------------------------------------------
-- Initialize after addon is enabled.
-------------------------------------------------------------------------------
function GUB:OnEnable()

  -- Do one time initialization.
  OnInitializeOnce()

  -- Update all the unitbars according to the new data.
  SetUnitBarsLayout()

  -- Set up the scripts.
  UnitBarsSetScript(true)

  -- Initialize special events.
  UnitBarsRegisterSpecialEvents()

  -- Initialize the status events.
  UnitBarsStatusRegisterEvents()

  -- Set the unitbars global settings
  GUB.UnitBars:UnitBarsSetAllOptions()

  -- Set the unitbars status and show the unitbars.
  GUB:UnitBarsUpdateStatus()

    GSB = GUB -- for debugging OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
  GUBdata = UnitBars
end

function GUB:OnDisable()

  -- Disable all the scripts.
  UnitBarsSetScript(false)

  -- Hide all the bars.
  for _, UBF in pairs(UnitBarsF) do
    UBF.Anchor:Hide()
  end

  -- All registered events automatically get disabled by ace3.
end
