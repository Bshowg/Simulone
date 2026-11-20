-- The things of The Colony: what lies in the nest and on the surface (food, soil, brood, fungus, what an ant carries,
-- the dig mark, rain). Run from the project folder:
--   Aseprite -b --script-param root=<project folder> --script art/colony/things.lua
local px = dofile(app.params.root .. '/art/colony/lib/px.lua')
local P = px.PAL
local OUT = 'art/colony/out/things/'
local items = {}
local function save(img, name) px.save(img, OUT .. name .. '.png'); items[#items + 1] = { img } end

-- Materials: a letter in a shape maps to a colour. l = lit (upper left), m = body, d = shade (lower right).
local CRUMB = { l = P.crumb[3], m = P.crumb[2], d = P.crumb[1] }
local SEED  = { l = '#b8945e', m = '#97733f', d = '#71542e', h = '#d2b07a' }   -- a seed is not a crumb: duller, browner
local SOIL  = { l = '#a27a50', m = '#86603e', d = P.loam[3], k = '#946c46' }    -- loam, a little dried on the lit side

-- Shapes of single bits, irregular. Each is a list of rows.
local CRUMBS = {
  { 'lm', 'md' },
  { '.lm', 'lmd', 'dd.' },
  { 'lmm', '.md' },
  { 'lm.', 'mmd' },
  { 'l', 'd' },
  { 'lmd' },
  { '.l', 'lm', 'md' },
  { 'lm', 'd.' },
  { 'llm', 'mmd', '.d.' },
  { 'm' },
}
local SOILS = {
  { 'lm', 'md' }, { 'lk', 'kd' }, { '.l.', 'lmd', '.d.' }, { 'lk', 'md' }, { 'lm', 'dd' }, { 'kl', 'md' }, { 'lkm', 'mdd' },
}
local SEEDS = { { '.hm.', 'lmmd', '.dd.' }, { 'hm', 'lm', 'md' }, { '.hl', 'lmd', 'dd.' } }

local function dims(s) return #s[1], #s end

-- A heap built by dropping bits one by one onto the floor (the bottom row). Each bit falls until it rests, then rolls
-- down the side of the heap if one side is clearly lower: so the heap grows upward and outward like real loose stuff.
local Heap = {}
Heap.__index = Heap
local function heap(w, h) local o = setmetatable({ w = w, h = h, g = {}, bits = {} }, Heap); return o end
function Heap:solid(x, y) if y >= self.h then return true end; if x < 0 or x >= self.w then return true end; return self.g[y * 64 + x] end
function Heap:fits(s, x, y)
  local sw, sh = dims(s)
  for j = 1, sh do for i = 1, sw do if s[j]:sub(i, i) ~= '.' then
    local X, Y = x + i - 1, y + j - 1
    if X < 0 or X >= self.w or Y >= self.h or (Y >= 0 and self.g[Y * 64 + X]) then return false end
  end end end
  return true
end
function Heap:rest(s, x) local y = -#s; while self:fits(s, x, y + 1) do y = y + 1 end; return y end
function Heap:drop(s, x, pal, seed)
  local sw = dims(s)
  x = math.max(0, math.min(self.w - sw, x))
  local y = self:rest(s, x)
  for step = 1, 8 do
    local best, bx = y, x
    for _, dx in ipairs(px.hash(seed, step) < 0.5 and { -1, 1 } or { 1, -1 }) do
      local nx = x + dx
      if nx >= 0 and nx <= self.w - sw and self:fits(s, nx, y) then
        local ny = self:rest(s, nx); if ny >= best + 1 then best, bx = ny, nx end
      end
    end
    if bx == x then break end
    x, y = bx, best
  end
  if y < 0 then return false end
  for j = 1, #s do for i = 1, #s[j] do local ch = s[j]:sub(i, i); if ch ~= '.' then
    self.g[(y + j - 1) * 64 + x + i - 1] = true
    self.bits[#self.bits + 1] = { x + i - 1, y + j - 1, pal[ch] }
  end end end
  return true
end
function Heap:draw(img, ox, oy) for _, b in ipairs(self.bits) do px.put(img, (ox or 0) + b[1], (oy or 0) + b[2], px.hex(b[3])) end end

-- A list of bits to drop: each { shape, palette, x }. A heap for count n uses the first n of the same list, so every
-- step holds everything of the step before plus more.
local function bitlist(n, seed, shapes, pal, spread0, spreadk, extra)
  local L = {}
  for k = 1, n do
    local s = shapes[math.floor(px.hash(k, seed) * #shapes) + 1]
    local p = pal
    if k == 1 and seed == 11 then s = shapes[2] end
    if extra and extra[k] then s, p = extra[k][1], extra[k][2] end
    local sw = dims(s)
    local off = (px.hash(k * 7, seed + 3) - 0.5) * (spread0 + spreadk * k)
    L[k] = { s, p, math.floor(6 - sw / 2 + off + 0.5) }
  end
  return L
end
local function build(list, n, seed)
  local H = heap(12, 12)
  for k = 1, n do local b = list[k]; H:drop(b[1], b[3], b[2], seed + k) end
  local img = px.image(12, 12); H:draw(img); return img, H
end

-- A heap with a given width and height: a rounded mound with an uneven top, packed with bits from the bottom up.
-- Each bit is lit on its own upper left, so the bits stay apart; the few holes left between them are shadow deep in the
-- heap, or open air at its surface (so the edge is crumbly, not smooth).
local function dome(W, H, cx, seed, shapes, pal, shadow, pre, airy, feet)
  local mask, top = {}, {}
  for x = 0, 11 do
    local d = math.abs(x + 0.5 - cx) / (W / 2)
    local h = 0
    if d < 1 then h = math.min(math.floor(H + 0.5), math.floor(H * (1 - d ^ 1.6) + (px.smooth(x, 0, 2, seed) - 0.5) * 2.2 + px.hash(x, seed) * 0.7 + 0.5)) end
    h = math.max(0, math.min(12, h)); top[x] = 12 - h
    for y = 12 - h, 11 do mask[y * 16 + x] = true end
  end
  local used, img = {}, px.image(12, 12)
  local function fits(s, x, y)
    for j = 1, #s do for i = 1, #s[j] do if s[j]:sub(i, i) ~= '.' then
      local k = (y + j - 1) * 16 + x + i - 1
      if x + i - 1 < 0 or x + i - 1 > 11 or not mask[k] or used[k] then return false end
    end end end
    return true
  end
  local function place(s, p, x, y)
    for j = 1, #s do for i = 1, #s[j] do local ch = s[j]:sub(i, i); if ch ~= '.' then
      local X, Y = x + i - 1, y + j - 1
      -- the heap as a whole is lit from the upper left too: its right flank is a tone darker, its left a tone lighter
      local r = px.hash(X * 7 + seed, Y * 11)
      if X > cx + 0.5 and r < 0.55 then ch = (ch == 'l' or ch == 'h' or ch == 'k') and 'm' or 'd'
      elseif X < cx - 2 and r < 0.45 and ch == 'd' then ch = 'm' end
      if not p[ch] then ch = 'm' end
      used[Y * 16 + X] = true; px.put(img, X, Y, px.hex(p[ch]))
    end end end
  end
  for _, q in ipairs(pre or {}) do local s = q[1]; local y = 12 - #s - q[3]; if fits(s, q[2], y) then place(s, q[4], q[2], y) end end
  for y = 0, 11 do for x = 0, 11 do local k = y * 16 + x
    if mask[k] and not used[k] then
      local start = math.floor(px.hash(x * 3 + seed, y * 5) * #shapes)
      local done = false
      for t = 0, #shapes - 1 do
        local s = shapes[(start + t) % #shapes + 1]
        local a = s[1]:find('[^.]')
        if fits(s, x - a + 1, y) then place(s, pal, x - a + 1, y); done = true; break end
      end
      if not done then
        used[k] = true
        local surface = y == top[x] or (x > 0 and top[x - 1] > y) or (x < 11 and top[x + 1] > y)
        if not surface or (not airy and px.hash(x, y + seed) < 0.5) then px.put(img, x, y, px.hex(shadow)) end
      end
      if airy and done and px.hash(x + 17, y * 3 + seed) < 0.2 then
        local surface = y == top[x]
        if surface then img:drawPixel(x, y, 0) end
      end
    end
  end end
  -- a few bits that rolled off lie loose at the foot of the heap
  for k, s in ipairs(feet or {}) do
    local sw = #s[1]
    local x = (k % 2 == 1) and math.floor(cx - W / 2 - sw + 0.5) or math.floor(cx + W / 2 + 0.5)
    if x >= 0 and x + sw <= 12 then place(s, pal, x, 12 - #s) end
  end
  return img
end
local function loose(list, n, seed) local H = heap(12, 12); for k = 1, n do local b = list[k]; H:drop(b[1], b[3], b[2], seed + k) end; local img = px.image(12, 12); H:draw(img); return img end

-- Crumbs in a store: 1 to 8. A few loose bits, then a heap that fills the cell as the store fills.
local clist = bitlist(4, 11, CRUMBS, CRUMB, 5, 0.6)
local CSH = '#8a6424'                                          -- the shadow between crumbs deep in a heap
save(loose(clist, 1, 100), 'crumbs_1')
save(loose(clist, 2, 100), 'crumbs_2')
save(loose(clist, 4, 100), 'crumbs_3')
local CD = { { 7, 4.2 }, { 8.5, 4.5 }, { 9.5, 5.5 }, { 10.5, 7 }, { 12, 9 } }
local CFEET = { {}, { { 'lm' } }, { { 'lm' }, { 'l', 'd' } }, { { 'lmd' }, { 'lm' } }, {} }
for n = 4, 8 do local d = CD[n - 3]; save(dome(d[1], d[2], 6, 13, CRUMBS, CRUMB, CSH, nil, false, CFEET[n - 3]), 'crumbs_' .. n) end

-- Food found on the surface: crumbs with a few seeds among them, from a few bits to a heap filling most of the cell.
local flist = bitlist(3, 23, CRUMBS, CRUMB, 6, 0.5, { [2] = { SEEDS[1], SEED } })
save(loose(flist, 3, 200), 'find_1')
local SEEDPRE = { { SEEDS[1], 2, 0, SEED }, { SEEDS[3], 7, 0, SEED }, { SEEDS[2], 5, 2, SEED }, { SEEDS[1], 3, 4, SEED } }
local FD = { { 7.5, 3.5 }, { 10, 5.5 }, { 12.6, 8.5 } }
local FFEET = { { { 'lm' }, { 'lmd' } }, { { 'l', 'd' } }, {} }
for n = 2, 4 do local d = FD[n - 1]; save(dome(d[1], d[2], 6, 29, CRUMBS, CRUMB, CSH, SEEDPRE, false, FFEET[n - 1]), 'find_' .. n) end

-- Loose soil dropped in a tunnel: small loam crumbs, one load to a small heap.
local SD = { { 5.5, 3 }, { 9, 4.5 }, { 11, 6 }, { 12.6, 8 } }
local SFEET = { { { 'l' } }, { { 'k' }, { 'lm' } }, { { 'lk' }, { 'm' }, }, { { 'l' }, { 'k' } } }
do local img = px.image(12, 12); px.sprite(img, { '..lk..', '.lmkmd', 'lkd.md' }, 3, 9, SOIL); px.put(img, 9, 11, px.hex(SOIL.k)); save(img, 'soil_1') end
for n = 2, 4 do local d = SD[n]; save(dome(d[1], d[2], 6, 41, SOILS, SOIL, P.loam[1], nil, true, SFEET[n]), 'soil_' .. n) end

-- Brood, in strips 4 wide and 12 high, lying on the floor.
local EGG = { e = P.egg, s = '#d4cebe' }
local LARVA = { l = P.larva[2], m = P.larva[1], d = '#b8a27a', h = '#8a6a44' }
local PUPA = { l = P.pupa[2], m = P.pupa[1], d = '#86683f', t = '#5e4628' }
local function brood(placements)
  local img = px.image(4, 12)
  for _, p in ipairs(placements) do px.sprite(img, p[1], p[2], p[3], p[4]) end
  return img
end
local EG = { 'ee', 'es' }
save(brood({ { EG, 1, 10, EGG } }), 'eggs_1')
save(brood({ { EG, 0, 10, EGG }, { EG, 1, 8, EGG } }), 'eggs_2')
save(brood({ { EG, 0, 10, EGG }, { EG, 2, 10, EGG }, { EG, 1, 8, EGG } }), 'eggs_3')
-- a larva: a fat cream grub curled on its side, the small head tucked at the lower left
local LV = { '.ll.', 'lmdm', 'h.md' }
local LV2 = { '.ll.', 'mdml', 'dm.h' }
save(brood({ { LV, 0, 9, LARVA } }), 'larvae_1')
save(brood({ { LV, 0, 9, LARVA }, { LV2, 0, 6, LARVA } }), 'larvae_2')
save(brood({ { LV, 0, 9, LARVA }, { LV2, 0, 6, LARVA }, { LV, 0, 3, LARVA } }), 'larvae_3')
-- a pupa: a tan cocoon, an upright oval, the dark spot at its bottom end
local PU = { '.lm.', 'lmmd', 'mmdd', '.dt.' }
local PU2 = { '.lm.', 'lmmd', 'mmdd', '.td.' }
save(brood({ { PU, 0, 8, PUPA } }), 'pupae_1')
save(brood({ { PU, 0, 8, PUPA }, { PU2, 0, 4, PUPA } }), 'pupae_2')
save(brood({ { PU, 0, 8, PUPA }, { PU2, 0, 4, PUPA }, { PU, 0, 0, PUPA } }), 'pupae_3')

-- Fungus garden: a bed of chewed leaf on the floor, the pale fungus growing out of it.
local BED = { '#5a5a32', '#646838', '#6e5a38', '#6f8a4a', '#7a8a4e' }
local FG = P.fungus
local function bed(img, seed)
  local top = {}
  for x = 0, 11 do
    local hb = 2 + math.floor(px.smooth(x, 0, 3, seed) * 2.2)
    if x == 0 or x == 11 then hb = math.max(1, hb - 1) end
    top[x] = 11 - hb + 1
    for j = 0, hb - 1 do
      local y = 11 - j
      local r = px.hash(x * 5 + seed, y * 3)
      local c = (j == hb - 1 and r < 0.55) and (r < 0.3 and BED[4] or BED[5]) or BED[math.floor(px.hash(x, y + seed) * 3) + 1]
      px.put(img, x, y, px.hex(c))
    end
  end
  return top
end
-- the growth: a spongy pale dome on the bed, its top uneven, lighter at the upper left and greyer at the lower right,
-- with grain of the neighbouring tones. `body` shifts it greyer (a ripe garden is older, with the bright knobs on it).
local function growth(img, top, W, height, seed, body, leafbits)
  local hs = {}
  for x = 0, 11 do
    local d = math.abs(x + 0.5 - 6) / (W / 2)
    local h = 0
    if d < 1 then h = math.floor(height * (1 - d ^ 1.6) + (px.smooth(x, 0, 1.5, seed) - 0.5) * 2.2 + 0.5) end
    hs[x] = math.max(0, h)
  end
  for x = 0, 11 do
    local h = hs[x]
    for j = 0, h - 1 do
      local y = top[x] - 1 - j
      local r = px.hash(x * 13 + seed, y * 7)
      local light = (h - j) / (h + 1) * 0.4 - x / 11 * 0.5 + 0.55 - (body or 0) + (r - 0.5) * 0.5
      local lit = (j == h - 1) or (x > 0 and hs[x - 1] <= j)
      local shade = (x < 11 and hs[x + 1] <= j) and not lit
      if lit then light = light + 0.35 elseif shade then light = light - 0.4 end
      if j == 0 then light = light - 0.25 end
      px.put(img, x, y, px.hex(px.ramp(FG, light)))
    end
  end
  -- the chewed leaf still shows here and there inside the sponge
  for _, b in ipairs(leafbits or {}) do local x = b[1]; if hs[x] > b[2] then px.put(img, x, top[x] - 1 - b[2], px.hex(b[3] or P.leaf)) end end
  return hs
end

-- fungus_0: bare bed
do local img = px.image(12, 12); bed(img, 5); save(img, 'fungus_0') end
-- fungus_1: pale threads starting from the bed
do
  local img = px.image(12, 12); local top = bed(img, 5)
  local threads = { { 2, 2, 1 }, { 4, 1, 0 }, { 5, 3, -1 }, { 7, 2, 0 }, { 9, 3, 1 }, { 10, 1, 0 } }
  for _, t in ipairs(threads) do
    local x, y = t[1], top[t[1]] - 1
    for j = 0, t[2] - 1 do
      px.put(img, x, y - j, px.hex(j == t[2] - 1 and FG[3] or FG[2]))
      if j == 1 and t[3] ~= 0 then x = x + t[3] end
    end
  end
  -- a fuzz of pale on the bed's surface
  for _, x in ipairs({ 1, 3, 6, 8, 11 }) do px.put(img, x, top[x], px.hex(FG[1])) end
  save(img, 'fungus_1')
end
-- fungus_2: full pale growth
do
  local img = px.image(12, 12); local top = bed(img, 5)
  growth(img, top, 11, 5.5, 71, 0, { { 2, 0, BED[5] }, { 9, 0, BED[1] } })
  save(img, 'fungus_2')
end
-- fungus_3: ripe: taller, a little greyer, with the round bright knobs the ants harvest and leaf bits in the sponge
do
  local img = px.image(12, 12); local top = bed(img, 5)
  local hs = growth(img, top, 12, 6.5, 71, 0.45, { { 2, 1, P.leaf }, { 5, 0, BED[5] }, { 9, 2, P.leaf }, { 7, 3, BED[1] }, { 3, 3, BED[2] } })
  -- the knobs: clusters of small bright beads crowning the grey sponge, each a low bump with the sponge's top brightened
  -- around it (so they read as swellings on it, not spikes)
  local knobs = { 1, 4, 7, 9 }
  for _, x in ipairs(knobs) do
    local y = top[x] - hs[x]
    local yl, yr = top[x] - hs[x], top[x + 1] - hs[x + 1]
    px.put(img, x, math.min(yl, yr) - 1, px.hex(FG[3]))
    px.put(img, x, yl, px.hex(FG[3])); px.put(img, x + 1, yr, px.hex(FG[3])); px.put(img, x + 1, yr - 1, px.hex(FG[2]))
    px.put(img, x, yl + 1, px.hex(FG[2])); px.put(img, x + 1, yr + 1, px.hex(FG[1]))
  end
  save(img, 'fungus_3')
end

-- What an ant carries: 4 x 4, held in the jaws.
local function carry(name, rows, pal) local img = px.image(4, 4); px.sprite(img, rows, 0, 0, pal); save(img, 'carry_' .. name) end
carry('crumb', { '....', '.lm.', 'lmmd', '.dd.' }, CRUMB)
carry('soil', { '....', '.lk.', 'lmmd', 'mdd.' }, SOIL)
carry('egg', { '....', '....', '.ee.', '.es.' }, EGG)
carry('larva', { '....', '.ll.', 'lmmd', 'hmd.' }, LARVA)
carry('pupa', { '.lm.', 'lmmd', 'mmdd', '.dt.' }, PUPA)

-- The dig mark: a broken pale line one pixel in from the cell's edge, irregular dashes, transparent in the middle.
do
  local img = px.image(12, 12)
  local path = {}
  for x = 1, 10 do path[#path + 1] = { x, 1 } end
  for y = 2, 10 do path[#path + 1] = { 10, y } end
  for x = 9, 1, -1 do path[#path + 1] = { x, 10 } end
  for y = 9, 2, -1 do path[#path + 1] = { 1, y } end
  local on, left, k = true, 3, 0
  for i, p in ipairs(path) do
    if on then px.put(img, p[1], p[2], px.hex(px.hash(i, 41) < 0.7 and P.sand[4] or P.sand[3])) end
    left = left - 1
    if left == 0 then k = k + 1; on = not on; left = on and (2 + math.floor(px.hash(k, 9) * 3)) or (1 + math.floor(px.hash(k, 17) * 2)) end
  end
  save(img, 'mark')
end

-- Rain: a few short slanted streaks; the second frame is the first moved down half the height and along the slant,
-- wrapping, so the two frames loop and the strip tiles in both directions.
do
  local streaks = { { 2, 1, 4 }, { 9, 4, 3 }, { 5, 9, 4 }, { 11, 13, 3 }, { 3, 16, 3 }, { 8, 19, 4 } }
  for f = 1, 2 do
    local img = px.image(12, 24)
    for _, s in ipairs(streaks) do
      for j = 0, s[3] - 1 do
        local y = s[2] + j + (f - 1) * 12
        local x = s[1] - (j // 2) - (f - 1) * 6
        px.put(img, x % 12, y % 24, px.hex(j == s[3] - 1 and P.sky[4] or P.sky[3]))
      end
    end
    save(img, 'rain_' .. f)
  end
end

px.sheet(items, 'art/colony/shots/things.png', 6, 8)
