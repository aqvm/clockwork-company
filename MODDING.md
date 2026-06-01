# Modding Data Guide

This project supports a hybrid data workflow:

- Core game authoring: `.tres` Resources in Godot (editor ergonomics).
- Mod authoring: JSON packs in `clockwork-company/mods/`.

The runtime loader merges base Resource-derived data with JSON override/addition packs.

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
