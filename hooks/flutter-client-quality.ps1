param(
    [ValidateSet("quick", "full")]
    [string]$Mode = "quick",

    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

$ErrorActionPreference = "Stop"

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Command
    )

    Write-Host "==> $Description"
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE"
    }
}

function Get-GitLines {
    param([string[]]$Arguments)

    $output = & git -C $RepoRoot @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }

    return @($output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Assert-NoMatches {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [string[]]$Paths = @()
    )

    if ($null -eq $Paths -or $Paths.Count -eq 0) {
        return
    }

    $matches = @()
    foreach ($path in $Paths) {
        $fullPath = Join-Path $RepoRoot $path
        if (-not (Test-Path $fullPath)) {
            continue
        }

        $found = & rg -n --with-filename --pcre2 $Pattern $fullPath
        if ($LASTEXITCODE -eq 0) {
            $matches += $found
        } elseif ($LASTEXITCODE -ne 1) {
            throw "rg failed while checking $Description"
        }
    }

    if ($matches.Count -gt 0) {
        Write-Host ""
        Write-Host $Description
        $matches | ForEach-Object { Write-Host $_ }
        throw $Description
    }
}

$flutterRoot = "clients/flutter-client"
$flutterLib = "$flutterRoot/lib"
$flutterTest = "$flutterRoot/test"

$stagedFlutter = Get-GitLines @("diff", "--cached", "--name-only", "--", $flutterRoot)
$changedFlutter = Get-GitLines @("diff", "--name-only", "HEAD", "--", $flutterRoot)
$untrackedFlutter = Get-GitLines @("ls-files", "--others", "--exclude-standard", "--", $flutterRoot)
$flutterChanges = @($stagedFlutter + $changedFlutter + $untrackedFlutter | Sort-Object -Unique)

if ($flutterChanges.Count -eq 0) {
    Write-Host "No Flutter client changes detected."
    exit 0
}

$dartChanges = @(
    $flutterChanges |
        Where-Object { $_.EndsWith(".dart", [StringComparison]::Ordinal) } |
        Where-Object { -not $_.StartsWith("$flutterRoot/lib/generated/", [StringComparison]::Ordinal) }
)
$sourceChanged = @(
    $dartChanges |
        Where-Object { $_.StartsWith("$flutterLib/", [StringComparison]::Ordinal) }
)
$testChanged = @(
    $dartChanges |
        Where-Object { $_.StartsWith("$flutterTest/", [StringComparison]::Ordinal) }
)

if ($dartChanges.Count -eq 0) {
    Invoke-Checked "Flutter whitespace check" {
        git -C $RepoRoot diff --check -- $flutterRoot
    }

    Write-Host "Flutter client $Mode quality gate passed; no Dart changes detected."
    exit 0
}

if ($sourceChanged.Count -gt 0 -and $testChanged.Count -eq 0 -and $env:SKIP_FLUTTER_TEST_GUARD -ne "1") {
    Write-Host "Flutter source changed without a matching Flutter test change:"
    $sourceChanged | ForEach-Object { Write-Host "  $_" }
    throw "Add focused Flutter tests or set SKIP_FLUTTER_TEST_GUARD=1 for an intentional docs/style-only exception."
}

$changedNonServiceSource = @(
    $sourceChanged |
        Where-Object { -not $_.EndsWith("_service.dart", [StringComparison]::Ordinal) } |
        Where-Object { -not $_.EndsWith("_repository.dart", [StringComparison]::Ordinal) } |
        Where-Object { -not $_.EndsWith("_security.dart", [StringComparison]::Ordinal) } |
        Where-Object { -not $_.EndsWith("_store.dart", [StringComparison]::Ordinal) } |
        Where-Object { $_ -ne "$flutterLib/features/auth/auth_credentials.dart" }
)

$changedUiSourceForMenuCheck = @(
    $changedNonServiceSource |
        Where-Object { $_ -ne "$flutterLib/features/workspace/shared/user_context_menu.dart" }
)

if ($changedNonServiceSource.Count -gt 0) {
    Assert-NoMatches `
        -Description "Flutter widgets/controllers must not open transport, credential, or filesystem primitives directly; route I/O through services." `
        -Pattern "import 'dart:io'|package:web_socket_channel|package:flutter_secure_storage|\bHttpClient\b|WebSocketChannel" `
        -Paths $changedNonServiceSource
}

Assert-NoMatches `
    -Description "Flutter diagnostics must not log obvious secret-bearing values." `
    -Pattern "debugPrint\([^\r\n]*(password|accessToken|sessionToken|refreshToken|twoFactorTicket|Bearer|Authorization)" `
    -Paths $sourceChanged

Assert-NoMatches `
    -Description "Flutter workspace code should import shared timestamp formatting from features/workspace/shared." `
    -Pattern "chat_workspace/chat_timestamp_format|import 'chat_timestamp_format\.dart'" `
    -Paths $dartChanges

if ($changedUiSourceForMenuCheck.Count -gt 0) {
    Assert-NoMatches `
        -Description "Flutter context menus must use the shared Verdant context menu helper instead of raw Material popup menus." `
        -Pattern "\bshowMenu\s*<|PopupMenuItem|PopupMenuDivider" `
        -Paths $changedUiSourceForMenuCheck
}

if ($dartChanges.Count -gt 0) {
    Invoke-Checked "Flutter Dart formatting verification" {
        dart format --set-exit-if-changed @($dartChanges | ForEach-Object { Join-Path $RepoRoot $_ })
    }
}

Invoke-Checked "Flutter analyzer" {
    flutter analyze (Join-Path $RepoRoot $flutterRoot)
}

Invoke-Checked "Flutter tests" {
    Push-Location (Join-Path $RepoRoot $flutterRoot)
    try {
        flutter test
    } finally {
        Pop-Location
    }
}

if ($Mode -eq "full") {
    Invoke-Checked "Flutter dependency freshness report" {
        Push-Location (Join-Path $RepoRoot $flutterRoot)
        try {
            flutter pub outdated
        } finally {
            Pop-Location
        }
    }
}

Invoke-Checked "Flutter whitespace check" {
    git -C $RepoRoot diff --check -- $flutterRoot
}

Write-Host "Flutter client $Mode quality gate passed."
