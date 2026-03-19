param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter(Mandatory = $false)]
    [string]$Message = "atualizacoes de unidade",

    [Parameter(Mandatory = $false)]
    [string]$Branch = "master",

    [Parameter(Mandatory = $false)]
    [switch]$NoPush
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([string]$Args)
    & git $Args
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar: git $Args"
    }
}

try {
    $inside = (& git rev-parse --is-inside-work-tree 2>$null)
    if ($LASTEXITCODE -ne 0 -or $inside.Trim() -ne "true") {
        throw "Este comando deve ser executado dentro de um repositório Git."
    }

    $statusUnidade = (& git status --porcelain -- UNIDADE)
    if ([string]::IsNullOrWhiteSpace(($statusUnidade -join "`n"))) {
        Write-Host "Nenhuma alteracao em UNIDADE para commitar." -ForegroundColor Yellow
        exit 0
    }

    Invoke-Git "add -- UNIDADE"

    $commitMessage = "chore(unidade): $Message [v$Version]"
    Invoke-Git "commit -m \"$commitMessage\""

    if (-not $NoPush) {
        Invoke-Git "push origin $Branch"
    }

    Write-Host "Concluido: UNIDADE enviada com versao v$Version." -ForegroundColor Green
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
