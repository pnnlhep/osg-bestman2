#!/bin/bash -e

: ${LCMAPS_DEBUG_LEVEL:='2'}

export LCMAPS_DEBUG_LEVEL

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

if [ $"x$staticTokenList" != "x" ]; then
    sed -i '/^staticTokenList=.*/d' /etc/bestman2/conf/bestman2.rc
    echo staticTokenList="$staticTokenList" >> /etc/bestman2/conf/bestman2.rc
fi

for x in GUMSserviceURL supportedProtocolList securePort localPathListAllowed localPathListToBlock; do
    eval v=\$$x
    sed -i '/^'$x'=.*/d' /etc/bestman2/conf/bestman2.rc
    echo "$x=$v" >> /etc/bestman2/conf/bestman2.rc
done

chown bestman /etc/grid-security/bestman/bestmancert.pem
chown bestman /etc/grid-security/bestman/bestmankey.pem

export LCMAPS_LOG_FILE=/srv/bestman2/var/log/lcmaps

. /etc/sysconfig/bestman2
export BESTMAN_LOG=/srv/bestman2/var/log/bestman2/bestman2.log
#ulimit -n 65536
chown bestman /srv/bestman2/var/log/bestman2
cd /tmp
su - bestman -c /bin/bash -c "/usr/sbin/bestman.server $BESTMAN_OPTIONS 2>> $BESTMAN_LOG  >> $BESTMAN_LOG"
