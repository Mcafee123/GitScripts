 param (
    [string]$gitPath = "C:\Program Files (x86)\Git\bin\git.exe"
 )

 function Log([string]$msg, [string]$status = "NORMAL")
 {
    write-host "##teamcity[message text='$msg' status='$status']"
 }

 function Fetch()
 {
    Log "fetch"
    & $gitPath fetch
    if ($LASTEXITCODE -ne 0)
    {
        Log "git fetch failed" "ERROR"
        exit 1
    }
 }

 function CheckChanges()
 {
    Log "check for changes"
    & $gitPath diff --shortstat --exit-code origin/master
    if ($LASTEXITCODE -ne 1)
    {
        Log "=== THIS IS NO ERROR === no changes found in master === THIS IS NO ERROR ===" "WARNING"
    }
 }

function Cleanup()
{
    Log "reset"
    & $gitPath reset --hard HEAD
    Log "clean"
    & $gitPath clean --force -x -d
    if($LASTEXITCODE -ne 0)
    {
        Log "cleanup failed" "ERROR"
        exit 1
    }
}

function MergeMasterChanges()
{
    Log "merge changes to build_history branch"
    & $gitPath merge -X theirs --no-ff --no-commit origin/master
    if ($LASTEXITCODE -ne 0)
    {
        Log "cold not merge changes" "ERROR"
        exit 1
    }
}

############################
# MAIN PROGRAM STARTS HERE #
############################

 #fetch changes
Fetch
# check for changes in master
CheckChanges
#cleanup
Cleanup
#merge changes into "build_history" branch
MergeMasterChanges
Log "prepare working copy OK"
exit 0