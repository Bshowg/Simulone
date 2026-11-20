-- Style proposals for The Lord's Will. Run with:
--   Aseprite -b --script-param out=<folder> --script proposal.lua
-- Draws the same small scene (ground cell 32 x 16, person 12 x 28) in three styles and saves each as a PNG, enlarged 3x.
local out = app.params.out or '.'
local pc = app.pixelColor
local N = 10
local W, H, OX, OY = 336, 244, 168, 76

local function hex(s) return pc.rgba(tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16), 255) end
local function mul(c, f) return pc.rgba(math.min(255, math.floor(pc.rgbaR(c) * f)), math.min(255, math.floor(pc.rgbaG(c) * f)), math.min(255, math.floor(pc.rgbaB(c) * f)), 255) end
local function hash(x, y)
  local n = (math.floor(x) * 374761393 + math.floor(y) * 668265263) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  return ((n ~ (n >> 16)) % 1000) / 1000
end
local function ramp(r, t) local i = math.floor(t * #r) + 1; if i < 1 then i = 1 elseif i > #r then i = #r end; return hex(r[i]) end

local STYLES = {
  { id = 'A-storybook', outline = 'dark', ink = '#2b1d1a',
    grass = { '#4f8a3a', '#5e9c42', '#6fae4b' }, dirt = { '#a8814f', '#b8925c', '#c7a26b' },
    thatch = { '#a07a30', '#b9943e', '#d0ad4c', '#e4c562' }, wall = { '#bca984', '#d6c6a0', '#eadcb8' }, timber = '#5a3b24',
    stone = { '#6c6863', '#8b867f', '#aaa59c' }, leaf = { '#2a5f30', '#39793a', '#4f9646', '#73b356' }, trunk = '#5e4128',
    wheat = { '#b98a28', '#d4aa38', '#ecc850' }, furrow = '#7a5a34', water = { '#3b6f9a', '#4a86b4', '#74a8cc' },
    skin = '#e8b890', hair = { '#5a3a22', '#c9a04a', '#3a2a22' }, tunic = { '#a8483a', '#3f6a8c', '#6b8a3c' }, legs = '#5b4a3a', shoe = '#33261e' },
  { id = 'B-muted', outline = 'none', ink = '#2a2622',
    grass = { '#657a4b', '#738653', '#82935c' }, dirt = { '#8a765b', '#998567', '#a89475' },
    thatch = { '#7a683e', '#8f7b4a', '#a69058', '#bca76b' }, wall = { '#a3957c', '#bbad93', '#d0c4ab' }, timber = '#4b3a2e',
    stone = { '#66676b', '#7e7f84', '#97989c' }, leaf = { '#34503a', '#436245', '#567650', '#6f8c5d' }, trunk = '#4f3d2e',
    wheat = { '#a88a40', '#bfa150', '#d4b866' }, furrow = '#6e5a40', water = { '#4a6578', '#5a788c', '#7b97a8' },
    skin = '#d9b193', hair = { '#4a3528', '#a58a55', '#332a26' }, tunic = { '#8c5146', '#4f6577', '#6c7a4c' }, legs = '#584c40', shoe = '#342c26' },
  { id = 'C-crisp', outline = 'self', ink = '#2a2233',
    grass = { '#479150', '#5cad58', '#79c466' }, dirt = { '#b07850', '#c68f62', '#dea873' },
    thatch = { '#c08a2c', '#dba63c', '#f0c24e', '#fbdc74' }, wall = { '#b9c2d0', '#dde3ea', '#fafafa' }, timber = '#3e2c3a',
    stone = { '#56647f', '#8493aa', '#b0bccd' }, leaf = { '#235a40', '#35803f', '#57b24c', '#93d868' }, trunk = '#5a3a34',
    wheat = { '#e09a20', '#f6c038', '#fee468' }, furrow = '#8a5a3a', water = { '#2f6fb0', '#3f93d0', '#8ccbee' },
    skin = '#f0c0a0', hair = { '#6a3a2a', '#f0c050', '#2e2630' }, tunic = { '#d04a48', '#3a78c0', '#6aa838' }, legs = '#4a4458', shoe = '#262030' },
}

-- what each ground cell is
local function kind(x, y)
  if y == 5 then return 'road' end
  if x <= 3 and y >= 7 then return 'field' end
  if y == 9 and x >= 5 then return 'water' end
  return 'grass'
end

local function draw(S)
  local scene = Image(W, H, ColorMode.RGB)
  local obj = Image(W, H, ColorMode.RGB)
  local function P(x, y, z) return OX + (x - y) * 16, OY + (x + y) * 8 - (z or 0) end
  local function put(img, x, y, c) if x >= 0 and y >= 0 and x < W and y < H then img:drawPixel(x, y, c) end end

  -- fill a polygon given as { {x,y}, ... } with colour function f(px, py)
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
      for k = 1, #xs - 1, 2 do
        for px = math.floor(xs[k] + 0.5), math.floor(xs[k + 1] - 0.5) do put(obj, px, py, f(px, py)) end
      end
    end
  end
  local function quad(a, b, c, d, f) poly({ a, b, c, d }, f) end
  local function pt(x, y, z) local sx, sy = P(x, y, z); return { sx, sy } end
  local function line(a, b, c)
    local n = math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2]))
    for i = 0, n do local t = n == 0 and 0 or i / n; put(obj, math.floor(a[1] + (b[1] - a[1]) * t + 0.5), math.floor(a[2] + (b[2] - a[2]) * t + 0.5), c) end
  end

  -- move what was drawn on `obj` to the scene, with the style's outline
  local function commit(outer)
    local ink = hex(S.ink)
    for y = 0, H - 1 do for x = 0, W - 1 do
      local c = obj:getPixel(x, y)
      local solid = pc.rgbaA(c) > 0
      local edge = false
      if S.outline ~= 'none' and (solid ~= (outer == true)) then
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
          local nx, ny = x + d[1], y + d[2]
          local n = (nx < 0 or ny < 0 or nx >= W or ny >= H) and 0 or pc.rgbaA(obj:getPixel(nx, ny))
          if (n > 0) ~= solid then edge = true end
        end
      end
      if solid then
        if edge and not outer then scene:drawPixel(x, y, S.outline == 'dark' and ink or mul(c, 0.55)) else scene:drawPixel(x, y, c) end
      elseif edge and outer then scene:drawPixel(x, y, ink) end
    end end
    obj:clear()
  end

  -- ── ground
  for py = 0, H - 1 do for px = 0, W - 1 do
    local u, v = (px + 0.5 - OX) / 16, (py + 0.5 - OY) / 8
    local x, y = (u + v) / 2, (v - u) / 2
    if x >= 0 and y >= 0 and x < N and y < N then
      local k, c = kind(math.floor(x), math.floor(y))
      local n = hash(px // 3, py // 2) * 0.6 + hash(px, py) * 0.4
      if k == 'grass' then
        c = ramp(S.grass, n)
        if hash(px * 7, py * 13) > 0.965 then c = hex(S.leaf[3]) end
      elseif k == 'road' then
        c = ramp(S.dirt, n); local f = y % 1; if f < 0.12 or f > 0.88 then c = mul(c, 0.88) end
      elseif k == 'field' then
        local f = (y * 3) % 1
        c = f < 0.28 and hex(S.furrow) or ramp(S.wheat, hash(px // 2, py) * 0.7 + (f - 0.28) * 0.4)
      else
        c = ramp(S.water, hash(px // 5, py) * 0.5 + 0.15); if hash(px // 4, py * 3) > 0.9 then c = hex(S.water[3]) end
      end
      scene:drawPixel(px, py, c)
    end
  end end

  -- ── things that stand on it, each with a depth to sort by
  local things = {}
  local function add(depth, f, outer) things[#things + 1] = { depth, f, outer } end

  local function house(x0, y0, x1, y1, h, rise, alongX)
    add(x1 + y1, function()
      local wallL = function(px, py) return ramp(S.wall, 0.55 + hash(px // 2, py // 2) * 0.45) end
      local wallR = function(px, py) return ramp(S.wall, hash(px // 2, py // 2) * 0.5) end
      local tim = hex(S.timber)
      quad(pt(x0, y1, 0), pt(x1, y1, 0), pt(x1, y1, h), pt(x0, y1, h), wallL)
      quad(pt(x1, y1, 0), pt(x1, y0, 0), pt(x1, y0, h), pt(x1, y1, h), wallR)
      -- timber frame
      line(pt(x0, y1, 0), pt(x0, y1, h), tim); line(pt(x1, y1, 0), pt(x1, y1, h), tim); line(pt(x1, y0, 0), pt(x1, y0, h), tim)
      line(pt(x0, y1, h * 0.55), pt(x1, y1, h * 0.55), tim); line(pt(x1, y1, h * 0.55), pt(x1, y0, h * 0.55), tim)
      -- door on the left face, window on the right
      local door = function() return mul(tim, 0.8) end
      local xm = (x0 + x1) / 2
      quad(pt(xm - 0.22, y1, 0), pt(xm + 0.22, y1, 0), pt(xm + 0.22, y1, h * 0.8), pt(xm - 0.22, y1, h * 0.8), door)
      local ym = (y0 + y1) / 2
      quad(pt(x1, ym + 0.2, h * 0.45), pt(x1, ym - 0.2, h * 0.45), pt(x1, ym - 0.2, h * 0.8), pt(x1, ym + 0.2, h * 0.8), function() return mul(tim, 0.6) end)
      local e = h - 3
      local thL = function(px, py) return ramp(S.thatch, 0.45 + hash(px, py // 3) * 0.55) end
      local thR = function(px, py) return ramp(S.thatch, hash(px, py // 3) * 0.5) end
      if alongX then
        quad(pt(x1, y0, h), pt(x1, y1, h), pt(x1, ym, h + rise), pt(x1, ym, h + rise), wallR)                 -- gable
        line(pt(x1, y1, h), pt(x1, ym, h + rise), tim); line(pt(x1, y0, h), pt(x1, ym, h + rise), tim)
        quad(pt(x0, y1, e), pt(x1, y1, e), pt(x1, ym, h + rise), pt(x0, ym, h + rise), thL)
        line(pt(x0, ym, h + rise), pt(x1, ym, h + rise), mul(hex(S.thatch[1]), 0.8))
      else
        quad(pt(x0, y1, h), pt(x1, y1, h), pt(xm, y1, h + rise), pt(xm, y1, h + rise), wallL)
        line(pt(x0, y1, h), pt(xm, y1, h + rise), tim); line(pt(x1, y1, h), pt(xm, y1, h + rise), tim)
        quad(pt(x1, y1, e), pt(x1, y0, e), pt(xm, y0, h + rise), pt(xm, y1, h + rise), thR)
        quad(pt(x0, y1, h), pt(xm, y1, h + rise), pt(xm, y0, h + rise), pt(x0, y0, h), thL)
        line(pt(xm, y0, h + rise), pt(xm, y1, h + rise), mul(hex(S.thatch[1]), 0.8))
      end
    end)
  end

  local function well(x0, y0)
    local a, b, c, d = x0 + 0.55, y0 + 0.55, x0 + 1.45, y0 + 1.45
    add(c + d, function()
      local sL = function(px, py) return ramp(S.stone, 0.5 + hash(px // 3, py // 2) * 0.5) end
      local sR = function(px, py) return ramp(S.stone, hash(px // 3, py // 2) * 0.5) end
      quad(pt(a, d, 0), pt(c, d, 0), pt(c, d, 8), pt(a, d, 8), sL)
      quad(pt(c, d, 0), pt(c, b, 0), pt(c, b, 8), pt(c, d, 8), sR)
      quad(pt(a, b, 8), pt(c, b, 8), pt(c, d, 8), pt(a, d, 8), function() return hex(S.stone[3]) end)
      quad(pt(a + 0.2, b + 0.2, 8), pt(c - 0.2, b + 0.2, 8), pt(c - 0.2, d - 0.2, 8), pt(a + 0.2, d - 0.2, 8), function() return hex(S.water[1]) end)
      local tim, ym = hex(S.timber), (b + d) / 2
      line(pt(a, ym, 8), pt(a, ym, 24), tim); line(pt(c, ym, 8), pt(c, ym, 24), tim)
      quad(pt(a, ym + 0.3, 22), pt(c, ym + 0.3, 22), pt(c, ym, 29), pt(a, ym, 29), function(px, py) return ramp(S.thatch, 0.5 + hash(px, py // 2) * 0.5) end)
    end)
  end

  local function tree(x, y, r)
    add(x + y, function()
      local bx, by = P(x, y)
      bx, by = math.floor(bx), math.floor(by)
      for i = 0, 11 do for j = -1, 1 do put(obj, bx + j, by - i, j == 1 and mul(hex(S.trunk), 0.75) or hex(S.trunk)) end end
      local blobs = { { 0, -r - 14, r }, { -r * 0.6, -r - 6, r * 0.75 }, { r * 0.6, -r - 7, r * 0.7 } }
      for _, bl in ipairs(blobs) do
        for dy = -math.ceil(bl[3]), math.ceil(bl[3]) do for dx = -math.ceil(bl[3]), math.ceil(bl[3]) do
          if dx * dx + dy * dy * 1.25 <= bl[3] * bl[3] then
            local lit = 0.5 - (dx + dy * 1.4) / (bl[3] * 2.6) + (hash(bx + dx + bl[1], by + dy) - 0.5) * 0.35
            put(obj, math.floor(bx + bl[1] + dx), math.floor(by + bl[2] + dy), ramp(S.leaf, lit))
          end
        end end
      end
    end)
  end

  local MAN = {
    '....hhhh....', '...hhhhhh...', '...hhhhhh...', '...hsssss...', '...sssess...', '...ssssss...', '....ssss....',
    '....tttt....', '...tttttt...', '..dttttttd..', '..dttttttd..', '..dttttttd..', '..dttttttd..', '..dttttttd..',
    '..dbbbbbbd..', '..stttttts..', '...tttttt...', '...tttttt...', '...tttttt...',
    '...ll..ll...', '...ll..ll...', '...ll..ll...', '...ll..ll...', '...ll..ll...', '...ll..ll...', '...ll..ll...',
    '...oo..oo...', '..ooo..ooo..' }
  local WOMAN = {
    '....hhhh....', '...hhhhhh...', '..hhhhhhhh..', '..hhsssssh..', '..hsssessh..', '..hssssssh..', '..h.ssss.h..',
    '....tttt....', '...tttttt...', '..dttttttd..', '..dttttttd..', '..dttttttd..', '..dttttttd..', '..dttttttd..',
    '..dbbbbbbd..', '..stttttts..', '...tttttt...', '...tttttt...', '..tttttttt..',
    '..tttttttt..', '..tttttttt..', '..tttttttt..', '..tttttttt..', '.tttttttttt.', '.tttttttttt.', '.tttttttttt.',
    '...oo..oo...', '............' }
  local SMAN = { '..hhhh..', '..hhhh..', '..sses..', '..ssss..', '...tt...', '..tttt..', '.dttttd.', '.dttttd.', '.dttttd.', '.dbbbbd.', '.stttts.', '..tttt..',
    '..l..l..', '..l..l..', '..l..l..', '..l..l..', '..l..l..', '.oo..oo.' }
  local SWOMAN = { '..hhhh..', '.hhhhhh.', '.hssesh.', '.hssssh.', '...tt...', '..tttt..', '.dttttd.', '.dttttd.', '.dttttd.', '.dbbbbd.', '.stttts.', '..tttt..',
    '.tttttt.', '.tttttt.', '.tttttt.', '.tttttt.', '.tttttt.', '..o..o..' }
  if app.params.small then MAN, WOMAN = SMAN, SWOMAN end
  local function person(x, y, rows, look)
    add(x + y, function()
      local bx, by = P(x, y); local pw = #rows[1]; bx, by = math.floor(bx) - pw // 2, math.floor(by) - #rows + 1
      local t = hex(S.tunic[look])
      local col = { h = hex(S.hair[look]), s = hex(S.skin), e = hex(S.ink), t = t, d = mul(t, 0.78), b = mul(t, 0.55), l = hex(S.legs), o = hex(S.shoe) }
      for r, row in ipairs(rows) do for i = 1, pw do
        local ch = row:sub(i, i)
        if ch ~= '.' then
          local c = col[ch]
          if (ch == 't' or ch == 's' or ch == 'h' or ch == 'l') and i > pw * 0.6 then c = mul(c, 0.86) end
          put(obj, bx + i - 1, by + r - 1, c)
        end
      end end
    end, true)
  end

  house(2, 2, 4, 4, 15, 18, true)
  house(6, 2, 8, 4, 15, 18, false)
  well(4, 6)
  tree(0.6, 0.6, 11); tree(1.7, 0.4, 9); tree(8.6, 7.4, 11); tree(9.5, 6.6, 9); tree(9.3, 8.4, 10); tree(7.4, 7.9, 8)
  person(5.2, 5.5, MAN, 1); person(7.4, 5.4, WOMAN, 2); person(3.4, 6.4, MAN, 3); person(1.2, 5.5, WOMAN, 1)
  table.sort(things, function(a, b) return a[1] < b[1] end)
  for _, t in ipairs(things) do t[2](); commit(t[3]) end

  -- enlarge 3x and save
  local Z = 3
  local big = Image(W * Z, H * Z, ColorMode.RGB)
  local bg = hex(S.outline == 'none' and '#22241f' or '#1c1a1e')
  for y = 0, H - 1 do for x = 0, W - 1 do
    local c = scene:getPixel(x, y); if pc.rgbaA(c) == 0 then c = bg end
    for j = 0, Z - 1 do for i = 0, Z - 1 do big:drawPixel(x * Z + i, y * Z + j, c) end end
  end end
  big:saveAs(out .. '/' .. S.id .. '.png')
  scene:saveAs(out .. '/' .. S.id .. '-1x.png')
end

for _, S in ipairs(STYLES) do if app.params.small then S.id = S.id .. '-small' end; if not app.params.only or S.id:sub(1, 1) == app.params.only then draw(S) end end
print('done')
