local assets = {}

function assets.image(name)
    return {
        type = "image",
        name = name,
        path = "assets/images/" .. name .. ".png"
    }
end

function assets.load(list)
    for _, asset in ipairs(list) do
        if asset.type == "image" then
            assets[asset.name] = lg.newImage(asset.path)
        else
            assert(false, "Unknown asset type")
        end
    end
end

return assets