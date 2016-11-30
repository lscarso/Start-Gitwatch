# http://dereknewton.com/2011/05/monitoring-file-system-changes-with-powershell/
# http://superuser.com/questions/226828/how-to-monitor-a-folder-and-trigger-a-command-line-action-when-a-file-is-created
# http://jnotify.sourceforge.net/index.html

$gitPath = "C:\Data\GitPortable\App\Git\bin"
$env:path+=";$gitPath"
$Script:excludedItems = ".git"

if (-Not (Get-Command git -errorAction SilentlyContinue)) {
  Write-Output "Error: git is not installed"
  Exit 1
}

if ($args.Count -eq 0) {
  $target_dir = $PSScriptRoot
} else {
  $target_dir = $Args[0]
}

if (-Not (Test-Path $target_dir)) {
  Write-Output "Error: Invalid directory '$target_dir'"
  Exit 1
}

$duration_in_seconds = 2
$autosave_message = "autosave"


function getCurrentDate() {
 $currentDate = Get-Date
 $currentDate = "{0:yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'}" -f $currentDate.ToUniversalTime()
 return $currentDate
}

try {
    Push-Location $target_dir

    if (-Not (Test-Path ".git")) {
        Write-Output "Error: Invalid git repository '$target_dir'"
        Exit 1
    }

    if ($duration_in_seconds -lt 0) {
        Write-Output "Error: Invalid duration '$duration_in_seconds', value must be >= 0";
        Exit 2
    }

    ### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
    Write-Output "Enabling FileSystem Watcher on $target_dir"
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $target_dir
    #$watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $true
    $watcher.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'
    $watcher.EnableRaisingEvents = $true

    ### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
    $action = {
        $watcher.EnableRaisingEvents = $False
        $path = $eventArgs.FullPath
        If (-not $path.Contains('.git')) {
            Write-Host "$($eventARgs.ChangeType) - $($eventArgs.FullPath)"
            #$files_changed = (git status)
            #write-host $files_changed
            #if (-Not [string]::IsNullOrEmpty($files_changed)) {
            #$current_branch = git rev-parse --abbrev-ref HEAD
            Write-Host 'git add -A .'
            &"git" "add" "-A" "."
            Write-Host 'git commit'
            &"git commit -am $autosave_message"

            #git log --format="%C(auto)[$current_branch %h] %s" -n 1 --stat
            &"git pull"
            &"git push"
            $watcher.EnableRaisingEvents = $true
            #}
        }
    }     

    ### DECIDE WHICH EVENTS SHOULD BE WATCHED 
    $changed = Register-ObjectEvent $watcher "Changed" -Action $action
    $created = Register-ObjectEvent $watcher "Created" -Action $action
    $deleted = Register-ObjectEvent $watcher "Deleted" -Action $action
    $renamed = Register-ObjectEvent $watcher "Renamed" -Action $action
  
  
  
    $base_commit = git rev-parse HEAD 2>$null
    if ($LASTEXITCODE -eq 128) {
        Write-Output "Warning: Creating initial commit for new git repository"
        git commit --allow-empty -m "initial commit"
        $base_commit = git rev-parse HEAD 2>$null
    }

    $base_commit = $base_commit.Substring(0, 7)
    $current_date = getCurrentDate

    $script_name = $MyInvocation.MyCommand.Name
    $repository = git rev-parse --show-toplevel
    Write-Output "$script_name
-------------------------------------------------------------
     Started: $current_date
    Duration: Every $duration_in_seconds second(s)
  Repository: $repository ($base_commit)
-------------------------------------------------------------"

    while($true){
        sleep 2
    }
    #pause

} finally {
    Write-Output "Exit..."
    Unregister-Event $changed.Id
    Unregister-Event $created.Id
    Unregister-Event $deleted.Id
    Unregister-Event $renamed.Id
    
    #git log "$base_commit...HEAD" --format="%C(auto) %h %s (%cd)" --date=relative
    Pop-Location
}

