local scenes = require("scenes")

local scene = {}

local duration = 0.7

local nextScene = nil
local nextSceneParams = nil
local time = 0
local progress = 0

local transitions = {}
local transition = nil
local disabledTransitions = {
    "spinyBars",
}

function scene.enter(_nextScene, ...)
    nextScene = _nextScene
    nextSceneParams = {...}
    time = 0

    local name
    while true do
        name = util.table.randomChoice(util.table.keys(transitions))
        if not util.table.inList(disabledTransitions, name) then
            break
        end
    end
    transition = transitions[name]
    --transition = transitions.doubleCircle
end

function scene.tick()
    time = time + const.simDt
    if time > duration then
        scenes.enter(nextScene, unpack(nextSceneParams))
    end
    progress = time / duration
end

function transitions.topDownSwipe()
    local height = math.floor(const.resY / 2.0 * progress)
    lg.rectangle("fill", 0, 0, const.resX, height)
    lg.rectangle("fill", 0, const.resY - height, const.resX, height)
end

local function bar(x, y, angle, w, h)
    lg.draw(assets.pixel, x, y, angle, w, h, 0.5, 0.5)
end

function transitions.spinyBars()
    local barWidth = 70
    local angle = time * 2.0 * math.pi / duration
    local x = math.floor(const.resX / 2.0 * progress)
    local params = {const.resY / 2, angle, barWidth, const.resX}
    bar(x, unpack(params))
    bar(const.resX - x, unpack(params))
end

function transitions.doubleCircle()
    local len = math.sqrt(const.resX*const.resX + const.resY*const.resY)
    local angle = math.pi * progress
    local x, y = const.resX / 2, const.resY / 2
    lg.arc("fill", x, y, len, 0, angle, 4)
    lg.arc("fill", x, y, len, math.pi, math.pi + angle, 4)
end

function transitions.sideSwipe()
    lg.rectangle("fill", 0, 0, const.resX * progress, const.resY)
end

function scene.draw(dt)
    util.gfx.pixelCanvas(const.resX, const.resY, nil, function(dt)
        lg.setColor(0, 0, 0)
        transition(dt)
    end, dt)
end

return scene