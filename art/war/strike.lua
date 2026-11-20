-- WAR, proposal B (Chronicle) with fighting animated: four frames for a blow and two for taking one, for every kind and
-- both realms, seen from the front and from behind. Writes into art/war/shots/:
--   B-strike-sheet.png  every kind and realm: front (standing, blow 1-4, struck 1-2) and back (blow 1-4, struck 1-2); 3x
--   B-duel.gif          a swordsman of the March and a spearman of the Crown trading blows, 5x
--   B-melee.gif         two front ranks fighting, at the scale of the battle view, 3x
--   B-duel-strip.png    the duel's twelve frames side by side, 4x
-- Run from Git Bash:
--   "/c/Program Files/Aseprite/Aseprite.exe" -b --script-param root="$(pwd -W)" --script art/war/strike.lua
--
-- A blow: 1 the wind-up (weight back, the weapon drawn or raised), 2 the strike (weight forward, the weapon at full
-- reach, a pale smear where it swept), 3 the follow-through, 4 the recovery. Taking a blow: 1 knocked back with blood
-- thrown off, 2 staggering, the head still turned away.
local F = dofile(app.params.root .. '/art/war/lib/figures.lua')
local X = dofile(app.params.root .. '/art/war/lib/fight.lua')(F)
local W, KINDS, grid, P, render = F.W, F.KINDS, F.grid, F.P, F.render
local S, blow, riderBlow, struck = X.S, X.blow, X.riderBlow, X.struck

-- ───────────────────────── the sheet ─────────────────────────
local cache = {}
local function img(kind, side, back, what)
  local k = kind .. side .. tostring(back) .. what
  if not cache[k] then
    local g
    if what == 'stand' then g = F.figure(S, kind, back, 4)
    elseif what:sub(1, 1) == 'a' then local n = tonumber(what:sub(2)); g = kind == 'rider' and riderBlow(back, n) or blow(kind, back, n)
    else g = struck(kind, back, tonumber(what:sub(2))) end
    cache[k] = render(S, side, g)
  end
  return cache[k]
end
local cols = { { false, 'stand' }, { false, 'a1' }, { false, 'a2' }, { false, 'a3' }, { false, 'a4' }, { false, 'r1' }, { false, 'r2' },
  { true, 'a1' }, { true, 'a2' }, { true, 'a3' }, { true, 'a4' }, { true, 'r1' }, { true, 'r2' } }
local px, py = 18, 22
local sheet = W.image(#cols * px + 4 + 8, #KINDS * 2 * py + 4)
W.fill(sheet, function(x, y) return W.hex(S.ground.grass[1 + ((x // 4 + y // 4) % 2)]) end)
for k, kind in ipairs(KINDS) do for side = 0, 1 do
  local y = 2 + ((k - 1) * 2 + side) * py
  for c, col in ipairs(cols) do W.blit(sheet, img(kind, side, col[1], col[2]), 2 + (c - 1) * px + (c > 7 and 8 or 0), y) end
end end
W.save(W.scale(sheet, 3), 'art/war/shots/strike-sheet.png')

-- ───────────────────────── animations ─────────────────────────
local function gif(frames, path, dur)
  local spr = Sprite(frames[1].width, frames[1].height, ColorMode.RGB)
  local layer = spr.layers[1]
  for i, im in ipairs(frames) do
    local fr = (i == 1) and spr.frames[1] or spr:newEmptyFrame()
    spr:newCel(layer, fr, im, Point(0, 0))
    fr.duration = dur
  end
  spr:saveAs(app.params.root .. '/' .. path)
  spr:close()
end
-- One exchange of blows, 12 frames: A strikes and B is struck, then the other way round.
local TL = {
  { 'a1', 'stand' }, { 'a2', 'stand' }, { 'a3', 'r1' }, { 'a4', 'r2' }, { 'stand', 'stand' }, { 'stand', 'stand' },
  { 'stand', 'a1' }, { 'stand', 'a2' }, { 'r1', 'a3' }, { 'r2', 'a4' }, { 'stand', 'stand' }, { 'stand', 'stand' },
}
local grass = function(x, y) local n = W.smooth(x, y, 6, 3) * 0.6 + W.hash(x, y) * 0.4; local r = S.ground.grass; return W.hex(r[math.min(#r, math.floor(n * #r) + 1)]) end
do                                                                    -- the duel: the March's swordsman (from behind) and the Crown's spearman
  local frames, small = {}, {}
  for _, step in ipairs(TL) do
    local im = W.image(56, 40)
    W.fill(im, grass)
    W.blit(im, img('spear', 1, false, step[2]), 23, 10, true)
    W.blit(im, img('sword', 0, true, step[1]), 15, 15)
    frames[#frames + 1] = W.scale(im, 5)
    small[#small + 1] = im
  end
  gif(frames, 'art/war/shots/duel.gif', 0.13)
  local strip = W.image(6 * 58, 2 * 42)                              -- the same twelve frames side by side, for a page
  for i, im in ipairs(small) do W.blit(strip, im, ((i - 1) % 6) * 58, ((i - 1) // 6) * 42) end
  W.save(W.scale(strip, 4), 'art/war/shots/duel-strip.png')
end
do                                                                    -- two front ranks, each pair at its own moment in the exchange
  local cw, ch = 14, 14
  local frames = {}
  for f = 0, 11 do
    local sp = {}
    local at = function(u, v) return (14 + v + u) / 2, (14 + v - u) / 2 end
    local add = function(kind, side, u, v, what) local x, y = at(u, v); sp[#sp + 1] = { x = x, y = y, img = img(kind, side, side == 0, what), flip = side == 1 } end
    for k = 0, 9 do
      local u = -7 + k * 1.45
      local phase = (k * 5) % 12
      local step = TL[((f + phase) % 12) + 1]
      local kindB = (k % 4 == 3) and 'levy' or 'sword'
      add('spear', 1, u, -1.4, step[2])
      add(kindB, 0, u + 0.4, -0.4, step[1])
      add('spear', 1, u + 0.5, -2.3, 'stand'); add(kindB, 0, u - 0.2, 0.5, (k + f) % 6 == 0 and 'a1' or 'stand')
    end
    local scene = F.field(S, cw, ch, function() return 'grass' end, sp, 24)
    local crop = W.image(150, 70)
    W.blit(crop, scene, -((scene.width - 150) // 2), -36)
    frames[#frames + 1] = W.scale(crop, 3)
  end
  gif(frames, 'art/war/shots/melee.gif', 0.12)
end
print('ok strike')
