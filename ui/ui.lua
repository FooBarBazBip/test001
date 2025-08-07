package.path = package.path .. ";./ui/?.lua"

local Windows = require("windows")
local Elements = require("elements")
local Controls = require("controls")

local UI = {}

-- Base Component class
UI.Component = {
    x = 1,
    y = 1,
    width = 1,
    height = 1,
    visible = true
}

function UI.Component:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- TopBar class
UI.TopBar = UI.Component:new({
    elements = {},
    height = 1
})

function UI.TopBar:addElement(element)
    table.insert(self.elements, element)
    self:updateElementPositions()
end

function UI.TopBar:updateElementPositions()
    local leftX = self.x
    local rightX = self.x + self.width - 1
    
    for _, element in ipairs(self.elements) do
        if element.align == "right" then
            element.x = rightX - #element.text
            rightX = element.x - 1
        else
            element.x = leftX
            leftX = leftX + #element.text + 1
        end
        element.y = self.y
    end
end

function UI.TopBar:draw()
    if not self.visible then return end
    term.setCursorPos(self.x, self.y)
    term.write(string.rep(" ", self.width))
    for _, element in ipairs(self.elements) do
        element:draw()
    end
end

-- BottomBar class
UI.BottomBar = UI.Component:new({
    mode = "off",
    modes = {},
    height = 1,
    text = "",
    menuItems = {},
    selectedMenuItem = 1
})

function UI.BottomBar:setModes(modes)
    self.modes = modes
end

-- Update BottomBar:setMode to properly set mode and text
function UI.BottomBar:setMode(mode)
    self.mode = mode
    if self.modes[mode] then
        if mode == "menu" then
            self.menuItems = self.modes[mode].items
            self.selectedMenuItem = 1
            self.inputControl.visible = false
            self.inputControl.focused = false
            self.text = "" -- Clear text in menu mode
        elseif mode == "input" then
            self.inputControl.text = ""
            self.inputControl.visible = true
            self.inputControl.focused = true
            -- Adjust scroll to show last line at bottom of window
            if self.parent and self.parent.mainWindow then
                local bufferLen = #self.parent.mainWindow.buffer
                local windowHeight = self.parent.mainWindow.height
                self.parent.mainWindow.scrollY = math.max(1, bufferLen - windowHeight + 1)
            end
        else
            self.inputControl.visible = false
            self.inputControl.focused = false
            self.text = self.modes[mode].text
        end
    end
end

-- Update BottomBar:draw to properly handle all modes
function UI.BottomBar:draw()
    if not self.visible then return end
    term.setCursorPos(self.x, self.y)
    term.write(string.rep(" ", self.width))
    term.setCursorPos(self.x, self.y)
    
    if self.mode == "input" then
        self.inputControl:draw()
    elseif self.mode == "menu" then
        local menuText = ""
        for i, item in ipairs(self.menuItems) do
            menuText = menuText .. (i == self.selectedMenuItem and "[" .. item .. "] " or item .. " ")
        end
        term.write(menuText)
    else
        term.write(self.text or "")
    end
end

function UI.BottomBar:new(o)
    o = UI.Component.new(self, o)
    o.inputControl = Controls.TextInput:new({
        x = o.x,
        y = o.y,
        width = o.width,
        visible = false,
        focused = false,
        label = "> ",  -- Move prompt here
        parent = o
    })
    return o
end

-- Update BottomBar:handleInput to properly handle input control
function UI.BottomBar:handleInput(event, param)
    if self.mode == "input" then
        if event == "key" then
            if param == 29 or param == 1 then  -- Left Ctrl or Escape
                return false  -- Pass to parent handler
            end
        end
        local result, text = self.inputControl:handleInput(event, param)
        if result and text then -- Text was submitted
            if self.parent and self.parent.mainWindow then
                table.insert(self.parent.mainWindow.buffer, text)
                -- Adjust scroll to show last line at bottom of window
                local bufferLen = #self.parent.mainWindow.buffer
                local windowHeight = self.parent.mainWindow.height
                self.parent.mainWindow.scrollY = math.max(1, bufferLen - windowHeight + 1)
            end
        end
        return result
    else
        self.inputControl.visible = false
        self.inputControl.focused = false
    end
    if event == "key" then
        if self.mode == "menu" then
            if param == 203 and self.selectedMenuItem > 1 then -- Left
                self.selectedMenuItem = self.selectedMenuItem - 1
                return true
            elseif param == 205 and self.selectedMenuItem < #self.menuItems then -- Right
                self.selectedMenuItem = self.selectedMenuItem + 1
                return true
            elseif param == 28 then -- Enter
                if self.menuItems[self.selectedMenuItem] == "Save" then
                    self.parent:showModal("save")
                    return true
                elseif self.menuItems[self.selectedMenuItem] == "Load" then
                    self.parent:showModal("load")
                    return true
                elseif self.menuItems[self.selectedMenuItem] == "Exit" then
                    error("Program terminated", 0)
                end
            end
        end
    end
    return false
end

-- Application class
UI.Application = UI.Component:new()

function UI.Application:new(o)
    o = UI.Component.new(self, o)
    o.topBar = UI.TopBar:new({
        x = 1,
        y = 1,
        width = o.width,
        height = 1,
        parent = o
    })
    
    o.mainWindow = Windows.Main:new({
        x = 1,
        y = 2,
        width = o.width,
        height = o.height - 2,
        buffer = o.buffer or {},
        mode = "read",
        parent = o
    })
    
    o.bottomBar = UI.BottomBar:new({
        x = 1,
        y = o.height,
        width = o.width,
        height = 1,
        parent = o
    })
    
    o.modalWindow = nil  -- Add this
    return o
end

-- Fix Application draw order and state management
function UI.Application:draw()
    -- Clear screen once
    term.clear()
    
    -- Draw components in order
    -- 1. Main window (background)
    self.mainWindow:draw()
    
    -- 2. Top bar (always on top of main window)
    self.topBar:draw()
    
    -- 3. Bottom bar (always on top of main window)
    self.bottomBar:draw()
    
    -- 4. Modal (if active, on top of everything)
    if self.modalWindow and self.modalWindow.visible then
        -- Ensure main window cursor is hidden
        term.setCursorBlink(false)
        self.modalWindow:draw()
    end
    
    -- Ensure proper cursor state
    if self.bottomBar.mode == "input" and self.bottomBar.inputControl.focused then
        term.setCursorBlink(true)
    elseif self.mainWindow.mode == "edit" then
        term.setCursorBlink(true)
    else
        term.setCursorBlink(false)
    end
end

-- Fix mode switching to properly handle states
function UI.Application:setMode(mode)
    self.bottomBar:setMode(mode)
    if mode == "edit" then
        self.mainWindow.mode = "edit"
    elseif mode == "visual" then
        self.mainWindow.mode = "visual"
    else
        self.mainWindow.mode = "read"
    end
    self:draw() -- Ensure immediate redraw
end

-- Update Application:handleInput
function UI.Application:handleInput()
    while true do
---@diagnostic disable-next-line: undefined-field
        local event, param = os.pullEvent()
        local redraw = false
        
        if event == "key" then
            if param == 1 then -- Escape
                if self.modalWindow and self.modalWindow.visible then
                    self.modalWindow.visible = false
                    self.bottomBar:setMode("menu")
                    redraw = true
                elseif self.bottomBar.mode ~= "read" then
                    self.bottomBar:setMode("read")
                    self.mainWindow.mode = "read"
                    redraw = true
                else
                    break  -- Exit program
                end
            elseif param == 29 then -- Left Ctrl
                if not (self.modalWindow and self.modalWindow.visible) then
                    local modes = {"read", "edit", "input", "menu", "visual"}
                    local currentIndex = 1
                    for i, mode in ipairs(modes) do
                        if self.bottomBar.mode == mode then
                            currentIndex = i
                            break
                        end
                    end
                    currentIndex = currentIndex % #modes + 1
                    self:setMode(modes[currentIndex]) -- Use setMode instead of direct mode setting
                    redraw = true
                end
            else
                -- Handle input based on current mode
                if self.modalWindow and self.modalWindow.visible then
                    redraw = self.modalWindow:handleInput(event, param)
                elseif self.bottomBar.mode == "menu" then
                    redraw = self.bottomBar:handleInput(event, param)
                elseif self.bottomBar.mode == "input" then
                    redraw = self.bottomBar:handleInput(event, param)
                else
                    redraw = self.mainWindow:handleInput(event, param)
                end
            end
        elseif event == "char" then
            if self.modalWindow and self.modalWindow.visible then
                redraw = self.modalWindow:handleInput(event, param)
            elseif self.bottomBar.mode == "input" then
                redraw = self.bottomBar:handleInput(event, param)
            elseif self.mainWindow.mode == "edit" then
                redraw = self.mainWindow:handleInput(event, param)
            end
        end
        
        if redraw then
            self:draw()
        end
    end
end

-- Add this function to UI.Application class
function UI.Application:run()
    self:draw()           -- Initial draw
    self:handleInput()    -- Start main input loop
end

-- Add these utility functions to UI.Application
function UI.Application:saveFile(path, buffer)
    local file = fs.open(path, "w")
    if file then
        for _, line in ipairs(buffer) do
            file.writeLine(line)
        end
        file.close()
        return true
    end
    return false
end

function UI.Application:loadFile(path)
    local file = fs.open(path, "r")
    if file then
        local buffer = {}
        local line = file.readLine()
        while line do
            table.insert(buffer, line)
            line = file.readLine()
        end
        file.close()
        return buffer
    end
    return nil
end

-- Modify showModal to include button handlers
function UI.Application:showModal(type)
    self.modalWindow = Windows.Modal:new({
        title = type == "load" and "Load File" or "Save File",
        width = 40,
        height = 15,
        parent = self,
        x = math.floor((self.width - 40) / 2),
        y = math.floor((self.height - 15) / 2),
        visible = true
    })
    
    -- Add controls
    self.modalWindow:addControl(Controls.Dropdown:new({
        x = self.modalWindow.x + 2,
        y = self.modalWindow.y + 1,
        label = "Path:",
        value = "/",
        options = fs.list("/")
    }))
    
    self.modalWindow:addControl(Controls.FileList:new({
        x = self.modalWindow.x + 2,
        y = self.modalWindow.y + 3,
        height = 8,
        items = fs.list("/")
    }))
    
    local filenameInput = Controls.TextInput:new({
        x = self.modalWindow.x + 2,
        y = self.modalWindow.y + 12,
        label = "File:",
        width = 30
    })
    self.modalWindow:addControl(filenameInput)
    
    -- Action button (Save/Load)
    local actionBtn = Controls.Button:new({
        x = self.modalWindow.x + 20,
        y = self.modalWindow.y + 13,
        label = type == "load" and "Load" or "Save",
        onClick = function()
            local path = fs.combine(self.modalWindow.controls[1].value, filenameInput.text)
            if type == "save" then
                if self:saveFile(path, self.mainWindow.buffer) then
                    self.modalWindow.visible = false
                    self.bottomBar:setMode("read")
                end
            else -- load
                local newBuffer = self:loadFile(path)
                if newBuffer then
                    self.mainWindow.buffer = newBuffer
                    self.mainWindow.scrollX = 1
                    self.mainWindow.scrollY = 1
                    self.modalWindow.visible = false
                    self.bottomBar:setMode("read")
                end
            end
        end
    })
    self.modalWindow:addControl(actionBtn)
    
    -- Cancel button
    local cancelBtn = Controls.Button:new({
        x = self.modalWindow.x + 30,
        y = self.modalWindow.y + 13,
        label = "Cancel",
        onClick = function()
            self.modalWindow.visible = false
            self.bottomBar:setMode("read")
        end
    })
    self.modalWindow:addControl(cancelBtn)
    
    self.bottomBar:setMode("visual")  -- Show help text
    self:draw()  -- Immediate redraw to show modal
    return self.modalWindow
end

return UI