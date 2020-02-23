local Book = {}
Book.__index = Book

local vertices = {
  {0, 0, 0, 0, 1, 1, 1, 1}, {0, 0, 0, 0, 1, 1, 1, 1},
  {0, 0, 0, 0, 1, 1, 1, 1}, {0, 0, 0, 0, 1, 1, 1, 1},

  {0, 0, 0, 0, 1, 1, 1, 1}, {0, 0, 0, 0, 1, 1, 1, 1},
  {0, 0, 0, 0, 1, 1, 1, 1}, {0, 0, 0, 0, 1, 1, 1, 1},

  {0, 0, 0, 0, 1, 1, 1, 1}, {0, 0, 0, 0, 1, 1, 1, 1},
  {0, 0, 0, 0, 1, 1, 1, 1}, {0, 0, 0, 0, 1, 1, 1, 1},

  {0, 0, 0, 0, 1, 1, 1, 1}, {0, 0, 0, 0, 1, 1, 1, 1},
  {0, 0, 0, 0, 1, 1, 1, 1}, {0, 0, 0, 0, 1, 1, 1, 1},
}

local mesh = love.graphics.newMesh(16, "triangles", "stream")
mesh:setVertexMap({
  1,  2,  3,  1,  3,  4, --First Page
  5,  6,  7,  5,  7,  8, --Second Page
  9, 11, 10,  9, 12, 11, --Flip Page
 13, 14, 15, 13, 15, 16, --Behind Page
})

local function getDirection (dir)
  if dir ~= "left" and dir ~= "right" then
    error("The provided direction is not valid, please use 'left' or 'right'.", 3)
  end

  return dir == "left" and 1 or -1
end

function Book:startFlip (direction, duration)
  if self._isFlipping then
    error("The book is already doing a flip animation. You can check with book:isFlipping() and use book:stopFlip() to stop it.", 2)
  end

  self._flipDirection = getDirection(direction)

  if self._flipDirection ==  1 and self:isLastPage() then
    error("You are in the last page, can't animate.", 2)
  end

  if self._flipDirection == -1 and self:isFirstPage() then
    error("You are in the first page, can't animate.", 2)
  end

  self._isFlipping = true
  self._flipDuration = duration
end

function Book:stopFlip (forward)
  if forward then
    self.currentPage = self.currentPage + 2 * self._flipDirection
    if self.onFlip then self:onFlip(self) end
  end

  self._flipTimer = 0
  self._flipDirection = 0
  self._flipDuration = 0

  self._isFlipping = false
end

function Book:update(dt)
  if self._isFlipping then
    self._flipTimer = self._flipTimer + dt

    if self._flipTimer >= self._flipDuration then
      self:stopFlip(true)
    end
  end
end

function pushSame (self, n, x, y)
  local behind, flip = vertices[12+n], vertices[8+n]
  local off = self._flipDirection == 1 and self.pagew or 0

  behind[1], behind[2] = off+x, y
  behind[3], behind[4] = x, y

  flip[1],   flip[2]   = off+x, y
  flip[3],   flip[4]   = self.pagew - x, y
end

function pushBasePage (self, b, t)
  local bottom, top, off
  if self._flipDirection == 1 then
    top, bottom, off = vertices[7], vertices[8], self.pagew
  else
    top, bottom, off = vertices[2], vertices[1], 0
  end

  top[1],    top[3]    = off+t, t
  bottom[1], bottom[3] = off+b, b
end


function pushMirror (self, n, x, y, cos, sin)
  local behind, flip = vertices[12+n], vertices[8+n]
  local off = self._flipDirection == 1 and self.pagew or 0

  local dist = math.abs(off - x)

  --Base
  behind[1], behind[2] = off+off, y
  behind[3], behind[4] = off, y
  --Mirror
  flip[1],   flip[2]   = off+x - cos*dist, y - sin*dist
  flip[3],   flip[4]   = self.pagew - off, y
end

local function calculateFlip(self)
  local width, height = self.pagew, self.pageh

  local progress = self._flipTimer / self._flipDuration
  progress = self.tween and self.tween(progress) or progress

  local left = self._flipDirection == 1
  local line = left and width or 0

  local angle = (.5 * math.pi - self.startAngle) * progress + self.startAngle
  local x = width * (left and (1 - progress) or progress)

  local m = math.tan(left and angle or (math.pi - angle))
  local n = 0 - m * x

  local vertical = m * line + n

  local cos = math.cos(math.pi - 2 * angle) * self._flipDirection
  local sin = math.sin(math.pi - 2 * angle)

  pushSame(self, 1, x, height)
  pushMirror(self, 2, x, height, cos, sin)

  if vertical <= height then
    pushSame(self, 3, line, height - vertical)
    pushSame(self, 4, line, height - vertical)
  else
    local horizontal = (height - n) / m
    
    pushBasePage(self, x, horizontal)

    pushMirror(self, 3, horizontal, 0, cos, sin)
    pushSame  (self, 4, horizontal, 0)
  end
end

local coords = {0, 1, 0, 0, 1, 0, 1, 1}
local function calculateBasePages (self)
  for i=1, 4 do
    local x = coords[i*2 - 1] * self.pagew
    local y = coords[i*2    ] * self.pageh

    local left, right = vertices[0+i], vertices[4+i]

    right[1], right[2] = x + self.pagew, y
    right[3], right[4] = x, y
    left[1],  left[2]  = x, y
    left[3],  left[4]  = x, y
  end
end

local function mapPages(self, i)
  if i <= 2 or self._flipDirection == 1 then
    return self.currentPage + i - 2
  end

  return self.currentPage - i + 1
end

local nopage = {0, 0}
local opaque, transparent = 1, 0

local function correctUVs (self)
  local w, h = self.texture:getDimensions()

  for i=1, 4 do
    local page = self.pages[mapPages(self, i)]
    local color = opaque

    if not page then
      page = nopage
      color = transparent
    end

    local offset = (i - 1) * 4
    for n=1, 4 do
      local vertex = vertices[n+offset]

      vertex[3] = (vertex[3] + page[1])/w
      vertex[4] = (vertex[4] + page[2])/h

      vertex[8] = color
    end
  end
end

local function zeroFlip (self)
  for i=1, 4 do
    pushSame(self, i, 0, 0)
  end
end

function Book:draw (x, y)
  calculateBasePages(self)

  if self._isFlipping then
    calculateFlip(self)
  else
    zeroFlip(self)
  end

  correctUVs(self)

  mesh:setVertices(vertices)
  mesh:setTexture(self.texture)
  love.graphics.draw(mesh, x, y)
end

function Book:isFlipping ()
  return self._isFlipping
end

function Book:isLastPage ()
  return self.pages[self.currentPage + 0] == nil or self.pages[self.currentPage + 1] == nil
end

function Book:isFirstPage ()
  return self.pages[self.currentPage - 1] == nil or self.pages[self.currentPage - 2] == nil
end

local function new (book)
  book._flipDirection = 0
  book._flipDuration = 0
  book._flipTimer = 0

  if not book.startAngle then
    book.startAngle = (.25 * math.pi)
  end

  book.currentPage = 1
  book._isFlipping = false

  return setmetatable(book, Book)
end

return new