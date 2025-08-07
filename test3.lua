-- Main program file
package.path = package.path .. ";./ui/?.lua"
-- Required libraries
local UI = require("ui")
local Elements = require("elements")
local Windows = require("windows")
local Controls = require("controls")

-- Initialize screen dimensions
local w, h = 51, 19

-- Create initial screen buffer content
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

-- Create UI components
local app = UI.Application:new({
    width = w,
    height = h,
    buffer = screenBuffer
})

-- Add top bar elements
--app.topBar:addElement(UI.TextElement:new({
app.topBar:addElement(Elements.Text:new({
    text = "Editor",
    align = "left"
}))

--app.topBar:addElement(UI.TimeElement:new({
app.topBar:addElement(Elements.Time:new({
    format = "%H:%M:%S",
    align = "right",
    updateInterval = 1
}))

-- Configure bottom bar modes
app.bottomBar:setModes({
    read = { text = "Reader Mode" },  -- Changed from 'off' to 'read'
    edit = { text = "Editor Mode" },  -- Updated text
    input = { text = "> " },
    menu = { items = {"Load", "Save", "Exit"} },
    visual = { text = "Tab:Next|SPACE:Toggle|Enter:Select|ESC:Cancel" }
})

-- Start application
app:run()