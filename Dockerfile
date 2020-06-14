## debian is an official account of docker on dockerhub, buster is the name
## of the latest version (10)

FROM debian:buster

## run execute commands
## debian DEBIAN_FRONTEND skips prompts during installation (no popups!)
## update / upgrade/ dist-upgrade assures we run the latest version of
## everything (packages and sytemp DISTribution)
## -y accepts automatically (confirmation prompt when running upgrades and such)
## nginx web server
## php is for phpmyadmin
## wget to get files from the internet
## unzip install a zipper
## lsb-release gnupg needed for mysql
## sudo is user manager
## see php doc
## procps enables pkill command

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade && apt-get -y install nginx wordpress php wget unzip lsb-release gnupg sudo php-fpm php-mysql procps

## remove and purge apache2 so nginx can take its place
RUN DEBIAN_FRONTEND=noninteractive apt-get -y remove apache2 && apt-get -y purge apache2

## download mysql from internet

RUN wget http://repo.mysql.com/mysql-apt-config_0.8.13-1_all.deb

## need to change environnement again because changes back for each command
## dpkg debian packages
## -i install
RUN DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.13-1_all.deb

## remove deb file to clean
RUN rm mysql-apt-config_0.8.13-1_all.deb

##upgrade once again to include mysql installation servers
RUN apt-get update

## install servers for mysql
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-community-client mysql-server

## create script directory to store files
RUN mkdir /script

## create database for mysql users
RUN echo "CREATE DATABASE wordpress_db;" > /script/config_mysql.sql

##set password for root, create user for wp database and grants rights
RUN echo "CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'bebechat';" >> /script/config_mysql.sql
RUN echo "GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wp_user'@'localhost';" >> /script/config_mysql.sql
RUN echo "UPDATE mysql.user SET authentication_string=null WHERE User='root';" >> /script/config_mysql.sql
RUN echo "FLUSH PRIVILEGES;" >> /script/config_mysql.sql
RUN echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'bebechat';" >> /script/config_mysql.sql

## WARNING to be done at the end of mysql configurations
## #!bin/bash is shebang which helps computer to understand that this is not a binary file and to use bin/bash to execute sc script
## create a script repository and a install.sh executable file to exec command and start processes
## pretends to be mysql user and start server in background
RUN echo "#!/bin/bash\nsudo -u mysql /usr/sbin/mysqld & > /dev/null 2>&1" > /script/install.sh && chmod +x /script/install.sh

#RUN echo "echo \"before wait\"" >> /script/install.sh

RUN echo "while ! mysqladmin ping -h localhost -u root; do\n    sleep 1\ndone\n" >> /script/install.sh

## database creation put in a script, launched as user mysql in root. Will go on when docker is run
RUN echo "mysql -u root < /script/config_mysql.sql" >> /script/install.sh

# kill server so it can be set up
RUN echo "pkill mysqld" >> /script/install.sh

RUN bash /script/install.sh

##replace the way php fmp interprets fils so that it won't run the neareast php file if the one searched isn't found. Helps with security in case someone tries to send a php script.
## WARNING, path is absolute until next php version which could change the version and thus the path name
RUN sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.3/fpm/php.ini

# start cgi manager of php for nginx so previous changes are applied
RUN echo "#!/bin/bash\n/etc/init.d/php7.3-fpm start &"> /script/run.sh

## tells nginx to take into account an index.php file for display
RUN sed -i 's/index index.html index.htm index.nginx-debian.html;/index index.php index.html index.htm index.nginx-debian.html;/g' /etc/nginx/sites-available/default

## First delete useless lines, then tells nginx to process php files through php fpm and also forbids the display of ht files (containing rights and passwords!)
RUN sed -i '53,94d' /etc/nginx/sites-available/default
RUN echo "location ~ \.php$ {include snippets/fastcgi-php.conf;fastcgi_pass unix:/run/php/php7.3-fpm.sock;}location ~ /\.ht {deny all;}}" >> /etc/nginx/sites-available/default

## first rename old index file so it's not taken into account, then create a new index.php file that will be displayed
RUN mv /var/www/html/index.nginx-debian.html /var/www/html/old-index.nginx-debian.html
RUN echo "<?php \n echo\"bonjour bebe chat \n\"; \n ?>" > /var/www/html/index.php

RUN echo "nginx &" >> /script/run.sh

RUN echo "sudo -u mysql /usr/sbin/mysqld" >> /script/run.sh && chmod +x /script/run.sh

##END: configure and download systemctl to make sure that interupted processes can be restarted automatically

## WARNING, passwords will be defined as env variables in user computer. SO need to define them before building docker!
