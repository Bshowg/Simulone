-- WAR's figures and ground, shared by the art scripts in art/war/ (sheet.lua, strike.lua). Load it with:
--   local F = dofile(app.params.root .. '/art/war/lib/figures.lua')
-- A figure is a grid of letters, one per material; a style turns the letters into pixels (render). The game uses the
-- Chronicle style (art/war/STYLE.md); the others are kept from the proposals it was chosen among.
local W = dofile(app.params.root .. '/art/war/lib/wpx.lua')
local KINDS = { 'levy', 'spear', 'sword', 'archer', 'rider' }

-- ───────────────────────── the styles ─────────────────────────
-- Each letter of a figure is a material; a style gives each material a ramp (dark, mid, light) per realm.
local STYLES = {
  A = { name = 'heraldic', geo = 'chunky', shade = 'flat', outline = '#2a201b',
    common = { k = { '#c8865e', '#e8a87a', '#f4c49a' }, a = { '#5a3a22', '#6e4a2c', '#82593a' }, e = { '#2a201b', '#2a201b', '#2a201b' },
      h = { '#7c8794', '#a8b2bc', '#d4dae0' }, i = { '#5e6874', '#7c8794', '#a8b2bc' }, w = { '#6a4224', '#8a5a32', '#a87444' },
      s = { '#b8c4cc', '#e2eaee', '#ffffff' }, b = { '#3a2a20', '#4a3626', '#5a4430' }, q = { '#6a4a2a', '#8a6236', '#a87c46' },
      n = { '#7a4424', '#9a5a30', '#b8743e' }, N = { '#5a3018', '#6e3c20', '#7a4424' }, m = { '#2e1e14', '#3e2a1c', '#4e3624' },
      f = { '#fff6c8', '#fff6c8', '#fff6c8' }, x = { '#a8201a', '#c8281c', '#e03a2a' }, u = { '#a8946a', '#c4ae80', '#dcc89a' },
      g = { '#2f6a2a', '#3e8a34', '#58a844' }, G = { '#4a3018', '#5e3c1e', '#704828' } },
    side = {
      { t = { '#22407a', '#2f58a4', '#4a76c4' }, d = { '#18284a', '#22385e', '#2c4874' }, l = { '#2f58a4', '#3a68b8', '#4a76c4' }, r = { '#d8d2c0', '#f4f0e4', '#ffffff' }, c = { '#e8e4d4', '#f8f6ee', '#ffffff' } },
      { t = { '#8a2418', '#b23224', '#d04a34' }, d = { '#5a1a12', '#6e2216', '#82301e' }, l = { '#c4961e', '#e0b42c', '#f0cc4a' }, r = { '#e0b42c', '#f0cc4a', '#fae07a' }, c = { '#9a2418', '#b23224', '#c43a28' } } },
    ground = { grass = { '#4e8a34', '#5a9a3c' }, field = { '#c8a83a', '#d8b84a' }, stream = { '#2e6aa8', '#3a7ec0' }, ford = { '#7aa8c4', '#8ab8d0' }, hill = { '#7a9a48', '#86a852' }, bg = '#1f2618' } },
  B = { name = 'chronicle', geo = 'slim', shade = 'rich', grain = true,
    common = { k = { '#8a5e44', '#a8785a', '#c09070' }, a = { '#3a2a1e', '#4a3626', '#5a4430' }, e = { '#2a1e16', '#2a1e16', '#2a1e16' },
      h = { '#4a4e52', '#6a6e72', '#8e9296' }, i = { '#3e4246', '#565a5e', '#72767a' }, w = { '#3e2c1e', '#54402a', '#6a5236' },
      s = { '#7a8084', '#a0a6a8', '#c4c8c8' }, b = { '#241a14', '#30241a', '#3c2e22' }, q = { '#4a3826', '#5e4832', '#725a3e' },
      n = { '#4e3220', '#64422c', '#7a5438' }, N = { '#3a2418', '#4a3020', '#5a3c28' }, m = { '#1e1610', '#2a1e16', '#36281e' },
      f = { '#d8ccb0', '#e8dcc0', '#f4ead0' }, x = { '#4e1610', '#6a1e16', '#842a1e' }, u = { '#6e604a', '#86765c', '#9c8c70' },
      g = { '#24361c', '#2e4422', '#3a522a' }, G = { '#30241a', '#3e2e20', '#4a3828' } },
    side = {
      { t = { '#323c48', '#46525e', '#5c6876' }, d = { '#22282e', '#2c343c', '#38424c' }, l = { '#4a5664', '#5c6a7a', '#6e7e8e' }, r = { '#9a948a', '#b4ae9e', '#c8c2b0' }, c = { '#a8a292', '#c0baa8', '#d2ccb8' } },
      { t = { '#4e2620', '#68342a', '#804436' }, d = { '#341a16', '#44221c', '#542c24' }, l = { '#7a5a2c', '#927038', '#a88446' }, r = { '#8a6a34', '#a28040', '#b8964e' }, c = { '#5e2820', '#78362a', '#8e4636' } } },
    ground = { grass = { '#3a5228', '#445e2e', '#4e6a34', '#58763a' }, field = { '#7e6e40', '#8e7c48', '#9c8a52' }, stream = { '#22404c', '#2a4c5a', '#5e8a96' }, ford = { '#4a6a70', '#567880' }, hill = { '#5a6a38', '#667640' }, mud = { '#4a3e2c', '#56482e' }, bg = '#1a1c14' } },
  C = { name = 'manuscript', geo = 'classic', shade = 'wash', outline = '#5e4028',
    common = { k = { '#e6c2a2', '#f0d0b2', '#f8e0c8' }, a = { '#b89272', '#c8a282', '#d6b292' }, e = { '#5e4028', '#5e4028', '#5e4028' },
      h = { '#c4c6c2', '#d6d8d2', '#e6e8e2' }, i = { '#b4b6b2', '#c4c6c2', '#d4d6d0' }, w = { '#b48a62', '#c49c74', '#d4ae86' },
      s = { '#d8dcd8', '#eceeea', '#f6f6f2' }, b = { '#8a6a50', '#9a7a5e', '#aa8a6e' }, q = { '#c4a27a', '#d2b28a', '#dec29c' },
      n = { '#c8a07a', '#d6b08a', '#e2c09c' }, N = { '#b48c68', '#c49c78', '#d0ac88' }, m = { '#8a6a50', '#9a7a5e', '#aa8a6e' },
      f = { '#fff8e0', '#fff8e0', '#fff8e0' }, x = { '#c86a5a', '#d47c6c', '#e08e7e' }, u = { '#e0d0b0', '#eadcbe', '#f2e6cc' },
      g = { '#b4c48c', '#c2d09a', '#d0dcaa' }, G = { '#b48a62', '#c49c74', '#d4ae86' } },
    side = {
      { t = { '#8ea4c4', '#a2b6d2', '#b8c8de' }, d = { '#76889e', '#8698ae', '#96a8be' }, l = { '#a2b6d2', '#b2c4dc', '#c2d2e4' }, r = { '#f4ecdc', '#faf4e8', '#fdf9f0' }, c = { '#f4ecdc', '#faf4e8', '#fdf9f0' } },
      { t = { '#d48e7e', '#e0a292', '#eab6a8' }, d = { '#b87a6c', '#c88a7c', '#d49a8c' }, l = { '#e8c87a', '#f0d48c', '#f6e0a2' }, r = { '#e8c87a', '#f0d48c', '#f6e0a2' }, c = { '#c8685a', '#d47c6e', '#de8e82' } } },
    ground = { grass = { '#e6dcbc', '#ece2c4' }, wash = { '#ccd6a8', '#d6deb4' }, field = { '#ecd8a0', '#f0deac' }, stream = { '#b4ccd6', '#c2d6de' }, ford = { '#d0dcdc', '#dae4e2' }, hill = { '#dcd6aa', '#e2dcb4' }, tick = '#8a7a52', bg = '#2a241c' } },
}
-- Proportions: head, body and legs in a 16 x 20 frame facing right; the feet are on the bottom row.
local GEO = {
  chunky  = { hx = 5, hy = 3, hw = 4, hh = 4, bx = 5, by = 7, bw = 6, bh = 7, ly = 14, lw = 2, l1 = 5, l2 = 9 },
  classic = { hx = 6, hy = 4, hw = 4, hh = 4, bx = 5, by = 8, bw = 6, bh = 6, ly = 14, lw = 2, l1 = 6, l2 = 9 },
  slim    = { hx = 6, hy = 3, hw = 3, hh = 3, bx = 5, by = 6, bw = 5, bh = 7, ly = 13, lw = 1, l1 = 6, l2 = 8 },
}

-- ───────────────────────── figures as letters ─────────────────────────
local function grid(w, h) local g = { w = w, h = h }; for y = 0, h - 1 do g[y] = {} end; return g end
local function P(g, x, y, w, h, ch) for j = 0, h - 1 do for i = 0, w - 1 do local X, Y = x + i, y + j; if X >= 0 and Y >= 0 and X < g.w and Y < g.h then g[Y][X] = ch end end end end
local function rows(g, x, y, list) for j, r in ipairs(list) do for i = 1, #r do local ch = r:sub(i, i); if ch ~= '.' then P(g, x + i - 1, y + j - 1, 1, 1, ch) end end end end

-- The rider: a horse facing right with a man on it.
local function riderFig(g, back, pose)
  local walking, blow = pose <= 3, pose == 5
  local legs = ({ { 0, 2, 0, 2 }, { 1, 1, 1, 1 }, { 2, 0, 2, 0 }, { 1, 1, 1, 1 } })[walking and pose + 1 or 2]
  P(g, 2, 10, 11, 5, 'n'); P(g, 2, 14, 11, 1, 'N')
  for k, x in ipairs({ 3, 5, 9, 11 }) do local up = legs[k] > 0 and 1 or 0; P(g, x, 15, 1, 4 - up, 'N'); P(g, x, 19 - up, 1, 1, 'b') end
  if not back then P(g, 12, 6, 2, 5, 'n'); P(g, 13, 5, 3, 3, 'n'); P(g, 15, 6, 1, 1, 'e'); P(g, 12, 5, 1, 3, 'm')
  else P(g, 12, 7, 2, 4, 'N'); P(g, 12, 6, 2, 1, 'm') end
  P(g, 1, 10, 1, 4, 'm'); P(g, 4, 9, 7, 2, 't'); P(g, 4, 11, 7, 1, 'r')
  P(g, 6, 3, 4, 6, 't'); P(g, 6, 8, 4, 1, 'd')
  P(g, 7, 0, 3, 3, back and 'a' or 'k'); P(g, 7, 0, 3, 1, 'h'); if not back then P(g, 9, 1, 1, 1, 'e') end
  if blow then P(g, 8, 5, 8, 1, 'w'); P(g, 14, 4, 2, 3, 's') else P(g, 11, 0, 1, 11, 'w'); P(g, 10, 0, 3, 1, 's') end
  P(g, 5, 4, 2, 4, 'l')
  return g
end

--- One figure: `kind`, seen from the back or the front, in a pose (0-3 walking, 4 standing, 5 striking, 6 reeling).
local function figure(S, kind, back, pose)
  local g = grid(16, 20)
  if pose == 6 then                                            -- reeling: the standing figure knocked back and up, a flash on him
    local base = figure(S, kind, back, 4)
    for y = 0, 19 do for x = 0, 15 do local ch = base[y][x]; if ch then P(g, x - 1, y - 1, 1, 1, ch) end end end
    local cx, cy = (kind == 'rider') and 9 or 10, (kind == 'rider') and 5 or 9
    P(g, cx, cy, 2, 2, 'f'); P(g, cx + 2, cy - 1, 1, 1, 'f'); P(g, cx + 2, cy + 2, 1, 1, 'f'); P(g, cx - 1, cy + 1, 1, 1, 'x'); P(g, cx + 1, cy + 2, 1, 1, 'x')
    return g
  end
  if kind == 'rider' then return riderFig(g, back, pose) end
  local G = GEO[S.geo]
  local walking, blow = pose <= 3, pose == 5
  local step = walking and ({ 1, 0, -1, 0 })[pose + 1] or 0
  -- legs: one lifted and forward while walking
  for k, lx in ipairs({ G.l1, G.l2 }) do
    local up = (k == 1 and step > 0) or (k == 2 and step < 0)
    local len = 19 - G.ly + (up and 0 or 1)
    P(g, lx, G.ly, G.lw, len - 1, 'd')
    P(g, lx + (up and (k == 1 and 1 or -1) or 0), G.ly + len - 1, G.lw, 1, 'b')
  end
  local bx, by, bw, bh, bx2 = G.bx, G.by, G.bw, G.bh, G.bx + G.bw
  P(g, bx, by, bw, bh, kind == 'levy' and 'u' or 't'); P(g, bx, by + bh - 2, bw, 1, 'd')
  if kind == 'levy' then P(g, bx, by, 1, bh - 2, 't'); P(g, bx + 1, by, 1, 1, 't') end   -- a realm-coloured sash
  if kind == 'spear' or kind == 'sword' then P(g, bx, by, bw, 2, 'i') end
  local hx, hy, hw, hh = G.hx, G.hy, G.hw, G.hh
  P(g, hx, hy, hw, hh, back and 'a' or 'k')
  if not back then P(g, hx + hw - 2, hy + 1, 1, 1, 'e') end
  if kind == 'spear' then P(g, hx, hy - 1, hw, 2, 'h'); P(g, hx - 1, hy, hw + 2, 1, 'h')
  elseif kind == 'sword' then P(g, hx, hy - 2, hw, 3, 'h'); P(g, hx - 1, hy, hw + 2, 1, 'h'); if not back then P(g, hx + hw - 2, hy + 1, 1, 2, 'h') end; P(g, hx + 1, hy - 3, 2, 1, 'r')
  elseif kind == 'archer' then P(g, hx, hy - 1, hw, 2, 'd'); P(g, hx + hw, hy - 1, 2, 1, 'r')
  else P(g, hx - 1, hy - 1, hw + 2, 2, 'q'); P(g, hx - 1, hy, 1, hh, 'q') end
  if kind == 'spear' then
    if blow then P(g, bx, by + 2, 16 - bx, 1, 'w'); P(g, 14, by + 1, 2, 3, 's') else P(g, bx2 + 1, 0, 1, G.ly + 4, 'w'); P(g, bx2, 0, 3, 1, 's'); P(g, bx2 + 1, 1, 1, 1, 's') end
  elseif kind == 'sword' then
    if blow then P(g, bx2, by + 2, 6, 1, 's'); P(g, bx2, by + 3, 5, 1, 's'); P(g, bx2 - 1, by + 2, 1, 2, 'w') else P(g, bx2, by - 2, 1, 6, 's'); P(g, bx2 - 1, by + 4, 3, 1, 'w') end
  elseif kind == 'archer' then
    if blow then P(g, bx2 + 3, by - 3, 1, bh + 4, 'w'); P(g, bx2 + 2, by - 4, 1, 1, 'w'); P(g, bx2 + 2, by + bh + 1, 1, 1, 'w'); P(g, bx2 - 2, by + 2, 5, 1, 's')
    else P(g, bx2 + 1, by - 2, 1, bh + 2, 'w'); P(g, bx2, by - 3, 1, 1, 'w'); P(g, bx2, by + bh, 1, 1, 'w') end
    if back then P(g, bx + 1, by, 2, bh - 2, 'q') else P(g, bx - 1, by - 1, 2, bh - 1, 'q') end
  else
    if blow then P(g, bx, by + 2, 16 - bx, 1, 'w'); P(g, 15, by + 1, 1, 1, 's'); P(g, 15, by + 3, 1, 1, 's') else P(g, bx2 + 1, 1, 1, G.ly + 3, 'w'); P(g, bx2, 0, 1, 2, 's'); P(g, bx2 + 2, 0, 1, 2, 's') end
  end
  if kind == 'spear' or kind == 'sword' then
    if back then P(g, bx2 - 2, by + 1, 3, bh - 1, 'd')
    else P(g, bx - 2, by + 1, 4, bh - 1, 'l'); P(g, bx - 2, by + 1, 4, 1, 'r'); P(g, bx - 2, by + bh - 1, 4, 1, 'r'); P(g, bx - 1, by + 3, 2, 2, 'c') end
  end
  P(g, back and bx or bx2 - 1, by + 2, 1, 4, back and 'd' or 'k')
  return g
end
-- A fallen man, lying on the ground (the bottom eight rows of the frame).
local function fallenFig(kind, k)
  local g = grid(16, 20)
  if kind == 'rider' then
    P(g, 1, 14, 12, 4, 'n'); P(g, 1, 17, 12, 1, 'N'); P(g, 12, 13, 3, 3, 'n'); P(g, 0, 15, 1, 2, 'm'); P(g, 3, 18, 1, 2, 'N'); P(g, 9, 18, 1, 2, 'N')
    P(g, 5, 12, 5, 2, 't'); P(g, 10, 12, 2, 2, 'k')
    P(g, 3, 19, 6, 1, 'x')
    return g
  end
  P(g, 3, 15, 9, 3, kind == 'levy' and 'u' or 't'); P(g, 3, 17, 9, 1, 'd'); P(g, 0, 16, 3, 2, 'd'); P(g, 0, 18, 1, 1, 'b')
  P(g, 12, 14, 3, 3, (kind == 'spear' or kind == 'sword') and 'h' or 'k')
  if kind == 'spear' or kind == 'levy' then P(g, 1, 13, 13, 1, 'w') elseif kind == 'sword' then P(g, 2, 19, 6, 1, 's') elseif kind == 'archer' then P(g, 4, 13, 1, 1, 'w'); P(g, 5, 12, 6, 1, 'w'); P(g, 11, 13, 1, 1, 'w') end
  if kind == 'spear' or kind == 'sword' then P(g, 6, 14, 4, 4, 'l'); P(g, 7, 15, 2, 2, 'c') end
  if k % 2 == 0 then P(g, 5, 18, 5, 1, 'x') end
  return g
end
-- A standard: a pole, and the realm's colours with its charge (the March: a white tower; the Crown: a gold crown).
local function standardFig(side)
  local g = grid(16, 32)
  P(g, 1, 0, 1, 32, 'w'); P(g, 0, 0, 3, 1, 's'); P(g, 1, 1, 1, 1, 's')
  P(g, 2, 3, 13, 11, 't'); P(g, 2, 14, 5, 2, 't'); P(g, 10, 14, 5, 2, 't')
  P(g, 2, 3, 13, 1, 'r'); P(g, 2, 13, 13, 1, 'd')
  if side == 1 then rows(g, 4, 6, { 'r.r.r.r.r', 'rrrrrrrrr', '.rrrrrrr.', '.rrrrrrr.' })
  else rows(g, 5, 5, { 'r.r.r.r', 'rrrrrrr', '.rrrrr.', '.rr.rr.', '.rrrrr.', '.rrrrr.' }) end
  return g
end
local function treeFig(k)
  local g = grid(18, 26)
  P(g, 8, 18, 2, 8, 'G')
  local blob = function(cx, cy, r) for y = -r, r do local w = math.floor(math.sqrt(r * r - y * y) + 0.5); P(g, cx - w, cy + y, w * 2, 1, 'g') end end
  if k == 1 then for j = 0, 3 do blob(9, 5 + j * 4, 2 + j) end
  else blob(9, 11, 7); blob(7, 8, 4); blob(12, 9, 4) end
  return g
end

-- ───────────────────────── letters to pixels ─────────────────────────
local function ramp(S, side, ch) return S.side[side + 1][ch] or S.common[ch] end
local function render(S, side, g)
  local img = W.image(g.w, g.h)
  local at = function(x, y) if x < 0 or y < 0 or x >= g.w or y >= g.h then return nil end; return g[y][x] end
  for y = 0, g.h - 1 do for x = 0, g.w - 1 do
    local ch = g[y][x]
    if ch then
      local r, tone = ramp(S, side, ch), 2
      if S.shade == 'flat' then if at(x + 1, y) ~= ch then tone = 1 end
      elseif S.shade == 'rich' then
        if at(x - 1, y) ~= ch or at(x, y - 1) ~= ch then tone = 3 elseif at(x + 1, y) ~= ch or at(x, y + 1) ~= ch then tone = 1 end
        if S.grain and (ch == 'g' or ch == 't' or ch == 'u') and W.hash(x * 3 + side, y * 7) > 0.8 then tone = math.max(1, tone - 1) end
      elseif S.shade == 'wash' then if at(x, y + 1) ~= ch and at(x, y + 1) then tone = 1 end end
      if ch == 'g' and S.shade ~= 'rich' then tone = (W.hash(x, y) > 0.75) and 1 or ((W.hash(x + 9, y) > 0.8) and 3 or 2) end
      W.put(img, x, y, W.hex(r[tone]))
    end
  end end
  if S.outline then
    local ink, add = W.hex(S.outline), {}
    for y = 0, g.h - 1 do for x = 0, g.w - 1 do
      if not g[y][x] and (at(x - 1, y) or at(x + 1, y) or at(x, y - 1) or at(x, y + 1)) then add[#add + 1] = { x, y } end
    end end
    for _, p in ipairs(add) do W.put(img, p[1], p[2], ink) end
  end
  return img
end

-- ───────────────────────── ground ─────────────────────────
-- Terrain of a cell of the mock field: 'grass', 'woods', 'field', 'stream', 'ford', 'hill'.
local function groundAt(S, t, px, py, cx, cy)
  local G = S.ground
  if S.name == 'heraldic' then
    local two = G[t == 'woods' and 'grass' or t] or G.grass
    local c = two[((math.floor(cx) + math.floor(cy)) % 2) + 1]
    if t == 'field' and py % 3 == 0 then return W.hex(c, 0.9) end
    if t == 'stream' and W.hash(px // 3, py) > 0.9 then return W.hex('#9ac4e4') end
    return W.hex(c)
  elseif S.name == 'chronicle' then
    local n = W.smooth(px, py, 6, 3) * 0.6 + W.hash(px, py) * 0.4
    local ramp = G[t == 'woods' and 'grass' or t] or G.grass
    if t == 'grass' and W.smooth(px, py, 10, 9) > 0.8 then ramp = G.mud end
    local c = ramp[math.min(#ramp, math.floor(n * #ramp) + 1)]
    if t == 'stream' and W.hash(px // 2, py) > 0.93 then c = G.stream[3] end
    return W.hex(c, t == 'woods' and 0.85 or 1)
  else
    local base = G[t] or G.grass
    local c = W.hex(base[(W.hash(px // 4, py // 2) > 0.5) and 1 or 2])
    if t == 'grass' and W.smooth(px, py, 12, 5) > 0.62 then c = W.hex(G.wash[1]) end
    if t == 'woods' then c = W.hex(G.wash[2]) end
    if (t == 'grass' or t == 'woods') and W.hash(px, py) > 0.965 then return W.hex(G.tick) end      -- pen ticks of grass
    if t == 'field' and px % 4 == 0 and py % 2 == 0 then return W.hex(G.tick, 1.3) end
    if t == 'stream' and (px + py * 2) % 7 == 0 then return W.hex('#7896a4') end
    return c
  end
end
-- An isometric field of cw x ch cells, its terrain from terrain(cx, cy); the sprites drawn on it back to front.
local function field(S, cw, ch, terrain, sprites, top)
  local ox, oy = ch * 8, top
  local img = W.image((cw + ch) * 8, (cw + ch) * 4 + top)
  W.fill(img, function(px, py)
    local a, b = (px - ox) / 8, (py - oy) / 4
    local x, y = (a + b) / 2, (b - a) / 2
    if x < 0 or y < 0 or x >= cw or y >= ch then return W.hex(S.ground.bg) end
    return groundAt(S, terrain(math.floor(x), math.floor(y)), px, py, x, y)
  end)
  table.sort(sprites, function(p, q) return p.x + p.y < q.x + q.y end)
  for _, s in ipairs(sprites) do
    local sx, sy = (s.x - s.y) * 8 + ox, (s.x + s.y) * 4 + oy
    W.blit(img, s.img, math.floor(sx - s.img.width / 2), math.floor(sy - s.img.height + 1), s.flip)
  end
  return img
end


return { W = W, KINDS = KINDS, STYLES = STYLES, GEO = GEO, grid = grid, P = P, rows = rows, figure = figure, riderFig = riderFig,
  fallenFig = fallenFig, standardFig = standardFig, treeFig = treeFig, render = render, field = field, groundAt = groundAt }
