$ErrorActionPreference = 'Stop'
$inputDir = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..\..\..\..\patch-notes\design-logs\task32-v1')).Path
$evalPath = Join-Path $inputDir 'evaluations.json'
$tracePath = Join-Path $inputDir 'contract_traces.json'
$evaluations = Get-Content -LiteralPath $evalPath -Raw | ConvertFrom-Json
$traces = Get-Content -LiteralPath $tracePath -Raw | ConvertFrom-Json

$rows = foreach ($evaluation in $evaluations) {
    $publisher = [string]$traces[[int]$evaluation.trace].name
    $cap = if ($publisher -eq 'crown') { 192000L } elseif ($publisher -eq 'neon') { 156000L } else { throw "Unexpected publisher: $publisher" }
    $numerator = [long]$evaluation.numerator
    $denominator = [long]$evaluation.denominator
    foreach ($advance in @(0L, 15000L, 20000L, 30000L)) {
        $product = ($cap - $advance) * $numerator
        $award = $advance + [long](($product - ($product % $denominator)) / $denominator)
        if ($advance -eq 0 -and $award -ne [long]$evaluation.payout) {
            throw "A=0 mismatch for trace $($evaluation.trace), target $($evaluation.target)"
        }
        [pscustomobject]@{
            publisher = $publisher
            target_scope = [int]$evaluation.target
            advance_cents = $advance
            award_cents = $award
            extra_cents = $award - [long]$evaluation.payout
            full = [bool]$evaluation.full
        }
    }
}

if ($evaluations.Count -ne 1280 -or $traces.Count -ne 640 -or $rows.Count -ne 5120) {
    throw "Unexpected Task32 input size: evaluations=$($evaluations.Count), traces=$($traces.Count), rows=$($rows.Count)"
}

$summary = foreach ($group in ($rows | Group-Object publisher, target_scope, advance_cents)) {
    $sample = $group.Group
    [pscustomobject]@{
        publisher = $sample[0].publisher
        target_scope = $sample[0].target_scope
        advance_cents = $sample[0].advance_cents
        historical_rows = $sample.Count
        full_rows = @($sample | Where-Object { $_.full }).Count
        mean_award_cents = [math]::Round(($sample | Measure-Object award_cents -Average).Average, 2)
        mean_extra_cents = [math]::Round(($sample | Measure-Object extra_cents -Average).Average, 2)
        min_award_cents = ($sample | Measure-Object award_cents -Minimum).Minimum
        max_award_cents = ($sample | Measure-Object award_cents -Maximum).Maximum
    }
}
$summary = $summary | Sort-Object publisher, target_scope, advance_cents
$summary | Export-Csv -LiteralPath (Join-Path $PSScriptRoot 'summary.csv') -NoTypeInformation -Encoding utf8
@(
    "evaluations.json SHA256 $((Get-FileHash -LiteralPath $evalPath -Algorithm SHA256).Hash)"
    "contract_traces.json SHA256 $((Get-FileHash -LiteralPath $tracePath -Algorithm SHA256).Hash)"
) | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'input-sha256.txt') -Encoding utf8
"PASS: $($evaluations.Count) A=0 exact-cent parity rows; $($summary.Count) summary groups"
