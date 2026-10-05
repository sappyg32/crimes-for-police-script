local ox_inventory = exports.ox_inventory

-- harvested[locIndex][plantIndex] = true while a plant is cut and waiting to respawn
local harvested = {}
for i = 1, #Config.Harvest do harvested[i] = {} end

-- Basic distance sanity check so a modified client can't trigger actions
-- from across the map. If the server has no position for the player
-- (no OneSync), the check is skipped.
local function near(source, coords, maxDist)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return true end
    local p = GetEntityCoords(ped)
    return #(p - vector3(coords.x, coords.y, coords.z)) <= maxDist
end

---------------------------------------------------------------------
-- Harvest state
---------------------------------------------------------------------
lib.callback.register('harvest:getState', function(source, locIndex)
    local out = {}
    for plantIndex in pairs(harvested[locIndex] or {}) do
        out[#out + 1] = plantIndex
    end
    return out
end)

lib.callback.register('harvest:giveItem', function(source, locIndex, plantIndex)
    local loc = Config.Harvest[locIndex]
    if not loc or type(plantIndex) ~= 'number' then return false end
    if plantIndex < 1 or plantIndex > loc.plantCount then return false end
    if harvested[locIndex][plantIndex] then return false end
    if not near(source, loc.marker, loc.radius + 30.0) then return false end

    -- claim first so two players can't both take the same plant
    harvested[locIndex][plantIndex] = true

    if not ox_inventory:AddItem(source, loc.item, loc.amount) then
        harvested[locIndex][plantIndex] = nil
        return false
    end

    TriggerClientEvent('harvest:plantState', -1, locIndex, plantIndex, false)

    SetTimeout(loc.respawn * 1000, function()
        harvested[locIndex][plantIndex] = nil
        TriggerClientEvent('harvest:plantState', -1, locIndex, plantIndex, true)
    end)

    return true
end)

---------------------------------------------------------------------
-- Processing (recipe is looked up by index, never trusted from the client)
---------------------------------------------------------------------
lib.callback.register('harvest:process', function(source, recipeIndex)
    local recipe = Config.Lab.recipes[recipeIndex]
    if not recipe then return false end
    if not near(source, Config.Lab.marker, 15.0) then return false end

    if not ox_inventory:RemoveItem(source, recipe.cost.item, recipe.cost.amount) then
        return false
    end

    if not ox_inventory:AddItem(source, recipe.reward.item, recipe.reward.amount) then
        ox_inventory:AddItem(source, recipe.cost.item, recipe.cost.amount) -- roll back
        return false
    end

    return true
end)

---------------------------------------------------------------------
-- Selling (offer is looked up by index, so the payout can't be forged)
---------------------------------------------------------------------
lib.callback.register('harvest:sell', function(source, offerIndex)
    local offer = Config.Distributor.offers[offerIndex]
    if not offer then return false end
    if not near(source, Config.Distributor.marker, 15.0) then return false end

    if not ox_inventory:RemoveItem(source, offer.item, offer.amount) then
        return false
    end

    if not ox_inventory:AddItem(source, 'money', offer.payout) then
        ox_inventory:AddItem(source, offer.item, offer.amount) -- roll back
        return false
    end

    return true
end)
