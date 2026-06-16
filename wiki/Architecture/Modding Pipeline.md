---
type: architecture
state: implemented
tags:
  - architecture
  - modding
  - json
---

# Modding Pipeline

Base content remains authored in Godot `.tres` Resources. The loader derives JSON-like dictionaries, merges enabled mod JSON overrides, validates the combined data, and reconstructs runtime Resources.

Every modding JSON file must have an adjacent `.options.md` sidecar documenting its externally authorable contract. Those sidecars are authoritative for fields, enums, reference rules, validation rules, and merge semantics.

## Primary Owners

- `clockwork-company/scripts/modding/json_content_loader.gd`
- `clockwork-company/mods/`
- `clockwork-company/modding/reference/`
- `clockwork-company/scripts/tools/content_validation_check.gd`

## Related

- [[MODDING]]
- [[Content Authoring]]
- [[Validation]]
