-- Hut, 2 x 2. A one-room peasant house: low rubble walls, a four-sided thatch that overhangs them, a plank door in
-- the S wall (where the game puts the entry) and one small window.
return function(ink)
  local M, P = ink.M, ink.P
  return {
    name = 'hut', w = 2, h = 2, height = 34,
    draw = function(c)
      local i = 0.1                                            -- walls stand in from the footprint so the eaves can overhang
      local walls = c:box(i, i, 2 - i, 2 - i, 0, 19, { wall = M.stone, top = false })
      walls:door('S', 0.78, 0.5, 12)                           -- the entry cell is x = 1..2 on the S side
      walls:window('E', 0.5, 0.45, 6, 5)
      walls:window('W', 0.5, 0.45, 6, 5)
      walls:window('N', 0.3, 0.45, 6, 5)
      c:hip(0, 0, 2, 2, 17, 12, 'x', { roof = M.thatch }, 0.7)
      c:smoke(1.15, 1, 29, 18)
    end,
  }
end
