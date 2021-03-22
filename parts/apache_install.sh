#!/usr/bin/env bash

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