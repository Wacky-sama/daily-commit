# Daily Commit Script (Linux Automation)

> This repository contains a simple automation setup for generating daily GitHub commits using a shell script and a cron job. It’s useful for learning automation, testing workflows, or keeping a repository active every day using a small, consistent update.

## How It Works

A shell script updates a file in this repository, commits the change, and pushes it to GitHub.
A Linux cron job schedules that script to run automatically once per day.

---

### Setup Instructions

1. Create your repository on your Github
Go to github.com and create a new repository. Clone it to your local machine:

```bash
git clone git@github.com:<username>/<repo-name>.git
cd <repo-name>
```

---

2. Generate an SSH Key (Dedicated for This Repo)

```bash
ssh-keygen -C "daily-commit"
```

- When prompted for a passphrase, you can leave it empty — cron runs unattended and can't type a passphrase for you.

---

3. Add the Public Key to GitHub
Copy your public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Then go to GitHub Repository > Settings > Deploy Keys > Add Deploy key, paste it in, and save.

3.1. Configure SSH

Edit your SSH config file:

```bash
nano ~/.ssh/config
```

Add:

```bash
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Set correct permissions and ownership:

```bash
sudo chmod 600 ~/.ssh/config

sudo chown $USER:$USER ~/.ssh/config
```

Test authentication:

```bash
ssh -T git@github.com
```

You should see:

```bash
Hi <username>/<repo-name>! You've successfully authenticated
```

---

4. Create the daily commit script
Inside the repository, create a file named daily.sh:

```bash
#!/bin/bash

# Point to SSH key
export GIT_SSH_COMMAND="ssh -i /home/<username>/.ssh/id_ed25519 -o StrictHostKeyChecking=no"

cd /path/to/your/repo || exit 1
echo "Last run: $(date)" > last_run.txt

git add last_run.txt
git commit -m "Daily update $(date '+%Y-%m-%d %H:%M:%S')"
git push
```

Why `GIT_SSH_COMMAND`? Cron runs with a stripped-down environment — it doesn't load your user session, so it won't find your SSH agent or default keys. Setting this variable explicitly tells Git exactly which key to use.

Make it executable:

```bash
chmod +x daily.sh
```

---

5. Test the Script Manually
From inside the repo:

```bash
bash /home/<username>/path/to/repo/daily.sh
```

If it commits and pushes successfully, you're good to go.

---

6. Add a cron job to automate the script
Open the cron editor:

```bash
crontab -e
```

Add a daily schedule (adjust the path and time to your preference):

```bash
0 9 * * * /path/to/daily.sh >> /path/to/daily.log 2>&1
```

This runs the script every day at 9:00 AM and saves output to daily.log.

---

Verifying It Works
After the cron job runs, check the log:

```bash
cat /home/<username>/path/to/daily.log
```

You should see a successful commit and push output. If something went wrong, the error will be in there too.

---

Notes

- No passwords stored. Everything authenticates via SSH key — no plaintext credentials anywhere.

- The private key (~/.ssh/daily-commit-id_ed25519) should have 600 permissions. SSH will refuse to use it otherwise. Verify with ls -lah ~/.ssh/.

- If you ever rotate the key, remember to update both the GitHub Repository setting and the path inside daily.sh.

---