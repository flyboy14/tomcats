#!/bin/bash

SAMPLEIP="192.168.56."

sudo yum -y install httpd httpd-devel autoconf libtool sed wget net-tools unzip

# Build ks.so module

cd /opt 
sudo wget http://ftp.byfly.by/pub/apache.org/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.46-src.tar.gz 
sudo tar xvzf tomcat-connectors-1.2.46-src.tar.gz

cd tomcat-connectors-1.2.46-src/native 
sudo ./configure --with-apxs="$(which apxs)"
sudo make
sudo cp apache-2.0/mod_jk.so /etc/httpd/modules/
sudo bash -c 'echo "LoadModule jk_module modules/mod_jk.so" >> /etc/httpd/conf/httpd.conf'

cd /vagrant
#
# Fill in worker.properties and vhosts config file for httpd 

cp vhosts.conf httpd-vhosts.conf
echo '' > workers.properties

WORKERLIST="tomcat-cluster"
NODESLIST=""
declare -i NUM
NUM=$1

while [[ $NUM -gt 0 ]];
do
	if [[ $NUM == $1 ]]; then
		NODESLIST="tomcat$NUM"
	else
    	NODESLIST="$NODESLIST,tomcat$NUM"
    fi
    echo "worker.tomcat$NUM.type=ajp13" >> workers.properties
    echo "worker.tomcat$NUM.host=tomcat$NUM" >> workers.properties
    echo "worker.tomcat$NUM.port=8009" >> workers.properties
    echo -e "worker.tomcat$NUM.lbfactor=1\n" >> workers.properties

    NUM=$(($NUM-1))
done

WORKERLIST="$NODESLIST,$WORKERLIST"
echo -e "\nworker.list=$WORKERLIST\n" >> workers.properties
echo "worker.tomcat-cluster.sticky_session=false" >> workers.properties
echo "worker.tomcat-cluster.type=lb" >> workers.properties
echo "worker.tomcat-cluster.balanced_workers=$NODESLIST" >> workers.properties

sudo mv workers.properties /etc/httpd/conf/

NUM=$1
while [[ $NUM -gt 0 ]];
do
	echo -e '\n<VirtualHost *:80>' >> httpd-vhosts.conf
	echo "  ServerName tomcat$NUM.lab" >> httpd-vhosts.conf
	echo "  JkMount / tomcat$NUM" >> httpd-vhosts.conf
	echo "  JkMount /* tomcat$NUM" >> httpd-vhosts.conf
	echo -e '</VirtualHost>\n' >> httpd-vhosts.conf
    NUM=$(($NUM-1))
done

echo "<VirtualHost *:80>" >> httpd-vhosts.conf
echo "  ServerName cluster.lab" >> httpd-vhosts.conf
echo "  JkMount / tomcat-cluster" >> httpd-vhosts.conf
echo "  JkMount /* tomcat-cluster" >> httpd-vhosts.conf
echo -e "</VirtualHost>\n" >> httpd-vhosts.conf

sudo mv httpd-vhosts.conf /etc/httpd/conf.d/

NUM=$1
while [[ $NUM -gt 0 ]];
do
	MACHINEIP="$SAMPLEIP$((2+$NUM))"

# All provissions after first one will cause useless string in hosts file
# No workaround yet.
	sudo bash -c "echo \"$MACHINEIP tomcat$NUM\" >> /etc/hosts"
#

	NUM=$(($NUM-1))
done
#

sudo systemctl restart httpd

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
