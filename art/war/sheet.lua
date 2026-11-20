-- WAR's sprite sheet for the game, in the Chronicle style (proposal B, chosen by the owner). Writes:
--   games/war/art.png         the sheet the battle view draws from
--   games/war/art-atlas.js    where everything is on it (read by games/war/art.js); written here, never by hand
--   art/war/shots/sheet.png   the sheet at 3x, on grass, to look at
-- Run from Git Bash:
--   "/c/Program Files/Aseprite/Aseprite.exe" -b --script-param root="$(pwd -W)" --script art/war/sheet.lua
--
-- Layout. A frame is 16 x 20, the feet on its bottom row. Each kind and realm has one row; in it, four facings one
-- after the other (front-right, back-right, back-left, front-left: the left ones are the right ones mirrored), and in
-- each facing eleven poses: walking 1-4, standing, the blow 1-4, struck 1-2. The fallen have a row per realm with four
-- bodies. Then three trees, then the ground textures (each 32 x 32 and seamless).
local root = app.params.root
local F = dofile(root .. '/art/war/lib/figures.lua')
local X = dofile(root .. '/art/war/lib/fight.lua')(F)
local W, S, render = F.W, X.S, F.render
local TYPES = { 'levy', 'spear', 'sword', 'archer', 'rider', 'fallen' }   -- the game's agent types, in its order
local SIDES, POSES, DIRS, FW, FH = 2, 11, 4, 16, 20
local TEX = 32
local GROUND = { 'floor', 'woods', 'hill', 'stream', 'ford', 'road', 'field' }

local rowsH = #TYPES * SIDES * FH
local treeY, groundY = rowsH, rowsH + 26
local sheet = W.image(DIRS * POSES * FW, groundY + TEX)

local function pose(kind, back, p)
  if p <= 4 then return F.figure(S, kind, back, p) end
  if p <= 8 then return kind == 'rider' and X.riderBlow(back, p - 4) or X.blow(kind, back, p - 4) end
  return X.struck(kind, back, p - 8)
end
for t, kind in ipairs(TYPES) do for side = 0, SIDES - 1 do
  local y = ((t - 1) * SIDES + side) * FH
  if kind == 'fallen' then
    local bodies = { 'spear', 'sword', 'levy', 'archer' }
    for k = 0, 3 do W.blit(sheet, render(S, side, F.fallenFig(bodies[k + 1], k)), k * FW, y) end
  else
    for dir = 0, 1 do for p = 0, POSES - 1 do
      local img = render(S, side, pose(kind, dir == 1, p))
      W.blit(sheet, img, (dir * POSES + p) * FW, y)
      W.blit(sheet, img, ((3 - dir) * POSES + p) * FW, y, true)          -- the same, facing left
    end end
  end
end end
local trees = {}
for k = 0, 2 do W.blit(sheet, render(S, 0, F.treeFig(k)), k * 18, treeY); trees[#trees + 1] = { x = k * 18, y = treeY, w = 18, h = 26 } end

-- Ground: seamless 32 x 32 textures, grain at two sizes in each ramp (noise that repeats every 32 pixels).
local function hashp(x, y) return W.hash(x % TEX, y % TEX) end
local function smoothp(x, y, size, seed)
  local n = TEX // size
  local gx, gy = x / size, y / size
  local x0, y0 = math.floor(gx), math.floor(gy)
  local fx, fy = gx - x0, gy - y0
  fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
  local g = function(i, j) return W.hash((i % n) + seed * 57, (j % n) + seed * 131) end
  local a, b, c, d = g(x0, y0), g(x0 + 1, y0), g(x0, y0 + 1), g(x0 + 1, y0 + 1)
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy
end
local RAMPS = {
  floor  = { '#3a5228', '#445e2e', '#4e6a34', '#58763a' },
  woods  = { '#2c4020', '#344a26', '#3c542a', '#465e30' },
  hill   = { '#56663a', '#606f40', '#6a7846', '#74824c' },
  stream = { '#22404c', '#284a58', '#2e5262', '#365c6c' },
  ford   = { '#4a6a70', '#527478', '#5a7e82', '#64888a' },
  road   = { '#5a4c36', '#64563e', '#6e6046', '#7a6a4e' },
  field  = { '#7a6a3e', '#857446', '#907e4e', '#9a8856' },
}
local groundRects = {}
for k, key in ipairs(GROUND) do
  local ox = (k - 1) * TEX
  local ramp = RAMPS[key]
  for y = 0, TEX - 1 do for x = 0, TEX - 1 do
    local n = smoothp(x, y, 8, k) * 0.55 + hashp(x * 3 + k, y * 5) * 0.45
    local c = ramp[math.min(#ramp, math.floor(n * #ramp) + 1)]
    if key == 'field' and y % 4 == 0 then c = ramp[1] end                   -- furrows
    if key == 'stream' and hashp(x // 3 + k, y) > 0.93 then c = '#5e8a96' end   -- light on the water
    if key == 'road' and hashp(x, y * 3) > 0.94 then c = '#8a7a5c' end       -- stones
    if (key == 'floor' or key == 'hill') and hashp(x * 7, y * 11) > 0.97 then c = '#7a8a4a' end   -- a lighter blade here and there
    W.put(sheet, ox + x, groundY + y, W.hex(c))
  end end
  groundRects[key] = { x = ox, y = groundY, w = TEX, h = TEX }
end
sheet:saveAs(root .. '/games/war/art.png')

-- The layout, for the game.
local function rect(r) return string.format('{ x: %d, y: %d, w: %d, h: %d }', r.x, r.y, r.w, r.h) end
local parts = {}
for _, key in ipairs(GROUND) do parts[#parts + 1] = string.format('%s: %s', key, rect(groundRects[key])) end
local treeParts = {}
for _, r in ipairs(trees) do treeParts[#treeParts + 1] = rect(r) end
local f = io.open(root .. '/games/war/art-atlas.js', 'w')
f:write('// Where everything is on art.png. Written by art/war/sheet.lua (run it in Aseprite after changing the art); not by hand.\n')
f:write('// A row per agent type and realm (types in this order); in a row four facings (front-right, back-right, back-left,\n')
f:write('// front-left), each with these poses. The fallen have four bodies in their row.\n')
f:write(string.format('export const ATLAS = {\n  width: %d, height: %d, frame: { w: %d, h: %d },\n', sheet.width, sheet.height, FW, FH))
f:write(string.format("  types: ['%s'], sides: %d, dirs: %d,\n", table.concat(TYPES, "', '"), SIDES, DIRS))
f:write("  poses: ['walk1', 'walk2', 'walk3', 'walk4', 'stand', 'blow1', 'blow2', 'blow3', 'blow4', 'struck1', 'struck2'],\n")
f:write('  trees: [' .. table.concat(treeParts, ', ') .. '],\n')
f:write('  ground: { ' .. table.concat(parts, ', ') .. ' },\n};\n')
f:close()

-- To look at: the sheet at 3x on grass.
local look = W.image(sheet.width, sheet.height)
W.fill(look, function(x, y) return W.hex(RAMPS.floor[1 + ((x // 4 + y // 4) % 2)]) end)
W.blit(look, sheet, 0, 0)
W.save(W.scale(look, 3), 'art/war/shots/sheet.png')
print('ok sheet ' .. sheet.width .. 'x' .. sheet.height)
