/* KTP Grenade Loadout v1.0.4
 * Customizable grenade loadouts per class via INI config
 *
 * AUTHOR: Nein_
 * VERSION: 1.0.4
 * DATE: 2026-02-01
 *
 * ========== FEATURES ==========
 * - Configure grenade counts per class via INI file
 * - Supports all DoD classes (US, German, British)
 * - Sets grenades on spawn with configurable delay
 * - Works in extension mode (no Metamod required)
 *
 * ========== REQUIREMENTS ==========
 * - KTPAMXX 2.6.6+ with DODX module (grenade ammo natives, dodx_give_grenade)
 *
 * ========== CONFIG FILE ==========
 * Location: addons/ktpamx/configs/grenade_loadout.ini
 *
 * Format:
 *   [allies]
 *   garand = 2
 *   carbine = 2
 *   thompson = 1
 *   ...
 *
 *   [axis]
 *   kar = 2
 *   k43 = 2
 *   mp40 = 1
 *   ...
 *
 *   [british]
 *   enfield = 2
 *   sten = 1
 *   ...
 *
 * ========== CHANGELOG ==========
 *
 * v1.0.4 (2026-02-01) - Code Cleanup
 *   * CHANGED: Reduced verbose logging
 *   * CHANGED: Simplified spawn handler logic
 *
 * v1.0.3 (2026-01-23) - Classes Without Grenades Fix
 *   * FIXED: Classes that don't normally have grenades (sniper, MG, etc.) now receive them
 *   * ADDED: Uses dodx_give_grenade to give weapon slot before setting ammo
 *
 * v1.0.2 (2026-01-23) - HUD Sync Fix
 *   * FIXED: Client HUD now correctly shows modified grenade count
 *   * ADDED: Uses new dodx_send_ammox native for HUD updates
 *   * ADDED: Version echo to player on connect
 *
 * v1.0.1 (2026-01-23) - Config Parsing Fix
 *   * FIXED: INI parser incorrectly included '=' in class name
 *
 * v1.0.0 (2026-01-22) - Initial Release
 *   + ADDED: INI-based grenade loadout configuration
 *   + ADDED: Per-class grenade counts for all DoD classes
 *   + ADDED: Delayed spawn application to ensure loadout sticks
 *
 */

#include <amxmodx>
#include <amxmisc>
#include <dodx>
#include <dodconst>

// Ammo slots for grenades (from DODX weaponData)
#define AMMOSLOT_HANDGRENADE 9
#define AMMOSLOT_STICKGRENADE 11

#define PLUGIN_NAME    "KTP Grenade Loadout"
#define PLUGIN_VERSION "1.0.4"
#define PLUGIN_AUTHOR  "Nein_"

// Grenade weapon IDs from dodconst.inc
#define DODW_HANDGRENADE  13
#define DODW_STICKGRENADE 14
#define DODW_MILLS_BOMB   36

// Default grenade count if not specified in config
#define DEFAULT_GRENADE_COUNT 1

// Class name mappings for INI parsing
// Index corresponds to DODC_* constants from dodconst.inc
new const g_szClassNames[][] = {
    "",             // 0 - unused
    "garand",       // 1 - DODC_GARAND
    "carbine",      // 2 - DODC_CARBINE
    "thompson",     // 3 - DODC_THOMPSON
    "grease",       // 4 - DODC_GREASE
    "sniper",       // 5 - DODC_SNIPER
    "bar",          // 6 - DODC_BAR
    "30cal",        // 7 - DODC_30CAL
    "bazooka",      // 8 - DODC_BAZOOKA
    "",             // 9 - unused (was DODC_ALLIES_MORTAR)
    "kar",          // 10 - DODC_KAR
    "k43",          // 11 - DODC_K43
    "mp40",         // 12 - DODC_MP40
    "mp44",         // 13 - DODC_MP44
    "scharfschutze",// 14 - DODC_SCHARFSCHUTZE
    "fg42",         // 15 - DODC_FG42
    "scopedfg42",   // 16 - DODC_SCOPED_FG42
    "mg34",         // 17 - DODC_MG34
    "mg42",         // 18 - DODC_MG42
    "panzerjager",  // 19 - DODC_PANZERJAGER
    "",             // 20 - unused (was DODC_AXIS_MORTAR)
    "enfield",      // 21 - DODC_ENFIELD
    "sten",         // 22 - DODC_STEN
    "marksman",     // 23 - DODC_MARKSMAN
    "bren",         // 24 - DODC_BREN
    "piat"          // 25 - DODC_PIAT
};

// Grenade counts per class (loaded from INI)
// -1 means use game default (don't modify)
new g_iGrenadeCount[26] = { -1, ... };

// Spawn delay before setting grenades (seconds)
#define SPAWN_DELAY 0.5

// Config file path
new g_szConfigPath[256];

// Cvar for enable/disable
new g_pcvarEnabled;

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    // Cvar to enable/disable the plugin
    g_pcvarEnabled = register_cvar("ktp_grenade_loadout", "1");

    // Build config path
    get_configsdir(g_szConfigPath, charsmax(g_szConfigPath));
    format(g_szConfigPath, charsmax(g_szConfigPath), "%s/grenade_loadout.ini", g_szConfigPath);

    // Load config
    load_config();

    // Note: dod_client_spawn forward is automatically available from DODX
    // No need to register anything - just implement the public function
}

public plugin_cfg() {
    // Reload config after server.cfg runs (in case of late changes)
    load_config();
}

// Forward: Player spawn (from DODX)
public dod_client_spawn(id) {
    if (!get_pcvar_num(g_pcvarEnabled))
        return;

    if (!is_user_alive(id))
        return;

    // Delay to let game apply default loadout first
    set_task(SPAWN_DELAY, "task_set_grenades", id);
}

public task_set_grenades(id) {
    if (!is_user_alive(id))
        return;

    new class = dod_get_user_class(id);
    if (class < 1 || class > 25)
        return;

    new grenadeCount = g_iGrenadeCount[class];

    // -1 means don't modify (use game default)
    if (grenadeCount < 0)
        return;

    new team = get_user_team(id);

    // Determine which grenade type based on team
    new grenadeType;
    if (team == AXIS) {
        grenadeType = DODW_STICKGRENADE;
    } else if (class >= 21 && class <= 25) {
        grenadeType = DODW_MILLS_BOMB;
    } else {
        grenadeType = DODW_HANDGRENADE;
    }

    // Get current count before setting
    new currentCount = dodx_get_grenade_ammo(id, grenadeType);

    // For classes without default grenades, give weapon first
    if (currentCount == 0 && grenadeCount > 0) {
        dodx_give_grenade(id, grenadeType);
    }

    // Set the grenade count
    dodx_set_grenade_ammo(id, grenadeType, grenadeCount);

    // Get new count after setting
    new newCount = dodx_get_grenade_ammo(id, grenadeType);

    // Send AmmoX message to update client HUD
    new ammoSlot = (grenadeType == DODW_STICKGRENADE) ? AMMOSLOT_STICKGRENADE : AMMOSLOT_HANDGRENADE;
    dodx_send_ammox(id, ammoSlot, grenadeCount);

    log_amx("[KTPGrenadeLoadout] Player %d: class=%d config=%d before=%d after=%d",
        id, class, grenadeCount, currentCount, newCount);
}

load_config() {
    // Reset all to -1 (don't modify)
    for (new i = 0; i < sizeof(g_iGrenadeCount); i++) {
        g_iGrenadeCount[i] = -1;
    }

    if (!file_exists(g_szConfigPath)) {
        log_amx("[KTPGrenadeLoadout] Config file not found: %s", g_szConfigPath);
        log_amx("[KTPGrenadeLoadout] Using game default grenade counts");
        return;
    }

    new file = fopen(g_szConfigPath, "r");
    if (!file) {
        log_amx("[KTPGrenadeLoadout] Failed to open config: %s", g_szConfigPath);
        return;
    }

    new line[128], key[32], value[16];
    new section[16];
    new classId, count, loaded = 0;

    while (fgets(file, line, charsmax(line))) {
        trim(line);

        // Skip empty lines and comments
        if (line[0] == '^0' || line[0] == ';' || line[0] == '#' || (line[0] == '/' && line[1] == '/'))
            continue;

        // Check for section header
        if (line[0] == '[') {
            // Extract section name
            new end = contain(line, "]");
            if (end > 1) {
                copy(section, end, line[1]);
                strtolower(section);
            }
            continue;
        }

        // Parse key=value
        new eq = contain(line, "=");
        if (eq < 1)
            continue;

        copy(key, eq, line);
        copy(value, charsmax(value), line[eq + 1]);
        trim(key);
        trim(value);
        strtolower(key);

        // Find matching class
        classId = find_class_by_name(key);
        if (classId < 1) {
            log_amx("[KTPGrenadeLoadout] Unknown class '%s' in config", key);
            continue;
        }

        // Parse count
        count = str_to_num(value);
        if (count < 0) count = 0;
        if (count > 10) count = 10;

        g_iGrenadeCount[classId] = count;
        loaded++;
    }

    fclose(file);
    log_amx("[KTPGrenadeLoadout] Loaded %d class grenade settings from config", loaded);
}

find_class_by_name(const name[]) {
    for (new i = 1; i < sizeof(g_szClassNames); i++) {
        if (equal(name, g_szClassNames[i])) {
            return i;
        }
    }
    return 0;
}

// Admin command to reload config
public plugin_natives() {
    // No custom natives needed
}

public client_putinserver(id) {
    // Skip bots and HLTV
    if (is_user_bot(id) || is_user_hltv(id))
        return;

    // Delayed version announcement
    set_task(5.0, "task_version_display", id);
}

public task_version_display(id) {
    if (!is_user_connected(id))
        return;

    client_print(id, print_chat, "%s version %s by %s", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
}
