<#
Remove only manifest-listed source files from explicitly named successful replay
bundles, after verifying an identical retained original and writing a recovery
receipt. This never removes run directories, caches, results, profiles, or saves.
Example: pwsh -File tools/prune_redundant_replay_sources.ps1 -Replay name1 -ReceiptPath sims/cleanup-receipts/run.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string[]]$Replay,
    [Parameter(Mandatory=$true)][string]$ReceiptPath,
    [string]$SimulationRoot = '',
    [switch]$Execute
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public static class PatchNotesReparseTag {
    [StructLayout(LayoutKind.Sequential)] public struct TagInfo { public uint Attributes; public uint Tag; }
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern SafeFileHandle CreateFileW(string name, uint access, uint share, IntPtr security, uint mode, uint flags, IntPtr template);
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool GetFileInformationByHandleEx(SafeFileHandle file, int infoClass, out TagInfo info, uint size);
    public static uint Read(string path) {
        // Open the reparse point itself; do not follow it or hydrate its contents.
        using (var handle = CreateFileW(path, 0, 7, IntPtr.Zero, 3, 0x02200000, IntPtr.Zero)) {
            if (handle.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
            TagInfo info;
            if (!GetFileInformationByHandleEx(handle, 9, out info, 8)) throw new Win32Exception(Marshal.GetLastWin32Error());
            return info.Tag;
        }
    }
    public static SafeFileHandle LockDirectory(string path) {
        // Allow other readers and writers, but deny deletion/rename of this
        // checked ancestor while its descendants are examined.
        var handle = CreateFileW(path, 0x80000000u, 3, IntPtr.Zero, 3, 0x02200000, IntPtr.Zero);
        if (handle.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
        return handle;
    }
    public static TagInfo Info(SafeFileHandle handle) {
        TagInfo info;
        if (!GetFileInformationByHandleEx(handle, 9, out info, 8)) throw new Win32Exception(Marshal.GetLastWin32Error());
        return info;
    }
}
'@
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\')
$defaultRoot = [IO.Path]::GetFullPath((Join-Path $repo 'docs/codex/threads/ai-competitors/sims')).TrimEnd('\')
if (-not $SimulationRoot) { $SimulationRoot = $defaultRoot }
$root = [IO.Path]::GetFullPath($SimulationRoot).TrimEnd('\')
$fixtureParent = [IO.Path]::GetFullPath((Join-Path $repo 'sims')).TrimEnd('\') + '\'
if (-not $root.Equals($defaultRoot,[StringComparison]::OrdinalIgnoreCase) -and
    -not ($root.StartsWith($fixtureParent,[StringComparison]::OrdinalIgnoreCase) -and
          (Split-Path -Leaf $root) -match '^cleanup-prune-fixture-[a-zA-Z0-9_-]+$')) {
    throw 'Only the AI simulation root or an isolated cleanup test fixture is permitted.'
}
$directoryHandles = [Collections.Generic.Dictionary[string,Microsoft.Win32.SafeHandles.SafeFileHandle]]::new([StringComparer]::OrdinalIgnoreCase)
$directoryProofs = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
$heldMetadata = [Collections.Generic.List[IO.FileStream]]::new()

function Assert-Within([string]$Path,[string]$Parent) {
    $p = [IO.Path]::GetFullPath($Path)
    $prefix = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    if (-not $p.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) { throw "Path escapes its permitted directory: $p" }
    return $p
}
function Assert-SafeNode([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.LinkType) { throw "Links and junctions are forbidden: $Path" }
    $attrs = [int64]$item.Attributes
    if (($attrs -band [int64][IO.FileAttributes]::Offline) -or ($attrs -band 0x00040000) -or ($attrs -band 0x00400000)) { throw "Offline or recall-on-open/access file: $Path" }
    if ($attrs -band [int64][IO.FileAttributes]::ReparsePoint) {
        if ([PatchNotesReparseTag]::Read($item.FullName) -ne [Convert]::ToUInt32('9000a01a',16)) { throw "Unknown or unsafe reparse tag: $Path" }
    }
    if ($item.PSIsContainer -and -not $directoryHandles.ContainsKey($item.FullName)) {
        $handle = [PatchNotesReparseTag]::LockDirectory($item.FullName)
        try {
            $info = [PatchNotesReparseTag]::Info($handle)
            if ($info.Attributes -ne [uint32]$attrs -or (($info.Attributes -band 0x400) -and $info.Tag -ne [Convert]::ToUInt32('9000a01a',16))) { throw "Directory changed while locking: $Path" }
            $directoryHandles.Add($item.FullName,$handle)
            # Cached handles are rechecked because write sharing allows other
            # processes to alter directory metadata without renaming it.
            $directoryProofs.Add($item.FullName,@{safetyAttributes=($info.Attributes -band 0x00441400); tag=$info.Tag})
            $handle = $null
        } finally { if ($null -ne $handle) { $handle.Dispose() } }
    }
}
function Assert-SafePath([string]$Path) {
    $p = [IO.Path]::GetFullPath($Path)
    Assert-Within $p $repo | Out-Null
    $parents = [Collections.Generic.List[string]]::new()
    while (-not $p.Equals($repo,[StringComparison]::OrdinalIgnoreCase)) {
        $parents.Add($p)
        $next = Split-Path -Parent $p
        if (-not $next -or $next -eq $p) { throw 'Could not validate path ancestry.' }
        $p = $next
    }
    $parents.Add($repo)
    for ($i=$parents.Count-1; $i -ge 0; $i--) {
        $node=$parents[$i]
        if ($directoryHandles.ContainsKey($node)) {
            $handle=$directoryHandles[$node]
            if ($handle.IsClosed -or $handle.IsInvalid) { throw "Directory lock lost: $node" }
            $info=[PatchNotesReparseTag]::Info($handle)
            $proof=$directoryProofs[$node]
            if (($info.Attributes -band 0x00441400) -ne $proof.safetyAttributes -or $info.Tag -ne $proof.tag) { throw "Directory safety attributes changed: $node" }
        } else { Assert-SafeNode $node }
    }
}
function Read-LockedJson([string]$Path) {
    Assert-SafePath $Path
    $stream = [IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    $heldMetadata.Add($stream)
    # The read-only share denies concurrent writes, deletion and replacement
    # for the lifetime of the operation, while allowing other readers.
    $hash = (Get-FileHash -InputStream $stream -Algorithm SHA256).Hash.ToLowerInvariant()
    $stream.Position = 0
    $reader = [IO.StreamReader]::new($stream,[Text.Encoding]::UTF8,$true,4096,$true)
    try { $json=$reader.ReadToEnd() } finally { $reader.Dispose() }
    return [PSCustomObject]@{path=$Path; sha256=$hash; bytes=$stream.Length; stream=$stream; value=($json | ConvertFrom-Json -AsHashtable)}
}
function Check-File([string]$Path,[string]$Hash,[long]$Length) {
    Assert-SafePath $Path
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.PSIsContainer -or $item.Length -ne $Length) { throw "Size/type drift: $Path" }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Hash) { throw "Hash drift: $Path" }
}
function Check-Space {
    $drive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($root))
    if ($drive.AvailableFreeSpace -lt 3GB) { throw "Less than 3 GiB free on $($drive.Name)." }
}

$mutex = [Threading.Mutex]::new($false,'Local\PatchNotesReplaySourceCleanup')
$locked = $false
try {
    $locked = $mutex.WaitOne(0)
    if (-not $locked) { throw 'Another replay cleanup is running.' }
    Check-Space
    Assert-SafePath $root
    if ($Replay.Count -eq 0 -or @($Replay | Select-Object -Unique).Count -ne $Replay.Count) { throw 'Provide distinct explicit replay directory names.' }
    foreach ($name in $Replay) { if ($name -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_-]*$') { throw "Unsafe replay name: $name" } }
    $selected = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $Replay) { [void]$selected.Add($name) }
    $receipt = Assert-Within $ReceiptPath (Join-Path $repo 'sims')
    if (Test-Path -LiteralPath $receipt) { throw 'Receipt must be a new file.' }
    Assert-SafePath (Split-Path -Parent $receipt)
    $ledgerPath = $receipt + '.removed.jsonl'
    if (Test-Path -LiteralPath $ledgerPath) { throw 'Removal ledger already exists.' }
    $bundles = @(); $bundleByName = @{}; $files = [Collections.Generic.List[object]]::new()
    foreach ($name in $Replay) {
        $bundle = Assert-Within (Join-Path $root $name) $root
        Assert-SafePath $bundle
        if (Test-Path -LiteralPath (Join-Path $bundle 'cases')) { throw "Replay contains cases and may be needed as an original: $name" }
        $reportPath = Join-Path $bundle 'run-report.json'
        $reportLock = Read-LockedJson $reportPath
        $report = $reportLock.value
        if ($report.format -ne 'patch-notes-isolated-simulation-v1' -or $report.mode -ne 'replay' -or $report.ok -ne $true -or $report.replay.ok -ne $true) { throw "Not a successful replay: $name" }
        if ($report.original_case -notmatch '^[a-zA-Z0-9_-]+$') { throw "Invalid original case: $name" }
        $original = Assert-Within ([string]$report.original_bundle) $root
        if (-not (Split-Path -Parent $original).Equals($root,[StringComparison]::OrdinalIgnoreCase)) { throw 'Original bundle must be an immediate child of the simulation root.' }
        if ($selected.Contains((Split-Path -Leaf $original))) { throw 'An original bundle is also selected for deletion.' }
        if ($original.Equals($bundle,[StringComparison]::OrdinalIgnoreCase)) { throw 'Replay cannot be its own original.' }
        if ($receipt.StartsWith($bundle.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase) -or $receipt.StartsWith($original.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Receipt must be outside the replay and retained original.' }
        Assert-SafePath $original
        $caseResult = Join-Path $original ('cases/' + $report.original_case + '/result.json')
        $caseLock = Read-LockedJson $caseResult
        $case = $caseLock.value
        if ($case.replayable -ne $true) { throw "Original case is not replayable: $name" }
        $caseHash = $caseLock.sha256
        if ($report.input_hashes['original-result.json'] -ne $caseHash) { throw "Original case hash mismatch: $name" }
        $replayManifestPath = Join-Path $bundle 'snapshot-manifest.json'
        $originalManifestPath = Join-Path $original 'snapshot-manifest.json'
        $manifestLock = Read-LockedJson $replayManifestPath
        $originalManifestLock = Read-LockedJson $originalManifestPath
        $manifest = $manifestLock.value
        $originalManifest = $originalManifestLock.value
        if ($manifest.Count -eq 0 -or $manifest.Count -ne $originalManifest.Count) { throw "Manifest count mismatch: $name" }
        $project = Join-Path $bundle 'project'; $source = Join-Path $original 'project'
        Assert-SafePath $project; Assert-SafePath $source
        $tracked = @(& git -C $repo ls-files -- (Join-Path $bundle 'project') 2>$null)
        if ($LASTEXITCODE -ne 0 -or $tracked.Count -gt 0) { throw "Replay project has tracked files or git failed: $name" }
        foreach ($relative in @($manifest.Keys | Sort-Object)) {
            if ($relative -notmatch '^[a-zA-Z0-9_./,\[\] -]+$' -or $relative.StartsWith('/') -or @($relative.Split('/') | Where-Object { $_ -eq '' -or $_ -eq '.' -or $_ -eq '..' -or $_.StartsWith('.') }).Count) { throw "Unsafe manifest path: $relative" }
            $hash = [string]$manifest[$relative]
            if ($hash -notmatch '^[0-9a-fA-F]{64}$' -or -not $originalManifest.ContainsKey($relative) -or $originalManifest[$relative] -ne $hash) { throw "Manifest mismatch: $name/$relative" }
            $target = Assert-Within (Join-Path $project $relative) $project
            $keep = Assert-Within (Join-Path $source $relative) $source
            Assert-SafePath $target; Assert-SafePath $keep
            $targetItem = Get-Item -LiteralPath $target -Force
            $length = $targetItem.Length
            Check-File $target $hash $length
            Check-File $keep $hash $length
            $files.Add([ordered]@{ replay=$name; relative=$relative; target=$target; retained_original=$keep; sha256=$hash.ToLowerInvariant(); bytes=$length })
        }
        $record = [ordered]@{
            name=$name; replay=$bundle; original=$original;
            case_result=$caseResult; case_sha256=$caseHash.ToLowerInvariant(); case_bytes=$caseLock.bytes;
            replay_report=$reportPath; replay_report_sha256=$reportLock.sha256; replay_report_bytes=$reportLock.bytes;
            replay_manifest=$replayManifestPath; replay_manifest_sha256=$manifestLock.sha256; replay_manifest_bytes=$manifestLock.bytes;
            original_manifest=$originalManifestPath; original_manifest_sha256=$originalManifestLock.sha256; original_manifest_bytes=$originalManifestLock.bytes
        }
        $bundles += $record
        $bundleByName[$name] = @{ record=$record; locks=@($reportLock,$caseLock,$manifestLock,$originalManifestLock) }
    }
    $totalBytes = 0L
    foreach ($entry in $files) { $totalBytes += [long]$entry.bytes }
    $data = [ordered]@{format='patch-notes-replay-source-prune-v1'; created_utc=[DateTime]::UtcNow.ToString('o'); root=$root; mode=($(if($Execute){'execute'}else{'dry-run'})); bundles=$bundles; files=$files.ToArray(); logical_bytes=$totalBytes} | ConvertTo-Json -Depth 12
    $stream = [IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    try { $bytes=[Text.UTF8Encoding]::new($false).GetBytes($data); $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
    if (-not $Execute) { Write-Output "DRY_RUN files=$($files.Count) bytes=$totalBytes receipt=$receipt"; return }
    $ledgerStream = [IO.File]::Open($ledgerPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    $ledger = [IO.StreamWriter]::new($ledgerStream,[Text.UTF8Encoding]::new($false))
    try {
        foreach ($entry in $files) {
            Check-Space
            $bundleState = $bundleByName[$entry.replay]
            $bundleInfo = $bundleState.record
            if (Test-Path -LiteralPath (Join-Path $bundleInfo.replay 'cases')) { throw 'Replay acquired cases during cleanup.' }
            foreach ($lockedFile in $bundleState.locks) {
                if ($lockedFile.stream.SafeFileHandle.IsClosed -or $lockedFile.stream.SafeFileHandle.IsInvalid -or $lockedFile.stream.Length -ne $lockedFile.bytes) { throw "Metadata lock lost: $($lockedFile.path)" }
            }
            Check-File $entry.target $entry.sha256 $entry.bytes
            Check-File $entry.retained_original $entry.sha256 $entry.bytes
            Remove-Item -LiteralPath $entry.target -ErrorAction Stop
            if (Test-Path -LiteralPath $entry.target) { throw "Removal not confirmed: $($entry.target)" }
            $ledger.WriteLine(($entry | ConvertTo-Json -Compress)); $ledger.Flush(); $ledgerStream.Flush($true)
        }
    } finally { $ledger.Dispose() }
    Write-Output "REMOVED files=$($files.Count) logical_bytes=$totalBytes receipt=$receipt"
} finally {
    foreach ($stream in $heldMetadata) { $stream.Dispose() }
    foreach ($handle in $directoryHandles.Values) { $handle.Dispose() }
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
