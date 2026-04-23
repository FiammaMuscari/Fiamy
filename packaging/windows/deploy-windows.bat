@echo off
setlocal

set ROOT_DIR=%~dp0..\..
set BUILD_DIR=%ROOT_DIR%\build-release-windows
set EXE_PATH=%BUILD_DIR%\fiamy.exe

if not exist "%EXE_PATH%" (
    echo [ERROR] No se encontro %EXE_PATH%
    echo Primero compila la version Release en Windows.
    exit /b 1
)

echo [INFO] Ejecutando windeployqt...
windeployqt "%EXE_PATH%"

echo [OK] Deploy base completado.
echo [INFO] Revisa DLLs, plugins multimedia y Qt6 antes de generar instalador.
