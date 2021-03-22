#!/usr/bin/env/bash

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