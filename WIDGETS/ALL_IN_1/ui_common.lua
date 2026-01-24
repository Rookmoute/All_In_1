-- /WIDGETS/All_IN_1/ui_common.lua
-- Fonctions d'UI communes aux modes arcs et leds (OPTIMISÉ)

local helpers = loadScript("/WIDGETS/All_IN_1/helpers.lua")()
local clamp = helpers.clamp
local safeRGB = helpers.safeRGB
local formatTime = helpers.formatTime

local M = {}

-- Constantes pour éviter les calculs répétés
local POPUP_CONFIGS = {
  displayMode = {w = 200, h = 110, offsetX = 10, offsetY = -20},
  capacity = {w = 200, h = 160, offsetX = 10, offsetY = -20},
  exitFullscreen = {w = 240, h = 100, offsetX = 10, offsetY = 40}
}

local DEBOUNCE_TIME = 20 -- centièmes de seconde
local STARTUP_BLINK_DURATION = 10 -- secondes

-- Fonction helper pour l'anti-rebond
local function isDebounced(widget, lastTimeKey, currentTime)
  local lastTime = widget[lastTimeKey]
  if lastTime and (currentTime - lastTime) < DEBOUNCE_TIME then
    return true
  end
  widget[lastTimeKey] = currentTime
  return false
end

-- Icône d'écran (bouton de mode)
function M.drawScreenIcon(x, y, size, color)
  lcd.drawRectangle(x, y, size, size * 0.7, color, 2)
  local footWidth = size * 0.4
  local footHeight = size * 0.15
  lcd.drawFilledRectangle(x + (size - footWidth) / 2, y + size * 0.7, footWidth, footHeight, color)
  lcd.drawFilledRectangle(x + size * 0.2, y + size * 0.85, size * 0.6, 2, color)
end

-- Helper pour dessiner un bouton de popup
local function drawPopupOption(popupX, popupY, popupW, optionY, text, isSelected, selectedColor, selectedBorder)
  local bgColor = isSelected and selectedColor or safeRGB(30, 30, 30)
  lcd.drawFilledRectangle(popupX + 15, optionY - 3, popupW - 30, 26, bgColor)
  
  if isSelected then
    lcd.setColor(CUSTOM_COLOR, selectedBorder)
    lcd.drawRectangle(popupX + 15, optionY - 3, popupW - 30, 26, CUSTOM_COLOR, 2)
  end
  
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 255, 255))
  lcd.drawText(popupX + popupW / 2, optionY, text, SMLSIZE + CENTER + CUSTOM_COLOR)
end

-- Fonction pour dessiner le popup de sélection du mode
function M.drawDisplayModePopup(widget)
  local z = widget.z
  local baseY = widget.baseY
  local cfg = POPUP_CONFIGS.displayMode
  local popupX = z.x + cfg.offsetX
  local popupY = baseY + cfg.offsetY
  
  lcd.drawFilledRectangle(z.x, z.y, z.w, z.h, safeRGB(0, 0, 0))
  lcd.drawFilledRectangle(popupX, popupY, cfg.w, cfg.h, safeRGB(40, 40, 40))
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 200, 0))
  lcd.drawRectangle(popupX, popupY, cfg.w, cfg.h, CUSTOM_COLOR, 3)
  
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 255, 255))
  lcd.drawText(popupX + cfg.w / 2, popupY + 8, "MODE", SMLSIZE + CENTER + CUSTOM_COLOR)
  
  local optionY = popupY + 30
  drawPopupOption(popupX, popupY, cfg.w, optionY, "LEDS", 
    widget.displayModeEditValue == 0, safeRGB(80, 80, 0), safeRGB(255, 255, 0))
  drawPopupOption(popupX, popupY, cfg.w, optionY + 32, "ARCS", 
    widget.displayModeEditValue == 1, safeRGB(80, 80, 0), safeRGB(255, 255, 0))
  
  lcd.setColor(CUSTOM_COLOR, safeRGB(200, 200, 200))
  lcd.drawText(popupX + cfg.w / 2, popupY + cfg.h - 20, "+/- | Enter", SMLSIZE + CENTER + CUSTOM_COLOR)
end

function M.drawCapacityPopup(widget)
  local z = widget.z
  local baseY = widget.baseY
  local cfg = POPUP_CONFIGS.capacity
  local popupX = z.x + cfg.offsetX
  local popupY = baseY + cfg.offsetY
  
  lcd.drawFilledRectangle(z.x, z.y, z.w, z.h, safeRGB(0, 0, 0, 50))
  lcd.drawFilledRectangle(popupX, popupY, cfg.w, cfg.h, safeRGB(40, 40, 40))
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 200, 0))
  lcd.drawRectangle(popupX, popupY, cfg.w, cfg.h, CUSTOM_COLOR, 3)
  
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 255, 255))
  lcd.drawText(popupX + cfg.w / 2, popupY + 5, "CAPA", SMLSIZE + CENTER + CUSTOM_COLOR)
  
  local currentValue = widget.capacityEditValue or 50
  local centerY = popupY + 70
  
  -- Bouton +
  local plusButtonY = centerY - 45
  lcd.drawFilledRectangle(popupX + 25, plusButtonY - 2, cfg.w - 50, 22, safeRGB(60, 120, 60))
  lcd.setColor(CUSTOM_COLOR, safeRGB(0, 255, 0))
  lcd.drawRectangle(popupX + 25, plusButtonY - 2, cfg.w - 50, 22, CUSTOM_COLOR, 2)
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 255, 255))
  lcd.drawText(popupX + cfg.w / 2, plusButtonY - 6, "+", MIDSIZE + CENTER + CUSTOM_COLOR)
  
  -- Valeur centrale
  lcd.drawFilledRectangle(popupX + 25, centerY - 8, cfg.w - 50, 36, safeRGB(80, 80, 0))
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 255, 0))
  lcd.drawRectangle(popupX + 25, centerY - 8, cfg.w - 50, 36, CUSTOM_COLOR, 2)
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 255, 255))
  lcd.drawText(popupX + cfg.w / 2, centerY - 4, string.format("%d00", currentValue), MIDSIZE + CENTER + CUSTOM_COLOR)
  
  -- Bouton -
  local minusButtonY = centerY + 45
  lcd.drawFilledRectangle(popupX + 25, minusButtonY - 2, cfg.w - 50, 20, safeRGB(120, 60, 60))
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 100, 100))
  lcd.drawRectangle(popupX + 25, minusButtonY - 2, cfg.w - 50, 20, CUSTOM_COLOR, 2)
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 255, 255))
  lcd.drawText(popupX + cfg.w / 2, minusButtonY - 9, "-", MIDSIZE + CENTER + CUSTOM_COLOR)
  
  lcd.setColor(CUSTOM_COLOR, safeRGB(200, 200, 200))
  lcd.drawText(popupX + cfg.w / 2, popupY + cfg.h - 25, "TAP | Enter", SMLSIZE + CENTER + CUSTOM_COLOR)
end

-- Helper pour détecter le touch dans une zone
local function isTouchInZone(tx, ty, x1, y1, x2, y2)
  return tx >= x1 and tx <= x2 and ty >= y1 and ty <= y2
end

-- Gestion du popup tactile capacité
function M.handleCapacityPopupTouch(widget, touchState)
  if not widget.capacityEditValue then
    widget.capacityEditValue = model.getGlobalVariable(1, 0) or 50
  end
  
  if not touchState or not touchState.x or not touchState.y or touchState.event ~= TOUCH_TAP then
    return true
  end
  
  if isDebounced(widget, 'lastCapacityTapTime', getTime()) then
    return true
  end
  
  local z = widget.z
  local baseY = widget.baseY
  local cfg = POPUP_CONFIGS.capacity
  local popupX = z.x + cfg.offsetX
  local popupY = baseY + cfg.offsetY
  local tx, ty = touchState.x, touchState.y
  local centerY = popupY + 70
  local buttonZoneX1 = popupX + 25
  local buttonZoneX2 = popupX + cfg.w - 25
  
  -- Bouton +
  if isTouchInZone(tx, ty, buttonZoneX1, centerY - 48, buttonZoneX2, centerY - 26) then
    widget.capacityEditValue = math.min(200, widget.capacityEditValue + 1)
    return true
  end
  
  -- Bouton -
  if isTouchInZone(tx, ty, buttonZoneX1, centerY + 43, buttonZoneX2, centerY + 65) then
    widget.capacityEditValue = math.max(10, widget.capacityEditValue - 1)
    return true
  end
  
  -- Zone centrale → VALIDER ET FERMER
  if isTouchInZone(tx, ty, buttonZoneX1, centerY - 8, buttonZoneX2, centerY + 28) then
    if widget.capacityEditValue then
      model.setGlobalVariable(1, 0, widget.capacityEditValue)
      widget.batteryCapacity = widget.capacityEditValue * 100
    end
    widget.editingCapacity = false
    widget.selectedButton = 3
    widget.lastCapacityTapTime = nil
    return true
  end
  
  return true
end

-- Gestion popup tactile MODE
function M.handlePopupTouch(widget, touchState)
  if not touchState or not touchState.x or not touchState.y or touchState.event ~= TOUCH_TAP then
    return true
  end
  
  if isDebounced(widget, 'lastModeTapTime', getTime()) then
    return true
  end
  
  local z = widget.z
  local baseY = widget.baseY
  local cfg = POPUP_CONFIGS.displayMode
  local popupX = z.x + cfg.offsetX
  local popupY = baseY + cfg.offsetY
  local tx, ty = touchState.x, touchState.y
  local optionY = popupY + 30
  
  local function selectMode(mode)
    widget.displayModeEditValue = mode
    model.setGlobalVariable(7, 0, mode)
    widget.editingDisplayMode = false
    widget.selectedButton = 3
    widget.lastModeTapTime = nil
  end
  
  -- Zone LEDS
  if isTouchInZone(tx, ty, popupX + 15, optionY - 3, popupX + cfg.w - 15, optionY + 23) then
    selectMode(0)
    return true
  end
  
  -- Zone ARCS
  if isTouchInZone(tx, ty, popupX + 15, optionY + 29, popupX + cfg.w - 15, optionY + 55) then
    selectMode(1)
    return true
  end
  
  return true
end

-- Fonction pour dessiner le popup de sortie plein écran
function M.drawExitFullscreenPopup(widget)
  local z = widget.z
  local baseY = widget.baseY
  local cfg = POPUP_CONFIGS.exitFullscreen
  local popupX = z.x + cfg.offsetX
  local popupY = baseY + cfg.offsetY
  
  lcd.drawFilledRectangle(z.x, z.y, z.w, z.h, safeRGB(0, 0, 0, 100))
  lcd.drawFilledRectangle(popupX, popupY, cfg.w, cfg.h, safeRGB(40, 40, 40))
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 100, 100))
  lcd.drawRectangle(popupX, popupY, cfg.w, cfg.h, CUSTOM_COLOR, 3)
  
  lcd.setColor(CUSTOM_COLOR, safeRGB(255, 255, 255))
  lcd.drawText(popupX + cfg.w / 2, popupY + 8, "Sortie Plein Ecran", SMLSIZE + CENTER + CUSTOM_COLOR)
  
  local option1Y = popupY + 35
  local option2Y = popupY + 60
  
  drawPopupOption(popupX, popupY, cfg.w, option1Y, "OUI - Sortir", 
    widget.exitFullscreenChoice == 0, safeRGB(80, 0, 0), safeRGB(255, 100, 100))
  drawPopupOption(popupX, popupY, cfg.w, option2Y, "NON - Annuler", 
    widget.exitFullscreenChoice == 1, safeRGB(0, 80, 0), safeRGB(100, 255, 100))
end

-- Gestion tactile popup sortie plein écran
function M.handleExitFullscreenTouch(widget, touchState)
  if not touchState or not touchState.x or not touchState.y or touchState.event ~= TOUCH_TAP then
    return true
  end
  
  if isDebounced(widget, 'lastExitTapTime', getTime()) then
    return true
  end
  
  local z = widget.z
  local baseY = widget.baseY
  local cfg = POPUP_CONFIGS.exitFullscreen
  local popupX = z.x + cfg.offsetX
  local popupY = baseY + cfg.offsetY
  local tx, ty = touchState.x, touchState.y
  local option1Y = popupY + 35
  local option2Y = popupY + 60
  
  local function closePopup()
    widget.showingExitPopup = false
    widget.selectedButton = 3
    widget.lastExitTapTime = nil
  end
  
  -- Zone OUI
  if isTouchInZone(tx, ty, popupX + 15, option1Y - 3, popupX + cfg.w - 15, option1Y + 19) then
    lcd.exitFullScreen()
    closePopup()
    return true
  end
  
  -- Zone NON
  if isTouchInZone(tx, ty, popupX + 15, option2Y - 3, popupX + cfg.w - 15, option2Y + 19) then
    closePopup()
    return true
  end
  
  return true
end

-- Helper pour gérer les événements de navigation
local function handleNavigationEvent(widget, event)
  if event == EVT_VIRTUAL_NEXT or event == EVT_PLUS_FIRST then
    return 1
  elseif event == EVT_VIRTUAL_PREV or event == EVT_MINUS_FIRST then
    return -1
  end
  return 0
end

-- Helper pour gérer les événements de validation/annulation
local function isExitEvent(event)
  return event == EVT_VIRTUAL_EXIT or event == EVT_RTN_FIRST or 
         event == EVT_RTN_BREAK or event == EVT_RTN_LONG or event == EVT_EXIT_BREAK
end

local function isEnterEvent(event)
  return event == EVT_VIRTUAL_ENTER or event == EVT_ENTER_BREAK or event == EVT_ENTER_LONG
end

-- Gestion des boutons + édition GV1 / GV7
function M.handleButtonsAndHeader(widget)
  local z = widget.z
  local baseY = widget.baseY
  local event = widget.event
  local touchState = widget.touchState

  -- Popup sortie plein écran
  if widget.showingExitPopup then
    M.drawExitFullscreenPopup(widget)
    if touchState then
      M.handleExitFullscreenTouch(widget, touchState)
    end
    
    if isExitEvent(event) then
      widget.showingExitPopup = false
      widget.selectedButton = 3
    elseif isEnterEvent(event) then
      if widget.exitFullscreenChoice == 0 then
        lcd.exitFullScreen()
      end
      widget.showingExitPopup = false
      widget.selectedButton = 3
    else
      local nav = handleNavigationEvent(widget, event)
      if nav ~= 0 then
        widget.exitFullscreenChoice = (widget.exitFullscreenChoice + nav + 2) % 2
      end
    end
    return
  end

  -- Popup MODE
  if widget.editingDisplayMode then
    M.drawDisplayModePopup(widget)
    if touchState then
      M.handlePopupTouch(widget, touchState)
    end
    
    if isExitEvent(event) then
      widget.editingDisplayMode = false
      widget.selectedButton = 3
    elseif isEnterEvent(event) then
      model.setGlobalVariable(7, 0, widget.displayModeEditValue)
      widget.editingDisplayMode = false
      widget.selectedButton = 3
    else
      local nav = handleNavigationEvent(widget, event)
      if nav ~= 0 then
        widget.displayModeEditValue = (widget.displayModeEditValue + nav + 2) % 2
      end
    end
    return
  end

  -- Indicateur tracking
  local indicatorX = z.x + z.w - 305
  local indicatorY = baseY + 180
  local indicatorRadius = 10
  local trackingColor = widget.trackingEnabled and safeRGB(0, 255, 0) or widget.colorRed
  lcd.drawFilledCircle(indicatorX, indicatorY, indicatorRadius, trackingColor)

  -- Colonne gauche
  local x0 = z.x + 12
  local y0 = baseY - 15
  local dy = 26
  local textFlags = SMLSIZE + BOLD
  local y = y0

  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x0, y, string.format("%.1fV (%.2fV/c)", widget.vbat, widget.vpercell), textFlags + CUSTOM_COLOR)

  -- Bouton mode d'affichage
  local displayButtonX = x0 + 195
  local displayButtonY = y - 2
  local displayButtonSize = 24
  local currentMode = model.getGlobalVariable(7, 0) or 0
  local xButtonX = displayButtonX + displayButtonSize + 8
  local xButtonY = displayButtonY
  local xButtonSize = 24

  -- Sélection boutons (événements clavier)
  if not widget.editingCapacity and not widget.editingDisplayMode and not widget.showingExitPopup and event ~= nil then
    local nav = handleNavigationEvent(widget, event)
    if nav ~= 0 then
      widget.selectedButton = ((widget.selectedButton - 1 + nav + 3) % 3) + 1
    end
  end

  -- Tactile sélection boutons
  if touchState and touchState.x and touchState.y and not widget.editingCapacity and 
     not widget.editingDisplayMode and not widget.showingExitPopup then
    local tx, ty = touchState.x, touchState.y
    local capButtonX = z.x + 110
    local capButtonY = baseY + 95
    local capButtonW = 165
    local capButtonH = 30

    -- Bouton capacité
    if isTouchInZone(tx, ty, capButtonX - 4, capButtonY - 4, capButtonX + capButtonW + 4, capButtonY + capButtonH + 4) then
      widget.selectedButton = 1
      if touchState.event == TOUCH_TAP then
        widget.editingCapacity = true
        widget.capacityEditValue = model.getGlobalVariable(1, 0) or 50
      end
    -- Bouton mode d'affichage
    elseif isTouchInZone(tx, ty, displayButtonX - 4, displayButtonY - 4, displayButtonX + displayButtonSize + 4, displayButtonY + displayButtonSize + 4) then
      widget.selectedButton = 2
      if touchState.event == TOUCH_TAP then
        widget.editingDisplayMode = true
        widget.displayModeEditValue = model.getGlobalVariable(7, 0) or 0
      end
    -- Bouton X
    elseif isTouchInZone(tx, ty, xButtonX - 4, xButtonY - 4, xButtonX + xButtonSize + 4, xButtonY + xButtonSize + 4) then
      widget.selectedButton = 3
      if touchState.event == TOUCH_TAP then
        widget.showingExitPopup = true
        widget.exitFullscreenChoice = 1
      end
    end
  end

  -- Helper pour dessiner un bouton
  local function drawButton(x, y, size, isSelected)
    local bgColor = isSelected and safeRGB(80, 80, 0) or safeRGB(40, 40, 40)
    local padding = isSelected and 3 or 2
    
    lcd.setColor(CUSTOM_COLOR, bgColor)
    lcd.drawFilledRectangle(x - padding, y - padding, size + padding * 2, size + padding * 2, CUSTOM_COLOR)
    
    if isSelected then
      lcd.setColor(CUSTOM_COLOR, safeRGB(255, 255, 0))
      lcd.drawRectangle(x - 3, y - 3, size + 6, size + 6, CUSTOM_COLOR, 2)
    end
  end

  -- Dessin bouton MODE
  drawButton(displayButtonX, displayButtonY, displayButtonSize, widget.selectedButton == 2)
  
  local iconColor = (currentMode == 0) and safeRGB(0, 150, 200) or safeRGB(255, 128, 0)
  M.drawScreenIcon(displayButtonX, displayButtonY, displayButtonSize, iconColor)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_SECONDARY)
  local modeText = (currentMode == 0) and "LEDS" or "ARCS"
  lcd.drawText(displayButtonX + displayButtonSize / 2, displayButtonY + displayButtonSize + 1, modeText, SMLSIZE + CENTER + CUSTOM_COLOR)

  -- Bouton X
  drawButton(xButtonX, xButtonY, xButtonSize, widget.selectedButton == 3)
  
  lcd.setColor(CUSTOM_COLOR, safeRGB(150, 150, 150))
  local xOffset = 6
  lcd.drawLine(xButtonX + xOffset, xButtonY + xOffset, xButtonX + xButtonSize - xOffset, xButtonY + xButtonSize - xOffset, SOLID, 2, CUSTOM_COLOR)
  lcd.drawLine(xButtonX + xButtonSize - xOffset, xButtonY + xOffset, xButtonX + xOffset, xButtonY + xButtonSize - xOffset, SOLID, 2, CUSTOM_COLOR)

  -- Infos colonne gauche
  y = y + dy
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x0, y, string.format("%.1fV BEC", widget.vbec), textFlags + CUSTOM_COLOR)
  y = y + dy
  lcd.drawText(x0, y, string.format("%.0f FBL %% ProcMax", widget.maxChp), textFlags + CUSTOM_COLOR)
  y = y + dy
  lcd.drawText(x0, y, string.format("%drpm", math.floor(widget.rpm + 0.5)), textFlags + CUSTOM_COLOR)
  y = y + dy
  lcd.drawText(x0, y, formatTime(widget.tval), textFlags + BOLD + CUSTOM_COLOR)

  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x0, baseY + 132, string.format("%.0fmAh", widget.cons), MIDSIZE + BOLD + CUSTOM_COLOR)
  lcd.drawText(x0, baseY + 172, string.format("%.1fA", widget.curr), MIDSIZE + CUSTOM_COLOR)

  -- Bouton capacité
  M.drawCapacityButton(widget, event, widget.colorBg, touchState)

  -- Vols
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(z.x + z.w - 200, baseY + 132, string.format("Vols: %d", widget.flightCount), MIDSIZE + BOLD + RIGHT + CUSTOM_COLOR)
end

-- drawCapacityButton
function M.drawCapacityButton(widget, event, colorBg, touchState)
  local z = widget.z
  local baseY = widget.baseY
  local capacityValue = widget.batteryCapacity or 0
  local currentTime = getTime() / 100

  if widget.startupTime == nil then
    widget.startupTime = currentTime
  end
  local elapsedTime = currentTime - widget.startupTime

  local capButtonX = z.x + 110
  local capButtonY = baseY + 95
  local capButtonW = 165
  local capButtonH = 30

  if widget.editingCapacity then
    M.drawCapacityPopup(widget)
    
    if touchState then
      M.handleCapacityPopupTouch(widget, touchState)
    end
    
    if isExitEvent(event) then
      widget.editingCapacity = false
      widget.selectedButton = 3
    elseif isEnterEvent(event) then
      model.setGlobalVariable(1, 0, widget.capacityEditValue)
      widget.batteryCapacity = widget.capacityEditValue * 100
      widget.editingCapacity = false
      widget.selectedButton = 3
    elseif event == EVT_VIRTUAL_INC or event == EVT_ROT_RIGHT or event == EVT_PLUS_FIRST then
      widget.capacityEditValue = math.min(200, (widget.capacityEditValue or 50) + 1)
    elseif event == EVT_VIRTUAL_DEC or event == EVT_ROT_LEFT or event == EVT_MINUS_FIRST then
      widget.capacityEditValue = math.max(10, (widget.capacityEditValue or 50) - 1)
    end
    return
  else
    -- Affichage bouton capacité
    if elapsedTime < STARTUP_BLINK_DURATION then
      local blinkCycle = math.floor((currentTime * 1) % 2)
      local bgColor, textColor, text
      
      if blinkCycle == 0 then
        bgColor = safeRGB(40, 40, 40)
        textColor = safeRGB(255, 255, 0)
        text = string.format("LiPo: %dmAh", capacityValue)
      else
        bgColor = safeRGB(80, 40, 0)
        textColor = safeRGB(255, 128, 0)
        text = "Régler CAPA"
      end
      
      lcd.setColor(CUSTOM_COLOR, bgColor)
      lcd.drawFilledRectangle(capButtonX - 3, capButtonY - 1, capButtonW + 6, capButtonH + 2, CUSTOM_COLOR)
      lcd.setColor(CUSTOM_COLOR, textColor)
      lcd.drawText(capButtonX, capButtonY + 2, text, MIDSIZE + CUSTOM_COLOR)
      
      if widget.selectedButton == 1 then
        lcd.setColor(CUSTOM_COLOR, safeRGB(255, 255, 0))
        lcd.drawRectangle(capButtonX - 4, capButtonY - 2, capButtonW + 8, capButtonH + 4, CUSTOM_COLOR, 2)
      end
    else
      local bgColor, textColor
      
      if widget.selectedButton == 1 then
        bgColor = safeRGB(60, 60, 0)
        textColor = safeRGB(255, 255, 0)
        lcd.setColor(CUSTOM_COLOR, bgColor)
        lcd.drawFilledRectangle(capButtonX - 3, capButtonY - 1, capButtonW + 6, capButtonH + 2, CUSTOM_COLOR)
        lcd.setColor(CUSTOM_COLOR, textColor)
        lcd.drawRectangle(capButtonX - 4, capButtonY - 2, capButtonW + 8, capButtonH + 4, CUSTOM_COLOR, 2)
      else
        bgColor = safeRGB(30, 30, 30)
        textColor = widget.hardcoded.TEXT_COLOR
        lcd.setColor(CUSTOM_COLOR, bgColor)
        lcd.drawFilledRectangle(capButtonX - 3, capButtonY - 1, capButtonW + 6, capButtonH + 2, CUSTOM_COLOR)
      end
      
      lcd.setColor(CUSTOM_COLOR, textColor)
      lcd.drawText(capButtonX, capButtonY + 2, string.format("LiPo: %dmAh", capacityValue), MIDSIZE + CUSTOM_COLOR)
    end

    -- Ouverture popup UNIQUEMENT via clavier
    if not widget.editingDisplayMode and not widget.showingExitPopup and isEnterEvent(event) then
      if widget.selectedButton == 1 and not widget.editingCapacity then
        widget.editingCapacity = true
        widget.capacityEditValue = model.getGlobalVariable(1, 0) or 50
      elseif widget.selectedButton == 2 and not widget.editingCapacity then
        widget.editingDisplayMode = true
        widget.displayModeEditValue = model.getGlobalVariable(7, 0) or 0
      elseif widget.selectedButton == 3 then
        widget.showingExitPopup = true
        widget.exitFullscreenChoice = 1
      end
    end
  end
end

function M.drawCapacityBarAndStats(widget)
  local z = widget.z
  local baseY = widget.baseY
  local fuel = widget.fuel
  local tval = widget.tval
  local cons = widget.cons

  -- Vérification taille écran
  if z.h <= 250 then return end

  -- Calculs barre de capacité
  local vFuel = clamp(fuel / 100, 0, 1)
  local barY = baseY + 200
  local barHeight = 25
  local barMargin = 12
  local barWidth = z.w - (2 * barMargin)
  local fillWidth = math.floor(barWidth * vFuel)

  -- Dessin barre de fond
  lcd.drawFilledRectangle(z.x + barMargin, barY, barWidth, barHeight, safeRGB(60, 60, 60))
  
  -- Remplissage coloré
  local Rf, Gf, Bf = helpers.getFuelColor(fuel, widget.colorBlue, widget.colorOrange, widget.colorRed)
  lcd.drawFilledRectangle(z.x + barMargin, barY, fillWidth, barHeight, safeRGB(Rf, Gf, Bf))

  -- Bordure et texte
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawRectangle(z.x + barMargin, barY, barWidth, barHeight, CUSTOM_COLOR, 2)
  lcd.drawText(z.x + z.w / 2, barY - 2, string.format("Capacité: %d%%", math.floor(fuel + 0.5)), MIDSIZE + CENTER + CUSTOM_COLOR)

  -- Calcul temps restant
  local timeRemain = 0
  if tval > 30 and cons > 0 and fuel > 0 and fuel < 99.9 then
    local usedPercent = 100 - fuel
    if usedPercent > 0.1 then
      local consRate = (tval > 0) and (cons / (tval / 60)) or 0
      local capacityRemain = widget.batteryCapacity * (fuel / 100)
      if consRate > 0 then
        timeRemain = (capacityRemain / consRate) * 60
        -- Protection contre NaN
        if timeRemain ~= timeRemain then timeRemain = 0 end
        timeRemain = math.min(9999, timeRemain)
      end
    end
  end

  -- Statistiques
  local statsY = barY + barHeight + 5
  local avgConsRate = (tval > 30 and tval > 0) and (cons / (tval / 60)) or 0
  
  local stats = {
    {text = string.format("I moy: %.1fA", widget.avgCurr), x = z.x + 12},
    {text = string.format("I max: %.1fA", widget.maxCurr), x = z.x + 120},
    {text = string.format("Moy: %.0fmAh/min", avgConsRate), x = z.x + 230},
    {text = string.format("Temps rest: %s", formatTime(timeRemain)), x = z.x + z.w - 12, flags = SMLSIZE + RIGHT + CUSTOM_COLOR}
  }

  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  for i = 1, 3 do
    lcd.drawText(stats[i].x, statsY, stats[i].text, SMLSIZE + CUSTOM_COLOR)
  end
  lcd.drawText(stats[4].x, statsY, stats[4].text, stats[4].flags)
end

return M