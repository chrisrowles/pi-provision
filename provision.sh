#!/usr/bin/env bash

[[ "$(whoami)" != 'root' ]] &&
{
    echo "this script must be run as root."
    exit 1;
}


WD=$(pwd)


echo "making sure system is up-to-date"
apt-get -y update
apt-get -y upgrade


# configure python3 (assumes it is installed... usually is on later versions of raspbian OS)
PYTHONDEFAULT=`python -V | awk -F ' ' '{print $2}' | awk -F '.' '{print $1}'`;
if [[ $PYTHONDEFAULT == "3" ]]
    then
        echo "python 3 is set as default"
    else
        # TODO check update-alternatives --list first
        echo "configuring python3 as default"
        update-alternatives --install  /usr/bin/python python /usr/bin/python3 1
        update-alternatives --set python /usr/bin/python3
fi


# configure pip3
PIPINSTALL=`dpkg -s python3-pip | grep Status`;
if [[ $PIPINSTALL == S* ]]
    then
        echo "pip3 is installed"
    else
        echo "installing pip3"
        apt-get -y install python3-pip
fi
echo "configuring pip3 as default"
update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
update-alternatives --set pip /usr/bin/pip3
echo "installing discord.py"
pip install discord.py

# make sure discord.sh is installed for webhooks.
if [ -f /usr/bin/discordnotification ];
    then
        echo "discord.sh is installed"
    else
        echo "Installing discord.sh from https://github.com/ChaoticWeg"
        wget https://raw.githubusercontent.com/ChaoticWeg/discord.sh/master/discord.sh -O /usr/bin/discordnotification
        chmod u+x /usr/bin/discordnotification
fi


# configure apache and virtualhost helper script
APACHEINSTALL=`dpkg -s apache2 | grep Status`;
if [[ $APACHEINSTALL == S* ]]
    then
        echo "apache is installed"
    else
        echo "installing apache"
        apt-get -y install apache2
fi
# install mod_wsgi
apt-get -y install libapache2-mod-wsgi-py3
echo "making sure apache is started and configured to run at boot"
systemctl start apache2
systemctl enable apache2
echo "enabling mod headers and mod rewrite"
a2enmod headers
a2enmod rewrite
if [ -f /usr/bin/virtualhost ];
    then
        echo "virtualhost helper script is installed"
    else
        echo "installing virtualhost helper script"
        wget https://raw.githubusercontent.com/chrisrowles/dotfiles/master/scripts/virtualhost -O /usr/bin/virtualhost
        chmod u+x /usr/bin/virtualhost
fi
echo "adding pi to www-data group and changing ownership of /var/www"
usermod -aG pi:www-data
chown -R pi:www-data /var/www


# make sure fail2ban is installed
JAILINSTALL=`dpkg -s fail2ban | grep Status`;
if [[ $JAILINSTALL == S* ]]
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
# make sure fail2ban is started and enabled at boot
echo "starting fail2ban and enabling at system boot"
systemctl start fail2ban
systemctl enable fail2ban


# make sure git is installed
GITINSTALL=`dpkg -s git | grep Status`;
if [[ $GITINSTALL == S* ]]
    then
        echo "git is installed"
    else
        echo "installing git"
        apt-get -y install git
fi


# configure system monitoring api
echo "cloning pi-monitor-api"
if [ ! -d /var/www/flaskapps ];
    then
        mkdir /var/www/flaskapps
    else
        if [ ! -d /var/www/flaskapps/pi-monitor-api ]; then
            rm -rf /var/www/flaskapps/pi-monitor-api
        fi
fi
git clone https://github.com/chrisrowles/pi-monitor-api.git /var/www/flaskapps/pi-monitor-api
cd /var/www/flaskapps/pi-monitor-api
# TODO create a virtualenv instead
pip install -r requirements.txt
cd $WD
echo "configuring virtual host"
AVAILABLECONF=/etc/apache2/sites-available/api.raspberrypi.local.conf
ENABLEDCONF=/etc/apache2/sites-enabled/api.raspberrypi.local.conf
if [ -f $AVAILABLECONF ]; then
    rm -rf $ENABLEDCONF
    rm -rf $AVAILABLECONF
fi
if ! cat << EOF > $AVAILABLECONF
<VirtualHost *:80>
    ServerName api.raspberrypi.local
    ServerAlias www.api.raspberrypi.local
    WSGIScriptAlias / /var/www/flaskapps/pi-monitor-api/api.wsgi
    <Directory /var/www/flaskapps/pi-monitor-api/app>
        Options FollowSymLinks MultiViews
        AllowOverride all
        Require all granted
    </Directory>
    ErrorLog /var/log/apache2/api.raspberrypi.local-error.log
    CustomLog /var/log/apache2/api.raspberrypi.local-access.log combined
</VirtualHost>
EOF
then
    echo "error creating virtual host."
else
    echo "success, virtual host created."
    ln -s $AVAILABLECONF $ENABLEDCONF
    systemctl restart apache2
fi


# Copy backup scripts (assumes hdd is connected and mounted in correct location)
echo "Configuring backups"
if [ ! -d /etc/backup ]; then
    mkdir /etc/backup
fi
cp $(pwd)/cron/backup-incremental-exclusions.txt /etc/backup/
cp $(pwd)/cron/backup-incremental.sh /etc/cron.daily/
cp $(pwd)/cron/backup-image.sh /etc/cron.monthly/


# Make sure supervisor is installed
SUPERVISORINSTALL=`dpkg -s supervisor | grep Status`;
if [[ $SUPERVISORINSTALL == S* ]]
    then
        echo "supervisor is installed."
    else
        echo "supervisor is not installed."
        echo "Installing supervisor. Please wait..."
        apt-get -y install supervisor
        # Configure to run as user pi
        chown -R pi:pi /var/log/supervisor
        cp $(pwd)/etc/supervisord/supervisord.conf /etc/supervisor/supervisord.conf
fi

# Configure monitord
if [ -d /home/pi/monitord ];
    then
        echo "monitord is installed, leaving it alone."
    else
        # TODO create virtualenv
        pip install tabulate
        pip install python-dotenv
        sudo -u pi git clone https://github.com/chrisrowles/pi-monitord.git /home/pi/pi-monitord
        ln -s /home/pi/pi-monitord/supervisor/bot.supervisor /etc/supervisor/conf.d/
        sudo -u pi supervisord
        sudo -u pi supervisorctl status
fi

echo "Provisioning complete. Don't forget to add discord environment variables to /home/pi/.env"

exit 0
