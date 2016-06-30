#!/bin/bash
# Installer for Ebot-CSGO and Ebot-WEB by Vince52

# This script will work on Debian and Ubuntu
# This is not bullet-proof. So I'm not responsible
# of anything if you use this script.
# If you see anything, please let me know here:
# LINK OF EBOT Forum.


# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -qs "dash"; then
	echo "This script needs to be run with bash, not sh"
	exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 2
fi

if [[ ! -e /dev/net/tun ]]; then
	echo "TUN is not available"
	exit 3
fi

if [[ -e /etc/debian_version ]]; then
	OS=debian
	GROUPNAME=nogroup
	RCLOCAL='/etc/rc.local'
else
	echo "Looks like you aren't running this installer on Debian or Ubuntu"
	exit 5
fi

# Try to get our IP from the system and fallback to the Internet.
# I do this to make the script compatible with NATed servers (lowendspirit.com)
# and to avoid getting an IPv6.
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
if [[ "$IP" = "" ]]; then
		IP=$(wget -qO- ipv4.icanhazip.com)
fi

if [[ -e /home/ebot/ebot-csgo/config/config.ini ]]; then
	while :
	do
	clear
		echo "Looks like Ebot-CSGO is already on your server"
		echo ""
		echo "What do you want to do?"
		echo "   1) Start Ebot-CSGO Daemon"
		echo "   2) Stop Ebot-CSGO Daemon"
		echo "   3) Restart Ebot-CSGO daemon"
		echo "   4) Clear cache Ebot-web"		
		echo "   5) Exit"
		read -p "Select an option [1-5]: " option
		case $option in
			1) 
			echo ""
			echo "Staring Ebot-CSGO... (need to be set)"
			exit
			;;
			2)
			echo "Stoping Ebot-CSGO"
			exit
			;;
			3) 
			echo "Restarting Ebot-CSGO"
			exit
			;;
			4) 
			echo "Clearing Cache"
			exit
			;;
			5) exit;;
		esac
	done
else
	clear
	echo 'Welcome to Ebot 3.2 installer'
	echo ""
	# Some questions for users
	echo "I need to ask you a few questions before starting the setup"
	echo "You can leave the default options and just press enter if you are ok with them"
	echo ""
	echo "First I need to know the IPv4 address of the network interface you want Ebot"
	echo "listening to."
	read -p "IP address: " -e -i $IP IP
	echo ""
	echo "Install ebot on sub domain or not?"
	echo "   1) On my own Sub-domain"
	echo "   2) On my public IP"
	read -p "your choice [1-2]: " -e -i 1 SUBORIP
	echo ""
	if [[ "$SUBORIP" -eq 1 ]]; then
		echo "Finally, tell me your sub-domain you where you want to install ebot"
		echo "Please, replace your it by your domain"
		read -p "Sub-domain name: " -e -i ebot.yourdomain.com SUBDOMAIN
	fi
	echo ""
	echo "Okay, that was all I needed."
	read -n1 -r -p "Press any key to continue..."
	
	# 2) Install SERVER-REQUIREMENTS
	apt-get update
	apt-get upgrade
	apt-get install apache2 gcc make libxml2-dev autoconf ca-certificates unzip nodejs curl libcurl4-openssl-dev pkg-config libssl-dev screen -y
	
	# 3) INSTALL PHP
	
	# If PHP is already installed, removing it.
	apt-get autoremove php php-dev php-cli 
		
	# COMPILE AND INSTALL THE NEW PHP VERSION:
	mkdir /home/install
	cd /home/install
	wget http://be2.php.net/get/php-5.5.15.tar.bz2/from/this/mirror -O php-5.5.15.tar.bz2
	tar -xjvf php-5.5.15.tar.bz2
	cd php-5.5.15
	./configure --prefix /usr/local --with-mysql --enable-maintainer-zts --enable-sockets --with-openssl --with-pdo-mysql 
	make
	make install
	cd /home/install
	wget http://pecl.php.net/get/pthreads-2.0.7.tgz
	tar -xvzf pthreads-2.0.7.tgz
	cd pthreads-2.0.7
	/usr/local/bin/phpize
	./configure
	make
	make install
	echo 'date.timezone = Europe/Paris' >> /usr/local/lib/php.ini
	echo 'extension=pthreads.so' >> /usr/local/lib/php.ini
	
	# 4) INSTALL & CONFIG MYSQL SERVER (NEED TO FINISH IT)
	apt-get install mysql-server
	
	# Variables to be set: $sqlpassword
	
	# 5) INSTALL EBOT-CSGO
	mkdir /home/ebot
	cd /home/ebot
	wget https://github.com/deStrO/eBot-CSGO/archive/master.zip
	unzip master.zip
	mv eBot-CSGO-master ebot-csgo
	cd ebot-csgo
	curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
	apt-get install -y nodejs
	npm install socket.io@0.9.12 archiver formidable
	curl -sS https://getcomposer.org/installer | php
	php composer.phar install
	# Command line of my ebot guide: cp config/config.ini.smp config/config.ini
	
	# Generate config.ini (need SQL DATABASE HERE $sqlpassword)
	echo '; eBot - A bot for match management for CS:GO
; @license     http://creativecommons.org/licenses/by/3.0/ Creative Commons 3.0
; @author      Julien Pardons <julien.pardons@esport-tools.net>
; @version     3.0
; @date        21/10/2012

[BDD]
MYSQL_IP = "127.0.0.1"
MYSQL_PORT = "3306"
MYSQL_USER = "ebotv3"
MYSQL_PASS = "$sqlpassword"
MYSQL_BASE = "ebotv3"

[Config]
BOT_IP = "$IP"
BOT_PORT = 12360
MANAGE_PLAYER = 1
DELAY_BUSY_SERVER = 120
NB_MAX_MATCHS = 0
PAUSE_METHOD = "nextRound" ; nextRound or instantConfirm or instantNoConfirm

[Match]
LO3_METHOD = "restart" ; restart or csay or esl
KO3_METHOD = "restart" ; restart or csay or esl
DEMO_DOWNLOAD = true ; true or false :: whether gotv demos will be downloaded from the gameserver after matchend or not
REMIND_RECORD = false ; true will print the 3x "Remember to record your own POV demos if needed!" messages, false will not
DAMAGE_REPORT = true; true will print damage reports at end of round to players, false will not

[MAPS]
MAP[] = "de_cache"
MAP[] = "de_season"
MAP[] = "de_dust2"
MAP[] = "de_nuke"
MAP[] = "de_inferno"
MAP[] = "de_train"
MAP[] = "de_mirage"
MAP[] = "de_cbble"
MAP[] = "de_overpass"

[WORKSHOP IDs]

[Settings]
COMMAND_STOP_DISABLED = false
RECORD_METHOD = "matchstart" ; matchstart or knifestart
DELAY_READY = true' > /home/ebot/ebot-csgo/config/config.ini


	
	
	# 6) INSTALL EBOT-WEB
	
	
	cd /home/ebot
	rm -R master*
	wget https://github.com/deStrO/eBot-CSGO-Web/archive/master.zip
	unzip master.zip
	mv eBot-CSGO-Web-master ebot-web
	cd ebot-web
	# cp config/app_user.yml.default config/app_user.yml
	
	# Generate app_user.yml
	echo "# ----------------------------------------------------------------------
# white space are VERY important, don't remove it or it will not work
# ----------------------------------------------------------------------

  log_match: ../../ebot-csgo/logs/log_match
  log_match_admin: ../../ebot-csgo/logs/log_match_admin
  demo_path: ../../ebot-csgo/demos

  # true or false, whether demos will be downloaded by the ebot server
  # the demos can be downloaded at the matchpage, if it's true

  demo_download: true

  ebot_ip: $IP
  ebot_port: 12360

  # lan or net, it's to display the server IP or the GO TV IP
  # net mode display only started match on home page
  mode: lan

  # set to 0 if you don't want a refresh
  refresh_time: 30" > /home/ebot/ebot-web/config/app_user.yml
	
	# Generate database.yml (NEED DATABASE HERE $sqlpassword)
	echo "# You can find more information about this file on the symfony website:
# http://www.symfony-project.org/reference/1_4/en/07-Databases

all:
  doctrine:
    class: sfDoctrineDatabase
    param:
      dsn:      mysql:host=127.0.0.1;dbname=ebotv3
      username: ebotv3
      password: $sqlpassword" > /home/ebot/ebot-web/config/app_user.yml	
	
	cd /home/ebot
	cd ebot-web
	mkdir cache
	chown -R www-data *
	chmod -R 777 cache
	
	php symfony cc
	php symfony doctrine:build --all --no-confirmation
	
	#ASK USER USERNAME AND PASSWORD
	
	php symfony guard:create-user --is-super-admin admin@ebot admin admin
	
	# 7) CONFIG APACHE
	
	a2enmod rewrite
	
	# IF INSTALL IS FOR A SUB-DOMAIN
	if [[ "$SUBORIP" -eq 1 ]]; then
		echo "<VirtualHost *:80>
	#Edit your email
	ServerAdmin contact@mydomain.com

#Edit your sub-domain
ServerAlias $SUBDOMAIN

DocumentRoot /home/ebot/ebot-web/web

<Directory /home/ebot/ebot-web/web/>
	Options Indexes FollowSymLinks MultiViews
	AllowOverride All
	<IfVersion < 2.4>
		Order allow,deny
		allow from all
	</IfVersion>

	<IfVersion >= 2.4>
		Require all granted
	</IfVersion>
</Directory>
</VirtualHost>" > /etc/apache2/sites-available/ebotv3.conf

	a2ensite ebotv3.conf
	
	fi
	
	service apache2 reload
	
	# 8) Start/Stop ebot daemon
	
	cd /home/install
	wget https://raw.githubusercontent.com/vince52/eBot-initscript/master/ebotv3; mv ebotv3 /etc/init.d/ebot && chmod +x /etc/init.d/ebot
	service ebot start
	/etc/init.d/ebot start
	
	
	# 9) SECURITY ??? (COMING SOON)
	
	# Finished
	echo ""
	echo "Finished!"
	echo ""
	#If ebot-web is on subdomain
	echo "You can access to ebot client here: http://$SUBDOMAIN.com"
	echo ""
fi
