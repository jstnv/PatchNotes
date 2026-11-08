param([int]$Count=120)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$fixture=Join-Path $repo ('sims/cleanup-prune-fixture-bench-' + [Guid]::NewGuid().ToString('N'))
$original=Join-Path $fixture 'original'; $replay=Join-Path $fixture 'replay'
foreach($p in @("$original/project/assets","$original/cases/case1","$replay/project/assets")) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
$manifest=[ordered]@{}
for($i=0;$i -lt $Count;$i++){
    $dir='group{0:00}' -f ($i % 12); $file='file{0:000}.txt' -f $i; $relative="assets/$dir/$file"
    foreach($run in @($original,$replay)) { $d=Join-Path "$run/project/assets" $dir; if(-not(Test-Path -LiteralPath $d)){New-Item -ItemType Directory -Path $d|Out-Null}; [IO.File]::WriteAllText((Join-Path $d $file),('fixture-{0}-' -f $i)+('x'*1024)) }
    $manifest[$relative]=(Get-FileHash -LiteralPath (Join-Path "$original/project" $relative) -Algorithm SHA256).Hash.ToLowerInvariant()
}
foreach($run in @($original,$replay)) { $manifest | ConvertTo-Json | Set-Content -Encoding utf8 "$run/snapshot-manifest.json" }
@{replayable=$true;case_id='case1'} | ConvertTo-Json | Set-Content -Encoding utf8 "$original/cases/case1/result.json"
$caseHash=(Get-FileHash "$original/cases/case1/result.json" -Algorithm SHA256).Hash.ToLowerInvariant()
@{format='patch-notes-isolated-simulation-v1';mode='replay';ok=$true;replay=@{ok=$true};original_bundle=$original;original_case='case1';input_hashes=@{'original-result.json'=$caseHash}} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$replay/run-report.json"
$tool=Join-Path $repo 'tools/prune_redundant_replay_sources.ps1'; $receipt=Join-Path $fixture 'receipt.json'
$watch=[Diagnostics.Stopwatch]::StartNew()
& pwsh -NoProfile -NonInteractive -File $tool -SimulationRoot $fixture -Replay replay -ReceiptPath $receipt -Execute
$exit=$LASTEXITCODE; $watch.Stop()
if($exit -ne 0) { throw "Benchmark failed: $exit" }
if(@(Get-Content -LiteralPath ($receipt+'.removed.jsonl')).Count -ne $Count) {throw 'Ledger count mismatch'}
'BENCHMARK files={0} elapsed_ms={1} fixture={2}' -f $Count,$watch.ElapsedMilliseconds,$fixture
