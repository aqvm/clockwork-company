# Integration Test Mod Pack Coverage

File: `integration_test_mod_pack.json`

Purpose: exercise a small, self-contained slice of the modding pipeline without referencing removed placeholder character content.

## Coverage Matrix

1. Status add:
- Adds `reconstitution_it`.
- Tests authored status reconstruction, intensify stacking, stack caps, and status-id references.

2. Job add:
- Adds `cleanser_it`.
- Tests new job creation, loadout linkage, a status-applying skill, and the `Forecast` passive capability.

3. Loadout add:
- Adds `cleanser_it_loadout`.
- Tests references to a newly added job id.

4. Unit add:
- Adds `cleanser_it_unit`.
- Tests new unit creation and roster placement.

5. Demo roster override:
- Replaces roster order and includes newly added unit id.
- Tests roster replacement behavior and reference validation.

## Expected Observable Signals

- Setup pane shows:
  - `Cleanser IT Unit` in Allies roster when the pack is enabled.
  - `Cleanser IT Loadout` assigned to that unit.
  - `Cleanser IT Reconstitution` available as the current-job skill.

- Replay behavior:
  - The added unit should participate without missing id or enum assertions.
  - Reconstitution IT should resolve when the added job skill targets an injured ally.

## Activation Steps

1. Open Mods dropdown in the combat scene.
2. Enable `Integration Test Mod Pack [ref]`.
3. Optionally disable other packs for isolation.
4. Start a scenario or debug run, then click `Run Fight`.

## Failure Clues

- If pack appears in menu but has no effect, inspect loader path filtering.
- If scene fails to load, inspect enum/reference assertions in `json_content_loader.gd`.
- If only some changes apply, inspect id collisions and patch merge keys.
