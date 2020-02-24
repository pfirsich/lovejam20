local scenes = require("scenes")
local gui = require("shittygui")
local DialogBox = require("dialogbox")

local scene = {}

sequences = {
    intro = {
        dialog = {
            {"The year is 2264 and I've made it.", 2.5, 0.5},
            {"I am the head janitor at the intergalatic space station Garzikulon Prime.", 3.8, 0.7},
            {"Only three years after basic training at the academy I reached the very top.", 4.0, 0.6},
            {"But not without a cost.", 1.5, 0.4},
            {"Two months ago my master Rüdiger-sensei died in a mission cleaning up a Glorzag-poop spill.", 4.0, 0.8},
            {"It was a routine job and Rüdiger-sensei was a pro.", 3.0, 0.5},
            {"Something is off about this and I will figure out what it is.", 3.5, 0.5},
            {"For now though, I simply have have to do my job.", 2.5},
        },
        audio = assets.voiceIntro,
        buttonText = "Do Your Job",
    },
    archives = {
        dialog = {
            {"The elders are impressed by my work and have decided to grant me access to the archives.", 4.0},
            {"It is said that secrets are hidden in this sacred place which would grant the power to clean the electrons off atoms and the stars off the firmament.", 5.0},
            {"The ultimate power to dissolve any stain and to clean order itself off the universe with only entropy left behind.", 4.5},
        },
        audio = nil,
        buttonText = "Acquire Ancient Wisdoms",
    },
    done = {
        dialog = {
            {"Alien poop: obliterated.", 1.0, 1.0},
        },
        audio = nil,
        buttonText = "Call It a Day",
    },
}

local dialogBox = nil
local storySequence = nil
local nextScene = nil
local nextSceneParams = nil
local audio = nil

local buttonStyle = {
    textPadding = 5,
    bgColor = const.palette[28],
    outlineColor = const.palette[31],
    hoverBgColor = const.palette[29],
    --markedBgColor = const.palette[5],
    --markedOutlineColor = const.palette[25],
    textColor = const.palette[32],
}

function scene.enter(sequenceName, _nextScene, ...)
    local sequence = sequences[sequenceName]
    dialogBox = DialogBox(sequence.dialog, 25)
    storySequence = sequence
    nextScene = _nextScene
    nextSceneParams = {...}

    if storySequence.audio then
        audio = storySequence.audio:play()
    end
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
                if audio then
                    audio:stop()
                    audio = nil
                end
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