#!/bin/bash

# Get instance number from hostname
NUM=$(hostname | sed "s/kazak-tomcat//g")
#

echo "Hello Im tomcat$NUM"
sudo yum install -y tomcat tomcat-webapps tomcat-admin-webapps unzip wget

# Add jvmRoute string, deploy users and clusterjsp for a single tomcat server instance
cd /vagrant
sed "s/routestringforSED/tomcat$NUM/g" tomcat_server.xml > server.xml
sudo cp server.xml /usr/share/tomcat/conf/
sudo cp tomcat-users.xml /usr/share/tomcat/conf/tomcat-users.xml
sudo cp clusterjsp.war /usr/share/tomcat/webapps/
#

rm server.xml

sudo systemctl restart tomcat

echo "GO AVAHI"

sudo yum install -y avahi
sudo systemctl start avahi-daemon
sudo systemctl enable avahi-daemon

echo "GO SERF"

cd /tmp
wget https://releases.hashicorp.com/serf/0.8.2/serf_0.8.2_linux_amd64.zip
unzip serf_0.8.2_linux_amd64.zip
sudo mv -f serf /usr/sbin/
sudo rm serf_0.8.2_linux_amd64.zip

cd /vagrant
sudo chmod +x handler.sh
