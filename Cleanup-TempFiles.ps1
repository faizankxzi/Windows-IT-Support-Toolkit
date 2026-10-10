param([string]$TargetProfilePath,[switch]$Confirmed)
. (Join-Path $PSScriptRoot 'Toolkit.Engine.ps1')
function Invoke-SafeTempCleanup {
    param([string]$Section,[string]$Path)
    Write-ToolkitStage ('Measuring '+$Section+' before cleanup')
    $root = Get-ToolkitDirectory $Path
    $before = Get-ToolkitInventory $root
    $notes = New-Object 'Collections.Generic.List[string]'
    foreach ($note in $before.Notes) { $notes.Add($note) }
    $deleted=0; $freed=0; $processed=0; $skipped=0; $lastPercent=-1
    foreach ($file in $before.Files) {
        if (Test-ToolkitCancellation) {break}
        $percent=[int][math]::Floor(100*$processed/$before.Files.Count)
        if ($percent -ne $lastPercent) {
            Write-Progress -Id 1 -Activity ('Cleaning '+$Section) -Status ('File '+($processed+1)+' of '+$before.Files.Count) -PercentComplete $percent
            $lastPercent=$percent
        }
        try {
            $current = Get-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
            if ($current -isnot [IO.FileInfo] -or ($current.Attributes -band [IO.FileAttributes]::ReparsePoint) -or !$current.FullName.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'File is outside the approved cleanup scope or is redirected.' }
            $null = Get-ToolkitDirectory $current.DirectoryName
            $length = $current.Length
            Assert-ToolkitNotCancelled
            Remove-Item -LiteralPath $current.FullName -Force -ErrorAction Stop
            $deleted++; $freed += $length
        } catch {if (Test-ToolkitCancellationError $_) {break};$skipped++;$notes.Add($file.FullName+': '+$_.Exception.Message)}
        $processed++
    }
    Write-Progress -Id 1 -Activity ('Cleaning '+$Section) -Completed
    $cancelled=Test-ToolkitCancellation
    $after=[pscustomobject]@{Files=@();Notes=@()}
    if (!$cancelled) {
        try {
            Write-ToolkitStage ('Measuring '+$Section+' after cleanup')
            $after=Get-ToolkitInventory $root
        } catch {if (Test-ToolkitCancellationError $_) {$cancelled=$true} else {throw}}
    }
    foreach ($note in $after.Notes) { $notes.Add($note) }
    $row = [pscustomobject]@{
        Section=$Section
        BeforeMB=if ($before.Notes.Count) {$null} else {[math]::Round(($before.Files | Measure-Object Length -Sum).Sum/1MB,2)}
        AfterMB=if ($cancelled -or $after.Notes.Count) {$null} else {[math]::Round(($after.Files | Measure-Object Length -Sum).Sum/1MB,2)}
        FreedMB=[math]::Round($freed/1MB,2);DeletedCount=$deleted;SkippedCount=$skipped;InspectionIssues=$before.Notes.Count+$after.Notes.Count
        Status=if ($cancelled) {'CANCELLED'} elseif ($before.Notes.Count -and !$before.Files.Count) {'FAILED'} elseif ($notes.Count) {'PARTIAL'} else {'SUCCESS'}
    }
    if ($cancelled) {$row | Add-Member NoteProperty UnprocessedFiles ($before.Files.Count-$processed);Write-Host 'Cleanup stopped. Deleted files remain deleted; after-size was not measured.'}
    Write-Host ($row | Format-Table -AutoSize | Out-String).TrimEnd()
    foreach ($note in $notes) { Write-Host ('Skipped/unavailable: '+$note) }
    return $row
}
$result = Invoke-ToolkitGuarded 'Temp' $TargetProfilePath -Confirmed:$Confirmed -Body {
    param($profile)
    $rows = New-Object 'Collections.Generic.List[object]'
    foreach ($section in @(@('Selected-profile Temp',(Join-Path $profile 'AppData\Local\Temp')),@('Windows Temp',(Join-Path $env:SystemRoot 'Temp')))) {
        if (Test-ToolkitCancellation) {break}
        try { $rows.Add((Invoke-SafeTempCleanup $section[0] $section[1])) }
        catch {
            $sectionStatus=if (Test-ToolkitCancellationError $_) {'CANCELLED'} else {'FAILED'}
            $rows.Add([pscustomobject]@{Section=$section[0];BeforeMB=$null;AfterMB=$null;FreedMB=0;DeletedCount=0;SkippedCount=0;Status=$sectionStatus});Write-Host $_.Exception.Message
        }
    }
    $status = if ((Test-ToolkitCancellation) -or @($rows | Where-Object Status -eq 'CANCELLED').Count) {'CANCELLED'} elseif (@($rows | Where-Object Status -eq 'FAILED').Count) {'FAILED'} elseif (@($rows | Where-Object Status -ne 'SUCCESS').Count) {'PARTIAL'} else {'SUCCESS'}
    $message=if ($status -eq 'CANCELLED') {'Cleanup cancelled. Review completed sections and deleted counts. Deleted files are not restored; unstarted sections were skipped.'} else {'Temp cleanup finished. Review deleted/skipped counts and before/after sizes.'}
    New-ToolkitResult 'Temp' $status $message ([pscustomobject]@{Rows=@($rows.ToArray())})
}
Write-Host ($result.Status+': '+$result.Message)
Write-Output $result
exit $result.ExitCode
