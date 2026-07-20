# KTP Grenade Loadout - Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Documentation

Doc-only pass; no plugin logic changed.

- **Added the `ktp_grenade_loadout_debug` cvar to the README.** It has existed
  since 1.0.5 but was never promoted out of the changelog, so the CVAR table
  listed one cvar when there are two. Documented with the production warning —
  that path is disk I/O on the game thread.
- **Corrected clamp-vs-reject.** The README read as if `-1`..`10` were enforced.
  Only non-numeric values are rejected; numeric out-of-range values are clamped
  silently. The CI test already had this right.
- **Documented that INI sections are cosmetic.** The parser skips every `[...]`
  line and matches class names globally, so grouping is convention only and a
  duplicated class key is last-wins across the whole file. The README, the
  config-test docstrings, and the CI workflow header all described sections as
  enforced. Note the per-section duplicate check in `test_grenade_loadout_ini.py`
  is narrower than the plugin's global resolution.
- Installation now points at the shipped `data/grenade_loadout.ini` sample and
  labels the inline block an example — the two differ, and nothing said which
  was authoritative.
- Requirements now name the `ktp_version_reporter` include and the
  `dod_client_spawn` forward (this plugin's entry point). Flagged that the stated
  "KTPAMXX 2.6.6+" floor is understated because of that include; the exact
  minimum release is unconfirmed.
- Compiling section notes this repo is the stack's `compile.sh` exception —
  two plugins, two build scripts.
- Not logged when it shipped: `SPAWN_DELAY` moved 0.2s → 0.5s in 1.0.2. The
  1.0.2 entry records only the HUD-sync fix; source is `0.5`. Recorded here
  rather than editing the historical entry.

## [1.0.9] - 2026-07-08

### Fixed
- **`dodx_give_grenade` return now checked** — the native returns 0 (entity create/spawn failed or player died) or -1 (pickup refused, entity removed — treat as "entity not granted"), and both were silently ignored before the ammo write. Failures now log a line with player/class/grenade-type. Success-path behavior unchanged; the ammo write still runs so a partial failure stays visible instead of compounding.
- **Non-numeric config values no longer strip grenades** — `str_to_num("abc")` returns 0, so a typo'd value silently zeroed the class's grenade count. Values are now validated as integers before parsing (inline `;`/`#`/`//` comments still allowed); invalid entries are rejected with a log naming the key and value, and the class keeps the game default.

---

## [1.0.8] - 2026-04-25

### Added
- **Adopted `ktp_version_reporter` shared include** — plugin now registers with the fleet-wide `amx_ktp_versions` rcon command (ADMIN_RCON). Output reports name, version, build SHA, and build time alongside other KTP plugins. See KTPMatchHandler 0.10.116 for the canary release introducing the include.
- **`compile_loadout.sh` build-info generation** — git short SHA + UTC build time written to `build_info.inc` and baked into the .amxx so the rcon command can report what's actually deployed.

### Fixed
- **`compile_loadout.sh` temp-dir nesting bug** — `cp -r src dst` accumulates nested `include/` dirs on re-runs. Added `rm -rf "$TEMP_BUILD"` before `mkdir`. (`compile_damage.sh` already had the fix.) Discovered while wiring `ktp_version_reporter`.

---

## [1.0.7] - 2026-03-24

### Changed
- **Version broadcast removed** — No longer sends plugin info to players on connect. Reduces chat noise and avoids leaking server tech stack.
- **INI section parsing removed** — Sections (`[allies]`, `[axis]`, `[british]`) were parsed but never enforced — class names are globally unique. Removed dead `section` variable and simplified parser. Sections remain as cosmetic comments in the INI.
- **`find_class_by_name` skips empty entries** — Unused mortar class slots (indices 9, 20) with empty names could false-match on malformed INI keys. Now skips `""` entries.
- **Dead code removed** — `TASK_VERSION_BASE`, `task_version_display`, and `client_putinserver`/`client_disconnected` version task management all removed.

---

## [1.0.6] - 2026-03-13

### Fixed
- **`g_bTaskScheduled` not reset on map change** — If map changed while batch task was in flight, flag stayed `true` permanently, blocking all future spawn grenade processing.
- **Section parser copied trailing `]`** — INI section names included the closing bracket character.
- **`set_task` used raw player ID as task ID** — Version display and batch tasks now use dedicated `TASK_VERSION_BASE` and `TASK_BATCH_SPAWN` constants.
- **INI key copy not clamped to buffer size** — `copy(key, eq, line)` used the raw `=` position as max length without clamping to `charsmax(key)`. A config key longer than 31 chars would overflow the `key[32]` buffer.

### Changed
- Version announcement restricted to connected players with proper task cleanup.

### Added
- `plugin_end()` to reset batch state on map change.
- `client_disconnected` cleanup for version display task.

---

## [1.0.5] - 2026-02-05

### Fixed
- **Performance: 196ms+ spike on mass spawns** - Observed during 12-man match round starts
  - Root cause: `log_amx()` called for every player spawn = 12 synchronous disk writes
  - Solution: Removed per-spawn logging, added optional debug cvar

### Changed
- **Batched spawn processing** - All spawns in a frame are now processed in a single task
  - Before: 12 separate `set_task()` calls on round start
  - After: 1 task processes all queued players
- **Removed redundant native call** - Eliminated verification `dodx_get_grenade_ammo()` after setting

### Added
- **Debug cvar** - `ktp_grenade_loadout_debug` (default: 0)
  - Set to 1 for verbose per-spawn logging (not recommended in production)
  - Logs individual player grenade assignments when enabled

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

[1.0.6]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.6
[1.0.5]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.5
[1.0.4]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.4
[1.0.3]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.3
[1.0.2]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.2
[1.0.1]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.1
[1.0.0]: https://github.com/afraznein/KTPGrenades/releases/tag/loadout-v1.0.0
