--
-- Options.lua
--
-- Handles all the options for GalvinUnitBars

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local DefaultUB = GUB.DefaultUB
local DUB = DefaultUB.Default.profile

local TriggerOptions = {}
local TextOptions = {}
GUB.TextOptions = TextOptions
GUB.TriggerOptions = TriggerOptions

local Main = GUB.Main
local Bar = GUB.Bar
local Options = GUB.Options

local ConvertPowerTypeHAP = Main.ConvertPowerTypeHAP
local ConvertPowerType = Main.ConvertPowerType
local ConvertCombatColor = Main.ConvertCombatColor
local LSM = Main.LSM

-- localize some globals.
local _, _G, print =
      _, _G, print
local floor, strupper, strlower, strfind, format, strsplit, strsub, strjoin =
      floor, strupper, strlower, strfind, format, strsplit, strsub, strjoin
local tonumber, gsub, tinsert, wipe, strsub =
      tonumber, gsub, tinsert, wipe, strsub
local ipairs, pairs, type, next, sort =
      ipairs, pairs, type, next, sort
local InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, GameTooltip, GetSpellInfo =
      InterfaceOptionsFrame, HideUIPanel, GameMenuFrame, LibStub, GameTooltip, GetSpellInfo
local GetAlternatePowerInfoByID =
      GetAlternatePowerInfoByID

-------------------------------------------------------------------------------
-- Locals
--
-- Options.MainOptionsOpen       If true then the options window is opened. Otherwise closed.
-- Options.AlignSwapOptionsOpen  If true then the align and swap options window is opened.  otherwise closed.
-- Options.Importing             if true then importing options are open
-- Options.Exporting             if true then exporting options are open
-- Options.ImportSourceBarType   Contains the bartype of the bar that started the import
-- Options.ExportData            Contains the string of the export
--
-- SlashOptions                  Options only used by slash commands. This is accessed
--                               by typing '/gub'.
--
-- DoFunctions                   Table used to save and call functions thru DoFunction()
--
-- AlignSwapAnchor               Contains the current anchor of the Unitbar that was clicked on to open
--                               the align and swap options window.
--
-- ImportOptionsData             String: Contains the import string to be imported
--
-- MainOptionsHideFrame          Frame used for when the main options window is closed.
-------------------------------------------------------------------------------
local AceConfigRegistery = LibStub('AceConfigRegistry-3.0')
local AceConfig = LibStub('AceConfig-3.0')
local AceDBOptions = LibStub('AceDBOptions-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')

-- Addon Constants
local AddonName = GetAddOnMetadata(MyAddon, 'Title')
local AddonMainOptions = MyAddon .. 'options'
local AddonAlignSwapOptions = MyAddon .. 'options2'
local AddonOptionsToGUB = MyAddon .. 'options3'
local AddonMessageBoxOptions = MyAddon .. 'options4'
local AddonSlashOptions = MyAddon

local DoFunctions = {}
local MainOptionsHideFrame = CreateFrame('Frame')
local AlignSwapOptionsHideFrame = CreateFrame('Frame')
local OutOfCombatFrame = CreateFrame('Frame')

local SlashOptions
local OptionsToGUB
local MainOptions
local AlignSwapOptions
local MessageBoxOptions
local AlignSwapAnchor

local ClipBoard
local TableData
local MenuButtons
local AltPowerBarSearch = ''

local DebugText = ''

local RefreshFrame = CreateFrame('Frame')
local OptionsTreeData = {
  Order = {},
  Expanded = {},
  Root = {},
  BranchKeys = {},
  AutoExpandBarType = false,
  EnableCount = 0,
}

local o = {

  -- Test mode
  TestModeUnitLevelMin = -1,
  TestModeUnitLevelMax = 200,
  TestModeOnCooldownMin = 0,
  TestModeOnCooldownMax = 6,
  TestModeEnergizeMin = 0,
  TestModeEnergizeMax = 7,
  TestModeShardMin = 0,
  TestModeShardMax = 5,
  TestModeShardFragmentMin = 0,
  TestModeShardFragmentMax = 50,
  TestModeHolyPowerMin = 0,
  TestModeHolyPowerMax = 5,
  TestModeChiMin = 0,
  TestModeChiMax = 6,
  TestModePointsMin = 0,
  TestModePointsMax = 6,
  TestModeArcaneChargesMin = 0,
  TestModeArcaneChargesMax = 4,
  TestModeStaggerMin = 0,
  TestModeStaggerMax = 4,
  TestModeStaggerPauseMin = 0,
  TestModeStaggerPauseMax = 3,
  TestModeAltPowerMin = 0,
  TestModeAltPowerMax = 100,
  TestModeAltMaxPowerMin = 0,
  TestModeAltMaxPowerMax = 99,
  TestModeAltPowerBarIDMin = 0,
  TestModeAltPowerBarIDMax = 500,
  TestModeAltPowerTimeMin = 0,
  TestModeAltPowerTimeMax = 60,

  -- Animation for all unitbars.
  AnimationOutTime = 1,
  AnimationInTime = 1,

  -- Bar fill FPS for all unitbars
  BarFillFPSMin = 10,
  BarFillFPSMax = 200,

  -- Text settings.
  MaxTextLines = 4,
  MaxValueNames = 6,

  -- Font text settings
  FontOffsetXMin = -150,
  FontOffsetXMax = 150,
  FontOffsetYMin = -150,
  FontOffsetYMax = 150,
  FontShadowOffsetMin = 0,
  FontShadowOffsetMax = 10,
  FontSizeMin = 1,
  FontSizeMax = 180,
  FontFieldWidthMin = 20,
  FontFieldWidthMax = 400,
  FontFieldHeightMin = 10,
  FontFieldHeightMax = 200,

  -- Trigger settings
  TriggerAnimateSpeedMin = 0.01,
  TriggerAnimateSpeedMax = 1,
  TriggerTextureScaleMin = 0.2,
  TriggerTextureScaleMax = 5,
  TriggerBarOffsetAllMin = -100,
  TriggerBarOffsetAllMax = 100,
  TriggerBarOffsetLeftMin = -100,
  TriggerBarOffsetLeftMax = 100,
  TriggerBarOffsetRightMin = -100,
  TriggerBarOffsetRightMax = 100,
  TriggerBarOffsetTopMin = -100,
  TriggerBarOffsetTopMax = 100,
  TriggerBarOffsetBottomMin = -100,
  TriggerBarOffsetBottomMax = 100,
  TriggerFontSizeMin = -180,
  TriggerFontSizeMax = 180,

  -- Layout settings
  LayoutBorderPaddingMin = -25,
  LayoutBorderPaddingMax = 50,
  LayoutRotationMin = 45,
  LayoutRotationMax = 360,
  LayoutSlopeMin = -100,
  LayoutSlopeMax = 100,
  LayoutPaddingMin = -50,
  LayoutPaddingMax = 50,
  LayoutSmoothFillMaxTimeMin = 0,
  LayoutSmoothFillMaxTimeMax = 2,
  LayoutSmoothFillSpeedMin = 0.01,
  LayoutSmoothFillSpeedMax = 1,
  LayoutTextureScaleMin = 0.55,
  LayoutTextureScaleMax = 5,
  LayoutAnimationInTimeMin = 0,
  LayoutAnimationInTimeMax = 1,
  LayoutAnimationOutTimeMin = 0,
  LayoutAnimationOutTimeMax = 1,
  LayoutAlignOffsetXMin = - 50,
  LayoutAlignOffsetXMax = 50,
  LayoutAlignOffsetYMin = -50,
  LayoutAlignOffsetYMax = 50,
  LayoutAlignPaddingXMin = -50,
  LayoutAlignPaddingXMax = 50,
  LayoutAlignPaddingYMin = -50,
  LayoutAlignPaddingYMax = 50,

  -- Backdrop and bar settings.
  UnitBarPaddingMin = -20,
  UnitBarPaddingMax = 20,

  -- Backdrop settings (Region and Background).
  UnitBarBgTileSizeMin = 1,
  UnitBarBgTileSizeMax = 100,
  UnitBarBorderSizeMin = 2,
  UnitBarBorderSizeMax = 32,

  -- Align and swap
  AlignSwapWidth = 415,
  AlignSwapHeight = 205,

  AlignSwapPaddingMin = -50,
  AlignSwapPaddingMax = 500,
  AlignSwapOffsetMin = -50,
  AlignSwapOffsetMax = 500,
  AlignSwapAdvancedMinMax = 25,

  -- Main options window size
  MainOptionsWidth = 850,
  MainOptionsHeight = 500,

  -- Attribute options
  UnitBarScaleMin = 0.10,
  UnitBarScaleMax = 4,
  UnitBarAlphaMin = 0.10,
  UnitBarAlphaMax = 1,

  -- Max Percent options
  UnitBarMaxPercentMin = .5,
  UnitBarMaxPercentMax = 2,

  -- Absorb size options
  UnitBarAbsorbSizeMin = .01,
  UnitBarAbsorbSizeMax = 1,

  -- Bar rotation options
  UnitBarRotationMin = -90,
  UnitBarRotationMax = 180,

  -- Bar size options
  UnitBarSizeMin = 15,
  UnitBarSizeMax = 500,
  UnitBarSizeAdvancedMinMax = 25,

  RuneOffsetXMin = -50,
  RuneOffsetXMax = 50,
  RuneOffsetYMin = -50,
  RuneOffsetYMax = 50,
}

local ConvertPlayerClass = {
  DEATHKNIGHT      = 'Death Knight',
  DEMONHUNTER      = 'Demon Hunter',
  DRUID            = 'Druid',
  HUNTER           = 'Hunter',
  MAGE             = 'Mage',
  MONK             = 'Monk',
  PALADIN          = 'Paladin',
  PRIEST           = 'Priest',
  ROGUE            = 'Rogue',
  SHAMAN           = 'Shaman',
  WARLOCK          = 'Warlock',
  WARRIOR          = 'Warrior',
  ['Death Knight'] = 'DEATHKNIGHT',
  ['Demon Hunter'] = 'DEMONHUNTER',
  Druid            = 'DRUID',
  Hunter           = 'HUNTER',
  Mage             = 'MAGE',
  Monk             = 'MONK',
  Paladin          = 'PALADIN',
  Priest           = 'PRIEST',
  Rogue            = 'ROGUE',
  Shaman           = 'SHAMAN',
  Warlock          = 'WARLOCK',
  Warrior          = 'WARRIOR',

  -- Indexed
  'DEATHKNIGHT',   -- 1
  'DEMONHUNTER',   -- 2
  'DRUID',         -- 3
  'HUNTER',        -- 4
  'MAGE',          -- 5
  'MONK',          -- 6
  'PALADIN',       -- 7
  'PRIEST',        -- 8
  'ROGUE',         -- 9
  'SHAMAN',        -- 10
  'WARLOCK',       -- 11
  'WARRIOR'        -- 12
}

local LSMDropdown = {
  StatusBar = LSM:HashTable('statusbar'),
  Border = LSM:HashTable('border'),
  Background = LSM:HashTable('background'),
  Font = LSM:HashTable('font'),
  Sound = LSM:HashTable('sound'),
}

local FontStyleDropdown = {
  NONE = 'None',
  OUTLINE = 'Outline',
  THICKOUTLINE = 'Thick Outline',
 -- ['NONE, MONOCHROME'] = 'No Outline, Mono',  Disabled due to causing a client crash.
  ['OUTLINE, MONOCHROME'] = 'Outline, Mono',
  ['THICKOUTLINE, MONOCHROME'] = 'Thick Outline, Mono',
}

local PositionDropdown = {
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

local DirectionDropdown = {
  HORIZONTAL = 'Horizontal',
  VERTICAL = 'Vertical'
}

local RuneModeDropdown = {
  rune = 'Runes',
  bar = 'Bars',
  runebar = 'Bars and Runes'
}

local FrameStrataDropdown = {
  'Background',
  'Low',
  'Medium (default)',
  'High',
  'Dialog',
  'Full Screen',
  'Full Screen Dialog',
  'Tooltip',
}

local ConvertFrameStrata = {
  BACKGROUND        = 1,
  LOW               = 2,
  MEDIUM            = 3,
  HIGH              = 4,
  DIALOG            = 5,
  FULLSCREEN        = 6,
  FULLSCREEN_DIALOG = 7,
  TOOLTIP           = 8,
  'BACKGROUND',           -- 1
  'LOW',                  -- 2
  'MEDIUM',               -- 3
  'HIGH',                 -- 4
  'DIALOG',               -- 5
  'FULLSCREEN',           -- 6
  'FULLSCREEN_DIALOG',    -- 7
  'TOOLTIP',              -- 8
}

local AnimationTypeDropdown = {
  alpha = 'Alpha',
  scale = 'Scale',
}

Options.o = o
Options.AceConfigDialog = AceConfigDialog
Options.AddonMainOptions = AddonMainOptions
Options.Importing = false
Options.LSMDropdown = LSMDropdown
Options.FontStyleDropdown = FontStyleDropdown
Options.PositionDropdown = PositionDropdown

--*****************************************************************************
--
-- Options Utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- FindMenuItem
--
-- Searches for a Value in an indexed array. Returns the Index found. or 1
--
-- Table       Any indexed array
-- Value       Value to search for.  Must be an exact match. Case is not sensitive.
--
-- Returns:
--   Index    Table element containing value
--   Item     Returns the item found in the menu in lowercase. If item is not found then
--            this equals the first item in the menu.
-------------------------------------------------------------------------------
local function FindMenuItem(Table, Value)
  local Item

  Value = strlower(Value)
  for Index = 1, #Table do
    local i = strlower(Table[Index])

    if Index == 1 then
      Item = i
    end
    if i == Value then
      return Index, i
    end
  end
  return 1, Item
end

-------------------------------------------------------------------------------
-- RefreshMainOptions
--
-- Refreshes the option panels.
-- Use this if something needs updating.
-------------------------------------------------------------------------------
function GUB.Options:RefreshMainOptions()
  AceConfigRegistery:NotifyChange(AddonMainOptions)
end

-------------------------------------------------------------------------------
-- RefreshAlignSwapOptions
--
-- Refreshes the option panels.
-- Use this if something needs updating.
-------------------------------------------------------------------------------
function GUB.Options:RefreshAlignSwapOptions()
  AceConfigRegistery:NotifyChange(AddonAlignSwapOptions)
end

-------------------------------------------------------------------------------
-- CloseMainOptions
--
-- Closes the main options window.
-------------------------------------------------------------------------------
function GUB.Options:CloseMainOptions()
  AceConfigDialog:Close(AddonMainOptions)
end

-------------------------------------------------------------------------------
-- CloseAlignSwapOptions
--
-- Closes the aling and swap options window
-------------------------------------------------------------------------------
function GUB.Options:CloseAlignSwapOptions()
  AceConfigDialog:Close(AddonAlignSwapOptions)
end

-------------------------------------------------------------------------------
-- Flag
--
-- Returns true if the flag is nil or its value if it does.
--
-- NilValue   The value returned if the Value is nil.
-------------------------------------------------------------------------------
local function Flag(NilValue, Value)
  if Value == nil then
    return NilValue
  else
    return Value
  end
end

-------------------------------------------------------------------------------
-- HideTooltip
--
-- Hides the tooltip based on a boolean value. Boolean value gets returned.
-- Used in for buttons that get disabled so the tooltip will close.
--
-- If true then tooltip is hidden, otherwise nothing is done.
-------------------------------------------------------------------------------
local function HideTooltip(Action)
  if Action then
    GameTooltip:Hide()
  end
  return Action
end

-------------------------------------------------------------------------------
-- DoFunction
--
-- Stores a list of functions that can be called on to change settings.
--
-- Object          Object to save the function under.
-- Name            Name to use to call the function.
--                 if 'clear' then all the functions under Object are erased.
-- Fn              Function to be saved. If fn is nil then FunctionName() gets called.
--                 if 'erase' then will erase the function.
--
-- Returns:
--   Function      The function that was passed.
-------------------------------------------------------------------------------
function GUB.Options:DoFunction(Object, Name, Fn)
  if Fn then

    -- Save the function under Object FunctionName
    local DoFunction = DoFunctions[Object]

    if DoFunction == nil then
      DoFunction = {}
      DoFunctions[Object] = DoFunction
    end

    if Fn == 'erase' then
      Fn = nil
    end
    DoFunction[Name] = Fn

    return Fn
  elseif Name == 'clear' then
    if DoFunctions[Object] then

      -- Wipe the table instead of nilling. Incase this function gets called thru DoFunction.
      wipe(DoFunctions[Object])
    end
  elseif Name then

    -- Call function by name
    DoFunctions[Object][Name]()
  else
    -- Call all functions if Fn not passed.
    for _, DF in pairs(DoFunctions) do
      for _, Fn in pairs(DF) do
        Fn()
      end
    end
  end
end

-------------------------------------------------------------------------------
-- CreateSpacer
--
-- Creates type 'description' for full width.  This is used to create a blank
-- line so that option elements appear in certain places on the screen.
--
-- Order         Order number
-- Width         Optional width.
-- HiddenFn      If not nil then will supply a function that will make the
--               spacer hidden or not.
-------------------------------------------------------------------------------
local function CreateSpacer(Order, Width, HiddenFn)
  return {
    type = 'description',
    name = '',
    order = Order,
    width = Width or 'full',
    hidden = HiddenFn,
  }
end

-------------------------------------------------------------------------------
-- RefreshEnable
--
-- Does a refresh options if the enable menu tree button is clicked on
-- This causes any autoexpanded trees to be closed
--
-- NOTES:  When the enable button is clicked. A count is set to see how
--         times the name function is called inside the RefreshButton
--         this buttin is hidden so it doesn't appear in the options.
--         Then a setscript to run on the next frame will call the function
--         to check to see how many times the name function was called.
--         if its more once.  Then the enable button was clicked on.
--
--         The refreshing flag is to prevent recursion
-------------------------------------------------------------------------------
local function RefreshFrameOnUpdate()
  local Refreshing = OptionsTreeData.Refreshing

  RefreshFrame:SetScript('OnUpdate', nil)
  if OptionsTreeData.EnableCount > 1 and not Refreshing then
    Refreshing = true
    OptionsTreeData.AutoExpandBarType = false
    Options:RefreshMainOptions()
  else
    Refreshing = false
  end
  OptionsTreeData.Refreshing = Refreshing
  OptionsTreeData.EnableCount = 0
end

local function RefreshEnable()
  if Main.Gdata.AutoExpand then
    OptionsTreeData.EnableCount = OptionsTreeData.EnableCount + 1
    RefreshFrame:SetScript('OnUpdate', RefreshFrameOnUpdate)
  end
end

-------------------------------------------------------------------------------
-- AddOptionsTree
--
-- Creates and adds to an options tree. Creates a tab view on the right
--
-- TreeGroups         Table containing the tree view on the left
-- BarType            This is used for the key name
-- Name               Name that will appear in the menu tree on the left
-- Order              Order number position in the tree
-------------------------------------------------------------------------------
local function AddOptionsTree(TreeGroups, BarType, Order, Name, Desc)
  local Expanded = OptionsTreeData.Expanded
  local Gdata = Main.Gdata
  Expanded[BarType] = false

  local OptionsTree = {
    type = 'group',
    name = Name,
    order = Order,
    desc = Desc,
    childGroups = 'tab',
    args = {
      Expand = {
        type = 'description',
        order = 0,
        name = function()
                 if Gdata.AutoExpand and OptionsTreeData.AutoExpandBarType ~= BarType then
                   OptionsTreeData.AutoExpandBarType = BarType
                   Options:RefreshMainOptions()
                 end
               end,
        hidden = true
      },
      AutoExpand = {
        type = 'toggle',
        width = 'normal',
        name = 'Auto Expand',
        order = 1,
        get = function()
                return Gdata.AutoExpand
              end,
        set = function(Info, Value)
                Gdata.AutoExpand = Value
                OptionsTreeData.AutoExpand = false
                if not Value then
                  OptionsTreeData.AutoExpandBarType = false
                  --Options:RefreshMainOptions()
                end
              end,
        disabled = function()
                     return Gdata.ExpandAll
                   end,
      },
      ExpandAll = {
        type = 'toggle',
        width = 'normal',
        name = 'Expand All',
        order = 2,
        get = function()
                return Gdata.ExpandAll
              end,
        set = function(Info, Value)
                Gdata.ExpandAll = Value
                --Options:RefreshMainOptions()
              end,
        disabled = function()
                     return Gdata.AutoExpand
                   end,
      },
    },
  }

  OptionsTreeData.Root[BarType] = OptionsTree
  OptionsTreeData.Order[BarType] = Order
  OptionsTreeData.BranchKeys[BarType] = {}
  TreeGroups[BarType] = OptionsTree
end

-------------------------------------------------------------------------------
-- RemoveOptionsTree
--
-- Removes the tree and all branches
-- And the options from TreeGroups
-------------------------------------------------------------------------------
local function RemoveOptionsTree(TreeGroups, BarType)
  if TreeGroups[BarType] then

    -- Remove all branches
    for TableName in pairs(OptionsTreeData.BranchKeys[BarType]) do
      TreeGroups[TableName] = nil
    end

    OptionsTreeData.Root[BarType] = nil
    OptionsTreeData.Order[BarType] = nil
    OptionsTreeData.BranchKeys[BarType] = nil
    OptionsTreeData.AutoExpandBarType = false
    OptionsTreeData.EnableCount = 0
    TreeGroups[BarType] = nil
  end
end

-------------------------------------------------------------------------------
-- AddTabGroup
--
-- Adds a tab group to an exsiting options tree.
-- This can be called more than once to add more tabs
--
-- BarType               The menu tree of bartype
-- Order                 Order in the tabs
-- Name                  Used if DialogInline is true
-- DialogInline          true or false
-- Options               Options group
-------------------------------------------------------------------------------
local function AddTabGroup(BarType, Order, Name, DialogInline, Options)
  if Options then
    local OptionArgs = OptionsTreeData.Root[BarType].args

    Options.dialogInline = DialogInline

    if DialogInline then
      OptionArgs[Name] = {
        type = 'group',
        name = Name,
        order = Order + 10,
        args = {
          TabOptions = Options
        },
      }
    else
      OptionArgs[Name] = Options
    end
  end
end

-------------------------------------------------------------------------------
-- AddOptionsBranch
--
-- Adds a branch to the options tree
--
-- TreeGroups Table containing the tree view on the left
-- BarType    Tree to add an options branch to
-- TableName  Keyname to use
-- Options    Options to be added
-------------------------------------------------------------------------------
local function AddOptionsBranch(TreeGroups, BarType, TableName, Options)
  local Name = Options.name
  local Gdata = Main.Gdata

  Options.order = OptionsTreeData.Order[BarType] + Options.order / 10000

  -- Add hidden to make tree expand and collapse
  local Hidden = Options.hidden
  Options.hidden = function()
    local Hide

    if Gdata.ExpandAll then
      Hide = false
    else
      Hide = OptionsTreeData.AutoExpandBarType ~= BarType
    end
    if Hide then
      return true
    else
      return Hidden and Hidden() or Hide
    end
  end

  Options.name = function()
    return format('|cffffffff   %s|r', type(Name) == 'function' and Name() or Name)
  end

  local BranchTableName = format('%s%s', TableName, BarType)
  OptionsTreeData.BranchKeys[BarType][BranchTableName] = true
  TreeGroups[BranchTableName] = Options
end

--*****************************************************************************
--
-- Options creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- CreateToGUBOptions
--
-- Creates an option that takes you to the GUB options frame.
--
-- Order     Position in the options list.
-- Name      Name of the options.
-- Desc      Description when mousing over the options name.
-------------------------------------------------------------------------------
local function OnHideToGUBOptions()
  MainOptionsHideFrame:SetScript('OnHide', nil)
  Bar:SetHighlightFont('off', Main.UnitBars.HideTextHighlight)
  Options.MainOptionsOpen = false
end

local function OpenOptionsOOC()
  OutOfCombatFrame:SetScript('OnEvent', nil)

  -- Hide blizz blizz options if it's opened.
  if InterfaceOptionsFrame:IsVisible() then
    InterfaceOptionsFrame:Hide()
    -- Hide the UI panel behind blizz options.
    HideUIPanel(GameMenuFrame)
  end
  Bar:SetHighlightFont('on', Main.UnitBars.HideTextHighlight)
  Options.MainOptionsOpen = true
  -- Open a movable options frame.
  AceConfigDialog:SetDefaultSize(AddonMainOptions, o.MainOptionsWidth, o.MainOptionsHeight)
  AceConfigDialog:Open(AddonMainOptions)
  -- Set the OnHideFrame's frame parent to AceConfigDialog's options frame.
  MainOptionsHideFrame:SetParent(AceConfigDialog.OpenFrames[AddonMainOptions].frame)
  -- When hidden call OnHideToGUBOptions for close.
  MainOptionsHideFrame:SetScript('OnHide', OnHideToGUBOptions)
end

local function OpenOptions()
  if not Main.InCombat then
    OpenOptionsOOC()
  else
    OutOfCombatFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
    OutOfCombatFrame:SetScript('OnEvent', OpenOptionsOOC)
    print(DefaultUB.InCombatOptionsMessage2)
  end
end

local function CreateToGUBOptions(Order, Name, Desc)
  local ToGUBOptions = {
    type = 'execute',
    name = Name,
    order = Order,
    desc = Desc,
    func = function()
             OpenOptions()
           end,
  }
  return ToGUBOptions
end

-------------------------------------------------------------------------------
-- CreateSlashOptions()
--
-- Returns a slash options table for unitbars.
-------------------------------------------------------------------------------
local function CreateSlashOptions()
  local SlashOptions = {
    type = 'group',
    name = 'slash command',
    order = 1,
    args = {
      about = {
        type = 'execute',
        name = 'about',
        order = 2,
        func = function()
                 print(AddonName, format('Version %.2f', DefaultUB.Version / 100))
               end,
      },
      config = CreateToGUBOptions(2, '', 'Opens a movable options frame'),
      c = CreateToGUBOptions(3, '', 'Same as config'),
    },
  }
  return SlashOptions
end

-------------------------------------------------------------------------------
-- CreateOptionsToGUB()
--
-- Creates options to be used in blizz options that takes you to GUB options
-- that can be moved.
------------------------------------------------------------------------------
local function CreateOptionsToGUB()
  local OptionsToGUB = {
    name = AddonName,
    type = 'group',
    order = 1,
    args = {
      ToGUBOptions = CreateToGUBOptions(1, 'GUB Options', 'Opens GUB options'),
    },
  }
  return OptionsToGUB
end

-------------------------------------------------------------------------------
-- CreateColorAllOptions
--
-- Creates all color options that support multiple colors.
--
-- Subfunction of CreateBackdropOptions()
-- Subfunction of CreateBarOptions()
-- Subfunction of CreateTextOptions()
-- Subfunction of CreateMoreLayoutRuneBarOptions()
--
--
-- BarType            Type of options being created.
-- TableName          Where the color is stored.
-- ColorPath          Table path to where the color data is stored.
-- KeyName            Name of the color table.
-- Order              Position in the options list.
-- Name               Name of the options.
-- DisableFn          Disabled options based on a function
--
-- ColorAllOptions  Options table for the bartype.
-------------------------------------------------------------------------------
local function CreateColorAllOptions(BarType, TableName, ColorPath, KeyName, Order, Name, DisableFn)
  local UBF = Main.UnitBarsF[BarType]
  local Names = UBF.Names

  local ColorAllOptions = {
    type = 'group',
    name = Name,
    order = Order,
    get = function(Info)
            local ColorIndex = tonumber(Info[#Info])
            local c = Main:GetUB(BarType, ColorPath)

            if ColorIndex > 0 then
              c = c[ColorIndex]
            end
            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local ColorIndex = tonumber(Info[#Info])
            local c = Main:GetUB(BarType, ColorPath)

            if ColorIndex > 0 then
              c = c[ColorIndex]
            end
            c.r, c.g, c.b, c.a = r, g, b, a

            -- Set the color to the bar
            UBF:SetAttr(TableName, KeyName)
          end,
    args = {
      ColorAllToggle = {
        type = 'toggle',
        name = 'All',
        order = 1,
        desc = 'Everything can be set to one color',
        get = function()
                return Main:GetUB(BarType, ColorPath).All
              end,
        set = function(Info, Value)
                Main:GetUB(BarType, ColorPath).All = Value

                -- Refresh colors when changing between all and normal.
                UBF:SetAttr(TableName, KeyName)
              end,
        disabled = function()
                     return DisableFn and DisableFn() or false
                   end,
      },
      ['0'] = {
        type = 'color',
        name = 'Color',
        order = 2,
        hasAlpha = true,
        desc = 'Set everything to one color',
        hidden = function()
                   return not Main:GetUB(BarType, ColorPath).All
                 end,
        disabled = function()
                     return DisableFn and DisableFn() or false
                   end,
      },
      Spacer = CreateSpacer(3),
    },
  }
  local CAOA = ColorAllOptions.args
  local Offset = Main:GetUB(BarType, ColorPath .. '._Offset', DUB) or 0

  for ColorIndex = 1, #Main:GetUB(BarType, ColorPath) do
    local Name = Names[ColorIndex + Offset]
    local ColorOption = {}

    --- Create the color table
    ColorOption.type = 'color'
    ColorOption.name = Name
    ColorOption.order = ColorIndex + 3
    ColorOption.hasAlpha = true
    ColorOption.hidden = function()
                           return Main:GetUB(BarType, ColorPath).All
                         end
    ColorOption.disabled = function()
                             return DisableFn and DisableFn() or false
                           end
    -- Add it to the options table
    CAOA[format('%s', ColorIndex)] = ColorOption
  end

  return ColorAllOptions
end

-------------------------------------------------------------------------------
-- GroupDisabled
--
-- Returns true if the DisableGroup should be disabled
--
-- Subfunction of CreateColorAllSelectOptions()
--
-- BarType     Type options being created.
-- TableName   Name of the table in the unitbar
-- UBF         Unitbar Frame
-------------------------------------------------------------------------------
local function GroupDisabled(BarType, TableName, UBF)
  local BurningEmbers = UBF.UnitBar.Layout.BurningEmbers

  if BarType == 'FragmentBar' then
    if TableName == 'BackgroundShard' or TableName == 'BarShard' then
      return BurningEmbers
    elseif TableName == 'BackgroundEmber' or TableName == 'BarEmber' then
      return not BurningEmbers
    end
  else
    return false
  end
end

-------------------------------------------------------------------------------
-- CreateColorAllSelectOptions
--
-- Allows multiple color all options to be selected by choosing a check box
--
-- BarType            Type of options being created.
-- TableName          Where the color is stored.
-- TableType          bar, bg, border
-- Order              Position in the options list.
-- Name               Name of the options.
--
-- NOTES: This saves the current menu selection into SelectedMenuButtonName
--        So if you had Green Fire selected on Ember.  The table would be like this:
--        SelectedMenuButtonName = { EmberShard = 'Green Fire' }
--        Each background and bar has one of these that uses this function in the defaults.
-------------------------------------------------------------------------------
local function CreateColorAllSelectOptions(BarType, TableType, TableName, Order, Name)
  local UBF = Main.UnitBarsF[BarType]
  local TabButtons

  if BarType == 'FragmentBar' then
    if TableType == 'bar' then
      TabButtons = {
        Color                 = { KeyName = 'Color',             ColorPath = '.Color',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or UBF.GreenFire end },
        ['Green Fire']        = { Keyname = 'ColorGreen',        ColorPath = '.ColorGreen',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or not UBF.GreenFire end },
      }
    end
    if TableType == 'barfull' then
      TabButtons = {
        Color                 = { KeyName = 'ColorFull',         ColorPath = '.ColorFull',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or UBF.GreenFire end },
        ['Green Fire']        = { KeyName = 'ColorFullGreen',    ColorPath = '.ColorFullGreen',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or not UBF.GreenFire end },
      }
    end
    if TableType == 'bg' then
      TabButtons = {
        Color                 = { KeyName = 'Color',             ColorPath = '.Color',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or UBF.GreenFire end },
        ['Green Fire']        = { Keyname = 'ColorGreen',        ColorPath = '.ColorGreen',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or not UBF.GreenFire end },
      }
    end
    if TableType == 'border' then
      TabButtons = {
        Color                 = { KeyName = 'BorderColor',       ColorPath = '.BorderColor',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or UBF.GreenFire or
                                                                not UBF.UnitBar[TableName].EnableBorderColor end },
        ['Green Fire']        = { Keyname = 'BorderColorGreen',  ColorPath = '.BorderColorGreen',
                                  DisableFn = function() return GroupDisabled(BarType, TableName, UBF) or not UBF.GreenFire or
                                                                not UBF.UnitBar[TableName].EnableBorderColor end },
      }
    end
  end
  if BarType == 'RuneBar' then
    if TableType == 'bar' then
      TabButtons = {
        Blood                 = { KeyName = 'ColorBlood',        ColorPath = '.ColorBlood',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 1 end },
        Frost                 = { KeyName = 'ColorFrost',        ColorPath = '.ColorFrost',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 2 end },
        Unholy                = { KeyName = 'ColorUnholy',       ColorPath = '.ColorUnholy',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 3 end },
      }
    end
    if TableType == 'bg' then
      TabButtons = {
        Blood                 = { KeyName = 'ColorBlood',        ColorPath = '.ColorBlood',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 1 end },
        Frost                 = { KeyName = 'ColorFrost',        ColorPath = '.ColorFrost',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 2 end },
        Unholy                = { KeyName = 'ColorUnholy',       ColorPath = '.ColorUnholy',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 3 end },
      }
    end
    if TableType == 'border' then
      TabButtons = {
        Blood                 = { KeyName = 'BorderColorBlood',  ColorPath = '.BorderColorBlood',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 1 end },
        Frost                 = { KeyName = 'BorderColorFrost',  ColorPath = '.BorderColorFrost',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 2 end },
        Unholy                = { KeyName = 'BorderColorUnholy', ColorPath = '.BorderColorUnholy',
                                  DisableFn = function() return UBF.PlayerSpecialization ~= 3 end },
      }
    end
  end

  local ColorAllSelectOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    args = {},
  }

  local Args = ColorAllSelectOptions.args

  -- Create the menu buttons
  for TabName, TabButton in pairs(TabButtons) do
    local DisableFn = TabButton.DisableFn
    local ColorAllOptions = CreateColorAllOptions(BarType, TableName, TableName .. TabButton.ColorPath, TabButton.KeyName, 100, TabName, DisableFn)

    ColorAllOptions.name = function()
                             if DisableFn() then
                               return TabName
                             else
                               return TabName .. ' *'
                             end
                           end
    Args[TabName] = ColorAllOptions
  end

  return ColorAllSelectOptions
end

-------------------------------------------------------------------------------
-- CreateBackdropOptions
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType     Type options being created.
-- TableName   Background + TableName
-- Order       Position in the options list.
-- Name        Name of the options.
-------------------------------------------------------------------------------
local function CreateBackdropOptions(BarType, TableName, Order, Name)
  local UBF = Main.UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local BackdropOptions = {
    type = 'group',
    childGroups = 'tab',
    name = function()
             local Tag = ''
             if BarType == 'FragmentBar' and TableName ~= 'Region' then
               if UBF.GreenFire then
                 Tag = ' [Green Fire]'
               end
               if not GroupDisabled(BarType, TableName, UBF) then
                 return Name .. Tag .. ' *'
               end
             end
             return Name .. Tag
           end,
    order = Order,
    args = {
      General = {
        type = 'group',
        name = 'General',
        order = 1,
        get = function(Info)
                local KeyName = Info[#Info]
                local Value = UBF.UnitBar[TableName][KeyName]

                if KeyName ~= 'EnableBorderColor' and strfind(KeyName, 'Color') then
                  return Value.r, Value.g, Value.b, Value.a
                else
                  return Value
                end
              end,
        set = function(Info, Value, g, b, a)
                local KeyName = Info[#Info]

                if KeyName == 'EnableBorderColor' then
                  UBF.UnitBar[TableName][KeyName] = Value
                  if BarType == 'FragmentBar' then

                    UBF:SetAttr(TableName, 'BorderColor')
                    UBF:SetAttr(TableName, 'BorderColorGreen')
                  elseif BarType == 'RuneBar' then

                    UBF:SetAttr(TableName, 'BorderColorBlood')
                    UBF:SetAttr(TableName, 'BorderColorFrost')
                    UBF:SetAttr(TableName, 'BorderColorUnholy')
                  else
                    UBF:SetAttr(TableName, 'BorderColor')
                  end

                elseif strfind(KeyName, 'Color') then
                  local c = UBF.UnitBar[TableName][KeyName]

                  c.r, c.g, c.b, c.a = Value, g, b, a
                  UBF:SetAttr(TableName, KeyName)
                else
                  UBF.UnitBar[TableName][KeyName] = Value
                  UBF:SetAttr(TableName, KeyName)
                end
              end,
        args = {
          BorderTexture = {
            type = 'select',
            name = 'Border',
            order = 1,
            dialogControl = 'LSM30_Border',
            values = LSMDropdown.Border,
            disabled = function()
                         return GroupDisabled(BarType, TableName, UBF)
                       end,
          },
          BgTexture = {
            type = 'select',
            name = 'Background',
            order = 2,
            dialogControl = 'LSM30_Background',
            values = LSMDropdown.Background,
            disabled = function()
                         return GroupDisabled(BarType, TableName, UBF)
                       end,
          },
          Spacer10 = CreateSpacer(10),
          BgTile = {
            type = 'toggle',
            name = 'Tile Background',
            order = 11,
            disabled = function()
                         return GroupDisabled(BarType, TableName, UBF)
                       end,
          },
          BgTileSize = {
            type = 'range',
            name = 'Background Tile Size',
            order = 12,
            min = o.UnitBarBgTileSizeMin,
            max = o.UnitBarBgTileSizeMax,
            step = 1,
            disabled = function()
                         return GroupDisabled(BarType, TableName, UBF)
                       end,
          },
          Spacer20 = CreateSpacer(20),
          BorderSize = {
            type = 'range',
            name = 'Border Thickness',
            order = 21,
            min = o.UnitBarBorderSizeMin,
            max = o.UnitBarBorderSizeMax,
            step = 2,
            disabled = function()
                         return GroupDisabled(BarType, TableName, UBF)
                       end,
          },
        },
      },
    },
  }

  local BackdropArgs = BackdropOptions.args
  local GeneralArgs = BackdropOptions.args.General.args

  if TableName ~= 'Region' then
    if UBD[TableName].EnableBorderColor ~= nil then
      GeneralArgs.Spacer30 = CreateSpacer(30)
      GeneralArgs.EnableBorderColor = {
        type = 'toggle',
        name = 'Enable Border Color',
        order = 32,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      }
    end
    -- Fragment bar options
    if BarType == 'FragmentBar' or BarType == 'RuneBar' then
      -- Remove default color all options
      BackdropArgs.ColorAllSelect = CreateColorAllSelectOptions(BarType, 'bg',  TableName, 2, 'Color')
      BackdropArgs.BorderColorAllSelect = CreateColorAllSelectOptions(BarType, 'border',  TableName, 3, 'Border Color')
      BackdropArgs.BorderColorAllSelect.disabled = function()
                                                     return not UBF.UnitBar[TableName].EnableBorderColor
                                                   end
    else
      -- All other unitbar color options.
      if UBD[TableName].Color.All == nil then
        GeneralArgs.Color = {
          type = 'color',
          name = 'Background Color',
          order = 22,
          hasAlpha = true,
        }
      else
        BackdropArgs.ColorAll = CreateColorAllOptions(BarType, TableName, TableName .. '.Color', 'Color', 2, 'Color')
      end
      if UBD[TableName].BorderColor.All == nil then
        GeneralArgs.BorderColor = {
          type = 'color',
          name = 'Border Color',
          order = 33,
          hasAlpha = true,
          disabled = function()
                      return not UBF.UnitBar[TableName].EnableBorderColor
                    end,
        }
      else
        BackdropArgs.BorderColorAll = CreateColorAllOptions(BarType, TableName, TableName .. '.BorderColor', 'BorderColor', 3, 'Border Color')
        BackdropArgs.BorderColorAll.disabled = function()
                                                 return not UBF.UnitBar[TableName].EnableBorderColor
                                               end
      end
    end
  else
    -- Region option
    GeneralArgs.Color = {
      type = 'color',
      name = 'Background Color',
      order = 22,
      hasAlpha = true,
    }
    GeneralArgs.Spacer30 = CreateSpacer(30)
    GeneralArgs.EnableBorderColor = {
      type = 'toggle',
      name = 'Enable Border Color',
      order = 32,
    }
    GeneralArgs.BorderColor = {
      type = 'color',
      name = 'Border Color',
      order = 33,
      hasAlpha = true,
      disabled = function()
                   return not UBF.UnitBar[TableName].EnableBorderColor
                 end,
    }
  end

  BackdropArgs.Padding = {
    type = 'group',
    name = 'Padding',
    order = 10,
    get = function(Info)
            local Padding = UBF.UnitBar[TableName].Padding
            local KeyName = Info[#Info]

            if KeyName == 'All' then
              return Padding.Left
            else
              return Padding[KeyName]
            end
          end,
    set = function(Info, Value)
            local Padding = UBF.UnitBar[TableName].Padding
            local KeyName = Info[#Info]

            if KeyName == 'All' then
              Padding.Left = Value
              Padding.Right = Value
              Padding.Top = Value
              Padding.Bottom = Value
            else
              Padding[KeyName] = Value
            end
            UBF:SetAttr(TableName, 'Padding')
          end,
    args = {
      PaddingAll = {
        type = 'toggle',
        name = 'All',
        order = 1,
        get = function()
                return UBF.UnitBar[TableName].PaddingAll
              end,
        set = function(Info, Value)
                UBF.UnitBar[TableName].PaddingAll = Value
              end,
        desc = 'Change padding with one value',
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Spacer = CreateSpacer(2),
      All = {
        type = 'range',
        name = 'Offset',
        order = 3,
        hidden = function()
                   return not UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Left = {
        type = 'range',
        name = 'Left',
        order = 4,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Right = {
        type = 'range',
        name = 'Right',
        order = 5,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Top = {
        type = 'range',
        name = 'Top',
        order = 6,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Bottom = {
        type = 'range',
        name = 'Bottom',
        order = 7,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
    },
  }

  return BackdropOptions
end

-------------------------------------------------------------------------------
-- CreateAbsorbOptions
--
-- Subfunction of CreateBarOptions()
--
-- Allows the user to set the way absorbs are shown
--
-- BarType     Type of options being created.
-- Order       Position in the options list.
-- Name        Name of the options.
-------------------------------------------------------------------------------
local function CreateAbsorbOptions(BarType, Order, Name)
  local UBF = Main.UnitBarsF[BarType]

  local AbsorbOptions = {
    type = 'group',
    name = Name,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Bar[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            UBF.UnitBar.Bar[KeyName] = Value
            UBF:SetAttr('Bar', '_Absorb')
          end,
    args = {
      AbsorbBarDontClip = {
        type = 'toggle',
        name = "Don't Clip Absorb Bar",
        desc = 'Will always show the absorb bar instead of being pushed off',
        width = 'double',
        order = 1,
      },
      AbsorbBarSize = {
        type = 'range',
        name = 'Absorb Bar Size',
        order = 2,
        desc = 'Shrinks the absorb bar by the percentage set',
        width = 'full',
        step = .01,
        isPercent = true,
        min = o.UnitBarAbsorbSizeMin,
        max = o.UnitBarAbsorbSizeMax,
      },
    },
  }

  return AbsorbOptions
end

-------------------------------------------------------------------------------
-- CreateBarSizeOptions
--
-- Subfunction of CreateBarOptions()
--
-- Allows the user to change size of bars then offset them for finer sizing.
--
-- BarType     Type of options being created.
-- TableName   Table found in UnitBars[BarType]
-- Order       Position in the options list.
-- Name        Name of the options.
-------------------------------------------------------------------------------
local function CreateBarSizeOptions(BarType, TableName, Order, Name)
  local UBF = Main.UnitBarsF[BarType]
  local BarSizeOptions

  local function SetSize()
    local UB = UBF.UnitBar[TableName]
    for KeyName in pairs(BarSizeOptions.args) do
      local SliderArgs = BarSizeOptions.args[KeyName]
      local Min
      local Max

      if KeyName == 'Width' or KeyName == 'Height' then
        Min = o.UnitBarSizeMin
        Max = o.UnitBarSizeMax
      end
      if Min and Max then
        local Value = UB[KeyName]

        if UB.Advanced then
          Value = Value < Min and Min or Value > Max and Max or Value
          UB[KeyName] = Value
          SliderArgs.min = Value - o.UnitBarSizeAdvancedMinMax
          SliderArgs.max = Value + o.UnitBarSizeAdvancedMinMax
          SliderArgs.name = format('Advanced %s', KeyName)
        else
          SliderArgs.min = Min
          SliderArgs.max = Max
          SliderArgs.name = KeyName
        end
      end
    end
  end

  BarSizeOptions = {
    type = 'group',
    name = Name,
    order = Order,
    get = function(Info)
            SetSize()
            return UBF.UnitBar[TableName][Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar[TableName][Info[#Info]] = Value
            SetSize()
            UBF:SetAttr(TableName, '_Size')
          end,
    args = {
      Advanced = {
        type = 'toggle',
        name = 'Advanced',
        desc = 'Allows you to make fine tune adjustments easier',
        order = 1,
        get = function()
                SetSize()
                return UBF.UnitBar[TableName].Advanced
              end,
        set = function(Info, Value)
                UBF.UnitBar[TableName].Advanced = Value
                SetSize()
              end,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Width = {
        type = 'range',
        name = '',
        order = 2,
        desc = 'Slide or click anywhere on the slider to change the width',
        width = 'full',
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Height = {
        type = 'range',
        name = '',
        order = 3,
        desc = 'Slide or click anywhere on the slider to change the height',
        width = 'full',
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
    },
  }

  return BarSizeOptions
end

-------------------------------------------------------------------------------
-- CreateBarOptions
--
-- Creates bar options for a unitbar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType     Type of options being created.
-- TableName   Name of the table containing the options.
-- Order       Position in the options list.
-- Name        Name of the options.
-------------------------------------------------------------------------------
local function CreateBarOptions(BarType, TableName, Order, Name)
  local UBF = Main.UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local BarOptions = {
    type = 'group',
    childGroups = 'tab',
    name = function()
             local Tag = ''
             if BarType == 'FragmentBar' and TableName ~= 'Region' then
               if UBF.GreenFire then
                 Tag = ' [Green Fire]'
               end
               if not GroupDisabled(BarType, TableName, UBF) then
                 return Name .. Tag .. ' *'
               end
             end
             return Name .. Tag
           end,
    order = Order,
    args = {
      General = {
        type = 'group',
        name = 'General',
        order = 1,
        get = function(Info)
                local KeyName = Info[#Info]

                if strfind(KeyName, 'Color') then
                  local c = UBF.UnitBar[TableName][KeyName]

                  return c.r, c.g, c.b, c.a
                else
                  return UBF.UnitBar[TableName][KeyName]
                end
              end,
        set = function(Info, Value, g, b, a)
                local KeyName = Info[#Info]


                if strfind(KeyName, 'Color') then
                  local c = UBF.UnitBar[TableName][KeyName]

                  c.r, c.g, c.b, c.a = Value, g, b, a
                  UBF:SetAttr(TableName, KeyName)
                else
                  UBF.UnitBar[TableName][KeyName] = Value
                  UBF:SetAttr(TableName, KeyName)
                end
              end,
        args = {},
      },
    },
  }

  local BarArgs = BarOptions.args
  local GeneralArgs = BarArgs.General.args

  -- Normal health and power bar.
  if UBD[TableName].StatusBarTexture ~= nil then
    GeneralArgs.StatusBarTexture = {
      type = 'select',
      name = 'Bar Texture',
      order = 1,
      dialogControl = 'LSM30_Statusbar',
      values = LSMDropdown.StatusBar,
      disabled = function()
                   return GroupDisabled(BarType, TableName, UBF)
                 end,
    }

    GeneralArgs.Spacer2 = CreateSpacer(2, 'half')

    -- Regular color
    local Color = UBD[TableName].Color
    if Color ~= nil and Color.All == nil then
      GeneralArgs.Color = {
        type = 'color',
        name = 'Color',
        hasAlpha = true,
        order = 3,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      }
      -- Only for power bars
      if UBD.Layout.UseBarColor ~= nil then
        GeneralArgs.Color.disabled = function()
                                       return not UBF.UnitBar.Layout.UseBarColor
                                     end
      end
      -- Only for health bars
      if UBD.Layout.ClassColor ~= nil then
        GeneralArgs.Color.disabled = function()
                                       return UBF.UnitBar.Layout.ClassColor or UBF.UnitBar.Layout.CombatColor
                                     end
      end
    end
  end

  -- Predicted Health and Power bar.
  if UBD[TableName].PredictedBarTexture ~= nil then
    GeneralArgs.Spacer10 = CreateSpacer(10)

    GeneralArgs.PredictedBarTexture = {
      type = 'select',
      name = UBF.IsHealth and 'Bar Texture (predicted health)' or
                              'Bar Texture (predicted power)' ,
      order = 11,
      dialogControl = 'LSM30_Statusbar',
      values = LSMDropdown.StatusBar,
    }

    GeneralArgs.Spacer12 = CreateSpacer(12, 'half')

    -- Predicted color
    if UBD[TableName].PredictedColor ~= nil then
      GeneralArgs.PredictedColor = {
        type = 'color',
        name = UBF.IsHealth and 'Color (predicted health)' or
                                'Color (predicted power)' ,
        hasAlpha = true,
        order = 13,
      }
    end
  end

  -- Absorb Health bar.
  if UBD[TableName].AbsorbBarTexture ~= nil then
    GeneralArgs.Spacer14 = CreateSpacer(14)

    GeneralArgs.AbsorbBarTexture = {
      type = 'select',
      name = 'Bar Texture (absorb health)',
      order = 15,
      dialogControl = 'LSM30_Statusbar',
      values = LSMDropdown.StatusBar,
    }

    GeneralArgs.Spacer16 = CreateSpacer(16, 'half')

    -- absorb color
    if UBD[TableName].AbsorbColor ~= nil then
      GeneralArgs.AbsorbColor = {
        type = 'color',
        name = 'Color (absorb health)',
        hasAlpha = true,
        order = 17,
      }
    end
  end

  -- Predicted cost bar
  if UBD[TableName].PredictedCostBarTexture ~= nil then
    GeneralArgs.Spacer20 = CreateSpacer(20)

    GeneralArgs.PredictedCostBarTexture = {
      type = 'select',
      name = 'Bar Texture (predicted cost)',
      order = 21,
      dialogControl = 'LSM30_Statusbar',
      values = LSMDropdown.StatusBar,
    }

    GeneralArgs.Spacer22 = CreateSpacer(22, 'half')

    -- Predicted cost color
    if UBD[TableName].PredictedCostColor ~= nil then
      GeneralArgs.PredictedCostColor = {
        type = 'color',
        name = 'Color (predicted cost)',
        hasAlpha = true,
        order = 23,
      }
    end
  end

  -- For fragment bar
  -- Can use the same order numbers as predictedbartexture
  -- since both of these never happen at the same time.
  if BarType == 'FragmentBar' then
    GeneralArgs.Spacer20 = CreateSpacer(20)

    GeneralArgs.FullBarTexture = {
      type = 'select',
      name = 'Bar Texture (full)',
      order = 21,
      dialogControl = 'LSM30_Statusbar',
      values = LSMDropdown.StatusBar,
      disabled = function()
                   return GroupDisabled(BarType, TableName, UBF)
                 end,
    }
  end

  -- Stagger bar
  if BarType == 'StaggerBar' and TableName == 'BarStagger' then
    -- Stagger group
    GeneralArgs.StaggerGroup = {
      type = 'group',
      order = 9,
      dialogInline = true,
      hidden = function()
                 return not UBF.UnitBar.Layout.Layered and not UBF.UnitBar.Layout.SideBySide
               end,
      args = {}
    }
    local StaggerGeneralArgs = GeneralArgs.StaggerGroup.args

    GeneralArgs.StaggerGroup.name = function()
                                      return format('|cffffff00Continued (%s%% to %s%%)|r', StaggerGeneralArgs.MaxPercentBStagger.min * 100,
                                                                                            UBF.UnitBar[TableName].MaxPercentBStagger * 100)
                                    end
    -- This section cant be part of the group
    GeneralArgs.MaxPercent = {
      type = 'range',
      name = 'Max Percent',
      desc = 'Changes how much percentage it takes to fill the bar',
      order = 5,
      step = .01,
      width = 'full',
      isPercent = true,
      get = function()
              local Value = UBF.UnitBar[TableName].MaxPercent

              -- Set the min/max percents for second bar
              local Min = Value + .01
              local Max = Value + o.UnitBarMaxPercentMax

              StaggerGeneralArgs.MaxPercentBStagger.min = Min
              StaggerGeneralArgs.MaxPercentBStagger.max = Max
              local Value2 = UBF.UnitBar[TableName].MaxPercentBStagger
              UBF.UnitBar[TableName].MaxPercentBStagger = Value2 < Min and Min or Value2 > Max and Max or Value2

              return Value
            end,
      set = function(Info, Value)
              UBF.UnitBar[TableName].MaxPercent = Value
              UBF:SetAttr(TableName, 'MaxPercent')

              -- Set the min/max percents for second bar
              local Min = Value + .01
              local Max = Value + o.UnitBarMaxPercentMax

              StaggerGeneralArgs.MaxPercentBStagger.min = Min
              StaggerGeneralArgs.MaxPercentBStagger.max = Max
              local Value2 = UBF.UnitBar[TableName].MaxPercentBStagger
              UBF.UnitBar[TableName].MaxPercentBStagger = Value2 < Min and Min or Value2 > Max and Max or Value2
            end,
      min = o.UnitBarMaxPercentMin,
      max = o.UnitBarMaxPercentMax,
    }

    StaggerGeneralArgs.Spacer20 = CreateSpacer(20)
    StaggerGeneralArgs.BStaggerBarTexture = {
      type = 'select',
      name = function()
               return format('Bar Texture', UBF.UnitBar[TableName].MaxPercent * 100)
             end,
      order = 21,
      dialogControl = 'LSM30_Statusbar',
      values = LSMDropdown.StatusBar,
    }

    StaggerGeneralArgs.Spacer22 = CreateSpacer(22, 'half')
    StaggerGeneralArgs.BStaggerColor = {
      type = 'color',
      name = 'Color',
      hasAlpha = true,
      order = 23,
    }
    StaggerGeneralArgs.Spacer24 = CreateSpacer(24)
    StaggerGeneralArgs.MaxPercentBStagger = {
      type = 'range',
      name = 'Max Percent',
      desc = 'This continues the percentage from Max Percent above',
      order = 25,
      step = .01,
      width = 'full',
      isPercent = true,
      min = o.UnitBarMaxPercentMin,
      max = o.UnitBarMaxPercentMax,
    }
  end

  GeneralArgs.Spacer30 = CreateSpacer(30)

  if UBD[TableName].SyncFillDirection ~= nil then
    GeneralArgs.SyncFillDirection = {
      type = 'toggle',
      name = 'Sync Fill Direction',
      order = 31,
      desc = 'Fill direction changes based on rotation',
      disabled = function()
                   return GroupDisabled(BarType, TableName, UBF)
                 end,
    }
  end

  if UBD[TableName].Clipping ~= nil then
    if UBD[TableName].SyncFillDirection ~= nil then
      GeneralArgs.Spacer32 = CreateSpacer(32, 'half')
    end

    GeneralArgs.Clipping = {
      type = 'toggle',
      name = 'Clipping',
      order = 33,
      desc = 'Texture is clipped instead of being stretched',
      disabled = function()
                   return GroupDisabled(BarType, TableName, UBF)
                 end,
    }
  end
  GeneralArgs.Spacer34 = CreateSpacer(34)

  if UBD[TableName].FillDirection ~= nil then
    GeneralArgs.FillDirection = {
      type = 'select',
      name = 'Fill Direction',
      order = 35,
      values = DirectionDropdown,
      style = 'dropdown',
      disabled = function()
                   return UBF.UnitBar[TableName].SyncFillDirection or false
                 end,
    }
    GeneralArgs.Spacer36 = CreateSpacer(36, 'half')
  end

  if UBD[TableName].RotateTexture ~= nil then
    GeneralArgs.RotateTexture = {
      type = 'range',
      name = 'Rotate Texture',
      order = 37,
      min = o.UnitBarRotationMin,
      max = o.UnitBarRotationMax,
      step = 90,
      disabled = function()
                   return GroupDisabled(BarType, TableName, UBF)
                 end,
    }
  end

  -- Standard color all
  local Color = UBD[TableName].Color
  if Color and Color.All ~= nil then
    BarArgs.ColorAll = CreateColorAllOptions(BarType, TableName, TableName .. '.Color', 'Color', 2, 'Color')
  end

  -- Fragment bar options
  if BarType == 'FragmentBar' or BarType == 'RuneBar' then
    -- Remove default color all options
    BarArgs.ColorAll = nil
    BarArgs.ColorAllSelect = CreateColorAllSelectOptions(BarType, 'bar', TableName, 2, 'Color')

    if BarType == 'FragmentBar' then
      BarArgs.ColorAllFullSelect = CreateColorAllSelectOptions(BarType, 'barfull', TableName, 2, 'Color (full)')
    end
  end

  if UBF.IsHealth then
    BarArgs.Absorb = CreateAbsorbOptions(BarType, 9, 'Absorb')
  end
  BarArgs.BoxSize = CreateBarSizeOptions(BarType, TableName, 10, 'Bar Size')


  BarArgs.Padding = {
    type = 'group',
    name = 'Padding',
    order = 10,
    get = function(Info)
            local KeyName = Info[#Info]
            local Padding = UBF.UnitBar[TableName].Padding

            if KeyName == 'All' then
              return Padding.Left
            else
              return Padding[KeyName]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local Padding = UBF.UnitBar[TableName].Padding

            if KeyName == 'All' then
              Padding.Left = Value
              Padding.Right = -Value
              Padding.Top = -Value
              Padding.Bottom = Value
            else
              Padding[KeyName] = Value
            end
            UBF:SetAttr(TableName, 'Padding')
          end,
    args = {
      PaddingAll = {
        type = 'toggle',
        name = 'All',
        order = 1,
        get = function()
                return UBF.UnitBar[TableName].PaddingAll
              end,
        set = function(Info, Value)
                UBF.UnitBar[TableName].PaddingAll = Value
              end,
        desc = 'Change padding with one value',
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Spacer = CreateSpacer(2),
      All = {
        type = 'range',
        name = 'Offset',
        order = 3,
        hidden = function()
                   return not UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Left = {
        type = 'range',
        name = 'Left',
        order = 4,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Right = {
        type = 'range',
        name = 'Right',
        order = 5,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Top = {
        type = 'range',
        name = 'Top',
        order = 6,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
      Bottom = {
        type = 'range',
        name = 'Bottom',
        order = 7,
        hidden = function()
                   return UBF.UnitBar[TableName].PaddingAll
                 end,
        min = o.UnitBarPaddingMin,
        max = o.UnitBarPaddingMax,
        step = 1,
        disabled = function()
                     return GroupDisabled(BarType, TableName, UBF)
                   end,
      },
    },
  }

  return BarOptions
end

-------------------------------------------------------------------------------
-- CreateSpecOptions
--
-- Create options to change specializations for the trigger
--
-- Subfunction of CreateTriggerTabOptions(), CreateUnitBarOptions()
--
-- Order         Position in the options.
-- UBF           Unitbar frame to access the bar functions.
-- BBar          Access to bar functions.
-- ClassSpecsTP  String or table, if string then its a table path to the ClassSpecs table
-- BBar          Only used with triggers
-- DisableFn     Only used with triggers
-------------------------------------------------------------------------------
local function MarkMenuSpec(ClassDropdown, SelectClassDropdown, ClassSpecs)

  -- Mark menu items that have specializations
  for Index, ClassName in pairs(ClassDropdown) do
    local ClassNameUpper = ConvertPlayerClass[ClassName]
    local ClassSpec = ClassSpecs[ClassNameUpper]

    if ClassSpec then
      local CN = ClassName
      local Found = false

      for _, Active in pairs(ClassSpec) do
        if Active then
          Found = true
          break
        end
      end
      if Found then
        CN = CN .. '*'
      end
      SelectClassDropdown[Index] = CN
    end
  end
end

local function GetClassSpecsTable(BarType, ClassSpecsTP)
  if type(ClassSpecsTP) == 'string' then
    return Main:GetUB(BarType, ClassSpecsTP)
  else
    return ClassSpecsTP
  end
end

local function CreateSpecOptions(BarType, Order, ClassSpecsTP, BBar, DisableFn)
  local UBF = Main.UnitBarsF[BarType]
  local ClassSpecializations = DefaultUB.ClassSpecializations
  local PlayerClass = Main.PlayerClass
  local ClassDropdown = {}
  local SelectClassDropdown = {}
  local SpecDropdown = {}
  local MyClassFound = false
  local CSD
  local ClassSpecs = GetClassSpecsTable(BarType, ClassSpecsTP)
  local Index = 1

  if BBar then
    CSD = DUB[BarType].Triggers.Default.ClassSpecs
  else
    CSD = DUB[BarType].ClassSpecs
  end

  -- Build pulldown menus
  for ClassName, Specs in pairs(CSD) do
    if type(Specs) == 'table' then
      local ClassNameLower =  ConvertPlayerClass[ClassName]

      if ClassName ~= PlayerClass then

        ClassDropdown[Index] = ClassNameLower
        SelectClassDropdown[Index] = ClassNameLower
        Index = Index + 1
      else
        MyClassFound = true
      end
      -- Create spec dropdown
      local ClassSpecialization = ClassSpecializations[ClassName]
      local SpecList = {}

      for Index in pairs(Specs) do
        SpecList[Index] = ClassSpecialization[Index]
      end
      SpecDropdown[ClassNameLower] = SpecList
    end
  end
  sort(ClassDropdown)
  sort(SelectClassDropdown)

  -- Set class you're on to the first entry
  -- Only if the bar supports your class
  if MyClassFound then
    local CN = ConvertPlayerClass[PlayerClass]
    tinsert(ClassDropdown, 1, CN)
    tinsert(SelectClassDropdown, 1, CN)
  end

  MarkMenuSpec(ClassDropdown, SelectClassDropdown, ClassSpecs)

  local SpecOptions = {
    type = 'group',
    dialogInline = true,
    name = function()
             MarkMenuSpec(ClassDropdown, SelectClassDropdown, GetClassSpecsTable(BarType, ClassSpecsTP))
             return ''
           end,
    order = Order,
    disabled = function()
                 return BBar == nil and ( Main.UnitBars.Show or Main.UnitBars.Testing )
               end,
    get = function(Info, Index)
            ClassSpecs = GetClassSpecsTable(BarType, ClassSpecsTP)
            local KeyName = Info[#Info]

            if KeyName == 'All' then
              return ClassSpecs.All
            elseif KeyName == 'Inverse' then
              return ClassSpecs.Inverse or false
            elseif KeyName == 'Class' then
              local ClassIndex = FindMenuItem(ClassDropdown, ClassSpecs.ClassName or '')

              -- Set default classname
              ClassSpecs.ClassName = ClassDropdown[ClassIndex]

              return ClassIndex
            else
              local ClassSpec = ClassSpecs[ConvertPlayerClass[ClassSpecs.ClassName]]

              return ClassSpec and ClassSpec[Index] or false
            end
          end,
    set = function(Info, Value, Active)
            ClassSpecs = GetClassSpecsTable(BarType, ClassSpecsTP)
            local KeyName = Info[#Info]

            if KeyName == 'All' then
              ClassSpecs.All = Value
            elseif KeyName == 'Inverse' then
              ClassSpecs.Inverse = Value
            elseif KeyName == 'Class' then
              ClassSpecs.ClassName = ClassDropdown[Value]
            else
              local ClassName = ClassSpecs.ClassName
              local ClassNameUpper = ConvertPlayerClass[ClassName]
              local ClassSpec = ClassSpecs[ClassNameUpper]

              if ClassSpec == nil then
                ClassSpec = {}
                ClassSpecs[ClassNameUpper] = ClassSpec
              end

              ClassSpec[Value] = Active
            end
            -- Update bar to reflect specialization setting.
            if BBar then
              BBar:CheckTriggers()
            end
            UBF:Update()
            if BBar then
              BBar:Display()
            end
          end,
    args = {
      All = {
        type = 'toggle',
        name = 'All',
        order = 1,
        desc = 'Matches all classes and specializations',
        width = 'half',
        disabled = function()
                     if DisableFn then
                       return DisableFn()
                     else
                       return false
                     end
                   end,
      },
      Inverse = {
        type = 'toggle',
        name = 'Inverse',
        order = 2,
        disabled = function()
                     return DisableFn and DisableFn() or GetClassSpecsTable(BarType, ClassSpecsTP).All
                   end,
      },
      Reset = {
        type = 'execute',
        order = 3,
        desc = 'Sets all specialization options to default',
        name = 'Reset',
        width = 'half',
        func = function()
                 ClassSpecs = GetClassSpecsTable(BarType, ClassSpecsTP)
                 Main:CopyTableValues(CSD, ClassSpecs, true)

                 if BBar then
                   BBar:CheckTriggers()
                 end
                 UBF:Update()
                 if BBar then
                   BBar:Display()
                 end
               end,
        confirm = function()
                    return 'This will reset your class specialization settings'
                  end,
        disabled = function()
                     return DisableFn and DisableFn() or false
                   end,
      },
      Clear = {
        type = 'execute',
        order = 4,
        desc = 'Uncheck all class specialization settings',
        name = 'Clear',
        width = 'half',
        func = function()
                 ClassSpecs = GetClassSpecsTable(BarType, ClassSpecsTP)

                 for _, ClassSpec in pairs(ClassSpecs) do
                   if type(ClassSpec) == 'table' then
                     for Index in pairs(ClassSpec) do
                       ClassSpec[Index] = false
                     end
                   end
                 end

                 if BBar then
                   BBar:CheckTriggers()
                 end
                 UBF:Update()
                 if BBar then
                   BBar:Display()
                 end
               end,
        confirm = function()
                    return 'This will uncheck your class specialization settings'
                  end,
        disabled = function()
                     return DisableFn and DisableFn() or false
                   end,
      },
      SpecGroup = {
        type = 'group',
        name = '',
        order = 10,
        disabled = function()
                     return DisableFn and DisableFn() or GetClassSpecsTable(BarType, ClassSpecsTP).All
                   end,
        args = {
          Class = {
            type = 'select',
            name = 'Class',
            order = 10,
            style = 'dropdown',
            values = SelectClassDropdown,
          },
          Spacer12 = CreateSpacer(12),
          Spec = {
            type = 'multiselect',
            name = 'Specialization',
            order = 11,
            --  width = 'double',
            --  dialogControl = 'Dropdown',
            values = function()
                       return SpecDropdown[ClassSpecs.ClassName]
                     end,
          },
        },
      },
    },
  }

  return SpecOptions
end

-------------------------------------------------------------------------------
-- CreateStatusOptions
--
-- Creates the status flags for all unitbars.
--
-- Subfunction of CreateUnitBarOptions
--
-- BarType       The options being created for.
-- Order         Where the options appear on screen.
-- Name          Name of the options.
-------------------------------------------------------------------------------
local function CreateStatusOptions(BarType, Order, Name)
  local UBF = Main.UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local StatusOptions = {
    type = 'group',
    name = Name,
--  dialogInline = true,
    order = Order,
    disabled = function()
                 return Main.UnitBars.Show or Main.UnitBars.Testing
               end,
    get = function(Info)
            return UBF.UnitBar.Status[Info[#Info]]
          end,
    set = function(Info, Value)
            UBF.UnitBar.Status[Info[#Info]] = Value

            -- Update the status of all bars.
            GUB:UnitBarsUpdateStatus()
          end,
    args = {}
  }

  local StatusArgs = StatusOptions.args

  if UBD.Status.ShowAlways ~= nil then
    StatusArgs.ShowAlways = {
      type = 'toggle',
      name = 'Show Always',
      order = 3,
      desc = "Always show the bar in and out of combat",
    }
  end
  if UBD.Status.HideWhenDead ~= nil then
    StatusArgs.HideWhenDead = {
      type = 'toggle',
      name = 'Hide when Dead',
      order = 4,
      desc = "Hides the bar when you're dead",
    }
  end
  if UBD.Status.HideNoTarget ~= nil then
    StatusArgs.HideNoTarget = {
      type = 'toggle',
      name = 'Hide no Target',
      order = 5,
      desc = 'Hides the bar when you have no target selected',
    }
  end
  if UBD.Status.HideInVehicle ~= nil then
    StatusArgs.HideInVehicle = {
      type = 'toggle',
      name = 'Hide in Vehicle',
      order = 6,
      desc = "Hides the bar when you're in a vehicle",
    }
  end
  if UBD.Status.HideInPetBattle ~= nil then
    StatusArgs.HideInPetBattle = {
      type = 'toggle',
      name = 'Hide in Pet Battle',
      order = 7,
      desc = "Hides the bar when you're in a pet battle",
    }
  end
  if UBD.Status.HideNotActive ~= nil then
    StatusArgs.HideNotActive = {
      type = 'toggle',
      name = 'Hide not Active',
      order = 8,
      desc = 'Bar will be hidden if its not active. This only gets checked out of combat',
    }
  end
  if UBD.Status.HideNoCombat ~= nil then
    StatusArgs.HideNoCombat = {
      type = 'toggle',
      name = 'Hide no Combat',
      order = 9,
      desc = 'When not in combat the bar will be hidden',
    }
  end
  if UBD.Status.HideIfBlizzAltPowerVisible ~= nil then
    StatusArgs.HideIfBlizzAltPowerVisible = {
      type = 'toggle',
      name = 'Hide if Blizzard Visible',
      order = 10,
      desc = 'Hide when the blizzard alternate power bar is visible. This only works while the alternate power bar is active',
    }
  end

  return StatusOptions
end

-------------------------------------------------------------------------------
-- CreateShowOptions
--
-- Creates a tab that holds options related to hiding and showing the bar
--
-- Subfunction of CreateUnitBarOptions
--
-- BarType       The options being created for.
-- Order         Where the options appear on screen.
-- Name          Name of the options.
-------------------------------------------------------------------------------
local function CreateShowOptions(BarType, Order, Name)
  local ShowOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    args = {
      Notes = {
        type = 'description',
        order = 1,
        name = '|cff00ff00Disabled because Show or Test Mode option is enabled|r',
        hidden = function()
                   return not Main.UnitBars.Show and not Main.UnitBars.Testing
                 end,
      },
      SpecGroup = {
        type = 'group',
        name = 'Specialization',
        order = 10,
        dialogInline = false,
        args = {
          SpecOptions = CreateSpecOptions(BarType, 10, 'ClassSpecs'), -- ClassSpecs is a table path
        },
      },
      StatusOptions = CreateStatusOptions(BarType, 20, 'Status'),
    },
  }

  return ShowOptions
end

-------------------------------------------------------------------------------
-- CreateTestModeOptions
--
-- Subfunction of CreateUnitBarOptions
--
-- BarType       The options being created for.
-- Order         Where the options appear on screen.
-- Name          Name of the options.
-------------------------------------------------------------------------------
local function CreateTestModeOptions(BarType, Order, Name)
  local UBF = Main.UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local TestModeOptions = {
    type = 'group',
    name = Name,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.TestMode[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local TestMode = UBF.UnitBar.TestMode
            TestMode[KeyName] = Value

            if Value then
              if KeyName == 'BloodSpec' then
                TestMode.FrostSpec = false
                TestMode.UnHolySpec = false
              elseif KeyName == 'FrostSpec' then
                TestMode.BloodSpec = false
                TestMode.UnHolySpec = false
              elseif KeyName == 'UnHolySpec' then
                TestMode.BloodSpec = false
                TestMode.FrostSpec = false
              end
              if KeyName == 'AltTypePower' then
                TestMode.AltTypeCounter = false
              end
              if KeyName == 'AltTypeCounter' then
                TestMode.AltTypePower = false
              end
            elseif KeyName == 'BloodSpec' or KeyName == 'FrostSpec' or KeyName == 'UnHolySpec' then
              if not TestMode.BloodSpec and not TestMode.FrostSpec and not TestMode.UnHolySpec then
                TestMode[KeyName] = true
              end
            elseif KeyName == 'AltTypePower' or KeyName == 'AltTypeCounter' then
              TestMode[KeyName] = true
            end

            -- Update the bar to show test mode changes.
            UBF:SetAttr('TestMode', KeyName)
          end,
    hidden = function()
               return not Main.UnitBars.Testing
             end,
    args = {},
  }
  local TestModeArgs = TestModeOptions.args

  if UBD.TestMode.Value ~= nil then
    TestModeArgs.Value = {
      type = 'range',
      name = 'Value',
      order = 100,
      desc = 'Change the bars value',
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.PredictedHealth ~= nil then
    TestModeArgs.PredictedHealth = {
      type = 'range',
      name = 'Predicted Health',
      order = 101,
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.AbsorbHealth ~= nil then
    TestModeArgs.AbsorbHealth = {
      type = 'range',
      name = 'Absorb Health',
      order = 102,
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.PredictedPower ~= nil then
    TestModeArgs.PredictedPower = {
      type = 'range',
      name = 'Predicted Power',
      order = 103,
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.PredictedCost ~= nil then
    TestModeArgs.PredictedCost = {
      type = 'range',
      name = 'Predicted Cost',
      order = 104,
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.UnitLevel ~= nil then
    TestModeArgs.UnitLevel = {
      type = 'range',
      name = 'Unit Level',
      order = 105,
      desc = 'Change the bars level',
      step = 1,
      width = 'full',
      min = o.TestModeUnitLevelMin,
      max = o.TestModeUnitLevelMax,
    }
  end
  if UBD.TestMode.ScaledLevel ~= nil then
    TestModeArgs.ScaledLevel = {
      type = 'range',
      name = 'Scaled Level',
      order = 106,
      desc = 'Change the bars scaled level',
      step = 1,
      width = 'full',
      min = o.TestModeUnitLevelMin,
      max = o.TestModeUnitLevelMax,
    }
  end
  if UBD.TestMode.BloodSpec ~= nil then
    TestModeArgs.BloodSpec = {
      type = 'toggle',
      name = 'Blood',
      width = 'half',
      order = 1,
    }
    TestModeArgs.FrostSpec = {
      type = 'toggle',
      name = 'Frost',
      width = 'half',
      order = 2,
    }
    TestModeArgs.UnHolySpec = {
      type = 'toggle',
      name = 'Unholy',
      width = 'half',
      order = 3,
    }
  end
  if UBD.TestMode.RuneTime ~= nil then
    TestModeArgs.RuneTime = {
      type = 'range',
      name = 'Time',
      order = 201,
      desc = '',
      step = .01,
      width = 'full',
      isPercent = true,
      min = 0,
      max = 1,
    }
  end
  if UBD.TestMode.RuneOnCooldown ~= nil then
    TestModeArgs.RuneOnCooldown = {
      type = 'range',
      name = 'On Cooldown',
      order = 202,
      desc = 'Set which rune is on cooldown, max for all',
      width = 'full',
      step = 1,
      min = o.TestModeOnCooldownMin,
      max = o.TestModeOnCooldownMax,
    }
  end
  if UBD.TestMode.SoulShards ~= nil then
    TestModeArgs.SoulShards = {
      type = 'range',
      name = 'Shards',
      order = 300,
      desc = 'Change how many shards are lit',
      width = 'full',
      step = 1,
      min = o.TestModeShardMin,
      max = o.TestModeShardMax,
    }
  end
  -- Fragement bar
  if UBD.TestMode.ShowFull ~= nil then
    TestModeArgs.ShowFull = {
      type = 'toggle',
      name = 'Show Full',
      order = 300,
    }
  end
  if UBD.TestMode.ShardFragments ~= nil then
    TestModeArgs.ShardFragments = {
      type = 'range',
      name = 'Shard Fragments',
      order = 301,
      desc = 'Change how many shards are filled',
      width = 'full',
      step = 1,
      min = o.TestModeShardFragmentMin,
      max = o.TestModeShardFragmentMax,
    }
  end
  if UBD.TestMode.HolyPower ~= nil then
    TestModeArgs.HolyPower = {
      type = 'range',
      name = 'Holy Power',
      order = 400,
      desc = 'Change how many holy runes are lit',
      width = 'full',
      step = 1,
      min = o.TestModeHolyPowerMin,
      max = o.TestModeHolyPowerMax,
    }
  end
  if UBD.TestMode.Ascension ~= nil then
    TestModeArgs.Ascension = {
      type = 'toggle',
      name = 'Ascension',
      order = 500,
    }
  end
  if UBD.TestMode.Chi ~= nil then
    TestModeArgs.Chi = {
      type = 'range',
      name = 'Chi',
      order = 501,
      desc = 'Change how many chi orbs are lit',
      width = 'full',
      step = 1,
      min = o.TestModeChiMin,
      max = o.TestModeChiMax,
    }
  end
  if UBD.TestMode.DeeperStratagem ~= nil then
    TestModeArgs.DeeperStratagem = {
      type = 'toggle',
      name = 'Deeper Stratagem',
      order = 600,
    }
  end
  if UBD.TestMode.ComboPoints ~= nil then
    TestModeArgs.ComboPoints = {
      type = 'range',
      name = 'Combo Points',
      order = 602,
      desc = 'Change how many combo points are lit',
      width = 'full',
      step = 1,
      min = o.TestModePointsMin,
      max = o.TestModePointsMax,
    }
  end
  if UBD.TestMode.ArcaneCharges ~= nil then
    TestModeArgs.ArcaneCharges = {
      type = 'range',
      name = 'Arcane Charges',
      order = 700,
      desc = 'Change how many arcane charges are lit',
      width = 'full',
      step = 1,
      min = o.TestModeArcaneChargesMin,
      max = o.TestModeArcaneChargesMax,
    }
  end
  if UBD.TestMode.StaggerPercent ~= nil then
    TestModeArgs.StaggerPercent = {
      type = 'range',
      name = 'Stagger',
      order = 800,
      step = .01,
      width = 'full',
      isPercent = true,
      min = o.TestModeStaggerMin,
      max = o.TestModeStaggerMax,
    }
  end
  if UBD.TestMode.StaggerPause ~= nil then
    TestModeArgs.StaggerPause = {
      type = 'range',
      name = 'Pause (seconds)',
      order = 801,
      step = .1,
      width = 'full',
      min = o.TestModeStaggerPauseMin,
      max = o.TestModeStaggerPauseMax,
    }
  end
  if UBD.TestMode.AltTypePower ~= nil then
    TestModeArgs.AltTypePower = {
      type = 'toggle',
      name = 'Power',
      order = 900,
      width = 'half',
      disabled = function()
                   return UBF.UnitBar.TestMode.AltTypeBoth
                 end,
    }
  end
  if UBD.TestMode.AltTypeCounter ~= nil then
    TestModeArgs.AltTypeCounter = {
      type = 'toggle',
      name = 'Counter',
      order = 901,
      width = 'half',
      disabled = function()
                   return UBF.UnitBar.TestMode.AltTypeBoth
                 end,
    }
  end
  if UBD.TestMode.AltTypeBoth ~= nil then
    TestModeArgs.AltTypeBoth = {
      type = 'toggle',
      name = 'Show Both',
      order = 902,
      desc = 'Lets you compare side by side, normally only one is visible'
    }
  end
  if UBD.TestMode.BothRotation ~= nil then
    TestModeArgs.BothRotation = {
      type = 'range',
      name = 'Rotation',
      order = 903,
      desc = 'Changes the orientation of the bar objects',
      step = 45,
      hidden = function()
                 return not UBF.UnitBar.TestMode.AltTypeBoth
               end,
      min = o.LayoutRotationMin,
      max = o.LayoutRotationMax,
    }
  end
  if UBD.TestMode.AltPowerName ~= nil then
    TestModeArgs.AltPowerName = {
      type = 'input',
      name = 'Power Name',
      order = 904,
    }
  end
  if UBD.TestMode.AltPower ~= nil then
    TestModeArgs.AltPower = {
      type = 'range',
      name = 'Alternate Power',
      order = 905,
      step = 1,
      width = 'full',
      min = o.TestModeAltPowerMin,
      max = o.TestModeAltPowerMax,
    }
  end
  if UBD.TestMode.AltPowerMax ~= nil then
    TestModeArgs.AltPowerMax = {
      type = 'range',
      name = 'Alternate Power Max',
      order = 906,
      step = 1,
      width = 'full',
      min = o.TestModeAltMaxPowerMin,
      max = o.TestModeAltMaxPowerMax,
    }
  end
  if UBD.TestMode.AltPowerBarID ~= nil then
    TestModeArgs.AltPowerBarID = {
      type = 'range',
      name = 'Alternate Power Bar ID',
      order = 907,
      step = 1,
      width = 'full',
      min = o.TestModeAltPowerBarIDMin,
      max = o.TestModeAltPowerBarIDMax,
    }
  end
  if UBD.TestMode.AltPowerTime ~= nil then
    TestModeArgs.AltPowerTime = {
      type = 'range',
      name = 'Alternate Power Time (counter only)',
      order = 908,
      step = 1,
      width = 'full',
      min = o.TestModeAltPowerTimeMin,
      max = o.TestModeAltPowerTimeMax,
      disabled = function()
                   local TestMode = UBF.UnitBar.TestMode
                   return TestMode.AltTypePower and not TestMode.AltTypeBoth
                 end,
    }
  end

  return TestModeOptions
end

-------------------------------------------------------------------------------
-- CreateMoreLayoutRuneBarOptions
--
-- Creates additional options that appear under layout for the rune bar.
--
-- Subfunction of CreateLayoutOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-------------------------------------------------------------------------------
local function CreateMoreLayoutRuneBarOptions(BarType, Order)
  local UBF = Main.UnitBarsF[BarType]

  local MoreLayoutRuneBarOptions = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Layout[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            UBF.UnitBar.Layout[KeyName] = Value

            -- Update the layout to show changes.
            UBF:SetAttr('Layout', KeyName)
          end,
    args = {
      RuneMode = {
        type = 'select',
        name = 'Rune Mode',
        order = 1,
        desc = 'Select the way runes are shown',
        values = RuneModeDropdown,
        style = 'dropdown',
      },
      Spacer20 = CreateSpacer(20),
      CooldownAnimation = {
        type = 'toggle',
        name = 'Cooldown Animation',
        order = 21,
        hidden = function()
                   return strfind(UBF.UnitBar.Layout.RuneMode, 'rune') == nil
                 end,
        desc = 'Shows the cooldown animation',
      },
      CooldownFlash = {
        type = 'toggle',
        name = 'Cooldown Flash',
        order = 22,
        hidden = function()
                   return strfind(UBF.UnitBar.Layout.RuneMode, 'rune') == nil
                 end,
        disabled = function()
                     return not UBF.UnitBar.Layout.CooldownAnimation
                   end,
        desc = 'Shows the flash animation after a rune comes off cooldown',
      },
      Spacer30 = CreateSpacer(30),
      BarSpark = {
        type = 'toggle',
        name = 'Bar Spark',
        order = 31,
        hidden = function()
                   return UBF.UnitBar.Layout.RuneMode == 'rune'
                 end,
        desc = 'Shows a spark on the bar animation',
      },
      CooldownLine = {
        type = 'toggle',
        name = 'Cooldown Line',
        order = 32,
        hidden = function()
                   return strfind(UBF.UnitBar.Layout.RuneMode, 'rune') == nil
                 end,
        disabled = function()
                     return not UBF.UnitBar.Layout.CooldownAnimation
                   end,
        desc = 'Shows a line on the cooldown animation',
      },
      RuneLocation = {
        type = 'group',
        name = 'Rune Location',
        dialogInline = true,
        order = 32,
        set = function(Info, Value)
                UBF.UnitBar.Layout[Info[#Info]] = Value

                -- Update the rune location.
                UBF:SetAttr('Layout', '_RuneLocation')
              end,
        hidden = function()
                   return UBF.UnitBar.Layout.RuneMode ~= 'runebar'
                 end,
        args = {
          RuneOffsetX = {
            type = 'range',
            name = 'Horizontal Offset',
            order = 1,
            min = o.RuneOffsetXMin,
            max = o.RuneOffsetYMax,
            step = 1,
          },
          RuneOffsetY = {
            type = 'range',
            name = 'Vertical Offset',
            order = 2,
            min = o.RuneOffsetYMin,
            max = o.RuneOffsetYMax,
            step = 1,
          },
          RunePosition = {
            type = 'select',
            name = 'Rune Position',
            order = 3,
            values = PositionDropdown,
            style = 'dropdown',
            desc = 'Position of the rune around the cooldown bar'
          },
        },
      },
    },
  }
  return MoreLayoutRuneBarOptions
end

-------------------------------------------------------------------------------
-- CreateMoreLayoutStaggerBarOptions
--
-- Creates additional options that appear under layout for the stagger bar.
--
-- Subfunction of CreateLayoutOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-------------------------------------------------------------------------------
local function CreateMoreLayoutStaggerBarOptions(BarType, Order)
  local UBF = Main.UnitBarsF[BarType]

  local MoreLayoutStaggerBarOptions = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Layout[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            UBF.UnitBar.Layout[KeyName] = Value

            -- Update the layout to show changes.
            UBF:SetAttr('Layout', KeyName)
          end,
    args = {
      Layered = {
        type = 'toggle',
        name = 'Layered',
        order = 1,
        desc = 'When the main stagger bar is full, it will be hidden while the second bar fills. Bar will have new options when this is active',
        disabled = function()
                     return UBF.UnitBar.Layout.SideBySide
                   end,
      },
      Overlay = {
        type = 'toggle',
        name = 'Overlay',
        order = 2,
        desc = 'When the main stagger bar is full it will remain visible while the second bar fills',
        disabled = function()
                     return UBF.UnitBar.Layout.SideBySide or not UBF.UnitBar.Layout.Layered
                   end,
      },
      SideBySide = {
        type = 'toggle',
        name = 'Side by Side',
        order = 3,
        desc = 'Main stagger and second bar is merged as one. Bar will have new options when this is active',
        disabled = function()
                     return UBF.UnitBar.Layout.Layered
                   end,
      },
      Spacer10 = CreateSpacer(10),
      PauseTimer = {
        type = 'toggle',
        name = 'Pause Timer',
        order = 11,
        desc = 'Displays a bar for when stagger gets paused',
      },
      PauseTimerAutoHide = {
        type = 'toggle',
        name = 'Pause Timer Autohide',
        order = 12,
        desc = "Hides the Pause Timer after it's finished",
        disabled = function()
                     return not UBF.UnitBar.Layout.PauseTimer
                   end
      },
    },
  }
  return MoreLayoutStaggerBarOptions
end

-------------------------------------------------------------------------------
-- CreateMoreLayoutAltPowerBarOptions
--
-- Creates additional options that appear under layout for the alternate power bar.
--
-- Subfunction of CreateLayoutOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-------------------------------------------------------------------------------
local function CreateMoreLayoutAltPowerBarOptions(BarType, Order)
  local UBF = Main.UnitBarsF[BarType]

  local MoreLayoutAltPowerBarOptions = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Layout[Info[#Info] ]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            UBF.UnitBar.Layout[KeyName] = Value

            -- Update the layout to show changes.
            UBF:SetAttr('Layout', KeyName)
          end,
    args = {
      UseBarColor = {
        type = 'toggle',
        name = 'Use Bar Color',
        order = 1,
        desc = 'Use bar color instead of alternate power color. Testmode always uses bar color',
      },
    },
  }

  return MoreLayoutAltPowerBarOptions
end

-------------------------------------------------------------------------------
-- CreateMoreLayoutOptions
--
-- Subfunction of CreateLayoutOptions
--
-- Creates additional options that appear in the layout. Not all bars use this.
--
-- BarType     Type of bar options being craeted for.
-- Order       Where to place options on screen.
-------------------------------------------------------------------------------
local function CreateMoreLayoutOptions(BarType, Order)
  local UBF = Main.UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local MoreLayoutOptions = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = Order,
    get = function(Info)
            return UBF.UnitBar.Layout[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local Layout = UBF.UnitBar.Layout

            if KeyName == 'ClassColor' and Value then
              Layout.CombatColor = false
            elseif KeyName == 'CombatColor' and Value then
              Layout.ClassColor = false
            end

            Layout[KeyName] = Value
            UBF:SetAttr('Layout', KeyName)
          end,
    args = {}
  }

  local MoreLayoutArgs = MoreLayoutOptions.args

  -- Health and power bar options.
  if UBD.Layout.UseBarColor ~= nil then
    MoreLayoutArgs.UseBarColor = {
      type = 'toggle',
      name = 'Use Bar Color',
      order = 1,
      desc = 'Use bar color instead of power color',
    }
  end
  if UBD.Layout.PredictedHealth ~= nil then
    MoreLayoutArgs.PredictedHealth = {
      type = 'toggle',
      name = 'Predicted Health',
      order = 2,
      desc = 'Predicted health will be shown',
    }
  end
  if UBD.Layout.AbsorbHealth ~= nil then
    MoreLayoutArgs.AbsorbHealth = {
      type = 'toggle',
      name = 'Absorb Health',
      order = 3,
      desc = 'Absorb health will be shown',
    }
  end
  if UBD.Layout.PredictedPower ~= nil then
    MoreLayoutArgs.PredictedPower = {
      type = 'toggle',
      name = 'Predicted Power',
      order = 4,
      desc = 'Show predicted power of spells that return power with a cast time',
    }
  end
  if UBD.Layout.PredictedCost ~= nil then
    MoreLayoutArgs.PredictedCost = {
      type = 'toggle',
      name = 'Predicted Cost',
      order = 6,
      desc = 'Show predicted cost of spells that cost power with a cast time',
    }
  end
  if UBD.Layout.ClassColor ~= nil then
    MoreLayoutArgs.ClassColor = {
      type = 'toggle',
      name = 'Class Color',
      order = 6,
      desc = 'Show class color',
    }
  end
  if UBD.Layout.CombatColor ~= nil then
    MoreLayoutArgs.CombatColor = {
      type = 'toggle',
      name = 'Combat Color',
      order = 7,
      desc = 'Show combat color',
    }
  end
  if UBD.Layout.TaggedColor ~= nil then
    MoreLayoutArgs.TaggedColor = {
      type = 'toggle',
      name = 'Tagged Color',
      order = 8,
      desc = 'Shows if the target is tagged by another player',
    }
  end
  if UBD.Layout.TextureScaleCombo ~= nil then
    MoreLayoutArgs.TextureScaleCombo = {
      type = 'range',
      name = 'Texture Scale (Combo)',
      order = 9,
      desc = 'Changes the texture size of the combo point objects',
      step = 0.01,
      isPercent = true,
      disabled = function()
                   return Flag(true, UBF.UnitBar.Layout.BoxMode)
                 end,
      min = o.LayoutTextureScaleMin,
      max = o.LayoutTextureScaleMax,
    }
  end
  if UBD.Layout.BurningEmbers ~= nil then
    MoreLayoutArgs.BurningEmbers = {
      type = 'toggle',
      name = 'Burning Embers',
      order = 12,
      desc = 'Changes the shards into burning embers',
    }
  end
  if UBD.Layout.GreenFire ~= nil then
    MoreLayoutArgs.GreenFire = {
      type = 'toggle',
      name = 'Green Fire',
      order = 13,
      desc = 'Use green fire',
      disabled = function()
                   return UBF.UnitBar.Layout.GreenFireAuto
                 end,
    }
  end
  if UBD.Layout.GreenFireAuto ~= nil then
    MoreLayoutArgs.GreenFireAuto = {
      type = 'toggle',
      name = 'Green Fire Auto',
      order = 14,
      desc = 'Use green fire if available',
      disabled = function()
                   return UBF.UnitBar.Layout.GreenFire
                 end,
    }
  end

  return MoreLayoutOptions
end

-------------------------------------------------------------------------------
-- CreateLayoutOptions
--
-- Subfunction of CreateUnitBarOptions
--
-- BarType       The options being created for.
-- Order         Where the options appear on screen.
-- Name          Name of the options.
-------------------------------------------------------------------------------
local function CreateLayoutOptions(BarType, Order, Name)
  local UBF = Main.UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local LayoutOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    args = {
      General = {
        type = 'group',
        name = 'General',
        order = 2,
        get = function(Info)
                return UBF.UnitBar.Layout[Info[#Info]]
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]

                if KeyName == 'Swap' and Value then
                  UBF.UnitBar.Layout.Align = false
                  UBF:SetAttr('Layout', 'Align')
                elseif KeyName == 'Align' and Value then
                  UBF.UnitBar.Layout.Swap = false
                  UBF:SetAttr('Layout', 'Swap')
                end
                UBF.UnitBar.Layout[KeyName] = Value

                if KeyName == 'HideText' then

                  -- Update any text highlights.  We use 'on' since its always on when options are opened.
                  Bar:SetHighlightFont('on', Main.UnitBars.HideTextHighlight)
                end

                -- Update the layout to show changes.
                UBF:SetAttr('Layout', KeyName)

                -- Create triggers only after layout has been set.
                if KeyName == 'EnableTriggers' and Value then
                  Options:DoFunction(BarType, 'CreateTriggerOptions')
                end
              end,
        args = {},
      },
    },
  }

  -- Create test mode options.
  if UBD.TestMode ~= nil then
    LayoutOptions.args.TestMode = CreateTestModeOptions(BarType, 1, 'Test Mode')
  end

  local GeneralArgs = LayoutOptions.args.General.args
  local Spacer = false

  -- Create more layout options.
  if UBD.Layout._More then
    if BarType == 'RuneBar' then
      GeneralArgs.MoreLayout = CreateMoreLayoutRuneBarOptions(BarType, 1)
    elseif BarType == 'StaggerBar' then
      GeneralArgs.MoreLayout = CreateMoreLayoutStaggerBarOptions(BarType, 1)
    elseif BarType == 'AltPowerBar' then
      GeneralArgs.MoreLayout = CreateMoreLayoutAltPowerBarOptions(BarType, 1)
    else
      GeneralArgs.MoreLayout = CreateMoreLayoutOptions(BarType, 1)
    end
    -- Delete more layout if it has no options.
    if next(GeneralArgs.MoreLayout.args) == nil then
      GeneralArgs.MoreLayout = nil
      GeneralArgs.Seperator = nil
    else
      -- Create seperator line
      GeneralArgs.Seperator = {
        type = 'header',
        name = '',
        order = 2,
      }
    end
  end

  if UBD.Layout.BoxMode ~= nil then
    Spacer = true
    GeneralArgs.BoxMode = {
      type = 'toggle',
      name = 'Box Mode',
      order = 10,
      desc = 'Switches from texture mode to box mode',
    }
  end
  if Spacer then
    GeneralArgs.Spacer11 = CreateSpacer(11)
    Spacer = false
  end

  if UBD.Layout.EnableTriggers ~= nil then
    Spacer = true
    GeneralArgs.EnableTriggers = {
      type = 'toggle',
      name = 'Enable Triggers',
      order = 12,
      desc = 'Acitvates all triggers for this bar and shows the trigger options',
    }
  end
  if UBD.Layout.HideRegion ~= nil then
    Spacer = true
    GeneralArgs.HideRegion = {
      type = 'toggle',
      name = 'Hide Region',
      order = 13,
      desc = "Hides the bar's region",
    }
  end
  if Spacer then
    GeneralArgs.Spacer20 = CreateSpacer(20)
    Spacer = false
  end

  if UBD.Layout.ReverseFill ~= nil then
    Spacer = true
    GeneralArgs.ReverseFill = {
      type = 'toggle',
      name = 'Reverse fill',
      order = 21,
      desc = 'Fill in reverse',
    }
  end
  if UBD.Layout.HideText ~= nil then
    Spacer = true
    GeneralArgs.HideText = {
      type = 'toggle',
      name = 'Hide Text',
      order = 22,
      desc = 'Hides all text',
    }
  end

  if BarType == 'StaggerBar' or BarType == 'AltPowerBar' then
    Spacer = true

    if BarType == 'StaggerBar' then
      GeneralArgs.HideTextPause = {
        type = 'toggle',
        name = 'Hide Text (pause)',
        order = 23,
        desc = 'Hides all text on the pause timer',
        disabled = function()
                     return not UBF.UnitBar.Layout.PauseTimer
                   end,
      }
    else
      GeneralArgs.HideTextCounter = {
        type = 'toggle',
        name = 'Hide Text (counter)',
        order = 23,
        desc = 'Hides all text on the counter bar',
      }
    end
  end

  if Spacer then
    GeneralArgs.Spacer30 = CreateSpacer(30)
    Spacer = false
  end

  if UBD.Layout.FillDirection ~= nil then
    Spacer = true
    GeneralArgs.FillDirection = {
      type = 'select',
      name = 'Fill Direction',
      order = 31,
      values = DirectionDropdown,
      style = 'dropdown',
    }
    if BarType == 'FragmentBar' then
      local FillDirection = GeneralArgs.FillDirection
      FillDirection.name = 'Fill Direction (texture mode)'
      FillDirection.disabled = function()
                                 return UBF.UnitBar.Layout.BoxMode
                               end
    end
  end
  if Spacer then
    GeneralArgs.Spacer40 = CreateSpacer(40)
    Spacer = false
  end

  if UBD.Layout.SmoothFillMaxTime ~= nil then
    Spacer = true
    GeneralArgs.SmoothFillMaxTime = {
      type = 'range',
      name = 'Smooth Fill Max Time',
      order = 41,
      desc = 'Sets the maximum amount of time in seconds a smooth fill can take',
      step = 0.01,
      min = o.LayoutSmoothFillMaxTimeMin,
      max = o.LayoutSmoothFillMaxTimeMax,
    }
    GeneralArgs.SmoothFillSpeed = {
      type = 'range',
      name = 'Smooth Fill Speed',
      order = 42,
      desc = 'Changes the fill animaton speed',
      step = 0.01,
      isPercent = true,
      disabled = function()
                   return UBF.UnitBar.Layout.SmoothFillMaxTime == 0
                 end,
      min = o.LayoutSmoothFillSpeedMin,
      max = o.LayoutSmoothFillSpeedMax,
    }
  end

  if Spacer then
    GeneralArgs.Spacer80 = CreateSpacer(80)
    Spacer = false
  end

  -------------------------
  -- Create objects options
  -------------------------
  GeneralArgs.Objects = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = 81,
    hidden = function()
               if BarType == 'StaggerBar' then
                 return not UBF.UnitBar.Layout.PauseTimer
               else
                 return false
               end
             end,
    args = {},
  }
  local ObjectsArgs = GeneralArgs.Objects.args
  local ObjectsFlag = false

  -- Create seperator line
  ObjectsArgs.Seperator = {
    type = 'header',
    name = '',
    order = 0,
  }

  if UBD.Layout.Swap ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Swap = {
      type = 'toggle',
      name = 'Swap',
      order = 1,
      desc = 'Allows you to swap one bar object with another by dragging it',
    }
  end
  if UBD.Layout.Float ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Float = {
      type = 'toggle',
      name = 'Float',
      order = 2,
      desc = 'Switches to floating mode.  Bar objects can be placed anywhere. Float options will be open below',
    }
  end

  if UBD.Layout.AnimationType ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Spacer10 = CreateSpacer(10)

    ObjectsArgs.AnimationType = {
      type = 'select',
      name = BarType ~= 'FragmentBar' and 'Animation Type' or 'Animation Type (full)',
      order = 11,
      style = 'dropdown',
      desc = 'Changes the type of animation played when showing or hiding bar objects',
      values = AnimationTypeDropdown,
    }
  end
  if Spacer then
    ObjectsArgs.Spacer20 = CreateSpacer(20)
    Spacer = false
  end

  if UBD.Layout.BorderPadding ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.BorderPadding = {
      type = 'range',
      name = 'Border Padding',
      order = 21,
      desc = "Changes the distance between the region's border and the bar objects",
      step = 1,
      disabled = function()
                   return UBF.UnitBar.Layout.HideRegion
                 end,
      min = o.LayoutBorderPaddingMin,
      max = o.LayoutBorderPaddingMax,
    }
  end

  if UBD.Layout.Rotation ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Rotation = {
      type = 'range',
      name = 'Rotation',
      order = 22,
      desc = 'Changes the orientation of the bar objects',
      step = 45,
      disabled = function()
                   return Flag(false, UBF.UnitBar.Layout.Float)
                 end,
      min = o.LayoutRotationMin,
      max = o.LayoutRotationMax,
    }
  end
  if Spacer then
    ObjectsArgs.Spacer30 = CreateSpacer(30)
    Spacer = false
  end

  if UBD.Layout.Slope ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Slope = {
      type = 'range',
      name = 'Slope',
      order = 31,
      desc = 'Makes the bar objects slope up or down when the rotation is horizontal or vertical',
      step = 1,
      disabled = function()
                   return Flag(false, UBF.UnitBar.Layout.Float) or UBF.UnitBar.Layout.Rotation % 90 ~= 0
                 end,
      min = o.LayoutSlopeMin,
      max = o.LayoutSlopeMax,
    }
  end
  if UBD.Layout.Padding ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.Padding = {
      type = 'range',
      name = 'Padding',
      order = 32,
      desc = 'Changes the space between each bar object',
      step = 1,
      disabled = function()
                   return Flag(false, UBF.UnitBar.Layout.Float)
                 end,
      min = o.LayoutPaddingMin,
      max = o.LayoutPaddingMax,
    }
  end
  if Spacer then
    ObjectsArgs.Spacer40 = CreateSpacer(40)
    Spacer = false
  end

  if UBD.Layout.TextureScale ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.TextureScale = {
      type = 'range',
      name = 'Texture Scale',
      order = 41,
      desc = 'Changes the texture size of the bar objects',
      step = 0.01,
      isPercent = true,
      disabled = function()
                   return BarType ~= 'RuneBar' and Flag(true, UBF.UnitBar.Layout.BoxMode) or
                          BarType == 'RuneBar' and strsub(UBF.UnitBar.Layout.RuneMode, 1, 4) ~= 'rune'
                 end,
      min = o.LayoutTextureScaleMin,
      max = o.LayoutTextureScaleMax,
    }
  end
  if Spacer then
    ObjectsArgs.Spacer50 = CreateSpacer(50)
    Spacer = false
  end

  if UBD.Layout.AnimationInTime ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.AnimationInTime = {
      type = 'range',
      name = BarType ~= 'FragmentBar' and 'Animation-in' or 'Animation-in (full)',
      order = 51,
      desc = 'The amount of time in seconds to play animation after showing a bar object',
      step = 0.1,
      min = o.LayoutAnimationInTimeMin,
      max = o.LayoutAnimationInTimeMax,
    }
  end
  if UBD.Layout.AnimationOutTime ~= nil then
    Spacer = true
    ObjectsFlag = true
    ObjectsArgs.AnimationOutTime = {
      type = 'range',
      name = BarType ~= 'FragmentBar' and 'Animation-out' or 'Animation-out (full)',
      order = 52,
      desc = 'The amount of time in seconds to play animation after showing a bar object',
      step = 0.1,
      min = o.LayoutAnimationOutTimeMin,
      max = o.LayoutAnimationOutTimeMax,
    }
  end
  if Spacer then
    ObjectsArgs.Spacer60 = CreateSpacer(60)
  end

  -- Float options
  if UBD.Layout.Float ~= nil then
    ObjectsFlag = true
    ObjectsArgs.FloatOptions = {
      type = 'group',
      name = 'Float Options',
      dialogInline = true,
      order = 101,
      hidden = function()
                 return not UBF.UnitBar.Layout.Float
               end,
      args = {
        Align = {
          type = 'toggle',
          name = 'Align',
          order = 1,
          desc = 'When a bar object is dragged near another it will align its self to it',
        },
        AlignGroup = {
          type = 'group',
          name = 'Align',
          dialogInline = true,
          order = 2,
          hidden = function()
                     return not UBF.UnitBar.Layout.Align
                   end,
          args = {
            Spacer10 = CreateSpacer(10),
            AlignPaddingX = {
              type = 'range',
              name = 'Padding Horizontal',
              order = 11,
              desc = 'Sets the distance between two or more bar objects that are aligned horizontally',
              step = 1,
              min = o.LayoutAlignPaddingXMin,
              max = o.LayoutAlignPaddingXMax,
            },
            AlignPaddingY = {
              type = 'range',
              name = 'Padding Vertical',
              order = 12,
              desc = 'Sets the distance between two or more bar objects that are aligned vertically',
              step = 1,
              min = o.LayoutAlignPaddingXMin,
              max = o.LayoutAlignPaddingXMax,
            },
            Spacer20 = CreateSpacer(20),
            AlignOffsetX = {
              type = 'range',
              name = 'Horizontal Offset',
              order = 21,
              desc = 'Offsets the padding group',
              step = 1,
              min = o.LayoutAlignOffsetXMin,
              max = o.LayoutAlignOffsetXMax,
            },
            AlignOffsetY = {
              type = 'range',
              name = 'Vertical Offset',
              order = 22,
              desc = 'Offsets the padding group',
              step = 1,
              min = o.LayoutAlignOffsetYMin,
              max = o.LayoutAlignOffsetYMax,
            },
          },
        },
      },
    }
    if UBF.UnitBar.Layout.Float ~= nil then
      local FloatArgs = ObjectsArgs.FloatOptions.args

      ObjectsFlag = true
      FloatArgs.Spacer30 = CreateSpacer(30)
      FloatArgs.ResetFloat = {
        type = 'execute',
        name = 'Copy Layout',
        order = 3,
        desc = 'Copy the normal mode layout to float',
        confirm = true,
        disabled = function()
                     return not UBF.UnitBar.Layout.Float
                   end,
        func = function()
                 UBF.BBar:CopyLayoutFloatBar()
                 UBF.BBar:Display()
               end
      }
    end
  end
  if not ObjectsFlag then
    GeneralArgs.Objects = nil
  end

  return LayoutOptions
end

-------------------------------------------------------------------------------
-- CreateResetOptions
--
-- SubFunction of CreateOtherOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
--
-- NOTES:  Reset options are created here and saved into defaults.
--         This way I don't have to maintain two sets of lists.
--         TablePath must lead to a table only if its more than one level deep.
-------------------------------------------------------------------------------
local function CreateResetOptions(BarType, Order, Name)
  local UBF = Main.UnitBarsF[BarType]
  local UBD = DUB[BarType]
  local ResetList = {}

  TableData = TableData or { -- For keynames, only the first one has to exist.
    All                       = { Name = 'All',                  Order =   1, Width = 'half' },
    Location                  = { Name = 'Location',             Order =   2, Width = 'half',   TablePaths = {'_x', '_y'} },
    Specialization            = { Name = 'Spec',                 Order =   3, Width = 'half',   TablePaths = {'ClassSpecs'} },
    Status                    = { Name = 'Status',               Order =   4, Width = 'half',   TablePaths = {'Status'} },
    Test                      = { Name = 'Test',                 Order =   5, Width = 'half',   TablePaths = {'TestMode'} },
    Layout                    = { Name = 'Layout',               Order =   6, Width = 'half',   TablePaths = {'Layout', 'BoxLocations', 'BoxOrder'} },
    Region                    = { Name = 'Region',               Order =   7, Width = 'half',   TablePaths = {'Region'} },
    Text                      = { Name = 'Text',                 Order =   8, Width = 'half',   TablePaths = {'Text'} },
    TextPause                 = { Name = 'Text (pause)',         Order =   9, Width = 'normal', BarType = 'StaggerBar',  TablePaths = {'Text2'} },
    TextCounter               = { Name = 'Text (counter)',       Order =  10, Width = 'normal', BarType = 'AltPowerBar', TablePaths = {'Text2'} },
    Triggers                  = { Name = 'Triggers',             Order =  11, Width = 'half',   TablePaths = {'Triggers'} },
    Attributes                = { Name = 'Attributes',           Order =  12, Width = 'normal', TablePaths = {'Attributes'} },
    --------------------------
    HEADER2 = { Order = 100, Name = 'Background' },

    BG                        = { Name = 'Background',           Order = 101, Width = 'wide',   TablePaths = {'Background'} },

    BGShard                   = { Name = 'Shard',                Order = 102, Width = 'wide',   TablePaths = {'BackgroundShard'} },
    BGEmber                   = { Name = 'Ember',                Order = 103, Width = 'wide',   TablePaths = {'BackgroundEmber'} },

    BGStagger                 = { Name = 'Stagger',              Order = 104, Width = 'wide',   TablePaths = {'BackgroundStagger'} },
    BGPause                   = { Name = 'Pause',                Order = 105, Width = 'wide',   TablePaths = {'BackgroundPause'} },

    BGAltPower                = { Name = 'Power',                Order = 106, Width = 'wide',   TablePaths = {'BackgroundPower'} },
    BGAltCounter              = { Name = 'Counter',              Order = 107, Width = 'wide',   TablePaths = {'BackgroundCounter'} },
    --------------------------
    HEADER3 = { Order = 200, Name = 'Bar' },

    Bar                       = { Name = 'Bar',                  Order = 201, Width = 'wide',   TablePaths = {'Bar'} },

    BarShard                  = { Name = 'Shard',                Order = 202, Width = 'wide',   TablePaths = {'BarShard'} },
    BarEmber                  = { Name = 'Ember',                Order = 203, Width = 'wide',   TablePaths = {'BarEmber'} },

    BarStagger                = { Name = 'Stagger',              Order = 204, Width = 'wide',   TablePaths = {'BarStagger'} },
    BarPause                  = { Name = 'Pause',                Order = 205, Width = 'wide',   TablePaths = {'BarPause'} },

    BarAltPower               = { Name = 'Power',                Order = 206, Width = 'wide',   TablePaths = {'BarPower'} },
    BarAltCounter             = { Name = 'Counter',              Order = 207, Width = 'wide',   TablePaths = {'BarCounter'} },
    --------------------------
    HEADER1 = { Order = 300, Name = 'Region Color', CheckTable = 'Region.Color' },

    RegionColorBG             = { Name = 'Background',           Order = 301, Width = 'wide',   TablePaths = {'Region.Color'} },
    RegionBorderColor         = { Name = 'Border',               Order = 302, Width = 'wide',   TablePaths = {'Region.BorderColor'} },
    --------------------------
    HEADER5 = { Order = 400, Name = 'Background Color' },

    BGColor                   = { Name = 'Background Color',     Order = 401, Width = 'wide',   TablePaths = {'Background.Color'} },
    BGBorderColor             = { Name = 'Border Color',         Order = 402, Width = 'wide',   TablePaths = {'Background.BorderColor'} },

    BGColorShard              = { Name = 'Shard',                Order = 403, Width = 'wide',   TablePaths = {'BackgroundShard.Color'} },
    BGColorEmber              = { Name = 'Ember',                Order = 404, Width = 'wide',   TablePaths = {'BackgroundEmber.Color'} },
    BGBorderColorShard        = { Name = 'Shard Border',         Order = 405, Width = 'wide',   TablePaths = {'BackgroundShard.BorderColor'} },
    BGBorderColorEmber        = { Name = 'Ember Border',         Order = 406, Width = 'wide',   TablePaths = {'BackgroundEmber.BorderColor'} },
    BGColorShardGreen         = { Name = 'Shard [Green]',        Order = 407, Width = 'wide',   TablePaths = {'BackgroundShard.ColorGreen'} },
    BGColorEmberGreen         = { Name = 'Ember [Green]',        Order = 408, Width = 'wide',   TablePaths = {'BackgroundEmber.ColorGreen'} },
    BGBorderColorShardGreen   = { Name = 'Shard Border [Green]', Order = 409, Width = 'wide',   TablePaths = {'BackgroundShard.BorderColorGreen'} },
    BGBorderColorEmberGreen   = { Name = 'Ember Border [Green]', Order = 410, Width = 'wide',   TablePaths = {'BackgroundEmber.BorderColorGreen'} },

    BGColorBlood              = { Name = 'Blood',                Order = 413, Width = 'wide',   TablePaths = {'Background.ColorBlood'} },
    BGColorFrost              = { Name = 'Frost',                Order = 414, Width = 'wide',   TablePaths = {'Background.ColorFrost'} },
    BGColorUnholy             = { Name = 'Unholy',               Order = 415, Width = 'wide',   TablePaths = {'Background.ColorUnholy'} },
    BGBorderColorBlood        = { Name = 'Blood Border',         Order = 416, Width = 'wide',   TablePaths = {'Background.BorderColorBlood'} },
    BGBorderColorFrost        = { Name = 'Frost Border',         Order = 417, Width = 'wide',   TablePaths = {'Background.BorderColorFrost'} },
    BGBorderColorUnholy       = { Name = 'Unholy Border',        Order = 418, Width = 'wide',   TablePaths = {'Background.BorderColorUnholy'} },

    BGColorStagger            = { Name = 'Stagger',              Order = 419, Width = 'wide',   TablePaths = {'BackgroundStagger.Color'} },
    BGColorPause              = { Name = 'Pause',                Order = 420, Width = 'wide',   TablePaths = {'BackgroundPause.Color'} },
    BGBorderColorStagger      = { Name = 'Stagger Border',       Order = 421, Width = 'wide',   TablePaths = {'BackgroundStagger.BorderColor'} },
    BGBorderColorPause        = { Name = 'Pause Border',         Order = 422, Width = 'wide',   TablePaths = {'BackgroundPause.BorderColor'} },

    BGColorAltPower           = { Name = 'Power',                Order = 423, Width = 'wide',   TablePaths = {'BackgroundPower.Color'} },
    BGColorAltCounter         = { Name = 'Counter',              Order = 424, Width = 'wide',   TablePaths = {'BackgroundCounter.Color'} },
    BGBorderColorAltPower     = { Name = 'Power Border',         Order = 425, Width = 'wide',   TablePaths = {'BackgroundPower.BorderColor'} },
    BGBorderColorAltCounter   = { Name = 'Counter Border',       Order = 426, Width = 'wide',   TablePaths = {'BackgroundCounter.BorderColor'} },
    --------------------------
    HEADER4 = { Order = 500, Name = 'Bar Color' },

    BarColor                  = { Name = 'Bar Color',            Order = 501, Width = 'wide',   TablePaths = {'Bar.Color'} },
    BarColorPredicted         = { Name = 'Predicted',            Order = 502, Width = 'wide',   TablePaths = {'Bar.PredictedColor'} },
    BarColorPredictedCost     = { Name = 'Predicted Cost',       Order = 503, Width = 'wide',   TablePaths = {'Bar.PredictedCostColor'} },
    BarColorAbsorbHealth      = { Name = 'Absorb Health',        Order = 504, Width = 'wide',   TablePaths = {'Bar.AbsorbColor'} },

    BarColorShard             = { Name = 'Shard',                Order = 505, Width = 'wide',   TablePaths = {'BarShard.Color'} },
    BarColorEmber             = { Name = 'Ember',                Order = 506, Width = 'wide',   TablePaths = {'BarEmber.Color'} },
    BarColorShardFull         = { Name = 'Shard (full)',         Order = 507, Width = 'wide',   TablePaths = {'BarShard.ColorFull'} },
    BarColorEmberFull         = { Name = 'Ember (full)',         Order = 508, Width = 'wide',   TablePaths = {'BarEmber.ColorFull'} },
    BarColorShardGreen        = { Name = 'Shard [Green]',        Order = 509, Width = 'wide',   TablePaths = {'BarShard.ColorGreen'} },
    BarColorEmberGreen        = { Name = 'Ember [Green]',        Order = 510, Width = 'wide',   TablePaths = {'BarEmber.ColorGreen'} },
    BarColorShardFullGreen    = { Name = 'Shard (full) [Green]', Order = 511, Width = 'wide',   TablePaths = {'BarShard.ColorFullGreen'} },
    BarColorEmberFullGreen    = { Name = 'Ember (full) [Green]', Order = 512, Width = 'wide',   TablePaths = {'BarEmber.ColorFullGreen'} },

    BarColorBlood             = { Name = 'Blood',                Order = 513, Width = 'wide',   TablePaths = {'Bar.ColorBlood'} },
    BarColorFrost             = { Name = 'Frost',                Order = 514, Width = 'wide',   TablePaths = {'Bar.ColorFrost'} },
    BarColorUnholy            = { Name = 'Unholy',               Order = 515, Width = 'wide',   TablePaths = {'Bar.ColorUnholy'} },

    BarColorStagger           = { Name = 'Stagger',              Order = 516, Width = 'wide',   TablePaths = {'BarStagger.Color'} },
    BarColorStaggerCont       = { Name = 'Stagger (Continued)',  Order = 517, Width = 'wide',   TablePaths = {'BarStagger.BStaggerColor'} },
    BarColorPause             = { Name = 'Pause',                Order = 518, Width = 'wide',   TablePaths = {'BarPause.Color'} },

    BarColorAltPower          = { Name = 'Power',                Order = 519, Width = 'wide',   TablePaths = {'BarPower.Color'} },
    BarColorAltCounter        = { Name = 'Counter',              Order = 520, Width = 'wide',   TablePaths = {'BarCounter.Color'} },
  }

  Options:DoFunction(BarType, 'ResetOptions', function()
    local Reset = Main.UnitBars.Reset

    -- Set defauls for reset in the unitbar
    for Name in pairs(TableData) do
      if strfind(Name, 'HEADER') == nil and Reset[Name] == nil then
        Reset[Name] = false
      end    end
    -- Delete entries that don't exist
    for Name in pairs(Reset) do
      if strfind(Name, 'HEADER') ~= nil or TableData[Name] == nil then
        Reset[Name] = nil
      end
    end
  end)

  Options:DoFunction(BarType, 'ResetOptions')

  local ResetOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            return Main.UnitBars.Reset[Info.arg]
          end,
    set = function(Info, Value)
            Main.UnitBars.Reset[Info.arg] = Value
          end,
    args = {
      Reset = {
        type = 'execute',
        order = 1,
        name = 'Reset',
        width = 'half',
        desc = 'Clicking this will reset the current items checked off below',
        confirm = true,
        func = function()
                 local UB = UBF.UnitBar
                 local UnitBars = Main.UnitBars

                 if UnitBars.Reset.All then
                   -- Do a deep copy that will copy underscore keys
                   Main:DeepCopy(UBD, UB)
                 else

                   -- Find the keys
                   for Name, TablePaths in pairs(ResetList) do

                     -- Only do the ones that are checked
                     if UnitBars.Reset[Name] then
                       for _, TablePath in ipairs(TablePaths) do

                         -- Get from default
                         local UBDv = Main:GetUB(BarType, TablePath, DUB)
                         -- Get from unitbar
                         local UBv = Main:GetUB(BarType, TablePath)

                         if UBv ~= nil then
                           if type(UBv) ~= 'table' then -- TablePath is a key here
                             UB[TablePath] = UBD[TablePath]
                           elseif UBDv then  -- copy table if found in defaults
                             Main:DeepCopy(UBDv, UBv)
                           else -- empty table since its not in defaults
                             wipe(UBv)
                           end
                         end
                       end
                     end
                   end
                 end

                 -- Update the layout.
                 Main.Reset = true

                 UBF:SetAttr()
                 UBF:Update()

                 -- Update any text highlights.  Use 'on' since its always on when options are opened.
                 Bar:SetHighlightFont('on', UnitBars.HideTextHighlight)

                 -- Update any dynamic options.
                 Options:DoFunction()

                 Main.Reset = false
               end,
        disabled = function()
                     if Main.UnitBars.Reset.All then
                       return false
                     else
                       local Disabled = true


                       for Name in pairs(ResetList) do
                         if Main.UnitBars.Reset[Name] then
                           Disabled = false
                         end
                       end
                       return Disabled
                     end
                   end,
      },
      Spacer10 = CreateSpacer(10),
      Notes = {
        type = 'description',
        name = 'Check off what to reset',
        order = 11,
      },
      Spacer1000 = CreateSpacer(1000),
    },
  }

  local Args = ResetOptions.args
  local Index = 1

  -- Only add check boxes that are found in the unitbar
  for Name, Table in pairs(TableData) do
    if strfind(Name, 'HEADER') then
      local CheckTable = Table.CheckTable

      if CheckTable == nil or Main:GetUB(BarType, CheckTable) ~= nil then
        Args[Name] = {
          type = 'header',
          name = Table.Name,
          order = 1000 + Table.Order,
          hidden = function()
                     return Name ~= 'All' and Main.UnitBars.Reset.All
                   end,
        }
      end
    else
      local TablePaths = Table.TablePaths

      -- option button if table path found.
      if ( Name == 'All' or Main:GetUB(BarType, TablePaths[1]) ) and (Table.BarType == nil or Table.BarType == BarType) then
        Args['ResetOption' .. Index] = {
          type = 'toggle',
          name = Table.Name,
          order = 1000 + Table.Order,
          width = Table.Width,
          hidden = function()
                     return Name ~= 'All' and Main.UnitBars.Reset.All
                   end,
          arg = Name,
        }
        if Name ~= 'All' then
          ResetList[Name] = TablePaths
        end
        Index = Index + 1
      end
    end
  end

  return ResetOptions
end

-------------------------------------------------------------------------------
-- CreateAttributeOptions
--
-- SubFunction of CreateUnitBarOptions
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateAttributeOptions(BarType, Order, Name)
  local UBF = Main.UnitBarsF[BarType]

  local AttributeOptions = {
    type = 'group',
    name = Name,
    dialogInline = true,
    order = Order,
    get = function(Info)
            local KeyName = Info[#Info]

            if KeyName == 'FrameStrata' then
              return ConvertFrameStrata[UBF.UnitBar.Attributes.FrameStrata]
            else
              return UBF.UnitBar.Attributes[KeyName]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local Attr = UBF.UnitBar.Attributes

            if KeyName == 'AnchorPoint' then
              Attr[KeyName] = Value
              Main:SetAnchorPoint(UBF.Anchor)
            else
              if KeyName == 'FrameStrata' then
                Value = ConvertFrameStrata[Value]
              end
              Attr[KeyName] = Value
              UBF:SetAttr('Attributes', KeyName)
            end
          end,
    args = {
      Scale = {
        type = 'range',
        name = 'Scale',
        order = 1,
        desc = 'Changes the scale of the bar',
        min = o.UnitBarScaleMin,
        max = o.UnitBarScaleMax,
        step = 0.01,
        isPercent  = true,
      },
      Alpha = {
        type = 'range',
        name = 'Alpha',
        order = 2,
        desc = 'Changes the transparency of the bar',
        min = o.UnitBarAlphaMin,
        max = o.UnitBarAlphaMax,
        step = 0.01,
        isPercent = true,
      },
      AnchorPoint = {
        type = 'select',
        name = 'Anchor Point',
        order = 3,
        style = 'dropdown',
        desc = 'Change the anchor point of the bar.  This effects where the bar will change size from',
        values = PositionDropdown,
      },
      FrameStrata = {
        type = 'select',
        name = 'Frame Strata',
        order = 4,
        desc = 'Sets the frame strata making the bar appear below or above other frames',
        values = FrameStrataDropdown,
        style = 'dropdown',
      },
      MainAnimationType = {
        type = 'toggle',
        name = 'Main Animation Type',
        order = 5,
        desc = 'Uses the Animation Type setting in Main Animation',
      },
      AnimationTypeBar = {
        type = 'select',
        name = 'Animation Type Bar',
        order = 6,
        style = 'dropdown',
        desc = 'Changes the type of animation played when showing or hiding the bar',
        values = AnimationTypeDropdown,
        disabled = function()
                     return UBF.UnitBar.Attributes.MainAnimationType
                   end
      },
    },
  }

  return AttributeOptions
end

-------------------------------------------------------------------------------
-- CreateCopyPasteOptions
--
-- Creates options for copy and paste bars.
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType   Bar thats using copy and paste.
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateCopyPasteOptions(BarType, Order, Name)
  local UBF = Main.UnitBarsF[BarType]
  local BBar = UBF.BBar
  local IsText = { ['Text']  = 1, ['Text.1']  = 1, ['Text.2']  = 1, ['Text.3']  = 1, ['Text.4']  = 1,
                   ['Text2'] = 1, ['Text2.1'] = 1, ['Text2.2'] = 1, ['Text2.3'] = 1, ['Text2.4'] = 1 } -- Stagger Pause Timer Text

  MenuButtons = MenuButtons or { -- Include means that these menu items will be usable during copy paste.
    ['Main'] = { Order = 1,
      { Name = 'All',                  All = false, TablePath = '',                                   },  -- 1
      { Name = 'Specialization',       All = true,  TablePath = 'ClassSpecs',                         },
      { Name = 'Status',               All = true,  TablePath = 'Status',                             },
      { Name = 'Attributes',           All = true,  TablePath = 'Attributes',                         },
      { Name = 'Layout',               All = true,  TablePath = 'Layout',                             },
      { Name = 'Region',               All = true,  TablePath = 'Region',                             }},

    ['Background'] = { Order = 2,
      { Name = 'Background',           All = true,  TablePath = 'Background',                         },  -- 1
      { Name = 'Shard',                All = false, TablePath = 'BackgroundShard',                    },
      { Name = 'Ember',                All = false, TablePath = 'BackgroundEmber',                    },
      { Name = 'Stagger',              All = false, TablePath = 'BackgroundStagger',                  },
      { Name = 'Pause',                All = false, TablePath = 'BackgroundPause',                    },
      { Name = 'Power',                All = false, TablePath = 'BackgroundPower',                    },
      { Name = 'Counter',              All = false, TablePath = 'BackgroundCounter',                  }},

    ['Bar'] = { Order = 3,
      { Name = 'Bar',                  All = true,  TablePath = 'Bar',                                },  -- 1
      { Name = 'Shard',                All = false, TablePath = 'BarShard',                           },
      { Name = 'Ember',                All = false, TablePath = 'BarEmber',                           },
      { Name = 'Stagger',              All = false, TablePath = 'BarStagger',                         },
      { Name = 'Pause',                All = false, TablePath = 'BarPause',                           },
      { Name = 'Power',                All = false, TablePath = 'BarPower',                           },
      { Name = 'Counter',              All = false, TablePath = 'BarCounter',                         }},

    ['Region Color'] = { Order = 4, Include = { ['Region Color'] = 1, ['Background Color'] = 1, ['Bar Color'] = 1 },
      { Name = 'Background',           All = true,  TablePath = 'Region.Color',                       },  -- 1
      { Name = 'Border',               All = true,  TablePath = 'Region.BorderColor',                 }},

    ['Background Color'] = { Order = 5, Include = { ['Region Color'] = 1, ['Background Color'] = 1, ['Bar Color'] = 1 },
      { Name = 'Background Color',     All = true,  TablePath = 'Background.Color',                   },  -- 1
      { Name = 'Border Color',         All = true,  TablePath = 'Background.BorderColor',             },
      { Name = 'Shard',                All = false, TablePath = 'BackgroundShard.Color',              },
      { Name = 'Ember',                All = false, TablePath = 'BackgroundEmber.Color',              },
      { Name = 'Shard [Green]',        All = false, TablePath = 'BackgroundShard.ColorGreen',         },
      { Name = 'Ember [Green]',        All = false, TablePath = 'BackgroundEmber.ColorGreen',         },
      { Name = 'Shard Border',         All = false, TablePath = 'BackgroundShard.BorderColor',        },
      { Name = 'Ember Border',         All = false, TablePath = 'BackgroundEmber.BorderColor',        },
      { Name = 'Shard Border [Green]', All = false, TablePath = 'BackgroundShard.BorderColorGreen',   },
      { Name = 'Ember Border [Green]', All = false, TablePath = 'BackgroundEmber.BorderColorGreen',   },
      { Name = 'Blood',                All = false, TablePath = 'Background.ColorBlood',              },
      { Name = 'Frost',                All = false, TablePath = 'Background.ColorFrost',              },
      { Name = 'Unholy',               All = false, TablePath = 'Background.ColorUnholy',             },
      { Name = 'Blood Border',         All = false, TablePath = 'Background.BorderColorBlood',        },
      { Name = 'Frost Border',         All = false, TablePath = 'Background.BorderColorFrost',        },
      { Name = 'Unholy Border',        All = false, TablePath = 'Background.BorderColorUnholy',       },
      { Name = 'Stagger',              All = false, TablePath = 'BackgroundStagger.Color',            },
      { Name = 'Pause',                All = false, TablePath = 'BackgroundPause.Color',              },
      { Name = 'Stagger Border',       All = false, TablePath = 'BackgroundStagger.BorderColor',      },
      { Name = 'Pause Border',         All = false, TablePath = 'BackgroundPause.BorderColor',        },
      { Name = 'Power',                All = false, TablePath = 'BackgroundPower.Color',              },
      { Name = 'Counter',              All = false, TablePath = 'BackgroundCounter.Color',            },
      { Name = 'Power Border',         All = false, TablePath = 'BackgroundPower.BorderColor',        },
      { Name = 'Counter Border',       All = false, TablePath = 'BackgroundCounter.BorderColor',      }},

    ['Bar Color'] = { Order = 6, Include = { ['Region Color'] = 1, ['Background Color'] = 1, ['Bar Color'] = 1 },
      { Name = 'Bar Color',            All = true,  TablePath = 'Bar.Color',                          },  -- 1
      { Name = 'Predicted',            All = true,  TablePath = 'Bar.PredictedColor',                 },
      { Name = 'Predicted Cost',       All = true,  TablePath = 'Bar.PredictedCostColor',             },
      { Name = 'Absorb Health',        All = true,  TablePath = 'Bar.AbsorbColor',                    },
      { Name = 'Shard',                All = false, TablePath = 'BarShard.Color',                     },
      { Name = 'Ember',                All = false, TablePath = 'BarEmber.Color',                     },
      { Name = 'Shard (full)',         All = false, TablePath = 'BarShard.ColorFull',                 },
      { Name = 'Ember (full)',         All = false, TablePath = 'BarEmber.ColorFull',                 },
      { Name = 'Shard [Green]',        All = false, TablePath = 'BarShard.ColorGreen',                },
      { Name = 'Ember [Green]',        All = false, TablePath = 'BarEmber.ColorGreen',                },
      { Name = 'Shard (full) [Green]', All = false, TablePath = 'BarShard.ColorFullGreen',            },
      { Name = 'Ember (full) [Green]', All = false, TablePath = 'BarEmber.ColorFullGreen',            },
      { Name = 'Blood',                All = false, TablePath = 'Bar.ColorBlood',                     },
      { Name = 'Frost',                All = false, TablePath = 'Bar.ColorFrost',                     },
      { Name = 'Unholy',               All = false, TablePath = 'Bar.ColorUnholy',                    },
      { Name = 'Stagger',              All = false, TablePath = 'BarStagger.Color',                   },
      { Name = 'Pause',                All = false, TablePath = 'BarPause.Color',                     },
      { Name = 'Power',                All = false, TablePath = 'BarPower.Color',                     },
      { Name = 'Counter',              All = false, TablePath = 'BarCounter.Color',                   }},

    ['Text'] = { Order = 7, Include = { ['Text'] = 1, ['Text (pause)'] = 1 },
      { Name  = 'All Text',            All = true,  TablePath = 'Text',                               },  -- 1
      { Name  = 'Text 1',              All = false, TablePath = 'Text.1',                             },
      { Name  = 'Text 2',              All = false, TablePath = 'Text.2',                             },
      { Name  = 'Text 3',              All = false, TablePath = 'Text.3',                             },
      { Name  = 'Text 4',              All = false, TablePath = 'Text.4',                             }},

    ['Text (pause)'] = { Order = 8, BarType = 'StaggerBar', Include = { ['Text'] = 1, ['Text (pause)'] = 1 },
      { Name  = 'All Text',            All = true,  TablePath = 'Text2',                              },  -- 1
      { Name  = 'Text 1',              All = false, TablePath = 'Text2.1',                            },
      { Name  = 'Text 2',              All = false, TablePath = 'Text2.2',                            },
      { Name  = 'Text 3',              All = false, TablePath = 'Text2.3',                            },
      { Name  = 'Text 4',              All = false, TablePath = 'Text2.4',                            }},

    ['Text (counter)'] = { Order = 8, BarType = 'AltPowerBar', Include = { ['Text'] = 1, ['Text (counter)'] = 1 },
      { Name  = 'All Text',            All = true,  TablePath = 'Text2',                              },  -- 1
      { Name  = 'Text 1',              All = false, TablePath = 'Text2.1',                            },
      { Name  = 'Text 2',              All = false, TablePath = 'Text2.2',                            },
      { Name  = 'Text 3',              All = false, TablePath = 'Text2.3',                            },
      { Name  = 'Text 4',              All = false, TablePath = 'Text2.4',                            }},

    ['Triggers'] = { Order = 9,
      { Name = 'Triggers',             All = true,  TablePath = 'Triggers',                           }}, -- 1
  }

  local CopyPasteOptions = {
    type = 'group',
    name = Name,
    order = Order,
    confirm = function(Info)
                local Name = Info[#Info]
                local Arg = Info.arg

                -- Make sure a select button was clicked
                if Arg and ClipBoard then
                  if Name == 'AppendTriggers' then
                    return format('Append Triggers from %s to\n%s', DUB[BarType]._Name, DUB[ClipBoard.BarType]._Name)
                  elseif Name ~= 'Clear' then
                    return format('Copy %s [ %s ] to \n%s [ %s ]', ClipBoard.BarName or '', ClipBoard.SelectButtonName, DUB[BarType]._Name, Arg.PasteName)
                  end
                end
              end,
    func = function(Info)
             local Name = Info[#Info]
             local Arg = Info.arg

             -- First click initialize.
             if ClipBoard == nil then
               ClipBoard = {}
               ClipBoard.BarType = BarType
               ClipBoard.BarName = UBF.UnitBar._Name
               ClipBoard.Hide = Arg.Hide
               ClipBoard.TablePath = Arg.TablePath
               ClipBoard.MenuButtonName = Arg.MenuButtonName
               ClipBoard.SelectButtonName = Arg.SelectButtonName
               ClipBoard.AllButton = Arg.AllButton
               ClipBoard.AllButtonText = Arg.AllButtonText
               ClipBoard.Include = Arg.Include
             else
               if Name == 'AppendTriggers' then
                 BBar:AppendTriggers(ClipBoard.BarType)
               else
                 -- Paste
                 if ClipBoard.AllButton then
                   for SelectIndex, SelectButton in pairs(MenuButtons) do
                     for _, SB in ipairs(SelectButton) do
                       if SB.All then
                         local TablePath = SB.TablePath

                         Main:CopyUnitBar(ClipBoard.BarType, BarType, TablePath, TablePath)
                       end
                     end
                   end
                 else
                   Main:CopyUnitBar(ClipBoard.BarType, BarType, ClipBoard.TablePath, Arg.TablePath)
                 end
               end

               -- Update the layout.
               Main.CopyPasted = true

               -- Need to do this to be sure the data is safe
               Main:FixUnitBars()

               UBF:SetAttr()
               UBF:Update()

               Main.CopyPasted = false
               -- Update any text highlights.  Use 'on' since its always on when options are opened.
               Bar:SetHighlightFont('on', Main.UnitBars.HideTextHighlight)

               -- Update any dynamic options.
               Options:DoFunction()
             end
             HideTooltip(true)
           end,
    args = {},
  }

  local Args = CopyPasteOptions.args

  Args.CopyName = {
    type = 'description',
    fontSize = 'medium',
    name = function()
             if ClipBoard then
               return format('|cffffff00%s - %s [ %s ]|r', ClipBoard.BarName or '', ClipBoard.MenuButtonName, ClipBoard.SelectButtonName)
             else
               return ' '
             end
           end,
    order = 1,
  }

  -- Create clear button
  Args.Clear = {
    type = 'execute',
    name = 'Clear',
    order = 10,
    width = 'half',
    func = function()
             ClipBoard = nil

             HideTooltip(true)
           end,
    hidden = function()
               return ClipBoard == nil
             end,
    disabled = function()
                 HideTooltip(true)

                 return ClipBoard == nil
               end,
  }

  -- Create menu buttons
  for MenuButtonName, MenuButton in pairs(MenuButtons) do
    local Found = false

    -- Check to see if any tables exist.
    for _, SelectButton in ipairs(MenuButton) do
      if SelectButton.Name == 'All' or Main:GetUB(BarType, SelectButton.TablePath) ~= nil then
        Found = true
        break
      end
    end

    if Found and (MenuButton.BarType == nil or MenuButton.BarType == BarType) then
      local GA = {}
      Args[MenuButtonName] = {
        type = 'group',
        order = MenuButton.Order,
        name = MenuButtonName,
        disabled = function()
                     if ClipBoard ~= nil then
                       if ClipBoard.MenuButtonName ~= MenuButtonName then
                         local Include = ClipBoard.Include

                         -- Check for inclusion
                         if Include == nil or Include[MenuButtonName] == nil then
                           return true
                         end
                       end
                     end
                     return false
                   end,
        args = GA
      }

      -- Create the select buttons
      for SelectIndex, SelectButton in ipairs(MenuButton) do
        local TablePath = SelectButton.TablePath
        local SelectButtonName = SelectButton.Name
        local AllButton = SelectButtonName == 'All'
        local AllButtonText = SelectButtonName == 'All Text'
        local MainMenu = MenuButtonName == 'Main'
        local Text = IsText[TablePath] ~= nil

        if AllButton or Text or Main:GetUB(BarType, TablePath) ~= nil then
          GA[MenuButtonName .. SelectButtonName] = {
            type = 'execute',
            name =  SelectButtonName,
            width = 'full',
            order = SelectIndex,
            hidden = function()
                       return Text and Main:GetUB(BarType, TablePath) == nil or ClipBoard ~= nil
                     end,
            arg = {Hide             = SelectButton.Hide,
                   TablePath        = TablePath,
                   MenuButtonName   = MenuButtonName,
                   SelectButtonName = SelectButtonName,
                   AllButton        = AllButton,
                   AllButtonText    = AllButtonText,
                   Include          = MenuButton.Include },
          }

          -- Create paste button
          GA['Paste' .. MenuButtonName .. SelectButtonName] = {
            type = 'execute',
            name = format('Paste %s', SelectButtonName),
            width = 'full',
            order = SelectIndex,
            hidden = function()
                       if ClipBoard then
                         -- Hide all buttons if All was picked except for paste all on other bars
                         if ClipBoard.AllButton then
                           return ClipBoard.BarType == BarType or not AllButton
                         elseif AllButton then
                           return true

                         -- Hide text buttons that are not needed (this is dynamic)
                         elseif Text and Main:GetUB(BarType, TablePath) == nil then
                           return true

                         -- Check if this is the source menu
                         elseif ClipBoard.MenuButtonName == MenuButtonName and ClipBoard.BarType == BarType then
                           -- Check for all text
                           if ClipBoard.AllButtonText or AllButtonText then
                             return true
                           else
                             -- Hide all if Main
                             if MainMenu then
                               return true
                             else
                               -- Check for same button pressed
                               return ClipBoard.SelectButtonName == SelectButtonName
                             end
                           end
                           -- Destination menu or same menu on a different bar
                         elseif MainMenu and ClipBoard.SelectButtonName ~= SelectButtonName then
                           return true
                         else
                           -- Hide all text buttons if all text was clicked
                           if ClipBoard.AllButtonText then
                             return not AllButtonText
                           else
                             return AllButtonText
                           end
                         end
                       else
                         return true
                       end
                     end,
            arg = {TablePath = TablePath, PasteName = SelectButtonName},
          }

          if SelectButtonName == 'Triggers' then
            GA.AppendTriggers = {
              type = 'execute',
              name = 'Append Triggers',
              width = 'full',
              order = 30,
              hidden = function()
                         return ClipBoard == nil or ClipBoard.BarType == BarType
                       end,
              arg = {TablePath = TablePath, PasteName = SelectButtonName},
            }
          end
        end
      end
    end
  end

  return CopyPasteOptions
end

-------------------------------------------------------------------------------
-- CreateImportExportOptions
--
-- Creates two buttons to export and import bar settings
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType   Bar thats using copy and paste.
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateImportExportOptions(BarType, Order, Name)
  local ImportExportOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {
      Import = {
        type = 'execute',
        name = 'Import',
        desc = 'Import the current unitbar settings',
        width = 'half',
        order = 1,
        func = function()
                 Options.Importing = true
                 Options.ImportSourceBarType = BarType
               end,
      },
      Export = {
        type = 'execute',
        name = 'Export',
        desc = 'Export the current unitbar setttings',
        width = 'half',
        order = 2,
        func = function()
                 Options.Exporting = true
                 Options.ExportData = Main:ExportTableString(BarType, 'unitbar', 'UnitBar', DUB[BarType]._Name, Main.UnitBars[BarType])
               end,
      },
    },
  }

  return ImportExportOptions
end


-------------------------------------------------------------------------------
-- CreateUnitBarOptions
--
-- Subfunction of CreateMainOptions
--
-- BarGroups        Menu tree on the left
-- BarType          Type of options table to create.
-- Order            Order number for the options.
-- Name             Name for the option to appear in the tree.
-- Desc             Description for option.  Set to nil for no description.
-------------------------------------------------------------------------------
local function CreateUnitBarOptions(BarGroups, BarType, Order, Name, Desc)
  local UBF = Main.UnitBarsF[BarType]
  local UBD = DUB[BarType]

  local Name = function()
    local Tag = ''
    if BarType == 'FragmentBar' then
      if UBF.UnitBar.Layout.BurningEmbers then
        Tag = ' (Ember)'
      else
        Tag = ' (Shard)'
      end
    end
    return Name .. Tag
  end

  -- Create the options root tree and tab groups
  AddOptionsTree(BarGroups, BarType, Order, Name, Desc)
  AddTabGroup(BarType, 1, 'Show',           false, CreateShowOptions(BarType, 1, 'Show') )
  AddTabGroup(BarType, 3, 'Attr',           false, UBD.Attributes and CreateAttributeOptions(BarType, 3, 'Attributes') or nil )
  AddTabGroup(BarType, 4, 'Reset',          false, CreateResetOptions(BarType, 4, 'Reset') )
  AddTabGroup(BarType, 5, 'Copy and Paste', false, CreateCopyPasteOptions(BarType, 5, 'Copy and Paste') )
  AddTabGroup(BarType, 6, 'Import Export',  false, CreateImportExportOptions(BarType, 6, 'Import Export') )

  -- Add layout options if they exist.
  if UBD.Layout then
    AddOptionsBranch(BarGroups, BarType, 'Layout', CreateLayoutOptions(BarType, 1000, 'Layout') )
  end

  -- Add region options if they exist.
  if UBD.Region then
    local Border = CreateBackdropOptions(BarType, 'Region', 1001, 'Region')
    Border.hidden = function()
                      return Flag(true, UBF.UnitBar.Layout.HideRegion)
                    end
    AddOptionsBranch(BarGroups, BarType, 'Region', Border)
  end

  -- Add tab background options
  local BackgroundOptions

  if BarType == 'FragmentBar' or BarType == 'StaggerBar' or BarType == 'AltPowerBar' then
    if BarType == 'FragmentBar' then
      BackgroundOptions = {
        type = 'group',
        name = 'Background',
        order = 1002,
        childGroups = 'tab',
      }
      BackgroundOptions.args = {
        Shard = CreateBackdropOptions(BarType, 'BackgroundShard', 1, 'Shard'),
        Ember = CreateBackdropOptions(BarType, 'BackgroundEmber', 2, 'Ember'),
      }
    -- Stagger bar
    elseif BarType == 'StaggerBar' then
      BackgroundOptions = {
        type = 'group',
        name = 'Background',
        order = 1002,
        childGroups = 'tab',
      }
      BackgroundOptions.args = {
        Stagger = CreateBackdropOptions(BarType, 'BackgroundStagger', 1, 'Stagger'),
        Pause = CreateBackdropOptions(BarType, 'BackgroundPause', 2, 'Pause'),
      }
    -- Alternate Power Bar
    else
      BackgroundOptions = {
        type = 'group',
        name = 'Background',
        order = 1002,
        childGroups = 'tab',
      }
      BackgroundOptions.args = {
        AltPower = CreateBackdropOptions(BarType, 'BackgroundPower', 1, 'Power'),
        AltCounter = CreateBackdropOptions(BarType, 'BackgroundCounter', 2, 'Counter'),
      }
    end
    BackgroundOptions.hidden = function()
                                 return not Flag(true, UBF.UnitBar.Layout.BoxMode)
                               end
  else
    -- Add background options
    BackgroundOptions = CreateBackdropOptions(BarType, 'Background', 1002, 'Background')
    if BarType == 'RuneBar' then
      BackgroundOptions.hidden = function()
                                   return UBF.UnitBar.Layout.RuneMode == 'rune'
                                 end
    else
      BackgroundOptions.hidden = function()
                                   return not Flag(true, UBF.UnitBar.Layout.BoxMode)
                                 end
    end
  end
  AddOptionsBranch(BarGroups, BarType, 'Background', BackgroundOptions)

  -- add tab bar options
  local BarOptions

  if BarType == 'FragmentBar' or BarType == 'StaggerBar' or BarType == 'AltPowerBar' then
    if BarType == 'FragmentBar' then
      BarOptions = {
        type = 'group',
        name = 'Bar',
        order = 1003,
        childGroups = 'tab',
      }
      BarOptions.args = {
        Shard = CreateBarOptions(BarType, 'BarShard', 1, 'Shard'),
        Ember = CreateBarOptions(BarType, 'BarEmber', 2, 'Ember'),
      }
    -- Stagger bar
    elseif BarType == 'StaggerBar' then
      BarOptions = {
        type = 'group',
        name = 'Bar',
        order = 1003,
        childGroups = 'tab',
      }
      BarOptions.args = {
        Stagger = CreateBarOptions(BarType, 'BarStagger', 1, 'Stagger'),
        Pause = CreateBarOptions(BarType, 'BarPause', 2, 'Pause'),
      }
    -- Alternate Power bar
    else
      BarOptions = {
        type = 'group',
        name = 'Bar',
        order = 1003,
        childGroups = 'tab',
      }
      BarOptions.args = {
        Power = CreateBarOptions(BarType, 'BarPower', 1, 'Power'),
        Counter = CreateBarOptions(BarType, 'BarCounter', 2, 'Counter'),
      }
    end
    BarOptions.hidden = function()
                          return not Flag(true, UBF.UnitBar.Layout.BoxMode)
                        end
  else
    -- add bar options
    BarOptions = CreateBarOptions(BarType, 'Bar', 1003, 'Bar')
    if BarType == 'RuneBar' then
      BarOptions.hidden = function()
                            return UBF.UnitBar.Layout.RuneMode == 'rune'
                          end
    else
      BarOptions.hidden = function()
                            return not Flag(true, UBF.UnitBar.Layout.BoxMode)
                          end
    end
  end
  AddOptionsBranch(BarGroups, BarType, 'Bar', BarOptions)

  -- Add text options
  if UBD.Text ~= nil then
    local TxtOptions

    if BarType == 'StaggerBar' or BarType == 'AltPowerBar' then
      if BarType == 'StaggerBar' then
        TxtOptions = {
          type = 'group',
          name = 'Text',
          order = 1004,
          childGroups = 'tab',
        }
        TxtOptions.args = {
          Stagger = TextOptions:CreateTextOptions(BarType, 'Text', 1, 'Stagger'),
          Pause = TextOptions:CreateTextOptions(BarType, 'Text2', 2, 'Pause'),
        }
      else
        TxtOptions = {
          type = 'group',
          name = 'Text',
          order = 1004,
          childGroups = 'tab',
        }
        TxtOptions.args = {
          Power = TextOptions:CreateTextOptions(BarType, 'Text', 1, 'Power'),
          Counter = TextOptions:CreateTextOptions(BarType, 'Text2', 2, 'Counter'),
        }
      end
    else
      TxtOptions = TextOptions:CreateTextOptions(BarType, 'Text', 1004, 'Text')
      TxtOptions.hidden = function()
                             return UBF.UnitBar.Layout.HideText
                           end
    end
    AddOptionsBranch(BarGroups, BarType, 'Text', TxtOptions)
  end

  -- Add trigger options
  if UBD.Triggers ~= nil then
    local TriggerOptions = TriggerOptions:CreateTriggerOptions(BarType, 1005, 'Triggers')

    TriggerOptions.hidden = function()
                               return not Flag(false, UBF.UnitBar.Layout.EnableTriggers)
                             end
    AddOptionsBranch(BarGroups, BarType, 'Triggers', TriggerOptions)
  end
end

-------------------------------------------------------------------------------
-- AddRemoveBarGroups
--
-- Adds or remove unitbar groups from the options panel based on whats
-- enables or disabled.
--
-- BarGroups   Table pointing to where the option bargroups are stored.
--             If nil then retreives it from the source.
-------------------------------------------------------------------------------
function GUB.Options:AddRemoveBarGroups()
  local BarGroups = MainOptions.args.UnitBars.args
  local Order = 0

  -- Add or remove multiple bargroups.
  for BarType, UBF in pairs(Main.UnitBarsF) do
    local UB = UBF.UnitBar

    Order = Order + 1

    if UB._Enabled then
      if BarGroups[BarType] == nil then
        local DB = DUB[BarType]

        CreateUnitBarOptions(BarGroups, BarType, DB._OptionOrder, DB._Name, DB._OptionText or '')
      end
    else
      Options:DoFunction(BarType, 'clear')
      RemoveOptionsTree(BarGroups, BarType)
    end
  end
end

-------------------------------------------------------------------------------
-- CreateEnableUnitBarOptions
--
-- Creates options that let you disable/enable unit bars.
--
-- Args      Table containing the unitbars.
-- Order     Position in the options list.
-- Name      Name of the options.
-- Desc      Description when mousing over the options name.
-------------------------------------------------------------------------------
local function CreateEnableUnitBarOptions(BarGroups, Order, Name, Desc)
  local EnableUnitBarOptions = {
    type = 'group',
    name = Name,
    order = Order,
    desc = Desc,
    args = {
      EnableRefresh = { -- See RefreshEnable()
        type = 'description',
        name = function()
                 RefreshEnable()
                 return 'EnableRefresh'
               end,
        order = 0.1,
        hidden = true,
      },
      EnableClass = {
        type = 'toggle',
        name = 'Enable Class Bars',
        desc = 'Enable bars for your class only',
        order = 1,
        get = function()
                return Main.UnitBars.EnableClass
              end,
        set = function(Info, Value)
                Main.UnitBars.EnableClass = Value
                Main:SetUnitBars()
              end
      },
      UnitBarList = {
        type = 'group',
        name = 'Check off the bars you want to enable',
        dialogInline = true,
        disabled = function()
                     return Main.UnitBars.EnableClass
                   end,
        order = 2,
        get = function(Info)
                return Main.UnitBars[Info[#Info]]._Enabled
              end,
        set = function(Info, Value)
                Main.UnitBars[Info[#Info]]._Enabled = Value
                Main:SetUnitBars()
              end,
        args = {
          Spacer10 = CreateSpacer(10),
        },
      },
    },
  }

  -- Create enable list
  local EUBOptions = EnableUnitBarOptions.args.UnitBarList.args

  for BarType, UBF in pairs(Main.UnitBarsF) do
    local UBToggle = {}
    local DB = DUB[BarType]

    UBToggle.type = 'toggle'
    UBToggle.name = DB._Name
    UBToggle.order = DB._OptionOrder * 10

    EUBOptions[BarType] = UBToggle
  end

  return EnableUnitBarOptions
end

-------------------------------------------------------------------------------
-- CreateAuraOptions
--
-- Creates options that let you view the aura list.
--
-- Order     Position in the options list.
-- Name      Name of the options.
-- Desc      Description when mousing over the options name.
-------------------------------------------------------------------------------
local function AuraSort(a, b)
  return a.Name < b.Name
end

local function RefreshAuraList(AG, Unit, AuraTrackersData)
  if Main.UnitBars.AuraListOn then
    AG.args = {}

    local AGA = AG.args
    local Order = 0
    local SortList = {}
    local AuraList = {}

    -- Build aura list
    local Auras = AuraTrackersData[Unit]

    if Auras then
      for SpellID, Aura in pairs(Auras) do
        if type(SpellID) == 'number' then
          AuraList[SpellID] = Aura
        end
      end
    end

    for SpellID, Aura in pairs(AuraList) do
      local AuraKey = format('Auras%s', SpellID)

      if AGA[AuraKey] == nil then
        Order = Order + 1

        local AuraInfo = {
          type = 'description',
          width = 'full',
          name = format('%s:24:14:(|cFF00FF00%s|r)', SpellID, SpellID),
          dialogControl = 'GUB_Spell_Info',
        }

        SortList[Order] = {Name = GetSpellInfo(SpellID), AuraInfo = AuraInfo}
        AGA[AuraKey] = AuraInfo
      end
    end
    sort(SortList, AuraSort)
    for Index = 1, #SortList do
      SortList[Index].AuraInfo.order = Index
    end
  end
end

local function DeleteAuraTabs(ALA)
  for Key in pairs(ALA) do
    if strfind(Key, 'AuraGroup') then
      ALA[Key] = nil
    end
  end
end

local function UpdateAuraTabs(ALA, Order)
  local AuraTrackersData = Main.AuraTrackersData
  local OrderNumber = Order

  for Unit in pairs(AuraTrackersData) do
    local Key = 'AuraGroup_' .. Unit

    if ALA[Key] == nil then
      ALA[Key] = {
        type = 'group',
        order = function()
                  if Unit == 'All' then
                    return OrderNumber - 0.5
                  else
                    return Order
                  end
                end,
        name = Unit,
        args = {},
      }
    end
    Order = Order + 1
  end

  -- Remove units no longer in use.
  for Key in pairs(ALA) do
    local _, Unit = strsplit('_', Key)

    if Unit then
      if AuraTrackersData[Unit] == nil then
        ALA[Key] = nil
      else
        RefreshAuraList(ALA[Key], Unit, AuraTrackersData)
      end
    end
  end
end

local function CreateAuraOptions(Order, Name, Desc)
  local ALA

  -- This is needed so the aura list is always updated.
  function GUB.Options:UpdateAuras()
    if Main.UnitBars.AuraListOn then
      UpdateAuraTabs(ALA, 100)
    else
      DeleteAuraTabs(ALA)
    end
  end

  local AuraListOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    desc = Desc,
    get = function(Info)
            return Main.UnitBars[Info[#Info]]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            -- remove extra spaces
            if KeyName == 'AuraListUnits' then
              Value = strjoin(' ', Main:SplitString(' ', Value))
           end

            Main.UnitBars[KeyName] = Value
            Main:UnitBarsSetAllOptions()
            GUB:UnitBarsUpdateStatus()

            -- Need this here after updaing auras in UnitBarsSetAllOptions
            if KeyName == 'AuraListUnits' then
              Options:UpdateAuras()
              Options:RefreshMainOptions()
            end
          end,
    args = {
      Description = {
        type = 'description',
        name = 'Lists all units and auras that the mod is using.  Can add additional units in the box below.  The All tab shows all units',
        order = 1,
      },
      AuraListUnits = {
        type = 'input',
        name = 'Units  ( separated by space )',
        order = 2,
        desc = 'Enter the units to track auras. Each unit can be seperated by a space',
        disabled = function()
                     return not Main.UnitBars.AuraListOn
                   end,
      },
      RefreshAuras = {
        type = 'execute',
        name = 'Refresh',
        desc = 'Refresh aura list',
        width = 'half',
        order = 5,
        func = function()
                 Options:UpdateAuras()
               end,
        disabled = function()
                     return not Main.UnitBars.AuraListOn
                   end
      },
      AuraListOn = {
        type = 'toggle',
        name = 'Enable',
        order = 6,
      },
      Spacer20 = CreateSpacer(20),
    }
  }

  ALA = AuraListOptions.args
  return AuraListOptions
end

-------------------------------------------------------------------------------
-- CreateAltPowerBarOptions
--
-- Creates options that let you view all the alternate power bars
--
-- TableName   Key name to store the options under
-- Order       Position in the options list.
-- Name        Name of the options.
-------------------------------------------------------------------------------
local function BuildAltPowerBarList(APA, TableName, Order, Name)
  local Gdata = Main.Gdata
  local APBUsed = Gdata.APBUsed

  local PowerBarList = {
    type = 'group',
    name = Name,
    order = Order,
    args = {},
    disabled = function()
                 return not Main.UnitBars.AltPowerBar._Enabled or Main.HasAltPower
               end,
  }
  APA[TableName] = PowerBarList
  local PBA = PowerBarList.args

  for BarID = 1, 1000 do
    local AltPowerType, MinPower, _, _, _, _, _, _, _, _, PowerName, PowerTooltip = GetAlternatePowerInfoByID(BarID)

    if AltPowerType then
      PBA[TableName .. ':' .. BarID .. 'APBL'] = {
        type = 'toggle',
        width = 'full',
        arg = BarID,
        name = function()
                 local ZoneName = APBUsed[BarID]
                 if ZoneName then
                   return format('|cff00ff00%s|r : |cffffff00%s|r (|cff00ffff%s|r)', BarID, PowerName, ZoneName)
                 else
                   return format('|cff00ff00%s|r : |cffffff00%s|r', BarID, PowerName)
                 end
               end,
        desc = PowerTooltip,
        order = BarID,
        hidden = function()
                   local ZoneName = APBUsed[BarID]
                   local APBShowUsed = Gdata.APBShowUsed

                   if AltPowerBarSearch == '' or BarID == tonumber(AltPowerBarSearch) or
                                                 strfind(strlower(PowerName),    strlower(AltPowerBarSearch)) or
                                                 strfind(strlower(PowerTooltip), strlower(AltPowerBarSearch)) or
                                                 ZoneName and strfind(strlower(ZoneName), strlower(AltPowerBarSearch)) then
                     if APBShowUsed and ZoneName ~= nil then
                       return false
                     elseif not APBShowUsed then
                       return false
                     end
                   end
                   return true
                 end,
      }
    end
  end
end

local function AddRemoveUseBlizz(APA, BarID, KeyName, APBUseBlizz)
  local UseBlizz = APA.UseBlizz

  if UseBlizz == nil then
    UseBlizz = {
      type = 'group',
      name = 'Use Blizzard',
      order = 200,
      arg = BarID,
      disabled = function()
                   return not Main.UnitBars.AltPowerBar._Enabled or Main.HasAltPower
                 end,
      args = {},
    }
    APA.UseBlizz = UseBlizz
  end
  if KeyName then
    local UseBlizzArgs = UseBlizz.args

    if APBUseBlizz then
      local TableName = strsplit(':', KeyName)
      UseBlizzArgs[KeyName] = APA[TableName].args[KeyName]
    else
      UseBlizzArgs[KeyName] = nil
    end
  end
end

---------------------------
-- CreateAltPowerBarOptions
---------------------------
local function CreateAltPowerBarOptions(Order, Name)
  local APA
  local Gdata = Main.Gdata

  local AltPowerBarOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    get = function(Info)
            local KeyName = Info[#Info]

            if strfind(KeyName, 'APBL') then
              local BarID = Info.arg
              local Value = Gdata.APBUseBlizz[Info.arg]

              AddRemoveUseBlizz(APA, BarID, KeyName, Value)
              return Value
            elseif KeyName == 'Search' then
              return AltPowerBarSearch
            else
              return Gdata.APBShowUsed
              --return Main.UnitBars[KeyName]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            if strfind(KeyName, 'APBL') then
              local BarID = Info.arg

              Gdata.APBUseBlizz[BarID] = Value
              AddRemoveUseBlizz(APA, BarID, KeyName, Value)
            elseif KeyName == 'Search' then
              AltPowerBarSearch = Value
            else
              Gdata.APBShowUsed = Value
              --Main.UnitBars[KeyName] = Value
            end
          end,
    disabled = function()
                 return not Main.UnitBars.AltPowerBar._Enabled or Main.HasAltPower
               end,
    args = {
      Description = {
        type = 'description',
        name = 'May take a few seconds to build the list. Bars already used have an area name.\nChecking off a bar will use the blizzard bar instead',
        order = 1,
      },
      Search = {
        type = 'input',
        name = 'Search',
        order = 3,
      },
      clearSearch = {
        type = 'execute',
        name = 'Clear',
        desc = 'Clear search',
        width = 'half',
        order = 4,
        func = function()
                 AltPowerBarSearch = ''
                 HideTooltip(true)
               end,
      },
      APBShowUsed = {
        type = 'toggle',
        name = 'Show used bars only',
        width = 'normal',
        order = 5,
      },
    },
  }

  APA = AltPowerBarOptions.args
  BuildAltPowerBarList(APA, 'PowerBarList', 100, 'Alternate Power Bar')

  -- Add second tab
  AddRemoveUseBlizz(APA, 1, nil)

  return AltPowerBarOptions
end

-------------------------------------------------------------------------------
-- CreateDebugOptions
--
-- Lists error messages in an edit box
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateDebugOptions(Order, Name)
  local DebugOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {
      Description = {
        type = 'description',
        name = 'Track error messages, works only for text',
        order = 1,
      },
      Clear = {
        type = 'execute',
        name = 'Clear',
        order = 2,
        width = 'half',
        func = function()
                 DebugText = ''
               end,
        disabled = function()
                     return not Main.UnitBars.DebugOn
                   end,
      },
      DebugOn = {
        type = 'toggle',
        name = 'Enable',
        order = 3,
      },
      DebugWindow = {
        type = 'input',
        name = '',
        order = 4,
        multiline = true,
        dialogControl = 'GUB_MultiLine_EditBox_Debug',
        width = 'full',
        get = function(text)
                return DebugText
              end,
        set = function()
              end,
      },
    },
  }

  return DebugOptions
end

function GUB.Options:AddDebugLine(Text)
  if Main.UnitBars.DebugOn then
    local Text, _, ErrorText = strsplit(':', Text, 3)

    ErrorText = Text .. ErrorText
    if strfind(DebugText, ErrorText, 1, true) == nil then
      DebugText = DebugText .. ErrorText .. '\n'
    end
  end
end

-------------------------------------------------------------------------------
-- CreatePowerColorOptions
--
-- Creates power color options for a UnitBar.
--
-- Subfunction of CreateMainOptions()
--
-- BarType   Type of options being created.
-- Order     Position in the options list.
-- Name      Name of the options.
--
-- PowerColorOptions    Options table for power colors.
-------------------------------------------------------------------------------
local function CreatePowerColorOptions(Order, Name)
  local PowerColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local KeyName = Info[#Info]
            local c = Main.UnitBars.PowerColor

            c = c[ConvertPowerType[KeyName]]

            return c.r, c.g, c.b, c.a
          end,
    set = function(Info, r, g, b, a)
            local KeyName = Info[#Info]
            local c = Main.UnitBars.PowerColor

            c = c[ConvertPowerType[KeyName]]
            c.r, c.g, c.b, c.a = r, g, b, a

            -- Set the color to all the bars
            for _, UBF in ipairs(Main.UnitBarsFE) do
              UBF:Update()
            end
          end,
    args = {
    --  Spacer10 = CreateSpacer(10),
      Spacer50 = CreateSpacer(50),
      Spacer100 = CreateSpacer(100),
      Reset = {
        type = 'execute',
        name = 'Reset',
        desc = 'Reset colors back to defaults',
        width = 'half',
        confirm = true,
        order = 101,
        func = function()
                 Main:CopyTableValues(DUB.PowerColor, Main.UnitBars.PowerColor)

                 -- Set the color to all the bars
                 for _, UBF in ipairs(Main.UnitBarsFE) do
                   UBF:Update()
                 end
               end,
      },
    },
  }

  -- Power types for the player power bar.
  -- These cover classes with more than one power type.
  local PlayerPower = {
    DRUID = {MANA = 0, ENERGY = 0, RAGE = 0, LUNAR_POWER = 8},
    MONK  = {MANA = 0, ENERGY = 0},
    SHAMAN = {MANA = 0, MAELSTROM = 11},
    PRIEST = {MANA = 0, INSANITY = 12},
    DEMONHUNTER = {FURY = 17, PAIN = 18},
  }
  local PowerWidth = {
    RUNIC_POWER = 'normal',
    LUNAR_POWER = 'normal',
    MAELSTROM = 'normal',
  }
  local PowerName = {
    RUNIC_POWER = 'Runic Power',
    LUNAR_POWER = 'Astral Power',
    MAELSTROM = 'Maelstrom',
  }

  -- Set up a power order.  half goes first, then normal
  local PowerOrder = {}
  local Index = 1

  for PowerType in pairs(ConvertPowerTypeHAP) do
    if PowerWidth[PowerType] == nil then
      PowerOrder[Index] = PowerType
      Index = Index + 1
    end
  end

  for PowerType in pairs(ConvertPowerTypeHAP) do
    if PowerWidth[PowerType] then
      PowerOrder[Index] = PowerType
      Index = Index + 1
    end
  end

  local PCOA = PowerColorOptions.args
  local ClassPowerType = PlayerPower[Main.PlayerClass]
  local PlayerPowerType = ConvertPowerType[Main.PlayerPowerType]
  Index = 0

  for _, PowerType in pairs(PowerOrder) do
    local n = gsub(strlower(PowerType), '%a', strupper, 1)
    Index = Index + 1

    if ClassPowerType and ClassPowerType[PowerType] or PowerType == PlayerPowerType then
      Order = Index
    else
      Order = Index + 50
    end

    PCOA[PowerType] = {
      type = 'color',
      name = PowerName[PowerType] or n,
      order = Order,
      width = PowerWidth[PowerType] or 'half',
      hasAlpha = true,
    }
  end

  return PowerColorOptions
end

-------------------------------------------------------------------------------
-- CreateClassColorOptions
--
-- Creates class color options for a UnitBar.
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateClassColorOptions(Order, Name)
  local ClassColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local KeyName = Info[#Info]

            if KeyName == 'ClassTaggedColor' then
              return Main.UnitBars.ClassTaggedColor
            else
              local c = Main.UnitBars.ClassColor[KeyName]
              return c.r, c.g, c.b, c.a
            end
          end,
    set = function(Info, r, g, b, a)
            local KeyName = Info[#Info]

            if KeyName == 'ClassTaggedColor' then
              Main.UnitBars.ClassTaggedColor = r
            else
              local c = Main.UnitBars.ClassColor[KeyName]
              c.r, c.g, c.b, c.a = r, g, b, a
            end

            -- Set the color to all the bars
            for _, UBF in ipairs(Main.UnitBarsFE) do
              UBF:Update()
            end
          end,
    args = {
      ClassTaggedColor = {
        type = 'toggle',
        name = 'Tagged Color',
        desc = 'Use tagged color if the unit is tagged and not a player',
        order = 9,
      },
      Spacer10 = CreateSpacer(10),
      Spacer50 = CreateSpacer(50),
      Spacer100 = CreateSpacer(100),
      Reset = {
        type = 'execute',
        name = 'Reset',
        desc = 'Reset colors back to defaults',
        width = 'half',
        confirm = true,
        order = 101,
        func = function()
                 Main:CopyTableValues(DUB.ClassColor, Main.UnitBars.ClassColor)

                 -- Set the color to all the bars
                 for _, UBF in ipairs(Main.UnitBarsFE) do
                   UBF:Update()
                 end
               end,
      },
    },
  }

  local CCOA = ClassColorOptions.args

  for Index, ClassName in ipairs(ConvertPlayerClass) do
    local Order = Index + 50
    local n = ConvertPlayerClass[ClassName]

    if ClassName == Main.PlayerClass then
      Order = 1
    end

    local Width = 'half'
    if Index == 1 or Index == 2 then
      Width = 'normal'
    end

    CCOA[ClassName] = {
      type = 'color',
      name = n,
      order = Order,
      desc = n == 'None' and 'Used if the unit has no class' or nil,
      width = Width,
      hasAlpha = true,
    }
  end
  CCOA.Spacer50 = CreateSpacer(50)

  return ClassColorOptions
end

-------------------------------------------------------------------------------
-- CreateCombatColorOptions
--
-- Creates option to change combat colors.
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateCombatColorOptions(Order, Name)
  local CombatColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local KeyName = Info[#Info]
            local UB = Main.UnitBars
            local c

            if strfind(KeyName, 'Player') then
              c = UB.PlayerCombatColor[strsub(KeyName, 7)]
            else
              c = UB.CombatColor[KeyName]
            end
            if type(c) ~= 'table' then
              return UB[KeyName]
            else
              return c.r, c.g, c.b, c.a
            end
          end,
    set = function(Info, r, g, b, a)
            local KeyName = Info[#Info]
            local UB = Main.UnitBars
            local c

            if strfind(KeyName, 'Player') then
              c = UB.PlayerCombatColor[strsub(KeyName, 7)]
            else
              c = UB.CombatColor[KeyName]
            end
            if type(c) ~= 'table' then
              UB[KeyName] = r
            else
              c.r, c.g, c.b, c.a = r, g, b, a
            end

            -- Set the color to all the bars
            for _, UBF in ipairs(Main.UnitBarsFE) do
              UBF:Update()
            end
          end,
    args = {
      CombatClassColor = {
        type = 'toggle',
        name = 'Class Color',
        desc = 'Replace Player Hostile and Attack with Class Color',
        order = 1,
      },
      CombatTaggedColor = {
        type = 'toggle',
        name = 'Tagged Color',
        desc = 'Use tagged color if the unit is tagged and not a player',
        order = 2,
      },
      -- NPC
      Player = {
        type = 'header',
        name = 'NPC',
        order = 10,
      },
      -- Players
      NPC = {
        type = 'header',
        name = 'Player',
        order = 50,
      },
      Spacer100 = CreateSpacer(100),
      Reset = {
        type = 'execute',
        name = 'Reset',
        desc = 'Reset colors back to defaults',
        width = 'half',
        confirm = true,
        order = 101,
        func = function()
                 Main:CopyTableValues(DUB.CombatColor, Main.UnitBars.CombatColor)
                 Main:CopyTableValues(DUB.PlayerCombatColor, Main.UnitBars.PlayerCombatColor)

                 -- Set the color to all the bars
                 for _, UBF in ipairs(Main.UnitBarsFE) do
                   UBF:Update()
                 end
               end,
      },
    },
  }

  local FCOA = CombatColorOptions.args

  -- Create NPC combat color options
  for CombatColor, Color in pairs(DUB.CombatColor) do
    local Order = ConvertCombatColor[CombatColor] + 10

    FCOA[CombatColor] = {
      type = 'color',
      name = CombatColor,
      order = Order,
      width = 'half',
      hasAlpha = true,
    }
  end

  -- Create combat color options
  for CombatColor, Color in pairs(DUB.PlayerCombatColor) do
    local Order = ConvertCombatColor[CombatColor] + 50
    local Desc
    local Disabled

    if CombatColor == 'Hostile' then
      Desc = 'Target can attack you'
    elseif CombatColor == 'Attack' then
      Desc = "Target can't attack you, but you can attack them"
    elseif CombatColor == 'Flagged' then
      Desc = 'PvP flagged'
    elseif CombatColor == 'Ally' then
      Desc = 'Target is not PvP flagged'
    end

    if CombatColor == 'Hostile' or CombatColor == 'Attack' then
      Disabled = function()
                   return Main.UnitBars.CombatClassColor
                 end
    end

    FCOA['Player' .. CombatColor] = {
      type = 'color',
      name = CombatColor,
      desc = Desc,
      order = Order,
      width = 'half',
      hasAlpha = true,
      disabled = Disabled,
    }
  end

  return CombatColorOptions
end

-------------------------------------------------------------------------------
-- CreateTaggedColorOptions
--
-- Creates option to change tagged color.
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateTaggedColorOptions(Order, Name)
  local TaggedColorOptions = {
    type = 'group',
    name = Name,
    order = Order,
    dialogInline = true,
    get = function(Info)
            local KeyName = Info[#Info]
            local c = Main.UnitBars[KeyName]

            if KeyName ~= 'TaggedTest' then
              return c.r, c.g, c.b, c.a
            else
              return c
            end
          end,
    set = function(Info, r, g, b, a)
            local KeyName = Info[#Info]
            local UB = Main.UnitBars

            if KeyName ~= 'TaggedTest' then
              local c = UB[KeyName]
              c.r, c.g, c.b, c.a = r, g, b, a
            else
              UB.TaggedTest = r
            end

            -- Set the color to all the bars
            for _, UBF in ipairs(Main.UnitBarsFE) do
              UBF:Update()
            end
          end,
    args = {
      TaggedColor = {
        type = 'color',
        name = 'Tagged',
        order = 1,
        width = 'half',
        hasAlpha = true,
      },
      TaggedTest = {
        type = 'toggle',
        name = 'Test',
        order = 11,
        desc = 'Tagging is always on. For testing',
      },
      Spacer100 = CreateSpacer(100),
      Reset = {
        type = 'execute',
        name = 'Reset',
        desc = 'Reset colors back to defaults',
        width = 'half',
        confirm = true,
        order = 101,
        func = function()
                 Main:CopyTableValues(DUB.TaggedColor, Main.UnitBars.TaggedColor)

                 -- Set the color to all the bars
                 for _, UBF in ipairs(Main.UnitBarsFE) do
                   UBF:Update()
                 end
               end,
      },
    },
  }

  return TaggedColorOptions
end

-------------------------------------------------------------------------------
-- CreateFrameOptions
--
-- Creates options for frames dealing with player, target, and alternate power bar.
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-------------------------------------------------------------------------------
local function CreateFrameOptions(Order, Name)
  local FrameOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {
      PortraitGroup = {
        type = 'group',
        order = 1,
        name = 'Portraits',
        dialogInline = true,
        get = function(Info)
                local MultiValue = tonumber(Main.UnitBars[Info[#Info]]) or 0
                Main.UnitBars[Info[#Info]] = MultiValue
                return MultiValue ~= 0
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]
                local MultiValue = tonumber(Main.UnitBars[KeyName]) or 0

                MultiValue = MultiValue + 1
                if MultiValue > 2 then
                  MultiValue = 0
                end
                Main.UnitBars[KeyName] = MultiValue
                Main:UnitBarsSetAllOptions()
              end,
        args = {
          Notes = {
            type = 'description',
            name = 'Unchecked means do nothing. If you checked, then unchecked an option.\nYou may need to reload UI to avoid a conflict with another addon doing the same thing',
            order = 1,
          },
          HidePlayerFrame = {
            type = 'toggle',
            width = 'full',
            order = 2,
            name = function()
                     local HidePlayerFrame = tonumber(Main.UnitBars.HidePlayerFrame) or 0

                     if HidePlayerFrame <= 1 then
                       return 'Hide Player Frame'
                     elseif HidePlayerFrame == 2 then
                       return 'Show Player Frame'
                     end
                   end,
          },
          HideTargetFrame = {
            type = 'toggle',
            width = 'full',
            order = 3,
            tristate = true,
            name = function()
                     local HideTargetFrame = tonumber(Main.UnitBars.HideTargetFrame) or 0

                     if HideTargetFrame <= 1 then
                       return 'Hide Target Frame'
                     elseif HideTargetFrame == 2 then
                       return 'Show Target Frame'
                     end
                   end,
          },
        },
      },
      APBGroup = {
        type = 'group',
        order = 2,
        name = 'Blizzard Alternate Power Bar',
        dialogInline = true,
        get = function(Info)
                local KeyName = Info[#Info]
                return Main.UnitBars[KeyName]
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]
                Main.UnitBars[KeyName] = Value

                if KeyName == 'APBMoverOptionsDisabled' then
                  Main:APBSetMover()
                end
              end,
        args = {
          Notes = {
            type = 'description',
            name = 'This will let you move the blizzard alternate power bar and the timer like those in the Darkmoon Faire\nIf this conflicts with other addons just disable.  May have to reload UI',
            order = 1,
          },
          APBMoverOptionsDisabled = {
            type = 'toggle',
            name = 'Disable mover',
            width = 'normal',
            order = 2,
          },
          Spacer5 = CreateSpacer(5, 'normal'),
          Reset = {
            type = 'execute',
            name = 'Reset',
            width = 'half',
            order = 6,
            confirm = function()
                        return 'Are you sure?'
                      end,
            func = function()
                     Main:APBReset()
                   end,
            disabled = function()
                         return Main.UnitBars.APBMoverOptionsDisabled
                       end,
          },
          Spacer7 = CreateSpacer(7),
          MoveAPB = {
            type = 'execute',
            name = function()
                     if Main.APBMoverEnabled then
                       return 'Stop Moving APB'
                     else
                       return 'Move APB'
                     end
                   end,
            order = 8,
            func = function()
                     Main.APBMoverEnabled = not Main.APBMoverEnabled
                     Main:APBSetMover('apb')
                   end,
            disabled = function()
                         return Main.UnitBars.APBMoverOptionsDisabled
                       end,
          },
          Spacer10 = CreateSpacer(10),
          MoveAPBTimer = {
            type = 'execute',
            name = function()
                     if Main.APBBuffTimerMoverEnabled then
                       return 'Stop moving Timer'
                     else
                       return 'Move Timer'
                     end
                   end,
            order = 11,
            func = function()
                     Main.APBBuffTimerMoverEnabled = not Main.APBBuffTimerMoverEnabled
                     Main:APBSetMover('timer')
                   end,
            disabled = function()
                         return Main.UnitBars.APBMoverOptionsDisabled
                       end,
          },
        },
      },
      EABGroup = {
        type = 'group',
        order = 3,
        name = 'Extra Action Button',
        dialogInline = true,
        get = function(Info)
                local KeyName = Info[#Info]
                return Main.UnitBars[KeyName]
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]
                Main.UnitBars[KeyName] = Value

                if KeyName == 'EABMoverOptionsDisabled' then
                  Main:DoExtraActionButton()
                end
              end,
        args = {
          Notes = {
            type = 'description',
            name = 'This will let you move the extra action button. If this conflicts with other addons just disable.  May have to reload UI',
            order = 1,
          },
          EABMoverOptionsDisabled = {
            type = 'toggle',
            name = 'Disable mover',
            width = 'normal',
            order = 2,
          },
          Spacer5 = CreateSpacer(5, 'normal'),
          Reset = {
            type = 'execute',
            name = 'Reset',
            width = 'half',
            order = 6,
            confirm = function()
                        return 'Are you sure?'
                      end,
            func = function()
                     Main:EABReset()
                   end,
            disabled = function()
                         return Main.UnitBars.EABMoverOptionsDisabled
                       end,
          },
          Spacer7 = CreateSpacer(7),
          MoveEAB = {
            type = 'execute',
            name = function()
                     if Main.EABMoverEnabled then
                       return 'Stop Moving EAB'
                     else
                       return 'Move EAB'
                     end
                   end,
            order = 8,
            func = function()
                     Main.EABMoverEnabled = not Main.EABMoverEnabled
                     Main:DoExtraActionButton()
                   end,
            disabled = function()
                         return Main.UnitBars.EABMoverOptionsDisabled
                       end,
          },
        },
      },
    },
  }

  return FrameOptions
end

-------------------------------------------------------------------------------
-- CreateHelpOptions
--
-- Displays help and links
--
-- Subfunction of CreateMainOptions()
--
-- Order     Position in the options list.
-- Name      Name of the options.
-- Text      Array containing the text to display.
-------------------------------------------------------------------------------
local function CreateHelpOptions(Order, Name, Text)
  local HelpOptions = {
    type = 'group',
    name = Name,
    order = Order,
    args = {},
  }

  local HOA = HelpOptions.args

  for TextIndex = 1, #Text do
    local Text = Text[TextIndex]
    local TextKey = 'Text' .. TextIndex
    local Pos = strfind(Text, 'http')

    if Pos then
      local Name = strsub(Text, 1, Pos - 1)
      local Link = strsub(Text, Pos)

      HOA[TextKey] = {
        type = 'input',
        name = Name or '',
        order = TextIndex,
        width = 'double',
        dialogControl = 'GUB_EditBox_ReadOnly_Selected',
        get = function()
                return format('|Cffffff00%s|r', Link)
              end,
        set = function() end,
      }
    else
      Pos = strfind(Text, '[]', 1, true)

      if Pos then
        local Name = strsub(Text, 1, Pos - 1)
        local SubText = strsub(Text, Pos + 3) -- +1 to skip newline \n

        HOA[TextKey] = {
          type = 'group',
          name = Name,
          order = TextIndex,
          dialogInline = true,
          args = {
            SubText = {
              type = 'description',
              name = SubText,
              fontSize = 'medium',
              order = 1,
              width = 'full',
            }
          }
        }
      else
        HOA[TextKey] = {
          type = 'description',
          name = Text,
          fontSize = 'medium',
          order = TextIndex,
          width = 'full',
        }
      end
    end
    HOA['Spacer' .. TextIndex] = CreateSpacer(TextIndex + 0.5)
  end

  return HelpOptions
end

-------------------------------------------------------------------------------
-- CreateImportOptions
--
-- Creates options for importing triggers or bars
--
-- Subfunction of CreateMainOptions()
-------------------------------------------------------------------------------
local function CreateImportOptions(Order, Name)
  local ImportText
  local ImportSuccess
  local ImportVersion
  local ImportVersionType
  local ImportBarType
  local ImportType
  local ImportDisplayType
  local ImportName
  local ImportTable

  local ShowImportedHeader = false
  local ShowImportError = false

  local ImportOptions = {
    type = 'group',
    name = Name,
    order = 2,
    hidden = function()
               return not Options.Importing
             end,
    args = {
      Text = {
        type = 'description',
        name = '|cff00ff00Click anywhere in the box below and ctrl-v to paste text|r',
        fontSize = 'medium',
        order = 1,
      },
      Import = {
        type = 'input',
        name = '',
        order = 2,
        multiline = 10,
        dialogControl = 'GUB_MultiLine_EditBox_Import',
        width = 'full',
        get = function()
                return ImportText or ''
              end,
        set = function(Info, Text)
                ImportText = Text
                ImportSuccess, ImportVersion, ImportVersionType, ImportBarType, ImportType, ImportDisplayType, ImportName, ImportTable = Main:ImportStringTable(Text)

                if ImportSuccess then
                  ShowImportedHeader = true
                  ShowImportError = false
                else
                  ShowImportError = true
                  ShowImportedHeader = false
                  ImportText = ''
                end
              end,
      },
      ImportError = {
        type = 'description',
        name = 'TEXT COULD NOT BE IMPORTED',
        fontSize = 'large',
        order = 3,
        hidden = function()
                   return not ShowImportError
                 end,
      },
      ImportedHeader = {
        type = 'group',
        name = function()
                 if ImportType ~= 'alltriggers' then
                   return format('%s ( %s )', ImportDisplayType or '', ImportName or '')
                 else
                   return ImportDisplayType or ''
                 end
               end,
        order = 4,
        dialogInline = true,
        hidden = function()
                   return not ShowImportedHeader
                 end,
        args = {
          GUBVersion = {
            type = 'description',
            name = function()
                     return format('|cff00ff00GUB Version:|r %s', (ImportVersion or 0) / 100)
                   end,
            fontSize = 'medium',
            order = 1,
          },
          GUBVersionType = {
            type = 'description',
            name = function()
                     return format('|cff00ff00GUB Version Type:|r %s', ImportVersionType or '')
                   end,
            fontSize = 'medium',
            order = 2,
          },
          ExportedFrom = {
            type = 'description',
            name = function()
                     if ImportBarType then
                       return format('|cff00ff00Exported From:|r %s', DUB[ImportBarType]._Name or '')
                     else
                       return ''
                     end
                   end,
            fontSize = 'medium',
            order = 4,
            hidden = function()
                       return ImportType ~= 'trigger' and ImportType ~= 'alltriggers'
                     end,
          },
          ImportingTo = {
            type = 'description',
            name = function()
                     local BarType = Options.ImportSourceBarType

                     if BarType then
                       return format('|cff00ff00Importing To:|r %s', DUB[BarType]._Name or '')
                     else
                       return ''
                     end
                   end,
            fontSize = 'medium',
            order = 5,
          },
          TriggerDesc = {
            type = 'description',
            name = 'Triggers will always get appended to your existing ones',
            order = 6,
            fontSize = 'medium',
            hidden = function()
                       return ImportType ~= 'trigger' and ImportType ~= 'alltriggers'
                     end,
          },
          ImportData = {
            type = 'execute',
            name = 'Import',
            width = 'half',
            order = 7,
            confirm = function()
                        if ImportType == 'unitbar' then
                          return format('Importing settings to %s will overwrite all your current bar settings', DUB[Options.ImportSourceBarType]._Name)
                        end
                      end,
            func = function()
                     local UnitBarsF = Main.UnitBarsF
                     local ImportSourceBarType = Options.ImportSourceBarType
                     local UBF = UnitBarsF[ImportSourceBarType]
                     local BBar = UnitBarsF[ImportSourceBarType].BBar

                     if ImportType == 'trigger' then
                       -- Fake it as a triggers array
                       BBar:AppendTriggers({ ImportTable })
                     elseif ImportType == 'alltriggers' then
                       BBar:AppendTriggers(ImportTable)
                     elseif ImportType == 'unitbar' then
                       -- Need to deep copy
                       Main:CopyTableValues(ImportTable, Main.UnitBars[ImportSourceBarType], true)
                     end

                     -- Need to do this to be sure the data is safe
                     Main:FixUnitBars()

                     -- Update the layout.
                     Main.CopyPasted = true

                     UBF:SetAttr()
                     UBF:Update()

                     Main.CopyPasted = false
                     -- Update any text highlights.  Use 'on' since its always on when options are opened.
                     Bar:SetHighlightFont('on', Main.UnitBars.HideTextHighlight)

                     -- Update any dynamic options.
                     Options:DoFunction()

                     -- Close import
                     ImportText = ''
                     ShowImportedHeader = false
                     ShowImportError = false
                     Options.Importing = false
                     AceConfigDialog:SelectGroup(AddonMainOptions, 'UnitBars')
                   end,
            hidden = function()
                       return ImportType == 'unitbar'and ImportBarType ~= Options.ImportSourceBarType
                     end
          },
          ImportError = {
            type = 'description',
            name = function()
                     if ImportType == 'unitbar'and Options.ImportSourceBarType ~= ImportBarType then
                       return format("Can't import this Unitbar. Must be imported from %s", DUB[ImportBarType]._Name)
                     end
                   end,
            order = 8,
            fontSize = 'large',
            hidden = function()
                       return ImportType == 'unitbar'and ImportBarType == Options.ImportSourceBarType
                     end,
          },
        },
      },
      ExitImport = {
        type = 'execute',
        name = 'Exit',
        order = 10,
        width = 'half',
        func = function()
                 ImportText = ''
                 ShowImportedHeader = false
                 ShowImportError = false
                 Options.Importing = false
                 AceConfigDialog:SelectGroup(AddonMainOptions, 'UnitBars')
               end,
      },
    },
  }

  return ImportOptions
end

-------------------------------------------------------------------------------
-- CreateExportOptions
--
-- Creates export for exporting triggers or bars
--
-- Subfunction of CreateMainOptions()
-------------------------------------------------------------------------------
local function CreateExportOptions(Order, Name)
  local ImportSuccess
  local ImportVersion
  local ImportVersionType
  local ImportBarType
  local ImportType
  local ImportDisplayType
  local ImportName
  local ImportTable

  local ExportOptions = {
    type = 'group',
    name = 'Export',
    order = 2,
    hidden = function()
               return not Options.Exporting
             end,
    args = {
      Text = {
        type = 'description',
        name = '|cff00ff00Click anywhere in the box below and ctrl-c to copy or ctrl-x to cut|r',
        fontSize = 'medium',
        order = 1,
      },
      Export = {
        type = 'input',
        name = '',
        order = 2,
        multiline = 12,
        dialogControl = 'GUB_MultiLine_EditBox_Export',
        width = 'full',
        get = function()
                local ExportData = Options.ExportData
                ImportSuccess, ImportVersion, ImportVersionType, ImportBarType, ImportType, ImportDisplayType, ImportName, ImportTable = Main:ImportStringTable(ExportData)

                return ExportData
              end,
        set = function()
              end,
      },
      ExportedHeader = {
        type = 'group',
        name = function()
                 if ImportType ~= 'alltriggers' then
                   return format('%s ( %s )', ImportDisplayType or '', ImportName or '')
                 else
                   return ImportDisplayType or ''
                 end
               end,
        order = 3,
        dialogInline = true,
        args = {
          GUBVersion = {
            type = 'description',
            name = function()
                     return format('|cff00ff00GUB Version:|r %s', (ImportVersion or 0) / 100)
                   end,
            fontSize = 'medium',
            order = 1,
          },
          GUBVersionType = {
            type = 'description',
            name = function()
                     return format('|cff00ff00GUB Version Type:|r %s', ImportVersionType or '')
                   end,
            fontSize = 'medium',
            order = 2,
          },
          ExportedFrom = {
            type = 'description',
            name = function()
                     local BarType = ImportBarType

                     if BarType then
                       return format('|cff00ff00Exported From:|r %s', DUB[BarType]._Name or '')
                     else
                       return ''
                     end
                   end,
            fontSize = 'medium',
            order = 3,
            hidden = function()
                       return ImportType ~= 'trigger' and ImportType ~= 'alltriggers'
                     end,
          },
        },
      },
      ExitExport = {
        type = 'execute',
        name = 'Exit',
        order = 10,
        width = 'half',
        func = function()
                 Options.ExportData = ''
                 Options.Exporting = false
                 AceConfigDialog:SelectGroup(AddonMainOptions, 'UnitBars')
               end,
      },
    },
  }

  return ExportOptions
end

-------------------------------------------------------------------------------
-- CreateMainOptions
--
-- Returns the main options table.
-------------------------------------------------------------------------------
local function ImportExportHidden()
  return Options.Importing or Options.Exporting
end

local function CreateMainOptions()
  MainOptions = {
    name = AddonName,
    type = 'group',
    order = 1,
    childGroups = 'tab',
    args = {
      Import = CreateImportOptions(1, 'Import'),
      Export = CreateExportOptions(2, 'Export'),
--=============================================================================
-------------------------------------------------------------------------------
--    GENERAL group.
-------------------------------------------------------------------------------
--=============================================================================

      General = {
        name = 'General',
        type = 'group',
        childGroups = 'tab',
        order = 10,
        get = function(Info)
                return Main.UnitBars[Info[#Info]]
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]

                Main.UnitBars[KeyName] = Value
                Main:UnitBarsSetAllOptions()

                if strfind(KeyName, 'Animation') == nil then
                  GUB:UnitBarsUpdateStatus()
                end

                -- Update align and swap bar location if needed if clamped cause bar to go off screen.
                if KeyName == 'Clamped' and not Main.UnitBars.Align and Options.AlignSwapOptionsOpen then
                  Options:RefreshAlignSwapOptions()
                end
              end,
        hidden = ImportExportHidden,
        args = {
          Main = {
            type = 'group',
            name = 'Main',
            order = 1,
            args = {
              Bars = {
                name = 'Bars',
                type = 'group',
                order = 1,
                dialogInline = true,
                args = {
                  Locked = {
                    type = 'toggle',
                    name = 'Lock',
                    order = 1,
                    desc = 'Prevent bars from being dragged around',
                  },
                  Show = {
                    type = 'toggle',
                    name = 'Show',
                    order = 2,
                    desc = "Shows all bars even if they shouldn't be shown",
                  },
                  Testing = {
                    type = 'toggle',
                    name = 'Test Mode',
                    order = 3,
                    desc = 'All bars will be displayed using fixed values',
                  },
                },
              },
              Tooltips = {
                type = 'group',
                name = 'Hide Tooltips',
                order = 2,
                dialogInline = true,
                args = {
                  HideTooltipsLocked = {
                    type = 'toggle',
                    name = 'Locked',
                    desc = 'Tooltips will be hidden when bars are locked',
                    order = 1,
                  },
                  HideTooltipsNotLocked = {
                    type = 'toggle',
                    name = 'Not Locked',
                    desc = 'Tooltips will be hidden when bars are not locked',
                    order = 2,
                  },
                  HideTooltipsDesc = {
                    type = 'toggle',
                    name = 'Description',
                    order = 10,
                    desc = 'Turns off the description in tooltips',
                  },
                  HideLocationInfo = {
                    type = 'toggle',
                    name = 'Location Info',
                    order = 11,
                    desc = 'Turns off the location information for bars and boxes in tooltips',
                  },
                },
              },
              Layout = {
                type = 'group',
                name = 'Other',
                order = 3,
                dialogInline = true,
                args = {
                  Clamped = {
                    type = 'toggle',
                    name = 'Screen Clamp',
                    order = 1,
                    desc = 'Prevent bars from going off the screen',
                  },
                  Grouped = {
                    type = 'toggle',
                    name = 'Group Drag',
                    order = 2,
                    desc = 'Drag all the bars as one instead of one at a time',
                  },
                  AlignAndSwapEnabled = {
                    type = 'toggle',
                    name = 'Enable Align & Swap',
                    order = 3,
                    desc = 'If unchecked, right clicking a unitbar will not open align and swap',
                  },
                  HideTextHighlight = {
                    type = 'toggle',
                    name = 'Hide Text Highlight',
                    order = 4,
                    desc = 'Text will not be highlighted when options is opened',
                  },
                  HighlightDraggedBar = {
                    type = 'toggle',
                    name = 'Highlight Dragged Bar',
                    order = 5,
                    desc = 'The bar being dragged will show a box around it',
                  },
                  BarFillFPS = {
                    type = 'range',
                    name = 'Bar Fill FPS',
                    order = 6,
                    desc = 'Change the frame rate of smooth fill and timer bars. Higher values will reduce choppyness, but will consume more cpu',
                    min = o.BarFillFPSMin,
                    max = o.BarFillFPSMax,
                    step = 1,
                  },
                },
              },
              Animation = {
                name = 'Animation',
                type = 'group',
                order = 4,
                dialogInline = true,
                args = {
                  ReverseAnimation = {
                    type = 'toggle',
                    name = 'Reverse Animation',
                    order = 1,
                    desc = 'Animation in/out can switch direction smoothly',
                  },
                  AnimationType = {
                    type = 'select',
                    name = 'Animation Type',
                    order = 2,
                    style = 'dropdown',
                    desc = 'Changes the type of animation played when showing or hiding bars',
                    values = AnimationTypeDropdown,
                  },
                  Spacer = CreateSpacer(3),
                  AnimationInTime = {
                    type = 'range',
                    name = 'Animation-in',
                    order = 8,
                    desc = 'The amount of time in seconds to play animation after showing a bar',
                    min = 0,
                    max = o.AnimationInTime,
                    step = 0.1,
                  },
                  AnimationOutTime = {
                    type = 'range',
                    name = 'Animation-out',
                    order = 9,
                    desc = 'The amount of time in seconds to play animation before hiding a bar',
                    min = 0,
                    max = o.AnimationOutTime,
                    step = 0.1,
                  },
                },
              },
            },
          },
          Frames = CreateFrameOptions(4, 'Frames'),
          Colors = {
            type = 'group',
            name = 'Colors',
            order = 5,
            args = {
              PowerColors = CreatePowerColorOptions(5, 'Power Color'),
              ClassColors = CreateClassColorOptions(6, 'Class Color'),
              CombatColors = CreateCombatColorOptions(7, 'Combat Color'),
              TaggedColor = CreateTaggedColorOptions(8, 'Tagged color'),
            },
          },
          AuraOptions = CreateAuraOptions(6, 'Aura List'),
          AltPowerBar = CreateAltPowerBarOptions(7, 'Alt Power Bar'),
          DebugOptions = CreateDebugOptions(8, 'Debug'),
        },
      },
    },
  }

--=============================================================================
-------------------------------------------------------------------------------
--    BARS group.
-------------------------------------------------------------------------------
--=============================================================================
  local MainOptionsArgs = MainOptions.args

  MainOptionsArgs.UnitBars = {
    type = 'group',
    name = 'Bars',
    order = 11,
    hidden = ImportExportHidden,
    args = {}
  }

  -- Enable Unitbar options.
  MainOptionsArgs.UnitBars.args.EnableBars = CreateEnableUnitBarOptions(MainOptionsArgs.UnitBars.args, 0, 'Enable', 'Enable or Disable bars')

--=============================================================================
-------------------------------------------------------------------------------
--    UTILITY group.
-------------------------------------------------------------------------------
--=============================================================================
--  MainOptionsArgs.Utility = {
--    type = 'group',
--    name = 'Utility',
--    order = 3,
--    args = {
--      AuraList = CreateAuraOptions(1, 'Aura List'),
--    },
--  }

--=============================================================================
-------------------------------------------------------------------------------
--    PROFILES group.
-------------------------------------------------------------------------------
--=============================================================================
  local Profile = AceDBOptions:GetOptionsTable(GUB.MainDB)
  MainOptionsArgs.Profile = Profile
  Profile.order = 100
  Profile.hidden = ImportExportHidden

--=============================================================================
-------------------------------------------------------------------------------
--    HELP group.
-------------------------------------------------------------------------------
--=============================================================================
  MainOptionsArgs.Help = {
    type = 'group',
    name = 'Help',
    order = 101,
    childGroups = 'tab',
    hidden = ImportExportHidden,
    args = {
      HelpText = CreateHelpOptions(1, format('|cffffd200%s   version %.2f|r', AddonName, DefaultUB.Version / 100), DefaultUB.HelpText),
      LinksText = CreateHelpOptions(2, 'Links', DefaultUB.LinksText),
      Changes = CreateHelpOptions(3, 'Changes', DefaultUB.ChangesText),
    },
  }

  return MainOptions
end

-------------------------------------------------------------------------------
-- CreateMessageBoxOptions
--
-- Creates a simple table to display a message box in an options frame.
-------------------------------------------------------------------------------
local function CreateMessageBoxOptions()
  local MessageBoxOptions = {
    type = 'group',
    name = AddonName,
    order = 1,
    args = {
      Message = {
        type = 'description',
        name = '',
      },
    },
  }

  return MessageBoxOptions
end

-------------------------------------------------------------------------------
-- MessageBox
--
-- Opens a message box to display a message
-------------------------------------------------------------------------------
function GUB.Options:MessageBox(Message)
  MessageBoxOptions.args.Message.name = Message
  AceConfigDialog:Open(AddonMessageBoxOptions)
end

-------------------------------------------------------------------------------
-- CreateAlingSwapOptions
--
-- Creates align and swap options for unitbars.
-------------------------------------------------------------------------------
local function CreateAlignSwapOptions()
  local AlignSwapOptions

  local function SetSize()
    for KeyName in pairs(AlignSwapOptions.args) do
      local SliderArgs = AlignSwapOptions.args[KeyName]
      local Min
      local Max

      if strfind(KeyName, 'Padding') then
        Min = o.AlignSwapPaddingMin
        Max = o.AlignSwapPaddingMax
      elseif strfind(KeyName, 'Offset') then
        Min = o.AlignSwapOffsetMin
        Max = o.AlignSwapOffsetMax
      end
      if Min and Max then
        local Value = Main.UnitBars[KeyName]

        if Main.UnitBars.AlignSwapAdvanced then
          Value = Value < Min and Min or Value > Max and Max or Value
          Main.UnitBars[KeyName] = Value
          SliderArgs.min = Value - o.AlignSwapAdvancedMinMax
          SliderArgs.max = Value + o.AlignSwapAdvancedMinMax
        else
          SliderArgs.min = Min
          SliderArgs.max = Max
        end
      end
    end
  end

  AlignSwapOptions = {
    type = 'group',
    name = 'Align and Swap',
    order = 1,
    get = function(Info)
            local KeyName = Info[#Info]

            if KeyName == 'x' or KeyName == 'y' then
              local UB = AlignSwapAnchor.UnitBar
              local BarX, BarY = floor(UB._x + 0.5), floor(UB._y + 0.5)

              if KeyName == 'x' then
                return format('%s', floor(BarX + 0.5))
              else
                return format('%s', floor(BarY + 0.5))
              end
            else
              SetSize()
              return Main.UnitBars[Info[#Info]]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            if KeyName == 'x' or KeyName == 'y' then
              Value = tonumber(Value)
              if Value then
                AlignSwapAnchor.UnitBar[KeyName] = Value
              end
              local UB = AlignSwapAnchor.UnitBar

              -- Position unitbar in new location.
              Main:SetAnchorPoint(AlignSwapAnchor, UB._x, UB._y)
            else
              if KeyName == 'Swap' and Value then
                Main.UnitBars.Align = false
              elseif KeyName == 'Align' and Value then
                Main.UnitBars.Swap = false
              end
              Main.UnitBars[KeyName] = Value
              SetSize()
              Main:SetUnitBarsAlignSwap()
            end
          end,
    args = {
      Align = {
        type = 'toggle',
        name = 'Align',
        order = 1,
        width = 'half',
        desc = 'When a bar is dragged near another it will align its self to it. \nThis needs to be unchecked to set bar location',
      },
      Swap = {
        type = 'toggle',
        name = 'Swap',
        order = 2,
        width = 'half',
        desc = 'Allows you to swap one bar with another',
      },
      AlignSwapAdvanced = {
        type = 'toggle',
        name = 'Advanced',
        order = 3,
        desc = 'Allows you to make fine tune adjustments easier with the sliders',
        hidden = function()
                     return not Main.UnitBars.Align
                   end,
      },
      AlignSwapPaddingX = {
        type = 'range',
        name = 'Padding Horizontal',
        order = 11,
        desc = 'Sets the distance between two or more bars that are aligned horizontally',
        step = 1,
        hidden = function()
                     return not Main.UnitBars.Align
                   end,
      },
      AlignSwapPaddingY = {
        type = 'range',
        name = 'Padding Vertical',
        order = 12,
        desc = 'Sets the distance between two or more bars that are aligned vertically',
        step = 1,
        hidden = function()
                     return not Main.UnitBars.Align
                   end,
      },
      AlignSwapOffsetX = {
        type = 'range',
        name = 'Offset Horizontal',
        order = 21,
        desc = 'Offsets the padding group',
        step = 1,
        hidden = function()
                     return not Main.UnitBars.Align
                   end,
      },
      AlignSwapOffsetY = {
        type = 'range',
        name = 'Offset Vertical',
        order = 22,
        desc = 'Offsets the padding group',
        step = 1,
        hidden = function()
                     return not Main.UnitBars.Align
                   end,
      },
      BarLocation = {
        type = 'group',
        name = function()
                 return format('Bar Location (%s)    Anchor Point (%s)', AlignSwapAnchor.Name, PositionDropdown[AlignSwapAnchor.UnitBar.Attributes.AnchorPoint])
               end,
        dialogInline = true,
        order = 30,
        hidden = function()
                   return Main.UnitBars.Align
                 end,
        args = {
          x = {
            type = 'input',
            name = 'Horizontal',
            order = 1,
          },
          y = {
            type = 'input',
            name = 'Vertical',
            order = 2,
          },
        },
      },
    },
  }

  return AlignSwapOptions
end

-------------------------------------------------------------------------------
-- OpenAlignSwapOptions
--
-- Opens up a window with the align and swap options for unitbars.
--
-- UnitBar   Unitbar that was right clicked on.
-------------------------------------------------------------------------------
local function OnHideAlignSwapOptions(self)
  self:SetScript('OnHide', nil)
  self.AlignSwapOptionFrame:SetClampedToScreen(self.Clamped)
  self.AlignSwapOptionFrame = nil

  Options.AlignSwapOptionsOpen = false
  Main:MoveFrameSetAlignPadding(Main.UnitBarsFE, 'reset')
end

function GUB.Options:OpenAlignSwapOptions(Anchor)
  if not Main.InCombat then
    AlignSwapAnchor = Anchor

    AceConfigDialog:SetDefaultSize(AddonAlignSwapOptions, o.AlignSwapWidth, o.AlignSwapHeight)
    AceConfigDialog:Open(AddonAlignSwapOptions)

    local AlignSwapOptionFrame = AceConfigDialog.OpenFrames[AddonAlignSwapOptions].frame

    AlignSwapOptionsHideFrame:SetParent(AlignSwapOptionFrame)
    AlignSwapOptionsHideFrame:SetScript('OnHide', OnHideAlignSwapOptions)
    AlignSwapOptionsHideFrame.Clamped = AlignSwapOptionFrame:IsClampedToScreen() and true or false
    AlignSwapOptionsHideFrame.AlignSwapOptionFrame = AlignSwapOptionFrame

    AlignSwapOptionFrame:SetClampedToScreen(true)

    Options.AlignSwapOptionsOpen = true
  else
    print(DefaultUB.InCombatOptionsMessage)
  end
end

--*****************************************************************************
--
-- Options Initialization
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- OnInitialize()
--
-- Initializes the options panel and slash options
-------------------------------------------------------------------------------
function GUB.Options:OnInitialize()

  OptionsToGUB = CreateOptionsToGUB()
  SlashOptions = CreateSlashOptions()
  AlignSwapOptions = CreateAlignSwapOptions()
  MainOptions = CreateMainOptions()
  MessageBoxOptions = CreateMessageBoxOptions()

  -- Register profile options with aceconfig.
  --LibStub('AceConfig-3.0'):RegisterOptionsTable(AddonProfileName, ProfileOptions)

  -- Register the options panels with aceconfig.
  AceConfig:RegisterOptionsTable(AddonSlashOptions, SlashOptions, 'gub')
  AceConfig:RegisterOptionsTable(AddonMainOptions, MainOptions)
  AceConfig:RegisterOptionsTable(AddonAlignSwapOptions, AlignSwapOptions)
  AceConfig:RegisterOptionsTable(AddonOptionsToGUB, OptionsToGUB)
  AceConfig:RegisterOptionsTable(AddonMessageBoxOptions, MessageBoxOptions)

  -- Add the options panels to blizz options.
  --MainOptionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(AddonMainOptions, AddonName)
  --local OptionsToGUBFrame = AceConfigDialog:AddToBlizOptions(AddonOptionsToGUB, AddonName)

  -- Add the Profiles UI as a subcategory below the main options.
  --ProfilesOptionsFrame = LibStub('AceConfigDialog-3.0'):AddToBlizOptions(AddonProfileName, 'Profiles', AddonName)
end

-- forward to text and trigger options
GUB.Options.FindMenuItem = FindMenuItem
GUB.Options.HideTooltip = HideTooltip
GUB.Options.CreateSpacer = CreateSpacer
GUB.Options.CreateSpecOptions = CreateSpecOptions
GUB.Options.CreateColorAllOptions = CreateColorAllOptions


