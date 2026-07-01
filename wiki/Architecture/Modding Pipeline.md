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

`ContentSchema` owns the shared vocabulary for JSON validation. `JsonContentLoader.load_content_result()` returns a structured content-load result with merged data, built Resources, and validation issues; callers that need fail-fast behavior can still use `load_content_resources()`.

Every modding JSON file must have an adjacent `.options.md` sidecar documenting its externally authorable contract. Those sidecars are authoritative for fields, enums, reference rules, validation rules, and merge semantics.

## Primary Owners

- `clockwork-company/scripts/modding/json_content_loader.gd`
- `clockwork-company/scripts/modding/content_load_result.gd`
- `clockwork-company/scripts/data/content_schema.gd`
- `clockwork-company/mods/`
- `clockwork-company/modding/reference/`
- `clockwork-company/scripts/tools/content_validation_check.gd`
- `clockwork-company/scripts/tools/content_schema_check.gd`

## Related

- [[MODDING]]
- [[Content Authoring]]
- [[Validation]]
