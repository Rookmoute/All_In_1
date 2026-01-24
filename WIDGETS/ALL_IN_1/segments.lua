-- /WIDGETS/All_IN_1/segments.lua
-- Fonctions pour mode segments

local helpers = loadScript("/WIDGETS/All_IN_1/helpers.lua")()
local ui_common = loadScript("/WIDGETS/All_IN_1/ui_common.lua")()

local clamp = helpers.clamp
local safeRGB = helpers.safeRGB
local getFuelColor = helpers.getFuelColor
local getTfblColor = helpers.getTfblColor
local getTescColor = helpers.getTescColor
local getRssiColor = helpers.getRssiColor
local getVfrColor = helpers.getVfrColor

local function drawSegmentGauge(widget, x, y, width, height, value, label, numSegments, R, G, B, bgColor, segmentBgColor, showMinMax, minValue, maxValue, isMaxType, colorBlue, colorOrange, colorRed, gaugeType)
  numSegments = numSegments or 10
  local segmentGap = math.max(1, math.min(5, 13 - (widget.thick or 10)))
  local segmentWidth = math.floor((width - (numSegments - 1) * segmentGap) / numSegments)
  local activeSegments = math.floor(value * numSegments)

  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(x + width / 2, y - 18, label, SMLSIZE + CENTER + CUSTOM_COLOR)

  for i = 0, numSegments - 1 do
    local segX = x + i * (segmentWidth + segmentGap)
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
    if gaugeType == "fuel" or gaugeType == "vfr" or gaugeType == "rssi" then
      extremeActualValue = minValue * 100
    elseif gaugeType == "tfbl" or gaugeType == "tesc" then
      extremeActualValue = maxValue * 120
    end

    local extremeR, extremeG, extremeB
    if gaugeType == "fuel" then
      extremeR, extremeG, extremeB = getFuelColor(extremeActualValue, colorBlue, colorOrange, colorRed)
    elseif gaugeType == "vfr" then
      extremeR, extremeG, extremeB = getVfrColor(extremeActualValue, colorBlue, colorOrange, colorRed)
    elseif gaugeType == "rssi" then
      extremeR, extremeG, extremeB = getRssiColor(extremeActualValue, colorBlue, colorOrange, colorRed)
    elseif gaugeType == "tfbl" then
      extremeR, extremeG, extremeB = getTfblColor(extremeActualValue, colorBlue, colorOrange, colorRed)
    elseif gaugeType == "tesc" then
      extremeR, extremeG, extremeB = getTescColor(extremeActualValue, colorBlue, colorOrange, colorRed)
    end

    for i = 0, numSegments - 1 do
      if i < extremeSegments then
        local segX = x + i * (segmentWidth + segmentGap)
        lcd.drawFilledRectangle(segX, y, segmentWidth, height, safeRGB(extremeR, extremeG, extremeB))
      end
    end
  end
end

local function refresh(widget)
  local z = widget.z
  local baseY = widget.baseY
  local colorBg = widget.colorBg
  local colorArcBg = widget.colorArcBg
  local colorBlue = widget.colorBlue
  local colorOrange = widget.colorOrange
  local colorRed = widget.colorRed

  local fuel = widget.fuel
  local tfbl = widget.tfbl
  local tesc = widget.tesc
  local rssi = widget.rssi
  local vfr = widget.vfr

  ui_common.handleButtonsAndHeader(widget)

  local gaugeWidth = 150
  local gaugeHeight = 20
  local gaugeSpacing = 38
  local gx = z.x + z.w - gaugeWidth - 25

  local gy1 = baseY + 10  -- VFR
  local gy2 = gy1 + gaugeSpacing -- RSSI
  local gy3 = gy2 + gaugeSpacing -- TESC
  local gy4 = gy3 + gaugeSpacing -- TFBL
  local gy5 = gy4 + gaugeSpacing -- CAPACITE

  local vFuel = clamp(fuel / 100, 0, 1)
  local vTFBL = clamp(tfbl / 120, 0, 1)
  local vRSSI = clamp(rssi / 100, 0, 1)
  local vTESC = clamp(tesc / 120, 0, 1)

  local vMinFuel = clamp(widget.minFuel / 100, 0, 1)
  local vMaxTFBL = clamp(widget.maxTfbl / 120, 0, 1)
  local vMinRSSI = clamp(widget.minRssi / 100, 0, 1)
  local vMaxTESC = clamp(widget.maxTesc / 120, 0, 1)
  local vMinVFR  = clamp(widget.minVfr / 100, 0, 1)

  -- Afficher min/max si VFR très bas (liaison coupée)
  local showMinMax = (vfr <= 5)

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

  drawSegmentGauge(widget, gx, gy1, gaugeWidth, gaugeHeight, clamp(widget.vVFR,0,1), "VFR", 10, Rv, Gv, Bv, colorBg, colorArcBg, showMinMax, vMinVFR, 0, false, colorBlue, colorOrange, colorRed, "vfr")
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
  lcd.drawText(gx - 2, gy3 + 3, string.format("%d°C", math.floor(tesc + 0.5)), SMLSIZE + RIGHT + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, safeRGB(RmaxTESC, GmaxTESC, BmaxTESC))
  lcd.drawText(gx + gaugeWidth + 2, gy3 + 3, string.format("%d", math.floor(widget.maxTesc + 0.5)), SMLSIZE + CUSTOM_COLOR)

  drawSegmentGauge(widget, gx, gy4, gaugeWidth, gaugeHeight, vTFBL, "FBL", 10, RtFBL, GtFBL, BtFBL, colorBg, colorArcBg, showMinMax, 0, vMaxTFBL, true, colorBlue, colorOrange, colorRed, "tfbl")
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(gx - 2, gy4 + 3, string.format("%d°C", math.floor(tfbl + 0.5)), SMLSIZE + RIGHT + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, safeRGB(RmaxTFBL, GmaxTFBL, BmaxTFBL))
  lcd.drawText(gx + gaugeWidth + 2, gy4 + 3, string.format("%d", math.floor(widget.maxTfbl + 0.5)), SMLSIZE + CUSTOM_COLOR)

  drawSegmentGauge(widget, gx, gy5, gaugeWidth, gaugeHeight, vFuel, "Capacité", 10, Rf, Gf, Bf, colorBg, colorArcBg, showMinMax, vMinFuel, 0, false, colorBlue, colorOrange, colorRed, "fuel")
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(gx - 2, gy5 + 3, string.format("%d%%", math.floor(fuel + 0.5)), SMLSIZE + RIGHT + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, safeRGB(RminFuel, GminFuel, BminFuel))
  lcd.drawText(gx + gaugeWidth + 2, gy5 + 3, string.format("%d", math.floor(widget.minFuel + 0.5)), SMLSIZE + CUSTOM_COLOR)

  ui_common.drawCapacityBarAndStats(widget)
end

return { refresh = refresh }
