#requires -Version 7.0
<#
Checks KonSol RetroStation registry structure OFFLINE.
No network calls, hardware flashing, or modification of source files.
#>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$platformPath = Join-Path $root 'catalog/platforms.json'
$gamesPath = Join-Path $root 'catalog/games.json'
$platforms = Get-Content -LiteralPath $platformPath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 30
$catalog = Get-Content -LiteralPath $gamesPath -Raw -Encoding utf8 | ConvertFrom-Json -Depth 30

if ($platforms.schema_version -ne '0.1' -or $catalog.schema_version -ne '0.1') {
    throw 'Unexpected catalog schema version'
}
$classes = @('FPGA','MCU','SBC','HYBRID')
$levels = @('discovered','source_documented','build_pass','operator_board_pass','candidate')
$distLevels = @('released','source_only','collection')
$boardIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$gameIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)

foreach ($board in @($platforms.boards)) {
    if ([string]::IsNullOrWhiteSpace([string]$board.id) -or
        -not $boardIds.Add([string]$board.id)) {
        throw "Invalid/duplicate board id: $($board.id)"
    }
    if ($classes -notcontains [string]$board.hardware_class) {
        throw "Invalid hardware class on board: $($board.id)"
    }
    if ([string]$board.source_url -notmatch '^https://github\.com/') {
        throw "Missing secure source URL on board: $($board.id)"
    }
}
foreach ($game in @($catalog.games)) {
    if ([string]::IsNullOrWhiteSpace([string]$game.id) -or
        -not $gameIds.Add([string]$game.id)) {
        throw "Invalid/duplicate game id: $($game.id)"
    }
    if ($classes -notcontains [string]$game.hardware_class) {
        throw "Invalid hardware class on game: $($game.id)"
    }
    if ($levels -notcontains [string]$game.evidence_level) {
        throw "Invalid evidence level on game: $($game.id)"
    }
    if ($distLevels -notcontains [string]$game.distribution.status) {
        throw "Invalid distribution status on game: $($game.id)"
    }
    if ([string]$game.source_url -notmatch '^https://github\.com/') {
        throw "Invalid source URL on game: $($game.id)"
    }
    foreach ($boardId in @($game.board_ids)) {
        if (-not $boardIds.Contains([string]$boardId)) {
            throw "Game $($game.id) references unknown board: $boardId"
        }
    }
    if ([string]$game.distribution.status -eq 'released') {
        if (@($game.board_ids).Count -eq 0) {
            throw "Released game without board target: $($game.id)"
        }
        if ([string]$game.distribution.sha256 -cnotmatch '^[a-f0-9]{64}$') {
            throw "Released game has invalid SHA256: $($game.id)"
        }
        if ([string]::IsNullOrWhiteSpace([string]$game.distribution.file)) {
            throw "Released game missing file name: $($game.id)"
        }
        if ([string]$game.distribution.download_url -notmatch '^https://github\.com/') {
            throw "Released game missing GitHub download URL: $($game.id)"
        }
    }
}
Write-Host "KONSOL_CATALOG_PASS: boards=$($boardIds.Count) games=$($gameIds.Count)" -ForegroundColor Green
