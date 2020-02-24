local utf8 = require("utf8")

local function utf8sub(s, from, to)
    local toByte = to and utf8.offset(s, to + 1) - 1 or s:len()
    return s:sub(utf8.offset(s, from), toByte)
end

local DialogBox = class("DialogBox")

function DialogBox:initialize(lines, defaultCharPerSec, lineDelim)
    defaultCharPerSec = defaultCharPerSec or 50
    self.lineDelim = lineDelim or "\n"
    self.lines = lines
    self.currentLine = 1
    self.lineProgress = 0 -- actually a float
    self.string = ""

    for _, line in ipairs(lines) do
        line.charCount = utf8.len(line.text)
        if line.duration then
            line.charPerSec = line.charCount / line.duration
        else
            line.charPerSec = defaultCharPerSec
        end
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
    table.insert(lines, utf8sub(curLine.text, 1, math.floor(self.lineProgress)))
    self.string = table.concat(lines, self.lineDelim)
end

function DialogBox:update(dt)
    local oldLineProgress = math.floor(self.lineProgress)
    local line = self.lines[self.currentLine]
    self.lineProgress = self.lineProgress + line.charPerSec * dt
    self.lineProgress = math.min(line.charCount, self.lineProgress)
    if self.lineProgress == line.charCount then
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