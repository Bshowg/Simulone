-- Mill, 3 x 3. A round rubble-stone tower mill with a conical boarded cap, four cloth sails on a cross turned to the S
-- (a flat cross in the x-z plane, so it shows in every rotation: in front in rotations 0 and 3, behind the tower in 1 and
-- 2), a tail pole running down the N side to wind the cap, and sacks of flour by the plank door in the S.
return function(ink)
  local M, P, pat = ink.M, ink.P, ink.pat
  local capMat = { lit = function() return pat.brick(P.shingle, P.shingleLine, 0, 4, 3) end,
                   shade = function() return pat.brick(P.shingleShade, P.shingleShadeLine, 0, 4, 3) end }
  local cloth = ink.plain(P.veil, P.linen)
  local sackLit, sackShade = P.linen, P.wattleShade

  local CX, CY, R = 1.5, 1.45, 0.68       -- the tower
  local TOP = 40                            -- top of the tower wall
  local RC = 0.84                           -- the cap's radius

  -- a flat rectangle lying on the tower's round face, facing `side`: hw is its half width (cells) along the face
  local function onTower(c, side, off, hw, z0, z1, fill)
    local ss = c:visible(side); if not ss then return end
    local e = 0.01
    local pts
    if side == 'S' then local y = CY + R + e; c:part(CX + off - hw, y, CX + off + hw, y + 0.01, z0, z1)
      pts = { { CX + off - hw, y, z0 }, { CX + off + hw, y, z0 }, { CX + off + hw, y, z1 }, { CX + off - hw, y, z1 } }
    elseif side == 'N' then local y = CY - R - e; c:part(CX + off - hw, y - 0.01, CX + off + hw, y, z0, z1)
      pts = { { CX + off - hw, y, z0 }, { CX + off + hw, y, z0 }, { CX + off + hw, y, z1 }, { CX + off - hw, y, z1 } }
    elseif side == 'E' then local x = CX + R + e; c:part(x, CY + off - hw, x + 0.01, CY + off + hw, z0, z1)
      pts = { { x, CY + off - hw, z0 }, { x, CY + off + hw, z0 }, { x, CY + off + hw, z1 }, { x, CY + off - hw, z1 } }
    else local x = CX - R - e; c:part(x - 0.01, CY + off - hw, x, CY + off + hw, z0, z1)
      pts = { { x, CY + off - hw, z0 }, { x, CY + off + hw, z0 }, { x, CY + off + hw, z1 }, { x, CY + off - hw, z1 } }
    end
    c:poly3(pts, fill, ss)
    return pts
  end

  -- a sack of flour standing on the ground: a soft block with its neck tied off
  local sackMat = ink.plain(sackLit, sackShade)
  local function sack(c, x, y, tall)
    tall = tall or 5
    local s = 0.1
    c:box(x - s, y - s, x + s, y + s, 0, tall, { wall = sackMat })
    c:part(x - 0.06, y - 0.06, x + 0.06, y + 0.06, tall, tall + 3)
    c:dot3(x, y, tall + 1, 2, sackLit)
    c:line3(x, y, tall + 1, x, y, tall + 1, P.wattleLine)
  end

  -- a course line drawn round the front of the tower at height z (added to the tower's own part)
  local function course(c, z, col)
    c:_op(function()
      local b = c:pt(CX, CY, z)
      local rx, ry = R * 16 * 1.4142, R * 8 * 1.4142
      for dx = -math.floor(rx) + 1, math.floor(rx) - 1 do
        local e = math.sqrt(math.max(0, 1 - (dx / rx) ^ 2)) * ry
        c:_put(b[1] + dx, b[2] + e, ink.hex(col))
      end
    end)
  end

  -- four sails on a cross centred at (hx, hy, hz) in the plane y = hy; len and wid in cells (z counts 16 px a cell)
  local function sails(c, hx, hy, hz, len, wid)
    local reach = math.sqrt(len * len + wid * wid) + 0.03
    c:part(hx - reach, hy, hx + reach, hy + 0.04, hz - reach * 16, hz + reach * 16)
    local light = c:visible('S') or c:visible('N')
    local function p3(u, v) return { hx + u, hy, hz + v * 16 } end
    for q = 0, 3 do
      local a = 0.18 + q * math.pi / 2
      local dx, dy = math.cos(a), math.sin(a)
      local px, py = -dy, dx
      local r0, r1 = 0.22, len
      c:poly3({ p3(dx * r0, dy * r0), p3(dx * r1, dy * r1), p3(dx * r1 + px * wid, dy * r1 + py * wid), p3(dx * r0 + px * wid, dy * r0 + py * wid) }, cloth, light)
      for t = 1, 4 do
        local r = r0 + (r1 - r0) * t / 5
        local a1, b1 = p3(dx * r, dy * r), p3(dx * r + px * wid, dy * r + py * wid)
        c:line3(a1[1], a1[2], a1[3], b1[1], b1[2], b1[3], P.wattleLine)
      end
      local a2, b2 = p3(dx * (r0 + 0.02) + px * wid * 0.5, dy * (r0 + 0.02) + py * wid * 0.5), p3(dx * r1 + px * wid * 0.5, dy * r1 + py * wid * 0.5)
      c:line3(a2[1], a2[2], a2[3], b2[1], b2[2], b2[3], P.wattleLine)
      local tip = p3(dx * (r1 + 0.04), dy * (r1 + 0.04))
      c:line3(hx, hy, hz, tip[1], tip[2], tip[3], P.ink)
    end
    c:dot3(hx, hy, hz, 2, P.wood)
  end

  return {
    name = 'mill', w = 3, h = 3, height = 74,
    draw = function(c)
      -- tail pole first: it runs from the back of the cap down to the ground on the N
      c:part(1.4, 0.08, 1.6, CY - RC + 0.02, 0, TOP + 5)
      for k = 0, 3 do c:line3(1.5, 0.16, 6 + k, 1.5, CY - RC + 0.02, TOP + 2 + k, k == 3 and P.woodShade or P.wood) end
      c:post(1.47, 0.14, 0, 9, P.wood, 2)

      c:cyl(CX, CY, R, 0, TOP, M.stone)
      course(c, 5, P.stoneShadeLine); course(c, 6, P.stoneShadeLine); course(c, TOP - 3, P.stoneShadeLine)
      -- door in the S (entrance cell x = 1..2), windows on every side
      onTower(c, 'S', 0, 0.2, 0, 13, M.planks)
      onTower(c, 'S', 0, 0.07, 24, 29, P.dark)
      onTower(c, 'E', -0.1, 0.07, 16, 21, P.dark)
      onTower(c, 'E', 0.1, 0.07, 33, 38, P.dark)
      onTower(c, 'W', 0.05, 0.07, 30, 35, P.dark)
      onTower(c, 'N', 0, 0.07, 20, 25, P.dark)

      c:cone(CX, CY, RC, TOP, 15, capMat)
      -- the windshaft sticks out of the cap to the S and carries the sails
      c:part(CX - 0.05, CY + RC - 0.1, CX + 0.05, CY + RC + 0.12, TOP + 6, TOP + 11)
      c:line3(CX, CY + RC - 0.08, TOP + 8, CX, CY + RC + 0.12, TOP + 8, P.wood)
      c:line3(CX, CY + RC - 0.08, TOP + 9, CX, CY + RC + 0.12, TOP + 9, P.wood)
      sails(c, CX, CY + RC + 0.13, TOP + 8, 1.45, 0.36)

      -- sacks of flour by the door
      sack(c, 1.95, 2.3); sack(c, 2.2, 2.35, 4); sack(c, 2.05, 2.58, 4)
      sack(c, 0.95, 2.35)
      -- a spare millstone lying on the ground to the E
      c:cyl(2.55, 1.75, 0.22, 0, 3, M.stone, P.stoneShade)
      c:dot3(2.55, 1.75, 3, 1, P.dark)
    end,
  }
end
