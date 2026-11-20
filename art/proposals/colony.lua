-- Style proposals for The Colony: the same slice of a nest, seen from the side at the game's own scale
-- (a cell is 16 pixels), drawn three different ways.
--   Aseprite -b --script-param out=<folder> --script colony.lua
local out = app.params.out or '.'
local pc = app.pixelColor
local CW, CH, T = 28, 34, 16
local W, H = CW * T, CH * T
local SURF = 5

local function hex(s) return pc.rgba(tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16), 255) end
local function hash(x, y)
  local n = (math.floor(x) * 374761393 + math.floor(y) * 668265263) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  return ((n ~ (n >> 16)) % 1000) / 1000
end
local function pick(r, t) local i = math.floor(t * #r) + 1; if i < 1 then i = 1 elseif i > #r then i = #r end; return hex(r[i]) end

-- ── the slice of nest: kinds of ground from smooth noise, then the tunnels and rooms dug into it
local map, zone = {}, {}
local function smooth(x, y, s, seed) local gx, gy = x / s, y / s; local x0, y0 = math.floor(gx), math.floor(gy); local fx, fy = gx - x0, gy - y0
  local a, b, c, d = hash(x0 + seed, y0), hash(x0 + 1 + seed, y0), hash(x0 + seed, y0 + 1), hash(x0 + 1 + seed, y0 + 1)
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy end
for y = 0, CH - 1 do map[y] = {}; zone[y] = {}
  for x = 0, CW - 1 do
    local k = 'loam'
    if y < SURF then k = 'sky' elseif y == SURF then k = 'air'
    elseif smooth(x, y, 3, 40) > 0.78 then k = 'stone'
    elseif smooth(x, y, 6, 7) > 0.66 and y > 14 then k = 'clay'
    elseif smooth(x, y, 5, 90) > 0.64 and y < 18 then k = 'sand' end
    map[y][x] = k
  end
end
local function dig(x0, y0, x1, y1, z) for y = y0, y1 do for x = x0, x1 do map[y][x] = 'open'; if z then zone[y][x] = z end end end end
dig(14, 6, 14, 12); dig(10, 12, 18, 14); dig(18, 13, 24, 13); dig(22, 13, 22, 22); dig(17, 22, 25, 24, 'brood')
dig(4, 13, 10, 13); dig(5, 13, 5, 19); dig(2, 19, 8, 21, 'food'); dig(14, 14, 14, 28); dig(10, 28, 18, 30, 'garden'); dig(14, 31, 14, 32)
map[31][14] = 'water'; map[32][14] = 'water'; map[30][13] = 'water'; map[30][14] = 'water'; map[30][15] = 'water'
map[23][26] = 'marked'; map[23][27] = 'marked'; map[9][15] = 'marked'; map[9][16] = 'marked'; map[9][17] = 'marked'
local function solid(x, y) local k = map[y] and map[y][x]; return k ~= 'open' and k ~= 'air' and k ~= 'water' and k ~= 'sky' end
local function isOpen(x, y) local k = map[y] and map[y][x]; return k == 'open' or k == 'water' end

-- where the ants are: { cell x, cell y, heading (1 right, -1 left, 2 down, -2 up), what it carries, kind }
local ANTS = { { 14, 7, -2, 'soil' }, { 14, 9, 2 }, { 14, 11, -2, 'soil' }, { 11, 13, 1 }, { 12, 14, -1, 'crumb' }, { 16, 12, 1 }, { 17, 14, -1 }, { 20, 13, 1, 'egg' }, { 23, 13, -1 },
  { 22, 16, 2, 'egg' }, { 22, 19, -2 }, { 19, 23, 1 }, { 21, 22, -1 }, { 24, 24, -1 }, { 25, 23, 1, nil, 'dig' }, { 7, 13, -1, 'crumb' }, { 5, 15, 2, 'crumb' }, { 5, 18, -2 },
  { 4, 20, 1 }, { 7, 21, -1 }, { 14, 17, 2 }, { 14, 21, -2 }, { 14, 25, 2 }, { 12, 29, 1 }, { 16, 28, -1 }, { 17, 30, -1 }, { 9, 5, 1, 'crumb' }, { 6, 5, 1 }, { 20, 5, -1 }, { 24, 5, -1, 'crumb' },
  { 14, 13, 1, nil, 'queen' }, { 13, 12, 1, nil, 'major' }, { 15, 6, -2, nil, 'major' } }

local STYLES = {
  -- 1. Pen and wash: the paper and brown ink of The Lord's Will. Earth is a thin wash, the nest is bare paper.
  { id = '1-pen-and-wash', ink = '#4a382c', line = true,
    sky = function(px, py) return hex('#eadfc6') end,
    ground = { loam = { '#cdb898', '#c6b08e', '#d2bea0' }, sand = { '#e0d0a4', '#d8c898', '#e6d8ae' }, clay = { '#c49a82', '#bc9078', '#caa48c' }, stone = { '#b8b2a6', '#aaa498', '#c4beb2' } },
    grain = 0.05, open = { '#f3ecda', '#efe7d2' }, water = { '#a9c6d0', '#9dbccb', '#c6dbe0' }, mark = '#f8f2e2',
    zones = { brood = '#e3d6ea', food = '#ecd9a6', garden = '#cfdcb0' }, grass = '#8fa56c', soil = '#8a6f52',
    ant = '#3d2a1c', queen = '#6a4a6e', major = '#8a3a28', crumb = '#d9b24a', egg = '#fbf7ea', larva = '#ecd9ae', pupa = '#c9a070' },
  -- 2. Engraved plate: a cut through dark earth as in an old natural history book. Shade is hatching; the nest is pale.
  { id = '2-engraved-plate', ink = '#1f1a16', line = true, hatch = true,
    sky = function(px, py) return (py % 4 == 0 and px % 2 == 0) and hex('#cfc6b0') or hex('#e9e2d0') end,
    ground = { loam = { '#5a4a3c', '#52443a', '#62513f' }, sand = { '#8a7a5c', '#807052', '#948462' }, clay = { '#6e4636', '#663f30', '#764c3a' }, stone = { '#8c8880', '#7e7a72', '#9a968e' } },
    grain = 0.16, open = { '#e9e2d0', '#e2dac6' }, water = { '#6f8f9e', '#5f8090', '#8fa9b4' }, mark = '#cfc6b0',
    zones = { brood = '#d9c8dc', food = '#e2c98a', garden = '#bccf9c' }, grass = '#3f4a30', soil = '#3a3026',
    ant = '#1f1a16', queen = '#4a2a4e', major = '#6a1c14', crumb = '#b8862e', egg = '#fffdf4', larva = '#e6d2a0', pupa = '#a8804e' },
  -- 3. Lit burrow: night-dark earth, and a nest that glows from inside. The strongest contrast, the easiest to read small.
  { id = '3-lit-burrow', ink = '#0e0b0a', line = false, glow = true,
    sky = function(px, py) return pick({ '#1a2440', '#1f2a4a', '#24305a' }, py / (SURF * T)) end,
    ground = { loam = { '#2a2018', '#261c15', '#2e241b' }, sand = { '#3e3424', '#3a3020', '#443a28' }, clay = { '#3a2018', '#341c15', '#40241b' }, stone = { '#3c3c40', '#34343a', '#444448' } },
    grain = 0.1, open = { '#c98a4a', '#c08040', '#d4964e' }, water = { '#2f6fb0', '#3f84c8', '#8ccbee' }, mark = '#6a4a30',
    zones = { brood = '#d9a0c0', food = '#f0c050', garden = '#9ac860' }, grass = '#24402c', soil = '#1c1510',
    ant = '#1a0f0a', queen = '#5a1c4a', major = '#7a1408', crumb = '#ffe070', egg = '#ffffff', larva = '#ffe8b0', pupa = '#e0a860' },
}

local function draw(S)
  local img = Image(W, H, ColorMode.RGB)
  local function put(x, y, c) x, y = math.floor(x), math.floor(y); if x >= 0 and y >= 0 and x < W and y < H then img:drawPixel(x, y, c) end end
  local function rect(x, y, w, h, c) for j = 0, h - 1 do for i = 0, w - 1 do put(x + i, y + j, c) end end end
  local ink = hex(S.ink)

  for py = 0, H - 1 do for px = 0, W - 1 do
    local cx, cy = px // T, py // T
    local k, c = map[cy][cx]
    if k == 'sky' or k == 'air' then c = S.sky(px, py)
    elseif k == 'open' then
      c = pick(S.open, hash(px // 3, py // 2))
      if S.glow then local d = 0; for _, o in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do if solid(cx + o[1], cy + o[2]) then
        local e = o[1] == 1 and (T - 1 - px % T) or o[1] == -1 and px % T or o[2] == 1 and (T - 1 - py % T) or py % T; if e < 4 then d = math.max(d, 4 - e) end end end
        if d > 0 then c = pc.rgba(math.floor(pc.rgbaR(c) * (1 - d * 0.14)), math.floor(pc.rgbaG(c) * (1 - d * 0.16)), math.floor(pc.rgbaB(c) * (1 - d * 0.18)), 255) end end
      local z = zone[cy][cx]
      if z and ((px + py) % 3 ~= 0 or S.glow) then local zc = hex(S.zones[z]); local f = S.glow and 0.45 or 0.6
        c = pc.rgba(math.floor(pc.rgbaR(c) * (1 - f) + pc.rgbaR(zc) * f), math.floor(pc.rgbaG(c) * (1 - f) + pc.rgbaG(zc) * f), math.floor(pc.rgbaB(c) * (1 - f) + pc.rgbaB(zc) * f), 255) end
    elseif k == 'water' then
      c = pick(S.water, hash(px // 5, py) * 0.6); if (py + math.floor(math.sin(px / 3) * 1.5)) % 5 == 0 then c = hex(S.water[3]) end
    else
      local g = S.ground[k == 'marked' and 'loam' or k]
      local n = hash(px // 2, py // 2) * 0.5 + hash(px // 5 + 11, py // 3) * 0.5
      c = pick(g, n)
      if hash(px * 3, py * 7) < S.grain then c = hex(g[2]) end
      if S.hatch then                                           -- each kind of ground has its own engraved texture
        if k == 'loam' and (px + py) % 4 == 0 then c = ink elseif k == 'clay' and py % 3 == 0 then c = ink
        elseif k == 'sand' and hash(px, py) > 0.86 then c = ink elseif k == 'stone' and ((px - py) % 6 == 0 and hash(px // 6, py // 6) > 0.4) then c = ink end
      elseif k == 'stone' and (px % T == 0 or py % T == 0) and hash(cx, cy) > 0.3 then c = hex(g[2])
      elseif k == 'clay' and py % 5 == 0 and hash(px // 7, py) > 0.5 then c = hex(g[2])
      elseif k == 'sand' and hash(px * 5, py * 3) > 0.93 then c = hex(g[3]) end
      if k == 'marked' then local m = hex(S.mark); c = ((px // 2 + py // 2) % 2 == 0) and m or c end
    end
    img:drawPixel(px, py, c)
  end end

  -- the line where dug-out ground meets earth, and where the surface meets the sky
  for cy = 0, CH - 1 do for cx = 0, CW - 1 do
    if isOpen(cx, cy) or map[cy][cx] == 'air' then
      local x, y = cx * T, cy * T
      local e = S.line and ink or hex(S.ground.loam[2])
      if solid(cx, cy - 1) then for i = 0, T - 1 do put(x + i, y + (hash(x + i, y) > 0.8 and 1 or 0), e) end end
      if solid(cx, cy + 1) then for i = 0, T - 1 do put(x + i, y + T - 1 - (hash(x + i, y + 9) > 0.8 and 1 or 0), e) end end
      if solid(cx - 1, cy) then for i = 0, T - 1 do put(x + (hash(x, y + i) > 0.8 and 1 or 0), y + i, e) end end
      if solid(cx + 1, cy) then for i = 0, T - 1 do put(x + T - 1 - (hash(x + 9, y + i) > 0.8 and 1 or 0), y + i, e) end end
    end
  end end

  -- the surface: grass, the mound of dug soil by the way out, a find of crumbs
  local gy = (SURF + 1) * T - 1
  for px = 0, W - 1 do if hash(px, 3) > 0.45 and (px < 13 * T or px > 16 * T) then local h = 2 + math.floor(hash(px, 5) * 4); for j = 0, h do put(px, gy - j, hex(S.grass)) end end end
  for px = 10 * T, 18 * T do local d = math.abs(px - 14.5 * T) / T; if d > 0.7 then local h = math.floor(math.max(0, 15 - d * 4) + hash(px, 1) * 2); for j = 0, h do put(px, gy - j, hex(S.soil)) end; if S.line and h > 0 then put(px, gy - h, ink) end end end
  for k = 0, 11 do rect(4 * T + 2 + (k % 4) * 3, gy - 2 - (k // 4) * 3, 2, 2, hex(S.crumb)) end

  -- what lies in the rooms
  local function dots(cx, cy, n, col, size, top) for k = 0, n - 1 do rect(cx * T + 2 + (k % 3) * 5, top and (cy * T + 2 + (k // 3) * 5) or (cy * T + T - 3 - size - (k // 3) * 4), size, size, hex(col)); if S.line then put(cx * T + 2 + (k % 3) * 5 + size, (top and (cy * T + 2 + (k // 3) * 5) or (cy * T + T - 3 - size - (k // 3) * 4)) + size, ink) end end end
  for x = 2, 8 do dots(x, 21, 6 + (x % 3) * 2, S.crumb, 3) end
  for x = 17, 25 do dots(x, 24, 3, (x % 3 == 0) and S.egg or (x % 3 == 1) and S.larva or S.pupa, (x % 3 == 0) and 2 or 3) end
  for x = 10, 18 do if x ~= 14 then for k = 0, 2 do local bx, by = x * T + 3 + k * 5, 29 * T + 8; rect(bx, by - 3, 1, 4, hex('#f4ecd8')); rect(bx - 1, by - 5, 3, 2, hex(S.zones.garden)); put(bx, by - 6, hex('#f4ecd8')) end end end

  -- the ants: three body parts and six legs, turned the way they walk
  local function ant(cx, cy, dir, carry, kind)
    local s = kind == 'queen' and 2 or kind == 'major' and 1.4 or 1
    local col = hex(kind == 'queen' and S.queen or kind == 'major' and S.major or S.ant)
    local ox, oy = cx * T + T // 2 + math.floor((hash(cx * 7, cy * 3) - 0.5) * 6), cy * T + T // 2 + math.floor((hash(cx, cy * 11) - 0.5) * 4)
    local ux, uy = 0, 0; if dir == 1 then ux = 1 elseif dir == -1 then ux = -1 elseif dir == 2 then uy = 1 else uy = -1 end
    local function part(along, r) local bx, by = ox + ux * along * s, oy + uy * along * s; local rr = math.max(1, math.floor(r * s + 0.5))
      for j = -rr, rr do for i = -rr, rr do if i * i + j * j <= rr * rr + 1 then put(bx + i, by + j, col) end end end end
    part(-4, 1.6); part(0, 1); part(3, 1.2)
    for k = -1, 1 do local lx, ly = ox + ux * k * 2 * s, oy + uy * k * 2 * s                 -- legs to either side
      put(lx - uy * (2 + s), ly - ux * (2 + s), col); put(lx + uy * (2 + s), ly + ux * (2 + s), col)
      put(lx - uy * (3 + s) + ux, ly - ux * (3 + s) + uy, col); put(lx + uy * (3 + s) + ux, ly + ux * (3 + s) + uy, col) end
    put(ox + ux * (5 * s) - uy, oy + uy * (5 * s) - ux, col); put(ox + ux * (5 * s) + uy, oy + uy * (5 * s) + ux, col)   -- feelers
    if carry then local c = hex(carry == 'soil' and S.soil or carry == 'crumb' and S.crumb or S.egg); rect(ox + ux * 7 - 1, oy + uy * 7 - 1, 3, 3, c) end
  end
  for _, a in ipairs(ANTS) do ant(a[1], a[2], a[3], a[4], a[5]) end

  local Z = 2
  local big = Image(W * Z, H * Z, ColorMode.RGB)
  for y = 0, H - 1 do for x = 0, W - 1 do local c = img:getPixel(x, y); for j = 0, Z - 1 do for i = 0, Z - 1 do big:drawPixel(x * Z + i, y * Z + j, c) end end end end
  big:saveAs(out .. '/' .. S.id .. '.png')
end
for _, S in ipairs(STYLES) do draw(S) end
print('done')
