--
-- EmberBar.lua
--
-- Displays the Warlock Burning Embers bar.

-------------------------------------------------------------------------------
-- GUB   shared data table between all parts of the addon
-------------------------------------------------------------------------------
local MyAddon, GUB = ...

local Main = GUB.Main
local Bar = GUB.Bar
local Options = GUB.Options

local ConvertPowerType = Main.ConvertPowerType

-- localize some globals.
local _
local abs, mod, max, floor, ceil, mrad,     mcos,     msin,     sqrt =
      abs, mod, max, floor, ceil, math.rad, math.cos, math.sin, math.sqrt
local strfind, strsplit, strsub, strupper, strlower, strmatch, format, strconcat, gsub, tonumber =
      strfind, strsplit, strsub, strupper, strlower, strmatch, format, strconcat, gsub, tonumber
local pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe =
      pcall, pairs, ipairs, type, select, next, print, sort, tremove, unpack, wipe
local GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip =
      GetTime, MouseIsOver, IsModifierKeyDown, GameTooltip
local UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown =
      UnitHasVehicleUI, UnitIsDeadOrGhost, UnitAffectingCombat, UnitExists, HasPetUI, IsSpellKnown
local UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax =
      UnitPowerType, UnitClass, UnitHealth, UnitHealthMax, UnitPower, UnitBuff, UnitPowerMax
local UnitName, UnitGetIncomingHeals, GetRealmName =
      UnitName, UnitGetIncomingHeals, GetRealmName
local GetRuneCooldown, GetRuneType, GetSpellInfo, GetTalentInfo, PlaySound =
      GetRuneCooldown, GetRuneType, GetSpellInfo, GetTalentInfo, PlaySound
local GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID =
      GetComboPoints, GetShapeshiftFormID, GetSpecialization, GetEclipseDirection, GetInventoryItemID
local CreateFrame, UnitGUID, getmetatable, setmetatable =
      CreateFrame, UnitGUID, getmetatable, setmetatable
local C_PetBattles, UIParent =
      C_PetBattles, UIParent

-------------------------------------------------------------------------------
-- Locals

-- UnitBarF = UnitBarsF[]
--
-- UnitBarF.BBar                     Contains the ember bar displayed on screen.
--
-- UnitBarF.GreenFire                This key is made inside of Update(). Used with GreenFireAuto or GreenFire
--                                   option setting.  Used by Update() and SetAttr()
--
-- EmberData                         Contains all the data for the ember bar texture.
--   Texture                         Path name to the texture file.
--   TextureGreen                    Same as Texture except its green themed.
--   TextureWidth, TextureHeight     Box size and size of the TextureFrame for texture mode.
--   [TextureType]
--     Point                         Texture point within the TextureFrame.
--     OffsetX, OffsetY              Offset from the point location of where the texture is placed.
--     Width, Height                 Width and Height of the texture.
--     Left, Right, Top, Bottom      Coordinates inside the main texture for the texture we need.
--
-- EmberSBar                         Contains the box for box mode.
-- EmberFierySBar                    Contains the on fire color for box mode.
-- EmberBgTexture                    Background texture for the ember bar.
-- EmberTexture                      Fill texture for showing the ember fill up.
-- EmberFieryTexture                 Fire texture shown after the ember is filled.
-- Fiery                             Change Number for hiding and showing fiery bar/texture.
-- EmberFill                         Change Number to set fill to bar/texture.
--
-- MaxPowerPerEmber                  Amount of power for each ember.
--
-- BarOffsetX, BarOffsetY            Offset the whole bar within the border.
-------------------------------------------------------------------------------
local MaxEmbers = 4
local Display = false

local MaxPowerPerEmber = MAX_POWER_PER_EMBER
local WarlockGreenFire = WARLOCK_GREEN_FIRE

-- Powertype constants
local PowerEmber = ConvertPowerType['BURNING_EMBERS']

-- Ember Texture constants
local BoxMode = 1
local TextureMode = 2

local Fiery = 3
local EmberFill = 4

local EmberSBar = 10
local EmberFierySBar = 11
local EmberBgTexture = 20
local EmberTexture = 21
local EmberFieryTexture = 22

local BarOffsetX = 0
local BarOffsetY = 2

local EmberData = {
  Texture = [[Interface\PlayerFrame\Warlock-DestructionUI]],
  TextureGreen = [[Interface\PlayerFrame\Warlock-DestructionUI-Green]],

  -- TextureFrame size.
  TextureWidth = 36, TextureHeight = 39 + 3,
  [EmberBgTexture] = {
    Level = 1,
    Point = 'BOTTOM',
    OffsetX = 0  + BarOffsetX, OffsetY = 0 + BarOffsetY,
    Width = 36, Height= 39,
    Left = 0.15234375, Right = 0.29296875, Top = 0.32812500, Bottom = 0.93750000,
  },
  [EmberTexture] = {
    Level = 2,
    Point = 'BOTTOM',
    OffsetX = 0 + BarOffsetX, OffsetY = 7 + BarOffsetY,
    Width = 20, Height = 22,
    Left = 0.30078125, Right = 0.37890625, Top = 0.32812500, Bottom = 0.67187500,
  },
  [EmberFieryTexture] = {
    Level = 3,
    Point = 'BOTTOM',
    OffsetX = 0 + BarOffsetX, OffsetY = 0 + BarOffsetY,
    Width = 36, Height = 39,
    Left = 0.00390625, Right = 0.14453125, Top = 0.32812500, Bottom = 0.93750000,
  }
}

-------------------------------------------------------------------------------
-- Statuscheck    UnitBarsF function
-------------------------------------------------------------------------------
Main.UnitBarsF.EmberBar.StatusCheck = GUB.Main.StatusCheck

--*****************************************************************************
--
-- Emberbar display
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- Update    UnitBarsF function
--
-- Update the ember bar.
--
-- Event        Event that called this function.  If nil then it wasn't called by an event.
-- Unit         Unit can be 'target', 'player', 'pet', etc.
-- PowerType    Type of power the unit has.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EmberBar:Update(Event, Unit, PowerType)

  -- Check if bar is not visible or has active flag waiting for activity.
  if not self.Visible and self.IsActive ~= 0 then
    return
  end

  PowerType = PowerType and ConvertPowerType[PowerType] or PowerEmber

  -- Return if not the correct powertype.
  if PowerType ~= PowerEmber then
    return
  end

  local BBar = self.BBar
  local EmberPower = UnitPower('player', PowerEmber, true)
  local MaxEmberPower = UnitPowerMax('player', PowerEmber, true)
  local ShowFiery = nil

  if Main.UnitBars.Testing then
    local TestMode = self.UnitBar.TestMode
    ShowFiery = TestMode.ShowFiery

    if TestMode.MaxResource then
      EmberPower = MaxPowerPerEmber * MaxEmbers
    else
      EmberPower = 0
    end
  end

  local NumEmbers = floor(MaxEmberPower / MaxPowerPerEmber)

  -- Set default value if NumEmbers returns zero.
  NumEmbers = NumEmbers > 0 and NumEmbers or MaxEmbers

  -- Check for green fire if auto is set
  local Gen = self.UnitBar.General
  local GreenFire = Gen.GreenFireAuto and IsSpellKnown(WarlockGreenFire) or Gen.GreenFire
  if self.GreenFire ~= GreenFire then
    self.GreenFire = GreenFire
    self:SetAttr()
    Options:RefreshOptions()
  end
  local EmberPower2 = EmberPower

  for EmberIndex = 1, NumEmbers do
    local Value = 1

    if EmberPower2 <= MaxPowerPerEmber then
      Value = EmberPower2 / MaxPowerPerEmber
      if Value < 0 then
        Value = 0
      end
    end

    BBar:ChangeTexture(EmberFill, 'SetFillTexture', EmberIndex, Value)
    if ShowFiery == nil then
      BBar:ChangeTexture(Fiery, 'SetHiddenTexture', EmberIndex, EmberPower2 < MaxPowerPerEmber)
    else
      BBar:ChangeTexture(Fiery, 'SetHiddenTexture', EmberIndex, not ShowFiery)
    end

    -- Left over for next ember.
    EmberPower2 = EmberPower2 - MaxPowerPerEmber
  end

  -- Set the IsActive flag
  self.IsActive = EmberPower ~= MaxPowerPerEmber

  -- Do a status check.
  self:StatusCheck()
end

--*****************************************************************************
--
-- emberbar creation/setting
--
--*****************************************************************************

-------------------------------------------------------------------------------
-- EnableMouseClicks    UnitBarsF function
--
-- This will enable or disbable mouse clicks for the ember bar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EmberBar:EnableMouseClicks(Enable)
  local BBar = self.BBar

  -- Enable/disable for border.
  BBar:EnableMouseClicksRegion(Enable)

  -- ENable/disable for box mode
  BBar:EnableMouseClicks(0, nil, Enable)
end

-------------------------------------------------------------------------------
-- SetAttr    UnitBarsF function
--
-- Sets different parts of the Emberbar.
-------------------------------------------------------------------------------
function Main.UnitBarsF.EmberBar:SetAttr(TableName, KeyName)
  local BBar = self.BBar

  if not BBar:OptionsSet() then

    BBar:SO('Other', '_', function() Main:UnitBarSetAttr(self) end)

    BBar:SO('Layout', 'BoxMode',        function(v)
      if v then

        -- Box mode
        BBar:ShowRowTextureFrame(BoxMode)
        BBar:SetChangeTexture(EmberFill, EmberSBar)
      else
        -- texture mode
        BBar:ShowRowTextureFrame(TextureMode)
        BBar:SetChangeTexture(EmberFill, EmberTexture)
      end
      BBar:DoOption()
      Display = true
    end)
    BBar:SO('Layout', 'HideRegion',    function(v) BBar:SetHiddenRegion(v) Display = true end)
    BBar:SO('Layout', 'Swap',          function(v) BBar:SetSwapBar(v) end)
    BBar:SO('Layout', 'Float',         function(v) BBar:SetFloatBar(v) Display = true end)
    BBar:SO('Layout', 'ReverseFill',   function(v) BBar:ChangeTexture(EmberFill, 'SetFillReverseTexture', 0, v) end)
    BBar:SO('Layout', 'BorderPadding', function(v) BBar:SetPaddingBorder(v) Display = true end)
    BBar:SO('Layout', 'Rotation',      function(v) BBar:SetRotationBar(v) Display = true end)
    BBar:SO('Layout', 'Slope',         function(v) BBar:SetSlopeBar(v) Display = true end)
    BBar:SO('Layout', 'Padding',       function(v) BBar:SetPaddingBox(0, v) Display = true end)
    BBar:SO('Layout', 'SmoothFill',    function(v) BBar:ChangeTexture(EmberFill, 'SetFillSmoothTimeTexture', 0, v) end)
    BBar:SO('Layout', 'TextureScale',  function(v) BBar:SetScaleTextureFrame(0, TextureMode, v) Display = true end)
    BBar:SO('Layout', 'FadeInTime',    function(v) BBar:SetFadeTimeTexture(0, EmberFierySBar, 'in', v)
                                                   BBar:SetFadeTimeTexture(0, EmberFieryTexture, 'in', v) end)
    BBar:SO('Layout', 'FadeOutTime',   function(v) BBar:SetFadeTimeTexture(0, EmberFierySBar, 'out', v)
                                                   BBar:SetFadeTimeTexture(0, EmberFieryTexture, 'out', v) end)
    BBar:SO('Layout', 'Align',         function(v) BBar:SetAlignBar(v) end)
    BBar:SO('Layout', 'AlignPaddingX', function(v) BBar:SetAlignPaddingBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignPaddingY', function(v) BBar:SetAlignPaddingBar(nil, v) Display = true end)
    BBar:SO('Layout', 'AlignOffsetX',  function(v) BBar:SetAlignOffsetBar(v, nil) Display = true end)
    BBar:SO('Layout', 'AlignOffsetY',  function(v) BBar:SetAlignOffsetBar(nil, v) Display = true end)

    BBar:SO('General', 'GreenFire',     function(v) self:Update() end)
    BBar:SO('General', 'GreenFireAuto', function(v)
      self:Update()
      local GreenFire = self.GreenFire

      for EmberIndex = 1, MaxEmbers do
        for TextureNumber, ED in pairs(EmberData) do
          if type(TextureNumber) == 'number' then
            BBar:SetTexture(EmberIndex, TextureNumber, GreenFire and EmberData.TextureGreen or EmberData.Texture)
          end
        end
      end
    end)

    BBar:SO('Region', 'BackdropSettings', function(v) BBar:SetBackdropRegion(v) end)
    BBar:SO('Region', 'Color',            function(v) BBar:SetBackdropColorRegion(v.r, v.g, v.b, v.a) end)

    BBar:SO('Background', 'BackdropSettings', function(v) BBar:SetBackdrop(0, BoxMode, v) end)
    BBar:SO('Background', 'Color',            function(v, UB, OD)
      if not self.GreenFire then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Background', 'ColorGreen',       function(v, UB, OD)
      if self.GreenFire then
        BBar:SetBackdropColor(OD.Index, BoxMode, OD.r, OD.g, OD.b, OD.a)
      end
    end)

    BBar:SO('Bar', 'StatusBarTexture',      function(v) BBar:SetTexture(0, EmberSBar, v) end)
    BBar:SO('Bar', 'FieryStatusBarTexture', function(v) BBar:SetTexture(0, EmberFierySBar, v) end)
    BBar:SO('Bar', 'FillDirection',         function(v) BBar:SetFillDirectionTexture(0, EmberSBar, v) end)
    BBar:SO('Bar', 'RotateTexture',         function(v) BBar:SetRotateTexture(0, EmberSBar, v)
                                                        BBar:SetRotateTexture(0, EmberFierySBar, v) end)
    BBar:SO('Bar', 'Color',                 function(v, UB, OD)
      if not self.GreenFire then
        BBar:SetColorTexture(OD.Index, EmberSBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorFiery',            function(v, UB, OD)
      if not self.GreenFire then
        BBar:SetColorTexture(OD.Index, EmberFierySBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorGreen',            function(v, UB, OD)
      if self.GreenFire then
        BBar:SetColorTexture(OD.Index, EmberSBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', 'ColorFieryGreen',       function(v, UB, OD)
      if self.GreenFire then
        BBar:SetColorTexture(OD.Index, EmberFierySBar, OD.r, OD.g, OD.b, OD.a)
      end
    end)
    BBar:SO('Bar', '_Size',                 function(v, UB) BBar:SetSizeTextureFrame(0, BoxMode, v.Width, v.Height) Display = true end)
    BBar:SO('Bar', 'Padding',               function(v) BBar:SetPaddingTexture(0, EmberSBar, v.Left, v.Right, v.Top, v.Bottom)
                                                        BBar:SetPaddingTexture(0, EmberFierySBar, v.Left, v.Right, v.Top, v.Bottom) Display = true end)
  end

  -- Do the option.  This will call one of the options above or all.
  BBar:DoOption(TableName, KeyName)

  if Main.UnitBars.Testing then
    self:Update()
  end

  if Display then
    BBar:Display()
    Display = false
  end
end

-------------------------------------------------------------------------------
-- CreateBar
--
-- UnitBarF     The unitbar frame which will contain the ember bar.
-- UB           Unitbar data.
-- ScaleFrame   ScaleFrame which the unitbar must be a child of for scaling.
-------------------------------------------------------------------------------
function GUB.EmberBar:CreateBar(UnitBarF, UB, ScaleFrame)
  local BBar = Bar:CreateBar(UnitBarF, ScaleFrame, MaxEmbers)

  local ColorAllNames = {}

  -- Create box mode.
  BBar:CreateTextureFrame(0, BoxMode, 0)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 1, EmberSBar)
    BBar:CreateTexture(0, BoxMode, 'statusbar', 2, EmberFierySBar)

  -- Create texture mode.
  for EmberIndex = 1, MaxEmbers do
    BBar:CreateTextureFrame(EmberIndex, TextureMode, 0)

    for TextureNumber, ED in pairs(EmberData) do
      if type(TextureNumber) == 'number' then
        BBar:CreateTexture(EmberIndex, TextureMode, 'texture', ED.Level, TextureNumber)

        BBar:SetTexture(EmberIndex, TextureNumber, EmberData.Texture)
        BBar:SetCoordTexture(EmberIndex, TextureNumber, ED.Left, ED.Right, ED.Top, ED.Bottom)
        BBar:SetSizeTexture(EmberIndex, TextureNumber, ED.Width, ED.Height)
        BBar:SetPointTexture(EmberIndex, TextureNumber, ED.Point, ED.OffsetX, ED.OffsetY)
      end
    end

    -- Set default fill.
    BBar:SetFillDirectionTexture(EmberIndex, EmberSBar, 'VERTICAL')
    BBar:SetFillDirectionTexture(EmberIndex, EmberTexture, 'VERTICAL')

    local Name = 'Burning Ember ' .. EmberIndex

    BBar:SetTooltip(EmberIndex, nil, Name)
    ColorAllNames[EmberIndex] = Name
  end

  -- Show the ember background and fill
  BBar:SetHiddenTexture(0, EmberSBar, false)
  BBar:SetHiddenTexture(0, EmberBgTexture, false)
  BBar:SetHiddenTexture(0, EmberTexture, false)

  BBar:SetSizeTextureFrame(0, BoxMode, UB.Bar.Width, UB.Bar.Height)
  BBar:SetSizeTextureFrame(0, TextureMode, EmberData.TextureWidth, EmberData.TextureHeight)

  BBar:SetChangeTexture(Fiery, EmberFieryTexture, EmberFierySBar)

  BBar:SetTooltipRegion(UB.Name)
  UnitBarF.ColorAllNames = ColorAllNames

  UnitBarF.BBar = BBar
end

--*****************************************************************************
--
-- Emberbar Enable/Disable functions
--
--*****************************************************************************

function Main.UnitBarsF.EmberBar:Enable(Enable)
  Main:RegEventFrame(Enable, self, 'UNIT_POWER_FREQUENT', self.Update, 'player')
end


