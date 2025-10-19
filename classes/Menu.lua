-- Word Search Game - Love2D
-- Menu Layout Fixes
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_sin = math.sin
local math_floor = math.floor
local table_insert = table.insert

local helpText = {
    "Find all the hidden words in the grid!",
    "",
    "How to Play:",
    "• Click and drag to select letters",
    "• Words can be in any direction",
    "• Found words will be highlighted",
    "",
    "Controls:",
    "• R - Reset selection",
    "• H - Use hint",
    "• ESC - Return to menu",
    "",
    "Features:",
    "• Combo system for consecutive finds",
    "• Rainbow highlighting for found words",
    "• Particle effects and animations",
    "",
    "Click anywhere to close"
}

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local instance = setmetatable({}, Menu)

    instance.screenWidth = 1000
    instance.screenHeight = 700
    instance.difficulty = "medium"
    instance.category = "general"
    instance.gridSize = "10"
    instance.title = {
        text = "WORD SEARCH",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.3,
        minScale = 0.95,
        maxScale = 1.05,
        rotation = 0,
        rotationSpeed = 0.2
    }
    instance.showHelp = false

    -- Fonts
    instance.smallFont = love.graphics.newFont(16)
    instance.mediumFont = love.graphics.newFont(22)
    instance.largeFont = love.graphics.newFont(42)
    instance.sectionFont = love.graphics.newFont(20)

    instance:createMenuButtons()
    instance:createOptionsButtons()

    return instance
end

function Menu:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:updateButtonPositions()
    self:updateOptionsButtonPositions()
end

function Menu:createMenuButtons()
    self.menuButtons = {
        { text = "Start Game", action = "start",   width = 200, height = 50, x = 0, y = 0 },
        { text = "Options",    action = "options", width = 200, height = 50, x = 0, y = 0 },
        { text = "Quit",       action = "quit",    width = 200, height = 50, x = 0, y = 0 } -- fixed
    }

    -- Help button
    self.helpButton = { text = "?", action = "help", width = 40, height = 40, x = 30, y = self.screenHeight - 50 }

    self:updateButtonPositions()
end

function Menu:createOptionsButtons()
    self.optionsButtons = {}

    -- Difficulty buttons
    local difficulties = { "Easy", "Medium", "Hard" }
    for _, diff in ipairs(difficulties) do
        table_insert(self.optionsButtons, {
            text = diff,
            action = "diff " .. diff:lower(),
            width = 120,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty"
        })
    end

    -- Category buttons
    local categories = { "General", "Animals", "Science", "Geography" }
    for _, cat in ipairs(categories) do
        table_insert(self.optionsButtons, {
            text = cat,
            action = "cate " .. cat:lower(),
            width = 140,
            height = 40,
            x = 0,
            y = 0,
            section = "category"
        })
    end

    -- Grid size buttons
    local sizes = { "8x8", "10x10", "12x12", "15x15" }
    for _, size in ipairs(sizes) do
        table_insert(self.optionsButtons, {
            text = size,
            action = "size " .. size:match("%d+"),
            width = 100,
            height = 40,
            x = 0,
            y = 0,
            section = "size"
        })
    end

    -- Navigation
    table_insert(self.optionsButtons, {
        text = "Back to Menu",
        action = "back",
        width = 180,
        height = 50,
        x = 0,
        y = 0,
        section = "navigation"
    })

    self:updateOptionsButtonPositions()
end

function Menu:updateButtonPositions()
    local startY = self.screenHeight / 2 - 50
    for i, button in ipairs(self.menuButtons) do
        button.x = (self.screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 70
    end
    self.helpButton.y = self.screenHeight - 60
end

function Menu:updateOptionsButtonPositions()
    local centerX = self.screenWidth / 2
    local startY = 150 + 30 -- shifted down by 30 pixels

    -- Difficulty
    local diffButtons = {}
    for _, b in ipairs(self.optionsButtons) do
        if b.section == "difficulty" then table_insert(diffButtons, b) end
    end
    local totalDiffW = #diffButtons * (diffButtons[1].width + 15) - 15
    for i, b in ipairs(diffButtons) do
        b.x = centerX - totalDiffW / 2 + (i - 1) * (b.width + 15)
        b.y = startY
    end

    -- Category (2x2)
    local cateButtons = {}
    for _, b in ipairs(self.optionsButtons) do
        if b.section == "category" then table_insert(cateButtons, b) end
    end
    local cateStartY = startY + 80
    local cateSpacingX, cateSpacingY = 20, 15
    local cateTotalW = 2 * cateButtons[1].width + cateSpacingX
    for i, b in ipairs(cateButtons) do
        b.x = centerX - cateTotalW / 2 + ((i - 1) % 2) * (b.width + cateSpacingX)
        b.y = cateStartY + math_floor((i - 1) / 2) * (b.height + cateSpacingY)
    end

    -- Grid size
    local sizeButtons = {}
    for _, b in ipairs(self.optionsButtons) do
        if b.section == "size" then table_insert(sizeButtons, b) end
    end
    local sizeTotalW = #sizeButtons * (sizeButtons[1].width + 15) - 15
    local sizeY = cateStartY + 100 + 45 -- original offset preserved
    for i, b in ipairs(sizeButtons) do
        b.x = centerX - sizeTotalW / 2 + (i - 1) * (b.width + 15)
        b.y = sizeY
    end

    -- Navigation
    for _, b in ipairs(self.optionsButtons) do
        if b.section == "navigation" then
            b.x = centerX - b.width / 2
            b.y = sizeY + 80
        end
    end
end

function Menu:update(dt, screenWidth, screenHeight)
    if screenWidth ~= self.screenWidth or screenHeight ~= self.screenHeight then
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self:updateButtonPositions()
        self:updateOptionsButtonPositions()
    end

    -- Update title animation
    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt

    if self.title.scale > self.title.maxScale then
        self.title.scale = self.title.maxScale
        self.title.scaleDirection = -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale = self.title.minScale
        self.title.scaleDirection = 1
    end

    self.title.rotation = self.title.rotation + self.title.rotationSpeed * dt
end

function Menu:draw(screenWidth, screenHeight, state)
    -- Draw animated title
    love.graphics.setColor(0.2, 0.6, 0.9)
    love.graphics.setFont(self.largeFont)

    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 6)
    love.graphics.rotate(math_sin(self.title.rotation) * 0.05)
    love.graphics.scale(self.title.scale, self.title.scale)
    love.graphics.printf(self.title.text, -screenWidth / 2, -self.largeFont:getHeight() / 2, screenWidth, "center")
    love.graphics.pop()

    if state == "menu" then
        if self.showHelp then
            self:drawHelpOverlay(screenWidth, screenHeight)
        else
            self:drawMenuButtons()
            -- Draw instructions
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.setFont(self.smallFont)
            love.graphics.printf("Find hidden words in any direction!\nClick and drag to select letters.",
                0, screenHeight / 4 + 50, screenWidth, "center")

            -- Draw help button
            self:drawHelpButton()
        end
    elseif state == "options" then
        self:drawOptionsInterface()
    end

    -- Draw copyright
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("© 2025 Jericho Crosby – Word Search", 10, screenHeight - 25, screenWidth - 20, "right")
end

function Menu:drawHelpButton()
    local button = self.helpButton

    -- Button background
    love.graphics.setColor(0.3, 0.5, 0.8, 0.8)
    love.graphics.circle("fill", button.x + button.width / 2, button.y + button.height / 2, button.width / 2)

    -- Button border
    love.graphics.setColor(0.6, 0.7, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", button.x + button.width / 2, button.y + button.height / 2, button.width / 2)

    -- Question mark
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.mediumFont)

    local textWidth = self.mediumFont:getWidth(button.text)
    local textHeight = self.mediumFont:getHeight()

    love.graphics.print(button.text,
        button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    love.graphics.setLineWidth(1)
end

function Menu:drawHelpOverlay(screenWidth, screenHeight)
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Help box
    local boxWidth = 600
    local boxHeight = 500
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = (screenHeight - boxHeight) / 2

    -- Box background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10)

    -- Box border
    love.graphics.setColor(0.3, 0.5, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.largeFont)
    love.graphics.printf("How to Play", boxX, boxY + 20, boxWidth, "center")

    -- Help text
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setFont(self.smallFont)

    local lineHeight = 22
    for i, line in ipairs(helpText) do
        local y = boxY + 80 + (i - 1) * lineHeight
        love.graphics.printf(line, boxX + 30, y, boxWidth - 60, "left")
    end

    love.graphics.setLineWidth(1)
end

function Menu:drawOptionsInterface()
    local startY = 150 + 30 -- shifted down by 30 pixels
    love.graphics.setFont(self.sectionFont)
    love.graphics.setColor(0.8, 0.8, 1)

    love.graphics.printf("Difficulty", 0, startY - 30, self.screenWidth, "center")
    love.graphics.printf("Category", 0, startY + 50, self.screenWidth, "center")
    love.graphics.printf("Grid Size", 0, startY + 190, self.screenWidth, "center")

    self:updateOptionsButtonPositions()
    self:drawOptionSection("difficulty")
    self:drawOptionSection("category")
    self:drawOptionSection("size")
    self:drawOptionSection("navigation")
end

function Menu:drawOptionSection(section)
    for _, button in ipairs(self.optionsButtons) do
        if button.section == section then
            self:drawButton(button)

            -- Draw selection highlight
            if button.action:sub(1, 4) == "diff" then
                local difficulty = button.action:sub(6)
                if difficulty == self.difficulty then
                    love.graphics.setColor(0.2, 0.8, 0.2, 0.4)
                    love.graphics.rectangle("fill", button.x - 3, button.y - 3, button.width + 6, button.height + 6, 5)
                end
            elseif button.action:sub(1, 4) == "cate" then
                local category = button.action:sub(6)
                if category == self.category then
                    love.graphics.setColor(0.2, 0.8, 0.2, 0.4)
                    love.graphics.rectangle("fill", button.x - 3, button.y - 3, button.width + 6, button.height + 6, 5)
                end
            elseif button.action:sub(1, 4) == "size" then
                local size = button.action:sub(6)
                if size == self.gridSize then
                    love.graphics.setColor(0.2, 0.8, 0.2, 0.4)
                    love.graphics.rectangle("fill", button.x - 3, button.y - 3, button.width + 6, button.height + 6, 5)
                end
            end
        end
    end
end

function Menu:drawMenuButtons()
    for _, button in ipairs(self.menuButtons) do
        self:drawButton(button)
    end
end

function Menu:drawButton(button)
    love.graphics.setColor(0.25, 0.25, 0.4, 0.9)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 8, 8)

    love.graphics.setColor(0.6, 0.6, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.mediumFont)

    local textWidth = self.mediumFont:getWidth(button.text)
    local textHeight = self.mediumFont:getHeight()

    love.graphics.print(button.text, button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    love.graphics.setLineWidth(1)
end

function Menu:handleClick(x, y, state)
    local buttons = state == "menu" and self.menuButtons or self.optionsButtons

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end

    -- Check help button in menu state
    if state == "menu" then
        if self.helpButton and x >= self.helpButton.x and x <= self.helpButton.x + self.helpButton.width and
            y >= self.helpButton.y and y <= self.helpButton.y + self.helpButton.height then
            self.showHelp = true
            return "help"
        end

        -- If help is showing, any click closes it
        if self.showHelp then
            self.showHelp = false
            return "help_close"
        end
    end

    return nil
end

function Menu:setDifficulty(difficulty)
    self.difficulty = difficulty
end

function Menu:getDifficulty()
    return self.difficulty
end

function Menu:setCategory(category)
    self.category = category
end

function Menu:getCategory()
    return self.category
end

function Menu:setGridSize(size)
    self.gridSize = size
end

function Menu:getGridSize()
    return self.gridSize
end

return Menu
