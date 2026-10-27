param(
    [Parameter(Mandatory = $true)]
    [string]$GodotPath,
    [string]$WorkDirectory = (Join-Path ([System.IO.Path]::GetTempPath()) ('core_localization_' + [guid]::NewGuid().ToString('N'))),
    [switch]$SkipExport
)

$ErrorActionPreference = 'Stop'
$addonRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$hostRoot = [System.IO.Path]::GetFullPath($WorkDirectory)
$enginePath = [System.IO.Path]::GetFullPath($GodotPath)
if (-not (Test-Path -LiteralPath $enginePath -PathType Leaf)) { throw 'Godot executable not found.' }
if ($hostRoot.StartsWith($addonRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or $hostRoot -eq $addonRoot) {
    throw 'Use a fresh work directory outside the addon to avoid recursive imports.'
}
if ((Test-Path -LiteralPath $hostRoot) -and @(Get-ChildItem -LiteralPath $hostRoot -Force).Count -gt 0) {
    throw 'Work directory must be empty; existing files are preserved.'
}
$version = (& $enginePath --headless --version | Out-String).Trim()
if (-not $version.StartsWith('4.7.2.')) { throw 'This acceptance run targets Godot 4.7.2.' }
if (-not $SkipExport -and $version.Contains('.mono.')) {
    throw 'Use standard Godot 4.7.2 for the Windows export, or pass -SkipExport for Mono host checks.'
}

New-Item -ItemType Directory -Path (Join-Path $hostRoot 'addons/godot_core_system') -Force | Out-Null
$copiedAddon = Join-Path $hostRoot 'addons/godot_core_system'
foreach ($entry in @('source', 'setting.gd')) {
    Copy-Item -LiteralPath (Join-Path $addonRoot $entry) -Destination $copiedAddon -Recurse
}
$copiedExamples = Join-Path $copiedAddon 'examples'
$copiedTests = Join-Path $copiedAddon 'test/unit'
New-Item -ItemType Directory -Path $copiedExamples, $copiedTests -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $addonRoot 'examples/localization_demo') -Destination $copiedExamples -Recurse
New-Item -ItemType Directory -Path (Join-Path $copiedTests 'fixtures') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $addonRoot 'test/unit/fixtures/localization') -Destination (Join-Path $copiedTests 'fixtures') -Recurse
$sceneNames = @('localization_native_checks', 'localization_checks', 'localization_demo_checks')
foreach ($sceneName in $sceneNames) {
    foreach ($extension in @('.gd', '.tscn', '.gd.uid')) {
        Copy-Item -LiteralPath (Join-Path $addonRoot ('test/unit/' + $sceneName + $extension)) -Destination $copiedTests
    }
}
$project = @'
config_version=5
[application]
config/name="Localization acceptance"
run/main_scene="res://addons/godot_core_system/test/unit/localization_native_checks.tscn"
[autoload]
CoreSystem="*res://addons/godot_core_system/source/core_system.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
[internationalization]
locale/fallback="en"
[godot_core_system]
module_enable/localization_manager=false
module_enable/logger=true
module_enable/config_manager=false
module_enable/audio_manager=false
module_enable/event_bus=false
module_enable/input_manager=false
module_enable/scene_manager=false
module_enable/time_manager=false
module_enable/resource_manager=false
module_enable/save_manager=false
module_enable/state_machine=false
module_enable/entity_manager=false
module_enable/trigger_manager=false
module_enable/gameplay_tag_manager=false
config_system/config_path="res://preferences.cfg"
'@
$projectPath = Join-Path $hostRoot 'project.godot'
$encoding = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($projectPath, $project, $encoding)

function Test-RunLog {
    param([string]$LogPath, [int]$ExitCode, [bool]$RequirePass)
    $content = [System.IO.File]::ReadAllText($LogPath)
    $unexpectedErrors = @($content -split '\r?\n' | Where-Object {
        if ($_ -notmatch '^ERROR:') { return $false }
        if ($_ -eq 'ERROR: Failed to read the root certificate store.') { return $false }
        # Restricted environments may deny editor cache/settings writes outside this host.
        if (-not $RequirePass -and ($_ -match '^ERROR: (Cannot create file .*editor_doc_cache|Cannot save editor help cache|Cannot save file .*editor_settings|Error saving editor settings|Could not open ''user://'' directory)')) { return $false }
        return $true
    })
    if ($ExitCode -ne 0 -or $unexpectedErrors.Count -gt 0 -or $content -match 'SCRIPT ERROR|Parse Error|FAIL:|ObjectDB instances leaked|resources still in use') {
        throw ('Acceptance failed; inspect ' + $LogPath)
    }
    if ($RequirePass -and $content -notmatch '(?m)^PASS:') {
        throw ('Missing PASS marker; inspect ' + $LogPath)
    }
}

Push-Location $hostRoot
try {
    $importLog = Join-Path $hostRoot 'import-output.txt'
    & $enginePath --headless --editor --path $hostRoot --import --log-file (Join-Path $hostRoot 'import.log') *> $importLog
    $importExit = $LASTEXITCODE
    # Native CSV import may register demo resources; unit fixtures own their catalogs.
    [System.IO.File]::WriteAllText($projectPath, $project, $encoding)
    Test-RunLog $importLog $importExit $false
    foreach ($sceneName in $sceneNames) {
        $runLog = Join-Path $hostRoot ($sceneName + '-output.txt')
        & $enginePath --headless --path $hostRoot ('res://addons/godot_core_system/test/unit/' + $sceneName + '.tscn') --quit-after 600 --log-file (Join-Path $hostRoot ($sceneName + '.log')) *> $runLog
        Test-RunLog $runLog $LASTEXITCODE $true
        Select-String -LiteralPath $runLog -Pattern '^PASS:' | ForEach-Object { Write-Output $_.Line }
    }
    if (-not $SkipExport) {
        $presets = @'
[preset.0]
name="Windows Acceptance"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter="*.po"
exclude_filter=""
export_path="exports/localization_checks.exe"
script_export_mode=0
[preset.0.options]
custom_template/debug=""
custom_template/release=""
binary_format/embed_pck=false
binary_format/architecture="x86_64"
codesign/enable=false
'@
        [System.IO.File]::WriteAllText((Join-Path $hostRoot 'export_presets.cfg'), $presets, $encoding)
        $exports = Join-Path $hostRoot 'exports'
        New-Item -ItemType Directory -Path $exports -Force | Out-Null
        $executable = Join-Path $exports 'localization_checks.exe'
        $exportLog = Join-Path $hostRoot 'export-output.txt'
        & $enginePath --headless --path $hostRoot --export-debug 'Windows Acceptance' $executable --log-file (Join-Path $hostRoot 'export.log') *> $exportLog
        Test-RunLog $exportLog $LASTEXITCODE $false
        $consoleExecutable = Join-Path $exports 'localization_checks.console.exe'
        if (Test-Path -LiteralPath $consoleExecutable) { $executable = $consoleExecutable }
        $runtimeLog = Join-Path $hostRoot 'export-runtime-output.txt'
        & $executable --headless --quit-after 600 --log-file (Join-Path $exports 'runtime.log') *> $runtimeLog
        Test-RunLog $runtimeLog $LASTEXITCODE $true
        Select-String -LiteralPath $runtimeLog -Pattern '^PASS:' | ForEach-Object { Write-Output ('Windows export: ' + $_.Line) }
    }
    Write-Output ('Logs and artifacts retained at ' + $hostRoot)
}
finally {
    Pop-Location
}
