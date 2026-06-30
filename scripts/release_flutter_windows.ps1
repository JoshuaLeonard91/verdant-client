param(
  [string]$Version,
  [switch]$Bump,
  [switch]$NoBuild,
  [switch]$SkipSigning,
  [switch]$SkipSignatureVerify,
  [switch]$NoAtlFallback,
  [string]$SigningHelper
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FlutterRoot = (Resolve-Path -LiteralPath (Join-Path $ScriptDir "..")).Path
$CandidateRepoRoot = (Resolve-Path -LiteralPath (Join-Path $FlutterRoot "..\..")).Path
$IsMonorepoLayout = (Test-Path -LiteralPath (Join-Path $CandidateRepoRoot "clients\flutter-client\pubspec.yaml")) -and
  (Test-Path -LiteralPath (Join-Path $CandidateRepoRoot "packages\client\package.json"))
$RepoRoot = if ($IsMonorepoLayout) { $CandidateRepoRoot } else { $FlutterRoot }
$ClientRoot = if ($IsMonorepoLayout) { Join-Path $RepoRoot "packages\client" } else { "" }
$PackagePath = if ($IsMonorepoLayout) { Join-Path $ClientRoot "package.json" } else { "" }
$TauriConfigPath = if ($IsMonorepoLayout) { Join-Path $ClientRoot "src-tauri\tauri.conf.json" } else { "" }
$PubspecPath = Join-Path $FlutterRoot "pubspec.yaml"
$ClientVersionPath = Join-Path $FlutterRoot "lib\app\client_version.dart"
$BumpScript = if ($IsMonorepoLayout) { Join-Path $ClientRoot "scripts\bump-version.ps1" } else { "" }
$FlutterWindowsScript = Join-Path $FlutterRoot "scripts\flutter_windows.ps1"
$CreateInstallerScript = Join-Path $FlutterRoot "scripts\create_windows_installer.ps1"
$DefaultSigningHelper = if ($IsMonorepoLayout -and (Test-Path -LiteralPath (Join-Path $ClientRoot "src-tauri\sign-windows.ps1"))) {
  Join-Path $ClientRoot "src-tauri\sign-windows.ps1"
} else {
  ""
}
$ResolvedSigningHelper = if (-not [string]::IsNullOrWhiteSpace($SigningHelper)) {
  $SigningHelper
} elseif (-not [string]::IsNullOrWhiteSpace($env:VERDANT_WINDOWS_SIGNING_HELPER)) {
  $env:VERDANT_WINDOWS_SIGNING_HELPER
} else {
  $DefaultSigningHelper
}
$SignToolPath = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe"

function Write-Step([string]$Step, [string]$Message) {
  Write-Host ("[{0}] {1}" -f $Step, $Message)
}

function Require-File([string]$Path, [string]$Description) {
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "$Description not found: $Path"
  }
}

function Read-JsonFile([string]$Path) {
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Assert-Semver([string]$Value, [string]$Name) {
  if ($Value -notmatch '^\d+\.\d+\.\d+$') {
    throw "$Name must be semver, got '$Value'."
  }
}

function Get-FlutterBuildNumber([string]$Value) {
  $parts = $Value.Split(".")
  return $parts[$parts.Length - 1]
}

function Read-FlutterPubspecVersion([string]$Path) {
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?\s*$') {
      return [pscustomobject]@{
        BuildName = $matches[1]
        BuildNumber = if ($matches.Count -gt 2) { $matches[2] } else { "" }
      }
    }
  }

  throw "Flutter pubspec version line not found or not semver: $Path"
}

function Read-FlutterClientVersion([string]$Path) {
  $content = Get-Content -Raw -LiteralPath $Path
  if ($content -match "const\s+verdantClientVersion\s*=\s*'([^']+)';") {
    return $matches[1]
  }

  throw "Flutter verdantClientVersion constant not found: $Path"
}

function Set-FlutterPubspecVersion([string]$Path, [string]$Version) {
  $buildNumber = Get-FlutterBuildNumber $Version
  $content = Get-Content -Raw -LiteralPath $Path
  $updated = [regex]::Replace(
    $content,
    '(?m)^version:\s*[0-9]+\.[0-9]+\.[0-9]+(?:\+[0-9]+)?\s*$',
    "version: $Version+$buildNumber",
    1
  )
  if ($updated -eq $content) {
    throw "Flutter pubspec version line not found or not semver: $Path"
  }
  [IO.File]::WriteAllText($Path, $updated, [Text.UTF8Encoding]::new($false))
}

function Set-FlutterClientVersion([string]$Path, [string]$Version) {
  $content = Get-Content -Raw -LiteralPath $Path
  $updated = [regex]::Replace(
    $content,
    "const\s+verdantClientVersion\s*=\s*'[^']+';",
    "const verdantClientVersion = '$Version';",
    1
  )
  if ($updated -eq $content) {
    throw "Flutter verdantClientVersion constant not found: $Path"
  }
  [IO.File]::WriteAllText($Path, $updated, [Text.UTF8Encoding]::new($false))
}

function Set-StandaloneFlutterVersion([string]$Version) {
  Write-Step "version" "Bumping standalone Flutter client version to $Version."
  Set-FlutterPubspecVersion -Path $PubspecPath -Version $Version
  Set-FlutterClientVersion -Path $ClientVersionPath -Version $Version
}

function Assert-AuthenticodeSignature([string]$Path, [string]$Description) {
  Require-File $SignToolPath "SignTool"
  Write-Step "verify" "Verifying Authenticode signature on $Description..."
  & $SignToolPath verify /pa /v $Path
  if ($LASTEXITCODE -ne 0) {
    throw "Authenticode verification failed for $Path"
  }

  $signature = Get-AuthenticodeSignature -FilePath $Path
  if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid) {
    throw "PowerShell Authenticode verification failed for $Path`: $($signature.StatusMessage)"
  }
  if (-not $signature.SignerCertificate) {
    throw "Authenticode signature is missing a signer certificate: $Path"
  }
  if (-not $signature.TimeStamperCertificate) {
    throw "Authenticode signature is missing a timestamp countersignature: $Path"
  }
}

if ($Bump) {
  if ([string]::IsNullOrWhiteSpace($Version)) {
    throw "Pass -Version when using -Bump."
  }
  Assert-Semver -Value $Version -Name "Version"
  if ($IsMonorepoLayout) {
    Write-Step "version" "Bumping Tauri and Flutter client versions to $Version."
    & $BumpScript -Version $Version
    if ($LASTEXITCODE -ne 0) {
      throw "Version bump failed with exit code $LASTEXITCODE."
    }
  } else {
    Set-StandaloneFlutterVersion -Version $Version
  }
}

$flutterPubspec = Read-FlutterPubspecVersion $PubspecPath
$flutterClientVersion = Read-FlutterClientVersion $ClientVersionPath

Assert-Semver -Value $flutterPubspec.BuildName -Name "clients/flutter-client/pubspec.yaml version"
Assert-Semver -Value $flutterClientVersion -Name "clients/flutter-client client version"

if ($IsMonorepoLayout) {
  $package = Read-JsonFile $PackagePath
  $tauriConfig = Read-JsonFile $TauriConfigPath
  $packageVersion = [string]$package.version
  $tauriVersion = [string]$tauriConfig.version

  Assert-Semver -Value $packageVersion -Name "packages/client/package.json version"
  Assert-Semver -Value $tauriVersion -Name "packages/client/src-tauri/tauri.conf.json version"

  if ($packageVersion -ne $tauriVersion) {
    throw "Client version mismatch: package.json=$packageVersion tauri.conf.json=$tauriVersion"
  }
  if ($packageVersion -ne $flutterPubspec.BuildName) {
    throw "Flutter pubspec version $($flutterPubspec.BuildName) does not match client version $packageVersion."
  }
  if ($packageVersion -ne $flutterClientVersion) {
    throw "Flutter client version $flutterClientVersion does not match client version $packageVersion."
  }

  $resolvedVersion = $packageVersion
} else {
  if ($flutterPubspec.BuildName -ne $flutterClientVersion) {
    throw "Flutter client version $flutterClientVersion does not match pubspec version $($flutterPubspec.BuildName)."
  }

  $resolvedVersion = $flutterPubspec.BuildName
}

$expectedBuildNumber = Get-FlutterBuildNumber $resolvedVersion
if ($flutterPubspec.BuildNumber -ne $expectedBuildNumber) {
  throw "Flutter pubspec build number $($flutterPubspec.BuildNumber) does not match expected $expectedBuildNumber."
}

if (-not [string]::IsNullOrWhiteSpace($Version) -and $Version -ne $resolvedVersion) {
  throw "Requested version $Version does not match checked-in client version $resolvedVersion. Use -Bump to update client version files."
}

$Version = $resolvedVersion
$willBuild = -not $NoBuild.IsPresent
$willSign = $willBuild -and -not $SkipSigning.IsPresent
Write-Step "preflight" "version=$Version build=$willBuild signing=$willSign"

if (-not $NoBuild) {
  Write-Step "build" "Building Flutter Windows release with certificate pin injection."
  if ($NoAtlFallback) {
    & $FlutterWindowsScript -Action build -Config release -BuildName $Version -BuildNumber $expectedBuildNumber -NoAtlFallback
  } else {
    & $FlutterWindowsScript -Action build -Config release -BuildName $Version -BuildNumber $expectedBuildNumber
  }
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter Windows release build failed with exit code $LASTEXITCODE."
  }
} else {
  Write-Step "build" "Skipping build; validating version alignment only."
  Write-Step "done" "Flutter Windows release preflight completed for $Version."
  exit 0
}

$releaseDir = Join-Path $FlutterRoot "build\windows\x64\runner\Release"
$exePath = Join-Path $releaseDir "verdant_flutter.exe"

Require-File $exePath "Flutter Windows release executable"
Require-File $CreateInstallerScript "Flutter Windows installer helper"

if (-not $SkipSigning) {
  Write-Step "sign" "Signing Flutter Windows executable with the existing Azure Artifact Signing profile."
  if ([string]::IsNullOrWhiteSpace($ResolvedSigningHelper)) {
    throw "Local signing is not configured for this source tree. Use the public GitHub release workflow for signed builds, set VERDANT_WINDOWS_SIGNING_HELPER to a local signing script, or pass -SkipSigning for local diagnostics."
  }
  Require-File $ResolvedSigningHelper "Windows signing helper"
  & $ResolvedSigningHelper $exePath
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter executable signing failed with exit code $LASTEXITCODE."
  }

  if (-not $SkipSignatureVerify) {
    Assert-AuthenticodeSignature $exePath "Flutter Windows executable"
  }
} elseif (-not $SkipSignatureVerify) {
  Write-Step "verify" "Skipping signing; verifying any existing Flutter Windows executable signature."
  Assert-AuthenticodeSignature $exePath "Flutter Windows executable"
}

$artifactDir = Join-Path $FlutterRoot "build\windows\x64\release-artifacts"
New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
$installerPath = Join-Path $artifactDir ("VerdantFlutter_{0}_windows_x64_setup.exe" -f $Version)
if (Test-Path -LiteralPath $installerPath) {
  Remove-Item -LiteralPath $installerPath -Force
}

Write-Step "package" "Creating Flutter Windows installer."
& $CreateInstallerScript -Version $Version -ReleaseDir $releaseDir -OutputDir $artifactDir
if ($LASTEXITCODE -ne 0) {
  throw "Flutter Windows installer packaging failed with exit code $LASTEXITCODE."
}
Require-File $installerPath "Flutter Windows installer"

if (-not $SkipSigning) {
  Write-Step "sign" "Signing Flutter Windows installer with the existing Azure Artifact Signing profile."
  & $ResolvedSigningHelper $installerPath
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter installer signing failed with exit code $LASTEXITCODE."
  }

  if (-not $SkipSignatureVerify) {
    Assert-AuthenticodeSignature $installerPath "Flutter Windows installer"
  }
} elseif (-not $SkipSignatureVerify) {
  Write-Step "verify" "Skipping signing; verifying any existing Flutter Windows installer signature."
  Assert-AuthenticodeSignature $installerPath "Flutter Windows installer"
}

Write-Step "artifacts" "executable=$exePath"
Write-Step "artifacts" "installer=$installerPath"
Write-Step "done" "Flutter Windows release workflow completed for $Version."
