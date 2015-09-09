#! /bin/sh
### BEGIN INIT INFO
# Provides:          uwsgi
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/stop uWSGI server instance(s)
# Description:       This script manages uWSGI server instance(s).
#
#                    You can issue to init.d script following commands:
#                      * start        | starts daemon
#                      * stop         | stops daemon
#                      * reload       | sends to daemon SIGHUP signal
#                      * force-reload | sends to daemon SIGTERM signal
#                      * restart      | issues 'stop', then 'start' commands
#                      * status       | shows status of daemon instance
### END INIT INFO

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="uwsgi service"
NAME=uwsgi
DAEMON=/usr/local/bin/uwsgi
DAEMON_ARGS=""
PIDFILE=/var/run/${NAME}.pid
LOGDIR=/var/log/$NAME
LOGFILE=${LOGDIR}/emperor.log
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

[ -d "$LOGDIR" ] || mkdir -p $LOGDIR

do_status() {
    RUNNING="0"
    kill -0 $(cat $PIDFILE) 2>/dev/null && RUNNING="1"
    if [ "$RUNNING" = "0" ] ; then
	   echo "$NAME not running ..."
	   return 1
    else
	   echo "$NAME running ..."
	   return 0
    fi
}

#
# Function that starts the daemon/service
#
do_start()
{
    action="0"
    do_status >/dev/null || action="start"
    if [ "$action" = "0" ] ; then
        echo "$NAME already running ..."
        return 1
    else
        echo "Starting $NAME ..."
        $DAEMON --emperor /etc/uwsgi -d $LOGFILE --pidfile $PIDFILE $DAEMON_ARGS
        return 0
    fi
}

#
# Function that stops the daemon/service
#
do_stop()
{
    action=0
    do_status >/dev/null && action="stop"
    if [ "$action" = 0 ] ; then
        echo "$NAME not running ..."
        return 1
    else
        echo "Stopping $NAME ..."
        kill -INT $(cat $PIDFILE)
        return 0
    fi
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
    action="0"
    do_status >/dev/null && action="reload"
    if [ "$action" = "0" ] ; then
        echo "$NAME not running ..."
        return 1
    else
        echo "Reloading $NAME ..."
        kill -HUP $(cat $PIDFILE)
        return 0
    fi
}

case "$1" in
    start)
	   do_start
	;;
    stop)
	   do_stop
	;;
    status)
	   do_status
       ;;
    reload)
	   do_reload
	;;
    restart|force-reload)
	   do_stop
	   sleep 1
	   do_start
	;;
    *)
	   echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
	   exit 1
	;;
esac
