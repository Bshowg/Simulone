-- WAR's fight frames for the Chronicle style: four frames of a blow and two of taking one, for a man on foot or a
-- rider, seen from the front or from behind, facing right. Load it after figures.lua:
--   local F = dofile(app.params.root .. '/art/war/lib/figures.lua')
--   local X = dofile(app.params.root .. '/art/war/lib/fight.lua')(F)
--   X.blow(kind, back, n), X.riderBlow(back, n), X.struck(kind, back, n)   -- grids of letters, drawn with F.render(X.S, side, g)
-- A blow: 1 the wind-up, 2 the strike (with a pale smear where the weapon swept), 3 the follow-through, 4 the recovery.
-- Taking a blow: 1 knocked back in a pale hit flash, blood thrown off, 2 staggering, the head still turned away.
return function(F)
local W, grid, P = F.W, F.grid, F.P
local S = F.STYLES.B
S.common.v = { '#8a8c82', '#a6a89c', '#c2c2b4' }                -- the smear of a weapon sweeping
S.common.y = { '#a89e88', '#bab09a', '#ccc2ac' }                -- a bowstring
S.common.w = { '#6a5238', '#8a6c4a', '#a4865e' }                -- weapon shafts, light enough to read on grass
local G = F.GEO[S.geo]

local function line(g, x0, y0, x1, y1, ch)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
  local err = dx + dy
  while true do
    P(g, x0, y0, 1, 1, ch)
    if x0 == x1 and y0 == y1 then return end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end
local function shifted(src, dx, dy, from, to)
  local g = grid(src.w, src.h)
  for y = 0, src.h - 1 do for x = 0, src.w - 1 do
    local ch = src[y][x]
    if ch then local ddx = (y >= (from or 0) and y < (to or 99)) and dx or dx; P(g, x + ddx, y + dy, 1, 1, ch) end
  end end
  return g
end

-- The body of a man on foot without legs or weapon, leaning `L` pixels forward (negative: back).
local function upper(g, kind, back, L)
  local bx, by, bw, bh = G.bx + L, G.by, G.bw, G.bh
  local bx2 = bx + bw
  P(g, bx, by, bw, bh, kind == 'levy' and 'u' or 't'); P(g, bx, by + bh - 2, bw, 1, 'd')
  if kind == 'levy' then P(g, bx, by, 1, bh - 2, 't'); P(g, bx + 1, by, 1, 1, 't') end
  if kind == 'spear' or kind == 'sword' then P(g, bx, by, bw, 2, 'i') end
  local hx, hy, hw, hh = G.hx + L, G.hy, G.hw, G.hh
  P(g, hx, hy, hw, hh, back and 'a' or 'k')
  if not back then P(g, hx + hw - 2, hy + 1, 1, 1, 'e') end
  if kind == 'spear' then P(g, hx, hy - 1, hw, 2, 'h'); P(g, hx - 1, hy, hw + 2, 1, 'h')
  elseif kind == 'sword' then P(g, hx, hy - 2, hw, 3, 'h'); P(g, hx - 1, hy, hw + 2, 1, 'h'); if not back then P(g, hx + hw - 2, hy + 1, 1, 2, 'h') end; P(g, hx + 1, hy - 3, 2, 1, 'r')
  elseif kind == 'archer' then P(g, hx, hy - 1, hw, 2, 'd'); P(g, hx + hw, hy - 1, 2, 1, 'r')
  else P(g, hx - 1, hy - 1, hw + 2, 2, 'q'); P(g, hx - 1, hy, 1, hh, 'q') end
  if kind == 'archer' then if back then P(g, bx + 1, by, 2, bh - 2, 'q') else P(g, bx - 1, by - 1, 2, bh - 1, 'q') end end
  if kind == 'spear' or kind == 'sword' then
    if back then P(g, bx2 - 2, by + 1, 3, bh - 1, 'd')
    else P(g, bx - 2, by + 1, 4, bh - 1, 'l'); P(g, bx - 2, by + 1, 4, 1, 'r'); P(g, bx - 2, by + bh - 1, 4, 1, 'r'); P(g, bx - 1, by + 3, 2, 2, 'c') end
  end
  return bx2
end
-- Legs planted for a blow: the back leg braced behind, the front one stepped forward; wider at the strike.
local function stance(g, wide)
  local b, f = wide and 4 or 5, wide and 10 or 9
  line(g, 6, G.ly, b, 18, 'd'); P(g, b - 1, 19, 2, 1, 'b')
  line(g, 8, G.ly, f, 18, 'd'); P(g, f, 19, 2, 1, 'b')
end

local LEAN = { -1, 2, 1, 0 }                                        -- the strike is a lunge
--- A man on foot, blow frame n (1-4).
local function blow(kind, back, n)
  local g = grid(16, 20)
  if kind == 'rider' then return nil end
  stance(g, n == 2 or n == 3)
  local L = (kind == 'archer') and 0 or LEAN[n]
  local bx2 = upper(g, kind, back, L)
  local by, bh = G.by, G.bh
  local arm = function(x, y, h) P(g, x, y, 1, h, back and 'd' or 'k') end
  if kind == 'spear' or kind == 'levy' then
    local tip = function(x, y)                                       -- a spearhead, or the two tines of a pitchfork
      if kind == 'spear' then P(g, x, y - 1, 1, 3, 's'); P(g, x + 1, y, 1, 1, 's') else P(g, x, y - 1, 2, 1, 's'); P(g, x, y + 1, 2, 1, 's') end
    end
    if n == 1 then line(g, 1 + L, by + 1, 11 + L, by + 1, 'w'); tip(12 + L, by + 1); arm(bx2 - 3, by + 1, 3)
    elseif n == 2 then line(g, 4 + L, by + 2, 13, by + 2, 'w'); tip(14, by + 2); arm(bx2 - 1, by + 2, 2); P(g, 2 + L, by + 1, 1, 1, 'v'); P(g, 1 + L, by + 3, 2, 1, 'v')
    elseif n == 3 then line(g, 5 + L, by + 1, 13, by + 5, 'w'); tip(14, by + 5); arm(bx2 - 1, by + 2, 3)
    else line(g, bx2 - 1, by + 7, bx2 + 2, 1, 'w'); tip(bx2 + 2, 1); arm(bx2 - 1, by + 2, 4) end
  elseif kind == 'sword' then
    if n == 1 then line(g, bx2 - 1, by, bx2 - 4, by - 6, 's'); P(g, bx2 - 1, by + 1, 2, 1, 'w'); arm(bx2 - 1, by - 1, 3)
    elseif n == 2 then line(g, bx2, by + 1, bx2 + 5, by - 3, 's'); P(g, bx2 - 1, by + 1, 1, 2, 'w'); P(g, bx2 - 2, by - 4, 1, 1, 'v'); P(g, bx2, by - 5, 2, 1, 'v'); P(g, bx2 + 3, by - 5, 1, 1, 'v'); arm(bx2 - 1, by + 1, 2)
    elseif n == 3 then line(g, bx2, by + 2, bx2 + 5, by + 6, 's'); P(g, bx2 - 1, by + 2, 1, 1, 'w'); P(g, bx2 + 5, by - 1, 1, 2, 'v'); P(g, bx2 + 6, by + 2, 1, 2, 'v'); arm(bx2 - 1, by + 2, 2)
    else P(g, bx2, by - 2, 1, 6, 's'); P(g, bx2 - 1, by + 4, 3, 1, 'w'); arm(bx2 - 1, by + 2, 3) end
  else                                                                -- archer
    if n == 1 then P(g, bx2 + 1, by - 2, 1, bh + 2, 'w'); P(g, bx2, by - 3, 1, 1, 'w'); P(g, bx2, by + bh, 1, 1, 'w'); P(g, bx2 - 1, by + 2, 4, 1, 's'); arm(bx2 - 1, by + 2, 2)
    elseif n == 2 then
      P(g, bx2 + 2, by - 2, 1, bh + 2, 'w'); P(g, bx2 + 1, by - 3, 1, 1, 'w'); P(g, bx2 + 1, by + bh, 1, 1, 'w')
      line(g, bx2 + 1, by - 3, bx2 - 2, by + 2, 'y'); line(g, bx2 + 1, by + bh, bx2 - 2, by + 2, 'y'); P(g, bx2 - 2, by + 2, 7, 1, 's'); arm(bx2 - 3, by + 2, 2)
    elseif n == 3 then
      P(g, bx2 + 2, by - 3, 1, bh + 4, 'w'); P(g, bx2 + 1, by - 3, 1, bh + 4, 'y')
      P(g, bx2 + 4, by + 2, 1, 1, 'v'); P(g, bx2 + 6, by + 2, 2, 1, 'v'); P(g, 15, by + 2, 1, 1, 's'); arm(bx2 - 1, by + 2, 2)
    else line(g, bx2 - 1, by + bh + 2, bx2 + 3, by - 1, 'w'); arm(bx2 - 1, by + 3, 3) end
  end
  return g
end
--- A rider, blow frame n (1-4): the lance couched, driven home at the gallop, held through, raised again.
local function riderBlow(back, n)
  local g = grid(16, 20)
  local legs = n == 2 and { 2, 0, 2, 0 } or n == 3 and { 0, 2, 0, 2 } or { 1, 1, 1, 1 }
  local lift = (n == 2) and 1 or 0                                     -- the horse surges: head and chest up a pixel
  P(g, 2, 10, 11, 5, 'n'); P(g, 2, 14, 11, 1, 'N')
  for k, x in ipairs({ 3, 5, 9, 11 }) do local up = legs[k] > 0 and 1 or 0; P(g, x + (k > 2 and up or -up), 15, 1, 4 - up, 'N'); P(g, x + (k > 2 and up or -up), 19 - up, 1, 1, 'b') end
  if not back then P(g, 12, 6 - lift, 2, 5, 'n'); P(g, 13, 5 - lift, 3, 3, 'n'); P(g, 15, 6 - lift, 1, 1, 'e'); P(g, 12, 5 - lift, 1, 3, 'm')
  else P(g, 12, 7 - lift, 2, 4, 'N'); P(g, 12, 6 - lift, 2, 1, 'm') end
  P(g, 1, 10, 1, 4, 'm'); P(g, 4, 9, 7, 2, 't'); P(g, 4, 11, 7, 1, 'r')
  local L = (n == 2 or n == 3) and 1 or 0
  P(g, 6 + L, 3, 4, 6, 't'); P(g, 6 + L, 8, 4, 1, 'd')
  P(g, 7 + L, 0, 3, 3, back and 'a' or 'k'); P(g, 7 + L, 0, 3, 1, 'h'); if not back then P(g, 9 + L, 1, 1, 1, 'e') end
  if n == 1 then P(g, 1, 5, 11, 1, 'w'); P(g, 12, 4, 1, 3, 's')
  elseif n == 2 then P(g, 7, 5, 8, 1, 'w'); P(g, 14, 4, 2, 3, 's'); P(g, 3, 4, 2, 1, 'v'); P(g, 2, 6, 3, 1, 'v')
  elseif n == 3 then line(g, 8, 5, 14, 8, 'w'); P(g, 15, 8, 1, 2, 's')
  else line(g, 9, 7, 13, 0, 'w'); P(g, 13, 0, 2, 1, 's') end
  P(g, 5 + L, 4, 2, 4, 'l')
  return g
end
--- Taking a blow: 1 knocked back with blood thrown off, 2 staggering.
local function struck(kind, back, n)
  local base = F.figure(S, kind, back, 4)
  local g
  local rider = kind == 'rider'
  if n == 1 then
    g = shifted(base, -1, -1)
    -- the hit flash: for that instant the man (not his horse) is all pale, which reads even when he is a few pixels tall
    for y = 0, rider and 9 or 19 do for x = 0, 15 do if g[y][x] then g[y][x] = 'f' end end end
    local cx, cy = rider and 9 or 9, rider and 5 or 8
    P(g, cx, cy, 2, 2, 'f'); P(g, cx + 2, cy - 1, 1, 1, 'f'); P(g, cx + 2, cy + 2, 1, 1, 'f')
    P(g, cx - 1, cy + 1, 1, 1, 'x'); P(g, rider and 4 or 2, cy - 1, 1, 1, 'x'); P(g, rider and 3 or 1, cy + 1, 1, 1, 'x'); P(g, rider and 5 or 3, cy - 2, 1, 1, 'x')
  else
    g = grid(16, 20)
    for y = 0, 19 do for x = 0, 15 do local ch = base[y][x]; if ch then
      local dx = rider and -1 or (y < G.by and -3 or (y < G.ly and -2 or -1))   -- the head thrown furthest back
      P(g, x + dx, y, 1, 1, ch)
    end end end
    P(g, rider and 6 or 7, 19, 1, 1, 'x'); P(g, rider and 9 or 4, 18, 1, 1, 'x')
  end
  return g
end


return { S = S, line = line, blow = blow, riderBlow = riderBlow, struck = struck }
end
