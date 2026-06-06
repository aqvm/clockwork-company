# Modding Data Guide

This project supports a hybrid data workflow:

- Core game authoring: `.tres` Resources in Godot (editor ergonomics).
- Mod authoring: JSON packs in `clockwork-company/mods/`.

The runtime loader merges base Resource-derived data with JSON override/addition packs.

Current JSON content supports freeform `tags` on ancestries, items, jobs, tactics, loadouts, and units. Tactics also support an optional `display_name`, which is used in setup and combat log text when present. Ancestries support base-stat ranges, baseline growth, and one always-on feature. Jobs support nested skill, passive, reaction, default-tactic, growth, and equipment-forbid payloads. Units support ancestry references, physical/magic damage, and per-job progress. Loadouts can optionally equip learned skill/passive/reaction payloads that override the current job defaults, plus weapon, armor, helmet, and trinket item ids. Equipment is allowed by default unless a job explicitly sets a `forbid_*` field. Items support declarative `effects` arrays for the first version of data-authored item behavior. See `clockwork-company/modding/reference/base_content.options.md` for the supported triggers, conditions, targets, effect types, and currently implemented combinations.

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
