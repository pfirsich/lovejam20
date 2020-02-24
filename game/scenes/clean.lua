local scenes = require("scenes")
local dirtgen = require("dirtgen")
local FreqMeasure = require("freqmeasure")
local particles = require("particles")
local codex = require("codex")
local blobtiles = require("blobtiles")

local scene = {}

local tools = {
    sponge = {
        image = "handSponge",
    },
    cloth = {
        image = "handCloth",
    },
    slorbex = {
        image = "handSlorbex",
    },
    oktoplox = {
        image = "handOktoplox",
    }
}
local currentTool = "sponge"

local showDebug = false

local scrubbing = false

local dirt = nil

local lastMouseX, lastMouseY = 0, 0
local mouseHistory = {}

local totalScrubFreqMeas = FreqMeasure(const.scrubHistoryLen, const.scrubSampleNum)

function scene.enter(dirtGenParams)
    dirt = dirtgen.generate(dirtGenParams)
    for y = 1, #dirt.tiles do
        for x = 1, #dirt.tiles[y] do
            dirt.tiles[y][x].scrubFreqMeas = FreqMeasure(const.scrubHistoryLen, const.scrubSampleNum)
            dirt.tiles[y][x].lastMouseInRect = false
        end
    end
    codex.init()
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
                if topLayer then
                    local match = topLayer.fsm:scrub(currentTool, tile.scrubFreqMeas:get(scene.simTime))
                    if match then
                        local sparkleImage = util.table.randomChoice({
                            assets.sparkle1, assets.sparkle2})
                        local sx = mx + util.math.randf(-10, 10)
                        local sy = my + util.math.randf(-10, 10)
                        particles.spawn("sparkles", sparkleImage, sx, sy, 0.2)
                        local sound = assets.sparkle:play()
                        sound:setPitch(util.math.randDeviate(1.0, 0.1))
                        sound:setVolume(0.3)
                    end
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

local function applyCleaner(cleaner)
    local images
    if cleaner == "glab" then
        images = {assets.bubble1, assets.bubble2}
    elseif cleaner == "shlooze" then
        images = {assets.squareBubble1, assets.squareBubble2}
    elseif cleaner == "blinge" then
        images = {assets.splat1, assets.splat2}
    end
    local radius = const.cleanerRadius[cleaner]
    local area = 2 * math.pi * radius * radius
    local num = math.floor(area / 4096) * 2
    local mx, my = util.gfx.getMouse(const.resX, const.resY)
    -- remove all other particles
    particles.forEach("bubbles", function(particle)
        if particle.cleanerType ~= cleaner and
                util.math.pointInCircle(particle.x, particle.y, mx, my, radius) then
            return true
        end
    end, true)
    for i = 1, num do
        local x, y = util.math.randCircle(mx, my, radius)
        local particle = particles.spawn("bubbles",
            util.table.randomChoice(images), x, y, const.cleanerLifetime[cleaner], false, 1)
        particle.color = {unpack(const.cleanerColors[cleaner])}
        particle.cleanerType = cleaner
    end
    assets.spray:play():setPitch(util.math.randDeviate(1.0, 0.1))

    for y = 1, #dirt.tiles do
        for x = 1, #dirt.tiles[y] do
            local tileSize = const.dirtTileSize
            local tx, ty = (x - 1) * tileSize, (y - 1) * tileSize

            if util.math.circleInRect(mx, my, radius, tx, ty, tileSize, tileSize) then
                local layerIdx, topLayer = pickTopLayer(x, y)
                if topLayer then
                    topLayer.fsm:applyCleaner(cleaner)
                end
            end
        end
    end
end

function scene.tick()
    local mx, my = util.gfx.getMouse(const.resX, const.resY)
    local mouseDown = love.mouse.isDown(1)

    if scrubbing then
        scrub()
    end

    codex.update(const.simDt, scrubbing)

    local tilesDirty = false
    for y = 1, #dirt.tiles do
        for x = 1, #dirt.tiles[y] do
            local tile = dirt.tiles[y][x]
            for layer = 1, dirt.layerCount do
                if tile.layers[layer] then
                    tilesDirty = true
                    tile.layers[layer].fsm:update(const.simDt)
                end
            end
            tile.scrubFreqMeas:truncate(scene.simTime)
        end
    end

    if not tilesDirty or (DEVMODE and (lk.isDown("f9") or lk.isDown("o"))) then
        scenes.enter(scenes.query, "Job well done!", {
            {key = "return", text = "<Return> to return to Mission Control", callback = function()
                scenes.enter(scenes.questview, true)
            end},
        })
    end

    totalScrubFreqMeas:truncate(scene.simTime)

    particles.update("bubbles", const.simDt, function(bubble)
        local alpha = 0.7
        if bubble.lifetime < 1.0 then
            alpha = util.math.clamp(bubble.lifetime) * 0.7
        end
        bubble.color[4] = alpha
    end)

    particles.update("sparkles", const.simDt, function(sparkle)
    end)
end

function scene.keypressed(key)
    local mx, my = util.gfx.getMouse(const.resX, const.resY)

    if key == "t" then
        currentTool = "sponge"
    elseif key == "r" then
        currentTool = "cloth"
    elseif key == "e" then
        currentTool = "slorbex"
    elseif key == "w" then
        currentTool = "oktoplox"
    end

    codex.keypressed(key)

    if not codex.hovered then
        if key == "g" then
            applyCleaner("glab")
        elseif key == "f" then
            applyCleaner("shlooze")
        elseif key == "d" then
            applyCleaner("blinge")
        end
    end

    if DEVMODE and key == "backspace" then
        scenes.enter(scenes.questview)
    end

    if key == "escape" then
        scenes.push(scenes.query, "Return to Mission Control?", {
            {key = "return", text = "<Return> to return to Mission Control", callback = function()
                scenes.enter(scenes.questview)
            end},
            {key = "escape", text = "<Escape> to abort", callback = function()
                scenes.pop()
            end}
        })
    end
end

function scene.mousepressed(x, y, button)
    local mx, my = util.gfx.getMouse(const.resX, const.resY)
    if button == 1 then
        codex.mousepressed(mx, my)
        if not codex.hovered then
            scrubbing = true
        end
    end
end

function scene.mousereleased(x, y, button)
    if button == 1 then
        scrubbing = false
    end
end

-- This should be somewhere in blobtiles maybe, but this is a fucking gamejam
local tileOffsets = {
    {-1, -1}, {0, -1}, {1, -1},
    {-1,  0},          {1,  0},
    {-1,  1}, {0,  1}, {1,  1},
}
local function getNeighbourHoodBitmask(x, y, layer)
    local n = 1
    local mask = 0
    local state = dirt.tiles[y][x].layers[layer].fsm.state
    for _, offset in ipairs(tileOffsets) do
        local tx = x + offset[1]
        local ty = y + offset[2]
        local layer = dirt.tiles[ty] and dirt.tiles[ty][tx]
            and dirt.tiles[ty][tx].layers[layer]
        if layer and layer.fsm.state == state then
            mask = mask + n
        end
        n = n * 2
    end
    return mask
end

function scene.draw(dt)
    util.gfx.pixelCanvas(const.resX, const.resY, {0.1, 0.1, 0.1}, function(dt)
        lg.draw(assets.backgroundMetal)

        lg.setScissor(0, 0, #dirt.tiles[1] * const.dirtTileSize, #dirt.tiles * const.dirtTileSize)
        for y = 1, #dirt.tiles do
            for x = 1, #dirt.tiles[y] do
                local tile = dirt.tiles[y][x]
                local tileSize = const.dirtTileSize
                local tx, ty = (x - 1) * tileSize, (y - 1) * tileSize

                for layerIdx = 1, dirt.layerCount do
                    local dirtType = dirt.layerData[layerIdx].dirtType

                    if tile.layers[layerIdx] then
                        local fsm = tile.layers[layerIdx].fsm
                        local bitmask = getNeighbourHoodBitmask(x, y, layerIdx)
                        lg.setColor(fsm:getColor())
                        lg.draw(fsm:getImage(), blobtiles.getQuad(bitmask), tx, ty)
                    end
                end

                if showDebug then
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
        end

        lg.setColor(1, 1, 1)
        particles.draw("bubbles")

        lg.setScissor()

        if showDebug then
            lg.setColor(0, 1, 0)
            local points = {}
            for _, mousePos in ipairs(mouseHistory) do
                table.insert(points, mousePos.x)
                table.insert(points, mousePos.y)
            end
            if #points > 2 then
                lg.line(points)
            end
        end

        codex.draw()

        lg.setColor(1, 1, 1)
        local mx, my = util.gfx.getMouse(const.resX, const.resY)
        local tool = tools[currentTool]
        local handImage = assets[tool.image]
        if codex.hovered then
            handImage = assets.handPoint
        end
        local imgW, imgH = handImage:getDimensions()
        lg.draw(handImage, mx, my, 0, 1, 1, imgW/2, imgH/2)

        lg.setColor(1, 1, 1)
        particles.draw("sparkles")

        if not codex.hovered then
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
                gaugeImg = "gaugeBrisk"
            end
            lg.setColor(1, 1, 1)
            lg.draw(assets[gaugeImg], gaugeX, gaugeY)
        end
    end)
end

return scene