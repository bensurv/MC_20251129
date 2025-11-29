local folder = "/repo/MyPrograms/Shell"

-- get current path string (semicolon separated)
local pathStr = shell.path()

-- append your folder (use ; separator)
pathStr = pathStr .. ";" .. folder

-- convert string to table
local pathTable = {}
for p in string.gmatch(pathStr, "[^;]+") do
    table.insert(pathTable, p)
end

-- set the updated PATH
shell.setPath(pathTable)
