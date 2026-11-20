-- Fourth round: four pen-and-paper takes (built from round3.lua and round4.styles.lua).
--   Aseprite -b --script-param out=<folder> --script round4.lua
local out = app.params.out or '.'
local pc = app.pixelColor
local N = 10
local W, H, OX, OY = 336, 250, 168, 82
local M = 6                                   -- margin for the border

local function hex(s) return pc.rgba(tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16), 255) end
local function hash(x, y)
  local n = (math.floor(x) * 374761393 + math.floor(y) * 668265263) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  return ((n ~ (n >> 16)) % 1000) / 1000
end
local function flat(c) local v = hex(c); return function() return v end end
-- patterns that follow a wall or roof: s is the slope of its long edge on screen (0.5 for left faces, -0.5 for right)
local function brick(base, ln, s, bw, bh) local b, k = hex(base), hex(ln); bw = bw or 8; bh = bh or 4
  return function(px, py) local v = math.floor(py - s * px); local row = v // bh; return (v % bh == 0 or (px + (row % 2) * (bw // 2)) % bw == 0) and k or b end end
local function scale(base, ln, s) local b, k = hex(base), hex(ln)
  return function(px, py) local v = math.floor(py - s * px); local row = v // 3; local q = (px + (row % 2) * 2) % 4
    return (v % 3 == 0 and q ~= 0) and b or ((v % 3 == 2 or q == 0) and k or b) end end
local function stripe(a, b2, w) local ca, cb = hex(a), hex(b2); return function(px) return (px // w) % 2 == 0 and ca or cb end end
local function hatch(base, ink, step, dir) local b, k = hex(base), hex(ink); return function(px, py) return (px + dir * py) % step == 0 and k or b end end

local function kind(x, y)
  if y == 5 then return 'road' end
  if x <= 3 and y >= 7 then return 'field' end
  if y == 9 and x >= 5 then return 'water' end
  return 'grass'
end

-- ── shared building parts
local function faces(c, x0, y0, x1, y1)
  return function(u, z) return c.pt(x0 + (x1 - x0) * u, y1, z) end, function(u, z) return c.pt(x1, y1 - (y1 - y0) * u, z) end
end
local function rect(c, f, u0, u1, z0, z1, col) c.quad(f(u0, z0), f(u1, z0), f(u1, z1), f(u0, z1), col) end
local function arch(c, f, uc, hw, z0, zs, rz, col)
  local pts = { f(uc - hw, z0), f(uc + hw, z0) }
  for k = 0, 8 do local a = math.pi * k / 8; pts[#pts + 1] = f(uc + hw * math.cos(a), zs + rz * math.sin(a)) end
  c.poly(pts, col)
end
local function walls(c, x0, y0, x1, y1, h, L, R)
  c.quad(c.pt(x0, y1, 0), c.pt(x1, y1, 0), c.pt(x1, y1, h), c.pt(x0, y1, h), L)
  c.quad(c.pt(x1, y1, 0), c.pt(x1, y0, 0), c.pt(x1, y0, h), c.pt(x1, y1, h), R)
end
local function gabled(c, x0, y0, x1, y1, h, rise, alongX, m)
  local xm, ym, e = (x0 + x1) / 2, (y0 + y1) / 2, h - 3
  if alongX then
    if rise < 13 * (y1 - y0) / 2 then c.quad(c.pt(x0, y0, h), c.pt(x1, y0, h), c.pt(x1, ym, h + rise), c.pt(x0, ym, h + rise), m.roofR) end
    c.poly({ c.pt(x1, y0, h), c.pt(x1, y1, h), c.pt(x1, ym, h + rise) }, m.gableR)
    c.quad(c.pt(x0, y1, e), c.pt(x1, y1, e), c.pt(x1, ym, h + rise), c.pt(x0, ym, h + rise), m.roofL)
    return c.pt(x0, ym, h + rise), c.pt(x1, ym, h + rise)
  else
    if rise < 13 * (x1 - x0) / 2 then c.quad(c.pt(x0, y1, h), c.pt(xm, y1, h + rise), c.pt(xm, y0, h + rise), c.pt(x0, y0, h), m.roofL) end
    c.poly({ c.pt(x0, y1, h), c.pt(x1, y1, h), c.pt(xm, y1, h + rise) }, m.gableL)
    c.quad(c.pt(x1, y1, e), c.pt(x1, y0, e), c.pt(xm, y0, h + rise), c.pt(xm, y1, h + rise), m.roofR)
    return c.pt(xm, y0, h + rise), c.pt(xm, y1, h + rise)
  end
end
local function finial(c, p, col) for dy = -3, 0 do c.put(p[1], p[2] + dy - 1, hex(col)) end; for dx = -1, 1 do for dy = -1, 1 do c.put(p[1] + dx, p[2] - 5 + dy, hex(col)) end end end

-- ── more shared parts for the pen-and-paper round
local function paper(base, dark, speck) local b, d, s = hex(base), hex(dark), hex(speck)
  return function(x, y) if hash(x * 7, y * 13) > 0.993 then return s end; return (hash(x // 11, y // 6) + hash(x // 23 + 5, y // 13 + 3)) > 1.3 and d or b end end
-- short pen strokes lying along a roof or wall (s: slope of its long edge on screen)
local function strokes(base, ink, s, gap, len, dens) local b, k = hex(base), hex(ink)
  return function(px, py) local v = math.floor(py - s * px); return (v % gap == 0 and hash(px // len, v) > (dens or 0.35)) and k or b end end
local function lattice(base, ink, step) local b, k = hex(base), hex(ink); return function(px, py) return ((px + py) % step == 0 or (px - py) % step == 0) and k or b end end
local function hip(c, x0, y0, x1, y1, h, rise, alongX, L, R)
  local xm, ym, e, d = (x0 + x1) / 2, (y0 + y1) / 2, h - 3, 0.55
  if alongX then
    c.quad(c.pt(x0, y1, e), c.pt(x1, y1, e), c.pt(x1 - d, ym, h + rise), c.pt(x0 + d, ym, h + rise), L)
    c.poly({ c.pt(x1, y1, e), c.pt(x1, y0, e), c.pt(x1 - d, ym, h + rise) }, R)
    return c.pt(x0 + d, ym, h + rise), c.pt(x1 - d, ym, h + rise)
  else
    c.quad(c.pt(x1, y1, e), c.pt(x1, y0, e), c.pt(xm, y0 + d, h + rise), c.pt(xm, y1 - d, h + rise), R)
    c.poly({ c.pt(x0, y1, e), c.pt(x1, y1, e), c.pt(xm, y1 - d, h + rise) }, L)
    return c.pt(xm, y0 + d, h + rise), c.pt(xm, y1 - d, h + rise)
  end
end
local function smoke(c, a, b, col)
  local cx, cy = math.floor((a[1] + b[1]) / 2) + 3, math.floor((a[2] + b[2]) / 2)
  for k = 0, 11 do local x = cx + math.floor(math.sin(k / 1.7) * 2.6 + 0.5); c.put(x, cy - 3 - k * 2, hex(col)); c.put(x + 1, cy - 4 - k * 2, hex(col)) end
  return cx, cy
end
local function wave(px, py, period, gap) return (py + math.floor(math.sin(px / period) * 1.6)) % gap == 0 end

-- ══ 1. Quill sketch: one brown ink, no colour at all. Shade is hatching. Cruck longhouses: more roof than wall.
local P1 = '#e8dcc0'
local S1 = { id = '1-quill-sketch', bg = P1, ink = '#3b2a1c', ink2 = '#6a5236', paper = paper(P1, '#e2d5b6', '#b9a27c'),
  ground = function(k, px, py, x, y)
    if k == 'grass' then local r = hash(px * 3, py * 7); if r > 0.992 or (r > 0.984 and hash(px * 3 - 3, py * 7) > 0.984) then return hex('#3b2a1c') end
    elseif k == 'road' then local f = y % 1; if (f < 0.08 or f > 0.92) and px % 5 < 3 then return hex('#3b2a1c') end; if hash(px * 5, py * 3) > 0.985 then return hex('#6a5236') end
    elseif k == 'field' then local f = (y * 3) % 1; if f < 0.14 then return hex('#3b2a1c') end; if f > 0.4 and f < 0.75 and px % 4 == 0 and hash(px, py // 2) > 0.4 then return hex('#6a5236') end
    else if wave(px, py, 5, 4) and hash(px // 8, py) > 0.25 then return hex('#3b2a1c') end end
  end,
  house = function(c, x0, y0, x1, y1, alongX)
    local fl, fr = faces(c, x0, y0, x1, y1); local h, rise = 7, 25
    walls(c, x0, y0, x1, y1, h, function(px) return hex(px % 4 == 0 and '#6a5236' or P1) end, hatch(P1, '#3b2a1c', 3, 1))
    local door = alongX and fr or fl
    local a, b = gabled(c, x0, y0, x1, y1, h, rise, alongX, { roofL = strokes(P1, '#3b2a1c', alongX and 0.5 or -0.5, 3, 3, 0.45), roofR = strokes(P1, '#3b2a1c', -0.5, 2, 2, 0.2),
      gableL = function(px) return hex(px % 4 == 0 and '#6a5236' or P1) end, gableR = hatch(P1, '#3b2a1c', 3, 1) })
    arch(c, door, 0.5, 0.13, 0, 8, 4, flat('#3b2a1c'))
    c.line(a, b, hex('#3b2a1c')); smoke(c, a, b, '#6a5236')
  end,
  stoneL = brick(P1, '#6a5236', 0.5, 6, 3), stoneR = hatch(P1, '#3b2a1c', 3, 1), stoneTop = flat(P1), wellWater = hatch(P1, '#3b2a1c', 2, 1), post = '#3b2a1c', wellRoof = strokes(P1, '#3b2a1c', 0.5, 2, 2, 0.3),
  tree = function(c, bx, by, r)
    local ink = hex('#3b2a1c')
    for i = 0, 13 do c.put(bx, by - i, ink) end
    for i = 0, 4 do c.put(bx - i, by - 9 - i, ink); c.put(bx + i, by - 8 - i, ink) end
    c.disc(bx, by - r - 10, r, function(dx, dy)
      if dx + dy > r * 0.3 and (dx - dy) % 3 == 0 then return ink end
      if hash(bx + dx * 3, by + dy * 5) > 0.95 then return hex('#6a5236') end
      return hex(P1) end)
  end,
  people = { { t = '#3b2a1c', p = P1 }, { t = '#6a5236', p = '#6a5236' }, { t = '#3b2a1c', p = '#3b2a1c' } },
  body = { h = '#3b2a1c', f = P1, n = '#3b2a1c', b = '#3b2a1c', l = '#3b2a1c', a = '#3b2a1c', i = '#6a5236' } }

-- ══ 2. Sepia wash: ink line with tonal washes of one brown, and washed shadows. Stone cottages with hipped thatch.
local P2 = '#eadfc6'
local S2 = { id = '2-sepia-wash', bg = P2, ink = '#3a2a20', ink2 = '#5a4634', paper = paper(P2, '#e4d7ba', '#bfa987'), shadow = '#c7b58e',
  ground = function(k, px, py, x, y)
    if k == 'grass' then if hash(px * 3, py * 7) > 0.99 then return hex('#5a4634') end; if hash(px // 13, py // 7) + hash(px // 29 + 3, py // 15) > 0.85 then return hex('#ddcfac') end
    elseif k == 'road' then local f = y % 1; if (f < 0.08 or f > 0.92) and px % 4 < 2 then return hex('#3a2a20') end
    elseif k == 'field' then local f = (y * 3) % 1; if f < 0.14 then return hex('#3a2a20') end; return hex(f < 0.5 and '#b89f72' or '#cdb88c')
    else if wave(px, py, 5, 4) then return hex(hash(px // 7, py) > 0.5 and '#3a2a20' or P2) end; return hex('#a8926a') end
  end,
  house = function(c, x0, y0, x1, y1, alongX)
    local fl, fr = faces(c, x0, y0, x1, y1); local h, rise = 13, 15
    walls(c, x0, y0, x1, y1, h, brick('#f3ead4', '#8f7650', 0.5, 6, 3), brick('#c9b388', '#5a4634', -0.5, 6, 3))
    rect(c, fl, 0.38, 0.62, 0, h * 0.8, flat('#5a4634')); rect(c, fr, 0.4, 0.6, h * 0.45, h * 0.8, flat('#3a2a20'))
    local a, b = hip(c, x0, y0, x1, y1, h, rise, alongX, strokes('#cdb88c', '#5a4634', 0.5, 3, 3, 0.4), strokes('#8f7650', '#3a2a20', -0.5, 3, 2, 0.4))
    c.line(a, b, hex('#3a2a20'))
    local cx, cy = smoke(c, a, b, '#a8926a')
    for dy = -5, 2 do for dx = -2, 1 do c.put(cx + dx, cy + dy, hex(dx < 0 and '#f3ead4' or '#b89f72')) end end
  end,
  stoneL = brick('#f3ead4', '#8f7650', 0.5, 6, 3), stoneR = brick('#c9b388', '#5a4634', -0.5, 6, 3), stoneTop = flat('#f3ead4'), wellWater = flat('#5a4634'), post = '#3a2a20', wellRoof = strokes('#cdb88c', '#5a4634', 0.5, 3, 3, 0.4),
  tree = function(c, bx, by, r)
    local ink = hex('#3a2a20')
    for i = 0, 14 do c.put(bx, by - i, ink) end
    for i = 0, 5 do c.put(bx - i, by - 9 - i, ink); c.put(bx + i, by - 8 - i, ink) end
    local q = math.max(4, math.floor(r * 0.5))
    for _, o in ipairs({ { -q, -14 }, { q, -13 }, { 0, -18 - q }, { -q - 2, -17 - q }, { q + 2, -16 - q }, { 0, -12 } }) do
      c.disc(bx + o[1], by + o[2] - 2, q, function(dx, dy)
        if dx * dx + dy * dy > (q - 1) * (q - 1) and dy >= dx then return ink end
        return hex(dx + dy > 1 and '#8f7650' or '#cdb88c') end)
    end
  end,
  people = { { t = '#5a4634', p = '#eadfc6' }, { t = '#b89f72', p = '#b89f72' }, { t = '#8f7650', p = '#8f7650' } },
  body = { h = '#3a2a20', f = '#eadfc6', n = '#3a2a20', b = '#3a2a20', l = '#3a2a20', a = '#3a2a20', i = '#8f7650' } }

-- ══ 3. Watercolour: a light, loose ink line over clear washes that do not quite stay inside it. Plastered cottages.
local P3 = '#f1e9d6'
local S3 = { id = '3-watercolour', bg = P3, ink = '#54433a', ink2 = '#8a7668', paper = paper(P3, '#ece3cd', '#d2c2a4'), shadow = '#a9bd8c', loose = true,
  ground = function(k, px, py, x, y)
    if k == 'grass' then
      local n = hash(px // 9, py // 5) + hash(px // 21 + 7, py // 11 + 2)
      if n < 0.38 then return nil end
      if hash(px * 3, py * 7) > 0.992 then return hex('#d8605a') end
      return hex(n > 1.25 and '#a3c07a' or '#bcd392')
    elseif k == 'road' then return hex(hash(px // 7, py // 4) > 0.7 and '#e3d2a6' or '#eddfb8')
    elseif k == 'field' then local f = (y * 3) % 1; if f < 0.16 then return hex('#b8862e') end; return hex(hash(px // 5, py // 3) > 0.6 and '#f3d77c' or '#ecc85c')
    else if wave(px, py, 6, 5) then return hex(hash(px // 9, py) > 0.55 and '#f6f2e6' or '#5f97b8') end; return hex(hash(px // 11, py // 4) > 0.5 and '#9cc6da' or '#8bbbd2') end
  end,
  house = function(c, x0, y0, x1, y1, alongX)
    local fl, fr = faces(c, x0, y0, x1, y1); local h, rise = 15, 18
    walls(c, x0, y0, x1, y1, h, flat('#fbf6ea'), flat('#d5d0d2'))
    rect(c, fl, 0.38, 0.62, 0, h * 0.75, stripe('#5f9090', '#4c7a7c', 2)); rect(c, fr, 0.38, 0.62, h * 0.4, h * 0.8, flat('#4a5a70'))
    rect(c, fr, 0.3, 0.38, h * 0.4, h * 0.8, flat('#5f9090')); rect(c, fr, 0.62, 0.7, h * 0.4, h * 0.8, flat('#5f9090'))
    for k = 0, 9 do local u = 0.05 + k * 0.1; if u < 0.36 or u > 0.64 then local p = fl(u, 1); c.put(p[1], p[2], hex(k % 2 == 0 and '#d8605a' or '#e8a0b0')); c.put(p[1], p[2] + 1, hex('#7fa860')) end end
    local a, b = gabled(c, x0, y0, x1, y1, h, rise, alongX, { roofL = strokes('#eac468', '#b8862e', alongX and 0.5 or -0.5, 4, 4, 0.5), roofR = strokes('#c99a46', '#8a6424', -0.5, 3, 3, 0.45), gableL = flat('#fbf6ea'), gableR = flat('#d5d0d2') })
    local cx, cy = smoke(c, a, b, '#b9b4b0')
    for dy = -6, 2 do for dx = -2, 1 do c.put(cx + dx, cy + dy, hex(dx < 0 and '#dba48c' or '#b97f68')) end end
  end,
  stoneL = flat('#eeeae6'), stoneR = flat('#c4c0c8'), stoneTop = flat('#fbf6ea'), wellWater = flat('#8bbbd2'), post = '#7a5a40', wellRoof = strokes('#eac468', '#b8862e', 0.5, 4, 4, 0.5),
  treePlain = true,
  tree = function(c, bx, by, r)
    local ink = hex('#54433a')
    for i = 0, 13 do c.put(bx, by - i, hex('#8a6a50')); c.put(bx + 1, by - i, ink) end
    local cy = by - r - 10
    c.disc(bx, cy, r, function(dx, dy) local n = hash((bx + dx) // 3, (by + dy) // 2); return hex(dx + dy > r * 0.4 and '#6f9c5a' or (n > 0.6 and '#a8cc80' or '#8fb96c')) end)
    for k = 0, 71 do
      local a = k / 72 * math.pi * 2
      if hash(bx + k, by) > 0.28 then c.put(bx + 2 + math.cos(a) * (r + (k % 9 < 2 and -1 or 0)), cy - 1 + math.sin(a) * r, ink) end
    end
  end,
  people = { { t = '#c9604e', p = '#f1e9d6' }, { t = '#6f93b8', p = '#6f93b8' }, { t = '#e0b450', p = '#e0b450' } },
  body = { h = '#54433a', f = '#f1d4bc', n = '#f1d4bc', b = '#54433a', l = '#54433a', a = '#54433a', i = '#8a6a50' } }

-- ══ 4. Two inks: black for the drawing, red for what matters (roofs, doors, clothes), as a scribe rubricates. Wattle walls.
local P4 = '#ece5d0'
local S4 = { id = '4-two-inks', bg = P4, ink = '#24211f', ink2 = '#3c3835', paper = paper(P4, '#e6dec6', '#c4b89a'),
  ground = function(k, px, py, x, y)
    if k == 'grass' then if hash(px * 3, py * 7) > 0.975 and (px + py) % 2 == 0 then return hex('#24211f') end
    elseif k == 'road' then local f = y % 1; if f < 0.07 or f > 0.93 then return hex('#24211f') end
    elseif k == 'field' then local f = (y * 3) % 1; if f < 0.14 then return hex('#b03a2a') end; if f > 0.45 and f < 0.7 and px % 3 == 0 then return hex('#24211f') end
    else if wave(px, py, 4, 3) then return hex('#24211f') end end
  end,
  house = function(c, x0, y0, x1, y1, alongX)
    local fl, fr = faces(c, x0, y0, x1, y1); local h, rise = 14, 21
    walls(c, x0, y0, x1, y1, h, lattice(P4, '#8a8478', 5), lattice(P4, '#24211f', 3))
    rect(c, fl, 0, 1, 0, 2, flat('#24211f')); rect(c, fr, 0, 1, 0, 2, flat('#24211f'))
    arch(c, fl, 0.5, 0.14, 0, 8, 3, flat('#b03a2a')); rect(c, fr, 0.4, 0.6, h * 0.45, h * 0.8, flat('#24211f'))
    local a, b = gabled(c, x0, y0, x1, y1, h, rise, alongX, { roofL = scale(P4, '#b03a2a', alongX and 0.5 or -0.5), roofR = hatch('#b03a2a', P4, 3, 1), gableL = lattice(P4, '#8a8478', 5), gableR = lattice(P4, '#24211f', 3) })
    c.line(a, b, hex('#24211f')); finial(c, a, '#24211f'); finial(c, b, '#24211f')
  end,
  stoneL = brick(P4, '#24211f', 0.5, 6, 3), stoneR = lattice(P4, '#24211f', 3), stoneTop = flat(P4), wellWater = flat('#24211f'), post = '#24211f', wellRoof = scale(P4, '#b03a2a', 0.5),
  tree = function(c, bx, by, r)
    local ink = hex('#24211f')
    for i = 0, 12 do c.put(bx, by - i, ink); c.put(bx + 1, by - i, ink) end
    local q = math.floor(r * 0.62)
    for _, o in ipairs({ { 0, -r - 15 }, { -q, -r - 7 }, { q, -r - 7 } }) do
      c.disc(bx + o[1], by + o[2], q, function(dx, dy)
        if (dx % 4 == 0 and dy % 4 == 2) then return hex('#b03a2a') end
        if dx + dy > q * 0.5 and (dx - dy) % 2 == 0 then return ink end
        return hex(P4) end)
    end
  end,
  people = { { t = '#24211f', p = '#b03a2a' }, { t = '#b03a2a', p = '#b03a2a' }, { t = '#24211f', p = '#24211f' } },
  body = { h = '#24211f', f = P4, n = '#24211f', b = '#24211f', l = '#24211f', a = '#24211f', i = '#b03a2a' } }

local MAN = { '...hhh...', '...hfh...', '...hhh...', '....n....', '.ttttttt.', '.ppppppp.', '.ttttttt.', '.ppppppp.', '.ttttttt.',
  'a.bbbbb.a', 'a.bbbbb.a', 'a.bbbbb.a', 'a.l...l.a', 'i.l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..' }
local WOMAN = { '...hhh...', '...hfh...', '...hhh...', '....n....', '.ttttttt.', '.ppppppp.', '.ttttttt.', '.ppppppp.', '.ttttttt.',
  'a.ttttt.a', 'a.ttttt.a', 'a.ttttt.a', 'a.ttttt.a', 'ittttttt.', '.ttttttt.', 'ttttttttt', 'ttttttttt', '..l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..' }

local function draw(S)
  local scene = Image(W, H, ColorMode.RGB)
  local obj = Image(W, H, ColorMode.RGB)
  local c = {}
  function c.P(x, y, z) return OX + (x - y) * 16, OY + (x + y) * 8 - (z or 0) end
  function c.put(x, y, col) x, y = math.floor(x), math.floor(y); if x >= 0 and y >= 0 and x < W and y < H then obj:drawPixel(x, y, col) end end
  function c.poly(pts, f)
    local lo, hi = math.huge, -math.huge
    for _, p in ipairs(pts) do lo = math.min(lo, p[2]); hi = math.max(hi, p[2]) end
    for py = math.floor(lo), math.ceil(hi) do
      local xs, yc = {}, py + 0.5
      for i = 1, #pts do
        local a, b = pts[i], pts[i % #pts + 1]
        if (a[2] <= yc) ~= (b[2] <= yc) then xs[#xs + 1] = a[1] + (yc - a[2]) / (b[2] - a[2]) * (b[1] - a[1]) end
      end
      table.sort(xs)
      for k = 1, #xs - 1, 2 do for px = math.floor(xs[k] + 0.5), math.floor(xs[k + 1] - 0.5) do c.put(px, py, f(px, py)) end end
    end
  end
  function c.pt(x, y, z) local sx, sy = c.P(x, y, z); return { sx, sy } end
  function c.quad(a, b, d, e, f) c.poly({ a, b, d, e }, f) end
  function c.line(a, b, col)
    local n = math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2]))
    for i = 0, n do local t = n == 0 and 0 or i / n; c.put(math.floor(a[1] + (b[1] - a[1]) * t + 0.5), math.floor(a[2] + (b[2] - a[2]) * t + 0.5), col) end
  end
  function c.disc(cx, cy, r, f, squash)
    for dy = -r, r do for dx = -r, r do if dx * dx + dy * dy * (squash and 1 / squash or 1) <= r * r + 1 then c.put(cx + dx, cy + dy, f(dx, dy)) end end end
  end
  local function commit(plain)
    local ink = hex(S.ink)
    for y = 0, H - 1 do for x = 0, W - 1 do
      local col = obj:getPixel(x, y)
      if pc.rgbaA(col) > 0 then
        local edge = false
        if not plain then
          for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local nx, ny = x + d[1], y + d[2]
            if nx < 0 or ny < 0 or nx >= W or ny >= H or pc.rgbaA(obj:getPixel(nx, ny)) == 0 then edge = true end
          end
        end
        if edge and S.loose and hash(x * 3, y * 5) > 0.82 then edge = false end
        scene:drawPixel(x, y, edge and (S.ink2 and hash(x // 2, y // 2) > 0.75 and hex(S.ink2) or ink) or col)
      elseif S.thick and not plain then
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
          local nx, ny = x + d[1], y + d[2]
          if nx >= 0 and ny >= 0 and nx < W and ny < H and pc.rgbaA(obj:getPixel(nx, ny)) > 0 then scene:drawPixel(x, y, ink); break end
        end
      end
    end end
    obj:clear()
  end

  for py = 0, H - 1 do for px = 0, W - 1 do
    local u, v = (px + 0.5 - OX) / 16, (py + 0.5 - OY) / 8
    local x, y = (u + v) / 2, (v - u) / 2
    if x >= 0 and y >= 0 and x < N and y < N then
      -- the edges between kinds of ground wobble, as a hand would draw them
      local jx, jy = x + math.sin(py / 3.1 + px / 7) * 0.05 + math.sin(px / 2.3) * 0.03, y + math.sin(px / 4.3 + py / 5) * 0.05 + math.sin(py / 1.9) * 0.03
      local g = S.ground(kind(math.floor(jx), math.floor(jy)), px, py, jx, jy)
      if g then scene:drawPixel(px, py, g) end
    end
  end end

  local things = {}
  local function add(depth, f, plain) things[#things + 1] = { depth, f, plain } end
  local function house(x0, y0, x1, y1, alongX)
    if S.shadow then add(-1, function() c.quad(c.pt(x1, y0), c.pt(x1 + 0.9, y0 + 0.25), c.pt(x1 + 0.9, y1 + 0.25), c.pt(x1, y1), flat(S.shadow)) end, true) end
    add(x1 + y1, function() S.house(c, x0, y0, x1, y1, alongX) end)
  end
  local function well(x0, y0)
    local a, b, e, d = x0 + 0.55, y0 + 0.55, x0 + 1.45, y0 + 1.45
    add(e + d, function()
      walls(c, a, b, e, d, 8, S.stoneL, S.stoneR)
      c.quad(c.pt(a, b, 8), c.pt(e, b, 8), c.pt(e, d, 8), c.pt(a, d, 8), S.stoneTop)
      c.quad(c.pt(a + 0.2, b + 0.2, 8), c.pt(e - 0.2, b + 0.2, 8), c.pt(e - 0.2, d - 0.2, 8), c.pt(a + 0.2, d - 0.2, 8), S.wellWater)
      local tim, ym = hex(S.post), (b + d) / 2
      c.line(c.pt(a, ym, 8), c.pt(a, ym, 24), tim); c.line(c.pt(e, ym, 8), c.pt(e, ym, 24), tim)
      c.quad(c.pt(a, ym + 0.3, 22), c.pt(e, ym + 0.3, 22), c.pt(e, ym, 29), c.pt(a, ym, 29), S.wellRoof)
    end)
  end
  local function tree(x, y, r)
    local bx, by = c.P(x, y); bx, by = math.floor(bx), math.floor(by)
    if S.shadow then add(-1, function() c.poly({ { bx, by - 2 }, { bx + r * 1.8, by + r * 0.35 }, { bx, by + 3 } }, flat(S.shadow)) end, true) end
    add(x + y, function() S.tree(c, bx, by, r) end, S.treePlain)
  end
  local function person(x, y, rows, look)
    add(x + y, function()
      local bx, by = c.P(x, y); bx, by = math.floor(bx) - 4, math.floor(by) - #rows + 1
      local L = S.people[look]
      for r, row in ipairs(rows) do for i = 1, #row do
        local ch = row:sub(i, i)
        if ch ~= '.' then c.put(bx + i - 1, by + r - 1, hex(ch == 't' and L.t or ch == 'p' and L.p or S.body[ch])) end
      end end
    end, true)
  end

  house(2, 2, 4, 4, true)
  house(6, 2, 8, 4, false)
  well(4, 6)
  tree(0.6, 0.6, 11); tree(1.7, 0.4, 9); tree(8.6, 7.4, 11); tree(9.5, 6.6, 9); tree(9.3, 8.4, 10); tree(7.4, 7.9, 8)
  person(5.2, 5.5, MAN, 1); person(7.4, 5.4, WOMAN, 2); person(3.4, 6.4, MAN, 3); person(1.2, 5.5, WOMAN, 1); person(6.1, 5.6, MAN, 2)
  table.sort(things, function(a, b) return a[1] < b[1] end)
  for _, t in ipairs(things) do t[2](); commit(t[3]) end

  -- the page: margin, border, then 3x
  local FW, FH, Z = W + M * 2, H + M * 2, 3
  local big = Image(FW * Z, FH * Z, ColorMode.RGB)
  local bg, ink = hex(S.bg), hex(S.ink)
  for y = 0, FH - 1 do for x = 0, FW - 1 do
    local col = S.paper and S.paper(x, y) or bg
    local sx, sy = x - M, y - M
    if sx >= 0 and sy >= 0 and sx < W and sy < H then local s = scene:getPixel(sx, sy); if pc.rgbaA(s) > 0 then col = s end end
    for j = 0, Z - 1 do for i = 0, Z - 1 do big:drawPixel(x * Z + i, y * Z + j, col) end end
  end end
  big:saveAs(out .. '/' .. S.id .. '.png')
end

for _, S in ipairs({ S1, S2, S3, S4 }) do if not app.params.only or S.id:sub(1, 1) == app.params.only then draw(S) end end
print('done')
