#!/bin/bash

sudo pkill serf


# do not join cluster on balancer vm
if [[ $(hostname) == "kazak-web" ]]; then 
	serf agent -node=$(hostname) -bind=$(hostname -I | sed "s/ /\n/g" | grep 192.168.56) -event-handler=/vagrant/handler.sh -log-level=debug > /tmp/.serf.log&
else
	serf agent -node=$(hostname) -bind=$(hostname -I | sed "s/ /\n/g" | grep 192.168.56) > /tmp/.serf.log&
fi
#
# workaround for slowpoke serf agents
sleep 5s 
#
serf join 192.168.56.2