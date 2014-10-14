-- Spells.lua

-- Adds a spell predicter to aceconfig.  This work is from AceGUI-3.0-Spell-EditBox
-- changed to a non lib to work in my addon.
-- Further modifications were done.
-- This version returns the Name and SpellID
-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...
local Main = GUB.Main

local AceGUI = LibStub('AceGUI-3.0')

-- localize some globals.
local GetSpellInfo, SPELL_PASSIVE, pairs, type, CreateFrame, select, floor, strlower, strmatch, format, tinsert, print =
      GetSpellInfo, SPELL_PASSIVE, pairs, type, CreateFrame, select, floor, strlower, strmatch, format, tinsert, print
local table, GameTooltip, ClearOverrideBindings, SetOverrideBindingClick, GetCursorInfo, GetSpellBookItemName =
      table, GameTooltip, ClearOverrideBindings, SetOverrideBindingClick, GetCursorInfo, GetSpellBookItemName
local ClearCursor, GameTooltip, UIParent, GameFontHighlight, GameFontNormal, ChatFontNormal, OKAY =
      ClearCursor, GameTooltip, UIParent, GameFontHighlight, GameFontNormal, ChatFontNormal, OKAY

-------------------------------------------------------------------------------
-- Locals
--
-- SpellList         Contains a list of loaded spells used in the editbox.
-- SpellsLoaded      if true then spells are already loaded.
-- SpellsPerRun      Amount of spells to load at one time.
-- Predictorlines    Amount of lines the predictor uses.
-- Predictors        Table that keeps track of predictor frames.
--                   The keyname is the Frame and the value is true or nil
-------------------------------------------------------------------------------
local SpellsTPS = 0.10 -- 10 times per second.
local SpellsPerRun = 1000
local SpellsLoaded = false
local Tooltip = nil
local HyperLinkSt = 'spell:%s'

local PredictorLines = 20
local EditBoxWidgetVersion = 1
local AuraEditBoxWidgetVersion = 1

local EditBoxWidgetType = 'GUB_Predictor_Base'
local AuraEditBoxWidgetType = 'GUB_Aura_EditBox'

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
    bottom = 9
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

    local Exclude = {
      ['interface\\icons\\trade_alchemy'] = true,
      ['interface\\icons\\trade_blacksmithing'] = true,
      ['interface\\icons\\trade_brewpoison'] = true,
      ['interface\\icons\\trade_engineering'] = true,
      ['interface\\icons\\trade_engraving'] = true,
      ['interface\\icons\\trade_fishing'] = true,
      ['interface\\icons\\trade_herbalism'] = true,
      ['interface\\icons\\trade_leatherworking'] = true,
      ['interface\\icons\\trade_mining'] = true,
      ['interface\\icons\\trade_tailoring'] = true,
      ['interface\\icons\\temp'] = true,
    }

    local ScanTooltip = CreateFrame('GameTooltip')

    ScanTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
    for i = 1, 6 do
      ScanTooltip['TextLeft' .. i] = ScanTooltip:CreateFontString()
      ScanTooltip['TextRight' .. i] = ScanTooltip:CreateFontString()
      ScanTooltip:AddFontStrings(ScanTooltip['TextLeft' .. i], ScanTooltip['TextRight' .. i])
    end

    local function LoadSpells(self)

      -- 5,000 invalid spells in a row means it's a safe assumption that there are no more spells to query
      if TotalInvalid >= 5000 then
        Main:SetTimer(self, nil)
        return
      end

      -- Load as many spells in
      for SpellID = CurrentIndex + 1, CurrentIndex + SpellsPerRun do
        local Name, SubName, Icon = GetSpellInfo(SpellID)
        local IsAura = false

        -- Pretty much every profession spell uses Trade_* and 99% of the random spells use the Trade_Engineering icon
        -- we can safely exclude any of these spells as they are not needed. Can get away with this because things like
        -- Alchemy use two icons, the Trade_* for the actual crafted spell and a different icon for the actual buff
        -- Passive spells have no use as well, since they are well passive and can't actually be used
        if Name and Name ~= '' and Exclude[strlower(Icon)] == nil and SubName ~= SPELL_PASSIVE then

          -- Scan tooltip for debuff/buff
          ScanTooltip:SetHyperlink(format(HyperLinkSt, SpellID))

          IsAura = true
          for i = 1, ScanTooltip:NumLines() do
            local Text = ScanTooltip['TextLeft' .. i]

            if Text and false then
              local r, g, b = Text:GetTextColor()

              r = floor(r + 0.10)
              g = floor(g + 0.10)
              b = floor(b + 0.10)

              -- Gold first text, it's a profession link
              -- If first line is not white then reject it.
              if i == 1 and (r ~= 1 or g ~= 1 or b ~= 1) then
                break

              -- Gold for anything else and it should be a valid aura
              -- line 2 or after is not white except it.
              elseif r ~= 1 or g ~= 1 or b ~= 1 then
                IsAura = true
                break
              end
            end
          end
        end

        if IsAura then
          NumSpells = NumSpells + 1
          SpellList[SpellID] = strlower(Name)

          TotalInvalid = 0
        else
          TotalInvalid = TotalInvalid + 1
        end
      end

      -- Every ~1 second it will update any visible predictors to make up for the fact that the data is delay loaded
      if CurrentIndex % 5000 == 0 then
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
  self.frame:ClearAllPoints()
  self.frame:Hide()
  self.PredictFrame:Hide()
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
  self.Object:Fire('OnEnter')
end

-------------------------------------------------------------------------------
-- EditBoxOnLeave
--
-- Gets called when the mouse enters the edit box.
-------------------------------------------------------------------------------
local function EditBoxOnLeave(self)
  self.Object:Fire('OnLeave')
end

-------------------------------------------------------------------------------
-- PopulatePredictorFrame
--
-- Populates the predictorframe using a SpellList table and SearchSt
--
-- Type    Type of spelllist
--            'spells'   Came from SpellList
--            'auras'  Came from trackedauras
-------------------------------------------------------------------------------

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
local function PopulatePredictor(self)
  local Object = self.Object
  local SearchSt = '^' .. strlower(Object.EditBox:GetText())
  local TrackedAuras = Main.TrackedAuras
  local ActiveButtons = 0

  for _, Button in pairs(self.Buttons) do
    Button:Hide()
  end

  -- Do auras
  if TrackedAuras then
    for SpellID, Name in pairs(TrackedAuras) do
      if type(SpellID) == 'number' then
        Name = strlower(GetSpellInfo(SpellID))
      end
      if type(SpellID) == 'number' and strmatch(Name, SearchSt) then
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
    if strmatch(Name, SearchSt) then
      local Found = TrackedAuras and TrackedAuras[SpellID] or nil
      if Found == nil then
        if ActiveButtons < PredictorLines then
          ActiveButtons = ActiveButtons + 1
          AddPredictorButton(self, ActiveButtons, '|T%s:15:15:2:11|t %s', SpellID)
        else
          break
        end
      end
    end
  end

  if ActiveButtons > 0 then
    self:SetHeight(15 + ActiveButtons * 17)
    self:Show()
  else
    self:Hide()
  end

  self.ActiveButtons = ActiveButtons
end

-------------------------------------------------------------------------------
-- PredictorShowButton
--
-- Shows a button in the editbox selector
-------------------------------------------------------------------------------
local function PredictorShowButton(self)
  if self.LastText ~= '' then
    self.PredictFrame.SelectedButton = nil
    PopulatePredictor(self.PredictFrame)
  else
    self.PredictFrame:Hide()
  end

  if self.showButton then
    self.Button:Show()
    self.EditBox:SetTextInsets(0, 20, 3, 3)
  end
end

-------------------------------------------------------------------------------
-- PredictorHideButton
--
-- Hides a button in the editbox selector
-------------------------------------------------------------------------------
local function PredictorHideButton(self)
  self.Button:Hide()
  self.EditBox:SetTextInsets(0, 0, 3, 3)

  self.PredictFrame.SelectedButton = nil
  self.PredictFrame:Hide()
end

-------------------------------------------------------------------------------
-- PredictorOnHide
--
-- Hides the predictor editbox and restores binds, tooltips
-------------------------------------------------------------------------------
local function PredictorOnHide(self)

  -- Allow users to use arrows to go back and forth again without the fix
  self.Object.EditBox:SetAltArrowKeyMode(false)

  -- Make sure the tooltip isn't kept open if one of the buttons was using it
  for _, Button in pairs(self.Buttons) do
    if GameTooltip:IsOwned(Button) then
      GameTooltip:Hide()
    end
  end

  -- Reset all bindings set on this predictor
  ClearOverrideBindings(self)
end

-------------------------------------------------------------------------------
-- EditBoxOnEnterPressed
--
-- Gets called when something is entered into the edit box
-------------------------------------------------------------------------------
local function EditBoxOnEnterPressed(self)
  local Object = self.Object

  -- Something is selected in the predictor, use that value instead of whatever is in the input box
  if Object.PredictFrame.SelectedButton then
    Object.PredictFrame.Buttons[Object.PredictFrame.SelectedButton]:Click()
    return
  end

  local cancel = Object:Fire('OnEnterPressed', self:GetText())
  if not cancel then
    PredictorHideButton(Object)
  end

  -- Reactive the cursor, odds are if someone is adding spells they are adding more than one
  -- and if they aren't, it can't hurt anyway.
  -- Object.EditBox:SetFocus()
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
-- EditBoxFixCursorPosition
--
-- When using SetAltArrowKeyMode the ability to move the cursor with left and right arrows is disabled
-- this reenables that so the user doesn't notice anything wrong
-------------------------------------------------------------------------------
local function EditBoxFixCursorPosition(self, Direction)
  self:SetCursorPosition(self:GetCursorPosition() + (Direction == 'RIGHT' and 1 or -1))
end

-------------------------------------------------------------------------------
-- EditBoxOnReceiveDrag
--
-- Gets called when a button is selected.
-------------------------------------------------------------------------------
local function EditBoxOnReceiveDrag(self)
  local Object = self.Object
  local Type, ID, Info = GetCursorInfo()

  ClearCursor()

  PredictorHideButton(Object)
  AceGUI:ClearFocus()
end

-------------------------------------------------------------------------------
-- EditBoxOnTextChanged
--
-- Gets called when the text changes in the edit box.
-------------------------------------------------------------------------------
local function EditBoxOnTextChanged(self)
  local Object = self.Object
  local Value = self:GetText()

  if Value ~= Object.LastText then
    Object:Fire('OnTextChanged', Value)
    Object.LastText = Value

    PredictorShowButton(Object)
  end
end

-------------------------------------------------------------------------------
-- EditBoxOnFocusLost
--
-- Gets called when the edit box loses focus
-------------------------------------------------------------------------------
local function EditBoxOnEditFocusLost(self)
  PredictorOnHide(self.Object.PredictFrame)
end

-------------------------------------------------------------------------------
-- EditBoxButtonOnclick
--
-- called when the 'edit' button in the edit box is clicked
-------------------------------------------------------------------------------
local function EditBoxButtonOnClick(self)
  EditBoxOnEnterPressed(self.Object.EditBox)
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
  self.disabled = Disabled

  if Disabled then
    self.EditBox:EnableMouse(false)
    self.EditBox:ClearFocus()
    self.EditBox:SetTextColor(0.5, 0.5, 0.5)
    self.Label:SetTextColor(0.5, 0.5, 0.5)
  else
    self.EditBox:EnableMouse(true)
    self.EditBox:SetTextColor(1, 1, 1)
    self.Label:SetTextColor(1, 0.82, 0)
  end
end

-------------------------------------------------------------------------------
-- EditBoxSetText
--
-- Changes the text in the edit box
-------------------------------------------------------------------------------
local function EditBoxSetText(self, Text, Cursor)
  self.LastText = Text or ''
  self.EditBox:SetText(self.LastText)
  self.EditBox:SetCursorPosition(Cursor or 0)

  PredictorHideButton(self)
end

-------------------------------------------------------------------------------
-- EditBoxSetLabel
--
-- Sets the label on the edit box.
-------------------------------------------------------------------------------
local function EditBoxSetLabel(self, Text)
  if Text and Text ~= '' then
    self.Label:SetText(Text)
    self.Label:Show()
    self.EditBox:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 7, -18)
    self:SetHeight(44)
    self.alignoffset = 30
  else
    self.Label:SetText('')
    self.Label:Hide()
    self.EditBox:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', 7, 0)
    self:SetHeight(26)
    self.alignoffset = 12
  end
end

-------------------------------------------------------------------------------
-- PredictorOnMouseDown
--
-- Gets called when the mouse is clicked on the predictor.
-------------------------------------------------------------------------------
local function PredictorOnMouseDown(self, Direction)

  -- Fix the cursor positioning if left or right arrow key was used
  if Direction == 'LEFT' or Direction == 'RIGHT' then
    EditBoxFixCursorPosition(self.EditBox, Direction)
  end
end

-------------------------------------------------------------------------------
-- PredictorButtonOnClick
--
-- Sets the editbox to the button that was clicked in the selector
-------------------------------------------------------------------------------
local function PredictorButtonOnClick(self)
  local Name = GetSpellInfo(self.SpellID)

  EditBoxSetText(self.parent.Object, Name, #Name)

  self.parent.SelectedButton = nil
  self.parent.Object:Fire('OnEnterPressed', Name, self.SpellID)
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

  GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 3)
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
    Button:SetPoint('TOPLEFT', Buttons[Index - 1], 'BOTTOMLEFT', 0, 0)
    Button:SetPoint('TOPRIGHT', Buttons[Index - 1], 'BOTTOMRIGHT', 0, 0)
  else
    Button:SetPoint('TOPLEFT', PredictFrame, 8, -8)
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
--local EditBox = CreateFrame('EditBox', 'AceGUI30SpellEditBox' .. Num, Frame, 'InputBoxTemplate')
  local EditBox = CreateFrame('EditBox', nil, Frame, 'InputBoxTemplate')

  -- Don't feel like looking up the specific callbacks for when a widget resizes, so going to be creative with SetPoint instead!
--local PredictFrame = CreateFrame('Frame', 'AceGUI30SpellEditBox' .. Num .. 'Predictor', UIParent)
  local PredictFrame = CreateFrame('Frame', nil, UIParent)
  local Buttons = {}
  PredictFrame:SetBackdrop(PredictorBackdrop)
  PredictFrame:SetBackdropColor(0, 0, 0, 0.85)
  PredictFrame:SetWidth(1)
  PredictFrame:SetHeight(150)
  PredictFrame:SetPoint('TOPLEFT', EditBox, 'BOTTOMLEFT', -6, 0)
  PredictFrame:SetPoint('TOPRIGHT', EditBox, 'BOTTOMRIGHT', 0, 0)
  PredictFrame:SetFrameStrata('TOOLTIP')
  PredictFrame:SetClampedToScreen(true)
  PredictFrame.Buttons = {}
  PredictFrame.PopulatePredictor = PopulatePredictor
  PredictFrame.EditBox = EditBox
  PredictFrame.Buttons = Buttons
  PredictFrame:Hide()

  -- Create the mass of predictor rows
  for Index = 1, PredictorLines do
    Buttons[Index] = CreateButton(PredictFrame, EditBox, Index)
  end

  -- Set the main info things for this thingy
  local self = {}
  self.type = EditBoxWidgetType
  self.frame = Frame

  self.OnRelease = OnRelease
  self.OnAcquire = OnAcquire

  self.SetDisabled = EditBoxSetDisabled
  self.SetText = EditBoxSetText
  self.SetLabel = EditBoxSetLabel

  self.PredictFrame = PredictFrame
  self.EditBox = EditBox

  self.alignoffset = 30

  Frame:SetHeight(44)
  Frame:SetWidth(200)

  Frame.Object = self
  EditBox.Object = self
  PredictFrame.Object = self

  -- EditBoxes override the OnKeyUp/OnKeyDown events so that they can function, meaning in order to make up and down
  -- arrow navigation of the menu work, I have to do some trickery with temporary bindings.
  -- This is currently taken out since no one uses a keyboard for dropdowns.
  PredictFrame:SetScript('OnMouseDown', PredictorOnMouseDown)
  PredictFrame:SetScript('OnHide', PredictorOnHide)
  --PredictFrame:SetScript('OnShow', PredictorOnShow)

  EditBox:SetScript('OnEnter', EditBoxOnEnter)
  EditBox:SetScript('OnLeave', EditBoxOnLeave)

  EditBox:SetAutoFocus(false)
  EditBox:SetFontObject(ChatFontNormal)
  EditBox:SetScript('OnEscapePressed', EditBoxOnEscapePressed)
  EditBox:SetScript('OnEnterPressed', EditBoxOnEnterPressed)
  EditBox:SetScript('OnTextChanged', EditBoxOnTextChanged)
  EditBox:SetScript('OnReceiveDrag', EditBoxOnReceiveDrag)
  EditBox:SetScript('OnMouseDown', EditBoxOnReceiveDrag)
  --EditBox:SetScript('OnEditFocusGained', EditBoxOnEditFocusGained)
  EditBox:SetScript('OnEditFocusLost', EditBoxOnEditFocusLost)

  EditBox:SetTextInsets(0, 0, 3, 3)
  EditBox:SetMaxLetters(256)

  EditBox:SetPoint('BOTTOMLEFT', Frame, 'BOTTOMLEFT', 6, 0)
  EditBox:SetPoint('BOTTOMRIGHT', Frame, 'BOTTOMRIGHT', 0, 0)
  EditBox:SetHeight(19)

  local Label = Frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  Label:SetPoint('TOPLEFT', Frame, 'TOPLEFT', 0, -2)
  Label:SetPoint('TOPRIGHT', Frame, 'TOPRIGHT', 0, -2)
  Label:SetJustifyH('LEFT')
  Label:SetHeight(18)

  self.Label = Label

  local Button = CreateFrame('Button', nil, EditBox, 'UIPanelButtonTemplate')
  Button:SetPoint('RIGHT', EditBox, 'RIGHT', -2, 0)
  Button:SetScript('OnClick', EditBoxButtonOnClick)
  Button:SetWidth(40)
  Button:SetHeight(20)
  Button:SetText(OKAY)
  Button:Hide()

  self.Button = Button
  Button.Object = self

  AceGUI:RegisterAsWidget(self)
  return self
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
