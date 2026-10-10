param([string]$TargetProfilePath=$env:USERPROFILE,[ValidateSet('CheckOnly','Scan','Full')][string]$Mode='Full',[switch]$Confirmed)
. (Join-Path $PSScriptRoot 'Toolkit.Engine.ps1')
$result=Invoke-ToolkitGuarded 'DISM' $TargetProfilePath -Body {
    param($profile)
    $steps=@('CheckHealth')
    if ($Mode -in @('Scan','Full')) { $steps+='ScanHealth' }
    if ($Mode -eq 'Full') { $steps+='RestoreHealth' }
    foreach ($step in $steps) {
        Write-ToolkitStage ('DISM: '+$step)
        Invoke-ToolkitNative 'dism.exe' @('/Online','/Cleanup-Image',('/'+$step))
    }
    New-ToolkitResult 'DISM' 'SUCCESS' ('DISM '+$Mode+' command completed. Review output for findings and restart requirements.')
}
Write-Host ($result.Status+': '+$result.Message)
Write-Output $result
exit $result.ExitCode
