param([string]$TargetProfilePath=$env:USERPROFILE,[switch]$Preview)
. (Join-Path $PSScriptRoot 'Toolkit.Engine.ps1')
try {
    $profile=if ($Preview) {'C:\Users\Sample User'} else {Resolve-ToolkitProfile $TargetProfilePath}
} catch {Write-Host $_.Exception.Message -ForegroundColor Red;return}
$identity=Get-ToolkitIdentity
if ($Preview) {Write-Host 'PREVIEW: all operations are simulated.' -ForegroundColor Yellow}
do {
    Write-Host ''
    Write-Host '===== IT SUPPORT AUTOMATION TOOLKIT =====' -ForegroundColor Cyan
    Write-Host ('Running as: '+$identity.Account+' | Administrator: '+$identity.Administrator)
    Write-Host ('Target profile: '+$profile+' (does not switch the running account)')
    Write-Host '1. Generate HTML Dashboard'
    Write-Host '2. Run Console Health Report'
    Write-Host '3. Clean Temp Files'
    Write-Host '4. Clean Recycle Bin'
    Write-Host '5. Run GPUpdate'
    Write-Host '6. Run SFC Scan'
    Write-Host '7. Full System Cleanup'
    Write-Host '8. Run DISM Repair'
    Write-Host '0. Exit'
    $choice=Read-Host 'Select an option'
    if ($choice -eq '0') {break}
    $actions=@{'1'='Report';'2'='ConsoleReport';'3'='Temp';'4'='Recycle';'5'='GPUpdate';'6'='SFC';'7'='Maintenance';'8'='DISM'}
    if (!$actions.ContainsKey($choice)) {Write-Host 'Choose 0-8.' -ForegroundColor Yellow;continue}
    $mode=if ($choice -eq '5') {'Force'} else {'Full'}
    $result=Invoke-ToolkitTask $actions[$choice] $profile -Mode $mode -Preview:$Preview
    Write-Host ($result.Status+': '+$result.Message) -ForegroundColor $(if ($result.Status -eq 'SUCCESS') {'Green'} elseif ($result.Status -eq 'FAILED') {'Red'} else {'Yellow'})
    foreach ($report in $result.Details.Reports) {Write-Host ('Saved report: '+$report.Path)}
    $null=Read-Host 'Press Enter to return to the menu'
} while ($true)
