#!/bin/bash
# Unified daily backup script for kutayilmaaz
# Backs up: openclaw + homelab
# Uses YOUR git identity (already set globally)

DATE=$(date +%Y-%m-%d)
LOGFILE=/srv/homelab/.backup.log
GITHUB_TOKEN="${GITHUB_TOKEN}"

echo "=== Backup started: $(date) ===" >> "$LOGFILE"

# Backup 1: OpenClaw
echo "[$(date)] Backing up openclaw..." >> "$LOGFILE"
cd ~/.openclaw || exit 1
git add -A
if git commit -m "Daily backup: $DATE" 2>/dev/null; then
    git push "https://kutayilmaaz:${GITHUB_TOKEN}@github.com/kutayilmaaz/openclaw-backup.git" main 2>&1 >> "$LOGFILE"
    echo "[$(date)] OpenClaw backup: SUCCESS" >> "$LOGFILE"
else
    echo "[$(date)] OpenClaw backup: No changes" >> "$LOGFILE"
fi

# Backup 2: Homelab
echo "[$(date)] Backing up homelab..." >> "$LOGFILE"
cd /srv/homelab || exit 1
/srv/homelab/backup.sh 2>&1 | tee -a "$LOGFILE"

echo "=== Backup completed: $(date) ===" >> "$LOGFILE"
echo "" >> "$LOGFILE"
