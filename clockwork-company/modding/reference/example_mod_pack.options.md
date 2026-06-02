# Example Mod Pack Notes

This sidecar documents the exact options used by `example_mod_pack.json`.
For the complete schema/keywords/enums, see `base_content.options.md` in the same folder.

## Purpose

Demonstrates three common mod actions:
- adding a new item (`tower_shield`)
- patching an existing loadout by id (`guard_buckler`)
- patching an existing unit stat by id (`mira_scout`)

## Keys used in this example

- Top-level:
  - `pack_id`
  - `pack_version`
  - `items`
  - `loadouts`
  - `units`

- `items[]`:
  - `id`
  - `display_name`
  - `slot`
  - `max_hp_modifier`
  - `physical_damage_modifier`
  - `magic_damage_modifier`
  - `armor_modifier`
  - `action_interval_modifier`
  - `trigger`
  - `effect`
  - `effect_amount`

- `loadouts[]`:
  - `id`
  - `armor_id`

- `units[]`:
  - `id`
  - `action_interval`

## Usage

Do not place this file directly under `res://mods/` unless you want it loaded.
To activate, copy it into `res://mods/` and rename if desired.
