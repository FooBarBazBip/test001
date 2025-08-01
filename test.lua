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
            if param == 200 then
                print("Up detected")
                break
            elseif param == 208 then
                print("Down detected")
                break
            end
        end
    end
end

hello()
print(os.date())
print("Printed date.")
rawread()