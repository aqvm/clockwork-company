# TODO

This is the living backlog for planned-but-not-done work. Keep it practical: add items when a decision or deferred task appears, remove or revise items when they are completed or deliberately abandoned, and keep deeper design rationale in `DESIGN_NOTES.md`.

## Near-Term UI and UX

- Continue replacing the prototype scenario workbench layout with cleaner dedicated UI panels/components.
- Split remaining `combat_test_scene.gd` responsibilities into focused Control scenes/scripts for any future tooltip host UI or smaller replay subpanels. The scenario list, scenario detail, party list, unit detail, unit action, and combat replay panels have been extracted.
- Move stable UI layout into `.tscn` component scenes while keeping truly data-driven rows/lists dynamic.
- Keep using custom panel signals for extracted UI components. `scenario_selected`, `unit_selected`, `cycle_equipment_requested`, and `equip_option_requested` are now used by extracted panels.
- Build a real inventory/equipment browser instead of cycle-buttons for equipment changes.
- Add a clearer combat start/encounter transition once a scenario has multiple fights.
- Decide whether the hidden old `Combat Conditions` pane should be fully deleted or replaced by a new fight-preview panel.

## Tooltips

- Add CK3-style locked tooltips that stay open when hovered intentionally.
- Add nested tooltip traversal from one Resource mention to another.
- Decide input behavior for locking/unlocking tooltips: hover delay, click, modifier key, or pinned mode.
- Add tooltip support for non-Resource glossary terms such as HP, armor, action interval, physical damage, magic damage, guard, and cooldown.
- Add tooltip support for combat log terms and structured event payloads.
- Add tooltip support for status effects once statuses exist.

## Scenario and Campaign

- Implement mechanical scenario rules instead of data-only placeholders.
- Make at least one scenario rule affect play and explain itself clearly.
- Make scenario rewards and content unlocks visibly change later options.
- Add campaign save/load for:
  - completed scenarios
  - unlocked scenario IDs
  - unlocked content IDs
  - active roster state
- Add persistent roster/job/gear integration across scenarios.
- Decide how roster/job/gear state moves from one scenario to the next.
- Decide how branching scenario trees should be represented once linear campaigns are not enough.
- Add optional mastery goals later, if they help create rotation pressure without punishment systems.

## Combat and Rules

- Add status effects when a focused scenario or item design actually needs them.
- Consider collapsible structured combat log groups instead of plain indented text.
- Add seeded randomness only after the deterministic core remains understandable.
- Keep magic damage ignoring armor unless a separate magic mitigation stat is deliberately introduced.

## Replay and Presentation

- Move visual replay toward structured simulator snapshots instead of reconstructing from log/event payloads where useful.
- Add richer replay visuals only when they clarify combat:
  - portraits
  - statuses
  - cast bars
  - cooldown shimmer
  - clearer defeat/readiness states
- Add accessibility/color options, including a color-blind-friendly palette.
- Decide whether keyword highlighting should remain whole-line or add phrase-level emphasis.
- Consider exposing background and highlight palette choices together.
- Keep replay presentation separate from combat simulation authority.
- Keep `CombatLogRichTextFormatter` shared between setup/status text and replay text if highlighting rules change.

## Units, Jobs, Progression, and Roster

- Replace loadout-level ability overrides with real learned ability unlock/equip rules when progression UI exists.
- Implement player choice for `pending_unlock_choice`.
- Decide whether job unlock dependencies should exist, and if so how small they can stay.
- Add persistent unit careers across scenarios.
- Decide whether equipment permissions should live only on jobs or also include unit/item-specific requirements.
- Decide whether tactics should live on unit, party, loadout, or encounter Resources long-term.
- Decide how roster rotation pressure should work through XP caps, scenario constraints, enemy mechanics, unlocks, and mastery goals.
- Avoid injury, fatigue, rest, base-building, calendars, and management-sim systems unless explicitly requested.

## Gear, Items, and Inventory

- Build a real inventory model instead of the current simple between-fight item list.
- Decide whether shields need a true offhand/handedness system or should remain bundled into weapon/armor concepts.
- Expand item effects only through declarative `EffectDefinition` data unless a focused mechanics pass requires new resolver code.
- Keep unsupported effect combinations obvious in logs/tooltips.
- Decide whether procedural items ever belong in the project; this is explicitly not soon.
- Audit item catalog balance once more scenarios are playable.

## Content and Authoring

- Turn the broad content catalog into curated scenario-facing content.
- Add more handcrafted scenarios only when the framework and UI can make them understandable.
- Keep enemies as normal unit/loadout/job/item/tactic builds, not a separate monster-only ruleset.
- Add scouting reports when enemy mechanics become more varied.
- Use tags for filtering/conditions/content tools when an actual tool or rule needs them.
- Keep JSON sidecar docs next to every JSON content/modding file.

## Modding and Data Pipeline

- Keep `.tres` Resources and JSON mod packs equivalent where practical.
- Update sidecar `*.options.md` files whenever JSON schema, enums, keywords, or reference rules change.
- Add better validation/errors for bad mod references and unsupported enum values.
- Decide whether base `.tres` content should eventually be exported to reference JSON automatically.
- Decide whether `project.godot` should eventually live at the repository root or remain nested.

## Save/Load and Persistence

- Add campaign save/load only after the campaign state shape is stable.
- Persist unlocked/completed scenarios before adding broader roster persistence.
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

- Fully remove or replace obsolete combat-test harness concepts as the scenario workbench matures.
- Watch for duplicated UI logic in `combat_test_scene.gd`; extract components only when duplication becomes painful.
- Keep `GODOT_BEST_PRACTICES_AUDIT.md` current when a documented practice is adopted, rejected, or substantially reconsidered.
- Keep `RunState` scenario-backed and old debug-run paths both working until the debug run is intentionally retired.
- Avoid adding more one-off strings for Resources now that `ResourceTooltipBuilder` exists.
- Keep `TODO.md`, `ROADMAP.md`, `DESIGN_NOTES.md`, `ARCHITECTURE.md`, and `LEARNING_LOG.md` synchronized when plans change.
