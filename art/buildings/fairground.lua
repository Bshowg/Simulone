-- Fairground, 6 x 6. The open place where the yearly fair is held; the game draws the crowd on it, so most of the
-- ground is left empty. A tall maypole with ribbons near the middle; round tents and booths with pastel cloth round the
-- edges; a little plank stage with a hanging cloth; lines of pennants on poles. No door: people walk in anywhere.
return function(ink)
  local M, P, pat = ink.M, ink.P, ink.pat
  -- cloths: a lit and a shaded wash from the palette
  local function cloth(lit, shade) return ink.plain(lit, shade) end
  local MADDER, WOAD, WELD, GREEN, LINEN = cloth(P.madder, P.tileShade), cloth(P.woad, P.slateShade), cloth(P.weld, P.thatchShade), cloth(P.green, P.leafShade), cloth(P.linen, P.wattleShade)
  -- a tent cloth sewn of panels of two colours (seen as upright bands)
  local function panels(a, b, ash, bsh)
    local function f(x, y) return function(px) return (px // 3) % 2 == 0 and ink.hex(x) or ink.hex(y) end end
    return { lit = function() return f(a, b) end, shade = function() return f(ash, bsh) end, top = function() return pat.flat(a) end, under = P.woodShadeLine }
  end

  -- a pennon flying from a pole top at (x, y, z)
  local function pennon(c, x, y, z, col)
    c:part(x - 0.02, y - 0.02, x + 0.03, y + 0.03, z, z + 9)
    c:post(x, y, z, z + 9, P.wood, 1)
    c:part(x + 0.03, y - 0.01, x + 0.25, y + 0.01, z + 5, z + 9)
    c:poly3({ { x + 0.03, y, z + 9 }, { x + 0.24, y, z + 7 }, { x + 0.03, y, z + 5 } }, col)
  end
  -- a round tent: drum of cloth, a conical roof, a door flap facing `side`
  local function tent(c, cx, cy, r, wallH, rise, wallM, roofM, flag)
    c:cyl(cx, cy, r, 0, wallH, wallM)
    c:cone(cx, cy, r + 0.08, wallH - 1, rise, roofM)
    pennon(c, cx, cy, wallH - 1 + rise - 1, flag)
  end
  -- a booth: a counter, two front posts and a cloth awning sloping down to the front (`front` side)
  local function booth(c, x0, y0, x1, y1, front, awning, goods)
    local fx0, fy0, fx1, fy1 = x0, y0, x1, y1                 -- counter along the front edge
    if front == 'S' then fy0 = y1 - 0.25 elseif front == 'N' then fy1 = y0 + 0.25 elseif front == 'E' then fx0 = x1 - 0.25 else fx1 = x0 + 0.25 end
    local back = { S = 'N', N = 'S', E = 'W', W = 'E' }
    -- the back wall of cloth
    local bx0, by0, bx1, by1 = x0, y0, x1, y1
    if front == 'S' then by1 = y0 + 0.08 elseif front == 'N' then by0 = y1 - 0.08 elseif front == 'E' then bx1 = x0 + 0.08 else bx0 = x1 - 0.08 end
    c:box(bx0, by0, bx1, by1, 0, 18, { wall = awning })
    local counter = c:box(fx0, fy0, fx1, fy1, 0, 7, { wall = M.planks, top = M.planks })
    if goods then goods(fx0, fy0, fx1, fy1) end
    -- front posts
    local p1, p2
    if front == 'S' then p1, p2 = { x0 + 0.04, y1 - 0.05 }, { x1 - 0.07, y1 - 0.05 }
    elseif front == 'N' then p1, p2 = { x0 + 0.04, y0 + 0.03 }, { x1 - 0.07, y0 + 0.03 }
    elseif front == 'E' then p1, p2 = { x1 - 0.05, y0 + 0.04 }, { x1 - 0.05, y1 - 0.07 }
    else p1, p2 = { x0 + 0.03, y0 + 0.04 }, { x0 + 0.03, y1 - 0.07 } end
    for _, p in ipairs({ p1, p2 }) do c:part(p[1] - 0.02, p[2] - 0.02, p[1] + 0.03, p[2] + 0.03, 7, 14); c:post(p[1], p[2], 7, 14, P.wood, 2) end
    c:shed(x0 - 0.04, y0 - 0.04, x1 + 0.04, y1 + 0.04, 14, 19, back[front], { roof = awning, wall = awning })
  end

  return {
    name = 'fairground', w = 6, h = 6, height = 86,
    draw = function(c)
      -- NW: a big round pavilion, madder and linen panels
      tent(c, 1.0, 1.0, 0.62, 13, 18, panels(P.linen, P.madder, P.wattleShade, P.tileShade), MADDER, P.weld)

      -- NE: the little stage, a cloth hung behind it on two poles
      local st = c:box(3.9, 0.55, 5.6, 1.55, 0, 7, { wall = M.planks, top = pat.planks(P.wood, P.woodLine, 4) })
      st:rect('S', 0, 1, 6, 7, P.woodShadeLine)
      st:rect('W', 0, 1, 6, 7, P.woodShadeLine)
      c:box(4.05, 1.55, 4.45, 1.85, 0, 2, { wall = M.planks })   -- a step
      c:part(3.9, 0.3, 3.96, 0.38, 0, 30); c:post(3.92, 0.34, 0, 30, P.wood, 2)
      c:part(5.56, 0.3, 5.62, 0.38, 0, 30); c:post(5.58, 0.34, 0, 30, P.wood, 2)
      local back = c:box(3.96, 0.32, 5.56, 0.37, 9, 28, { wall = WOAD, top = false })
      for k = 1, 4 do back:line('S', k / 5, 0, k / 5, 19, P.slateLine); back:line('N', k / 5, 0, k / 5, 19, P.slateLine) end
      pennon(c, 3.92, 0.34, 30, P.madder)
      pennon(c, 5.58, 0.34, 30, P.weld)

      -- W edge: a booth of cloth and boards with pots on the counter
      booth(c, 0.25, 2.5, 0.95, 3.6, 'E', WELD, function(x0, y0, x1, y1)
        for k = 0, 2 do local yy = y0 + 0.2 + k * 0.33; c:cyl((x0 + x1) / 2, yy, 0.07, 7, 11, cloth(P.tile, P.tileShade), P.dark) end
      end)
      -- SW: a booth facing the middle, green awning, cloth bolts on the counter
      booth(c, 0.35, 4.85, 1.75, 5.65, 'N', GREEN, function(x0, y0, x1, y1)
        local cols = { P.woad, P.madder, P.linen }
        for k = 0, 2 do local xx = x0 + 0.2 + k * 0.45; c:box(xx, y0 + 0.06, xx + 0.28, y1 - 0.06, 7, 10, { wall = cloth(cols[k + 1], P.wattleShade) }) end
      end)
      -- E edge: a booth with an awning of woad
      booth(c, 5.05, 3.0, 5.75, 4.3, 'W', WOAD, function(x0, y0, x1, y1)
        for k = 0, 1 do c:cyl((x0 + x1) / 2, y0 + 0.3 + k * 0.6, 0.11, 7, 13, M.planks, P.wood) end
      end)
      -- SE: a small round tent of linen with a woad roof
      tent(c, 5.0, 5.05, 0.5, 11, 14, LINEN, WOAD, P.madder)

      -- lines of pennants on poles: along the N side, and down the W side by the S corner
      local function pennants(xa, ya, xb, yb, z, n)
        c:part(xa - 0.03, ya - 0.03, xa + 0.03, ya + 0.03, 0, z + 2); c:post(xa, ya, 0, z + 2, P.wood, 2)
        c:part(xb - 0.03, yb - 0.03, xb + 0.03, yb + 0.03, 0, z + 2); c:post(xb, yb, 0, z + 2, P.wood, 2)
        c:part(math.min(xa, xb) + 0.04, math.min(ya, yb) - 0.01, math.max(xa, xb) - 0.04, math.max(ya, yb) + 0.01, z - 9, z)
        local cols = { P.madder, P.weld, P.woad, P.green, P.linen }
        local prev
        for k = 0, n do
          local t = k / n
          local sag = 4 * t * (1 - t) * 4
          local x, y, zz = xa + (xb - xa) * t, ya + (yb - ya) * t, z - sag
          if prev then c:line3(prev[1], prev[2], prev[3], x, y, zz, P.ink2) end
          prev = { x, y, zz }
        end
        for k = 1, n - 1 do
          local t, t2 = (k - 0.35) / n, (k + 0.35) / n
          local s1, s2, tm = 16 * t * (1 - t), 16 * t2 * (1 - t2), 16 * (k / n) * (1 - k / n)
          c:poly3({ { xa + (xb - xa) * t, ya + (yb - ya) * t, z - s1 }, { xa + (xb - xa) * t2, ya + (yb - ya) * t2, z - s2 },
                    { xa + (xb - xa) * k / n, ya + (yb - ya) * k / n, z - tm - 5 } }, cols[k % #cols + 1])
        end
      end
      pennants(1.85, 0.3, 3.75, 0.3, 26, 7)
      pennants(0.2, 3.85, 0.2, 4.7, 22, 4)
      pennants(5.8, 1.9, 5.8, 2.85, 22, 4)

      -- the maypole in the middle, with a garland and ribbons pegged out round it
      local MX, MY, TOP = 2.95, 2.95, 72
      local ribbons = { P.madder, P.woad, P.weld, P.green, P.madder, P.woad, P.weld, P.green }
      local R = 0.62
      local function ribbon(k)
        local a = (k + 0.5) / #ribbons * 2 * math.pi
        local ex, ey = MX + R * math.cos(a), MY + R * math.sin(a)
        local bx0, bx1, by0, by1 = math.min(MX, ex), math.max(MX, ex), math.min(MY, ey), math.max(MY, ey)
        -- keep the ribbon's box clear of the pole on its main axis, so it sorts in front of or behind it
        if math.abs(ex - MX) > math.abs(ey - MY) then if ex > MX then bx0 = MX + 0.04 else bx1 = MX - 0.04 end
        else if ey > MY then by0 = MY + 0.04 else by1 = MY - 0.04 end end
        c:part(bx0, by0, bx1, by1, 0, TOP - 6, { plain = true })
        c:line3(MX, MY, TOP - 7, ex, ey, 0, ribbons[k + 1])
        c:line3(MX, MY, TOP - 8, ex, ey, 1, ribbons[k + 1])
        c:dot3(ex, ey, 0, 1, P.wood)
      end
      for k = 0, #ribbons - 1 do local a = (k + 0.5) / #ribbons * 2 * math.pi; if math.cos(a) + math.sin(a) < 0 then ribbon(k) end end
      c:part(MX - 0.03, MY - 0.03, MX + 0.03, MY + 0.03, 0, TOP + 1)
      c:post(MX, MY, 0, TOP, P.wood, 2)
      c:line3(MX, MY, TOP - 2, MX, MY, TOP - 2, P.woodShade)
      for k = 0, #ribbons - 1 do local a = (k + 0.5) / #ribbons * 2 * math.pi; if math.cos(a) + math.sin(a) >= 0 then ribbon(k) end end
      -- the garland: a ring of leaves round the pole near the top
      c:part(MX - 0.16, MY - 0.16, MX + 0.16, MY + 0.16, TOP - 9, TOP - 5)
      c:_op(function()
        local p = c:pt(MX, MY, TOP - 7)
        for dx = -4, 4 do
          for dy = -2, 2 do
            local d = (dx / 4) ^ 2 + (dy / 2) ^ 2
            if d <= 1.05 and d >= 0.3 then c:_put(p[1] + dx, p[2] + dy, ink.hex(((dx + dy) % 3 == 0) and P.madder or P.leaf)) end
          end
        end
      end)
      pennon(c, MX, MY, TOP, P.madder)
    end,
  }
end
