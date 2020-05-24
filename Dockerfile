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

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade && apt-get -y install nginx wordpress php wget unzip lsb-release gnupg sudo

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

## WARNING to be done at the end of mysql configurations
## create a script repository and a run.sh executable file to exec command and start processes
## pretends to be mysql user and start server in background
RUN mkdir /script && echo "sudo -u mysql /usr/sbin/mysqld &" > /script/run.sh && chmod +x /script/run.sh



##END: configure and download systemctl to make sure that interupted processes can be restarted automatically
