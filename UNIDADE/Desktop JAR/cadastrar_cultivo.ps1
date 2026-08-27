param()
Write-Host "==== Cadastrar Cultivo - Estufa Smart (PowerShell) ====" -ForegroundColor Cyan
$base = Read-Host "Digite a URL base da API (ex: https://api-estufa.onrender.com)"
if ([string]::IsNullOrWhiteSpace($base)) { Write-Error "URL vazia. Abortando."; exit 1 }

$nome = Read-Host "Nome da planta"
$tipo = Read-Host "Tipo da planta"
$tempMin = Read-Host "Temperatura mínima (numero)"
$tempMax = Read-Host "Temperatura máxima (numero)"
$umMin = Read-Host "Umidade minima (%)"
$umMax = Read-Host "Umidade maxima (%)"
$soloMin = Read-Host "Umidade solo minima (%)"
$soloMax = Read-Host "Umidade solo maxima (%)"

$body = @{
    nome = $nome
    tipo = $tipo
    temperaturaMinima = [double]$tempMin
    temperaturaMaxima = [double]$tempMax
    umidadeMinima = [double]$umMin
    umidadeMaxima = [double]$umMax
    umidadeSoloMinima = [double]$soloMin
    umidadeSoloMaxima = [double]$soloMax
}

$uri = "$base/api/cultivos"
Write-Host "Enviando POST para: $uri"
try {
    $resp = Invoke-RestMethod -Method Post -Uri $uri -Body ($body | ConvertTo-Json -Depth 5) -ContentType 'application/json' -Headers @{ Accept = 'application/json' } -ErrorAction Stop
    Write-Host "Cultivo criado com sucesso:" -ForegroundColor Green
    $resp | ConvertTo-Json -Depth 5 | Write-Host
} catch {
    Write-Host "Falha ao criar cultivo:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Read-Host "Pressione Enter para sair"
