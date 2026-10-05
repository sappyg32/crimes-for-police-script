# ox-cannabis — server-owned field and dealer

## Requirements

- **OneSync enabled** (`set onesync on`). Without it, server-side props and
  peds cannot be created. The server prints a warning at start if it is off.
- ox_lib, ox_target, ox_inventory.

## How it works

- **Plants:** created by the server as networked objects, so everyone sees
  the same ones. The server cannot read ground height, so the first player
  to come near the field resolves Z for each plant once and sends it to the
  server, which then spawns them. After that the field exists for everyone.
  Set `Config.Field.exportMode = true` once, copy `positions.lua` into
  `Config.Field.positions`, and the field spawns at boot with no client step.
- **Dealer:** created directly by the server (`CreatePed`), frozen in place
  with an idle scenario, and tagged with a state bag. Clients attach the
  sell option to any ped carrying that tag, so late joiners and re-streamed
  peds work. A watchdog respawns the dealer if it disappears.
- **Harvest/sell:** validated server-side (distance, inventory). The server
  deletes harvested plants and runs the respawn timer.
- **Dealer wander was removed.** Ped movement tasks are not available
  server-side, so the dealer now stands idle instead of pacing.

## Server console on a good start

```
[cannabis] field will spawn when the first player comes near it
[cannabis] dealer spawned (netId 1234)
[cannabis] field: 24/24 plants spawned      <- when someone nears the field
```

## Tuning

- Dealer floating or sunk: adjust `Config.Dealer.zOffset`.
- Plants rejected: raise `Config.Field.zTolerance`.
