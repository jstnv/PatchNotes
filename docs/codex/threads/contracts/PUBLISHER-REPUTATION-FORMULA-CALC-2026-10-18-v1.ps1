# Deterministic arithmetic study only; never invokes Patch Notes gameplay.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../..')).Path
$matrixPath = Join-Path $repoRoot 'docs/codex/findings/queue-20261018-v1/challenges-v3/verify_contract_challenge_matrix.json'
$expectedHash = '4025887E0BBCD537DC14B5464D07204B39569D9A92BF227A7CBF16B513938B82'
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $matrixPath).Hash -ne $expectedHash) {
    throw 'Pinned challenge matrix changed; stop before comparison.'
}
$matrix = Get-Content -LiteralPath $matrixPath -Raw | ConvertFrom-Json
if ($matrix.cases.Count -ne 10) { throw 'Expected exactly ten verifier cases.' }
$grades = @($matrix.cases | ForEach-Object { [int]$_.grade_bp })
if (@($grades | Where-Object { $_ -eq 0 }).Count -ne 3 -or
    @($grades | Where-Object { $_ -eq 5000 }).Count -ne 3 -or
    @($grades | Where-Object { $_ -eq 10000 }).Count -ne 4) {
    throw 'Expected grade-class coverage changed.'
}

$M = 10 # Illustration only; not approved balance.
function Get-Gains([int]$completionBp, [int]$promiseBp) {
    if ($completionBp -lt 0 -or $completionBp -gt 10000 -or
        $promiseBp -lt 0 -or $promiseBp -gt 10000) {
        throw 'Grade outside [0,10000].'
    }
    $low = [Math]::Min($completionBp, $promiseBp)
    [pscustomobject]@{
        weakest = [int][Math]::Floor($M * $low / 10000)
        product = [int][Math]::Floor(([long]$M * $completionBp * $promiseBp) / 100000000)
        average = [int][Math]::Floor($M * ($completionBp + $promiseBp) / 20000)
    }
}

$levels = @(0, 2500, 5000, 7500, 10000)
$grid = @(
    foreach ($c in $levels) {
        foreach ($g in $levels) {
            $gain = Get-Gains $c $g
            [pscustomobject]@{
                completion_bp = $c
                promise_bp = $g
                weakest = $gain.weakest
                product = $gain.product
                average = $gain.average
            }
        }
    }
)

foreach ($name in @('weakest', 'product', 'average')) {
    foreach ($row in $grid) {
        $value = [int]$row.$name
        if ($value -lt 0 -or $value -gt $M) { throw "Out-of-range gain for $name" }
        if ($name -ne 'average' -and ($row.completion_bp -eq 0 -or $row.promise_bp -eq 0) -and $value -ne 0) {
            throw "Zero-boundary failure for $name"
        }
        foreach ($other in $grid) {
            if ($other.completion_bp -ge $row.completion_bp -and
                $other.promise_bp -ge $row.promise_bp -and
                [int]$other.$name -lt $value) {
                throw "Monotonicity failure for $name"
            }
        }
    }
}
if ((Get-Gains 10000 10000).weakest -ne $M -or
    (Get-Gains 10000 10000).product -ne $M -or
    (Get-Gains 10000 10000).average -ne $M) {
    throw 'Maximum-boundary failure.'
}

$csvPath = Join-Path $PSScriptRoot 'PUBLISHER-REPUTATION-GRID-2026-10-18-v1.csv'
$grid | Export-Csv -LiteralPath $csvPath -NoTypeInformation
$projected = @(
    foreach ($item in $matrix.cases) {
        $gain = Get-Gains 10000 ([int]$item.grade_bp)
        [pscustomobject]@{
            case = [string]$item.case
            observed_challenge_grade_bp = [int]$item.grade_bp
            assumed_completion_bp = 10000
            weakest = $gain.weakest
            product = $gain.product
            average = $gain.average
        }
    }
)
$projectionPath = Join-Path $PSScriptRoot 'PUBLISHER-REPUTATION-PROJECTIONS-2026-10-18-v1.json'
$projected | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $projectionPath -Encoding utf8

Write-Output "Grid rows: $($grid.Count); verifier projections: $($projected.Count); audit: PASS"
Write-Output 'Key comparison rows:'
$grid | Where-Object {
    ($_.completion_bp -eq 5000 -and $_.promise_bp -eq 5000) -or
    ($_.completion_bp -eq 10000 -and $_.promise_bp -eq 5000) -or
    ($_.completion_bp -eq 10000 -and $_.promise_bp -eq 0) -or
    ($_.completion_bp -eq 0 -and $_.promise_bp -eq 10000) -or
    ($_.completion_bp -eq 10000 -and $_.promise_bp -eq 10000)
} | Format-Table -AutoSize | Out-String | Write-Output
foreach ($name in @('weakest', 'product', 'average')) {
    $distinct = @($grid | Select-Object -ExpandProperty $name -Unique).Count
    Write-Output "$name distinct grid outputs: $distinct"
}
Write-Output "CSV: $csvPath"
Write-Output "Projections: $projectionPath"
