-- people.lua: the figure sheet for The Lord's Will.
--   Aseprite -b --script-param root=<path to art> --script <path to art>/people.lua
-- Output: art/out/people/people.png, a grid of 13 x 24 cells, no gaps.
--   row    = stage * 6 + variant   (stage 0 child, 1 youth, 2 adult, 3 elder; variant 0-2 male, 3-5 female)
--   column = pose * 4 + frame      (pose 0 walk, 1 work the land, 2 stand and talk)
-- Feet stand on the bottom row of the cell, centred on column 6. Light from the left.
-- Also writes art/out/people/preview.png: the sheet x4, once on grass and once on road.
local root = app.params.root
local ink = dofile(root .. '/lib/ink.lua')
local P = ink.P

-- ── colours added for people: the pastel cloths of ink.P taken a step or two darker, so a small figure stands out on
-- pale grass and pale road. Each cloth has a body colour (c) and a shadow colour (s).
local CLOTH = {
  madder = { c = '#a8786a', s = '#835a4e' },
  woad   = { c = '#7d92a8', s = '#5e7086' },
  russet = { c = '#8e7656', s = '#6c583e' },
  weld   = { c = '#bba660', s = '#8f7c44' },
  green  = { c = '#80906a', s = '#606e4e' },
  linen  = { c = '#c2b496', s = '#968670' },
}
local HAIR = { brown = P.hair, dark = '#4e3c30', fair = '#a88c5c', red = '#94603e', grey = P.hairGrey }
local IRON = P.iron
local WOOD = P.woodShadeLine

local CW, CH = 13, 24
local CX = 6

-- ── who is who
-- stage: H total height, head rows, torso rows (tunic, to the thigh), legs rows, body width, arm length,
-- leg columns (offset from centre), belt row (in the torso), arm offset (from centre).
local STAGE = {
  [0] = { H = 13, torso = 5, legs = 5, half = 2, arm = 3, legx = 1, belt = 3, armx = 3 },            -- child
  [1] = { H = 19, torso = 8, legs = 8, half = 2, arm = 5, legx = 2, belt = 4, armx = 3 },            -- youth
  [2] = { H = 22, torso = 10, legs = 9, half = 3, arm = 6, legx = 2, belt = 5, armx = 4 },           -- adult
  [3] = { H = 22, torso = 10, legs = 8, half = 3, arm = 6, legx = 2, belt = 5, armx = 4, stoop = true }, -- elder
}
-- per stage, six variants: cloth, hair, head ('hair', 'hood', 'girl', 'coif', 'veil', 'wimple'), stick
local PEOPLE = {
  [0] = {
    { cloth = 'russet', hair = 'brown', head = 'hair' },
    { cloth = 'green', hair = 'fair', head = 'hair' },
    { cloth = 'woad', hair = 'red', head = 'hair' },
    { cloth = 'madder', hair = 'fair', head = 'girl' },
    { cloth = 'weld', hair = 'brown', head = 'girl' },
    { cloth = 'linen', hair = 'red', head = 'girl' },
  },
  [1] = {
    { cloth = 'green', hair = 'dark', head = 'hair' },
    { cloth = 'madder', hair = 'fair', head = 'hair' },
    { cloth = 'linen', hair = 'brown', head = 'hood', hood = 'russet' },
    { cloth = 'woad', hair = 'brown', head = 'coif' },
    { cloth = 'green', hair = 'red', head = 'coif' },
    { cloth = 'madder', hair = 'dark', head = 'coif' },
  },
  [2] = {
    { cloth = 'woad', hair = 'brown', head = 'hair' },
    { cloth = 'russet', hair = 'dark', head = 'hair' },
    { cloth = 'madder', hair = 'fair', head = 'hood', hood = 'green' },
    { cloth = 'green', hair = 'brown', head = 'veil' },
    { cloth = 'weld', hair = 'brown', head = 'veil' },
    { cloth = 'woad', hair = 'brown', head = 'veil' },
  },
  [3] = {
    { cloth = 'russet', hair = 'grey', head = 'hair', stick = true },
    { cloth = 'linen', hair = 'grey', head = 'hood', hood = 'woad', stick = true },
    { cloth = 'green', hair = 'grey', head = 'hair' },
    { cloth = 'madder', hair = 'grey', head = 'wimple' },
    { cloth = 'russet', hair = 'grey', head = 'wimple', stick = true },
    { cloth = 'woad', hair = 'grey', head = 'wimple' },
  },
}

-- ── the sheet and a cell-local pen
local sheet = ink.sprite(CW * 12, CH * 24)
local OX, OY = 0, 0
local function put(x, y, col)
  if col and x >= 1 and x < CW - 1 and y >= 0 and y < CH then sheet:put(OX + x, OY + y, col) end
end
local function line(x0, y0, x1, y1, col)
  local n = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
  for i = 0, n do local t = n == 0 and 0 or i / n; put(math.floor(x0 + (x1 - x0) * t + 0.5), math.floor(y0 + (y1 - y0) * t + 0.5), col) end
end

-- ── a head: 3 wide, 3 high, its top-left at (x, y). turn: -1 looks left, 1 looks right, 0 front.
local function head(x, y, who, turn)
  local h = HAIR[who.hair]
  local S, V = P.skin, P.veil
  local k = who.head
  local face = { S, S, S }
  if turn == -1 then face = { S, S, h } elseif turn == 1 then face = { h, S, S } end
  if k == 'hair' then
    for i = 0, 2 do put(x + i, y, h) end
    for i = 0, 2 do put(x + i, y + 1, face[i + 1]) end
    put(x + 1, y + 2, S)
  elseif k == 'hood' then
    local c = CLOTH[who.hood]
    for i = 0, 2 do put(x + i, y, c.c) end
    put(x - 1, y + 1, c.c); put(x + 3, y + 1, c.s)
    for i = 0, 2 do put(x + i, y + 1, turn == 0 and S or face[i + 1]) end
    if turn == -1 then put(x + 2, y + 1, c.c) elseif turn == 1 then put(x, y + 1, c.c) end
    put(x - 1, y + 2, c.c); put(x + 1, y + 2, S); put(x + 3, y + 2, c.s); put(x, y + 2, c.c); put(x + 2, y + 2, c.s)
  elseif k == 'girl' then
    for i = 0, 2 do put(x + i, y, h) end
    for i = 0, 2 do put(x + i, y + 1, face[i + 1]) end
    put(x - 1, y + 1, h); put(x + 3, y + 1, h)
    put(x - 1, y + 2, h); put(x + 1, y + 2, S); put(x + 3, y + 2, h)
  elseif k == 'coif' then
    for i = 0, 2 do put(x + i, y, V) end
    for i = 0, 2 do put(x + i, y + 1, face[i + 1] == h and V or face[i + 1]) end
    put(x - 1, y + 1, h); put(x + 3, y + 1, h)
    put(x - 1, y + 2, h); put(x + 1, y + 2, S); put(x + 3, y + 2, h)
  elseif k == 'veil' then
    for i = 0, 2 do put(x + i, y, V) end
    put(x - 1, y + 1, V); put(x + 3, y + 1, V)
    for i = 0, 2 do put(x + i, y + 1, face[i + 1] == h and V or face[i + 1]) end
    put(x - 1, y + 2, V); put(x + 1, y + 2, S); put(x + 3, y + 2, V)
  elseif k == 'wimple' then
    for i = 0, 2 do put(x + i, y, V) end
    put(x - 1, y + 1, V); put(x + 3, y + 1, V)
    for i = 0, 2 do put(x + i, y + 1, face[i + 1] == h and V or face[i + 1]) end
    for i = -1, 3 do put(x + i, y + 2, V) end
  end
end

-- ── standing figure, facing the viewer (walk and talk).
-- o: bob (0 or 1: body one pixel lower), feet { dx, lift } for left and right leg, arms 'down' | 'fwd' | 'back' | 'up'
-- for left and right, turn (head), lean (upper body shifted -1/0/1 for a shift of weight), stick dx.
local function front(who, st, o)
  local male = (who.head == 'hair' or who.head == 'hood')
  local cl = CLOTH[who.cloth]
  local top = CH - st.H + o.bob
  local tT = top + 3                                -- torso top row
  local hipY = tT + st.torso                        -- first leg row
  local hf = st.half
  local ln = o.lean or 0
  -- legs (ink, one pixel), from the hips to the feet on the bottom row
  local lx, rx = CX - st.legx, CX + st.legx
  if male then
    line(lx + ln, hipY, lx + o.lf[1], CH - 1 - o.lf[2], P.ink)
    line(rx + ln, hipY, rx + o.rf[1], CH - 1 - o.rf[2], P.ink)
  end
  -- body
  local bottom = male and hipY - 1 or CH - 2
  for y = tT, bottom do
    local r = y - tT
    local sh = ln
    local h0, h1 = -hf, hf
    if r == 0 then h0, h1 = -hf + 1, hf - 1 end                    -- shoulders
    if not male and y >= CH - 4 then h0, h1 = -hf - 1, hf + 1 end -- the skirt flares at the hem
    if not male and y >= CH - 4 then sh = sh + (o.hem or 0) end
    for x = CX + h0 + sh, CX + h1 + sh do
      local col = cl.c
      if x == CX + h1 + sh then col = cl.s end                     -- shadow side
      if r == st.belt then col = P.ink end                         -- belt
      if male and y == bottom and st.H > 15 then col = cl.s end    -- hem
      if not male and y == CH - 2 then col = cl.s end
      put(x, y, col)
    end
  end
  if not male then                                                 -- shoes under the hem
    if o.lf[2] == 0 then put(lx + o.lf[1], CH - 1, P.ink) end
    if o.rf[2] == 0 then put(rx + o.rf[1], CH - 1, P.ink) end
  end
  -- head
  -- the old are hunched: the head sits a pixel lower, down between the shoulders
  head(CX - 1 + ln, top + (st.stoop and 1 or 0), who, o.turn or 0)
  -- arms: left in shadow cloth, right in ink (it is on the shaded side)
  local aT = tT + 1
  local function arm(side, how, col)
    local ax = CX + side * st.armx + ln
    local L = st.arm
    if how == 'down' then
      line(ax, aT, ax, aT + L - 1, col); put(ax, aT + L, P.skin)
    elseif how == 'fwd' then
      line(ax, aT, ax, aT + L - 2, col); put(ax, aT + L - 1, P.skin)
    elseif how == 'back' then
      line(ax, aT, ax, aT + L - 2, col); put(ax + side, aT + L - 1, col); put(ax + side, aT + L, P.skin)
    elseif how == 'up' then
      line(ax, aT, ax, aT + 2, col); put(ax + side, aT + 1, col); put(ax + side, aT, col); put(ax + side, aT - 1, P.skin)
    end
  end
  if who.stick and st.stoop then
    local sx = CX - st.armx - 1 + (o.stick or 0)
    line(CX - st.armx + ln, aT, sx + 1, aT + st.arm - 1, cl.s)
    put(sx, aT + st.arm, P.skin)
    line(sx, aT + st.arm + 1, sx + (o.stickFoot or 0), CH - 1, WOOD)
  else
    arm(-1, o.la, cl.s)
  end
  arm(1, o.ra, P.ink)
end

-- ── bent at work, in profile facing left: a hoe for men, a sickle for women. f = frame 0..3.
-- The worker stands with the front foot at CX - 2 and the back foot at CX + 2; the hips sit back over the back leg and
-- the back leans forward, so the head comes out in front of the shoulders. Tools are one pixel wide.
local function work(who, st, f)
  local male = (who.head == 'hair' or who.head == 'hood')
  local cl = CLOTH[who.cloth]
  local legs = st.legs - 1                          -- knees a little bent
  local hipY = CH - legs                            -- first leg row
  local fx, bx = CX - 2, CX + 2
  local bob = (f == 2) and 1 or 0                   -- the body dips as the blow lands
  local w = st.half + 2                             -- body thickness seen from the side
  local x0 = CX                                     -- back of the hips at x0 + w - 1
  -- legs
  if male then
    line(x0, hipY + bob, fx, CH - 1, P.ink)
    line(x0 + w - 2, hipY + bob, bx, CH - 1, P.ink)
  else
    put(fx, CH - 1, P.ink); put(bx, CH - 1, P.ink)
  end
  -- below the hips: the tunic's skirt to the thigh, or the long dress to the ankle
  local skirtTop = hipY - 2 + bob
  local skirtEnd = male and hipY - 1 + bob or CH - 2
  for y = skirtTop, skirtEnd do
    local k = y - skirtTop
    local fl = male and 0 or math.min(1, k // 3)
    for x = x0 - fl, x0 + w - 1 + (male and 0 or math.min(1, k // 4)) do
      put(x, y, (x >= x0 + w - 1 or y == skirtEnd) and cl.s or cl.c)
    end
  end
  -- the back: rows from the waist up, each a little further forward. How far it leans changes with the stroke:
  -- nearly upright with the hoe raised, bent right over as it strikes.
  local tr = st.torso - 3
  if st.stoop then tr = tr - 1 end
  local LEAN = male and { [0] = 0.5, [1] = 0.6, [2] = 0.75, [3] = 0.6 } or { [0] = 0.6, [1] = 0.75, [2] = 0.9, [3] = 0.75 }
  local lean = LEAN[f] + (st.stoop and 0.15 or 0)
  local rows = {}
  for r = 0, tr - 1 do
    local y = skirtTop - 1 - r
    local s = math.floor(r * lean + 0.5)
    local a, b = x0 - s, x0 - s + w - 1
    if r == tr - 1 then a = a + 1 end                               -- round the shoulders
    rows[r] = { a = a, b = b, y = y }
  end
  local top = rows[tr - 1]
  local function back()
    for r = 0, tr - 1 do
      local q = rows[r]
      for x = q.a, q.b do put(x, q.y, r == 0 and P.ink or ((x == q.b) and cl.s or cl.c)) end   -- belt on the lowest row
    end
    if st.stoop then put(top.b + 1, top.y + 1, cl.s); put(top.b, top.y - 1, cl.s) end  -- the round back of the old
  end
  -- the head: on top of the shoulders when upright, out in front of them when bent
  local bent = lean >= 0.45
  local hx, hy = top.a - (bent and 3 or 2), top.y - (bent and 1 or 3)
  -- shoulder point and the hands
  local sx, sy = top.a + 1, top.y + 1
  local tool = {}
  local hand
  if st.H < 15 then
    -- children glean: stoop to the stubble, come up with a few ears of corn
    local CORN, STALK = P.cornLine, P.corn2
    local glean = {
      [0] = { hand = { -1, 0 }, px = { { 0, -1, STALK }, { 0, -2, CORN }, { -1, -3, CORN } } },
      [1] = { hand = { -2, 2 }, px = { { -1, 0, STALK }, { -2, -1, CORN } } },
      [2] = { hand = { -2, 4 }, px = { { -1, 1, STALK }, { 0, 1, STALK } } },
      [3] = { hand = { -2, 1 }, px = { { -1, -1, STALK }, { -1, -2, CORN }, { -2, -2, CORN } } },
    }
    local p = glean[f]
    hand = { sx + p.hand[1], math.min(CH - 2, sy + p.hand[2]) }
    tool.px = {}
    for _, q in ipairs(p.px) do tool.px[#tool.px + 1] = { hand[1] + q[1], hand[2] + q[2], q[3] } end
  elseif male then
    local hoe = {
      [0] = { hand = { -2, 0 }, tip = { 3, -8 }, blade = { { -1, 0 }, { -2, 1 } } },
      [1] = { hand = { -2, 1 }, tip = { -4, -6 }, blade = { { -1, 0 }, { -2, 0 } } },
      [2] = { hand = { -2, 3 }, tip = nil, blade = { { 1, 0 }, { 2, 0 } } },
      [3] = { hand = { -2, 2 }, tip = { -6, 6 }, blade = { { 0, 1 }, { 1, 1 } } },
    }
    local p = hoe[f]
    local k = (st.torso + st.legs) / 19                -- a smaller hoe for smaller people
    hand = { sx + p.hand[1], sy + p.hand[2] }
    local tip = p.tip and { sx + math.floor(p.tip[1] * k + 0.5), sy + math.floor(p.tip[2] * k + 0.5) } or { math.max(2, hand[1] - 2), CH - 1 }
    if tip[1] < 2 then tip[1] = 2 end
    if tip[2] < 0 then tip[2] = 0 end
    local dx, dy = tip[1] - hand[1], tip[2] - hand[2]
    local n = math.max(math.abs(dx), math.abs(dy), 1)
    tool.handle = { hand[1] - math.floor(dx / n * 2 + 0.5), hand[2] - math.floor(dy / n * 2 + 0.5), tip[1], tip[2] }
    tool.blade = {}
    for _, b in ipairs(p.blade) do tool.blade[#tool.blade + 1] = { tip[1] + b[1], tip[2] + b[2] } end
  else
    local sick = {
      [0] = { hand = { 0, 1 }, px = { { 0, -1, WOOD }, { -1, -2, IRON }, { -2, -2, IRON }, { -3, -1, IRON } } },
      [1] = { hand = { -1, 3 }, px = { { -1, 0, WOOD }, { -2, -1, IRON }, { -3, -1, IRON }, { -4, 0, IRON } } },
      [2] = { hand = { -2, 5 }, px = { { -1, 1, WOOD }, { -2, 1, IRON }, { -3, 0, IRON }, { -3, -1, IRON } } },
      [3] = { hand = { -1, 3 }, px = { { 0, -1, WOOD }, { 0, -2, IRON }, { -1, -3, IRON }, { -2, -3, IRON } } },
    }
    local p = sick[f]
    hand = { sx + p.hand[1], sy + p.hand[2] }
    tool.px = {}
    for _, q in ipairs(p.px) do tool.px[#tool.px + 1] = { hand[1] + q[1], hand[2] + q[2], q[3] } end
  end
  -- far arm (ink), the tool, the head, then the near arm (shadow cloth) and the hand
  line(sx + 1, sy, hand[1] + 1, hand[2], P.ink)
  back()
  if tool.handle then line(tool.handle[1], tool.handle[2], tool.handle[3], tool.handle[4], WOOD) end
  for _, b in ipairs(tool.blade or {}) do put(b[1], b[2], IRON) end
  for _, q in ipairs(tool.px or {}) do put(q[1], q[2], q[3]) end
  line(sx, sy, hand[1], hand[2], cl.s)
  put(hand[1], hand[2], P.skin)
  head(hx, hy + (st.stoop and 1 or 0), who, -1)
end

-- ── the poses
local WALK = {
  [0] = { bob = 0, lf = { 0, 0 }, rf = { 0, 0 }, la = 'down', ra = 'down' },
  [1] = { bob = 1, lf = { -1, 0 }, rf = { 1, 1 }, la = 'back', ra = 'fwd', hem = -1, stick = -1, stickFoot = -1 },
  [2] = { bob = 0, lf = { 0, 0 }, rf = { 0, 2 }, la = 'down', ra = 'down' },
  [3] = { bob = 1, lf = { -1, 1 }, rf = { 1, 0 }, la = 'fwd', ra = 'back', hem = 1, stick = 0, stickFoot = 0 },
}
local TALK = {
  [0] = { bob = 0, lf = { 0, 0 }, rf = { 0, 0 }, la = 'down', ra = 'down', turn = 0 },
  [1] = { bob = 0, lf = { 0, 0 }, rf = { 0, 0 }, la = 'down', ra = 'down', turn = 0, lean = 1 },
  [2] = { bob = 0, lf = { 0, 0 }, rf = { 0, 0 }, la = 'up', ra = 'down', turn = -1 },
  [3] = { bob = 0, lf = { 0, 0 }, rf = { 0, 0 }, la = 'down', ra = 'fwd', turn = 1 },
}

for stage = 0, 3 do
  local st = STAGE[stage]
  for v = 0, 5 do
    local who = PEOPLE[stage][v + 1]
    local row = stage * 6 + v
    for pose = 0, 2 do
      for f = 0, 3 do
        OX, OY = (pose * 4 + f) * CW, row * CH
        if pose == 0 then front(who, st, WALK[f])
        elseif pose == 1 then work(who, st, f)
        else front(who, st, TALK[f]) end
      end
    end
  end
end

sheet:save(root .. '/out/people/people.png')

-- ── preview: the sheet x4 on grass (left) and on road (right)
local S = 4
local W, H = CW * 12, CH * 24
local pv = Image(W * 2 * S, H * S, ColorMode.RGB)
local g, rd = ink.hex(P.grass), ink.hex(P.road)
local gl = ink.hex('#b8c296')
local pc = app.pixelColor
for y = 0, H * S - 1 do for x = 0, W * 2 * S - 1 do
  local col = x < W * S and g or rd
  local cx, cy = (x % (W * S)) // S, y // S
  if cx % CW == 0 and cy % CH == CH - 1 and x < W * S then col = gl end
  pv:drawPixel(x, y, col)
end end
for half = 0, 1 do
  for y = 0, H - 1 do for x = 0, W - 1 do
    local col = sheet.img:getPixel(x, y)
    if pc.rgbaA(col) > 0 then
      for j = 0, S - 1 do for i = 0, S - 1 do pv:drawPixel((half * W + x) * S + i, y * S + j, col) end end
    end
  end end
end
pv:saveAs(root .. '/out/people/preview.png')
print('ok people ' .. W .. 'x' .. H)
