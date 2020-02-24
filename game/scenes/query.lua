local scene = {}

local message = nil
local options = nil
local clearColor = nil
local initBg = false

function scene.enter(_message, _options, clear)
    initBg = true
    message = _message
    options = _options
    if clear then
        clearColor = {0, 0, 0}
    else
        clearColor = nil
    end
end

function scene.keypressed(key)
    for _, option in ipairs(options) do
        if option.key == key then
            option.callback()
        end
    end
end

function scene.draw(dt)
    local font = assets.computerfont
    local fontH = font:getHeight()
    lg.setFont(font)
    util.gfx.pixelCanvas(const.resX, const.resY, clearColor, function(dt)
        if not clearColor and initBg then
            lg.setColor(0, 0, 0, 0.7)
            lg.rectangle("fill", 0, 0, const.resX, const.resY)
            initBg = false
        end

        local text = message .. "\n"
        for _, option in ipairs(options) do
            text = text .. "\n" .. option.text
        end
        local width, wrapped = font:getWrap(text, const.resX)
        lg.setColor(1, 1, 1)
        lg.printf(text, 0, const.resY / 2 - fontH * #wrapped / 2, const.resX, "center")
    end, dt)
end

return scene