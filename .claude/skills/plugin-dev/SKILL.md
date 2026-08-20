---
name: plugin-dev
description: Use BEFORE writing or modifying any code in KTPGrenades (KTPGrenadeLoadout or KTPGrenadeDamage) — two-plugin repo layout, dodx native return-value discipline, weapon-ID constant conventions, and the compile/review/stage/verify workflow. Also use when planning a change, to know which invariants it touches.
---

# KTPGrenades Development

This repo ships two separate plugins onto a production fleet (24 instances):
**KTPGrenadeLoadout** (per-class grenade counts from an INI) and
**KTPGrenadeDamage** (grenade damage reduction). They compile, version, and
change independently — treat them as siblings, not one plugin.

## Hard safety rules
- **NEVER restart game servers** or issue LinuxGSM control commands without the
  operator's explicit permission in the current conversation.
- Deploys are staged as `KTPGrenadeLoadout.amxx.new` / `KTPGrenadeDamage.amxx.new`
  in each instance's plugins dir and swap at the 03:00 ET nightly restart. Never
  hot-swap the live `.amxx`.
- Run the `ktp-code-review` agent on any nontrivial change BEFORE compiling for deploy.
- **Never switch `ktp_grenade_loadout` off in response to `ret=-1` log volume.**
  Those lines do not establish that the give failed (see below), and disabling the
  plugin silently reverts every class to the game's default grenade count — a real
  gameplay change, made across an entire host, on the strength of a log line that
  may be reporting nothing wrong.

## Two plugins, two compile scripts, two changelogs
- `compile_loadout.sh` builds `KTPGrenadeLoadout.sma` only.
  `compile_damage.sh` builds `KTPGrenadeDamage.sma` only. There is no combined
  `compile.sh` — don't invent one, and don't assume a change to one plugin
  requires touching the other's build.
- Changes to Loadout go in `CHANGELOG_Loadout.md`; changes to Damage go in
  `CHANGELOG_Damage.md`. Each plugin has its own `PLUGIN_VERSION` and bumps
  independently. `README.md` is shared and has a section per plugin — update
  only the section that changed.

## dodx native return values are load-bearing, not advisory
`dodx_give_grenade()` and `dodx_set_grenade_ammo()` are sibling natives with the
same internal failure guard (`!ingame || !pEdict || !pvPrivateData` in
`KTPAMXX/modules/dod/dodx/NBase.cpp`) — both can silently no-op. `is_user_alive(id)`
checked right before the call narrows the race window but does not close it.
- **Always capture and check the return value.** On failure, log a line naming
  player/class/weapon-type/count (match the pattern already used for
  `dodx_give_grenade` in Loadout) — the native itself does not log.
- If a write fails, don't let anything downstream advertise a count the server
  never actually set — skip it, or bail as `set_player_grenades` does.
- **Do not send AmmoX by hand.** 1.0.12 removed the last `dodx_send_ammox` call:
  DODX 2.7.29 stopped writing `m_rgAmmoLast`, so the DLL's own `SendAmmoUpdate`
  diffs the pair each frame and emits for the slot it actually wrote. A plugin
  message is a second, unsynchronised writer of the same client counter.
- `dodx_get_grenade_ammo` returns **-1**, not 0, on failure since 2.7.29 — test a
  count with `<= 0` if an unreadable one must take the same path as an empty one.
- Before adding any new dodx setter-native call in either plugin, check whether
  its return value can indicate failure and wire up the same log-on-failure
  pattern — this class of bug generalizes to any dodx setter, not just grenades.

## `dodx_give_grenade`'s `-1` is UNRESOLVED — the convention is provisional
`CHANGELOG_Loadout.md` and the call-site comment both read `-1` as "pickup
refused, entity removed". That is a working convention, not a decoded return
value, and it should keep saying so. The native infers success from whether the
weapon entity's `solid` field changed across `pfnTouch`, and that single signal
cannot separate a refused pickup from a give that succeeded by transferring ammo
into a slot the player already held. Settling it needs a DODX change — test
possession before creating the entity, return a distinct code — so nothing done
in this repo will resolve it. Don't let a tidying pass promote the convention to
a documented meaning, and don't harden a check around it.

- **Loadout is the origin of every `ret=-1` line the fleet produces.** It is the
  only call site in the stack that logs on `!= 1`; the sibling plugins log only
  on `0`. That corpus has already been misattributed to KTPPracticeMode, which
  inverted its meaning and got a fix rejected in review — name the plugin before
  reasoning from the volume, and expect the volume to track player count rather
  than any host or config.
- **The `currentCount <= 0` gate is what makes those lines evidence.** Because the
  give only fires when the player's count reads empty or unreadable, "the player
  already holds one" is impossible at this site, which is what makes its `-1`s
  unambiguous — and therefore the strongest argument *against* reading `-1` as
  benign. Widening or removing that gate destroys the evidentiary value of the log
  without touching a line of logging code. If you rework the give path, keep the
  gate or say plainly what replaced it.
- **`dodx.ini`'s `pdata_offset` is excluded as a cause — don't re-test it.** The
  give native reads no pdata offsets; only `dodx_strip_grenade` does. The
  hypothesis also has a live counter-example: a host carrying an explicit offset
  override logged the same failures in quantity. Offsets are the obvious first
  guess on meeting this log line, which is exactly why the exclusion is written
  down.

## Weapon-ID constants: use dodconst.inc, don't shadow it
`dodconst.inc` (already included by both plugins) declares `DODW_HANDGRENADE`,
`DODW_STICKGRENADE`, `DODW_MILLS_BOMB`, etc. as enum members. **KTPGrenadeDamage
uses these enum symbols directly — that's the canonical pattern.** Do not
locally `#define` a weapon ID as a raw integer literal that duplicates an enum
value already in scope: it compiles fine today but silently diverges with no
compiler error if the upstream enum is ever reordered or gains an insertion.
If you touch weapon-ID handling in Loadout, prefer converging on the
`dodconst.inc` enum over adding another local `#define`.

## Ini validation (Loadout)
Config values in `data/grenade_loadout.ini` must be validated as integers
before use — a non-numeric or malformed value must be rejected with a log
naming the key/value (not silently coerced to 0 via `str_to_num`), and the
class should keep the game default on rejection. This is 1.0.9+ behavior;
preserve it in any parser rework.

## Never run a destructive simulation inside the working tree
Verifying a fix often means simulating the failure — writing a fake `build.sh`, a
fake artifact, a fake staging dir. Do it in a **verified** scratch dir, never in
the repo:

```bash
T="$(mktemp -d)" || exit 1
[ -n "$T" ] && [ -d "$T" ] || exit 1   # verify BEFORE you cd — this is the whole rule
cd "$T" || exit 1
```

`cd "$T"` with an empty `$T` **silently succeeds and leaves you where you were** —
in the repo. A simulation that then writes `build.sh` overwrites the real one. On
2026-07-16 exactly that truncated a tracked 60-line upstream file to 2 lines and
dropped a junk `.so` into `build/`, where a `find | head -1` could have staged it.
It was caught only because `git status` showed a modification nobody made.

So: verify the scratch dir before `cd`, and **run `git status` after any test that
touches the filesystem** — an unexpected change is the tell. Prefer copying inputs
out to the scratch dir over running tools "in place".

## Workflow
1. **Version bump** (per plugin, every shipped change): `#define PLUGIN_VERSION`
   in the changed plugin's `.sma`, new section in that plugin's `CHANGELOG_*.md`,
   and the matching section of the shared `README.md`.
2. **Compile**:
   - Loadout: `wsl bash -c "cd '/mnt/n/Nein_/KTP Git Projects/KTPGrenades' && bash compile_loadout.sh"`
   - Damage: `wsl bash -c "cd '/mnt/n/Nein_/KTP Git Projects/KTPGrenades' && bash compile_damage.sh"`
   - Both output to `compiled/` and auto-stage to the KTP DoD Server test tree.
3. **Review**: `ktp-code-review` agent before any fleet stage.
4. **Fleet stage**: deploy as `.new` via paramiko (see root CLAUDE.md § SSH);
   verify staged md5 on all 24 active instances.
5. **Post-activation verify** (after the nightly): 24/24 on the new md5, no
   leftover `.new`, and check `/tmp` for cores — `find /tmp -maxdepth 1 -name
   'core.*' -mtime -1` on every host. A game-tree core search proves nothing
   (matches only core.so/core.ini/core.wav, never the actual crash dump).

## Comment conventions
Short, explain *why* not *what*, no ticket/finding IDs, never delete a tripwire
fact while editing nearby code.
