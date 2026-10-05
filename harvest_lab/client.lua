local PlantState = {}   -- [loc][idx] = false when harvested (nil/true = available)
local spawned    = {}   -- [loc][idx] = entity
local busy       = {}   -- [loc][idx] = true while a spawn is in progress
local groundZ    = {}   -- [loc][idx] = resolved ground height
local inRange    = {}   -- [loc] = true while the player is near the site

for i = 1, #Config.Harvest do
    PlantState[i], spawned[i], busy[i], groundZ[i] = {}, {}, {}, {}
end

---------------------------------------------------------------------
-- Utility
---------------------------------------------------------------------
local function loadModel(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) do
        if GetGameTimer() > timeout then return false end
        Wait(0)
    end
    return true
end

-- Ground height at x,y. Collision is requested first and we keep asking
-- until the terrain is actually there: spawning before collision has
-- streamed in is what makes props and peds fall through the map.
local function findGround(x, y, refZ)
    local deadline = GetGameTimer() + 3000
    while GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, refZ)
        local found, z = GetGroundZFor_3dCoord(x, y, refZ + 50.0, false)
        if found then return z end
        Wait(50)
    end
    return nil
end

local function createBlip(coords, cfg)
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

-- Fixed position for plant n, identical on every client and after every
-- respawn (no math.random).
local function plantPlacement(loc, n)
    local jitter = ((n * 2654435761) % 1000) / 1000 * 0.4
    local spread = ((n * 2246822519) % 1000) / 1000
    local angle  = (n / loc.plantCount) * math.pi * 2 + jitter
    local dist   = math.sqrt(spread) * loc.radius
    return loc.marker.x + math.cos(angle) * dist,
           loc.marker.y + math.sin(angle) * dist,
           ((n * 97) % 360) + 0.0
end

---------------------------------------------------------------------
-- Plants
---------------------------------------------------------------------
local function removePlant(li, pi)
    local entity = spawned[li][pi]
    if not entity then return end
    spawned[li][pi] = nil

    if DoesEntityExist(entity) then
        exports.ox_target:removeLocalEntity(entity)
        DeleteEntity(entity)
    end
end

local function harvestPlant(li, pi)
    if PlantState[li][pi] == false then return end

    local ok = lib.callback.await('harvest:giveItem', false, li, pi)
    if not ok then
        lib.notify({ type = 'error', description = 'Your hands are full.' })
    end
    -- on success the server broadcasts the state change and removePlant runs
end

local function spawnPlant(li, pi)
    if spawned[li][pi] or busy[li][pi] then return end
    if PlantState[li][pi] == false then return end

    local loc = Config.Harvest[li]
    local model = joaat(loc.prop)

    busy[li][pi] = true

    if not loadModel(model) then
        busy[li][pi] = nil
        return
    end

    local x, y, rot = plantPlacement(loc, pi)

    local gz = groundZ[li][pi]
    if not gz then
        gz = findGround(x, y, loc.marker.z) or loc.marker.z
        groundZ[li][pi] = gz
    end

    -- the player may have left, or the plant been harvested, while we waited
    if not inRange[li] or PlantState[li][pi] == false then
        busy[li][pi] = nil
        return
    end

    local z
    if loc.useAutoSnap == false then
        local minDim = GetModelDimensions(model)
        z = gz + minDim.z + (loc.zAdjust or 0.0)
    else
        z = gz + 0.5 + (loc.zAdjust or 0.0)
    end

    local entity = CreateObjectNoOffset(model, x, y, z, false, false, false)
    if entity == 0 then
        busy[li][pi] = nil
        return
    end

    SetEntityAsMissionEntity(entity, true, true)
    SetEntityRotation(entity, 0.0, 0.0, rot, 2, true)

    if loc.useAutoSnap ~= false then
        PlaceObjectOnGroundProperly(entity)
    end

    FreezeEntityPosition(entity, true)

    exports.ox_target:addLocalEntity(entity, {
        {
            name     = ('harvest_%s_%d'):format(loc.name, pi),
            label    = ('Harvest %s'):format(loc.label),
            icon     = 'fa-solid fa-seedling',
            distance = 1.5,
            canInteract = function() return PlantState[li][pi] ~= false end,
            onSelect = function() harvestPlant(li, pi) end
        }
    })

    spawned[li][pi] = entity
    busy[li][pi] = nil
end

local function spawnSite(li)
    local loc = Config.Harvest[li]
    for pi = 1, loc.plantCount do
        if not inRange[li] then return end
        spawnPlant(li, pi)
        Wait(10)
    end
end

local function despawnSite(li)
    local loc = Config.Harvest[li]
    for pi = 1, loc.plantCount do
        removePlant(li, pi)
    end
    SetModelAsNoLongerNeeded(joaat(loc.prop))
end

RegisterNetEvent('harvest:plantState', function(li, pi, available)
    if not PlantState[li] then return end

    PlantState[li][pi] = available and nil or false

    if not available then
        removePlant(li, pi)
    elseif inRange[li] then
        CreateThread(function() spawnPlant(li, pi) end)
    end
end)

CreateThread(function()
    for li, loc in ipairs(Config.Harvest) do
        createBlip(loc.marker, loc.blip)

        -- catch up on plants that were already harvested before we joined
        local cut = lib.callback.await('harvest:getState', false, li)
        for _, pi in ipairs(cut or {}) do
            PlantState[li][pi] = false
            removePlant(li, pi)
        end

        lib.points.new({
            coords   = vec3(loc.marker.x, loc.marker.y, loc.marker.z),
            distance = loc.radius + Config.StreamDistance,
            onEnter  = function()
                inRange[li] = true
                CreateThread(function() spawnSite(li) end)
            end,
            onExit   = function()
                inRange[li] = nil
                despawnSite(li)
            end
        })
    end
end)

---------------------------------------------------------------------
-- The Lab
---------------------------------------------------------------------
CreateThread(function()
    local lab = Config.Lab
    createBlip(lab.marker, lab.blip)

    local options = {}
    for index, recipe in ipairs(lab.recipes) do
        options[#options + 1] = {
            name     = 'lab_' .. index,
            label    = recipe.label,
            icon     = recipe.icon,
            distance = 2.5,
            onSelect = function()
                local ok = lib.callback.await('harvest:process', false, index)
                if ok then
                    lib.notify({ type = 'success',
                        description = ('Received %dx %s'):format(recipe.reward.amount, recipe.reward.item) })
                else
                    lib.notify({ type = 'error', description = 'You lack the required ingredients.' })
                end
            end
        }
    end

    exports.ox_target:addSphereZone({
        coords  = vector3(lab.marker.x, lab.marker.y, lab.marker.z),
        radius  = 2.0,
        debug   = false,
        options = options
    })
end)

---------------------------------------------------------------------
-- Distributor NPC
---------------------------------------------------------------------
local distributor = nil
local distributorBusy = false
local distributorInRange = false

local function removeDistributor()
    if distributor and DoesEntityExist(distributor) then
        exports.ox_target:removeLocalEntity(distributor)
        DeleteEntity(distributor)
    end
    distributor = nil
end

local function spawnDistributor()
    if distributor or distributorBusy then return end
    distributorBusy = true

    local dist  = Config.Distributor
    local model = joaat(dist.model)

    if not loadModel(model) then
        distributorBusy = false
        return
    end

    -- wait for terrain so he doesn't drop through the map
    local gz = findGround(dist.marker.x, dist.marker.y, dist.marker.z) or (dist.marker.z - 1.0)

    if not distributorInRange then
        distributorBusy = false
        return
    end

    local ped = CreatePed(4, model, dist.marker.x, dist.marker.y, gz, dist.marker.w, false, true)
    if not ped or ped == 0 then
        distributorBusy = false
        return
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetEntityInvincible(ped, true)

    TaskWanderInArea(ped,
        dist.marker.x, dist.marker.y, dist.marker.z,
        dist.wanderRadius, 1.0, 3.0)

    local options = {}
    for index, offer in ipairs(dist.offers) do
        options[#options + 1] = {
            name     = 'dist_' .. offer.item,
            label    = offer.label,
            icon     = offer.icon,
            distance = 2.5,
            onSelect = function()
                local ok = lib.callback.await('harvest:sell', false, index)
                if ok then
                    lib.notify({ type = 'success',
                        description = ('Sold %dx %s for $%d'):format(offer.amount, offer.item, offer.payout) })
                else
                    lib.notify({ type = 'error', description = 'You have nothing to sell.' })
                end
            end
        }
    end

    exports.ox_target:addLocalEntity(ped, options)

    distributor = ped
    distributorBusy = false
end

CreateThread(function()
    local dist = Config.Distributor
    createBlip(dist.marker, dist.blip)

    lib.points.new({
        coords   = vec3(dist.marker.x, dist.marker.y, dist.marker.z),
        distance = Config.StreamDistance,
        onEnter  = function()
            distributorInRange = true
            CreateThread(spawnDistributor)
        end,
        onExit   = function()
            distributorInRange = false
            removeDistributor()
        end
    })
end)

---------------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------------
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end

    for li = 1, #Config.Harvest do
        for pi in pairs(spawned[li]) do
            removePlant(li, pi)
        end
    end
    removeDistributor()
end)
