# Pi Monitor Provisioning

## Introduction

This repository provides automatic installation and configuration of the following software in order to provision a new Raspberry Pi OS/Raspbian install with system monitoring, backup jobs, and discord bot integration:


- Python3
- Pip3
- Apache
- Git
- Fail2Ban
- Supervisor
- [discord.py](https://pypi.org/project/discord.py/): A python wrapper for discord, built by [rapptz](https://pypi.org/user/rapptz/).
- [discord.sh](https://github.com/ChaoticWeg/discord.sh): A cli utility for discord webhooks, built by [ChaoticWeg](https://github.com/ChaoticWeg).
- [pi-monitor-api](https://github.com/chrisrowles/pi-monitor-api): A system-monitoring api built by [yours truly](https://github.com/chrisrowles).
- [pi-monitord](https://github.com/chrisrowles/pi-monitord): Discord integration for the api (also built by [yours truly](https://github.com/chrisrowles)).

Check out the monitoring api [here](https://github.com/chrisrowles/pi-monitor-api).

Check out the discord integration [here](https://github.com/chrisrowles/pi-monitord).

You can also a get a web client for the monitoring api [here](https://github.com/chrisrowles/pi-monitor). It is not included in this provisioning tool, however please feel free to use and modify it as much as you like!

## Installation

1. Download the repository to your pi, or clone it if you already have git installed.

    ```sh
    git clone https://github.com/chrisrowles/pi-provision.git
    ```
2. Change your current working directory to the repository.

    ```sh
    cd pi-provision
    ```
3. Run the provisioning script with sudo.

    ```sh
    sudo bash provision.sh
    ```
4. At some point, the script will ask you to set the following environment variables:
    - `DISCORD_TOKEN`: your bot token. Create a new app at https://discord.com/developers/applications
    - `USER_ID`: Your discord user id.
    - `CHANNEL_ID`: Your main channel id.
    - `BACKUP_WEBHOOK`: Whichever channel you decide to use for backup cron job notifications, you'll need to make sure you create a webhook that the backup script can call during its stages, assign the webhook url to this variable.

5. After setting your environment variables, the script will continue on to completion.


# Todo

- Allow users to set required environment variables as part the install process rather than just informing them that they need to add them after the install has completed.

- Give users a choice where to install `pi-monitord`, by default it's installed to the `pi` user's home directory - `/home/pi/pi-monitord`, in addition to updates to the provisioning script this will also require updates to `pi-monitord`'s `bot.supervisor`, to reference the correct package location.

- Make it more customisable (decide what to offer, what to include by default etc).
