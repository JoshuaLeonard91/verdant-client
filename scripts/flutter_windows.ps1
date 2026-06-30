param(
  [ValidateSet("build", "run", "doctor")]
  [string]$Action = "build",

  [ValidateSet("debug", "profile", "release")]
  [string]$Config = "debug",

  [switch]$EnableDriverExtension,

  [switch]$DisableDriverExtension,

  [switch]$NoCertificatePin,

  [string]$OfficialApiHost = "api.verdant.chat",

  [ValidateSet("primary", "secondary")]
  [string]$AppProfile = "primary",

  [switch]$NoAtlFallback,

  [string]$BuildName,

  [string]$BuildNumber,

  [string[]]$DartDefine = @()
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoClientRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$MonorepoRoot = Resolve-Path (Join-Path $RepoClientRoot "..\..")
$RepoRoot = if ((Test-Path -LiteralPath (Join-Path $MonorepoRoot "clients\flutter-client\pubspec.yaml")) -and
                (Test-Path -LiteralPath (Join-Path $MonorepoRoot "package.json"))) {
  $MonorepoRoot
} else {
  $RepoClientRoot
}
$VsWhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"

function Get-VisualStudioInstances {
  if (!(Test-Path -LiteralPath $VsWhere)) {
    throw "vswhere.exe was not found. Install Visual Studio 2022 Build Tools with Desktop development with C++."
  }

  $json = & $VsWhere -all -products * -format json
  if ($LASTEXITCODE -ne 0) {
    throw "vswhere.exe failed with exit code $LASTEXITCODE."
  }

  $instances = $json | ConvertFrom-Json
  foreach ($instance in $instances) {
    $instance
  }
}

function Get-MsvcAtlRoot {
  param([object[]]$Instances)

  $candidates = @()
  foreach ($instance in $Instances) {
    $toolsRoot = Join-Path $instance.installationPath "VC\Tools\MSVC"
    if (!(Test-Path -LiteralPath $toolsRoot)) {
      continue
    }

    Get-ChildItem -LiteralPath $toolsRoot -Directory |
      Sort-Object Name -Descending |
      ForEach-Object {
        $atlInclude = Join-Path $_.FullName "atlmfc\include\atlstr.h"
        $atlLib = Join-Path $_.FullName "atlmfc\lib\x64\atls.lib"
        if ((Test-Path -LiteralPath $atlInclude) -and
            (Test-Path -LiteralPath $atlLib)) {
          $isBuildTools = $instance.productId -eq "Microsoft.VisualStudio.Product.BuildTools"
          $candidates += [pscustomobject]@{
            IsBuildTools = $isBuildTools
            DisplayName = $instance.displayName
            InstallationPath = $instance.installationPath
            AtlRoot = Join-Path $_.FullName "atlmfc"
            Version = $_.Name
          }
        }
      }
  }

  return $candidates |
    Sort-Object @{ Expression = "IsBuildTools"; Descending = $true },
                @{ Expression = "Version"; Descending = $true } |
    Select-Object -First 1
}

function Set-AtlCompilerEnvironment {
  param([object]$AtlCandidate)

  $include = Join-Path $AtlCandidate.AtlRoot "include"
  $lib = Join-Path $AtlCandidate.AtlRoot "lib\x64"

  $env:CL = "/I`"$include`" $env:CL"
  $env:LINK = "/LIBPATH:`"$lib`" $env:LINK"

  Write-Host "Using ATL from $($AtlCandidate.DisplayName): $($AtlCandidate.AtlRoot)"
  if (-not $AtlCandidate.IsBuildTools) {
    Write-Warning "ATL is not installed in Visual Studio Build Tools. This script is using another Visual Studio instance. For permanent Build Tools setup, run Visual Studio Installer as Administrator and add Microsoft.VisualStudio.Component.VC.ATL."
  }
}

function Read-DotEnvValue {
  param(
    [string]$Path,
    [string]$Name
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }

  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -match "^\s*#") {
      continue
    }
    if ($line -match ("^\s*" + [regex]::Escape($Name) + "\s*=\s*(.*)\s*$")) {
      $value = $matches[1].Trim()
      if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
          ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      if (-not [string]::IsNullOrWhiteSpace($value)) {
        return $value
      }
    }
  }

  return $null
}

function Normalize-CertificatePins {
  param([string]$Raw)

  if ([string]::IsNullOrWhiteSpace($Raw)) {
    return $null
  }

  $pins = @()
  foreach ($entry in $Raw.Split(",")) {
    $value = $entry.Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
      continue
    }
    if ($value.StartsWith("sha256/", [StringComparison]::Ordinal)) {
      try {
        $bytes = [Convert]::FromBase64String($value.Substring(7).Trim())
      } catch {
        throw "Certificate pin is not valid sha256/base64."
      }
      if ($bytes.Length -ne 32) {
        throw "Certificate pin must decode to 32 bytes."
      }
      $value = -join ($bytes | ForEach-Object { $_.ToString("x2") })
    } else {
      $value = $value.Replace(":", "").ToLowerInvariant()
    }
    if ($value.Length -ne 64 -or $value -notmatch "^[a-f0-9]{64}$") {
      throw "Certificate pin must be a 64-character SHA-256 hex fingerprint."
    }
    $pins += $value
  }

  $pins = @($pins | Sort-Object -Unique)
  if ($pins.Count -eq 0) {
    return $null
  }
  if ($pins.Count -gt 8) {
    throw "Certificate pin list must contain at most 8 entries."
  }
  return ($pins -join ",")
}

function Get-LeafCertificateSha256Hex {
  param([string]$HostName)

  $tcp = [System.Net.Sockets.TcpClient]::new()
  try {
    $tcp.Connect($HostName, 443)
    $ssl = [System.Net.Security.SslStream]::new(
      $tcp.GetStream(),
      $false,
      ({ param($sender, $certificate, $chain, $errors)
          return $errors -eq [System.Net.Security.SslPolicyErrors]::None
       })
    )
    try {
      $ssl.AuthenticateAsClient($HostName)
      $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($ssl.RemoteCertificate)
      $sha = [System.Security.Cryptography.SHA256]::Create()
      try {
        $hash = $sha.ComputeHash($cert.RawData)
      } finally {
        $sha.Dispose()
      }
      return -join ($hash | ForEach-Object { $_.ToString("x2") })
    } finally {
      $ssl.Dispose()
    }
  } finally {
    $tcp.Dispose()
  }
}

function Get-ConfiguredCertificatePins {
  param([bool]$AllowLiveFallback)

  foreach ($name in @("VERDANT_OFFICIAL_CERT_SHA256_PINS", "INSTANCE_CERT_SHA256_PINS", "VERDANT_CERT_SHA256_PINS")) {
    $normalized = Normalize-CertificatePins ([Environment]::GetEnvironmentVariable($name))
    if ($null -ne $normalized) {
      Write-Host "Using Flutter certificate pins from environment variable $name."
      return $normalized
    }
  }

  foreach ($file in @((Join-Path $RepoRoot ".env"), (Join-Path $RepoRoot ".env.dev.local"))) {
    foreach ($name in @("VERDANT_OFFICIAL_CERT_SHA256_PINS", "INSTANCE_CERT_SHA256_PINS", "VERDANT_CERT_SHA256_PINS")) {
      $normalized = Normalize-CertificatePins (Read-DotEnvValue -Path $file -Name $name)
      if ($null -ne $normalized) {
        Write-Host "Using Flutter certificate pins from $(Split-Path -Leaf $file): $name."
        return $normalized
      }
    }
  }

  if ($AllowLiveFallback) {
    $pin = Get-LeafCertificateSha256Hex -HostName $OfficialApiHost
    Write-Warning "Using live TLS certificate fingerprint for dev Flutter build. Release builds require configured pins from env or .env."
    return $pin
  }

  return $null
}

$instances = @(Get-VisualStudioInstances)
$atl = Get-MsvcAtlRoot -Instances $instances
if ($null -eq $atl) {
  throw "No Visual Studio ATL installation was found. Install Microsoft.VisualStudio.Component.VC.ATL."
}

if ($NoAtlFallback -and -not $atl.IsBuildTools) {
  throw "Build Tools ATL is missing. Re-run without -NoAtlFallback or install Microsoft.VisualStudio.Component.VC.ATL into Build Tools."
}

Set-AtlCompilerEnvironment -AtlCandidate $atl

if ($Action -eq "doctor") {
  Write-Host "Windows Flutter build prerequisites look usable."
  exit 0
}

Push-Location $RepoClientRoot
try {
  $certificatePinArgs = @()
  if (-not $NoCertificatePin) {
    $isReleaseBuild = $Action -eq "build" -and $Config -eq "release"
    $pins = Get-ConfiguredCertificatePins -AllowLiveFallback:(-not $isReleaseBuild)
    if ([string]::IsNullOrWhiteSpace($pins)) {
      throw "Flutter certificate pinning is required for release builds. Set VERDANT_OFFICIAL_CERT_SHA256_PINS or update .env before building."
    }
    $certificatePinArgs += "--dart-define=VERDANT_OFFICIAL_CERT_SHA256_PINS=$pins"
  } else {
    if ($Action -eq "build" -and $Config -eq "release") {
      throw "-NoCertificatePin is not allowed for release builds."
    }
    Write-Warning "Flutter certificate pinning disabled for this non-release command."
  }

  $dartDefineArgs = @()
  $dartDefineArgs += $certificatePinArgs
  foreach ($define in $DartDefine) {
    if ([string]::IsNullOrWhiteSpace($define)) {
      continue
    }
    if ($define -notmatch "^[A-Za-z_][A-Za-z0-9_]*=.*$") {
      throw "DartDefine entries must use NAME=value syntax, got '$define'."
    }
    $dartDefineArgs += "--dart-define=$define"
  }

  if ($Action -eq "run") {
    if ($EnableDriverExtension -and $DisableDriverExtension) {
      throw "Use either -EnableDriverExtension or -DisableDriverExtension, not both."
    }
    $runConfigArg = "--$Config"
    $entrypointArgs = @()
    if ($AppProfile -ne "primary") {
      $entrypointArgs += "-a"
      $entrypointArgs += "--verdant-profile=$AppProfile"
    }
    if ($EnableDriverExtension) {
      & flutter run -d windows $runConfigArg @dartDefineArgs @entrypointArgs -t test_driver/driver_main.dart
    } else {
      & flutter run -d windows $runConfigArg @dartDefineArgs @entrypointArgs
    }
    exit $LASTEXITCODE
  }

  $versionArgs = @()
  if (-not [string]::IsNullOrWhiteSpace($BuildName)) {
    if ($BuildName -notmatch '^\d+\.\d+\.\d+$') {
      throw "BuildName must be semver, got '$BuildName'."
    }
    $versionArgs += "--build-name=$BuildName"
  }
  if (-not [string]::IsNullOrWhiteSpace($BuildNumber)) {
    if ($BuildNumber -notmatch '^\d+$') {
      throw "BuildNumber must be numeric, got '$BuildNumber'."
    }
    $versionArgs += "--build-number=$BuildNumber"
  }

  & flutter build windows "--$Config" @dartDefineArgs @versionArgs
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
