#!/usr/bin/env bash

[[ "$(whoami)" != 'root' ]] &&
{
    echo "this script must be run as root."
    exit 1;
}

echo "making sure system is up-to-date"
apt-get -y update
apt-get -y upgrade

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

# get parts for installation
declare -a parts=(
    "env_config.sh"
    "python_pip_install.sh"
    "discord_install.sh"
    "apache_install.sh"
    "fail2ban_install.sh"
    "supervisor_install.sh"
    "monitor_install.sh"
    "cron_install.sh"
)

for script in "${parts[@]}"
do
    # run each part in the current shell process
    source "./parts/$script"
done

# notify script completion
echo "Provisioning is complete."
echo "------------------------------------------"
echo "http://$servername"

exit 0
