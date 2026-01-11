-- /WIDGETS/All_IN/arcs.lua
-- Fonctions pour mode arcs

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

local function drawGauge(widget, cx, cy, r, value, R, G, B, label, thickness, extremeValue, isMax, bgColor, arcBgColor, redColor)
  local startAngle = -225
  local sweep = 270
  local v = clamp(value, 0, 1) * sweep
  thickness = thickness or 10
  local r_outer = r + math.floor(thickness / 2)
  local r_inner = r - math.ceil(thickness / 2)
  
  local hasInnerArc = extremeValue ~= nil
  local r_extreme_outer, r_extreme_inner
  if hasInnerArc then
    local innerThickness = thickness
    local gap = -2
    r_extreme_outer = r_inner - gap
    r_extreme_inner = r_extreme_outer - innerThickness
  end
  
  local gray = arcBgColor or safeRGB(80, 80, 80)
  local red = redColor or safeRGB(139, 0, 0)
  local arcColor = safeRGB(R, G, B)
  
  lcd.drawPie(cx, cy, r_outer, startAngle, startAngle + sweep, gray)
  lcd.drawPie(cx, cy, r_outer, startAngle, startAngle + v, arcColor)
  lcd.drawFilledCircle(cx, cy, r_inner, bgColor)
  
  if hasInnerArc then
    local extremeV = clamp(extremeValue, 0, 1) * sweep
    lcd.drawPie(cx, cy, r_extreme_outer, startAngle, startAngle + sweep, gray)
    lcd.drawPie(cx, cy, r_extreme_outer, startAngle, startAngle + extremeV, red)
    lcd.drawFilledCircle(cx, cy, r_extreme_inner, bgColor)
  end
  
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(cx, cy - 20, label, SMLSIZE + CENTER + CUSTOM_COLOR)
end

local function refresh(widget)
  local z = widget.z
  local colorBg = widget.colorBg
  local colorArcBg = widget.colorArcBg
  local colorBlue = widget.colorBlue
  local colorOrange = widget.colorOrange
  local colorRed = widget.colorRed
  local baseY = widget.baseY
  local thick = widget.thick
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
  
  -- Positions jauges arcs
  local cx1 = z.x + z.w - 215 -- Capacité
  local cy1 = baseY + 35
  local cx2 = z.x + z.w - 45  -- FBL
  local cy2 = baseY + 35
  local cx3 = z.x + z.w - 132 -- RSSI
  local cy3 = baseY + 140
  local cx4 = z.x + z.w - 45  -- ESC
  local cy4 = baseY + 140
  local cx5 = z.x + z.w - 132 -- VFR
  local cy5 = baseY + 35
  local r = 42
  
  -- Valeurs normalisées
  local vFuel = clamp(fuel / 100, 0, 1)
  local vTFBL = clamp(tfbl / 120, 0, 1)
  local vRSSI = clamp(rssi / 100, 0, 1)
  local vTESC = clamp(tesc / 120, 0, 1)
  local vMaxTFBL = clamp(widget.maxTfbl / 120, 0, 1)
  local vMaxTESC = clamp(widget.maxTesc / 120, 0, 1)
  local vMinVFR = clamp(widget.minVfr / 100, 0, 1)
  local vMinRSSI = clamp(widget.minRssi / 100, 0, 1)
  local vMinFuel = clamp(widget.minFuel / 100, 0, 1)
  
  -- Couleurs jauges
  local Rf, Gf, Bf = getFuelColor(fuel, colorBlue, colorOrange, colorRed)
  local RtFBL, GtFBL, BtFBL = getTfblColor(tfbl, colorBlue, colorOrange, colorRed)
  local Rr, Gr, Br = getRssiColor(rssi, colorBlue, colorOrange, colorRed)
  local RtESC, GtESC, BtESC = getTescColor(tesc, colorBlue, colorOrange, colorRed)
  local Rv, Gv, Bv = getVfrColor(vfr, colorBlue, colorOrange, colorRed)
  
  -- Dessiner jauges arcs
  drawGauge(widget, cx1, cy1, r, vFuel, Rf, Gf, Bf, "Capacité", thick, vMinFuel, false, colorBg, colorArcBg, colorRed)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(cx1, cy1 + 0, string.format("%d%%", math.floor(fuel + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_SECONDARY)
  lcd.drawText(cx1, cy1 + 12, string.format("%d", math.floor(widget.minFuel + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  
  drawGauge(widget, cx2, cy2, r, vTFBL, RtFBL, GtFBL, BtFBL, "FBL", thick, vMaxTFBL, true, colorBg, colorArcBg, colorRed)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(cx2, cy2 + 0, string.format("%d°C", math.floor(tfbl + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_SECONDARY)
  lcd.drawText(cx2, cy2 + 12, string.format("%d", math.floor(widget.maxTfbl + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  
  drawGauge(widget, cx3, cy3, r, vRSSI, Rr, Gr, Br, "RSSI", thick, vMinRSSI, false, colorBg, colorArcBg, colorRed)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(cx3, cy3 + 0, string.format("%d%%", math.floor(rssi + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_SECONDARY)
  lcd.drawText(cx3, cy3 + 12, string.format("%d", math.floor(widget.minRssi + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  
  drawGauge(widget, cx4, cy4, r, vTESC, RtESC, GtESC, BtESC, "ESC", thick, vMaxTESC, true, colorBg, colorArcBg, colorRed)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(cx4, cy4 + 0, string.format("%d°C", math.floor(tesc + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_SECONDARY)
  lcd.drawText(cx4, cy4 + 12, string.format("%d", math.floor(widget.maxTesc + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  
  drawGauge(widget, cx5, cy5, r, vVFR, Rv, Gv, Bv, "VFR", thick, vMinVFR, false, colorBg, colorArcBg, colorRed)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(cx5, cy5 + 0, string.format("%d%%", math.floor(vfr + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_SECONDARY)
  lcd.drawText(cx5, cy5 + 12, string.format("%d", math.floor(widget.minVfr + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  
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