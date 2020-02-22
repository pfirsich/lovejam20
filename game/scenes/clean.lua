local dirtgen = require("dirtgen")
local FreqMeasure = require("freqmeasure")

local scene = {}

local tools = {
    sponge = {
        image = "handSponge",
    },
    cloth = {
        image = "handCloth",
    }
}
local currentTool = "sponge"

local dirt = nil

local lastMouseX, lastMouseY = 0, 0
local mouseVelX, mouseVelY = 0, 0

local mouseHistory = {}

local totalScrubFreqMeas = FreqMeasure(const.scrubHistoryLen, const.scrubSampleNum)

local tileMaskShader = lg.newShader([[
uniform Image mask;
uniform vec4 maskRegion;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    float maskValue = Texel(mask, maskRegion.xy + texture_coords * maskRegion.zw).r;
    return texturecolor * color * maskValue;
}
]])

function scene.enter()
    dirt = dirtgen.generate {
        {dirtType = "goo", genType = "simplex", params = {
            scale = 2.0,
            octaves = {1.0, 0.5, 0.3},
            threshold = 0.8,
        }},
        {dirtType = "specks", genType = "simplex", params = {
            scale = 3.0,
            octaves = {1.0},
            threshold = 0.8,
        }},
    }
    for y = 1, #dirt.tiles do
        for x = 1, #dirt.tiles[y] do
            dirt.tiles[y][x].scrubFreqMeas = FreqMeasure(const.scrubHistoryLen, const.scrubSampleNum)
            dirt.tiles[y][x].lastMouseInRect = false
        end
    end
end

-- return true if scrub in place
local function updateMouseHistory(mx, my)
    table.insert(mouseHistory, {x = mx , y = my})
    if #mouseHistory > math.floor(const.mouseHistoryLen / const.simDt) then
        table.remove(mouseHistory, 1)
    end
    if #mouseHistory > 3 then
        local mouseVelHistory = {}
        for i = 2, #mouseHistory do
            table.insert(mouseVelHistory, {
                x = mouseHistory[i].x - mouseHistory[i-1].x,
                y = mouseHistory[i].y - mouseHistory[i-1].y,
            })
        end
        local lastVel = mouseVelHistory[#mouseVelHistory]
        local foundAScrub = false
        for i = 1, #mouseVelHistory - 1 do
            local dot = mouseVelHistory[i].x * lastVel.x + mouseVelHistory[i].y * lastVel.y
            if dot < 0.0 then
                foundAScrub = true
                break
            end
        end
        if foundAScrub then
            -- truncate the mouse history and leave the last velocity (last two positions!)
            mouseHistory = {
                mouseHistory[#mouseHistory - 1],
                mouseHistory[#mouseHistory]
            }
            return true
        end
    end
    return false
end

local function count(list)
    local n = 0
    for i = 1, #list do
        n = n + (list[i] and 1 or 0)
    end
    return n
end

local function pickTopLayer(x, y)
    local tile = dirt.tiles[y][x]
    for l = dirt.layerCount, 1, -1 do
        if tile.layers[l] ~= nil then
            return l, tile.layers[l]
        end
    end
    return nil, nil
end

local function scrub()
    local mx, my = util.gfx.getMouse(const.resX, const.resY)
    local lastMouse = mouseHistory[#mouseHistory] or {x = mx, y = my}
    local scrubInPlace = updateMouseHistory(mx, my)
    if scrubInPlace then
        assets.scrub:play():setPitch(util.math.randDeviate(1.0, 0.05))
        totalScrubFreqMeas:event(scene.simTime)
    end

    for y = 1, #dirt.tiles do
        for x = 1, #dirt.tiles[y] do
            local tile = dirt.tiles[y][x]
            local tileSize = const.dirtTileSize
            local tx, ty = (x - 1) * tileSize, (y - 1) * tileSize
            local inRect = util.math.lineIntersectRect(
                lastMouse.x, lastMouse.y, mx, my,
                tx, ty, tileSize, tileSize)
            local tileScrubbed = inRect and (not tile.lastMouseInRect or scrubInPlace)
            if tileScrubbed then
                tile.scrubFreqMeas:event(scene.simTime)

                local layerIdx, topLayer = pickTopLayer(x, y)
                if topLayer and topLayer.fsm:scrub(currentTool, tile.scrubFreqMeas:get(scene.simTime)) then
                    -- state changed
                    if topLayer.fsm.state == "clean" then
                        -- remove the layer
                        tile.layers[layerIdx] = nil
                    end
                end
            end
            tile.lastMouseInRect = inRect
        end
    end
end

function scene.tick()
    if love.mouse.isDown(1) then
        scrub()
    end

    for y = 1, #dirt.tiles do
        for x = 1, #dirt.tiles[y] do
            local tile = dirt.tiles[y][x]
            tile.scrubFreqMeas:truncate(scene.simTime)
        end
    end

    totalScrubFreqMeas:truncate(scene.simTime)
end

function scene.keypressed(key)
    if key == "r" then
        currentTool = "sponge"
    elseif key == "e" then
        currentTool = "cloth"
    end
end



local tileOffsets = {
    {-1, -1}, {0, -1}, {1, -1},
    {-1,  0},          {1,  0},
    {-1,  1}, {0,  1}, {1,  1},
}
local function getNeighbourHoodBitmask(x, y, layer)
    local n = 1
    local mask = 0
    for _, offset in ipairs(tileOffsets) do
        local tx = x + offset[1]
        local ty = y + offset[2]
        if dirt.tiles[ty] and dirt.tiles[ty][tx]
                and dirt.tiles[ty][tx].layers[layer] then
            mask = mask + n
        end
        n = n * 2
    end
    return mask
end

function scene.draw(dt)
    util.gfx.pixelCanvas(const.resX, const.resY, {0.1, 0.1, 0.1}, function(dt)
        for y = 1, #dirt.tiles do
            for x = 1, #dirt.tiles[y] do
                local tile = dirt.tiles[y][x]
                local tileSize = const.dirtTileSize
                local tx, ty = (x - 1) * tileSize, (y - 1) * tileSize

                lg.setShader(tileMaskShader)
                for layerIdx = 1, dirt.layerCount do
                    local dirtType = dirt.layerData[layerIdx].dirtType

                    if tile.layers[layerIdx] then
                        local bitmask = getNeighbourHoodBitmask(x, y, layerIdx)
                        local transitionTileX = bitmask % 16
                        local transitionTileY = math.floor(bitmask / 16)
                        local uvOffset = {
                            transitionTileX / 16,
                            transitionTileY / 16,
                        }
                        local uvScale = {
                            assets[dirtType]:getWidth() / assets.transitions:getWidth(),
                            assets[dirtType]:getHeight() / assets.transitions:getHeight(),
                        }

                        tileMaskShader:send("mask", assets.transitions)
                        tileMaskShader:send("maskRegion", {
                            uvOffset[1], uvOffset[2],
                            uvScale[1], uvScale[2]
                        })
                        lg.setColor(tile.layers[layerIdx].fsm:getColor())
                        lg.draw(assets[dirtType], tx, ty)
                    end
                end

                lg.setShader()
                lg.setColor(0, 0, 1)
                local recentlyScrubbed = #tile.scrubFreqMeas > 0
                    and tile.scrubFreqMeas.samples[1] > scene.simTime - 0.1
                if recentlyScrubbed then
                    lg.setColor(1, 0, 0)
                end
                lg.rectangle("line", tx, ty, tileSize, tileSize)
                local text = ("%.2f"):format(tile.scrubFreqMeas:get(scene.simTime))
                local layerIdx, topLayer = pickTopLayer(x, y)
                if topLayer then
                    local dirtType = dirt.layerData[layerIdx].dirtType
                    text = text .. ("\n%s\n%s\n%s"):format(
                        dirtType,
                        topLayer.fsm.state,
                        finspect(topLayer.fsm.progress))
                end
                lg.print(text, tx + 2, ty + 2)
            end
        end

        lg.setColor(0, 1, 0)
        local points = {}
        for _, mousePos in ipairs(mouseHistory) do
            table.insert(points, mousePos.x)
            table.insert(points, mousePos.y)
        end
        if #points > 2 then
            lg.line(points)
        end

        lg.setColor(1, 1, 1)
        local mx, my = util.gfx.getMouse(const.resX, const.resY)
        local tool = tools[currentTool]
        local image = assets[tool.image]
        local imgW, imgH = image:getDimensions()
        lg.draw(image, mx, my, 0, 1, 1, imgW/2, imgH/2)

        local scrubFreq = totalScrubFreqMeas:get(scene.simTime)

        local gaugeX = mx + const.gaugeOffset[1]
        local gaugeY = my + const.gaugeOffset[2]
        local scrubAmount = util.math.clamp(scrubFreq / 9.0)
        local gaugeImg = "gaugeFast"
        if scrubAmount < 0.05 then
            gaugeImg = "gaugeEmpty"
        elseif scrubAmount < 0.33333 then
            gaugeImg = "gaugeSlow"
        elseif scrubAmount < 0.6666 then
            gaugeImg = "gaugeMed"
        end
        lg.setColor(1, 1, 1)
        lg.draw(assets[gaugeImg], gaugeX, gaugeY)

        lg.setColor(1, 1, 1)
        lg.print(("Scrub Frequency: %.1f Hz"):format(scrubFreq), 5, const.resY - 15)
    end)
end

return scene