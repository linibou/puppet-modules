#!/bin/sh

## Main configuration
BACKUPROOT='/home/backup/'
BACKUPDIR='mysql'
TMPDIR='/home/tmp/backup_tmp'
LVMROOT='/dev/data'
LVMYSQL="${LVMROOT}/data_mysql"
LVSNAPNAME="mysql-snapshot"

## Remote configuration (remote ftp server)
#change to 1 to send backup to remote ftp server
REMOTE_ENABLE=1
REMOTE_HOST='dedibackup-bzn.online.net'
REMOTE_USER='user'
REMOTE_PASSWORD='xxxx'
MAX_DAYS_TO_KEEP=14

DATE=$(date +'%Y_%m_%d_%H.%M')

usage()
{
    cat <<EOF

$(basename $0) perform a backup of mysql databases using lvm snapshot.

usage:
  $(basename $0) [--file-copy|--sqldump]

options:
  --file-copy : make an archive of mysql datadir (default).
  --sqldump   : make a gziped sql dump. (not yet implemented)

EOF
    exit 1
}

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
      lftp -u ${REMOTE_USER},${REMOTE_PASSWORD} $REMOTE_HOST -e "mirror --delete -R ${BACKUPROOT}/${BACKUPDIR}/ ; exit"
    fi
}

take_lvm_snapshot()
{
    export LVM_SUPPRESS_FD_WARNINGS=1
    /usr/bin/mysql <<SQL_EOF
FLUSH TABLES WITH READ LOCK;
FLUSH LOGS;
SYSTEM /sbin/lvcreate -L10G -s -n $LVSNAPNAME $LVMYSQL
UNLOCK TABLES;
SQL_EOF
    logger -t "[$(basename $0)][info]" "snapshot created"
}

mount_lvm_snapshot()
{
    mkdir ${TMPDIR}/mysql
    mount ${LVMROOT}/${LVSNAPNAME} ${TMPDIR}/mysql && logger -t "[$(basename $0)][info]" "snapshot mounted"
}

umount_lvm_snapshot()
{
    umount ${TMPDIR}/mysql && logger -t "[$(basename $0)][info]" "snapshot unmounted"
}

backup_to_archive()
{
    cd ${TMPDIR}
    tar czf ${BACKUPROOT}/${BACKUPDIR}/$BACKUP_NAME mysql && logger -t "[$(basename $0)][info]" "archive created"
}

remove_snapshot()
{
    /sbin/lvremove -f ${LVMROOT}/${LVSNAPNAME} && logger -t "[$(basename $0)][info]" "snapshot removed"
}

test -d ${BACKUPROOT}/${BACKUPDIR} || mkdir -p ${BACKUPROOT}/${BACKUPDIR}
test -d $TMPDIR || mkdir -p $TMPDIR
rm -rf ${TMPDIR}/*

BACKUP_NAME="backup_$(hostname)_${DATE}.tar.gz"
REMOTE_PREFIX_TO_REMOVE="backup_$(hostname)_$(date +'%Y_%m_%d_' -d -${MAX_DAYS_TO_KEEP}days)"
cd ${BACKUPROOT}/${BACKUPDIR}/
ls --sort=time ${BACKUPROOT}/${BACKUPDIR}/ | awk -v maxtokeep=$MAX_DAYS_TO_KEEP '{if (NR > maxtokeep) {print "rm -f "$0}}' | bash

take_lvm_snapshot
mount_lvm_snapshot
backup_to_archive
umount_lvm_snapshot
remove_snapshot
remote_transfer
