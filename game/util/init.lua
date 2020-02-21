local util = {}

util.inspect = require("libs.inspect")
util.class = require("libs.class")

function util.callNonNil(f, ...)
    if f then f(...) end
end

function util.loveDoFile(path)
    local chunk, err = love.filesystem.load(path)
    if chunk then
        return chunk()
    else
        error(err)
    end
end

function util.nop()
    -- pass
end

function util.ModifiedChecker()
    local lastModified = {}

    return function(path)
        local mod = lf.getInfo(path).modtime or 0
        return not lastModified[path] or lastModified[path] < mod
    end
end

function util.trim(s)
    return s:match "^%s*(.-)%s*$"
end

for _, item in ipairs(lf.getDirectoryItems("util")) do
    if item ~= "init.lua" then
        local name = item:sub(1,-5)
        util[name] = require("util." .. name)
    end
end

return util
