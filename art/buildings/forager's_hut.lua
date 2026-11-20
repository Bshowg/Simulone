-- Forager's hut, 2 x 2. A small round hut of wattle under a cone of thatch, where the gatherers bring back what the
-- woods give: baskets of nuts and berries by the door, mushrooms and bunches of herbs hung up to dry on a rack.
return function(ink)
  local M, P = ink.M, ink.P
  return {
    name = "forager's hut", w = 2, h = 2, height = 40,
    draw = function(c)
      -- the hut: a drum of wattle, a cone of thatch with a smoke hole
      c:cyl(0.95, 0.85, 0.62, 0, 13, M.wattle)
      c:cone(0.95, 0.85, 0.78, 11, 18, M.thatch)
      c:smoke(0.95, 0.85, 29, 10)
      -- the doorway, on the S side of the drum (the camera-facing face of the circle is drawn by hand)
      c:part(0.85, 1.4, 1.25, 1.5, 0, 10)
      c:poly3({ { 0.88, 1.46, 0 }, { 1.2, 1.46, 0 }, { 1.2, 1.46, 9 }, { 0.88, 1.46, 9 } }, P.dark, 'L')
      -- a drying rack beside it: two posts and a pole hung with bunches
      c:part(1.45, 0.25, 1.85, 0.3, 0, 14)
      c:post(1.48, 0.27, 0, 13, P.wood, 1); c:post(1.82, 0.27, 0, 13, P.wood, 1)
      c:line3(1.48, 0.27, 12, 1.82, 0.27, 12, P.woodShadeLine)
      for k = 0, 3 do
        local x = 1.53 + k * 0.085
        c:line3(x, 0.27, 12, x, 0.27, 9, P.ink2)
        c:dot3(x, 0.27, 8, 1, k % 2 == 0 and P.leafShade or P.earth2)   -- herbs, and strings of mushrooms
      end
      -- baskets by the door: nuts, berries, mushrooms
      local function basket(x, y, fill)
        c:part(x - 0.13, y - 0.13, x + 0.13, y + 0.13, 0, 5)
        c:dot3(x, y, 2, 3, M.planks)
        c:dot3(x, y - 0.02, 4, 2, fill)
      end
      basket(1.45, 1.6, P.woodShade); basket(1.7, 1.25, P.madder); basket(0.5, 1.65, P.linen)
      -- a few cut branches with leaves, leaning on the hut
      c:part(0.2, 0.5, 0.35, 1.1, 0, 12)
      c:line3(0.25, 1.05, 0, 0.3, 0.6, 11, P.wood); c:dot3(0.3, 0.6, 11, 2, P.leaf)
    end,
  }
end
