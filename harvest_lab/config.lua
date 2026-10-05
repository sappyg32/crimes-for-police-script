Config = {}

-- Props and the NPC are spawned by each client when the player gets within
-- Config.StreamDistance of a site, and removed when they leave. The server
-- only tracks which plants are harvested.
Config.StreamDistance = 80.0

-- Harvest locations
Config.Harvest = {
    {
        name        = 'grain_field',
        label       = 'Grain Field',
        marker      = vec4(-2180.98, 2484.92, 5.09, 330.17),
        prop        = 'prop_plant_01a',
        useAutoSnap = true,
        zAdjust     = 0.0,
        item        = 'magic_grain',
        amount      = 3,
        respawn     = 60,                        -- seconds
        plantCount  = 20,
        radius      = 20.0,
        blip        = { sprite = 496, color = 5, scale = 0.8, label = 'Ergot Grain Field' }
    },
    {
        name        = 'coco_leaves',
        label       = 'Coco Leaves',
        marker      = vec4(220.86, 7402.41, 16.91, 330.17),
        prop        = 'h4_prop_bush_cocaplant_01',
        useAutoSnap = false,
        zAdjust     = 0.6,
        item        = 'coco_leaf',
        amount      = 2,
        respawn     = 120,
        plantCount  = 20,
        radius      = 20.0,
        blip        = { sprite = 836, color = 2, scale = 0.8, label = 'Coca Leaves' }
    }
}

-- Processing lab
Config.Lab = {
    marker = vec4(3560.14, 3674.92, 28.12, 167.75),
    blip   = { sprite = 499, color = 27, scale = 0.9, label = 'The Lab' },
    recipes = {
        {
            label  = 'Process Acid',
            icon   = 'fa-solid fa-flask',
            cost   = { item = 'magic_grain', amount = 1 },
            reward = { item = 'acid', amount = 5 }
        },
        {
            label  = 'Process Cocaine',
            icon   = 'fa-solid fa-mortar-pestle',
            cost   = { item = 'coco_leaf', amount = 1 },
            reward = { item = 'yayo', amount = 3 }
        }
    }
}

-- Distributor NPC
Config.Distributor = {
    marker       = vec4(-242.14, 6257.20, 31.49, 240.15),
    model        = 'g_m_m_chigoon_02',
    wanderRadius = 3.05,        -- ~10 ft
    blip         = { sprite = 1, color = 1, scale = 0.9, label = 'Distributor' },
    offers = {
        { label = 'Sell Yayo', icon = 'fa-solid fa-sack-dollar', item = 'yayo', amount = 10, payout = 10000 },
        { label = 'Sell Acid', icon = 'fa-solid fa-sack-dollar', item = 'acid', amount = 10, payout = 5000  }
    }
}
