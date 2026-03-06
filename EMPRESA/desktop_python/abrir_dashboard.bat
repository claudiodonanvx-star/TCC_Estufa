@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"

if not exist ".env" (
    echo [ERRO] Arquivo .env nao encontrado.
    echo Crie com base no .env.example antes de executar.
    pause
    exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in (`type ".env"`) do (
    set "KEY=%%~A"
    set "VAL=%%~B"
    if not "!KEY!"=="" (
        if /i not "!KEY:~0,1!"=="#" (
            set "!KEY!=!VAL!"
        )
    )
)

if "%DB_HOST%"=="" (
    echo [ERRO] DB_HOST nao definido no .env
    pause
    exit /b 1
)
if "%DB_USER%"=="" (
    echo [ERRO] DB_USER nao definido no .env
    pause
    exit /b 1
)
if "%DB_PASSWORD%"=="" (
    echo [ERRO] DB_PASSWORD nao definido no .env
    pause
    exit /b 1
)
if "%DB_NAME%"=="" (
    echo [ERRO] DB_NAME nao definido no .env
    pause
    exit /b 1
)

set "PYTHON_EXE="
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" set "PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" set "PYTHON_EXE=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
if not defined PYTHON_EXE set "PYTHON_EXE=python"

"%PYTHON_EXE%" --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado. Instale o Python 3.11+ e tente novamente.
    pause
    exit /b 1
)

"%PYTHON_EXE%" -c "import mysql.connector, dotenv" >nul 2>nul
if errorlevel 1 (
    echo Instalando dependencias...
    "%PYTHON_EXE%" -m pip install -r requirements.txt
    if errorlevel 1 (
        echo [ERRO] Falha ao instalar dependencias.
        pause
        exit /b 1
    )
)

echo Abrindo dashboard...
start "Empresa Dashboard" "%PYTHON_EXE%" "%~dp0app.py"

if errorlevel 1 (
    echo [ERRO] Falha ao executar o dashboard.
    pause
    exit /b 1
)

endlocal
exit /b 0
