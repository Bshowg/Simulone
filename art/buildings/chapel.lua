-- Chapel, 3 x 4. A humble village chapel: a rubble stone nave running along y with a steep shingle roof, a lower
-- chancel at the N end, a round-arched door in the S gable (the liturgical west front, where the game puts the entry),
-- a little timber bell-cote with its bell on that gable, narrow round-headed windows, a wooden cross on the N (east) gable.
return function(ink)
  local M, P = ink.M, ink.P
  return {
    name = 'chapel', w = 3, h = 4, height = 70,
    draw = function(c)
      -- chancel (east end, N), lower and narrower
      local ch = c:box(0.75, 0.2, 2.25, 1.35, 0, 16, { wall = M.stone, top = false })
      ch:window('N', 0.5, 0.14, 5, 7, { arch = true })
      ch:window('E', 0.5, 0.14, 5, 7, { arch = true })
      ch:window('W', 0.5, 0.14, 5, 7, { arch = true })
      c:gable(0.62, 0.2, 2.38, 1.35, 16, 19, 'y', { roof = M.shingle, gable = M.stone })
      -- a wooden cross on the east gable
      c:part(1.3, 0.18, 1.7, 0.22, 34, 48)
      c:post(1.5, 0.2, 33, 48, P.wood, 2)
      c:line3(1.32, 0.2, 44, 1.68, 0.2, 44, P.wood)
      c:line3(1.32, 0.2, 43, 1.68, 0.2, 43, P.woodShade)

      -- nave
      local nave = c:box(0.4, 1.35, 2.6, 3.8, 0, 21, { wall = M.stone, top = false })
      -- a round-arched plank door with a ring of ink round it
      nave:arch('S', 0.5, 0.25 / 2.2 + 0.03, 0, 9, 6, P.ink)
      nave:arch('S', 0.5, 0.25 / 2.2, 0, 9, 5, M.planks)
      nave:window('S', 0.14, 0.12, 9, 7, { arch = true })
      nave:window('S', 0.86, 0.12, 9, 7, { arch = true })
      nave:window('N', 0.5, 0.12, 8, 6, { arch = true })
      for _, s in ipairs({ 'E', 'W' }) do
        nave:window(s, 0.22, 0.13, 7, 8, { arch = true })
        nave:window(s, 0.62, 0.13, 7, 8, { arch = true })
        nave:rect(s, 0, 1, 0, 2, s == 'E' and P.stoneShadeLine or P.stoneLine) -- a plinth course
      end
      local nr = c:gable(0.25, 1.35, 2.75, 3.8, 21, 27, 'y', { roof = M.shingle, gable = M.stone })
      nr:window('S', 0.5, 0.1, 9, 5, { arch = true })     -- a little light high in the west gable

      -- bell-cote astride the west (S) gable: a boarded base, two posts with the bell between, a tiny shingle roof
      c:box(1.26, 3.56, 1.74, 3.8, 43, 50, { wall = M.planks })
      c:part(1.25, 3.66, 1.75, 3.7, 50, 60)
      c:post(1.27, 3.68, 50, 60, P.wood, 2)
      c:post(1.69, 3.68, 50, 60, P.wood, 2)
      c:line3(1.3, 3.68, 59, 1.69, 3.68, 59, P.woodShade)
      c:part(1.38, 3.67, 1.62, 3.69, 51, 58)
      c:poly3({ { 1.38, 3.68, 52 }, { 1.62, 3.68, 52 }, { 1.58, 3.68, 54 }, { 1.56, 3.68, 57 }, { 1.5, 3.68, 58 }, { 1.44, 3.68, 57 }, { 1.42, 3.68, 54 } }, P.iron)
      c:line3(1.5, 3.68, 52, 1.5, 3.68, 51, P.ink)
      c:gable(1.18, 3.5, 1.82, 3.88, 60, 7, 'x', { roof = M.shingle, gable = M.planks })
    end,
  }
end
