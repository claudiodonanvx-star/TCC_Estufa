@echo off
setlocal
echo ==== Cadastrar Cultivo - Estufa Smart ====
set /p BASEURL=Digite a URL base da API (ex: https://api-estufa.onrender.com): 
if "%BASEURL%"=="" (
  echo URL vazia. Abortando.
  pause
  exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0cadastrar_cultivo.ps1"

pause
