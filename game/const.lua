local util = require("util")

local const = {}

local modified = util.ModifiedChecker()

function const.reload(root, dontSetup)
    root = root or ""
    local suffix = ".const.lua"
    for _, item in ipairs(lf.getDirectoryItems(root)) do
        local path = (root or "") .. "/" .. item
        if lf.getInfo(path, "file") then
            if item:sub(-suffix:len()) == suffix and modified(path) then
                local c = util.loveDoFile(path)
                assert(not util.table.inList(util.table.keys(c), "reload"))
                util.table.updateTable(const, c)
            end
        elseif lf.getInfo(path, "directory") then
            const.reload(path, true)
        end
    end
end

return const