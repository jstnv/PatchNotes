$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$fixture=Join-Path $repo ('sims/cleanup-prune-fixture-' + [Guid]::NewGuid().ToString('N'))
$root=Join-Path $fixture 'runs'
# The tool only accepts fixtures as direct sims children, so use the fixture root.
$root=$fixture
$original=Join-Path $root 'original'; $replay=Join-Path $root 'replay'
foreach($p in @("$original/project/assets","$original/cases/case1","$replay/project/assets","$replay/project/.godot/imported")) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
$source='actual retained fixture source'; $asset='asset contents'
foreach($run in @($original,$replay)) { [IO.File]::WriteAllText("$run/project/project.godot",$source); [IO.File]::WriteAllText("$run/project/assets/test.txt",$asset); [IO.File]::WriteAllText("$run/project/assets/Font[wdth,wght].ttf",'font') }
[IO.File]::WriteAllText("$replay/project/.godot/imported/cache.dat",'retained cache')
$manifest=[ordered]@{'project.godot'=(Get-FileHash -LiteralPath "$original/project/project.godot" -Algorithm SHA256).Hash.ToLowerInvariant();'assets/test.txt'=(Get-FileHash -LiteralPath "$original/project/assets/test.txt" -Algorithm SHA256).Hash.ToLowerInvariant();'assets/Font[wdth,wght].ttf'=(Get-FileHash -LiteralPath "$original/project/assets/Font[wdth,wght].ttf" -Algorithm SHA256).Hash.ToLowerInvariant()}
foreach($run in @($original,$replay)) { $manifest | ConvertTo-Json | Set-Content -Encoding utf8 "$run/snapshot-manifest.json" }
@{replayable=$true;case_id='case1'} | ConvertTo-Json | Set-Content -Encoding utf8 "$original/cases/case1/result.json"
$caseHash=(Get-FileHash "$original/cases/case1/result.json" -Algorithm SHA256).Hash.ToLowerInvariant()
$report=@{format='patch-notes-isolated-simulation-v1';mode='replay';ok=$true;replay=@{ok=$true};original_bundle=$original;original_case='case1';input_hashes=@{'original-result.json'=$caseHash}}
$report | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$replay/run-report.json"
$tool=Join-Path $repo 'tools/prune_redundant_replay_sources.ps1'
function Invoke-Tool([string]$Receipt,[switch]$Execute) {
    $arguments=@('-NoProfile','-NonInteractive','-File',$tool,'-SimulationRoot',$root,'-Replay','replay','-ReceiptPath',$Receipt)
    if($Execute){$arguments += '-Execute'}
    & pwsh @arguments 2>&1 | Out-Null
    return $LASTEXITCODE
}
function Require([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message};Write-Output "PASS $Message"}
$dry=Join-Path $fixture 'dry.json'; $exit=Invoke-Tool $dry
Require ($exit -eq 0 -and (Test-Path "$replay/project/project.godot") -and (Test-Path $dry)) 'Dry run keeps files and writes a receipt'
[IO.File]::WriteAllText("$original/project/project.godot",'changed original')
$bad=Join-Path $fixture 'bad.json'; $exit=Invoke-Tool $bad -Execute
Require ($exit -ne 0 -and -not (Test-Path $bad) -and (Test-Path "$replay/project/project.godot")) 'Source drift aborts before receipt or deletion'
[IO.File]::WriteAllText("$original/project/project.godot",$source)
New-Item -ItemType Directory -Path "$replay/cases" | Out-Null
$bad2=Join-Path $fixture 'bad-cases.json'; $exit=Invoke-Tool $bad2 -Execute
Require ($exit -ne 0 -and -not (Test-Path $bad2) -and (Test-Path "$replay/project/project.godot")) 'Replay with cases is protected'
Remove-Item -LiteralPath "$replay/cases"
$report.original_bundle=Join-Path $repo 'patch-notes'; $report | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$replay/run-report.json"
$bad3=Join-Path $fixture 'bad-original.json'; $exit=Invoke-Tool $bad3 -Execute
Require ($exit -ne 0 -and -not (Test-Path $bad3) -and (Test-Path "$replay/project/project.godot")) 'An original outside the simulation root is protected'
$report.original_bundle=$original; $report.replay.ok=$false; $report | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$replay/run-report.json"
$bad4=Join-Path $fixture 'bad-status.json'; $exit=Invoke-Tool $bad4 -Execute
Require ($exit -ne 0 -and -not (Test-Path $bad4) -and (Test-Path "$replay/project/project.godot")) 'A failed replay is protected'
$report.replay.ok=$true; $report | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$replay/run-report.json"
$busy=[IO.File]::Open("$replay/run-report.json",[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::ReadWrite)
try { $busyReceipt=Join-Path $fixture 'busy.json'; $exit=Invoke-Tool $busyReceipt -Execute }
finally { $busy.Dispose() }
Require ($exit -ne 0 -and -not (Test-Path $busyReceipt) -and (Test-Path "$replay/project/project.godot")) 'An existing metadata writer blocks cleanup before deletion'
$done=Join-Path $fixture 'removed.json'; $exit=Invoke-Tool $done -Execute
Require ($exit -eq 0 -and -not (Test-Path "$replay/project/project.godot") -and -not (Test-Path "$replay/project/assets/test.txt") -and -not (Test-Path -LiteralPath "$replay/project/assets/Font[wdth,wght].ttf")) 'Verified duplicate files including literal bracket paths are removed'
Require ((Test-Path "$original/project/project.godot") -and (Test-Path "$original/project/assets/test.txt") -and (Test-Path "$replay/project/.godot/imported/cache.dat") -and (Test-Path "$replay/run-report.json") -and (Test-Path "$replay/snapshot-manifest.json")) 'Original source, cache, report and manifest are preserved'
Require (@(Get-Content -LiteralPath ($done+'.removed.jsonl')).Count -eq 3) 'Removal ledger lists every file'
$text=Get-Content -Raw -LiteralPath $tool
if($text -notmatch "(?s)Add-Type -TypeDefinition @'\r?\n(.*?)\r?\n'@") {throw 'Directory lock implementation missing'}
Add-Type -TypeDefinition $Matches[1]
$lockPath=Join-Path $fixture 'directory-lock-test'; New-Item -ItemType Directory -Path $lockPath | Out-Null
$handle=[PatchNotesReparseTag]::LockDirectory($lockPath)
try {
    $otherFile=Join-Path $lockPath 'unrelated.txt'
    [IO.File]::WriteAllText($otherFile,'first')
    [IO.File]::WriteAllText($otherFile,'second')
    $writesWork=([IO.File]::ReadAllText($otherFile) -eq 'second')
    $initialAttributes=[IO.File]::GetAttributes($lockPath)
    try {
        $before=[PatchNotesReparseTag]::Info($handle)
        [IO.File]::SetAttributes($lockPath,($initialAttributes -bor [IO.FileAttributes]::Offline))
        $during=[PatchNotesReparseTag]::Info($handle)
        $offlineDriftObserved=(($before.Attributes -band 0x00441400) -ne ($during.Attributes -band 0x00441400))
    } finally { [IO.File]::SetAttributes($lockPath,$initialAttributes) }
    $blocked=$false; try {Rename-Item -LiteralPath $lockPath -NewName 'directory-lock-moved' -ErrorAction Stop} catch {$blocked=$true}
}
finally { $handle.Dispose() }
Require $writesWork 'Unrelated file creation and writes work while the directory is pinned'
Require $offlineDriftObserved 'A pinned handle detects concurrent offline-attribute drift'
Require ($blocked -and (Test-Path -LiteralPath $lockPath) -and -not (Test-Path -LiteralPath (Join-Path $fixture 'directory-lock-moved'))) 'A pinned ancestor cannot be renamed during cleanup'
Write-Output "FIXTURE=$fixture"
