# Flutter Windows Build

The Flutter desktop experiment uses `flutter_secure_storage` for desktop
credentials. On Windows, that plugin needs the Visual C++ ATL headers and
libraries (`atlstr.h`, `atls.lib`) at build time.

Announcement feed video playback uses `flutter_inappwebview` on Windows. That
plugin downloads native WebView2 build packages through `nuget.exe`, so the
NuGet CLI must be on `PATH` before running a Windows build. WebView2 Runtime is
also required at app runtime; it is installed by default on Windows 11, but
older Windows 10 machines may need the Evergreen Runtime installed separately.

## Preferred Setup

Install ATL into Visual Studio Build Tools:

```powershell
"C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe" modify `
  --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools" `
  --add Microsoft.VisualStudio.Component.VC.ATL `
  --quiet `
  --norestart
```

Run that command from an elevated Administrator shell. Non-elevated quiet or
passive Visual Studio Installer commands fail with exit code `5007`.

Install NuGet CLI with your preferred system package manager, or place
`nuget.exe` in a local tools directory and prepend that directory to `PATH` for
the build shell:

```powershell
$env:PATH = "C:\path\to\nuget;$env:PATH"
.\scripts\flutter_windows.ps1 -Action build -Config debug
```

## Repo Build Wrapper

If ATL is installed in another Visual Studio instance, use the repo wrapper. It
detects ATL with `vswhere`, sets `CL`/`LINK` for the current command, and then
runs Flutter:

```powershell
.\scripts\flutter_windows.ps1 -Action doctor
.\scripts\flutter_windows.ps1 -Action build -Config debug
.\scripts\flutter_windows.ps1 -Action run
```

The wrapper prefers Build Tools ATL. If Build Tools is missing ATL but Visual
Studio Community has it, the wrapper uses Community and prints a warning.

The wrapper also injects Flutter certificate pins automatically for both dev and
release commands. It resolves pins in this order:

1. `VERDANT_OFFICIAL_CERT_SHA256_PINS`, `INSTANCE_CERT_SHA256_PINS`, or
   `VERDANT_CERT_SHA256_PINS` from the current environment.
2. Local `.env` or `.env.dev.local`.
3. A live `api.verdant.chat` TLS certificate fingerprint for non-release dev
   commands only.

## Release Flow

Use the release wrapper when validating a publishable Windows build:

```powershell
.\scripts\release_flutter_windows.ps1 -NoBuild
.\scripts\release_flutter_windows.ps1 -SkipSigning -SkipSignatureVerify
```

The release wrapper keeps the Flutter version aligned with the desktop client
release version in the private monorepo. In the standalone public Flutter repo,
it validates `pubspec.yaml` against `lib/app/client_version.dart` directly.
For local diagnostics it can run the certificate-pinned release build and create
a versioned archive. Signed public releases should be produced by the GitHub
Actions workflow.

Public GitHub release automation should use the `signed-windows-release`
environment and GitHub OIDC instead of a checked-in or repo-level secret.
That public workflow signs the built `verdant_flutter.exe` with Azure Artifact
Signing before packaging the release archive and publishes the archive,
`SHA256SUMS`, and GitHub artifact attestation to the tag's GitHub Release.

Release builds fail if no configured pin is available from environment or local
env files. Use `-NoCertificatePin` only for non-release local diagnostics.

To require the permanent Build Tools installation and fail when it is missing,
run:

```powershell
.\scripts\flutter_windows.ps1 -Action doctor -NoAtlFallback
```
