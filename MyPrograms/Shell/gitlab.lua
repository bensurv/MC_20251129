local USER = "bensurv"
local REPO = "MC_20251129"

local args = {...}
local remoteFolder = args[1] or ""
local localFolder

if args[2] ~= nil and args[2] ~= "" then
    localFolder = args[2]
elseif remoteFolder == "" then
    localFolder == "defaultFolder"
else
    localFolder == remoteFolder
end

shell.run("github " .. USER .. "/" ..  REPO .. "/" .. remoteFolder .. " " .. localFolder)