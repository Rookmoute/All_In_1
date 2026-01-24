-- /WIDGETS/All_IN_1/arcs.lua
-- Fonctions pour mode arcs

local helpers = loadScript("/WIDGETS/All_IN_1/helpers.lua")()
local ui_common = loadScript("/WIDGETS/All_IN_1/ui_common.lua")()

local clamp = helpers.clamp
local safeRGB = helpers.safeRGB
local getFuelColor = helpers.getFuelColor
local getTfblColor = helpers.getTfblColor
local getTescColor = helpers.getTescColor
local getRssiColor = helpers.getRssiColor
local getVfrColor = helpers.getVfrColor

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
  local baseY = widget.baseY
  local thick = widget.thick
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

  -- Positions jauges arcs
  local cx2 = z.x + z.w - 45  -- FBL
  local cy2 = baseY + 35
  local cx3 = z.x + z.w - 132 -- RSSI
  local cy3 = baseY + 140
  local cx4 = z.x + z.w - 45  -- ESC
  local cy4 = baseY + 140
  local cx5 = z.x + z.w - 132 -- VFR
  local cy5 = baseY + 35

  local r = 42

  local vFuel = clamp(fuel / 100, 0, 1)
  local vTFBL = clamp(tfbl / 120, 0, 1)
  local vRSSI = clamp(rssi / 100, 0, 1)
  local vTESC = clamp(tesc / 120, 0, 1)

  local vMaxTFBL = clamp(widget.maxTfbl / 120, 0, 1)
  local vMaxTESC = clamp(widget.maxTesc / 120, 0, 1)
  local vMinVFR  = clamp(widget.minVfr / 100, 0, 1)
  local vMinRSSI = clamp(widget.minRssi / 100, 0, 1)
  local vMinFuel = clamp(widget.minFuel / 100, 0, 1)

  local Rf, Gf, Bf = getFuelColor(fuel, colorBlue, colorOrange, colorRed)
  local RtFBL, GtFBL, BtFBL = getTfblColor(tfbl, colorBlue, colorOrange, colorRed)
  local Rr, Gr, Br = getRssiColor(rssi, colorBlue, colorOrange, colorRed)
  local RtESC, GtESC, BtESC = getTescColor(tesc, colorBlue, colorOrange, colorRed)
  local Rv, Gv, Bv = getVfrColor(vfr, colorBlue, colorOrange, colorRed)

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

  drawGauge(widget, cx5, cy5, r, clamp(widget.vVFR,0,1), Rv, Gv, Bv, "VFR", thick, vMinVFR, false, colorBg, colorArcBg, colorRed)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_COLOR)
  lcd.drawText(cx5, cy5 + 0, string.format("%d%%", math.floor(vfr + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, widget.hardcoded.TEXT_SECONDARY)
  lcd.drawText(cx5, cy5 + 12, string.format("%d", math.floor(widget.minVfr + 0.5)), SMLSIZE + CENTER + CUSTOM_COLOR)

  ui_common.drawCapacityBarAndStats(widget)
end

return { refresh = refresh }
