local tblUtil = {}

function tblUtil.updateTable(tbl, with)
    for k, v in pairs(with) do
        tbl[k] = v
    end
end

function tblUtil.enum(list)
    local enum = {}
    local counter = 0
    for i = 1, #list do
        enum[list[i]] = counter
        counter = counter + 1
    end
    return enum
end

function tblUtil.mergeLists(...)
    local ret = {}
    for i = 1, select("#", ...) do
        tblUtil.extend(ret, select(i, ...))
    end
    return ret
end

function tblUtil.extend(a, b)
    if not b then
        return a
    end

    for _, item in ipairs(b) do
        table.insert(a, item)
    end

    return a
end

function tblUtil.indexOf(list, elem)
    for i, v in ipairs(list) do
        if v == elem then return i end
    end
    return nil
end

function tblUtil.inList(list, elem)
    return tblUtil.indexOf(list, elem) ~= nil
end

function tblUtil.inverseTable(tbl)
    local ret = {}
    for k, v in pairs(tbl) do
        ret[v] = k
    end
    return ret
end

-- TODO: implement, step, negative indices
function tblUtil.slice(tbl, from, to)
    from = from or 1
    to = to or #tbl
    local ret = {}
    for i = from, to do
        table.insert(ret, tbl[i])
    end
    return ret
end

function tblUtil.unpackKeys(tbl, keys)
    if #keys == 0 then
        return nil
    elseif #keys == 1 then
        return tbl[keys[1]]
    else
        return tbl[keys[1]], tblUtil.unpackKeys(tbl, tblUtil.slice(keys, 2))
    end
end

function tblUtil.stableSort(list, cmp)
    for i = 2, #list do
        local v = list[i]
        local j = i
        while j > 1 and cmp(v, list[j-1]) do
            list[j] = list[j-1]
            j = j - 1
        end
        list[j] = v
    end
end

function tblUtil.randomChoice(list)
    return list[love.math.random(1, #list)]
end

function tblUtil.keys(tbl)
    local ret = {}
    for k, _ in pairs(tbl) do
        table.insert(ret, k)
    end
    return ret
end

return tblUtil
