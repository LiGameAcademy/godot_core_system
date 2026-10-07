param([Parameter(Mandatory = $true)][string]$Destination)
$ErrorActionPreference = 'Stop'
$taskRepository = Split-Path $PSScriptRoot -Parent
$taskDestination = [IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $taskDestination) {
    throw 'Destination must be a new directory; existing hosts are never overwritten.'
}
$taskScripts = @(
    'source/input_system/input_manager.gd',
    'source/input_system/input_state.gd',
    'source/input_system/core_inputs.gd',
    'source/input_system/core_input_binding.gd',
    'source/input_system/features/input_buffer.gd',
    'source/input_system/features/input_recorder.gd',
    'source/input_system/features/input_virtual_axis.gd',
    'source/input_system/features/input_event_processor.gd',
    'source/input_system/config/input_config.gd',
    'source/input_system/config/input_config_adapter.gd'
)
$taskModuleFiles = @('source/input_system/input_manager.tscn')
foreach ($taskScript in $taskScripts) {
    $taskModuleFiles += $taskScript
    $taskModuleFiles += "$taskScript.uid"
}
$taskFixtures = @(
    'tests/standalone_input/input_module_checks.gd', 'tests/standalone_input/input_module_checks.tscn',
    'tests/standalone_input/input_example_checks.gd', 'tests/standalone_input/input_example_checks.tscn',
    'examples/input_extensions/input_extensions.gd', 'examples/input_extensions/input_extensions.tscn'
)
foreach ($taskFile in $taskModuleFiles + $taskFixtures) {
    if (-not (Test-Path -LiteralPath (Join-Path $taskRepository $taskFile) -PathType Leaf)) {
        throw "Missing installation file: $taskFile"
    }
}
foreach ($taskFile in $taskModuleFiles + $taskFixtures) {
    $taskTarget = Join-Path $taskDestination $taskFile
    New-Item -ItemType Directory -Path (Split-Path $taskTarget -Parent) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $taskRepository $taskFile) -Destination $taskTarget
}
@'
config_version=5
[application]
config/name="Standalone input validation"
run/main_scene="res://tests/standalone_input/input_module_checks.tscn"
[rendering]
renderer/rendering_method="gl_compatibility"
'@ | Set-Content -LiteralPath (Join-Path $taskDestination 'project.godot') -Encoding utf8
$taskModuleFiles | Set-Content -LiteralPath (Join-Path $taskDestination 'module_manifest.txt') -Encoding utf8
Write-Output "Created standalone input host: $taskDestination"
