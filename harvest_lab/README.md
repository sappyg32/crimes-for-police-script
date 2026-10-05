# harvest_lab

A FiveM resource adding two harvest locations, a processing lab and a distributor NPC.

## Requirements
- ox_lib
- ox_target
- ox_inventory

## Install
1. Drop the `harvest_lab` folder into your `resources` directory.
2. Add `ensure harvest_lab` to your server.cfg (after ox_lib, ox_target and ox_inventory).
3. Copy the item definitions from `items_to_add.lua` into `ox_inventory/data/items.lua`
   (or better, into a separate file required from it), then restart ox_inventory.

## How spawning works (1.2.0)

Props and the distributor are spawned **by each client, when the player gets near**, and
removed when they leave (`Config.StreamDistance`, default 80m beyond a site's radius).

Earlier versions spawned everything once at resource start. A player who was far away
at that moment had no map collision loaded, so the ped and props could drop through the
terrain and never be seen, while a player standing nearby saw them fine. Spawning on
approach waits for the ground to exist before creating anything.

- Plant positions are fixed per index (no random), so they are identical on every client
  and a respawned plant returns to the same spot.
- The server tracks which plants are harvested and broadcasts changes, so a plant cut by
  one player disappears for everyone and cannot be harvested twice.
- Lab recipes and distributor offers are sent to the server by index and looked up there,
  so payouts and rewards cannot be forged by a modified client.

## Locations
| Spot         | Coords                                  | Yields                     | Respawn |
|--------------|-----------------------------------------|----------------------------|---------|
| Grain Field  | vec4(-2180.98, 2484.92, 5.09, 330.17)   | 3x magic_grain             | 60s     |
| Coco Leaves  | vec4(220.86, 7402.41, 16.91, 330.17)    | 2x coco_leaf               | 120s    |

## The Lab
Coords: vec4(3560.14, 3674.92, 28.12, 167.75)

- Process Magic Grain -> consumes 1 magic_grain, gives 10 acid
- Process Coco        -> consumes 1 coco_leaf, gives 3 yayo

## Distributor
Coords: vec4(-242.14, 6257.20, 31.49, 240.15). Wanders a ~10 ft radius.

- Sell Yayo -> consumes 1 yayo, pays $1000
- Sell Acid -> consumes 1 acid, pays $500

## Ground placement
- `useAutoSnap` - `true` when the prop's origin is trustworthy and it can be snapped
  down natively. `false` for props whose origin misreports (the coca bush).
- `zAdjust` - fine-tune lift in metres. Raise it if a prop noses into the ground, lower
  it if one hovers.

## Tweaking
Everything lives in `config.lua`: coords, props, item names, yields, respawn timers,
payouts, blip colours and stream distance.
