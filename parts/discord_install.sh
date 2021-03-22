#!/usr/bin/env bash

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

