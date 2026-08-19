# KTPGrenades - Claude Code Context

**REQUIRED: Before writing or modifying any code in this repo, invoke the `plugin-dev` skill** (`.claude/skills/plugin-dev/SKILL.md`). It carries the two-plugin build/version conventions and deploy workflow; do not edit either .sma without it loaded.

Combined grenade-related plugins for KTP Day of Defeat servers.

## Plugins in This Repository

| Plugin | Source | Description |
|--------|--------|-------------|
| **KTPGrenadeLoadout** | `KTPGrenadeLoadout.sma` | Per-class grenade loadout configuration via INI |
| **KTPGrenadeDamage** | `KTPGrenadeDamage.sma` | Grenade damage reduction by configurable percentage |

---

## Compile Commands

### Compile Loadout Plugin
```bash
wsl bash -c "cd '/mnt/n/Nein_/KTP Git Projects/KTPGrenades' && bash compile_loadout.sh"
```

### Compile Damage Plugin
```bash
wsl bash -c "cd '/mnt/n/Nein_/KTP Git Projects/KTPGrenades' && bash compile_damage.sh"
```

Both scripts:
1. Compile using KTPAMXX compiler
2. Output to `compiled/` directory
3. Auto-stage to `N:\Nein_\KTP Git Projects\KTP DoD Server\serverfiles\dod\addons\ktpamx\plugins\`

---

## Project Structure

```
KTPGrenades/
  KTPGrenadeLoadout.sma      # Loadout plugin source
  KTPGrenadeDamage.sma       # Damage plugin source
  compile_loadout.sh         # Loadout compile script
  compile_damage.sh          # Damage compile script
  compiled/                  # Compiled .amxx output
  data/
    grenade_loadout.ini      # Sample loadout config
  tests/
    config_parse/            # pytest schema guard for grenade_loadout.ini
  .github/workflows/         # Tier 1 smoke + config-parse CI
  CHANGELOG_Loadout.md       # Loadout version history
  CHANGELOG_Damage.md        # Damage version history
```

---

## KTPGrenadeLoadout

### Config File
Deploy `data/grenade_loadout.ini` to: `addons/ktpamx/configs/grenade_loadout.ini`

```ini
[allies]
garand = 2      ; Class name = grenade count
carbine = 2
thompson = 1
sniper = 1      ; Classes without default grenades also supported
...

[axis]
kar = 2
scharfschutze = 1
...

[british]
enfield = 2
marksman = 1
...
```

- Use -1 or omit entry to keep game default
- Maximum count: 10 (numeric out-of-range values are clamped silently; non-numeric are rejected with a log line)
- Class names are case-insensitive
- Section headers are cosmetic — the parser skips `[...]` lines and matches class names globally, so a duplicated class key is last-wins across the whole file

### Cvars
| Cvar | Default | Description |
|------|---------|-------------|
| `ktp_grenade_loadout` | 1 | Enable/disable plugin |
| `ktp_grenade_loadout_debug` | 0 | Verbose per-spawn logging. Off in production — disk I/O on the game thread |

### Dependencies
- KTPAMXX **2.7.29+** with DODX module (`dodx_set_grenade_ammo`, `dodx_give_grenade`) and the `dod_client_spawn` forward. The 2.7.29 floor does not fail loudly: older DODX writes `m_rgAmmoLast` and suppresses the DLL's own `AmmoX`, so the grenade HUD count stops moving (1.0.12 removed the manual `dodx_send_ammox` that covered for that). Behaviour on an older module is **undefined, not merely degraded** — 2.7.27 also addresses `m_rgAmmo` one int low, so its ammo writes miss the right slot regardless. **Stage the module before this plugin.**
- `ktp_version_reporter.inc` from the KTPAMXX include tree. Both plugins include it, so the long-stated floor is understated — an include tree without that file fails to compile. Exact minimum release unconfirmed.

---

## KTPGrenadeDamage

### Cvars
| Cvar | Default | Description |
|------|---------|-------------|
| `ktp_grenade_dmg` | 1 | Enable/disable damage reduction |
| `ktp_grenade_dmg_reduce` | 50 | Reduction percentage (0-100). Cached at `plugin_cfg` — rcon changes take effect next map change, silently. `ktp_grenade_dmg` is live |

### How It Works
1. DODX fires `dod_damage_pre` forward before finalizing damage
2. Plugin checks if weapon ID is a grenade type
3. Returns modified damage value (original * (100 - reduction) / 100)
4. DODX heals player by the difference, effectively reducing damage

### Grenade Weapon IDs
| Constant | Value | Description |
|----------|-------|-------------|
| DODW_HANDGRENADE | 13 | US/Allied hand grenade |
| DODW_STICKGRENADE | 14 | German stick grenade |
| DODW_STICKGRENADE_EX | 15 | German stick grenade (variant) |
| DODW_HANDGRENADE_EX | 16 | Allied hand grenade (variant) |
| DODW_MILLS_BOMB | 36 | British Mills bomb |

### Dependencies
- KTPAMXX DODX module with `dod_damage_pre` forward

---

## Class Name Reference (Loadout)

| Section | Class Name | DODC Constant | Description |
|---------|------------|---------------|-------------|
| allies | garand | DODC_GARAND | Rifleman |
| allies | carbine | DODC_CARBINE | Staff Sergeant |
| allies | thompson | DODC_THOMPSON | Master Sergeant |
| allies | grease | DODC_GREASE | Sergeant |
| allies | sniper | DODC_SNIPER | Sniper |
| allies | bar | DODC_BAR | Support Infantry |
| allies | 30cal | DODC_30CAL | Machine Gunner |
| allies | bazooka | DODC_BAZOOKA | Rocket Infantry |
| axis | kar | DODC_KAR | Grenadier |
| axis | k43 | DODC_K43 | Stosstruppe |
| axis | mp40 | DODC_MP40 | Unteroffizier |
| axis | mp44 | DODC_MP44 | Sturmtruppe |
| axis | scharfschutze | DODC_SCHARFSCHUTZE | Sniper |
| axis | fg42 | DODC_FG42 | FG42-Zweibein |
| axis | scopedfg42 | DODC_SCOPED_FG42 | FG42-Zielfernrohr |
| axis | mg34 | DODC_MG34 | MG34-Schutze |
| axis | mg42 | DODC_MG42 | MG42-Schutze |
| axis | panzerjager | DODC_PANZERJAGER | Panzerjager |
| british | enfield | DODC_ENFIELD | Rifleman |
| british | sten | DODC_STEN | Sergeant Major |
| british | marksman | DODC_MARKSMAN | Marksman |
| british | bren | DODC_BREN | Gunner |
| british | piat | DODC_PIAT | Piat |

---

## Server Deployment

Deploy compiled plugins to production servers using Python/Paramiko.

**Remote Paths:**
- `~/dod-{port}/serverfiles/dod/addons/ktpamx/plugins/KTPGrenadeLoadout.amxx`
- `~/dod-{port}/serverfiles/dod/addons/ktpamx/plugins/KTPGrenadeDamage.amxx`

See `N:\Nein_\KTP Git Projects\CLAUDE.md` for paramiko SSH documentation.

---

## Version Bump Checklist

### KTPGrenadeLoadout
1. `KTPGrenadeLoadout.sma` - Update version header and `PLUGIN_VERSION`
2. `CHANGELOG_Loadout.md` - Add new version entry
3. `README.md` - Update version in Loadout section

### KTPGrenadeDamage
1. `KTPGrenadeDamage.sma` - Update `#define PLUGIN_VERSION`
2. `CHANGELOG_Damage.md` - Add new version entry
3. `README.md` - Update version in Damage section
