-- Cottage, 3 x 2. A better house than the hut, for two families: a timber frame with plaster panels, a steep gabled
-- thatch running along the long side, a plank door in the S wall, shuttered windows, and a small stone chimney on the
-- ridge with a curl of smoke.
return function(ink)
  local M, P = ink.M, ink.P
  return {
    name = 'cottage', w = 3, h = 2, height = 46,
    draw = function(c)
      local x0, y0, x1, y1, zw = 0.15, 0.2, 2.85, 1.8, 20
      local walls = c:box(x0, y0, x1, y1, 0, zw, { wall = M.plaster, top = false })
      -- the frame: posts, rail, sole plate and braces on the long walls, a simpler frame on the ends
      walls:frame('S', zw, 5, true); walls:frame('N', zw, 5, true)
      walls:frame('E', zw, 3, false); walls:frame('W', zw, 3, false)
      -- door on the entry cell (x = 1..2, centre 1.5)
      local ud = (1.5 - x0) / (x1 - x0)
      walls:door('S', ud, 0.42, 13)
      walls:line('S', ud - 0.08, 13, ud + 0.08, 13, P.beam)
      walls:window('S', 0.2, 0.22, 8, 5, { shutters = true })
      walls:window('S', 0.82, 0.22, 8, 5, { shutters = true })
      walls:window('N', 0.3, 0.22, 8, 5, { shutters = true })
      walls:window('N', 0.72, 0.22, 8, 5, { shutters = true })
      walls:window('E', 0.5, 0.25, 8, 5, { shutters = true })
      walls:window('W', 0.5, 0.25, 8, 5, { shutters = true })
      -- a steep thatch, ridge along x; the gable ends stand in the end walls' plane and the eaves overhang N and S
      local rise = 18
      local roof = c:gable(x0, 0.02, x1, 1.98, zw, rise, 'x', { roof = M.thatch, gable = M.plaster })
      for _, side in ipairs({ 'W', 'E' }) do
        roof:line(side, 0.5, 0, 0.5, rise, P.beam)
        roof:line(side, 0.12, 1, 0.88, 1, P.beam)
        roof:line(side, 0.5, 4, 0.3, 1, P.beam); roof:line(side, 0.5, 4, 0.7, 1, P.beam)
      end
      -- a small rubble chimney through the ridge near the E end, smoking
      local cz = zw + rise - 4
      c:box(2.18, 0.88, 2.42, 1.12, cz, cz + 9, { wall = M.stone, top = ink.plain(P.dark) })
      c:smoke(2.3, 1.0, cz + 10, 12)
    end,
  }
end
