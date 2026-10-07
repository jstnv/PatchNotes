param([Parameter(Mandatory=$true)][string]$TracePath)
$data = Get-Content -Raw -LiteralPath $TracePath | ConvertFrom-Json
$titles = @{}
$releaseByMonth = @{}
foreach ($release in $data.releases) {
    $titles[$release.release_id] = @{ review = [double]$release.final_review; cumulative = 0; linear = 0; sqrt = 0; linearLaunch = 0; sqrtLaunch = 0 }
    $releaseByMonth[[int]($release.cycle / 2)] = $release
}
$linearFans = 0
$sqrtFans = 0
$rows = @()
foreach ($month in $data.final.fan_history) {
    $linearGain = 0
    $sqrtGain = 0
    foreach ($earned in $month.releases) {
        $title = $titles[$earned.release_id]
        $title.cumulative += [int]$earned.earned_units
        $quality = [Math]::Min(1.5, [Math]::Max(0.0, ($title.review - 5.0) / 2.0))
        $linearTarget = [int][Math]::Floor([Math]::Max(0.0, $title.cumulative - $title.linearLaunch) * 0.08 * $quality)
        $sqrtTarget = [int][Math]::Floor([Math]::Max(0.0, $title.cumulative - $title.sqrtLaunch) * 0.08 * [Math]::Sqrt($quality))
        $linearGain += $linearTarget - $title.linear
        $sqrtGain += $sqrtTarget - $title.sqrt
        $title.linear = $linearTarget
        $title.sqrt = $sqrtTarget
    }
    $linearFans += $linearGain
    $sqrtFans += $sqrtGain
    if ($linearFans -ne [int]$month.ending) { throw "Linear reconciliation failed at month $($month.month): $linearFans vs $($month.ending)" }
    $row = [ordered]@{month=[int]$month.month; linearGain=$linearGain; sqrtGain=$sqrtGain; linearFans=$linearFans; sqrtFans=$sqrtFans}
    if ($releaseByMonth.ContainsKey([int]$month.month)) {
        $release = $releaseByMonth[[int]$month.month]
        $title = $titles[$release.release_id]
        $title.linearLaunch = $linearFans
        $title.sqrtLaunch = $sqrtFans
        $row.release = $release.base_name
        $row.review = $release.final_review
        $row.linearAwareness = [int][Math]::Floor(150.0 * $linearFans / ($linearFans + 300))
        $row.sqrtAwareness = [int][Math]::Floor(150.0 * $sqrtFans / ($sqrtFans + 300))
    }
    $rows += [pscustomobject]$row
}
$rows | Where-Object { $_.month -in @(16,17,25,26,34,43) -or $_.PSObject.Properties.Name -contains 'release' } | Format-Table -AutoSize
"reconciled=$($rows.Count) finalLinear=$linearFans finalSqrt=$sqrtFans"
