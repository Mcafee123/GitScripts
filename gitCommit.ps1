 param (
	[string]$gitPath = "C:\Program Files (x86)\Git\bin\git.exe"
 )

  function Log([string]$msg, [string]$status = "NORMAL")
 {
    write-host "##teamcity[message text='$msg' status='$status']"
 }

 function SetConfig()
 {
    Log "set user name and e-mail"
    $args = @("config", "--system", "user.name", "'build server'")
    & "$gitPath" $args
    $args = @("config", "--system", "user.email", "builds@itree.ch")
    & "$gitPath" $args
    if ($LASTEXITCODE -ne 0)
    {
        Log "could not set username and email" "WARNING"
    }
 }

 function Commit()
 {
    Log "add changes"
    & $gitPath add -u
    if ($LASTEXITCODE -ne 0)
    {
        Log "add failed" "ERROR"
        exit 1
    }
    Log "commit changes"
    $args = @("commit", "-m build: $buildNumber created")
    & "$gitPath" $args
    if ($LASTEXITCODE -ne 0)
    {
        Log "commit failed" "ERROR"
        exit 1
    }
 }

 function CreateLastBuildBranch()
 {
    Log "create last-build branch"
    & $gitPath branch --force last-build HEAD
    if ($LASTEXITCODE -ne 0)
    {
        Log "create last build branch failed" "ERROR"
        exit 1
    }
 }

 function PushToCentralRepo()
 {
    # check path
    Log "push last-build to central repository"
	$centralRepo = [string](git config --get remote.origin.url) 
    if ("$centralRepo" -eq "")
    {
        Log "no path to central repository"
        return 1
    }

    #check if remote is already there (in case of an error in a previous build cycle)
    [string[]]$remotes = & $gitPath remote
    if ($remotes.Contains("central") -eq $false)
    {
        # create a remote for the cental repo
        Log "create remote"
        $args = @("remote", "add", "central", $centralRepo)
        & "$gitPath" $args
        if ($LASTEXITCODE -ne 0)
        {
            Log "could not add remote" "ERROR"
            exit 1
        }
    }

    # delete remote last-build
	if ($remotes.Contains("last-build") -eq $true)
    {
		Log "delete last-build in remote repository"
		$args = @("push", "central", ":last-build")
		& $gitPath $args
		if ($LASTEXITCODE -ne 0)
		{
			Log "could delete last-build branch in central repository" "WARNING"
		}
	}

    # push changes to last-build
    Log "push last build"
    $args = @("push", "--force", "central", "last-build:last-build")
    & "$gitPath" $args
    if ($LASTEXITCODE -ne 0)
    {
        Log "could not push changes to remote" "ERROR"
        exit 1
    }

    #remove the remote "central repo"
    Log "remove remote"
    $args = @("remote", "remove", "central")
    & "$gitPath" $args
    if ($LASTEXITCODE -ne 0)
    {
        Log "could not remove remote" "ERROR"
        exit 1
    }
 }

# build number
$buildNumber = $env:build_number
# set config details
SetConfig
# commit changes
Commit
# create last-build branch
CreateLastBuildBranch
# push changes to central repo
PushToCentralRepo

Log "commit $buildNumber ok"
exit 0