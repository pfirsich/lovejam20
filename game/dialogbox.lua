local utf8 = require("utf8")

local function utf8sub(s, from, to)
    local toByte = to and utf8.offset(s, to + 1) - 1 or s:len()
    return s:sub(utf8.offset(s, from), toByte)
end

local DialogBox = class("DialogBox")

function DialogBox:initialize(_lines, defaultCharPerSec, lineDelim)
    defaultCharPerSec = defaultCharPerSec or 50
    self.lineDelim = lineDelim or "\n"
    self.lines = {}
    self.currentLine = 1
    self.lineProgress = 0 -- actually a float
    self.string = ""

    for _, _line in ipairs(_lines) do
        local line = {
            text = _line[1],
            duration = _line[2],
            wait = _line[3]
        }
        line.charCount = utf8.len(line.text)
        if line.duration then
            line.charPerSec = line.charCount / line.duration
        else
            line.charPerSec = defaultCharPerSec
        end
        table.insert(self.lines, line)
    end
end

function DialogBox:skip()
    if self.currentLine < #self.lines then
        self.currentLine = self.currentLine + 1
        self.lineProgress = 0
    elseif self.currentLine == #self.lines then
        self.lineProgress = self.lines[#self.lines].charCount
    end
    self:updateString()
end

function DialogBox:updateString()
    local lines = {}
    for i = 1, self.currentLine - 1 do
        table.insert(lines, self.lines[i].text)
    end
    local curLine = self.lines[self.currentLine]
    local chars = math.min(curLine.charCount, math.floor(self.lineProgress))
    table.insert(lines, utf8sub(curLine.text, 1, chars))
    self.string = table.concat(lines, self.lineDelim)
end

function DialogBox:update(dt)
    local oldLineProgress = math.floor(self.lineProgress)
    local line = self.lines[self.currentLine]
    self.lineProgress = self.lineProgress + line.charPerSec * dt
    local toSkip = line.charCount + line.charPerSec * (line.wait or 0)
    if self.lineProgress >= toSkip then
        self:skip()
    elseif math.floor(self.lineProgress) ~= oldLineProgress then
        self:updateString()
    end
end

function DialogBox:isFinished()
    local line = self.lines[self.currentLine]
    return self.currentLine == #self.lines and self.lineProgress == line.charCount
end

function DialogBox:finish()
    self.currentLine = #self.lines
    self.lineProgress = self.lines[self.currentLine].charCount
    self:updateString()
end

function DialogBox:draw(x, y, limit)
    love.graphics.printf(self.string, x, y, limit)
end

return DialogBox