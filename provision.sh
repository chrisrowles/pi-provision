#!/usr/bin/env bash

[[ "$(whoami)" != 'root' ]] &&
{
    echo "this script must be run as root."
    exit 1;
}


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


# configure apache and virtualhost helper script
APACHEINSTALL=`dpkg -s apache2 | grep Status`;
if [[ $APACHEINSTALL == S* ]]
    then
        echo "apache is installed"
    else
        echo "installing apache"
        apt-get -y install apache2 libapache2-mod-wsgi-py3
fi
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
WD=$(pwd)
cd /var/www/pi-monitor-api
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

# notify of completion and perform final checks
echo "provisioning process completed, performing final checks."
if [ ! -d /home/pi/pi-monitord ]; then
    echo "please note, monitor bot and utilities may not be installed."
    echo "more info: https://github.com/chrisrowles/pi-monitor-bot"
fi

exit 0
