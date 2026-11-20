-- Village green, 4 x 4. Open trodden ground where the people gather (left empty: the game draws the ground and the
-- people). A big old oak near the N corner with a plank bench round its trunk, a stone cross on a stepped base at the
-- E corner, and two stumps to sit on. Most of the cells stay free.
return function(ink)
  local M, P = ink.M, ink.P
  local bark = ink.plain(P.wood, P.woodShade)

  -- model offset (dx, dy) that moves a point sx pixels right and sy pixels down on screen, in this rotation
  local function screenStep(c, sx, sy)
    local vx, vy = sx / 32 + sy / 16, -sx / 32 + sy / 16
    local r = c.rot
    if r == 0 then return vx, vy elseif r == 1 then return vy, -vx elseif r == 2 then return -vx, -vy else return -vy, vx end
  end

  -- an oak at (cx, cy): a stout trunk with limbs, a crown of leafy clumps, each with an inked lower edge, lit from the left
  local function oak(c, cx, cy, trunkTop)
    c:cyl(cx, cy, 0.16, 0, trunkTop, bark)
    -- limbs reaching into the crown
    c:part(cx - 0.6, cy - 0.6, cx + 0.6, cy + 0.6, trunkTop - 6, trunkTop + 6)
    for _, l in ipairs({ { -0.55, 0.05 }, { 0.5, -0.1 }, { 0.05, 0.55 }, { -0.05, -0.55 } }) do
      c:line3(cx, cy, trunkTop - 6, cx + l[1], cy + l[2], trunkTop + 5, P.woodShade)
      c:line3(cx + 0.02, cy, trunkTop - 6, cx + l[1] + 0.02, cy + l[2], trunkTop + 5, P.wood)
    end
    -- the crown: clumps on a low dome
    -- a broad, spreading crown wider than it is tall: an outer ring of low clumps, a middle ring, a top
    local crown = { { 0, 0, 21, 8 } }
    for k = 0, 10 do local a = k * math.pi * 2 / 11 + 0.3; local rr = 0.95 + 0.12 * ink.hash(k, 1)
      crown[#crown + 1] = { math.cos(a) * rr, math.sin(a) * rr, 6 + (k % 3) * 3, 6 + (k % 2) } end
    for k = 0, 5 do local a = k * math.pi / 3 + 0.8
      crown[#crown + 1] = { math.cos(a) * 0.55, math.sin(a) * 0.55, 14 + (k % 2) * 4, 7 } end
    c:part(cx - 1.2, cy - 1.2, cx + 1.2, cy + 1.2, trunkTop + 6, trunkTop + 32)
    table.sort(crown, function(p, q)                           -- far clumps first, near and high ones last
      local pa, pb = c:view(cx + p[1], cy + p[2]); local qa, qb = c:view(cx + q[1], cy + q[2])
      return (pa + pb) * 8 + p[3] < (qa + qb) * 8 + q[3]
    end)
    local z0 = trunkTop + 6
    for _, q in ipairs(crown) do
      local x, y, z, r = cx + q[1], cy + q[2], z0 + q[3], q[4]
      local ax, ay = screenStep(c, 1, 1)
      c:dot3(x + ax, y + ay, z, r + 1, P.ink)                  -- inked edge that parts it from the clump behind
      c:dot3(x, y, z, r, P.leafShade)
      local bx, by = screenStep(c, -1, 0)
      c:dot3(x + bx, y + by, z + 1, r - 2, P.leaf)             -- the lit upper left
      local dx, dy = screenStep(c, -2, 0)
      c:dot3(x + dx, y + dy, z + 2, 0, P.leafShade); c:dot3(x - dx, y - dy, z + 3, 0, P.leafShade)
    end
  end

  return {
    name = 'green', w = 4, h = 4, height = 39,
    draw = function(c)
      local cx, cy = 1.3, 1.3
      -- the bench round the trunk: four plank seats on short legs, in a pinwheel so they do not overlap
      local a, b, zs = 0.42, 0.27, 5
      local seat = { wall = ink.plain(P.wood, P.woodShade), top = ink.pat.planks(P.wood, P.woodLine, 3) }
      local seats = { { cx - a, cy - a, cx + b, cy - b }, { cx + b, cy - a, cx + a, cy + b }, { cx - b, cy + b, cx + a, cy + a }, { cx - a, cy - b, cx - b, cy + a } }
      for _, s in ipairs(seats) do
        c:part(s[1], s[2], s[3], s[4], 0, zs - 2)
        for _, p in ipairs({ { s[1] + 0.03, s[2] + 0.03 }, { s[3] - 0.04, s[2] + 0.03 }, { s[1] + 0.03, s[4] - 0.03 }, { s[3] - 0.04, s[4] - 0.03 } }) do
          c:post(p[1], p[2], 0, zs - 2, P.woodShade, 1)
        end
        c:box(s[1], s[2], s[3], s[4], zs - 2, zs, seat)
      end
      oak(c, cx, cy, 20)
      -- the stone cross on two steps
      local kx, ky = 3.25, 0.8
      c:box(kx - 0.2, ky - 0.2, kx + 0.2, ky + 0.2, 0, 3, { wall = M.stone })
      c:box(kx - 0.12, ky - 0.12, kx + 0.12, ky + 0.12, 3, 6, { wall = M.stone })
      c:box(kx - 0.06, ky - 0.06, kx + 0.06, ky + 0.06, 6, 25, { wall = ink.plain(P.stone, P.stoneShade) })
      c:box(kx - 0.21, ky - 0.05, kx - 0.06, ky + 0.05, 16, 20, { wall = ink.plain(P.stone, P.stoneShade) })
      c:box(kx + 0.06, ky - 0.05, kx + 0.21, ky + 0.05, 16, 20, { wall = ink.plain(P.stone, P.stoneShade) })
      -- stumps to sit on
      c:cyl(2.35, 0.4, 0.12, 0, 5, bark, ink.plain(P.wattle))
      c:cyl(0.5, 2.9, 0.13, 0, 5, bark, ink.plain(P.wattle))
      c:cyl(1.35, 3.2, 0.1, 0, 4, bark, ink.plain(P.wattle))
    end,
  }
end
