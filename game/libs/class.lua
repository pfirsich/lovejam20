local function class_call(c, ...)
    local self = setmetatable({}, c)
    self.class = c
    if self.initialize then self:initialize(...) end
    return self
end

local function class(name, base)
    local cls = {}
    cls.__index = cls
    cls.name = name

    return setmetatable(cls, {
        __index = base,
        __call = class_call,
    })
end

return class
