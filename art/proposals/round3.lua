-- Third round: four takes on an illuminated medieval manuscript, each with its own buildings, trees and ground.
--   Aseprite -b --script-param out=<folder> --script round3.lua
local out = app.params.out or '.'
local pc = app.pixelColor
local N = 10
local W, H, OX, OY = 336, 250, 168, 82
local M = 14                                   -- margin for the border

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

-- ══ 1. Book of hours: lapis, vermilion and gold on a green meadow; tall houses with scaled blue roofs
local S1 = { id = '1-book-of-hours', bg = '#ead9b4', ink = '#2a1c14', border = function(i, t) return (i // 10) % 2 == 0 and (t == 2 and '#c43a2a' or '#e8b83a') or (t == 2 and '#2f55a8' or '#e8b83a') end,
  ground = function(k, px, py, x, y)
    if k == 'grass' then
      local r = hash(px * 5, py * 11)
      if r > 0.992 then return hex('#f4ead0') elseif r > 0.985 then return hex('#d8483a') elseif r > 0.978 then return hex('#e8b83a') end
      return hex(hash(px // 5, py // 3) > 0.45 and '#4f8a4a' or '#447d42')
    elseif k == 'road' then return hex(hash(px // 3, py // 2) > 0.8 and '#c9ad74' or '#dcc48e')
    elseif k == 'field' then return (y * 3) % 1 < 0.22 and hex('#8a5a22') or hex((px + py // 2) % 3 == 0 and '#f2d268' or '#e0b040')
    else return ((py + math.floor(math.sin(px / 4) * 2)) % 5 == 0) and hex('#dfe8f4') or hex(hash(px // 6, py // 2) > 0.5 and '#2b4f9a' or '#274890') end
  end,
  house = function(c, x0, y0, x1, y1, alongX)
    local fl, fr = faces(c, x0, y0, x1, y1); local h, rise = 21, 25
    walls(c, x0, y0, x1, y1, h, flat('#f6ecd2'), flat('#d9c7a2'))
    rect(c, fl, 0, 1, 0, 3, flat('#b9a37a')); rect(c, fr, 0, 1, 0, 3, flat('#9c8862'))
    arch(c, fl, 0.5, 0.13, 0, 9, 4, flat('#c43a2a')); arch(c, fl, 0.5, 0.07, 0, 8, 3, flat('#7a1f18'))
    arch(c, fr, 0.5, 0.09, 9, 14, 3, flat('#1c2a58')); arch(c, fl, 0.82, 0.06, 10, 14, 2, flat('#1c2a58'))
    local a, b = gabled(c, x0, y0, x1, y1, h, rise, alongX, { roofL = scale('#3a66bc', '#1c3270', alongX and 0.5 or -0.5), roofR = scale('#2a4c98', '#132452', -0.5), gableL = flat('#f6ecd2'), gableR = flat('#d9c7a2') })
    c.line(a, b, hex('#e8b83a')); finial(c, a, '#e8b83a'); finial(c, b, '#e8b83a')
  end,
  stoneL = brick('#e9dfc8', '#a8997c', 0.5, 6, 3), stoneR = brick('#cbbd9e', '#8c7d60', -0.5, 6, 3), stoneTop = flat('#f6ecd2'), wellWater = flat('#2b4f9a'), post = '#5a3a22', wellRoof = scale('#c43a2a', '#7a1f18', 0.5),
  tree = function(c, bx, by, r)
    for i = 0, 13 do c.put(bx, by - i, hex('#6a4426')); c.put(bx + 1, by - i, hex('#4a2c18')) end
    c.disc(bx, by - r - 11, r, function(dx, dy) local d = math.sqrt(dx * dx + dy * dy)
      if hash(bx + dx * 3, by + dy * 5) > 0.93 then return hex('#e8b83a') end
      if (math.floor(d) % 4 == 3) and dy > -r * 0.6 then return hex('#1f5a2c') end
      return hex(dx + dy < -r * 0.3 and '#4fa050' or '#33803c') end)
  end,
  people = { { t = '#c43a2a', p = '#e8b83a' }, { t = '#2f55a8', p = '#2f55a8' }, { t = '#f4ead0', p = '#c43a2a' } },
  body = { h = '#2a1c14', f = '#f0c8a4', n = '#f0c8a4', b = '#2a1c14', l = '#2a1c14', a = '#f0c8a4', i = '#e8b83a' } }

-- ══ 2. Romanesque: flat fields of colour, heavy line, round arches, striped low roofs with a little tower
local S2 = { id = '2-romanesque', bg = '#e6d3a3', ink = '#1e1a1a', thick = true, border = function(i, t) return (i // 8) % 2 == 0 and '#a8352a' or '#d9a441' end,
  ground = function(k, px, py, x, y)
    if k == 'grass' then
      local gx, gy = (x * 2) % 1, (y * 2) % 1
      if math.abs(gx - 0.5) < 0.09 and gy > 0.3 and gy < 0.7 and hash(math.floor(x * 2), math.floor(y * 2)) > 0.55 then return hex('#3f6a48') end
      return hex('#a9b36a')
    elseif k == 'road' then return hex('#ecdcb0')
    elseif k == 'field' then return (y * 2) % 1 < 0.16 and hex('#a8352a') or hex('#d9a441')
    else return ((py + math.floor(math.sin(px / 3) * 2.5)) % 6 < 2) and hex('#efe3c0') or hex('#27406a') end
  end,
  house = function(c, x0, y0, x1, y1, alongX)
    local fl, fr = faces(c, x0, y0, x1, y1); local h, rise = 19, 9
    walls(c, x0, y0, x1, y1, h, flat('#efe3c0'), flat('#d9a441'))
    for k = 0, 2 do arch(c, fl, 0.2 + k * 0.3, 0.1, k == 1 and 0 or 5, 10, 4, flat('#27406a')); arch(c, fr, 0.2 + k * 0.3, 0.1, 5, 10, 4, flat('#1e1a1a')) end
    rect(c, fl, 0, 1, h - 3, h, flat('#a8352a')); rect(c, fr, 0, 1, h - 3, h, flat('#7a241c'))
    gabled(c, x0, y0, x1, y1, h, rise, alongX, { roofL = stripe('#a8352a', '#d9a441', 3), roofR = stripe('#7a241c', '#b9862e', 3), gableL = flat('#efe3c0'), gableR = flat('#d9a441') })
    local xm, ym = (x0 + x1) / 2, (y0 + y1) / 2
    local tl, tr = faces(c, xm - 0.3, ym - 0.3, xm + 0.3, ym + 0.3)
    c.quad(tl(0, h + 4), tl(1, h + 4), tl(1, h + 18), tl(0, h + 18), flat('#efe3c0')); c.quad(tr(0, h + 4), tr(1, h + 4), tr(1, h + 18), tr(0, h + 18), flat('#d9a441'))
    arch(c, tl, 0.5, 0.22, h + 9, h + 13, 2, flat('#1e1a1a')); arch(c, tr, 0.5, 0.22, h + 9, h + 13, 2, flat('#1e1a1a'))
    c.poly({ tl(0, h + 18), tl(1, h + 18), c.pt(xm, ym, h + 28) }, flat('#3f6a48')); c.poly({ tr(0, h + 18), tr(1, h + 18), c.pt(xm, ym, h + 28) }, flat('#2a4a34'))
  end,
  stoneL = flat('#efe3c0'), stoneR = flat('#d9a441'), stoneTop = flat('#efe3c0'), wellWater = flat('#27406a'), post = '#1e1a1a', wellRoof = stripe('#a8352a', '#d9a441', 3),
  tree = function(c, bx, by, r)
    for i = 0, 12 do for j = -1, 1 do c.put(bx + j, by - i, hex('#7a241c')) end end
    local q = math.floor(r * 0.62)
    for _, o in ipairs({ { 0, -r - 16 }, { -q, -r - 7 }, { q, -r - 7 } }) do
      c.disc(bx + o[1], by + o[2], q, function(dx, dy) if dx == 0 and dy == 0 or (math.abs(dx) == 2 and dy == 2) then return hex('#a8352a') end; return hex('#3f6a48') end)
    end
  end,
  people = { { t = '#a8352a', p = '#a8352a' }, { t = '#27406a', p = '#efe3c0' }, { t = '#3f6a48', p = '#3f6a48' } },
  body = { h = '#1e1a1a', f = '#efe3c0', n = '#1e1a1a', b = '#1e1a1a', l = '#1e1a1a', a = '#1e1a1a', i = '#d9a441' } }

-- ══ 3. Pen and wash: brown ink drawing with thin washes; timber frames, thatch, chimney smoke
local S3 = { id = '3-pen-and-wash', bg = '#eadfc4', ink = '#4a3524', border = function(i, t) return t == 1 and '#4a3524' or '#eadfc4' end,
  ground = function(k, px, py, x, y)
    if k == 'grass' then
      local r = hash(px * 3, py * 7)
      if r > 0.988 then return hex('#4a3524') elseif r > 0.975 then return hex('#7d8f52') end
      return hex(hash(px // 14, py // 7) > 0.42 and '#cfd6a4' or '#dcd8b2')
    elseif k == 'road' then local f = y % 1; if (f < 0.1 or f > 0.9) and px % 4 < 2 then return hex('#4a3524') end; return hex('#f1e8d0')
    elseif k == 'field' then local f = (y * 3) % 1; if f < 0.16 then return hex('#4a3524') end; return (px % 3 == 0 and f < 0.7) and hex('#a88832') or hex('#ead590')
    else return ((py + math.floor(math.sin(px / 5) * 1.5)) % 4 == 0 and hash(px // 9, py) > 0.3) and hex('#3e5a66') or hex('#bcd0cc') end
  end,
  house = function(c, x0, y0, x1, y1, alongX)
    local fl, fr = faces(c, x0, y0, x1, y1); local h, rise, ink = 16, 18, hex('#4a3524')
    walls(c, x0, y0, x1, y1, h, flat('#f6eeda'), flat('#dfd3b4'))
    for _, f in ipairs({ fl, fr }) do
      for k = 0, 3 do c.line(f(k / 3, 0), f(k / 3, h), ink) end
      c.line(f(0, h * 0.5), f(1, h * 0.5), ink); c.line(f(0, 0), f(1, 0), ink)
      c.line(f(0, h * 0.5), f(1 / 3, h), ink); c.line(f(1, h * 0.5), f(2 / 3, h), ink)
      c.line(f(0, h * 0.5), f(1 / 3, 0), ink); c.line(f(1, h * 0.5), f(2 / 3, 0), ink)
    end
    rect(c, fl, 0.36, 0.64, 0, h * 0.72, flat('#7a5a3a')); rect(c, fr, 0.4, 0.6, h * 0.55, h * 0.85, flat('#4a3524'))
    local thL, thR = hatch('#e2cc86', '#8a6a2c', 5, alongX and -2 or 2), hatch('#c9b06a', '#6e5222', 3, 2)
    local a, b = gabled(c, x0, y0, x1, y1, h, rise, alongX, { roofL = thL, roofR = thR, gableL = flat('#f6eeda'), gableR = flat('#dfd3b4') })
    c.line(a, b, ink)
    local cx, cy = math.floor((a[1] + b[1]) / 2) + 4, math.floor((a[2] + b[2]) / 2)
    for dy = -6, 2 do for dx = 0, 3 do c.put(cx + dx, cy + dy, hex(dx < 2 and '#c9a48a' or '#a07a62')) end end
    for k = 0, 9 do c.put(cx + 2 + math.floor(math.sin(k / 1.6) * 2.4), cy - 9 - k * 2, hex('#9a8f80')); c.put(cx + 3 + math.floor(math.sin(k / 1.6) * 2.4), cy - 10 - k * 2, hex('#9a8f80')) end
  end,
  stoneL = brick('#f6eeda', '#4a3524', 0.5, 6, 3), stoneR = brick('#dfd3b4', '#4a3524', -0.5, 6, 3), stoneTop = flat('#f6eeda'), wellWater = flat('#3e5a66'), post = '#4a3524', wellRoof = hatch('#e2cc86', '#8a6a2c', 4, -2),
  tree = function(c, bx, by, r)
    local ink = hex('#4a3524')
    for i = 0, 14 do c.put(bx, by - i, ink) end
    for i = 0, 5 do c.put(bx - i, by - 9 - i, ink); c.put(bx + i, by - 8 - i, ink) end
    local q = math.max(4, math.floor(r * 0.5))
    for _, o in ipairs({ { -q, -14 }, { q, -13 }, { 0, -18 - q }, { -q - 2, -17 - q }, { q + 2, -16 - q }, { 0, -12 } }) do
      c.disc(bx + o[1], by + o[2] - 2, q, function(dx, dy) local d2 = dx * dx + dy * dy
        if d2 > (q - 1) * (q - 1) and dy >= dx then return ink end
        return hex((dx - dy) % 4 == 0 and dx + dy > 0 and '#6f8448' or '#a9b878') end)
    end
  end,
  people = { { t = '#8a4a3a', p = '#eadfc4' }, { t = '#6e86a0', p = '#6e86a0' }, { t = '#8f9a5c', p = '#8f9a5c' } },
  body = { h = '#4a3524', f = '#eadfc4', n = '#4a3524', b = '#4a3524', l = '#4a3524', a = '#4a3524', i = '#8a4a3a' } }

-- ══ 4. Diapered ground: the patterned gold-and-blue background of court miniatures; white stone towers
local S4 = { id = '4-diaper', bg = '#ead9b4', ink = '#1a1430', border = function(i, t) return t == 2 and (i % 6 == 3 and '#f0c040' or '#22388a') or '#f0c040' end,
  ground = function(k, px, py, x, y)
    local gx, gy = (x * 2) % 1, (y * 2) % 1
    local edge = gx < 0.1 or gy < 0.1
    local dot = math.abs(gx - 0.55) < 0.12 and math.abs(gy - 0.55) < 0.12
    local odd = (math.floor(x * 2) + math.floor(y * 2)) % 2 == 0
    if k == 'grass' then if edge or dot then return hex('#f0c040') end; return hex(odd and '#22388a' or '#2f4aa6')
    elseif k == 'road' then return hex((edge or dot) and '#b8842a' or '#f0c040')
    elseif k == 'field' then if edge or dot then return hex('#f0c040') end; return hex(odd and '#b8382c' or '#cf4a38')
    else return ((py + math.floor(math.sin(px / 3) * 2)) % 5 < 1) and hex('#f6f2e6') or hex('#2f8a8a') end
  end,
  house = function(c, x0, y0, x1, y1, alongX)
    local fl, fr = faces(c, x0, y0, x1, y1); local h = 18
    walls(c, x0, y0, x1, y1, h, brick('#f6f2e6', '#b9b2a2', 0.5), brick('#d4ccba', '#9a927e', -0.5))
    arch(c, fl, 0.5, 0.14, 0, 8, 4, flat('#1a1430')); rect(c, fr, 0.47, 0.53, 6, 13, flat('#1a1430')); rect(c, fl, 0.82, 0.87, 8, 14, flat('#1a1430'))
    c.quad(c.pt(x0, y0, h), c.pt(x1, y0, h), c.pt(x1, y1, h), c.pt(x0, y1, h), flat('#e6dfce'))
    for k = 0, 4 do rect(c, fl, k * 0.22, k * 0.22 + 0.12, h, h + 4, flat('#f6f2e6')); rect(c, fr, k * 0.22, k * 0.22 + 0.12, h, h + 4, flat('#d4ccba')) end
    local xm, ym, q = (x0 + x1) / 2, (y0 + y1) / 2, 0.5
    local a0, b0, a1, b1 = xm - q, ym - q, xm + q, ym + q
    if not alongX then a0, a1 = a0 - 0.2, a1 - 0.2 else b0, b1 = b0 - 0.2, b1 - 0.2 end
    local tl, tr = faces(c, a0, b0, a1, b1)
    c.quad(tl(0, h), tl(1, h), tl(1, h + 14), tl(0, h + 14), brick('#f6f2e6', '#b9b2a2', 0.5)); c.quad(tr(0, h), tr(1, h), tr(1, h + 14), tr(0, h + 14), brick('#d4ccba', '#9a927e', -0.5))
    rect(c, tl, 0.42, 0.58, h + 5, h + 11, flat('#1a1430')); rect(c, tr, 0.42, 0.58, h + 5, h + 11, flat('#1a1430'))
    local top = c.pt((a0 + a1) / 2, (b0 + b1) / 2, h + 34)
    c.poly({ tl(0, h + 13), tl(1, h + 13), top }, flat('#d8483a')); c.poly({ tr(0, h + 13), tr(1, h + 13), top }, flat('#9c2a22'))
    finial(c, top, '#f0c040')
  end,
  stoneL = brick('#f6f2e6', '#b9b2a2', 0.5, 6, 3), stoneR = brick('#d4ccba', '#9a927e', -0.5, 6, 3), stoneTop = flat('#f6f2e6'), wellWater = flat('#2f8a8a'), post = '#f0c040', wellRoof = flat('#d8483a'),
  tree = function(c, bx, by, r)
    for i = 0, 12 do c.put(bx, by - i, hex('#f0c040')); c.put(bx + 1, by - i, hex('#b8842a')) end
    for t = 0, 2 do
      local rr = r - t * 3
      c.disc(bx, by - 12 - t * (r * 0.9), math.max(3, rr), function(dx, dy)
        if dy < -rr * 0.2 and dx < 0 and (dx + dy) % 3 == 0 then return hex('#bfe08a') end
        return hex(dy > rr * 0.3 and '#1f6a3a' or '#34964a') end, 0.55)
    end
  end,
  people = { { t = '#f6f2e6', p = '#d8483a' }, { t = '#f0c040', p = '#f0c040' }, { t = '#d8483a', p = '#d8483a' } },
  body = { h = '#1a1430', f = '#f4d0b0', n = '#f4d0b0', b = '#f6f2e6', l = '#f6f2e6', a = '#f4d0b0', i = '#f0c040' } }

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
        scene:drawPixel(x, y, edge and ink or col)
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
    if x >= 0 and y >= 0 and x < N and y < N then scene:drawPixel(px, py, S.ground(kind(math.floor(x), math.floor(y)), px, py, x, y)) end
  end end

  local things = {}
  local function add(depth, f, plain) things[#things + 1] = { depth, f, plain } end
  local function house(x0, y0, x1, y1, alongX) add(x1 + y1, function() S.house(c, x0, y0, x1, y1, alongX) end) end
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
  local function tree(x, y, r) local bx, by = c.P(x, y); add(x + y, function() S.tree(c, math.floor(bx), math.floor(by), r) end) end
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
    local col = bg
    local sx, sy = x - M, y - M
    if sx >= 0 and sy >= 0 and sx < W and sy < H then local s = scene:getPixel(sx, sy); if pc.rgbaA(s) > 0 then col = s end end
    local d = math.min(x, y, FW - 1 - x, FH - 1 - y)
    if d >= 3 and d <= 9 then
      local along = (d == x or d == FW - 1 - x) and y or x
      if d == 3 or d == 9 then col = ink else col = hex(S.border(along, (d == 4 or d == 8) and 1 or 2)) end
    end
    for j = 0, Z - 1 do for i = 0, Z - 1 do big:drawPixel(x * Z + i, y * Z + j, col) end end
  end end
  big:saveAs(out .. '/' .. S.id .. '.png')
end

for _, S in ipairs({ S1, S2, S3, S4 }) do if not app.params.only or S.id:sub(1, 1) == app.params.only then draw(S) end end
print('done')
