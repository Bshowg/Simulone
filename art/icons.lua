-- Small icons for the page: the resources, and a few things the top strip counts. 14 x 14 each, ink outline.
--   Aseprite -b --script-param root=<path to art> --script <path to art>/icons.lua
-- Output: art/out/icons/<name>.png and art/out/icons/preview.png
local root = app.params.root
local ink = dofile(root .. '/lib/ink.lua')
local P = ink.P
local items = {}
local function icon(name, draw)
  local s = ink.sprite(14, 14)
  draw(s)
  s:finish('outer')
  s:save(root .. '/out/icons/' .. name .. '.png')
  items[#items + 1] = { img = s.img }
end

icon('grain', function(s)                                    -- a sheaf: ears fanning out above the tie
  local half = { 5, 5, 4, 4, 3, 2, 1, 2, 2, 3 }                -- half-width of each row, from the top
  for r, h in ipairs(half) do s:rect(7 - h, r + 1, 6 + h, r + 1, r <= 4 and P.corn or P.corn2) end
  for x = 2, 11, 2 do s:put(x, 2, P.cornLine); s:put(x + 1, 4, P.cornLine) end
  s:rect(6, 8, 7, 8, P.furrow)
  s:put(5, 11, P.cornLine); s:put(8, 11, P.cornLine)
end)
icon('firewood', function(s)                                 -- three split logs, end on
  for _, c in ipairs({ { 4, 9 }, { 9, 9 }, { 7, 5 } }) do
    s:disc(c[1], c[2], 2, P.wood); s:put(c[1], c[2], P.woodShadeLine); s:put(c[1] + 1, c[2] + 1, P.woodShade)
  end
end)
icon('timber', function(s)                                   -- one long trunk
  s:rect(2, 5, 10, 9, P.wood); s:rect(2, 8, 10, 9, P.woodShade)
  s:line(3, 6, 8, 6, P.woodLine)
  s:disc(10, 7, 2, P.earth); s:put(10, 7, P.woodLine)
end)
icon('planks', function(s)                                   -- sawn boards, stacked
  s:rect(2, 3, 10, 5, P.shingle); s:rect(3, 6, 11, 8, P.thatch); s:rect(2, 9, 10, 11, P.shingle)
  s:line(2, 5, 10, 5, P.shingleLine); s:line(3, 8, 11, 8, P.thatchLine); s:line(2, 11, 10, 11, P.shingleLine)
end)
icon('flour', function(s)                                    -- a tied sack
  s:disc(7, 8, 4, P.linen, 0.9); s:rect(5, 2, 8, 3, P.linen); s:line(5, 4, 8, 4, P.ink2)
  s:put(9, 9, P.ink2); s:put(9, 10, P.ink2); s:put(8, 11, P.ink2); s:put(6, 7, P.veil); s:put(5, 8, P.veil)
end)
icon('bread', function(s)                                    -- a round loaf, slashed
  s:disc(7, 8, 5, P.tile, 0.55); s:rect(3, 9, 11, 10, P.tileShade)
  s:line(5, 6, 6, 8, P.tileLine); s:line(7, 5, 8, 8, P.tileLine); s:line(9, 6, 10, 8, P.tileLine)
end)
icon('ale', function(s)                                      -- a wooden mug with a head on it
  s:rect(4, 5, 8, 11, P.wood); s:rect(7, 5, 8, 11, P.woodShade); s:rect(3, 2, 9, 4, P.veil)
  s:line(4, 7, 8, 7, P.woodLine); s:line(4, 10, 8, 10, P.woodLine)
  s:put(10, 6, P.wood); s:put(11, 7, P.wood); s:put(11, 8, P.wood); s:put(10, 9, P.wood)
end)
icon('coin', function(s)                                     -- a penny with its cross
  s:disc(7, 7, 4, P.weld); s:disc(8, 8, 2, P.corn2)
  s:line(7, 4, 7, 10, P.thatchLine); s:line(4, 7, 10, 7, P.thatchLine)
end)
icon('people', function(s)                                   -- head and shoulders
  s:disc(7, 4, 2, P.skin); s:rect(6, 2, 8, 2, P.hair)
  s:rect(4, 8, 10, 12, P.woad); s:rect(5, 7, 9, 7, P.woad); s:rect(9, 8, 10, 12, P.slateShadeLine)
end)
icon('food', function(s)                                     -- a full bowl
  s:rect(3, 7, 11, 8, P.wood); s:rect(4, 9, 10, 10, P.wood); s:rect(5, 11, 9, 11, P.woodShade)
  s:rect(4, 6, 10, 6, P.corn2); s:rect(5, 5, 9, 5, P.corn)
  s:put(6, 3, P.smoke); s:put(7, 2, P.smoke); s:put(9, 3, P.smoke)
end)
icon('regard', function(s)                                   -- the lord's seal on its ribbon
  s:disc(7, 6, 4, P.madder); s:disc(7, 6, 2, P.tileShade); s:put(7, 6, P.tileShadeLine)
  s:rect(5, 10, 6, 12, P.tile); s:rect(8, 10, 9, 12, P.tile)
end)

icon('vegetables', function(s)                               -- a cabbage and a leek
  s:disc(6, 8, 4, P.leaf); s:disc(7, 9, 2, P.green); s:put(4, 7, P.leafShade); s:put(8, 6, P.leafShade); s:rect(5, 11, 8, 11, P.leafShade)
  s:rect(10, 3, 11, 9, P.veil); s:rect(10, 1, 11, 3, P.green); s:put(12, 1, P.green)
end)
icon('forage', function(s)                                   -- a little basket of nuts and berries
  s:rect(2, 7, 11, 11, P.wood); s:rect(3, 12, 10, 12, P.woodShade); s:line(2, 9, 11, 9, P.woodLine)
  s:put(4, 6, P.woodShade); s:put(6, 5, P.madder); s:put(7, 6, P.madder); s:put(9, 5, P.woodShade); s:put(10, 6, P.madder); s:put(5, 6, P.madder); s:put(8, 5, P.wood)
  s:line(3, 6, 6, 2, P.woodShadeLine); s:line(6, 2, 10, 6, P.woodShadeLine)
end)
icon('eggs', function(s)                                     -- two eggs
  s:disc(5, 8, 3, P.veil, 1.6); s:disc(9, 8, 3, P.linen, 1.6); s:put(10, 9, P.earth2); s:put(6, 9, P.linen)
end)

ink.sheet(root .. '/out/icons/preview.png', items, #items, 6)
print('ok icons ' .. #items)
