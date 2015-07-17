 param (
	[string]$gitPath = "C:\Program Files (x86)\Git\bin\git.exe",
	[string]$branchName = "master"
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
    & $gitPath diff --shortstat --exit-code origin/$branchName
    if ($LASTEXITCODE -ne 1)
    {
        Log "=== THIS IS NO ERROR === no changes found in $branchName === THIS IS NO ERROR ===" "WARNING"
    }
 }

function Cleanup()
{
    Log "reset"
    & $gitPath reset --hard HEAD
    Log "clean"
    & $gitPath clean --force -x -d -e cmn.Dlls/
    if($LASTEXITCODE -ne 0)
    {
        Log "cleanup failed" "WARNING"
        #exit 1
    }
}

function MergeChanges()
{
    Log "merge changes to build_history branch"
    & $gitPath merge -X theirs --no-ff --no-commit origin/$branchName
    if ($LASTEXITCODE -ne 0)
    {
        Log "cold not merge changes, perhaps something was deleted, try adding the deletion" "WARNING"
		& $gitPath add -u
		if ($LASTEXITCODE -ne 0)
		{
			Log "adding deletion failed" "ERROR"
			exit 1
		}
		& $gitPath commit -m "Merge remote-tracking branch 'origin/$branchName' into build-history, deleted files as in remote"
		if ($LASTEXITCODE -ne 0)
		{
			Log "committing deletion failed" "ERROR"
			exit 1
		}
    }
}

############################
# MAIN PROGRAM STARTS HERE #
############################

 #fetch changes
Fetch
# check for changes
CheckChanges
#cleanup
Cleanup
#merge changes into "build_history" branch
MergeChanges
Log "prepare working copy OK"
exit 0
