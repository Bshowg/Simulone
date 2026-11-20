-- Tavern, 3 x 3. Two storeys of timber frame on a stone footing; the upper storey is jettied out over the street on the
-- S (and a little on the other sides), with the joist ends showing under it. A steep tiled roof turns its gable to the S.
-- Over the door an ale-stake (a pole with a bush) sticks out, a painted sign hangs from an iron bracket at the corner,
-- and a bench and a barrel stand outside. The ground-floor windows glow.
return function(ink)
  local M, P, pat = ink.M, ink.P, ink.pat

  local function barrel(c, cx, cy, r, z0, z1)
    c:part(cx - r, cy - r, cx + r, cy + r, z0, z1)
    c:_op(function()
      local b, t = c:pt(cx, cy, z0), c:pt(cx, cy, z1)
      local rx, ry = r * 16 * 1.4142, r * 8 * 1.4142
      local H = z1 - z0
      local wl, ws, wd, ir, lid = ink.hex(P.wood), ink.hex(P.woodShade), ink.hex(P.woodShadeLine), ink.hex(P.iron), ink.hex(P.woodLine)
      for dx = -math.floor(rx), math.floor(rx) do
        local e = math.sqrt(math.max(0, 1 - (dx / rx) ^ 2)) * ry
        local px = math.floor(b[1] + dx)
        local bot = math.floor(b[2] + e)
        for py = math.floor(t[2] - e), bot do
          local col
          if py <= t[2] + e then col = ((dx + 100) % 4 == 0) and lid or wl
          else
            local zz = bot - py
            if zz == 2 or zz == H - 2 or zz == H // 2 then col = ir
            elseif (px % 3) == 0 then col = wd
            else col = dx < -rx * 0.1 and wl or ws end
          end
          c:_put(px, py, col)
        end
      end
    end)
  end

  return {
    name = 'tavern', w = 3, h = 3, height = 63,
    draw = function(c)
      -- ground floor
      local gx0, gy0, gx1, gy1, gz = 0.32, 0.38, 2.68, 2.42, 17
      local g = c:box(gx0, gy0, gx1, gy1, 0, gz, { wall = M.plaster, top = false })
      for _, s in ipairs({ 'N', 'E', 'S', 'W' }) do
        g:rect(s, 0, 1, 0, 4, M.stone)
        local n = 5
        for k = 0, n - 1 do g:line(s, k / (n - 1), 4, k / (n - 1), gz, P.beam) end
        g:line(s, 0, 4, 1, 4, P.beam)
        g:line(s, 0, 4, 0.25, gz - 1, P.beam); g:line(s, 1, 4, 0.75, gz - 1, P.beam)
      end
      g:rect('S', 0, 1, gz - 2, gz, P.plasterShade)             -- shadow under the jetty
      g:door('S', (1.5 - gx0) / (gx1 - gx0), 0.48, 12)
      g:window('S', 0.14, 0.22, 7, 6, { fill = P.glow })
      g:window('S', 0.86, 0.22, 7, 6, { fill = P.glow })
      g:window('E', 0.38, 0.24, 7, 6, { fill = P.glow })
      g:window('E', 0.62, 0.24, 7, 6, { fill = P.glow })
      g:window('W', 0.5, 0.24, 7, 6, { fill = P.glow })
      g:door('N', 0.7, 0.4, 11)
      g:window('N', 0.3, 0.22, 7, 6)

      -- joist ends under the jetty on the S
      local uy1 = 2.72
      c:part(gx0, gy1, gx1, uy1, gz - 2, gz)
      for x = gx0 + 0.08, gx1 - 0.05, 0.16 do c:line3(x, gy1, gz - 1, x, uy1, gz - 1, P.beam) end

      -- the jettied upper storey
      local ux0, uy0, ux1, uz = 0.24, 0.32, 2.8, 33
      local u = c:box(ux0, uy0, ux1, uy1, gz, uz, { wall = M.plaster, top = false })
      for _, s in ipairs({ 'N', 'E', 'S', 'W' }) do
        local n = 9
        for k = 0, n - 1 do u:line(s, k / (n - 1), 0, k / (n - 1), uz - gz, P.beam) end
        u:line(s, 0, 0, 1, 0, P.dark); u:line(s, 0, 1, 1, 1, P.beam); u:line(s, 0, 8, 1, 8, P.beam); u:line(s, 0, uz - gz - 1, 1, uz - gz - 1, P.beam)
      end
      u:window('S', 0.25, 0.22, 7, 6, { shutters = true })
      u:window('S', 0.75, 0.22, 7, 6, { shutters = true })
      u:window('E', 0.3, 0.22, 7, 6, { fill = P.glow })
      u:window('E', 0.7, 0.22, 7, 6)
      u:window('W', 0.35, 0.22, 7, 6); u:window('W', 0.7, 0.22, 7, 6, { fill = P.glow })
      u:window('N', 0.5, 0.22, 7, 6)

      -- steep tiled roof, gable to the street
      local r = c:gable(0.14, 0.22, 2.9, 2.84, uz - 2, 18, 'y', { roof = M.tile, gable = M.plaster })
      for _, s in ipairs({ 'N', 'S' }) do
        r:line(s, 0.5, 0, 0.5, 17, P.beam); r:line(s, 0.12, 2, 0.88, 2, P.beam)
        r:line(s, 0.3, 2, 0.5, 10, P.beam); r:line(s, 0.7, 2, 0.5, 10, P.beam)
        r:rect(s, 0.43, 0.57, 4, 8, P.dark)
      end
      c:smoke(1.52, 0.75, uz - 2 + 18, 12)                       -- from the hearth, out through the ridge

      -- ale-stake over the door: a pole out from the jetty with a bush at its end
      c:part(1.42, uy1, 1.58, 2.99, 18, 29)
      c:line3(1.5, uy1, 24, 1.5, 2.92, 22, P.wood); c:line3(1.5, uy1, 25, 1.5, 2.92, 23, P.wood)
      c:dot3(1.5, 2.92, 22, 4, P.leafShade)
      c:dot3(1.49, 2.91, 23, 2, P.leaf)

      -- sign on an iron bracket at the SE corner
      local sx = 2.56
      c:part(sx - 0.03, uy1, sx + 0.03, 2.99, 13, 28)
      c:line3(sx, uy1, 26, sx, 2.97, 26, P.iron); c:line3(sx, uy1, 21, sx, 2.82, 26, P.iron)
      c:line3(sx, 2.78, 25, sx, 2.78, 22, P.iron); c:line3(sx, 2.94, 25, sx, 2.94, 22, P.iron)
      c:poly3({ { sx, 2.75, 22 }, { sx, 2.97, 22 }, { sx, 2.97, 13 }, { sx, 2.75, 13 } }, ink.plain(P.weld, P.russet), c:visible('E') or c:visible('W'))
      c:dot3(sx, 2.86, 17, 2, P.madder)

      -- bench and barrel outside
      c:part(0.55, 2.68, 1.1, 2.84, 0, 4)
      for _, p in ipairs({ { 0.6, 2.71 }, { 1.04, 2.71 }, { 0.6, 2.8 }, { 1.04, 2.8 } }) do c:post(p[1], p[2], 0, 4, P.wood, 1) end
      c:box(0.53, 2.68, 1.12, 2.84, 4, 5, { wall = M.planks })
      barrel(c, 2.12, 2.8, 0.14, 0, 10)
      barrel(c, 2.36, 2.86, 0.1, 0, 7)
    end,
  }
end
