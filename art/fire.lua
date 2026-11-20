-- Every building on fire: three frames per rotation, made from the finished drawings (run after run.lua).
--   Aseprite -b --script-param root=<path to art> --script <path to art>/fire.lua
-- Reads art/out/buildings/<item>_r<rot>.png, writes <item>_fire<frame>_r<rot>.png (same size) and a preview.
-- The building is scorched; tongues of flame stand on its upper parts and flicker from frame to frame; smoke rises.
local root = app.params.root
local ink = dofile(root .. '/lib/ink.lua')
local P, hex, hash, pc = ink.P, ink.hex, ink.hash, app.pixelColor
local ITEMS = { 'hut', 'well', 'lodge', 'granary', 'carpenter', 'cottage', 'green', 'mill', 'bakery', 'brewery', 'tavern', 'market',
  'chapel', 'watch_house', 'guildhall', 'great_church', 'hospital', 'fairground', 'hen_house', "forager's_hut", 'storehouse' }
local char = hex(P.char)
local function scorch(c, k)
  local cr, cg, cb = pc.rgbaR(char), pc.rgbaG(char), pc.rgbaB(char)
  return pc.rgba(math.floor(pc.rgbaR(c) * (1 - k) + cr * k), math.floor(pc.rgbaG(c) * (1 - k) + cg * k), math.floor(pc.rgbaB(c) * (1 - k) + cb * k), 255)
end
local shown = {}
for n, item in ipairs(ITEMS) do
  for rot = 0, 3 do
    local src = Image { fromFile = root .. '/out/buildings/' .. item .. '_r' .. rot .. '.png' }
    if src then
      local W, H = src.width, src.height
      local top = H
      for y = 0, H - 1 do for x = 0, W - 1 do if pc.rgbaA(src:getPixel(x, y)) > 0 and y < top then top = y end end end
      -- where flames stand: solid pixels in the upper part, chosen the same way every time
      local spots, want = {}, math.max(3, W // 9)
      local tries = 0
      while #spots < want and tries < 4000 do
        tries = tries + 1
        local x = 3 + math.floor(hash(tries * 7 + n, rot * 13 + 1) * (W - 6))
        local y = top + math.floor(hash(tries * 11 + 5, n + rot) * (H - top) * 0.6)
        if pc.rgbaA(src:getPixel(x, y)) > 0 then spots[#spots + 1] = { x, y, 7 + math.floor(hash(x, y) * 8) } end
      end
      for f = 0, 2 do
        local img = Image(W, H, ColorMode.RGB)
        for y = 0, H - 1 do for x = 0, W - 1 do
          local c = src:getPixel(x, y)
          if pc.rgbaA(c) > 0 then img:drawPixel(x, y, scorch(c, 0.28 + 0.3 * hash(x // 5, y // 4 + n))) end
        end end
        local function put(x, y, c) if x >= 0 and y >= 0 and x < W and y < H then img:drawPixel(x, y, hex(c)) end end
        for k, s in ipairs(spots) do
          local tall = s[3] + ((f + k) % 3) * 2 - 1
          local lean = ((f + k) % 3) - 1
          for dy = 0, tall do                                   -- a tongue: wide near its foot, a point at the top
            local t = dy / tall
            local half = math.floor((1 - t) * 2.6 * (dy < 2 and 0.6 or 1) + 0.5)
            local cx = s[1] + math.floor(lean * t * 2 + 0.5)
            for dx = -half, half do
              put(cx + dx, s[2] - dy, (math.abs(dx) < half and t < 0.55) and P.flameCore or (t > 0.8 and P.ember or P.flame))
            end
          end
          for p = 1, 3 do                                       -- smoke drifting up and to the right
            local sy = s[2] - tall - 3 - p * 5 - f * 2
            local sx = s[1] + p * 2 + ((f + p) % 2)
            if (k + p + f) % 2 == 0 then for dy = -1, 1 do for dx = -1, 1 do if dx * dx + dy * dy <= 1 then put(sx + dx, sy + dy, P.smoke) end end end end
          end
        end
        img:saveAs(root .. '/out/buildings/' .. item .. '_fire' .. f .. '_r' .. rot .. '.png')
        if rot == 0 and (f == 0 or f == 1) and (item == 'hut' or item == 'cottage' or item == 'tavern' or item == 'chapel') then shown[#shown + 1] = { img = img } end
      end
    end
  end
end
ink.sheet(root .. '/out/preview/_fire.png', shown, 8, 3)
print('ok fire')
