-- Second round of style proposals for The Lord's Will: four art directions that differ in how things are drawn, not only
-- in colour. People follow STYLE REFERENCE.gif: a small head, a block of a body, legs and arms one pixel wide.
--   Aseprite -b --script-param out=<folder> --script round2.lua
local out = app.params.out or '.'
local pc = app.pixelColor
local N = 10
local W, H, OX, OY = 336, 244, 168, 76

local function hex(s) return pc.rgba(tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16), 255) end
local function hash(x, y)
  local n = (math.floor(x) * 374761393 + math.floor(y) * 668265263) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  return ((n ~ (n >> 16)) % 1000) / 1000
end
local function pick(r, t) local i = math.floor(t * #r) + 1; if i < 1 then i = 1 elseif i > #r then i = #r end; return hex(r[i]) end
local BAYER = { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 }
local function bayer(x, y) return (BAYER[(y % 4) * 4 + (x % 4) + 1] + 0.5) / 16 end
local function flat(c) local v = hex(c); return function() return v end end

local function kind(x, y)
  if y == 5 then return 'road' end
  if x <= 3 and y >= 7 then return 'field' end
  if y == 9 and x >= 5 then return 'water' end
  return 'grass'
end

-- ── A: manuscript. Ink on parchment: almost no fill, shade is hatching, one red for roofs.
local INK, PARCH = '#33291f', '#e9dcbd'
local function hatch(base, ink, step, dir) local b, k = hex(base), hex(ink); return function(px, py) return (px + dir * py) % step == 0 and k or b end end
local A = { id = '1-manuscript', bg = PARCH, outline = true, ink = INK,
  ground = function(k, px, py, x, y)
    if k == 'grass' then
      if hash(px * 3, py * 7) > 0.985 then return hex('#6f7a45') end
      return hex(hash(px // 6, py // 3) > 0.5 and '#e3d6b3' or '#dfd1ac')
    elseif k == 'road' then
      local f = y % 1; if (f < 0.1 or f > 0.9) and px % 3 == 0 then return hex(INK) end
      return hex('#f3ead2')
    elseif k == 'field' then
      local f = (y * 3) % 1
      if f < 0.2 then return hex('#8a6a2c') end
      return (px + py) % 3 == 0 and hex('#b98f32') or hex('#ead9a0')
    else
      if (py + math.floor(math.sin(px / 5) * 1.5)) % 4 == 0 and hash(px // 9, py) > 0.3 then return hex('#3e5a66') end
      return hex('#b9cbc4')
    end
  end,
  house = { h = 15, rise = 18, wallL = flat('#f6efdc'), wallR = hatch('#f6efdc', '#8c7c62', 3, 1), roofL = hatch('#c0573c', '#7a2c1e', 4, -1), roofR = hatch('#a3432c', '#5e2016', 2, 1),
    frame = INK, door = flat(INK), window = flat(INK) },
  stoneL = flat('#f6efdc'), stoneR = hatch('#f6efdc', '#8c7c62', 2, 1), stoneTop = flat('#f6efdc'), wellWater = flat('#3e5a66'), post = INK, wellRoof = hatch('#c0573c', '#7a2c1e', 3, -1),
  tree = function(put, bx, by, r)
    for i = 0, 12 do put(bx, by - i, hex(INK)) end
    for dy = -r, r do for dx = -r, r do
      if dx * dx + dy * dy <= r * r then
        local c = hex('#a9b06e')
        if dx + dy > r * 0.35 and (dx - dy) % 3 == 0 then c = hex('#58652f') end
        if hash(bx + dx, by + dy) > 0.93 then c = hex(INK) end
        put(bx + dx, by - r - 10 + dy, c)
      end
    end end
  end,
  people = { { t = '#33291f', p = '#a9a670' }, { t = '#8f8a5c', p = '#8f8a5c' }, { t = '#33291f', p = '#33291f' } },
  body = { h = '#33291f', f = '#e9dcbd', n = '#33291f', b = '#33291f', l = '#33291f', a = '#6b6446', i = '#a3432c' } }

-- ── B: paper cut. Flat planes, no texture, no outline; cast shadows; steep roofs and cone trees.
local B = { id = '2-papercut', bg = '#f4efe6', outline = false,
  ground = function(k, px, py, x, y)
    if k == 'grass' then return hex((math.floor(x) + math.floor(y)) % 2 == 0 and '#9ad27a' or '#90ca72')
    elseif k == 'road' then return hex('#f0dca8')
    elseif k == 'field' then return hex((y * 2) % 1 < 0.5 and '#f7c948' or '#e9b436')
    else return hex((py // 3 + px // 14) % 4 == 0 and '#a8e2f2' or '#62c4e4') end
  end,
  shadow = '#74b860',
  house = { h = 13, rise = 28, wallL = flat('#fff6e6'), wallR = flat('#e4cfb2'), roofL = flat('#ef6a50'), roofR = flat('#c94a38'), door = flat('#7c4a3c'), window = flat('#4e8fb4') },
  stoneL = flat('#e8e4ee'), stoneR = flat('#b9b3c6'), stoneTop = flat('#f6f4fa'), wellWater = flat('#62c4e4'), post = '#7c4a3c', wellRoof = flat('#ef6a50'),
  tree = function(put, bx, by, r)
    for i = 0, 6 do for j = -1, 0 do put(bx + j, by - i, hex('#7c4a3c')) end end
    local hgt = r * 3
    for i = 0, hgt do
      local half = math.floor((1 - i / hgt) * r + 0.5)
      for dx = -half, half do put(bx + dx, by - 6 - i, hex(dx < 0 and '#3fae6a' or '#2c8a56')) end
    end
  end,
  people = { { t = '#ef6a50', p = '#ef6a50' }, { t = '#4e8fb4', p = '#fff6e6' }, { t = '#f7c948', p = '#f7c948' } },
  body = { h = '#f2c4a0', f = '#f2c4a0', n = '#f2c4a0', b = '#3b4466', l = '#3b4466', a = '#f2c4a0', i = '#7c4a3c' } }

-- ── C: dusk. A dark village, lit from its own windows and lanterns.
local function noise(r, sx, sy, bias) return function(px, py) return pick(r, (bias or 0) + hash(px // sx, py // sy)) end end
local C = { id = '3-dusk', bg = '#0c0e1c', outline = false, glow = true,
  ground = function(k, px, py, x, y)
    if k == 'grass' then return pick({ '#1b3336', '#1f3a3c', '#244242' }, hash(px // 3, py // 2) * 0.7 + hash(px, py) * 0.3)
    elseif k == 'road' then return pick({ '#3c3646', '#443e4e', '#4c4656' }, hash(px // 2, py // 2))
    elseif k == 'field' then return (y * 3) % 1 < 0.28 and hex('#2a2a30') or pick({ '#5c5236', '#6a5e3c', '#786a42' }, hash(px // 2, py))
    else return hash(px // 5, py * 3) > 0.9 and hex('#93a8dc') or pick({ '#16224a', '#1c2c5a' }, hash(px // 6, py)) end
  end,
  house = { h = 15, rise = 18, wallL = noise({ '#4a4460', '#524c68' }, 2, 2), wallR = noise({ '#322e44', '#383248' }, 2, 2), roofL = noise({ '#3c3444', '#463c4c', '#504454' }, 1, 3), roofR = noise({ '#262230', '#2c2636' }, 1, 3),
    frame = '#1c1826', door = flat('#ffc860'), window = flat('#ffe08a') },
  stoneL = noise({ '#4a5068', '#545a72' }, 3, 2), stoneR = noise({ '#30344a', '#363a50' }, 3, 2), stoneTop = flat('#5e6480'), wellWater = flat('#16224a'), post = '#1c1826', wellRoof = noise({ '#3c3444', '#504454' }, 1, 2),
  tree = function(put, bx, by, r)
    for i = 0, 11 do put(bx, by - i, hex('#141820')); put(bx + 1, by - i, hex('#141820')) end
    for _, bl in ipairs({ { 0, -r - 14, r }, { -r * 0.6, -r - 6, r * 0.75 }, { r * 0.6, -r - 7, r * 0.7 } }) do
      for dy = -math.ceil(bl[3]), math.ceil(bl[3]) do for dx = -math.ceil(bl[3]), math.ceil(bl[3]) do
        if dx * dx + dy * dy * 1.25 <= bl[3] * bl[3] then
          put(math.floor(bx + bl[1] + dx), math.floor(by + bl[2] + dy), pick({ '#102426', '#152e30', '#1b3a3a', '#27504c' }, 0.45 - (dx + dy * 1.4) / (bl[3] * 2.6) + (hash(bx + dx, by + dy) - 0.5) * 0.3))
        end
      end end
    end
  end,
  people = { { t = '#7a6f96', p = '#9a8fb6' }, { t = '#8a7a70', p = '#8a7a70' }, { t = '#5f7486', p = '#5f7486' } },
  body = { h = '#b8a898', f = '#b8a898', n = '#b8a898', b = '#221f30', l = '#221f30', a = '#7a6f96', i = '#ffd070' } }

-- ── D: four tones. The olive palette of the reference, everything shaded by ordered dither.
local TONES = { '#141c11', '#636344', '#a4a671', '#e6e8c8' }
local function tone(t, px, py)
  local v = math.max(0, math.min(2.999, t * 3)); local lo = math.floor(v)
  return hex(TONES[lo + ((v - lo) > bayer(px, py) and 2 or 1)])
end
local function dith(t) return function(px, py) return tone(t, px, py) end end
local D = { id = '4-four-tone', bg = '#141c11', outline = true, ink = '#141c11',
  ground = function(k, px, py, x, y)
    if k == 'grass' then return tone(0.52 + (hash(px // 12, py // 6) - 0.5) * 0.22, px, py)
    elseif k == 'road' then return tone(0.9, px, py)
    elseif k == 'field' then return (y * 3) % 1 < 0.3 and hex(TONES[1]) or tone(0.78, px, py)
    else return (py % 3 == 0 and hash(px // 7, py) > 0.45) and hex(TONES[4]) or tone(0.22, px, py) end
  end,
  house = { h = 15, rise = 20, wallL = dith(1), wallR = dith(0.7), roofL = dith(0.42), roofR = dith(0.16), frame = '#141c11', door = flat('#141c11'), window = flat('#141c11') },
  stoneL = dith(0.9), stoneR = dith(0.55), stoneTop = dith(1), wellWater = flat('#141c11'), post = '#141c11', wellRoof = dith(0.4),
  tree = function(put, bx, by, r)
    for i = 0, 11 do put(bx, by - i, hex(TONES[1])); put(bx + 1, by - i, hex(TONES[1])) end
    for _, bl in ipairs({ { 0, -r - 14, r }, { -r * 0.6, -r - 6, r * 0.75 }, { r * 0.6, -r - 7, r * 0.7 } }) do
      for dy = -math.ceil(bl[3]), math.ceil(bl[3]) do for dx = -math.ceil(bl[3]), math.ceil(bl[3]) do
        if dx * dx + dy * dy * 1.25 <= bl[3] * bl[3] then
          local x, y = math.floor(bx + bl[1] + dx), math.floor(by + bl[2] + dy)
          put(x, y, tone(0.32 - (dx + dy * 1.4) / (bl[3] * 3.2), x, y))
        end
      end end
    end
  end,
  people = { { t = '#141c11', p = '#a4a671' }, { t = '#636344', p = '#636344' }, { t = '#141c11', p = '#141c11' } },
  body = { h = '#141c11', f = '#a4a671', n = '#141c11', b = '#141c11', l = '#141c11', a = '#636344', i = '#141c11' } }

local MAN = { '...hhh...', '...hfh...', '...hhh...', '....n....', '.ttttttt.', '.ppppppp.', '.ttttttt.', '.ppppppp.', '.ttttttt.',
  'a.bbbbb.a', 'a.bbbbb.a', 'a.bbbbb.a', 'a.l...l.a', 'i.l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..' }
local WOMAN = { '...hhh...', '...hfh...', '...hhh...', '....n....', '.ttttttt.', '.ppppppp.', '.ttttttt.', '.ppppppp.', '.ttttttt.',
  'a.ttttt.a', 'a.ttttt.a', 'a.ttttt.a', 'a.ttttt.a', 'ittttttt.', '.ttttttt.', 'ttttttttt', 'ttttttttt', '..l...l..', '..l...l..', '..l...l..', '..l...l..', '..l...l..' }

local function draw(S)
  local scene = Image(W, H, ColorMode.RGB)
  local obj = Image(W, H, ColorMode.RGB)
  local lights = {}
  local function P(x, y, z) return OX + (x - y) * 16, OY + (x + y) * 8 - (z or 0) end
  local function put(x, y, c) if x >= 0 and y >= 0 and x < W and y < H then obj:drawPixel(x, y, c) end end
  local function poly(pts, f)
    local lo, hi = math.huge, -math.huge
    for _, p in ipairs(pts) do lo = math.min(lo, p[2]); hi = math.max(hi, p[2]) end
    for py = math.floor(lo), math.ceil(hi) do
      local xs, yc = {}, py + 0.5
      for i = 1, #pts do
        local a, b = pts[i], pts[i % #pts + 1]
        if (a[2] <= yc) ~= (b[2] <= yc) then xs[#xs + 1] = a[1] + (yc - a[2]) / (b[2] - a[2]) * (b[1] - a[1]) end
      end
      table.sort(xs)
      for k = 1, #xs - 1, 2 do for px = math.floor(xs[k] + 0.5), math.floor(xs[k + 1] - 0.5) do put(px, py, f(px, py)) end end
    end
  end
  local function pt(x, y, z) local sx, sy = P(x, y, z); return { sx, sy } end
  local function quad(a, b, c, d, f) poly({ a, b, c, d }, f) end
  local function line(a, b, c)
    local n = math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2]))
    for i = 0, n do local t = n == 0 and 0 or i / n; put(math.floor(a[1] + (b[1] - a[1]) * t + 0.5), math.floor(a[2] + (b[2] - a[2]) * t + 0.5), c) end
  end
  local function commit(plain)
    local ink = S.ink and hex(S.ink)
    for y = 0, H - 1 do for x = 0, W - 1 do
      local c = obj:getPixel(x, y)
      if pc.rgbaA(c) > 0 then
        local edge = false
        if S.outline and not plain then
          for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local nx, ny = x + d[1], y + d[2]
            if nx < 0 or ny < 0 or nx >= W or ny >= H or pc.rgbaA(obj:getPixel(nx, ny)) == 0 then edge = true end
          end
        end
        scene:drawPixel(x, y, edge and ink or c)
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

  local function house(x0, y0, x1, y1, alongX)
    local M, h, rise = S.house, S.house.h, S.house.rise
    local xm, ym = (x0 + x1) / 2, (y0 + y1) / 2
    if S.shadow then add(-1, function() quad(pt(x1, y0), pt(x1 + 1.1, y0 + 0.3), pt(x1 + 1.1, y1 + 0.3), pt(x1, y1), flat(S.shadow)) end, true) end
    add(x1 + y1, function()
      quad(pt(x0, y1, 0), pt(x1, y1, 0), pt(x1, y1, h), pt(x0, y1, h), M.wallL)
      quad(pt(x1, y1, 0), pt(x1, y0, 0), pt(x1, y0, h), pt(x1, y1, h), M.wallR)
      if M.frame then
        local tim = hex(M.frame)
        line(pt(x1, y1, 0), pt(x1, y1, h), tim)
        line(pt(x0, y1, h * 0.55), pt(x1, y1, h * 0.55), tim); line(pt(x1, y1, h * 0.55), pt(x1, y0, h * 0.55), tim)
      end
      quad(pt(xm - 0.22, y1, 0), pt(xm + 0.22, y1, 0), pt(xm + 0.22, y1, h * 0.8), pt(xm - 0.22, y1, h * 0.8), M.door)
      quad(pt(x1, ym + 0.2, h * 0.4), pt(x1, ym - 0.2, h * 0.4), pt(x1, ym - 0.2, h * 0.8), pt(x1, ym + 0.2, h * 0.8), M.window)
      if S.glow then local a, b = pt(xm, y1, 5), pt(x1, ym, 9); lights[#lights + 1] = { a[1] - 4, a[2] + 6, 30 }; lights[#lights + 1] = { b[1] + 5, b[2] + 6, 26 } end
      local e = h - 3
      if alongX then
        poly({ pt(x1, y0, h), pt(x1, y1, h), pt(x1, ym, h + rise) }, M.wallR)
        quad(pt(x0, y1, e), pt(x1, y1, e), pt(x1, ym, h + rise), pt(x0, ym, h + rise), M.roofL)
      else
        poly({ pt(x0, y1, h), pt(x1, y1, h), pt(xm, y1, h + rise) }, M.wallL)
        quad(pt(x1, y1, e), pt(x1, y0, e), pt(xm, y0, h + rise), pt(xm, y1, h + rise), M.roofR)
        quad(pt(x0, y1, h), pt(xm, y1, h + rise), pt(xm, y0, h + rise), pt(x0, y0, h), M.roofL)
      end
    end)
  end

  local function well(x0, y0)
    local a, b, c, d = x0 + 0.55, y0 + 0.55, x0 + 1.45, y0 + 1.45
    if S.shadow then add(-1, function() quad(pt(c, b), pt(c + 0.5, b + 0.15), pt(c + 0.5, d + 0.15), pt(c, d), flat(S.shadow)) end, true) end
    add(c + d, function()
      quad(pt(a, d, 0), pt(c, d, 0), pt(c, d, 8), pt(a, d, 8), S.stoneL)
      quad(pt(c, d, 0), pt(c, b, 0), pt(c, b, 8), pt(c, d, 8), S.stoneR)
      quad(pt(a, b, 8), pt(c, b, 8), pt(c, d, 8), pt(a, d, 8), S.stoneTop)
      quad(pt(a + 0.2, b + 0.2, 8), pt(c - 0.2, b + 0.2, 8), pt(c - 0.2, d - 0.2, 8), pt(a + 0.2, d - 0.2, 8), S.wellWater)
      local tim, ym = hex(S.post), (b + d) / 2
      line(pt(a, ym, 8), pt(a, ym, 24), tim); line(pt(c, ym, 8), pt(c, ym, 24), tim)
      quad(pt(a, ym + 0.3, 22), pt(c, ym + 0.3, 22), pt(c, ym, 29), pt(a, ym, 29), S.wellRoof)
    end)
  end

  local function tree(x, y, r)
    local bx, by = P(x, y); bx, by = math.floor(bx), math.floor(by)
    if S.shadow then add(-1, function() poly({ { bx, by - 2 }, { bx + r * 2, by + r * 0.4 }, { bx, by + 3 } }, flat(S.shadow)) end, true) end
    add(x + y, function() S.tree(put, bx, by, r) end)
  end

  local function person(x, y, rows, look)
    add(x + y, function()
      local bx, by = P(x, y); bx, by = math.floor(bx) - 4, math.floor(by) - #rows + 1
      local L = S.people[look]
      for r, row in ipairs(rows) do for i = 1, #row do
        local ch = row:sub(i, i)
        if ch ~= '.' then put(bx + i - 1, by + r - 1, hex(ch == 't' and L.t or ch == 'p' and L.p or S.body[ch])) end
      end end
      if S.glow then lights[#lights + 1] = { bx, by + 14, 16 } end
    end, true)
  end

  house(2, 2, 4, 4, true)
  house(6, 2, 8, 4, false)
  well(4, 6)
  tree(0.6, 0.6, 11); tree(1.7, 0.4, 9); tree(8.6, 7.4, 11); tree(9.5, 6.6, 9); tree(9.3, 8.4, 10); tree(7.4, 7.9, 8)
  person(5.2, 5.5, MAN, 1); person(7.4, 5.4, WOMAN, 2); person(3.4, 6.4, MAN, 3); person(1.2, 5.5, WOMAN, 1); person(6.1, 5.6, MAN, 2)
  table.sort(things, function(a, b) return a[1] < b[1] end)
  for _, t in ipairs(things) do t[2](); commit(t[3]) end

  if S.glow then
    for y = 0, H - 1 do for x = 0, W - 1 do
      local c = scene:getPixel(x, y)
      if pc.rgbaA(c) > 0 then
        local k = 0
        for _, l in ipairs(lights) do local d = math.sqrt((x - l[1]) ^ 2 + ((y - l[2]) * 2) ^ 2); if d < l[3] then k = k + (1 - d / l[3]) ^ 2 end end
        if k > 0 then
          k = math.min(1, k)
          scene:drawPixel(x, y, pc.rgba(math.min(255, math.floor(pc.rgbaR(c) + k * 120)), math.min(255, math.floor(pc.rgbaG(c) + k * 78)), math.min(255, math.floor(pc.rgbaB(c) + k * 16)), 255))
        end
      end
    end end
  end

  local Z = 3
  local big = Image(W * Z, H * Z, ColorMode.RGB)
  local bg = hex(S.bg)
  for y = 0, H - 1 do for x = 0, W - 1 do
    local c = scene:getPixel(x, y); if pc.rgbaA(c) == 0 then c = bg end
    for j = 0, Z - 1 do for i = 0, Z - 1 do big:drawPixel(x * Z + i, y * Z + j, c) end end
  end end
  big:saveAs(out .. '/' .. S.id .. '.png')
end

for _, S in ipairs({ A, B, C, D }) do draw(S) end
print('done')
