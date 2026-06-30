param(
  [Parameter(Mandatory = $true)]
  [string]$Version,
  [string]$ReleaseDir,
  [string]$OutputDir,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FlutterRoot = (Resolve-Path -LiteralPath (Join-Path $ScriptDir "..")).Path

function Write-Step([string]$Step, [string]$Message) {
  Write-Host ("[{0}] {1}" -f $Step, $Message)
}

function Require-File([string]$Path, [string]$Description) {
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "$Description not found: $Path"
  }
}

function Assert-Semver([string]$Value) {
  if ($Value -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must be semver, got '$Value'."
  }
}

function Resolve-IsccPath {
  $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $programFilesX86 = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86)
  $programFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
  $candidates = @()
  if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
    $candidates += (Join-Path $programFilesX86 "Inno Setup 6\ISCC.exe")
  }
  if (-not [string]::IsNullOrWhiteSpace($programFiles)) {
    $candidates += (Join-Path $programFiles "Inno Setup 6\ISCC.exe")
  }

  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) {
      return $candidate
    }
  }

  throw "Inno Setup compiler not found. Install Inno Setup 6 or ensure ISCC.exe is on PATH."
}

function Escape-InnoQuoted([string]$Value) {
  return $Value.Replace('"', '""')
}

Assert-Semver $Version

if ([string]::IsNullOrWhiteSpace($ReleaseDir)) {
  $ReleaseDir = Join-Path $FlutterRoot "build\windows\x64\runner\Release"
}
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
  $OutputDir = Join-Path $FlutterRoot "build\windows\x64\release-artifacts"
}

$ReleaseDir = (Resolve-Path -LiteralPath $ReleaseDir).Path
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$OutputDir = (Resolve-Path -LiteralPath $OutputDir).Path

$exePath = Join-Path $ReleaseDir "verdant_flutter.exe"
Require-File $exePath "Flutter Windows release executable"

$installerBaseName = "VerdantFlutter_{0}_windows_x64_setup" -f $Version
$installerPath = Join-Path $OutputDir "$installerBaseName.exe"
$issPath = Join-Path $OutputDir "verdant_flutter_installer_$Version.iss"
$iconPath = Join-Path $FlutterRoot "windows\runner\resources\app_icon.ico"

$setupIconLine = if (Test-Path -LiteralPath $iconPath) {
  "SetupIconFile=$(Escape-InnoQuoted $iconPath)"
} else {
  ""
}

$issLines = @(
  "#define MyAppName ""Verdant""",
  "#define MyAppVersion ""$Version""",
  "#define MyAppPublisher ""Verdant""",
  "#define MyAppExeName ""verdant_flutter.exe""",
  "",
  "[Setup]",
  "AppId={{BDE71C15-459F-41E4-85F6-8E04D378A2A1}",
  "AppName={#MyAppName}",
  "AppVersion={#MyAppVersion}",
  "AppPublisher={#MyAppPublisher}",
  "DefaultDirName={localappdata}\Programs\Verdant",
  "DefaultGroupName={#MyAppName}",
  "DisableProgramGroupPage=yes",
  "OutputDir=$(Escape-InnoQuoted $OutputDir)",
  "OutputBaseFilename=$installerBaseName",
  "Compression=lzma2",
  "SolidCompression=yes",
  "ArchitecturesAllowed=x64",
  "ArchitecturesInstallIn64BitMode=x64",
  "PrivilegesRequired=lowest",
  "WizardStyle=modern",
  "UninstallDisplayIcon={app}\{#MyAppExeName}",
  "UninstallDisplayName={#MyAppName}",
  "CloseApplications=yes",
  "SetupLogging=yes"
)

if (-not [string]::IsNullOrWhiteSpace($setupIconLine)) {
  $issLines += $setupIconLine
}

$issLines += @(
  "",
  "[Tasks]",
  "Name: ""desktopicon""; Description: ""{cm:CreateDesktopIcon}""; GroupDescription: ""{cm:AdditionalIcons}""; Flags: unchecked",
  "",
  "[Files]",
  "Source: ""$(Escape-InnoQuoted $ReleaseDir)\*""; DestDir: ""{app}""; Flags: ignoreversion recursesubdirs createallsubdirs",
  "",
  "[Icons]",
  "Name: ""{group}\{#MyAppName}""; Filename: ""{app}\{#MyAppExeName}""",
  "Name: ""{autodesktop}\{#MyAppName}""; Filename: ""{app}\{#MyAppExeName}""; Tasks: desktopicon",
  "",
  "[Run]",
  "Filename: ""{app}\{#MyAppExeName}""; Description: ""{cm:LaunchProgram,{#MyAppName}}""; Flags: nowait postinstall skipifsilent"
)

[IO.File]::WriteAllText($issPath, ($issLines -join "`r`n"), [Text.UTF8Encoding]::new($false))
Write-Step "installer" "Wrote Inno Setup script: $issPath"

if ($DryRun) {
  Write-Step "installer" "Dry run completed; installer would be written to $installerPath."
  Write-Step "artifacts" "installer=$installerPath"
  Write-Step "artifacts" "script=$issPath"
  exit 0
}

$isccPath = Resolve-IsccPath
Write-Step "installer" "Building Windows installer with $isccPath."
& $isccPath $issPath
if ($LASTEXITCODE -ne 0) {
  throw "Inno Setup failed with exit code $LASTEXITCODE."
}

Require-File $installerPath "Flutter Windows installer"
Write-Step "artifacts" "installer=$installerPath"
