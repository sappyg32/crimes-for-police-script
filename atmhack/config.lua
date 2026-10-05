Config = {}

-- Item required in the player's ox_inventory to start a hack.
Config.RequiredItem = 'atmhacker'

-- Consume the item on a successful hack?
Config.ConsumeItem = false

-- How many items to remove when ConsumeItem is true.
Config.ConsumeAmount = 1

-- Reward paid on a successful hack.
Config.RewardItem = 'black_money' -- ox_inventory item name for the payout
Config.RewardAmount = 10000

-- Pay into an ESX account instead of an ox_inventory item?
-- ESX "black_money" = dirty money. If you run dirty money as an ox_inventory
-- ITEM, leave this false and set Config.RewardItem to the item name.
Config.UseAccount = true
Config.RewardAccount = 'black_money'

-- ---------------------------------------------------------------------------
-- Locks
-- ---------------------------------------------------------------------------
-- One failure, then the player must wait before trying again.
-- Enforced server side, so a client can't skip it.
Config.FailLockout = 15 * 60 -- 15 minutes, in seconds

-- Cooldown after a SUCCESSFUL hack. Set to 0 to disable.
Config.SuccessCooldown = 60

-- Is the fail lockout per player, or per ATM prop? Per-player is the usual
-- choice: it stops a player walking to the next ATM and trying again at once.
-- Set to true to lock only the machine that was failed against.
Config.PerAtmLockout = false

-- ---------------------------------------------------------------------------
-- Minigame settings (datacrack)
-- ---------------------------------------------------------------------------
-- API:  exports['datacrack']:Start(difficulty)
--       difficulty ranges 2 (easiest) to 5 (hardest), floats accepted.
--       Anything below 2 or above 5 falls back to the resource's default.
--
-- The outcome arrives on the 'datacrack' event: true = cracked, false =
-- failed or aborted with ESC -- datacrack reports an abort as a failure.
--
-- Difficulty is picked at random from this list per attempt.
Config.Difficulties = {
    2.5, -- easy
    3.5, -- medium
    4.5, -- hard
}

-- How long to wait for the datacrack event before giving up and cleaning up.
-- datacrack has no internal time limit -- the player solves it at their own
-- pace or presses ESC to abort -- so this is a safety net, not a game rule.
-- Set to 0 to wait indefinitely.
Config.MinigameTimeout = 180 -- seconds

-- ---------------------------------------------------------------------------
-- ATM prop models to attach the ox_target option to
-- ---------------------------------------------------------------------------
Config.AtmModels = {
    'prop_atm_01',
    'prop_atm_02',
    'prop_atm_03',
    'prop_fleeca_atm',
}

-- ox_target interaction distance
Config.TargetDistance = 2.0

-- Interaction icon shown in the ox_target menu
Config.TargetIcon = 'fa-solid fa-microchip'
Config.TargetLabel = 'Hack ATM'

-- How far out to watch for ATM props, in metres. Must comfortably exceed
-- Config.TargetDistance so the option is attached before you can reach the
-- machine. Keep it modest -- the scan walks the object pool each pass.
Config.TargetStreamRadius = 12.0

-- How often to rescan for ATMs that entered or left range, in milliseconds.
-- 1000 is plenty; the pool walk is cheap but there's no reason to spam it.
Config.TargetScanInterval = 1000

-- ---------------------------------------------------------------------------
-- Alerts / police
-- ---------------------------------------------------------------------------
-- Chance (0.0 - 1.0) the alarm triggers on a successful hack.
Config.AlarmChance = 0.35
Config.AlarmRadius = 120.0
