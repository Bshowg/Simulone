-- Carpenter's shop, 3 x 2. A timber-framed workshop under a shingle roof whose E end is an open bay: a workbench
-- against the shop wall with a saw and a mallet hung above it, sawn boards leaning on the plank back wall, and outside
-- the bay a sawhorse with a log on it. More boards lean against the W wall.
return function(ink)
  local M, P = ink.M, ink.P
  local pale = ink.plain(P.wattle, P.wattleShade)              -- fresh-sawn wood
  local sawn = ink.plain(P.wood, P.woodShade)                  -- seasoned boards

  -- the top and visible sides of a slab, added to the current part
  local function slab(c, x0, y0, x1, y1, z0, z1, mat)
    c:poly3({ { x0, y0, z1 }, { x1, y0, z1 }, { x1, y1, z1 }, { x0, y1, z1 } }, mat, 'T')
    local faces = { S = { { x0, y1 }, { x1, y1 } }, N = { { x1, y0 }, { x0, y0 } }, E = { { x1, y1 }, { x1, y0 } }, W = { { x0, y0 }, { x0, y1 } } }
    for side, e in pairs(faces) do
      local ss = c:visible(side)
      if ss then c:poly3({ { e[1][1], e[1][2], z0 }, { e[2][1], e[2][2], z0 }, { e[2][1], e[2][2], z1 }, { e[1][1], e[1][2], z1 } }, mat, ss) end
    end
  end
  -- a board leaning on a wall along y (facing +x when dir = 1, -x when -1) at x = xw: y .. y + wd, top at z
  local function boardX(c, xw, dir, y, wd, foot, z)
    local light = c:visible(dir > 0 and 'E' or 'W') or 'L'
    c:poly3({ { xw + dir * foot, y, 0 }, { xw + dir * foot, y + wd, 0 }, { xw + dir * 0.02, y + wd, z }, { xw + dir * 0.02, y, z } }, sawn, light)
  end
  -- a board leaning on a wall along x facing +y, at y = yw: x .. x + wd, top at z
  local function boardY(c, yw, x, wd, foot, z)
    local light = c:visible('S') or 'L'
    c:poly3({ { x, yw + foot, 0 }, { x + wd, yw + foot, 0 }, { x + wd, yw + 0.02, z }, { x, yw + 0.02, z } }, sawn, light)
  end

  return {
    name = 'carpenter', w = 3, h = 2, height = 29,
    draw = function(c)
      local x0, y0, x1, y1, zw = 0.15, 0.2, 2.6, 1.8, 20
      local xs = 1.85                                          -- where the closed shop ends and the open bay begins
      -- the closed shop: plaster in a timber frame
      local shop = c:box(x0, y0, xs, y1, 0, zw, { wall = M.plaster, top = false })
      shop:frame('S', zw, 4, true); shop:frame('N', zw, 4, true); shop:frame('W', zw, 3, false); shop:frame('E', zw, 3, false)
      local ud = (1.5 - x0) / (xs - x0)
      shop:door('S', ud, 0.42, 13)
      shop:window('S', 0.3, 0.25, 8, 5, { shutters = true })
      shop:window('N', 0.5, 0.25, 8, 5, { shutters = true })
      shop:window('W', 0.5, 0.25, 8, 5, { shutters = true })
      -- tools hung on the shop's E wall, over the bench: a saw and a mallet
      shop:rect('E', 0.35, 0.55, 11, 14, P.iron); shop:rect('E', 0.55, 0.62, 11, 15, P.wood)
      shop:rect('E', 0.7, 0.76, 9, 14, P.wood); shop:rect('E', 0.66, 0.8, 14, 16, P.woodShade)
      -- the bay: plank back wall, corner posts at the open corner
      c:box(xs, y0, x1, y0 + 0.08, 0, zw, { wall = M.planks, top = false })
      c:part(x1 - 0.06, y1 - 0.06, x1, y1, 0, zw); c:post(x1 - 0.04, y1 - 0.03, 0, zw, P.beam)
      c:part(x1 - 0.06, y0 + 0.08, x1, y0 + 0.14, 0, zw); c:post(x1 - 0.04, y0 + 0.11, 0, zw, P.beam)
      -- boards leaning on the back wall
      c:part(1.95, y0 + 0.08, 2.5, y0 + 0.3, 0, 16)
      boardY(c, y0 + 0.08, 2.32, 0.15, 0.2, 14); boardY(c, y0 + 0.08, 2.14, 0.16, 0.18, 16)
      -- the workbench against the shop wall, a board and shavings on it
      local bx0, bx1, by0, by1 = xs + 0.02, xs + 0.3, 0.6, 1.5
      c:part(bx0, by0, bx1, by1, 0, 10)
      for _, p in ipairs({ { bx1 - 0.04, by1 - 0.04 }, { bx1 - 0.04, by0 + 0.04 }, { bx0 + 0.05, by1 - 0.04 } }) do c:post(p[1], p[2], 0, 6, P.woodShade) end
      slab(c, bx0, by0, bx1, by1, 6, 8, ink.plain(P.wood, P.woodShade))
      slab(c, bx0 + 0.06, by0 + 0.15, bx1 - 0.06, by1 - 0.25, 8, 9, pale)
      -- the sawhorse outside the bay with a log across it
      local hx = 2.8
      c:part(hx - 0.1, 0.6, hx + 0.1, 1.4, 0, 14)
      for _, y in ipairs({ 0.75, 1.25 }) do
        c:line3(hx - 0.08, y, 0, hx, y, 7, P.wood); c:line3(hx + 0.08, y, 0, hx, y, 7, P.woodShade)
      end
      slab(c, hx - 0.03, 0.7, hx + 0.03, 1.3, 7, 8, ink.plain(P.wood, P.woodShade))
      for k = 0, 22 do c:dot3(hx, 0.62 + 0.76 * k / 22, 11, 3, P.woodShade) end
      for k = 0, 22 do c:dot3(hx, 0.62 + 0.76 * k / 22, 12, 2, P.wood) end
      local ye = c:visible('S') and 1.38 or 0.62
      c:dot3(hx, ye, 11, 3, P.wattle); c:dot3(hx, ye, 11, 0, P.woodLine)
      -- boards leaning on the W wall outside
      c:part(0.0, 0.45, x0, 1.2, 0, 15)
      boardX(c, x0, -1, 0.5, 0.17, 0.13, 13); boardX(c, x0, -1, 0.72, 0.17, 0.12, 15); boardX(c, x0, -1, 0.95, 0.17, 0.13, 12)
      -- and on the S wall, between the window and the door
      c:part(0.88, y1, 1.24, 1.97, 0, 16)
      local function boardS(x, wd, foot, z)
        c:poly3({ { x, y1 + foot, 0 }, { x + wd, y1 + foot, 0 }, { x + wd, y1 + 0.02, z }, { x, y1 + 0.02, z } }, sawn, c:visible('S') or 'L')
      end
      boardS(0.9, 0.15, 0.15, 15); boardS(1.07, 0.15, 0.13, 13)
      -- shavings on the bay floor
      c:part(2.15, 0.7, 2.5, 1.6, 0, 0, { plain = true })
      for k = 0, 12 do c:dot3(2.18 + ink.hash(k, 3) * 0.3, 0.75 + ink.hash(k, 7) * 0.8, 0, 0, P.corn) end
      -- shingle roof over shop and bay, ridge along x, the E gable framed over the open bay on a tie beam
      local rise = 16
      local roof = c:gable(x0, 0.02, x1 + 0.04, 1.98, zw, rise, 'x', { roof = M.shingle, gable = M.plaster })
      for _, side in ipairs({ 'W', 'E' }) do
        roof:line(side, 0.5, 0, 0.5, rise, P.beam); roof:line(side, 0.06, 0, 0.94, 0, P.beam); roof:line(side, 0.06, 1, 0.94, 1, P.beam)
        roof:line(side, 0.5, 6, 0.28, 1, P.beam); roof:line(side, 0.5, 6, 0.72, 1, P.beam)
      end
    end,
  }
end
