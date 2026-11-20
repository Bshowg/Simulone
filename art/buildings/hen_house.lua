-- Hen house, 2 x 2. A small wattle coop raised a little on posts, under a lean-to of thatch, with a plank ramp up to
-- its pop-hole on the S side, a fenced run of wattle hurdles beside it, a feeding trough and a few hens pecking.
return function(ink)
  local M, P = ink.M, ink.P
  return {
    name = 'hen house', w = 2, h = 2, height = 34,
    draw = function(c)
      -- the coop: on four short posts, wattle walls, a thatched lean-to falling to the S
      local x0, y0, x1, y1 = 0.15, 0.15, 1.25, 1.05
      for _, p in ipairs({ { x0 + 0.05, y0 + 0.05 }, { x1 - 0.05, y0 + 0.05 }, { x0 + 0.05, y1 - 0.05 }, { x1 - 0.05, y1 - 0.05 } }) do
        c:part(p[1] - 0.04, p[2] - 0.04, p[1] + 0.04, p[2] + 0.04, 0, 4); c:post(p[1], p[2], 0, 4, P.wood, 2)
      end
      local coop = c:box(x0, y0, x1, y1, 4, 15, { wall = M.wattle, top = false })
      coop:rect('S', 0.42, 0.62, 0, 5, P.dark)                    -- the pop-hole the hens use
      coop:frame('S', 11, 3, false, P.beam); coop:frame('E', 11, 2, false, P.beam); coop:frame('W', 11, 2, false, P.beam); coop:frame('N', 11, 3, false, P.beam)
      c:shed(x0 - 0.1, y0 - 0.1, x1 + 0.1, y1 + 0.12, 13, 20, 'N', { roof = M.thatch, wall = M.wattle })
      -- the ramp from the pop-hole down to the ground
      c:part(0.65, 1.05, 0.85, 1.55, 0, 5)
      c:poly3({ { 0.66, 1.05, 4 }, { 0.84, 1.05, 4 }, { 0.84, 1.5, 0 }, { 0.66, 1.5, 0 } }, M.planks, 'T')
      c:line3(0.66, 1.2, 3, 0.84, 1.2, 3, P.woodLine); c:line3(0.66, 1.35, 1.5, 0.84, 1.35, 1.5, P.woodLine)
      -- the run: low wattle hurdles round the E part of the footprint, open towards the door cell
      local function hurdle(ax, ay, bx, by)
        c:part(math.min(ax, bx) - 0.03, math.min(ay, by) - 0.03, math.max(ax, bx) + 0.03, math.max(ay, by) + 0.03, 0, 6)
        c:poly3({ { ax, ay, 0 }, { bx, by, 0 }, { bx, by, 6 }, { ax, ay, 6 } }, ax == bx and M.wattle.shade() or M.wattle.lit(), ax == bx and 'R' or 'L')
        c:line3(ax, ay, 6, bx, by, 6, P.wood)
      end
      hurdle(1.4, 0.15, 1.9, 0.15); hurdle(1.9, 0.15, 1.9, 1.85); hurdle(1.15, 1.85, 1.9, 1.85)
      -- a trough
      c:box(1.45, 0.9, 1.8, 1.05, 0, 2, { wall = M.planks, top = P.corn2 })
      -- hens: small pale bodies with a red comb
      for k, h in ipairs({ { 1.55, 0.55 }, { 1.7, 1.35 }, { 1.3, 1.55 }, { 0.45, 1.6 } }) do
        c:part(h[1] - 0.06, h[2] - 0.06, h[1] + 0.06, h[2] + 0.06, 0, 4)
        c:dot3(h[1], h[2], 2, 1, k % 2 == 0 and P.linen or P.veil)
        c:dot3(h[1] - 0.05, h[2] + 0.02, 3.5, 0, P.madder)
      end
    end,
  }
end
