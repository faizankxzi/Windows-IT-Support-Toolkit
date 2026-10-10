param([string]$TargetProfilePath=$env:USERPROFILE,[string]$ReportLabel='HealthReport',
    [ValidatePattern('^[a-fA-F0-9]{32}$')][string]$RunId=([guid]::NewGuid().ToString('N')),[switch]$NoOpen)
. (Join-Path $PSScriptRoot 'Toolkit.Engine.ps1')
try {
    $health=Get-ToolkitHealth $TargetProfilePath
    Write-ToolkitStage 'Saving the health report'
    $reportFolder=Join-Path (Split-Path $PSScriptRoot -Parent) 'Reports'
    if (!(Test-Path -LiteralPath $reportFolder)) { $null=New-Item -Path $reportFolder -ItemType Directory -ErrorAction Stop }
    $null=Get-ToolkitDirectory $reportFolder
    $label=$ReportLabel -replace '[^A-Za-z0-9_-]','_'
    $path=Join-Path $reportFolder ((Get-Date -Format 'yyyy-MM-dd-HHmmssfff')+'-'+$RunId+'-'+$label+'-'+[guid]::NewGuid().ToString('N')+'.html')
    function ConvertTo-ToolkitHtml { param($Value); [Net.WebUtility]::HtmlEncode([string]$Value) }
    $rows=($health.Rows | ForEach-Object { '<tr><td>'+(ConvertTo-ToolkitHtml $_.Check)+'</td><td>'+(ConvertTo-ToolkitHtml $_.Value)+'</td><td class="'+(ConvertTo-ToolkitHtml $_.Status)+'">'+(ConvertTo-ToolkitHtml $_.Status)+'</td><td>'+(ConvertTo-ToolkitHtml $_.Notes)+'</td></tr>' }) -join [Environment]::NewLine
    $status=if (@($health.Rows | Where-Object Status -eq 'UNAVAILABLE').Count) {'PARTIAL'} else {'SUCCESS'}
    $overall=if (@($health.Rows | Where-Object Status -eq 'CRITICAL').Count) {'CRITICAL'} elseif (@($health.Rows | Where-Object Status -eq 'WARNING').Count) {'WARNING'} elseif ($status -eq 'PARTIAL') {'INCOMPLETE'} else {'OK'}
    $html=@"
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>IT Support Toolkit - $(ConvertTo-ToolkitHtml $ReportLabel)</title>
<style>body{font:14px Segoe UI,Arial,sans-serif;background:#f0f2f5;color:#17212d;padding:24px}main{max-width:1100px;margin:auto;background:white;border:1px solid #d6dbe2;border-radius:8px;padding:24px}h1{font-size:24px}p{line-height:1.5}table{border-collapse:collapse;width:100%;font-size:13px}th,td{text-align:left;padding:12px;border-bottom:1px solid #e1e5eb;overflow-wrap:anywhere}th{background:#edf5ff}.OK{color:#178347}.WARNING,.UNAVAILABLE{color:#946500}.CRITICAL{color:#bd2525}.NOT_FOUND{color:#697586}</style>
</head><body><main><h1>System Health Report</h1><p>$(ConvertTo-ToolkitHtml $ReportLabel) | $(ConvertTo-ToolkitHtml (Get-Date))</p>
<p><b>Computer:</b> $(ConvertTo-ToolkitHtml $health.Identity.Computer)<br><b>Running account:</b> $(ConvertTo-ToolkitHtml $health.Identity.Account)<br><b>Selected target profile:</b> $(ConvertTo-ToolkitHtml $health.Profile)</p>
<h2>Overall: $(ConvertTo-ToolkitHtml $overall)</h2><p>Unavailable data is not a healthy zero. Selecting a profile does not switch accounts. Downloads and Outlook files are measured only.</p>
<table><thead><tr><th>Check</th><th>Value</th><th>Status</th><th>Notes</th></tr></thead><tbody>$rows</tbody></table>
<p>These measurements are a snapshot. They do not prove Windows repairs succeeded. Outlook is checked in two local cache folders only; no mailbox contents are inspected.</p></main></body></html>
"@
    $stream=New-Object IO.FileStream($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $bytes=(New-Object Text.UTF8Encoding($false)).GetBytes($html);$stream.Write($bytes,0,$bytes.Length) } finally {$stream.Dispose()}
    Write-Host ('Report saved: '+$path)
    $message='Report saved. Review any warnings or unavailable measurements.'
    if (Test-ToolkitCancellation) {$status='CANCELLED';$message='Cancel requested after saving the report. The saved file is retained.'}
    if (!$NoOpen -and $status -ne 'CANCELLED') { try { Start-Process -FilePath $path -ErrorAction Stop } catch { $status='PARTIAL';$message+=' The report viewer could not open: '+$_.Exception.Message } }
    $result=New-ToolkitResult 'Report' $status $message ([pscustomobject]@{
        Rows=$health.Rows;Reports=@([pscustomobject]@{Label=$ReportLabel;Path=$path});RunId=$RunId
    })
} catch {
    $status=if (Test-ToolkitCancellationError $_) {'CANCELLED'} else {'FAILED'}
    $result=New-ToolkitResult 'Report' $status $_.Exception.Message
}
Write-Host ($result.Status+': '+$result.Message)
Write-Output $result
exit $result.ExitCode

