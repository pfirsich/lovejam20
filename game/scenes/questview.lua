local scenes = require("scenes")
local DialogBox = require("dialogbox")
local gui = require("shittygui")
local codex = require("codex")

local scene = {}

local function getGenParams(dirtType, baseScale, octaves, threshold)
    return {dirtType = dirtType, genType = "simplex", params = {
        scale = baseScale, octaves = octaves, threshold = threshold,
    }}
end

local genParams = {
    glorzak = getGenParams("glorzak", 2.0, {1.0, 0.5, 0.3}, 0.8),
    fleeb = getGenParams("fleeb", 3.0, {1.0}, 0.8),
    lsorble = getGenParams("lsorble", 1.0, {1.0}, 0.5),
    ziltoid = getGenParams("ziltoid", 1.0, {1.0}, 0.5),
    flaglonz = getGenParams("flaglonz", 1.0, {1.0}, 0.5),
}

local quests = {
    {
        id = "tutorial",
        title = "Poop in the Sink",
        description = {
            {"Hey Chief!", 0.6, 0.4},
            {"We've got a situation in the Medical Sector.", 1.8, 0.2},
            {"A Glorzak has pooped in the sink!", 2.0},
        },
        audio = assets.voiceGuyGlorzak,
        dirtTypes = {"Glorzak"},
        genParams = {genParams.glorzak},
    },
    {
        title = "Unsanitary Conditions",
        description = {
            {"Hello Chief!", 0.9, 0.5},
            {"Someone found Fleeb poop in the Kitchen!", 3.0},
        },
        audio = assets.voiceGuyFleeb,
        dirtTypes = {"Fleeb", "Glorzak"},
        requires = {"tutorial"},
        genParams = {genParams.glorzak, genParams.fleeb},
    },
    {
        id = "archives",
        title = "A Total Mess",
        description = {
            {"Hi Chief!", 0.7, 0.4},
            {"We got another one in the Cargo Bay!", 1.5, 0.3},
            {"There's Lsorble poop everywhere!", 2.0},
        },
        audio = assets.voiceGuyLsorble,
        dirtTypes = {"Fleeb", "Glorzag", "Lsorble"},
        requires = {"tutorial"},
        storySequence = "archives",
        genParams = {genParams.glorzak, genParams.lsorble, genParams.fleeb},
    },
    {
        id = "miniboss",
        title = "New Frontiers",
        description = {
            {"Sir!", 0.5, 0.3},
            {"Hold tight! Something big's coming!", 1.9, 0.55},
            {"Ziltoid and Flaglonz poop all over the Bridge!", 2.8, 0.4},
            {"I don't know if you can handle this one yet!", 1.6},
        },
        audio = assets.voiceGuyZiltoid,
        dirtTypes = {"Flaglonz", "Ziltoid"},
        requires = {"tutorial"},
        genParams = {genParams.flaglonz, genParams.ziltoid, genParams.flaglonz},
    },
    {
        title = "More Poop",
        description = {
            {"Hey, Chief!", 1.0, 0.6},
            {"They just keep it coming today!", 1.4, 0.55},
            {"Flaglonz poop in Life Support!", 2.2},
        },
        audio = assets.voiceGuyFlaglonz,
        dirtTypes = {"Flaglonz", "Fleeb"},
        requires = {"miniboss"},
        genParams = {genParams.flaglonz, genParams.fleeb},
    },
    {
        title = "God Help Us All",
        description = {
            {"Chief!", 0.8, 0.45},
            {"I've never seen anything like this!", 1.4, 0.5},
            {"There's poop everywhere!", 1.4, 0.4},
            {"It's in the walls!", 1.0, 0.5},
            {"I hope this day ends soon!", 1.5},
        },
        audio = assets.voiceGuyWalls,
        dirtTypes = {"Flaglonz", "Lsorble", "Ziltoid"},
        requires = {"miniboss"},
        genParams = {genParams.flaglonz, genParams.lsorble, genParams.ziltoid},
    },
}


--- actual vars
scene.selectedQuest = nil

local detailDialogBox = nil
local headsetGuySound = nil

local numVisits = 0
local codexEnabled = false
local showAllQuests = false


-- constants
local overviewWidth = 200
local padding = 15
local elementHeight = 25
local elementMargin = 5
local detailsPadding = 10
local detailsDescriptionOffset = 30
local codexBottomMargin = 40

local bgColor = const.palette[3]
local panelBgColor = const.palette[27]
local outlineColor = const.palette[23]
local textColor = const.palette[32]

local buttonStyle = {
    textPadding = 5,
    bgColor = const.palette[4],
    outlineColor = const.palette[23],
    hoverBgColor = const.palette[6],
    markedBgColor = const.palette[5],
    markedOutlineColor = const.palette[25],
    textColor = const.palette[32],
}

local startWidth = 120
local startHeight = 40

function scene.enter(finished)
    if scene.selectedQuest and finished then
        local quest = quests[scene.selectedQuest]
        quest.done = true
        if quest.storySequence then
            scenes.enter(scenes.storysequence, quest.storySequence, scenes.questview)
        end
    end

    local allDone = true
    for _, quest in ipairs(quests) do
        if not quest.done then
            allDone = false
            break
        end
    end
    if allDone then
        scenes.enter(scenes.storysequence, "done", scenes.exitgame)
    end

    scene.selectedQuest = nil
    detailDialogBox = nil
    headsetGuySound = nil

    numVisits = numVisits + 1
    codexEnabled = numVisits > 1
    if codexEnabled then
        codex.init()
    end
end

function scene.tick()
    if detailDialogBox then
        detailDialogBox:update(const.simDt)
    end
    if codexEnabled then
        codex.update(const.simDt)
    end
end

function scene.getDoneQuestIds()
    local done = {}
    for _, quest in ipairs(quests) do
        if quest.done and quest.id then
            table.insert(done, quest.id)
        end
    end
    return done
end

local function getOverviewRect()
    local x = padding
    local y = padding
    local h = const.resY - padding * 2
    if codexEnabled then
        h = h - codexBottomMargin
    end
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

local function getQuestById(id)
    for _, quest in ipairs(quests) do
        if quest.id == id then
            return quest
        end
    end
    return nil
end

local function isQuestUnlocked(idx)
    if not quests[idx].requires then
        return true
    end

    for _, required in ipairs(quests[idx].requires) do
        local quest = getQuestById(required)
        if not quest.done then
            return false
        end
    end
    return true
end

local function isQuestVisible(idx)
    if showAllQuests then
        return true
    end
    return not quests[idx].done and isQuestUnlocked(idx)
end

function scene.mousepressed(x, y, button)
    if button == 1 then
        local mx, my = util.gfx.getMouse(const.resX, const.resY)
        codex.mousepressed(mx, my)
        if codexEnabled and codex.hovered then
            return
        end

        local visibleIndex = 1
        for i, quest in ipairs(quests) do
            if isQuestVisible(i) then
                local x, y, w, h = getQuestRect(visibleIndex)
                local hover = util.math.pointInRect(mx, my, x, y, w, h)
                if hover and scene.selectedQuest ~= i then
                    scene.selectedQuest = i
                    detailDialogBox = DialogBox(quest.description, 35)
                    if headsetGuySound then
                        headsetGuySound:stop()
                        headsetGuySound = nil
                    end
                    if quest.read then
                        -- efficiency first! :>
                        detailDialogBox:finish()
                    else
                        headsetGuySound = quest.audio:play()
                        quest.read = true
                    end
                    break
                end
                visibleIndex = visibleIndex + 1
            end
        end

        if scene.selectedQuest and detailDialogBox:isFinished() then
            local quest = quests[scene.selectedQuest]
            local x, y, w, h = getStartButtonRect()
            if util.math.pointInRect(mx, my, x, y, w, h) then
                if headsetGuySound then
                    headsetGuySound:stop()
                    headsetGuySound = nil
                end
                scenes.enter(scenes.transition, scenes.clean, quest.genParams or quests[1].genParams)
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

function scene.pause()
    if headsetGuySound then
        headsetGuySound:pause()
    end
end

function scene.resume()
    if headsetGuySound then
        -- this errors for some reason
        -- headsetGuySound:play()
    end
end

function scene.keypressed(key)
    if codexEnabled then
        codex.keypressed(key)
    end

    if DEVMODE and key == "i" then
        showAllQuests = not showAllQuests
    end

    if key == "escape" then
        scenes.push(scenes.query, "Close the Game?", {
            {key = "return", text = "<Return> to close the game", callback = function()
                love.event.push("quit")
            end},
            {key = "escape", text = "<Escape> to abort", callback = function()
                scenes.pop()
            end}
        })
    end
end

function scene.draw(dt)
    local font = assets.computerfont
    local fontH = font:getHeight()
    lg.setFont(font)
    util.gfx.pixelCanvas(const.resX, const.resY, bgColor, function(dt)
        local mx, my = util.gfx.getMouse(const.resX, const.resY)

        local interactable = false

        -- quest overview
        local ox, oy, ow, oh = getOverviewRect()
        lg.setColor(panelBgColor)
        lg.rectangle("fill", ox, oy, ow, oh)
        lg.setColor(outlineColor)
        lg.rectangle("line", ox, oy, ow, oh)

        local visibleIndex = 1
        for i, quest in ipairs(quests) do
            if isQuestVisible(i) then
                local x, y, w, h = getQuestRect(visibleIndex)
                local hovered = util.math.pointInRect(mx, my, x, y, w, h)
                local selected = scene.selectedQuest == i
                local text = quest.title
                if not quest.read then
                    text = "! " .. text
                end
                interactable = interactable or hovered
                -- hax, idc
                buttonStyle.textAlign = "left"
                gui.drawButton(text, x, y, w, h, hovered, selected, buttonStyle)
                buttonStyle.textAlign = nil
                visibleIndex = visibleIndex + 1
            end
        end

        -- quest details view
        local dx, dy, dw, dh = getDetailsRect()
        lg.setColor(panelBgColor)
        lg.rectangle("fill", dx, dy, dw, dh)
        lg.setColor(outlineColor)
        lg.rectangle("line", dx, dy, dw, dh)

        lg.setColor(textColor)
        if scene.selectedQuest then
            local quest = quests[scene.selectedQuest]
            local x = dx + detailsPadding
            local y = dy + detailsPadding
            local freeWidth = dw - detailsPadding * 2

            lg.print(quest.title, x, y)

            assert(detailDialogBox)
            detailDialogBox:draw(x, y + fontH * 2, freeWidth)

            if detailDialogBox:isFinished() then
                local challengesString = "Challenges:"
                for _, type in ipairs(quest.dirtTypes) do
                    challengesString = challengesString .. ("\n- %s poop"):format(type)
                end
                local descrLines = #select(2, font:getWrap(detailDialogBox.string, freeWidth))
                lg.print(challengesString, x, y + fontH * (descrLines + 3))

                local startX, startY, startWidth, startHeight = getStartButtonRect()
                local hovered = util.math.pointInRect(mx, my,
                    startX, startY, startWidth, startHeight)
                interactable = interactable or hovered
                gui.drawButton("Deploy", startX, startY, startWidth, startHeight,
                    hovered, false, buttonStyle)
            end

            if headsetGuySound then
                lg.setColor(1, 1, 1)
                local guy = assets.headsetGuy
                local gx = dx + dw - detailsPadding - guy:getWidth()
                local gy = dy + dh - detailsPadding - guy:getHeight()
                lg.draw(guy, gx, gy)
            end
        end

        if codexEnabled then
            interactable = interactable or codex.hovered
            codex.draw()
        end

        local mx, my = util.gfx.getMouse(const.resX, const.resY)
        local handImage = interactable and assets.handPoint or assets.handOpen
        local imgW, imgH = handImage:getDimensions()
        lg.draw(handImage, mx, my, 0, 0, imgW/2, imgH/2)
    end, dt)

    lg.print(tostring(lt.getFPS()), 5, 5)
end

return scene