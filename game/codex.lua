local Book = require("libs.book")

local codex = {}

-- ASSET: open book sound, close book sound, flip page sound
-- ASSET: study sound "mmhm"

local pageWidth = 300
local pageHeight = 350

local function text(text, x, y, params)
    params = params or {}
    return {
        type = "text",
        text = text,
        x = x, y = y,
        size = params.size or 16,
        align = params.align or "left",
        valign = params.valign or "top",
        color = params.color or {1, 1, 1, 1},
    }
end

local pages = {
    {
        text("TOME OF FILTH", 0.5, 0.5, {size = 35, align = "center", valign = "middle"}),
    },
    {
        text("TEST\nTEST\nFOOBAR", 0, 0),
    },
    {
        text("Hello Pablo!", 0, 0),
    },
    {
        text("This is page 4", 0, 0),
    },
    {
        text("This is page 5", 0, 0),
    },
    {
        text("This is page 6", 0, 0),
    },
    {
        text("This is page 7", 0, 0),
    },
    {
        text("This is page 8", 0, 0),
    },
    {
        text("This is page 9", 0, 0),
    },
    {
        text("This is page 10", 0, 0),
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

    local pageCoords = {}

    local canvasX = pagesX * pageWidth
    local canvasY = pagesY * pageHeight
    print(canvasX, canvasY)
    codex.pageImageCanvas = lg.newCanvas(canvasX, canvasY)
    lg.setCanvas(codex.pageImageCanvas)
    lg.clear(0, 0, 0, 1)
    local pageMargin = 3
    for p, page in ipairs(pages) do
        local pageX = pageWidth * ((p - 1) % pagesX)
        local pageY = pageHeight * math.floor((p - 1) / pagesX)
        table.insert(pageCoords, {pageX, pageY})
        lg.setColor(1, 1, 1)
        lg.rectangle("line", pageX, pageY, pageWidth, pageHeight)
        for e, element in ipairs(page) do
            if element.type == "text" then
                if not fontCache[element.size] then
                    fontCache[element.size] = lg.newFont(element.size)
                end
                local font = fontCache[element.size]

                local x = element.x
                if x <= 1.0 then
                    x = x * math.floor(pageWidth - pageMargin * 2)
                end
                x = x + pageX + pageMargin
                local y = element.y
                if y <= 1.0 then
                    y = y * math.floor(pageHeight - pageMargin * 2)
                end
                y = y + pageY + pageMargin

                if element.align == "center" then
                    x = x - font:getWidth(element.text) / 2
                elseif element.align == "right" then
                    x = x - font:getWidth(element.text)
                end

                if element.valign == "middle" then
                    y = y - font:getHeight() / 2
                elseif element.valign == "bottom" then
                    y = y - font:getHeight()
                end

                lg.setColor(element.color)
                lg.setFont(font)
                lg.print(element.text, x, y)
            end
        end
    end
    lg.setCanvas()
    lg.setFont(fontBackup)

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

    local pageDiff = targetPage - codex.book.currentPage
    if math.abs(pageDiff) > 0 and not codex.book:isFlipping() then
        local dir = pageDiff < 0 and "right" or "left"
        codex.book:startFlip(dir, 1) -- use 1 for duration, because we adjust with dt
    end
    codex.book:update(dt * math.abs(pageDiff) / 2)
end

function codex.draw()
    assert(codex.book)
    local x = const.resX / 2 - pageWidth
    local y = const.resY / 2 - pageHeight / 2
    codex.book:draw(x, y)
end


return codex