-- Great church, 5 x 6. The largest building in the game: a tall ashlar nave along y with lean-to aisles on both sides,
-- buttresses between the bays, pointed glazed windows (a clerestory above the aisle roofs), a chancel at the N (east)
-- end with a great east window and a cross, and a square west tower at the S end holding the great arched door (the
-- entry), with belfry openings and a short pyramid spire. Slate roofs, lead on the spire.
return function(ink)
  local M, P = ink.M, ink.P
  local LEAD = { lit = function(s) return ink.pat.boards(P.lead, P.slateLine, s, 4) end, shade = function(s) return ink.pat.boards(P.slateShade, P.slateShadeLine, s, 4) end, top = function() return ink.pat.flat(P.lead) end, under = P.slateShadeLine }

  -- a pointed (gothic) opening on a wall: centre u, half-width hw (in u), from za up to the springing zs, then `rise`
  local function pointed(h, side, u, hw, za, zs, rise, fill)
    h:draw(side, function(f, ss, c)
      local pts = { f(u - hw, za), f(u + hw, za) }
      for k = 0, 6 do local d = 1 - k / 6; pts[#pts + 1] = f(u + hw * d, zs + rise * math.sqrt(1 - d)) end
      for k = 1, 6 do local d = k / 6; pts[#pts + 1] = f(u - hw * d, zs + rise * math.sqrt(1 - d)) end
      local fl = type(fill) == 'string' and ink.pat.flat(fill) or (ss == 'R' and fill.shade(-0.5) or fill.lit(0.5))
      c:_poly(pts, fl)
    end)
  end
  local function glassWin(h, side, u, hw, za, zs, rise)
    pointed(h, side, u, hw * 1.35, za - 1, zs, rise + 1.5, P.stoneShadeLine)
    pointed(h, side, u, hw, za, zs, rise, P.glass)
    h:line(side, u, za, u, zs + rise - 1, P.ink2)
  end
  local function buttress(c, x0, y0, x1, y1, z1)
    c:box(x0, y0, x1, y1, 0, z1, { wall = M.ashlar })
  end

  return {
    name = 'great_church', w = 5, h = 6, height = 106,
    draw = function(c)
      -- chancel (east end, N)
      local ch = c:box(1.9, 0.18, 3.1, 0.95, 0, 33, { wall = M.ashlar, top = false })
      glassWin(ch, 'N', 0.5, 0.16, 8, 20, 9)
      ch:line('N', 0.4, 8, 0.4, 26, P.ink2); ch:line('N', 0.6, 8, 0.6, 26, P.ink2)
      for _, s in ipairs({ 'E', 'W' }) do glassWin(ch, s, 0.5, 0.13, 9, 18, 6) end
      for _, x in ipairs({ 1.82, 3.03 }) do buttress(c, x, 0.12, x + 0.15, 0.27, 24) end
      c:gable(1.82, 0.18, 3.18, 0.95, 33, 18, 'y', { roof = M.slate, gable = M.ashlar })
      c:part(2.42, 0.16, 2.58, 0.2, 50, 60)
      c:post(2.5, 0.18, 50, 60, P.stoneShade, 2)
      c:line3(2.42, 0.18, 57, 2.58, 0.18, 57, P.stoneShade); c:line3(2.42, 0.18, 56, 2.58, 0.18, 56, P.stoneShadeLine)

      -- aisles: low walls and lean-to roofs against the nave
      local NY0, NY1 = 0.95, 4.3
      for _, a in ipairs({ { 0.45, 1.75, 'E', 'W' }, { 3.25, 4.55, 'W', 'E' } }) do
        local ax0, ax1, high, out = a[1], a[2], a[3], a[4]
        local ais = c:box(ax0, NY0 + 0.1, ax1, NY1, 0, 19, { wall = M.ashlar, top = false })
        for k = 0, 3 do glassWin(ais, out, (k + 0.5) / 4, 0.045, 5, 12, 5) end
        glassWin(ais, 'S', 0.5, 0.12, 5, 12, 5)
        glassWin(ais, 'N', 0.5, 0.12, 5, 12, 5)
        -- buttresses between the bays
        local bx0 = out == 'W' and ax0 - 0.14 or ax1
        for k = 0, 4 do
          local y = NY0 + 0.1 + (NY1 - NY0 - 0.1) * k / 4
          local yy0, yy1 = math.max(NY0 + 0.1, y - 0.07), math.min(NY1, y + 0.07)
          if k == 0 then yy0, yy1 = NY0 + 0.1, NY0 + 0.24 end
          if k == 4 then yy0, yy1 = NY1 - 0.14, NY1 end
          buttress(c, bx0, yy0, bx0 + 0.14, yy1, 16)
        end
        local rx0, rx1 = ax0, ax1
        if out == 'W' then rx0 = ax0 - 0.1 else rx1 = ax1 + 0.1 end
        c:shed(rx0, NY0 + 0.05, rx1, NY1, 19, 30, high, { roof = M.slate, wall = M.ashlar })
      end

      -- the nave, with a clerestory above the aisle roofs
      local nave = c:box(1.75, NY0, 3.25, NY1, 0, 42, { wall = M.ashlar, top = false })
      for _, s in ipairs({ 'E', 'W' }) do
        for k = 0, 3 do glassWin(nave, s, (k + 0.5) / 4, 0.04, 31, 36, 4) end
      end
      c:gable(1.65, NY0, 3.35, NY1, 42, 22, 'y', { roof = M.slate, gable = M.ashlar })

      -- the west tower
      local TX0, TX1, TY0, TY1 = 1.68, 3.32, 4.3, 5.86
      local tw = c:box(TX0, TY0, TX1, TY1, 0, 74, { wall = M.ashlar, top = false })
      for _, s in ipairs({ 'N', 'S', 'E', 'W' }) do
        tw:rect(s, 0, 1, 46, 47, s == 'E' and P.stoneShadeLine or P.stoneLine)     -- string course under the belfry
        tw:rect(s, 0, 1, 72, 74, s == 'E' and P.stoneShadeLine or P.stoneLine)
        pointed(tw, s, 0.33, 0.07, 52, 62, 6, P.dark)                            -- paired belfry openings
        pointed(tw, s, 0.67, 0.07, 52, 62, 6, P.dark)
        for z = 54, 62, 3 do tw:line(s, 0.27, z, 0.39, z, P.wood); tw:line(s, 0.61, z, 0.73, z, P.wood) end
        if s ~= 'S' then glassWin(tw, s, 0.5, 0.06, 26, 33, 4) end
      end
      -- the great west door: a deep pointed arch, ringed in shadow, with a window above
      pointed(tw, 'S', 0.5, 0.25, 0, 14, 10, P.stoneShadeLine)
      pointed(tw, 'S', 0.5, 0.21, 0, 13, 9, P.ink)
      pointed(tw, 'S', 0.5, 0.18, 0, 12, 8, M.planks)
      tw:line('S', 0.5, 0, 0.5, 19, P.woodShadeLine)
      glassWin(tw, 'S', 0.5, 0.11, 28, 38, 7)
      tw:line('S', 0.5, 28, 0.5, 44, P.ink2)
      -- corner buttresses of the tower
      for _, b in ipairs({ { TX0 - 0.14, TY1 - 0.3, TX0, TY1 }, { TX1, TY1 - 0.3, TX1 + 0.14, TY1 }, { TX0 - 0.14, TY0, TX0, TY0 + 0.3 }, { TX1, TY0, TX1 + 0.14, TY0 + 0.3 } }) do
        buttress(c, b[1], b[2], b[3], b[4], 40)
      end
      for _, b in ipairs({ { TX0, TY1, TX0 + 0.3, TY1 + 0.12 }, { TX1 - 0.3, TY1, TX1, TY1 + 0.12 } }) do
        buttress(c, b[1], b[2], b[3], b[4], 40)
      end
      -- a short lead pyramid spire with a cross
      c:hip(TX0 - 0.08, TY0 - 0.06, TX1 + 0.08, TY1 + 0.06, 74, 24, 'x', { roof = LEAD }, (TY1 - TY0 + 0.12) / 2)
      c:part(2.46, 5.06, 2.54, 5.1, 96, 104)
      c:post(2.5, 5.08, 96, 104, P.iron, 1)
      c:line3(2.44, 5.08, 101, 2.56, 5.08, 101, P.iron)
    end,
  }
end
