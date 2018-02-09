#!/bin/bash -e

: ${LCMAPS_DEBUG_LEVEL:='2'}

export LCMAPS_DEBUG_LEVEL

if [ "x$SKIP_ENV" = "x" ]; then

if [ "x$GUMSserviceURL" = "x" ]; then
    echo You must specify GUMSserviceURL
    exit -1
fi

if [ "x$supportedProtocolList" = "x" ]; then
    echo You must specify supportedProtocolList
    exit -1
fi

if [ "x$USE_LDAP" != "x" ]
then
    sed -i 's/^passwd:.*/passwd:	files ldap/' /etc/nsswitch.conf
    sed -i 's/^shadow:.*/shadow:	files ldap/' /etc/nsswitch.conf
    sed -i 's/^group:.*/group:	files ldap/' /etc/nsswitch.conf
fi

if [ $"x$REMOVE_BESTMAN_USER" != "x" ]; then
    sed -i '/^bestman/d' /etc/passwd
    sed -i '/^bestman/d' /etc/group
    sed -i '/^bestman/d' /etc/gshadow
    sed -i '/^bestman/d' /etc/shadow
fi

mkdir -p /srv/bestman2/etc/grid-security
mkdir -p /srv/bestman2/var/log/bestman2

if [ ! -f /srv/bestman2/etc/lcmaps.db ]
then
    cp -a /etc/lcmaps.db.bak /srv/bestman2/etc/lcmaps.db
fi

rm -f /etc/lcmaps.db || true
ln -s /srv/bestman2/etc/lcmaps.db /etc/lcmaps.db

if [ ! -f /srv/bestman2/etc/grid-security/gsi-authz.conf ]
then
    cp -a /etc/grid-security/gsi-authz.conf.bak /srv/bestman2/etc/grid-security/gsi-authz.conf
fi

rm -f /etc/grid-security/gsi-authz.conf || true
ln -s /srv/bestman2/etc/grid-security/gsi-authz.conf /etc/grid-security/gsi-authz.conf

: ${securePort:=8443}
: ${localPathListAllowed:=/se}
: ${localPathListToBlock:='/root;/etc;/var;/usr;/srv;/boot'}
: ${javaHeap:=1024}

if [ $"x$staticTokenList" != "x" ]; then
    sed -i '/^staticTokenList=.*/d' /etc/bestman2/conf/bestman2.rc
    echo staticTokenList="$staticTokenList" >> /etc/bestman2/conf/bestman2.rc
fi

if [ $"x$ADLER32" != "x" ]; then
    sed -i '/^showChecksumWhenListingFile=.*/d' /etc/bestman2/conf/bestman2.rc
    sed -i '/^defaultChecksumType=.*/d' /etc/bestman2/conf/bestman2.rc
    sed -i '/^hexChecksumCommand=.*/d' /etc/bestman2/conf/bestman2.rc
    echo showChecksumWhenListingFile=true >> /etc/bestman2/conf/bestman2.rc
    echo defaultChecksumType=adler32 >> /etc/bestman2/conf/bestman2.rc
    echo hexChecksumCommand=/usr/bin/adler32 >> /etc/bestman2/conf/bestman2.rc
fi

for x in GUMSserviceURL supportedProtocolList securePort localPathListAllowed localPathListToBlock; do
    eval v=\$$x
    sed -i '/^'$x'=.*/d' /etc/bestman2/conf/bestman2.rc
    echo "$x=$v" >> /etc/bestman2/conf/bestman2.rc
done

sed -i '/^BESTMAN_MAX_JAVA_HEAP=/d' /etc/sysconfig/bestman2
echo "BESTMAN_MAX_JAVA_HEAP=$javaHeap" >> /etc/sysconfig/bestman2

sed -i 's@^EventLogLocation=.*@EventLogLocation=/srv/bestman2/var/log/bestman2@' /etc/bestman2/conf/bestman2.rc

chown bestman /etc/grid-security/bestman/bestmancert.pem
chown bestman /etc/grid-security/bestman/bestmankey.pem

fi #end "x$SKIP_ENV" = "x" ]

touch /var/run/bestman2.pid
chown bestman /var/run/bestman2.pid
mkdir -p /srv/bestman2/var/log/bestman2
chown bestman /srv/bestman2/var/log/bestman2

(
if [ "x$START_WAIT_FILE" != "x" ]; then
	while true; do
		[ -f "$START_WAIT_FILE" ] && break
		sleep 1
	done
fi
export LCMAPS_LOG_FILE=/srv/bestman2/var/log/lcmaps
. /etc/sysconfig/bestman2
if [ -f /etc/sysconfig/bestman2.1 ]; then
  . /etc/sysconfig/bestman2.1
fi
if [ -f /etc/start.extra.sh ]; then
  . /etc/start.extra.sh
fi
cd /tmp
exec su - bestman -c /bin/bash -c "/usr/sbin/bestman.server $BESTMAN_OPTIONS"
) & pid=$!

trap "kill $pid" TERM
echo $pid > /var/run/cbestman2.pid
if [ "x$START_WAIT_DONE_FILE" != "x" ]; then
	touch "$START_WAIT_DONE_FILE"
fi
wait $pid
[ -f /etc/shutdown.sh ] && bash /etc/shutdown.sh
