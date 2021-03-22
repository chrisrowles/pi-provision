#!/usr/bin/env bash

# Copy backup scripts
echo "Configuring backups"
cp $(pwd)/cron/backup-incremental-exclusions.txt /etc/backup/
cp $(pwd)/cron/backup-incremental /etc/cron.daily/
cp $(pwd)/cron/backup-image /etc/cron.monthly/