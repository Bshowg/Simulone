-- ground.lua: the ground textures for The Lord's Will.
--   Aseprite -b --script-param root=<path to art> --script <path to art>/ground.lua
-- Every texture is 128 x 128, opaque and tiles seamlessly in both directions. The game fills areas with them in SCREEN
-- space and shows them reduced and smoothed on big maps, so each is one colour with a faint unevenness (a second tone
-- about 3.5 percent darker, in large soft areas with dithered edges), like watercolour on paper, plus a few sparse marks. Lines along the isometric grid have slope 0.5 (2 across, 1 down) and rows of them are
-- 4, 8 or 16 pixels apart, so they meet themselves at the tile edge.
-- Output: art/out/ground/<name>.png and art/out/ground/preview.png (each texture 2 x 2, enlarged 2 times).
local root = app.params.root
local ink = dofile(root .. '/lib/ink.lua')
local P, hex, hash = ink.P, ink.hex, ink.hash
local OUT = root .. '/out/ground/'
local N = 128
local AREA = (N // 64) ^ 2                                     -- mark counts below are per 64 x 64

-- colours added for the ground (soft pastels in the family of ink.P)
local X = {
  grassSp = '#c9d8a4', grassSp2 = '#b9cb93',                  -- spring grass, fresher
  grassAu = '#d4cfa3', grassAu2 = '#c7c193',                  -- autumn grass, yellowed
  forSp = '#b3c691', forSp2 = '#a5b984',                      -- forest floors, deeper and shadier
  forSu = '#abbb8d', forSu2 = '#9dae81',
  forAu = '#c8bd90', forAu2 = '#baae82',
  forWi = '#e9e9e2', forWi2 = '#dcdedb',
  litter = '#b7a07a',                                         -- brown leaf litter
  deadGrass = '#c2b48e',                                      -- dead grass through snow
  ice = '#d7e0e2', ice2 = '#c9d5d9', iceLine = '#9aabb2',     -- winter ice
  slush = '#d6d6cc',                                          -- trodden slush
  shallow = '#bed4d4',                                        -- ford water over gravel
}

-- ── a texture: an N x N table of colours, every write wraps around the edges
local function tex() local t = { px = {} }; return t end
local function put(t, x, y, c) t.px[(y % N) * N + (x % N)] = c end
local function get(t, x, y) return t.px[(y % N) * N + (x % N)] end

-- periodic value noise: lattice of cx x cy pixels (both divide N), so it tiles
local function vnoise(x, y, cx, cy, seed)
  local nx, ny = N // cx, N // cy
  local gx, gy = x / cx, y / cy
  local ix, iy = math.floor(gx), math.floor(gy)
  local fx, fy = gx - ix, gy - iy
  fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
  local function v(i, j) return hash((i % nx) * 7 + seed * 131 + 3, (j % ny) * 13 + seed * 71 + 5) end
  local a = v(ix, iy) + (v(ix + 1, iy) - v(ix, iy)) * fx
  local b = v(ix, iy + 1) + (v(ix + 1, iy + 1) - v(ix, iy + 1)) * fx
  return a + (b - a) * fy
end
-- soft, isometrically flattened blotches (wider than tall)
local function blot(x, y, seed)
  return 0.3 * vnoise(x, y, 32, 16, seed) + 0.45 * vnoise(x, y, 16, 8, seed + 1) + 0.25 * vnoise(x, y, 8, 4, seed + 2)
end
-- the quiet wash: few, large, soft areas (no small islands)
local function soft(x, y, seed)
  return 0.6 * vnoise(x, y, 64, 32, seed) + 0.32 * vnoise(x, y, 32, 16, seed + 1) + 0.08 * vnoise(x, y, 16, 16, seed + 2)
end
local BAYER = { [0] = { [0] = 0, 8, 2, 10 }, { [0] = 12, 4, 14, 6 }, { [0] = 3, 11, 1, 9 }, { [0] = 15, 7, 13, 5 } }
local function bayer(x, y) return (BAYER[y % 4][x % 4] + 0.5) / 16 end

-- colour arithmetic: a tone f times as bright, and a mix of two colours
local function rgb(c) return tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16) end
local function shade(c, f) local r, g, b = rgb(c); return string.format('#%02x%02x%02x', math.min(255, math.floor(r * f + 0.5)), math.min(255, math.floor(g * f + 0.5)), math.min(255, math.floor(b * f + 0.5))) end
local function mix(a, b, k) local r1, g1, b1 = rgb(a); local r2, g2, b2 = rgb(b)
  return string.format('#%02x%02x%02x', math.floor(r1 + (r2 - r1) * k + 0.5), math.floor(g1 + (g2 - g1) * k + 0.5), math.floor(b1 + (b2 - b1) * k + 0.5)) end

-- the base: one colour, with large soft areas 3.5 percent darker; edges dithered so they melt
local function base(t, seed, c, cut)
  local d = shade(c, 0.965)
  cut = cut or 0.52
  for y = 0, N - 1 do for x = 0, N - 1 do
    put(t, x, y, soft(x, y, seed) + (bayer(x, y) - 0.5) * 0.07 > cut and d or c)
  end end
end
-- large soft patches of another (close) colour over the base, edges dithered
local function patches(t, seed, c, cut)
  for y = 0, N - 1 do for x = 0, N - 1 do
    if soft(x, y, seed) + (bayer(x, y) - 0.5) * 0.08 > cut then put(t, x, y, c) end
  end end
end

-- the base wash: tones = { c1, c2, c3? }, cut = thresholds on the noise
local function wash(t, seed, tones, cut)
  cut = cut or { 0.5, 0.62 }
  for y = 0, N - 1 do for x = 0, N - 1 do
    local n = blot(x, y, seed)
    local c = tones[1]
    if n > cut[1] then c = tones[2] end
    if tones[3] and n > cut[2] then c = tones[3] end
    put(t, x, y, c)
  end end
end

-- n scattered points, deterministic
local function scatter(n, seed, fn)
  for i = 1, math.floor(n * AREA) do fn(math.floor(hash(i * 7 + seed, seed * 3 + 1) * N), math.floor(hash(seed * 5 + 2, i * 11 + seed) * N), i) end
end

-- small marks
local function tuft(t, x, y, c)  put(t, x, y, c); put(t, x + 2, y, c); put(t, x + 1, y - 1, c) end
local function flower(t, x, y, c) put(t, x, y, c) end
local function pebble(t, x, y, c, edge) put(t, x, y, c); put(t, x + 1, y, c); put(t, x + 1, y + 1, edge); put(t, x, y + 1, edge) end
-- an isometric stroke: len pixels across at slope dir*0.5
local function iso(t, x, y, len, c, dir) dir = dir or 1; for i = 0, len - 1 do put(t, x + i, y + dir * (i // 2), c) end end

-- the row coordinate of a slope-0.5 line family: rows of pixels with (y - x//2) equal lie on one line
local function rowv(x, y) return y - (x % N) // 2 end
-- a row index that is the same on both sides of every seam (rows of spacing sp): N/2 rows of drop across the tile
local function rowid(x, y, sp) return (rowv(x, y) // sp) % ((N // 2) // sp) end

-- ── the textures
local T = {}
local order = {}
local function def(name, fn) order[#order + 1] = name; T[name] = fn end

local function grass(t, c1, c2, seed, flowers, nfl, tuftc, ntuft)
  base(t, seed, c1)
  scatter(ntuft, seed + 10, function(x, y) tuft(t, x, y, tuftc) end)
  scatter(nfl, seed + 20, function(x, y, i) flower(t, x, y, flowers[i % #flowers + 1]) end)
end

def('grass_summer', function(t) grass(t, P.grass, P.grass2, 1, { P.snow, P.weld, P.snow }, 9, P.green, 6) end)
def('grass_spring', function(t) grass(t, X.grassSp, X.grassSp2, 27, { P.snow, P.weld, P.veil, P.madder, P.woad }, 22, P.grass2, 5) end)
def('grass_autumn', function(t) grass(t, X.grassAu, X.grassAu2, 3, { P.russet, P.weld }, 6, P.russet, 7) end)
def('grass_winter', function(t)
  base(t, 4, P.snow)
  scatter(9, 40, function(x, y, i) tuft(t, x, y, i % 3 == 0 and P.russet or X.deadGrass); if i % 2 == 0 then put(t, x + 1, y, X.deadGrass) end end)
end)

def('forest_summer', function(t) grass(t, X.forSu, X.forSu2, 5, { P.leafShade }, 10, P.leafShade, 8)
  scatter(5, 51, function(x, y) put(t, x, y, P.russet) end) end)
def('forest_spring', function(t) grass(t, X.forSp, X.forSp2, 6, { P.snow, P.veil, P.leafShade }, 14, P.leafShade, 7) end)
def('forest_autumn', function(t)
  base(t, 7, X.forAu)
  local lc = { P.russet, P.weld, P.madder, X.litter, P.corn2 }
  scatter(46, 70, function(x, y, i) local c = lc[i % #lc + 1]; put(t, x, y, c); if i % 3 == 0 then put(t, x + 1, y, c) end end)
end)
def('forest_winter', function(t)
  base(t, 8, X.forWi)
  scatter(14, 80, function(x, y, i) put(t, x, y, X.litter); if i % 2 == 0 then put(t, x + 1, y, X.deadGrass) end end)
  scatter(5, 81, function(x, y) tuft(t, x, y, X.deadGrass) end)
end)

-- water: wave strokes at slope 0.5 on rows 8 apart, broken into short pieces, with paper glints
local function waves(t, seed, line, glint, rowsp, keep)
  for y = 0, N - 1 do for x = 0, N - 1 do
    local v = rowv(x, y) % rowsp
    local id = rowid(x, y, rowsp)
    local seg = (x % N) // 16
    local pos = x % 16
    local h = hash(seg * 5 + seed, id * 13 + seed)
    local off = math.floor(hash(id + seed, seg * 3 + 1) * 8)
    if v == 0 and h > keep and pos >= off and pos < off + 6 then put(t, x, y, line)
    elseif v == 1 and h > keep and pos >= off + 1 and pos < off + 4 then put(t, x, y, glint) end
  end end
end
def('water', function(t)
  base(t, 9, P.water)
  waves(t, 9, P.waterLine, P.road, 8, 0.6)
end)
def('water_winter', function(t)
  base(t, 10, X.ice)
  -- a few cracks: short jagged lines
  local function crack(x, y, steps, s)
    for k = 1, steps do
      local dx = hash(k, s) > 0.5 and 1 or 2
      local dy = hash(s, k) > 0.6 and 1 or (hash(k + 9, s) > 0.5 and 0 or -1)
      x = x + dx; y = y + dy; put(t, x, y, X.iceLine)
      if hash(k * 3, s + 1) > 0.88 then iso(t, x, y, 4, X.iceLine, -1) end
    end
  end
  crack(3, 12, 13, 1); crack(36, 40, 11, 2); crack(20, 55, 6, 3); crack(70, 20, 14, 4); crack(90, 84, 10, 5); crack(60, 110, 12, 6); crack(8, 90, 9, 7)
  scatter(10, 101, function(x, y) put(t, x, y, P.snow); put(t, x + 1, y, P.snow) end)
end)
def('ford', function(t)
  base(t, 11, X.shallow); patches(t, 12, mix(X.shallow, P.road2, 0.3), 0.6)
  scatter(28, 110, function(x, y, i) put(t, x, y, i % 2 == 0 and P.earth2 or P.stoneShade) end)
  scatter(9, 111, function(x, y) pebble(t, x, y, P.stone, P.stoneShadeLine) end)
  waves(t, 11, P.waterLine, P.road, 16, 0.55)
end)

-- road: trodden earth, a few pebbles, faint ruts at slope 0.5 (two lines 3 apart in each 16-pixel band)
local function ruts(t, c, seed, edge)
  for y = 0, N - 1 do for x = 0, N - 1 do
    local v = rowv(x, y) % 16
    if v == 5 or v == 8 then
      local seg = (x % N) // 16
      if hash(seg + seed, rowid(x, y, 16) * 5 + seed) > 0.25 and hash(x % N, (y + seed) % N) > 0.15 then
        put(t, x, y, c)
        if edge then put(t, x, y - 1, edge) end
      end
    end
  end end
end
def('road', function(t)
  base(t, 12, P.road)
  ruts(t, P.earth, 12)
  scatter(7, 120, function(x, y) pebble(t, x, y, P.stoneShade, P.stoneShadeLine) end)
  scatter(10, 121, function(x, y) put(t, x, y, P.earth2) end)
end)
def('road_winter', function(t)
  base(t, 13, mix(P.snowShade, X.slush, 0.5))
  for y = 0, N - 1 do for x = 0, N - 1 do
    local v = rowv(x, y) % 16
    local seg = (x % N) // 16
    local keep = hash(seg + 13, rowid(x, y, 16) * 5 + 13) > 0.2
    if (v == 5 or v == 8) and keep then put(t, x, y, hash(x % N, y % N) > 0.3 and P.road2 or P.earth2)
    elseif (v == 6 or v == 7) and keep then put(t, x, y, X.slush)
    elseif (v == 4 or v == 9) and keep then if hash(x % N, y % N) > 0.3 then put(t, x, y, P.snow) end end
  end end
  scatter(4, 130, function(x, y) pebble(t, x, y, P.stoneShade, P.stoneShadeLine) end)
end)
def('earth', function(t)
  base(t, 14, mix(P.earth, P.road2, 0.4))
  scatter(6, 140, function(x, y) pebble(t, x, y, P.stoneShade, P.stoneShadeLine) end)
  scatter(12, 141, function(x, y) put(t, x, y, P.earth2) end)
end)

-- fields: rows at slope 0.5, 8 pixels apart; v = position across the row (0..7). Each row is wobbled up or down by a
-- pixel in 4-pixel pieces (the wobble repeats across the seams), so the rows look ploughed by hand.
local function rows(t, seed, fn)
  for y = 0, N - 1 do for x = 0, N - 1 do
    local id = rowid(x, y, 8)
    local w = hash((x % N) // 4 + seed, id * 3 + seed) > 0.7 and 1 or 0
    fn(x, y, (rowv(x, y) - w) % 8, hash(x % N, (y + seed) % N))
  end end
end
def('field_fallow', function(t)                                 -- bare ploughed earth: dark furrows, broad ridges
  wash(t, 15, { P.earth, P.earth2 }, { 0.58 })
  rows(t, 15, function(x, y, v, h)
    if v == 7 then put(t, x, y, h > 0.15 and P.furrow or P.earth2)
    elseif v == 6 or v == 0 then put(t, x, y, P.earth2)
    elseif v == 3 and h > 0.93 then put(t, x, y, P.stoneShade) end
  end)
end)
def('field_sown', function(t)                                   -- furrows, paler earth, the first green specks
  wash(t, 16, { P.earth, P.road2 }, { 0.7 })
  rows(t, 16, function(x, y, v, h)
    if v == 7 then put(t, x, y, h > 0.45 and P.earth2 or P.furrow)
    elseif v == 6 then put(t, x, y, P.earth2)
    elseif (v == 4 or v == 3 or v == 2) and h > 0.6 then put(t, x, y, v == 3 and P.green or P.leaf)
    elseif v == 1 and h > 0.85 then put(t, x, y, P.green) end
  end)
end)
def('field_growing', function(t)                                -- rows of green blades with earth between
  wash(t, 17, { P.leaf, P.grass2 }, { 0.55 })
  rows(t, 17, function(x, y, v, h)
    if v == 7 then put(t, x, y, h > 0.3 and P.earth or P.earth2)
    elseif v == 6 then put(t, x, y, h > 0.6 and P.earth or P.leafShade)
    elseif v == 5 then if x % 2 == 0 then put(t, x, y, P.green) end
    elseif v == 1 and x % 3 == 0 and h > 0.4 then put(t, x, y, P.green) end
  end)
end)
def('field_ripe', function(t)                                   -- the approved gold corn: wavy strokes in rows
  wash(t, 18, { P.corn, P.corn2 }, { 0.5 })
  rows(t, 18, function(x, y, v, h)
    if v == 7 then put(t, x, y, h > 0.35 and P.furrow or P.cornLine)
    elseif v == 6 then put(t, x, y, P.cornLine)
    elseif v == 3 and h > 0.55 then put(t, x, y, P.cornLine) end
  end)
end)
def('field_stubble', function(t)                                -- pale stubble ticks in rows, earth showing
  wash(t, 19, { P.corn, P.road }, { 0.5 })
  rows(t, 19, function(x, y, v, h)
    if v == 7 then put(t, x, y, h > 0.25 and P.earth2 or P.earth)
    elseif v == 6 or v == 0 then put(t, x, y, P.earth)
    elseif v == 4 and x % 2 == 0 then put(t, x, y, P.cornLine); put(t, x, y - 1, P.corn)
    elseif v == 1 and x % 2 == 1 and h > 0.3 then put(t, x, y, P.corn2) end
  end)
end)

def('garden', function(t)                                     -- beds of cabbages and beans in rows, dark earth between
  wash(t, 26, { P.earth2, P.earth }, { 0.6 })
  rows(t, 26, function(x, y, v, h)
    if v == 7 then put(t, x, y, P.furrow)
    elseif v == 3 and x % 6 == 0 then                            -- a cabbage: a round head of leaves, shaded on its lower right
      put(t, x, y - 1, P.leaf); put(t, x + 1, y - 1, P.leaf); put(t, x - 1, y, P.leaf); put(t, x, y, P.green); put(t, x + 1, y, P.green)
      put(t, x + 2, y, P.leafShade); put(t, x, y + 1, P.leafShade); put(t, x + 1, y + 1, P.leafShade)
    elseif v == 5 and x % 4 == 1 and h > 0.25 then put(t, x, y, P.green); put(t, x, y - 1, P.leafShade)   -- a row of beans
    end
  end)
end)
def('green', function(t)                                        -- grass worn to earth in a few soft patches
  base(t, 20, P.grass)
  patches(t, 21, mix(P.grass, P.road2, 0.2), 0.58)
  patches(t, 21, mix(P.grass, P.road2, 0.3), 0.68)
  scatter(5, 200, function(x, y) tuft(t, x, y, P.green) end)
  scatter(5, 201, function(x, y) flower(t, x, y, P.snow) end)
end)
def('market', function(t)                                       -- packed earth, a few irregular cobbled patches
  base(t, 22, P.road)
  patches(t, 23, mix(P.road, P.earth, 0.4), 0.62)
  local spots = { { 22, 18, 10 }, { 84, 40, 13 }, { 40, 86, 8 }, { 104, 104, 9 }, { 70, 120, 6 } }
  for si, sp in ipairs(spots) do
    local rx = sp[3]
    for cy = -rx, rx, 3 do for cx = -2 * rx, 2 * rx, 4 do
      local x, y = sp[1] + cx + ((cy // 3) % 2) * 2, sp[2] + cy
      local d = (cx / (2 * rx)) ^ 2 + (cy / rx) ^ 2 + (hash(x % N + si, y % N) - 0.5) * 0.5
      if d < 1 and hash(x % N, y % N + si * 7) > 0.15 then
        put(t, x, y, P.stone); put(t, x + 1, y, P.stone); put(t, x + 2, y, P.stoneShade)
        put(t, x, y + 1, P.stoneShade); put(t, x + 1, y + 1, P.stoneShade); put(t, x + 2, y + 1, P.stoneLine)
      end
    end end
  end
  scatter(5, 220, function(x, y) put(t, x, y, P.earth2) end)
end)
def('fairground', function(t)                                   -- trodden grass with straw
  base(t, 24, mix(P.grass, P.grass2, 0.5))
  patches(t, 25, mix(P.grass2, P.road2, 0.3), 0.62)
  scatter(18, 240, function(x, y, i)
    local c = i % 3 == 0 and P.cornLine or P.corn
    if i % 2 == 0 then put(t, x, y, c); put(t, x + 1, y, c); put(t, x + 2, y + 1, c)
    else put(t, x, y, c); put(t, x + 1, y - 1, c) end
  end)
end)
def('snow', function(t)
  base(t, 25, P.snow)
  scatter(4, 250, function(x, y) put(t, x, y, P.snowShade); put(t, x + 1, y, P.snowShade) end)
end)

-- ── render
local function toImage(t)
  local img = Image(N, N, ColorMode.RGB)
  for y = 0, N - 1 do for x = 0, N - 1 do img:drawPixel(x, y, hex(get(t, x, y) or '#ff00ff')) end end
  return img
end

local imgs = {}
for _, name in ipairs(order) do
  local t = tex(); T[name](t)
  local img = toImage(t)
  img:saveAs(OUT .. name .. '.png')
  imgs[#imgs + 1] = img
end

-- preview: each texture 2 x 2 (256 x 256), on paper, in a grid, enlarged 2 times
local cols, gap = 6, 8
local cw = 2 * N + gap
local rowsN = math.ceil(#imgs / cols)
local W, H = cols * cw + gap, rowsN * cw + gap
local sheet = Image(W, H, ColorMode.RGB)
local pa = hex(P.paper)
for y = 0, H - 1 do for x = 0, W - 1 do sheet:drawPixel(x, y, pa) end end
for i, img in ipairs(imgs) do
  local ox, oy = gap + ((i - 1) % cols) * cw, gap + ((i - 1) // cols) * cw
  for y = 0, 2 * N - 1 do for x = 0, 2 * N - 1 do sheet:drawPixel(ox + x, oy + y, img:getPixel(x % N, y % N)) end end
end
local s = 2
local big = Image(W * s, H * s, ColorMode.RGB)
for y = 0, H - 1 do for x = 0, W - 1 do local c = sheet:getPixel(x, y); for j = 0, s - 1 do for i = 0, s - 1 do big:drawPixel(x * s + i, y * s + j, c) end end end end
big:saveAs(OUT .. 'preview.png')
if app.params.small then sheet:saveAs(app.params.small) end
print('ok ground ' .. #imgs .. ' textures')
