---
type: workflow
state: implemented
tags:
  - workflow
  - validation
---

# Validation

Use the narrowest focused check during implementation. Run the established complete validation suite once as the final pre-commit/pre-push gate.

## Main Checks

- Wiki graph and references: `powershell -ExecutionPolicy Bypass -File tools/check_wiki.ps1`
- Full Godot/script checks: `tools/check_godot.ps1`
- Content and reference checks: `tools/check_content.ps1`
- Focused status mechanics: `clockwork-company/scripts/tools/status_mechanics_check.gd`
- Focused shared effects/jobs: `clockwork-company/scripts/tools/triggered_effect_mechanics_check.gd`
- Tactic authoring: `clockwork-company/scripts/tools/tactic_authoring_check.gd`
- Foretell: `clockwork-company/scripts/tools/forecast_mechanics_check.gd`
- Event pipeline: `clockwork-company/scripts/tools/combat_event_pipeline_check.gd`
- Content validation: `clockwork-company/scripts/tools/content_validation_check.gd`

## Godot CLI Rule

Always direct Godot CLI logging to the project-local reusable scratch file:

```powershell
Godot_v4.6-stable_win64_console.exe --headless --path clockwork-company --log-file godot-check.log --check-only --script res://scripts/ui/combat_test_scene.gd
```

This avoids sandbox failures when Godot tries to write to its normal `user://logs` location.

## Documentation-Only Changes

For wiki-only changes, verify:

- `powershell -ExecutionPolicy Bypass -File tools/check_wiki.ps1` passes
- `git diff --check` passes
