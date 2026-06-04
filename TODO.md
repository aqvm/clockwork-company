# TODO

This is the living backlog for planned-but-not-done work. Keep it practical: add items when a decision or deferred task appears, remove or revise items when they are completed or deliberately abandoned, and keep deeper design rationale in `DESIGN_NOTES.md`.

## Near-Term UI and UX

- Continue replacing the prototype scenario workbench layout with cleaner dedicated UI panels/components. The planning workbench row and run-flow controls now live in focused UI components; next good extraction candidate is tooltip hosting if nested traversal makes it grow.
- Split remaining `combat_test_scene.gd` responsibilities into focused Control scenes/scripts for any future tooltip host UI or smaller replay subpanels. The scenario list, scenario detail, party list, unit detail, unit action, and combat replay panels have been extracted.
- Move stable UI layout into `.tscn` component scenes while keeping truly data-driven rows/lists dynamic. The planning workbench row and top control row now have component ownership; keep moving only stable layout, not generated rows.
- Keep using custom panel signals for extracted UI components. `scenario_selected`, `unit_selected`, `planning_item_requested`, `equip_option_requested`, and run-flow request signals are now used by extracted panels.

## Tooltips

- Add tooltip support for status effects once statuses exist.

## Scenario and Campaign

- Add more scenario rule resolvers only when a scenario needs them. `iron_tollgate_armored_enemies` is the first mechanical rule and gives enemies +2 armor.
- Make scenario rewards and content unlocks mechanically change later options after the campaign progression model is broader. Current UI shows scenario unlock state and content unlock state, but content IDs are still informational.
- Add campaign save/load for active roster state after roster persistence is designed. Completed scenarios, unlocked scenario IDs, unlocked content IDs, campaign completion, and campaign ID/version validation now save/load as small JSON.
- Add persistent roster/job/gear integration across scenarios.
- Decide how roster/job/gear state moves from one scenario to the next.
- Add optional mastery goals later, if they help create rotation pressure without punishment systems.

## Combat and Rules

- Add status effects when a focused scenario or item design actually needs them.
- Consider collapsible structured combat log groups instead of plain indented text.

## Replay and Presentation

- Keep moving visual replay toward structured simulator snapshots where richer visuals need more state. The replay now consumes simulator-authored unit snapshots after battle start and each root event, while structured events still drive text grouping and lightweight effects.
- Add richer replay visuals only when they clarify combat:
  - portraits
  - statuses
  - cast bars
- Keep `CombatLogRichTextFormatter` shared between setup/status text and replay text if highlighting rules change.

## Units, Jobs, Progression, and Roster

- Replace loadout-level ability overrides with real learned ability unlock/equip rules when progression UI exists.
- Implement player choice for `pending_unlock_choice`.
- Add persistent unit careers across scenarios.
- Decide how roster rotation pressure should work through XP caps, scenario constraints, enemy mechanics, unlocks, and mastery goals.

## Gear, Items, and Inventory

- Build a real inventory model instead of the current simple between-fight item list.
- Expand item effects only through declarative `EffectDefinition` data unless a focused mechanics pass requires new resolver code.
- Audit item catalog balance once more scenarios are playable.

## Content and Authoring

- Turn the broad content catalog into curated scenario-facing content. A first slice now adds existing catalog rewards to the authored scenarios; keep future curation small and scenario-specific.
- Add more handcrafted scenarios only when the framework and UI can make them understandable.
- Keep enemies as normal unit/loadout/job/item/tactic builds, not a separate monster-only ruleset.
- Use tags for filtering/conditions/content tools when an actual tool or rule needs them.
- Keep JSON sidecar docs next to every JSON content/modding file. `tools/check_content.ps1` now validates that discovered JSON packs have adjacent `*.options.md` files.

## Modding and Data Pipeline

- Keep `.tres` Resources and JSON mod packs equivalent where practical.
- Update sidecar `*.options.md` files whenever JSON schema, enums, keywords, or reference rules change; the content check enforces sidecar presence, not prose completeness.
- Decide whether base `.tres` content should eventually be exported to reference JSON automatically.

## Save/Load and Persistence

- Add broader campaign save/load only after the campaign state shape is stable.
- Persisted unlocked/completed scenarios now exist as the first save slice; add roster persistence separately.
- Persist roster/job/gear state after the roster model is clear.
- Keep save data small and inspectable while the project is still learning-first.

## Later / Not Soon

- Async multiplayer snapshots / ghost mode.
- Enemy doctrine analysis and adaptive enemy behavior.
- Procedural generation.
- Procedural items.
- Large content sets.
- Complex economy.
- Base-building.
- Injury/fatigue/rest/calendar systems.
- Polish-heavy animation/audio passes.

## Cleanup Watchlist

- Fully remove or replace obsolete combat-test harness concepts as the scenario workbench matures. The old Phase 7/loss-test controls now live behind a Debug toggle.
- Watch for duplicated UI logic in `combat_test_scene.gd`; extract components only when duplication becomes painful.
- Keep `GODOT_BEST_PRACTICES_AUDIT.md` current when a documented practice is adopted, rejected, or substantially reconsidered.
- Keep `RunState` scenario-backed and old debug-run paths both working until the debug run is intentionally retired.
- Avoid adding more one-off strings for Resources now that `ResourceTooltipBuilder` exists.
- Keep `TODO.md`, `ROADMAP.md`, `DESIGN_NOTES.md`, `ARCHITECTURE.md`, and `LEARNING_LOG.md` synchronized when plans change.
