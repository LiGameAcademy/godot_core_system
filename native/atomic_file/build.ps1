param([Parameter(Mandatory = $true)][string]$Compiler)
$ErrorActionPreference = 'Stop'
$nativeDirectory = $PSScriptRoot
$outputFile = Join-Path $nativeDirectory 'bin/core_atomic_file.windows.x86_64.dll'
New-Item -ItemType Directory -Force -Path (Split-Path $outputFile) | Out-Null
& $Compiler -shared -Wall -o $outputFile (Join-Path $nativeDirectory 'atomic_file.c')
if ($LASTEXITCODE -ne 0) { throw 'Native compilation failed.' }
Get-FileHash -Algorithm SHA256 -LiteralPath $outputFile
