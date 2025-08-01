local w, h = 51, 19
local screenBuffer = {"This is a very long line that needs horizontal scrolling to be fully visible", 
                     "Another long line that extends beyond the screen width limit of 51 characters",
                     "This is line 3 with more content that we want to scroll horizontally to see",
                     "=== Key Features ===",
                     "1. Window size: 51x19 characters",
                     "2. Vertical scrolling with Up/Down arrows",
                     "3. Horizontal scrolling with Left/Right arrows",
                     "4. Escape key to exit the viewer",
                     "",
                     "=== Implementation Details ===",
                     "1. Tracks scroll position with verticalScroll and horizontalScroll",
                     "2. Prevents scrolling past content boundaries",
                     "3. Only redraws screen when necessary using redraw flag",
                     "4. Calculates maximum line length for horizontal bounds",
                     "5. Uses substring to show only visible portion of text",
                     "",
                     "=== Usage Instructions ===",
                     "- Press UP/DOWN to scroll vertically",
                     "- Press LEFT/RIGHT to scroll horizontally",
                     "- Press ESC to exit the viewer",
                     "",
                     "=== Test Content Below ==="}

-- Add additional test lines
for i = 1, 30 do
    table.insert(screenBuffer, string.format("Test line %d with extra content to demonstrate scrolling %d", i, i * 100))
end

local verticalScroll = 1
local horizontalScroll = 1

local function displayBuffer()
    term.clear()
    term.setCursorPos(1, 1)
    for i = verticalScroll, math.min(verticalScroll + h - 1, #screenBuffer) do
        local line = screenBuffer[i]
        -- Display substring based on horizontal scroll position
        local visibleText = string.sub(line, horizontalScroll, horizontalScroll + w - 1)
        print(visibleText)
    end
end

local function getKeypress()
    while true do
        local sEvent, param = os.pullEvent("key")
        if sEvent == "key" then
            local redraw = false
            if param == 200 and verticalScroll > 1 then -- Up
                verticalScroll = verticalScroll - 1
                redraw = true
            elseif param == 208 and verticalScroll < (#screenBuffer - h + 1) then -- Down
                verticalScroll = verticalScroll + 1
                redraw = true
            elseif param == 203 and horizontalScroll > 1 then -- Left
                horizontalScroll = horizontalScroll - 1
                redraw = true
            elseif param == 205 then -- Right
                -- Check if any line needs more scrolling
                local maxLength = 0
                for _, line in ipairs(screenBuffer) do
                    maxLength = math.max(maxLength, #line)
                end
                if horizontalScroll < maxLength - w + 1 then
                    horizontalScroll = horizontalScroll + 1
                    redraw = true
                end
            elseif param == 1 then -- Escape
                break
            end
            
            if redraw then
                displayBuffer()
            end
        end
    end
end

term.clear()
displayBuffer()
getKeypress()
print("End of test2.lua")