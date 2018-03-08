#!/bin/bash

## setting color values
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

## Gathering info
CPU=$(lscpu | grep -i "model name" | cut -d: -f2 | sed 's/ //g')
MEM=$(lsmem | grep -i "total online memory" | awk '{print $4}')
IP=$(ifconfig | grep inet | awk '{print $2; exit}')
HOST=$(hostname)

## checking service status
APACHE=$(service apache2 status | grep active | awk '{print $2}')
MYSQL=$(service mysql status | grep active | awk '{print $2}')
PHPFILE="/var/www/html/info.php"

clear; echo -e "${PURPLE}LAMP Installer Script Created by Armin.G 2018\n***** NOTE: This script needs to run under root permission *****${NC}\n\n"
echo -e "System Info:"
echo -e "${GREEN}CPU: $CPU"
echo -e "Memory: $MEM"
echo -e "Machine IP: $IP"
echo -e "Hostname: $HOST ${NC}\n"
echo -e "Checking required services:"

## Display Apache status
if [ "$APACHE" == "active" ]
then
echo -e "${GREEN}Apache installed and running"
apacheinstalled=1
else
echo -e "${RED}Apache not installed or running"
apacheinstalled=0
fi

## Display MySQL status
if [ "$MYSQL" == "active" ]
then
echo -e "${GREEN}MySQL installed and running"
mysqlinstalled=1
else
echo -e "${RED}MySQL not installed or running"
mysqlinstalled=0
fi
echo -e "${NC}"

## Function for on-screen prompt
promptyn () {
while true; do
    read -p "$1" yn
    case $yn in
        [Yy]* ) return 1;;
        [Nn]* ) return 0;;
        * ) echo "Please answer yes or no.";;
    esac
done
}

if [ "$apacheinstalled" -eq 0 ] || [ "$mysqlinstalled" -eq 0 ]
then
    if promptyn "Install missing applications/service? (y/n)";
    then
    echo -e "${YELLOW}\n\nExited without any changes${NC}"
    else
        echo -e "${YELLOW}\nChecking and applying updates..."
        sudo apt-get update >/dev/null && sudo apt-get dist-upgrade -y >/dev/null && sudo apt-get autoremove -y >/dev/null
        echo -e "${NC}"
        if [ "$apacheinstalled" -eq 0 ]
            then
                echo -e "${YELLOW}Installing Apache"
                sudo apt-get install -y apache2 >/dev/null
                sudo systemctl enable apache2
                echo -e "${NC}"
                apacheinstalled=1

        fi
        if [ "$mysqlinstalled" -eq 0 ]
            then
                echo -e "${YELLOW}Installing MySQL Server"
                sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password Abcd@1234'
                sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password Abcd@1234'
                sudo apt-get install -y mysql-server mysql-client >/dev/null
                echo -e "${NC}"
                mysqlinstalled=1
        fi
        if [ "$apacheinstalled" -eq 1 ] || [ "$mysqlinstalled" -eq 1 ]
            then
                echo -e "${YELLOW}Installing PHP"
                sudo apt-get install -y php libapache2-mod-php php-mysql >/dev/null
                sudo service apache2 restart
                sudo echo "<?php" > $PHPFILE
                sudo echo "phpinfo();" >> $PHPFILE
                sudo echo "?>" >> $PHPFILE
                echo -e "${NC}\n\nYou should be able to browse into ${GREEN}http://$IP/info.php ${NC}now.\n"
                while true; do
    				read -p "Do you wish to add WordPress?" yesno
    				case $yesno in
        				[Yy]* ) wordpressinstall=1;;
        				[Nn]* ) wordpressinstall=0;;
        				* ) echo "Please answer yes or no.";;
    				esac
				done
        fi
        if [ "$wordpressinstall" -eq 1]
        	then
        	wget https://wordpress.org/latest.tar.gz
        	tar -xzvf latest.tar.gz
        	sudo rsync -av wordpress/* /var/www/html/
        	sudo chown -R www-data:www-data /var/www/html/
        	sudo chmod -R 755 /var/www/html/
        	sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
        	sudo sed 's/database_name_here/wordpress/g'  /var/www/html/wp-config.php
			sudo sed 's/username_here/root/g'  /var/www/html/wp-config.php
			sudo sed 's/password_here/Abcd@1234/g'  /var/www/html/wp-config.php
        fi
    fi
else
clear; echo -e "${PURPLE}LAMP Installer Script Created by Armin.G 2018\n***** NOTE: This script needs to run under root permission *****${NC}\n\n"
echo -e "System Info:"
echo -e "${GREEN}CPU: $CPU"
echo -e "Memory: $MEM"
echo -e "Machine IP: $IP"
echo -e "Hostname: $HOST ${NC}\n"
echo -e "\n${GREEN}All required applications/services are installed and running\n\n${NC}"
echo -n "Do you wish to add WordPress (y/n)?" 
read wordpressinstall
if echo "$wordpressinstall" | grep -iq "^y";
        	then
        	wget https://wordpress.org/latest.tar.gz
        	tar -xzvf latest.tar.gz
        	sudo rsync -av wordpress/* /var/www/html/
        	sudo chown -R www-data:www-data /var/www/html/
        	sudo chmod -R 755 /var/www/html/
        	sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
        	sudo sed 's/database_name_here/wordpress/g'  /var/www/html/wp-config.php
			sudo sed 's/username_here/root/g'  /var/www/html/wp-config.php
			sudo sed 's/password_here/Abcd@1234/g'  /var/www/html/wp-config.php
        fi
fi
