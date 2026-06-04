# Godot Best Practices Audit

Research date: 2026-06-03

This document records Godot best-practice guidance that matters for this project, why each practice exists, whether Clockwork Company currently follows it, and whether we should change anything. It is an audit and decision log, not a rulebook. Update it when we deliberately adopt, reject, or revise a Godot practice.

Primary sources used:

- Godot official Best Practices index: https://docs.godotengine.org/en/stable/tutorials/best_practices/
- Godot project organization: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
- Godot scene organization: https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html
- Godot autoload guidance: https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html
- Godot node alternatives: https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html
- Godot Resources: https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html
- Godot GDScript style guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
- Godot static typing guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html
- Godot signals guide: https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html
- Godot UI containers: https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html
- Godot size and anchors: https://docs.godotengine.org/en/stable/tutorials/ui/size_and_anchors.html
- Godot version control: https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html
- GDQuest OpenRPG repository: https://github.com/gdquest-demos/godot-open-rpg
- ramaureirac Godot Tactical RPG project structure overview: https://deepwiki.com/ramaureirac/godot-tactical-rpg/1.1-project-structure

## Executive Summary

The project is strongest where its learning goals already pushed it: deterministic combat logic, inspectable Resource data, readable docs, and separation between definitions and runtime state.

The main architectural pressure is UI composition. `clockwork-company/scripts/ui/combat_test_scene.gd` is now a 1400+ line scenario workbench, combat replay, party editor, tooltip host, and debug surface. That was acceptable while the UI shape was forming, but it is now the clearest place where Godot best practices point toward smaller scenes/scripts.

Do not chase every best practice immediately. The next high-value cleanup is to split the UI into focused Control scenes/scripts while preserving the existing combat and Resource data model.

## Audit Matrix

| Practice | Purpose | Current status | Recommendation |
| --- | --- | --- | --- |
| Organize files consistently using Godot's filesystem-first model. | Godot has no enforced project structure, so predictable folders make Resources, scenes, and scripts easier to find. | Mostly followed. The nested Godot project keeps `resources/`, `scripts/`, `scenes/`, `modding/`, and docs separate. | Keep current structure. Do not move `project.godot` during active feature work. Revisit root-vs-nested project only as a cleanup task. |
| Use `snake_case` for files/folders and `PascalCase` for node/class names. | Avoids case-sensitivity problems and matches Godot conventions. | Mostly followed for scripts/resources. Node names in the scene should be checked as UI scenes multiply. | Continue. New component scenes should use `snake_case.tscn` files and `PascalCase` node names. |
| Keep scenes focused and loosely coupled. | Reusable scenes should not depend on fragile external node paths or one giant parent script. | Partially followed. Combat logic is separate, but the main UI script owns too many panels and interactions. | Split the scenario workbench into child Control scenes/scripts with small public setup methods and signals. |
| Use scenes for reusable UI/visual structure and scripts for behavior. | Godot scenes make UI hierarchy inspectable in the editor; scripts should not become the only source of layout truth. | Partially followed. The main scene exists, but many controls are built dynamically in code. | Keep dynamic rows/lists where data-driven, but extract stable panels: scenario list/detail, party list, unit detail, combat replay, tooltip layer. |
| Prefer Resources/RefCounted/Object over nodes for pure data. | Nodes carry scene-tree behavior; Resources are lighter, serializable, Inspector-friendly data containers. | Followed well. Units, jobs, items, encounters, rewards, scenarios, rules, and campaigns are Resources; runtime state is separate. | Keep using Resources for authored content. Use RefCounted for runtime progress/state that should not be saved as authored content yet. |
| Separate data definitions from runtime mutable state. | Prevents authored content from being accidentally mutated during combat or campaign play. | Followed. `UnitDefinition`, `ItemDefinition`, `ScenarioDefinition`, etc. are definitions; `RunState`, `UnitState`, `ScenarioProgress`, and `CampaignProgress` are runtime-ish state. | Keep this boundary explicit. Tooltips should show when content is Resource data versus current combat state. |
| Use autoloads only for truly broad-scope services. | Autoloads are convenient but can create global coupling and hard-to-trace state. | Followed by restraint. The project does not appear to rely on autoloads for campaign/combat/UI state. | Do not autoload `CampaignManager` or tooltip services yet. Consider autoload only when multiple main scenes need the same service. |
| Use signals to decouple UI events from owners. | Signals keep buttons/panels from directly controlling unrelated systems. | Partially followed. Buttons connect to callbacks; future panel boundaries will need custom signals. | When splitting UI panels, have panels emit `scenario_selected`, `unit_selected`, `equipment_change_requested`, etc. Parent scene coordinates. |
| Prefer static typing consistently where practical. | Static types improve editor completion, readability, and earlier error detection. | Partially followed. Many scripts use type hints, but some dynamic `Resource` casts and Dictionary/Array payloads remain. | Keep typed GDScript as the project default. Allow localized dynamic code for generic Resource tooltip/modding surfaces. |
| Keep deterministic game logic independent from frame processing. | Tactical/autobattler rules should be testable and reproducible, not tied to `_process(delta)`. | Followed. Combat simulation is run as deterministic logic and replayed by UI. | Preserve. Future animations should consume combat events/snapshots, not become combat authority. |
| Use containers, size flags, and anchors for resizable UI. | Godot Control layouts need containers/anchors to handle varied window sizes and scaling. | Improved but partial. Recent UI resizing work helped, but the single script still manages a complex layout. | Keep building UI with Container nodes. Add manual resize checks after each UI pass. |
| Use external Resources for shared authored data. | External `.tres` files are inspectable, reusable, and diffable compared with buried scene resources. | Followed. Gameplay content is in `clockwork-company/resources/`. | Continue. Built-in scene resources are fine only for one-off presentation values. |
| Keep version-control ignores aligned with Godot 4.1+ guidance. | Avoids committing generated cache data while keeping real project data. | Mostly followed. Root and project `.gitignore` ignore `.godot/`; root ignores `clockwork-company/godot-check.log`; project ignores `/android/`. | Good enough. Keep committing `.tres`, `.tscn`, `.gd`, `.uid`, `.import`, and project config files unless a generated file is proven disposable. |
| Keep generated/imported asset policy explicit. | Godot import metadata affects reproducibility; large assets may eventually need Git LFS. | Partially relevant. This prototype has almost no heavy assets. | No Git LFS yet. Add it only before committing large binary art/audio/model files. |
| Favor learning-oriented, practical code over framework-building. | Open learning repos such as GDQuest OpenRPG emphasize reusable examples without turning into a general engine. | Followed in spirit. This repo has docs and small Resources, but recent UI growth risks obscuring the lesson. | Keep systems vertical and reviewable. Refactor only where it makes the current prototype clearer. |

## Project-Specific Guidance

### Data and Combat

Keep doing this:

- Author gameplay content as external `.tres` Resources.
- Clone/load runtime combat state rather than mutating authored Unit/Item/Encounter Resources.
- Keep combat simulation separate from combat replay and UI.
- Keep scenario/campaign as thin wrappers over existing run/combat flow.
- Let scenario rules exist as data before mechanics enforce them.

Be careful with:

- Adding many one-off Resource fields before the UI/tooltips can explain them.
- Making `RunState` know too much about UI.
- Letting combat logs become the only source of replay state. Logs are excellent explanations, but structured snapshots/events will be easier to animate.

### UI

The current UI is functional but past the point where one large script is healthy. The next UI pass should introduce focused ownership:

- `ScenarioListPanel`: displays available/locked/completed scenarios and emits selection.
- `ScenarioDetailPanel`: renders selected scenario story, encounters, rules, rewards, and unlocks.
- `PartyPanel`: shows roster summary and emits unit selection.
- `UnitDetailPanel`: shows stats, job, equipment, tactics, skills, passives, reactions, and equipment-change requests.
- `CombatReplayPanel`: owns replay controls and display.
- `TooltipPresenter`: stays a reusable tooltip layer/helper, not a global autoload yet.

This follows Godot's scene composition model and gives the human owner smaller files to inspect.

### GDScript Style and Types

Use typed GDScript as the default:

- Add return types to new functions.
- Type function parameters when the expected type is known.
- Use `class_name` for reusable data/runtime classes.
- Keep generic `Resource` or `Dictionary` surfaces only where the engine or modding pipeline genuinely requires them.

Do not turn this into a style-policing task. Improve types during normal edits or focused cleanup passes.

### Autoloads

Do not add autoloads right now. The campaign, tooltip, and combat systems still live in one main UI flow. Autoloads become more attractive when:

- there are multiple playable scenes that need shared campaign state,
- save/load exists,
- a service owns broad-scope state without reaching into unrelated systems.

Until then, explicit parent-owned managers are easier to reason about.

### Version Control

The Godot 4.1+ guidance says to ignore `.godot/` and generated translation files. This repo already does that. Continue tracking:

- `.gd`, `.gd.uid`
- `.tscn`, `.tres`
- `.import` files for imported assets
- `project.godot`
- root docs
- JSON modding references and their sidecar docs

Do not add Git LFS until real binary assets become large enough to justify it.

## Adopt / Defer Decisions

Adopted:

- Split the first four planning UI responsibilities into component scenes/scripts: scenario list, scenario detail, party list, and unit detail.
- Use custom child-panel signals for scenario and unit selection.

Adopt soon:

- Continue splitting the main UI script into component scenes/scripts, especially unit actions and combat replay.
- Keep new UI components signal-driven.
- Add a light content validation script or Godot check scene once scenario content grows.
- Keep `TODO.md` synced with this audit when recommendations become actual backlog items.

Adopt gradually:

- Increase static typing in older dynamic surfaces.
- Move stable layout out of code and into `.tscn` scenes.
- Add richer structured replay snapshots if combat animation becomes hard to drive from events.

Defer:

- Autoload managers.
- Git LFS.
- Plugins/addons for testing or UI unless the project starts paying clear complexity costs.
- Root-project migration.
- Any management-sim campaign systems.

Reject for now:

- Procedural content architecture.
- Async multiplayer/ghost infrastructure.
- Global singleton state for every manager.
- Large framework-style abstraction layers.

## Manual Audit Checklist

Use this before/after substantial Godot changes:

1. Can the project still open with `clockwork-company/project.godot`?
2. Does `combat_test_scene.gd` still pass the project-local Godot check?
3. Did the change mutate authored Resources at runtime?
4. Did UI code grow a new responsibility that should belong to a child panel?
5. Did new content use external `.tres` Resources where inspectability matters?
6. Did JSON schema/content changes update sidecar `*.options.md` docs?
7. Did TODO/design/architecture/learning docs need an update?

## One Small Exercise

Pick one section of `combat_test_scene.gd`, such as scenario selection or party list rendering, and sketch the signals and public methods it would need if it became its own `Control` scene. Do not implement it yet; just write the intended API in comments or notes. This checks whether the component boundary is real or only cosmetic.
