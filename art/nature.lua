-- nature.lua: the trees of The Lord's Will, four shapes in four seasons.
--   Aseprite -b --script-param root=<path to art> --script <path to art>/nature.lua
-- Every sprite is 40 x 56, transparent, hard pixels. The trunk's foot is at (20, 47): the centre of the cell diamond the
-- game puts under the sprite (the sprite's bottom centre sits on the diamond's bottom corner). Nothing below y = 51.
-- Shapes: 0 broad oak, 1 tall ash, 2 hazel bush, 3 birch. Crowns are clumps of leaves, each with an ink edge on its
-- shaded lower right side; trunks are ink. Winter trees are bare ink branches with snow lying on them.
-- Output: art/out/nature/tree_<season>_<k>.png and art/out/nature/preview_trees.png (sprites, and a 5 x 5 forest per
-- season placed as the game places them, enlarged 3 times).
local root = app.params.root
local ink = dofile(root .. '/lib/ink.lua')
local P, hex, hash = ink.P, ink.hex, ink.hash
local OUT = root .. '/out/nature/'
local W, H, FX, FY = 40, 56, 20, 47

-- colours added for the trees (soft pastels in the family of ink.P)
local X = {
  spring = '#cadaa0', springShade = '#a4bd86', springLight = '#dde7b8',   -- fresh pale green
  blossom = '#eedfd8',                                                    -- pinkish white blossom
  ochre = '#d6b78a', ochreLight = '#e6cda2',                              -- autumn orange-ochre
  birch = '#ece6d8',                                                      -- birch bark
}

-- ── the shapes: clumps { x, y, r } and branches { x0, y0, x1, y1 } from the trunk; trunk = { top y, base width }
local SHAPES = {
  [0] = { -- broad oak: a wide low dome on a short thick trunk
    trunk = { top = 31, wide = 3 },
    clumps = { { 14, 13, 7 }, { 26, 12, 7 }, { 20, 8, 6 }, { 8, 21, 6 }, { 20, 19, 8 }, { 32, 21, 6 },
               { 12, 28, 6 }, { 28, 28, 6 }, { 20, 30, 6 } },
    branches = { { 20, 35, 11, 24 }, { 20, 33, 29, 23 }, { 20, 31, 15, 15 }, { 20, 31, 25, 14 }, { 20, 30, 20, 10 } },
  },
  [1] = { -- ash / elm: tall and narrow, crown in loose tiers
    trunk = { top = 24, wide = 2 },
    clumps = { { 20, 6, 5 }, { 15, 11, 6 }, { 25, 11, 6 }, { 12, 18, 6 }, { 21, 18, 7 }, { 28, 24, 6 },
               { 13, 25, 6 }, { 21, 28, 6 } },
    branches = { { 20, 30, 14, 25 }, { 20, 28, 27, 23 }, { 20, 24, 13, 17 }, { 20, 22, 24, 11 }, { 20, 22, 16, 10 }, { 20, 22, 20, 5 } },
  },
  [2] = { -- hazel: a low bush of several stems from the ground
    trunk = { top = 44, wide = 2 },
    stems = { { 19, 47, 14, 33 }, { 20, 47, 20, 29 }, { 21, 47, 26, 33 }, { 20, 46, 11, 39 }, { 20, 46, 29, 39 } },
    clumps = { { 20, 26, 6 }, { 14, 31, 6 }, { 26, 31, 6 }, { 10, 37, 5 }, { 30, 37, 5 }, { 17, 37, 6 }, { 24, 39, 5 } },
    branches = {},
  },
  [3] = { -- birch: a slender white trunk to the top, small airy clumps
    trunk = { top = 8, wide = 2, birch = true },
    clumps = { { 20, 7, 4 }, { 16, 12, 5 }, { 24, 14, 5 }, { 14, 20, 5 }, { 25, 21, 5 }, { 17, 27, 5 },
               { 26, 29, 4 }, { 12, 31, 4 } },
    branches = { { 20, 30, 13, 30 }, { 20, 28, 26, 29 }, { 20, 24, 17, 26 }, { 20, 22, 25, 21 }, { 20, 18, 14, 20 }, { 20, 15, 24, 14 }, { 20, 12, 16, 12 } },
  },
}

-- ── a little pixel buffer with tags (so snow and ink are known when finishing)
local function canvas() return { c = {}, tag = {} } end
local function put(b, x, y, col, tag)
  if x < 0 or y < 0 or x >= W or y > 51 then return end
  local k = y * W + x; b.c[k] = col; b.tag[k] = tag
end
local function getc(b, x, y) if x < 0 or y < 0 or x >= W or y >= H then return nil end; return b.c[y * W + x] end
local function gett(b, x, y) if x < 0 or y < 0 or x >= W or y >= H then return nil end; return b.tag[y * W + x] end
local function line(b, x0, y0, x1, y1, col, tag)
  local n = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
  for i = 0, n do local t = n == 0 and 0 or i / n; put(b, math.floor(x0 + (x1 - x0) * t + 0.5), math.floor(y0 + (y1 - y0) * t + 0.5), col, tag) end
end

-- the trunk: ink, a little wider at the foot; birch bark is pale with ink marks
local function trunk(b, s)
  local tr = s.trunk
  if s.stems then
    for _, st in ipairs(s.stems) do line(b, st[1], st[2], st[3], st[4], P.ink, 'wood') end
    return
  end
  for y = tr.top, FY do
    local wide = tr.wide + ((y >= FY - 2) and 1 or 0)
    local x0 = FX - (wide // 2)
    for k = 0, wide - 1 do
      local col = P.ink
      if tr.birch then col = (k == 0 or k == wide - 1) and P.ink or X.birch
        if k == 0 and hash(y, 3) > 0.7 then col = P.ink2 end
      elseif k == 0 then col = P.ink2 end
      put(b, x0 + k, y, col, 'wood')
    end
  end
  if tr.birch then
    for y = tr.top + 2, FY - 2, 3 do if hash(y, 7) > 0.4 then put(b, FX, y, P.ink, 'wood') end end
  end
  put(b, FX - 2, FY, P.ink, 'wood'); put(b, FX + 2, FY, P.ink, 'wood')
end
local function branches(b, s, col)
  for _, br in ipairs(s.branches) do line(b, br[1], br[2], br[3], br[4], col or P.ink, 'wood') end
end

-- one clump of leaves: base colour, a shaded crescent to the lower right edged with ink, a light touch upper left
local function clump(b, cx, cy, r, pal, seed)
  local sq = 0.82                                              -- a little flatter than round
  local function inside(dx, dy) return dx * dx + (dy / sq) ^ 2 <= r * r + 0.6 end
  for dy = -r, r do for dx = -r, r do
    if inside(dx, dy) then
      local x, y = cx + dx, cy + dy
      local edge = not (inside(dx - 1, dy) and inside(dx + 1, dy) and inside(dx, dy - 1) and inside(dx, dy + 1))
      local lr = dx * 0.8 + dy
      local col
      if edge and lr > -0.4 * r then col = hash(x // 2 + seed, y // 2) > 0.8 and P.ink2 or P.ink
      elseif lr > r * 0.25 then col = pal.shade
      elseif lr < -r * 0.75 and hash(x, y + seed) > 0.35 then col = pal.light
      else col = pal.base
        if hash(x * 3 + seed, y * 5) > 0.9 then col = pal.shade end    -- a few leaf strokes
      end
      put(b, x, y, col, 'leaf')
    end
  end end
end

-- the outline of the whole crown: every pixel at the edge of the shape becomes ink (snow stays snow)
local function silhouette(b)
  local out = {}
  for y = 0, H - 1 do for x = 0, W - 1 do
    local c = getc(b, x, y)
    if c and gett(b, x, y) ~= 'snow' then
      if not (getc(b, x - 1, y) and getc(b, x + 1, y) and getc(b, x, y - 1) and getc(b, x, y + 1)) then
        out[#out + 1] = { x, y, hash(x // 2, y // 2) > 0.8 and P.ink2 or P.ink }
      end
    end
  end end
  for _, o in ipairs(out) do b.c[o[2] * W + o[1]] = o[3] end
end

-- ── seasons
local PAL = {
  summer = { { base = P.leaf, shade = P.leafShade, light = P.grass } },
  spring = { { base = X.spring, shade = X.springShade, light = X.springLight } },
  autumn = { { base = P.weld, shade = P.russet, light = P.corn },
             { base = X.ochre, shade = P.madder, light = X.ochreLight },
             { base = P.corn2, shade = P.cornLine, light = P.corn },
             { base = P.leaf, shade = P.leafShade, light = P.grass } },
}

local function sortedClumps(s)
  local list = {}
  for i, c in ipairs(s.clumps) do list[#list + 1] = { c[1], c[2], c[3], i } end
  table.sort(list, function(a, b2) if a[2] ~= b2[2] then return a[2] < b2[2] end; return a[1] < b2[1] end)
  return list
end

local function leafy(k, season)
  local s, b = SHAPES[k], canvas()
  trunk(b, s); branches(b, s)
  for _, c in ipairs(sortedClumps(s)) do
    local i, r = c[4], c[3]
    local pal
    if season == 'autumn' then
      if hash(i * 7 + k, 11) < 0.3 then goto skip end           -- thinner crowns: some clumps already gone
      r = math.max(3, r - 1)
      local h = hash(i * 3 + k * 5, 17)
      pal = PAL.autumn[h < 0.4 and 1 or h < 0.7 and 2 or h < 0.94 and 3 or 4]
    else pal = PAL[season][1] end
    clump(b, c[1], c[2], r, pal, i * 13 + k)
    ::skip::
  end
  silhouette(b)
  if season == 'spring' then                                    -- a few blossoms on the lit upper parts
    for _, c in ipairs(s.clumps) do
      for j = 1, 3 do
        local x = c[1] + math.floor((hash(c[1] * 3 + j, c[2]) - 0.6) * c[3] * 1.4)
        local y = c[2] + math.floor((hash(c[2] * 5, c[1] + j) - 0.7) * c[3] * 1.2)
        if gett(b, x, y) == 'leaf' and hash(c[1] + j * 9, c[2] + k) > 0.45 then put(b, x, y, j == 2 and P.veil or X.blossom, 'leaf') end
      end
    end
  end
  if season == 'autumn' then                                    -- a few leaves fallen at the foot
    for j = 1, 5 do
      local x = FX + math.floor((hash(j, k + 3) - 0.5) * 14)
      local y = FY + math.floor((hash(k + 5, j) - 0.4) * 5)
      if not getc(b, x, y) then put(b, x, y, j % 2 == 0 and P.russet or P.weld, 'litter') end
    end
  end
  return b
end

-- winter: the trunk and branches, each branch going on to its clump's centre and splitting into twigs
local function winter(k)
  local s, b = SHAPES[k], canvas()
  trunk(b, s)
  local tr = s.trunk
  for _, br in ipairs(s.branches) do line(b, br[1], br[2], br[3], br[4], P.ink, 'wood') end
  for i, c in ipairs(s.clumps) do
    -- the nearest branch end or stem end feeds this clump
    local sx, sy = FX, tr.top
    local best = math.huge
    local ends = s.stems or s.branches
    for _, br in ipairs(ends) do local d = (br[3] - c[1]) ^ 2 + (br[4] - c[2]) ^ 2; if d < best then best = d; sx, sy = br[3], br[4] end end
    if (sx - c[1]) ^ 2 + (sy - c[2]) ^ 2 > 2 then line(b, sx, sy, c[1], c[2], P.ink, 'wood') end
    -- twigs fanning outward and upward from the clump centre
    local ox = c[1] - FX
    local dirs = { { -0.8, -0.7 }, { 0.15, -1 }, { 0.85, -0.6 } }
    for j, d in ipairs(dirs) do
      local len = c[3] * (0.7 + hash(i * 3 + j, k) * 0.5)
      local dx = d[1] + ox * 0.04
      local ex, ey = c[1] + dx * len, c[2] + d[2] * len
      line(b, c[1], c[2], ex, ey, j == 2 and P.ink or P.ink2, 'wood')
      if hash(i + j * 5, k + 1) > 0.4 then line(b, ex, ey, ex + (dx > 0 and 2 or -2), ey - 1, P.ink2, 'wood') end
    end
  end
  -- snow lies on the tops of the gentler branches
  local adds = {}
  for y = 1, 51 do for x = 0, W - 1 do
    if gett(b, x, y) == 'wood' and not getc(b, x, y - 1) then
      local flat = gett(b, x - 1, y) == 'wood' or gett(b, x + 1, y) == 'wood'
      if (flat and hash(x, y * 3 + k) > 0.1) or hash(x * 7, y + k) > 0.6 then adds[#adds + 1] = { x, y - 1 } end
    end
  end end
  for _, a in ipairs(adds) do put(b, a[1], a[2], P.snow, 'snow') end
  -- a little snow at the foot
  if not s.stems then for dx = -3, 3 do if not getc(b, FX + dx, FY) and math.abs(dx) > 1 then put(b, FX + dx, FY, P.snow, 'snow') end end end
  return b
end

-- ── render and save
local function toImage(b)
  local spr = ink.sprite(W, H)
  for k, col in pairs(b.c) do spr:put(k % W, k // W, col) end
  return spr
end

local SEASONS = { 'spring', 'summer', 'autumn', 'winter' }
local imgs = {}
for _, season in ipairs(SEASONS) do
  imgs[season] = {}
  for k = 0, 3 do
    local b = season == 'winter' and winter(k) or leafy(k, season)
    local spr = toImage(b)
    spr:save(OUT .. 'tree_' .. season .. '_' .. k .. '.png')
    imgs[season][k] = spr.img
  end
end

-- ── preview: per season, the four sprites on paper, then a 5 x 5 forest on that season's ground, enlarged 3 times
local pc = app.pixelColor
local function loadTex(name, fallback)
  local ok, img = pcall(function() return Image { fromFile = root .. '/out/ground/' .. name .. '.png' } end)
  if ok and img and img.width > 0 then local w, h = img.width, img.height; return function(x, y) return img:getPixel(x % w, y % h) end end
  local v = hex(fallback); return function() return v end
end
local GRASS = { spring = '#c9d8a4', summer = P.grass, autumn = '#d4cfa3', winter = P.snow }
local FN, colW = 5, 220
local sheetW, sheetH = colW * 4, 72 + 160
local sheet = Image(sheetW, sheetH, ColorMode.RGB)
local pa = hex(P.paper)
for y = 0, sheetH - 1 do for x = 0, sheetW - 1 do sheet:drawPixel(x, y, pa) end end
local function blit(img, ox, oy)
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do
    local c = img:getPixel(x, y); if pc.rgbaA(c) > 0 then sheet:drawPixel(ox + x, oy + y, c) end
  end end
end
for si, season in ipairs(SEASONS) do
  local x0 = (si - 1) * colW
  for k = 0, 3 do blit(imgs[season][k], x0 + 10 + k * 50, 6) end
  -- ground: grass around, forest floor under the forest cells (screen space textures)
  local grass = loadTex('grass_' .. season, GRASS[season])
  local floor = loadTex('forest_' .. season, GRASS[season])
  local ox, oy = x0 + colW // 2, 72 + 40                       -- top corner of cell (0, 0)
  for y = 72, sheetH - 1 do for x = x0 + 4, x0 + colW - 5 do
    local u, v = (x - ox + 0.5) / 16, (y - oy + 0.5) / 8
    local gx, gy = (u + v) / 2, (v - u) / 2
    local inForest = gx >= 0 and gy >= 0 and gx < FN and gy < FN
    sheet:drawPixel(x, y, (inForest and floor or grass)(x, y))
  end end
  local cells = {}
  for cy = 0, FN - 1 do for cx = 0, FN - 1 do cells[#cells + 1] = { cx, cy } end end
  table.sort(cells, function(a, b) return a[1] + a[2] < b[1] + b[2] end)
  for _, c in ipairs(cells) do
    local h = hash(c[1] * 5 + 1, c[2] * 3 + 2)
    local k = h < 0.4 and 0 or h < 0.65 and 1 or h < 0.8 and 2 or 3
    local sx, sy = ox + (c[1] - c[2]) * 16, oy + (c[1] + c[2]) * 8
    blit(imgs[season][k], sx - 20, sy + 16 - 56)
  end
end
local s = 3
local big = Image(sheetW * s, sheetH * s, ColorMode.RGB)
for y = 0, sheetH - 1 do for x = 0, sheetW - 1 do local c = sheet:getPixel(x, y); for j = 0, s - 1 do for i = 0, s - 1 do big:drawPixel(x * s + i, y * s + j, c) end end end end
big:saveAs(OUT .. 'preview_trees.png')
print('ok nature 16 trees')
