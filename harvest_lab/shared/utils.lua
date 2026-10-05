-- Shared helpers, loaded on both sides.
-- Nothing in here may touch a client-only native: it is executed by the
-- server too.

---------------------------------------------------------------------
-- Ground height
---------------------------------------------------------------------
-- The server is the only place that resolves plant Z now, so this lives
-- here. GetGroundZFor_3dCoord is a client-native; when this file runs on
-- the server the caller must pass a fallback and accept it.
function GroundZFor(x, y, fallback)
    if IsDuplicityVersion() then
        return fallback
    end

    local found, z = GetGroundZFor_3dCoord(x, y, 1000.0, false)
    if found then return z end

    RequestCollisionAtCoord(x, y, fallback + 5.0)
    local timeout = GetGameTimer() + 1500
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and GetGameTimer() < timeout do
        Wait(0)
    end

    local ok, z2 = GetGroundZFor_3dCoord(x, y, fallback + 100.0, false)
    if ok then return z2 end

    return fallback
end

---------------------------------------------------------------------
-- Deterministic spawn ring
---------------------------------------------------------------------
-- Produces the same offsets on both sides so a plant's index always maps to
-- the same spot, and a respawn reuses the original position instead of
-- picking a new random one. The server walks this list once, up front, and
-- stores every resolved coord; it never re-rolls on respawn.
function BuildSpawnOffsets(loc)
    local offsets = {}

    for i = 1, loc.plantCount do
        local n = i

        -- stable per-index jitter (no math.random, so server and client agree)
        local jitter = (n * 2654435761) % 1000 / 1000 * 0.4
        local ring   = (n * 40503) % 1000 / 1000
        local spread = (n * 2246822519) % 1000 / 1000

        local angle = (n / loc.plantCount) * math.pi * 2 + jitter
        local dist  = math.sqrt(spread) * loc.radius

        offsets[i] = {
            dx   = math.cos(angle) * dist,
            dy   = math.sin(angle) * dist,
            rotZ = (n * 97) % 360
        }
    end

    return offsets
end

---------------------------------------------------------------------
-- Resolve a plant's placement height
---------------------------------------------------------------------
-- Crop/bush props report an origin that does not match the visible geometry,
-- so the model box is measured instead of the origin.
function ModelBottomOffset(model)
    if IsDuplicityVersion() then return 0.0 end
    if not HasModelLoaded(model) then return 0.0 end

    local minDim, maxDim = GetModelDimensions(model)
    if not minDim or not maxDim then return 0.0 end

    return minDim.z
end

function ResolvePlantZ(loc, z, model)
    if loc.useAutoSnap == false then
        -- origin misreports: trust the sampled ground and drop the model's
        -- actual bottom onto it
        return z + ModelBottomOffset(model) + (loc.zAdjust or 0.0)
    end

    -- origin is trustworthy: lift the creation point so the server's
    -- ground snap resolves downward onto real terrain instead of no-oping
    return z + 0.5 + (loc.zAdjust or 0.0)
end

---------------------------------------------------------------------
-- Blip helper
---------------------------------------------------------------------
function CreateHarvestBlip(coords, cfg)
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
