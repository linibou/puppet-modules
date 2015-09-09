#!/bin/sh

## Main configuration
BACKUPDIR='/home/backup/mysql'
TMPDIR='/home/tmp/backup_tmp'
MYCNF='/etc/mysql/my.cnf'
MYCNFACCESS='/root/.my.cnf'
MY_INIT='/etc/init.d/mysql'

## Remote configuration (remote ftp server)
#change to 1 to send backup to remote ftp server
REMOTE_ENABLE=1
REMOTE_HOST='dedibackup-bzn.online.net'
REMOTE_USER='user'
REMOTE_PASSWORD='xxxx'
MAX_DAYS_TO_KEEP=7

DATE=$(date +'%Y_%m_%d_%H.%M')

usage()
{
    cat <<EOF

$(basename $0) perform a backup of all mysql datadir or specifics databases using mysqlhotcopy
 - when using specific backup, mysql database is always backuped, no need to specify it.

usage:
$(basename $0) [all] [ -- db1 db2 db3 ...]

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

backup_all()
{
    test -f $MYCNF || abort "can't find $MYCNF !"
    datadir=$(grep "^datadir" $MYCNF | awk '{print $3}')
    cd $datadir
    $MY_INIT stop || abort "can't stop database !"
    tar czf ${BACKUPDIR}/${BACKUP_NAME} * || abort "problem while creating archive !"
    $MY_INIT start || abort "can't start database !"
    logger -t "[$(basename $0)][ok]" backup successfull
}

backup_bases()
{
    test -f $MYCNFACCESS || abort "can't find access info in $MYCNFACCESS !"
    cd $TMPDIR
    mysqlhotcopy mysql $@ $TMPDIR || abort "porblem while performing hotcopy !"
    tar czf ${BACKUPDIR}/${BACKUP_NAME} * || abort "problem while creating archive !"
    logger -t "[$(basename $0)][ok]" backup successfull
}

remote_transfer()
{
    if [ "$REMOTE_ENABLE" = "1" ] ; then
	test -x /usr/bin/lftp || abort "can't find lftp client, remote transfer aborted !"
	lftp -u ${REMOTE_USER},${REMOTE_PASSWORD} $REMOTE_HOST -e "mrm -f ${REMOTE_PREFIX_TO_REMOVE}* ; put ${BACKUPDIR}/${BACKUP_NAME} ; exit"
    fi
}

test -f $MY_INIT || abort "can't find $MY_INIT"
test -d $BACKUPDIR || mkdir -p $BACKUPDIR
test -d $TMPDIR || mkdir -p $TMPDIR
rm -rf ${TMPDIR}/*
rm -rf ${BACKUPDIR}/*

BACKUP_NAME="backup_$(hostname)_mysql_${DATE}.tar.gz"
REMOTE_PREFIX_TO_REMOVE="backup_$(hostname)_mysql_$(date +'%Y_%m_%d_' -d -${MAX_DAYS_TO_KEEP}days)"

case $1 in
    all)
	backup_all
	remote_transfer ;;
    --)
	shift
	backup_bases $@
	remote_transfer ;;
    *)
	usage ;;
esac
