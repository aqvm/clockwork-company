param(
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
		--script res://scripts/tools/content_validation_check.gd
	exit $LASTEXITCODE
}
finally {
	Pop-Location
}
