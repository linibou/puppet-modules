#!/bin/sh
### BEGIN INIT INFO
# Provides:          firewall
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: firewall service
# Description:       manage firewall
### END INIT INFO

IPV6=true

if [ "$IPV6" = "false" ] ; then
    COMMANDS="/sbin/iptables"
else
    COMMANDS="/sbin/iptables /sbin/ip6tables"
fi

FWRULESDIR="/home/scripts/firewall/rules"
export INTERFACE="eth+"
INPUT_TCP="22"

tables_purge() {
    for command in $COMMANDS ; do
        $command -F
        $command -X
        $command -F -t nat
        $command -X -t nat

    done
}

set_default_policy() {
    for command in $COMMANDS ; do
        $command -P INPUT $1
        $command -P OUTPUT $1
        $command -P FORWARD $1
    done
}

case $1 in
    start|restart)
	echo "+------------------------+"
	echo "| activation du firewall |"
	echo "+------------------------+"

    tables_purge
    set_default_policy DROP

	for command in $COMMANDS ; do
        ################################
        # regles pour la boucle locale #
        ################################
	    $command -A INPUT -i lo -j ACCEPT
	    $command -A OUTPUT -o lo -j ACCEPT

        #################
        # regles OUTPUT #
        #################
	    $command -A OUTPUT -m state ! --state INVALID -j ACCEPT

        ################
        # regles INPUT #
        ################
        for port in $INPUT_TCP ; do
            $command -A INPUT -i $INTERFACE -p tcp --dport $port -m state ! --state INVALID -j ACCEPT
        done

        for rule in ${FWRULESDIR}/* ; do
            if [ -f $rule ] ; then
                awk -v c=$command '$0 !~ /^#/ {print c" "$0}' $rule | bash
            fi
        done

        ##connexions etablies
	    $command -A INPUT -i $INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
        # ping
    	$command -A INPUT -i $INTERFACE -p icmp -m state --state NEW,RELATED,ESTABLISHED,UNTRACKED -j ACCEPT
	done
    exit 0
	;;

    stop)
	echo "+-------------------+"
	echo "| arret du firewall |"
	echo "+-------------------+"

    tables_purge
    set_default_policy ACCEPT

    exit 0
	;;

    *)
	echo "Usage: $0 {start|stop|restart}"
	;;
esac

