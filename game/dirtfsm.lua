local DirtFsm = class("DirtFsm")

local function transition(from, to, tool, speed, duration, cleaners)
    return {
        from = from,
        to = to,
        tool = tool,
        scrubSpeed = speed,
        scrubDuration = duration,
        cleaners = cleaners
    }
end

local scrubSpeeds = {
    -- {min, max}
    slow = {0.4, 3.0},
    brisk = {3.0, 6.0},
    fast = {6.0, 100.0},
}

local dirtFsmData = {
    goo = {
        states = {
            {name = "init"},
            {name = "softened", color = {1, 0, 1, 0.8}},
            {name = "clean", color = {1, 1, 1, 0.3}},
        },
        transitions = {
            transition("init", "softened", "sponge", "brisk", 3.0, {"cleanerA"}),
            transition("softened", "clean", "cloth", "fast", 1.0, {"cleanerC"}),
        }
    },
    specks = {
        states = {
            {name = "init"},
            {name = "clean", color = {1, 1, 1, 0.7}},
        },
        transitions = {
            transition("init", "clean", "sponge", "fast", 1.0, {"cleanerB"}),
        }
    }
}

function DirtFsm:initialize(dirtType)
    assert(util.table.hasKey(dirtFsmData, dirtType), dirtType)
    self.fsmData = dirtFsmData[dirtType]
    assert(self.fsmData.states[1].name == "init")
    assert(self.fsmData.states[#self.fsmData.states].name == "clean")
    self:enter("init")
    self.cleaners = {}
end

function DirtFsm:getStateData(name)
    name = name or self.state
    local _, stateData = util.table.findKeyValue(
        self.fsmData.states, "name", name)
    return stateData
end

function DirtFsm:enter(state)
    self.state = state
    self.progress = {}
    self.timeout = self:getStateData().timeout
end

function DirtFsm:getColor()
    return self:getStateData().color or {1, 1, 1, 1}

    -- local totalProgress = 0
    -- local maxProgress = 0
    -- for _, progress in pairs(self.progress) do
    --     totalProgress = totalProgress + progress
    --     maxProgress = math.max(maxProgress, progress)
    -- end

    -- -- weighted average of target color
    -- local targetColor = {0, 0, 0, 0}
    -- for targetState, progress in pairs(self.progress) do
    --     local color = self:getStateData(targetState).color or {1, 1, 1, 1}
    --     for i = 1, 4 do
    --         targetColor[i] = targetColor[i] + progress / totalProgress * color[i]
    --     end
    --     totalProgress = totalProgress + progress
    -- end

    -- -- lerp original color and target color with max progress
    -- local color = {unpack(self:getStateData().color or {1, 1, 1, 1})}
    -- for i = 1, 4 do
    --     color[i] = util.math.lerp(color[i], targetColor[i], maxProgress)
    -- end

    -- return color
end

function DirtFsm:scrub(tool, frequency)
    local anyMatch = false
    for _, transition in ipairs(self.fsmData.transitions) do
        local freqMin, freqMax = unpack(scrubSpeeds[transition.scrubSpeed])
        local match = transition.from == self.state
            and transition.tool == tool
            and frequency > freqMin and frequency < freqMax
        for _, cleaner in ipairs(transition.cleaners) do
            match = match and (self.cleaners[cleaner] ~= nil)
        end
        if match then
            anyMatch = true
            -- integrating 1/frequency should be seconds scrubbed
            -- dividing by scrubDuration to get into [0, 1] progress range
            self.progress[transition.to] = (self.progress[transition.to] or 0)
                + 1.0 / frequency / transition.scrubDuration
            if self.progress[transition.to] >= 1.0 then
                self:enter(transition.to)
                return true
            end
        end
    end
    return anyMatch
end

function DirtFsm:applyCleaner(cleaner)
    self.cleaners[cleaner] = 1.0
end

function DirtFsm:update(dt)
    for _, cleaner in ipairs(util.table.keys(self.cleaners)) do
        local value = self.cleaners[cleaner]
        value = value - dt / const.cleanerLifetime[cleaner]
        if value <= 0 then
            self.cleaners[cleaner] = nil
        else
            self.cleaners[cleaner] = value
        end
    end
end

return DirtFsm