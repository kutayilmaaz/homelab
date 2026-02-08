#!/bin/bash
# Daily homelab backup to GitHub
# Runs at 6:00 AM daily

HOMEDIR=/srv/homelab
LOGFILE=/srv/homelab/.backup.log

cd "$HOMEDIR" || exit 1

# Ensure correct git author
git config user.name "kutayilmaaz"
git config user.email "contact@kutayyilmaz.com"

# Check if there are any changes
if git diff --quiet && git diff --cached --quiet; then
    echo "$(date): No changes to backup" >> "$LOGFILE"
    exit 0
fi

# Add all changes
git add -A

# Commit with timestamp
git commit -m "Auto backup: $(date +%Y-%m-%d %H:%M)"

# Push to GitHub
if git push origin master; then
    echo "$(date): Backup successful" >> "$LOGFILE"
else
    echo "$(date): Backup failed" >> "$LOGFILE"
fi
