# KTP Grenade Loadout

**Version 1.0.1** - Per-class grenade loadout configuration for Day of Defeat servers

An AMX Mod X plugin that allows server administrators to customize grenade counts per class via INI configuration file.

---

## Features

- **INI-based configuration** - Simple config file format for grenade counts
- **Per-class customization** - Different grenade counts for each DoD class
- **All factions supported** - US, German, and British classes
- **Spawn-time application** - Grenades set on spawn with delay to ensure loadout sticks
- **Game default fallback** - Classes not in config use game defaults

---

## Requirements

- **KTPAMXX** with DODX module containing grenade ammo natives:
  - `dodx_set_grenade_ammo()`
  - `dodx_get_grenade_ammo()`

---

## Installation

1. **Compile** the plugin:
   ```bash
   amxxpc KTPGrenadeLoadout.sma -oKTPGrenadeLoadout.amxx
   ```

2. **Install** to your server:
   - KTPAMXX: `addons/ktpamx/plugins/KTPGrenadeLoadout.amxx`
   - AMX Mod X: `addons/amxmodx/plugins/KTPGrenadeLoadout.amxx`

3. **Add to** `plugins.ini`:
   ```
   KTPGrenadeLoadout.amxx
   ```

4. **Create config** at `<configsdir>/grenade_loadout.ini`:
   ```ini
   ; Grenade counts per class
   ; Set to -1 or omit to use game default

   [allies]
   garand = 2
   carbine = 2
   thompson = 1
   grease = 1
   sniper = 0
   bar = 1
   30cal = 0
   bazooka = 0

   [axis]
   kar = 2
   k43 = 2
   mp40 = 1
   mp44 = 1
   scharfschutze = 0
   fg42 = 1
   scopedfg42 = 1
   mg34 = 0
   mg42 = 0
   panzerjager = 0

   [british]
   enfield = 2
   sten = 1
   marksman = 0
   bren = 0
   piat = 0
   ```

5. **Restart** server

---

## Configuration

### Config File Location

`<configsdir>/grenade_loadout.ini`

- KTPAMXX: `addons/ktpamx/configs/grenade_loadout.ini`
- AMX Mod X: `addons/amxmodx/configs/grenade_loadout.ini`

### Config Format

```ini
[section]
classname = count
```

- **Sections**: `[allies]`, `[axis]`, `[british]`
- **Class names**: Lowercase (see table below)
- **Count**: 0-10, or -1 to use game default

### Class Names

| Allies | Axis | British |
|--------|------|---------|
| garand | kar | enfield |
| carbine | k43 | sten |
| thompson | mp40 | marksman |
| grease | mp44 | bren |
| sniper | scharfschutze | piat |
| bar | fg42 | |
| 30cal | scopedfg42 | |
| bazooka | mg34 | |
| | mg42 | |
| | panzerjager | |

---

## CVARs

| CVAR | Default | Description |
|------|---------|-------------|
| `ktp_grenade_loadout` | 1 | Enable/disable the plugin (0 = disabled) |

---

## Technical Notes

- Grenades are set 0.2 seconds after spawn to ensure the default loadout has been applied first
- The plugin hooks `dod_client_spawn` forward from DODX module
- Grenade types are automatically determined by team:
  - Allies (US): Hand Grenade
  - Allies (British): Mills Bomb
  - Axis: Stick Grenade

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## License

GPL-2.0 - See [LICENSE](LICENSE) file for details.

---

## Author

**Nein_**
- GitHub: [@afraznein](https://github.com/afraznein)
- Project: KTP Competitive Infrastructure

---

## Related Projects

- [KTPAMXX](https://github.com/afraznein/KTPAMXX) - Custom AMX Mod X fork with DODX grenade natives
- [KTPMatchHandler](https://github.com/afraznein/KTPMatchHandler) - Competitive match management
- [KTPPracticeMode](https://github.com/afraznein/KTPPracticeMode) - Practice mode with infinite grenades
