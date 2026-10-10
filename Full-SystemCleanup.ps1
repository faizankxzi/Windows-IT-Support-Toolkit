param([string]$TargetProfilePath,[ValidateSet('CheckOnly','Scan','Full')][string]$DISMMode='Full',[switch]$Confirmed)
. (Join-Path $PSScriptRoot 'Toolkit.Engine.ps1')
function Invoke-MaintenanceReport {
    param($Profile,$Label,$RunId)
    try {
        $global:LASTEXITCODE=$null
        $items=@(& (Join-Path $PSScriptRoot 'Generate-HealthReportHTML.ps1') -TargetProfilePath $Profile -ReportLabel $Label -RunId $RunId -NoOpen)
        $code=$LASTEXITCODE
        $found=@($items | Where-Object { $_.PSObject.Properties['ToolkitResult'] })
        if ($found.Count -ne 1 -or $null -eq $code -or $found[0].ExitCode -ne $code) { throw 'Report result could not be verified.' }
        return $found[0]
    } catch { return New-ToolkitResult 'Report' 'FAILED' $_.Exception.Message }
}
$result=Invoke-ToolkitGuarded 'Maintenance' $TargetProfilePath -Confirmed:$Confirmed -Body {
    param($profile)
    $runId=[guid]::NewGuid().ToString('N')
    $reports=New-Object 'Collections.Generic.List[object]'
    $tasks=New-Object 'Collections.Generic.List[object]'
    Write-ToolkitStage 'Saving before-maintenance report'
    $reports.Add((Invoke-MaintenanceReport $profile 'BeforeMaintenance' $runId))
    $cancelled=Test-ToolkitCancellation
    try {
        foreach ($action in @('Temp','Recycle','GPUpdate','DISM','SFC')) {
            if (Test-ToolkitCancellation) {$cancelled=$true;break}
            Write-ToolkitStage ('Full maintenance: '+$action)
            $mode=if ($action -eq 'GPUpdate') {'Force'} else {$DISMMode}
            $task=Invoke-ToolkitTask $action $profile -Mode $mode -Confirmed
            $tasks.Add($task)
            if ($task.Status -eq 'CANCELLED') {$cancelled=$true;break}
        }
    } catch {
        if (Test-ToolkitCancellationError $_) {$cancelled=$true} else {throw}
    } finally {
        if (Test-ToolkitCancellation) {
            $cancelled=$true
            $reports.Add((New-ToolkitResult 'Report' 'CANCELLED' 'After report not generated because maintenance was cancelled.'))
        } else {
            try {
                Write-ToolkitStage 'Saving after-maintenance report'
                $reports.Add((Invoke-MaintenanceReport $profile 'AfterMaintenance' $runId))
            } catch {
                if (Test-ToolkitCancellationError $_) {
                    $cancelled=$true
                    $reports.Add((New-ToolkitResult 'Report' 'CANCELLED' 'After report cancelled.'))
                } else {throw}
            }
        }
    }
    $cancelled=$cancelled -or (Test-ToolkitCancellation) -or @($reports | Where-Object Status -eq 'CANCELLED').Count -gt 0
    $maintenance=if (@($tasks | Where-Object Status -eq 'FAILED').Count) {'FAILED'} elseif ($cancelled -and $tasks.Count -lt 5) {'CANCELLED'} elseif (@($tasks | Where-Object Status -eq 'CANCELLED').Count) {'CANCELLED'} elseif (@($tasks | Where-Object Status -ne 'SUCCESS').Count) {'PARTIAL'} else {'SUCCESS'}
    $reportStatus=if (@($reports | Where-Object Status -eq 'FAILED').Count) {'FAILED'} elseif (@($reports | Where-Object Status -eq 'CANCELLED').Count) {'CANCELLED'} elseif (@($reports | Where-Object Status -ne 'SUCCESS').Count) {'PARTIAL'} else {'SUCCESS'}
    $status=if ($cancelled) {'CANCELLED'} elseif ($maintenance -eq 'FAILED') {'FAILED'} elseif ($maintenance -ne 'SUCCESS' -or $reportStatus -ne 'SUCCESS') {'PARTIAL'} else {'SUCCESS'}
    $taskRows=@($tasks | ForEach-Object {[pscustomobject]@{Task=$_.Action;Status=$_.Status;Message=$_.Message}})
    foreach ($action in @('Temp','Recycle','GPUpdate','DISM','SFC')) {
        if (!@($tasks | Where-Object Action -eq $action).Count) {$taskRows+=([pscustomobject]@{Task=$action;Status='NOT_RUN';Message='Skipped after cancellation.'})}
    }
    $reportRows=@(for ($i=0;$i -lt $reports.Count;$i++) {[pscustomobject]@{Report=@('Before','After')[$i];Status=$reports[$i].Status;Message=$reports[$i].Message}})
    $cleanupRows=@($tasks | Where-Object Action -eq 'Temp' | ForEach-Object { $_.Details.Rows })
    $links=@($reports | ForEach-Object { $_.Details.Reports } | Where-Object { $null -ne $_ })
    Write-Host ($taskRows | Format-Table -Wrap | Out-String).TrimEnd()
    Write-Host ($reportRows | Format-Table -Wrap | Out-String).TrimEnd()
    $message=if ($cancelled) {'Maintenance cancelled. Completed work and saved reports are retained; remaining steps were skipped. Changes already made are not undone.'} else {'Maintenance and report-generation outcomes are shown separately.'}
    New-ToolkitResult 'Maintenance' $status $message ([pscustomobject]@{
        Rows=$cleanupRows;TaskResults=$taskRows;ReportResults=$reportRows;Reports=$links
        MaintenanceStatus=$maintenance;ReportStatus=$reportStatus;RunId=$runId
    })
}
Write-Host ($result.Status+': '+$result.Message)
Write-Output $result
exit $result.ExitCode
