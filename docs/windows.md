# 🪟 Windows

Esta guía queda como referencia para la rama `windows-legacy`.

## Objetivo

Preservar el flujo histórico de Windows sin mezclarlo con los cambios Linux.

## Próximo uso

- revisar qué partes siguen vigentes
- separar deploy de Windows
- documentar dependencias Qt6 / DLLs necesarias

## Flujo mínimo recomendado

En Windows, la idea es usar `windeployqt` sobre el ejecutable release:

```bat
packaging\windows\deploy-windows.bat
```

Ese script queda como base para el empaquetado posterior.
