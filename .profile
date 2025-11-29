local folder = "/repo/MyPrograms/Shell"

-- Get current PATH string
local pathStr = shell.path()  -- this is a string

-- Append your folder, separated by ;
pathStr = pathStr .. ";" .. folder

-- Set updated PATH
shell.setPath(pathStr)
