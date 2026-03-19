param(
    [int]$IntervalSeconds = 3,
    [int]$Limit = 10,
    [string]$ApiBaseUrl = "http://localhost:8080"
)

$ErrorActionPreference = "Stop"

while ($true) {
    Clear-Host
    Write-Host "API: $ApiBaseUrl"
    Write-Host "Atualizado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""

    try {
        $dados = Invoke-RestMethod -Uri "$ApiBaseUrl/api/dados" -Method Get

        $filtrados = $dados |
            Where-Object {
                $_.significado -and
                $_.significado -notmatch 'indefinida|teste solo'
            } |
            Select-Object -Last $Limit id, temperatura, umidade, umidadeSolo, significado

        if ($filtrados) {
            $filtrados | Format-Table -AutoSize
        }
        else {
            Write-Host "Nenhum registro valido encontrado ainda."
        }
    }
    catch {
        Write-Host "Erro ao consultar API: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds $IntervalSeconds
}