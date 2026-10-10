# Windows IT Support Toolkit: browser-demo specification

Status: implemented browser simulation. This document records its behaviour and acceptance criteria.

## Purpose and authoritative references

This is a portfolio demonstration of the existing Windows toolkit, not a browser
administration tool. Every Windows command, file operation and reported measurement
is simulated. The Windows scripts remain the working internal-tool prototype.

Windows sources are in src/. Start-ToolkitGUI.bat stays at the repository root;
real reports are saved in the root Reports/ folder. This specification and the
browser assets are in docs/.

References inspected in this publication folder:

- `src/Start-ToolkitGUI.ps1`: layout, colours, eight menu cards, navigation, defaults,
  confirmations, live activity, completion banners, cancellation and report links.
- `src/Toolkit.Engine.ps1`: Preview fixtures, measurements, thresholds, task results
  and progress/output handling.
- `src/Generate-HealthReportHTML.ps1`: report content and overall-health calculation.
- `src/Cleanup-TempFiles.ps1`, `src/Cleanup-RecycleBin.ps1`, `src/Run-GPUpdate.ps1`,
  `src/Run-SFCScan.ps1`, `src/Run-DISMRepair.ps1` and `src/Full-SystemCleanup.ps1`: scopes,
  command choices, execution order, before/after records and cancellation.
- `src/IT-Toolkit.ps1`: confirms available operations. The browser demonstrates the
  desktop GUI, not a second interactive console interface.

The copied Windows GUI was exercised in Preview, including its displayed running,
cancelling and result screens. Engine Preview report and locked-file maintenance
results were also inspected. No real maintenance commands were run for this review.

Do not add Windows Update, antivirus, firewall, network, service or event-log
dashboards, installation tools, an escalated Group Policy reset, credential
deletion, mailbox inspection, file uploading, or any other unimplemented feature.
Earlier Lovable concepts are not the authoritative feature list.

## Persistent simulation notice

Keep this exact text visible on every screen, including reports:

**Interactive simulation · Sample data · No access to your computer**

Place it in a persistent header notice. Allow wrapping on small screens; never
truncate it or hide it when a task starts. Label activity as simulated output,
report locations as simulated locations, and the administrator badge as simulated
administrator access. Never imply that a real scan, repair or permission check ran.

## Appearance and responsive layout

Use the current GUI's appearance, not the original plain mockup:

- App title: **IT Support Toolkit**. Main content approximately 960 px wide,
  centred, with about 24 px content padding and a blue/teal/green header gradient.
- Header gradient: `#238FBB`, `#169FA5`, `#4EB58D`; page gradient: `#E1F2F5`,
  `#F4F8FB`, `#FAF1E8`; main text `#25313F`; secondary text `#667085`.
- Diagnostics `#159C9F`, Cleanup `#D97845`, Maintenance `#3D76C9`.
- White tool cards, coloured outlines and icon backgrounds, about 18 px corner
  radii. Hover lifts the card about 3 px and sweeps a tinted fill upward.
- Icons tilt about -8 degrees and gently pulse on hover. Primary buttons use the
  header gradient; buttons are rounded, sweep colour on hover, and shrink slightly
  when pressed. Red-outline Cancel uses `#B42318` text.
- Page changes fade in over roughly 360 ms with a 14 px settling motion; outgoing
  pages fade over 140 ms, and container height eases over 380 ms. Navigation
  and busy-state changes happen immediately; animations do not delay permissions.
- Running panel: pale blue, stage, elapsed time and rounded gradient progress bar.
  Activity: rounded dark panel `#14191F`, light text `#DFE8F2`, Consolas/system
  monospace. Result tables remain read-only.
- Result banners: green completion, amber partial/cancelled/busy, red failure.
  Use status text as well as colour.

Two tool columns and two account/profile columns on wider screens. Below about
640 px, stack both sets into one column. At 320 px there must be no page-level
horizontal overflow. Long fictional paths wrap. Tables may scroll horizontally
inside labelled containers or become equivalent labelled rows. Task output has a
bounded scroll area; Cancel and Back remain reachable through normal page scrolling.
The header notice remains visible without covering controls at 200% zoom.

Use system fonts and local inline SVG icons corresponding to the toolkit's icons;
do not rely on Windows-only icon fonts or an icon CDN. Hover is decoration, never
required for touch use. Per the requested design, browser animations are always
enabled: there is no toggle or reduced-motion override. Stages, timings, output
and progress meaning do not depend on decorative motion. Provide visible
keyboard focus, labelled inputs, native radio groups/buttons, semantic headings,
and a restrained live region for stage/result announcements, not every log line.

## Main menu and navigation

Account panel:

- Running as: `EXAMPLE\Technician`.
- Computer: `EXAMPLE-PC`.
- Badge: `Administrator (simulated)`.
- Target user profile: `Sample User` initially; also offer `Sample Admin`.
- Keep the GUI explanation: selecting a profile chooses whose files profile-based
  tasks work on; it does not switch the account running the toolkit.
- Retain the Preview scenario selector: `Success`, `LockedFiles`, `ReportFailure`,
  `Failure`, initially `Success`. Capture the chosen scenario at task start.

Cards, in the same order and groups as the Windows GUI:

| Group | Card | Destination |
| --- | --- | --- |
| Diagnostics | Generate Health Report | Running screen directly |
| Diagnostics | Open Reports Folder | Simulated reports list |
| Cleanup | Temp Cleanup | In-window confirmation |
| Cleanup | Recycle Bin Cleanup | In-window confirmation |
| Maintenance | Full System Maintenance | DISM options, then confirmation |
| Maintenance | GPUpdate | Normal/Force options |
| Maintenance | SFC Scan | Running screen directly |
| Maintenance | DISM Repair | DISM options |

Retain the existing card descriptions and each task's **Affects** and **How it may
help** text, with clear simulation wording where required. Do not add routine
browser alert/confirm popups. **Go back** returns to the menu without starting or
changing anything. **Back to toolkit** returns from results without resetting data.
Keep profile/scenario selection between tasks. Reopening an options page restores
the GUI's defaults: GPUpdate Force; DISM and full-maintenance DISM CheckHealth only.

## Fictional dataset and threshold rules

All values are authored sample data, not read from the visitor. Initialise a
fictional clock at `2026-01-15 12:00:00 UTC` and last reboot at
`2026-01-07 00:00:00 UTC`, giving 8.5 days uptime. The sample clock may advance by
the demo's logical elapsed duration; report timestamps and uptime must derive from
that same clock. Use a separate monotonic elapsed timer for animation scheduling.

| Measurement | Initial sample | Initial status |
| --- | --- | --- |
| System drive capacity (internal calculation only) | 256 GB | Not a new report row |
| Disk used | 214 GB | OK |
| Disk free | 42 GB | OK |
| Total RAM | 16 GB | OK |
| Free RAM | 6 GB | OK |
| Last reboot | Fictional date above | OK |
| Uptime | 8.5 days | WARNING |
| Sample User Temp | 256 MB, 10 files | OK |
| Shared Windows Temp | 128 MB, 8 files | OK |
| Sample User Downloads | 1536 MB | WARNING |
| Sample User Outlook OST | 24 GB | WARNING |
| Running-account Recycle Bin | 576 MB, 12 items | WARNING |
| Sample Admin Temp | 128 MB, 8 files | OK |
| Sample Admin Downloads | 768 MB | OK |
| Sample Admin Outlook OST | No OST in the two checked folders | NOT_FOUND |

Fictional profile paths are `C:\Users\Sample User` and `C:\Users\Sample Admin`.
Shared Temp is `C:\Windows\Temp`. Sample User's OST note may show
`C:\Users\Sample User\AppData\Local\Microsoft\Outlook\sample.ost`. These are display
strings only. Selecting Sample Admin changes profile measurements and cleanup
targets, not the running account, shared Temp or Recycle Bin. Nonselected-profile
Temp is part of the fictional occupied disk space and must remain unchanged.

Represent files and sizes explicitly, using integer bytes:

- Sample User Temp: files 1-8 are 24 MB each, file 9 is 48 MB, file 10 is 16 MB.
- Sample Admin Temp: eight files of 16 MB each.
- Windows Temp: eight files of 16 MB each.
- Recycle Bin: twelve items of 48 MB each, belonging to `EXAMPLE\Technician`.
- Downloads and OST sizes never change through this demo's operations.

Match PowerShell units: displayed MB = bytes / 2^20 and GB = bytes / 2^30. Round
displayed measurements to two decimals using half-to-even rounding, as the scripts
do. Test rounding separately rather than relying on JavaScript `toFixed` alone.

Exact implemented thresholds (after the corresponding measurement rounding):

| Check | Rule |
| --- | --- |
| Disk free | Below 10 GB is CRITICAL; 10 GB or above is OK |
| Uptime | Above 14 days is CRITICAL; above 7 through 14 is WARNING; 7 or below OK |
| Profile Temp, Windows Temp, Downloads | Above 1000 MB WARNING; otherwise OK |
| Largest Outlook OST | 48 GB or above CRITICAL; 20 through below 48 WARNING; below 20 OK |
| Running-account Recycle Bin | Above 500 MB WARNING; otherwise OK |
| RAM and last reboot | No extra threshold; available values are OK |

Use NOT_FOUND for missing folders/OST and UNAVAILABLE for unreadable measurements.
Unavailable values are not zero. No invented memory, disk-percentage or repair
health score. Overall report health is CRITICAL if any row is CRITICAL; otherwise
WARNING if any row is WARNING; otherwise INCOMPLETE if any row is UNAVAILABLE;
otherwise OK. A report can be successfully created while overall health is WARNING.
UNAVAILABLE makes report-generation status PARTIAL; ordinary health warnings do not.

## Shared running and result behaviour

Starting a task captures profile, mode and scenario in an immutable run request.
Replace the menu with the running screen. Show title, running account, captured
target profile, scope, benefit, stage, elapsed time, progress, and accumulating
sample activity. Keep the GUI's task-specific wording; label log lines as simulated.

Use one active task per demo instance. Disable/inert every task launcher, hidden
menu control, profile selector, scenario selector and Reset while running or
cancelling; also enforce a JavaScript busy guard against rapid or stale clicks.
Do not offer Back during work. There is no real cross-window Windows lock in this
demo: separate browser tabs run independent simulations.

Indeterminate stages show moving bands without percentages or time-to-finish
claims. Temp deletion progress comes from processed fixture files, including
skipped files. SFC/DISM may emit scripted percentage lines; display those values
as simulated command progress, not inferred time progress. GPUpdate and measurements
remain indeterminate. Do not add a new overall full-maintenance percentage.

Results reproduce the GUI's banner, message, running/target identity, relevant
read-only tables, explicit report buttons, expandable activity and Back button.
Statuses: SUCCESS (Task completed), PARTIAL (Completed with issues), FAILED (Task
failed), CANCELLED (Task cancelled), BUSY (Another maintenance task is running).
Unknown completion uses Outcome unknown and must not claim successful changes.
BUSY/unknown are supported outcomes, not extra visitor-facing scenario options.

Retain the completed run record in session memory when returning to the menu;
before/after report snapshots must never be recalculated from current data.
Do not add an unrelated task-history dashboard. A new task may replace the visible
result, but must not erase saved report snapshots or apply earlier mutations again.

## Each task's flow, stages and results

### Generate Health Report

Menu -> running -> results. No confirmation or mode choice.

Approximately 1.6 seconds: collect disk/RAM/boot data (0.3 s), measure profile
folders/Windows Temp (0.5 s), inspect sample OST/running-account bin (0.4 s), then
save an in-memory snapshot (0.4 s). The same budget applies to before/after reports.
Use the stage labels from Get-ToolkitHealth and the report script.

Result rows match the actual report's Check, Value, Status and Notes columns, with
the fictional measurements above. Keep the actual HTML report's simple white
panel/table, heading, identity and overall status in the report viewer; do not
replace it with the richer unimplemented Lovable dashboard. Creating a report
adds one simulated report entry and an explicit Open report button. Never auto-open.
No sample storage measurements change as a result of generating the report.

### Temp Cleanup

Menu -> confirmation -> running -> results. Confirmation uses the existing warning
that deleted files cannot be recovered from the Recycle Bin, while visibly stating
that this demo only changes sample data. Show both selected-profile Temp and shared
Windows Temp paths, running account and target profile. Start cleanup begins;
Go back does nothing.

Stages: measure selected-profile Temp before, process its files, measure after;
then repeat for Windows Temp. Allow approximately 3.5-4.5 seconds in total with
0.12-0.18 seconds per file and short measurement stages.

Display the same row fields as the script: Section, BeforeMB, AfterMB, FreedMB,
DeletedCount, SkippedCount, InspectionIssues and Status; label the MB/count columns
like the GUI. Notes identify skipped sample files. This operation touches neither
Downloads/OST nor the bin, and does not remove/recreate empty folders.

Fresh Sample User Success: profile 256 -> 0 MB, 10 deleted, zero skipped; Windows
128 -> 0 MB, 8 deleted, zero skipped. Total freed 384 MB.

LockedFiles: the final remaining Sample User Temp file (16 MB) is locked, or the
final remaining Sample Admin Temp file (16 MB) for that profile. On a fresh Sample
User run: 256 -> 16 MB, 9 deleted, 1 skipped, 240 MB freed; Windows 128 -> 0 MB,
8 deleted and 128 MB freed. Both sections remain separately recorded and overall
completion is PARTIAL. Do not lock or recreate a file that is already absent.

### Recycle Bin Cleanup

Menu -> confirmation -> running -> results. Confirmation targets only
`EXAMPLE\Technician`'s bin, regardless of selected profile. Retain the deletion
warning and simulation notice. Stages: inspect bin, empty sample items, inspect
remaining count; approximately 2 seconds total.

Fresh success: Account, ItemsBefore = 12, ItemsAfter = 0, Status = SUCCESS. Remove
576 MB from the sample bin; do not add a new MB column to the toolkit's bin result
table, although the next health report reflects its new size. Repeating on an
empty bin yields 0 -> 0 and frees nothing. Treat emptying as one atomic sample step.

### GPUpdate

Menu -> options -> running -> results. Normal applies changed policies; Force
reapplies all policies and is selected by default. Continue starts; Go back returns
to menu. No additional cleanup confirmation. Show computer and running-account
scope and chosen mode. No reset option, policy-folder deletion or credential clearing.

Approximately 2.5 seconds of indeterminate sample activity. Logs describe the
chosen command, computer policy and user policy. Command strings, if displayed,
match `gpupdate /wait:-1` or `gpupdate /force /wait:-1`, prefixed as simulated.
Result says the command completed and any logoff/restart request must be reviewed;
the demo never performs or pretends to automatically accept a restart/logoff.
No disk, RAM, uptime, profile or bin measurement changes.

### SFC Scan

Menu -> running -> results directly. Scope is protected files in the fictional
running Windows installation. Show sample `sfc /scannow` output over approximately
3.5 seconds, with scripted scan percentages such as 0, 25, 50, 75, 100.

Default sample finding: no integrity violations. Result distinguishes command
completion from proof of repair and retains activity for review. No storage or
boot measurement changes. Failure/cancellation never displays a finished 100%
scan or the successful finding unless that step really completed in the simulation.

### DISM Repair

Menu -> options -> running -> results. Match the GUI's three choices and default:

- CheckHealth only (CheckOnly), initially selected: approximately 2 seconds.
- CheckHealth + ScanHealth (Scan): approximately 4.5 seconds.
- Full repair (Full): CheckHealth, ScanHealth, RestoreHealth, approximately 7 seconds.

Only selected stages run, in that order. Scope is the fictional running Windows
image. Simulated command strings match `/Online /Cleanup-Image` plus the selected
step. CheckHealth is indeterminate; ScanHealth/RestoreHealth may show scripted
command percentages. Use benign, explicitly fictional findings such as no component
store corruption; completion of RestoreHealth does not invent new health measures.
No simulated download, network inspection, restart or storage change is necessary.

### Full System Maintenance

Menu -> DISM options (CheckOnly default) -> cleanup confirmation -> running -> results.
Confirm selected-profile Temp, Windows Temp, running-account bin, GPUpdate /force,
chosen DISM steps, SFC, and separate before/after reports. Continue from options
does not start maintenance until Start cleanup is clicked on confirmation.

Run exactly this order:

1. Before-maintenance report: 1.6 s, immutable snapshot saved before any cleanup.
2. Temp cleanup: approximately 3.5-4.5 s.
3. Running-account Recycle Bin cleanup: approximately 2 s.
4. GPUpdate Force: approximately 2.5 s.
5. DISM: approximately 2 / 4.5 / 7 s for the chosen mode.
6. SFC: approximately 3.5 s.
7. After-maintenance report: 1.6 s, snapshot of actual resulting sample state.

Approximately 17-23 seconds overall, so visitors can see stages and cancel. Timing
is a shortened simulation, not an estimate of real maintenance duration.

Show cleanup rows, task outcomes for Temp/Recycle/GPUpdate/DISM/SFC, and independent
Before/After report outcomes. The summary separates MaintenanceStatus and
ReportStatus. Ordinary task failure does not stop subsequent tasks in the script;
cancellation does. Saved before/after reports share a run ID but have distinct IDs
and snapshots. Report creation failures must not hide maintenance successes/failures.

Fresh Sample User Success: profile Temp 0 MB, Windows Temp 0 MB, bin 0 items/0 MB;
total released storage = 960 MB. Disk free becomes 42.9375 GB (display 42.94), used
213.0625 GB (display 213.06). Downloads, OST, RAM and boot time are unchanged;
uptime advances only with the fictional clock. Health overall remains WARNING
because Downloads, OST and uptime warnings remain. Maintenance/report generation
can still both be SUCCESS.

Fresh Sample User LockedFiles: profile Temp 16 MB, Windows Temp 0 MB, bin empty;
released storage 944 MB; disk free displays 42.92 GB and used 213.08 GB.
Temp/maintenance/overall task are PARTIAL; report generation is SUCCESS.

## Preview scenarios and failure fixtures

Keep the four existing scenario names. Describe applicability beside the selector;
do not silently make a scenario a new toolkit operation or reset the dataset.

| Scenario | Defined simulation effect |
| --- | --- |
| Success | Normal task completion; all extant cleanup files unlocked |
| LockedFiles | Locked selected-profile Temp file for Temp or Maintenance; other operations use Success behaviour |
| ReportFailure | Maintenance's after-report save fails; before report and maintenance operations remain intact; other operations use Success behaviour |
| Failure | Standalone task fails before any persistent mutation/report save; for Maintenance, Temp fails before either Temp section changes, other tasks continue |

For full-maintenance Failure on fresh Sample User data: Temp measurements remain
256/128 MB, bin empties, GPUpdate/DISM/SFC complete, both report snapshots save.
MaintenanceStatus and overall task are FAILED; ReportStatus is SUCCESS. Only
576 MB is freed, so disk free displays 42.56 GB and used 213.44 GB. Failed Temp
rows have zero deleted/freed counts, failed status and an explanation; do not
claim they were cleaned. Native standalone failures show incomplete simulated
output, a nonzero result and no changed storage.

For ReportFailure on fresh full-maintenance Success: release the same 960 MB,
MaintenanceStatus SUCCESS, ReportStatus FAILED, overall PARTIAL. Keep the Before
report link; show After failed/not saved without an Open button or report-list entry.

Desktop Preview uses generic stages, sparse health rows and illustrative results
that reset on each invocation; some Failure results retain success-looking sample
rows. The browser should not reproduce that inconsistency. Use the actual task
scripts' result fields and outcomes with deterministic fixtures and one evolving
dataset. This is simulation bookkeeping, not a new Windows feature.

## State consistency and saved reports

Maintain one session dataset, not independent canned before/after cards. Each file
deletion or atomic bin emptying updates it once, and each freed byte reduces disk
used and increases disk free equally. Calculate disk storage from the initial
occupied space minus committed deletions; never subtract again when rendering.
Repeated cleanups act on remaining files/items and cannot free the same space twice.
Changing profiles preserves earlier work and leaves the other profile untouched.
Only Reset or a new page load restores fixtures.

Store each report's ID, label, fictional timestamp, run ID when relevant, captured
identity/profile and complete measurement rows by value. Show a sample relative
location such as `Reports\demo-001-HealthReport.html`; no actual file is created.
Sequential fictional IDs are sufficient; report storage size is ignored in sample
disk accounting and this simplification is stated in the report viewer.

Open Reports Folder opens a simulated list in the app, initially empty. List only
successfully saved snapshots (including a saved-but-cancelled report), with title,
sample timestamp/profile and Open report. There is no file picker, explorer window,
download, upload or connection to the publication folder's real reports. Opening
a report displays its immutable table in the same app. Back returns to its caller
(report list or task results), without clearing data. Never auto-open a report or
spawn new tabs/windows. A fresh page load empties the list.

## Cancellation, completed work and Reset Demo

Cancel task immediately changes to disabled **Cancelling...**, changes the stage
and footer to waiting/stopping language, and keeps all other tasks blocked.
Resolve at the next scheduled simulation boundary, normally within 100-300 ms;
atomic bin emptying may finish its current short step before stopping. No subsequent
step starts. A second Cancel is ignored; if completion already won the race, preserve
its completed result rather than relabelling it cancelled.

- Temp: preserve committed deletions, byte totals and skips. During interrupted
  deletion/measurement show unavailable after-size, not zero, and count unprocessed
  files separately. Earlier measured sections retain their valid after-size.
  Unstarted sections must not be presented as cleaned. Next task inventories the
  actual remaining fixture files.
- Bin: cancellation before the atomic step leaves the bin intact; cancellation
  during it may produce an emptied bin with CANCELLED status and honest counts.
- Report: before the save boundary, no new entry; after saving, retain the snapshot
  and link even if cancellation wins before the final result.
- GPUpdate/SFC/DISM: retain completed output/stages and partial activity; do not
  generate successful messages for interrupted or unstarted stages. Do not claim
  that prior commands/repairs were undone.
- Full maintenance: retain completed cleanup and task outcomes plus saved reports.
  Mark unstarted tasks NOT_RUN. Cancellation before after-report creation records
  After CANCELLED/not generated; never create a fake after snapshot. A completed
  before report remains available. Prior failed task/report records remain visible
  even though overall cancellation takes precedence. Derive maintenance/report
  summary status using the precedence in src/Full-SystemCleanup.ps1.

Cancellation never restores deleted sample files automatically. Show the GUI's
explanation that completed changes are retained; add that these are sample-data
changes only. A fresh task gets fresh cancellation state and cannot inherit a
previous run's cancelled flag or scheduled callbacks.

Place **Reset Demo** in the persistent header, beside the notice, as a demonstration
control distinct from toolkit actions. It is disabled during running/cancelling;
visitors must cancel and wait before resetting. When idle, Reset returns to menu,
restores every fixture, profile/scenario defaults, clears reports/results/activity,
resets fictional time and ID counters, and invalidates old run callbacks. No popup
is needed. Returning to menu alone must not reset anything.

Browser Back must not expose enabled launchers while busy: restore the active task
view or otherwise keep the running view authoritative. Closing/reloading a browser
tab cannot be blocked like the Windows window; it simply discards the independent
in-memory simulation. No before-unload warning or claim of background Windows work.

## Implemented static demo

Three authored application files inside `docs/`, plus an empty hosting marker:

- `docs/index.html`: semantic app shell and screen containers.
- `docs/styles.css`: GUI-derived styling, responsive layout and always-enabled animation rules.
- `docs/app.js`: fixture data, threshold calculations, state machine, scheduler,
  sample mutations, immutable report snapshots and rendering.
- `docs/.nojekyll`: empty marker for GitHub Pages static hosting.

Plain HTML/CSS/JavaScript. Use a normal deferred script rather than module fetching
so the demo can also open locally without installation or a local server. Use no
framework, build step, package manager, backend, CDN, external font/icon/library,
analytics or service worker. Assets/icons are inline or local. Relative asset paths
must work beneath the repository subpath as well as from a local file.

The browser executes only simulation UI code. No PowerShell/BAT invocation, OS
integration, local filesystem APIs, file pickers, shell links, clipboard/device
permissions, network discovery, geolocation or visitor account/device detection.
No fetch/XHR/WebSocket requests from demo code, telemetry, remote assets, cookies,
localStorage or IndexedDB; all demo state remains in memory. Normal loading of its
own static HTML/CSS/JS by the browser is the only hosted resource access needed.

Implemented state: current view, selected profile/scenario, captured run request,
sample files/bin/disk/RAM/boot clock, reports, latest completed run, busy/cancel flag,
run generation ID and scheduled event handles. Use explicit transitions:
menu -> options/confirmation -> running -> cancelling/results -> menu; report
list/viewer are idle-only. Keep rendering separate from mutation. Commit sample
changes at defined event boundaries, not by counting timer ticks or log renders.
Invalidate stale callbacks when a run finishes or resets; resume delayed background
tab scheduling in chronological order without duplicating events or rushing past a
cancel request. Never infer successful completion merely from a progress bar.

The Windows scripts remain unchanged. The source link is configured to
https://github.com/faizankxzi/Windows-IT-Support-Toolkit. The hosting target is
GitHub Pages using main and /docs, at the expected address
https://faizankxzi.github.io/Windows-IT-Support-Toolkit/. No license has been added.

## Acceptance checks and verification

The table records acceptance criteria. Simulation/model checks and browser checks
covered task flows, cancellation, repeated runs, reset, immutable reports and
consistent sample measurements. Final smoke checks cover report generation/viewing,
cancellation, reset, responsive layout and console errors. Direct file opening
was reviewed structurally (relative links and a deferred classic script), because
the automated browser blocks file URLs. Full touch and 200% zoom testing remain
unverified. This does not verify real Windows maintenance operations.

| ID | Interaction/check | Expected result |
| --- | --- | --- |
| A01 | Load demo | Exact persistent notice, fictional account/computer, Sample User, Success, eight correctly grouped cards; no auto-start |
| A02 | Change profile | Only profile measurements/targets change; account/bin/shared Temp remain the same |
| A03 | Open options, change mode, Go back | No mutation/report/task; reopening uses actual GUI defaults |
| A04 | Temp/Recycle confirmation and Go back | Correct scopes/identities/deletion warning plus simulation notice; no changes |
| A05 | Generate report | Approximately 1-2 s; complete actual measurement rows; one saved sample report, no storage changes or auto-opening |
| A06 | Open report from result/list, then Back | One in-app immutable viewer, caller restored, persistent notice, no new tab/download/real report access |
| A07 | Reports list before/after generation | Initially empty; only saved snapshots listed; failure does not create an entry; separate full-maintenance Before/After entries |
| A08 | Fresh Temp Success | 256/128 MB become zero; 10/8 files deleted; 384 MB freed; other profile, Downloads, OST and bin unchanged |
| A09 | Fresh Temp LockedFiles | Profile 16 MB remains, 9 deleted/1 skipped; Windows cleared; 368 MB freed; PARTIAL with locked-file reason |
| A10 | Repeat cleanup/change profile | Only remaining files processed; no repeated space gains; selected profile only plus shared Windows Temp |
| A11 | Recycle cleanup/repeat, alternate target | Running-account bin 12 -> 0, 576 MB removed; repeat 0 -> 0; target profile never changes bin ownership |
| A12 | Both GPUpdate modes | Force default; correct chosen simulated output; no reset/deletion options, storage changes or accepted restart |
| A13 | SFC | Direct running flow, scripted percentage/activity then result; finding clearly sample; no added health metric |
| A14 | Each DISM choice | CheckOnly default; only correct ordered steps; chosen mode survives into scope/output/result; no real command/download |
| A15 | Full-maintenance Go back/start | Options then confirmation; no run until final Start cleanup |
| A16 | Fresh full Success in every DISM mode | Actual sequence; distinct before/after snapshots; five task outcomes; correct shortened duration; 960 MB freed and disk 42.94/213.06 GB for Sample User |
| A17 | Full LockedFiles | 944 MB freed; 16 MB locked file retained; maintenance PARTIAL, reports SUCCESS; disk 42.92/213.08 GB |
| A18 | Full ReportFailure | Before snapshot survives, After failed/no link, sample cleanup retained; maintenance SUCCESS, reports FAILED, overall PARTIAL |
| A19 | Standalone Failure for each task | FAILED; no successful finding, report save or storage mutation; sample activity explains failure |
| A20 | Full Failure | Temp failed/unchanged; subsequent tasks continue; bin emptied only, 576 MB freed; maintenance FAILED, reports SUCCESS; disk 42.56/213.44 GB |
| A21 | Scenarios outside their applicability | Success behaviour, accurately described; choosing scenario does not restore/alter data |
| A22 | Cancel report before/after save boundary | Unsaved report absent; saved snapshot retained; no invented completed work |
| A23 | Cancel Temp in each measurement/file section | Completed deletions/skips retained, unknown after-size not zero, remaining files count correct, later section unstarted |
| A24 | Cancel bin before/during atomic step | Counts reflect unchanged/completed sample step; no rollback claim |
| A25 | Cancel GPUpdate/SFC and each DISM step | Cancelling wait, no later command stage, completed activity preserved, no false success |
| A26 | Cancel full maintenance during every stage | Completed tasks/reports retained; later tasks NOT_RUN; no after report before its save; failure records remain visible |
| A27 | Double Cancel/finish race/new task after cancel | One cancellation request, truthful winning result, fresh task cancellation state |
| A28 | Rapid double clicks, hidden buttons, keyboard, Back while busy | One active run; captures cannot change; no task launches/reset before worker stops |
| A29 | Reset from menu/options/confirmation/results/list/viewer | All data, time, counters, reports and selections restored; no old callback fires |
| A30 | Reset while running/cancelling | Disabled, including programmatic guard; Cancel is still usable |
| A31 | Report after earlier cleanup/partial cancellation | Uses actual remaining sample state; earlier report remains unchanged; used + free stays 256 GB |
| A32 | Threshold boundaries | Free 9.99/10; uptime 7/7.01/14/14.01; folders 1000/1000.01; OST 19.99/20/47.99/48; bin 500/500.01 produce exact source statuses |
| A33 | Internal missing/unavailable fixtures | NOT_FOUND/UNAVAILABLE, never healthy zero; partial generation and overall precedence correct; no extra visitor control required |
| A34 | Health vs command completion | Warnings remain after cleanup; SUCCESS report/task is not a promise of healthy Windows or completed repairs |
| A35 | Progress/output | Percentage only for fixture file count/scripted SFC-DISM output; measurements/GPUpdate indeterminate; no guessed ETA |
| A36 | Wide/640/375/320 px, 200% zoom, touch | No page overflow/overlap; notice, Cancel and Back usable; tables/output scroll within containers |
| A37 | Keyboard/animations | Entire flow usable without mouse; clear focus/announcements; animations remain enabled without delaying or blocking input |
| A38 | Background tab, delayed callbacks, rapid reset/start | No duplicate mutations, reports, completion events or stale output; logical operation order preserved |
| A39 | Local opening/repository subpath/offline after assets loaded | Relative assets work; no installation/backend/external dependency required |
| A40 | Inspect network/permissions/storage and page reload | Only own static assets; no device APIs/telemetry/persistent storage; reload starts fresh sample session |
| A41 | Compare publication scripts before/after demo work | Windows scripts untouched; demo assets confined to docs/; no real reports copied into demo |

## Browser differences and decisions

Necessary differences are explicit: browser layout can stack on mobile; icons use
local SVG equivalents; Windows Explorer/report files become an in-app reports list
and immutable in-memory viewer; timing is shortened; UAC/admin identity is fictional;
closing a tab resets the simulation rather than being blocked; Reset Demo is a
simulation-only control. The report list, reset and evolving dataset are requested
demo adaptations, not new features advertised for the Windows toolkit.

The browser implementation uses the defaults above. No additional design decision
is required for publication. The existing pending license decision is unchanged.
