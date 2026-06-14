param(
	[string]$GodotExecutable = "Godot_v4.6-stable_win64_console.exe",
	[int]$PerCheckTimeoutSeconds = 30
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$checks = @(
	@{ Name = "Godot script parse"; Arguments = @("--check-only", "--script", "res://scripts/ui/combat_test_scene.gd") },
	@{ Name = "Content validation"; Arguments = @("--script", "res://scripts/tools/content_validation_check.gd") },
	@{ Name = "Combat event pipeline"; Arguments = @("--script", "res://scripts/tools/combat_event_pipeline_check.gd") },
	@{ Name = "Status mechanics"; Arguments = @("--script", "res://scripts/tools/status_mechanics_check.gd") },
	@{ Name = "Triggered effects"; Arguments = @("--script", "res://scripts/tools/triggered_effect_mechanics_check.gd") },
	@{ Name = "Tactic authoring"; Arguments = @("--script", "res://scripts/tools/tactic_authoring_check.gd") },
	@{ Name = "Foretell mechanics"; Arguments = @("--script", "res://scripts/tools/forecast_mechanics_check.gd") }
)

function Invoke-GodotValidation {
	param(
		[string]$Name,
		[string[]]$CheckArguments
	)

	$arguments = @(
		"--headless",
		"--path", "clockwork-company",
		"--log-file", "godot-check.log"
	) + $CheckArguments
	$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$serializedArguments = ConvertTo-Json -InputObject $arguments -Compress
	$job = Start-Job -ScriptBlock {
		param($Root, $Executable, $SerializedArguments)
		Set-Location $Root
		$arguments = ConvertFrom-Json $SerializedArguments
		& $Executable @arguments | Out-Null
		$LASTEXITCODE
	} -ArgumentList $repoRoot.Path, $GodotExecutable, $serializedArguments
	try {
		if ($null -eq (Wait-Job -Job $job -Timeout $PerCheckTimeoutSeconds)) {
			Stop-Job -Job $job
			throw "$Name timed out after $PerCheckTimeoutSeconds seconds. Inspect clockwork-company/godot-check.log."
		}
		$exitCode = Receive-Job -Job $job
		if ($exitCode -ne 0) {
			throw "$Name failed with exit code $exitCode. Inspect clockwork-company/godot-check.log."
		}
	}
	finally {
		$stopwatch.Stop()
		if ($job.State -eq "Running") {
			Stop-Job -Job $job
		}
		Remove-Job -Job $job -Force
	}
	Write-Host ("Passed: {0} ({1:N2}s)" -f $Name, $stopwatch.Elapsed.TotalSeconds)
}

Push-Location $repoRoot
try {
	$suiteStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	foreach ($check in $checks) {
		Invoke-GodotValidation -Name $check.Name -CheckArguments $check.Arguments
	}
	& powershell -ExecutionPolicy Bypass -File tools/check_wiki.ps1
	if ($LASTEXITCODE -ne 0) {
		throw "Wiki validation failed."
	}
	& git diff --check
	if ($LASTEXITCODE -ne 0) {
		throw "git diff --check failed."
	}
	$suiteStopwatch.Stop()
	Write-Host ("Complete validation suite passed ({0:N2}s)." -f $suiteStopwatch.Elapsed.TotalSeconds)
}
finally {
	Pop-Location
}
