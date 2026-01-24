-- /WIDGETS/All_IN_1/main.lua
-- Version 2.1.0

local name = "All_IN_1"

local options = {
  { "Thick",    VALUE, 10, 8, 12 },
  { "Cells",    VALUE, 6, 3, 6 },
  { "SeuilInfo",VALUE, 40, 20, 50 },
  { "ColorBlue",COLOR, lcd.RGB(0, 0, 255), 0, 0 },
  { "ColorOrng",COLOR, lcd.RGB(255,128, 0), 0, 0 },
  { "ColorRed", COLOR, lcd.RGB(200, 0, 0), 0, 0 },
  { "ColorBg",  COLOR, lcd.RGB(0, 0, 0), 0, 0 },
  { "ColorArcBg",COLOR,lcd.RGB(80,80,80), 0, 0 },
  { "ColText",  COLOR, lcd.RGB(255,255,255),0,0 },
  { "ColText2", COLOR, lcd.RGB(200,200,200),0,0 },
}

local function loadSensorConfig()
  local cfgPath = "/SCRIPTS/ALL_IN_1/AllIN1_cfg.lua"
  local defaultConfig = {
    VBAT = "Vbat",
    VBEC = "Vbec",
    CURR = "Curr",
    FUEL = "Bat%",
    RPM  = "Hspd",
    RSSI = "RSSI",
    TFBL = "Tfbl",
    TESC = "Tesc",
    CONS = "mah1",
    VFR  = "VFR",
    CHP  = "ChP",
    CAPACITY = 5000
  }

  local chunk = loadScript(cfgPath)
  if chunk then
    local ok, cfg = pcall(chunk)
    if ok and type(cfg) == "table" then
      for k, v in pairs(defaultConfig) do
        if cfg[k] ~= nil and cfg[k] ~= "" then
          defaultConfig[k] = cfg[k]
        end
      end
    end
  end

  return defaultConfig
end

local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

local function getNum(src)
  if src == nil or src == "" or src == 0 then return 0 end
  local v = getValue(src)
  if v == nil then return 0 end
  if type(v) == "table" then v = v.value or 0 end
  if type(v) ~= "number" then return 0 end
  if v ~= v or v == math.huge or v == -math.huge then return 0 end
  return v
end

local function updateMax(currentMax, newValue, minAcceptable)
  if newValue > minAcceptable then
    return math.max(currentMax, newValue)
  end
  return currentMax
end

local function create(zone, opts)
  local widget = { zone = zone, options = opts }
  widget.lastAnnouncedFuel = 101
  widget.prevTimer = 0
  widget.flightCount = model.getGlobalVariable(8, 0) or 0
  widget.maxTfbl = 0
  widget.maxTesc = 0
  widget.maxChp = 0
  widget.minVfr = 100
  widget.minRssi = 100
  widget.minFuel = 100
  widget.rssi100StartTime = 0
  widget.trackingEnabled = false
  widget.maxCurr = 0
  widget.currSum = 0
  widget.currCount = 0
  widget.configReloadCounter = 0
  widget.hardcoded = nil
  widget.batteryCapacity = 5000
  widget.loadError = nil
  widget.gvInitialized = false
  widget.editingCapacity = false
  widget.capacityEditValue = 50
  widget.editingDisplayMode = false
  widget.displayModeEditValue = 0
  widget.selectedButton = 3
  widget.startupTime = nil

  widget.cachedMode = nil
  widget.cachedDisp = nil

  return widget
end

local function update(widget, opts)
  widget.options = opts
end

local function background(widget)
end

local function refresh(widget, event, touchState)
  local z = widget.zone
  local o = widget.options

  if widget.hardcoded == nil then
    local sensorConfig = loadSensorConfig()
    widget.hardcoded = {
      CURR = sensorConfig.CURR,
      RPM  = sensorConfig.RPM,
      RSSI = sensorConfig.RSSI,
      TFBL = sensorConfig.TFBL,
      TESC = sensorConfig.TESC,
      CONS = sensorConfig.CONS,
      VBAT = sensorConfig.VBAT,
      VBEC = sensorConfig.VBEC,
      FUEL = sensorConfig.FUEL,
      VFR  = sensorConfig.VFR,
      CHP  = sensorConfig.CHP,
      TEXT_COLOR = lcd.RGB(255, 255, 255),
      TEXT_SECONDARY = lcd.RGB(200, 200, 200)
    }
  end

  if not widget.gvInitialized then
    local gv2 = model.getGlobalVariable(1, 0)
    if gv2 == nil or gv2 == 0 then
      model.setGlobalVariable(1, 0, 50)
    end

    local gv8 = model.getGlobalVariable(7, 0)
    if gv8 == nil then
      model.setGlobalVariable(7, 0, 0)
    end

    widget.gvInitialized = true
  end

  local gv2 = model.getGlobalVariable(1, 0)
  if gv2 == nil or gv2 <= 0 or gv2 > 200 then
    gv2 = 50
  end
  widget.batteryCapacity = math.max(500, math.min(20000, gv2 * 100))

  widget.configReloadCounter = widget.configReloadCounter + 1
  if widget.configReloadCounter >= 100 then
    widget.configReloadCounter = 0
    local sensorConfig = loadSensorConfig()
    widget.hardcoded.CURR = sensorConfig.CURR
    widget.hardcoded.RPM  = sensorConfig.RPM
    widget.hardcoded.RSSI = sensorConfig.RSSI
    widget.hardcoded.TFBL = sensorConfig.TFBL
    widget.hardcoded.TESC = sensorConfig.TESC
    widget.hardcoded.CONS = sensorConfig.CONS
    widget.hardcoded.VBAT = sensorConfig.VBAT
    widget.hardcoded.VBEC = sensorConfig.VBEC
    widget.hardcoded.FUEL = sensorConfig.FUEL
    widget.hardcoded.VFR  = sensorConfig.VFR
    widget.hardcoded.CHP  = sensorConfig.CHP
  end

  local hardcoded = widget.hardcoded

  local thick = o.Thick or 10
  local cells = o.Cells or 6
  local Seuil_Info = o.SeuilInfo or 40

  local colorBlue = o.ColorBlue or lcd.RGB(0, 0, 255)
  local colorOrange = o.ColorOrng or lcd.RGB(255, 165, 0)
  local colorRed = o.ColorRed or lcd.RGB(200, 0, 0)
  local colorBg = o.ColorBg or lcd.RGB(0, 0, 0)
  local colorArcBg = o.ColorArcBg or lcd.RGB(80, 80, 80)

  hardcoded.TEXT_COLOR = o.ColText or hardcoded.TEXT_COLOR
  hardcoded.TEXT_SECONDARY = o.ColText2 or hardcoded.TEXT_SECONDARY

  local mode = model.getGlobalVariable(7, 0) or 0
  if mode ~= 0 and mode ~= 1 then
    mode = 0
    model.setGlobalVariable(7, 0, 0)
  end

  if widget.cachedMode ~= mode or widget.cachedDisp == nil then
    local scriptPath = "/WIDGETS/All_IN_1/" .. (mode == 0 and "segments" or "arcs") .. ".lua"
    local chunk = loadScript(scriptPath)
    if not chunk then
      lcd.drawFilledRectangle(z.x, z.y, z.w, z.h, colorBg)
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(255, 0, 0))
      lcd.drawText(z.x + z.w/2, z.y + z.h/2 - 20, "ERREUR:", MIDSIZE + CENTER + CUSTOM_COLOR)
      lcd.drawText(z.x + z.w/2, z.y + z.h/2 + 5, "Fichier manquant", SMLSIZE + CENTER + CUSTOM_COLOR)
      lcd.drawText(z.x + z.w/2, z.y + z.h/2 + 25, scriptPath, SMLSIZE + CENTER + CUSTOM_COLOR)
      return
    end
    local ok, disp = pcall(chunk)
    if not ok or not disp or type(disp.refresh) ~= "function" then
      lcd.drawFilledRectangle(z.x, z.y, z.w, z.h, colorBg)
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(255, 0, 0))
      lcd.drawText(z.x + z.w/2, z.y + z.h/2 - 10, "ERREUR:", MIDSIZE + CENTER + CUSTOM_COLOR)
      lcd.drawText(z.x + z.w/2, z.y + z.h/2 + 15, "Module invalide", SMLSIZE + CENTER + CUSTOM_COLOR)
      return
    end
    widget.cachedMode = mode
    widget.cachedDisp = disp
  end

  local disp = widget.cachedDisp

  local vbat = getNum(hardcoded.VBAT)
  local vbec = getNum(hardcoded.VBEC)
  local curr = getNum(hardcoded.CURR)
  local cons = getNum(hardcoded.CONS)
  local rpm  = getNum(hardcoded.RPM)
  local rssi = getNum(hardcoded.RSSI)
  local tfbl = getNum(hardcoded.TFBL)
  local tesc = getNum(hardcoded.TESC)
  local tval = model.getTimer(0).value
  local vfr  = getNum(hardcoded.VFR)
  local chp  = getNum(hardcoded.CHP)

  local fuel = 100
  if widget.batteryCapacity > 0 then
    fuel = clamp(100 - (cons / widget.batteryCapacity * 100), 0, 100)
  end

  local vpercell = (cells > 0) and (vbat / cells) or 0
  local vVFR = clamp(vfr / 100, 0, 1)

  widget.maxTfbl = updateMax(widget.maxTfbl, tfbl, 10)
  widget.maxTesc = updateMax(widget.maxTesc, tesc, 10)
  widget.maxChp  = updateMax(widget.maxChp, chp, 5)
  widget.maxCurr = math.max(widget.maxCurr, curr > 0 and curr or 0)

  if curr > 0 then
    widget.currSum = widget.currSum + curr
    widget.currCount = widget.currCount + 1
  end
  local avgCurr = (widget.currCount > 0) and (widget.currSum / widget.currCount) or 0

  local currentTime = getTime()
  if rssi >= 100 then
    if widget.rssi100StartTime == 0 then
      widget.rssi100StartTime = currentTime
    elseif not widget.trackingEnabled then
      local elapsed = (currentTime - widget.rssi100StartTime) / 100
      if elapsed >= 2 then widget.trackingEnabled = true end
    end
  elseif not widget.trackingEnabled then
    widget.rssi100StartTime = 0
  end

  if widget.trackingEnabled then
    if vfr > 0 then widget.minVfr = math.min(widget.minVfr, vfr) end
    if rssi > 0 then widget.minRssi = math.min(widget.minRssi, rssi) end
    if fuel > 0 then widget.minFuel = math.min(widget.minFuel, fuel) end
  end

  if widget.prevTimer <= 30 and tval > 30 then
    widget.flightCount = widget.flightCount + 1
    model.setGlobalVariable(8, 0, widget.flightCount)
    widget.trackingEnabled = false
    widget.rssi100StartTime = 0
    widget.minVfr = 100
    widget.minRssi = 100
    widget.minFuel = 100
  end
  widget.prevTimer = tval

  local flooredFuel = math.floor(fuel)
  if flooredFuel >= Seuil_Info then
    widget.lastAnnouncedFuel = 101
  elseif flooredFuel < Seuil_Info and flooredFuel <= widget.lastAnnouncedFuel - 3 then
    playNumber(flooredFuel, UNIT_PERCENT, 0)
    widget.lastAnnouncedFuel = flooredFuel
  end

  lcd.drawFilledRectangle(z.x, z.y, z.w, z.h, colorBg)
  local yOffset = 25
  local baseY = z.y + yOffset

  widget.vbat = vbat
  widget.vbec = vbec
  widget.curr = curr
  widget.fuel = fuel
  widget.rpm  = rpm
  widget.rssi = rssi
  widget.tfbl = tfbl
  widget.tesc = tesc
  widget.cons = cons
  widget.tval = tval
  widget.vfr  = vfr
  widget.chp  = chp
  widget.vpercell = vpercell
  widget.vVFR = vVFR
  widget.avgCurr = avgCurr
  widget.colorBg = colorBg
  widget.colorArcBg = colorArcBg
  widget.colorBlue = colorBlue
  widget.colorOrange = colorOrange
  widget.colorRed = colorRed
  widget.baseY = baseY
  widget.thick = thick
  widget.z = z
  widget.o = o
  widget.event = event
  widget.touchState = touchState

  disp.refresh(widget)
end

return {
  name = name,
  options = options,
  create = create,
  update = update,
  refresh = refresh,
  background = background
}
