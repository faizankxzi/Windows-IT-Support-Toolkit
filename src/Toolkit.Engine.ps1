# Shared task helpers. The GUI runs these scripts in a background PowerShell
# runspace; task output/progress stays inside the toolkit window.
function Test-ToolkitCancellation {
    $source=Get-Variable -Name ToolkitCancellation -Scope Global -ValueOnly -ErrorAction Ignore
    return $null -ne $source -and $source.IsCancellationRequested
}
function Assert-ToolkitNotCancelled {
    if (Test-ToolkitCancellation) {throw (New-Object OperationCanceledException('Cancellation requested. Changes already made are not undone.'))}
}
function Test-ToolkitCancellationError {
    param($Record)
    $exception=$Record.Exception
    while ($null -ne $exception) {
        if ($exception -is [OperationCanceledException]) {return $true}
        $exception=$exception.InnerException
    }
    return $false
}

function Get-ToolkitIdentity {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    [pscustomobject]@{
        Account = $identity.Name; Computer = $env:COMPUTERNAME
        Administrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

function Get-ToolkitProfiles {
    foreach ($key in (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ErrorAction Stop)) {
        if ($key.PSChildName -notmatch '^(S-1-5-21-\d+-\d+-\d+-\d+|S-1-12-1-\d+-\d+-\d+-\d+)$') { continue }
        $path = [Environment]::ExpandEnvironmentVariables((Get-ItemProperty -LiteralPath $key.PSPath -Name ProfileImagePath -ErrorAction Stop).ProfileImagePath)
        if (Test-Path -LiteralPath $path -PathType Container) {
            [pscustomobject]@{ Name = Split-Path $path -Leaf; Path = $path.TrimEnd('\') }
        }
    }
}

function Get-ToolkitDirectory {
    param([string]$Path)
    if ($Path -notmatch '^[A-Za-z]:\\' -or $Path.StartsWith('\\')) { throw 'Choose an absolute local folder.' }
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($item -isnot [IO.DirectoryInfo]) { throw 'The selected path is not a folder.' }
    $parent = $item
    while ($null -ne $parent) {
        if ($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw ('Redirected folders are not supported: ' + $parent.FullName) }
        $parent = $parent.Parent
    }
    return $item.FullName.TrimEnd('\')
}

function Resolve-ToolkitProfile {
    param([string]$Path)
    $resolved = Get-ToolkitDirectory $Path
    if (@(Get-ToolkitProfiles | Where-Object { $_.Path -eq $resolved }).Count -ne 1) { throw 'Choose an existing registered Windows user profile.' }
    return $resolved
}

function Get-ToolkitInventory {
    param([string]$Path)
    $files = New-Object 'Collections.Generic.List[object]'
    $notes = New-Object 'Collections.Generic.List[string]'
    $pending = New-Object 'Collections.Generic.Stack[string]'
    try { $pending.Push((Get-ToolkitDirectory $Path)) } catch { $notes.Add($_.Exception.Message) }
    while ($pending.Count) {
        Assert-ToolkitNotCancelled
        $directory = $pending.Pop()
        try {
            $null = Get-ToolkitDirectory $directory
            foreach ($item in (Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
                Assert-ToolkitNotCancelled
                if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { $notes.Add('Skipped redirected path: ' + $item.FullName) }
                elseif ($item -is [IO.DirectoryInfo]) { $pending.Push($item.FullName) }
                elseif ($item -is [IO.FileInfo]) { $files.Add($item) }
            }
        } catch { if (Test-ToolkitCancellationError $_) {throw};$notes.Add($_.Exception.Message) }
    }
    [pscustomobject]@{ Files = @($files.ToArray()); Notes = @($notes.ToArray()) }
}

function Get-ToolkitFolderSize {
    param([string]$Path)
    if (!(Test-Path -LiteralPath $Path)) { return [pscustomobject]@{MB=$null;Status='NOT_FOUND';Notes='Folder not found.'} }
    $inventory = Get-ToolkitInventory $Path
    [pscustomobject]@{
        MB = if ($inventory.Notes.Count) { $null } else { [math]::Round(($inventory.Files | Measure-Object Length -Sum).Sum / 1MB, 2) }
        Status = if ($inventory.Notes.Count) { 'UNAVAILABLE' } else { 'OK' }
        Notes = $inventory.Notes -join '; '
    }
}

function New-ToolkitResult {
    param([string]$Action,[string]$Status,[string]$Message,$Details=$null)
    $codes = @{SUCCESS=0;FAILED=1;PARTIAL=2;CANCELLED=3;BUSY=4}
    [pscustomobject]@{
        ToolkitResult=$true; Action=$Action; Status=$Status; ExitCode=$codes[$Status]
        Message=$Message; Details=$Details; Finished=(Get-Date).ToString('o')
    }
}

function Write-ToolkitStage {
    param([string]$Text)
    Assert-ToolkitNotCancelled
    Write-Progress -Id 0 -Activity $Text -Status 'Working...' -PercentComplete -1
    Write-Host $Text
}

function Enter-ToolkitLock {
    $name = 'Global\ITSupportToolkit-Maintenance'
    try { $mutex = [Threading.Mutex]::OpenExisting($name) }
    catch {
        $acl = New-Object Security.AccessControl.MutexSecurity
        $sid = New-Object Security.Principal.SecurityIdentifier('S-1-5-11')
        $rights = [Security.AccessControl.MutexRights]::Synchronize -bor [Security.AccessControl.MutexRights]::Modify
        $acl.AddAccessRule((New-Object Security.AccessControl.MutexAccessRule($sid,$rights,[Security.AccessControl.AccessControlType]::Allow)))
        $created = $false
        $mutex = New-Object Threading.Mutex($false,$name,[ref]$created,$acl)
    }
    try {
        try { $acquired = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $acquired = $true }
        if (!$acquired) { $mutex.Dispose(); return $null }
        return $mutex
    } catch { $mutex.Dispose(); throw }
}

function Invoke-ToolkitGuarded {
    param([string]$Action,[string]$TargetProfilePath,[switch]$Confirmed,[scriptblock]$Body)
    $lock = $null
    try {
        Assert-ToolkitNotCancelled
        $profile = Resolve-ToolkitProfile $TargetProfilePath
        if (!(Get-ToolkitIdentity).Administrator) { throw 'Administrator access is required. No maintenance started.' }
        if ($Action -in @('Temp','Recycle','Maintenance') -and !$Confirmed) {
            Write-Host ('Running account: ' + (Get-ToolkitIdentity).Account)
            Write-Host ('Target profile: ' + $profile)
            $scope = switch ($Action) {
                'Temp' { 'Delete ordinary files in selected-profile Temp AND Windows Temp.' }
                'Recycle' { 'Permanently empty the running account Recycle Bin across its drives.' }
                'Maintenance' { 'Delete selected-profile/Windows Temp files and empty the running account Recycle Bin, then refresh policy and run repairs.' }
            }
            Write-Host $scope -ForegroundColor Yellow
            if ((Read-Host 'Type YES to proceed') -cne 'YES') { return New-ToolkitResult $Action 'CANCELLED' 'No action started.' }
        }
        $lock = Enter-ToolkitLock
        if ($null -eq $lock) { return New-ToolkitResult $Action 'BUSY' 'Another toolkit maintenance task is already running.' }
        return & $Body $profile
    } catch {
        $status=if (Test-ToolkitCancellationError $_) {'CANCELLED'} else {'FAILED'}
        return New-ToolkitResult $Action $status $_.Exception.Message
    }
    finally { if ($null -ne $lock) { $lock.ReleaseMutex(); $lock.Dispose() } }
}

function Invoke-ToolkitNative {
    param([string]$File,[string[]]$Arguments)
    Assert-ToolkitNotCancelled
    $command = Get-Command $File -CommandType Application -ErrorAction Stop
    # No console is created. Both streams are drained together to avoid blocking.
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $command.Source
    $info.Arguments = $Arguments -join ' '
    $info.UseShellExecute = $false; $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    $info.RedirectStandardInput = $true
    # SFC writes UTF-16; other Windows tools use the system OEM code page.
    $encoding = if ([IO.Path]::GetFileName($File) -ieq 'sfc.exe') { [Text.Encoding]::Unicode } else { [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage) }
    $info.StandardOutputEncoding = $encoding; $info.StandardErrorEncoding = $encoding
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    $started=$false
    try {
        if (!$process.Start()) { throw 'The Windows command did not start.' }
        $started=$true
        # A native request for input cannot hang an invisible console. No reboot
        # or logoff is accepted; Windows output explains any required follow-up.
        $process.StandardInput.Close()
        $readers = @($process.StandardOutput,$process.StandardError)
        $pending = @($readers[0].ReadLineAsync(),$readers[1].ReadLineAsync())
        $stopRequested=$false
        while ($null -ne $pending[0] -or $null -ne $pending[1]) {
            if ((Test-ToolkitCancellation) -and !$stopRequested) {
                $stopRequested=$true
                if (!$process.HasExited) {Stop-ToolkitNativeProcess $process}
            }
            foreach ($index in @(0,1)) {
                for ($batch=0;$batch -lt 64;$batch++) {
                    if ($null -eq $pending[$index] -or !$pending[$index].IsCompleted) {break}
                    $line = $pending[$index].GetAwaiter().GetResult()
                    if ($null -eq $line) { $pending[$index] = $null;break }
                    if ($line.Trim()) { Write-ToolkitNativeLine $line.Trim() $File }
                    $pending[$index] = $readers[$index].ReadLineAsync()
                }
            }
            [Threading.Thread]::Sleep(25)
        }
        while (!$process.WaitForExit(100)) {
            if ((Test-ToolkitCancellation) -and !$stopRequested) {
                $stopRequested=$true
                Stop-ToolkitNativeProcess $process
            }
        }
        Write-Host ('Command exit code: ' + $process.ExitCode)
        Assert-ToolkitNotCancelled
        if ($process.ExitCode -ne 0) { throw ($File + ' failed with exit code ' + $process.ExitCode + '. Review the activity output.') }
    } catch {
        if ($started -and (Test-ToolkitCancellation) -and $process.HasExited) {Assert-ToolkitNotCancelled}
        throw
    } finally {
        # Never release the maintenance lock with our command still running,
        # including when reading redirected output fails.
        try {
            if ($started -and !$process.HasExited) {
                Stop-ToolkitNativeProcess $process
                $process.WaitForExit()
            }
        } finally {$process.Dispose()}
    }
}

function Stop-ToolkitNativeProcess {
    param([Diagnostics.Process]$Process)
    # Stop only this process tree, by the PID of the command we started.
    # Never stop processes by name or stop Windows services.
    if ($Process.HasExited) {return}
    Write-Host ('Cancellation: stopping toolkit command PID '+$Process.Id+' and its child processes.')
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=Join-Path ([Environment]::GetFolderPath('System')) 'taskkill.exe'
    $info.Arguments='/PID '+$Process.Id+' /T /F'
    $info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    $stopper=New-Object Diagnostics.Process
    $stopper.StartInfo=$info
    try {
        if (!$stopper.Start()) {throw 'The stop request could not start.'}
        $stdout=$stopper.StandardOutput.ReadToEndAsync();$stderr=$stopper.StandardError.ReadToEndAsync()
        if (!$stopper.WaitForExit(10000)) {$stopper.Kill();$stopper.WaitForExit();throw 'The stop request timed out.'}
        foreach ($output in @($stdout.GetAwaiter().GetResult(),$stderr.GetAwaiter().GetResult())) {if ($output.Trim()) {Write-Host $output.Trim()}}
        if (!$Process.HasExited) {Write-Host 'The command has not stopped. Waiting for it to finish before releasing the maintenance lock.'}
    } catch {Write-Host ('Could not stop the command: '+$_.Exception.Message+'. Waiting for it to finish.')}
    finally {$stopper.Dispose()}
}

function Write-ToolkitNativeLine {
    param([string]$Line,[string]$File)
    Write-Host $Line
    if ($File -match '(^|[\\/])(dism|sfc)\.exe$' -and $Line -match '(?<![\d.])(\d{1,3}(?:[.,]\d+)?)\s*%') {
        $percent=[double]::Parse($Matches[1].Replace(',','.'),[Globalization.CultureInfo]::InvariantCulture)
        if ($percent -ge 0 -and $percent -le 100) {
            Write-Progress -Id 1 -Activity ([IO.Path]::GetFileName($File)+' - Windows-reported progress') -Status $Line -PercentComplete ([int][math]::Floor($percent))
        }
    }
}

function Get-ToolkitHealth {
    param([string]$TargetProfilePath)
    $profile = Resolve-ToolkitProfile $TargetProfilePath
    $rows = New-Object 'Collections.Generic.List[object]'
    function Add-Row { param($Name,$Value,$Status='OK',$Note=''); $rows.Add([pscustomobject]@{Check=$Name;Value=$Value;Status=$Status;Notes=$Note}) }
    Write-ToolkitStage 'Collecting disk and memory information'
    try {
        $disk = Get-PSDrive -Name $env:SystemDrive.TrimEnd(':') -ErrorAction Stop
        if ($null -eq $disk.Free -or $null -eq $disk.Used) {throw 'Disk measurements are unavailable.'}
        $free = [math]::Round($disk.Free/1GB,2)
        Add-Row 'Disk used' ([string][math]::Round($disk.Used/1GB,2)+' GB')
        Add-Row 'Disk free' ($free.ToString()+' GB') $(if ($free -lt 10) {'CRITICAL'} else {'OK'})
    } catch { Add-Row 'Disk information' 'Unavailable' 'UNAVAILABLE' $_.Exception.Message }
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        if ($null -eq $os.LastBootUpTime -or $null -eq $os.TotalVisibleMemorySize -or $null -eq $os.FreePhysicalMemory) {throw 'Memory or boot-time measurements are unavailable.'}
        $days = [math]::Round(((Get-Date)-$os.LastBootUpTime).TotalDays,2)
        Add-Row 'Total RAM' ([string][math]::Round($os.TotalVisibleMemorySize/1MB,2)+' GB')
        Add-Row 'Free RAM' ([string][math]::Round($os.FreePhysicalMemory/1MB,2)+' GB')
        Add-Row 'Last reboot' $os.LastBootUpTime
        Add-Row 'Uptime' ($days.ToString()+' days') $(if ($days -gt 14) {'CRITICAL'} elseif ($days -gt 7) {'WARNING'} else {'OK'})
    } catch { Add-Row 'Memory and uptime' 'Unavailable' 'UNAVAILABLE' $_.Exception.Message }
    Write-ToolkitStage 'Measuring profile folders and Windows Temp'
    foreach ($folder in @(
        @('Selected-profile Temp',(Join-Path $profile 'AppData\Local\Temp')),
        @('Windows Temp',(Join-Path $env:SystemRoot 'Temp')),
        @('Downloads',(Join-Path $profile 'Downloads'))
    )) {
        $size = Get-ToolkitFolderSize $folder[1]
        $status = if ($size.Status -ne 'OK') {$size.Status} elseif ($size.MB -gt 1000) {'WARNING'} else {'OK'}
        Add-Row $folder[0] $(if ($null -eq $size.MB) {$size.Status} else {$size.MB.ToString()+' MB'}) $status $size.Notes
    }
    Write-ToolkitStage 'Checking Outlook cache and running-account Recycle Bin'
    try {
        $ostFiles = @()
        foreach ($folder in @((Join-Path $profile 'AppData\Local\Microsoft\Outlook'),(Join-Path $profile 'Documents\Outlook'))) {
            Assert-ToolkitNotCancelled
            if (Test-Path -LiteralPath $folder) {
                $null = Get-ToolkitDirectory $folder
                $ostFiles += Get-ChildItem -LiteralPath $folder -Filter '*.ost' -File -ErrorAction Stop | Where-Object { !($_.Attributes -band [IO.FileAttributes]::ReparsePoint) }
            }
        }
        $ost = $ostFiles | Sort-Object Length -Descending | Select-Object -First 1
        if ($null -eq $ost) { Add-Row 'Outlook OST' 'No OST found in the two checked folders' 'NOT_FOUND' }
        else {
            $gb = [math]::Round($ost.Length/1GB,2)
            Add-Row 'Outlook OST' ($gb.ToString()+' GB') $(if ($gb -ge 48) {'CRITICAL'} elseif ($gb -ge 20) {'WARNING'} else {'OK'}) $ost.FullName
        }
    } catch { if (Test-ToolkitCancellationError $_) {throw};Add-Row 'Outlook OST' 'Unavailable' 'UNAVAILABLE' $_.Exception.Message }
    $shell = $null; $bin = $null
    try {
        $shell = New-Object -ComObject Shell.Application
        $bin = $shell.Namespace(10)
        if ($null -eq $bin) { throw 'The Recycle Bin could not be read.' }
        $bytes = 0
        foreach ($item in $bin.Items()) {
            Assert-ToolkitNotCancelled
            $size = $item.ExtendedProperty('System.Size')
            if ($null -eq $size) { throw 'A Recycle Bin item size is unavailable.' }
            $bytes += [long]$size
        }
        $mb = [math]::Round($bytes/1MB,2)
        Add-Row 'Running-account Recycle Bin' ($mb.ToString()+' MB') $(if ($mb -gt 500) {'WARNING'} else {'OK'})
    } catch { if (Test-ToolkitCancellationError $_) {throw};Add-Row 'Running-account Recycle Bin' 'Unavailable' 'UNAVAILABLE' $_.Exception.Message }
    finally {
        foreach ($com in @($bin,$shell)) { if ($null -ne $com -and [Runtime.InteropServices.Marshal]::IsComObject($com)) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($com) } }
    }
    [pscustomobject]@{Rows=@($rows.ToArray());Profile=$profile;Identity=Get-ToolkitIdentity}
}

function Invoke-ToolkitTask {
    param([string]$Action,[string]$TargetProfilePath,[string]$Mode='CheckOnly',[switch]$Confirmed,[switch]$Preview,[string]$Scenario='Success')
    if (Test-ToolkitCancellation) {return New-ToolkitResult $Action 'CANCELLED' 'Task cancelled before it started.'}
    if ($Preview) {
        try {return Invoke-ToolkitPreview $Action $TargetProfilePath $Scenario}
        catch {
            $status=if (Test-ToolkitCancellationError $_) {'CANCELLED'} else {'FAILED'}
            return New-ToolkitResult $Action $status $_.Exception.Message
        }
    }
    $files = @{Report='Generate-HealthReportHTML.ps1';ConsoleReport='SystemHealthReport.ps1';Temp='Cleanup-TempFiles.ps1';Recycle='Cleanup-RecycleBin.ps1';GPUpdate='Run-GPUpdate.ps1';SFC='Run-SFCScan.ps1';DISM='Run-DISMRepair.ps1';Maintenance='Full-SystemCleanup.ps1'}
    if (!$files.ContainsKey($Action)) { return New-ToolkitResult $Action 'FAILED' 'Unknown task.' }
    try {
        $arguments = @{TargetProfilePath=$TargetProfilePath}
        if ($Action -notin @('Report','ConsoleReport')) { $arguments.Confirmed=[bool]$Confirmed }
        if ($Action -eq 'Report') { $arguments.NoOpen=$true }
        if ($Action -in @('DISM','GPUpdate')) { $arguments.Mode=$Mode }
        if ($Action -eq 'Maintenance') { $arguments.DISMMode=$Mode }
        Write-Host ('Running account: '+(Get-ToolkitIdentity).Account)
        Write-Host ('Selected target profile: '+$TargetProfilePath)
        $global:LASTEXITCODE = $null
        $output = @(& (Join-Path $PSScriptRoot $files[$Action]) @arguments)
        $exitCode = $LASTEXITCODE
        $results = @($output | Where-Object { $_.PSObject.Properties['ToolkitResult'] -and $_.ToolkitResult })
        foreach ($item in $output) { if (!$item.PSObject.Properties['ToolkitResult']) { Write-Host ($item | Out-String).TrimEnd() } }
        if ($results.Count -ne 1 -or $null -eq $exitCode -or $results[0].ExitCode -ne $exitCode) { throw 'The task did not return a matching result and exit code. Its outcome is unknown.' }
        return $results[0]
    } catch {
        $status=if (Test-ToolkitCancellationError $_) {'CANCELLED'} else {'FAILED'}
        return New-ToolkitResult $Action $status $_.Exception.Message
    }
}

function Invoke-ToolkitPreview {
    param([string]$Action,[string]$TargetProfilePath,[string]$Scenario)
    foreach ($stage in @('Checking task scope','Measuring current usage','Running simulated task','Preparing results')) {
        Write-ToolkitStage $stage
        [Threading.Thread]::Sleep(250)
    }
    $details = [ordered]@{Rows=@();Reports=@();TaskResults=@();ReportResults=@()}
    $status='SUCCESS'; $message='Simulated task complete. No Windows commands ran and no files were deleted.'
    if ($Action -in @('Temp','Maintenance')) {
        for ($i=1;$i -le 10;$i++) {
            Assert-ToolkitNotCancelled
            Write-Progress -Id 1 -Activity 'Cleaning simulated files' -Status "$i of 10 files" -PercentComplete ($i*10)
            Write-Host ("Simulated file $i of 10")
            [Threading.Thread]::Sleep(60)
        }
        $details.Rows=@(
            [pscustomobject]@{Section='Selected-profile Temp';BeforeMB=256;AfterMB=16;FreedMB=240;DeletedCount=9;SkippedCount=1;Status='PARTIAL'},
            [pscustomobject]@{Section='Windows Temp';BeforeMB=128;AfterMB=0;FreedMB=128;DeletedCount=8;SkippedCount=0;Status='SUCCESS'}
        )
        if ($Scenario -eq 'LockedFiles') { $status='PARTIAL';$message='Simulated cleanup completed with one locked file skipped. No real files were deleted.' }
        else { $details.Rows[0].AfterMB=0;$details.Rows[0].FreedMB=256;$details.Rows[0].DeletedCount=10;$details.Rows[0].SkippedCount=0;$details.Rows[0].Status='SUCCESS' }
    }
    if ($Action -in @('Report','ConsoleReport')) {
        $details.Rows=@(
            [pscustomobject]@{Check='Disk free';Value='42 GB';Status='OK'},
            [pscustomobject]@{Check='Selected-profile Temp';Value='256 MB';Status='OK'},
            [pscustomobject]@{Check='Outlook OST';Value='No OST found';Status='NOT_FOUND'}
        )
    }
    if ($Action -eq 'Recycle') { $details.Rows=@([pscustomobject]@{Account='EXAMPLE\Technician';ItemsBefore=12;ItemsAfter=0;Status='SUCCESS'}) }
    if ($Action -eq 'Maintenance') {
        $details.MaintenanceStatus='SUCCESS';$details.ReportStatus='SUCCESS'
        $details.TaskResults=@('Temp','Recycle','GPUpdate','DISM','SFC' | ForEach-Object { [pscustomobject]@{Task=$_;Status='SUCCESS';Message='Simulated'} })
        $details.ReportResults=@([pscustomobject]@{Report='Before';Status='SUCCESS';Message='Simulated; no file saved'},[pscustomobject]@{Report='After';Status='SUCCESS';Message='Simulated; no file saved'})
        if ($Scenario -eq 'LockedFiles') {$details.MaintenanceStatus='PARTIAL';$details.TaskResults[0].Status='PARTIAL'}
        if ($Scenario -eq 'ReportFailure') { $status='PARTIAL';$details.ReportStatus='FAILED';$details.ReportResults[1].Status='FAILED';$details.ReportResults[1].Message='Simulated report-generation failure' }
    }
    if ($Scenario -eq 'ReportFailure' -and $Action -eq 'Maintenance') {$message='Simulated maintenance succeeded; the after report failed. No Windows commands ran.'}
    if ($Scenario -eq 'Failure') {
        $status='FAILED';$message='Simulated failure. No Windows commands ran.'
        if ($Action -eq 'Maintenance') {$details.MaintenanceStatus='FAILED';$details.TaskResults[0].Status='FAILED'}
    }
    Assert-ToolkitNotCancelled
    Write-Progress -Id 1 -Activity 'Simulated task' -Completed
    return New-ToolkitResult $Action $status $message ([pscustomobject]$details)
}
