-- Ant designs for The Colony, at the scale of the chosen ground (12 pixels a cell). Four ways of drawing the ant,
-- each shown as one row on the shaded wall of a tunnel:
--   walking (two steps) · carrying a crumb · carrying soil · carrying an egg · climbing · a young ant · a major ·
--   the queen · a princess · a raider from a rival nest
--   Aseprite -b --script-param out=<folder> --script ants.lua
local out = app.params.out or '.'
local pc = app.pixelColor
local function rgb(s) return tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16) end
local function col(r, g, b) return pc.rgba(math.max(0, math.min(255, math.floor(r))), math.max(0, math.min(255, math.floor(g))), math.max(0, math.min(255, math.floor(b))), 255) end
local function hex(s) local r, g, b = rgb(s); return col(r, g, b) end
local function hash(x, y) local n = (math.floor(x) * 374761393 + math.floor(y) * 668265263) % 4294967296; n = ((n ~ (n >> 13)) * 1274126177) % 4294967296; return ((n ~ (n >> 16)) % 1000) / 1000 end
local function mixc(a, b, t) local r1, g1, b1 = rgb(a); local r2, g2, b2 = rgb(b); return string.format('#%02x%02x%02x', math.floor(r1 + (r2 - r1) * t), math.floor(g1 + (g2 - g1) * t), math.floor(b1 + (b2 - b1) * t)) end

-- Each design: the worker facing right, in two steps. Letters: k body, h the light on it, r the fore-body (head and
-- thorax, where a design colours them apart), l legs, a feelers, m jaws.
local DESIGNS = {
  { id = 'A', name = 'garden ant, seen from the side', side = true,
    pal = { k = '#140a07', h = '#6a4430', r = '#140a07', l = '#2a160e', a = '#2a160e', m = '#2a160e' },
    walk = { { '...........a..', '.kkh.....kk.a.', 'kkkhk.rr.rrr..', 'kkkkkkrrrrrr..', '.kkk..rr..rm..', '..l..l.l.l....', '.l...l..l.l...' },
             { '...........a..', '.kkh.....kk.a.', 'kkkhk.rr.rrr..', 'kkkkkkrrrrrr..', '.kkk..rr..rm..', '...l.l.l..l...', '...l..l...l...' } } },
  { id = 'B', name = 'wood ant, two colours, larger', side = true,
    pal = { k = '#1a0d09', h = '#7a5238', r = '#8e3616', l = '#4a1e10', a = '#4a1e10', m = '#3a160c' },
    walk = { { '.............a...', '..khh......rr.a..', '.kkkhhk.rr.rrrr..', 'kkkkkkk.rrrrrrrr.', 'kkkkkkkrrrrr.rrr.', '.kkkkk..rrr...m..', '..l....l.l.l.....', '.l....l..l..l....' },
               { '.............a...', '..khh......rr.a..', '.kkkhhk.rr.rrrr..', 'kkkkkkk.rrrrrrrr.', 'kkkkkkkrrrrr.rrr.', '.kkkkk..rrr...m..', '...l...l.l..l....', '...l....l...l....' } } },
  { id = 'C', name = 'lit from above: a line of light along the back', side = true, rim = '#e0a060',
    pal = { k = '#0e0706', h = '#0e0706', r = '#0e0706', l = '#7a563c', a = '#7a563c', m = '#7a563c' },
    walk = { { '...........a..', '.kkk.....kk.a.', 'kkkkk.rr.rrr..', 'kkkkkkrrrrrr..', '.kkk..rr..rm..', '..l..l.l.l....', '.l...l..l.l...' },
             { '...........a..', '.kkk.....kk.a.', 'kkkkk.rr.rrr..', 'kkkkkkrrrrrr..', '.kkk..rr..rm..', '...l.l.l..l...', '...l..l...l...' } } },
  { id = 'D', name = 'seen from above, as it walks on the wall', side = false,
    pal = { k = '#180c08', h = '#74482e', r = '#180c08', l = '#3c2014', a = '#3c2014', m = '#3c2014' },
    walk = { { '..l....l.l...', '...l...l..l.a', '.kkk.rr.rrr.a', 'kkhkkrrrrrr..', '.kkk.rr.rrr.a', '...l...l..l.a', '..l....l.l...' },
             { '...l..l...l..', '...l...l.l..a', '.kkk.rr.rrr.a', 'kkhkkrrrrrr..', '.kkk.rr.rrr.a', '...l...l.l..a', '...l..l...l..' } } },
}
local CELLS, SLOT_W, SLOT_H, Z = 11, 30, 24, 5
local W, H = CELLS * SLOT_W, #DESIGNS * SLOT_H

local img = Image(W, H, ColorMode.RGB)
local function put(x, y, c) x, y = math.floor(x), math.floor(y); if x >= 0 and y >= 0 and x < W and y < H then img:drawPixel(x, y, c) end end

-- the shaded wall of a tunnel behind every row, with its floor
for y = 0, H - 1 do for x = 0, W - 1 do
  local ry = y % SLOT_H
  local n = hash(x, y) * 0.5 + hash(x // 3, y // 3) * 0.5
  local base = ({ '#3e2a1b', '#45301f', '#4c3523', '#533a27' })[math.floor(n * 4) + 1]
  if ry >= SLOT_H - 3 then base = ({ '#6b4a30', '#755236', '#80593b' })[math.floor(n * 3) + 1] elseif ry == SLOT_H - 4 then base = '#8a6242' elseif ry < 2 then base = '#2c1d12' end
  img:drawPixel(x, y, hex(base))
end end

-- draw a design's sprite: scaled, in another palette, turned to climb, with a rim of light, with wings, with a load
local function sprite(D, rows, ox, baseY, o)
  o = o or {}
  local s, pal = o.scale or 1, o.pal or D.pal
  local sw, sh = #rows[1], #rows
  local grid, gw, gh = {}, math.ceil(sw * s), math.ceil(sh * s)
  for y = 0, gh - 1 do grid[y] = {}; for x = 0, gw - 1 do
    local ch = rows[math.min(sh, math.floor(y / s) + 1)]:sub(math.min(sw, math.floor(x / s) + 1), math.min(sw, math.floor(x / s) + 1))
    grid[y][x] = ch ~= '.' and ch or nil end end
  if o.wings then for y = 0, math.floor(gh * 0.35) do for x = math.floor(gw * 0.05), math.floor(gw * 0.6) do if (x + y) % 2 == 0 or grid[y][x] == nil then grid[y][x] = 'w' end end end end
  if o.bigHead then for y = 0, gh - 1 do for x = math.floor(gw * 0.62), gw - 1 do
    if grid[y][x] == nil and ((grid[y] and grid[y][x - 1] == 'r') or (grid[y + 1] and grid[y + 1][x] == 'r' and y > gh * 0.1 and y < gh * 0.6)) and x < gw - 2 then grid[y][x] = 'R' end end end
    for y = 0, gh - 1 do for x = 0, gw - 1 do if grid[y][x] == 'R' then grid[y][x] = 'r' end end end end
  local function at(x, y) return grid[y] and grid[y][x] end
  local x0 = ox - gw // 2
  local y0 = D.side and (baseY - gh) or (baseY - 6 - gh // 2)
  for y = 0, gh - 1 do for x = 0, gw - 1 do
    local ch = at(x, y)
    if ch then
      local c = ch == 'w' and '#d8d4c8' or pal[ch] or pal.k
      if D.rim and (ch == 'k' or ch == 'r') and not at(x, y - 1) then c = o.rim or D.rim end
      local px, py = x0 + x, y0 + y
      if o.climb then px, py = ox - gh // 2 + y, baseY - 3 - x end      -- turned a quarter: head up, feet to the wall
      put(px, py, hex(c))
    end
  end end
  if o.carry then
    local hx, hy = x0 + gw, D.side and (y0 + gh * 0.45) or (y0 + gh // 2 - 1)
    if o.climb then hx, hy = ox - 1, baseY - 3 - gw - 1 end
    for j = 0, 2 do for i = 0, 2 do if not ((i == 0 or i == 2) and (j == 0 or j == 2) and o.carry[2]) then put(hx + i - 1, hy + j, hex(o.carry[1])) end end end
  end
end

for row, D in ipairs(DESIGNS) do
  local baseY = row * SLOT_H - 3
  local cx = function(k) return (k - 1) * SLOT_W + SLOT_W // 2 end
  local young = {}; for key, v in pairs(D.pal) do young[key] = mixc(v, '#c8a070', 0.5) end
  local rival = { k = '#7a5a14', h = '#d8b450', r = '#8a6418', l = '#5a4210', a = '#5a4210', m = '#5a4210' }
  if D.id == 'B' then rival = { k = '#2a2a30', h = '#8a8a96', r = '#3a3a44', l = '#1c1c22', a = '#1c1c22', m = '#1c1c22' } end
  sprite(D, D.walk[1], cx(1), baseY)
  sprite(D, D.walk[2], cx(2), baseY)
  sprite(D, D.walk[1], cx(3) - 1, baseY, { carry = { '#e6c46a' } })
  sprite(D, D.walk[2], cx(4) - 1, baseY, { carry = { '#9a7248' } })
  sprite(D, D.walk[1], cx(5) - 1, baseY, { carry = { '#f4f0e4', true } })
  sprite(D, D.walk[1], cx(6), baseY, { climb = true })
  sprite(D, D.walk[1], cx(7), baseY, { pal = young, scale = 0.9 })
  sprite(D, D.walk[1], cx(8), baseY, { scale = 1.35, bigHead = true })
  sprite(D, D.walk[1], cx(9), baseY, { scale = 1.9 })
  sprite(D, D.walk[1], cx(10), baseY, { scale = 1.4, wings = true })
  sprite(D, D.walk[2], cx(11), baseY, { pal = rival, rim = D.rim and '#f0d080' or nil })
end

local function save(z, name)
  local big = Image(W * z, H * z, ColorMode.RGB)
  for y = 0, H - 1 do for x = 0, W - 1 do local c = img:getPixel(x, y); for j = 0, z - 1 do for i = 0, z - 1 do big:drawPixel(x * z + i, y * z + j, c) end end end end
  big:saveAs(out .. '/' .. name)
end
save(Z, 'ants-large.png'); save(2, 'ants-phone-size.png')
print('done')
