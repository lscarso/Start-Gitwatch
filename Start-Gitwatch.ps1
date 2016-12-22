Param(
    [ValidateScript({Test-Path $_ -PathType ‘Container’})]
    [String]$PathToMonitor = 'C:\Users\Luca\Documents\Git\',
    [ValidateScript({Get-Command $_ -errorAction SilentlyContinue})]
    [String]$gitPath = 'C:\Data\GitPortable\App\Git\bin\git',
    [Switch]$Verbose
)

# Global settings
$global:gitwatch = @{
	git = $gitPath
	dir = $PathToMonitor
	debug = $Verbose
}


try{
    New-Alias -Name git -Value $gitPath
    Push-Location $global:gitwatch.dir
    
    # Test if it's a git repository
    if (-Not (Test-Path ".git")) {
        Write-Host "Error: Invalid git repository '$global:gitwatch.dir'"
        Pop-Location
        Exit 1
    }

    #Inizialize fs watcher
    $watcher = New-Object 'System.IO.FileSystemWatcher'
    $watcher.Path = $global:gitwatch.dir
    $watcher.IncludeSubdirectories = $true
    $watcher.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'

    # register Events
    $changed = Register-ObjectEvent $watcher 'Changed' -Action {
	    try {
            $watcher.EnableRaisingEvents = $false
            Get-Event | Remove-Event
		    $path = $eventArgs.FullPath
		    if (-not $path.Contains('.git')) {
                git add $path
			    git commit -m "Autosave: $path changed."
			    if ($global:gitwatch.debug) {
				    Write-Host "Changed: $path"
			    }
                git pull
                git push
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
			    git add $path
			    git commit -m "Autosave: $path created."
			    if ($global:gitwatch.debug) {
				    Write-Host "Created: $path"
			    }
                git pull
                git push
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
			    git rm -rf $path
			    git commit -m "Autosave: $Path removed."
			    if ($global:gitwatch.debug) {
				    Write-Host "Deleted: $path"
			    }
                git pull
                git push
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
			    git mv $oldPath $path
			    git commit -m "Autosave: $oldPath renamed."
			    if ($global:gitwatch.debug) {
				    Write-Host "Renamed: $oldPath → $path"
			    }
                git pull
                git push
		    }
	    } catch {
		    Write-Host "Exception: $_"
	    } finally {
            $watcher.EnableRaisingEvents = $true
        }
    }

    # Check initial commit
    $base_commit = $(git rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -eq 128) {
        Write-Host "Warning: Creating initial commit for new git repository"
        git commit --allow-empty -m "initial commit"
        $base_commit = git rev-parse HEAD
    }
    
    # Start monitoring
    $base_commit = $base_commit.Substring(0, 7)
    $repository = git rev-parse --show-toplevel
    Write-Host "$script_name
-------------------------------------------------------------
     Started: $(Get-date)
  Repository: $repository ($base_commit)
-------------------------------------------------------------"

    git pull
    if ((-Not [string]::IsNullOrEmpty([string]$(git status --porcelain)))){
        git push 2>$null
    }

    $watcher.EnableRaisingEvents = $true

    #Wait for fs events
    Wait-Event

} finally {
    Write-Host "Exit..."
    # Unregister Events
    Unregister-Event $changed.Id
    Unregister-Event $created.Id
    Unregister-Event $deleted.Id
    Unregister-Event $renamed.Id
    Get-Event | Remove-Event
    Remove-Item alias:\git
    Pop-Location
}

