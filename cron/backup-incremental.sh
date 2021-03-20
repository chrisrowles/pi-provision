#!/usr/bin/env bash

# Authors: Chris Rowles
# Incremental backup using rsync and discord webhooks.

echo "Starting incremental backup process"

# Load environment variables
echo "Loading ennvironment variables"
if [ -f "/home/pi/.env" ]; then
    export $(cat "/home/pi/.env" | grep -v '#' | awk '/=/ {print $1}')
fi

# Setting up directories
SUBDIR=incremental
DIR=/media/pi/backup/$SUBDIR/

# Check if backup directory exists
if [ ! -d "$DIR" ];
    then
        echo "Incremental backup directory $DIR does not exist, creating it now."
        mkdir $DIR
fi

# notify discord channel
discordnotification --webhook-url="$BACKUP_WEBHOOK" --text "**[incremental]** backup to \`$DIR\` started.\nRunning rsync in archive mode and preserving hard links."

echo "Starting incremental backup, this may take some time."
rsync -aH --delete --exclude-from=/home/pi/backup-incremental-exclusions.txt / $DIR

# notify discord channel
discordnotification --webhook-url="$BACKUP_WEBHOOK" --text "**[incremental]** backup has completed successfully.\nNext backup will be performed tomorrow at 09:00AM."
