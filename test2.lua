local w, h = 51, 18  -- Changed from 19 to 18 to accommodate input bar
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
local inputMode = false
local inputText = ""
local inputScroll = 1

local function displayInput()
    term.setCursorPos(1, 19)  -- Position at bottom line
    term.clearLine()
    if inputMode then
        local visibleInput = string.sub(inputText, inputScroll, inputScroll + w - 1)
        term.write("> " .. visibleInput)
        term.setCursorPos(math.min(#inputText + 3 - inputScroll, w), 19)
    end
end

local function displayBuffer()
    term.clear()
    term.setCursorPos(1, 1)
    for i = verticalScroll, math.min(verticalScroll + h - 1, #screenBuffer) do
        local line = screenBuffer[i]
        local visibleText = string.sub(line, horizontalScroll, horizontalScroll + w - 1)
        print(visibleText)
    end
    displayInput()
end

local function getKeypress()
    while true do
        local sEvent, param = os.pullEvent()
        if sEvent == "key" then
            local redraw = false
            
            if param == 29 then -- Left Ctrl
                inputMode = not inputMode
                redraw = true
            elseif inputMode then
                if param == 28 then -- Enter
                    if #inputText > 0 then
                        table.insert(screenBuffer, inputText)
                        inputText = ""
                        inputScroll = 1
                        redraw = true
                    end
                elseif param == 203 and inputScroll > 1 then -- Left
                    inputScroll = inputScroll - 1
                    redraw = true
                elseif param == 205 and inputScroll < #inputText - w + 3 then -- Right
                    inputScroll = inputScroll + 1
                    redraw = true
                elseif param == 14 then -- Backspace
                    if #inputText > 0 then
                        inputText = string.sub(inputText, 1, -2)
                        inputScroll = math.min(inputScroll, #inputText)
                        redraw = true
                    end
                end
            else
                -- Original scrolling controls when not in input mode
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
                    local maxLength = 0
                    for _, line in ipairs(screenBuffer) do
                        maxLength = math.max(maxLength, #line)
                    end
                    if horizontalScroll < maxLength - w + 1 then
                        horizontalScroll = horizontalScroll + 1
                        redraw = true
                    end
                end
            end
            
            if param == 1 then -- Escape
                break
            end
            
            if redraw then
                displayBuffer()
            end
        elseif sEvent == "char" and inputMode then
            -- Handle character input
            inputText = inputText .. param
            redraw = true
            displayBuffer()
        end
    end
end

term.clear()
displayBuffer()
getKeypress()
print("End of test2.lua")