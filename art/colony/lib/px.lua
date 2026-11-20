-- Shared helpers for drawing The Colony's art in Aseprite batch mode. Load it with:
--   local px = dofile(app.params.root .. '/art/colony/lib/px.lua')
-- and run a script with:
--   Aseprite -b --script-param root=<project folder> --script art/colony/<name>.lua
-- Everything is drawn pixel by pixel on images with a transparent background and saved as PNG at 1x.
local px = {}
local pc = app.pixelColor

px.CELL = 12                                                   -- pixels in one map cell

-- The palette of the chosen look (proposal 2, "soil at 12 px"). Ramps run dark to light.
px.PAL = {
  sky    = { '#86b2d6', '#9cc2de', '#b4d2e4', '#cfe2e8' },
  humus  = { '#33241a', '#3d2b1e', '#463222' },
  loam   = { '#5e4029', '#69482e', '#735034', '#7e593a' },
  sand   = { '#a98852', '#b4935c', '#c0a068', '#ccad76' },
  clay   = { '#6d5448', '#775c4e', '#836656' }, claySeam = '#7b7d84',
  stone  = { '#4e4a46', '#6a655f', '#888279', '#a8a298' },
  grass  = { '#35602a', '#467a33', '#5f953c', '#7fae4a' },
  root   = { '#8a7150', '#bca27c' },
  water  = { '#1f3a4a', '#2c5468', '#7aa8b8' },
  crumb  = { '#a87c2e', '#c8a04a', '#e6c46a' },
  egg = '#f4f0e4', larva = { '#d8c49c', '#e8d8b4' }, pupa = { '#a8875a', '#c2a070' },
  fungus = { '#bdbab0', '#d8d6cc', '#f0eee6' }, leaf = '#6f8a4a',
  ant    = { '#140a07', '#2a160e', '#6a4430' },                  -- body, legs and feelers, the one touch of light
  wall   = 0.66,                                               -- a tunnel's back wall is the earth behind it, this much darker
  dry    = 1.25,                                               -- soil thrown out on the surface dries this much lighter
}

function px.rgb(s) return tonumber(s:sub(2, 3), 16), tonumber(s:sub(4, 5), 16), tonumber(s:sub(6, 7), 16) end
function px.col(r, g, b, a) local c = function(v) return math.max(0, math.min(255, math.floor(v + 0.5))) end; return pc.rgba(c(r), c(g), c(b), a or 255) end
--- A colour from '#rrggbb', optionally made lighter or darker by a factor.
function px.hex(s, f) local r, g, b = px.rgb(s); f = f or 1; return px.col(r * f, g * f, b * f) end
--- A colour between two '#rrggbb' colours.
function px.mix(a, b, t) local r1, g1, b1 = px.rgb(a); local r2, g2, b2 = px.rgb(b); return px.col(r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t) end
--- Pick from a ramp by t in 0..1 (clamped).
function px.ramp(r, t) local i = math.floor(t * #r) + 1; if i < 1 then i = 1 elseif i > #r then i = #r end; return r[i] end

--- A fixed "random" number 0..1 for a pair of whole numbers. The same inputs always give the same output.
function px.hash(x, y)
  local n = (math.floor(x) * 374761393 + math.floor(y) * 668265263) % 4294967296
  n = ((n ~ (n >> 13)) * 1274126177) % 4294967296
  return ((n ~ (n >> 16)) % 1000) / 1000
end
--- The same, repeating every w across and h down: use it for textures that must tile without a seam.
function px.hashp(x, y, w, h) return px.hash(x % w, y % h) end
--- Smooth noise 0..1 with features about `size` pixels across. With w and h it repeats every w × h pixels (they must be
--- multiples of `size`), so a texture made from it tiles without a seam.
function px.smooth(x, y, size, seed, w, h)
  local gx, gy = x / size, y / size
  local x0, y0 = math.floor(gx), math.floor(gy)
  local fx, fy = gx - x0, gy - y0
  fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
  local function g(ix, iy) if w then ix = ix % (w // size); iy = iy % (h // size) end; return px.hash(ix + (seed or 0) * 57, iy + (seed or 0) * 131) end
  local a, b, c, d = g(x0, y0), g(x0 + 1, y0), g(x0, y0 + 1), g(x0 + 1, y0 + 1)
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy
end

--- A new image, fully transparent.
function px.image(w, h) return Image(w, h, ColorMode.RGB) end
function px.put(img, x, y, c) x, y = math.floor(x), math.floor(y); if x >= 0 and y >= 0 and x < img.width and y < img.height then img:drawPixel(x, y, c) end end
function px.get(img, x, y) if x < 0 or y < 0 or x >= img.width or y >= img.height then return 0 end; return img:getPixel(x, y) end
function px.solid(img, x, y) return pc.rgbaA(px.get(img, x, y)) > 0 end
function px.rect(img, x, y, w, h, c) for j = 0, h - 1 do for i = 0, w - 1 do px.put(img, x + i, y + j, c) end end end
--- Fill every pixel from a function f(x, y) → colour (or nil to leave it transparent).
function px.fill(img, f) for y = 0, img.height - 1 do for x = 0, img.width - 1 do local c = f(x, y); if c then img:drawPixel(x, y, c) end end end end
--- Draw rows of letters at (x, y): each letter is looked up in `pal` (a '#rrggbb' string); '.' is left transparent.
--- `flip` mirrors it left to right.
function px.sprite(img, rows, x, y, pal, flip)
  for j, row in ipairs(rows) do for i = 1, #row do
    local ch = row:sub(i, i)
    if ch ~= '.' and pal[ch] then px.put(img, x + (flip and (#row - i) or (i - 1)), y + j - 1, px.hex(pal[ch])) end
  end end
end
--- Copy one image onto another at (x, y), skipping transparent pixels.
function px.blit(dst, src, x, y) for j = 0, src.height - 1 do for i = 0, src.width - 1 do local c = src:getPixel(i, j); if pc.rgbaA(c) > 0 then px.put(dst, x + i, y + j, c) end end end end

--- Save an image as a PNG, creating nothing else. `path` is relative to the project folder.
function px.save(img, path) img:saveAs(app.params.root .. '/' .. path) end

--- A contact sheet for looking at what was drawn: the images in rows, enlarged `zoom` times, on the colour of a tunnel
--- wall (so sprites are judged against what they will stand on). `items` is a list of { image, tile = true|false }:
--- with `tile` the image is repeated 3 × 3 so seams show. Saved to `path`.
function px.sheet(items, path, zoom, perRow, bg)
  zoom = zoom or 6; perRow = perRow or 8
  local gap, cw, ch = 4, 0, 0
  for _, it in ipairs(items) do local m = it.tile and 3 or 1; cw = math.max(cw, it[1].width * m); ch = math.max(ch, it[1].height * m) end
  local rows = math.ceil(#items / perRow)
  local W, H = perRow * (cw + gap) + gap, rows * (ch + gap) + gap
  local small = Image(W, H, ColorMode.RGB)
  px.fill(small, function(x, y) return px.hex(px.ramp(px.PAL.loam, px.hash(x, y) * 0.5 + px.hash(x // 3, y // 3) * 0.5), bg or px.PAL.wall) end)
  for k, it in ipairs(items) do
    local ox, oy = gap + ((k - 1) % perRow) * (cw + gap), gap + ((k - 1) // perRow) * (ch + gap)
    local m = it.tile and 3 or 1
    for ty = 0, m - 1 do for tx = 0, m - 1 do px.blit(small, it[1], ox + tx * it[1].width, oy + ty * it[1].height) end end
  end
  local big = Image(W * zoom, H * zoom, ColorMode.RGB)
  for y = 0, H - 1 do for x = 0, W - 1 do local c = small:getPixel(x, y); for j = 0, zoom - 1 do for i = 0, zoom - 1 do big:drawPixel(x * zoom + i, y * zoom + j, c) end end end end
  big:saveAs(app.params.root .. '/' .. path)
end

return px
