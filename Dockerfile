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
## systemd is task manager

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade && apt-get -y install nginx wordpress php wget unzip lsb-release gnupg sudo systemd

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
RUN echo "CREATE DATABASE wordpress_db;" > /script/init_mysql_wpdb.sql

## WARNING to be done at the end of mysql configurations
## #!bin/bash is shebang which helps computer to understand that this is not a binary file and to use bin/bash to execute sc script
## create a script repository and a run.sh executable file to exec command and start processes
## pretends to be mysql user and start server in background
RUN echo "#!/bin/bash\nsudo -u mysql /usr/sbin/mysqld &>/dev/null" > /script/run.sh && chmod +x /script/run.sh

## database creation put in a script, launched as user mysql in root. Will go on when docker is run
RUN echo "mysql -u root < /script/init_mysql_wpdb.sql" >> /script/run.sh


##END: configure and download systemctl to make sure that interupted processes can be restarted automatically

## WARNING, passwords will be defined as env variables in user computer. SO need to define them before building docker!
