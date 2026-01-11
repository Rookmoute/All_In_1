-- /WIDGETS/All_IN_1/main.lua
-- Compatible avec EdgeTX 2.11.x sur FRSKY Horus X10S (480x272)
-- Toutes les fonctions sont expliquées dans le script
-- Script autonome pour hélicoptère avec FBL
-- Créé par Rookmoute en collaboration avec Grok by xAI, claude.ia et perplexity.ai
-- Les couleurs des jauges (adaptées pour un daltonien) sont bleu, orange, rouge, avec des seuils, toutes configurables
-- Mode sélectionné via GV7 (0: segments, 1: arcs). Utilisez le tool script pour changer.

local name = "All_IN_1"

-- Options du widget (10/10 autorisées sur EdgeTX 2.11) - conservées comme d'origine
local options = {
  { "Thick", VALUE, 10, 8, 12 },           -- épaisseur des arcs (non utilisé avec segments)
  { "Cells", VALUE, 6, 3, 6 },             -- nombre d'éléments batterie
  { "SeuilInfo", VALUE, 40, 20, 50 },      -- seuil info vocale capacité (%)et annonce tous les 3(%)
  { "ColorBlue", COLOR, lcd.RGB(0, 0, 255), 0, 0 },    -- couleur conditions normales (bleu)
  { "ColorOrng", COLOR, lcd.RGB(255, 128, 0), 0, 0 },  -- couleur avertissement (orange)
  { "ColorRed", COLOR, lcd.RGB(200, 0, 0), 0, 0 },     -- couleur alerte critique (rouge)
  { "ColorBg", COLOR, lcd.RGB(0, 0, 0), 0, 0 },   -- couleur fond widget
  { "ColorArcBg", COLOR, lcd.RGB(80, 80, 80), 0, 0 },  -- couleur fond des arcs/segments
  { "ColText", COLOR, lcd.RGB(255, 255, 255), 0, 0 },  -- couleur textes principaux
  { "ColText2", COLOR, lcd.RGB(255, 255, 255), 0, 0 }  -- couleur textes secondaires
}

-- Fonction pour charger la configuration des capteurs
local function loadSensorConfig()
  local cfgPath = "/SCRIPTS/ALL_IN_1/AllIN1_cfg.lua"
  
  -- Valeurs par défaut
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
    CHP  = "ChP"
  }
  
  -- Tentative de chargement du fichier
  local chunk = loadScript(cfgPath)
  if chunk then
    local ok, cfg = pcall(chunk)
    if ok and type(cfg) == "table" then
      -- Fusionner avec les valeurs par défaut
      for k, v in pairs(defaultConfig) do
        if cfg[k] and cfg[k] ~= "" then
          defaultConfig[k] = cfg[k]
        end
      end
    end
  end
  
  return defaultConfig
end

-- Helpers (communs)
local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

local function getNum(src)
  if src == 0 then return 0 end
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
  
  -- Charger la configuration des capteurs (première fois)
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
      TEXT_COLOR     = lcd.RGB(255, 255, 255),
      TEXT_SECONDARY = lcd.RGB(200, 200, 200)
    }
  end
  
  -- Recharger la configuration toutes les 100 itérations (~10 secondes)
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
  
  -- Options numériques
  local thick = o.Thick or 10
  local cells = o.Cells or 6
  local Seuil_Info = o.SeuilInfo or 40
  
  -- Options couleurs
  local colorBlue = o.ColorBlue or lcd.RGB(0, 0, 255)
  local colorOrange = o.ColorOrng or lcd.RGB(255, 165, 0)
  local colorRed = o.ColorRed or lcd.RGB(200, 0, 0)
  local colorBg = o.ColorBg or lcd.RGB(0, 0, 0)
  local colorArcBg = o.ColorArcBg or lcd.RGB(80, 80, 80)
  
  -- Couleurs texte
  hardcoded.TEXT_COLOR = o.ColText or hardcoded.TEXT_COLOR
  hardcoded.TEXT_SECONDARY = o.ColText2 or hardcoded.TEXT_SECONDARY
  
  -- Mode depuis GV7
  local mode = model.getGlobalVariable(7, 0)  -- 0: segments, 1: arcs (changez via tool)
  
  -- Chargement dynamique du fichier d'affichage
  local scriptPath = "/WIDGETS/All_IN_1/" .. (mode == 0 and "segments" or "arcs") .. ".lua"
  local disp = loadScript(scriptPath)()
  
  -- Télémétrie
  local vbat = getNum(hardcoded.VBAT)
  local vbec = getNum(hardcoded.VBEC)
  local curr = getNum(hardcoded.CURR)
  local fuel = getNum(hardcoded.FUEL)
  local rpm = getNum(hardcoded.RPM)
  local rssi = getNum(hardcoded.RSSI)
  local tfbl = getNum(hardcoded.TFBL)
  local tesc = getNum(hardcoded.TESC)
  local cons = getNum(hardcoded.CONS)
  local tval = model.getTimer(0).value
  local vfr = getNum(hardcoded.VFR)
  local chp = getNum(hardcoded.CHP)
  
  local vpercell = (cells > 0) and (vbat / cells) or 0
  local vVFR = clamp(vfr / 100, 0, 1)
  
  -- Max sécurisés
  widget.maxTfbl = updateMax(widget.maxTfbl, tfbl, 10)
  widget.maxTesc = updateMax(widget.maxTesc, tesc, 10)
  widget.maxChp = updateMax(widget.maxChp, chp, 5)
  widget.maxCurr = math.max(widget.maxCurr, curr > 0 and curr or 0)
  
  if curr > 0 then
    widget.currSum = widget.currSum + curr
    widget.currCount = widget.currCount + 1
  end
  local avgCurr = (widget.currCount > 0) and (widget.currSum / widget.currCount) or 0
  
  -- Tracking min
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
  
  -- Compteur vols
  if widget.prevTimer <= 30 and tval > 30 then
    widget.flightCount = widget.flightCount + 1
    model.setGlobalVariable(8, 0, widget.flightCount)
  end
  widget.prevTimer = tval
  
  -- Annonce vocale fuel
  local flooredFuel = math.floor(fuel)
  if flooredFuel >= Seuil_Info then
    widget.lastAnnouncedFuel = 101
  elseif flooredFuel < Seuil_Info and flooredFuel <= widget.lastAnnouncedFuel - 3 then
    playNumber(flooredFuel, UNIT_PERCENT, 0)
    widget.lastAnnouncedFuel = flooredFuel
  end
  
  -- Fond
  lcd.drawFilledRectangle(z.x, z.y, z.w, z.h, colorBg)
  
  local yOffset = 25
  local baseY = z.y + yOffset
  
  -- Stockage des valeurs dans widget pour les refresh_modes
  widget.vbat = vbat
  widget.vbec = vbec
  widget.curr = curr
  widget.fuel = fuel
  widget.rpm = rpm
  widget.rssi = rssi
  widget.tfbl = tfbl
  widget.tesc = tesc
  widget.cons = cons
  widget.tval = tval
  widget.vfr = vfr
  widget.chp = chp
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
  
  -- Appel au refresh du mode choisi
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
