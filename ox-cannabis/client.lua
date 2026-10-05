-- Props and the dealer are created by the server. The client draws blips,
-- resolves ground height once when asked, and attaches interactions.

local fieldBlip, dealerBlip
local STREAM_RANGE = Config.Field.radius + 40.0

-- ---------------------------------------------------------------- blips
local function addBlip(coords, cfg)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, cfg.sprite)
    SetBlipColour(blip, cfg.color)
    SetBlipScale(blip, cfg.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(cfg.label)
    EndTextCommandSetBlipName(blip)
    return blip
end

-- ---------------------------------------------------------------- ground
local function getGroundZ(x, y)
    local centre = Config.Field.coords
    local deadline = GetGameTimer() + 1500

    repeat
        RequestCollisionAtCoord(x, y, centre.z)
        local found, z = GetGroundZFor_3dCoord(x, y, centre.z + 50.0, false)
        if found and math.abs(z - centre.z) <= Config.Field.zTolerance then
            return z
        end
        Wait(50)
    until GetGameTimer() > deadline

    return nil
end

RegisterNetEvent('cannabis:resolveField', function(token, points)
    local out = {}
    for _, p in ipairs(points) do
        local z = getGroundZ(p.x, p.y)
        if z then out[#out + 1] = { x = p.x, y = p.y, z = z } end
    end
    TriggerServerEvent('cannabis:fieldResolved', token, out)
end)

-- Ask the server to spawn the field while we are near and it hasn't yet.
CreateThread(function()
    local centre = Config.Field.coords

    while true do
        local pos = GetEntityCoords(PlayerPedId())
        local d = #(vector2(pos.x, pos.y) - vector2(centre.x, centre.y))

        if d < STREAM_RANGE then
            RequestCollisionAtCoord(centre.x, centre.y, centre.z)
            local state = lib.callback.await('cannabis:fieldState', false)
            if not state then TriggerServerEvent('cannabis:fieldNear') end
            Wait(state == 'ready' and 5000 or 3000)
        else
            Wait(2000)
        end
    end
end)

-- ---------------------------------------------------------------- actions
function harvest(plant)
    local netId = NetworkGetNetworkIdFromEntity(plant)
    lib.requestAnimDict(Config.Harvest.anim.dict)

    local ok = lib.progressCircle({
        duration = Config.Harvest.duration,
        label = 'Harvesting weed...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = Config.Harvest.anim.dict, clip = Config.Harvest.anim.clip }
    })

    ClearPedTasks(cache.ped)
    if not ok then return end

    if lib.callback.await('cannabis:giveReward', false, netId) then
        lib.notify({ type = 'success',
            description = ('You harvested %d cannabis.'):format(Config.Harvest.amount) })
    else
        lib.notify({ type = 'error', description = 'You could not harvest this plant.' })
    end
end

function sellWeed()
    local result = lib.callback.await('cannabis:sell', false)
    if not result then return end

    lib.notify({ type = 'success',
        description = ('Sold 1 cannabis for $%d'):format(result.payout) })
end

-- ---------------------------------------------------------------- targets
-- Model/state based, so they work for every player and survive streaming.
exports.ox_target:addModel(Config.Field.model, {
    {
        name = 'cannabis_harvest',
        label = Config.Harvest.label,
        icon = Config.Harvest.icon,
        distance = 2.0,
        onSelect = function(data) harvest(data.entity) end
    }
})

exports.ox_target:addGlobalPed({
    {
        name = 'cannabis_sell',
        label = Config.Dealer.targetLabel,
        icon = Config.Dealer.targetIcon,
        distance = Config.Dealer.targetDistance,
        canInteract = function(entity)
            return Entity(entity).state.cannabisDealer == true
        end,
        onSelect = function() sellWeed() end
    }
})

-- ---------------------------------------------------------------- blips / cleanup
CreateThread(function()
    fieldBlip = addBlip(Config.Field.coords, Config.Field.blip)
    dealerBlip = addBlip(Config.Dealer.coords, Config.Dealer.blip)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    exports.ox_target:removeModel(Config.Field.model, 'cannabis_harvest')
    exports.ox_target:removeGlobalPed('cannabis_sell')
    if fieldBlip then RemoveBlip(fieldBlip) end
    if dealerBlip then RemoveBlip(dealerBlip) end
end)
