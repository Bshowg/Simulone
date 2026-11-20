-- Woodcutters' lodge, 3 x 3. A low log-walled house under a thatch at the back of the plot, an open shingled lean-to
-- on its E end with split firewood stacked under it, a pile of felled trunks along the W edge of the yard, and a
-- chopping block with an axe in it among split billets.
return function(ink)
  local M, P = ink.M, ink.P
  local none = function() return 0 end                         -- a fill that draws nothing (open sides)
  -- end grain of stacked billets: pale cut ends in little courses
  local billets = { lit = function(s) return ink.pat.brick(P.wattle, P.woodLine, s, 3, 3) end,
                    shade = function(s) return ink.pat.brick(P.wattleShade, P.woodShadeLine, s, 3, 3) end,
                    top = function() return ink.pat.planks(P.wood, P.woodLine, 2) end }

  -- a felled trunk lying along y from ya to yb at x, its centre zc pixels up, r pixels thick; the cut end that faces
  -- the camera shows its pale wood and a heart
  local function trunk(c, x, ya, yb, zc, r)
    c:part(x - 0.07, ya, x + 0.07, yb, zc - r, zc + r)
    local n = math.floor((yb - ya) / 0.03)
    for k = 0, n do c:dot3(x, ya + (yb - ya) * k / n, zc, r, P.woodShade) end
    for k = 0, n do c:dot3(x, ya + (yb - ya) * k / n, zc + 1, r - 1, P.wood) end
    for k = 2, n - 2, 5 do c:dot3(x, ya + (yb - ya) * k / n, zc + 1, 0, P.woodLine) end
    local ye = c:visible('S') and yb or ya
    c:dot3(x, ye, zc, r, P.wattle); c:dot3(x, ye, zc, 0, P.woodLine)
  end

  return {
    name = 'lodge', w = 3, h = 3, height = 26,
    draw = function(c)
      -- the house: log walls, thatch with the ridge along x, plank gables
      local x0, y0, x1, y1, zw = 0.15, 0.2, 2.0, 1.85, 16
      local walls = c:box(x0, y0, x1, y1, 0, zw, { wall = M.logs, top = false })
      local ud = (1.5 - x0) / (x1 - x0)
      walls:door('S', ud, 0.42, 12, { fill = ink.plain(P.dark) })
      walls:rect('S', ud - 0.105, ud - 0.04, 0, 11, M.planks) -- the door leaf stands open
      walls:line('S', ud - 0.04, 0, ud - 0.04, 11)
      walls:window('S', 0.25, 0.25, 7, 4, { shutters = true })
      walls:window('W', 0.5, 0.25, 7, 4, { shutters = true })
      walls:window('N', 0.6, 0.25, 7, 4, { shutters = true })
      walls:window('E', 0.3, 0.2, 9, 4)
      local rise = 14
      local roof = c:gable(x0, 0.02, x1, 2.03, zw, rise, 'x', { roof = M.thatch, gable = M.planks })
      c:smoke(0.9, 1.02, zw + rise - 2, 10)

      -- the open lean-to on the E end, roofed with shingles, two posts at its outer edge, firewood stacked under it
      local lx0, lx1, ly0, ly1 = x1, 2.88, 0.3, 1.78
      c:box(2.06, 0.42, 2.55, 1.66, 0, 9, { wall = billets, N = M.logs, S = M.logs, top = billets })
      c:part(2.78, ly0, 2.84, ly0 + 0.06, 0, 12); c:post(2.8, ly0 + 0.03, 0, 12)
      c:part(2.78, ly1 - 0.06, 2.84, ly1, 0, 12); c:post(2.8, ly1 - 0.03, 0, 12)
      c:shed(lx0, ly0 - 0.08, lx1, ly1 + 0.08, 12, 15, 'W', { roof = M.shingle, wall = none })

      -- felled trunks piled along the W edge of the yard (clear of the door in every view)
      local r = 3
      trunk(c, 0.2, 2.08, 2.9, r, r); trunk(c, 0.42, 2.08, 2.9, r, r)
      trunk(c, 0.31, 2.14, 2.84, 3 * r - 1, r)

      -- the chopping block with the axe bitten into it, split billets lying round
      local bx, by = 2.45, 2.45
      c:cyl(bx, by, 0.15, 0, 7, ink.plain(P.wood, P.woodShade), ink.plain(P.wattle))
      c:part(bx - 0.1, by - 0.05, bx + 0.34, by + 0.05, 7, 14)
      c:line3(bx - 0.03, by, 8, bx + 0.27, by, 14, P.wood); c:line3(bx - 0.02, by, 8, bx + 0.28, by, 14, P.woodShade)
      c:poly3({ { bx - 0.1, by, 7 }, { bx + 0.01, by, 7 }, { bx + 0.03, by, 11 }, { bx - 0.08, by, 10 } }, P.iron)
      c:box(2.0, 2.65, 2.2, 2.72, 0, 2, { wall = billets })
      c:box(2.7, 2.2, 2.77, 2.4, 0, 2, { wall = billets })
      c:box(2.55, 2.8, 2.75, 2.87, 0, 2, { wall = billets })
    end,
  }
end
