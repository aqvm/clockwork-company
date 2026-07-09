# Example Mod Pack Notes

This sidecar documents the exact options used by `example_mod_pack.json`.
For the complete schema/keywords/enums, see `base_content.options.md` in the same folder.

## Purpose

Demonstrates one small mod action against the clean-slate catalog:
- patching an existing unit by id (`template_pyromancer`)

## Keys used in this example

- Top-level:
  - `pack_id`
  - `pack_version`
  - `units`
  - `demo_roster`

- `units[]`:
  - `id`
  - `display_name`
  - `team`
  - `max_hp`
  - `physical_damage`
  - `magic_damage`
  - `armor`
  - `action_speed`
  - `loadout_id`
  - `tooltip_text`

## Usage

Do not place this file directly under `res://mods/` unless you want it loaded.
To activate, copy it into `res://mods/` and rename if desired.
