-- The Colony: the ground. Soil textures, pebbles, grass, roots, skies and water, drawn to match the approved
-- picture art/proposals/colony2/2-soil-12px.png (style 1 of art/proposals/colony2.lua at 12 pixels a cell).
--   Aseprite -b --script-param root=<project folder> --script art/colony/ground.lua
local px = dofile(app.params.root .. '/art/colony/lib/px.lua')
local pc = app.pixelColor
local P = px.PAL
local OUT = 'art/colony/out/ground/'
local N = 48                                                   -- textures repeat every 48 x 48

local function hx(x, y) return px.hashp(x, y, N, N) end
-- a second, independent hash that still tiles: wrap first, then scramble
local function hx2(x, y, a, b) return px.hash(math.floor(px.hash(x % N, y % N) * 99991) + a * 7919, b * 104729 + (x % N) * 31 + (y % N)) end
local function sm(x, y, size, seed) return px.smooth(x, y, size, seed, N, N) end
-- grain at two sizes, as in the approved picture (fine grain, clumps about 4 px, broad patches about 12 px)
local function grain(x, y, seed)
  seed = seed or 0
  return hx(x + seed * 13, y + seed * 29) * 0.45 + sm(x, y, 4, 3 + seed) * 0.35 + sm(x, y, 12, 17 + seed) * 0.2
end
local function scale(c, f) return px.col(pc.rgbaR(c) * f, pc.rgbaG(c) * f, pc.rgbaB(c) * f) end

local saved = {}
local function save(img, name, tile) px.save(img, OUT .. name); saved[#saved + 1] = { img, tile = tile, name = name } end

-- ── soil textures, 48 x 48, tiling ─────────────────────────────────────────────────────────────────────────────
local function texture(f) local img = px.image(N, N); px.fill(img, f); return img end

save(texture(function(x, y)                                    -- loam: the body of the earth, an occasional grain of grit
  local c = px.ramp(P.loam, grain(x, y))
  if hx2(x, y, 5, 11) > 0.965 then c = P.sand[2] end
  return px.hex(c)
end), 'loam.png', true)

save(texture(function(x, y)                                    -- topsoil: the darkest, fine and even
  local c = px.ramp(P.humus, grain(x, y, 2))
  if hx2(x, y, 9, 4) > 0.985 then c = P.loam[1] end            -- a rare paler fleck of mineral soil
  return px.hex(c)
end), 'humus.png', true)

save(texture(function(x, y)                                    -- sand: speckled with a few pale and dark grains
  local c = px.ramp(P.sand, grain(x, y, 4))
  if hx2(x, y, 7, 3) > 0.94 then c = P.sand[4]
  elseif hx2(x, y, 3, 9) > 0.95 then c = P.loam[2] end
  return px.hex(c)
end), 'sand.png', true)

save(texture(function(x, y)                                    -- clay: dense, with thin grey seams laid down in layers
  local off = math.floor(sm(x, y, 12, 5) * 4)                  -- seams wander up and down a little
  if (y + off) % 6 == 0 and px.hashp(x // 6, y, 8, N) > 0.35 then return px.hex(P.claySeam, 0.9) end
  return px.hex(px.ramp(P.clay, grain(x, y, 6)))
end), 'clay.png', true)

save(texture(function(x, y)                                    -- plug: loam packed by the ants, a little lighter and more even
  local n = 0.5 + (grain(x, y, 8) - 0.5) * 0.55
  local c = px.ramp({ P.loam[2], P.loam[3], P.loam[4] }, n)
  if hx2(x, y, 5, 11) > 0.985 then c = P.sand[2] end
  return px.hex(c, 1.05)
end), 'plug.png', true)

do                                                             -- mound: dried loam thrown out, crumbly: small clods lit from the upper left
  local img = texture(function(x, y)
    local c = px.ramp(P.loam, grain(x, y, 10) * 0.85)
    return px.hex(c, P.dry * 0.96)
  end)
  local function wput(x, y, c) px.put(img, x % N, y % N, c) end
  for k = 0, 70 do                                             -- clods, wrapping round the edges so the tile still repeats
    local cx, cy = math.floor(px.hash(k, 501) * N), math.floor(px.hash(k, 502) * N)
    local r = px.hash(k, 503) > 0.7 and 2 or 1
    for j = -r, r do for i = -r, r do
      if i * i + j * j <= r * r + (px.hash(k + i, j + 9) > 0.5 and 1 or 0) then
        local t = 0.62 - (i + j) * 0.22 + (px.hash(cx + i, cy + j) - 0.5) * 0.3
        wput(cx + i, cy + j, px.hex(px.ramp(P.loam, t), P.dry))
      end
    end end
    wput(cx + r, cy + r + 1, px.hex(P.loam[1], P.dry * 0.8))     -- the crack under the clod, away from the light
    if px.hash(k, 504) > 0.4 then wput(cx + r + 1, cy + r, px.hex(P.loam[1], P.dry * 0.8)) end
  end
  for y = 0, N - 1 do for x = 0, N - 1 do                      -- a few loose crumbs and pores
    if hx2(x, y, 3, 5) > 0.975 then px.put(img, x, y, px.hex(P.loam[1], P.dry * 0.78)) end
    if hx2(x, y, 8, 2) > 0.98 then px.put(img, x, y, px.hex(P.loam[4], P.dry * 1.06)) end
  end end
  save(img, 'mound.png', true)
end

-- ── pebbles, 12 x 12, transparent ───────────────────────────────────────────────────────────────────────────────
-- A pebble: an irregular rounded outline (radius wobbling with the angle), lit from the upper left.
local function pebble(img, cx, cy, rx, ry, seed, tilt)
  tilt = tilt or 0
  local R = math.ceil(math.max(rx, ry)) + 2
  for j = -R, R do for i = -R, R do
    local x, y = cx + i, cy + j
    local dx, dy = (i + 0.5 - (cx % 1)), (j + 0.5 - (cy % 1))
    -- rotate a little so not every pebble sits square
    local ax = dx * math.cos(tilt) + dy * math.sin(tilt)
    local ay = -dx * math.sin(tilt) + dy * math.cos(tilt)
    local ang = math.atan(ay, ax)
    local wob = 1 + (px.hash(math.floor((ang + 3.2) * 1.6), seed) - 0.5) * 0.22
    local d = (ax * ax) / (rx * rx) + (ay * ay) / (ry * ry)
    if d <= wob * wob then
      local r = math.max(rx, ry)
      local lit = 0.52 - (dx / rx + dy / ry) * 0.42 + (px.hash(x + seed * 7, y + seed * 3) - 0.5) * 0.22
      if d > 0.6 * wob * wob and dx + dy > 0 then lit = lit - 0.18 end   -- the rim away from the light
      local c = px.ramp(P.stone, lit)
      px.put(img, x, y, px.hex(c))
    end
  end end
  -- one glint at the upper left, not always
  if rx >= 2 and px.hash(seed, 99) > 0.25 then
    px.put(img, math.floor(cx - rx * 0.45), math.floor(cy - ry * 0.5), px.hex(P.stone[4], 1.04))
  end
end

local STONES = {
  { { 6.0, 6.3, 4.9, 4.1, 1, 0.15 } },                                                  -- one large
  { { 4.0, 7.6, 3.1, 2.6, 2, -0.3 }, { 8.6, 4.2, 2.4, 2.0, 3, 0.4 } },                -- two small
  { { 3.2, 4.0, 2.2, 1.9, 4, 0 }, { 8.4, 5.2, 2.6, 2.1, 5, 0.5 }, { 5.2, 9.0, 2.3, 1.7, 6, -0.2 } }, -- three small
  { { 6.2, 7.0, 5.3, 3.3, 7, -0.12 } },                                                  -- one large, flat
  { { 4.6, 5.0, 3.6, 3.2, 8, 0.2 }, { 9.4, 9.0, 1.8, 1.5, 9, 0 } },                  -- medium and a grain
  { { 3.6, 8.0, 2.8, 2.3, 10, 0.6 }, { 8.4, 7.4, 3.0, 2.5, 11, -0.4 }, { 7.0, 2.6, 1.6, 1.3, 12, 0 } }, -- two and a chip
}
for k, list in ipairs(STONES) do
  local img = px.image(12, 12)
  for _, s in ipairs(list) do pebble(img, s[1], s[2], s[3], s[4], s[5] + k * 17, s[6]) end
  save(img, 'stone_' .. k .. '.png')
end

-- ── grass, 12 x 12, rooted on the bottom edge ───────────────────────────────────────────────────────────────────
-- Each blade rises from the bottom row, leans as it goes up, and is lighter at the tip.
for k = 1, 6 do
  local img = px.image(12, 12)
  local seed = k * 31
  local dens = ({ 0.6, 0.66, 0.52, 0.7, 0.62, 0.56 })[k]
  local tall = ({ 0.55, 0.6, 0.45, 0.7, 0.5, 0.62 })[k]
  for x0 = 0, 11 do
    if px.hash(x0, seed) < dens then
      local h = math.floor((0.25 + px.hash(x0, seed + 5) * tall) * 12)
      if px.hash(x0, seed + 8) > 0.9 then h = h + 2 end           -- now and then a taller one
      h = math.min(h, 11)
      local lean = px.hash(x0, seed + 9) > 0.5 and 1 or -1
      local bend = px.hash(x0, seed + 11)
      local x = x0
      for j = 0, h do
        if j > h * (0.4 + bend * 0.35) and j < h and px.hash(x0 * 3 + j, seed) > 0.55 then x = x + lean end
        local t = j / (h + 1) + (px.hash(x0 + j * 5, seed + 2) - 0.5) * 0.3
        local c = px.ramp(P.grass, t)
        if j == h and h >= 5 then c = P.grass[4] end
        if x >= 0 and x < 12 then px.put(img, x, 11 - j, px.hex(c)) end
      end
    end
  end
  -- a dark base so the clump sits on the soil
  for x = 0, 11 do if px.solid(img, x, 11) and px.hash(x, seed + 40) > 0.75 then px.put(img, x, 11, px.hex(P.grass[1])) end end
  save(img, 'grass_' .. k .. '.png')
end

-- ── roots, 12 x 36, hanging from the top edge ───────────────────────────────────────────────────────────────────
for k = 1, 4 do
  local img = px.image(12, 36)
  local seed = k * 53
  local len = ({ 33, 24, 35, 28 })[k]
  local thick = ({ 9, 6, 12, 7 })[k]                           -- how far down the root is two pixels wide
  local x = ({ 5, 6, 4, 7 })[k]
  local path = {}
  for y = 0, len do
    local r = px.hash(seed, y)
    if y > 0 and r > 0.74 then x = x + 1 elseif y > 0 and r < 0.26 then x = x - 1 end
    x = math.max(1, math.min(10, x))
    path[y] = x
    local c = px.hex(P.root[y < len * 0.5 and 2 or 1])
    px.put(img, x, y, c)
    if y < thick then px.put(img, x + 1, y, px.hex(P.root[1])) end   -- the shaded side
    if y > 0 and math.abs(path[y] - path[y - 1]) > 0 then px.put(img, path[y - 1], y, c) end  -- keep the line joined
  end
  -- a side rootlet branching off and tapering
  local by = math.floor(len * (0.3 + px.hash(seed, 7) * 0.25))
  local dir = px.hash(seed, 8) > 0.5 and 1 or -1
  local bx, bl = path[by], 4 + math.floor(px.hash(seed, 9) * 5)
  for i = 1, bl do
    bx = bx + dir
    local yy = by + i // 2 + (px.hash(seed + i, 3) > 0.6 and 1 or 0)
    if bx >= 0 and bx < 12 then px.put(img, bx, yy, px.hex(P.root[1])) end
  end
  save(img, 'root_' .. k .. '.png')
end

-- ── skies, 12 x 96 (night 48 x 96), lightest at the horizon ────────────────────────────────────────────────────
local function sky(name, ramp, w, grainAmt, extra)
  local img = px.image(w, 96)
  px.fill(img, function(x, y)
    local t = y / 96 + (px.hashp(x, y, w, 96) - 0.5) * grainAmt
    return px.hex(px.ramp(ramp, t))
  end)
  if extra then extra(img, w) end
  save(img, name)
end
sky('sky_day.png', P.sky, 12, 0.08)
sky('sky_dusk.png', { '#5c6a90', '#6e7298', '#8a7e9c', '#a88894', '#c2928a', '#d6a282', '#e2b688' }, 12, 0.07)
sky('sky_night.png', { '#0c1424', '#0f182b', '#121d33', '#16233b', '#1b2a44', '#22334e' }, 48, 0.07, function(img, w)
  local stars = { { 5, 8, 2 }, { 31, 14, 1 }, { 19, 27, 1 }, { 42, 33, 2 }, { 9, 44, 1 }, { 27, 52, 1 }, { 38, 6, 1 }, { 14, 63, 1 }, { 45, 58, 1 } }
  for _, s in ipairs(stars) do
    px.put(img, s[1], s[2], px.hex(s[3] == 2 and '#d4dae2' or '#8a96aa'))
  end
end)
sky('sky_rain.png', { '#4e5459', '#565c62', '#5f656a', '#686e73', '#72787c', '#7d8286' }, 12, 0.09)
sky('sky_heat.png', { '#aec4d0', '#bccdd6', '#c9d6da', '#d4dcda', '#dcdcd2', '#e2d8c2', '#e6d2b2' }, 12, 0.08)

-- ── water, 12 x 12, opaque ──────────────────────────────────────────────────────────────────────────────────────
-- As in the approved picture: the water colour over the shaded tunnel wall, 65 / 35.
local function wall(x, y)
  local c = px.hex(px.ramp(P.loam, px.hashp(x, y, 12, 12) * 0.5 + px.smooth(x, y, 4, 3, 12, 12) * 0.5), P.wall)
  return pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
end
local function wet(x, y, w)
  local r, g, b = wall(x, y)
  local wr, wg, wb = px.rgb(w)
  return px.col(r * 0.35 + wr * 0.65, g * 0.35 + wg * 0.65, b * 0.35 + wb * 0.65)
end
local function deep(x, y)                                       -- dark, slightly uneven, the unevenness drawn out sideways
  local v = px.smooth(x, y * 2, 6, 71, 12, 24) * 0.6 + px.hashp(x, y, 12, 12) * 0.25 + 0.08
  return px.ramp({ P.water[1], P.water[2] }, v - 0.05)
end
-- the light on the surface: a smoothed row of 12 random values that drifts 3 px a frame (four frames make one loop)
local glint = {}
for i = 0, 11 do glint[i] = (px.hash(i, 801) + px.hash((i + 1) % 12, 801) + px.hash((i + 11) % 12, 801)) / 3 end
local function lightAt(x, f) return glint[(x + (f - 1) * 3) % 12] end
local wimg = px.image(12, 12)
px.fill(wimg, function(x, y) return wet(x, y, deep(x, y)) end)
save(wimg, 'water.png', true)

for f = 1, 4 do
  local img = px.image(12, 12)
  px.fill(img, function(x, y)
    if y < 2 then
      local b = lightAt(x, f)
      if y == 0 then return b > 0.36 and px.hex(P.water[3], 0.92) or wet(x, y, P.water[2]) end
      return b > 0.6 and wet(x, y, P.water[3]) or wet(x, y, P.water[2])
    end
    return wet(x, y, deep(x, y))
  end)
  save(img, 'water_top_' .. f .. '.png')
end

-- ── contact sheets ─────────────────────────────────────────────────────────────────────────────────────────────
-- Skies are shown three strips wide so a sideways seam would show; everything else as saved (tiles 3 x 3).
local function wide(img, n)
  local w = px.image(img.width * n, img.height)
  for i = 0, n - 1 do px.blit(w, img, i * img.width, 0) end
  return w
end
local all, texs, smalls, skies, waters = {}, {}, {}, {}, {}
for _, it in ipairs(saved) do
  local item = it
  if it.name:find('^sky_') then item = { wide(it[1], it[1].width == 12 and 3 or 1) }; skies[#skies + 1] = item
  elseif it[1].width == 48 then texs[#texs + 1] = it
  elseif it.name:find('^water') then waters[#waters + 1] = { it[1], tile = true }
  else smalls[#smalls + 1] = it end
  all[#all + 1] = item
end
-- the water_top frames read better side by side with the water tile under them
px.sheet(texs, 'art/colony/shots/ground-1.png', 3, 4)
px.sheet(smalls, 'art/colony/shots/ground-2.png', 6, 8)
px.sheet(skies, 'art/colony/shots/ground-3.png', 3, 5)
px.sheet(waters, 'art/colony/shots/ground-4.png', 8, 5)
px.sheet(all, 'art/colony/shots/ground.png', 4, 6)
print('ground: ' .. #saved .. ' files')
