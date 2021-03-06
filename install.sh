#!/bin/bash

## setting color values
NC='\033[0m'
RED='\033[0;31m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

## Gathering info
CPU=$(lscpu | grep -i "model name" | cut -d: -f2 | sed 's/ //g')
MEM=$(lsmem | grep -i "total online memory" | awk '{print $4}')
IP=$(ifconfig | grep inet | awk '{print $2; exit}' | sed 's/addr://g')
HOST=$(hostname)

## checking service status
APACHE=$(service apache2 status | grep active | awk '{print $2}')
MYSQL=$(service mysql status | grep active | awk '{print $2}')
PHPFILE="/var/www/html/info.php"

clear; echo -e "${PURPLE}LAMP & WordPress Installer Script Created by Armin.G 2018\n***** NOTE: This script needs to run under root permission *****${NC}\n\n"
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
        sudo apt-get update >/dev/null #&& sudo apt-get dist-upgrade -y >/dev/null && sudo apt-get autoremove -y >/dev/null
        echo -e "${NC}"
        if [ "$apacheinstalled" -eq 0 ]
            then
                echo -e "${YELLOW}Installing Apache..."
                sudo apt-get install -y apache2 >/dev/null
                sudo systemctl enable apache2 >/dev/null 2>&1
                echo -e "Installed\n${NC}"
                apacheinstalled=1

        fi
        if [ "$mysqlinstalled" -eq 0 ]
            then
                echo -e "${YELLOW}Installing MySQL Server..."
                sudo DEBIAN_FRONTEND=noninteractive apt-get install -q -y mysql-server mysql-client >/dev/null
                read -p "Enter new root password:" rootpassword1
				read -p "Enter root password again:" rootpassword2
				if [ "$rootpassword1" == "$rootpassword2" ]
					then
                		sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password "$rootpassword1"'
                		sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password "$rootpassword1"'
                	else
                		echo -e "${YELLOW}Passwords do not match"
                		echo -e "${YELLOW}Execute the script again"
                		break
                fi
                echo -e "Installed\n${NC}"
                mysqlinstalled=1
        fi
        if [ "$apacheinstalled" -eq 1 ] || [ "$mysqlinstalled" -eq 1 ]
            then
                echo -e "${YELLOW}Installing PHP..."
                sudo apt-get install -y php libapache2-mod-php php-mysql >/dev/null
                sudo service apache2 restart 
                sudo echo "<?php" > $PHPFILE
                sudo echo "phpinfo();" >> $PHPFILE
                sudo echo "?>" >> $PHPFILE
                echo -e "Installed\n${NC}"
                echo -e "${NC}\n\nYou should be able to browse into ${GREEN}http://$IP/info.php ${NC}now.\n"

## Installing Wordpress				
		read -p "Do you wish to add WordPress (y/n)?" wordpressinstall
			if echo "$wordpressinstall" | grep -iq "^y";
        	then
    			echo -e "${YELLOW}Installing WordPress..."
    	   		wget https://wordpress.org/latest.tar.gz >/dev/null 2>&1
       			tar -xzvf latest.tar.gz >/dev/null
       			sudo rsync -av wordpress/* /var/www/html/ >/dev/null
       			sudo chown -R www-data:www-data /var/www/html/
       			sudo chmod -R 755 /var/www/html/
       			sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
		        read -p "set WordPress DB password:" wppassword1
        		read -p "Re-Type the password:" wppassword2
        		if [ "$wppassword1" == "$wppassword2" ]
        			then
        				#echo -e "${RED}MySQL Root Password?"
        				mysql -u root -e "CREATE DATABASE IF NOT EXISTS mywp_site;GRANT ALL PRIVILEGES ON mywp_site.* TO 'wpsite_admin'@'localhost' IDENTIFIED BY '$wppassword1';FLUSH PRIVILEGES;"
        			else
        				echo -e "${RED}Passwords doesn't match\nRe-run the script"
        		fi
        		sudo sed -i "s/database_name_here/mywp_site/g;s/username_here/wpsite_admin/g;s/password_here/$wppassword1/g" /var/www/html/wp-config.php
			   	sudo rm /var/www/html/index.html >/dev/null 2>&1	
      			echo -e "${NC}\n\nYou should be able to browse into ${GREEN}http://$IP/ ${NC}now.\n"
    		fi
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

## Installing Wordpress if Apache and MySQL already installed
read -p "Do you wish to add WordPress (y/n)?" wordpressinstall
	if echo "$wordpressinstall" | grep -iq "^y";
        then
    		echo -e "${YELLOW}Installing WordPress..."
    		wget https://wordpress.org/latest.tar.gz >/dev/null 2>&1
       		tar -xzvf latest.tar.gz >/dev/null
       		sudo rsync -av wordpress/* /var/www/html/ >/dev/null
       		sudo chown -R www-data:www-data /var/www/html/
       		sudo chmod -R 755 /var/www/html/
       		sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
			read -p "set WordPress DB password:" wppassword1
        	read -p "Re-Type the password:" wppassword2
        if [ "$wppassword1" == "$wppassword2" ]
        	then
        		#echo -e "${RED}MySQL Root Password?"
        		mysql -u root -e "CREATE DATABASE IF NOT EXISTS mywp_site;GRANT ALL PRIVILEGES ON mywp_site.* TO 'wpsite_admin'@'localhost' IDENTIFIED BY '$wppassword1';FLUSH PRIVILEGES;"
        	else
        		echo -e "${RED}Passwords doesn't match\nRe-run the script"
        fi
        sudo sed -i "s/database_name_here/mywp_site/g;s/username_here/wpsite_admin/g;s/password_here/$wppassword1/g" /var/www/html/wp-config.php
		sudo rm /var/www/html/index.html >/dev/null 2>&1
    	echo -e "${NC}\n\nYou should be able to browse into ${GREEN}http://$IP/ ${NC}now.\n"
    fi
fi
