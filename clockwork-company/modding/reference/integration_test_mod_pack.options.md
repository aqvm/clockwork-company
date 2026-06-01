# Integration Test Mod Pack Coverage

File: `integration_test_mod_pack.json`

Purpose: exercise as many modding code paths as possible in one toggleable pack.

## Coverage Matrix

1. Item add:
- Adds `tower_shield_it` (new id).
- Tests new content creation and reference usage by loadouts.

2. Item override:
- Overrides existing `glass_focus`.
- Tests id-based patching of existing base content.

3. Job add:
- Adds `warden_it`.
- Tests new job creation and loadout linkage.

4. Job override:
- Overrides existing `apprentice`.
- Tests updated job modifiers/effect behavior in existing units.

5. Tactic add:
- Adds `guard_then_attack_it`.
- Tests custom tactic id flow into loadouts and combat logs.

6. Tactic override:
- Overrides existing `attack_frontmost`.
- Tests patch behavior for base tactic ids.

7. Loadout add:
- Adds `warden_anchor_it`.
- Tests references to added job/item and base item/tactic ids.

8. Loadout override:
- Overrides existing `scout_support_boots`.
- Tests existing unit behavior shift through loadout patching.

9. Unit add:
- Adds `borin_anchor_it`.
- Tests new unit creation and roster placement.

10. Unit override:
- Overrides existing `mira_scout` with `action_interval = 70`.
- Tests extreme stat patch and visible runtime impact.

11. Demo roster override:
- Replaces roster order and includes newly added unit id.
- Tests roster replacement behavior and reference validation.

## Expected Observable Signals

- Setup pane shows:
  - `Borin Anchor IT` in Allies roster.
  - `Mira Scout (IT Override)` with interval `70`.
  - Loadout names ending with `(IT Override)` where patched.
  - `Tower Shield IT` and `Glass Focus (IT Override)` in gear summaries.

- Replay behavior:
  - Mira should act dramatically later because of interval `70`.
  - Added/overridden tactics should appear in tactic selection lines.
  - Added battle-start armor trigger should appear in item trigger lines.

## Activation Steps

1. Open Mods dropdown in the combat scene.
2. Enable `Integration Test Mod Pack [ref]`.
3. Optionally disable other packs for isolation.
4. Click `Run Jobs 3v3 Fight`.

## Failure Clues

- If pack appears in menu but has no effect, inspect loader path filtering.
- If scene fails to load, inspect enum/reference assertions in `json_content_loader.gd`.
- If only some changes apply, inspect id collisions and patch merge keys.
