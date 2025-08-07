local Elements = {}

-- Base Element class
Elements.Base = {
    x = 1,
    y = 1,
    width = 1,
    height = 1,
    text = "",
    align = "left",
    visible = true  -- Add this
}

function Elements.Base:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Text Element class
Elements.Text = Elements.Base:new()

function Elements.Text:draw()
    if not self.visible then return end
    term.setCursorPos(self.x, self.y)
    term.write(self.text)
end

-- Time Element class
Elements.Time = Elements.Base:new({
    format = "%H:%M:%S",
    updateInterval = 1,
    lastUpdate = 0
})

function Elements.Time:draw()
    if not self.visible then return end
    local currentTime = os.time()
    if currentTime - self.lastUpdate >= self.updateInterval then
        self.text = os.date(self.format)
        self.lastUpdate = currentTime
    end
    if self.align == "right" then
        term.setCursorPos(self.x + self.width - #self.text, self.y)
    else
        term.setCursorPos(self.x, self.y)
    end
    term.write(self.text)
end

return Elements