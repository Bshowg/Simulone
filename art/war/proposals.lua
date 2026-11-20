-- WAR: three proposals for the battle art, drawn at the sizes the battle view uses today (a 16 x 8 ground cell, a
-- 16 x 20 frame for a man or a rider). For each proposal it writes, into art/war/proposals/:
--   <S>-sheet.png      every kind of soldier for both realms (front: standing, four walking frames, striking, reeling,
--                      fallen; back: standing, walking, striking), the two standards, a tree, and a patch of ground; 3x
--   <S>-scene-1x.png   a small battle at real scale
--   <S>-scene-3x.png   the same, three times larger (about how a phone shows it close up)
-- Run from Git Bash:
--   "/c/Program Files/Aseprite/Aseprite.exe" -b --script-param root="$(pwd -W)" --script art/war/proposals.lua
-- (add --script-param style=A to draw only one)
--
-- The three proposals share one figure geometry per proportion and differ in how it is drawn:
--   A  Heraldic      chunky figures with a dark outline, clean flat colour, bold shields with the realm's charge
--   B  Chronicle     slimmer figures, no outline, muted wool and iron lit from the upper left, textured earth
--   C  Manuscript    brown ink outline and pale washes on a paper-coloured field, like a page of a chronicle
local root = app.params.root
local F = dofile(root .. '/art/war/lib/figures.lua')
local W, KINDS, STYLES, figure, fallenFig, standardFig, treeFig, render, field = F.W, F.KINDS, F.STYLES, F.figure, F.fallenFig, F.standardFig, F.treeFig, F.render, F.field
local only = app.params.style

-- ───────────────────────── one proposal ─────────────────────────
local function draw(key)
  local S = STYLES[key]
  local cache = {}
  local function man(kind, side, back, pose) local k = kind .. side .. tostring(back) .. pose; cache[k] = cache[k] or render(S, side, figure(S, kind, back, pose)); return cache[k] end
  local function dead(kind, side, k) local id = 'dead' .. kind .. side .. k; cache[id] = cache[id] or render(S, side, fallenFig(kind, k)); return cache[id] end
  local trees = { render(S, 0, treeFig(0)), render(S, 0, treeFig(1)), render(S, 0, treeFig(2)) }
  local flags = { render(S, 0, standardFig(0)), render(S, 1, standardFig(1)) }

  -- the sheet: a row per kind and realm
  local cols = { { false, 4 }, { false, 0 }, { false, 1 }, { false, 2 }, { false, 3 }, { false, 5 }, { false, 6 }, 'dead', { true, 4 }, { true, 1 }, { true, 5 }, { true, 6 } }
  local pitchX, pitchY = 18, 22
  local sheetW, sheetH = #cols * pitchX + 60, #KINDS * 2 * pitchY + 100
  local sheet = W.image(sheetW, sheetH)
  local bg = S.ground.grass
  W.fill(sheet, function(x, y) return W.hex(bg[1 + ((x // 4 + y // 4) % 2)]) end)
  for k, kind in ipairs(KINDS) do for side = 0, 1 do
    local y = 2 + ((k - 1) * 2 + side) * pitchY
    for c, col in ipairs(cols) do
      local img = col == 'dead' and dead(kind, side, k) or man(kind, side, col[1], col[2])
      W.blit(sheet, img, 2 + (c - 1) * pitchX, y)
    end
  end end
  W.blit(sheet, flags[1], #cols * pitchX + 6, 4); W.blit(sheet, flags[2], #cols * pitchX + 30, 4)
  for t = 1, 3 do W.blit(sheet, trees[t], #cols * pitchX + 4 + (t - 1) * 18 // 1, 44 + (t - 1) * 30) end
  -- a patch of ground: grass, woods, a stream with a ford, a field, a rise
  local patchT = function(x, y) if x >= 5 then return 'woods' elseif y == 3 then return x == 2 and 'ford' or 'stream' elseif x <= 1 and y <= 1 then return 'field' elseif x <= 1 and y >= 5 then return 'hill' else return 'grass' end end
  local ps = {}
  for y = 0, 6 do for x = 5, 6 do if W.hash(x, y) > 0.2 then ps[#ps + 1] = { x = x + 0.5, y = y + 0.5, img = trees[1 + (x + y) % 3] } end end end
  local patch = field(S, 7, 7, patchT, ps, 24)
  W.blit(sheet, patch, 2, #KINDS * 2 * pitchY + 2 - 24 + 20)
  W.save(W.scale(sheet, 3), 'art/war/proposals/' .. key .. '-sheet.png')

  -- the mock battle: the Crown's spears and archers at the top, the March's swords, levies and archers at the bottom,
  -- their front ranks fighting across the middle, the Crown's riders charging on the right
  local CW, CH = 20, 20
  local terrainT = function(x, y)
    if x - y >= 6 and x + y <= 17 then return 'woods' end
    if y - x >= 9 then return 'field' end
    if x + y >= 30 and x + y <= 31 then return (x - y == 2) and 'ford' or 'stream' end
    if x - y <= -4 and x + y <= 10 then return 'hill' end
    return 'grass'
  end
  -- positions are given across the screen (u, in cells) and down it (v): x - y = u, x + y = 21 + v
  local sp = {}
  local at = function(u, v) v = v * 1.45 + 1.5; return (21 + v + u) / 2, (21 + v - u) / 2 end   -- depth spread a little, so the gap reads
  local function add(kind, side, u, v, pose) local x, y = at(u, v); sp[#sp + 1] = { x = x, y = y, img = man(kind, side, side == 0, pose), flip = side == 1 } end
  local function put(img, u, v, flip) local x, y = at(u, v); sp[#sp + 1] = { x = x, y = y, img = img, flip = flip } end
  local r = function(a, b) return W.hash(a * 13 + 7, b * 29 + 3) end
  for k = 0, 8 do put(trees[1 + k % 3], 8.4 + (k % 3) * 1.5 + r(k, 1) * 0.6, -8.6 + (k // 3) * 1.1 + r(k, 2) * 0.5) end
  -- the Crown at the top: archers, three ranks of spears; riders on its right
  for f = 0, 11 do for rk = 0, 1 do add('archer', 1, -6 + f * 0.9 + rk * 0.45, -13 + rk * 0.8, r(f, rk) > 0.5 and 5 or 4) end end
  for f = 0, 13 do for rk = 0, 2 do add('spear', 1, -8 + f * 0.85, -9.6 + rk * 0.8, rk == 2 and (r(f, 9) > 0.6 and 5 or 4) or 4) end end
  for k = 0, 5 do add('rider', 1, 5.5 + (k % 3) * 1.6, -4.5 + (k // 3) * 1.2, k < 3 and 5 or (k % 2)) end
  -- the March at the bottom: three ranks of swords, levies on the right, archers behind
  for f = 0, 11 do for rk = 0, 2 do add('sword', 0, -9 + f * 0.85, 0.2 + rk * 0.8, rk == 0 and (r(f, 4) > 0.5 and 5 or 4) or (r(f, rk) > 0.85 and 1 or 4)) end end
  for f = 0, 4 do for rk = 0, 2 do add('levy', 0, 1.6 + f * 0.85, 0.4 + rk * 0.8, rk == 0 and (r(f, 7) > 0.5 and 6 or 5) or ((f + rk) % 4)) end end
  for f = 0, 12 do add('archer', 0, -8 + f * 0.95, 4.6, r(f, 21) > 0.4 and 5 or 4) end
  -- in the gap: men fighting in pairs, and the fallen
  for k = 0, 5 do
    local u = -7.5 + k * 2.2
    add('spear', 1, u, -4.3, k % 2 == 0 and 6 or 5)
    add(k % 3 == 2 and 'levy' or 'sword', 0, u + 0.6, -3.1, k % 2 == 0 and 5 or 6)
  end
  for k = 0, 15 do
    local side = k % 2
    local kind = side == 1 and 'spear' or (k % 3 == 0 and 'levy' or 'sword')
    put(dead(kind, side, k), -9 + r(k, 1) * 17, -6.5 + r(k, 2) * 5, r(k, 3) > 0.5)
  end
  put(dead('rider', 1, 1), 6.8, -1.6); put(dead('levy', 0, 2), 4.2, -0.9, true)
  -- the standards
  put(flags[2], -1.2, -10.8); put(flags[1], -2, 2.4)
  local scene = field(S, CW, CH, terrainT, sp, 34)
  W.save(scene, 'art/war/proposals/' .. key .. '-scene-1x.png')
  W.save(W.scale(scene, 3), 'art/war/proposals/' .. key .. '-scene-3x.png')
  print('ok ' .. key .. ' ' .. S.name .. ': sheet ' .. sheetW .. 'x' .. sheetH .. ', scene ' .. scene.width .. 'x' .. scene.height)
end

for _, key in ipairs({ 'A', 'B', 'C' }) do if not only or only == key then draw(key) end end
