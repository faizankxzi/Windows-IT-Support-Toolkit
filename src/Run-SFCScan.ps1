param([string]$TargetProfilePath=$env:USERPROFILE,[switch]$Confirmed)
. (Join-Path $PSScriptRoot 'Toolkit.Engine.ps1')
$result=Invoke-ToolkitGuarded 'SFC' $TargetProfilePath -Body {
    param($profile)
    Write-ToolkitStage 'Running System File Checker'
    Invoke-ToolkitNative 'sfc.exe' @('/scannow')
    New-ToolkitResult 'SFC' 'SUCCESS' 'SFC command completed. Review its output for findings and any restart requirement.'
}
Write-Host ($result.Status+': '+$result.Message)
Write-Output $result
exit $result.ExitCode
