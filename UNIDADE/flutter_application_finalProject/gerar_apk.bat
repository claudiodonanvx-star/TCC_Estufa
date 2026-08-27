@echo off
setlocal
cd /d "%~dp0"

echo Configurando caminhos do Android...
set "ANDROID_SDK_ROOT=%LOCALAPPDATA%\Android\Sdk"
if exist "%ANDROID_SDK_ROOT%" (
  set "ANDROID_HOME=%ANDROID_SDK_ROOT%"
) else (
  set "ANDROID_SDK_ROOT=%USERPROFILE%\AppData\Local\Android\Sdk"
  if exist "%ANDROID_SDK_ROOT%" (
    set "ANDROID_HOME=%ANDROID_SDK_ROOT%"
  )
)

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter nao encontrado no PATH.
  echo Instale o Flutter e adicione ao PATH antes de continuar.
  pause
  exit /b 1
)

echo Baixando dependencias...
flutter pub get

echo Aplicando icone do app...
flutter pub run flutter_launcher_icons:main

echo Gerando APK de release...
flutter build apk --release

if exist "build\app\outputs\flutter-apk\app-release.apk" (
  echo.
  echo APK gerado em:
  echo %cd%\build\app\outputs\flutter-apk\app-release.apk
) else (
  echo.
  echo APK nao foi encontrado.
  echo Verifique se o Android SDK/Android Studio estao instalados.
)

pause
