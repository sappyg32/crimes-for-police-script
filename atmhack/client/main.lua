local ESX = exports['es_extended']:getSharedObject()

local hacking = false

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Returns true if the player currently has the required item.
local function hasRequiredItem()
    return exports.ox_inventory:Search('count', Config.RequiredItem) > 0
end

--- Plays the datacrack minigame and returns true on success.
---
--- datacrack's surface, from its client.lua:
---   exports['datacrack']:Start(difficulty)   -- difficulty 2..5
---   AddEventHandler('datacrack', function(output) end)  -- output: boolean
---
--- There is no cancel call on our side. datacrack binds ESC
--- (INPUT_FRONTEND_CANCEL) internally and routes it to its own Abort(), which
--- fires the same event with false. We don't add a second keybind because
--- datacrack holds DisableControlAction over most keys while it runs.
local function playMinigame()
    local difficulty = Config.Difficulties[math.random(#Config.Difficulties)]

    local p = promise.new()
    local settled = false
    local timeoutId
    local resultHandler

    local function resolve(success)
        if settled then return end
        settled = true

        if timeoutId then
            ClearTimeout(timeoutId)
            timeoutId = nil
        end

        if resultHandler then
            RemoveEventHandler(resultHandler)
            resultHandler = nil
        end

        p:resolve(success and true or false)
    end

    -- One-shot: the handler blanks its own reference so the teardown below
    -- can't remove it a second time. datacrack fires 'datacrack' from two
    -- places (its success branch and Abort), and removing an already-removed
    -- handler raises "Invalid event data passed to RemoveEventHandler()".
    resultHandler = AddEventHandler('datacrack', function(output)
        resolve(output)
    end)

    -- Safety net only. datacrack has no time limit of its own, so if the
    -- event never arrives we clean up instead of hanging this thread forever.
    if Config.MinigameTimeout > 0 then
        timeoutId = SetTimeout(Config.MinigameTimeout * 1000, function()
            timeoutId = nil
            resolve(false)
        end)
    end

    exports['datacrack']:Start(difficulty)

    return Citizen.Await(p)
end

--- Small animation while the player is at the ATM.
local function playHackAnimation(duration)
    local ped = PlayerPedId()

    RequestAnimDict('anim@heists@ornate_bank@hack')
    while not HasAnimDictLoaded('anim@heists@ornate_bank@hack') do
        Wait(10)
    end

    TaskPlayAnim(ped, 'anim@heists@ornate_bank@hack', 'hack_loop', 8.0, -8.0, duration, 49, 0, false, false, false)

    local prop = CreateObject(`hei_prop_hst_laptop`, 0.0, 0.0, 0.0, true, true, false)
    local bone = GetPedBoneIndex(ped, 60309)

    AttachEntityToEntity(prop, ped, bone, 0.0, 0.10, 0.06, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    return prop
end

local function stopHackAnimation(prop)
    local ped = PlayerPedId()

    ClearPedTasks(ped)
    RemoveAnimDict('anim@heists@ornate_bank@hack')

    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        DeleteEntity(prop)
    end
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

-- ---------------------------------------------------------------------------
-- The actual hack flow
-- ---------------------------------------------------------------------------

local function startHack(entity)
    if hacking then return end

    if not hasRequiredItem() then
        lib.notify({
            title = 'ATM Hacking',
            description = ('You need a %s to do this.'):format(Config.RequiredItem),
            type = 'error'
        })
        return
    end

    -- The server owns the locks: item check, fail lockout, success cooldown.
    local allowed, reason = lib.callback.await('atmhack:server:canHack', false, entity)

    if not allowed then
        lib.notify({
            title = 'ATM Hacking',
            description = reason or 'You cannot do that right now.',
            type = 'error'
        })
        return
    end

    hacking = true

    local prop = playHackAnimation(-1)

    local success = playMinigame()

    stopHackAnimation(prop)

    hacking = false

    -- One round only. Whatever datacrack reported, we report to the server and
    -- stop -- a failure arms the lockout and nothing here re-runs the minigame.
    local ok, message = lib.callback.await('atmhack:server:finishHack', false, success, entity)

    if ok then
        lib.notify({
            title = 'ATM Hacking',
            description = ('Hack complete. You got $%s in dirty money.'):format(message),
            type = 'success'
        })
    else
        lib.notify({
            title = 'ATM Hacking',
            description = message or 'The hack failed. The ATM locked you out.',
            type = 'error'
        })
    end
end

-- ---------------------------------------------------------------------------
-- ox_target setup
-- ---------------------------------------------------------------------------
--
-- NOT using ox_target:addModel here on purpose. Model registration only binds
-- to entities that are already streamed in when the call runs, and this
-- resource starts during loading -- before any ATM prop exists on the client.
-- The option silently attaches to nothing.
--
-- Instead we watch for ATM props entering range and bind to the ENTITY, which
-- always has a live handle to attach to. Options are removed again once the
-- prop streams out, so we don't accumulate stale registrations over a session.

local trackedAtms = {} -- [entity] = optionId, for ATMs we hold an option on

local function buildModelSet()
    local set = {}

    for _, model in ipairs(Config.AtmModels) do
        set[joaat(model)] = true
    end

    return set
end

local ATM_MODELS = buildModelSet()

--- Returns the model hash if the entity is an ATM we should offer the hack on,
--- otherwise nil. Does NOT write to modelCache -- a pool scan touches hundreds
--- of entities a second and caching them all would grow unbounded.
local function getAtmModel(entity)
    if not DoesEntityExist(entity) then return nil end

    local model = GetEntityModel(entity)

    if not ATM_MODELS[model] then return nil end

    return model
end

--- Adds the option to a single ATM. Idempotent: re-entry for an entity that
--- is already tracked returns early, so ox_target never sees a duplicate name
--- and never prints its "Replacing existing target option" warning.
local function registerAtm(entity)
    if trackedAtms[entity] then return end

    -- Sanity check before spending a slot: if ox_target is unsure, bail.
    if not getAtmModel(entity) then return end

    local optionId = exports.ox_target:addLocalEntity(entity, {
        {
            name = ('atmhack:hack:%s'):format(entity),
            icon = Config.TargetIcon,
            label = Config.TargetLabel,
            distance = Config.TargetDistance,
            canInteract = function()
                return not hacking
            end,
            onSelect = function()
                startHack(entity)
            end
        }
    })

    -- A nil return means ox_target refused the add; don't record it as tracked,
    -- or the next pass would skip an entity that has no option attached.
    if not optionId then return end

    trackedAtms[entity] = optionId
end

--- Removes the option when the prop streams out, so the table stays small.
local function unregisterAtm(entity)
    local optionId = trackedAtms[entity]

    if not optionId then return end

    exports.ox_target:removeLocalEntity(entity, optionId)

    trackedAtms[entity] = nil
end

CreateThread(function()
    -- Bind anything already in range when the resource starts.
    for _, entity in ipairs(GetGamePool('CObject')) do
        registerAtm(entity)
    end

    while true do
        local coords = GetEntityCoords(PlayerPedId())
        local radius = Config.TargetStreamRadius

        for _, entity in ipairs(GetGamePool('CObject')) do
            local distance = #(coords - GetEntityCoords(entity))
            local tracked = trackedAtms[entity]

            if distance < radius then
                -- registerAtm is a no-op once the entity is tracked, so this
                -- costs one table lookup per in-range object per pass.
                registerAtm(entity)
            elseif tracked then
                unregisterAtm(entity)
            end
        end

        Wait(Config.TargetScanInterval)
    end
end)

-- ---------------------------------------------------------------------------
-- Lockout feedback
-- ---------------------------------------------------------------------------

-- The server tells us when a lockout begins. Nothing is stored client side --
-- the server is the source of truth and the next interaction re-validates --
-- but the handler exists so the event isn't unhandled.
RegisterNetEvent('atmhack:client:lockoutStarted', function(untilTime)
    print(('[atmhack] Locked out until %s'):format(untilTime))
end)

-- Drop every registration and the animation if the resource stops, so nothing
-- is left attached to the world.
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for entity in pairs(trackedAtms) do
        unregisterAtm(entity)
    end

    ClearPedTasks(PlayerPedId())
end)
