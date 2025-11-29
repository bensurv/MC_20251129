-- Get current shell PATH
local path = shell.path()

-- Ensure path is a table (just in case)
if type(path) ~= "table" then
    path = {}
end

-- Add folder if not already in PATH
local folder = "/repo/MyPrograms/Shell"
local alreadyAdded = false
for _, p in ipairs(path) do
    if p == folder then
        alreadyAdded = true
        break
    end
end

if not alreadyAdded then
    table.insert(path, folder)
end

-- Set the updated PATH
shell.setPath(path)
