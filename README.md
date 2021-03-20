# Pi Monitor Provisioning

This repository provides automatic installation and configuration of the following software:

- Python3
- Pip3
- Apache
- Git
- Fail2Ban
- Supervisor

And following packages:

- [discord.py](https://pypi.org/project/discord.py/): A python wrapper for discord, built by [rapptz](https://pypi.org/user/rapptz/).
- [discord.sh](https://github.com/ChaoticWeg/discord.sh): A cli utility for discord webhooks, built by [ChaoticWeg](https://github.com/ChaoticWeg).
- [pi-monitor-api](https://github.com/chrisrowles/pi-monitor-api): A system-monitoring api built by [yours truly](https://github.com/chrisrowles).
- [pi-monitord](https://github.com/chrisrowles/pi-monitord): Discord integration for the api (also built by [yours truly](https://github.com/chrisrowles)).

In order to provision a brand new Raspberry Pi OS/Raspbian install with a system monitoring suite, complete with discord bot integration.

Check out the monitoring api [here](https://github.com/chrisrowles/pi-monitor-api).

Check out the discord integration [here](https://github.com/chrisrowles/pi-monitord).

You can also a web client for the monitoring api [here](https://github.com/chrisrowles/pi-monitor). It is not included in this provisioning tool, however please feel free to use and modify it as much as you like!

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
4. Go and make a cup of tea, coffee or hot chocolate, whichever you prefer
5. In about ten minutes or so, the script will complete and your monitoring api will be online
6. Change directory to `/home/pi/pi-monitord` and copy `.env.example` to `.env`
    ```sh
    cd /home/pi/pi-monitord
    cp .env.example .env
    ```
7. Populate your environment variables for your discord bot and channel webhook URLs
8. Copy `.env` to `/home/pi/.env`
9. ???
10. Profit :D

## How it Works

1. The script starts by updating any software packages.
2. Checks to see if python is mapped to python3, if not, `update-alternatives` is invoked to set the default to python3.
3. The same process is repeated with pip3.
4. [discord.sh](https://github.com/ChaoticWeg/discord.sh) is installed to `/usr/bin/discordnotification`.
5. Checks to see if apache is installed, if not then it is installed.
6. `libapache2-mod-wsgi-py3` is installed.
7. A [virtualhost helper script](https://github.com/chrisrowles/dotfiles/blob/master/scripts/virtualhost) is installed to `/usr/bin/virtualhost`.
8. User `pi` is added to group `www-data`.
9. Ownership on `/var/www` is changed to `pi:www-data` (so we can clone directly to the web directory).
10. Checks to see if fail2ban is installed, if not then it is installed.
    - `/etc/fail2ban/action.d/discord_notifications` is copied to `/etc/fail2ban/action.d/`, this is the action to trigger a discord webhook on fail2ban events.
    - `/etc/fail2ban/jail.local` is copied to `/etc/fail2ban`, this contains configuration settings for the `sshd` jail.
11. Checks to see if git is installed, if not then it is installed.
12. [pi-monitor-api](https://github.com/chrisrowles/pi-monitor-api) is cloned to `/var/www`, dependencies installed*, and virtualhost configured.
13. Backup scripts are configured as cron jobs.
    - `/etc/cron/backup-image.sh` is copied to `/etc/cron.monthly`, this script creates an identical copy of the entire disk using dd.
    - `/etc/cron/backup-incremental.sh` is copied to `/etc/cron.monthly`, this script creates an incremental backup using rsync.
14. Checks to see if supervisor is installed, if not then it is installed (using apt-get, not pip).
15. Ownership on `/var/log/supervisor` is changed to `pi:pi`.
16. [pi-monitord](https://github.com/chrisrowles/pi-monitord) is installed to `/home/pi/pi-monitord`.
17. `/home/pi/pi-monitord/supervisor/bot.supervisor` is linked to `/etc/supervisor/conf.d/`.
18. supervisor is restarted, provisioning is complete!
