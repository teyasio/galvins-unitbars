--
-- TriggerOptions.lua
--
-- Handles all the trigger options for GalvinUnitBars.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local DefaultUB = GUB.DefaultUB
local DUB = DefaultUB.Default.profile

local Options = GUB.Options
local Main = GUB.Main
local Bar = GUB.Bar

-- tables
local o = Options.o
local AceConfigDialog = Options.AceConfigDialog
local AddonMainOptions = Options.AddonMainOptions
local LSMDropdown = Options.LSMDropdown
local FontStyleDropdown = Options.FontStyleDropdown

-- functions
local CreateSpacer = Options.CreateSpacer
local FindMenuItem = Options.FindMenuItem
local HideTooltip = Options.HideTooltip
local CreateSpecOptions = Options.CreateSpecOptions
local CreateStanceOptions = Options.CreateStanceOptions

-- localize some globals.
local _, _G, print =
      _, _G, print
local strupper, strtrim, strfind, format, strsplit, strsub, tostring =
      strupper, strtrim, strfind, format, strsplit, strsub, tostring
local tonumber, gsub, tremove, tinsert, tconcat     , wipe, strsub =
      tonumber, gsub, tremove, tinsert, table.concat, wipe, strsub
local ipairs, pairs, type, select, next =
      ipairs, pairs, type, select, next
local C_Spell_GetSpellName, C_Spell_GetSpellTexture =
      C_Spell.GetSpellName, C_Spell.GetSpellTexture
local IsModifierKeyDown =
      IsModifierKeyDown

local TextLineDropdown = {
  [0] = 'All',
  [1] = 'Line 1',
  [2] = 'Line 2',
  [3] = 'Line 3',
  [4] = 'Line 4',
}

local Operator_NumberDropdown = {
  '<',             -- 1
  '>',             -- 2
  '<=',            -- 3
  '>=',            -- 4
  '=',             -- 5
  '<>',            -- 6
}

local Operator_TextStateDropdown = {
  '=',  -- 1
  '<>', -- 2
}

local TriggerOperatorDropdown = {
  whole   = Operator_NumberDropdown,
  percent = Operator_NumberDropdown,
  decimal = Operator_NumberDropdown,
  text    = Operator_TextStateDropdown,
  state   = Operator_TextStateDropdown,
}

local TriggerSoundChannelDropdown = {
  Ambience = 'Ambience',
  Master = 'Master',
  Music = 'Music',
  SFX = 'Sound Effects',
  Dialog = 'Dialog',
}

local TriggerStateValueDropdown = {
  'True',   -- 1
  'False',  -- 2
}

local AuraStackOperatorDropdown = {
  '<',             -- 1
  '>',             -- 2
  '<=',            -- 3
  '>=',            -- 4
  '=',             -- 5
  '<>',            -- 6
}

local DebuffTypesDropdown = {
  'Curse',         -- 1
  'Disease',       -- 2
  'Enrage',        -- 3
  'Magic',         -- 4
  'Poison',        -- 5
}

local TriggerTypeColorIcon = {
  bartexturecolor = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBarColor]],
  bartexture      = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBar]],
  border          = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBorder]],
  bordercolor     = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBorderColor]],
  texturescale    = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextureScale]],
  baroffset       = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerChangeOffset]],
  sound           = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerSound]],
  background      = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBackground]],
  backgroundcolor = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBackgroundColor]],
  fontsize        = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextChangeSize]],
  fontoffset      = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextChangeOffset]],
  fontcolor       = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextColor]],
  fonttype        = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextType]],
  fontstyle       = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerTextOutline]],

  regionborder          = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBorder]],
  regionbordercolor     = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBorderColor]],
  regionbackground      = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBackground]],
  regionbackgroundcolor = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_TriggerBackgroundColor]],
}

--*****************************************************************************
--
-- Trigger Options Utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- ToHex
--
-- Returns a hexidecimal address of a function or table.
-------------------------------------------------------------------------------
local function ToHex(Object)
  return strtrim(select(2, strsplit(':', tostring(Object))))
end

-------------------------------------------------------------------------------
-- TriggerTypeToIcon
--
-- Returns an icon to inserted into text for triggers
-------------------------------------------------------------------------------
local function TriggerTypeToIcon(Type,Size)
  return format('|T%s:%s|t', TriggerTypeColorIcon[Type], Size)
end

--*****************************************************************************
--
-- Trigger Options creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- CreateTriggerDisplayOptions
--
-- Subfunction of CreateTriggerTabOptions()
--
-- Creates options to create the displaying of the triggers
-------------------------------------------------------------------------------
local function CreateTriggerDisplayOptions(Order, UBF, BBar, Trigger)
  local TriggerData = BBar.TriggerData
  local GroupsDropdown = TriggerData.GroupsDropdown
  local Groups = TriggerData.Groups
  local OT = GUB.Bar.TriggerObjectTypes
  local TypeBorder =     {OT.BackgroundBorder,
                          OT.RegionBorder     }
  local TypeColor =      {OT.BackgroundBorderColor,
                          OT.BackgroundColor,
                          OT.BarColor,
                          OT.RegionBorderColor,
                          OT.RegionBackgroundColor }
  local TypeBackground = {OT.BackgroundBackground,
                          OT.RegionBackground     }
  local Name = ''

  ----------------------
  -- TriggerDisplayGroup
  ----------------------
  local function TriggerDisplayGroup(Order, ObjectTypes, Args)
    return {
      type = 'group',
      name = function()
               return Name
             end,
      order = Order,
      dialogInline = true,
      hidden = function()
                 local Found = false
                 for _, ObjectType in pairs(ObjectTypes) do
                   if Trigger.ObjectType == ObjectType then
                     Found = true
                     break
                   end
                 end
                 return not Found
               end,
      args = Args,
    }
  end

  ----------------
  -- Color Options
  ----------------
  local ColorOptions = {
    type = 'group',
    name = '',
    order = 100,
    dialogInline = true,
    hidden = function()
               return strfind(Trigger.ObjectType, 'color') == nil
             end,
    args = {
      Color = {
        type = 'color',
        name = 'Color',
        order = 1,
        width = 'half',
        get = function()
                return Trigger.Par1, Trigger.Par2, Trigger.Par3, Trigger.Par4
              end,
        set = function(Info, r, g, b, a)
                Trigger.Par1, Trigger.Par2, Trigger.Par3, Trigger.Par4 = r, g, b, a

                -- Dont need to do a checktriggers here
                UBF:Update()
                BBar:Display()
              end,
      },
      ColorType = {
        type = 'select',
        name = 'Color Type',
        desc = 'This will override the current color, if there is a new one to replace it with',
        order = 2,
        values = Bar.TriggerColorPulldown,
        get = function()
                return Bar.TriggerConvertColorIndex[Trigger.ColorFnType]
              end,
        set = function(Info, Value)
                Trigger.ColorFnType = Bar.TriggerConvertColorIndex[Value]

                -- Need to do a check triggers when changing color type
                BBar:CheckTriggers()
                UBF:Update()
                BBar:Display()
              end,
      },
      ColorUnit = {
        type = 'input',
        name = 'Color Unit',
        desc = 'Enter the unit you want to get the color from',
        order = 3,
        hidden = function()
                   return Trigger.ColorFnType == ''
                 end,
      },
    },
  }

  ------------------
  -- Animate Options
  ------------------
  local AnimateOptions = {
    type = 'group',
    name = '',
    order = 1,
    dialogInline = true,
    hidden = function()
               return not Trigger.CanAnimate
             end,
    args = {
      Animate = {
        type = 'toggle',
        name = 'Animate',
        desc = 'Apply animation to this trigger',
        order = 1,
      },
      AnimateSpeed = {
        type = 'range',
        name = 'Animate Speed',
        order = 2,
        desc = 'Changes the speed of the animation',
        step = .01,
        isPercent = true,
        disabled = function()
                     return not Trigger.Animate
                   end,
        min = o.TriggerAnimateSpeedMin,
        max = o.TriggerAnimateSpeedMax,
      },
    },
  }

  --------------------
  -- Text Line Options
  --------------------
  local TextLineOptions = {
    type = 'select',
    name = 'Text Line',
    order = 2,
    values = TextLineDropdown,
    style = 'dropdown',
  }

  ---===============
  -- Display Options
  ---===============
  local DisplayOptions = {
    type = 'group',
    name = '',
    order = Order,
    dialogInline = true,
    get = function(Info)
            local KeyName = Info[#Info]
            local Value = Trigger[KeyName]

            if KeyName == 'ObjectTypeID' then
              local Group = Groups[Trigger.GroupNumber]
              Value = Group.Objects[Value].Index
              Name = gsub(Group.ObjectsDropdown[Value], 'BG:', 'Background:')

              return Value
            end

            return Trigger[KeyName]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local Default

            if KeyName == 'GroupNumber' then
              Default = 'default'
              BBar:UndoTriggers()

            elseif KeyName == 'ObjectTypeID' then
              local Group = Groups[Trigger.GroupNumber]
              Name = gsub(Group.ObjectsDropdown[Value], 'BG:', 'Background:')
              Value = Group.IndexObjectTypeID[Value]

              Trigger[KeyName] = Value
              -- Setting pars to nil will force checktriggers to set defaults
              Trigger.Par1, Trigger.Par2, Trigger.Par3, Trigger.Par4 = nil, nil, nil, nil

              -- Check triggers to set default pars
              BBar:CheckTriggers()
              UBF:Update()
              BBar:Display()

              return
            end
            Trigger[KeyName] = Value

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers(Default)
            UBF:Update()
            BBar:Display()
          end,
    args = {
      GroupNumber = {
        type = 'select',
        name = 'Name',
        order = 1,
        values = GroupsDropdown,
      },
      ObjectTypeID = {
        type = 'select',
        dialogControl = 'GUB_Dropdown_Select',
        name = 'Type',
        order = 2,
        width = 'double',
        values = function()
                   return Groups[Trigger.GroupNumber].ObjectsDropdown
                 end,
      },
      ObjectGroups = {
        type = 'group',
        name = '',
        order = 5,
        get = function(Info)
                local KeyName = Info[#Info]

                return Trigger[KeyName]
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]

                if KeyName == 'ColorUnit' then
                  Value = strsplit(' ', Value)
                end

                Trigger[KeyName] = Value

                if KeyName == 'TextLine' then
                  -- Undo changes on other textlines
                  BBar:UndoTriggers()
                end
                -- Update bar to reflect trigger changes
                -- Don't do check triggers here
                UBF:Update()
                BBar:Display()
              end,
        args = {
          -- %%%%%%
          -- Border
          -- %%%%%%
          Border = TriggerDisplayGroup(4, TypeBorder, {
            Par1 = {
              type = 'select',
              name = 'Border',
              order = 10,
              dialogControl = 'LSM30_Border',
              width = 'double',
              values = LSMDropdown.Border,
            },
          }),
          -- %%%%%
          -- Color
          -- %%%%%
          Color = TriggerDisplayGroup(4, TypeColor, {
            ColorGroup = ColorOptions,
          }),
          -- %%%%%%%%%%
          -- Background
          -- %%%%%%%%%%
          Background = TriggerDisplayGroup(4, TypeBackground, {
            Par1 = {
              type = 'select',
              name = 'Background',
              width = 'double',
              order = 10,
              dialogControl = 'LSM30_Background',
              values = LSMDropdown.Background,
            },
          }),
          -- %%%%%%%%%%
          -- Bartexture
          -- %%%%%%%%%%
          BarTexture = TriggerDisplayGroup(4, {OT.BarTexture}, {
            Par1 = {
              type = 'select',
              name = 'Texture',
              order = 10,
              width = 'double',
              dialogControl = 'LSM30_Statusbar',
              values = LSMDropdown.StatusBar,
            },
          }),
          -- %%%%%%%%%%%%%
          -- Texture Scale
          -- %%%%%%%%%%%%%
          TextureScale = TriggerDisplayGroup(4, {OT.TextureScale}, {
            Animate = AnimateOptions,
            Par1 = {
              type = 'range',
              name = 'Texture Scale',
              order = 10,
              desc = 'Change the texture size',
              step = .01,
              width = 'double',
              isPercent = true,
              min = o.TriggerTextureScaleMin,
              max = o.TriggerTextureScaleMax,
            },
          }),
          -- %%%%%%%%%%
          -- Bar Offset
          -- %%%%%%%%%%
          BarOffset = TriggerDisplayGroup(4, {OT.BarOffset}, {
            OffsetAll = {
              type = 'toggle',
              name = 'All',
              order = 7,
              get = function()
                      return Trigger.OffsetAll
                    end,
              set = function(Info, Value)
                      Trigger.OffsetAll = Value
                    end,
              desc = 'Change offset with one value'
            },
            Animate = AnimateOptions,
            All = {
              type = 'range',
              name = 'Offset',
              order = 8,
              width = 'double',
              get = function()
                      return Trigger.Par1
                    end,
              set = function(Info, Value)
                      Trigger.Par1 = Value
                      Trigger.Par2 = -Value
                      Trigger.Par3 = -Value
                      Trigger.Par4 = Value

                      -- Dont need to do a checktriggers here.
                      UBF:Update()
                      BBar:Display()
                    end,
              hidden = function()
                         return not Trigger.OffsetAll
                       end,
              min = o.TriggerBarOffsetAllMin,
              max = o.TriggerBarOffsetAllMax,
              step = 1,
            },
            Spacer9 = CreateSpacer(9),
            Par1 = { -- Left
              type = 'range',
              name = 'Left',
              order = 10,
              hidden = function()
                         return Trigger.OffsetAll
                       end,
              min = o.TriggerBarOffsetLeftMin,
              max = o.TriggerBarOffsetLeftMax,
              step = 1,
            },
            Par2 = { -- Right
              type = 'range',
              name = 'Right',
              order = 11,
              hidden = function()
                         return Trigger.OffsetAll
                       end,
              min = o.TriggerBarOffsetRightMin,
              max = o.TriggerBarOffsetRightMax,
              step = 1,
            },
            Spacer12 = CreateSpacer(12),
            Par3 = { -- Top
              type = 'range',
              name = 'Top',
              order = 13,
              hidden = function()
                         return Trigger.OffsetAll
                       end,
              min = o.TriggerBarOffsetTopMin,
              max = o.TriggerBarOffsetTopMax,
              step = 1,
            },
            Par4 = { -- Bottom
              type = 'range',
              name = 'Bottom',
              order = 14,
              hidden = function()
                         return Trigger.OffsetAll
                       end,
              min = o.TriggerBarOffsetBottomMin,
              max = o.TriggerBarOffsetBottomMax,
              step = 1,
            },
          }),
          -- %%%%%%%%%%%%%%%
          -- Text font color
          -- %%%%%%%%%%%%%%%
          TextFontColor = TriggerDisplayGroup(4, {OT.TextFontColor}, {
            TextLine = TextLineOptions,
            Spacer3 = CreateSpacer(3),
            ColorGroup = ColorOptions,
          }),
          -- %%%%%%%%%%%%%%%%
          -- Text font offset
          -- %%%%%%%%%%%%%%%%
          TextFontOffset = TriggerDisplayGroup(4, {OT.TextFontOffset}, {
            Animate = AnimateOptions,
            TextLine = TextLineOptions,
            Spacer3 = CreateSpacer(3),
            ColorGroup = ColorOptions,
            Par1 = { -- x
              type = 'range',
              name = 'Horizonal',
              order = 10,
              min = o.FontOffsetXMin,
              max = o.FontOffsetXMax,
              step = 1,
            },
            Par2 = { -- y
              type = 'range',
              name = 'Vertical',
              order = 11,
              min = o.FontOffsetYMin,
              max = o.FontOffsetYMax,
              step = 1,
            },
          }),
          -- %%%%%%%%%%%%%%
          -- Text font size
          -- %%%%%%%%%%%%%%
          TextFontSize = TriggerDisplayGroup(4, {OT.TextFontSize}, {
            Animate = AnimateOptions,
            TextLine = TextLineOptions,
            Spacer3 = CreateSpacer(3),
            Par1 = {
              type = 'range',
              name = 'Size',
              order = 10,
              min = o.TriggerFontSizeMin,
              max = o.TriggerFontSizeMax,
              step = 1,
              width = 'double',
            },
          }),
          -- %%%%%%%%%%%%%%
          -- Text font type
          -- %%%%%%%%%%%%%%
          TextFontType = TriggerDisplayGroup(4, {OT.TextFontType}, {
            TextLine = TextLineOptions,
            Spacer3 = CreateSpacer(3),
            Par1 = {
              type = 'select',
              name = 'Type',
              order = 10,
              dialogControl = 'LSM30_Font',
              values = LSMDropdown.Font,
            },
          }),
          -- %%%%%%%%%%%%%%%
          -- Text font style
          -- %%%%%%%%%%%%%%%
          TextFontStyle = TriggerDisplayGroup(4, {OT.TextFontStyle}, {
            TextLine = TextLineOptions,
            Spacer3 = CreateSpacer(3),
            Par1 = {
              type = 'select',
              name = 'Style',
              order = 10,
              style = 'dropdown',
              values = FontStyleDropdown,
            },
          }),
          -- %%%%%
          -- Sound
          -- %%%%%
          Sound = TriggerDisplayGroup(4, {OT.Sound}, {
            Par1 = {
              type = 'select',
              name = 'Sound',
              order = 10,
              width = 'double',
              dialogControl = 'LSM30_Sound',
              values = LSMDropdown.Sound,
            },
            Par2 = {
              type = 'select',
              name = 'Sound Channel',
              order = 11,
              style = 'dropdown',
              values = TriggerSoundChannelDropdown,
            },
          }),
        },
      },
    },
  }

  return DisplayOptions
end

-------------------------------------------------------------------------------
-- AddTriggerAuraOption
--
-- Subfunction of CreateTriggerAuraOptions()
--
-- Adds aura options for the trigger
--
-- UBF                     Unitbar Frame
-- BBar                    Table that contains the bar thats using this aura
-- AOA                     Aura Options Args
-- Auras                   Contains all the auras
-- Aura                    Current aura that these options will use
-------------------------------------------------------------------------------
local function AddTriggerAuraOption(UBF, BBar, AOA, Auras, Aura)
  local AuraGroup = 'AuraGroup' .. ToHex(Aura)

  AOA[AuraGroup] = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = function()
              return Aura.OrderNumber
            end,
    disabled = function()
                 return Auras.Disabled
               end,
    get = function(Info)
            local KeyName = Info[#Info]
            local Value = Aura[KeyName]

            if KeyName == 'SpellID' then
              Value = '' -- return blank on perpose
            elseif KeyName == 'Units' then
              Value = tconcat(Value, ' ')
            elseif KeyName == 'StackOperator' then
              Value = FindMenuItem(AuraStackOperatorDropdown, Aura.StackOperator)
            elseif KeyName == 'Stacks' then
              Value = tostring(Value)
            elseif KeyName == 'Own' then
              Value = Aura.Own ~= 0
            elseif KeyName == 'Type' then
              Value = Aura.Type ~= 0
            end

            return Value
          end,
    set = function(Info, Value, SpellID)
            local KeyName = Info[#Info]

            if KeyName == 'SpellID' then
              -- Escape was pressed. Cancel input
              if Value == -1 then
                return
              end
              Value = tonumber(Value) or SpellID
            elseif KeyName == 'Units' then
              Value = { Main:SplitString(' ', Value) }
            elseif KeyName == 'StackOperator' then
              Value = AuraStackOperatorDropdown[Value]
            elseif KeyName == 'Own' then
              Value = Aura.Own + 1
              if Value > 2 then
                Value = 0
              end
            elseif KeyName == 'Type' then
              Value = Aura.Type + 1
              if Value > 2 then
                Value = 0
              end
            end
            Aura[KeyName] = Value

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()
          end,
    args = {
      Header = {
        type = 'header',
        name = '',
        order = 1,
      },
      SpellName = {
        type = 'description',
        width = 'full',
        order = 2,
        dialogControl = 'GUB_Spell_Info',
        name = function()
                 local SpellID = Aura.SpellID
                 if SpellID > 0 then
                   local Name = C_Spell_GetSpellName(SpellID)
                   local Icon = C_Spell_GetSpellTexture(SpellID)

                   if Name == nil then
                     return format('%s:20:16:%s', 0, "Aura doesn't exist.  enter Spell ID or Spell Name")
                   else
                     return format('%s:20:16:(|cFF00FF00%s|r)', SpellID, SpellID)
                   end
                 else
                   return '16::|cFF00FF00MATCH ANY AURA|r or enter Spell ID or Spell Name'
                 end
               end,
      },
      MinimizeGroup = {
        type = 'group',
        name = '',
        dialogInline = true,
        order = 9,
        hidden = function()
                   return Aura.Minimized
                 end,
        args = {
          SpellID = {
            type = 'input',
            name = 'Aura: Escape to cancel entry',
            desc = 'Enter nothing to look for any aura',
            order = 10,
            dialogControl = 'GUB_Aura_EditBox',
          },
          Own = {
            type = 'toggle',
            name = function()
                     local Own = Aura.Own

                     return Own <= 1 and 'Own' or 'Not Own'
                   end,
            desc = function()
                     local Own = Aura.Own
                     local St

                     if Own == 0 then
                       St = 'If checked, then this aura must be cast by you'
                     elseif Own == 1 then
                       St = 'This aura must be cast by you'
                     else
                       St = 'This aura can only be cast from someone else'
                     end

                     return '|C0000ff00Multi-state Toggle|r (Own, Not Own) \n' .. St
                   end,
            order = 11,
            width = 'half',
          },
          Type = {
            type = 'toggle',
            name = function()
                     local Type = Aura.Type

                     return Type <= 1 and 'Buff' or 'Debuff'
                   end,
            desc = function()
                     local Type = Aura.Type
                     local St = ''

                     if Type == 0 then
                       St = 'If checked, then this aura can only be a buff'
                     elseif Type == 1 then
                       St = 'This aura can only be a buff'
                     elseif Type == 2 then
                       St = 'This aura can only be a debuff'
                     end

                     return '|C0000ff00Multi-state Toggle|r (Buff, Debuff) \n' .. St
                   end,
            order = 12,
            width = 'half',
          },
          Inverse = {
            type = 'toggle',
            name = 'Inverse',
            desc = 'If checked, then the aura matching is reversed',
            order = 13,
            width = 'half',
          },
          Spacer20 = CreateSpacer(20),
          Units = {
            type = 'input',
            name = 'Units  ( separated by space )',
            order = 21,
          },
          StackOperator = {
            type = 'select',
            name = 'Operator',
            width = 'half',
            order = 22,
            values = AuraStackOperatorDropdown,
          },
          Stacks = {
            type = 'input',
            name = 'Stacks',
            width = 'half',
            order = 23,
          },
          Spacer30 = CreateSpacer(30),
          CheckDebuffTypes = {
            type = 'toggle',
            name = 'Check Debuff Types',
            order = 31,
            hidden = function()
                       return Aura.Type == 1
                     end,
          },
          CheckDebuffTypesSelect = {
            type = 'multiselect',
            name = 'Debuff Types',
            order = 32,
            --dialogControl = 'Dropdown',
            values = DebuffTypesDropdown,
            width = 'half',
            hidden = function()
                       return not Aura.CheckDebuffTypes or Aura.Type == 1
                     end,
            get = function(Info, Index)
                    return Aura[ DebuffTypesDropdown[Index] ]
                  end,
            set = function(Info, Value, Active)
                    Aura[ DebuffTypesDropdown[Value] ] = Active

                    -- Update bar to reflect trigger changes
                    BBar:CheckTriggers()
                    UBF:Update()
                    BBar:Display()
                  end,
          },
        },
      },
      Minimize = {
        type = 'execute',
        width = 'half',
        order = 10,
        name = function()
                 if Aura.Minimized then
                   return 'Expand'
                 else
                   return 'Collapse'
                 end
               end,
        func = function()
                 Aura.Minimized = not Aura.Minimized
               end,
      },
      Add = {
        type = 'execute',
        name = function()
                 if Aura.OrderNumber < #Auras then
                   return 'Insert'
                 else
                   return 'Add'
                 end
               end,
        order = 11,
        width = 'half',
        func = function()
                 local Index = Aura.OrderNumber
                 local Aura = {}

                 Main:CopyTableValues(DefaultUB.TriggerAurasArray, Aura, true)
                 tinsert(Auras, Index + 1, Aura)

                 BBar:CheckTriggers()
                 AddTriggerAuraOption(UBF, BBar, AOA, Auras, Aura)

                 -- Update bar to reflect trigger changes
                 UBF:Update()
                 BBar:Display()
               end,
      },
      Up = {
        type = 'execute',
        name = 'Up',
        order = 12,
        width = 'half',
        hidden = function()
                   return Aura.OrderNumber == 1
                 end,
        func = function()
                 local Index = Aura.OrderNumber

                 Auras[Index], Auras[Index - 1] = Auras[Index - 1], Auras[Index]

                 -- Update bar to reflect trigger changes
                 BBar:CheckTriggers()
                 UBF:Update()
                 BBar:Display()
               end
      },
      Down = {
        type = 'execute',
        name = 'Down',
        order = 13,
        width = 'half',
        hidden = function()
                   return Aura.OrderNumber == #Auras
                 end,
        func = function()
                 local Index = Aura.OrderNumber

                 Auras[Index], Auras[Index + 1] = Auras[Index + 1], Auras[Index]

                 -- Update bar to reflect trigger changes
                 BBar:CheckTriggers()
                 UBF:Update()
                 BBar:Display()
               end
      },
      Spacer14 = CreateSpacer(14, 'half'),
      Spacer15 = CreateSpacer(15, 'half', function()
                                            local Index = Aura.OrderNumber
                                            return Index > 1 and Index < #Auras
                                          end),
      Delete = {
        type = 'execute',
        name = 'Delete',
        order = 16,
        width = 'half',
        confirm = function()
                    if not IsModifierKeyDown() then
                      return 'Are you sure you want to delete this aura?\n Hold a modifier key down and click delete to bypass this warning'
                    end
                  end,
        func = function()
                 tremove(Auras, Aura.OrderNumber)

                 -- Delete this option
                 AOA[AuraGroup] = nil

                 -- Update bar to reflect trigger changes
                 BBar:CheckTriggers()
                 UBF:Update()
                 BBar:Display()

                 HideTooltip(true)
               end
      },
    },
  }
end

-------------------------------------------------------------------------------
-- CreateTriggerAuraOptions
--
-- Subfunction of CreateTriggerOptions()
--
-- Create dynamic options that can be add and remove auras
--
-- Order     Position in the options
-- UBF       Unitbar Frame
-- BBar      Table that contains the bar thats using this trigger
-- Trigger  Current trigger being modified
-------------------------------------------------------------------------------
local function CreateTriggerAuraOptions(Order, UBF, BBar, Trigger)
  local Auras = Trigger.Auras

  local AuraOptions = {
    type = 'group',
    name = 'Auras',
    order = Order,
    get = function(Info)
            local KeyName = Info[#Info]

            return Auras[KeyName]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            Auras[KeyName] = Value

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()
          end,
    args = {},
  }

  local AOA = AuraOptions.args

  AOA.Disabled = {
    type = 'toggle',
    name = 'Disable',
    order = 0.1,
  }
  AOA.All = {
    type = 'toggle',
    name = 'All',
    width = 'half',
    desc = 'If checked, then all auras must be found. \nIf All then all units must match per aura',
    order = 0.2,
  }
  AOA.Add = {
    type = 'execute',
    name = 'Add',
    width = 'half',
    hidden = function()
               return #Auras > 0
             end,
    disabled = function()
                 return Auras.Disabled
               end,
    func = function()
             local Aura = {}

             Main:CopyTableValues(DefaultUB.TriggerAurasArray, Aura, true)
             Auras[1] = Aura

             -- Update bar to reflect trigger changes
             BBar:CheckTriggers()
             UBF:Update()
             BBar:Display()

             AddTriggerAuraOption(UBF, BBar, AOA, Auras, Aura)
           end,
  }

  for Index = 1, #Auras do
    AddTriggerAuraOption(UBF, BBar, AOA, Auras, Auras[Index])
  end

  return AuraOptions
end

-------------------------------------------------------------------------------
-- AddTriggerConditionOption
--
-- Subfunction of CreateTriggerConditionOptions()
--
-- Adds condition options for the trigger
--
-- UBF                         Unitbar Frame
-- BBar                        Table that contains the bar thats using this condition
-- COA                         Condition Option Args
-- InputValueNamesDropdown     Menu to select which input name to use
-- InputValueTypes             Contains the value type for each input name
-- Conditions                  Contains all the conditions
-- Condition                   Current condition that these options will use
-------------------------------------------------------------------------------
local function AddTriggerConditionOption(UBF, BBar, COA, Conditions, Condition)
  local ConditionGroup = 'ConditionGroup' .. ToHex(Condition)
  local TriggerData = BBar.TriggerData
  local InputValueNamesDropdown = TriggerData.InputValueNamesDropdown
  local InputValueTypes = TriggerData.InputValueTypes
  local InputValueType

  COA[ConditionGroup] = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = function()
              return Condition.OrderNumber
            end,
    disabled = function()
                 return Conditions.Disabled
               end,
    get = function(Info)
            local KeyName = Info[#Info]
            local Value = Condition[KeyName]

            if KeyName == 'InputValueName' then
              local InputValueName = Condition.InputValueName
              Value = FindMenuItem(InputValueNamesDropdown, InputValueName)

              InputValueName = InputValueNamesDropdown[Value]
              InputValueType = InputValueTypes[InputValueName]
            elseif KeyName == 'Operator' then
              Value = FindMenuItem(TriggerOperatorDropdown[InputValueType], Condition.Operator)
            elseif KeyName == 'Value' then
              Value = tostring(Value)
            end

            return Value
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            if KeyName == 'InputValueName' then
              Value = InputValueNamesDropdown[Value]
            elseif KeyName == 'Operator' then
              Value = TriggerOperatorDropdown[InputValueType][Value]
            end
            Condition[KeyName] = Value

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()
          end,
    args = {
      Header = {
        type = 'header',
        name = '',
        order = 10,
      },
      InputValueName = {
        type = 'select',
        name = 'Input Value Name',
        order = 20,
        values = InputValueNamesDropdown,
        style = 'dropdown',
      },
      Operator = {
        type = 'select',
        name = 'Operator',
        width = 'half',
        order = 21,
        hidden = function()
                   return InputValueType == 'state'
                 end,
        values = function()
                   return TriggerOperatorDropdown[InputValueType]
                 end,
      },
      Value = {
        type = 'input',
        name = function()
                 return format('Value (%s)', InputValueType or '')
               end,
        order = 22,
        hidden = function()
                   return InputValueType ~= 'whole' and
                          InputValueType ~= 'decimal' and
                          InputValueType ~= 'percent' and
                          InputValueType ~= 'text'
                 end,
      },
      State = {
        type = 'select',
        name = 'Value (state)',
        order = 23,
        hidden = function()
                   return InputValueType ~= 'state'
                 end,
        values = TriggerStateValueDropdown,
        get = function()
                local Value = Condition.Value
                Value = Value and 1 or 2

                return Value
              end,
        set = function(Info, Value)
                Condition.Value = Value == 1 and true or false

                -- Update bar to reflect trigger changes
                BBar:CheckTriggers()
                UBF:Update()
                BBar:Display()
              end,
      },
      Spacer40 = CreateSpacer(40),
      Add = {
        type = 'execute',
        name = function()
                 if Condition.OrderNumber < #Conditions then
                   return 'Insert'
                 else
                   return 'Add'
                 end
               end,
        order = 41,
        width = 'half',
        func = function()
                 local Index = Condition.OrderNumber
                 local Condition = {}

                 Main:CopyTableValues(DefaultUB.TriggerConditionsArray, Condition, true)
                 tinsert(Conditions, Index + 1, Condition)

                 BBar:CheckTriggers()
                 AddTriggerConditionOption(UBF, BBar, COA, Conditions, Condition)

                 -- Update bar to reflect trigger changes
                 UBF:Update()
                 BBar:Display()
               end,
      },
      Up = {
        type = 'execute',
        name = 'Up',
        order = 42,
        width = 'half',
        hidden = function()
                   return Condition.OrderNumber == 1
                 end,
        func = function()
                 local Index = Condition.OrderNumber

                 Conditions[Index], Conditions[Index - 1] = Conditions[Index - 1], Conditions[Index]

                 -- Update bar to reflect trigger changes
                 BBar:CheckTriggers()
                 UBF:Update()
                 BBar:Display()
               end
      },
      Down = {
        type = 'execute',
        name = 'Down',
        order = 43,
        width = 'half',
        hidden = function()
                   return Condition.OrderNumber == #Conditions
                 end,
        func = function()
                 local Index = Condition.OrderNumber

                 Conditions[Index], Conditions[Index + 1] = Conditions[Index + 1], Conditions[Index]

                 -- Update bar to reflect trigger changes
                 BBar:CheckTriggers()
                 UBF:Update()
                 BBar:Display()
               end
      },
      Spacer14 = CreateSpacer(44, 'half'),
      Spacer15 = CreateSpacer(45, 'half', function()
                                            local Index = Condition.OrderNumber
                                            return Index > 1 and Index < #Conditions
                                          end),
      Delete = {
        type = 'execute',
        name = 'Delete',
        order = 46,
        width = 'half',
        confirm = function()
                    if not IsModifierKeyDown() then
                      return 'Are you sure you want to delete this condition?\n Hold a modifier key down and click delete to bypass this warning'
                    end
                  end,
        func = function()
                 tremove(Conditions, Condition.OrderNumber)

                 -- Delete this option
                 COA[ConditionGroup] = nil

                 -- Update bar to reflect trigger changes
                 BBar:CheckTriggers()
                 UBF:Update()
                 BBar:Display()

                 HideTooltip(true)
               end
      },
    },
  }
end

-------------------------------------------------------------------------------
-- CreateTriggerConditionOptions
--
-- Creates dynamic options that can add and remove conditions
--
-- Subfunction of CreateTriggerOptions()
--
-- Order     Position in the options
-- UBF       Unitbar Frame
-- BBar      Table that contains the bar thats using this trigger
-- Trigger   Current trigger being modified
-------------------------------------------------------------------------------
local function CreateTriggerConditionOptions(Order, UBF, BBar, Trigger)
  local Conditions = Trigger.Conditions

  local ConditionOptions = {
    type = 'group',
    name = 'Conditions',
    order = Order,
    get = function(Info)
            local KeyName = Info[#Info]

            return Conditions[KeyName]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            Conditions[KeyName] = Value

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()
          end,
    args = {},
  }

  local COA = ConditionOptions.args

  COA.Disabled = {
    type = 'toggle',
    name = 'Disable',
    order = 0.1,
  }
  COA.All = {
    type = 'toggle',
    name = 'All',
    width = 'half',
    desc = 'If checked, then all conditions must be true',
    order = 0.2,
  }
  COA.Add = {
    type = 'execute',
    name = 'Add',
    width = 'half',
    order = 1,
    hidden = function()

               return #Conditions > 0
             end,
    disabled = function()
                 return Conditions.Disabled
               end,
    func = function()
             local Condition = {}

             Main:CopyTableValues(DefaultUB.TriggerConditionsArray, Condition, true)
             Conditions[1] = Condition

             -- Update bar to reflect trigger changes
             BBar:CheckTriggers()
             UBF:Update()
             BBar:Display()

             AddTriggerConditionOption(UBF, BBar, COA, Conditions, Condition)
           end,
  }

  for Index = 1, #Conditions do
    AddTriggerConditionOption(UBF, BBar, COA, Conditions, Conditions[Index])
  end

  return ConditionOptions
end

-------------------------------------------------------------------------------
-- AddTriggerTalentOption
--
-- Subfunction of CreateTriggerTalentOptions()
--
-- Adds talent options for this trigger
--
-- UBF                       Unitbar frame
-- BBar                      Table that contains the bar thats using these talents
-- TOA                       Talent Option Args
-- Talents                   Contains all the talents
-- Talent                    Current talent that these options will use
-------------------------------------------------------------------------------
local function AddTriggerTalentOption(UBF, BBar, TOA, Talents, Talent)
  local TalentGroup = 'TalentGroup' .. ToHex(Talent)
  local TalentTrackersData = Main.TalentTrackersData
  local SpellIDs = TalentTrackersData.SpellIDs
  local TalentIsPvP = Main.TalentTrackersData.TalentIsPvP
  local PvEDropdown = TalentTrackersData.PvEDropdown
  local PvEIconDropdown = TalentTrackersData.PvEIconDropdown
  local PvENotUseDropdown = TalentTrackersData.PvENotUseDropdown
  local PvENotUseIconDropdown = TalentTrackersData.PvENotUseIconDropdown
  local PvPDropdown = TalentTrackersData.PvPDropdown
  local PvPIconDropdown = TalentTrackersData.PvPIconDropdown

  TOA[TalentGroup] = {
    type = 'group',
    name = '',
    dialogInline = true,
    order = function()
              return Talent.OrderNumber
            end,
    disabled = function()
                 return Talents.Disabled
               end,
    get = function(Info)
            if Info[#Info] == 'Match' then
              return Talent.Match
            end
            return
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local Dropdown

            if KeyName == 'Match' then
              Talent.Match = Value
            else
              if KeyName == 'TalentName' then
                Dropdown = PvEDropdown
              elseif KeyName == 'TalentNameNotUse' then
                Dropdown = PvENotUseDropdown
              else
                Dropdown = PvPDropdown
              end
              local TalentName = Dropdown[Value]
              local SpellID = SpellIDs[TalentName] or 0

              Talent.SpellID = SpellID
              Talent.IsPvP = TalentIsPvP[SpellID]
            end

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()
          end,
    args = {
      Header = {
        type = 'header',
        name = '',
        order = 10,
      },
      TalentNameSelected = {
        type = 'description',
        width = 'full',
        order = 11,
        dialogControl = 'GUB_Spell_Info',
        get = function() end,
        set = function() end,
        name = function()
                 local SpellID = Talent.SpellID or 0
                 local IsPvP = Talent.IsPvP and '(PvP)' or ''
                 local Match = Talent.Match and '(Match)' or "(Can't Match)"

                 if SpellID == 0 then
                   return format('%s:20:16:%s', 0, 'No talent selected. Pick one from the pulldowns below')
                 elseif type(SpellID) == 'string' then
                   return format('0:20:16: %s (log into character to finish convert)', SpellID)
                 else
                   return format('%s:20:16: %s %s', SpellID, IsPvP, Match)
                 end
               end,
      },
      MinimizeGroup = {
        type = 'group',
        name = '',
        dialogInline = true,
        order = 20,
        hidden = function()
                   return Talent.Minimized
                 end,
        args = {
          TalentName = {
            type = 'select',
            dialogControl = 'GUB_Dropdown_Select',
            name = 'Talent Name:normal',
            order = 1,
            values = function()
                       return PvEIconDropdown
                     end,
          },
          TalentNameNotUse = {
            type = 'select',
            dialogControl = 'GUB_Dropdown_Select',
            name = 'Talent Name (not in use):normal',
            order = 2,
            values = function()
                       return PvENotUseIconDropdown
                     end,
          },
          TalentNamePvP = {
            type = 'select',
            dialogControl = 'GUB_Dropdown_Select',
            name = 'Talent Name (PvP):normal',
            order = 3,
            values = function()
                       return PvPIconDropdown
                     end,
          },
          Match = {
            type = 'toggle',
            name = 'Match',
            desc = "If unchecked, then the talent can't match",
            order = 4,
          },
        },
      },
      Minimize = {
        type = 'execute',
        width = 'half',
        order = 40,
        name = function()
                 if Talent.Minimized then
                   return 'Expand'
                 else
                   return 'Collapse'
                 end
               end,
        func = function()
                 Talent.Minimized = not Talent.Minimized
               end,
      },
      Add = {
        type = 'execute',
        name = function()
                 if Talent.OrderNumber < #Talents then
                   return 'Insert'
                 else
                   return 'Add'
                 end
               end,
        order = 41,
        width = 'half',
        func = function()
                 local Index = Talent.OrderNumber
                 local Talent = {}

                 Main:CopyTableValues(DefaultUB.TriggerTalentsArray, Talent, true)
                 tinsert(Talents, Index + 1, Talent)

                 BBar:CheckTriggers()
                 AddTriggerTalentOption(UBF, BBar, TOA, Talents, Talent)

                 -- Update bar to reflect trigger changes
                 UBF:Update()
                 BBar:Display()
               end,
      },
      Up = {
        type = 'execute',
        name = 'Up',
        order = 42,
        width = 'half',
        hidden = function()
                   return Talent.OrderNumber == 1
                 end,
        func = function()
                 local Index = Talent.OrderNumber

                 Talents[Index], Talents[Index - 1] = Talents[Index - 1], Talents[Index]

                 -- Update bar to reflect trigger changes
                 BBar:CheckTriggers()
                 UBF:Update()
                 BBar:Display()
               end
      },
      Down = {
        type = 'execute',
        name = 'Down',
        order = 43,
        width = 'half',
        hidden = function()
                   return Talent.OrderNumber == #Talents
                 end,
        func = function()
                 local Index = Talent.OrderNumber

                 Talents[Index], Talents[Index + 1] = Talents[Index + 1], Talents[Index]

                 -- Update bar to reflect trigger changes
                 BBar:CheckTriggers()
                 UBF:Update()
                 BBar:Display()
               end
      },
      Spacer45 = CreateSpacer(45, 'half', function()
                                            local Index = Talent.OrderNumber
                                            return Index > 1 and Index < #Talents
                                          end),
      Delete = {
        type = 'execute',
        name = 'Delete',
        order = 46,
        width = 'half',
        confirm = function()
                    if not IsModifierKeyDown() then
                      return 'Are you sure you want to delete this talent?\n Hold a modifier key down and click delete to bypass this warning'
                    end
                  end,
        func = function()
                 tremove(Talents, Talent.OrderNumber)

                 -- Delete this option
                 TOA[TalentGroup] = nil

                 -- Update bar to reflect trigger changes
                 BBar:CheckTriggers()
                 UBF:Update()
                 BBar:Display()

                 HideTooltip(true)
               end
      },
    },
  }
end

-------------------------------------------------------------------------------
-- CreateTriggerTalentOptions
--
-- Createsa  dynamic options that can add remove talents
--
-- Subfunction of CreateTriggerOptions()
--
-- Order     Position in the options
-- UBF       Unitbar frame
-- BBar      Table that contains the bar thats using this trigger
-- Trigger   Current trigger being modified
-------------------------------------------------------------------------------
local function CreateTriggerTalentOptions(Order, UBF, BBar, Trigger)
  local Talents = Trigger.Talents

  local TalentOptions = {
    type = 'group',
    name = 'Talents',
    order = Order,
    get = function(Info)
            local KeyName = Info[#Info]

            return Talents[KeyName]
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]

            Talents[KeyName] = Value

            -- Update bar to reflect trigger changes
            BBar:CheckTriggers()
            UBF:Update()
            BBar:Display()
          end,
    args = {},
  }

  local TOA = TalentOptions.args

  TOA.Disabled = {
    type = 'toggle',
    name = 'Disable',
    order = 0.1,
  }
  TOA.All = {
    type = 'toggle',
    name = 'All',
    width = 'half',
    desc = 'If checked, then all talents must be active',
    order = 0.2,
  }
  TOA.Add = {
    type = 'execute',
    name = 'Add',
    width = 'half',
    order = 1,
    hidden = function()
               return #Talents > 0
             end,
    disabled = function()
                 return Talents.Disabled
               end,
    func = function()
             local Talent = {}

             Main:CopyTableValues(DefaultUB.TriggerTalentsArray, Talent, true)
             Talents[1] = Talent

             -- Update bar to reflect changes
             BBar:CheckTriggers()
             UBF:Update()
             BBar:Display()

             AddTriggerTalentOption(UBF, BBar, TOA, Talents, Talent)
           end,
  }

  for Index = 1, #Talents do
    AddTriggerTalentOption(UBF, BBar, TOA, Talents, Talents[Index])
  end

  return TalentOptions
end

-------------------------------------------------------------------------------
-- RemoveTriggerTabOptions
--
-- Deletes all tab options no longer being used
--
-- SubFunction of EditTriggerListOptions()
--
-- TOA        TriggerOptionsArgs
-- Triggers   Triggers are used to see which options to delete
-------------------------------------------------------------------------------
local function RemoveTriggerTabOptions(TOA, Triggers)
  local TriggersHex = {}

  for TriggerIndex = 1, #Triggers do
    TriggersHex[ToHex(Triggers[TriggerIndex])] = 1
  end

  -- Remove options not being used anymore
  for Key in pairs(TOA) do
    if strfind(Key, 'Activate') or strfind(Key, 'Display') then
      local _, TriggerHex = strsplit(':', Key)

      -- Delete only if trigger doesn't exist
      if TriggersHex[TriggerHex] == nil then
        TOA[Key] = nil
      end
    end
  end
end

-------------------------------------------------------------------------------
-- CreateTriggerTabOptions
--
-- SubFunction of CreateTriggerOptions()
--
-- Creates the tabs that appear after trigger list tab
--
-- BarType      Current bar this trigger belongs to
-- UBF          Unitbar Frame
-- BBar         Bar object
-- TOA          Trigger Options args
-- Trigger      Current Trigger these options belong to
-- EditList     See EditTriggerListOptions()
-------------------------------------------------------------------------------
local function CreateTriggerTabOptions(BarType, UBF, BBar, TOA, Trigger, EditList)
  local Hex = {}
  local HexSt = ToHex(Hex)
  local Activate = 'Activate' .. HexSt .. ':' .. ToHex(Trigger)
  local Display = 'Display' .. HexSt .. ':' .. ToHex(Trigger)

  local TriggerData = BBar.TriggerData
  local GroupsDropdown = TriggerData.GroupsDropdown
  local Groups = TriggerData.Groups

  -- Activate tab
  TOA[Activate] = {
    type = 'group',
    name = 'Activate',
    order = 100,
    childGroups = 'tab',
    hidden = function()
               return EditList.Edit ~= nil or Trigger ~= EditList.Trigger
             end,
    disabled = function()
                 return Trigger.Disabled or Trigger.Static
               end,
    args = {
      -- Specialization
      SpecTab = {
        type = 'group',
        name = 'Specialization',
        order = 1,
        args = {
          SpecEnabled = {
            type = 'toggle',
            name = 'Enable',
            order = 1,
            get = function()
                    return Trigger.SpecEnabled
                  end,
            set = function(Info, Value)
                    Trigger.SpecEnabled = Value

                    -- Update bar to reflect trigger changes
                    BBar:CheckTriggers()
                    UBF:Update()
                    BBar:Display()
                  end,
          },
          Header = {
            type = 'header',
            name = '',
            order = 2,
          },
          SpecOptions = CreateSpecOptions(BarType, 3, Trigger.ClassSpecs, BBar, function() return not Trigger.SpecEnabled end),
        },
      },

      -- Stances
      StancesTab = {
        type = 'group',
        name = 'Stances',
        order = 2,
        disabled = function()
                     return next(DUB[BarType].Triggers.Default.ClassStances) == nil
                   end,
        args = {
          StanceEnabled = {
            type = 'toggle',
            name = 'Enable',
            order = 1,
            get = function()
                    return Trigger.StanceEnabled
                  end,
            set = function(Info, Value)
                    Trigger.StanceEnabled = Value

                    -- Update bar to reflect trigger changes
                    BBar:CheckTriggers()
                    UBF:Update()
                    BBar:Display()
                  end,
          },
          Header = {
            type = 'header',
            name = '',
            order = 2,
          },
          StanceOptions = CreateStanceOptions(BarType, 3, Trigger.ClassStances, BBar, function() return not Trigger.StanceEnabled end),
        },
      },

      -- Talents
      TalentOptions = CreateTriggerTalentOptions(2, UBF, BBar, Trigger),

      -- Auras
      AuraOptions = CreateTriggerAuraOptions(3, UBF, BBar, Trigger),

      -- Conditions
      ConditionOptions = CreateTriggerConditionOptions(4, UBF, BBar, Trigger),
    },
  }

  TOA[Display] = {
    type = 'group',
    name = function()
             local Group = Groups[Trigger.GroupNumber]
             local Index = Group.Objects[Trigger.ObjectTypeID].Index

             return format('Display ( %s )  ( %s )', GroupsDropdown[Trigger.GroupNumber],
                                                    Group.ObjectsDropdown[Index]         )
           end,
    order = 101,
    hidden = function()
               return EditList.Edit ~= nil or Trigger ~= EditList.Trigger
             end,
    disabled = function()
                 return Trigger.Disabled
               end,
    args = {
      DisplayOptions = CreateTriggerDisplayOptions(1, UBF, BBar, Trigger),
    }
  }
end

-------------------------------------------------------------------------------
-- SelectEditList
--
-- Selects a position in the edit list tree
--
-- Subfunction of EditTriggerListOptions()
--
-- BarType    Bar the editlist is in
-- Order      Order number to select in the tree
-- TLA        Tree to search to find the position
-------------------------------------------------------------------------------
local function SelectEditList(BarType, Order, TLA)
  local OrderList = {}

  for Key in pairs(TLA) do
    local OptionTable = TLA[Key]

    OrderList[OptionTable.order] = Key
  end

  local Key
  if OrderList[Order] then
    Key = OrderList[Order]
  else
    Key = OrderList[#OrderList]
  end

  AceConfigDialog:SelectGroup(AddonMainOptions, 'UnitBars', 'Triggers' .. BarType, 'List', Key)
end

-------------------------------------------------------------------------------
-- EditTriggerListOptions
--
-- Updates the trigger list depending on what type of editing is being applied
--
-- Subfunction of CreateTriggerOptions()
--
-- BarType           Current bar this trigger belongs to
-- UBF               Unitbar frame to access the bar functions.
-- BBar              The bar object to access the bar DB functions.
-- Action            'list'   Show the current trigger list
--                   'add'    Adds a new trigger copied from defaults
--                   'copy'   Copies one trigger to a new index location
--                   'move'   Moves one trigger to another index location
--                   'swap'   Swaps two triggers with each others index location
-- TLA               TriggerListArgs
-- TOA               TriggerOptionsArgs
-- Triggers          Array containing all the triggers
-- EditList            For copy, move, swap, etc
--   Trigger           Current trigger table selected
--   Index             Current selected trigger
-- SaveMenuKey       Don't delete the menu entry that matches this
-------------------------------------------------------------------------------
local function EditTriggerListOptions(BarType, UBF, BBar, Action, TLA, TOA, Triggers, EditList, SaveMenuKey)

  -- Refresh if there are no triggers
  if #Triggers == 0 then
    EditList.Edit = true
    Options:RefreshMainOptions()
  end

  if Action == 'list' then

    wipe(EditList)
    -- Delete all menu entries except the SaveMenuKey
    for MenuKey, TriggerListArgs in pairs(TLA) do
      if MenuKey ~= SaveMenuKey then
        TLA[MenuKey] = nil
      end
    end

    -- Create menu list
    for TriggerIndex, Trigger in ipairs(Triggers) do
      local MenuKey = ToHex(Trigger)

      TLA[MenuKey] = {
        type = 'group',
        name = function()
                 local Color
                 local Name = TriggerTypeToIcon(Trigger.ObjectType, 14) .. ' ' .. Trigger.Name or ''
                 if Trigger.Disabled then
                   Color = 'ffdbdbdb'
                 elseif Trigger.Static then
                   Color = 'ff00f700'
                 end
                 if Color then
                   return format('|c%s%s|r', Color, Name)
                 else
                   return Name
                 end
               end,
        order = TriggerIndex,
        disabled = function()
                     EditList.Trigger = Trigger
                     EditList.Index = TriggerIndex

                     -- Refresh here so name field and tabs can update
                     Options:RefreshMainOptions()

                     return Action ~= 'list'
                   end,
        get = function(Info)
                local KeyName = Info[#Info]

                return Trigger[KeyName]
              end,
        set = function(Info, Value)
                local KeyName = Info[#Info]

                Trigger[KeyName] = Value

                -- update the bar
                BBar:CheckTriggers()
                UBF:Update()
                BBar:Display()
              end,
        args = {
          Static = {
            type = 'toggle',
            name = 'Static',
            order = 1,
            width = 'half',
            desc = 'Click to make the trigger always on',
          },
          Disabled = {
            type = 'toggle',
            name = 'Disable',
            order = 2,
            width = 'half',
            desc = 'If checked, this trigger will no longer function',
          },
          Header10 = {
            type = 'header',
            name = '',
            order = 10,
          },
          Add = {
            type = 'execute',
            name = 'Add',
            order = 11,
            width = 'half',
            func = function()
                     Action = 'add'
                     EditList.Edit = true
                     EditTriggerListOptions(BarType, UBF, BBar, 'add', TLA, TOA, Triggers, EditList)
            end,
          },
          Copy = {
            type = 'execute',
            name = 'Copy',
            order = 12,
            width = 'half',
            func = function()
                     Action = 'copy'
                     EditList.Edit = true
                     EditTriggerListOptions(BarType, UBF, BBar, 'copy', TLA, TOA, Triggers, EditList)
                   end,
          },
          Move = {
            type = 'execute',
            name = 'Move',
            order = 13,
            width = 'half',
            func = function()
                     Action = 'move'
                     EditList.Edit = true
                     EditTriggerListOptions(BarType, UBF, BBar, 'move', TLA, TOA, Triggers, EditList)
                   end,
          },
          Swap = {
            type = 'execute',
            name = 'Swap',
            order = 14,
            width = 'half',
            func = function()
                     Action = 'swap'
                     EditList.Edit = true
                     EditTriggerListOptions(BarType, UBF, BBar, 'swap', TLA, TOA, Triggers, EditList)
                   end
          },
          Header20 = {
            type = 'header',
            name = '',
            order = 20,
          },
          Delete = {
            type = 'execute',
            name = 'Delete',
            order = 21,
            width = 'half',
            confirm = function()
                        if not IsModifierKeyDown() then
                          return 'Are you sure you want to delete this trigger?\n Hold a modifier key down and click delete to bypass this warning'
                        end
                      end,
            func = function()
                     BBar:UndoTriggers()
                     tremove(Triggers, TriggerIndex)

                     if #Triggers == 0 then
                       TLA[MenuKey] = nil
                       Action = 'add'
                     else
                       Action = 'list'
                     end
                     EditTriggerListOptions(BarType, UBF, BBar, Action, TLA, TOA, Triggers, EditList)

                     -- Delete tab options
                     RemoveTriggerTabOptions(TOA, Triggers)

                     -- Select the new trigger list position
                     if #Triggers > 0 then
                       SelectEditList(BarType, TriggerIndex, TLA)
                     end

                     -- update the bar
                     BBar:CheckTriggers()
                     UBF:Update()
                     BBar:Display()
                   end,
          },
          Cancel = {
            type = 'execute',
            name = 'Cancel',
            order = 100,
            width = 'half',
            disabled = function()
                         return Action == 'list'
                       end,
            func = function()
                     EditTriggerListOptions(BarType, UBF, BBar, 'list', TLA, TOA, Triggers, EditList)
                   end,
          },
          Header200 = {
            type = 'header',
            name = '',
            order = 200,
          },
          Import = {
            type = 'execute',
            name = 'Import',
            order = 201,
            width = 'half',
            func = function()
                     Options.Importing = true
                     Options.ImportSourceBarType = BarType
                   end,
          },
          Export = {
            type = 'execute',
            name = 'Export',
            desc = 'Export the selected trigger',
            order = 202,
            width = 'half',
            func = function()
                     local Trigger = EditList.Trigger
                     Options.Exporting = true
                     Options.ExportData = Main:ExportTableString(BarType, 'trigger', 'Trigger', Trigger.Name, Trigger)
                   end,
          },
          ExportAll = {
            type = 'execute',
            name = 'Export All',
            desc = 'Export all the triggers',
            order = 203,
            width = 'normal',
            func = function()
                     Options.Exporting = true
                     Options.ExportData = Main:ExportTableString(BarType, 'alltriggers', 'All Triggers', '', Triggers)
                   end,
          },
        },
      }
    end
  else
    -- Create edit menu list
    for TriggerIndex = 1, #Triggers + 1 do
      local NewTrigger = {}
      local MenuKey = ToHex(NewTrigger)

      if Action == 'swap' and TriggerIndex > 1 or Action ~= 'swap' then
        TLA[MenuKey] = {
          type = 'group',
          name = format('    <%s here>', Action),
          order = TriggerIndex - 0.5,
          args = {
            Paste = {
              type = 'execute',
              name = strupper(strsub(Action, 1, 1)) .. strsub(Action, 2),
              order = 10,
              width = 'half',
              func = function()
                       if Action == 'add' then
                         Main:CopyTableValues(DUB[UBF.BarType].Triggers.Default, NewTrigger, true)
                         NewTrigger.Name = 'Trigger'
                         tinsert(Triggers, TriggerIndex, NewTrigger)

                       elseif Action == 'copy' then
                         Main:CopyTableValues(EditList.Trigger, NewTrigger, true)

                         NewTrigger.Name = 'Copy ' .. NewTrigger.Name
                         tinsert(Triggers, TriggerIndex, NewTrigger)

                       elseif Action == 'move' then
                         local EditListIndex = EditList.Index

                         Main:CopyTableValues(EditList.Trigger, NewTrigger, true)
                         tinsert(Triggers, TriggerIndex, NewTrigger)

                         -- Check if EditList index has to be offset by 1.
                         if TriggerIndex <= EditListIndex then
                           EditListIndex = EditListIndex + 1
                         end
                         tremove(Triggers, EditListIndex)

                       elseif Action == 'swap' then
                         local EditListTrigger = EditList.Trigger

                         -- Do it this way so menu tree selection doesn't move
                         Main:CopyTableValues(EditListTrigger, NewTrigger, true)
                         EditListTrigger = {}
                         Main:CopyTableValues(Triggers[TriggerIndex - 1], EditListTrigger, true)
                         Triggers[TriggerIndex - 1] = NewTrigger
                         Triggers[EditList.Index] = EditListTrigger

                         -- Create a new tab for the Selected
                         CreateTriggerTabOptions(BarType, UBF, BBar, TOA, EditListTrigger, EditList)

                         MenuKey = nil
                       end
                       -- Do this here before options updating
                       BBar:CheckTriggers()

                       -- Create tab options for new trigger
                       CreateTriggerTabOptions(BarType, UBF, BBar, TOA, NewTrigger, EditList)

                       EditTriggerListOptions(BarType, UBF, BBar, 'list', TLA, TOA, Triggers, EditList, MenuKey)

                       -- Delete tab options
                       RemoveTriggerTabOptions(TOA, Triggers)

                       -- update the bar
                       UBF:Update()
                       BBar:Display()
                     end
            },
            Cancel = {
              type = 'execute',
              name = 'Cancel',
              order = 100,
              width = 'half',
              disabled = function()
                           return #Triggers == 0
                         end,
              func = function()
                       EditTriggerListOptions(BarType, UBF, BBar, 'list', TLA, TOA, Triggers, EditList)
                     end,
            },
            Header200 = {
              type = 'header',
              name = '',
              order = 200,
            },
            Import = {
              type = 'execute',
              name = 'Import',
              order = 201,
              width = 'half',
              func = function()
                       Options.Importing = true
                       Options.ImportSourceBarType = BarType
                     end,
              disabled = function()
                           return EditList.Edit and #Triggers > 0
                         end,
            },
          },
        }
      end
    end
  end
end

-------------------------------------------------------------------------------
-- CreateTriggerOptions
--
-- SubFunction of CreateUnitBarOptions()
--
-- Creates the main UI for the triggers
--
-- BarType    Current bar these trigger options are for
-- Order      Position in the options
-- Name       Name of the option
-------------------------------------------------------------------------------
function GUB.TriggerOptions:CreateTriggerOptions(BarType, Order, Name)
  local TriggerOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    args = {},
  }

  -- Create the trigger list options.
  Options:DoFunction(BarType, 'CreateTriggerOptions', function()

    -- Only create triggers if they're enabled.
    if Main.UnitBars[BarType].Layout.EnableTriggers then
      local TOA = {}
      local TLA
      TriggerOptions.args = TOA

      local UBF = Main.UnitBarsF[BarType]
      local BBar = UBF.BBar
      local Triggers = UBF.UnitBar.Triggers
      local EditList = {}
      local Action = 'list'
      local Notes = DUB[BarType].Triggers.Notes

      -- Trigger Notes
      if Notes then
        TOA.Notes = {
          type = 'description',
          name = Notes,
          order = 1,
        }
      end

      -- Trigger Name
      TOA.TriggerName = {
        type = 'input',
        name = function()
                 local Name = ''
                 local Trigger = EditList.Edit == nil and EditList.Trigger
                 if Trigger then
                   Name = TriggerTypeToIcon(Trigger.ObjectType, 14)
                 end

                 return Name .. ' Name'
               end,
        order = 2,
        width = 'full',
        disabled = function()
                     return EditList.Edit
                   end,
        get = function()
                return EditList.Edit == nil and EditList.Trigger and EditList.Trigger.Name or ''
              end,
        set = function(Info, Value)
                EditList.Trigger.Name = Value

                -- Relist to reflect changes to name
                EditTriggerListOptions(BarType, UBF, BBar, 'list', TLA, TOA, Triggers, EditList)
              end,
      }

      -- Trigger list
      TOA.List = {
        type = 'group',
        name = 'List',
        order = 10,
        args = {},
      }
      TLA = TOA.List.args

      if #Triggers == 0 then
        Action = 'add'
      end

      EditTriggerListOptions(BarType, UBF, BBar, Action, TLA, TOA, Triggers, EditList)

      -- Create tabs
      for TriggerIndex = 1, #Triggers do
        CreateTriggerTabOptions(BarType, UBF, BBar, TOA, Triggers[TriggerIndex], EditList)
      end
    end
  end)

  Options:DoFunction(BarType, 'CreateTriggerOptions')

  return TriggerOptions
end
