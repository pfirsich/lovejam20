local assets = {}

function assets.image(name)
    return {
        type = "image",
        name = name,
        path = "assets/images/" .. name .. ".png",
    }
end

function assets.sound(name)
    return {
        type = "sound",
        name = name,
        path = "assets/sounds/" .. name .. ".wav",
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