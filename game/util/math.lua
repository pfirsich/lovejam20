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

return m