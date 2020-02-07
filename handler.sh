#!/bin/bash

# REWRITES HTTPD CONFIG FILES ON THE FLY, USE WITH CAUTION

VAR=${SERF_EVENT}
join_handler () {

 	echo "Someone joined!"

}

leave_handler () {
	
	echo "Someone left!"

}

handler () {
	sleep 2s
	cp /vagrant/vhosts.conf httpd-vhosts.conf
	echo '' > workers.properties

	WORKERLIST="tomcat-cluster"
	NODESLIST=""
	declare -i NUM
	NUM=1
	MEMBERIPS=$(serf members | grep alive | grep tomcat | sed "/\t/d"|awk '{print $1}' | awk -F"-" '{print $2}' | xargs)

 	for i in $MEMBERIPS; do

 		# workaround for extra ","
	    if [[ $NUM == 1 ]];then			
			NODESLIST="$i"
	    else
 	    	NODESLIST="$NODESLIST,$i"
	    fi

	    #

	    echo "worker.$i.type=ajp13" >> workers.properties
 	    echo "worker.$i.host=$i" >> workers.properties
 	    echo "worker.$i.port=8009" >> workers.properties
 	    echo -e "worker.$i.lbfactor=1\n" >> workers.properties

	    echo '<VirtualHost *:80>' >> httpd-vhosts.conf
		echo "  ServerName $i.lab" >> httpd-vhosts.conf
		echo "  JkMount / $i" >> httpd-vhosts.conf
		echo "  JkMount /* $i" >> httpd-vhosts.conf
		echo -e '</VirtualHost>\n' >> httpd-vhosts.conf

	    NUM=$(($NUM+1))
	done

	[[ -z $MEMBERIPS ]]&& exit 0

	WORKERLIST="$NODESLIST,$WORKERLIST"
	echo -e "\nworker.list=$WORKERLIST\n" >> workers.properties
	echo "worker.tomcat-cluster.sticky_session=false" >> workers.properties
	echo "worker.tomcat-cluster.type=lb" >> workers.properties
	echo "worker.tomcat-cluster.balanced_workers=$NODESLIST" >> workers.properties

	sudo cp workers.properties /etc/httpd/conf/

	echo "<VirtualHost *:80>" >> httpd-vhosts.conf
	echo "ServerName cluster.lab" >> httpd-vhosts.conf
	echo "JkMount / tomcat-cluster" >> httpd-vhosts.conf
	echo "JkMount /* tomcat-cluster" >> httpd-vhosts.conf
	echo "</VirtualHost>" >> httpd-vhosts.conf

	sudo cp httpd-vhosts.conf /etc/httpd/conf.d/

	rm httpd-vhosts.conf workers.properties
	
	sudo systemctl reload httpd && echo "Refreshed balancer nodes."

}

echo "New event: $VAR."

case $VAR in 

	member-join)
	 join_handler
	 handler # comment this out if you don't want to rewrite any rules after first execution of vagrant up
	 ;;
	member-leave)
	 leave_handler
	 handler # comment this out if you don't want to rewrite any rules after first execution of vagrant up
	 ;;
	*)
	 exit 0
	 ;;
esac



