# Mods Folder

Any `.json` file placed directly in this folder (`res://mods/`) is loaded by the JSON content loader and merged into base game data.

## Rules

- Merge key is `id` per collection (`items`, `jobs`, `tactics`, `loadouts`, `units`).
- Later files can override fields from earlier/base entries.
- Invalid enum/reference values fail fast during load.
- Keep a sidecar `*.options.md` file next to every mod JSON to document supported keys and author intent.

## Recommended workflow

1. Copy a template from `res://modding/reference/`.
2. Rename it for your mod.
3. Keep the matching sidecar markdown in sync with your JSON.
