#!/usr/bin/env bash

# configure monitor api domain
read -p "Please enter chosen domain for the api (defaults to api.raspberrypi.local): " domain
servername=${domain:="api.raspberrypi.local"}

# Configure discord environment variables
echo "Please configure your discord settings."
read -p "Please enter your discord user id: "  discord_user_id
read -p "Please enter your discord app token: " discord_app_token
read -p "Please enter your discord channel id for system monitoring notifications: " discord_channel_id
read -p "Please enter your discord channel webhook url for backup job notifications: "  discord_webhook

if [ ! -d /etc/backup ]; then
    echo "creating backup config directory"
    mkdir /etc/backup
fi

cat << EOF > /etc/backup/.env
SYSAPI_URL=http://$servername/
DISCORD_TOKEN=$discord_app_token
USER_ID=<@$discord_user_id>
CHANNEL_ID=$discord_channel_id

BACKUP_WEBHOOK=$discord_webhook
EOF