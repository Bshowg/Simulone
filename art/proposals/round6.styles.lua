-- ══ Sepia ink line with realistic pastel washes: the colours things really have, thinned with water.
-- Clothes are plain: undyed wool and linen, or the soft plant dyes (madder, woad, weld). `full` covers the ground entirely.
local function pastel(id, full)
  local INK = '#4a382c'
  return { id = id, bg = PP, ink = INK, ink2 = '#6e5a4a', paper = finepaper, shadow = full and '#a9b48e' or '#c9c6a2',
    ground = function(k, px, py, x, y)
      if k == 'grass' then
        local r = hash(px * 3, py * 7)
        if r > 0.994 then return hex('#f3efe2') elseif r > 0.990 then return hex('#d9c98a') elseif r > 0.983 then return hex('#8f9f74') end
        local n = hash(px // 13, py // 7) + hash(px // 29 + 3, py // 15)
        if not full and n < 0.5 then return nil end
        return hex(n > 1.2 and '#b7c596' or '#c8d2a8')
      elseif k == 'road' then local f = y % 1; if (f < 0.08 or f > 0.92) and px % 4 < 2 then return hex(INK) end
        return hex(hash(px // 6, py // 3) > 0.7 and '#dfd2b4' or '#e8dcc0')
      elseif k == 'field' then local f = (y * 3) % 1; if f < 0.14 then return hex('#8a7450') end
        return hex((px % 3 == 0 and f > 0.5) and '#c9b06c' or (hash(px // 5, py // 3) > 0.55 and '#e8d8a2' or '#dfcb8c'))
      else
        if wave(px, py, 5, 4) then return hex(hash(px // 7, py) > 0.5 and '#6f8f9e' or '#eef0ea') end
        return hex(hash(px // 11, py // 4) > 0.5 and '#b6cfd6' or '#a6c2cc')
      end
    end,
    house = function(c, x0, y0, x1, y1, alongX)
      local fl, fr = faces(c, x0, y0, x1, y1); local h, rise = 13, 15
      walls(c, x0, y0, x1, y1, h, brick('#f0eadc', '#b3a892', 0.5, 6, 3), brick('#cfc8b8', '#8f8674', -0.5, 6, 3))
      rect(c, fl, 0.38, 0.62, 0, h * 0.78, stripe('#a58a6c', '#8f765a', 2)); rect(c, fr, 0.4, 0.6, h * 0.45, h * 0.8, flat('#5a4a40'))
      local a, b = hip(c, x0, y0, x1, y1, h, rise, alongX, strokes('#dccc9e', '#8a7450', 0.5, 3, 3, 0.4), strokes('#b9a67a', '#6a5638', -0.5, 3, 2, 0.4))
      c.line(a, b, hex(INK))
      local cx, cy = smoke(c, a, b, '#b4aca2')
      for dy = -5, 2 do for dx = -2, 1 do c.put(cx + dx, cy + dy, hex(dx < 0 and '#e2d8c8' or '#b8ac9a')) end end
    end,
    stoneL = brick('#f0eadc', '#b3a892', 0.5, 6, 3), stoneR = brick('#cfc8b8', '#8f8674', -0.5, 6, 3), stoneTop = flat('#f0eadc'), wellWater = flat('#8fb0bc'), post = INK, wellRoof = strokes('#dccc9e', '#8a7450', 0.5, 3, 3, 0.4),
    tree = function(c, bx, by, r)
      local ink = hex(INK)
      for i = 0, 14 do c.put(bx, by - i, ink) end
      for i = 0, 5 do c.put(bx - i, by - 9 - i, ink); c.put(bx + i, by - 8 - i, ink) end
      local q = math.max(4, math.floor(r * 0.5))
      for _, o in ipairs({ { -q, -14 }, { q, -13 }, { 0, -18 - q }, { -q - 2, -17 - q }, { q + 2, -16 - q }, { 0, -12 } }) do
        c.disc(bx + o[1], by + o[2] - 2, q, function(dx, dy)
          if dx * dx + dy * dy > (q - 1) * (q - 1) and dy >= dx then return ink end
          return hex(dx + dy > 1 and '#86a078' or '#b2c69a') end)
      end
    end,
    people = { { t = '#b98878' }, { t = '#93a6ba' }, { t = '#a08a6a' }, { t = '#cdbc80' }, { t = '#98a682' }, { t = '#d6cab2' } },
    body = { h = '#6a5040', f = '#e8cdb4', n = '#e8cdb4', b = INK, l = '#5a4a40', a = '#e8cdb4', i = '#8f765a', v = '#f0e8d6' } }
end
local S7, S8 = pastel('1-pastel-loose', false), pastel('2-pastel-full', true)

