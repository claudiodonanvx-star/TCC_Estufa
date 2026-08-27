param()
Write-Host "==== Remover Cultivo - Estufa Smart (PowerShell) ====" -ForegroundColor Cyan
$base = Read-Host "Digite a URL base da API (ex: https://api-estufa.onrender.com)"
if ([string]::IsNullOrWhiteSpace($base)) { Write-Error "URL vazia. Abortando."; exit 1 }
$id = Read-Host "Digite o ID do cultivo a remover"
if ([string]::IsNullOrWhiteSpace($id)) { Write-Error "ID vazio. Abortando."; exit 1 }

$uri = "$base/api/cultivos/$id"
Write-Host "Enviando DELETE para: $uri"
try {
    $resp = Invoke-RestMethod -Method Delete -Uri $uri -Headers @{ Accept = 'application/json' } -ErrorAction Stop
    Write-Host "Resposta:" -ForegroundColor Green
    $resp | ConvertTo-Json -Depth 5 | Write-Host
} catch {
    Write-Host "Falha ao remover:" -ForegroundColor Red
    if ($_.Exception.Response) {
        try { $_.Exception.Response.GetResponseStream() | 
                ForEach-Object { [System.IO.StreamReader]::new($_).ReadToEnd() } | Write-Host } catch {}
    } else {
        Write-Host $_.Exception.Message
    }
}

Read-Host "Pressione Enter para sair"
