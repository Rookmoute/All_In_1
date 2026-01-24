-- /WIDGETS/All_IN_1/helpers.lua
-- Fonctions helpers communes pour éviter la duplication de code

local M = {}

function M.clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

function M.safeRGB(r, g, b)
  r = math.max(0, math.min(255, math.floor(r or 0)))
  g = math.max(0, math.min(255, math.floor(g or 0)))
  b = math.max(0, math.min(255, math.floor(b or 0)))
  return lcd.RGB(r, g, b)
end

function M.getRGB(color)
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

function M.getFuelColor(value, blueColor, orangeColor, redColor)
  if value > 50 then return M.getRGB(blueColor) end
  if value > 20 then return M.getRGB(orangeColor) end
  return M.getRGB(redColor)
end

function M.getTfblColor(value, blueColor, orangeColor, redColor)
  if value <= 40 then return M.getRGB(blueColor) end
  if value < 50 then return M.getRGB(orangeColor) end
  return M.getRGB(redColor)
end

function M.getTescColor(value, blueColor, orangeColor, redColor)
  if value <= 40 then return M.getRGB(blueColor) end
  if value < 60 then return M.getRGB(orangeColor) end
  return M.getRGB(redColor)
end

function M.getRssiColor(value, blueColor, orangeColor, redColor)
  if value > 60 then return M.getRGB(blueColor) end
  if value > 40 then return M.getRGB(orangeColor) end
  return M.getRGB(redColor)
end

function M.getVfrColor(value, blueColor, orangeColor, redColor)
  if value > 60 then return M.getRGB(blueColor) end
  if value > 40 then return M.getRGB(orangeColor) end
  return M.getRGB(redColor)
end

function M.formatTime(sec)
  sec = math.floor(math.abs(sec))
  local m = math.floor(sec / 60)
  local s = sec % 60
  return string.format("%02d:%02d", m, s)
end

return M
