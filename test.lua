-- Test program in VS Code for ComputerCraft
local function hello()
    term.clear()
    term.setCursorPos(1,1)
    print("Hello World!")
end

function rawread()
    while true do
        local sEvent, param = os.pullEvent("key")
        if sEvent == "key" then
            if param == 29 then
                print("Left Ctrl detected")
                break
            elseif param == 209 then
                print("Page Down detected")
                break
            end
        end
    end
end

hello()
print(os.date())
print("Printed date.")
rawread()