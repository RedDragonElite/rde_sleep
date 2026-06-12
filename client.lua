-- ============================================
-- 🐉 RDE SLEEPMOD - CLIENT v1.2.9
-- Proximity Loading | GlobalState Sync | ox_core
-- Pattern: rde_props / rde_doors style
-- Author: Red Dragon Elite | SerpentsByte
-- ============================================

local Config = require 'config'
local GetLanguageString = GetLanguageString

-- ============================================
-- 🎯 LOCAL STATE
-- ============================================

---@type table<string, {entity: number, skinApplied: boolean, targetSetup: boolean}>
local spawnedPeds = {}
local isCarrying = false
local carriedEntity = nil
local carriedIdentifier = nil
local isAdmin = false
local playerReady = false
local ownStateId = nil  -- ✅ Own stateId — skip spawning our own sleeper

-- ============================================
-- 🔧 UTILITY
-- ============================================

local function Debug(...)
    if Config.Debug then
        print('[^3RDE SLEEPMOD^0]', ...)
    end
end

local function LoadAnimDict(dict)
    if not dict then return false end
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 100 do Wait(10) t = t + 1 end
    return HasAnimDictLoaded(dict)
end

local function LoadModel(model)
    if type(model) == 'string' then model = joaat(model) end
    if not IsModelValid(model) then return false end
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local t = 0
    while not HasModelLoaded(model) and t < 100 do Wait(10) t = t + 1 end
    return HasModelLoaded(model)
end

-- ============================================
-- 🎨 SKIN APPLICATION (illenium-appearance format)
-- ============================================

local OVERLAY_MAP = {
    blemishes = 0, beard = 1, eyebrows = 2, ageing = 3,
    makeUp = 4, blush = 5, complexion = 6, sunDamage = 7,
    lipstick = 8, moleAndFreckles = 9, chestHair = 10, bodyBlemishes = 11,
}

local FACE_FEATURE_MAP = {
    noseWidth = 0, nosePeakHigh = 1, nosePeakSize = 2, noseBoneHigh = 3,
    nosePeakLowering = 4, noseBoneTwist = 5, eyeBrownHigh = 6, eyeBrownForward = 7,
    cheeksBoneHigh = 8, cheeksBoneWidth = 9, cheeksWidth = 10, eyesOpening = 11,
    lipsThickness = 12, jawBoneWidth = 13, jawBoneBackSize = 14, chinBoneLowering = 15,
    chinBoneLenght = 16, chinBoneSize = 17, chinHole = 18, neckThickness = 19,
}

local function ApplySkin(ped, skinJson)
    if not ped or not DoesEntityExist(ped) or not skinJson then return end

    local skin = type(skinJson) == 'string' and json.decode(skinJson) or skinJson
    if not skin then return end

    -- Try illenium-appearance first
    local ok = pcall(function()
        exports['illenium-appearance']:setPedAppearance(ped, skin)
    end)
    if ok then
        Debug('Skin via illenium-appearance')
        return
    end

    -- Manual application
    if skin.components then
        for _, c in pairs(skin.components) do
            if c.component_id and c.drawable and c.drawable >= 0 then
                SetPedComponentVariation(ped, c.component_id, c.drawable, c.texture or 0, 0)
            end
        end
    end

    if skin.props then
        for _, p in pairs(skin.props) do
            if p.prop_id then
                if p.drawable and p.drawable >= 0 then
                    SetPedPropIndex(ped, p.prop_id, p.drawable, p.texture or 0, true)
                else
                    ClearPedProp(ped, p.prop_id)
                end
            end
        end
    end

    if skin.headBlend then
        local h = skin.headBlend
        SetPedHeadBlendData(ped,
            h.shapeFirst or 0, h.shapeSecond or 0, h.shapeThird or 0,
            h.skinFirst or 0, h.skinSecond or 0, h.skinThird or 0,
            (h.shapeMix or 0.0) + 0.0, (h.skinMix or 0.0) + 0.0, (h.thirdMix or 0.0) + 0.0, false)
    end

    if skin.hair then
        SetPedComponentVariation(ped, 2, skin.hair.style or 0, skin.hair.texture or 0, 0)
        SetPedHairColor(ped, skin.hair.color or 0, skin.hair.highlight or 0)
    end

    if skin.faceFeatures then
        for name, val in pairs(skin.faceFeatures) do
            local idx = FACE_FEATURE_MAP[name]
            if idx then SetPedFaceFeature(ped, idx, (val or 0.0) + 0.0) end
        end
    end

    if skin.headOverlays then
        for name, ov in pairs(skin.headOverlays) do
            local idx = OVERLAY_MAP[name]
            if idx then
                SetPedHeadOverlay(ped, idx, ov.style or 0, (ov.opacity or 0.0) + 0.0)
                if ov.color ~= nil then
                    local ct = 1
                    if idx == 4 or idx == 5 or idx == 8 then ct = 2 end
                    SetPedHeadOverlayColor(ped, idx, ct, ov.color or 0, ov.secondColor or 0)
                end
            end
        end
    end

    if skin.eyeColor and skin.eyeColor >= 0 then
        SetPedEyeColor(ped, skin.eyeColor)
    end

    if skin.tattoos then
        ClearPedDecorations(ped)
        for _, tattooList in pairs(skin.tattoos) do
            if type(tattooList) == 'table' then
                for _, t in pairs(tattooList) do
                    local col = t.collection
                    local ov = t.hashMale or t.hashFemale
                    if col and ov then
                        AddPedDecorationFromHashes(ped, joaat(col), joaat(ov))
                    end
                end
            end
        end
    end

    Debug('Skin applied manually')
end

-- ============================================
-- 🎮 PED SPAWNING (Client-side, proximity)
-- ============================================

local function SpawnSleepingPed(identifier, data)
    if spawnedPeds[identifier] then return end

    local model = data.model
    if not LoadModel(model) then
        Debug('Model load failed:', model)
        return
    end

    -- ✅ FIX: Use stored Z directly — no offset!
    -- Offset was causing compounding Z drift (each carry-drop sinks ped further)
    local ped = CreatePed(4, model, data.x, data.y, data.z, data.w or 0.0, false, false)
    if not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(model)
        return
    end

    spawnedPeds[identifier] = { entity = ped, skinApplied = false, targetSetup = false }

    SetEntityInvincible(ped, Config.InvinciblePeds)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityCollision(ped, true, true)
    -- ✅ Do NOT freeze yet — anim needs to play first
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedConfigFlag(ped, 17, true)
    SetPedConfigFlag(ped, 24, true)
    SetPedConfigFlag(ped, 120, true)
    SetPedConfigFlag(ped, 122, true)
    SetPedConfigFlag(ped, 166, true)
    SetPedConfigFlag(ped, 281, true)
    TaskSetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetModelAsNoLongerNeeded(model)

    CreateThread(function()
        Wait(Config.Performance.skinApplyDelay)
        if not DoesEntityExist(ped) or not spawnedPeds[identifier] then return end

        local skinJson = lib.callback.await('rde_sleepmod:getSkinData', false, identifier)
        if skinJson then
            ApplySkin(ped, skinJson)
            if spawnedPeds[identifier] then spawnedPeds[identifier].skinApplied = true end
        end

        -- ✅ FIX: illenium-appearance clears ped tasks — need longer delay before anim
        Wait(500)
        if not DoesEntityExist(ped) then return end

        -- ✅ ANIM FIX v1.3.0 — Two-phase sleep animation
        -- Phase 1: @base clip played ONCE  → ped physically lies down (no loop)
        -- Phase 2: @idle_a clip looped     → ped breathes/sleeps in position
        --
        -- ROOT CAUSE of old "idle twitch" bug:
        --   @base clips with flag=1 (loop) repeat the lie-down intro forever.
        --   Config.SleepingAnimations now contains ONLY @idle_a dicts.
        --   This function derives the @base dict automatically for phase 1.
        local anims = Config.SleepingAnimations
        local anim  = anims[math.random(#anims)]  -- picks an @idle_a entry

        -- Phase 1 — derive @base dict from @idle_a dict name
        local baseDict = anim.dict:gsub('@idle_a', '@base')
        if LoadAnimDict(baseDict) then
            -- flag 0 = play once, duration 2400ms covers the full lie-down motion
            TaskPlayAnim(ped, baseDict, 'base', 8.0, -8.0, 2400, 0, 0, false, false, false)
            Wait(2200)
        end

        -- Phase 2 — loop the actual sleep idle
        if DoesEntityExist(ped) and LoadAnimDict(anim.dict) then
            TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 1, 0, false, false, false)
        end

        -- ✅ Wait for animation to settle, then freeze (NO PlaceObjectOnGroundProperly!)
        Wait(1000)
        if DoesEntityExist(ped) then
            FreezeEntityPosition(ped, true)
        end

        if spawnedPeds[identifier] and not spawnedPeds[identifier].targetSetup then
            SetupTarget(ped, identifier)
            spawnedPeds[identifier].targetSetup = true
        end

        Debug('Ped ready:', identifier, '| skin:', skinJson and 'YES' or 'NO')
    end)
end

local function DespawnSleepingPed(identifier)
    local data = spawnedPeds[identifier]
    if not data then return end
    if data.entity and DoesEntityExist(data.entity) then
        pcall(exports.ox_target.removeLocalEntity, exports.ox_target, data.entity)
        DeleteEntity(data.entity)
    end
    spawnedPeds[identifier] = nil
end

-- ============================================
-- 🎯 OX_TARGET
-- ============================================

function SetupTarget(entity, identifier)
    if not DoesEntityExist(entity) then return end

    -- ✅ FIX: Check admin status EACH TIME a target is set up
    -- (instead of once at init — groups might not be loaded yet at that point)
    local adminStatus = lib.callback.await('rde_sleepmod:isAdmin', false) or false
    Debug('SetupTarget admin check:', adminStatus, 'for:', identifier)

    local options = {
        {
            name = 'rde_sleep_rob_' .. identifier,
            icon = Config.TargetIcons.rob,
            label = GetLanguageString('rob_player'),
            distance = Config.TargetDistance,
            onSelect = function() RobSleepingPlayer(entity, identifier) end,
        },
        {
            name = 'rde_sleep_carry_' .. identifier,
            icon = Config.TargetIcons.carry,
            label = GetLanguageString('carry_player'),
            distance = Config.TargetDistance,
            canInteract = function() return not isCarrying end,
            onSelect = function() StartCarrying(entity, identifier) end,
        },
    }

    if adminStatus then
        options[#options + 1] = {
            name = 'rde_sleep_wake_' .. identifier,
            icon = Config.TargetIcons.wake,
            label = GetLanguageString('wake_player'),
            distance = Config.TargetDistance,
            onSelect = function() TriggerServerEvent('rde_sleepmod:wakePlayer', identifier) end,
        }
    end

    exports.ox_target:addLocalEntity(entity, options)
end

-- ============================================
-- 🔫 ROBBERY
-- ============================================

function RobSleepingPlayer(entity, identifier)
    if not DoesEntityExist(entity) then return end
    if #(GetEntityCoords(entity) - GetEntityCoords(cache.ped)) > Config.RobDistance then
        lib.notify({ title = GetLanguageString('error'), description = GetLanguageString('too_far'), type = 'error' })
        return
    end

    local success = lib.progressBar({
        duration = Config.RobDuration,
        label = GetLanguageString('searching_pockets'),
        useWhileDead = false, canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = Config.RobAnimation.dict, clip = Config.RobAnimation.clip },
    })

    if success then
        local registered = lib.callback.await('rde_sleepmod:registerStash', false, identifier)
        if registered then
            exports.ox_inventory:openInventory('stash', 'sleeping_' .. identifier)
            lib.notify({ title = GetLanguageString('success'), description = GetLanguageString('inventory_opened'), type = 'success' })
        else
            lib.notify({ title = GetLanguageString('error'), description = GetLanguageString('inventory_failed'), type = 'error' })
        end
    end
end

-- ============================================
-- 🏃 CARRYING
-- ============================================

function StartCarrying(entity, identifier)
    if not DoesEntityExist(entity) or isCarrying then
        if isCarrying then
            lib.notify({ title = GetLanguageString('warning'), description = GetLanguageString('already_carrying'), type = 'warning' })
        end
        return
    end

    local playerPed = cache.ped
    local initCoords = GetEntityCoords(entity)
    local initHeading = GetEntityHeading(entity)

    isCarrying = true
    carriedEntity = entity
    carriedIdentifier = identifier

    FreezeEntityPosition(entity, false)
    LoadAnimDict(Config.CarryAnimation.carrier.dict)
    LoadAnimDict(Config.CarryAnimation.carried.dict)

    TaskPlayAnim(entity, Config.CarryAnimation.carried.dict, Config.CarryAnimation.carried.clip,
        8.0, -8.0, -1, 33, 0, false, false, false)
    AttachEntityToEntity(entity, playerPed, 0,
        Config.CarryOffset.x, Config.CarryOffset.y, Config.CarryOffset.z,
        Config.CarryOffset.pitch, Config.CarryOffset.roll, Config.CarryOffset.yaw,
        false, false, false, false, 2, true)
    TaskPlayAnim(playerPed, Config.CarryAnimation.carrier.dict, Config.CarryAnimation.carrier.clip,
        8.0, -8.0, -1, 49, 0, false, false, false)

    lib.notify({ title = GetLanguageString('success'), description = GetLanguageString('player_carried'), type = 'success' })
    lib.showTextUI(GetLanguageString('press_release'), { position = 'right-center' })

    CreateThread(function()
        -- Wait(0) is required here — IsControlJustPressed() only returns true
        -- for exactly one frame. Any higher interval would miss the keypress.
        -- Legitimate Standards exception: control detection thread.
        while isCarrying and DoesEntityExist(entity) and DoesEntityExist(playerPed) do
            if IsControlJustPressed(0, 38) or IsEntityDead(playerPed) then
                StopCarrying(entity, initCoords, initHeading)
                break
            end
            Wait(0)
        end
    end)
end

function StopCarrying(entity, origCoords, origHeading)
    if not isCarrying or not DoesEntityExist(entity) then return end

    local playerPed = cache.ped
    local coords = GetEntityCoords(playerPed)

    ClearPedTasksImmediately(entity)
    ClearPedTasksImmediately(playerPed)
    DetachEntity(entity, true, true)

    -- ✅ FIX: Use player's current Z directly — no offset, no GetGroundZ!
    -- GetGroundZFor_3dCoord returns ROOF in interiors
    -- Offset causes compounding Z drift on repeated carry-drops
    local fwd = GetEntityForwardVector(playerPed)
    local x = coords.x + fwd.x * 1.5
    local y = coords.y + fwd.y * 1.5
    local z = coords.z  -- Player is standing on ground, use their Z

    SetEntityCoordsNoOffset(entity, x, y, z, false, false, false)
    SetEntityHeading(entity, GetEntityHeading(playerPed))
    SetEntityCollision(entity, true, true)

    -- Ped is already horizontal (was in carry anim) — skip the lie-down intro,
    -- go straight to the sleep idle loop.
    local anims = Config.SleepingAnimations
    local anim  = anims[math.random(#anims)]
    if LoadAnimDict(anim.dict) then
        TaskPlayAnim(entity, anim.dict, anim.clip, 8.0, -8.0, -1, 1, 0, false, false, false)
    end
    
    Wait(1000)
    FreezeEntityPosition(entity, true)

    -- ✅ FIX: Send PLAYER coords (x, y, z) not entity coords
    -- Entity Z drifts after animation+freeze, player Z is correct (standing on ground)
    TriggerServerEvent('rde_sleepmod:updatePosition', carriedIdentifier,
        { x = x, y = y, z = z, w = GetEntityHeading(entity) })

    lib.hideTextUI()
    lib.notify({ title = GetLanguageString('success'), description = GetLanguageString('player_released'), type = 'success' })

    isCarrying = false
    carriedEntity = nil
    carriedIdentifier = nil
end

-- ============================================
-- 📡 PROXIMITY LOADING LOOP
-- ============================================

CreateThread(function()
    while not cache.ped do Wait(500) end

    -- ✅ FIX: Poll for own stateId — LocalPlayer.state may not be ready immediately on resource restart
    -- ox_core sets the statebag slightly after resource start, so we retry until we get it
    local stateIdAttempts = 0
    while not ownStateId and stateIdAttempts < 20 do
        ownStateId = LocalPlayer.state.identifier or nil
        if not ownStateId then Wait(250) end
        stateIdAttempts = stateIdAttempts + 1
    end
    Debug('Startup: own stateId:', ownStateId or 'NOT FOUND after retries')

    playerReady = true
    isAdmin = lib.callback.await('rde_sleepmod:isAdmin', false) or false
    Debug('Player ready | admin:', isAdmin)

    while true do
        Wait(Config.Performance.proximityTick)

        local sleepData = GlobalState.sleepingPlayers
        if not sleepData or not next(sleepData) then
            for id in pairs(spawnedPeds) do DespawnSleepingPed(id) end
            goto continue
        end

        local playerCoords = GetEntityCoords(cache.ped)
        local visibleCount = 0

        for identifier, data in pairs(sleepData) do
            -- ✅ Never spawn our own sleeper — it gets removed by ox:playerLoaded
            if ownStateId and identifier == ownStateId then goto skipOwn end

            local dist = #(playerCoords - vector3(data.x, data.y, data.z))

            if dist <= Config.Performance.renderDistance then
                if not spawnedPeds[identifier] and visibleCount < Config.Performance.maxVisiblePeds then
                    SpawnSleepingPed(identifier, data)
                end
                visibleCount = visibleCount + 1
            elseif dist > Config.Performance.despawnDistance and spawnedPeds[identifier] then
                DespawnSleepingPed(identifier)
            end
            ::skipOwn::
        end

        for identifier in pairs(spawnedPeds) do
            if not sleepData[identifier] then
                DespawnSleepingPed(identifier)
            end
        end

        ::continue::
    end
end)

-- ============================================
-- 🎯 PLAYER EVENTS
-- ============================================

RegisterNetEvent('ox:playerLoaded', function()
    Debug('ox:playerLoaded')
    -- ✅ Cache own stateId so proximity loop skips our own sleeper
    ownStateId = LocalPlayer.state.identifier or nil
    Debug('ox:playerLoaded: own stateId:', ownStateId)

    -- ✅ FIX: 3s delay (was 10s) — ensures cache is written before early disconnect
    -- Critical for new-account creation flow where player may disconnect within seconds
    SetTimeout(3000, function()
        local ped = cache.ped
        if ped and DoesEntityExist(ped) then
            TriggerServerEvent('rde_sleepmod:saveAppearanceCache', {
                coords = json.encode(vector4(GetEntityCoords(ped), GetEntityHeading(ped))),
                model = GetEntityModel(ped),
            })
        end
    end)
end)

RegisterNetEvent('ox:playerLogout', function()
    ownStateId = nil
    local ped = cache.ped
    if not ped then return end
    TriggerServerEvent('rde_sleepmod:createSleepingPed', {
        coords = json.encode(vector4(GetEntityCoords(ped), GetEntityHeading(ped))),
        model = GetEntityModel(ped),
    })
end)

-- ✅ FIX: Teleport player to sleeping ped position on reconnect
-- (if someone carried the sleeper, player spawns at new location)
RegisterNetEvent('rde_sleepmod:teleportToSleepPos', function(x, y, z, w)
    CreateThread(function()
        local ped = cache.ped
        if not ped or not DoesEntityExist(ped) then
            -- Wait for ped
            local timeout = 0
            while (not ped or not DoesEntityExist(ped)) and timeout < 100 do
                Wait(100)
                ped = cache.ped
                timeout = timeout + 1
            end
        end
        if not ped or not DoesEntityExist(ped) then return end

        local currentCoords = GetEntityCoords(ped)
        local targetCoords = vector3(x, y, z)
        local dist = #(currentCoords - targetCoords)

        -- Only teleport if > 5m from sleeping position
        if dist > 5.0 then
            DoScreenFadeOut(500)
            Wait(500)
            SetEntityCoords(ped, x, y, z, false, false, false, false)
            SetEntityHeading(ped, w or 0.0)
            PlaceObjectOnGroundProperly(ped)
            Wait(300)
            DoScreenFadeIn(500)
            Debug(('Teleported to sleeping position: %.1f, %.1f, %.1f (was %.1f away)'):format(x, y, z, dist))
        end
    end)
end)

-- ============================================
-- 🧹 CLEANUP
-- ============================================

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- ✅ FIX: Save current coords before cleanup — catches disconnects and resource restarts
    local ped = cache.ped
    if ped and DoesEntityExist(ped) then
        TriggerServerEvent('rde_sleepmod:saveAppearanceCache', {
            coords = json.encode(vector4(GetEntityCoords(ped), GetEntityHeading(ped))),
            model = GetEntityModel(ped),
        })
        Debug('onResourceStop: coords saved')
    end
    if isCarrying and carriedEntity then
        StopCarrying(carriedEntity, GetEntityCoords(carriedEntity), GetEntityHeading(carriedEntity))
    end
    for id in pairs(spawnedPeds) do DespawnSleepingPed(id) end
    lib.hideTextUI()
end)

-- ============================================
-- 🚀 AUTO-SAVE (every 5 min)
-- ============================================

CreateThread(function()
    while true do
        -- ✅ FIX: 30s interval (was 5min) — ensures coords are always fresh on disconnect
        Wait(30000)
        local ped = cache.ped
        if ped and DoesEntityExist(ped) then
            TriggerServerEvent('rde_sleepmod:saveAppearanceCache', {
                coords = json.encode(vector4(GetEntityCoords(ped), GetEntityHeading(ped))),
                model = GetEntityModel(ped),
            })
            Debug('Auto-saved cache')
        end
    end
end)

-- ============================================
-- 🎮 COMMANDS
-- ============================================

RegisterCommand('sleeplogout', function()
    local ped = cache.ped
    if not ped then return end
    TriggerServerEvent('rde_sleepmod:createSleepingPed', {
        coords = json.encode(vector4(GetEntityCoords(ped), GetEntityHeading(ped))),
        model = GetEntityModel(ped),
    })
    lib.notify({ title = GetLanguageString('success'), description = 'Sleeping...', type = 'success' })
    Wait(1000)
    TriggerEvent('ox:playerLogout')
end, false)

if Config.Debug then
    RegisterCommand('sleeptest', function()
        local s, g = 0, 0
        for _ in pairs(spawnedPeds) do s = s + 1 end
        local data = GlobalState.sleepingPlayers
        if data then for _ in pairs(data) do g = g + 1 end end
        print(('[RDE SLEEPMOD] Spawned: %d | GlobalState: %d'):format(s, g))
    end, false)
end

-- ============================================
-- 📤 EXPORTS
-- ============================================

exports('IsClone', function(entity)
    for _, d in pairs(spawnedPeds) do if d.entity == entity then return true end end
    return false
end)
exports('IsSleepingClone', function(entity)
    for _, d in pairs(spawnedPeds) do if d.entity == entity then return true end end
    return false
end)
