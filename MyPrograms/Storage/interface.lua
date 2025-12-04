-- interface.lua
-- Simple UI with Insert button, Search bar, Search button, and dynamic chest system

local helpers = require("helpers")

-- Terminal size
local w, h = term.getSize()

-------------------------------------------------------
-- UI Positions
-------------------------------------------------------
-- Buttons
local insertBtn = {x=2, y=2, w=10, h=3}
local searchBtn = {x=41, y=2, w=10, h=3}
local clearSearchBtn = {x=37, y=2, w=3, h=3}
local clearBtn = {x=2, y=6, w=12, h=1}
local indexBtn = {x=18, y=6, w=12, h=1}

-- Text boxes
local searchBar = {x=13, y=2, w=24, h=3}
local resultBox = {x=2, y=8, w=49, h=13}

-------------------------------------------------------
-- Data
-------------------------------------------------------
local searchText = ""
local cursorPos = 1
local resultList = {}

-- Helpers
local getChestIndex = helpers.getChestIndex

-- Chest configuration
local mainChestName = "minecraft:chest_21"

-- Initialize chests dynamically
local dropChest = peripheral.wrap(mainChestName)
local storageChests = {}
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "minecraft:chest" and name ~= mainChestName then
        table.insert(storageChests, peripheral.wrap(name))
    end
end

-- Persistent index
local indexFile = "chestIndex.txt"
local itemToChest = {}
if fs.exists(indexFile) then
    local f = fs.open(indexFile, "r")
    itemToChest = textutils.unserialize(f.readAll()) or {}
    f.close()
end

local function saveIndex()
    local f = fs.open(indexFile, "w")
    f.write(textutils.serialize(itemToChest))
    f.close()
end

-------------------------------------------------------
-- UI helpers
-------------------------------------------------------
local function drawButton(x, y, w, h, bg, fg, label)
    term.setBackgroundColor(bg)
    term.setTextColor(fg)
    for i=0, h-1 do
        term.setCursorPos(x, y+i)
        term.write(string.rep(" ", w))
    end
    term.setCursorPos(x + math.floor((w - #label)/2), y + math.floor(h/2))
    term.write(label)
end

local function drawTextBox(x, y, w, h, bg, fg, lines)
    lines = lines or {}
    term.setBackgroundColor(bg)
    term.setTextColor(fg)
    for i=0, h-1 do
        term.setCursorPos(x, y+i)
        term.write(string.rep(" ", w))
    end
    for i=1, math.min(#lines, h) do
        local str = lines[i]
        if #str > w then str = str:sub(1, w) end
        term.setCursorPos(x, y+i-1)
        term.write(str)
    end
end

local function clicked(mx, my, x, y, w, h)
    return mx >= x and mx <= x+w-1 and my >= y and my <= y+h-1
end

-------------------------------------------------------
-- Search bar with blinking cursor
-------------------------------------------------------
local cursorVisible = true

local function drawSearchBar()
    local x, y, w, h = searchBar.x, searchBar.y, searchBar.w, searchBar.h
    local middleLine = y + math.floor(h/2)

    -- Clear box
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    for i=0,h-1 do
        term.setCursorPos(x, y+i)
        term.write(string.rep(" ", w))
    end

    -- Draw text
    term.setCursorPos(x, middleLine)
    term.setTextColor(colors.white)
    term.write(searchText:sub(1, w))

    -- Draw blinking cursor
    if cursorVisible then
        local cursorX = x + math.min(cursorPos-1, w-1)
        term.setCursorPos(cursorX, middleLine)
        term.setTextColor(colors.lightGray)
        term.write("|")
    end
end

local function cursorBlink()
    while true do
        cursorVisible = not cursorVisible
        drawSearchBar()
        sleep(0.5)
    end
end

-------------------------------------------------------
-- Draw UI
-------------------------------------------------------
local function drawUI()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    term.setCursorPos(1,1)
    term.setTextColor(colors.yellow)
    term.write("Storage Interface")

    drawButton(insertBtn.x, insertBtn.y, insertBtn.w, insertBtn.h, colors.green, colors.black, "Insert")
    drawButton(searchBtn.x, searchBtn.y, searchBtn.w, searchBtn.h, colors.blue, colors.white, "Search")
    drawButton(clearSearchBtn.x, clearSearchBtn.y, clearSearchBtn.w, clearSearchBtn.h, colors.lightGray, colors.black, "X")
    drawSearchBar()
    drawTextBox(resultBox.x, resultBox.y, resultBox.w, resultBox.h, colors.black, colors.white, resultList)
    drawButton(clearBtn.x, clearBtn.y, clearBtn.w, clearBtn.h, colors.lightGray, colors.black, "Clear logs")
    drawButton(indexBtn.x, indexBtn.y, indexBtn.w, indexBtn.h, colors.orange, colors.black, "Index inventory")
end

drawUI()

-------------------------------------------------------
-- Core functions
-------------------------------------------------------
local function insert()
    local numChests = #storageChests
    local dropItems = dropChest.list()

    if next(dropItems) == nil then
        table.insert(resultList, "No item to insert in main chest")
    end

    for slot, item in pairs(dropItems) do
        local chestIndex = getChestIndex(item.name, numChests)
        local targetChest = storageChests[chestIndex]
        local moved = dropChest.pushItems(peripheral.getName(targetChest), slot)
        itemToChest[item.name] = chestIndex
        saveIndex()
        table.insert(resultList, "Moved " .. moved .. " of " .. item.name .. " to chest " .. chestIndex)
    end

    drawUI()
end

local function retrieveItem(itemName)
    local foundAny = false
    local chestIndex = itemToChest[itemName]

    if chestIndex then
        local chest = storageChests[chestIndex]
        local items = chest.list()
        for slot, item in pairs(items) do
            if item.name == itemName then
                local moved = chest.pushItems(peripheral.getName(dropChest), slot)
                if moved > 0 then
                    table.insert(resultList,
                        "Retrieved " .. moved .. " of " .. itemName ..
                        " from chest " .. chestIndex .. " slot " .. slot)
                    foundAny = true
                end
            end
        end
    end

    if not foundAny then
        for cIndex, chest in ipairs(storageChests) do
            local items = chest.list()
            for slot, item in pairs(items) do
                if item.name == itemName then
                    local moved = chest.pushItems(peripheral.getName(dropChest), slot)
                    if moved > 0 then
                        table.insert(resultList,
                            "Retrieved " .. moved .. " of " .. itemName ..
                            " from chest " .. cIndex .. " slot " .. slot)
                        itemToChest[itemName] = cIndex
                        saveIndex()
                        foundAny = true
                    end
                end
            end
        end
    end

    if not foundAny then
        table.insert(resultList, "Item '" .. itemName .. "' not found in storage.")
    end
    drawUI()
end

local function searchIds(query)
    resultList = {}
    query = query:lower()
    if #query < 3 then
        table.insert(resultList, "Search must be at least 3 characters.")
        drawUI()
        return
    end

    local foundAny = false
    for itemName, chestIndex in pairs(itemToChest) do
        if itemName:lower():find(query, 1, true) then
            foundAny = true
            local chest = storageChests[chestIndex]
            if chest then
                local items = chest.list()
                for slot, item in pairs(items) do
                    if item.name == itemName then
                        table.insert(resultList,
                            "Found " .. item.count .. " x " .. item.name ..
                            " in chest " .. chestIndex .. " (slot " .. slot .. ")")
                    end
                end
            end
        end
    end

    if not foundAny then
        table.insert(resultList, "No items match \"" .. query .. "\".")
    end
    drawUI()
end

local function reindexChests()
    resultList = {}
    itemToChest = {}
    for chestIndex, chest in ipairs(storageChests) do
        local items = chest.list()
        if next(items) == nil then
            table.insert(resultList, "Chest " .. chestIndex .. " is empty.")
        else
            for slot, item in pairs(items) do
                table.insert(resultList,
                    "Chest " .. chestIndex .. " Slot " .. slot .. ": " ..
                    item.count .. " x " .. item.name)
                itemToChest[item.name] = chestIndex
            end
        end
    end
    table.insert(resultList, "Reindex complete!")
    saveIndex()
    drawUI()
end

if next(itemToChest) == nil then
    reindexChests()
end

-------------------------------------------------------
-- Event loop
-------------------------------------------------------
parallel.waitForAny(
    function() cursorBlink() end,
    function()
        while true do
            local ev = {os.pullEvent()}

            if ev[1] == "char" then
                searchText = searchText:sub(1, cursorPos-1) .. ev[2] .. searchText:sub(cursorPos)
                cursorPos = cursorPos + 1
                drawSearchBar()

            elseif ev[1] == "key" then
                if ev[2] == keys.backspace and cursorPos > 1 then
                    searchText = searchText:sub(1, cursorPos-2) .. searchText:sub(cursorPos)
                    cursorPos = cursorPos - 1
                    drawSearchBar()
                elseif ev[2] == keys.delete and cursorPos <= #searchText then
                    searchText = searchText:sub(1, cursorPos-1) .. searchText:sub(cursorPos+1)
                    drawSearchBar()
                elseif ev[2] == keys.left and cursorPos > 1 then
                    cursorPos = cursorPos - 1
                    drawSearchBar()
                elseif ev[2] == keys.right and cursorPos <= #searchText then
                    cursorPos = cursorPos + 1
                    drawSearchBar()
                elseif ev[2] == keys.enter then
                    if searchText and #searchText >= 3 then
                        if searchText:find(":") then
                            retrieveItem(searchText)
                        else
                            searchIds(searchText)
                        end
                    else
                        table.insert(resultList, "You must input at least 3 characters to search")
                        drawUI()
                    end
                end

            elseif ev[1] == "mouse_click" then
                local x, y = ev[3], ev[4]

                if clicked(x, y, insertBtn.x, insertBtn.y, insertBtn.w, insertBtn.h) then
                    insert()
                elseif clicked(x, y, clearSearchBtn.x, clearSearchBtn.y, clearSearchBtn.w, clearSearchBtn.h) then
                    searchText = ""
                    cursorPos = 1
                    drawUI()
                elseif clicked(x, y, searchBtn.x, searchBtn.y, searchBtn.w, searchBtn.h) then
                    if searchText and #searchText >= 3 then
                        if searchText:find(":") then
                            retrieveItem(searchText)
                        else
                            searchIds(searchText)
                        end
                    else
                        table.insert(resultList, "You must input at least 3 characters to search")
                        drawUI()
                    end
                elseif clicked(x, y, clearBtn.x, clearBtn.y, clearBtn.w, clearBtn.h) then
                    resultList = {}
                    drawUI()
                elseif clicked(x, y, indexBtn.x, indexBtn.y, indexBtn.w, indexBtn.h) then
                    reindexChests()
                end
            end
        end
    end
)
