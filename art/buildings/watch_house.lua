-- Watch house, 2 x 2. A small square stone tower of two storeys; on top an overhanging timber lookout gallery under a
-- pyramid shingle roof. The town watch puts out fires, so a water barrel, buckets and a long fire-hook stand by the
-- narrow door in the S wall (the entry), and a lantern hangs beside it.
return function(ink)
  local M, P = ink.M, ink.P
  local x0, y0, x1, y1 = 0.62, 0.22, 1.82, 1.32            -- the tower
  -- a barrel: a drum of staves with water in it and two iron hoops (drawn in screen space, so it looks the same turned)
  local function barrel(c, cx, cy, r, h)
    c:cyl(cx, cy, r, 0, h, M.planks, P.water2)
    c:_op(function()
      local b = c:pt(cx, cy, 0)
      local rx, ry = r * ink.HW * 1.4142, r * ink.HH * 1.4142
      for _, z in ipairs({ 2, h - 3 }) do
        for dx = -math.floor(rx), math.floor(rx) do
          local e = math.sqrt(math.max(0, 1 - (dx / rx) ^ 2)) * ry
          c:_put(b[1] + dx, b[2] - z + e, ink.hex(P.iron))
        end
      end
    end)
  end
  return {
    name = 'watch_house', w = 2, h = 2, height = 80,
    draw = function(c)
      local t = c:box(x0, y0, x1, y1, 0, 40, { wall = M.stone, top = false })
      t:door('S', (1.5 - x0) / (x1 - x0), 0.34, 12, { arch = true })
      for _, s in ipairs({ 'N', 'S', 'E', 'W' }) do
        t:rect(s, 0, 1, 20, 21, s == 'E' and P.stoneShadeLine or P.stoneLine)   -- a string course between the storeys
        t:window(s, s == 'S' and 0.3 or 0.5, 0.1, 25, 7, { arch = true })      -- slits in the upper storey
      end
      t:window('W', 0.5, 0.1, 8, 6)
      t:window('N', 0.5, 0.1, 8, 6)
      t:window('E', 0.35, 0.1, 8, 6)

      -- the lookout gallery: a boarded parapet on beam ends, posts, and the room behind them
      local gx0, gy0, gx1, gy1 = 0.46, 0.06, 1.98, 1.48
      c:box(x0 - 0.02, y0 - 0.02, x1 + 0.02, y1 + 0.02, 38, 40, { wall = P.beam, top = false })
      local par = c:box(gx0, gy0, gx1, gy1, 40, 46, { wall = M.planks, top = P.dark })
      for _, s in ipairs({ 'N', 'S', 'E', 'W' }) do par:line(s, 0, 1, 1, 1, P.woodShadeLine) end
      local room = c:box(x0 + 0.05, y0 + 0.05, x1 - 0.05, y1 - 0.05, 46, 59, { wall = P.dark, top = false })
      for _, s in ipairs({ 'N', 'S', 'E', 'W' }) do room:rect(s, 0.15, 0.85, 1, 12, P.ink2) end
      for _, p in ipairs({ { gx0 + 0.04, gy0 + 0.04 }, { gx1 - 0.06, gy0 + 0.04 }, { gx0 + 0.04, gy1 - 0.06 }, { gx1 - 0.06, gy1 - 0.06 } }) do
        c:part(p[1] - 0.02, p[2] - 0.02, p[1] + 0.03, p[2] + 0.03, 46, 59)
        c:post(p[1], p[2], 46, 59, P.wood, 2)
      end
      c:hip(gx0 - 0.04, gy0 - 0.04, gx1 + 0.0, gy1 + 0.06, 58, 17, 'x', { roof = M.shingle }, 0.8)
      -- a little iron finial
      c:part(1.2, 0.77, 1.24, 0.81, 75, 78)
      c:post(1.22, 0.79, 75, 78, P.iron, 1)

      -- a lantern on an iron bracket on the E wall
      c:part(1.83, 0.66, 1.93, 0.92, 12, 23)
      c:line3(1.83, 0.79, 22, 1.91, 0.79, 22, P.iron)
      c:poly3({ { 1.91, 0.67, 12 }, { 1.91, 0.91, 12 }, { 1.91, 0.91, 18 }, { 1.91, 0.79, 21 }, { 1.91, 0.67, 18 } }, P.glow)
      c:line3(1.91, 0.79, 12, 1.91, 0.79, 18, P.iron)

      -- the fire-hook leaning on the S wall
      c:part(0.76, 1.34, 1.32, 1.47, 0, 36)
      c:line3(0.78, 1.45, 0, 1.22, 1.36, 32, P.wood)
      c:line3(0.79, 1.45, 0, 1.23, 1.36, 32, P.woodShade)
      c:line3(1.22, 1.36, 32, 1.24, 1.36, 36, P.iron)
      c:line3(1.24, 1.36, 35, 1.3, 1.36, 31, P.iron)

      -- the water barrel and two leather buckets
      barrel(c, 0.33, 1.64, 0.21, 9)
      c:cyl(0.66, 1.84, 0.09, 0, 4, ink.plain(P.russet, P.woodShade), P.dark)
      c:cyl(0.9, 1.86, 0.09, 0, 4, ink.plain(P.russet, P.woodShade), P.dark)
    end,
  }
end
