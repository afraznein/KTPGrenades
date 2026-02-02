# KTP Grenade Loadout - Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.4] - 2026-02-01

### Changed
- **Code cleanup** - Reduced verbose logging and simplified spawn handler logic
  - Removed redundant log_amx calls with detailed debug info
  - Simplified if/else blocks
  - Consolidated grenade type selection logic

---

## [1.0.3] - 2026-01-23

### Fixed
- **Classes without grenades** - Sniper, MG, and other classes that don't normally spawn with grenades can now receive them
  - Uses `dodx_give_grenade` native to give weapon slot before setting ammo
  - Previously these classes would have ammo set but no grenade weapon

---

## [1.0.2] - 2026-01-23

### Fixed
- **Client HUD not showing modified grenade count** - After setting grenade ammo, client HUD displayed the default value instead of the configured value
  - Now uses `dodx_send_ammox` native to send AmmoX message and sync client HUD
  - Requires KTPAMXX 2.6.6+ with new `dodx_send_ammox` native

### Added
- **Version echo to player** - Displays plugin name and version in chat 5 seconds after player connects

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

[1.0.4]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.4
[1.0.3]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.3
[1.0.2]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.2
[1.0.1]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.1
[1.0.0]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.0
