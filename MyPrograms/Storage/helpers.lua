-- helpers.lua
-- Utility functions for chest management

local function hashItemName(name)
    local hash = 0
    for i = 1, #name do
        hash = hash + string.byte(name, i)
    end
    return hash
end

local function getChestIndex(itemName, numChests)
    local hash = hashItemName(itemName)
    return (hash % numChests) + 1
end

local function initChests(mainChestName)
    local dropChest = peripheral.wrap(mainChestName)
    local storageChests = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "minecraft:chest" and name ~= mainChestName then
            table.insert(storageChests, peripheral.wrap(name))
        end
    end
    return dropChest, storageChests
end

return {
    getChestIndex = getChestIndex,
    initChests = initChests
}
