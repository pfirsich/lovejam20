local scenes = require("scenes")
local DialogBox = require("dialogbox")

local scene = {}

scene.activeQuests = {
    {
        title = "Poop in the Sink",
        description = {
            {text = "Hey Chief!"},
            {text = "We have a situation in the Medical Sector."},
            {text = "A Glargle has pooped in the sink!"},
        },
        dirtTypes = {"Glorzak", "Glargle", "Glob"},
        read = false,
    },
    {
        title = "A Total Mess",
        description = {
            {text = "Hey Chief!"},
            {text = "We have a situation in the Medical Sector."},
            {text = "A Glorzak has pooped in the sink!"},
        },
        dirtTypes = {"Glorzak", "Fleeb", "Glob"},
        read = false,
    },
    {
        title = "Sheesh!",
        description = {
            {text = "Hey Chief!"},
            {text = "We have a situation in the Medical Sector."},
            {text = "A Fleeb has pooped in the sink!"},
        },
        dirtTypes = {"Glorzak", "Fleeb", "Lsorble"},
        read = false,
    },
}
scene.selectedQuest = nil

local detailDialogBox = nil

local overviewWidth = 200
local padding = 15
local elementHeight = 25
local elementMargin = 5
local detailsPadding = 10
local detailsDescriptionOffset = 30

local bgColor = const.palette[3]
local panelBgColor = const.palette[27]
local outlineColor = const.palette[23]
local textColor = const.palette[32]

local buttonPadding = 5
local buttonBgColor = const.palette[4]
local buttonHoverBgColor = const.palette[6]
local buttonSelectBgColor = const.palette[5]
local buttonSelectOutlineColor = const.palette[25]

local startWidth = 120
local startHeight = 40

function scene.enter()
    scene.selectedQuest = nil
end

function scene.tick()
    if detailDialogBox then
        detailDialogBox:update(const.simDt)
    end
end

local function getOverviewRect()
    local x = padding
    local y = padding
    local h = const.resY - padding * 2
    return x, y, overviewWidth, h
end

local function getQuestRect(idx)
    local ox, oy, ow, oh = getOverviewRect()
    local x = ox + elementMargin
    local y = oy + idx * elementMargin + (idx - 1) * elementHeight
    local w = ow - elementMargin * 2
    local h = elementHeight
    return x, y, w, h
end

local function getDetailsRect()
    local ox, oy, ow, oh = getOverviewRect()
    local x = ox + ow + padding
    local w = const.resX - x - padding
    return x, oy, w, oh
end

local function getStartButtonRect()
    local dx, dy, dw, dh = getDetailsRect()
    local freeWidth = dw - detailsPadding * 2
    local x = dx + detailsPadding + math.floor(freeWidth / 4 - startWidth / 2)
    local y = dy + dh - detailsPadding - startHeight
    return x, y, startWidth, startHeight
end

local function drawButton(text, x, y, w, h, textAlign, hovered, marked)
    if hovered then
        lg.setColor(buttonHoverBgColor)
    else
        if marked then
            lg.setColor(buttonSelectBgColor)
        else
            lg.setColor(buttonBgColor)
        end
    end
    lg.rectangle("fill", x, y, w, h)
    if marked then
        lg.setColor(buttonSelectOutlineColor)
    else
        lg.setColor(outlineColor)
    end
    lg.rectangle("line", x, y, w, h)

    local textX = x + buttonPadding
    local fontH = assets.computerfont:getHeight()
    local textY = math.floor(y + h / 2 - fontH / 2)
    lg.setColor(textColor)
    lg.printf(text, textX, textY, w - buttonPadding * 2, textAlign or "left")
end

function scene.mousepressed(x, y, button)
    if button == 1 then
        local mx, my = util.gfx.getMouse(const.resX, const.resY)
        for i, quest in ipairs(scene.activeQuests) do
            local x, y, w, h = getQuestRect(i)
            local hover = util.math.pointInRect(mx, my, x, y, w, h)
            if hover and scene.selectedQuest ~= i then
                scene.selectedQuest = i
                detailDialogBox = DialogBox(quest.description, 35)
                if quest.read then
                    -- efficiency first! :>
                    detailDialogBox:finish()
                end
                quest.read = true
                break
            end
        end

        if scene.selectedQuest and detailDialogBox:isFinished() then
            local x, y, w, h = getStartButtonRect()
            if util.math.pointInRect(mx, my, x, y, w, h) then
                scenes.enter(scenes.transition, scenes.clean)
            end
        end

        local dx, dy, dw, dh = getDetailsRect()
        if util.math.pointInRect(mx, my, dx, dy, dw, dh) then
            if detailDialogBox and not detailDialogBox:isFinished() then
                detailDialogBox:skip()
            end
        end
    end
end

function scene.draw(dt)
    local font = assets.computerfont
    local fontH = font:getHeight()
    lg.setFont(font)
    util.gfx.pixelCanvas(const.resX, const.resY, bgColor, function(dt)
        local mx, my = util.gfx.getMouse(const.resX, const.resY)

        -- quest overview
        local ox, oy, ow, oh = getOverviewRect()
        lg.setColor(panelBgColor)
        lg.rectangle("fill", ox, oy, ow, oh)
        lg.setColor(outlineColor)
        lg.rectangle("line", ox, oy, ow, oh)

        for i, quest in ipairs(scene.activeQuests) do
            local x, y, w, h = getQuestRect(i)
            local hovered = util.math.pointInRect(mx, my, x, y, w, h)
            local selected = scene.selectedQuest == i
            local text = quest.title
            if not quest.read then
                text = "! " .. text
            end
            drawButton(text, x, y, w, h, "left", hovered, selected)
        end

        -- quest details view
        local dx, dy, dw, dh = getDetailsRect()
        lg.setColor(panelBgColor)
        lg.rectangle("fill", dx, dy, dw, dh)
        lg.setColor(outlineColor)
        lg.rectangle("line", dx, dy, dw, dh)

        lg.setColor(textColor)
        if scene.selectedQuest then
            local quest = scene.activeQuests[scene.selectedQuest]
            local x = dx + detailsPadding
            local y = dy + detailsPadding
            local freeWidth = dw - detailsPadding * 2

            local challengesString = "Challenges:"
            for _, type in ipairs(quest.dirtTypes) do
                challengesString = challengesString .. ("\n- %s poop"):format(type)
            end
            --local text = quest.description .. "\n\n" .. challengesString

            lg.print(quest.title, x, y)

            assert(detailDialogBox)
            detailDialogBox:draw(x, y + detailsDescriptionOffset, freeWidth)
            --lg.printf(text, x, y + detailsDescriptionOffset, freeWidth)

            if detailDialogBox:isFinished() then
                local startX, startY, startWidth, startHeight = getStartButtonRect()
                local hovered = util.math.pointInRect(mx, my,
                    startX, startY, startWidth, startHeight)
                drawButton("Deploy", startX, startY, startWidth, startHeight,
                    "center", hovered)
            else
                lg.setColor(1, 1, 1)
                local guy = assets.headsetGuy
                local gx = dx + dw - detailsPadding - guy:getWidth()
                local gy = dy + dh - detailsPadding - guy:getHeight()
                lg.circle("fill", gx, gy, 3)
                lg.draw(guy, gx, gy)
            end
        end
    end, dt)
end

return scene