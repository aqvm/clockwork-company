param(
	[string]$Script = "res://scripts/ui/combat_test_scene.gd",
	[string]$GodotExecutable = "Godot_v4.6-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $repoRoot
try {
	& $GodotExecutable `
		--headless `
		--path clockwork-company `
		--log-file godot-check.log `
		--check-only `
		--script $Script
	exit $LASTEXITCODE
}
finally {
	Pop-Location
}
