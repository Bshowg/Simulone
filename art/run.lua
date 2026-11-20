-- Draws one building in its four rotations and saves the sprites plus a preview sheet.
--   Aseprite -b --script-param root=<path to art> --script-param item=<name> --script <path to art>/run.lua
-- `item` is the file name in art/buildings without ".lua" (for example "hut" or "watch_house").
-- Output: art/out/buildings/<item>_r0.png .. _r3.png (the sprites, 1x), <item>_night_r0.png .. (the same with lit
-- windows) and art/out/preview/<item>.png (all four by day, 3x).
local root = app.params.root
local item = app.params.item
local ink = dofile(root .. '/lib/ink.lua')
local def = dofile(root .. '/buildings/' .. item .. '.lua')(ink)
local items = {}
for rot = 0, 3 do
  local c = ink.canvas(def.w, def.h, def.height, rot)
  def.draw(c, ink)
  c:finish()
  c:save(root .. '/out/buildings/' .. item .. '_r' .. rot .. '.png')
  items[#items + 1] = { img = c.img, w = def.w, h = def.h, vw = c.vw, vh = c.vh }
end
ink.sheet(root .. '/out/preview/' .. item .. '.png', items, 4, 3)
-- the same building after dark: its windows lit
ink.night = true
ink.P.glass = ink.P.glow                                    -- glazing drawn by hand shows the light too
for rot = 0, 3 do
  local c = ink.canvas(def.w, def.h, def.height, rot)
  def.draw(c, ink)
  c:finish()
  c:save(root .. '/out/buildings/' .. item .. '_night_r' .. rot .. '.png')
end
print('ok ' .. item .. ' ' .. items[1].img.width .. 'x' .. items[1].img.height)
