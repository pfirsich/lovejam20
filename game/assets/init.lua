local assets = {}

function assets.image(name, path)
    return {
        type = "image",
        name = name,
        path = "assets/images/" .. (path or (name .. ".png")),
    }
end

function assets.sound(name, path)
    return {
        type = "sound",
        name = name,
        path = "assets/sounds/" .. (path or (name .. ".wav")),
    }
end

function assets.font(name, path)
    return {
        type = "font",
        name = name,
        path = "assets/fonts/" .. (path or (name .. ".fnt")),
    }
end

function assets.load(list)
    for _, asset in ipairs(list) do
        if asset.type == "image" then
            assets[asset.name] = lg.newImage(asset.path)
            assets[asset.name]:setFilter("nearest", "nearest")
        elseif asset.type == "sound" then
            assets[asset.name] = love.audio.newSource(asset.path, "static")
        elseif asset.type == "font" then
            assets[asset.name] = lg.newFont(asset.path)
            assets[asset.name]:setFilter("nearest", "nearest")
        else
            assert(false, "Unknown asset type")
        end
    end
end

return assets