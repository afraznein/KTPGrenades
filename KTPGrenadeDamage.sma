// vim: set ts=4 sw=4 tw=99 noet:
//
// KTPGrenadeDamage - Grenade damage reduction plugin for Day of Defeat
// Copyright (C) 2026 KTP Team
//
// This plugin reduces grenade damage by a configurable percentage.
// Uses the dod_damage_pre forward from DODX module.
//

#include <amxmodx>
#include <dodx>
#include <dodconst>
#include <ktp_version_reporter>

#define PLUGIN_NAME    "KTP Grenade Damage"
#define PLUGIN_VERSION "1.0.5"
#define PLUGIN_AUTHOR  "Nein_"

// Cvar pointers
new g_pCvarEnabled;
new g_pCvarReduction;

// Cached reduction value (avoid cvar read on every damage event)
new Float:g_fCachedReduction = 50.0;

// Grenade weapon IDs (from dodconst.inc)
// DODW_HANDGRENADE = 13
// DODW_STICKGRENADE = 14
// DODW_STICKGRENADE_EX = 15
// DODW_HANDGRENADE_EX = 16
// DODW_MILLS_BOMB = 36

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	KTP_RegisterVersion(PLUGIN_NAME, PLUGIN_VERSION);

	// Cvars
	g_pCvarEnabled = register_cvar("ktp_grenade_dmg", "1");           // 0 = disabled, 1 = enabled
	g_pCvarReduction = register_cvar("ktp_grenade_dmg_reduce", "50"); // Reduction percentage (0-100)

}

public plugin_cfg()
{
	// Cache reduction value after cvars are loaded from config
	cache_reduction();
}

stock cache_reduction()
{
	g_fCachedReduction = get_pcvar_float(g_pCvarReduction);
	if (g_fCachedReduction < 0.0) g_fCachedReduction = 0.0;
	else if (g_fCachedReduction > 100.0) g_fCachedReduction = 100.0;
}

/**
 * Pre-damage forward - called before damage is finalized.
 * Return the modified damage value.
 */
public dod_damage_pre(attacker, victim, damage, wpnindex, hitplace, TA)
{
	// Check if plugin is enabled
	if (!get_pcvar_num(g_pCvarEnabled))
		return damage;

	// Don't reduce team damage (friendly fire)
	if (TA)
		return damage;

	// Check if this is grenade damage
	if (!is_grenade_weapon(wpnindex))
		return damage;

	// Use cached reduction value (updated at plugin_cfg, avoidscvar read per damage event)
	// RCON changes require map change to take effect — acceptable for a rarely-changed setting
	new Float:multiplier = (100.0 - g_fCachedReduction) / 100.0;
	new Float:newDamage = float(damage) * multiplier;

	// Round to nearest integer (0 is valid at 100% reduction)
	new reducedDamage = floatround(newDamage, floatround_round);
	if (reducedDamage < 0)
		reducedDamage = 0;

	return reducedDamage;
}

/**
 * Check if weapon ID is a grenade type.
 */
stock bool:is_grenade_weapon(wpnindex)
{
	switch (wpnindex)
	{
		case DODW_HANDGRENADE,
		     DODW_STICKGRENADE,
		     DODW_STICKGRENADE_EX,
		     DODW_HANDGRENADE_EX,
		     DODW_MILLS_BOMB:
		{
			return true;
		}
	}
	return false;
}
