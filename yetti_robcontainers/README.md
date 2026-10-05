# Yetti Rob Containers (map marker build)

Based on [YeeetSK/yetti_robcontainers](https://github.com/YeeetSK/yetti_robcontainers) (GPL-3.0).

## What this build adds

- **Gang NPC** at `vec4(336.45, -1015.20, 29.29, 100.44)` with its own permanent blip.
- **Container map markers** that do NOT appear until you ox_target the NPC and request the jobs.
- Each container's blip is removed as you enter it.
- When all containers are completed, **every container blip is removed** — only the NPC blip remains.
- **10 minute cooldown** before the NPC will hand out the job list again.
- **Every container pays 5000 dirty money.**
- **Backspace ends the job early** — press `BACKSPACE` while a job is running to clear
  every marker and reset the round. `/endrobbery` does the same thing.

## Dependencies

- ox_lib
- ox_target
- ox_inventory
- Starter Shells (props)

## Install

1. Drop `yetti_robcontainers` into your resources directory.
2. In `server.cfg`, `ensure yetti_robcontainers` **after** the dependencies.

## Tuning

| Setting | Where | Default |
| --- | --- | --- |
| NPC coords / model / blip | `config.lua` → `Config.Npc` | dealer ped, red blip |
| Container blip look | `config.lua` → `Config.ContainerBlip` | sprite 478, yellow |
| Re-request cooldown | `config.lua` → `Config.RequestCooldown` | 600 (10 min) |
| Payout per container | `config.lua` → `Config.ContainerPayout` | 5000 |
| Dirty money item | `config.lua` → `Config.DirtyMoneyItem` | `black_money` |
| Container locations | `config.lua` → `Config.ContainerCoords` | 5 locations |
| End-job key | `config.lua` → `Config.EndJobKey` | 177 (BACKSPACE) |

## Ending a job early

While a job is active, pressing `Config.EndJobKey` (default **BACKSPACE**, control index `177`)
runs the same reset as the `/endrobbery` command:

- every container blip is removed,
- client-side progress is wiped,
- markers stay off until the NPC hands out a new job,
- the NPC request cooldown is freed immediately,
- the server-side per-container payout locks are cleared.

The key does nothing when no job is running. Set `Config.EndJobKey = false` to
disable it entirely. `194` (DELETE) is a good alternative if another resource
already uses backspace.

The reset also fires a local event you can hook from another resource:

```lua
AddEventHandler('yetti_robcontainers:client:ended', function (reason)
    -- reason: 'key' | 'command' | 'manual'
end)
```

`exports.yetti_robcontainers:EndRobbery()` remains available for radial menus
and keybinds.

## Notes

- `Config.Cooldown` (120s) is the per-container re-entry lock; the 10 minute
  figure is the separate NPC re-request gate (`Config.RequestCooldown`).
- This build targets ox_inventory. On ESX, swap the inventory calls
  (`exports.ox_inventory:Search` / `AddItem`) for ESX player methods and pay
  `black_money` as an account rather than an item.
- If your server names dirty money something other than `black_money`
  (`markedbills`, `dirtymoney`), change `Config.DirtyMoneyItem`.
