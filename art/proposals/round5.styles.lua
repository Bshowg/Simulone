-- ══ Sepia wash with illuminated details: the drawing stays brown ink and brown wash; gold, lapis and vermilion are
-- kept for what a limner would pick out. `rich` also colours water, ripe corn and leaves.
local PP = '#eadfc6'
local GOLD, GOLD2, LAPIS, VERM, GREEN = '#d9a62e', '#f2cf5c', '#2f4f9a', '#b8382c', '#5f8a5a'
local function finepaper(x, y) if hash(x * 7, y * 13) > 0.994 then return hex('#c4ae8a') end; return (hash(x // 3, y // 2) + hash(x // 7 + 5, y // 5 + 3)) > 1.45 and hex('#e5d9bd') or hex(PP) end
local function sepia(id, rich)
  return { id = id, bg = PP, ink = '#3a2a20', ink2 = '#5a4634', paper = finepaper, shadow = '#cfbd96',
    ground = function(k, px, py, x, y)
      if k == 'grass' then
        local r = hash(px * 3, py * 7)
        if r > 0.9965 then return hex(VERM) elseif r > 0.993 then return hex(LAPIS) elseif r > 0.9895 then return hex(GOLD) elseif r > 0.982 then return hex('#5a4634') end
        if hash(px // 13, py // 7) + hash(px // 29 + 3, py // 15) > 0.85 then return hex(rich and '#d3d0a2' or '#ddcfac') end
      elseif k == 'road' then local f = y % 1; if (f < 0.08 or f > 0.92) and px % 4 < 2 then return hex('#3a2a20') end
      elseif k == 'field' then local f = (y * 3) % 1; if f < 0.14 then return hex('#3a2a20') end
        if rich then return hex((px + py // 2) % 3 == 0 and GOLD2 or GOLD) end
        if f > 0.55 and px % 3 == 0 then return hex(GOLD) end
        return hex(f < 0.5 and '#b89f72' or '#cdb88c')
      else
        if wave(px, py, 5, 4) then return hex(hash(px // 7, py) > 0.5 and (rich and '#eef0f4' or LAPIS) or PP) end
        return hex(rich and (hash(px // 9, py // 3) > 0.5 and '#3a5cae' or LAPIS) or '#a8926a')
      end
    end,
    house = function(c, x0, y0, x1, y1, alongX)
      local fl, fr = faces(c, x0, y0, x1, y1); local h, rise = 13, 15
      walls(c, x0, y0, x1, y1, h, brick('#f3ead4', '#8f7650', 0.5, 6, 3), brick('#c9b388', '#5a4634', -0.5, 6, 3))
      arch(c, fl, 0.5, 0.13, 0, 7, 3, flat(VERM)); arch(c, fl, 0.5, 0.06, 0, 6, 2, flat('#7a2018'))
      rect(c, fr, 0.4, 0.6, h * 0.45, h * 0.8, flat(LAPIS)); rect(c, fr, 0.49, 0.51, h * 0.45, h * 0.8, flat(GOLD))
      local a, b = hip(c, x0, y0, x1, y1, h, rise, alongX, strokes('#cdb88c', '#5a4634', 0.5, 3, 3, 0.4), strokes('#8f7650', '#3a2a20', -0.5, 3, 2, 0.4))
      c.line(a, b, hex(GOLD)); c.line({ a[1], a[2] - 1 }, { b[1], b[2] - 1 }, hex(GOLD2)); finial(c, a, GOLD); finial(c, b, GOLD)
      smoke(c, a, b, '#a8926a')
    end,
    stoneL = brick('#f3ead4', '#8f7650', 0.5, 6, 3), stoneR = brick('#c9b388', '#5a4634', -0.5, 6, 3), stoneTop = flat('#f3ead4'), wellWater = flat(LAPIS), post = '#3a2a20', wellRoof = scale(VERM, '#7a2018', 0.5),
    tree = function(c, bx, by, r)
      local ink = hex('#3a2a20')
      for i = 0, 14 do c.put(bx, by - i, ink) end
      for i = 0, 5 do c.put(bx - i, by - 9 - i, ink); c.put(bx + i, by - 8 - i, ink) end
      local q = math.max(4, math.floor(r * 0.5))
      for n, o in ipairs({ { -q, -14 }, { q, -13 }, { 0, -18 - q }, { -q - 2, -17 - q }, { q + 2, -16 - q }, { 0, -12 } }) do
        c.disc(bx + o[1], by + o[2] - 2, q, function(dx, dy)
          if dx * dx + dy * dy > (q - 1) * (q - 1) and dy >= dx then return ink end
          if (dx == -1 and dy == -1 and n % 2 == 0) or (dx == 1 and dy == 1 and n % 3 == 0) then return hex(n % 2 == 0 and GOLD or VERM) end
          if rich then return hex(dx + dy > 1 and '#4f7550' or '#8fae78') end
          return hex(dx + dy > 1 and '#8f7650' or '#cdb88c') end)
      end
    end,
    people = { { t = VERM, p = GOLD }, { t = LAPIS, p = LAPIS }, { t = '#5a4634', p = GOLD } },
    body = { h = '#3a2a20', f = '#eadfc6', n = '#3a2a20', b = '#3a2a20', l = '#3a2a20', a = '#3a2a20', i = GOLD } }
end
local S5, S6 = sepia('1-sepia-touches', false), sepia('2-sepia-rich', true)

