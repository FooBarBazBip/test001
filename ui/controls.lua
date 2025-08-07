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
    scrollOffset = 0,
    maxVisibleItems = 8,
    width = 36
})

function Controls.FileList:updateFiles(path)
    self.items = {}
    if fs.exists(path) and fs.isDir(path) then
        for _, item in ipairs(fs.list(path)) do
            local fullPath = fs.combine(path, item)
            if not fs.isDir(fullPath) then -- Files only
                table.insert(self.items, item)
            end
        end
    end
    self.selectedIndex = math.min(self.selectedIndex, #self.items)
end

function Controls.FileList:draw()
    if not self.visible then return end
    
    -- Draw border around file list
    local borderX, borderY = self.x - 1, self.y - 1
    local borderWidth, borderHeight = self.width + 2, self.height + 2
    
    -- Top border
    term.setCursorPos(borderX, borderY)
    term.write("+" .. string.rep("-", borderWidth - 2) .. "+")
    
    -- Side borders and content
    for i = 1, self.height do
        term.setCursorPos(borderX, borderY + i)
        term.write("|")
        term.setCursorPos(borderX + borderWidth - 1, borderY + i)
        term.write("|")
        
        -- Clear content area
        term.setCursorPos(self.x, self.y + i - 1)
        term.write(string.rep(" ", self.width))
        
        -- Draw file items
        local idx = i + self.scrollOffset
        if self.items[idx] then
            term.setCursorPos(self.x, self.y + i - 1)
            local prefix = self.focused and (idx == self.selectedIndex and ">" or " ") or " "
            local item = string.sub(self.items[idx], 1, self.width - 2)
            term.write(prefix .. item)
        end
    end
    
    -- Bottom border
    term.setCursorPos(borderX, borderY + borderHeight - 1)
    term.write("+" .. string.rep("-", borderWidth - 2) .. "+")
    
    -- Draw scroll indicator if needed
    if #self.items > self.height then
        local scrollPercent = self.scrollOffset / math.max(1, #self.items - self.height)
        local indicatorPos = math.floor(scrollPercent * (self.height - 1)) + 1
        for i = 1, self.height do
            term.setCursorPos(self.x + self.width, self.y + i - 1)
            if i == indicatorPos then
                term.write("#")
            else
                term.write("|")
            end
        end
    end
end

function Controls.FileList:handleInput(event, param)
    if not self.enabled or not self.focused then return false end
    
    if event == "key" then
        if param == 200 and self.selectedIndex > 1 then -- Up
            self.selectedIndex = self.selectedIndex - 1
            -- Adjust scroll offset if needed
            if self.selectedIndex <= self.scrollOffset then
                self.scrollOffset = math.max(0, self.selectedIndex - 1)
            end
            return true
        elseif param == 208 and self.selectedIndex < #self.items then -- Down
            self.selectedIndex = self.selectedIndex + 1
            -- Adjust scroll offset if needed
            if self.selectedIndex > self.scrollOffset + self.height then
                self.scrollOffset = self.selectedIndex - self.height
            end
            return true
        elseif param == 28 then -- Enter
            if self.items[self.selectedIndex] then
                -- Update filename input with selected file
                if self.parent and self.parent.controls[3] then
                    self.parent.controls[3].text = self.items[self.selectedIndex]
                    self.parent.controls[3].cursorPos = #self.items[self.selectedIndex] + 1
                    -- Move focus to filename input
                    self.focused = false
                    self.parent.selectedControl = 3
                    self.parent.controls[3].focused = true
                end
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

-- ComboBox Control
Controls.ComboBox = Controls.TextInput:new({
    options = {},
    isOpen = false,
    selectedIndex = 1,
    currentPath = "/",
    onPathChange = nil
})

function Controls.ComboBox:draw()
    if not self.visible then return end
    
    -- Clear the line first to prevent artifacts
    term.setCursorPos(self.x, self.y)
    term.write(string.rep(" ", self.width))
    
    -- Draw main input field with fixed positioning
    term.setCursorPos(self.x, self.y)
    local displayText = self.label .. self.text
    local maxTextWidth = self.width - 4 -- Reserve space for indicator
    if #displayText > maxTextWidth then
        displayText = string.sub(displayText, 1, maxTextWidth)
    end
    
    local indicator = self.focused and (self.isOpen and "[v]" or "[>]") or "   "
    term.write(displayText .. indicator)
    
    -- Show cursor if focused and not in dropdown mode
    if self.focused and not self.isOpen then
        local cursorPos = self.x + #self.label + (self.cursorPos - self.scrollOffset - 1)
        if cursorPos >= self.x + #self.label and cursorPos < self.x + maxTextWidth then
            term.setCursorPos(cursorPos, self.y)
            term.setCursorBlink(true)
        end
    else
        term.setCursorBlink(false)
    end
    
    -- Draw compact dropdown below with boundaries
    if self.isOpen and #self.options > 0 then
        local maxShow = math.min(3, #self.options)
        for i = 1, maxShow do
            local idx = i + self.scrollOffset
            if self.options[idx] then
                term.setCursorPos(self.x, self.y + i)
                term.write(string.rep(" ", self.width)) -- Clear line
                term.setCursorPos(self.x, self.y + i)
                local prefix = (idx == self.selectedIndex) and ">" or " "
                local item = string.sub(fs.getName(self.options[idx]), 1, self.width - 3)
                term.write(prefix .. item)
            end
        end
        -- Draw dropdown boundary
        term.setCursorPos(self.x + self.width - 1, self.y + 1)
        term.write("|")
        term.setCursorPos(self.x + self.width - 1, self.y + 2)
        term.write("|")
        term.setCursorPos(self.x + self.width - 1, self.y + 3)
        term.write("|")
    end
end

function Controls.ComboBox:handleInput(event, param)
    if not self.visible or not self.focused then return false end
    
    if event == "char" and not self.isOpen then
        -- Full text input functionality
        self.text = string.sub(self.text, 1, self.cursorPos - 1) 
            .. param 
            .. string.sub(self.text, self.cursorPos)
        self.cursorPos = self.cursorPos + 1
        -- Adjust scroll if needed
        local maxTextWidth = self.width - 4
        if self.cursorPos - self.scrollOffset > maxTextWidth - #self.label then
            self.scrollOffset = self.cursorPos - (maxTextWidth - #self.label)
        end
        return true
    elseif event == "key" then
        if param == 57 then -- Space
            if not self.isOpen then
                self:toggleDropdown()
            else
                -- Add space character when dropdown is closed
                return self:handleInput("char", " ")
            end
            return true
        elseif param == 28 then -- Enter
            if self.isOpen and self.options[self.selectedIndex] then
                self.text = self.options[self.selectedIndex]
                self.isOpen = false
                self:updatePath()
                -- Move focus to next control (file list)
                if self.parent and self.parent.controls[2] then
                    self.focused = false
                    self.parent.selectedControl = 2
                    self.parent.controls[2].focused = true
                end
            else
                self:updatePath()
            end
            return true
        elseif param == 14 and not self.isOpen then -- Backspace
            if self.cursorPos > 1 then
                self.text = string.sub(self.text, 1, self.cursorPos - 2) 
                    .. string.sub(self.text, self.cursorPos)
                self.cursorPos = math.max(1, self.cursorPos - 1)
                if self.scrollOffset > 0 and self.cursorPos <= self.scrollOffset then
                    self.scrollOffset = math.max(0, self.scrollOffset - 1)
                end
            end
            return true
        elseif param == 203 and not self.isOpen then -- Left
            if self.cursorPos > 1 then
                self.cursorPos = self.cursorPos - 1
                if self.scrollOffset > 0 and self.cursorPos <= self.scrollOffset then
                    self.scrollOffset = self.scrollOffset - 1
                end
            end
            return true
        elseif param == 205 and not self.isOpen then -- Right
            if self.cursorPos <= #self.text then
                self.cursorPos = self.cursorPos + 1
                local maxTextWidth = self.width - 4
                if self.cursorPos - self.scrollOffset > maxTextWidth - #self.label then
                    self.scrollOffset = self.cursorPos - (maxTextWidth - #self.label)
                end
            end
            return true
        elseif param == 199 and not self.isOpen then -- Home
            self.cursorPos = 1
            self.scrollOffset = 0
            return true
        elseif param == 207 and not self.isOpen then -- End
            self.cursorPos = #self.text + 1
            local maxTextWidth = self.width - 4
            if #self.text > maxTextWidth - #self.label then
                self.scrollOffset = #self.text - (maxTextWidth - #self.label)
            end
            return true
        elseif self.isOpen then
            if param == 200 and self.selectedIndex > 1 then -- Up
                self.selectedIndex = self.selectedIndex - 1
                if self.selectedIndex <= self.scrollOffset then
                    self.scrollOffset = math.max(0, self.scrollOffset - 1)
                end
                return true
            elseif param == 208 and self.selectedIndex < #self.options then -- Down
                self.selectedIndex = self.selectedIndex + 1
                if self.selectedIndex > self.scrollOffset + 3 then
                    self.scrollOffset = self.selectedIndex - 3
                end
                return true
            end
        end
    end
    return true
end

function Controls.ComboBox:toggleDropdown()
    if not self.isOpen then
        -- Populate with directories only
        self.options = {}
        local path = self.text ~= "" and self.text or "/"
        if fs.exists(path) and fs.isDir(path) then
            for _, item in ipairs(fs.list(path)) do
                local fullPath = fs.combine(path, item)
                if fs.isDir(fullPath) then
                    table.insert(self.options, fullPath)
                end
            end
        end
        self.selectedIndex = 1
    end
    self.isOpen = not self.isOpen
end

function Controls.ComboBox:updatePath()
    if fs.exists(self.text) and fs.isDir(self.text) then
        self.currentPath = self.text
        if self.onPathChange then
            self.onPathChange(self.currentPath)
        end
    end
end

return Controls