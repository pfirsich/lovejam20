local Book = require("libs.book")
local blobtiles = require("blobtiles")

local codex = {}

-- ASSET: open book sound, close book sound, flip page sound
-- ASSET: study sound "mmhm"

local pageWidth = 300
local pageHeight = 350

local function text(text, y, params)
    params = params or {}
    return {
        type = "text",
        text = text,
        y = y,
        scale = params.scale or 1,
        align = params.align or "left",
        valign = params.valign or "top",
        color = params.color or {0, 0, 0, 1},
    }
end

local function recipeTitle(str)
    return text(str, 0, {align = "center"})
end

local function image(assetName, scale, y)
    return {type = "image", asset = assetName, scale = scale, y = y}
end

local function recipeDirtImage(asset)
    return {type = "dirttile", asset = asset, scale = 0.4, y = 0.15}
end

local pages = {
    {
        text("Tome of Filth", 0.5, {scale = 2, align = "center", valign = "middle"}),
    },
    {
        text([[T to equip Sponge
R to equip Cloth
E to equip Slorbex
W to equip Oktoplox

G to apply Glab
F to apply Shlooze
D to apply Blinge]], 0),
    },
    {
        recipeTitle("Prisparkartarium"),
        recipeDirtImage("goo"),
        text(
[[1. Soften using brisk scrub with Slorbex and Glab
2. Wipe off slowly Cloth and Blinge]], 0.5),
    },
    {
        recipeTitle("Flaglonze"),
        recipeDirtImage("specks"),
        text("Fast scrubbing with Sponge and Shlooze", 0.5),
    },
    {
        text("This is page 5", 0),
    },
    {
        text("This is page 6", 0),
    },
    {
        text("This is page 7", 0),
    },
    {
        text("This is page 8", 0),
    },
    {
        text("This is page 9", 0),
    },
    {
        text("This is page 10", 0),
    },
}

codex.targetPosition = 1
codex.book = nil

function codex.init()
    local fontCache = {}

    assert(#pages % 2 == 0)
    -- gotta make sure pagesH is even
    local pagesX = math.floor(math.sqrt(#pages / 2)) * 2
    local pagesY = math.ceil(#pages / pagesX)
    assert(pagesX % 2 == 0 and pagesX * pagesY >= #pages)

    local fontBackup = lg.getFont()
    local font = assets.bookfont
    lg.setFont(font)

    local pageCoords = {}

    local canvasX = pagesX * pageWidth
    local canvasY = pagesY * pageHeight
    codex.pageImageCanvas = lg.newCanvas(canvasX, canvasY)
    lg.setCanvas(codex.pageImageCanvas)
    --lg.clear(0.87, 0.75, 0.59, 1)
    lg.clear(0, 0, 0, 0)
    local pageMarginX, pageMarginY = 20, 20
    local freePageX = pageWidth - pageMarginX * 2
    local freePageY = pageHeight - pageMarginY * 2
    for p, page in ipairs(pages) do
        local pageX = pageWidth * ((p - 1) % pagesX)
        local pageY = pageHeight * math.floor((p - 1) / pagesX)
        table.insert(pageCoords, {pageX, pageY})

        lg.setColor(1, 1, 1)
        if p % 2 == 1 then
            lg.draw(assets.page, pageX, pageY)
        end
        for e, element in ipairs(page) do
            if element.type == "text" then
                local y = element.y
                if y <= 1.0 then
                    y = math.floor(y * freePageY)
                end
                y = y + pageY + pageMarginY

                local h = font:getHeight() * element.scale
                if element.valign == "middle" then
                    y = y - h / 2
                elseif element.valign == "bottom" then
                    y = y - h
                end

                lg.setColor(element.color)
                local scale = math.floor(element.scale)
                lg.printf(element.text, pageX + pageMarginX, y, freePageX / scale,
                    element.align, 0, scale)
            elseif element.type == "image" then
                local image = assets[element.asset]
                local scale = freePageX / image:getWidth() * element.scale
                local x = pageX + pageWidth / 2 - image:getWidth() / 2 * scale
                local y = pageY + math.floor(element.y * freePageY)
                lg.setColor(1, 1, 1)
                lg.draw(image, x, y, 0, scale)
            elseif element.type == "dirttile" then
                -- copy paste, gotta get done here
                local image = assets[element.asset]
                local scale = freePageX / const.dirtTileSize * element.scale
                local x = pageX + pageWidth / 2 - const.dirtTileSize / 2 * scale
                local y = pageY + math.floor(element.y * freePageY)
                lg.setColor(1, 1, 1)
                lg.draw(image, blobtiles.getQuad(0), x, y, 0, scale)
            end
        end
    end
    lg.setCanvas()
    lg.setFont(fontBackup)
    codex.pageImageCanvas:setFilter("nearest", "nearest")

    codex.book = Book {
        texture = codex.pageImageCanvas,
        pages = pageCoords,
        pagew = pageWidth,
        pageh = pageHeight,

        startAngle = .3 * math.pi,
        tween = function (x) return math.sin(math.pi * .5 * x) end,
        onFlip = function (self) end,
    }
    codex.book.currentPage = 2
end

function codex.update(dt)
    assert(codex.book)
    local targetPage = 2 * util.math.clamp(codex.targetPosition, 1, #pages / 2)

    local dtFactor = 1
    local pageDiff = targetPage - codex.book.currentPage
    if math.abs(pageDiff) > 0 then
        if not codex.book:isFlipping() then
            local dir = pageDiff < 0 and "right" or "left"
            codex.book:startFlip(dir, 1) -- use 1 for duration, because we adjust with dt
        else
            dtFactor = math.abs(pageDiff) / 2
        end
    end
    codex.book:update(dt * dtFactor)
end

function codex.draw(y)
    assert(codex.book)
    lg.setColor(1, 1, 1, 1)
    local backX = const.resX / 2 - assets.bookBack:getWidth() / 2
    lg.draw(assets.bookBack, backX, y - 15) -- yeees, harcoded shit
    local x = const.resX / 2 - pageWidth
    codex.book:draw(x, y)
end


return codex