-- Granary, 3 x 3. A tall plank store raised off the ground on nine stone staddles (mushroom stones that the rats
-- cannot climb), under a steep shingle roof with its gables N and S. A loading door high in the S wall is reached by a
-- ladder; a few sacks of grain wait at its foot.
return function(ink)
  local M, P = ink.M, ink.P
  local stone = ink.plain(P.stone, P.stoneShade)

  -- a sack of grain sitting on the ground at (x, y)
  local function sack(c, x, y, big)
    local r = big and 3 or 2
    c:part(x - 0.1, y - 0.1, x + 0.1, y + 0.1, 0, 3 * r + 3)
    c:dot3(x, y, r, r + 1, P.wattleShade)                    -- the shaded belly
    c:dot3(x - 0.03, y + 0.03, r + 1, r, P.linen)
    c:dot3(x, y, 2 * r + 1, r - 1, P.linen)                  -- the shoulders
    c:dot3(x, y, 3 * r, 1, P.wattleLine)                     -- the tied neck
    c:dot3(x, y, 3 * r + 2, 1, P.linen)
  end

  return {
    name = 'granary', w = 3, h = 3, height = 50,
    draw = function(c)
      local a, b, zb, zt = 0.45, 2.55, 14, 40            -- the store box and the height of its floor and eaves
      -- staddles: a tapering stone stem with a wide flat cap
      for _, x in ipairs({ 0.62, 1.5, 2.38 }) do for _, y in ipairs({ 0.62, 1.5, 2.38 }) do
        c:cyl(x, y, 0.1, 0, 3, stone)
        c:cyl(x, y, 0.07, 3, 9, stone)
        c:cyl(x, y, 0.17, 9, zb - 1, stone)
      end end
      -- the floor beam, then the plank walls
      c:box(a, a, b, b, zb - 1, zb + 1, { wall = ink.plain(P.beam, P.woodShadeLine), top = false })
      local walls = c:box(a, a, b, b, zb + 1, zt, { wall = M.planks, top = false })
      local h = zt - zb - 1
      for _, side in ipairs({ 'N', 'S', 'E', 'W' }) do
        walls:line(side, 0.02, 0, 0.02, h, P.beam); walls:line(side, 0.98, 0, 0.98, h, P.beam)
        walls:line(side, 0, h // 2, 1, h // 2, P.beam); walls:line(side, 0, h - 1, 1, h - 1, P.beam)
      end
      -- loading door high on the S wall, over the entry cell; small vents on the other walls
      walls:door('S', 0.5, 0.45, 12, { z = 2 })
      walls:line('S', 0.5, 2, 0.5, 14, P.woodShadeLine)
      walls:window('N', 0.5, 0.2, 16, 4); walls:window('E', 0.5, 0.2, 16, 4); walls:window('W', 0.5, 0.2, 16, 4)
      -- the steep roof, overhanging E and W
      local rise = 24
      local roof = c:gable(0.22, a, 2.78, b, zt, rise, 'y', { roof = M.thatch, gable = M.planks })
      roof:window('S', 0.5, 0.25, 6, 5); roof:window('N', 0.5, 0.25, 6, 5)
      -- a ladder from the ground to the door sill
      local zs = zb + 1 + 2
      c:part(1.33, 2.56, 1.67, 2.98, 0, zs + 2)
      for _, x in ipairs({ 1.38, 1.62 }) do
        c:line3(x, 2.95, 0, x, 2.57, zs + 2, P.wood); c:line3(x + 0.03, 2.95, 0, x + 0.03, 2.57, zs + 2, P.woodShade)
      end
      for k = 1, 5 do local t = k / 6; c:line3(1.38, 2.95 - 0.38 * t, (zs + 2) * t, 1.62, 2.95 - 0.38 * t, (zs + 2) * t, P.woodShade) end
      -- sacks
      sack(c, 0.8, 2.82, true); sack(c, 1.03, 2.86, false); sack(c, 2.15, 2.8, true)
    end,
  }
end
