# KTP Grenade Loadout - Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.1] - 2026-01-23

### Fixed
- **INI parser bug** - Config parser incorrectly included `=` character in class name
  - Caused all classes to fail matching (logged as "Unknown class 'garand ='")
  - Fixed by correcting `copy()` length parameter from `eq + 1` to `eq`

---

## [1.0.0] - 2026-01-22

### Added
- **INI-based grenade loadout configuration** - Configure grenade counts per class
  - Config file: `<configsdir>/grenade_loadout.ini`
  - Sections: `[allies]`, `[axis]`, `[british]`
  - Supports all DoD classes
- **Spawn-time grenade application** - Sets grenades 0.2s after spawn
  - Delay ensures default loadout is applied first
  - Prevents game from resetting grenade count
- **Automatic grenade type detection** - Based on team/class
  - US classes: Hand Grenade
  - British classes: Mills Bomb
  - Axis classes: Stick Grenade
- **Enable/disable CVAR** - `ktp_grenade_loadout` (default: 1)
- **Game default fallback** - Classes not in config use game defaults

### Technical
- Uses new DODX natives: `dodx_set_grenade_ammo()`, `dodx_get_grenade_ammo()`
- Hooks `dod_client_spawn` forward from DODX module
- Config reloaded in `plugin_cfg()` after server.cfg runs

---

[1.0.1]: https://github.com/afraznein/KTPGrenadeLoadout/releases/tag/v1.0.1
[1.0.0]: https://github.com/afraznein/KTPGrenadeLoadout/releases/tag/v1.0.0
