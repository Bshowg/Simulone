-- The Colony: the ants. One PNG per kind in art/colony/out/ants/, each a row of 7 frames:
--   walk 1, walk 2, walk 3, walk 4, work 1, work 2, still
-- The ant faces right, feet on the bottom row, body centred and fixed in place across frames.
--   Aseprite -b --script-param root=<project folder> --script art/colony/ants.lua
local px = dofile(app.params.root .. '/art/colony/lib/px.lua')
local pc = app.pixelColor
local A = px.PAL.ant                                   -- body, legs and feelers, the light on the abdomen

local function hx(c) return string.format('#%02x%02x%02x', pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)) end
local function mix(a, b, t) return hx(px.mix(a, b, t)) end

-- Letters in the rows below:
--   k body   h the light on the abdomen   g a seam between plates (a tone between body and legs)
--   d a darker band (the rival's abdomen)  m jaws   e eye
-- Legs and feelers are not drawn as rows: legs are lines hip -> knee -> foot, feelers are pixel lists.

-------------------------------------------------------------------------------------------------- drawing
local function line(img, x0, y0, x1, y1, c)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    px.put(img, x0, y0, c)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

local function rows(img, part, ox, pal, oy) px.sprite(img, part.rows, ox + part.x, part.y + (oy or 0), pal) end

-- Wings: drawn over what is already there. 'w' the pale margin, 'u' the clear membrane, 'v' a vein. Over the body the
-- wing is mixed with it, so the body shows through; off the body the membrane is mixed with the earth behind.
local function wings(img, part, ox, pal, oy)
  for j, row in ipairs(part.rows) do for i = 1, #row do
    local ch = row:sub(i, i)
    if ch ~= '.' then
      local x, y = ox + part.x + i - 1, part.y + j - 1 + (oy or 0)
      local under = px.get(img, x, y)
      local base = pal[ch]
      if pc.rgbaA(under) > 0 then
        px.put(img, x, y, px.mix(base, hx(under), ({ w = 0.45, u = 0.6, v = 0.5 })[ch]))
      else
        px.put(img, x, y, px.hex(base))
      end
    end
  end end
end

--------------------------------------------------------------------------------------------------- frames
-- tripod A = near front, near rear, far middle; tripod B = the other three. Over four frames A is planted
-- (forward, then back) while B swings lifted, then the other way round.
local STEP = { { 1, false }, { -1, false }, { 0, true }, { 1, true } }

local function frame(K, f, img, fx0)
  local ox = fx0 + K.ox
  local oy = K.oy or 0
  local hipY = K.hipY + oy
  local pal = K.pal
  local ground = K.H - 1
  local walking = f <= 4
  local work = (f == 5 or f == 6) and (f - 4) or nil

  local function legPose(set)                      -- set 'A' or 'B' -> shift, lifted
    if not walking then return 0, false end
    local k = set == 'A' and f or ((f + 1) % 4) + 1
    return STEP[k][1], STEP[k][2]
  end
  local function drawLeg(which, near, set)
    local L = K.legs[which]
    local hipx = ox + K.hips[which]
    local s, lifted = legPose(set)
    local spread = 0
    if not walking and not near then spread = K.farSpread[which] end
    local stride = K.stride or 1
    local kx = hipx + L[1] + s * (K.kneeMove or 1) + spread
    local ky = hipY + L[2] - (lifted and (K.liftKnee or 0) or 0)
    local fx = hipx + L[3] + s * stride + spread
    local fy = ground - (lifted and (K.lift or 1) or 0)
    local c = px.hex(near and pal.l or pal.f)
    if K.farFeet and not near then                -- the far legs show only below the near ones: their feet
      line(img, fx, fy - (K.farFeet - 1), fx, fy, c)
      return
    end
    line(img, hipx, hipY, kx, ky, c)
    line(img, kx, ky, fx, fy, c)
  end

  -- far legs, then near legs, then the body over their hips, then head, feelers and wings
  drawLeg('front', false, 'B'); drawLeg('mid', false, 'A'); drawLeg('rear', false, 'B')
  drawLeg('front', true, 'A'); drawLeg('mid', true, 'B'); drawLeg('rear', true, 'A')
  for _, p in ipairs(K.body) do rows(img, p, ox, pal, oy) end
  local head = work and K.head['work' .. work] or K.head.rest
  rows(img, head, ox, pal, oy)
  local fk = work and ('work' .. work) or (f == 7 and 'still' or ((f % 2 == 1) and 'walkA' or 'walkB'))
  if K.feelFar then
    for _, p in ipairs(K.feelFar[fk]) do px.put(img, ox + p[1], p[2] + oy, px.hex(pal.f)) end
  end
  for _, p in ipairs(K.feel[fk]) do px.put(img, ox + p[1], p[2] + oy, px.hex(pal.a)) end
  if K.wings then wings(img, K.wings, ox, pal, oy) end
end

local function build(K)
  -- centre the body (tail to jaw tip, at rest) in the frame
  K.ox = (K.W - (K.span[2] - K.span[1] + 1)) // 2 - K.span[1]
  local img = px.image(K.W * 7, K.H)
  for f = 1, 7 do
    local one = px.image(K.W, K.H)
    frame(K, f, one, 0)
    px.blit(img, one, (f - 1) * K.W, 0)
  end
  px.save(img, 'art/colony/out/ants/' .. K.name .. '.png')
  return img
end

---------------------------------------------------------------------------------------------------- kinds
-- A worker, 24 x 12. Feet on row 11, legs rows 9-11, body rows 5-8, feelers above.
local function worker(name, pal, opts)
  opts = opts or {}
  local gaster = opts.gaster or { '.kkh.', 'kkkhk', 'kkkkk', '.kkk.' }
  local gx = opts.gx or 0
  return {
    name = name, W = 24, H = 12, pal = pal, kneeMove = 0,
    body = {
      { x = gx, y = 5, rows = gaster },
      { x = 5, y = 7, rows = { 'k' } },                         -- the waist
      { x = 6, y = 6, rows = { '.kk', 'kkk', 'kkk' } },         -- the thorax, higher in front
    },
    head = {                                                    -- neck on row 7 only, jaws below the front
      rest  = { x = 9,  y = 5, rows = { '.kk.', '.kkk', 'kkkk', '...m' } },
      work1 = { x = 9,  y = 6, rows = { '.kk.', '.kkk', 'kkkk', '...mm' } },
      work2 = { x = 9,  y = 7, rows = { '..kk', '.kkkk', '..kkk', '....m' } },
    },
    feel = {                                                    -- scape up from the brow, elbow, whip forward
      walkA = { { 12, 4 }, { 13, 4 }, { 14, 5 }, { 15, 6 } },
      walkB = { { 12, 4 }, { 13, 4 }, { 14, 4 }, { 15, 5 } },
      still = { { 12, 4 }, { 13, 3 }, { 14, 2 }, { 15, 2 }, { 16, 3 } },
      work1 = { { 12, 5 }, { 13, 4 }, { 14, 5 }, { 15, 6 } },
      work2 = { { 13, 6 }, { 14, 5 }, { 15, 6 }, { 15, 7 } },
    },
    hips = { rear = 6, mid = 7, front = 8 }, hipY = 8, oy = 1, farFeet = 1,
    legs = { rear = { -1, 1, -3 }, mid = { 0, 1, -1 }, front = { 1, 1, 2 } },   -- knee dx, knee dy, foot dx
    farSpread = { rear = -1, mid = 1, front = 1 },
    span = { gx, 13 },
  }
end

local LEG = mix(A[2], A[3], 0.2)                         -- legs a touch lighter, so they read on the dark wall
local GROWN = { k = A[1], h = A[3], l = LEG, a = LEG, m = LEG, f = mix(A[1], A[2], 0.2), g = mix(A[1], A[2], 0.5) }
local OLD = { k = mix(A[1], '#000000', 0.25), h = mix(A[3], A[1], 0.4), l = mix(A[2], A[1], 0.25), a = mix(A[2], A[1], 0.25),
              m = mix(A[2], A[1], 0.25), f = mix(A[1], A[2], 0.3), g = A[1] }
-- callow: pale amber-brown, the light of the grown ant lifted towards the colour of a pupa
local YOUNG = { k = mix(A[3], '#a8875a', 0.35), h = '#c2a070', l = mix(A[3], '#a8875a', 0.75), a = mix(A[3], '#a8875a', 0.75),
                m = mix(A[3], '#a8875a', 0.75), f = mix(A[3], A[2], 0.3), g = A[3] }
local RK, RH = '#7a5a14', '#d8b450'
local RIVAL = { k = RK, h = RH, l = mix(RK, RH, 0.4), a = mix(RK, RH, 0.4), m = mix(RK, A[1], 0.3), f = mix(RK, A[1], 0.25),
                d = mix(RK, A[1], 0.45), g = mix(RK, A[1], 0.3) }

local kinds = {}

kinds[#kinds + 1] = worker('young', YOUNG, { gaster = { '.kh.', 'kkhk', 'kkkk', '.kk.' }, gx = 1 })
kinds[#kinds + 1] = worker('grown', GROWN)
kinds[#kinds + 1] = worker('old', OLD, { gaster = { '.kkkh.', 'kkkkhk', 'kkkkkk', '.kkkk.' }, gx = -1 })

-- the raider: same build, banded abdomen
do
  local r = worker('raider', RIVAL, { gaster = { '.kdh.', 'kkdhk', 'kkdkk', '.kdk.' } })
  kinds[#kinds + 1] = r
end

-- the major: a third larger, head as big as its abdomen, heavy jaws. Body rows 3-8, legs rows 9-11.
kinds[#kinds + 1] = {
  name = 'major', W = 24, H = 12, pal = GROWN, kneeMove = 0, farFeet = 2,
  body = {
    { x = 0, y = 4, rows = { '.kkkh.', 'kkkkhk', 'kkkkkk', 'kkkkkk', '.kkkk.' } },
    { x = 6, y = 6, rows = { 'k' } },
    { x = 7, y = 5, rows = { '..kk', '.kkk', 'kkkk', 'kkk.' } },
  },
  head = {
    rest  = { x = 11, y = 3, rows = { '..kkk..', '.kkkkk.', 'kkkkkkm', '.kkkkmm', '..kkk.m' } },
    work1 = { x = 11, y = 4, rows = { '..kkk..', '.kkkkk.', 'kkkkkkm', '.kkkkmm', '..kkk.m' } },
    work2 = { x = 11, y = 5, rows = { '..kkk..', '.kkkkk.', 'kkkkkk.', '.kkkkkm', '..kkkmm', '......m' } },
  },
  feel = {
    walkA = { { 16, 2 }, { 17, 1 }, { 18, 1 }, { 19, 2 } },
    walkB = { { 16, 2 }, { 17, 1 }, { 18, 2 }, { 19, 3 } },
    still = { { 16, 2 }, { 16, 1 }, { 17, 0 }, { 18, 0 }, { 19, 0 } },
    work1 = { { 16, 3 }, { 17, 2 }, { 18, 3 }, { 19, 4 } },
    work2 = { { 16, 4 }, { 17, 3 }, { 18, 4 }, { 19, 5 } },
  },
  hips = { rear = 7, mid = 8, front = 9 }, hipY = 8,
  legs = { rear = { -2, 1, -4 }, mid = { 1, 1, 0 }, front = { 2, 1, 3 } },
  farSpread = { rear = -1, mid = -1, front = 1 },
  span = { 0, 17 },
}

-- queens, 36 x 16, feet on row 15
local function queen(name, pal, gaster)
  return {
    name = name, W = 36, H = 16, pal = pal, stride = 2, lift = 2,
    body = {
      { x = 0, y = 7, rows = gaster },
      { x = 11, y = 9, rows = { 'k', 'k' } },                                     -- the waist
      { x = 12, y = 6, rows = { '..kkk.', '.kkkgk', 'kkkkkk', 'kkkkkk', 'kkkkkk', '.kkkk.' } }, -- broad thorax, wing scar
    },
    head = {
      rest  = { x = 18, y = 6, rows = { '.kkk.', 'kkkkk', '.kkkk', '..kkm', '....m' } },
      work1 = { x = 18, y = 7, rows = { '.kkk.', 'kkkkk', '.kkkk', '..kkm', '....m' } },
      work2 = { x = 18, y = 8, rows = { '.kkk.', 'kkkkk', '.kkkk', '..kkkm', '....mm' } },
    },
    feel = {
      walkA = { { 22, 5 }, { 23, 4 }, { 24, 3 }, { 25, 3 }, { 26, 4 }, { 27, 5 } },
      walkB = { { 22, 5 }, { 23, 4 }, { 24, 3 }, { 25, 4 }, { 26, 5 }, { 27, 6 } },
      still = { { 22, 5 }, { 22, 4 }, { 23, 3 }, { 24, 2 }, { 25, 2 }, { 26, 2 }, { 27, 1 } },
      work1 = { { 22, 6 }, { 23, 5 }, { 24, 5 }, { 25, 6 }, { 26, 7 }, { 26, 8 } },
      work2 = { { 23, 7 }, { 24, 6 }, { 25, 7 }, { 26, 8 }, { 26, 9 }, { 27, 10 } },
    },
    hips = { rear = 13, mid = 15, front = 17 }, hipY = 11,
    legs = { rear = { -3, 1, -6 }, mid = { 1, 1, -1 }, front = { 3, 1, 5 } },
    farSpread = { rear = -2, mid = 2, front = 2 },
    span = { 0, 22 },
  }
end

kinds[#kinds + 1] = queen('queen', GROWN, {
  '...kkkkh...',
  '.kkkgkkhhk.',
  'kkkkgkkgkkk',
  'kkkkgkkgkkk',
  '.kkkgkkgkk.',
  '...kkkkk...' })

-- the princess: between worker and queen, two pairs of wings folded back along her body
local WING = mix('#bdbab0', A[3], 0.15)
kinds[#kinds + 1] = {
  name = 'princess', W = 36, H = 16, pal = setmetatable({ w = WING, u = mix(WING, px.PAL.loam[1], 0.5), v = mix(WING, A[1], 0.55) }, { __index = GROWN }),
  stride = 1, lift = 1,
  body = {
    { x = 0, y = 8, rows = { '..kkkh..', '.kkkkkhk', 'kkkkkkkk', '.kkkkkkk', '..kkkk..' } },
    { x = 8, y = 10, rows = { 'k' } },
    { x = 9, y = 7, rows = { '.kkk.', 'kkkkk', 'kkkkk', 'kkkkk', '.kkk.' } },
  },
  head = {
    rest  = { x = 14, y = 7, rows = { '.kk.', 'kkkk', '.kkk', '...m' } },
    work1 = { x = 14, y = 8, rows = { '.kk.', 'kkkk', '.kkk', '...m' } },
    work2 = { x = 14, y = 9, rows = { '.kk.', 'kkkk', '.kkkm', '....m' } },
  },
  feel = {
    walkA = { { 17, 6 }, { 18, 5 }, { 19, 5 }, { 20, 6 }, { 21, 7 } },
    walkB = { { 17, 6 }, { 18, 5 }, { 19, 6 }, { 20, 7 }, { 21, 7 } },
    still = { { 17, 6 }, { 17, 5 }, { 18, 4 }, { 19, 4 }, { 20, 4 }, { 21, 3 } },
    work1 = { { 17, 7 }, { 18, 6 }, { 19, 7 }, { 20, 8 }, { 20, 9 } },
    work2 = { { 18, 8 }, { 19, 8 }, { 20, 9 }, { 20, 10 }, { 21, 11 } },
  },
  wings = { x = -5, y = 7, rows = {                    -- forewing over hindwing, folded flat, tips past the tail
    '...wwwwwwwwwwwwww',
    '.wwuuvuuuuuvuuuw.',
    'wuuvuuuuuvuuww...',
    '.wwwuuww.........' } },
  hips = { rear = 10, mid = 11, front = 13 }, hipY = 11,
  legs = { rear = { -3, 1, -5 }, mid = { 1, 1, -1 }, front = { 2, 1, 4 } },
  farSpread = { rear = -1, mid = 1, front = 1 },
  span = { -5, 17 },
}

kinds[#kinds + 1] = queen('rival_queen', RIVAL, {
  '...kkdhh...',
  '.kkdkkdhhk.',
  'kkkdkkdkkdk',
  'kkkdkkdkkdk',
  '.kkdkkdkkd.',
  '...dkkdk...' })

print('ok')

------------------------------------------------------------------------------------------------- from above
-- The same ants seen from above, for one walking on the back wall of a tunnel: <kind>_top.png, a row of 5 frames
-- (walk 1-4, still). The ant faces right and is centred in its frame, so the game can turn it to any heading.
-- A body is a chain of ovals along the middle row; legs go out to both sides from the thorax, three a side.
local function oval(img, x0, x1, ry, cy, c, shade)
  local cx, rx = (x0 + x1) / 2, (x1 - x0 + 1) / 2
  for y = math.floor(cy - ry), math.ceil(cy + ry) do for x = x0, x1 do
    local dx, dy = (x - cx) / rx, (y - cy) / (ry + 0.35)
    if dx * dx + dy * dy <= 1 then px.put(img, x, y, shade and shade(x, y) or c) end
  end end
end

local function topFrame(T, f, img)
  local pal, cy, ox = T.pal, T.H // 2, T.ox
  local walking = f <= 4
  local SH = { 1, 0, -1, 0 }
  local sA = walking and SH[f] or 0
  local sB = -sA
  -- legs: hip on the thorax, knee half way out, foot at full reach; the two tripods swing against each other
  local function leg(i, side)
    local L = T.legs[i]
    local s = ((i + (side > 0 and 1 or 0)) % 2 == 0) and sA or sB
    local hx0, hy0 = ox + L[1], cy + side
    local fx, fy = ox + L[1] + L[2] + s * (T.stride or 1), cy + side * T.reach
    local kx, ky = ox + L[1] + (L[2] + s) // 2, cy + side * (T.reach // 2 + 1)
    line(img, hx0, hy0, kx, ky, px.hex(pal.l)); line(img, kx, ky, fx, fy, px.hex(pal.l))
  end
  for i = 1, 3 do leg(i, -1); leg(i, 1) end
  if T.wings then                                    -- folded back over the abdomen, one each side, under the thorax
    for side = -1, 1, 2 do
      oval(img, ox + T.wings[1], ox + T.wings[2], T.wings[3], cy + side * T.wings[4], px.hex(pal.u))
    end
  end
  local g = T.gaster
  oval(img, ox + g[1], ox + g[2], g[3], cy, nil, function(x, y)
    local lx = x - ox
    if T.bands then for _, b in ipairs(T.bands) do if lx == b then return px.hex(pal.d or pal.g) end end end
    if y == cy - 1 and lx > g[1] + 1 and lx < g[2] - 1 then return px.hex(pal.h) end        -- the light along its back
    return px.hex(pal.k)
  end)
  px.put(img, ox + g[2] + 1, cy, px.hex(pal.k))       -- the waist
  local t = T.thorax; oval(img, ox + t[1], ox + t[2], t[3], cy, px.hex(pal.k))
  local h = T.head; oval(img, ox + h[1], ox + h[2], h[3], cy, px.hex(pal.k))
  local jr = math.max(1, math.floor(h[3]))
  px.put(img, ox + h[2] + 1, cy - jr, px.hex(pal.m)); px.put(img, ox + h[2] + 1, cy + jr, px.hex(pal.m))   -- jaws
  if T.heavy then px.put(img, ox + h[2] + 2, cy - jr + 1, px.hex(pal.m)); px.put(img, ox + h[2] + 2, cy + jr - 1, px.hex(pal.m)) end
  -- feelers: out from the brow, elbowed forward; they swing a pixel as it walks
  local n = T.feel or 3
  for side = -1, 1, 2 do
    local w = walking and (((f + (side > 0 and 1 or 0)) % 2 == 0) and 1 or 0) or 0
    for k = 1, n do
      local out = math.min(k, 2) + (k > 2 and w or 0)
      px.put(img, ox + h[2] + k, cy + side * (jr + out), px.hex(pal.a))
    end
  end
end

local function buildTop(T)
  T.ox = (T.W - (T.span[2] - T.span[1] + 1)) // 2 - T.span[1]
  local img = px.image(T.W * 5, T.H)
  for f = 1, 5 do
    local one = px.image(T.W, T.H)
    topFrame(T, f, one)
    px.blit(img, one, (f - 1) * T.W, 0)
  end
  px.save(img, 'art/colony/out/ants/' .. T.name .. '_top.png')
  return img
end

local function workerTop(name, pal, glen, gry, bands)
  return { name = name, W = 24, H = 15, pal = pal, reach = 5, bands = bands,
    gaster = { 0, glen - 1, gry }, thorax = { glen + 1, glen + 3, 1 }, head = { glen + 4, glen + 7, 1.3 },
    legs = { { glen + 1, -3 }, { glen + 2, 0 }, { glen + 3, 3 } }, span = { 0, glen + 10 } }
end
local function queenTop(name, pal, bands)
  return { name = name, W = 36, H = 23, pal = pal, reach = 8, stride = 2, bands = bands, feel = 4,
    gaster = { 0, 10, 3.2 }, thorax = { 12, 17, 2.4 }, head = { 18, 22, 2 },
    legs = { { 13, -5 }, { 15, 0 }, { 17, 5 } }, span = { 0, 26 } }
end
local tops = {
  workerTop('young', YOUNG, 4, 1.3),
  workerTop('grown', GROWN, 5, 1.5),
  workerTop('old', OLD, 6, 1.7),
  workerTop('raider', RIVAL, 5, 1.5, { 2 }),
  { name = 'major', W = 24, H = 15, pal = GROWN, reach = 6, heavy = true, feel = 3,
    gaster = { 0, 5, 2 }, thorax = { 7, 10, 1.4 }, head = { 11, 15, 2.4 },
    legs = { { 7, -4 }, { 9, 0 }, { 10, 3 } }, span = { 0, 18 } },
  queenTop('queen', GROWN, { 4, 7 }),
  { name = 'princess', W = 36, H = 23, pal = setmetatable({ u = mix(WING, px.PAL.loam[1], 0.35) }, { __index = GROWN }), reach = 7, feel = 4,
    gaster = { 0, 7, 2.2 }, thorax = { 9, 13, 2 }, head = { 14, 17, 1.6 }, wings = { -5, 10, 1.3, 3 },
    legs = { { 10, -4 }, { 11, 0 }, { 13, 4 } }, span = { -5, 21 } },
  queenTop('rival_queen', RIVAL, { 3, 6, 9 }),
}
local topItems = {}
for _, T in ipairs(tops) do topItems[#topItems + 1] = { buildTop(T) } end
px.sheet(topItems, 'art/colony/shots/ants-top.png', 6, 1)

-------------------------------------------------------------------------------------------- contact sheet
local items = {}
for _, K in ipairs(kinds) do items[#items + 1] = { build(K) } end
px.sheet(items, 'art/colony/shots/ants.png', 6, 1)
