-- Server-authoritative field and dealer.
-- Only natives that exist server-side are used here (OneSync required).

local plants = {}              -- [netId] = { entity, coords }
local fieldState = nil         -- nil | 'resolving' | 'ready'
local resolveToken = 0
local dealerEntity, dealerNetId

local function notify(source, kind, msg)
    TriggerClientEvent('ox_lib:notify', source, { type = kind, description = msg })
end

local function dist2d(a, b)
    return #(vector2(a.x, a.y) - vector2(b.x, b.y))
end

local function isNearField(coords)
    return dist2d(coords, Config.Field.coords) <= Config.Field.radius + 15.0
end

local function isNearDealer(coords)
    return dist2d(coords, Config.Dealer.coords) <= Config.Dealer.sellDistance
end

-- ---------------------------------------------------------------- plants
-- Deterministic x/y layout (same every session). Z comes from a client.
local function layout()
    local out = {}
    local c = Config.Field.coords
    for i = 1, Config.Field.props do
        local angle = (i / Config.Field.props) * math.pi * 2
        local d = math.sqrt(((i * 37) % 100) / 100) * Config.Field.radius
        out[i] = { x = c.x + math.cos(angle) * d, y = c.y + math.sin(angle) * d }
    end
    return out
end

local function spawnPlant(coords)
    local obj = CreateObject(Config.Field.model, coords.x, coords.y, coords.z, true, true, false)
    if not obj or obj == 0 then return nil end

    pcall(SetEntityHeading, obj, math.random(0, 359) + 0.0)
    FreezeEntityPosition(obj, true)

    local netId = NetworkGetNetworkIdFromEntity(obj)
    plants[netId] = { entity = obj, coords = vector3(coords.x, coords.y, coords.z) }
    return obj
end

local function spawnAll(points)
    local spawned = 0
    for i = 1, #points do
        if spawnPlant(points[i]) then spawned += 1 end
        Wait(0)
    end
    fieldState = 'ready'
    print(('[cannabis] field: %d/%d plants spawned'):format(spawned, #points))

    if Config.Field.exportMode then
        local lines = { 'Config.Field.positions = {' }
        for i = 1, #points do
            lines[#lines + 1] = ('    vector3(%.2f, %.2f, %.2f),'):format(points[i].x, points[i].y, points[i].z)
        end
        lines[#lines + 1] = '}'
        SaveResourceFile(GetCurrentResourceName(), 'positions.lua', table.concat(lines, '\n'), -1)
        print('[cannabis] positions written to positions.lua')
    end
end

-- A player near the field asks for it; one client resolves ground Z.
RegisterNetEvent('cannabis:fieldNear', function()
    local src = source
    if fieldState then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    if dist2d(GetEntityCoords(ped), Config.Field.coords) > Config.Field.radius + 60.0 then return end

    fieldState = 'resolving'
    resolveToken += 1
    local token = resolveToken

    TriggerClientEvent('cannabis:resolveField', src, token, layout())

    SetTimeout(60000, function()
        if fieldState == 'resolving' and token == resolveToken then
            fieldState = nil
            print('[cannabis] field resolve timed out, will retry when a player is near')
        end
    end)
end)

RegisterNetEvent('cannabis:fieldResolved', function(token, points)
    if fieldState ~= 'resolving' or token ~= resolveToken then return end
    if type(points) ~= 'table' then return end

    local c = Config.Field.coords
    local valid = {}
    for _, p in ipairs(points) do
        if type(p) == 'table' and type(p.x) == 'number' and type(p.y) == 'number' and type(p.z) == 'number'
            and dist2d(p, c) <= Config.Field.radius + 2.0
            and math.abs(p.z - c.z) <= Config.Field.zTolerance then
            valid[#valid + 1] = vector3(p.x, p.y, p.z)
        end
    end

    if #valid == 0 then
        fieldState = nil
        print('[cannabis] client resolved 0 usable ground points, will retry')
        return
    end

    spawnAll(valid)
end)

lib.callback.register('cannabis:fieldState', function()
    return fieldState
end)

-- ---------------------------------------------------------------- dealer
local function spawnDealer()
    local c = Config.Dealer
    local ped = CreatePed(4, c.model, c.coords.x, c.coords.y, c.coords.z + c.zOffset, c.coords.w, true, true)

    local deadline = GetGameTimer() + 5000
    while (not ped or ped == 0 or not DoesEntityExist(ped)) and GetGameTimer() < deadline do
        Wait(50)
    end

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        print('[cannabis] dealer CreatePed failed (is OneSync enabled?)')
        return
    end

    FreezeEntityPosition(ped, true)
    pcall(TaskStartScenarioInPlace, ped, c.scenario, 0, true)

    dealerEntity = ped
    dealerNetId = NetworkGetNetworkIdFromEntity(ped)

    -- clients find the dealer through this flag, so late joiners and
    -- re-streamed peds work without any event
    Entity(ped).state:set('cannabisDealer', true, true)

    print(('[cannabis] dealer spawned (netId %d)'):format(dealerNetId))
end

CreateThread(function()
    while true do
        Wait(15000)
        if not dealerEntity or not DoesEntityExist(dealerEntity) then
            dealerEntity, dealerNetId = nil, nil
            spawnDealer()
        end
    end
end)

-- ---------------------------------------------------------------- harvest
lib.callback.register('cannabis:giveReward', function(source, netId)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    if not isNearField(coords) then
        notify(source, 'error', 'You are not near the field.')
        return false
    end

    local entry = plants[netId]
    if not entry or not DoesEntityExist(entry.entity) then
        notify(source, 'error', 'That plant is already gone.')
        return false
    end

    if #(coords - entry.coords) > 6.0 then
        notify(source, 'error', 'You are too far from that plant.')
        return false
    end

    if not exports.ox_inventory:CanCarryItem(source, Config.Harvest.item, Config.Harvest.amount) then
        notify(source, 'error', 'You cannot carry that much.')
        return false
    end

    if not exports.ox_inventory:AddItem(source, Config.Harvest.item, Config.Harvest.amount) then
        notify(source, 'error', 'Harvest failed - check the item name.')
        return false
    end

    local respawnAt = entry.coords
    plants[netId] = nil
    DeleteEntity(entry.entity)

    SetTimeout(Config.Harvest.respawnTime * 1000, function()
        spawnPlant(respawnAt)
    end)

    return true
end)

-- ---------------------------------------------------------------- sell
lib.callback.register('cannabis:sell', function(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end

    if not isNearDealer(GetEntityCoords(ped)) then
        notify(source, 'error', 'You are not near the dealer.')
        return false
    end

    local amount = 1

    if (exports.ox_inventory:GetItemCount(source, Config.Dealer.item) or 0) < amount then
        notify(source, 'error', 'You have no cannabis to sell.')
        return false
    end

    local payout = amount * Config.Dealer.price

    if not exports.ox_inventory:CanCarryItem(source, Config.Dealer.payoutItem, payout) then
        notify(source, 'error', 'You cannot carry that much money.')
        return false
    end

    if not exports.ox_inventory:RemoveItem(source, Config.Dealer.item, amount) then
        notify(source, 'error', 'Could not remove the cannabis.')
        return false
    end

    if not exports.ox_inventory:AddItem(source, Config.Dealer.payoutItem, payout) then
        exports.ox_inventory:AddItem(source, Config.Dealer.item, amount)
        notify(source, 'error', 'Payment failed. Check the payout item name.')
        print(('[cannabis] AddItem failed for payout item "%s"'):format(Config.Dealer.payoutItem))
        return false
    end

    return { amount = amount, payout = payout }
end)

-- ---------------------------------------------------------------- boot / cleanup
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    local onesync = GetConvar('onesync', 'off')
    if onesync == 'off' then
        print('[cannabis] WARNING: OneSync is off. Server-side props/peds will not spawn.')
    end

    if Config.Field.positions and #Config.Field.positions > 0 then
        spawnAll(Config.Field.positions)
    else
        print('[cannabis] field will spawn when the first player comes near it')
    end

    spawnDealer()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, entry in pairs(plants) do
        if DoesEntityExist(entry.entity) then DeleteEntity(entry.entity) end
    end
    if dealerEntity and DoesEntityExist(dealerEntity) then DeleteEntity(dealerEntity) end
end)
