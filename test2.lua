local screenBuffer = {"This is line 1", "This is line 2", "This is line 3"}
local function displayBuffer()
    term.clear()
    term.setCursorPos(1, 1)
    for i, line in ipairs(screenBuffer) do
        print(line)
    end
end

local function getKeypress()
    while true do
        local sEvent, param = os.pullEvent("key")
        if sEvent == "key" then
            if param == 200 then
                print("Up detected")
                break
            elseif param == 208 then
                print("Down detected")
                break
            elseif param == 203 then
                print("Left detected")
                break
            elseif param == 205 then
                print("Right detected")
                break
            elseif param == 1 then
                print("Escape detected")
                break
            end
            else
        end
    end
end

