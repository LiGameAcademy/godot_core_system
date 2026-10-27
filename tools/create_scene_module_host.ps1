param(
    [Parameter(Mandatory = $true)]
    [string]$Destination
)

$ErrorActionPreference = 'Stop'
$taskRepository = Split-Path $PSScriptRoot -Parent
$taskDestination = [IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $taskDestination) {
    throw 'Destination must be a new directory; existing hosts are never overwritten.'
}

# Explicit installation manifest. No recursive copy of the plugin is performed.
$taskModuleFiles = @(
    'source/scene_system/core_scenes.gd',
    'source/scene_system/core_scenes.gd.uid',
    'source/scene_system/core_scene_request.gd',
    'source/scene_system/core_scene_request.gd.uid',
    'source/scene_system/core_scene_transition.gd',
    'source/scene_system/core_scene_transition.gd.uid',
    'source/scene_system/core_scene_transition_operation.gd',
    'source/scene_system/core_scene_transition_operation.gd.uid',
    'source/scene_system/core_scene_transition.tscn'
)
$taskFixtures = @('scene_module_checks.gd', 'scene_a.tscn', 'scene_b.tscn')
foreach ($taskFile in $taskModuleFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $taskRepository $taskFile) -PathType Leaf)) {
        throw "Missing module file: $taskFile"
    }
}
foreach ($taskFile in $taskFixtures) {
    if (-not (Test-Path -LiteralPath (Join-Path $taskRepository "tests/standalone_scenes/$taskFile") -PathType Leaf)) {
        throw "Missing fixture: $taskFile"
    }
}
New-Item -ItemType Directory -Path $taskDestination | Out-Null
foreach ($taskFile in $taskModuleFiles) {
    $taskOutput = Join-Path $taskDestination "addons/godot_core_system/$taskFile"
    New-Item -ItemType Directory -Force -Path (Split-Path $taskOutput -Parent) | Out-Null
    Copy-Item -LiteralPath (Join-Path $taskRepository $taskFile) -Destination $taskOutput
}
$taskFixtureDirectory = Join-Path $taskDestination 'fixtures'
New-Item -ItemType Directory -Path $taskFixtureDirectory | Out-Null
foreach ($taskFile in $taskFixtures) {
    Copy-Item -LiteralPath (Join-Path $taskRepository "tests/standalone_scenes/$taskFile") -Destination $taskFixtureDirectory
}
@'
config_version=5
[application]
config/name="StandaloneSceneModuleChecks"
run/main_scene="res://fixtures/scene_a.tscn"
[autoload]
SceneModuleChecks="*res://fixtures/scene_module_checks.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
'@ | Set-Content -LiteralPath (Join-Path $taskDestination 'project.godot') -Encoding UTF8
$taskModuleFiles | Set-Content -LiteralPath (Join-Path $taskDestination 'installed_module_files.txt') -Encoding UTF8
Write-Output "Created scene-only host: $taskDestination"
Write-Output "Installed $($taskModuleFiles.Count) module files plus $($taskFixtures.Count) check fixtures. Import the host before running it."
