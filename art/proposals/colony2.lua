-- Second round for The Colony: low resolution, drawn as true to life as the pixels allow. Nothing here is
-- taken from The Lord's Will. The same slice of nest three ways: real soil at 8 pixels a cell, the same at
-- 12 pixels a cell, and an ant farm between glass at 8.
--   Aseprite -b --script-param out=<folder> --script colony2.lua
local out = app.params.out or '.'
local pc = app.pixelColor
local CW, CH, SURF = 28, 34, 5

local function rgb(s) return tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16) end
local function col(r, g, b) return pc.rgba(math.max(0, math.min(255, math.floor(r))), math.max(0, math.min(255, math.floor(g))), math.max(0, math.min(255, math.floor(b))), 255) end
local function hex(s, f) local r, g, b = rgb(s); f = f or 1; return col(r * f, g * f, b * f) end
local function hash(x, y)
  local n = (math.floor(x) * 374761393 + math.floor(y) * 668265263) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  return ((n ~ (n >> 16)) % 1000) / 1000
end
local function smooth(x, y, s, seed) local gx, gy = x / s, y / s; local x0, y0 = math.floor(gx), math.floor(gy); local fx, fy = gx - x0, gy - y0
  fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
  local a, b, c, d = hash(x0 + seed, y0), hash(x0 + 1 + seed, y0), hash(x0 + seed, y0 + 1), hash(x0 + 1 + seed, y0 + 1)
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy end
local function ramp(r, t) local i = math.floor(t * #r) + 1; if i < 1 then i = 1 elseif i > #r then i = #r end; return r[i] end

-- ── the slice of nest (cells)
local map = {}
for y = 0, CH - 1 do map[y] = {}
  for x = 0, CW - 1 do
    local k = 'loam'
    if y < SURF then k = 'sky' elseif y == SURF then k = 'air'
    elseif smooth(x, y, 3, 40) > 0.76 then k = 'stone'
    elseif smooth(x, y, 6, 7) > 0.62 and y > 14 then k = 'clay'
    elseif smooth(x, y, 5, 90) > 0.6 and y < 18 then k = 'sand' end
    map[y][x] = k
  end
end
local function dig(x0, y0, x1, y1) for y = y0, y1 do for x = x0, x1 do map[y][x] = 'open' end end end
dig(14, 6, 14, 12); dig(10, 12, 18, 14); dig(18, 13, 24, 13); dig(22, 13, 22, 22); dig(17, 22, 25, 24)
dig(4, 13, 10, 13); dig(5, 13, 5, 19); dig(2, 19, 8, 21); dig(14, 14, 14, 28); dig(10, 28, 18, 30); dig(14, 31, 14, 32)
for _, c in ipairs({ { 14, 31 }, { 14, 32 }, { 13, 30 }, { 14, 30 }, { 15, 30 } }) do map[c[2]][c[1]] = 'water' end
local function kind(x, y) return (map[y] and map[y][x]) or 'loam' end
local function hollow(x, y) local k = kind(x, y); return k == 'open' or k == 'water' end
local function earth(x, y) local k = kind(x, y); return k ~= 'open' and k ~= 'water' and k ~= 'air' and k ~= 'sky' end

local ANTS = { { 14, 7, -2, 'soil' }, { 14, 9, 2 }, { 14, 11, -2, 'soil' }, { 11, 13, 1 }, { 12, 14, -1, 'crumb' }, { 16, 12, 1 }, { 17, 14, -1 }, { 20, 13, 1, 'egg' }, { 23, 13, -1 },
  { 22, 16, 2, 'egg' }, { 22, 19, -2 }, { 19, 23, 1 }, { 21, 22, -1 }, { 24, 24, -1 }, { 7, 13, -1, 'crumb' }, { 5, 15, 2, 'crumb' }, { 5, 18, -2 },
  { 4, 20, 1 }, { 7, 21, -1 }, { 14, 17, 2 }, { 14, 21, -2 }, { 14, 25, 2 }, { 12, 29, 1 }, { 16, 28, -1 }, { 17, 29, -1 }, { 9, 5, 1, 'crumb' }, { 6, 5, 1 }, { 20, 5, -1 }, { 24, 5, -1, 'crumb' },
  { 14, 13, 1, nil, 'queen' }, { 12, 12, 1, nil, 'major' }, { 15, 6, 2, nil, 'major' } }

local STYLES = {
  { id = '1-soil-8px', T = 8, Z = 4,
    sky = { '#86b2d6', '#9cc2de', '#b4d2e4', '#cfe2e8' }, humus = { '#33241a', '#3d2b1e', '#463222' },
    loam = { '#5e4029', '#69482e', '#735034', '#7e593a' }, sand = { '#a98852', '#b4935c', '#c0a068', '#ccad76' }, clay = { '#6d5448', '#775c4e', '#836656', '#7b7d84' },
    stone = { '#4e4a46', '#6a655f', '#888279', '#a8a298' }, grass = { '#35602a', '#467a33', '#5f953c', '#7fae4a' }, root = { '#8a7150', '#bca27c' },
    back = 0.66, ant = { '#120806', '#2c140c', '#7a3c22' }, queen = { '#1a0a06', '#40180c', '#964a26' }, water = { '#1f3a4a', '#2c5468', '#7aa8b8' },
    crumb = { '#c8a04a', '#e6c46a' }, egg = '#f4f0e4', larva = '#e8d8b4', pupa = '#c2a070', fungus = { '#d8d6cc', '#f0eee6', '#6f8a4a' }, dry = 1.25 },
  { id = '2-soil-12px', T = 12, Z = 3 },
  { id = '3-ant-farm-8px', T = 8, Z = 4, glass = true,
    sky = { '#cfcabd', '#d6d1c4', '#dcd8cc', '#e2ded2' }, humus = { '#b79a6a', '#c0a474', '#c9ae7e' },
    loam = { '#c4a878', '#cdb282', '#d6bc8e', '#dfc79a' }, sand = { '#dccba4', '#e4d4ae', '#ecddb8', '#f2e6c4' }, clay = { '#b48e74', '#bd977c', '#c7a186', '#a89a94' },
    stone = { '#55504c', '#6e6862', '#8a847c', '#a8a299' }, grass = { '#6a7a4a', '#7c8c56', '#909f66', '#a6b47a' }, root = { '#9a8462', '#c2ad88' },
    back = 0.62, ant = { '#0e0a09', '#221612', '#4a3024' }, queen = { '#120b08', '#30180e', '#603a26' }, water = { '#5a7c8c', '#7498a6', '#b8d2da' },
    crumb = { '#a87c2e', '#cfa246' }, egg = '#ffffff', larva = '#f4e8c8', pupa = '#b08a58', fungus = { '#eeece4', '#ffffff', '#7a9456' }, dry = 1.08 },
}
for k, v in pairs(STYLES[1]) do if STYLES[2][k] == nil then STYLES[2][k] = v end end

local function draw(S)
  local T = S.T
  local W, H = CW * T, CH * T
  local s = T / 8                                            -- everything drawn is scaled from the 8-pixel cell
  local img = Image(W, H, ColorMode.RGB)
  local function put(x, y, c) x, y = math.floor(x + 0.5), math.floor(y + 0.5); if x >= 0 and y >= 0 and x < W and y < H then img:drawPixel(x, y, c) end end

  -- the colour of the earth at a pixel: grain at two sizes, a little darker with depth, each kind its own look
  local function soil(k, px, py)
    local depth = 1 - math.min(0.22, (py / H) * 0.26)
    local n = hash(px, py) * 0.45 + smooth(px, py, 3 * s, 3) * 0.35 + smooth(px, py, 9 * s, 17) * 0.2
    if k == 'stone' then                                       -- pebbles bedded in loam: round, lit from the upper left
      local cx, cy = px // T, py // T
      local ox, oy = (cx + 0.5 + (hash(cx, cy) - 0.5) * 0.3) * T, (cy + 0.5 + (hash(cy, cx) - 0.5) * 0.3) * T
      local r = T * (0.42 + hash(cx * 3, cy * 5) * 0.12)
      local dx, dy = px + 0.5 - ox, (py + 0.5 - oy) * 1.2
      if dx * dx + dy * dy <= r * r then
        local lit = 0.5 - (dx + dy) / (r * 2.6) + (hash(px, py) - 0.5) * 0.2
        return hex(ramp(S.stone, lit), depth)
      end
      k = 'loam'
    end
    if k == 'loam' and py < (SURF + 2.2) * T + smooth(px, 0, 5 * s, 9) * T * 0.8 then return hex(ramp(S.humus, n), depth) end   -- dark topsoil
    if k == 'clay' then
      if (py + math.floor(smooth(px, py, 7 * s, 5) * 3 * s)) % math.floor(4 * s) == 0 and hash(px // math.floor(5 * s), py) > 0.35 then return hex(S.clay[4], depth * 0.9) end   -- grey seams
      return hex(ramp({ S.clay[1], S.clay[2], S.clay[3] }, n), depth)
    end
    if k == 'sand' then local c = ramp(S.sand, n); if hash(px * 7, py * 3) > 0.94 then c = S.sand[4] elseif hash(px * 3, py * 9) > 0.95 then c = S.loam[2] end; return hex(c, depth) end
    local c = ramp(S.loam, n); if hash(px * 5, py * 11) > 0.965 then c = S.sand[2] end                 -- a grain of grit
    return hex(c, depth)
  end

  for py = 0, H - 1 do for px = 0, W - 1 do
    local cx, cy = px // T, py // T
    local k = kind(cx, cy)
    local lx, ly = px % T, py % T
    -- the edge between earth and hollow is rough, never the straight side of a cell
    local open = hollow(cx, cy)
    local bite = math.floor(hash(px // math.max(1, math.floor(s)), py // math.max(1, math.floor(s))) * 2.4 * s)
    if not open and k ~= 'sky' and k ~= 'air' then
      if (hollow(cx - 1, cy) and lx < bite) or (hollow(cx + 1, cy) and T - 1 - lx < bite) or (hollow(cx, cy - 1) and ly < bite) or (hollow(cx, cy + 1) and T - 1 - ly < bite) then open = true end
    end
    local c
    if k == 'sky' or (k == 'air' and not open) then
      c = hex(ramp(S.sky, py / ((SURF + 1) * T) + (hash(px, py) - 0.5) * 0.08))
    elseif open then
      -- inside the nest: the back wall of the tunnel, in shade; darkest under the roof, a lit edge along the floor
      local behind = (k == 'open' or k == 'water') and 'loam' or k
      local roof = earth(cx, cy - 1) and ly < 2.5 * s
      local floor = earth(cx, cy + 1) and ly >= T - 1.2 * s
      local f = S.back * (roof and 0.72 or 1) * (0.92 + smooth(px, py, 4 * s, 23) * 0.16)
      local r, g, b = rgb(ramp(S[behind] or S.loam, hash(px, py) * 0.5 + smooth(px, py, 3 * s, 3) * 0.5))
      if floor then f = f * 1.45 end
      c = col(r * f, g * f * 0.97, b * f * 0.94)
      if kind(cx, cy) == 'water' then                          -- standing water: dark, with the light on its surface
        local top = kind(cx, cy - 1) ~= 'water' and ly < 1.4 * s
        local wr, wg, wb = rgb(top and S.water[3] or ramp({ S.water[1], S.water[2] }, hash(px // 2, py) * 0.9))
        c = col(pc.rgbaR(c) * 0.35 + wr * 0.65, pc.rgbaG(c) * 0.35 + wg * 0.65, pc.rgbaB(c) * 0.35 + wb * 0.65)
      end
    else
      c = soil(k, px, py)
      -- earth right against a hollow catches a little light on the side that faces up
      if hollow(cx, cy - 1) and ly < 1.2 * s then c = col(pc.rgbaR(c) * 1.18, pc.rgbaG(c) * 1.16, pc.rgbaB(c) * 1.12) end
    end
    img:drawPixel(px, py, c)
  end end

  local gy = (SURF + 1) * T - 1
  -- roots hanging down from the grass
  for k = 0, 9 do
    local x, y, len = math.floor(hash(k, 77) * W), gy + 1, math.floor((1.5 + hash(k, 5) * 3.5) * T)
    for i = 0, len do
      x = x + (hash(k * 13, i) > 0.72 and 1 or hash(k * 13, i) < 0.28 and -1 or 0)
      local cx, cy = x // T, (y + i) // T
      if earth(cx, cy) then put(x, y + i, hex(S.root[i < len * 0.5 and 2 or 1])) end
    end
  end
  -- the mound: dried soil thrown out round the hole, lighter than the earth below
  for px = 10 * T, 19 * T do
    local d = math.abs(px - 14.5 * T) / T
    if d > 0.6 then local h = math.floor(math.max(0, 2.1 - d * 0.5) * T * 0.75 + hash(px, 1) * 1.5 * s)
      for j = 0, h do put(px, gy - j, hex(ramp(S.loam, hash(px, j) * 0.9), S.dry * (0.9 + (j / (h + 1)) * 0.2))) end end
  end
  -- grass: blades of uneven height, lighter at the tip
  for px = 0, W - 1 do
    local d = math.abs(px - 14.5 * T) / T
    if hash(px, 3) > 0.3 and d > 2.6 then local h = math.floor((0.25 + hash(px, 5) * 0.55) * T)
      for j = 0, h do put(px + (j > h * 0.6 and (hash(px, 9) > 0.5 and 1 or -1) or 0), gy - j, hex(ramp(S.grass, j / (h + 1) + hash(px, j) * 0.2))) end end
  end
  local function grains(x0, y0, n, wide, cols, size)           -- a heap of small things lying on a floor
    for k = 0, n - 1 do local gx = x0 + hash(k, x0) * wide; local up = math.floor(hash(k * 3, y0) * hash(k, 9) * n * 0.16 * s)
      for j = 0, size - 1 do for i = 0, size - 1 do put(gx + i, y0 - up - j, hex(cols[(k + i + j) % #cols + 1])) end end end
  end
  grains(4 * T, gy, 14, T * 1.6, S.crumb, math.max(1, math.floor(s)))
  -- the stores: seeds heaped in the food room, brood laid out in the brood room, fungus in the garden
  grains(2 * T + 2, 22 * T - 1, 90, 6.6 * T, S.crumb, math.max(1, math.floor(s)))
  local function oval(x, y, w, h, c) for j = 0, h - 1 do for i = 0, w - 1 do if not ((i == 0 or i == w - 1) and (j == 0 or j == h - 1) and w > 2) then put(x + i, y + j, c) end end end end
  for k = 0, 33 do local x = 17 * T + 2 + k * (8.6 * T / 34); local t = k % 3
    if t == 0 then oval(x, 25 * T - 1 - math.floor(s), math.max(1, math.floor(s)), math.max(1, math.floor(s)), hex(S.egg))
    elseif t == 1 then oval(x, 25 * T - 1 - math.floor(1.6 * s), math.floor(2.4 * s), math.floor(1.6 * s), hex(S.larva))
    else oval(x, 25 * T - 1 - math.floor(2 * s), math.floor(2.6 * s), math.floor(2 * s), hex(S.pupa)) end end
  for px = 10 * T + 2, 19 * T - 3 do if math.abs(px - 14.5 * T) > T * 1.6 then
    local h = math.floor((0.25 + smooth(px, 0, 2.5 * s, 51) * 0.5) * T)
    for j = 0, h do local c = hash(px, j * 7) > 0.9 and S.fungus[3] or ramp({ S.fungus[1], S.fungus[2] }, j / (h + 1) + hash(px, j) * 0.3); put(px, 30 * T - 1 - j + (T - 1) * 0, hex(c)) end end end

  -- an ant: head, thorax, a larger abdomen with the light on its back, feelers, six legs
  local function ant(cx, cy, dir, carry, who)
    local P = who == 'queen' and S.queen or S.ant
    local m = (who == 'queen' and 1.9 or who == 'major' and 1.35 or 1) * s
    local ox = cx * T + T / 2 + (hash(cx * 7, cy * 3) - 0.5) * T * 0.3
    local oy = (dir == 1 or dir == -1) and ((cy + 1) * T - 1 - 1.6 * m) or (cy * T + T / 2)       -- walking along a floor, or up a shaft
    local ux, uy, vx, vy = 0, 0, 0, 0
    if dir == 1 then ux, vy = 1, -1 elseif dir == -1 then ux, vy = -1, -1 elseif dir == 2 then uy, vx = 1, 1 else uy, vx = -1, 1 end
    local function blob(along, rx, ry, c1, c2)
      for j = -math.ceil(ry), math.ceil(ry) do for i = -math.ceil(rx), math.ceil(rx) do
        if (i * i) / (rx * rx + 0.3) + (j * j) / (ry * ry + 0.3) <= 1 then
          local bx, by = ox + ux * (along * m + i) + vx * j, oy + uy * (along * m + i) + vy * j
          put(bx, by, hex(j > 0 and c2 or c1))                 -- j > 0 is the back, towards the light
        end end end
    end
    for k = -1, 1 do                                           -- legs first, so the body covers where they join
      local lx, ly = ox + ux * (k * 1.3 * m), oy + uy * (k * 1.3 * m)
      for t = 1, math.max(1, math.floor(1.4 * m)) do put(lx - vx * t + ux * (k * 0.4 * t), ly - vy * t + uy * (k * 0.4 * t), hex(P[1])) end
    end
    blob(-2.3, 1.5 * m, 0.95 * m, P[2], P[3])                  -- abdomen
    blob(0.1, 0.8 * m, 0.55 * m, P[1], P[2])                   -- thorax
    blob(1.9, (who == 'major' and 1.1 or 0.8) * m, (who == 'major' and 0.9 or 0.65) * m, P[1], P[2])   -- head
    put(ox + ux * (3.2 * m) + vx, oy + uy * (3.2 * m) + vy, hex(P[1])); put(ox + ux * (3.6 * m) + vx * 2, oy + uy * (3.6 * m) + vy * 2, hex(P[1]))
    if carry then local c = carry == 'soil' and hex(ramp(S.loam, 0.6), S.dry) or carry == 'crumb' and hex(S.crumb[2]) or hex(S.egg)
      for j = 0, math.max(1, math.floor(s)) do for i = 0, math.max(1, math.floor(s)) do put(ox + ux * (3.4 * m) + i - vx, oy + uy * (3.4 * m) + j - vy, c) end end end
  end
  for _, a in ipairs(ANTS) do ant(a[1], a[2], a[3], a[4], a[5]) end

  if S.glass then                                              -- the sheet of glass in front: two faint streaks of glare
    for py = 0, H - 1 do for px = 0, W - 1 do local d = (px + py * 0.6) % (W * 0.9)
      if (d > 40 and d < 52) or (d > 60 and d < 64) then local c = img:getPixel(px, py); img:drawPixel(px, py, col(pc.rgbaR(c) * 0.9 + 26, pc.rgbaG(c) * 0.9 + 26, pc.rgbaB(c) * 0.9 + 26)) end end end
  end

  local Z = S.Z
  local big = Image(W * Z, H * Z, ColorMode.RGB)
  for y = 0, H - 1 do for x = 0, W - 1 do local c = img:getPixel(x, y); for j = 0, Z - 1 do for i = 0, Z - 1 do big:drawPixel(x * Z + i, y * Z + j, c) end end end end
  big:saveAs(out .. '/' .. S.id .. '.png')
end
for _, S in ipairs(STYLES) do draw(S) end
print('done')
