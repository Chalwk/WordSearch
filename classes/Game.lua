-- Word Search Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_random = math.random
local table_insert = table.insert
local table_remove = table.remove

local WordBank = require("classes/WordBank")

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 1000
    instance.screenHeight = 700
    instance.wordBank = WordBank.new()
    instance.words = {}
    instance.wordsUpper = {}
    instance.foundWords = {}
    instance.grid = {}
    instance.gridSize = 10
    instance.cellSize = 40
    instance.gridX = 0
    instance.gridY = 0
    instance.gameOver = false
    instance.selectedCells = {}
    instance.isSelecting = false
    instance.selectionStart = nil
    instance.selectionEnd = nil
    instance.animations = {}
    instance.particles = {}
    instance.hintsAvailable = 3
    instance.score = 0
    instance.combo = 0
    instance.comboTimer = 0
    instance.comboDuration = 3

    -- Directions: right, left, down, up, down-right, down-left, up-right, up-left
    instance.directions = {
        { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 }
    }

    -- Preload fonts for performance
    instance:loadFonts()

    return instance
end

function Game:loadFonts()
    self.fonts = {}
    for size = 12, 40 do
        self.fonts[size] = love.graphics.newFont(size)
    end
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:calculateGridPosition()
end

function Game:calculateGridPosition()
    local gridWidth = self.gridSize * self.cellSize
    local gridHeight = self.gridSize * self.cellSize
    self.gridX = (self.screenWidth - gridWidth) / 2
    self.gridY = (self.screenHeight - gridHeight) / 2 - 20
end

function Game:startNewGame(difficulty, category, gridSize)
    self.difficulty = difficulty or "medium"
    self.category = category or "general"
    self.gridSize = tonumber(gridSize) or 10
    self.cellSize = math.min(40, 500 / self.gridSize)

    self:calculateGridPosition()
    self.words = self.wordBank:getWordList(self.difficulty, self.category, self.gridSize)
    self.wordsUpper = {}
    for i, w in ipairs(self.words) do
        self.wordsUpper[i] = w:upper()
    end

    self.foundWords = {}
    self.selectedCells = {}
    self.gameOver = false
    self.hintsAvailable = 3
    self.score = 0
    self.combo = 0
    self.comboTimer = 0
    self.animations = {}
    self.particles = {}

    self:generateGrid()
    self:placeWords()
    self:fillEmptyCells()
end

function Game:generateGrid()
    self.grid = {}
    for y = 1, self.gridSize do
        self.grid[y] = {}
        for x = 1, self.gridSize do
            self.grid[y][x] = {
                letter = " ",
                found = false,
                hint = false
            }
        end
    end
end

function Game:placeWords()
    local placedWords = {}

    for idx, word in ipairs(self.wordsUpper) do
        local placed = false
        local attempts = 0
        local maxAttempts = 100

        while not placed and attempts < maxAttempts do
            attempts = attempts + 1

            local dir = self.directions[math_random(#self.directions)]
            local dx, dy = dir[1], dir[2]

            local startX = math_random(1, self.gridSize)
            local startY = math_random(1, self.gridSize)

            local endX = startX + dx * (#word - 1)
            local endY = startY + dy * (#word - 1)

            if endX >= 1 and endX <= self.gridSize and endY >= 1 and endY <= self.gridSize then
                local canPlace = true
                local cellsToUpdate = {}

                for i = 1, #word do
                    local x = startX + dx * (i - 1)
                    local y = startY + dy * (i - 1)
                    local cell = self.grid[y][x]
                    local requiredLetter = word:sub(i, i)

                    if cell.letter ~= " " and cell.letter ~= requiredLetter then
                        canPlace = false
                        break
                    end
                    table_insert(cellsToUpdate, { x = x, y = y, letter = requiredLetter, position = i })
                end

                if canPlace then
                    for _, cellInfo in ipairs(cellsToUpdate) do
                        local x, y = cellInfo.x, cellInfo.y
                        local existingCell = self.grid[y][x]

                        if existingCell.letter == " " then
                            self.grid[y][x] = {
                                letter = cellInfo.letter,
                                found = false,
                                hint = false,
                                word = word,
                                position = cellInfo.position,
                                direction = { dx, dy }
                            }
                        else
                            self.grid[y][x].word = word
                            self.grid[y][x].position = cellInfo.position
                            self.grid[y][x].direction = { dx, dy }
                        end
                    end

                    table_insert(placedWords, {
                        word = word,
                        startX = startX,
                        startY = startY,
                        direction = { dx, dy }
                    })

                    placed = true
                end
            end
        end

        if not placed then
            print("Warning: Could not place word: " .. self.words[idx])
        end
    end

    self.placedWords = placedWords
end

function Game:fillEmptyCells()
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for y = 1, self.gridSize do
        for x = 1, self.gridSize do
            if self.grid[y][x].letter == " " then
                local randIndex = math_random(1, #letters)
                self.grid[y][x] = {
                    letter = letters:sub(randIndex, randIndex),
                    found = false,
                    hint = false
                }
            end
        end
    end
end

function Game:update(dt)
    if self.combo > 0 then
        self.comboTimer = self.comboTimer + dt
        if self.comboTimer >= self.comboDuration then
            self.combo = 0
            self.comboTimer = 0
        end
    end

    -- Update animations using swap-remove
    local i = 1
    while i <= #self.animations do
        local anim = self.animations[i]
        anim.progress = anim.progress + dt / anim.duration
        if anim.progress >= 1 then
            self.animations[i] = self.animations[#self.animations]
            self.animations[#self.animations] = nil
        else
            i = i + 1
        end
    end

    -- Update particles using swap-remove
    local j = 1
    while j <= #self.particles do
        local particle = self.particles[j]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt
        if particle.life <= 0 then
            self.particles[j] = self.particles[#self.particles]
            self.particles[#self.particles] = nil
        else
            j = j + 1
        end
    end
end

function Game:draw()
    self:drawGrid()
    self:drawWordList()
    self:drawUI()
    self:drawParticles()

    if self.gameOver then
        self:drawGameOver()
    end
end

function Game:drawGrid()
    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", self.gridX - 10, self.gridY - 10,
        self.gridSize * self.cellSize + 20, self.gridSize * self.cellSize + 20, 5)

    for y = 1, self.gridSize do
        for x = 1, self.gridSize do
            local cell = self.grid[y][x]
            local cellX = self.gridX + (x - 1) * self.cellSize
            local cellY = self.gridY + (y - 1) * self.cellSize

            if cell.found then
                local wordIndex = self:getWordIndex(cell.word)
                local hue = (wordIndex * 137.5) % 360
                local r, g, b = self:hsvToRgb(hue / 360, 0.7, 0.8)
                love.graphics.setColor(r, g, b, 0.3)
                love.graphics.rectangle("fill", cellX, cellY, self.cellSize, self.cellSize)
            elseif self:isCellSelected(x, y) then
                love.graphics.setColor(0.3, 0.5, 0.8, 0.5)
                love.graphics.rectangle("fill", cellX, cellY, self.cellSize, self.cellSize)
            elseif cell.hint then
                love.graphics.setColor(1, 0.8, 0.2, 0.3)
                love.graphics.rectangle("fill", cellX, cellY, self.cellSize, self.cellSize)
            end

            love.graphics.setColor(0.5, 0.5, 0.6)
            love.graphics.rectangle("line", cellX, cellY, self.cellSize, self.cellSize)

            local fontSize = math.max(12, math.floor(self.cellSize * 0.6))
            love.graphics.setFont(self.fonts[fontSize])

            if cell.found then
                love.graphics.setColor(1, 1, 1)
            elseif cell.hint then
                love.graphics.setColor(1, 0.8, 0.2)
            else
                love.graphics.setColor(0.8, 0.8, 0.9)
            end

            local font = self.fonts[fontSize]
            local textWidth = font:getWidth(cell.letter)
            local textHeight = font:getHeight()
            local scale = math.min(1, (self.cellSize * 0.8) / math.max(textWidth, textHeight))

            love.graphics.print(cell.letter,
                cellX + (self.cellSize - textWidth * scale) / 2,
                cellY + (self.cellSize - textHeight * scale) / 2,
                0, scale, scale)
        end
    end

    if self.isSelecting and self.selectionStart and self.selectionEnd then
        self:drawSelectionLine()
    end

    self:drawFoundWordLines()
end

function Game:drawSelectionLine()
    local startX = self.gridX + (self.selectionStart.x - 1) * self.cellSize + self.cellSize / 2
    local startY = self.gridY + (self.selectionStart.y - 1) * self.cellSize + self.cellSize / 2
    local endX = self.gridX + (self.selectionEnd.x - 1) * self.cellSize + self.cellSize / 2
    local endY = self.gridY + (self.selectionEnd.y - 1) * self.cellSize + self.cellSize / 2

    love.graphics.setColor(0, 1, 1, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.line(startX, startY, endX, endY)
    love.graphics.setLineWidth(1)
end

function Game:drawFoundWordLines()
    for _, placedWord in ipairs(self.placedWords) do
        if self:isWordFound(placedWord.word) then
            local startX = self.gridX + (placedWord.startX - 1) * self.cellSize + self.cellSize / 2
            local startY = self.gridY + (placedWord.startY - 1) * self.cellSize + self.cellSize / 2
            local endX = startX + placedWord.direction[1] * (#placedWord.word - 1) * self.cellSize
            local endY = startY + placedWord.direction[2] * (#placedWord.word - 1) * self.cellSize

            -- Rainbow gradient line
            love.graphics.setLineWidth(4)
            self:drawRainbowLine(startX, startY, endX, endY)
            love.graphics.setLineWidth(1)
        end
    end
end

function Game:drawRainbowLine(x1, y1, x2, y2)
    local segments = 20
    for i = 0, segments - 1 do
        local t1 = i / segments
        local t2 = (i + 1) / segments

        local segX1 = x1 + (x2 - x1) * t1
        local segY1 = y1 + (y2 - y1) * t1
        local segX2 = x1 + (x2 - x1) * t2
        local segY2 = y1 + (y2 - y1) * t2

        local hue = (i / segments) * 360
        local r, g, b = self:hsvToRgb(hue / 360, 0.8, 1)
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.line(segX1, segY1, segX2, segY2)
    end
end

function Game:drawWordList()
    local listX = 50
    local listY = 50
    local listWidth = 200

    love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
    love.graphics.rectangle("fill", listX - 10, listY - 10, listWidth - 10, 300, 5)

    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.print("Words to Find:", listX, listY)

    love.graphics.setFont(love.graphics.newFont(16))
    for i, word in ipairs(self.words) do
        local y = listY + 30 + (i - 1) * 25

        if self:isWordFound(word) then
            love.graphics.setColor(0.2, 0.8, 0.2)
            love.graphics.print(word, listX, y)
        else
            love.graphics.setColor(0.8, 0.8, 0.9)
            love.graphics.print(word, listX, y)
        end
    end
end

function Game:drawUI()
    -- Score and combo
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.print("Score: " .. self.score, self.screenWidth - 200, 50)

    if self.combo > 0 then
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print("Combo: x" .. self.combo, self.screenWidth - 200, 80)

        -- Combo timer bar
        local barWidth = 100
        local barHeight = 10
        local progress = 1 - (self.comboTimer / self.comboDuration)

        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", self.screenWidth - 200, 100, barWidth, barHeight)
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.rectangle("fill", self.screenWidth - 200, 100, barWidth * progress, barHeight)
    end

    -- Hints
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.print("Hints: " .. self.hintsAvailable, self.screenWidth - 200, 130)

    -- Controls
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("Press R to reset selection", self.screenWidth - 200, 160)
    love.graphics.print("Press H for hint", self.screenWidth - 200, 180)
    love.graphics.print("Press ESC for menu", self.screenWidth - 200, 200)

    -- Hint button
    if self.hintsAvailable > 0 and not self.gameOver then
        love.graphics.setColor(0.3, 0.7, 1)
        love.graphics.rectangle("line", self.screenWidth - 140, 220, 120, 40, 5)
        love.graphics.setColor(0.3, 0.7, 1, 0.3)
        love.graphics.rectangle("fill", self.screenWidth - 140, 220, 120, 40, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.print("Use Hint", self.screenWidth - 130, 232)
    end

    -- Reset button
    if not self.gameOver then
        love.graphics.setColor(0.8, 0.6, 0.2)
        love.graphics.rectangle("line", self.screenWidth - 140, 270, 120, 40, 5)
        love.graphics.setColor(0.8, 0.6, 0.2, 0.3)
        love.graphics.rectangle("fill", self.screenWidth - 140, 270, 120, 40, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.print("Reset Game", self.screenWidth - 130, 282)
    end
end

function Game:drawParticles()
    for _, particle in ipairs(self.particles) do
        local alpha = math.min(1, particle.life * 2)
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.print(particle.char, particle.x, particle.y, 0, particle.size / 20)
    end
end

function Game:drawGameOver()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    local font = love.graphics.newFont(48)
    love.graphics.setFont(font)
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.printf("PUZZLE COMPLETE!", 0, self.screenHeight / 2 - 80, self.screenWidth, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Final Score: " .. self.score, 0, self.screenHeight / 2, self.screenWidth, "center")

    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf("Click anywhere to continue", 0, self.screenHeight / 2 + 60, self.screenWidth, "center")
end

function Game:handleMousePress(x, y)
    if self.gameOver then
        return
    end

    -- Check UI buttons
    if x >= self.screenWidth - 140 and x <= self.screenWidth - 20 then
        if y >= 220 and y <= 260 then
            self:useHint()
            return
        elseif y >= 270 and y <= 310 then
            self:resetGame()
            return
        end
    end

    -- Start selection
    local gridPos = self:screenToGrid(x, y)
    if gridPos then
        self.isSelecting = true
        self.selectionStart = gridPos
        self.selectionEnd = gridPos
        self.selectedCells = { gridPos }
    end
end

function Game:handleMouseRelease(x, y)
    if not self.isSelecting then return end

    self.isSelecting = false

    if #self.selectedCells >= 2 then
        self:checkWord()
    end

    self.selectedCells = {}
end

function Game:handleMouseMove(x, y)
    if not self.isSelecting then return end

    local gridPos = self:screenToGrid(x, y)
    if gridPos and gridPos ~= self.selectionEnd then
        self.selectionEnd = gridPos
        self.selectedCells = self:getCellsInLine(self.selectionStart, self.selectionEnd)
    end
end

function Game:screenToGrid(x, y)
    if x < self.gridX or x > self.gridX + self.gridSize * self.cellSize or
        y < self.gridY or y > self.gridY + self.gridSize * self.cellSize then
        return nil
    end

    local gridX = math.floor((x - self.gridX) / self.cellSize) + 1
    local gridY = math.floor((y - self.gridY) / self.cellSize) + 1

    if gridX >= 1 and gridX <= self.gridSize and gridY >= 1 and gridY <= self.gridSize then
        return { x = gridX, y = gridY }
    end

    return nil
end

function Game:getCellsInLine(start, end_)
    local cells = {}
    local dx = end_.x - start.x
    local dy = end_.y - start.y

    -- Check if selection is straight line
    if dx == 0 or dy == 0 or math.abs(dx) == math.abs(dy) then
        local steps = math.max(math.abs(dx), math.abs(dy))
        local stepX = (dx > 0 and 1) or (dx < 0 and -1) or 0
        local stepY = (dy > 0 and 1) or (dy < 0 and -1) or 0

        for i = 0, steps do
            local x = start.x + i * stepX
            local y = start.y + i * stepY
            if x >= 1 and x <= self.gridSize and y >= 1 and y <= self.gridSize then
                table_insert(cells, { x = x, y = y })
            end
        end
    end

    return cells
end

function Game:isCellSelected(x, y)
    for _, cell in ipairs(self.selectedCells) do
        if cell.x == x and cell.y == y then
            return true
        end
    end
    return false
end

function Game:checkWord()
    if #self.selectedCells < 2 then return end

    local selectedWord = ""
    for _, cell in ipairs(self.selectedCells) do
        selectedWord = selectedWord .. self.grid[cell.y][cell.x].letter
    end

    for idx, wordUpper in ipairs(self.wordsUpper) do
        if selectedWord == wordUpper or selectedWord == wordUpper:reverse() then
            local word = self.words[idx]
            if not self:isWordFound(word) then
                self:markWordFound(word, self.selectedCells)
                return true
            end
        end
    end

    return false
end

function Game:markWordFound(word, cells)
    table_insert(self.foundWords, word)

    -- Mark cells as found
    for _, cell in ipairs(cells) do
        self.grid[cell.y][cell.x].found = true
        self.grid[cell.y][cell.x].hint = false
    end

    -- Calculate score
    local wordScore = #word * 10
    if self.combo > 0 then
        wordScore = wordScore * self.combo
    end
    self.score = self.score + wordScore

    -- Increase combo
    self.combo = self.combo + 1
    self.comboTimer = 0

    -- Create celebration particles
    for _, cell in ipairs(cells) do
        self:createWordParticles(cell.x, cell.y, word)
    end

    -- Check if game is over
    if #self.foundWords == #self.words then
        self.gameOver = true
        self:createCompletionParticles()
    end
end

function Game:createWordParticles(x, y, word)
    local cellX = self.gridX + (x - 1) * self.cellSize + self.cellSize / 2
    local cellY = self.gridY + (y - 1) * self.cellSize + self.cellSize / 2

    for i = 1, 8 do
        table_insert(self.particles, {
            x = cellX,
            y = cellY,
            dx = (math_random() - 0.5) * 200,
            dy = (math_random() - 0.5) * 200 - 50,
            life = math_random(1.0, 2.0),
            color = { math_random(), math_random(), math_random() },
            size = math_random(8, 15),
            char = word:sub(math_random(1, #word))
        })
    end
end

function Game:createCompletionParticles()
    for i = 1, 50 do
        table_insert(self.particles, {
            x = math_random(self.screenWidth),
            y = math_random(self.screenHeight),
            dx = (math_random() - 0.5) * 300,
            dy = (math_random() - 0.5) * 300,
            life = math_random(2.0, 4.0),
            color = { math_random(), math_random(), math_random() },
            size = math_random(10, 20),
            char = string.char(math_random(65, 90))
        })
    end
end

function Game:useHint()
    if self.hintsAvailable <= 0 or self.gameOver then return end

    -- Find an unfound word
    local unfoundWords = {}
    for _, word in ipairs(self.words) do
        if not self:isWordFound(word) then
            table_insert(unfoundWords, word)
        end
    end

    if #unfoundWords > 0 then
        local hintWord = unfoundWords[math_random(#unfoundWords)]

        -- Find the word in the grid and highlight one letter
        for _, placedWord in ipairs(self.placedWords) do
            if placedWord.word == hintWord:upper() then
                local letterIndex = math_random(#hintWord)
                local x = placedWord.startX + placedWord.direction[1] * (letterIndex - 1)
                local y = placedWord.startY + placedWord.direction[2] * (letterIndex - 1)

                if x >= 1 and x <= self.gridSize and y >= 1 and y <= self.gridSize then
                    self.grid[y][x].hint = true

                    -- Create hint particles
                    self:createHintParticles(x, y)

                    self.hintsAvailable = self.hintsAvailable - 1
                    return
                end
            end
        end
    end
end

function Game:createHintParticles(x, y)
    local cellX = self.gridX + (x - 1) * self.cellSize + self.cellSize / 2
    local cellY = self.gridY + (y - 1) * self.cellSize + self.cellSize / 2

    for i = 1, 12 do
        table_insert(self.particles, {
            x = cellX,
            y = cellY,
            dx = (math_random() - 0.5) * 100,
            dy = (math_random() - 0.5) * 100,
            life = math_random(1.5, 2.5),
            color = { 1, 0.8, 0.2 },
            size = math_random(6, 12),
            char = "?"
        })
    end
end

function Game:resetSelection()
    self.selectedCells = {}
    self.isSelecting = false
end

function Game:resetGame()
    self:startNewGame(self.difficulty, self.category, self.gridSize)
end

function Game:isWordFound(word)
    for _, foundWord in ipairs(self.foundWords) do
        if foundWord:upper() == word:upper() then
            return true
        end
    end
    return false
end

function Game:getWordIndex(word)
    for i, w in ipairs(self.words) do
        if w:upper() == word then
            return i
        end
    end
    return 1
end

function Game:hsvToRgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end

    return r, g, b
end

return Game
