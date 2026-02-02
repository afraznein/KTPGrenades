# KTPGrenades - Claude Code Context

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
- Maximum count: 10
- Class names are case-insensitive

### Cvars
| Cvar | Default | Description |
|------|---------|-------------|
| `ktp_grenade_loadout` | 1 | Enable/disable plugin |

### Dependencies
- KTPAMXX 2.6.6+ with DODX module (`dodx_set_grenade_ammo`, `dodx_give_grenade`, `dodx_send_ammox`)

---

## KTPGrenadeDamage

### Cvars
| Cvar | Default | Description |
|------|---------|-------------|
| `ktp_grenade_dmg` | 1 | Enable/disable damage reduction |
| `ktp_grenade_dmg_reduce` | 50 | Reduction percentage (0-100) |

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

**Server Credentials:**
| Server | Host | User | Password |
|--------|------|------|----------|
| Atlanta | 74.91.112.182 | dodserver | ktp |
| Dallas | 74.91.114.195 | dodserver | ktp |

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
