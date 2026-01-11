-- /WIDGETS/All_IN/segments.lua
-- Fonctions pour mode segments

-- Dupliquer les helpers nécessaires ici
local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

local function safeRGB(r, g, b)
  r = math.max(0, math.min(255, math.floor(r or 0)))
  g = math.max(0, math.min(255, math.floor(g or 0)))
  b = math.max(0, math.min(255, math.floor(b or 0)))
  return lcd.RGB(r, g, b)
end

local function getRGB(color)
  local c = lcd.getColor(color) or color
  local rgb565 = c >> 16
  local r5 = rgb565 >> 11
  local g6 = (rgb565 >> 5) & 0x3F
  local b5 = rgb565 & 0x1F
  local r = math.floor(r5 * 255 / 31 + 0.5)
  local g = math.floor(g6 * 255 / 63 + 0.5)
  local b = math.floor(b5 * 255 / 31 + 0.5)
  return r, g, b
end

local function getFuelColor(value, blueColor, orangeColor, redColor)
  if value > 50 then return getRGB(blueColor) end
  if value > 20 then return getRGB(orangeColor) end
  return getRGB(redColor)
end

local function getTfblColor(value, blueColor, orangeColor, redColor)
  if value <= 40 then return getRGB(blueColor) end
  if value < 50 then return getRGB(orangeColor) end
  return getRGB(redColor)
end

local function getTescColor(value, blueColor, orangeColor, redColor)
  if value <= 40 then return getRGB(blueColor) end
  if value < 60 then return getRGB(orangeColor) end
  return getRGB(redColor)
end

local function getRssiColor(value, blueColor, orangeColor, redColor)
  if value > 60 then return getRGB(blueColor) end
  if value > 40 then return getRGB(orangeColor) end
  return getRGB(redColor)
end

local function getVfrColor(value, blueColor, orangeColor, redColor)
  if value > 60 then return getRGB(blueColor) end
  if value > 40 then return getRGB(orangeColor) end
  return getRGB(redColor)
end

local function formatTime(sec)
  sec = math.floor(math.abs(sec))
  local m = math.floor(sec / 60)
  local s = sec % 60
  return string.format("%02d:%02d", m, s)
end

local function drawSegmentGauge(widget, x, y, width, height, value, label, numSegments, R, G, B, bgColor, segmentBgColor, showMinMax, minValue, maxValue, isMaxType, colorBlue, colorOrange, colorRed, gaugeType)
  numSegments = numSegments or 10
  local segmentWidth = math.floor((width - (numSegments - 1) * 3) / numSegments)
  local activeSegments = math.floor(value * numSegments)
  
  -- Label au-dessus
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x + width / 2, y - 18, label, SMLSIZE + CENTER + CUSTOM_COLOR)
  
  -- Dessiner les segments
  for i = 0, numSegments - 1 do
    local segX = x + i * (segmentWidth + 3)
    
    if i < activeSegments then
      lcd.drawFilledRectangle(segX, y, segmentWidth, height, safeRGB(R, G, B))
    else
      lcd.drawFilledRectangle(segX, y, segmentWidth, height, segmentBgColor)
    end
  end
  
  if showMinMax then
    local extremeValue = isMaxType and maxValue or minValue
    local extremeSegments = math.floor(extremeValue * numSegments)
    
    local extremeActualValue
    if gaugeType == "fuel" then extremeActualValue = minValue * 100
    elseif gaugeType == "vfr" then extremeActualValue = minValue * 100
    elseif gaugeType == "rssi" then extremeActualValue = minValue * 100
    elseif gaugeType == "tfbl" then extremeActualValue = maxValue * 120
    elseif gaugeType == "tesc" then extremeActualValue = maxValue * 120 end
    
    local extremeR, extremeG, extremeB
    if gaugeType == "fuel" then extremeR, extremeG, extremeB = getFuelColor(extremeActualValue, colorBlue, colorOrange, colorRed)
    elseif gaugeType == "vfr" then extremeR, extremeG, extremeB = getVfrColor(extremeActualValue, colorBlue, colorOrange, colorRed)
    elseif gaugeType == "rssi" then extremeR, extremeG, extremeB = getRssiColor(extremeActualValue, colorBlue, colorOrange, colorRed)
    elseif gaugeType == "tfbl" then extremeR, extremeG, extremeB = getTfblColor(extremeActualValue, colorBlue, colorOrange, colorRed)
    elseif gaugeType == "tesc" then extremeR, extremeG, extremeB = getTescColor(extremeActualValue, colorBlue, colorOrange, colorRed) end
    
    for i = 0, numSegments - 1 do
      local segX = x + i * (segmentWidth + 3)
      if i < extremeSegments then
        lcd.drawFilledRectangle(segX, y, segmentWidth, height, safeRGB(extremeR, extremeG, extremeB))
      end
    end
  end
end

local function refresh(widget)
  local z = widget.z
  local colorBg = widget.colorBg
  local colorArcBg = widget.colorArcBg
  local colorBlue = widget.colorBlue
  local colorOrange = widget.colorOrange
  local colorRed = widget.colorRed
  local baseY = widget.baseY
  local vbat = widget.vbat
  local vbec = widget.vbec
  local curr = widget.curr
  local fuel = widget.fuel
  local rpm = widget.rpm
  local rssi = widget.rssi
  local tfbl = widget.tfbl
  local tesc = widget.tesc
  local cons = widget.cons
  local tval = widget.tval
  local vfr = widget.vfr
  local chp = widget.chp
  local vpercell = widget.vpercell
  local vVFR = widget.vVFR
  local avgCurr = widget.avgCurr

  -- Indicateur tracking
  local indicatorX = z.x + z.w - 305
  local indicatorY = baseY + 180
  local indicatorRadius = 10
  if widget.trackingEnabled then
    lcd.drawFilledCircle(indicatorX, indicatorY, indicatorRadius, safeRGB(0, 255, 0))
  else
    lcd.drawFilledCircle(indicatorX, indicatorY, indicatorRadius, colorRed)
  end

  -- Colonne gauche
  local x0 = z.x + 12
  local y0 = baseY - 15
  local dy = 26
  local textFlags = SMLSIZE + BOLD
  local y = y0
  
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x0, y, string.format("%.1fV (%.2fV/c)", vbat, vpercell), textFlags + CUSTOM_COLOR)
  y = y + dy
  
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x0, y, string.format("%.1fV BEC", vbec), textFlags + CUSTOM_COLOR)
  y = y + dy
  
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x0, y, string.format("%.0f FBL %% ProcMax", widget.maxChp), textFlags + CUSTOM_COLOR)
  y = y + dy
  
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x0, y, string.format("%drpm", math.floor(rpm+0.5)), textFlags + CUSTOM_COLOR)
  y = y + dy
  
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x0, y, formatTime(tval), textFlags + BOLD + CUSTOM_COLOR)
  
  -- mAh et A
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x0, baseY + 132, string.format("%.0fmAh", cons), MIDSIZE + BOLD + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x0, baseY + 172, string.format("%.1fA", curr), MIDSIZE + CUSTOM_COLOR)
  
  -- Vols
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(z.x + z.w - 200, baseY + 132, string.format("Vols: %d", widget.flightCount), MIDSIZE + BOLD + RIGHT + CUSTOM_COLOR)
  
  -- Positions et tailles des jauges segments
  local gaugeWidth = 150
  local gaugeHeight = 20
  local gaugeSpacing = 38
  
  local gx = z.x + z.w - gaugeWidth - 25
  local gy1 = baseY + 10  -- VFR
  local gy2 = gy1 + gaugeSpacing  -- RSSI
  local gy3 = gy2 + gaugeSpacing  -- TESC
  local gy4 = gy3 + gaugeSpacing  -- TFBL
  local gy5 = gy4 + gaugeSpacing  -- CAPACITÉ
  
  -- Valeurs normalisées
  local vFuel = clamp(fuel / 100, 0, 1)
  local vTFBL = clamp(tfbl / 120, 0, 1)
  local vRSSI = clamp(rssi / 100, 0, 1)
  local vTESC = clamp(tesc / 120, 0, 1)
  local vMinFuel = clamp(widget.minFuel / 100, 0, 1)
  local vMaxTFBL = clamp(widget.maxTfbl / 120, 0, 1)
  local vMinRSSI = clamp(widget.minRssi / 100, 0, 1)
  local vMaxTESC = clamp(widget.maxTesc / 120, 0, 1)
  local vMinVFR = clamp(widget.minVfr / 100, 0, 1)
  
  -- Show min/max si liaison coupée
  local showMinMax = (rssi == 0)
  
  -- Couleurs jauges
  local Rf, Gf, Bf = getFuelColor(fuel, colorBlue, colorOrange, colorRed)
  local RtFBL, GtFBL, BtFBL = getTfblColor(tfbl, colorBlue, colorOrange, colorRed)
  local Rr, Gr, Br = getRssiColor(rssi, colorBlue, colorOrange, colorRed)
  local RtESC, GtESC, BtESC = getTescColor(tesc, colorBlue, colorOrange, colorRed)
  local Rv, Gv, Bv = getVfrColor(vfr, colorBlue, colorOrange, colorRed)
  
  local RminVFR, GminVFR, BminVFR = getVfrColor(widget.minVfr, colorBlue, colorOrange, colorRed)
  local RminRSSI, GminRSSI, BminRSSI = getRssiColor(widget.minRssi, colorBlue, colorOrange, colorRed)
  local RmaxTESC, GmaxTESC, BmaxTESC = getTescColor(widget.maxTesc, colorBlue, colorOrange, colorRed)
  local RmaxTFBL, GmaxTFBL, BmaxTFBL = getTfblColor(widget.maxTfbl, colorBlue, colorOrange, colorRed)
  local RminFuel, GminFuel, BminFuel = getFuelColor(widget.minFuel, colorBlue, colorOrange, colorRed)
  
  -- Dessiner jauges segments
  drawSegmentGauge(widget, gx, gy1, gaugeWidth, gaugeHeight, vVFR, "VFR", 10, Rv, Gv, Bv, colorBg, colorArcBg, showMinMax, vMinVFR, 0, false, colorBlue, colorOrange, colorRed, "vfr")
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(gx - 2, gy1 + 3, string.format("%d%%", math.floor(vfr + 0.5)), SMLSIZE + RIGHT + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, safeRGB(RminVFR, GminVFR, BminVFR))
  lcd.drawText(gx + gaugeWidth + 2, gy1 + 3, string.format("%d", math.floor(widget.minVfr + 0.5)), SMLSIZE + CUSTOM_COLOR)
  
  drawSegmentGauge(widget, gx, gy2, gaugeWidth, gaugeHeight, vRSSI, "RSSI", 10, Rr, Gr, Br, colorBg, colorArcBg, showMinMax, vMinRSSI, 0, false, colorBlue, colorOrange, colorRed, "rssi")
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(gx - 2, gy2 + 3, string.format("%d%%", math.floor(rssi + 0.5)), SMLSIZE + RIGHT + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, safeRGB(RminRSSI, GminRSSI, BminRSSI))
  lcd.drawText(gx + gaugeWidth + 2, gy2 + 3, string.format("%d", math.floor(widget.minRssi + 0.5)), SMLSIZE + CUSTOM_COLOR)
  
  drawSegmentGauge(widget, gx, gy3, gaugeWidth, gaugeHeight, vTESC, "ESC", 10, RtESC, GtESC, BtESC, colorBg, colorArcBg, showMinMax, 0, vMaxTESC, true, colorBlue, colorOrange, colorRed, "tesc")
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(gx - 2, gy3 + 3, string.format("%d°", math.floor(tesc + 0.5)), SMLSIZE + RIGHT + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, safeRGB(RmaxTESC, GmaxTESC, BmaxTESC))
  lcd.drawText(gx + gaugeWidth + 2, gy3 + 3, string.format("%d", math.floor(widget.maxTesc + 0.5)), SMLSIZE + CUSTOM_COLOR)
  
  drawSegmentGauge(widget, gx, gy4, gaugeWidth, gaugeHeight, vTFBL, "FBL", 10, RtFBL, GtFBL, BtFBL, colorBg, colorArcBg, showMinMax, 0, vMaxTFBL, true, colorBlue, colorOrange, colorRed, "tfbl")
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(gx - 2, gy4 + 3, string.format("%d°", math.floor(tfbl + 0.5)), SMLSIZE + RIGHT + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, safeRGB(RmaxTFBL, GmaxTFBL, BmaxTFBL))
  lcd.drawText(gx + gaugeWidth + 2, gy4 + 3, string.format("%d", math.floor(widget.maxTfbl + 0.5)), SMLSIZE + CUSTOM_COLOR)
  
  drawSegmentGauge(widget, gx, gy5, gaugeWidth, gaugeHeight, vFuel, "Capacité", 10, Rf, Gf, Bf, colorBg, colorArcBg, showMinMax, vMinFuel, 0, false, colorBlue, colorOrange, colorRed, "fuel")
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(gx - 2, gy5 + 3, string.format("%d%%", math.floor(fuel + 0.5)), SMLSIZE + RIGHT + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, safeRGB(RminFuel, GminFuel, BminFuel))
  lcd.drawText(gx + gaugeWidth + 2, gy5 + 3, string.format("%d", math.floor(widget.minFuel + 0.5)), SMLSIZE + CUSTOM_COLOR)
  
  -- Barre capacité + stats
  if z.h > 250 then
    local barY = baseY + 200
    local barHeight = 25
    local barMargin = 12
    local barWidth = z.w - (2 * barMargin)
    
    lcd.drawFilledRectangle(z.x + barMargin, barY, barWidth, barHeight, safeRGB(60, 60, 60))
    local fillWidth = math.floor(barWidth * vFuel)
    local Rf, Gf, Bf = getFuelColor(fuel, colorBlue, colorOrange, colorRed)
    lcd.drawFilledRectangle(z.x + barMargin, barY, fillWidth, barHeight, safeRGB(Rf, Gf, Bf))
    
    lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
    lcd.drawRectangle(z.x + barMargin, barY, barWidth, barHeight, CUSTOM_COLOR, 2)
    lcd.drawText(z.x + z.w / 2, barY - 2, string.format("Capacité: %d%%", math.floor(fuel + 0.5)), MIDSIZE + CENTER + CUSTOM_COLOR)
    
    local statsY = barY + barHeight + 5
    local timeFlown = tval
    local timeRemain = 0
    if timeFlown > 30 and cons > 0 and fuel > 0 and fuel < 99.9 then
      local usedPercent = 100 - fuel
      if usedPercent > 0.1 then
        local consRate = cons / (timeFlown / 60)
        local capacityTotal = cons / (usedPercent / 100)
        local capacityRemain = capacityTotal * (fuel / 100)
        if consRate > 0 then timeRemain = (capacityRemain / consRate) * 60 end
      end
    end
    
    local stat1 = string.format("I moy: %.1fA", avgCurr)
    local stat2 = string.format("I max: %.1fA", widget.maxCurr)
    local stat3 = string.format("Moy: %.0fmAh/min", (timeFlown > 30) and (cons / (timeFlown / 60)) or 0)
    local stat4 = string.format("Temps rest: %s", formatTime(timeRemain))
    
    lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
    lcd.drawText(z.x + 12, statsY, stat1, SMLSIZE + CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
    lcd.drawText(z.x + 120, statsY, stat2, SMLSIZE + CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
    lcd.drawText(z.x + 230, statsY, stat3, SMLSIZE + CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
    lcd.drawText(z.x + z.w - 12, statsY, stat4, SMLSIZE + RIGHT + CUSTOM_COLOR)
  end
end

return { refresh = refresh }