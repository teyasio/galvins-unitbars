--
-- TextOptions.lua
--
-- Handles all the text options for GalvinUnitBars.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local DUB = GUB.DefaultUB.Default.profile

local Options = GUB.Options
local Main = GUB.Main
local Bar = GUB.Bar

-- tables
local o = Options.o
local LSMDropdown = Options.LSMDropdown
local FontStyleDropdown = Options.FontStyleDropdown
local PositionDropdown = Options.PositionDropdown

-- functions
local CreateSpacer = Options.CreateSpacer
local HideTooltip = Options.HideTooltip
local CreateColorAllOptions = Options.CreateColorAllOptions

-- localize some globals.
local _, _G, print =
      _, _G, print
local format, gsub, tremove, ipairs, pairs =
      format, gsub, tremove, ipairs, pairs

local FontHAlignDropdown = {
  LEFT = 'Left',
  CENTER = 'Center',
  RIGHT = 'Right'
}

local FontVAlignDropdown = {
  TOP = 'Top',
  MIDDLE = 'Middle',
  BOTTOM = 'Bottom',
}

local ValueName_AllDropdown = { -- this isn't used anymore
  [99] = 'None',                -- 99
}

local ValueName_HapDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [7]  = 'Name',
  [8]  = 'Level',
  [99] = 'None',
}

local ValueName_HealthDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [3]  = 'Predicted Health',
  [6]  = 'Absorb Health',
  [7]  = 'Name',
  [8]  = 'Level',
  [99] = 'None',
}

local ValueName_PowerDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [4]  = 'Predicted Power',
  [5]  = 'Predicted Cost',
  [7]  = 'Name',
  [8]  = 'Level',
  [99] = 'None',
}

local ValueName_ManaDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [5]  = 'Predicted Cost',
  [7]  = 'Name',
  [8]  = 'Level',
  [99] = 'None',
}

local ValueName_RuneDropdown = {
  [12] = 'Time',
  [99] = 'None',
}

local ValueName_StaggerDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [12] = 'Time',
  [99] = 'None',
}

local ValueName_AltPowerDropdown = {
  [1]  = 'Current Value',
  [2]  = 'Maximum Value',
  [13] = 'Power Name',
}

local ValueName_AltCounterDropdown = {
  [9]  = 'Counter',
  [10] = 'Current Counter',
  [11] = 'Maximum Counter',
  [12] = 'Time',
  [13] = 'Power Name',
}

local ValueNameMenuDropdown = {
  all          = ValueName_AllDropdown,
  health       = ValueName_HealthDropdown,
  power        = ValueName_PowerDropdown,
  mana         = ValueName_ManaDropdown,
  hap          = ValueName_HapDropdown,
  rune         = ValueName_RuneDropdown,
  stagger      = ValueName_StaggerDropdown,
  staggerpause = ValueName_RuneDropdown,
  essence      = ValueName_RuneDropdown,
  altpower     = ValueName_AltPowerDropdown,
  altcounter   = ValueName_AltCounterDropdown,
}

local ValueType_ValueDropdown = {
  'Whole',                -- 1
  'Short',                -- 2
  'Thousands',            -- 3
  'Millions',             -- 4
  'Whole (Groups)',       -- 5
  'Short (Groups)',       -- 6
  'Thousands (Groups)',   -- 7
  'Millions (Groups)',    -- 8
  'Percentage',           -- 9
}

local ValueType_NameDropdown = {
  [30] = 'Unit Name',
  [31] = 'Realm Name',
  [32] = 'Unit Name and Realm',
}

local ValueType_LevelDropdown = {
  [40] = 'Unit Level',
  [41] = 'Scaled Level',
  [42] = 'Unit Level and Scaled',
}

local ValueType_TimeDropdown = {
  [20] = 'Seconds',
  [21] = 'Seconds.0',
  [22] = 'Seconds.00',
}

local ValueType_WholeDropdown = {
  'Whole', -- 1
}

local ValueType_TextDropdown = {
  [50] = 'Text',
}

local ValueType_NoneDropdown = {
  [100] = '',
}

local ValueTypeMenuDropdown = {
  current         = ValueType_ValueDropdown,
  maximum         = ValueType_ValueDropdown,
  predictedhealth = ValueType_ValueDropdown,
  predictedpower  = ValueType_ValueDropdown,
  predictedcost   = ValueType_ValueDropdown,
  absorbhealth    = ValueType_ValueDropdown,
  name            = ValueType_NameDropdown,
  level           = ValueType_LevelDropdown,
  time            = ValueType_TimeDropdown,
  powername       = ValueType_TextDropdown,
  counter         = ValueType_WholeDropdown,
  countermin      = ValueType_WholeDropdown,
  countermax      = ValueType_WholeDropdown,
  none            = ValueType_NoneDropdown,

  -- prevent error if these values are found.
  unitname      = ValueType_NoneDropdown,
  realmname     = ValueType_NoneDropdown,
  unitnamerealm = ValueType_NoneDropdown,
}

local ConvertValueName = {
         current           = 1,
         maximum           = 2,
         predictedhealth   = 3,
         predictedpower    = 4,
         predictedcost     = 5,
         absorbhealth      = 6,
         name              = 7,
         level             = 8,
         counter           = 9,
         countermin        = 10,
         countermax        = 11,
         time              = 12,
         powername         = 13,
         none              = 99,
         'current',         -- 1
         'maximum',         -- 2
         'predictedhealth', -- 3
         'predictedpower',  -- 4
         'predictedcost',   -- 5
         'absorbhealth',    -- 6
         'name',            -- 7
         'level',           -- 8
         'counter',         -- 9
         'countermin',      -- 10
         'countermax',      -- 11
         'time',            -- 12
         'powername',       -- 13
  [99] = 'none',            -- 99
}

local ConvertValueType = {
  whole                    = 1,
  short                    = 2,
  thousands                = 3,
  millions                 = 4,
  whole_dgroups            = 5,
  short_dgroups            = 6,
  thousands_dgroups        = 7,
  millions_dgroups         = 8,
  percent                  = 9,
  timeSS                   = 20,
  timeSS_H                 = 21,
  timeSS_HH                = 22,
  unitname                 = 30,
  realmname                = 31,
  unitnamerealm            = 32,
  unitlevel                = 40,
  scaledlevel              = 41,
  unitlevelscaled          = 42,
  text                     = 50,
  [1]  = 'whole',
  [2]  = 'short',
  [3]  = 'thousands',
  [4]  = 'millions',
  [5]  = 'whole_dgroups',
  [6]  = 'short_dgroups',
  [7]  = 'thousands_dgroups',
  [8]  = 'millions_dgroups',
  [9]  = 'percent',
  [20] = 'timeSS',
  [21] = 'timeSS_H',
  [22] = 'timeSS_HH',
  [30] = 'unitname',
  [31] = 'realmname',
  [32] = 'unitnamerealm',
  [40] = 'unitlevel',
  [41] = 'scaledlevel',
  [42] = 'unitlevelscaled',
  [50] = 'text',
}

--*****************************************************************************
--
-- Text Options creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- CreateTextFontOptions
--
-- Creats font options to control color, size, etc for text.
--
-- Subfunction of CreateTextOptions()
--
-- BarType       Name of the bar using these options.
-- TableName     Name of the table containing the text.
-- UBF           Unitbar Frame to acces the unitbar functions
-- TLA           Font options will be inserted into this table.
-- Texts         Texts[] option data
-- TextLine      Texts[TextLine]
-- Order         Position to place the options at
-------------------------------------------------------------------------------
local function CreateTextFontOptions(BarType, TableName, UBF, TLA, Texts, TextLine, Order)
  local UBF = Main.UnitBarsF[BarType]
  local Text = Texts[TextLine]

  TLA.FontOptions = {
    type = 'group',
    name = function()
             -- highlight the text in green.
             Bar:SetHighlightFont(BarType, Main.UnitBars.HideTextHighlight, TextLine)
             return 'Font'
           end,
    order = Order + 1,
    get = function(Info)
            return Text[Info[#Info]]
          end,
    set = function(Info, Value)
            Text[Info[#Info]] = Value
            UBF:SetAttr('Text', '_Font')
          end,
    args = {
      FontType = {
        type = 'select',
        name = 'Type',
        order = 1,
        dialogControl = 'LSM30_Font',
        values = LSMDropdown.Font,
      },
      FontStyle = {
        type = 'select',
        name = 'Style',
        order = 2,
        style = 'dropdown',
        values = FontStyleDropdown,
        },
      Spacer20 = CreateSpacer(20),
      FontSize = {
        type = 'range',
        name = 'Size',
        order = 21,
        min = o.FontSizeMin,
        max = o.FontSizeMax,
        step = 1,
      },
      Spacer30 = CreateSpacer(30),
      Anchor = {
        type = 'group',
        name = 'Anchor',
        dialogInline = true,
        order = 31,
        args = {
          FontAnchorPosition = {
            type = 'select',
            name = 'Position',
            order = 11,
            style = 'dropdown',
            desc = 'Change the anchor position of the font frame',
            values = PositionDropdown,
          },
          FontBarPosition = {
            type = 'select',
            name = "To Bar's",
            order = 12,
            style = 'dropdown',
            desc = 'Location of the font frame around the bar',
            values = PositionDropdown,
          },
        },
      },
      Alignment = {
        type = 'group',
        name = 'Alignment |cffffff00(only works when \\n is used)|r',
        dialogInline = true,
        order = 32,
        args = {
          FontHAlign = {
            type = 'select',
            name = 'Horizontal',
            desc = 'Text location within the font frame',
            order = 1,
            style = 'dropdown',
            values = FontHAlignDropdown,
          },
          FontVAlign = {
            type = 'select',
            name = 'Vertical',
            desc = 'Text location within the font frame',
            order = 2,
            style = 'dropdown',
            values = FontVAlignDropdown,
          },
        },
      },
    },
  }

  -- Add color all text option for the runebar and essecenbar only.
  if BarType == 'RuneBar' or BarType == 'EssenceBar' then
    TLA.TextColors = CreateColorAllOptions(BarType, 'Text', TableName .. '.1.Color', '_Font', Order, 'Color')
  else
    TLA.FontOptions.args.TextColor = {
      type = 'color',
      name = 'Color',
      order = 22,
      hasAlpha = true,
      get = function()
              local c = Text.Color

              return c.r, c.g, c.b, c.a
            end,
      set = function(Info, r, g, b, a)
              local c = Text.Color

              c.r, c.g, c.b, c.a = r, g, b, a
              UBF:SetAttr('Text', '_Font')
            end,
    }
  end

  TLA.FontOptions.args.Offsets = {
    type = 'group',
    name = 'Offsets',
    dialogInline = true,
    order = 41,
    get = function(Info)
            return Text[Info[#Info]]
          end,
    set = function(Info, Value)
            Text[Info[#Info]] = Value
            UBF:SetAttr('Text', '_Font')
          end,
    args = {
      OffsetX = {
        type = 'range',
        name = 'Horizonal',
        order = 2,
        min = o.FontOffsetXMin,
        max = o.FontOffsetXMax,
        step = 1,
      },
      OffsetY = {
        type = 'range',
        name = 'Vertical',
        order = 3,
        min = o.FontOffsetYMin,
        max = o.FontOffsetYMax,
        step = 1,
      },
      ShadowOffset = {
        type = 'range',
        name = 'Shadow',
        order = 4,
        min = o.FontShadowOffsetMin,
        max = o.FontShadowOffsetMax,
        step = 1,
      },
    },
  }
end

-------------------------------------------------------------------------------
-- AddValueIndexOptions
--
-- Creates dynamic drop down options for text value names and types
--
-- Subfunction of CreateTextValueOptions()
--
-- DUBTexts       Default unitbar text
-- ValueNames     Current array, both value name and value type menus are made from this.
-- ValueIndex     Index into ValueNames
-- Order          Position to place the options at
-------------------------------------------------------------------------------
local function AddValueIndexOptions(DUBTexts, ValueNames, ValueIndex, Order)
  local ValueNameDropdown = ValueNameMenuDropdown[DUBTexts._ValueNameMenu]

  local ValueIndexOptions = {
    type = 'group',
    name = '',
    order = Order + ValueIndex,
    dialogInline = true,
    args = {
      ValueName = {
        type = 'select',
        name = format('Value Name %s', ValueIndex),
        values = ValueNameDropdown,
        order = 1,
        arg = ValueIndex,
      },
      ValueType = {
        type = 'select',
        name = format('Value Type %s', ValueIndex),
        disabled = function()
                     -- Disable if the ValueName is not found in the menu.
                     return ValueNames[ValueIndex] == 'none' or
                            ValueNameDropdown[ConvertValueName[ValueNames[ValueIndex]]] == nil
                   end,
        values = function()
                   local VName = ValueNames[ValueIndex]
                   if ValueNameDropdown[ConvertValueName[VName]] == nil then

                     -- Valuename not found in the menu so return an empty menu
                     return ValueType_NoneDropdown
                   else
                     return ValueTypeMenuDropdown[VName]
                   end
                 end,
        arg = ValueIndex,
      },
    },
  }

  return ValueIndexOptions
end

-------------------------------------------------------------------------------
-- CreateTextValueOptions
--
-- Creates dynamic drop down options for text value names and types
--
-- Subfunction of AddTextLineOptions()
--
-- UBF            Unitbar Frame to acces the unitbar functions
-- TLA            Current Text Line options being used.
-- Texts          Texts[] option data
-- TextLine       Texts[TextLine]
-- Order          Position to place the options at
-------------------------------------------------------------------------------
local function CreateTextValueOptions(UBF, TLA, DUBTexts, Texts, TextLine, Order)
  local Text = Texts[TextLine]
  local ValueNames = Text.ValueNames
  local ValueTypes = Text.ValueTypes
  local NumValues = 0
  local MaxValueNames = o.MaxValueNames
  local ValueIndexName = 'ValueIndexOptions%s'

  -- Forward Value option arguments
  local VOA

  TLA.ValueOptions = {
    type = 'group',
    name = 'Value',
    order = Order,
    get = function(Info)
            local KeyName = Info[#Info]
            local ValueIndex = Info.arg

            if KeyName == 'ValueName' then

              -- Check if the valuename is not found in the menu.
              return ConvertValueName[ValueNames[ValueIndex]]

            elseif KeyName == 'ValueType' then
              return ConvertValueType[ValueTypes[ValueIndex]]
            end
          end,
    set = function(Info, Value)
            local KeyName = Info[#Info]
            local ValueIndex = Info.arg

            if KeyName == 'ValueName' then
              local VName = ConvertValueName[Value]
              ValueNames[ValueIndex] = VName

              -- ValueType menu may have changed, so need to update ValueTypes.
              local Dropdown = ValueTypeMenuDropdown[VName]
              local Value = ConvertValueType[ValueTypes[ValueIndex]]

              -- Find the first menu entry
              if Dropdown[Value] == nil then
                Value = 100
                for Index in pairs(Dropdown) do
                  if Value > Index then
                    Value = Index
                  end
                end
                ValueTypes[ValueIndex] = ConvertValueType[Value]
              end
            elseif KeyName == 'ValueType' then
              ValueTypes[ValueIndex] = ConvertValueType[Value]
            end

            -- Update the font.
            UBF:SetAttr('Text', '_Font')
          end,
    args = {
      Message = {
        type = 'description',
        name = 'Custom Layout: "))" = ")", "%%" = "%", or "|||" = "|" in the format string\n                               "\\n" for new line',
        order = 1,
        hidden = function()
                   return not Text.Custom
                 end,
      },
      Output = {
        type = 'description',
        fontSize = 'medium',
        name = function()
                 return format('|cff00ff00%s|r', Text.ErrorMessage or Text.SampleText or '')
               end,
        order = 2,
      },
      Layout = {
        type = 'input',
        name = 'Layout',
        order = 3,
        multiline = true,
        width = 'full',
        desc = 'To customize the layout change it here',
        get = function()
                return gsub(Text.Layout, '|', '||')
              end,
        set = function(Info, Value)
                Text.Custom = true
                Text.Layout = gsub(Value, '||', '|')

                -- Update the bar.
                UBF:SetAttr('Text', '_Font')
              end,
      },
      Spacer4 = CreateSpacer(4),
      RemoveValue = {
        type = 'execute',
        name = 'Remove',
        order = 5,
        width = 'half',
        desc = 'Remove a value',
        disabled = function()
                     -- Hide the tooltip since the button will be disabled.
                     return HideTooltip(NumValues == 1)
                   end,
        func = function()
                 -- remove last value type.
                 tremove(ValueNames, NumValues)
                 tremove(ValueTypes, NumValues)

                 VOA[format(ValueIndexName, NumValues)] = nil

                 NumValues = NumValues - 1

                 -- Update the font to reflect changes
                 UBF:SetAttr('Text', '_Font')
               end,
      },
      AddValue = {
        type = 'execute',
        name = 'Add',
        order = 6,
        width = 'half',
        desc = 'Add another value',
        disabled = function()
                     -- Hide the tooltip since the button will be disabled.
                     return HideTooltip(NumValues == MaxValueNames)
                   end,
        func = function()
                 NumValues = NumValues + 1
                 VOA[format(ValueIndexName, NumValues)] = AddValueIndexOptions(DUBTexts, ValueNames, NumValues, 10)

                 -- Add a new value setting.
                 ValueNames[NumValues] = DUBTexts[1].ValueNames[1]
                 ValueTypes[NumValues] = DUBTexts[1].ValueTypes[1]

                 -- Update the font to reflect changes
                 UBF:SetAttr('Text', '_Font')
               end,
      },
      Spacer7 = CreateSpacer(7, 'half'),
      ExitCustomLayout = {
        type = 'execute',
        name = 'Exit',
        order = 8,
        width = 'half',
        hidden = function()
                   return HideTooltip(not Text.Custom)
                 end,
        desc = 'Exit custom layout mode',
        func = function()
                 Text.Custom = false

                 -- Call setattr to reset layout without changing the text settings.
                 UBF:SetAttr()
               end,
      },
      Spacer9 = CreateSpacer(9),
    },
  }

  VOA = TLA.ValueOptions.args

  -- Add additional value options if needed
  for ValueIndex, Value in ipairs(ValueNames) do
    VOA[format(ValueIndexName, ValueIndex)] = AddValueIndexOptions(DUBTexts, ValueNames, ValueIndex, 10)
    NumValues = ValueIndex
  end
end

-------------------------------------------------------------------------------
-- AddTextLineOptions
--
-- Creates a new set of options for a textline.
--
-- Subfunction of CreateTextOptions()
--
-- BarType           Name of the bar using these options.
-- TableName         Name of the table containing the text options data.
-- UBF               Unitbar Frame to acces the unitbar functions
-- TOA               TextOptions.args
-- DUBTexts          Defalt unitbar text
-- Texts             Texts[] option data
-- TextLine          Texts[TextLine]
-------------------------------------------------------------------------------
local function AddTextLineOptions(BarType, TableName, UBF, TOA, DUBTexts, Texts, TextLine)
  local MaxTextLines = o.MaxTextLines

  local TextLineOptions = {
    type = 'group',
    name = format('Text Line %s', TextLine),
    order = TextLine,
    childGroups = 'tab',
    args = {},
  }

  -- Add text line to TextOptions
  local TextLineName = 'TextLine%s'
  local TLA = TextLineOptions.args
  TOA[format(TextLineName, TextLine)] = TextLineOptions

  if DUBTexts.Notes ~= nil then
    TLA.Notes = {
      type = 'description',
      order = 0.1,
      name = DUBTexts.Notes,
    }
  end

  TLA.RemoveTextLine = {
    type = 'execute',
    name = function()
             return format('Remove Text Line', TextLine)
           end,
    width = 'normal',
    order = 1,
    desc = function()
             return format('Remove Text Line %s', TextLine)
           end,
    disabled = function()
               -- Hide the tooltip since the button will be disabled.
               return HideTooltip(#Texts == 1)
             end,
    confirm = function()
                return format('Remove Text Line %s ?', TextLine)
              end,
    func = function()
             -- Delete the text setting.
             tremove(Texts, TextLine)

             -- Move options down by one by deleting and recreating
             for TextLine = #Texts, MaxTextLines do
               TOA[format(TextLineName, TextLine)] = nil

               if TextLine <= #Texts then
                 AddTextLineOptions(BarType, TableName, UBF, TOA, DUBTexts, Texts, TextLine)
               end
             end

             -- Update the the bar to reflect changes
             UBF:SetAttr('Text', '_Font')
           end,
  }
  TLA.AddTextLine = {
    type = 'execute',
    order = 2,
    name = 'Add Text Line',
    width = 'normal',
    disabled = function()
               -- Hide the tooltip since the button will be disabled.
               return HideTooltip(#Texts == MaxTextLines)
             end,
    func = function()

             -- Add text on to end.
             -- Deep Copy first text setting from defaults into text table.
             local TextTable = {}

             Main:CopyTableValues(DUBTexts[1], TextTable, true)
             Texts[#Texts + 1] = TextTable

             -- Add options for new text line.
             AddTextLineOptions(BarType, TableName, UBF, TOA, DUBTexts, Texts, #Texts)

             -- Update the the bar to reflect changes
             UBF:SetAttr('Text', '_Font')
           end,
  }

  CreateTextValueOptions(UBF, TLA, DUBTexts, Texts, TextLine, 10)
  CreateTextFontOptions(BarType, TableName, UBF, TLA, Texts, TextLine, 11)
end

-------------------------------------------------------------------------------
-- CreateTextOptions
--
-- Creates dyanmic text options for a unitbar.
--
-- Subfunction of CreateUnitBarOptions()
--
-- BarType               Type options being created.
-- TableName             Name of the table containing the text.
-- Order                 Order number.
-- Name                  Name text
--
-- TextOptions     Options table for text options.
--
-- NOTES:  Since DoFunction is being used.  When it gets called UnitBarF[].UnitBar
--         is not upto date at that time.  So Main.UnitBars[BarType] must be used
--         instead.
-------------------------------------------------------------------------------
function GUB.TextOptions:CreateTextOptions(BarType, TableName, Order, Name)
  local TextOptions = {
    type = 'group',
    name = Name,
    order = Order,
    childGroups = 'tab',
    args = {}, -- need this so ACE3 dont crash if text options are not created.
  }

  local DoFunctionTextName = 'CreateTextOptions' .. TableName

  -- This will modify text options table if the profile changed.
  -- Basically rebuild the text options when ever the profile changes.
  Options:DoFunction(BarType, DoFunctionTextName, function()
    local TOA = {}
    TextOptions.args = TOA

    local UBF = Main.UnitBarsF[BarType]
    local Texts = UBF.UnitBar[TableName]
    local DUBTexts = DUB[BarType][TableName]

    -- Add the textlines
    for TextLine = 1, #Texts do
      AddTextLineOptions(BarType, TableName, UBF, TOA, DUBTexts, Texts, TextLine)
    end
  end)

  -- Set up the options
  Options:DoFunction(BarType, DoFunctionTextName)

  return TextOptions
end
