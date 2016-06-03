-- Controls.lua

-- Contains custom controls.
--
-- Spell predictor    Modified from AceGUI-3.0-Spell-EditBox
-- Menu Button        Button thats part menu and part button. Used by triggers
-- Flex Button        Button that can be flexible in side.  Also can be left/center/right justified.
-- Editbox Selected   An edit box that automatically selects what's in it.
-- Spell Info         Shows a tooltip when moused over.  Also shows an icon with text next to it.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...
local Main = GUB.Main

local LSM = Main.LSM

local AceGUI = LibStub('AceGUI-3.0')

-- localize some globals.
local GetSpellInfo, SPELL_PASSIVE, ipairs, pairs, type, tonumber, CreateFrame, select, floor, strlower, strfind, strsplit, format, tinsert, print, sort =
      GetSpellInfo, SPELL_PASSIVE, ipairs, pairs, type, tonumber, CreateFrame, select, floor, strlower, strfind, strsplit, format, tinsert, print, sort
local table, GameTooltip, ClearOverrideBindings, SetOverrideBindingClick, GetCursorInfo, GetSpellBookItemName, PlaySound, CreateFont =
      table, GameTooltip, ClearOverrideBindings, SetOverrideBindingClick, GetCursorInfo, GetSpellBookItemName, PlaySound, CreateFont
local ClearCursor, GameTooltip, UIParent, GameFontHighlight, GameFontNormal, GameFontDisable, GameFontHighlight, ChatFontNormal, OKAY =
      ClearCursor, GameTooltip, UIParent, GameFontHighlight, GameFontNormal, GameFontDisable, GameFontHighlight, ChatFontNormal, OKAY
local C_TradeSkillUIGetTradeSkillLineForRecipe,  GetTime  =
      C_TradeSkillUI.GetTradeSkillLineForRecipe, GetTime

-------------------------------------------------------------------------------
-- Locals
--
-- SpellList         Contains a list of loaded spells used in the editbox.
-- SpellsLoaded      if true then spells are already loaded.
-- SpellsPerRun      Amount of spells to load at one time.
-- Predictorlines    Amount of lines the predictor uses.
-- MenuLines         How many lines to show without a scroll bar.
-- MenuFrameWidth    Width of the menu in pixels.
-- MenuButtonHeight  Height of the menu buttons in pixels.
-- FlexButtonHeight  Height of the flex buttons in pixels.
-- MenuArrowSize     Size of the menu arrow in pixels.
-- Predictors        Table that keeps track of predictor frames.
--                   The keyname is the Frame and the value is true or nil
-------------------------------------------------------------------------------
local SpellsTPS = 0.10 -- 10 times per second.
local SpellsPerRun = 1000
local SpellsLoaded = false
local Tooltip = nil
local HyperLinkSt = 'spell:%s'

local PredictorLines = 100
local MenuLines = 10
local MenuFrameWidth = 200
local MenuArrowSize = 32 / 2.7
local MenuBulletSize = 32 / 3.5
local MenuButtonHeight = 24
local FlexButtonHeight = 24
local TextButtonHeight = 24
local TextButtonHL = {r = 0.3, g = 0.3, b = 0.3}


local EditBoxWidgetVersion = 1
local AuraEditBoxWidgetVersion = 1
local MenuButtonWidgetVersion = 1
local FlexButtonWidgetVersion = 1
local EditBoxSelectedWidgetVersion = 1
local SpellInfoWidgetVersion = 1
local TextButtonWidgetVersion = 1

local EditBoxWidgetType = 'GUB_Predictor_Base'
local AuraEditBoxWidgetType = 'GUB_Aura_EditBox'
local MenuButtonWidgetType = 'GUB_Menu_Button'
local FlexButtonWidgetType = 'GUB_Flex_Button'
local EditBoxSelectedWidgetType = 'GUB_EditBox_Selected'
local SpellInfoWidgetType = 'GUB_Spell_Info'
local TextButtonWidgetType = 'GUB_Text_Button'

local MenuOpenedIcon        = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_MenuOpened.tga]]
local MenuClosedIcon        = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_MenuClosed.tga]]
local MenuBulletIcon        = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_MenuBullet.tga]]

local SpellsTimer = {}
local SpellList = {}
local Predictors = {}
local SpellFilterCache = {}

local PredictorBackdrop = {
  bgFile   = [[Interface\ChatFrame\ChatFrameBackground]],
  edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
  edgeSize = 26,
  insets = {
    left = 9 ,
    right = 9,
    top = 9,
    bottom = 9,
  },
}

local SliderBackdrop = {
  bgFile = [[Interface\Buttons\UI-SliderBar-Background]],
  edgeFile = [[Interface\Buttons\UI-SliderBar-Border]],
  tile = true,
  edgeSize = 8,
  tileSize = 8,
  insets = {
    left = 3,
    right = 3,
    top = 3,
    bottom = 3,
  },
}

local MenuButtonBorder = {
  bgFile   = LSM:Fetch('background', 'Blizzard Rock'),
  edgeFile = LSM:Fetch('border', 'Blizzard Dialog'),
  tile = false,
  tileSize = 16,
  edgeSize = 16,
  insets = {
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

local MenuButtonHighlightBorder = {
  bgFile   = LSM:Fetch('background', 'Blizzard Rock'),
  edgeFile = [[Interface\AddOns\GalvinUnitBars\Textures\GUB_MenuHighlightBorder]],
  tile = false,
  tileSize = 16,
  edgeSize = 16,
  insets = {
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

local TextButtonBorder = {
  bgFile   = LSM:Fetch('background', 'Blizzard Tooltip'),
  edgeFile = LSM:Fetch('border', 'Blizzard Tooltip'),
  tile = false,
  tileSize = 16,
  edgeSize = 16,
  insets = {
    left = 4 ,
    right = 4,
    top = 4,
    bottom = 4
  }
}

--*****************************************************************************
--
-- Spell utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- RegisterSpellPredictor
--
-- Frame    Frame that will contain the predicted spells
-------------------------------------------------------------------------------
local function RegisterSpellPredictor(Frame)
  Predictors[Frame] = true
end

-------------------------------------------------------------------------------
-- UnegisterSpellPredictor
--
-- Frame    Frame that will no longer contain the predicted spells
-------------------------------------------------------------------------------
local function UnregisterSpellPredictor(Frame)
  Predictors[Frame] = nil
end

-------------------------------------------------------------------------------
-- LoadSpells
--
-- Loads spells just once.  This is used for the predictor.
-------------------------------------------------------------------------------
local function LoadSpells()
  if not SpellsLoaded then
    local TotalInvalid = 0
    local CurrentIndex = 0
    local NumSpells = 0
    local LastTime = GetTime()

    local function LoadSpells(self)

      -- 5,000 invalid spells in a row means it's a safe assumption that there are no more spells to query
      if TotalInvalid >= 5000 then
        Main:SetTimer(self, nil)
        return
      end

      -- Load as many spells in
      for SpellID = CurrentIndex + 1, CurrentIndex + SpellsPerRun do
        local Name, SubName, Icon = GetSpellInfo(SpellID)

        -- Filter out all trade skill spells.
        -- Passive can't really be used, so filter out those too.
        if Name and Name ~= '' and SubName ~= SPELL_PASSIVE and C_TradeSkillUIGetTradeSkillLineForRecipe(SpellID) == nil then
          NumSpells = NumSpells + 1
          SpellList[SpellID] = strlower(Name)

          TotalInvalid = 0
        else
          TotalInvalid = TotalInvalid + 1
        end
      end

      -- Every 1 second it will update any visible predictors to make up for the fact that the data is delay loaded
      local Time = GetTime()
      if Time - LastTime >= 1 then
        LastTime = Time
        for Frame in pairs(Predictors) do
          if Frame:IsVisible() then
            Frame:PopulatePredictor()
          end
        end
      end

      -- Increment and do it all over!
      CurrentIndex = CurrentIndex + SpellsPerRun
    end

    Main:SetTimer(SpellsTimer, LoadSpells, SpellsTPS)
    SpellsLoaded = true
  end
end

--*****************************************************************************
--
-- Editbox for the predictor
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- ScrollerOnMouseWheel
--
-- Scrolls the menu up or down based on the mouse wheel
-------------------------------------------------------------------------------
local function ScrollerOnMouseWheel(self, Dir)
  local Scroller = self.Scroller

  Scroller:SetValue(Scroller:GetValue() + 17 * 3 * Dir * -1)
end

-------------------------------------------------------------------------------
-- HideScroller
--
-- Hides the scroll and disabled mouse wheel event.
-------------------------------------------------------------------------------
local function HideScroller(PredictFrame, Hide)
  local ScrollFrame = PredictFrame.ScrollFrame
  local Scroller = PredictFrame.Scroller
  local MenuFrame = PredictFrame.MenuFrame

  if Hide then
    Scroller:SetValue(0)
    Scroller:Hide()
    ScrollFrame:SetPoint('BOTTOMRIGHT', -9, 6)
    MenuFrame:SetScript('OnMouseWheel', nil)
  else
    Scroller:Show()
    ScrollFrame:SetPoint('TOPLEFT', 0, -10)
    ScrollFrame:SetPoint('BOTTOMRIGHT', -28, 10)
    MenuFrame:SetScript('OnMouseWheel', ScrollerOnMouseWheel)
  end
end

------------------------------------------------------------------------------
-- OnAcquire
--
-- Gets called after a new widget is created or reused.
------------------------------------------------------------------------------
local function OnAcquire(self)
  self:SetHeight(26)
  self:SetWidth(200)
  self:SetDisabled(false)
  self:SetLabel()
  self.showButton = true

  RegisterSpellPredictor(self.PredictFrame)
  LoadSpells()
end

------------------------------------------------------------------------------
-- OnRelease
--
-- Gets called when the widget is released
------------------------------------------------------------------------------
local function OnRelease(self)
  local Frame = self.frame

  Frame:ClearAllPoints()
  Frame:Hide()
  self.PredictFrame.MenuFrame:Hide()
  self.SpellFilter = nil

  self:SetDisabled(false)

  UnregisterSpellPredictor(self.PredictFrame)
end

-------------------------------------------------------------------------------
-- EditBoxOnEnter
--
-- Gets called when the mouse enters the edit box.
-------------------------------------------------------------------------------
local function EditBoxOnEnter(self)
  self.Widget:Fire('OnEnter')
end

-------------------------------------------------------------------------------
-- EditBoxOnLeave
--
-- Gets called when the mouse leaves the edit box.
-------------------------------------------------------------------------------
local function EditBoxOnLeave(self)
  self.Widget:Fire('OnLeave')
end

-------------------------------------------------------------------------------
-- AddPredictorButton
--
-- Adds a button to the predictor frame
--
-- ActiveButton    Button position to add one at.
-- FormatText      Format string
-- SpellID         SpellID to add to button
-------------------------------------------------------------------------------
local function AddPredictorButton(self, ActiveButton, FormatText, SpellID)

  -- Ran out of text to suggest :<
  local Button = self.Buttons[ActiveButton]
  local Name, _, Icon = GetSpellInfo(SpellID)

  Button:SetFormattedText(FormatText, Icon, Name)
  Button.SpellID = SpellID
  Button:Show()

  -- Highlight if needed
  if ActiveButton ~= self.SelectedButton then
    Button:UnlockHighlight()

    if GameTooltip:IsOwned(Button) then
      GameTooltip:Hide()
    end
  end
end

-------------------------------------------------------------------------------
-- PopulatePredictor
--
-- Populates the predictor with a list of spells matching the spell name entered.
-------------------------------------------------------------------------------
local function SortMatches(a, b)
   return SpellList[a] < SpellList[b]
end

local function PopulatePredictor(self)
  local Widget = self.Widget
  local SearchSt = strlower(Widget.EditBox:GetText())
  local TrackedAurasList = Main.TrackedAurasList
  local Matches = {}
  local ActiveButtons = 0

  for _, Button in pairs(self.Buttons) do
    Button:Hide()
  end

  -- Do auras
  if TrackedAurasList then
    for SpellID, Aura in pairs(TrackedAurasList.All) do
      local Name = strlower(GetSpellInfo(SpellID))

      if strfind(Name, SearchSt, 1) == 1 then
        if ActiveButtons < PredictorLines then
          ActiveButtons = ActiveButtons + 1
          AddPredictorButton(self, ActiveButtons, '|T%s:15:15:2:11|t |cFFFFFFFF%s|r', SpellID)
        else
          break
        end
      end
    end
  end

  -- Do SpellList
  for SpellID, Name in pairs(SpellList) do
    if strfind(strlower(Name), SearchSt, 1) == 1 then
      local Found = TrackedAurasList and TrackedAurasList[SpellID] or nil

      Matches[#Matches + 1] = SpellID
    end
  end

  -- Sort only the spells from the SpellList
  sort(Matches, SortMatches)

  for _, SpellID in ipairs(Matches) do
    if ActiveButtons < PredictorLines then
      ActiveButtons = ActiveButtons + 1
      AddPredictorButton(self, ActiveButtons, '|T%s:15:15:2:11|t %s', SpellID)
    else
      break
    end
  end

  -- Set the size of the menu.
  local MenuFrame = self.MenuFrame

  if ActiveButtons > 0 then
    if ActiveButtons <= MenuLines then
      MenuFrame:SetHeight(20 + ActiveButtons * 17)
      HideScroller(self, true)
    else
      MenuFrame:SetHeight(20 + MenuLines * 17)
      self.Scroller:SetMinMaxValues(1, 18 + (ActiveButtons - MenuLines - 1) * 17)
      HideScroller(self, false)
    end
    MenuFrame:Show()
  else
    MenuFrame:Hide()
  end

  self.ActiveButtons = ActiveButtons
end

-------------------------------------------------------------------------------
-- PredictorShowButton
--
-- Shows the okay button in the editbox selector
-------------------------------------------------------------------------------
local function PredictorShowButton(self)
  if self.LastText ~= '' then
    self.PredictFrame.SelectedButton = nil
    PopulatePredictor(self.PredictFrame)
  else
    self.PredictFrame.MenuFrame:Hide()
  end

  if self.showButton then
    self.Button:Show()
    self.EditBox:SetTextInsets(0, 20, 3, 3)
  end
end

-------------------------------------------------------------------------------
-- PredictorHideButton
--
-- Hides the okay button in the editbox selector
-------------------------------------------------------------------------------
local function PredictorHideButton(self)
  self.Button:Hide()
  self.EditBox:SetTextInsets(0, 0, 3, 3)

  self.PredictFrame.SelectedButton = nil
  self.PredictFrame.MenuFrame:Hide()
end

-------------------------------------------------------------------------------
-- PredictorOnShow
--
-- Hides the predictor editbox and restores binds, tooltips
-------------------------------------------------------------------------------
local function PredictorOnShow(self)
  if self.EditBox:GetText() ~= '' then
    self.MenuFrame:Show()
  end
end

-------------------------------------------------------------------------------
-- PredictorOnHide
--
-- Hides the predictor editbox and restores binds, tooltips
-------------------------------------------------------------------------------
local function PredictorOnHide(self)

  -- Allow users to use arrows to go back and forth again without the fix
  self.Widget.EditBox:SetAltArrowKeyMode(false)

  -- Make sure the tooltip isn't kept open if one of the buttons was using it
  for _, Button in pairs(self.Buttons) do
    if GameTooltip:IsOwned(Button) then
      GameTooltip:Hide()
    end
  end

  self.SelectedButton = nil
  self.MenuFrame:Hide()


  -- Reset all bindings set on this predictor
  ClearOverrideBindings(self)
end

-------------------------------------------------------------------------------
-- EditBoxOnEnterPressed
--
-- Gets called when something is entered into the edit box
-------------------------------------------------------------------------------
local function EditBoxOnEnterPressed(self)
  local Widget = self.Widget
  local PredictFrame = Widget.PredictFrame

  -- Something is selected in the predictor, use that value instead of whatever is in the input box
  if PredictFrame.SelectedButton then
    PredictFrame.Buttons[Widget.PredictFrame.SelectedButton]:Click()
    return
  end

  local cancel = Widget:Fire('OnEnterPressed', self:GetText())
  if not cancel then
    PredictorHideButton(Widget)
  end

  -- Reactive the cursor, odds are if someone is adding spells they are adding more than one
  -- and if they aren't, it can't hurt anyway.
  -- Widget.EditBox:SetFocus()
end

-------------------------------------------------------------------------------
-- EditBoxOnEscapePressed
--
-- Gets called when esckey is pressed which clears the focus
-------------------------------------------------------------------------------
local function EditBoxOnEscapePressed(self)
  self:ClearFocus()
end

-------------------------------------------------------------------------------
-- EditBoxOnTextChanged
--
-- Gets called when the text changes in the edit box.
-------------------------------------------------------------------------------
local function EditBoxOnTextChanged(self)
  local Widget = self.Widget
  local Value = self:GetText()

  if Value ~= Widget.LastText then
    Widget:Fire('OnTextChanged', Value)
    Widget.LastText = Value

    PredictorShowButton(Widget)
  end
end

-------------------------------------------------------------------------------
-- EditBoxOnFocusGained
--
-- Gets called when the edit box loses focus
-------------------------------------------------------------------------------
local function EditBoxOnEditFocusGained(self)
  PredictorOnShow(self.Widget.PredictFrame)
end

-------------------------------------------------------------------------------
-- EditBoxOnFocusLost
--
-- Gets called when the edit box loses focus
-------------------------------------------------------------------------------
local function EditBoxOnEditFocusLost(self)
  PredictorOnHide(self.Widget.PredictFrame)
end

-------------------------------------------------------------------------------
-- EditBoxButtonOnclick
--
-- called when the 'edit' button in the edit box is clicked
-------------------------------------------------------------------------------
local function EditBoxButtonOnClick(self)
  EditBoxOnEnterPressed(self.Widget.EditBox)
end

--*****************************************************************************
--
-- Editbox for the predictor
-- API calls
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EditBoxSetDisabled
--
-- Disables the edit box
-------------------------------------------------------------------------------
local function EditBoxSetDisabled(self, Disabled)
  local EditBox = self.EditBox

  self.disabled = Disabled

  if Disabled then
    EditBox:EnableMouse(false)
    EditBox:ClearFocus()
    EditBox:SetTextColor(0.5, 0.5, 0.5)
    self.Label:SetTextColor(0.5, 0.5, 0.5)
  else
    EditBox:EnableMouse(true)
    EditBox:SetTextColor(1, 1, 1)
    self.Label:SetTextColor(1, 0.82, 0)
  end
end

-------------------------------------------------------------------------------
-- EditBoxSetText
--
-- Changes the text in the edit box
-------------------------------------------------------------------------------
local function EditBoxSetText(self, Text, Cursor)
  local EditBox = self.EditBox

  self.LastText = Text or ''
  EditBox:SetText(self.LastText)
  EditBox:SetCursorPosition(Cursor or 0)

  PredictorHideButton(self)
end

-------------------------------------------------------------------------------
-- EditBoxSetLabel
--
-- Sets the label on the edit box.
-------------------------------------------------------------------------------
local function EditBoxSetLabel(self, Text)
  local Label = self.Label

  if Text and Text ~= '' then
    Label:SetText(Text)
    Label:Show()
    self.EditBox:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 7, -18)
    self:SetHeight(44)
    self.alignoffset = 30
  else
    Label:SetText('')
    Label:Hide()
    self.EditBox:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 7, 0)
    self:SetHeight(26)
    self.alignoffset = 12
  end
end

-------------------------------------------------------------------------------
-- PredictorButtonOnClick
--
-- Sets the editbox to the button that was clicked in the selector
-------------------------------------------------------------------------------
local function PredictorButtonOnClick(self)
  local Name = GetSpellInfo(self.SpellID)
  local Parent = self.parent

  EditBoxSetText(self.parent.Widget, Name, #Name)

  Parent.SelectedButton = nil
  Parent.Widget:Fire('OnEnterPressed', Name, self.SpellID)
end

-------------------------------------------------------------------------------
-- PredictorButtonOnEnter
--
-- Highlights the predictor button when the mouse enters the button area
-------------------------------------------------------------------------------
local function PredictorButtonOnEnter(self)
  self.parent.SelectedButton = nil
  self:LockHighlight()
  local SpellID = self.SpellID

  GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 8)
  GameTooltip:SetHyperlink(format(HyperLinkSt, SpellID))
  GameTooltip:AddLine(format('|cFFFFFF00SpellID:|r|cFF00FF00%s|r', SpellID))

  -- Need to show to make sure the tooltip surrounds the AddLine text
  -- after SetHyperlink
  GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- PredictorButtonOnLeave
--
-- Highlights the predictor button when the mouse enters the button area
-------------------------------------------------------------------------------
local function PredictorButtonOnLeave(self)
  self:UnlockHighlight()
  GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- ScrollerOnValueChanged
--
-- Scrolls the menu up or down as the scroller gets dragged up or down
-------------------------------------------------------------------------------
local function ScrollerOnValueChanged(self, Value)
  self:GetParent():SetVerticalScroll(Value)
end

-------------------------------------------------------------------------------
-- CreateButton
--
-- Creates a button for the predictor frame.
--
-- PredictFrame       Frame the will contain the buttons
-- EditBox            Reference to the EditBox
-- Index              Button Index, needed for setpoint
--
-- Returns
--   Button           Created buttom.
-------------------------------------------------------------------------------
local function CreateButton(PredictFrame, EditBox, Index)
  local Buttons = PredictFrame.Buttons
  local Button = CreateFrame('Button', nil, PredictFrame)

  Button:SetHeight(17)
  Button:SetWidth(1)
  Button:SetPushedTextOffset(-2, 0)
  Button:SetScript('OnClick', PredictorButtonOnClick)
  Button:SetScript('OnEnter', PredictorButtonOnEnter)
  Button:SetScript('OnLeave', PredictorButtonOnLeave)
  Button.parent = PredictFrame
  Button.EditBox = EditBox
  Button:Hide()

  if Index > 1 then
    Button:SetPoint('TOPLEFT', Buttons[Index - 1], 'BOTTOMLEFT')
    Button:SetPoint('TOPRIGHT', Buttons[Index - 1], 'BOTTOMRIGHT')
  else
    Button:SetPoint('TOPLEFT', PredictFrame, 12, -1)
    Button:SetPoint('TOPRIGHT', PredictFrame, -7, 0)
  end

  -- Create the actual text
  local Text = Button:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  Text:SetHeight(1)
  Text:SetWidth(1)
  Text:SetJustifyH('LEFT')
  Text:SetAllPoints(Button)
  Button:SetFontString(Text)

  -- Setup the highlighting
  local Texture = Button:CreateTexture(nil, 'ARTWORK')
  Texture:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
  Texture:ClearAllPoints()
  Texture:SetPoint('TOPLEFT', Button, 0, -2)
  Texture:SetPoint('BOTTOMRIGHT', Button, 5, 2)
  Texture:SetAlpha(0.70)

  Button:SetHighlightTexture(Texture)
  Button:SetHighlightFontObject(GameFontHighlight)
  Button:SetNormalFontObject(GameFontNormal)

  return Button
end

-------------------------------------------------------------------------------
-- PredictorConstructor
--
-- Creates the widget for the edit box and predictor
-------------------------------------------------------------------------------
local function PredictorConstructor()
  local Frame = CreateFrame('Frame', nil, UIParent)
  local EditBox = CreateFrame('EditBox', nil, Frame, 'InputBoxTemplate')

  -- Don't feel like looking up the specific callbacks for when a widget resizes, so going to be creative with SetPoint instead!
  local MenuFrame = CreateFrame('Frame', nil, UIParent)
  MenuFrame:SetBackdrop(PredictorBackdrop)
  MenuFrame:SetBackdropColor(0, 0, 0, 0.85)
  MenuFrame:SetWidth(1)
  MenuFrame:SetHeight(150)
  MenuFrame:SetPoint('TOPLEFT', EditBox, 'BOTTOMLEFT', -6, 0)
  MenuFrame:SetWidth(MenuFrameWidth)
  MenuFrame:SetFrameStrata('TOOLTIP')
  MenuFrame:SetClampedToScreen(true)
  MenuFrame:Hide()

  -- Create the scroll frame
  local ScrollFrame = CreateFrame('ScrollFrame', nil, MenuFrame)
  ScrollFrame:SetPoint('TOPLEFT', 0, -6)
  ScrollFrame:SetPoint('BOTTOMRIGHT', -28, 6)

    local PredictFrame = CreateFrame('Frame', nil, ScrollFrame)
    local Buttons = {}

    PredictFrame:SetSize(MenuFrameWidth, 2000)
    PredictFrame.PopulatePredictor = PopulatePredictor
    PredictFrame.EditBox = EditBox
    PredictFrame.Buttons = Buttons
    PredictFrame.MenuFrame = MenuFrame
    PredictFrame.ScrollFrame = ScrollFrame

  ScrollFrame:SetScrollChild(PredictFrame)

  -- Create the scroller
  local Scroller = CreateFrame('slider', nil, ScrollFrame)
  Scroller:SetOrientation('VERTICAL')
  Scroller:SetPoint('TOPRIGHT', MenuFrame, 'TOPRIGHT', -12, -7)
  Scroller:SetPoint('BOTTOMRIGHT', MenuFrame, 'BOTTOMRIGHT', -12, 7)
  Scroller:SetBackdrop(SliderBackdrop)
  Scroller:SetThumbTexture( [[Interface\Buttons\UI-SliderBar-Button-Vertical]] )
  Scroller:SetMinMaxValues(0, 1)
  Scroller:SetWidth(12)
  Scroller:SetValueStep(1)
  Scroller:SetValue(0)
  Scroller:SetScript('OnValueChanged', ScrollerOnValueChanged)

  MenuFrame.Scroller = Scroller
  PredictFrame.Scroller = Scroller

  -- Create the mass of predictor rows
  for Index = 1, PredictorLines + 1 do
    Buttons[Index] = CreateButton(PredictFrame, EditBox, Index)
  end

  -- Set the main info things for this thingy
  local Widget = {}

  Widget.type = EditBoxWidgetType
  Widget.frame = Frame

  Widget.OnRelease = OnRelease
  Widget.OnAcquire = OnAcquire

  Widget.SetDisabled = EditBoxSetDisabled
  Widget.SetText = EditBoxSetText
  Widget.SetLabel = EditBoxSetLabel

  Widget.PredictFrame = PredictFrame
  Widget.EditBox = EditBox

  Widget.alignoffset = 30

  Frame:SetHeight(44)
  Frame:SetWidth(200)

  Frame.Widget = Widget
  EditBox.Widget = Widget
  PredictFrame.Widget = Widget

  EditBox:SetScript('OnEnter', EditBoxOnEnter)
  EditBox:SetScript('OnLeave', EditBoxOnLeave)

  EditBox:SetAutoFocus(false)
  EditBox:SetFontObject(ChatFontNormal)
  EditBox:SetScript('OnEscapePressed', EditBoxOnEscapePressed)
  EditBox:SetScript('OnEnterPressed', EditBoxOnEnterPressed)
  EditBox:SetScript('OnTextChanged', EditBoxOnTextChanged)
  EditBox:SetScript('OnEditFocusGained', EditBoxOnEditFocusGained)
  EditBox:SetScript('OnEditFocusLost', EditBoxOnEditFocusLost)

  EditBox:SetTextInsets(0, 0, 3, 3)
  EditBox:SetMaxLetters(256)

  EditBox:SetPoint('BOTTOMLEFT', Frame, 'BOTTOMLEFT', 6, 0)
  EditBox:SetPoint('BOTTOMRIGHT', Frame, 'BOTTOMRIGHT')
  EditBox:SetHeight(19)

  local Label = Frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  Label:SetPoint('TOPLEFT', Frame, 'TOPLEFT', 0, -2)
  Label:SetPoint('TOPRIGHT', Frame, 'TOPRIGHT', 0, -2)
  Label:SetJustifyH('LEFT')
  Label:SetHeight(18)

  Widget.Label = Label

  local Button = CreateFrame('Button', nil, EditBox, 'UIPanelButtonTemplate')
  Button:SetPoint('RIGHT', EditBox, 'RIGHT', -2, 0)
  Button:SetScript('OnClick', EditBoxButtonOnClick)
  Button:SetWidth(40)
  Button:SetHeight(20)
  Button:SetText(OKAY)
  Button:Hide()

  Widget.Button = Button
  Button.Widget = Widget

  AceGUI:RegisterAsWidget(Widget)

  return Widget
end

--*****************************************************************************
--
-- Aura_EditBox dialog control
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- AuraEditBoxConstructor
--
-- Creates the widget for the Aura_EditBox
--
-- I know theres a better way of doing this than this, but not sure for the time being, works fine though!
-------------------------------------------------------------------------------
local function AuraEditBoxConstructor()
  return AceGUI:Create(EditBoxWidgetType)
end

AceGUI:RegisterWidgetType(EditBoxWidgetType, PredictorConstructor, EditBoxWidgetVersion)
AceGUI:RegisterWidgetType(AuraEditBoxWidgetType, AuraEditBoxConstructor, AuraEditBoxWidgetVersion)

--*****************************************************************************
--
-- Menu_Button util
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SetMenuIcon
--
-- Sets the menu arrow to opened, closed or none.  Disabled or enabled.
--
-- ButtonFrame    Frame to position arrow on.
-- State          '0', '1', '2'
-------------------------------------------------------------------------------
local function SetMenuIcon(ButtonFrame, State)
  local MenuIcon = nil
  local MenuIconSize = nil
  local MenuArrowClosed = ButtonFrame.MenuArrowClosed
  local MenuArrowOpened = ButtonFrame.MenuArrowOpened
  local MenuBullet = ButtonFrame.MenuBullet

  if State == '0' then -- arrow closed
    MenuIconSize = MenuArrowSize
    MenuIcon = ButtonFrame.MenuArrowClosed
    MenuArrowOpened:Hide()
    MenuBullet:Hide()
  elseif State == '1' then -- arrow open
    MenuIconSize = MenuArrowSize
    MenuIcon = ButtonFrame.MenuArrowOpened
    MenuArrowClosed:Hide()
    MenuBullet:Hide()
  elseif State == '2' then -- show bullet
    MenuIconSize = MenuBulletSize
    MenuIcon = ButtonFrame.MenuBullet
    MenuArrowOpened:Hide()
    MenuArrowClosed:Hide()
  end

  if State == '' then
    MenuArrowOpened:Hide()
    MenuArrowClosed:Hide()
    MenuBullet:Hide()
  else
    MenuIcon:Show()

    -- Calc center position
    local Center = (MenuButtonHeight - MenuIconSize) / 2

    MenuIcon:SetPoint('TOPLEFT', 9, Center * -1)
  end
end

--*****************************************************************************
--
-- Menu_Button dialog control
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- MenuButtonOnAcquire
--
-- Gets called when the menu button is visible on screen.
--
-- self   Widget
-------------------------------------------------------------------------------
local function MenuButtonOnAcquire(self)
  self:SetHeight(MenuButtonHeight)
  self:SetDisabled(false)
end

-------------------------------------------------------------------------------
-- MenuButtonDisable
--
-- Gets called if the options disables/enables the menu button.
--
-- self        Widget
-- Disabled    If true then disabled, otherwise false
-------------------------------------------------------------------------------
local function MenuButtonDisable(self, Disabled)
  local ButtonFrame = self.ButtonFrame

  if Disabled then
    ButtonFrame:Disable()
    SetMenuIcon(ButtonFrame, '')
  else
    ButtonFrame:Enable()
  end
end

-------------------------------------------------------------------------------
-- MenuButtonOnEnterPressed
--
-- Gets called if the menu button gets clicked
-------------------------------------------------------------------------------
local function MenuButtonOnEnterPressed(self, ...)
  AceGUI:ClearFocus()
  PlaySound('igMainMenuOption')
  self.Widget:Fire('OnEnterPressed', ...)
end


local function MenuButtonOnEnter(self)
  self:SetBackdrop(MenuButtonHighlightBorder)
  self:SetBackdropColor(0.45, 0.45, 0.45, 1)
  self:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
end

local function MenuButtonOnLeave(self)
  self:SetBackdrop(MenuButtonBorder)
  self:SetBackdropColor(0.45, 0.45, 0.45, 1)
end

-------------------------------------------------------------------------------
-- MenuButtonSetLabel
--
-- Sets the text for the menu button
--
-- self   Widget
-- Text   Text to display
--
-- Text also takes the state. Example: <text>:0 or 1
-------------------------------------------------------------------------------
local function MenuButtonSetLabel(self, Text)
  local ButtonFrame = self.ButtonFrame
  local Text, State = strsplit(':', Text)

  ButtonFrame:SetText('       ' .. Text)

  SetMenuIcon(ButtonFrame, State or '')
end

-------------------------------------------------------------------------------
-- MenuButtonConstructor
--
-- Creates the button for the ace options to use.
--
-- To use this in ace-config.  Use type = 'input', and then use set to respond
-- To mouse clicks on the button.
--
-- To set the state use: 'Menu:#' # = 0 closed, # = 1 opened, # = 2 bullet
-------------------------------------------------------------------------------
local function MenuButtonConstructor()
  local Frame = CreateFrame('Frame', nil, UIParent)
  local ButtonFrame = CreateFrame('Button', nil, Frame)
  local Widget = {}

  ButtonFrame:SetBackdrop(MenuButtonBorder)
  ButtonFrame:SetBackdropColor(0.45, 0.45, 0.45, 1)

  -- Need this so there is space between each control.
  ButtonFrame:SetPoint('TOPLEFT', 1, 0)
  ButtonFrame:SetPoint('BOTTOMRIGHT', -1, 0)

  -- Create font text for enabled, disabled, and highlight
  local FontNormal = CreateFont('GUB_FontNormal')
  FontNormal:SetFontObject(GameFontNormal)
  FontNormal:SetJustifyH('LEFT')
  ButtonFrame:SetNormalFontObject(FontNormal)

  local FontDisable = CreateFont('GUB_FontDisable')
  FontDisable:SetFontObject(GameFontDisable)
  FontDisable:SetJustifyH('LEFT')
  ButtonFrame:SetDisabledFontObject(FontDisable)

  local FontHighlight = CreateFont('GUB_FontHighlight')
  FontHighlight:SetFontObject(GameFontHighlight)
  FontHighlight:SetJustifyH('LEFT')
  ButtonFrame:SetHighlightFontObject(FontHighlight)

  -- Create menu arrows
  local MenuArrowOpened = ButtonFrame:CreateTexture(nil, 'OVERLAY')
  MenuArrowOpened:SetTexture(MenuOpenedIcon)

  local MenuArrowClosed = ButtonFrame:CreateTexture(nil, 'OVERLAY')
  MenuArrowClosed:SetTexture(MenuClosedIcon)

  local MenuBullet = ButtonFrame:CreateTexture(nil, 'OVERLAY')
  MenuBullet:SetTexture(MenuBulletIcon)
  MenuBullet:Hide()

  -- Set size and color of menu arrows
  MenuArrowOpened:SetSize(MenuArrowSize, MenuArrowSize)
  MenuArrowClosed:SetSize(MenuArrowSize, MenuArrowSize)
  MenuBullet:SetSize(MenuBulletSize, MenuBulletSize)

  MenuArrowOpened:SetVertexColor(0.75, 0.75, 0.75, 1)
  MenuArrowClosed:SetVertexColor(0.75, 0.75, 0.75, 1)
  MenuBullet:SetVertexColor(0.75, 0.75, 0.75, 1)

  ButtonFrame.MenuArrowOpened = MenuArrowOpened
  ButtonFrame.MenuArrowClosed = MenuArrowClosed
  ButtonFrame.MenuBullet = MenuBullet


  ButtonFrame:SetScript('OnClick', MenuButtonOnEnterPressed)
  ButtonFrame:SetScript('OnEnter', MenuButtonOnEnter)
  ButtonFrame:SetScript('OnLeave', MenuButtonOnLeave)


  ButtonFrame.Widget = Widget


  Widget.frame = Frame
  Widget.type = MenuButtonWidgetType
  Widget.ButtonFrame = ButtonFrame

  Widget.OnAcquire = MenuButtonOnAcquire

  -- Set functions for ace config dialog
  Widget.SetDisabled = MenuButtonDisable
  Widget.SetLabel = MenuButtonSetLabel
  Widget.SetText = function() end

  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(MenuButtonWidgetType, MenuButtonConstructor, MenuButtonWidgetVersion)

--*****************************************************************************
--
-- Flex_Button dialog control
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- FlexButtonOnAcquire
--
-- Gets called when the flex button is visible on screen.
--
-- self   Widget
-------------------------------------------------------------------------------
local function FlexButtonOnAcquire(self)
  self:SetHeight(24)
  self:SetWidth(200)
  self:SetDisabled(false)
end

-------------------------------------------------------------------------------
-- FlexButtonDisable
--
-- Gets called if the options disables/enables the flex button.
--
-- self        Widget
-- Disabled    If true then disabled, otherwise false
--------------------------------------------------------------------------
local function FlexButtonDisable(self, Disabled)
  local ButtonFrame = self.ButtonFrame

  if Disabled then
    ButtonFrame:Disable()
  else
    ButtonFrame:Enable()
  end
end

-------------------------------------------------------------------------------
-- FlexButtonSetLabel
--
-- Sets the text for the flex button
--
-- self   Widget
-- Text   Text to display
-------------------------------------------------------------------------------
local function FlexButtonSetLabel(self, Text)
  self.ButtonFrame:SetText(Text)
end

-------------------------------------------------------------------------------
-- FlexButtonSetCommand
--
-- Changes the flex button based on the command
--
-- self      Widget
-- Command   Command in the form of Command,Width
-------------------------------------------------------------------------------
local function FlexButtonSetCommand(self, Command)
  local Command, Width = strsplit(',', Command or '')
  local ButtonFrame = self.ButtonFrame

  if Width then
    ButtonFrame:SetWidth(Width)
  end

  ButtonFrame:ClearAllPoints()
  self.ButtonFrame:SetHeight(FlexButtonHeight)

  if Command == 'L' then
    ButtonFrame:SetPoint('TOPLEFT')
  elseif Command == 'R' then
    ButtonFrame:SetPoint('TOPRIGHT')
  elseif Command == 'C' then
    ButtonFrame:SetPoint('CENTER')
  end
end

-------------------------------------------------------------------------------
-- FlexButtonOnEnterPressed
--
-- Gets called when the flex button gets clicked
-------------------------------------------------------------------------------
local function FlexButtonOnEnterPressed(self, ...)
  AceGUI:ClearFocus()
  PlaySound('igMainMenuOption')
  self.Widget:Fire('OnEnterPressed', ...)
end

-------------------------------------------------------------------------------
-- FlexButtonOnEnter
--
-- Gets called when mousing over the flex button
-------------------------------------------------------------------------------
local function FlexButtonOnEnter(self)
  self.Widget:Fire('OnEnter', 'test')
end

-------------------------------------------------------------------------------
-- FlexButtonOnLeave
--
-- Gets called when the mouse leaves the flex button
-------------------------------------------------------------------------------
local function FlexButtonOnLeave(self)
  self.Widget:Fire('OnLeave')
end

-------------------------------------------------------------------------------
-- MenuButtonConstructor
--
-- Creates the flex button for ace options to use.
--
-- To use this in ace-config.  Use type = 'input', and then use set to respond
-- To mouse clicks on the button.
--
-- in 'get' you can specify commands in the format of text:commands
-- Commands are 'L' button will be left justified
--              'R' Button will be right justified
--              'C' Button will be in the center
--              A length paramater can be specified using a comma
-- Example   text:L,23  Left justified and 23 pixels wide.
-------------------------------------------------------------------------------
local function FlexButtonConstructor()
  local Frame = CreateFrame('Frame', nil, UIParent)
  local ButtonFrame = CreateFrame('Button', nil, Frame, 'UIPanelButtonTemplate')
  local Widget = {}

  -- Need this so there is space between each control.
  ButtonFrame:SetPoint('TOPLEFT')
  ButtonFrame:SetPoint('BOTTOMRIGHT')

  ButtonFrame:EnableMouse(true)
  ButtonFrame:SetScript('OnClick', FlexButtonOnEnterPressed)
  ButtonFrame:SetScript('OnEnter', FlexButtonOnEnter)
  ButtonFrame:SetScript('OnLeave', FlexButtonOnLeave)

  ButtonFrame.Widget = Widget

  local Text = ButtonFrame:GetFontString()
  Text:ClearAllPoints()
  Text:SetPoint('TOPLEFT', 15, -1)
  Text:SetPoint('BOTTOMRIGHT', -15, 1)
  Text:SetJustifyV('MIDDLE')


  Widget.frame = Frame
  Widget.type = FlexButtonWidgetType
  Widget.ButtonFrame = ButtonFrame

  Widget.OnAcquire = FlexButtonOnAcquire

  -- Set functions for ace config dialog
  Widget.SetDisabled = FlexButtonDisable
  Widget.SetLabel = FlexButtonSetLabel
  Widget.SetText = FlexButtonSetCommand

  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(FlexButtonWidgetType, FlexButtonConstructor, FlexButtonWidgetVersion)

--*****************************************************************************
--
-- Text_Button dialog control
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- TextButtonOnAcquire
--
-- Gets called when the text button is visible on screen.
--
-- self   Widget
-------------------------------------------------------------------------------
local function TextButtonOnAcquire(self)
  self:SetHeight(TextButtonHeight)
  self:SetDisabled(false)
end

-------------------------------------------------------------------------------
-- TextButtonDisable
--
-- Gets called if the options disables/enables the text button.
--
-- self        Widget
-- Disabled    If true then disabled, otherwise false
-------------------------------------------------------------------------------
local function TextButtonDisable(self, Disabled)
  local ButtonFrame = self.ButtonFrame

  if Disabled then
    ButtonFrame:Disable()
  else
    ButtonFrame:Enable()
  end
end

-------------------------------------------------------------------------------
-- TextButtonOnEnterPressed
--
-- Gets called if the text button gets clicked
-------------------------------------------------------------------------------
local function TextButtonOnEnterPressed(self, ...)
  AceGUI:ClearFocus()
  PlaySound('igMainMenuOption')
  self.Widget:Fire('OnEnterPressed', ...)
end

-------------------------------------------------------------------------------
-- TextButtonSetLabel
--
-- Sets the text for the button
--
-- self   Widget
-- Text   Text to display
-------------------------------------------------------------------------------
local function TextButtonSetLabel(self, Text)

  -- get color
  local rgb, Text = strsplit(':', Text, 2)
  local r, g, b = strsplit(',', rgb, 3)

  self.ButtonFrame.Text:SetText(Text)
  self.BorderFrame:SetBackdropBorderColor(r, g, b, 1)
end

-------------------------------------------------------------------------------
-- TextButtonOnEnter
--
-- Gets called when mousing over the text button
-------------------------------------------------------------------------------
local function TextButtonOnEnter(self)
  local Widget = self.Widget

  Widget.BorderFrame:SetBackdropColor(TextButtonHL.r, TextButtonHL.g, TextButtonHL.b, 1)
 -- Widget:Fire('OnEnter')
end

-------------------------------------------------------------------------------
-- TextButtonOnLeave
--
-- Gets called when the mouse leaves the flex button
-------------------------------------------------------------------------------
local function TextButtonOnLeave(self)
  local Widget = self.Widget

  Widget.BorderFrame:SetBackdropColor(0, 0, 0, 1)
 -- self.Widget:Fire('OnLeave')
end

-------------------------------------------------------------------------------
-- TextButtonConstructor
--
-- Creates a button that shows only text, no borders, etc.
--
-- To use this in ace-config.  Use type = 'input', and then use name = 'r,g,b:text'
-- to set the text of the button.
--
-- r,g,b is the color for red green and blue.
-------------------------------------------------------------------------------
local function TextButtonConstructor()
  local Frame = CreateFrame('Frame', nil, UIParent)
  local ButtonFrame = CreateFrame('Button', nil, Frame)
  local Widget = {}

  -- Need this so there is space between each control.
  ButtonFrame:SetAllPoints(Frame)
  ButtonFrame:EnableMouse(true)

  ButtonFrame:SetScript('OnEnter', TextButtonOnEnter)
  ButtonFrame:SetScript('OnLeave', TextButtonOnLeave)


  local BorderFrame = CreateFrame('Frame', nil, Frame)
  BorderFrame:SetPoint('TOPLEFT', 0, 3)
  BorderFrame:SetPoint('BOTTOMRIGHT', 0, -3)
  BorderFrame:SetBackdrop(TextButtonBorder)
  BorderFrame:SetBackdropColor(0, 0, 0, 1)
  BorderFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

  --BorderFrame:Hide()

  ButtonFrame.Widget = Widget

  -- Create text
  local Text = ButtonFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  Text:SetJustifyH('LEFT')
  Text:SetWordWrap(false)
  Text:SetPoint('TOPLEFT', 6, 0)
  Text:SetPoint('BOTTOMRIGHT', -6, 0)

  ButtonFrame:SetScript('OnClick', TextButtonOnEnterPressed)

  ButtonFrame.Text = Text

  Widget.frame = Frame
  Widget.type = TextButtonWidgetType
  Widget.ButtonFrame = ButtonFrame
  Widget.BorderFrame = BorderFrame

  Widget.OnAcquire = TextButtonOnAcquire

  -- Set functions for ace config dialog
  Widget.SetDisabled = TextButtonDisable
  Widget.SetLabel = TextButtonSetLabel
  Widget.SetText = function() end

  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(TextButtonWidgetType, TextButtonConstructor, TextButtonWidgetVersion)

--*****************************************************************************
--
-- Edit_Box_Selected dialog control
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EditBoxSelectedOnFocusGained
--
-- Overrides the original script so that the okay button can be hidden.
-------------------------------------------------------------------------------
local function EditBoxSelectedOnFocusGained(self)
  AceGUI:SetFocus(self.obj)
  self:HighlightText()
  self:SetCursorPosition(1000)

  -- Hide the okay button
  self.obj:DisableButton(true)
end

-------------------------------------------------------------------------------
-- EditBoxSelectedOnEscapePressed
--
-- Overrides the original script so that input can't be changed.
-------------------------------------------------------------------------------
local function EditBoxSelectedOnEscapePressed(self)
  AceGUI:ClearFocus()

  self:SetText(self.obj.lasttext or '')
end

-------------------------------------------------------------------------------
-- EditBoxSelectedConstructor
--
-- Creates an read only editbox that preselects all the text when clicked.
-------------------------------------------------------------------------------
local function EditBoxSelectedConstructor()
  local Widget = AceGUI:Create('EditBox')

  -- Set on focus to select text
  local EditBox = Widget.editbox
  EditBox:SetScript('OnEditFocusGained', EditBoxSelectedOnFocusGained)
  EditBox:SetScript('OnEditFocusLost', EditBoxSelectedOnEscapePressed)
  EditBox:SetScript('OnEscapePressed', EditBoxSelectedOnEscapePressed)
  EditBox:SetScript('OnTextChanged', nil)

  Widget.type = EditBoxSelectedWidgetType

  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(EditBoxSelectedWidgetType, EditBoxSelectedConstructor, EditBoxSelectedWidgetVersion)

--*****************************************************************************
--
-- Spell_Info dialog control
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- SpellInfoOnAcquire
--
-- Gets called when the spell info label is visible on screen.
--
-- self   Widget
-------------------------------------------------------------------------------
local function SpellInfoOnAcquire(self)
  self:SetHeight(24)
  self:SetWidth(200)
end

-------------------------------------------------------------------------------
-- SpellInfoSetLabel
--
-- Sets the spell icon, size, and text
--
-- See constructor for examples
--
-- self       Widget
-- Text       SpellID, size, and text
-------------------------------------------------------------------------------
local function SpellInfoSetLabel(self, Text)
  local SpellID, IconSize, FontSize, Text = strsplit(':', Text, 4)

  SpellID = tonumber(SpellID)
  IconSize = tonumber(IconSize)
  FontSize = tonumber(FontSize)

  -- Set up the icon and position
  local Name, _, Icon = GetSpellInfo(SpellID)
  local IconFrame = self.IconFrame
  local IconTexture = self.IconTexture
  local IconLabel = self.IconLabel

  IconTexture:SetTexture(Icon)
  IconFrame:SetSize(IconSize, IconSize)

  -- This sets the height of Widget.frame
  self:SetHeight(IconSize)

  -- Set the icon label
  IconLabel:SetFont(LSM:Fetch('font', 'Arial Narrow'), FontSize, 'NONE')
  IconLabel:ClearAllPoints()
  IconLabel:SetPoint('TOPLEFT', IconSize + 5, 0)
  IconLabel:SetPoint('BOTTOMRIGHT')
  IconLabel:SetText(format('%s %s', Name or '', Text or ''))

  -- Set spell ID for OnEnter
  IconFrame.SpellID = SpellID
end

-------------------------------------------------------------------------------
-- IconFrameOnEnter
--
-- Shows the spell info tool tip when the mouse is over the icon
--
-- self   IconFrame
-------------------------------------------------------------------------------
local function IconFrameOnEnter(self)
  local SpellID = self.SpellID

  GameTooltip:SetOwner(self, 'ANCHOR_RIGHT', 8)
  GameTooltip:SetHyperlink(format(HyperLinkSt, SpellID))
  GameTooltip:AddLine(format('|cFFFFFF00SpellID:|r|cFF00FF00%s|r', SpellID))

  -- Need to show to make sure the tooltip surrounds the AddLine text
  -- after SetHyperlink
  GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- IconFrameOnLeave
--
-- Removes the spell info tool tip when the mouse leaves the icon
--
-- self   IconFrame
-------------------------------------------------------------------------------
local function IconFrameOnLeave(self)
  GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- SpellInfoContructor
--
-- Creates an icon with text.  Can mouse over icon for spell info.
--
-- To use this in ace-config.  Use type = 'input'
-- In the 'name' field you specify the spell ID, iconsize, and fontsize, followed by text
-- Example:  10750:32:14:This is some text
--
-- Will show an icon of of storm bolt with a with and hight of 32. Fontsize will be 14.
-- And display 'This is some text' to the right of it.
-------------------------------------------------------------------------------
local function SpellInfoConstructor()
  local Frame = CreateFrame('Frame', nil, UIParent)
  local IconFrame = CreateFrame('Frame', nil, Frame)
  local IconTexture = IconFrame:CreateTexture(nil, 'BACKGROUND')
  local IconLabel = Frame:CreateFontString(nil, 'BACKGROUND')
  local Widget = {}

  IconFrame:SetScript('OnEnter', IconFrameOnEnter)
  IconFrame:SetScript('OnLeave', IconFrameOnLeave)

  IconLabel:SetJustifyH('LEFT')
  IconLabel:SetJustifyV('CENTER')

  IconFrame:SetPoint('TOPLEFT')
  IconTexture:SetAllPoints()

  Widget.frame = Frame
  Widget.type = SpellInfoWidgetType
  Widget.OnAcquire = SpellInfoOnAcquire

  Widget.IconFrame = IconFrame
  Widget.IconTexture = IconTexture
  Widget.IconLabel = IconLabel

  -- Set functions for ace config dialog
  Widget.SetLabel = SpellInfoSetLabel
  Widget.SetText = function() end

  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(SpellInfoWidgetType, SpellInfoConstructor, SpellInfoWidgetVersion)
