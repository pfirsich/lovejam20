-- I don't want too many of these and I want to keep track, so I keep them here in the globals-cage
lf = love.filesystem
lg = love.graphics
lk = love.keyboard
lt = love.timer
lm = love.math

-- I want to be able to use this anytime for ez debugging
inspect = require("libs.inspect")

-- f = flat
function finspect(t)
    return inspect(t, {newline = "", indent = ""})
end

-- I need these almost everywhere
assets = require("assets")
class = require("libs.class")
const = require("const")
util = require("util")