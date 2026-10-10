param([string]$TargetProfilePath=$env:USERPROFILE)
. (Join-Path $PSScriptRoot 'Toolkit.Engine.ps1')
try {
    $health=Get-ToolkitHealth $TargetProfilePath
    Write-Host ('Running account: '+$health.Identity.Account)
    Write-Host ('Selected target profile: '+$health.Profile)
    Write-Host ($health.Rows | Format-Table -Wrap | Out-String).TrimEnd()
    $status=if (@($health.Rows | Where-Object Status -eq 'UNAVAILABLE').Count) {'PARTIAL'} else {'SUCCESS'}
    $result=New-ToolkitResult 'ConsoleReport' $status 'Health measurements collected.' ([pscustomobject]@{Rows=$health.Rows})
} catch {
    $status=if (Test-ToolkitCancellationError $_) {'CANCELLED'} else {'FAILED'}
    $result=New-ToolkitResult 'ConsoleReport' $status $_.Exception.Message
}
Write-Output $result
exit $result.ExitCode
