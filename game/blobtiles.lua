local bit = require("bit")

local blobtiles = {}

-- as in the tilesetter blob tiles output
local masks = {
    208, 248, 104,    64,    80, 120, 216,  72,  88, 219, nil,
    214, 255, 107,    66,    86, 127, 223,  75,  95, 126, nil,
     22,  31,  11,     2,   210, 251, 254, 106, 250, 218, 122,
     16,  24,   8,     0,    18,  27,  30,  10,  26,  94,  92,
    nil, nil, nil,   nil,    82, 123, 222,  74,  90,
}
local maxMaskIndex = 47 + 6 -- 6 nils
local masksCountX = 11
local masksCountY = math.ceil(maxMaskIndex / masksCountX)

local quads = {}

function blobtiles.init(tileSize)
    for i = 1, maxMaskIndex do
        local mask = masks[i]
        if mask then
            local ix = (i - 1) % masksCountX
            local iy = math.floor((i - 1) / masksCountX)
            quads[mask] = love.graphics.newQuad(
                ix * tileSize, iy * tileSize,
                tileSize, tileSize,
                masksCountX * tileSize, masksCountY * tileSize)
        end
    end
end

local topLeft = 1
local top = 2
local topRight = 4
local left = 8
local right = 16
local bottomLeft = 32
local bottom = 64
local bottomRight = 128
local all = 255

function blobtiles.getQuad(mask)
    -- This is just some shit I threw at the wall
    -- I don't actually know if that's the right algorithm, but it looks fine
    if quads[mask] == nil then
        -- remove all corners that are missing an edge
        if bit.band(mask, top + left) ~= top + left then
            mask = bit.band(mask, all - topLeft)
        end
        if bit.band(mask, top + right) ~= top + right then
            mask = bit.band(mask, all - topRight)
        end
        if bit.band(mask, bottom + left) ~= bottom + left then
            mask = bit.band(mask, all - bottomLeft)
        end
        if bit.band(mask, bottom + right) ~= bottom + right then
            mask = bit.band(mask, all - bottomRight)
        end
    end
    -- this is a failsafe, so the assert doesn't actually fire.
    if quads[mask] == nil then
        -- remove all corners
        mask = bit.band(mask, top + left + right + bottom)
    end
    assert(quads[mask], "Could not find Quad?! - " .. tostring(mask))
    return quads[mask]
end

return blobtiles