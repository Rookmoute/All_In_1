-- Script tool pour sélectionner l'affichage du widget All_IN
-- Placez dans /SCRIPTS/TOOLS/
-- Appuyez sur ENTER pour toggler le mode (0: segments, 1: arcs)
-- Sortez avec RTN ou EXIT

local function run(event)
  lcd.clear()
  
  local mode = model.getGlobalVariable(7, 0)
  
  lcd.drawText(10, 10, "Mode actuel: " .. (mode == 0 and "Segments (LED)" or "Arcs circulaires"), DBLSIZE)
  lcd.drawText(10, 50, "Appuyez sur ENTER pour changer", SMLSIZE)
  lcd.drawText(10, 70, "Sortez avec RTN/EXIT", SMLSIZE)
  
  if event == EVT_ENTER_BREAK then
    mode = 1 - mode
    model.setGlobalVariable(7, 0, mode)
  end
  
  return 0  -- Continue à rafraîchir
end

return { run = run }