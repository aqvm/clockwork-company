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

- Revisit `iron_tollgate_armored_enemies`. It was useful as the first mechanical scenario rule, but "enemies have more armor" should usually be expressed through enemy builds/loadouts, not a scenario rule.
- Use scenario rules for broad scenario-wide modifiers such as weather, terrain, visibility, ritual pressure, or other global conditions that affect the battlefield rather than patching individual enemy stats.
- Build scenarios and encounters to test a specific mechanic, matchup question, or synergy pattern. If a fight is meant to test armor-breaking, author enemies with naturally high-armor builds instead of adding invisible armor from a rule.
- Scenario questions should not have one mandatory correct answer. Good enemy designs pose pressures that can be solved through several build routes, such as mitigation, burst damage, sustain, control, ramping damage, or targeting plans.
- Prefer self-synergistic encounter design. Enemy parties should demonstrate coherent combinations of jobs, gear, tactics, ancestry, items, and scenario context so losses teach the player what kinds of synergies are possible.
- Design scenario scouting around honest theming and mode-specific information. A first-time standalone scenario should reveal little beyond name/theme, while a campaign scenario should usually reveal enough about the first fight for planning.
- After a standalone scenario has been attempted, whether won or lost, allow exact encounter contents to be inspected for future attempts.
- Keep scenario themes dominant and consistent across encounters so campaign players can reasonably infer later fights from the scenario name, story framing, and first encounter.
- Use three encounters as the normal scenario length. Four or five encounters can appear occasionally for pacing texture, but should justify the longer commitment.
- Climactic campaign bosses can break normal length/party assumptions: either one huge expanded-roster fight, or an eight-to-ten-fight gauntlet for a smaller party that asks contradictory build questions.
- Use mini-bosses in some longer scenarios. A mini-boss should usually be an upgraded, overleveled, or overgeared normal unit with one memorable mechanic, not a separate monster-only ruleset.
- Revisit final boss design later. A campaign final boss needs enough scale, mechanics, and tension to support roughly nine developed units, but the exact approach needs its own design pass.
- Keep normal deployed party size at three units. Larger party sizes should be rare scenario-authored exceptions, not campaign progression upgrades.
- Allow voluntary under-deployment where practical, such as taking one or two units into a three-unit scenario, but tune scenarios around the authored maximum party size.
- Do not add campaign unlocks that increase party size. Extra party slots would become mandatory high-priority upgrades and make encounter tuning much harder.
- For now, finishing a campaign scenario should unlock the next authored scenario or scenarios for that campaign within the current run.
- Make scenario rewards and content unlocks mechanically change later options after the campaign progression model is broader. Current UI shows scenario unlock state and content unlock state, but content IDs are still informational.
- Scenario rewards should mostly be gear choices, because gear is the main between-scenario buildcraft lever.
- Recruit choices should appear less often, roughly every couple of scenarios when the campaign wants to widen the roster or introduce new build possibilities.
- A campaign roster can grow to roughly three full deployed parties by the end, around nine units. This supports rotation and finale payoff without diluting unit biography too much.
- Early campaign recruits should usually have an ancestry but otherwise be blank slates, giving the player room to shape their biography through jobs, gear, tactics, and scenario history.
- Late campaign recruits should be partially developed because there is not enough campaign time left to build everyone from scratch. They may arrive with job levels, unlocked skills, unusual passives/reactions, or other authored history hooks.
- Most campaign scenarios can stay limited to a small deployed party, currently three units, while a campaign finale can deliberately allow the entire roster so long-term roster development pays off.
- Future content unlocks should gate content complexity, not raw power. Good first targets are new recruit candidates, new item/reward types entering scenario reward pools, optional scenario branches, or more complex buildcraft concepts.
- Avoid using content unlock IDs to hide basic UI, core job rules, or strictly stronger upgrades unless a later design pass deliberately revises the unlock philosophy.
- Expand campaign save/load after the first roster-state slice. Completed scenarios, unlocked scenario IDs, unlocked content IDs, campaign completion, campaign roster units, job progress, loadout equipment, and campaign inventory now save/load as small JSON; active scenario attempts still do not.
- Keep hardening persistent roster/job/gear integration across scenarios in campaigns. Standalone practice scenarios should remain self-contained and should not write long-term roster state.
- Campaign runs should carry forward everything that contributes to unit biography: named unit identity, ancestry/body, current job, job progress, learned/equipped abilities, tactics/loadout choices, equipped gear, unequipped inventory, and scenario/content unlocks.
- Unit biography should eventually surface stats, jobs trained, job features unlocked, scars acquired, bosses defeated, notable scenario clears, tactics used, and other history that explains how the unit became who they are.
- Do not overemphasize gear in biography tracking because gear is intentionally swappable. Current equipment matters to builds, but long-term biography should focus more on persistent unit history.
- Add a profile-level mythos/legacy feature later that lets the player flag MVP units for preservation and later display outside the current campaign.
- Do not carry battle-only effects forward after a scenario. Current HP damage, temporary armor, statuses, and other combat runtime effects should reset unless a later explicit design pass adds long-term consequences.
- Lock roster, gear, tactics, jobs, and learned ability assignments for the duration of a scenario once it starts. The player can adjust them before starting or retrying a scenario, not between encounters inside that scenario.
- Between encounters inside a scenario, reset surviving units to baseline combat capacity: HP, temporary armor, statuses, cooldown-like battle state, and other runtime effects should reset before the next fight.
- Revisit campaign unit instance id presentation once recruits can duplicate the same base unit template or unit renaming exists. The runtime now carries stable ids for knockout tracking, but the UI intentionally still shows readable unit names.
- Expand non-permadeath retry planning controls. Losing a campaign scenario now returns to durable campaign planning and marks the scenario attempted, but the UI still needs real roster selection, job changing, tactics editing, and learned-ability assignment before retry planning matches the full design.
- Expand failed-attempt knowledge beyond the first attempted-scenario marker. Campaign progress now tracks attempted scenario ids without awarding XP, rewards, unlocks, or roster progression; future scouting state should decide exactly which encounters, enemy parties, or notes become inspectable after a loss.
- Revisit campaign retry framing later. Retries fit the buildcraft puzzle, but may weaken campaign narrative stakes if the story implies irreversible events.
- Add a future permadeath mode design pass. Account for replacement/catch-up problems such as losing an MVP, accelerated progression for new units, possible progression penalties for catch-up recruits, roster minimums, finale roster viability, UI warnings, and how memorialization affects unit biography.
- Design a death-consequence model before adding true long-term deaths. A biography-focused game should not memoryhole character death; explore scars that modify stats or capabilities after near-death events, and a final blaze-of-glory option where a unit's true death produces an extraordinary, life-saving effect for the party.
- Do not add a separate mastery-goals system for now. Let scenario-specific constraints and encounter parameters create implicit mastery pressure.

## Combat and Rules

- Add status effects when a focused scenario, job, enemy, or item design actually needs them.
- Design ailments as distinct rule pressures, not generic damage-over-time variants. Each ailment should create a readable tactical question or matchup hook.
- Good ailment directions to explore: bleed that punishes faster units or future movement, confusion that skips the first tactic the unit would have used, armor corrosion that changes mitigation math, silence-like effects that disrupt skill use, or panic effects that alter targeting.
- Ailments may either punish a unit's strengths or exploit a unit's weaknesses. Both paradigms are valid and can coexist.
- Add debuff purge options eventually, but keep them specific and intentionally scarce. Avoid a universal, always-accessible cleanse that erases ailment matchup pressure.
- Avoid generic ailment resistance stats. Occasional authored immunities are acceptable when they make a unit, enemy, item, or scenario identity clearer.
- Keep the first ailment implementation very small: one or two statuses with clear logs, deterministic duration rules, tooltip support, and simulator-owned state. Do not build a broad status framework until concrete content needs it.
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
- Future learned ability equipment should give each unit two skills: their current assigned class/job skill, plus one equipped learned skill unlocked from a different class/job.
- Future learned ability equipment should also give each unit one equipped learned passive and one equipped learned reaction from their unlocked ability pool.
- Track which class/job each learned ability came from so progression menus can filter, explain, and assign cross-class skills/passives/reactions correctly.
- Implement player choice for `pending_unlock_choice` using authored, non-random job unlock offers.
- First player-facing unlock choice should offer an active skill versus a reaction from the unit's current job. A later unlock should offer the job passive.
- Let unpicked active/reaction options remain available through further investment in that same job where practical, so the choice affects development order and biography without making experimentation too brittle.
- Keep the first real progression implementation content-small: build the unlock tracking, choice, equip, persistence, and UI plumbing around the current one-skill/one-passive/one-reaction job scaffold before adding larger job ability catalogs.
- Add persistent unit careers across scenarios.
- Build roster rotation pressure around opportunity cost and matchup evaluation, not fatigue/injury/rest punishment. Max-level units should still be legal and powerful, but bringing them should waste potential XP compared with developing lower-level units.
- Make scenario and enemy design push different roster/gear answers. If the optimal campaign habit becomes "bring the same three best units to every fight," the roster design has failed.
- Use scenario constraints, enemy mechanics, unlock incentives, and optional mastery goals only when they create readable matchup questions; do not add hard XP caps as the primary rotation mechanism.
- Add FFT-style job unlock dependencies later, after basic learned ability tracking and assignment are understandable. Do not bundle job dependency trees into the first progression UI pass.

## Gear, Items, and Inventory

- Build a real inventory model instead of the current simple between-fight item list.
- Campaign inventory should support free gear swapping between scenarios. Gear should remember who currently has it equipped, but should be unequippable and re-equippable to another available unit between scenarios when unit/job/item constraints allow it.
- Equipment should be locked only during an active battle/scenario resolution, not permanently bound to a unit across the campaign.
- Expand item effects only through declarative `EffectDefinition` data unless a focused mechanics pass requires new resolver code.
- Audit item catalog balance once more scenarios are playable.

## Content and Authoring

- Turn the broad content catalog into curated scenario-facing content. A first slice now adds existing catalog rewards to the authored scenarios; keep future curation small and scenario-specific.
- Add more handcrafted scenarios only when the framework and UI can make them understandable.
- Keep enemies as normal unit/loadout/job/item/tactic builds, not a separate monster-only ruleset.
- Do a project-wide content hook audit for mechanics authoring. Ensure mechanics can be authored, applied, inspected, and responded to through the relevant systems: tactics conditions/actions/targets, declarative item effects, job skills/passives/reactions, ancestry features, enemy builds, scenario rules, combat logs, replay snapshots, tooltips, save boundaries, content validation, and JSON sidecar docs where applicable.
- During the content hook audit, look for existing straggler mechanics that only work through one-off code paths or are not exposed cleanly to content authors.
- Use tags for filtering/conditions/content tools when an actual tool or rule needs them.
- Keep scenario, campaign, rule, and reward references complete enough for `tools/check_content.ps1` to validate ids, names, graph links, and reward items.
- Keep JSON sidecar docs next to every JSON content/modding file. `tools/check_content.ps1` now validates that discovered JSON packs have adjacent `*.options.md` files.

## Modding and Data Pipeline

- Keep `.tres` Resources and JSON mod packs equivalent where practical.
- Update sidecar `*.options.md` files whenever JSON schema, enums, keywords, or reference rules change; the content check enforces sidecar presence, not prose completeness.

## Save/Load and Persistence

- Add broader campaign save/load only after the remaining campaign state shapes are stable.
- Persisted unlocked/completed scenarios and first roster/job/gear/inventory state now exist; add active-attempt save/load only after scenario-local knockout, retry, and scouting reveal state are modeled cleanly.
- Revisit roster/job/gear serialization once learned ability choice/equip UI exists, because current persistence keeps the one-skill/one-passive/one-reaction scaffold but does not yet solve broader learned-ability catalogs.
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
