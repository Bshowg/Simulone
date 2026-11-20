-- Bakery, 3 x 2. A timber-framed, plastered house under thatch. A big domed clay bread oven on a stone plinth is built
-- against its E end, with its own stubby stone chimney and smoke; firewood is stacked against the W end, and a board of
-- loaves stands on trestles by the door in the S.
return function(ink)
  local M, P, pat = ink.M, ink.P, ink.pat
  local clay = { lit = function() return pat.speckle(P.earth, P.earth2, 0.8) end, shade = function() return pat.speckle(P.earth2, P.wattleShadeLine, 0.85) end,
                 top = function() return pat.speckle(P.earth, P.earth2, 0.8) end }
  local logEnds = function(base, line)
    local b, k = ink.hex(base), ink.hex(line)
    return function(px, py)
      local row = py // 3; local a, b2 = (px + row * 2) % 4, py % 3
      return ((a == 0 and b2 ~= 1) or (b2 == 0 and a ~= 2)) and k or b
    end
  end
  local logsMat = { lit = function() return logEnds(P.wattle, P.woodLine) end, shade = function() return logEnds(P.wattleShade, P.woodShadeLine) end, top = function() return pat.flat(P.wood) end }

  -- a dome of clay: base circle centre (cx, cy), radius r cells, from z0, `rise` pixels high
  local function dome(c, cx, cy, r, z0, rise, mat, zTopBound)
    c:part(cx - r, cy - r, cx + r, cy + r, z0, zTopBound or (z0 + rise))
    c:_op(function()
      local b = c:pt(cx, cy, z0)
      local rx, ry = r * 16 * 1.4142, r * 8 * 1.4142
      local up = math.sqrt(rise * rise + ry * ry)
      local lit, shade = mat.lit(0.5), mat.shade(-0.5)
      for dx = -math.floor(rx), math.floor(rx) do
        local e = math.sqrt(math.max(0, 1 - (dx / rx) ^ 2))
        local px = math.floor(b[1] + dx)
        for py = math.floor(b[2] - e * up), math.floor(b[2] + e * ry) do
          c:_put(px, py, (dx < -rx * 0.05 and lit or shade)(px, py))
        end
      end
    end)
  end

  return {
    name = 'bakery', w = 3, h = 2, height = 38,
    draw = function(c)
      local x0, y0, x1, y1, wz = 0.35, 0.15, 2.1, 1.62, 20
      -- firewood stacked against the W end: log ends face out
      c:box(0.05, 0.35, 0.3, 1.4, 0, 10, { wall = M.logs, W = logsMat, E = logsMat, top = P.wood })

      local h = c:box(x0, y0, x1, y1, 0, wz, { wall = M.plaster, top = false })
      for _, s in ipairs({ 'S', 'N' }) do h:frame(s, wz, 5, true) end
      for _, s in ipairs({ 'E', 'W' }) do h:frame(s, wz, 3, false) end
      local du = (1.5 - x0) / (x1 - x0)                        -- the entry cell is x = 1..2 on the S side
      h:door('S', du, 0.45, 13)
      h:window('S', 0.2, 0.25, 9, 5, { shutters = true })
      h:window('N', 0.35, 0.25, 9, 5, { shutters = true })
      h:window('N', 0.75, 0.25, 9, 5)
      h:window('W', 0.5, 0.3, 12, 5)
      h:window('E', 0.2, 0.2, 13, 4)
      local g = c:gable(x0 - 0.08, y0 - 0.1, x1 + 0.08, y1 + 0.13, wz - 2, 15, 'x', { roof = M.thatch, gable = M.plaster })
      for _, s in ipairs({ 'E', 'W' }) do g:line(s, 0.5, 0, 0.5, 14, P.beam); g:line(s, 0.3, 0, 0.5, 9, P.beam); g:line(s, 0.7, 0, 0.5, 9, P.beam) end

      -- the oven: a stone plinth, a clay dome with its mouth to the S, a stubby chimney at the back of the dome
      local ox, oy, orr, oz = 2.53, 0.92, 0.42, 4
      c:box(ox - orr, oy - orr, ox + orr, oy + orr, 0, oz, { wall = M.stone })
      dome(c, ox, oy, orr - 0.03, oz, 9, clay, oz + 7)
      local ss = c:visible('S')
      if ss then                                                -- the oven mouth, a dark arch with a stone lip
        local y = oy + orr - 0.03
        local function arch(hw, top)
          local pts = { { ox - hw, y, oz } , { ox + hw, y, oz } }
          for k = 0, 8 do local a = math.pi * k / 8; pts[#pts + 1] = { ox + hw * math.cos(a), y, oz + top - 3 + 3 * math.sin(a) } end
          return pts
        end
        c:poly3(arch(0.15, 7), P.stoneShade, ss)
        c:poly3(arch(0.1, 5), P.dark, ss)
      end
      local ch = c:box(ox - 0.09, oy - 0.3, ox + 0.09, oy - 0.12, oz + 7, oz + 15, { wall = clay, top = P.dark })
      for _, s in ipairs({ 'N', 'E', 'S', 'W' }) do ch:rect(s, 0, 1, 6, 8, ink.plain(P.earth2, P.wattleShadeLine)) end
      c:smoke(ox, oy - 0.21, oz + 16, 16)

      -- a board of loaves on trestles by the door
      c:part(0.7, 1.76, 1.2, 1.94, 0, 5)
      c:post(0.74, 1.8, 0, 5, P.wood, 1); c:post(1.16, 1.8, 0, 5, P.wood, 1)
      c:post(0.74, 1.9, 0, 5, P.wood, 1); c:post(1.16, 1.9, 0, 5, P.wood, 1)
      c:box(0.68, 1.76, 1.22, 1.94, 5, 6, { wall = M.planks })
      for i, x in ipairs({ 0.78, 0.92, 1.06, 1.14 }) do
        local y = i % 2 == 0 and 1.88 or 1.82
        c:part(x - 0.05, y - 0.04, x + 0.05, y + 0.04, 6, 9)
        c:dot3(x, y, 7, 2, P.weld)
        c:dot3(x - 0.01, y, 8, 1, P.corn)
      end
    end,
  }
end
