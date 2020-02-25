local DirtFsm = require("dirtfsm")

local dirtgen = {}

local function generateSimplexLayer(tiles, layerIdx, layerGenParams)
    local baseScale = layerGenParams.params.scale or 1.0
    local octaves = layerGenParams.params.octaves or {1.0}
    local threshold = layerGenParams.params.threshold or 0.5
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
                tiles[y][x].layers[layerIdx] = {
                    fsm = DirtFsm(layerGenParams.dirtType),
                }
            end
        end
    end
end

function dirtgen.generate(layerData)
    local dirt = {
        tiles = {},
        numTilesX = math.floor(const.resX / const.dirtTileSize),
        numTilesY = math.floor(const.resY / const.dirtTileSize),
        layerData = layerData,
        layerCount = #layerData,
    }

    for y = 1, dirt.numTilesY do
        dirt.tiles[y] = {}
        for x = 1, dirt.numTilesX do
            dirt.tiles[y][x] = {
                layers = {},
            }
        end
    end

    for layerIdx, layerGenParams in ipairs(layerData) do
        -- last min hax
        local lgParams = {
            dirtType = layerGenParams[1],
            genType = "simplex",
            params = {
                scale = layerGenParams[2],
                octaves = layerGenParams[3],
                threshold = layerGenParams[4] or 0.5,
            },
        }
        if layerGenParams.genType == "simplex" then
            generateSimplexLayer(dirt.tiles, layerIdx, layerGenParams)
        end
    end

    return dirt
end

return dirtgen