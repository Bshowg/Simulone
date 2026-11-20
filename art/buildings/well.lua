-- Well, 2 x 2. A square stone rim with water in it; two posts on the rim carry a small thatched roof, with a windlass
-- bar and a rope between them. The rest of the footprint is trodden ground (left empty: the ground shows).
return function(ink)
  local M, P = ink.M, ink.P
  return {
    name = 'well', w = 2, h = 2, height = 34,
    draw = function(c)
      local a, b = 0.55, 1.45
      c:box(a, a, b, b, 0, 8, { wall = M.stone })
      c:part(a + 0.2, a + 0.2, b - 0.2, b - 0.2, 8, 8.5, { plain = true })
      c:poly3({ { a + 0.2, a + 0.2, 8 }, { b - 0.2, a + 0.2, 8 }, { b - 0.2, b - 0.2, 8 }, { a + 0.2, b - 0.2, 8 } }, P.water2, 'T')
      -- posts on the rim at the two ends of the roof ridge, a windlass between them, a rope to the water
      c:part(a, 0.95, b, 1.05, 8, 27)
      c:post(a + 0.06, 1, 8, 27); c:post(b - 0.1, 1, 8, 27)
      c:line3(a + 0.06, 1, 19, b - 0.1, 1, 19, P.ink); c:line3(a + 0.06, 1, 20, b - 0.1, 1, 20, P.wood)
      c:line3(1, 1, 19, 1, 1, 10, P.ink)
      c:gable(a - 0.12, 1 - 0.42, b + 0.12, 1 + 0.42, 24, 7, 'x', { roof = M.thatch, gable = P.thatchUnder })
    end,
  }
end
