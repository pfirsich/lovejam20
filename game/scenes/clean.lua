local dirtgen = require("dirtgen")
local DirtFsm = require("dirtfsm")
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

local dirtTiles = nil

local lastMouseX, lastMouseY = 0, 0
local mouseVelX, mouseVelY = 0, 0

local mouseHistory = {}

local totalScrubFreqMeas = FreqMeasure(const.scrubHistoryLen, const.scrubSampleNum)

function scene.enter()
    dirtTiles = dirtgen.generate {
        {type = "dirt", dirtType = "goo", genType = "simplex", params = {
            scale = 2.0,
            octaves = {1.0, 0.5, 0.3},
            threshold = 0.8,
        }},
        {type = "dirt", dirtType = "specks", genType = "simplex", params = {
            scale = 3.0,
            octaves = {1.0},
            threshold = 0.8,
        }},
    }
    for y = 1, #dirtTiles do
        for x = 1, #dirtTiles[y] do
            dirtTiles[y][x].scrubFreqMeas = FreqMeasure(const.scrubHistoryLen, const.scrubSampleNum)
            dirtTiles[y][x].lastMouseInRect = false
            if #dirtTiles[y][x].dirtTypes > 0 then
                dirtTiles[y][x].dirtFsm = DirtFsm(
                    dirtTiles[y][x].dirtTypes[#dirtTiles[y][x].dirtTypes])
            end
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

local function scrub()
    local mx, my = util.gfx.getMouse(const.resX, const.resY)
    local lastMouse = mouseHistory[#mouseHistory] or {x = mx, y = my}
    local scrubInPlace = updateMouseHistory(mx, my)
    if scrubInPlace then
        assets.scrub:play():setPitch(util.math.randDeviate(1.0, 0.05))
        totalScrubFreqMeas:event(scene.simTime)
    end

    for y = 1, #dirtTiles do
        for x = 1, #dirtTiles[y] do
            local tile = dirtTiles[y][x]
            local tileSize = const.dirtTileSize
            local tx, ty = (x - 1) * tileSize, (y - 1) * tileSize
            local inRect = util.math.lineIntersectRect(
                lastMouse.x, lastMouse.y, mx, my,
                tx, ty, tileSize, tileSize)
            local tileScrubbed = inRect and (not tile.lastMouseInRect or scrubInPlace)
            if tileScrubbed and tile.dirtFsm then
                tile.scrubFreqMeas:event(scene.simTime)

                if tile.dirtFsm:scrub(currentTool, tile.scrubFreqMeas:get(scene.simTime)) then
                    -- state changed
                    if tile.dirtFsm.state == "clean" then
                        table.remove(tile.dirtTypes)
                        if #tile.dirtTypes > 0 then
                            tile.dirtFsm = DirtFsm(tile.dirtTypes[#tile.dirtTypes])
                        else
                            -- squeaky clean
                            tile.dirtFsm = nil
                        end
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

    for y = 1, #dirtTiles do
        for x = 1, #dirtTiles[y] do
            local tile = dirtTiles[y][x]
            if tile.dirtFsm then
                tile.dirtFsm:update(const.simDt)
            end
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

function scene.draw(dt)
    util.gfx.pixelCanvas(const.resX, const.resY, {0.1, 0.1, 0.1}, function(dt)
        for y = 1, #dirtTiles do
            for x = 1, #dirtTiles[y] do
                local tile = dirtTiles[y][x]
                local tileSize = const.dirtTileSize
                local tx, ty = (x - 1) * tileSize, (y - 1) * tileSize

                for _, dirtType in ipairs(tile.dirtTypes) do
                    lg.setColor(tile.dirtFsm:getColor())
                    lg.draw(assets[dirtType], tx, ty)
                end

                lg.setColor(0, 0, 1)
                local recentlyScrubbed = #tile.scrubFreqMeas > 0
                    and tile.scrubFreqMeas.samples[1] > scene.simTime - 0.1
                if recentlyScrubbed then
                    lg.setColor(1, 0, 0)
                end
                lg.rectangle("line", tx, ty, tileSize, tileSize)
                local text = ("%.2f"):format(tile.scrubFreqMeas:get(scene.simTime))
                if #tile.dirtTypes > 0 then
                    text = text .. ("\n%s\n%s\n%s"):format(
                        tile.dirtTypes[#tile.dirtTypes],
                        tile.dirtFsm.state,
                        finspect(tile.dirtFsm.progress))
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

        local gaugeX = mx + const.gaugeOffset[1] - const.gaugeWidth / 2
        local gaugeY = my + const.gaugeOffset[2]
        lg.setColor(0, 0, 0)
        lg.rectangle("fill", gaugeX, gaugeY, const.gaugeWidth, const.gaugeHeight)
        local scrubAmount = util.math.clamp(scrubFreq / 9.0)
        if scrubAmount < 0.33333 then
            lg.setColor(0, 1, 0)
        elseif scrubAmount < 0.6666 then
            lg.setColor(1, 1, 0)
        else
            lg.setColor(1, 0, 0)
        end
        lg.rectangle("fill", gaugeX, gaugeY,
            math.floor(const.gaugeWidth * scrubAmount),
            math.floor(const.gaugeHeight))
        lg.rectangle("line", gaugeX, gaugeY, const.gaugeWidth, const.gaugeHeight)

        lg.setColor(1, 1, 1)
        lg.print(("Scrub Frequency: %.1f Hz"):format(scrubFreq), 5, const.resY - 15)
    end)
end

return scene