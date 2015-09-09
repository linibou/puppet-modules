#!/bin/sh

DATE=$(date +'%Y_%m_%d_%H.%M')
BACKUPDIR='/home/backup/pgsql'
BACKUP_NAME="backup_$(hostname)_pgsql_${DATE}.sql.gz"

## Remote configuration (remote ftp server)
#change to 1 to send backup to remote ftp server
REMOTE_ENABLE=1
REMOTE_HOST='dedibackup-bzn.online.net'
REMOTE_USER='user'
REMOTE_PASSWORD='xxxx'
MAX_DAYS_TO_KEEP=7
REMOTE_PREFIX_TO_REMOVE="backup_$(hostname)_pgsql_$(date +'%Y_%m_%d_' -d -${MAX_DAYS_TO_KEEP}days)"

abort()
{
    echo "[$(basename $0)] error during backup -> $1" >&2
    logger -t "[$(basename $0)][error]" $1
    echo "exiting ..." >&2
    exit 1
}

remote_transfer()
{
    if [ "$REMOTE_ENABLE" = "1" ] ; then
    test -x /usr/bin/lftp || abort "can't find lftp client, remote transfer aborted !"
    lftp -u ${REMOTE_USER},${REMOTE_PASSWORD} $REMOTE_HOST -e "mrm -f ${REMOTE_PREFIX_TO_REMOVE}* ; put ${BACKUPDIR}/${BACKUP_NAME} ; exit"
    fi
}

test -d $BACKUPDIR || mkdir -p $BACKUPDIR
rm -rf ${BACKUPDIR}/*

if { su -c pg_dumpall postgres | gzip >${BACKUPDIR}/$BACKUP_NAME ;} ; then
    logger -t "[$(basename $0)][ok]" backup sucessfull
else
    echo "error during backup !" >&2
    abort "error during backup"
fi

remote_transfer
