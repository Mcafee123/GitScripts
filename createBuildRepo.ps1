param (
    [string]$sourceRepoPath = "",
    [string]$repoPath = "",
    [string]$branchName = "master"
)

function CheckParam([string]$tocheck, [string]$msg)
{
    if ("$tocheck" -eq "")
    {
        Write-Host $msg
        exit 1
    }
}

function CheckFolderExists([string]$folderName)
{
    Test-Path -path $folderName -PathType Container
}

CheckParam $sourceRepoPath "please provide source repository path (where the source repository lies)"
CheckParam $repoPath "please provide repository absolute path (where to create the build repository)"

if ((CheckFolderExists $sourceRepoPath) -eq $false)
{
    Write-Host "source repository folder does not exist"
    exit 1
}

if ((CheckFolderExists $repoPath) -eq $true)
{
    Write-Host "repository folder already exists"
    exit 1
}

New-Item $repoPath -ItemType directory
cd $repoPath
& git init
if ($LASTEXITCODE -ne 0)
{
    exit 1
}
& git remote add -t $branchName origin $sourceRepoPath
if ($LASTEXITCODE -ne 0)
{
    exit 1
}
& git fetch
if ($LASTEXITCODE -ne 0)
{
    exit 1
}
$firstCommit = [string](git log --oneline --first-parent origin/$branchName | tail -1)
$firstCommitHash = $firstCommit.Substring(0, $firstCommit.IndexOf(" "))
& git checkout -b build-history $firstCommitHash

Write-Host "Repository Created at $repoPath"
