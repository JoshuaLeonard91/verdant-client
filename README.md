# Verdant Flutter Client

Verdant Flutter Client is the Windows desktop client for Verdant. It connects
to the official Verdant network and to user-added self-host networks through
backend-scoped credentials and network-scoped runtime state.

This repository is a public source split from the private Verdant development
workspace. It contains the Flutter desktop client, generated protocol bindings,
Windows build helpers, and the public Windows release workflow. Private
operator tooling, local live-test harnesses, and production-only scripts are
not part of the public client surface.

## Requirements

- Flutter stable with Windows desktop support enabled.
- Visual Studio 2022 Build Tools with Desktop development with C++.
- Visual C++ ATL headers and libraries.
- NuGet CLI on `PATH` for WebView2-related Windows builds.

See [`docs/WINDOWS_BUILD.md`](docs/WINDOWS_BUILD.md) for Windows-specific setup.

## Build And Run

From the repository root:

```powershell
flutter pub get
flutter analyze
flutter test
```

Use the Windows wrapper when building or running the desktop app:

```powershell
.\scripts\flutter_windows.ps1 -Action doctor
.\scripts\flutter_windows.ps1 -Action build -Config debug
.\scripts\flutter_windows.ps1 -Action run
```

Release builds require certificate pin configuration. Set
`VERDANT_OFFICIAL_CERT_SHA256_PINS`, `INSTANCE_CERT_SHA256_PINS`, or
`VERDANT_CERT_SHA256_PINS` in the environment before building a release.

## Project Layout

- `lib/`: Flutter application code.
- `lib/generated/`: generated protocol bindings.
- `assets/`: application icons and bundled assets.
- `windows/`: Flutter Windows runner.
- `scripts/`: public build and release helper scripts. Local profiling,
  live-test, and private signing credential helpers are intentionally not part
  of the public client split.
- `docs/`: public client build and architecture notes.

The client treats local UI state as cache. Authentication, authorization,
membership, uploads, moderation, and media access must be enforced by the
owning backend and the native transport layer.

## Releases

Public Windows releases are built by GitHub Actions from immutable `v*.*.*`
tags. The release workflow builds the Flutter client on Windows, signs the
executable with Azure Artifact Signing through GitHub OIDC, packages a Windows
x64 installer, signs the installer, writes checksums, and publishes release
assets with GitHub artifact attestation.

Do not move or overwrite release tags after publication.
