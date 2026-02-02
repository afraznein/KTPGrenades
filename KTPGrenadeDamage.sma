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

#define PLUGIN_NAME    "KTP Grenade Damage"
#define PLUGIN_VERSION "1.0.2"
#define PLUGIN_AUTHOR  "Nein_"

// Cvar pointers
new g_pCvarEnabled;
new g_pCvarReduction;

// Grenade weapon IDs (from dodconst.inc)
// DODW_HANDGRENADE = 13
// DODW_STICKGRENADE = 14
// DODW_STICKGRENADE_EX = 15
// DODW_HANDGRENADE_EX = 16
// DODW_MILLS_BOMB = 36

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	// Cvars
	g_pCvarEnabled = register_cvar("ktp_grenade_dmg", "1");           // 0 = disabled, 1 = enabled
	g_pCvarReduction = register_cvar("ktp_grenade_dmg_reduce", "50"); // Reduction percentage (0-100)

	server_print("[KTP] %s v%s by %s enabled", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
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

	// Check if this is grenade damage
	if (!is_grenade_weapon(wpnindex))
		return damage;

	// Get reduction percentage
	new Float:reduction = get_pcvar_float(g_pCvarReduction);

	// Clamp to 0-100 range
	if (reduction < 0.0)
		reduction = 0.0;
	else if (reduction > 100.0)
		reduction = 100.0;

	// Calculate reduced damage
	// reduction = 50 means keep 50% of damage (reduce by 50%)
	new Float:multiplier = (100.0 - reduction) / 100.0;
	new Float:newDamage = float(damage) * multiplier;

	// Round to nearest integer, minimum 1 if any damage was done
	new reducedDamage = floatround(newDamage, floatround_round);
	if (reducedDamage < 1 && damage > 0)
		reducedDamage = 1;

	return reducedDamage;
}

/**
 * Check if weapon ID is a grenade type.
 */
bool:is_grenade_weapon(wpnindex)
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
