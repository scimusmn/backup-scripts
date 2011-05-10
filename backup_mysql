#!/bin/bash

GZIP="$(which gzip)"
ECHO="$(which echo)"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"

# ------------------------------------------------
#
# Mount the Exhibit Projects SAMBA share
# This is where backups will be stored
#
# ------------------------------------------------

# Path to backup destination
# DEST_SERVER=""
# DEST_VOLUME=""
# 
# No trailing slash
# DEST_MOUNT_DESTINATION=""

# if [[ ! -d $DEST_MOUNT_DESTINATION ]]; then
  # mkdir $DEST_MOUNT_DESTINATION
# fi

# No leading or trailing slash
# DEST_PATH=""
# DEST_USER=""

# echo 'Connecting the SMM fileserver. Password request will be for SMM domain password'
# mount_smbfs //$BACKUP_USER@$BACKUP_SERVER/$BACKUP_VOLUME $MOUNT_DESTINATION

# DEST=$MOUNT_DESTINATION/$BACKUP_PATH

# Backup destination. No trailing slash
BACKUP_DEST=''

# ------------------------------------------------
#
# Backup MYSQL databases
#
# ------------------------------------------------

MyUSER=""                # USERNAME
MyPASS=""      # PASSWORD
MyHOST="localhost"           # Hostname
 
# Linux bin paths, change this if it can't be autodetected via which command
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"

# BCK 2009_05_15 - Removing the parts of this script that chown/root the backup
# directory. This complicates things to much for right now, although it might be 
# a good idea in the future

# Main directory where backup will be stored
MYSQL_BACKUP_DEST="$BACKUP_DEST/mysql"
 
# Get hostname
HOST="$(hostname)"
 
# Get data in dd-mm-yyyy format
NOW="$(date "+%Y_%m_%d_%H_%M")"
 
# File to store current backup file
FILE=""
# Store list of databases
DBS=""
 
# DO NOT BACKUP these databases
IGNORE="test"
 
[ ! -d $MYSQL_BACKUP_DEST ] && mkdir -p $MYSQL_BACKUP_DEST || :
 
# BCK 2009_05_15 - Removing the parts of this script that chown/root the backup
# directory. This complicates things to much for right now, although it might be 
# a good idea in the future
# Only root can access it!
#$CHOWN 0.0 -R $DEST
#$CHMOD 0600 $DEST
 
# Get all database list first
DBS="$($MYSQL -u $MyUSER -h $MyHOST -p$MyPASS -Bse 'show databases')"
 
for db in $DBS
do
    skipdb=-1
    if [ "$IGNORE" != "" ];
    then
  for i in $IGNORE
  do
      [ "$db" == "$i" ] && skipdb=1 || :
  done
    fi
 
    if [ "$skipdb" == "-1" ] ; then
  FILE="$MYSQL_BACKUP_DEST/$db.$HOST.$NOW.gz"
  # do all inone job in pipe,
  # connect to mysql using mysqldump for select mysql database
  # and pipe it out to gz file in backup dir :)
        $MYSQLDUMP -u $MyUSER -h $MyHOST -p$MyPASS $db | $GZIP -9 > $FILE
        $ECHO "Table backed up : $db"
        # move to file server
        #mv $FILE $MYSQL_BACKUP_DEST
    fi
done
umount $MOUNT_DESTINATION
