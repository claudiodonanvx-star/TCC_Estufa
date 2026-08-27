@echo off
REM Menu para utilitários Desktop - Estufa Smart
setlocal enabledelayedexpansion
:menu
cls
echo ===============================
echo  Estufa Smart - Desktop Utilities
echo ===============================
echo 1) Rodar aplicacao desktop (Gradle run)
echo 2) Cadastrar planta (via API)
echo 3) Remover planta (via API)
echo 4) Abrir pasta Desktop JAR
echo 5) Sair
set /p choice=Escolha uma opcao [1-5]: 
if "%choice%"=="1" goto run_app
if "%choice%"=="2" goto cadastrar
if "%choice%"=="3" goto remover
if "%choice%"=="4" goto abrir_pasta
if "%choice%"=="5" goto fim
goto menu

:run_app
pushd "%~dp0..\desktop_java_unidade" || (
  echo Diretorio do projeto nao encontrado.
  pause
  goto menu
)
if not exist "gradlew.bat" (
  echo gradlew.bat nao encontrado em %CD%.
  popd
  pause
  goto menu
)
echo Iniciando aplicativo desktop...
call gradlew.bat run
popd
pause
goto menu

:cadastrar
echo Abrindo formulario de cadastro...
start "" "%~dp0cadastrar_cultivo.bat"
goto menu

:remover
echo Abrindo utilitario de remocao...
start "" "%~dp0remover_cultivo.bat"
goto menu

:abrir_pasta
explorer "%~dp0"
goto menu

:fim
endlocal
exit /b 0
