<#
Creates desktop shortcuts for the Estufa Smart desktop utilities.
Run this script locally by right-click -> Run with PowerShell, or from PowerShell:
  powershell -ExecutionPolicy Bypass -File "create_shortcuts.ps1"
#>

# Get current script folder and user's desktop
# Use PSScriptRoot when available for reliable script directory
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
$desktop = [Environment]::GetFolderPath('Desktop')

$files = @(
  @{ Name = 'executar-desktop.bat'; Shortcut = 'Executar Estufa Smart.lnk' },
  @{ Name = 'remover_cultivo.bat'; Shortcut = 'Remover Planta - Estufa Smart.lnk' },
  @{ Name = 'remover_cultivo.ps1'; Shortcut = 'Remover Planta (PS) - Estufa Smart.lnk' },
  @{ Name = 'cadastrar_cultivo.bat'; Shortcut = 'Cadastrar Planta - Estufa Smart.lnk' },
  @{ Name = 'cadastrar_cultivo.ps1'; Shortcut = 'Cadastrar Planta (PS) - Estufa Smart.lnk' }
)

$shell = New-Object -ComObject WScript.Shell

foreach ($f in $files) {
    $source = Join-Path $scriptDir $f.Name
    if (-not (Test-Path $source)) {
      Write-Warning "Arquivo não encontrado: $source - pulando"
        continue
    }

    $shortcutPath = Join-Path $desktop $f.Shortcut
    try {
        $lnk = $shell.CreateShortcut($shortcutPath)
        $lnk.TargetPath = $source
        $lnk.WorkingDirectory = Split-Path $source
        $lnk.IconLocation = $source
        $lnk.Save()
        Write-Host "Atalho criado:" $shortcutPath
    } catch {
        Write-Warning "Falha ao criar atalho para $source : $_"
    }
}

Write-Host "Concluido. Verifique sua Area de Trabalho." -ForegroundColor Green
