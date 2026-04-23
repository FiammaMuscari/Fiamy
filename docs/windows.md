# 🪟 Windows

This guide is kept as a reference for the `windows-legacy` branch.

## Goal

Preserve the historical Windows flow without mixing it with the Linux changes.

## Next use

- review which parts are still relevant
- separate Windows deployment
- document the required Qt6 / DLL dependencies

## Recommended minimal flow

On Windows, the idea is to use `windeployqt` on the release executable:

```bat
packaging\windows\deploy-windows.bat
```

That script is the base for the later packaging step.

