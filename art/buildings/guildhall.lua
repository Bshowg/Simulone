-- Guildhall, 4 x 3. The richest secular building in town: an ashlar ground floor opening on the S (entrance) side in an
-- arcade of round arches, a broad flight of steps up to the door in the middle bay, a jettied timber-framed upper storey
-- with glazed windows and the guilds' banners, a tall tiled roof with a little timber turret (a louvre with a bell) on
-- the ridge.
return function(ink)
  local M, P = ink.M, ink.P
  local X0, X1, Y0, Y1 = 0.15, 3.85, 0.38, 2.5          -- ground floor
  local function u(x) return (x - X0) / (X1 - X0) end
  return {
    name = 'guildhall', w = 4, h = 3, height = 88,
    draw = function(c)
      -- ground floor of squared stone on a plinth
      local g = c:box(X0, Y0, X1, Y1, 0, 19, { wall = M.ashlar, top = false })
      for _, s in ipairs({ 'N', 'S', 'E', 'W' }) do g:rect(s, 0, 1, 0, 3, s == 'E' and P.stoneShadeLine or P.stoneShade) end
      -- the arcade: five round arches, dark inside; the middle one (x = 2.5) holds the door
      for _, x in ipairs({ 0.55, 1.5, 2.5, 3.45 }) do
        local hw = 0.3 / (X1 - X0)
        g:arch('S', u(x), hw + 0.012, 3, 12, 5, P.stoneShadeLine)
        g:arch('S', u(x), hw, 3, 12, 4, P.dark)
      end
      g:arch('S', u(2.5), 0.2 / (X1 - X0), 3, 12, 3, M.planks)
      g:line('S', u(2.5), 3, u(2.5), 15, P.woodShadeLine)
      -- small barred windows on the other sides of the ground floor
      for _, s in ipairs({ 'N', 'E', 'W' }) do
        local n = (s == 'N') and 4 or 2
        for k = 1, n do g:window(s, (k - 0.5) / n, 0.18, 8, 6, { arch = true }) end
      end

      -- broad steps up to the door
      c:box(1.9, Y1, 3.1, 2.95, 0, 2, { wall = M.ashlar })
      c:box(2.02, Y1, 2.98, 2.74, 2, 4, { wall = M.ashlar })

      -- jetty beam and the timber-framed upper storey
      c:box(X0 - 0.04, Y0 - 0.06, X1 + 0.04, Y1 + 0.06, 19, 21, { wall = P.beam, top = false })
      local up = c:box(X0 - 0.06, Y0 - 0.1, X1 + 0.06, Y1 + 0.1, 21, 39, { wall = M.plaster, top = false })
      local banners = { P.madder, P.woad, P.weld, P.green }
      for _, s in ipairs({ 'N', 'S', 'E', 'W' }) do
        local long = (s == 'N' or s == 'S')
        local posts = long and 9 or 5
        up:frame(s, 18, posts, true)
        if long then
          for k = 0, 3 do                                            -- glazed two-light windows in alternate bays
            local uc = (2 * k + 1.5) / 8
            if k == 3 then uc = 6.5 / 8 end
            up:window(s, (2 * k + 1) / 8, 0.32, 3, 9, { fill = P.glass, bars = true })
          end
          if s == 'S' then                                           -- the guilds' banners between the windows
            for k = 0, 3 do
              local uc = (2 * k + 2) / 8
              if k < 3 then
                up:rect(s, uc - 0.035, uc + 0.035, 1, 15, banners[k + 1])
                up:line(s, uc - 0.035, 1, uc - 0.035, 15, P.ink2); up:line(s, uc + 0.035, 1, uc + 0.035, 15, P.ink2)
                up:draw(s, function(f, ss, cc) local a, b = f(uc - 0.035, 1), f(uc + 0.035, 1); local m = f(uc, 4); cc:_line(a, m, ink.hex(P.ink2)); cc:_line(m, b, ink.hex(P.ink2))
                  local m2 = f(uc, 3); cc:_line({ a[1], a[2] - 1 }, { m2[1], m2[2] }, ink.hex(P.plaster)); cc:_line({ m2[1], m2[2] }, { b[1], b[2] - 1 }, ink.hex(P.plaster))
                  local q = f(uc, 10); cc:_put(q[1], q[2], ink.hex(P.paper)) end)
                up:line(s, uc - 0.05, 16, uc + 0.05, 16, P.beam)
              end
            end
          end
        else
          up:window(s, 0.5, 0.42, 3, 9, { fill = P.glass, bars = true })
        end
      end

      -- the tall tiled roof, its gable ends framed too
      local r = c:gable(X0 - 0.06, Y0 - 0.2, X1 + 0.06, Y1 + 0.2, 39, 29, 'x', { roof = M.tile, gable = M.plaster })
      for _, s in ipairs({ 'W', 'E' }) do
        r:line(s, 0.5, 0, 0.5, 30, P.beam)
        r:line(s, 0.12, 0, 0.12, 7, P.beam); r:line(s, 0.88, 0, 0.88, 7, P.beam)
        r:line(s, 0.15, 10, 0.85, 10, P.beam)
        r:window(s, 0.5, 0.35, 13, 7, { fill = P.glass, bars = true, arch = true })
      end

      -- a little timber turret (a louvre with the guild bell) on the ridge
      local tx0, tx1, ty0, ty1 = 1.72, 2.28, 1.24, 1.68
      local t = c:box(tx0, ty0, tx1, ty1, 62, 74, { wall = M.planks, top = false })
      for _, s in ipairs({ 'N', 'S', 'E', 'W' }) do t:arch(s, 0.5, 0.22, 3, 8, 2, P.dark) end
      c:hip(tx0 - 0.08, ty0 - 0.08, tx1 + 0.08, ty1 + 0.08, 74, 10, 'x', { roof = M.slate }, 0.32)
      c:part(1.98, 1.44, 2.02, 1.48, 84, 86)
      c:post(2.0, 1.46, 84, 86, P.iron, 1)
    end,
  }
end
