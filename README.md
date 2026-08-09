# KTP Grenades

Grenade-related plugins for Day of Defeat servers running KTPAMXX.

---

## Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| **KTPGrenadeLoadout** | 1.0.11 | Per-class grenade loadout configuration via INI file |
| **KTPGrenadeDamage** | 1.0.5 | Grenade damage reduction by configurable percentage |

---

## Requirements

- **KTPAMXX 2.6.6+** with DODX module containing:
  - `dodx_set_grenade_ammo()` / `dodx_get_grenade_ammo()`
  - `dodx_send_ammox()`
  - `dodx_give_grenade()`
  - `dod_damage_pre` forward (Damage plugin)
  - `dod_client_spawn` forward (Loadout plugin — its entire entry point)
- **`ktp_version_reporter.inc`** from the KTPAMXX include tree. Both plugins include it,
  so the "2.6.6+" floor above is understated: any include tree without that file fails to
  compile. Exact minimum release unconfirmed.

Both plugins report name/version/build SHA/build time through the fleet-wide
`amx_ktp_versions` rcon command (ADMIN_RCON).

---

## KTPGrenadeLoadout

Customize grenade counts per class via INI configuration file.

### Features

- **INI-based configuration** - Simple config file format
- **Per-class customization** - Different counts for each DoD class
- **All factions supported** - US, German, and British classes
- **Classes without grenades** - Give grenades to snipers, MGs, etc.
- **Spawn-time application** - Grenades set on spawn with delay
- **HUD sync** - Client ammo display updates correctly

### Installation

1. Copy `KTPGrenadeLoadout.amxx` to `addons/ktpamx/plugins/`
2. Add to `plugins.ini`: `KTPGrenadeLoadout.amxx`
3. Copy the shipped sample `data/grenade_loadout.ini` to
   `addons/ktpamx/configs/grenade_loadout.ini` and edit it. The block below is an
   illustrative example, not the shipped defaults — the two differ:

```ini
[allies]
garand = 2
carbine = 2
thompson = 1
grease = 1
sniper = 1        ; Classes without default grenades supported
bar = 1
30cal = 1
bazooka = 0

[axis]
kar = 2
k43 = 2
mp40 = 1
mp44 = 1
scharfschutze = 1
fg42 = 1
scopedfg42 = 1
mg34 = 1
mg42 = 1
panzerjager = 0

[british]
enfield = 2
sten = 1
marksman = 1
bren = 1
piat = 0
```

Values must be integers (inline `;`/`#`/`//` comments allowed). Numeric values outside `-1` to `10` are **clamped** to that range silently; non-numeric values are **rejected** with a log line and the class keeps the game default — they no longer silently parse to 0 and strip grenades.

Sections are cosmetic. The parser skips every `[...]` line and matches class names globally, so a key resolves the same regardless of which section it sits under — and a class listed twice anywhere in the file is last-wins.

### CVARs

| CVAR | Default | Description |
|------|---------|-------------|
| `ktp_grenade_loadout` | 1 | Enable/disable plugin (0 = disabled) |
| `ktp_grenade_loadout_debug` | 0 | Verbose per-spawn logging. Leave off in production — this is disk I/O on the game thread (see the 1.0.5 spawn-spike note) |

### Changelog

See [CHANGELOG_Loadout.md](CHANGELOG_Loadout.md)

---

## KTPGrenadeDamage

Reduces grenade damage by a configurable percentage.

### Features

- **Configurable reduction** - Set damage reduction percentage (0-100%)
- **All grenade types** - Hand grenades, stick grenades, Mills bombs
- **Non-intrusive** - Uses DODX damage forward, no entity modification

### Installation

1. Copy `KTPGrenadeDamage.amxx` to `addons/ktpamx/plugins/`
2. Add to `plugins.ini`: `KTPGrenadeDamage.amxx`

### CVARs

| CVAR | Default | Description |
|------|---------|-------------|
| `ktp_grenade_dmg` | 1 | Enable/disable damage reduction (0 = disabled) |
| `ktp_grenade_dmg_reduce` | 50 | Reduction percentage (0-100). 50 = 50% less damage. **Cached at map load** — an rcon change takes effect at the next map change, silently until then. (`ktp_grenade_dmg` is read live.) |

### How It Works

1. DODX fires `dod_damage_pre` forward before finalizing damage
2. Plugin checks if weapon is a grenade type
3. Returns modified damage: `original * (100 - reduction) / 100`
4. DODX heals player by the difference, effectively reducing damage taken
5. At 100% reduction, damage is reduced to 0 (friendly fire is not reduced)

**Platform contract:** `dod_damage_pre` is an ET_CONTINUE forward — DODX applies the *highest* return value across plugins. If a second damage-modifier plugin ever ships, the least reduction silently wins. The single-modifier assumption is load-bearing.

### Changelog

See [CHANGELOG_Damage.md](CHANGELOG_Damage.md)

---

## Class Names Reference

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

## Compiling

This repo is the stack's one exception to the standard `compile.sh` pattern: it holds
two independently-versioned plugins, so each has its own build script. There is no
`compile.sh` here.

### Loadout Plugin
```bash
wsl bash -c "cd '/mnt/n/Nein_/KTP Git Projects/KTPGrenades' && bash compile_loadout.sh"
```

### Damage Plugin
```bash
wsl bash -c "cd '/mnt/n/Nein_/KTP Git Projects/KTPGrenades' && bash compile_damage.sh"
```

---

## License

GPL-3.0 — see [LICENSE](LICENSE).

---

## Author

**Nein_**
- GitHub: [@afraznein](https://github.com/afraznein)
- Project: KTP Competitive Infrastructure

---

## Related Projects

- [KTPAMXX](https://github.com/afraznein/KTPAMXX) - Custom AMX Mod X with DODX grenade natives
- [KTPMatchHandler](https://github.com/afraznein/KTPMatchHandler) - Competitive match management
- [KTPPracticeMode](https://github.com/afraznein/KTPPracticeMode) - Practice mode with infinite grenades
