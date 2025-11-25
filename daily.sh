#!/bin/bash

cd /home/wackysama/Projects/personal/daily-commit

echo "Last run: $(date)" > last_run.txt

git add last_run.txt
git commit -m "Daily update $(date '+%Y-%m-%d %H:%M:%S')"
git push

