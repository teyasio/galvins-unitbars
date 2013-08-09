--
-- WoWUI.lua
--
-- This allows option controls using the world of warcraft UI.
--
-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local WoWUI = GUB.WoWUI
local Main = GUB.Main
local LSM = GUB.LSM

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin
local strfind, strsub, strupper, strlower, strmatch, format, strconcat, strmatch, gsub, tonumber =
      strfind, strsub, strupper, strlower, strmatch, format, strconcat, strmatch, gsub, tonumber
local pcall, pairs, ipairs, type, select, next, print, sort, tremove =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitName, UnitGetIncomingHeals =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax, UnitName, UnitGetIncomingHeals
local GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, GetSpellInfo, GetTalentInfo, PlaySound =
      GetRuneCooldown, CooldownFrame_SetTimer, GetRuneType, SetDesaturation, GetSpellInfo, GetTalentInfo, PlaySound
local GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, UIParent =
      C_PetBattles, UIParent

-------------------------------------------------------------------------------
-- Locals
--
-- SelectButtonFrame
--   Enabled                    If true then the control is active otherwise inactive.
--   SelectButtonBg             Background texture for the select button.
--   SelectButtonCheck          Texture used when the button is selected.
--   SelectButtonHighlight      Highlight texture when the user mouses over the button.
--   SelectButtonLabel          Text that appears in the select button.
--   Checked                    If true the button is selected, otherwise false.
--                              This value is internal and should not be changed.
--   SetValue(true or false)    Select or unselect the button.
--   SetEnabled(true or false)  Enable or disable the button.
--   ValueChangedFn             Function that gets called when the button changes.
--   WoWUI                      Used by Main:ShowTooltip()
--
-- SliderFrame
--   Enabled                    if true then the control is active otherwise inactive.
--   SliderMinLabel             Text for the minimum value.
--   SliderMaxLabel             Text for the maximum value.
--   SliderLabel                Text that appears above the slider in yellow.
--   SetLabel(text)             Changes the Label for the slider.
--   SetEnabled(true or false)  Enable or disable the slider.
--   SetMinMax(min, max)        Change the minimum and maximum values of the slider.
--   ValueChangedFn             Function that gets called when the slider changes.
--   WoWUI                      Used by Main:ShowTooltip()

-- PanelButtonFrame
--   SetEnabled(true or false)  Enable or disable the button.
--   WoWUI                      Used by Main:ShowTooltip()
-------------------------------------------------------------------------------
local CheckBoxTextureBg = [[Interface\Buttons\UI-CheckBox-Up]]
local CheckBoxTextureChecked = [[Interface\Buttons\UI-CheckBox-Check]]
local CheckBoxTextureHighlight = [[Interface\Buttons\UI-CheckBox-Highlight]]
local RadioTexture = [[Interface\Buttons\UI-RadioButton]]
local SliderThumbTexture = [[Interface\Buttons\UI-SliderBar-Button-Horizontal]]

local GameFontHighlight = 'GameFontHighlight'
local GameFontHighlightSmall = 'GameFontHighlightSmall'
local GameFontNormal = 'GameFontNormal'

local ControlWindowBackdrop = {
  bgFile   = [[Interface\DialogFrame\UI-DialogBox-Background]], -- background texture
  edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],     -- border texture
  tile = true,      -- True to repeat the background texture to fill the frame, false to scale it.
  tileSize = 16,    -- Size (width or height) of the square repeating background tiles (in pixels).
  edgeSize = 16,    -- Thickness of edge segments and square size of edge corners (in pixels).
  insets = {        -- Positive values shrink the border inwards, negative expand it outwards.
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

local PaneBackdrop  = {
  bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = {
    left = 3,
    right = 3,
    top = 5,
    bottom = 3
  }
}

local SliderBackdrop  = {
  bgFile = [[Interface\Buttons\UI-SliderBar-Background]],
  edgeFile = [[Interface\Buttons\UI-SliderBar-Border]],
  tile = true,
  tileSize = 8,
  edgeSize = 8,
  insets = {
    left = 3,
    right = 3,
    top = 6,
    bottom = 6
  }
}

local SliderEditBoxBackdrop = {
  bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
  edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
  tile = true,
  tileSize = 5,
  edgeSize = 1,
}

-------------------------------------------------------------------------------
-- SetGreyedOut
--
-- Sets a texture or font string to be greyed out.
--
-- Usage: SetGreyedOut(Object, Type, Value)
--
-- Object   Can be a texture or fontstring.
-- Type     = 'font' or 'texture'
-- Value    = true to set greyed out or false to clear it.
-------------------------------------------------------------------------------
local function SetGreyedOut(Object, Type, Value)
  local Color = Object.Color
  if Value then
    if Type == 'font' then

      -- Save current color before changing it.
      if Color == nil then
        Color = {}
        Object.Color = Color
      end
      if Object.GreyedOut == nil or not Object.GreyedOut then
        Color.r, Color.g, Color.b, Color.a = Object:GetTextColor()
        Object.GreyedOut = true
      end
      Object:SetTextColor(0.5, 0.5, 0.5)
    elseif Type == 'texture' then
      SetDesaturation(Object, true)
    end
  elseif Type == 'font' then

    -- Only restore color if color was changed from greying out.
    if Color then
      Object.GreyedOut = false
      Object:SetTextColor(Color.r, Color.g, Color.b, Color.a)
    end
  elseif Type == 'texture' then
    SetDesaturation(Object, false)
  end
end

-------------------------------------------------------------------------------
-- SetButtonValue
--
-- Clears or sets a check or radio button.
--
-- Sub function of CreateSelectButton()
--
-- Usage: SetButtonValue(self, true or false)
--
-- self     Button to be set
--
-- Note:    Changing a button value will cause the buttons Value changed function to be called.
-------------------------------------------------------------------------------
local function SetButtonValue(self, Value)

  -- Check to see if button changed value.
  if self.Checked ~= Value then
    self.Checked = Value
    if Value then
      self.SelectButtonCheck:Show()
    else
      self.SelectButtonCheck:Hide()
    end
    self.ValueChangedFn(self)
  end
end

-------------------------------------------------------------------------------
-- SetSliderMinMax
--
-- Sets the slider minimum and maximum value.
--
-- Sub function of CreateSlider()
--
-- Usage: SetSliderMinMax(self, Min, Max)
--
-- self     Slider being changed.
-- Min      Minimum value.
-- Max      Maximum value.
-------------------------------------------------------------------------------
local function SetSliderMinMax(self, Min, Max)
  self.SliderMinLabel:SetFormattedText('%d', Min)
  self.SliderMinLabel:SetFormattedText('%d', Max)
  self:SetMinMaxValues(Min, Max)
end

-------------------------------------------------------------------------------
-- SetControlLabel
--
-- Changes the text for the control.
--
-- Sub function of CreateSelectButton(), CreateSlider().
--
-- Usage: SetControlLabel(self, Value)
--
-- self    Control being changed.
-- Value   New text for control.
-------------------------------------------------------------------------------
local function SetControlLabel(self, Value)
  local SelectButtonLabel = self.SelectButtonLabel
  local SliderLabel = self.SliderLabel
  if self.TooltipName then
    self.TooltipName = Value
  end
  if SelectButtonLabel then
    SelectButtonLabel:SetText(Value)

    -- Set width to match string for mouse over.
    if self.Type == 'check' then
      self:SetWidth(24 + SelectButtonLabel:GetStringWidth())
    elseif self.Type == 'radio' then
      self:SetWidth(16 + SelectButtonLabel:GetStringWidth())
    end
  elseif SliderLabel then
    SliderLabel:SetText(Value)
  end
end

-------------------------------------------------------------------------------
-- SetContrlEnabled
--
-- Disables or enables a control.
--
-- Sub function of CreateSelectButton(), CreateSlider().
--
-- Usage: SetControlEnabled(self, true or false)
--
-- self    Control to enable or disable.
-------------------------------------------------------------------------------
local function SetControlEnabled(self, Value)

  -- Check for button control.
  if self.SelectButtonLabel then
    SetGreyedOut(self.SelectButtonCheck, 'texture', not Value)
    SetGreyedOut(self.SelectButtonLabel, 'font', not Value)

  -- Check for slider control
  elseif self.SliderLabel then
    SetGreyedOut(self.SliderMinLabel, 'font', not Value)
    SetGreyedOut(self.SliderMaxLabel, 'font', not Value)
    SetGreyedOut(self.SliderLabel, 'font', not Value)
    local SliderEditBoxFrame = self.SliderEditBoxFrame

    SetGreyedOut(SliderEditBoxFrame, 'font', not Value)
    SliderEditBoxFrame:EnableMouse(Value)
    SliderEditBoxFrame:ClearFocus()
  end

  -- Else its a panel button.
  if Value then
    self:Enable()
  else
    self:Disable()
  end
end

-------------------------------------------------------------------------------
-- CreateSelectButton
--
-- Creates a SelectButton or radio button that can be clicked on
--
-- Usage: Frame = CreateSelecButton(Parent, Type, Label, Point, OffsetX, OffsetY, ValueChangedFn)
--
-- Parent          The SelectButton will be a child of parent.
-- Label           Label to be displayed next to the SelectButton.
-- Type            'radio' or 'check'
-- ValueChangedFn  Gets called with 'self' passed.  Use self.Checked to test if checked or unchecked.
-- Point           Point 'LEFT', 'TOP', etc.
-- ParentPoint     If '' then ignored.  Parent frame point.
-- OffsetX         Horizontal offset from Point.
-- OffsetY         Vertical offset from point.
--
-- Use the following to modify the button or check its state.
--   Frame:SetValue(true or false)    Set the button to selected or not selected.
--   Frame:SetEnabled(true or false)  Enable or disable the button.
--   Frame.Checked                    If true then selected otherwise false.
--   Frame.Type                       'radio' or 'check'
--   Frame:SetLabel(text)             Change the label to text.
--   Frame:SetTooltip(name, desc)     Sets a desc to tooltip
-------------------------------------------------------------------------------
function GUB.WoWUI:CreateSelectButton(Parent, Type, Label, Point, ParentPoint, OffsetX, OffsetY, ValueChangedFn)

  -- Create check box.
  local SelectButtonFrame = CreateFrame('Button', nil, Parent)
  if ParentPoint ~= '' then
    SelectButtonFrame:SetPoint(Point, Parent, ParentPoint, OffsetX, OffsetY)
  else
    SelectButtonFrame:SetPoint(Point, OffsetX, OffsetY)
  end
  SelectButtonFrame:SetHeight(24)

  -- Create the border texture.
  local SelectButtonBg = SelectButtonFrame:CreateTexture(nil, 'ARTWORK')
  SelectButtonBg:SetPoint('LEFT', 0, 0)

  --- Create the check mark texture.
  local SelectButtonCheck = SelectButtonFrame:CreateTexture(nil, 'OVERLAY')
  SelectButtonCheck:SetAllPoints(SelectButtonBg)
  SelectButtonCheck:Hide()

  -- Create the highlight texture.
  local SelectButtonHighlight = SelectButtonFrame:CreateTexture(nil, 'HIGHLIGHT')
  SelectButtonHighlight:SetBlendMode('ADD')
  SelectButtonHighlight:SetAllPoints(SelectButtonBg)
  SelectButtonHighlight:Hide()

  -- Create the label.
  local SelectButtonLabel = SelectButtonFrame:CreateFontString(nil, 'OVERLAY', GameFontHighlight)
  SelectButtonLabel:SetPoint('LEFT', SelectButtonBg, 'RIGHT', 0, 0)
  SelectButtonLabel:SetJustifyH('LEFT')
  SelectButtonLabel:SetText(Label)

  if Type == 'check' then
    SelectButtonBg:SetWidth(24)
    SelectButtonBg:SetHeight(24)
    SelectButtonBg:SetTexture(CheckBoxTextureBg)
    SelectButtonCheck:SetTexture(CheckBoxTextureChecked)
    SelectButtonHighlight:SetTexture(CheckBoxTextureHighlight)

    -- Set width to match string for mouse over.
    SelectButtonFrame:SetWidth(24 + SelectButtonLabel:GetStringWidth())

  elseif Type == 'radio' then
    SelectButtonBg:SetWidth(16)
    SelectButtonBg:SetHeight(16)
    SelectButtonBg:SetTexture(RadioTexture)
    SelectButtonBg:SetTexCoord(0, 0.25, 0, 1)
    SelectButtonCheck:SetTexture(RadioTexture)
    SelectButtonCheck:SetTexCoord(0.25, 0.5, 0, 1)
    SelectButtonHighlight:SetTexture(RadioTexture)
    SelectButtonHighlight:SetTexCoord(0.5, 0.75, 0, 1)

    -- Set width to match string for mouse over.
    SelectButtonFrame:SetWidth(16 + SelectButtonLabel:GetStringWidth())
  end

  -- Set the scripts.
  SelectButtonFrame:SetScript('OnEnter', function(self)
                                           SelectButtonHighlight:Show()
                                           Main:ShowTooltip(self, true)
                                         end)
  SelectButtonFrame:SetScript('OnLeave', function(self)
                                           SelectButtonHighlight:Hide()
                                           Main:ShowTooltip(self, false)
                                         end)
  SelectButtonFrame:SetScript('OnMouseDown', function(self)
                                               if self.Enabled then
                                                 SelectButtonLabel:SetPoint('LEFT', SelectButtonBg, 'RIGHT', 1, -1)
                                               end
                                             end)
  SelectButtonFrame:SetScript('OnMouseUp', function(self)
                                             if self.Enabled then
                                               SelectButtonLabel:SetPoint('LEFT', SelectButtonBg, 'RIGHT', 0, 0)
                                               if Type == 'check' then
                                                 self:SetValue(not self.Checked)
                                               elseif Type == 'radio' then
                                                 if self.Checked == false then
                                                   self:SetValue(true)
                                                 end
                                               end
                                               PlaySound('igMainMenuOptionCheckBoxOn')
                                             end
                                           end)

  -- Save everything to the frame and return it.
  SelectButtonFrame.Enabled = true
  SelectButtonFrame.SelectButtonBg = SelectButtonBg
  SelectButtonFrame.SelectButtonCheck = SelectButtonCheck
  SelectButtonFrame.SelectButtonHighlight = SelectButtonHighlight
  SelectButtonFrame.SelectButtonLabel = SelectButtonLabel
  SelectButtonFrame.Checked = nil
  SelectButtonFrame.SetValue = SetButtonValue
  SelectButtonFrame.SetEnabled = SetControlEnabled
  SelectButtonFrame.SetLabel = SetControlLabel
  SelectButtonFrame.Type = Type
  SelectButtonFrame.WoWUI = true
  SelectButtonFrame.SetTooltip = function(self, Name, Description)
                                   Main:SetTooltip(self, Name, Description)
                                 end
  SelectButtonFrame.ValueChangedFn = ValueChangedFn

  return SelectButtonFrame
end

-------------------------------------------------------------------------------
-- CreateSlider
--
-- Creates a slider
--
-- Usage: Frame = CreateSlider(Parent, Label, Point, ParentPoint, OffsetX, OffsetY, Width, Min, Max, ValueChangedFn)
--
-- Parent          The slider will be a child of Parent.
-- Point           'CENTER' , 'LEFT', etc.
-- Label           Name of the slider.
-- ParentPoint     if '' then ignored.  Point of parent.
-- OffsetX         Horizontal offset from Point.
-- OffsetY         Vertical offset from point.
-- Width           Width of the slider.
-- Min             Minimum value of the slider.
-- Max             Maximum value of the slider.
-- ValueChangedFn  Gets called with 'self' passed.  Use self:GetValue() to get the value of the slider.
--
-- Use the following to modify the slider.
--   Frame:SetValue(n)                Change the value of slider to n.
--   Frame:SetEnabled(true or false)  Enable or disable the slider.
--   Frame:SetMinMax(min, max)        Change the min and max values of the slider.
--   Frame:SetLabel(text)             Change the label to text.
--   Frame:SetTooltip(name, desc)     Sets a desc to tooltip
--------------------------------------------------------------------------------
function GUB.WoWUI:CreateSlider(Parent, Label, Point, ParentPoint, OffsetX, OffsetY, Width, Min, Max, ValueChangedFn)

  -- Create slider frame
  local SliderFrame = CreateFrame('Slider', nil, Parent)
  SliderFrame:SetOrientation('HORIZONTAL')
  if ParentPoint ~= '' then
    SliderFrame:SetPoint(Point, Parent, ParentPoint, OffsetX, OffsetY)
  else
    SliderFrame:SetPoint(Point, OffsetX, OffsetY)
  end
  SliderFrame:SetHeight(18)
  SliderFrame:SetWidth(Width)
  SliderFrame:SetHitRectInsets(0, 0, -10, 0)
  SliderFrame:SetMinMaxValues(Min, Max)
  SliderFrame:SetValueStep(1)
  SliderFrame:SetBackdrop(SliderBackdrop)
  SliderFrame:SetThumbTexture(SliderThumbTexture)

  -- Create slider text min.
  local SliderMinLabel = SliderFrame:CreateFontString(nil, 'ARTWORK', GameFontHighlightSmall)
  SliderMinLabel:SetPoint('TOPLEFT', SliderFrame, 'BOTTOMLEFT', 0, 0)
  SliderMinLabel:SetWidth(100)
  SliderMinLabel:SetJustifyH('LEFT')
  SliderMinLabel:SetFormattedText('%d', Min)

  -- Create slider text max.
  local SliderMaxLabel = SliderFrame:CreateFontString(nil, 'ARTWORK', GameFontHighlightSmall)
  SliderMaxLabel:SetPoint('TOPRIGHT', SliderFrame, 'BOTTOMRIGHT', 0, 0)
  SliderMaxLabel:SetWidth(100)
  SliderMaxLabel:SetJustifyH('RIGHT')
  SliderMaxLabel:SetFormattedText('%d', Max)

  -- Create slider label
  local SliderLabel = SliderFrame:CreateFontString(nil, 'OVERLAY', GameFontNormal)
  SliderLabel:SetPoint('BOTTOM', SliderFrame, 'TOP', 0, 0)
  SliderLabel:SetWidth(100)
  SliderLabel:SetJustifyH('CENTER')
  SliderLabel:SetText(Label)

  -- Create slider edit box.
  local SliderEditBoxFrame = CreateFrame('EditBox', nil, SliderFrame)
  SliderEditBoxFrame:SetAutoFocus(false)
  SliderEditBoxFrame:SetFontObject(GameFontHighlightSmall)
  SliderEditBoxFrame:SetPoint('TOP', SliderFrame, 'BOTTOM', 0, 0)
  SliderEditBoxFrame:SetHeight(14)
  SliderEditBoxFrame:SetWidth(70)
  SliderEditBoxFrame:SetJustifyH('CENTER')
  SliderEditBoxFrame:EnableMouse(true)
  SliderEditBoxFrame:SetBackdrop(SliderEditBoxBackdrop)
  SliderEditBoxFrame:SetBackdropColor(0, 0, 0, 0.5)
  SliderEditBoxFrame:SetBackdropBorderColor(0.3, 0.3, 0.30, 0.80)

  -- Set slider scripts.
  SliderFrame:SetScript('OnEnter', function(self)
                                           Main:ShowTooltip(self, true)
                                         end)
  SliderFrame:SetScript('OnLeave', function(self)
                                           Main:ShowTooltip(self, false)
                                         end)
  SliderFrame:SetScript('OnValueChanged', function(self)
                                            SliderEditBoxFrame:SetText(format('%d', self:GetValue()))
                                            ValueChangedFn(self)
                                          end)
  SliderEditBoxFrame:SetScript('OnEnter', function(self)
                                            self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                                          end)
  SliderEditBoxFrame:SetScript('OnLeave', function(self)
                                            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
                                          end)
  SliderEditBoxFrame:SetScript('OnEnterPressed', function(self)
                                                   local Value = tonumber(self:GetText())
                                                   if Value then
                                                     PlaySound('igMainMenuOptionCheckBoxOn')
                                                     SliderFrame:SetValue(Value)
                                                     self:ClearFocus()
                                                   end
                                                 end)
  SliderEditBoxFrame:SetScript('OnEscapePressed', function(self)
                                                    self:ClearFocus()
                                                  end)

  -- Save everything to the frame and return it.
  SliderFrame.Enabled = true
  SliderFrame.SliderMinLabel = SliderMinLabel
  SliderFrame.SliderMaxLabel = SliderMaxLabel
  SliderFrame.SliderLabel = SliderLabel
  SliderFrame.SliderEditBoxFrame = SliderEditBoxFrame
  SliderFrame.SetLabel = SetControlLabel
  SliderFrame.SetEnabled = SetControlEnabled
  SliderFrame.SetMinMax = SetSliderMinMax
  SliderFrame.WoWUI = true
  SliderFrame.SetTooltip = function(self, Name, Description)
                             Main:SetTooltip(self, Name, Description)
                           end
  SliderFrame.ValueChangedFn = ValueChangedFn

  return SliderFrame
end

-------------------------------------------------------------------------------
-- CreatePanelButton
--
-- Creates a button that can be clicked on.  Like 'cancel' and 'ok' buttons.
--
-- Usage: Frame = CreatePanelButton(Parent, Label, Point, ParentPoint, OffsetX, OffsetY, Width, ExecuteFn)
--
-- Parent        The button will be a child of Parent.
-- Label         Text that will appear on the button.
-- Point         'CENTER', 'LEFT', etc.
-- ParentPoint   if '' then ignored.  Point of parent.
-- Width         Width of button.
-- Height        Height of button.
-- OffsetX       Horizontal offset from Point.
-- OffsetY       Vertical offset from Point.
-- ExecuteFn     Gets call when button is clicked.
--
-- Frame:SetTooltip(name, desc)   Sets a desc to tooltip
-------------------------------------------------------------------------------
function GUB.WoWUI:CreatePanelButton(Parent, Label, Point, ParentPoint, OffsetX, OffsetY, Width, ExecuteFn)
  local PanelButtonFrame = CreateFrame('Button', nil, Parent, 'UIPanelButtonTemplate')

  if ParentPoint ~= '' then
    PanelButtonFrame:SetPoint(Point, Parent, ParentPoint, OffsetX, OffsetY)
  else
    PanelButtonFrame:SetPoint(Point, OffsetX, OffsetY)
  end
  PanelButtonFrame:SetWidth(Width)
  PanelButtonFrame:SetHeight(20)
  PanelButtonFrame:SetText(Label)

  PanelButtonFrame:SetScript('OnEnter', function(self)
                                           Main:ShowTooltip(self, true)
                                         end)
  PanelButtonFrame:SetScript('OnLeave', function(self)
                                           Main:ShowTooltip(self, false)
                                         end)
  PanelButtonFrame:SetScript('OnClick', function(self)
                                          PlaySound('igMainMenuOptionCheckBoxOn')
                                          ExecuteFn(self)
                                        end)

  PanelButtonFrame.PanelButtonLabel = Label
  PanelButtonFrame.WoWUI = true
  PanelButtonFrame.SetTooltip = function(self, Name, Description)
                                  Main:SetTooltip(self, Name, Description)
                                end
  PanelButtonFrame.SetEnabled = SetControlEnabled

  return PanelButtonFrame
end

-------------------------------------------------------------------------------
-- CreateControlWindow
--
-- Creates a window on screen that can be dragged around.
--
-- Usage: Frame = CreateControlWindow(Point, Height, OffsetX, OffsetY, Width, WindowFn)
--
-- Point          'CENTER', 'LEFT', etc.
-- Width          Window width.
-- Height         Window Height.
-- OffsetX        Horizontal offset from Point.
-- OffsetY        Vertical offset from point.
-- Frame          Contains the window.
-- WindowFn       Gets called when the window is closed.
--                Event gets passed .  Which can have one of two values:
--                'close'    Close button was clicked.
--                'show'     Window was shown. By Frame:Show()
--
-- Frame.ControlPaneFrame    Contains the frame for the window pane.
-------------------------------------------------------------------------------
function GUB.WoWUI:CreateControlWindow(Point, Height, OffsetX, OffsetY, Width, WindowFn)

  -- Create control window.
  local ControlWindowFrame = CreateFrame('Frame', nil, UIParent)
  ControlWindowFrame:SetMovable(true)
  ControlWindowFrame:SetToplevel(true)
  ControlWindowFrame:SetClampedToScreen(true)
  ControlWindowFrame:SetPoint(Point, OffsetX, OffsetY)
  ControlWindowFrame:SetWidth(Width)
  ControlWindowFrame:SetHeight(Height)
  ControlWindowFrame:SetBackdrop(ControlWindowBackdrop)
  ControlWindowFrame:SetBackdropColor(0, 0, 0, 1)

  -- Create the close window button.
  local CloseWindowButton = WoWUI:CreatePanelButton(ControlWindowFrame, 'Close', 'BOTTOMRIGHT', '', -7, 7, 90,
                                                      function(self)
                                                        WindowFn(ControlWindowFrame, 'close')
                                                      end)

  -- Create the control pane.
  local ControlPaneFrame = CreateFrame('Frame', nil, ControlWindowFrame)
  ControlPaneFrame:SetPoint('TOPLEFT', 10, -10)
  ControlPaneFrame:SetPoint('RIGHT', -10, 0)
  ControlPaneFrame:SetPoint('BOTTOM', CloseWindowButton, 'TOP', 0, 5)
  ControlPaneFrame:SetBackdrop(PaneBackdrop)
  ControlPaneFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
  ControlPaneFrame:SetBackdropBorderColor(0.4, 0.4, 0.4)

  -- Set the control window scripts.
  ControlWindowFrame:SetScript('OnMouseDown', function(self, Button)
                                                self:StartMoving()
                                              end)
  ControlWindowFrame:SetScript('OnMouseUp', function(self, Button)
                                              self:StopMovingOrSizing()
                                            end)
  ControlWindowFrame:SetScript('OnShow', function(self)
                                         WindowFn(ControlWindowFrame, 'show')
                                       end)
  ControlWindowFrame:SetScript('OnHide', function(self)
                                         WindowFn(ControlWindowFrame, 'hide')
                                       end)

  ControlWindowFrame.ControlPaneFrame = ControlPaneFrame

  return ControlWindowFrame
end
