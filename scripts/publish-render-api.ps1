param(
    [string]$Branch = "master",
    [string]$Remote = "origin",
    [string]$CommitMessage = "Render: update prebuilt api jar",
    [switch]$SkipPush
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$apiDir = Join-Path $repoRoot "UNIDADE\apiProjetoSensor"
$jarOutDir = Join-Path $apiDir "render"
$jarOutPath = Join-Path $jarOutDir "app.jar"

Write-Host "==> Repo root: $repoRoot"
Write-Host "==> API dir:   $apiDir"

if (-not (Test-Path $apiDir)) {
    throw "API directory not found: $apiDir"
}

Push-Location $apiDir
try {
    Write-Host "==> Building Spring Boot jar..."
    .\gradlew.bat bootJar --no-daemon -x test

    $builtJar = Get-ChildItem -Path (Join-Path $apiDir "build\libs\*.jar") |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $builtJar) {
        throw "No jar found under build/libs after build."
    }

    New-Item -ItemType Directory -Force -Path $jarOutDir | Out-Null
    Copy-Item -Path $builtJar.FullName -Destination $jarOutPath -Force

    Write-Host "==> Updated: $jarOutPath"
    Write-Host "==> Source jar: $($builtJar.Name)"
}
finally {
    Pop-Location
}

Write-Host "==> Staging files for commit..."
git -C $repoRoot add "UNIDADE/apiProjetoSensor/render/app.jar" "UNIDADE/apiProjetoSensor/Dockerfile"

$status = git -C $repoRoot status --short
if (-not $status) {
    Write-Host "==> No changes to commit. Done."
    exit 0
}

Write-Host "==> Committing..."
git -C $repoRoot commit -m $CommitMessage

if ($SkipPush) {
    Write-Host "==> SkipPush enabled. Commit created locally only."
    exit 0
}

Write-Host "==> Pushing to $Remote/$Branch ..."
git -C $repoRoot push $Remote $Branch

Write-Host "==> Done. Render can deploy latest commit now."