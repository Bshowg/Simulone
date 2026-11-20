-- ink.lua: the shared drawing library for The Lord's Will art. Runs inside Aseprite (batch mode).
--
-- Style: brown ink line, realistic pastel washes, on paper. Light comes from the left: faces turned to the lower left of
-- the screen are lit, faces turned to the lower right are in shade.
--
-- A building is described ONCE, in model space, and drawn in any of the four rotations: the library turns it, hides the
-- faces that point away, puts doors and windows only on walls that can be seen, and sorts the parts back to front.
--
-- Model space: x runs 0..w and y runs 0..h over the footprint (cells), z is height in PIXELS. Sides of a box are named
-- as on a map: 'N' is the y = y0 side, 'S' the y = y1 side, 'W' the x = x0 side, 'E' the x = x1 side. In rotation 0 the
-- camera sees the S side (lower left of the screen, lit) and the E side (lower right, shaded).
-- One cell is a 32 x 16 pixel diamond; one cell of height is 16 pixels.
local ink = {}
-- Set ink.night = true before drawing to get the building as it is after dark: its windows lit (run.lua does this).
local pc = app.pixelColor
local HW, HH = 16, 8
ink.HW, ink.HH = HW, HH

local cache = {}
local function hex(s)
  local v = cache[s]
  if not v then v = pc.rgba(tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16), 255); cache[s] = v end
  return v
end
local function hash(x, y)
  local n = (math.floor(x) * 374761393 + math.floor(y) * 668265263) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  return ((n ~ (n >> 16)) % 1000) / 1000
end
ink.hex, ink.hash = hex, hash

-- ── palette (every colour used anywhere must come from here, or be added here)
local P = {
  ink = '#4a382c', ink2 = '#6e5a4a', paper = '#eadfc6', paper2 = '#e5d9bd',
  stone = '#f0eadc', stoneLine = '#b3a892', stoneShade = '#cfc8b8', stoneShadeLine = '#8f8674',
  plaster = '#f3ecdd', plasterShade = '#d6cdbb', beam = '#7a644c',
  wattle = '#e3d6b8', wattleLine = '#b39f7a', wattleShade = '#c4b594', wattleShadeLine = '#8f7c5c',
  wood = '#a58a6c', woodLine = '#8f765a', woodShade = '#8f765a', woodShadeLine = '#7a644c', dark = '#5a4a40',
  thatch = '#dccc9e', thatchLine = '#8a7450', thatchShade = '#b9a67a', thatchShadeLine = '#6a5638', thatchUnder = '#8a7450',
  tile = '#d8ad94', tileLine = '#a87c66', tileShade = '#b98e78', tileShadeLine = '#8a6250',
  slate = '#aeb8be', slateLine = '#7e8a92', slateShade = '#909ca4', slateShadeLine = '#66727a',
  shingle = '#bca88c', shingleLine = '#8c7a62', shingleShade = '#9e8c72', shingleShadeLine = '#70604a',
  lead = '#9fb0b8', glass = '#8fa6b4', glow = '#f2d9a0', iron = '#6a6460', smoke = '#b4aca2',
  grass = '#c8d2a8', grass2 = '#b7c596', leaf = '#b2c69a', leafShade = '#86a078', earth = '#d9c8a6', earth2 = '#c4b08a',
  road = '#e8dcc0', road2 = '#dfd2b4', water = '#b6cfd6', water2 = '#a6c2cc', waterLine = '#6f8f9e',
  corn = '#e8d8a2', corn2 = '#dfcb8c', cornLine = '#c9b06c', furrow = '#8a7450',
  madder = '#b98878', woad = '#93a6ba', russet = '#a08a6a', weld = '#cdbc80', green = '#98a682', linen = '#d6cab2',
  skin = '#e8cdb4', hair = '#6a5040', hairGrey = '#b0a898', veil = '#f0e8d6',
  snow = '#f6f3ea', snowShade = '#dfe2e0',
  flame = '#eea85e', flameCore = '#f7dd8c', ember = '#d2725a', char = '#5a4a40',
}
ink.P = P

-- ── patterns: each returns a colour function f(px, py). `s` is the slope on screen of the surface's long edge
-- (0.5 on faces turned to the lower left, -0.5 on faces turned to the lower right, 0 on flat tops).
local pat = {}
function pat.flat(c) local v = hex(c); return function() return v end end
function pat.brick(base, line, s, bw, bh) local b, k = hex(base), hex(line); bw = bw or 6; bh = bh or 3
  return function(px, py) local v = math.floor(py - s * px); local row = v // bh; return (v % bh == 0 or (px + (row % 2) * (bw // 2)) % bw == 0) and k or b end end
function pat.strokes(base, line, s, gap, len, dens) local b, k = hex(base), hex(line)
  return function(px, py) local v = math.floor(py - s * px); return (v % gap == 0 and hash(px // len, v) > (dens or 0.4)) and k or b end end
function pat.planks(base, line, w) local b, k = hex(base), hex(line); return function(px) return px % (w or 3) == 0 and k or b end end
function pat.boards(base, line, s, gap) local b, k = hex(base), hex(line); return function(px, py) return math.floor(py - s * px) % (gap or 3) == 0 and k or b end end
function pat.scale(base, line, s) local b, k = hex(base), hex(line)
  return function(px, py) local v = math.floor(py - s * px); local row = v // 3; local q = (px + (row % 2) * 2) % 4; return (v % 3 == 2 or (q == 0 and v % 3 ~= 0)) and k or b end end
function pat.lattice(base, line, step) local b, k = hex(base), hex(line); return function(px, py) return ((px + py) % step == 0 or (px - py) % step == 0) and k or b end end
function pat.hatch(base, line, step, dir) local b, k = hex(base), hex(line); return function(px, py) return (px + (dir or 1) * py) % step == 0 and k or b end end
function pat.speckle(base, dot, dens) local b, k = hex(base), hex(dot); return function(px, py) return hash(px * 3, py * 7) > (dens or 0.9) and k or b end end
function pat.blotch(a, b2, sx, sy) local ca, cb = hex(a), hex(b2); return function(px, py) return hash(px // (sx or 5), py // (sy or 3)) > 0.55 and cb or ca end end
ink.pat = pat

-- ── materials: { lit = f(s), shade = f(s), top = f() }. Make your own with the same shape if you need one.
local M = {}
M.stone = { lit = function(s) return pat.brick(P.stone, P.stoneLine, s) end, shade = function(s) return pat.brick(P.stoneShade, P.stoneShadeLine, s) end, top = function() return pat.flat(P.stone) end }
M.ashlar = { lit = function(s) return pat.brick(P.stone, P.stoneLine, s, 10, 5) end, shade = function(s) return pat.brick(P.stoneShade, P.stoneShadeLine, s, 10, 5) end, top = function() return pat.flat(P.stone) end }
M.plaster = { lit = function() return pat.flat(P.plaster) end, shade = function() return pat.flat(P.plasterShade) end, top = function() return pat.flat(P.plaster) end }
M.wattle = { lit = function() return pat.lattice(P.wattle, P.wattleLine, 5) end, shade = function() return pat.lattice(P.wattleShade, P.wattleShadeLine, 5) end, top = function() return pat.flat(P.wattle) end }
M.planks = { lit = function() return pat.planks(P.wood, P.woodLine, 3) end, shade = function() return pat.planks(P.woodShade, P.woodShadeLine, 3) end, top = function() return pat.flat(P.wood) end }
M.logs = { lit = function(s) return pat.boards(P.wood, P.woodLine, s, 3) end, shade = function(s) return pat.boards(P.woodShade, P.woodShadeLine, s, 3) end, top = function() return pat.flat(P.wood) end }
M.thatch = { lit = function(s) return pat.strokes(P.thatch, P.thatchLine, s, 3, 3, 0.4) end, shade = function(s) return pat.strokes(P.thatchShade, P.thatchShadeLine, s, 3, 2, 0.4) end, top = function() return pat.flat(P.thatch) end, under = P.thatchUnder }
M.tile = { lit = function(s) return pat.scale(P.tile, P.tileLine, s) end, shade = function(s) return pat.scale(P.tileShade, P.tileShadeLine, s) end, top = function() return pat.flat(P.tile) end, under = P.tileShadeLine }
M.slate = { lit = function(s) return pat.scale(P.slate, P.slateLine, s) end, shade = function(s) return pat.scale(P.slateShade, P.slateShadeLine, s) end, top = function() return pat.flat(P.slate) end, under = P.slateShadeLine }
M.shingle = { lit = function(s) return pat.brick(P.shingle, P.shingleLine, s, 4, 3) end, shade = function(s) return pat.brick(P.shingleShade, P.shingleShadeLine, s, 4, 3) end, top = function() return pat.flat(P.shingle) end, under = P.shingleShadeLine }
M.earth = { lit = function() return pat.blotch(P.earth, P.earth2) end, shade = function() return pat.flat(P.earth2) end, top = function() return pat.blotch(P.earth, P.earth2) end }
ink.M = M
--- A plain material from two colours (lit and shaded).
function ink.plain(lit, shade) return { lit = function() return pat.flat(lit) end, shade = function() return pat.flat(shade or lit) end, top = function() return pat.flat(lit) end } end

-- a fill may be a colour '#rrggbb', a colour function f(px, py), or a material
local function resolve(fill, light, slope)
  if ink.night and fill == P.glass then fill = P.glow end           -- glazing shows the light inside after dark
  if type(fill) == 'string' then return pat.flat(fill) end
  if type(fill) == 'function' then return fill end
  if light == 'T' then return (fill.top or fill.lit)(0) end
  if light == 'R' then return fill.shade(slope or -0.5) end
  return fill.lit(slope or 0.5)
end

-- ══ the canvas
local C = {}; C.__index = C

--- A sprite canvas for a w x h footprint (cells, as in rotation 0), `height` pixels of room above the ground, in
--- rotation `rot` (0-3, quarter turns clockwise). The image is (w + h) * 16 wide whatever the rotation.
function ink.canvas(w, h, height, rot)
  local c = setmetatable({ w = w, h = h, height = height, rot = (rot or 0) % 4 }, C)
  c.vw, c.vh = (c.rot % 2 == 1) and h or w, (c.rot % 2 == 1) and w or h
  c.W, c.H = (w + h) * HW, (w + h) * HH + height
  c.img = Image(c.W, c.H, ColorMode.RGB)
  c.scratch = Image(c.W, c.H, ColorMode.RGB)
  c.solids = {}
  return c
end

function C:view(x, y)
  local r, w, h = self.rot, self.w, self.h
  if r == 0 then return x, y elseif r == 1 then return h - y, x elseif r == 2 then return w - x, h - y else return y, w - x end
end
function C:dir(dx, dy)
  local r = self.rot
  if r == 0 then return dx, dy elseif r == 1 then return -dy, dx elseif r == 2 then return -dx, -dy else return dy, -dx end
end
--- Model point → screen point { sx, sy }.
function C:pt(x, y, z)
  local vx, vy = self:view(x, y)
  return { (vx - vy) * HW + self.vh * HW, (vx + vy) * HH - (z or 0) + self.height }
end
local NORMAL = { N = { 0, -1 }, S = { 0, 1 }, W = { -1, 0 }, E = { 1, 0 } }
--- Can the camera see this side of things in the current rotation? Returns 'L' (lit, lower left), 'R' (shaded, lower right) or nil.
function C:visible(side)
  local vx, vy = self:dir(NORMAL[side][1], NORMAL[side][2])
  if vy > 0 then return 'L' elseif vx > 0 then return 'R' end
  return nil
end
--- The model side that is seen on the lower left ('L') or lower right ('R') of the screen in this rotation.
function C:sideAt(screenSide) for _, s in ipairs({ 'N', 'E', 'S', 'W' }) do if self:visible(s) == screenSide then return s end end end
-- slope on screen of a line that runs along model axis 'x' or 'y'
function C:slopeAlong(axis) local vx = self:dir(axis == 'x' and 1 or 0, axis == 'x' and 0 or 1); return vx ~= 0 and 0.5 or -0.5 end

-- raw drawing onto the part being drawn (screen coordinates)
function C:_put(x, y, col) x, y = math.floor(x), math.floor(y); if x >= 0 and y >= 0 and x < self.W and y < self.H then self.scratch:drawPixel(x, y, col) end end
function C:_poly(pts, f)
  local lo, hi = math.huge, -math.huge
  for _, p in ipairs(pts) do lo = math.min(lo, p[2]); hi = math.max(hi, p[2]) end
  for py = math.floor(lo), math.ceil(hi) do
    local xs, yc = {}, py + 0.5
    for i = 1, #pts do
      local a, b = pts[i], pts[i % #pts + 1]
      if (a[2] <= yc) ~= (b[2] <= yc) then xs[#xs + 1] = a[1] + (yc - a[2]) / (b[2] - a[2]) * (b[1] - a[1]) end
    end
    table.sort(xs)
    for k = 1, #xs - 1, 2 do for px = math.floor(xs[k] + 0.5), math.floor(xs[k + 1] - 0.5) do self:_put(px, py, f(px, py)) end end
  end
end
function C:_line(a, b, col)
  local n = math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2]))
  for i = 0, n do local t = n == 0 and 0 or i / n; self:_put(math.floor(a[1] + (b[1] - a[1]) * t + 0.5), math.floor(a[2] + (b[2] - a[2]) * t + 0.5), col) end
end

-- a solid: a part with a bounding box (for sorting) and a list of drawing steps
function C:_solid(x0, y0, x1, y1, z0, z1)
  local ax, ay = self:view(x0, y0); local bx, by = self:view(x1, y1)
  local s = { vx0 = math.min(ax, bx), vx1 = math.max(ax, bx), vy0 = math.min(ay, by), vy1 = math.max(ay, by), z0 = z0, z1 = z1, ops = {}, seq = #self.solids + 1 }
  self.solids[#self.solids + 1] = s; self.cur = s
  return s
end
function C:_op(f, s) s = s or self.cur; s.ops[#s.ops + 1] = f end

-- a wall face of the box (x0..x1, y0..y1) standing on z0: returns f(u, z) → screen point, and 'L' or 'R'; nil if hidden.
-- u runs 0..1 along the wall from left to right as seen from outside; z is pixels above z0.
function C:_face(side, x0, y0, x1, y1, z0)
  local ss = self:visible(side)
  if not ss then return nil end
  local f
  if side == 'S' then f = function(u, z) return self:pt(x0 + (x1 - x0) * u, y1, z0 + z) end
  elseif side == 'E' then f = function(u, z) return self:pt(x1, y1 - (y1 - y0) * u, z0 + z) end
  elseif side == 'N' then f = function(u, z) return self:pt(x1 - (x1 - x0) * u, y0, z0 + z) end
  else f = function(u, z) return self:pt(x0, y0 + (y1 - y0) * u, z0 + z) end end
  return f, ss
end

-- ── what you can put on a wall. `h` is the handle returned by box(), gable(), hip(), shed().
local Hd = {}; Hd.__index = Hd
function C:_handle(s, x0, y0, x1, y1, z0) return setmetatable({ c = self, s = s, x0 = x0, y0 = y0, x1 = x1, y1 = y1, z0 = z0 }, Hd) end
function Hd:_f(side) return self.c:_face(side, self.x0, self.y0, self.x1, self.y1, self.z0) end
function Hd:len(side) return (side == 'S' or side == 'N') and (self.x1 - self.x0) or (self.y1 - self.y0) end
--- Free drawing on a wall, only if it can be seen: fn(f, screenSide, canvas), where f(u, z) gives the screen point.
function Hd:draw(side, fn) local c = self.c; c:_op(function() local f, ss = self:_f(side); if f then fn(f, ss, c) end end, self.s); return self end
--- A rectangle on a wall: u0..u1 along it (0..1), za..zb pixels above the wall's foot.
function Hd:rect(side, u0, u1, za, zb, fill)
  return self:draw(side, function(f, ss, c) c:_poly({ f(u0, za), f(u1, za), f(u1, zb), f(u0, zb) }, resolve(fill, ss, ss == 'L' and 0.5 or -0.5)) end)
end
--- A line on a wall, in wall coordinates.
function Hd:line(side, u0, za, u1, zb, color) return self:draw(side, function(f, ss, c) c:_line(f(u0, za), f(u1, zb), hex(color or P.ink)) end) end
--- A round-headed opening: centre u, half-width hw (in u), from za up to the springing zs, then `rise` more.
function Hd:arch(side, u, hw, za, zs, rise, fill)
  return self:draw(side, function(f, ss, c)
    local pts = { f(u - hw, za), f(u + hw, za) }
    for k = 0, 8 do local a = math.pi * k / 8; pts[#pts + 1] = f(u + hw * math.cos(a), zs + rise * math.sin(a)) end
    c:_poly(pts, resolve(fill, ss, ss == 'L' and 0.5 or -0.5))
  end)
end
--- A door: centre at u (0..1), `width` in cells, `height` in pixels. opts: fill (default wood planks), arch (true for a
--- round head), z (pixels above the wall's foot, default 0).
function Hd:door(side, u, width, height, opts)
  opts = opts or {}
  local hw, z = width / self:len(side) / 2, opts.z or 0
  local fill = opts.fill or M.planks
  if opts.arch then self:arch(side, u, hw, z, z + height - 3, 3, fill) else self:rect(side, u - hw, u + hw, z, z + height, fill) end
  if not opts.arch then self:line(side, u - hw, z, u - hw, z + height); self:line(side, u + hw, z, u + hw, z + height); self:line(side, u - hw, z + height, u + hw, z + height) end
  return self
end
--- A window: centre at u, `width` in cells, bottom at z, `height` pixels. opts: fill (default dark; use P.glow for a
--- lit one, P.glass for glazing), arch, shutters (true), bars (true: a cross of glazing bars).
function Hd:window(side, u, width, z, height, opts)
  opts = opts or {}
  local hw = width / self:len(side) / 2
  local fill = opts.fill or P.dark
  if ink.night and (fill == P.dark or fill == P.glass) then fill = P.glow end   -- after dark there is a light inside
  if opts.arch then self:arch(side, u, hw, z, z + height - 2, 2, fill) else self:rect(side, u - hw, u + hw, z, z + height, fill) end
  if opts.bars then self:line(side, u, z, u, z + height, P.ink2); self:line(side, u - hw, z + height / 2, u + hw, z + height / 2, P.ink2) end
  if opts.shutters then self:rect(side, u - hw * 1.9, u - hw, z, z + height, M.planks); self:rect(side, u + hw, u + hw * 1.9, z, z + height, M.planks) end
  return self
end
--- Timber framing on a wall of height `zTop`: `posts` upright posts (including both ends), a rail at mid height, and
--- diagonal braces in the end bays when `braces` is true.
function Hd:frame(side, zTop, posts, braces, color)
  posts = posts or 4; color = color or P.beam
  for k = 0, posts - 1 do self:line(side, k / (posts - 1), 0, k / (posts - 1), zTop, color) end
  self:line(side, 0, zTop / 2, 1, zTop / 2, color); self:line(side, 0, 0, 1, 0, color); self:line(side, 0, zTop - 1, 1, zTop - 1, color)
  if braces then
    local b = 1 / (posts - 1)
    self:line(side, 0, zTop / 2, b, zTop - 1, color); self:line(side, 1, zTop / 2, 1 - b, zTop - 1, color)
  end
  return self
end

-- ── solids

--- A box: walls from z0 up to z1. mats: { wall = material, N/S/E/W = material for one side, top = material or false }.
--- Returns a handle for doors, windows and other wall detail.
function C:box(x0, y0, x1, y1, z0, z1, mats)
  mats = mats or {}
  local s = self:_solid(x0, y0, x1, y1, z0, z1)
  local wall = mats.wall or M.plaster
  self:_op(function()
    if mats.top ~= false then self:_poly({ self:pt(x0, y0, z1), self:pt(x1, y0, z1), self:pt(x1, y1, z1), self:pt(x0, y1, z1) }, resolve(mats.top or wall, 'T', 0)) end
    for _, side in ipairs({ 'N', 'W', 'S', 'E' }) do
      local f, ss = self:_face(side, x0, y0, x1, y1, z0)
      if f then self:_poly({ f(0, 0), f(1, 0), f(1, z1 - z0), f(0, z1 - z0) }, resolve(mats[side] or wall, ss, ss == 'L' and 0.5 or -0.5)) end
    end
  end)
  return self:_handle(s, x0, y0, x1, y1, z0)
end

-- sloping faces: each { dir = {dx, dy} (which way it faces, model), run (cells from eave to top), rise (px), pts (model points),
-- along ('x'|'y': the axis its eave runs along), eave = { p, q } (model points of the eave, or nil) }
function C:_slopes(list, roof, under)
  local far, near = {}, {}
  for _, f in ipairs(list) do
    local vx, vy = self:dir(f.dir[1], f.dir[2])
    if (f.rise / f.run) * (vx + vy) + 16 > 0.01 then
      f.light = (vy > 0 or vx < 0) and 'L' or 'R'
      f.slope = self:slopeAlong(f.along)
      if vx + vy > 0 then near[#near + 1] = f else far[#far + 1] = f end
    end
  end
  local function paint(f)
    local pts = {}
    for _, p in ipairs(f.pts) do pts[#pts + 1] = self:pt(p[1], p[2], p[3]) end
    self:_poly(pts, resolve(f.fill or roof, f.light, f.slope))
  end
  for _, f in ipairs(far) do paint(f) end
  for _, f in ipairs(near) do
    paint(f)
    if f.eave and under then
      local p, q = f.eave[1], f.eave[2]
      self:_poly({ self:pt(p[1], p[2], p[3] - 2), self:pt(q[1], q[2], q[3] - 2), self:pt(q[1], q[2], q[3]), self:pt(p[1], p[2], p[3]) }, pat.flat(under))
    end
  end
end

--- A two-sided roof. Eaves at height z, ridge `rise` pixels higher, running along `axis` ('x' or 'y') through the middle.
--- mats: { roof = material (default thatch), gable = material of the two end walls (default plaster) }.
--- Returns a handle: its 'W'/'E' sides (axis 'x') or 'N'/'S' sides (axis 'y') are the gable walls, z measured from the eaves.
function C:gable(x0, y0, x1, y1, z, rise, axis, mats)
  mats = mats or {}
  local roof, gab = mats.roof or M.thatch, mats.gable or M.plaster
  local s = self:_solid(x0, y0, x1, y1, z - 2, z + rise)
  local xm, ym, T = (x0 + x1) / 2, (y0 + y1) / 2, z + rise
  self:_op(function()
    local gables, slopes, A, B
    if axis == 'x' then
      A, B = { x0, ym, T }, { x1, ym, T }
      gables = { { 'W', { { x0, y0, z }, { x0, y1, z }, A } }, { 'E', { { x1, y0, z }, { x1, y1, z }, B } } }
      slopes = { { dir = { 0, -1 }, run = ym - y0, rise = rise, along = 'x', pts = { { x0, y0, z }, { x1, y0, z }, B, A }, eave = { { x0, y0, z }, { x1, y0, z } } },
                 { dir = { 0, 1 }, run = y1 - ym, rise = rise, along = 'x', pts = { { x0, y1, z }, { x1, y1, z }, B, A }, eave = { { x0, y1, z }, { x1, y1, z } } } }
    else
      A, B = { xm, y0, T }, { xm, y1, T }
      gables = { { 'N', { { x0, y0, z }, { x1, y0, z }, A } }, { 'S', { { x0, y1, z }, { x1, y1, z }, B } } }
      slopes = { { dir = { -1, 0 }, run = xm - x0, rise = rise, along = 'y', pts = { { x0, y0, z }, { x0, y1, z }, B, A }, eave = { { x0, y0, z }, { x0, y1, z } } },
                 { dir = { 1, 0 }, run = x1 - xm, rise = rise, along = 'y', pts = { { x1, y0, z }, { x1, y1, z }, B, A }, eave = { { x1, y0, z }, { x1, y1, z } } } }
    end
    for _, g in ipairs(gables) do
      local ss = self:visible(g[1])
      if ss then
        local pts = {}; for _, p in ipairs(g[2]) do pts[#pts + 1] = self:pt(p[1], p[2], p[3]) end
        self:_poly(pts, resolve(gab, ss, ss == 'L' and 0.5 or -0.5))
      end
    end
    self:_slopes(slopes, roof, roof.under or P.thatchUnder)
    self:_line(self:pt(A[1], A[2], A[3]), self:pt(B[1], B[2], B[3]), hex(P.ink))
  end)
  return self:_handle(s, x0, y0, x1, y1, z)
end

--- A four-sided roof. Eaves at z all round, ridge `rise` higher along `axis`; `inset` is how far (cells) the ridge ends
--- stand in from the end eaves (default: a 45 degree hip; give half the length for a pyramid).
function C:hip(x0, y0, x1, y1, z, rise, axis, mats, inset)
  mats = mats or {}
  local roof = mats.roof or M.thatch
  self:_solid(x0, y0, x1, y1, z - 2, z + rise)
  local xm, ym, T = (x0 + x1) / 2, (y0 + y1) / 2, z + rise
  self:_op(function()
    local A, B, d
    if axis == 'x' then d = math.min(inset or (y1 - y0) / 2, (x1 - x0) / 2); A, B = { x0 + d, ym, T }, { x1 - d, ym, T }
    else d = math.min(inset or (x1 - x0) / 2, (y1 - y0) / 2); A, B = { xm, y0 + d, T }, { xm, y1 - d, T } end
    local e = function(p, q) return { { p[1], p[2], z }, { q[1], q[2], z } } end
    local NW, NE, SE, SW = { x0, y0, z }, { x1, y0, z }, { x1, y1, z }, { x0, y1, z }
    local slopes
    if axis == 'x' then
      slopes = { { dir = { 0, -1 }, run = ym - y0, rise = rise, along = 'x', pts = { NW, NE, B, A }, eave = e(NW, NE) }, { dir = { 0, 1 }, run = y1 - ym, rise = rise, along = 'x', pts = { SW, SE, B, A }, eave = e(SW, SE) },
                 { dir = { -1, 0 }, run = d, rise = rise, along = 'y', pts = { NW, SW, A }, eave = e(NW, SW) }, { dir = { 1, 0 }, run = d, rise = rise, along = 'y', pts = { NE, SE, B }, eave = e(NE, SE) } }
    else
      slopes = { { dir = { -1, 0 }, run = xm - x0, rise = rise, along = 'y', pts = { NW, SW, B, A }, eave = e(NW, SW) }, { dir = { 1, 0 }, run = x1 - xm, rise = rise, along = 'y', pts = { NE, SE, B, A }, eave = e(NE, SE) },
                 { dir = { 0, -1 }, run = d, rise = rise, along = 'x', pts = { NW, NE, A }, eave = e(NW, NE) }, { dir = { 0, 1 }, run = d, rise = rise, along = 'x', pts = { SW, SE, B }, eave = e(SW, SE) } }
    end
    self:_slopes(slopes, roof, roof.under or P.thatchUnder)
    self:_line(self:pt(A[1], A[2], A[3]), self:pt(B[1], B[2], B[3]), hex(P.ink))
  end)
end

--- A lean-to: one slope, high (zHigh) along the `high` side ('N', 'S', 'E' or 'W') and low (zLow) along the opposite one,
--- with its end walls and back wall filled. mats: { roof, wall }. Returns a handle (z measured from zLow).
function C:shed(x0, y0, x1, y1, zLow, zHigh, high, mats)
  mats = mats or {}
  local roof, wall = mats.roof or M.thatch, mats.wall or M.plaster
  local s = self:_solid(x0, y0, x1, y1, zLow - 2, zHigh)
  self:_op(function()
    local zc = function(x, y) if high == 'N' then return y == y0 and zHigh or zLow elseif high == 'S' then return y == y1 and zHigh or zLow elseif high == 'W' then return x == x0 and zHigh or zLow else return x == x1 and zHigh or zLow end end
    local corner = { N = { { x0, y0 }, { x1, y0 } }, S = { { x0, y1 }, { x1, y1 } }, W = { { x0, y0 }, { x0, y1 } }, E = { { x1, y0 }, { x1, y1 } } }
    for _, side in ipairs({ 'N', 'W', 'S', 'E' }) do
      local ss = self:visible(side)
      if ss then
        local p, q = corner[side][1], corner[side][2]
        self:_poly({ self:pt(p[1], p[2], zLow), self:pt(q[1], q[2], zLow), self:pt(q[1], q[2], zc(q[1], q[2])), self:pt(p[1], p[2], zc(p[1], p[2])) }, resolve(wall, ss, ss == 'L' and 0.5 or -0.5))
      end
    end
    local opp = { N = 'S', S = 'N', W = 'E', E = 'W' }
    local lowSide = opp[high]
    local n = NORMAL[lowSide]
    local lo = corner[lowSide]
    local run = (high == 'N' or high == 'S') and (y1 - y0) or (x1 - x0)
    self:_slopes({ { dir = n, run = run, rise = zHigh - zLow, along = (high == 'N' or high == 'S') and 'x' or 'y',
      pts = { { x0, y0, zc(x0, y0) }, { x1, y0, zc(x1, y0) }, { x1, y1, zc(x1, y1) }, { x0, y1, zc(x0, y1) } },
      eave = { { lo[1][1], lo[1][2], zLow }, { lo[2][1], lo[2][2], zLow } } } }, roof, roof.under or P.thatchUnder)
  end)
  return self:_handle(s, x0, y0, x1, y1, zLow)
end

--- A round tower or drum: centre (cx, cy), radius r cells, from z0 to z1. Looks the same in every rotation.
function C:cyl(cx, cy, r, z0, z1, mat, top)
  mat = mat or M.stone
  self:_solid(cx - r, cy - r, cx + r, cy + r, z0, z1)
  self:_op(function()
    local b, t = self:pt(cx, cy, z0), self:pt(cx, cy, z1)
    local rx, ry = r * HW * 1.4142, r * HH * 1.4142
    local lit, shade, tp = resolve(mat, 'L', 0), resolve(mat, 'R', 0), resolve(top or mat, 'T', 0)
    for dx = -math.floor(rx), math.floor(rx) do
      local e = math.sqrt(math.max(0, 1 - (dx / rx) ^ 2)) * ry
      local px = math.floor(b[1] + dx)
      for py = math.floor(t[2] - e), math.floor(b[2] + e) do
        self:_put(px, py, py <= t[2] + e and tp(px, py) or (dx < rx * 0.15 and lit or shade)(px, py))
      end
    end
  end)
end
--- A cone (a round roof, a haystack): base circle at z0, apex `rise` pixels above it.
function C:cone(cx, cy, r, z0, rise, mat)
  mat = mat or M.thatch
  self:_solid(cx - r, cy - r, cx + r, cy + r, z0, z0 + rise)
  self:_op(function()
    local b, a = self:pt(cx, cy, z0), self:pt(cx, cy, z0 + rise)
    local rx, ry = r * HW * 1.4142, r * HH * 1.4142
    local lit, shade = resolve(mat, 'L', 0.5), resolve(mat, 'R', -0.5)
    for dx = -math.floor(rx), math.floor(rx) do
      local e = math.sqrt(math.max(0, 1 - (dx / rx) ^ 2)) * ry
      local px = math.floor(b[1] + dx)
      local top = math.min(a[2] + math.abs(dx) / rx * (b[2] - a[2]), b[2] - e)
      for py = math.floor(top), math.floor(b[2] + e) do self:_put(px, py, (dx < rx * 0.1 and lit or shade)(px, py)) end
    end
  end)
end

--- An empty part with its own place in the back-to-front order. Follow it with poly3 / line3 / post / dot3 calls.
--- opts.plain = true leaves it without an ink outline (smoke, a wash on the ground).
function C:part(x0, y0, x1, y1, z0, z1, opts) local s = self:_solid(x0, y0, x1, y1, z0, z1); s.plain = opts and opts.plain; return s end
--- A filled polygon through model points { {x, y, z}, ... }, added to the latest part. `light`: 'L', 'R' or 'T' picks
--- the lit, shaded or top look of a material.
function C:poly3(pts, fill, light)
  self:_op(function() local q = {}; for _, p in ipairs(pts) do q[#q + 1] = self:pt(p[1], p[2], p[3]) end; self:_poly(q, resolve(fill, light or 'L', light == 'R' and -0.5 or 0.5)) end)
end
function C:line3(x0, y0, z0, x1, y1, z1, color) self:_op(function() self:_line(self:pt(x0, y0, z0), self:pt(x1, y1, z1), hex(color or P.ink)) end) end
--- An upright post at (x, y) from z0 to z1, `wide` pixels thick (default 2).
function C:post(x, y, z0, z1, color, wide)
  self:_op(function()
    local a, b = self:pt(x, y, z0), self:pt(x, y, z1)
    for k = 0, (wide or 2) - 1 do self:_line({ a[1] + k, a[2] }, { b[1] + k, b[2] }, hex(k == 0 and (color or P.wood) or P.woodShade)) end
  end)
end
--- A blob of pixels at a model point: `r` pixels radius.
function C:dot3(x, y, z, r, fill)
  self:_op(function() local p = self:pt(x, y, z); local f = resolve(fill, 'L', 0)
    for dy = -r, r do for dx = -r, r do if dx * dx + dy * dy <= r * r + 0.5 then self:_put(p[1] + dx, p[2] + dy, f(math.floor(p[1] + dx), math.floor(p[2] + dy))) end end end end)
end
--- A thin curl of smoke rising from (x, y, z). Its own part, no outline.
function C:smoke(x, y, z, tall)
  self:part(x - 0.1, y - 0.1, x + 0.1, y + 0.1, z, z + (tall or 22), { plain = true })
  self:_op(function() local p = self:pt(x, y, z)
    for k = 0, ((tall or 22) // 2) do local sx = p[1] + math.floor(math.sin(k / 1.7) * 2.6 + 0.5); self:_put(sx, p[2] - k * 2, hex(P.smoke)); self:_put(sx + 1, p[2] - 1 - k * 2, hex(P.smoke)) end end)
end

-- ── finishing
local function behind(a, b) local e = 0.001; return a.vx1 <= b.vx0 + e or a.vy1 <= b.vy0 + e or a.z1 <= b.z0 + e end
--- Draw everything, back to front, each part with its ink outline. Returns the image.
function C:finish()
  local left = {}
  for _, s in ipairs(self.solids) do left[#left + 1] = s end
  local order = {}
  while #left > 0 do
    local pick
    for i, x in ipairs(left) do
      local ok = true
      for j, y in ipairs(left) do if i ~= j and behind(y, x) and not behind(x, y) then ok = false; break end end
      if ok then pick = i; break end
    end
    if not pick then
      local best = math.huge
      for i, x in ipairs(left) do local d = x.vx0 + x.vx1 + x.vy0 + x.vy1 + x.z0 / 16; if d < best then best = d; pick = i end end
    end
    order[#order + 1] = table.remove(left, pick)
  end
  local W, H, sc, img = self.W, self.H, self.scratch, self.img
  local k1, k2 = hex(P.ink), hex(P.ink2)
  for _, s in ipairs(order) do
    sc:clear()
    for _, op in ipairs(s.ops) do op() end
    for y = 0, H - 1 do for x = 0, W - 1 do
      local col = sc:getPixel(x, y)
      if pc.rgbaA(col) > 0 then
        local edge = false
        if not s.plain then
          if (x > 0 and pc.rgbaA(sc:getPixel(x - 1, y)) == 0) or (x < W - 1 and pc.rgbaA(sc:getPixel(x + 1, y)) == 0)
            or (y > 0 and pc.rgbaA(sc:getPixel(x, y - 1)) == 0) or (y < H - 1 and pc.rgbaA(sc:getPixel(x, y + 1)) == 0) then edge = true end
        end
        img:drawPixel(x, y, edge and (hash(x // 2, y // 2) > 0.75 and k2 or k1) or col)
      end
    end end
  end
  self.solids = {}
  return img
end
function C:save(path) self.img:saveAs(path) end

-- ── free-standing sprites (trees, figures, tiles): a plain pixel canvas with the same outline finish
local F = {}; F.__index = F
--- A w x h pixel canvas. Draw with put / disc / rect / line, then finish(outline) and save.
function ink.sprite(w, h) return setmetatable({ W = w, H = h, img = Image(w, h, ColorMode.RGB) }, F) end
function F:put(x, y, col) x, y = math.floor(x), math.floor(y); if x >= 0 and y >= 0 and x < self.W and y < self.H then self.img:drawPixel(x, y, type(col) == 'string' and hex(col) or col) end end
function F:get(x, y) if x < 0 or y < 0 or x >= self.W or y >= self.H then return 0 end; return self.img:getPixel(x, y) end
function F:rect(x0, y0, x1, y1, fill) local f = resolve(fill, 'L', 0); for y = y0, y1 do for x = x0, x1 do self:put(x, y, f(x, y)) end end end
function F:disc(cx, cy, r, fill, squash) local f = type(fill) == 'function' and fill or resolve(fill, 'L', 0)
  for dy = -r, r do for dx = -r, r do if dx * dx + dy * dy / (squash or 1) <= r * r + 0.5 then self:put(cx + dx, cy + dy, f(cx + dx, cy + dy, dx, dy)) end end end end
function F:line(x0, y0, x1, y1, col) local n = math.max(math.abs(x1 - x0), math.abs(y1 - y0))
  for i = 0, n do local t = n == 0 and 0 or i / n; self:put(math.floor(x0 + (x1 - x0) * t + 0.5), math.floor(y0 + (y1 - y0) * t + 0.5), col) end end
--- Rows of characters → pixels. `map` gives a colour per character; '.' is empty.
function F:rows(x, y, rows, map) for r, row in ipairs(rows) do for i = 1, #row do local ch = row:sub(i, i); if ch ~= '.' and map[ch] then self:put(x + i - 1, y + r - 1, map[ch]) end end end end
--- Ink the edge. mode: 'inner' (the outermost pixels become ink; the shape keeps its size) or 'outer' (ink is added
--- around the shape; leave a pixel of room). Without a mode nothing is inked.
function F:finish(mode)
  if not mode then return self.img end
  local src = self.img:clone()
  local k1, k2 = hex(P.ink), hex(P.ink2)
  local function a(x, y) if x < 0 or y < 0 or x >= self.W or y >= self.H then return 0 end; return pc.rgbaA(src:getPixel(x, y)) end
  for y = 0, self.H - 1 do for x = 0, self.W - 1 do
    local solid = a(x, y) > 0
    local n = (a(x - 1, y) > 0 and 1 or 0) + (a(x + 1, y) > 0 and 1 or 0) + (a(x, y - 1) > 0 and 1 or 0) + (a(x, y + 1) > 0 and 1 or 0)
    if (mode == 'inner' and solid and n < 4) or (mode == 'outer' and not solid and n > 0) then self.img:drawPixel(x, y, hash(x // 2, y // 2) > 0.75 and k2 or k1) end
  end end
  return self.img
end
function F:save(path) self.img:saveAs(path) end

-- ── preview sheets, so you can look at what you drew
--- Save a sheet of images on paper, enlarged. items: { { img = Image, w = cells, h = cells (optional: draws a grass
--- footprint under a building), label = unused }, ... }. cols: how many per row. scale: enlargement (default 3).
function ink.sheet(path, items, cols, scale, ground)
  cols = cols or #items; scale = scale or 3
  local cw, ch = 0, 0
  for _, it in ipairs(items) do cw = math.max(cw, it.img.width); ch = math.max(ch, it.img.height) end
  cw = cw + 12; ch = ch + 12
  local rows = math.ceil(#items / cols)
  local W, H = cw * cols, ch * rows
  local sheet = Image(W, H, ColorMode.RGB)
  local pa, pb, g1, g2 = hex(P.paper), hex(P.paper2), hex(ground or P.grass), hex(P.grass2)
  for y = 0, H - 1 do for x = 0, W - 1 do sheet:drawPixel(x, y, (hash(x // 3, y // 2) + hash(x // 7 + 5, y // 5 + 3)) > 1.45 and pb or pa) end end
  for i, it in ipairs(items) do
    local ox = ((i - 1) % cols) * cw + (cw - it.img.width) // 2
    local oy = ((i - 1) // cols) * ch + (ch - it.img.height) - 6
    if it.w then                                               -- the footprint diamond, bottom corner at the image's bottom centre... of its width
      local n = it.w + it.h
      for py = 0, n * HH - 1 do for px = 0, n * HW - 1 do
        local u, v = (px + 0.5 - it.vh * HW) / HW, (py + 0.5) / HH
        local gx, gy = (u + v) / 2, (v - u) / 2
        if gx >= 0 and gy >= 0 and gx < it.vw and gy < it.vh then sheet:drawPixel(ox + px, oy + it.img.height - n * HH + py, hash(px // 13, py // 7) > 0.6 and g2 or g1) end
      end end
    end
    for y = 0, it.img.height - 1 do for x = 0, it.img.width - 1 do
      local col = it.img:getPixel(x, y)
      if pc.rgbaA(col) > 0 then sheet:drawPixel(ox + x, oy + y, col) end
    end end
  end
  local big = Image(W * scale, H * scale, ColorMode.RGB)
  for y = 0, H - 1 do for x = 0, W - 1 do local col = sheet:getPixel(x, y); for j = 0, scale - 1 do for i = 0, scale - 1 do big:drawPixel(x * scale + i, y * scale + j, col) end end end end
  big:saveAs(path)
end

return ink
