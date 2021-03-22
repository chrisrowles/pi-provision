#!/usr/bin/env bash

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
wd=$(pwd)
cd /var/www/flaskapps/pi-monitor-api
pip install testresources
pip install -r requirements.txt
cd $wd
chown -R pi:www-data /var/www/flaskapps

# configure pi-monitor-api virtualhost
echo "configuring virtual host"
available_conf=/etc/apache2/sites-available/$servername.conf
enabled_conf=/etc/apache2/sites-enabled/$servername.conf
if [ -f $available_conf ]; then
    rm -rf $enabled_conf
    rm -rf $available_conf
fi
if ! cat << EOF > $available_conf
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
