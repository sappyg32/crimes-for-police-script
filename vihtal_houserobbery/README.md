# Vihtal House Robbery

A house robbery system for FiveM ESX Legacy servers with stealth mechanics, noise system, and tiered house difficulties.

## Features

- **Tiered Houses**: Poor, Medium, and High-End houses with different lockpick requirements and loot
- **Stealth System**: Noise meter that increases when moving - crouch to stay quiet
- **Lockpick Mechanics**: Different lockpick tiers (basic, advanced, master) with durability
- **Instancing**: Players are teleported to private instances so multiple robberies don't conflict
- **Police Alerts**: Dispatch integration for failed attempts and caught players
- **Discord Logging**: Optional webhook logging for all robbery activities
- **Configurable**: All settings, houses, loot, and mechanics fully configurable

## Dependencies

- [es_extended](https://github.com/esx-framework/esx_core) (ESX Legacy)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)

## Installation

1. Download and extract to your resources folder
2. Add `ensure vihtal_houserobbery` to your server.cfg
3. Configure `config.lua` to your liking
4. Add the lockpick items to your ox_inventory items if not already present




```

### Lockpick Items
The script supports three tiers of lockpicks:
- `lockpick` - Basic (works on poor houses)
- `advanced_lockpick` - Advanced (works on poor + medium houses)
- `master_lockpick` - Master (works on all houses)



## Noise System

When inside a house:
- **Walking** increases noise
- **Running** increases noise faster
- **Sprinting** increases noise very fast
- **Crouching** (CTRL) significantly reduces noise gain
- **Standing still** decreases noise over time
- **100% noise** = caught by homeowner (hostile NPC spawns)

## Credits

- **Author**: Vihtal
- **Version**: 1.1.0

## License

This resource is free to use and modify. Credit appreciated but not required.
