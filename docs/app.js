"use strict";

// All values and operations below are fictional. No Windows commands or device APIs.
const MB = 2 ** 20, GB = 2 ** 30;
const ACCOUNT = "EXAMPLE\\Technician", COMPUTER = "EXAMPLE-PC";
const PROFILE_NAMES = ["Sample User", "Sample Admin"];
const TASKS = {
  Report: {title:"Generate Health Report", group:"Diagnostics", icon:"health", description:"Disk, RAM, uptime, Temp, Downloads, Recycle Bin and Outlook cache.", helps:"Gives a snapshot of disk space, memory, uptime and profile storage to review or attach to a support ticket."},
  ReportsFolder: {title:"Open Reports Folder", group:"Diagnostics", icon:"folder", description:"Shows reports saved by this toolkit."},
  Temp: {title:"Temp Cleanup", group:"Cleanup", icon:"trash", description:"Removes temporary files from the selected profile and Windows Temp.", helps:"Can free space used by leftover app and installer files. Files in use are skipped; Downloads and Outlook files are not deleted."},
  Recycle: {title:"Recycle Bin Cleanup", group:"Cleanup", icon:"recycle", description:"Permanently empties the running account Recycle Bin.", helps:"Can free space occupied by previously deleted files in the running account Recycle Bin."},
  Maintenance: {title:"Full System Maintenance", group:"Maintenance", icon:"wrench", description:"Reports, cleanup, policy refresh, DISM and SFC in sequence.", helps:"Combines diagnostics, cleanup and Windows maintenance, with each outcome recorded separately."},
  GPUpdate: {title:"GPUpdate", group:"Maintenance", icon:"refresh", description:"Refreshes computer and running-account Group Policy.", helps:"Refreshes policy settings. Windows may still require a logoff or restart."},
  SFC: {title:"SFC Scan", group:"Maintenance", icon:"health", description:"Checks protected Windows files and may repair damaged files.", helps:"May repair damaged protected Windows files. Completion does not mean that corruption was found or repaired."},
  DISM: {title:"DISM Repair", group:"Maintenance", icon:"package", description:"Checks or repairs the running Windows image.", helps:"Checks the Windows component store; Full mode may repair it and may require Windows Update access."}
};
const ACTION_ORDER = ["Temp","Recycle","GPUpdate","DISM","SFC"];
const SCENARIOS = ["Success","LockedFiles","ReportFailure","Failure"];
const DISM_MODES = [
  ["CheckOnly","CheckHealth only — quick check for known corruption","Read-only inspection of the fictional Windows image."],
  ["Scan","CheckHealth + ScanHealth — deeper inspection","A longer read-only sample scan."],
  ["Full","Full repair — CheckHealth, ScanHealth and RestoreHealth","In the real toolkit this may use Windows Update to repair the image."]
];
function roundEven(value, digits=2) {
  const factor=10 ** digits, scaled=value*factor, floor=Math.floor(scaled), fraction=scaled-floor;
  const tolerance=Number.EPSILON*Math.max(1,Math.abs(scaled))*4;
  return (Math.abs(fraction-.5)<=tolerance ? floor+(floor%2) : Math.round(scaled))/factor;
}
function classify(check,value) {
  if (value === null || value === undefined || !Number.isFinite(value)) return "UNAVAILABLE";
  value=roundEven(value);
  if (check==="Disk free") return value<10?"CRITICAL":"OK";
  if (check==="Uptime") return value>14?"CRITICAL":value>7?"WARNING":"OK";
  if (["Selected-profile Temp","Windows Temp","Downloads"].includes(check)) return value>1000?"WARNING":"OK";
  if (check==="Outlook OST") return value>=48?"CRITICAL":value>=20?"WARNING":"OK";
  if (check==="Running-account Recycle Bin") return value>500?"WARNING":"OK";
  return "OK";
}
function overall(rows) {
  return rows.some(r=>r.Status==="CRITICAL")?"CRITICAL":rows.some(r=>r.Status==="WARNING")?"WARNING":rows.some(r=>r.Status==="UNAVAILABLE")?"INCOMPLETE":"OK";
}
function clone(value) {return JSON.parse(JSON.stringify(value));}
function freeze(value) {if(value&&typeof value==="object"){Object.values(value).forEach(freeze);Object.freeze(value);}return value;}
function sum(files) {return files?files.reduce((total,file)=>total+file.bytes,0):0;}
function pathFor(profile) {return "C:\\Users\\"+profile;}
function stamp(time) {return new Date(time).toISOString().replace("T"," ").slice(0,19)+" UTC (sample)";}
function elapsed(ms) {const secs=Math.floor(ms/1000);return String(Math.floor(secs/60)).padStart(2,"0")+":"+String(secs%60).padStart(2,"0");}
function scope(action,profile,mode) {
  return {
    Report:"Read-only sample measurements. Saves one simulated report in the reports list.",
    Temp:"Selected-profile Temp: "+pathFor(profile)+"\\AppData\\Local\\Temp\nWindows Temp: C:\\Windows\\Temp",
    Recycle:"Running account "+ACCOUNT+"'s Recycle Bin across its fictional drives. The selected profile does not change this account.",
    Maintenance:"Before report; selected-profile Temp: "+pathFor(profile)+"\\AppData\\Local\\Temp; Windows Temp: C:\\Windows\\Temp; "+ACCOUNT+"'s Recycle Bin; GPUpdate /force; DISM ("+mode+"); SFC; after report.",
    GPUpdate:"Computer and running-account Group Policy. Mode: "+mode+".",
    SFC:"Protected system files in the fictional running Windows installation.",
    DISM:"Fictional running Windows image. Mode: "+mode+"."
  }[action];
}
class SampleModel {
  constructor() {
    const files=(sizes,prefix)=>sizes.map((size,i)=>({id:prefix+(i+1),name:"sample-"+(i+1)+".tmp",bytes:size*MB}));
    this.profiles={
      "Sample User":{temp:files([24,24,24,24,24,24,24,24,48,16],"u"),downloads:1536*MB,ost:24*GB,lockedId:"u10"},
      "Sample Admin":{temp:files(Array(8).fill(16),"a"),downloads:768*MB,ost:null,lockedId:"a8"}
    };
    this.windowsTemp=files(Array(8).fill(16),"w");this.bin=files(Array(12).fill(48),"b");
    this.freedBytes=0;this.diskInitialUsed=214*GB;this.diskInitialFree=42*GB;
    this.ramTotal=16;this.ramFree=6;this.clock=Date.UTC(2026,0,15,12);this.boot=Date.UTC(2026,0,7);
    this.reports=[];this.nextReport=1;this.nextRun=1;
  }
  deleteFile(files,file) {const index=files.findIndex(f=>f.id===file.id);if(index>=0){this.freedBytes+=files[index].bytes;files.splice(index,1);return true;}return false;}
  emptyBin() {this.freedBytes+=sum(this.bin);this.bin=[];}
  health(profile) {
    const rows=[],data=this.profiles[profile];
    const row=(check,value,status="OK",notes="")=>rows.push({Check:check,Value:value,Status:status,Notes:notes});
    const measure=(check,value,unit,notes="")=>row(check,value===null?"Unavailable":roundEven(value)+" "+unit,classify(check,value),notes);
    measure("Disk used",(this.diskInitialUsed-this.freedBytes)/GB,"GB");measure("Disk free",(this.diskInitialFree+this.freedBytes)/GB,"GB");
    if(this.ramTotal===null||this.ramFree===null||this.boot===null) row("Memory and uptime","Unavailable","UNAVAILABLE","Sample measurement unavailable.");
    else {measure("Total RAM",this.ramTotal,"GB");measure("Free RAM",this.ramFree,"GB");row("Last reboot",stamp(this.boot));measure("Uptime",(this.clock-this.boot)/86400000,"days");}
    for(const [check,files] of [["Selected-profile Temp",data.temp],["Windows Temp",this.windowsTemp]]) {
      if(files===null) row(check,"NOT_FOUND","NOT_FOUND","Sample folder not found.");
      else measure(check,sum(files)/MB,"MB");
    }
    measure("Downloads",data.downloads===null?null:data.downloads/MB,"MB");
    if(data.ost===null) row("Outlook OST","No OST found in the two checked folders","NOT_FOUND");
    else measure("Outlook OST",data.ost/GB,"GB",pathFor(profile)+"\\AppData\\Local\\Microsoft\\Outlook\\sample.ost");
    measure("Running-account Recycle Bin",sum(this.bin)/MB,"MB");
    return rows;
  }
  saveReport(profile,label,runId) {
    const id="demo-"+String(this.nextReport++).padStart(3,"0"),rows=this.health(profile);
    const report=freeze({id,label,runId,profile,account:ACCOUNT,computer:COMPUTER,time:stamp(this.clock),path:"Reports\\"+id+"-"+label+".html",rows,overall:overall(rows),status:rows.some(r=>r.Status==="UNAVAILABLE")?"PARTIAL":"SUCCESS"});
    this.reports.push(report);return report;
  }
}

// One scheduled operation at a time. Mutations occur once at commit boundaries.
// The injected clock lets acceptance tests cover every boundary without waiting.
class Simulation {
  constructor(model,request,onUpdate=()=>{},onDone=()=>{},scheduler=null) {
    this.model=model;this.request=freeze(clone(request));this.onUpdate=onUpdate;this.onDone=onDone;
    this.scheduler=scheduler||{now:()=>performance.now(),set:(fn,ms)=>setTimeout(fn,ms),clear:id=>clearTimeout(id)};
    this.timer=null;this.frame=null;this.finished=false;this.cancelled=false;this.stage=null;
    this.started=this.scheduler.now();this.stageStarted=this.started;
    this.result={action:request.action,profile:request.profile,mode:request.mode,scenario:request.scenario,status:"SUCCESS",message:"Simulated task complete. No Windows commands ran and no real files were deleted.",rows:[],tasks:[],reportResults:[],reports:[],logs:[],elapsedMs:0,runId:"run-"+model.nextRun++};
    this.activeTask=null;this.activeReport=null;this.activeCleanup=null;this.activeBin=null;
    this.iterator=this.plan();
  }
  log(text) {this.result.logs.push(text);}
  start() {this.next();this.paintClock();return this;}
  paintClock() {if(this.finished)return;this.onUpdate(this);this.frame=this.scheduler.set(()=>this.paintClock(),100);}
  step(label,duration,commit=null,percent=null,note="") {return {label,duration,commit,percent,note};}
  next() {
    if(this.finished)return;
    try {
      const item=this.iterator.next();
      if(item.done){this.finish();return;}
      this.stage=item.value;this.stageStarted=this.scheduler.now();this.log("> "+this.stage.label);this.onUpdate(this);
      this.timer=this.scheduler.set(()=>{
        this.timer=null;if(this.finished||this.cancelled)return;
        try {this.model.clock+=this.stage.duration;if(this.stage.commit)this.stage.commit();this.next();}
        catch(error){this.failUnknown(error);}
      },this.stage.duration);
    } catch(error){this.failUnknown(error);}
  }
  *report(label,reportName,failSave=false) {
    const record={Report:reportName,Status:"RUNNING",Message:"Collecting sample measurements."};
    this.result.reportResults.push(record);this.activeReport=record;
    yield this.step("Collecting disk and memory information",300,()=>this.log("Sample disk, RAM and boot measurements collected."));
    yield this.step("Measuring profile folders and Windows Temp",500,()=>this.log("Sample Temp and Downloads sizes inspected; no files changed."));
    yield this.step("Checking Outlook cache and running-account Recycle Bin",400,()=>this.log("Only the two sample OST folders and running-account sample bin are inspected."));
    yield this.step("Saving the health report",250,()=>{
      if(failSave){record.Status="FAILED";record.Message="Simulated after-report save failure. No snapshot saved.";this.log(record.Message);return;}
      const report=this.model.saveReport(this.request.profile,label,this.result.runId);
      this.result.reports.push(report.id);record.Status=report.status;record.Message="Sample snapshot saved: "+report.path;record.savedId=report.id;
      if(this.request.action==="Report")this.result.rows=clone(report.rows);
      this.log(record.Message);
    });
    yield this.step("Preparing report results",150);
    this.activeReport=null;
  }
  *temp(fail=false) {
    const data=this.model.profiles[this.request.profile];
    const sections=[["Selected-profile Temp",data.temp,pathFor(this.request.profile)+"\\AppData\\Local\\Temp"],["Windows Temp",this.model.windowsTemp,"C:\\Windows\\Temp"]];
    if(fail){
      yield this.step("Checking cleanup locations",900,()=>{
        for(const [section,files] of sections)this.result.rows.push({Section:section,BeforeMB:roundEven(sum(files)/MB),AfterMB:null,FreedMB:0,DeletedCount:0,SkippedCount:0,InspectionIssues:1,Status:"FAILED"});
        this.log("Simulated access failure. Neither Temp section was changed.");
      });return "FAILED";
    }
    for(const [section,files,path] of sections){
      const queue=(files||[]).slice();
      const row={Section:section,BeforeMB:null,AfterMB:null,FreedMB:0,DeletedCount:0,SkippedCount:0,InspectionIssues:0,Status:"RUNNING"};
      this.result.rows.push(row);this.activeCleanup={row,queue,processed:0};
      yield this.step("Measuring "+section+" before cleanup",350,()=>{row.BeforeMB=roundEven(sum(files)/MB);this.log("Sample location: "+path+" · "+queue.length+" files, "+row.BeforeMB+" MB");});
      for(let i=0;i<queue.length;i++){
        const file=queue[i];
        yield this.step("Cleaning "+section,150,()=>{
          if(section==="Selected-profile Temp"&&this.request.scenario==="LockedFiles"&&file.id===data.lockedId){row.SkippedCount++;this.log("Skipped sample file (locked): "+path+"\\"+file.name);}
          else if(this.model.deleteFile(files,file)){row.DeletedCount++;row.FreedMB=roundEven(row.FreedMB+file.bytes/MB);this.log("Removed sample file: "+file.name+" · "+file.bytes/MB+" MB");}
          this.activeCleanup.processed++;
        },Math.floor(100*i/queue.length),"Sample file "+(i+1)+" of "+queue.length);
      }
      yield this.step("Measuring "+section+" after cleanup",350,()=>{row.AfterMB=roundEven(sum(files)/MB);row.Status=row.SkippedCount?"PARTIAL":"SUCCESS";this.log(section+": "+row.BeforeMB+" → "+row.AfterMB+" MB; "+row.DeletedCount+" removed, "+row.SkippedCount+" skipped (sample).");});
      this.activeCleanup=null;
    }
    return this.result.rows.some(r=>r.Status==="PARTIAL")?"PARTIAL":"SUCCESS";
  }
  *recycle() {
    const row={Account:ACCOUNT,ItemsBefore:null,ItemsAfter:null,Status:"RUNNING"};this.activeBin=row;if(this.request.action!=="Maintenance")this.result.rows.push(row);
    yield this.step("Checking the running-account Recycle Bin",900,()=>{row.ItemsBefore=this.model.bin.length;this.log("Sample running-account bin: "+row.ItemsBefore+" items.");});
    const commit=()=>{this.model.emptyBin();this.log("Sample bin operation returned. No real files were deleted.");};
    const atomic=this.step("Emptying the running-account Recycle Bin",200,commit);atomic.atomic=true;yield atomic;
    yield this.step("Checking remaining Recycle Bin items",900,()=>{row.ItemsAfter=this.model.bin.length;row.Status="SUCCESS";this.log("Sample bin: "+row.ItemsBefore+" → "+row.ItemsAfter+" items.");});
    this.activeBin=null;return "SUCCESS";
  }
  *native(action,mode) {
    if(action==="GPUpdate"){
      yield this.step("Refreshing Group Policy ("+mode+")",800,()=>this.log("Simulated command: gpupdate "+(mode==="Force"?"/force ":"")+"/wait:-1"));
      yield this.step("Refreshing computer policy",850,()=>this.log("Sample computer policy refresh completed."));
      yield this.step("Refreshing running-account policy",850,()=>this.log("Sample user policy refresh completed. No logoff or restart is accepted automatically."));
    }else if(action==="SFC"){
      this.log("Simulated command: sfc /scannow");
      for(const percent of [0,25,50,75,100])yield this.step("Scanning protected Windows files",700,()=>this.log("Sample verification "+percent+"% complete."),percent,"Simulated SFC progress");
      this.log("Sample finding: Windows Resource Protection did not find any integrity violations.");
    }else{
      yield this.step("DISM: CheckHealth",2000,()=>this.log("Simulated command: dism /Online /Cleanup-Image /CheckHealth\nSample finding: no component store corruption detected."));
      const steps=mode==="Full"?["ScanHealth","RestoreHealth"]:mode==="Scan"?["ScanHealth"]:[];
      for(const name of steps){
        this.log("Simulated command: dism /Online /Cleanup-Image /"+name);
        for(const percent of [0,25,50,75,100])yield this.step("DISM: "+name,500,()=>this.log("Sample "+name+" progress: "+percent+"%."),percent,"Simulated DISM progress");
        this.log("Sample "+name+" command completed. Review output; completion alone is not proof that repairs were needed.");
      }
    }
    return "SUCCESS";
  }
  *action(action,mode,fail=false) {
    const record={Task:action,Status:"RUNNING",Message:"Sample operation in progress."};
    this.result.tasks.push(record);this.activeTask=record;
    let status;
    if(fail&&action!=="Temp"){
      yield this.step("Starting "+TASKS[action].title,900,()=>this.log("Simulated command failed before any persistent change. Sample exit code: 5."));status="FAILED";
    }else if(action==="Temp")status=yield* this.temp(fail);
    else if(action==="Recycle")status=yield* this.recycle();
    else status=yield* this.native(action,mode);
    record.Status=status;record.Message=status==="FAILED"?"Simulated failure; no change from this operation.":status==="PARTIAL"?"Sample cleanup completed with a locked file skipped.":"Simulated command completed; review sample activity for findings.";
    this.activeTask=null;return record;
  }
  *plan() {
    const {action,mode,scenario}=this.request;
    if(action==="Report"){
      if(scenario==="Failure"){yield this.step("Collecting sample health measurements",1000,()=>this.log("Simulated report failure. No report saved."));this.result.status="FAILED";}
      else yield* this.report("HealthReport","Health report");
    }else if(action==="Maintenance"){
      yield* this.report("BeforeMaintenance","Before");
      for(const task of ACTION_ORDER)yield* this.action(task,task==="GPUpdate"?"Force":mode,scenario==="Failure"&&task==="Temp");
      yield* this.report("AfterMaintenance","After",scenario==="ReportFailure");
    }else yield* this.action(action,mode,scenario==="Failure");
  }
  cancel() {
    if(this.finished||this.cancelled)return false;
    this.cancelled=true;this.scheduler.clear(this.timer);this.timer=null;
    this.log("Cancel requested. Completed sample changes remain; later steps will not start.");this.onUpdate(this);
    this.timer=this.scheduler.set(()=>{
      this.timer=null;if(this.finished)return;
      if(this.stage&&this.stage.atomic&&this.stage.commit)this.stage.commit();
      if(this.activeCleanup){const {row,queue,processed}=this.activeCleanup;row.AfterMB=null;row.Status="CANCELLED";row.UnprocessedFiles=queue.length-processed;}
      const currentBin=this.activeBin;
      if(currentBin){currentBin.ItemsAfter=this.model.bin.length;currentBin.Status="CANCELLED";}
      if(this.activeTask){this.activeTask.Status="CANCELLED";this.activeTask.Message=currentBin?"Interrupted sample bin: "+(currentBin.ItemsBefore??"not measured")+" → "+currentBin.ItemsAfter+" items. Completed sample changes remain.":"Interrupted. Completed sample work is retained.";}
      if(this.activeReport&&this.activeReport.Status!=="FAILED"){this.activeReport.Status="CANCELLED";this.activeReport.Message=this.activeReport.savedId?"Cancelled after saving; sample snapshot retained.":"Cancelled before saving; no snapshot created.";}
      if(this.request.action==="Maintenance"){
        for(const task of ACTION_ORDER)if(!this.result.tasks.some(t=>t.Task===task))this.result.tasks.push({Task:task,Status:"NOT_RUN",Message:"Skipped after cancellation."});
        if(!this.result.reportResults.some(r=>r.Report==="After"))this.result.reportResults.push({Report:"After",Status:"CANCELLED",Message:"Not generated because maintenance was cancelled."});
      }
      this.finish("CANCELLED");
    },150);return true;
  }
  failUnknown(error) {this.log("Simulation error: "+error.message);this.result.outcomeKnown=false;this.finish("FAILED");}
  finish(forced=null) {
    if(this.finished)return;
    this.finished=true;this.scheduler.clear(this.timer);this.scheduler.clear(this.frame);this.timer=this.frame=null;
    const tasks=this.result.tasks,reports=this.result.reportResults;
    const maintenance=tasks.some(t=>t.Status==="FAILED")?"FAILED":tasks.some(t=>["CANCELLED","NOT_RUN"].includes(t.Status))?"CANCELLED":tasks.some(t=>t.Status!=="SUCCESS")?"PARTIAL":"SUCCESS";
    const reportStatus=reports.some(r=>r.Status==="FAILED")?"FAILED":reports.some(r=>r.Status==="CANCELLED")?"CANCELLED":reports.some(r=>r.Status!=="SUCCESS")?"PARTIAL":"SUCCESS";
    if(this.request.action==="Maintenance"){this.result.maintenanceStatus=maintenance;this.result.reportStatus=reportStatus;}
    if(forced)this.result.status=forced;
    else if(this.result.status!=="FAILED")this.result.status=maintenance==="FAILED"||this.request.action==="Report"&&reportStatus==="FAILED"?"FAILED":maintenance!=="SUCCESS"||reportStatus!=="SUCCESS"?"PARTIAL":"SUCCESS";
    this.result.elapsedMs=this.scheduler.now()-this.started;
    this.result.message=this.result.outcomeKnown===false?"The simulation did not return a verified completion result. Review activity; no successful outcome is claimed.":this.result.status==="CANCELLED"?"Task cancelled. Completed sample changes and saved reports are retained. Remaining steps were skipped; no real computer changes occurred.":this.result.status==="FAILED"?"Simulated task failure. Review individual outcomes and activity.":this.request.action==="Maintenance"?"Maintenance and report-generation outcomes are shown separately. All results are simulated.":this.result.status==="PARTIAL"?"Simulated task completed with issues. Review skipped files or unavailable measurements.":this.result.message;
    this.onDone(freeze(clone(this.result)));
  }
  dispose() {this.finished=true;this.scheduler.clear(this.timer);this.scheduler.clear(this.frame);this.timer=this.frame=null;}
}

// UI uses one persistent header and replaces only the screen below it.
const ICON_PATHS={health:'<path d="M4 4h16v16H4z M5 13h4l2-6 3 10 2-4h3"/>',folder:'<path d="M3 7V4h7l2 3h9l-4 13H2V7z M3 9h17"/>',trash:'<path d="M3 6h18 M9 6V3h6v3 M6 6l1 15h10l1-15 M10 10v7 M14 10v7"/>',recycle:'<path d="M4 9a8 8 0 1 1 0 6 M4 3v6h6"/>',refresh:'<path d="M4 9a8 8 0 1 1 0 6 M4 3v6h6 M20 21v-6h-6"/>',wrench:'<path d="M14 6a5 5 0 0 0-6 6L3 17a2.8 2.8 0 0 0 4 4l5-5a5 5 0 0 0 6-6l-3 3-4-4 3-3Z"/>',package:'<path d="m12 2 9 5v10l-9 5-9-5V7z M3 7l9 5 9-5 M12 12v10 M7 4l10 6"/>',user:'<circle cx="12" cy="7" r="3"/><path d="M6 21v-3a6 6 0 0 1 12 0v3"/>',back:'<path d="m11 5-7 7 7 7 M4 12h16"/>',cancel:'<circle cx="12" cy="12" r="9"/><path d="m8 8 8 8 M16 8l-8 8"/>',report:'<path d="M5 2h9l5 5v15H5z M14 2v6h5 M8 12h8 M8 16h8"/>'};
function icon(name){return '<svg viewBox="0 0 24 24" aria-hidden="true">'+(ICON_PATHS[name]||ICON_PATHS.health)+'</svg>';}
function esc(value){return String(value??"").replace(/[&<>"']/g,char=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[char]));}
function button(label,action,style="",extra=""){return '<button type="button" class="btn '+style+'" data-command="'+action+'" '+extra+'>'+label+'</button>';}
function status(value){return '<span class="status '+esc(value)+'">'+esc(value)+'</span>';}
function table(title,rows){
  if(!rows||!rows.length)return "";
  const labels={BeforeMB:"Before (MB)",AfterMB:"After (MB)",FreedMB:"Freed (MB)",DeletedCount:"Deleted files",SkippedCount:"Skipped files",InspectionIssues:"Inspection issues",ItemsBefore:"Items before",ItemsAfter:"Items after",UnprocessedFiles:"Unprocessed files"};
  const keys=[...new Set(rows.flatMap(row=>Object.keys(row)))].filter(key=>key!=="savedId");
  return '<h2>'+esc(title)+'</h2><div class="table-wrap" tabindex="0" role="region" aria-label="'+esc(title)+'"><table><thead><tr>'+keys.map(key=>'<th scope="col">'+esc(labels[key]||key)+'</th>').join("")+'</tr></thead><tbody>'+rows.map(row=>'<tr>'+keys.map(key=>'<td>'+(key==="Status"?status(row[key]):row[key]===null?'<span class="muted">Not measured</span>':esc(row[key]))+'</td>').join("")+'</tr>').join("")+'</tbody></table></div>';
}
function identity(profile){return '<p class="identity">Running as: '+esc(ACCOUNT)+'<br>Selected target profile: '+esc(pathFor(profile))+'</p>';}
function title(action){return '<div class="title-row">'+icon(TASKS[action].icon)+'<h1 tabindex="-1">'+esc(TASKS[action].title)+'</h1></div>';}
let uiState={model:new SampleModel(),profile:"Sample User",scenario:"Success",view:"menu",pending:null,runner:null,last:null,report:null,reportCaller:"list",generation:0};
const isBusy=()=>!!uiState.runner&&!uiState.runner.finished;
function menuMarkup(){
  const groups={Diagnostics:["#159c9f","#dff1f2"],Cleanup:["#d97845","#fbece5"],Maintenance:["#3d76c9","#e6edfa"]};
  return '<h1 class="sr-only" tabindex="-1">Toolkit tasks</h1><div class="account-panel"><div><div class="account-line">'+icon("user")+'<div><div class="label">Running as</div><div class="account-name">'+esc(ACCOUNT)+'</div></div></div><span class="badge">Administrator (simulated)</span><p class="computer">Computer: '+COMPUTER+'</p></div><div class="profile-panel"><label for="profile">Target user profile</label><select id="profile">'+PROFILE_NAMES.map(name=>'<option '+(name===uiState.profile?'selected':'')+'>'+name+'</option>').join("")+'</select><p>Chooses whose files profile-based tasks work on. It does not switch the account running the toolkit.</p></div></div>'+Object.entries(groups).map(([group,colors])=>'<section class="tool-group"><h2 class="group-heading">'+group.toUpperCase()+'</h2><div class="tool-grid">'+Object.entries(TASKS).filter(([,task])=>task.group===group).map(([action,task])=>'<button type="button" class="tool-tile" data-task="'+action+'" style="--tile:'+colors[0]+';--soft:'+colors[1]+'"><span class="tile-icon">'+icon(task.icon)+'</span><span><span class="tile-title">'+task.title+'</span><span class="tile-description">'+task.description+'</span></span></button>').join("")+'</div></section>').join("")+'<div class="scenario-panel"><div class="scenario-row"><label for="scenario">Preview scenario (no Windows operations)</label><select id="scenario">'+SCENARIOS.map(name=>'<option '+(name===uiState.scenario?'selected':'')+'>'+name+'</option>').join("")+'</select></div><p class="scenario-note">LockedFiles affects Temp cleanup. ReportFailure affects full maintenance’s after report. Failure demonstrates task failures. Other combinations use Success behaviour.</p></div>';
}
function optionsMarkup(){
  const pending=uiState.pending,gp=pending.action==="GPUpdate";
  const choices=gp?[["Normal","Normal — apply policies that changed","Refresh computer and running-account sample policy."],["Force","Force — reapply all policies","Reapply changed and unchanged sample policies."]]:DISM_MODES;
  return title(pending.action)+'<p class="muted">'+(gp?'Choose how to refresh policy. No policy folders or saved credentials are deleted.':'Choose the DISM level. CheckHealth and ScanHealth inspect the image; Full also runs RestoreHealth.')+'</p><fieldset class="option-box"><legend>'+ (gp?'Choose GPUpdate mode':'Choose DISM mode')+'</legend>'+choices.map(([value,label,note])=>'<label class="radio-card"><input type="radio" name="mode" value="'+value+'" '+(value===pending.mode?'checked':'')+'><span>'+esc(label)+'<small>'+esc(note)+'</small></span></label>').join("")+'</fieldset><div class="button-row">'+button('Continue','continue','primary')+button(icon('back')+'Go back','menu')+'</div>';
}
function confirmMarkup(){const {action,mode}=uiState.pending;return '<h1 tabindex="-1">Confirm: '+esc(TASKS[action].title)+'</h1><p class="muted">Deleted files cannot be recovered from the Recycle Bin.</p><div class="warning-box"><p><strong>This will affect sample data only:</strong></p><p class="scope">'+esc(scope(action,uiState.profile,mode))+'</p><p class="label">This browser demo does not delete any real files.</p></div>'+identity(uiState.profile)+'<div class="button-row">'+button('Start cleanup','start','primary')+button(icon('back')+'Go back','menu')+'</div>';}
function runningMarkup(){const request=uiState.runner.request;return title(request.action)+identity(request.profile)+'<p class="scope">Affects: '+esc(scope(request.action,request.profile,request.mode))+'</p><div class="progress-panel"><div class="progress-heading"><strong id="stage">Starting task...</strong><span id="elapsed" class="elapsed">Elapsed 00:00 (simulated run)</span></div><div class="progress-track" id="progress" role="progressbar" aria-label="Simulated task progress"><div id="progress-fill" class="progress-fill indeterminate"></div></div><p id="progress-note" class="progress-note"></p></div><p class="benefit"><strong>How it may help: </strong>'+esc(TASKS[request.action].helps)+'</p><p class="activity-label">Activity · simulated output · shortened timings</p><pre id="activity" class="activity" tabindex="0" aria-label="Simulated activity output"></pre><div class="task-footer"><p id="task-footer">Other tasks are unavailable until this task finishes or stops. Cancelling does not undo sample changes.</p>'+button(icon('cancel')+'<span>Cancel task</span>','cancel','danger','id="cancel-task"')+'</div>';}
function reportCards(ids){return ids.map(id=>uiState.model.reports.find(report=>report.id===id)).filter(Boolean).map(report=>'<div class="report-card"><div class="report-info"><strong>'+esc(report.label)+'</strong><small>'+esc(report.time)+' · '+esc(report.profile)+'</small><small>Simulated location: '+esc(report.path)+'</small></div>'+button(icon('report')+'Open report','open-report','','data-report="'+report.id+'"')+'</div>').join("");}
function resultsMarkup(){
  const result=uiState.last,known=result.outcomeKnown!==false;
  const headlines={SUCCESS:"Task completed",PARTIAL:"Completed with issues",FAILED:"Task failed",CANCELLED:"Task cancelled",BUSY:"Another maintenance task is running"};
  return title(result.action)+'<div class="banner '+(known?result.status.toLowerCase():'unknown')+'"><h2>'+esc(known?headlines[result.status]:'Outcome unknown')+'</h2><p>'+esc(result.message)+'</p><p class="completion-meta">Sample result · shortened run took '+elapsed(result.elapsedMs)+'</p></div>'+identity(result.profile)+(result.action==='Maintenance'?'<p class="summary">Maintenance: '+status(result.maintenanceStatus)+' · Report generation: '+status(result.reportStatus)+'</p>':'')+table(result.action==='Report'?'Health measurements':'Measurements / cleanup before and after',result.rows)+(result.action==='Maintenance'?table('Maintenance tasks',result.tasks)+table('Report-generation outcomes',result.reportResults):'')+(result.reports.length?'<h2>Reports · simulated snapshots</h2>'+reportCards(result.reports):'')+'<details><summary>Activity output (simulated)</summary><pre class="activity" tabindex="0">'+esc(result.logs.join('\n'))+'</pre></details><div class="button-row">'+button(icon('back')+'Back to toolkit','menu','primary')+'</div>';
}
function listMarkup(){return '<h1 tabindex="-1">Reports · simulated folder</h1><p class="muted">Snapshots saved in this demo session. No files are read from your computer.</p>'+(uiState.model.reports.length?reportCards(uiState.model.reports.map(report=>report.id)):'<p class="empty-state">No sample reports yet. Generate a health report or run full maintenance to create one.</p>')+'<div class="button-row">'+button(icon('back')+'Back to toolkit','menu','primary')+'</div>';}
function reportMarkup(){const report=uiState.model.reports.find(report=>report.id===uiState.report);if(!report)return listMarkup();return '<h1 tabindex="-1">Sample report</h1><div class="report-view"><h2>System Health Report</h2><p>'+esc(report.label)+' | '+esc(report.time)+'</p><p><strong>Computer:</strong> '+esc(report.computer)+'<br><strong>Running account:</strong> '+esc(report.account)+'<br><strong>Selected target profile:</strong> '+esc(pathFor(report.profile))+'</p><h2>Overall: '+status(report.overall)+'</h2><p>Unavailable data is not a healthy zero. Selecting a profile does not switch accounts. Downloads and Outlook files are measured only.</p>'+table('Measurements',report.rows)+'<p>These sample measurements are an immutable snapshot. They do not prove Windows repairs succeeded. Outlook is checked in two local cache folders only; no mailbox contents are inspected.</p><p class="label">Simulated location: '+esc(report.path)+'. No file was created. Sample report storage size is ignored in disk calculations.</p></div><div class="button-row">'+button(icon('back')+'Back','report-back','primary')+'</div>';}
let lastAnnouncement="";
function announce(text){if(typeof document==='undefined')return;const target=document.getElementById('announcer');if(target&&text!==lastAnnouncement){target.textContent=text;lastAnnouncement=text;}}

// Motion is presentation only: navigation and task locks take effect immediately.
let pageMotionCleanup=null;
function animateElement(element,frames,options){
  if(typeof element.animate!=='function')return null;
  return element.animate(frames,options);
}
function transitionPage(target,outgoing,beforeHeight){
  const incoming=target.querySelector('.page');
  if(typeof incoming.animate!=='function')return;
  const afterHeight=target.getBoundingClientRect().height;
  const effects=[];
  if(outgoing){
    // The outgoing screen is visual only, never a second set of active controls.
    outgoing.className='page page-leaving';outgoing.setAttribute('aria-hidden','true');outgoing.setAttribute('inert','');
    outgoing.querySelectorAll('[id]').forEach(node=>node.removeAttribute('id'));
    outgoing.querySelectorAll('input,select,button').forEach(node=>{node.disabled=true;node.removeAttribute('name');});
    outgoing.querySelectorAll('[tabindex]').forEach(node=>node.removeAttribute('tabindex'));
    target.append(outgoing);
    effects.push(animateElement(outgoing,[{opacity:1,transform:'translateY(0)'},{opacity:0,transform:'translateY(-8px)'}],{duration:140,easing:'ease-out',fill:'both'}));
    target.classList.add('screen-transition');
    effects.push(animateElement(target,[{height:beforeHeight+'px'},{height:afterHeight+'px'}],{duration:380,easing:'cubic-bezier(.22,1,.36,1)'}));
  }
  effects.push(animateElement(incoming,[{opacity:0,transform:'translateY(14px)'},{opacity:1,transform:'translateY(0)'}],{duration:360,delay:outgoing?45:0,easing:'cubic-bezier(.16,1,.3,1)',fill:'both'}));
  const cleanup=()=>{
    effects.forEach(effect=>{if(effect)effect.cancel();});
    if(outgoing)outgoing.remove();target.classList.remove('screen-transition');
    if(pageMotionCleanup===cleanup)pageMotionCleanup=null;
  };
  pageMotionCleanup=cleanup;
  let remaining=effects.filter(Boolean).length;
  effects.filter(Boolean).forEach(effect=>effect.addEventListener('finish',()=>{if(--remaining===0)cleanup();},{once:true}));
}
function render(){
  if(typeof document==='undefined')return;
  const target=document.getElementById('screen');if(!target)return;
  if(pageMotionCleanup)pageMotionCleanup();
  const outgoing=target.querySelector('.page'),beforeHeight=target.getBoundingClientRect().height;
  const markup={menu:menuMarkup,options:optionsMarkup,confirm:confirmMarkup,running:runningMarkup,results:resultsMarkup,list:listMarkup,report:reportMarkup}[uiState.view];
  target.innerHTML='<section class="page">'+markup()+'</section>';
  document.getElementById('reset-demo').disabled=isBusy();
  window.scrollTo(0,0);
  const heading=target.querySelector('h1');if(heading)heading.focus({preventScroll:true});
  if(uiState.view==='running')updateRunning(uiState.runner);else announce(heading?heading.textContent:'Toolkit demo');
  transitionPage(target,outgoing,beforeHeight);
}
function committedPercent(runner){
  const current=runner.stage;
  if(runner.cancelled||!current)return null;
  const dism=current.label.match(/^DISM: (ScanHealth|RestoreHealth)$/);
  const pattern=current.label==='Scanning protected Windows files'?/^Sample verification (\d+)% complete\.$/:dism?new RegExp('^Sample '+dism[1]+' progress: (\\d+)%\\.$'):null;
  if(!pattern)return current.percent;
  for(let i=runner.result.logs.length-1;i>=0;i--){const match=runner.result.logs[i].match(pattern);if(match)return Number(match[1]);}
  return 0;
}
function updateRunning(runner){
  if(typeof document==='undefined'||uiState.runner!==runner||uiState.view!=='running')return;
  const stage=document.getElementById('stage'),fill=document.getElementById('progress-fill'),progress=document.getElementById('progress');if(!stage)return;
  const cancelling=runner.cancelled,current=runner.stage;
  const nextStage=cancelling?'Cancelling task...':current?current.label:'Starting task...';
  if(stage.textContent!==nextStage){stage.textContent=nextStage;animateElement(stage,[{opacity:.35,transform:'translateY(3px)'},{opacity:1,transform:'translateY(0)'}],{duration:220,easing:'ease-out'});}
  announce(nextStage);
  document.getElementById('elapsed').textContent='Elapsed '+elapsed(runner.scheduler.now()-runner.started)+' (simulated run)';
  const percent=committedPercent(runner);
  fill.classList.toggle('indeterminate',percent===null);fill.style.width=percent===null?'':percent+'%';
  if(percent===null)progress.removeAttribute('aria-valuenow');else progress.setAttribute('aria-valuenow',percent);
  document.getElementById('progress-note').textContent=cancelling?'Waiting for the sample operation to stop. Completed sample changes are retained.':percent===null?'Working. This stage has no measurable percentage or remaining time. Timings are shortened for the simulation.':(current.note||'Scripted sample progress')+' ('+percent+'%) · simulated';
  const output=document.getElementById('activity'),shown=Number(output.dataset.lines||0);
  if(shown<runner.result.logs.length){
    const fragment=document.createDocumentFragment();
    runner.result.logs.slice(shown).forEach(line=>{const node=document.createElement('span');node.className='log-line';node.textContent=line;fragment.append(node);});
    output.append(fragment);output.dataset.lines=runner.result.logs.length;output.scrollTop=output.scrollHeight;
  }
  const cancel=document.getElementById('cancel-task');cancel.disabled=cancelling;cancel.querySelector('span').textContent=cancelling?'Cancelling...':'Cancel task';
  if(cancelling)document.getElementById('task-footer').textContent='Stopping this sample task before allowing another one. No real Windows operation is running.';
}
function choose(action){
  if(isBusy()||!TASKS[action])return false;
  if(action==='ReportsFolder'){uiState.view='list';render();return true;}
  uiState.pending={action,mode:action==='GPUpdate'?'Force':'CheckOnly'};
  if(['Maintenance','GPUpdate','DISM'].includes(action))uiState.view='options';
  else if(['Temp','Recycle'].includes(action))uiState.view='confirm';
  else return startTask();
  render();return true;
}
function startTask(){
  if(isBusy()||!uiState.pending)return false;
  const request={...uiState.pending,profile:uiState.profile,scenario:uiState.scenario},generation=++uiState.generation;
  const runner=new Simulation(uiState.model,request,updateRunning,result=>{
    if(uiState.runner!==runner||uiState.generation!==generation)return;
    uiState.last=result;uiState.runner=null;uiState.pending=null;uiState.view='results';render();if(typeof document!=='undefined')announce(result.status==='CANCELLED'?'Task cancelled; completed sample work retained.':document.querySelector('.banner h2').textContent);
  });
  uiState.runner=runner;uiState.view='running';render();runner.start();return true;
}
function resetDemo(){
  // Like the toolkit, require cancellation to finish before accepting another action.
  if(isBusy())return false;
  if(uiState.runner)uiState.runner.dispose();
  uiState={model:new SampleModel(),profile:'Sample User',scenario:'Success',view:'menu',pending:null,runner:null,last:null,report:null,reportCaller:'list',generation:uiState.generation+1};render();announce('Demo reset. All fictional data restored.');return true;
}
function handleCommand(command,element){
  if(command==='cancel'){if(isBusy())uiState.runner.cancel();return;}
  if(isBusy())return;
  if(command==='menu'){uiState.view='menu';uiState.pending=null;}
  else if(command==='continue'&&uiState.view==='options'){if(uiState.pending.action==='Maintenance')uiState.view='confirm';else{startTask();return;}}
  else if(command==='start'&&uiState.view==='confirm'){startTask();return;}
  else if(command==='open-report'&&element.dataset.report){uiState.report=element.dataset.report;uiState.reportCaller=uiState.view;uiState.view='report';}
  else if(command==='report-back'){uiState.view=uiState.reportCaller;uiState.report=null;}
  else return;
  render();
}
if(typeof document!=='undefined'&&document.getElementById('screen')){
  document.getElementById('reset-demo').addEventListener('click',resetDemo);
  document.getElementById('screen').addEventListener('click',event=>{const target=event.target.closest('button');if(!target||target.disabled)return;if(target.dataset.task)choose(target.dataset.task);else if(target.dataset.command)handleCommand(target.dataset.command,target);});
  document.getElementById('screen').addEventListener('change',event=>{
    if(isBusy())return;
    if(event.target.id==='profile'&&PROFILE_NAMES.includes(event.target.value))uiState.profile=event.target.value;
    if(event.target.id==='scenario'&&SCENARIOS.includes(event.target.value))uiState.scenario=event.target.value;
    if(event.target.name==='mode'&&uiState.pending){const valid=uiState.pending.action==='GPUpdate'?['Normal','Force']:DISM_MODES.map(row=>row[0]);if(valid.includes(event.target.value))uiState.pending.mode=event.target.value;}
  });
  // We do not add browser history entries; a back/forward restore never enables
  // hidden menu controls while a simulated run is active.
  window.addEventListener('popstate',()=>{if(isBusy()){uiState.view='running';render();}});
  window.addEventListener('pageshow',()=>{if(isBusy()){uiState.view='running';render();}});
  render();
}
