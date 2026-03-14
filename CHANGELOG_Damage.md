# KTP Grenade Damage - Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.3] - 2026-03-13

### Fixed
- **TK damage also reduced** — Friendly fire grenade damage was incorrectly reduced. Now skips reduction when `TA` flag is set.
- **Minimum-1 floor at 100% reduction** — Setting reduction to 100% still dealt 1 damage. Now correctly allows 0 damage.

### Changed
- **Added `stock` tag** to `is_grenade_weapon` helper function.

---

## [1.0.2] - 2026-01-23

### Changed
- **Removed debug logging** - Production ready, no more console spam
  - Removed `ktp_grenade_dmg_debug` cvar
  - Removed debug print statements

---

## [1.0.1] - 2026-01-23

### Added
- **Debug cvar** - `ktp_grenade_dmg_debug` for troubleshooting
  - Prints original/reduced damage values to server console

### Fixed
- **Damage calculation** - Corrected percentage reduction formula

---

## [1.0.0] - 2026-01-23

### Added
- **Initial release** - Grenade damage reduction plugin
- **Configurable reduction** - `ktp_grenade_dmg_reduce` cvar (0-100%)
- **Enable/disable toggle** - `ktp_grenade_dmg` cvar
- **All grenade types supported**:
  - DODW_HANDGRENADE (US)
  - DODW_STICKGRENADE (German)
  - DODW_STICKGRENADE_EX (German variant)
  - DODW_HANDGRENADE_EX (US variant)
  - DODW_MILLS_BOMB (British)

### Technical
- Uses `dod_damage_pre` forward from KTPAMXX DODX module
- Returns modified damage value for DODX to apply heal-back

---

[1.0.3]: https://github.com/afraznein/KTPGrenades/releases/tag/damage-v1.0.3
[1.0.2]: https://github.com/afraznein/KTPGrenades/releases/tag/damage-v1.0.2
[1.0.1]: https://github.com/afraznein/KTPGrenades/releases/tag/damage-v1.0.1
[1.0.0]: https://github.com/afraznein/KTPGrenades/releases/tag/damage-v1.0.0
