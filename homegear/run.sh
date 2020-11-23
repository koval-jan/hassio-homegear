#!/bin/bash

# Inspired by https://github.com/Homegear/Homegear-Docker/blob/master/nightly/start.sh

_term() {
	HOMEGEAR_PID=$(cat /var/run/homegear/homegear.pid)
	kill $(cat /var/run/homegear/homegear-management.pid)
	kill $(cat /var/run/homegear/homegear-webssh.pid)
	kill $(cat /var/run/homegear/homegear-influxdb.pid)
	kill $HOMEGEAR_PID
	wait "$HOMEGEAR_PID"
	/config/homegear/homegear-stop.sh
	exit 0
}

trap _term SIGTERM

if [[ $GET_VERSION -eq 1 ]]; then
	homegear -v
	exit $?
fi

USER=homegear

USER_ID=$(id -u $USER)
USER_GID=$(id -g $USER)

USER_ID=${HOST_USER_ID:=$USER_ID}
USER_GID=${HOST_USER_GID:=$USER_GID}

if [ $USER_ID -ne 0 ]; then
	sed -i -e "s/^${USER}:\([^:]*\):[0-9]*:[0-9]*/${USER}:\1:${USER_ID}:${USER_GID}/" /etc/passwd
	sed -i -e "s/^${USER}:\([^:]*\):[0-9]*/${USER}:\1:${USER_GID}/" /etc/group
fi

# prepare config/share
mkdir -p /config/homegear /share/homegear/data /share/homegear/log
chown ${USER}:${USER} /config/homegear /share/homegear/data /share/homegear/log

#rm -Rf /config/homegear /var/lib/homegear /var/log/homegear
#ln -nfs /config/homegear /etc/homegear
#ln -nfs /share/homegear/lib /var/lib/homegear
#ln -nfs /share/homegear/log /var/log/homegear
#

if ! [ "$(ls -A /config/homegear)" ]; then
	cp -a /etc/homegear.config/* /config/homegear/
fi

if ! [ "$(ls -A /share/homegear/data)" ]; then
	cp -a /var/lib/homegear.data/* /share/homegear/data
else
	rm -Rf /share/homegear/data/modules/*
	mkdir -p /var/lib/homegear.data/modules
	cp -a /var/lib/homegear.data/modules/* /share/homegear/data/modules/
	[ $? -ne 0 ] && echo "Could not copy modules to \"homegear.data/modules/\". Please check the permissions on this directory and make sure it is writeable."

	rm -Rf /share/homegear/data/flows/nodes/*
	mkdir -p /var/lib/homegear.data/node-blue/nodes
	cp -a /var/lib/homegear.data/node-blue/nodes/* /share/homegear/data/node-blue/nodes/
	[ $? -ne 0 ] && echo "Could not copy nodes to \"homegear.data/node-blue/nodes\". Please check the permissions on this directory and make sure it is writeable."

	cd /share/homegear/data/admin-ui; ls /share/homegear/data/admin-ui/ | grep -v translations | xargs rm -Rf
	mkdir -p /var/lib/homegear.data/admin-ui
	cp -a /var/lib/homegear.data/admin-ui/* /share/homegear/data/admin-ui/
	[ ! -f /share/homegear/data/admin-ui/.env ] && cp -a /var/lib/homegear.data/admin-ui/.env /share/homegear/data/admin-ui/
	cp -a /var/lib/homegear.data/admin-ui/.version /share/homegear/data/admin-ui/
	[ $? -ne 0 ] && echo "Could not copy admin UI to \"homegear.data/admin-ui\". Please check the permissions on this directory and make sure it is writeable."
fi
rm -f /share/homegear/data/homegear_updated

if ! [ -f /share/homegear/log/homegear.log ]; then
	touch /share/homegear/log/homegear.log
	touch /share/homegear/log/homegear-webssh.log
	touch /share/homegear/log/homegear-flows.log
	touch /share/homegear/log/homegear-scriptengine.log
	touch /share/homegear/log/homegear-management.log
	touch /share/homegear/log/homegear-influxdb.log
fi

if ! [ -f /config/homegear/dh1024.pem ]; then
	openssl genrsa -out /config/homegear/homegear.key 2048
	openssl req -batch -new -key /config/homegear/homegear.key -out /config/homegear/homegear.csr
	openssl x509 -req -in /config/homegear/homegear.csr -signkey /config/homegear/homegear.key -out /config/homegear/homegear.crt
	rm /config/homegear/homegear.csr
	chmod 400 /config/homegear/homegear.key
	openssl dhparam -check -text -5 -out /config/homegear/dh1024.pem 1024
	chmod 400 /config/homegear/dh1024.pem
fi

chown -R root:root /config/homegear
chown ${USER}:${USER} /config/homegear/*.key
chown ${USER}:${USER} /config/homegear/*.pem
chown ${USER}:${USER} /config/homegear/ca/private/*.key
find /config/homegear -type d -exec chmod 755 {} \;
chown -R ${USER}:${USER} /share/homegear/log /share/homegear/data
find /share/homegear/log -type d -exec chmod 750 {} \;
find /share/homegear/log -type f -exec chmod 640 {} \;
find /share/homegear/data -type d -exec chmod 750 {} \;
find /share/homegear/data -type f -exec chmod 640 {} \;
find /share/homegear/data/scripts -type f -exec chmod 550 {} \;

# reconfigure folders

find /config/homegear -type f -exec sed -i 's"/etc/homegear"/config/homegear"g; s"/var/lib/homegear"/share/homegear/data"g; s"/var/log/homegear"/share/homegear/log"g' {} +
find /share/homegear/data -type f -exec sed -i 's"/etc/homegear"/config/homegear"g; s"/var/lib/homegear"/share/homegear/data"g; s"/var/log/homegear"/share/homegear/log"g' {} +

sed -i 's"/usr/bin/homegear"/usr/bin/homegear -c /config/homegear"' /config/homegear/homegear-start.sh

ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

mkdir -p /var/run/homegear
chown ${USER}:${USER} /var/run/homegear

/config/homegear/homegear-start.sh
/usr/bin/homegear -u ${USER} -g ${USER} -p /var/run/homegear/homegear.pid &
sleep 5
/usr/bin/homegear-management -p /var/run/homegear/homegear-management.pid &
/usr/bin/homegear-webssh -u ${USER} -g ${USER} -p /var/run/homegear/homegear-webssh.pid &
/usr/bin/homegear-influxdb -u ${USER} -g ${USER} -p /var/run/homegear/homegear-influxdb.pid &
tail -f /share/homegear/log/homegear-webssh.log &
tail -f /share/homegear/log/homegear-flows.log &
tail -f /share/homegear/log/homegear-scriptengine.log &
tail -f /share/homegear/log/homegear-management.log &
tail -f /share/homegear/log/homegear-influxdb.log &
tail -f /share/homegear/log/homegear.log &
child=$!
wait "$child"
