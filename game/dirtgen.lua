local dirtgen = {}

local function generateSimplexLayer(tiles, layer)
    local baseScale = layer.params.scale or 1.0
    local octaves = layer.params.octaves or {1.0}
    local threshold = layer.params.threshold or 0.5
    local offX, offY = lm.random(), lm.random()
    for y = 1, #tiles do
        for x = 1, #tiles[y] do
            local value = 0.0
            local scale = baseScale / #tiles
            for _, octave in ipairs(octaves) do
                value = value + lm.noise(x * scale + offX, y * scale + offY) * octave
                scale = scale / 2.0
            end
            if value > threshold then
                table.insert(tiles[y][x].dirtTypes, layer.dirtType)
            end
        end
    end
end

function dirtgen.generate(layers)
    local dirtTiles = {}
    local numTilesX = math.floor(const.resX / const.dirtTileSize)
    local numTilesY = math.floor(const.resY / const.dirtTileSize)

    for y = 1, numTilesY do
        dirtTiles[y] = {}
        for x = 1, numTilesX do
            dirtTiles[y][x] = {
                dirtTypes = {},
                objects = {},
            }
        end
    end

    for _, layer in ipairs(layers) do
        if layer.type == "dirt" then
            if layer.genType == "simplex" then
                generateSimplexLayer(dirtTiles, layer)
            end
        elseif layer.type == "object" then
            if layer.genType == "uniform" then
                generateUniformObjects(dirtTiles, layer)
            end
        end
    end

    return dirtTiles
end

return dirtgen