# Integration Test Mod Pack Coverage

File: `integration_test_mod_pack.json`

Purpose: exercise as many modding code paths as possible in one toggleable pack.

## Coverage Matrix

1. Status add:
- Adds `reconstitution_it`.
- Tests authored status reconstruction, intensify stacking, stack caps, and status-id references.

2. Item add:
- Adds `tower_shield_it` (new id).
- Tests new content creation, reference usage by loadouts, and finite three-turn battle-start `Apply Status`.
- Adds `resolver_vocabulary_it` to validate JSON temporary modifiers and specific-status removal.
- Adds `formula_counter_probe_it` to validate counter modification, counter-threshold conditions, multi-stack application fields, and formula scaling reconstruction.
- Covers `attack_count` and opt-in `repeat_within_event_chain` reconstruction.

3. Item override:
- Overrides existing `glass_focus`.
- Tests id-based patching of existing base content.

4. Job add:
- Adds `warden_it`.
- Tests new job creation, loadout linkage, a five-turn status-applying skill, and the `Forecast` passive capability.
- Adds `cleanser_it` to validate an `Effects Only` skill with deterministic ailment removal.
- `cleanser_it` also validates passive status and damage-request interception, an effect-only stack-gated reaction, formula-driven healing/consumption, and a status-aware default tactic.

5. Job override:
- Overrides existing `apprentice`.
- Tests updated job modifiers/effect behavior in existing units.

6. Tactic add:
- Adds `guard_then_attack_it` and `foretell_heal_it`.
- Adds `attack_slow_target_it`.
- Tests custom tactic id flow, speed-aware targeting conditions, normal condition/target, and `foretell_enabled` reconstruction.

7. Tactic override:
- Overrides existing `attack_frontmost`.
- Tests patch behavior for base tactic ids.

8. Loadout add:
- Adds `warden_anchor_it`.
- Tests references to added job/item and base item/tactic ids.

9. Loadout override:
- Overrides existing `scout_support_boots`.
- Tests existing unit behavior shift through loadout patching.

10. Unit add:
- Adds `borin_anchor_it`.
- Tests new unit creation and roster placement.

11. Unit override:
- Overrides existing `mira_scout` with `action_interval = 70`.
- Tests extreme stat patch and visible runtime impact.

12. Demo roster override:
- Replaces roster order and includes newly added unit id.
- Tests roster replacement behavior and reference validation.

## Expected Observable Signals

- Setup pane shows:
  - `Borin Anchor IT` in Allies roster.
  - `Mira Scout (IT Override)` with interval `70`.
  - Loadout names ending with `(IT Override)` where patched.
  - `Tower Shield IT` and `Glass Focus (IT Override)` in gear summaries.
  - `Borin Anchor IT` gains the `Reconstitution IT` boon for three owner turns at battle start.

- Replay behavior:
  - Mira should act dramatically later because of interval `70`.
  - Added/overridden tactics should appear in tactic selection lines.
  - Added battle-start armor trigger should appear in item trigger lines.
  - After Borin takes damage and reaches another turn, Reconstitution should restore half of the damage received since Borin's previous turn.

## Activation Steps

1. Open Mods dropdown in the combat scene.
2. Enable `Integration Test Mod Pack [ref]`.
3. Optionally disable other packs for isolation.
4. Start a scenario or the Phase 7 debug run, then click `Run Fight`.

## Failure Clues

- If pack appears in menu but has no effect, inspect loader path filtering.
- If scene fails to load, inspect enum/reference assertions in `json_content_loader.gd`.
- If only some changes apply, inspect id collisions and patch merge keys.
