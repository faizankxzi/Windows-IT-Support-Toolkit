param([string]$TargetProfilePath=$env:USERPROFILE,[ValidateSet('Normal','Force')][string]$Mode='Force',[switch]$Confirmed)
. (Join-Path $PSScriptRoot 'Toolkit.Engine.ps1')
$result=Invoke-ToolkitGuarded 'GPUpdate' $TargetProfilePath -Body {
    param($profile)
    Write-ToolkitStage ('Refreshing Group Policy ('+$Mode+')')
    $arguments=@('/wait:-1')
    if ($Mode -eq 'Force') { $arguments=@('/force','/wait:-1') }
    Invoke-ToolkitNative 'gpupdate.exe' $arguments
    New-ToolkitResult 'GPUpdate' 'SUCCESS' 'Policy refresh command completed for the computer and running account. Review any logoff/restart request; none is accepted automatically.'
}
Write-Host ($result.Status+': '+$result.Message)
Write-Output $result
exit $result.ExitCode
