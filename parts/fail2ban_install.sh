#!/usr/bin/env bash

# install fail2ban
echo "checking for fail2ban"
fail2ban_install=`dpkg -s fail2ban | grep Status`;
if [[ $fail2ban_install == S* ]]
    then
        echo "fail2ban is installed."
    else
        echo "fail2ban is not installed."
        echo "Installing fail2ban. Please wait..."
        apt-get -y install fail2ban

        echo "setting up discord webhook"
        cp $(pwd)/etc/fail2ban/action.d/discord_notifications.conf /etc/fail2ban/action.d/discord_notifications.conf

        echo "copying jail configuration"
        cp $(pwd)/etc/fail2ban/jail.local /etc/fail2ban/jail.local
fi

# start fail2ban at boot
echo "starting fail2ban and enabling at system boot"
systemctl start fail2ban
systemctl enable fail2ban
