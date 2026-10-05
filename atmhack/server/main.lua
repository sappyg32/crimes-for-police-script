local ESX = exports['es_extended']:getSharedObject()

-- Lock states, keyed by identifier (or identifier:prop when PerAtmLockout is on).
--   failLocks[  key ] = os.time() when the lockout expires
--   successLocks[key] = os.time() when the cooldown expires
local failLocks = {}
local successLocks = {}

-- Players with a hack in flight, so one player can't run two at once.
local inProgress = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function getIdentifier(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end
    return xPlayer.identifier
end

--- Builds the lock key. Per-ATM mode isolates the machine so a player can move
--- to another one; the default is per-player, which is the real deterrent.
local function lockKey(identifier, entity)
    if Config.PerAtmLockout and entity then
        return ('%s:%s'):format(identifier, entity)
    end

    return identifier
end

local function countItem(src, item)
    return exports.ox_inventory:GetItemCount(src, item) or 0
end

local function removeItem(src, item, count)
    return exports.ox_inventory:RemoveItem(src, item, count)
end

local function addItem(src, item, count)
    return exports.ox_inventory:AddItem(src, item, count)
end

local function hasRequiredItem(src)
    return countItem(src, Config.RequiredItem) > 0
end

--- Pays the reward. Two modes, so this works whether your server runs dirty
--- money as an ox_inventory item or as an ESX account.
--- Returns (ok, err) -- err is only set when the payout legitimately failed.
local function payReward(src, amount)
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then
        return false, 'Invalid player.'
    end

    -- Account mode (default): plain ESX account money, always succeeds.
    if Config.UseAccount then
        xPlayer.addAccountMoney(Config.RewardAccount, amount)
        return true
    end

    -- Item mode: goes through ox_inventory, which can fail on weight.
    if not addItem(src, Config.RewardItem, amount) then
        return false, 'No room for the payout.'
    end

    return true
end

--- Formats seconds as "14m 30s" for the notifications.
local function formatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))

    local minutes = math.floor(seconds / 60)
    local remainder = seconds % 60

    if minutes <= 0 then
        return ('%ss'):format(remainder)
    end

    if remainder <= 0 then
        return ('%sm'):format(minutes)
    end

    return ('%sm %ss'):format(minutes, remainder)
end

--- Returns the seconds left on a fail lock, or 0 when not locked.
local function getFailLockRemaining(key)
    local expires = failLocks[key]

    if not expires then return 0 end

    local remaining = expires - os.time()

    if remaining <= 0 then
        failLocks[key] = nil
        return 0
    end

    return remaining
end

local function getSuccessLockRemaining(key)
    local expires = successLocks[key]

    if not expires then return 0 end

    local remaining = expires - os.time()

    if remaining <= 0 then
        successLocks[key] = nil
        return 0
    end

    return remaining
end

-- ---------------------------------------------------------------------------
-- Callbacks
-- ---------------------------------------------------------------------------

--- Pre-flight check before the minigame opens.
lib.callback.register('atmhack:server:canHack', function(source, entity)
    local src = source

    if not ESX.GetPlayerFromId(src) then
        return false, 'Invalid player.'
    end

    if inProgress[src] then
        return false, 'You are already hacking an ATM.'
    end

    if not hasRequiredItem(src) then
        return false, ('You need a %s.'):format(Config.RequiredItem)
    end

    local identifier = getIdentifier(src)
    local key = lockKey(identifier, entity)

    -- Failure lockout wins over everything: one failure, then wait.
    local locked = getFailLockRemaining(key)

    if locked > 0 then
        return false, ('This ATM is locked out. Try again in %s.'):format(formatDuration(locked))
    end

    local cooling = getSuccessLockRemaining(key)

    if cooling > 0 then
        return false, ('The system is still resetting. Wait %s.'):format(formatDuration(cooling))
    end

    inProgress[src] = true

    return true
end)

--- Called once when the minigame reports back. This is the ONLY place a
--- payout or a lockout is applied, so a player can only fail into the
--- 15-minute lockout one time per attempt.
lib.callback.register('atmhack:server:finishHack', function(source, success, entity)
    local src = source

    -- Clear the in-flight flag whatever the outcome, so a player isn't stuck
    -- in "already hacking" if something went wrong upstream.
    if not inProgress[src] then
        return false, 'That hack was already resolved.'
    end

    inProgress[src] = nil

    if not ESX.GetPlayerFromId(src) then
        return false, 'Invalid player.'
    end

    local identifier = getIdentifier(src)
    local key = lockKey(identifier, entity)

    -- -----------------------------------------------------------------------
    -- Failure (including an ESC abort, which datacrack reports as a failure)
    -- -----------------------------------------------------------------------
    if not success then
        failLocks[key] = os.time() + Config.FailLockout

        print(('[atmhack] %s failed an ATM hack -- locked out for %s'):format(
            GetPlayerName(src), formatDuration(Config.FailLockout)
        ))

        TriggerClientEvent('atmhack:client:lockoutStarted', src, failLocks[key])

        return false, ('The hack failed. The ATM locked you out for %s.'):format(
            formatDuration(Config.FailLockout)
        )
    end

    -- -----------------------------------------------------------------------
    -- Success
    -- -----------------------------------------------------------------------

    -- Only the ITEM is re-validated here. The reward is paid on the success
    -- the minigame just reported -- it does not depend on the tool still
    -- being in the player's hands.
    if Config.ConsumeItem then
        if not removeItem(src, Config.RequiredItem, Config.ConsumeAmount) then
            return false, 'Could not take the item.'
        end
    end

    local paid, payError = payReward(src, Config.RewardAmount)

    if not paid then
        return false, payError
    end

    if Config.SuccessCooldown > 0 then
        successLocks[key] = os.time() + Config.SuccessCooldown
    end

    print(('[atmhack] %s cracked an ATM and received %s (%s)'):format(
        GetPlayerName(src),
        Config.RewardAmount,
        Config.UseAccount and ('account:' .. Config.RewardAccount) or ('item:' .. Config.RewardItem)
    ))

    -- Optional heat: only ever fires on a success.
    if math.random() < Config.AlarmChance then
        TriggerClientEvent('atmhack:client:alarm', -1, GetEntityCoords(GetPlayerPed(src)))
    end

    return true, Config.RewardAmount
end)

-- ---------------------------------------------------------------------------
-- Housekeeping
-- ---------------------------------------------------------------------------

AddEventHandler('playerDropped', function()
    local src = source
    inProgress[src] = nil
end)
