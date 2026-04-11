-- ============================================
-- 🐉 RDE SLEEPMOD - SERVER v1.0.0
-- Proximity Loading | GlobalState Sync | ox_core
-- Author: Red Dragon Elite | SerpentsByte
-- ============================================

local Config = require 'config'
local Ox = require '@ox_core.lib.init'
local GetLanguageString = GetLanguageString

-- ============================================
-- 🎯 STATE: Server-side data only, NO entities
-- ============================================

---@type table<string, {coords: string, model: number, charid: number, skin: string?, inventory: string?}>
local sleepingPlayers = {}
local activeStashes = {}

-- ✅ FIX: Cache source → stateId/charId because Ox.GetPlayer() returns nil during playerDropped
---@type table<number, {stateId: string, charId: number}>
local playerCache = {}

-- ============================================
-- 🔧 UTILITY
-- ============================================

local function Debug(...)
    if Config.Debug then
        print('[^3RDE SLEEPMOD^0]', ...)
    end
end

--- ✅ ox_core uses charId (camelCase!) not charid
--- Also populates playerCache for use during playerDropped
local function GetPlayerData(source)
    local player = Ox.GetPlayer(source)
    if player then
        local stateId = player.stateId
        local charId = player.charId
        -- Cache it so playerDropped can use it later
        if stateId then
            playerCache[source] = { stateId = stateId, charId = charId }
        end
        return stateId, charId, player
    end
    -- Fallback: use cache if player object is already gone (during disconnect)
    local cached = playerCache[source]
    if cached then
        return cached.stateId, cached.charId, nil
    end
    return nil, nil, nil
end

-- ============================================
-- 📡 GLOBALSTATE SYNC
-- ============================================

local function SyncGlobalState()
    local syncData = {}
    for identifier, data in pairs(sleepingPlayers) do
        local coords = json.decode(data.coords)
        if coords then
            syncData[identifier] = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                w = coords.w or 0.0,
                model = data.model,
            }
        end
    end
    GlobalState.sleepingPlayers = syncData
    Debug('GlobalState synced,', next(syncData) and 'has entries' or 'empty')
end

-- ============================================
-- 🛡️ ADMIN
-- ============================================

local function IsPlayerAdmin(source)
    local stateId, charId, player = GetPlayerData(source)
    if not player then return false end

    local identifier = GetPlayerIdentifierByType(source, 'steam')
    local cfg = Config.AdminSystem

    for _, method in ipairs(cfg.checkOrder) do
        if method == 'ace' then
            if IsPlayerAceAllowed(source, cfg.acePermission) then return true end
        elseif method == 'oxcore' then
            local ok, groups = pcall(player.getGroups, player)
            if ok and groups then
                for groupName, minGrade in pairs(cfg.oxGroups) do
                    if groups[groupName] and groups[groupName] >= minGrade then return true end
                end
            end
        elseif method == 'steam' then
            if identifier then
                for _, id in ipairs(cfg.steamIds) do
                    if identifier == id then return true end
                end
            end
        end
    end
    return false
end

-- ============================================
-- 📊 DATABASE
-- ============================================

local function InitializeDatabase()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ]] .. Config.DatabaseTable .. [[ (
            identifier VARCHAR(60) PRIMARY KEY,
            charid INT DEFAULT NULL,
            coords TEXT NOT NULL,
            model INT NOT NULL,
            skin LONGTEXT,
            inventory LONGTEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    Debug('Database table initialized')
end

local function SaveToDB(identifier, data)
    MySQL.insert([[
        INSERT INTO ]] .. Config.DatabaseTable .. [[ 
        (identifier, charid, coords, model, skin, inventory)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            charid = VALUES(charid),
            coords = VALUES(coords),
            model = VALUES(model),
            skin = VALUES(skin),
            inventory = VALUES(inventory),
            updated_at = CURRENT_TIMESTAMP
    ]], {
        identifier,
        data.charid,
        data.coords,
        data.model,
        data.skin,
        data.inventory
    })
end

local function DeleteFromDB(identifier)
    MySQL.query('DELETE FROM ' .. Config.DatabaseTable .. ' WHERE identifier = ?', {identifier})
end

local function LoadAllFromDB()
    return MySQL.query.await('SELECT * FROM ' .. Config.DatabaseTable) or {}
end

-- ============================================
-- 🎨 SKIN: Load from playerskins table
-- ✅ FIXED: No 'active' filter, simple query
-- ============================================

local function LoadSkinFromDB(charid)
    if not charid or charid <= 0 then
        Debug('LoadSkinFromDB: Invalid charid:', charid)
        return nil
    end

    -- ✅ FIXED: Column is 'citizenid' in playerskins table
    local result = MySQL.single.await(
        'SELECT skin FROM playerskins WHERE citizenid = ? LIMIT 1',
        {charid}
    )

    if result and result.skin then
        Debug('Loaded skin from playerskins for charid:', charid)
        return result.skin
    end

    Debug('No skin found in playerskins for charid:', charid)
    return nil
end

-- ============================================
-- 🎮 SLEEPING ENTRY MANAGEMENT
-- ============================================

local function CreateSleepingEntry(source, data)
    local stateId, charId, player = GetPlayerData(source)
    if not stateId or not player then return end

    Debug('CreateSleepingEntry: stateId=' .. tostring(stateId) .. ' charId=' .. tostring(charId))

    -- ✅ Load skin from playerskins using charId
    local skin = LoadSkinFromDB(charId)

    -- Collect inventory
    local inventoryData = {}
    local ok, inventory = pcall(exports.ox_inventory.GetInventory, exports.ox_inventory, source)
    if ok and inventory and inventory.items then
        for _, item in pairs(inventory.items) do
            if item.count and item.count > 0 then
                inventoryData[#inventoryData + 1] = {
                    name = item.name,
                    count = item.count,
                    slot = item.slot,
                    metadata = item.metadata
                }
            end
        end
    end

    local entry = {
        coords = data.coords,
        model = data.model,
        charid = charId,
        skin = skin,
        inventory = json.encode(inventoryData),
    }

    sleepingPlayers[stateId] = entry
    SaveToDB(stateId, entry)
    SyncGlobalState()

    Debug('Created sleeping entry for:', player.name,
        '| stateId:', stateId,
        '| charId:', charId,
        '| skin:', skin and 'YES' or 'NO')
end

local function RemoveSleepingEntry(identifier)
    if not sleepingPlayers[identifier] then return end

    sleepingPlayers[identifier] = nil
    DeleteFromDB(identifier)

    if activeStashes[identifier] then
        pcall(exports.ox_inventory.RemoveInventory, exports.ox_inventory, 'sleeping_' .. identifier)
        activeStashes[identifier] = nil
    end

    SyncGlobalState()
    Debug('Removed sleeping entry:', identifier)
end

-- ============================================
-- 📦 STASH
-- ============================================

local function RegisterStash(identifier)
    local data = sleepingPlayers[identifier]
    if not data then return false end

    local stashId = 'sleeping_' .. identifier

    -- ✅ If stash already registered and populated, just return true
    if activeStashes[identifier] then
        return true
    end

    local ok = pcall(exports.ox_inventory.RegisterStash, exports.ox_inventory,
        stashId, 'Sleeping Player', Config.MaxSlots, Config.MaxWeight)
    if not ok then return false end

    -- ✅ Only add items on FIRST registration
    if data.inventory then
        local items = type(data.inventory) == 'string' and json.decode(data.inventory) or data.inventory
        if items then
            for _, item in pairs(items) do
                if item.count and item.count > 0 then
                    pcall(exports.ox_inventory.AddItem, exports.ox_inventory,
                        stashId, item.name, item.count, item.metadata, item.slot)
                end
            end
        end
    end

    activeStashes[identifier] = true
    return true
end

-- ✅ Sync stash contents back to DB (called periodically and on player reconnect)
local function SyncStashToDB(identifier)
    if not activeStashes[identifier] then return end

    local stashId = 'sleeping_' .. identifier
    local ok, inventory = pcall(exports.ox_inventory.GetInventory, exports.ox_inventory, stashId)
    if not ok or not inventory then return end

    local items = {}
    if inventory.items then
        for _, item in pairs(inventory.items) do
            if item.count and item.count > 0 then
                items[#items + 1] = {
                    name = item.name,
                    count = item.count,
                    slot = item.slot,
                    metadata = item.metadata,
                }
            end
        end
    end

    local inv = json.encode(items)

    -- Update in-memory
    if sleepingPlayers[identifier] then
        sleepingPlayers[identifier].inventory = inv
    end

    -- Update DB
    MySQL.update('UPDATE ' .. Config.DatabaseTable .. ' SET inventory = ? WHERE identifier = ?', {inv, identifier})
    Debug('Synced stash to DB for:', identifier)
end

-- ============================================
-- 📞 CALLBACKS
-- ============================================

lib.callback.register('rde_sleepmod:registerStash', function(source, identifier)
    return RegisterStash(identifier)
end)

lib.callback.register('rde_sleepmod:isAdmin', function(source)
    return IsPlayerAdmin(source)
end)

lib.callback.register('rde_sleepmod:getSkinData', function(source, identifier)
    local data = sleepingPlayers[identifier]
    if not data then return nil end

    -- If skin is cached in sleepingPlayers, return it
    if data.skin then return data.skin end

    -- Fallback: try loading from playerskins
    if data.charid and data.charid > 0 then
        local skin = LoadSkinFromDB(data.charid)
        if skin then
            data.skin = skin
            -- Update DB cache too
            MySQL.update('UPDATE ' .. Config.DatabaseTable .. ' SET skin = ? WHERE identifier = ?', {skin, identifier})
            return skin
        end
    end

    return nil
end)

-- ============================================
-- 🎯 EVENTS
-- ============================================

AddEventHandler('ox:playerLoaded', function(source, userid, charid)
    -- ✅ Cache immediately (before SetTimeout) so playerDropped can use it
    if source and source > 0 and charid then
        local player = Ox.GetPlayer(source)
        if player and player.stateId then
            playerCache[source] = { stateId = player.stateId, charId = charid }
            Debug('Cached player data for source:', source, '| stateId:', player.stateId, '| charId:', charid)
        end
    end

    SetTimeout(5000, function() -- ✅ 5s delay to ensure ox_inventory is fully loaded
        if not source or source <= 0 then return end
        local stateId, playerCharId, player = GetPlayerData(source)
        if not stateId or not sleepingPlayers[stateId] then return end

        local sleepData = sleepingPlayers[stateId]
        Debug('Player reconnected:', stateId)

        -- ✅ FIX: Update characters table with sleeping ped position
        -- So if someone carried the sleeper, the player spawns at the new location
        local coords = sleepData.coords and json.decode(sleepData.coords)
        if coords and playerCharId then
            -- Update characters table x, y, z, heading
            MySQL.update([[
                UPDATE characters SET x = ?, y = ?, z = ?, heading = ? WHERE charid = ?
            ]], { coords.x, coords.y, coords.z, coords.w or 0.0, playerCharId })

            -- ✅ Teleport player to sleeping ped position (they may have spawned at old coords)
            TriggerClientEvent('rde_sleepmod:teleportToSleepPos', source, coords.x, coords.y, coords.z, coords.w or 0.0)

            Debug(('Updated characters spawn pos for charid %d: %.1f, %.1f, %.1f'):format(
                playerCharId, coords.x, coords.y, coords.z
            ))
        end

        -- ✅ If stash was accessed (robbery happened), calculate what was stolen
        if activeStashes[stateId] then
            local stashId = 'sleeping_' .. stateId

            -- Get original snapshot (what they had when they disconnected)
            local originalItems = {}
            local origData = sleepData.inventory
            if origData then
                local parsed = type(origData) == 'string' and json.decode(origData) or origData
                if parsed then
                    for _, item in pairs(parsed) do
                        originalItems[item.name] = (originalItems[item.name] or 0) + item.count
                    end
                end
            end

            -- Get what's LEFT in the stash now
            local remainingItems = {}
            local ok, stashInv = pcall(exports.ox_inventory.GetInventory, exports.ox_inventory, stashId)
            if ok and stashInv and stashInv.items then
                for _, item in pairs(stashInv.items) do
                    if item.count and item.count > 0 then
                        remainingItems[item.name] = (remainingItems[item.name] or 0) + item.count
                    end
                end
            end

            -- Calculate stolen: original - remaining = stolen
            for itemName, originalCount in pairs(originalItems) do
                local remaining = remainingItems[itemName] or 0
                local stolen = originalCount - remaining
                if stolen > 0 then
                    -- ✅ Remove stolen items from the player's actual inventory
                    pcall(exports.ox_inventory.RemoveItem, exports.ox_inventory,
                        source, itemName, stolen)
                    Debug('Removed stolen item from player:', itemName, 'x' .. stolen)
                end
            end
        end

        RemoveSleepingEntry(stateId)
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source

    -- ✅ Get data BEFORE player object disappears
    local stateId, charId, player = GetPlayerData(src)

    SetTimeout(500, function()
        if not stateId then
            Debug('playerDropped: No stateId for source:', src)
            return
        end
        if sleepingPlayers[stateId] then
            Debug('playerDropped: Entry already exists for:', stateId)
            return
        end

        -- Use cached data from DB (saved by auto-save)
        local cached = MySQL.single.await(
            'SELECT * FROM ' .. Config.DatabaseTable .. ' WHERE identifier = ?',
            {stateId}
        )

        if cached then
            -- If skin was NULL in cache, try loading it now
            local skin = cached.skin
            if not skin and cached.charid and cached.charid > 0 then
                skin = LoadSkinFromDB(cached.charid)
            end
            -- If still no skin and we have charId from before drop
            if not skin and charId and charId > 0 then
                skin = LoadSkinFromDB(charId)
            end

            sleepingPlayers[stateId] = {
                coords = cached.coords,
                model = cached.model,
                charid = cached.charid or charId,
                skin = skin,
                inventory = cached.inventory,
            }

            -- Update skin in DB if we loaded it
            if skin and not cached.skin then
                MySQL.update('UPDATE ' .. Config.DatabaseTable .. ' SET skin = ? WHERE identifier = ?', {skin, stateId})
            end

            SyncGlobalState()
            Debug('playerDropped: Activated sleeping entry from cache:', stateId, '| skin:', skin and 'YES' or 'NO')
        else
            Debug('playerDropped: No cache for:', stateId)
        end

        -- ✅ Clean up player cache after processing
        playerCache[src] = nil
    end)
end)

RegisterNetEvent('rde_sleepmod:createSleepingPed', function(data)
    CreateSleepingEntry(source, data)
end)

-- ✅ Auto-save: saves skin from playerskins into rde_sleepmod cache
RegisterNetEvent('rde_sleepmod:saveAppearanceCache', function(data)
    local src = source
    local stateId, charId, player = GetPlayerData(src)
    if not stateId or not player then return end

    -- ✅ Load skin from playerskins
    local skin = LoadSkinFromDB(charId)

    local inventoryData = {}
    local ok, inventory = pcall(exports.ox_inventory.GetInventory, exports.ox_inventory, src)
    if ok and inventory and inventory.items then
        for _, item in pairs(inventory.items) do
            if item.count and item.count > 0 then
                inventoryData[#inventoryData + 1] = {
                    name = item.name,
                    count = item.count,
                    slot = item.slot,
                    metadata = item.metadata
                }
            end
        end
    end

    SaveToDB(stateId, {
        coords = data.coords,
        model = data.model,
        charid = charId,
        skin = skin,
        inventory = json.encode(inventoryData),
    })

    Debug('Cache saved for:', player.name, '| charId:', charId, '| skin:', skin and 'YES' or 'NO')
end)

RegisterNetEvent('rde_sleepmod:updatePosition', function(identifier, newCoords)
    local data = sleepingPlayers[identifier]
    if not data then return end
    data.coords = json.encode(newCoords)
    MySQL.update('UPDATE ' .. Config.DatabaseTable .. ' SET coords = ? WHERE identifier = ?', {data.coords, identifier})

    -- ✅ FIX: Also update characters table so player spawns at new position
    if data.charid and data.charid > 0 then
        MySQL.update([[
            UPDATE characters SET x = ?, y = ?, z = ?, heading = ? WHERE charid = ?
        ]], { newCoords.x, newCoords.y, newCoords.z, newCoords.w or 0.0, data.charid })
        Debug(('Updated characters spawn pos for sleeper %s (charid %d)'):format(identifier, data.charid))
    end

    SyncGlobalState()
end)

RegisterNetEvent('rde_sleepmod:wakePlayer', function(identifier)
    local src = source
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = GetLanguageString('error'),
            description = GetLanguageString('no_permission'),
            type = 'error'
        })
        return
    end
    RemoveSleepingEntry(identifier)
    TriggerClientEvent('ox_lib:notify', src, {
        title = GetLanguageString('success'),
        description = GetLanguageString('player_woken'),
        type = 'success'
    })
end)

-- ============================================
-- 🧹 CLEANUP
-- ============================================

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(activeStashes) do
        pcall(exports.ox_inventory.RemoveInventory, exports.ox_inventory, 'sleeping_' .. id)
    end
    GlobalState.sleepingPlayers = nil
end)

-- ============================================
-- 🚀 INIT
-- ============================================

MySQL.ready(function()
    if Config.AutoCreateTable then InitializeDatabase() end

    Wait(2000)

    local dbEntries = LoadAllFromDB()
    for _, entry in ipairs(dbEntries) do
        -- ✅ If skin is NULL, try loading from playerskins now
        local skin = entry.skin
        if not skin and entry.charid and entry.charid > 0 then
            skin = LoadSkinFromDB(entry.charid)
            if skin then
                MySQL.update('UPDATE ' .. Config.DatabaseTable .. ' SET skin = ? WHERE identifier = ?', {skin, entry.identifier})
                Debug('Backfilled skin for:', entry.identifier)
            end
        end

        sleepingPlayers[entry.identifier] = {
            coords = entry.coords,
            model = entry.model,
            charid = entry.charid,
            skin = skin,
            inventory = entry.inventory,
        }
    end

    SyncGlobalState()
    Debug('Server initialized with', #dbEntries, 'sleeping players')
end)

-- ============================================
-- 📤 EXPORTS
-- ============================================

exports('GetSleepingPlayer', function(id) return sleepingPlayers[id] end)
exports('GetAllSleepingPlayers', function() return sleepingPlayers end)
exports('RemoveSleepingPlayer', function(id) RemoveSleepingEntry(id) end)
