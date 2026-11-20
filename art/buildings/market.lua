-- Market place, 4 x 4. An open place where the game draws the crowd: most of the ground is left empty. A stone market
-- cross on three steps stands near the middle; four stalls stand round the edges, each a trestle table under a cloth
-- awning on poles that slopes down towards the middle, with its goods: baskets of produce, sacks, bolts of cloth, pots.
-- The S side is open (the cell x = 2..3 is the way in).
return function(ink)
  local M, P, pat = ink.M, ink.P, ink.pat

  local function clothMat(col) return { lit = function() return pat.flat(col) end, shade = function() return pat.hatch(col, P.woodLine, 4) end, top = function() return pat.flat(col) end } end
  local wicker = { lit = function() return pat.lattice(P.wattle, P.wattleLine, 3) end, shade = function() return pat.lattice(P.wattleShade, P.wattleShadeLine, 3) end }
  local sackMat = ink.plain(P.linen, P.wattleShade)

  local function basket(c, x, y, z, fill)
    c:cyl(x, y, 0.1, z, z + 3, wicker, fill)
    c:dot3(x, y, z + 3, 1, fill)
  end
  local function sack(c, x, y, z, tall)
    tall = tall or 5
    c:box(x - 0.08, y - 0.08, x + 0.08, y + 0.08, z, z + tall, { wall = sackMat })
    c:part(x - 0.05, y - 0.05, x + 0.05, y + 0.05, z + tall, z + tall + 2)
    c:dot3(x, y, z + tall + 1, 1, P.linen)
  end
  local function bolt(c, x0, y0, x1, y1, z, col)
    c:box(x0, y0, x1, y1, z, z + 2, { wall = ink.plain(col, col), top = col })
  end
  local function pot(c, x, y, z)
    c:cyl(x, y, 0.07, z, z + 4, ink.plain(P.tile, P.tileShade), P.dark)
  end

  -- a stall: awning over (x0, y0)..(x1, y1), high along `high`; `goods(c, tx0, ty0, tx1, ty1, z)` fills the table top
  local function stall(c, x0, y0, x1, y1, high, cloth, goods)
    local zl, zh = 17, 22
    -- poles at the four corners, up to the underside of the awning
    for _, p in ipairs({ { x0 + 0.02, y0 + 0.02 }, { x1 - 0.04, y0 + 0.02 }, { x1 - 0.04, y1 - 0.04 }, { x0 + 0.02, y1 - 0.04 } }) do
      c:part(p[1] - 0.02, p[2] - 0.02, p[1] + 0.04, p[2] + 0.04, 0, zl - 2)
      c:post(p[1], p[2], 0, zl - 2, P.wood, 2)
    end
    -- the table stands under the low (front) half of the awning
    local i, d, o = 0.08, 0.32, 0.12                       -- the table reaches a little out in front of the awning
    local tx0, ty0, tx1, ty1 = x0 + i, y0 + i, x1 - i, y1 - i
    if high == 'N' then ty1 = y1 + o; ty0 = ty1 - d elseif high == 'S' then ty0 = y0 - o; ty1 = ty0 + d
    elseif high == 'W' then tx1 = x1 + o; tx0 = tx1 - d else tx0 = x0 - o; tx1 = tx0 + d end
    local t = c:box(tx0, ty0, tx1, ty1, 0, 6, { wall = M.planks, top = P.wood })
    for _, sd in ipairs({ 'N', 'E', 'S', 'W' }) do t:rect(sd, 0, 1, 4, 6, M.logs); t:line(sd, 0, 4, 1, 4, P.woodShadeLine) end
    goods(c, tx0, ty0, tx1, ty1, 6)
    c:shed(x0, y0, x1, y1, zl, zh, high, { roof = cloth, wall = cloth })
  end

  return {
    name = 'market', w = 4, h = 4, height = 39,
    draw = function(c)
      -- the market cross on its steps
      local cx, cy = 2.0, 1.85
      c:box(cx - 0.42, cy - 0.42, cx + 0.42, cy + 0.42, 0, 3, { wall = M.ashlar })
      c:box(cx - 0.3, cy - 0.3, cx + 0.3, cy + 0.3, 3, 6, { wall = M.ashlar })
      c:box(cx - 0.18, cy - 0.18, cx + 0.18, cy + 0.18, 6, 9, { wall = M.ashlar })
      c:box(cx - 0.07, cy - 0.07, cx + 0.07, cy + 0.07, 9, 37, { wall = M.plaster, top = P.stone })
      c:box(cx - 0.38, cy - 0.07, cx - 0.07, cy + 0.07, 25, 31, { wall = M.plaster, top = P.stone })
      c:box(cx + 0.07, cy - 0.07, cx + 0.38, cy + 0.07, 25, 31, { wall = M.plaster, top = P.stone })

      -- N stall: produce
      stall(c, 0.6, 0.22, 1.8, 0.78, 'N', clothMat(P.madder), function(c, a, b, x1, y1, z)
        basket(c, a + 0.14, (b + y1) / 2, z, P.madder); basket(c, a + 0.38, (b + y1) / 2, z, P.leaf)
        basket(c, a + 0.62, (b + y1) / 2, z, P.weld); basket(c, a + 0.86, (b + y1) / 2, z, P.leafShade)
      end)
      -- E stall: cloth
      stall(c, 3.22, 1.2, 3.8, 2.45, 'E', clothMat(P.woad), function(c, a, b, x1, y1, z)
        bolt(c, a + 0.05, b + 0.08, x1 - 0.05, b + 0.28, z, P.madder)
        bolt(c, a + 0.05, b + 0.36, x1 - 0.05, b + 0.56, z, P.weld)
        bolt(c, a + 0.05, b + 0.36, x1 - 0.05, b + 0.56, z + 2, P.green)
        bolt(c, a + 0.05, b + 0.64, x1 - 0.05, b + 0.84, z, P.linen)
        bolt(c, a + 0.05, b + 0.92, x1 - 0.05, b + 1.08, z, P.woad)
      end)
      -- W stall: grain and meal in sacks
      stall(c, 0.2, 1.75, 0.76, 2.95, 'W', clothMat(P.weld), function(c, a, b, x1, y1, z)
        sack(c, (a + x1) / 2, b + 0.15, z); sack(c, (a + x1) / 2, b + 0.4, z, 4); sack(c, (a + x1) / 2, b + 0.65, z)
        basket(c, (a + x1) / 2, b + 0.9, z, P.corn)
      end)
      -- S stall: pots and eggs
      stall(c, 0.35, 3.22, 1.55, 3.78, 'S', clothMat(P.green), function(c, a, b, x1, y1, z)
        pot(c, a + 0.12, (b + y1) / 2, z); pot(c, a + 0.3, (b + y1) / 2, z); basket(c, a + 0.52, (b + y1) / 2, z, P.veil)
        pot(c, a + 0.75, (b + y1) / 2, z); basket(c, a + 0.95, (b + y1) / 2, z, P.madder)
      end)

      -- a few goods on the ground beside the stalls
      sack(c, 1.98, 0.5, 0); sack(c, 2.14, 0.62, 0, 4)
      basket(c, 3.0, 2.7, 0, P.leaf)
      sack(c, 0.24, 3.06, 0, 4)
    end,
  }
end
