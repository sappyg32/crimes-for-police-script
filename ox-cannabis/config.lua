Config = {}

-- Where the plants spawn
Config.Field = {
    coords = vec4(2496.59, 4857.20, 36.70, 33.74), -- centre of the field
    -- A client-resolved ground height must land within this many metres of
    -- coords.z or it is rejected (stops plants spawning in the sky/void).
    zTolerance = 20.0,
    blip = {
        sprite = 469,           -- weed leaf
        color = 2,              -- green
        scale = 0.8,
        label = 'Cannabis Field'
    }
}

-- How many plants, and how far they scatter from the centre
Config.Field.props = 24
Config.Field.radius = 12.0        -- metres; tune to taste

-- Prop model used for the plants
Config.Field.model = `prop_weed_01`

-- Optional: freeze the layout with exact positions (vector3 with real Z).
-- If empty, the first player to come near the field resolves ground heights
-- once and the server spawns the plants from that. Set exportMode = true to
-- write the resolved positions to positions.lua in the resource folder, then
-- paste them here.
Config.Field.positions = {}
Config.Field.exportMode = false

-- Harvest settings
Config.Harvest = {
    duration = 5000,              -- ms for the progress bar
    respawnTime = 60,             -- seconds until the plant returns
    amount = 3,                   -- cannabis per harvest
    item = 'cannabis',
    label = 'Harvest Weed',
    icon = 'fa-solid fa-cannabis',
    anim = {
        dict = 'amb@world_human_gardener_plant@male@base',
        clip = 'base',
        flag = 1
    }
}

-- The weed dealer NPC
Config.Dealer = {
    coords = vec4(1198.45, -1393.24, 35.23, 184.90),
    zOffset = 0.0,                          -- nudge if the ped floats (+) or sinks (-)
    model = `g_m_y_ballaeast_01`,           -- gang member model
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    blip = {
        sprite = 496,                       -- hand-holding-money icon
        color = 2,                          -- green
        scale = 0.8,
        label = 'Weed Dealer'
    },
    targetLabel = 'Sell Cannabis',
    targetIcon = 'fa-solid fa-hand-holding-dollar',
    targetDistance = 2.5,                   -- ox_target reach for the ped
    sellDistance = 25.0,                    -- server-side sanity check
    price = 300,                            -- money per cannabis
    payoutItem = 'money',
    item = 'cannabis'
}
