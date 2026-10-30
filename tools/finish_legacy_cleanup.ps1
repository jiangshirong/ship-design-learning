$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$courseRoot = Split-Path -Parent $projectRoot
$userRoot = Join-Path $env:APPDATA 'Godot/app_userdata/船舶原理学习'
$oldUser = Join-Path $env:APPDATA 'Godot/app_userdata/第一周口试25题'
$oldProject = Join-Path $courseRoot '口试25题学习'
$oldLauncher = Join-Path $courseRoot '开始口试25题.cmd'
$destination = Join-Path $userRoot 'review'
$archive = Join-Path $destination 'legacy-import/20261023'
New-Item -ItemType Directory -Path $archive -Force | Out-Null
function LearningHashes {
    $result = @{}
    $files = @(Get-Item -LiteralPath (Join-Path $userRoot 'progress.json') -ErrorAction SilentlyContinue)
    $files += @(Get-ChildItem -LiteralPath $destination -File | Where-Object Name -NotMatch '^qa-')
    foreach ($file in $files) { $result[$file.FullName] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
    return $result
}
$before = LearningHashes
$records = @()
if (Test-Path -LiteralPath $oldUser) {
    $files = Get-ChildItem -LiteralPath $oldUser -File | Where-Object { $_.Name -match '^(progress|reading-review|stability-progress)\.json' -or $_.Name -match '^qa-.*corrupt.*\.json' }
    foreach ($file in $files) {
        $copy = Join-Path $archive $file.Name
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        if (Test-Path -LiteralPath $copy) {
            if ((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -ne $hash) { throw "Archive collision: $($file.Name)" }
        } else { Copy-Item -LiteralPath $file.FullName -Destination $copy }
        if ((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -ne $hash) { throw 'Progress copy mismatch' }
        $valid = $true
        try { Get-Content -LiteralPath $copy -Raw | ConvertFrom-Json -ErrorAction Stop | Out-Null } catch { $valid = $false }
        $target = Join-Path $destination $file.Name
        $kept = Test-Path -LiteralPath $target
        if (-not $kept -and $valid -and $file.Name -match '^(progress|reading-review|stability-progress)\.json(\.bak)?$') {
            Copy-Item -LiteralPath $copy -Destination $target
            if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $hash) { throw 'Target migration mismatch' }
        }
        $records += @{ file=$file.Name; sha256=$hash; valid_json=$valid; existing_target_preserved=$kept; archived=$true }
    }
}
# Verify every previously existing learning file before deleting the legacy app.
$after = LearningHashes
foreach ($key in $before.Keys) { if ($before[$key] -ne $after[$key]) { throw "Existing learning progress changed: $key" } }
$removed = @()
foreach ($target in @($oldProject,$oldUser,$oldLauncher)) {
    if (-not (Test-Path -LiteralPath $target)) { continue }
    $absolute = (Resolve-Path -LiteralPath $target).Path
    $expected = [IO.Path]::GetFullPath($target)
    if ($absolute -ne $expected -or $absolute -eq $projectRoot -or $absolute -eq $userRoot) { throw 'Unexpected cleanup path' }
    if ($target -eq $oldProject -and (Split-Path -Parent $absolute) -ne $courseRoot) { throw 'Project outside intended course folder' }
    if ($target -eq $oldUser -and (Split-Path -Leaf $absolute) -ne '第一周口试25题') { throw 'Unexpected legacy user folder' }
    Remove-Item -LiteralPath $absolute -Recurse -Force
    if (Test-Path -LiteralPath $absolute) { throw 'Legacy path still exists' }
    $removed += $absolute
}
@{ copied_and_verified=$records; removed=$removed; existing_learning_files_unchanged=$true; before=$before; after=$after } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $projectRoot 'qa/repair-20261023/legacy-cleanup.json') -Encoding utf8
Write-Output "Archived and verified $($records.Count) progress files; removed $($removed.Count) legacy paths; current progress unchanged."
