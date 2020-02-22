local m = {}

function m.round(v)
    return math.floor(v + 0.5)
end

function m.clamp(v, lo, hi)
    return math.min(math.max(v, lo or 0), hi or 1)
end

function m.length(x, y)
    return math.sqrt(x*x + y*y)
end

function m.normalize(x, y)
    local l = m.length(x, y)
    return x / l, y / l
end

function m.inRect(x, y, rx, ry, rw, rh)
    return x > rx and x < rx + rw and y > ry and y < ry + rh
end

function m.intervalsOverlap(x1, x2, y1, y2)
    return x1 <= y2 and y1 <= x2
end

function m.lineIntersectRect(lx1, ly1, lx2, ly2, rx, ry, rw, rh)
    -- TODO: handle dx, dy = 0
    local dx, dy = lx2 - lx1, ly2 - ly1
    local tX1 = (rx - lx1) / dx
    local tX2 = (rx + rw - lx1) / dx
    local tminX, tmaxX = math.min(tX1, tX2), math.max(tX1, tX2)
    if not m.intervalsOverlap(tminX, tmaxX, 0, 1) then
        return false
    end

    local tY1 = (ry - ly1) / dy
    local tY2 = (ry + rh - ly1) / dy
    local tminY, tmaxY = math.min(tY1, tY2), math.max(tY1, tY2)
    if not m.intervalsOverlap(tminY, tmaxY, 0, 1) then
        return false
    end

    return m.intervalsOverlap(tminX, tmaxX, tminY, tmaxY)
end

function m.randf(min, max)
    min = min or 0
    max = max or 1
    return min + love.math.random() * (max - min)
end

function m.randDeviate(base, deviation)
    return m.randf(base - deviation, base + deviation)
end

return m