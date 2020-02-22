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

function assets.load(list)
    for _, asset in ipairs(list) do
        if asset.type == "image" then
            assets[asset.name] = lg.newImage(asset.path)
        elseif asset.type == "sound" then
            assets[asset.name] = love.audio.newSource(asset.path, "static")
        else
            assert(false, "Unknown asset type")
        end
    end
end

return assets