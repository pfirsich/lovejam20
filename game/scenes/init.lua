local mod = {}
-- I do it this way, so you can iterate over the k,v pairs in scenes and don't find current, require and enter as well
local scenes = setmetatable({}, {__index = mod})

mod.current = {}

function mod.enter(scene, ...)
    if mod.current and mod.current.exit then
        mod.current.exit(scene)
    end

    mod.current = scene
    if mod.current.enter then
        mod.current.enter(...)
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