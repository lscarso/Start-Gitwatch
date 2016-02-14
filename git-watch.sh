#!/usr/bin/env bash

if [[ ! -x "$(command -v git 2>&2)" ]]; then
  echo "Error: git is not installed"
  exit 1
fi

if [ ! -d $1 ]; then
  echo "Error: Invalid directory '$1'"
  exit 1
fi

trap 'on_exit; exit' SIGINT SIGQUIT
on_exit() {
  git log $base_commit...HEAD --format="%C(auto) %h %s (%cd)" --date=relative
  popd &> /dev/null
}

duration_in_seconds=2
autosave_message="autosave"

if [[ ! -z $1 ]]; then
  pushd $1 1> /dev/null
fi

if [[ ! -d .git ]]; then
  echo "Error: Invalid git repository '${PWD}'"
  exit 1
fi

if [[ $duration_in_seconds -lt 0 ]]; then
  echo "Error: Invalid duration '$duration_in_seconds', value must be >= 0";
  exit 2
fi

base_commit=$(git rev-parse HEAD 2>&2)
if [[ 128 -eq $? ]]; then
  echo "Warning: Creating initial commit for new git repository"
  git commit --allow-empty -m "initial commit"
  base_commit=$(git rev-parse HEAD 2>&2)
fi

base_commit="${base_commit:0:7}"
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

script_name="${0##*/}"
repository=$(git rev-parse --show-toplevel)

echo -e "$script_name
-------------------------------------------------------------
     Started: $current_date
    Duration: Every $duration_in_seconds second(s)
  Repository: $repository ($base_commit)
-------------------------------------------------------------"

while true; do
  files_changed=$(git status -s)

  if [[ ! -z $files_changed ]]; then
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    git add -AN
    git commit -am $autosave_message --quiet &> /dev/null
    git log --format="%C(auto)[$current_branch %h] %s" -n 1 --stat
    echo

    # git reset 1625758 &> /dev/null
    # git add -AN &> /dev/null
  fi

  sleep $duration_in_seconds
done
