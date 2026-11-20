-- Hospital, 4 x 3. A monastic infirmary: a long rubble stone hall along x under a tiled roof, with a row of small
-- round-headed windows; a taller little chapel at the E end with a cross on its gable; a covered timber porch over the
-- door in the S wall (the entry); and in the SW corner a walled herb garden with beds of plants.
return function(ink)
  local M, P = ink.M, ink.P
  local HX0, HX1, HY0, HY1 = 0.15, 2.95, 0.28, 1.62
  return {
    name = 'hospital', w = 4, h = 3, height = 60,
    draw = function(c)
      -- the infirmary hall
      local hall = c:box(HX0, HY0, HX1, HY1, 0, 19, { wall = M.stone, top = false })
      for _, s in ipairs({ 'N', 'S' }) do
        for k = 0, 5 do
          local uu = (k + 0.5) / 6
          if not (s == 'S' and k == 5) then hall:window(s, uu, 0.13, 7, 6, { arch = true }) end
        end
        hall:rect(s, 0, 1, 0, 2, P.stoneLine)
      end
      hall:window('W', 0.5, 0.16, 7, 6, { arch = true })
      hall:door('S', (2.5 - HX0) / (HX1 - HX0), 0.42, 12, { arch = true })
      local hr = c:gable(HX0, HY0 - 0.16, HX1, HY1 + 0.16, 19, 18, 'x', { roof = M.tile, gable = M.stone })
      hr:window('W', 0.5, 0.18, 6, 5, { arch = true })

      -- the chapel at the E end, a little taller, with a cross
      local CX0, CX1, CY0, CY1 = HX1, 3.85, 0.4, 1.5
      local ch = c:box(CX0, CY0, CX1, CY1, 0, 23, { wall = M.stone, top = false })
      ch:window('E', 0.5, 0.2, 7, 10, { arch = true, fill = P.dark })
      ch:line('E', 0.5, 7, 0.5, 16, P.ink2)
      ch:window('N', 0.5, 0.13, 8, 7, { arch = true })
      ch:window('S', 0.5, 0.13, 8, 7, { arch = true })
      c:gable(CX0, CY0 - 0.12, CX1, CY1 + 0.12, 23, 17, 'x', { roof = M.tile, gable = M.stone })
      c:part(3.83, 0.88, 3.87, 1.02, 39, 49)
      c:post(3.85, 0.95, 39, 49, P.wood, 2)
      c:line3(3.85, 0.87, 46, 3.85, 1.03, 46, P.wood)
      c:line3(3.85, 0.87, 45, 3.85, 1.03, 45, P.woodShade)

      -- the covered porch over the door: four posts, a low boarded rail, a small tiled gable
      local PX0, PX1, PY0, PY1 = 2.17, 2.83, HY1, 2.22
      for _, p in ipairs({ { PX0 + 0.03, PY1 - 0.05 }, { PX1 - 0.07, PY1 - 0.05 } }) do
        c:part(p[1] - 0.02, p[2] - 0.02, p[1] + 0.04, p[2] + 0.04, 0, 11)
        c:post(p[1], p[2], 0, 11, P.wood, 2)
      end
      for _, x in ipairs({ PX0, PX1 - 0.04 }) do
        local rail = c:box(x, PY0 + 0.02, x + 0.04, PY1 - 0.08, 0, 5, { wall = M.planks })
      end
      local pr = c:gable(PX0 - 0.06, PY0, PX1 + 0.06, PY1 + 0.04, 10, 8, 'y', { roof = M.tile, gable = M.planks })

      -- the walled herb garden in the SW corner
      local GX0, GX1, GY0, GY1 = 0.1, 1.9, 1.88, 2.9
      local wallM = { wall = M.stone }
      c:box(GX0, GY0, GX1, GY0 + 0.1, 0, 5, wallM)                -- N wall, along the hall
      c:box(GX0, GY0 + 0.1, GX0 + 0.1, GY1, 0, 5, wallM)          -- W wall
      c:box(GX1 - 0.1, GY0 + 0.1, GX1, 2.25, 0, 5, wallM)         -- E wall, with a gap for the gate
      c:box(GX1 - 0.1, 2.55, GX1, GY1, 0, 5, wallM)
      c:box(GX0 + 0.1, GY1 - 0.1, GX1 - 0.1, GY1, 0, 5, wallM)    -- S wall
      -- three beds of herbs: rows of leaves on raised earth, a few taller plants
      local herbs = ink.pat.blotch(P.leaf, P.leafShade, 2, 1)
      local herbs2 = ink.pat.blotch(P.green, P.grass2, 2, 1)
      for i, bx in ipairs({ 0.3, 0.82, 1.34 }) do
        c:box(bx, 2.1, bx + 0.38, 2.68, 0, 3, { wall = M.earth, top = (i % 2 == 0) and herbs2 or herbs })
      end
      for _, p in ipairs({ { 0.49, 2.25 }, { 1.01, 2.5 }, { 1.53, 2.3 } }) do
        c:part(p[1] - 0.06, p[2] - 0.06, p[1] + 0.06, p[2] + 0.06, 3, 7)
        c:dot3(p[1], p[2], 5, 2, P.leafShade)
        c:dot3(p[1], p[2], 6, 1, P.leaf)
      end
    end,
  }
end
