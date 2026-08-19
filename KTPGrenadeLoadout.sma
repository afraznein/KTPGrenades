/* KTP Grenade Loadout v1.0.12
 * Customizable grenade loadouts per class via INI config
 *
 * AUTHOR: Nein_
 * VERSION: 1.0.12
 * DATE: 2026-08-15
 *
 * ========== FEATURES ==========
 * - Configure grenade counts per class via INI file
 * - Supports all DoD classes (US, German, British)
 * - Sets grenades on spawn with configurable delay
 * - Works in extension mode (no Metamod required)
 *
 * ========== REQUIREMENTS ==========
 * - KTPAMXX 2.7.29+ with DODX module (grenade ammo natives, dodx_give_grenade).
 *   2.7.29 is a hard floor since 1.0.12: older DODX suppresses the DLL's own
 *   AmmoX, and this plugin no longer sends a replacement. Behaviour against an
 *   older module is UNDEFINED, not merely degraded -- 2.7.27 also addresses
 *   m_rgAmmo one int low, so its ammo writes land on the wrong slot anyway.
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
 * v1.0.12 (2026-08-15) - Drop the manual AmmoX; the DLL emits its own
 *   * FIXED: the manual AmmoX was only ever needed because DODX wrote
 *     m_rgAmmoLast, which suppressed the DLL's own AmmoX -- SendAmmoUpdate
 *     diffs the pair every frame. DODX 2.7.29 stopped writing it, so the DLL
 *     now emits for the slot it actually wrote and the extra message is a
 *     second, unsynchronised writer of the same client counter.
 *   * The 9/11 constants themselves were RIGHT -- DoD precaches all weapons in
 *     a fixed order, so they are invariant, and 2.7.29 keeps them as its own
 *     fallback. Removing the message is about ownership, not a wrong constant.
 *   * ORDERING: must not ship before DODX 2.7.29 is live on the fleet.
 *
 * v1.0.11 (2026-08-09) - Use the dodconst.inc weapon enum, drop the local copies
 *   * CLEANUP: the local DODW_HANDGRENADE/STICKGRENADE/MILLS_BOMB defines
 *     shadowed the dodconst.inc enum already in scope. Same values today, but a
 *     literal copy diverges silently if the upstream enum ever shifts.
 *     KTPGrenadeDamage already uses the enum directly. No behaviour change.
 *
 * v1.0.10 (2026-08-09) - dodx_set_grenade_ammo return value
 *   * FIXED: return was ignored -- the same defect 1.0.9 fixed for
 *     dodx_give_grenade, one line below it. A 0 return means the ammo never
 *     landed, so the dodx_send_ammox that followed advertised a HUD count the
 *     player does not have.
 *
 * v1.0.9 (2026-07-08) - Config Validation + Native Failure Logging
 *   * FIXED: dodx_give_grenade return was ignored — 0 (entity/spawn failure)
 *            and -1 (pickup refused, entity removed) now log a failure line
 *   * FIXED: Non-numeric INI value parsed to 0 = silent grenade strip;
 *            values are now validated, bad entries rejected with a log
 *
 * v1.0.8 (2026-04-25) - Version Reporting
 *   + ADDED: ktp_version_reporter include (amx_ktp_versions rcon reporting)
 *   + ADDED: compile_loadout.sh bakes git SHA + build time into the .amxx
 *   * FIXED: compile_loadout.sh temp-dir nesting on re-runs
 *
 * v1.0.7 (2026-03-24) - Cleanup
 *   * CHANGED: Version broadcast to players removed (chat noise / info leak)
 *   * CHANGED: Dead INI section parsing removed (class names are globally unique)
 *   * CHANGED: find_class_by_name skips empty entries (unused mortar slots)
 *
 * v1.0.6 (2026-03-13) - Bug Fixes + Safety
 *   * FIXED: g_bTaskScheduled not reset on map change (permanent deadlock after map change during task)
 *   * FIXED: Section parser copied trailing ']' into section name
 *   * FIXED: set_task used raw player ID as task ID (collision risk)
 *   * FIXED: INI key copy not clamped to buffer size (overflow with key > 31 chars)
 *   * CHANGED: Version announcement restricted to admins only
 *   + ADDED: client_disconnected cleanup for version task
 *   + ADDED: plugin_end() to flush pending queue on map change
 *
 * v1.0.5 (2026-02-05) - Performance Optimization
 *   * FIXED: Removed per-spawn log_amx() call that caused 196ms+ spikes on mass spawns
 *   * FIXED: Removed redundant dodx_get_grenade_ammo() verification call
 *   * ADDED: Debug cvar ktp_grenade_loadout_debug for optional verbose logging
 *   * CHANGED: Batched spawn processing - single task handles all pending spawns
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
#include <ktp_version_reporter>

#define PLUGIN_NAME    "KTP Grenade Loadout"
#define PLUGIN_VERSION "1.0.12"
#define PLUGIN_AUTHOR  "Nein_"

// Task IDs
#define TASK_BATCH_SPAWN     7033

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
new g_pcvarDebug;

// Batched spawn processing - queue of players needing grenade setup
new g_iPendingSpawns[33];  // Player IDs waiting for grenade setup
new g_iPendingCount = 0;   // Number of players in queue
new bool:g_bTaskScheduled = false;  // Is batch task already scheduled?
new bool:g_bDebug = false;  // Cached debug flag

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    KTP_RegisterVersion(PLUGIN_NAME, PLUGIN_VERSION);

    // Cvar to enable/disable the plugin
    g_pcvarEnabled = register_cvar("ktp_grenade_loadout", "1");

    // Debug cvar - enables verbose per-spawn logging (WARNING: causes disk I/O)
    g_pcvarDebug = register_cvar("ktp_grenade_loadout_debug", "0");

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

public plugin_end() {
    // Reset batch state on map change to prevent g_bTaskScheduled deadlock
    g_bTaskScheduled = false;
    g_iPendingCount = 0;
}

// Forward: Player spawn (from DODX)
// Uses batched processing to avoid 12 separate tasks on round start
public dod_client_spawn(id) {
    if (!get_pcvar_num(g_pcvarEnabled))
        return;

    if (!is_user_alive(id))
        return;

    // Add to pending queue (avoid duplicates)
    for (new i = 0; i < g_iPendingCount; i++) {
        if (g_iPendingSpawns[i] == id)
            return;  // Already queued
    }

    if (g_iPendingCount < sizeof(g_iPendingSpawns)) {
        g_iPendingSpawns[g_iPendingCount++] = id;
    }

    // Schedule batch task if not already scheduled
    if (!g_bTaskScheduled) {
        g_bTaskScheduled = true;
        set_task(SPAWN_DELAY, "task_process_spawns", TASK_BATCH_SPAWN);
    }
}

// Batched spawn processing - handles all queued players in one task
public task_process_spawns(taskid) {
    g_bTaskScheduled = false;
    g_bDebug = bool:get_pcvar_num(g_pcvarDebug);

    new processed = 0;

    // Process all queued players
    for (new i = 0; i < g_iPendingCount; i++) {
        new id = g_iPendingSpawns[i];
        if (set_player_grenades(id)) {
            processed++;
        }
    }

    // Clear the queue
    g_iPendingCount = 0;

    // Only log summary if debug enabled or something was processed
    if (g_bDebug && processed > 0) {
        log_amx("[KTPGrenadeLoadout] Batch processed %d players", processed);
    }
}

// Set grenades for a single player - returns true if modified
set_player_grenades(id) {
    if (!is_user_alive(id))
        return false;

    new class = dod_get_user_class(id);
    if (class < 1 || class > 25)
        return false;

    new grenadeCount = g_iGrenadeCount[class];

    // -1 means don't modify (use game default)
    if (grenadeCount < 0)
        return false;

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

    // Get current count to check if we need to give weapon
    new currentCount = dodx_get_grenade_ammo(id, grenadeType);

    // For classes without default grenades, give weapon first. <= 0 because
    // 2.7.29 changed the getter's failure return from 0 to -1, and an
    // unreadable count must still take the give path rather than skip it.
    if (currentCount <= 0 && grenadeCount > 0) {
        // 0 = entity create/spawn failed or player died; -1 = pickup refused,
        // entity removed. Either way the ammo write below may land on a player
        // with no grenade weapon slot — log it, don't fail silently.
        new giveResult = dodx_give_grenade(id, grenadeType);
        if (giveResult != 1) {
            log_amx("[KTPGrenadeLoadout] dodx_give_grenade failed (ret=%d) player=%d class=%d type=%d",
                giveResult, id, class, grenadeType);
        }
    }

    // Same failure class as the give above: a 0 here means the ammo never landed,
    // so this player was not modified and must not be counted as one.
    if (!dodx_set_grenade_ammo(id, grenadeType, grenadeCount)) {
        log_amx("[KTPGrenadeLoadout] dodx_set_grenade_ammo failed player=%d class=%d type=%d count=%d",
            id, class, grenadeType, grenadeCount);
        return false;
    }

    // No manual AmmoX: dodx_set_grenade_ammo writes m_rgAmmo alone, so the DLL's
    // own SendAmmoUpdate diffs it against m_rgAmmoLast and emits the HUD update
    // for the slot it actually wrote. Requires DODX 2.7.29+.

    // Debug logging (expensive - only when explicitly enabled)
    if (g_bDebug) {
        log_amx("[KTPGrenadeLoadout] Player %d: class=%d config=%d before=%d",
            id, class, grenadeCount, currentCount);
    }

    return true;
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
    new classId, count, loaded = 0;

    while (fgets(file, line, charsmax(line))) {
        trim(line);

        // Skip empty lines, comments, and section headers
        // (sections like [allies]/[axis]/[british] are cosmetic — class names are globally unique)
        if (line[0] == '^0' || line[0] == ';' || line[0] == '#' || (line[0] == '/' && line[1] == '/') || line[0] == '[')
            continue;

        // Parse key=value
        new eq = contain(line, "=");
        if (eq < 1)
            continue;

        copy(key, min(eq, charsmax(key)), line);
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

        // Strip inline comment from the value ("garand = 1  ; Rifleman")
        strip_inline_comment(value);
        trim(value);

        // Validate before str_to_num — a non-numeric value parses to 0,
        // silently stripping the class's grenades. Keep the default instead.
        if (!is_valid_count(value)) {
            log_amx("[KTPGrenadeLoadout] Invalid count '%s' for class '%s' in config — entry ignored", value, key);
            continue;
        }

        // Parse count (-1 = use game default, 0-10 = override)
        count = str_to_num(value);
        if (count < -1) count = -1;
        if (count > 10) count = 10;

        g_iGrenadeCount[classId] = count;
        loaded++;
    }

    fclose(file);
    log_amx("[KTPGrenadeLoadout] Loaded %d class grenade settings from config", loaded);
}

// Truncate at the first ';', '#', or "//" so inline comments don't fail validation
strip_inline_comment(str[]) {
    for (new i = 0; str[i]; i++) {
        if (str[i] == ';' || str[i] == '#' || (str[i] == '/' && str[i + 1] == '/')) {
            str[i] = '^0';
            return;
        }
    }
}

// Strict integer check — str_to_num("abc") is 0, which would read as "strip grenades"
bool:is_valid_count(const str[]) {
    new i = 0;
    if (str[0] == '-')
        i = 1;
    if (!str[i])
        return false;
    for (; str[i]; i++) {
        if (!isdigit(str[i]))
            return false;
    }
    return true;
}

find_class_by_name(const name[]) {
    for (new i = 1; i < sizeof(g_szClassNames); i++) {
        // Skip empty entries (unused mortar class slots at indices 9, 20)
        if (g_szClassNames[i][0] == '^0')
            continue;
        if (equal(name, g_szClassNames[i]))
            return i;
    }
    return 0;
}

// Version broadcast removed — no need to leak plugin info to players
