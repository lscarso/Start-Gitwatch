$target_dir = "C:\Users\Luca\Documents\Git"
Push-Location $target_dir


try{
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $target_dir
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$action = {Write-Host "$($eventARgs.ChangeType) - $($eventArgs.FullPath)"}

$changed = Register-ObjectEvent $watcher "Changed" -Action $action
$created = Register-ObjectEvent $watcher "Created" -Action $action
$deleted = Register-ObjectEvent $watcher "Deleted" -Action $action
$renamed = Register-ObjectEvent $watcher "Renamed" -Action $action

while($true){
    sleep 2
}
} Finally{

Write-Output "Exit..."
Unregister-Event $changed.Id
Unregister-Event $created.Id
Unregister-Event $deleted.Id
Unregister-Event $renamed.Id
Pop-Location
}    


