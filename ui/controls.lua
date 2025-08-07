local Controls = {}

-- Base Control class
Controls.Base = {
    x = 1,
    y = 1,
    width = 1,
    height = 1,
    enabled = true,
    focused = false,
    value = nil
}

function Controls.Base:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Controls.Base:handleInput(event, param)
    return false  -- Base control handles no input
end

-- Dropdown Control
Controls.Dropdown = Controls.Base:new({
    options = {},
    selectedIndex = 1,
    isOpen = false,
    label = ""
})

function Controls.Dropdown:draw()
    if not self.visible then return end
    term.setCursorPos(self.x, self.y)
    term.write(self.label .. " " .. self.value)
    
    if self.isOpen then
        for i, option in ipairs(self.options) do
            term.setCursorPos(self.x, self.y + i)
            term.write(i == self.selectedIndex and "> " .. option or "  " .. option)
        end
    end
end

function Controls.Dropdown:handleInput(event, param)
    if not self.enabled or not self.focused then return false end
    
    if event == "key" then
        if param == 57 then  -- Space
            self.isOpen = not self.isOpen
            return true
        elseif self.isOpen then
            if param == 200 and self.selectedIndex > 1 then  -- Up
                self.selectedIndex = self.selectedIndex - 1
                return true
            elseif param == 208 and self.selectedIndex < #self.options then  -- Down
                self.selectedIndex = self.selectedIndex + 1
                return true
            elseif param == 28 then  -- Enter
                self.value = self.options[self.selectedIndex]
                self.isOpen = false
                return true
            end
        end
    end
    return false
end

-- FileList Control
Controls.FileList = Controls.Base:new({
    items = {},
    selectedIndex = 1,
    scrollOffset = 0
})

function Controls.FileList:draw()
    if not self.visible then return end
    local visibleItems = math.min(self.height, #self.items)
    
    for i = 1, visibleItems do
        local itemIndex = i + self.scrollOffset
        if itemIndex <= #self.items then
            term.setCursorPos(self.x, self.y + i - 1)
            local item = self.items[itemIndex]
            term.write(itemIndex == self.selectedIndex and "> " .. item or "  " .. item)
        end
    end
end

function Controls.FileList:handleInput(event, param)
    if not self.enabled or not self.focused then return false end
    
    if event == "key" then
        if param == 200 and self.selectedIndex > 1 then  -- Up
            self.selectedIndex = self.selectedIndex - 1
            return true
        elseif param == 208 and self.selectedIndex < #self.items then  -- Down
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > self.scrollOffset + self.height then
                self.scrollOffset = self.scrollOffset + 1
            end
            return true
        elseif param == 28 then  -- Enter
            if self.onSelect then
                self.onSelect(self.items[self.selectedIndex])
            end
            return true
        end
    end
    return false
end

-- TextInput Control
Controls.TextInput = Controls.Base:new({
    text = "",
    cursorPos = 1,
    scrollOffset = 0,
    label = ""
})

function Controls.TextInput:draw()
    if not self.visible then return end
    term.setCursorPos(self.x, self.y)
    local visibleText = string.sub(self.text, self.scrollOffset + 1, self.scrollOffset + self.width - #self.label - 1)
    term.write(self.label .. visibleText)
    if self.focused then
        -- Position cursor at actual cursor position
        local cursorScreenPos = self.x + #self.label + (self.cursorPos - self.scrollOffset - 1)
        if cursorScreenPos >= self.x + #self.label and cursorScreenPos < self.x + self.width then
            term.setCursorPos(cursorScreenPos, self.y)
            term.setCursorBlink(true)
        end
    end
end

-- Fix TextInput backspace handling
function Controls.TextInput:handleInput(event, param)
    if not self.visible or not self.focused then return false end
    
    if event == "char" then
        self.text = string.sub(self.text, 1, self.cursorPos - 1) 
            .. param 
            .. string.sub(self.text, self.cursorPos)
        self.cursorPos = self.cursorPos + 1
        -- Adjust scroll if needed
        if self.cursorPos - self.scrollOffset > self.width - #self.label then
            self.scrollOffset = self.cursorPos - (self.width - #self.label)
        end
        return true
    elseif event == "key" then
        if param == 28 then -- Enter
            if self.onSubmit then
                self.onSubmit(self.text)
            end
            local oldText = self.text -- Store text before clearing
            self.text = ""
            self.cursorPos = 1
            self.scrollOffset = 0
            return true, oldText -- Return text for processing
        elseif param == 14 then -- Backspace
            if self.cursorPos > 1 then
                self.text = string.sub(self.text, 1, self.cursorPos - 2) 
                    .. string.sub(self.text, self.cursorPos)
                self.cursorPos = math.max(1, self.cursorPos - 1)
                if self.scrollOffset > 0 and self.cursorPos <= self.scrollOffset then
                    self.scrollOffset = math.max(0, self.scrollOffset - 1)
                end
            end
            return true
        elseif param == 211 then -- Delete
            if self.cursorPos <= #self.text then
                self.text = string.sub(self.text, 1, self.cursorPos - 1) 
                    .. string.sub(self.text, self.cursorPos + 1)
                return true
            end
        elseif param == 203 then -- Left
            self.cursorPos = self.cursorPos - 1
            if self.scrollOffset > 0 and self.cursorPos <= self.scrollOffset then
                self.scrollOffset = self.scrollOffset - 1
            end
            return true
        elseif param == 205 and self.cursorPos <= #self.text then -- Right
            self.cursorPos = self.cursorPos + 1
            if self.cursorPos - self.scrollOffset > self.width - #self.label then
                self.scrollOffset = self.cursorPos - (self.width - #self.label)
            end
            return true
        elseif param == 199 then -- Home
            self.cursorPos = 1
            self.scrollOffset = 0
            return true
        elseif param == 207 then -- End
            self.cursorPos = #self.text + 1
            if #self.text > self.width - #self.label then
                self.scrollOffset = #self.text - (self.width - #self.label)
            end
            return true
        end
    end
    return true  -- Prevent event propagation to main window
end

-- Button Control
Controls.Button = Controls.Base:new({
    label = "",
    onClick = nil
})

function Controls.Button:draw()
    if not self.visible then return end
    term.setCursorPos(self.x, self.y)
    if self.focused then
        term.write("[" .. self.label .. "]")
    else
        term.write(" " .. self.label .. " ")
    end
end

function Controls.Button:handleInput(event, param)
    if not self.enabled or not self.focused then return false end
    
    if event == "key" and param == 28 then  -- Enter
        if self.onClick then
            self.onClick()
        end
        return true
    end
    return false
end

return Controls