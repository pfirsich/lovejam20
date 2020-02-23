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

local function lineIntersectAxis(lineStart, lineEnd, rectMin, rectMax)
    local delta = lineEnd - lineStart
    if delta == 0 then
        return lineStart > rectMin and lineStart < rectMax, nil, nil
    end
    local t1 = (rectMin - lineStart) / delta
    local t2 = (rectMax - lineStart) / delta
    local tMin, tMax = math.min(t1, t2), math.max(t1, t2)
    if not m.intervalsOverlap(tMin, tMax, 0, 1) then
        return false, nil, nil
    end
    return true, tMin, tMax
end

function m.lineIntersectRect(lx1, ly1, lx2, ly2, rx, ry, rw, rh)
    -- TODO: handle dx, dy = 0
    local dx, dy = lx2 - lx1, ly2 - ly1

    local canIntersectX, tminX, tmaxX = lineIntersectAxis(lx1, lx2, rx, rx + rw)
    local canIntersectY, tminY, tmaxY = lineIntersectAxis(ly1, ly2, ry, ry + rh)

    if not canIntersectX or not canIntersectY then
        return false
    end

    if tminX == nil or tminY == nil or tminY == nil or tmaxY == nil then
        return true
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

function m.avg(...)
    local v = 0
    local n = select("#", ...)
    for i = 1, n do
        local _v = select(i, ...)
        v = v + _v
    end
    return v / n
end

function m.lerp(a, b, t)
    return a * (1 - t) + b * t
end

function m.randCircle(x, y, radius)
    while true do
        local cx = m.randf(-radius, radius)
        local cy = m.randf(-radius, radius)
        if cx*cx + cy*cy < radius*radius then
            return x + cx, y + cy
        end
    end
end

function m.circleInRect(cx, cy, radius, rx, ry, rw, rh)
    -- closest point to circle center inside rect
    local closestX = m.clamp(cx, rx, rx + rw)
    local closestY = m.clamp(cy, ry, ry + rh)
    local relX = closestX - cx
    local relY = closestY - cy
    return relX*relX + relY*relY < radius*radius
end

function m.pointInCircle(px, py, cx, cy, radius)
    local relX = px - cx
    local relY = py - cy
    return relX*relX + relY*relY < radius*radius
end

return m