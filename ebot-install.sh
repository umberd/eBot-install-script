#!/bin/bash
# Installer for Ebot-CSGO and Ebot-WEB by Vince52

# This script will work on Debian and Ubuntu
# This is not bullet-proof. So I'm not responsible
# of anything if you use this script.
# If you see anything wrong, please let me know here:
# http://forum.esport-tools.net/d/94-ebot-auto-install-script


# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -qs "dash"; then
	echo "This script needs to be run with bash, not sh"
	exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 2
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
# CHECK NAT
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
if [[ "$IP" = "" ]]; then
		echo '1'
		IP=$(wget -qO- api.ipify.org)
fi

if [[ -e /home/ebot/ebot-csgo/config/config.ini ]]; then
	while :
	do
	
		echo "Looks like Ebot-CSGO is already on your server"
		echo ""
		echo "What do you want to do?"
		echo "   1) Start Ebot-CSGO Daemon"
		echo "   2) Stop Ebot-CSGO Daemon"
		echo "   3) Restart Ebot-CSGO daemon"
		echo "   4) Clear cache Ebot-web"	
		echo "   5) Secure mysql"
		echo "   6) Delete EBOT (coming soon)"
		echo "   7) Update Ebot (coming soon)"		
		echo "   8) Exit"
		read -p "Select an option [1-5]: " option
		case $option in
			1) 
			echo ""
			echo "Staring Ebot-CSGO... (need to be set)"
			service ebot start
			exit
			;;
			2)
			echo "Stoping Ebot-CSGO"
			service ebot stop
			exit
			;;
			3) 
			echo "Restarting Ebot-CSGO"
			service ebot restart
			exit
			;;
			4) 
			echo "Clearing Cache"
			service ebot clear-cache
			exit
			;;
			5) 
			echo "Securing mysql"
			mysql_secure_installation
			exit
			;;
			6) 
			echo "(coming soon)"
			exit
			;;
			7) 
			echo "(coming soon)"
			exit
			;;
			8) exit;;
		esac
	done
else
	clear
	echo 'Welcome to Ebot 3.2 installer by vince52'
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
	echo "Okay, I will ask you other questions later."
	read -n1 -r -p "Press any key to continue..."
	
	# 2) Install SERVER-REQUIREMENTS
	apt-get update
	apt-get install apache2 gcc make libxml2-dev autoconf ca-certificates unzip nodejs curl libcurl4-openssl-dev pkg-config libssl-dev screen -y
	if [ $? != 0 ]; then
		echo "(LINE 126) There is an error. Are you running apt application somewhere?"
		echo "Can you check your debian source list?"
		echo "ABORT"
		exit
	fi
	# 3) INSTALL PHP
	
	# If PHP is already installed, removing it.
	apt-get autoremove php5 php5-dev php5-cli php php-dev php-cli -y
	#if [ $? != 0 ]; then
	#	echo "(LINE 126) There is an error. Are you running apt application somewhere?"
	#	echo "Can you check your debian source list?"
	#	echo "ABORT"
	#	exit
	#fi
		
	# COMPILE AND INSTALL THE NEW PHP VERSION:
	mkdir /home/install
	cd /home/install
	wget http://be2.php.net/get/php-5.6.27.tar.bz2/from/this/mirror -O php-5.6.27.tar.bz2
	tar -xjvf php-5.6.27.tar.bz2
	cd php-5.6.27
	./configure --prefix /usr/local --with-mysql --enable-maintainer-zts --enable-sockets --with-openssl --with-pdo-mysql 
	make
	make install
	cd /home/install
	wget http://pecl.php.net/get/pthreads-2.0.10.tgz
	tar -xvzf pthreads-2.0.10.tgz
	cd pthreads-2.0.10
	/usr/local/bin/phpize
	./configure
	make
	make install
	echo 'date.timezone = Europe/Paris' >> /usr/local/lib/php.ini
	echo 'extension=pthreads.so' >> /usr/local/lib/php.ini
	
	apt-get install libapache2-mod-php5 -y
	if [ $? != 0 ]; then
		echo "(LINE 162) There is an error. Are you running apt application somewhere?"
		echo "Can you check your debian source list?"
		echo "ABORT"
		exit
	fi
	
	# 4) INSTALL & CONFIG MYSQL SERVER (NEED TO FINISH IT)
	
	if [[ ! -e /etc/mysql/conf.d ]]; then
		echo "Okay, Mysql is not installed."
		echo "This script will install it for you"
		echo "You will need to set a MYSQL's root password"
		echo ""
		echo "Here is an example of a good and random password:"
		rootpasswd=$(openssl rand -base64 12)
		echo $rootpasswd
		echo "DON'T FORGET TO REMEMBER IT IF IT IS DIFFERENT THAN THIS ONE"
		echo "YOU WILL NEED IT AFTER FOR EBOT!!!"
		read -n1 -r -p "Press any key to continue..."
		
		apt-get install mysql-server -y
		if [ $? != 0 ]; then
			echo "(LINE 183) There is an error. Are you running the APT application somewhere?"
			echo "Can you check your debian source list?"
			echo "ABORT"
			exit
		fi
		
	fi
	
	# create random password
	SQLPASSWORDEBOTV3="$(openssl rand -base64 12)"

	# If /root/.my.cnf exists then it won't ask for root password
	if [ -f /root/.my.cnf ]; then

		mysql -e "CREATE DATABASE ebotv3;"
		mysql -e "CREATE USER ebotv3@localhost IDENTIFIED BY '$SQLPASSWORDEBOTV3';"
		mysql -e "GRANT ALL PRIVILEGES ON ebotv3.* TO 'ebotv3'@'localhost';"
		mysql -e "FLUSH PRIVILEGES;"

	# If /root/.my.cnf doesn't exist then it'll ask for root password   
	else
		echo "Please enter root user MySQL password!"
		read -p "YOUR SQL ROOT PASSWORD: " -e -i $rootpasswd rootpasswd
		until mysql -u root -p$mysqlRootPassword  -e ";" ; do
			read -p "Can't connect, please retry: " -e -i $rootpasswd rootpasswd
		done
		mysql -u root -p$rootpasswd -e "CREATE DATABASE ebotv3;"
		mysql -u root -p$rootpasswd -e "CREATE USER ebotv3@localhost IDENTIFIED BY '$SQLPASSWORDEBOTV3';"
		mysql -u root -p$rootpasswd -e "GRANT ALL PRIVILEGES ON ebotv3.* TO 'ebotv3'@'localhost';"
		mysql -u root -p$rootpasswd -e "FLUSH PRIVILEGES;"
	fi
	
	apt-get install php5-mysql -y
	if [ $? != 0 ]; then
		echo "(LINE 213) There is an error. Are you running apt application somewhere?"
		echo "Can you check your debian source list?"
		echo "ABORT"
		exit
	fi
	
	# Variables to be set: $SQLPASSWORDEBOTV3
	
	# 5) INSTALL EBOT-CSGO
	
	mkdir /home/ebot
	cd /home/ebot
	wget https://github.com/deStrO/eBot-CSGO/archive/master.zip
	unzip master.zip
	mv eBot-CSGO-master ebot-csgo
	cd ebot-csgo
	curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
	
	apt-get install -y nodejs
	if [ $? != 0 ]; then
		echo "(LINE 232) There is an error. Are you running apt application somewhere?"
		echo "Can you check your debian source list?"
		echo "ABORT"
		exit
	fi
	
	npm install socket.io@0.9.12 archiver formidable
	curl -sS https://getcomposer.org/installer | php
	php composer.phar install
	# Command line of my ebot guide: cp config/config.ini.smp config/config.ini
	
	EXTERNALIP=$(wget -qO- ipv4.icanhazip.com)
	EXTIP=""
	if [[ "$IP" != "$EXTERNALIP" ]]; then
		echo ""
		echo "Looks like your server is behind a NAT!"
		echo ""
		echo "If your server is NATed (e.g. LowEndSpirit), I need to know the external IP"
		echo "If that's not the case, just ignore this and leave the next field blank"
		read -p "External IP: " -e USEREXTERNALIP
		if [[ "$USEREXTERNALIP" != "" ]]; then
			EXTIP=$USEREXTERNALIP
		fi
	fi
	
	
	# Generate config.ini (need SQL DATABASE HERE $SQLPASSWORDEBOTV3)
	echo '; eBot - A bot for match management for CS:GO
; @license     http://creativecommons.org/licenses/by/3.0/ Creative Commons 3.0
; @author      Julien Pardons <julien.pardons@esport-tools.net>
; @version     3.0
; @date        21/10/2012
[BDD]
MYSQL_IP = "127.0.0.1"
MYSQL_PORT = "3306"
MYSQL_USER = "ebotv3"
MYSQL_PASS = "'$SQLPASSWORDEBOTV3'"
MYSQL_BASE = "ebotv3"
[Config]
BOT_IP = "'$IP'"
BOT_PORT = 12360
EXTERNAL_LOG_IP = "'$EXTIP'" ; use this in case your server isnt binded with the external IP (behind a NAT)
MANAGE_PLAYER = 1
DELAY_BUSY_SERVER = 120
NB_MAX_MATCHS = 0
PAUSE_METHOD = "nextRound" ; nextRound or instantConfirm or instantNoConfirm
NODE_STARTUP_METHOD = "node" ; binary file name or none in case you are starting it with forever or manually
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

  default_max_round: 15
  default_rules: rules
  default_overtime_max_round: 3
  default_overtime_startmoney: 16000

  # true or false, whether demos will be downloaded by the ebot server
  # the demos can be downloaded at the matchpage, if it's true

  demo_download: true
  ebot_ip: "$IP"
  ebot_port: 12360

  # lan or net, it's to display the server IP or the GO TV IP
  # net mode display only started match on home page
  mode: net

  # set to 0 if you don't want a refresh
  refresh_time: 30

  # Toornament Configuration
  toornament_id:
  toornament_secret:
  toornament_api_key:
  toornament_plugin_key: test-123457890" > /home/ebot/ebot-web/config/app_user.yml
	
	# Generate databases.yml
	rm /home/ebot/ebot-web/config/databases.yml
	echo "# You can find more information about this file on the symfony website:
# http://www.symfony-project.org/reference/1_4/en/07-Databases
all:
  doctrine:
    class: sfDoctrineDatabase
    param:
      dsn:      mysql:host=127.0.0.1;dbname=ebotv3
      username: ebotv3
      password: $SQLPASSWORDEBOTV3" > /home/ebot/ebot-web/config/databases.yml	
	
	cd /home/ebot
	cd ebot-web
	mkdir cache
	chown -R www-data *
	chmod -R 777 cache
	
	php symfony cc
	php symfony doctrine:build --all --no-confirmation
	
	#ASK USER USERNAME AND PASSWORD
	echo "THE LAST QUESTION: I need a username and a password for ebot"
	read -p "Username: " -e -i admin EBOTUSER
	read -p "Username: " -e -i password EBOTPASSWORD
	php symfony guard:create-user --is-super-admin admin@ebot $EBOTUSER $EBOTPASSWORD
	
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
		
	else
		echo "Alias / /home/ebot/ebot-web/web/
<Directory /home/ebot/ebot-web/web/>
	AllowOverride All
	<IfVersion < 2.4>
		Order allow,deny
		allow from all
	</IfVersion>
	<IfVersion >= 2.4>
		Require all granted
	</IfVersion>
</Directory>" > /etc/apache2/sites-available/ebotv3.conf

		echo "Options +FollowSymLinks +ExecCGI
<IfModule mod_rewrite.c>
  RewriteEngine On
  # uncomment the following line, if you are having trouble
  # getting no_script_name to work
  RewriteBase /
  # we skip all files with .something
  #RewriteCond %{REQUEST_URI} \..+$
  #RewriteCond %{REQUEST_URI} !\.html$
  #RewriteRule .* - [L]
  # we check if the .html version is here (caching)
  RewriteRule ^$ index.html [QSA]
  RewriteRule ^([^.]+)$ $1.html [QSA]
  RewriteCond %{REQUEST_FILENAME} !-f
  # no, so we redirect to our front web controller
  RewriteRule ^(.*)$ index.php [QSA,L]
</IfModule>" > /home/ebot/ebot-web/web/.htaccess

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
	if [[ "$SUBORIP" -eq 1 ]]; then
		echo "You can access to eBot-WEB interface here: http://$SUBDOMAIN"
	else
		echo "You can access to ebot client here: http://$IP"
	fi
	echo "Username: $EBOTUSER"
	echo "Password: $EBOTPASSWORD"
	echo ""
fi
