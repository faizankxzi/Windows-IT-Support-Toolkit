# IT Support Toolkit

An internal Windows IT support prototype, shared as a portfolio showcase, with an
interactive browser simulation for exploring its interface.

**[Try the live browser demo](https://faizankxzi.github.io/Windows-IT-Support-Toolkit/)**

The Windows application performs real maintenance through PowerShell. The browser
demo uses fictional data only and has no access to your computer. This remains a
prototype; real Windows maintenance still needs the VM checks below.

A portable Windows PowerShell toolkit for health reports, temporary-file cleanup,
Recycle Bin cleanup, Group Policy refresh, SFC and DISM. Keep the scripts together.
It uses Windows' built-in desktop controls; there are no packages to install.

## Open the browser demo

Use the live link above, or double-click **docs/index.html** after copying this
folder. No installation, build step or server is required. Relative assets also
support hosting beneath this repository's GitHub Pages path.

The demo recreates the Windows menu, task choices, inline cleanup confirmations,
live sample output, progress and results. Try the fictional target profiles and
Preview scenarios for success, locked files, report failure and task failure.
Reports stay inside the page. Full maintenance retains separate before/after
snapshots and completed work when cancelled. Repeated cleanup uses the remaining
sample data rather than claiming the same space twice.

**Cancel task** stops the simulation. Other tasks and **Reset Demo** stay unavailable
until it stops; then Reset restores the initial fictional data and clears reports
and results. Reloading also starts a fresh session. Animations are always enabled,
with no animation toggle. Timings and command results are explicitly simulated.

The persistent notice reads: **Interactive simulation · Sample data · No access to your computer**.
There is no backend, telemetry, device detection or persistent storage. The demo
does not run PowerShell, scan Windows or read local files. Its implemented behaviour
and sample measurements are documented in [DEMO-SPEC.md](DEMO-SPEC.md).

## Open the Windows toolkit

Double-click **Start-ToolkitGUI.bat**. Windows may ask for administrator access once
at launch. If elevation is cancelled, reports remain available and maintenance
buttons are disabled. Use Windows PowerShell 5.1 on Windows 10 or 11.

The menu becomes the task screen while work runs. Output, elapsed time and the
current stage appear there. Results appear in the same window afterwards.
Progress uses a percentage only when file counts or Windows command output make
one available; otherwise the bar animates without a guessed finishing time.

Cleanup asks for confirmation inside the window. GPUpdate and DISM show their mode
choices. Reports open only when you click **Open report**.

The desktop UI uses coloured tool groups, rounded cards and buttons, hover effects,
screen transitions and striped progress bars. These are built-in Windows controls;
no browser, web server or animation packages are required. Screen and icon motion
respect Windows' client-area animation setting.

Use **Cancel task** to stop a running task. The button changes to **Cancelling...**
and other tasks remain blocked until the worker exits. Cleanup stops between files;
full maintenance skips remaining steps and retains completed results and saved
reports. After-size measurements or an after report may be skipped, and are not
shown as successful or as zero.

For SFC, DISM and GPUpdate, cancellation terminates the toolkit's command and its
child processes. Windows servicing already handed to a system service may continue.
Individual Windows calls, including Recycle Bin deletion and system-information
queries, must return before the worker can stop. **Cancel does not undo deleted
files, policy changes or repairs already applied.** Interrupted repairs may need
to be rerun; real cancellation behaviour still requires VM verification.
Closing the window remains blocked while work is running or stopping.

## Try the UI without changing Windows

From PowerShell in this folder:

~~~powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Start-ToolkitGUI.ps1 -Preview
~~~

The yellow Preview badge means every task is simulated. The scenario dropdown
demonstrates success, locked files, report failure and task failure. Preview does
not delete files, run maintenance commands, save reports or open folders.

The console menu is also available:

~~~powershell
.\IT-Toolkit.ps1 -TargetProfilePath 'C:\Users\Example User'
.\IT-Toolkit.ps1 -Preview
~~~

Run the real console menu from an administrator PowerShell for maintenance.
Console cleanup requires typing YES. Its output and results stay in the console;
saved report paths are printed.

## Scope and files

The **running account** is the account executing PowerShell, including any different
administrator used for elevation. The **target profile** selects whose Temp,
Downloads and Outlook cache are inspected. Selecting it does not change accounts.

- Temp cleanup deletes ordinary files inside that profile's AppData\Local\Temp
  and the shared Windows Temp folder. Locked files are skipped and reported.
  Redirected folders/links are refused or skipped; Downloads and Outlook files
  are measured only. Empty directories are left in place.
- Recycle Bin cleanup affects the running account's bin across its drives.
- GPUpdate affects computer and running-account policy. It never deletes policy
  folders or stored credentials, and never accepts a reboot/logoff automatically.
- SFC checks protected Windows files. DISM offers CheckHealth, CheckHealth +
  ScanHealth, or all three steps including RestoreHealth. Full maintenance uses
  the DISM mode selected on its mode screen.
- Full maintenance saves separate before and after reports. Maintenance outcomes
  and report-generation outcomes are listed separately. Repairs can require
  Windows Update access and a later restart. Command completion alone does not
  prove that corruption was repaired; review the activity output.

**Start-ToolkitGUI.ps1** contains the window. **IT-Toolkit.ps1** contains the console
menu. The individual task scripts remain separate. **Toolkit.Engine.ps1** shares
profile validation, progress/output handling, measurements and a maintenance lock
that prevents concurrent tasks across toolkit windows and copies.

Reports are saved as new HTML files in **Reports**. Existing reports are not
overwritten. Unavailable measurements are labelled, not shown as healthy zeros.

## Verification and release status

Browser simulation checks covered task flows, cancellation, repeated runs, reset,
report snapshots and sample-data consistency. The interface was inspected at
desktop and narrow widths. Final publication smoke checks cover report generation
and viewing, cancellation, reset, responsive layout and browser-console errors.
Direct file opening was checked through relative asset and classic-script review;
the automated browser environment cannot navigate to file URLs. Full touch and
200% zoom testing remain unverified. These demo checks do not validate Windows
maintenance operations.

Both interfaces were tested with simulated/mocked operations. Checks covered
button navigation, live output, blocked overlapping clicks, explicit report
opening, paths with spaces/brackets/apostrophes, missing elevation, invalid
profiles, simulated locked files, separate reports and failure results. A harmless
output fixture tested stdout/stderr streaming, UTF-16, percentages and nonzero
exits. Redirected-folder refusal and the maintenance lock were checked. The
displayed preview window was checked at a smaller size and while closing during
a task. Cancel was checked for every GUI task, during mocked cleanup and full
maintenance, and against a harmless command with a child process. Those checks
verified the stopping screen, completed-work records, skipped steps, fresh tasks
after cancellation, and release of the lock only after the worker finished.

**Real cleanup, SFC, DISM, GPUpdate, Recycle Bin deletion, UAC and elevation with
different administrator credentials remain unverified.** No disposable Windows VM
was available. Before relying on real maintenance operations, use a VM snapshot and:

1. Copy the toolkit to a folder with spaces. Launch the BAT, cancel UAC, and
   confirm diagnostics work while maintenance stays disabled. Then relaunch with
   a different administrator and check that both identities/scopes are clear.
2. Create a test profile with ordinary and locked Temp files. Add sentinel files
   in Downloads and outside Temp; put a junction inside Temp pointing outside it.
   Run cleanup in both interfaces. Check before/after sizes, skipped files,
   untouched sentinels, and that the junction target is untouched.
3. Populate the running account's Recycle Bin, select the other profile, and check
   that only the running account's bin is emptied.
4. Run both GPUpdate modes, SFC and each DISM mode. Confirm live output, reported
   Windows percentages when present, correct failure results and no extra task
   console windows. Start a task from a second toolkit copy; it must report busy.
5. Run full maintenance. Check that two report files survive with separate
   outcomes. Make the Reports folder unwritable and repeat: report failures must
   not turn successful maintenance into failed maintenance or hide failed tasks.
6. Cancel during folder measurement, Temp cleanup, Recycle Bin cleanup and each
   native scan/repair. Verify completed work is retained, no later steps start,
   and another toolkit stays blocked until the command stops. Inspect Windows
   servicing state after interrupted repairs and rerun the repair if needed.

Generated **Reports**, **HealthReport.html**, local backups and test output are
excluded from this publication copy. The .gitignore keeps generated reports and
local development output out of future commits; source scripts and screenshots
remain eligible for inclusion. Reports contain real account names, computer
details, paths and storage data, so review the exact files being committed.
**The license decision is pending.**
