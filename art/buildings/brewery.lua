-- Brewery, 3 x 2. A sturdy house on a rubble-stone footing, timber-framed above, under a steep shingle roof with a
-- louvred vent on the ridge to let the steam out. Against its E end an open lean-to on posts shelters the brewing copper
-- on its stone hearth and a wooden mash tun; big barrels stand stacked by the W end of the S front.
return function(ink)
  local M, P, pat = ink.M, ink.P, ink.pat
  local copper = ink.plain(P.tile, P.tileShade)

  -- a barrel standing at (cx, cy) from z0 to z1: staves, iron hoops, a round lid
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
    name = 'brewery', w = 3, h = 2, height = 50,
    draw = function(c)
      local x0, y0, x1, y1, wz, fz = 0.12, 0.15, 2.0, 1.6, 21, 7
      local h = c:box(x0, y0, x1, y1, 0, wz, { wall = M.plaster, top = false })
      for _, s in ipairs({ 'N', 'E', 'S', 'W' }) do
        h:rect(s, 0, 1, 0, fz, M.stone)
        local n = (s == 'N' or s == 'S') and 5 or 3
        for k = 0, n - 1 do h:line(s, k / (n - 1), fz, k / (n - 1), wz, P.beam) end
        h:line(s, 0, fz, 1, fz, P.beam); h:line(s, 0, wz - 1, 1, wz - 1, P.beam); h:line(s, 0, 14, 1, 14, P.beam)
        local b = 1 / (n - 1)
        h:line(s, 0, fz, b, 14, P.beam); h:line(s, 1, fz, 1 - b, 14, P.beam)
      end
      local du = (1.5 - x0) / (x1 - x0)                        -- the entry cell is x = 1..2 on the S side
      h:door('S', du, 0.48, 14, { arch = true })
      h:window('S', 0.22, 0.2, 13, 4)
      h:window('N', 0.4, 0.2, 13, 4); h:window('N', 0.75, 0.2, 13, 4)
      h:window('W', 0.5, 0.25, 13, 4, { shutters = true })
      h:window('E', 0.5, 0.2, 15, 4)

      local g = c:gable(x0 - 0.08, y0 - 0.1, x1 + 0.08, y1 + 0.1, wz - 2, 16, 'x', { roof = M.shingle, gable = M.plaster })
      for _, s in ipairs({ 'E', 'W' }) do g:line(s, 0.5, 0, 0.5, 15, P.beam); g:line(s, 0.25, 0, 0.5, 8, P.beam); g:line(s, 0.75, 0, 0.5, 8, P.beam) end

      -- the louvred vent on the ridge
      local ym, rz = (y0 - 0.1 + y1 + 0.1) / 2, wz - 2 + 16
      local v = c:box(0.85, ym - 0.13, 1.2, ym + 0.13, rz - 2, rz + 8, { wall = M.planks, top = false })
      for _, s in ipairs({ 'N', 'E', 'S', 'W' }) do for z = 3, 9, 2 do v:line(s, 0.12, z, 0.88, z, P.dark) end end
      c:gable(0.8, ym - 0.2, 1.25, ym + 0.2, rz + 8, 5, 'x', { roof = M.shingle, gable = M.planks })

      -- lean-to on posts at the E end over the copper on its hearth; the mash tun stands beside it in the open
      local lx0, lx1, ly0, ly1, zl, zh = 2.04, 2.94, 0.18, 1.02, 12, 17
      c:cyl(2.55, 0.6, 0.25, 0, 3, M.stone)                     -- hearth
      c:cyl(2.55, 0.6, 0.2, 3, 10, copper, P.dark)              -- copper
      c:dot3(2.55, 0.6 + 0.26, 1, 1, P.glow)                    -- the fire under it
      barrel(c, 2.5, 1.35, 0.23, 0, 9)                          -- mash tun
      c:part(2.32, 1.3, 2.7, 1.34, 9, 12)                       -- a paddle across it
      c:line3(2.32, 1.32, 10, 2.7, 1.32, 11, P.wood)
      for _, p in ipairs({ { 2.89, ly0 + 0.04 }, { 2.89, ly1 - 0.05 } }) do
        c:part(p[1] - 0.03, p[2] - 0.03, p[1] + 0.03, p[2] + 0.03, 0, zl - 2)
        c:post(p[1], p[2], 0, zl - 2, P.wood, 2)
      end
      c:shed(lx0, ly0, lx1, ly1, zl, zh, 'W', { roof = M.shingle, wall = M.planks })
      c:smoke(2.5, 0.6, zh - 1, 14)

      -- barrels stacked by the W end of the front
      barrel(c, 0.3, 1.86, 0.14, 0, 11)
      barrel(c, 0.62, 1.86, 0.14, 0, 11)
      barrel(c, 0.46, 1.86, 0.14, 11, 21)
      barrel(c, 0.95, 1.88, 0.11, 0, 8)
    end,
  }
end
