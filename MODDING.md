# Modding Data Guide

This project supports a hybrid data workflow:

- Core game authoring: `.tres` Resources in Godot (editor ergonomics).
- Mod authoring: JSON packs in `clockwork-company/mods/`.

The runtime loader merges base Resource-derived data with JSON override/addition packs.

An equipped passive with `passive_type: "Forecast"` grants access to tactics with `foretell_enabled: true`. Foretell uses the tactic's normal state condition and target selector against one deterministic speculative baseline; it does not add forecast-specific conditions or targets.

Current JSON content supports authored statuses with `Boon`/`Ailment` polarity, `Ignore`/`Refresh`/`Intensify` stacking rules, and freeform `tags` on statuses, ancestries, items, jobs, tactics, loadouts, and units. Status application sources author finite owner-turn duration, defaulting to three turns, or explicitly opt into permanent application. Tactics support optional `display_name` and `foretell_enabled` fields. `Job Skill` and `Assigned Skill` are distinct tactic actions. Ancestries support base-stat ranges, baseline growth, one always-on feature, and optional equipment blacklists. Jobs support nested skill, passive, reaction, default-tactic, growth, and equipment-blacklist payloads. Skills can apply referenced statuses, and item `effects` can apply a referenced status at battle start. Units support ancestry references, physical/magic damage, and per-job progress. Loadouts can equip one learned skill from a job other than the current job, plus one unlocked passive, one unlocked reaction, and weapon, armor, helmet, and trinket item ids. Equipment is allowed unless the current job or immutable ancestry explicitly forbids its slot. See `clockwork-company/modding/reference/base_content.options.md` for the supported status ids, triggers, conditions, targets, effect types, and currently implemented combinations.

## Active Mod Folder

- Active mod JSON files: `clockwork-company/mods/*.json`
- All active JSON files are loaded and merged by id.

## Reference Folder

- Reference JSON and examples: `clockwork-company/modding/reference/`
- These files are documentation/templates and are not auto-loaded.
- Includes `integration_test_mod_pack.json` for broad end-to-end mod loader validation.

## Documentation Rule (Required)

Every JSON mod/data file must have an adjacent sidecar markdown file named:

- `<same-name>.options.md`

The sidecar must document:

- supported keys
- allowed enum/keyword values
- id/reference expectations
- merge/override behavior notes relevant to that file

When any schema/enum/keyword/reference rule changes, update JSON and sidecar docs in the same patch.
