#!/usr/bin/env bash

[[ "$(whoami)" != 'root' ]] &&
{
    echo "this script must be run as root."
    exit 1;
}

wd=$(pwd)

echo "making sure system is up-to-date"
apt-get -y update
apt-get -y upgrade

# configure python3 (assumes it is installed... usually is on latest version of raspbian OS)
echo "checking for python 3"
python_default=`python -V | awk -F ' ' '{print $2}' | awk -F '.' '{print $1}'`;
if [[ $python_default == "3" ]]
    then
        echo "python 3 is set as default"
    else
        # TODO check update-alternatives --list first
        echo "configuring python 3 as default"
        update-alternatives --install /usr/bin/python python /usr/bin/python3 1
        update-alternatives --set python /usr/bin/python3
fi

# configure pip3
echo "checking for pip3"
pip_install=`dpkg -s python3-pip | grep Status`;
if [[ $pip_install == S* ]]
    then
        echo "pip3 is installed"
    else
        echo "installing pip3"
        apt-get -y install python3-pip
fi
echo "configuring pip3 as default"
update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
update-alternatives --set pip /usr/bin/pip3

# install discord.py
echo "installing discord.py"
pip install discord.py

# install discord.sh
echo "checking for discord.sh"
if [ -f /usr/bin/discordnotification ];
    then
        echo "discord.sh is installed"
    else
        echo "Installing discord.sh from https://github.com/ChaoticWeg"
        wget https://raw.githubusercontent.com/ChaoticWeg/discord.sh/master/discord.sh -O /usr/bin/discordnotification
        chmod u+x /usr/bin/discordnotification
fi

# install apache
echo "checking for apache"
apache_install=`dpkg -s apache2 | grep Status`;
if [[ $apache_install == S* ]]
    then
        echo "apache is installed"
    else
        echo "installing apache"
        apt-get -y install apache2
fi

# install mod_wsgi
apt-get -y install libapache2-mod-wsgi-py3

# start apache at boot
echo "making sure apache is started and configured to run at boot"
systemctl start apache2
systemctl enable apache2

# enable modules
echo "enabling mod headers and mod rewrite"
a2enmod headers
a2enmod rewrite

# install virtualhost helper script
if [ -f /usr/bin/virtualhost ];
    then
        echo "virtualhost helper script is installed"
    else
        echo "installing virtualhost helper script"
        wget https://raw.githubusercontent.com/chrisrowles/dotfiles/master/scripts/virtualhost -O /usr/bin/virtualhost
        chmod u+x /usr/bin/virtualhost
fi

# set ownership on /var/www/
echo "adding pi to www-data group and changing ownership of /var/www"
usermod -aG www-data pi
chown -R pi:www-data /var/www

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

# install git
echo "checking for git"
git_install=`dpkg -s git | grep Status`;
if [[ $git_install == S* ]]
    then
        echo "git is installed"
    else
        echo "installing git"
        apt-get -y install git
fi

# install pi-monitor-api
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
pip install testresources
pip install -r requirements.txt
cd $wd
chown -R pi:www-data /var/www/flaskapps

read -p "Please enter chosen domain for the api (defaults to http://api.raspberrypi.local): " domain
servername=${domain:="http://api.raspberrypi.local"}

# configure pi-monitor-api virtualhost
echo "configuring virtual host"
available_conf=/etc/apache2/sites-available/$servername.conf
enabled_conf=/etc/apache2/sites-enabled/$servername.conf
if [ -f $available_conf ]; then
    rm -rf $enabled_conf
    rm -rf $available_conf
fi
if ! cat << EOF > $AVAILABLECONF
<VirtualHost *:80>
    ServerName $servername
    ServerAlias www.$servername
    WSGIScriptAlias / /var/www/flaskapps/pi-monitor-api/api.wsgi
    <Directory /var/www/flaskapps/pi-monitor-api/app>
        Options FollowSymLinks MultiViews
        AllowOverride all
        Require all granted
    </Directory>
    ErrorLog /var/log/apache2/$servername-error.log
    CustomLog /var/log/apache2/$servername-access.log combined
</VirtualHost>
EOF
then
    echo "error creating virtual host."
else
    echo "success, virtual host created."
    cat << EOF >> /etc/hosts
127.0.0.1   $servername
EOF
    ln -s $available_conf $enabled_conf
    systemctl restart apache2
fi

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

# Configure discord environment variables
echo "Please configure your discord settings."
read -p "Please enter your discord user id: "  discord_user_id
read -p "Please enter your discord app token: " discord_app_token
read -p "Please enter your discord channel id for system monitoring notifications: " discord_channel_id
read -p "Please enter your discord channel webhook url for backup job notifications: "  discord_webhook

cat << EOF > /etc/backup/.env
SYSAPI_URL=$servername/
DISCORD_TOKEN=$discord_app_token
USER_ID=<@$discord_user_id>
CHANNEL_ID=$discord_channel_id

BACKUP_WEBHOOK=$discord_webhook
EOF

# install supervisord
echo "checking for supervisor"
supervisor_install=`dpkg -s supervisor | grep Status`;
if [[ $supervisor_install == S* ]]
    then
        echo "supervisor is installed."
    else
        echo "supervisor is not installed."
        echo "Installing supervisor. Please wait..."
        apt-get -y install supervisor
fi

# Configure supervisord to run as user pi
chown -R pi:pi /var/log/supervisor
cp $(pwd)/etc/supervisord/supervisord.conf /etc/supervisor/supervisord.conf

# Configure pi-monitord
echo "checking for pi-monitord"
if [ -d /home/pi/monitord ];
    then
        echo "pi-monitord is installed, leaving it alone."
    else
        echo "installing pi-monitord."
        if [ ! -d /home/pi/logs ]; then
            sudo -u pi mkdir /home/pi/logs
        fi
        # TODO create virtualenv
        pip install tabulate
        pip install python-dotenv
        sudo -u pi git clone https://github.com/chrisrowles/pi-monitord.git /home/pi/pi-monitord
        if [ -f /etc/backup/.env ]; then
            cp /etc/backup/.env /home/pi/pi-monitord/.env
            chown pi:pi /home/pi/pi-monitord/.env
        fi
        ln -s /home/pi/pi-monitord/supervisor/bot.supervisor /etc/supervisor/conf.d/
        sudo -u pi supervisord
        sudo -u pi supervisorctl status
fi

echo "Provisioning is complete."
echo "------------------------------------------"
echo "$servername"

exit 0
