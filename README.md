# Daily Commit Script (Linux Automation)

> This repository contains a simple automation setup for generating daily GitHub commits using a shell script and a systemd timer. It's useful for learning automation, testing workflows, or keeping a repository active every day using a small, consistent update.

## How It Works

A shell script updates a file in this repository, commits the change, and pushes it to GitHub.
A systemd timer schedules that script to run automatically once per day — with better logging, timezone support, and reliability than a traditional cron job.

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

Why `GIT_SSH_COMMAND`? systemd runs with a stripped-down environment — it doesn't load your user session, SSH agent, or default keys. Setting this variable explicitly tells Git exactly which key to use.

Why `git pull --rebase` before push? Prevents push rejections if the remote has diverged (e.g. from another machine or manual commit).

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

6. Create the systemd Service Unit

Create the service file at `/etc/systemd/system/daily-commit.service`:

```bash
sudo nano /etc/systemd/system/daily-commit.service
```

Paste the following:

```bash
[Unit]
Description=Daily GitHub commit
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=<username>
ExecStart=/home/<username>/path/to/repo/daily.sh
StandardOutput=journal
StandardError=journal
```

- `Type=oneshot` — runs once and exits, perfect for scripts.
- `After=network-online.target` — waits for network before running, avoiding silent SSH failures.
- `StandardOutput=journal` — logs go to journald automatically, no log file needed.

---

7. Create the systemd Timer Unit

Create the timer file at `/etc/systemd/system/daily-commit.timer`:

```bash
sudo nano /etc/systemd/system/daily-commit.timer
```

Paste the following:

```bash
[Unit]
Description=Run daily-commit every day at midnight

[Timer]
OnCalendar=*-*-* 00:00:00 Asia/Manila
Persistent=true

[Install]
WantedBy=timers.target
```

- `OnCalendar=*-*-* 00:00:00 Asia/Manila` — fires at midnight every day and explicitly sets the timezone so it always fires at midnight local time, not UTC.
- `Persistent=true` — if the machine was off at midnight, it will run the job on next boot instead of skipping it.

Adjust `TimeZone` to your own timezone (e.g. `America/New_York`, `Europe/London`). Find yours with:

```bash
timedatectl
```

---

8. Enable and Start the Timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now daily-commit.timer
```

Verify it's scheduled:

```bash
systemctl list-timers | grep daily-commit
```

You should see the next scheduled run time listed.

---

Verifying It Works

Run it manually on demand:

```bash
sudo systemctl start daily-commit.service
```

Check the logs:

```bash
journalctl -u daily-commit.service -n 30
```

You should see a successful commit and push output. If something went wrong, the error will be there too.

Follow logs in real time:

```bash
journalctl -u daily-commit.service -f
```

---

Notes

- No passwords stored. Everything authenticates via SSH key — no plaintext credentials anywhere.

- The private key (`~/.ssh/daily-commit-id_ed25519`) should have `600` permissions. SSH will refuse to use it otherwise. Verify with:

```bash
ls -lah ~/.ssh/
```

- If you ever rotate the key, update both the GitHub Deploy Key setting and the path inside `daily.sh`.

- Unlike cron, systemd timers are managed with standard `systemctl` commands — enable, disable, start, stop, status — consistent with every other service on your system.

- To disable the automation entirely:

```bash
sudo systemctl disable --now daily-commit.timer
```

---