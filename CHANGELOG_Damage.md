# KTP Grenade Damage - Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Documentation

Doc-only pass; no plugin logic changed.

- **`ktp_grenade_dmg_reduce` was documented as if it were live.** It is read once
  into `g_fCachedReduction` at `plugin_cfg` and the damage path only ever reads
  the cache, so an rcon change mid-match does nothing until the next map — with
  no error and no feedback. Worse, `ktp_grenade_dmg` in the same table *is* live,
  so two adjacent rows behaved differently with nothing to distinguish them. The
  caching is deliberate (1.0.4, to avoid a cvar read per damage event); it just
  never reached the README. Caveat added.
- **Licence is now actually shipped, and it is GPL-3.0, not GPL-2.0.** The repo is
  public and asserted GPL-2.0 in the README with no licence text behind it — a
  grant nobody could read, pointing at a 404. GPL-2.0 was also wrong: every other
  KTP plugin that ships a licence is GPL-3, and these plugins build against
  GPL-3 KTPAMXX headers, which GPL-2-only terms sit awkwardly against. `LICENSE`
  (GPL-3.0) added and the README now links it.

## [1.0.5 docs note] - 2026-07-08

- **Platform contract documented (no code change, stays 1.0.5):** `dod_damage_pre` is an ET_CONTINUE forward — DODX applies the highest return value across plugins, so if a second damage-modifier plugin ever ships, the least reduction silently wins. The single-modifier assumption is load-bearing. Noted in the source header and README.

---

## [1.0.5] - 2026-04-25

### Added
- **Adopted `ktp_version_reporter` shared include** — plugin now registers with the fleet-wide `amx_ktp_versions` rcon command (ADMIN_RCON). Output reports name, version, build SHA, and build time alongside other KTP plugins. See KTPMatchHandler 0.10.116 for the canary release introducing the include.
- **`compile_damage.sh` build-info generation** — git short SHA + UTC build time written to `build_info.inc` and baked into the .amxx so the rcon command can report what's actually deployed.

---

## [1.0.4] - 2026-03-24

### Changed
- **Cached reduction cvar** — `get_pcvar_float(g_pCvarReduction)` was called on every grenade damage event in a hot path. Now cached at `plugin_cfg` into `g_fCachedReduction` with clamping. RCON changes require map change (acceptable for a rarely-changed setting).
- **Removed `server_print` from `plugin_init`** — Fired on every map change. `register_plugin` already records the plugin for `amx plugins` output.

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
