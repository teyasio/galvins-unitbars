-- Controls.lua

-- Contains custom controls.
--
-- Aura Menu                     Modified from AceGUI-3.0-Spell-EditBox
-- Editbox Ready Only Selected   An edit box that automatically selects what's in it.  Also read only
-- Spell Info                    Shows a tooltip when moused over.  Also shows an icon with text next to it.
-- Dropdown Select               Same as a normal drop down except has a scroll bar
-- Multi line edit box debug     Same as a regular one but for debug

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main

local LSM = Main.LSM
local HyperlinkSt = Main.HyperlinkSt

local AceGUI = LibStub('AceGUI-3.0')

-- localize some globals.
local _, _G, print =
      _, _G, print
local CreateFrame, strlower, strfind, strsplit, strtrim, strsub, format, sort, tostring =
      CreateFrame, strlower, strfind, strsplit, strtrim, strsub, format, sort, tostring
local tonumber, tconcat     , GetTime =
      tonumber, table.concat, GetTime
local pairs, unpack =
      pairs, unpack
local C_Spell_GetSpellName, C_Spell_GetSpellTexture =
      C_Spell.GetSpellName, C_Spell.GetSpellTexture
local GameTooltip, ClearOverrideBindings, ACCEPT, GetCursorInfo, ClearCursor, GetMacroInfo =
      GameTooltip, ClearOverrideBindings, ACCEPT, GetCursorInfo, ClearCursor, GetMacroInfo
local UIParent, GameFontNormal, GameFontHighlight, ChatFontNormal, OKAY, PlaySound =
      UIParent, GameFontNormal, GameFontHighlight, ChatFontNormal, OKAY, PlaySound

-------------------------------------------------------------------------------
-- Locals
--
-- Spells                 Contains a list of loaded spells used in the editbox
-- CharSpellsIndex        Helps in searching faster
-- HighestSpellID         Load spells hits when SpellID passes this number
-- GetSpellIDsDone        if true then spell IDs are done
-- SpellsPerRun           Amount of spells to load at one time
-- SpellsTPS              Amount of calls per second
-- MaxSpellMenuLines      Amount of lines used
-- MenuLines              How many lines to show without a scroll bar
-- SpellsMenuFrameWidth   Width of the menu in pixels for spells menu
-- SpellMenuFrame         Contains the current open pulldown window for spells
-------------------------------------------------------------------------------
local HighestSpellID = 600000
local SpellsTPS = 1 / 30      -- 30 times per second
local SpellsPerRun = 5000 -- Total Spells to load each run
local GetSpellIDsDone = false
local Ace3Widgets = {}
local DefaultType = 0

local MaxSpellMenuLines = 100
local MenuLines = 10
local SpellsMenuFrameWidth = 250

local EditBoxWidgetVersion = 1
local AuraEditBoxWidgetVersion = 1
local EditBoxReadOnlySelectedWidgetVersion = 1
local SpellInfoWidgetVersion = 1
local MultiLineEditBoxDebugWidgetVersion = 1
local MultiLineEditBoxImportWidgetVersion = 1
local MultiLineEditBoxExportWidgetVersion = 1
local DropdownSelectWidgetVersion = 1

local EditBoxWidgetType = 'GUB_AuraMenu_Base'
local AuraEditBoxWidgetType = 'GUB_Aura_EditBox'
local EditBoxReadOnlySelectedWidgetType = 'GUB_EditBox_ReadOnly_Selected'
local MultiLineEditBoxDebugWidgetType = 'GUB_MultiLine_EditBox_Debug'
local MultiLineEditBoxImportWidgetType = 'GUB_MultiLine_EditBox_Import'
local MultiLineEditBoxExportWidgetType = 'GUB_MultiLine_EditBox_Export'
local SpellInfoWidgetType = 'GUB_Spell_Info'
local DropdownSelectWidgetType = 'GUB_Dropdown_Select'

local SpellsTimer = {}
local Spells = {}
local CharSpellsIndex = {}
local WidgetUserData = {}

local SpellTooltipTimer = {}

local SpellMenuBackdrop = {
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

--#############################################################################
--#############################################################################
--
-- ACE3 code here to be reused
--
--#############################################################################
--#############################################################################

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Code copied/modified from AceGUIWidget-EditBox.lua
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

do

local function ShowButton(self)
  if not self.disablebutton then
    self.button:Show()
    self.editbox:SetTextInsets(0, 20, 3, 3)
  end
end

local function HideButton(self)
  self.button:Hide()
  self.editbox:SetTextInsets(0, 0, 3, 3)
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
  frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
  frame.obj:Fire("OnLeave")
end

local function Frame_OnShowFocus(frame)
  frame.obj.editbox:SetFocus()
  frame:SetScript("OnShow", nil)
end

local function EditBox_OnEscapePressed(frame)
  AceGUI:ClearFocus()
end

local function EditBox_OnEnterPressed(frame)
  local self = frame.obj
  local value = frame:GetText()
  local cancel = self:Fire("OnEnterPressed", value)
  if not cancel then
    PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    HideButton(self)
  end
end

local function EditBox_OnReceiveDrag(frame)
  local self = frame.obj
  local type, id, info = GetCursorInfo()
  local name

  if type == "item" then
    name = info
  elseif type == "spell" then -- spellbook
    name = C_Spell_GetSpellName(id)  --name = GetSpellInfo(id, info)
  elseif type == "macro" then
    name = GetMacroInfo(id)
  end
  if name then
    self:SetText(name)
    self:Fire("OnEnterPressed", name)
    ClearCursor()
    HideButton(self)
    AceGUI:ClearFocus()
  end
end

local function EditBox_OnTextChanged(frame)
  local self = frame.obj
  local value = frame:GetText()
  if tostring(value) ~= tostring(self.lasttext) then
    self:Fire("OnTextChanged", value)
    self.lasttext = value
    ShowButton(self)
  end
end

local function EditBox_OnFocusGained(frame)
  AceGUI:SetFocus(frame.obj)
end

local function Button_OnClick(frame)
  local editbox = frame.obj.editbox
  editbox:ClearFocus()
  EditBox_OnEnterPressed(editbox)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    -- height is controlled by SetLabel
    self:SetWidth(200)
    self:SetDisabled(false)
    self:SetLabel()
    self:SetText()
    self:DisableButton(false)
    self:SetMaxLetters(0)
  end,

  ["OnRelease"] = function(self)
    self:ClearFocus()
  end,

  ["SetDisabled"] = function(self, disabled)
    self.disabled = disabled
    if disabled then
      self.editbox:EnableMouse(false)
      self.editbox:ClearFocus()
      self.editbox:SetTextColor(0.5,0.5,0.5)
      self.label:SetTextColor(0.5,0.5,0.5)
    else
      self.editbox:EnableMouse(true)
      self.editbox:SetTextColor(1,1,1)
      self.label:SetTextColor(1,.82,0)
    end
  end,

  ["SetText"] = function(self, text)
    self.lasttext = text or ""
    self.editbox:SetText(text or "")
    self.editbox:SetCursorPosition(0)
    HideButton(self)
  end,

  ["GetText"] = function(self, text)
    return self.editbox:GetText()
  end,

  ["SetLabel"] = function(self, text)
    if text and text ~= "" then
      self.label:SetText(text)
      self.label:Show()
      self.editbox:SetPoint("TOPLEFT",self.frame,"TOPLEFT",7,-18)
      self:SetHeight(44)
      self.alignoffset = 30
    else
      self.label:SetText("")
      self.label:Hide()
      self.editbox:SetPoint("TOPLEFT",self.frame,"TOPLEFT",7,0)
      self:SetHeight(26)
      self.alignoffset = 12
    end
  end,

  ["DisableButton"] = function(self, disabled)
    self.disablebutton = disabled
    if disabled then
      HideButton(self)
    end
  end,

  ["SetMaxLetters"] = function (self, num)
    self.editbox:SetMaxLetters(num or 0)
  end,

  ["ClearFocus"] = function(self)
    self.editbox:ClearFocus()
    self.frame:SetScript("OnShow", nil)
  end,

  ["SetFocus"] = function(self)
    self.editbox:SetFocus()
    if not self.frame:IsShown() then
      self.frame:SetScript("OnShow", Frame_OnShowFocus)
    end
  end,

  ["HighlightText"] = function(self, from, to)
    self.editbox:HighlightText(from, to)
  end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
function Ace3Widgets:EditBox()
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:Hide()

  local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  editbox:SetAutoFocus(false)
  editbox:SetFontObject(ChatFontNormal)
  editbox:SetScript("OnEnter", Control_OnEnter)
  editbox:SetScript("OnLeave", Control_OnLeave)
  editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
  editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
  editbox:SetScript("OnTextChanged", EditBox_OnTextChanged)
  editbox:SetScript("OnReceiveDrag", EditBox_OnReceiveDrag)
  editbox:SetScript("OnMouseDown", EditBox_OnReceiveDrag)
  editbox:SetScript("OnEditFocusGained", EditBox_OnFocusGained)
  editbox:SetTextInsets(0, 0, 3, 3)
  editbox:SetMaxLetters(256)
  editbox:SetPoint("BOTTOMLEFT", 6, 0)
  editbox:SetPoint("BOTTOMRIGHT")
  editbox:SetHeight(19)

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", 0, -2)
  label:SetPoint("TOPRIGHT", 0, -2)
  label:SetJustifyH("LEFT")
  label:SetHeight(18)

  local button = CreateFrame("Button", nil, editbox, "UIPanelButtonTemplate")
  button:SetWidth(40)
  button:SetHeight(20)
  button:SetPoint("RIGHT", -2, 0)
  button:SetText(OKAY)
  button:SetScript("OnClick", Button_OnClick)
  button:Hide()

  local widget = {
    alignoffset = 30,
    editbox     = editbox,
    label       = label,
    button      = button,
    frame       = frame,
    type        = DefaultType
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end
  editbox.obj, button.obj = widget, widget

  return widget
end

end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--
-- Code copied/modified from AceGUIWidget-MultiLineEditBox.lua
--
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

do
local function Layout(self)
  self:SetHeight(self.numlines * 14 + (self.disablebutton and 19 or 41) + self.labelHeight)

  if self.labelHeight == 0 then
    self.scrollBar:SetPoint("TOP", self.frame, "TOP", 0, -23)
  else
    self.scrollBar:SetPoint("TOP", self.label, "BOTTOM", 0, -19)
  end

  if self.disablebutton then
    self.scrollBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 21)
    self.scrollBG:SetPoint("BOTTOMLEFT", 0, 4)
  else
    self.scrollBar:SetPoint("BOTTOM", self.button, "TOP", 0, 18)
    self.scrollBG:SetPoint("BOTTOMLEFT", self.button, "TOPLEFT")
  end
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function OnClick(self)                                                     -- Button
  self = self.obj
  self.editBox:ClearFocus()
  if not self:Fire("OnEnterPressed", self.editBox:GetText()) then
    self.button:Disable()
  end
end

local function OnCursorChanged(self, _, y, _, cursorHeight)                      -- EditBox
  self, y = self.obj.scrollFrame, -y
  local offset = self:GetVerticalScroll()
  if y < offset then
    self:SetVerticalScroll(y)
  else
    y = y + cursorHeight - self:GetHeight()
    if y > offset then
      self:SetVerticalScroll(y)
    end
  end
end

local function OnEditFocusLost(self)                                             -- EditBox
  self:HighlightText(0, 0)
  self.obj:Fire("OnEditFocusLost")
end

local function OnEnter(self)                                                     -- EditBox / ScrollFrame
  self = self.obj
  if not self.entered then
    self.entered = true
    self:Fire("OnEnter")
  end
end

local function OnLeave(self)                                                     -- EditBox / ScrollFrame
  self = self.obj
  if self.entered then
    self.entered = nil
    self:Fire("OnLeave")
  end
end

local function OnMouseUp(self)                                                   -- ScrollFrame
  self = self.obj.editBox
  self:SetFocus()
  self:SetCursorPosition(self:GetNumLetters())
end

local function OnReceiveDrag(self)                                               -- EditBox / ScrollFrame
  local type, id, info = GetCursorInfo()
  if type == "spell" then
    info = C_Spell_GetSpellName(id) --info = GetSpellInfo(id, info)
  elseif type ~= "item" then
    return
  end
  ClearCursor()
  self = self.obj
  local editBox = self.editBox
  if not editBox:HasFocus() then
    editBox:SetFocus()
    editBox:SetCursorPosition(editBox:GetNumLetters())
  end
  editBox:Insert(info)
  self.button:Enable()
end

local function OnSizeChanged(self, width, height)                                -- ScrollFrame
  self.obj.editBox:SetWidth(width)
end

local function OnTextChanged(self, userInput)                                    -- EditBox
  if userInput then
    self = self.obj
    self:Fire("OnTextChanged", self.editBox:GetText())
    self.button:Enable()
  end
end

local function OnTextSet(self)                                                   -- EditBox
  self:HighlightText(0, 0)
  self:SetCursorPosition(self:GetNumLetters())
  self:SetCursorPosition(0)
  self.obj.button:Disable()
end

local function OnVerticalScroll(self, offset)                                    -- ScrollFrame
  local editBox = self.obj.editBox
  editBox:SetHitRectInsets(0, 0, offset, editBox:GetHeight() - offset - self:GetHeight())
end

local function OnShowFocus(frame)
  frame.obj.editBox:SetFocus()
  frame:SetScript("OnShow", nil)
end

local function OnEditFocusGained(frame)
  AceGUI:SetFocus(frame.obj)
  frame.obj:Fire("OnEditFocusGained")
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self.editBox:SetText("")
    self:SetDisabled(false)
    self:SetWidth(200)
    self:DisableButton(false)
    self:SetNumLines()
    self.entered = nil
    self:SetMaxLetters(0)
  end,

  ["OnRelease"] = function(self)
    self:ClearFocus()
  end,

  ["SetDisabled"] = function(self, disabled)
    local editBox = self.editBox
    if disabled then
      editBox:ClearFocus()
      editBox:EnableMouse(false)
      editBox:SetTextColor(0.5, 0.5, 0.5)
      self.label:SetTextColor(0.5, 0.5, 0.5)
      self.scrollFrame:EnableMouse(false)
      self.button:Disable()
    else
      editBox:EnableMouse(true)
      editBox:SetTextColor(1, 1, 1)
      self.label:SetTextColor(1, 0.82, 0)
      self.scrollFrame:EnableMouse(true)
    end
  end,

  ["SetLabel"] = function(self, text)
    if text and text ~= "" then
      self.label:SetText(text)
      if self.labelHeight ~= 10 then
        self.labelHeight = 10
        self.label:Show()
      end
    elseif self.labelHeight ~= 0 then
      self.labelHeight = 0
      self.label:Hide()
    end
    Layout(self)
  end,

  ["SetNumLines"] = function(self, value)
    if not value or value < 4 then
      value = 4
    end
    self.numlines = value
    Layout(self)
  end,

  ["SetText"] = function(self, text)
    self.editBox:SetText(text)
  end,

  ["GetText"] = function(self)
    return self.editBox:GetText()
  end,

  ["SetMaxLetters"] = function (self, num)
    self.editBox:SetMaxLetters(num or 0)
  end,

  ["DisableButton"] = function(self, disabled)
    self.disablebutton = disabled
    if disabled then
      self.button:Hide()
    else
      self.button:Show()
    end
    Layout(self)
  end,

  ["ClearFocus"] = function(self)
    self.editBox:ClearFocus()
    self.frame:SetScript("OnShow", nil)
  end,

  ["SetFocus"] = function(self)
    self.editBox:SetFocus()
    if not self.frame:IsShown() then
      self.frame:SetScript("OnShow", OnShowFocus)
    end
  end,

  ["HighlightText"] = function(self, from, to)
    self.editBox:HighlightText(from, to)
  end,

  ["GetCursorPosition"] = function(self)
    return self.editBox:GetCursorPosition()
  end,

  ["SetCursorPosition"] = function(self, ...)
    return self.editBox:SetCursorPosition(...)
  end,


}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local backdrop = {
  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
  insets = { left = 4, right = 3, top = 4, bottom = 3 }
}

function Ace3Widgets:MultiLineEditBox()
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:Hide()

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
  label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -4)
  label:SetJustifyH("LEFT")
  label:SetText(ACCEPT)
  label:SetHeight(10)

  local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  button:SetPoint("BOTTOMLEFT", 0, 4)
  button:SetHeight(22)
  button:SetWidth(label:GetStringWidth() + 24)
  button:SetText(ACCEPT)
  button:SetScript("OnClick", OnClick)
  button:Disable()

  local text = button:GetFontString()
  text:ClearAllPoints()
  text:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
  text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 1)
  text:SetJustifyV("MIDDLE")

  local scrollBG = CreateFrame("Frame", nil, frame, 'BackdropTemplate')
  scrollBG:SetBackdrop(backdrop)
  scrollBG:SetBackdropColor(0, 0, 0)
  scrollBG:SetBackdropBorderColor(0.4, 0.4, 0.4)

  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")

  local scrollBar = scrollFrame.ScrollBar
  scrollBar:ClearAllPoints()
  scrollBar:SetPoint("TOP", label, "BOTTOM", 0, -19)
  scrollBar:SetPoint("BOTTOM", button, "TOP", 0, 18)
  scrollBar:SetPoint("RIGHT", frame, "RIGHT")

  scrollBG:SetPoint("TOPRIGHT", scrollBar, "TOPLEFT", 0, 19)
  scrollBG:SetPoint("BOTTOMLEFT", button, "TOPLEFT")

  scrollFrame:SetPoint("TOPLEFT", scrollBG, "TOPLEFT", 5, -6)
  scrollFrame:SetPoint("BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -4, 4)
  scrollFrame:SetScript("OnEnter", OnEnter)
  scrollFrame:SetScript("OnLeave", OnLeave)
  scrollFrame:SetScript("OnMouseUp", OnMouseUp)
  scrollFrame:SetScript("OnReceiveDrag", OnReceiveDrag)
  scrollFrame:SetScript("OnSizeChanged", OnSizeChanged)
  scrollFrame:HookScript("OnVerticalScroll", OnVerticalScroll)

  local editBox = CreateFrame("EditBox", nil, scrollFrame)
  editBox:SetAllPoints()
  editBox:SetFontObject(ChatFontNormal)
  editBox:SetMultiLine(true)
  editBox:EnableMouse(true)
  editBox:SetAutoFocus(false)
  editBox:SetCountInvisibleLetters(false)
  editBox:SetScript("OnCursorChanged", OnCursorChanged)
  editBox:SetScript("OnEditFocusLost", OnEditFocusLost)
  editBox:SetScript("OnEnter", OnEnter)
  editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
  editBox:SetScript("OnLeave", OnLeave)
  editBox:SetScript("OnMouseDown", OnReceiveDrag)
  editBox:SetScript("OnReceiveDrag", OnReceiveDrag)
  editBox:SetScript("OnTextChanged", OnTextChanged)
  editBox:SetScript("OnTextSet", OnTextSet)
  editBox:SetScript("OnEditFocusGained", OnEditFocusGained)


  scrollFrame:SetScrollChild(editBox)

  local widget = {
    button      = button,
    editBox     = editBox,
    frame       = frame,
    label       = label,
    labelHeight = 10,
    numlines    = 4,
    scrollBar   = scrollBar,
    scrollBG    = scrollBG,
    scrollFrame = scrollFrame,
    type        = DefaultType
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end
  button.obj, editBox.obj, scrollFrame.obj = widget, widget, widget

  return widget
end

end

--#############################################################################
--#############################################################################
--
-- End of ace3 code
--
--#############################################################################
--#############################################################################


--*****************************************************************************
--
-- Spell utility
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Show tooltip with SpellID
-------------------------------------------------------------------------------
local function UpdateSpellToolTipTimer(SpellTooltipTimer)
  local SpellID = SpellTooltipTimer.SpellID
  GameTooltip:ClearLines()

  GameTooltip:SetHyperlink(format(HyperlinkSt, SpellID))
  GameTooltip:AddLine(format('|cFFFFFF00SpellID:|r|cFF00FF00%s|r', SpellID))

  -- Need to show to make sure the tooltip surrounds the AddLine text
  -- after SetHyperlink
  GameTooltip:Show()
end

local function StartSpellTooltipTimer(self, SpellID, Anchor)
  SpellTooltipTimer.SpellID = SpellID

  GameTooltip:SetOwner(self, Anchor, 8)
  UpdateSpellToolTipTimer(SpellTooltipTimer)

  Main:SetTimer(SpellTooltipTimer, UpdateSpellToolTipTimer, 1 / 10) -- 10 times per second
end

local function StopSpellTooltipTimer()
  -- Stop timer
  Main:SetTimer(SpellTooltipTimer, nil)
  GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- GetSpellIDs
--
-- Gets spells just once.  This is used for the aura menu
-- This will use a lot of memory, but then release all the strings at the end
-- I tried to make the sort work as fast as possible by avoiding using
-- a call back sort function
-------------------------------------------------------------------------------
local function GetSpellIDs()
  if not GetSpellIDsDone then
    print("Loading Spells: Spell Menu won't work until done")
    local SpellIndex = 0
    local SpellID = 1

    local function GetSpellIDs2(self)
      local TotalSpells = 0

      repeat
        -- Check for end
        if SpellID > HighestSpellID then
          Main:SetTimer(self, nil)

          sort(Spells)

          -- Build char to spells index for faster searches in the populate aura menu
          -- Remove all strings from Spells now that it's sorted
          local LastFirstChar
          for Index = 1, SpellIndex do
            local Name = Spells[Index]
            local NumLength = strsub(Name, #Name, -1)

            -- set SpellID
            Spells[Index] = tonumber(strsub(Name, #Name - NumLength, -2))

            local FirstChar = strsub(Name, 1, 1)
            if FirstChar ~= LastFirstChar then
              LastFirstChar = FirstChar
              CharSpellsIndex[FirstChar] = Index
            end
          end
          print('Loading Spells: Done')
          break
        end

        local Name = C_Spell_GetSpellName(SpellID)
        local Icon = C_Spell_GetSpellTexture(SpellID)

        if Name and Icon and Name ~= '' then
          SpellIndex = SpellIndex + 1
          Spells[SpellIndex] = strlower(Name) .. SpellID .. #tostring(SpellID)
        end
        SpellID = SpellID + 1
        TotalSpells = TotalSpells + 1
      until TotalSpells > SpellsPerRun
    end -- function end

    Main:SetTimer(SpellsTimer, GetSpellIDs2, SpellsTPS)
  end

  GetSpellIDsDone = true
end

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
local function HideScroller(ContentSpellMenuFrame, Hide)
  local ScrollFrame = ContentSpellMenuFrame.ScrollFrame
  local Scroller = ContentSpellMenuFrame.Scroller
  local MenuFrame = ContentSpellMenuFrame.MenuFrame

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

-------------------------------------------------------------------------------
-- AddSpellMenuButton
--
-- Adds a button to the spell menu frame
--
-- ActiveButton    Button position to add one at.
-- FormatText      Format string
-- SpellID         SpellID to add to button
-- Icon            Number: contains the icon
-- Name            Name of the spell
-------------------------------------------------------------------------------
local function AddSpellMenuButton(self, ActiveButton, FormatText, SpellID, Icon, Name)

  -- Ran out of text to suggest :<
  local Button = self.Buttons[ActiveButton]

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
-- PopulateAuraMenu
--
-- Populates the aura menu with a list of spells matching the spell name entered.
-------------------------------------------------------------------------------
local function PopulateAuraMenu(self)
  local Widget = self.Widget
  local SearchSt = strlower(Widget.EditBox:GetText())
  local AuraTrackersData = Main.AuraTrackersData
  local ActiveButtons = 0

  for _, Button in pairs(self.Buttons) do
    Button:Hide()
  end

  -- Do auras
  local All = AuraTrackersData.All
  if All then
    for SpellID, Aura in pairs(All) do
      local Name = C_Spell_GetSpellName(SpellID)
      local Icon = C_Spell_GetSpellTexture(SpellID)

      if strfind(strlower(Name), SearchSt, 1, true) == 1 then
        if ActiveButtons < MaxSpellMenuLines then
          ActiveButtons = ActiveButtons + 1
          AddSpellMenuButton(self, ActiveButtons, '|T%s:15:15:2:11|t |cFFFFFFFF%s|r', SpellID, Icon, Name)
        else
          break
        end
      end
    end
  end

  -- Add spells
  local FirstChar = strsub(SearchSt, 1, 1)
  local StartingIndex = CharSpellsIndex[FirstChar]

  local StartBlockSearch = false
  local BlockLen = 1
  if #SearchSt > 1 then
    BlockLen = #SearchSt - 1
  end
  local BlockSt = strsub(SearchSt, 1, BlockLen)

  -- Only search if there is something to find
  if StartingIndex then
    for Index = StartingIndex, #Spells do
      if ActiveButtons < MaxSpellMenuLines  then
        local SpellID = Spells[Index]

        local Name = C_Spell_GetSpellName(SpellID)
        local Icon = C_Spell_GetSpellTexture(SpellID)
        local NameLower = strlower(Name)

        -- Abort if search goes out of block
        if strsub(NameLower, 1, 1) == FirstChar then

          -- Abort if search goes out of sub block
          if strsub(NameLower, 1, BlockLen) == BlockSt then
            if not StartBlockSearch then
              StartBlockSearch = true
            end
            if strfind(NameLower, SearchSt, 1, true) == 1 then
              ActiveButtons = ActiveButtons + 1

              AddSpellMenuButton(self, ActiveButtons, '|T%s:15:15:2:11|t %s', SpellID, Icon, Name)
            end
          elseif StartBlockSearch then
            break
          end
        else
          break
        end
      else
        break
      end
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
-- SpellMenuShowButton
--
-- Shows the okay button in the editbox selector
-------------------------------------------------------------------------------
local function SpellMenuShowButton(self)
  if self.showButton then
    self.Button:Show()
    self.EditBox:SetTextInsets(0, 20, 3, 3)
  end
end

-------------------------------------------------------------------------------
-- SpellMenuHideButton
--
-- Hides the okay button in the editbox selector
-------------------------------------------------------------------------------
local function SpellMenuHideButton(self)
  self.Button:Hide()
  self.EditBox:SetTextInsets(0, 0, 3, 3)

  self.ContentSpellMenuFrame.SelectedButton = nil
  self.ContentSpellMenuFrame.MenuFrame:Hide()
end

-------------------------------------------------------------------------------
-- SpellMenuOnShow
--
-- Hides the spell menu editbox and restores binds, tooltips
-------------------------------------------------------------------------------
local function SpellMenuOnShow(self)
  if self.EditBox:GetText() ~= '' then
    local MenuFrame = self.MenuFrame
    MenuFrame:Show()
  end
end

-------------------------------------------------------------------------------
-- SpellMenuOnHide
--
-- Hides the spell menu editbox and restores binds, tooltips
-------------------------------------------------------------------------------
local function SpellMenuOnHide(self)

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

  -- Reset all bindings set on this spell menu
  ClearOverrideBindings(self)
end

--*****************************************************************************
--
-- Editbox for the spell menu
--
--*****************************************************************************

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
-- EditBoxOnEnterPressed
--
-- Gets called when something is entered into the edit box
-------------------------------------------------------------------------------
local function EditBoxOnEnterPressed(self)
  local Widget = self.Widget
  local ContentSpellMenuFrame = Widget.ContentSpellMenuFrame

  -- Something is selected in the spell menu, use that value instead of whatever is in the input box
  if ContentSpellMenuFrame.SelectedButton then
    ContentSpellMenuFrame.Buttons[Widget.ContentSpellMenuFrame.SelectedButton]:Click()
    return
  end

  local cancel = Widget:Fire('OnEnterPressed', self:GetText())
  if not cancel then
    SpellMenuHideButton(Widget)
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
  self.Widget:Fire('OnEnterPressed', -1)
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

    if Widget.LastText ~= '' then
      Widget.ContentSpellMenuFrame.SelectedButton = nil
      PopulateAuraMenu(Widget.ContentSpellMenuFrame)
    else
      Widget.ContentSpellMenuFrame.MenuFrame:Hide()
    end

    SpellMenuShowButton(Widget)
  end
end

-------------------------------------------------------------------------------
-- EditBoxOnFocusGained
--
-- Gets called when the edit box loses focus
-------------------------------------------------------------------------------
local function EditBoxOnEditFocusGained(self)
  SpellMenuOnShow(self.Widget.ContentSpellMenuFrame)
  AceGUI:SetFocus(self.Widget.MenuFrame)
end

-------------------------------------------------------------------------------
-- EditBoxOnFocusLost
--
-- Gets called when the edit box loses focus
-------------------------------------------------------------------------------
local function EditBoxOnEditFocusLost(self)
  if Main:MouseInRect(self.Widget.MenuFrame) then
    SpellMenuOnHide(self.Widget.ContentSpellMenuFrame)
  end
end

-------------------------------------------------------------------------------
-- EditBoxButtonOnclick
--
-- called when the 'edit' button in the edit box is clicked
-------------------------------------------------------------------------------
local function EditBoxButtonOnClick(self)
  EditBoxOnEnterPressed(self.Widget.EditBox)
end

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

  self.LastText = ''
  EditBox:SetText(Text)
  EditBox:SetCursorPosition(Cursor or 0)

  SpellMenuHideButton(self)
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
-- SpellMenuButtonOnClick
--
-- Sets the editbox to the button that was clicked in the selector
-------------------------------------------------------------------------------
local function SpellMenuButtonOnClick(self, ...)
  local Name = C_Spell_GetSpellName(self.SpellID)
  local Parent = self.parent

  EditBoxSetText(self.parent.Widget, Name, #Name)

  Parent.SelectedButton = nil
  Parent.Widget:Fire('OnEnterPressed', Name, self.SpellID)
end

-------------------------------------------------------------------------------
-- SpellMenuButtonOnEnter
--
-- Highlights the spell menu button when the mouse enters the button area
-------------------------------------------------------------------------------
local function SpellMenuButtonOnEnter(self)
  self.parent.SelectedButton = nil
  self:LockHighlight()
  StartSpellTooltipTimer(self, self.SpellID, 'ANCHOR_BOTTOMRIGHT')
end

-------------------------------------------------------------------------------
-- SpellMenuButtonOnLeave
--
-- Highlights the spell menu button when the mouse enters the button area
-------------------------------------------------------------------------------
local function SpellMenuButtonOnLeave(self)
  self:UnlockHighlight()
  StopSpellTooltipTimer()
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
-- Creates a button for the spell menu frame.
--
-- ContentSpellMenuFrame  Frame the will contain the buttons
-- EditBox                Reference to the EditBox
-- Index                  Button Index, needed for setpoint
--
-- Returns
--   Button           Created buttom.
-------------------------------------------------------------------------------
local function CreateButton(ContentSpellMenuFrame, EditBox, Index)
  local Buttons = ContentSpellMenuFrame.Buttons
  local Button = CreateFrame('Button', nil, ContentSpellMenuFrame)

  Button:SetHeight(17)
  Button:SetWidth(1)
  Button:SetPushedTextOffset(-2, 0)
  Button:SetScript('OnClick', SpellMenuButtonOnClick)
  Button:SetScript('OnEnter', SpellMenuButtonOnEnter)
  Button:SetScript('OnLeave', SpellMenuButtonOnLeave)
  Button.parent = ContentSpellMenuFrame
  Button.EditBox = EditBox
  Button:Hide()

  if Index > 1 then
    Button:SetPoint('TOPLEFT', Buttons[Index - 1], 'BOTTOMLEFT')
    Button:SetPoint('TOPRIGHT', Buttons[Index - 1], 'BOTTOMRIGHT')
  else
    Button:SetPoint('TOPLEFT', ContentSpellMenuFrame, 12, -1)
    Button:SetPoint('TOPRIGHT', ContentSpellMenuFrame, -7, 0)
  end

  -- Create the actual text
  local Text = Button:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  Text:SetHeight(1)
  Text:SetWidth(1)
  Text:SetJustifyH('LEFT')
  Text:SetAllPoints()
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

  GetSpellIDs()
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
  self.ContentSpellMenuFrame.MenuFrame:Hide()
  self.SpellFilter = nil

  self:SetDisabled(false)
end

-------------------------------------------------------------------------------
-- EditBoxSpellMenuWidget
--
-- Base for spell menu and talent menu
-------------------------------------------------------------------------------
local function EditBoxSpellMenuWidget()
  local Frame = CreateFrame('Frame', nil, UIParent)
  local EditBox = CreateFrame('EditBox', nil, Frame, 'InputBoxTemplate')

  local MenuFrame = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
  MenuFrame:SetBackdrop(SpellMenuBackdrop)
  MenuFrame:SetBackdropColor(0, 0, 0, 0.85)
  MenuFrame:SetWidth(1)
  MenuFrame:SetHeight(150)
  MenuFrame:SetPoint('TOPLEFT', EditBox, 'BOTTOMLEFT', -6, 0)
  MenuFrame:SetWidth(SpellsMenuFrameWidth)
  MenuFrame:SetFrameStrata('TOOLTIP')
  MenuFrame:SetClampedToScreen(true)
  MenuFrame:Hide()

  -- Create the scroll frame
  local ScrollFrame = CreateFrame('ScrollFrame', nil, MenuFrame)
  ScrollFrame:SetPoint('TOPLEFT', 0, -6)
  ScrollFrame:SetPoint('BOTTOMRIGHT', -28, 6)

    local ContentSpellMenuFrame = CreateFrame('Frame', nil, ScrollFrame)
    local Buttons = {}

    ContentSpellMenuFrame:SetSize(SpellsMenuFrameWidth, 2000)
    ContentSpellMenuFrame.PopulateAuraMenu = PopulateAuraMenu
    ContentSpellMenuFrame.EditBox = EditBox
    ContentSpellMenuFrame.Buttons = Buttons
    ContentSpellMenuFrame.MenuFrame = MenuFrame
    ContentSpellMenuFrame.ScrollFrame = ScrollFrame

  ScrollFrame:SetScrollChild(ContentSpellMenuFrame)

  -- Create the scroller
  local Scroller = CreateFrame('slider', nil, ScrollFrame, 'BackdropTemplate')
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
  ContentSpellMenuFrame.Scroller = Scroller

  -- Create the mass of spell menu rows
  for Index = 1, MaxSpellMenuLines + 1 do
    Buttons[Index] = CreateButton(ContentSpellMenuFrame, EditBox, Index)
  end

  -- Set the main info things for this thingy
  local Widget = {}

  Widget.frame = Frame

  Widget.OnRelease = OnRelease
  Widget.OnAcquire = OnAcquire

  Widget.SetDisabled = EditBoxSetDisabled
  Widget.SetText = EditBoxSetText
  Widget.SetLabel = EditBoxSetLabel

  Widget.MenuFrame = MenuFrame
  Widget.ContentSpellMenuFrame = ContentSpellMenuFrame
  Widget.EditBox = EditBox

  Widget.alignoffset = 30

  Frame:SetHeight(44)
  Frame:SetWidth(200)

  Frame.Widget = Widget
  EditBox.Widget = Widget
  MenuFrame.Widget = Widget
  ContentSpellMenuFrame.Widget = Widget

  EditBox:SetScript('OnEnter', EditBoxOnEnter)
  EditBox:SetScript('OnLeave', EditBoxOnLeave)

  EditBox:SetAutoFocus(false)
  EditBox:SetFontObject(ChatFontNormal)
  EditBox:SetScript('OnEscapePressed', EditBoxOnEscapePressed)
  EditBox:SetScript('OnEnterPressed', EditBoxOnEnterPressed)
  EditBox:SetScript('OnTextChanged', EditBoxOnTextChanged)
  EditBox:SetScript('OnEditFocusGained', EditBoxOnEditFocusGained)

  -- Set focus takes care of this now
  --EditBox:SetScript('OnEditFocusLost', EditBoxOnEditFocusLost)

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

  -- These two lines insure that the menu will get closed if clicked outside
  MenuFrame.ClearFocus = function(self) SpellMenuOnHide(self.Widget.ContentSpellMenuFrame) end
  Scroller:SetScript('OnMouseDown', function()  AceGUI:SetFocus(MenuFrame)  end)

  Widget.Button = Button
  Button.Widget = Widget

  AceGUI:RegisterAsWidget(Widget)
  AceGUI:SetFocus(MenuFrame)

  return Widget
end

-------------------------------------------------------------------------------
-- AuraMenuConstructor
--
-- Creates the widget for the edit box and aura menu
--
-- Notes: If escape is pressed. Then a -1 is returned instead of what was entered
--        into the edit box
-------------------------------------------------------------------------------
local function AuraMenuConstructor()
  local Widget = EditBoxSpellMenuWidget()
  Widget.type = EditBoxWidgetType

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
-------------------------------------------------------------------------------
local function AuraEditBoxConstructor()
  return AceGUI:Create(EditBoxWidgetType)
end

AceGUI:RegisterWidgetType(EditBoxWidgetType, AuraMenuConstructor, EditBoxWidgetVersion)
AceGUI:RegisterWidgetType(AuraEditBoxWidgetType, AuraEditBoxConstructor, AuraEditBoxWidgetVersion)

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
-- SpellInfoSetText
--
-- Sets the spell icon, size, and text
--
-- See constructor for examples
--
-- self       Widget
-- Text       SpellID, size, and text
-------------------------------------------------------------------------------
local function SpellInfoSetText(self, Text)
  local Name
  local Icon
  local SpellID
  local IconSize
  local FontSize

  local IconFrame = self.IconFrame
  local IconLabel = self.IconLabel
  local IconTexture = self.IconTexture

  if strfind(Text, '::', 1, true) == nil then
    SpellID, IconSize, FontSize, Text = strsplit(':', Text, 4)

    SpellID = tonumber(SpellID)
    IconSize = tonumber(IconSize)

    -- Set up the icon and position
    if SpellID == 0 then
      Icon = [[INTERFACE\ICONS\INV_MISC_QUESTIONMARK]]
      Name = nil
    else
      Name = C_Spell_GetSpellName(SpellID)
      Icon = C_Spell_GetSpellTexture(SpellID)
    end

    IconTexture:SetTexture(Icon)
    IconFrame:Show()
    IconFrame:SetSize(IconSize, IconSize)

    -- This sets the height of Widget.frame
    self:SetHeight(IconSize)
  else
    FontSize, _, Text = strsplit(':', Text, 3)
    IconFrame:Hide()
    IconFrame:SetSize(0, 0)
    IconSize = -5
  end

  FontSize = tonumber(FontSize)

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
  StartSpellTooltipTimer(self, self.SpellID, 'ANCHOR_RIGHT')
end

-------------------------------------------------------------------------------
-- IconFrameOnLeave
--
-- Removes the spell info tool tip when the mouse leaves the icon
--
-- self   IconFrame
-------------------------------------------------------------------------------
local function IconFrameOnLeave(self)
  StopSpellTooltipTimer()
end

-------------------------------------------------------------------------------
-- SpellInfoConstructor
--
-- Creates an icon with text.  Can mouse over icon for spell info.
--
-- To use this in ace-config.  Use type = 'description'
-- fontsize gets ignored
--
-- In the 'name' field you specify the spell ID, iconsize, and fontsize, followed by text
-- Example:  10750:32:14:This is some text
--
-- OR
--
-- fontsize::text
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
  IconLabel:SetJustifyV('MIDDLE')

  IconFrame:SetPoint('TOPLEFT')
  IconTexture:SetAllPoints()

  Widget.frame = Frame
  Widget.type = SpellInfoWidgetType
  Widget.OnAcquire = SpellInfoOnAcquire

  Widget.IconFrame = IconFrame
  Widget.IconTexture = IconTexture
  Widget.IconLabel = IconLabel

  -- Set functions for ace config dialog
  --Widget.SetLabel =
  Widget.SetText = SpellInfoSetText
  Widget.SetFontObject = function() end

  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(SpellInfoWidgetType, SpellInfoConstructor, SpellInfoWidgetVersion)

--*****************************************************************************
--
-- Dropdown Select. Same as pulldowns, but with a scrollbar
--
--*****************************************************************************
local function SetPointItemFrame(ItemFrame, ScrollFrame, Offset)
  ItemFrame:ClearAllPoints()
  ItemFrame:SetPoint('TOPLEFT', ScrollFrame, 'TOPLEFT', 0, Offset or 0)
  ItemFrame:SetPoint('TOPRIGHT', ScrollFrame, 'TOPRIGHT', -24, Offset or 0)
end

-- Setup pullout
local function SetupPullout(Widget)
  local Pullout = Widget.pullout
  local Slider = Pullout.slider
  local ScrollFrame = Pullout.scrollFrame
  local ItemFrame = Pullout.itemFrame

  -- Store original values in userdata
  local UserData = WidgetUserData[Widget]
  if UserData == nil then
    UserData = {}
    WidgetUserData[Widget] = UserData
  end

  -- Reset slider was causing a bug when one menu was clicked outside.
  -- then another menu was clicked inside
  UserData.SliderValue = Slider:GetValue()
  Slider:SetValue(0)

  -- OnScrollValueChanged
  -- The ItemFrame needs to be set again since SetScroll changes it
  local OldSetScroll = Pullout.SetScroll
  UserData.SetScroll = OldSetScroll
  Pullout.SetScroll = function(self, Value)
    OldSetScroll(self, Value)
    SetPointItemFrame(ItemFrame, ScrollFrame, Pullout.scrollStatus.offset)
  end

  local SliderPoints = UserData.SliderPoints
  if SliderPoints == nil then
    SliderPoints = {}
    UserData.SliderPoints = SliderPoints
  end
  local ItemFramePoints = UserData.ItemFramePoints
  if ItemFramePoints == nil then
    ItemFramePoints = {}
    UserData.ItemFramePoints = ItemFramePoints
  end

  -- Save all points
  for PointIndex = 1, Slider:GetNumPoints() do
    SliderPoints[PointIndex] = { Slider:GetPoint(PointIndex) }
  end
  for PointIndex = 1, ItemFrame:GetNumPoints() do
    ItemFramePoints[PointIndex] = { ItemFrame:GetPoint(PointIndex) }
  end

  -- Setup the pullout width and height
  UserData.MaxHeight = Pullout.maxHeight
  Pullout:SetMaxHeight(188)
  Widget:SetPulloutWidth(320)

  -- Move slider a few pixels to the left and make it easier to click
  Slider:SetHitRectInsets(-5, 0, -10, 0)

  UserData.SliderWidth = Slider:GetWidth()
  Slider:SetWidth(12)

  Slider:ClearAllPoints()
  Slider:SetPoint('TOPLEFT', ScrollFrame, 'TOPRIGHT', -20, 0)
  Slider:SetPoint('BOTTOMLEFT', ScrollFrame, 'BOTTOMRIGHT', -20, 0)

  SetPointItemFrame(ItemFrame, ScrollFrame)

  -- Lower the strata of the itemframe so the slider is easier to click
  -- Slider frame strata was set to 'TOOLTIP'
  UserData.ItemFrameStrata = ItemFrame:GetFrameStrata()
  ItemFrame:SetFrameStrata('FULLSCREEN_DIALOG')
end

-- Restore pullout
local function RestorePullout(Widget)
  local UserData = WidgetUserData[Widget]
  local ItemFonts = UserData.ItemFonts
  local SliderPoints = UserData.SliderPoints
  local ItemFramePoints = UserData.ItemFramePoints
  local Pullout = Widget.pullout
  local Items = Pullout.items
  local Slider = Pullout.slider
  local ItemFrame = Pullout.itemFrame

  -- Restore pullout item fonts
  for ItemFontIndex = 1, #Items do
    Items[ItemFontIndex].text:SetFontObject(ItemFonts[ItemFontIndex])
    ItemFonts[ItemFontIndex] = nil
  end

  -- Restore Slider
  Slider:SetWidth(UserData.SliderWidth)
  Slider:SetHitRectInsets(0, 0, -10, 0)
  Slider:ClearAllPoints()
  for PointIndex = 1, #SliderPoints do
    Slider:SetPoint(unpack(SliderPoints[PointIndex]))
  end

  Slider:SetValue(UserData.SliderValue)

  -- Restore SetScroll
  Pullout.SetScroll = UserData.SetScroll

  -- Restore ItemFrame
  ItemFrame:ClearAllPoints()
  for PointIndex = 1, #ItemFramePoints do
    ItemFrame:SetPoint(unpack(ItemFramePoints[PointIndex]))
  end
  Pullout:SetMaxHeight(UserData.MaxHeight)
  Pullout.itemFrame:SetFrameStrata(UserData.ItemFrameStrata)
end

-------------------------------------------------------------------------------
-- DropdownSelectConstructor
--
-- This uses an existing widget, then changes it into a custom
-- This make a menu have a scroll bar
--
-- In the 'name' field you specify name and font size (normal)
-- Example: Name:normal
-- Defaults to small if no font size specified
-------------------------------------------------------------------------------
local function DropdownSelectConstructor()
  local Widget = AceGUI:Create('Dropdown')
  Widget.type = DropdownSelectWidgetType

  -- methods
  local OldOnRelease = Widget.OnRelease
  local OldOnAcquire = Widget.OnAcquire
  local OldSetLabel  = Widget.SetLabel
  local OldSetList   = Widget.SetList

  Widget.OnRelease = function(self, ...)
    RestorePullout(self)

    -- Reset font size
    WidgetUserData[self].FontObjectSize = nil

    OldOnRelease(self, ...)
  end
  Widget.OnAcquire = function(self, ...)
    -- Only call OnAcquire if there is no pullout created
    -- This prevents two calls. Once during Create and
    -- again when this custom control is created
    if Widget.pullout == nil then
      OldOnAcquire(self, ...)
    end
    SetupPullout(self)
  end
  Widget.SetLabel = function(self, ...)
    local Text = ...
    if Text then
      local Name, FontSize = strsplit(':', Text)
      OldSetLabel(self, Name)

      -- Set font size
      local FontObjectSize
      if FontSize and FontSize == 'normal' then
        FontObjectSize = 'GameFontNormal'
      end
      WidgetUserData[self].FontObjectSize = FontObjectSize
    end
  end
  Widget.SetList = function(self, ...)
    OldSetList(self, ...)
    -- Store original values in userdata
    local UserData = WidgetUserData[self]
    local ItemFonts = UserData.ItemFonts
    if ItemFonts == nil then
      ItemFonts = {}
      UserData.ItemFonts = ItemFonts
    end
    -- Store old font objects. These gets restored in OnRelease()
    local Items = Widget.pullout.items
    for ItemFontIndex = 1, #Items do
      local Text = Items[ItemFontIndex].text
      ItemFonts[ItemFontIndex] = Text:GetFontObject()

      local FontObjectSize = WidgetUserData[self].FontObjectSize
      if FontObjectSize then
        Text:SetFontObject(FontObjectSize)
      end
    end
  end

  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(DropdownSelectWidgetType, DropdownSelectConstructor, DropdownSelectWidgetVersion)

--*****************************************************************************
--
-- EditBox_ReadOnly_Selected dialog control
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EditBoxSelectedReadOnlyOnFocusGained
--
-- Selects the text when the focus is gained
-------------------------------------------------------------------------------
local function EditBoxSelectedReadOnlyOnFocusGained(Frame)
  AceGUI:SetFocus(Frame.obj)
  Frame:HighlightText()
  Frame:SetCursorPosition(1000)
end

-------------------------------------------------------------------------------
-- EditBoxSelectedReadOnlySetText
--
-- Makes sure the text is only displayed once
-------------------------------------------------------------------------------
local function EditBoxSelectedReadOnlySetText(self, Text)
  local EditBox = self.editbox
  local ReadOnlyText = EditBox.ReadOnlyText

  if ReadOnlyText == nil then
    ReadOnlyText = Text
    EditBox.ReadOnlyText = ReadOnlyText
  end

  EditBox:SetText(ReadOnlyText or '')
  EditBox:SetCursorPosition(1000)
end

-------------------------------------------------------------------------------
-- EditBoxSelectedReadOnlyClearFocus
--
-- Resets ReadOnlyText when the edit box loses focus
-------------------------------------------------------------------------------
local function EditBoxSelectedReadOnlyClearFocus(self)
  local EditBox = self.editbox
  EditBox:ClearFocus()
  EditBox.ReadOnlyText = nil
  self.frame:SetScript('OnShow', nil)
end

-------------------------------------------------------------------------------
-- EditBoxSelectedConstructor
--
-- Creates an read only editbox that preselects all the text when clicked.
-------------------------------------------------------------------------------
local function EditBoxReadOnlySelectedConstructor()
  local Widget = Ace3Widgets:EditBox()

  -- Set on focus to select text
  local EditBox = Widget.editbox

  EditBox:SetScript('OnEditFocusGained', EditBoxSelectedReadOnlyOnFocusGained)
  EditBox:SetScript('OnTextChanged', function(self)
    if self:HasFocus() then
      self:SetText(self.ReadOnlyText)
      self:HighlightText()
    end
  end)
  EditBox:SetScript('OnChar', function(self)
    if self:HasFocus() then
      self:SetText(self.ReadOnlyText)
      self:HighlightText()
    end
  end)
  EditBox:SetScript('OnCursorChanged', function(self)
    if self:HasFocus() then
      self:HighlightText()
    end
  end)

  Widget.SetText = EditBoxSelectedReadOnlySetText
  Widget.ClearFocus = EditBoxSelectedReadOnlyClearFocus
  Widget.type = EditBoxReadOnlySelectedWidgetType

  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(EditBoxReadOnlySelectedWidgetType, EditBoxReadOnlySelectedConstructor, EditBoxReadOnlySelectedWidgetVersion)

--*****************************************************************************
--
-- MultiLine_Edit_Box dialog control
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- MultiLineEditBoxConstructor
--
-- Creates an editbox without the 'accept' button
-------------------------------------------------------------------------------
local function MultiLineEditBoxDebugConstructor()
  local Widget = Ace3Widgets:MultiLineEditBox()

  Widget.button:SetPoint('BOTTOMLEFT', 0, -197)
  Widget.DisableButton = function() end
  Widget.button:Hide()

  Widget.type = MultiLineEditBoxDebugWidgetType

  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(MultiLineEditBoxDebugWidgetType, MultiLineEditBoxDebugConstructor, MultiLineEditBoxDebugWidgetVersion)

--*****************************************************************************
--
-- MultiLine_Edit_Box_Import dialog control
-- Some code ideas borrowed from weakauras
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- MultiLineEditBoxImportConstructor
--
-- Creates an edit box to import data.  The done button gets hidden
-------------------------------------------------------------------------------
local function MultiLineEditBoxImportConstructor()
  local TextBuffer
  local Pasted
  local LastOnCharTime
  local CharCount = 0

  local Widget = Ace3Widgets:MultiLineEditBox()

  local function ImportTextBuffer(self)
    self:SetScript('OnUpdate', nil)

    Pasted = strtrim(tconcat(TextBuffer))
    TextBuffer = {}

    -- import
    if #Pasted > 20 then
      self:SetMaxBytes(2500)
      self:SetText(strsub(Pasted, 1, 2500))

      -- exit editbox and passback the pasted text
      self:ClearFocus()
      Widget:Fire('OnEnterPressed', Pasted or '')
    end
  end

  Widget.type = MultiLineEditBoxImportWidgetType

  Widget.button:SetSize(1, 1)
  Widget.button:Hide()
  -- blank this function so button don't get shown
  Widget.DisableButton = function() end

  Widget.GetText = function() return Pasted or '' end

  local EditBox = Widget.editBox
  EditBox:SetMaxBytes(2500)
  EditBox:SetScript('OnMouseUp', nil);
  EditBox:SetScript('OnTextChanged', nil)

  -- Need to do a paste this way otherwise WoW may freeze
  -- So the paste is faked a little.
  -- This idea was taken from Weakauras
  EditBox:SetScript('OnChar', function(self, Char)
    if LastOnCharTime ~= GetTime() then
      TextBuffer = {}
      CharCount = 0
      LastOnCharTime = GetTime()
      -- Call ImportTextBuffer on the next frame
      self:SetScript('OnUpdate', ImportTextBuffer)
    end
    -- Add character input to the buffer
    CharCount = CharCount + 1
    TextBuffer[CharCount] = Char
  end)
  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(MultiLineEditBoxImportWidgetType, MultiLineEditBoxImportConstructor, MultiLineEditBoxImportWidgetVersion)


--*****************************************************************************
--
-- MultiLine_Edit_Box_Export dialog control
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- MultiLineEditBoxExportOnFocusGained
--
-- Selects the text when the focus is gained
-------------------------------------------------------------------------------
local function MultiLineEditBoxExportOnFocusGained(Frame)
  AceGUI:SetFocus(Frame.obj)
  Frame:HighlightText()
  Frame:SetCursorPosition(1000)
  Frame.obj:Fire('OnEditFocusGained')
end

-------------------------------------------------------------------------------
-- MultiLineEditBoxExportSetText
--
-- Makes sure the text is only displayed once
-------------------------------------------------------------------------------
local function MultiLineEditBoxExportSetText(self, Text)
  local EditBox = self.editBox
  local ReadOnlyText = EditBox.ReadOnlyText

  if ReadOnlyText == nil then
    ReadOnlyText = Text
    EditBox.ReadOnlyText = ReadOnlyText
  end
  EditBox:SetText(ReadOnlyText or '')
end

-------------------------------------------------------------------------------
-- MultiLineEditBoxExportClearFocus
--
-- Resets ReadOnlyText when the edit box loses focus
-------------------------------------------------------------------------------
local function MultiLineEditBoxExportClearFocus(self)
  local EditBox = self.editBox
  EditBox:ClearFocus()
  EditBox.ReadOnlyText = nil
  self.frame:SetScript('OnShow', nil)
end

-------------------------------------------------------------------------------
-- MultiLineEditBoxExportConstructor
--
-- Creates a read only editbox
-------------------------------------------------------------------------------
local function MultiLineEditBoxExportConstructor()
  local Widget = Ace3Widgets:MultiLineEditBox()

  Widget.type = MultiLineEditBoxExportWidgetType
  Widget.button:SetSize(1, 1)
  Widget.button:Hide()
  -- blank this function so button don't get shown
  Widget.DisableButton = function() end

  local EditBox = Widget.editBox
  EditBox:SetScript('OnTextSet', nil)
  EditBox:SetScript('OnTextChanged', nil)

  EditBox:SetScript('OnEditFocusGained', MultiLineEditBoxExportOnFocusGained)
  EditBox:SetScript('OnChar', function(self, UserInput)
    if self:HasFocus() then
      self:SetText(self.ReadOnlyText)
      self:HighlightText()
    end
  end)
  EditBox:SetScript('OnCursorChanged', function(self)
    if self:HasFocus() then
      self:HighlightText()
    end
  end)
  EditBox:SetMaxBytes(0)

  Widget.SetText = MultiLineEditBoxExportSetText
  Widget.ClearFocus = MultiLineEditBoxExportClearFocus

  return AceGUI:RegisterAsWidget(Widget)
end

AceGUI:RegisterWidgetType(MultiLineEditBoxExportWidgetType, MultiLineEditBoxExportConstructor, MultiLineEditBoxExportWidgetVersion)

