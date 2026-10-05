
Config = {}

Config.PoliceJob = 'police'              -- Job name for police
Config.MinCopsOnline = 0                 -- Minimum police required to rob (0 = no requirement)
Config.UseDispatch = false               -- Enable dispatch alerts core_dispatch is used, change SendDispatchAlert function if needed in client LINE 129
Config.LockpickDuration = 3000           -- Lockpick animation duration (ms)
Config.SearchDuration = 4000             -- Loot search animation duration (ms)


Config.LockpickDurability = {
    enabled = true,                      -- Enable durability system
    durabilityLoss = 5,                  -- % durability lost per use
    breakChance = 5                      -- Extra % chance to instantly break
}


Config.NoiseUI = {
    showNoiseBar = true,                 -- Show the noise bar UI
    barPosition = 'top-left',            -- Position: 'top-left', 'top-right', 'bottom-left', 'bottom-right'
    showCrouchHint = true,               -- Show CTRL crouch hint
    wakeUpThreshold = 80                 -- Noise level that triggers warning state
}

-- Noise values (how fast noise increases/decreases)
Config.NoiseSettings = {
    -- Standing movement
    sprint = 20,
    run = 12,
    walk = 6,
    -- Crouched movement
    crouchSprint = 4,
    crouchRun = 2,
    crouchWalk = 1,
    -- Noise decay when still
    decay = 2
}

---------------------------------------------------------------------------
-- DISCORD LOGGING
---------------------------------------------------------------------------

Config.DiscordWebhook = ''               -- Discord webhook URL (leave empty to disable)
Config.DiscordBotName = 'House Robbery'  -- Bot name shown in Discord


Config.Houses = {

    ---------------------------------------------------------------------------
    -- POOR HOUSES (any lockpick) EDIT/ADD AS MANY ITEMS YOU LIKE
    ---------------------------------------------------------------------------
    {
        coords = vector4(114.2159, -1961.2693, 21.3342, 215.3654),
        blip = true,
        blipData = {
            sprite = 40, color = 1, scale = 0.8, name = "Robbable House"
        },
        lockpickItems = {'lockpick', 'advanced_lockpick', 'master_lockpick'},
        lockpickFailChance = 15,
        cooldownMinutes = 30,
        interior = vector4(266.0442, -1007.2127, -101.0085, 7.22),
        loot = {
            {coords = vector3(257.2011, -995.6414, -99.0086), item = 'flatscreen', min = 1, max = 1, chance = 90},
            {coords = vector3(262.9351, -1002.65, -99.0086), item = 'computer_chip', min = 1, max = 1, chance = 5},
            {coords = vector3(265.7506, -999.8489, -99.0086), item = 'cash', min = 500, max = 800, chance = 50},
            {coords = vector3(262.016, -995.4942, -99.0087), item = 'heavypistolblueprint', min = 1, max = 1, chance = 10},
            {coords = vector3(259.8708, -1003.9705, -99.0086), item = 'rolex', min = 1, max = 1, chance = 55}
        },
        exit = vector3(265.9945, -1007.3914, -101.0141)
    },

    {
        coords = vector4(126.8187, -1929.9514, 21.3824, 239.215),
        blip = true,
        blipData = {
            sprite = 40, color = 1, scale = 0.8, name = "Robbable House"
        },
        lockpickItems = {'lockpick', 'advanced_lockpick', 'master_lockpick'},
        lockpickFailChance = 15,
        cooldownMinutes = 30,
        interior = vector4(266.0442, -1007.2127, -101.0085, 7.22),
        loot = {
            {coords = vector3(257.2011, -995.6414, -99.0086), item = 'flatscreen', min = 1, max = 1, chance = 90},
            {coords = vector3(262.9351, -1002.65, -99.0086), item = 'computer_chip', min = 1, max = 1, chance = 5},
            {coords = vector3(265.7506, -999.8489, -99.0086), item = 'cash', min = 500, max = 800, chance = 50},
            {coords = vector3(262.016, -995.4942, -99.0087), item = 'heavypistolblueprint', min = 1, max = 1, chance = 10},
            {coords = vector3(259.8708, -1003.9705, -99.0086), item = 'rolex', min = 1, max = 1, chance = 55}
        },
        exit = vector3(265.9945, -1007.3914, -101.0141)
    },

    {
        coords = vector4(100.7862, -1912.1105, 21.4074, 325.7753),
        blip = true,
        blipData = {
            sprite = 40, color = 1, scale = 0.8, name = "Robbable House"
        },
        lockpickItems = {'lockpick', 'advanced_lockpick', 'master_lockpick'},
        cooldownMinutes = 30,
        lockpickFailChance = 15,
        interior = vector4(266.0442, -1007.2127, -101.0085, 7.22),
        loot = {
            {coords = vector3(257.2011, -995.6414, -99.0086), item = 'flatscreen', min = 1, max = 1, chance = 90},
            {coords = vector3(262.9351, -1002.65, -99.0086), item = 'computer_chip', min = 1, max = 1, chance = 5},
            {coords = vector3(265.7506, -999.8489, -99.0086), item = 'cash', min = 500, max = 800, chance = 50},
            {coords = vector3(262.016, -995.4942, -99.0087), item = 'heavypistolblueprint', min = 1, max = 1, chance = 10},
            {coords = vector3(259.8708, -1003.9705, -99.0086), item = 'rolex', min = 1, max = 1, chance = 55}
        },
        exit = vector3(265.9945, -1007.3914, -101.0141)
    },

    ---------------------------------------------------------------------------
    -- MEDIUM HOUSES (Advanced/Master lockpick required)
    ---------------------------------------------------------------------------
    {
        coords = vector4(-952.6212, -1077.6531, 2.6747, 36.2856),
        blip = true,
        blipData = {
            sprite = 40, color = 2, scale = 0.8, name = "Middle Class Robbable House"
        },
        lockpickItems = {'advanced_lockpick', 'master_lockpick'},
        lockpickFailChance = 20,
        interior = vector4(346.5564, -1011.981, -99.1962, 1.31),
        cooldownMinutes = 30,
        loot = {
            {coords = vector3(338.3178, -996.9246, -99.1962), item = 'flatscreen', min = 1, max = 1, chance = 100},
            {coords = vector3(339.5163, -1003.2219, -99.1962), item = 'rolex', min = 1, max = 2, chance = 50},
            {coords = vector3(351.7983, -998.6481, -99.1963), item = 'smgblueprint', min = 1, max = 1, chance = 5},
            {coords = vector3(345.3091, -994.9373, -99.1963), item = 'computer_chip', min = 1, max = 1, chance = 10},
            {coords = vector3(344.0763, -1001.3369, -99.1963), item = 'clam', min = 1, max = 1, chance = 60},
            {coords = vector3(350.6192, -993.737, -99.1962), item = 'cash', min = 1000, max = 1500, chance = 50},
        },
        exit = vector3(346.7228, -1013.0067, -99.1962)
    },
    {
        coords = vector4(-978.1337, -1108.2983, 2.1503, 227.4049),
        blip = true,
        blipData = {
            sprite = 40, color = 2, scale = 0.8, name = "Middle Class Robbable House"
        },
        lockpickItems = {'advanced_lockpick', 'master_lockpick'},
        lockpickFailChance = 20,
        interior = vector4(346.5564, -1011.981, -99.1962, 1.31),
        cooldownMinutes = 30,
        loot = {
            {coords = vector3(338.3178, -996.9246, -99.1962), item = 'flatscreen', min = 1, max = 1, chance = 100},
            {coords = vector3(339.5163, -1003.2219, -99.1962), item = 'rolex', min = 1, max = 2, chance = 50},
            {coords = vector3(351.7983, -998.6481, -99.1963), item = 'smgblueprint', min = 1, max = 1, chance = 5},
            {coords = vector3(345.3091, -994.9373, -99.1963), item = 'computer_chip', min = 1, max = 1, chance = 10},
            {coords = vector3(344.0763, -1001.3369, -99.1963), item = 'clam', min = 1, max = 1, chance = 60},
            {coords = vector3(350.6192, -993.737, -99.1962), item = 'cash', min = 1000, max = 1500, chance = 50},
        },
        exit = vector3(346.7228, -1013.0067, -99.1962)
    },

    {
        coords = vector4(-1082.446, -1139.2554, 2.1586, 42.4493),
        blip = true,
        blipData = {
            sprite = 40, color = 2, scale = 0.8, name = "Middle Class Robbable House"
        },
        lockpickItems = {'advanced_lockpick', 'master_lockpick'},
        lockpickFailChance = 20,
        interior = vector4(346.5564, -1011.981, -99.1962, 1.31),
        cooldownMinutes = 30,
        loot = {
            {coords = vector3(338.3178, -996.9246, -99.1962), item = 'flatscreen', min = 1, max = 1, chance = 100},
            {coords = vector3(339.5163, -1003.2219, -99.1962), item = 'rolex', min = 1, max = 2, chance = 50},
            {coords = vector3(351.7983, -998.6481, -99.1963), item = 'smgblueprint', min = 1, max = 1, chance = 5},
            {coords = vector3(345.3091, -994.9373, -99.1963), item = 'computer_chip', min = 1, max = 1, chance = 10},
            {coords = vector3(344.0763, -1001.3369, -99.1963), item = 'clam', min = 1, max = 1, chance = 60},
            {coords = vector3(350.6192, -993.737, -99.1962), item = 'cash', min = 1000, max = 1500, chance = 50},
        },
        exit = vector3(346.7228, -1013.0067, -99.1962)
    },

    ---------------------------------------------------------------------------
    -- HIGH-END HOUSES (Master lockpick required)
    ---------------------------------------------------------------------------
    {
        coords = vector4(-595.6528, 530.2561, 107.7548, 351.9426),
        blip = true,
        blipData = {
            sprite = 40, color = 5, scale = 0.8, name = "Luxury Robbable House"
        },
        lockpickItems = {'master_lockpick'},
        lockpickFailChance = 30,
        cooldownMinutes = 30,
        interior = vector4(-786.8663, 315.7642, 187.9136, 278.32),
        loot = {
            {coords = vector3(-789.1169, 320.7265, 187.3132), item = 'cash', min = 1000, max = 1500, chance = 60},
            {coords = vector3(-780.3466, 337.8327, 187.4456), item = 'flatscreen', min = 1, max = 1, chance = 100},
            {coords = vector3(-793.6407, 341.64, 187.1135), item = 'wallet', min = 1, max = 1, chance = 35},
            {coords = vector3(-799.5466, 329.7497, 190.7159), item = 'rolex', min = 1, max = 3, chance = 60},
            {coords = vector3(-781.9847, 330.7953, 187.3132), item = 'clam', min = 1, max = 2, chance = 60},
            {coords = vector3(-794.9417, 326.1464, 187.3132), item = 'microsmgblueprint', min = 1, max = 1, chance = 5},
            {coords = vector3(-796.7165, 328.4228, 187.3132), item = 'armour', min = 1, max = 1, chance = 5},
            {coords = vector3(-798.0312, 322.1114, 187.3132), item = 'computer_chip', min = 1, max = 1, chance = 15},
        },
        exit = vector3(-787.5426, 315.6943, 187.9135)
    },

    {
        coords = vector4(-640.9697, 520.5316, 109.8828, 9.8318),
        blip = true,
        blipData = {
            sprite = 40, color = 5, scale = 0.8, name = "Luxury Robbable House"
        },
        lockpickItems = {'master_lockpick'},
        lockpickFailChance = 30,
        cooldownMinutes = 30,
        interior = vector4(-786.8663, 315.7642, 187.9136, 278.32),
        loot = {
            {coords = vector3(-789.1169, 320.7265, 187.3132), item = 'cash', min = 1000, max = 1500, chance = 60},
            {coords = vector3(-780.3466, 337.8327, 187.4456), item = 'flatscreen', min = 1, max = 1, chance = 100},
            {coords = vector3(-793.6407, 341.64, 187.1135), item = 'wallet', min = 1, max = 1, chance = 35},
            {coords = vector3(-799.5466, 329.7497, 190.7159), item = 'rolex', min = 1, max = 3, chance = 60},
            {coords = vector3(-781.9847, 330.7953, 187.3132), item = 'clam', min = 1, max = 2, chance = 60},
            {coords = vector3(-794.9417, 326.1464, 187.3132), item = 'microsmgblueprint', min = 1, max = 1, chance = 5},
            {coords = vector3(-796.7165, 328.4228, 187.3132), item = 'armour', min = 1, max = 1, chance = 5},
            {coords = vector3(-798.0312, 322.1114, 187.3132), item = 'computer_chip', min = 1, max = 1, chance = 15},
        },
        exit = vector3(-787.5426, 315.6943, 187.9135)
    },

    {
        coords = vector4(-580.4072, 491.5713, 108.903, 185.2434),
        blip = true,
        blipData = {
            sprite = 40, color = 5, scale = 0.8, name = "Luxury Robbable House"
        },
        lockpickItems = {'master_lockpick'},
        lockpickFailChance = 30,
        cooldownMinutes = 30,
        interior = vector4(-786.8663, 315.7642, 187.9136, 278.32),
        loot = {
            {coords = vector3(-789.1169, 320.7265, 187.3132), item = 'cash', min = 1000, max = 1500, chance = 60},
            {coords = vector3(-780.3466, 337.8327, 187.4456), item = 'flatscreen', min = 1, max = 1, chance = 100},
            {coords = vector3(-793.6407, 341.64, 187.1135), item = 'wallet', min = 1, max = 1, chance = 35},
            {coords = vector3(-799.5466, 329.7497, 190.7159), item = 'rolex', min = 1, max = 3, chance = 60},
            {coords = vector3(-781.9847, 330.7953, 187.3132), item = 'clam', min = 1, max = 2, chance = 60},
            {coords = vector3(-794.9417, 326.1464, 187.3132), item = 'microsmgblueprint', min = 1, max = 1, chance = 5},
            {coords = vector3(-796.7165, 328.4228, 187.3132), item = 'armour', min = 1, max = 1, chance = 5},
            {coords = vector3(-798.0312, 322.1114, 187.3132), item = 'computer_chip', min = 1, max = 1, chance = 15},
        },
        exit = vector3(-787.5426, 315.6943, 187.9135)
    },
}
