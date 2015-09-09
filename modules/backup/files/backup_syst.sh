#!/bin/sh
BACKUPROOT=/home/backup/
BACKUPDIR=system
BACKUPMOUNT=mnt
BACKUPPREFIX=system_$(hostname)_

## Remote configuration (remote ftp server)
#change to 1 to send backup to remote ftp server
REMOTE_ENABLE=0
REMOTE_HOST='dedibackup-bzn.online.net'
REMOTE_USER='user'
REMOTE_PASSWORD='xxxx'
MAX_TO_KEEP=3

#pour avoir la date du jour:
date=`date +'%d_%m_%Y'`

BACKUP_NAME=${BACKUPPREFIX}${date}.tar.gz

usage()
{
    cat <<EOF

$(basename $0) perform a backup of / partition

usage:
$(basename $0)

EOF
    exit 0
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
    #lftp -u ${REMOTE_USER},${REMOTE_PASSWORD} $REMOTE_HOST -e "mrm -f ${REMOTE_PREFIX_TO_REMOVE}* ; put ${BACKUPDIR}/${BACKUP_NAME} ; exit"
    lftp -u ${REMOTE_USER},${REMOTE_PASSWORD} $REMOTE_HOST -e "mirror --delete -R ${BACKUPROOT}/${BACKUPDIR}/ ; exit"
    fi
}
case $1 in
    help|--help|-h)
        usage
        ;;
esac

test -d ${BACKUPROOT} || { mkdir -p ${BACKUPROOT} || abort "can't create ${BACKUPROOT}" ;}
cd $BACKUPROOT

#on vérifie que l'on a un répertoire ou on va pouvoir monter nos partitions système
#si il n'existe pas on le crée
test -d ${BACKUPMOUNT} || mkdir ${BACKUPMOUNT}
test -d ${BACKUPDIR} || mkdir ${BACKUPDIR}

mount --bind / ${BACKUPMOUNT} || abort "can't mount / on $BACKUPMOUNT"

#on va dans le répertoire et on fait la sauvegarde
cd ${BACKUPMOUNT}
tar -czf ../${BACKUPDIR}/${BACKUPPREFIX}${date}.tar.gz * 2>>/dev/null && logger -t "[$(basename $0)][ok]" "System archive successfully created"

#on sort et on démonte tout
cd ..
umount ${BACKUPMOUNT} || abort "can't unmount $BACKUPMOUNT"

#on purge les anciennes sauvegardes, on en conserve que 3
ls --sort=time ${BACKUPDIR}/${BACKUPPREFIX}* | awk -v maxtokeep=$MAX_TO_KEEP '{if (NR > maxtokeep) {print "rm -f "$0}}' | bash
REMOTE_PREFIX_TO_REMOVE=${BACKUPPREFIX}

remote_transfer

