#!/bin/sh

BACKUPDIR='/home/backup/mysql'

## Remote configuration (remote ftp server)
#change to 1 to send backup to remote ftp server
REMOTE_ENABLE=1
REMOTE_HOST='dedibackup-bzn.online.net'
REMOTE_USER='user'
REMOTE_PASSWORD='xxxx'
MAX_DAYS_TO_KEEP=14

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
      lftp -u ${REMOTE_USER},${REMOTE_PASSWORD} $REMOTE_HOST -e "mirror --delete -R ${BACKUPDIR}/ ; exit"
    fi
}

mylvmbackup >/dev/null

find /home/backup/ -name "backup-*mysql*" -mtime +${MAX_DAYS_TO_KEEP} -exec rm -f {} \;

remote_transfer

