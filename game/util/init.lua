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

function util.autoFullscreen()
    local supported = love.window.getFullscreenModes()
    table.sort(supported, function(a, b) return a.width*a.height < b.width*b.height end)

    local filtered = {}
    local scrWidth, scrHeight = love.window.getDesktopDimensions()
    for _, mode in ipairs(supported) do
        if mode.width*scrHeight == scrWidth*mode.height then
            table.insert(filtered, mode)
        end
    end
    supported = filtered

    local max = supported[#supported]
    local flags = {fullscreen = true}
    if not love.window.setMode(max.width, max.height, flags) then
        error(string.format("Resolution %dx%d could not be set successfully.", max.width, max.height))
    end
    if love.resize then love.resize(max.width, max.height) end
end

for _, item in ipairs(lf.getDirectoryItems("util")) do
    if item ~= "init.lua" then
        local name = item:sub(1,-5)
        util[name] = require("util." .. name)
    end
end

return util
