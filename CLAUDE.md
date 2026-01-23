# KTPGrenadeLoadout - Claude Code Context

## Compile Command
To compile this plugin, use:
```bash
wsl bash -c "cd '/mnt/n/Nein_/KTP Git Projects/KTPGrenadeLoadout' && bash compile.sh"
```

This will:
1. Compile `KTPGrenadeLoadout.sma` using KTPAMXX compiler
2. Output to `compiled/KTPGrenadeLoadout.amxx`
3. Auto-stage to `N:\Nein_\KTP Git Projects\KTP DoD Server\serverfiles\dod\addons\ktpamx\plugins\`

## Project Structure
- `KTPGrenadeLoadout.sma` - Main plugin source
- `compile.sh` - WSL compile script
- `compiled/` - Compiled .amxx output
- `data/grenade_loadout.ini` - Sample config file

## Config File
Deploy `data/grenade_loadout.ini` to: `addons/ktpamx/configs/grenade_loadout.ini`

### Config Format
```ini
[allies]
garand = 2      ; Class name = grenade count
carbine = 2
thompson = 1
...

[axis]
kar = 2
k43 = 2
...

[british]
enfield = 2
sten = 1
...
```

- Use -1 or omit entry to keep game default
- Maximum count: 10
- Class names are case-insensitive

## Dependencies
- **KTPAMXX** with DODX module containing `dodx_set_grenade_ammo` native
- Requires KTPAMXX build from 2026-01-22 or later

## Key Features
- INI-based per-class grenade configuration
- Applies grenades on spawn with delay (ensures default loadout is applied first)
- Works in extension mode (no Metamod required)
- Can be disabled via `ktp_grenade_loadout 0` cvar

## Class Name Reference
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
