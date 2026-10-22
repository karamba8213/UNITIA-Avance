[CmdletBinding()]
param(
    [string]$CredentialsRoot = 'C:\unitia-credenciales-locales',
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$credentialFiles = @(
    'backend/.env',
    'frontend/.env.local',
    'firebase-admin.json',
    'unitia_app/android/app/google-services.json',
    'unitia_app/ios/Runner/GoogleService-Info.plist'
)

if (-not (Test-Path -LiteralPath $CredentialsRoot -PathType Container)) {
    throw "No se encontro el respaldo de credenciales en: $CredentialsRoot. Use -CredentialsRoot para indicar su ubicacion."
}

# Validar el inventario completo antes de copiar cualquier archivo.
foreach ($relativePath in $credentialFiles) {
    $source = Join-Path $CredentialsRoot $relativePath
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Falta un archivo en el respaldo: $relativePath"
    }
}

foreach ($relativePath in $credentialFiles) {
    $source = Join-Path $CredentialsRoot $relativePath
    $destination = Join-Path $projectRoot $relativePath
    if (Test-Path -LiteralPath $destination -PathType Leaf) {
        Write-Output "Conservado (ya existe): $relativePath"
        continue
    }
    if ($CheckOnly) {
        Write-Output "Disponible para restaurar: $relativePath"
        continue
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
    if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
        throw "No se pudo verificar la copia: $relativePath"
    }
    Write-Output "Restaurado y verificado: $relativePath"
}
