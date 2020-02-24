local utilMath = require("util.math")

local gfx = {}

function gfx.getPixelCanvasParams(resX, resY)
    local winW, winH = love.graphics.getDimensions()
    local scaleX, scaleY = math.floor(winW / resX), math.floor(winH / resY)
    local scale = math.min(scaleX, scaleY)
    local finalW, finalH = scale * resX, scale * resY
    return winW/2 - finalW/2, winH/2 - finalH/2, scale
end

function gfx.getMouse(resX, resY)
    local mx, my = love.mouse.getPosition()
    local cx, cy, scale = gfx.getPixelCanvasParams(resX, resY)
    local rmx = utilMath.clamp(mx - cx, 0, resX * scale)
    local rmy = utilMath.clamp(my - cy, 0, resY * scale)
    return math.floor(rmx / scale), math.floor(rmy / scale)
end

local pixelCanvas = nil
function gfx.pixelCanvas(resX, resY, clearColor, drawFunc, ...)
    if pixelCanvas == nil then
        pixelCanvas = love.graphics.newCanvas(resX, resY)
        pixelCanvas:setFilter("nearest", "nearest")
    end
    love.graphics.setCanvas(pixelCanvas)
    if clearColor then
        love.graphics.clear(clearColor)
    end
    drawFunc(...)

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    local x, y, scale = gfx.getPixelCanvasParams(resX, resY)
    love.graphics.draw(pixelCanvas, x, y, 0, scale)
end

return gfx