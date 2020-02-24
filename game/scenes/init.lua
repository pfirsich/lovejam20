local mod = {}
-- I do it this way, so you can iterate over the k,v pairs in scenes and don't find current, require and enter as well
local scenes = setmetatable({}, {__index = mod})

local stack = {}

mod.current = {}

function mod.enter(scene, ...)
    if mod.current and mod.current.exit then
        mod.current.exit(scene)
    end

    stack = {} -- if you enter after a push, remove it all
    mod.current = scene
    if mod.current.enter then
        mod.current.enter(...)
    end
end

function mod.push(scene, ...)
    if mod.current and mod.current.pause then
        mod.current.pause(scene)
    end

    table.insert(stack, mod.current)
    mod.current = scene
    if mod.current.enter then
        mod.current.enter(...)
    end
end

function mod.pop()
    assert(#stack > 0)
    local top = table.remove(stack)

    if mod.current and mod.current.exit then
        mod.current.exit(top)
    end

    mod.current = top
    if mod.current.resume then
        mod.current.resume()
    end
end

function mod.require()
    for _, item in ipairs(lf.getDirectoryItems("scenes")) do
        local path = "scenes/" .. item

        if lf.getInfo(path, "file") and item:sub(-4) == ".lua" and item ~= "init.lua" then
            local name = item:sub(1, -5)
            assert(name ~= "current" and name ~= "enter" and name ~= "require")
            scenes[name] = require("scenes." .. name)
        end
    end
end

return scenes