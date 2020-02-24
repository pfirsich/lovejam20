local function parseColor(str)
    -- strip leading '#'
    assert(str:len() == 6)
    return {
        tonumber(str:sub(1, 2), 16) / 255.0,
        tonumber(str:sub(3, 4), 16) / 255.0,
        tonumber(str:sub(5, 6), 16) / 255.0,
    }
end

return {
    -- https://lospec.com/palette-list/koni32
    palette = {
        parseColor("000000"),
        parseColor("0b0a0d"),
        parseColor("161524"),
        parseColor("222640"),
        parseColor("2b4057"),
        parseColor("306566"),
        parseColor("34a870"),
        parseColor("49f25a"),
        parseColor("a4ff63"),
        parseColor("fff240"),
        parseColor("f2a53f"),
        parseColor("cc7a47"),
        parseColor("f54025"),
        parseColor("a63a3a"),
        parseColor("995348"),
        parseColor("733758"),
        parseColor("4d2a49"),
        parseColor("46346a"),
        parseColor("8c2eb8"),
        parseColor("f261da"),
        parseColor("ffa8d4"),
        parseColor("b3dfff"),
        parseColor("70a5fa"),
        parseColor("407cff"),
        parseColor("1f50cc"),
        parseColor("213ea6"),
        parseColor("272f66"),
        parseColor("414558"),
        parseColor("6d7078"),
        parseColor("898b8c"),
        parseColor("bbbdbf"),
        parseColor("ffffff"),
    },
}