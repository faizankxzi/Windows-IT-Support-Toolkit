param([string]$TargetProfilePath=$env:USERPROFILE,[switch]$Confirmed)
. (Join-Path $PSScriptRoot 'Toolkit.Engine.ps1')
$result = Invoke-ToolkitGuarded 'Recycle' $TargetProfilePath -Confirmed:$Confirmed -Body {
    param($profile)
    $shell=$null;$bin=$null
    try {
        Write-ToolkitStage 'Checking the running-account Recycle Bin'
        $shell=New-Object -ComObject Shell.Application
        $bin=$shell.Namespace(10)
        if ($null -eq $bin) { throw 'The running-account Recycle Bin could not be read.' }
        $before=$bin.Items().Count
        if ($before) { Write-ToolkitStage 'Emptying the running-account Recycle Bin';Clear-RecycleBin -Force -ErrorAction Stop }
        # Clear-RecycleBin is one Windows operation; let it return, then honour cancel.
        Write-Host 'Checking remaining Recycle Bin items'
        $after=$bin.Items().Count
        $status=if (Test-ToolkitCancellation) {'CANCELLED'} elseif ($after) {'PARTIAL'} else {'SUCCESS'}
        $row=[pscustomobject]@{Account=(Get-ToolkitIdentity).Account;ItemsBefore=$before;ItemsAfter=$after;Status=$status}
        Write-Host ($row | Format-Table -AutoSize | Out-String).TrimEnd()
        $message=if ($status -eq 'CANCELLED') {'Cancel requested. The Windows bin operation returned; any items already deleted remain deleted. Review the counts.'} else {'The running-account bin was targeted; selecting a profile does not switch accounts.'}
        New-ToolkitResult 'Recycle' $status $message ([pscustomobject]@{Rows=@($row)})
    } finally {
        foreach ($com in @($bin,$shell)) { if ($null -ne $com -and [Runtime.InteropServices.Marshal]::IsComObject($com)) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($com) } }
    }
}
Write-Host ($result.Status+': '+$result.Message)
Write-Output $result
exit $result.ExitCode
