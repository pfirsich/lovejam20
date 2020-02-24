local gui = {}

function gui.drawButton(text, x, y, w, h, hovered, marked, style)
    if hovered then
        lg.setColor(style.hoverBgColor)
    else
        if marked then
            lg.setColor(style.markedBgColor)
        else
            lg.setColor(style.bgColor)
        end
    end
    lg.rectangle("fill", x, y, w, h)
    if marked then
        lg.setColor(style.markedOutlineColor)
    else
        lg.setColor(style.outlineColor)
    end
    lg.rectangle("line", x, y, w, h)

    local textX = x + style.textPadding
    local fontH = lg.getFont():getHeight()
    local textY = math.floor(y + h / 2 - fontH / 2)
    lg.setColor(style.textColor)
    lg.printf(text, textX, textY,
        w - style.textPadding * 2, style.textAlign or "center")
end

return gui