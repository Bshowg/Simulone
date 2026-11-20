-- Small helpers for drawing WAR's art in Aseprite batch mode. Load it with:
--   local W = dofile(app.params.root .. '/art/war/lib/wpx.lua')
-- Everything is drawn pixel by pixel on images with a transparent background, with hard pixels (fully opaque or fully
-- transparent), and saved as PNG.
local W = {}
local pc = app.pixelColor

function W.rgb(s) return tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16) end
local function clamp(v) return math.max(0, math.min(255, math.floor(v + 0.5))) end
--- A colour from '#rrggbb', optionally lighter or darker by a factor.
function W.hex(s, f) local r, g, b = W.rgb(s); f = f or 1; return pc.rgba(clamp(r * f), clamp(g * f), clamp(b * f), 255) end
--- Between two '#rrggbb' colours.
function W.mix(a, b, t) local r1, g1, b1 = W.rgb(a); local r2, g2, b2 = W.rgb(b); return pc.rgba(clamp(r1 + (r2 - r1) * t), clamp(g1 + (g2 - g1) * t), clamp(b1 + (b2 - b1) * t), 255) end
function W.alpha(c) return pc.rgbaA(c) end

--- A fixed "random" number 0..1 for a pair of whole numbers.
function W.hash(x, y)
  local n = (math.floor(x) * 374761393 + math.floor(y) * 668265263) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  return ((n ~ (n >> 16)) % 1000) / 1000
end
--- Smooth noise 0..1 with features about `size` pixels across.
function W.smooth(x, y, size, seed)
  local gx, gy = x / size, y / size
  local x0, y0 = math.floor(gx), math.floor(gy)
  local fx, fy = gx - x0, gy - y0
  fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
  local function g(ix, iy) return W.hash(ix + (seed or 0) * 57, iy + (seed or 0) * 131) end
  local a, b, c, d = g(x0, y0), g(x0 + 1, y0), g(x0, y0 + 1), g(x0 + 1, y0 + 1)
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy
end

function W.image(w, h) return Image(w, h, ColorMode.RGB) end
function W.put(img, x, y, c) x, y = math.floor(x), math.floor(y); if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end end
function W.get(img, x, y) if x < 0 or y < 0 or x >= img.width or y >= img.height then return 0 end; return img:getPixel(x, y) end
function W.solid(img, x, y) return pc.rgbaA(W.get(img, x, y)) > 0 end
function W.rect(img, x, y, w, h, c) for j = 0, h - 1 do for i = 0, w - 1 do W.put(img, x + i, y + j, c) end end end
function W.fill(img, f) for y = 0, img.height - 1 do for x = 0, img.width - 1 do local c = f(x, y); if c then img:drawPixel(x, y, c) end end end end
--- Copy src onto dst at (x, y), skipping transparent pixels; `flip` mirrors it left to right.
function W.blit(dst, src, x, y, flip)
  for j = 0, src.height - 1 do for i = 0, src.width - 1 do
    local c = src:getPixel(flip and (src.width - 1 - i) or i, j)
    if pc.rgbaA(c) > 0 then W.put(dst, x + i, y + j, c) end
  end end
end
--- The image enlarged `z` times with hard pixels.
function W.scale(img, z)
  local big = Image(img.width * z, img.height * z, ColorMode.RGB)
  for y = 0, img.height - 1 do for x = 0, img.width - 1 do
    local c = img:getPixel(x, y)
    if pc.rgbaA(c) > 0 then for j = 0, z - 1 do for i = 0, z - 1 do big:drawPixel(x * z + i, y * z + j, c) end end end
  end end
  return big
end
function W.save(img, path) img:saveAs(app.params.root .. '/' .. path) end

return W
