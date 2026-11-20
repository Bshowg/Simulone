-- Storehouse, 3 x 2. A long, low barn for everything that is not grain: a stone footing, timber-framed wattle walls and
-- a hipped roof of shingles. Wide double doors in the middle of the S side stand open; barrels wait by the E end, a
-- basket of cabbages and a crate of eggs by the door, and a stack of sawn planks along the W end.
return function(ink)
  local M, P = ink.M, ink.P
  local stone = ink.plain(P.stone, P.stoneShade)

  -- a barrel standing at (x, y)
  local function barrel(c, x, y)
    c:cyl(x, y, 0.09, 0, 9, M.planks)
    c:part(x - 0.1, y - 0.1, x + 0.1, y + 0.1, 0, 10)
    c:dot3(x, y, 3, 1, P.iron); c:dot3(x, y, 7, 1, P.iron)
  end

  return {
    name = 'storehouse', w = 3, h = 2, height = 44,
    draw = function(c)
      local x0, y0, x1, y1, zf, zt = 0.15, 0.15, 2.85, 1.75, 4, 22
      -- stone footing, then the framed wattle walls
      c:box(x0, y0, x1, y1, 0, zf, { wall = M.stone, top = false })
      local walls = c:box(x0, y0, x1, y1, zf, zt, { wall = M.wattle, top = false })
      local h = zt - zf
      walls:frame('S', h, 5, true); walls:frame('N', h, 5, true); walls:frame('E', h, 3, false); walls:frame('W', h, 3, false)
      -- the wide double doors over the entry cell (x 1..2), standing open onto the dark inside
      walls:rect('S', 0.4, 0.6, 0, 14, P.dark)
      walls:line('S', 0.4, 0, 0.4, 14, P.beam); walls:line('S', 0.6, 0, 0.6, 14, P.beam); walls:line('S', 0.4, 14, 0.6, 14, P.beam)
      walls:rect('S', 0.32, 0.4, 0, 14, M.planks); walls:rect('S', 0.6, 0.68, 0, 14, M.planks)
      -- small shuttered vents on the long N side and the ends
      walls:window('N', 0.3, 0.2, 9, 4); walls:window('N', 0.7, 0.2, 9, 4)
      walls:window('E', 0.5, 0.2, 9, 4); walls:window('W', 0.5, 0.2, 9, 4)
      -- the hipped shingle roof, overhanging all round
      c:hip(0.05, 0.05, 2.95, 1.85, zt, 18, 'x', { roof = M.shingle })
      -- barrels by the E end
      barrel(c, 2.55, 1.9); barrel(c, 2.78, 1.9)
      -- a basket of cabbages and a crate of eggs beside the door
      c:part(0.95, 1.8, 1.15, 1.98, 0, 6)
      c:cyl(1.05, 1.89, 0.08, 0, 4, ink.plain(P.wattle, P.wattleShade))
      c:dot3(1.03, 1.87, 5, 2, P.green); c:dot3(1.08, 1.91, 5, 1, P.leaf)
      c:box(1.85, 1.82, 2.1, 1.97, 0, 3, { wall = M.planks, top = P.veil })
      -- a stack of sawn planks along the W end, on two bearers
      c:part(0.0, 0.3, 0.13, 1.6, 0, 6)
      c:poly3({ { 0.02, 0.35, 0 }, { 0.12, 0.35, 0 }, { 0.12, 1.55, 0 }, { 0.02, 1.55, 0 } }, P.woodShade, 'T')
      c:box(0.02, 0.35, 0.12, 1.55, 1, 5, { wall = M.logs, top = P.wood })
    end,
  }
end
