local scenes = require("scenes")
local gui = require("shittygui")
local DialogBox = require("dialogbox")

local scene = {}

local dialogBox = nil
local storySequence = nil
local nextScene = nil
local nextSceneParams = nil

local buttonStyle = {
    textPadding = 5,
    bgColor = const.palette[28],
    outlineColor = const.palette[31],
    hoverBgColor = const.palette[29],
    --markedBgColor = const.palette[5],
    --markedOutlineColor = const.palette[25],
    textColor = const.palette[32],
}

function scene.enter(_storySequence, _nextScene, ...)
    dialogBox = DialogBox(_storySequence.dialog)
    storySequence = _storySequence
    nextScene = _nextScene
    nextSceneParams = {...}
end

function scene.tick()
    dialogBox:update(const.simDt)
end

local function getButtonRect()
    local buttonWidth = 250
    local buttonHeight = 50
    local buttonMargin = 25
    local x = const.resX / 2 - buttonWidth / 2
    local y = const.resY - buttonHeight - buttonMargin
    return x, y, buttonWidth, buttonHeight
end

function scene.mousepressed(x, y, button)
    if button == 1 then
        local mx, my = util.gfx.getMouse(const.resX, const.resY)

        if dialogBox:isFinished() then
            local x, y, w, h = getButtonRect()
            if util.math.pointInRect(mx, my, x, y, w, h) then
                scenes.enter(nextScene, unpack(nextSceneParams))
            end
        else
            dialogBox:skip()
        end
    end
end

function scene.draw(dt)
    local font = assets.computerfont
    local fontH = font:getHeight()
    lg.setFont(font)
    util.gfx.pixelCanvas(const.resX, const.resY, {0, 0, 0}, function(dt)
        if storySequence.image then
            lg.setColor(1, 1, 1)
            lg.draw(storySequence)
        end

        local dialogBoxW = const.resX / 4 * 3
        local dialogBoxH = const.resY / 2
        local x = const.resX / 2 - dialogBoxW / 2
        local y = const.resY / 2 - dialogBoxH / 2
        dialogBox:draw(x, y, dialogBoxW)

        if dialogBox:isFinished() then
            local mx, my = util.gfx.getMouse(const.resX, const.resY)
            local x, y, w, h = getButtonRect()
            local hovered = util.math.pointInRect(mx, my, x, y, w, h)
            gui.drawButton(storySequence.buttonText, x, y, w, h,
                hovered, false, buttonStyle)
        end
    end, dt)
end

return scene