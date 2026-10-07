param([Parameter(Mandatory = $true)][string]$Destination)
$ErrorActionPreference = 'Stop'
$taskRepository = Split-Path $PSScriptRoot -Parent
$taskDestination = [IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $taskDestination) {
    throw 'Destination must be a new directory; existing hosts are never overwritten.'
}
# Explicit installation manifest. No recursive plugin copy.
$taskScripts = @(
    'source/utils/async_io_manager.gd',
    'source/utils/threading/single_thread.gd',
    'source/utils/threading/module_thread.gd',
    'source/utils/io_strategies/serialization/serialization_strategy.gd',
    'source/utils/io_strategies/serialization/json_serialization_strategy.gd',
    'source/utils/io_strategies/compression/compression_strategy.gd',
    'source/utils/io_strategies/compression/no_compression_strategy.gd',
    'source/utils/io_strategies/compression/gzip_compression_strategy.gd',
    'source/utils/io_strategies/encryption/encryption_strategy.gd',
    'source/utils/io_strategies/encryption/no_encryption_strategy.gd',
    'source/utils/io_strategies/encryption/xor_encryption_strategy.gd',
    'source/save_system/game_state_data.gd',
    'source/save_system/save_format_strategy/save_format_strategy.gd',
    'source/save_system/save_format_strategy/async_io_strategy.gd',
    'source/save_system/save_format_strategy/json_save_strategy.gd',
    'source/save_system/save_format_strategy/binary_save_strategy.gd',
    'source/save_system/save_format_strategy/resource_save_strategy.gd'
)
$taskModuleFiles = @()
foreach ($taskScript in $taskScripts) {
    $taskModuleFiles += $taskScript
    $taskModuleFiles += "$taskScript.uid"
}
$taskFixtures = @('tests/standalone_io/io_module_checks.gd', 'tests/standalone_io/io_module_checks.tscn')
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
config/name="Standalone IO validation"
run/main_scene="res://tests/standalone_io/io_module_checks.tscn"
[rendering]
renderer/rendering_method="gl_compatibility"
'@ | Set-Content -LiteralPath (Join-Path $taskDestination 'project.godot') -Encoding utf8
$taskModuleFiles | Set-Content -LiteralPath (Join-Path $taskDestination 'module_manifest.txt') -Encoding utf8
Write-Output "Created standalone IO host: $taskDestination"
