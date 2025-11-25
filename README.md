# Daily Commit Script (Linux Automation)

> This repository contains a simple automation setup for generating daily GitHub commits using a shell script and a cron job. It’s useful for learning automation, testing workflows, or keeping a repository active every day using a small, consistent update.

## How It Works

A shell script updates a file in this repository, commits the change, and pushes it to GitHub.
A Linux cron job schedules that script to run automatically once per day.

### Setup Instructions

1. Clone the repository:

```bash
git clone https://github.com/Wacky-sama/daily-commit.git
cd daily-commit
```

2. Create the daily commit script
Inside the repository, create a file named daily.sh:

```bash
#!/bin/bash

cd /path/to/your/repo

echo "Last run: $(date)" > last_run.txt

git add last_run.txt
git commit -m "Daily update $(date '+%Y-%m-%d %H:%M:%S')"
git push
```

Make it executable:

```bash
chmod +x daily.sh
```

3. Allow Git to push without asking for credentials

```bash
git config --global credential.helper store
```

Then perform one manual push so Git stores your credentials.

4. Add a cron job to automate the script
Open the cron editor:

```bash
crontab -e
```

Add this daily schedule (adjust the path to your script):

```bash
0 9 * * * /path/to/daily.sh >> /path/to/daily.log 2>&1
```

This runs the script every day at 9:00 AM and saves output to daily.log.

5. Test the script manually
From inside the repo:

```bash
./daily.sh
```

If it commits and pushes correctly, the cron job will work as well.
