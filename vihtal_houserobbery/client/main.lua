
local ESX = exports['es_extended']:getSharedObject()

local robbing = false
local currentHouse = nil
local noiseLevel = 0
local noiseBarActive = false
local noisePedSpawned = false
local isCrouching = false
local helpActive = false
local lootedSpots = {}
local lootTargets = {}
local entryTargets = {}


---@param dict string 
---@param anim string 
---@param duration number|nil 
local function PlayAnim(dict, anim, duration)
    local ped = PlayerPedId()
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, duration or -1, 1, 0, false, false, false)
    if duration and duration > 0 then
        Wait(duration)
        ClearPedTasks(ped)
    end
end


---@param msg string 
---@param duration number|nil 
local function ShowNotification(msg, duration)
    exports.ox_lib:showTextUI(msg)
    helpActive = true
    SetTimeout(duration or 2000, function()
        exports.ox_lib:hideTextUI()
        helpActive = false
    end)
end


---@param coords vector3|vector4 
---@param heading number|nil 
local function TeleportWithFade(coords, heading)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), heading or coords.w or 0.0)
    Wait(250)
    DoScreenFadeIn(2000)
end


---@param itemName string 
---@return string Label 
local function GetLockpickLabel(itemName)
    
    if exports.ox_inventory and exports.ox_inventory.Items then
        local items = exports.ox_inventory:Items()
        if items and items[itemName] and items[itemName].label then
            return items[itemName].label
        end
    end
    
    local labels = {
        lockpick = 'Lockpick',
        advanced_lockpick = 'Advanced Lockpick',
        master_lockpick = 'Master Lockpick'
    }
    return labels[itemName] or itemName
end

---@param house table 
---@return table Array 
local function GetLockpickItems(house)
    return house.lockpickItems 
        or (house.lockpickItem and {house.lockpickItem}) 
        or {Config.LockpickItem or 'lockpick'}
end

---@return boolean
local function IsPolice()
    local playerData = ESX.GetPlayerData()
    return playerData.job and playerData.job.name == Config.PoliceJob
end

---@param cb function 
local function GetCopsOnline(cb)
    ESX.TriggerServerCallback('houserobbery:getCops', function(count)
        cb(count)
    end)
end

---@param offsetX number|nil 
local function SpawnHostilePed(offsetX)
    local pedModel = GetHashKey("a_m_m_business_01")
    local weaponHash = GetHashKey("WEAPON_PISTOL")
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(10) end
    
    local enemy = CreatePed(4, pedModel, playerCoords.x + (offsetX or 1.5), playerCoords.y, playerCoords.z, 0.0, true, true)
    if not DoesEntityExist(enemy) then return end
    
    
    SetEntityVisible(enemy, true, false)
    FreezeEntityPosition(enemy, false)
    SetEntityInvincible(enemy, false)
    SetBlockingOfNonTemporaryEvents(enemy, true)
    GiveWeaponToPed(enemy, weaponHash, 100, false, true)
    SetPedDropsWeaponsWhenDead(enemy, false)
    SetPedCombatAttributes(enemy, 46, true)
    SetPedCombatAbility(enemy, 2)
    SetPedCombatRange(enemy, 2)
    SetPedAsEnemy(enemy, true)
    local relGroupHash = GetHashKey("HATES_PLAYER")
    SetPedRelationshipGroupHash(enemy, relGroupHash)
    SetRelationshipBetweenGroups(5, relGroupHash, GetPedRelationshipGroupDefaultHash(playerPed))
    SetRelationshipBetweenGroups(5, GetPedRelationshipGroupDefaultHash(playerPed), relGroupHash)
    ClearPedTasksImmediately(enemy)
    TaskCombatPed(enemy, playerPed, 0, 16)
    SetEntityAsNoLongerNeeded(enemy)
end

---------------------------------------------------------------------------
-- DISPATCH ALERTS
---------------------------------------------------------------------------

--- Sends a dispatch alert to police
---@param title string Alert title
---@param description string Alert description
---@param icon string FontAwesome icon
---@param coords vector3|vector4 Location
local function SendDispatchAlert(title, description, icon, coords)
    if not Config.UseDispatch then return end
    exports['core_dispatch']:addCall(
        '10-31',
        title,
        {{icon = icon, info = description}},
        {coords.x, coords.y, coords.z},
        'police',
        10000,
        431,
        3
    )
end


---@param house table 
---@param cb function 
local function TryLockpick(house, cb)
    ESX.TriggerServerCallback('houserobbery:tryLockpick', function(ok, reason, mins)
        if not ok then
            if cb then cb(reason, mins) end
            return
        end
        
        local itemsToCheck = GetLockpickItems(house)
        local foundItem, foundSlot = nil, nil
        
        for _, itemName in ipairs(itemsToCheck) do
            local count = exports.ox_inventory:Search('count', itemName)
            if count and count > 0 then
                local slots = exports.ox_inventory:Search('slots', itemName)
                if slots then
                    if type(slots) == 'table' and #slots > 0 then
                        foundItem, foundSlot = itemName, slots[1]
                    elseif type(slots) == 'number' then
                        foundItem, foundSlot = itemName, slots
                    else
                        foundItem = itemName
                    end
                    break
                end
            end
        end
        
        if not foundItem then
            ShowNotification('You need: ' .. GetLockpickLabel(itemsToCheck[1]))
            if cb then cb("no_lockpick") end
            return
        end
        
        local ped = PlayerPedId()
        RequestAnimDict('veh@break_in@0h@p_m_one@')
        while not HasAnimDictLoaded('veh@break_in@0h@p_m_one@') do Wait(10) end
        TaskPlayAnim(ped, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 8.0, -8.0, -1, 1, 0, false, false, false)
        
        exports.ox_lib:progressBar({
            duration = Config.LockpickDuration or 3000,
            label = 'Lockpicking',
            useWhileDead = false,
            canCancel = false,
            disable = {move = true, car = true, combat = true}
        })
        ClearPedTasks(ped)
        
        
        TriggerServerEvent('houserobbery:useLockpick', foundItem, foundSlot)
        
        
        local failChance = house.lockpickFailChance or Config.LockpickFailChance or 30
        if math.random(1, 100) <= failChance then
            ESX.TriggerServerCallback('houserobbery:tryLockpick', function()
                exports.ox_lib:notify({
                    title = 'Lockpick',
                    description = ('Failed! Someone heard you... Wait %d minutes.'):format(Config.CooldownMinutes or 30),
                    type = 'error',
                    duration = 3500
                })
                SendDispatchAlert('Lockpick Attempt Failed', 'Lockpick attempt failed, possible break-in.', 'lock', GetEntityCoords(ped))
                SpawnHostilePed()
                if cb then cb("fail") end
            end, house, 'fail')
            return
        end
        
       
        ESX.TriggerServerCallback('houserobbery:tryLockpick', function()
            if cb then cb("success") end
        end, house, 'success')
    end, house)
end

---@param house table 
---@param result string 
---@param mins number|nil 
local function HandleLockpickResult(house, result, mins)
    if result == "success" then
        EnterHouse(house)
    elseif result == "cooldown" then
        exports.ox_lib:notify({
            title = 'Lockpick',
            description = ('You cannot try again yet. Wait %d minutes.'):format(mins or Config.CooldownMinutes or 30),
            type = 'error',
            duration = 3500
        })
    elseif result == "house_cooldown" then
        exports.ox_lib:notify({
            title = 'Robbery',
            description = ('You cannot rob this house again for %d minutes.'):format(mins or Config.CooldownMinutes or 30),
            type = 'error',
            duration = 3500
        })
    elseif result == "no_lockpick" then
    elseif result == "fail" then
    end
end

---@param house table 
---@param index number 
---@return number Zone 
local function CreateEntryTarget(house, index)
    local coords = vector3(house.coords.x, house.coords.y, house.coords.z)
    return exports.ox_target:addSphereZone({
        coords = coords,
        radius = 1.2,
        debug = false,
        options = {{
            name = 'entrydoor_' .. index,
            label = 'Lockpick Door',
            icon = 'fas fa-door-closed',
            canInteract = function()
                return #(GetEntityCoords(PlayerPedId()) - coords) <= 2.0
            end,
            onSelect = function()
                GetCopsOnline(function(cops)
                    if cops >= Config.MinCopsOnline then
                        TryLockpick(house, function(result, mins)
                            HandleLockpickResult(house, result, mins)
                        end)
                    else
                        ShowNotification('Not enough police online!')
                    end
                end)
            end
        }}
    })
end

local function RemoveEntryTargets()
    for _, id in pairs(entryTargets) do
        exports.ox_target:removeZone(id)
    end
    entryTargets = {}
end

local function CreateAllEntryTargets()
    RemoveEntryTargets()
    for i, house in ipairs(Config.Houses) do
        entryTargets[i] = CreateEntryTarget(house, i)
    end
end


local function StartCrouchThread()
    CreateThread(function()
        while robbing do
            if IsControlJustPressed(0, 36) then 
                isCrouching = not isCrouching
                if isCrouching then
                    RequestAnimSet('move_ped_crouched')
                    while not HasAnimSetLoaded('move_ped_crouched') do Wait(10) end
                    SetPedMovementClipset(PlayerPedId(), 'move_ped_crouched', 0.25)
                else
                    ResetPedMovementClipset(PlayerPedId(), 0.25)
                end
                SendNUIMessage({action = 'setCrouching', crouching = isCrouching})
            end
            Wait(0)
        end
        if isCrouching then
            ResetPedMovementClipset(PlayerPedId(), 0.25)
            isCrouching = false
        end
    end)
end

---@param isSprinting boolean
---@param isRunning boolean
---@param isWalking boolean
---@return number Noise 
local function CalculateNoiseIncrease(isSprinting, isRunning, isWalking)
    local noise = Config.NoiseSettings or {}
    
    if isCrouching then
        if isSprinting then return noise.crouchSprint or 4
        elseif isRunning then return noise.crouchRun or 2
        elseif isWalking then return noise.crouchWalk or 1
        end
    else
        if isSprinting then return noise.sprint or 20
        elseif isRunning then return noise.run or 12
        elseif isWalking then return noise.walk or 6
        end
    end
    return 0
end


local function HandleNoiseCaught()
    if not currentHouse or not currentHouse.coords then return end
    
    ESX.TriggerServerCallback('houserobbery:tryLockpick', function(ok, reason, mins)
        local cooldownMins = mins or Config.CooldownMinutes or 30
        exports.ox_lib:notify({
            title = 'Robbery',
            description = ('You made too much noise! Wait %d minutes.'):format(cooldownMins),
            type = 'error'
        })
        
        -- Dispatch alert
        SendDispatchAlert('Loud Noise Reported', 'Possible robbery, loud noise detected.', 'volume-up', currentHouse.coords)
        
        
        TeleportWithFade(currentHouse.coords)
        TriggerServerEvent('houserobbery:setBucket', 0)
        Wait(250)
        
        
        SpawnHostilePed()
        
        robbing = false
        ExitHouse()
    end, currentHouse, 'noise')
end

local function StartNoiseThread()
    CreateThread(function()
        while robbing do
            local ped = PlayerPedId()
            local isSprinting = IsPedSprinting(ped)
            local isRunning = IsPedRunning(ped)
            local isWalking = IsPedWalking(ped)
            local isMoving = isSprinting or isRunning or isWalking
            
            if isMoving then
                local increase = CalculateNoiseIncrease(isSprinting, isRunning, isWalking)
                noiseLevel = math.min(100, noiseLevel + increase)
            else
                local decay = Config.NoiseSettings and Config.NoiseSettings.decay or 2
                noiseLevel = math.max(0, noiseLevel - decay)
            end
            
            
            SendNUIMessage({
                action = 'updateNoise',
                noise = noiseLevel,
                max = 100,
                warning = noiseLevel >= (Config.NoiseUI.wakeUpThreshold or 80)
            })
            
            
            if noiseLevel >= 100 and not noisePedSpawned then
                noisePedSpawned = true
                HandleNoiseCaught()
            end
            
            Wait(500)
        end
        noiseBarActive = false
    end)
end

---@param house table 
function EnterHouse(house)
    local myServerId = GetPlayerServerId(PlayerId())
    TriggerServerEvent('houserobbery:setBucket', myServerId)
    
    
    if house and house.interior then
        TeleportWithFade(house.interior)
    end
    
    
    RemoveEntryTargets()
    
    
    noiseLevel = 0
    noisePedSpawned = false
    isCrouching = false
    lootedSpots = {}
    robbing = true
    currentHouse = house
    
    
    if Config.NoiseUI.showNoiseBar then
        SendNUIMessage({
            action = 'showUI',
            position = Config.NoiseUI.barPosition,
            showHint = Config.NoiseUI.showCrouchHint
        })
        SetNuiFocus(false, false)
    end
    
   
    if not noiseBarActive then
        noiseBarActive = true
        StartCrouchThread()
        StartNoiseThread()
    end
    
    ShowNotification('Search for loot!')
    
    
    lootTargets = {}
    if house.loot then
        for idx, loot in ipairs(house.loot) do
            lootTargets[idx] = exports.ox_target:addSphereZone({
                coords = loot.coords,
                radius = 0.7,
                debug = false,
                options = {{
                    name = 'lootspot_' .. idx,
                    label = 'Steal',
                    icon = 'fas fa-hand-paper',
                    canInteract = function()
                        return #(GetEntityCoords(PlayerPedId()) - loot.coords) <= 2.0
                    end,
                    onSelect = function()
                        TryLoot()
                    end
                }}
            })
        end
    end
    
    local exitCoords = house.exit or vector3(265.9945, -1007.3914, -101.0141)
end

function ExitHouse()
    TriggerServerEvent('houserobbery:setBucket', 0)
    
    
    noiseLevel = 0
    noisePedSpawned = false
    robbing = false
    currentHouse = nil
    
    
    SendNUIMessage({action = 'hideUI'})
    
    
    if isCrouching then
        ResetPedMovementClipset(PlayerPedId(), 0.25)
        isCrouching = false
    end
    
   
    if lootTargets then
        for _, id in pairs(lootTargets) do
            if id then exports.ox_target:removeZone(id) end
        end
        lootTargets = {}
    end
    
    CreateAllEntryTargets()
    
    ShowNotification('You left the house.')
end

function TryLoot()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    
    local closestIdx, closestDist = nil, math.huge
    if currentHouse and currentHouse.loot then
        for idx, loot in ipairs(currentHouse.loot) do
            local dist = #(pos - loot.coords)
            if dist < closestDist then
                closestDist = dist
                closestIdx = idx
            end
        end
    end
    
    if not closestIdx then return end
    
    
    if lootedSpots[closestIdx] then
        exports.ox_lib:notify({
            title = 'Robbery',
            description = 'You found nothing!',
            type = 'error',
            duration = 2500
        })
        return
    end
    
    
    TaskStartScenarioInPlace(ped, 'PROP_HUMAN_BUM_BIN', 0, true)
    exports.ox_lib:progressBar({
        duration = Config.SearchDuration or 4000,
        label = 'Searching',
        useWhileDead = false,
        canCancel = false,
        disable = {move = true, car = true, combat = true}
    })
    ClearPedTasks(ped)
    
    
    lootedSpots[closestIdx] = true
    
    
    if lootTargets[closestIdx] then
        exports.ox_target:removeZone(lootTargets[closestIdx])
        lootTargets[closestIdx] = nil
    end
    
    
    TriggerServerEvent('houserobbery:tryLoot', currentHouse, closestIdx)
end

CreateThread(function()
    for _, house in ipairs(Config.Houses) do
        if house.blip then
            local blip = AddBlipForCoord(house.coords.x, house.coords.y, house.coords.z)
            local data = house.blipData or {}
            SetBlipSprite(blip, data.sprite or 40)
            SetBlipColour(blip, data.color or 2)
            SetBlipScale(blip, data.scale or 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(data.name or "Robbable House")
            EndTextCommandSetBlipName(blip)
        end
    end
end)

CreateThread(function()
    CreateAllEntryTargets()
    
    local uniqueExits = {}
    for _, house in ipairs(Config.Houses) do
        local exit = house.exit
        if exit then
            local key = string.format('%.4f_%.4f_%.4f', exit.x, exit.y, exit.z)
            if not uniqueExits[key] then
                
                uniqueExits[key] = {exit = exit, entry = house.coords}
            end
        end
    end
    
    for _, data in pairs(uniqueExits) do
        local exitCoords = data.exit
        local fallbackEntry = data.entry
        exports.ox_target:addSphereZone({
            coords = exitCoords,
            radius = 0.7,
            debug = false,
            options = {{
                name = 'exitdoor',
                label = 'Exit',
                icon = 'fas fa-door-open',
                canInteract = function()
                    return #(GetEntityCoords(PlayerPedId()) - exitCoords) <= 2.0
                end,
                onSelect = function()
                    if currentHouse and currentHouse.coords then
                        TeleportWithFade(currentHouse.coords)
                    else
                        
                        TeleportWithFade(fallbackEntry)
                    end
                    ExitHouse()
                end
            }}
        })
    end
end)



RegisterNetEvent('houserobbery:lootResult', function(success, item, count)
    if success then
        ShowNotification(('You found %dx %s!'):format(count, item))
    else
        exports.ox_lib:notify({
            title = 'Robbery',
            description = 'You found nothing!',
            type = 'error',
            duration = 2500
        })
    end
end)
