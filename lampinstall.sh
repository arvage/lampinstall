#!/bin/bash


## setting color values
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

## getting IP and hostname
IP=$(ifconfig | grep inet | awk '{print $2; exit}')
HOST=$(hostname)

## checking service status
APACHE=$(service apache2 status | grep active | awk '{print $2}')
MYSQL=$(service mysql status | grep active | awk '{print $2}')
PHPFILE="/var/www/html/info.php"

clear; echo -e "${PURPLE}LAMP Installer Script Created by Armin.G 2018\n***** NOTE: This script needs to run under root permission *****${NC}\n\n"
echo -e "System Info:"
echo -e "${GREEN}Machine IP: $IP"
echo -e "Hostname: $HOST ${NC}\n"
echo -e "Checking required services:"
if [ "$APACHE" == "active" ]
then
echo -e "${GREEN}Apache installed and running"
apacheinstalled=1
else
echo -e "${RED}Apache not installed or running"
apacheinstalled=0
fi

if [ "$MYSQL" == "active" ]
then
echo -e "${GREEN}MySQL installed and running"
mysqlinstalled=1
else
echo -e "${RED}MySQL not installed or running"
mysqlinstalled=0
fi
echo -e "${NC}"

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
        echo -e "${YELLOW}checking for updates"
        sudo apt-get update && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y >/dev/null
        if [ "$apacheinstalled" -eq 0 ]
            then
                echo -e "${BLUE}Installing Apache"
                sudo apt-get install -y apache2 >/dev/null
                echo -e "${NC}"
                apacheinstalled=1

        fi
        if [ "$mysqlinstalled" -eq 0 ]
            then
                echo -e "${CYAN}"
                sudo apt-get install -y mysql-server mysql-client
                echo -e "${NC}"
                mysqlinstalled=1
        fi
        if [ "$apacheinstalled" -eq 1 ] || [ "$mysqlinstalled" -eq 1 ]
            then
                sudo apt-get install -y php libapache2-mod-php php-mysql
                sudo service apache2 restart
                sudo echo "<?php" > $PHPFILE
                sudo echo "phpinfo();" >> $PHPFILE
                sudo echo "?>" >> $PHPFILE
                echo -e "\n\nYou should be able to browse into ${GREEN}http://$IP/info.php ${NC}now.\n"
        fi
    fi
else
clear
echo -e "\n${GREEN}All required applications/services are installed and running\n\n${NC}"
fi
