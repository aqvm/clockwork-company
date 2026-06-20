$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$markdownFiles = Get-ChildItem -Path $repoRoot -Recurse -Filter *.md
$wikiFiles = Get-ChildItem -Path (Join-Path $repoRoot "wiki") -Recurse -Filter *.md
$errors = [System.Collections.Generic.List[string]]::new()

function Get-RepoRelativePath([string] $fullPath) {
    return $fullPath.Substring($repoRoot.Length + 1)
}

$duplicateGroups = $markdownFiles | Group-Object BaseName | Where-Object Count -gt 1
foreach ($group in $duplicateGroups) {
    $relativePaths = $group.Group | ForEach-Object {
        Get-RepoRelativePath $_.FullName
    }
    $errors.Add("Duplicate Markdown basename '$($group.Name)': $($relativePaths -join ', ')")
}

$pageNames = @{}
foreach ($file in $markdownFiles) {
    $pageNames[$file.BaseName] = $true
}

foreach ($file in $markdownFiles) {
    $text = Get-Content $file.FullName -Raw
    if ($null -eq $text) {
        $text = ""
    }
    foreach ($match in [regex]::Matches($text, "\[\[([^\]|#]+)(?:#[^\]|]+)?(?:\|[^\]]+)?\]\]")) {
        $target = $match.Groups[1].Value
        if (-not $pageNames.ContainsKey($target)) {
            $relativePath = Get-RepoRelativePath $file.FullName
            $errors.Add("Broken wikilink in '$relativePath': $target")
        }
    }
}

foreach ($file in $wikiFiles) {
    $text = Get-Content $file.FullName -Raw
    if ($null -eq $text) {
        $text = ""
    }
    $relativePath = Get-RepoRelativePath $file.FullName
    if (-not $text.StartsWith("---")) {
        $errors.Add("Missing frontmatter in '$relativePath'.")
    }
    if ($text -notmatch "(?m)^type: ") {
        $errors.Add("Missing type in '$relativePath'.")
    }
    if ($file.Name -ne "Home.md" -and $text -notmatch "(?m)^state: ") {
        $errors.Add("Missing state in '$relativePath'.")
    }

    foreach ($match in [regex]::Matches($text, '`((?:clockwork-company|tools)/[^`]+)`')) {
        $relativeReference = $match.Groups[1].Value -replace "/", [System.IO.Path]::DirectorySeparatorChar
        $referencedPath = Join-Path $repoRoot $relativeReference
        if (-not (Test-Path -LiteralPath $referencedPath)) {
            $errors.Add("Missing repository path in '$relativePath': $($match.Groups[1].Value)")
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "Wiki validation passed: $($wikiFiles.Count) wiki pages, unique Markdown basenames, resolved wikilinks, required frontmatter, and valid repository paths."
