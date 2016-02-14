# git-watch

A set of bash and powershell scripts to autocommit to a git repository.

This is a simpler multi-platform version [gitwatch](https://github.com/nevik/gitwatch)
by [nevik](https://github.com/nevik).

## Requirements
To run this script, you must have installed and globally available:
  * `git` ([git/git](https://github.com/git/git) or http://www.git-scm.com)

## Tested with
```md
bash: 4.3
git: 2.4, 2.5
powershell: 4.0
```

## What it does
 1. Validate `git` exists
 2. Validate the path is a directory
 3. Validate the path is a `git` repository
 4. Validate the time duration
 5. Find the current `HEAD` commit, if one doesn't exist an initial empty commit will be created
 6. Run `git status` every *n* seconds (default: 2 seconds)
 7. If `git status` is not empty, add all files/directories and commit with the *autosave* commit message
 8. Print output of list changes (hash, message, stats)
 9. On exit, show an abbreviated list of autosaved commits

## Configuration
```shell
# git-watch.sh
duration_in_seconds=2
autosave_message="autosave"
```

```powershell
# git-watch.ps1
$duration_in_seconds = 2
$autosave_message = "autosave"
```

## Usage
```
# bash
gitwatch.sh <repository_path>
```

```
# powershell
gitwatch.ps1 <repository_path>
```

If a repository is not specified, it'll check against the current directory.


## Sample output
*While running*
```
git-watch.sh
-------------------------------------------------------------
     Started: 2016-02-14T00:00:00Z
    Duration: Every 2 second(s)
  Repository: /path/to/repo (debac1e)
-------------------------------------------------------------
[master deadbee] autosave

 test-file.txt   |  9 ++++++++
 git-watch.ps1   | 72 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 git-watch.sh    | 68 +++++++++++++++++++++++++++++++++++++++++++++++++++++
 README.md       |  2 +-
 4 files changed, 150 insertions(+), 1 deletion(-)

[master ca5cade] autosave

 git-watch.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

[master 1acce55] autosave

 git-watch.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

*On interrupt/exit*: List of autosaved commits since start

```
 1acce55 autosave (1 second ago)
 ca5cade autosave (3 seconds ago)
 deadbee autosave (9 seconds ago)
```

