#!/usr/bin/env sh

############################################################
# backup_mysql.sh
#
# A script to backup all mysql tables on a given server into
# seperate .sql files and an optional .gz archive.
#
# Inspiration from:
# http://bash.cyberciti.biz/backup/backup-mysql-database-server-2/
############################################################

GZIP="$(which gzip)"
ECHO="$(which echo)"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"

BACKUP_DEST=''

# Usage description
usage ()
{
cat << EOF
USAGE: $0 arguments

This script makes mysql backups of all tables

ARGUMENTS:
   ?   Display this help.

       ALL ARGUMENTS ARE REQUIRED
  -u   Username
  -p   Password
  -h   Hostname
  -d   Destination

EOF
}

# Get the command line arguments.
while getopts ":u:p:h:" opt ; do
  case $opt in
    u ) MYSQLUSER=$OPTARG ;;
    p ) MYSQLPASS=$OPTARG ;;
    h ) MYSQLHOST=$OPTARG ;;
    d ) MYSQL_BACKUP_DEST=$OPTARG ;;

    * ) echo \n $usage
      exit 1 ;;
  esac
done

# Make sure the user has specified all the required attributes
if ( [ -z "$MYSQLUSER" ] || [ -z "$MYSQLPASS" ] || [ -z "$MYSQLHOST" ] || [ -z "$MYSQL_BACKUP_DEST" ] ) ; then
  echo ERROR: "You must specify a mysql username, password, and host."
  usage
  exit 1
fi

# ------------------------------------------------
#
# Backup MYSQL databases
#
# ------------------------------------------------

# Linux bin paths, change this if it can't be autodetected via which command
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"

# Get data in dd-mm-yyyy format
NOW="$(date "+%Y_%m_%d_%H_%M")"

# File to store current backup file
FILE=""
# Store list of databases
DBS=""

# DO NOT BACKUP these databases
# TODO Make this an argument in the future
IGNORE="test"

[ ! -d $MYSQL_BACKUP_DEST ] && mkdir -p $MYSQL_BACKUP_DEST || :

# Get a list of all the databases
DBS="$($MYSQL -u $MYSQLUSER -h $MYSQLHOST -p$MYSQLPASS -Bse 'show databases')"

# mysqldump each database individualy
for db in $DBS
do
  skipdb=-1
  if [ "$IGNORE" != "" ]; then
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
  fi
done
