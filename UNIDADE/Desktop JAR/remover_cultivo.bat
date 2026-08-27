@echo off
setlocal
echo ==== Remover Cultivo - Estufa Smart ====
set /p BASEURL=Digite a URL base da API (ex: https://api-estufa.onrender.com): 
if "%BASEURL%"=="" (
  echo URL vazia. Abortando.
  pause
  exit /b 1
)
set /p ID=Digite o ID do cultivo a remover: 
if "%ID%"=="" (
  echo ID vazio. Abortando.
  pause
  exit /b 1
)

echo Enviando requisição DELETE para %BASEURL%/api/cultivos/%ID% ...
curl -s -X DELETE "%BASEURL%/api/cultivos/%ID%" -w "\nHTTP:%{http_code}\n"
echo.
echo Pronto.
pause
