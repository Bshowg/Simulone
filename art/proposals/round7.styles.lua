-- ── the hut, corrected: walls set in from the footprint, a four-sided thatch whose eaves run all round and overhang them
local function hip4(c, x0, y0, x1, y1, e, rise, alongX, L, R, under)
  local xm, ym, d, T = (x0 + x1) / 2, (y0 + y1) / 2, 0.7, e + rise
  local A, B
  if alongX then
    A, B = c.pt(x0 + d, ym, T), c.pt(x1 - d, ym, T)
    c.quad(c.pt(x0, y0, e), c.pt(x1, y0, e), B, A, R); c.poly({ c.pt(x0, y0, e), c.pt(x0, y1, e), A }, L)
    c.quad(c.pt(x0, y1, e), c.pt(x1, y1, e), B, A, L); c.poly({ c.pt(x1, y1, e), c.pt(x1, y0, e), B }, R)
  else
    A, B = c.pt(xm, y0 + d, T), c.pt(xm, y1 - d, T)
    c.quad(c.pt(x0, y0, e), c.pt(x0, y1, e), B, A, L); c.poly({ c.pt(x0, y0, e), c.pt(x1, y0, e), A }, R)
    c.quad(c.pt(x1, y1, e), c.pt(x1, y0, e), A, B, R); c.poly({ c.pt(x0, y1, e), c.pt(x1, y1, e), B }, L)
  end
  c.quad(c.pt(x0, y1, e - 2), c.pt(x1, y1, e - 2), c.pt(x1, y1, e), c.pt(x0, y1, e), under)      -- the thickness of the thatch at the eaves
  c.quad(c.pt(x1, y1, e - 2), c.pt(x1, y0, e - 2), c.pt(x1, y0, e), c.pt(x1, y1, e), under)
  return A, B
end
S8.id = 'pastel-full-fixed'
S8.house = function(c, x0, y0, x1, y1, alongX)
  local i, h, INK = 0.1, 19, '#4a382c'
  local a0, b0, a1, b1 = x0 + i, y0 + i, x1 - i, y1 - i
  local fl, fr = faces(c, a0, b0, a1, b1)
  walls(c, a0, b0, a1, b1, h, brick('#f0eadc', '#b3a892', 0.5, 6, 3), brick('#cfc8b8', '#8f8674', -0.5, 6, 3))
  rect(c, fl, 0.36, 0.64, 0, 12, stripe('#a58a6c', '#8f765a', 2)); rect(c, fr, 0.38, 0.62, 6, 11, flat('#5a4a40'))
  local A, B = hip4(c, x0, y0, x1, y1, h - 2, 12, alongX, strokes('#dccc9e', '#8a7450', 0.5, 3, 3, 0.4), strokes('#b9a67a', '#6a5638', -0.5, 3, 2, 0.4), flat('#8a7450'))
  c.line(A, B, hex(INK))
  smoke(c, A, B, '#b4aca2')
end
-- ── the well, corrected: two posts stand on the rim and carry a small two-sided roof; a windlass and rope hang between them
S8.well = function(c, a, b, e, d)
  local INK, ym, xm = hex('#4a382c'), (b + d) / 2, (a + e) / 2
  walls(c, a, b, e, d, 8, S8.stoneL, S8.stoneR)
  c.quad(c.pt(a, b, 8), c.pt(e, b, 8), c.pt(e, d, 8), c.pt(a, d, 8), S8.stoneTop)
  c.quad(c.pt(a + 0.2, b + 0.2, 8), c.pt(e - 0.2, b + 0.2, 8), c.pt(e - 0.2, d - 0.2, 8), c.pt(a + 0.2, d - 0.2, 8), S8.wellWater)
  local wood = function(px) return hex(px % 2 == 0 and '#a58a6c' or '#8f765a') end
  for _, x in ipairs({ a + 0.08, e - 0.08 }) do c.quad(c.pt(x - 0.06, ym, 8), c.pt(x + 0.06, ym, 8), c.pt(x + 0.06, ym, 27), c.pt(x - 0.06, ym, 27), wood) end
  c.line(c.pt(a + 0.08, ym, 19), c.pt(e - 0.08, ym, 19), INK); c.line(c.pt(a + 0.08, ym, 20), c.pt(e - 0.08, ym, 20), hex('#a58a6c'))
  c.line(c.pt(xm, ym, 19), c.pt(xm, ym, 10), INK)
  local r0, r1, w, z0, z1 = a - 0.12, e + 0.12, 0.42, 24, 31
  c.quad(c.pt(r0, ym - w, z0), c.pt(r1, ym - w, z0), c.pt(r1, ym, z1), c.pt(r0, ym, z1), strokes('#b9a67a', '#6a5638', 0.5, 3, 2, 0.4))
  c.poly({ c.pt(r1, ym - w, z0), c.pt(r1, ym + w, z0), c.pt(r1, ym, z1) }, flat('#8a7450'))
  c.quad(c.pt(r0, ym + w, z0), c.pt(r1, ym + w, z0), c.pt(r1, ym, z1), c.pt(r0, ym, z1), strokes('#dccc9e', '#8a7450', 0.5, 3, 3, 0.4))
  c.line(c.pt(r0, ym, z1), c.pt(r1, ym, z1), INK)
end

