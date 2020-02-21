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

local dirtTiles = {}

local lastMouseX, lastMouseY = 0, 0
local mouseVelX, mouseVelY = 0, 0

function scene.enter()
    for y = 1, const.dirtTilesY do
        dirtTiles[y] = {}
        for x = 1, const.dirtTilesX do
            dirtTiles[y][x] = {
                touches = {},
                nextTouchIndex = 1,
                lastMouseInRect = false,
            }
        end
    end
end

-- returns if mouse changed direction
local function updateMouseVel()
    local mx, my = love.mouse.getPosition()
    local lastVelX, lastVelY = mouseVelX, mouseVelY
    mouseVelX, mouseVelY = mx - lastMouseX, my - lastMouseY
    lastMouseX, lastMouseY = mx, my

    -- new velocity at least perpendicular (or opposite)
    return lastVelX*mouseVelX + lastVelY*mouseVelY < 0
end

local function getLastDirtTileTouch(x, y, index)
    local tile = dirtTiles[y] and dirtTiles[y][x]
    if not tile or #tile.touches == 0 then
        return false
    end
    local idx = tile.nextTouchIndex - index
    if idx < 1 then
        idx = #tile.touches + idx
    end
    return tile.touches[idx]
end

function scene.tick()
    local mx, my = util.gfx.getMouse(const.resX, const.resY)
    local mouseSwitched = updateMouseVel()
    for y = 1, #dirtTiles do
        for x = 1, #dirtTiles[y] do
            local tile = dirtTiles[y][x]
            local tw, th = const.resX / const.dirtTilesX, const.resY / const.dirtTilesY
            local tx, ty = (x - 1) * tw, (y - 1) * th
            local inRect = util.math.inRect(mx, my, tx, ty, tw, th)
            local tileTouched = inRect and (not tile.lastMouseInRect or mouseSwitched)
            tile.touches[tile.nextTouchIndex] = tileTouched
            tile.nextTouchIndex = tile.nextTouchIndex + 1
            local maxTouches = const.touchHistoryLen / const.simDt
            if tile.nextTouchIndex > maxTouches then
                tile.nextTouchIndex = 1
            end
            tile.lastMouseInRect = inRect
        end
    end
end

function scene.keypressed(key)
    if key == "r" then
        currentTool = "sponge"
    elseif key == "e" then
        currentTool = "cloth"
    end
end

local function count(list)
    local n = 0
    for i = 1, #list do 
        n = n + (list[i] and 1 or 0)
    end
    return n
end

local function getDirtTileTouchFrequency(x, y)
    return count(dirtTiles[y][x].touches) / const.touchHistoryLen
end

local function getRecentlyTouched(x, y, pastFrames)
    for i = 1, pastFrames do 
        if getLastDirtTileTouch(x, y, i) then
            return true
        end
    end
    return false
end

function scene.draw(dt)
    util.gfx.pixelCanvas(const.resX, const.resY, {0.1, 0.1, 0.1}, function(dt)
        for y = 1, #dirtTiles do
            for x = 1, #dirtTiles[y] do
                local tile = dirtTiles[y][x]
                local tw, th = const.resX / const.dirtTilesX, const.resY / const.dirtTilesY
                local tx, ty = (x - 1) * tw, (y - 1) * th
                lg.setColor(0, 0, 1)
                if getRecentlyTouched(x, y, math.floor(0.1 * const.touchHistoryLen / const.simDt)) then 
                    lg.setColor(1, 0, 0)
                end
                lg.rectangle("line", tx, ty, tw, th)
                lg.print(("%.2f"):format(getDirtTileTouchFrequency(x, y)), tx + 2, ty + 2)
            end
        end

        lg.setColor(1, 1, 1)
        local mx, my = util.gfx.getMouse(const.resX, const.resY)
        local tool = tools[currentTool]
        local image = assets[tool.image]
        local imgW, imgH = image:getDimensions()
        lg.draw(image, mx, my, 0, 1, 1, imgW/2, imgH/2)
    end)
end

return scene