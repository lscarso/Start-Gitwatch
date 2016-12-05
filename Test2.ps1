Param(
    [ValidateScript({Test-Path $_ -PathType ‘Container’})]
    [String]$PathToMonitor = 'C:\Users\Luca\Documents\Git\',
    [ValidateScript({Get-Command $_ -errorAction SilentlyContinue})]
    [String]$gitPath = 'C:\Data\GitPortable\App\Git\bin\git',
    [Switch]$Verbose
)

$global:gitwatch = @{
	git = $gitPath
	dir = $PathToMonitor
	debug = $Verbose
}


try{
    Push-Location $global:gitwatch.dir
    if (-Not (Test-Path ".git")) {
        Write-Host "Error: Invalid git repository '$global:gitwatch.dir'"
        Pop-Location
        Exit 1
    }
    Pop-Location

    $watcher = New-Object 'System.IO.FileSystemWatcher'
    $watcher.Path = $global:gitwatch.dir
    $watcher.IncludeSubdirectories = $true
    $watcher.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'

    $changed = Register-ObjectEvent $watcher 'Changed' -Action {
	    try {
            $watcher.EnableRaisingEvents = $false
            Get-Event | Remove-Event
		    $path = $eventArgs.FullPath
		    if (-not $path.Contains('.git')) {
			    Push-Location $global:gitwatch.dir
                & $global:gitwatch.git add $path
			    & $global:gitwatch.git commit -m "Autosave: $path changed."
			    if ($global:gitwatch.debug) {
				    Write-Host "Changed: $path"
			    }
                $gitstatus = $(& $global:gitwatch.git pull)
			    if ($global:gitwatch.debug) {
                    Write-Host "Git Pull: $gitstatus"
                }
                $gitstatus =$(& $global:gitwatch.git push)
  			    if ($global:gitwatch.debug) {
                    Write-Host "Git Push : $gitstatus"
                }
                Pop-Location
		    }
	    } catch {
		    Write-Host "Exception: $_"
	    } finally {
            $watcher.EnableRaisingEvents = $true
        }
    }

    $created = Register-ObjectEvent $watcher 'Created' -Action {
	    try {
            $watcher.EnableRaisingEvents = $false
            Get-Event | Remove-Event
		    $path = $eventArgs.FullPath
		    if (-not $path.Contains("\.git")) {
                Push-Location $global:gitwatch.dir
			    & $global:gitwatch.git add $path
			    & $global:gitwatch.git commit -m "Autosave: $path created."
			    if ($global:gitwatch.debug) {
				    Write-Host "Created: $path"
			    }
                & $global:gitwatch.git pull
                & $global:gitwatch.git push
                Pop-Location
		    }
	    } catch {
		    Write-Host "Exception: $_"
	    } finally {
            $watcher.EnableRaisingEvents = $true
        }
    }

    $deleted = Register-ObjectEvent $watcher 'Deleted' -Action {
	    try {
            $watcher.EnableRaisingEvents = $false
            Get-Event | Remove-Event
		    $path = $eventArgs.FullPath
		    if (-not $path.Contains('.git')) {
                Push-Location $global:gitwatch.dir
			    & $global:gitwatch.git rm -rf $path
			    & $global:gitwatch.git commit -m "Autosave: $Path removed."
			    if ($global:gitwatch.debug) {
				    Write-Host "Deleted: $path"
			    }
                & $global:gitwatch.git pull
                & $global:gitwatch.git push
                Pop-Location
		    }
	    } catch {
		    Write-Host "Exception: $_"
	    } finally {
            $watcher.EnableRaisingEvents = $true
        }
    }

    $renamed = Register-ObjectEvent $watcher 'Renamed' -Action {
	    try {
            $watcher.EnableRaisingEvents = $false
            Get-Event | Remove-Event
		    $oldPath = $eventArgs.OldFullPath
		    $path = $eventArgs.FullPath
		    # TODO: Check whether file was moved from or inside to repository.
		    if (-not $path.Contains('.git')) {
                Push-Location $global:gitwatch.dir 
			    & $global:gitwatch.git mv $oldPath $path
			    & $global:gitwatch.git commit -m "Autosave: $oldPath renamed."
			    if ($global:gitwatch.debug) {
				    Write-Host "Renamed: $oldPath → $path"
			    }
                & $global:gitwatch.git pull
                & $global:gitwatch.git push
                Pop-Location
		    }
	    } catch {
		    Write-Host "Exception: $_"
	    } finally {
            $watcher.EnableRaisingEvents = $true
        }
    }

    $base_commit = $(& $global:gitwatch.git rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -eq 128) {
        Write-Host "Warning: Creating initial commit for new git repository"
        & $global:gitwatch.git commit --allow-empty -m "initial commit"
        $base_commit = & $global:gitwatch.git rev-parse HEAD 2>$null
    }
    $base_commit = $base_commit.Substring(0, 7)

    $repository = & $global:gitwatch.git rev-parse --show-toplevel
    Write-Host "$script_name
-------------------------------------------------------------
     Started: $(Get-date)
  Repository: $repository ($base_commit)
-------------------------------------------------------------"

    $gitstatus = & $global:gitwatch.git pull
    if ($global:gitwatch.debug) {
        Write-Host "Git Pull: $gitstatus"
    }
    if ((-Not [string]::IsNullOrEmpty([string]$(& $global:gitwatch.git status --porcelain)))){
        $gitstatus = & $global:gitwatch.git push
        if ($global:gitwatch.debug) {
            Write-Host "Git Push : $gitstatus"
        }
    }

    $watcher.EnableRaisingEvents = $true

    Wait-Event

} finally {
    Write-Host "Exit..."
    Unregister-Event $changed.Id
    Unregister-Event $created.Id
    Unregister-Event $deleted.Id
    Unregister-Event $renamed.Id
    Get-Event | Remove-Event
}

