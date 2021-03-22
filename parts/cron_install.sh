#!/usr/bin/env bash

# Copy backup scripts
echo "Configuring backups"
if [ ! -d /etc/backup ]; then
    echo "creating backup config directory"
    mkdir /etc/backup
fi
echo "copying backup cron jobs"
cp $(pwd)/cron/backup-incremental-exclusions.txt /etc/backup/
cp $(pwd)/cron/backup-incremental /etc/cron.daily/
cp $(pwd)/cron/backup-image /etc/cron.monthly/

cat << EOF > /etc/backup/.env
SYSAPI_URL=http://$servername/
DISCORD_TOKEN=$discord_app_token
USER_ID=<@$discord_user_id>
CHANNEL_ID=$discord_channel_id

BACKUP_WEBHOOK=$discord_webhook
EOF