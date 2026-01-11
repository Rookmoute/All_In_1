-- All_In_1_Sensors.lua
-- Script TOOLS pour configurer les capteurs du widget AllIN1
-- Compatible EdgeTX

local cfgPath = "/SCRIPTS/ALL_IN_1/AllIN1_cfg.lua"

local labels = {
  "Tension pack",
  "BEC",
  "Courant",
  "Capacite %",
  "RPM",
  "RSSI",
  "Temp FBL",
  "Temp ESC",
  "Conso mAh",
  "VFR",
  "CHP/Proc"
}

local keys = {
  "VBAT","VBEC","CURR","FUEL","RPM","RSSI","TFBL","TESC","CONS","VFR","CHP"
}

local cfg = {}
local selectedLine = 1
local editMode = false
local editIndex = 1
local sourcesList = {}
local savedMessage = ""
local savedMessageTime = 0

-- Fonction pour construire la liste des sources disponibles
local function buildSourcesList()
  sourcesList = {}
  
  -- Ajouter une option vide
  table.insert(sourcesList, { name = "---", id = 0 })
  
  for i = 0, 500 do
    local info = getFieldInfo(i)
    if info and info.name and type(info.name) == "string" then
      local name = info.name
      local nameLower = string.lower(name)
      local len = string.len(name)
      local exclude = false
      
      -- CH ou ch suivi de chiffres
      if len >= 3 then
        local prefix = string.sub(nameLower, 1, 2)
        if prefix == "ch" then
          local num = string.sub(name, 3)
          if tonumber(num) then exclude = true end
        end
      end
      
      -- I ou i suivi de chiffres, ou "input"
      if not exclude and len >= 2 then
        if string.sub(nameLower, 1, 5) == "input" then
          exclude = true
        elseif string.sub(nameLower, 1, 1) == "i" then
          local num = string.sub(name, 2)
          if tonumber(num) then exclude = true end
        end
      end
      
      -- S + A-H (majuscule ou minuscule)
      if not exclude and len >= 2 then
        local first = string.sub(nameLower, 1, 1)
        local second = string.sub(nameLower, 2, 2)
        if first == "s" and (second >= "a" and second <= "h") then
          exclude = true
        end
      end
      
      -- LS ou ls
      if not exclude and len >= 2 then
        if string.sub(nameLower, 1, 2) == "ls" then
          exclude = true
        end
      end
      
      -- GV ou gv ou gvar
      if not exclude and len >= 2 then
        local prefix2 = string.sub(nameLower, 1, 2)
        local prefix4 = string.sub(nameLower, 1, 4)
        if prefix2 == "gv" or prefix4 == "gvar" then
          exclude = true
        end
      end
      
      -- CYC ou cyc
      if not exclude and len >= 3 then
        if string.sub(nameLower, 1, 3) == "cyc" then
          exclude = true
        end
      end
      
      -- PPM ou ppm
      if not exclude and len >= 3 then
        if string.sub(nameLower, 1, 3) == "ppm" then
          exclude = true
        end
      end
      
      -- Trim ou trim
      if not exclude and len >= 3 then
        if string.sub(nameLower, 1, 4) == "trim" or string.sub(nameLower, 1, 3) == "trm" then
          exclude = true
        end
      end
      
      -- Timer ou timer
      if not exclude and len >= 3 then
        if string.sub(nameLower, 1, 5) == "timer" or string.sub(nameLower, 1, 3) == "tmr" then
          exclude = true
        end
      end
      
      -- EXT ou ext
      if not exclude and len >= 3 then
        if string.sub(nameLower, 1, 3) == "ext" then
          exclude = true
        end
      end
      
      -- LUA ou lua
      if not exclude and len >= 3 then
        if string.sub(nameLower, 1, 3) == "lua" then
          exclude = true
        end
      end
      
      -- Sticks
      if not exclude then
        if nameLower == "rud" or nameLower == "ele" or nameLower == "thr" or nameLower == "ail" then
          exclude = true
        end
      end
      
      -- MAX, MIN
      if not exclude then
        if nameLower == "max" or nameLower == "min" then
          exclude = true
        end
      end
      
      if not exclude then
        table.insert(sourcesList, { name = name, id = i })
      end
    end
  end
  
  -- Trier par nom
  table.sort(sourcesList, function(a, b) 
    if a.name == "---" then return true end
    if b.name == "---" then return false end
    return a.name < b.name 
  end)
end

-- Fonction pour trouver l'index d'une source par son nom
local function findSourceIndex(name)
  if not name or name == "" then return 1 end
  for i, src in ipairs(sourcesList) do
    if src.name == name then
      return i
    end
  end
  return 1
end

-- Fonction pour charger la configuration
local function loadCfg()
  cfg = {
    VBAT  = "Vbat",
    VBEC  = "Vbec",
    CURR  = "Curr",
    FUEL  = "Bat%",
    RPM   = "Hspd",
    RSSI  = "RSSI",
    TFBL  = "Tfbl",
    TESC  = "Tesc",
    CONS  = "mah1",
    VFR   = "VFR",
    CHP   = "ChP"
  }

  local chunk = loadScript(cfgPath)
  if chunk then
    local ok, t = pcall(chunk)
    if ok and type(t) == "table" then
      for k, v in pairs(t) do
        if type(k) == "string" and type(v) == "string" then
          cfg[k] = v
        end
      end
    end
  end
end

-- Fonction pour sauvegarder la configuration
local function saveCfg()
  -- Construire le contenu du fichier
  local content = "-- Auto-generated by AllIN1Tool.lua\n"
  content = content .. "-- Timestamp: " .. getTime() .. "\n"
  content = content .. "local cfg = {\n"
  for _, key in ipairs(keys) do
    local v = cfg[key] or ""
    content = content .. string.format("  %s = %q,\n", key, v)
  end
  content = content .. "}\n\nreturn cfg\n"
  
  -- Sauvegarder avec une méthode compatible EdgeTX
  local result = pcall(function()
    local f = io.open(cfgPath, "w")
    if f then
      io.write(f, content)
      io.close(f)
    end
  end)
  
  -- Si échec, essayer une autre méthode
  if not result then
    pcall(function()
      local f = assert(io.open(cfgPath, "w"))
      f:write(content)
      f:close()
    end)
  end
end

-- Initialisation
local function init()
  loadCfg()
  buildSourcesList()
end

-- Fonction principale
local function run(event)
  lcd.clear()
  
  -- Titre
  lcd.drawText(LCD_W / 2, 5, "Config capteurs AllIN1", MIDSIZE + CENTER)
  
  -- Ligne de séparation
  lcd.drawLine(0, 32, LCD_W, 32, SOLID, 1)
  
  -- Instructions
  if editMode then
    lcd.drawText(LCD_W / 2, 38, "Molette=choisir  ENTER=OK  EXIT=annuler", SMLSIZE + CENTER)
  else
    lcd.drawText(LCD_W / 2, 38, "Haut/Bas=naviguer  ENTER=modifier  EXIT=quitter", SMLSIZE + CENTER)
  end
  
  -- Gestion des événements
  if event == EVT_VIRTUAL_EXIT or event == EVT_RTN_FIRST then
    if editMode then
      editMode = false
    else
      return 2  -- Quitter le script
    end
  elseif event == EVT_VIRTUAL_ENTER or event == EVT_ENTER_BREAK then
    if editMode then
      -- Valider la sélection
      local selectedSource = sourcesList[editIndex]
      if selectedSource then
        cfg[keys[selectedLine]] = selectedSource.name
        saveCfg()
        savedMessage = "OK"
        savedMessageTime = getTime()
      end
      editMode = false
    else
      -- Entrer en mode édition
      editMode = true
      editIndex = findSourceIndex(cfg[keys[selectedLine]])
    end
  elseif event == EVT_VIRTUAL_NEXT or event == EVT_ROT_RIGHT then
    if editMode then
      -- Source suivante
      editIndex = editIndex + 1
      if editIndex > #sourcesList then editIndex = 1 end
    else
      -- Ligne suivante
      selectedLine = selectedLine + 1
      if selectedLine > #keys then selectedLine = 1 end
    end
  elseif event == EVT_VIRTUAL_PREV or event == EVT_ROT_LEFT then
    if editMode then
      -- Source précédente
      editIndex = editIndex - 1
      if editIndex < 1 then editIndex = #sourcesList end
    else
      -- Ligne précédente
      selectedLine = selectedLine - 1
      if selectedLine < 1 then selectedLine = #keys end
    end
  end
  
  -- Zone de liste
  local listY = 60
  local listH = LCD_H - listY - 25
  local lineH = 28
  local maxLines = 5
  
  -- Dessiner le cadre de la liste
  lcd.drawRectangle(0, listY, LCD_W, listH, SOLID, 1)
  
  -- En-têtes de colonnes
  lcd.drawText(15, listY + 0, "Capteur", SMLSIZE + BOLD)
  lcd.drawText(LCD_W - 110, listY + 0, "Source", SMLSIZE + BOLD)
  lcd.drawLine(5, listY + 26, LCD_W - 5, listY + 26, SOLID, 1)
  
  -- Afficher les lignes
  local y = listY + 33
  local startLine = math.max(1, math.min(selectedLine - 2, #keys - maxLines + 1))
  local endLine = math.min(#keys, startLine + maxLines - 1)
  
  for i = startLine, endLine do
    local key = keys[i]
    local label = labels[i]
    local value = cfg[key] or "---"
    
    -- Highlight de la ligne sélectionnée
    if i == selectedLine then
      lcd.drawRectangle(5, y - 4, LCD_W - 10, lineH - 2, SOLID, 2)
    end
    
    -- Label
    lcd.drawText(15, y, label, SMLSIZE)
    
    -- Valeur
    if editMode and i == selectedLine then
      local editName = sourcesList[editIndex].name
      lcd.drawRectangle(LCD_W - 120, y - 2, 110, lineH - 6, SOLID, 1)
      lcd.drawText(LCD_W - 115, y, editName, SMLSIZE + BOLD + INVERS)
    else
      lcd.drawText(LCD_W - 115, y, value, SMLSIZE)
    end
    
    y = y + lineH
  end
  
  -- Barre d'état
  lcd.drawFilledRectangle(0, LCD_H - 18, LCD_W, 18, GREY_DEFAULT)
  
  if savedMessage ~= "" and (getTime() - savedMessageTime) < 150 then
    lcd.drawText(5, LCD_H - 15, "Sauvegarde OK!", SMLSIZE + BOLD)
  else
    savedMessage = ""
    lcd.drawText(5, LCD_H - 15, string.format("Sources: %d", #sourcesList), SMLSIZE)
  end
  
  if editMode then
    lcd.drawText(LCD_W - 5, LCD_H - 15, string.format("%d/%d", editIndex, #sourcesList), SMLSIZE + RIGHT)
  else
    lcd.drawText(LCD_W - 5, LCD_H - 15, string.format("Ligne %d/%d", selectedLine, #keys), SMLSIZE + RIGHT)
  end
  
  return 0
end

return { init = init, run = run }