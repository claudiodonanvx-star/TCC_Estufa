@echo off
REM Atalho para executar o desktop Java na pasta UNIDADE\desktop_java_unidade usando o Gradle wrapper
pushd "%~dp0..\desktop_java_unidade" || (
  echo Diretorio do projeto nao encontrado.
  pause
  exit /b 1
)

if not exist "gradlew.bat" (
  echo gradlew.bat nao encontrado em %CD%.
  popd
  pause
  exit /b 1
)

echo Iniciando aplicativo desktop...
call gradlew.bat run
popd
pause
