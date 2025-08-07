local Windows = {}

-- Base Window class
Windows.Base = {
    x = 1,
    y = 1,
    width = 1,
    height = 1,
    buffer = {},
    scrollX = 1,
    scrollY = 1,
    visible = true,
    controls = {},
    selectedControl = 1
}

function Windows.Base:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.controls = o.controls or {}
    return o
end

function Windows.Base:draw()
    if not self.visible then return end
    -- Draw window content
    for y = 1, self.height do
        local bufferY = y + self.scrollY - 1
        if bufferY <= #self.buffer then
            term.setCursorPos(self.x, self.y + y - 1)
            local line = self.buffer[bufferY]
            local visibleText = string.sub(line, self.scrollX, self.scrollX + self.width - 1)
            term.write(visibleText .. string.rep(" ", self.width - #visibleText))
        end
    end
    -- Draw controls if any
    for _, control in ipairs(self.controls) do
        control:draw()
    end
end

function Windows.Base:addControl(control)
    table.insert(self.controls, control)
    return #self.controls
end

function Windows.Base:handleInput(event, param)
    if event == "key" then
        -- Add bounds checking for scrolling
        if param == 200 then -- Up
            if self.scrollY > 1 then
                self.scrollY = self.scrollY - 1
                return true
            end
        elseif param == 208 then -- Down
            if self.scrollY < math.max(1, #self.buffer - self.height + 1) then
                self.scrollY = self.scrollY + 1
                return true
            end
        elseif param == 203 then -- Left
            if self.scrollX > 1 then
                self.scrollX = self.scrollX - 1
                return true
            end
        elseif param == 205 then -- Right
            local maxLength = 0
            for _, line in ipairs(self.buffer) do
                maxLength = math.max(maxLength, #line)
            end
            if self.scrollX < math.max(1, maxLength - self.width + 1) then
                self.scrollX = self.scrollX + 1
                return true
            end
        end
    end
    
    -- Pass input to focused control if any
    if self.selectedControl and 
       self.selectedControl > 0 and 
       self.controls[self.selectedControl] and 
       self.controls[self.selectedControl].handleInput then
        return self.controls[self.selectedControl]:handleInput(event, param)
    end
    return false
end

-- Main Window class
Windows.Main = Windows.Base:new({
    mode = "read", -- read, edit, visual
    cursorX = 1,   -- Add this
    cursorY = 1    -- Add this
})

function Windows.Main:draw()
    if not self.visible then return end
    -- Draw window content
    for y = 1, self.height do
        local bufferY = y + self.scrollY - 1
        if bufferY <= #self.buffer then
            term.setCursorPos(self.x, self.y + y - 1)
            local line = self.buffer[bufferY]
            local visibleText = string.sub(line or "", self.scrollX, self.scrollX + self.width - 1)
            term.write(visibleText .. string.rep(" ", self.width - #visibleText))
        end
        
        -- Draw cursor in edit mode
        if self.mode == "edit" then
            local curY = self.y + (self.cursorY - self.scrollY)
            if curY >= self.y and curY < self.y + self.height then
                term.setCursorPos(self.x + (self.cursorX - self.scrollX), curY)
                term.setCursorBlink(true)
            end
        end
    end
end

function Windows.Main:handleInput(event, param)
    if self.mode == "edit" then
        if event == "char" then
            -- Insert character at cursor position
            local line = self.buffer[self.cursorY] or ""
            self.buffer[self.cursorY] = string.sub(line, 1, self.cursorX - 1) 
                .. param 
                .. string.sub(line, self.cursorX)
            self.cursorX = self.cursorX + 1
            return true
        elseif event == "key" then
            if param == 28 then -- Enter
                -- Split line at cursor
                local line = self.buffer[self.cursorY] or ""
                local before = string.sub(line, 1, self.cursorX - 1)
                local after = string.sub(line, self.cursorX)
                self.buffer[self.cursorY] = before
                table.insert(self.buffer, self.cursorY + 1, after)
                self.cursorY = self.cursorY + 1
                self.cursorX = 1
                return true
            elseif param == 14 then -- Backspace
                if self.cursorX > 1 then
                    -- Delete character before cursor
                    local line = self.buffer[self.cursorY]
                    self.buffer[self.cursorY] = string.sub(line, 1, self.cursorX - 2) 
                        .. string.sub(line, self.cursorX)
                    self.cursorX = self.cursorX - 1
                elseif self.cursorY > 1 then
                    -- Join with previous line
                    local prevLine = self.buffer[self.cursorY - 1]
                    local currLine = self.buffer[self.cursorY]
                    self.cursorX = #prevLine + 1
                    self.buffer[self.cursorY - 1] = prevLine .. currLine
                    table.remove(self.buffer, self.cursorY)
                    self.cursorY = self.cursorY - 1
                end
                return true
            elseif param == 203 then -- Left
                if self.cursorX > 1 then
                    self.cursorX = self.cursorX - 1
                end
                return true
            elseif param == 205 then -- Right
                local line = self.buffer[self.cursorY] or ""
                if self.cursorX <= #line then
                    self.cursorX = self.cursorX + 1
                end
                return true
            elseif param == 200 and self.cursorY > 1 then -- Up
                self.cursorY = self.cursorY - 1
                local line = self.buffer[self.cursorY] or ""
                self.cursorX = math.min(self.cursorX, #line + 1)
                return true
            elseif param == 208 and self.cursorY < #self.buffer then -- Down
                self.cursorY = self.cursorY + 1
                local line = self.buffer[self.cursorY] or ""
                self.cursorX = math.min(self.cursorX, #line + 1)
                return true
            elseif param == 199 then -- Home
                self.cursorX = 1
                return true
            elseif param == 207 then -- End
                local line = self.buffer[self.cursorY] or ""
                self.cursorX = #line + 1
                return true
            end
        end
    end
    return Windows.Base.handleInput(self, event, param)
end

-- Modal Window class
Windows.Modal = Windows.Base:new({
    title = "",
    draggable = false,
    result = nil
})

function Windows.Modal:new(o)
    o = Windows.Base.new(self, o)
    o.selectedControl = 1
    return o
end

-- Update Modal:draw to remove color handling
function Windows.Modal:draw()
    if not self.visible then return end
    
    -- Draw window background and border
    for y = 0, self.height + 1 do
        term.setCursorPos(self.x - 1, self.y + y - 1)
        if y == 0 or y == self.height + 1 then
            term.write("+" .. string.rep("-", self.width) .. "+")
        else
            term.write("|" .. string.rep(" ", self.width) .. "|")
        end
    end
    
    -- Draw title
    if self.title then
        term.setCursorPos(self.x + math.floor((self.width - #self.title) / 2), self.y - 1)
        term.write(self.title)
    end
    
    -- Draw controls
    for i, control in ipairs(self.controls) do
        control.visible = true
        control.focused = (i == self.selectedControl)
        control:draw()
    end
end

function Windows.Modal:handleInput(event, param)
    if event == "key" then
        if param == 15 then -- Tab
            if #self.controls > 0 then
                self.controls[self.selectedControl].focused = false
                self.selectedControl = (self.selectedControl % #self.controls) + 1
                self.controls[self.selectedControl].focused = true
                return true
            end
        end
    end
    
    -- Pass input to focused control
    if self.selectedControl > 0 and 
       self.controls[self.selectedControl] and 
       self.controls[self.selectedControl].handleInput then
        return self.controls[self.selectedControl]:handleInput(event, param)
    end
    return false
end

return Windows