
local ESX = exports['es_extended']:getSharedObject()
local ox_inventory = exports.ox_inventory

local playerCooldowns = {}


---@param title string 
---@param message string 
---@param color number|nil 
local function SendToDiscord(title, message, color)
    local webhook = Config.DiscordWebhook
    if not webhook or webhook == '' then return end
    
    PerformHttpRequest(webhook, function() end, 'POST', json.encode({
        username = Config.DiscordBotName or 'House Robbery',
        embeds = {{
            color = color or 16753920,
            title = title,
            description = message,
            footer = {text = os.date('%Y-%m-%d %H:%M:%S')}
        }}
    }), {['Content-Type'] = 'application/json'})
end


---@param coords vector4 
---@return string Unique 
local function GetHouseKey(coords)
    return string.format('%.4f_%.4f_%.4f_%.2f', coords.x, coords.y, coords.z, coords.w or 0.0)
end

---@param player table 
---@param src number 
---@return string Player 
local function GetPlayerName(player, src)
    if not player then return tostring(src) end
    return player.getName and player.getName() 
        or player.getIdentifier and player.getIdentifier() 
        or tostring(src)
end

---@param house table|nil 
---@return number Cooldown 
local function GetCooldownSeconds(house)
    local mins = (house and house.cooldownMinutes) or Config.CooldownMinutes or 30
    return mins * 60
end


ESX.RegisterServerCallback('houserobbery:getCops', function(src, cb)
    local cops = ESX.GetExtendedPlayers('job', Config.PoliceJob)
    cb(#cops)
end)


ESX.RegisterServerCallback('houserobbery:tryLockpick', function(src, cb, house, action)
    local player = ESX.GetPlayerFromId(src)
    
    
    if not player or not house or not house.coords then
        cb(false, 'error')
        return
    end
    
    local identifier = player.getIdentifier and player.getIdentifier() or tostring(src)
    local houseKey = GetHouseKey(house.coords)
    local now = os.time()
    local cooldownDuration = GetCooldownSeconds(house)
    
    playerCooldowns[identifier] = playerCooldowns[identifier] or {}
    local data = playerCooldowns[identifier][houseKey] or {lockpick = 0, house = 0}
    

    if not action then
        if data.lockpick > now then
            cb(false, 'cooldown', math.ceil((data.lockpick - now) / 60))
            return
        end
        if data.house > now then
            cb(false, 'house_cooldown', math.ceil((data.house - now) / 60))
            return
        end
    end
    
    
    if action == 'fail' or action == 'success' or action == 'noise' then
        data.lockpick = now + cooldownDuration
        data.house = now + cooldownDuration
        playerCooldowns[identifier][houseKey] = data
    end
    
    cb(true)
end)



RegisterNetEvent('houserobbery:setBucket', function(bucket)
    local src = source
    SetPlayerRoutingBucket(src, bucket)
end)


RegisterNetEvent('houserobbery:useLockpick', function(itemName, slotId)
    local src = source
    if not itemName then return end
    
    local durabilityConfig = Config.LockpickDurability
    if not durabilityConfig or not durabilityConfig.enabled then return end
    
    
    local playerItems = ox_inventory:GetInventoryItems(src)
    if not playerItems then return end
    
    local targetSlot, currentDurability = nil, 100
    for slot, item in pairs(playerItems) do
        if item and item.name == itemName then
            targetSlot = slot
            if item.metadata and item.metadata.durability then
                currentDurability = item.metadata.durability
            end
            break
        end
    end
    
    if not targetSlot then return end
    
    
    local durabilityLoss = durabilityConfig.durabilityLoss or 20
    local newDurability = currentDurability - durabilityLoss
    
    
    if math.random(1, 100) <= (durabilityConfig.breakChance or 10) then
        newDurability = 0
    end
    
    if newDurability <= 0 then
        ox_inventory:RemoveItem(src, itemName, 1, nil, targetSlot)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lockpick',
            description = 'Your lockpick broke!',
            type = 'error',
            duration = 3000
        })
        
        local player = ESX.GetPlayerFromId(src)
        SendToDiscord('Lockpick Broken', ('%s broke their %s'):format(GetPlayerName(player, src), itemName), 15548997)
    else
       
        ox_inventory:SetDurability(src, targetSlot, newDurability)
        
        if newDurability <= 30 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Lockpick',
                description = ('Your lockpick is wearing out! (%d%% left)'):format(math.floor(newDurability)),
                type = 'warning',
                duration = 2500
            })
        end
    end
end)


RegisterNetEvent('houserobbery:tryLoot', function(house, spotIdx)
    local src = source
    local player = ESX.GetPlayerFromId(src)
    
    
    if not player or not spotIdx then
        TriggerClientEvent('houserobbery:lootResult', src, false)
        return
    end
    
   
    local lootDef = house.loot and house.loot[spotIdx]
    if not lootDef or not lootDef.item then
        TriggerClientEvent('houserobbery:lootResult', src, false)
        return
    end
    
    local item = lootDef.item
    
    
    local chance = lootDef.chance or Config.LootChance or 50
    if math.random(1, 100) > chance then
        TriggerClientEvent('houserobbery:lootResult', src, false)
        return
    end
    
    
    local count = math.random(lootDef.min or 1, lootDef.max or lootDef.min or 1)
    
    
    if ox_inventory:CanCarryItem(src, item, count) then
        ox_inventory:AddItem(src, item, count)
        TriggerClientEvent('houserobbery:lootResult', src, true, item, count)
        
        SendToDiscord('House Robbery Loot', ('%s looted %dx %s from a house.'):format(GetPlayerName(player, src), count, item), 16753920)
    else
        TriggerClientEvent('ox_inventory:notify', src, {
            type = 'error',
            text = 'You cannot carry this item.'
        })
        TriggerClientEvent('houserobbery:lootResult', src, false)
    end
end)
